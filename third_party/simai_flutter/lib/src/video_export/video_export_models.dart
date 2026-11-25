import 'dart:async';

import 'package:flutter/material.dart';

import '../simai_file.dart';
import '../ui/center_display_mode.dart';
import '../ui/simai_player.dart';

enum SimaiChartDifficulty {
  basic,
  advanced,
  expert,
  master,
  reMaster;

  int get simaiIndex => switch (this) {
    SimaiChartDifficulty.basic => 2,
    SimaiChartDifficulty.advanced => 3,
    SimaiChartDifficulty.expert => 4,
    SimaiChartDifficulty.master => 5,
    SimaiChartDifficulty.reMaster => 6,
  };

  String get label => switch (this) {
    SimaiChartDifficulty.basic => 'BASIC',
    SimaiChartDifficulty.advanced => 'ADVANCED',
    SimaiChartDifficulty.expert => 'EXPERT',
    SimaiChartDifficulty.master => 'MASTER',
    SimaiChartDifficulty.reMaster => 'Re:MASTER',
  };

  Color get cardColor => switch (this) {
    SimaiChartDifficulty.basic => const Color(0xFF4CAF6A),
    SimaiChartDifficulty.advanced => const Color(0xFFF4C542),
    SimaiChartDifficulty.expert => const Color(0xFFE84C4F),
    SimaiChartDifficulty.master => const Color(0xFF8F55C7),
    SimaiChartDifficulty.reMaster => const Color(0xFFD7B4F3),
  };

  Color get foregroundColor => switch (this) {
    SimaiChartDifficulty.advanced => const Color(0xFF201A00),
    SimaiChartDifficulty.reMaster => const Color(0xFF2B1838),
    _ => Colors.white,
  };
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

  int get videoBitrate => switch (this) {
    SimaiVideoQuality.hd720 => 4 * 1000 * 1000,
    SimaiVideoQuality.fullHd1080 => 8 * 1000 * 1000,
  };

  String get label => switch (this) {
    SimaiVideoQuality.hd720 => '720 × 864',
    SimaiVideoQuality.fullHd1080 => '1080 × 1296',
  };
}

enum SimaiVideoAudioMode { musicAndHitSounds, musicOnly, silent }

const int simaiVideoAudioBitrate = 192000;

