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
    required this.fadeStart,
    required this.fadeEnd,
    required this.textAnchor,
    required this.centerAngle,
  });

  final Path arrowPath;
  final List<Offset> points;
  final List<double> cumulativeDistances;
  final double length;

  /// 缓存箭尾淡入起点（距离 0），供 HUD 直接复用而无需每帧二分采样。
  final Offset fadeStart;

  /// 缓存箭尾淡入终点（距离 0.34 * length）。
  final Offset fadeEnd;

  /// 缓存判定文字缩放锚点（距离 0.34 * length）。
  final Offset textAnchor;

  /// 缓存锚点处切线角度。
  final double centerAngle;

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

/// WiFi 滑星判定圆弧几何缓存，避免每帧重复计算角度与重建 Path。
@immutable
class SimaiWifiFeedbackGeometry {
  const SimaiWifiFeedbackGeometry({
    required this.arcPath,
    required this.centerAngle,
    required this.arcStart,
    required this.arcEnd,
    required this.radius,
    required this.textAnchor,
    required this.clockwise,
  });

  final Path arcPath;
  final double centerAngle;
  final double arcStart;
  final double arcEnd;
  final double radius;
  final Offset textAnchor;
  final bool clockwise;
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
    fadeStart: Offset.zero,
    fadeEnd: Offset.zero,
    textAnchor: Offset.zero,
    centerAngle: 0.0,
  );
  // 拉长版常规滑星箭头：前后均采用 `>` 折线，再沿尾段路径连接两侧边缘点。
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

  final fadeStart = measure.pointAt(0);
  final anchorDistance = length * 0.34;
  final anchorPoint = measure.pointAt(anchorDistance);
  final centerAngle = measure.angleAt(anchorDistance);

  return SimaiSlideFeedbackGeometry._(
    arrowPath: path,
    points: measure.points,
    cumulativeDistances: measure.cumulativeDistances,
    length: length,
    fadeStart: fadeStart,
    fadeEnd: anchorPoint,
    textAnchor: anchorPoint,
    centerAngle: centerAngle,
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

/// 构建可复用的 WiFi 滑星判定圆弧几何对象，避免逐帧三角计算与重建 Path。
SimaiWifiFeedbackGeometry? buildSimaiWifiFeedbackGeometry({
  required List<double> centerX,
  required List<double> centerY,
  required List<double> leftX,
  required List<double> leftY,
  required List<double> rightX,
  required List<double> rightY,
  required Offset chartCenter,
  required double chartRadius,
}) {
  if (!chartRadius.isFinite ||
      chartRadius <= 0 ||
      centerX.isEmpty ||
      centerY.isEmpty ||
      leftX.isEmpty ||
      leftY.isEmpty ||
      rightX.isEmpty ||
      rightY.isEmpty) {
    return null;
  }

  final drawScale = chartRadius / 300.0;
  final centerEnd = Offset(centerX.last, centerY.last) * drawScale + chartCenter;
  final leftEnd = Offset(leftX.last, leftY.last) * drawScale + chartCenter;
  final rightEnd = Offset(rightX.last, rightY.last) * drawScale + chartCenter;
  final centerAngle = atan2(
    centerEnd.dy - chartCenter.dy,
    centerEnd.dx - chartCenter.dx,
  );
  final leftOffset = _normalizedWifiAngleOffset(
    atan2(leftEnd.dy - chartCenter.dy, leftEnd.dx - chartCenter.dx) -
        centerAngle,
  );
  final rightOffset = _normalizedWifiAngleOffset(
    atan2(rightEnd.dy - chartCenter.dy, rightEnd.dx - chartCenter.dx) -
        centerAngle,
  );
  final minimumOffset = min(leftOffset, rightOffset) - 0.055;
  final maximumOffset = max(leftOffset, rightOffset) + 0.055;
  final sweep = maximumOffset - minimumOffset;
  if (sweep <= 0.05 || sweep > pi) return null;

  final arcStart = centerAngle + minimumOffset;
  final arcEnd = centerAngle + maximumOffset;
  final radius = chartRadius * 0.875;
  final thickness = chartRadius * 0.155;
  final arcPath = buildSimaiWifiFeedbackArcPath(
    center: chartCenter,
    radius: radius,
    thickness: thickness,
    startAngle: arcStart,
    sweepAngle: sweep,
  );
  final textAnchor =
      chartCenter + Offset(cos(centerAngle), sin(centerAngle)) * radius;

  return SimaiWifiFeedbackGeometry(
    arcPath: arcPath,
    centerAngle: centerAngle,
    arcStart: arcStart,
    arcEnd: arcEnd,
    radius: radius,
    textAnchor: textAnchor,
    clockwise: sin(centerAngle) <= 0,
  );
}

double _normalizedWifiAngleOffset(double angle) {
  var result = angle;
  while (result <= -pi) {
    result += 2 * pi;
  }
  while (result > pi) {
    result -= 2 * pi;
  }
  return result;
}
