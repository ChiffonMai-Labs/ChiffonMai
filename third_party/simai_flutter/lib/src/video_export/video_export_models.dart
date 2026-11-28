import 'dart:async';

import 'package:flutter/material.dart';

import '../gameplay/gameplay_models.dart';
import '../simai_file.dart';
import '../ui/auto_play_mode.dart';
import '../ui/center_display_mode.dart';
import '../ui/custom_note_skin.dart';
import '../ui/hit_effect_style.dart';
import '../ui/note_style.dart';
import '../ui/simai_player.dart';

/// 视频导出页准备 PV 时的实时进度回调（progress 为 null 表示不确定进度，如探测/连接阶段）。
typedef SimaiPvDownloadProgressCallback =
    void Function({double? progress, String? status});

/// 视频导出页下载 PV 的委托：返回本地文件路径；无 PV、取消或失败时返回 null。
typedef SimaiVideoExportPvDownloader =
    Future<String?> Function(
      BuildContext context, {
      SimaiPvDownloadProgressCallback? onProgress,
    });

enum SimaiChartDifficulty {
  basic,
  advanced,
  expert,
  master,
  reMaster,
  utage;

  int get simaiIndex => switch (this) {
    SimaiChartDifficulty.basic => 2,
    SimaiChartDifficulty.advanced => 3,
    SimaiChartDifficulty.expert => 4,
    SimaiChartDifficulty.master => 5,
    SimaiChartDifficulty.reMaster => 6,
    SimaiChartDifficulty.utage => 7,
  };

  String get label => switch (this) {
    SimaiChartDifficulty.basic => 'BASIC',
    SimaiChartDifficulty.advanced => 'ADVANCED',
    SimaiChartDifficulty.expert => 'EXPERT',
    SimaiChartDifficulty.master => 'MASTER',
    SimaiChartDifficulty.reMaster => 'Re:MASTER',
    SimaiChartDifficulty.utage => 'UTAGE',
  };

  Color get cardColor => switch (this) {
    SimaiChartDifficulty.basic => const Color(0xFF4CAF6A),
    SimaiChartDifficulty.advanced => const Color(0xFFF4C542),
    SimaiChartDifficulty.expert => const Color(0xFFE84C4F),
    SimaiChartDifficulty.master => const Color(0xFF8F55C7),
    SimaiChartDifficulty.reMaster => const Color(0xFFD7B4F3),
    SimaiChartDifficulty.utage => const Color(0xFFEA4C89),
  };

  Color get foregroundColor => switch (this) {
    SimaiChartDifficulty.advanced => const Color(0xFF201A00),
    SimaiChartDifficulty.reMaster => const Color(0xFF2B1838),
    _ => Colors.white,
  };
}

enum SimaiVideoFrameRate {
  fps60,
  fps120;

  int get fps => switch (this) {
    SimaiVideoFrameRate.fps60 => 60,
    SimaiVideoFrameRate.fps120 => 120,
  };

  String get label => '${fps}fps';
}

enum SimaiVideoQuality {
  hd720,
  fullHd1080;

  int get width => switch (this) {
    SimaiVideoQuality.hd720 => 720,
    SimaiVideoQuality.fullHd1080 => 1080,
  };

  int get height => switch (this) {
    SimaiVideoQuality.hd720 => 864,
    SimaiVideoQuality.fullHd1080 => 1296,
  };

  int heightFor({required bool showHeader}) => showHeader ? height : width;

  int get videoBitrate => videoBitrateFor(SimaiVideoFrameRate.fps60);

  int videoBitrateFor(SimaiVideoFrameRate frameRate) => switch ((
    this,
    frameRate,
  )) {
    (SimaiVideoQuality.hd720, SimaiVideoFrameRate.fps60) => 4 * 1000 * 1000,
    (SimaiVideoQuality.hd720, SimaiVideoFrameRate.fps120) =>
      6500 * 1000,
    (SimaiVideoQuality.fullHd1080, SimaiVideoFrameRate.fps60) =>
      8 * 1000 * 1000,
    (SimaiVideoQuality.fullHd1080, SimaiVideoFrameRate.fps120) =>
      12 * 1000 * 1000,
  };

  String get label => labelFor(showHeader: true);

