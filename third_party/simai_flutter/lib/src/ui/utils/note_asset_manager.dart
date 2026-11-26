import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../note_geometry.dart';
import '../note_style.dart';
import '../simai_colors.dart';
import '../simai_visual_tokens.dart';
import 'note_utils.dart';

class NoteBatchFrameMetrics {
  final int spriteCount;
  final int flushCount;

  const NoteBatchFrameMetrics({
    required this.spriteCount,
    required this.flushCount,
  });
}

/// 零堆分配的原生图集批处理槽位，直接向 `canvas.drawRawAtlas` 提交预分配类型数组。
class _ReusableSpriteBatch {
  _ReusableSpriteBatch(this.atlas);

  static const int _initialCapacity = 64;

  final ui.Image atlas;
  Float32List _transforms = Float32List(_initialCapacity * 4);
  Float32List _rects = Float32List(_initialCapacity * 4);
  Int32List _colors = Int32List(_initialCapacity);
  int _capacity = _initialCapacity;
  int used = 0;
  bool _hasColorModulation = false;

  void reset() {
    used = 0;
    _hasColorModulation = false;
  }

  void _ensureCapacity() {
    if (used < _capacity) return;
    final nextCapacity = _capacity * 2;
    final nextTransforms = Float32List(nextCapacity * 4);
    nextTransforms.setRange(0, _capacity * 4, _transforms);
    final nextRects = Float32List(nextCapacity * 4);
    nextRects.setRange(0, _capacity * 4, _rects);
    final nextColors = Int32List(nextCapacity);
    nextColors.setRange(0, _capacity, _colors);
    _transforms = nextTransforms;
    _rects = nextRects;
    _colors = nextColors;
    _capacity = nextCapacity;
  }

  void addRaw({
    required Rect source,
    required double x,
    required double y,
    required double scale,
    required double rotation,
    required int argbColor,
  }) {
    _ensureCapacity();

    // 旋转角为 0 时直接省去 sin/cos 计算。
    final double scos;
    final double ssin;
    if (rotation == 0.0) {
      scos = scale;
      ssin = 0.0;
    } else {
      scos = math.cos(rotation) * scale;
      ssin = math.sin(rotation) * scale;
    }
    final double anchorX = source.width * 0.5;
    final double anchorY = source.height * 0.5;
    final double tx = x - scos * anchorX + ssin * anchorY;
    final double ty = y - ssin * anchorX - scos * anchorY;

    final int base4 = used * 4;
    _transforms[base4] = scos;
    _transforms[base4 + 1] = ssin;
    _transforms[base4 + 2] = tx;
    _transforms[base4 + 3] = ty;

    _rects[base4] = source.left;
    _rects[base4 + 1] = source.top;
    _rects[base4 + 2] = source.right;
    _rects[base4 + 3] = source.bottom;

    _colors[used] = argbColor;
    if (argbColor != 0xFFFFFFFF) {
      _hasColorModulation = true;
    }
    used++;
  }

  bool render(Canvas canvas, Paint paint) {
    if (used == 0) return false;
    canvas.drawRawAtlas(
      atlas,
      Float32List.sublistView(_transforms, 0, used * 4),
      Float32List.sublistView(_rects, 0, used * 4),
      _hasColorModulation ? Int32List.sublistView(_colors, 0, used) : null,
      _hasColorModulation ? BlendMode.modulate : null,
      null,
      paint,
    );
    used = 0;
    _hasColorModulation = false;
    return true;
  }

  void clear() {
    used = 0;
    _hasColorModulation = false;
  }
}

class NoteAssetManager {
  NoteAssetManager({required this.images});

  final Images images;
  static const double _assetPixelRatio = 3.0;
  static const double _cellExtent = 110.0;
  static const int _atlasColumns = 4;

  /// 图集单格逻辑基准边长（noteScale = 1.0 时）。
  static const double cellExtent = _cellExtent;

  /// 打击特效预烘焙时的基准光环半径（留足外扩高斯柔光安全边距，避免跨格渗色）。
  static const double hitGlowBakedRadius = 26.0;

