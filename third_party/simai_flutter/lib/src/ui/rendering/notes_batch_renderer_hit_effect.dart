part of 'notes_batch_renderer.dart';

const double _hitEffectPulseDuration = 0.36;
const double _holdHitEffectPulseInterval = 0.14;

// 仅在图集尚未就绪时的无模糊降级画笔（零 MaskFilter.blur，静态复用）。
final Paint _hitEffectFallbackRingPaint = Paint()
  ..isAntiAlias = true
  ..style = PaintingStyle.stroke;

/// Pass 1 预收集仍处于活跃脉冲期的打击特效，返回 true 表示需进入 Pass 2 合批。
bool _collectHitEffect({
  required SimaiGame game,
  required SimaiGameplaySession? session,
  required Note note,
  required double noteTime,
  required int collectionIndex,
  required int noteIndex,
  required _DeferredHitEffectEntry out,
}) {
  var effectTime = noteTime;
  var effectColor = const Color(0xFFFFC83D);
  var holdDuration = _hitEffectHoldDuration(note);
  if (session != null) {
    final feedback = session.headFeedbackFor(collectionIndex, noteIndex);
    if (feedback == null) return false;
    effectTime = feedback.judgedTime;
    effectColor = _judgementEffectColor(feedback.grade);
    if (holdDuration > 0) {
      final pressed = session.isHoldPressed(
        collectionIndex,
        noteIndex,
        game.chartTime,
      );
      if (!pressed && feedback.grade == SimaiJudgeGrade.miss) return false;
      if (!pressed) holdDuration = 0.0;
    } else if (feedback.grade == SimaiJudgeGrade.miss) {
      return false;
    }
  }

  final elapsed = game.chartTime - effectTime;
  if (!elapsed.isFinite || elapsed < 0) return false;
  final safeHoldDuration = holdDuration.isFinite ? max(0.0, holdDuration) : 0.0;
  if (safeHoldDuration <= 0) {
    if (elapsed >= _hitEffectPulseDuration) return false;
  } else {
    final lastPulseIndex =
        (min(elapsed, safeHoldDuration) / _holdHitEffectPulseInterval).floor();
    final firstPulseIndex = max(
      0,
      ((elapsed - _hitEffectPulseDuration) / _holdHitEffectPulseInterval)
          .ceil(),
    );
    if (firstPulseIndex > lastPulseIndex) return false;
  }

  out
    ..note = note
    ..effectTime = effectTime
    ..holdDuration = safeHoldDuration
    ..effectColor = effectColor;
  return true;
}

/// Pass 2 统一合批绘制已收集的打击光环特效（走 `'hit_glow'` 图集精灵，零 MaskFilter.blur、零临时 Paint）。
void _drawCollectedHitEffect(
  Canvas canvas, {
  required SimaiGame game,
  required _DeferredHitEffectEntry entry,
}) {
  final note = entry.note!;
  final baseRadius = game.chartRadius * NoteGeometry.tapStarHoldRadiusRatio;
  if (!baseRadius.isFinite || baseRadius <= 0) return;

  final mirroredLocation = NoteUtils.mirrorLocation(
    note.location,
    game.mirrorMode,
  );
  final position = NoteUtils.getTouchPosition(
    game.chartCenter,
    game.chartRadius,
    mirroredLocation,
  );
  final elapsed = game.chartTime - entry.effectTime;
  if (!elapsed.isFinite || elapsed < 0) return;

  final safeHoldDuration = entry.holdDuration;
  if (safeHoldDuration <= 0) {
    if (elapsed < _hitEffectPulseDuration) {
      _drawHitEffectPulse(
        canvas,
        game: game,
        position: position,
        baseRadius: baseRadius,
        age: elapsed,
        pulsePhase: 0,
        color: entry.effectColor,
      );
    }
    return;
  }

  final lastPulseIndex =
      (min(elapsed, safeHoldDuration) / _holdHitEffectPulseInterval).floor();
  final firstPulseIndex = max(
    0,
    ((elapsed - _hitEffectPulseDuration) / _holdHitEffectPulseInterval).ceil(),
  );
  var pulsePhase = 0;
  for (var index = firstPulseIndex; index <= lastPulseIndex; index++) {
    final age = elapsed - index * _holdHitEffectPulseInterval;
    if (age >= 0 && age < _hitEffectPulseDuration) {
      _drawHitEffectPulse(
        canvas,
        game: game,
        position: position,
        baseRadius: baseRadius,
        age: age,
        pulsePhase: pulsePhase++,
        color: entry.effectColor,
      );
    }
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
  required SimaiGame game,
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
  final int spriteAlpha = (255 * opacity * pulseVariation).round().clamp(
    0,
    255,
  );
  if (spriteAlpha <= 0) return;

  if (game.noteAssets.drawSprite(
    canvas,
    key: 'hit_glow',
    position: position,
    size: NoteAssetManager.hitGlowSpriteSize(radius),
    alpha: spriteAlpha,
    color: color,
  )) {
    return;
  }

  // 图集未就绪时的轻量降级绘制（无模糊、复用静态 Paint）。
  game.noteAssets.flush(canvas);
  _hitEffectFallbackRingPaint
    ..strokeWidth = baseRadius * (0.24 - progress * 0.05)
    ..color = color.withAlpha((235 * opacity * pulseVariation).round().clamp(0, 255));
  canvas.drawCircle(position, radius, _hitEffectFallbackRingPaint);
}