  String labelFor({required bool showHeader}) =>
      '$width × ${heightFor(showHeader: showHeader)}';
}

enum SimaiVideoAudioMode { musicAndHitSounds, musicOnly, silent }

const int simaiVideoAudioBitrate = 192000;

int estimateSimaiVideoFileSizeBytes({
  required SimaiVideoQuality quality,
  SimaiVideoFrameRate frameRate = SimaiVideoFrameRate.fps60,
  required Duration duration,
  required bool includeAudio,
}) {
  final durationSeconds = duration.inMicroseconds / 1000000.0;
  if (!durationSeconds.isFinite || durationSeconds <= 0) return 0;
  final bitsPerSecond =
      quality.videoBitrateFor(frameRate) +
      (includeAudio ? simaiVideoAudioBitrate : 0);
  // MP4 metadata and encoder rate-control variance are represented by a small
  // overhead so the UI estimate is less likely to under-report the final file.
  return (bitsPerSecond * durationSeconds / 8 * 1.03).ceil();
}

enum SimaiVideoExportPhase {
  preparing,
  rendering,
  mixingAudio,
  muxing,
  completed,
  cancelled,
  failed,
}

class SimaiVideoMetadata {
  final ImageProvider coverImageProvider;
  final String title;
  final String artist;
  final SimaiChartDifficulty difficulty;
  final String level;

  const SimaiVideoMetadata({
    required this.coverImageProvider,
    required this.title,
    required this.artist,
    required this.difficulty,
    required this.level,
  });

  factory SimaiVideoMetadata.fromSimaiFile(
    SimaiFile file, {
    required ImageProvider coverImageProvider,
    required SimaiChartDifficulty difficulty,
    String? inoteKey,
    String? fallbackTitle,
    String? fallbackArtist,
    String? fallbackLevel,
  }) {
    final rawTitle = file.getValue('title')?.trim();
    final title = (rawTitle != null && rawTitle.isNotEmpty)
        ? rawTitle
        : fallbackTitle?.trim();
    final rawArtist = file.getValue('artist')?.trim();
    final artist = (rawArtist != null && rawArtist.isNotEmpty)
        ? rawArtist
        : fallbackArtist?.trim();
    final rawInoteLevel = inoteKey != null && inoteKey.trim().isNotEmpty
        ? file.getValue('lv_${inoteKey.trim()}')?.trim()
        : null;
    final rawDiffLevel = file.getValue('lv_${difficulty.simaiIndex}')?.trim();
    final level = (rawInoteLevel != null && rawInoteLevel.isNotEmpty)
        ? rawInoteLevel
        : (rawDiffLevel != null && rawDiffLevel.isNotEmpty)
        ? rawDiffLevel
        : fallbackLevel?.trim();
    if (title == null || title.isEmpty) {
      throw const FormatException('Missing required Simai metadata: title');
    }
    if (artist == null) {
      throw const FormatException('Missing required Simai metadata: artist');
    }
    if (level == null || level.isEmpty) {
      throw FormatException(
        'Missing required Simai metadata: lv_${inoteKey ?? difficulty.simaiIndex}',
      );
    }
    return SimaiVideoMetadata(
      coverImageProvider: coverImageProvider,
      title: title,
      artist: artist,
      difficulty: difficulty,
      level: level,
    );
  }
}

class SimaiVideoExportOptions {
  final SimaiVideoQuality quality;
  final SimaiVideoFrameRate frameRate;
  final SimaiVideoAudioMode audioMode;

  /// Overrides the player controller's hit-sound setting for this export.
  ///
  /// A null value inherits the controller snapshot. This setting only applies
  /// when [audioMode] allows hit sounds.
  final bool? hitSoundEnabled;

  /// Overrides the player controller's corner-HUD setting for this export.
  ///
  /// A null value inherits the controller snapshot.
  final bool? showCornerInfo;

  /// 覆盖导出时的详细性能信息开关；为 null 时沿用控制器快照。
  final bool? showDetailedPerformanceInfo;
  final String? outputPath;

  /// 用作圆窗背景的本地 PV 视频文件路径；仅单次导出传递，不持久化保存。
  final String? pvVideoPath;

