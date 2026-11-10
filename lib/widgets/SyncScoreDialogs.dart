import 'AnimatedReveal.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import '../utils/AppTaskActivity.dart';
import 'RankingPrivacyOptions.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../constant/LoadingTipsConstant.dart';
import '../manager/DivingFishProbeManager.dart';
import '../service/SyncStatsService.dart';
import '../service/PostSyncRefreshService.dart';
import '../utils/AppTheme.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../utils/SyncRouteNotifier.dart';
import '../utils/SecureCredentialStore.dart';
import 'QrQuickFillButtons.dart';
import 'SyncDialogUi.dart';
import 'QuickSyncOption.dart';

import 'PostSyncRefreshOptions.dart';
import 'SmoothLinearProgressIndicator.dart';
import 'ConfettiEffect.dart';
import 'RefreshDataDialog.dart'
    show CurrentDataSourceNotifier, RefreshDataRequest, RefreshDataSource;
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../utils/AppDesignTokens.dart';
import 'AppUi.dart' hide AnimatedReveal;

export 'MultiScoreSyncDialog.dart'
    show MultiScoreSyncInput, showMultiScoreSyncInputDialog;

/// 同步成绩相关的回调上下文：用于让同步对话框在父页面（首页 / 我的）之间复用。
class SyncCallbacks {
  /// 同步成功后保存新 QQ
  final Future<void> Function(String qq) onSaveQQ;

  /// 同步完成后自动刷新本地数据（用于继续展示进度）
  final Future<void> Function({
    required String qq,
    required void Function(double progress, String text) onProgress,
    required bool participateRankings,
    required bool showNickname,
  }) onRefreshAfterSync;

  /// 登录状态变更后通知父页面更新（例如刷新我的页面的登录状态）
  final Future<void> Function() onLoginStateChanged;

  const SyncCallbacks({
    required this.onSaveQQ,
    required this.onRefreshAfterSync,
    required this.onLoginStateChanged,
  });
}

// ============================================================
// 输入 / 执行 分离的同步流程（用于把进度显示在调用方的按钮上）
// ============================================================

/// 「同步成绩到水鱼」对话框收集到的输入。
class DivingFishSyncInput {
  /// 舞萌|中二登入二维码（SGWCMAID 开头）
  final String qrCode;
  final bool quickUpdate;
  final bool participateRankings;
  final bool showNickname;
  final RefreshDataRequest? refreshRequest;

  const DivingFishSyncInput({
    required this.qrCode,
    this.quickUpdate = false,
    required this.participateRankings,
    required this.showNickname,
    this.refreshRequest,
  });
}

/// 同步过程中抛出的异常：message 可直接展示给用户。
class SyncFlowException implements Exception {
  final String message;
  const SyncFlowException(this.message);
  @override
  String toString() => message;
}

/// 同步结果：用于调用方决定成功提示文案。
class DivingFishSyncOutcome {
  final int exportedCount;
  final bool localDataRefreshed;
  final String? refreshError;
  const DivingFishSyncOutcome({
    required this.exportedCount,
    required this.localDataRefreshed,
    this.refreshError,
  });
}

/// 只收集输入的「同步成绩到水鱼」对话框：二维码 / 排行榜选项。
///
/// 返回 null 表示用户取消；返回非 null 时调用方应执行
/// [executeDivingFishSync]，并把进度显示在自己的按钮上。
///
/// 弹窗**彻底消失之后**再释放它用过的 controller。
///
/// 为什么不能直接 `await showDialog(...)` 之后就 dispose：`showDialog` 返回的
/// future 是 **`Route.popped`** —— pop 那一刻就完成，而弹窗此时还在**退场动画**里
/// （退场期间键盘收起等变化会让 `AlertDialog` 重建，重建过程会再读一次
/// controller）。于是必现
/// 「A TextEditingController was used after being disposed」，
/// 而且因为结果早已从 pop 返回，**同步流程仍会正常往下走**（用户看到的是
/// 「报错但同步照跑」）。回归测试：`test/sync_dialog_dispose_test.dart`。
///
/// [route] 是弹窗自己的 `ModalRoute`（在 builder 里用 `ModalRoute.of(ctx)` 取）。
/// 等 `Route.completed`：Flutter 文档明确它「退场动画结束、overlay 条目被移除后」
/// 才完成，正是可以安全释放的时机。
Future<void> _disposeAfterDialogCloses(
  ModalRoute<dynamic>? route,
  List<ChangeNotifier> notifiers,
) async {
  await route?.completed;
  for (final notifier in notifiers) {
    notifier.dispose();
  }
}

