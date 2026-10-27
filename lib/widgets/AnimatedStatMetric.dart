import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/AppTheme.dart';

/// 共用统计数值与趋势动画；增减沿用自动同步的配色和上下浮动箭头。
class AnimatedStatMetric extends StatefulWidget {
  const AnimatedStatMetric(
      {super.key,
      required this.value,
      required this.label,
      required this.revision,
      this.loading = false,
      this.active = false,
      this.animateValue = true,
      this.fractionDigits = 0,
      this.suffix = '',
      this.labelLeading,
      this.labelSpacing = 3,
      this.valueStyle,
      this.valueBuilder,
      this.semanticValue,
      this.increaseIsPositive = false,
      this.trendDuration});

  final num? value;
  final int fractionDigits;
  final String suffix;
  final TextStyle? valueStyle;
  final Widget Function(double value)? valueBuilder;
  final String? semanticValue;

  /// 剩余次数增加代表改善；默认保持原统计项的趋势配色。
  final bool increaseIsPositive;
  final Duration? trendDuration;
  final String label;
  final Widget? labelLeading;
  final double labelSpacing;
  final int revision;
  final bool active;
  final bool animateValue;
  final bool loading;

  @override
  State<AnimatedStatMetric> createState() => _AnimatedStatMetricState();
}

class _AnimatedStatMetricState extends State<AnimatedStatMetric>
    with TickerProviderStateMixin {
  late final AnimationController _numberController;
  late final AnimationController _arrowController;
  late Tween<double> _numberTween;
  Timer? _trendTimer;
  int _direction = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400), value: 1);
    _arrowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _numberTween = Tween<double>(
        begin: widget.value?.toDouble() ?? 0,
        end: widget.value?.toDouble() ?? 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.loading) {
      _syncLoadingAnimation();
      return;
    }
    if (_reduceMotion) {
      _numberController.value = 1;
      _stopArrow();
    }
  }

  @override
  void didUpdateWidget(AnimatedStatMetric oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading) {
      _syncLoadingAnimation();
      return;
    }
    if (oldWidget.loading || oldWidget.value == null || widget.value == null) {
      _numberController.stop();
      _numberTween = Tween<double>(
          begin: widget.value?.toDouble() ?? 0,
          end: widget.value?.toDouble() ?? 0);
      _numberController.value = 1;
      _stopArrow();
      return;
    }
    if (widget.value != oldWidget.value) {
      // 新结果到来时从当前显示值继续计数，避免动画中途跳回旧目标。
      final current = _numberTween.evaluate(_numberController);
      _numberTween = Tween<double>(
          begin: widget.animateValue ? current : widget.value!.toDouble(),
          end: widget.value!.toDouble());
      if (_reduceMotion) {
        _numberController.value = 1;
        _stopArrow();
      } else {
        if (widget.animateValue) {
          _numberController.duration = Duration(
              milliseconds: ((widget.value! - current).abs() * 80)
                  .clamp(240, 600)
                  .round());
          _numberController.forward(from: 0);
        } else {
          _numberController.stop();
          _numberController.value = 1;
        }
        _direction = widget.value! > oldWidget.value! ? 1 : -1;
        _arrowController.repeat();
        _trendTimer?.cancel();
        if (widget.trendDuration case final Duration duration) {
          _trendTimer = Timer(duration, () {
            if (mounted) setState(_stopArrow);
          });
        }
      }
    } else if (widget.revision != oldWidget.revision) {
      _stopArrow();
    }
  }

  void _syncLoadingAnimation() {
    _stopArrow();
    if (_reduceMotion) {
      _numberController.stop();
      _numberController.value = 1;
    } else if (!_numberController.isAnimating) {
      _numberController.repeat(
          reverse: true, period: const Duration(milliseconds: 850));
    }
  }

  void _stopArrow() {
    _trendTimer?.cancel();
    _direction = 0;
    _arrowController.stop();
    _arrowController.reset();
  }

  @override
  void dispose() {
    _trendTimer?.cancel();
    _numberController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  String _format(double value) => widget.fractionDigits == 0
      ? '${value.round()}'
      : value.toStringAsFixed(widget.fractionDigits);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = Text(widget.label,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        label: widget.loading
            ? '${widget.label}，加载中'
            : '${widget.label} ${widget.semanticValue ?? widget.value ?? '暂不可用'}${_direction > 0 ? '，增加' : _direction < 0 ? '，减少' : ''}',
        excludeSemantics: true,
        child: Row(children: [
          Flexible(
              child: AnimatedBuilder(
            animation: _numberController,
            builder: (context, _) => SizedBox(
              height: MediaQuery.textScalerOf(context).scale(32),
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: 1,
                child: widget.loading
                    ? Opacity(
                        opacity: 0.35 + _numberController.value * 0.4,
                        child: Container(
                          width: 42,
                          height: 22,
                          decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant,
                              borderRadius: BorderRadius.circular(5)),
                        ))
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: widget.valueBuilder?.call(
                                _numberTween.evaluate(_numberController)) ??
                            Text(
                              widget.value == null
                                  ? '—'
                                  : '${_format(_numberTween.evaluate(_numberController))}${widget.suffix}',
                              style: (widget.valueStyle ??
                                      theme.textTheme.headlineSmall)
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: widget.active
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                      ),
              ),
            ),
          )),
          // 保留箭头位置，趋势出现和消失时不挤动数字。
          SizedBox(
              width: widget.valueStyle == null ? 23 : 20,
              height: 28,
              child: _direction == 0
                  ? null
                  : AnimatedBuilder(
                      animation: _arrowController,
                      builder: (context, _) => Transform.translate(
                        offset: Offset(
                            0,
                            -_direction *
                                (Curves.easeInOut
                                            .transform(_arrowController.value) *
                                        4 -
                                    2)),
                        child: Icon(
                            _direction > 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 18,
                            color: (_direction > 0) == widget.increaseIsPositive
                                ? AppColors.successForeground(theme.brightness)
                                : AppColors.errorRed(theme.brightness)),
                      ),
                    )),
        ]),
      ),
      SizedBox(height: widget.labelSpacing),
      if (widget.labelLeading == null)
        label
      else
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            ExcludeSemantics(child: widget.labelLeading!),
            const SizedBox(width: 3),
            label,
          ]),
        ),
    ]);
  }
}
