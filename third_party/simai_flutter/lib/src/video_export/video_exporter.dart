import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../ui/simai_game.dart';
import '../ui/simai_player.dart';
import 'video_export_models.dart';
import 'video_export_platform.dart';
import 'video_export_timeline.dart';
import 'video_frame_renderer.dart';

class SimaiVideoExporter with WidgetsBindingObserver {
  static final SimaiVideoExporter instance = SimaiVideoExporter._();

  final SimaiNativeVideoExportPlatform _platform;
  bool _observingLifecycle = false;
  final StreamController<SimaiVideoExportTask?> _activeTaskController =
      StreamController<SimaiVideoExportTask?>.broadcast(sync: true);
  SimaiVideoExportTask? _activeTask;
  SimaiVideoExportTask? _lastCompletedTask;
  int _openExportPageCount = 0;

  SimaiVideoExporter._() : _platform = SimaiNativeVideoExportPlatform.instance;

  static const int frameRate = 60;

  /// The single export currently owned by this process, if any.
  ///
  /// Use [SimaiVideoExportTask.currentProgress] for an immediate snapshot and
  /// [SimaiVideoExportTask.progress] for subsequent updates. Closing an export
  /// page does not clear or cancel this task.
  SimaiVideoExportTask? get activeTask => _activeTask;

  /// Most recent completed task whose result has not yet been consumed or dismissed.
  SimaiVideoExportTask? get lastCompletedTask => _lastCompletedTask;

  /// Whether at least one [SimaiVideoExportPage] is currently mounted.
  bool get isExportPageOpen => _openExportPageCount > 0;

  void registerExportPageOpened() => _openExportPageCount++;

  void registerExportPageClosed() {
    if (_openExportPageCount > 0) _openExportPageCount--;
  }

  void clearLastCompletedTask([SimaiVideoExportTask? task]) {
    if (task == null || identical(_lastCompletedTask, task)) {
      _lastCompletedTask = null;
    }
  }

  /// Emits whenever [activeTask] starts or returns to null.
  Stream<SimaiVideoExportTask?> get activeTaskChanges =>
      _activeTaskController.stream;

  bool get hasActiveTask => _activeTask != null;

  Future<bool> isSupported({
    SimaiVideoQuality quality = SimaiVideoQuality.hd720,
    SimaiVideoFrameRate frameRate = SimaiVideoFrameRate.fps60,
    bool showHeader = true,
  }) {
    return _platform.isSupported(
      width: quality.width,
      height: quality.heightFor(showHeader: showHeader),
      fps: frameRate.fps,
    );
  }

  /// Saves a completed export to the system media library.
  ///
  /// This method never requests photo or storage permissions. The host
  /// application must declare and request any permission required by the
  /// target OS before calling it.
  ///
  /// After the video has been copied successfully, [SimaiVideoExportResult.path]
  /// is deleted automatically and must not be reused.
  Future<String?> saveToGallery(SimaiVideoExportResult result) async {
    try {
      final identifier = await _platform.saveToGallery(result.path);
      if (_lastCompletedTask?.completedResult?.path == result.path) {
        _lastCompletedTask = null;
      }
      return identifier;
    } on PlatformException catch (error) {
      throw SimaiVideoExportException(
        error.code,
        error.message ?? 'Unable to save the exported video to the gallery.',
        error,
      );
    }
  }

  /// Opens the system share sheet for a completed export.
  ///
  /// The exported file at [SimaiVideoExportResult.path] is deleted after the
  /// share sheet opens. The platform keeps a separate temporary copy for the
  /// receiving app when necessary.
  Future<void> share(SimaiVideoExportResult result, {String? text}) async {
    try {
      final shareTarget = result.savedToGallery &&
              result.galleryUri != null &&
              result.galleryUri!.isNotEmpty
          ? result.galleryUri!
          : result.path;
      await _platform.shareVideo(path: shareTarget, text: text);
      if (!result.savedToGallery &&
          _lastCompletedTask?.completedResult?.path == result.path) {
        _lastCompletedTask = null;
      }
    } on PlatformException catch (error) {
      throw SimaiVideoExportException(
        error.code,
        error.message ?? 'Unable to share the exported video.',
        error,
      );
    }
  }

