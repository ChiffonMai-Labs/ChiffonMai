part of 'notes_batch_renderer.dart';

// 预计算 Touch 四片花瓣方向角的余弦/正弦，避免每音符每帧反复三角函数计算。
const List<double> _touchAngles = <double>[
  -pi / 2,
  0.0,
  pi / 2,
  -pi,
];
const List<double> _touchCos = <double>[0.0, 1.0, 0.0, -1.0];
const List<double> _touchSin = <double>[-1.0, 0.0, 1.0, 0.0];

// 图集不可用时的降级画笔。
final Paint _touchFallbackFillPaint = Paint()
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

final Paint _touchFallbackStrokePaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

/// Pass 2：单押与多押 Touch 全部通过图集精灵（touch_* / touch_multi / touch_center）合批绘制。
void _drawTouchSpritePass(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required double noteTime,
  required bool isEach,
  required double approachTime,
}) {
  final bool isBreak =
      note.type == NoteType.breakNote || (note.styles & NoteStyles.mine) != 0;
  final Offset h = NoteUtils.getTouchPosition(
    game.chartCenter,
    game.chartRadius,
    NoteUtils.mirrorLocation(note.location, game.mirrorMode),
  );

  final double r = approachTime;
  final double n = noteTime - game.chartTime;
  if (n > r) return;

  double a = 1.0;
  if (n > r * 0.95) {
    a = 1.0 - (n - r * 0.95) / (r * 0.05);
  }

  double c = 1.0;
  if (n > 0 && n < r) {
    final double s = r - n;
    if (s < 0.15) c = s / 0.15;
  }

  final bool m = (note.parentCollection?.length ?? 0) >= 2;
  final double t = (a * c).clamp(0.0, 1.0);
  final int petalAlpha = (255 * t).round().clamp(0, 255);
  final int dotAlpha = (255 * a).round().clamp(0, 255);

  final double u = 40.0 * game.noteScale;
  final double fEnd = u;
  final double fStart = u + 18.0 * game.noteScale;

  double f = fStart;
  if (n > 0 && n <= r) {
    final double s = 1.0 - n / r;
    final double k = s * s * s * s;
    f = fStart - (fStart - fEnd) * k;
  } else if (n <= 0) {
    f = fEnd;
  }

  final Color color = isBreak
      ? SimaiColors.touchBreak
      : (isEach ? SimaiColors.touchEach : SimaiColors.touchNormal);

  // 多押同样走预烘焙 'touch_multi' 图集精灵，消灭每音符 4×drawShadow + 12 Path + 4 Gradient.linear。
  final String petalKey = m
      ? 'touch_multi'
      : (isBreak
            ? 'touch_break'
            : (isEach ? 'touch_each' : 'touch_normal'));

  final double petalSpriteSize = NoteAssetManager.cellExtent * game.noteScale;
  bool allPetalsBatched = game.noteAssets.hasAsset(petalKey);
  if (allPetalsBatched && petalAlpha > 0) {
    for (int idx = 0; idx < 4; idx++) {
      final double k = _touchAngles[idx];
      final Offset petal = Offset(
        h.dx + _touchCos[idx] * f,
        h.dy + _touchSin[idx] * f,
      );
      if (!game.noteAssets.drawSprite(
        canvas,
        key: petalKey,
        position: petal,
        size: petalSpriteSize,
        rotation: k + pi,
        alpha: petalAlpha,
      )) {
        allPetalsBatched = false;
        break;
      }
    }
  }

  if (!allPetalsBatched && petalAlpha > 0) {
    _drawTouchPetalsVectorFallback(
      canvas,
      game: game,
      center: h,
      petalOffset: f,
      petalSize: u,
      isMulti: m,
      color: color,
      t: t,
      petalAlpha: petalAlpha,
    );
  }

  // 中心圆点统一使用经典（机台）样式，通过 'touch_center' 白色精灵染色合批（带外黑环，零额外 flush）。
  final double dotRadius = 8.0 * game.noteScale;
  final double outlineWidth = 2.0 * game.noteScale;
  final Color dotColor = m
      ? const Color(0xFFFFFF00)
      : (isBreak ? SimaiColors.touchBreak : const Color(0xFF00BFFF));

  if (dotAlpha > 0) {
    if (game.noteAssets.hasAsset('touch_center')) {
      final double outerDotRadius = dotRadius + outlineWidth * 0.5;
      final double innerDotRadius = max(1.0, dotRadius - outlineWidth * 0.5);
      game.noteAssets.drawSprite(
        canvas,
        key: 'touch_center',
        position: h,
        size: NoteAssetManager.touchCenterSpriteSize(
          outerDotRadius + outlineWidth * 0.9,
        ),
        alpha: dotAlpha,
        color: Colors.black,
      );
      game.noteAssets.drawSprite(
        canvas,
        key: 'touch_center',
        position: h,
        size: NoteAssetManager.touchCenterSpriteSize(outerDotRadius),
        alpha: dotAlpha,
        color: Colors.white,
      );
      game.noteAssets.drawSprite(
        canvas,
        key: 'touch_center',
        position: h,
        size: NoteAssetManager.touchCenterSpriteSize(innerDotRadius),
        alpha: dotAlpha,
        color: dotColor,
      );
    } else {
      game.noteAssets.flush(canvas);
      _touchFallbackStrokePaint
        ..strokeWidth = outlineWidth * 3.0
        ..color = Colors.black.withAlpha(dotAlpha);
      canvas.drawCircle(h, dotRadius, _touchFallbackStrokePaint);
      _touchFallbackFillPaint
        ..shader = null
        ..color = dotColor.withAlpha(dotAlpha);
      canvas.drawCircle(h, dotRadius, _touchFallbackFillPaint);

      _touchFallbackStrokePaint
        ..strokeWidth = outlineWidth
        ..color = Colors.white.withAlpha(dotAlpha);
      canvas.drawCircle(h, dotRadius, _touchFallbackStrokePaint);
    }
  }
}

