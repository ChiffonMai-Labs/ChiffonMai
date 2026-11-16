part of 'notes_batch_renderer.dart';

void _drawTouch(
  Canvas canvas, {
  required SimaiGame game,
  required Note note,
  required double noteTime,
  required int collectionIndex,
  required int noteIndex,
  required bool isEach,
  required BaseNoteDrawState state,
}) {
  final bool isBreak =
      note.type == NoteType.breakNote || (note.styles & NoteStyles.mine) != 0;

  final bool isHold = note.isTouchHold;
  final session = game.gameplaySession;
  final headResolved =
      session?.isHeadResolved(collectionIndex, noteIndex) ?? false;
  if (session != null && !isHold && headResolved) return;
  final Offset h = NoteUtils.getTouchPosition(
    game.chartCenter,
    game.chartRadius,
    NoteUtils.mirrorLocation(note.location, game.mirrorMode),
  );

  final double r = max(state.approachTime, 0.001);
  final double n = noteTime - game.chartTime;
  if (n > r) return;
  if (session == null && !isHold && n <= 0) return;
  if (isHold && game.chartTime > noteTime + (note.length ?? 0) + 0.05) return;

  if (isHold) {
    game.noteAssets.flush(canvas);
    TouchHoldPainter.paint(
      canvas,
      center: h,
      scale: game.noteScale,
      timeUntilHead: n,
      approachTime: r,
      duration: note.length ?? 0,
      isEach: isEach,
    );
    return;
  }

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

  final double cornerRadius = 8.0 * game.noteScale;
  final double innerCornerRadius = cornerRadius * 0.4;
  final double outlineWidth = 3.0 * game.noteScale;
  final double dotRadius = 8.0 * game.noteScale;

  final double u = 40.0 * game.noteScale;
  const double gapEnd = 0;
  final double gapStart = gapEnd + 18.0 * game.noteScale;
  final double fEnd = u + gapEnd;
  final double fStart = u + gapStart;

  double f = fStart;
  if (n > 0 && n <= r) {
    final double s = 1.0 - n / r;
    final double k = s * s * s * s;
    f = fStart - (fStart - fEnd) * k;
  } else if (n <= 0) {
    f = fEnd;
  }

  final List<double> angles = [-pi / 4, pi / 4, 3 * pi / 4, -3 * pi / 4];
  const double w = -pi / 4;

  final List<Offset> petalTips = [];
  final List<Offset> petalLefts = [];
  final List<Offset> petalRights = [];

  final Color color = isBreak
      ? SimaiColors.touchBreak
      : (isEach ? SimaiColors.touchEach : SimaiColors.touchNormal);

  for (int idx = 0; idx < 4; idx++) {
    final double k = angles[idx] + w;
    final Offset petal = Offset(h.dx + cos(k) * f, h.dy + sin(k) * f);

    final double v = u;
    final Offset tip = Offset(
      petal.dx + cos(k + pi) * v,
      petal.dy + sin(k + pi) * v,
    );
    final Offset left = Offset(
      petal.dx + cos(k + pi / 2) * v,
      petal.dy + sin(k + pi / 2) * v,
    );
    final Offset right = Offset(
      petal.dx + cos(k - pi / 2) * v,
      petal.dy + sin(k - pi / 2) * v,
    );

    if (!m) {
      String key = 'touch_normal';
      if (isBreak) {
        key = 'touch_break';
      } else if (isEach) {
        key = 'touch_each';
      }

      if (game.noteAssets.drawSprite(
        canvas,
        key: key,
        position: petal,
        size: 110.0 * game.noteScale,
        rotation: k + pi,
        alpha: (255 * t).round(),
      )) {
        continue;
      }
    }

    petalTips.add(tip);
    petalLefts.add(left);
    petalRights.add(right);
  }

  final bool hasPetals =
      petalTips.length == 4 &&
      petalLefts.length == 4 &&
      petalRights.length == 4;

  game.noteAssets.flush(canvas);

  if (hasPetals) {
    for (int idx = 0; idx < 4; idx++) {
      final double k = angles[idx] + w;
      final Offset petal = Offset(h.dx + cos(k) * f, h.dy + sin(k) * f);

      final Offset tip = petalTips[idx];
      final Offset left = petalLefts[idx];
      final Offset right = petalRights[idx];
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

      canvas.drawShadow(
        outer,
        Color.fromARGB((128 * t).round(), 0, 0, 0),
        8.0 * game.noteScale,
        true,
      );

      final Paint fillPaint = Paint()..style = PaintingStyle.fill;

      final Color g0 = m ? const Color(0xFFFFFF00) : color;
      final Color g1 = m
          ? const Color(0xFFFFD700)
          : Color.lerp(color, Colors.black, 0.35)!;
      fillPaint.shader = ui.Gradient.linear(petal, tip, [
        g0.withAlpha((255 * t).round()),
        g1.withAlpha((255 * t).round()),
      ]);
      fillPaint.color = Colors.white.withAlpha((255 * t).round());

      canvas.drawPath(fillPath, fillPaint);

      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withAlpha((255 * t).round());

      canvas.drawPath(outer, strokePaint);

      canvas.drawPath(inner, strokePaint);
    }
  }

  final Paint dotPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = (m ? const Color(0xFFFFFF00) : color).withAlpha(
      (255 * a).round(),
    );
  canvas.drawCircle(h, dotRadius, dotPaint);

  final Paint dotStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = outlineWidth
    ..color = Colors.white.withAlpha((255 * a).round());
  canvas.drawCircle(h, dotRadius, dotStroke);
}

double _touchHoldRevealSweep(double progress) {
  if (!progress.isFinite) return 0.0;
  return progress.clamp(0.0, 1.0) * pi * 2;
}
