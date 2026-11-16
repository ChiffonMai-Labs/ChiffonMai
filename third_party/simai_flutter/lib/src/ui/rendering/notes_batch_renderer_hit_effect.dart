part of 'notes_batch_renderer.dart';

const double _hitEffectPulseDuration = 0.36;
const double _holdHitEffectPulseInterval = 0.14;

void _drawHitEffect(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required double noteTime,
  required int collectionIndex,
  required int noteIndex,
}) {
  if (!game.showHitEffects) return;

  var effectTime = noteTime;
  var effectColor = const Color(0xFFFFC83D);
  var holdDuration = _hitEffectHoldDuration(note);
  final session = game.gameplaySession;
  if (session != null) {
    final feedback = session.headFeedbackFor(collectionIndex, noteIndex);
    if (feedback == null) return;
    effectTime = feedback.judgedTime;
    effectColor = _judgementEffectColor(feedback.grade);
    if (holdDuration > 0) {
      final pressed = session.isHoldPressed(
        collectionIndex,
        noteIndex,
        game.chartTime,
      );
      if (!pressed && feedback.grade == SimaiJudgeGrade.miss) return;
      if (!pressed) holdDuration = 0.0;
    } else if (feedback.grade == SimaiJudgeGrade.miss) {
      return;
    }
  }

  final elapsed = game.chartTime - effectTime;
  final pulseAges = _hitEffectPulseAges(
    elapsed: elapsed,
    holdDuration: holdDuration,
  );
  if (pulseAges.isEmpty) return;

  final mirroredLocation = NoteUtils.mirrorLocation(
    note.location,
    game.mirrorMode,
  );
  final position = NoteUtils.getTouchPosition(
    game.chartCenter,
    game.chartRadius,
    mirroredLocation,
  );
  final baseRadius = game.chartRadius * NoteGeometry.tapStarHoldRadiusRatio;
  if (!baseRadius.isFinite || baseRadius <= 0) return;

  game.noteAssets.flush(canvas);
  for (var i = 0; i < pulseAges.length; i++) {
    _drawHitEffectPulse(
      canvas,
      position: position,
      baseRadius: baseRadius,
      age: pulseAges[i],
      pulsePhase: i,
      color: effectColor,
    );
  }
}

Color _judgementEffectColor(SimaiJudgeGrade grade) => switch (grade) {
  SimaiJudgeGrade.criticalPerfect => const Color(0xFFFFD65A),
  SimaiJudgeGrade.perfect => const Color(0xFFFFC83D),
  SimaiJudgeGrade.great => const Color(0xFFFF6FAE),
  SimaiJudgeGrade.good => const Color(0xFF69D46F),
  SimaiJudgeGrade.miss => const Color(0xFF9E9E9E),
};

double _hitEffectHoldDuration(Note note) {
  if ((note.length ?? 0.0) <= 0.0) return 0.0;
  final duration = note.length ?? 0.0;
  return duration.isFinite ? max(0.0, duration) : 0.0;
}

List<double> _hitEffectPulseAges({
  required double elapsed,
  required double holdDuration,
}) {
  if (!elapsed.isFinite || elapsed < 0) return const <double>[];

  final safeHoldDuration = holdDuration.isFinite ? max(0.0, holdDuration) : 0.0;
  if (safeHoldDuration <= 0) {
    return elapsed < _hitEffectPulseDuration
        ? <double>[elapsed]
        : const <double>[];
  }

  final lastPulseIndex =
      (min(elapsed, safeHoldDuration) / _holdHitEffectPulseInterval).floor();
  final firstPulseIndex = max(
    0,
    ((elapsed - _hitEffectPulseDuration) / _holdHitEffectPulseInterval).ceil(),
  );
  if (firstPulseIndex > lastPulseIndex) return const <double>[];

  final ages = <double>[];
  for (var index = firstPulseIndex; index <= lastPulseIndex; index++) {
    final age = elapsed - index * _holdHitEffectPulseInterval;
    if (age >= 0 && age < _hitEffectPulseDuration) ages.add(age);
  }
  return ages;
}

void _drawHitEffectPulse(
  Canvas canvas, {
  required Offset position,
  required double baseRadius,
  required double age,
  required int pulsePhase,
  Color color = const Color(0xFFFFC83D),
}) {
  final progress = (age / _hitEffectPulseDuration).clamp(0.0, 1.0);
  final eased = Curves.easeOutCubic.transform(progress);
  final radius = ui.lerpDouble(baseRadius * 0.55, baseRadius * 1.5, eased)!;

  final fade = pow(1.0 - progress, 1.35).toDouble();
  final fadeIn = (progress / 0.08).clamp(0.0, 1.0);
  final opacity = fade * (0.38 + 0.62 * fadeIn);
  if (opacity <= 0.001) return;

  final pulseVariation = 0.92 + (pulsePhase.isEven ? 0.08 : 0.0);
  final glowPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = baseRadius * (0.5 - progress * 0.12)
    ..color = color.withAlpha(
      (115 * opacity * pulseVariation).round().clamp(0, 255),
    )
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 0.32);

  final ringPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = baseRadius * (0.24 - progress * 0.05)
    ..color = color.withAlpha(
      (235 * opacity * pulseVariation).round().clamp(0, 255),
    );

  final highlightPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.0, baseRadius * 0.055)
    ..color = const Color(
      0xFFFFF0A0,
    ).withAlpha((175 * opacity * pulseVariation).round().clamp(0, 255));

  canvas.drawCircle(position, radius, glowPaint);
  canvas.drawCircle(position, radius, ringPaint);
  canvas.drawCircle(
    position,
    radius - ringPaint.strokeWidth * 0.32,
    highlightPaint,
  );
}
