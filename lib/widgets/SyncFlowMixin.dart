import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../page/Awmc/AwmcSyncFlow.dart';
import '../page/Awmc/AwmcUi.dart';
import '../page/AwmcNet/AwmcNetSyncFlow.dart';
import '../page/AwmcNet/SyncToAwmcNetPage.dart' show AwmcNetSyncInput;
import '../service/SyncStatsService.dart';
import '../service/MultiScoreSyncRunner.dart';
import '../service/PostSyncRefreshService.dart';
import '../service/AWMC/AwmcApiService.dart';
import '../service/AWMC/AwmcGatewaySettings.dart';
import '../service/AWMC/AwmcQrSyncService.dart';
import '../service/AWMC/AwmcQuickIdentityStore.dart';
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../service/AWMC/AwmcStore.dart';
import '../utils/SyncRouteNotifier.dart';
import '../utils/AppTaskActivity.dart';
import 'RefreshDataDialog.dart' show SharedRefreshData;
import '../utils/SecureCredentialStore.dart';
import 'SyncScoreDialogs.dart'
    show SyncCallbacks, SyncFlowException, SyncScoreDialogs;
import 'ErrorMessageDialog.dart';
import 'ConfettiEffect.dart';
import 'MultiScoreSyncDialog.dart' show showMultiScoreSyncInputDialog;
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 「同步成绩到水鱼 / 落雪 / AWMC NET」三个入口的**按钮上进度**编排。
///
/// ## 为什么要有这个 mixin
///
/// 「系统」hub 页显示各平台同步入口与统计页脚（[SyncStatsFooter]），
/// 首页搜索与收藏区通过回调委托给同一份执行器与互斥状态，保证行为完全一致。
///
/// ## 交互约定（三个入口一致）
///
/// * **需要用户输入的部分**（二维码 / 机台身份）走对话框；
/// * **耗时等待**（抓取 → 推送 → 刷新本地数据）期间对话框立即关闭，
///   进度以 `loadingText` 打在**按钮**上，不锁整页。
mixin SyncFlowMixin<T extends StatefulWidget> on State<T> {
  // ===== 按钮上进度显示所需的状态 =====
  bool _syncingDivingFish = false;
  String _syncText = '';
  bool _syncingLuoXue = false;
  String _luoXueText = '';
  bool _syncingAwmcNet = false;
  String _awmcNetText = '';
  bool _syncingMulti = false;
  String _multiSyncText = '';
  double? _divingFishProgress;
  double? _luoXueProgress;
  double? _awmcNetProgress;
  double? _multiSyncProgress;

  double? get divingFishProgress => _divingFishProgress;
  double? get luoXueProgress => _luoXueProgress;
  double? get awmcNetProgress => _awmcNetProgress;
  double? get multiSyncProgress => _multiSyncProgress;

  /// 水鱼按钮：进行中。
  bool get syncingDivingFish => _syncingDivingFish;

  /// 水鱼按钮：进度文案。
  String get syncText => _syncText;

  /// 落雪按钮：进行中。
  bool get syncingLuoXue => _syncingLuoXue;

  /// 落雪按钮：进度文案。
  String get luoXueText => _luoXueText;

  /// AWMC NET 按钮：进行中。
  bool get syncingAwmcNet => _syncingAwmcNet;

  /// AWMC NET 按钮：进度文案。
  String get awmcNetText => _awmcNetText;

  bool get syncingMulti => _syncingMulti;
  String get multiSyncText => _multiSyncText;

  /// 三个同步入口是否都空闲。
  ///
  /// 宿主页面可以把它并进自己更宽的「任意长任务进行中」判断里
  /// （「系统」hub 页还有刷新数据、刷新 maidata 等任务）。
  bool get syncFlowsIdle =>
      !_syncingDivingFish &&
      !_syncingLuoXue &&
      !_syncingAwmcNet &&
      !_syncingMulti;

  /// 四个同步入口中是否有任意一个正在执行。
  bool get anySyncBusy => !syncFlowsIdle;

  /// 任意长任务进行中：用于禁用其它入口，避免并发操作互相踩缓存。
  ///
  /// 由宿主页面实现 —— 各页面的长任务集合不同。
  bool get anyBusy;

  /// 同步流程回调（QQ 落盘 / 同步后刷新本地数据 / 登录态变化）。
  ///
  /// 由宿主页面按自己的刷新逻辑提供；做成 getter 而不是字段，是为了让它每次
  /// 用到时才构造。
  SyncCallbacks get syncCallbacks;

  void onSyncStateChanged() {}

  /// 统一改三个入口的按钮进度（不碰对话框）。
  ///
  /// 拆成「取计数 / 取文案 / 写回」三步是为了避免在表达式里对整个
  /// `this` 做空判断 —— 那样会把 mixin 自身也判进去，读起来莫名其妙。
  void _updateSyncState({
    bool? divingFish,
    String? divingFishText,
    bool? luoXue,
    String? luoXueText,
    bool? awmcNet,
    String? awmcNetText,
    bool? multi,
    String? multiText,
    double? divingFishProgress,
    double? luoXueProgress,
    double? awmcNetProgress,
    double? multiProgress,
  }) {
    if (!mounted) return;
    setState(() {
      // 新任务和结束任务都清除上次的进度，等待网关响应时不伪造百分比。
      if (divingFish != null && divingFish != _syncingDivingFish)
        _divingFishProgress = null;
      if (luoXue != null && luoXue != _syncingLuoXue) _luoXueProgress = null;
      if (awmcNet != null && awmcNet != _syncingAwmcNet)
        _awmcNetProgress = null;
      if (multi != null && multi != _syncingMulti) _multiSyncProgress = null;
      if (divingFishProgress != null) _divingFishProgress = divingFishProgress;
      if (luoXueProgress != null) _luoXueProgress = luoXueProgress;
      if (awmcNetProgress != null) _awmcNetProgress = awmcNetProgress;
      if (multiProgress != null) _multiSyncProgress = multiProgress;
      if (divingFish != null) _syncingDivingFish = divingFish;
      if (divingFishText != null) _syncText = divingFishText;
      if (luoXue != null) _syncingLuoXue = luoXue;
      if (luoXueText != null) _luoXueText = luoXueText;
      if (awmcNet != null) _syncingAwmcNet = awmcNet;
      if (awmcNetText != null) _awmcNetText = awmcNetText;
      if (multi != null) _syncingMulti = multi;
      if (multiText != null) _multiSyncText = multiText;
    });
    onSyncStateChanged();
  }

  // ===== 水鱼 =====

  /// 线路1（AWMC 网关免导入 Token）只需能解析到水鱼 QQ（或已有本地 Import-Token 回退）。
  Future<bool> _ensureDivingFishAccountForAwmc() async {
    if (await AwmcQrSyncService.resolveDivingFishQq() != null) return true;
    final legacyToken = await SecureCredentialStore.read(
          CacheKeyConstant.probeDivingFishImportToken,
        ) ??
        '';
    if (legacyToken.trim().isNotEmpty) return true;
    if (!mounted) return false;
    final goToLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(context.l10n.featureNotice),
        content: Text(context.l10n.flowSignInToYourDivingFishAccount),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.featureCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.flowSignInFirst),
          ),
        ],
      ),
    );
    if (goToLogin != true || !mounted) return false;
    await SyncScoreDialogs.showDivingFishLoginDialog(context, syncCallbacks);
    if (!mounted) return false;
    return await AwmcQrSyncService.resolveDivingFishQq() != null;
  }

  /// 线路1（AWMC 网关）同步到水鱼：优先使用水鱼 OAuth 写入权限，免导入 Token。
  Future<void> syncToDivingFishViaAwmc() async {
    if (anyBusy) return;
    final outcome = await AwmcSyncFlow.run(
      context,
      target: AwmcSyncTarget.divingFish,
      onMissingCredential: _ensureDivingFishAccountForAwmc,
      onBusy: (label) =>
          _updateSyncState(divingFish: true, divingFishText: label),
      onProgress: (p, text) => _updateSyncState(
          divingFishText: '$text ${(p * 100).round()}%', divingFishProgress: p),
      onIdle: () => _updateSyncState(divingFish: false, divingFishText: ''),
    );
    if (!mounted || outcome.cancelled) return;
    if (outcome.ok) {
      ConfettiEffect.show(context);
      AppToast.show(
          AwmcSyncFlow.successToast(AwmcSyncTarget.divingFish, outcome));
      if (outcome.refreshError != null && mounted) {
        await showErrorMessageDialog(
          context,
          title: context.l10n.flowCouldNotRefreshData,
          error: outcome.refreshError,
          stage: '同步后刷新水鱼数据',
          source: 'shuiyu',
          message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
              (outcome.refreshError).toString()),
        );
      }
    } else if (outcome.error != null || outcome.message != null) {
      await showErrorMessageDialog(
        context,
        appError: outcome.error,
        message: outcome.message,
        title: context.l10n.featureSyncFailed,
        stage: '同步至水鱼',
        source: 'shuiyu',
      );
    }
    // 统计是异步写进 Redis 的，稍等一下再刷新，让这一行尽快反映本次结果
    SyncRouteNotifier.instance.refreshStatsSoon();
  }

  // ===== 落雪 =====

  /// 线路1（AWMC 网关）同步到落雪：OAuth 免个人 API 密钥。
  Future<void> syncToLuoXueViaAwmc() async {
    if (anyBusy) return;
    final outcome = await AwmcSyncFlow.run(
      context,
      target: AwmcSyncTarget.luoXue,
      onBusy: (label) => _updateSyncState(luoXue: true, luoXueText: label),
      onProgress: (p, text) => _updateSyncState(
          luoXueText: '$text ${(p * 100).round()}%', luoXueProgress: p),
      onIdle: () => _updateSyncState(luoXue: false, luoXueText: ''),
    );
    if (!mounted || outcome.cancelled) return;
    if (outcome.ok) {
      ConfettiEffect.show(context);
      AppToast.show(AwmcSyncFlow.successToast(AwmcSyncTarget.luoXue, outcome));
      if (outcome.refreshError != null && mounted) {
        await showErrorMessageDialog(
          context,
          title: context.l10n.flowCouldNotRefreshData,
          error: outcome.refreshError,
          stage: '同步后刷新落雪数据',
          source: 'luoxue',
          message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
              (outcome.refreshError).toString()),
        );
      }
    } else if (outcome.error != null || outcome.message != null) {
      await showErrorMessageDialog(
        context,
        appError: outcome.error,
        message: outcome.message,
        title: context.l10n.featureSyncFailed,
        stage: '同步至落雪',
        source: 'luoxue',
      );
    }
    SyncRouteNotifier.instance.refreshStatsSoon();
  }

  // ===== AWMC NET（机台二维码直传，没有线路概念） =====

  /// 同步成绩到 AWMC NET：**输入在对话框完成，等待进度显示在按钮上**
  /// ——与上面四个入口完全一致（早先是对话框里转圈等 30 多秒）。
  Future<void> syncToAwmcNetWithButton() async {
    if (anyBusy) return;
    final outcome = await AwmcNetSyncFlow.run(
      context,
      onBusy: (label) => _updateSyncState(awmcNet: true, awmcNetText: label),
      onProgress: (p, text) => _updateSyncState(
          awmcNetText: '$text ${(p * 100).round()}%', awmcNetProgress: p),
      onIdle: () => _updateSyncState(awmcNet: false, awmcNetText: ''),
    );
    if (!outcome.cancelled) SyncRouteNotifier.instance.refreshStatsSoon();
    if (!mounted || outcome.cancelled) return;
    final message = AwmcNetSyncFlow.toastFor(outcome);
    if (outcome.ok) {
      ConfettiEffect.show(context);
      AppToast.show(message);
      if (outcome.refreshError != null && mounted) {
        await showErrorMessageDialog(
          context,
          title: context.l10n.flowCouldNotRefreshData,
          error: outcome.refreshError,
          stage: '同步后刷新 AWMC 数据',
          source: 'awmc',
          message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
              (outcome.refreshError).toString()),
        );
      }
    } else {
      await showErrorMessageDialog(
        context,
        message: message,
        title: context.l10n.featureSyncFailed,
        stage: '同步至 AWMC NET',
        source: 'awmc',
      );
    }
  }

  /// 一次输入二维码，顺序调用三个已经配置好的查分器。
  /// 每个平台独立记录成功/失败，最后一次性把汇总结果告诉用户。
  Future<void> syncToMultiplePlatforms() async {
    if (anyBusy) return;
    final input = await showMultiScoreSyncInputDialog(context);
    if (input == null || !mounted || anyBusy) return;

    _updateSyncState(multi: true, multiText: context.l10n.flowPreparingSync2);
    final successes = <String>[];
    final failures = <String>[];
    final refreshFailures = <String>[];
    var anySynchronized = false;
    final finishTask = AppTaskActivity.begin();
    try {
      final prefs = await SharedPreferences.getInstance();
      final sharedRefresh = SharedRefreshData(
        forceSourceIds: input.forceSourceIds ??
            (prefs.getStringList(CacheKeyConstant.advancedRefreshForceSources) ??
                    const <String>[])
                .toSet(),
        reportFailures: true,
      );
      var completedPlatforms = 0;
      final quickReadSession = AwmcQuickReadSession();
      final serverQuickPlatforms = input.quickUpdate &&
          (input.platforms.contains(SyncPlatform.divingFish) ||
              input.platforms.contains(SyncPlatform.awmc));

      Future<AwmcQuickServerResponse>? sharedQuickFuture;
      Future<AwmcQuickServerResponse> loadSharedQuickSync() {
        return sharedQuickFuture ??= () async {
          final userId = await AwmcQuickIdentityStore.read();
          if (userId == null) {
            throw SyncFlowException(
                appL10n.svcUserCredentialsAreNotCachedEnterA);
          }
          _updateSyncState(multiText: appL10n.flowCheckingAWMCGateway);
          final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
          final health =
              await AwmcApiService.health(token: '', timeout: probeTimeout);
          await AwmcAuditLog.record(health, note: '多端快速同步前的网关探活');
          if (!health.ok) {
            final msg =
                health.displayMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
            final short = msg.length <= 40 ? msg : '${msg.substring(0, 40)}…';
            throw SyncFlowException(
                appL10n.flowAWMCGatewayUnavailableP0SyncCancelledNo(short));
          }
          _updateSyncState(
              multiText: appL10n.flowQuicklyReadingCabinetScores);
          return AwmcQrSyncService.quickSyncViaServer(
            userId: userId,
            fishQq: input.platforms.contains(SyncPlatform.divingFish)
                ? input.fishQq
                : null,
            awmcQq: input.platforms.contains(SyncPlatform.awmc)
                ? input.awmcQq
                : null,
            includeLx: input.platforms.contains(SyncPlatform.luoXue),
          );
        }();
      }

      var pendingQr = input.qrCode;
      Future<String?> takeQr(String label, String routeLabel) async {
        if (pendingQr.isNotEmpty) {
          final qr = pendingQr;
          pendingQr = '';
          return qr;
        }
        if (!mounted) return null;
        _updateSyncState(
            multiText: context.l10n.flowEnterANewQRForP0P1(
                (label).toString(), (routeLabel).toString()));
        return AwmcUi.askQrcode(
          context,
          title: context.l10n.flowEnterANewQRCodeForP0((label).toString()),
          body: context.l10n.flowThisQRIsUsedOnlyForThis(
              (label).toString(), (routeLabel).toString()),
        );
      }

      final sharedAwmc = input.platforms.contains(SyncPlatform.awmc) &&
          !input.quickUpdate &&
          AwmcQrSyncService.qqPattern.hasMatch(input.awmcQq);
      final sharedFish = input.platforms.contains(SyncPlatform.divingFish) &&
          !input.quickUpdate &&
          AwmcQrSyncService.qqPattern.hasMatch(input.fishQq) &&
          input.fishOAuthWrite;
      final sharedLx =
          input.platforms.contains(SyncPlatform.luoXue) && !input.quickUpdate;

      Future<AwmcQrSyncResponse>? sharedQrFuture;
      Future<AwmcQrSyncResponse> loadSharedQrSync() {
        return sharedQrFuture ??= () async {
          final labels = [
            if (sharedAwmc) 'AWMC NET',
            if (sharedFish) appLocalizeLabel(SyncPlatform.divingFish.label),
            if (sharedLx) appLocalizeLabel(SyncPlatform.luoXue.label),
          ].join(' / ');
          final qrCode = await takeQr(labels, appL10n.flowRoute1);
          if (qrCode == null) {
            throw SyncFlowException(appL10n.svcQRCodeEntryCancelled);
          }
          if (!qrCode.startsWith('SGWCMAID')) {
            throw SyncFlowException(appL10n.flowInvalidCabinetLoginQRCode);
          }
          _updateSyncState(multiText: appL10n.flowCheckingAWMCGateway);
          final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
          final health =
              await AwmcApiService.health(token: '', timeout: probeTimeout);
          await AwmcAuditLog.record(health, note: '多端同步前的网关探活');
          if (!health.ok) {
            final msg =
                health.displayMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
            final short = msg.length <= 40 ? msg : '${msg.substring(0, 40)}…';
            throw SyncFlowException(
                appL10n.flowAWMCGatewayUnavailableP0SyncCancelledNo(short));
          }
          _updateSyncState(
              multiText: appL10n.flowSyncingToP0ThroughAWMCGateway(labels));
          return AwmcQrSyncService.syncByQr(
            qrCode: qrCode,
            fishQq: sharedFish ? input.fishQq : null,
            awmcQq: sharedAwmc ? input.awmcQq : null,
            includeLx: sharedLx,
          );
        }();
      }

      final results = await MultiScoreSyncRunner.run(
        platforms: input.platforms,
        execute: (platform) async {
          final routeLabel = input.quickUpdate
              ? context.l10n.flowQuickSync
              : platform == SyncPlatform.awmc
                  ? context.l10n.flowDirectQRUpload
                  : context.l10n.flowRoute1;
          _updateSyncState(
              multiText: context.l10n.flowSyncingToP0P1(
                  appLocalizeLabel(platform.label), (routeLabel).toString()),
              multiProgress: completedPlatforms / input.platforms.length);
          try {
            if (input.quickUpdate) {
              final prefetchedQuick =
                  serverQuickPlatforms ? await loadSharedQuickSync() : null;
              final refresh = await PostSyncRefreshOperation.capture(
                  AwmcQuickSyncService.sourceOf(platform),
                  request: input.refreshRequests[platform]);
              final result = await AwmcQuickSyncService.run(
                platform: platform,
                readSession: quickReadSession,
                prefetchedServerQuickSync: prefetchedQuick,
                onProgress: (p, text) => _updateSyncState(
                    multiText: '${platform.label}：$text',
                    multiProgress:
                        (completedPlatforms + p) / input.platforms.length),
              );
              anySynchronized = true;
              final refreshError = await refresh.run(
                  sharedRefresh: sharedRefresh,
                  onProgress: (p, text) =>
                      _updateSyncState(multiText: '${platform.label}：$text'));
              if (refreshError != null)
                refreshFailures.add('${platform.label}：$refreshError');
              return result.submitted == 0
                  ? context.l10n
                      .flowP0UpToDate(appLocalizeLabel(platform.label))
                  : context.l10n.flowP0QuickSyncUpdatedP1(
                      appLocalizeLabel(platform.label),
                      (result.submitted).toString());
            }
            if (platform != SyncPlatform.awmc) {
              final prefetched = await loadSharedQrSync();
              final target = platform == SyncPlatform.divingFish
                  ? AwmcSyncTarget.divingFish
                  : AwmcSyncTarget.luoXue;
              final outcome = await AwmcSyncFlow.runWithInput(
                qrCode: '',
                target: target,
                prefetchedQrSync: prefetched,
                fishQqOverride: input.fishQq,
                allowLegacyFallback: false,
                refreshRequest: input.refreshRequests[platform],
                sharedRefresh: sharedRefresh,
                onBusy: (text) => _updateSyncState(
                    multiText: context.l10n.flowP0Route1P1(
                        appLocalizeLabel(platform.label), (text).toString())),
                onProgress: (p, text) => _updateSyncState(
                    multiText: context.l10n.flowP0Route1P1P2(
                        appLocalizeLabel(platform.label),
                        (text).toString(),
                        ((p * 100).round()).toString()),
                    multiProgress:
                        (completedPlatforms + p) / input.platforms.length),
              );
              if (!outcome.ok) {
                throw SyncFlowException(
                    outcome.message ?? context.l10n.flowRoute1SyncFailed);
              }
              anySynchronized = true;
              if (outcome.refreshError != null)
                refreshFailures
                    .add('${platform.label}：${outcome.refreshError}');
              return context.l10n
                  .flowP0Route1(appLocalizeLabel(platform.label));
            }
            final prefetched = await loadSharedQrSync();
            final netInput = AwmcNetSyncInput(
              qr: '',
              qq: input.awmcQq,
              refreshRequest: input.refreshRequests[platform],
            );
            final outcome = await AwmcNetSyncFlow.runWithInput(
              netInput,
              prefetchedQrSync: prefetched,
              sharedRefresh: sharedRefresh,
              onBusy: (label) =>
                  _updateSyncState(multiText: 'AWMC NET：$label'),
              onIdle: () {},
            );
            if (!outcome.ok) {
              throw SyncFlowException(AwmcNetSyncFlow.toastFor(outcome));
            }
            anySynchronized = true;
            if (outcome.refreshError != null)
              refreshFailures.add('AWMC NET：${outcome.refreshError}');
            return 'AWMC NET';
          } finally {
            completedPlatforms++;
            _updateSyncState(
                multiProgress: completedPlatforms / input.platforms.length);
          }
        },
      );
      for (final result in results) {
        if (result.ok) {
          successes.add(result.message);
        } else {
          failures.add('${result.platform.label}：${result.message}');
        }
      }

      if (anySynchronized) {
        await sharedRefresh.finish(
          (text) => _updateSyncState(multiText: text),
        );
        if (sharedRefresh.failures.isNotEmpty) {
          refreshFailures.add(appL10n.flowCouldNotRefreshDataP0(
              sharedRefresh.failures.join('、')));
        }
      }
      if (!mounted) return;
      if (anySynchronized) ConfettiEffect.show(context);
      if (failures.isEmpty && refreshFailures.isEmpty) {
        AppToast.show(context.l10n
            .flowMultiPlatformSyncCompleteP0((successes.join('、')).toString()));
      } else {
        await showErrorMessageDialog(
          context,
          title: context.l10n.featureSyncFailed,
          stage: '多平台同步',
          message: context.l10n.flowSyncCompleteP0P1P2(
              (successes.isEmpty ? context.l10n.flowNone2 : successes.join('、'))
                  .toString(),
              (failures.isEmpty
                      ? ''
                      : context.l10n
                          .flowSyncFailedP02((failures.join('\n')).toString()))
                  .toString(),
              (refreshFailures.isEmpty
                      ? ''
                      : context.l10n.flowSyncSucceededButRefreshFailedP0(
                          (refreshFailures.join('\n')).toString()))
                  .toString()),
        );
      }
    } finally {
      finishTask();
      _updateSyncState(multi: false, multiText: '');
      SyncRouteNotifier.instance.refreshStatsSoon();
    }
  }

  /// 统一走 AWMC 网关免导入 Token 同步水鱼成绩。
  Future<void> syncToDivingFishByCurrentRoute() => syncToDivingFishViaAwmc();

  /// 统一走 AWMC 网关 OAuth 免密钥同步落雪成绩。
  Future<void> syncToLuoXueByCurrentRoute() => syncToLuoXueViaAwmc();
}
