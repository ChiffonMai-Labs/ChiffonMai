import 'dart:math';

import 'package:flutter/material.dart';

import '../../gameplay/gameplay_models.dart';

const double simaiJudgementFeedbackDuration = 0.50;

/// 判定反馈视觉分级，用于区分支行（CRITICAL / FAST / LATE）、绝赞与主判定配色。
enum SimaiJudgementVisualKind {
  critical,
  criticalPerfect,
  breakCritical,
  breakCriticalPerfect,
  breakMergedCriticalPerfect,
  perfect,
  great,
  good,
  miss,
  fast,
  late,
}

class SimaiJudgementLine {
  const SimaiJudgementLine({
    required this.text,
    required this.color,
    this.kind = SimaiJudgementVisualKind.perfect,
    this.isSubLine = false,
  });

  final String text;
  final Color color;
  final SimaiJudgementVisualKind kind;
  final bool isSubLine;
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
  const overshootDuration = 0.055;
  const settleDuration = 0.11;
  const fadeStart = 0.34;
  if (age < overshootDuration) {
    final progress = Curves.easeOutCubic.transform(age / overshootDuration);
    return SimaiJudgementAnimationState(
      opacity: 0.35 + 0.65 * progress,
      scale: 0.64 + 0.49 * progress,
    );
  }
  if (age < settleDuration) {
    final progress = Curves.easeOutCubic.transform(
      (age - overshootDuration) / (settleDuration - overshootDuration),
    );
    return SimaiJudgementAnimationState(
      opacity: 1.0,
      scale: 1.13 - 0.13 * progress,
    );
  }
  if (age <= fadeStart) {
    return const SimaiJudgementAnimationState(opacity: 1.0, scale: 1.0);
  }
  final progress =
      ((age - fadeStart) / (simaiJudgementFeedbackDuration - fadeStart)).clamp(
        0.0,
        1.0,
      );
  final eased = Curves.easeInQuad.transform(progress);
  return SimaiJudgementAnimationState(
    opacity: 1.0 - eased,
    scale: 1.0 - 0.04 * eased,
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

  SimaiJudgementVisualKind get primaryKind =>
      gradeLine?.kind ?? timingLine?.kind ?? SimaiJudgementVisualKind.perfect;

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
    final bool isBreak = record.scoringType == SimaiGameplayScoringType.breakNote;
    final gradeText = _gradeText(record, mode);
    final gradeColor = _gradeColor(record.grade);
    final gradeKind = _gradeKind(record.grade, gradeText, isBreak: isBreak);
    final timingColor = switch (record.timing) {
      SimaiJudgeTiming.fast => const Color(0xFF36C2FF),
      SimaiJudgeTiming.late => const Color(0xFFFF4F64),
      SimaiJudgeTiming.none => gradeColor,
    };
    final timingKind = switch (record.timing) {
      SimaiJudgeTiming.fast => SimaiJudgementVisualKind.fast,
      SimaiJudgeTiming.late => SimaiJudgementVisualKind.late,
      SimaiJudgeTiming.none => gradeKind,
    };
    final visibleTiming = allowsTiming ? timingText : null;
    final showsCritical = gradeText == 'CRITICAL PERFECT';

    // Critical occupies the same visual row as FAST/LATE while PERFECT stays
    // on the grade row. Variant D still hides C-Perfect as documented.
    if (showsCritical && mode.variant != 'D') {
      return SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(
          text: 'PERFECT',
          color: gradeColor,
          kind: isBreak
              ? SimaiJudgementVisualKind.breakCriticalPerfect
              : SimaiJudgementVisualKind.criticalPerfect,
        ),
        timingLine: SimaiJudgementLine(
          text: 'CRITICAL',
          color: isBreak ? const Color(0xFFFFF49A) : const Color(0xFFFFF176),
          kind: isBreak
              ? SimaiJudgementVisualKind.breakCritical
              : SimaiJudgementVisualKind.critical,
          isSubLine: true,
        ),
      );
    }

    return switch (mode.variant) {
      'A' => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(
          text: gradeText,
          color: gradeColor,
          kind: gradeKind,
        ),
      ),
      'B' || 'E' => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(
          text: gradeText,
          color: gradeColor,
          kind: gradeKind,
        ),
        timingLine: visibleTiming == null
            ? null
            : SimaiJudgementLine(
                text: visibleTiming,
                color: gradeColor,
                kind: gradeKind,
                isSubLine: true,
              ),
      ),
      // 机台 x-C：保留主判定原色，副行以蓝/红双色显示 FAST/LATE。
      'C' => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(
          text: gradeText,
          color: gradeColor,
          kind: gradeKind,
        ),
        timingLine: visibleTiming == null
            ? null
            : SimaiJudgementLine(
                text: visibleTiming,
                color: timingColor,
                kind: timingKind,
                isSubLine: true,
              ),
      ),
      // 机台 x-D：隐藏主判定字样仅显示 FAST/LATE，但 MISS 仍需保留显示。
      'D' => record.grade == SimaiJudgeGrade.miss
          ? SimaiJudgementPresentation(
              gradeLine: SimaiJudgementLine(
                text: gradeText,
                color: gradeColor,
                kind: gradeKind,
              ),
            )
          : SimaiJudgementPresentation(
              timingLine: visibleTiming == null
                  ? null
                  : SimaiJudgementLine(
                      text: visibleTiming,
                      color: timingColor,
                      kind: timingKind,
                    ),
            ),
      _ => SimaiJudgementPresentation(
        gradeLine: SimaiJudgementLine(
          text: gradeText,
          color: gradeColor,
          kind: gradeKind,
        ),
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
        mode.category == 1 ? 'PERFECT' : 'CRITICAL PERFECT',
      SimaiJudgeGrade.perfect => 'PERFECT',
      SimaiJudgeGrade.great => 'GREAT',
      SimaiJudgeGrade.good => 'GOOD',
      SimaiJudgeGrade.miss => 'MISS',
    };
  }

  static SimaiJudgementVisualKind _gradeKind(
    SimaiJudgeGrade grade,
    String gradeText, {
    bool isBreak = false,
  }) => switch (grade) {
    SimaiJudgeGrade.criticalPerfect =>
      gradeText == 'CRITICAL PERFECT'
          ? (isBreak
                ? SimaiJudgementVisualKind.breakCriticalPerfect
                : SimaiJudgementVisualKind.criticalPerfect)
          : (isBreak
                ? SimaiJudgementVisualKind.breakMergedCriticalPerfect
                : SimaiJudgementVisualKind.perfect),
    SimaiJudgeGrade.perfect => SimaiJudgementVisualKind.perfect,
    SimaiJudgeGrade.great => SimaiJudgementVisualKind.great,
    SimaiJudgeGrade.good => SimaiJudgementVisualKind.good,
    SimaiJudgeGrade.miss => SimaiJudgementVisualKind.miss,
  };

  static Color _gradeColor(SimaiJudgeGrade grade) => switch (grade) {
    SimaiJudgeGrade.criticalPerfect => const Color(0xFFFFE04A),
    SimaiJudgeGrade.perfect => const Color(0xFFFFC418),
    SimaiJudgeGrade.great => const Color(0xFFFF52A2),
    SimaiJudgeGrade.good => const Color(0xFF42DC5A),
    SimaiJudgeGrade.miss => const Color(0xFFAAB4C4),
  };
}
