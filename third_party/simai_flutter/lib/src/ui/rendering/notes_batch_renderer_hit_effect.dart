part of 'notes_batch_renderer.dart';

const double _hitEffectPulseDuration = 0.36;
const double _holdHitEffectPulseInterval = 0.14;
const double _arcadeNormalPulseDuration = 0.34;
const double _arcadeBreakPulseDuration = 0.48;
const double _arcadeBreakSecondHexDelay = 0.035;

// 仅在图集尚未就绪时的无模糊降级画笔与路径（零 MaskFilter.blur，静态复用）。
final Paint _hitEffectFallbackRingPaint = Paint()
  ..isAntiAlias = true
  ..style = PaintingStyle.stroke;

final Path _hitEffectFallbackHexPath = Path();

class _ArcadeBreakPalette {
  const _ArcadeBreakPalette({
    required this.core,
    required this.primary,
    required this.accent,
    required this.sparkleA,
    required this.sparkleB,
  });

  final Color core;
  final Color primary;
  final Color accent;
  final Color sparkleA;
  final Color sparkleB;
}

bool _isBreakHitNote(Note note) =>
    note.type == NoteType.breakNote || (note.styles & NoteStyles.breakHead) != 0;

double _hitEffectDurationFor(
  SimaiHitEffectStyle style, {
  required bool isBreak,
}) {
  return switch (style) {
    SimaiHitEffectStyle.ring => _hitEffectPulseDuration,
    SimaiHitEffectStyle.arcadeBurst =>
      isBreak ? _arcadeBreakPulseDuration : _arcadeNormalPulseDuration,
  };
}

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
  var grade = SimaiJudgeGrade.criticalPerfect;
  var effectColor = const Color(0xFFFFD65A);
  var holdDuration = _hitEffectHoldDuration(note);
  if (session != null) {
    final feedback = session.headFeedbackFor(collectionIndex, noteIndex);
    if (feedback == null) return false;
    effectTime = feedback.judgedTime;
    grade = feedback.grade;
    effectColor = _judgementEffectColor(grade);
    if (holdDuration > 0) {
      final pressed = session.isHoldPressed(
        collectionIndex,
        noteIndex,
        game.chartTime,
      );
      if (!pressed && grade == SimaiJudgeGrade.miss) return false;
      if (!pressed) holdDuration = 0.0;
    } else if (grade == SimaiJudgeGrade.miss) {
      return false;
    }
  } else {
    grade = game.autoPlayTimeline.headGradeFor(collectionIndex, noteIndex);
    if (grade == SimaiJudgeGrade.miss) return false;
    effectColor = _judgementEffectColor(grade);
  }

  final bool isBreak = _isBreakHitNote(note);
  final double pulseDuration = _hitEffectDurationFor(
    game.hitEffectStyle,
    isBreak: isBreak,
  );
  final elapsed = game.chartTime - effectTime;
  if (!elapsed.isFinite || elapsed < 0) return false;
  final safeHoldDuration = holdDuration.isFinite ? max(0.0, holdDuration) : 0.0;
  if (safeHoldDuration <= 0) {
    if (elapsed >= pulseDuration) return false;
  } else {
    final lastPulseIndex =
        (min(elapsed, safeHoldDuration) / _holdHitEffectPulseInterval).floor();
    final firstPulseIndex = max(
      0,
      ((elapsed - pulseDuration) / _holdHitEffectPulseInterval).ceil(),
    );
    if (firstPulseIndex > lastPulseIndex) return false;
  }

  out
    ..note = note
    ..effectTime = effectTime
    ..holdDuration = safeHoldDuration
    ..effectColor = effectColor
    ..grade = grade
    ..isBreak = isBreak
    ..seed = collectionIndex * 31 + noteIndex;
  return true;
}

