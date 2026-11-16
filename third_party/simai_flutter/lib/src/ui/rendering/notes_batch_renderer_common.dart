part of 'notes_batch_renderer.dart';

void _drawTouchFireworksForCollection(
  Canvas canvas, {
  required SimaiGame game,
  required NoteCollection collection,
  required int collectionIndex,
}) {
  final Map<int, List<Note>> groupedNotes = <int, List<Note>>{};
  for (var noteIndex = 0; noteIndex < collection.length; noteIndex++) {
    final note = collection[noteIndex];
    if (note.location.group == NoteGroup.tap) continue;
    if ((note.styles & NoteStyles.fireworks) == 0) continue;

    final session = game.gameplaySession;
    final feedback = session?.headFeedbackFor(collectionIndex, noteIndex);
    if (session != null &&
        (feedback == null || feedback.grade == SimaiJudgeGrade.miss)) {
      continue;
    }
    final double eventTime =
        feedback?.judgedTime ??
        collection.time +
            ((note.type == NoteType.hold && (note.length ?? 0) > 0)
                ? (note.length ?? 0)
                : 0.0);
    final int eventKey = (eventTime * 1000).round();
    groupedNotes.putIfAbsent(eventKey, () => <Note>[]).add(note);
  }

  if (groupedNotes.isEmpty) return;

  final Path judgeClip = Path()
    ..addOval(
      Rect.fromCircle(center: game.chartCenter, radius: game.chartRadius),
    );

  for (final entry in groupedNotes.entries) {
    final double eventTime = entry.key / 1000.0;
    final double elapsed = game.chartTime - eventTime;
    if (elapsed < 0 ||
        elapsed >= NotesBatchRenderer.touchFireworksRippleDuration) {
      continue;
    }

    final double t = (elapsed / NotesBatchRenderer.touchFireworksRippleDuration)
        .clamp(0.0, 1.0);
    final double eased = Curves.easeOutCubic.transform(t);

    Offset center = Offset.zero;
    for (final note in entry.value) {
      final Offset pos = NoteUtils.getTouchPosition(
        game.chartCenter,
        game.chartRadius,
        NoteUtils.mirrorLocation(note.location, game.mirrorMode),
      );
      center += pos;
    }
    center /= entry.value.length.toDouble();
    final double maxRadius =
        game.chartRadius + (center - game.chartCenter).distance;
    final double radius = ui.lerpDouble(
      0.0,
      maxRadius,
      Curves.easeOutQuart.transform(eased),
    )!;
    final int fillAlpha = (96 * (1.0 - t * 0.82) * (1.0 - t * 0.82)).round();

    game.noteAssets.flush(canvas);
    canvas.save();
    canvas.clipPath(judgeClip);

    final Paint fillPaint = Paint()
      ..isAntiAlias = true
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          Colors.white.withAlpha(fillAlpha),
          Colors.white.withAlpha((fillAlpha * 0.72).round()),
          Colors.white.withAlpha((fillAlpha * 0.3).round()),
          Colors.white.withAlpha(0),
        ],
        const [0.0, 0.38, 0.72, 1.0],
      );
    canvas.drawCircle(center, radius, fillPaint);

    canvas.restore();
  }
}

void _drawApproachArc(
  Canvas canvas, {
  required SimaiGame game,
  required double progress,
  required double currentRadius,
  required double drawAngle,
  required Color color,
  required int alpha,
  required bool connectEach,
  required bool isOpposite,
}) {
  if (!game.showApproachLine) return;
  if (progress >= 1.0) return;
  if (game.chartRadius <= 0) return;

  game.noteAssets.flush(canvas);

  final double sweep = isOpposite ? pi * 2 : pi / 2;
  final double start = drawAngle - sweep / 2;

  // Draw at the current radius instead of scaling a cached bitmap. This
  // keeps stroke width and blur constant while the arc follows the note.
  final double baseWidth = 1.6 * game.noteScale;

  final Paint p = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  if (isOpposite) {
    final double fade = connectEach ? 1.0 : 0.9;
    p
      ..strokeWidth = baseWidth
      ..shader = null
      ..color = color.withAlpha((alpha * fade).round());
    canvas.drawArc(
      Rect.fromCircle(center: game.chartCenter, radius: currentRadius),
      start,
      sweep,
      false,
      p,
    );
  } else {
    final int edgeAlpha = connectEach ? (alpha * 0.18).round() : 0;
    final rect = Rect.fromCircle(
      center: game.chartCenter,
      radius: currentRadius,
    );
    p
      ..strokeWidth = baseWidth
      ..color = Colors.white
      ..shader = ui.Gradient.sweep(
        game.chartCenter,
        <Color>[
          color.withAlpha(edgeAlpha),
          color.withAlpha(alpha),
          color.withAlpha(edgeAlpha),
        ],
        const <double>[0.0, 0.5, 1.0],
        TileMode.clamp,
        start,
        start + sweep,
      );
    canvas.drawArc(rect, start, sweep, false, p);
  }
}

int _sampleIndex(double progress, int sampleCount) {
  if (sampleCount <= 1) return 0;
  return (progress * (sampleCount - 1)).round().clamp(0, sampleCount - 1);
}
