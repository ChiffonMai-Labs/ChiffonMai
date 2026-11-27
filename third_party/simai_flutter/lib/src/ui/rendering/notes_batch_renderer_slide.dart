part of 'notes_batch_renderer.dart';

// 复用 WiFi 滑星矢量画笔与常规滑星降级画笔，避免每条轨道每帧分配 Paint。
final Paint _fanArrowPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

final Paint _slideArrowFallbackPaint = Paint()
  ..isAntiAlias = true
  ..style = PaintingStyle.fill;

/// WiFi/扇形滑星每段箭头跟随完成度最慢的分支，三支全部到达该组后才整段消除。
bool shouldHideFanArrowSection({
  required bool leftCleared,
  required bool centerCleared,
  required bool rightCleared,
}) => leftCleared && centerCleared && rightCleared;

bool _isFanSlidePath(SlidePath slidePath) {
  final segments = slidePath.segments;
  for (int i = 0; i < segments.length; i++) {
    if (segments[i].slideType == SlideType.fan) return true;
  }
  return false;
}

Color _resolveSlideHeadColor(SimaiGame game, Note note, bool isEach) {
  final bool headIsBreak = (note.styles & NoteStyles.breakHead) != 0;
  Color headColor;
  if (game.pinkSlideStar) {
    headColor = headIsBreak
        ? SimaiColors.tapBreak
        : (isEach ? SimaiColors.tapEach : SimaiColors.tapNormal);
  } else {
    headColor = headIsBreak
        ? SimaiColors.slideBreak
        : (isEach ? SimaiColors.slideEach : SimaiColors.slideNormal);
  }

  if (game.standardBreakSlide && headIsBreak) {
    headColor = isEach ? SimaiColors.slideEach : SimaiColors.slideNormal;
    if (game.pinkSlideStar) {
      headColor = isEach ? SimaiColors.tapEach : SimaiColors.tapNormal;
    }
  }
  return headColor;
}

Color _resolveSlidePathColor({
  required SimaiGame game,
  required SlidePath slidePath,
  required double startTime,
  required bool isEach,
  required Map<double, int>? slideStartCounts,
}) {
  final Color trackBaseColor = isEach
      ? SimaiColors.slideEach
      : SimaiColors.slideNormal;
  if (slidePath.type == NoteType.breakNote && !game.standardBreakSlide) {
    return SimaiColors.slideBreak;
  }
  final double key = (startTime * 1000).round() / 1000.0;
  final int count = slideStartCounts?[key] ?? 0;
  if (count > 1) {
    return SimaiColors.slideEach;
  }
  if (trackBaseColor == SimaiColors.slideEach ||
      trackBaseColor == SimaiColors.slideNormal) {
    return SimaiColors.slideNormal;
  }
  return trackBaseColor;
}

int _resolveSlideTrackAlpha({
  required double chartTime,
  required double noteTime,
  required double approachTime,
}) {
  if (chartTime < noteTime) {
    final double p = 1.0 - (noteTime - chartTime) / approachTime;
    return (255 * p).clamp(0, 255).toInt();
  }
  return 255;
}

double _resolveSlideHeadRotation({
  required SimaiGame game,
  required Note note,
  required int collectionIndex,
  required int noteIndex,
  required BaseNoteDrawState state,
}) {
  // 图集中的星星朝右，原始未旋转星头朝上。
  double rotation = -pi / 2;
  if (game.rotateSlideStar && note.slidePaths.isNotEmpty) {
    final slideData =
        game.precalcData.slides['${collectionIndex}_${noteIndex}_0'];
    if (slideData != null) {
      rotation += _slideApproachRotation(
        progress: state.progress,
        approachTime: state.approachTime,
        pathLength: slideData.totalLength,
        duration: note.slidePaths.first.duration,
      );
    }
  }
  return rotation;
}

int _resolveSlideHeadAlpha(
  SimaiGame game,
  double noteTime,
  BaseNoteDrawState state,
) {
  if (state.progress < 1.0) return 255;
  return (255 *
          (1.0 -
              (game.chartTime - noteTime) /
                  SimaiTapJudgementRules.maximumWindowSeconds))
      .clamp(0, 255)
      .round();
}