/// Pass 2 统一合批绘制已收集的打击特效（零 MaskFilter.blur、零临时 Paint/Path）。
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

  final style = game.hitEffectStyle;
  final pulseDuration = _hitEffectDurationFor(style, isBreak: entry.isBreak);
  final safeHoldDuration = entry.holdDuration;

  void drawSinglePulse(double age, int pulsePhase, {required bool isHoldSustained}) {
    if (style == SimaiHitEffectStyle.ring) {
      _drawHitEffectPulse(
        canvas,
        game: game,
        position: position,
        baseRadius: baseRadius,
        age: age,
        pulsePhase: pulsePhase,
        color: entry.effectColor,
      );
      return;
    }
    _drawArcadeBurstHitEffect(
      canvas,
      game: game,
      position: position,
      baseRadius: baseRadius,
      age: age,
      pulsePhase: pulsePhase,
      grade: entry.grade,
      normalColor: entry.effectColor,
      isBreak: entry.isBreak,
      isHoldSustained: isHoldSustained,
      seed: entry.seed,
    );
  }

  if (safeHoldDuration <= 0) {
    if (elapsed < pulseDuration) {
      drawSinglePulse(elapsed, 0, isHoldSustained: false);
    }
    return;
  }

  final lastPulseIndex =
      (min(elapsed, safeHoldDuration) / _holdHitEffectPulseInterval).floor();
  final firstPulseIndex = max(
    0,
    ((elapsed - pulseDuration) / _holdHitEffectPulseInterval).ceil(),
  );
  for (var index = firstPulseIndex; index <= lastPulseIndex; index++) {
    final age = elapsed - index * _holdHitEffectPulseInterval;
    if (age >= 0 && age < pulseDuration) {
      drawSinglePulse(
        age,
        index,
        isHoldSustained: index > 0,
      );
    }
  }
}

Color _judgementEffectColor(SimaiJudgeGrade grade) => switch (grade) {
  SimaiJudgeGrade.criticalPerfect => const Color(0xFFFFE066),
  SimaiJudgeGrade.perfect => const Color(0xFFFFB830),
  SimaiJudgeGrade.great => const Color(0xFFFF64A8),
  SimaiJudgeGrade.good => const Color(0xFF5CD66B),
  SimaiJudgeGrade.miss => const Color(0xFF9E9E9E),
};

_ArcadeBreakPalette _breakPalette(SimaiJudgeGrade grade) => switch (grade) {
  SimaiJudgeGrade.criticalPerfect => const _ArcadeBreakPalette(
    core: Color(0xFFFFFDF2),
    primary: Color(0xFFFFD84A),
    accent: Color(0xFFFF5E24),
    sparkleA: Color(0xFFFFF3B0),
    sparkleB: Color(0xFFFF7AD9),
  ),
  SimaiJudgeGrade.perfect => const _ArcadeBreakPalette(
    core: Color(0xFFFFF6DC),
    primary: Color(0xFFFFAA2B),
    accent: Color(0xFFFF4A1C),
    sparkleA: Color(0xFFFFE082),
    sparkleB: Color(0xFFFF7043),
  ),
  SimaiJudgeGrade.great => const _ArcadeBreakPalette(
    core: Color(0xFFFFF0F7),
    primary: Color(0xFFFF64A8),
    accent: Color(0xFFFF8C3B),
    sparkleA: Color(0xFFFFB3D9),
    sparkleB: Color(0xFFFFD166),
  ),
  SimaiJudgeGrade.good => const _ArcadeBreakPalette(
    core: Color(0xFFF0FFF4),
    primary: Color(0xFF5CD66B),
    accent: Color(0xFFFFE066),
    sparkleA: Color(0xFFB9F6CA),
    sparkleB: Color(0xFFFFF176),
  ),
  SimaiJudgeGrade.miss => const _ArcadeBreakPalette(
    core: Color(0xFFEEEEEE),
    primary: Color(0xFF9E9E9E),
    accent: Color(0xFF757575),
    sparkleA: Color(0xFFBDBDBD),
    sparkleB: Color(0xFF9E9E9E),
  ),
};

double _hitEffectHoldDuration(Note note) {
  if ((note.length ?? 0.0) <= 0.0) return 0.0;
  final duration = note.length ?? 0.0;
  return duration.isFinite ? max(0.0, duration) : 0.0;
}

