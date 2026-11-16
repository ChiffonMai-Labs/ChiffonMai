import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../ui/simai_game.dart';
import '../ui/simai_player.dart';
import 'video_export_models.dart';

class SimaiVideoFrameRenderer {
  final SimaiPlayerController controller;
  final SimaiVideoMetadata metadata;
  final SimaiVideoQuality quality;
  final Size? outputSize;

  late final SimaiVideoLayout layout = outputSize == null
      ? SimaiVideoLayout.forQuality(quality)
      : SimaiVideoLayout.forSize(outputSize!);
  late final SimaiGame _game;
  ui.Image? _coverImage;
  ui.Picture? _headerPicture;
  bool _prepared = false;
  bool _disposed = false;

  SimaiVideoFrameRenderer({
    required this.controller,
    required this.metadata,
    required this.quality,
    this.outputSize,
  });

  double get visualDuration => _game.totalVisualDuration;

  @visibleForTesting
  bool get debugShowCornerInfo => _game.showCornerInfo;

  @visibleForTesting
  bool get debugShowFps => _game.showFps;

  void updateShowCornerInfo(bool value) {
    if (!_prepared || _disposed) return;
    _game.showCornerInfo = value;
  }

  Future<void> prepare({bool Function()? isCancelled}) async {
    if (_prepared) return;
    if (_disposed) throw StateError('Renderer is already disposed.');
    void checkCancelled() {
      if (isCancelled?.call() ?? false) {
        throw const SimaiVideoExportCancelledException();
      }
    }

    checkCancelled();
    _coverImage = await _resolveImage(
      metadata.coverImageProvider,
      layout.coverRect.size,
    );
    checkCancelled();
    _headerPicture = _buildHeaderPicture();

    _game = SimaiGame(
      chart: controller.chart,
      headlessExport: true,
      headlessExportCancelled: isCancelled,
      isPlaying: false,
      ringApproachTime: controller.approachTime,
      touchApproachTime: controller.touchApproachTime,
      playbackRate: 1.0,
      musicVolume: controller.musicVolume,
      hitSoundOffset: controller.hitSoundOffsetMs / 1000.0,
      hitSoundEnabled: false,
      backgroundMode: controller.backgroundMode,
      mirrorMode: controller.mirrorMode,
      rotateSlideStar: controller.rotateSlideStar,
      pinkSlideStar: controller.pinkSlideStar,
      standardBreakSlide: controller.standardBreakSlide,
      highlightExNotes: controller.highlightExNotes,
      showApproachLine: controller.showApproachLine,
      showHitEffects: controller.showHitEffects,
      showAchievementRate: controller.showAchievementRate,
      centerDisplayMode: controller.centerDisplayMode,
      showCornerInfo: controller.showCornerInfo,
      showFps: false,
      showDetailedPerformanceInfo: controller.showDetailedPerformanceInfo,
      initialChartTime: 0,
      offset: controller.effectiveMusicOffsetSeconds,
      backgroundImageProvider: controller.backgroundImageProvider,
    );
    await _game.prepareHeadlessExport(Vector2.all(layout.contentRect.width));
    checkCancelled();
    _prepared = true;
  }

  Future<Uint8List> renderRgbaFrame(
    double chartTime, {
    required bool resetWindow,
  }) async {
    final image = await renderImageFrame(chartTime, resetWindow: resetWindow);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) {
        throw StateError('Flutter failed to read back the rendered frame.');
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  Future<ui.Image> renderImageFrame(
    double chartTime, {
    required bool resetWindow,
  }) async {
    if (!_prepared || _disposed) {
      throw StateError('Renderer is not ready.');
    }
    _game.updateExportTime(chartTime, resetWindow: resetWindow);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFF08080B), BlendMode.src);
    canvas.drawPicture(_headerPicture!);

