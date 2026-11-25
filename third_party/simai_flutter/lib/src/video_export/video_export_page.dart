import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../audio/soloud_audio_player.dart';
import '../ui/center_display_mode.dart';
import '../ui/simai_game.dart';
import '../ui/simai_player.dart';
import 'video_export_models.dart';
import 'video_export_timeline.dart';
import 'video_exporter.dart';
import 'video_frame_renderer.dart';

/// A dedicated workspace for configuring, previewing, and monitoring exports.
///
/// Before an export starts, the page shows configuration and WYSIWYG preview
/// tabs. Once a task starts (or an existing [task] is supplied), those tabs are
/// replaced by a progress view. The route returns a [SimaiVideoExportResult]
/// after a successful export and returns null when it is closed while an export
/// is still running. Closing this page never cancels the task.
class SimaiVideoExportPage extends StatefulWidget {
  final SimaiPlayerController controller;
  final SimaiVideoMetadata metadata;
  final SimaiVideoExportOptions initialOptions;
  final SimaiVideoExportSettings? initialSettings;
  final ValueChanged<SimaiVideoExportSettings>? onSettingsChanged;
  final Future<String?> Function()? resolveAudioFilePath;
  final SimaiVideoExportTask? task;
  final ValueChanged<SimaiVideoExportResult>? onVideoExported;
  final TextStyle? displayFont;
  final SimaiTextStyleResolver? textStyleResolver;
  final Future<void> Function()? prepareFonts;

  const SimaiVideoExportPage({
    super.key,
    required this.controller,
    required this.metadata,
    this.initialOptions = const SimaiVideoExportOptions(),
    this.initialSettings,
    this.onSettingsChanged,
    this.resolveAudioFilePath,
    this.task,
    this.onVideoExported,
    this.displayFont,
    this.textStyleResolver,
    this.prepareFonts,
  });

  @override
  State<SimaiVideoExportPage> createState() => _SimaiVideoExportPageState();
}

