import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../l10n/AppMessages.dart';
import '../../utils/ApiClient.dart';
import '../../utils/ChartDifficulty.dart';

/// 排行榜上传资格状态。
enum RankingGuardState { normal, frozen, blacklisted }

/// 排行榜上传没有完成的原因类别，决定独立对话框的语气。
enum RankingUploadIssue { rejected, frozen, blacklisted, upgradeRequired, failed }

/// 排行榜上传没有完成。成绩本身已经刷新并保存，只是排行榜没有更新，
/// 所以由独立的「排行榜上传未完成」对话框展示，不当作刷新失败。
class RankingUploadException implements Exception {
  /// 已本地化的具体原因。
  final String message;
  final RankingUploadIssue issue;

  const RankingUploadException(this.message, this.issue);

  static RankingUploadIssue issueOf(String? code) => switch (code) {
        'UPLOAD_REJECTED' => RankingUploadIssue.rejected,
        'RANKING_FROZEN' => RankingUploadIssue.frozen,
        'RANKING_BLACKLISTED' => RankingUploadIssue.blacklisted,
        'CLIENT_UPGRADE_REQUIRED' => RankingUploadIssue.upgradeRequired,
        _ => RankingUploadIssue.failed,
      };

  @override
  String toString() => message;
}

/// 一次预检的结果。[ok] 为 true 时 [ticket] 可能为空（服务端尚未部署守卫或暂不可用）。
class RankingPrecheckResult {
  final bool ok;
  final String? ticket;

  /// 不通过时给用户看的完整说明（已本地化）。
  final String? message;
  final String? code;

  const RankingPrecheckResult.passed(this.ticket)
      : ok = true,
        message = null,
        code = null;

  const RankingPrecheckResult.blocked(this.code, this.message)
      : ok = false,
        ticket = null;
}

/// 排行榜上传守卫的客户端部分（服务端见 server/upload-guard.js）。
///
/// 上传前先把本次的 Rating 与全部成绩交给服务端一次性校验，通过后拿到
/// 10 分钟有效的凭证，Rating 榜与单曲榜上传都带上它：任何一处不合法就整次都不写入。
///
/// 冻结 / 黑名单状态按数据源记在本地，「参与排行榜」勾选框据此禁用并说明原因。
class RankingUploadGuard {
  RankingUploadGuard._();

  static const String ticketHeader = 'X-Upload-Ticket';
  static const String _stateKeyPrefix = 'ranking_guard_state_';

  /// 各数据源（shuiyu / luoxue / awmc）当前的上传资格状态。
  static final ValueNotifier<Map<String, RankingGuardState>> states =
      ValueNotifier(const {});

  static bool _loaded = false;
  static String? _appVersion;

