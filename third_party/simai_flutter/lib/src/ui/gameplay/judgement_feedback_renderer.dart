import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../gameplay/gameplay_models.dart';
import '../../structures/location.dart';
import '../../structures/note_group.dart';
import '../note_geometry.dart';
import '../rendering/precalc_data.dart';
import '../simai_game.dart';
import '../simai_mirror.dart';
import '../utils/note_utils.dart';
import 'judgement_display.dart';
import 'slide_feedback_geometry.dart';

/// 预烘焙判定反馈位图条目（含源像素矩形与相对锚点的逻辑矩形，销毁时释放 GPU 纹理）。
class _BakedFeedbackBitmap {
  const _BakedFeedbackBitmap({
    required this.image,
    required this.sourceRect,
    required this.localBounds,
  });

  final ui.Image image;
  final Rect sourceRect;
  final Rect localBounds;

  void dispose() => image.dispose();
}

/// 复用于谱面游玩、谱面播放与无头视频导出的高性能判定反馈渲染器。
///
/// 核心性能优化：
/// 1. 同位置去重（与机台一致：同一轨道/传感区新判定覆盖旧判定，砍掉高密段 60%–80% Overdraw）；
/// 2. 单/双行弧形判定文字合批烘焙为单张 `ui.Image`，运行时每条判定仅 1 次 `drawImageRect`；
/// 3. 滑星/扇形（WiFi）反馈将投影、渐变箭头底板与弯曲文字一次性合批烘焙为单张 `ui.Image`，
///    动画持续期间零 `ui.Gradient` 创建、零 Path 光栅化、零 `TextPainter` 分配。
class SimaiJudgementFeedbackRenderer {
  static const double _bitmapPixelRatio = 2.0;
  static const int _maxArcCompositeCacheEntries = 96;

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

  int _cachedQuantizedRadius = -1;
  int _cachedCenterX = 0;
  int _cachedCenterY = 0;
  SimaiMirrorMode? _cachedMirrorMode;
  PrecalcChartData? _cachedPrecalcData;

  final Map<String, _BakedFeedbackBitmap> _arcCompositeBitmaps =
      <String, _BakedFeedbackBitmap>{};
  final Map<String, SimaiSlideFeedbackGeometry?> _slideGeometryCache =
      <String, SimaiSlideFeedbackGeometry?>{};
  final Map<String, SimaiWifiFeedbackGeometry?> _wifiGeometryCache =
      <String, SimaiWifiFeedbackGeometry?>{};
  final Map<String, _BakedFeedbackBitmap> _slideCompositeBitmaps =
      <String, _BakedFeedbackBitmap>{};
  final Set<String> _activeSlideCompositeKeys = <String>{};

  // 复用每帧位置去重容器，消除热路径集合分配。
  final Map<int, SimaiJudgementRecord> _latestByLocation =
      <int, SimaiJudgementRecord>{};
  final List<SimaiJudgementRecord> _slideRecords = <SimaiJudgementRecord>[];

  final Paint _bitmapPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  /// 绘制当前活跃的判定记录列表。
  void paintRecords(
    Canvas canvas, {
    required SimaiGame game,
    required Iterable<SimaiJudgementRecord> records,
    required SimaiJudgementDisplayMode mode,
    bool skipAuto = true,
  }) {
    if (game.chartRadius <= 0 || !game.chartRadius.isFinite) return;
    _syncCachesForMetrics(game);
    _activeSlideCompositeKeys.clear();
    _latestByLocation.clear();
    _slideRecords.clear();

    // 同轨道/同传感区仅保留最新判定（与机台行为一致，避免纵连/连打叠绘糊白与 GPU 过绘）。
    for (final record in records) {
      if (skipAuto && record.isAuto) continue;
      if (record.slidePathIndex != null) {
        _slideRecords.add(record);
        continue;
      }
      final note =
          game.chart.noteCollections[record.collectionIndex][record.noteIndex];
      final loc = note.location;
      final locKey = (loc.group.index << 8) | loc.index;
      final prev = _latestByLocation[locKey];
      if (prev == null || record.judgedTime >= prev.judgedTime) {
        _latestByLocation[locKey] = record;
      }
    }

    for (final record in _latestByLocation.values) {
      _paintNonSlideRecord(canvas, game: game, record: record, mode: mode);
    }

    for (var i = 0; i < _slideRecords.length; i++) {
      _paintSlideRecord(
        canvas,
        game: game,
        record: _slideRecords[i],
        mode: mode,
      );
    }

    _pruneExpiredSlideBitmaps();
  }

