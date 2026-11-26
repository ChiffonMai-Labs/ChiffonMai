part of 'notes_batch_renderer.dart';

// 预计算单位正六边形 6 个顶点的余弦/正弦基向量，每音符仅需一次 cos/sin。
const double _hexSin60 = 0.8660254037844386;
const List<double> _hexUnitX = <double>[1.0, 0.5, -0.5, -1.0, -0.5, 0.5];
const List<double> _hexUnitY = <double>[
  0.0,
  _hexSin60,
  _hexSin60,
  0.0,
  -_hexSin60,
  -_hexSin60,
];

// 复用 Hold 静态画笔与路径，彻底消除热路径 Paint/Path/List 堆分配。
final Paint _holdHighlightPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

final Paint _holdFillPaint = Paint()
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

final Paint _holdStrokePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

final Path _holdHighlightPath = Path();
final Path _holdOuterPath = Path();
final Path _holdInnerPath = Path();
final Path _holdCombinedPath = Path()..fillType = PathFillType.evenOdd;
final Path _holdSegmentPath = Path();

const List<double> _holdActiveBrightnessCurve = <double>[
  0.714, 0.51, 0.286, 0.095, 0.0, 0.01, 0.095, 0.293,
  0.552, 0.762, 0.917, 0.976, 1.0, 0.995, 0.969, 0.917,
];
const double _holdActiveCycleMs = 16000.0 / 60.0;

Color _tintHoldColor(Color base, double factor, int alpha) {
  if ((factor - 1.0).abs() < 1e-4) return base.withAlpha(alpha);
  final r = (base.r * 255.0 * factor).round().clamp(0, 255);
  final g = (base.g * 255.0 * factor).round().clamp(0, 255);
  final b = (base.b * 255.0 * factor).round().clamp(0, 255);
  return Color.fromARGB(alpha, r, g, b);
}

double _holdActiveBrightness(double elapsedMs) {
  if (elapsedMs < 0) return 1.0;
  final steps = _holdActiveBrightnessCurve.length;
  final pos = ((elapsedMs % _holdActiveCycleMs) / _holdActiveCycleMs) * steps;
  final index = pos.floor();
  final t = pos - index;
  final a = _holdActiveBrightnessCurve[index % steps];
  final b = _holdActiveBrightnessCurve[(index + 1) % steps];
  return 0.82 + (a + (b - a) * t) * 0.18;
}

