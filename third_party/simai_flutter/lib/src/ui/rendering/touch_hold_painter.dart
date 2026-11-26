import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../note_style.dart';
import '../simai_colors.dart';
import '../utils/note_utils.dart';

/// TouchHold 绘制器（支持经典扁平与官方机台还原两种样式，基于 300 逻辑半径）。
class TouchHoldPainter {
  static const double openDistance = 300 / 6.25 * 1.1;
  static const double closedDistance = 300 / 12.5 * 1.3;
  static const double centerRadius = 300 / 37.5 * 0.8;
  static const double progressHalf = 99.75 * 300 / 480;
  static const double _wedgeRadius = progressHalf * sqrt2;
  static const _angles = [-pi / 4, pi / 4, 3 * pi / 4, -3 * pi / 4];
  static const _colors = [
    SimaiColors.touchHoldTopRight,
    SimaiColors.touchHoldBottomRight,
    SimaiColors.touchHoldBottomLeft,
    SimaiColors.touchHoldTopLeft,
  ];
  // 借鉴 LXNS TouchRenderer：四片花瓣的官方机台四段纵向渐变与进度环四色。
  static const _arcadePalettes = <List<Color>>[
    [Color(0xFFFF5511), Color(0xFFF74601), Color(0xFFE74201), Color(0xFFFFF6F2)],
    [Color(0xFFF8DE00), Color(0xFFF6ED00), Color(0xFFECF402), Color(0xFFFFFBEF)],
    [Color(0xFF1EB476), Color(0xFF12A86A), Color(0xFF0AA062), Color(0xFFECFFF8)],
    [Color(0xFF00AAF8), Color(0xFF0097F6), Color(0xFF0289F4), Color(0xFFEFFCFF)],
  ];
  static const _arcadeProgressColors = <Color>[
    Color(0xFFE95513),
    Color(0xFFFAED00),
    Color(0xFF0DAC67),
    Color(0xFF2CA6E0),
  ];

  // 按顺时针顺序（起点 -pi/2）预计算四个象限矩形，避免每帧分配 Rect。
  static const _quadrantRects = <Rect>[
    Rect.fromLTWH(0, -progressHalf, progressHalf, progressHalf),
    Rect.fromLTWH(0, 0, progressHalf, progressHalf),
    Rect.fromLTWH(-progressHalf, 0, progressHalf, progressHalf),
    Rect.fromLTWH(-progressHalf, -progressHalf, progressHalf, progressHalf),
  ];

  // 复用静态 Paint 与扇形 Path，避免热路径每帧堆分配。
  static final Paint _fillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;
  static final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  static final Path _wedgePath = Path();
  static final Rect _wedgeBounds = Rect.fromCircle(
    center: Offset.zero,
    radius: _wedgeRadius,
  );

