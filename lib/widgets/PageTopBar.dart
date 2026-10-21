import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/AppTheme.dart';

/// 标题的排布方式（映射到 `AppBar.centerTitle`）。
enum PageTopBarTitleAlign {
  /// 居中（`centerTitle: true`）—— 与「Rating 排行榜」页一致。
  center,

  /// 靠左，跟在返回按钮后面（`centerTitle: false`）。
  start,
}

/// 全 App 统一的页面标题栏 —— **就是一层 Material `AppBar`**。
///
/// 历史：这套标题栏原本在 **48 个页面**里各抄了一份手写 `Container + Row`
/// （透明无底、写死 48dp 顶部偏移）。先收敛到本组件，再按「Rating 排行榜」页
/// 的观感重做；最后发现**标准 `AppBar` 本身更好看**，于是直接把实现换成 `AppBar`。
///
/// 关键点：`AppBar` 并不要求放在 `Scaffold.appBar` —— 它就是个普通 widget
/// （`PreferredSizeWidget` 只是它顺便实现的），放在 body 的 `Column` 里一样正确：
/// 自己带 `SafeArea` 处理状态栏、自带 `Material` 底色、自带 `Semantics(header)`、
/// 自带 `AnnotatedRegion<SystemUiOverlayStyle>`。所以 48 个页面**不需要改结构**
/// （README：原来的 `Column(children: [bar, Expanded(content)])` 原样保留），
/// 就拿到了标准观感。
///
/// 与「Rating 排行榜」页完全同源：同一个 `AppBar` + 同一份 `appBarTheme`，
/// 底色取 `AppColors.cardBackground`（Rating 页是 Scaffold 底色透出透明 AppBar，
/// 这里由 AppBar 自己画），标题默认 20 / bold / `colorScheme.primary` / 居中。
///
/// 字体固定走 [AppTheme.font]（思源黑体，`google_fonts` 运行时从网络获取），
/// 与全 App 正文同一套 —— `AppBar` 会给标题另套一层 `DefaultTextStyle`，
/// 裸 `TextStyle` 会把 `main.dart` 注入的全局字体顶掉，标题就悄悄变成系统默认字体。
///
/// 与 `Scaffold.appBar` 的唯一区别：不参与 Scaffold 布局，所以不会自动处理
/// drawer 汉堡键、`extendBodyBehindAppBar`、以及给 body 去掉顶部 `MediaQuery.padding`
/// —— 本项目的页面都不依赖这些。
class PageTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// 标题文字。
  final String title;

  /// 右侧动作区。
  final List<Widget> actions;

  /// 返回回调；默认用标准 [BackButton]（`Navigator.maybePop`）。
  final VoidCallback? onBack;

  /// 是否显示返回按钮（默认显示，与迁移前一致）。
  ///
  /// 这里用「显式 leading」而不是 `automaticallyImplyLeading`：后者在路由不可 pop
  /// 时会把返回键藏掉，而各页面一直是「总是有返回键」。
  final bool showBack;

  /// 标题字号；默认 20（与 `appBarTheme.titleTextStyle` 一致）。
  final double? fontSize;

  /// 标题颜色；默认 `colorScheme.primary`。
  final Color? titleColor;

  /// 标题字重；默认 bold。
  final FontWeight? titleWeight;

  /// 标题排布；默认居中。
  final PageTopBarTitleAlign titleAlign;

  /// bar 的底色。默认 `AppColors.cardBackground(brightness)`；
  /// 传 `Colors.transparent` 可做成透明 bar。
  final Color? barBackground;

  /// 底部是否画一条 `outlineVariant` 细线（默认不画，与 Rating 页一致）。
  final bool showDivider;

  /// 工具栏高度；默认交给 `AppBar`（`kToolbarHeight` = 56）。
  final double? toolbarHeight;

  /// 状态栏高度之后是否让 AppBar 自己处理（默认 true）。
  ///
  /// 关掉它（`primary: false`）表示「我不希望 bar 自己去避让状态栏」，
  /// 一般只有嵌在别的 bar 下面时才需要。
  final bool primary;

  /// 附着在标题栏下方的部件（如进度条），对应 `AppBar.bottom`。
  final PreferredSizeWidget? bottom;

  /// 标题字符串变化时是否使用淡入滑动过渡。
  final bool animateTitle;

  /// 标题是否在返回按钮与右侧操作按钮之间的可用区域内居中。
  ///
  /// 适合标题栏右侧有多个操作按钮、又希望标题只占左侧空间的页面。
  final bool centerTitleInAvailableSpace;

  const PageTopBar({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.onBack,
    this.showBack = true,
    this.fontSize,
    this.titleColor,
    this.titleWeight,
    this.titleAlign = PageTopBarTitleAlign.center,
    this.barBackground,
    this.showDivider = false,
    this.toolbarHeight,
    this.primary = true,
    this.bottom,
    this.animateTitle = false,
    this.centerTitleInAvailableSpace = false,
  });

  /// 标题默认字号（与 `appBarTheme.titleTextStyle` 一致）。
  static const double titleFontSize = 20;

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;

    final resolvedColor = titleColor ?? scheme.primary;
    final resolvedFontSize = fontSize ?? titleFontSize;
    final resolvedWeight = titleWeight ?? FontWeight.bold;

    final titleText = _PageTopBarTitle(
      title: title,
      style: AppTheme.font(
        color: resolvedColor,
        fontSize: resolvedFontSize,
        fontWeight: resolvedWeight,
      ),
      defaultTextAlign: centerTitleInAvailableSpace ||
              titleAlign == PageTopBarTitleAlign.center
          ? TextAlign.center
          : TextAlign.start,
      // 歌曲详情页切换到长歌名时，只有实际发生省略才靠左，短标题和未截断的歌名始终居中。
      alignStartWhenOverflow:
          animateTitle && titleAlign == PageTopBarTitleAlign.center,
    );

    // 普通标题交给 NavigationToolbar 自己计算中心点。动画标题使用一块固定宽度，
    // 宽度不超过两侧最大控件的安全范围，避免撑满后被返回按钮夹到右侧。
    final Widget titleWidget;
    if (centerTitleInAvailableSpace) {
      titleWidget = SizedBox(width: double.infinity, child: titleText);
    } else if (animateTitle && titleAlign == PageTopBarTitleAlign.center) {
      final leadingWidth = showBack ? kToolbarHeight : 0.0;
      final trailingWidth = actions.length * kToolbarHeight;
      // NavigationToolbar 默认会在两侧各保留 16dp 的 middleSpacing；
      // 这部分也要计入安全边界，否则标题会再向右偏一小段。
      final sideWidth = math.max(leadingWidth, trailingWidth) +
          NavigationToolbar.kMiddleSpacing;
      final centeredTitleWidth =
          (MediaQuery.sizeOf(context).width - sideWidth * 2)
              .clamp(0.0, double.infinity)
              .toDouble();
      titleWidget = SizedBox(width: centeredTitleWidth, child: titleText);
    } else {
      titleWidget = titleText;
    }
    final resolvedTitleWidget = centerTitleInAvailableSpace
        ? Align(alignment: Alignment.center, child: titleWidget)
        : titleWidget;

    final appBar = AppBar(
      // 有底：由 AppBar 自己的 Material 画，状态栏区域也一起着色
      backgroundColor: barBackground ?? AppColors.cardBackground(brightness),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // 透明标题栏无法靠背景色自动推断亮度；按当前主题明确指定状态栏图标，
      // 避免浅色页面沿用浅色图标而与背景融为一体。
      systemOverlayStyle: AppTheme.systemUiOverlayStyle(
        brightness,
        navigationBarColor: scheme.surface,
      ),
      centerTitle: titleAlign == PageTopBarTitleAlign.center,
      primary: primary,
      toolbarHeight: toolbarHeight,
      bottom: bottom,
      shape: showDivider
          ? Border(bottom: BorderSide(color: scheme.outlineVariant))
          : null,
      // 返回键：显式给 leading（见 showBack 注释），默认用标准 BackButton
      automaticallyImplyLeading: false,
      leading: !showBack
          ? null
          : Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  if (onBack != null) {
                    onBack!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ),
      // 窄屏或动作按钮较多时按可用空间截断，避免字号缩到只剩一条线。
      title: animateTitle
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.12),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                alignment: Alignment.center,
                fit: StackFit.passthrough,
                children: [
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              ),
              child: KeyedSubtree(
                key: ValueKey(title),
                child: resolvedTitleWidget,
              ),
            )
          : resolvedTitleWidget,
      actions: actions.isEmpty ? null : actions,
      // 图标色与 appBarTheme.iconTheme 一致（primary）；页面传进来的 actions
      // 若自带 color 则以自带的为准
      iconTheme: IconThemeData(color: scheme.primary),
      actionsIconTheme: IconThemeData(color: scheme.primary),
    );

    // 带 `bottom`（进度条/TabBar）时，AppBar 内部是 `Column + Flexible`，
    // 需要**有界高度**才不会报 "non-zero flex but unbounded height" ——
    // 放在 Scaffold.appBar 时由 Scaffold 提供，放在 body 的 Column 里就得自己给。
    if (bottom == null) return appBar;
    final statusBar = primary ? MediaQuery.paddingOf(context).top : 0.0;
    return SizedBox(
      height: preferredSize.height + statusBar,
      child: appBar,
    );
  }
}

