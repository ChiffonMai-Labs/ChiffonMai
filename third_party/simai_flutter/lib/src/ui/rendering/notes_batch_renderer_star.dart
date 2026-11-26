part of 'notes_batch_renderer.dart';

// 复用星星 EX 光晕与降级画笔。
final Paint _starHighlightPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

final Paint _starExFillPaint = Paint()
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

final Path _starExRingPath = Path()..fillType = PathFillType.evenOdd;

final Paint _starFallbackFillPaint = Paint()
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

final Paint _starFallbackStrokePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

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
    // 修复 pinkSlideStar && breakHead 此前误映射为 tap_break 并回退矢量绘制的问题，统一走图集。
    key = 'star_tap_break';
  } else {
    key = 'star_normal';
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

    final double size = NoteAssetManager.cellExtent * noteScale * scale;
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
  SimaiNoteStyle noteStyle = SimaiNoteStyle.classic,
}) {
  final double outerRadius = NoteGeometry.tapStarHoldRadius * scale * noteScale;
  if (noteStyle == SimaiNoteStyle.arcade) {
    final Path outerEx = NoteUtils.createStarPath(outerRadius * 1.19);
    final Path innerStar = NoteUtils.createStarPath(outerRadius);
    _starExRingPath
      ..reset()
      ..fillType = PathFillType.evenOdd
      ..addPath(outerEx, Offset.zero)
      ..addPath(innerStar, Offset.zero);
    _starExFillPaint.color = color.withAlpha((alpha * 0.72).round().clamp(0, 255));
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    canvas.drawPath(_starExRingPath, _starExFillPaint);
    canvas.restore();
    return;
  }

  _starHighlightPaint
    ..color = color.withAlpha((alpha * 0.4).toInt())
    ..strokeWidth = 12.0 * scale * noteScale;

  final Path highlightStarPath = NoteUtils.createStarPath(
    outerRadius + 6.0 * scale * noteScale,
  );
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(rotation);
  canvas.drawPath(highlightStarPath, _starHighlightPaint);
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

  const double innerRatio = 0.6;
  final Path outerPath = NoteUtils.createStarPath(radius);
  final Path innerPath = NoteUtils.createStarPath(radius * innerRatio);

  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.rotate(rotation);

  _starFallbackFillPaint.color = color.withAlpha(alpha);

  final Path combinedPath = Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(outerPath, Offset.zero)
    ..addPath(innerPath, Offset.zero);
  canvas.drawPath(combinedPath, _starFallbackFillPaint);

  _starFallbackStrokePaint
    ..color = Colors.white.withAlpha(alpha)
    ..strokeWidth = 2.0 * scale * noteScale;

  canvas.drawPath(outerPath, _starFallbackStrokePaint);
  canvas.drawPath(innerPath, _starFallbackStrokePaint);
  canvas.restore();
}