  /// 最近一次被守卫拒绝的原因代码（本轮预检开始时清空），用来区分拒绝 / 冻结 / 拉黑。
  static String? lastBlockedCode;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final next = <String, RankingGuardState>{};
      for (final source in const ['shuiyu', 'luoxue', 'awmc']) {
        final name = prefs.getString('$_stateKeyPrefix$source');
        final state = RankingGuardState.values
            .where((value) => value.name == name)
            .firstOrNull;
        if (state != null && state != RankingGuardState.normal) {
          next[source] = state;
        }
      }
      states.value = next;
    } catch (e) {
      debugPrint('[RankingGuard] 读取状态失败: $e');
    }
  }

  static Future<void> _setState(String source, RankingGuardState state) async {
    await load();
    if ((states.value[source] ?? RankingGuardState.normal) == state) return;
    states.value = {...states.value, source: state}
      ..removeWhere((_, value) => value == RankingGuardState.normal);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_stateKeyPrefix$source', state.name);
    } catch (_) {}
  }

  static String _sourceOf(String playerId) => playerId.split(':').first;

  static Future<Map<String, String>> _headers() async {
    try {
      _appVersion ??= (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    return {
      'Content-Type': 'application/json',
      if (_appVersion != null) 'X-App-Version': _appVersion!,
    };
  }

  /// 从服务端查一次当前资格（打开带「参与排行榜」的对话框时调用）。
  static Future<void> refreshStatus(String playerId) async {
    if (playerId.isEmpty) return;
    try {
      final response = await ApiClient.get(
        Uri.parse(
            '${ApiUrls.UploadGuardStatusUrl}/${Uri.encodeComponent(playerId)}'),
        headers: await _headers(),
      );
      if (response.statusCode != 200) return;
      final body = json.decode(response.body);
      if (body is! Map || body['success'] != true) return;
      await _setState(_sourceOf(playerId), _parseState(body['status']));
    } catch (e) {
      debugPrint('[RankingGuard] 查询资格失败: $e');
    }
  }

  static RankingGuardState _parseState(Object? raw) =>
      RankingGuardState.values.where((v) => v.name == raw).firstOrNull ??
      RankingGuardState.normal;

  /// 上传前预检。[records] 为本次要参与单曲榜的成绩（已在本地剔除不合法的记录），
  /// [titles] 用来把违规项换成曲名展示。
  ///
  /// 网络失败、服务端还没有这个接口（404）或校验服务暂不可用时放行，
  /// 由各上传接口自己的校验兜底，不因为守卫本身的故障阻断正常玩家。
  static Future<RankingPrecheckResult> precheck({
    required String playerId,
    required int totalRating,
    required int best35Rating,
    required int best15Rating,
    required List<Map<String, dynamic>> records,
    Map<String, String> titles = const {},
  }) async {
    lastBlockedCode = null;
    try {
      final response = await ApiClient.postGzip(
        Uri.parse(ApiUrls.UploadGuardCheckUrl),
        headers: await _headers(),
        body: {
          'playerId': playerId,
          'rating': {
            'total': totalRating,
            'best35': best35Rating,
            'best15': best15Rating,
          },
          'records': records,
        },
        timeout: const Duration(seconds: 60),
      );
      final body = _decode(response.body);
      if (response.statusCode == 200 && body?['success'] == true) {
        await _setState(_sourceOf(playerId), RankingGuardState.normal);
        return RankingPrecheckResult.passed(body?['ticket'] as String?);
      }
      final blocked = blockedFromResponse(
          playerId, response.statusCode, body,
          titles: titles);
      return blocked ?? const RankingPrecheckResult.passed(null);
    } catch (e) {
      debugPrint('[RankingGuard] 预检失败，交由上传接口兜底: $e');
      return const RankingPrecheckResult.passed(null);
    }
  }

  static Map<String, dynamic>? _decode(String text) {
    try {
      final value = json.decode(text);
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }

  /// 把守卫的拒绝响应转成提示；不是守卫的响应时返回 null。
  /// 上传接口（Rating 榜、单曲榜）收到非 200 时也用它解析。
  static RankingPrecheckResult? blockedFromResponse(
    String playerId,
    int statusCode,
    Map<String, dynamic>? body, {
    Map<String, String> titles = const {},
  }) {
    final code = body?['code'] as String?;
    final source = _sourceOf(playerId);
    if (const {
      'RANKING_FROZEN',
      'RANKING_BLACKLISTED',
      'CLIENT_UPGRADE_REQUIRED',
      'UPLOAD_REJECTED',
    }.contains(code)) {
      lastBlockedCode = code;
    }
    switch (code) {
      case 'RANKING_FROZEN':
        _setState(source, RankingGuardState.frozen);
        return RankingPrecheckResult.blocked(
            code, appL10n.rankingGuardFrozen);
      case 'RANKING_BLACKLISTED':
        _setState(source, RankingGuardState.blacklisted);
        return RankingPrecheckResult.blocked(
            code, appL10n.rankingGuardBlacklisted);
      case 'CLIENT_UPGRADE_REQUIRED':
        return RankingPrecheckResult.blocked(
            code, appL10n.rankingGuardUpgradeRequired);
      case 'UPLOAD_REJECTED':
        final violations = (body?['violations'] as List?) ?? const [];
        final reasons = <String>{
          for (final item in violations.whereType<Map>())
            _describe(item, titles),
        }.take(3).join('；');
        final left = (body?['strikesLeft'] as num?)?.toInt() ?? 0;
        return RankingPrecheckResult.blocked(
          code,
          appL10n.rankingGuardRejected(
              reasons.isEmpty ? appL10n.rankingGuardReasonInvalid : reasons,
              left.toString()),
        );
      default:
        return null;
    }
  }

  static String _describe(Map item, Map<String, String> titles) {
    final songId = item['songId']?.toString();
    final level = (item['levelIndex'] as num?)?.toInt();
    String chart() {
      final title = songId == null ? '' : (titles[songId] ?? songId);
      final label = level == null
          ? ''
          : ChartDifficulty.labelOf(level,
              isUtage: (songId?.length ?? 0) >= 6);
      return '$title $label'.trim();
    }

    switch (item['code']) {
      case 'RATING_OVER_LIMIT':
        return appL10n.rankingGuardReasonRating;
      case 'UNKNOWN_SONG':
        return appL10n.rankingGuardReasonUnknownSong(chart());
      case 'UNRELEASED_SONG':
        return appL10n.rankingGuardReasonUnreleased(chart());
      case 'LEVEL_OUT_OF_RANGE':
        return appL10n.rankingGuardReasonLevel(chart());
      case 'ACHIEVEMENT_OVER_LIMIT':
        return appL10n.rankingGuardReasonAchievement(chart());
      case 'DX_OVER_LIMIT':
        return appL10n.rankingGuardReasonDx(chart());
      default:
        return appL10n.rankingGuardReasonInvalid;
    }
  }
}
