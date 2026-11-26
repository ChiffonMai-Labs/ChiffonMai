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
import '../simai_mirror.dart';
import '../utils/note_utils.dart';
import 'judgement_display.dart';
import 'slide_feedback_geometry.dart';

/// 预烘焙判定文字位图条目（含源像素矩形与逻辑锚点矩形，销毁时释放 GPU 纹理）。
class _BakedTextBitmap {
  const _BakedTextBitmap({
    required this.image,
    required this.sourceRect,
    required this.localBounds,
  });

  final ui.Image image;
  final Rect sourceRect;
  final Rect localBounds;

  void dispose() => image.dispose();
}

class GameplayHudComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  GameplayHudComponent(this.session);

  final SimaiGameplaySession session;

  // 中心与右上角显示仅监听 scoreRevision 与模式/尺寸变化，避免触控微移引发重建。
  int _lastScoreRevision = -1;
  double _lastDimension = -1;
  SimaiGameplayCenterDisplayMode? _lastCenterMode;
  SimaiGameplayCenterDisplayMode? _lastTopRightMode;
  int _lastAutoAssistNotes = -1;
  TextPainter? _centerValuePainter;
  TextPainter? _centerLabelPainter;
  TextPainter? _topRightPainter;
  TextPainter? _autoPainter;

  // 判定文字位图与滑星几何缓存（按量化后的盘面半径失效重建并显式释放旧 ui.Image）。
  static const double _bitmapPixelRatio = 2.0;
  static const int _maxArcWordCacheEntries = 96;

  int _cachedQuantizedRadius = -1;
  int _cachedCenterX = 0;
  int _cachedCenterY = 0;
  SimaiMirrorMode? _cachedMirrorMode;
  PrecalcChartData? _cachedPrecalcData;

  final Map<String, _BakedTextBitmap> _arcWordBitmaps =
      <String, _BakedTextBitmap>{};
  final Map<String, SimaiSlideFeedbackGeometry?> _slideGeometryCache =
      <String, SimaiSlideFeedbackGeometry?>{};
  final Map<String, SimaiWifiFeedbackGeometry?> _wifiGeometryCache =
      <String, SimaiWifiFeedbackGeometry?>{};
  final Map<String, _BakedTextBitmap> _slideTextBitmaps =
      <String, _BakedTextBitmap>{};
  final Set<String> _activeSlideTextKeys = <String>{};

  // 复用静态/成员画笔，运行时零临时 Paint 与零 MaskFilter.blur。
  final Paint _bitmapPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final Paint _slideShadowFillPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final Paint _slideShadowStrokePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  final Paint _slideFillPaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;

  static const TextStyle _hudBaseStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 17,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

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
    final scoreRevision = session.scoreRevision;
    final mode = session.settings.centerDisplayMode;
    final topRightMode = session.settings.topRightDisplayMode;
    final autoAssistNotes = session.summary.autoAssistNotes;
    if (_lastScoreRevision == scoreRevision &&
        _lastDimension == dimension &&
        _lastCenterMode == mode &&
        _lastTopRightMode == topRightMode &&
        _lastAutoAssistNotes == autoAssistNotes) {
      return;
    }
    _lastScoreRevision = scoreRevision;
    _lastDimension = dimension;
    _lastCenterMode = mode;
    _lastTopRightMode = topRightMode;
    _lastAutoAssistNotes = autoAssistNotes;
    _rebuildCenterDisplay(dimension);
    _rebuildTopRightDisplay(topRightMode);

    _autoPainter?.dispose();
    if (autoAssistNotes > 0) {
      _autoPainter = _text(
        'AUTO ASSIST $autoAssistNotes',
        _hudStyle.copyWith(color: const Color(0xFF80CBC4), fontSize: 12),
      );
    } else {
      _autoPainter = null;
    }
  }

  /// 格式化 4 位小数百分比，避免浮点误差产生 `-0.0000%`。
  static String _formatPercent(double value) {
    final normalized = value.abs() < 0.00005 ? 0.0 : value;
    return '${normalized.toStringAsFixed(4)}%';
  }

  void _rebuildCenterDisplay(double dimension) {
    final mode = session.settings.centerDisplayMode;
    if (mode == SimaiGameplayCenterDisplayMode.none) {
      _centerValuePainter?.dispose();
      _centerLabelPainter?.dispose();
      _centerValuePainter = null;
      _centerLabelPainter = null;
      return;
    }
    final value = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd => _formatPercent(
        session.achievement,
      ),
      SimaiGameplayCenterDisplayMode.achievement100Plus => _formatPercent(
        session.achievement100Plus,
      ),
      SimaiGameplayCenterDisplayMode.achievement101Subtract => _formatPercent(
        session.achievement101Remaining,
      ),
      SimaiGameplayCenterDisplayMode.dxScoreAdd => session.dxScore.toString(),
      SimaiGameplayCenterDisplayMode.dxScoreSubtract =>
        session.remainingDxScore.toString(),
      SimaiGameplayCenterDisplayMode.dxStars => session.dxStarBonusText,
      SimaiGameplayCenterDisplayMode.combo => session.currentCombo.toString(),
      SimaiGameplayCenterDisplayMode.overS => _formatPercent(
        session.achievementOverS,
      ),
      SimaiGameplayCenterDisplayMode.overSS => _formatPercent(
        session.achievementOverSS,
      ),
      SimaiGameplayCenterDisplayMode.overSSS => _formatPercent(
        session.achievementOverSSS,
      ),
      SimaiGameplayCenterDisplayMode.none => '',
    };
    final label = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd ||
      SimaiGameplayCenterDisplayMode.achievement100Plus ||
      SimaiGameplayCenterDisplayMode.achievement101Subtract => 'ACHIEVEMENT',
      SimaiGameplayCenterDisplayMode.dxScoreAdd ||
      SimaiGameplayCenterDisplayMode.dxScoreSubtract => 'DX SCORE',
      SimaiGameplayCenterDisplayMode.dxStars => 'DX STAR',
      SimaiGameplayCenterDisplayMode.combo => 'COMBO',
      SimaiGameplayCenterDisplayMode.overS => 'S BORDER',
      SimaiGameplayCenterDisplayMode.overSS => 'SS BORDER',
      SimaiGameplayCenterDisplayMode.overSSS => 'SSS BORDER',
      SimaiGameplayCenterDisplayMode.none => '',
    };
    final valueSize = (dimension * 0.065).clamp(22.0, 42.0).toDouble();
    _centerValuePainter?.dispose();
    _centerValuePainter = _text(
      value,
      _hudStyle.copyWith(
        fontSize: valueSize,
        color: Colors.white.withValues(alpha: 0.88),
        letterSpacing: -0.5,
      ),
    );
    _centerLabelPainter?.dispose();
    _centerLabelPainter = _text(
      label,
      _hudStyle.copyWith(
        fontSize: (valueSize * 0.34).clamp(9.0, 13.0).toDouble(),
        color: Colors.white.withValues(alpha: 0.62),
        letterSpacing: 1.2,
      ),
    );
  }

  /// 构建游玩态右上角 11 模式统计文本。
  void _rebuildTopRightDisplay(SimaiGameplayCenterDisplayMode mode) {
    _topRightPainter?.dispose();
    if (mode == SimaiGameplayCenterDisplayMode.none) {
      _topRightPainter = null;
      return;
    }
    final text = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd =>
        'ACHV ${_formatPercent(session.achievement)}',
      SimaiGameplayCenterDisplayMode.achievement100Plus =>
        'ACHV ${_formatPercent(session.achievement100Plus)}',
      SimaiGameplayCenterDisplayMode.achievement101Subtract =>
        'ACHV ${_formatPercent(session.achievement101Remaining)}',
      SimaiGameplayCenterDisplayMode.dxScoreAdd =>
        'DX ${session.dxScore} / ${session.totalDxScore}',
      SimaiGameplayCenterDisplayMode.dxScoreSubtract =>
        'DX ${session.remainingDxScore}',
      SimaiGameplayCenterDisplayMode.dxStars => session.dxStarBonusText,
      SimaiGameplayCenterDisplayMode.combo =>
        'COMBO ${session.currentCombo} / ${session.totalScoringNotes}',
      SimaiGameplayCenterDisplayMode.overS =>
        'S ${_formatPercent(session.achievementOverS)}',
      SimaiGameplayCenterDisplayMode.overSS =>
        'SS ${_formatPercent(session.achievementOverSS)}',
      SimaiGameplayCenterDisplayMode.overSSS =>
        'SSS ${_formatPercent(session.achievementOverSSS)}',
      SimaiGameplayCenterDisplayMode.none => '',
    };
    if (text.isEmpty) {
      _topRightPainter = null;
      return;
    }
    _topRightPainter = _text(
      text,
      _hudStyle.copyWith(fontSize: 14, color: Colors.white),
    );
  }

  /// 检测盘面半径、中心点、镜像模式或预计算数据变更，及时释放旧位图并清空几何缓存。
  void _syncCachesForMetrics() {
    final int quantizedRadius = (game.chartRadius * 2.0).round();
    final int centerX = (game.chartCenter.dx * 2.0).round();
    final int centerY = (game.chartCenter.dy * 2.0).round();
    final bool radiusChanged = quantizedRadius != _cachedQuantizedRadius;
    final bool geometryChanged =
        radiusChanged ||
        centerX != _cachedCenterX ||
        centerY != _cachedCenterY ||
        game.mirrorMode != _cachedMirrorMode ||
        !identical(game.precalcData, _cachedPrecalcData);

    if (radiusChanged) {
      _disposeArcWordBitmaps();
      _cachedQuantizedRadius = quantizedRadius;
    }
    if (geometryChanged) {
      _slideGeometryCache.clear();
      _wifiGeometryCache.clear();
      _disposeSlideTextBitmaps();
      _cachedCenterX = centerX;
      _cachedCenterY = centerY;
      _cachedMirrorMode = game.mirrorMode;
      _cachedPrecalcData = game.precalcData;
    }
  }

  void _disposeArcWordBitmaps() {
    for (final bitmap in _arcWordBitmaps.values) {
      bitmap.dispose();
    }
    _arcWordBitmaps.clear();
  }

  void _disposeSlideTextBitmaps() {
    for (final bitmap in _slideTextBitmaps.values) {
      bitmap.dispose();
    }
    _slideTextBitmaps.clear();
  }

  void _pruneExpiredSlideTextBitmaps() {
    if (_slideTextBitmaps.isEmpty) return;
    if (_activeSlideTextKeys.isEmpty) {
      _disposeSlideTextBitmaps();
      return;
    }
    if (_slideTextBitmaps.length == _activeSlideTextKeys.length) return;
    List<String>? expired;
    for (final key in _slideTextBitmaps.keys) {
      if (!_activeSlideTextKeys.contains(key)) {
        (expired ??= <String>[]).add(key);
      }
    }
    if (expired != null) {
      for (final key in expired) {
        _slideTextBitmaps.remove(key)?.dispose();
      }
    }
  }

  @override
  void onRemove() {
    _centerValuePainter?.dispose();
    _centerLabelPainter?.dispose();
    _topRightPainter?.dispose();
    _autoPainter?.dispose();
    _centerValuePainter = null;
    _centerLabelPainter = null;
    _topRightPainter = null;
    _autoPainter = null;
    _disposeArcWordBitmaps();
    _disposeSlideTextBitmaps();
    _slideGeometryCache.clear();
    _wifiGeometryCache.clear();
    _cachedPrecalcData = null;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    _paintCenterDisplay(canvas);

    final topRight = _topRightPainter;
    var autoTop = 12.0;
    if (topRight != null) {
      topRight.paint(canvas, Offset(size.x - topRight.width - 12, 12));
      autoTop = 12.0 + topRight.height + 4.0;
    }

    final auto = _autoPainter;
    if (auto != null) {
      auto.paint(canvas, Offset(size.x - auto.width - 12, autoTop));
    }

    if (game.chartRadius <= 0 || !game.chartRadius.isFinite) return;
    _syncCachesForMetrics();
    _activeSlideTextKeys.clear();

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

    // 清理本帧已过期的滑星判定文字位图，防止显存累积。
    _pruneExpiredSlideTextBitmaps();
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

  /// 通过预烘焙弧形字样位图绘制单行判定文字，运行时仅执行 1 次 drawImageRect。
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
    final int alpha = (opacity * 255).round().clamp(0, 255);
    if (alpha <= 0 || line.text.isEmpty) return;

    final bitmap = _obtainArcWordBitmap(
      text: line.text,
      color: line.color,
      fontSize: fontSize,
      radius: radius,
      clockwise: clockwise,
    );
    if (bitmap == null) return;

    final Offset midpoint =
        center + Offset(cos(centerAngle), sin(centerAngle)) * radius;
    final double targetRotation = clockwise
        ? centerAngle + pi / 2
        : centerAngle - pi / 2;

    _bitmapPaint.color = Color.fromARGB(alpha, 255, 255, 255);
    canvas.save();
    canvas.translate(midpoint.dx, midpoint.dy);
    canvas.rotate(targetRotation);
    canvas.drawImageRect(
      bitmap.image,
      bitmap.sourceRect,
      bitmap.localBounds,
      _bitmapPaint,
    );
    canvas.restore();
  }

  _BakedTextBitmap? _obtainArcWordBitmap({
    required String text,
    required Color color,
    required double fontSize,
    required double radius,
    required bool clockwise,
  }) {
    // 半径按 4px 分桶、字号按 0.5px 量化，使各轨道共享同一份判定字样位图。
    final int quantizedFontSize = (fontSize * 2.0).round();
    final int radiusBucket = (radius / 4.0).round();
    final double bakedFontSize = quantizedFontSize / 2.0;
    final double bakedRadius = max(bakedFontSize * 2.0, radiusBucket * 4.0);
    final int colorValue = color.toARGB32();
    final String key =
        '$text|$colorValue|$quantizedFontSize|$radiusBucket|${clockwise ? 1 : 0}';

    final existing = _arcWordBitmaps[key];
    if (existing != null) return existing;

    final baked = _bakeArcWordBitmap(
      text: text,
      color: color,
      fontSize: bakedFontSize,
      radius: bakedRadius,
      clockwise: clockwise,
    );
    if (baked == null) return null;

    if (_arcWordBitmaps.length >= _maxArcWordCacheEntries) {
      final oldestKey = _arcWordBitmaps.keys.first;
      _arcWordBitmaps.remove(oldestKey)?.dispose();
    }
    _arcWordBitmaps[key] = baked;
    return baked;
  }

  /// 将有限判定词表中的单个词按弧线布局烘焙为带描边阴影的 ui.Image，并立即释放临时 TextPainter。
  _BakedTextBitmap? _bakeArcWordBitmap({
    required String text,
    required Color color,
    required double fontSize,
    required double radius,
    required bool clockwise,
  }) {
    final glyphs = text.split('');
    if (glyphs.isEmpty) return null;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.6, fontSize * 0.14)
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.82);

    final fillStyle = _hudStyle.copyWith(
      color: color,
      fontSize: fontSize,
      letterSpacing: 0.25,
      shadows: const [Shadow(color: Colors.black, blurRadius: 3.5)],
    );
    final outlineStyle = _hudBaseStyle.copyWith(
      foreground: outlinePaint,
      fontSize: fontSize,
      letterSpacing: 0.25,
    );

    final fillPainters = <TextPainter>[];
    final outlinePainters = <TextPainter>[];
    try {
      for (final glyph in glyphs) {
        fillPainters.add(_text(glyph, fillStyle));
        outlinePainters.add(_text(glyph, outlineStyle));
      }

      final bakeCenterAngle = clockwise ? -pi / 2 : pi / 2;
      final placements = simaiArcGlyphLayout(
        advances: fillPainters.map((p) => p.width).toList(growable: false),
        centerAngle: bakeCenterAngle,
        radius: radius,
        clockwise: clockwise,
      );
      if (placements.isEmpty) return null;

      final anchorOrigin = Offset(0.0, clockwise ? -radius : radius);
      final double margin = fontSize * 0.45 + 6.0;
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      final centers = <Offset>[];
      for (var i = 0; i < fillPainters.length; i++) {
        final painter = fillPainters[i];
        final placement = placements[i];
        final relCenter =
            Offset(cos(placement.angle), sin(placement.angle)) * radius -
            anchorOrigin;
        centers.add(relCenter);
        final double halfExtent =
            hypotHalf(painter.width, painter.height) + margin;
        if (relCenter.dx - halfExtent < minX) minX = relCenter.dx - halfExtent;
        if (relCenter.dy - halfExtent < minY) minY = relCenter.dy - halfExtent;
        if (relCenter.dx + halfExtent > maxX) maxX = relCenter.dx + halfExtent;
        if (relCenter.dy + halfExtent > maxY) maxY = relCenter.dy + halfExtent;
      }

      final double logicalW = max(1.0, maxX - minX);
      final double logicalH = max(1.0, maxY - minY);
      final int pxW = max(1, (logicalW * _bitmapPixelRatio).ceil());
      final int pxH = max(1, (logicalH * _bitmapPixelRatio).ceil());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..scale(_bitmapPixelRatio, _bitmapPixelRatio)
        ..translate(-minX, -minY);

      for (var i = 0; i < fillPainters.length; i++) {
        final fillPainter = fillPainters[i];
        final outlinePainter = outlinePainters[i];
        final relCenter = centers[i];
        final offset = Offset(-fillPainter.width / 2, -fillPainter.height / 2);
        canvas.save();
        canvas.translate(relCenter.dx, relCenter.dy);
        canvas.rotate(placements[i].rotation);
        outlinePainter.paint(canvas, offset);
        fillPainter.paint(canvas, offset);
        canvas.restore();
      }

      final picture = recorder.endRecording();
      try {
        final image = picture.toImageSync(pxW, pxH);
        return _BakedTextBitmap(
          image: image,
          sourceRect: Rect.fromLTWH(0, 0, pxW.toDouble(), pxH.toDouble()),
          localBounds: Rect.fromLTWH(
            minX,
            minY,
            pxW / _bitmapPixelRatio,
            pxH / _bitmapPixelRatio,
          ),
        );
      } finally {
        picture.dispose();
      }
    } finally {
      for (final painter in fillPainters) {
        painter.dispose();
      }
      for (final painter in outlinePainters) {
        painter.dispose();
      }
    }
  }

  static double hypotHalf(double width, double height) =>
      0.5 * sqrt(width * width + height * height);

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
        slideKey: key,
        data: data,
        lines: lines,
        color: color,
        animation: animation,
      );
    }

    final geometry = _obtainSlideGeometry(key, data);
    if (geometry == null) return false;

    final textAnchor = geometry.textAnchor;
    canvas.save();
    canvas.translate(textAnchor.dx, textAnchor.dy);
    canvas.scale(animation.scale, animation.scale);
    canvas.translate(-textAnchor.dx, -textAnchor.dy);

    final fadeStart = geometry.fadeStart;
    final fadeEnd = geometry.fadeEnd;

    // 移除运行时 MaskFilter.blur，改用无模糊半透明底层填充 + 柔和暗色外描边表现投影层次。
    _slideShadowStrokePaint
      ..strokeWidth = game.chartRadius * 0.018
      ..shader = ui.Gradient.linear(fadeStart, fadeEnd, [
        Colors.transparent,
        Colors.black.withValues(alpha: animation.opacity * 0.16),
      ]);
    _slideShadowFillPaint.shader = ui.Gradient.linear(fadeStart, fadeEnd, [
      Colors.transparent,
      Colors.black.withValues(alpha: animation.opacity * 0.28),
    ]);
    canvas.save();
    canvas.translate(0, game.chartRadius * 0.010);
    canvas.drawPath(geometry.arrowPath, _slideShadowStrokePaint);
    canvas.drawPath(geometry.arrowPath, _slideShadowFillPaint);
    canvas.restore();
    _slideShadowStrokePaint.shader = null;
    _slideShadowFillPaint.shader = null;

    _slideFillPaint.shader = ui.Gradient.linear(fadeStart, fadeEnd, [
      color.withValues(alpha: 0),
      color.withValues(alpha: animation.opacity * 0.96),
    ]);
    canvas.drawPath(geometry.arrowPath, _slideFillPaint);
    _slideFillPaint.shader = null;

    _paintSlideFeedbackTextCached(
      canvas,
      slideKey: key,
      geometry: geometry,
      lines: lines,
      opacity: animation.opacity,
    );
    canvas.restore();
    return true;
  }

  SimaiSlideFeedbackGeometry? _obtainSlideGeometry(
    String slideKey,
    PrecalcSlideData data,
  ) {
    if (_slideGeometryCache.containsKey(slideKey)) {
      return _slideGeometryCache[slideKey];
    }
    final xs = data.starX ?? data.fanStarCenterX;
    final ys = data.starY ?? data.fanStarCenterY;
    SimaiSlideFeedbackGeometry? geometry;
    if (xs != null && ys != null && xs.length >= 2 && ys.length >= 2) {
      final drawScale = game.chartRadius / 300.0;
      final tailPoints = simaiSlideFeedbackTailPoints(
        xs: xs,
        ys: ys,
        totalLength: data.totalLength,
        normalizedTailLength: 108.0,
        drawScale: drawScale,
        center: game.chartCenter,
      );
      geometry = buildSimaiSlideFeedbackGeometry(
        pathPoints: tailPoints,
        halfWidth: NoteGeometry.slideArrowHalfWidth * game.noteScale,
        chevronDepth: NoteGeometry.slideArrowChevronDepth * game.noteScale,
      );
    }
    _slideGeometryCache[slideKey] = geometry;
    return geometry;
  }

  SimaiWifiFeedbackGeometry? _obtainWifiGeometry(
    String slideKey,
    PrecalcSlideData data,
  ) {
    if (_wifiGeometryCache.containsKey(slideKey)) {
      return _wifiGeometryCache[slideKey];
    }
    final geometry = buildSimaiWifiFeedbackGeometry(
      centerX: data.fanStarCenterX!,
      centerY: data.fanStarCenterY!,
      leftX: data.fanStarLeftX!,
      leftY: data.fanStarLeftY!,
      rightX: data.fanStarRightX!,
      rightY: data.fanStarRightY!,
      chartCenter: game.chartCenter,
      chartRadius: game.chartRadius,
    );
    _wifiGeometryCache[slideKey] = geometry;
    return geometry;
  }

  bool _paintWifiFeedback(
    Canvas canvas, {
    required String slideKey,
    required PrecalcSlideData data,
    required List<SimaiJudgementLine> lines,
    required Color color,
    required SimaiJudgementAnimationState animation,
  }) {
    final geometry = _obtainWifiGeometry(slideKey, data);
    if (geometry == null) return false;

    final textAnchor = geometry.textAnchor;
    canvas.save();
    canvas.translate(textAnchor.dx, textAnchor.dy);
    canvas.scale(animation.scale, animation.scale);
    canvas.translate(-textAnchor.dx, -textAnchor.dy);

    // 移除运行时 MaskFilter.blur，改用无模糊半透明底层填充与柔和外描边。
    _slideShadowStrokePaint
      ..strokeWidth = game.chartRadius * 0.018
      ..shader = ui.Gradient.sweep(
        game.chartCenter,
        [
          Colors.transparent,
          Colors.black.withValues(alpha: animation.opacity * 0.16),
          Colors.black.withValues(alpha: animation.opacity * 0.16),
          Colors.transparent,
        ],
        const [0.0, 0.18, 0.82, 1.0],
        TileMode.clamp,
        geometry.arcStart,
        geometry.arcEnd,
      );
    _slideShadowFillPaint.shader = ui.Gradient.sweep(
      game.chartCenter,
      [
        Colors.transparent,
        Colors.black.withValues(alpha: animation.opacity * 0.28),
        Colors.black.withValues(alpha: animation.opacity * 0.28),
        Colors.transparent,
      ],
      const [0.0, 0.18, 0.82, 1.0],
      TileMode.clamp,
      geometry.arcStart,
      geometry.arcEnd,
    );
    canvas.save();
    canvas.translate(0, game.chartRadius * 0.010);
    canvas.drawPath(geometry.arcPath, _slideShadowStrokePaint);
    canvas.drawPath(geometry.arcPath, _slideShadowFillPaint);
    canvas.restore();
    _slideShadowStrokePaint.shader = null;
    _slideShadowFillPaint.shader = null;

    _slideFillPaint.shader = ui.Gradient.sweep(
      game.chartCenter,
      [
        color.withValues(alpha: 0),
        color.withValues(alpha: animation.opacity * 0.96),
        color.withValues(alpha: animation.opacity * 0.96),
        color.withValues(alpha: 0),
      ],
      const [0.0, 0.18, 0.82, 1.0],
      TileMode.clamp,
      geometry.arcStart,
      geometry.arcEnd,
    );
    canvas.drawPath(geometry.arcPath, _slideFillPaint);
    _slideFillPaint.shader = null;

    final fontSize = (game.chartRadius * 0.045).clamp(10.0, 16.0).toDouble();
    final clockwise = geometry.clockwise;
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
        centerAngle: geometry.centerAngle,
        radius: geometry.radius + radiusOffset,
        clockwise: clockwise,
        fontSize: fontSize,
        opacity: animation.opacity,
      );
    }
    canvas.restore();
    return true;
  }

  /// 按滑星条目缓存沿轨迹弯曲的判定文字位图，动画持续期间仅 drawImageRect，过期自动 dispose。
  void _paintSlideFeedbackTextCached(
    Canvas canvas, {
    required String slideKey,
    required SimaiSlideFeedbackGeometry geometry,
    required List<SimaiJudgementLine> lines,
    required double opacity,
  }) {
    final int alpha = (opacity * 255).round().clamp(0, 255);
    if (alpha <= 0 || lines.isEmpty) return;

    final String textKey = lines.length == 1
        ? lines[0].text
        : '${lines[0].text}\n${lines[1].text}';
    final String cacheKey = '$slideKey|$textKey';
    _activeSlideTextKeys.add(cacheKey);

    var bitmap = _slideTextBitmaps[cacheKey];
    if (bitmap == null) {
      bitmap = _bakeSlideTextBitmap(geometry: geometry, lines: lines);
      if (bitmap == null) return;
      _slideTextBitmaps[cacheKey] = bitmap;
    }

    _bitmapPaint.color = Color.fromARGB(alpha, 255, 255, 255);
    canvas.drawImageRect(
      bitmap.image,
      bitmap.sourceRect,
      bitmap.localBounds,
      _bitmapPaint,
    );
  }

  _BakedTextBitmap? _bakeSlideTextBitmap({
    required SimaiSlideFeedbackGeometry geometry,
    required List<SimaiJudgementLine> lines,
  }) {
    var fontSize = (game.chartRadius * 0.043).clamp(10.0, 15.5).toDouble();
    final availableWidth = geometry.length * 0.68;
    final probeStyle = _hudStyle.copyWith(fontSize: fontSize, letterSpacing: 0);
    double widest = 0.0;
    for (final line in lines) {
      final probe = _text(line.text, probeStyle);
      widest = max(widest, probe.width);
      probe.dispose();
    }
    if (widest > availableWidth && widest > 0) {
      fontSize *= availableWidth / widest;
    }
    fontSize = max(8.0, fontSize);

    final centerDistance = geometry.length * 0.34;
    final centerAngle = geometry.centerAngle;
    final forward = cos(centerAngle) >= 0;
    final pathDirection = forward ? 1.0 : -1.0;
    final lineGap = fontSize * 0.48;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.4, fontSize * 0.14)
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.72);

    final fillStyle = _hudStyle.copyWith(
      color: Colors.white,
      fontSize: fontSize,
      letterSpacing: 0,
      shadows: const <Shadow>[Shadow(color: Color(0xAA000000), blurRadius: 2)],
    );
    final outlineStyle = _hudBaseStyle.copyWith(
      foreground: outlinePaint,
      fontSize: fontSize,
      letterSpacing: 0,
    );

    final allFillPainters = <TextPainter>[];
    final allOutlinePainters = <TextPainter>[];
    final glyphPositions = <Offset>[];
    final glyphRotations = <double>[];

    try {
      final double margin = fontSize * 0.45 + 4.0;
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final lineFillPainters = <TextPainter>[];
        final lineOutlinePainters = <TextPainter>[];
        double totalWidth = 0.0;
        for (final glyph in lines[lineIndex].text.split('')) {
          final fp = _text(glyph, fillStyle);
          final op = _text(glyph, outlineStyle);
          lineFillPainters.add(fp);
          lineOutlinePainters.add(op);
          allFillPainters.add(fp);
          allOutlinePainters.add(op);
          totalWidth += fp.width;
        }

        var cursor = -totalWidth / 2;
        final lateralOffset = lines.length == 1
            ? 0.0
            : lineIndex == 0
            ? -lineGap
            : lineGap;

        for (var i = 0; i < lineFillPainters.length; i++) {
          final painter = lineFillPainters[i];
          final glyphDistance =
              (centerDistance + pathDirection * (cursor + painter.width / 2))
                  .clamp(0.0, geometry.length)
                  .toDouble();
          final angle = geometry.angleAt(glyphDistance);
          var normal = Offset(-sin(angle), cos(angle));
          if (normal.dy < 0) normal = -normal;
          final position =
              geometry.pointAt(glyphDistance) + normal * lateralOffset;
          final rotation = angle + (forward ? 0.0 : pi);

          glyphPositions.add(position);
          glyphRotations.add(rotation);
          final halfExtent = hypotHalf(painter.width, painter.height) + margin;
          if (position.dx - halfExtent < minX) minX = position.dx - halfExtent;
          if (position.dy - halfExtent < minY) minY = position.dy - halfExtent;
          if (position.dx + halfExtent > maxX) maxX = position.dx + halfExtent;
          if (position.dy + halfExtent > maxY) maxY = position.dy + halfExtent;
          cursor += painter.width;
        }
      }

      if (allFillPainters.isEmpty) return null;

      final double logicalW = max(1.0, maxX - minX);
      final double logicalH = max(1.0, maxY - minY);
      final int pxW = max(1, (logicalW * _bitmapPixelRatio).ceil());
      final int pxH = max(1, (logicalH * _bitmapPixelRatio).ceil());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..scale(_bitmapPixelRatio, _bitmapPixelRatio)
        ..translate(-minX, -minY);

      for (var i = 0; i < allFillPainters.length; i++) {
        final fp = allFillPainters[i];
        final op = allOutlinePainters[i];
        final pos = glyphPositions[i];
        final offset = Offset(-fp.width / 2, -fp.height / 2);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(glyphRotations[i]);
        op.paint(canvas, offset);
        fp.paint(canvas, offset);
        canvas.restore();
      }

      final picture = recorder.endRecording();
      try {
        final image = picture.toImageSync(pxW, pxH);
        return _BakedTextBitmap(
          image: image,
          sourceRect: Rect.fromLTWH(0, 0, pxW.toDouble(), pxH.toDouble()),
          localBounds: Rect.fromLTWH(
            minX,
            minY,
            pxW / _bitmapPixelRatio,
            pxH / _bitmapPixelRatio,
          ),
        );
      } finally {
        picture.dispose();
      }
    } finally {
      for (final painter in allFillPainters) {
        painter.dispose();
      }
      for (final painter in allOutlinePainters) {
        painter.dispose();
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
