import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'MarqueeText.dart';

/// 全 App 统一的页面顶部区域。
///
/// 透明底，直接铺在页面背景上：左边白色圆形返回键，紧跟靠左的粗体标题，右边是
/// 同样圆形的操作按钮。标题放不下时横向滚动，不截断。
///
/// 放进 `Scaffold.body` 的 `Column` 首位即可（也可以直接当 `Scaffold.appBar`），
/// 状态栏高度按真机自适应。
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// 标题文字。
  final String title;

  /// 右侧操作区。里面的 `IconButton` 默认是白色圆形，页面可以自己覆盖样式。
  final List<Widget> actions;

  /// 返回回调；默认 `Navigator.maybePop`。
  final VoidCallback? onBack;

  /// 是否显示返回按钮。
  final bool showBack;

  /// 底色，默认透明。盖在滚动内容上时传页面底色。
  final Color? barBackground;

  /// 附着在标题下方的部件（进度条、来源说明、TabBar）。
  final PreferredSizeWidget? bottom;

  /// 标题字符串变化时淡入淡出。
  final bool animateTitle;

  const AppHeader({
    super.key,
    required this.title,
    this.actions = const <Widget>[],
    this.onBack,
    this.showBack = true,
    this.barBackground,
    this.bottom,
    this.animateTitle = false,
  });

  /// 标题字号，与 `appBarTheme.titleTextStyle` 一致。
  static const double titleFontSize = 20;

  /// 标题行高度（不含状态栏）。
  static const double toolbarHeight = 56;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final circleButton = IconButton.styleFrom(
      backgroundColor: AppSurfaces.card(context),
      foregroundColor: scheme.onSurface,
      overlayColor: Colors.transparent,
      disabledBackgroundColor: AppSurfaces.card(context).withValues(alpha: 0.5),
      fixedSize: const Size(44, 44),
      minimumSize: const Size(44, 44),
      padding: EdgeInsets.zero,
    );
    final titleText = Semantics(
      header: true,
      child: MarqueeText(
        key: ValueKey(title),
        text: title,
        style: AppTheme.font(
          color: scheme.onSurface,
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return AnnotatedRegion(
      value: AppTheme.systemUiOverlayStyle(
        theme.brightness,
        navigationBarColor: scheme.surface,
      ),
      child: Material(
        color: barBackground ?? Colors.transparent,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: toolbarHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      if (showBack) ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, size: 22),
                          style: circleButton,
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            if (onBack != null) {
                              onBack!();
                            } else {
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: animateTitle
                            ? AnimatedSwitcher(
                                duration: AppDesignTokens.motion(
                                    context, AppDesignTokens.fastMotion),
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ...previous,
                                    if (current != null) current,
                                  ],
                                ),
                                child: titleText,
                              )
                            : titleText,
                      ),
                      if (actions.isNotEmpty)
                        IconButtonTheme(
                          data: IconButtonThemeData(style: circleButton),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final action in actions)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: action,
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
