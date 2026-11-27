import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/CacheKeyConstant.dart';
import '../../widgets/AppToast.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcGatewaySettings.dart';
import '../../service/AWMC/AwmcQrSyncService.dart';
import '../../service/AWMC/AwmcQuickSyncService.dart';
import '../../service/AWMC/AwmcStore.dart';
import '../../service/Sync/AwmcNetScoreUploadService.dart';
import '../../service/Sync/PostSyncRefreshService.dart';
import '../../service/Sync/SyncStatsService.dart';
import '../../utils/SecureCredentialStore.dart';
import '../../utils/SyncRouteNotifier.dart';
import '../../widgets/AccountAuthorizationDialog.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/RefreshDataDialog.dart'
    show RefreshDataSource, SharedRefreshData;
import 'SyncToAwmcNetPage.dart'
    show showAwmcNetSyncInputDialog, AwmcNetSyncInput;

/// 一次「同步成绩到 AWMC NET」的结果。
class AwmcNetSyncOutcome {
  final bool quickUpdate;

  /// 用户在输入阶段取消（没有发出任何请求，不计入统计）。
  final bool cancelled;

  /// 同步接口是否成功。
  final bool ok;

  /// 接口统计结果（取消时为 null）。
  final AwmcNetQrImportResult? result;
  final String? refreshError;

  const AwmcNetSyncOutcome({
    this.quickUpdate = false,
    this.cancelled = false,
    this.ok = false,
    this.result,
    this.refreshError,
  });

  static const AwmcNetSyncOutcome userCancelled =
      AwmcNetSyncOutcome(cancelled: true);
}

/// 「同步成绩到 AWMC NET」的完整流程：输入在对话框、等待进度在按钮上。
class AwmcNetSyncFlow {
  AwmcNetSyncFlow._();

  static Future<AwmcNetSyncOutcome> run(
    BuildContext context, {
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    var qq = await AwmcQrSyncService.resolveAwmcNetQq();
    if (qq == null || !AwmcQrSyncService.qqPattern.hasMatch(qq)) {
      if (!context.mounted) return AwmcNetSyncOutcome.userCancelled;
      final goBind = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppAlertDialog(
          title: Text(ctx.l10n.accountLinkAWMC),
          content: Text(ctx.l10n.flowAWMCNETQQNoTokenHint),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(ctx.l10n.featureCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(ctx.l10n.accountLinkAWMC),
            ),
          ],
        ),
      );
      if (goBind != true || !context.mounted) {
        return AwmcNetSyncOutcome.userCancelled;
      }
      await showAccountAuthorizationDialog(context, luoxue: false);
      if (!context.mounted) return AwmcNetSyncOutcome.userCancelled;
      qq = await AwmcQrSyncService.resolveAwmcNetQq();
      if (qq == null || !AwmcQrSyncService.qqPattern.hasMatch(qq)) {
        return AwmcNetSyncOutcome.userCancelled;
      }
    }

    final input = await showAwmcNetSyncInputDialog(context, boundQq: qq);
    if (input == null) return AwmcNetSyncOutcome.userCancelled;

