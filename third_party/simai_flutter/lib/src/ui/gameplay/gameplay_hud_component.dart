import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../gameplay/gameplay_models.dart';
import '../../gameplay/gameplay_session.dart';
import '../../structures/location.dart';
import '../../structures/note_group.dart';
import '../note_geometry.dart';
import '../rendering/precalc_data.dart';
import '../simai_game.dart';
import '../utils/note_utils.dart';
import 'judgement_display.dart';
import 'slide_feedback_geometry.dart';

class GameplayHudComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  GameplayHudComponent(this.session);

  final SimaiGameplaySession session;
  int _lastRevision = -1;
  double _lastDimension = -1;
  TextPainter? _centerValuePainter;
  TextPainter? _centerLabelPainter;
  TextPainter? _autoPainter;

  static const TextStyle _hudStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 17,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
  );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _lastDimension = -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final dimension = min(size.x, size.y);
    if (_lastRevision == session.revision && _lastDimension == dimension) {
      return;
    }
    _lastRevision = session.revision;
    _lastDimension = dimension;
    _rebuildCenterDisplay(dimension);
    if (session.summary.autoAssistNotes > 0) {
      _autoPainter = _text(
        'AUTO ASSIST ${session.summary.autoAssistNotes}',
        _hudStyle.copyWith(color: const Color(0xFF80CBC4), fontSize: 12),
      );
    } else {
      _autoPainter = null;
    }
  }

  void _rebuildCenterDisplay(double dimension) {
    final mode = session.settings.centerDisplayMode;
    final value = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd =>
        '${session.achievement.toStringAsFixed(4)}%',
      SimaiGameplayCenterDisplayMode.achievement101Subtract =>
        '${session.achievement101Remaining.toStringAsFixed(4)}%',
      SimaiGameplayCenterDisplayMode.achievement100Subtract =>
        '${session.achievement100Remaining.toStringAsFixed(4)}%',
      SimaiGameplayCenterDisplayMode.combo => session.currentCombo.toString(),
      SimaiGameplayCenterDisplayMode.dxScoreAdd => session.dxScore.toString(),
      SimaiGameplayCenterDisplayMode.dxScoreSubtract =>
        session.remainingDxScore.toString(),
    };
    final label = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd ||
      SimaiGameplayCenterDisplayMode.achievement101Subtract ||
      SimaiGameplayCenterDisplayMode.achievement100Subtract => 'ACHIEVEMENT',
      SimaiGameplayCenterDisplayMode.combo => 'COMBO',
      SimaiGameplayCenterDisplayMode.dxScoreAdd ||
      SimaiGameplayCenterDisplayMode.dxScoreSubtract => 'DX SCORE',
    };
    final valueSize = (dimension * 0.065).clamp(22.0, 42.0).toDouble();
    _centerValuePainter = _text(
      value,
      _hudStyle.copyWith(
        fontSize: valueSize,
        color: Colors.white.withValues(alpha: 0.88),
        letterSpacing: -0.5,
      ),
    );
    _centerLabelPainter = _text(
      label,
      _hudStyle.copyWith(
        fontSize: (valueSize * 0.34).clamp(9.0, 13.0).toDouble(),
        color: Colors.white.withValues(alpha: 0.62),
        letterSpacing: 1.2,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    _paintCenterDisplay(canvas);

    final auto = _autoPainter;
    if (auto != null) {
      auto.paint(canvas, Offset(size.x - auto.width - 12, 12));
    }

    for (final record in session.recentFeedback(
      game.chartTime,
      duration: simaiJudgementFeedbackDuration,
    )) {
      if (record.isAuto) continue;
      final presentation = SimaiJudgementPresentation.forRecord(
        record,
        session.settings.judgementDisplayMode,
      );
      final note =
          game.chart.noteCollections[record.collectionIndex][record.noteIndex];
      final feedbackLocation = record.slidePathIndex == null
          ? note.location
          : note.slidePaths[record.slidePathIndex!].segments.isEmpty
          ? note.location
          : note.slidePaths[record.slidePathIndex!].segments.last.vertices.last;
      final mirroredLocation = NoteUtils.mirrorLocation(
        feedbackLocation,
        game.mirrorMode,
      );
      final position = _feedbackPosition(mirroredLocation);
      final timingFirst = mirroredLocation.group == NoteGroup.tap
          ? _tapTimingFirst(mirroredLocation.index)
          : position.dy <= game.chartCenter.dy;
      final lines = presentation.lines(timingFirst: timingFirst);
      if (lines.isEmpty) continue;
      final age = max(0.0, game.chartTime - record.judgedTime);
      final animation = simaiJudgementAnimationAt(age);
      if (!animation.visible) continue;
      if (record.slidePathIndex != null &&
          _paintSlideFeedback(
            canvas,
            record: record,
            lines: lines,
            color: presentation.color,
            animation: animation,
          )) {
        continue;
      }
      _paintFeedbackLines(
        canvas,
        lines: lines,
        position: position,
        animation: animation,
      );
    }
  }

  void _paintCenterDisplay(Canvas canvas) {
    final value = _centerValuePainter;
    final label = _centerLabelPainter;
    if (value == null || label == null) return;
    final valueOffset = Offset(
      (size.x - value.width) / 2,
      (size.y - value.height) / 2,
    );
    final labelOffset = Offset(
      (size.x - label.width) / 2,
      valueOffset.dy - label.height - max(2.0, value.height * 0.05),
    );
    label.paint(canvas, labelOffset);
    value.paint(canvas, valueOffset);
  }

  Offset _feedbackPosition(Location location) {
    final center = game.chartCenter;
    final radius = game.chartRadius;
    if (location.group == NoteGroup.tap) {
      final judgePoint = NoteUtils.getTouchPosition(center, radius, location);
      final direction = judgePoint - center;
      return center + direction / max(direction.distance, 1e-9) * radius * 0.80;
    }
    if (location.group == NoteGroup.cSensor) {
      return center + Offset(0, radius * 0.18);
    }
    final sensorPoint = NoteUtils.getTouchPosition(center, radius, location);
    final direction = sensorPoint - center;
    final distance = direction.distance;
    if (distance <= 1e-9) return center;
    final displayRadius = (distance + radius * 0.11)
        .clamp(radius * 0.34, radius * 0.78)
        .toDouble();
    return center + direction / distance * displayRadius;
  }

  void _paintFeedbackLines(
    Canvas canvas, {
    required List<SimaiJudgementLine> lines,
    required Offset position,
    required SimaiJudgementAnimationState animation,
  }) {
    final fontSize = (game.chartRadius * 0.052).clamp(12.0, 18.0).toDouble();
    final center = game.chartCenter;
    final delta = position - center;
    final baseRadius = delta.distance;
    if (baseRadius <= 1e-9) return;
    final centerAngle = atan2(delta.dy, delta.dx);
    final clockwise = delta.dy <= 0;
    final lineOffset = fontSize * 0.58;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.scale(animation.scale, animation.scale);
    canvas.translate(-position.dx, -position.dy);
    for (var index = 0; index < lines.length; index++) {
      final radiusOffset = lines.length == 1
          ? 0.0
          : index == 0
          ? (clockwise ? lineOffset : -lineOffset)
          : (clockwise ? -lineOffset : lineOffset);
      _paintArcTextLine(
        canvas,
        line: lines[index],
        center: center,
        centerAngle: centerAngle,
        radius: max(fontSize * 2, baseRadius + radiusOffset),
        clockwise: clockwise,
        fontSize: fontSize,
        opacity: animation.opacity,
      );
    }
    canvas.restore();
  }

  void _paintArcTextLine(
    Canvas canvas, {
    required SimaiJudgementLine line,
    required Offset center,
    required double centerAngle,
    required double radius,
    required bool clockwise,
    required double fontSize,
    required double opacity,
  }) {
    final style = _hudStyle.copyWith(
      color: line.color.withValues(alpha: opacity),
      fontSize: fontSize,
      letterSpacing: 0.25,
    );
    final painters = <TextPainter>[
      for (final glyph in line.text.split('')) _text(glyph, style),
    ];
    final placements = simaiArcGlyphLayout(
      advances: painters.map((painter) => painter.width).toList(),
      centerAngle: centerAngle,
      radius: radius,
      clockwise: clockwise,
    );
    for (var index = 0; index < painters.length; index++) {
      final painter = painters[index];
      final placement = placements[index];
      final glyphCenter =
          center + Offset(cos(placement.angle), sin(placement.angle)) * radius;
      canvas.save();
      canvas.translate(glyphCenter.dx, glyphCenter.dy);
      canvas.rotate(placement.rotation);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  bool _paintSlideFeedback(
    Canvas canvas, {
    required SimaiJudgementRecord record,
    required List<SimaiJudgementLine> lines,
    required Color color,
    required SimaiJudgementAnimationState animation,
  }) {
    final slidePathIndex = record.slidePathIndex;
    if (slidePathIndex == null) return false;
    final key = '${record.collectionIndex}_${record.noteIndex}_$slidePathIndex';
    final data = game.precalcData.slides[key];
    if (data == null) return false;
    if (data.fanStarCenterX != null &&
        data.fanStarCenterY != null &&
        data.fanStarLeftX != null &&
        data.fanStarLeftY != null &&
        data.fanStarRightX != null &&
        data.fanStarRightY != null) {
      return _paintWifiFeedback(
        canvas,
        data: data,
        lines: lines,
        color: color,
        animation: animation,
      );
    }
    final xs = data.starX ?? data.fanStarCenterX;
    final ys = data.starY ?? data.fanStarCenterY;
    if (xs == null || ys == null || xs.length < 2 || ys.length < 2) {
      return false;
    }

    final drawScale = game.chartRadius / 300.0;
    final tailPoints = simaiSlideFeedbackTailPoints(
      xs: xs,
      ys: ys,
      totalLength: data.totalLength,
      normalizedTailLength: 108.0,
      drawScale: drawScale,
      center: game.chartCenter,
    );
    final geometry = buildSimaiSlideFeedbackGeometry(
      pathPoints: tailPoints,
      halfWidth: NoteGeometry.slideArrowHalfWidth * game.noteScale,
      chevronDepth: NoteGeometry.slideArrowChevronDepth * game.noteScale,
    );
    if (geometry == null) return false;

    final textAnchor = geometry.pointAt(geometry.length * 0.34);
    canvas.save();
    canvas.translate(textAnchor.dx, textAnchor.dy);
    canvas.scale(animation.scale, animation.scale);
    canvas.translate(-textAnchor.dx, -textAnchor.dy);

    final fadeStart = geometry.pointAt(0);
    final fadeEnd = geometry.pointAt(geometry.length * 0.34);
    final shadowPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(fadeStart, fadeEnd, [
        Colors.transparent,
        Colors.black.withValues(alpha: animation.opacity * 0.34),
      ])
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        game.chartRadius * 0.018,
      );
    canvas.save();
    canvas.translate(0, game.chartRadius * 0.012);
    canvas.drawPath(geometry.arrowPath, shadowPaint);
    canvas.restore();

    final fillPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.linear(fadeStart, fadeEnd, [
        color.withValues(alpha: 0),
        color.withValues(alpha: animation.opacity * 0.96),
      ]);
    canvas.drawPath(geometry.arrowPath, fillPaint);
    _paintSlideFeedbackText(
      canvas,
      geometry: geometry,
      lines: lines,
      opacity: animation.opacity,
    );
    canvas.restore();
    return true;
  }

  bool _paintWifiFeedback(
    Canvas canvas, {
    required PrecalcSlideData data,
    required List<SimaiJudgementLine> lines,
    required Color color,
    required SimaiJudgementAnimationState animation,
  }) {
    final centerX = data.fanStarCenterX!;
    final centerY = data.fanStarCenterY!;
    final leftX = data.fanStarLeftX!;
    final leftY = data.fanStarLeftY!;
    final rightX = data.fanStarRightX!;
    final rightY = data.fanStarRightY!;
    if (centerX.isEmpty ||
        centerY.isEmpty ||
        leftX.isEmpty ||
        leftY.isEmpty ||
        rightX.isEmpty ||
        rightY.isEmpty) {
      return false;
    }

    final drawScale = game.chartRadius / 300.0;
    final centerEnd =
        Offset(centerX.last, centerY.last) * drawScale + game.chartCenter;
    final leftEnd =
        Offset(leftX.last, leftY.last) * drawScale + game.chartCenter;
    final rightEnd =
        Offset(rightX.last, rightY.last) * drawScale + game.chartCenter;
    final centerAngle = atan2(
      centerEnd.dy - game.chartCenter.dy,
      centerEnd.dx - game.chartCenter.dx,
    );
    final leftOffset = _normalizedAngleOffset(
      atan2(
            leftEnd.dy - game.chartCenter.dy,
            leftEnd.dx - game.chartCenter.dx,
          ) -
          centerAngle,
    );
    final rightOffset = _normalizedAngleOffset(
      atan2(
            rightEnd.dy - game.chartCenter.dy,
            rightEnd.dx - game.chartCenter.dx,
          ) -
          centerAngle,
    );
    final minimumOffset = min(leftOffset, rightOffset) - 0.055;
    final maximumOffset = max(leftOffset, rightOffset) + 0.055;
    final sweep = maximumOffset - minimumOffset;
    if (sweep <= 0.05 || sweep > pi) return false;
    final arcStart = centerAngle + minimumOffset;
    final arcEnd = centerAngle + maximumOffset;

    final radius = game.chartRadius * 0.875;
    final thickness = game.chartRadius * 0.155;
    final arcPath = buildSimaiWifiFeedbackArcPath(
      center: game.chartCenter,
      radius: radius,
      thickness: thickness,
      startAngle: arcStart,
      sweepAngle: sweep,
    );
    final textAnchor =
        game.chartCenter + Offset(cos(centerAngle), sin(centerAngle)) * radius;

    canvas.save();
    canvas.translate(textAnchor.dx, textAnchor.dy);
    canvas.scale(animation.scale, animation.scale);
    canvas.translate(-textAnchor.dx, -textAnchor.dy);

    final shadowPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..shader = ui.Gradient.sweep(
        game.chartCenter,
        [
          Colors.transparent,
          Colors.black.withValues(alpha: animation.opacity * 0.34),
          Colors.black.withValues(alpha: animation.opacity * 0.34),
          Colors.transparent,
        ],
        const [0.0, 0.18, 0.82, 1.0],
        TileMode.clamp,
        arcStart,
        arcEnd,
      )
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        game.chartRadius * 0.018,
      );
    canvas.save();
    canvas.translate(0, game.chartRadius * 0.012);
    canvas.drawPath(arcPath, shadowPaint);
    canvas.restore();
    canvas.drawPath(
      arcPath,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.sweep(
          game.chartCenter,
          [
            color.withValues(alpha: 0),
            color.withValues(alpha: animation.opacity * 0.96),
            color.withValues(alpha: animation.opacity * 0.96),
            color.withValues(alpha: 0),
          ],
          const [0.0, 0.18, 0.82, 1.0],
          TileMode.clamp,
          arcStart,
          arcEnd,
        ),
    );

    final fontSize = (game.chartRadius * 0.045).clamp(10.0, 16.0).toDouble();
    final clockwise = sin(centerAngle) <= 0;
    final lineOffset = fontSize * 0.52;
    for (var index = 0; index < lines.length; index++) {
      final radiusOffset = lines.length == 1
          ? 0.0
          : index == 0
          ? (clockwise ? lineOffset : -lineOffset)
          : (clockwise ? -lineOffset : lineOffset);
      _paintArcTextLine(
        canvas,
        line: SimaiJudgementLine(text: lines[index].text, color: Colors.white),
        center: game.chartCenter,
        centerAngle: centerAngle,
        radius: radius + radiusOffset,
        clockwise: clockwise,
        fontSize: fontSize,
        opacity: animation.opacity,
      );
    }
    canvas.restore();
    return true;
  }

  static double _normalizedAngleOffset(double angle) {
    var result = angle;
    while (result <= -pi) {
      result += 2 * pi;
    }
    while (result > pi) {
      result -= 2 * pi;
    }
    return result;
  }

  void _paintSlideFeedbackText(
    Canvas canvas, {
    required SimaiSlideFeedbackGeometry geometry,
    required List<SimaiJudgementLine> lines,
    required double opacity,
  }) {
    var fontSize = (game.chartRadius * 0.043).clamp(10.0, 15.5).toDouble();
    final availableWidth = geometry.length * 0.68;
    final probeStyle = _hudStyle.copyWith(fontSize: fontSize, letterSpacing: 0);
    final widest = lines.fold<double>(0.0, (width, line) {
      return max(width, _text(line.text, probeStyle).width);
    });
    if (widest > availableWidth && widest > 0) {
      fontSize *= availableWidth / widest;
    }
    fontSize = max(8.0, fontSize);

    final centerDistance = geometry.length * 0.34;
    final centerAngle = geometry.angleAt(centerDistance);
    final forward = cos(centerAngle) >= 0;
    final pathDirection = forward ? 1.0 : -1.0;
    final lineGap = fontSize * 0.48;

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final style = _hudStyle.copyWith(
        color: Colors.white.withValues(alpha: opacity),
        fontSize: fontSize,
        letterSpacing: 0,
        shadows: <Shadow>[
          Shadow(
            color: Colors.black.withValues(alpha: opacity * 0.66),
            blurRadius: 2,
          ),
        ],
      );
      final painters = <TextPainter>[
        for (final glyph in lines[lineIndex].text.split(''))
          _text(glyph, style),
      ];
      final totalWidth = painters.fold<double>(
        0.0,
        (sum, painter) => sum + painter.width,
      );
      var cursor = -totalWidth / 2;
      final lateralOffset = lines.length == 1
          ? 0.0
          : lineIndex == 0
          ? -lineGap
          : lineGap;
      for (final painter in painters) {
        final glyphDistance =
            (centerDistance + pathDirection * (cursor + painter.width / 2))
                .clamp(0.0, geometry.length)
                .toDouble();
        final angle = geometry.angleAt(glyphDistance);
        var normal = Offset(-sin(angle), cos(angle));
        if (normal.dy < 0) normal = -normal;
        final position =
            geometry.pointAt(glyphDistance) + normal * lateralOffset;
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(angle + (forward ? 0.0 : pi));
        painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
        canvas.restore();
        cursor += painter.width;
      }
    }
  }

  static bool _tapTimingFirst(int index) =>
      index == 6 || index == 7 || index == 0 || index == 1;

  static TextPainter _text(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