/// 注意：二维码的「读取剪贴板 / 相册识别 / 扫码」三个按钮需要 setState 刷新
/// 输入框，这里用一个局部 StatefulBuilder 承载，输入项本身是自包含的。
Future<DivingFishSyncInput?> showDivingFishSyncInputDialog(BuildContext context,
    {bool allowQuickUpdate = false}) async {
  final prefs = await SharedPreferences.getInstance();
  var participateRankings =
      prefs.getBool(CacheKeyConstant.participateRankings) ?? false;
  var showNickname = prefs.getBool(CacheKeyConstant.showNickname) ?? false;
  final qrController = TextEditingController();
  var quickUpdate = false;
  final refreshKey = GlobalKey<PostSyncRefreshOptionsState>();
  ModalRoute<DivingFishSyncInput>? dialogRoute;

  if (!context.mounted) return null;

  final result = await showDialog<DivingFishSyncInput>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      dialogRoute ??= ModalRoute.of(dialogContext);
      return StatefulBuilder(
        builder: (context, setState) => AppAlertDialog(
          title: Text(context.l10n.featureSyncToDivingFish),
          subtitle: context.l10n.featureScanACodeToFetchAndSync,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allowQuickUpdate)
                  SyncDialogSection(
                    first: true,
                    icon: Icons.bolt_rounded,
                    title: context.l10n.syncDialogMode,
                    child: QuickSyncOption(
                      platforms: const {SyncPlatform.divingFish},
                      onChanged: (enabled) => setState(() {
                        quickUpdate = enabled;
                      }),
                    ),
                  ),
                AnimatedReveal(
                  visible: !quickUpdate,
                  child: SyncDialogSection(
                    first: !allowQuickUpdate,
                    icon: Icons.qr_code_2_rounded,
                    title: context.l10n.syncDialogQrCode,
                    caption: context.l10n.flowRequestAndOpenALoginQRCode,
                    child: SyncQrInput(
                      controller: qrController,
                      hintText:
                          context.l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID,
                    ),
                  ),
                ),
                SyncDialogSection(
                  icon: Icons.refresh_rounded,
                  title: context.l10n.flowRefreshDataAfterSync,
                  caption: context.l10n
                      .flowRefreshAutomaticallyAfterUploadRefreshErrorsAre,
                  child: PostSyncRefreshOptions(
                    key: refreshKey,
                    source: RefreshDataSource.shuiyu,
                    showHeader: false,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.featureCancel),
            ),
            SyncStartButton(
              label: context.l10n.flowStartSync,
              onPressed: () async {
                final qrCode = qrController.text.trim();
                if (!quickUpdate && qrCode.isEmpty) {
                  AppToast.show(
                      context.l10n.flowPasteTheMaimaiCHUNITHMLoginQRString,
                      tone: AppToastTone.warning);
                  return;
                }
                if (!quickUpdate && !qrCode.startsWith('SGWCMAID')) {
                  AppToast.show(context.l10n.flowInvalidQRCodeUseALoginQR,
                      tone: AppToastTone.warning);
                  return;
                }
                final prefs2 = await SharedPreferences.getInstance();
                await prefs2.setBool(
                    CacheKeyConstant.participateRankings, participateRankings);
                await prefs2.setBool(
                    CacheKeyConstant.showNickname, showNickname);
                final refreshRequest =
                    await refreshKey.currentState?.collectRequest();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(DivingFishSyncInput(
                  qrCode: qrCode,
                  quickUpdate: quickUpdate,
                  participateRankings: participateRankings,
                  showNickname: showNickname,
                  refreshRequest: refreshRequest,
                ));
              },
            ),
          ],
        ),
      );
    },
  );

  await _disposeAfterDialogCloses(dialogRoute, [qrController]);
  return result;
}

/// 把 [SyncProgress] 的阶段映射为 0-1 的进度值。
double divingFishStageProgress(SyncProgress p) =>
    SyncScoreDialogs._stageProgress(p);

// ============================================================
// 「同步成绩到落雪」的输入 / 执行分离版本
// ============================================================

/// 「同步成绩到落雪」对话框收集到的输入。
class LuoXueSyncInput {
  /// 舞萌|中二登入二维码（SGWCMAID 开头）
  final String qrCode;
  final bool quickUpdate;

  /// 落雪个人 API 密钥；统一从本地缓存读取（在「成绩导入凭据」里维护）。
  final String? lxnsImportToken;
  final RefreshDataRequest? refreshRequest;

  const LuoXueSyncInput({
    required this.qrCode,
    this.quickUpdate = false,
    required this.lxnsImportToken,
    this.refreshRequest,
  });
}

