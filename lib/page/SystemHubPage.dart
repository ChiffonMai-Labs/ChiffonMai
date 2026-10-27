import '../widgets/CommunityAppearanceBanner.dart';
import '../widgets/PlayerExperienceStrip.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'HubComponents.dart';
import '../utils/FeatureRegistry.dart';
import 'SettingsPage.dart';
import 'DataBackupPage.dart';
import 'AutoSyncPage.dart';
import 'MaimaiServerStatusPage.dart';
import 'RecentCommentsPage.dart';
import 'RecentRatingsPage.dart';
import 'AboutAppPage.dart';
import 'Awmc/AwmcPlayCountSyncFlow.dart';
import 'SupportDeveloperPage.dart';
import 'FriendLinksPage.dart';
import 'LoadingTipsPage.dart';
import '../manager/LZYCheckUpdateManager.dart';
import '../manager/DivingFishProbeManager.dart';
import '../manager/DivingFish/ProberException.dart';
import '../manager/LuoXue/CollectionsManager.dart';
import '../entity/LuoXue/Collection.dart';
import '../service/ConnectivityService.dart';
import '../service/SyncStatsService.dart';
import '../utils/SyncRouteNotifier.dart';
import '../utils/HomeRefreshNotifier.dart';
import '../utils/RefreshErrorPresenter.dart';
import '../utils/UpdateNotifier.dart';
import '../widgets/SyncRouteFooter.dart';
import '../widgets/SyncStatsFooter.dart';
import '../widgets/AutoSyncStatusFooter.dart';
import '../widgets/SyncFlowMixin.dart';
import '../widgets/SyncScoreDialogs.dart' show SyncScoreDialogs, SyncCallbacks;
import '../widgets/CollectionPickerSheet.dart';
import '../service/LogExportService.dart';
import '../widgets/RefreshDataDialog.dart'
    show
        showRefreshDataDialog,
        executeRefreshData,
        refreshBest50DataWithProgress,
        executeAdvancedRefreshData,
        launchUrlFallback;
import '../widgets/AdvancedRefreshDataDialog.dart'
    show showAdvancedRefreshDataDialog;
import '../widgets/MaimaiHubLoginDialog.dart' show showMaimaiHubLoginDialog;
import '../constant/CacheKeyConstant.dart';
import '../constant/AppLinks.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../utils/LoginStateNotifier.dart';
import '../utils/UserProfileNotifier.dart';
import '../utils/AppTheme.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../utils/ExportPathUtil.dart';
import '../service/CommunityAvatarStore.dart';
import '../widgets/ErrorMessageDialog.dart';
import '../widgets/CacheManagementDialog.dart';
import '../service/CacheManagementService.dart';
import '../widgets/AccountRegistrationGuideDialog.dart';
import '../widgets/ConfettiEffect.dart';
import '../entity/FeatureModels.dart';

class SystemHubPage extends StatefulWidget {
  final VoidCallback onAccountManageTap;

  const SystemHubPage({super.key, required this.onAccountManageTap});

  @override
  State<SystemHubPage> createState() => SystemHubPageState();
}