/// 标题栏中的单行文本。
///
/// 动画标题使用整块可用宽度作为稳定的布局基准，避免 AnimatedSwitcher 在
/// 长歌名和「歌曲详情」之间切换时按文本自身宽度重新定位。实际发生省略时
/// 才改为左对齐，恢复为短标题后会直接在同一块区域的中心显示。
class _PageTopBarTitle extends StatelessWidget {
  final String title;
  final TextStyle style;
  final TextAlign defaultTextAlign;
  final bool alignStartWhenOverflow;

  const _PageTopBarTitle({
    required this.title,
    required this.style,
    required this.defaultTextAlign,
    required this.alignStartWhenOverflow,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!alignStartWhenOverflow || !constraints.hasBoundedWidth) {
          return Text(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: defaultTextAlign,
            style: style,
          );
        }

        final textDirection = Directionality.of(context);
        final textScaler = MediaQuery.textScalerOf(context);
        final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
        final painter = TextPainter(
          text: TextSpan(text: title, style: effectiveStyle),
          maxLines: 1,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout();
        // 省略号出现前额外保留两个汉字宽度，避免标题刚超出一点就过早截断。
        final twoCharactersPainter = TextPainter(
          text: TextSpan(text: '中中', style: effectiveStyle),
          maxLines: 1,
          textDirection: textDirection,
          textScaler: textScaler,
        )..layout();
        final extraWidth = twoCharactersPainter.width;
        final expandedWidth = constraints.maxWidth + extraWidth;
        final isOverflowing = painter.width > expandedWidth + 0.1;
        final visualWidth = painter.width > constraints.maxWidth
            ? expandedWidth
            : constraints.maxWidth;
        final textHeight = painter.height;
        painter.dispose();
        twoCharactersPainter.dispose();
        final text = SizedBox(
          width: visualWidth,
          child: Text(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: isOverflowing ? TextAlign.start : defaultTextAlign,
            style: style,
          ),
        );

        if (visualWidth <= constraints.maxWidth) return text;
        // AppBar 为标题提供的高度无上限；扩宽时只放开宽度，避免高度变成无穷大而无法绘制。
        return SizedBox(
          height: textHeight,
          child: OverflowBox(
            alignment: isOverflowing ? Alignment.centerLeft : Alignment.center,
            minWidth: constraints.maxWidth,
            maxWidth: visualWidth,
            child: text,
          ),
        );
      },
    );
  }
}
