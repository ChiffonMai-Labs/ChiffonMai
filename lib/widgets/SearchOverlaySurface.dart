import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// 搜索框展开为临时页面的共用动效，输入区和内容区分别避让安全边距与键盘。
class SearchOverlaySurface extends StatefulWidget {
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
  State<SearchOverlaySurface> createState() => _SearchOverlaySurfaceState();
}

class _SearchOverlaySurfaceState extends State<SearchOverlaySurface> {
  late CurvedAnimation _surfaceCurve;
  late CurvedAnimation _contentFade;

  @override
  void initState() {
    super.initState();
    _bindCurves(widget.animation);
  }

  void _bindCurves(Animation<double> animation) {
    _surfaceCurve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );
    _contentFade = CurvedAnimation(
      parent: _surfaceCurve,
      curve: const Interval(0.25, 1.0),
    );
  }

  @override
  void didUpdateWidget(covariant SearchOverlaySurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _contentFade.dispose();
      _surfaceCurve.dispose();
      _bindCurves(widget.animation);
    }
  }

  @override
  void dispose() {
    _contentFade.dispose();
    _surfaceCurve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final colors = Theme.of(context).colorScheme;
    final contentChild = RepaintBoundary(
      child: FadeTransition(
        opacity: _contentFade,
        child: widget.child,
      ),
    );
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final destination = Offset.zero & size;
      final targetInput = Rect.fromLTWH(
        16 + media.viewPadding.left,
        media.viewPadding.top + 8,
        math.max(0, size.width - 32 - media.viewPadding.horizontal),
        widget.sourceRect.height,
      );
      return AnimatedBuilder(
        animation: _surfaceCurve,
        child: contentChild,
        builder: (context, cachedContent) {
          final progress = _surfaceCurve.value;
          final surface = Rect.lerp(widget.sourceRect, destination, progress)!;
          final inputRect = Rect.lerp(widget.sourceRect, targetInput, progress)!;
          final contentTop = inputRect.bottom + 12;
          final contentHeight = math.max(
            0.0,
            size.height -
                contentTop -
                math.max(media.viewInsets.bottom, media.viewPadding.bottom) -
                16,
          );
          return IgnorePointer(
            ignoring: widget.closing,
            child: ClipRRect(
              clipper:
                  _SearchRevealClipper(surface, lerpDouble(8, 0, progress)!),
              child: Material(
                color: colors.surface,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onBackgroundTap,
                  child: Stack(children: [
                    Positioned.fromRect(rect: inputRect, child: widget.input),
                    Positioned(
                      top: contentTop,
                      left: targetInput.left,
                      width: targetInput.width,
                      height: contentHeight,
                      child: cachedContent!,
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
