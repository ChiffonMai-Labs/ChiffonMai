import 'dart:ui' as ui;

import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../note_geometry.dart';
import '../simai_colors.dart';
import 'note_utils.dart';

class NoteBatchFrameMetrics {
  final int spriteCount;
  final int flushCount;

  const NoteBatchFrameMetrics({
    required this.spriteCount,
    required this.flushCount,
  });
}

class _ReusableSpriteBatch {
  _ReusableSpriteBatch(ui.Image atlas)
    : batch = SpriteBatch(atlas, defaultColor: const Color(0xFFFFFFFF));

  final SpriteBatch batch;
  final List<int> handles = <int>[];
  int used = 0;

  void reset() {
    used = 0;
  }

  void add({
    required Rect source,
    required ui.RSTransform transform,
    Color? color,
  }) {
    final effectiveColor = color ?? const Color(0xFFFFFFFF);
    if (used < handles.length) {
      batch.replace(
        handles[used],
        source: source,
        transform: transform,
        color: effectiveColor,
      );
    } else {
      handles.add(
        batch.addTransform(
          source: source,
          transform: transform,
          color: effectiveColor,
        ),
      );
    }
    used++;
  }

  bool render(Canvas canvas, Paint paint) {
    if (used == 0) return false;
    while (handles.length > used) {
      batch.removeAt(handles.removeLast());
    }
    batch.render(canvas, blendMode: BlendMode.modulate, paint: paint);
    used = 0;
    return true;
  }

  void clear() {
    batch.clear();
    handles.clear();
    used = 0;
  }
}

class NoteAssetManager {
  NoteAssetManager({required this.images});

