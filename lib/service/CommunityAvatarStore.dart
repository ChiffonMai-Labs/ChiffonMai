import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/CacheKeyConstant.dart';
import '../entity/LuoXue/Collection.dart';
import '../utils/ApiClient.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import '../utils/SecureCredentialStore.dart';
import 'CommunityProfileAuthorization.dart';
import 'RankingList/RatingRankListService.dart';
import 'RankingList/AvgRankingListService.dart';
import 'RankingList/FittedRatingRankingListService.dart';

/// 保留原类型名称，头像与其它装扮共用同步状态。
enum AvatarSyncLevel { localOnly, syncing, synced, pending, error }

class AvatarSyncState {
  final String? playerId;
  final int avatarId, generation;
  final Map<String, dynamic>? nameplate, frame, trophy;
  final String message;
  final bool pending;
  final AvatarSyncLevel level;
  int? get plateId => nameplate?['id'] as int?;
  int? get frameId => frame?['id'] as int?;
  int? get trophyId => trophy?['id'] as int?;
  const AvatarSyncState(
      {this.playerId,
      this.avatarId = 1,
      this.nameplate,
      this.frame,
      this.trophy,
      this.generation = 0,
      this.message = '装扮仅保存在本机',
      this.pending = false,
      this.level = AvatarSyncLevel.localOnly});
  Map<String, dynamic> get appearance => {
        'avatarId': avatarId,
        'nameplate': nameplate,
        'frame': frame,
        'trophy': trophy,
        'generation': generation
      };
}

/// 每账号独立的持久化待发队列；只上传有改动的字段，版本冲突时重读并重试。
class CommunityAvatarStore extends ValueNotifier<AvatarSyncState> {
  CommunityAvatarStore._() : super(const AvatarSyncState());
  static final instance = CommunityAvatarStore._();

  /// 服务端确认装扮变化并清理缓存后通知公开资料页面重新读取。
  static final profileChanges = ChangeNotifier();
  static const _endpoint = 'https://chiffonmai.cloud/api/me/appearance';
  static const _legacyOwner = 'community_avatar_legacy_owner';
  static const _localKey = 'community_appearance_local_v1';
  static const _fields = ['avatarId', 'nameplate', 'frame', 'trophy'];
  static String _key(String player) => 'community_avatar_v1_$player';
  Future<void> _writes = Future.value();
  final Set<String> _syncing = {}, _resync = {};
  Future<void>? _activationFuture;
  bool _activateAgain = false;
  String? _lastActivatedPlayer;

