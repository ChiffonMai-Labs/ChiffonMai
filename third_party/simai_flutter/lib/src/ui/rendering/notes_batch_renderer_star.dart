part of 'notes_batch_renderer.dart';

void _drawStarWithCache(
  Canvas canvas, {
  required SimaiGame game,
  required Offset position,
  required Color color,
  required double scale,
  required int alpha,
  required double rotation,
  required double noteScale,
  bool highlight = false,
}) {
  String key;
  if (color == SimaiColors.slideNormal) {
    key = 'star_normal';
  } else if (color == SimaiColors.slideEach) {
    key = 'star_each';
  } else if (color == SimaiColors.slideBreak) {
    key = 'star_break';
  } else if (color == SimaiColors.tapNormal) {
    key = 'star_tap_normal';
  } else if (color == SimaiColors.tapEach) {
    key = 'star_tap_each';
  } else if (color == SimaiColors.tapBreak) {
    key = 'tap_break';
  } else {
    key = 'star_normal';
  }

  if (key == 'tap_break') {
    game.noteAssets.flush(canvas);
    _drawStar(
      canvas,
      position: position,
      color: color,
      scale: scale,
      alpha: alpha,
      rotation: rotation,
      noteScale: noteScale,
      highlight: highlight,
    );
    return;
  }

  if (game.noteAssets.hasAsset(key)) {
    if (highlight) {
      game.noteAssets.flush(canvas);
      _drawStarHighlight(
        canvas,
        position: position,
        color: color,
        scale: scale,
        alpha: alpha,
        rotation: rotation,
        noteScale: noteScale,
      );
    }

    final double baseSize = 110.0 * noteScale;
    final double size = baseSize * scale;
    if (game.noteAssets.drawSprite(
      canvas,
      key: key,
      position: position,
      size: size,
      rotation: rotation,
      alpha: alpha,
    )) {
      return;
    }
  }

  game.noteAssets.flush(canvas);
  _drawStar(
    canvas,
    position: position,
    color: color,
    scale: scale,
    alpha: alpha,
    rotation: rotation,
    noteScale: noteScale,
    highlight: highlight,
  );
}

void _drawStarHighlight(
  Canvas canvas, {
  required Offset position,
  required Color color,
  required double scale,
  required int alpha,
  required double rotation,
  required double noteScale,
}) {
  final Paint highlightPaint = Paint()
    ..color = color.withAlpha((alpha * 0.4).toInt())
    ..style = PaintingStyle.stroke
    ..strokeWidth = 12.0 * scale * noteScale
    ..strokeJoin = StrokeJoin.round;

  final Path highlightStarPath = NoteUtils.createStarPath(
    NoteGeometry.tapStarHoldRadius * scale * noteScale +
        6.0 * scale * noteScale,
  );
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(rotation);
  canvas.drawPath(highlightStarPath, highlightPaint);
  canvas.restore();
}

void _drawStar(
  Canvas canvas, {
  required Offset position,
  required Color color,
  required double scale,
  required int alpha,
  required double rotation,
  required double noteScale,
  required bool highlight,
}) {
  final double radius = NoteGeometry.tapStarHoldRadius * scale * noteScale;

  if (highlight && alpha > 0) {
    final Paint highlightPaint = Paint()
      ..color = color.withAlpha((alpha * 0.4).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0 * scale * noteScale
      ..strokeJoin = StrokeJoin.round;

    final Path highlightStarPath = NoteUtils.createStarPath(
      radius + 6.0 * scale * noteScale,
    );
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    canvas.drawPath(highlightStarPath, highlightPaint);
    canvas.restore();
  }

  const double innerRatio = 0.6;
  final Path outerPath = NoteUtils.createStarPath(radius);
  final Path innerPath = NoteUtils.createStarPath(radius * innerRatio);

  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(rotation);

  final Paint paint = Paint()
    ..color = color.withAlpha(alpha)
    ..style = PaintingStyle.fill;

  final Path combinedPath = Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(outerPath, Offset.zero)
    ..addPath(innerPath, Offset.zero);
  canvas.drawPath(combinedPath, paint);

  final Paint strokePaint = Paint()
    ..color = Colors.white.withAlpha(alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0 * scale * noteScale
    ..strokeJoin = StrokeJoin.round;

  canvas.drawPath(outerPath, strokePaint);
  canvas.drawPath(innerPath, strokePaint);
  canvas.restore();
}