  void _paintNonSlideRecord(
    Canvas canvas, {
    required SimaiGame game,
    required SimaiJudgementRecord record,
    required SimaiJudgementDisplayMode mode,
  }) {
    final presentation = SimaiJudgementPresentation.forRecord(record, mode);
    final note =
        game.chart.noteCollections[record.collectionIndex][record.noteIndex];
    final mirroredLocation = NoteUtils.mirrorLocation(
      note.location,
      game.mirrorMode,
    );
    final position = _feedbackPosition(game, mirroredLocation);
    final timingFirst = mirroredLocation.group == NoteGroup.tap
        ? _tapTimingFirst(mirroredLocation.index)
        : position.dy <= game.chartCenter.dy;
    final lines = presentation.lines(timingFirst: timingFirst);
    if (lines.isEmpty) return;
    final age = max(0.0, game.chartTime - record.judgedTime);
    final animation = simaiJudgementAnimationAt(age);
    if (!animation.visible) return;

    _paintArcComposite(
      canvas,
      game: game,
      lines: lines,
      position: position,
      animation: animation,
    );
  }

  void _paintSlideRecord(
    Canvas canvas, {
    required SimaiGame game,
    required SimaiJudgementRecord record,
    required SimaiJudgementDisplayMode mode,
  }) {
    final presentation = SimaiJudgementPresentation.forRecord(record, mode);
    final note =
        game.chart.noteCollections[record.collectionIndex][record.noteIndex];
    final slidePath = note.slidePaths[record.slidePathIndex!];
    final feedbackLocation = slidePath.segments.isEmpty
        ? note.location
        : slidePath.segments.last.vertices.last;
    final mirroredLocation = NoteUtils.mirrorLocation(
      feedbackLocation,
      game.mirrorMode,
    );
    final position = _feedbackPosition(game, mirroredLocation);
    final timingFirst = mirroredLocation.group == NoteGroup.tap
        ? _tapTimingFirst(mirroredLocation.index)
        : position.dy <= game.chartCenter.dy;
    final lines = presentation.lines(timingFirst: timingFirst);
    if (lines.isEmpty) return;
    final age = max(0.0, game.chartTime - record.judgedTime);
    final animation = simaiJudgementAnimationAt(age);
    if (!animation.visible) return;

    if (!_paintSlideFeedback(
      canvas,
      game: game,
      record: record,
      lines: lines,
      color: presentation.color,
      animation: animation,
    )) {
      _paintArcComposite(
        canvas,
        game: game,
        lines: lines,
        position: position,
        animation: animation,
      );
    }
  }

  /// 释放所有预烘焙 GPU 纹理与缓存（关闭开关或组件卸载时调用）。
  void dispose() {
    _disposeArcCompositeBitmaps();
    _disposeSlideCompositeBitmaps();
    _slideGeometryCache.clear();
    _wifiGeometryCache.clear();
    _latestByLocation.clear();
    _slideRecords.clear();
    _cachedQuantizedRadius = -1;
    _cachedPrecalcData = null;
  }