void _drawTouchPetalsVectorFallback(
  Canvas canvas, {
  required SimaiGame game,
  required Offset center,
  required double petalOffset,
  required double petalSize,
  required bool isMulti,
  required Color color,
  required double t,
  required int petalAlpha,
}) {
  game.noteAssets.flush(canvas);
  final double cornerRadius = 8.0 * game.noteScale;
  final double innerCornerRadius = cornerRadius * 0.4;
  final double outlineWidth = 3.0 * game.noteScale;
  final Color g0 = isMulti ? const Color(0xFFFFFF00) : color;
  final Color g1 = isMulti
      ? const Color(0xFFFFD700)
      : Color.lerp(color, Colors.black, 0.35)!;

  _touchFallbackStrokePaint
    ..strokeWidth = outlineWidth
    ..color = Colors.white.withAlpha(petalAlpha);

  for (int idx = 0; idx < 4; idx++) {
    final double k = _touchAngles[idx];
    final Offset petal = Offset(
      center.dx + _touchCos[idx] * petalOffset,
      center.dy + _touchSin[idx] * petalOffset,
    );
    final Offset tip = Offset(
      petal.dx + cos(k + pi) * petalSize,
      petal.dy + sin(k + pi) * petalSize,
    );
    final Offset left = Offset(
      petal.dx + cos(k + pi / 2) * petalSize,
      petal.dy + sin(k + pi / 2) * petalSize,
    );
    final Offset right = Offset(
      petal.dx + cos(k - pi / 2) * petalSize,
      petal.dy + sin(k - pi / 2) * petalSize,
    );
    final Path outer = NoteUtils.roundedTrianglePath(
      tip,
      left,
      right,
      cornerRadius,
    );
    final Offset centroid = Offset(
      (tip.dx + left.dx + right.dx) / 3,
      (tip.dy + left.dy + right.dy) / 3,
    );
    final Path inner = NoteUtils.roundedTrianglePath(
      centroid + (tip - centroid) * 0.4,
      centroid + (left - centroid) * 0.4,
      centroid + (right - centroid) * 0.4,
      innerCornerRadius,
    );
    final Path fillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addPath(inner, Offset.zero);

    _touchFallbackFillPaint
      ..color = Colors.white.withAlpha(petalAlpha)
      ..shader = ui.Gradient.linear(petal, tip, [
        g0.withAlpha(petalAlpha),
        g1.withAlpha(petalAlpha),
      ]);
    canvas.drawPath(fillPath, _touchFallbackFillPaint);
    _touchFallbackFillPaint.shader = null;

    canvas.drawPath(outer, _touchFallbackStrokePaint);
    canvas.drawPath(inner, _touchFallbackStrokePaint);
  }
}

double _touchHoldRevealSweep(double progress) {
  if (!progress.isFinite) return 0.0;
  return progress.clamp(0.0, 1.0) * pi * 2;
}