/// 原地向 [path] 写入 Hold 胶囊六边形外包络（顶点顺序与原 getHull 一致），零 List/Offset 分配。
void _writeHoldHullPath(
  Path path,
  Offset head,
  Offset tail,
  double radius,
  double ca,
  double sa,
) {
  final double vx0 = (ca * _hexUnitX[0] - sa * _hexUnitY[0]) * radius;
  final double vy0 = (sa * _hexUnitX[0] + ca * _hexUnitY[0]) * radius;
  final double vx1 = (ca * _hexUnitX[1] - sa * _hexUnitY[1]) * radius;
  final double vy1 = (sa * _hexUnitX[1] + ca * _hexUnitY[1]) * radius;
  final double vx2 = (ca * _hexUnitX[2] - sa * _hexUnitY[2]) * radius;
  final double vy2 = (sa * _hexUnitX[2] + ca * _hexUnitY[2]) * radius;
  final double vx3 = (ca * _hexUnitX[3] - sa * _hexUnitY[3]) * radius;
  final double vy3 = (sa * _hexUnitX[3] + ca * _hexUnitY[3]) * radius;
  final double vx4 = (ca * _hexUnitX[4] - sa * _hexUnitY[4]) * radius;
  final double vy4 = (sa * _hexUnitX[4] + ca * _hexUnitY[4]) * radius;
  final double vx5 = (ca * _hexUnitX[5] - sa * _hexUnitY[5]) * radius;
  final double vy5 = (sa * _hexUnitX[5] + ca * _hexUnitY[5]) * radius;

  // 顺序：[t[2], h[2], h[1], h[0], h[5], t[5], t[4], t[3]]
  path
    ..reset()
    ..moveTo(tail.dx + vx2, tail.dy + vy2)
    ..lineTo(head.dx + vx2, head.dy + vy2)
    ..lineTo(head.dx + vx1, head.dy + vy1)
    ..lineTo(head.dx + vx0, head.dy + vy0)
    ..lineTo(head.dx + vx5, head.dy + vy5)
    ..lineTo(tail.dx + vx5, tail.dy + vy5)
    ..lineTo(tail.dx + vx4, tail.dy + vy4)
    ..lineTo(tail.dx + vx3, tail.dy + vy3)
    ..close();
}

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

  final session = game.gameplaySession;
  final double tailProgressRaw =
      1.0 - (endTime - game.chartTime) / state.approachTime;

  final double startRadius =
      game.chartRadius * BaseNoteComponent.initialRadiusRatio;

  final double tm = tailProgressRaw < BaseNoteComponent.scaleInProgressRatio
      ? 0.0
      : ((tailProgressRaw - BaseNoteComponent.scaleInProgressRatio) /
                (1.0 - BaseNoteComponent.scaleInProgressRatio))
            .clamp(0.0, 1.0);
  final double tailRadius = startRadius + (game.chartRadius - startRadius) * tm;

  final Offset tailPos = Offset(
    game.chartCenter.dx + tailRadius * cos(state.drawAngle),
    game.chartCenter.dy + tailRadius * sin(state.drawAngle),
  );

  final bool isPressed =
      (session == null && game.chartTime >= noteTime) ||
      (session != null &&
          session.isHoldPressed(collectionIndex, noteIndex, game.chartTime));
  final double pressedElapsedMs = isPressed
      ? (game.chartTime - noteTime) * 1000.0
      : -1.0;

  // Hold 运行在 Pass 1 底层矢量阶段，无需触发 SpriteBatch flush。
  _drawHoldHexagon(
    canvas,
    head: state.drawPosition,
    tail: tailPos,
    rotation: state.drawAngle,
    color: baseColor,
    scale: state.drawScale,
    alpha: alpha,
    noteScale: game.noteScale,
    chartRadius: game.chartRadius,
    highlight: isEx,
    noteStyle: game.noteStyle,
    isBreak: isBreak,
    isEach: isEach,
    isPressed: isPressed,
    pressedElapsedMs: pressedElapsedMs,
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
  required double chartRadius,
  required bool highlight,
  required SimaiNoteStyle noteStyle,
  required bool isBreak,
  required bool isEach,
  required bool isPressed,
  required double pressedElapsedMs,
}) {
  final double outerRadius = NoteGeometry.tapStarHoldRadius * scale * noteScale;

  final double dx = head.dx - tail.dx;
  final double dy = head.dy - tail.dy;
  final double angle = (dx.abs() < 0.001 && dy.abs() < 0.001)
      ? rotation
      : atan2(dy, dx);
  final double ca = cos(angle);
  final double sa = sin(angle);

  if (noteStyle == SimaiNoteStyle.arcade) {
    _drawArcadeHoldBody(
      canvas,
      head: head,
      tail: tail,
      ca: ca,
      sa: sa,
      outerRadius: outerRadius,
      scale: scale,
      alpha: alpha,
      noteScale: noteScale,
      chartRadius: chartRadius,
      highlight: highlight,
      isBreak: isBreak,
      isEach: isEach,
      isPressed: isPressed,
      pressedElapsedMs: pressedElapsedMs,
    );
    return;
  }

  if (highlight && alpha > 0) {
    _holdHighlightPaint
      ..color = color.withAlpha((alpha * 0.4).toInt())
      ..strokeWidth = 12.0 * scale * noteScale;
    _writeHoldHullPath(
      _holdHighlightPath,
      head,
      tail,
      outerRadius + 6.0 * scale * noteScale,
      ca,
      sa,
    );
    canvas.drawPath(_holdHighlightPath, _holdHighlightPaint);
  }

  const double innerRatio = 0.7;
  final double innerRadius = outerRadius * innerRatio;

  _writeHoldHullPath(_holdOuterPath, head, tail, outerRadius, ca, sa);
  _writeHoldHullPath(_holdInnerPath, head, tail, innerRadius, ca, sa);

  // Path.reset() 会把 fillType 清回 nonZero，必须重新指定 evenOdd 确保 Hold 中央镂空。
  _holdCombinedPath
    ..reset()
    ..fillType = PathFillType.evenOdd
    ..addPath(_holdOuterPath, Offset.zero)
    ..addPath(_holdInnerPath, Offset.zero);

  _holdFillPaint
    ..shader = null
    ..color = color.withAlpha(alpha);
  canvas.drawPath(_holdCombinedPath, _holdFillPaint);

  _holdStrokePaint
    ..color = Colors.white.withAlpha(alpha)
    ..strokeWidth = 2.0 * scale * noteScale;
  // 一次描边即可同时勾勒内外轮廓两条闭合子路径。
  canvas.drawPath(_holdCombinedPath, _holdStrokePaint);

  final double dotRadius = 5.0 * scale * noteScale;
  canvas.drawCircle(head, dotRadius, _holdFillPaint);
  canvas.drawCircle(tail, dotRadius, _holdFillPaint);
}

