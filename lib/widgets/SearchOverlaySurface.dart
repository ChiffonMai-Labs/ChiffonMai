import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// 搜索框展开为临时页面的共用动效，输入区和内容区分别避让安全边距与键盘。
class SearchOverlaySurface extends StatelessWidget {
  const SearchOverlaySurface({
    super.key,
    required this.animation,
    required this.sourceRect,
    required this.input,
    required this.child,
    required this.onBackgroundTap,
    this.closing = false,
  });

  final Animation<double> animation;
  final Rect sourceRect;
  final Widget input;
  final Widget child;
  final VoidCallback onBackgroundTap;
  final bool closing;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final destination = Offset.zero & size;
      final targetInput = Rect.fromLTWH(
        16 + media.viewPadding.left,
        media.viewPadding.top + 8,
        math.max(0, size.width - 32 - media.viewPadding.horizontal),
        sourceRect.height,
      );
      return AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = Curves.easeInOutCubic.transform(animation.value);
          final surface = Rect.lerp(sourceRect, destination, progress)!;
          final inputRect = Rect.lerp(sourceRect, targetInput, progress)!;
          final contentTop = inputRect.bottom + 12;
          final contentHeight = math.max(
            0.0,
            size.height -
                contentTop -
                math.max(media.viewInsets.bottom, media.viewPadding.bottom) -
                16,
          );
          return IgnorePointer(
            ignoring: closing,
            child: ClipRRect(
              clipper:
                  _SearchRevealClipper(surface, lerpDouble(8, 0, progress)!),
              child: Material(
                color: colors.surface,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBackgroundTap,
                  child: Stack(children: [
                    Positioned.fromRect(rect: inputRect, child: input),
                    Positioned(
                      top: contentTop,
                      left: targetInput.left,
                      width: targetInput.width,
                      height: contentHeight,
                      child: Opacity(
                        opacity: ((progress - .25) / .75).clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _SearchRevealClipper extends CustomClipper<RRect> {
  const _SearchRevealClipper(this.rect, this.radius);
  final Rect rect;
  final double radius;

  @override
  RRect getClip(Size size) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  bool shouldReclip(_SearchRevealClipper oldClipper) =>
      rect != oldClipper.rect || radius != oldClipper.radius;
}
