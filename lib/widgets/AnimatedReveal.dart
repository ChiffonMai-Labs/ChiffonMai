import 'package:flutter/material.dart';

/// 同步淡化与高度变化，隐藏后不保留点击和语义区域。
class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({super.key, required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal> {
  late Widget _lastVisibleChild;

  @override
  void initState() {
    super.initState();
    _lastVisibleChild = widget.child;
  }

  @override
  void didUpdateWidget(AnimatedReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 收起时保留上一帧文案，不能先把提示清空再播放空白淡出。
    if (widget.visible) _lastVisibleChild = widget.child;
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: widget.visible ? 1 : 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        child: _lastVisibleChild,
        builder: (context, value, child) => ClipRect(
          child: Align(
            alignment: Alignment.topLeft,
            heightFactor: value,
            child: IgnorePointer(
              ignoring: !widget.visible,
              child: ExcludeFocus(
                excluding: !widget.visible,
                child: ExcludeSemantics(
                  excluding: !widget.visible,
                  child: Opacity(opacity: value, child: child),
                ),
              ),
            ),
          ),
        ),
      );
}