  /// 导出完成后是否直接写入系统相册并清理临时工作文件，避免落盘缓存目录。
  final bool saveToGallery;

  /// 写入系统相册时的建议文件名（如 `曲名_MASTER.mp4`）。
  final String? displayName;

  /// 是否显示视频上方的基础信息板块；关闭时收起对应高度为 1:1 正方形画布。
  final bool showHeader;

  const SimaiVideoExportOptions({
    this.quality = SimaiVideoQuality.fullHd1080,
    this.frameRate = SimaiVideoFrameRate.fps60,
    this.audioMode = SimaiVideoAudioMode.musicAndHitSounds,
    this.hitSoundEnabled,
    this.showCornerInfo,
    this.showDetailedPerformanceInfo,
    this.outputPath,
    this.pvVideoPath,
    this.saveToGallery = true,
    this.displayName,
    this.showHeader = false,
  });

  SimaiVideoExportOptions copyWith({
    SimaiVideoQuality? quality,
    SimaiVideoFrameRate? frameRate,
    SimaiVideoAudioMode? audioMode,
    bool? hitSoundEnabled,
    bool inheritHitSoundEnabled = false,
    bool? showCornerInfo,
    bool inheritShowCornerInfo = false,
    bool? showDetailedPerformanceInfo,
    bool inheritShowDetailedPerformanceInfo = false,
    String? outputPath,
    bool clearOutputPath = false,
    String? pvVideoPath,
    bool clearPvVideoPath = false,
    bool? saveToGallery,
    String? displayName,
    bool? showHeader,
  }) {
    return SimaiVideoExportOptions(
      quality: quality ?? this.quality,
      frameRate: frameRate ?? this.frameRate,
      audioMode: audioMode ?? this.audioMode,
      hitSoundEnabled: inheritHitSoundEnabled
          ? null
          : hitSoundEnabled ?? this.hitSoundEnabled,
      showCornerInfo: inheritShowCornerInfo
          ? null
          : showCornerInfo ?? this.showCornerInfo,
      showDetailedPerformanceInfo: inheritShowDetailedPerformanceInfo
          ? null
          : showDetailedPerformanceInfo ?? this.showDetailedPerformanceInfo,
      outputPath: clearOutputPath ? null : outputPath ?? this.outputPath,
      pvVideoPath: clearPvVideoPath ? null : pvVideoPath ?? this.pvVideoPath,
      saveToGallery: saveToGallery ?? this.saveToGallery,
      displayName: displayName ?? this.displayName,
      showHeader: showHeader ?? this.showHeader,
    );
  }
}

/// 视频导出页面的记忆化设置快照，涵盖规格、帧率、显示与音频全部选项。
@immutable
class SimaiVideoExportSettings {
  final SimaiVideoQuality quality;
  final SimaiVideoFrameRate frameRate;
  final bool showHeader;
  final bool includeMusic;
  final SimaiMirrorMode mirrorMode;
  final SimaiBackgroundMode backgroundMode;
  final double speed;
  final double touchSpeed;
  final double slideDisplayTiming;
  final SimaiAutoPlayMode autoPlayMode;
  final bool rotateSlideStar;
  final bool pinkSlideStar;
  final bool standardBreakSlide;
  final bool showApproachLine;
  final bool showHitEffects;
  final SimaiHitEffectStyle hitEffectStyle;
  final bool showJudgementDisplay;
  final SimaiJudgementDisplayMode judgementDisplayMode;
  final SimaiCenterDisplayMode centerDisplayMode;
  final SimaiCenterDisplayMode topRightDisplayMode;
  final SimaiNoteStyle noteStyle;
  final SimaiNoteStyle holdStyle;
  final SimaiCustomNoteSkin customNoteSkin;
  final String? customHitSoundPath;
  final bool showAchievementRate;
  final bool highlightExNotes;
  final bool showCornerInfo;
  final bool showDetailedPerformanceInfo;
  final bool hitSoundEnabled;
  final double musicVolume;
  final double hitSoundVolume;
  final int musicOffsetMs;
  final int hitSoundOffsetMs;