List<double> _hitEffectPulseAges({
  required double elapsed,
  required double holdDuration,
  SimaiHitEffectStyle style = SimaiHitEffectStyle.ring,
  bool isBreak = false,
}) {
  if (!elapsed.isFinite || elapsed < 0) return const <double>[];

  final double pulseDuration = _hitEffectDurationFor(style, isBreak: isBreak);
  final safeHoldDuration = holdDuration.isFinite ? max(0.0, holdDuration) : 0.0;
  if (safeHoldDuration <= 0) {
    return elapsed < pulseDuration ? <double>[elapsed] : const <double>[];
  }

  final lastPulseIndex =
      (min(elapsed, safeHoldDuration) / _holdHitEffectPulseInterval).floor();
  final firstPulseIndex = max(
    0,
    ((elapsed - pulseDuration) / _holdHitEffectPulseInterval).ceil(),
  );
  if (firstPulseIndex > lastPulseIndex) return const <double>[];

  final ages = <double>[];
  for (var index = firstPulseIndex; index <= lastPulseIndex; index++) {
    final age = elapsed - index * _holdHitEffectPulseInterval;
    if (age >= 0 && age < pulseDuration) ages.add(age);
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

void _drawArcadeBurstHitEffect(
  Canvas canvas, {
  required SimaiGame game,
  required Offset position,
  required double baseRadius,
  required double age,
  required int pulsePhase,
  required SimaiJudgeGrade grade,
  required Color normalColor,
  required bool isBreak,
  required bool isHoldSustained,
  required int seed,
}) {
  final double duration =
      isBreak ? _arcadeBreakPulseDuration : _arcadeNormalPulseDuration;
  final double progress = (age / duration).clamp(0.0, 1.0);
  final double baseAngle = ((seed * 37) % 12) * (pi / 6.0);
  final double fadeIn = (progress / 0.06).clamp(0.0, 1.0);
  final double envelope = 0.38 + 0.62 * fadeIn;

  if (!isBreak) {
    final Color coreColor = Color.lerp(normalColor, Colors.white, 0.55)!;
    if (isHoldSustained) {
      final double eased = Curves.easeOutCubic.transform(progress);
      final double hexR = ui.lerpDouble(
        baseRadius * 0.52,
        baseRadius * 1.24,
        eased,
      )!;
      final double fade = pow(1.0 - progress, 1.4).toDouble();
      final int glowAlpha = (105 * fade * envelope).round().clamp(0, 255);
      final int hexAlpha = (175 * fade * envelope).round().clamp(0, 255);
      if (glowAlpha > 0) {
        if (!game.noteAssets.drawSprite(
          canvas,
          key: 'hit_glow',
          position: position,
          size: NoteAssetManager.hitGlowSpriteSize(hexR * 0.94),
          alpha: glowAlpha,
          color: normalColor,
        )) {
          _drawArcadeHexFallback(
            canvas,
            game: game,
            position: position,
            radius: hexR,
            rotation: baseAngle + progress * 0.18,
            strokeWidth: baseRadius * 0.16,
            color: normalColor,
            alpha: hexAlpha,
          );
          return;
        }
      }
      if (hexAlpha > 0) {
        if (!game.noteAssets.drawSprite(
          canvas,
          key: 'hit_hex_ring',
          position: position,
          size: NoteAssetManager.hitHexRingSpriteSize(hexR),
          rotation: baseAngle + progress * 0.18,
          alpha: hexAlpha,
          color: normalColor,
        )) {
          _drawArcadeHexFallback(
            canvas,
            game: game,
            position: position,
            radius: hexR,
            rotation: baseAngle + progress * 0.18,
            strokeWidth: baseRadius * 0.16,
            color: normalColor,
            alpha: hexAlpha,
          );
        }
      }
      return;
    }

    // 非绝赞主命中：底衬柔光环 + 主六边形冲击波 + 瞬时核心白闪 + 克制短星芒。
    final double glowR = ui.lerpDouble(
      baseRadius * 0.46,
      baseRadius * 1.38,
      Curves.easeOutCubic.transform(progress),
    )!;
    final int glowAlpha =
        (150 * pow(1.0 - progress, 1.5) * envelope).round().clamp(0, 255);
    if (glowAlpha > 0) {
      if (!game.noteAssets.drawSprite(
        canvas,
        key: 'hit_glow',
        position: position,
        size: NoteAssetManager.hitGlowSpriteSize(glowR),
        alpha: glowAlpha,
        color: normalColor,
      )) {
        _drawArcadeHexFallback(
          canvas,
          game: game,
          position: position,
          radius: glowR,
          rotation: baseAngle,
          strokeWidth: baseRadius * 0.18,
          color: normalColor,
          alpha: glowAlpha,
        );
        return;
      }
    }

    final double hexR = ui.lerpDouble(
      baseRadius * 0.48,
      baseRadius * 1.54,
      Curves.easeOutQuart.transform(progress),
    )!;
    final int hexAlpha =
        (245 * pow(1.0 - progress, 1.3) * envelope).round().clamp(0, 255);
    if (hexAlpha > 0) {
      game.noteAssets.drawSprite(
        canvas,
        key: 'hit_hex_ring',
        position: position,
        size: NoteAssetManager.hitHexRingSpriteSize(hexR),
        rotation: baseAngle + progress * 0.22,
        alpha: hexAlpha,
        color: normalColor,
      );
    }

    if (progress < 0.38) {
      final double tCore = (progress / 0.38).clamp(0.0, 1.0);
      final double coreR = ui.lerpDouble(
        baseRadius * 0.58,
        baseRadius * 1.08,
        Curves.easeOutCubic.transform(tCore),
      )!;
      final int coreAlpha = (235 * (1.0 - tCore) * (1.0 - tCore)).round().clamp(
        0,
        255,
      );
      if (coreAlpha > 0) {
        game.noteAssets.drawSprite(
          canvas,
          key: 'hit_core_flash',
          position: position,
          size: NoteAssetManager.hitCoreFlashSpriteSize(coreR),
          alpha: coreAlpha,
          color: coreColor,
        );
      }
    }

    if (progress < 0.42) {
      final double tRay = (progress / 0.42).clamp(0.0, 1.0);
      final double rayR = ui.lerpDouble(
        baseRadius * 0.45,
        baseRadius * 0.96,
        Curves.easeOutCubic.transform(tRay),
      )!;
      final int rayAlpha =
          (125 * pow(1.0 - tRay, 1.6)).round().clamp(0, 255);
      if (rayAlpha > 0) {
        game.noteAssets.drawSprite(
          canvas,
          key: 'hit_starburst',
          position: position,
          size: NoteAssetManager.hitStarburstSpriteSize(rayR),
          rotation: baseAngle + tRay * 0.16,
          alpha: rayAlpha,
          color: coreColor,
        );
      }
    }
    return;
  }

  // 绝赞（Break Tap / Break Hold / Break Slide 头）：双层交错六边形 + 八向星芒爆裂 + 星屑粒子。
  final palette = _breakPalette(grade);
  if (isHoldSustained) {
    final bool evenPulse = pulsePhase.isEven;
    final Color ringColor = evenPulse ? palette.primary : palette.accent;
    final double hexR = ui.lerpDouble(
      baseRadius * 0.50,
      baseRadius * 1.48,
      Curves.easeOutCubic.transform(progress),
    )!;
    final double fade = pow(1.0 - progress, 1.3).toDouble();
    final int hexAlpha = (210 * fade * envelope).round().clamp(0, 255);
    if (hexAlpha > 0) {
      if (!game.noteAssets.drawSprite(
        canvas,
        key: 'hit_hex_ring',
        position: position,
        size: NoteAssetManager.hitHexRingSpriteSize(hexR),
        rotation: baseAngle + (evenPulse ? 0.0 : pi / 6.0) + progress * 0.2,
        alpha: hexAlpha,
        color: ringColor,
      )) {
        _drawArcadeHexFallback(
          canvas,
          game: game,
          position: position,
          radius: hexR,
          rotation: baseAngle + (evenPulse ? 0.0 : pi / 6.0),
          strokeWidth: baseRadius * 0.2,
          color: ringColor,
          alpha: hexAlpha,
        );
        return;
      }
    }
    if (progress < 0.72) {
      final double ts = (progress / 0.72).clamp(0.0, 1.0);
      final double starR = ui.lerpDouble(
        baseRadius * 0.42,
        baseRadius * 1.08,
        Curves.easeOutCubic.transform(ts),
      )!;
      final int starAlpha = (155 * pow(1.0 - ts, 1.45) * envelope).round().clamp(
        0,
        255,
      );
      if (starAlpha > 0) {
        game.noteAssets.drawSprite(
          canvas,
          key: 'hit_starburst',
          position: position,
          size: NoteAssetManager.hitStarburstSpriteSize(starR),
          rotation: baseAngle + (evenPulse ? 0.0 : pi / 8.0) + ts * 0.25,
          alpha: starAlpha,
          color: palette.core,
        );
      }
    }
    return;
  }

  // 1) 炽热外扩散辉光
  final double outerGlowR = ui.lerpDouble(
    baseRadius * 0.52,
    baseRadius * 1.92,
    Curves.easeOutCubic.transform(progress),
  )!;
  final int outerGlowAlpha =
      (195 * pow(1.0 - progress, 1.35) * envelope).round().clamp(0, 255);
  if (outerGlowAlpha > 0) {
    if (!game.noteAssets.drawSprite(
      canvas,
      key: 'hit_glow',
      position: position,
      size: NoteAssetManager.hitGlowSpriteSize(outerGlowR),
      alpha: outerGlowAlpha,
      color: palette.accent,
    )) {
      _drawArcadeHexFallback(
        canvas,
        game: game,
        position: position,
        radius: outerGlowR,
        rotation: baseAngle,
        strokeWidth: baseRadius * 0.24,
        color: palette.primary,
        alpha: outerGlowAlpha,
      );
      return;
    }
  }

  // 2) 外层主六边形冲击波
  final double outerHexR = ui.lerpDouble(
    baseRadius * 0.44,
    baseRadius * 2.06,
    Curves.easeOutQuart.transform(progress),
  )!;
  final int outerHexAlpha =
      (255 * pow(1.0 - progress, 1.25) * envelope).round().clamp(0, 255);
  if (outerHexAlpha > 0) {
    game.noteAssets.drawSprite(
      canvas,
      key: 'hit_hex_ring',
      position: position,
      size: NoteAssetManager.hitHexRingSpriteSize(outerHexR),
      rotation: baseAngle + progress * 0.28,
      alpha: outerHexAlpha,
      color: palette.primary,
    );
  }

  // 3) 延迟 35ms 的反向交错内六边形（旋转差 30° 构成 12 角星芒晶格冲击波）
  if (age > _arcadeBreakSecondHexDelay) {
    final double t2 = ((age - _arcadeBreakSecondHexDelay) /
            (_arcadeBreakPulseDuration - _arcadeBreakSecondHexDelay))
        .clamp(0.0, 1.0);
    final double innerHexR = ui.lerpDouble(
      baseRadius * 0.36,
      baseRadius * 1.74,
      Curves.easeOutQuart.transform(t2),
    )!;
    final int innerHexAlpha =
        (235 * pow(1.0 - t2, 1.3) * (0.38 + 0.62 * (t2 / 0.08).clamp(0.0, 1.0)))
            .round()
            .clamp(0, 255);
    if (innerHexAlpha > 0) {
      game.noteAssets.drawSprite(
        canvas,
        key: 'hit_hex_ring',
        position: position,
        size: NoteAssetManager.hitHexRingSpriteSize(innerHexR),
        rotation: baseAngle + pi / 6.0 - t2 * 0.22,
        alpha: innerHexAlpha,
        color: palette.accent,
      );
    }
  }

  // 4) 强力八向星芒爆裂（外层炽金芒 + 偏转白热内芒）
  if (progress < 0.62) {
    final double ts = (progress / 0.62).clamp(0.0, 1.0);
    final double outerStarR = ui.lerpDouble(
      baseRadius * 0.48,
      baseRadius * 2.02,
      Curves.easeOutExpo.transform(ts),
    )!;
    final int outerStarAlpha =
        (250 * pow(1.0 - ts, 1.45)).round().clamp(0, 255);
    if (outerStarAlpha > 0) {
      game.noteAssets.drawSprite(
        canvas,
        key: 'hit_starburst',
        position: position,
        size: NoteAssetManager.hitStarburstSpriteSize(outerStarR),
        rotation: baseAngle + ts * 0.24,
        alpha: outerStarAlpha,
        color: palette.primary,
      );
    }
    if (ts < 0.55) {
      final double tInner = (ts / 0.55).clamp(0.0, 1.0);
      final double innerStarR = ui.lerpDouble(
        baseRadius * 0.38,
        baseRadius * 1.45,
        Curves.easeOutExpo.transform(tInner),
      )!;
      final int innerStarAlpha =
          (220 * pow(1.0 - tInner, 1.55)).round().clamp(0, 255);
      if (innerStarAlpha > 0) {
        game.noteAssets.drawSprite(
          canvas,
          key: 'hit_starburst',
          position: position,
          size: NoteAssetManager.hitStarburstSpriteSize(innerStarR),
          rotation: baseAngle + pi / 8.0 - tInner * 0.18,
          alpha: innerStarAlpha,
          color: palette.core,
        );
      }
    }
  }

  // 5) 白热核心爆闪
  if (progress < 0.36) {
    final double tc = (progress / 0.36).clamp(0.0, 1.0);
    final double coreR = ui.lerpDouble(
      baseRadius * 0.56,
      baseRadius * 1.38,
      Curves.easeOutCubic.transform(tc),
    )!;
    final int coreAlpha = (255 * pow(1.0 - tc, 1.7)).round().clamp(0, 255);
    if (coreAlpha > 0) {
      game.noteAssets.drawSprite(
        canvas,
        key: 'hit_core_flash',
        position: position,
        size: NoteAssetManager.hitCoreFlashSpriteSize(coreR),
        alpha: coreAlpha,
        color: palette.core,
      );
    }
  }

  // 6) 8 颗确定性飞散星屑粒子（4 颗外圈快粒 + 4 颗内圈余韵粒）
  final int particleAlpha =
      (245 * pow(1.0 - progress, 1.35) * ((progress / 0.08).clamp(0.0, 1.0)))
          .round()
          .clamp(0, 255);
  if (particleAlpha <= 0) return;

  final double outerEased = Curves.easeOutCubic.transform(progress);
  final double innerEased = Curves.easeOutQuart.transform(progress);
  for (int i = 0; i < 8; i++) {
    final bool isOuter = i.isEven;
    final int jitterSteps = ((seed + i * (isOuter ? 7 : 11)) % 5) - 2;
    final double angle =
        baseAngle + i * (pi / 4.0) + jitterSteps * (isOuter ? 0.06 : 0.08);
    final double dist = isOuter
        ? ui.lerpDouble(baseRadius * 0.46, baseRadius * 2.38, outerEased)!
        : ui.lerpDouble(baseRadius * 0.34, baseRadius * 1.78, innerEased)!;
    final double particleR = isOuter
        ? ui.lerpDouble(baseRadius * 0.32, baseRadius * 0.09, progress)!
        : ui.lerpDouble(baseRadius * 0.25, baseRadius * 0.07, progress)!;
    final Color particleColor = isOuter
        ? ((i ~/ 2).isEven ? palette.sparkleA : palette.sparkleB)
        : (((i - 1) ~/ 2).isEven ? palette.core : palette.sparkleA);
    final double particleRotation = isOuter
        ? baseAngle + i + progress * 2.2
        : baseAngle + i - progress * 1.9;

    game.noteAssets.drawSprite(
      canvas,
      key: 'hit_sparkle',
      position: Offset(
        position.dx + cos(angle) * dist,
        position.dy + sin(angle) * dist,
      ),
      size: NoteAssetManager.hitSparkleSpriteSize(particleR),
      rotation: particleRotation,
      alpha: isOuter ? particleAlpha : (particleAlpha * 0.88).round(),
      color: particleColor,
    );
  }
}

void _drawArcadeHexFallback(
  Canvas canvas, {
  required SimaiGame game,
  required Offset position,
  required double radius,
  required double rotation,
  required double strokeWidth,
  required Color color,
  required int alpha,
}) {
  if (alpha <= 0 || radius <= 0) return;
  game.noteAssets.flush(canvas);
  _hitEffectFallbackHexPath.reset();
  for (int i = 0; i < 6; i++) {
    final double angle = rotation - pi / 2 + i * pi / 3;
    final double px = position.dx + cos(angle) * radius;
    final double py = position.dy + sin(angle) * radius;
    if (i == 0) {
      _hitEffectFallbackHexPath.moveTo(px, py);
    } else {
      _hitEffectFallbackHexPath.lineTo(px, py);
    }
  }
  _hitEffectFallbackHexPath.close();
  _hitEffectFallbackRingPaint
    ..strokeWidth = strokeWidth
    ..color = color.withAlpha(alpha);
  canvas.drawPath(_hitEffectFallbackHexPath, _hitEffectFallbackRingPaint);
}
