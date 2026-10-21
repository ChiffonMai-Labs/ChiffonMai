import 'package:flutter/material.dart';
import 'package:simai_flutter/simai_flutter.dart';

/// 只为播放器依赖内部打开的视频导出页补齐不透明底色。
/// 保留现有转场配置，不切换 App 的主题或改变底下页面的颜色。
class VideoExportPageTransitionsTheme extends PageTransitionsTheme {
  const VideoExportPageTransitionsTheme({required super.builders});

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // simai_flutter 以这个返回类型 push 导出页，普通播放/游玩路由不匹配。
    if (route is MaterialPageRoute<SimaiVideoExportResult>) {
      final theme = Theme.of(context);
      final background = theme.colorScheme.surface;
      child = ColoredBox(
        color: background,
        child: Theme(
          data: theme.copyWith(scaffoldBackgroundColor: background),
          child: child,
        ),
      );
    }
    return super
        .buildTransitions(route, context, animation, secondaryAnimation, child);
  }
}
