import 'dart:async';

import 'package:flutter/material.dart';

import '../simai_file.dart';

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
    SimaiVideoQuality.hd720 => 1280,
    SimaiVideoQuality.fullHd1080 => 1920,
  };

  int get videoBitrate => switch (this) {
    SimaiVideoQuality.hd720 => 4 * 1000 * 1000,
    SimaiVideoQuality.fullHd1080 => 8 * 1000 * 1000,
  };

  String get label => switch (this) {
    SimaiVideoQuality.hd720 => '720 × 1280',
    SimaiVideoQuality.fullHd1080 => '1080 × 1920',
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
  final String? outputPath;

  const SimaiVideoExportOptions({
    this.quality = SimaiVideoQuality.fullHd1080,
    this.audioMode = SimaiVideoAudioMode.musicAndHitSounds,
    this.hitSoundEnabled,
    this.showCornerInfo,
    this.outputPath,
  });

  SimaiVideoExportOptions copyWith({
    SimaiVideoQuality? quality,
    SimaiVideoAudioMode? audioMode,
    bool? hitSoundEnabled,
    bool inheritHitSoundEnabled = false,
    bool? showCornerInfo,
    bool inheritShowCornerInfo = false,
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
      outputPath: clearOutputPath ? null : outputPath ?? this.outputPath,
    );
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
    final expectedHeight = videoSize.width * 16 / 9;
    if ((videoSize.height - expectedHeight).abs() > 0.01) {
      throw ArgumentError.value(
        videoSize,
        'videoSize',
        'Video export layout requires a 9:16 portrait size.',
      );
    }
    final scale = videoSize.width / 1080.0;
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
      headerRect: scaledRect(48, 64, 984, 196),
      coverRect: scaledRect(72, 88, 148, 148),
      contentRect: scaledRect(48, 468, 984, 984),
      scale: scale,
    );
  }
}