  const SimaiVideoExportSettings({
    this.quality = SimaiVideoQuality.fullHd1080,
    this.frameRate = SimaiVideoFrameRate.fps60,
    this.showHeader = false,
    this.includeMusic = true,
    this.mirrorMode = SimaiMirrorMode.none,
    this.backgroundMode = SimaiBackgroundMode.judgeLine,
    this.speed = 8.0,
    this.touchSpeed = 8.0,
    this.slideDisplayTiming = 0.0,
    this.autoPlayMode = SimaiAutoPlayMode.allCriticalPerfect,
    this.rotateSlideStar = true,
    this.pinkSlideStar = false,
    this.standardBreakSlide = false,
    this.showApproachLine = true,
    this.showHitEffects = true,
    this.hitEffectStyle = SimaiHitEffectStyle.ring,
    this.showJudgementDisplay = false,
    this.judgementDisplayMode = SimaiJudgementDisplayMode.twoB,
    this.centerDisplayMode = SimaiCenterDisplayMode.achievementAdd,
    this.topRightDisplayMode = SimaiCenterDisplayMode.combo,
    this.noteStyle = SimaiNoteStyle.arcade,
    this.holdStyle = SimaiNoteStyle.arcade,
    this.customNoteSkin = SimaiCustomNoteSkin.empty,
    this.customHitSoundPath,
    this.showAchievementRate = true,
    this.highlightExNotes = true,
    this.showCornerInfo = true,
    this.showDetailedPerformanceInfo = false,
    this.hitSoundEnabled = true,
    this.musicVolume = 0.5,
    this.hitSoundVolume = 2.0,
    this.musicOffsetMs = 0,
    this.hitSoundOffsetMs = 0,
  });

  factory SimaiVideoExportSettings.capture(
    SimaiPlayerController controller, {
    required SimaiVideoQuality quality,
    SimaiVideoFrameRate frameRate = SimaiVideoFrameRate.fps60,
    bool showHeader = false,
    required bool includeMusic,
  }) {
    return SimaiVideoExportSettings(
      quality: quality,
      frameRate: frameRate,
      showHeader: showHeader,
      includeMusic: includeMusic,
      mirrorMode: controller.mirrorMode,
      backgroundMode: controller.backgroundMode,
      speed: controller.speed,
      touchSpeed: controller.touchSpeed,
      slideDisplayTiming: controller.slideDisplayTiming,
      autoPlayMode: controller.autoPlayMode,
      rotateSlideStar: controller.rotateSlideStar,
      pinkSlideStar: controller.pinkSlideStar,
      standardBreakSlide: controller.standardBreakSlide,
      showApproachLine: controller.showApproachLine,
      showHitEffects: controller.showHitEffects,
      hitEffectStyle: controller.hitEffectStyle,
      showJudgementDisplay: controller.showJudgementDisplay,
      judgementDisplayMode: controller.judgementDisplayMode,
      centerDisplayMode: controller.centerDisplayMode,
      topRightDisplayMode: controller.topRightDisplayMode,
      noteStyle: controller.noteStyle,
      holdStyle: controller.holdStyle,
      customNoteSkin: controller.customNoteSkin,
      customHitSoundPath: controller.customHitSoundPath,
      showAchievementRate: controller.showAchievementRate,
      highlightExNotes: controller.highlightExNotes,
      showCornerInfo: controller.showCornerInfo,
      showDetailedPerformanceInfo: controller.showDetailedPerformanceInfo,
      hitSoundEnabled: controller.hitSoundEnabled,
      musicVolume: controller.musicVolume,
      hitSoundVolume: controller.hitSoundVolume,
      musicOffsetMs: controller.musicOffsetMs,
      hitSoundOffsetMs: controller.hitSoundOffsetMs,
    );
  }