class _SimaiVideoExportPageState extends State<SimaiVideoExportPage>
    with TickerProviderStateMixin {
  static const Size _previewRenderSize = Size(600, 720);

  late final TabController _tabController;
  late final Ticker _previewTicker;
  late SimaiVideoQuality _quality;
  late bool _includeMusic;
  late final bool _wasPlaying;
  late final Future<void> _pauseSourceFuture;

  final Map<SimaiVideoQuality, bool> _qualitySupport = {};
  SimaiPlayerController? _configurationController;
  SimaiPlayerController? _previewController;
  SimaiVideoFrameRenderer? _previewRenderer;
  SoLoudAudioPlayer? _previewMusicPlayer;
  String? _loadedPreviewMusicFile;
  String? _loadedPreviewMusicAsset;
  bool _previewMusicReady = false;
  bool _previewAudioPlayActive = false;
  AudioSource? _previewHitSource;
  bool _previewHitLoading = false;
  final List<SoundHandle> _previewHitVoices = <SoundHandle>[];
  List<int> _previewHitEventsUs = const <int>[];
  int _previewHitIndex = 0;
  bool _resolvingAudio = false;
  Future<String?>? _audioResolveFuture;
  ui.Image? _previewImage;
  Object? _previewError;
  double _previewTime = 0;
  double _previewDuration = 0;
  Duration? _lastTickElapsed;
  double? _queuedPreviewTime;
  bool _queuedResetWindow = false;
  bool _previewReady = false;
  bool _previewPlaying = false;
  bool _renderingPreview = false;
  Future<void>? _previewPrepareTask;
  Completer<void>? _previewRenderIdle;
  Timer? _previewRebuildTimer;
  Future<void> _previewRebuildChain = Future<void>.value();
  int _previewSettingsGeneration = 0;
  bool _loadingSupport = true;
  Object? _supportError;
  SimaiVideoExportTask? _task;
  SimaiVideoExportProgress? _taskProgress;
  SimaiVideoExportResult? _taskResult;
  Object? _taskError;
  StreamSubscription<SimaiVideoExportProgress>? _taskSubscription;
  Timer? _elapsedTimer;
  bool _savingToGallery = false;
  bool _sharingVideo = false;
  bool _savedToGallery = false;
  bool _shareSheetOpened = false;
  bool _localFileDeleted = false;
  bool _disposed = false;

  bool get _hasAudioSource {
    final settings = _settingsController;
    return (settings.audioFilePath != null &&
            settings.audioFilePath!.isNotEmpty) ||
        (settings.audioAsset != null && settings.audioAsset!.isNotEmpty);
  }

  bool get _audioEnabled => _includeMusic && _hasAudioSource;

  bool get _selectedQualitySupported => _qualitySupport[_quality] == true;

  SimaiPlayerController get _settingsController =>
      _configurationController ?? widget.controller;

  SimaiVideoExportOptions get _selectedOptions {
    final settings = _settingsController;
    final useMusic = _includeMusic && _hasAudioSource;
    final selectedAudioMode = !useMusic
        ? SimaiVideoAudioMode.silent
        : settings.hitSoundEnabled
        ? SimaiVideoAudioMode.musicAndHitSounds
        : SimaiVideoAudioMode.musicOnly;
    return widget.initialOptions.copyWith(
      quality: _quality,
      audioMode: selectedAudioMode,
      hitSoundEnabled: useMusic && settings.hitSoundEnabled,
      showCornerInfo: settings.showCornerInfo,
      showDetailedPerformanceInfo: settings.showDetailedPerformanceInfo,
    );
  }

  int get _estimatedFileSizeBytes =>
      SimaiVideoExporter.instance.estimateFileSizeBytes(
        controller: _settingsController,
        options: _selectedOptions,
      );

  @override
  void initState() {
    super.initState();
    SimaiVideoExporter.instance.registerExportPageOpened();
    final activeTask =
        widget.task ??
        SimaiVideoExporter.instance.activeTask ??
        SimaiVideoExporter.instance.lastCompletedTask;
    final initialSettings = widget.initialSettings;
    _quality =
        activeTask?.options.quality ??
        initialSettings?.quality ??
        widget.initialOptions.quality;
    _includeMusic = activeTask != null
        ? activeTask.options.audioMode != SimaiVideoAudioMode.silent
        : initialSettings?.includeMusic ??
              (widget.initialOptions.audioMode != SimaiVideoAudioMode.silent);
    if (activeTask == null) {
      final configuration = createSimaiVideoExportControllerSnapshot(
        widget.controller,
      );
      if (initialSettings != null) {
        initialSettings.applyTo(configuration);
      } else {
        configuration.hitSoundEnabled =
            _includeMusic &&
            (widget.initialOptions.hitSoundEnabled ??
                widget.controller.hitSoundEnabled);
        configuration.showCornerInfo =
            widget.initialOptions.showCornerInfo ??
            widget.controller.showCornerInfo;
        configuration.showDetailedPerformanceInfo =
            widget.initialOptions.showDetailedPerformanceInfo ??
            widget.controller.showDetailedPerformanceInfo;
      }
      _configurationController = configuration;
    }
    _wasPlaying = widget.controller.isPlaying;
    _pauseSourceFuture = _wasPlaying
        ? widget.controller.pause()
        : Future<void>.value();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChanged);
    _previewTicker = createTicker(_handlePreviewTick);
    if (activeTask != null) {
      _loadingSupport = false;
      _attachTask(activeTask);
    } else {
      unawaited(_loadQualitySupport());
      _startPreviewPreparation();
      if (_includeMusic && !_hasAudioSource) {
        unawaited(_ensureMusicResolved(notifyOnMissing: false));
      } else if (_includeMusic) {
        unawaited(_preparePreviewAudio());
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    SimaiVideoExporter.instance.registerExportPageClosed();
    _tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    _previewTicker.dispose();
    _previewSettingsGeneration++;
    _previewRebuildTimer?.cancel();
    _taskSubscription?.cancel();
    _elapsedTimer?.cancel();
    _queuedPreviewTime = null;
    _queuedResetWindow = false;
    _previewImage?.dispose();
    _previewImage = null;
    unawaited(_disposePreviewAudio());
    unawaited(_disposePreviewResourcesWhenIdle());
    _configurationController?.dispose();
    _configurationController = null;
    if (_wasPlaying) {
      unawaited(_restoreSourcePlayback());
    }
    super.dispose();
  }

  Future<void> _loadQualitySupport() async {
    final qualities = SimaiVideoQuality.values;
    late final List<bool> support;
    try {
      support = await Future.wait(
        qualities.map(
          (quality) =>
              SimaiVideoExporter.instance.isSupported(quality: quality),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _supportError = error;
        _loadingSupport = false;
      });
      return;
    }
    if (!mounted) return;
    for (int index = 0; index < qualities.length; index++) {
      _qualitySupport[qualities[index]] = support[index];
    }
    if (!_selectedQualitySupported) {
      for (final quality in qualities) {
        if (_qualitySupport[quality] == true) {
          _quality = quality;
          break;
        }
      }
    }
    setState(() => _loadingSupport = false);
  }

  Future<void> _preparePreview() async {
    try {
      await _pauseSourceFuture;
      if (_disposed) return;
      if (mounted) {
        setState(() {
          _previewError = null;
          _previewReady = false;
        });
      }
      final previewController = createSimaiVideoExportControllerSnapshot(
        _settingsController,
      );
      final renderer = SimaiVideoFrameRenderer(
        controller: previewController,
        metadata: widget.metadata,
        quality: SimaiVideoQuality.hd720,
        outputSize: _previewRenderSize,
        displayFont: widget.displayFont,
        textStyleResolver: widget.textStyleResolver,
        prepareFonts: widget.prepareFonts,
      );
      _previewController = previewController;
      _previewRenderer = renderer;
      await renderer.prepare();
      if (_disposed) return;
      _previewDuration = renderer.visualDuration;
      _previewReady = true;
      _queuePreviewFrame(resetWindow: true);
      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      setState(() => _previewError = error);
    }
  }

  void _startPreviewPreparation() {
    if (_disposed || _previewPrepareTask != null) return;
    final task = _preparePreview();
    _previewPrepareTask = task;
    unawaited(
      task.whenComplete(() {
        if (identical(_previewPrepareTask, task)) {
          _previewPrepareTask = null;
        }
      }),
    );
  }

  void _handleTabChanged() {
    if (_tabController.index != 1 && _previewPlaying) {
      _setPreviewPlaying(false);
    }
  }

  void _handlePreviewTick(Duration elapsed) {
    if (!_previewPlaying || !_previewReady) return;
    final previous = _lastTickElapsed;
    _lastTickElapsed = elapsed;
    if (previous == null) return;
    final delta = (elapsed - previous).inMicroseconds / 1000000.0;
    if (!delta.isFinite || delta <= 0) return;
    _previewTime += delta;
    if (_previewDuration > 0 && _previewTime >= _previewDuration) {
      _previewTime = _previewDuration;
      _setPreviewPlaying(false);
    } else {
      _advancePreviewAudio();
    }
    _queuePreviewFrame();
  }

  void _setPreviewPlaying(bool value) {
    if (!_previewReady || _previewPlaying == value) return;
    if (value &&
        _previewDuration > 0 &&
        _previewTime >= _previewDuration - 1e-6) {
      _previewTime = 0;
      _queuePreviewFrame(resetWindow: true);
    }
    setState(() => _previewPlaying = value);
    _lastTickElapsed = null;
    if (value) {
      _previewTicker.start();
      unawaited(_startPreviewAudioPlayback());
    } else {
      _previewTicker.stop();
      unawaited(_pausePreviewAudioPlayback());
    }
  }

  void _restartPreview() {
    if (!_previewReady) return;
    _setPreviewPlaying(false);
    _previewTime = 0;
    _previewHitIndex = _lowerBoundHitEvent(0);
    unawaited(_seekPreviewMusic(0));
    _queuePreviewFrame(resetWindow: true);
  }

  void _queuePreviewFrame({bool resetWindow = false}) {
    if (!_previewReady || _disposed) return;
    _queuedPreviewTime = _previewTime;
    _queuedResetWindow = _queuedResetWindow || resetWindow;
    if (!_renderingPreview) unawaited(_drainPreviewFrames());
  }

  Future<void> _drainPreviewFrames() async {
    final renderer = _previewRenderer;
    if (renderer == null) return;
    _renderingPreview = true;
    final renderIdle = Completer<void>();
    _previewRenderIdle = renderIdle;
    try {
      while (!_disposed && _queuedPreviewTime != null) {
        final frameTime = _queuedPreviewTime!;
        final resetWindow = _queuedResetWindow;
        _queuedPreviewTime = null;
        _queuedResetWindow = false;
        final image = await renderer.renderImageFrame(
          frameTime,
          resetWindow: resetWindow,
        );
        if (!mounted) {
          image.dispose();
          return;
        }
        final previous = _previewImage;
        setState(() {
          _previewImage = image;
          _previewError = null;
        });
        if (previous != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            previous.dispose();
          });
        }
      }
    } catch (error) {
      if (mounted) setState(() => _previewError = error);
    } finally {
      _renderingPreview = false;
      if (!renderIdle.isCompleted) renderIdle.complete();
      if (!_disposed && _queuedPreviewTime != null) {
        unawaited(_drainPreviewFrames());
      }
    }
  }

  Future<void> _releasePreview() async {
    _setPreviewPlaying(false);
    _queuedPreviewTime = null;
    _queuedResetWindow = false;
    final prepareTask = _previewPrepareTask;
    if (prepareTask != null) await prepareTask;
    final renderIdle = _previewRenderIdle;
    if (renderIdle != null && !renderIdle.isCompleted) {
      await renderIdle.future;
    }
    final image = _previewImage;
    _previewImage = null;
    image?.dispose();
    _previewRenderer?.dispose();
    _previewRenderer = null;
    _previewController?.dispose();
    _previewController = null;
    _previewReady = false;
  }

  Future<void> _disposePreviewResourcesWhenIdle() async {
    try {
      final prepareTask = _previewPrepareTask;
      if (prepareTask != null) await prepareTask;
      final renderIdle = _previewRenderIdle;
      if (renderIdle != null && !renderIdle.isCompleted) {
        await renderIdle.future;
      }
    } finally {
      _previewRenderer?.dispose();
      _previewRenderer = null;
      _previewController?.dispose();
      _previewController = null;
    }
  }

  Future<void> _restoreSourcePlayback() async {
    try {
      await _pauseSourceFuture;
      await widget.controller.play();
    } catch (_) {
      // The hosting player may already be disposed while its route is closing.
    }
  }

  void _notifySettingsChanged() {
    final callback = widget.onSettingsChanged;
    if (callback == null || _task != null) return;
    callback(
      SimaiVideoExportSettings.capture(
        _settingsController,
        quality: _quality,
        includeMusic: _includeMusic,
      ),
    );
  }

  void _rebuildPreviewHitEvents() {
    final controller = _settingsController;
    _previewHitEventsUs = buildSimaiHitSoundEventTimesUs(
      controller.chart,
      userOffsetMs: controller.hitSoundOffsetMs,
    );
    _previewHitIndex = _lowerBoundHitEvent((_previewTime * 1000000).round());
  }

  Future<String?> _ensureMusicResolved({required bool notifyOnMissing}) async {
    if (_hasAudioSource) {
      unawaited(_preparePreviewAudio());
      return _settingsController.audioFilePath;
    }
    final resolver = widget.resolveAudioFilePath;
    if (resolver == null) {
      if (mounted && _includeMusic) {
        setState(() => _includeMusic = false);
        _notifySettingsChanged();
        if (notifyOnMissing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到可用音源，已切换为静音导出')),
          );
        }
      }
      return null;
    }
    final existingFuture = _audioResolveFuture;
    if (existingFuture != null) return existingFuture;
    if (mounted) setState(() => _resolvingAudio = true);
    final task = () async {
      try {
        final path = await resolver();
        if (_disposed) return null;
        if (path != null && path.isNotEmpty) {
          final cfg = _configurationController;
          if (cfg != null) {
            cfg.audioAsset = null;
            cfg.audioFilePath = path;
          }
          if (mounted) setState(() {});
          _notifySettingsChanged();
          if (_includeMusic) {
            await _preparePreviewAudio();
          }
          return path;
        }
        if (mounted && _includeMusic) {
          setState(() => _includeMusic = false);
          _notifySettingsChanged();
          if (notifyOnMissing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('未找到可用音源，已切换为静音导出')),
            );
          }
        }
        return null;
      } catch (e) {
        debugPrint('[VideoExport] 加载音源失败: $e');
        if (mounted && _includeMusic) {
          setState(() => _includeMusic = false);
          _notifySettingsChanged();
          if (notifyOnMissing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('未找到可用音源，已切换为静音导出')),
            );
          }
        }
        return null;
      } finally {
        _audioResolveFuture = null;
        if (mounted) setState(() => _resolvingAudio = false);
      }
    }();
    _audioResolveFuture = task;
    return task;
  }

  Future<void> _preparePreviewAudio() async {
    if (_disposed || !_includeMusic || _task != null) return;
    final settings = _settingsController;
    final filePath = settings.audioFilePath;
    final asset = settings.audioAsset;
    if ((filePath == null || filePath.isEmpty) &&
        (asset == null || asset.isEmpty)) {
      return;
    }
    _rebuildPreviewHitEvents();
    if (settings.hitSoundEnabled) {
      unawaited(_preparePreviewHitSound());
    }
    final alreadyLoaded =
        _previewMusicReady &&
        _loadedPreviewMusicFile == filePath &&
        _loadedPreviewMusicAsset == asset;
    if (alreadyLoaded) {
      unawaited(_previewMusicPlayer?.setVolume(settings.musicVolume));
      return;
    }

    _previewMusicReady = false;
    _previewAudioPlayActive = false;
    _loadedPreviewMusicFile = filePath;
    _loadedPreviewMusicAsset = asset;
    final player = _previewMusicPlayer ??= SoLoudAudioPlayer();
    try {
      await _pauseSourceFuture;
      if (_disposed ||
          !_includeMusic ||
          _loadedPreviewMusicFile != filePath ||
          _loadedPreviewMusicAsset != asset) {
        return;
      }
      if (filePath != null && filePath.isNotEmpty) {
        await player.loadFile(filePath);
      } else {
        await player.loadAsset(asset!);
      }
      if (_disposed ||
          !_includeMusic ||
          _loadedPreviewMusicFile != filePath ||
          _loadedPreviewMusicAsset != asset) {
        return;
      }
      _previewMusicReady = true;
      await player.setRate(1.0);
      await player.setVolume(settings.musicVolume);
      if (_previewPlaying && _tabController.index == 1) {
        unawaited(_startPreviewAudioPlayback());
      }
    } catch (e) {
      debugPrint('[VideoExportPreview] 预览音乐加载失败: $e');
      _previewMusicReady = false;
    }
  }

  Future<void> _preparePreviewHitSound() async {
    if (_disposed || _previewHitSource != null || _previewHitLoading) return;
    _previewHitLoading = true;
    try {
      await ensureSoLoudInitialized(SoLoud.instance);
      if (_disposed) return;
      const assetPath = 'packages/simai_flutter/assets/answer.wav';
      final src = kIsWeb
          ? await SoLoud.instance.loadAsset(assetPath, mode: LoadMode.disk)
          : await SoLoud.instance.loadAsset(assetPath);
      if (_disposed) {
        unawaited(SoLoud.instance.disposeSource(src));
        return;
      }
      _previewHitSource = src;
    } catch (e) {
      debugPrint('[VideoExportPreview] 预览正解音加载失败: $e');
    } finally {
      _previewHitLoading = false;
    }
  }

  Future<void> _startPreviewAudioPlayback() async {
    if (_disposed || !_includeMusic || !_previewPlaying) return;
    _rebuildPreviewHitEvents();
    if (_settingsController.hitSoundEnabled && _previewHitSource == null) {
      unawaited(_preparePreviewHitSound());
    }
    if (!_previewMusicReady) {
      unawaited(_preparePreviewAudio());
      return;
    }
    final musicSeconds =
        _previewTime - _settingsController.effectiveMusicOffsetSeconds;
    if (musicSeconds >= 0) {
      _previewAudioPlayActive = true;
      await _seekAndPlayPreviewMusic(musicSeconds);
    } else {
      _previewAudioPlayActive = false;
      await _seekPreviewMusic(0);
    }
  }

  Future<void> _seekAndPlayPreviewMusic(double musicSeconds) async {
    final player = _previewMusicPlayer;
    if (player == null || !_previewMusicReady || _disposed) return;
    try {
      final pos = Duration(
        microseconds: math.max(0, (musicSeconds * 1000000).round()),
      );
      await player.seek(pos);
      if (_disposed || !_previewPlaying || !_includeMusic) return;
      await player.setVolume(_settingsController.musicVolume);
      await player.play();
    } catch (e) {
      debugPrint('[VideoExportPreview] 预览音乐播放失败: $e');
    }
  }

  Future<void> _seekPreviewMusic(double musicSeconds) async {
    final player = _previewMusicPlayer;
    if (player == null || !_previewMusicReady || _disposed) return;
    try {
      final pos = Duration(
        microseconds: math.max(0, (musicSeconds * 1000000).round()),
      );
      await player.pause();
      await player.seek(pos);
    } catch (_) {}
  }

  Future<void> _pausePreviewAudioPlayback() async {
    _previewAudioPlayActive = false;
    _stopPreviewHitVoices();
    final player = _previewMusicPlayer;
    if (player == null || !_previewMusicReady) return;
    try {
      await player.pause();
    } catch (_) {}
  }

  void _advancePreviewAudio() {
    if (!_includeMusic || !_previewPlaying) return;
    final musicSeconds =
        _previewTime - _settingsController.effectiveMusicOffsetSeconds;
    if (_previewMusicReady && musicSeconds >= 0 && !_previewAudioPlayActive) {
      _previewAudioPlayActive = true;
      unawaited(_seekAndPlayPreviewMusic(musicSeconds));
    }
    if (_settingsController.hitSoundEnabled &&
        _previewHitSource != null &&
        _previewHitEventsUs.isNotEmpty) {
      final nowUs = (_previewTime * 1000000).round();
      var triggered = 0;
      while (_previewHitIndex < _previewHitEventsUs.length &&
          _previewHitEventsUs[_previewHitIndex] <= nowUs) {
        final deltaUs = nowUs - _previewHitEventsUs[_previewHitIndex];
        _previewHitIndex++;
        if (deltaUs <= 60000) {
          triggered++;
        }
      }
      if (triggered > 0) {
        _playPreviewHitVoice(triggered);
      }
    }
  }

  void _playPreviewHitVoice(int voiceCount) {
    final src = _previewHitSource;
    if (src == null || !SoLoud.instance.isInitialized || _disposed) return;
    _previewHitVoices.removeWhere(
      (handle) => !SoLoud.instance.getIsValidVoiceHandle(handle),
    );
    final baseGain = _settingsController.hitSoundVolume.clamp(0.0, 1.0);
    final gain = baseGain / math.sqrt(voiceCount);
    if (gain <= 0) return;
    try {
      final handle = SoLoud.instance.play(src, volume: gain);
      if (!handle.isError) {
        _previewHitVoices.add(handle);
      }
    } catch (_) {}
  }

  void _stopPreviewHitVoices() {
    if (_previewHitVoices.isEmpty || !SoLoud.instance.isInitialized) {
      _previewHitVoices.clear();
      return;
    }
    for (final handle in _previewHitVoices) {
      if (SoLoud.instance.getIsValidVoiceHandle(handle)) {
        unawaited(SoLoud.instance.stop(handle));
      }
    }
    _previewHitVoices.clear();
  }

  Future<void> _disposePreviewAudio() async {
    _previewAudioPlayActive = false;
    _previewMusicReady = false;
    _stopPreviewHitVoices();
    final player = _previewMusicPlayer;
    _previewMusicPlayer = null;
    if (player != null) {
      try {
        await player.dispose();
      } catch (_) {}
    }
    final src = _previewHitSource;
    _previewHitSource = null;
    if (src != null && SoLoud.instance.isInitialized) {
      try {
        await SoLoud.instance.disposeSource(src);
      } catch (_) {}
    }
  }

  int _lowerBoundHitEvent(int targetUs) {
    final list = _previewHitEventsUs;
    var low = 0;
    var high = list.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (list[mid] < targetUs) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  void _updateVisualSetting(
    void Function(SimaiPlayerController controller) update, {
    bool rebuildPreview = true,
  }) {
    final controller = _configurationController;
    if (controller == null) return;
    update(controller);
    setState(() {});
    _notifySettingsChanged();
    if (rebuildPreview) {
      _schedulePreviewRebuild();
    } else {
      _queuePreviewFrame();
    }
  }

  void _updateAudioSetting(
    void Function(SimaiPlayerController controller) update,
  ) {
    final controller = _configurationController;
    if (controller == null) return;
    update(controller);
    setState(() {});
    _notifySettingsChanged();
    _rebuildPreviewHitEvents();
    unawaited(_previewMusicPlayer?.setVolume(controller.musicVolume));
    if (controller.hitSoundEnabled && _includeMusic) {
      unawaited(_preparePreviewHitSound());
    }
  }

  void _setIncludeMusic(bool value) {
    if (_includeMusic == value) return;
    setState(() => _includeMusic = value);
    _notifySettingsChanged();
    if (!value) {
      unawaited(_pausePreviewAudioPlayback());
      return;
    }
    if (_hasAudioSource) {
      unawaited(_preparePreviewAudio());
    } else {
      unawaited(_ensureMusicResolved(notifyOnMissing: true));
    }
  }

  void _setShowCornerInfo(bool value) {
    final controller = _configurationController;
    if (controller == null) return;
    controller.showCornerInfo = value;
    setState(() {});
    _notifySettingsChanged();
    _previewController?.showCornerInfo = value;
    _previewRenderer?.updateShowCornerInfo(value);
    _queuePreviewFrame();
  }

  void _setShowDetailedPerformanceInfo(bool value) {
    final controller = _configurationController;
    if (controller == null) return;
    controller.showDetailedPerformanceInfo = value;
    setState(() {});
    _notifySettingsChanged();
    _previewController?.showDetailedPerformanceInfo = value;
    _previewRenderer?.updateShowDetailedPerformanceInfo(value);
    _queuePreviewFrame();
  }

  void _schedulePreviewRebuild() {
    if (_disposed || _task != null) return;
    final generation = ++_previewSettingsGeneration;
    _previewRebuildTimer?.cancel();
    _previewRebuildTimer = Timer(const Duration(milliseconds: 180), () {
      _previewRebuildChain = _previewRebuildChain.then((_) async {
        if (_disposed || _task != null) return;
        if (generation != _previewSettingsGeneration) return;
        await _releasePreview();
        if (_disposed || _task != null) return;
        if (generation != _previewSettingsGeneration) return;
        _startPreviewPreparation();
      });
    });
  }

  void _attachTask(
    SimaiVideoExportTask task, {
    bool notifyOnCompletion = false,
  }) {
    _taskSubscription?.cancel();
    _elapsedTimer?.cancel();
    _task = task;
    _taskProgress = task.currentProgress;
    _taskResult = task.completedResult;
    _taskError = task.terminalError;
    _taskSubscription = task.progress.listen((progress) {
      if (!mounted || !identical(_task, task)) return;
      setState(() => _taskProgress = progress);
    });
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && identical(_task, task) && task.isRunning) {
        setState(() {});
      }
    });
    final completionCallback = notifyOnCompletion
        ? widget.onVideoExported
        : null;
    unawaited(
      task.result.then(
        (result) {
          completionCallback?.call(result);
          if (!mounted || !identical(_task, task)) return;
          _elapsedTimer?.cancel();
          setState(() {
            _taskResult = result;
            _taskError = null;
            _taskProgress = task.currentProgress;
          });
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted || !identical(_task, task)) return;
          _elapsedTimer?.cancel();
          setState(() {
            _taskError = error;
            _taskProgress = task.currentProgress;
          });
        },
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _confirmCancelExport() async {
    final task = _task;
    if (task == null || !task.isRunning || task.isCancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认取消导出？'),
        content: const Text('当前进度无法恢复，已生成的临时文件会被清理。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续导出'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('取消导出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {});
    await task.cancel();
    if (mounted) setState(() {});
  }

  void _closeProgressView() {
    SimaiVideoExporter.instance.clearLastCompletedTask(_task);
    Navigator.of(context).pop(_taskResult);
  }

  Future<void> _saveCompletedVideoToGallery() async {
    final result = _taskResult ?? _task?.completedResult;
    if (result == null || _savingToGallery || _localFileDeleted) return;
    setState(() => _savingToGallery = true);
    try {
      await SimaiVideoExporter.instance.saveToGallery(result);
      SimaiVideoExporter.instance.clearLastCompletedTask(_task);
      if (!mounted) return;
      setState(() {
        _savedToGallery = true;
        _localFileDeleted = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('视频已保存到相册，本地导出文件已删除')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存到相册失败：$error')));
    } finally {
      if (mounted) setState(() => _savingToGallery = false);
    }
  }

  Future<void> _shareCompletedVideo() async {
    final task = _task;
    final result = _taskResult ?? task?.completedResult;
    if (result == null || _sharingVideo || _localFileDeleted) return;
    setState(() => _sharingVideo = true);
    try {
      await SimaiVideoExporter.instance.share(
        result,
        text: task?.metadata.title,
      );
      SimaiVideoExporter.instance.clearLastCompletedTask(_task);
      if (!mounted) return;
      setState(() {
        _shareSheetOpened = true;
        _localFileDeleted = true;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('无法打开分享面板：$error')));
    } finally {
      if (mounted) setState(() => _sharingVideo = false);
    }
  }

  Future<void> _startExport() async {
    if (_task != null ||
        _loadingSupport ||
        _resolvingAudio ||
        !_selectedQualitySupported) {
      return;
    }
    _notifySettingsChanged();
    _previewSettingsGeneration++;
    _previewRebuildTimer?.cancel();
    await _previewRebuildChain;
    await _pausePreviewAudioPlayback();
    await _disposePreviewAudio();
    await _releasePreview();
    if (!mounted) return;
    try {
      final task = SimaiVideoExporter.instance.export(
        controller: _settingsController,
        metadata: widget.metadata,
        options: _selectedOptions,
        displayFont: widget.displayFont,
        textStyleResolver: widget.textStyleResolver,
        prepareFonts: widget.prepareFonts,
      );
      _attachTask(task, notifyOnCompletion: true);
    } on SimaiVideoExportException catch (error) {
      if (error.code == 'busy') {
        final activeTask = SimaiVideoExporter.instance.activeTask;
        if (activeTask != null) {
          _attachTask(activeTask);
          return;
        }
      }
      _startPreviewPreparation();
      if (_includeMusic) unawaited(_preparePreviewAudio());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('无法开始导出：$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = _task;
    final displayMetadata = task?.metadata ?? widget.metadata;
    final theme = Theme.of(context);
    final appBarForeground =
        theme.appBarTheme.titleTextStyle?.color ??
        theme.appBarTheme.foregroundColor ??
        theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '视频导出',
              style:
                  (theme.appBarTheme.titleTextStyle ??
                          theme.textTheme.titleMedium)
                      ?.copyWith(
                        color: appBarForeground,
                        fontSize: theme.textTheme.titleMedium?.fontSize,
                        fontWeight: FontWeight.w700,
                      ),
            ),
            Text(
              displayMetadata.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: appBarForeground.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        bottom: task == null
            ? TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: '选项'),
                  Tab(text: '预览'),
                ],
              )
            : null,
      ),
      body: task == null
          ? TabBarView(
              controller: _tabController,
              children: [_buildOptionsTab(theme), _buildPreviewTab(theme)],
            )
          : _buildProgressView(theme, task),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final task = _task;
    late final VoidCallback? onPressed;
    late final Widget icon;
    late final String label;
    ButtonStyle? style;
    if (task == null) {
      onPressed = _loadingSupport || _resolvingAudio || !_selectedQualitySupported
          ? null
          : _startExport;
      icon = const Icon(Icons.file_upload_outlined);
      label = _loadingSupport
          ? '正在检查编码器…'
          : _resolvingAudio
          ? '正在准备音源…'
          : _supportError != null
          ? '无法检测硬件编码器'
          : _selectedQualitySupported
          ? '导出 ${_quality.label} · 约 ${_formatBytes(_estimatedFileSizeBytes)}'
          : '当前设备不支持所选规格';
    } else if (task.isRunning) {
      onPressed = task.isCancelling ? null : _confirmCancelExport;
      icon = task.isCancelling
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.close);
      label = task.isCancelling ? '正在取消…' : '取消导出';
      style = FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
      );
    } else {
      onPressed = _closeProgressView;
      icon = Icon(
        _taskResult != null ? Icons.check_circle_outline : Icons.close,
      );
      label = _taskResult != null ? '完成' : '关闭';
    }
    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            style: style,
            onPressed: onPressed,
            icon: icon,
            label: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressView(ThemeData theme, SimaiVideoExportTask task) {
    final progress = _taskProgress ?? task.currentProgress;
    final result = _taskResult ?? task.completedResult;
    final error = _taskError ?? task.terminalError;
    final elapsed = DateTime.now().difference(task.startedAt);
    final percent = (progress.overallFraction * 100).clamp(0.0, 100.0);
    final displayedSize =
        result?.fileSizeBytes ??
        progress.estimatedFileSizeBytes ??
        task.estimatedFileSizeBytes ??
        0;
    final phaseLabel = task.isCancelling
        ? '正在取消导出…'
        : switch (progress.phase) {
            SimaiVideoExportPhase.preparing => '正在准备渲染资源',
            SimaiVideoExportPhase.rendering => '正在渲染并编码视频',
            SimaiVideoExportPhase.mixingAudio => '正在混合音乐和正解音',
            SimaiVideoExportPhase.muxing => '正在封装 MP4',
            SimaiVideoExportPhase.completed => '导出完成',
            SimaiVideoExportPhase.cancelled => '导出已取消',
            SimaiVideoExportPhase.failed => '导出失败',
          };
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      phaseLabel,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: progress.overallFraction.clamp(0.0, 1.0),
                minHeight: 10,
                borderRadius: BorderRadius.circular(999),
              ),
              if (progress.totalFrames > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${progress.completedFrames} / ${progress.totalFrames} 帧',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.65,
          children: [
            _ProgressMetric(
              label: '已用时间',
              value: _formatDuration(elapsed),
              icon: Icons.timer_outlined,
            ),
            _ProgressMetric(
              label: '预计剩余',
              value: result != null
                  ? '0 秒'
                  : progress.estimatedRemaining == null
                  ? '计算中'
                  : _formatDuration(progress.estimatedRemaining!),
              icon: Icons.hourglass_bottom,
            ),
            _ProgressMetric(
              label: result != null ? '文件大小' : '预估大小',
              value: _formatBytes(displayedSize),
              icon: Icons.data_usage_outlined,
            ),
            _ProgressMetric(
              label: '输出规格',
              value: task.options.quality == SimaiVideoQuality.hd720
                  ? '720p · 60fps'
                  : '1080p · 60fps',
              icon: Icons.high_quality_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (result != null) ...[
          _buildCompletedActions(theme),
          const SizedBox(height: 16),
        ],
        if (task.isRunning)
          const _ProgressNotice(
            icon: Icons.open_in_new,
            text: '可以切到后台或退出此页面，导出会通过通知栏持续进行。再次点击导出或通知栏即可回到这里。',
          ),
        if (result != null)
          _ProgressNotice(
            icon: Icons.check_circle_outline,
            text: _localFileDeleted
                ? _savedToGallery
                      ? '视频已保存到相册，本地导出文件已自动删除。'
                      : '系统分享面板已打开，本地导出文件已自动删除。'
                : '视频已保存到：${result.path}',
            color: theme.colorScheme.primary,
          ),
        if (error != null && error is SimaiVideoExportCancelledException)
          const _ProgressNotice(
            icon: Icons.cancel_outlined,
            text: '导出已取消，临时文件已清理。',
          ),
        if (error != null && error is! SimaiVideoExportCancelledException)
          _ProgressNotice(
            icon: Icons.error_outline,
            text: '导出失败：$error',
            color: theme.colorScheme.error,
          ),
      ],
    );
  }

  Widget _buildCompletedActions(ThemeData theme) {
    Widget actionProgressIndicator() => SizedBox.square(
      dimension: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.colorScheme.primary,
      ),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _savingToGallery || _localFileDeleted
                ? null
                : _saveCompletedVideoToGallery,
            icon: _savingToGallery
                ? actionProgressIndicator()
                : Icon(
                    _savedToGallery
                        ? Icons.check_circle_outline
                        : Icons.photo_library_outlined,
                  ),
            label: Text(_savedToGallery ? '已保存到相册' : '保存到相册'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _sharingVideo || _localFileDeleted
                ? null
                : _shareCompletedVideo,
            icon: _sharingVideo
                ? actionProgressIndicator()
                : Icon(
                    _shareSheetOpened
                        ? Icons.check_circle_outline
                        : Icons.ios_share_outlined,
                  ),
            label: Text(_shareSheetOpened ? '已打开分享' : '分享'),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsTab(ThemeData theme) {
    final controller = _settingsController;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _buildSectionHeader(theme, '导出设置'),
        _buildSegmentedSetting<SimaiVideoQuality>(
          theme,
          label: '画面规格',
          icon: Icons.high_quality_outlined,
          value: _quality,
          segments: SimaiVideoQuality.values
              .map(
                (quality) => ButtonSegment(
                  value: quality,
                  label: Text(
                    quality == SimaiVideoQuality.hd720 ? '720p' : '1080p',
                  ),
                  enabled: _loadingSupport || _qualitySupport[quality] == true,
                ),
              )
              .toList(growable: false),
          onChanged: _loadingSupport
              ? null
              : (quality) {
                  setState(() => _quality = quality);
                  _notifySettingsChanged();
                },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 10, 0, 0),
          child: Text(
            '${_quality.label} · 60fps · H.264/AAC',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        _buildSectionHeader(theme, '显示设置'),
        _buildSegmentedSetting<SimaiMirrorMode>(
          theme,
          label: '镜像',
          icon: Icons.flip,
          value: controller.mirrorMode,
          segments: const [
            ButtonSegment(value: SimaiMirrorMode.none, label: Text('无')),
            ButtonSegment(value: SimaiMirrorMode.horizontal, label: Text('左右')),
            ButtonSegment(value: SimaiMirrorMode.vertical, label: Text('上下')),
            ButtonSegment(value: SimaiMirrorMode.full, label: Text('全反')),
          ],
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.mirrorMode = value,
          ),
        ),
        const SizedBox(height: 16),
        _buildSegmentedSetting<SimaiBackgroundMode>(
          theme,
          label: '判定线',
          icon: Icons.blur_on,
          value: controller.backgroundMode,
          segments: const [
            ButtonSegment(value: SimaiBackgroundMode.none, label: Text('无')),
            ButtonSegment(value: SimaiBackgroundMode.dots, label: Text('点')),
            ButtonSegment(
              value: SimaiBackgroundMode.judgeLine,
              label: Text('线'),
            ),
            ButtonSegment(
              value: SimaiBackgroundMode.judgeZone,
              label: Text('区'),
            ),
          ],
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.backgroundMode = value,
          ),
        ),
        _buildSliderSetting(
          theme,
          label: '流速',
          icon: Icons.speed,
          value: controller.speed,
          min: 3,
          max: 9,
          divisions: 24,
          valueSuffix: 'x${controller.speed.toStringAsFixed(2)}',
          onChanged: (value) =>
              _updateVisualSetting((controller) => controller.speed = value),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          theme,
          label: '星星旋转',
          icon: Icons.rotate_right,
          value: controller.rotateSlideStar,
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.rotateSlideStar = value,
          ),
        ),
        _buildSwitchSetting(
          theme,
          label: '粉色星星头',
          icon: Icons.star,
          value: controller.pinkSlideStar,
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.pinkSlideStar = value,
          ),
        ),
        _buildSwitchSetting(
          theme,
          label: '标准色绝赞星星',
          icon: Icons.star_border,
          value: controller.standardBreakSlide,
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.standardBreakSlide = value,
          ),
        ),
        _buildSwitchSetting(
          theme,
          label: 'Approach Line',
          icon: Icons.timeline,
          value: controller.showApproachLine,
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.showApproachLine = value,
          ),
        ),
        _buildSwitchSetting(
          theme,
          label: '打击特效',
          icon: Icons.auto_awesome,
          value: controller.showHitEffects,
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.showHitEffects = value,
          ),
        ),
        const SizedBox(height: 16),
        _buildSegmentedSetting<SimaiCenterDisplayMode>(
          theme,
          label: '中央显示',
          icon: Icons.swap_vert,
          value: controller.centerDisplayMode,
          segments: const [
            ButtonSegment(
              value: SimaiCenterDisplayMode.achievement,
              label: Text('达成率'),
            ),
            ButtonSegment(
              value: SimaiCenterDisplayMode.combo,
              label: Text('Combo'),
            ),
          ],
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.centerDisplayMode = value,
          ),
        ),
        _buildSwitchSetting(
          theme,
          label: '显示达成率',
          icon: Icons.percent,
          value: controller.showAchievementRate,
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.showAchievementRate = value,
          ),
        ),
        _buildSwitchSetting(
          theme,
          label: '高亮保护套',
          icon: Icons.brightness_high,
          value: controller.highlightExNotes,
          onChanged: (value) => _updateVisualSetting(
            (controller) => controller.highlightExNotes = value,
          ),
        ),
        _buildSwitchSetting(
          theme,
          label: '四角信息',
          icon: Icons.dashboard_customize_outlined,
          value: controller.showCornerInfo,
          onChanged: _setShowCornerInfo,
        ),
        _buildSwitchSetting(
          theme,
          label: '详细性能信息',
          icon: Icons.monitor_heart_outlined,
          value: controller.showDetailedPerformanceInfo,
          onChanged: _setShowDetailedPerformanceInfo,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        _buildSectionHeader(theme, '音频设置'),
        _buildSwitchSetting(
          theme,
          label: '背景音乐（音源）',
          icon: Icons.library_music_outlined,
          value: _includeMusic,
          enabled: !_resolvingAudio,
          onChanged: _setIncludeMusic,
        ),
        _buildSwitchSetting(
          theme,
          label: '正解音播放',
          icon: Icons.music_note,
          value: _audioEnabled && controller.hitSoundEnabled,
          enabled: _audioEnabled,
          onChanged: (value) => _updateAudioSetting(
            (controller) => controller.hitSoundEnabled = value,
          ),
        ),
        _buildSliderSetting(
          theme,
          label: '音乐音量',
          icon: Icons.volume_up,
          value: controller.musicVolume,
          min: 0,
          max: 1,
          divisions: 100,
          enabled: _audioEnabled,
          valueSuffix: '${(controller.musicVolume * 100).toInt()}%',
          onChanged: (value) => _updateAudioSetting(
            (controller) => controller.musicVolume = value,
          ),
        ),
        _buildSliderSetting(
          theme,
          label: '音乐偏移',
          icon: Icons.audiotrack,
          value: controller.musicOffsetMs.toDouble(),
          min: -2000,
          max: 2000,
          divisions: 400,
          enabled: _audioEnabled,
          valueSuffix: '${controller.musicOffsetMs}ms',
          onChanged: (value) => _updateAudioSetting(
            (controller) => controller.musicOffsetMs = value.toInt(),
          ),
        ),
        _buildSliderSetting(
          theme,
          label: '正解音偏移',
          icon: Icons.timer,
          value: controller.hitSoundOffsetMs.toDouble(),
          min: -200,
          max: 200,
          divisions: 40,
          enabled: _audioEnabled && controller.hitSoundEnabled,
          valueSuffix: '${controller.hitSoundOffsetMs}ms',
          onChanged: (value) => _updateAudioSetting(
            (controller) => controller.hitSoundOffsetMs = value.toInt(),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        const _ExportNotice(),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSegmentedSetting<T>(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required T value,
    required List<ButtonSegment<T>> segments,
    required ValueChanged<T>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(label, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            segments: segments,
            selected: {value},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: onChanged == null
                ? null
                : (selection) => onChanged(selection.first),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    );
  }

  Widget _buildSliderSetting(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? valueSuffix,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.disabledColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: enabled ? null : theme.disabledColor,
                    ),
                  ),
                ),
                if (valueSuffix != null)
                  Text(
                    valueSuffix,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: enabled
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = math.max(160.0, constraints.maxHeight - 104);
        final previewWidth = math.min(
          math.max(120.0, constraints.maxWidth - 32),
          availableHeight * SimaiVideoLayout.aspectRatio,
        );
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: previewWidth,
                  height: previewWidth / SimaiVideoLayout.aspectRatio,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.35),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: _buildPreviewCanvas(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: '重新开始',
                    onPressed: _previewReady ? _restartPreview : null,
                    icon: const Icon(Icons.replay),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: _previewReady
                        ? () => _setPreviewPlaying(!_previewPlaying)
                        : null,
                    icon: Icon(
                      _previewPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    label: Text(_previewPlaying ? '暂停' : '播放'),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${_formatTime(_previewTime)} / '
                    '${_formatTime(_previewDuration)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPreviewCanvas() {
    final error = _previewError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '预览生成失败\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    final image = _previewImage;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RawImage(
      image: image,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }

  static String _formatTime(double seconds) {
    final totalSeconds = seconds.isFinite
        ? seconds.clamp(0.0, double.infinity).floor()
        : 0;
    final minutes = totalSeconds ~/ 60;
    final remainder = totalSeconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds ~/ 60) % 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours 小时 ${minutes.toString().padLeft(2, '0')} 分';
    }
    if (minutes > 0) {
      return '$minutes 分 ${seconds.toString().padLeft(2, '0')} 秒';
    }
    return '$seconds 秒';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '—';
    final megabytes = bytes / (1024 * 1024);
    if (megabytes < 1024) return '${megabytes.toStringAsFixed(1)} MB';
    return '${(megabytes / 1024).toStringAsFixed(2)} GB';
  }
}

class _ExportNotice extends StatelessWidget {
  const _ExportNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '此页使用独立的配置副本，改动会自动记住且不影响播放器。预览与成片读取同一份配置，固定按 1× 时间轴输出。',
            style: TextStyle(color: color, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 17, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _ProgressNotice({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: effectiveColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: effectiveColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
