import '../utils/UserProfileNotifier.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../utils/ApiClient.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import 'CommunityProfileAuthorization.dart';

class PlayerExperienceService extends ValueNotifier<Map<String, dynamic>?> {
  PlayerExperienceService._() : super(null);
  static final instance = PlayerExperienceService._();
  final Map<String, Future<void>> _inFlight = {};
  int _cacheGeneration = 0;
  String message = '';
  bool _started = false;

  /// AWMC 按 QQ 匹配账号，水鱼和落雪沿用各自的登录或管理凭据。
  static Future<Map<String, String>> ownerHeaders(String playerId) =>
      CommunityProfileAuthorization.ownerHeaders(playerId);

  Future<void> start() async {
    if (_started) return;
    _started = true;
    CurrentDataSourceNotifier.instance.addListener(_sourceChanged);
    UserProfileNotifier.instance.addListener(_sourceChanged);
    try {
      await _loadCurrentCache();
      final player = await _currentPlayer();
      if (player != null) await _checkIn(player);
    } catch (_) {
      message = '签到暂时不可用，下次启动会自动重试';
      notifyListeners();
    }
  }

  void _sourceChanged() {
    message = '';
    value = null;
    // 普通切换只读取缓存；登录或验证成功通过明确的入口补签。
    unawaited(_loadCurrentCache().catchError((Object _) {
      message = '成长记录暂时无法读取，下次启动会自动重试';
      notifyListeners();
    }));
  }

  Future<String?> _currentPlayer() async {
    final prefs = await SharedPreferences.getInstance();
    final source = RefreshDataSource.fromKey(
        prefs.getString(CacheKeyConstant.lastDataSource));
    final marker = prefs.getString(source.userIdCacheKey);
    return marker?.startsWith('${source.key}:') == true ? marker : null;
  }

  Future<void> _loadCurrentCache() async {
    final generation = ++_cacheGeneration;
    final player = await _currentPlayer();
    final prefs = await SharedPreferences.getInstance();
    final raw =
        player == null ? null : prefs.getString('player_experience_v1:$player');
    if (player != await _currentPlayer() || generation != _cacheGeneration)
      return;
    Map<String, dynamic>? cached;
    try {
      final decoded = raw == null ? null : jsonDecode(raw);
      if (decoded is Map) cached = Map<String, dynamic>.from(decoded);
    } on FormatException {
      // 本地缓存损坏不能阻止本次服务端签到。
    }
    message = cached?['date'] == _today() ? '今日已签到' : '';
    value = cached;
  }

  /// 本机登录或身份验证成功后调用，不依赖目标账号是否正在前台显示。
  Future<void> onAccountAuthenticated(String player) async {
    if (!RegExp(r'^(shuiyu|luoxue|awmc):[1-9]\d*$').hasMatch(player)) return;
    // 启动时的旧凭据请求可能仍在进行，等它结束后再用新凭据检查。
    final running = _inFlight[player];
    if (running != null) await running;
    await _checkIn(player);
  }

  static String _today() => DateTime.now()
      .toUtc()
      .add(const Duration(hours: 8))
      .toIso8601String()
      .substring(0, 10);

  Future<void> _checkIn(String player) {
    return _inFlight[player] ??= _performCheckIn(player).whenComplete(() {
      _inFlight.remove(player);
    });
  }

  Future<void> _performCheckIn(String player) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('player_experience_v1:$player');
      try {
        final cached = raw == null ? null : jsonDecode(raw);
        // 只依据服务端上次确认的日期跳过，当天失败不会阻止登录后重试。
        if (cached is Map &&
            cached['playerId'] == player &&
            cached['date'] == _today()) return;
      } on FormatException {
        // 损坏的缓存不妨碍服务端签到。
      }
      final response = await ApiClient.post(
          Uri.parse('${ApiUrls.BackendBaseUrl}/api/me/experience/checkin'),
          headers: await ownerHeaders(player),
          body: jsonEncode({'playerId': player}),
          timeout: const Duration(seconds: 20));
      final body = jsonDecode(response.body) as Map;
      if (response.statusCode != 200 || body['success'] != true) {
        throw StateError(body['error']?.toString() ?? '签到暂时不可用，下次启动自动重试');
      }
      final data = Map<String, dynamic>.from(body['data'] as Map);
      if (data['playerId'] != player) throw StateError('签到账号不匹配');
      await prefs.setString('player_experience_v1:$player', jsonEncode(data));
      if (player != await _currentPlayer()) return;
      ++_cacheGeneration;
      message = (data['awarded'] as num) > 0
          ? '今日签到 +${data['awarded']} 经验'
          : '今日已签到';
      value = data;
    } catch (e) {
      if (player != await _currentPlayer()) return;
      message = e.toString().replaceFirst('Bad state: ', '');
      notifyListeners();
    }
  }
}
