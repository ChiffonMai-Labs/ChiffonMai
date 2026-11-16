part of 'notes_batch_renderer.dart';

void _drawTap(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required double noteTime,
  required int collectionIndex,
  required int noteIndex,
  required bool isEach,
  required bool isOpposite,
  required BaseNoteDrawState state,
}) {
  if (state.progress < 0.0) return;
  final session = game.gameplaySession;
  if (session?.isHeadResolved(collectionIndex, noteIndex) ?? false) return;
  if (state.progress >= 1.0 && session == null) return;
  if (session != null &&
      game.chartTime > noteTime + SimaiTapJudgementRules.maximumWindowSeconds) {
    return;
  }

  var drawPosition = state.drawPosition;
  var drawScale = state.drawScale;
  if (session != null && state.progress >= 1.0) {
    final drawRadius = _tapRadiusAfterJudge(
      chartRadius: game.chartRadius,
      approachTime: state.approachTime,
      lateSeconds: game.chartTime - noteTime,
    );
    drawPosition =
        game.chartCenter +
        Offset(cos(state.drawAngle), sin(state.drawAngle)) * drawRadius;
    drawScale = 1.0;
  }

  final bool isBreak =
      note.type == NoteType.breakNote || (note.styles & NoteStyles.mine) != 0;
  final bool isEx = (note.styles & NoteStyles.ex) != 0 && game.highlightExNotes;

  Color baseColor;
  if (note.type == NoteType.breakNote) {
    baseColor = SimaiColors.tapBreak;
  } else {
    baseColor = isBreak
        ? SimaiColors.tapBreak
        : (isEach ? SimaiColors.tapEach : SimaiColors.tapNormal);
  }

  const int alpha = 255;

  if (state.progress < 1.0) {
    _drawApproachArc(
      canvas,
      game: game,
      progress: state.progress,
      currentRadius: state.currentRadius,
      drawAngle: state.drawAngle,
      color: baseColor,
      alpha: alpha,
      connectEach: isEach,
      isOpposite: isOpposite,
    );
  }

  String key;
  if (note.type == NoteType.breakNote) {
    key = 'tap_break';
  } else if (isBreak) {
    key = 'tap_break';
  } else if (isEach) {
    key = 'tap_each';
  } else {
    key = 'tap_normal';
  }

  if (game.noteAssets.hasAsset(key)) {
    if (isEx) {
      game.noteAssets.flush(canvas);
      _drawTapHighlight(
        canvas,
        position: drawPosition,
        color: baseColor,
        scale: drawScale,
        alpha: alpha,
        noteScale: game.noteScale,
      );
    }

    final double baseSize = 110.0 * game.noteScale;
    final double size = baseSize * drawScale;
    if (game.noteAssets.drawSpriteDirect(
      canvas,
      key: key,
      position: drawPosition,
      size: size,
      alpha: alpha,
    )) {
      return;
    }
  }

  game.noteAssets.flush(canvas);
  _drawTapBody(
    canvas,
    position: drawPosition,
    color: baseColor,
    scale: drawScale,
    alpha: alpha,
    noteScale: game.noteScale,
    highlight: isEx,
  );
}

double _tapRadiusAfterJudge({
  required double chartRadius,
  required double approachTime,
  required double lateSeconds,
}) {
  if (!chartRadius.isFinite || chartRadius <= 0) return 0.0;
  final safeApproachTime = approachTime.isFinite
      ? max(approachTime, 0.001)
      : 0.001;
  final safeLateSeconds = lateSeconds.isFinite ? max(0.0, lateSeconds) : 0.0;
  return chartRadius * (1.0 + 1.5 * safeLateSeconds / safeApproachTime);
}

void _drawTapHighlight(
  Canvas canvas, {
  required Offset position,
  required Color color,
  required double scale,
  required int alpha,
  required double noteScale,
}) {
  final double outerRadius = NoteGeometry.tapStarHoldRadius * scale * noteScale;
  final Paint highlightPaint = Paint()
    ..color = color.withAlpha((alpha * 0.4).toInt())
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12.0 * scale * noteScale;
  canvas.drawCircle(
    position,
    outerRadius + 4.0 * scale * noteScale,
    highlightPaint,
  );
}

void _drawTapBody(
  Canvas canvas, {
  required Offset position,
  required Color color,
  required double scale,
  required int alpha,
  required double noteScale,
  required bool highlight,
}) {
  final double outerRadius = NoteGeometry.tapStarHoldRadius * scale * noteScale;

  if (highlight && alpha > 0) {
    final Paint highlightPaint = Paint()
      ..color = color.withAlpha((alpha * 0.4).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 * scale * noteScale;
    canvas.drawCircle(
      position,
      outerRadius + 4.0 * scale * noteScale,
      highlightPaint,
    );
  }

  const double innerRatio = 0.65;
  final double innerRadius = outerRadius * innerRatio;

  final Paint paint = Paint()
    ..color = color.withAlpha(alpha)
    ..style = PaintingStyle.fill;

  final Path path = Path()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: position, radius: outerRadius))
    ..addOval(Rect.fromCircle(center: position, radius: innerRadius));
  canvas.drawPath(path, paint);

  final Paint strokePaint = Paint()
    ..color = Colors.white.withAlpha(alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0 * scale * noteScale;
  canvas.drawCircle(position, outerRadius, strokePaint);
  canvas.drawCircle(position, innerRadius, strokePaint);

  final double dotRadius = 4.0 * scale * noteScale;
  canvas.drawCircle(position, dotRadius, paint);
}