  void applyTo(SimaiPlayerController controller) {
    controller
      ..mirrorMode = mirrorMode
      ..backgroundMode = backgroundMode
      ..speed = speed
      ..touchSpeed = touchSpeed
      ..slideDisplayTiming = slideDisplayTiming
      ..autoPlayMode = autoPlayMode
      ..rotateSlideStar = rotateSlideStar
      ..pinkSlideStar = pinkSlideStar
      ..standardBreakSlide = standardBreakSlide
      ..showApproachLine = showApproachLine
      ..showHitEffects = showHitEffects
      ..hitEffectStyle = hitEffectStyle
      ..showJudgementDisplay = showJudgementDisplay
      ..judgementDisplayMode = judgementDisplayMode
      ..centerDisplayMode = centerDisplayMode
      ..topRightDisplayMode = topRightDisplayMode
      ..noteStyle = noteStyle
      ..holdStyle = holdStyle
      ..customNoteSkin = customNoteSkin
      ..customHitSoundPath = customHitSoundPath
      ..showAchievementRate = showAchievementRate
      ..highlightExNotes = highlightExNotes
      ..showCornerInfo = showCornerInfo
      ..showDetailedPerformanceInfo = showDetailedPerformanceInfo
      ..hitSoundEnabled = hitSoundEnabled
      ..musicVolume = musicVolume
      ..hitSoundVolume = hitSoundVolume
      ..musicOffsetMs = musicOffsetMs
      ..hitSoundOffsetMs = hitSoundOffsetMs;
  }
}

class SimaiVideoExportProgress {
  final SimaiVideoExportPhase phase;
  final int completedFrames;
  final int totalFrames;
  final double fraction;
  final Duration? estimatedRemaining;
  final int? estimatedFileSizeBytes;

  const SimaiVideoExportProgress({
    required this.phase,
    required this.completedFrames,
    required this.totalFrames,
    required this.fraction,
    this.estimatedRemaining,
    this.estimatedFileSizeBytes,
  });

  const SimaiVideoExportProgress.preparing({this.estimatedFileSizeBytes})
    : phase = SimaiVideoExportPhase.preparing,
      completedFrames = 0,
      totalFrames = 0,
      fraction = 0,
      estimatedRemaining = null;

  double get overallFraction => switch (phase) {
    SimaiVideoExportPhase.preparing => 0.02,
    SimaiVideoExportPhase.rendering => 0.04 + fraction.clamp(0.0, 1.0) * 0.9,
    SimaiVideoExportPhase.mixingAudio => 0.95,
    SimaiVideoExportPhase.muxing => 0.98,
    SimaiVideoExportPhase.completed => 1.0,
    SimaiVideoExportPhase.cancelled ||
    SimaiVideoExportPhase.failed => fraction.clamp(0.0, 1.0),
  };
}

class SimaiVideoExportResult {
  /// Absolute path or gallery content URI of the newly exported MP4.
  final String path;
  final Duration duration;
  final int width;
  final int height;
  final int fps;
  final int frameCount;
  final int fileSizeBytes;
  final bool savedToGallery;
  final String? galleryUri;

  const SimaiVideoExportResult({
    required this.path,
    required this.duration,
    required this.width,
    required this.height,
    this.fps = 60,
    required this.frameCount,
    required this.fileSizeBytes,
    this.savedToGallery = false,
    this.galleryUri,
  });
}

class SimaiVideoExportException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const SimaiVideoExportException(this.code, this.message, [this.cause]);

  @override
  String toString() => 'SimaiVideoExportException($code): $message';
}

class SimaiVideoExportCancelledException extends SimaiVideoExportException {
  const SimaiVideoExportCancelledException()
    : super('cancelled', 'Video export was cancelled.');
}

class SimaiVideoExportTask {
  final SimaiVideoMetadata metadata;
  final SimaiVideoExportOptions options;
  final DateTime startedAt;
  final Future<void> Function() _cancelCallback;
  final StreamController<SimaiVideoExportProgress> _progressController =
      StreamController<SimaiVideoExportProgress>.broadcast(sync: true);
  final Completer<SimaiVideoExportResult> _resultCompleter =
      Completer<SimaiVideoExportResult>();
  late SimaiVideoExportProgress _currentProgress;
  SimaiVideoExportResult? _completedResult;
  Object? _terminalError;
  Future<void>? _cancelFuture;
  bool _cancelRequested = false;
  bool _progressClosed = false;

  SimaiVideoExportTask.internal({
    required this.metadata,
    required this.options,
    required int estimatedFileSizeBytes,
    required Future<void> Function() cancelCallback,
  }) : startedAt = DateTime.now(),
       _cancelCallback = cancelCallback {
    _currentProgress = SimaiVideoExportProgress.preparing(
      estimatedFileSizeBytes: estimatedFileSizeBytes,
    );
  }