  static final Path progressRing = Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(_roundedDiamond(97.75, 82.75), Offset.zero)
    // 保持外轮廓不变，将环带宽度收窄 30%。
    ..addPath(_roundedDiamond(74.125, 60.175), Offset.zero);
  static final Path arcadeProgressRing = Path()
    ..fillType = PathFillType.evenOdd
    ..addPath(_roundedDiamond(97.75, 82.75), Offset.zero)
    ..addPath(_roundedDiamond(64.0, 50.5), Offset.zero);
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
    SimaiNoteStyle noteStyle = SimaiNoteStyle.arcade,
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
    final bool arcade = noteStyle == SimaiNoteStyle.arcade;
    final double strokeWidth = arcade ? 2.0 : 3.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    if (timeUntilHead < 0 && duration > 0) {
      _paintProgress(
        canvas,
        (-timeUntilHead / duration).clamp(0.0, 1.0),
        alpha,
        arcade: arcade,
      );
    }
    final opacity = (255 * alpha * petalAlpha).round();
    for (var index = 0; index < 4; index++) {
      final position = Offset.fromDirection(_angles[index], distance);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      final path = _petals[index];
      if (arcade) {
        _strokePaint
          ..strokeWidth = strokeWidth * 3.0
          ..color = Colors.black.withAlpha(opacity);
        canvas.drawPath(path, _strokePaint);

        final palette = _arcadePalettes[index];
        final tip = Offset.fromDirection(_angles[index] + pi, closedDistance);
        _fillPaint
          ..color = Colors.white.withAlpha(opacity)
          ..shader = ui.Gradient.linear(
            Offset.zero,
            tip,
            [
              palette[0].withAlpha(opacity),
              palette[1].withAlpha(opacity),
              palette[2].withAlpha(opacity),
              palette[3].withAlpha(opacity),
            ],
            const [0.0, 0.35, 0.72, 1.0],
          );
        canvas.drawPath(path, _fillPaint);
        _fillPaint.shader = null;
      } else {
        _fillPaint
          ..shader = null
          ..color = _colors[index].withAlpha(opacity);
        canvas.drawPath(path, _fillPaint);
      }
      _strokePaint
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withAlpha(opacity);
      canvas.drawPath(path, _strokePaint);
      canvas.restore();
    }
    final dotAlpha = (255 * alpha).round();
    if (arcade) {
      _strokePaint
        ..strokeWidth = strokeWidth * 3.0
        ..color = Colors.black.withAlpha(dotAlpha);
      canvas.drawCircle(Offset.zero, centerRadius, _strokePaint);
    }
    _fillPaint
      ..shader = null
      ..color = (isEach ? const Color(0xFFFFFF00) : const Color(0xFF00BFFF))
          .withAlpha(dotAlpha);
    _strokePaint
      ..strokeWidth = strokeWidth
      ..color = Colors.white.withAlpha(dotAlpha);
    canvas.drawCircle(Offset.zero, centerRadius, _fillPaint);
    canvas.drawCircle(Offset.zero, centerRadius, _strokePaint);
    canvas.restore();
  }

  /// 仅保留单层 progressRing 裁切：完整象限直接画矩形，当前推进象限绘制扇形，
  /// 彻底消除双层非矩形 clipPath 嵌套带来的 GPU 模板开销。
  static void _paintProgress(
    Canvas canvas,
    double progress,
    double alpha, {
    required bool arcade,
  }) {
    if (progress <= 0) return;
    final int paintAlpha = (255 * alpha).round().clamp(0, 255);
    const double unit = 300 / 480;
    canvas.save();
    canvas.clipPath(arcade ? arcadeProgressRing : progressRing);
    final double scaledProgress = progress * 4.0;
    for (var index = 0; index < 4; index++) {
      final double quadProgress = (scaledProgress - index).clamp(0.0, 1.0);
      if (quadProgress <= 0.0) break;
      if (arcade) {
        final angle = -pi / 4 + index * (pi / 2);
        final dx = cos(angle);
        final dy = sin(angle);
        final c = _arcadeProgressColors[index];
        _fillPaint
          ..color = Colors.white.withAlpha(paintAlpha)
          ..shader = ui.Gradient.linear(
            Offset(dx * 50.5 * unit, dy * 50.5 * unit),
            Offset(dx * 82.75 * unit, dy * 82.75 * unit),
            [
              Color.lerp(c, Colors.black, 0.28)!.withAlpha(paintAlpha),
              c.withAlpha(paintAlpha),
              Color.lerp(c, Colors.white, 0.32)!.withAlpha(paintAlpha),
              Color.lerp(c, Colors.white, 0.08)!.withAlpha(paintAlpha),
            ],
            const [0.0, 0.35, 0.72, 1.0],
          );
      } else {
        _fillPaint
          ..shader = null
          ..color = _colors[index].withAlpha(paintAlpha);
      }
      if (quadProgress >= 1.0) {
        canvas.drawRect(_quadrantRects[index], _fillPaint);
      } else {
        final double startAngle = -pi / 2 + index * (pi / 2);
        _wedgePath
          ..reset()
          ..moveTo(0, 0)
          ..arcTo(_wedgeBounds, startAngle, quadProgress * (pi / 2), false)
          ..close();
        canvas.drawPath(_wedgePath, _fillPaint);
      }
    }
    _fillPaint.shader = null;
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
