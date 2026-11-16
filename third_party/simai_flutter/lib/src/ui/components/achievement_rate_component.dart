import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../structures/mai_chart.dart';
import '../../structures/note.dart';
import '../../structures/note_styles.dart';
import '../../structures/note_type.dart';
import '../center_display_mode.dart';
import '../simai_game.dart';

class CriticalAchievementSnapshot {
  final double achievement;
  final int judgedCount;
  final int judgedWeightedPoints;
  final int judgedBreakCount;

  const CriticalAchievementSnapshot({
    required this.achievement,
    required this.judgedCount,
    required this.judgedWeightedPoints,
    required this.judgedBreakCount,
  });
}

class _CriticalAchievementEvent {
  final double time;
  final int weight;
  final bool isBreak;

  const _CriticalAchievementEvent({
    required this.time,
    required this.weight,
    required this.isBreak,
  });
}

class CenterLabelOpacity {
  final double autoplay;
  final double metric;

  const CenterLabelOpacity({required this.autoplay, required this.metric});
}

const double _centerLabelHoldDuration = 4.7;
const double _centerLabelTransitionDuration = 0.3;
const double _centerLabelCycleDuration = 10.0;

@visibleForTesting
CenterLabelOpacity centerLabelOpacityAt(double elapsed) {
  const halfCycle = _centerLabelHoldDuration + _centerLabelTransitionDuration;
  final safeElapsed = elapsed.isFinite && elapsed >= 0 ? elapsed : 0.0;
  final phase = safeElapsed % _centerLabelCycleDuration;

  if (phase < _centerLabelHoldDuration) {
    return const CenterLabelOpacity(autoplay: 1, metric: 0);
  }
  if (phase < halfCycle) {
    final progress = Curves.easeInOutCubic.transform(
      (phase - _centerLabelHoldDuration) / _centerLabelTransitionDuration,
    );
    return CenterLabelOpacity(autoplay: 1 - progress, metric: progress);
  }
  if (phase < halfCycle + _centerLabelHoldDuration) {
    return const CenterLabelOpacity(autoplay: 0, metric: 1);
  }

  final progress = Curves.easeInOutCubic.transform(
    (phase - halfCycle - _centerLabelHoldDuration) /
        _centerLabelTransitionDuration,
  );
  return CenterLabelOpacity(autoplay: progress, metric: 1 - progress);
}

/// Precomputed Critical-only achievement timeline following AstroDX's
/// AchievementStats weights and Break bonus calculation.
class CriticalAchievementIndex {
  final List<double> _eventTimes;
  final List<int> _weightedPointPrefix;
  final List<int> _breakCountPrefix;

  final int totalWeightedPoints;
  final int totalBreakCount;

  const CriticalAchievementIndex._({
    required List<double> eventTimes,
    required List<int> weightedPointPrefix,
    required List<int> breakCountPrefix,
    required this.totalWeightedPoints,
    required this.totalBreakCount,
  }) : _eventTimes = eventTimes,
       _weightedPointPrefix = weightedPointPrefix,
       _breakCountPrefix = breakCountPrefix;

  factory CriticalAchievementIndex.build(MaiChart chart) {
    final events = <_CriticalAchievementEvent>[];

    for (final collection in chart.noteCollections) {
      final headTime = _finiteOrZero(collection.time);
      for (final note in collection) {
        final head = _headEvent(note, headTime);
        if (head != null) events.add(head);

        for (final path in note.slidePaths) {
          final isBreak = path.type == NoteType.breakNote;
          events.add(
            _CriticalAchievementEvent(
              time: _finiteOrZero(
                headTime +
                    _nonNegativeFinite(path.delay) +
                    _nonNegativeFinite(path.duration),
              ),
              weight: isBreak ? 5 : 3,
              isBreak: isBreak,
            ),
          );
        }
      }
    }

    events.sort((a, b) => a.time.compareTo(b.time));
    final eventTimes = <double>[];
    final weightedPointPrefix = <int>[0];
    final breakCountPrefix = <int>[0];

    for (final event in events) {
      eventTimes.add(event.time);
      weightedPointPrefix.add(weightedPointPrefix.last + event.weight);
      breakCountPrefix.add(breakCountPrefix.last + (event.isBreak ? 1 : 0));
    }

    return CriticalAchievementIndex._(
      eventTimes: List.unmodifiable(eventTimes),
      weightedPointPrefix: List.unmodifiable(weightedPointPrefix),
      breakCountPrefix: List.unmodifiable(breakCountPrefix),
      totalWeightedPoints: weightedPointPrefix.last,
      totalBreakCount: breakCountPrefix.last,
    );
  }

