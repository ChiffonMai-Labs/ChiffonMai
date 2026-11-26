part of 'notes_batch_renderer.dart';

// 复用引导线与烟花波纹画笔及判定圆裁切路径，避免每音符每帧新建 Paint/Path/Gradient.sweep。
final Paint _approachArcPaint = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

final Paint _fireworksFillPaint = Paint()..isAntiAlias = true;
Offset? _cachedFireworksClipCenter;
double _cachedFireworksClipRadius = -1.0;
final Path _cachedFireworksClipPath = Path();

Path _judgeCircleClipPath(Offset center, double radius) {
  if (_cachedFireworksClipCenter != center ||
      _cachedFireworksClipRadius != radius) {
    _cachedFireworksClipCenter = center;
    _cachedFireworksClipRadius = radius;
    _cachedFireworksClipPath
      ..reset()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }
  return _cachedFireworksClipPath;
}

void _drawTouchFireworksForCollection(
  Canvas canvas, {
  required SimaiGame game,
  required NoteCollection collection,
  required int collectionIndex,
}) {
  // 无烟花音符时延迟分配 Map，绝大多数集合零堆分配直接返回。
  Map<int, List<Note>>? groupedNotes;
  final session = game.gameplaySession;
  for (var noteIndex = 0; noteIndex < collection.length; noteIndex++) {
    final note = collection[noteIndex];
    if (note.location.group == NoteGroup.tap) continue;
    if ((note.styles & NoteStyles.fireworks) == 0) continue;

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
    final double elapsed = game.chartTime - eventTime;
    if (elapsed < 0 ||
        elapsed >= NotesBatchRenderer.touchFireworksRippleDuration) {
      continue;
    }
    final int eventKey = (eventTime * 1000).round();
    groupedNotes ??= <int, List<Note>>{};
    groupedNotes.putIfAbsent(eventKey, () => <Note>[]).add(note);
  }

  if (groupedNotes == null || groupedNotes.isEmpty) return;

  final Path judgeClip = _judgeCircleClipPath(
    game.chartCenter,
    game.chartRadius,
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
    if (radius <= 0.0) continue;
    final int fillAlpha = (96 * (1.0 - t * 0.82) * (1.0 - t * 0.82)).round();

    canvas.save();
    canvas.clipPath(judgeClip);

    _fireworksFillPaint.shader = ui.Gradient.radial(
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
    canvas.drawCircle(center, radius, _fireworksFillPaint);
    _fireworksFillPaint.shader = null;

    canvas.restore();
  }
}

/// Pass 1 引导线绘制：复用静态 Paint，用双层轻量半透明弧替代每音符每帧新建 ui.Gradient.sweep。
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
  if (game.chartRadius <= 0 || currentRadius <= 0) return;

  final double baseWidth = 1.6 * game.noteScale;
  _approachArcPaint
    ..strokeWidth = baseWidth
    ..shader = null;

  if (isOpposite) {
    final double fade = connectEach ? 1.0 : 0.9;
    _approachArcPaint.color = color.withAlpha((alpha * fade).round());
    canvas.drawCircle(game.chartCenter, currentRadius, _approachArcPaint);
  } else {
    final rect = Rect.fromCircle(
      center: game.chartCenter,
      radius: currentRadius,
    );
    // 单层半透明弧，将高密段引导线 drawArc 开销减半。
    final double sweep = connectEach ? pi * 0.42 : pi * 0.36;
    final int arcAlpha =
        (alpha * (connectEach ? 0.72 : 0.62)).round().clamp(0, 255);

    _approachArcPaint.color = color.withAlpha(arcAlpha);
    canvas.drawArc(rect, drawAngle - sweep / 2, sweep, false, _approachArcPaint);
  }
}

int _sampleIndex(double progress, int sampleCount) {
  if (sampleCount <= 1) return 0;
  return (progress * (sampleCount - 1)).round().clamp(0, sampleCount - 1);
}
