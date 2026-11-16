import 'dart:math';

import 'package:flutter/material.dart';

import '../../gameplay/gameplay_models.dart';

const double simaiJudgementFeedbackDuration = 0.50;

class SimaiJudgementLine {
  const SimaiJudgementLine({required this.text, required this.color});

  final String text;
  final Color color;
}

class SimaiJudgementAnimationState {
  const SimaiJudgementAnimationState({
    required this.opacity,
    required this.scale,
  });

  final double opacity;
  final double scale;

  bool get visible => opacity > 0.001;
}

class SimaiArcGlyphPlacement {
  const SimaiArcGlyphPlacement({required this.angle, required this.rotation});

  final double angle;
  final double rotation;
}

List<SimaiArcGlyphPlacement> simaiArcGlyphLayout({
  required List<double> advances,
  required double centerAngle,
  required double radius,
  required bool clockwise,
}) {
  if (advances.isEmpty || !radius.isFinite || radius <= 0) {
    return const <SimaiArcGlyphPlacement>[];
  }
  final safeAdvances = advances
      .map((advance) => advance.isFinite ? max(0.0, advance) : 0.0)
      .toList(growable: false);
  final totalAdvance = safeAdvances.fold<double>(
    0.0,
    (sum, value) => sum + value,
  );
  final direction = clockwise ? 1.0 : -1.0;
  var cursor = -totalAdvance / 2;
  return <SimaiArcGlyphPlacement>[
    for (final advance in safeAdvances)
      (() {
        final angle = centerAngle + direction * (cursor + advance / 2) / radius;
        cursor += advance;
        return SimaiArcGlyphPlacement(
          angle: angle,
          rotation: angle + (clockwise ? pi / 2 : -pi / 2),
        );
      })(),
  ];
}

SimaiJudgementAnimationState simaiJudgementAnimationAt(double age) {
  if (!age.isFinite || age < 0 || age >= simaiJudgementFeedbackDuration) {
    return const SimaiJudgementAnimationState(opacity: 0, scale: 1);
  }
  const enterDuration = 0.10;
  const fadeStart = 0.30;
  if (age < enterDuration) {
    final progress = Curves.easeOutCubic.transform(age / enterDuration);
    return SimaiJudgementAnimationState(
      opacity: progress,
      scale: 1.0 + 0.55 * (1.0 - progress),
    );
  }
  if (age <= fadeStart) {
    return const SimaiJudgementAnimationState(opacity: 1, scale: 1);
  }
  final progress =
      ((age - fadeStart) / (simaiJudgementFeedbackDuration - fadeStart)).clamp(
        0.0,
        1.0,
      );
  return SimaiJudgementAnimationState(
    opacity: 1.0 - Curves.easeInQuad.transform(progress),
    scale: 1,
  );
}

class SimaiJudgementPresentation {
  const SimaiJudgementPresentation({this.gradeLine, this.timingLine});

  final SimaiJudgementLine? gradeLine;
  final SimaiJudgementLine? timingLine;

  String? get text {
    final values = lines(timingFirst: true);
    return values.isEmpty ? null : values.map((line) => line.text).join(' ');
  }

  Color get color =>
      gradeLine?.color ?? timingLine?.color ?? Colors.transparent;

  List<SimaiJudgementLine> lines({required bool timingFirst}) {
    final grade = gradeLine;
    final timing = timingLine;
    if (grade == null && timing == null) return const <SimaiJudgementLine>[];
    if (grade == null) return <SimaiJudgementLine>[timing!];
    if (timing == null) return <SimaiJudgementLine>[grade];
    return timingFirst
        ? <SimaiJudgementLine>[timing, grade]
        : <SimaiJudgementLine>[grade, timing];
  }

  static SimaiJudgementPresentation forRecord(
    SimaiJudgementRecord record,
    SimaiJudgementDisplayMode mode,
  ) {
    final allowsTiming = _allowsTiming(record, mode);
    final timingText = switch (record.timing) {
      SimaiJudgeTiming.fast => 'FAST',
      SimaiJudgeTiming.late => 'LATE',
      SimaiJudgeTiming.none => null,
    };
    final gradeText = _gradeText(record, mode);
    final gradeColor = _gradeColor(record.grade);
    final timingColor = switch (record.timing) {
      SimaiJudgeTiming.fast => const Color(0xFF42A5F5),
      SimaiJudgeTiming.late => const Color(0xFFEF5350),
      SimaiJudgeTiming.none => gradeColor,
    };
    final visibleTiming = allowsTiming ? timingText : null;
    final showsCritical = gradeText == 'CRITICAL PERFECT';

    // Critical occupies the same visual row as FAST/LATE while PERFECT stays
    // on the grade row. Variant D still hides C-Perfect as documented.
    if (showsCritical && mode.variant != 'D') {
      return SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(text: 'PERFECT', color: gradeColor),
        timingLine: SimaiJudgementLine(text: 'CRITICAL', color: gradeColor),
      );
    }

    return switch (mode.variant) {
      'A' => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(text: gradeText, color: gradeColor),
      ),
      'B' || 'E' => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(text: gradeText, color: gradeColor),
        timingLine: visibleTiming == null
            ? null
            : SimaiJudgementLine(text: visibleTiming, color: gradeColor),
      ),
      'C' => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(
          text: gradeText,
          color: visibleTiming == null ? gradeColor : timingColor,
        ),
      ),
      'D' => SimaiJudgementPresentation(
        timingLine: visibleTiming == null
            ? null
            : SimaiJudgementLine(text: visibleTiming, color: timingColor),
      ),
      _ => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(text: gradeText, color: gradeColor),
      ),
    };
  }

  static bool _allowsTiming(
    SimaiJudgementRecord record,
    SimaiJudgementDisplayMode mode,
  ) {
    if (record.timing == SimaiJudgeTiming.none) return false;
    if (record.grade == SimaiJudgeGrade.great ||
        record.grade == SimaiJudgeGrade.good) {
      return true;
    }
    if (mode.category == 3 && record.grade == SimaiJudgeGrade.perfect) {
      return true;
    }
    return mode.variant == 'E' &&
        record.scoringType == SimaiGameplayScoringType.breakNote &&
        record.grade == SimaiJudgeGrade.perfect;
  }

  static String _gradeText(
    SimaiJudgementRecord record,
    SimaiJudgementDisplayMode mode,
  ) {
    return switch (record.grade) {
      SimaiJudgeGrade.criticalPerfect =>
        mode.category == 1 &&
                record.scoringType != SimaiGameplayScoringType.breakNote
            ? 'PERFECT'
            : 'CRITICAL PERFECT',
      SimaiJudgeGrade.perfect => 'PERFECT',
      SimaiJudgeGrade.great => 'GREAT',
      SimaiJudgeGrade.good => 'GOOD',
      SimaiJudgeGrade.miss => 'MISS',
    };
  }

  static Color _gradeColor(SimaiJudgeGrade grade) => switch (grade) {
    SimaiJudgeGrade.criticalPerfect => const Color(0xFFFFD54F),
    SimaiJudgeGrade.perfect => const Color(0xFFFFC107),
    SimaiJudgeGrade.great => const Color(0xFFEC6BAA),
    SimaiJudgeGrade.good => const Color(0xFF66BB6A),
    SimaiJudgeGrade.miss => const Color(0xFFBDBDBD),
  };
}
