import 'package:flutter/material.dart';

import 'LiquidGlassNavigationBar.dart' show LiquidGlassDestination;

/// 选中项展开为横向胶囊，未选中项只显示图标。
/// 只在选择变化时运行动画，沿用主壳的尺寸、安全区与页面切换逻辑。
class ExpandingPillNavigationBar extends StatefulWidget {
  const ExpandingPillNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 66,
    this.animationEnabled = true,
  })  : assert(destinations.length > 1),
        assert(selectedIndex >= 0 && selectedIndex < destinations.length);

  final List<LiquidGlassDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;
  final bool animationEnabled;

  @override
  State<ExpandingPillNavigationBar> createState() =>
      _ExpandingPillNavigationBarState();
}

class _ExpandingPillNavigationBarState extends State<ExpandingPillNavigationBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<double> _from;
  late List<double> _to;

  bool get _animate =>
      widget.animationEnabled && !MediaQuery.disableAnimationsOf(context);

  List<double> get _targetWeights => List.generate(widget.destinations.length,
      (index) => index == widget.selectedIndex ? 2.0 : 1.0);

  List<double> get _weights {
    final progress = Curves.easeOutCubic.transform(_controller.value);
    return List.generate(_to.length,
        (index) => _from[index] + (_to[index] - _from[index]) * progress);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
    _to = _targetWeights;
    _from = _to;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animate) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant ExpandingPillNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinations.length != widget.destinations.length) {
      _to = _targetWeights;
      _from = _to;
      _controller.value = 1;
    } else if (oldWidget.selectedIndex != widget.selectedIndex) {
      // 快速连续切换时从当前可见宽度继续，不跳回上一个目标。
      _from = _weights;
      _to = _targetWeights;
      if (_animate) {
        _controller.forward(from: 0);
      } else {
        _controller.value = 1;
      }
    } else if (!_animate) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Material(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.96),
        elevation: 8,
        shadowColor: scheme.shadow.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: LayoutBuilder(
              builder: (context, constraints) => AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final weights = _weights;
                  final total =
                      weights.fold(0.0, (sum, weight) => sum + weight);
                  return Row(
                    children: [
                      for (var index = 0; index < weights.length; index++)
                        SizedBox(
                          width: constraints.maxWidth * weights[index] / total,
                          height: 48,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildDestination(
                                index,
                                (weights[index] - 1).clamp(0.0, 1.0).toDouble(),
                                scheme),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestination(int index, double expansion, ColorScheme scheme) {
    final destination = widget.destinations[index];
    final selected = index == widget.selectedIndex;
    final color = Color.lerp(
        scheme.onSurfaceVariant, scheme.onPrimaryContainer, expansion)!;
    return Semantics(
      label: destination.label,
      selected: selected,
      button: true,
      child: TextButton(
        onPressed: () {
          if (!selected) widget.onSelected(index);
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: color,
          backgroundColor: Color.lerp(
              scheme.primaryContainer.withValues(alpha: 0),
              scheme.primaryContainer,
              expansion),
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          shape: const StadiumBorder(),
        ).copyWith(
          // 颜色随宽度逐帧插值，避免按钮自己的隐式动画再次延迟。
          animationDuration: Duration.zero,
          side: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.focused)
                  ? BorderSide(color: scheme.primary, width: 1.5)
                  : BorderSide.none),
        ),
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: _animate
                      ? const Duration(milliseconds: 120)
                      : Duration.zero,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: color,
                  ),
                ),
                ClipRect(
                  child: Align(
                    widthFactor: expansion,
                    heightFactor: 1,
                    child: Opacity(
                      opacity: expansion,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            destination.label,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
