import 'dart:math';
import 'dart:ui';

import '../../../simai_flutter.dart';

class NoteUtils {
  static Location mirrorLocation(Location location, SimaiMirrorMode mode) {
    return SimaiMirrorUtils.mirrorLocation(location, mode);
  }

  static SlideType mirrorSlideType(SlideType type, SimaiMirrorMode mode) {
    return SimaiMirrorUtils.mirrorSlideType(type, mode);
  }

  static Offset getTouchPosition(Offset center, double radius, Location loc) {
    if (loc.group == NoteGroup.cSensor) return center;
    if (loc.group == NoteGroup.aSensor) {
      final double r = radius * (4.0 / 4.8);
      final double angle = (-67.5 + loc.index * 45) * pi / 180;
      return center + Offset(r * cos(angle), r * sin(angle));
    }
    if (loc.group == NoteGroup.bSensor) {
      final double r = radius * (2.2 / 4.8);
      final double angle = (-67.5 + loc.index * 45) * pi / 180;
      return center + Offset(r * cos(angle), r * sin(angle));
    }
    if (loc.group == NoteGroup.dSensor) {
      final double r = radius * (4.1 / 4.8);
      final double angle = (-90 + loc.index * 45) * pi / 180;
      return center + Offset(r * cos(angle), r * sin(angle));
    }
    if (loc.group == NoteGroup.eSensor) {
      final double r = radius * (3.1 / 4.8);
      final double angle = (-90 + loc.index * 45) * pi / 180;
      return center + Offset(r * cos(angle), r * sin(angle));
    }
    final double angle = (-67.5 + loc.index * 45) * pi / 180;
    return Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
  }

  static Path createStarPath(double r) {
    Path path = Path();
    double angle = 0; // Start at Right (0 deg) to point forward
    double step = pi / 5; // 36 degrees
    // Star fatness ratio (inner radius / outer radius of the star points)
    double starShapeRatio = 0.5;
    double rIn = r * starShapeRatio;

    path.moveTo(r * cos(angle), r * sin(angle));

    for (int i = 1; i < 10; i++) {
      double currentR = (i % 2 == 0) ? r : rIn;
      double currentAngle = angle + i * step;
      path.lineTo(currentR * cos(currentAngle), currentR * sin(currentAngle));
    }
    path.close();
    return path;
  }

  static Path roundedTrianglePath(
    Offset p0,
    Offset p1,
    Offset p2,
    double radius,
  ) {
    final List<Offset> pts = [p0, p1, p2];
    final List<Offset> starts = List.filled(3, Offset.zero);
    final List<Offset> ends = List.filled(3, Offset.zero);

    for (int i = 0; i < 3; i++) {
      final Offset prev = pts[(i + 2) % 3];
      final Offset curr = pts[i];
      final Offset next = pts[(i + 1) % 3];
      final Offset v1 = prev - curr;
      final Offset v2 = next - curr;
      final double len1 = v1.distance;
      final double len2 = v2.distance;
      double r = radius;
      if (len1 > 0) r = min(r, len1 / 2);
      if (len2 > 0) r = min(r, len2 / 2);
      final Offset s = curr + (len1 == 0 ? Offset.zero : v1 / len1 * r);
      final Offset e = curr + (len2 == 0 ? Offset.zero : v2 / len2 * r);
      starts[i] = s;
      ends[i] = e;
    }

    final Path path = Path()..moveTo(ends[0].dx, ends[0].dy);
    path.lineTo(starts[1].dx, starts[1].dy);
    path.quadraticBezierTo(pts[1].dx, pts[1].dy, ends[1].dx, ends[1].dy);
    path.lineTo(starts[2].dx, starts[2].dy);
    path.quadraticBezierTo(pts[2].dx, pts[2].dy, ends[2].dx, ends[2].dy);
    path.lineTo(starts[0].dx, starts[0].dy);
    path.quadraticBezierTo(pts[0].dx, pts[0].dy, ends[0].dx, ends[0].dy);
    path.close();
    return path;
  }
}
