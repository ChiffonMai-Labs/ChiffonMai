import 'package:flutter/cupertino.dart' as ios;
import '../../l10n/FeatureLocalizations.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import '../../entity/Home/FeatureModels.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppModePreferences.dart';
import '../../utils/NavigationPreferences.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/LiquidGlassNavigationBar.dart';
import '../../widgets/ExpandingPillNavigationBar.dart';
import '../../widgets/MainNavigationViewport.dart';
import '../../widgets/MainNavigationInsets.dart';
import '../../widgets/ThemeAwareBackground.dart';
import '../Home/HomePage.dart';
import '../Hub/ScoreHubPage.dart';
import '../Hub/LibraryHubPage.dart';
import '../Hub/PlayZoneHubPage.dart';
import '../Hub/SystemHubPage.dart';
import '../Portable/PortablePlayerPage.dart';

class AppShell extends StatefulWidget {
  final VoidCallback? onFirstFrameRendered;

  const AppShell({super.key, this.onFirstFrameRendered});

  /// 打开随身听曲库页（悬浮球的「播放列表」按钮用）。
  ///
  /// 只做一件事：push 曲库页。**没有**用来控制悬浮球显隐 ——
  /// 球本体挂在 `main.dart` 的 `MaterialApp.builder` 上（在所有路由之上；
  /// 放 AppShell 的 body 里会被 push 出来的功能页整个盖住，表现就是
  /// 「进了功能页只听到声音、看不到球」），显隐由 `PortablePlayerScope`
  /// 加上球自己判断。
  static Future<void> openPortablePlayerPage(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PortablePlayerPage()),
    );
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late final List<Widget> _pages;
  final _activeFeatureTask = ValueNotifier<FeatureTask?>(null);
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();
  final GlobalKey<SystemHubPageState> _systemPageKey =
      GlobalKey<SystemHubPageState>();
  final GlobalKey<PlayZoneHubPageState> _playZoneKey =
      GlobalKey<PlayZoneHubPageState>();
  bool _firstFrameNotified = false;
  double _horizontalDragDistance = 0;
  Timer? _navSelectionDebounce;
  int? _pendingIndex;

  static const Duration _navDebounceDuration = Duration(milliseconds: 120);

  // ===== 5 个主分类标签（2026-11：出勤 + 休闲 合并为「游玩」） =====
  // 下标顺序即页面顺序：首页 0 / 曲库 1 / 成绩 2 / 游玩 3 / 我的 4。
  static const int _playZoneIndex = 3;
  static const List<int> _standardTabIndices = [0, 1, 2, 3, 4];
  static const List<int> _simpleTabIndices = [0, 2, 4];

  List<int> get _visibleTabIndices => AppModePreferences.instance.isSimple
      ? _simpleTabIndices
      : _standardTabIndices;

  static const List<_NavTab> _tabs = [
    _NavTab(
      label: '首页',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavTab(
      label: '曲库',
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
    ),
    _NavTab(
      label: '成绩',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics_rounded,
    ),
    _NavTab(
      label: '游玩',
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports_rounded,
    ),
    _NavTab(
      label: '我的',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  // ===== 底部导航尺寸 =====
  // 药丸 indicator 与图标槽共用 pillH/iconTop，图标天生在药丸内垂直居中，
  // 不再依赖 Column 在整栏里的居中位置（那样药丸和图标会有几像素错位）。
  static const double barH = 72; // 导航栏总高
  static const double pillW = 56; // 药丸宽
  static const double pillH = 30; // 药丸高（也是图标槽高）
  static const double iconTop = 11; // 药丸/图标槽的顶部偏移
  static const double labelGap = 4; // 图标与文字间距
  static const double navigationBottomGap = 14;
  static const double contentBottomGap = 8;

  @override
  void initState() {
    super.initState();
    NavigationPreferences.instance.addListener(_onNavigationPreferencesChanged);
    AppModePreferences.instance.addListener(_onAppModeChanged);
    unawaited(NavigationPreferences.instance.load());
    unawaited(AppModePreferences.instance.load());
    _pages = [
      HomePage(
        key: _homePageKey,
        activeTask: _activeFeatureTask,
        onLibraryTap: () {
          if (AppModePreferences.instance.isSimple) {
            _openSubHub(
              title: context.featureText('曲库'),
              child: const LibraryHubPage(showHeader: false),
            );
          } else {
            _selectIndex(1);
          }
        },
        onEntertainmentTap: () {
          if (AppModePreferences.instance.isSimple) {
            _openSubHub(
              title: context.featureText('游玩'),
              child: const PlayZoneHubPage(
                showHeader: false,
                initialSection: 1,
              ),
            );
          } else {
            _selectIndex(_playZoneIndex);
            _playZoneKey.currentState?.showSection(1);
          }
        },
        onSystemFeatureTap: (item) async {
          await _systemPageKey.currentState?.openFeature(item);
        },
      ),
      const LibraryHubPage(),
      const ScoreHubPage(),
      PlayZoneHubPage(key: _playZoneKey),
      SystemHubPage(
        key: _systemPageKey,
        activeTask: _activeFeatureTask,
      ),
    ];
    // 仅在首帧渲染完成后触发一次回调，避免每次 build 都重新调度
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _firstFrameNotified) return;
      _firstFrameNotified = true;
      widget.onFirstFrameRendered?.call();
    });
  }

  @override
  void dispose() {
    _navSelectionDebounce?.cancel();
    _activeFeatureTask.dispose();
    NavigationPreferences.instance
        .removeListener(_onNavigationPreferencesChanged);
    AppModePreferences.instance.removeListener(_onAppModeChanged);
    super.dispose();
  }

  void _onNavigationPreferencesChanged() {
    if (mounted) setState(() {});
  }

  void _onAppModeChanged() {
    if (!mounted) return;
    // 从简洁模式隐藏掉的标签页切入时，回落到首页并清理未触发的切页防抖。
    if (!_visibleTabIndices.contains(_index)) {
      _navSelectionDebounce?.cancel();
      _pendingIndex = null;
      _index = 0;
    }
    setState(() {});
  }

  void _openSubHub({required String title, required Widget child}) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) => BackgroundPageScaffold(
          title: title,
          child: MediaQuery.removePadding(
            context: routeContext,
            removeTop: true,
            child: child,
          ),
        ),
      ),
    );
  }

  void _selectIndex(int index) {
    // 离开当前 Hub 时清理输入框焦点，避免返回首页后输入法重新拉起。
    FocusManager.instance.primaryFocus?.unfocus();
    final next = index.clamp(0, _tabs.length - 1);
    if (next == _index && _pendingIndex == null) return;
    if (next == _index) {
      _pendingIndex = null;
      _navSelectionDebounce?.cancel();
      return;
    }

    _pendingIndex = next;
    _navSelectionDebounce?.cancel();
    _navSelectionDebounce = Timer(_navDebounceDuration, () {
      if (!mounted || _pendingIndex == null) return;
      final target = _pendingIndex!;
      _pendingIndex = null;
      if (target == _index || !_visibleTabIndices.contains(target)) return;
      setState(() => _index = target);
    });
  }

  void _onHorizontalDragStart(DragStartDetails _) {
    _horizontalDragDistance = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _horizontalDragDistance += details.primaryDelta ?? details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (NavigationPreferences.instance.swipeEnabled &&
        _horizontalDragDistance.abs() >= 48) {
      final visible = _visibleTabIndices;
      final pos = visible.indexOf(_index);
      final currentPos = pos < 0 ? 0 : pos;
      final nextPos = (currentPos + (_horizontalDragDistance < 0 ? 1 : -1))
          .clamp(0, visible.length - 1);
      _selectIndex(visible[nextPos]);
    }
    _horizontalDragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSimple = AppModePreferences.instance.isSimple;
    final visibleIndices = _visibleTabIndices;
    final rawNavIndex = visibleIndices.indexOf(_index);
    final navIndex =
        (rawNavIndex < 0 ? 0 : rawNavIndex).clamp(0, visibleIndices.length - 1);
    // viewPadding 是窗口当前真实的系统底部 inset：系统导航栏隐藏时为 0，
    // 手势条/三键导航栏出现时则自动变成对应设备的实际高度。
    // 不使用 padding，避免 SafeArea 或键盘状态改变后把系统栏高度算错。
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final systemBottomInset = viewPadding.bottom;
    // Hub 列表的尾部留白由布局参数和系统 inset 共同计算，而不是写死某个
    // 设备的导航栏高度。这样有无系统栏时，最后一个功能按钮到悬浮栏的视觉距离相同。
    final appleBar = Theme.of(context).platform == TargetPlatform.iOS &&
        NavigationPreferences.instance.barStyle == NavigationBarStyle.standard;
    final navigationReserve = systemBottomInset +
        contentBottomGap +
        (appleBar ? 50.0 : barH + navigationBottomGap);
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      // 随身听悬浮球**不在这里** —— 它挂在 main.dart 的 MaterialApp.builder 上，
      // 这样才盖得住 push 出来的各个功能页（详见那边的注释）。
      body: Stack(
        children: [
          // Stack 的普通子节点会收到宽松约束。自由窗口切换时，
          // 这可能让背景和 Hub 内容拿不到有效尺寸，而下面的悬浮导航因为
          // 是 Positioned 仍然正常显示，最终表现为「只剩导航栏、页面全黑」。
          // 用 Positioned.fill 固定内容层跟随当前窗口尺寸。
          Positioned.fill(
            child: ColoredBox(
              // 先铺主题底色，避免窗口调整或背景图异步加载时露出系统黑底。
              color: scheme.surface,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart:
                    NavigationPreferences.instance.swipeEnabled
                        ? _onHorizontalDragStart
                        : null,
                onHorizontalDragUpdate:
                    NavigationPreferences.instance.swipeEnabled
                        ? _onHorizontalDragUpdate
                        : null,
                onHorizontalDragEnd: NavigationPreferences.instance.swipeEnabled
                    ? _onHorizontalDragEnd
                    : null,
                child: DeferredAppModeScope(
                  child: ThemeAwareBackground(
                    showDecorativeImage: _index == 0,
                    child: MainNavigationInsets(
                      bottom: navigationReserve,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: viewPadding.left,
                          right: viewPadding.right,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxWidth: AppDesignTokens.maxContentWidth),
                            child: MainNavigationViewport(
                              pages: _pages,
                              index: _index,
                              transitionEnabled: NavigationPreferences
                                      .instance.transitionEnabled &&
                                  !isSimple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 导航栏属于页面内容层：它只占自己的圆角浮层，不再挂在
          // Scaffold.bottomNavigationBar，也不会铺满设备底部。
          Positioned(
            left: (appleBar ? 0 : 12) + viewPadding.left,
            right: (appleBar ? 0 : 12) + viewPadding.right,
            bottom: appleBar ? 0 : systemBottomInset + navigationBottomGap,
            child: appleBar
                ? ios.CupertinoTabBar(
                    currentIndex: navIndex,
                    onTap: (i) => _selectIndex(visibleIndices[i]),
                    activeColor: scheme.primary,
                    items: [
                      for (final tabIndex in visibleIndices)
                        BottomNavigationBarItem(
                            icon: Icon(const [
                              ios.CupertinoIcons.house,
                              ios.CupertinoIcons.music_note_list,
                              ios.CupertinoIcons.chart_bar,
                              ios.CupertinoIcons.game_controller,
                              ios.CupertinoIcons.person_crop_circle
                            ][tabIndex]),
                            label: context.featureText(_tabs[tabIndex].label))
                    ],
                  )
                : _buildFloatingNavigation(scheme, visibleIndices, navIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingNavigation(
    ColorScheme scheme,
    List<int> visibleIndices,
    int navIndex,
  ) {
    final navigation = NavigationPreferences.instance;
    final destinations = [
      for (final tabIndex in visibleIndices)
        LiquidGlassDestination(
          label: context.featureText(_tabs[tabIndex].label),
          icon: _tabs[tabIndex].icon,
          selectedIcon: _tabs[tabIndex].activeIcon,
        ),
    ];
    if (navigation.barStyle == NavigationBarStyle.expandingPill) {
      return ExpandingPillNavigationBar(
        height: barH,
        selectedIndex: navIndex,
        onSelected: (i) => _selectIndex(visibleIndices[i]),
        animationEnabled: navigation.transitionEnabled,
        destinations: destinations,
      );
    }
    if (NavigationPreferences.instance.liquidGlassEnabled) {
      return LiquidGlassNavigationBar(
        height: barH,
        selectedIndex: navIndex,
        onSelected: (i) => _selectIndex(visibleIndices[i]),
        animationEnabled: NavigationPreferences.instance.transitionEnabled,
        destinations: destinations,
      );
    }
    // 「经典悬浮」样式（B 方案）：白色浮条 + 柔和投影 + 常驻文字标签。
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
      color: AppSurfaces.card(context).withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: barH,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double tabW = constraints.maxWidth / visibleIndices.length;
            return Stack(
              children: [
                // 滑动的药丸 indicator（核心改动：AnimatedPositioned）
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  left: navIndex * tabW + (tabW - pillW) / 2,
                  top: iconTop,
                  width: pillW,
                  height: pillH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(pillH / 2),
                    ),
                  ),
                ),
                // Tab row：icon + label，点击切换 _index
                Row(
                  children: [
                    for (int i = 0; i < visibleIndices.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _selectIndex(visibleIndices[i]),
                          child: Padding(
                            // 图标槽与药丸同高同顶，保证图标在药丸内垂直居中
                            padding: const EdgeInsets.only(top: iconTop),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: pillH,
                                  child: Center(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                      child: Icon(
                                        i == navIndex
                                            ? _tabs[visibleIndices[i]]
                                                .activeIcon
                                            : _tabs[visibleIndices[i]].icon,
                                        key: ValueKey(i == navIndex),
                                        size: 22,
                                        color: i == navIndex
                                            ? scheme.onSecondaryContainer
                                            : scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: labelGap),
                                SizedBox(
                                  width: tabW,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                    context.featureText(
                                        _tabs[visibleIndices[i]].label),
                                    maxLines: 1,
                                    softWrap: false,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: i == navIndex
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      letterSpacing: 0,
                                      color: i == navIndex
                                          ? scheme.onSurface
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }
}

class _NavTab {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