  final Images images;
  static const double _assetPixelRatio = 3.0;
  static const double _cellExtent = 110.0;
  static const int _atlasColumns = 4;
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
  };

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
    // A completed renderer always flushes in a finally block. Clear here too so
    // an interrupted frame can never leak stale draw commands into the next.
    for (final slot in _batchSlots) {
      slot.reset();
    }
    _activeBatchSlot = 0;
    _frameSpriteCount = 0;
    _frameFlushCount = 0;
  }

  bool enqueueSprite({
    required String key,
    required Offset position,
    required double size,
    double rotation = 0.0,
    int alpha = 255,
  }) {
    final source = _regions[key];
    final atlas = _atlas;
    if (atlas == null || source == null || size <= 0 || !size.isFinite) {
      return false;
    }

    final transform = ui.RSTransform.fromComponents(
      scale: size / source.width,
      rotation: rotation,
      translateX: position.dx,
      translateY: position.dy,
      anchorX: source.width / 2,
      anchorY: source.height / 2,
    );
    _batchSlot(atlas).add(
      source: source,
      transform: transform,
      color: alpha >= 255
          ? null
          : Color.fromARGB(alpha.clamp(0, 255).toInt(), 255, 255, 255),
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
  }) {
    if (kIsWeb) {
      return drawSpriteDirect(
        canvas,
        key: key,
        position: position,
        size: size,
        rotation: rotation,
        alpha: alpha,
      );
    }
    return enqueueSprite(
      key: key,
      position: position,
      size: size,
      rotation: rotation,
      alpha: alpha,
    );
  }

  bool drawSpriteDirect(
    Canvas canvas, {
    required String key,
    required Offset position,
    required double size,
    double rotation = 0.0,
    int alpha = 255,
  }) {
    final atlas = _atlas;
    final source = _regions[key];
    if (atlas == null || source == null || size <= 0 || !size.isFinite) {
      return false;
    }
    flush(canvas);
    _directPaint.color = Color.fromARGB(
      alpha.clamp(0, 255).toInt(),
      255,
      255,
      255,
    );
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

  Future<void> rebuild(double noteScale) async {
    if (_disposed) return;
    final safeScale = noteScale.isFinite && noteScale > 0 ? noteScale : 1.0;
    final pixelCell = (_cellExtent * safeScale * _assetPixelRatio).ceil();
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
      _drawAtlasEntry(canvas, entry.key, center, safeScale);
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
  ) {
    switch (key) {
      case 'tap_normal':
        _drawTapBody(canvas, center, SimaiColors.tapNormal, 1, 255, noteScale);
        return;
      case 'tap_each':
        _drawTapBody(canvas, center, SimaiColors.tapEach, 1, 255, noteScale);
        return;
      case 'tap_break':
        _drawTapBody(canvas, center, SimaiColors.tapBreak, 1, 255, noteScale);
        return;
      case 'star_normal':
        _drawStarBody(
          canvas,
          center,
          SimaiColors.slideNormal,
          1,
          255,
          0,
          noteScale,
        );
        return;
      case 'star_each':
        _drawStarBody(
          canvas,
          center,
          SimaiColors.slideEach,
          1,
          255,
          0,
          noteScale,
        );
        return;
      case 'star_break':
        _drawStarBody(
          canvas,
          center,
          SimaiColors.slideBreak,
          1,
          255,
          0,
          noteScale,
        );
        return;
      case 'star_tap_normal':
        _drawStarBody(
          canvas,
          center,
          SimaiColors.tapNormal,
          1,
          255,
          0,
          noteScale,
        );
        return;
      case 'star_tap_each':
        _drawStarBody(
          canvas,
          center,
          SimaiColors.tapEach,
          1,
          255,
          0,
          noteScale,
        );
        return;
      case 'touch_normal':
        _drawTouchPetalBody(
          canvas,
          center,
          SimaiColors.touchNormal,
          255,
          noteScale,
        );
        return;
      case 'touch_each':
        _drawTouchPetalBody(
          canvas,
          center,
          SimaiColors.touchEach,
          255,
          noteScale,
        );
        return;
      case 'touch_break':
        _drawTouchPetalBody(
          canvas,
          center,
          SimaiColors.touchBreak,
          255,
          noteScale,
        );
        return;
    }
  }

  // --- Drawing Helpers (Copied/Adapted from Components) ---

  void _drawTapBody(
    Canvas canvas,
    Offset position,
    Color color,
    double scale,
    int alpha,
    double noteScale,
  ) {
    double outerRadius = NoteGeometry.tapStarHoldRadius * scale * noteScale;
    double innerRatio = 0.65;
    double innerRadius = outerRadius * innerRatio;

    Paint paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Path path = Path();
    path.fillType = PathFillType.evenOdd;
    path.addOval(Rect.fromCircle(center: position, radius: outerRadius));
    path.addOval(Rect.fromCircle(center: position, radius: innerRadius));

    canvas.drawPath(path, paint);

    Paint strokePaint = Paint()
      ..color = Colors.white.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale * noteScale
      ..isAntiAlias = true;

    canvas.drawCircle(position, outerRadius, strokePaint);
    canvas.drawCircle(position, innerRadius, strokePaint);

    double dotRadius = 4.0 * scale * noteScale;
    canvas.drawCircle(position, dotRadius, paint);
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
    double radius = NoteGeometry.tapStarHoldRadius * scale * noteScale;
    double innerRatio = 0.6;
    Path outerPath = NoteUtils.createStarPath(radius);
    Path innerPath = NoteUtils.createStarPath(radius * innerRatio);

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    Paint paint = Paint()
      ..color = color.withAlpha(alpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    Path combinedPath = Path();
    combinedPath.fillType = PathFillType.evenOdd;
    combinedPath.addPath(outerPath, Offset.zero);
    combinedPath.addPath(innerPath, Offset.zero);

    canvas.drawPath(combinedPath, paint);

    Paint strokePaint = Paint()
      ..color = Colors.white.withAlpha(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * scale * noteScale
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(outerPath, strokePaint);
    canvas.drawPath(innerPath, strokePaint);

    canvas.restore();
  }

  void _drawTouchPetalBody(
    Canvas canvas,
    Offset center,
    Color color,
    int alpha,
    double noteScale,
  ) {
    // Draw a single petal triangle centered at `center`.
    // Points are relative to `center`.
    // Let's assume the petal points to the RIGHT (0 deg).
    // Tip at (v, 0), Left at (0, -v), Right at (0, v)?
    // No, standard Touch logic:
    // tip = petal + (cos(k+pi)*v, sin(k+pi)*v)
    // left = petal + (cos(k+pi/2)*v, ...)
    // right = petal + (cos(k-pi/2)*v, ...)
    // If we want it pointing RIGHT, let's say k=pi (so tip is at cos(2pi)=1).
    // Then tip = (v, 0).
    // left = (cos(3pi/2)*v, sin(3pi/2)*v) = (0, -v).
    // right = (cos(pi/2)*v, sin(pi/2)*v) = (0, v).

    final double v = 40.0 * noteScale;
    final double cornerRadius = 8.0 * noteScale;
    final double innerCornerRadius = cornerRadius * 0.4;
    final double outlineWidth = 3.0 * noteScale;

    final Offset tip = Offset(v, 0);
    final Offset left = Offset(0, -v);
    final Offset right = Offset(0, v);

    // Shift by center
    final Offset t = center + tip;
    final Offset l = center + left;
    final Offset r = center + right;

    final Path outer = NoteUtils.roundedTrianglePath(t, l, r, cornerRadius);

    // Gradient logic from TouchNoteComponent
    // fillPaint.shader = ui.Gradient.linear(petal, tip, ...)
    // petal is center, tip is t.
    // We can simulate this.
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Use a simpler gradient or solid color for cache?
    // The gradient depends on `t` (animation progress) in TouchNoteComponent.
    // Wait, `t` (alpha/fade) changes per frame.
    // If we bake the gradient with alpha=255, we can apply alpha later with drawImage.
    // But the gradient colors (g0, g1) might change?
    // g0 = color, g1 = lerp(color, black, 0.35).
    // This is constant for a given color type.

    final Color g0 = color;
    final Color g1 = Color.lerp(color, Colors.black, 0.35)!;

    fillPaint.shader = ui.Gradient.linear(center, t, [g0, g1]);
    fillPaint.color = Colors.white; // Base for shader?

    // Inner path
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

    final Path fillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addPath(inner, Offset.zero);

    canvas.drawPath(fillPath, fillPaint);

    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white
      ..isAntiAlias = true;

    canvas.drawPath(outer, strokePaint);
    canvas.drawPath(inner, strokePaint);
  }
}
