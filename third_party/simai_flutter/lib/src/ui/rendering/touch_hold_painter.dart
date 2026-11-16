import 'dart:math';

import 'package:flutter/material.dart';

import '../simai_colors.dart';
import '../utils/note_utils.dart';

/// Flat TouchHold styling with maimai-chart-engine geometry at radius 300.
class TouchHoldPainter {
  static const double openDistance = 300 / 6.25 * 1.1;
  static const double closedDistance = 300 / 12.5 * 1.3;
  static const double centerRadius = 300 / 37.5 * 0.8;
  static const double progressHalf = 99.75 * 300 / 480;
  static const _angles = [-pi / 4, pi / 4, 3 * pi / 4, -3 * pi / 4];
  static const _colors = [
    SimaiColors.touchHoldTopRight,
    SimaiColors.touchHoldBottomRight,
    SimaiColors.touchHoldBottomLeft,
    SimaiColors.touchHoldTopLeft,
  ];
  static final Path progressRing = Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(_roundedDiamond(97.75, 82.75), Offset.zero)
    // Keep the outer silhouette and reduce the band width by 30%.
    ..addPath(_roundedDiamond(74.125, 60.175), Offset.zero);
  static final _petals = [
    for (final angle in _angles)
      NoteUtils.roundedTrianglePath(
        Offset.fromDirection(angle + pi, closedDistance),
        Offset.fromDirection(angle + pi / 2, closedDistance),
        Offset.fromDirection(angle - pi / 2, closedDistance),
        8,
      ),
  ];
  static double petalDistance(double progress) {
    final p = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;
    return openDistance - (openDistance - closedDistance) * p * p * p * p;
  }

  static void paint(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required double timeUntilHead,
    required double approachTime,
    required double duration,
    required bool isEach,
  }) {
    if (!scale.isFinite ||
        scale <= 0 ||
        !timeUntilHead.isFinite ||
        !approachTime.isFinite ||
        approachTime <= 0 ||
        timeUntilHead > approachTime ||
        timeUntilHead < -duration - 0.05) {
      return;
    }
    final alpha = timeUntilHead > approachTime * 0.95
        ? (1 - (timeUntilHead - approachTime * 0.95) / (approachTime * 0.05))
              .clamp(0.0, 1.0)
        : 1.0;
    final age = approachTime - timeUntilHead;
    final petalAlpha = timeUntilHead > 0 ? (age / 0.15).clamp(0.0, 1.0) : 1.0;
    final distance = petalDistance(1 - timeUntilHead / approachTime);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    if (timeUntilHead < 0 && duration > 0) {
      _paintProgress(
        canvas,
        (-timeUntilHead / duration).clamp(0.0, 1.0),
        alpha,
      );
    }
    final opacity = (255 * alpha * petalAlpha).round();
    for (var index = 0; index < 4; index++) {
      final position = Offset.fromDirection(_angles[index], distance);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      final path = _petals[index];
      canvas.drawPath(path, Paint()..color = _colors[index].withAlpha(opacity));
      canvas.drawPath(path, _stroke(Colors.white, 3, opacity));
      canvas.restore();
    }
    final dotAlpha = (255 * alpha).round();
    canvas.drawCircle(
      Offset.zero,
      centerRadius,
      Paint()
        ..color = (isEach ? const Color(0xFFFFFF00) : const Color(0xFF00BFFF))
            .withAlpha(dotAlpha),
    );
    canvas.drawCircle(
      Offset.zero,
      centerRadius,
      _stroke(Colors.white, 3, dotAlpha),
    );
    canvas.restore();
  }

  static Paint _stroke(Color color, double width, int alpha) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..color = color.withAlpha(alpha);

  static void _paintProgress(Canvas canvas, double progress, double alpha) {
    canvas.save();
    canvas.clipPath(progressRing);
    if (progress < 1) {
      canvas.clipPath(
        Path()
          ..moveTo(0, 0)
          ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: progressHalf),
            -pi / 2,
            progress * pi * 2,
            false,
          )
          ..close(),
      );
    }
    for (var index = 0; index < 4; index++) {
      final direction = Offset.fromDirection(_angles[index]);
      canvas.drawRect(
        Rect.fromLTWH(
          direction.dx > 0 ? 0 : -progressHalf,
          direction.dy > 0 ? 0 : -progressHalf,
          progressHalf,
          progressHalf,
        ),
        Paint()..color = _colors[index].withAlpha((255 * alpha).round()),
      );
    }
    canvas.restore();
  }

  static Path _roundedDiamond(double axis, double diagonal) {
    const unit = 300 / 480;
    final radius = diagonal * sqrt2 * unit;
    final offset = 2 * (radius - axis * unit);
    return Path()
      ..moveTo(-offset, -radius + offset)
      ..quadraticBezierTo(0, -radius, offset, -radius + offset)
      ..lineTo(radius - offset, -offset)
      ..quadraticBezierTo(radius, 0, radius - offset, offset)
      ..lineTo(offset, radius - offset)
      ..quadraticBezierTo(0, radius, -offset, radius - offset)
      ..lineTo(-radius + offset, offset)
      ..quadraticBezierTo(-radius, 0, -radius + offset, -offset)
      ..close();
  }
}
