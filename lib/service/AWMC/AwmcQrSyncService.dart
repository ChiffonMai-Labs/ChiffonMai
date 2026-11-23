import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../l10n/AppMessages.dart';
import '../../manager/DivingFish/DivingFishOAuthManager.dart';
import '../../manager/DivingFishProbeManager.dart';
import '../../manager/LuoXue/LuoXueOAuthManager.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AppTaskActivity.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/QuotaRetryHint.dart';
import '../../utils/SecureCredentialStore.dart';
import '../AccountAuthorizationStore.dart';
import '../AccountStore.dart';
import '../SyncStatsService.dart';
import 'AwmcApiService.dart';
import 'AwmcQuickIdentityStore.dart';
import 'AwmcStore.dart';

/// 服务端 `/api/awmc/qr-sync` 解析出的单条标准谱面机台成绩。
class AwmcParsedScore {
  final int songId;
  final int levelIndex;
  final int achievement;
  final int dxScore;
  final String? fc;
  final String? fs;

  const AwmcParsedScore({
    required this.songId,
    required this.levelIndex,
    required this.achievement,
    required this.dxScore,
    this.fc,
    this.fs,
  });

  double get percent => achievement / 10000.0;
  String get type => songId >= 10000 ? 'DX' : 'SD';
  String get key => '$songId/$levelIndex/$type';

  factory AwmcParsedScore.fromJson(Map<String, dynamic> json) =>
      AwmcParsedScore(
        songId: (json['songId'] as num?)?.toInt() ?? 0,
        levelIndex: (json['levelIndex'] as num?)?.toInt() ?? 0,
        achievement: (json['achievement'] as num?)?.toInt() ?? 0,
        dxScore: (json['dxScore'] as num?)?.toInt() ?? 0,
        fc: json['fc']?.toString(),
        fs: json['fs']?.toString(),
      );
}

class AwmcQrFishResult {
  final bool ok;
  final int submitted;
  final int creates;
  final int updates;
  final int skipped;
  final String? code;
  final String? message;
  final int? httpStatus;

  const AwmcQrFishResult({
    required this.ok,
    this.submitted = 0,
    this.creates = 0,
    this.updates = 0,
    this.skipped = 0,
    this.code,
    this.message,
    this.httpStatus,
  });

  factory AwmcQrFishResult.fromJson(Map<String, dynamic> json) =>
      AwmcQrFishResult(
        ok: json['ok'] == true,
        submitted: (json['submitted'] as num?)?.toInt() ?? 0,
        creates: (json['creates'] as num?)?.toInt() ?? 0,
        updates: (json['updates'] as num?)?.toInt() ?? 0,
        skipped: (json['skipped'] as num?)?.toInt() ?? 0,
        code: json['code']?.toString(),
        message: json['message']?.toString(),
        httpStatus: (json['http'] as num?)?.toInt(),
      );
}

class AwmcQrAwmcResult {
  final bool ok;
  final int totalRecords;
  final int imported;
  final int updated;
  final int skipped;
  final List<String> errors;
  final String? code;
  final String? message;
  final int? httpStatus;

  const AwmcQrAwmcResult({
    required this.ok,
    this.totalRecords = 0,
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
    this.code,
    this.message,
    this.httpStatus,
  });

  factory AwmcQrAwmcResult.fromJson(Map<String, dynamic> json) =>
      AwmcQrAwmcResult(
        ok: json['ok'] == true,
        totalRecords: (json['totalRecords'] as num?)?.toInt() ?? 0,
        imported: (json['imported'] as num?)?.toInt() ?? 0,
        updated: (json['updated'] as num?)?.toInt() ?? 0,
        skipped: (json['skipped'] as num?)?.toInt() ?? 0,
        errors: json['errors'] is List
            ? (json['errors'] as List).map((e) => '$e').toList()
            : const [],
        code: json['code']?.toString(),
        message: json['message']?.toString(),
        httpStatus: (json['http'] as num?)?.toInt(),
      );
}