int estimateSimaiVideoFileSizeBytes({
  required SimaiVideoQuality quality,
  required Duration duration,
  required bool includeAudio,
}) {
  final durationSeconds = duration.inMicroseconds / 1000000.0;
  if (!durationSeconds.isFinite || durationSeconds <= 0) return 0;
  final bitsPerSecond =
      quality.videoBitrate + (includeAudio ? simaiVideoAudioBitrate : 0);
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
  }) {
    final title = file.getValue('title')?.trim();
    final artist = file.getValue('artist')?.trim();
    final level = file.getValue('lv_${difficulty.simaiIndex}')?.trim();
    if (title == null || title.isEmpty) {
      throw const FormatException('Missing required Simai metadata: title');
    }
    if (artist == null || artist.isEmpty) {
      throw const FormatException('Missing required Simai metadata: artist');
    }
    if (level == null || level.isEmpty) {
      throw FormatException(
        'Missing required Simai metadata: lv_${difficulty.simaiIndex}',
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

  const SimaiVideoExportOptions({
    this.quality = SimaiVideoQuality.fullHd1080,
    this.audioMode = SimaiVideoAudioMode.musicAndHitSounds,
    this.hitSoundEnabled,
    this.showCornerInfo,
    this.showDetailedPerformanceInfo,
    this.outputPath,
  });

  SimaiVideoExportOptions copyWith({
    SimaiVideoQuality? quality,
    SimaiVideoAudioMode? audioMode,
    bool? hitSoundEnabled,
    bool inheritHitSoundEnabled = false,
    bool? showCornerInfo,
    bool inheritShowCornerInfo = false,
    bool? showDetailedPerformanceInfo,
    bool inheritShowDetailedPerformanceInfo = false,
    String? outputPath,
    bool clearOutputPath = false,
  }) {
    return SimaiVideoExportOptions(
      quality: quality ?? this.quality,
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
    );
  }
}

/// 视频导出页面的记忆化设置快照，涵盖规格、显示与音频全部选项。
@immutable
class SimaiVideoExportSettings {
  final SimaiVideoQuality quality;
  final bool includeMusic;
  final SimaiMirrorMode mirrorMode;
  final SimaiBackgroundMode backgroundMode;
  final double speed;
  final bool rotateSlideStar;
  final bool pinkSlideStar;
  final bool standardBreakSlide;
  final bool showApproachLine;
  final bool showHitEffects;
  final SimaiCenterDisplayMode centerDisplayMode;
  final bool showAchievementRate;
  final bool highlightExNotes;
  final bool showCornerInfo;
  final bool showDetailedPerformanceInfo;
  final bool hitSoundEnabled;
  final double musicVolume;
  final int musicOffsetMs;
  final int hitSoundOffsetMs;

  const SimaiVideoExportSettings({
    this.quality = SimaiVideoQuality.fullHd1080,
    this.includeMusic = true,
    this.mirrorMode = SimaiMirrorMode.none,
    this.backgroundMode = SimaiBackgroundMode.judgeLine,
    this.speed = 8.0,
    this.rotateSlideStar = true,
    this.pinkSlideStar = false,
    this.standardBreakSlide = false,
    this.showApproachLine = true,
    this.showHitEffects = true,
    this.centerDisplayMode = SimaiCenterDisplayMode.achievement,
    this.showAchievementRate = true,
    this.highlightExNotes = true,
    this.showCornerInfo = true,
    this.showDetailedPerformanceInfo = false,
    this.hitSoundEnabled = false,
    this.musicVolume = 0.8,
    this.musicOffsetMs = 0,
    this.hitSoundOffsetMs = 0,
  });

  factory SimaiVideoExportSettings.capture(
    SimaiPlayerController controller, {
    required SimaiVideoQuality quality,
    required bool includeMusic,
  }) {
    return SimaiVideoExportSettings(
      quality: quality,
      includeMusic: includeMusic,
      mirrorMode: controller.mirrorMode,
      backgroundMode: controller.backgroundMode,
      speed: controller.speed,
      rotateSlideStar: controller.rotateSlideStar,
      pinkSlideStar: controller.pinkSlideStar,
      standardBreakSlide: controller.standardBreakSlide,
      showApproachLine: controller.showApproachLine,
      showHitEffects: controller.showHitEffects,
      centerDisplayMode: controller.centerDisplayMode,
      showAchievementRate: controller.showAchievementRate,
      highlightExNotes: controller.highlightExNotes,
      showCornerInfo: controller.showCornerInfo,
      showDetailedPerformanceInfo: controller.showDetailedPerformanceInfo,
      hitSoundEnabled: controller.hitSoundEnabled,
      musicVolume: controller.musicVolume,
      musicOffsetMs: controller.musicOffsetMs,
      hitSoundOffsetMs: controller.hitSoundOffsetMs,
    );
  }

  void applyTo(SimaiPlayerController controller) {
    controller
      ..mirrorMode = mirrorMode
      ..backgroundMode = backgroundMode
      ..speed = speed
      ..rotateSlideStar = rotateSlideStar
      ..pinkSlideStar = pinkSlideStar
      ..standardBreakSlide = standardBreakSlide
      ..showApproachLine = showApproachLine
      ..showHitEffects = showHitEffects
      ..centerDisplayMode = centerDisplayMode
      ..showAchievementRate = showAchievementRate
      ..highlightExNotes = highlightExNotes
      ..showCornerInfo = showCornerInfo
      ..showDetailedPerformanceInfo = showDetailedPerformanceInfo
      ..hitSoundEnabled = hitSoundEnabled
      ..musicVolume = musicVolume
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
  /// Absolute path of the newly exported MP4.
  ///
  /// Calling `SimaiVideoExporter.saveToGallery` or
  /// `SimaiVideoExporter.share` deletes this file after the requested action
  /// succeeds, so the path must not be reused afterwards.
  final String path;
  final Duration duration;
  final int width;
  final int height;
  final int frameCount;
  final int fileSizeBytes;

  const SimaiVideoExportResult({
    required this.path,
    required this.duration,
    required this.width,
    required this.height,
    required this.frameCount,
    required this.fileSizeBytes,
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
  static const double aspectRatio = designWidth / designHeight;

  final Size videoSize;
  final Rect headerRect;
  final Rect coverRect;
  final Rect contentRect;
  final double scale;

  const SimaiVideoLayout({
    required this.videoSize,
    required this.headerRect,
    required this.coverRect,
    required this.contentRect,
    required this.scale,
  });

  factory SimaiVideoLayout.forQuality(SimaiVideoQuality quality) {
    return SimaiVideoLayout.forSize(
      Size(quality.width.toDouble(), quality.height.toDouble()),
    );
  }

  factory SimaiVideoLayout.forSize(Size videoSize) {
    if (videoSize.width <= 0 || videoSize.height <= 0) {
      throw ArgumentError.value(videoSize, 'videoSize', 'Must be positive.');
    }
    final expectedHeight = videoSize.width * designHeight / designWidth;
    if ((videoSize.height - expectedHeight).abs() > 0.01) {
      throw ArgumentError.value(
        videoSize,
        'videoSize',
        'Video export layout requires a 5:6 portrait size.',
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
      headerRect: scaledRect(48, 40, 984, 196),
      coverRect: scaledRect(72, 64, 148, 148),
      contentRect: scaledRect(48, 272, 984, 984),
      scale: scale,
    );
  }
}
