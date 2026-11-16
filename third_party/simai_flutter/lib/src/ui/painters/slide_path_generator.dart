import 'dart:math';
import 'dart:ui';

import '../../structures/location.dart';
import '../../structures/note_group.dart';
import '../../structures/slide_type.dart';

/// Generates slide geometry in the same normalized coordinate system used by
/// AstroDX's `SlideGenerators`.
class SlidePathGenerator {
  // AstroDX expresses these values through RenderManager. The existing Flutter
  // renderer uses the play-field radius as its input and the same center-ring
  // proportion for q/p, s/z and qq/pp slides.
  static const double _centerRadiusRatio = 0.39;
  static const double _edgeCurveRadiusScale = 1.2;
  static const double _edgeCurveCenterRadiusRatio = 0.4662;
  static const double _edgeCurveCenterAngle = 3 * pi / 8; // 67.5 degrees.
  static const double _defaultWrapThreshold = pi / 16; // AstroDX: tau / 32.
  static const double _edgeCurveWrapThreshold = pi / 2;

  static Path generatePath(
    SlideType type,
    Location start,
    List<Location> vertices,
    Offset center,
    double radius, {
    Path? path,
  }) {
    path ??= Path();

    final startPosition = _getStartPosition(type, start, center, radius);
    if (path.computeMetrics().isEmpty) {
      path.moveTo(startPosition.dx, startPosition.dy);
    } else {
      path.lineTo(startPosition.dx, startPosition.dy);
    }

    if (vertices.isEmpty) return path;

    final end = vertices.last;

    switch (type) {
      case SlideType.straightLine:
        _lineTo(path, _getPosition(end, center, radius));
        break;

      case SlideType.ringCw:
      case SlideType.ringCcw:
        _addRing(
          path,
          start,
          end,
          center,
          radius,
          clockwise: type == SlideType.ringCw,
        );
        break;

      case SlideType.fold:
        _lineTo(path, center);
        _lineTo(path, _getPosition(end, center, radius));
        break;

      case SlideType.curveCw:
      case SlideType.curveCcw:
        _addCenterCurve(
          path,
          start,
          end,
          center,
          radius,
          clockwise: type == SlideType.curveCw,
        );
        break;

      case SlideType.zigZagS:
      case SlideType.zigZagZ:
        _addZigZag(
          path,
          start,
          end,
          center,
          radius,
          isZ: type == SlideType.zigZagZ,
        );
        break;

      case SlideType.edgeFold:
        if (vertices.length >= 2) {
          _lineTo(path, _getPosition(vertices[0], center, radius));
          _lineTo(path, _getPosition(vertices[1], center, radius));
        }
        break;

      case SlideType.edgeCurveCw:
      case SlideType.edgeCurveCcw:
        _addEdgeCurve(
          path,
          start,
          end,
          center,
          radius,
          clockwise: type == SlideType.edgeCurveCw,
        );
        break;

      case SlideType.fan:
        _addFan(path, start, center, radius);
        break;
    }

    return path;
  }

  static void _addCenterCurve(
    Path path,
    Location start,
    Location end,
    Offset center,
    double playFieldRadius, {
    required bool clockwise,
  }) {
    final curveRadius = playFieldRadius * _centerRadiusRatio;
    final startRotation = _getRotation(start);
    final endRotation = _getRotation(end);
    final tangentDelta = acos((curveRadius / playFieldRadius).clamp(-1.0, 1.0));

    // Flutter's Y axis points down, so AstroDX's clockwise (decreasing Unity
    // angle) becomes an increasing screen-space angle.
    final tangentInRotation = clockwise
        ? startRotation + tangentDelta
        : startRotation - tangentDelta;
    final tangentOutRotation = clockwise
        ? endRotation - tangentDelta
        : endRotation + tangentDelta;

    final tangentIn = _getRadialPosition(
      tangentInRotation,
      curveRadius,
      center,
    );
    final endPosition = _getRadialPosition(
      endRotation,
      playFieldRadius,
      center,
    );

    _lineTo(path, tangentIn);
    final span = _getAngleSpan(
      tangentInRotation,
      tangentOutRotation,
      clockwise: clockwise,
    );
    _addArc(
      path,
      center: center,
      radius: curveRadius,
      startAngle: tangentInRotation,
      sweepAngle: clockwise ? span : -span,
    );
    _lineTo(path, endPosition);
  }