  Future<T> _queue<T>(Future<T> Function() action) {
    final result = _writes.then((_) => action());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Map<String, dynamic> _read(SharedPreferences prefs, String key) {
    try {
      return Map<String, dynamic>.from(
          jsonDecode(prefs.getString(key) ?? '{}') as Map);
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _entry(SharedPreferences prefs, String player) =>
      _read(prefs, _key(player));
  Future<void> _persist(
      SharedPreferences prefs, String key, Map<String, dynamic> entry) async {
    if (!await prefs.setString(key, jsonEncode(entry)))
      throw StateError('无法保存装扮');
  }

  Set<String> _dirty(Map<String, dynamic> entry) => entry['dirtyFields'] is List
      ? (entry['dirtyFields'] as List)
          .whereType<String>()
          .where(_fields.contains)
          .toSet()
      : entry['pending'] == true
          ? {'avatarId'}
          : {};
  AvatarSyncState _state(String? player, Map<String, dynamic> entry,
      String message, AvatarSyncLevel level) {
    Map<String, dynamic>? item(String key) =>
        entry[key] is Map ? Map<String, dynamic>.from(entry[key] as Map) : null;
    return AvatarSyncState(
        playerId: player,
        avatarId: entry['avatarId'] as int? ?? 1,
        nameplate: item('nameplate'),
        frame: item('frame'),
        trophy: item('trophy'),
        generation: entry['generation'] as int? ?? 0,
        pending: entry['pending'] == true,
        message: message,
        level: level);
  }

  void _publish(String player, Map<String, dynamic> entry, String message,
      AvatarSyncLevel level) {
    if (value.playerId != player ||
        (value.pending &&
            value.generation > (entry['generation'] as int? ?? 0))) return;
    value = _state(player, entry, message, level);
  }

  Future<String?> _activePlayer(SharedPreferences prefs) async {
    final source = RefreshDataSource.fromKey(
        prefs.getString(CacheKeyConstant.lastDataSource));
    final marker = prefs.getString(source.userIdCacheKey);
    if (marker?.startsWith('${source.key}:') == true &&
        RefreshDataSource.parseUserIdMarker(marker) != null) return marker;
    if (source == RefreshDataSource.shuiyu &&
        (await SecureCredentialStore.read(
                    CacheKeyConstant.probeDivingFishToken))
                ?.isNotEmpty ==
            true) {
      final qq =
          prefs.getString(CacheKeyConstant.probeDivingFishBindQQ)?.trim();
      if (qq != null && RegExp(r'^[1-9]\d{4,11}$').hasMatch(qq))
        return 'shuiyu:$qq';
    }
    return null;
  }

  Future<void> _compatibility(SharedPreferences prefs, String? player,
      Map<String, dynamic> entry) async {
    if (value.playerId != player ||
        value.generation != (entry['generation'] as int? ?? 0)) return;
    if (player != await _activePlayer(prefs)) return;
    await prefs.setInt('selectedAvatarId', entry['avatarId'] as int? ?? 1);
    if (value.playerId != player || player != await _activePlayer(prefs))
      return;
    final plate =
        entry['nameplate'] is Map ? entry['nameplate']['id'] as int? : null;
    if (plate == null) {
      await prefs.remove(CacheKeyConstant.selectedPlateIdCache);
    } else {
      await prefs.setInt(CacheKeyConstant.selectedPlateIdCache, plate);
    }
  }

  Future<void> activate() {
    if (_activationFuture != null) {
      _activateAgain = true;
      return _activationFuture!;
    }
    final future = _runActivation();
    _activationFuture = future;
    future.whenComplete(() => _activationFuture = null);
    return future;
  }

  Future<void> _runActivation() async {
    try {
      do {
        _activateAgain = false;
        await _queue(_activate);
      } while (_activateAgain);
    } catch (_) {
      value = const AvatarSyncState(
          message: '装扮未能读取，请重新打开此页', level: AvatarSyncLevel.error);
    }
  }

  Future<void> _activate() async {
    final prefs = await SharedPreferences.getInstance();
    final player = await _activePlayer(prefs);
    if (player != await _activePlayer(prefs)) {
      _activateAgain = true;
      return;
    }
    if (player == null) {
      _lastActivatedPlayer = null;
      var local = _read(prefs, _localKey);
      if (local.isEmpty && prefs.getString(_legacyOwner) == null)
        local = {
          'avatarId': prefs.getInt('selectedAvatarId') ?? 1,
          if (prefs.getInt(CacheKeyConstant.selectedPlateIdCache) != null)
            'nameplate': {
              'id': prefs.getInt(CacheKeyConstant.selectedPlateIdCache)
            }
        };
      final source = RefreshDataSource.fromKey(
          prefs.getString(CacheKeyConstant.lastDataSource));
      final message = switch (source) {
        RefreshDataSource.shuiyu => '仅本机保存 · 登录水鱼后自动同步',
        RefreshDataSource.luoxue => '仅本机保存 · 请先登录并刷新落雪账号',
        RefreshDataSource.awmc => '仅本机保存 · 请先填写 AWMC 账号的 QQ 号',
      };
      value = _state(null, local, message, AvatarSyncLevel.localOnly);
      return;
    }
    var entry = _entry(prefs, player);
    // 落雪的首次装扮由服务端按上游资料初始化；不把本机默认值当成用户选择上传。
    final preferRemote = player.startsWith('luoxue:');
    final local = _read(prefs, _localKey);
    if (!preferRemote && entry.isEmpty && local['pending'] == true) {
      entry = Map<String, dynamic>.from(local);
      await _persist(prefs, _key(player), entry);
      await prefs.remove(_localKey);
    }
    if (!preferRemote &&
        entry.isEmpty &&
        prefs.getString(_legacyOwner) == null &&
        prefs.containsKey('selectedAvatarId')) {
      entry = {
        'avatarId': prefs.getInt('selectedAvatarId') ?? 1,
        'pending': true,
        'generation': 1,
        'dirtyFields': ['avatarId']
      };
    }
    if (entry['appearanceMigrated'] != true) {
      final dirty = _dirty(entry),
          plate = prefs.getInt(CacheKeyConstant.selectedPlateIdCache);
      final source = RefreshDataSource.fromKey(
          prefs.getString(CacheKeyConstant.lastDataSource));
      if (!preferRemote &&
          plate != null &&
          (prefs.getString(source.userIdCacheKey) == player ||
              prefs.getString(_legacyOwner) == null) &&
          !entry.containsKey('nameplate')) {
        entry['nameplate'] = {'id': plate};
        dirty.add('nameplate');
      }
      entry.addAll({
        'appearanceMigrated': true,
        'dirtyFields': dirty.toList(),
        'pending': dirty.isNotEmpty
      });
      await _persist(prefs, _key(player), entry);
    }
    if (prefs.getString(_legacyOwner) == null)
      await prefs.setString(_legacyOwner, player);
    if (player != await _activePlayer(prefs)) {
      _activateAgain = true;
      return;
    }
    if (_lastActivatedPlayer == player && value.playerId == player) {
      if (preferRemote) unawaited(sync(player));
      return;
    }
    _lastActivatedPlayer = player;
    value = _state(
        player,
        entry,
        entry['pending'] == true ? '装扮待同步' : '正在读取社区装扮',
        AvatarSyncLevel.syncing);
    await _compatibility(prefs, player, entry);
    unawaited(sync(player));
  }

  Future<void> select(int avatarId) => _select('avatarId', avatarId);
  Future<void> selectPlate(Collection? item) =>
      _select('nameplate', _item(item));
  Future<void> selectFrame(Collection? item) => _select('frame', _item(item));
  Future<void> selectTrophy(Collection? item) => _select('trophy', _item(item));
  Map<String, dynamic>? _item(Collection? item) => item == null
      ? null
      : {
          'id': item.id,
          'name': item.name,
          if (item.color != null) 'color': item.color
        };
  Future<void> _select(String field, dynamic choice) {
    final player = value.playerId,
        optimistic = {
          ...value.appearance,
          field: choice,
          'pending': true,
          'generation': value.generation + 1
        };
    value = _state(player, optimistic, player == null ? value.message : '装扮待同步',
        player == null ? AvatarSyncLevel.localOnly : AvatarSyncLevel.pending);
    return _queue(() async {
      final prefs = await SharedPreferences.getInstance(),
          key = player == null ? _localKey : _key(player);
      final entry = player == null ? _read(prefs, key) : _entry(prefs, player);
      final dirty = _dirty(entry)..add(field);
      entry.addAll({
        field: choice,
        'dirtyFields': dirty.toList(),
        'pending': true,
        'generation': optimistic['generation'],
        'appearanceMigrated': true
      });
      await _persist(prefs, key, entry);
      await _compatibility(prefs, player, entry);
      if (player != null) unawaited(sync(player));
    });
  }

  /// 保留旧昵称与资料接口的来源凭据入口。
  static Future<Map<String, String>?> authorizationHeaders(String player) =>
      CommunityProfileAuthorization.legacyHeaders(player);
  Future<void> retry() async {
    final player = value.playerId;
    if (player != null) await sync(player);
  }

  String _failure(int status) =>
      [401, 403].contains(status) ? '装扮待同步 · 请登录或验证对应账号后重试' : '装扮待同步 · 点击重试';

  bool _sameChoice(String key, dynamic local, dynamic remote) {
    if (key == 'avatarId') {
      return int.tryParse('$local') == int.tryParse('$remote');
    }
    if (local == null || remote == null) return local == remote;
    return local is Map && remote is Map && local['id'] == remote['id'];
  }

  Future<void> _invalidateProfileCaches(SharedPreferences prefs) async {
    await Future.wait([
      RatingRankListService.clearRankingsCache(),
      AvgRankingListService.clearRankingsCache(),
      FittedRatingRankingListService.clearRankingsCache(),
    ]);
    for (final key in prefs
        .getKeys()
        .where((key) =>
            key.startsWith(CacheKeyConstant.songCommentsCacheTimestampPrefix))
        .toList()) {
      await prefs.remove(key);
    }
    profileChanges.notifyListeners();
  }

  Future<void> sync(String player) async {
    if (!_syncing.add(player)) {
      _resync.add(player);
      return;
    }
    var rerun = false;
    try {
      await _writes;
      final prefs = await SharedPreferences.getInstance(),
          headers = await CommunityProfileAuthorization.ownerHeaders(player);
      var entry = _entry(prefs, player);
      final hasAwmcQq = headers['X-Profile-Source'] == 'awmc' &&
          headers['X-Profile-QQ'] != null &&
          player == 'awmc:${headers['X-Profile-QQ']}';
      if (!hasAwmcQq &&
          !headers.containsKey('Authorization') &&
          !headers.containsKey('X-Auto-Sync-Token')) {
        _publish(
            player, entry, '仅本机保存 · 请先登录或验证对应账号', AvatarSyncLevel.localOnly);
        return;
      }
      _publish(player, entry, '正在同步社区装扮', AvatarSyncLevel.syncing);
      final get = await ApiClient.get(
          Uri.parse(_endpoint).replace(queryParameters: {'playerId': player}),
          headers: headers);
      if (get.statusCode != 200) {
        _publish(
            player, entry, _failure(get.statusCode), AvatarSyncLevel.error);
        return;
      }
      final readBody = jsonDecode(get.body) as Map;
      if (readBody['success'] != true || readBody['data'] is! Map) {
        throw StateError('装扮读取未被确认');
      }
      var remote = Map<String, dynamic>.from(readBody['data'] as Map);
      if (remote['playerId'] != player) throw StateError('装扮账号不匹配');
      await _writes;
      entry = _entry(prefs, player);
      if (entry['pending'] != true) {
        final applied = await _queue(() async {
          final latest = _entry(prefs, player);
          if (latest['pending'] == true) return false;
          final changed =
              _fields.any((key) => !_sameChoice(key, latest[key], remote[key]));
          latest.addAll({
            for (final key in _fields) key: remote[key],
            'revision': remote['profileRevision']
          });
          await _persist(prefs, _key(player), latest);
          _publish(player, latest, '社区装扮已同步', AvatarSyncLevel.synced);
          await _compatibility(prefs, player, latest);
          if (changed) await _invalidateProfileCaches(prefs);
          return true;
        });
        if (!applied) rerun = true;
      } else {
        for (var attempt = 0; attempt < 3; attempt++) {
          final generation = entry['generation'], dirty = _dirty(entry);
          final result = await ApiClient.put(Uri.parse(_endpoint),
              headers: headers,
              timeout: const Duration(seconds: 25),
              body: jsonEncode({
                'playerId': player,
                'expectedProfileRevision': remote['profileRevision'].toString(),
                for (final key in dirty) key: entry[key]
              }));
          final body = jsonDecode(result.body) as Map;
          await _writes;
          final latest = _entry(prefs, player);
          if (result.statusCode == 409 && body['data'] is Map) {
            remote = Map<String, dynamic>.from(body['data'] as Map);
            if (remote['playerId'] != player) throw StateError('装扮账号不匹配');
            entry = latest;
            continue;
          }
          if (result.statusCode != 200 ||
              body['success'] != true ||
              body['data']?['playerId'] != player) {
            _publish(player, latest, _failure(result.statusCode),
                AvatarSyncLevel.error);
            return;
          }
          remote = Map<String, dynamic>.from(body['data'] as Map);
          // HTTP 成功并不等于选择已经保存；旧响应或接口忽略字段时保留待发选择。
          if (dirty.any((key) =>
              !remote.containsKey(key) ||
              !_sameChoice(key, entry[key], remote[key]))) {
            _publish(
                player, latest, '装扮待同步 · 服务端尚未确认所选装扮', AvatarSyncLevel.error);
            return;
          }
          final saved = await _queue(() async {
            final current = _entry(prefs, player);
            if (current['generation'] != generation) return false;
            current.addAll({
              for (final key in _fields) key: remote[key],
              'pending': false,
              'dirtyFields': <String>[],
              'revision': remote['profileRevision']
            });
            await _persist(prefs, _key(player), current);
            _publish(player, current, '社区装扮已同步', AvatarSyncLevel.synced);
            await _compatibility(prefs, player, current);
            return true;
          });
          if (!saved) {
            entry = _entry(prefs, player);
            continue;
          }
          await _invalidateProfileCaches(prefs);
          break;
        }
        entry = _entry(prefs, player);
        if (entry['pending'] == true)
          _publish(player, entry, '装扮待同步 · 点击重试', AvatarSyncLevel.pending);
      }
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      _publish(
          player, _entry(prefs, player), '装扮待同步 · 点击重试', AvatarSyncLevel.error);
    } finally {
      await _writes;
      final prefs = await SharedPreferences.getInstance();
      final pending = _entry(prefs, player)['pending'] == true;
      _syncing.remove(player);
      final requested = _resync.remove(player);
      if ((rerun || requested) && (pending || player.startsWith('luoxue:')))
        unawaited(sync(player));
    }
  }
}