  /// 滑星箭头在图集内的烘焙倍率（2× 烘焙可提升任意角度旋转时的边缘锐度）。
  static const double slideArrowBakeScale = 2.0;

  /// Touch 中心圆点在图集内的烘焙半径。
  static const double touchCenterBakedRadius = 40.0;

  /// 4×5（17 格）图集槽位定义。
  static const Map<String, int> _atlasSlots = <String, int>{
    'tap_normal': 0,
    'tap_each': 1,
    'tap_break': 2,
    'star_normal': 3,
    'star_each': 4,
    'star_break': 5,
    'star_tap_normal': 6,
    'star_tap_each': 7,
    'touch_normal': 8,
    'touch_each': 9,
    'touch_break': 10,
    'touch_multi': 11,
    'hit_glow': 12,
    'slide_arrow': 13,
    'touch_center': 14,
    'star_tap_break': 15,
    'slide_arrow_break': 16,
  };

  /// 根据目标光环半径换算 `'hit_glow'` 精灵绘制尺寸。
  static double hitGlowSpriteSize(double targetRadius) =>
      targetRadius * (_cellExtent / hitGlowBakedRadius);

  /// 根据目标箭头缩放倍率换算 `'slide_arrow'` 精灵绘制尺寸。
  static double slideArrowSpriteSize(double arrowScale) =>
      arrowScale * (_cellExtent / slideArrowBakeScale);

  /// 根据目标圆点半径换算 `'touch_center'` 精灵绘制尺寸。
  static double touchCenterSpriteSize(double targetRadius) =>
      targetRadius * (_cellExtent / touchCenterBakedRadius);

  final Paint _batchPaint = Paint()
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;
  final Paint _directPaint = Paint()
    ..filterQuality = FilterQuality.high
    ..isAntiAlias = true;

  final Map<String, Rect> _regions = <String, Rect>{};
  final List<_ReusableSpriteBatch> _batchSlots = <_ReusableSpriteBatch>[];
  ui.Image? _atlas;
  String? _atlasCacheKey;
  int? _lastPixelCell;
  SimaiNoteStyle? _lastNoteStyle;
  int _atlasGeneration = 0;
  int _frameSpriteCount = 0;
  int _frameFlushCount = 0;
  int _activeBatchSlot = 0;
  bool _disposed = false;

  bool hasAsset(String key) => _atlas != null && _regions.containsKey(key);

  @visibleForTesting
  ui.Image? get debugAtlas => _atlas;

  @visibleForTesting
  Rect? debugRegion(String key) => _regions[key];

  void beginFrame() {
    // 正常渲染结束总会在 finally 中 flush；此处再次清零可避免异常中断帧残留脏数据。
    for (final slot in _batchSlots) {
      slot.reset();
    }
    _activeBatchSlot = 0;
    _frameSpriteCount = 0;
    _frameFlushCount = 0;
  }

  /// 合并可选染色与透明度为 `BlendMode.modulate` 调制色。
  static Color? _resolveModulationColor(Color? color, int alpha) {
    final clampedAlpha = alpha.clamp(0, 255).toInt();
    if (color == null) {
      return clampedAlpha >= 255
          ? null
          : Color.fromARGB(clampedAlpha, 255, 255, 255);
    }
    final effectiveAlpha = (color.a * clampedAlpha).round().clamp(0, 255);
    return color.withAlpha(effectiveAlpha);
  }

  /// 用整型位运算直接算出 `BlendMode.modulate` 的 ARGB 值，热路径零 Color 对象分配。
  static int _resolveModulationArgb(Color? color, int alpha) {
    final clampedAlpha = alpha.clamp(0, 255).toInt();
    if (color == null) {
      return clampedAlpha >= 255
          ? 0xFFFFFFFF
          : ((clampedAlpha & 0xFF) << 24) | 0x00FFFFFF;
    }
    final effectiveAlpha = (color.a * clampedAlpha).round().clamp(0, 255);
    return ((effectiveAlpha & 0xFF) << 24) | (color.toARGB32() & 0x00FFFFFF);
  }

