import 'package:flutter/cupertino.dart' as ios;
import 'AwmcNet/PlayerConnectionPage.dart';
import 'Awmc/AwmcCabinetPage.dart';
import 'Awmc/AwmcResourcesPage.dart';
import '../widgets/AccountAuthorizationDialog.dart';
import '../widgets/AccountAuthorizationStatus.dart';
import '../widgets/AccountBindingManager.dart';
import '../widgets/DivingFishAuthorizationDialog.dart';
import '../widgets/AccountSwitchSheet.dart';
import '../widgets/QuickSyncOption.dart' show showBindCabinetIdentityDialog;
import '../utils/CurrentDataSourceNotifier.dart';
import '../l10n/LocalizationsExtension.dart';
import '../l10n/FeatureLocalizations.dart';
import '../widgets/CommunityAppearanceBanner.dart';
import '../widgets/PlayerExperienceStrip.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HubComponents.dart';
import '../utils/FeatureRegistry.dart';
import 'SettingsPage.dart';
import 'DeleteAccountPage.dart';
import 'DataBackupPage.dart';
import 'AutoSyncPage.dart';
import 'MaimaiServerStatusPage.dart';
import 'RecentCommentsPage.dart';
import 'RecentRatingsPage.dart';
import 'AboutAppPage.dart';
import 'AnnouncementsPage.dart';
import 'CommunityTravelAppearancePage.dart';
import 'Awmc/AwmcCabinetAppearanceFlow.dart';
import 'Awmc/AwmcPlayCountSyncFlow.dart';
import 'SupportDeveloperPage.dart';
import 'FriendLinksPage.dart';
import 'LoadingTipsPage.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/DivingFishProbeManager.dart';
import '../manager/LZYCheckUpdateManager.dart';
import '../manager/DivingFish/ProberException.dart';
import '../manager/LuoXue/CollectionsManager.dart';
import '../entity/LuoXue/Collection.dart';
import '../service/SyncStatsService.dart';
import '../utils/SyncRouteNotifier.dart';
import '../utils/HomeRefreshNotifier.dart';
import '../utils/RefreshErrorPresenter.dart';
import '../utils/UpdateNotifier.dart';
import '../widgets/SyncStatsFooter.dart';
import '../widgets/AutoSyncStatusFooter.dart';
import '../widgets/SyncFlowMixin.dart';
import '../widgets/SyncScoreDialogs.dart' show SyncScoreDialogs, SyncCallbacks;
import '../widgets/CollectionPickerSheet.dart';
import '../service/LogExportService.dart';
import '../widgets/ExportSuccessDialog.dart';
import '../widgets/RefreshDataDialog.dart'
    show
        RefreshDataRequest,
        showRefreshDataDialog,
        executeRefreshData,
        refreshBest50DataWithProgress,
        launchUrlFallback;
import '../widgets/MaimaiHubLoginDialog.dart' show showMaimaiHubLoginDialog;
import '../constant/CacheKeyConstant.dart';
import '../constant/AppLinks.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../utils/LoginStateNotifier.dart';
import '../utils/UserProfileNotifier.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../utils/ExportPathUtil.dart';
import '../service/CommunityAvatarStore.dart';
import '../widgets/CommunityAvatar.dart';
import '../widgets/ErrorMessageDialog.dart';
import '../widgets/CacheManagementDialog.dart';
import '../widgets/AccountRegistrationGuideDialog.dart';
import '../widgets/ConfettiEffect.dart';
import '../entity/FeatureModels.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppModePreferences.dart';
import '../utils/AppTaskActivity.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUi.dart';
import '../utils/MaimaiHubLoginNotifier.dart';

class SystemHubPage extends StatefulWidget {
  final ValueNotifier<FeatureTask?> activeTask;

  const SystemHubPage({
    super.key,
    required this.activeTask,
  });

  @override
  State<SystemHubPage> createState() => SystemHubPageState();
}