/// Pass 1：绘制滑星星头引导线、EX 星头外圈光晕以及 WiFi 滑星的底层矢量条。
void _drawSlideVectorPass(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required int collectionIndex,
  required int noteIndex,
  required double noteTime,
  required bool isEach,
  required bool isOpposite,
  required double approachTime,
  required BaseNoteDrawState? state,
  required bool skipHead,
  required Map<double, int>? slideStartCounts,
}) {
  // 1) 星头引导线与 EX 光晕（无头星或已判定头部时跳过）
  if (!skipHead && state != null && state.progress >= 0.0) {
    final Color headColor = _resolveSlideHeadColor(game, note, isEach);
    final int alpha = _resolveSlideHeadAlpha(game, noteTime, state);
    if (state.progress < 1.0) {
      _drawApproachArc(
        canvas,
        game: game,
        progress: state.progress,
        currentRadius: state.currentRadius,
        drawAngle: state.drawAngle,
        color: headColor,
        alpha: alpha,
        connectEach: isEach,
        isOpposite: isOpposite,
      );
    }
    final bool isEx =
        (note.styles & NoteStyles.ex) != 0 && game.highlightExNotes;
    if (isEx && alpha > 0) {
      final double rotation = _resolveSlideHeadRotation(
        game: game,
        note: note,
        collectionIndex: collectionIndex,
        noteIndex: noteIndex,
        state: state,
      );
      _drawStarHighlight(
        canvas,
        position: state.drawPosition,
        color: headColor,
        scale: state.drawScale,
        alpha: alpha,
        rotation: rotation,
        noteScale: game.noteScale,
        noteStyle: game.noteStyle,
      );
    }
  }

  // 2) WiFi / 扇形滑星底层矢量折线
  final session = game.gameplaySession;
  final double drawScale = game.chartRadius / 300.0;
  for (int sIdx = 0; sIdx < note.slidePaths.length; sIdx++) {
    final slidePath = note.slidePaths[sIdx];
    if (!_isFanSlidePath(slidePath)) continue;

    final precalcData =
        game.precalcData.slides['${collectionIndex}_${noteIndex}_$sIdx'];
    if (precalcData == null || precalcData.fanCenterX == null) continue;
    if (session?.isSlideResolved(collectionIndex, noteIndex, sIdx) ?? false) {
      continue;
    }

    final int trackAlpha = _resolveSlideTrackAlpha(
      chartTime: game.chartTime,
      noteTime: noteTime,
      approachTime: approachTime,
    );
    if (trackAlpha == 0) continue;

    final double startTime = noteTime + slidePath.delay;
    double slideP = 0.0;
    if (game.chartTime >= startTime && slidePath.duration > 0) {
      slideP = (game.chartTime - startTime) / slidePath.duration;
      if (session == null && slideP >= 1.0) continue;
    }

    final Color effectiveColor = _resolveSlidePathColor(
      game: game,
      slidePath: slidePath,
      startTime: startTime,
      isEach: isEach,
      slideStartCounts: slideStartCounts,
    );
    _fanArrowPaint
      ..color = effectiveColor.withAlpha(trackAlpha)
      ..strokeWidth = 12.0 * game.noteScale;

    // 在循环外一次性获取滑星 runtime 句柄，循环内 O(1) 判定分组消除状态。
    final Object? slideRuntime = session?.findSlideRuntime(
      collectionIndex,
      noteIndex,
      sIdx,
    );
    final gameplay = precalcData.gameplay;
    final fanCenterX = precalcData.fanCenterX!;
    final fanCenterY = precalcData.fanCenterY!;
    final fanLeftX = precalcData.fanLeftX!;
    final fanLeftY = precalcData.fanLeftY!;
    final fanRightX = precalcData.fanRightX!;
    final fanRightY = precalcData.fanRightY!;
    final leftGroupIds = gameplay.fanLeftGroupIds;
    final centerGroupIds = gameplay.fanCenterGroupIds;
    final rightGroupIds = gameplay.fanRightGroupIds;
    final arrowDistances = precalcData.arrowDistances;

    for (int i = 0; i < arrowDistances.length; i++) {
      final double d = arrowDistances[i];
      if (session == null && d / precalcData.totalLength < slideP) continue;

      if (session != null && slideRuntime != null) {
        final leftGroup = i < leftGroupIds.length ? leftGroupIds[i] : -1;
        final centerGroup = i < centerGroupIds.length ? centerGroupIds[i] : -1;
        final rightGroup = i < rightGroupIds.length ? rightGroupIds[i] : -1;
        final leftCleared =
            leftGroup >= 0 &&
            session.isSlideGroupClearedForRuntime(slideRuntime, leftGroup);
        final centerCleared =
            centerGroup >= 0 &&
            session.isSlideGroupClearedForRuntime(slideRuntime, centerGroup);
        final rightCleared =
            rightGroup >= 0 &&
            session.isSlideGroupClearedForRuntime(slideRuntime, rightGroup);
        if (shouldHideFanArrowSection(
          leftCleared: leftCleared,
          centerCleared: centerCleared,
          rightCleared: rightCleared,
        )) {
          continue;
        }
      }

      final Offset pCenter =
          Offset(fanCenterX[i], fanCenterY[i]) * drawScale + game.chartCenter;
      final Offset pLeft =
          Offset(fanLeftX[i], fanLeftY[i]) * drawScale + game.chartCenter;
      final Offset pRight =
          Offset(fanRightX[i], fanRightY[i]) * drawScale + game.chartCenter;
      if (game.noteStyle.usesEnhancedVisuals) {
        final double mainW = 12.0 * game.noteScale;
        _fanArrowPaint
          ..color = Colors.black.withAlpha((trackAlpha * 0.45).round())
          ..strokeWidth = mainW + 4.0 * game.noteScale;
        canvas.drawLine(pLeft, pCenter, _fanArrowPaint);
        canvas.drawLine(pCenter, pRight, _fanArrowPaint);
        _fanArrowPaint
          ..color = effectiveColor.withAlpha(trackAlpha)
          ..strokeWidth = mainW;
      }
      canvas.drawLine(pLeft, pCenter, _fanArrowPaint);
      canvas.drawLine(pCenter, pRight, _fanArrowPaint);
    }
  }
}