  bool enqueueSprite({
    required String key,
    required Offset position,
    required double size,
    double rotation = 0.0,
    int alpha = 255,
    Color? color,
  }) {
    final source = _regions[key];
    final atlas = _atlas;
    if (atlas == null || source == null || size <= 0 || !size.isFinite) {
      return false;
    }

    _batchSlot(atlas).addRaw(
      source: source,
      x: position.dx,
      y: position.dy,
      scale: size / source.width,
      rotation: rotation,
      argbColor: _resolveModulationArgb(color, alpha),
    );
    _frameSpriteCount++;
    return true;
  }

  bool drawSprite(
    Canvas canvas, {
    required String key,
    required Offset position,
    required double size,
    double rotation = 0.0,
    int alpha = 255,
    Color? color,
  }) {
    if (kIsWeb) {
      return drawSpriteDirect(
        canvas,
        key: key,
        position: position,
        size: size,
        rotation: rotation,
        alpha: alpha,
        color: color,
      );
    }
    return enqueueSprite(
      key: key,
      position: position,
      size: size,
      rotation: rotation,
      alpha: alpha,
      color: color,
    );
  }

  bool drawSpriteDirect(
    Canvas canvas, {
    required String key,
    required Offset position,
    required double size,
    double rotation = 0.0,
    int alpha = 255,
    Color? color,
  }) {
    final atlas = _atlas;
    final source = _regions[key];
    if (atlas == null || source == null || size <= 0 || !size.isFinite) {
      return false;
    }
    flush(canvas);
    final modulation = _resolveModulationColor(color, alpha);
    if (color != null && modulation != null) {
      _directPaint
        ..color = const Color(0xFFFFFFFF)
        ..colorFilter = ColorFilter.mode(modulation, BlendMode.modulate);
    } else {
      _directPaint
        ..colorFilter = null
        ..color = modulation ?? const Color(0xFFFFFFFF);
    }
    if (rotation == 0.0) {
      canvas.drawImageRect(
        atlas,
        source,
        Rect.fromCenter(center: position, width: size, height: size),
        _directPaint,
      );
    } else {
      canvas
        ..save()
        ..translate(position.dx, position.dy)
        ..rotate(rotation)
        ..drawImageRect(
          atlas,
          source,
          Rect.fromCenter(center: Offset.zero, width: size, height: size),
          _directPaint,
        )
        ..restore();
    }
    _frameSpriteCount++;
    return true;
  }

  void flush(Canvas canvas) {
    if (_activeBatchSlot >= _batchSlots.length) return;
    if (_batchSlots[_activeBatchSlot].render(canvas, _batchPaint)) {
      _frameFlushCount++;
      _activeBatchSlot++;
    }
  }

  _ReusableSpriteBatch _batchSlot(ui.Image atlas) {
    if (_activeBatchSlot == _batchSlots.length) {
      _batchSlots.add(_ReusableSpriteBatch(atlas));
    }
    return _batchSlots[_activeBatchSlot];
  }

  NoteBatchFrameMetrics endFrame() {
    return NoteBatchFrameMetrics(
      spriteCount: _frameSpriteCount,
      flushCount: _frameFlushCount,
    );
  }