class AwmcQrSyncResponse {
  final bool ok;
  final int httpStatus;
  final int? userId;
  final int totalPlayCount;
  final int scoreCount;
  final int elapsedMs;
  final AwmcQrFishResult? fish;
  final AwmcQrAwmcResult? awmc;
  final List<AwmcParsedScore> lxScores;
  final String? code;
  final String? errorMessage;

  const AwmcQrSyncResponse({
    required this.ok,
    this.httpStatus = 0,
    this.userId,
    this.totalPlayCount = 0,
    this.scoreCount = 0,
    this.elapsedMs = 0,
    this.fish,
    this.awmc,
    this.lxScores = const [],
    this.code,
    this.errorMessage,
  });

  bool get fishConsentRequired =>
      code == 'FISH_CONSENT_REQUIRED' || fish?.code == 'FISH_CONSENT_REQUIRED';
}

class AwmcQuickServerTargetResult {
  final bool ok;
  final int submitted;
  final int unchanged;
  final int skipped;
  final String? code;
  final String? message;
  final int? httpStatus;

  const AwmcQuickServerTargetResult({
    required this.ok,
    this.submitted = 0,
    this.unchanged = 0,
    this.skipped = 0,
    this.code,
    this.message,
    this.httpStatus,
  });

  factory AwmcQuickServerTargetResult.fromJson(Map<String, dynamic> json) =>
      AwmcQuickServerTargetResult(
        ok: json['ok'] == true,
        submitted: (json['submitted'] as num?)?.toInt() ?? 0,
        unchanged: (json['unchanged'] as num?)?.toInt() ?? 0,
        skipped: (json['skipped'] as num?)?.toInt() ?? 0,
        code: json['code']?.toString(),
        message: json['message']?.toString(),
        httpStatus: (json['http'] as num?)?.toInt(),
      );
}

class AwmcQuickServerResponse {
  final bool ok;
  final int httpStatus;
  final int scoreCount;
  final int elapsedMs;
  final AwmcQuickServerTargetResult? fish;
  final AwmcQuickServerTargetResult? awmc;
  final List<AwmcParsedScore> lxScores;
  final String? code;
  final String? errorMessage;

  const AwmcQuickServerResponse({
    required this.ok,
    this.httpStatus = 0,
    this.scoreCount = 0,
    this.elapsedMs = 0,
    this.fish,
    this.awmc,
    this.lxScores = const [],
    this.code,
    this.errorMessage,
  });

  bool get fishConsentRequired =>
      code == 'FISH_CONSENT_REQUIRED' || fish?.code == 'FISH_CONSENT_REQUIRED';
}

/// 线路 1 单次二维码读取与免导入 Token 分发客户端。
class AwmcQrSyncService {
  AwmcQrSyncService._();

  static final RegExp qqPattern = RegExp(r'^\d{5,12}$');
  static const String _qrSyncEndpoint = '${ApiUrls.BackendBaseUrl}/api/awmc/qr-sync';
  static const Duration _syncTimeout = Duration(seconds: 130);
  static const int _lxBatchSize = 200;

  /// 将可能带 `@qq.com` 后缀的水鱼账号归约为 5–12 位纯数字 QQ。
  static String? normalizeDivingFishQq(String? raw) {
    final value = raw?.trim() ?? '';
    final match = RegExp(r'^(\d{5,12})(?:@qq\.com)?$', caseSensitive: false)
        .firstMatch(value);
    return match?.group(1);
  }

  /// 解析当前已绑定的水鱼 QQ（顺序：水鱼资料 bind_qq → 在线 profile → 存档账号 QQ）。
  static Future<String?> resolveDivingFishQq() async {
    final prefs = await SharedPreferences.getInstance();
    final cached =
        normalizeDivingFishQq(prefs.getString(CacheKeyConstant.probeDivingFishBindQQ));
    if (cached != null) return cached;
    final fetched = normalizeDivingFishQq(await DivingFishProbeManager().fetchBindQQ());
    if (fetched != null) return fetched;
    final shuiyuId = normalizeDivingFishQq((await AccountStore.loadAll())['shuiyu']?.id);
    return shuiyuId;
  }