/// 只收集输入的「同步成绩到落雪」对话框。
///
/// 返回 null 表示用户取消。落雪 API 密钥统一在「成绩导入凭据」里维护，
/// 这个对话框不再要求填写，执行时会直接从本地缓存读取。
Future<LuoXueSyncInput?> showLuoXueSyncInputDialog(BuildContext context,
    {bool allowQuickUpdate = false}) async {
  final brightness = Theme.of(context).brightness;
  final qrController = TextEditingController();
  var quickUpdate = false;
  final refreshKey = GlobalKey<PostSyncRefreshOptionsState>();
  String? error;
  ModalRoute<LuoXueSyncInput>? dialogRoute;

  // 打开时就检查密钥是否已保存：缺失时直接展示获取引导（与 AWMC NET 对话框一致）。
  final savedToken =
      await SecureCredentialStore.read(CacheKeyConstant.probeLxnsImportToken);
  final hasSavedToken = savedToken != null && savedToken.isNotEmpty;

  if (!context.mounted) return null;

  final result = await showDialog<LuoXueSyncInput>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      dialogRoute ??= ModalRoute.of(dialogContext);
      return StatefulBuilder(
        builder: (context, setState) => AppAlertDialog(
          title: Text(context.l10n.featureSyncToLXNS),
          subtitle: context.l10n.featureSyncLocalScoresToLXNS,
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allowQuickUpdate)
                  SyncDialogSection(
                    first: true,
                    icon: Icons.bolt_rounded,
                    title: context.l10n.syncDialogMode,
                    child: QuickSyncOption(
                      platforms: const {SyncPlatform.luoXue},
                      onChanged: (enabled) => setState(() {
                        quickUpdate = enabled;
                      }),
                    ),
                  ),
                AnimatedReveal(
                  visible: !quickUpdate,
                  child: SyncDialogSection(
                    first: !allowQuickUpdate,
                    icon: Icons.qr_code_2_rounded,
                    title: context.l10n.syncDialogQrCode,
                    caption: context.l10n.flowRequestAndOpenALoginQRCode,
                    // 与水鱼同步对话框保持一致：剪贴板 / 相册 / 扫码三件套
                    child: SyncQrInput(
                      controller: qrController,
                      hintText:
                          context.l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID,
                      onFilled: () => setState(() => error = null),
                    ),
                  ),
                ),
                // 密钥缺失时的获取引导：和「同步成绩到 AWMC NET」对话框同一套写法。
                if (!hasSavedToken)
                  SyncDialogSection(
                    icon: Icons.key_outlined,
                    title: context.l10n.featureAccountManagement,
                    child: _buildLuoXueKeyGuide(context, brightness),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!,
                      style: TextStyle(
                          fontSize: 12, color: AppColors.errorRed(brightness))),
                ],
                SyncDialogSection(
                  icon: Icons.refresh_rounded,
                  title: context.l10n.flowRefreshDataAfterSync,
                  caption: context.l10n
                      .flowRefreshAutomaticallyAfterUploadRefreshErrorsAre,
                  child: PostSyncRefreshOptions(
                    key: refreshKey,
                    source: RefreshDataSource.luoxue,
                    showHeader: false,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.featureCancel),
            ),
            SyncStartButton(
              label: context.l10n.flowStartSync,
              onPressed: () async {
                final qrCode = qrController.text.trim();
                if (!quickUpdate && qrCode.isEmpty) {
                  setState(() => error =
                      context.l10n.flowPasteTheMaimaiCHUNITHMLoginQRString);
                  return;
                }
                if (!quickUpdate && !qrCode.startsWith('SGWCMAID')) {
                  setState(
                      () => error = context.l10n.flowInvalidQRCodeUseALoginQR);
                  return;
                }
                // 密钥统一在「成绩导入凭据」里维护，这里只读本地缓存，
                // 不再让用户在同步对话框里输入。
                final token = await SecureCredentialStore.read(
                    CacheKeyConstant.probeLxnsImportToken);
                if (!dialogContext.mounted) return;
                if (token == null || token.isEmpty) {
                  setState(() => error =
                      context.l10n.flowNoLXNSPersonalAPIKeySetConfigure);
                  return;
                }
                final refreshRequest =
                    await refreshKey.currentState?.collectRequest();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(LuoXueSyncInput(
                  qrCode: qrCode,
                  quickUpdate: quickUpdate,
                  lxnsImportToken: token,
                  refreshRequest: refreshRequest,
                ));
              },
            ),
          ],
        ),
      );
    },
  );

  await _disposeAfterDialogCloses(dialogRoute, [qrController]);
  return result;
}

/// 落雪个人 API 密钥的获取页面（密钥在页面最底部生成）。
const String _luoXueProfileUrl =
    'https://maimai.lxns.net/user/profile?tab=thirdparty';

/// 落雪个人 API 密钥的获取引导。
///
/// 与「同步成绩到 AWMC NET」对话框里的 Token 引导同一套结构：
/// 说明 + 编号步骤 + 可点击链接。密钥统一在「成绩导入凭据 → 落雪 API 密钥」保存，
/// 所以第三步直接写清粘贴路径，避免用户拿到密钥后还要再找入口。
Widget _buildLuoXueKeyGuide(BuildContext context, Brightness brightness) {
  final hintStyle =
      TextStyle(fontSize: 12, color: AppColors.greyHint(brightness));
  final warn = AppColors.warningOrange(brightness);
  return SyncNoticeCard(
    icon: Icons.vpn_key,
    color: warn,
    title: context.l10n.flowSetLXNSPersonalAPIKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.flowExportingToLXNSRequiresYourPersonalAPI,
            style: hintStyle),
        const SizedBox(height: 4),
        Text(context.l10n.flow1OpenTheLXNSProfileLinkBelow, style: hintStyle),
        Text(context.l10n.flow2ScrollToTheBottomAndCopy, style: hintStyle),
        Text(context.l10n.flow3ReturnToAccountManagementLXNSAPI,
            style: hintStyle),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _openLuoXueProfilePage,
          child: Text(
            _luoXueProfileUrl,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(context.l10n.flowReopenThisDialogAfterSavingToSync,
            style: hintStyle),
      ],
    ),
  );
}

/// 打开落雪个人主页（密钥在页面最底部），打不开浏览器时给出手动地址。
Future<void> _openLuoXueProfilePage() async {
  final uri = Uri.parse(_luoXueProfileUrl);
  try {
    if (await ExternalLaunchUtil.open(uri)) return;
  } catch (e) {
    debugPrint('打开落雪个人主页失败: $e');
  }
  AppToast.show(
      appL10n.flowCouldNotOpenABrowserVisitP0((_luoXueProfileUrl).toString()),
      tone: AppToastTone.warning);
}