  Future<void> rebuild(
    double noteScale, {
    SimaiNoteStyle noteStyle = SimaiNoteStyle.arcade,
  }) async {
    if (_disposed) return;
    final safeScale = noteScale.isFinite && noteScale > 0 ? noteScale : 1.0;
    final pixelCell = (_cellExtent * safeScale * _assetPixelRatio).ceil();
    // 尺寸与样式缓存守卫：单格像素尺寸和音符样式均未变化且图集有效时直接返回，避免重复离屏 3× GPU 纹理栅格化。
    if (pixelCell == _lastPixelCell &&
        noteStyle == _lastNoteStyle &&
        _atlas != null &&
        !_disposed) {
      return;
    }
    final rows = (_atlasSlots.length / _atlasColumns).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(_assetPixelRatio, _assetPixelRatio);
    final logicalCell = pixelCell / _assetPixelRatio;

    for (final entry in _atlasSlots.entries) {
      final slot = entry.value;
      final row = slot ~/ _atlasColumns;
      final column = slot % _atlasColumns;
      final center = Offset(
        (column + 0.5) * logicalCell,
        (row + 0.5) * logicalCell,
      );
      final cellRect = Rect.fromCenter(
        center: center,
        width: logicalCell,
        height: logicalCell,
      );
      // 逐格裁切，防止预烘焙阴影或高斯柔光跨格污染相邻精灵。
      canvas.save();
      canvas.clipRect(cellRect);
      _drawAtlasEntry(canvas, entry.key, center, safeScale, noteStyle);
      canvas.restore();
    }

    final picture = recorder.endRecording();
    ui.Image image;
    try {
      image = await picture.toImage(
        pixelCell * _atlasColumns,
        pixelCell * rows,
      );
    } finally {
      picture.dispose();
    }

    if (_disposed) {
      image.dispose();
      return;
    }

    final newKey = 'simai-note-atlas-${++_atlasGeneration}';
    images.add(newKey, image);
    final oldKey = _atlasCacheKey;
    _atlasCacheKey = newKey;
    _atlas = image;
    _lastPixelCell = pixelCell;
    _lastNoteStyle = noteStyle;
    for (final slot in _batchSlots) {
      slot.clear();
    }
    _batchSlots.clear();
    _regions
      ..clear()
      ..addEntries(
        _atlasSlots.entries.map((entry) {
          final slot = entry.value;
          final row = slot ~/ _atlasColumns;
          final column = slot % _atlasColumns;
          return MapEntry(
            entry.key,
            Rect.fromLTWH(
              column * pixelCell.toDouble(),
              row * pixelCell.toDouble(),
              pixelCell.toDouble(),
              pixelCell.toDouble(),
            ),
          );
        }),
      );
    if (oldKey != null) {
      images.clear(oldKey);
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _lastPixelCell = null;
    _lastNoteStyle = null;
    for (final slot in _batchSlots) {
      slot.clear();
    }
    _batchSlots.clear();
    _atlas = null;
    _regions.clear();
    final key = _atlasCacheKey;
    _atlasCacheKey = null;
    if (key != null) {
      images.clear(key);
    }
  }

  void _drawAtlasEntry(
    Canvas canvas,
    String key,
    Offset center,
    double noteScale,
    SimaiNoteStyle noteStyle,
  ) {
    final bool arcade = noteStyle == SimaiNoteStyle.arcade;
    switch (key) {
      case 'tap_normal':
        if (arcade) {
          _drawArcadeTapBody(
            canvas,
            center,
            SimaiColors.tapNormal,
            SimaiVisualTokens.colorTapGradientStart,
            SimaiVisualTokens.colorTapGradientEnd,
            noteScale,
          );
        } else {
          _drawTapBody(canvas, center, SimaiColors.tapNormal, 1, 255, noteScale);
        }
        return;
      case 'tap_each':
        if (arcade) {
          _drawArcadeTapBody(
            canvas,
            center,
            SimaiColors.tapEach,
            SimaiVisualTokens.colorSimultaneousGradientStart,
            SimaiVisualTokens.colorSimultaneousGradientEnd,
            noteScale,
          );
        } else {
          _drawTapBody(canvas, center, SimaiColors.tapEach, 1, 255, noteScale);
        }
        return;
      case 'tap_break':
        if (arcade) {
          _drawArcadeTapBody(
            canvas,
            center,
            SimaiColors.tapBreak,
            SimaiVisualTokens.colorBreakGradientStart,
            SimaiVisualTokens.colorBreakGradientEnd,
            noteScale,
          );
        } else {
          _drawTapBody(canvas, center, SimaiColors.tapBreak, 1, 255, noteScale);
        }
        return;
      case 'star_normal':
        _drawStarEntry(canvas, center, SimaiColors.slideNormal, noteScale, arcade);
        return;
      case 'star_each':
        _drawStarEntry(canvas, center, SimaiColors.slideEach, noteScale, arcade);
        return;
      case 'star_break':
        _drawStarEntry(canvas, center, SimaiColors.slideBreak, noteScale, arcade);
        return;
      case 'star_tap_normal':
        _drawStarEntry(canvas, center, SimaiColors.tapNormal, noteScale, arcade);
        return;
      case 'star_tap_each':
        _drawStarEntry(canvas, center, SimaiColors.tapEach, noteScale, arcade);
        return;
      case 'star_tap_break':
        _drawStarEntry(canvas, center, SimaiColors.tapBreak, noteScale, arcade);
        return;
      case 'touch_normal':
        if (arcade) {
          _drawTouchPetalBody(
            canvas,
            center,
            SimaiVisualTokens.colorTouchCyan,
            255,
            noteScale,
            gradientStart: SimaiVisualTokens.colorTouchCyan,
            gradientEnd: SimaiVisualTokens.colorTouchBlue,
            bakeShadow: true,
            arcadeOutline: true,
          );
        } else {
          _drawTouchPetalBody(
            canvas,
            center,
            SimaiColors.touchNormal,
            255,
            noteScale,
          );
        }
        return;
      case 'touch_each':
        if (arcade) {
          _drawTouchPetalBody(
            canvas,
            center,
            const Color(0xFFFFFF00),
            255,
            noteScale,
            gradientStart: const Color(0xFFFFFF00),
            gradientEnd: SimaiVisualTokens.colorSimultaneousGold,
            bakeShadow: true,
            arcadeOutline: true,
          );
        } else {
          _drawTouchPetalBody(
            canvas,
            center,
            SimaiColors.touchEach,
            255,
            noteScale,
          );
        }
        return;
      case 'touch_break':
        if (arcade) {
          _drawTouchPetalBody(
            canvas,
            center,
            SimaiColors.touchBreak,
            255,
            noteScale,
            gradientStart: SimaiVisualTokens.colorBreakGradientStart,
            gradientEnd: SimaiVisualTokens.colorBreakGradientEnd,
            bakeShadow: true,
            arcadeOutline: true,
          );
        } else {
          _drawTouchPetalBody(
            canvas,
            center,
            SimaiColors.touchBreak,
            255,
            noteScale,
          );
        }
        return;
      case 'touch_multi':
        _drawTouchMultiPetalBody(
          canvas,
          center,
          noteScale,
          arcadeOutline: arcade,
        );
        return;
      case 'hit_glow':
        _drawHitGlowBody(canvas, center, noteScale);
        return;
      case 'slide_arrow':
        if (arcade) {
          _drawArcadeSlideArrowBody(
            canvas,
            center,
            noteScale,
            isBreakDualColor: false,
          );
        } else {
          _drawSlideArrowBody(canvas, center, noteScale);
        }
        return;
      case 'slide_arrow_break':
        if (arcade) {
          _drawArcadeSlideArrowBody(
            canvas,
            center,
            noteScale,
            isBreakDualColor: true,
          );
        } else {
          _drawSlideArrowBody(canvas, center, noteScale);
        }
        return;
      case 'touch_center':
        _drawTouchCenterBody(canvas, center, noteScale);
        return;
    }
  }

  void _drawStarEntry(
    Canvas canvas,
    Offset center,
    Color color,
    double noteScale,
    bool arcade,
  ) {
    if (arcade) {
      _drawArcadeStarBody(canvas, center, color, noteScale);
    } else {
      _drawStarBody(canvas, center, color, 1, 255, 0, noteScale);
    }
  }

  // --- 图集离屏预烘焙绘制函数 ---

  void _drawTapBody(
    Canvas canvas,
    Offset position,
    Color color,
    double scale,
    int alpha,
    double noteScale,
  ) {
    final double outerRadius = NoteGeometry.tapStarHoldRadius * scale * noteScale;
    const double innerRatio = 0.65;
    final double innerRadius = outerRadius * innerRatio;

    final Paint paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path path = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: position, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: position, radius: innerRadius));

