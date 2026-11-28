import 'package:flutter/material.dart';

import 'ExpressiveLoadingIndicator.dart';

/// 图片加载中的占位：浅底 + M3E 变形加载动画。
///
/// 动画延迟淡入：本地磁盘命中通常几十毫秒就读完，用户看不到它，
/// 只有真的在等网络时才出现，不会让「读本地」看起来像「正在联网」。
class ImageLoadingIndicator extends StatelessWidget {
  /// 浅底的颜色，不传时用主题的浅底。盖在别的占位图上时传透明。
  final Color? background;

  const ImageLoadingIndicator({super.key, this.background});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: background ?? scheme.surfaceContainerHighest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortest = constraints.biggest.shortestSide;
          final size = shortest.isFinite
              ? (shortest * 0.42).clamp(14.0, 28.0)
              : 22.0;
          return Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: const Interval(0.5, 1),
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: ExpressiveLoadingIndicator(
                size: size,
                color: scheme.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}
