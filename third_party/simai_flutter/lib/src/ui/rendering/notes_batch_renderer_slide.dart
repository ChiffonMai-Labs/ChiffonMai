part of 'notes_batch_renderer.dart';

/// A Wifi/Fan arrow section follows the least-complete branch. The whole
/// section disappears only after left, center and right have all reached it.
bool shouldHideFanArrowSection({
  required bool leftCleared,
  required bool centerCleared,
  required bool rightCleared,
}) => leftCleared && centerCleared && rightCleared;

void _drawSlide(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required int collectionIndex,
  required int noteIndex,
  required double noteTime,
  required bool isEach,
  required bool isOpposite,
  required BaseNoteDrawState state,
  required Map<double, int>? slideStartCounts,
}) {
  final bool headIsBreak = (note.styles & NoteStyles.breakHead) != 0;
  final bool isEx = (note.styles & NoteStyles.ex) != 0 && game.highlightExNotes;

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

  final Color trackBaseColor = isEach
      ? SimaiColors.slideEach
      : SimaiColors.slideNormal;

  final session = game.gameplaySession;
  final headResolved =
      session?.isHeadResolved(collectionIndex, noteIndex) ?? false;
  final lateHeadVisible =
      session != null &&
      game.chartTime <= noteTime + SimaiTapJudgementRules.maximumWindowSeconds;
  final headVisible =
      state.progress >= 0.0 &&
      !headResolved &&
      (state.progress < 1.0 || lateHeadVisible);
  final int alpha = state.progress < 1.0
      ? 255
      : (255 *
                (1.0 -
                    (game.chartTime - noteTime) /
                        SimaiTapJudgementRules.maximumWindowSeconds))
            .clamp(0, 255)
            .round();

  if (headVisible) {
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
    // Cached stars point right; the reference's unrotated star points up.
    double rotation = -pi / 2;
    if (game.rotateSlideStar && note.slidePaths.isNotEmpty) {
      // Split slides use their first trajectory for head rotation.
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
    _drawStarWithCache(
      canvas,
      game: game,
      position: state.drawPosition,
      color: headColor,
      scale: state.drawScale,
      alpha: alpha,
      rotation: rotation,
      noteScale: game.noteScale,
      highlight: isEx,
    );
  }

  _drawSlidePaths(
    canvas,
    game: game,
    note: note,
    collectionIndex: collectionIndex,
    noteIndex: noteIndex,
    noteTime: noteTime,
    isEach: isEach,
    color: trackBaseColor,
    approachTime: state.approachTime,
    slideStartCounts: slideStartCounts,
  );
}

void _drawSlidePaths(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required int collectionIndex,
  required int noteIndex,
  required double noteTime,
  required bool isEach,
  required Color color,
  required double approachTime,
  required Map<double, int>? slideStartCounts,
}) {
  for (int sIdx = 0; sIdx < note.slidePaths.length; sIdx++) {
    final slidePath = note.slidePaths[sIdx];
    final String precalcKey = '${collectionIndex}_${noteIndex}_$sIdx';
    final precalcData = game.precalcData.slides[precalcKey];
    if (precalcData == null) continue;
    final session = game.gameplaySession;
    if (session?.isSlideResolved(collectionIndex, noteIndex, sIdx) ?? false) {
      continue;
    }

    final double startTime = noteTime + slidePath.delay;

    Color effectiveColor = color;

    if (slidePath.type == NoteType.breakNote && !game.standardBreakSlide) {
      effectiveColor = SimaiColors.slideBreak;
    } else {
      final double key = (startTime * 1000).round() / 1000.0;
      final int count = slideStartCounts?[key] ?? 0;
      if (count > 1) {
        effectiveColor = SimaiColors.slideEach;
      } else if (color == SimaiColors.slideEach ||
          color == SimaiColors.slideNormal) {
        effectiveColor = SimaiColors.slideNormal;
      }
    }

    int trackAlpha = 255;
    double strokeScale = 1.0;

    if (game.chartTime < noteTime) {
      final double p = 1.0 - (noteTime - game.chartTime) / approachTime;
      trackAlpha = (255 * p).clamp(0, 255).toInt();
    } else if (game.chartTime < startTime) {
      trackAlpha = 255;
      strokeScale = 1.0;
    } else {
      trackAlpha = 255;
    }

    if (trackAlpha == 0) continue;

    double startDistance = 0.0;
    double slideP = 0.0;
    if (game.chartTime >= startTime) {
      if (slidePath.duration > 0) {
        slideP = (game.chartTime - startTime) / slidePath.duration;
        if (session == null) {
          startDistance = precalcData.totalLength * slideP;
        }

        if (session == null && slideP >= 1.0) continue;
      }
    }

    if (trackAlpha > 0) {
      game.noteAssets.flush(canvas);
      final double arrowScale = strokeScale * game.noteScale;

      final Paint fanArrowPaint = Paint()
        ..color = effectiveColor.withAlpha(trackAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0 * arrowScale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final Paint slideArrowPaint = Paint()
        ..isAntiAlias = true
        ..color = effectiveColor.withAlpha(trackAlpha)
        ..style = PaintingStyle.fill;

      final bool isFan = slidePath.segments.any(
        (s) => s.slideType == SlideType.fan,
      );
      final double drawScale =
          game.chartRadius / 300.0; // scale factor from normalized space

      if (isFan && precalcData.fanCenterX != null) {
        for (int i = 0; i < precalcData.arrowDistances.length; i++) {
          final double d = precalcData.arrowDistances[i];
          final double p = d / precalcData.totalLength;
          if (session == null && p < slideP) continue;

          final Offset pCenter =
              Offset(precalcData.fanCenterX![i], precalcData.fanCenterY![i]) *
                  drawScale +
              game.chartCenter;
          final Offset pLeft =
              Offset(precalcData.fanLeftX![i], precalcData.fanLeftY![i]) *
                  drawScale +
              game.chartCenter;
          final Offset pRight =
              Offset(precalcData.fanRightX![i], precalcData.fanRightY![i]) *
                  drawScale +
              game.chartCenter;

          final gameplay = precalcData.gameplay;
          final leftGroup = i < gameplay.fanLeftGroupIds.length
              ? gameplay.fanLeftGroupIds[i]
              : -1;
          final centerGroup = i < gameplay.fanCenterGroupIds.length
              ? gameplay.fanCenterGroupIds[i]
              : -1;
          final rightGroup = i < gameplay.fanRightGroupIds.length
              ? gameplay.fanRightGroupIds[i]
              : -1;
          bool cleared(int groupId) =>
              session != null &&
              groupId >= 0 &&
              session.isSlideInteractionGroupCleared(
                collectionIndex,
                noteIndex,
                sIdx,
                groupId,
              );
          final leftCleared = cleared(leftGroup);
          final centerCleared = cleared(centerGroup);
          final rightCleared = cleared(rightGroup);
          final sectionCleared = shouldHideFanArrowSection(
            leftCleared: leftCleared,
            centerCleared: centerCleared,
            rightCleared: rightCleared,
          );
          if (!sectionCleared) {
            canvas.drawLine(pLeft, pCenter, fanArrowPaint);
            canvas.drawLine(pCenter, pRight, fanArrowPaint);
          }
        }
      } else if (precalcData.arrowX != null) {
        final arrowPath = NoteGeometry.buildSlideArrowPath(arrowScale);
        for (int i = 0; i < precalcData.arrowDistances.length; i++) {
          final double d = precalcData.arrowDistances[i];
          if (d < startDistance) continue;
          if (session != null &&
              i < precalcData.gameplay.arrowGroupIds.length &&
              session.isSlideInteractionGroupCleared(
                collectionIndex,
                noteIndex,
                sIdx,
                precalcData.gameplay.arrowGroupIds[i],
              )) {
            continue;
          }

          final Offset pos =
              Offset(precalcData.arrowX![i], precalcData.arrowY![i]) *
                  drawScale +
              game.chartCenter;
          final double angle = precalcData.arrowAngles![i];

          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(-angle);
          canvas.drawPath(arrowPath, slideArrowPaint);
          canvas.restore();
        }
      }
    }

    if (game.chartTime >= noteTime) {
      double starScale = 1.0;
      int starAlpha = 255;
      double starRotation = 0.0;

      if (game.chartTime < startTime) {
        final double waitDuration = startTime - noteTime;
        if (waitDuration > 0) {
          final double p = (game.chartTime - noteTime) / waitDuration;
          starScale = 0.5 + 0.5 * p.clamp(0.0, 1.0);
          starAlpha = (255 * p).clamp(0, 255).toInt();
        }
      } else if (game.chartTime >= startTime) {
        starScale = 1.0;
        starAlpha = 255;
        starRotation = 0.0;
      }

      if (starAlpha > 0) {
        final bool isFan = slidePath.segments.any(
          (s) => s.slideType == SlideType.fan,
        );
        final double drawScale = game.chartRadius / 300.0;

        if (isFan) {
          if (slidePath.duration > 0) {
            double p = (game.chartTime - startTime) / slidePath.duration;
            p = p.clamp(0.0, 1.0);
            if (game.chartTime >= startTime && p >= 1.0) continue;

            final sampleCount = precalcData.fanStarCenterX?.length ?? 0;
            if (sampleCount == 0) continue;
            final sampleIndex = _sampleIndex(p, sampleCount);

            if (precalcData.fanStarCenterX != null) {
              final Offset posCenter =
                  Offset(
                        precalcData.fanStarCenterX![sampleIndex],
                        precalcData.fanStarCenterY![sampleIndex],
                      ) *
                      drawScale +
                  game.chartCenter;
              final double angleCenter =
                  precalcData.fanStarCenterAngles![sampleIndex];
              _drawStarWithCache(
                canvas,
                game: game,
                position: posCenter,
                color: effectiveColor,
                scale: starScale,
                alpha: starAlpha,
                rotation: game.rotateSlideStar
                    ? starRotation - angleCenter
                    : -pi / 2,
                noteScale: game.noteScale,
              );

              final Offset posLeft =
                  Offset(
                        precalcData.fanStarLeftX![sampleIndex],
                        precalcData.fanStarLeftY![sampleIndex],
                      ) *
                      drawScale +
                  game.chartCenter;
              final double angleLeft =
                  precalcData.fanStarLeftAngles![sampleIndex];
              _drawStarWithCache(
                canvas,
                game: game,
                position: posLeft,
                color: effectiveColor,
                scale: starScale,
                alpha: starAlpha,
                rotation: game.rotateSlideStar
                    ? starRotation - angleLeft
                    : -pi / 2,
                noteScale: game.noteScale,
              );

              final Offset posRight =
                  Offset(
                        precalcData.fanStarRightX![sampleIndex],
                        precalcData.fanStarRightY![sampleIndex],
                      ) *
                      drawScale +
                  game.chartCenter;
              final double angleRight =
                  precalcData.fanStarRightAngles![sampleIndex];
              _drawStarWithCache(
                canvas,
                game: game,
                position: posRight,
                color: effectiveColor,
                scale: starScale,
                alpha: starAlpha,
                rotation: game.rotateSlideStar
                    ? starRotation - angleRight
                    : -pi / 2,
                noteScale: game.noteScale,
              );
            }
          }
        } else {
          double p = 0.0;
          if (slidePath.duration > 0) {
            p = (game.chartTime - startTime) / slidePath.duration;
            p = p.clamp(0.0, 1.0);
          }
          if (game.chartTime >= startTime && p >= 1.0) continue;

          if (precalcData.starX != null) {
            final sampleCount = precalcData.starX!.length;
            if (sampleCount == 0) continue;
            final sampleIndex = _sampleIndex(p, sampleCount);
            final Offset pos =
                Offset(
                      precalcData.starX![sampleIndex],
                      precalcData.starY![sampleIndex],
                    ) *
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
              rotation: game.rotateSlideStar ? starRotation - angle : -pi / 2,
              noteScale: game.noteScale,
            );
          }
        }
      }
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
  // Reference: (length in 480-radius units / pi / durationMs) * 0.9
  // degrees/ms, capped at 1.08 degrees/ms, rotating counterclockwise.
  final normalizedLength = safeLength * (480.0 / 300.0);
  final radiansPerSecond = min(normalizedLength * 0.005 / safeDuration, 6 * pi);
  return -radiansPerSecond * safeProgress * approachTime;
}