/// Pass 2a：常规滑星轨道箭头改用 `'slide_arrow'` 图集精灵 + RSTransform 颜色调制合批。
void _drawSlideArrowsSpritePass(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required int collectionIndex,
  required int noteIndex,
  required double noteTime,
  required bool isEach,
  required double approachTime,
  required Map<double, int>? slideStartCounts,
}) {
  final session = game.gameplaySession;
  final double drawScale = game.chartRadius / 300.0;
  final bool hasArrowSprite = game.noteAssets.hasAsset('slide_arrow');

  for (int sIdx = 0; sIdx < note.slidePaths.length; sIdx++) {
    final slidePath = note.slidePaths[sIdx];
    if (_isFanSlidePath(slidePath)) continue;

    final precalcData =
        game.precalcData.slides['${collectionIndex}_${noteIndex}_$sIdx'];
    if (precalcData == null || precalcData.arrowX == null) continue;
    if (session?.isSlideResolved(collectionIndex, noteIndex, sIdx) ?? false) {
      continue;
    }

    final int trackAlpha = _resolveSlideTrackAlpha(
      chartTime: game.chartTime,
      noteTime: noteTime,
      approachTime: approachTime,
    );
    if (trackAlpha == 0) continue;

    final double startTime = noteTime + slidePath.delay;
    double startDistance = 0.0;
    if (game.chartTime >= startTime && slidePath.duration > 0) {
      final double slideP = (game.chartTime - startTime) / slidePath.duration;
      if (session == null) {
        if (slideP >= 1.0) continue;
        startDistance = precalcData.totalLength * slideP;
      }
    }

    final Color effectiveColor = _resolveSlidePathColor(
      game: game,
      slidePath: slidePath,
      startTime: startTime,
      isEach: isEach,
      slideStartCounts: slideStartCounts,
    );

    // 箭头循环外一次性取回滑星 runtime，循环内 O(1) 检查消除状态。
    final Object? slideRuntime = session?.findSlideRuntime(
      collectionIndex,
      noteIndex,
      sIdx,
    );
    final arrowDistances = precalcData.arrowDistances;
    final arrowX = precalcData.arrowX!;
    final arrowY = precalcData.arrowY!;
    final arrowAngles = precalcData.arrowAngles!;
    final arrowGroupIds = precalcData.gameplay.arrowGroupIds;

    final double arrowScale = game.noteScale;
    final double spriteSize = NoteAssetManager.slideArrowSpriteSize(arrowScale);
    final bool useBreakDualArrow =
        game.noteStyle.usesEnhancedVisuals &&
        effectiveColor == SimaiColors.slideBreak &&
        game.noteAssets.hasAsset('slide_arrow_break');
    final String arrowKey =
        useBreakDualArrow ? 'slide_arrow_break' : 'slide_arrow';
    final Color? arrowTint = useBreakDualArrow ? null : effectiveColor;
    Path? fallbackArrowPath;
    if (!hasArrowSprite) {
      game.noteAssets.flush(canvas);
      fallbackArrowPath = NoteGeometry.buildSlideArrowPath(arrowScale);
      _slideArrowFallbackPaint.color = effectiveColor.withAlpha(trackAlpha);
    }

    for (int i = 0; i < arrowDistances.length; i++) {
      final double d = arrowDistances[i];
      if (d < startDistance) continue;
      if (session != null &&
          slideRuntime != null &&
          i < arrowGroupIds.length &&
          session.isSlideGroupClearedForRuntime(
            slideRuntime,
            arrowGroupIds[i],
          )) {
        continue;
      }

      final Offset pos =
          Offset(arrowX[i], arrowY[i]) * drawScale + game.chartCenter;
      final double angle = arrowAngles[i];

      if (hasArrowSprite) {
        game.noteAssets.drawSprite(
          canvas,
          key: arrowKey,
          position: pos,
          size: spriteSize,
          rotation: -angle,
          alpha: trackAlpha,
          color: arrowTint,
        );
      } else {
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(-angle);
        canvas.drawPath(fallbackArrowPath!, _slideArrowFallbackPaint);
        canvas.restore();
      }
    }
  }
}

