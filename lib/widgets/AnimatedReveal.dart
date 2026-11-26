import 'package:flutter/material.dart';

/// 同步淡化与高度变化，隐藏后不保留点击和语义区域。
class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({super.key, required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  static const _defaultDuration = Duration(milliseconds: 260);
  late Widget _lastVisibleChild;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _defaultDuration,
    value: widget.visible ? 1 : 0,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _lastVisibleChild = widget.child;
    _controller.addStatusListener(_onStatusChanged);
  }

  void _onStatusChanged(AnimationStatus status) {
    if ((status == AnimationStatus.dismissed ||
            status == AnimationStatus.completed) &&
        mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _defaultDuration;
    _controller.duration = duration;
    if (duration == Duration.zero) {
      _controller.value = widget.visible ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(AnimatedReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 收起时保留上一帧文案，不能先把提示清空再播放空白淡出。
    if (widget.visible) _lastVisibleChild = widget.child;
    if (widget.visible == oldWidget.visible) return;
    if (_controller.duration == Duration.zero) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hidden = !widget.visible && _controller.isDismissed;
    return Offstage(
      offstage: hidden,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: ExcludeFocus(
          excluding: !widget.visible,
          child: ExcludeSemantics(
            excluding: !widget.visible,
            child: SizeTransition(
              sizeFactor: _curve,
              axisAlignment: -1.0,
              child: FadeTransition(
                opacity: _curve,
                child: _lastVisibleChild,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
