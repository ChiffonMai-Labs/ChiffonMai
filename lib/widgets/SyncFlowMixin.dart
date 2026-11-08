import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../manager/DivingFishProbeManager.dart';
import '../page/Awmc/AwmcSyncFlow.dart';
import '../page/Awmc/AwmcUi.dart';
import '../page/AwmcNet/AwmcNetSyncFlow.dart';
import '../page/AwmcNet/SyncToAwmcNetPage.dart' show AwmcNetSyncInput;
import '../service/AccountStore.dart';
import '../service/SyncRouteStore.dart';
import '../service/SyncStatsService.dart';
import '../service/MultiScoreSyncRunner.dart';
import '../service/PostSyncRefreshService.dart';
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../utils/SyncRouteNotifier.dart';
import '../utils/SecureCredentialStore.dart';
import 'SyncScoreDialogs.dart'
    show
        SyncCallbacks,
        SyncFlowException,
        DivingFishSyncInput,
        LuoXueSyncInput,
        SyncScoreDialogs,
        showDivingFishSyncInputDialog,
        executeDivingFishSync,
        showLuoXueSyncInputDialog,
        executeLuoXueSync,
        showMultiScoreSyncInputDialog;
import 'ErrorMessageDialog.dart';
import 'ConfettiEffect.dart';
import 'MaimaiHubLoginGate.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 「同步成绩到水鱼 / 落雪 / AWMC NET」三个入口的**按钮上进度**编排。
///
/// ## 为什么要有这个 mixin
///
/// 「系统」hub 页与首页「收藏的功能」区显示的是同一批入口、同一套线路切换器
/// （[SyncRouteFooter]）、同一套统计行（[SyncStatsFooter]）。但**点击之后的编排**
/// 曾经各写了一遍，于是同一功能在两处表现完全不同：
///
///   * 水鱼：hub 页进度打在按钮上；收藏区走 `showDivingFishSyncDialog` 弹模态框。
///   * 落雪：hub 页进度打在按钮上；收藏区 `UpdateLuoXueScorePage.show` 跳页，什么进度都没有。
///   * 三个入口在收藏区还都缺少 `_anyBusy` 互斥，能同时点起两个同步互相踩缓存。
///
/// 现在三个流程只此一份，两个页面 mixin 进来即可，行为不可能再走歪。
///
/// ## 交互约定（三个入口一致）
///
/// * **需要用户输入的部分**（二维码、账号密码、排行榜选项）走对话框；
/// * **耗时等待**（抓取 → 推送 → 刷新本地数据）期间对话框立即关闭，
///   进度以 `loadingText` 打在**按钮**上，不锁整页 —— AWMC NET 一次要 30 多秒，
///   用模态框把整页锁住太难受。
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
  }

  // ===== 水鱼 =====

  /// 确保水鱼同步所需的 JWT 与 ImportToken 都已缓存。
  ///
  /// 线路1、线路2共用这份引导，避免线路1只检查 ImportToken 时弹出另一套
  /// Toast。登录成功后调用方可以继续原来的同步流程。
  Future<bool> _ensureDivingFishSyncCredential() async {
    final jwt = await SecureCredentialStore.read(
          CacheKeyConstant.probeDivingFishToken,
        ) ??
        '';
    final importToken = await SecureCredentialStore.read(
          CacheKeyConstant.probeDivingFishImportToken,
        ) ??
        '';
    if (jwt.isNotEmpty && importToken.isNotEmpty) return true;
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
    final jwtAfterLogin = await SecureCredentialStore.read(
          CacheKeyConstant.probeDivingFishToken,
        ) ??
        '';
    final importTokenAfterLogin = await SecureCredentialStore.read(
          CacheKeyConstant.probeDivingFishImportToken,
        ) ??
        '';
    return jwtAfterLogin.isNotEmpty && importTokenAfterLogin.isNotEmpty;
  }

  /// 同步成绩到水鱼（线路2 maimai Score Hub）：输入（二维码 / 排行榜选项）
  /// 在对话框完成，点「开始同步」后对话框立即关闭，抓取 → 推送 → 刷新本地数据
  /// 的进度全部显示在按钮上。
  ///
  /// 调用方负责按当前线路决定走这个还是 [syncToDivingFishViaAwmc]。
  Future<void> syncToDivingFishWithButton() async {
    if (anyBusy) return;

    if (!await _ensureDivingFishSyncCredential()) return;

    final prefs = await SharedPreferences.getInstance();
    final bindQQ =
        prefs.getString(CacheKeyConstant.probeDivingFishBindQQ) ?? '';
    final cachedQQ = (await AccountStore.loadAll())['shuiyu']?.id;
    if (bindQQ.isNotEmpty && cachedQQ != null && bindQQ != cachedQQ) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AppAlertDialog(
          title: Text(context.l10n.flowAccountMismatch),
          content: Text(
            context.l10n.flowTheSignedInDivingFishQQP0(
                (bindQQ).toString(), (cachedQQ).toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.featureOK),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    // 线路2 复用 maimai Score Hub 已有登录态；本次二维码只用于机台抓取，
    // 不再拿它去登录（一张二维码只处理一个上游请求）。
    if (!await ensureMaimaiHubLogin(context,
        reason: context.l10n.flowDivingFishRoute2)) return;
    if (!mounted) return;
    final input = await showDivingFishSyncInputDialog(context);
    if (input == null || !mounted) return;

    _updateSyncState(
        divingFish: true, divingFishText: context.l10n.flowSyncingScores);
    // 记录本次同步耗时 / 成败（Redis，尽力而为）
    final stopwatch = Stopwatch()..start();
    int? syncDurationMs;
    var syncOk = false;
    // 缺 ImportToken 时会转交给对话框再走一遍完整流程（那一次由对话框上报），
    // 这里就不再记一条，免得同一次用户操作算成两条样本
    var handedOffToDialog = false;
    try {
      final outcome = await executeDivingFishSync(
        syncCallbacks,
        input,
        onSyncFinished: (durationMs) => syncDurationMs = durationMs,
        onSyncSucceeded: () {
          if (mounted) ConfettiEffect.show(context);
        },
        onProgress: (p, t) => _updateSyncState(
          divingFishText: '$t ${(p * 100).round()}%',
          divingFishProgress: p,
        ),
      );
      syncOk = true;
      if (!mounted) return;
      AppToast.show(outcome.localDataRefreshed
          ? context.l10n.flowSyncCompleteP0ScoresSyncedAndLocal(
              (outcome.exportedCount).toString())
          : context.l10n.flowSyncCompleteP0ScoresSentToDiving(
              (outcome.exportedCount).toString()));
      if (outcome.refreshError != null && mounted) {
        await showErrorMessageDialog(context,
            message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
                (outcome.refreshError).toString()));
      }
    } on SyncFlowException catch (e) {
      if (!mounted) return;
      await showErrorMessageDialog(context, message: e.message);
      if (!mounted) return;
      // 需要 ImportToken 时按钮上没法输入账号密码，回到原有的对话框完成绑定。
      // 本次二维码可能已经用于创建抓取任务（一张二维码只能处理一个请求），
      // 不能在补绑定对话框里复用，让用户重新输入一张新的二维码。
      if (e.message.contains('ImportToken')) {
        handedOffToDialog = true;
        await SyncScoreDialogs.showDivingFishSyncDialog(
          context,
          syncCallbacks,
        );
      }
    } catch (e) {
      if (mounted) {
        await showErrorMessageDialog(context,
            message: context.l10n.flowSyncFailedP0((e).toString()));
      }
    } finally {
      stopwatch.stop();
      if (!handedOffToDialog && !input.quickUpdate) {
        unawaited(SyncStatsService.record(
          line: SyncLine.scoreHub,
          platform: SyncPlatform.divingFish,
          durationMs: syncDurationMs ?? stopwatch.elapsedMilliseconds,
          ok: syncOk,
        ));
        SyncRouteNotifier.instance.refreshStatsSoon();
      }
      _updateSyncState(divingFish: false, divingFishText: '');
    }
  }

  /// 线路1（AWMC 网关）同步到水鱼：二维码 + 用户的水鱼凭据，网关开发者密钥由服务端代理注入。
  Future<void> syncToDivingFishViaAwmc() async {
    if (anyBusy) return;
    final outcome = await AwmcSyncFlow.run(
      context,
      target: AwmcSyncTarget.divingFish,
      onMissingCredential: _ensureDivingFishSyncCredential,
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
          message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
              (outcome.refreshError).toString()),
        );
      }
    } else if (outcome.message != null) {
      await showErrorMessageDialog(context, message: outcome.message!);
    }
    // 统计是异步写进 Redis 的，稍等一下再刷新，让这一行尽快反映本次结果
    SyncRouteNotifier.instance.refreshStatsSoon();
  }

  // ===== 落雪 =====

  /// 同步成绩到落雪（线路2 maimai Score Hub）：输入在对话框完成，进度显示在按钮上。
  Future<void> syncToLuoXueWithButton() async {
    if (anyBusy) return;
    // 同水鱼线路2：先复用 Score Hub 登录态，本次二维码只用于抓取。
    if (!await ensureMaimaiHubLogin(context,
        reason: context.l10n.flowLXNSRoute2)) return;
    if (!mounted) return;
    final input = await showLuoXueSyncInputDialog(context);
    if (input == null || !mounted) return;

    _updateSyncState(luoXue: true, luoXueText: context.l10n.flowSyncingScores);
    final stopwatch = Stopwatch()..start();
    int? syncDurationMs;
    var syncOk = false;
    String? refreshError;
    try {
      final count = await executeLuoXueSync(
        input,
        onRefreshFailed: (error) => refreshError = error,
        onSyncFinished: (durationMs) => syncDurationMs = durationMs,
        onSyncSucceeded: () {
          if (mounted) ConfettiEffect.show(context);
        },
        onProgress: (p, t) {
          _updateSyncState(
              luoXueText: '$t ${(p * 100).round()}%', luoXueProgress: p);
        },
      );
      syncOk = true;
      if (!mounted) return;
      AppToast.show(context.l10n
          .flowSyncCompleteP0ScoresExportedToLXNS((count).toString()));
      if (refreshError != null && mounted) {
        await showErrorMessageDialog(context,
            message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
                (refreshError).toString()));
      }
    } on SyncFlowException catch (e) {
      if (mounted) {
        await showErrorMessageDialog(context, message: e.message);
      }
    } catch (e) {
      if (mounted) {
        await showErrorMessageDialog(context,
            message: context.l10n.flowSyncFailedP0((e).toString()));
      }
    } finally {
      stopwatch.stop();
      if (!input.quickUpdate)
        unawaited(SyncStatsService.record(
          line: SyncLine.scoreHub,
          platform: SyncPlatform.luoXue,
          durationMs: syncDurationMs ?? stopwatch.elapsedMilliseconds,
          ok: syncOk,
        ));
      SyncRouteNotifier.instance.refreshStatsSoon();
      _updateSyncState(luoXue: false, luoXueText: '');
    }
  }

  /// 线路1（AWMC 网关）同步到落雪：二维码 + 用户的落雪凭据，网关开发者密钥由服务端代理注入。
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
          message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
              (outcome.refreshError).toString()),
        );
      }
    } else if (outcome.message != null) {
      await showErrorMessageDialog(context, message: outcome.message!);
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
          message: context.l10n.flowSyncSucceededButDataRefreshFailedP0(
              (outcome.refreshError).toString()),
        );
      }
    } else {
      await showErrorMessageDialog(context, message: message);
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final participate =
          prefs.getBool(CacheKeyConstant.participateRankings) ?? false;
      final nickname = prefs.getBool(CacheKeyConstant.showNickname) ?? false;
      var completedPlatforms = 0;
      final quickReadSession = AwmcQuickReadSession();
      // 多端同步里只要有一个线路2目标，就先复用/建立 Score Hub 登录态。
      // 若这次确实需要登录，对话框里提前输入的二维码可能已经过期，
      // 必须重新输入；否则本次二维码仍只用于第一个需要它的目标。
      final needsHubSession = input.platforms.any((platform) =>
          !input.quickUpdateFor(platform) &&
          platform != SyncPlatform.awmc &&
          input.routeOf(platform) == SyncRouteStore.routeScoreHub);
      var pendingQr = input.qrCode;
      if (needsHubSession) {
        final hadSession = await DivingFishProbeManager().hasValidHubSession();
        if (!mounted) return;
        if (!hadSession) pendingQr = '';
        if (!await ensureMaimaiHubLogin(context,
            reason: context.l10n.flowMultiPlatformRoute2)) {
          return;
        }
        if (!mounted) return;
      }
      // 普通同步每个目标都要用一张新的二维码：对话框里输入的那张只给
      // 第一个需要二维码的目标，后续目标在开始前单独询问。
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

      final results = await MultiScoreSyncRunner.run(
        platforms: input.platforms,
        execute: (platform) async {
          final routeLabel = input.quickUpdateFor(platform)
              ? context.l10n.flowQuickSync
              : platform == SyncPlatform.awmc
                  ? context.l10n.flowDirectQRUpload
                  : input.routeOf(platform) == SyncRouteStore.routeAwmc
                      ? context.l10n.flowRoute1
                      : context.l10n.flowRoute2;
          _updateSyncState(
              multiText: context.l10n.flowSyncingToP0P1(
                  appLocalizeLabel(platform.label), (routeLabel).toString()),
              multiProgress: completedPlatforms / input.platforms.length);
          try {
            if (input.quickUpdateFor(platform)) {
              final refresh = await PostSyncRefreshOperation.capture(
                  AwmcQuickSyncService.sourceOf(platform),
                  request: input.refreshRequests[platform]);
              final result = await AwmcQuickSyncService.run(
                platform: platform,
                readSession: quickReadSession,
                onProgress: (p, text) => _updateSyncState(
                    multiText: '${platform.label}：$text',
                    multiProgress:
                        (completedPlatforms + p) / input.platforms.length),
              );
              anySynchronized = true;
              final refreshError = await refresh.run(
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
            if (platform != SyncPlatform.awmc &&
                input.routeOf(platform) == SyncRouteStore.routeAwmc) {
              final qrCode =
                  await takeQr(platform.label, context.l10n.flowRoute1);
              if (qrCode == null) {
                throw SyncFlowException(context.l10n.svcQRCodeEntryCancelled);
              }
              final target = platform == SyncPlatform.divingFish
                  ? AwmcSyncTarget.divingFish
                  : AwmcSyncTarget.luoXue;
              final outcome = await AwmcSyncFlow.runWithInput(
                qrCode: qrCode,
                target: target,
                refreshRequest: input.refreshRequests[platform],
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
                throw SyncFlowException(outcome.message ?? context.l10n.flowRoute1SyncFailed);
              }
              anySynchronized = true;
              if (outcome.refreshError != null)
                refreshFailures
                    .add('${platform.label}：${outcome.refreshError}');
              return context.l10n
                  .flowP0Route1(appLocalizeLabel(platform.label));
            }
            switch (platform) {
              case SyncPlatform.divingFish:
                if (!await ensureMaimaiHubLogin(context,
                    reason: context.l10n.flowDivingFishRoute2)) {
                  throw SyncFlowException(
                      context.l10n.flowNotSignedInToMaimaiScoreHub);
                }
                final qrCode = await takeQr(context.l10n.featureFish, context.l10n.flowRoute2);
                if (qrCode == null) {
                  throw SyncFlowException(context.l10n.svcQRCodeEntryCancelled);
                }
                final result = await executeDivingFishSync(
                  syncCallbacks,
                  DivingFishSyncInput(
                    qrCode: qrCode,
                    participateRankings: participate,
                    showNickname: nickname,
                    refreshRequest: input.refreshRequests[platform],
                  ),
                  onSyncSucceeded: () => anySynchronized = true,
                  onProgress: (p, text) => _updateSyncState(
                      multiText: context.l10n.flowDivingFishRoute2P0P1(
                          (text).toString(), ((p * 100).round()).toString()),
                      multiProgress:
                          (completedPlatforms + p) / input.platforms.length),
                );
                if (result.refreshError != null)
                  refreshFailures.add(context.l10n
                      .flowDivingFishP0((result.refreshError).toString()));
                return context.l10n.flowDivingFishRoute2P0Scores(
                    (result.exportedCount).toString());
              case SyncPlatform.luoXue:
                if (!await ensureMaimaiHubLogin(context,
                    reason: context.l10n.flowLXNSRoute2)) {
                  throw SyncFlowException(
                      context.l10n.flowNotSignedInToMaimaiScoreHub2);
                }
                final qrCode = await takeQr(context.l10n.featureLxns, context.l10n.flowRoute2);
                if (qrCode == null) {
                  throw SyncFlowException(context.l10n.svcQRCodeEntryCancelled);
                }
                final token = await SecureCredentialStore.read(
                    CacheKeyConstant.probeLxnsImportToken);
                final count = await executeLuoXueSync(
                  LuoXueSyncInput(
                      qrCode: qrCode,
                      lxnsImportToken: token,
                      refreshRequest: input.refreshRequests[platform]),
                  onRefreshFailed: (error) => refreshFailures
                      .add(context.l10n.flowLXNSP0((error).toString())),
                  onSyncSucceeded: () => anySynchronized = true,
                  onProgress: (p, text) => _updateSyncState(
                      multiText: context.l10n.flowLXNSRoute2P0P1(
                          (text).toString(), ((p * 100).round()).toString()),
                      multiProgress:
                          (completedPlatforms + p) / input.platforms.length),
                );
                return context.l10n.flowLXNSRoute2P0Scores((count).toString());
              case SyncPlatform.awmc:
                final qrCode =
                    await takeQr('AWMC NET', context.l10n.flowDirectQRUpload);
                if (qrCode == null) {
                  throw SyncFlowException(context.l10n.svcQRCodeEntryCancelled);
                }
                final token = await SecureCredentialStore.read(
                    CacheKeyConstant.awmcNetImportToken);
                if (token == null || token.isEmpty) {
                  throw SyncFlowException(
                      context.l10n.flowAWMCNETScoreImportTokenNotSet);
                }
                final outcome = await AwmcNetSyncFlow.runWithInput(
                  AwmcNetSyncInput(
                      qr: qrCode,
                      importToken: token,
                      refreshRequest: input.refreshRequests[platform]),
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
            }
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

      if (!mounted) return;
      if (anySynchronized) ConfettiEffect.show(context);
      if (failures.isEmpty && refreshFailures.isEmpty) {
        AppToast.show(context.l10n
            .flowMultiPlatformSyncCompleteP0((successes.join('、')).toString()));
      } else {
        await showErrorMessageDialog(
          context,
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
      _updateSyncState(multi: false, multiText: '');
      SyncRouteNotifier.instance.refreshStatsSoon();
    }
  }

  /// 按 [SyncRouteStore] 里记住的线路分发水鱼同步。
  ///
  /// 两个页面都要做这个分支，集中在这里免得一边改一边忘。
  Future<void> syncToDivingFishByCurrentRoute() async {
    if (SyncRouteNotifier.instance.routeOf(SyncPlatform.divingFish) ==
        SyncRouteStore.routeAwmc) {
      await syncToDivingFishViaAwmc();
    } else {
      await syncToDivingFishWithButton();
    }
  }

  /// 按 [SyncRouteStore] 里记住的线路分发落雪同步。
  Future<void> syncToLuoXueByCurrentRoute() async {
    if (SyncRouteNotifier.instance.routeOf(SyncPlatform.luoXue) ==
        SyncRouteStore.routeAwmc) {
      await syncToLuoXueViaAwmc();
    } else {
      await syncToLuoXueWithButton();
    }
  }
}