/// Pass 2b：合批绘制滑星星头与沿轨移动的滑星。
void _drawSlideStarsSpritePass(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required int collectionIndex,
  required int noteIndex,
  required double noteTime,
  required bool isEach,
  required double approachTime,
  required BaseNoteDrawState? state,
  required bool skipHead,
  required Map<double, int>? slideStartCounts,
}) {
  // 1) 星头（无头星或已判定头部时跳过；EX 光晕已在 Pass 1 绘制）
  if (!skipHead && state != null && state.progress >= 0.0) {
    final Color headColor = _resolveSlideHeadColor(game, note, isEach);
    final int alpha = _resolveSlideHeadAlpha(game, noteTime, state);
    if (alpha > 0) {
      final double rotation = _resolveSlideHeadRotation(
        game: game,
        note: note,
        collectionIndex: collectionIndex,
        noteIndex: noteIndex,
        state: state,
      );
      _drawStarWithCache(
        canvas,
        game: game,
        position: state.drawPosition,
        color: headColor,
        scale: state.drawScale,
        alpha: alpha,
        rotation: rotation,
        noteScale: game.noteScale,
        highlight: false,
      );
    }
  }

  // 2) 沿轨移动滑星（仅 chartTime >= noteTime 时出现）
  if (game.chartTime < noteTime) return;

  final session = game.gameplaySession;
  final double drawScale = game.chartRadius / 300.0;

  for (int sIdx = 0; sIdx < note.slidePaths.length; sIdx++) {
    final slidePath = note.slidePaths[sIdx];
    final precalcData =
        game.precalcData.slides['${collectionIndex}_${noteIndex}_$sIdx'];
    if (precalcData == null) continue;
    if (session?.isSlideResolved(collectionIndex, noteIndex, sIdx) ?? false) {
      continue;
    }

    final int trackAlpha = _resolveSlideTrackAlpha(
      chartTime: game.chartTime,
      noteTime: noteTime,
      approachTime: approachTime,
    );
    if (trackAlpha == 0) continue;

    final double startTime = noteTime + slidePath.delay;
    if (game.chartTime >= startTime && slidePath.duration > 0) {
      final double slideP = (game.chartTime - startTime) / slidePath.duration;
      if (slideP >= 1.0) continue;
    }

    final Color effectiveColor = _resolveSlidePathColor(
      game: game,
      slidePath: slidePath,
      startTime: startTime,
      isEach: isEach,
      slideStartCounts: slideStartCounts,
    );

    double starScale = 1.0;
    int starAlpha = 255;
    if (game.chartTime < startTime) {
      final double waitDuration = startTime - noteTime;
      if (waitDuration > 0) {
        final double p = (game.chartTime - noteTime) / waitDuration;
        starScale = 0.5 + 0.5 * p.clamp(0.0, 1.0);
        starAlpha = (255 * p).clamp(0, 255).toInt();
      }
    }
    if (starAlpha <= 0) continue;

    final bool isFan = _isFanSlidePath(slidePath);
    if (isFan) {
      if (slidePath.duration <= 0) continue;
      final double p =
          ((game.chartTime - startTime) / slidePath.duration).clamp(0.0, 1.0);
      if (game.chartTime >= startTime && p >= 1.0) continue;

      final sampleCount = precalcData.fanStarCenterX?.length ?? 0;
      if (sampleCount == 0) continue;
      final sampleIndex = _sampleIndex(p, sampleCount);

      final Offset posCenter =
          Offset(
                precalcData.fanStarCenterX![sampleIndex],
                precalcData.fanStarCenterY![sampleIndex],
              ) *
              drawScale +
          game.chartCenter;
      final double angleCenter = precalcData.fanStarCenterAngles![sampleIndex];
      _drawStarWithCache(
        canvas,
        game: game,
        position: posCenter,
        color: effectiveColor,
        scale: starScale,
        alpha: starAlpha,
        rotation: game.rotateSlideStar ? -angleCenter : -pi / 2,
        noteScale: game.noteScale,
      );

      final Offset posLeft =
          Offset(
                precalcData.fanStarLeftX![sampleIndex],
                precalcData.fanStarLeftY![sampleIndex],
              ) *
              drawScale +
          game.chartCenter;
      final double angleLeft = precalcData.fanStarLeftAngles![sampleIndex];
      _drawStarWithCache(
        canvas,
        game: game,
        position: posLeft,
        color: effectiveColor,
        scale: starScale,
        alpha: starAlpha,
        rotation: game.rotateSlideStar ? -angleLeft : -pi / 2,
        noteScale: game.noteScale,
      );

      final Offset posRight =
          Offset(
                precalcData.fanStarRightX![sampleIndex],
                precalcData.fanStarRightY![sampleIndex],
              ) *
              drawScale +
          game.chartCenter;
      final double angleRight = precalcData.fanStarRightAngles![sampleIndex];
      _drawStarWithCache(
        canvas,
        game: game,
        position: posRight,
        color: effectiveColor,
        scale: starScale,
        alpha: starAlpha,
        rotation: game.rotateSlideStar ? -angleRight : -pi / 2,
        noteScale: game.noteScale,
      );
    } else {
      double p = 0.0;
      if (slidePath.duration > 0) {
        p = ((game.chartTime - startTime) / slidePath.duration).clamp(0.0, 1.0);
      }
      if (game.chartTime >= startTime && p >= 1.0) continue;

      final starX = precalcData.starX;
      if (starX == null || starX.isEmpty) continue;
      final sampleIndex = _sampleIndex(p, starX.length);
      final Offset pos =
          Offset(starX[sampleIndex], precalcData.starY![sampleIndex]) *
              drawScale +
          game.chartCenter;
      final double angle = precalcData.starAngles![sampleIndex];

      _drawStarWithCache(
        canvas,
        game: game,
        position: pos,
        color: effectiveColor,
        scale: starScale,
        alpha: starAlpha,
        rotation: game.rotateSlideStar ? -angle : -pi / 2,
        noteScale: game.noteScale,
      );
    }
  }
}

double _slideApproachRotation({
  required double progress,
  required double pathLength,
  required double duration,
  double approachTime = 1.0,
}) {
  final safeProgress = progress.isFinite ? max(0.0, progress) : 0.0;
  final safeLength = pathLength.isFinite ? max(0.0, pathLength) : 0.0;
  final safeDuration = duration.isFinite ? max(0.0, duration) : 0.0;
  if (safeLength <= 0.0 ||
      safeDuration <= 0.0 ||
      !approachTime.isFinite ||
      approachTime <= 0.0) {
    return 0.0;
  }
  // 按 480 半径基准长度与时长换算角速度，逆时针旋转且封顶 1.08°/ms。
  final normalizedLength = safeLength * (480.0 / 300.0);
  final radiansPerSecond = min(normalizedLength * 0.005 / safeDuration, 6 * pi);
  return -radiansPerSecond * safeProgress * approachTime;
}