class SystemHubPageState extends State<SystemHubPage> with SyncFlowMixin {
  /// 首页搜索调用系统 Hub 的原有入口，沿用同一份进度与互斥状态。
  Future<void> openFeature(ButtonItem item) async {
    if (anyBusy) {
      Fluttertoast.showToast(msg: '正在处理其它任务，请稍候');
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
    if (item.title == '刷新数据（高级）') {
      await _advancedRefreshData();
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
  bool _maimaiHubLoggedIn = false;

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
  bool _refreshingAdvanced = false;
  String _refreshAdvancedText = '';
  double _refreshAdvancedProgress = 0;
  bool _refreshingPlayCounts = false;
  String _refreshPlayCountsText = '';
  // 三个同步入口的进行状态由 SyncFlowMixin 持有（同步按钮上进度 + 互斥）。

  /// 任意长任务进行中：用于禁用其它入口，避免并发刷新互相踩缓存
  @override
  bool get anyBusy =>
      _loggingOut ||
      _refreshing ||
      _refreshingAdvanced ||
      _refreshingPlayCounts ||
      CacheManagementService.instance.reloadingBase ||
      !syncFlowsIdle ||
      HomeRefreshNotifier.isBusy.value;

  @override
  void initState() {
    super.initState();
    // 监听共享状态：首页登出水鱼账号 / 同步成功后此处也会自动刷新昵称 / QQ
    UserProfileNotifier.instance.addListener(_onUserProfileChanged);
    _onUserProfileChanged();
    CommunityAvatarStore.instance.addListener(_onAvatarChanged);
    LoginStateNotifier.instance.addListener(_onAvatarLoginChanged);
    unawaited(CommunityAvatarStore.instance.activate());
    _collectionsReady = Future.wait(
        [_fetchAvatarIcons(), _fetchExtraAppearance(), _fetchAvatarPlates()]);
    unawaited(_refreshMaimaiHubLoginState());
    // 线路 + 统计（与首页收藏区共享同一份状态；重复调用幂等）
    SyncRouteNotifier.instance.addListener(_onSyncRouteChanged);
    CacheManagementService.instance.addListener(_onSyncRouteChanged);
    SyncRouteNotifier.instance.ensureLoaded();
    HomeRefreshNotifier.isBusy.addListener(_onHomeRefreshBusyChanged);
  }

  Future<void> _refreshMaimaiHubLoginState() async {
    final token = await DivingFishProbeManager().ensureAuthToken();
    if (mounted) setState(() => _maimaiHubLoggedIn = token != null);
  }

  void _onSyncRouteChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CommunityAvatarStore.instance.removeListener(_onAvatarChanged);
    LoginStateNotifier.instance.removeListener(_onAvatarLoginChanged);
    UserProfileNotifier.instance.removeListener(_onUserProfileChanged);
    SyncRouteNotifier.instance.removeListener(_onSyncRouteChanged);
    CacheManagementService.instance.removeListener(_onSyncRouteChanged);
    HomeRefreshNotifier.isBusy.removeListener(_onHomeRefreshBusyChanged);
    super.dispose();
  }

  void _onHomeRefreshBusyChanged() {
    if (mounted) setState(() {});
  }

  /// 共享用户档案变更回调：把 notifier 中的值同步到本地字段，
  /// 我的页头像区昵称等区域立刻更新。
  void _onUserProfileChanged() {
    if (!mounted) return;
    final p = UserProfileNotifier.instance.value;
    setState(() {
      _userNickname = p.nickname;
    });
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

  void _showCollectionPicker() {
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
            if (store.value.playerId != player) {
              if (ctx.mounted) Navigator.pop(ctx);
              Fluttertoast.showToast(msg: '账号已切换，请重新选择装扮');
              return;
            }
            if (ctx.mounted) Navigator.pop(ctx);
            unawaited(save().catchError((Object _) {
              Fluttertoast.showToast(msg: '装扮未能保存，请重新选择');
            }));
          }

          return FutureBuilder<List<void>>(
              future: _collectionsReady,
              builder: (context, loaded) => ValueListenableBuilder<
                      AvatarSyncState>(
                  valueListenable: store,
                  builder: (context, state, _) => CollectionPickerSheet(
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
        subDir: '日志', title: '选择日志保存位置')) {
      return;
    }
    try {
      final file = await LogExportService.instance.export();
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('日志已导出'),
                content: SelectableText(file.path),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('知道了'))
                ],
              ));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出日志失败：$e')));
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
    // 统一走公共兜底：复制剪贴板 + SnackBar（各写一遍很容易漏掉复制那一步）
    launchUrlFallback(
      url,
      context,
      copyText: copyText,
      message: failMessage ?? '无法打开浏览器，$label已复制到剪贴板，请手动粘贴打开',
    );
  }

