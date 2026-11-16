part of 'notes_batch_renderer.dart';

void _drawHold(
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
  if (note.location.group != NoteGroup.tap) return;

  final bool isBreak =
      note.type == NoteType.breakNote || (note.styles & NoteStyles.mine) != 0;
  final bool isEx = (note.styles & NoteStyles.ex) != 0 && game.highlightExNotes;

  final Color baseColor = isBreak
      ? SimaiColors.holdBreak
      : (isEach ? SimaiColors.holdEach : SimaiColors.holdNormal);

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

  final double duration = note.length ?? 0;
  final double endTime = noteTime + duration;
  if (game.chartTime >= endTime) return;

  final double tailProgressRaw =
      1.0 - (endTime - game.chartTime) / state.approachTime;

  final double startRadius =
      game.chartRadius * BaseNoteComponent.initialRadiusRatio;

  double tailMovementProgress(double p) {
    if (p < BaseNoteComponent.scaleInProgressRatio) return 0.0;
    return ((p - BaseNoteComponent.scaleInProgressRatio) /
            (1.0 - BaseNoteComponent.scaleInProgressRatio))
        .clamp(0.0, 1.0);
  }

  final double tm = tailMovementProgress(tailProgressRaw);
  final double tailRadius = startRadius + (game.chartRadius - startRadius) * tm;

  final Offset tailPos = Offset(
    game.chartCenter.dx + tailRadius * cos(state.drawAngle),
    game.chartCenter.dy + tailRadius * sin(state.drawAngle),
  );

  game.noteAssets.flush(canvas);
  _drawHoldHexagon(
    canvas,
    head: state.drawPosition,
    tail: tailPos,
    rotation: state.drawAngle,
    color: baseColor,
    scale: state.drawScale,
    alpha: alpha,
    noteScale: game.noteScale,
    highlight: isEx,
  );
}

void _drawHoldHexagon(
  Canvas canvas, {
  required Offset head,
  required Offset tail,
  required double rotation,
  required Color color,
  required double scale,
  required int alpha,
  required double noteScale,
  required bool highlight,
}) {
  final double thickness =
      NoteGeometry.tapStarHoldRadius * 2 * scale * noteScale;
  final double outerRadius = thickness / 2;

  final double dx = head.dx - tail.dx;
  final double dy = head.dy - tail.dy;
  final double angle = (dx.abs() < 0.001 && dy.abs() < 0.001)
      ? rotation
      : atan2(dy, dx);

  List<Offset> getHexVertices(Offset center, double r, double a) {
    final List<Offset> points = [];
    for (int i = 0; i < 6; i++) {
      final double theta = a + i * pi / 3;
      points.add(
        Offset(center.dx + r * cos(theta), center.dy + r * sin(theta)),
      );
    }
    return points;
  }

  List<Offset> getHull(List<Offset> h, List<Offset> t) {
    return [t[2], h[2], h[1], h[0], h[5], t[5], t[4], t[3]];
  }

  final List<Offset> outerHead = getHexVertices(head, outerRadius, angle);
  final List<Offset> outerTail = getHexVertices(tail, outerRadius, angle);
  final List<Offset> outerHullPoints = getHull(outerHead, outerTail);

  if (highlight && alpha > 0) {
    final Paint highlightPaint = Paint()
      ..color = color.withAlpha((alpha * 0.4).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 * scale * noteScale
      ..strokeJoin = StrokeJoin.round;

    final List<Offset> highlightHead = getHexVertices(
      head,
      outerRadius + 6.0 * scale * noteScale,
      angle,
    );
    final List<Offset> highlightTail = getHexVertices(
      tail,
      outerRadius + 6.0 * scale * noteScale,
      angle,
    );
    final List<Offset> highlightHullPoints = getHull(
      highlightHead,
      highlightTail,
    );

    final Path highlightPath = Path()..addPolygon(highlightHullPoints, true);
    canvas.drawPath(highlightPath, highlightPaint);
  }

  const double innerRatio = 0.7;
  final double innerRadius = outerRadius * innerRatio;

  final List<Offset> innerHead = getHexVertices(head, innerRadius, angle);
  final List<Offset> innerTail = getHexVertices(tail, innerRadius, angle);

  final List<Offset> innerHullPoints = getHull(innerHead, innerTail);

  final Path path = Path()
    ..fillType = PathFillType.evenOdd
    ..addPolygon(outerHullPoints, true)
    ..addPolygon(innerHullPoints, true);

  final Paint paint = Paint()
    ..color = color.withAlpha(alpha)
    ..style = PaintingStyle.fill;
  canvas.drawPath(path, paint);

  final Paint strokePaint = Paint()
    ..color = Colors.white.withAlpha(alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0 * scale * noteScale
    ..strokeJoin = StrokeJoin.round;

  final Path outerPath = Path()..addPolygon(outerHullPoints, true);
  final Path innerPath = Path()..addPolygon(innerHullPoints, true);
  canvas.drawPath(outerPath, strokePaint);
  canvas.drawPath(innerPath, strokePaint);

  final double dotRadius = 5.0 * scale * noteScale;
  canvas.drawCircle(head, dotRadius, paint);
  canvas.drawCircle(tail, dotRadius, paint);
}
