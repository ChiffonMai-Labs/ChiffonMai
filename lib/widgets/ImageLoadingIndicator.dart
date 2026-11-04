import 'package:flutter/material.dart';

/// 图片加载中的占位：浅底 + 小转圈。
///
/// 转圈延迟淡入：本地磁盘命中通常几十毫秒就读完，用户看不到它，
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
              ? (shortest * 0.36).clamp(12.0, 26.0)
              : 20.0;
          return Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: const Interval(0.5, 1),
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: size < 18 ? 1.6 : 2.2,
                  color: scheme.primary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