  CriticalAchievementSnapshot at(double chartTime) {
    final judgedCount = _judgedCountAt(chartTime);
    final judgedWeightedPoints = _weightedPointPrefix[judgedCount];
    final judgedBreakCount = _breakCountPrefix[judgedCount];

    return CriticalAchievementSnapshot(
      achievement: _achievementFor(judgedCount),
      judgedCount: judgedCount,
      judgedWeightedPoints: judgedWeightedPoints,
      judgedBreakCount: judgedBreakCount,
    );
  }

  double achievementAt(double chartTime) {
    return _achievementFor(_judgedCountAt(chartTime));
  }

  int _judgedCountAt(double chartTime) {
    return _upperBound(_eventTimes, chartTime.isFinite ? chartTime : 0.0);
  }

  double _achievementFor(int judgedCount) {
    final judgedWeightedPoints = _weightedPointPrefix[judgedCount];
    final judgedBreakCount = _breakCountPrefix[judgedCount];
    final baseAchievement = totalWeightedPoints == 0
        ? 0.0
        : judgedWeightedPoints * 100.0 / totalWeightedPoints;
    final breakBonus = totalBreakCount == 0
        ? 0.0
        : judgedBreakCount / totalBreakCount;
    return baseAchievement + breakBonus;
  }

  static _CriticalAchievementEvent? _headEvent(Note note, double headTime) {
    if (note.type == NoteType.forceInvalidate) return null;

    final isBreak =
        note.type == NoteType.breakNote ||
        (note.styles & NoteStyles.breakHead) != 0;
    final isHold = note.type == NoteType.hold || note.length != null;
    final weight = isBreak ? 5 : (isHold ? 2 : 1);
    final judgementTime = isHold
        ? headTime + _nonNegativeFinite(note.length ?? 0.0)
        : headTime;

    return _CriticalAchievementEvent(
      time: _finiteOrZero(judgementTime),
      weight: weight,
      isBreak: isBreak,
    );
  }

  static double _finiteOrZero(double value) => value.isFinite ? value : 0.0;

  static double _nonNegativeFinite(double value) {
    if (!value.isFinite || value <= 0) return 0.0;
    return value;
  }

