import '../l10n/LocalizationsExtension.dart';
import '../widgets/AccountAuthorizationStatus.dart';
import 'CustomTagsPage.dart';
import '../widgets/DivingFishAuthorizationDialog.dart' show fetchDivingFishProfile;
import '../l10n/FeatureLocalizations.dart';
import '../service/GuessChartGame/GuessAudioService.dart';
import 'GuessChartGame/GuessGameSettingsPage.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/MainNavigationInsets.dart';
import '../utils/SearchInteractionPreferences.dart';
import '../utils/DivingFishMaskStatus.dart';
import '../service/RankingList/RankingUploadGuard.dart';
import '../utils/CoverUtil.dart';
import '../entity/DivingFish/Song.dart';
import '../service/SongSearchService.dart';
import 'SongInfoPage.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/page/RankingList/AvgScoreRankingListPage.dart';
import 'package:my_first_flutter_app/page/RankingList/FittedRatingRankingListPage.dart';
import 'package:my_first_flutter_app/page/RankingList/RatingRankListPage.dart';
import 'package:my_first_flutter_app/page/RankingList/SpecialRankingListPage.dart';
import 'package:my_first_flutter_app/service/RankingList/AvgRankingListService.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../constant/AppLinks.dart';
import '../constant/LoadingTipsConstant.dart';
import '../service/HomeService.dart';
import '../manager/LZYCheckUpdateManager.dart';
import '../widgets/ThemePreferenceControls.dart';
import '../widgets/AccountRegistrationGuideDialog.dart';
import '../service/CacheManagementService.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import '../utils/AppTheme.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../utils/AppConstants.dart';
import '../utils/SecureCredentialStore.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'DifficultyDistributionPage.dart';
import 'SettingsPage.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../manager/MaidataManager.dart';
import '../manager/SongAliasManager.dart';
import '../entity/FeatureModels.dart';
import 'HubComponents.dart';
import 'FeatureCategoryPage.dart';
import '../utils/FeatureRegistry.dart';
import 'AchievementFullReverseCalculatorPage.dart';
import 'AchievementRateCalculatorPage.dart';
import '../widgets/SyncScoreDialogs.dart';
import 'VersionViewPage.dart';
import 'Best50/Best50Page.dart';
import 'Best50/DiffBest50Page.dart';
import 'Best50/PersonalizedBest50Page.dart';
import 'Best50/PersonalizedDiffBest50Page.dart';
import 'Best50/CustomBest50Page.dart';
import 'Best50/IdealBest50Page.dart';
import 'History/RatingHistoryPage.dart';
import 'History/ScoreImprovementHistoryPage.dart';
import 'GlobalArcadeMapPage.dart';
import 'Collection/CollectionSearchPage.dart';
import 'GuessChartGame/GuessChartByAliaPage.dart';
import 'GuessChartGame/GuessChartByBlurredCoverPage.dart';
import 'GuessChartGame/GuessChartByCoverPage.dart';
import 'GuessChartGame/GuessChartByInfoPage.dart';
import 'GuessChartGame/GuessChartBySongExcerptPage.dart';
import 'GuessChartGame/GuessSongByOpenLettersPage.dart';
import 'GuessChartGame/GuessChartByFlashCoverPage.dart';
import 'GuessChartGame/GuessChartByTileRevealPage.dart';
import 'GuessChartGame/GuessChartByChartPeekPage.dart';
import 'KaleidXScope/KaleidXScopeSelectPage.dart';
import 'FavoriteFolderPage.dart';
import 'MaimaiServerStatusPage.dart';
import 'Multiplayer/MultiplayerLobbyPage.dart';
import 'PaiziProgressPage.dart';
import 'PersonalizedChartPlayConfigure.dart';
import 'Portable/PortablePlayerPage.dart';
import 'NextPlayQueuePage.dart';
import 'LoadingTipsPage.dart';
import 'PersonalizedScorePage.dart';
import 'RankTable/RankTablePage.dart';
import 'RandomChartPage.dart';
import 'AttendanceWheelPage.dart';
import 'RatingRecommendPage.dart';
import 'GainRecommendPage.dart';
import 'DsRangeRecommendPage.dart';
import 'RecommendByTagsPage.dart';
import 'SingleRatingCalculatorPage.dart';
import 'SongSearchPage.dart';
import 'UnionUpdateComparePage.dart';
import 'UpdateCalendarPage.dart';
import 'UserScoreSearchPage.dart';
import 'AboutAppPage.dart';
import 'SupportDeveloperPage.dart';
import 'FriendLinksPage.dart';
import 'CoverRecognitionPage.dart';
import 'ScoreOcrPage.dart';
import 'DataBackupPage.dart';
import 'DailyRecommendPage.dart';
import '../widgets/RefreshDataDialog.dart'
    show
        showRefreshDataDialog,
        executeRefreshData,
        executeAdvancedRefreshData,
        RefreshDataRequest,
        CurrentDataSourceNotifier,
        RefreshDataSource,
        refreshBest50DataWithProgress,
        launchUrlFallback;
// PLAYER OVERVIEW 卡片上半部分 → 「刷新数据（高级）」对话框
import '../widgets/AdvancedRefreshDataDialog.dart'
    show showAdvancedRefreshDataDialog;
import 'FriendComparePage.dart';
import 'RecentCommentsPage.dart';
import 'RecentRatingsPage.dart';
import '../manager/DivingFishProbeManager.dart';
import 'package:my_first_flutter_app/utils/FavoriteFeaturesNotifier.dart';
import 'package:my_first_flutter_app/utils/LoginStateNotifier.dart';
import 'package:my_first_flutter_app/utils/UserProfileNotifier.dart';
import '../widgets/AccountSwitchSheet.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import '../widgets/QrQuickFillButtons.dart';
import '../service/SyncStatsService.dart';
import '../service/AutoSyncService.dart';
import '../utils/SyncRouteNotifier.dart';
import '../utils/HomeRefreshNotifier.dart';
import '../utils/RefreshErrorPresenter.dart';
import '../widgets/ErrorMessageDialog.dart';
import '../utils/UpdateNotifier.dart';
import '../widgets/ConfettiEffect.dart';
import '../widgets/SyncFlowMixin.dart';
import '../widgets/QuickSearchBar.dart';
import '../widgets/FeatureSearchOverlay.dart';
import '../widgets/MarqueeText.dart';
import '../service/CommunityAvatarStore.dart';
import '../widgets/CommunityAvatar.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/HomeStatusWidgets.dart';
import '../service/HomeWidgetService.dart';
import 'package:my_first_flutter_app/widgets/FavoriteEditGrid.dart';

// ds值与歌曲对应关系数据类已随 _calculateRatingLimits 一起抽离到
// lib/widgets/RefreshDataDialog.dart，不再需要此处的定义。

// 首页初始化时间间隔常量
class _InitInterval {
  static const Duration initializationCooldown = Duration(days: 7);
}

class _AwmcNetTokenSection extends StatefulWidget {
  final Brightness brightness;

  const _AwmcNetTokenSection({required this.brightness});

  @override
  State<_AwmcNetTokenSection> createState() => _AwmcNetTokenSectionState();
}