  int estimateFileSizeBytes({
    required SimaiPlayerController controller,
    SimaiVideoExportOptions options = const SimaiVideoExportOptions(),
  }) {
    final hitSoundEnabled =
        options.hitSoundEnabled ?? controller.hitSoundEnabled;
    final audioMode = resolveSimaiVideoAudioMode(
      requestedMode: options.audioMode,
      hitSoundEnabled: hitSoundEnabled,
    );
    final visualDuration = max(0.0, controller.chartInfo.totalDuration);
    final timelineStart = min(
      0.0,
      audioMode == SimaiVideoAudioMode.silent
          ? 0.0
          : controller.effectiveMusicOffsetSeconds,
    );
    final estimatedDuration = max(0.0, visualDuration - timelineStart);
    return estimateSimaiVideoFileSizeBytes(
      quality: options.quality,
      frameRate: options.frameRate,
      duration: Duration(microseconds: (estimatedDuration * 1000000).ceil()),
      includeAudio: audioMode != SimaiVideoAudioMode.silent,
    );
  }

  SimaiVideoExportTask export({
    required SimaiPlayerController controller,
    required SimaiVideoMetadata metadata,
    SimaiVideoExportOptions options = const SimaiVideoExportOptions(),
    TextStyle? displayFont,
    SimaiTextStyleResolver? textStyleResolver,
    Future<void> Function()? prepareFonts,
  }) {
    _ensureLifecycleObserver();
    if (_activeTask != null) {
      throw const SimaiVideoExportException(
        'busy',
        'Another video export is already running.',
      );
    }
    _lastCompletedTask = null;
    final snapshotController = createSimaiVideoExportControllerSnapshot(
      controller,
    );
    snapshotController.hitSoundEnabled =
        options.hitSoundEnabled ?? snapshotController.hitSoundEnabled;
    snapshotController.showCornerInfo =
        options.showCornerInfo ?? snapshotController.showCornerInfo;
    snapshotController.showDetailedPerformanceInfo =
        options.showDetailedPerformanceInfo ??
        snapshotController.showDetailedPerformanceInfo;
    int? nativeSessionId;
    bool cancelled = false;

    Future<void> cancel() async {
      if (cancelled) return;
      cancelled = true;
      final id = nativeSessionId;
      if (id != null) {
        await _platform.cancel(id);
      }
    }

    final task = SimaiVideoExportTask.internal(
      metadata: metadata,
      options: options,
      estimatedFileSizeBytes: estimateFileSizeBytes(
        controller: snapshotController,
        options: options,
      ),
      cancelCallback: cancel,
    );
    _activeTask = task;
    _activeTaskController.add(task);
    unawaited(
      _runExport(
        snapshotController: snapshotController,
        metadata: metadata,
        options: options,
        task: task,
        displayFont: displayFont,
        textStyleResolver: textStyleResolver,
        prepareFonts: prepareFonts,
        isCancelled: () => cancelled,
        onSessionCreated: (id) => nativeSessionId = id,
      ),
    );
    return task;
  }