/// 执行「同步成绩到落雪」：抓取机台成绩 → 导出到落雪。
Future<int> executeLuoXueSync(
  LuoXueSyncInput input, {
  required void Function(double progress, String text) onProgress,
  void Function(int durationMs)? onSyncFinished,
  VoidCallback? onSyncSucceeded,
  void Function(String error)? onRefreshFailed,
}) =>
    AppTaskActivity.run(() async {
      if (input.quickUpdate) {
        throw SyncFlowException(appL10n.flowQuickSyncSupportsRoute1Only);
      }
      final refresh = await PostSyncRefreshOperation.capture(
          RefreshDataSource.luoxue,
          request: input.refreshRequest);
      onProgress(0.05, appL10n.flowPreparingSync);
      final syncStopwatch = Stopwatch()..start();
      final result = await DivingFishProbeManager().syncByCabinetQrToLxns(
        input.qrCode,
        lxnsImportToken: input.lxnsImportToken,
        onProgress: (p) => onProgress(divingFishStageProgress(p), p.message),
      );
      if (!result.isSuccess) {
        if (result.hubLoginRequired) {
          throw SyncFlowException(
              appL10n.flowMaimaiScoreHubSessionExpiredSignIn);
        }
        throw SyncFlowException(
            result.errorMessage ?? appL10n.featureSyncFailed);
      }
      syncStopwatch.stop();
      onSyncFinished?.call(syncStopwatch.elapsedMilliseconds);
      onSyncSucceeded?.call();
      onProgress(0.72, appL10n.flowSyncCompleteRefreshingLocalData);
      final refreshError = await refresh.run(
          onProgress: (p, text) => onProgress(0.72 + p * 0.0028, text));
      if (refreshError != null) onRefreshFailed?.call(refreshError);
      onProgress(
          1.0,
          appL10n.flowSyncCompleteP0ScoresExportedToLXNS(
              (result.exportedCount).toString()));
      return result.exportedCount;
    });

/// 执行「同步成绩到水鱼」：抓取成绩 → 推送到水鱼 → 刷新本地数据。
///
/// [onProgress] 用于把进度与状态文案推给调用方的按钮。
/// 失败时抛 [SyncFlowException]，调用方 catch 后自行提示。
///
/// 关于水鱼 ImportToken 绑定：绑定需要输入账号密码，没法在按钮上完成，
/// 所以这里抛出的消息带有 [SyncFlowException] 标记，
/// 调用方捕获后可再次调用 [SyncScoreDialogs.showDivingFishSyncDialog]
/// 进入绑定流程（该对话框仍然保留完整的绑定 + 同步能力）。
Future<DivingFishSyncOutcome> executeDivingFishSync(
  SyncCallbacks callbacks,
  DivingFishSyncInput input, {
  required void Function(double progress, String text) onProgress,
  void Function(int durationMs)? onSyncFinished,
  VoidCallback? onSyncSucceeded,
}) =>
    AppTaskActivity.run(() async {
      if (input.quickUpdate) {
        throw SyncFlowException(appL10n.flowQuickSyncSupportsRoute1Only);
      }
      final refresh = await PostSyncRefreshOperation.capture(
          RefreshDataSource.shuiyu,
          request: input.refreshRequest);
      onProgress(0.05, appL10n.flowPreparingSync);
      final syncStopwatch = Stopwatch()..start();
      final result = await DivingFishProbeManager().syncByCabinetQr(
        input.qrCode,
        onProgress: (p) => onProgress(divingFishStageProgress(p), p.message),
      );

      if (!result.isSuccess) {
        if (result.hubLoginRequired) {
          throw SyncFlowException(
              appL10n.flowMaimaiScoreHubSessionExpiredSignIn);
        }
        final msg = result.errorMessage ?? appL10n.featureSyncFailed;
        if (msg == '用户取消同步') {
          throw SyncFlowException(appL10n.flowSyncCancelled);
        }
        if (msg.contains('divingFishImportToken') || msg.contains('missing')) {
          throw SyncFlowException(
              appL10n.flowLinkDivingFishToObtainAnImportToken);
        }
        throw SyncFlowException(msg);
      }
      syncStopwatch.stop();
      onSyncFinished?.call(syncStopwatch.elapsedMilliseconds);
      onSyncSucceeded?.call();

      // 不先写共用 QQ 槽；刷新事务会把目标账号与数据一起提交。
      onProgress(0.70, appL10n.flowSyncSucceededRefreshingLocalData);
      final refreshError = await refresh.run(
          onProgress: (p, text) => onProgress(0.70 + p * 0.003, text));
      onProgress(
          1.0,
          refresh.refreshed
              ? appL10n.flowDoneLocalDataRefreshed
              : appL10n.flowSyncComplete);
      return DivingFishSyncOutcome(
        exportedCount: result.exportedCount,
        localDataRefreshed: refresh.refreshed,
        refreshError: refreshError,
      );
    });

