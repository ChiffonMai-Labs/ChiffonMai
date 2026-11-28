import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../l10n/AppMessages.dart';
import '../../manager/AWMC/AwmcForumOAuthManager.dart';
import '../../manager/DivingFish/DivingFishOAuthManager.dart';
import '../../manager/DivingFish/DivingFishProbeManager.dart';
import '../../manager/LuoXue/LuoXueOAuthManager.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AppError.dart';
import '../../utils/AppTaskActivity.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/QuotaRetryHint.dart';
import '../../utils/SecureCredentialStore.dart';
import '../Account/AccountAuthorizationStore.dart';
import '../Account/AccountStore.dart';
import '../Sync/SyncStatsService.dart';
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
  bool get isUtage => songId >= 100000;
  String get type => isUtage ? 'UTAGE' : (songId >= 10000 ? 'DX' : 'SD');
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
  final String? requestId;
  final AppError? error;
  final int? expectedUserId;
  final int? actualUserId;

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
    this.requestId,
    this.error,
    this.expectedUserId,
    this.actualUserId,
  });

  bool get fishConsentRequired =>
      code == 'FISH_CONSENT_REQUIRED' || fish?.code == 'FISH_CONSENT_REQUIRED';

  bool get qrUserMismatch => code == 'QR_USER_MISMATCH';
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
  final String? requestId;
  final AppError? error;

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
    this.requestId,
    this.error,
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

  /// 为需要绑定目标 QQ 归属的 AWMC 接口附加论坛 OAuth 会话令牌。
  static Future<Map<String, String>> _awmcAuthHeaders(String? awmcQq) =>
      AwmcForumOAuthManager.authHeaders(awmcQq?.trim());

  static Future<Map<String, String>> _migrationAuthHeaders(String awmcQq) async {
    final fishToken = (await SecureCredentialStore.read(
      CacheKeyConstant.probeDivingFishToken,
    ))?.trim();
    return {
      ...await _awmcAuthHeaders(awmcQq),
      if (fishToken != null && fishToken.isNotEmpty)
        'Authorization': 'Bearer $fishToken',
    };
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
    int? expectedUserId,
    bool checkBoundIdentity = true,
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

        int? resolvedExpectedUserId = expectedUserId;
        if (resolvedExpectedUserId == null && checkBoundIdentity) {
          try {
            resolvedExpectedUserId = await AwmcQuickIdentityStore.read();
          } catch (_) {}
        }

        final awmcAuthHeaders = await _awmcAuthHeaders(awmcQq);
        final sw = Stopwatch()..start();
        try {
          final response = await ApiClient.post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              ...awmcAuthHeaders,
            },
            body: json.encode({
              'qrcode': qr,
              'targets': targets,
              if (resolvedExpectedUserId != null)
                'expectedUserId': resolvedExpectedUserId,
            }),
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
            final parsedError = ApiClient.parseError(
              response,
              title: appL10n.featureSyncFailed,
              stage: 'AWMC 单码同步',
              fallbackCode: code != null ? 'SYNC-$code' : 'SYNC-QR-FAILED',
            );
            final errWithMsg = parsedError.copyWith(userMessage: msg);
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
              requestId: errWithMsg.requestId,
              error: errWithMsg,
              expectedUserId: (decoded?['expectedUserId'] as num?)?.toInt(),
              actualUserId: (decoded?['actualUserId'] as num?)?.toInt(),
            );
          }

          final userId = (decoded!['userId'] as num?)?.toInt();
          if (userId != null &&
              userId > 0 &&
              userId <= 0xFFFFFFFF &&
              (resolvedExpectedUserId == null ||
                  resolvedExpectedUserId == userId)) {
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
        } on TimeoutException catch (e, stack) {
          final elapsed = sw.elapsedMilliseconds;
          final msg =
              appL10n.flowRequestTimedOutP0S(_syncTimeout.inSeconds.toString());
          final mapped = AppErrorMapper.from(
            e,
            stack: stack,
            title: appL10n.featureSyncFailed,
            stage: 'AWMC 单码同步',
          ).copyWith(userMessage: msg);
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
            requestId: mapped.requestId,
            error: mapped,
          );
        } catch (e, stack) {
          final elapsed = sw.elapsedMilliseconds;
          final raw = e.toString();
          final msg = raw.contains('Invalid media type')
              ? appL10n.svcTheGatewayCouldNotReachItsOrigin
              : appL10n.svcRequestFailedP0(AwmcApiService.redact(raw));
          final mapped = AppErrorMapper.from(
            e,
            stack: stack,
            title: appL10n.featureSyncFailed,
            stage: 'AWMC 单码同步',
          ).copyWith(userMessage: msg);
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
            requestId: mapped.requestId,
            error: mapped,
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

        final awmcAuthHeaders = await _awmcAuthHeaders(normalizedAwmcQq);
        final sw = Stopwatch()..start();
        final rivalCost = AwmcApiService.costOf('/v1/rival/music');
        try {
          final response = await ApiClient.post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              ...awmcAuthHeaders,
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
            final parsedError = ApiClient.parseError(
              response,
              title: appL10n.featureSyncFailed,
              stage: 'AWMC 快速同步',
              fallbackCode: code != null ? 'SYNC-$code' : 'SYNC-QUICK-FAILED',
            ).copyWith(userMessage: msg);
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
              requestId: parsedError.requestId,
              error: parsedError,
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
        } on TimeoutException catch (e, stack) {
          final elapsed = sw.elapsedMilliseconds;
          final msg =
              appL10n.flowRequestTimedOutP0S(_syncTimeout.inSeconds.toString());
          final mapped = AppErrorMapper.from(
            e,
            stack: stack,
            title: appL10n.featureSyncFailed,
            stage: 'AWMC 快速同步',
          ).copyWith(userMessage: msg);
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
            requestId: mapped.requestId,
            error: mapped,
          );
        } catch (e, stack) {
          final elapsed = sw.elapsedMilliseconds;
          final raw = e.toString();
          final msg = raw.contains('Invalid media type')
              ? appL10n.svcTheGatewayCouldNotReachItsOrigin
              : appL10n.svcRequestFailedP0(AwmcApiService.redact(raw));
          final mapped = AppErrorMapper.from(
            e,
            stack: stack,
            title: appL10n.featureSyncFailed,
            stage: 'AWMC 快速同步',
          ).copyWith(userMessage: msg);
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
            requestId: mapped.requestId,
            error: mapped,
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
    if (code == 'AWMC_OAUTH_REQUIRED') {
      return 'AWMC 论坛授权已失效或尚未完成，请前往「绑定与授权管理」重新通过 AWMC 论坛授权绑定';
    }
    final raw = decoded?['message']?.toString() ?? decoded?['error']?.toString();
    if (raw != null && raw.trim().isNotEmpty) {
      return AwmcApiService.redact(raw.trim());
    }
    return 'HTTP ${response.statusCode}';
  }

  static final RegExp _lxInvalidScoreRe = RegExp(
    r'invalid score \(id:\s*(\d+),\s*type:\s*([a-zA-Z_]+),\s*level_index:\s*(\d+)\)',
    caseSensitive: false,
  );

  static ({int id, String type, int levelIndex})? parseLxInvalidScore(
      String? message) {
    final match = _lxInvalidScoreRe.firstMatch(message ?? '');
    if (match == null) return null;
    final id = int.tryParse(match.group(1) ?? '');
    final levelIndex = int.tryParse(match.group(3) ?? '');
    if (id == null || levelIndex == null) return null;
    return (
      id: id,
      type: (match.group(2) ?? '').toLowerCase(),
      levelIndex: levelIndex,
    );
  }

  static String _lxScoreKey(Map<String, dynamic> item) =>
      '${item['id']}/${(item['type'] ?? '').toString().toLowerCase()}/${item['level_index']}';

  static int? _findLxInvalidIndex(
    List<Map<String, dynamic>> pending,
    int badId,
    String badType,
    int badLevel,
  ) {
    final normalizedType = badType.toLowerCase();
    for (var i = 0; i < pending.length; i++) {
      final item = pending[i];
      if (item['id'] == badId &&
          (item['type'] ?? '').toString().toLowerCase() == normalizedType &&
          item['level_index'] == badLevel) {
        return i;
      }
    }
    if (normalizedType != 'dx') return null;
    for (var i = 0; i < pending.length; i++) {
      final item = pending[i];
      if ((item['type'] ?? '').toString().toLowerCase() != 'dx' ||
          item['level_index'] != badLevel) {
        continue;
      }
      final id = item['id'] as int?;
      final rawId = item['_raw_music_id'] as int?;
      if (id == null) continue;
      final variants = <int>{
        id,
        if (rawId != null && rawId > 0) rawId,
        id >= 10000 ? id % 10000 : id + 10000,
      };
      if (variants.contains(badId)) return i;
    }
    return null;
  }

  static Map<String, dynamic>? _dxRawIdFallback(Map<String, dynamic> item) {
    if ((item['type'] ?? '').toString().toLowerCase() != 'dx') return null;
    final id = item['id'] as int?;
    if (id == null || id <= 0) return null;
    final rawId = item['_raw_music_id'] as int?;
    final int? altId = (rawId != null && rawId >= 10000)
        ? rawId
        : (id < 10000 ? id + 10000 : null);
    if (altId == null || altId == id) return null;
    return {...item, 'id': altId};
  }

  static List<Map<String, dynamic>> _stripLxPrivateFields(
          List<Map<String, dynamic>> items) =>
      items
          .map((item) => {
                for (final entry in item.entries)
                  if (!entry.key.startsWith('_')) entry.key: entry.value,
              })
          .toList(growable: false);

  /// 落雪单批上传并自愈 `invalid score`：DX 优先尝试 Sega 原始 ID 回退一次，
  /// 仍被拒时仅剔除该条记入跳过并续传同批其余成绩，避免单曲差异拖垮整批。
  static Future<({int submitted, int skipped})> uploadLxBatchWithRepair(
    List<Map<String, dynamic>> initialBatch, {
    required Future<http.Response> Function(List<Map<String, dynamic>> wire)
        send,
    required DateTime deadline,
    void Function(http.Response response, Map<String, dynamic>? decoded)?
        onFatalError,
  }) async {
    final pending = [for (final item in initialBatch) Map<String, dynamic>.from(item)];
    final triedAlt = <String>{};
    var skipped = 0;
    var repairs = 0;
    final maxRepairs = pending.length * 2 > 40 ? pending.length * 2 : 40;

    while (pending.isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        throw AppError(
          code: 'SRV-LXNS-TIMEOUT',
          userMessage: appL10n.flowRequestTimedOutP0S('120'),
          stage: '上传成绩至落雪',
          source: 'luoxue',
        ).asStateError();
      }
      final response = await send(_stripLxPrivateFields(pending));
      Map<String, dynamic>? decoded;
      try {
        final raw = json.decode(utf8.decode(response.bodyBytes));
        if (raw is Map) decoded = Map<String, dynamic>.from(raw);
      } catch (_) {}

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          decoded != null &&
          decoded['success'] == true) {
        return (submitted: pending.length, skipped: skipped);
      }

      if (response.statusCode == 400 || response.statusCode == 422) {
        final detail =
            decoded?['message']?.toString() ?? decoded?['error']?.toString();
        final invalid = parseLxInvalidScore(detail);
        if (invalid != null && repairs < maxRepairs) {
          final targetIdx = _findLxInvalidIndex(
            pending,
            invalid.id,
            invalid.type,
            invalid.levelIndex,
          );
          if (targetIdx != null) {
            final bad = pending[targetIdx];
            final alt = _dxRawIdFallback(bad);
            final badKey = _lxScoreKey(bad);
            final altKey = alt != null ? _lxScoreKey(alt) : null;
            if (alt != null &&
                altKey != null &&
                !triedAlt.contains(badKey) &&
                !triedAlt.contains(altKey)) {
              triedAlt.add(badKey);
              triedAlt.add(altKey);
              pending[targetIdx] = alt;
              repairs++;
              continue;
            }
            pending.removeAt(targetIdx);
            skipped++;
            repairs++;
            continue;
          }
        }
      }

      if (onFatalError != null) {
        onFatalError(response, decoded);
      }
      throw AppError(
        code: 'SRV-LXNS-UPLOAD',
        userMessage: appL10n.svcUploadToP0FailedHTTPP1Remaining(
          appLocalizeLabel(SyncPlatform.luoXue.label),
          response.statusCode.toString(),
        ),
        stage: '上传成绩至落雪',
        source: 'luoxue',
        httpStatus: response.statusCode,
        requestId: ApiClient.requestIdOf(response),
      ).asStateError();
    }

    return (submitted: 0, skipped: skipped);
  }

  /// 直接把解析好的机台成绩推送到落雪：OAuth (`write_player`) Bearer 优先，无 OAuth 时回退个人 API 密钥。
  static Future<({int submitted, int skipped})> uploadLxScores(
    List<AwmcParsedScore> scores, {
    void Function(double progress, String text)? onProgress,
  }) =>
      AppTaskActivity.run(() async {
        if (scores.isEmpty) {
          throw AppError(
            code: 'DATA-SYNC-NO-SCORES',
            userMessage: appL10n.svcNoValidScoresWereReadNothingWas,
            stage: '读取待上传成绩',
            source: 'luoxue',
          ).asStateError();
        }
        onProgress?.call(
            0.55,
            appL10n.flowCheckingChartsSupportedByP02(
                appLocalizeLabel(SyncPlatform.luoXue.label)));
        final supportedCharts = await _fetchLuoXueCharts();
        final payload = <Map<String, dynamic>>[];
        var skipped = 0;
        for (final score in scores) {
          if (!score.isUtage && !supportedCharts.contains(score.key)) {
            skipped++;
            continue;
          }
          payload.add({
            'id': score.isUtage ? score.songId : (score.songId % 10000),
            'type': score.isUtage
                ? 'utage'
                : (score.songId >= 10000 ? 'dx' : 'standard'),
            'level_index': score.levelIndex,
            'achievements': score.percent,
            'dx_score': score.dxScore,
            if (score.fc != null && score.fc!.isNotEmpty) 'fc': score.fc,
            if (score.fs != null && score.fs!.isNotEmpty) 'fs': score.fs,
            '_raw_music_id': score.songId,
          });
        }
        if (payload.isEmpty) {
          throw AppError(
            code: 'DATA-SYNC-NO-MATCH',
            userMessage: appL10n.svcNoValidScoresMatchedTheLocalSong,
            stage: '匹配落雪曲库',
            source: 'luoxue',
          ).asStateError();
        }

        var oauthToken = await LuoXueOAuthManager().getAccessToken();
        String? apiKey;
        var usingOAuth = oauthToken != null && oauthToken.isNotEmpty;
        if (!usingOAuth) {
          apiKey = (await SecureCredentialStore.read(
                  CacheKeyConstant.probeLxnsImportToken))
              ?.trim();
          if (apiKey == null || apiKey.isEmpty) {
            throw AppError(
              code: 'AUTH-LXNS-NOT-AUTHORIZED',
              userMessage: appL10n.svcYourLXNSAccountIsNotAuthorizedComplete,
              stage: '校验落雪同步授权',
              source: 'luoxue',
              suggestion: appL10n.errSuggestionReauth,
              retryable: false,
            ).asStateError();
          }
        }

        var retriedAuth = false;
        var submitted = 0;
        final deadline = DateTime.now().add(const Duration(seconds: 120));
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
          final batchRes = await uploadLxBatchWithRepair(
            batch,
            deadline: deadline,
            send: (wire) async {
              var response = await _postLxBatch(
                wire,
                oauthToken: usingOAuth ? oauthToken : null,
                apiKey: usingOAuth ? null : apiKey,
              );
              if (usingOAuth && response.statusCode == 401 && !retriedAuth) {
                retriedAuth = true;
                final refreshed = await LuoXueOAuthManager().refreshToken();
                if (refreshed != null && refreshed.accessToken.isNotEmpty) {
                  oauthToken = refreshed.accessToken;
                  response = await _postLxBatch(wire, oauthToken: oauthToken);
                }
              }
              return response;
            },
            onFatalError: (response, _) {
              if (response.statusCode == 401) {
                throw AppError(
                  code: 'AUTH-LXNS-EXPIRED',
                  userMessage: appL10n.svcLXNSAuthorizationExpiredOrTheKeyIs,
                  stage: '上传成绩至落雪',
                  source: 'luoxue',
                  httpStatus: 401,
                  requestId: ApiClient.requestIdOf(response),
                  suggestion: appL10n.errSuggestionReauth,
                  retryable: false,
                ).asStateError();
              }
              if (response.statusCode == 403) {
                throw AppError(
                  code: 'AUTH-LXNS-FORBIDDEN',
                  userMessage: appL10n
                      .svcLXNSRejectedThisWriteInsufficientPermissions,
                  stage: '上传成绩至落雪',
                  source: 'luoxue',
                  httpStatus: 403,
                  requestId: ApiClient.requestIdOf(response),
                  suggestion: appL10n.errSuggestionReauth,
                  retryable: false,
                ).asStateError();
              }
            },
          );
          submitted += batchRes.submitted;
          skipped += batchRes.skipped;
        }

        if (submitted == 0) {
          throw AppError(
            code: 'DATA-SYNC-NO-MATCH',
            userMessage: appL10n.svcNoValidScoresMatchedTheLocalSong,
            stage: '上传成绩至落雪',
            source: 'luoxue',
          ).asStateError();
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
      throw AppError(
        code: 'SRV-LXNS-SONG-LIST',
        userMessage: appL10n.svcCouldNotReadTheP0SongLibrary(
            appLocalizeLabel(SyncPlatform.luoXue.label)),
        stage: '读取落雪曲库',
        source: 'luoxue',
        httpStatus: response.statusCode != 200 ? response.statusCode : null,
        requestId: ApiClient.requestIdOf(response),
      ).asStateError();
    }
    final charts = <String>{};
    for (final song in data.whereType<Map>()) {
      final id = int.tryParse('${song['id']}');
      if (id == null || id <= 0) continue;
      final difficulties = song['difficulties'];
      if (difficulties is! Map) continue;
      for (final type in ['standard', 'dx', 'utage']) {
        final levels = difficulties[type];
        if (levels is! List) continue;
        final isUtage = type == 'utage';
        final dx = type == 'dx';
        final songId = !isUtage && dx && id < 10000 ? id + 10000 : id;
        for (final level in levels.whereType<Map>()) {
          final index = int.tryParse('${level['difficulty']}');
          if (index != null && ChartDifficulty.isStandard(index)) {
            charts.add('$songId/$index/${isUtage ? 'UTAGE' : (dx ? 'DX' : 'SD')}');
          }
        }
      }
    }
    if (charts.isEmpty) {
      throw AppError(
        code: 'DATA-LXNS-SONG-LIST-EMPTY',
        userMessage: appL10n.svcTheP0SongLibraryIsEmptyNo(
            appLocalizeLabel(SyncPlatform.luoXue.label)),
        stage: '校验落雪曲库',
        source: 'luoxue',
      ).asStateError();
    }
    return charts;
  }

  /// 检查水鱼写入授权（更新 `DivingFishOAuthManager` 状态）。
  static Future<bool?> checkFishWriteAuthorized(String qq) =>
      DivingFishOAuthManager().checkWriteAuthorization(qq);

  /// 使用已绑定的水鱼 OAuth 成绩一键初始化 AWMC NET 档案（服务端含水鱼打码拦截）。
  static Future<AwmcProfileMigrationResult> initAwmcProfileFromFish({
    required String awmcQq,
    required String fishQq,
  }) =>
      AppTaskActivity.run(() async {
        final uri = Uri.parse(ApiUrls.AwmcInitProfileUrl);
        try {
          final authHeaders = await _migrationAuthHeaders(awmcQq);
          final response = await ApiClient.post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              ...authHeaders,
            },
            body: json.encode({
              'source': 'fish',
              'awmcQq': awmcQq.trim(),
              'fishQq': fishQq.trim(),
            }),
            timeout: _syncTimeout,
          );
          Map<String, dynamic>? decoded;
          try {
            final raw = json.decode(utf8.decode(response.bodyBytes));
            if (raw is Map) decoded = Map<String, dynamic>.from(raw);
          } catch (_) {}
          if (response.statusCode >= 200 &&
              response.statusCode < 300 &&
              decoded?['ok'] == true) {
            final awmc = decoded!['awmc'] is Map
                ? Map<String, dynamic>.from(decoded['awmc'] as Map)
                : const <String, dynamic>{};
            return AwmcProfileMigrationResult(
              ok: true,
              totalRecords: (awmc['totalRecords'] as num?)?.toInt() ??
                  (decoded['scoreCount'] as num?)?.toInt() ??
                  0,
              imported: (awmc['imported'] as num?)?.toInt() ?? 0,
              updated: (awmc['updated'] as num?)?.toInt() ?? 0,
              skipped: (awmc['skipped'] as num?)?.toInt() ?? 0,
            );
          }
          final code = decoded?['code']?.toString();
          return AwmcProfileMigrationResult(
            ok: false,
            code: code,
            message: _formatError(response, decoded, code),
          );
        } catch (e) {
          return AwmcProfileMigrationResult(
            ok: false,
            message: AwmcApiService.redact('$e'),
          );
        }
      });

  /// 使用已授权的落雪成绩一键初始化 AWMC NET 档案。
  static Future<AwmcProfileMigrationResult> initAwmcProfileFromLuoXue({
    required String awmcQq,
  }) =>
      AppTaskActivity.run(() async {
        try {
          var oauthToken = await LuoXueOAuthManager().getAccessToken();
          String? apiKey;
          final usingOAuth = oauthToken != null && oauthToken.isNotEmpty;
          if (!usingOAuth) {
            apiKey = (await SecureCredentialStore.read(
                    CacheKeyConstant.probeLxnsImportToken))
                ?.trim();
            if (apiKey == null || apiKey.isEmpty) {
              return AwmcProfileMigrationResult(
                ok: false,
                code: 'AUTH_LXNS_NOT_AUTHORIZED',
                message: appL10n.svcYourLXNSAccountIsNotAuthorizedComplete,
              );
            }
          }
          Future<http.Response> fetchScores({String? bearer}) => ApiClient.get(
                Uri.parse(ApiUrls.LuoXuePlayerScoresApi),
                headers: {
                  'Accept': 'application/json',
                  if (bearer != null)
                    'Authorization': 'Bearer $bearer'
                  else if (apiKey != null)
                    'X-User-Token': apiKey,
                },
                timeout: const Duration(seconds: 45),
              );
          var scoreRes =
              await fetchScores(bearer: usingOAuth ? oauthToken : null);
          if (usingOAuth && scoreRes.statusCode == 401) {
            final refreshed = await LuoXueOAuthManager().refreshToken();
            if (refreshed != null && refreshed.accessToken.isNotEmpty) {
              oauthToken = refreshed.accessToken;
              scoreRes = await fetchScores(bearer: oauthToken);
            }
          }
          if (scoreRes.statusCode != 200) {
            return AwmcProfileMigrationResult(
              ok: false,
              code: 'LXNS_READ_FAILED',
              message: '读取落雪成绩失败（HTTP ${scoreRes.statusCode}）',
            );
          }
          dynamic decodedScores;
          try {
            decodedScores = json.decode(utf8.decode(scoreRes.bodyBytes));
          } catch (_) {}
          for (var i = 0; i < 4 && decodedScores is Map; i++) {
            if (decodedScores['success'] == false) break;
            decodedScores = decodedScores['data'] ??
                decodedScores['records'] ??
                decodedScores['scores'];
          }
          if (decodedScores is! List || decodedScores.isEmpty) {
            return const AwmcProfileMigrationResult(
              ok: false,
              code: 'EMPTY_SOURCE_SCORES',
              message: '落雪账号暂无可迁移的成绩记录',
            );
          }

          final awmcAuthHeaders = await _awmcAuthHeaders(awmcQq);
          final response = await ApiClient.post(
            Uri.parse(ApiUrls.AwmcInitProfileUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              ...awmcAuthHeaders,
            },
            body: json.encode({
              'source': 'lx',
              'awmcQq': awmcQq.trim(),
              'records': decodedScores,
            }),
            timeout: _syncTimeout,
          );
          Map<String, dynamic>? decoded;
          try {
            final raw = json.decode(utf8.decode(response.bodyBytes));
            if (raw is Map) decoded = Map<String, dynamic>.from(raw);
          } catch (_) {}
          if (response.statusCode >= 200 &&
              response.statusCode < 300 &&
              decoded?['ok'] == true) {
            final awmc = decoded!['awmc'] is Map
                ? Map<String, dynamic>.from(decoded['awmc'] as Map)
                : const <String, dynamic>{};
            return AwmcProfileMigrationResult(
              ok: true,
              totalRecords: (awmc['totalRecords'] as num?)?.toInt() ??
                  (decoded['scoreCount'] as num?)?.toInt() ??
                  0,
              imported: (awmc['imported'] as num?)?.toInt() ?? 0,
              updated: (awmc['updated'] as num?)?.toInt() ?? 0,
              skipped: (awmc['skipped'] as num?)?.toInt() ?? 0,
            );
          }
          final code = decoded?['code']?.toString();
          return AwmcProfileMigrationResult(
            ok: false,
            code: code,
            message: _formatError(response, decoded, code),
          );
        } catch (e) {
          return AwmcProfileMigrationResult(
            ok: false,
            message: AwmcApiService.redact('$e'),
          );
        }
      });

  /// 反向迁移：将 AWMC NET 已有成绩一次性写入新授权的水鱼账号。
  static Future<AwmcProfileMigrationResult> migrateAwmcToFish({
    required String awmcQq,
    required String fishQq,
  }) =>
      AppTaskActivity.run(() async {
        try {
          final authHeaders = await _migrationAuthHeaders(awmcQq);
          final response = await ApiClient.post(
            Uri.parse(ApiUrls.AwmcMigrateToFishUrl),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              ...authHeaders,
            },
            body: json.encode({
              'awmcQq': awmcQq.trim(),
              'fishQq': fishQq.trim(),
            }),
            timeout: _syncTimeout,
          );
          Map<String, dynamic>? decoded;
          try {
            final raw = json.decode(utf8.decode(response.bodyBytes));
            if (raw is Map) decoded = Map<String, dynamic>.from(raw);
          } catch (_) {}
          if (response.statusCode >= 200 &&
              response.statusCode < 300 &&
              decoded?['ok'] == true) {
            final fish = decoded!['fish'] is Map
                ? Map<String, dynamic>.from(decoded['fish'] as Map)
                : const <String, dynamic>{};
            return AwmcProfileMigrationResult(
              ok: true,
              totalRecords: (fish['submitted'] as num?)?.toInt() ?? 0,
              imported: (fish['creates'] as num?)?.toInt() ?? 0,
              updated: (fish['updates'] as num?)?.toInt() ?? 0,
              skipped: (fish['skipped'] as num?)?.toInt() ?? 0,
            );
          }
          final code = decoded?['code']?.toString();
          return AwmcProfileMigrationResult(
            ok: false,
            code: code,
            message: _formatError(response, decoded, code),
          );
        } catch (e) {
          return AwmcProfileMigrationResult(
            ok: false,
            message: AwmcApiService.redact('$e'),
          );
        }
      });

  /// 反向迁移：读取 AWMC NET 已有成绩并一次性推送至新授权的落雪账号。
  static Future<AwmcProfileMigrationResult> migrateAwmcToLuoXue({
    required String awmcQq,
    void Function(double progress, String text)? onProgress,
  }) =>
      AppTaskActivity.run(() async {
        try {
          onProgress?.call(0.1, '正在读取 AWMC NET 已有成绩…');
          final uri = Uri.parse(ApiUrls.AwmcNetRecordsProxyApi)
              .replace(queryParameters: {'qq': awmcQq.trim()});
          final res = await ApiClient.get(
            uri,
            headers: const {'Accept': 'application/json'},
            timeout: const Duration(seconds: 45),
          );
          if (res.statusCode == 404) {
            return const AwmcProfileMigrationResult(
              ok: false,
              code: 'AWMC_NET_TARGET_NOT_FOUND',
              message: '未在 AWMC NET 找到该 QQ 的成绩记录',
            );
          }
          if (res.statusCode != 200) {
            return AwmcProfileMigrationResult(
              ok: false,
              code: 'AWMC_NET_READ_FAILED',
              message: '读取 AWMC NET 成绩失败（HTTP ${res.statusCode}）',
            );
          }
          dynamic decoded;
          try {
            decoded = json.decode(utf8.decode(res.bodyBytes));
          } catch (_) {}
          final rawList = decoded is Map
              ? (decoded['records'] ?? decoded['data'])
              : decoded;
          if (rawList is! List || rawList.isEmpty) {
            return const AwmcProfileMigrationResult(
              ok: false,
              code: 'EMPTY_SOURCE_SCORES',
              message: 'AWMC NET 档案暂无可迁移的成绩记录',
            );
          }
          final scores = <AwmcParsedScore>[];
          for (final item in rawList.whereType<Map>()) {
            final songId = int.tryParse('${item['song_id'] ?? item['id']}');
            final rawLevel = int.tryParse('${item['level_index']}');
            final achNum = num.tryParse('${item['achievements']}');
            if (songId == null ||
                songId <= 0 ||
                rawLevel == null ||
                achNum == null ||
                achNum <= 0) {
              continue;
            }
            final levelIndex =
                (songId >= 100000 && rawLevel == 10) ? 0 : rawLevel;
            if (levelIndex < 0 || levelIndex > 4) continue;
            final dxScore =
                int.tryParse('${item['dxScore'] ?? item['dx_score'] ?? 0}') ??
                    0;
            final fc = item['fc']?.toString().trim();
            final fs = item['fs']?.toString().trim();
            scores.add(AwmcParsedScore(
              songId: songId,
              levelIndex: levelIndex,
              achievement: (achNum * 10000).round(),
              dxScore: dxScore < 0 ? 0 : dxScore,
              fc: fc != null && fc.isNotEmpty ? fc : null,
              fs: fs != null && fs.isNotEmpty ? fs : null,
            ));
          }
          if (scores.isEmpty) {
            return const AwmcProfileMigrationResult(
              ok: false,
              code: 'EMPTY_SOURCE_SCORES',
              message: 'AWMC NET 档案暂无有效谱面成绩',
            );
          }
          final uploadRes = await uploadLxScores(scores, onProgress: onProgress);
          return AwmcProfileMigrationResult(
            ok: true,
            totalRecords: uploadRes.submitted,
            imported: uploadRes.submitted,
            skipped: uploadRes.skipped,
          );
        } catch (e) {
          return AwmcProfileMigrationResult(
            ok: false,
            message: AwmcApiService.redact('$e'),
          );
        }
      });
}

class AwmcProfileMigrationResult {
  final bool ok;
  final int totalRecords;
  final int imported;
  final int updated;
  final int skipped;
  final String? code;
  final String? message;

  const AwmcProfileMigrationResult({
    required this.ok,
    this.totalRecords = 0,
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    this.code,
    this.message,
  });
}
