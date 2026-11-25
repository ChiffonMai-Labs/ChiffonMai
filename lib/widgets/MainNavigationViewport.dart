import 'package:flutter/material.dart';

import '../utils/AppModePreferences.dart';
import '../utils/WindowDiagnostics.dart';

/// 保留所有主页面的状态，只对当前页和上一页进行淡入滑动过渡。
class MainNavigationViewport extends StatefulWidget {
  final List<Widget> pages;
  final int index;
  final bool transitionEnabled;

  const MainNavigationViewport({
    super.key,
    required this.pages,
    required this.index,
    required this.transitionEnabled,
  });

  @override
  State<MainNavigationViewport> createState() => _MainNavigationViewportState();
}

class _MainNavigationViewportState extends State<MainNavigationViewport>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _fadeIn = _curve;
  late final Animation<double> _fadeOut =
      Tween<double>(begin: 1.0, end: 0.0).animate(_curve);
  late Animation<Offset> _slideIn =
      const AlwaysStoppedAnimation<Offset>(Offset.zero);
  late Animation<Offset> _slideOut =
      const AlwaysStoppedAnimation<Offset>(Offset.zero);
  late int _fromIndex = widget.index;
  Size? _windowSize;

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_onAnimationStatus);
    _updateSlideAnimations(forward: true);
  }

  void _onAnimationStatus(AnimationStatus status) {
    // 动画完成时刷一次把上一页放入 Offstage，平时不触发整棵页面重建。
    if (status == AnimationStatus.completed && mounted) {
      setState(() {});
    }
  }

  void _updateSlideAnimations({required bool forward}) {
    final dx = forward ? 0.035 : -0.035;
    _slideIn = Tween<Offset>(
      begin: Offset(dx, 0),
      end: Offset.zero,
    ).animate(_curve);
    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-dx, 0),
    ).animate(_curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    if (_windowSize != null && size != _windowSize) {
      // 小窗/分屏切换会重建 Surface。结束正在进行的淡出，避免焦点和
      // 生命周期同时变化时，当前页留在透明的中间态；保留每个页面的 State。
      _controller.stop();
      _controller.value = 1;
      _fromIndex = widget.index;
      debugPrint('[Window] 主页面尺寸 ${WindowDiagnostics.size(_windowSize!)} -> '
          '${WindowDiagnostics.size(size)}，当前页 ${widget.index}，过渡已收尾');
    }
    _windowSize = size;
  }

  @override
  void didUpdateWidget(covariant MainNavigationViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _fromIndex = oldWidget.index;
      _updateSlideAnimations(forward: widget.index > _fromIndex);
      if (widget.transitionEnabled) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    } else if (!widget.transitionEnabled) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  static const _zeroOffset = AlwaysStoppedAnimation<Offset>(Offset.zero);
  static const _fullOpacity = AlwaysStoppedAnimation<double>(1.0);

  @override
  Widget build(BuildContext context) {
    final current = widget.index;
    final previous = _fromIndex;
    final animating = widget.transitionEnabled && !_controller.isCompleted;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.pages.length; i++)
          // 每个页面始终处于同一层级。切换包装组件的类型会销毁页面 State，
          // 导致账号、头像等重新加载，不能按可见性使用不同的组件结构。
          Offstage(
            offstage: i != current && (!animating || i != previous),
            child: IgnorePointer(
              ignoring: i != current,
              // 用 SlideTransition + FadeTransition 走渲染合成层，避免每帧
              // rebuild 整棵页面并用 Opacity 触发全屏离屏 saveLayer。
              child: SlideTransition(
                position: !animating
                    ? _zeroOffset
                    : (i == current
                        ? _slideIn
                        : (i == previous ? _slideOut : _zeroOffset)),
                child: FadeTransition(
                  opacity: !animating
                      ? _fullOpacity
                      : (i == current
                          ? _fadeIn
                          : (i == previous ? _fadeOut : _fullOpacity)),
                  child: TickerMode(
                    enabled: i == current,
                    child: DeferredAppModeScope(
                      child: widget.pages[i],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
