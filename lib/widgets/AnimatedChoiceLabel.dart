import 'package:flutter/material.dart';

/// 可平铺的单选标签：背景从左向右展开，取消选中时反向收回。
class AnimatedChoiceLabel extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color unselectedColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final Color? borderColor;
  final Color? selectedBorderColor;
  final double borderWidth;
  final double radius;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;

  const AnimatedChoiceLabel({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.unselectedColor = Colors.transparent,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.borderColor,
    this.selectedBorderColor,
    this.borderWidth = 1,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    this.textStyle,
  });

  @override
  State<AnimatedChoiceLabel> createState() => _AnimatedChoiceLabelState();
}

class _AnimatedChoiceLabelState extends State<AnimatedChoiceLabel>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 260);
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
      value: widget.selected ? 1 : 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    _controller.duration = disableAnimations ? Duration.zero : _duration;
    if (disableAnimations) _controller.value = widget.selected ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant AnimatedChoiceLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected) return;
    if (_controller.duration == Duration.zero) {
      _controller.value = widget.selected ? 1 : 0;
    } else if (widget.selected) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final borderRadius = BorderRadius.circular(widget.radius);
    final duration =
        MediaQuery.disableAnimationsOf(context) ? Duration.zero : _duration;
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          onTap: () {
            if (!widget.selected) widget.onTap();
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeOutCubic.transform(_controller.value);
              return ClipRRect(
                borderRadius: borderRadius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.unselectedColor,
                    border: Border.all(
                      color: widget.selected
                          ? (widget.selectedBorderColor ??
                              widget.borderColor ??
                              scheme.primary)
                          : (widget.borderColor ?? scheme.outlineVariant),
                      width: widget.borderWidth,
                    ),
                    borderRadius: borderRadius,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: progress,
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.selectedColor ??
                                    scheme.primaryContainer,
                                borderRadius: borderRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: widget.padding,
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          style: theme.textTheme.labelLarge!
                              .merge(widget.textStyle)
                              .copyWith(
                                color: widget.selected
                                    ? (widget.selectedTextColor ??
                                        scheme.onPrimaryContainer)
                                    : (widget.unselectedTextColor ??
                                        scheme.onSurfaceVariant),
                                fontWeight: widget.textStyle?.fontWeight ??
                                    (widget.selected
                                        ? FontWeight.bold
                                        : FontWeight.w500),
                              ),
                          child: Text(widget.label),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