class SystemHubPageState extends State<SystemHubPage>
    with SyncFlowMixin, WidgetsBindingObserver {
  /// 首页收藏和搜索沿用「我的」的功能入口、进度和互斥状态。
  Future<void> openFeature(ButtonItem item) async {
    if (anyBusy &&
        FeatureRegistry.taskRestrictedFeatures.contains(item.title)) {
      AppToast.show(context.featureText('正在处理其它任务，请稍候'));
      return;
    }
    if (item.title == '切换账号') {
      await showAccountSwitchDialog(context,
          onNeedRefresh: (source) => _refreshData(initialSource: source));
      return;
    }
    if (item.title == '绑定与授权管理') {
      await _manageAccountBindings();
      return;
    }
    switch (item.title) {
      case '同步成绩到水鱼':
        return syncToDivingFishByCurrentRoute();
      case '同步成绩到落雪':
        return syncToLuoXueByCurrentRoute();
      case '同步成绩到 AWMC NET':
        return syncToAwmcNetWithButton();
      case '同步成绩到多端':
        return syncToMultiplePlatforms();
      default:
        break;
    }
    if (item.title == '落雪账号授权' || item.title == '绑定 AWMC NET 账号') {
      await _authorizePlatform(luoxue: item.title == '落雪账号授权');
      return;
    }
    if (item.title == '绑定机台身份') {
      await showBindCabinetIdentityDialog(context);
      return;
    }
    if (item.title == '登录 maimai Score Hub') {
      await _loginMaimaiHub();
      return;
    }
    if (item.title == '自动同步') {
      FocusManager.instance.primaryFocus?.unfocus();
      _open(context, const AutoSyncPage());
      return;
    }
    if (item.title == '打印日志') {
      await _exportLogs();
      return;
    }
    if (item.title == '缓存管理') {
      await _showCacheManagementDialog();
      return;
    }
    if (item.title == '刷新机台游玩次数') {
      await _refreshPlayCounts();
      return;
    }
    if (item.title == FeatureRegistry.cabinetAppearanceTitle) {
      await _syncCabinetAppearance();
      return;
    }
    // 旧的「（高级）」收藏键已迁移；这里兜底指向合并后的刷新入口。
    if (item.title == '拉取成绩并更新数据（高级）') {
      await _refreshData();
    }
  }

  // ===== 账号 / 用户信息（昵称 / QQ 来自 UserProfileNotifier） =====
  String _userNickname = '';

  // 同步成绩的线路与统计都由 SyncRouteNotifier 统一持有：
  // 首页「收藏的功能」区里的同名入口读的是同一份状态，两边永远不会显示不一致。
  // 线路落盘仍走 SyncRouteStore（同一套 prefs 键）。

  // ===== 登出水鱼确认 + 进度 =====
  bool _loggingOut = false;
  String _logoutText = '';

  // ===== 社区装扮；头像与姓名框同时兼容 Best50 图片导出 =====
  List<Collection> _avatarIcons = [];
  List<Collection> _avatarPlates = [];
  List<Collection> _avatarFrames = [];
  List<Collection> _avatarTrophies = [];
  late final Future<List<void>> _collectionsReady;

  // ===== 长任务的进行状态（显示在对应按钮上，替代原来的进度对话框） =====
  bool _refreshing = false;
  String _refreshText = '';
  double _refreshProgress = 0;
  bool _refreshingPlayCounts = false;
  String _refreshPlayCountsText = '';
  String? _cabinetAppearanceProgress;
  final ValueNotifier<int> _subPageRevision = ValueNotifier<int>(0);
  // 三个同步入口的进行状态由 SyncFlowMixin 持有（同步按钮上进度 + 互斥）。

  /// 任意长任务进行中：用于禁用其它入口，避免并发刷新互相踩缓存
  @override
  bool get anyBusy => _activeTask != null || HomeRefreshNotifier.isBusy.value;

  FeatureTask? get _activeTask {
    if (syncingDivingFish) {
      return (title: '同步成绩到水鱼', progress: divingFishProgress);
    }
    if (syncingLuoXue) return (title: '同步成绩到落雪', progress: luoXueProgress);
    if (syncingAwmcNet) {
      return (title: '同步成绩到 AWMC NET', progress: awmcNetProgress);
    }
    if (syncingMulti) return (title: '同步成绩到多端', progress: multiSyncProgress);
    if (_refreshing) return (title: '拉取成绩并更新数据', progress: _refreshProgress);
    if (_refreshingPlayCounts) return (title: '刷新机台游玩次数', progress: null);
    if (_cabinetAppearanceProgress != null) {
      return (title: FeatureRegistry.cabinetAppearanceTitle, progress: null);
    }
    if (_loggingOut) return (title: '绑定与授权管理', progress: null);
    return null;
  }

  @override
  void onSyncStateChanged() => _publishActiveTask();

  void _notifySubPages() {
    if (mounted) _subPageRevision.value++;
  }

  void _publishActiveTask() {
    widget.activeTask.value = _activeTask;
    _notifySubPages();
  }

  late final Listenable _hubListenable = Listenable.merge([
    FavoriteFeaturesNotifier.instance,
    LoginStateNotifier.instance,
  ]);

  late final Listenable _subPageListenable = Listenable.merge([
    _subPageRevision,
    FavoriteFeaturesNotifier.instance,
    LoginStateNotifier.instance,
    UpdateNotifier.available,
    HomeRefreshNotifier.isBusy,
    AccountAuthorizationStatus.changes,
    SyncRouteNotifier.instance,
  ]);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AccountAuthorizationStatus.changes.addListener(_onSyncRouteChanged);
    // 监听共享状态：首页登出水鱼账号 / 同步成功后此处也会自动刷新昵称 / QQ
    UserProfileNotifier.instance.addListener(_onUserProfileChanged);
    _onUserProfileChanged();
    CommunityAvatarStore.instance.addListener(_onAvatarChanged);
    LoginStateNotifier.instance.addListener(_onAvatarLoginChanged);
    unawaited(CommunityAvatarStore.instance.activate());
    _collectionsReady = Future.wait(
        [_fetchAvatarIcons(), _fetchExtraAppearance(), _fetchAvatarPlates()]);
    // 线路 + 统计（与首页收藏区共享同一份状态；重复调用幂等）
    SyncRouteNotifier.instance.addListener(_onSyncRouteChanged);
    SyncRouteNotifier.instance.ensureLoaded();
    HomeRefreshNotifier.isBusy.addListener(_onHomeRefreshBusyChanged);
  }

  void _onSyncRouteChanged() {
    if (!mounted) return;
    setState(() {});
    _notifySubPages();
  }

  @override
  void dispose() {
    _subPageRevision.dispose();
    WidgetsBinding.instance.removeObserver(this);
    AccountAuthorizationStatus.changes.removeListener(_onSyncRouteChanged);
    CommunityAvatarStore.instance.removeListener(_onAvatarChanged);
    LoginStateNotifier.instance.removeListener(_onAvatarLoginChanged);
    UserProfileNotifier.instance.removeListener(_onUserProfileChanged);
    SyncRouteNotifier.instance.removeListener(_onSyncRouteChanged);
    HomeRefreshNotifier.isBusy.removeListener(_onHomeRefreshBusyChanged);
    super.dispose();
  }

  void _onHomeRefreshBusyChanged() {
    if (!mounted) return;
    setState(() {});
    _notifySubPages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(AccountAuthorizationStatus.refresh());
    }
  }

  /// 共享用户档案变更回调：把 notifier 中的值同步到本地字段，
  /// 我的页头像区昵称等区域立刻更新。
  void _onUserProfileChanged() {
    if (!mounted) return;
    // 初次载入、账号切换和恢复备份后重新核对，凭据写入则由存储层直接通知。
    unawaited(AccountAuthorizationStatus.refresh());
    final p = UserProfileNotifier.instance.value;
    setState(() {
      _userNickname = p.nickname;
    });
    _notifySubPages();
  }

  /// 共享收藏列表：当前是否已收藏（来自 FavoriteFeaturesNotifier，跨页面实时同步）
  bool _isFavorited(String title) =>
      FavoriteFeaturesNotifier.titles.contains(title);

  /// 切换收藏：写入共享 notifier，所有监听者自动重建
  Future<void> _toggleFavorite(String title) =>
      FavoriteFeaturesNotifier.toggle(title);

  Future<void> _loadProfile() => UserProfileNotifier.load();

  // ===== 头像 / 姓名框读写 =====

  void _onAvatarChanged() {
    if (mounted) setState(() {});
  }

  void _onAvatarLoginChanged() {
    if (mounted)
      unawaited(() async {
        await CommunityAvatarStore.instance.activate();
        await CommunityAvatarStore.instance.retry();
      }());
  }

  Future<void> _fetchAvatarIcons() async {
    try {
      final collectionData = await CollectionsManager().fetchIconsCollections();
      if (collectionData?.icons != null && mounted) {
        setState(() => _avatarIcons = collectionData!.icons!);
      }
    } catch (e) {
      debugPrint('获取头像列表失败: $e');
    }
  }

  Future<void> _fetchExtraAppearance() async {
    final manager = CollectionsManager();
    Future<void> load(bool frame) async {
      try {
        final data = frame
            ? await manager.fetchFramesCollections()
            : await manager.fetchTrophiesCollections();
        if (!mounted) return;
        setState(() {
          if (frame) {
            _avatarFrames = data?.frames ?? [];
          } else {
            _avatarTrophies = data?.trophies ?? [];
          }
        });
      } catch (e) {
        debugPrint('获取装扮列表失败: $e');
      }
    }

    await Future.wait([load(true), load(false)]);
  }

  Future<void> _fetchAvatarPlates() async {
    try {
      final collectionData =
          await CollectionsManager().fetchPlatesCollections();
      if (collectionData?.plates != null && mounted) {
        setState(() => _avatarPlates = collectionData!.plates!);
      }
    } catch (e) {
      debugPrint('获取姓名框列表失败: $e');
    }
  }

  /// [initialTab]：0 头像、1 姓名框、2 背景、3 称号（展开个人信息时点哪张图就进哪页）。
  void _showCollectionPicker([int initialTab = 0]) {
    FocusManager.instance.primaryFocus?.unfocus();
    final store = CommunityAvatarStore.instance;
    final player = store.value.playerId;
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          void choose(Future<void> Function() save) {
            if (!ctx.mounted || ModalRoute.of(ctx)?.isCurrent != true) return;
            if (store.value.playerId != player) {
              Navigator.pop(ctx);
              AppToast.show(
                  context.l10n.flowAccountChangedChooseYourAppearanceAgain,
                  tone: AppToastTone.warning);
              return;
            }
            Navigator.pop(ctx);
            unawaited(save().catchError((Object _) {
              AppToast.show(
                  context.l10n.flowCouldNotSaveYourAppearanceChooseAgain,
                  tone: AppToastTone.error);
            }));
          }

          return FutureBuilder<List<void>>(
              future: _collectionsReady,
              builder: (context, loaded) => ValueListenableBuilder<
                      AvatarSyncState>(
                  valueListenable: store,
                  builder: (context, state, _) => CollectionPickerSheet(
                        initialTab: initialTab,
                        isLoading:
                            loaded.connectionState != ConnectionState.done,
                        avatarIcons: _avatarIcons,
                        avatarPlates: _avatarPlates,
                        frames: _avatarFrames,
                        trophies: _avatarTrophies,
                        selectedAvatarId: state.avatarId,
                        selectedPlateId: state.plateId,
                        selectedFrameId: state.frameId,
                        selectedTrophyId: state.trophyId,
                        onAvatarPicked: (id) => choose(() => store.select(id)),
                        onPlatePicked: (id) => choose(() => store.selectPlate(
                            _avatarPlates.firstWhere((item) => item.id == id))),
                        onClearPlate: () =>
                            choose(() => store.selectPlate(null)),
                        onFramePicked: (item) =>
                            choose(() => store.selectFrame(item)),
                        onTrophyPicked: (item) =>
                            choose(() => store.selectTrophy(item)),
                      )));
        });
  }

  // ===== 通用 =====

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page))
          .then((_) => _loadProfile());

  Future<void> _exportLogs() async {
    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '日志', title: context.l10n.flowChooseWhereToSaveLogs)) {
      return;
    }
    try {
      final file = await LogExportService.instance.export();
      if (!mounted) return;
      await showExportSuccessDialog(
        context,
        title: context.l10n.flowLogsExported,
        filePath: file.path,
        fileName: file.uri.pathSegments.last,
      );
    } catch (e, stack) {
      if (mounted) {
        AppToast.showError(
          e,
          stack: stack,
          title: context.l10n.featureExportLogs,
          stage: '导出运行日志',
        );
      }
    }
  }

  /// 打开外链；**打不开就把内容复制到剪贴板并提示**（不会静默失败）。
  ///
  /// [copyText] 默认复制 [url]。加群链接那种「复制链接没用」的情况要显式换成群号；
  /// [failMessage] 用来说明复制到的是什么、接下来怎么办。两个都不给时用通用文案。
  Future<void> _launchExternal(
    BuildContext context,
    String url,
    String label, {
    String? copyText,
    String? failMessage,
  }) async {
    final uri = Uri.parse(url);
    try {
      if (await ExternalLaunchUtil.open(uri)) {
        return;
      }
    } catch (e) {
      debugPrint('打开 $url 失败: $e');
    }
    if (!context.mounted) return;
    // 统一走公共兜底：复制剪贴板 + 轻提示（各写一遍很容易漏掉复制那一步）
    launchUrlFallback(
      url,
      context,
      copyText: copyText,
      message: failMessage ??
          context.l10n.flowCouldNotOpenABrowserP0Copied((label).toString()),
    );
  }

  /// 刷新数据：对话框只收集输入，进度显示在「刷新数据」这个按钮上。
  Future<void> _refreshData({RefreshDataSource? initialSource}) async {
    if (anyBusy) return;
    final request =
        await showRefreshDataDialog(context, initialSource: initialSource);
    if (request == null || !mounted || anyBusy) return;
    await _executeRefreshRequest(request);
  }

  /// 执行一次成绩拉取与缓存更新，并同步按钮和活动任务状态。
  Future<void> _executeRefreshRequest(RefreshDataRequest request) async {
    if (!mounted || anyBusy) return;

    setState(() {
      _refreshing = true;
      _refreshText = context.l10n.flowRefreshingData;
      _refreshProgress = 0;
    });
    _publishActiveTask();
    try {
      await executeRefreshData(request, onProgress: (p, t) {
        if (!mounted) return;
        setState(() {
          _refreshText = '$t $p%';
          _refreshProgress = p / 100;
        });
        _publishActiveTask();
      });
      if (!mounted) return;
      ConfettiEffect.show(context);
      AppToast.show(context.l10n.flowDataRefreshed, tone: AppToastTone.success);
    } on ProberException catch (e) {
      // 未授权 → 直接拉起授权页；其余按统一文案提示。
      // 与首页刷新入口共用 presentRefreshError，避免两边行为不一致。
      if (mounted) await presentRefreshError(context, e, qq: request.qq.trim());
    } catch (e) {
      if (mounted) await presentRefreshError(context, e, qq: request.qq.trim());
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
          _refreshText = '';
        });
        _publishActiveTask();
      }
    }
  }

  /// 从无或未成功状态变为成功后自动拉取成绩（不强制刷新，不参与排行榜）。
  Future<void> _autoRefreshAfterAuthSuccess(
    RefreshDataSource source, {
    String qq = '',
  }) async {
    if (!mounted || anyBusy) return;
    final request = RefreshDataRequest(
      dataSource: source,
      qq: qq,
      authCode: '',
      participateRankings: false,
      showNickname: false,
      showBriefProfile: false,
      forceFullRefresh: false,
      useSavedAuthorization: source == RefreshDataSource.luoxue,
    );
    await _executeRefreshRequest(request);
  }

  Future<void> _showCacheManagementDialog() async {
    if (anyBusy) {
      AppToast.show(context.featureText('正在处理其它任务，请稍候'));
      return;
    }
    await showCacheManagementDialog(context);
  }

  /// 独立读取机台游玩次数；普通成绩同步不再复用二维码调用这个接口。
  Future<void> _refreshPlayCounts() async {
    if (anyBusy) return;
    setState(() {
      _refreshingPlayCounts = true;
      _refreshPlayCountsText = context.l10n.flowPreparingToReadCabinetPlayCount;
    });
    _publishActiveTask();
    try {
      final outcome = await AwmcPlayCountSyncFlow.run(
        context,
        onBusy: (text) {
          if (!mounted) return;
          setState(() => _refreshPlayCountsText = text);
          _notifySubPages();
        },
        onIdle: () {
          if (!mounted) return;
          setState(() => _refreshPlayCountsText = '');
          _notifySubPages();
        },
      );
      if (!mounted || outcome.cancelled) return;
      AppToast.show(outcome.ok
          ? context.l10n.flowPlayCountsUpdatedP0Records(
              (outcome.cachedRecords).toString())
          : context.l10n.flowCouldNotReadPlayCountsP0(
              (outcome.message ?? context.l10n.featureUnknownError)
                  .toString()));
    } finally {
      if (mounted) {
        setState(() {
          _refreshingPlayCounts = false;
          _refreshPlayCountsText = '';
        });
        _publishActiveTask();
      }
    }
  }

  Future<void> _checkUpdate() {
    return LZYCheckUpdateManager().showUpdateDialog(context, force: true);
  }

  Future<void> _syncCabinetAppearance() async {
    if (anyBusy) return;
    setState(() => _cabinetAppearanceProgress =
        context.l10n.cabinetAppearanceCheckingCloud);
    _publishActiveTask();
    try {
      await AppTaskActivity.run(() => AwmcCabinetAppearanceFlow.run(
            context,
            onProgress: (label) {
              if (!mounted) return;
              setState(() => _cabinetAppearanceProgress = label);
              _notifySubPages();
            },
          ));
    } catch (error) {
      debugPrint('同步机台装扮失败: ${error.runtimeType}');
      if (mounted) {
        AppToast.show(context.l10n.cabinetAppearanceFailed,
            tone: AppToastTone.error);
      }
    } finally {
      if (mounted) {
        setState(() => _cabinetAppearanceProgress = null);
        _publishActiveTask();
      }
    }
  }

  // ===== 同步成绩 =====

  /// SyncFlowMixin 需要一个按本页刷新逻辑实现的回调集。
  @override
  SyncCallbacks get syncCallbacks => SyncCallbacks(
        onSaveQQ: (qq) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(CacheKeyConstant.probeDivingFishBindQQ, qq);
        },
        onRefreshAfterSync: _refreshAfterSync,
        onLoginStateChanged: () async {
          await _loadProfile();
          // 登录成功后通知共享 LoginStateNotifier：
          // 本页与监听此 notifier 的其他页面（首页分类页等）会即时把
          // "登录水鱼" 按钮切换为 "登出账号"。
          LoginStateNotifier.setLoggedIn(true);
        },
      );

  Future<void> _refreshAfterSync({
    required String qq,
    required void Function(double progress, String text) onProgress,
    required bool participateRankings,
    required bool showNickname,
  }) async {
    await refreshBest50DataWithProgress(
        qq, (p, text) => onProgress(0.70 + p / 100 * 0.30, text),
        participateRankings: participateRankings, showNickname: showNickname);
    await _loadProfile();
  }

  // 五个同步流程（水鱼线路1/线路2、落雪线路1/线路2、AWMC NET）原来在这里各写了一份，
  // 与首页「收藏的功能」区的那份逐渐走歪。现在统一由 SyncFlowMixin 提供：
  //   syncToDivingFishByCurrentRoute / syncToLuoXueByCurrentRoute / syncToAwmcNetWithButton
  // 按钮上的进度文案从 syncingDivingFish / luoXueText 等 getter 读。
  // 线路1 = AWMC 网关、线路2 = maimai Score Hub（详见 SyncRouteStore）。

  Future<bool> _loginDivingFish() {
    return SyncScoreDialogs.showDivingFishLoginDialog(context, syncCallbacks);
  }

  /// 读取当前已登录水鱼账号绑定的 QQ 号；本地未缓存时回退查询账号资料。
  Future<String> _resolveDivingFishBindQQ() async {
    final prefs = await SharedPreferences.getInstance();
    final cached =
        prefs.getString(CacheKeyConstant.probeDivingFishBindQQ)?.trim() ?? '';
    if (cached.isNotEmpty) return cached;
    return (await DivingFishProbeManager().fetchBindQQ())?.trim() ?? '';
  }

  /// 授权落雪或绑定 AWMC NET；若从无或未成功状态变为成功，关闭弹窗后立即自动拉取成绩。
  Future<void> _authorizePlatform({required bool luoxue}) async {
    final outcome =
        await showAccountAuthorizationDialog(context, luoxue: luoxue);
    if (!outcome.becameSuccessful || !mounted || anyBusy) return;
    if (luoxue) {
      await _autoRefreshAfterAuthSuccess(RefreshDataSource.luoxue);
    } else if (outcome.awmcQQ.isNotEmpty) {
      await _autoRefreshAfterAuthSuccess(
        RefreshDataSource.awmc,
        qq: outcome.awmcQQ,
      );
    }
  }

  Future<void> _loginMaimaiHub() async {
    if (anyBusy) return;
    final loggedIn = await showMaimaiHubLoginDialog(context);
    if (!mounted) return;
    if (loggedIn) {
      MaimaiHubLoginNotifier.instance.value = true;
      AppToast.show(context.l10n.flowMaimaiScoreHubSignInSavedOCR);
    }
  }

  /// 「绑定与授权管理」：先选目标，再沿用各自原有的登录 / 授权 / 绑定流程。
  Future<void> _manageAccountBindings() async {
    if (anyBusy) return;
    final target = await showAccountBindingDialog(context);
    if (target == null || !mounted || anyBusy) return;
    switch (target) {
      case AccountBindingTarget.scoreHub:
        await _loginMaimaiHub();
      case AccountBindingTarget.divingFish:
        if (LoginStateNotifier.instance.value) {
          await _logoutDivingFish();
        } else {
          final loggedIn = await _loginDivingFish();
          if (loggedIn && mounted && !anyBusy) {
            final bindQQ = await _resolveDivingFishBindQQ();
            if (bindQQ.isNotEmpty) {
              final authorized =
                  await DivingFishOAuthManager().checkAuthorization(bindQQ);
              if (authorized == true && mounted && !anyBusy) {
                await _autoRefreshAfterAuthSuccess(
                  RefreshDataSource.shuiyu,
                  qq: bindQQ,
                );
              }
            }
          }
        }
      case AccountBindingTarget.divingFishAuth:
        if (!LoginStateNotifier.instance.value) {
          AppToast.show(context.l10n.flowNotSignedInToDivingFish,
              tone: AppToastTone.warning);
          return;
        }
        final becameAuthorized =
            await showDivingFishAuthorizationDialog(context);
        if (becameAuthorized &&
            mounted &&
            !anyBusy &&
            LoginStateNotifier.instance.value) {
          final bindQQ = await _resolveDivingFishBindQQ();
          if (bindQQ.isNotEmpty && mounted && !anyBusy) {
            await _autoRefreshAfterAuthSuccess(
              RefreshDataSource.shuiyu,
              qq: bindQQ,
            );
          }
        }
      case AccountBindingTarget.lxns:
        await _authorizePlatform(luoxue: true);
      case AccountBindingTarget.awmc:
        await _authorizePlatform(luoxue: false);
      case AccountBindingTarget.cabinet:
        await showBindCabinetIdentityDialog(context);
    }
  }

  Future<bool> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(context.l10n.flowSignOutOfDivingFish),
        content: Text(context.l10n.flowSigningOutClearsSavedLoginDetailsAnd),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.featureCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.flowSignOut),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// 登出水鱼账号：先弹出确认对话框，再清除账号相关缓存。
  Future<void> _logoutDivingFish() async {
    if (_loggingOut) return;
    if (!await _confirmLogout() || !mounted || anyBusy) return;
    setState(() {
      _loggingOut = true;
      _logoutText = context.l10n.flowSigningOutOfDivingFish2;
    });
    _publishActiveTask();
    try {
      await UserProfileNotifier.clearShuiyuAccountCache();
      if (!mounted) return;
      LoginStateNotifier.setLoggedIn(false);
      AppToast.show(context.l10n.flowSignedOutOfDivingFish,
          tone: AppToastTone.success);
    } catch (e, stack) {
      debugPrint('登出水鱼账号失败：$e');
      if (mounted) {
        await showErrorMessageDialog(
          context,
          title: context.l10n.flowSigningOutOfDivingFish,
          error: e,
          stack: stack,
          stage: '登出水鱼账号',
          source: 'shuiyu',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loggingOut = false;
          _logoutText = '';
        });
        _publishActiveTask();
      }
    }
  }

  String get _busyReason => context.l10n
      .hubBusyTask(context.featureText(_activeTask?.title ?? '拉取成绩并更新数据'));

  Widget _buildSimpleHero(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appearance = CommunityAvatarStore.instance.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (Theme.of(context).platform == TargetPlatform.iOS) ...[
          ios.CupertinoListTile(
            leading: const Icon(ios.CupertinoIcons.link),
            title: Text(context.l10n.qqPlayerConnect),
            trailing: const ios.CupertinoListTileChevron(),
            onTap: () => PlayerConnectionPage.open(context),
          ),
          const SizedBox(height: 8),
        ],
        AppCard(
          radius: AppDesignTokens.radiusMedium,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CommunityAvatar(
                avatarId: appearance.avatarId,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _userNickname.isEmpty
                          ? kUnsetNicknameLabel
                          : _userNickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    ValueListenableBuilder<RefreshDataSource>(
                      valueListenable: CurrentDataSourceNotifier.instance,
                      builder: (context, source, _) => Text(
                        context.featureText(source.shortDisplayName),
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppSurfaces.track(context),
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: anyBusy
                      ? null
                      : () => showAccountSwitchDialog(
                            context,
                            onNeedRefresh: (source) =>
                                _refreshData(initialSource: source),
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 15,
                          color: anyBusy
                              ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                              : scheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.flowSwitchAccount,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: anyBusy
                                ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                                : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          radius: AppDesignTokens.radiusMedium,
          padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
          child: Row(
            children: [
              Icon(
                Icons.layers_clear_outlined,
                size: 16,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.simpleModeActiveHint,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  AppModePreferences.instance.setMode(AppDisplayMode.standard);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  context.l10n.switchToStandardMode,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _activeSyncLabel(BuildContext context) {
    String format(String key, String detail) {
      final base = context.featureText(key);
      return detail.isEmpty ? base : '$base · $detail';
    }

    if (syncingAwmcNet) return format('同步成绩到 AWMC NET', awmcNetText);
    if (syncingDivingFish) return format('同步成绩到水鱼', syncText);
    if (syncingLuoXue) return format('同步成绩到落雪', luoXueText);
    if (syncingMulti) return format('同步成绩到多端', multiSyncText);
    return null;
  }

  double? get _activeSyncProgress {
    if (syncingAwmcNet) return awmcNetProgress;
    if (syncingDivingFish) return divingFishProgress;
    if (syncingLuoXue) return luoXueProgress;
    if (syncingMulti) return multiSyncProgress;
    return null;
  }

  bool get _cabinetToolBusy =>
      _refreshingPlayCounts || _cabinetAppearanceProgress != null;

  String? get _cabinetToolText => _refreshingPlayCounts
      ? _refreshPlayCountsText
      : _cabinetAppearanceProgress;

  void _openSubPage(BuildContext context, HubSubPage page) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    ).then((_) => _loadProfile());
  }

  Widget _buildSyncEntryTile(BuildContext context) {
    final l10n = context.l10n;
    return HubActionTile(
      title: '成绩同步',
      subtitle: '查看各平台同步统计、多端与自动同步',
      icon: Icons.cloud_sync_outlined,
      onTap: () => _openSyncSubPage(context),
      loading: anySyncBusy,
      loadingText: _activeSyncLabel(context),
      showProgress: true,
      progressValue: _activeSyncProgress,
      disabled: anyBusy && !anySyncBusy,
      disabledReason: _busyReason,
      footer: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          LinkPill(
            label: l10n.accountBindingAwmc,
            onTap: anyBusy ? null : syncToAwmcNetWithButton,
          ),
          LinkPill(
            label: l10n.accountBindingDivingFish,
            onTap: anyBusy ? null : syncToDivingFishByCurrentRoute,
          ),
          LinkPill(
            label: l10n.accountBindingLxns,
            onTap: anyBusy ? null : syncToLuoXueByCurrentRoute,
          ),
          LinkPill(
            label: l10n.hubPillMultiPlatform,
            onTap: anyBusy ? null : syncToMultiplePlatforms,
          ),
          LinkPill(
            label: l10n.featureAutoSync,
            onTap: anyBusy
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _open(context, const AutoSyncPage());
                  },
          ),
        ],
      ),
    );
  }

  void _openSyncSubPage(BuildContext context) {
    _openSubPage(
      context,
      HubSubPage(
        title: '成绩同步',
        listenable: _subPageListenable,
        builder: (pageContext) => [
          HubSection(
            title: '单平台同步',
            subtitle: '分别同步成绩到各查分器',
            icon: Icons.cloud_sync_outlined,
            contentPadding: const EdgeInsets.only(bottom: 8),
            children: _buildSinglePlatformSyncTiles(),
          ),
          const SizedBox(height: 24),
          HubSection(
            title: '批量与定时同步',
            subtitle: '多端同步与自动同步',
            icon: Icons.schedule_outlined,
            contentPadding: const EdgeInsets.only(bottom: 8),
            children: _buildBatchSyncTiles(pageContext),
          ),
        ],
      ),
    );
  }

  void _openAccountAuthSubPage(BuildContext context) {
    _openSubPage(
      context,
      HubSubPage(
        title: '账号与授权',
        listenable: _subPageListenable,
        builder: (pageContext) => [
          HubSection(
            title: '账号与授权',
            subtitle: '管理账号与数据源登录状态',
            icon: Icons.manage_accounts_outlined,
            children: _buildAccountAuthTiles(pageContext, includeSwitch: false),
          ),
        ],
      ),
    );
  }

  void _openCabinetSubPage(BuildContext context) {
    _openSubPage(
      context,
      HubSubPage(
        title: '机台与 AWMC',
        listenable: _subPageListenable,
        builder: (pageContext) => [
          HubSection(
            title: '机台与 AWMC',
            subtitle: '游玩次数 · 机台装扮 · 机台查询 · 资源查询',
            icon: Icons.point_of_sale_outlined,
            children: _buildCabinetTiles(pageContext),
          ),
        ],
      ),
    );
  }

  void _openMaintenanceSubPage(BuildContext context) {
    _openSubPage(
      context,
      HubSubPage(
        title: '数据与维护',
        listenable: _subPageListenable,
        builder: (pageContext) => [
          HubSection(
            title: '本地与偏好',
            subtitle: '备份数据，管理本地缓存',
            icon: Icons.storage_outlined,
            children: _buildLocalDataTiles(pageContext),
          ),
          const SizedBox(height: 24),
          HubSection(
            title: '运行诊断',
            subtitle: '检查服务状态，导出运行日志',
            icon: Icons.network_check_rounded,
            children: _buildDiagnosticTiles(pageContext),
          ),
        ],
      ),
    );
  }

  void _showCommunitySheet(BuildContext context) {
    showHubGroupSheet(
      context,
      title: '社区动态',
      subtitle: '最近评论 · 最近评分',
      listenable: _subPageListenable,
      itemsBuilder: (sheetContext) => _buildCommunityTiles(
        sheetContext,
        beforeOpen: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  void _openAboutFeedbackSubPage(BuildContext context) {
    _openSubPage(
      context,
      HubSubPage(
        title: '关于与反馈',
        listenable: _subPageListenable,
        builder: (pageContext) => [
          HubSection(
            title: '项目与链接',
            subtitle: '版本更新、项目介绍与相关链接',
            icon: Icons.info_outline_rounded,
            children: _buildProjectLinkTiles(pageContext),
          ),
          const SizedBox(height: 24),
          HubSection(
            title: '反馈与支持',
            subtitle: '反馈问题、交流建议与支持开发',
            icon: Icons.support_agent_rounded,
            children: _buildFeedbackSupportTiles(pageContext),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSinglePlatformSyncTiles() => [
        HubActionTile(
          title: '同步成绩到 AWMC NET',
          subtitle: '用机台二维码导入成绩到 AWMC NET',
          icon: Icons.cloud_upload_outlined,
          isFavorited: _isFavorited('同步成绩到 AWMC NET'),
          onToggleFavorite: () => _toggleFavorite('同步成绩到 AWMC NET'),
          // AWMC NET 只有「机台二维码」这一条写入路径，只显示近 100 次统计。
          onTap: syncToAwmcNetWithButton,
          loading: syncingAwmcNet,
          loadingText: awmcNetText,
          showProgress: true,
          progressValue: awmcNetProgress,
          disabledReason: _busyReason,
          disabled: anyBusy && !syncingAwmcNet,
          footerLift: SyncStatsFooter.footerLift,
          footer: const SyncStatsFooter(
            slot: (SyncLine.direct, SyncPlatform.awmc),
          ),
        ),
        HubActionTile(
          title: '同步成绩到水鱼',
          subtitle: '扫码抓取并同步最新成绩',
          icon: Icons.cloud_upload_outlined,
          isFavorited: _isFavorited('同步成绩到水鱼'),
          onToggleFavorite: () => _toggleFavorite('同步成绩到水鱼'),
          onTap: syncToDivingFishByCurrentRoute,
          loading: syncingDivingFish,
          loadingText: syncText,
          showProgress: true,
          progressValue: divingFishProgress,
          disabledReason: _busyReason,
          disabled: anyBusy && !syncingDivingFish,
          footerLift: SyncStatsFooter.footerLift,
          footer: const SyncStatsFooter(
            slot: (SyncLine.awmc, SyncPlatform.divingFish),
          ),
        ),
        HubActionTile(
          title: '同步成绩到落雪',
          subtitle: '将本地成绩同步到落雪咖啡屋',
          icon: Icons.cloud_sync_outlined,
          isFavorited: _isFavorited('同步成绩到落雪'),
          onToggleFavorite: () => _toggleFavorite('同步成绩到落雪'),
          onTap: syncToLuoXueByCurrentRoute,
          loading: syncingLuoXue,
          loadingText: luoXueText,
          showProgress: true,
          progressValue: luoXueProgress,
          disabledReason: _busyReason,
          disabled: anyBusy && !syncingLuoXue,
          footerLift: SyncStatsFooter.footerLift,
          footer: const SyncStatsFooter(
            slot: (SyncLine.awmc, SyncPlatform.luoXue),
          ),
        ),
      ];

  List<Widget> _buildBatchSyncTiles(BuildContext ctx) => [
        HubActionTile(
          title: '同步成绩到多端',
          subtitle: '一份成绩同步到多个查分器',
          icon: Icons.devices_other_outlined,
          isFavorited: _isFavorited('同步成绩到多端'),
          onToggleFavorite: () => _toggleFavorite('同步成绩到多端'),
          onTap: syncToMultiplePlatforms,
          loading: syncingMulti,
          loadingText: multiSyncText,
          showProgress: true,
          progressValue: multiSyncProgress,
          disabledReason: _busyReason,
          disabled: anyBusy && !syncingMulti,
        ),
        HubActionTile(
          title: '自动同步',
          subtitle: '每天定时同步成绩，解放双手',
          icon: Icons.schedule_outlined,
          isFavorited: _isFavorited('自动同步'),
          onToggleFavorite: () => _toggleFavorite('自动同步'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const AutoSyncPage());
          },
          disabledReason: _busyReason,
          disabled: anyBusy,
          footerLift: SyncStatsFooter.footerLift,
          footer: AutoSyncStatusFooter(
            onTap: () {
              if (!anyBusy) {
                FocusManager.instance.primaryFocus?.unfocus();
                _open(ctx, const AutoSyncPage());
              }
            },
          ),
        ),
      ];

  Widget _buildBindingAuthTile({bool compactFooter = false}) => HubActionTile(
        title: '绑定与授权管理',
        subtitle: '登录、授权与绑定各数据源账号',
        icon: Icons.admin_panel_settings_outlined,
        isFavorited: _isFavorited('绑定与授权管理'),
        onToggleFavorite: () => _toggleFavorite('绑定与授权管理'),
        onTap: _manageAccountBindings,
        loading: _loggingOut,
        loadingText: _logoutText,
        disabledReason: _busyReason,
        disabled: anyBusy && !_loggingOut,
        footer: compactFooter ? null : const AccountBindingStatusFooter(),
      );

  Widget _buildSwitchAccountTile({bool showFooter = true}) => HubActionTile(
        title: '切换账号',
        subtitle: '切换数据源与玩家信息，使用本地缓存',
        icon: Icons.switch_account_outlined,
        isFavorited: _isFavorited('切换账号'),
        onToggleFavorite: () => _toggleFavorite('切换账号'),
        onTap: () => openFeature(const ButtonItem(
            title: '切换账号',
            subtitle: '切换数据源与玩家信息，使用本地缓存',
            icon: Icons.switch_account_outlined)),
        disabled: anyBusy,
        disabledReason: _busyReason,
        footer: showFooter ? const AccountSwitchStatusFooter() : null,
      );

  List<Widget> _buildAccountAuthTiles(
    BuildContext ctx, {
    bool includeSwitch = true,
  }) =>
      [
        _buildBindingAuthTile(),
        if (includeSwitch) _buildSwitchAccountTile(),
        HubActionTile(
          title: '账号注册引导',
          subtitle: '水鱼注册、落雪注册与 AWMC NET 档案创建引导',
          icon: Icons.person_add_alt_1_outlined,
          isFavorited: _isFavorited('账号注册引导'),
          onToggleFavorite: () => _toggleFavorite('账号注册引导'),
          onTap: () => showAccountRegistrationGuide(ctx),
        ),
        HubActionTile(
          title: '删除账号',
          subtitle: '删除本机账号、成绩缓存与服务端记录',
          icon: Icons.delete_forever_outlined,
          isFavorited: _isFavorited('删除账号'),
          onToggleFavorite: () => _toggleFavorite('删除账号'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const DeleteAccountPage());
          },
          disabled: anyBusy,
          disabledReason: _busyReason,
        ),
      ];

  List<Widget> _buildCabinetTiles(BuildContext ctx) => [
        HubActionTile(
          title: '刷新机台游玩次数',
          subtitle: '单独读取当前账号的 PC 数；不会附带同步成绩',
          icon: Icons.numbers_outlined,
          isFavorited: _isFavorited('刷新机台游玩次数'),
          onToggleFavorite: () => _toggleFavorite('刷新机台游玩次数'),
          onTap: _refreshPlayCounts,
          loading: _refreshingPlayCounts,
          loadingText: _refreshPlayCountsText,
          disabledReason: _busyReason,
          disabled: anyBusy && !_refreshingPlayCounts,
        ),
        HubActionTile(
          title: FeatureRegistry.cabinetAppearanceTitle,
          subtitle: FeatureRegistry.cabinetAppearanceSubtitle,
          icon: Icons.checkroom_outlined,
          isFavorited: _isFavorited(FeatureRegistry.cabinetAppearanceTitle),
          onToggleFavorite: () =>
              _toggleFavorite(FeatureRegistry.cabinetAppearanceTitle),
          onTap: _syncCabinetAppearance,
          loading: _cabinetAppearanceProgress != null,
          loadingText: _cabinetAppearanceProgress,
          disabledReason: _busyReason,
          disabled: anyBusy && _cabinetAppearanceProgress == null,
        ),
        HubActionTile(
          title: 'AWMC 机台查询',
          subtitle: '账号预览 · 已拥有道具 · 游玩地区',
          icon: Icons.point_of_sale_outlined,
          isFavorited: _isFavorited('AWMC 机台查询'),
          onToggleFavorite: () => _toggleFavorite('AWMC 机台查询'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const AwmcCabinetPage());
          },
        ),
        HubActionTile(
          title: 'AWMC 资源查询',
          subtitle: '资源候选 · 对手资料',
          icon: Icons.manage_search_rounded,
          isFavorited: _isFavorited('AWMC 资源查询'),
          onToggleFavorite: () => _toggleFavorite('AWMC 资源查询'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const AwmcResourcesPage());
          },
        ),
      ];

  List<Widget> _buildLocalDataTiles(BuildContext ctx) => [
        HubActionTile(
          title: '数据备份',
          subtitle: '导入或导出本地数据',
          icon: Icons.backup_outlined,
          isFavorited: _isFavorited('数据备份'),
          onToggleFavorite: () => _toggleFavorite('数据备份'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const DataBackupPage());
          },
        ),
        HubActionTile(
          title: '缓存管理',
          subtitle: '查看并清理音源、PV、maidata 缓存',
          disabled: anyBusy,
          disabledReason: _busyReason,
          icon: Icons.storage_outlined,
          isFavorited: _isFavorited('缓存管理'),
          onToggleFavorite: () => _toggleFavorite('缓存管理'),
          onTap: _showCacheManagementDialog,
        ),
        HubActionTile(
          title: '加载语录管理',
          subtitle: '选择加载时展示的语录',
          icon: Icons.format_quote,
          isFavorited: _isFavorited('加载语录管理'),
          onToggleFavorite: () => _toggleFavorite('加载语录管理'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const LoadingTipsPage());
          },
        ),
      ];

  List<Widget> _buildDiagnosticTiles(BuildContext ctx) => [
        HubActionTile(
          title: '服务器状态',
          subtitle: '查看舞萌服务状态',
          icon: Icons.cloud_outlined,
          isFavorited: _isFavorited('服务器状态'),
          onToggleFavorite: () => _toggleFavorite('服务器状态'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const MaimaiServerStatusPage());
          },
        ),
        HubActionTile(
          title: '打印日志',
          subtitle: '导出最近运行日志，方便排查问题',
          icon: Icons.receipt_long_outlined,
          isFavorited: _isFavorited('打印日志'),
          onToggleFavorite: () => _toggleFavorite('打印日志'),
          onTap: _exportLogs,
        ),
      ];

  List<Widget> _buildCommunityTiles(
    BuildContext ctx, {
    VoidCallback? beforeOpen,
  }) =>
      [
        HubActionTile(
          title: '最近评论',
          subtitle: '查看社区最近评论',
          icon: Icons.comment_outlined,
          isFavorited: _isFavorited('最近评论'),
          onToggleFavorite: () => _toggleFavorite('最近评论'),
          onTap: () {
            beforeOpen?.call();
            FocusManager.instance.primaryFocus?.unfocus();
            _open(context, const RecentCommentsPage());
          },
        ),
        HubActionTile(
          title: '最近评分',
          subtitle: '查看社区最近评分',
          icon: Icons.star_outline_rounded,
          isFavorited: _isFavorited('最近评分'),
          onToggleFavorite: () => _toggleFavorite('最近评分'),
          onTap: () {
            beforeOpen?.call();
            FocusManager.instance.primaryFocus?.unfocus();
            _open(context, const RecentRatingsPage());
          },
        ),
      ];

  List<Widget> _buildProjectLinkTiles(BuildContext ctx) => [
        HubActionTile(
          title: '关于 APP',
          subtitle: '了解项目与版本信息',
          icon: Icons.info_outline_rounded,
          isFavorited: _isFavorited('关于 APP'),
          onToggleFavorite: () => _toggleFavorite('关于 APP'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const AboutAppPage());
          },
        ),
        HubActionTile(
          title: '访问官方网站',
          subtitle: '前往 chiffonmai.cloud 查看项目主页',
          icon: Icons.public,
          isFavorited: _isFavorited('访问官方网站'),
          onToggleFavorite: () => _toggleFavorite('访问官方网站'),
          onTap: () => _launchExternal(
            ctx,
            AppLinks.officialSite,
            '官网链接',
            failMessage: ctx.l10n.flowCouldNotOpenABrowserWebsiteLink(
                (AppLinks.officialSite).toString()),
          ),
        ),
        HubActionTile(
          title: '查看友情链接',
          subtitle: '发现同好项目',
          icon: Icons.link_rounded,
          isFavorited: _isFavorited('查看友情链接'),
          onToggleFavorite: () => _toggleFavorite('查看友情链接'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const FriendLinksPage());
          },
        ),
      ];

  List<Widget> _buildFeedbackSupportTiles(BuildContext ctx) => [
        HubActionTile(
          title: '问题反馈',
          subtitle: '反馈使用中遇到的问题',
          icon: Icons.feedback_outlined,
          isFavorited: _isFavorited('问题反馈'),
          onToggleFavorite: () => _toggleFavorite('问题反馈'),
          onTap: () => _launchExternal(ctx, AppLinks.feedbackUrl, '反馈链接'),
        ),
        HubActionTile(
          title: '加入 QQ 群',
          subtitle: ctx.l10n.hubJoinGroup(AppLinks.qqGroupNumber),
          icon: Icons.groups_outlined,
          isFavorited: _isFavorited('加入 QQ 群'),
          onToggleFavorite: () => _toggleFavorite('加入 QQ 群'),
          onTap: () => _launchExternal(
            ctx,
            AppLinks.qqGroupJoinUrl,
            '群号',
            // 加群链接在浏览器里只是个空壳中转页，所以要复制**群号**
            copyText: AppLinks.qqGroupNumber,
            failMessage: ctx.l10n.flowCouldNotOpenQQGroupIDP0(
                (AppLinks.qqGroupNumber).toString()),
          ),
        ),
        HubActionTile(
          title: '问卷调查',
          subtitle: '助力 ChiffonMai 更上一层楼',
          icon: Icons.poll_outlined,
          isFavorited: _isFavorited('问卷调查'),
          onToggleFavorite: () => _toggleFavorite('问卷调查'),
          onTap: () => _launchExternal(ctx, AppLinks.surveyUrl, '问卷链接'),
        ),
        HubActionTile(
          title: '支持开发者',
          subtitle: '支持项目持续更新',
          icon: Icons.volunteer_activism_outlined,
          isFavorited: _isFavorited('支持开发者'),
          onToggleFavorite: () => _toggleFavorite('支持开发者'),
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            _open(ctx, const SupportDeveloperPage());
          },
        ),
      ];

  Widget _buildRefreshDataTile() => HubActionTile(
        title: '拉取成绩并更新数据',
        subtitle: '拉取所选账号的成绩并重算 Best50，同时更新曲目、定数与标签',
        icon: Icons.file_upload_sharp,
        isFavorited: _isFavorited('拉取成绩并更新数据'),
        onToggleFavorite: () => _toggleFavorite('拉取成绩并更新数据'),
        onTap: _refreshData,
        loading: _refreshing,
        loadingText: _refreshText,
        showProgress: true,
        progressValue: _refreshProgress,
        disabledReason: _busyReason,
        disabled: anyBusy && !_refreshing,
      );

  Widget _buildSettingsTile(BuildContext ctx) => HubActionTile(
        title: '系统设置',
        subtitle: '调整主题、背景图、交互与同步选项',
        icon: Icons.palette_outlined,
        isFavorited: _isFavorited('系统设置'),
        onToggleFavorite: () => _toggleFavorite('系统设置'),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          _open(ctx, const SettingsPage());
        },
      );

  Widget _buildAnnouncementsTile(BuildContext ctx) => HubActionTile(
        title: '公告中心',
        subtitle: '查看服务公告与项目动态',
        icon: Icons.campaign_outlined,
        isFavorited: _isFavorited('公告中心'),
        onToggleFavorite: () => _toggleFavorite('公告中心'),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          _open(ctx, const AnnouncementsPage());
        },
      );

  Widget _buildCheckUpdateTile() => ValueListenableBuilder<UpdateAvailability?>(
        valueListenable: UpdateNotifier.available,
        builder: (context, update, _) {
          if (update == null) {
            return HubActionTile(
              title: UpdateNotifier.idleTitle,
              subtitle: UpdateNotifier.idleSubtitle,
              icon: Icons.system_update_alt_outlined,
              isFavorited: _isFavorited(UpdateNotifier.idleTitle),
              onToggleFavorite: () => _toggleFavorite(UpdateNotifier.idleTitle),
              onTap: _checkUpdate,
            );
          }
          return HubActionTile(
            title: UpdateNotifier.titleFor(update),
            subtitle: context.l10n.hubUpdateReleased(
                update.latestVersion.isEmpty
                    ? context.featureText('新版本')
                    : 'v${update.latestVersion}'),
            icon: Icons.arrow_upward_rounded,
            titleColor: UpdateAvailableIcon.green,
            leading: const UpdateAvailableIcon(),
            isFavorited: _isFavorited(UpdateNotifier.idleTitle),
            onToggleFavorite: () => _toggleFavorite(UpdateNotifier.idleTitle),
            onTap: _checkUpdate,
          );
        },
      );

  Widget _buildStandardHero(BuildContext context) => Column(children: [
        if (Theme.of(context).platform == TargetPlatform.iOS)
          ios.CupertinoListTile(
              leading: const Icon(ios.CupertinoIcons.link),
              title: Text(context.l10n.qqPlayerConnect),
              trailing: const ios.CupertinoListTileChevron(),
              onTap: () => PlayerConnectionPage.open(context)),
        CommunityAppearanceBanner(
          appearance: CommunityAvatarStore.instance.value,
          nickname: _userNickname,
          onPickTap: _showCollectionPicker,
          onRetry: () => unawaited(CommunityAvatarStore.instance.retry()),
          onTravelAppearanceTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.push<void>(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityTravelAppearancePage(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppSurfaces.card(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          ),
          child: const MyPlayerExperience(),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final isSimple = AppModeScope.isSimpleOf(context);
    return ListenableBuilder(
      listenable: _hubListenable,
      builder: (context, _) => HubPageScaffold(
        title: '我的',
        subtitle: '账号、同步、备份与应用偏好',
        icon: Icons.person_rounded,
        hero: isSimple ? _buildSimpleHero(context) : _buildStandardHero(context),
        children: [
          HubSection(
            title: '账号与同步',
            subtitle: '拉取成绩、同步查分器与管理账号',
            icon: Icons.cloud_sync_outlined,
            children: [
              _buildRefreshDataTile(),
              _buildSyncEntryTile(context),
              _buildSwitchAccountTile(showFooter: !isSimple),
              HubActionTile(
                title: '账号与授权',
                subtitle: '绑定与授权 · 注册引导 · 删除账号',
                icon: Icons.manage_accounts_outlined,
                onTap: () => _openAccountAuthSubPage(context),
                loading: _loggingOut,
                loadingText: _logoutText,
                disabled: anyBusy && !_loggingOut,
                disabledReason: _busyReason,
              ),
            ],
          ),
          const SizedBox(height: 24),
          HubSection(
            title: '设置与工具',
            subtitle: '偏好设置、机台工具、数据维护与社区动态',
            icon: Icons.tune_rounded,
            children: [
              _buildSettingsTile(context),
              HubActionTile(
                title: '机台与 AWMC',
                subtitle: '游玩次数 · 机台装扮 · 机台查询 · 资源查询',
                icon: Icons.point_of_sale_outlined,
                onTap: () => _openCabinetSubPage(context),
                loading: _cabinetToolBusy,
                loadingText: _cabinetToolText,
                disabled: anyBusy && !_cabinetToolBusy,
                disabledReason: _busyReason,
              ),
              HubActionTile(
                title: '数据与维护',
                subtitle: '数据备份 · 缓存管理 · 加载语录 · 状态与日志',
                icon: Icons.storage_outlined,
                onTap: () => _openMaintenanceSubPage(context),
                disabled: anyBusy,
                disabledReason: _busyReason,
              ),
              HubActionTile(
                title: '社区动态',
                subtitle: '最近评论 · 最近评分',
                icon: Icons.forum_outlined,
                onTap: () => _showCommunitySheet(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          HubSection(
            title: '关于与更新',
            subtitle: '版本更新、公告与项目反馈',
            icon: Icons.info_outline_rounded,
            children: [
              _buildCheckUpdateTile(),
              _buildAnnouncementsTile(context),
              HubActionTile(
                title: '关于与反馈',
                subtitle: '关于 APP · 官网 · 友链 · QQ 群 · 反馈 · 支持',
                icon: Icons.support_agent_rounded,
                onTap: () => _openAboutFeedbackSubPage(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