/// 官方机台风格 Hold（借鉴 LXNS `HoldRenderer`：6 段梯形渐变色带、中央透明镂空、黑白双线与按压辉光）。
void _drawArcadeHoldBody(
  Canvas canvas, {
  required Offset head,
  required Offset tail,
  required double ca,
  required double sa,
  required double outerRadius,
  required double scale,
  required int alpha,
  required double noteScale,
  required double chartRadius,
  required bool highlight,
  required bool isBreak,
  required bool isEach,
  required bool isPressed,
  required double pressedElapsedMs,
}) {
  final double strokeW = 2.0 * scale * noteScale;
  const double innerRatio = SimaiVisualTokens.holdInnerRatio;
  final double innerRadius = outerRadius * innerRatio;

  _writeHoldHullPath(_holdOuterPath, head, tail, outerRadius, ca, sa);
  _writeHoldHullPath(_holdInnerPath, head, tail, innerRadius, ca, sa);

  if (highlight && alpha > 0) {
    final Color exColor = isBreak
        ? SimaiVisualTokens.colorExOverlayBreak
        : (isEach
              ? SimaiVisualTokens.colorExOverlaySimultaneous
              : SimaiVisualTokens.colorExOverlayNormal);
    _writeHoldHullPath(
      _holdHighlightPath,
      head,
      tail,
      outerRadius * 1.19,
      ca,
      sa,
    );
    _holdCombinedPath
      ..reset()
      ..fillType = PathFillType.evenOdd
      ..addPath(_holdHighlightPath, Offset.zero)
      ..addPath(_holdOuterPath, Offset.zero);
    _holdFillPaint
      ..shader = null
      ..color = exColor.withAlpha((exColor.a * alpha).round().clamp(0, 255));
    canvas.drawPath(_holdCombinedPath, _holdFillPaint);
  }

  // 先画加宽黑底描边，后续环带色块覆盖内侧，仅外露 1× 清晰黑边。
  _holdStrokePaint
    ..color = Colors.black.withAlpha(alpha)
    ..strokeWidth = strokeW * 3.0;
  if (!highlight) {
    canvas.drawPath(_holdOuterPath, _holdStrokePaint);
  }
  canvas.drawPath(_holdInnerPath, _holdStrokePaint);

  final Color gradStart = isBreak
      ? SimaiVisualTokens.colorBreakGradientStart
      : (isEach
            ? SimaiVisualTokens.colorSimultaneousGradientStart
            : SimaiVisualTokens.colorTapGradientStart);
  final Color gradEnd = isBreak
      ? SimaiVisualTokens.colorBreakGradientEnd
      : (isEach
            ? SimaiVisualTokens.colorSimultaneousGradientEnd
            : SimaiVisualTokens.colorTapGradientEnd);
  final double brightness =
      isPressed ? _holdActiveBrightness(pressedElapsedMs) : 1.0;
  final Color lightColor = _tintHoldColor(
    Color.lerp(gradStart, Colors.white, SimaiVisualTokens.noteLightenRatio)!,
    brightness,
    alpha,
  );
  final Color bodyColor = _tintHoldColor(gradEnd, brightness, alpha);

  // 外包络 6 个顶点按逆/顺时针闭环依次为：h0, h1, t2, t3, t4, h5（内环按 innerRatio 同构缩放）。
  final double ox0 = (ca * _hexUnitX[0] - sa * _hexUnitY[0]) * outerRadius;
  final double oy0 = (sa * _hexUnitX[0] + ca * _hexUnitY[0]) * outerRadius;
  final double ox1 = (ca * _hexUnitX[1] - sa * _hexUnitY[1]) * outerRadius;
  final double oy1 = (sa * _hexUnitX[1] + ca * _hexUnitY[1]) * outerRadius;
  final double ox2 = (ca * _hexUnitX[2] - sa * _hexUnitY[2]) * outerRadius;
  final double oy2 = (sa * _hexUnitX[2] + ca * _hexUnitY[2]) * outerRadius;
  final double ox3 = (ca * _hexUnitX[3] - sa * _hexUnitY[3]) * outerRadius;
  final double oy3 = (sa * _hexUnitX[3] + ca * _hexUnitY[3]) * outerRadius;
  final double ox4 = (ca * _hexUnitX[4] - sa * _hexUnitY[4]) * outerRadius;
  final double oy4 = (sa * _hexUnitX[4] + ca * _hexUnitY[4]) * outerRadius;
  final double ox5 = (ca * _hexUnitX[5] - sa * _hexUnitY[5]) * outerRadius;
  final double oy5 = (sa * _hexUnitX[5] + ca * _hexUnitY[5]) * outerRadius;

  void drawSegment(
    double x0,
    double y0,
    double x1,
    double y1,
    double ix0,
    double iy0,
    double ix1,
    double iy1,
  ) {
    _holdSegmentPath
      ..reset()
      ..moveTo(x0, y0)
      ..lineTo(x1, y1)
      ..lineTo(ix1, iy1)
      ..lineTo(ix0, iy0)
      ..close();
    _holdFillPaint.shader = ui.Gradient.linear(
      Offset(x0, y0),
      Offset(x1, y1),
      [lightColor, bodyColor],
    );
    canvas.drawPath(_holdSegmentPath, _holdFillPaint);
  }

  final double hx0 = head.dx + ox0, hy0 = head.dy + oy0;
  final double hx1 = head.dx + ox1, hy1 = head.dy + oy1;
  final double tx2 = tail.dx + ox2, ty2 = tail.dy + oy2;
  final double tx3 = tail.dx + ox3, ty3 = tail.dy + oy3;
  final double tx4 = tail.dx + ox4, ty4 = tail.dy + oy4;
  final double hx5 = head.dx + ox5, hy5 = head.dy + oy5;

  final double ihx0 = head.dx + ox0 * innerRatio, ihy0 = head.dy + oy0 * innerRatio;
  final double ihx1 = head.dx + ox1 * innerRatio, ihy1 = head.dy + oy1 * innerRatio;
  final double itx2 = tail.dx + ox2 * innerRatio, ity2 = tail.dy + oy2 * innerRatio;
  final double itx3 = tail.dx + ox3 * innerRatio, ity3 = tail.dy + oy3 * innerRatio;
  final double itx4 = tail.dx + ox4 * innerRatio, ity4 = tail.dy + oy4 * innerRatio;
  final double ihx5 = head.dx + ox5 * innerRatio, ihy5 = head.dy + oy5 * innerRatio;

  drawSegment(hx0, hy0, hx1, hy1, ihx0, ihy0, ihx1, ihy1);
  drawSegment(hx1, hy1, tx2, ty2, ihx1, ihy1, itx2, ity2);
  drawSegment(tx2, ty2, tx3, ty3, itx2, ity2, itx3, ity3);
  drawSegment(tx3, ty3, tx4, ty4, itx3, ity3, itx4, ity4);
  drawSegment(tx4, ty4, hx5, hy5, itx4, ity4, ihx5, ihy5);
  drawSegment(hx5, hy5, hx0, hy0, ihx5, ihy5, ihx0, ihy0);
  _holdFillPaint.shader = null;

  _holdStrokePaint
    ..color = _tintHoldColor(Colors.white, brightness, alpha)
    ..strokeWidth = strokeW;
  canvas.drawPath(_holdOuterPath, _holdStrokePaint);
  canvas.drawPath(_holdInnerPath, _holdStrokePaint);

  final Color dotBaseColor = isBreak
      ? SimaiColors.holdBreak
      : (isEach ? SimaiColors.holdEach : SimaiColors.holdNormal);
  final double dotRadius = outerRadius * 0.15;
  if (isPressed && chartRadius > 0) {
    final double glowOuter = chartRadius * 0.06;
    if (glowOuter >= 1.0) {
      final int br = (gradStart.r * 255.0).round();
      final int bg = (gradStart.g * 255.0).round();
      final int bb = (gradStart.b * 255.0).round();
      Color ch(double mr, double mg, double mb) => Color.fromARGB(
        alpha,
        (br * mr).round().clamp(0, 255),
        (bg * mg).round().clamp(0, 255),
        (bb * mb).round().clamp(0, 255),
      );
      _holdFillPaint.shader = ui.Gradient.radial(
        head,
        glowOuter,
        [
          ch(0.99, 1.11, 1.29),
          ch(0.99, 0.79, 0.72),
          ch(0.93, 0.49, 0.62),
          ch(0.54, 0.08, 0.13),
          const Color(0x00000000),
        ],
        const [0.0, 0.2, 0.4, 0.6, 1.0],
      );
      canvas.drawCircle(head, glowOuter, _holdFillPaint);
      _holdFillPaint.shader = null;
    }
  } else {
    _holdFillPaint.color = dotBaseColor.withAlpha(alpha);
    canvas.drawCircle(head, dotRadius, _holdFillPaint);
  }
  _holdFillPaint.color = _tintHoldColor(dotBaseColor, brightness, alpha);
  canvas.drawCircle(tail, dotRadius, _holdFillPaint);
}
