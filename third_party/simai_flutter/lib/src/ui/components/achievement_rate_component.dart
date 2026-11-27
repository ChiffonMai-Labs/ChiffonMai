import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../structures/mai_chart.dart';
import '../../structures/note.dart';
import '../../structures/note_styles.dart';
import '../../structures/note_type.dart';
import '../auto_play_mode.dart';
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

  /// 总判定事件数（用于判断是否抵达终值）。
  int get eventCount => _eventTimes.length;

  /// 本谱面理论满分达成率（含绝赞为 101%，无绝赞为 100%，空谱为 0%）。
  double get maxAchievement =>
      totalWeightedPoints == 0 ? 0.0 : (totalBreakCount > 0 ? 101.0 : 100.0);

  /// 指定已判定事件数对应的已过线绝赞数量。
  int judgedBreakCountAt(int judgedCount) => _breakCountPrefix[judgedCount];

  /// 查询指定谱面时间已过线的判定事件数。
  int judgedCountAt(double chartTime) => _judgedCountAt(chartTime);

  /// 根据已过线判定事件数计算 0%+ 模式达成率。
  double achievementForJudgedCount(int judgedCount) =>
      _achievementFor(judgedCount);

  /// 根据已过线绝赞数计算 100%+ 模式达成率。
  double achievement100PlusForBreakCount(int judgedBreakCount) {
    if (totalWeightedPoints == 0) return 100.0;
    final breakBonus =
        totalBreakCount == 0 ? 0.0 : judgedBreakCount / totalBreakCount;
    return 100.0 + breakBonus;
  }

  /// 判断模式是否属于百分比达成率类（用于受 `showAchievementRate` 开关控制）。
  static bool isPercentageAchievementMode(SimaiCenterDisplayMode mode) =>
      switch (mode) {
        SimaiCenterDisplayMode.achievementAdd ||
        SimaiCenterDisplayMode.achievement100Plus ||
        SimaiCenterDisplayMode.achievement101Subtract ||
        SimaiCenterDisplayMode.overS ||
        SimaiCenterDisplayMode.overSS ||
        SimaiCenterDisplayMode.overSSS => true,
        SimaiCenterDisplayMode.dxScoreAdd ||
        SimaiCenterDisplayMode.dxScoreSubtract ||
        SimaiCenterDisplayMode.dxStars ||
        SimaiCenterDisplayMode.combo ||
        SimaiCenterDisplayMode.none => false,
      };

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

  // 淡入淡出阶段改用颜色 alpha 调制的缓存画笔，彻底消除 canvas.saveLayer 离屏切换。
  TextStyle? _cachedLabelStyle;
  double _cachedOutlineStrokeWidth = 2.0;
  String _cachedMetricLabel = 'ACHIEVEMENT';
  int _lastAutoplayFadeAlpha = -1;
  TextPainter? _autoplayFadeOutlinePainter;
  TextPainter? _autoplayFadeFillPainter;
  int _lastMetricFadeAlpha = -1;
  TextPainter? _metricFadeOutlinePainter;
  TextPainter? _metricFadeFillPainter;

  int _lastMetricKey = -1;
  double _lastFontSize = -1;
  double _lastLabelFontSize = -1;
  SimaiCenterDisplayMode? _lastMode;
  SimaiAutoPlayMode? _lastAutoPlayMode;
  bool _wasVisible = false;
  double _labelElapsed = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _lastFontSize = -1;
  }

  @override
  void onRemove() {
    _disposeAllPainters();
    super.onRemove();
  }

  void _disposeFadePainters() {
    _autoplayFadeOutlinePainter?.dispose();
    _autoplayFadeFillPainter?.dispose();
    _metricFadeOutlinePainter?.dispose();
    _metricFadeFillPainter?.dispose();
    _autoplayFadeOutlinePainter = null;
    _autoplayFadeFillPainter = null;
    _metricFadeOutlinePainter = null;
    _metricFadeFillPainter = null;
    _lastAutoplayFadeAlpha = -1;
    _lastMetricFadeAlpha = -1;
  }

  void _disposeAllPainters() {
    _valueOutlinePainter?.dispose();
    _valueFillPainter?.dispose();
    _autoplayLabelOutlinePainter?.dispose();
    _autoplayLabelFillPainter?.dispose();
    _metricLabelOutlinePainter?.dispose();
    _metricLabelFillPainter?.dispose();
    _valueOutlinePainter = null;
    _valueFillPainter = null;
    _autoplayLabelOutlinePainter = null;
    _autoplayLabelFillPainter = null;
    _metricLabelOutlinePainter = null;
    _metricLabelFillPainter = null;
    _disposeFadePainters();
  }

  /// 判断模式是否属于百分比达成率类，用于受 `showAchievementRate` 开关控制。
  static bool _isPercentageAchievementMode(SimaiCenterDisplayMode mode) =>
      CriticalAchievementIndex.isPercentageAchievementMode(mode);

  bool _isHidden(SimaiCenterDisplayMode mode) =>
      mode == SimaiCenterDisplayMode.none ||
      (!game.showAchievementRate && _isPercentageAchievementMode(mode));

  static int _percentKey(double value) {
    final normalized = value.abs() < 0.00005 ? 0.0 : value;
    return (normalized * 10000.0).round();
  }

  /// 按当前显示模式的实际展示值生成增量键，避免 101- / BORDER / DX- 在 CP 音符过线时无意义重排。
  static int _displayValueKey(
    SimaiCenterDisplayMode mode,
    SimaiAutoPlaySnapshot snapshot,
  ) => switch (mode) {
    SimaiCenterDisplayMode.achievementAdd => _percentKey(
      snapshot.achievementAdd,
    ),
    SimaiCenterDisplayMode.achievement100Plus => _percentKey(
      snapshot.achievement100Plus,
    ),
    SimaiCenterDisplayMode.achievement101Subtract => _percentKey(
      snapshot.achievement101Subtract,
    ),
    SimaiCenterDisplayMode.overS => _percentKey(
      snapshot.achievement101Subtract - 97.0,
    ),
    SimaiCenterDisplayMode.overSS => _percentKey(
      snapshot.achievement101Subtract - 99.0,
    ),
    SimaiCenterDisplayMode.overSSS => _percentKey(
      snapshot.achievement101Subtract - 100.0,
    ),
    SimaiCenterDisplayMode.dxScoreAdd => snapshot.earnedDxScore,
    SimaiCenterDisplayMode.dxScoreSubtract ||
    SimaiCenterDisplayMode.dxStars => snapshot.remainingDxScore,
    SimaiCenterDisplayMode.combo => snapshot.combo,
    SimaiCenterDisplayMode.none => 0,
  };

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) {
      _labelElapsed = (_labelElapsed + dt) % _centerLabelCycleDuration;
    }
    final mode = game.centerDisplayMode;
    if (mode == SimaiCenterDisplayMode.none) {
      if (_wasVisible || _valueFillPainter != null) {
        _disposeAllPainters();
      }
      _wasVisible = false;
      _lastMode = mode;
      return;
    }
    if (!game.showAchievementRate && _isPercentageAchievementMode(mode)) {
      _wasVisible = false;
      return;
    }

    if (_lastMode != null && mode != _lastMode) {
      _labelElapsed = 0;
    }
    final autoPlayMode = game.autoPlayMode;
    final snapshot = game.autoPlayTimeline.snapshotAt(game.chartTime);
    final int metricKey = _displayValueKey(mode, snapshot);
    final minEdge = min(size.x, size.y);
    final fontSize = game.headlessExport
        ? (minEdge * 0.064).clamp(22.0, 68.0)
        : (minEdge * 0.055).clamp(18.0, 34.0);
    if (_wasVisible &&
        mode == _lastMode &&
        autoPlayMode == _lastAutoPlayMode &&
        metricKey == _lastMetricKey &&
        fontSize == _lastFontSize) {
      return;
    }

    final bool needsLabelRebuild =
        !_wasVisible ||
        mode != _lastMode ||
        fontSize != _lastLabelFontSize ||
        _autoplayLabelFillPainter == null ||
        _metricLabelFillPainter == null;

    _wasVisible = true;
    _lastMode = mode;
    _lastAutoPlayMode = autoPlayMode;
    _lastMetricKey = metricKey;
    _lastFontSize = fontSize;
    switch (mode) {
      case SimaiCenterDisplayMode.achievementAdd:
        _rebuildPercentagePainters(
          snapshot.achievementAdd,
          metricLabel: 'ACHIEVEMENT',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.achievement100Plus:
        _rebuildPercentagePainters(
          snapshot.achievement100Plus,
          metricLabel: 'ACHIEVEMENT',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.achievement101Subtract:
        _rebuildPercentagePainters(
          snapshot.achievement101Subtract,
          metricLabel: 'ACHIEVEMENT',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.dxScoreAdd:
        _rebuildPainters(
          integerText: snapshot.earnedDxScore.toString(),
          decimalText: '',
          metricLabel: 'DX SCORE',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.dxScoreSubtract:
        _rebuildPainters(
          integerText: snapshot.remainingDxScore.toString(),
          decimalText: '',
          metricLabel: 'DX SCORE',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.dxStars:
        _rebuildPainters(
          integerText: formatSimaiDxStarBonus(
            snapshot.remainingDxScore,
            snapshot.maxDxScore,
          ),
          decimalText: '',
          metricLabel: 'DX STAR',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.combo:
        _rebuildPainters(
          integerText: snapshot.combo.toString(),
          decimalText: '',
          metricLabel: 'COMBO',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.overS:
        _rebuildPercentagePainters(
          snapshot.achievement101Subtract - 97.0,
          metricLabel: 'S BORDER',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.overSS:
        _rebuildPercentagePainters(
          snapshot.achievement101Subtract - 99.0,
          metricLabel: 'SS BORDER',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.overSSS:
        _rebuildPercentagePainters(
          snapshot.achievement101Subtract - 100.0,
          metricLabel: 'SSS BORDER',
          fontSize: fontSize,
          rebuildLabels: needsLabelRebuild,
        );
      case SimaiCenterDisplayMode.none:
        break;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_isHidden(game.centerDisplayMode)) {
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
      isAutoplay: true,
      text: 'AUTOPLAY',
      outline: autoplayLabelOutline,
      fill: autoplayLabelFill,
      offset: autoplayOffset,
      opacity: opacity.autoplay,
    );
    _paintLabel(
      canvas,
      isAutoplay: false,
      text: _cachedMetricLabel,
      outline: metricLabelOutline,
      fill: metricLabelFill,
      offset: metricOffset,
      opacity: opacity.metric,
    );
    valueOutline.paint(canvas, valueOffset);
    valueFill.paint(canvas, valueOffset);
  }

  /// 用颜色 alpha 调制替代 canvas.saveLayer，避免淡入淡出过渡期触发离屏渲染目标切换。
  void _paintLabel(
    Canvas canvas, {
    required bool isAutoplay,
    required String text,
    required TextPainter outline,
    required TextPainter fill,
    required Offset offset,
    required double opacity,
  }) {
    if (opacity <= 0.001) {
      _clearFadeSlot(isAutoplay: isAutoplay);
      return;
    }
    if (opacity >= 0.999) {
      _clearFadeSlot(isAutoplay: isAutoplay);
      outline.paint(canvas, offset);
      fill.paint(canvas, offset);
      return;
    }

    final labelStyle = _cachedLabelStyle;
    if (labelStyle == null) return;
    final int alphaStep = (opacity * 255).round().clamp(1, 254);

    if (isAutoplay) {
      if (_lastAutoplayFadeAlpha != alphaStep ||
          _autoplayFadeOutlinePainter == null ||
          _autoplayFadeFillPainter == null) {
        _autoplayFadeOutlinePainter?.dispose();
        _autoplayFadeFillPainter?.dispose();
        final (nextOutline, nextFill) = _buildAlphaModulatedLabelPainters(
          text: text,
          labelStyle: labelStyle,
          opacity: opacity,
        );
        _autoplayFadeOutlinePainter = nextOutline;
        _autoplayFadeFillPainter = nextFill;
        _lastAutoplayFadeAlpha = alphaStep;
      }
      _autoplayFadeOutlinePainter!.paint(canvas, offset);
      _autoplayFadeFillPainter!.paint(canvas, offset);
    } else {
      if (_lastMetricFadeAlpha != alphaStep ||
          _metricFadeOutlinePainter == null ||
          _metricFadeFillPainter == null) {
        _metricFadeOutlinePainter?.dispose();
        _metricFadeFillPainter?.dispose();
        final (nextOutline, nextFill) = _buildAlphaModulatedLabelPainters(
          text: text,
          labelStyle: labelStyle,
          opacity: opacity,
        );
        _metricFadeOutlinePainter = nextOutline;
        _metricFadeFillPainter = nextFill;
        _lastMetricFadeAlpha = alphaStep;
      }
      _metricFadeOutlinePainter!.paint(canvas, offset);
      _metricFadeFillPainter!.paint(canvas, offset);
    }
  }

  void _clearFadeSlot({required bool isAutoplay}) {
    if (isAutoplay) {
      if (_autoplayFadeOutlinePainter != null ||
          _autoplayFadeFillPainter != null) {
        _autoplayFadeOutlinePainter?.dispose();
        _autoplayFadeFillPainter?.dispose();
        _autoplayFadeOutlinePainter = null;
        _autoplayFadeFillPainter = null;
        _lastAutoplayFadeAlpha = -1;
      }
    } else {
      if (_metricFadeOutlinePainter != null || _metricFadeFillPainter != null) {
        _metricFadeOutlinePainter?.dispose();
        _metricFadeFillPainter?.dispose();
        _metricFadeOutlinePainter = null;
        _metricFadeFillPainter = null;
        _lastMetricFadeAlpha = -1;
      }
    }
  }

  (TextPainter, TextPainter) _buildAlphaModulatedLabelPainters({
    required String text,
    required TextStyle labelStyle,
    required double opacity,
  }) {
    final outlinePaint = Paint()
      ..color = Colors.black.withAlpha((150 * opacity).round().clamp(0, 255))
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cachedOutlineStrokeWidth
      ..strokeJoin = StrokeJoin.round;
    final outline = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(foreground: outlinePaint),
      ),
    )..layout();
    final fill = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(
          color: Colors.white.withAlpha((180 * opacity).round().clamp(0, 255)),
        ),
      ),
    )..layout();
    return (outline, fill);
  }

  void _rebuildPercentagePainters(
    double value, {
    required String metricLabel,
    required double fontSize,
    required bool rebuildLabels,
  }) {
    final normalized = value.abs() < 0.00005 ? 0.0 : value;
    final fixed = normalized.toStringAsFixed(4);
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
      metricLabel: metricLabel,
      fontSize: fontSize,
      rebuildLabels: rebuildLabels,
    );
  }

  void _rebuildPainters({
    required String integerText,
    required String decimalText,
    required String metricLabel,
    required double fontSize,
    required bool rebuildLabels,
  }) {
    final decimalFontSize = fontSize * 0.82;
    final labelFontSize = game.headlessExport
        ? (fontSize * 0.30).clamp(10.0, 22.0)
        : (fontSize * 0.38).clamp(9.0, 13.0);
    final strokeWidth = max(2.0, fontSize * 0.08);
    final outlinePaint = Paint()
      ..color = Colors.black.withAlpha(150)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
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

    _valueOutlinePainter?.dispose();
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

    _valueFillPainter?.dispose();
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

    if (!rebuildLabels) return;

    final labelStyle = game.withDisplayFont(
      TextStyle(
        fontSize: labelFontSize,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
    _cachedLabelStyle = labelStyle;
    _cachedOutlineStrokeWidth = strokeWidth;
    _cachedMetricLabel = metricLabel;
    _lastLabelFontSize = fontSize;
    _disposeFadePainters();

    _autoplayLabelOutlinePainter?.dispose();
    _autoplayLabelOutlinePainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'AUTOPLAY',
        style: labelStyle.copyWith(foreground: outlinePaint),
      ),
    )..layout();

    _autoplayLabelFillPainter?.dispose();
    _autoplayLabelFillPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'AUTOPLAY',
        style: labelStyle.copyWith(color: Colors.white.withAlpha(180)),
      ),
    )..layout();

    _metricLabelOutlinePainter?.dispose();
    _metricLabelOutlinePainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: metricLabel,
        style: labelStyle.copyWith(foreground: outlinePaint),
      ),
    )..layout();

    _metricLabelFillPainter?.dispose();
    _metricLabelFillPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: metricLabel,
        style: labelStyle.copyWith(color: Colors.white.withAlpha(180)),
      ),
    )..layout();
  }
}