    canvas.drawPath(path, paint);

    final Paint strokePaint = Paint()
      ..color = Colors.white.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale * noteScale
      ..isAntiAlias = true;

    canvas.drawCircle(position, outerRadius, strokePaint);
    canvas.drawCircle(position, innerRadius, strokePaint);

    final double dotRadius = 4.0 * scale * noteScale;
    canvas.drawCircle(position, dotRadius, paint);
  }

  /// 官方机台风格 Tap（借鉴 LXNS `NoteRenderer`：四象限方向渐变、黑白双描边、按比例中心点）。
  void _drawArcadeTapBody(
    Canvas canvas,
    Offset position,
    Color baseColor,
    Color gradStart,
    Color gradEnd,
    double noteScale,
  ) {
    final double outerRadius = NoteGeometry.tapStarHoldRadius * noteScale;
    final double innerRadius = outerRadius * SimaiVisualTokens.tapInnerRingRatio;
    final double strokeW = 2.0 * noteScale;
    final Color lightColor = Color.lerp(
      gradStart,
      Colors.white,
      SimaiVisualTokens.noteLightenRatio,
    )!;
    final double midR = (innerRadius + outerRadius) * 0.5;
    final Rect outerRect = Rect.fromCircle(
      center: position,
      radius: outerRadius,
    );
    final Rect innerRect = Rect.fromCircle(
      center: position,
      radius: innerRadius,
    );

    final Paint sectorPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    for (int i = 0; i < 4; i++) {
      final double sectorStart = i * (math.pi / 2);
      final double sectorEnd = sectorStart + (math.pi / 2);
      final Offset p0 =
          position +
          Offset(math.cos(sectorStart) * midR, math.sin(sectorStart) * midR);
      final Offset p1 =
          position +
          Offset(math.cos(sectorEnd) * midR, math.sin(sectorEnd) * midR);
      sectorPaint.shader = ui.Gradient.linear(p0, p1, [lightColor, gradEnd]);
      final Path sectorPath = Path()
        ..arcTo(outerRect, sectorStart, math.pi / 2, false)
        ..arcTo(innerRect, sectorEnd, -math.pi / 2, false)
        ..close();
      canvas.drawPath(sectorPath, sectorPaint);
    }

    final Paint blackStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..isAntiAlias = true;
    canvas.drawCircle(position, outerRadius + strokeW, blackStroke);
    final double innerBlackR = innerRadius - strokeW;
    if (innerBlackR > 0) {
      canvas.drawCircle(position, innerBlackR, blackStroke);
    }

    final Paint whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..isAntiAlias = true;
    canvas.drawCircle(position, outerRadius, whiteStroke);
    canvas.drawCircle(position, innerRadius, whiteStroke);

    final Paint dotPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(position, outerRadius * 0.15, dotPaint);
  }

  void _drawStarBody(
    Canvas canvas,
    Offset position,
    Color color,
    double scale,
    int alpha,
    double rotation,
    double noteScale,
  ) {
    final double radius = NoteGeometry.tapStarHoldRadius * scale * noteScale;
    const double innerRatio = 0.6;
    final Path outerPath = NoteUtils.createStarPath(radius);
    final Path innerPath = NoteUtils.createStarPath(radius * innerRatio);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    final Paint paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path combinedPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outerPath, Offset.zero)
      ..addPath(innerPath, Offset.zero);

    canvas.drawPath(combinedPath, paint);

    final Paint strokePaint = Paint()
      ..color = Colors.white.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale * noteScale
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(outerPath, strokePaint);
    canvas.drawPath(innerPath, strokePaint);

    canvas.restore();
  }

  /// 官方机台风格五角星（借鉴 LXNS `SlideRenderer.drawStar`：0.55 内孔比例、黑底描边、白线与中心点）。
  void _drawArcadeStarBody(
    Canvas canvas,
    Offset position,
    Color color,
    double noteScale,
  ) {
    final double radius = NoteGeometry.tapStarHoldRadius * noteScale;
    const double innerHoleRatio = 0.55;
    final double strokeW = 2.0 * noteScale;
    final Path outerPath = NoteUtils.createStarPath(radius);
    final Path innerPath = NoteUtils.createStarPath(radius * innerHoleRatio);

    canvas.save();
    canvas.translate(position.dx, position.dy);

    final Paint blackStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 3
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(outerPath, blackStroke);
    canvas.drawPath(innerPath, blackStroke);

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final Path combinedPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outerPath, Offset.zero)
      ..addPath(innerPath, Offset.zero);
    canvas.drawPath(combinedPath, fillPaint);

    final Paint whiteStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(outerPath, whiteStroke);
    canvas.drawPath(innerPath, whiteStroke);

    canvas.drawCircle(Offset.zero, radius * 0.15, fillPaint);
    canvas.restore();
  }

  void _drawTouchPetalBody(
    Canvas canvas,
    Offset center,
    Color color,
    int alpha,
    double noteScale, {
    Color? gradientStart,
    Color? gradientEnd,
    bool bakeShadow = false,
    bool arcadeOutline = false,
  }) {
    final double v = 40.0 * noteScale;
    final double cornerRadius = 8.0 * noteScale;
    final double innerCornerRadius = cornerRadius * 0.4;
    final double outlineWidth = (arcadeOutline ? 2.0 : 3.0) * noteScale;

    final Offset t = center + Offset(v, 0);
    final Offset l = center + Offset(0, -v);
    final Offset r = center + Offset(0, v);

    final Path outer = NoteUtils.roundedTrianglePath(t, l, r, cornerRadius);

    // 多押或街机风格 Touch 在图集构建期一次性预烘焙柔和外阴影，运行时不再逐帧调用 drawShadow。
    if (bakeShadow) {
      final Paint shadowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x80000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0 * noteScale)
        ..isAntiAlias = true;
      canvas.drawPath(outer, shadowPaint);
    }

    final Color g0 = gradientStart ?? color;
    final Color g1 = gradientEnd ?? Color.lerp(color, Colors.black, 0.35)!;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = Colors.white.withAlpha(alpha)
      ..shader = ui.Gradient.linear(center, t, [g0, g1]);

    final Offset centroid = Offset(
      (t.dx + l.dx + r.dx) / 3,
      (t.dy + l.dy + r.dy) / 3,
    );
    final Offset innerTip = centroid + (t - centroid) * 0.4;
    final Offset innerLeft = centroid + (l - centroid) * 0.4;
    final Offset innerRight = centroid + (r - centroid) * 0.4;
    final Path inner = NoteUtils.roundedTrianglePath(
      innerTip,
      innerLeft,
      innerRight,
      innerCornerRadius,
    );

    if (arcadeOutline) {
      final Paint blackStroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outlineWidth * 3
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black.withAlpha(alpha)
        ..isAntiAlias = true;
      canvas.drawPath(outer, blackStroke);
      canvas.drawPath(inner, blackStroke);
    }

    final Path fillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addPath(inner, Offset.zero);

    canvas.drawPath(fillPath, fillPaint);

    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withAlpha(alpha)
      ..isAntiAlias = true;

    canvas.drawPath(outer, strokePaint);
    canvas.drawPath(inner, strokePaint);
  }

  /// 预烘焙黄色多押 Touch 花瓣（含柔和外阴影与金黄渐变）。
  void _drawTouchMultiPetalBody(
    Canvas canvas,
    Offset center,
    double noteScale, {
    bool arcadeOutline = false,
  }) {
    _drawTouchPetalBody(
      canvas,
      center,
      const Color(0xFFFFFF00),
      255,
      noteScale,
      gradientStart: const Color(0xFFFFFF00),
      gradientEnd: const Color(0xFFFFD700),
      bakeShadow: true,
      arcadeOutline: arcadeOutline,
    );
  }

  /// 预烘焙白色径向柔光 + 亮环打击特效（高斯模糊仅在此处烘焙一次，运行时靠染色合批）。
  void _drawHitGlowBody(Canvas canvas, Offset center, double noteScale) {
    final double r = hitGlowBakedRadius * noteScale;
    final double glowStroke = r * 0.44;
    final double ringStroke = r * 0.22;
    final double highlightStroke = (r * 0.06).clamp(1.0, 4.0 * noteScale);

    final Paint glowPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = glowStroke
      ..color = Colors.white.withAlpha(115)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.25);

    final Paint ringPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringStroke
      ..color = Colors.white.withAlpha(235);

    final Paint highlightPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlightStroke
      ..color = Colors.white.withAlpha(195);

    canvas.drawCircle(center, r, glowPaint);
    canvas.drawCircle(center, r, ringPaint);
    canvas.drawCircle(center, r - ringStroke * 0.32, highlightPaint);
  }

  /// 预烘焙白色通用滑星箭头（运行时通过 RSTransform 旋转缩放 + 颜色调制合批）。
  void _drawSlideArrowBody(Canvas canvas, Offset center, double noteScale) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    final Path arrowPath = NoteGeometry.buildSlideArrowPath(
      noteScale * slideArrowBakeScale,
    );
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, paint);
    canvas.restore();
  }

  /// 官方机台风格 V 形角平分线滑星箭头（借鉴 LXNS `SlideRenderer.buildArrowPaths`：带阴影、黑边与绝赞双色）。
  void _drawArcadeSlideArrowBody(
    Canvas canvas,
    Offset center,
    double noteScale, {
    required bool isBreakDualColor,
  }) {
    final s = noteScale * slideArrowBakeScale;
    const arrowHeight = 44.6;
    const arrowWidth = 12.2;
    const lineWidth = 16.6;
    const centerShiftX = 9.5;
    const shadowShift = 5.0;

    final x1 = (-arrowWidth / 2 + centerShiftX) * s;
    final y1 = (-arrowHeight / 2) * s;
    final x2 = (arrowWidth / 2 + centerShiftX) * s;
    const y2 = 0.0;
    final x3 = (-arrowWidth / 2 + centerShiftX) * s;
    final y3 = (arrowHeight / 2) * s;

    double hypot(double dx, double dy) => math.sqrt(dx * dx + dy * dy);
    final dx1 = x1 - x2;
    final dy1 = y1 - y2;
    final dx2 = x3 - x2;
    final dy2 = y3 - y2;
    final len1 = hypot(dx1, dy1);
    final len2 = hypot(dx2, dy2);
    if (len1 == 0 || len2 == 0) return;

    final cosAngle = ((dx1 * dx2 + dy1 * dy2) / (len1 * len2)).clamp(-1.0, 1.0);
    final sinHalf = math.sqrt((1.0 - cosAngle) / 2.0);
    if (sinHalf <= 0.001) return;

    final midX = (x1 + x3) * 0.5;
    final midY = (y1 + y3) * 0.5;
    final bLen = hypot(midX - x2, midY - y2);
    if (bLen == 0) return;
    final edgeLen = (lineWidth * s) / sinHalf;
    final bx = x2 + ((midX - x2) / bLen) * edgeLen;
    final by = y2 + ((midY - y2) / bLen) * edgeLen;
    final bx3 = bx + x3 - x2;
    final by3 = by + y3 - y2;
    final bx1 = bx + x1 - x2;
    final by1 = by + y1 - y2;

    final mainPath = Path()
      ..moveTo(x2, y2)
      ..lineTo(x3, y3)
      ..lineTo(bx3, by3)
      ..lineTo(bx, by)
      ..lineTo(bx1, by1)
      ..lineTo(x1, y1)
      ..close();

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // 反向投影
    canvas.save();
    canvas.translate(-shadowShift * s, 0.0);
    canvas.drawPath(
      mainPath,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = const Color(0x66000000),
    );
    canvas.restore();

    if (isBreakDualColor) {
      // 绝赞滑星右橙左黄双色，先铺整箭橙色再覆盖左半明黄避免拼接缝。
      canvas.drawPath(
        mainPath,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = SimaiVisualTokens.colorSlideArrowRight,
      );
      final leftHalf = Path()
        ..moveTo(x2, y2)
        ..lineTo(bx, by)
        ..lineTo(bx3, by3)
        ..lineTo(x3, y3)
        ..close();
      canvas.drawPath(
        leftHalf,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = SimaiVisualTokens.colorSlideSimultaneous,
      );
    } else {
      // 常规与双押箭头的填充留纯白，运行时由 BlendMode.modulate 上青/黄色。
      canvas.drawPath(
        mainPath,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = Colors.white,
      );
    }

    canvas.drawPath(
      mainPath,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * s
        ..strokeJoin = StrokeJoin.miter
        ..color = Colors.black,
    );
    canvas.restore();
  }

  /// 预烘焙白色 Touch 中心圆点（运行时按单/多押配色合批绘制外描边与内实心圆）。
  void _drawTouchCenterBody(Canvas canvas, Offset center, double noteScale) {
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, touchCenterBakedRadius * noteScale, paint);
  }
}