    return runWithInput(input,
        onBusy: onBusy, onProgress: onProgress, onIdle: onIdle);
  }

  /// 使用已经收集好的输入执行同步；支持传入 [prefetchedQrSync] 供「同步成绩到多端」单码复用。
  static Future<AwmcNetSyncOutcome> runWithInput(
    AwmcNetSyncInput input, {
    AwmcQrSyncResponse? prefetchedQrSync,
    SharedRefreshData? sharedRefresh,
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    final refresh = await PostSyncRefreshOperation.capture(
        RefreshDataSource.awmc,
        request: input.refreshRequest);
    if (input.quickUpdate) {
      try {
        final result = await AwmcQuickSyncService.run(
          platform: SyncPlatform.awmc,
          onProgress: (p, text) {
            onBusy?.call(text);
            onProgress?.call(p, text);
          },
        );
        final refreshError = await refresh.run(
            sharedRefresh: sharedRefresh,
            onProgress: (p, text) {
              onBusy?.call(text);
              onProgress?.call(.7 + p * .003, text);
            });
        return AwmcNetSyncOutcome(
            ok: true,
            quickUpdate: true,
            refreshError: refreshError,
            result: AwmcNetQrImportResult(
                ok: true, totalRecords: result.submitted));
      } catch (error) {
        return AwmcNetSyncOutcome(
            result: AwmcNetQrImportResult.failure('$error'));
      } finally {
        onIdle?.call();
      }
    }

    final attempt = SyncAttemptTracker(
      line: SyncLine.direct,
      platform: SyncPlatform.awmc,
    );
    attempt.start();

    var waited = 0;
    onBusy?.call(_busyLabel(0));
    final ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      waited++;
      onBusy?.call(_busyLabel(waited));
    });

    try {
      final AwmcNetQrImportResult result;
      final qq = input.qq.trim();
      final useBotSync =
          prefetchedQrSync != null || AwmcQrSyncService.qqPattern.hasMatch(qq);

      if (useBotSync) {
        AwmcQrSyncResponse? qrRes = prefetchedQrSync;
        if (qrRes == null) {
          final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
          final health =
              await AwmcApiService.health(token: '', timeout: probeTimeout);
          await AwmcAuditLog.record(health, note: '同步前的网关探活');
          if (!health.ok) {
            final msg = health.displayMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
            final short = msg.length <= 40 ? msg : '${msg.substring(0, 40)}…';
            result = AwmcNetQrImportResult.failure(
              appL10n.flowAWMCGatewayUnavailableP0SyncCancelledNo(short),
            );
            if (attempt.finish(ok: false)) {
              SyncRouteNotifier.instance.refreshStatsSoon();
            }
            return AwmcNetSyncOutcome(ok: false, result: result);
          }
          qrRes = await AwmcQrSyncService.syncByQr(
            qrCode: input.qr,
            awmcQq: qq,
          );
        }

        if (!qrRes.ok) {
          result = AwmcNetQrImportResult.failure(
            qrRes.errorMessage ?? appL10n.flowImportFailed,
            elapsedMs: qrRes.elapsedMs,
          );
        } else {
          final awmcRes = qrRes.awmc;
          if (awmcRes == null || !awmcRes.ok) {
            result = AwmcNetQrImportResult.failure(
              awmcRes?.message ?? qrRes.errorMessage ?? appL10n.flowImportFailed,
              elapsedMs: qrRes.elapsedMs,
            );
          } else {
            result = AwmcNetQrImportResult(
              ok: true,
              totalRecords: awmcRes.totalRecords,
              imported: awmcRes.imported,
              updated: awmcRes.updated,
              skipped: awmcRes.skipped,
              errors: awmcRes.errors,
              elapsedMs: qrRes.elapsedMs,
            );
          }
        }
      } else {
        result = await AwmcNetScoreUploadService.instance.importByQr(
          importToken: input.importToken,
          sgwcmaid: input.qr,
        );
        if (result.tokenInvalid) {
          await SecureCredentialStore.delete(
              CacheKeyConstant.awmcNetImportToken);
        }
      }

      if (attempt.finish(ok: result.ok)) {
        SyncRouteNotifier.instance.refreshStatsSoon();
      }
      String? refreshError;
      if (result.ok) {
        ticker.cancel();
        if (useBotSync && AwmcQrSyncService.qqPattern.hasMatch(qq)) {
          await _maybeNotifyFirstProfileCreated(qq);
        }
        refreshError = await refresh.run(
            sharedRefresh: sharedRefresh,
            onProgress: (p, text) {
              onBusy?.call(text);
              onProgress?.call(.7 + p * .003, text);
            });
      }
      return AwmcNetSyncOutcome(
        ok: result.ok,
        result: result,
        refreshError: refreshError,
      );
    } finally {
      ticker.cancel();
      onIdle?.call();
    }
  }

  static String _busyLabel(int seconds) =>
      appL10n.flowImportingScoresWaitingP0Seconds((seconds).toString());

  static Future<void> _maybeNotifyFirstProfileCreated(String qq) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final noticed = prefs
              .getStringList(CacheKeyConstant.awmcNetFirstProfileNoticedQqs) ??
          const <String>[];
      if (noticed.contains(qq)) return;
      await prefs.setStringList(
        CacheKeyConstant.awmcNetFirstProfileNoticedQqs,
        [...noticed, qq],
      );
      AppToast.show(
        '已自动在 AWMC NET 创建/同步档案，后续可用 QQ 邮箱登录 net.wmc.pub 查看',
        tone: AppToastTone.success,
      );
    } catch (_) {}
  }

  static String toastFor(AwmcNetSyncOutcome outcome) {
    final r = outcome.result;
    if (r == null) return appL10n.flowImportFailed;
    if (!r.ok) return r.errorMessage ?? appL10n.flowImportFailed;
    if (outcome.quickUpdate) {
      return r.totalRecords == 0
          ? appL10n.flowScoresAreUpToDateNoUpload
          : appL10n.flowQuickSyncCompleteSubmittedP0ChangedScores(
              (r.totalRecords).toString());
    }

    final seconds = (r.elapsedMs / 1000).toStringAsFixed(1);
    final buffer = StringBuffer(appL10n.flowImportCompleteAddedP0UpdatedP1(
        (r.imported).toString(), (r.updated).toString()));
    if (r.skipped > 0) {
      buffer.write(appL10n.flowSkippedP0((r.skipped).toString()));
    }
    buffer.write(appL10n.flowP0Seconds((seconds).toString()));
    if (r.errors.isNotEmpty) {
      buffer.write(
          appL10n.flowP0ChartsAreNotYetInAWMC((r.errors.length).toString()));
    }
    return buffer.toString();
  }
}