  /// 解析已配置的 AWMC NET QQ（只取 AWMC 相关槽位，不借用其它数据源 QQ）。
  static Future<String?> resolveAwmcNetQq() async {
    final lookup = (await AccountAuthorizationStore.awmcQQ()).trim();
    if (qqPattern.hasMatch(lookup)) return lookup;
    final awmcId = (await AccountStore.loadAll())['awmc']?.id.trim() ?? '';
    if (qqPattern.hasMatch(awmcId)) return awmcId;
    final prefs = await SharedPreferences.getInstance();
    final marker = (prefs.getString(CacheKeyConstant.awmcUserId) ?? '').trim();
    if (marker.startsWith('awmc:')) {
      final q = marker.substring(5).trim();
      if (qqPattern.hasMatch(q)) return q;
    }
    final netSync =
        (prefs.getString(CacheKeyConstant.awmcNetSyncQQ) ?? '').trim();
    return qqPattern.hasMatch(netSync) ? netSync : null;
  }

  /// 落雪线路 1 是否已有 OAuth 或个人 API 密钥。
  static Future<bool> hasLuoXueSyncAuth() async {
    if (await LuoXueOAuthManager().isLoggedIn()) return true;
    final key =
        (await SecureCredentialStore.read(CacheKeyConstant.probeLxnsImportToken))
                ?.trim() ??
            '';
    return key.isNotEmpty;
  }