  void _syncCachesForMetrics(SimaiGame game) {
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
      _disposeArcCompositeBitmaps();
      _cachedQuantizedRadius = quantizedRadius;
    }
    if (geometryChanged) {
      _slideGeometryCache.clear();
      _wifiGeometryCache.clear();
      _disposeSlideCompositeBitmaps();
      _cachedCenterX = centerX;
      _cachedCenterY = centerY;
      _cachedMirrorMode = game.mirrorMode;
      _cachedPrecalcData = game.precalcData;
    }
  }

  void _disposeArcCompositeBitmaps() {
    for (final bitmap in _arcCompositeBitmaps.values) {
      bitmap.dispose();
    }
    _arcCompositeBitmaps.clear();
  }

  void _disposeSlideCompositeBitmaps() {
    for (final bitmap in _slideCompositeBitmaps.values) {
      bitmap.dispose();
    }
    _slideCompositeBitmaps.clear();
  }

  void _pruneExpiredSlideBitmaps() {
    if (_slideCompositeBitmaps.isEmpty) return;
    if (_activeSlideCompositeKeys.isEmpty) {
      _disposeSlideCompositeBitmaps();
      return;
    }
    if (_slideCompositeBitmaps.length == _activeSlideCompositeKeys.length) {
      return;
    }
    List<String>? expired;
    for (final key in _slideCompositeBitmaps.keys) {
      if (!_activeSlideCompositeKeys.contains(key)) {
        (expired ??= <String>[]).add(key);
      }
    }
    if (expired != null) {
      for (final key in expired) {
        _slideCompositeBitmaps.remove(key)?.dispose();
      }
    }
  }

  Offset _feedbackPosition(SimaiGame game, Location location) {
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

  /// 单次 drawImageRect 绘制 1–2 行合批弧形判定字样（消除逐行变换与重复提交）。
  void _paintArcComposite(
    Canvas canvas, {
    required SimaiGame game,
    required List<SimaiJudgementLine> lines,
    required Offset position,
    required SimaiJudgementAnimationState animation,
  }) {
    final int alpha = (animation.opacity * 255).round().clamp(0, 255);
    if (alpha <= 0 || lines.isEmpty) return;

    final center = game.chartCenter;
    final delta = position - center;
    final baseRadius = delta.distance;
    if (baseRadius <= 1e-9) return;
    final fontSize = (game.chartRadius * 0.052).clamp(12.0, 18.0).toDouble();
    final centerAngle = atan2(delta.dy, delta.dx);
    final clockwise = delta.dy <= 0;

    final bitmap = _obtainArcCompositeBitmap(
      lines: lines,
      fontSize: fontSize,
      baseRadius: baseRadius,
      clockwise: clockwise,
    );
    if (bitmap == null) return;

    final double targetRotation = clockwise
        ? centerAngle + pi / 2
        : centerAngle - pi / 2;

    _bitmapPaint.color = Color.fromARGB(alpha, 255, 255, 255);
    canvas.save();
    canvas.translate(position.dx, position.dy);
    if ((animation.scale - 1.0).abs() > 1e-4) {
      canvas.scale(animation.scale, animation.scale);
    }
    canvas.rotate(targetRotation);
    canvas.drawImageRect(
      bitmap.image,
      bitmap.sourceRect,
      bitmap.localBounds,
      _bitmapPaint,
    );
    canvas.restore();
  }

  _BakedFeedbackBitmap? _obtainArcCompositeBitmap({
    required List<SimaiJudgementLine> lines,
    required double fontSize,
    required double baseRadius,
    required bool clockwise,
  }) {
    final int quantizedFontSize = (fontSize * 2.0).round();
    final int radiusBucket = (baseRadius / 4.0).round();
    final double bakedFontSize = quantizedFontSize / 2.0;
    final double bakedRadius = max(bakedFontSize * 2.0, radiusBucket * 4.0);

    final String key = lines.length == 1
        ? '${lines[0].text}|${lines[0].color.toARGB32()}|$quantizedFontSize|$radiusBucket|${clockwise ? 1 : 0}'
        : '${lines[0].text}|${lines[0].color.toARGB32()}|${lines[1].text}|${lines[1].color.toARGB32()}|$quantizedFontSize|$radiusBucket|${clockwise ? 1 : 0}';

    final existing = _arcCompositeBitmaps[key];
    if (existing != null) return existing;

    final baked = _bakeArcCompositeBitmap(
      lines: lines,
      fontSize: bakedFontSize,
      baseRadius: bakedRadius,
      clockwise: clockwise,
    );
    if (baked == null) return null;

    if (_arcCompositeBitmaps.length >= _maxArcCompositeCacheEntries) {
      final oldestKey = _arcCompositeBitmaps.keys.first;
      _arcCompositeBitmaps.remove(oldestKey)?.dispose();
    }
    _arcCompositeBitmaps[key] = baked;
    return baked;
  }

  /// 将 1–2 行判定词按弧线布局一次性合批烘焙为单张带描边阴影的 ui.Image。
  _BakedFeedbackBitmap? _bakeArcCompositeBitmap({
    required List<SimaiJudgementLine> lines,
    required double fontSize,
    required double baseRadius,
    required bool clockwise,
  }) {
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.6, fontSize * 0.14)
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.82);

    final outlineStyle = _hudBaseStyle.copyWith(
      foreground: outlinePaint,
      fontSize: fontSize,
      letterSpacing: 0.25,
    );

    final allFillPainters = <TextPainter>[];
    final allOutlinePainters = <TextPainter>[];
    final allCenters = <Offset>[];
    final allRotations = <double>[];

    try {
      final bakeCenterAngle = clockwise ? -pi / 2 : pi / 2;
      final anchorOrigin = Offset(0.0, clockwise ? -baseRadius : baseRadius);
      final lineOffset = fontSize * 0.58;
      final double margin = fontSize * 0.45 + 6.0;
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;

      for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
        final line = lines[lineIdx];
        if (line.text.isEmpty) continue;
        final glyphs = line.text.split('');
        final fillStyle = _hudStyle.copyWith(
          color: line.color,
          fontSize: fontSize,
          letterSpacing: 0.25,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3.5)],
        );

        final lineFills = <TextPainter>[];
        for (final glyph in glyphs) {
          final fp = _text(glyph, fillStyle);
          final op = _text(glyph, outlineStyle);
          lineFills.add(fp);
          allFillPainters.add(fp);
          allOutlinePainters.add(op);
        }

        final double radiusOffset = lines.length == 1
            ? 0.0
            : lineIdx == 0
            ? (clockwise ? lineOffset : -lineOffset)
            : (clockwise ? -lineOffset : lineOffset);
        final double lineRadius = max(fontSize * 2.0, baseRadius + radiusOffset);

        final placements = simaiArcGlyphLayout(
          advances: lineFills.map((p) => p.width).toList(growable: false),
          centerAngle: bakeCenterAngle,
          radius: lineRadius,
          clockwise: clockwise,
        );

        for (var i = 0; i < lineFills.length; i++) {
          final painter = lineFills[i];
          final placement = placements[i];
          final relCenter =
              Offset(cos(placement.angle), sin(placement.angle)) * lineRadius -
              anchorOrigin;
          allCenters.add(relCenter);
          allRotations.add(placement.rotation);
          final double halfExtent =
              _hypotHalf(painter.width, painter.height) + margin;
          if (relCenter.dx - halfExtent < minX) minX = relCenter.dx - halfExtent;
          if (relCenter.dy - halfExtent < minY) minY = relCenter.dy - halfExtent;
          if (relCenter.dx + halfExtent > maxX) maxX = relCenter.dx + halfExtent;
          if (relCenter.dy + halfExtent > maxY) maxY = relCenter.dy + halfExtent;
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
        final fillPainter = allFillPainters[i];
        final outlinePainter = allOutlinePainters[i];
        final relCenter = allCenters[i];
        final offset = Offset(-fillPainter.width / 2, -fillPainter.height / 2);
        canvas.save();
        canvas.translate(relCenter.dx, relCenter.dy);
        canvas.rotate(allRotations[i]);
        outlinePainter.paint(canvas, offset);
        fillPainter.paint(canvas, offset);
        canvas.restore();
      }

      final picture = recorder.endRecording();
      try {
        final image = picture.toImageSync(pxW, pxH);
        return _BakedFeedbackBitmap(
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

  bool _paintSlideFeedback(
    Canvas canvas, {
    required SimaiGame game,
    required SimaiJudgementRecord record,
    required List<SimaiJudgementLine> lines,
    required Color color,
    required SimaiJudgementAnimationState animation,
  }) {
    final slidePathIndex = record.slidePathIndex;
    if (slidePathIndex == null) return false;
    final int alpha = (animation.opacity * 255).round().clamp(0, 255);
    if (alpha <= 0) return true;

    final key = '${record.collectionIndex}_${record.noteIndex}_$slidePathIndex';
    final data = game.precalcData.slides[key];
    if (data == null) return false;

    final bool isWifi =
        data.fanStarCenterX != null &&
        data.fanStarCenterY != null &&
        data.fanStarLeftX != null &&
        data.fanStarLeftY != null &&
        data.fanStarRightX != null &&
        data.fanStarRightY != null;

    final String textKey = lines.length == 1
        ? lines[0].text
        : '${lines[0].text}\n${lines[1].text}';
    final String cacheKey = '$key|${color.toARGB32()}|$textKey';
    _activeSlideCompositeKeys.add(cacheKey);

    Offset textAnchor;
    var bitmap = _slideCompositeBitmaps[cacheKey];

    if (isWifi) {
      final geometry = _obtainWifiGeometry(game, key, data);
      if (geometry == null) return false;
      textAnchor = geometry.textAnchor;
      if (bitmap == null) {
        bitmap = _bakeWifiCompositeBitmap(
          game: game,
          geometry: geometry,
          lines: lines,
          color: color,
        );
        if (bitmap == null) return false;
        _slideCompositeBitmaps[cacheKey] = bitmap;
      }
    } else {
      final geometry = _obtainSlideGeometry(game, key, data);
      if (geometry == null) return false;
      textAnchor = geometry.textAnchor;
      if (bitmap == null) {
        bitmap = _bakeSlideCompositeBitmap(
          game: game,
          geometry: geometry,
          lines: lines,
          color: color,
        );
        if (bitmap == null) return false;
        _slideCompositeBitmaps[cacheKey] = bitmap;
      }
    }

    _bitmapPaint.color = Color.fromARGB(alpha, 255, 255, 255);
    canvas.save();
    canvas.translate(textAnchor.dx, textAnchor.dy);
    if ((animation.scale - 1.0).abs() > 1e-4) {
      canvas.scale(animation.scale, animation.scale);
    }
    canvas.drawImageRect(
      bitmap.image,
      bitmap.sourceRect,
      bitmap.localBounds,
      _bitmapPaint,
    );
    canvas.restore();
    return true;
  }

  SimaiSlideFeedbackGeometry? _obtainSlideGeometry(
    SimaiGame game,
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
    SimaiGame game,
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

  /// 将常规滑星判定「投影 + 渐变箭头底板 + 弯曲文字」一次性合批烘焙为单张位图。
  _BakedFeedbackBitmap? _bakeSlideCompositeBitmap({
    required SimaiGame game,
    required SimaiSlideFeedbackGeometry geometry,
    required List<SimaiJudgementLine> lines,
    required Color color,
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
      final shadowPad = game.chartRadius * 0.024 + 4.0;
      final pathBounds = geometry.arrowPath.getBounds();
      double minX = pathBounds.left - shadowPad;
      double minY = pathBounds.top - shadowPad;
      double maxX = pathBounds.right + shadowPad;
      double maxY = pathBounds.bottom + shadowPad + game.chartRadius * 0.012;

      final double margin = fontSize * 0.45 + 4.0;
      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final lineFillPainters = <TextPainter>[];
        double totalWidth = 0.0;
        for (final glyph in lines[lineIndex].text.split('')) {
          final fp = _text(glyph, fillStyle);
          final op = _text(glyph, outlineStyle);
          lineFillPainters.add(fp);
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
          final halfExtent = _hypotHalf(painter.width, painter.height) + margin;
          if (position.dx - halfExtent < minX) minX = position.dx - halfExtent;
          if (position.dy - halfExtent < minY) minY = position.dy - halfExtent;
          if (position.dx + halfExtent > maxX) maxX = position.dx + halfExtent;
          if (position.dy + halfExtent > maxY) maxY = position.dy + halfExtent;
          cursor += painter.width;
        }
      }

      final double logicalW = max(1.0, maxX - minX);
      final double logicalH = max(1.0, maxY - minY);
      final int pxW = max(1, (logicalW * _bitmapPixelRatio).ceil());
      final int pxH = max(1, (logicalH * _bitmapPixelRatio).ceil());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..scale(_bitmapPixelRatio, _bitmapPixelRatio)
        ..translate(-minX, -minY);

      final fadeStart = geometry.fadeStart;
      final fadeEnd = geometry.fadeEnd;

      final shadowStrokePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = game.chartRadius * 0.018
        ..shader = ui.Gradient.linear(fadeStart, fadeEnd, const [
          Colors.transparent,
          Color(0x29000000),
        ]);
      final shadowFillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(fadeStart, fadeEnd, const [
          Colors.transparent,
          Color(0x47000000),
        ]);
      canvas.save();
      canvas.translate(0, game.chartRadius * 0.010);
      canvas.drawPath(geometry.arrowPath, shadowStrokePaint);
      canvas.drawPath(geometry.arrowPath, shadowFillPaint);
      canvas.restore();

      final fillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(fadeStart, fadeEnd, [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.96),
        ]);
      canvas.drawPath(geometry.arrowPath, fillPaint);

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
        final anchor = geometry.textAnchor;
        return _BakedFeedbackBitmap(
          image: image,
          sourceRect: Rect.fromLTWH(0, 0, pxW.toDouble(), pxH.toDouble()),
          localBounds: Rect.fromLTWH(
            minX - anchor.dx,
            minY - anchor.dy,
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

  /// 将扇形（WiFi）滑星判定「投影弧 + 渐变扇弧 + 弧形白字」一次性合批烘焙为单张位图。
  _BakedFeedbackBitmap? _bakeWifiCompositeBitmap({
    required SimaiGame game,
    required SimaiWifiFeedbackGeometry geometry,
    required List<SimaiJudgementLine> lines,
    required Color color,
  }) {
    final fontSize = (game.chartRadius * 0.045).clamp(10.0, 16.0).toDouble();
    final clockwise = geometry.clockwise;
    final lineOffset = fontSize * 0.52;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.4, fontSize * 0.14)
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.80);
    final fillStyle = _hudStyle.copyWith(
      color: Colors.white,
      fontSize: fontSize,
      letterSpacing: 0.25,
      shadows: const [Shadow(color: Colors.black, blurRadius: 3.0)],
    );
    final outlineStyle = _hudBaseStyle.copyWith(
      foreground: outlinePaint,
      fontSize: fontSize,
      letterSpacing: 0.25,
    );

    final allFillPainters = <TextPainter>[];
    final allOutlinePainters = <TextPainter>[];
    final glyphPositions = <Offset>[];
    final glyphRotations = <double>[];

    try {
      final shadowPad = game.chartRadius * 0.024 + 4.0;
      final arcBounds = geometry.arcPath.getBounds();
      double minX = arcBounds.left - shadowPad;
      double minY = arcBounds.top - shadowPad;
      double maxX = arcBounds.right + shadowPad;
      double maxY = arcBounds.bottom + shadowPad + game.chartRadius * 0.012;

      final double margin = fontSize * 0.45 + 4.0;
      for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
        final text = lines[lineIdx].text;
        if (text.isEmpty) continue;
        final lineFills = <TextPainter>[];
        for (final glyph in text.split('')) {
          final fp = _text(glyph, fillStyle);
          final op = _text(glyph, outlineStyle);
          lineFills.add(fp);
          allFillPainters.add(fp);
          allOutlinePainters.add(op);
        }
        final radiusOffset = lines.length == 1
            ? 0.0
            : lineIdx == 0
            ? (clockwise ? lineOffset : -lineOffset)
            : (clockwise ? -lineOffset : lineOffset);
        final lineRadius = max(fontSize * 2.0, geometry.radius + radiusOffset);
        final placements = simaiArcGlyphLayout(
          advances: lineFills.map((p) => p.width).toList(growable: false),
          centerAngle: geometry.centerAngle,
          radius: lineRadius,
          clockwise: clockwise,
        );
        for (var i = 0; i < lineFills.length; i++) {
          final fp = lineFills[i];
          final placement = placements[i];
          final pos =
              game.chartCenter +
              Offset(cos(placement.angle), sin(placement.angle)) * lineRadius;
          glyphPositions.add(pos);
          glyphRotations.add(placement.rotation);
          final halfExtent = _hypotHalf(fp.width, fp.height) + margin;
          if (pos.dx - halfExtent < minX) minX = pos.dx - halfExtent;
          if (pos.dy - halfExtent < minY) minY = pos.dy - halfExtent;
          if (pos.dx + halfExtent > maxX) maxX = pos.dx + halfExtent;
          if (pos.dy + halfExtent > maxY) maxY = pos.dy + halfExtent;
        }
      }

      final double logicalW = max(1.0, maxX - minX);
      final double logicalH = max(1.0, maxY - minY);
      final int pxW = max(1, (logicalW * _bitmapPixelRatio).ceil());
      final int pxH = max(1, (logicalH * _bitmapPixelRatio).ceil());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..scale(_bitmapPixelRatio, _bitmapPixelRatio)
        ..translate(-minX, -minY);

      final shadowStrokePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = game.chartRadius * 0.018
        ..shader = ui.Gradient.sweep(
          game.chartCenter,
          const [
            Colors.transparent,
            Color(0x29000000),
            Color(0x29000000),
            Colors.transparent,
          ],
          const [0.0, 0.18, 0.82, 1.0],
          TileMode.clamp,
          geometry.arcStart,
          geometry.arcEnd,
        );
      final shadowFillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.sweep(
          game.chartCenter,
          const [
            Colors.transparent,
            Color(0x47000000),
            Color(0x47000000),
            Colors.transparent,
          ],
          const [0.0, 0.18, 0.82, 1.0],
          TileMode.clamp,
          geometry.arcStart,
          geometry.arcEnd,
        );
      canvas.save();
      canvas.translate(0, game.chartRadius * 0.010);
      canvas.drawPath(geometry.arcPath, shadowStrokePaint);
      canvas.drawPath(geometry.arcPath, shadowFillPaint);
      canvas.restore();

      final fillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.sweep(
          game.chartCenter,
          [
            color.withValues(alpha: 0),
            color.withValues(alpha: 0.96),
            color.withValues(alpha: 0.96),
            color.withValues(alpha: 0),
          ],
          const [0.0, 0.18, 0.82, 1.0],
          TileMode.clamp,
          geometry.arcStart,
          geometry.arcEnd,
        );
      canvas.drawPath(geometry.arcPath, fillPaint);

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
        final anchor = geometry.textAnchor;
        return _BakedFeedbackBitmap(
          image: image,
          sourceRect: Rect.fromLTWH(0, 0, pxW.toDouble(), pxH.toDouble()),
          localBounds: Rect.fromLTWH(
            minX - anchor.dx,
            minY - anchor.dy,
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

  static double _hypotHalf(double width, double height) =>
      0.5 * sqrt(width * width + height * height);

  static bool _tapTimingFirst(int index) =>
      index == 6 || index == 7 || index == 0 || index == 1;

  static TextPainter _text(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