  Future<void> _runExport({
    required SimaiPlayerController snapshotController,
    required SimaiVideoMetadata metadata,
    required SimaiVideoExportOptions options,
    required SimaiVideoExportTask task,
    required TextStyle? displayFont,
    required SimaiTextStyleResolver? textStyleResolver,
    required Future<void> Function()? prepareFonts,
    required bool Function() isCancelled,
    required ValueChanged<int> onSessionCreated,
  }) async {
    SimaiVideoFrameRenderer? renderer;
    SimaiNativeVideoSession? session;
    bool nativeCompleted = false;
    try {
      task.updateProgressForExport(
        SimaiVideoExportProgress.preparing(
          estimatedFileSizeBytes: task.estimatedFileSizeBytes,
        ),
      );
      final nativeAudioMode = resolveSimaiVideoAudioMode(
        requestedMode: options.audioMode,
        hitSoundEnabled: snapshotController.hitSoundEnabled,
      );
      final includesMusic = nativeAudioMode != SimaiVideoAudioMode.silent;
      final includesHits =
          nativeAudioMode == SimaiVideoAudioMode.musicAndHitSounds;
      if (includesMusic &&
          snapshotController.audioAsset == null &&
          snapshotController.audioFilePath == null) {
        throw const SimaiVideoExportException(
          'invalid_audio_source',
          'The selected audio mode requires a music source.',
        );
      }

      final fps = options.frameRate.fps;
      final outputWidth = options.quality.width;
      final outputHeight = options.quality.heightFor(
        showHeader: options.showHeader,
      );
      final supported = await isSupported(
        quality: options.quality,
        frameRate: options.frameRate,
        showHeader: options.showHeader,
      );
      if (!supported) {
        throw SimaiVideoExportException(
          'unsupported',
          '${options.quality.labelFor(showHeader: options.showHeader)} ${fps}fps hardware export is not supported.',
        );
      }
      if (isCancelled()) throw const SimaiVideoExportCancelledException();

      final pvVideoPath = options.pvVideoPath;
      final hasPvVideo = pvVideoPath != null && pvVideoPath.isNotEmpty;
      renderer = SimaiVideoFrameRenderer(
        controller: snapshotController,
        metadata: metadata,
        quality: options.quality,
        initialFrameRate: options.frameRate,
        displayFont: displayFont,
        textStyleResolver: textStyleResolver,
        prepareFonts: prepareFonts,
        transparentContentBackground: hasPvVideo,
        showHeader: options.showHeader,
      );
      List<int>? pvRect;
      if (hasPvVideo) {
        final circle = renderer.layout.pvCircleRect;
        final maxW = outputWidth;
        final maxH = outputHeight;
        final left = circle.left.floor().clamp(0, maxW - 1);
        final top = circle.top.floor().clamp(0, maxH - 1);
        final right = circle.right.ceil().clamp(left + 1, maxW);
        final bottom = circle.bottom.ceil().clamp(top + 1, maxH);
        pvRect = <int>[left, top, right - left, bottom - top];
      }
      final suggestedDisplayName =
          options.displayName ??
          '${metadata.title}_${metadata.difficulty.label}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      session = await _platform.start(
        width: outputWidth,
        height: outputHeight,
        fps: fps,
        videoBitrate: options.quality.videoBitrateFor(options.frameRate),
        outputPath: options.outputPath,
        audioAsset: snapshotController.audioAsset,
        audioFilePath: snapshotController.audioFilePath,
        audioMode: nativeAudioMode.name,
        pvVideoPath: hasPvVideo ? pvVideoPath : null,
        pvRect: pvRect,
        saveToGallery: options.saveToGallery,
        displayName: suggestedDisplayName,
      );
      onSessionCreated(session.id);
      if (isCancelled()) throw const SimaiVideoExportCancelledException();
      await renderer.prepare(isCancelled: isCancelled);
      if (isCancelled()) throw const SimaiVideoExportCancelledException();
      if (session.bufferAddresses.length != 2) {
        throw const SimaiVideoExportException(
          'invalid_native_buffer_pool',
          'The native exporter must provide exactly two frame buffers.',
        );
      }
      final expectedFrameBytes = outputWidth * outputHeight * 4;
      if (session.bufferLength != expectedFrameBytes) {
        throw SimaiVideoExportException(
          'invalid_native_buffer_size',
          'Expected $expectedFrameBytes bytes, got ${session.bufferLength}.',
        );
      }

      final hitEvents = includesHits
          ? buildSimaiHitSoundEventTimesUs(
              snapshotController.chart,
              userOffsetMs: snapshotController.hitSoundOffsetMs,
            )
          : const <int>[];
      final timeline = SimaiVideoTimeline.calculate(
        visualEnd: renderer.visualDuration,
        musicOffset: snapshotController.effectiveMusicOffsetSeconds,
        audioDuration: session.audioDurationUs / 1000000.0,
        hitEventTimesUs: hitEvents,
        includeMusic: includesMusic,
        includeHitSounds: includesHits,
        fps: fps,
      );
      final estimatedFileSizeBytes = estimateSimaiVideoFileSizeBytes(
        quality: options.quality,
        frameRate: options.frameRate,
        duration: Duration(microseconds: timeline.durationUs),
        includeAudio: includesMusic || includesHits,
      );
      task.updateProgressForExport(
        SimaiVideoExportProgress(
          phase: SimaiVideoExportPhase.preparing,
          completedFrames: 0,
          totalFrames: timeline.frameCount,
          fraction: 0,
          estimatedFileSizeBytes: estimatedFileSizeBytes,
        ),
      );
      await _platform.validateStorage(
        sessionId: session.id,
        durationUs: timeline.durationUs,
      );
      if (isCancelled()) throw const SimaiVideoExportCancelledException();

      final frameStepDelta = 1.0 / fps;
      final renderStopwatch = Stopwatch()..start();
      for (int frame = 0; frame < timeline.frameCount; frame++) {
        if (isCancelled()) throw const SimaiVideoExportCancelledException();
        final chartTime = timeline.chartTimeForFrame(frame);
        final rgba = await renderer.renderRgbaFrame(
          chartTime,
          resetWindow: frame == 0,
          stepDelta: frameStepDelta,
        );
        final slot = frame & 1;
        _platform.copyFrameToSlot(
          session: session,
          slot: slot,
          rgbaBytes: rgba,
        );
        int? pvTimeUs;
        if (hasPvVideo) {
          final pvSec =
              (chartTime - snapshotController.effectiveMusicOffsetSeconds) -
              (snapshotController.pvOffsetMs / 1000.0);
          pvTimeUs = (pvSec * 1000000).round();
        }
        await _platform.submitFrame(
          sessionId: session.id,
          slot: slot,
          presentationTimeUs: timeline.presentationTimeUsForFrame(frame),
          pvTimeUs: pvTimeUs,
        );
        final completed = frame + 1;
        Duration? estimatedRemaining;
        if (completed >= 3 && renderStopwatch.elapsedMicroseconds > 0) {
          final framesPerSecond =
              completed /
              (renderStopwatch.elapsedMicroseconds /
                  Duration.microsecondsPerSecond);
          if (framesPerSecond.isFinite && framesPerSecond > 0) {
            final remainingSeconds =
                (timeline.frameCount - completed) / framesPerSecond + 2.0;
            estimatedRemaining = Duration(
              milliseconds: (remainingSeconds * 1000).ceil(),
            );
          }
        }
        task.updateProgressForExport(
          SimaiVideoExportProgress(
            phase: SimaiVideoExportPhase.rendering,
            completedFrames: completed,
            totalFrames: timeline.frameCount,
            fraction: timeline.frameCount == 0
                ? 1
                : completed / timeline.frameCount,
            estimatedRemaining: estimatedRemaining,
            estimatedFileSizeBytes: estimatedFileSizeBytes,
          ),
        );
        if ((frame & 3) == 3) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      if (isCancelled()) throw const SimaiVideoExportCancelledException();
      task.updateProgressForExport(
        SimaiVideoExportProgress(
          phase: includesMusic || includesHits
              ? SimaiVideoExportPhase.mixingAudio
              : SimaiVideoExportPhase.muxing,
          completedFrames: timeline.frameCount,
          totalFrames: timeline.frameCount,
          fraction: 1,
          estimatedRemaining: const Duration(seconds: 2),
          estimatedFileSizeBytes: estimatedFileSizeBytes,
        ),
      );
      final nativeResult = await _platform.finish(
        sessionId: session.id,
        durationUs: timeline.durationUs,
        timelineStartUs: (timeline.chartStart * 1000000).round(),
        musicOffsetUs:
            (snapshotController.effectiveMusicOffsetSeconds * 1000000).round(),
        musicVolume: snapshotController.musicVolume.clamp(0.0, 1.0),
        hitSoundVolume: snapshotController.hitSoundVolume
            .clamp(0.0, simaiMaxHitSoundVolume)
            .toDouble(),
        hitEventTimesUs: hitEvents,
      );
      nativeCompleted = true;
      task.updateProgressForExport(
        SimaiVideoExportProgress(
          phase: SimaiVideoExportPhase.completed,
          completedFrames: timeline.frameCount,
          totalFrames: timeline.frameCount,
          fraction: 1,
          estimatedRemaining: Duration.zero,
          estimatedFileSizeBytes: nativeResult.fileSizeBytes,
        ),
      );
      task.completeResultForExport(
        SimaiVideoExportResult(
          path: nativeResult.outputPath,
          duration: Duration(microseconds: timeline.durationUs),
          width: outputWidth,
          height: outputHeight,
          fps: fps,
          frameCount: timeline.frameCount,
          fileSizeBytes: nativeResult.fileSizeBytes,
          savedToGallery: nativeResult.savedToGallery,
          galleryUri: nativeResult.galleryUri,
        ),
      );
      _lastCompletedTask = task;
    } on SimaiVideoExportCancelledException catch (error, stackTrace) {
      final current = task.currentProgress;
      task.updateProgressForExport(
        SimaiVideoExportProgress(
          phase: SimaiVideoExportPhase.cancelled,
          completedFrames: current.completedFrames,
          totalFrames: current.totalFrames,
          fraction: current.overallFraction,
          estimatedFileSizeBytes: current.estimatedFileSizeBytes,
        ),
      );
      task.completeErrorForExport(error, stackTrace);
    } on PlatformException catch (error, stackTrace) {
      if (!task.isCompleted) {
        if (error.code == 'cancelled') {
          final current = task.currentProgress;
          task.updateProgressForExport(
            SimaiVideoExportProgress(
              phase: SimaiVideoExportPhase.cancelled,
              completedFrames: current.completedFrames,
              totalFrames: current.totalFrames,
              fraction: current.overallFraction,
              estimatedFileSizeBytes: current.estimatedFileSizeBytes,
            ),
          );
          task.completeErrorForExport(
            const SimaiVideoExportCancelledException(),
            stackTrace,
          );
          return;
        }
        final current = task.currentProgress;
        task.updateProgressForExport(
          SimaiVideoExportProgress(
            phase: SimaiVideoExportPhase.failed,
            completedFrames: current.completedFrames,
            totalFrames: current.totalFrames,
            fraction: current.overallFraction,
            estimatedFileSizeBytes: current.estimatedFileSizeBytes,
          ),
        );
        task.completeErrorForExport(
          SimaiVideoExportException(
            error.code,
            error.message ?? 'Native video export failed.',
            error,
          ),
          stackTrace,
        );
      }
    } catch (error, stackTrace) {
      if (!task.isCompleted) {
        final current = task.currentProgress;
        task.updateProgressForExport(
          SimaiVideoExportProgress(
            phase: SimaiVideoExportPhase.failed,
            completedFrames: current.completedFrames,
            totalFrames: current.totalFrames,
            fraction: current.overallFraction,
            estimatedFileSizeBytes: current.estimatedFileSizeBytes,
          ),
        );
        task.completeErrorForExport(error, stackTrace);
      }
    } finally {
      if (!nativeCompleted && session != null) {
        try {
          await _platform.cancel(session.id);
        } catch (_) {}
      }
      renderer?.dispose();
      snapshotController.dispose();
      await task.closeProgressForExport();
      if (identical(_activeTask, task)) {
        _activeTask = null;
        _activeTaskController.add(null);
      }
    }
  }

