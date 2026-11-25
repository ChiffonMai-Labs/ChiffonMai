import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/CacheKeyConstant.dart';
import '../../manager/DivingFish/DivingFishOAuthManager.dart';
import '../../manager/DivingFishProbeManager.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcGatewaySettings.dart';
import '../../service/AWMC/AwmcQrSyncService.dart';
import '../../service/AWMC/AwmcQuickSyncService.dart';
import '../../service/AWMC/AwmcStore.dart';
import '../../service/PostSyncRefreshService.dart';
import '../../service/SyncStatsService.dart';
import '../../utils/AppError.dart';
import '../../utils/SecureCredentialStore.dart';
import '../../widgets/AccountAuthorizationDialog.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/RefreshDataDialog.dart'
    show RefreshDataRequest, RefreshDataSource, SharedRefreshData;
import '../../widgets/SyncScoreDialogs.dart'
    show showDivingFishSyncInputDialog, showLuoXueSyncInputDialog;

/// 「通过 AWMC 网关同步成绩」的目标平台。
enum AwmcSyncTarget {
  /// 同步到水鱼 Diving-Fish（OAuth 免导入 Token）。
  divingFish(
    label: '水鱼',
    path: '/qr-sync',
    auditNote: '通过 AWMC 网关同步到水鱼',
  ),

  /// 同步到落雪 LXNS（OAuth 免个人 API 密钥）。
  luoXue(
    label: '落雪',
    path: '/qr-sync',
    auditNote: '通过 AWMC 网关同步到落雪',
  );

  const AwmcSyncTarget({
    required this.label,
    required this.path,
    required this.auditNote,
  });

  final String label;
  final String path;
  final String auditNote;

  int get syncCost => 4;
}

enum _FishWritePromptAction { cancel, authorize, useLegacy }

class _AwmcQrInput {
  final String qrCode;
  final RefreshDataRequest? refreshRequest;
  final bool quickUpdate;
  const _AwmcQrInput(this.qrCode, this.refreshRequest, this.quickUpdate);
}

/// 一次 AWMC 同步的结果。
class AwmcSyncOutcome {
  final bool quickUpdate;

  /// 用户中途取消（未发出任何请求）。
  final bool cancelled;

  /// 同步接口是否成功。
  final bool ok;

  final AwmcCallResult? syncResult;

  /// 本次提交的谱面条数。
  final int cachedRecords;

  /// 兼容旧版调用方的结果字段。普通同步已不再读取游玩次数，始终为 false。
  final bool playCountsRefreshed;

  /// 兼容旧版调用方的结果字段。普通同步已不再读取游玩次数，始终为 null。
  final String? readErrorMessage;

  final String? message;
  final String? refreshError;
  final AppError? error;

  const AwmcSyncOutcome({
    this.quickUpdate = false,
    this.cancelled = false,
    this.ok = false,
    this.syncResult,
    this.cachedRecords = 0,
    this.playCountsRefreshed = false,
    this.readErrorMessage,
    this.message,
    this.refreshError,
    this.error,
  });

  static const AwmcSyncOutcome userCancelled = AwmcSyncOutcome(cancelled: true);
}

/// 「同步成绩到水鱼 / 落雪」的 **线路1 · AWMC 网关** 实现（免导入 Token）。
///
/// 安全约束不变：二维码每次当场输入、用完即弃；写操作串行不自动重试；
/// 全程写审计日志。
class AwmcSyncFlow {
  AwmcSyncFlow._();