  /// 通过服务端单次调用 AWMC `/v1/user/music`（4 Token），并按请求写入水鱼 / AWMC NET / 返回落雪成绩。
  static Future<AwmcQrSyncResponse> syncByQr({
    required String qrCode,
    String? fishQq,
    String? awmcQq,
    bool includeLx = false,
  }) =>
      AppTaskActivity.run(() async {
        final qr = qrCode.trim();
        final uri = Uri.parse(_qrSyncEndpoint);
        if (uri.host != Uri.parse(ApiUrls.BackendBaseUrl).host) {
          return AwmcQrSyncResponse(
            ok: false,
            errorMessage: appL10n.flowRefusedRequestToANonGatewayAddress(
                uri.host.toString()),
          );
        }

        final targets = <String, dynamic>{
          if (fishQq != null && fishQq.trim().isNotEmpty)
            'fish': {'qq': fishQq.trim()},
          if (awmcQq != null && awmcQq.trim().isNotEmpty)
            'awmc': {'qq': awmcQq.trim()},
          if (includeLx) 'lx': true,
        };
        if (targets.isEmpty) {
          return const AwmcQrSyncResponse(
            ok: false,
            errorMessage: '未指定任何同步目标',
          );
        }

        final sw = Stopwatch()..start();
        try {
          final response = await ApiClient.post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({'qrcode': qr, 'targets': targets}),
            timeout: _syncTimeout,
          );
          final elapsed = sw.elapsedMilliseconds;
          Map<String, dynamic>? decoded;
          try {
            final raw = json.decode(utf8.decode(response.bodyBytes));
            if (raw is Map) decoded = Map<String, dynamic>.from(raw);
          } catch (_) {}

          final ok = response.statusCode >= 200 &&
              response.statusCode < 300 &&
              decoded?['ok'] == true;
          final code = decoded?['code']?.toString();

          if (!ok) {
            final msg = _formatError(response, decoded, code);
            unawaited(AwmcAuditLog.record(
              AwmcCallResult(
                method: 'POST',
                path: '/qr-sync',
                httpStatus: response.statusCode,
                returnCode: (decoded?['returnCode'] as num?)?.toInt(),
                code: null,
                msg: msg,
                businessData: null,
                ok: false,
                costTokens: 4,
                elapsedMs: elapsed,
                errorMessage: msg,
              ),
              note: '通过 AWMC 网关单码同步 (${targets.keys.join('+')})',
            ));
            return AwmcQrSyncResponse(
              ok: false,
              httpStatus: response.statusCode,
              elapsedMs: elapsed,
              code: code,
              errorMessage: msg,
            );
          }

          final userId = (decoded!['userId'] as num?)?.toInt();
          if (userId != null && userId > 0 && userId <= 0xFFFFFFFF) {
            // 顺手保存机台身份（忽略写入失败，不影响主同步结果）
            try {
              await AwmcQuickIdentityStore.write(userId);
            } catch (_) {}
          }

          final resultsMap = decoded['results'] is Map
              ? Map<String, dynamic>.from(decoded['results'] as Map)
              : const <String, dynamic>{};
          final fishRes = resultsMap['fish'] is Map
              ? AwmcQrFishResult.fromJson(
                  Map<String, dynamic>.from(resultsMap['fish'] as Map))
              : null;
          final awmcRes = resultsMap['awmc'] is Map
              ? AwmcQrAwmcResult.fromJson(
                  Map<String, dynamic>.from(resultsMap['awmc'] as Map))
              : null;
          final lxList = <AwmcParsedScore>[];
          if (decoded['lxScores'] is List) {
            for (final item in decoded['lxScores'] as List) {
              if (item is Map) {
                lxList.add(
                    AwmcParsedScore.fromJson(Map<String, dynamic>.from(item)));
              }
            }
          }

          unawaited(AwmcAuditLog.record(
            AwmcCallResult(
              method: 'POST',
              path: '/qr-sync',
              httpStatus: response.statusCode,
              returnCode: 1,
              code: 0,
              msg: null,
              businessData: null,
              ok: true,
              costTokens: 4,
              elapsedMs: elapsed,
            ),
            note: '通过 AWMC 网关单码同步 (${targets.keys.join('+')})',
          ));

          return AwmcQrSyncResponse(
            ok: true,
            httpStatus: response.statusCode,
            userId: userId,
            totalPlayCount: (decoded['totalPlayCount'] as num?)?.toInt() ?? 0,
            scoreCount: (decoded['scoreCount'] as num?)?.toInt() ?? 0,
            elapsedMs: elapsed,
            fish: fishRes,
            awmc: awmcRes,
            lxScores: lxList,
          );
        } on TimeoutException {
          final elapsed = sw.elapsedMilliseconds;
          final msg =
              appL10n.flowRequestTimedOutP0S(_syncTimeout.inSeconds.toString());
          unawaited(AwmcAuditLog.record(
            AwmcCallResult.failure(
              method: 'POST',
              path: '/qr-sync',
              message: msg,
              elapsedMs: elapsed,
            ),
            note: '单码同步超时',
          ));
          return AwmcQrSyncResponse(
            ok: false,
            elapsedMs: elapsed,
            errorMessage: msg,
          );
        } catch (e) {
          final elapsed = sw.elapsedMilliseconds;
          final raw = e.toString();
          final msg = raw.contains('Invalid media type')
              ? appL10n.svcTheGatewayCouldNotReachItsOrigin
              : appL10n.svcRequestFailedP0(AwmcApiService.redact(raw));
          unawaited(AwmcAuditLog.record(
            AwmcCallResult.failure(
              method: 'POST',
              path: '/qr-sync',
              message: msg,
              elapsedMs: elapsed,
            ),
            note: '单码同步连接失败',
          ));
          return AwmcQrSyncResponse(
            ok: false,
            elapsedMs: elapsed,
            errorMessage: msg,
          );
        }
      });

  /// 通过服务端调用 AWMC `/v1/rival/music` 并增量同步至水鱼（OAuth）/ AWMC NET（Bot-Token），按需回传落雪成绩列表。
  static Future<AwmcQuickServerResponse> quickSyncViaServer({
    required int userId,
    String? fishQq,
    String? awmcQq,
    bool includeLx = false,
  }) =>
      AppTaskActivity.run(() async {
        final uri = Uri.parse(ApiUrls.AwmcQuickSyncUrl);
        if (uri.host != Uri.parse(ApiUrls.BackendBaseUrl).host) {
          return AwmcQuickServerResponse(
            ok: false,
            errorMessage: appL10n.flowRefusedRequestToANonGatewayAddress(
                uri.host.toString()),
          );
        }

        final normalizedFishQq = normalizeDivingFishQq(fishQq);
        final normalizedAwmcQq = awmcQq != null && qqPattern.hasMatch(awmcQq.trim())
            ? awmcQq.trim()
            : null;
        final targets = <String, dynamic>{
          if (normalizedFishQq != null) 'fish': {'qq': normalizedFishQq},
          if (normalizedAwmcQq != null) 'awmc': {'qq': normalizedAwmcQq},
          if (includeLx) 'lx': true,
        };
        if (targets.isEmpty) {
          return const AwmcQuickServerResponse(
            ok: false,
            errorMessage: '未指定任何同步目标',
          );
        }

        final sw = Stopwatch()..start();
        final rivalCost = AwmcApiService.costOf('/v1/rival/music');
        try {
          final response = await ApiClient.post(
            uri,
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: json.encode({'userId': userId, 'targets': targets}),
            timeout: _syncTimeout,
          );
          final elapsed = sw.elapsedMilliseconds;
          Map<String, dynamic>? decoded;
          try {
            final raw = json.decode(utf8.decode(response.bodyBytes));
            if (raw is Map) decoded = Map<String, dynamic>.from(raw);
          } catch (_) {}

          final ok = response.statusCode >= 200 &&
              response.statusCode < 300 &&
              decoded?['ok'] == true;
          final code = decoded?['code']?.toString();

          if (!ok && (decoded?['results'] is! Map || response.statusCode >= 400)) {
            final msg = _formatError(response, decoded, code);
            unawaited(AwmcAuditLog.record(
              AwmcCallResult(
                method: 'POST',
                path: '/quick-sync',
                httpStatus: response.statusCode,
                returnCode: (decoded?['returnCode'] as num?)?.toInt(),
                code: null,
                msg: msg,
                businessData: null,
                ok: false,
                costTokens: rivalCost,
                elapsedMs: elapsed,
                errorMessage: msg,
              ),
              note: '通过 AWMC 网关快速同步 (${targets.keys.join('+')})',
            ));
            return AwmcQuickServerResponse(
              ok: false,
              httpStatus: response.statusCode,
              elapsedMs: elapsed,
              code: code,
              errorMessage: msg,
            );
          }

          final resultsMap = decoded!['results'] is Map
              ? Map<String, dynamic>.from(decoded['results'] as Map)
              : const <String, dynamic>{};
          final fishRes = resultsMap['fish'] is Map
              ? AwmcQuickServerTargetResult.fromJson(
                  Map<String, dynamic>.from(resultsMap['fish'] as Map))
              : null;
          final awmcRes = resultsMap['awmc'] is Map
              ? AwmcQuickServerTargetResult.fromJson(
                  Map<String, dynamic>.from(resultsMap['awmc'] as Map))
              : null;
          final lxList = <AwmcParsedScore>[];
          if (decoded['lxScores'] is List) {
            for (final item in decoded['lxScores'] as List) {
              if (item is Map) {
                lxList.add(
                    AwmcParsedScore.fromJson(Map<String, dynamic>.from(item)));
              }
            }
          }

          unawaited(AwmcAuditLog.record(
            AwmcCallResult(
              method: 'POST',
              path: '/quick-sync',
              httpStatus: response.statusCode,
              returnCode: 1,
              code: 0,
              msg: null,
              businessData: null,
              ok: ok,
              costTokens: rivalCost,
              elapsedMs: elapsed,
            ),
            note: '通过 AWMC 网关快速同步 (${targets.keys.join('+')})',
          ));

          return AwmcQuickServerResponse(
            ok: ok,
            httpStatus: response.statusCode,
            scoreCount: (decoded['scoreCount'] as num?)?.toInt() ?? 0,
            elapsedMs: elapsed,
            fish: fishRes,
            awmc: awmcRes,
            lxScores: lxList,
          );
        } on TimeoutException {
          final elapsed = sw.elapsedMilliseconds;
          final msg =
              appL10n.flowRequestTimedOutP0S(_syncTimeout.inSeconds.toString());
          unawaited(AwmcAuditLog.record(
            AwmcCallResult.failure(
              method: 'POST',
              path: '/quick-sync',
              message: msg,
              elapsedMs: elapsed,
            ),
            note: '快速同步超时',
          ));
          return AwmcQuickServerResponse(
            ok: false,
            elapsedMs: elapsed,
            errorMessage: msg,
          );
        } catch (e) {
          final elapsed = sw.elapsedMilliseconds;
          final raw = e.toString();
          final msg = raw.contains('Invalid media type')
              ? appL10n.svcTheGatewayCouldNotReachItsOrigin
              : appL10n.svcRequestFailedP0(AwmcApiService.redact(raw));
          unawaited(AwmcAuditLog.record(
            AwmcCallResult.failure(
              method: 'POST',
              path: '/quick-sync',
              message: msg,
              elapsedMs: elapsed,
            ),
            note: '快速同步连接失败',
          ));
          return AwmcQuickServerResponse(
            ok: false,
            elapsedMs: elapsed,
            errorMessage: msg,
          );
        }
      });

  static String _formatError(
    http.Response response,
    Map<String, dynamic>? decoded,
    String? code,
  ) {
    if (response.statusCode == 429) {
      final hint = quotaRetryHint(utf8.decode(response.bodyBytes));
      return appL10n.svcTooManyAWMCNETRequestsTryAgain(hint.toString());
    }
    if (code == 'FISH_CONSENT_REQUIRED') {
      return appL10n.flowDivingFishWriteConsentRequiredMessage;
    }
    final raw = decoded?['message']?.toString() ?? decoded?['error']?.toString();
    if (raw != null && raw.trim().isNotEmpty) {
      return AwmcApiService.redact(raw.trim());
    }
    return 'HTTP ${response.statusCode}';
  }

  /// 直接把解析好的机台成绩推送到落雪：OAuth (`write_player`) Bearer 优先，无 OAuth 时回退个人 API 密钥。
  static Future<({int submitted, int skipped})> uploadLxScores(
    List<AwmcParsedScore> scores, {
    void Function(double progress, String text)? onProgress,
  }) =>
      AppTaskActivity.run(() async {
        if (scores.isEmpty) {
          throw StateError(appL10n.svcNoValidScoresWereReadNothingWas);
        }
        onProgress?.call(
            0.55,
            appL10n.flowCheckingChartsSupportedByP02(
                appLocalizeLabel(SyncPlatform.luoXue.label)));
        final supportedCharts = await _fetchLuoXueCharts();
        final payload = <Map<String, dynamic>>[];
        var skipped = 0;
        for (final score in scores) {
          if (!supportedCharts.contains(score.key)) {
            skipped++;
            continue;
          }
          payload.add({
            'id': score.songId % 10000,
            'type': score.songId >= 10000 ? 'dx' : 'standard',
            'level_index': score.levelIndex,
            'achievements': score.percent,
            'dx_score': score.dxScore,
            if (score.fc != null && score.fc!.isNotEmpty) 'fc': score.fc,
            if (score.fs != null && score.fs!.isNotEmpty) 'fs': score.fs,
          });
        }
        if (payload.isEmpty) {
          throw StateError(appL10n.svcNoValidScoresMatchedTheLocalSong);
        }

        var oauthToken = await LuoXueOAuthManager().getAccessToken();
        String? apiKey;
        var usingOAuth = oauthToken != null && oauthToken.isNotEmpty;
        if (!usingOAuth) {
          apiKey = (await SecureCredentialStore.read(
                  CacheKeyConstant.probeLxnsImportToken))
              ?.trim();
          if (apiKey == null || apiKey.isEmpty) {
            throw StateError(appL10n.svcYourLXNSAccountIsNotAuthorizedComplete);
          }
        }

        var retriedAuth = false;
        var submitted = 0;
        for (var start = 0; start < payload.length; start += _lxBatchSize) {
          final end = (start + _lxBatchSize).clamp(0, payload.length);
          onProgress?.call(
            0.6 + 0.35 * start / payload.length,
            appL10n.flowUpdatingP0ScoresP1P2(
              appLocalizeLabel(SyncPlatform.luoXue.label),
              start.toString(),
              payload.length.toString(),
            ),
          );
          final batch = payload.sublist(start, end);
          var response = await _postLxBatch(
            batch,
            oauthToken: usingOAuth ? oauthToken : null,
            apiKey: usingOAuth ? null : apiKey,
          );
          if (usingOAuth && response.statusCode == 401 && !retriedAuth) {
            retriedAuth = true;
            final refreshed = await LuoXueOAuthManager().refreshToken();
            if (refreshed != null && refreshed.accessToken.isNotEmpty) {
              oauthToken = refreshed.accessToken;
              response = await _postLxBatch(batch, oauthToken: oauthToken);
            }
          }
          Map<String, dynamic>? decoded;
          try {
            final raw = json.decode(utf8.decode(response.bodyBytes));
            if (raw is Map) decoded = Map<String, dynamic>.from(raw);
          } catch (_) {}

          if (response.statusCode == 401) {
            throw StateError(appL10n.svcLXNSAuthorizationExpiredOrTheKeyIs);
          }
          if (response.statusCode == 403) {
            throw StateError(
                appL10n.svcLXNSRejectedThisWriteInsufficientPermissions);
          }
          if (response.statusCode < 200 ||
              response.statusCode >= 300 ||
              decoded == null ||
              decoded['success'] != true) {
            throw StateError(appL10n.svcUploadToP0FailedHTTPP1Remaining(
              appLocalizeLabel(SyncPlatform.luoXue.label),
              response.statusCode.toString(),
            ));
          }
          submitted += batch.length;
        }

        return (submitted: submitted, skipped: skipped);
      });

  static Future<http.Response> _postLxBatch(
    List<Map<String, dynamic>> batch, {
    String? oauthToken,
    String? apiKey,
  }) =>
      ApiClient.post(
        Uri.parse(ApiUrls.LuoXuePlayerScoresApi),
        headers: {
          'Content-Type': 'application/json',
          if (oauthToken != null)
            'Authorization': 'Bearer $oauthToken'
          else if (apiKey != null)
            'X-User-Token': apiKey,
        },
        body: json.encode({'scores': batch}),
        timeout: const Duration(seconds: 60),
      );

  static Future<Set<String>> _fetchLuoXueCharts() async {
    final response = await ApiClient.get(
      Uri.parse(ApiUrls.LuoXueSongsApi),
      timeout: const Duration(seconds: 45),
    );
    dynamic data;
    if (response.statusCode == 200) {
      try {
        data = json.decode(utf8.decode(response.bodyBytes));
      } catch (_) {}
    }
    if (data is Map) data = data['songs'];
    if (data is! List) {
      throw StateError(appL10n.svcCouldNotReadTheP0SongLibrary(
          appLocalizeLabel(SyncPlatform.luoXue.label)));
    }
    final charts = <String>{};
    for (final song in data.whereType<Map>()) {
      final id = int.tryParse('${song['id']}');
      if (id == null || id <= 0 || id >= 100000) continue;
      final difficulties = song['difficulties'];
      if (difficulties is! Map) continue;
      for (final type in ['standard', 'dx']) {
        final levels = difficulties[type];
        if (levels is! List) continue;
        final dx = type == 'dx';
        final songId = dx && id < 10000 ? id + 10000 : id;
        for (final level in levels.whereType<Map>()) {
          final index = int.tryParse('${level['difficulty']}');
          if (index != null && ChartDifficulty.isStandard(index)) {
            charts.add('$songId/$index/${dx ? 'DX' : 'SD'}');
          }
        }
      }
    }
    if (charts.isEmpty) {
      throw StateError(appL10n.svcTheP0SongLibraryIsEmptyNo(
          appLocalizeLabel(SyncPlatform.luoXue.label)));
    }
    return charts;
  }

  /// 检查水鱼写入授权（更新 `DivingFishOAuthManager` 状态）。
  static Future<bool?> checkFishWriteAuthorized(String qq) =>
      DivingFishOAuthManager().checkWriteAuthorization(qq);
}