/// 同步对话框集合：用于在水鱼 / 落雪 / 我的 等位置复用
class SyncScoreDialogs {
  /// 显示水鱼同步对话框
  ///
  /// [presetQrCode] 只允许传入**尚未使用过**的新二维码；上游已限制一张二维码
  /// 只能处理一个请求，已经用于创建抓取任务的二维码绝不能在这里复用。
  /// 按钮驱动流程在缺少 ImportToken 时回到这里补绑定时，会要求用户重新输入。
  static Future<String?> showDivingFishSyncDialog(
      BuildContext context, SyncCallbacks callbacks,
      {String? presetQrCode}) async {
    final brightness = Theme.of(context).brightness;
    final refreshKey = GlobalKey<PostSyncRefreshOptionsState>();
    final TextEditingController qrController =
        TextEditingController(text: presetQrCode ?? '');
    final TextEditingController dfUserController = TextEditingController();
    final TextEditingController dfPassController = TextEditingController();
    ModalRoute<String?>? dialogRoute;
    bool isSyncing = false;
    // 带 presetQrCode 进来时直接从「绑定水鱼账号」阶段开始
    bool needDivingFishToken = presetQrCode != null;
    bool isBinding = false;
    String statusText = '';
    String? bindingError;
    double? progress;
    SyncStage? currentStage;

    bool participateRankings = false;
    bool showNickname = false;
    bool showBriefProfile = false;

    Future<void> loadRankingSettings() async {
      final prefs = await SharedPreferences.getInstance();
      participateRankings =
          prefs.getBool(CacheKeyConstant.participateRankings) ?? false;
      showNickname = prefs.getBool(CacheKeyConstant.showNickname) ?? false;
      showBriefProfile =
          prefs.getBool(CacheKeyConstant.showBriefProfile) ?? false;
    }

    Future<void> saveRankingSettings() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          CacheKeyConstant.participateRankings, participateRankings);
      await prefs.setBool(CacheKeyConstant.showNickname, showNickname);
      await prefs.setBool(CacheKeyConstant.showBriefProfile,
          participateRankings && showNickname && showBriefProfile);
    }

    await loadRankingSettings();

    // 本次同步尝试的耗时 / 成败（Redis，尽力而为）。    //
    // 为什么上报放在对话框里：这个对话框自己跑完整个「抓取 → 刷新本地」流程，
    // 成功信号只有它内部有（调用方拿到的返回值是好友码）。放在这里，
    // 从首页 / 我的 / 系统 hub 任一入口打开都会算进同一份「线路2 · 水鱼」统计。
    // 口径（取消 / 缺绑定不算样本）见 [SyncAttemptTracker]。
    final attempt = SyncAttemptTracker(
      line: SyncLine.scoreHub,
      platform: SyncPlatform.divingFish,
    );

    void startAttempt() => attempt.start();

    void finishAttempt({required bool ok, bool skip = false}) {
      if (attempt.finish(ok: ok, skip: skip)) {
        // 等 Redis 写入落地再刷新，让首页 / hub 的统计行立刻反映这一次
        SyncRouteNotifier.instance.refreshStatsSoon();
      }
    }

    // 闭包外持有 timer/subscription/loading tip 状态，弹窗关闭后统一释放避免泄漏
    Timer? autoCloseTimer;
    StreamSubscription<String>? tipSub;
    final stopLoadingTips = () {
      autoCloseTimer?.cancel();
      autoCloseTimer = null;
      LoadingTipsConstant.stopAutoSwitch();
      tipSub?.cancel();
      tipSub = null;
    };

    final String? result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        dialogRoute ??= ModalRoute.of(dialogContext);
        int countdown = 3;
        String currentTip = LoadingTipsConstant.getRandomLoadingTip();
        return StatefulBuilder(
          builder: (context, setState) {
            final isDone = currentStage == SyncStage.completed ||
                currentStage == SyncStage.failed ||
                currentStage == SyncStage.cancelled;

            if (isDone && autoCloseTimer == null) {
              void tick() {
                countdown--;
                if (countdown > 0) {
                  setState(() {});
                  autoCloseTimer = Timer(const Duration(seconds: 1), tick);
                } else {
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              }

              autoCloseTimer = Timer(const Duration(seconds: 1), tick);
            }

            return PopScope(
              canPop: !isSyncing && !isBinding,
              child: AppAlertDialog(
                title: Row(
                  children: [
                    Icon(
                      needDivingFishToken ? Icons.link : Icons.qr_code_scanner,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(needDivingFishToken
                        ? dialogContext.l10n.flowLinkDivingFishAccount
                        : dialogContext.l10n.featureSyncToDivingFish),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ===== 阶段 1：输入 QR 码 =====
                      if (!isSyncing && !needDivingFishToken) ...[
                        Text(
                          dialogContext.l10n.flowRequestAndOpenALoginQRCode,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.greyHint(brightness)),
                        ),
                        const SizedBox(height: 12),
                        QrQuickFillButtons(controller: qrController),
                        const SizedBox(height: 12),
                        TextField(
                          controller: qrController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: dialogContext
                                .l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID,
                            hintStyle: TextStyle(
                                fontSize: 13,
                                color:
                                    AppColors.greyHint(brightness, shade: 400)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusSmall),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        RankingPrivacyOptions(
                            participate: participateRankings,
                            showNickname: showNickname,
                            showBriefProfile: showBriefProfile,
                            // 同步后刷新的是当前数据源
                            divingFishSource:
                                CurrentDataSourceNotifier.instance.value ==
                                    RefreshDataSource.shuiyu,
                            dataSourceKey: CurrentDataSourceNotifier
                                .instance.value.key,
                            onChanged: (participate, nickname, brief) =>
                                setState(() {
                                  participateRankings = participate;
                                  showNickname = nickname;
                                  showBriefProfile = brief;
                                })),
                        PostSyncRefreshOptions(
                            key: refreshKey, source: RefreshDataSource.shuiyu),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send, size: 18),
                          label: Text(dialogContext.l10n.flowStartSync),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () async {
                            final qrCode = qrController.text.trim();
                            if (qrCode.isEmpty) {
                              AppToast.show(
                                  dialogContext.l10n
                                      .flowPasteTheMaimaiCHUNITHMLoginQRString,
                                  tone: AppToastTone.warning);
                              return;
                            }
                            final request =
                                await refreshKey.currentState?.collectRequest();
                            final refresh =
                                await PostSyncRefreshOperation.capture(
                                    RefreshDataSource.shuiyu,
                                    request: request);
                            await saveRankingSettings();
                            if (!dialogContext.mounted) return;
                            setState(() {
                              isSyncing = true;
                              statusText = dialogContext.l10n.flowPreparingSync;
                              currentStage = SyncStage.authenticating;
                            });

                            LoadingTipsConstant.startAutoSwitch(3);
                            tipSub?.cancel();
                            tipSub =
                                LoadingTipsConstant.tipStream.listen((tip) {
                              setState(() => currentTip = tip);
                            });

                            if (!qrCode.startsWith('SGWCMAID')) {
                              setState(() {
                                currentStage = SyncStage.failed;
                                statusText = dialogContext
                                    .l10n.flowInvalidQRCodeUseALoginQR;
                                isSyncing = false;
                              });
                              LoadingTipsConstant.stopAutoSwitch();
                              tipSub?.cancel();
                              return;
                            }

                            startAttempt();
                            final result =
                                await DivingFishProbeManager().syncByCabinetQr(
                              qrCode,
                              onProgress: (p) {
                                setState(() {
                                  currentStage = p.stage;
                                  statusText = p.message;
                                  progress = _stageProgress(p);
                                });
                              },
                            );

                            LoadingTipsConstant.stopAutoSwitch();
                            tipSub?.cancel();

                            if (result.isSuccess) {
                              finishAttempt(ok: true);
                              if (context.mounted) ConfettiEffect.show(context);
                              setState(() {
                                currentStage = SyncStage.exporting;
                                statusText = dialogContext
                                    .l10n.flowSyncSucceededRefreshingLocalData;
                                progress = 0.70;
                              });

                              final refreshError =
                                  await refresh.run(onProgress: (p, t) {
                                if (!dialogContext.mounted) return;
                                setState(() {
                                  progress = .7 + p * .003;
                                  statusText = t;
                                });
                              });
                              if (!dialogContext.mounted) return;
                              setState(() {
                                currentStage = SyncStage.completed;
                                progress = 1.0;
                                if (refresh.refreshed) {
                                  statusText = dialogContext.l10n
                                      .flowDoneP0ScoresSyncedAndLocalData(
                                          (result.exportedCount).toString());
                                } else {
                                  statusText = dialogContext.l10n
                                      .flowP0ScoresSentToDivingFishData(
                                          (result.exportedCount).toString(),
                                          (refreshError).toString());
                                }
                              });
                            } else if (result.errorMessage == '用户取消同步') {
                              finishAttempt(ok: false, skip: true);
                              setState(() {
                                currentStage = SyncStage.cancelled;
                                statusText =
                                    dialogContext.l10n.flowSyncCancelled;
                              });
                            } else {
                              final msg = result.errorMessage ?? '';
                              if (msg.contains('divingFishImportToken') ||
                                  msg.contains('missing')) {
                                // 还没绑定 ImportToken：马上会走下面的「绑定并同步」，
                                // 那一次才算样本
                                finishAttempt(ok: false, skip: true);
                                needDivingFishToken = true;
                                isSyncing = false;
                              } else {
                                finishAttempt(ok: false);
                                setState(() {
                                  currentStage = SyncStage.failed;
                                  statusText = msg;
                                });
                              }
                            }
                          },
                        ),
                      ],

                      // ===== 阶段 2：绑定水鱼账号 =====
                      if (needDivingFishToken && !isSyncing) ...[
                        Text(
                          dialogContext
                              .l10n.flowLinkYourDivingFishAccountToObtain,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.greyHint(brightness)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: dfUserController,
                          decoration: InputDecoration(
                            labelText:
                                dialogContext.l10n.flowDivingFishUsername,
                          ).insetLabel(context),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: dfPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText:
                                dialogContext.l10n.flowDivingFishPassword,
                          ).insetLabel(context),
                        ),
                        if (bindingError != null) ...[
                          const SizedBox(height: 8),
                          Text(bindingError!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.errorRed(brightness))),
                        ],
                      ],

                      // ===== 进度显示 =====
                      if (isSyncing) ...[
                        const SizedBox(height: 12),
                        Text(statusText,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: currentStage == SyncStage.failed
                                    ? AppColors.errorRed(brightness)
                                    : currentStage == SyncStage.completed ||
                                            currentStage == SyncStage.cancelled
                                        ? AppColors.successGreen(brightness)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface)),
                        if (currentStage != SyncStage.completed &&
                            currentStage != SyncStage.failed &&
                            currentStage != SyncStage.cancelled) ...[
                          const SizedBox(height: 10),
                          if (progress != null)
                            SmoothLinearProgressIndicator(
                                value: progress,
                                color: Theme.of(context).colorScheme.primary)
                          else
                            SmoothLinearProgressIndicator(
                                color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              currentTip,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyHint(brightness,
                                      shade: 600)),
                            ),
                          ),
                        ],
                        if (currentStage == SyncStage.completed) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              dialogContext
                                  .l10n.flowScoresSyncedViewThemOnDivingFish,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.greyHint(brightness,
                                      shade: 600)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                actions: [
                  if (!isSyncing && !needDivingFishToken)
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(dialogContext.l10n.featureClose),
                    ),
                  if (isSyncing &&
                      (currentStage == SyncStage.completed ||
                          currentStage == SyncStage.failed ||
                          currentStage == SyncStage.cancelled))
                    TextButton(
                      onPressed: () {
                        autoCloseTimer?.cancel();
                        final fc = currentStage == SyncStage.completed
                            ? DivingFishProbeManager().currentFriendCode
                            : null;
                        Navigator.of(dialogContext).pop(fc);
                      },
                      child: Text(countdown > 0
                          ? dialogContext.l10n.flowOKP0((countdown).toString())
                          : dialogContext.l10n.featureOK),
                    ),
                  if (needDivingFishToken && !isSyncing) ...[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(dialogContext.l10n.flowSkip),
                    ),
                    ElevatedButton.icon(
                      icon: isBinding
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.link, size: 18),
                      label: Text(isBinding
                          ? dialogContext.l10n.flowLinking
                          : dialogContext.l10n.flowLinkAndSync),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: isBinding
                          ? null
                          : () async {
                              final username = dfUserController.text.trim();
                              final password = dfPassController.text.trim();
                              if (username.isEmpty || password.isEmpty) {
                                setState(() {
                                  bindingError = dialogContext.l10n
                                      .flowEnterYourDivingFishUsernameAndPassword;
                                });
                                return;
                              }
                              setState(() {
                                isBinding = true;
                                isSyncing = true;
                                currentStage = SyncStage.exporting;
                                progress = 0.68;
                                bindingError = null;
                              });
                              startAttempt();
                              final ok = await DivingFishProbeManager()
                                  .bindDivingFishAccount(username, password);

                              if (!ok) {
                                finishAttempt(ok: false);
                                setState(() {
                                  isBinding = false;
                                  isSyncing = false;
                                  bindingError = dialogContext
                                      .l10n.flowCouldNotLinkDivingFishTryAgain;
                                });
                                return;
                              }

                              // 绑定成功 → 同步缓存水鱼 JWT（用于后续 fetchBindQQ）
                              final manager = DivingFishProbeManager();
                              final loginResult = await manager
                                  .loginDivingFishDirect(username, password);
                              if (loginResult == null) {
                                finishAttempt(ok: false);
                                setState(() {
                                  isBinding = false;
                                  isSyncing = false;
                                  bindingError = manager
                                          .lastLoginFailure?.message ??
                                      dialogContext.l10n
                                          .flowDivingFishSignInFailedTryAgain;
                                });
                                return;
                              }

                              final refresh =
                                  await PostSyncRefreshOperation.capture(
                                      RefreshDataSource.shuiyu);
                              final exportResult =
                                  await DivingFishProbeManager()
                                      .exportLatestToDivingFish(
                                onProgress: (p) {
                                  setState(() {
                                    currentStage = p.stage;
                                    statusText = p.message;
                                    progress = _stageProgress(p);
                                  });
                                },
                                bindCachedImportToken: false,
                              );
                              if (exportResult.isSuccess) {
                                finishAttempt(ok: true);
                                if (context.mounted)
                                  ConfettiEffect.show(context);
                                setState(() {
                                  statusText = dialogContext.l10n
                                      .flowSyncSucceededRefreshingLocalData;
                                  progress = 0.70;
                                });
                                final refreshError =
                                    await refresh.run(onProgress: (p, t) {
                                  if (!dialogContext.mounted) return;
                                  setState(() {
                                    progress = .7 + p * .003;
                                    statusText = t;
                                  });
                                });
                                if (!dialogContext.mounted) return;
                                setState(() {
                                  isBinding = false;
                                  currentStage = SyncStage.completed;
                                  progress = 1.0;
                                  statusText = refresh.refreshed
                                      ? dialogContext.l10n
                                          .flowDoneP0ScoresSyncedAndLocalData(
                                              (exportResult.exportedCount)
                                                  .toString())
                                      : dialogContext.l10n
                                          .flowP0ScoresSentToDivingFishData(
                                              (exportResult.exportedCount)
                                                  .toString(),
                                              (refreshError).toString());
                                });
                                final fc =
                                    DivingFishProbeManager().currentFriendCode;
                                if (refreshError != null) {
                                  AppToast.show(
                                      dialogContext.l10n
                                          .flowSyncSucceededButDataRefreshFailedP0(
                                              (refreshError).toString()),
                                      tone: AppToastTone.error);
                                }
                                Navigator.of(dialogContext).pop(fc);
                              } else {
                                finishAttempt(ok: false);
                                setState(() {
                                  isBinding = false;
                                  isSyncing = false;
                                  currentStage = SyncStage.failed;
                                  bindingError = exportResult.errorMessage ??
                                      dialogContext
                                          .l10n.flowExportFailedTryAgain;
                                });
                              }
                            },
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );

    // 弹窗关闭（无论成功失败或被系统返回）后统一释放资源，避免 Timer/Subscription/Controller 泄漏
    stopLoadingTips();
    // controller 要等弹窗**走完退场动画**再释放（否则退场期间的重建会读它）
    await _disposeAfterDialogCloses(
        dialogRoute, [qrController, dfUserController, dfPassController]);

    return result;
  }

  /// 显示水鱼登录对话框
  static Future<void> showDivingFishLoginDialog(
      BuildContext context, SyncCallbacks callbacks) async {
    final brightness = Theme.of(context).brightness;
    final TextEditingController userController = TextEditingController();
    final TextEditingController passController = TextEditingController();
    ModalRoute<dynamic>? dialogRoute;
    bool isLoggingIn = false;
    bool loginSuccess = false;
    String? importedToken;
    String statusText = '';
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        dialogRoute ??= ModalRoute.of(dialogContext);
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AppAlertDialog(
              title: Row(
                children: [
                  Icon(
                    loginSuccess ? Icons.check_circle : Icons.login,
                    color: loginSuccess
                        ? AppColors.successGreen(brightness)
                        : Theme.of(context).colorScheme.onSurface,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(loginSuccess
                      ? dialogContext.l10n.flowSignedIn
                      : dialogContext.l10n.featureSignInToDivingFish),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!loginSuccess) ...[
                      Text(
                        dialogContext
                            .l10n.flowEnterYourDivingFishCredentialsToObtain,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.greyHint(brightness)),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: userController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.flowUsername,
                          hintText: dialogContext.l10n.flowDivingFishUsername2,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ).insetLabel(context),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.flowPassword,
                          hintText: dialogContext.l10n.flowDivingFishPassword2,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ).insetLabel(context),
                      ),
                      if (errorMsg != null) ...[
                        const SizedBox(height: 8),
                        Text(errorMsg!,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.errorRed(brightness))),
                      ],
                    ] else ...[
                      Icon(Icons.check_circle,
                          color: AppColors.successGreen(brightness), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        statusText.isNotEmpty
                            ? statusText
                            : dialogContext.l10n.flowSignedIn,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(dialogContext.l10n.flowImportTokenRetrievedAndSaved,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.greyHint(brightness))),
                      const SizedBox(height: 4),
                      Text('Token: ${importedToken ?? "***"}',
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  AppColors.greyHint(brightness, shade: 600))),
                      const SizedBox(height: 4),
                      Text(dialogContext.l10n.flowYouCanNowSyncScoresToDiving,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.greyHint(brightness))),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(loginSuccess
                      ? dialogContext.l10n.featureDone
                      : dialogContext.l10n.featureCancel),
                ),
                if (!loginSuccess)
                  ElevatedButton.icon(
                    icon: isLoggingIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login, size: 18),
                    label: Text(isLoggingIn
                        ? dialogContext.l10n.flowSigningIn
                        : dialogContext.l10n.flowSignIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: isLoggingIn
                        ? null
                        : () async {
                            final username = userController.text.trim();
                            final password = passController.text.trim();
                            if (username.isEmpty || password.isEmpty) {
                              setState(() => errorMsg = dialogContext
                                  .l10n.flowEnterUsernameAndPassword);
                              return;
                            }
                            setState(() {
                              isLoggingIn = true;
                              errorMsg = null;
                            });
                            final manager = DivingFishProbeManager();
                            final result = await manager.loginDivingFishDirect(
                                username, password);
                            if (result != null &&
                                result.tryGet<String>('importToken') != null) {
                              final bindQQ =
                                  result.tryGet<String>('bind_qq')?.trim() ??
                                      '';
                              if (bindQQ.isEmpty) {
                                setState(() {
                                  isLoggingIn = false;
                                  errorMsg = divingFishMissingBindQqMessage;
                                });
                                return;
                              }
                              final token =
                                  result.tryGet<String>('importToken') ?? '';
                              final nickname =
                                  result.tryGet<String>('nickname') ?? '';
                              final plate =
                                  result.tryGet<String>('plate') ?? '';
                              setState(() {
                                isLoggingIn = false;
                                loginSuccess = true;
                                importedToken = token.isNotEmpty
                                    ? '${token.substring(0, token.length > 12 ? 12 : token.length)}...'
                                    : '***';
                                statusText = dialogContext.l10n.flowWelcomeP0P1(
                                    (nickname).toString(),
                                    (plate.isNotEmpty ? " ($plate)" : "")
                                        .toString());
                              });
                              await callbacks.onSaveQQ(bindQQ);
                              await callbacks.onLoginStateChanged();
                            } else {
                              setState(() {
                                isLoggingIn = false;
                                errorMsg = manager.lastLoginFailure?.message ??
                                    dialogContext
                                        .l10n.flowSignInFailedTryAgainLater;
                              });
                            }
                          },
                  ),
              ],
            );
          },
        );
      },
    );

    // 弹窗关闭后释放 controllers，避免泄漏（等退场动画结束再放，见助手注释）
    await _disposeAfterDialogCloses(
        dialogRoute, [userController, passController]);
  }

  // ===== 内部辅助 =====

  static double _stageProgress(SyncProgress p) {
    switch (p.stage) {
      case SyncStage.authenticating:
        return 0.02;
      case SyncStage.requesting:
        return 0.10;
      case SyncStage.sendingFriendRequest:
        return 0.18;
      case SyncStage.waitingAcceptance:
        return 0.25;
      case SyncStage.scraping:
        return 0.25 + (p.progress ?? 0) * 0.40;
      case SyncStage.exporting:
        return 0.68;
      default:
        return 0.0;
    }
  }
}