  /// 刷新数据：对话框只收集输入，进度显示在「刷新数据」这个按钮上。
  Future<void> _refreshData() async {
    if (anyBusy) return;
    final request = await showRefreshDataDialog(context);
    if (request == null || !mounted) return;

    setState(() {
      _refreshing = true;
      _refreshText = '正在刷新数据...';
      _refreshProgress = 0;
    });
    try {
      await executeRefreshData(request, onProgress: (p, t) {
        if (!mounted) return;
        setState(() {
          _refreshText = '$t $p%';
          _refreshProgress = p / 100;
        });
      });
      if (!mounted) return;
      ConfettiEffect.show(context);
      Fluttertoast.showToast(msg: '数据刷新成功!');
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
      }
    }
  }

  /// 高级模式刷新数据：弹新对话框，让用户按缓存源勾选强制刷新，并测试 API 连通性。
  /// 进度同样显示在按钮上（不再弹转圈对话框）。
  Future<void> _advancedRefreshData() async {
    if (anyBusy) return;
    final request = await showAdvancedRefreshDataDialog(context);
    if (request == null || !mounted) return;

    setState(() {
      _refreshingAdvanced = true;
      _refreshAdvancedText = '正在刷新数据...';
      _refreshAdvancedProgress = 0;
    });
    try {
      await executeAdvancedRefreshData(
        request,
        onProgress: (p, t) {
          if (!mounted) return;
          setState(() {
            _refreshAdvancedText = '$t $p%';
            _refreshAdvancedProgress = p / 100;
          });
        },
      );
      if (!mounted) return;
      ConfettiEffect.show(context);
      Fluttertoast.showToast(msg: '数据刷新成功!');
    } on ProberException catch (e) {
      // 未授权 → 直接拉起授权页；其余按统一文案提示。
      // 与首页刷新入口共用 presentRefreshError，避免两边行为不一致。
      if (mounted) await presentRefreshError(context, e, qq: request.qq.trim());
    } catch (e) {
      if (mounted) await presentRefreshError(context, e, qq: request.qq.trim());
    } finally {
      if (mounted) {
        setState(() {
          _refreshingAdvanced = false;
          _refreshAdvancedText = '';
        });
      }
    }
  }

  Future<void> _showCacheManagementDialog() async {
    if (anyBusy) {
      Fluttertoast.showToast(msg: '正在处理其它任务，请稍候');
      return;
    }
    final reload = await showCacheManagementDialog(context);
    if (reload != true || !mounted || anyBusy) return;
    try {
      await CacheManagementService.instance.reloadBaseMaidata();
      if (mounted) Fluttertoast.showToast(msg: '基础量 maidata 已重新拉取');
    } catch (error) {
      if (mounted) await showErrorMessageDialog(context, message: '重新拉取失败：$error');
    }
  }

  /// 独立读取机台游玩次数；普通成绩同步不再复用二维码调用这个接口。
  Future<void> _refreshPlayCounts() async {
    if (anyBusy) return;
    setState(() {
      _refreshingPlayCounts = true;
      _refreshPlayCountsText = '准备读取机台游玩次数…';
    });
    try {
      final outcome = await AwmcPlayCountSyncFlow.run(
        context,
        onBusy: (text) {
          if (mounted) setState(() => _refreshPlayCountsText = text);
        },
        onIdle: () {
          if (mounted) setState(() => _refreshPlayCountsText = '');
        },
      );
      if (!mounted || outcome.cancelled) return;
      Fluttertoast.showToast(
        msg: outcome.ok
            ? '游玩次数已更新（${outcome.cachedRecords} 条）'
            : '游玩次数读取失败：${outcome.message ?? '未知错误'}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _refreshingPlayCounts = false;
          _refreshPlayCountsText = '';
        });
      }
    }
  }

  Future<void> _checkUpdate() async {
    final isOnline = await ConnectivityService().hasConnection();
    if (!mounted) return;
    if (!isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前无网络连接，请联网后重试')),
      );
      return;
    }
    final updateManager = LZYCheckUpdateManager();
    updateManager.showUpdateDialog(context, force: true);
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

  void _loginDivingFish() {
    SyncScoreDialogs.showDivingFishLoginDialog(context, syncCallbacks);
  }

  Future<void> _loginMaimaiHub() async {
    if (anyBusy) return;
    final loggedIn = await showMaimaiHubLoginDialog(context);
    if (!mounted) return;
    if (loggedIn) {
      setState(() => _maimaiHubLoggedIn = true);
      Fluttertoast.showToast(msg: 'maimai Score Hub 登录状态已保存，现在可以使用 OCR 了');
    }
  }

  Future<bool> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认登出水鱼账号'),
        content: const Text('登出后将清除缓存的登录信息和 ImportToken，确定要登出吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('登出'),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// 登出水鱼账号：先弹出确认对话框，再清除账号相关缓存。
  Future<void> _logoutDivingFish() async {
    if (_loggingOut) return;
    if (!await _confirmLogout() || !mounted) return;
    setState(() {
      _loggingOut = true;
      _logoutText = '正在登出水鱼账号...';
    });
    try {
      await UserProfileNotifier.clearShuiyuAccountCache();
      if (!mounted) return;
      LoginStateNotifier.setLoggedIn(false);
      Fluttertoast.showToast(msg: '已登出水鱼账号');
    } catch (e) {
      debugPrint('登出水鱼账号失败：$e');
      if (mounted) {
        await showErrorMessageDialog(context, message: '登出水鱼账号失败：$e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loggingOut = false;
          _logoutText = '';
        });
      }
    }
  }

  String get _busyReason {
    final task = syncingDivingFish
        ? '同步成绩到水鱼'
        : syncingLuoXue
            ? '同步成绩到落雪'
            : syncingAwmcNet
                ? '同步成绩到 AWMC NET'
                : syncingMulti
                    ? '多端同步'
                    : _refreshingAdvanced
                        ? '高级数据刷新'
                        : _refreshingPlayCounts
                            ? '读取游玩次数'
                            : _loggingOut
                                ? '退出账号'
                                : _refreshing
                                    ? '数据刷新'
                                    : '首页数据刷新';
    return '$task正在进行中，不能使用本功能';
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) => ValueListenableBuilder<bool>(
          valueListenable: LoginStateNotifier.instance,
          builder: (context, loggedIn, __) {
            final features = <String, Widget>{
              '账号注册引导': HubActionTile(
                title: '账号注册引导',
                subtitle: '水鱼注册、落雪注册与 AWMC NET 档案创建引导',
                icon: Icons.person_add_alt_1_outlined,
                isFavorited: _isFavorited('账号注册引导'),
                onToggleFavorite: () => _toggleFavorite('账号注册引导'),
                onTap: () => showAccountRegistrationGuide(context),
              ),
              '账号管理': HubActionTile(
                title: '账号管理',
                subtitle: '查看已绑定的水鱼账号信息',
                icon: Icons.manage_accounts_outlined,
                isFavorited: _isFavorited('账号管理'),
                onToggleFavorite: () => _toggleFavorite('账号管理'),
                onTap: widget.onAccountManageTap,
              ),
              '登录 maimai Score Hub': HubActionTile(
                title: '登录 maimai Score Hub',
                subtitle: _maimaiHubLoggedIn
                    ? '已登录，可直接使用 OCR；点击可重新登录'
                    : '仅登录，不同步成绩；用于 OCR 与 maimai Score Hub 功能',
                icon: _maimaiHubLoggedIn
                    ? Icons.verified_user_outlined
                    : Icons.login_rounded,
                isFavorited: _isFavorited('登录 maimai Score Hub'),
                onToggleFavorite: () => _toggleFavorite('登录 maimai Score Hub'),
                onTap: _loginMaimaiHub,
                disabledReason: _busyReason,
                disabled: anyBusy,
              ),
              '登录水鱼': HubActionTile(
                title: loggedIn ? '登出水鱼账号' : '登录水鱼',
                subtitle: loggedIn ? '清除水鱼登录状态' : '获取 ImportToken 以使用同步功能',
                icon: loggedIn ? Icons.logout_rounded : Icons.login_rounded,
                isFavorited: _isFavorited(loggedIn ? '登出水鱼账号' : '登录水鱼'),
                onToggleFavorite: () =>
                    _toggleFavorite(loggedIn ? '登出水鱼账号' : '登录水鱼'),
                onTap: loggedIn ? _logoutDivingFish : _loginDivingFish,
                loading: _loggingOut,
                loadingText: _logoutText,
                disabledReason: _busyReason,
                disabled: anyBusy && !_loggingOut,
              ),
              '同步成绩到水鱼': HubActionTile(
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
                // 线路切换 + 统计：与首页「收藏的功能」区共用同一份状态
                footer: SyncRouteFooter(
                  platform: SyncPlatform.divingFish,
                  enabled: !anyBusy,
                ),
              ),
              '同步成绩到落雪': HubActionTile(
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
                footer: SyncRouteFooter(
                  platform: SyncPlatform.luoXue,
                  enabled: !anyBusy,
                ),
              ),
              '同步成绩到 AWMC NET': HubActionTile(
                title: '同步成绩到 AWMC NET',
                subtitle: '用机台二维码导入成绩到 AWMC NET',
                icon: Icons.cloud_upload_outlined,
                isFavorited: _isFavorited('同步成绩到 AWMC NET'),
                onToggleFavorite: () => _toggleFavorite('同步成绩到 AWMC NET'),
                // AWMC NET 只有「机台二维码」这一条写入路径（读成绩的 AWMC 数据源
                // 不需要登录），所以**没有线路切换器**，只有一行近 100 次统计
                // —— 也就是 SyncStatsFooter 而不是 SyncRouteFooter。
                // 等待进度与另外两个同步入口一样显示在这个按钮上。
                onTap: syncToAwmcNetWithButton,
                loading: syncingAwmcNet,
                loadingText: awmcNetText,
                showProgress: true,
                progressValue: awmcNetProgress,
                disabledReason: _busyReason,
                disabled: anyBusy && !syncingAwmcNet,
                // 统计行上提一点贴紧按钮：tile 底部本来就空着约 23px，
                // 一行小字挂在那里会显得离按钮太远（见 SyncStatsFooter.footerLift）
                footerLift: SyncStatsFooter.footerLift,
                footer: const SyncStatsFooter(
                  slot: (SyncLine.direct, SyncPlatform.awmc),
                ),
              ),
              '同步成绩到多端': HubActionTile(
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
              '自动同步': HubActionTile(
                title: '自动同步',
                subtitle: '每天定时同步成绩，解放双手',
                icon: Icons.schedule_outlined,
                isFavorited: _isFavorited('自动同步'),
                onToggleFavorite: () => _toggleFavorite('自动同步'),
                onTap: () => _open(context, const AutoSyncPage()),
                disabledReason: _busyReason,
                disabled: anyBusy,
                footerLift: SyncStatsFooter.footerLift,
                footer: AutoSyncStatusFooter(
                  onTap: () => _open(context, const AutoSyncPage()),
                ),
              ),
              '刷新数据': HubActionTile(
                title: '刷新数据',
                subtitle: '重新拉取并初始化所有本地缓存',
                icon: Icons.file_upload_sharp,
                isFavorited: _isFavorited('刷新数据'),
                onToggleFavorite: () => _toggleFavorite('刷新数据'),
                onTap: _refreshData,
                loading: _refreshing,
                loadingText: _refreshText,
                showProgress: true,
                progressValue: _refreshProgress,
                disabledReason: _busyReason,
                disabled: anyBusy && !_refreshing,
              ),
              '刷新数据（高级）': HubActionTile(
                title: '刷新数据（高级）',
                subtitle: '按缓存源勾选强制刷新，并测试各 API 连通性',
                icon: Icons.tune_rounded,
                isFavorited: _isFavorited('刷新数据（高级）'),
                onToggleFavorite: () => _toggleFavorite('刷新数据（高级）'),
                onTap: _advancedRefreshData,
                loading: _refreshingAdvanced,
                loadingText: _refreshAdvancedText,
                showProgress: true,
                progressValue: _refreshAdvancedProgress,
                disabledReason: _busyReason,
                disabled: anyBusy && !_refreshingAdvanced,
              ),
              '刷新机台游玩次数': HubActionTile(
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
              '数据备份': HubActionTile(
                title: '数据备份',
                subtitle: '导入或导出本地数据',
                icon: Icons.backup_outlined,
                isFavorited: _isFavorited('数据备份'),
                onToggleFavorite: () => _toggleFavorite('数据备份'),
                onTap: () => _open(context, const DataBackupPage()),
              ),
              '缓存管理': HubActionTile(
                title: '缓存管理',
                subtitle: '查看并清理音源、PV、maidata 缓存',
                loading: CacheManagementService.instance.reloadingBase,
                loadingText: CacheManagementService.instance.reloadText,
                progressValue: CacheManagementService.instance.reloadProgress,
                disabled: anyBusy && !CacheManagementService.instance.reloadingBase,
                icon: Icons.storage_outlined,
                isFavorited: _isFavorited('缓存管理'),
                onToggleFavorite: () => _toggleFavorite('缓存管理'),
                onTap: _showCacheManagementDialog,
              ),
              '系统设置': HubActionTile(
                title: '系统设置',
                subtitle: '调整主题、背景图、交互与同步选项',
                icon: Icons.palette_outlined,
                isFavorited: _isFavorited('系统设置'),
                onToggleFavorite: () => _toggleFavorite('系统设置'),
                onTap: () => _open(context, const SettingsPage()),
              ),
              '加载语录管理': HubActionTile(
                title: '加载语录管理',
                subtitle: '选择加载时展示的语录',
                icon: Icons.format_quote,
                isFavorited: _isFavorited('加载语录管理'),
                onToggleFavorite: () => _toggleFavorite('加载语录管理'),
                onTap: () => _open(context, const LoadingTipsPage()),
              ),
              '服务器状态': HubActionTile(
                title: '服务器状态',
                subtitle: '查看舞萌服务状态',
                icon: Icons.cloud_outlined,
                isFavorited: _isFavorited('服务器状态'),
                onToggleFavorite: () => _toggleFavorite('服务器状态'),
                onTap: () => _open(context, const MaimaiServerStatusPage()),
              ),
              '打印日志': HubActionTile(
                title: '打印日志',
                subtitle: '导出最近运行日志，方便排查问题',
                icon: Icons.receipt_long_outlined,
                isFavorited: _isFavorited('打印日志'),
                onToggleFavorite: () => _toggleFavorite('打印日志'),
                onTap: _exportLogs,
              ),
              '最近评论': HubActionTile(
                title: '最近评论',
                subtitle: '查看社区最近评论',
                icon: Icons.comment_outlined,
                isFavorited: _isFavorited('最近评论'),
                onToggleFavorite: () => _toggleFavorite('最近评论'),
                onTap: () => _open(context, const RecentCommentsPage()),
              ),
              '最近评分': HubActionTile(
                title: '最近评分',
                subtitle: '查看社区最近评分',
                icon: Icons.star_outline_rounded,
                isFavorited: _isFavorited('最近评分'),
                onToggleFavorite: () => _toggleFavorite('最近评分'),
                onTap: () => _open(context, const RecentRatingsPage()),
              ),
              '检查更新': // 「检查更新」在检测到新版本时会变成「发现新版本」+
// 绿色圆环箭头（见 UpdateAvailableIcon）。
// 点击逻辑两者完全一致，都是 _checkUpdate。
                  ValueListenableBuilder<UpdateAvailability?>(
                valueListenable: UpdateNotifier.available,
                builder: (context, update, _) {
                  if (update == null) {
                    return HubActionTile(
                      title: UpdateNotifier.idleTitle,
                      subtitle: UpdateNotifier.idleSubtitle,
                      icon: Icons.system_update_alt_outlined,
                      isFavorited: _isFavorited(UpdateNotifier.idleTitle),
                      onToggleFavorite: () =>
                          _toggleFavorite(UpdateNotifier.idleTitle),
                      onTap: _checkUpdate,
                    );
                  }
                  return HubActionTile(
                    title: UpdateNotifier.titleFor(update),
                    subtitle: UpdateNotifier.subtitleFor(
                        update, UpdateNotifier.idleSubtitle),
                    icon: Icons.arrow_upward_rounded,
                    titleColor: UpdateAvailableIcon.green,
                    leading: const UpdateAvailableIcon(),
                    isFavorited: _isFavorited(UpdateNotifier.idleTitle),
                    onToggleFavorite: () =>
                        _toggleFavorite(UpdateNotifier.idleTitle),
                    onTap: _checkUpdate,
                  );
                },
              ),
              '关于 APP': HubActionTile(
                title: '关于 APP',
                subtitle: '了解项目与版本信息',
                icon: Icons.info_outline_rounded,
                isFavorited: _isFavorited('关于 APP'),
                onToggleFavorite: () => _toggleFavorite('关于 APP'),
                onTap: () => _open(context, const AboutAppPage()),
              ),
              '访问官方网站': HubActionTile(
                title: '访问官方网站',
                subtitle: '前往 chiffonmai.cloud 查看项目主页',
                icon: Icons.public,
                isFavorited: _isFavorited('访问官方网站'),
                onToggleFavorite: () => _toggleFavorite('访问官方网站'),
                onTap: () => _launchExternal(
                  context,
                  AppLinks.officialSite,
                  '官网链接',
                  failMessage: '无法打开浏览器，官网链接已复制到剪贴板，'
                      '请粘贴到浏览器访问 ${AppLinks.officialSite}',
                ),
              ),
              '查看友情链接': HubActionTile(
                title: '查看友情链接',
                subtitle: '发现同好项目',
                icon: Icons.link_rounded,
                isFavorited: _isFavorited('查看友情链接'),
                onToggleFavorite: () => _toggleFavorite('查看友情链接'),
                onTap: () => _open(context, const FriendLinksPage()),
              ),
              '问题反馈': HubActionTile(
                title: '问题反馈',
                subtitle: '反馈使用中遇到的问题',
                icon: Icons.feedback_outlined,
                isFavorited: _isFavorited('问题反馈'),
                onToggleFavorite: () => _toggleFavorite('问题反馈'),
                onTap: () =>
                    _launchExternal(context, AppLinks.feedbackUrl, '反馈链接'),
              ),
              '加入 QQ 群': HubActionTile(
                title: '加入 QQ 群',
                subtitle: '一键跳转官方交流群（${AppLinks.qqGroupNumber}）',
                icon: Icons.groups_outlined,
                isFavorited: _isFavorited('加入 QQ 群'),
                onToggleFavorite: () => _toggleFavorite('加入 QQ 群'),
                onTap: () => _launchExternal(
                  context,
                  AppLinks.qqGroupJoinUrl,
                  '群号',
                  // 加群链接在浏览器里只是个空壳中转页，所以要复制**群号**
                  copyText: AppLinks.qqGroupNumber,
                  failMessage: '没能跳转到 QQ，群号 ${AppLinks.qqGroupNumber} '
                      '已复制到剪贴板，可在 QQ 里搜索加入',
                ),
              ),
              '问卷调查': HubActionTile(
                title: '问卷调查',
                subtitle: '助力 ChiffonMai 更上一层楼',
                icon: Icons.poll_outlined,
                isFavorited: _isFavorited('问卷调查'),
                onToggleFavorite: () => _toggleFavorite('问卷调查'),
                onTap: () =>
                    _launchExternal(context, AppLinks.surveyUrl, '问卷链接'),
              ),
              '支持开发者': HubActionTile(
                title: '支持开发者',
                subtitle: '支持项目持续更新',
                icon: Icons.volunteer_activism_outlined,
                isFavorited: _isFavorited('支持开发者'),
                onToggleFavorite: () => _toggleFavorite('支持开发者'),
                onTap: () => _open(context, const SupportDeveloperPage()),
              ),
            };
            final sections = FeatureRegistry.sections['我的']!;
            return HubPageScaffold(
              title: '我的',
              subtitle: '账号、同步、备份与应用偏好',
              icon: Icons.person_rounded,
              hero: Column(children: [
                CommunityAppearanceBanner(
                  appearance: CommunityAvatarStore.instance.value,
                  nickname: _userNickname,
                  onPickTap: _showCollectionPicker,
                  onRetry: () =>
                      unawaited(CommunityAvatarStore.instance.retry()),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  child: const MyPlayerExperience(),
                ),
              ]),
              children: [
                for (final section in sections) ...[
                  HubSection(
                    title: section.title,
                    subtitle: section.subtitle,
                    icon: section.icon,
                    badgeCount: section.titles.length,
                    contentPadding: section.title == '单平台同步' ||
                            section.title == '批量与定时同步'
                        ? const EdgeInsets.only(bottom: 8)
                        : EdgeInsets.zero,
                    children: [
                      for (final title in section.titles) features[title]!
                    ],
                  ),
                  if (section != sections.last) const SizedBox(height: 24),
                ],
              ],
            );
          },
        ),
      );
}