  static void _addEdgeCurve(
    Path path,
    Location start,
    Location end,
    Offset center,
    double playFieldRadius, {
    required bool clockwise,
  }) {
    final curveRadius =
        playFieldRadius * _centerRadiusRatio * _edgeCurveRadiusScale;
    final startRotation = _getRotation(start);
    final endRotation = _getRotation(end);

    final curveCenterRotation = clockwise
        ? startRotation - _edgeCurveCenterAngle
        : startRotation + _edgeCurveCenterAngle;
    final curveCenter = _getRadialPosition(
      curveCenterRotation,
      playFieldRadius * _edgeCurveCenterRadiusRatio,
      center,
    );

    final startPosition = _getRadialPosition(
      startRotation,
      playFieldRadius,
      center,
    );
    final endPosition = _getRadialPosition(
      endRotation,
      playFieldRadius,
      center,
    );

    final relativeStartRotation = _polarAngle(startPosition, curveCenter);
    final relativeEndRotation = _polarAngle(endPosition, curveCenter);
    final startMagnitude = (startPosition - curveCenter).distance;
    final endMagnitude = (endPosition - curveCenter).distance;
    final startDelta = acos((curveRadius / startMagnitude).clamp(-1.0, 1.0));
    final endDelta = acos((curveRadius / endMagnitude).clamp(-1.0, 1.0));

    final tangentInRotation = clockwise
        ? relativeStartRotation + startDelta
        : relativeStartRotation - startDelta;
    final tangentOutRotation = clockwise
        ? relativeEndRotation - endDelta
        : relativeEndRotation + endDelta;
    final tangentIn = _getRadialPosition(
      tangentInRotation,
      curveRadius,
      curveCenter,
    );

    _lineTo(path, tangentIn);
    final span = _getAngleSpan(
      tangentInRotation,
      tangentOutRotation,
      clockwise: clockwise,
      wrapThreshold: _edgeCurveWrapThreshold,
    );
    _addArc(
      path,
      center: curveCenter,
      radius: curveRadius,
      startAngle: tangentInRotation,
      sweepAngle: clockwise ? span : -span,
    );
    _lineTo(path, endPosition);
  }

  static void _addRing(
    Path path,
    Location start,
    Location end,
    Offset center,
    double playFieldRadius, {
    required bool clockwise,
  }) {
    final startRotation = _getRotation(start);
    final endRotation = _getRotation(end);
    final startRadius = _getRadius(start, playFieldRadius);
    final endRadius = _getRadius(end, playFieldRadius);
    final span = _getAngleSpan(
      startRotation,
      endRotation,
      clockwise: clockwise,
    );

    if ((startRadius - endRadius).abs() < 1e-6) {
      _addArc(
        path,
        center: center,
        radius: startRadius,
        startAngle: startRotation,
        sweepAngle: clockwise ? span : -span,
      );
      return;
    }

    // AstroDX linearly interpolates the radius while traversing the angle.
    // Approximate that Archimedean spiral with enough short segments to keep
    // PathMetric positions and rotations stable for sensor endpoints.
    final segmentCount = max(16, (span / (pi / 64)).ceil());
    for (var i = 1; i <= segmentCount; i++) {
      final t = i / segmentCount;
      final angle = startRotation + (clockwise ? span : -span) * t;
      final radius = startRadius + (endRadius - startRadius) * t;
      _lineTo(path, _getRadialPosition(angle, radius, center));
    }
  }

  static void _addZigZag(
    Path path,
    Location start,
    Location end,
    Offset center,
    double playFieldRadius, {
    required bool isZ,
  }) {
    final innerRadius = playFieldRadius * _centerRadiusRatio;
    final screenAngleOffset = isZ ? pi / 2 : -pi / 2;
    final startZag = _getRadialPosition(
      _getRotation(start) + screenAngleOffset,
      innerRadius,
      center,
    );
    final endZag = _getRadialPosition(
      _getRotation(end) + screenAngleOffset,
      innerRadius,
      center,
    );
    final endPosition = _getRadialPosition(
      _getRotation(end),
      playFieldRadius,
      center,
    );

    _lineTo(path, startZag);
    _lineTo(path, endZag);
    _lineTo(path, endPosition);
  }

