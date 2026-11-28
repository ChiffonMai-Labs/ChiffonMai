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
  final SimaiVideoFrameRate initialFrameRate;
  final Size? outputSize;
  final TextStyle? displayFont;
  final SimaiTextStyleResolver? textStyleResolver;
  final Future<void> Function()? prepareFonts;

  /// 是否将谱面内容区的 PV 圆窗抠透明以便原生层叠画视频背景。
  final bool transparentContentBackground;

  /// 是否在画面顶部绘制基础信息板块；关闭时收起多余高度。
  final bool showHeader;

  late final SimaiVideoLayout layout = outputSize == null
      ? SimaiVideoLayout.forQuality(quality, showHeader: showHeader)
      : SimaiVideoLayout.forSize(outputSize!, showHeader: showHeader);
  late final SimaiGame _game;
  ui.Image? _coverImage;
  ui.Picture? _headerPicture;
  bool _prepared = false;
  bool _disposed = false;

  SimaiVideoFrameRenderer({
    required this.controller,
    required this.metadata,
    required this.quality,
    this.initialFrameRate = SimaiVideoFrameRate.fps60,
    this.outputSize,
    this.displayFont,
    this.textStyleResolver,
    this.prepareFonts,
    this.transparentContentBackground = false,
    this.showHeader = true,
  });

  double get visualDuration => _game.totalVisualDuration;

  @visibleForTesting
  bool get debugShowCornerInfo => _game.showCornerInfo;

  @visibleForTesting
  bool get debugShowFps => _game.showFps;

  void updateShowCornerInfo(bool value) {
    if (!_prepared || _disposed) return;
    _game.showCornerInfo = value;
    _game.refreshStatusText();
  }

  void updateShowDetailedPerformanceInfo(bool value) {
    if (!_prepared || _disposed) return;
    _game.showDetailedPerformanceInfo = value;
    _game.showFps = value;
    _game.refreshStatusText();
  }

  void updateFrameRate(SimaiVideoFrameRate frameRate) {
    if (!_prepared || _disposed) return;
    final fps = frameRate.fps.toDouble();
    _game.measuredFps = fps;
    _game.frameIntervalP95Ms = 1000.0 / fps;
    _game.motionStepP95Ms = 1000.0 / fps;
    _game.refreshStatusText();
  }

  /// 热同步预览渲染器的全部可视选项（含异步等待 NOTE 图集与镜像预计算完成），
  /// 避免每次改动都销毁重建整个无头 Flame 实例引发竞态或掉同步。
  Future<void> syncVisualSettings(
    SimaiPlayerController source, {
    required SimaiVideoFrameRate frameRate,
  }) async {
    if (!_prepared || _disposed) return;
    controller
      ..speed = source.speed
      ..touchSpeed = source.touchSpeed
      ..slideDisplayTiming = source.slideDisplayTiming
      ..autoPlayMode = source.autoPlayMode
      ..autoPlaySeed = source.autoPlaySeed
      ..mirrorMode = source.mirrorMode
      ..backgroundMode = source.backgroundMode
      ..backgroundOpacity = source.backgroundOpacity
      ..rotateSlideStar = source.rotateSlideStar
      ..pinkSlideStar = source.pinkSlideStar
      ..standardBreakSlide = source.standardBreakSlide
      ..highlightExNotes = source.highlightExNotes
      ..showApproachLine = source.showApproachLine
      ..showHitEffects = source.showHitEffects
      ..hitEffectStyle = source.hitEffectStyle
      ..showJudgementDisplay = source.showJudgementDisplay
      ..judgementDisplayMode = source.judgementDisplayMode
      ..showAchievementRate = source.showAchievementRate
      ..centerDisplayMode = source.centerDisplayMode
      ..topRightDisplayMode = source.topRightDisplayMode
      ..noteStyle = source.noteStyle
      ..holdStyle = source.holdStyle
      ..customNoteSkin = source.customNoteSkin
      ..showCornerInfo = source.showCornerInfo
      ..showDetailedPerformanceInfo = source.showDetailedPerformanceInfo;

    _game
      ..ringApproachTime = source.approachTime
      ..touchApproachTime = source.touchApproachTime
      ..rotateSlideStar = source.rotateSlideStar
      ..pinkSlideStar = source.pinkSlideStar
      ..standardBreakSlide = source.standardBreakSlide
      ..highlightExNotes = source.highlightExNotes
      ..showApproachLine = source.showApproachLine
      ..showHitEffects = source.showHitEffects
      ..hitEffectStyle = source.hitEffectStyle
      ..showJudgementDisplay = source.showJudgementDisplay
      ..judgementDisplayMode = source.judgementDisplayMode
      ..showAchievementRate = source.showAchievementRate
      ..centerDisplayMode = source.centerDisplayMode
      ..topRightDisplayMode = source.topRightDisplayMode
      ..showCornerInfo = source.showCornerInfo
      ..showFps = source.showDetailedPerformanceInfo
      ..showDetailedPerformanceInfo = source.showDetailedPerformanceInfo;
    _game.setBackgroundMode(source.backgroundMode);
    _game.setBackgroundOpacity(source.backgroundOpacity);
    _game.setSlideDisplayTiming(source.slideDisplayTiming);
    _game.setAutoPlayMode(source.autoPlayMode);
    _game.setAutoPlaySeed(source.autoPlaySeed);
    updateFrameRate(frameRate);

    await _game.setNoteStyleAsync(source.noteStyle);
    if (_disposed) return;
    _game.setHoldStyle(source.holdStyle);
    await _game.setCustomNoteSkinAsync(source.customNoteSkin);
    if (_disposed) return;
    await _game.setMirrorModeAsync(source.mirrorMode);
    if (_disposed) return;
    _game.invalidateNotes(resetWindow: true);
    _game.refreshStatusText();
  }

  TextStyle _resolveTextStyle(TextStyle style) {
    if (textStyleResolver != null) return textStyleResolver!(style);
    if (displayFont == null) return style;
    return style.copyWith(
      fontFamily: displayFont!.fontFamily,
      fontFamilyFallback: displayFont!.fontFamilyFallback,
    );
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
    if (prepareFonts != null) {
      await prepareFonts!();
      checkCancelled();
    }
    if (showHeader) {
      _coverImage = await _resolveImage(
        metadata.coverImageProvider,
        layout.coverRect.size,
      );
      checkCancelled();
      _headerPicture = _buildHeaderPicture();
    }

    _game = SimaiGame(
      chart: controller.chart,
      headlessExport: true,
      headlessExportCancelled: isCancelled,
      displayFont: displayFont,
      textStyleResolver: textStyleResolver,
      isPlaying: false,
      ringApproachTime: controller.approachTime,
      touchApproachTime: controller.touchApproachTime,
      slideDisplayTiming: controller.slideDisplayTiming,
      autoPlayMode: controller.autoPlayMode,
      autoPlaySeed: controller.autoPlaySeed,
      playbackRate: 1.0,
      musicVolume: controller.musicVolume,
      hitSoundOffset: controller.hitSoundOffsetMs / 1000.0,
      hitSoundEnabled: false,
      backgroundMode: controller.backgroundMode,
      backgroundOpacity: controller.backgroundOpacity,
      mirrorMode: controller.mirrorMode,
      rotateSlideStar: controller.rotateSlideStar,
      pinkSlideStar: controller.pinkSlideStar,
      standardBreakSlide: controller.standardBreakSlide,
      highlightExNotes: controller.highlightExNotes,
      showApproachLine: controller.showApproachLine,
      showHitEffects: controller.showHitEffects,
      hitEffectStyle: controller.hitEffectStyle,
      showJudgementDisplay: controller.showJudgementDisplay,
      judgementDisplayMode: controller.judgementDisplayMode,
      showAchievementRate: controller.showAchievementRate,
      centerDisplayMode: controller.centerDisplayMode,
      topRightDisplayMode: controller.topRightDisplayMode,
      noteStyle: controller.noteStyle,
      holdStyle: controller.holdStyle,
      customNoteSkin: controller.customNoteSkin,
      showCornerInfo: controller.showCornerInfo,
      showFps: controller.showDetailedPerformanceInfo,
      showDetailedPerformanceInfo: controller.showDetailedPerformanceInfo,
      hasVideoBackground: transparentContentBackground,
      initialChartTime: 0,
      offset: controller.effectiveMusicOffsetSeconds,
      backgroundImageProvider: controller.backgroundImageProvider,
    );
    await _game.prepareHeadlessExport(
      Vector2.all(layout.contentRect.width),
      initialStepDelta: 1.0 / initialFrameRate.fps,
    );
    checkCancelled();
    _prepared = true;
  }

  Future<Uint8List> renderRgbaFrame(
    double chartTime, {
    required bool resetWindow,
    double stepDelta = 1 / 60,
  }) async {
    final image = await renderImageFrame(
      chartTime,
      resetWindow: resetWindow,
      stepDelta: stepDelta,
    );
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
    double stepDelta = 1 / 60,
  }) async {
    if (!_prepared || _disposed) {
      throw StateError('Renderer is not ready.');
    }
    _game.updateExportTime(
      chartTime,
      resetWindow: resetWindow,
      dt: stepDelta,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xFF08080B), BlendMode.src);
    if (_headerPicture != null) {
      canvas.drawPicture(_headerPicture!);
    }

    final contentRect = layout.contentRect;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(contentRect, Radius.circular(28 * layout.scale)),
    );
    canvas.drawRect(contentRect, Paint()..color = Colors.black);
    if (transparentContentBackground) {
      // 抠出圆形透明窗并叠画背景压暗遮罩，使原生底层的 PV 视频透出。
      final circleRect = layout.pvCircleRect;
      canvas.save();
      canvas.clipPath(Path()..addOval(circleRect));
      canvas.drawRect(circleRect, Paint()..blendMode = BlendMode.clear);
      final dimAlpha = (1.0 - controller.backgroundOpacity.clamp(0.0, 1.0))
          .clamp(0.0, 1.0);
      if (dimAlpha > 0.0) {
        canvas.drawRect(
          circleRect,
          Paint()..color = Colors.black.withValues(alpha: dimAlpha),
        );
      }
      canvas.restore();
    }
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
      Offset(textLeft, header.top + 32 * scale),
      textWidth,
      maxFontSize: 46 * scale,
      minFontSize: 30 * scale,
      color: foreground,
      fontWeight: FontWeight.w700,
    );
    _paintSingleLine(
      canvas,
      metadata.artist,
      Offset(textLeft, header.top + 102 * scale),
      textWidth,
      maxFontSize: 30 * scale,
      minFontSize: 21 * scale,
      color: foreground.withValues(alpha: 0.88),
      fontWeight: FontWeight.w500,
    );

    _paintCenteredSingleLine(
      canvas,
      metadata.difficulty.label,
      Rect.fromLTWH(792 * scale, header.top + 36 * scale, 208 * scale, 42 * scale),
      maxFontSize: 31 * scale,
      minFontSize: 22 * scale,
      color: foreground,
      fontWeight: FontWeight.w700,
    );
    _paintCenteredSingleLine(
      canvas,
      metadata.level,
      Rect.fromLTWH(792 * scale, header.top + 81 * scale, 208 * scale, 78 * scale),
      maxFontSize: 58 * scale,
      minFontSize: 38 * scale,
      color: foreground,
      fontWeight: FontWeight.w800,
    );
    return recorder.endRecording();
  }

  void _paintSingleLine(
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

  void _paintCenteredSingleLine(
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
      Offset(
        rect.left + (rect.width - painter.width) / 2,
        rect.top + (rect.height - painter.height) / 2,
      ),
    );
    painter.dispose();
  }

  TextPainter _createFittedTextPainter(
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
      final style = _resolveTextStyle(
        TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.15,
        ),
      );
      painter = TextPainter(
        text: TextSpan(text: text, style: style),
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
