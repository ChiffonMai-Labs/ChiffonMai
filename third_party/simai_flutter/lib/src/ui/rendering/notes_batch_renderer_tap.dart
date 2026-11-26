part of 'notes_batch_renderer.dart';

// 复用 Tap EX 光晕与降级画笔，避免热路径分配。
final Paint _tapHighlightPaint = Paint()
  ..style = PaintingStyle.stroke
  ..isAntiAlias = true;

final Paint _tapExRingFillPaint = Paint()
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

final Path _tapExRingPath = Path();

final Paint _tapFallbackFillPaint = Paint()
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

final Paint _tapFallbackStrokePaint = Paint()
  ..style = PaintingStyle.stroke
  ..isAntiAlias = true;

final Path _tapFallbackPath = Path()..fillType = PathFillType.evenOdd;

Color _resolveTapColor(Note note, bool isEach) {
  final bool isBreak =
      note.type == NoteType.breakNote || (note.styles & NoteStyles.mine) != 0;
  if (note.type == NoteType.breakNote || isBreak) {
    return SimaiColors.tapBreak;
  }
  return isEach ? SimaiColors.tapEach : SimaiColors.tapNormal;
}

String _resolveTapAssetKey(Note note, bool isEach) {
  final bool isBreak =
      note.type == NoteType.breakNote || (note.styles & NoteStyles.mine) != 0;
  if (note.type == NoteType.breakNote || isBreak) {
    return 'tap_break';
  }
  return isEach ? 'tap_each' : 'tap_normal';
}

/// Pass 1：绘制 Tap 引导线与 EX 外圈光晕，保证位于 Pass 2 Tap 精灵之下且不打断合批。
void _drawTapVectorPass(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required double noteTime,
  required bool isEach,
  required bool isOpposite,
  required BaseNoteDrawState state,
}) {
  if (state.progress < 0.0) return;

  final Color baseColor = _resolveTapColor(note, isEach);
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

  final bool isEx = (note.styles & NoteStyles.ex) != 0 && game.highlightExNotes;
  if (!isEx) return;

  var drawPosition = state.drawPosition;
  var drawScale = state.drawScale;
  if (game.gameplaySession != null && state.progress >= 1.0) {
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

  _drawTapHighlight(
    canvas,
    position: drawPosition,
    color: baseColor,
    scale: drawScale,
    alpha: alpha,
    noteScale: game.noteScale,
    noteStyle: game.noteStyle,
    isBreak:
        note.type == NoteType.breakNote ||
        (note.styles & NoteStyles.mine) != 0,
    isEach: isEach,
  );
}

/// Pass 2：将 Tap 主体送入 SpriteBatch 合批，不再逐个 drawSpriteDirect 强制 flush。
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

  const int alpha = 255;
  final String key = _resolveTapAssetKey(note, isEach);
  final double size = NoteAssetManager.cellExtent * game.noteScale * drawScale;
  final double rotation =
      game.noteStyle == SimaiNoteStyle.arcade ? state.drawAngle : 0.0;

  if (game.noteAssets.drawSprite(
    canvas,
    key: key,
    position: drawPosition,
    size: size,
    rotation: rotation,
    alpha: alpha,
  )) {
    return;
  }

  // 图集不可用时的矢量降级分支（EX 光晕已在 Pass 1 绘制，此处不再重复）。
  final Color baseColor = _resolveTapColor(note, isEach);
  game.noteAssets.flush(canvas);
  _drawTapBody(
    canvas,
    position: drawPosition,
    color: baseColor,
    scale: drawScale,
    alpha: alpha,
    noteScale: game.noteScale,
    highlight: false,
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
  SimaiNoteStyle noteStyle = SimaiNoteStyle.classic,
  bool isBreak = false,
  bool isEach = false,
}) {
  final double outerRadius = NoteGeometry.tapStarHoldRadius * scale * noteScale;
  if (noteStyle == SimaiNoteStyle.arcade) {
    final double exOuterRadius = outerRadius * 1.19;
    final Color exColor = isBreak
        ? SimaiVisualTokens.colorExOverlayBreak
        : (isEach
              ? SimaiVisualTokens.colorExOverlaySimultaneous
              : SimaiVisualTokens.colorExOverlayNormal);
    _tapExRingFillPaint.color = exColor.withAlpha(
      (exColor.a * alpha).round().clamp(0, 255),
    );
    _tapExRingPath
      ..reset()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: position, radius: exOuterRadius))
      ..addOval(Rect.fromCircle(center: position, radius: outerRadius));
    canvas.drawPath(_tapExRingPath, _tapExRingFillPaint);
    return;
  }
  _tapHighlightPaint
    ..color = color.withAlpha((alpha * 0.4).toInt())
    ..strokeWidth = 12.0 * scale * noteScale;
  canvas.drawCircle(
    position,
    outerRadius + 4.0 * scale * noteScale,
    _tapHighlightPaint,
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
    _drawTapHighlight(
      canvas,
      position: position,
      color: color,
      scale: scale,
      alpha: alpha,
      noteScale: noteScale,
    );
  }

  const double innerRatio = 0.65;
  final double innerRadius = outerRadius * innerRatio;

  _tapFallbackFillPaint.color = color.withAlpha(alpha);
  _tapFallbackPath
    ..reset()
    ..fillType = PathFillType.evenOdd
    ..addOval(Rect.fromCircle(center: position, radius: outerRadius))
    ..addOval(Rect.fromCircle(center: position, radius: innerRadius));
  canvas.drawPath(_tapFallbackPath, _tapFallbackFillPaint);

  _tapFallbackStrokePaint
    ..color = Colors.white.withAlpha(alpha)
    ..strokeWidth = 2.0 * scale * noteScale;
  canvas.drawCircle(position, outerRadius, _tapFallbackStrokePaint);
  canvas.drawCircle(position, innerRadius, _tapFallbackStrokePaint);

  final double dotRadius = 4.0 * scale * noteScale;
  canvas.drawCircle(position, dotRadius, _tapFallbackFillPaint);
}
