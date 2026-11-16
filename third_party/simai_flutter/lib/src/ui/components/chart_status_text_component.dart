import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../chart_timing_mapper.dart';
import '../simai_game.dart';

@visibleForTesting
String? buildChartPerformanceText({
  required bool showFps,
  required bool showDetailedPerformanceInfo,
  required double measuredFps,
  required double frameIntervalP95Ms,
  required double motionStepP95Ms,
  required double frozenFrameRatio,
}) {
  if (!showFps) return null;
  if (!showDetailedPerformanceInfo) {
    return 'FPS ${measuredFps.toStringAsFixed(1)}';
  }
  return 'FPS ${measuredFps.toStringAsFixed(1)}  '
      'P95 ${frameIntervalP95Ms.toStringAsFixed(1)}ms  '
      'Move ${motionStepP95Ms.toStringAsFixed(1)}ms  '
      'Frozen ${(frozenFrameRatio * 100).toStringAsFixed(0)}%';
}

/// Controls the short color pulse shown when the active chart BPM changes.
class BpmIndicatorColorTransition {
  static const Color idleColor = Colors.white70;
  static const Color increasedColor = Color(0xFFFF8A65);
  static const Color decreasedColor = Color(0xFF64B5F6);
  static const double holdDuration = 0.5;
  static const double recoveryDuration = 1.5;

  double _elapsed = holdDuration + recoveryDuration;
  Color _accent = idleColor;

  void trigger({required bool increased}) {
    _accent = increased ? increasedColor : decreasedColor;
    _elapsed = 0.0;
  }

  void update(double dt) {
    _elapsed = (_elapsed + dt).clamp(0.0, holdDuration + recoveryDuration);
  }

  Color get color {
    if (_elapsed <= holdDuration) return _accent;
    final progress = Curves.easeOutCubic.transform(
      ((_elapsed - holdDuration) / recoveryDuration).clamp(0.0, 1.0),
    );
    return Color.lerp(_accent, idleColor, progress)!;
  }
}

class ChartStatusTextComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  ChartStatusTextComponent({super.position});

  static const TextStyle _baseStyle = TextStyle(
    color: BpmIndicatorColorTransition.idleColor,
    fontSize: 13,
    height: 0.9,
    fontWeight: FontWeight.bold,
  );

  final BpmIndicatorColorTransition _bpmColor = BpmIndicatorColorTransition();
  TextPainter? _painter;
  double? _displayedBpm;
  double _refreshElapsed = 0.25;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(8, 0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bpmColor.update(dt);
    _refreshElapsed += dt;

    // Refresh promptly enough that the pulse starts at the timing boundary.
    if (_refreshElapsed >= 1 / 30 || _painter == null) {
      _refreshElapsed = 0.0;
      _refreshText();
    } else if (_bpmColor.color != BpmIndicatorColorTransition.idleColor) {
      _rebuildPainter();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.showCornerInfo) return;
    _painter?.paint(canvas, Offset.zero);
  }

  void _refreshText() {
    final timing = ChartTimingMapper.timingAtTime(game.chart, game.chartTime);
    final bpm = timing.tempo;
    final previousBpm = _displayedBpm;
    if (previousBpm != null && (bpm - previousBpm).abs() > 0.0001) {
      _bpmColor.trigger(increased: bpm > previousBpm);
    }
    _displayedBpm = bpm;
    _rebuildPainter();
  }

  void _rebuildPainter() {
    final bpm = _displayedBpm;
    if (bpm == null) return;
    final timing = ChartTimingMapper.timingAtTime(game.chart, game.chartTime);
    final denom = timing.subdivisions.round().clamp(1, 1024);
    final measure = _measureNumberAt(game.chartTime);
    final progress = _quarterProgressCodeAt(game.chartTime);
    final performanceText = buildChartPerformanceText(
      showFps: game.showFps,
      showDetailedPerformanceInfo: game.showDetailedPerformanceInfo,
      measuredFps: game.measuredFps,
      frameIntervalP95Ms: game.frameIntervalP95Ms,
      motionStepP95Ms: game.motionStepP95Ms,
      frozenFrameRatio: game.frozenFrameRatio,
    );
    final statusText = StringBuffer('  M$measure  $progress  [1/$denom]');
    if (performanceText != null) {
      statusText
        ..write('\n')
        ..write(performanceText);
    }

    final baseStyle = game.withDisplayFont(_baseStyle);
    _painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: 'BPM ${bpm.toStringAsFixed(1)}',
            style: baseStyle.copyWith(color: _bpmColor.color),
          ),
          TextSpan(text: statusText.toString()),
        ],
      ),
    )..layout();
    size = Vector2(_painter!.width, _painter!.height);
  }

  double _beatsAt(double time) =>
      ChartTimingMapper.beatsAtTime(game.chart, time);

  int _measureNumberAt(double time) => (_beatsAt(time) / 4.0).floor() + 1;

  String _quarterProgressCodeAt(double time) {
    final beats = _beatsAt(time);
    final beatInMeasure = (beats - (beats / 4.0).floorToDouble() * 4.0).clamp(
      0.0,
      3.999999,
    );
    final beatIndex = beatInMeasure.floor().clamp(0, 3) + 1;
    final local = beatInMeasure - (beatIndex - 1);
    final pct = (local * 100).floor().clamp(0, 99);
    return '$beatIndex.${pct.toString().padLeft(2, '0')}';
  }
}