    final contentRect = layout.contentRect;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(contentRect, Radius.circular(28 * layout.scale)),
    );
    canvas.drawRect(contentRect, Paint()..color = Colors.black);
    canvas.translate(contentRect.left, contentRect.top);
    _game.render(canvas);
    canvas.restore();

    final picture = recorder.endRecording();
    try {
      return await picture.toImage(
        layout.videoSize.width.round(),
        layout.videoSize.height.round(),
      );
    } finally {
      picture.dispose();
    }
  }

  ui.Picture _buildHeaderPicture() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = layout.scale;
    final header = layout.headerRect;
    final foreground = metadata.difficulty.foregroundColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(header, Radius.circular(28 * scale)),
      Paint()..color = metadata.difficulty.cardColor,
    );

    final cover = _coverImage;
    if (cover != null) {
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(layout.coverRect, Radius.circular(20 * scale)),
      );
      paintImage(
        canvas: canvas,
        rect: layout.coverRect,
        image: cover,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      );
      canvas.restore();
    }

    final textLeft = 244 * scale;
    final textWidth = 520 * scale;
    _paintSingleLine(
      canvas,
      metadata.title,
      Offset(textLeft, 96 * scale),
      textWidth,
      maxFontSize: 46 * scale,
      minFontSize: 30 * scale,
      color: foreground,
      fontWeight: FontWeight.w700,
    );
    _paintSingleLine(
      canvas,
      metadata.artist,
      Offset(textLeft, 166 * scale),
      textWidth,
      maxFontSize: 30 * scale,
      minFontSize: 21 * scale,
      color: foreground.withValues(alpha: 0.88),
      fontWeight: FontWeight.w500,
    );

    _paintCenteredSingleLine(
      canvas,
      metadata.difficulty.label,
      Rect.fromLTWH(792 * scale, 100 * scale, 208 * scale, 42 * scale),
      maxFontSize: 31 * scale,
      minFontSize: 22 * scale,
      color: foreground,
      fontWeight: FontWeight.w700,
    );
    _paintCenteredSingleLine(
      canvas,
      metadata.level,
      Rect.fromLTWH(792 * scale, 145 * scale, 208 * scale, 78 * scale),
      maxFontSize: 58 * scale,
      minFontSize: 38 * scale,
      color: foreground,
      fontWeight: FontWeight.w800,
    );
    return recorder.endRecording();
  }

  static void _paintSingleLine(
    Canvas canvas,
    String text,
    Offset offset,
    double maxWidth, {
    required double maxFontSize,
    required double minFontSize,
    required Color color,
    required FontWeight fontWeight,
  }) {
    final painter = _createFittedTextPainter(
      text,
      maxWidth,
      maxFontSize: maxFontSize,
      minFontSize: minFontSize,
      color: color,
      fontWeight: fontWeight,
    );
    painter.paint(canvas, offset);
    painter.dispose();
  }

  static void _paintCenteredSingleLine(
    Canvas canvas,
    String text,
    Rect rect, {
    required double maxFontSize,
    required double minFontSize,
    required Color color,
    required FontWeight fontWeight,
  }) {
    final painter = _createFittedTextPainter(
      text,
      rect.width,
      maxFontSize: maxFontSize,
      minFontSize: minFontSize,
      color: color,
      fontWeight: fontWeight,
      textAlign: TextAlign.center,
    );
    painter.paint(
      canvas,
      Offset(rect.left, rect.top + (rect.height - painter.height) / 2),
    );
    painter.dispose();
  }

  static TextPainter _createFittedTextPainter(
    String text,
    double maxWidth, {
    required double maxFontSize,
    required double minFontSize,
    required Color color,
    required FontWeight fontWeight,
    TextAlign textAlign = TextAlign.left,
  }) {
    double fontSize = maxFontSize;
    late TextPainter painter;
    while (true) {
      painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);
      if (!painter.didExceedMaxLines || fontSize <= minFontSize) break;
      painter.dispose();
      fontSize = (fontSize - 2).clamp(minFontSize, maxFontSize);
    }
    return painter;
  }

  static Future<ui.Image> _resolveImage(ImageProvider provider, Size size) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration(size: size));
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete(info.image.clone());
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_prepared) {
      _game.disposeHeadlessExport();
    }
    _headerPicture?.dispose();
    _headerPicture = null;
    _coverImage?.dispose();
    _coverImage = null;
  }
}