  static int _upperBound(List<double> values, double target) {
    int low = 0;
    int high = values.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (values[mid] <= target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

class AchievementRateComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  AchievementRateComponent(this.index, {required this.comboAt});

  final CriticalAchievementIndex index;
  final int Function(double chartTime) comboAt;

  TextPainter? _valueOutlinePainter;
  TextPainter? _valueFillPainter;
  TextPainter? _autoplayLabelOutlinePainter;
  TextPainter? _autoplayLabelFillPainter;
  TextPainter? _metricLabelOutlinePainter;
  TextPainter? _metricLabelFillPainter;
  int _lastMetricKey = -1;
  double _lastFontSize = -1;
  SimaiCenterDisplayMode? _lastMode;
  bool _wasVisible = false;
  double _labelElapsed = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _lastFontSize = -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) {
      _labelElapsed = (_labelElapsed + dt) % _centerLabelCycleDuration;
    }
    final mode = game.centerDisplayMode;
    if (mode == SimaiCenterDisplayMode.achievement &&
        !game.showAchievementRate) {
      _wasVisible = false;
      return;
    }

    if (_lastMode != null && mode != _lastMode) {
      _labelElapsed = 0;
    }
    final metricKey = mode == SimaiCenterDisplayMode.achievement
        ? index._judgedCountAt(game.chartTime)
        : comboAt(game.chartTime);
    final fontSize = (min(size.x, size.y) * 0.055).clamp(18.0, 34.0);
    if (_wasVisible &&
        mode == _lastMode &&
        metricKey == _lastMetricKey &&
        fontSize == _lastFontSize) {
      return;
    }

    _wasVisible = true;
    _lastMode = mode;
    _lastMetricKey = metricKey;
    _lastFontSize = fontSize;
    if (mode == SimaiCenterDisplayMode.achievement) {
      _rebuildAchievementPainters(index._achievementFor(metricKey), fontSize);
    } else {
      _rebuildPainters(
        integerText: metricKey.toString(),
        decimalText: '',
        metricLabel: 'COMBO',
        fontSize: fontSize,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.centerDisplayMode == SimaiCenterDisplayMode.achievement &&
        !game.showAchievementRate) {
      return;
    }
    final valueFill = _valueFillPainter;
    final valueOutline = _valueOutlinePainter;
    final autoplayLabelFill = _autoplayLabelFillPainter;
    final autoplayLabelOutline = _autoplayLabelOutlinePainter;
    final metricLabelFill = _metricLabelFillPainter;
    final metricLabelOutline = _metricLabelOutlinePainter;
    if (valueFill == null ||
        valueOutline == null ||
        autoplayLabelFill == null ||
        autoplayLabelOutline == null ||
        metricLabelFill == null ||
        metricLabelOutline == null) {
      return;
    }

    final valueOffset = Offset(
      (size.x - valueFill.width) / 2,
      (size.y - valueFill.height) / 2,
    );
    final labelBottom = valueOffset.dy - max(2.0, _lastFontSize * 0.08);
    final autoplayOffset = Offset(
      (size.x - autoplayLabelFill.width) / 2,
      labelBottom - autoplayLabelFill.height,
    );
    final metricOffset = Offset(
      (size.x - metricLabelFill.width) / 2,
      labelBottom - metricLabelFill.height,
    );
    final opacity = centerLabelOpacityAt(_labelElapsed);
    _paintLabel(
      canvas,
      outline: autoplayLabelOutline,
      fill: autoplayLabelFill,
      offset: autoplayOffset,
      opacity: opacity.autoplay,
    );
    _paintLabel(
      canvas,
      outline: metricLabelOutline,
      fill: metricLabelFill,
      offset: metricOffset,
      opacity: opacity.metric,
    );
    valueOutline.paint(canvas, valueOffset);
    valueFill.paint(canvas, valueOffset);
  }

  void _paintLabel(
    Canvas canvas, {
    required TextPainter outline,
    required TextPainter fill,
    required Offset offset,
    required double opacity,
  }) {
    if (opacity <= 0.001) return;
    if (opacity >= 0.999) {
      outline.paint(canvas, offset);
      fill.paint(canvas, offset);
      return;
    }

    final bounds = Rect.fromLTWH(
      offset.dx - 4,
      offset.dy - 4,
      max(outline.width, fill.width) + 8,
      max(outline.height, fill.height) + 8,
    );
    canvas.saveLayer(
      bounds,
      Paint()..color = Colors.white.withAlpha((opacity * 255).round()),
    );
    outline.paint(canvas, offset);
    fill.paint(canvas, offset);
    canvas.restore();
  }

  void _rebuildAchievementPainters(double achievement, double fontSize) {
    final fixed = achievement.toStringAsFixed(4);
    final decimalIndex = fixed.indexOf('.');
    final integerText = decimalIndex == -1
        ? fixed
        : fixed.substring(0, decimalIndex);
    final decimalText = decimalIndex == -1
        ? '%'
        : '${fixed.substring(decimalIndex)}%';
    _rebuildPainters(
      integerText: integerText,
      decimalText: decimalText,
      metricLabel: 'ACHIEVEMENT',
      fontSize: fontSize,
    );
  }

  void _rebuildPainters({
    required String integerText,
    required String decimalText,
    required String metricLabel,
    required double fontSize,
  }) {
    final decimalFontSize = fontSize * 0.82;
    final labelFontSize = (fontSize * 0.38).clamp(9.0, 13.0);
    final outlinePaint = Paint()
      ..color = Colors.black.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(2.0, fontSize * 0.08)
      ..strokeJoin = StrokeJoin.round;
    final integerStyle = game.withDisplayFont(
      TextStyle(
        fontSize: fontSize,
        height: 1,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final decimalStyle = integerStyle.copyWith(
      fontSize: decimalFontSize,
      fontWeight: FontWeight.w700,
    );
    final labelStyle = game.withDisplayFont(
      TextStyle(
        fontSize: labelFontSize,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );

    _valueOutlinePainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        children: [
          TextSpan(
            text: integerText,
            style: integerStyle.copyWith(foreground: outlinePaint),
          ),
          if (decimalText.isNotEmpty)
            TextSpan(
              text: decimalText,
              style: decimalStyle.copyWith(foreground: outlinePaint),
            ),
        ],
      ),
    )..layout();
    _valueFillPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        children: [
          TextSpan(
            text: integerText,
            style: integerStyle.copyWith(color: Colors.white.withAlpha(215)),
          ),
          if (decimalText.isNotEmpty)
            TextSpan(
              text: decimalText,
              style: decimalStyle.copyWith(color: Colors.white.withAlpha(215)),
            ),
        ],
      ),
    )..layout();
    _autoplayLabelOutlinePainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'AUTOPLAY',
        style: labelStyle.copyWith(foreground: outlinePaint),
      ),
    )..layout();
    _autoplayLabelFillPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'AUTOPLAY',
        style: labelStyle.copyWith(color: Colors.white.withAlpha(180)),
      ),
    )..layout();
    _metricLabelOutlinePainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: metricLabel,
        style: labelStyle.copyWith(foreground: outlinePaint),
      ),
    )..layout();
    _metricLabelFillPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: metricLabel,
        style: labelStyle.copyWith(color: Colors.white.withAlpha(180)),
      ),
    )..layout();
  }
}