  void _ensureLifecycleObserver() {
    if (_observingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.detached) {
      return;
    }
    final task = _activeTask;
    if (task != null) unawaited(task.cancel());
  }
}

@visibleForTesting
SimaiVideoAudioMode resolveSimaiVideoAudioMode({
  required SimaiVideoAudioMode requestedMode,
  required bool hitSoundEnabled,
}) {
  if (requestedMode != SimaiVideoAudioMode.musicAndHitSounds) {
    return requestedMode;
  }
  return hitSoundEnabled
      ? SimaiVideoAudioMode.musicAndHitSounds
      : SimaiVideoAudioMode.musicOnly;
}

SimaiPlayerController createSimaiVideoExportControllerSnapshot(
  SimaiPlayerController source,
) {
  final snapshot = SimaiPlayerController(
    chart: source.chart,
    audioAsset: source.audioAsset,
    audioFilePath: source.audioFilePath,
    backgroundImageProvider: source.backgroundImageProvider,
    initialChartTime: source.initialChartTime,
  )..title = source.title;
  snapshot
    ..speed = source.speed
    ..touchSpeed = source.touchSpeed
    ..slideDisplayTiming = source.slideDisplayTiming
    ..autoPlayMode = source.autoPlayMode
    ..autoPlaySeed = source.autoPlaySeed
    ..playbackRate = source.playbackRate
    ..musicVolume = source.musicVolume
    ..hitSoundVolume = source.hitSoundVolume
    ..musicOffsetMs = source.musicOffsetMs
    ..hitSoundOffsetMs = source.hitSoundOffsetMs
    ..pvOffsetMs = source.pvOffsetMs
    ..hitSoundEnabled = source.hitSoundEnabled
    ..backgroundMode = source.backgroundMode
    ..backgroundOpacity = source.backgroundOpacity
    ..mirrorMode = source.mirrorMode
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
    ..showCornerInfo = source.showCornerInfo
    ..showDetailedPerformanceInfo = source.showDetailedPerformanceInfo;
  return snapshot;
}