  Stream<SimaiVideoExportProgress> get progress => _progressController.stream;

  SimaiVideoExportProgress get currentProgress => _currentProgress;

  Future<SimaiVideoExportResult> get result => _resultCompleter.future;

  SimaiVideoExportResult? get completedResult => _completedResult;

  Object? get terminalError => _terminalError;

  bool get isCompleted => _resultCompleter.isCompleted;

  bool get isRunning => !isCompleted;

  bool get isCancelling => _cancelRequested && !isCompleted;

  int? get estimatedFileSizeBytes => _currentProgress.estimatedFileSizeBytes;

  Future<void> cancel() {
    if (isCompleted) return Future<void>.value();
    _cancelRequested = true;
    return _cancelFuture ??= _cancelCallback();
  }

  void updateProgressForExport(SimaiVideoExportProgress progress) {
    _currentProgress = progress;
    if (!_progressClosed) _progressController.add(progress);
  }

  void completeResultForExport(SimaiVideoExportResult result) {
    if (_resultCompleter.isCompleted) return;
    _completedResult = result;
    _resultCompleter.complete(result);
  }

  void completeErrorForExport(Object error, StackTrace stackTrace) {
    if (_resultCompleter.isCompleted) return;
    _terminalError = error;
    _resultCompleter.completeError(error, stackTrace);
  }

  Future<void> closeProgressForExport() async {
    if (_progressClosed) return;
    _progressClosed = true;
    await _progressController.close();
  }
}

class SimaiVideoLayout {
  static const double designWidth = 1080.0;
  static const double designHeight = 1296.0;
  static const double designCompactHeight = 1080.0;
  static const double aspectRatio = designWidth / designHeight;

  static double designHeightFor({required bool showHeader}) =>
      showHeader ? designHeight : designCompactHeight;

  static double aspectRatioFor({required bool showHeader}) =>
      designWidth / designHeightFor(showHeader: showHeader);

  final Size videoSize;
  final Rect headerRect;
  final Rect coverRect;
  final Rect contentRect;
  final double scale;
  final bool showHeader;

  /// PV 视频在内容区内的圆形裁切区域（与判定环 1.05 倍外缘对齐）。
  Rect get pvCircleRect =>
      Rect.fromCircle(center: contentRect.center, radius: contentRect.width * 0.42);

  const SimaiVideoLayout({
    required this.videoSize,
    required this.headerRect,
    required this.coverRect,
    required this.contentRect,
    required this.scale,
    this.showHeader = true,
  });

  factory SimaiVideoLayout.forQuality(
    SimaiVideoQuality quality, {
    bool showHeader = true,
  }) {
    return SimaiVideoLayout.forSize(
      Size(
        quality.width.toDouble(),
        quality.heightFor(showHeader: showHeader).toDouble(),
      ),
      showHeader: showHeader,
    );
  }

  factory SimaiVideoLayout.forSize(
    Size videoSize, {
    bool showHeader = true,
  }) {
    if (videoSize.width <= 0 || videoSize.height <= 0) {
      throw ArgumentError.value(videoSize, 'videoSize', 'Must be positive.');
    }
    final targetDesignHeight = designHeightFor(showHeader: showHeader);
    final expectedHeight = videoSize.width * targetDesignHeight / designWidth;
    if ((videoSize.height - expectedHeight).abs() > 0.01) {
      throw ArgumentError.value(
        videoSize,
        'videoSize',
        showHeader
            ? 'Video export layout requires a 5:6 portrait size.'
            : 'Compact video export layout requires a 1:1 square size.',
      );
    }
    final scale = videoSize.width / designWidth;
    Rect scaledRect(double left, double top, double width, double height) {
      return Rect.fromLTWH(
        left * scale,
        top * scale,
        width * scale,
        height * scale,
      );
    }

    return SimaiVideoLayout(
      videoSize: videoSize,
      headerRect: showHeader ? scaledRect(48, 40, 984, 196) : Rect.zero,
      coverRect: showHeader ? scaledRect(72, 64, 148, 148) : Rect.zero,
      contentRect: showHeader
          ? scaledRect(48, 272, 984, 984)
          : scaledRect(48, 48, 984, 984),
      scale: scale,
      showHeader: showHeader,
    );
  }
}