  /// 执行一次同步。会自行弹输入对话框 / 授权引导 / 结果反馈。
  static Future<AwmcSyncOutcome> run(
    BuildContext context, {
    required AwmcSyncTarget target,
    Future<bool> Function()? onMissingCredential,
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    String? fishQq;
    String? legacyFishToken;

    if (target == AwmcSyncTarget.divingFish) {
      fishQq = await AwmcQrSyncService.resolveDivingFishQq();
      if (fishQq == null && onMissingCredential != null) {
        final recovered = await onMissingCredential();
        if (!recovered || !context.mounted) return AwmcSyncOutcome.userCancelled;
        fishQq = await AwmcQrSyncService.resolveDivingFishQq();
      }
      if (fishQq == null) {
        legacyFishToken = await _resolveCredential(target);
        if (legacyFishToken == null) {
          if (context.mounted) {
            AppToast.show(_missingCredentialHint(target));
          }
          return AwmcSyncOutcome(message: _missingCredentialHint(target));
        }
      } else {
        final writeAuth =
            await AwmcQrSyncService.checkFishWriteAuthorized(fishQq);
        if (writeAuth == false) {
          final fallbackToken = await _resolveCredential(target);
          if (!context.mounted) return AwmcSyncOutcome.userCancelled;
          final action = await _promptFishWriteAuthorization(
            context,
            hasLegacyToken: fallbackToken != null,
          );
          if (!context.mounted || action == _FishWritePromptAction.cancel) {
            return AwmcSyncOutcome.userCancelled;
          }
          if (action == _FishWritePromptAction.authorize) {
            final opened = await DivingFishOAuthManager().openBindingLink(fishQq);
            if (context.mounted) {
              AppToast.show(
                opened
                    ? context.l10n.flowAuthorizationOpenedCompleteItInYourBrowser
                    : context.l10n.flowCouldNotStartAuthorizationTryAgain,
                tone: opened ? AppToastTone.success : AppToastTone.error,
              );
            }
            return AwmcSyncOutcome.userCancelled;
          }
          legacyFishToken = fallbackToken;
        }
      }
    } else {
      var hasLxAuth = await AwmcQrSyncService.hasLuoXueSyncAuth();
      if (!hasLxAuth) {
        if (!context.mounted) return AwmcSyncOutcome.userCancelled;
        final goAuthorize = await showDialog<bool>(
          context: context,
          builder: (ctx) => AppAlertDialog(
            title: Text(ctx.l10n.flowLuoXueRoute1AuthDialogTitle),
            content: Text(ctx.l10n.flowLuoXueRoute1AuthDialogBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(ctx.l10n.featureCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.l10n.accountAuthorizeLXNS),
              ),
            ],
          ),
        );
        if (goAuthorize != true || !context.mounted) {
          return AwmcSyncOutcome.userCancelled;
        }
        await showAccountAuthorizationDialog(context, luoxue: true);
        if (!context.mounted) return AwmcSyncOutcome.userCancelled;
        hasLxAuth = await AwmcQrSyncService.hasLuoXueSyncAuth();
        if (!hasLxAuth) return AwmcSyncOutcome.userCancelled;
      }
    }

    if (!context.mounted) return AwmcSyncOutcome.userCancelled;
    final gatewayError = await _checkGateway(onBusy: onBusy);
    onIdle?.call();
    if (gatewayError != null) return AwmcSyncOutcome(message: gatewayError);

    if (!context.mounted) return AwmcSyncOutcome.userCancelled;
    final input = await _askQrCode(context, target);
    if (input == null) return AwmcSyncOutcome.userCancelled;
    if (input.quickUpdate) {
      final refresh = await PostSyncRefreshOperation.capture(
          target == AwmcSyncTarget.divingFish
              ? RefreshDataSource.shuiyu
              : RefreshDataSource.luoxue,
          request: input.refreshRequest);
      onBusy?.call(appL10n.flowQuickSyncing);
      try {
        final result = await AwmcQuickSyncService.run(
          platform: target == AwmcSyncTarget.divingFish
              ? SyncPlatform.divingFish
              : SyncPlatform.luoXue,
          onProgress: (p, text) {
            onBusy?.call(text);
            onProgress?.call(p, text);
          },
        );
        final refreshError = await refresh.run(onProgress: (p, text) {
          onBusy?.call(text);
          onProgress?.call(.7 + p * .003, text);
        });
        return AwmcSyncOutcome(
            ok: true,
            quickUpdate: true,
            cachedRecords: result.submitted,
            refreshError: refreshError);
      } catch (error) {
        return AwmcSyncOutcome(message: '$error');
      } finally {
        onIdle?.call();
      }
    }
    return _executeWithInput(
      qrCode: input.qrCode,
      target: target,
      fishQq: fishQq,
      legacyFishToken: legacyFishToken,
      refreshRequest: input.refreshRequest,
      onBusy: onBusy,
      onProgress: onProgress,
      onIdle: onIdle,
    );
  }