class _AwmcNetTokenSectionState extends State<_AwmcNetTokenSection> {
  final TextEditingController _controller = TextEditingController();
  bool _checking = true;
  bool _hasToken = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final value =
        await SecureCredentialStore.read(CacheKeyConstant.awmcNetImportToken);
    if (!mounted) return;
    setState(() {
      _hasToken = value?.isNotEmpty == true;
      _checking = false;
    });
  }

  Future<void> _openGuide() async {
    final uri = Uri.parse('https://net.wmc.pub/settings/');
    try {
      if (!await ExternalLaunchUtil.open(uri) && mounted) {
        launchUrlFallback(uri.toString(), context);
      }
    } catch (e) {
      debugPrint('打开 AWMC NET 设置链接失败: $e');
      if (mounted) launchUrlFallback(uri.toString(), context);
    }
  }

  Future<void> _save() async {
    final token = _controller.text.trim();
    if (token.isEmpty) {
      AppToast.show(context.l10n.flowEnterYourAWMCNETTokenFirst,
          tone: AppToastTone.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      final message = await AutoSyncService.instance
          .savePersonalCredential(SyncPlatform.awmc, token);
      if (!mounted) return;
      setState(() {
        _hasToken = true;
        _controller.clear();
      });
      AppToast.show(message);
    } catch (_) {
      if (mounted)
        AppToast.show(context.l10n.flowCouldNotSaveYourPersonalKeyTry,
            tone: AppToastTone.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final message = await AutoSyncService.instance
          .clearPersonalCredential(SyncPlatform.awmc);
      if (!mounted) return;
      setState(() => _hasToken = false);
      AppToast.show(message);
    } catch (_) {
      if (mounted)
        AppToast.show(context.l10n.flowCouldNotDisableAutoSyncYourKey,
            tone: AppToastTone.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Icon(
              _hasToken ? Icons.check_circle : Icons.vpn_key,
              size: 18,
              color: _hasToken
                  ? AppColors.successGreen(brightness)
                  : AppColors.greyHint(brightness),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.flowAWMCNETScoreImportToken,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_checking)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else ...[
          if (_hasToken)
            Text(
              context.l10n.flowSet,
              style: TextStyle(
                color: AppColors.successGreen(brightness),
                fontSize: 13,
              ),
            )
          else ...[
            Text(
              context.l10n.flowNotSet,
              style: TextStyle(
                color: AppColors.warningOrange(brightness),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _openGuide,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: context.l10n.flowVisit,
                        style: TextStyle(fontSize: 12)),
                    TextSpan(
                      text: 'https://net.wmc.pub/settings/',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: context.l10n.flowToGenerateOrRotateYourTokenAt,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText:
                          context.l10n.flowPasteYourAWMCNETScoreImportToken,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.save, style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
          if (_hasToken) ...[
            // 与落雪密钥区一致：紧贴「已设置」一行，去掉 TextButton 默认的上下留白。
            const SizedBox(height: 2),
            TextButton(
              onPressed: _clear,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                context.l10n.flowClearToken,
                style: TextStyle(
                    color: AppColors.errorRed(brightness), fontSize: 12),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// 首页功能搜索结果，保留分类信息以便展示功能路径。
class _HomeFeatureSearchEntry {
  final ButtonCategory category;
  final ButtonItem item;

  const _HomeFeatureSearchEntry(this.category, this.item);
}

// 应用常量类：集中管理所有硬编码的配置值

// ButtonItem / ButtonCategory 已移至 ../entity/FeatureModels.dart

/// 首页页头的问候语：`欢迎回来，<昵称>`，**永远单行、整行同字号**。
///
/// ── 为什么需要它 ──
/// 360dp 屏上页头可用宽度只有约 272px（左右各 20px 页边距 + 右侧主题按钮 48px）。
/// 「欢迎回来，」在 24px 下要占 120px，留给昵称的只剩约 150px ——
/// **6 个汉字就开始换行**，而机台昵称最长 8 个字，几乎人人都会撞上（实测 8 字
/// 昵称确实会排成两行）。页头一旦变两行，下面的仪表盘就整体往下跳。
///
/// ── 做法 ──
/// **不做大小混排**：问候语和昵称用同一个字号。放不下时按 `可用宽度 / 实际宽度`
/// 把**整行等比缩小**（最短缩到 [minFontSize]），再放不下才用省略号收尾。
/// 也就是说：昵称不长时和以前**一模一样**（原字号、原位置），只有长昵称才会
/// 整行小一点点 —— 换来的是不换行、也不截掉名字。
///
/// 行高按原字号固定预留，所以不管昵称多长，页头高度都不变。
///
/// 回归测试：`test/home_greeting_test.dart`。
class HomeGreetingText extends StatelessWidget {
  /// 用户昵称；空串表示还没登录（这时显示登录引导）。
  final String nickname;

  /// 允许缩到的最小字号。再小就不好看了，改用省略号。
  static const double minFontSize = 16;

  /// 基准字号；不传时用主题的 headlineSmall。
  final double? fontSize;

  const HomeGreetingText({super.key, required this.nickname, this.fontSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base =
        theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800);
    final baseSize = fontSize ?? base?.fontSize ?? 24;
    final isHint = nickname.trim().isEmpty;
    final text = isHint
        ? context.featureText('前往「我的」同步数据')
        : context.l10n.homeWelcome(nickname);

    return LayoutBuilder(
      builder: (context, constraints) {
        // ⚠️ 量宽度必须用**真正渲染时的样式**（合并环境 DefaultTextStyle，
        // 并带上 textScaler），否则字距和系统字体缩放都会漏算 —— 详见 AGENTS.md §8
        final style = DefaultTextStyle.of(context).style.merge(base);
        final scaler = MediaQuery.textScalerOf(context);

        TextPainter layoutAt(double size) => TextPainter(
              text: TextSpan(text: text, style: style.copyWith(fontSize: size)),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();

        final basePainter = layoutAt(baseSize);
        final available = constraints.maxWidth;
        // 行高按**原字号**预留：昵称长短不影响页头高度
        final lineHeight = basePainter.size.height;

        var size = baseSize;
        if (basePainter.size.width > available) {
          size = (baseSize * available / basePainter.size.width)
              // 引导语是固定文案，不能被省略号截断，放不下时继续缩小。
              .clamp(isHint ? 11.0 : minFontSize, baseSize);
        }

        return SizedBox(
          height: lineHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            // 整行同字号：一个 Text 就够，不用 Text.rich 分段
            child: Text(
              text,
              style: style.copyWith(fontSize: size),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

/// 首页组件：有状态组件，包含所有页面元素和业务数据
class HomePage extends StatefulWidget {
  final VoidCallback? onFirstFrameRendered;
  final VoidCallback? onEntertainmentTap;
  final Future<void> Function(ButtonItem)? onSystemFeatureTap;

  const HomePage(
      {super.key,
      this.onFirstFrameRendered,
      this.onEntertainmentTap,
      this.onSystemFeatureTap});

  @override
  State<HomePage> createState() => HomePageState();
}

/// 首页状态类：处理页面状态、存储数据、实现布局构建
class HomePageState extends State<HomePage> with SyncFlowMixin {
  void showAccountManageDialog() {
    if (!mounted) return;
    _showAccountManageDialog(context);
  }

  // 后台初始化状态
  bool _isBackgroundInitializing = false;
  bool _isInitializationCompleted = false;
  String _initializationProgress = '';
  String _hubSearchQuery = '';
  final _featureSearchFieldKey = GlobalKey();
  bool _featureSearchOpen = false;
  bool _sortingFavorites = false;

  /// 「搜索」按钮在非弹层模式下展开的内联搜索框。

  // 用户数据（昵称 / Rating）：实际数据来自 UserProfileNotifier，字段保留便于本地访问
  String _userNickname = "";
  // 0 表示尚未从水鱼/落雪拉取真实数据；UI 层用 _displayBest* 回落为 "-"
  int _best50TotalRA = 0;
  int _best35TotalRA = 0;
  int _best15TotalRA = 0;

  // 缓存的QQ号（实际数据来自 UserProfileNotifier，字段保留便于本地访问）

  /// 任意长任务进行中：收藏区那三个同步入口之间也要互斥，
  /// 否则能同时点起两个同步互相踩缓存（「系统」hub 页一直有这个保护）。
  @override
  bool get anyBusy =>
      !syncFlowsIdle ||
      _isRefreshing ||
      CacheManagementService.instance.reloadingBase;

  // 初始化方法，用于从本地存储加载数据
  @override
  void initState() {
    super.initState();
    // 监听用户档案共享状态（昵称 / Rating / QQ 跨页面同步）
    SearchInteractionPreferences.instance
        .addListener(_onSearchInteractionChanged);
    SearchInteractionPreferences.instance.load();
    UserProfileNotifier.instance.addListener(_onUserProfileChanged);
    _onUserProfileChanged();
    _loadUserData();
    _checkDivingFishLoginStatus();
    // 注意：收藏列表的实时同步不再走 addListener，
    // 而是直接在 build 顶层用 ValueListenableBuilder<FavoritesPayload>
    // 包整个 Scaffold，确保 IndexedStack 内任意子页面点星标时首页都能立即重建。
    // 无论冷却状态如何，都先加载别名缓存到内存
    // 防止冷却期间别名丢失（详见：冷却逻辑在_initializeDataInBackground内）
    SongAliasManager.instance.init();
    _initializeDataInBackground();
    // 同步入口的线路 + 统计（与「系统」hub 页共享同一份状态；重复调用幂等）
    SyncRouteNotifier.instance.addListener(_onSyncRouteChanged);
    CacheManagementService.instance.addListener(_onSyncRouteChanged);
    SyncRouteNotifier.instance.ensureLoaded();
    CommunityAvatarStore.instance.addListener(_pushDesktopProfile);
    unawaited(CommunityAvatarStore.instance.activate());

    // 在第一帧渲染完成后触发字体加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onFirstFrameRendered?.call();
      // 桌面小组件上点的功能，从这里打开
      unawaited(HomeWidgetService.listen((action) {
        if (mounted) _openFeatureByTitle(action);
      }));
    });
  }

  /// 桌面小组件上的头像和昵称。
  void _pushDesktopProfile() {
    unawaited(HomeWidgetService.pushProfile(
      nickname: _userNickname.isEmpty ? kUnsetNicknameLabel : _userNickname,
      avatarId: CommunityAvatarStore.instance.value.avatarId,
    ));
  }

  // 从本地存储加载用户数据
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNickname = prefs.getString('userNickname') ?? '';
      // 0 表示尚未拉到真实数据，UI 显示为 "-"
      _best50TotalRA = prefs.getInt('best50TotalRA') ?? 0;
      _best35TotalRA = prefs.getInt('best35TotalRA') ?? 0;
      _best15TotalRA = prefs.getInt('best15TotalRA') ?? 0;
    });
    unawaited(HomeWidgetService.pushRating(
      total: _best50TotalRA,
      b35: _best35TotalRA,
      b15: _best15TotalRA,
    ));
    _pushDesktopProfile();
  }

  // 更新初始化进度
  void _updateProgress(String message) {
    if (mounted) {
      setState(() => _initializationProgress = message);
    }
  }

  // 后台初始化数据 - 使用 HomeService
  Future<void> _initializeDataInBackground() async {
    // 曲库缓存是否可用：用于「冷却期内但缓存缺失」的抢占式兜底。
    //
    // 背景（真实故障）：冷却期只看 `lastInitializationTimestamp`，一旦上次
    // 初始化**失败/被跳过**（离线、接口 502、恢复备份后 prefs 被清空……）
    // 而这个时间戳照样被写下，就会连续 7 天跳过自动初始化。结果是
    // `cachedSongs` 长期为空，所有单人猜歌页抽不到曲 → 永久转圈。
    // 所以缓存缺失时必须无视冷却期，立刻补一次拉取。
    final hasSongCache = await MaimaiMusicDataManager().hasValidMusicCache(
      maxAge: const Duration(days: 30),
    );

    if (hasSongCache) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastInitMillis =
            prefs.getInt(CacheKeyConstant.lastInitializationTimestamp);
        if (lastInitMillis != null) {
          final lastInit = DateTime.fromMillisecondsSinceEpoch(lastInitMillis);
          final diff = DateTime.now().difference(lastInit);
          if (diff < _InitInterval.initializationCooldown) {
            debugPrint(
                '距上次初始化仅 ${diff.inHours} 小时，跳过自动初始化（冷却时间：${_InitInterval.initializationCooldown.inHours} 小时）');
            return;
          }
        }
      } catch (e) {
        debugPrint('检查上次初始化时间失败: $e，继续执行初始化');
      }
    } else {
      debugPrint('曲库缓存缺失，无视 7 天冷却期，立即执行数据初始化');
    }

    if (mounted) {
      setState(() {
        _isBackgroundInitializing = true;
        _initializationProgress = context.l10n.homeInitWorking;
      });
    }

    final result = await HomeService().initializeDataInBackground(
      onProgress: _updateProgress,
    );

    if (mounted) {
      setState(() {
        _isBackgroundInitializing = false;
        if (result.success) {
          _isInitializationCompleted = true;
          _initializationProgress =
              context.l10n.homeInitFinished(result.durationStr);
        } else {
          _initializationProgress =
              context.l10n.homeInitFailed("${result.errorMessage}");
        }
      });

      // 冷却时间戳只在「曲库真的拿到了」时才写。
      //
      // 原先无论成功与否都写，于是「首次启动时没网」会让 App 认下这次初始化，
      // 接下来 7 天都不再自动补拉，`cachedSongs` 一直是空的 ——
      // 这正是「所有单人猜歌卡加载页」的成因之一。
      final libraryReady = await MaimaiMusicDataManager().hasValidMusicCache(
        maxAge: const Duration(days: 30),
      );
      if (result.success && libraryReady) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            CacheKeyConstant.lastInitializationTimestamp,
            DateTime.now().millisecondsSinceEpoch,
          );
        } catch (e) {
          debugPrint('保存初始化时间戳失败: $e');
        }
      } else if (result.success) {
        debugPrint('曲库仍为空，不记录初始化时间戳（下次进首页会重试）');
      }

      if (!mounted) return;
      // 4秒后隐藏完成提示
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isInitializationCompleted = false;
            _initializationProgress = '';
          });
        }
      });
    }
  }

  // 保存QQ号到本地存储
  Future<void> _saveQQ(String qq) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.probeDivingFishBindQQ, qq);
  }

  // 使用 ValueNotifier 以便 FeatureCategoryPage 等子页面也能响应登录状态变化
  final ValueNotifier<bool> _loginStateNotifier = ValueNotifier<bool>(false);
  bool get _isDivingFishLoggedIn => _loginStateNotifier.value;

  @override
  void dispose() {
    CommunityAvatarStore.instance.removeListener(_pushDesktopProfile);
    UserProfileNotifier.instance.removeListener(_onUserProfileChanged);
    SearchInteractionPreferences.instance
        .removeListener(_onSearchInteractionChanged);
    SyncRouteNotifier.instance.removeListener(_onSyncRouteChanged);
    CacheManagementService.instance.removeListener(_onSyncRouteChanged);
    _loginStateNotifier.dispose();
    super.dispose();
  }

  /// 线路 / 统计变化时重建首页（收藏区那一行要立刻反映）。
  void _onSyncRouteChanged() {
    if (mounted) setState(() {});
  }

  /// 渲染用的 Rating：值为 0 时回落为 "-"，避免暴露 15049/10670/4379 这类硬编码占位。
  String _displayBest50RA() => _best50TotalRA == 0 ? '-' : '$_best50TotalRA';
  String _displayBest35RA() => _best35TotalRA == 0 ? '-' : '$_best35TotalRA';
  String _displayBest15RA() => _best15TotalRA == 0 ? '-' : '$_best15TotalRA';

  /// 共享用户档案变更回调：把 notifier 中的值同步到本地字段，
  /// 触发 setState 后首页"欢迎回来，xxx" / 仪表盘 Rating 等区域立刻更新。
  void _onUserProfileChanged() {
    if (!mounted) return;
    final p = UserProfileNotifier.instance.value;
    setState(() {
      _userNickname = p.nickname;
      _best50TotalRA = p.best50TotalRA;
      _best35TotalRA = p.best35TotalRA;
      _best15TotalRA = p.best15TotalRA;
    });
    unawaited(HomeWidgetService.pushRating(
      total: _best50TotalRA,
      b35: _best35TotalRA,
      b15: _best15TotalRA,
    ));
    _pushDesktopProfile();
  }

  Future<void> _checkDivingFishLoginStatus() async {
    final jwt = await SecureCredentialStore.read(
            CacheKeyConstant.probeDivingFishToken) ??
        '';
    // 只更新 ValueNotifier；登录态变化本身就是触发重建的信号，不需要再 setState
    final loggedIn = jwt.isNotEmpty;
    _loginStateNotifier.value = loggedIn;
    // 同步共享 LoginStateNotifier，让"我的"页等监听者也能感知登录态变化
    LoginStateNotifier.setLoggedIn(loggedIn);
  }

  Future<void> _toggleFavorite(String title) async {
    // 通过共享 notifier 切换；顶层 ValueListenableBuilder 会随之重建首页 UI。
    await FavoriteFeaturesNotifier.toggle(title);
  }

  Future<void> _logoutDivingFish() async {
    // 集中清理：清掉水鱼账号相关的所有成绩 / 缓存（保留歌曲 / 收藏品等静态数据）
    if (!mounted) return;
    // 立即给出视觉反馈：清缓存是逐键移除，可能耗时较久，先弹一个加载框
    // 避免出现"点了半天没反应"的空白等待。
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(context.l10n.flowSigningOutOfDivingFish),
          ],
        ),
      ),
    );
    try {
      await UserProfileNotifier.clearShuiyuAccountCache();
    } catch (e) {
      debugPrint('登出水鱼账号失败：$e');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        await showErrorMessageDialog(context,
            message: context.l10n.flowSignOutFailedP0((e).toString()));
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    LoginStateNotifier.setLoggedIn(false);
    _loginStateNotifier.value = false;
    AppToast.show(context.l10n.flowSignedOutOfDivingFish,
        tone: AppToastTone.success);
  }

  List<ButtonCategory> get _buttonCategories =>
      FeatureRegistry.allCategories(_isDivingFishLoggedIn);

  /// 不参与首页搜索和收藏的分类名集合
  static const Set<String> _excludedFromSearch = <String>{};

  /// 参与首页搜索和收藏的分类（已过滤掉 _excludedFromSearch 中的项）
  List<ButtonCategory> get _searchableCategories => _buttonCategories
      .where((c) => !_excludedFromSearch.contains(c.name))
      .toList();

  @override
  Widget build(BuildContext context) {
    // 顶层直接监听共享收藏列表：
    //   IndexedStack 子页面点星标 / 收藏管理页删除收藏 / 其他 Hub 页切换收藏时，
    //   整页 Scaffold 必定重建，"收藏的功能"区域即时刷新。
    //   不依赖 addListener 隐式 setState（IndexedStack 中非可见子页在某些情况下
    //   不会触发自身的 markNeedsBuild 链路）。
    return ValueListenableBuilder<FavoritesPayload>(
      valueListenable: FavoriteFeaturesNotifier.instance,
      builder: (context, payload, _) {
        // 收藏数据完全由 notifier 提供，首页不再自行读一遍 prefs
        return _buildScaffold(context, payload.titles);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Set<String> favoriteTitles) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppDesignTokens.gutter + 4,
            10,
            AppDesignTokens.gutter + 4,
            24 + MainNavigationInsets.bottomOf(context),
          ),
          children: [
            _buildHomeHeader(context),
            const SizedBox(height: 20),
            // 输入时收起概览和状态小组件，让搜索框升到结果上方、不被键盘挡住。
            // 这里只换这一格的内容：搜索框在列表里的位置不变，否则输入框会被
            // 重建，焦点一丢键盘就收回去了（§22.12）。
            AnimatedSize(
              duration:
                  AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
              curve: AppDesignTokens.emphasizedCurve,
              alignment: Alignment.topCenter,
              child: _hubSearchQuery.trim().isNotEmpty
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDashboardSummary(context, brightness),
                        if (_refreshText.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildRefreshProgress(context),
                        ],
                        const SizedBox(height: 20),
                        EntranceAnimation(
                          duration: const Duration(milliseconds: 500),
                          baseDelay: const Duration(milliseconds: 120),
                          offset: const Offset(0, 12),
                          child: _buildStatusWidgets(),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            // 选了浮层搜索时，输入框只是入口，点开后从这里展开浮层。
            Opacity(
              key: _featureSearchFieldKey,
              opacity: _featureSearchOpen ? 0 : 1,
              child: QuickSearchBar(
                padding: EdgeInsets.zero,
                query: _hubSearchQuery,
                hintText: context.featureText(
                    SearchInteractionPreferences.instance.homeSearchScope.hint),
                onTap: SearchInteractionPreferences.instance.usesOverlay
                    ? _openHomeFeatureSearch
                    : null,
                onChanged: (query) {
                  if (mounted) setState(() => _hubSearchQuery = query.trim());
                },
              ),
            ),
            if (_hubSearchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildHomeFeatureSearchResults(
                  context, _hubSearchQuery, _handleFeatureTap),
            ] else ...[
              const SizedBox(height: 20),
              // 顶层监听保证收藏区跨页面实时刷新。
              _buildFavoriteFeaturesSection(context, favoriteTitles),
              if (_isBackgroundInitializing || _isInitializationCompleted) ...[
                const SizedBox(height: 16),
                _buildInitializationStatus(context),
              ],
            ],
            _HomeSearchKeyboardSpacer(
                coveredBottom: MainNavigationInsets.bottomOf(context)),
          ],
        ),
      ),
    );
  }

  /// 顶部一行：头像（环色 = Rating 段位）、问候 + 数据源、搜索、主题。
  Widget _buildHomeHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tier = AppColors.ratingTier(_best50TotalRA);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: _best50TotalRA > 0
                ? SweepGradient(colors: [...tier.colors, tier.colors.first])
                : null,
            color: _best50TotalRA > 0 ? null : scheme.outlineVariant,
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              color: scheme.surface,
            ),
            // 社区头像：与「我的」页、排行榜里的是同一个
            child: ValueListenableBuilder<AvatarSyncState>(
              valueListenable: CommunityAvatarStore.instance,
              builder: (context, appearance, _) => CommunityAvatar(
                avatarId: appearance.avatarId,
                size: 39,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              HomeGreetingText(nickname: _userNickname, fontSize: 17),
              const SizedBox(height: 3),
              _buildDataSourceChip(context),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _headerIconButton(
          context,
          tooltip: context.featureText('主题与导航设置'),
          icon: Theme.of(context).brightness == Brightness.dark
              ? Icons.dark_mode_outlined
              : Icons.light_mode_outlined,
          onPressed: _showThemeDialog,
        ),
      ],
    );
  }

  Widget _headerIconButton(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppSurfaces.card(context),
        foregroundColor: scheme.onSurface,
        fixedSize: const Size(44, 44),
      ),
      icon: Icon(icon, size: 20),
    );
  }

  /// 点「数据源」即可切换 水鱼 / 落雪 / AWMC NET 账号（使用缓存，不联网）。
  /// 用**短名**：`AWMC NET` 在窄屏上放不下，与排行榜 Tab 的叫法一致。
  Widget _buildDataSourceChip(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder<RefreshDataSource>(
      valueListenable: CurrentDataSourceNotifier.instance,
      builder: (context, source, _) => Semantics(
        button: true,
        label: context.l10n
            .homeSwitchSource(context.featureText(source.shortDisplayName)),
        excludeSemantics: true,
        child: Material(
          color: AppSurfaces.track(context),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _showAccountSwitchSheet,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.featureText(source.shortDisplayName),
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.swap_horiz_rounded,
                      size: 13, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openFeatureByTitle(String title) {
    for (final item in _searchableCategories.expand((c) => c.items)) {
      if (item.title == title) {
        _handleFeatureTap(item);
        return;
      }
    }
  }

  Widget _buildStatusWidgets() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: HomeAutoSyncWidget(
              onTap: () => _openFeatureByTitle('自动同步'),
            ),
          ),
          const SizedBox(width: AppDesignTokens.cardGap),
          Expanded(
            child: HomeServerStatusWidget(
              onTap: () => _openFeatureByTitle('服务器状态'),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchInteractionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openHomeFeatureSearch() async {
    if (_featureSearchOpen) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final field = _featureSearchFieldKey.currentContext?.findRenderObject();
    final overlay = navigator.overlay?.context.findRenderObject();
    if (field is! RenderBox || overlay is! RenderBox) return;
    final sourceRect =
        field.localToGlobal(Offset.zero, ancestor: overlay) & field.size;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _featureSearchOpen = true);
    final route = FeatureSearchOverlay.route(
      sourceRect: sourceRect,
      initialQuery: _hubSearchQuery,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
      hintText: context.featureText(
          SearchInteractionPreferences.instance.homeSearchScope.hint),
      queryResultsBuilder: (context, query, close) =>
          _buildHomeFeatureSearchResults(context, query, _handleFeatureTap,
              closeOverlay: close),
    );
    String? query;
    try {
      query = await navigator.push(route);
      await route.completed;
    } finally {
      if (mounted) setState(() => _featureSearchOpen = false);
    }
    if (!mounted || query == null) return;
    final keyword = query.trim();
    // 收起时把关键词带回首页显示结果；只存历史的话看起来就是直接退回首页。
    setState(() => _hubSearchQuery = keyword);
    if (keyword.isEmpty) return;
    try {
      await FeatureSearchOverlay.historyStore.remember(keyword);
    } catch (error) {
      debugPrint('保存功能搜索历史失败: $error');
    }
  }

  Widget _buildRefreshProgress(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarqueeText(
            text: _refreshText,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          SmoothLinearProgressIndicator(
            value: _refreshProgress,
            minHeight: 5,
            color: scheme.primary,
          ),
        ],
      ),
    );
  }

  /// 主页搜索支持标题/副标题的连续字符匹配：输入完整词组时走普通包含，
  /// 只输入几个关键字时也能按顺序匹配到对应功能。
  bool _matchesHomeFeature(String value, String query) {
    final text = value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final keyword = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (text.contains(keyword)) return true;

    var cursor = 0;
    for (final rune in keyword.runes) {
      final index = text.indexOf(String.fromCharCode(rune), cursor);
      if (index < 0) return false;
      cursor = index + 1;
    }
    return keyword.isNotEmpty;
  }

  List<_HomeFeatureSearchEntry> _homeFeatureSearchResults(String query) {
    final results = <_HomeFeatureSearchEntry>[];
    for (final category in _searchableCategories) {
      for (final item in category.items) {
        if (_matchesHomeFeature(item.title, query) ||
            _matchesHomeFeature(item.subtitle, query) ||
            _matchesHomeFeature(context.featureText(item.title), query) ||
            _matchesHomeFeature(context.featureText(item.subtitle), query)) {
          results.add(_HomeFeatureSearchEntry(category, item));
        }
      }
    }
    return results;
  }

  Widget _buildHomeFeatureSearchResults(
      BuildContext context, String query, ValueChanged<ButtonItem> onSelected,
      {VoidCallback? closeOverlay}) {
    final scheme = Theme.of(context).colorScheme;
    final scope = SearchInteractionPreferences.instance.homeSearchScope;
    final showFeatures = scope != HomeSearchScope.song;
    final showSongs = scope != HomeSearchScope.feature;
    final results = showFeatures
        ? _homeFeatureSearchResults(query)
        : <_HomeFeatureSearchEntry>[];
    final resultBody = results.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                context.featureText('没有找到匹配的功能'),
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          )
        : Column(
            children: [
              for (final entry in results)
                Builder(
                  builder: (context) {
                    final path =
                        FeatureRegistry.pathFor(entry.category, entry.item)
                            .map(context.featureText)
                            .join(' > ');
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap:
                            _isSyncBlockedFeature(entry.item.title) && anyBusy
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    // 必须先关搜索层再跳转：搜索层是 push 在同一个
                                    // Navigator 上的透明路由，closeOverlay 内部就是
                                    // Navigator.pop，弹的永远是「栈顶」而不是搜索层。
                                    // 若先跳转后关闭，pop 会命中刚 push 的功能页——
                                    // 功能页被弹掉、搜索层却留在栈顶进入 closing 态
                                    // （IgnorePointer 且不再响应点击），表现就是点了
                                    // 结果卡死，只能手势返回才恢复到首页。
                                    closeOverlay?.call();
                                    onSelected(entry.item);
                                  },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 11),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                alignment: Alignment.center,
                                child: Icon(entry.item.icon,
                                    size: 20, color: scheme.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MarqueeText(
                                      text:
                                          context.featureText(entry.item.title),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    MarqueeText(
                                      text: context
                                          .featureText(entry.item.subtitle),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      path,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: scheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );

    return SingleChildScrollView(
      // 有歌曲结果时不按关键词换 key：歌曲要等搜索返回，输入时保留上一次的结果。
      key: showSongs ? null : ValueKey(query),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showFeatures) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
              child: Text(
                showSongs
                    ? context.l10n.homeFeatureCount(results.length)
                    : query.isEmpty
                        ? context.l10n.homeAllFeatureCount(results.length)
                        : context.l10n.homeResultCount(results.length),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            resultBody,
          ],
          if (showFeatures && showSongs) const SizedBox(height: 16),
          if (showSongs)
            _HomeSongSearchResults(
              query: query,
              onOpen: (songId) {
                // 和功能结果一样：先关搜索层再跳转。
                FocusScope.of(context).unfocus();
                closeOverlay?.call();
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                      builder: (_) => SongInfoPage(songId: songId)),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 首页 Rating 总览（2026-11 B 方案）。
  ///
  /// 白卡片 + 大号等宽数字 + Rating 段位小标识 + B35/B15 占比条。
  /// 交互与旧版一致：点上半部分（标签 + 总 Rating）打开「刷新数据（高级）」，
  /// 点右下角数据源胶囊切换 水鱼 / 落雪 / AWMC NET 账号（使用缓存，不联网）。
  Widget _buildDashboardSummary(BuildContext context, Brightness brightness) {
    final scheme = Theme.of(context).colorScheme;
    final total = _best50TotalRA;
    final tier = AppColors.ratingTier(total);
    final fraction = total > 0 ? _best35TotalRA / total : 0.7;
    final secondary = scheme.primary.withValues(alpha: 0.5);
    // 字体样式只随页面状态生成，避免动画每一帧重复查询主字体与回落字体。
    final ratingStyle = AppTheme.number(
      fontSize: 68,
      fontWeight: FontWeight.w700,
      height: 0.95,
      letterSpacing: -2,
      color: scheme.onSurface,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 大数字 → 「刷新数据（高级）」
          Semantics(
            button: true,
            label: context.l10n.homeTotalRatingAction(_displayBest50RA()),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: anyBusy ? null : _openAdvancedRefreshData,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RepaintBoundary(
                        child: Stack(
                          children: [
                            // 用最终数字占位，计数位数变化时不再牵动整行和首页布局。
                            Opacity(
                              opacity: 0,
                              child: Text(_displayBest50RA(),
                                  maxLines: 1, style: ratingStyle),
                            ),
                            Positioned.fill(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: total.toDouble()),
                                duration: AppDesignTokens.motion(context,
                                    const Duration(milliseconds: 1100)),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) => FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    total == 0 ? '-' : '${value.round()}',
                                    maxLines: 1,
                                    style: ratingStyle,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (total > 0) ...[
                          _buildRatingTierChip(tier),
                          const SizedBox(height: 4),
                        ],
                        Text('Rating',
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SplitBar(
            fraction: fraction,
            primary: scheme.primary,
            secondary: secondary,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryMetric(context, 'B35', _displayBest35RA()),
              _summaryMetric(context, 'B15', _displayBest15RA()),
            ],
          ),
        ],
      ),
    );
  }

  /// Rating 段位小标识（彩 / 白金 / 金 …），颜色对应游戏里的 Rating 框。
  Widget _buildRatingTierChip(
      ({String label, List<Color> colors, Color foreground}) tier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tier.colors),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        context.featureText(tier.label),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: tier.foreground,
        ),
      ),
    );
  }

  // 顶部头像 / 姓名框入口已迁移到 MeHubPage；选择结果仍存于 SharedPreferences，
  // 供 Best50 / 拟合等图片导出时由 ExportUserInfoWidget 读取。

  Widget _summaryMetric(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        const SizedBox(width: 4),
        Text(value,
            style: AppTheme.number(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface)),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildAllFeaturesList(BuildContext context) {
    final categories = _searchableCategories;
    return Column(
      children: [
        for (final category in categories)
          _buildCategoryCard(category, context),
      ],
    );
  }

  Widget _buildInitializationStatus(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completed = _isInitializationCompleted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: completed
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        if (!completed)
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(Icons.check_circle_outline, color: scheme.onSecondaryContainer),
        const SizedBox(width: 10),
        Expanded(
            child: Text(_initializationProgress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: completed
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                    fontSize: 12))),
      ]),
    );
  }

  // 收藏品选择 tab 按钮已迁移到独立的 CollectionPickerSheet StatefulWidget
  //（避免 showModalBottomSheet.builder 多次调用时局部变量 activeTab 被重置的 bug）

  SyncCallbacks get syncCallbacks => SyncCallbacks(
        onSaveQQ: _saveQQ,
        onRefreshAfterSync: ({
          required String qq,
          required void Function(double progress, String text) onProgress,
          required bool participateRankings,
          required bool showNickname,
        }) async {
          await refreshBest50DataWithProgress(
            qq,
            (p, t) {
              debugPrint('[HomePage] 后台刷新 $p%: $t');
              onProgress(0.70 + (p / 100) * 0.30, t);
            },
            participateRankings: participateRankings,
            showNickname: showNickname,
          );
        },
        onLoginStateChanged: () async {
          await _loadUserData();
          await _checkDivingFishLoginStatus();
        },
      );

  // 收藏区三个同步入口的编排（线路分发、按钮进度、统计上报）统一由 SyncFlowMixin
  // 提供 —— 原先这里自己写了一份，导致同一功能在「系统」hub 页与收藏区表现不同：
  // 水鱼弹模态框、落雪直接跳页且没有任何进度。
  // 现在两边调用同一份代码：syncToDivingFishByCurrentRoute /
  // syncToLuoXueByCurrentRoute / syncToAwmcNetWithButton。

  // 显示刷新数据对话框（旧版实现已抽离到 lib/widgets/RefreshDataDialog.dart，
  // 这里仅保留给其它可能的本地调用入口；首页/系统 Tab 现统一调用 showRefreshDataDialog）
  Future<void> _autoRefreshAfterSync({
    Future<void> Function(double progress, String text)? onProgress,
  }) async {
    final qq = await DivingFishProbeManager().fetchBindQQ();

    if (qq == null || qq.isEmpty) {
      debugPrint('[HomePage] _autoRefreshAfterSync: QQ 为空，跳过刷新');
      return;
    }

    debugPrint('[HomePage] _autoRefreshAfterSync: 使用 QQ=$qq 自动刷新');

    await refreshBest50DataWithProgress(
      qq,
      (p, t) async {
        debugPrint('[HomePage] 后台刷新 $p%: $t');
        await onProgress?.call(0.70 + (p / 100) * 0.30, t);
      },
      participateRankings: await _getParticipateRankings(),
      showNickname: await _getShowNickname(),
    );
    debugPrint('[HomePage] _autoRefreshAfterSync: 完成');
  }

  Future<bool> _getParticipateRankings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(CacheKeyConstant.participateRankings) ?? false;
  }

  Future<bool> _getShowNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(CacheKeyConstant.showNickname) ?? false;
  }

  // 显示同步成绩对话框，返回 friendCode 表示同步成功
  // 单曲同步成绩 / 水鱼登录两个弹窗目前无调用点，保留实现备用
  // ignore: unused_element
  Future<String?> _showSyncScoreDialog(BuildContext context) async {
    final brightness = Theme.of(context).brightness;
    final TextEditingController qrController = TextEditingController();
    final TextEditingController dfUserController = TextEditingController();
    final TextEditingController dfPassController = TextEditingController();
    bool isSyncing = false;
    bool needDivingFishToken = false;
    bool isBinding = false;
    String statusText = '';
    String? bindingError;
    double? progress;
    SyncStage? currentStage;

    // 排行榜选项（与刷新数据对话框公用 prefs 缓存）
    bool participateRankings = false;
    bool showNickname = false;

    // 从缓存读取排行榜设置
    Future<void> loadRankingSettings() async {
      final prefs = await SharedPreferences.getInstance();
      participateRankings =
          prefs.getBool(CacheKeyConstant.participateRankings) ?? false;
      showNickname = prefs.getBool(CacheKeyConstant.showNickname) ?? false;
    }

    Future<void> saveRankingSettings() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
          CacheKeyConstant.participateRankings, participateRankings);
      await prefs.setBool(CacheKeyConstant.showNickname, showNickname);
    }

    loadRankingSettings();
    RankingUploadGuard.load();
    // 后台确认水鱼账号最新的成绩掩码设置，开启时禁用「参与排行榜」
    if (CurrentDataSourceNotifier.instance.value == RefreshDataSource.shuiyu) {
      DivingFishMaskStatus.instance.refresh();
    }

    final String? result = await showDialog<String?>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        Timer? _autoCloseTimer;
        int _countdown = 3;
        String _currentTip = LoadingTipsConstant.getRandomLoadingTip();
        StreamSubscription<String>? _tipSub;
        return StatefulBuilder(
          builder: (context, setState) {
            // 完成态：点击空白可关闭 + 3 秒倒计时自动关闭
            final isDone = currentStage == SyncStage.completed ||
                currentStage == SyncStage.failed ||
                currentStage == SyncStage.cancelled;

            if (isDone && _autoCloseTimer == null) {
              void tick() {
                _countdown--;
                if (_countdown > 0) {
                  setState(() {}); // 刷新按钮文字
                  _autoCloseTimer = Timer(const Duration(seconds: 1), tick);
                } else {
                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              }

              _autoCloseTimer = Timer(const Duration(seconds: 1), tick);
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
                        // 多方式导入按钮（剪贴板 / 相册 / 扫码，公共组件）
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
                        // 水鱼账号开了成绩掩码时不能参与排行榜（掩码成绩不准确）
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            DivingFishMaskStatus.instance,
                            RankingUploadGuard.states,
                          ]),
                          builder: (_, __) {
                            final source =
                                CurrentDataSourceNotifier.instance.value;
                            final maskBlocked =
                                DivingFishMaskStatus.instance.value &&
                                    source == RefreshDataSource.shuiyu;
                            // 排行榜守卫：该数据源账号被冻结或拉黑
                            final guardState =
                                RankingUploadGuard.states.value[source.key] ??
                                    RankingGuardState.normal;
                            final blocked = maskBlocked ||
                                guardState != RankingGuardState.normal;
                            final reason = switch (guardState) {
                              RankingGuardState.blacklisted =>
                                dialogContext.l10n.rankingGuardBlacklisted,
                              RankingGuardState.frozen =>
                                dialogContext.l10n.rankingGuardFrozen,
                              RankingGuardState.normal => dialogContext
                                  .l10n.flowRankingDivingFishMasked,
                            };
                            if (blocked && participateRankings) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!participateRankings) return;
                                setState(() {
                                  participateRankings = false;
                                  showNickname = false;
                                });
                                saveRankingSettings();
                              });
                            }
                            return CheckboxListTile(
                              title: Text(
                                  dialogContext.l10n.flowJoinLeaderboards,
                                  style: TextStyle(fontSize: 14)),
                              subtitle: blocked
                                  ? Text(
                                      reason,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(dialogContext)
                                              .colorScheme
                                              .error))
                                  : null,
                              value: participateRankings && !blocked,
                              onChanged: blocked
                                  ? null
                                  : (value) {
                                      setState(() {
                                        participateRankings = value ?? false;
                                        if (!participateRankings)
                                          showNickname = false;
                                      });
                                      saveRankingSettings();
                                    },
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            );
                          },
                        ),
                        if (participateRankings)
                          CheckboxListTile(
                            title: Text(
                                dialogContext.l10n
                                    .flowShowNicknameOtherwiseShownAsAnonymous,
                                style: TextStyle(fontSize: 13)),
                            value: showNickname,
                            onChanged: (value) {
                              setState(() => showNickname = value ?? false);
                              saveRankingSettings();
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                      ],

                      // ===== 阶段 2：绑定水鱼账号 =====
                      if (needDivingFishToken) ...[
                        Text(
                          dialogContext
                              .l10n.flowScoresFetchedLinkYourDivingFishAccount,
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
                            hintText:
                                dialogContext.l10n.flowEnterDivingFishUsername,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ).insetLabel(context),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: dfPassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText:
                                dialogContext.l10n.flowDivingFishPassword,
                            hintText:
                                dialogContext.l10n.flowEnterDivingFishPassword,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ).insetLabel(context),
                        ),
                        if (bindingError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            bindingError!,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.errorRed(brightness)),
                          ),
                        ],
                      ],

                      // ===== 同步进度 =====
                      if (isSyncing && !needDivingFishToken) ...[
                        // 同步中：随机 Tips + 警告
                        if (currentStage != SyncStage.completed &&
                            currentStage != SyncStage.failed &&
                            currentStage != SyncStage.cancelled) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.warningOrange(brightness)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusSmall),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 16,
                                    color: AppColors.warningOrange(brightness)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dialogContext.l10n
                                        .flowSyncInProgressPleaseWaitAndAvoid,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.warningOrange(
                                            brightness)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.5),
                              ),
                            ),
                          ),
                        ],

                        // 完成/失败/取消：阶段图标
                        if (currentStage == SyncStage.completed ||
                            currentStage == SyncStage.failed ||
                            currentStage == SyncStage.cancelled) ...[
                          const SizedBox(height: 8),
                          Center(
                              child: _buildStageIcon(currentStage, brightness)),
                          const SizedBox(height: 8),
                        ],
                        Center(
                          child: Text(
                            statusText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: currentStage == SyncStage.failed ||
                                      currentStage == SyncStage.cancelled
                                  ? AppColors.errorRed(brightness)
                                  : currentStage == SyncStage.completed
                                      ? AppColors.successGreen(brightness)
                                      : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (currentStage != SyncStage.completed &&
                            currentStage != SyncStage.failed &&
                            currentStage != SyncStage.cancelled) ...[
                          const SizedBox(height: 10),
                          if (progress != null)
                            SmoothLinearProgressIndicator(
                                value: progress,
                                color: AppColors.linkBlue(brightness))
                          else
                            SmoothLinearProgressIndicator(
                                color: AppColors.linkBlue(brightness)),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _currentTip,
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
                  // ---- 初始/失败/完成：关闭按钮 ----
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
                        _autoCloseTimer?.cancel();
                        final fc = currentStage == SyncStage.completed
                            ? DivingFishProbeManager().currentFriendCode
                            : null;
                        Navigator.of(dialogContext).pop(fc);
                      },
                      child: Text(
                        _countdown > 0
                            ? dialogContext.l10n
                                .flowOKP0((_countdown).toString())
                            : dialogContext.l10n.featureOK,
                      ),
                    ),

                  // ---- 绑定水鱼账号页面：关闭 & 绑定 ----
                  if (needDivingFishToken) ...[
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
                        backgroundColor: AppColors.linkBlue(brightness),
                        foregroundColor: Colors.white,
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
                                bindingError = null;
                              });

                              final ok = await DivingFishProbeManager()
                                  .bindDivingFishAccount(username, password);

                              if (!ok) {
                                setState(() {
                                  isBinding = false;
                                  bindingError = dialogContext
                                      .l10n.flowCouldNotLinkDivingFishTryAgain;
                                });
                                return;
                              }

                              // 绑定成功 → 同步缓存水鱼 JWT（用于后续 fetchBindQQ）
                              _log('maimai Score Hub 绑定成功，同步直登水鱼以缓存 JWT...');
                              final manager = DivingFishProbeManager();
                              final loginResult = await manager
                                  .loginDivingFishDirect(username, password);
                              if (loginResult == null) {
                                setState(() {
                                  isBinding = false;
                                  bindingError = manager
                                          .lastLoginFailure?.message ??
                                      dialogContext.l10n
                                          .flowDivingFishSignInFailedTryAgain;
                                });
                                return;
                              }

                              // 重试导出
                              _log('重试导出到水鱼...');
                              final exportData = await DivingFishProbeManager()
                                  .exportToDivingFish();

                              if (exportData != null &&
                                  (exportData.tryGet<int>('status') ?? 0) ==
                                      200) {
                                final count =
                                    exportData.tryGet<int>('exported') ?? 0;
                                if (context.mounted)
                                  ConfettiEffect.show(context);

                                // 自动刷新本地数据
                                setState(() {
                                  statusText = dialogContext.l10n
                                      .flowSyncSucceededRefreshingLocalData;
                                });
                                String? qq = await DivingFishProbeManager()
                                    .fetchBindQQ();
                                if (qq == null) {
                                  qq = await DivingFishProbeManager()
                                      .fetchBindQQ();
                                }
                                if (qq != null && qq.isNotEmpty) {
                                  await _saveQQ(qq);
                                }
                                await _autoRefreshAfterSync(
                                  onProgress: (p, t) async {
                                    setState(() {
                                      progress = p;
                                      statusText = t;
                                    });
                                    await Future.delayed(
                                        const Duration(milliseconds: 80));
                                  },
                                );

                                AppToast.show(dialogContext.l10n
                                    .flowDoneP0ScoresSyncedAndLocalData(
                                        (count).toString()));
                                final fc =
                                    DivingFishProbeManager().currentFriendCode;
                                Navigator.of(dialogContext).pop(fc);
                              } else {
                                setState(() {
                                  isBinding = false;
                                  bindingError = dialogContext
                                      .l10n.flowExportFailedTryAgain;
                                });
                              }
                            },
                    ),
                  ],

                  // ---- 初始：开始同步按钮 ----
                  if (!isSyncing && !needDivingFishToken)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(dialogContext.l10n.flowStartSync),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.linkBlue(brightness),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final qrCode = qrController.text.trim();
                        if (qrCode.isEmpty) {
                          AppToast.show(
                              dialogContext
                                  .l10n.flowPasteTheMaimaiCHUNITHMLoginQRString,
                              tone: AppToastTone.warning);
                          return;
                        }

                        setState(() {
                          isSyncing = true;
                          statusText = dialogContext.l10n.flowPreparingSync;
                          currentStage = SyncStage.authenticating;
                        });

                        LoadingTipsConstant.startAutoSwitch(3);
                        _tipSub?.cancel();
                        _tipSub = LoadingTipsConstant.tipStream.listen((tip) {
                          setState(() => _currentTip = tip);
                        });

                        // 验证二维码格式：必须为 SGWCMAID 开头
                        if (!qrCode.startsWith('SGWCMAID')) {
                          setState(() {
                            currentStage = SyncStage.failed;
                            statusText =
                                dialogContext.l10n.flowInvalidQRCodeUseALoginQR;
                            isSyncing = false;
                          });
                          LoadingTipsConstant.stopAutoSwitch();
                          _tipSub?.cancel();
                          return;
                        }

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
                        _tipSub?.cancel();

                        if (result.isSuccess) {
                          if (context.mounted) ConfettiEffect.show(context);
                          // ===== 同步成功 → 先展示过渡态 =====
                          setState(() {
                            currentStage = SyncStage.exporting;
                            statusText = dialogContext
                                .l10n.flowSyncSucceededRefreshingLocalData;
                            progress = 0.70;
                          });
                          // 让 UI 先渲染出 70% 和过渡文字
                          await Future.delayed(
                              const Duration(milliseconds: 300));

                          // 确保 QQ 已保存
                          String? qq =
                              await DivingFishProbeManager().fetchBindQQ();
                          if (qq == null) {
                            qq = await DivingFishProbeManager().fetchBindQQ();
                          }
                          final hasQQ = qq != null && qq.isNotEmpty;
                          if (hasQQ) {
                            await _saveQQ(qq);
                          }

                          if (hasQQ) {
                            await _autoRefreshAfterSync(
                              onProgress: (p, t) async {
                                setState(() {
                                  progress = p;
                                  statusText = t;
                                });
                                await Future.delayed(
                                    const Duration(milliseconds: 80));
                              },
                            );
                          } else {
                            // 没有 QQ，假装走一段进度让用户看到
                            for (int i = 0; i < 4; i++) {
                              setState(() => progress = 0.70 + (i + 1) * 0.05);
                              await Future.delayed(
                                  const Duration(milliseconds: 200));
                            }
                          }

                          setState(() {
                            currentStage = SyncStage.completed;
                            progress = 1.0;
                            if (hasQQ) {
                              statusText = dialogContext.l10n
                                  .flowDoneP0ScoresSyncedAndLocalData(
                                      (result.exportedCount).toString());
                            } else {
                              statusText = dialogContext.l10n
                                  .flowP0ScoresSentToDivingFishSign(
                                      (result.exportedCount).toString());
                            }
                          });
                        } else if (result.errorMessage == '用户取消同步') {
                          setState(() {
                            currentStage = SyncStage.cancelled;
                            statusText = dialogContext.l10n.flowSyncCancelled;
                          });
                        } else {
                          final msg = result.errorMessage ?? '';
                          if (msg.contains('divingFishImportToken') ||
                              msg.contains('missing')) {
                            needDivingFishToken = true;
                            isSyncing = false;
                            _log('检测到缺少水鱼 importToken，切换到绑定界面');
                          } else {
                            setState(() {
                              currentStage = SyncStage.failed;
                              statusText = msg;
                            });
                          }
                        }
                      },
                    ),
                ],
              ),
            ); // PopScope closing
          },
        );
      },
    );
    return result;
  }

  // 将同步阶段映射为 0~1 的进度值（总范围 0~0.70，刷新占 0.70~1.0）
  double _stageProgress(SyncProgress p) {
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
        // 抓取阶段：25%~65%，由实际 diffs 进度填充
        return 0.25 + (p.progress ?? 0) * 0.40;
      case SyncStage.exporting:
        return 0.68;
      default:
        return 0.0;
    }
  }

  // 调试日志（HomePage 内用，避免和 DivingFishProbeManager 混淆）
  void _log(String msg) {
    debugPrint('[HomePage-Sync] $msg');
  }

  // 显示水鱼登录对话框
  // ignore: unused_element
  void _showDivingFishLoginDialog(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final TextEditingController userController = TextEditingController();
    final TextEditingController passController = TextEditingController();
    bool isLoggingIn = false;
    bool loginSuccess = false;
    String? importedToken;
    String statusText = '';
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                            horizontal: 12,
                            vertical: 10,
                          ),
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
                      Text(
                        dialogContext.l10n.flowImportTokenRetrievedAndSaved,
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.greyHint(brightness)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Token: ${importedToken ?? "***"}',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.greyHint(brightness, shade: 600)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dialogContext.l10n.flowYouCanNowSyncScoresToDiving,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.greyHint(brightness)),
                      ),
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login, size: 18),
                    label: Text(isLoggingIn
                        ? dialogContext.l10n.flowSigningIn
                        : dialogContext.l10n.flowSignIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.linkBlue(brightness),
                      foregroundColor: Colors.white,
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
                              // 登录成功后立即更新缓存的QQ号，确保排行榜等页面使用新账号标识
                              await _saveQQ(bindQQ);
                              _checkDivingFishLoginStatus();
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
  }

  // 与「系统设置」页面使用同一组控件和缓存。
  void _showThemeDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(context.featureText('主题设置')),
        content: const SingleChildScrollView(child: ThemePreferenceControls()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
            child: Text(context.featureText('更多设置')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.featureText('完成')),
          ),
        ],
      ),
    );
  }

  // 显示成绩导入凭据对话框
  /// 打开「切换账号」底部面板；目标无缓存时引导去刷新对应数据源。
  Future<void> _showAccountSwitchSheet() async {
    if (anyBusy) return;
    await showAccountSwitchSheet(
      context,
      onNeedRefresh: (source) => _openRefreshData(initialSource: source),
    );
  }

  /// 首页普通刷新与高级刷新共用摘要下方的进度条。
  Future<void> _openRefreshData({RefreshDataSource? initialSource}) async {
    if (anyBusy) return;
    final request = await showRefreshDataDialog(
      context,
      initialSource: initialSource,
    );
    if (request == null || !mounted) return;
    await _runHomeRefresh(request, advanced: false);
  }

  /// 高级模式刷新数据：和「系统」Tab 的入口同源，只是这里把入口挂在
  /// PLAYER OVERVIEW 卡片的上半部分（标题 + 总分）上。
  ///
  /// 高级对话框返回的 [RefreshDataRequest.forceSourceIds] 非空，
  /// 交给 executeAdvancedRefreshData 按缓存源强制刷新；进度条显示在
  /// PLAYER OVERVIEW 下方，避免刷新过程中反复弹出底部提示。
  bool _isRefreshing = false;
  String _refreshText = '';
  double _refreshProgress = 0;

  Future<void> _openAdvancedRefreshData(
      {RefreshDataSource? initialSource}) async {
    if (anyBusy) return;
    final request = await showAdvancedRefreshDataDialog(
      context,
      initialSource: initialSource,
    );
    if (request == null || !mounted) return;
    await _runHomeRefresh(request, advanced: true);
  }

  Future<void> _runHomeRefresh(RefreshDataRequest request,
      {required bool advanced}) async {
    if (anyBusy) return;
    setState(() {
      _isRefreshing = true;
      _refreshText = advanced
          ? context.l10n.flowAdvancedDataRefreshInProgress
          : context.l10n.flowRefreshingData;
      _refreshProgress = 0;
    });
    HomeRefreshNotifier.setBusy(true);
    try {
      void updateProgress(int p, String t) {
        if (!mounted) return;
        setState(() {
          _refreshText = '$t ($p%)';
          _refreshProgress = (p / 100).clamp(0.0, 1.0);
        });
      }

      if (advanced) {
        await executeAdvancedRefreshData(request, onProgress: updateProgress);
      } else {
        await executeRefreshData(request, onProgress: updateProgress);
      }
      if (mounted) {
        ConfettiEffect.show(context);
        AppToast.show(context.l10n.flowDataRefreshed,
            tone: AppToastTone.success);
      }
    } catch (e) {
      if (mounted) await presentRefreshError(context, e, qq: request.qq);
    } finally {
      HomeRefreshNotifier.setBusy(false);
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _refreshText = '';
          _refreshProgress = 0;
        });
      }
    }
  }

  void _showAccountManageDialog(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: fetchDivingFishProfile(),
          builder: (ctx, snapshot) {
            final isLoading = snapshot.connectionState != ConnectionState.done;
            final errorMsg = snapshot.hasError ? '${snapshot.error}' : null;
            final profile = snapshot.data;

            return AppAlertDialog(
              title: Row(
                children: [
                  Icon(Icons.manage_accounts, size: 22),
                  SizedBox(width: 8),
                  Text(dialogContext.l10n.featureAccountManagement),
                ],
              ),
              content: SingleChildScrollView(
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : errorMsg != null
                        ? Text(errorMsg,
                            style: TextStyle(
                                color: AppColors.errorRed(brightness)))
                        : Column(mainAxisSize: MainAxisSize.min, children: [
                            // 已登录水鱼：只显示成绩导入 Token
                            if (profile != null) ...[
                              // 标题样式与下方落雪、AWMC NET 两节一致：
                              // 已有 Token 显示绿色勾，否则灰色钥匙。
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Builder(builder: (_) {
                                      final hasToken = (profile.tryGet<String>(
                                                  'import_token') ??
                                              '')
                                          .isNotEmpty;
                                      return Icon(
                                        hasToken
                                            ? Icons.check_circle
                                            : Icons.vpn_key,
                                        size: 18,
                                        color: hasToken
                                            ? AppColors.successGreen(brightness)
                                            : AppColors.greyHint(brightness),
                                      );
                                    }),
                                    const SizedBox(width: 8),
                                    Text(
                                      dialogContext.l10n.flowDivingFishProfile,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(dialogContext)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 水鱼账号资料与授权已移到「绑定与授权管理 → 水鱼授权」。
                              _buildAccountInfo(profile, dialogContext),
                            ] else
                              // 未登录水鱼：友好提示用户去登录水鱼（落雪 token 仍可操作）
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  dialogContext
                                      .l10n.flowNotSignedInToDivingFishOnly,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.greyHint(brightness),
                                  ),
                                ),
                              ),
                            // 始终显示：落雪 API 密钥管理（不依赖水鱼登录）
                            _buildLxnsTokenSection(brightness),
                            // AWMC NET 成绩导入 Token 同样独立于水鱼登录
                            _buildAwmcNetTokenSection(brightness),
                          ]),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(dialogContext.l10n.featureClose),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 本地检查落雪 importToken 是否已缓存
  Future<bool> _checkLxnsTokenLocal() async {
    final local =
        await SecureCredentialStore.read(CacheKeyConstant.probeLxnsImportToken);
    return local != null && local.isNotEmpty;
  }

  /// 管理落雪 API 密钥（maimai Score Hub 侧）
  Widget _buildLxnsTokenSection(Brightness brightness) {
    final tokenCtrl = TextEditingController();
    bool? hasToken;
    bool saving = false;
    bool checking = true;

    return StatefulBuilder(
      builder: (ctx, setState) {
        // 初次检查：优先本地缓存，其次查询 maimai Score Hub
        if (checking) {
          _checkLxnsTokenLocal().then((localHas) {
            if (localHas) {
              if (checking)
                setState(() {
                  hasToken = true;
                  checking = false;
                });
            } else {
              DivingFishProbeManager().hasLxnsImportToken().then((has) {
                if (checking)
                  setState(() {
                    hasToken = has;
                    checking = false;
                  });
              });
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  hasToken == true ? Icons.check_circle : Icons.vpn_key,
                  size: 18,
                  color: hasToken == true
                      ? AppColors.successGreen(brightness)
                      : AppColors.greyHint(brightness),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.flowLXNSPersonalAPIKey,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(ctx).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (checking)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              if (hasToken == true)
                Text(context.l10n.flowSet,
                    style: TextStyle(
                        color: AppColors.successGreen(brightness),
                        fontSize: 13))
              else ...[
                Text(context.l10n.flowNotSet,
                    style: TextStyle(
                        color: AppColors.warningOrange(brightness),
                        fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(
                        'https://maimai.lxns.net/user/profile?tab=thirdparty');
                    try {
                      if (await ExternalLaunchUtil.open(uri)) {
                        return;
                      } else {
                        launchUrlFallback(uri.toString(), context);
                      }
                    } catch (e) {
                      debugPrint('打开落雪第三方绑定链接失败: $e');
                      launchUrlFallback(uri.toString(), context);
                    }
                  },
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                            text: context.l10n.flowVisit2,
                            style: TextStyle(fontSize: 12)),
                        TextSpan(
                          text:
                              'https://maimai.lxns.net/user/profile?tab=thirdparty',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: TextDecoration.underline),
                        ),
                        TextSpan(
                            text: context.l10n.flowAndScrollToTheBottomToGet,
                            style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tokenCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText:
                              context.l10n.flowPasteYourLXNSPersonalAPIKey,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final t = tokenCtrl.text.trim();
                              if (t.isEmpty) {
                                AppToast.show(
                                    context.l10n.flowEnterYourAPIKeyFirst,
                                    tone: AppToastTone.warning);
                                return;
                              }
                              setState(() => saving = true);
                              try {
                                final message = await AutoSyncService.instance
                                    .savePersonalCredential(
                                        SyncPlatform.luoXue, t);
                                // maimai Score Hub 仍沿用已有绑定流程。
                                await DivingFishProbeManager()
                                    .setLxnsImportToken(t);
                                if (!ctx.mounted) return;
                                hasToken = true;
                                tokenCtrl.clear();
                                setState(() {});
                                AppToast.show(message);
                              } catch (_) {
                                if (ctx.mounted)
                                  AppToast.show(
                                      context.l10n
                                          .flowCouldNotSaveYourPersonalKeyTry,
                                      tone: AppToastTone.error);
                              } finally {
                                if (ctx.mounted) setState(() => saving = false);
                              }
                            },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(context.l10n.save,
                              style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
              if (hasToken == true) ...[
                // 紧贴「已设置」一行：TextButton 默认有 48dp 的 tap 尺寸和内部
                // 上下留白，不加这个紧凑样式时看起来离上面那行很远。
                const SizedBox(height: 2),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setState(() => saving = true);
                          try {
                            final message = await AutoSyncService.instance
                                .clearPersonalCredential(SyncPlatform.luoXue);
                            await DivingFishProbeManager()
                                .setLxnsImportToken(null);
                            if (!ctx.mounted) return;
                            hasToken = false;
                            AppToast.show(message);
                          } catch (_) {
                            if (ctx.mounted)
                              AppToast.show(
                                  context
                                      .l10n.flowCouldNotDisableAutoSyncYourKey,
                                  tone: AppToastTone.error);
                          } finally {
                            if (ctx.mounted) setState(() => saving = false);
                          }
                        },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(context.l10n.flowClearKey,
                      style: TextStyle(
                          color: AppColors.errorRed(brightness), fontSize: 12)),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  /// 管理 AWMC NET 成绩导入 Token。
  Widget _buildAwmcNetTokenSection(Brightness brightness) {
    return _AwmcNetTokenSection(brightness: brightness);
  }

  Widget _buildAccountInfo(Map<String, dynamic> p, BuildContext dialogContext) {
    final brightness = Theme.of(dialogContext).brightness;
    var importToken =
        p.tryGet<String>('import_token') ?? dialogContext.l10n.flowNone2;

    // 需要跨 setState 保持状态，声明在 StatefulBuilder 外部
    bool isRefreshing = false;

    return StatefulBuilder(
      builder: (ctx, setState) {
        final rows = <Widget>[
          // ImportToken 行带操作按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              // 按钮比文字高，居中才在同一行上
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 90,
                  child: Text('ImportToken',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                          color: AppColors.greyHint(brightness), fontSize: 13)),
                ),
                Expanded(
                  child: Text(
                    importToken,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                if (isRefreshing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 24),
                    tooltip: dialogContext.l10n.flowRefreshImportToken,
                    onPressed: () async {
                      setState(() => isRefreshing = true);
                      final newToken = await _refreshImportToken();
                      if (!ctx.mounted) return;
                      if (newToken != null) {
                        importToken = newToken.token;
                        AppToast.show(newToken.message);
                      } else {
                        await showErrorMessageDialog(
                          context,
                          message: dialogContext
                              .l10n.flowCouldNotRefreshImportTokenTryAgain,
                        );
                      }
                      if (!ctx.mounted) return;
                      setState(() => isRefreshing = false);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 28, minHeight: 24),
                    tooltip: dialogContext.l10n.flowCopyImportToken,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: importToken));
                      AppToast.show(dialogContext.l10n.flowImportTokenCopied);
                    },
                  ),
                ],
              ],
            ),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }

  Future<({String token, String message})?> _refreshImportToken() async {
    final jwt =
        await SecureCredentialStore.read(CacheKeyConstant.probeDivingFishToken);
    if (jwt == null || jwt.isEmpty) return null;

    try {
      final response = await ApiClient.put(
        Uri.parse(ApiUrls.DivingFishImportTokenApi),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'jwt_token=$jwt',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final newToken = data.tryGet<String>('token') ?? '';
        if (newToken.isNotEmpty) {
          final message = await AutoSyncService.instance
              .savePersonalCredential(SyncPlatform.divingFish, newToken);
          return (token: newToken, message: message);
        }
      }
    } catch (e) {
      debugPrint('刷新水鱼个人 key 失败（错误详情已隐藏）');
    }
    return null;
  }

  // 构建同步状态图标
  Widget _buildStageIcon(SyncStage? stage, Brightness brightness) {
    if (stage == null) return const SizedBox.shrink();
    switch (stage) {
      case SyncStage.completed:
        return Icon(Icons.check_circle,
            color: AppColors.successGreen(brightness), size: 36);
      case SyncStage.failed:
        return Icon(Icons.error,
            color: AppColors.errorRed(brightness), size: 36);
      case SyncStage.cancelled:
        return Icon(Icons.cancel,
            color: AppColors.greyHint(brightness), size: 36);
      case SyncStage.waitingAcceptance:
        return Icon(Icons.hourglass_bottom,
            color: AppColors.warningOrange(brightness), size: 36);
      default:
        return const SizedBox.shrink();
    }
  }

  // 功能按钮点击分发（提取为独立方法，作为回调传给 FeatureCategoryPage）
  Future<void> _handleFeatureTap(ButtonItem item) async {
    FocusManager.instance.primaryFocus?.unfocus();
    debugPrint("点击了：${item.title}");
    if (item.title == '账号注册引导') {
      await showAccountRegistrationGuide(context);
      return;
    }
    if (const {
      '绑定与授权管理',
      '登录 maimai Score Hub',
      '切换账号',
      '落雪账号授权',
      '绑定 AWMC NET 账号',
      '绑定机台身份',
      '自动同步',
      '打印日志',
      '缓存管理',
      '拉取成绩并更新数据（高级）',
      '刷新机台游玩次数',
    }.contains(item.title)) {
      await widget.onSystemFeatureTap?.call(item);
      return;
    }
    final extraPage = switch (item.title) {
      '自定义标签' => const CustomTagsPage(),
      '自定义 Best50' => const CustomBest50Page(),
      '理想 Best50' => const IdealBest50Page(),
      '曲绘快闪猜歌' => const GuessChartByFlashCoverPage(),
      '曲绘拼图猜歌' => const GuessChartByTileRevealPage(),
      '像素曲绘猜歌' => const GuessChartByBlurredCoverPage(pixelated: true),
      '谱面片段猜歌' => const GuessChartByChartPeekPage(),
      '吃分推荐' => const GainRecommendPage(),
      _ => null,
    };
    if (extraPage != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => extraPage));
      return;
    }
    // 版本对照按钮点击事件
    if (item.title == '版本对照') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VersionView()),
      );
    }
    if (item.title == '达成率计算') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AchievementRateCalculator()),
      );
    }
    if (item.title == '达成率反推') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AchievementFullReverseCalculator()),
      );
    }
    if (item.title == 'Best50') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => B50Page()),
      );
    }
    if (item.title == '单曲 Rating 计算') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SingleRatingCalculator()),
      );
    }
    if (item.title == '基于标签推荐') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RecommendByTags()),
      );
    }
    if (item.title == '基于目标 Rating 推荐') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RatingRecommendPage()),
      );
    }
    if (item.title == '基于定数区间推荐') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DsRangeRecommendPage()),
      );
    }
    if (item.title == '乐曲查询' || item.title == '非国服乐曲查询') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SongSearchPage(extraOnly: item.title == '非国服乐曲查询')),
      );
    }
    if (item.title == '国服更新对照') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UnionUpdateComparePage()),
      );
    }
    if (item.title == '更新日历') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UpdateCalendarPage()),
      );
    }
    if (item.title == '拉取成绩并更新数据') {
      await _openRefreshData();
    }
    if (item.title == '刷新 maidata') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppAlertDialog(
          title: Text(context.l10n.flowConfirmRefresh),
          content:
              Text(context.l10n.flowThisClearsAllMaidataCachesAndDownloads),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.l10n.featureCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(context.l10n.flowConfirmRefresh),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        // 显示加载对话框
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AppAlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(context.l10n.flowRefreshingMaidata),
                ],
              ),
            ),
          );
        }
        try {
          // 清除所有maidata缓存
          await MaidataManager().clearCache();
          await MaimaiMusicDataManager().clearAddedSongsCache();
          final prefs = await SharedPreferences.getInstance();
          final keys = prefs.getKeys();
          for (final key in keys) {
            if (key.startsWith(CacheKeyConstant.maidataCachePrefix)) {
              await prefs.remove(key);
            }
          }
          // 重新拉取全量maidata
          await MaimaiMusicDataManager().refreshDataWithSmartMaidata(
            forceMaidataRefresh: true,
          );
          // 关闭加载对话框
          if (mounted) Navigator.of(context).pop();
          if (mounted) {
            AppToast.show(context.l10n.flowMaidataRefreshed,
                tone: AppToastTone.success);
            ConfettiEffect.show(context);
          }
        } catch (e) {
          debugPrint('[HomePage] 刷新maidata失败: $e');
          if (mounted) Navigator.of(context).pop();
          if (mounted) {
            await showErrorMessageDialog(context,
                message: context.l10n.flowRefreshFailedP0((e).toString()));
          }
        }
      }
    }
    if (item.title == '成绩查询') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserScoreSearchPage()),
      );
    }
    if (item.title == '成绩提升历史') {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const ScoreImprovementHistoryPage()));
      return;
    }
    if (item.title == '拟合 Best50') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DiffBest50Page()),
      );
    }
    if (item.title == '出勤转盘') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AttendanceWheelPage()));
      return;
    }
    if (item.title == '随机乐曲') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RandomChartPage()),
      );
    }
    if (item.title == '无提示猜歌') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuessChartByInfoPage()),
      );
    }
    if (item.title == '根据部分曲绘猜歌') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuessChartByCoverPage()),
      );
    }
    if (item.title == '收藏品查询') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CollectionSearchPage()),
      );
    }
    if (item.title == '根据模糊曲绘猜歌') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuessChartByBlurredCoverPage()),
      );
    }
    if (item.title == '单人猜歌游戏设置') {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const GuessGameSettingsPage()));
      return;
    }
    if (item.title == '倒放音频猜歌' || item.title == '变速变调猜歌') {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GuessChartBySongExcerptPage(
                  mode: item.title == '倒放音频猜歌'
                      ? GuessAudioMode.reverseAudio
                      : GuessAudioMode.pitchAudio)));
      return;
    }
    if (item.title == '根据歌曲片段猜歌') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuessChartBySongExcerptPage()),
      );
    }
    if (item.title == '根据别名猜歌') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuessChartByAliaPage()),
      );
    }
    if (item.title == '舞萌开字母') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GuessSongByOpenLettersPage()),
      );
    }
    if (item.title == '多人猜歌游戏') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MultiplayerLobbyPage()),
      );
    }
    if (item.title == '服务器状态') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MaimaiServerStatusPage()),
      );
    }
    if (item.title == '个性化 Best50') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PersonalizedBest50Page()),
      );
    }
    if (item.title == 'Rating 历史') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RatingHistoryPage()),
      );
    }
    if (item.title == '个性化拟合 Best50') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PersonalizedDiffBest50Page()),
      );
    }
    if (item.title == 'KALEIDXSCOPE') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => KaleidXScopeSelectPage()),
      );
    }
    if (item.title == '曲绘识别') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CoverRecognitionPage()),
      );
    }
    if (item.title == '结算画面识别') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScoreOcrPage()),
      );
    }
    if (item.title == '牌子进度') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaiziProgressPage()),
      );
    }
    if (item.title == '个性化成绩查询') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PersonalizedScorePage()),
      );
    }
    if (item.title == '随身听') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PortablePlayerPage()),
      );
    }
    if (item.title == '下次想玩') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NextPlayQueuePage()),
      );
    }
    if (item.title == '加载语录管理') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoadingTipsPage()),
      );
    }
    if (item.title == '自定义谱面播放') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PersonalizedChartPlayConfigure()),
      );
    }
    if (item.title == '关于 APP') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AboutAppPage()),
      );
    }
    if (item.title == '支持开发者') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SupportDeveloperPage()),
      );
    }
    if (item.title == '问卷调查' || item.title == '问题反馈') {
      final uri = Uri.parse(
          item.title == '问题反馈' ? AppLinks.feedbackUrl : AppLinks.surveyUrl);
      try {
        if (await ExternalLaunchUtil.open(uri)) {
          return;
        }
      } catch (e) {
        debugPrint('打开${item.title}链接失败: $e');
      }
      if (!mounted) return;
      launchUrlFallback(uri.toString(), context);
      return;
    }
    if (item.title == '访问官方网站') {
      final uri = Uri.parse(AppLinks.officialSite);
      try {
        if (await ExternalLaunchUtil.open(uri)) {
          return;
        } else {
          launchUrlFallback(
            uri.toString(),
            context,
            message: context.l10n.flowCouldNotOpenABrowserWebsiteLink(
                (AppLinks.officialSite).toString()),
          );
        }
      } catch (e) {
        debugPrint('打开官网失败: $e');
        launchUrlFallback(
          uri.toString(),
          context,
          message: context.l10n.flowCouldNotOpenABrowserWebsiteLink(
              (AppLinks.officialSite).toString()),
        );
      }
    }
    if (item.title == '加入 QQ 群') {
      final uri = Uri.parse(AppLinks.qqGroupJoinUrl);
      // 跳不动时复制的是**群号**：加群链接在浏览器里只是个空壳中转页
      final failMessage = context.l10n
          .flowCouldNotOpenQQGroupIDP0((AppLinks.qqGroupNumber).toString());
      try {
        if (await ExternalLaunchUtil.open(uri)) {
          return;
        } else {
          launchUrlFallback(
            uri.toString(),
            context,
            copyText: AppLinks.qqGroupNumber,
            message: failMessage,
          );
        }
      } catch (e) {
        debugPrint('跳转 QQ 群失败: $e');
        launchUrlFallback(
          uri.toString(),
          context,
          copyText: AppLinks.qqGroupNumber,
          message: failMessage,
        );
      }
    }
    if (item.title == '同步成绩到水鱼') {
      // 与「系统」hub 页同一份实现（SyncFlowMixin）：线路1 走 AWMC 网关，
      // 线路2 走对话框输入 + 按钮上进度
      await syncToDivingFishByCurrentRoute();
    }
    if (item.title == '成绩导入凭据') {
      _showAccountManageDialog(context);
    }
    if (item.title == '登录水鱼') {
      await SyncScoreDialogs.showDivingFishLoginDialog(context, syncCallbacks);
    }
    if (item.title == '登出水鱼账号') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppAlertDialog(
          title: Text(context.l10n.flowConfirmSignOut),
          content: Text(context.l10n.flowSigningOutClearsSavedLoginDetailsAnd),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.l10n.featureCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.errorRed(Theme.of(context).brightness)),
              child: Text(context.l10n.flowSignOut,
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (ok == true) {
        await _logoutDivingFish();
      }
    }
    if (item.title == '段位表') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RankListPage()),
      );
    }
    if (item.title == 'Rating 排行榜') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RatingRankListPage()),
      );
    }
    if (item.title == '拟合总Rating排行榜') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FittedRatingRankingListPage(),
        ),
      );
    }
    if (item.title == '特殊排行榜') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SpecialRankingListPage()),
      );
    }
    if (item.title == '平均达成率排行榜') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AvgScoreRankingListPage(
              initialMetric: AvgMetric.achievement),
        ),
      );
    }
    if (item.title == '平均DX分数达成率排行榜') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const AvgScoreRankingListPage(initialMetric: AvgMetric.dx),
        ),
      );
    }
    if (item.title == '检查更新') {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AppAlertDialog(
            title: Text(context.featureText('检查更新')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(context.featureText('正在检查更新...')),
              ],
            ),
          );
        },
      );

      // 检查更新
      final updateManager = LZYCheckUpdateManager();
      updateManager.showUpdateDialog(context, force: true).then((_) {
        Navigator.of(context).pop(); // 关闭加载对话框
      }).catchError((error) {
        Navigator.of(context).pop(); // 关闭加载对话框
        // 显示错误提示
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AppAlertDialog(
                title: Text(context.featureText('检查更新失败')),
                // 单列按原顺序排，确定在最下面。
                actionColumns: 1,
                content: Text(context.featureText('请检查网络连接后重试')),
                actions: [
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: LZYCheckUpdateManager.platformDownloadUrl));
                      Navigator.of(context).pop();
                      AppToast.show(context.featureText('下载链接已复制到剪贴板'),
                          duration: Duration(seconds: 2));
                    },
                    child: Text(context.featureText('复制下载链接')),
                  ),
                  LZYCheckUpdateManager().buildReleasesButton(context),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(context.featureText('确定')),
                  ),
                ],
              );
            },
          );
        }
      });
    }
    if (item.title == '定数分布') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const DifficultyDistributionPage()),
      );
    }
    if (item.title == '系统设置') {
      _showThemeDialog();
    }
    if (item.title == '收藏夹') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FavoriteFolderPage()),
      );
    }
    if (item.title == '同步成绩到落雪') {
      // 与「系统」hub 页同一份实现（SyncFlowMixin）：线路2 走对话框输入 +
      // 按钮上进度，不再跳 UpdateLuoXueScorePage（那里没有任何进度反馈）
      await syncToLuoXueByCurrentRoute();
    }
    if (item.title == '同步成绩到 AWMC NET') {
      // AWMC NET 只有二维码这一条写入路径（与另外两个平台不同，没有线路概念）。
      // 等待进度与另外两个同步入口一样显示在**按钮**上，不锁住整个页面。
      await syncToAwmcNetWithButton();
    }
    if (item.title == '同步成绩到多端') {
      await syncToMultiplePlatforms();
    }
    if (item.title == '每日推荐') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DailyRecommendPage()),
      );
    }
    if (item.title == '好友对比') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FriendComparePage()),
      );
    }
    if (item.title == '全国音游地图') {
      final uri = Uri.parse('https://map.bemanicn.com/');
      try {
        if (await ExternalLaunchUtil.open(uri)) {
          return;
        } else {
          launchUrlFallback(uri.toString(), context);
        }
      } catch (e) {
        debugPrint('打开全国音游地图失败: $e');
        launchUrlFallback(uri.toString(), context);
      }
    }
    if (item.title == '全球音游街机地图') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GlobalArcadeMapPage()),
      );
    }
    if (item.title == '最近评论') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecentCommentsPage()),
      );
    }
    if (item.title == '最近评分') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecentRatingsPage()),
      );
    }
    if (item.title == '数据备份') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const DataBackupPage()),
      );
    }
    if (item.title == '查看友情链接') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FriendLinksPage()),
      );
    }
  }

  // 构建收藏的功能区域（首页直接显示已收藏功能的入口按钮）
  // [titles] 来自 FavoriteFeaturesNotifier 的实时值，
  // 这样其他页面切换星标后，本区域无需依赖本地缓存即可立即刷新。
  Widget _buildFavoriteFeaturesSection(
      BuildContext context, Set<String> titles) {
    final available = {
      for (final item in _searchableCategories.expand((c) => c.items))
        item.title: item,
    };
    final items = [
      for (final title in titles)
        if (available.containsKey(title)) available[title]!,
    ];

    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(context.featureText('常用'),
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              _buildFavoriteSortButton(context),
            ],
          ),
        ),
        AnimatedReveal(
          visible: _sortingFavorites,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(context.featureText('拖动图标调整顺序；点叉号或拖到删除区域可移除收藏'),
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
        ),
        if (items.isEmpty)
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Text(
              context.featureText('点击分类中的 ⭐ 星标即可收藏功能，收藏后直接显示在此处'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          )
        else
          // 正常态和编辑态共用一棵树：切换时图标不重新入场。
          ValueListenableBuilder<UpdateAvailability?>(
            valueListenable: UpdateNotifier.available,
            builder: (context, update, _) => ListenableBuilder(
              listenable: AccountAuthorizationStatus.changes,
              builder: (context, _) => FavoriteEditGrid(
                editing: _sortingFavorites,
                items: [
                  for (final item in items)
                    () {
                      final isUpdate = UpdateNotifier.isUpdateEntry(item.title);
                      final effective =
                          isUpdate && update != null ? update : null;
                      final presentation =
                          AccountAuthorizationStatus.present(context, item);
                      return FavoriteEditItem(
                        title: item.title,
                        displayTitle: isUpdate
                            ? UpdateNotifier.titleFor(effective)
                            : presentation.title,
                        icon: isUpdate
                            ? Icons.arrow_upward_rounded
                            : presentation.icon,
                        titleColor: effective == null
                            ? null
                            : UpdateAvailableIcon.green,
                        loading: _syncBusyFor(item.title),
                        progress: _syncProgressFor(item.title),
                        onTap: _isSyncBlockedFeature(item.title) &&
                                anyBusy &&
                                !_syncBusyFor(item.title)
                            ? null
                            : () => _handleFeatureTap(item),
                      );
                    }(),
                ],
                onReorder: (ordered) {
                  // 当前不可用的收藏不显示，但要留在原来的集合里。
                  final hidden = titles.where((t) => !ordered.contains(t));
                  unawaited(FavoriteFeaturesNotifier.replaceAll(
                      {...ordered, ...hidden}));
                },
                onRemove: _toggleFavorite,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteSortButton(BuildContext context) {
    return Semantics(
      button: true,
      selected: _sortingFavorites,
      label: _sortingFavorites
          ? context.featureText('完成收藏功能编辑')
          : context.featureText('编辑收藏功能'),
      excludeSemantics: true,
      child: TextButton(
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _sortingFavorites = !_sortingFavorites);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(44, 40),
        ),
        child: Text(
            _sortingFavorites
                ? context.featureText('完成')
                : context.featureText('编辑'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }

  /// 收藏区某个同步入口是否正在跑（用来在按钮上出进度）。
  ///
  /// 只有这一个入口为 true 时按钮才会转；同一时刻最多一个在跑（[anyBusy] 互斥）。
  bool _syncBusyFor(String title) {
    if (title == '缓存管理') return CacheManagementService.instance.reloadingBase;
    if (title == '同步成绩到水鱼') return syncingDivingFish;
    if (title == '同步成绩到落雪') return syncingLuoXue;
    if (title == '同步成绩到 AWMC NET') return syncingAwmcNet;
    if (title == '同步成绩到多端') return syncingMulti;
    return false;
  }

  bool _isSyncFeature(String title) =>
      title == '同步成绩到水鱼' ||
      title == '同步成绩到落雪' ||
      title == '同步成绩到 AWMC NET' ||
      title == '同步成绩到多端';

  bool _isSyncBlockedFeature(String title) =>
      _isSyncFeature(title) ||
      title == '登录水鱼' ||
      title == '登出水鱼账号' ||
      title == '拉取成绩并更新数据' ||
      title == '拉取成绩并更新数据（高级）' ||
      title == '缓存管理' ||
      title == '刷新机台游玩次数';

  double? _syncProgressFor(String title) {
    if (title == '缓存管理') return CacheManagementService.instance.reloadProgress;
    if (title == '同步成绩到水鱼') return divingFishProgress;
    if (title == '同步成绩到落雪') return luoXueProgress;
    if (title == '同步成绩到 AWMC NET') return awmcNetProgress;
    if (title == '同步成绩到多端') return multiSyncProgress;
    return null;
  }

  // 构建大类导航卡片按钮
  Widget _buildCategoryCard(
    ButtonCategory category,
    BuildContext context, {
    int? overrideCount,
    VoidCallback? onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: SizedBox(
        height: screenHeight * 0.09,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: scheme.surface.withValues(alpha: 0.85),
            side: BorderSide(
              color: scheme.outlineVariant,
              width: AppConstants.borderWidth,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadiusLarge),
            ),
            elevation: 0,
          ),
          onPressed: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => FeatureCategoryPage(
                      category: category,
                      onFeatureTap: _handleFeatureTap,
                      loginStateNotifier: _loginStateNotifier,
                    ),
                  ),
                ).then((_) {
                  _checkDivingFishLoginStatus();
                });
              },
          child: Row(
            children: [
              // 左侧：分类图标（主题色圆形背景）
              Container(
                width: screenWidth * 0.11,
                height: screenWidth * 0.11,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon ??
                      (category.items.isNotEmpty
                          ? category.items.first.icon
                          : Icons.folder),
                  color: scheme.primary,
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              // 中间：分类名称 + 功能数量
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.featureText(category.name),
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      context.l10n.hubFeaturesCount(
                          overrideCount ?? category.items.length),
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.6),
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ],
                ),
              ),
              // 右侧：箭头
              Icon(
                Icons.chevron_right,
                color: scheme.onSurface.withValues(alpha: 0.5),
                size: screenWidth * 0.06,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首页搜索的歌曲结果：输入停顿后才搜索，旧请求不会覆盖新结果。
class _HomeSongSearchResults extends StatefulWidget {
  final String query;
  final ValueChanged<String> onOpen;

  const _HomeSongSearchResults({required this.query, required this.onOpen});

  @override
  State<_HomeSongSearchResults> createState() => _HomeSongSearchResultsState();
}

class _HomeSongSearchResultsState extends State<_HomeSongSearchResults> {
  /// 结果最多显示这么多首，完整结果和筛选在「乐曲查询」。
  static const int _maxShown = 50;

  Timer? _debounce;
  int _generation = 0;
  List<Song>? _songs;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(_HomeSongSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _search() async {
    final generation = ++_generation;
    final query = widget.query.trim();
    if (query.isEmpty) {
      setState(() {
        _songs = const [];
        _failed = false;
      });
      return;
    }
    try {
      final songs = await SongSearchService.searchSongs(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _songs = songs;
        _failed = false;
      });
    } catch (error) {
      debugPrint('首页歌曲搜索失败: $error');
      if (!mounted || generation != _generation) return;
      setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final songs = _songs;
    Widget message(String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
          ),
        );
    final Widget body;
    if (_failed) {
      body = message(context.l10n.flowSongSearchFailedTheLibraryMayNot);
    } else if (songs == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (songs.isEmpty) {
      body = message(widget.query.trim().isEmpty
          ? context.featureText('输入关键词搜索歌曲')
          : context.featureText('没有找到匹配的歌曲'));
    } else {
      final shown = songs.take(_maxShown).toList();
      body = AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < shown.length; i++)
              InkWell(
                onTap: () => widget.onOpen(shown[i].id),
                child: Container(
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(
                            top: BorderSide(
                                color: AppSurfaces.hairline(context))),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CoverUtil.buildCoverWidgetWithContext(
                              context, shown[i].id, 40),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SongTypeBadge(songId: shown[i].id, type: shown[i].type),
                      const SizedBox(width: 6),
                      Expanded(
                        child: MarqueeText(
                          text: shown[i].basicInfo.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text(
            songs == null
                ? context.featureText('歌曲')
                : songs.length > _maxShown
                    ? context.l10n.homeSongCountLimited(songs.length, _maxShown)
                    : context.l10n.homeSongCount(songs.length),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        body,
      ],
    );
  }
}

/// 列表末尾的留白：开启避让后把可滚动范围抬到输入法上方，背景和列表位置都不变。
///
/// 单独成组件，键盘动画的每一帧只重建这一格，不重建整个首页。
class _HomeSearchKeyboardSpacer extends StatelessWidget {
  /// 列表底部内边距里已经留出的高度。
  final double coveredBottom;

  const _HomeSearchKeyboardSpacer({required this.coveredBottom});

  @override
  Widget build(BuildContext context) {
    if (!SearchInteractionPreferences.instance.avoidKeyboard) {
      return const SizedBox.shrink();
    }
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return SizedBox(height: inset > coveredBottom ? inset - coveredBottom : 0);
  }
}