  static void _addFan(
    Path path,
    Location start,
    Offset center,
    double playFieldRadius,
  ) {
    final startPosition = _getPosition(start, center, playFieldRadius);
    final leftEnd = _getPosition(
      Location((start.index + 3) % 8, start.group),
      center,
      playFieldRadius,
    );
    final centerEnd = _getPosition(
      Location((start.index + 4) % 8, start.group),
      center,
      playFieldRadius,
    );
    final rightEnd = _getPosition(
      Location((start.index + 5) % 8, start.group),
      center,
      playFieldRadius,
    );

    _lineTo(path, centerEnd);
    path.moveTo(startPosition.dx, startPosition.dy);
    _lineTo(path, leftEnd);
    path.moveTo(startPosition.dx, startPosition.dy);
    _lineTo(path, rightEnd);
  }

  static double _getAngleSpan(
    double startRotation,
    double endRotation, {
    required bool clockwise,
    double wrapThreshold = _defaultWrapThreshold,
  }) {
    const tau = 2 * pi;
    var span = clockwise
        ? (endRotation - startRotation + 2 * tau) % tau
        : (startRotation - endRotation + 2 * tau) % tau;
    if (span <= wrapThreshold) span += tau;
    return span;
  }

  static void _addArc(
    Path path, {
    required Offset center,
    required double radius,
    required double startAngle,
    required double sweepAngle,
  }) {
    if (radius <= 0 || sweepAngle == 0) return;

    // Flutter may collapse sweeps at or above a full revolution. Breaking the
    // arc into <= pi chunks preserves AstroDX's deliberate wrapped paths.
    final rect = Rect.fromCircle(center: center, radius: radius);
    final chunkCount = max(1, (sweepAngle.abs() / pi).ceil());
    final chunkSweep = sweepAngle / chunkCount;
    for (var i = 0; i < chunkCount; i++) {
      path.arcTo(rect, startAngle + chunkSweep * i, chunkSweep, false);
    }
  }

  static Offset _getPosition(
    Location location,
    Offset center,
    double playFieldRadius,
  ) {
    return _getRadialPosition(
      _getRotation(location),
      _getRadius(location, playFieldRadius),
      center,
    );
  }

  static Offset _getStartPosition(
    SlideType type,
    Location location,
    Offset center,
    double playFieldRadius,
  ) {
    switch (type) {
      case SlideType.curveCw:
      case SlideType.curveCcw:
      case SlideType.zigZagS:
      case SlideType.zigZagZ:
      case SlideType.edgeCurveCw:
      case SlideType.edgeCurveCcw:
        return _getRadialPosition(
          _getRotation(location),
          playFieldRadius,
          center,
        );
      case SlideType.straightLine:
      case SlideType.ringCw:
      case SlideType.ringCcw:
      case SlideType.fold:
      case SlideType.edgeFold:
      case SlideType.fan:
        return _getPosition(location, center, playFieldRadius);
    }
  }

  static double _getRotation(Location location) {
    var angle = (-67.5 + location.index * 45) * pi / 180;
    if (location.group == NoteGroup.dSensor ||
        location.group == NoteGroup.eSensor) {
      angle -= pi / 8;
    }
    return angle;
  }

  static double _getRadius(Location location, double playFieldRadius) {
    switch (location.group) {
      case NoteGroup.tap:
        return playFieldRadius;
      case NoteGroup.aSensor:
      case NoteGroup.dSensor:
        return playFieldRadius * 0.8;
      case NoteGroup.bSensor:
        return playFieldRadius * 0.4;
      case NoteGroup.cSensor:
        return 0;
      case NoteGroup.eSensor:
        return playFieldRadius * 0.45;
    }
  }

  static Offset _getRadialPosition(double angle, double radius, Offset center) {
    return Offset(
      center.dx + cos(angle) * radius,
      center.dy + sin(angle) * radius,
    );
  }

  static double _polarAngle(Offset position, Offset center) {
    final relative = position - center;
    return atan2(relative.dy, relative.dx);
  }

  static void _lineTo(Path path, Offset point) {
    path.lineTo(point.dx, point.dy);
  }
}