  static Future<_FishWritePromptAction> _promptFishWriteAuthorization(
    BuildContext context, {
    required bool hasLegacyToken,
  }) async {
    final l10n = context.l10n;
    final chosen = await showDialog<_FishWritePromptAction>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(l10n.flowDivingFishWriteAuthDialogTitle),
        content: Text(hasLegacyToken
            ? l10n.flowDivingFishWriteAuthDialogBodyWithFallback
            : l10n.flowDivingFishWriteAuthDialogBody),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_FishWritePromptAction.cancel),
            child: Text(l10n.featureCancel),
          ),
          if (hasLegacyToken)
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(_FishWritePromptAction.useLegacy),
              child: Text(l10n.flowUseImportTokenFallback),
            ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_FishWritePromptAction.authorize),
            child: Text(l10n.flowOpenAuthorizationLink),
          ),
        ],
      ),
    );
    return chosen ?? _FishWritePromptAction.cancel;
  }

  /// toast 用的短原因：`displayMessage` 最多 600 字，整段塞进 toast 看不清。
  static String _shortReason(AwmcCallResult r) {
    final msg = r.displayMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
    const max = 40;
    return msg.length <= max ? msg : '${msg.substring(0, max)}…';
  }

  /// 多端同步复用已输入的二维码；支持直接传入单码读取到的 [prefetchedQrSync]。
  static Future<AwmcSyncOutcome> runWithInput({
    required String qrCode,
    required AwmcSyncTarget target,
    RefreshDataRequest? refreshRequest,
    SharedRefreshData? sharedRefresh,
    AwmcQrSyncResponse? prefetchedQrSync,
    String? fishQqOverride,
    bool allowLegacyFallback = true,
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    if (prefetchedQrSync == null && !qrCode.startsWith('SGWCMAID')) {
      return AwmcSyncOutcome(message: appL10n.flowInvalidCabinetLoginQRCode);
    }
    try {
      String? fishQq = fishQqOverride;
      String? legacyFishToken;

      if (prefetchedQrSync == null) {
        if (target == AwmcSyncTarget.divingFish) {
          fishQq ??= await AwmcQrSyncService.resolveDivingFishQq();
          if (fishQq == null) {
            legacyFishToken = allowLegacyFallback
                ? await _resolveCredential(target)
                : null;
            if (legacyFishToken == null) {
              return AwmcSyncOutcome(message: _missingCredentialHint(target));
            }
          } else {
            final writeAuth =
                await AwmcQrSyncService.checkFishWriteAuthorized(fishQq);
            if (writeAuth == false) {
              legacyFishToken = allowLegacyFallback
                  ? await _resolveCredential(target)
                  : null;
              if (legacyFishToken == null) {
                return AwmcSyncOutcome(
                    message: appL10n.flowDivingFishWriteConsentRequiredMessage);
              }
            }
          }
        } else {
          if (!await AwmcQrSyncService.hasLuoXueSyncAuth()) {
            return AwmcSyncOutcome(message: _missingCredentialHint(target));
          }
        }

        final gatewayError = await _checkGateway(onBusy: onBusy);
        if (gatewayError != null) return AwmcSyncOutcome(message: gatewayError);
      }

      return await _executeWithInput(
        qrCode: qrCode,
        target: target,
        fishQq: fishQq,
        legacyFishToken: legacyFishToken,
        prefetchedQrSync: prefetchedQrSync,
        refreshRequest: refreshRequest,
        sharedRefresh: sharedRefresh,
        onBusy: onBusy,
        onProgress: onProgress,
      );
    } finally {
      onIdle?.call();
    }
  }

  static Future<String?> _checkGateway({
    void Function(String label)? onBusy,
  }) async {
    onBusy?.call(appL10n.flowCheckingAWMCGateway);
    final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
    final health = await AwmcApiService.health(
      token: '',
      timeout: probeTimeout,
    );
    await AwmcAuditLog.record(health, note: '同步前的网关探活');
    if (health.ok) return null;
    debugPrint('[AWMC] 网关探活失败，已取消同步: ${health.displayMessage}');
    return appL10n.flowAWMCGatewayUnavailableP0SyncCancelledNo(
        (_shortReason(health)).toString());
  }

  static Future<AwmcSyncOutcome> _executeWithInput({
    required String qrCode,
    required AwmcSyncTarget target,
    String? fishQq,
    String? legacyFishToken,
    AwmcQrSyncResponse? prefetchedQrSync,
    RefreshDataRequest? refreshRequest,
    SharedRefreshData? sharedRefresh,
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    final refresh = await PostSyncRefreshOperation.capture(
        target == AwmcSyncTarget.divingFish
            ? RefreshDataSource.shuiyu
            : RefreshDataSource.luoxue,
        request: refreshRequest);

    final stopwatch = Stopwatch()..start();
    var ok = false;
    var count = 0;
    String? errorMsg;
    AppError? structuredError;
    AwmcCallResult? legacyResult;

    onBusy?.call(appL10n
        .flowSyncingToP0ThroughAWMCGateway(appLocalizeLabel(target.label)));

    if (target == AwmcSyncTarget.divingFish) {
      if (legacyFishToken != null && prefetchedQrSync == null) {
        legacyResult = await AwmcApiService.updateFish(
          token: '',
          qrcode: qrCode,
          fishToken: legacyFishToken,
        );
        await AwmcAuditLog.record(legacyResult, note: '通过 AWMC 网关推送到水鱼');
        ok = legacyResult.ok;
        if (!ok) {
          errorMsg = legacyResult.displayMessage;
          structuredError = AppError(
            code: 'SYNC-AWMC-LEGACY-FISH',
            title: appL10n.featureSyncFailed,
            stage: 'AWMC 网关写入水鱼',
            source: 'shuiyu',
            httpStatus: legacyResult.httpStatus,
            userMessage: errorMsg,
          );
        }
      } else {
        final qrRes = prefetchedQrSync ??
            await AwmcQrSyncService.syncByQr(
              qrCode: qrCode,
              fishQq: fishQq,
            );
        if (!qrRes.ok) {
          ok = false;
          errorMsg = qrRes.errorMessage ?? appL10n.featureSyncFailed;
          structuredError = qrRes.error ??
              AppError(
                code: 'SYNC-QR-FAILED',
                title: appL10n.featureSyncFailed,
                stage: 'AWMC 单码同步',
                source: 'shuiyu',
                httpStatus: qrRes.httpStatus > 0 ? qrRes.httpStatus : null,
                requestId: qrRes.requestId,
                userMessage: errorMsg,
              );
        } else {
          final fishRes = qrRes.fish;
          if (fishRes != null && fishRes.ok) {
            ok = true;
            count = fishRes.submitted;
          } else {
            ok = false;
            errorMsg = fishRes?.message ??
                qrRes.errorMessage ??
                appL10n.featureSyncFailed;
            structuredError = AppError(
              code: fishRes?.code != null
                  ? 'SYNC-${fishRes!.code}'
                  : 'SYNC-FISH-TARGET',
              title: appL10n.featureSyncFailed,
              stage: 'AWMC 同步写入水鱼',
              source: 'shuiyu',
              httpStatus: fishRes?.httpStatus,
              requestId: qrRes.requestId,
              userMessage: errorMsg,
            );
          }
        }
      }
    } else {
      try {
        final qrRes = prefetchedQrSync ??
            await AwmcQrSyncService.syncByQr(
              qrCode: qrCode,
              includeLx: true,
            );
        if (!qrRes.ok) {
          ok = false;
          errorMsg = qrRes.errorMessage ?? appL10n.featureSyncFailed;
          structuredError = qrRes.error ??
              AppError(
                code: 'SYNC-QR-FAILED',
                title: appL10n.featureSyncFailed,
                stage: 'AWMC 单码同步',
                source: 'luoxue',
                httpStatus: qrRes.httpStatus > 0 ? qrRes.httpStatus : null,
                requestId: qrRes.requestId,
                userMessage: errorMsg,
              );
        } else {
          final uploadRes = await AwmcQrSyncService.uploadLxScores(
            qrRes.lxScores,
            onProgress: (p, text) {
              onBusy?.call(text);
              onProgress?.call(p, text);
            },
          );
          ok = true;
          count = uploadRes.submitted;
        }
      } catch (e, stack) {
        ok = false;
        structuredError = AppErrorMapper.from(
          e,
          stack: stack,
          title: appL10n.featureSyncFailed,
          stage: 'AWMC 同步写入落雪',
          source: 'luoxue',
        );
        errorMsg = structuredError.userMessage;
      }
    }

    stopwatch.stop();
    String? refreshError;
    if (ok) {
      refreshError = await refresh.run(
          sharedRefresh: sharedRefresh,
          onProgress: (p, text) {
            onBusy?.call(text);
            onProgress?.call(.7 + p * .003, text);
          });
    }
    onIdle?.call();

    unawaited(SyncStatsService.record(
      line: SyncLine.awmc,
      platform: target == AwmcSyncTarget.divingFish
          ? SyncPlatform.divingFish
          : SyncPlatform.luoXue,
      durationMs: stopwatch.elapsedMilliseconds,
      ok: ok,
    ));

    return AwmcSyncOutcome(
      ok: ok,
      syncResult: legacyResult,
      cachedRecords: count,
      message: ok ? null : appL10n.flowSyncFailedP0((errorMsg ?? '').toString()),
      refreshError: refreshError,
      error: ok ? null : structuredError,
    );
  }

  /// 同步成功后的小提示文案（与线路2 的口径一致）。
  static String successToast(AwmcSyncTarget target, AwmcSyncOutcome outcome) {
    if (outcome.quickUpdate) {
      return outcome.cachedRecords == 0
          ? appL10n.flowP0ScoresAreUpToDateNo(appLocalizeLabel(target.label))
          : appL10n.flowQuickSyncCompleteSubmittedP1ChangedScores(
              appLocalizeLabel(target.label),
              (outcome.cachedRecords).toString());
    }
    final prefix = outcome.cachedRecords > 0
        ? appL10n.flowP0ScoresTotal((outcome.cachedRecords).toString())
        : appL10n.featureScores;
    final suffix = target == AwmcSyncTarget.divingFish
        ? appL10n.flowSentToDivingFishThroughAWMCGateway
        : appL10n.flowExportedToLXNSThroughAWMCGateway;
    return appL10n.flowSyncCompleteP0P1(
        (prefix).toString(), (suffix).toString());
  }

  /// 复用输入对话框，仅线路1开放免二维码快速同步与 OAuth 免密钥。
  static Future<_AwmcQrInput?> _askQrCode(
    BuildContext context,
    AwmcSyncTarget target,
  ) async {
    if (target == AwmcSyncTarget.divingFish) {
      final input =
          await showDivingFishSyncInputDialog(context, allowQuickUpdate: true);
      return input == null
          ? null
          : _AwmcQrInput(input.qrCode, input.refreshRequest, input.quickUpdate);
    }
    final input = await showLuoXueSyncInputDialog(
      context,
      allowQuickUpdate: true,
      allowOAuth: true,
    );
    return input == null
        ? null
        : _AwmcQrInput(input.qrCode, input.refreshRequest, input.quickUpdate);
  }

  /// 取本机缓存的传统导入凭据（用于旧账号暂无 OAuth 写权限时的可选回退）。
  static Future<String?> _resolveCredential(AwmcSyncTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    if (target == AwmcSyncTarget.divingFish) {
      final cached =
          await DivingFishProbeManager().getCachedDivingFishImportToken();
      if (cached != null && cached.isNotEmpty) return cached;
      final again =
          prefs.getString(CacheKeyConstant.probeDivingFishImportToken);
      return (again == null || again.isEmpty) ? null : again;
    }
    final secure = await SecureCredentialStore.read(
      CacheKeyConstant.probeLxnsImportToken,
    );
    if (secure != null && secure.isNotEmpty) return secure;
    final legacy = prefs.getString(CacheKeyConstant.probeLxnsImportToken);
    if (legacy != null && legacy.isNotEmpty) {
      await SecureCredentialStore.write(
        CacheKeyConstant.probeLxnsImportToken,
        legacy,
      );
      await prefs.remove(CacheKeyConstant.probeLxnsImportToken);
      return legacy;
    }
    return null;
  }

  static String _missingCredentialHint(AwmcSyncTarget target) {
    if (target == AwmcSyncTarget.divingFish) {
      return appL10n.flowNoDivingFishQqBoundHint;
    }
    return appL10n.svcYourLXNSAccountIsNotAuthorizedComplete;
  }
}
