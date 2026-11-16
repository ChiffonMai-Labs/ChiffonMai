import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class SimaiSlideFeedbackGeometry {
  const SimaiSlideFeedbackGeometry._({
    required this.arrowPath,
    required this.points,
    required this.cumulativeDistances,
    required this.length,
  });

  final Path arrowPath;
  final List<Offset> points;
  final List<double> cumulativeDistances;
  final double length;

  Offset pointAt(double distance) {
    if (points.length == 1 || length <= 0) return points.first;
    final target = distance.clamp(0.0, length).toDouble();
    final segment = _segmentAt(target);
    final startDistance = cumulativeDistances[segment];
    final endDistance = cumulativeDistances[segment + 1];
    final span = endDistance - startDistance;
    if (span <= 1e-9) return points[segment];
    return Offset.lerp(
      points[segment],
      points[segment + 1],
      (target - startDistance) / span,
    )!;
  }

  double angleAt(double distance) {
    if (points.length <= 1) return 0.0;
    final segment = _segmentAt(distance.clamp(0.0, length).toDouble());
    final delta = points[segment + 1] - points[segment];
    return atan2(delta.dy, delta.dx);
  }

  int _segmentAt(double distance) {
    var low = 0;
    var high = cumulativeDistances.length - 1;
    while (low + 1 < high) {
      final middle = (low + high) >> 1;
      if (cumulativeDistances[middle] <= distance) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return low.clamp(0, points.length - 2);
  }
}

List<Offset> simaiSlideFeedbackTailPoints({
  required List<double> xs,
  required List<double> ys,
  required double totalLength,
  required double normalizedTailLength,
  required double drawScale,
  required Offset center,
  int maximumSamples = 24,
}) {
  final count = min(xs.length, ys.length);
  if (count == 0 || !drawScale.isFinite || drawScale <= 0) {
    return const <Offset>[];
  }
  if (count == 1 || !totalLength.isFinite || totalLength <= 0) {
    return <Offset>[Offset(xs.first, ys.first) * drawScale + center];
  }

  final startProgress = (1.0 - normalizedTailLength / totalLength).clamp(
    0.0,
    1.0,
  );
  final rawStart = startProgress * (count - 1);
  final startIndex = rawStart.floor().clamp(0, count - 1);
  final nextIndex = min(count - 1, startIndex + 1);
  final startPoint = Offset.lerp(
    Offset(xs[startIndex], ys[startIndex]),
    Offset(xs[nextIndex], ys[nextIndex]),
    rawStart - startIndex,
  )!;

  final result = <Offset>[startPoint * drawScale + center];
  final remaining = count - 1 - nextIndex;
  final stride = max(1, (remaining / max(2, maximumSamples - 2)).ceil());
  for (var index = nextIndex; index < count - 1; index += stride) {
    result.add(Offset(xs[index], ys[index]) * drawScale + center);
  }
  result.add(Offset(xs[count - 1], ys[count - 1]) * drawScale + center);
  return result;
}

SimaiSlideFeedbackGeometry? buildSimaiSlideFeedbackGeometry({
  required List<Offset> pathPoints,
  required double halfWidth,
  required double chevronDepth,
}) {
  if (pathPoints.isEmpty || !halfWidth.isFinite || halfWidth <= 0) return null;
  final points = <Offset>[];
  for (final point in pathPoints) {
    if (!point.dx.isFinite || !point.dy.isFinite) continue;
    if (points.isEmpty || (point - points.last).distance > 0.25) {
      points.add(point);
    }
  }
  if (points.length < 2) return null;

  final cumulative = <double>[0.0];
  for (var index = 1; index < points.length; index++) {
    cumulative.add(
      cumulative.last + (points[index] - points[index - 1]).distance,
    );
  }
  final length = cumulative.last;
  if (length <= halfWidth * 1.5) return null;

  final measure = SimaiSlideFeedbackGeometry._(
    arrowPath: Path(),
    points: List.unmodifiable(points),
    cumulativeDistances: List.unmodifiable(cumulative),
    length: length,
  );
  // An elongated regular Slide chevron: the front and rear both use the same
  // `>` polyline, then their corresponding side points are connected along
  // the final path.
  final safeChevronDepth = chevronDepth.clamp(1.0, length * 0.40);
  final frontBaseDistance = max(0.0, length - safeChevronDepth);
  final sideSamples = (frontBaseDistance / max(4.0, halfWidth * 0.6))
      .ceil()
      .clamp(3, 32);
  final left = <Offset>[];
  final right = <Offset>[];
  for (var index = 0; index <= sideSamples; index++) {
    final progress = index / sideSamples;
    final distance = frontBaseDistance * progress;
    final point = measure.pointAt(distance);
    final angle = measure.angleAt(distance);
    final normal = Offset(-sin(angle), cos(angle));
    left.add(point + normal * halfWidth);
    right.add(point - normal * halfWidth);
  }

  final rearTip = measure.pointAt(safeChevronDepth);
  final path = Path()..moveTo(left.first.dx, left.first.dy);
  for (var index = 1; index < left.length; index++) {
    path.lineTo(left[index].dx, left[index].dy);
  }
  final tip = measure.pointAt(length);
  path.lineTo(tip.dx, tip.dy);
  for (var index = right.length - 1; index >= 0; index--) {
    path.lineTo(right[index].dx, right[index].dy);
  }
  path
    ..lineTo(rearTip.dx, rearTip.dy)
    ..close();

  return SimaiSlideFeedbackGeometry._(
    arrowPath: path,
    points: measure.points,
    cumulativeDistances: measure.cumulativeDistances,
    length: length,
  );
}

Path buildSimaiWifiFeedbackArcPath({
  required Offset center,
  required double radius,
  required double thickness,
  required double startAngle,
  required double sweepAngle,
}) {
  if (!radius.isFinite ||
      !thickness.isFinite ||
      !startAngle.isFinite ||
      !sweepAngle.isFinite ||
      radius <= 0 ||
      thickness <= 0 ||
      sweepAngle.abs() <= 1e-9) {
    return Path();
  }
  final halfThickness = min(thickness / 2, radius * 0.9);
  final outerRadius = radius + halfThickness;
  final innerRadius = max(0.5, radius - halfThickness);
  return Path()
    ..arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      true,
    )
    ..arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    )
    ..close();
}
