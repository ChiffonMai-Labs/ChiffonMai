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
/// 判定颜色与多层描边配色表（参考舞萌 DX 机台 / AstroDX 贴纸字样层级）。
class _JudgementPalette {
  const _JudgementPalette({
    required this.gradientColors,
    required this.gradientStops,
    required this.outerStrokeColor,
    required this.innerStrokeColor,
    required this.glowColor,
    required this.bannerColors,
    required this.bannerEdgeColor,
  });

  final List<Color> gradientColors;
  final List<double> gradientStops;
  final Color outerStrokeColor;
  final Color innerStrokeColor;
  final Color glowColor;
  final List<Color> bannerColors;
  final Color bannerEdgeColor;
}

class SimaiJudgementFeedbackRenderer {
  static const double _bitmapPixelRatio = 2.0;
  static const int _maxArcCompositeCacheEntries = 160;
  static const double _glyphStretchX = 1.05;

  static const TextStyle _hudBaseStyle = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 17,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const Map<SimaiJudgementVisualKind, _JudgementPalette> _palettes =
      <SimaiJudgementVisualKind, _JudgementPalette>{
        SimaiJudgementVisualKind.breakCritical: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFFFBDF0),
            Color(0xFFFFF275),
            Color(0xFF8CF5FF),
            Color(0xFFFF9E1F),
          ],
          gradientStops: <double>[0.0, 0.25, 0.50, 0.75, 1.0],
          outerStrokeColor: Color(0xF5681200),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0xCCFF9E2C),
          bannerColors: <Color>[Color(0xFFFFDC52), Color(0xFFFF8818)],
          bannerEdgeColor: Color(0xEEFFF8D0),
        ),
        SimaiJudgementVisualKind.breakCriticalPerfect: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFFDF5),
            Color(0xFFFFE84D),
            Color(0xFFFF9A18),
            Color(0xFFFF4D1A),
          ],
          gradientStops: <double>[0.0, 0.30, 0.68, 1.0],
          outerStrokeColor: Color(0xF5681200),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0xCCFF9E2C),
          bannerColors: <Color>[Color(0xFFFFDC52), Color(0xFFFF8818)],
          bannerEdgeColor: Color(0xEEFFF8D0),
        ),
        SimaiJudgementVisualKind.breakMergedCriticalPerfect: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFFFE552),
            Color(0xFFFFB8EA),
            Color(0xFF8FF5FF),
            Color(0xFFFF7A14),
          ],
          gradientStops: <double>[0.0, 0.24, 0.50, 0.74, 1.0],
          outerStrokeColor: Color(0xF76E0E00),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0xD9FF9420),
          bannerColors: <Color>[Color(0xFFFFDC52), Color(0xFFFF8818)],
          bannerEdgeColor: Color(0xEEFFF8D0),
        ),
        SimaiJudgementVisualKind.critical: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFFFFF),
            Color(0xFFFFF6A8),
            Color(0xFFFFCF38),
          ],
          gradientStops: <double>[0.0, 0.45, 1.0],
          outerStrokeColor: Color(0xF24E1E00),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0x78FFD43B),
          bannerColors: <Color>[Color(0xFFFFD448), Color(0xFFFF9B10)],
          bannerEdgeColor: Color(0xEEFFF4C2),
        ),
        SimaiJudgementVisualKind.criticalPerfect: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFFDE0),
            Color(0xFFFFEA52),
            Color(0xFFFFB810),
            Color(0xFFFF8600),
          ],
          gradientStops: <double>[0.0, 0.32, 0.70, 1.0],
          outerStrokeColor: Color(0xF24E1E00),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0x78FFD43B),
          bannerColors: <Color>[Color(0xFFFFD448), Color(0xFFFF9B10)],
          bannerEdgeColor: Color(0xEEFFF4C2),
        ),
        SimaiJudgementVisualKind.perfect: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFF678),
            Color(0xFFFFC818),
            Color(0xFFFF8600),
          ],
          gradientStops: <double>[0.0, 0.52, 1.0],
          outerStrokeColor: Color(0xF24E1E00),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0x66FFBA18),
          bannerColors: <Color>[Color(0xFFFFCC32), Color(0xFFF58A00)],
          bannerEdgeColor: Color(0xEBFFF0B8),
        ),
        SimaiJudgementVisualKind.great: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFBEE0),
            Color(0xFFFF55A6),
            Color(0xFFD91674),
          ],
          gradientStops: <double>[0.0, 0.48, 1.0],
          outerStrokeColor: Color(0xF24A0626),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0x6BFFA8D4),
          bannerColors: <Color>[Color(0xFFFF66B2), Color(0xFFD91C78)],
          bannerEdgeColor: Color(0xEBFFE0F0),
        ),
        SimaiJudgementVisualKind.good: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFB8FF82),
            Color(0xFF40E05C),
            Color(0xFF149E34),
          ],
          gradientStops: <double>[0.0, 0.50, 1.0],
          outerStrokeColor: Color(0xF2063B14),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0x6680F09A),
          bannerColors: <Color>[Color(0xFF52E56B), Color(0xFF1CA63E)],
          bannerEdgeColor: Color(0xEBDCFFE4),
        ),
        SimaiJudgementVisualKind.miss: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFEDF2F8),
            Color(0xFF9EA8BA),
            Color(0xFF5D677A),
          ],
          gradientStops: <double>[0.0, 0.52, 1.0],
          outerStrokeColor: Color(0xEB1E242E),
          innerStrokeColor: Color(0xEBEEF2F7),
          glowColor: Color(0x4798A4B8),
          bannerColors: <Color>[Color(0xFF8C96A8), Color(0xFF566072)],
          bannerEdgeColor: Color(0xCCE6ECF5),
        ),
        SimaiJudgementVisualKind.fast: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFD0F8FF),
            Color(0xFF3CC6FF),
            Color(0xFF0078EE),
          ],
          gradientStops: <double>[0.0, 0.48, 1.0],
          outerStrokeColor: Color(0xF2052654),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0x7058D0FF),
          bannerColors: <Color>[Color(0xFF42C8FF), Color(0xFF0A84EB)],
          bannerEdgeColor: Color(0xEBD6F6FF),
        ),
        SimaiJudgementVisualKind.late: _JudgementPalette(
          gradientColors: <Color>[
            Color(0xFFFFC8D0),
            Color(0xFFFF5068),
            Color(0xFFD91836),
          ],
          gradientStops: <double>[0.0, 0.48, 1.0],
          outerStrokeColor: Color(0xF24E0614),
          innerStrokeColor: Color(0xFFFFFFFF),
          glowColor: Color(0x70FF687E),
          bannerColors: <Color>[Color(0xFFFF5A70), Color(0xFFD91E3C)],
          bannerEdgeColor: Color(0xEBFFDCE2),
        ),
      };

  static _JudgementPalette _paletteFor(SimaiJudgementVisualKind kind) =>
      _palettes[kind]!;

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
      kind: presentation.primaryKind,
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
      return center + direction / max(direction.distance, 1e-9) * radius * 0.79;
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
    final fontSize = (game.chartRadius * 0.064).clamp(13.0, 34.0).toDouble();
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
    final bool isBreakMergedPerfectArc = _hasBreakMergedCriticalVisual(lines);
    final bool isBreakCriticalArc = _hasBreakCriticalVisual(lines);
    final double effectiveScale = isBreakMergedPerfectArc
        ? animation.scale * 1.08
        : (isBreakCriticalArc ? animation.scale * 1.07 : animation.scale);

    _bitmapPaint.color = Color.fromARGB(alpha, 255, 255, 255);
    canvas.save();
    canvas.translate(position.dx, position.dy);
    if ((effectiveScale - 1.0).abs() > 1e-4) {
      canvas.scale(effectiveScale, effectiveScale);
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

  static bool _hasBreakCriticalVisual(List<SimaiJudgementLine> lines) {
    for (var i = 0; i < lines.length; i++) {
      final kind = lines[i].kind;
      if (kind == SimaiJudgementVisualKind.breakCritical ||
          kind == SimaiJudgementVisualKind.breakCriticalPerfect) {
        return true;
      }
    }
    return false;
  }

  static bool _hasBreakMergedCriticalVisual(List<SimaiJudgementLine> lines) {
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].kind == SimaiJudgementVisualKind.breakMergedCriticalPerfect) {
        return true;
      }
    }
    return false;
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
        ? '${lines[0].text}|${lines[0].kind.index}|${lines[0].isSubLine ? 1 : 0}|$quantizedFontSize|$radiusBucket|${clockwise ? 1 : 0}'
        : '${lines[0].text}|${lines[0].kind.index}|${lines[0].isSubLine ? 1 : 0}|${lines[1].text}|${lines[1].kind.index}|${lines[1].isSubLine ? 1 : 0}|$quantizedFontSize|$radiusBucket|${clockwise ? 1 : 0}';

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

  /// 将 1–2 行判定词按弧线布局一次性合批烘焙为单张带四层机台描边、渐变与投影的 ui.Image。
  _BakedFeedbackBitmap? _bakeArcCompositeBitmap({
    required List<SimaiJudgementLine> lines,
    required double fontSize,
    required double baseRadius,
    required bool clockwise,
  }) {
    final allPainters = <TextPainter>[];
    final glyphGlow = <TextPainter>[];
    final glyphOuter = <TextPainter>[];
    final glyphInner = <TextPainter>[];
    final glyphFill = <TextPainter>[];
    final glyphShadowOffsets = <double>[];
    final allCenters = <Offset>[];
    final allRotations = <double>[];

    try {
      final bool isBreakCriticalArc = _hasBreakCriticalVisual(lines);
      final bool isBreakMergedPerfectArc = _hasBreakMergedCriticalVisual(lines);
      final bool hasBreakSpecialArc =
          isBreakCriticalArc || isBreakMergedPerfectArc;
      final bakeCenterAngle = clockwise ? -pi / 2 : pi / 2;
      final anchorOrigin = Offset(0.0, clockwise ? -baseRadius : baseRadius);
      final lineFontSizes = <double>[
        for (final line in lines)
          line.isSubLine
              ? (fontSize * 0.68).clamp(9.0, 24.0).toDouble()
              : fontSize,
      ];
      final double halfSeparation = lines.length > 1
          ? (lineFontSizes[0] + lineFontSizes[1]) * 0.275
          : 0.0;
      final double margin =
          fontSize * (hasBreakSpecialArc ? 0.95 : 0.65) +
          (hasBreakSpecialArc ? 12.0 : 8.0);
      double minX = double.infinity;
      double minY = double.infinity;
      double maxX = double.negativeInfinity;
      double maxY = double.negativeInfinity;
      double maxGlyphAngleOffset = 0.0;

      for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
        final line = lines[lineIdx];
        if (line.text.isEmpty) continue;
        final double lineFontSize = lineFontSizes[lineIdx];
        final _JudgementPalette palette = _paletteFor(line.kind);
        final double letterSpacing = line.text == 'CRITICAL'
            ? 0.35
            : (line.isSubLine ? 0.15 : -0.25);

        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(3.4, lineFontSize * 0.36)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = palette.glowColor
          ..maskFilter = ui.MaskFilter.blur(
            ui.BlurStyle.normal,
            max(1.1, lineFontSize * 0.085),
          );
        final outerPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.6, lineFontSize * 0.28)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = palette.outerStrokeColor;
        final innerPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.35, lineFontSize * 0.14)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = palette.innerStrokeColor;

        final glowStyle = _hudBaseStyle.copyWith(
          foreground: glowPaint,
          fontSize: lineFontSize,
          letterSpacing: letterSpacing,
          shadows: <Shadow>[
            Shadow(
              color: const Color(0x88000000),
              offset: Offset(0, lineFontSize * 0.05),
              blurRadius: max(1.5, lineFontSize * 0.12),
            ),
          ],
        );
        final outerStyle = _hudBaseStyle.copyWith(
          foreground: outerPaint,
          fontSize: lineFontSize,
          letterSpacing: letterSpacing,
        );
        final innerStyle = _hudBaseStyle.copyWith(
          foreground: innerPaint,
          fontSize: lineFontSize,
          letterSpacing: letterSpacing,
        );
        final probeStyle = _hudBaseStyle.copyWith(
          color: Colors.white,
          fontSize: lineFontSize,
          letterSpacing: letterSpacing,
        );

        final lineProbes = <TextPainter>[];
        final glyphs = line.text.split('');
        for (final glyph in glyphs) {
          final probe = _text(glyph, probeStyle);
          lineProbes.add(probe);
          allPainters.add(probe);
        }

        final double sampleHeight = lineProbes.first.height;
        final fillPaint = Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.linear(
            Offset(0.0, sampleHeight * 0.10),
            Offset(0.0, sampleHeight * 0.90),
            palette.gradientColors,
            palette.gradientStops,
          );
        final fillStyle = _hudBaseStyle.copyWith(
          foreground: fillPaint,
          fontSize: lineFontSize,
          letterSpacing: letterSpacing,
        );

        final double radiusOffset = lines.length == 1
            ? 0.0
            : lineIdx == 0
            ? (clockwise ? halfSeparation : -halfSeparation)
            : (clockwise ? -halfSeparation : halfSeparation);
        final double lineRadius = max(
          lineFontSize * 2.0,
          baseRadius + radiusOffset,
        );

        final placements = simaiArcGlyphLayout(
          advances: lineProbes
              .map((p) => p.width * _glyphStretchX)
              .toList(growable: false),
          centerAngle: bakeCenterAngle,
          radius: lineRadius,
          clockwise: clockwise,
        );

        for (var i = 0; i < lineProbes.length; i++) {
          final glyph = glyphs[i];
          final probe = lineProbes[i];
          final placement = placements[i];
          final double angleDiff = (placement.angle - bakeCenterAngle).abs();
          if (angleDiff > maxGlyphAngleOffset) {
            maxGlyphAngleOffset = angleDiff;
          }
          final relCenter =
              Offset(cos(placement.angle), sin(placement.angle)) * lineRadius -
              anchorOrigin;
          final gp = _text(glyph, glowStyle);
          final op = _text(glyph, outerStyle);
          final ip = _text(glyph, innerStyle);
          final fp = _text(glyph, fillStyle);
          allPainters
            ..add(gp)
            ..add(op)
            ..add(ip)
            ..add(fp);
          glyphGlow.add(gp);
          glyphOuter.add(op);
          glyphInner.add(ip);
          glyphFill.add(fp);
          glyphShadowOffsets.add(lineFontSize * 0.055);
          allCenters.add(relCenter);
          allRotations.add(placement.rotation);

          final double halfExtent =
              _hypotHalf(probe.width * _glyphStretchX, probe.height) + margin;
          if (relCenter.dx - halfExtent < minX) minX = relCenter.dx - halfExtent;
          if (relCenter.dy - halfExtent < minY) minY = relCenter.dy - halfExtent;
          if (relCenter.dx + halfExtent > maxX) maxX = relCenter.dx + halfExtent;
          if (relCenter.dy + halfExtent > maxY) maxY = relCenter.dy + halfExtent;
        }
      }

      if (glyphFill.isEmpty) return null;

      void expandBoundsFor(Offset point, double pad) {
        if (point.dx - pad < minX) minX = point.dx - pad;
        if (point.dy - pad < minY) minY = point.dy - pad;
        if (point.dx + pad > maxX) maxX = point.dx + pad;
        if (point.dy + pad > maxY) maxY = point.dy + pad;
      }

      final double ornamentRadius = max(fontSize * 2.0, baseRadius);
      final double starPadAngle = (fontSize * 0.78) / ornamentRadius;
      final double endStarAngleOffset = maxGlyphAngleOffset + starPadAngle;
      final double arcFlareHalfAngle = endStarAngleOffset +
          (fontSize * 0.55) / ornamentRadius;
      final double outerCrestRadius = ornamentRadius +
          (lines.length > 1 ? halfSeparation + fontSize * 0.74 : fontSize * 0.78);
      final double apexStarRadius = fontSize * 0.42;
      final double sideStarRadius = fontSize * 0.46;
      final double sideMiniRadius = fontSize * 0.28;
      final Offset apexStarCenter =
          Offset(cos(bakeCenterAngle), sin(bakeCenterAngle)) * outerCrestRadius -
          anchorOrigin;
      final double leftEndAngle = bakeCenterAngle - endStarAngleOffset;
      final double rightEndAngle = bakeCenterAngle + endStarAngleOffset;
      final Offset leftStarCenter =
          Offset(cos(leftEndAngle), sin(leftEndAngle)) * ornamentRadius -
          anchorOrigin;
      final Offset rightStarCenter =
          Offset(cos(rightEndAngle), sin(rightEndAngle)) * ornamentRadius -
          anchorOrigin;
      final Offset leftMiniCenter =
          Offset(
                cos(leftEndAngle - (fontSize * 0.34) / ornamentRadius),
                sin(leftEndAngle - (fontSize * 0.34) / ornamentRadius),
              ) *
              (ornamentRadius + fontSize * 0.36) -
          anchorOrigin;
      final Offset rightMiniCenter =
          Offset(
                cos(rightEndAngle + (fontSize * 0.34) / ornamentRadius),
                sin(rightEndAngle + (fontSize * 0.34) / ornamentRadius),
              ) *
              (ornamentRadius + fontSize * 0.36) -
          anchorOrigin;
      final double apexFlankAngle = (fontSize * 0.56) / ornamentRadius;
      final double apexFlankRadius = outerCrestRadius - fontSize * 0.06;
      final Offset apexLeftCenter =
          Offset(
                cos(bakeCenterAngle - apexFlankAngle),
                sin(bakeCenterAngle - apexFlankAngle),
              ) *
              apexFlankRadius -
          anchorOrigin;
      final Offset apexRightCenter =
          Offset(
                cos(bakeCenterAngle + apexFlankAngle),
                sin(bakeCenterAngle + apexFlankAngle),
              ) *
              apexFlankRadius -
          anchorOrigin;

      if (hasBreakSpecialArc) {
        final double pad = fontSize * 0.75 + 8.0;
        expandBoundsFor(apexStarCenter, pad);
        expandBoundsFor(leftStarCenter, pad);
        expandBoundsFor(rightStarCenter, pad);
        expandBoundsFor(leftMiniCenter, pad);
        expandBoundsFor(rightMiniCenter, pad);
        if (isBreakMergedPerfectArc) {
          expandBoundsFor(apexLeftCenter, pad);
          expandBoundsFor(apexRightCenter, pad);
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

      if (isBreakMergedPerfectArc) {
        _paintBreakMergedPerfectArcOrnament(
          canvas,
          arcOrigin: -anchorOrigin,
          arcRadius: ornamentRadius,
          fontSize: fontSize,
          centerAngle: bakeCenterAngle,
          halfAngle: arcFlareHalfAngle,
          bandThickness: lines.length > 1
              ? (halfSeparation * 2.0 + fontSize * 0.96)
              : fontSize * 1.24,
          apexStarCenter: apexStarCenter,
          apexStarRadius: apexStarRadius * 1.08,
          apexLeftCenter: apexLeftCenter,
          apexRightCenter: apexRightCenter,
          apexFlankRadius: fontSize * 0.25,
          leftStarCenter: leftStarCenter,
          rightStarCenter: rightStarCenter,
          sideStarRadius: sideStarRadius * 1.06,
          leftMiniCenter: leftMiniCenter,
          rightMiniCenter: rightMiniCenter,
          sideMiniRadius: sideMiniRadius * 1.08,
          leftRotation: leftEndAngle + pi / 2,
          rightRotation: rightEndAngle + pi / 2,
          apexRotation: bakeCenterAngle + pi / 2,
        );
      } else if (isBreakCriticalArc) {
        _paintBreakCriticalArcOrnament(
          canvas,
          arcOrigin: -anchorOrigin,
          arcRadius: ornamentRadius,
          centerAngle: bakeCenterAngle,
          halfAngle: arcFlareHalfAngle,
          bandThickness: lines.length > 1
              ? (halfSeparation * 2.0 + fontSize * 0.92)
              : fontSize * 1.18,
          apexStarCenter: apexStarCenter,
          apexStarRadius: apexStarRadius,
          leftStarCenter: leftStarCenter,
          rightStarCenter: rightStarCenter,
          sideStarRadius: sideStarRadius,
          leftMiniCenter: leftMiniCenter,
          rightMiniCenter: rightMiniCenter,
          sideMiniRadius: sideMiniRadius,
          leftRotation: leftEndAngle + pi / 2,
          rightRotation: rightEndAngle + pi / 2,
          apexRotation: bakeCenterAngle + pi / 2,
        );
      }

      for (var i = 0; i < glyphFill.length; i++) {
        final fillPainter = glyphFill[i];
        final relCenter = allCenters[i];
        final shadowDy = glyphShadowOffsets[i];
        canvas.save();
        canvas.translate(relCenter.dx, relCenter.dy);
        canvas.rotate(allRotations[i]);
        canvas.scale(_glyphStretchX, 1.0);
        canvas.translate(-fillPainter.width / 2, -fillPainter.height / 2);
        glyphGlow[i].paint(canvas, Offset(0.0, shadowDy));
        glyphOuter[i].paint(canvas, Offset.zero);
        glyphInner[i].paint(canvas, Offset.zero);
        fillPainter.paint(canvas, Offset.zero);
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
      for (final painter in allPainters) {
        painter.dispose();
      }
    }
  }

  bool _paintSlideFeedback(
    Canvas canvas, {
    required SimaiGame game,
    required SimaiJudgementRecord record,
    required List<SimaiJudgementLine> lines,
    required SimaiJudgementVisualKind kind,
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
    final String cacheKey = '$key|${kind.index}|${color.toARGB32()}|$textKey';
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
          kind: kind,
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
          kind: kind,
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

  /// 将常规滑星判定「投影 + 渐变高亮边框箭头底板 + 立体描边文字」一次性合批烘焙为单张位图。
  _BakedFeedbackBitmap? _bakeSlideCompositeBitmap({
    required SimaiGame game,
    required SimaiSlideFeedbackGeometry geometry,
    required List<SimaiJudgementLine> lines,
    required SimaiJudgementVisualKind kind,
  }) {
    final _JudgementPalette bannerPalette = _paletteFor(kind);
    var fontSize = (game.chartRadius * 0.048).clamp(10.5, 26.0).toDouble();
    final availableWidth = geometry.length * 0.68;
    final probeStyle = _hudBaseStyle.copyWith(
      color: Colors.white,
      fontSize: fontSize,
      letterSpacing: 0,
    );
    double widest = 0.0;
    for (final line in lines) {
      final probe = _text(line.text, probeStyle);
      widest = max(widest, probe.width * _glyphStretchX);
      probe.dispose();
    }
    if (widest > availableWidth && widest > 0) {
      fontSize *= availableWidth / widest;
    }
    fontSize = max(8.5, fontSize);

    final centerDistance = geometry.length * 0.34;
    final centerAngle = geometry.centerAngle;
    final forward = cos(centerAngle) >= 0;
    final pathDirection = forward ? 1.0 : -1.0;
    final lineFontSizes = <double>[
      for (final line in lines)
        line.isSubLine
            ? (fontSize * 0.78).clamp(7.5, 20.0).toDouble()
            : fontSize,
    ];
    final double halfSeparation = lines.length > 1
        ? (lineFontSizes[0] + lineFontSizes[1]) * 0.28
        : 0.0;

    final allPainters = <TextPainter>[];
    final allOutlinePainters = <TextPainter>[];
    final allFillPainters = <TextPainter>[];
    final glyphPositions = <Offset>[];
    final glyphRotations = <double>[];

    try {
      final shadowPad = game.chartRadius * 0.028 + 5.0;
      final pathBounds = geometry.arrowPath.getBounds();
      double minX = pathBounds.left - shadowPad;
      double minY = pathBounds.top - shadowPad;
      double maxX = pathBounds.right + shadowPad;
      double maxY = pathBounds.bottom + shadowPad + game.chartRadius * 0.014;

      final double margin = fontSize * 0.55 + 6.0;
      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final line = lines[lineIndex];
        final double lineFontSize = lineFontSizes[lineIndex];
        final _JudgementPalette linePalette = _paletteFor(line.kind);
        final outlinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.2, lineFontSize * 0.24)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = linePalette.outerStrokeColor;
        final outlineStyle = _hudBaseStyle.copyWith(
          foreground: outlinePaint,
          fontSize: lineFontSize,
          letterSpacing: 0,
        );
        final probeLineStyle = _hudBaseStyle.copyWith(
          color: Colors.white,
          fontSize: lineFontSize,
          letterSpacing: 0,
        );

        final lineProbes = <TextPainter>[];
        double totalWidth = 0.0;
        final glyphs = line.text.split('');
        for (final glyph in glyphs) {
          final probe = _text(glyph, probeLineStyle);
          lineProbes.add(probe);
          allPainters.add(probe);
          totalWidth += probe.width * _glyphStretchX;
        }
        if (lineProbes.isEmpty) continue;

        final double sampleHeight = lineProbes.first.height;
        final fillPaint = Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.linear(
            Offset(0.0, sampleHeight * 0.12),
            Offset(0.0, sampleHeight * 0.88),
            <Color>[Colors.white, linePalette.gradientColors.first],
          );
        final fillStyle = _hudBaseStyle.copyWith(
          foreground: fillPaint,
          fontSize: lineFontSize,
          letterSpacing: 0,
        );

        var cursor = -totalWidth / 2;
        final double lateralOffset = lines.length == 1
            ? 0.0
            : lineIndex == 0
            ? -halfSeparation
            : halfSeparation;

        for (var i = 0; i < lineProbes.length; i++) {
          final probe = lineProbes[i];
          final glyphAdvance = probe.width * _glyphStretchX;
          final glyphDistance =
              (centerDistance + pathDirection * (cursor + glyphAdvance / 2))
                  .clamp(0.0, geometry.length)
                  .toDouble();
          final angle = geometry.angleAt(glyphDistance);
          var normal = Offset(-sin(angle), cos(angle));
          if (normal.dy < 0) normal = -normal;
          final position =
              geometry.pointAt(glyphDistance) + normal * lateralOffset;
          final rotation = angle + (forward ? 0.0 : pi);

          final fp = _text(glyphs[i], fillStyle);
          final op = _text(glyphs[i], outlineStyle);
          allPainters
            ..add(fp)
            ..add(op);
          allFillPainters.add(fp);
          allOutlinePainters.add(op);

          glyphPositions.add(position);
          glyphRotations.add(rotation);
          final halfExtent =
              _hypotHalf(glyphAdvance, probe.height) + margin;
          if (position.dx - halfExtent < minX) minX = position.dx - halfExtent;
          if (position.dy - halfExtent < minY) minY = position.dy - halfExtent;
          if (position.dx + halfExtent > maxX) maxX = position.dx + halfExtent;
          if (position.dy + halfExtent > maxY) maxY = position.dy + halfExtent;
          cursor += glyphAdvance;
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
        ..strokeWidth = game.chartRadius * 0.020
        ..shader = ui.Gradient.linear(fadeStart, fadeEnd, const [
          Colors.transparent,
          Color(0x36000000),
        ]);
      final shadowFillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(fadeStart, fadeEnd, const [
          Colors.transparent,
          Color(0x52000000),
        ]);
      canvas.save();
      canvas.translate(0, game.chartRadius * 0.011);
      canvas.drawPath(geometry.arrowPath, shadowStrokePaint);
      canvas.drawPath(geometry.arrowPath, shadowFillPaint);
      canvas.restore();

      final Color bannerTop = bannerPalette.bannerColors[0];
      final Color bannerBottom = bannerPalette.bannerColors[1];
      final fillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          fadeStart,
          fadeEnd,
          [
            bannerTop.withValues(alpha: 0),
            bannerTop.withValues(alpha: 0.94),
            bannerBottom.withValues(alpha: 0.96),
          ],
          const [0.0, 0.55, 1.0],
        );
      canvas.drawPath(geometry.arrowPath, fillPaint);

      final edgePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = max(1.4, game.chartRadius * 0.0085)
        ..shader = ui.Gradient.linear(fadeStart, fadeEnd, [
          Colors.transparent,
          bannerPalette.bannerEdgeColor,
        ]);
      canvas.drawPath(geometry.arrowPath, edgePaint);

      for (var i = 0; i < allFillPainters.length; i++) {
        final fp = allFillPainters[i];
        final op = allOutlinePainters[i];
        final pos = glyphPositions[i];
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(glyphRotations[i]);
        canvas.scale(_glyphStretchX, 1.0);
        canvas.translate(-fp.width / 2, -fp.height / 2);
        op.paint(canvas, Offset.zero);
        fp.paint(canvas, Offset.zero);
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
      for (final painter in allPainters) {
        painter.dispose();
      }
    }
  }

  /// 将扇形（WiFi）滑星判定「投影弧 + 渐变亮边扇弧 + 立体弧形文字」一次性合批烘焙为单张位图。
  _BakedFeedbackBitmap? _bakeWifiCompositeBitmap({
    required SimaiGame game,
    required SimaiWifiFeedbackGeometry geometry,
    required List<SimaiJudgementLine> lines,
    required SimaiJudgementVisualKind kind,
  }) {
    final _JudgementPalette bannerPalette = _paletteFor(kind);
    final fontSize = (game.chartRadius * 0.050).clamp(10.5, 27.0).toDouble();
    final clockwise = geometry.clockwise;
    final lineFontSizes = <double>[
      for (final line in lines)
        line.isSubLine
            ? (fontSize * 0.78).clamp(8.0, 21.0).toDouble()
            : fontSize,
    ];
    final double halfSeparation = lines.length > 1
        ? (lineFontSizes[0] + lineFontSizes[1]) * 0.285
        : 0.0;

    final allPainters = <TextPainter>[];
    final allOutlinePainters = <TextPainter>[];
    final allFillPainters = <TextPainter>[];
    final glyphPositions = <Offset>[];
    final glyphRotations = <double>[];

    try {
      final shadowPad = game.chartRadius * 0.028 + 5.0;
      final arcBounds = geometry.arcPath.getBounds();
      double minX = arcBounds.left - shadowPad;
      double minY = arcBounds.top - shadowPad;
      double maxX = arcBounds.right + shadowPad;
      double maxY = arcBounds.bottom + shadowPad + game.chartRadius * 0.014;

      final double margin = fontSize * 0.55 + 6.0;
      for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
        final line = lines[lineIdx];
        final text = line.text;
        if (text.isEmpty) continue;
        final double lineFontSize = lineFontSizes[lineIdx];
        final _JudgementPalette linePalette = _paletteFor(line.kind);
        final outlinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(2.2, lineFontSize * 0.24)
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = linePalette.outerStrokeColor;
        final outlineStyle = _hudBaseStyle.copyWith(
          foreground: outlinePaint,
          fontSize: lineFontSize,
          letterSpacing: 0.20,
        );
        final probeStyle = _hudBaseStyle.copyWith(
          color: Colors.white,
          fontSize: lineFontSize,
          letterSpacing: 0.20,
        );

        final lineProbes = <TextPainter>[];
        final glyphs = text.split('');
        for (final glyph in glyphs) {
          final probe = _text(glyph, probeStyle);
          lineProbes.add(probe);
          allPainters.add(probe);
        }
        if (lineProbes.isEmpty) continue;

        final double sampleHeight = lineProbes.first.height;
        final fillPaint = Paint()
          ..isAntiAlias = true
          ..shader = ui.Gradient.linear(
            Offset(0.0, sampleHeight * 0.12),
            Offset(0.0, sampleHeight * 0.88),
            <Color>[Colors.white, linePalette.gradientColors.first],
          );
        final fillStyle = _hudBaseStyle.copyWith(
          foreground: fillPaint,
          fontSize: lineFontSize,
          letterSpacing: 0.20,
        );

        final double radiusOffset = lines.length == 1
            ? 0.0
            : lineIdx == 0
            ? (clockwise ? halfSeparation : -halfSeparation)
            : (clockwise ? -halfSeparation : halfSeparation);
        final lineRadius = max(
          lineFontSize * 2.0,
          geometry.radius + radiusOffset,
        );
        final placements = simaiArcGlyphLayout(
          advances: lineProbes
              .map((p) => p.width * _glyphStretchX)
              .toList(growable: false),
          centerAngle: geometry.centerAngle,
          radius: lineRadius,
          clockwise: clockwise,
        );
        for (var i = 0; i < lineProbes.length; i++) {
          final probe = lineProbes[i];
          final placement = placements[i];
          final pos =
              game.chartCenter +
              Offset(cos(placement.angle), sin(placement.angle)) * lineRadius;
          final fp = _text(glyphs[i], fillStyle);
          final op = _text(glyphs[i], outlineStyle);
          allPainters
            ..add(fp)
            ..add(op);
          allFillPainters.add(fp);
          allOutlinePainters.add(op);
          glyphPositions.add(pos);
          glyphRotations.add(placement.rotation);
          final halfExtent =
              _hypotHalf(probe.width * _glyphStretchX, probe.height) + margin;
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
        ..strokeWidth = game.chartRadius * 0.020
        ..shader = ui.Gradient.sweep(
          game.chartCenter,
          const [
            Colors.transparent,
            Color(0x36000000),
            Color(0x36000000),
            Colors.transparent,
          ],
          const [0.0, 0.16, 0.84, 1.0],
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
            Color(0x52000000),
            Color(0x52000000),
            Colors.transparent,
          ],
          const [0.0, 0.16, 0.84, 1.0],
          TileMode.clamp,
          geometry.arcStart,
          geometry.arcEnd,
        );
      canvas.save();
      canvas.translate(0, game.chartRadius * 0.011);
      canvas.drawPath(geometry.arcPath, shadowStrokePaint);
      canvas.drawPath(geometry.arcPath, shadowFillPaint);
      canvas.restore();

      final Color bannerTop = bannerPalette.bannerColors[0];
      final Color bannerBottom = bannerPalette.bannerColors[1];
      final fillPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.sweep(
          game.chartCenter,
          [
            bannerTop.withValues(alpha: 0),
            bannerTop.withValues(alpha: 0.95),
            bannerBottom.withValues(alpha: 0.95),
            bannerBottom.withValues(alpha: 0),
          ],
          const [0.0, 0.16, 0.84, 1.0],
          TileMode.clamp,
          geometry.arcStart,
          geometry.arcEnd,
        );
      canvas.drawPath(geometry.arcPath, fillPaint);

      final edgePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = max(1.4, game.chartRadius * 0.0085)
        ..shader = ui.Gradient.sweep(
          game.chartCenter,
          [
            Colors.transparent,
            bannerPalette.bannerEdgeColor,
            bannerPalette.bannerEdgeColor,
            Colors.transparent,
          ],
          const [0.0, 0.16, 0.84, 1.0],
          TileMode.clamp,
          geometry.arcStart,
          geometry.arcEnd,
        );
      canvas.drawPath(geometry.arcPath, edgePaint);

      for (var i = 0; i < allFillPainters.length; i++) {
        final fp = allFillPainters[i];
        final op = allOutlinePainters[i];
        final pos = glyphPositions[i];
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(glyphRotations[i]);
        canvas.scale(_glyphStretchX, 1.0);
        canvas.translate(-fp.width / 2, -fp.height / 2);
        op.paint(canvas, Offset.zero);
        fp.paint(canvas, Offset.zero);
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
      for (final painter in allPainters) {
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

  /// 为非滑条绝赞（Tap / Hold / Slide 星头）的 CRITICAL PERFECT 烘焙专属炽金光带与星芒徽章，
  /// 使 2600 绝赞与普通 CRITICAL PERFECT 在高速谱面中一眼可辨（Break Slide 维持原有箭头横幅）。
  static void _paintBreakCriticalArcOrnament(
    Canvas canvas, {
    required Offset arcOrigin,
    required double arcRadius,
    required double centerAngle,
    required double halfAngle,
    required double bandThickness,
    required Offset apexStarCenter,
    required double apexStarRadius,
    required Offset leftStarCenter,
    required Offset rightStarCenter,
    required double sideStarRadius,
    required Offset leftMiniCenter,
    required Offset rightMiniCenter,
    required double sideMiniRadius,
    required double leftRotation,
    required double rightRotation,
    required double apexRotation,
  }) {
    final double sweepStart = centerAngle - halfAngle;
    final double sweepAngle = halfAngle * 2.0;
    final double gradCenter = centerAngle < 0 ? centerAngle + 2 * pi : centerAngle;
    final double gradStart = gradCenter - halfAngle;
    final double gradEnd = gradCenter + halfAngle;
    final Rect arcRect = Rect.fromCircle(center: arcOrigin, radius: arcRadius);

    // 1. 弧形炽金-赤橙双层背光焰带（两端自然羽化消隐）
    final outerAuraPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandThickness
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        max(2.2, bandThickness * 0.20),
      )
      ..shader = ui.Gradient.sweep(
        arcOrigin,
        const <Color>[
          Color(0x00FF6A00),
          Color(0x66FF5E1A),
          Color(0x9EFFAE24),
          Color(0x66FF5E1A),
          Color(0x00FF6A00),
        ],
        const <double>[0.0, 0.22, 0.50, 0.78, 1.0],
        TileMode.clamp,
        gradStart,
        gradEnd,
      );
    canvas.drawArc(arcRect, sweepStart, sweepAngle, false, outerAuraPaint);

    final coreRibbonPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(2.2, bandThickness * 0.26)
      ..shader = ui.Gradient.sweep(
        arcOrigin,
        const <Color>[
          Color(0x00FFE466),
          Color(0x88FFE978),
          Color(0xCCFFFFFF),
          Color(0x88FFE978),
          Color(0x00FFE466),
        ],
        const <double>[0.0, 0.26, 0.50, 0.74, 1.0],
        TileMode.clamp,
        gradStart,
        gradEnd,
      );
    canvas.drawArc(arcRect, sweepStart, sweepAngle, false, coreRibbonPaint);

    // 2. 顶部皇冠四角星芒 + 左右侧翼冷暖棱镜星屑
    _paintFourPointStar(
      canvas,
      center: apexStarCenter,
      radius: apexStarRadius,
      rotation: apexRotation,
      glowColor: const Color(0xCCFF8C1A),
      coreColor: const Color(0xFFFFFCE0),
    );
    _paintFourPointStar(
      canvas,
      center: leftStarCenter,
      radius: sideStarRadius,
      rotation: leftRotation,
      glowColor: const Color(0xCCFF7A18),
      coreColor: const Color(0xFFFFFFFF),
    );
    _paintFourPointStar(
      canvas,
      center: rightStarCenter,
      radius: sideStarRadius,
      rotation: rightRotation,
      glowColor: const Color(0xCCFF7A18),
      coreColor: const Color(0xFFFFFFFF),
    );
    _paintFourPointStar(
      canvas,
      center: leftMiniCenter,
      radius: sideMiniRadius,
      rotation: leftRotation + pi / 4,
      glowColor: const Color(0xB85CE8FF),
      coreColor: const Color(0xFFF0FCFF),
    );
    _paintFourPointStar(
      canvas,
      center: rightMiniCenter,
      radius: sideMiniRadius,
      rotation: rightRotation + pi / 4,
      glowColor: const Color(0xB8FF7FD8),
      coreColor: const Color(0xFFFFF0FA),
    );
  }

  /// 为「所有 Perfect 合并显示」(1-A~1-E) 下仍仅显示 `PERFECT` 的非滑条绝赞 CRITICAL PERFECT
  /// 烘焙专属双轨虹光边丝与三连皇冠星芒，使其与普通 2550/2500 PERFECT 一目了然区别开来。
  static void _paintBreakMergedPerfectArcOrnament(
    Canvas canvas, {
    required Offset arcOrigin,
    required double arcRadius,
    required double fontSize,
    required double centerAngle,
    required double halfAngle,
    required double bandThickness,
    required Offset apexStarCenter,
    required double apexStarRadius,
    required Offset apexLeftCenter,
    required Offset apexRightCenter,
    required double apexFlankRadius,
    required Offset leftStarCenter,
    required Offset rightStarCenter,
    required double sideStarRadius,
    required Offset leftMiniCenter,
    required Offset rightMiniCenter,
    required double sideMiniRadius,
    required double leftRotation,
    required double rightRotation,
    required double apexRotation,
  }) {
    final double sweepStart = centerAngle - halfAngle;
    final double sweepAngle = halfAngle * 2.0;
    final double gradCenter = centerAngle < 0 ? centerAngle + 2 * pi : centerAngle;
    final double gradStart = gradCenter - halfAngle;
    final double gradEnd = gradCenter + halfAngle;
    final Rect arcRect = Rect.fromCircle(center: arcOrigin, radius: arcRadius);

    // 1. 炽金-赤橙背光焰带 + 内核白金高光线
    final outerAuraPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = bandThickness
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        max(2.4, bandThickness * 0.22),
      )
      ..shader = ui.Gradient.sweep(
        arcOrigin,
        const <Color>[
          Color(0x00FF5A00),
          Color(0x78FF5518),
          Color(0xBAFFB82E),
          Color(0x78FF5518),
          Color(0x00FF5A00),
        ],
        const <double>[0.0, 0.20, 0.50, 0.80, 1.0],
        TileMode.clamp,
        gradStart,
        gradEnd,
      );
    canvas.drawArc(arcRect, sweepStart, sweepAngle, false, outerAuraPaint);

    // 2. 上下双轨弧形耀金丝线框（单行 PERFECT 专属视觉框定，与普通 PERFECT 拉开层级）
    final double rimHalfOffset = fontSize * 0.56;
    final double rimSweep = halfAngle * 0.90;
    final double rimStart = centerAngle - rimSweep;
    final double rimGradStart = gradCenter - rimSweep;
    final double rimGradEnd = gradCenter + rimSweep;
    final rimPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.4, fontSize * 0.085)
      ..shader = ui.Gradient.sweep(
        arcOrigin,
        const <Color>[
          Color(0x00FFE86E),
          Color(0xBBFFF088),
          Color(0xF5FFFFFF),
          Color(0xBBFFF088),
          Color(0x00FFE86E),
        ],
        const <double>[0.0, 0.24, 0.50, 0.76, 1.0],
        TileMode.clamp,
        rimGradStart,
        rimGradEnd,
      );
    canvas.drawArc(
      Rect.fromCircle(center: arcOrigin, radius: arcRadius + rimHalfOffset),
      rimStart,
      rimSweep * 2.0,
      false,
      rimPaint,
    );
    if (arcRadius - rimHalfOffset > 4.0) {
      canvas.drawArc(
        Rect.fromCircle(center: arcOrigin, radius: arcRadius - rimHalfOffset),
        rimStart,
        rimSweep * 2.0,
        false,
        rimPaint,
      );
    }

    // 3. 顶部三连皇冠星芒 + 两侧虹光星屑
    _paintFourPointStar(
      canvas,
      center: apexStarCenter,
      radius: apexStarRadius,
      rotation: apexRotation,
      glowColor: const Color(0xD9FF8418),
      coreColor: const Color(0xFFFFFCE6),
    );
    _paintFourPointStar(
      canvas,
      center: apexLeftCenter,
      radius: apexFlankRadius,
      rotation: apexRotation + pi / 4,
      glowColor: const Color(0xCCFFE058),
      coreColor: const Color(0xFFFFFFFF),
    );
    _paintFourPointStar(
      canvas,
      center: apexRightCenter,
      radius: apexFlankRadius,
      rotation: apexRotation + pi / 4,
      glowColor: const Color(0xCCFFE058),
      coreColor: const Color(0xFFFFFFFF),
    );
    _paintFourPointStar(
      canvas,
      center: leftStarCenter,
      radius: sideStarRadius,
      rotation: leftRotation,
      glowColor: const Color(0xCCFF7A18),
      coreColor: const Color(0xFFFFFFFF),
    );
    _paintFourPointStar(
      canvas,
      center: rightStarCenter,
      radius: sideStarRadius,
      rotation: rightRotation,
      glowColor: const Color(0xCCFF7A18),
      coreColor: const Color(0xFFFFFFFF),
    );
    _paintFourPointStar(
      canvas,
      center: leftMiniCenter,
      radius: sideMiniRadius,
      rotation: leftRotation + pi / 4,
      glowColor: const Color(0xCC5CE8FF),
      coreColor: const Color(0xFFF0FCFF),
    );
    _paintFourPointStar(
      canvas,
      center: rightMiniCenter,
      radius: sideMiniRadius,
      rotation: rightRotation + pi / 4,
      glowColor: const Color(0xCCFF7FD8),
      coreColor: const Color(0xFFFFF0FA),
    );
  }

  static void _paintFourPointStar(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required Color glowColor,
    required Color coreColor,
  }) {
    if (radius <= 0.5) return;
    final double inner = radius * 0.26;
    final Path starPath = Path()
      ..moveTo(0, -radius)
      ..lineTo(inner, -inner)
      ..lineTo(radius, 0)
      ..lineTo(inner, inner)
      ..lineTo(0, radius)
      ..lineTo(-inner, inner)
      ..lineTo(-radius, 0)
      ..lineTo(-inner, -inner)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final glowPaint = Paint()
      ..isAntiAlias = true
      ..color = glowColor
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        max(1.2, radius * 0.35),
      );
    canvas.drawPath(starPath, glowPaint);

    final strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = max(1.0, radius * 0.18)
      ..color = const Color(0xCC6B1800);
    canvas.drawPath(starPath, strokePaint);

    final fillPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = coreColor;
    canvas.drawPath(starPath, fillPaint);
    canvas.restore();
  }
}
