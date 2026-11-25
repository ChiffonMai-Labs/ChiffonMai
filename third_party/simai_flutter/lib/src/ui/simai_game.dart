import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../../simai_flutter.dart';
import 'simai_colors.dart';
import 'components/chart_status_text_component.dart';
import 'components/chart_counter_overlay_component.dart';
import 'components/achievement_rate_component.dart';
import 'rendering/notes_batch_renderer.dart';
import 'utils/note_asset_manager.dart';
import 'rendering/precalc_data.dart';
import 'rendering/precalc_worker.dart';
import 'rendering/chart_runtime_index.dart';
import '../audio/soloud_audio_player.dart';
import 'gameplay/gameplay_hud_component.dart';
import 'note_geometry.dart';
import 'note_motion.dart';

typedef SimaiTextStyleResolver = TextStyle Function(TextStyle style);

@visibleForTesting
double hitSoundVoiceGain(int voiceCount, {double baseGain = 0.72}) {
  if (voiceCount <= 0) return 0.0;
  return baseGain / sqrt(voiceCount);
}

@visibleForTesting
bool shouldCompleteAtVisualEnd({required bool hasAudio}) => !hasAudio;

class SimaiGame extends FlameGame {
  final MaiChart chart;
  final bool headlessExport;
  final bool Function()? headlessExportCancelled;
  final SimaiGameplaySession? gameplaySession;
  final TextStyle? displayFont;
  final SimaiTextStyleResolver? textStyleResolver;
  bool isPlaying;
  double chartTime = 0.0;
  double ringApproachTime;
  double touchApproachTime;
  double playbackRate;
  double musicVolume;
  double _hitSoundOffset;
  double hitSoundVolume;
  bool _hitSoundEnabled;
  SimaiBackgroundMode backgroundMode;
  SimaiMirrorMode mirrorMode;
  bool rotateSlideStar;
  bool pinkSlideStar;
  bool standardBreakSlide;
  bool highlightExNotes;
  bool showApproachLine;
  bool showHitEffects;
  bool showGameplayInputPartitions;
  bool showGameplayTouchIndicators;
  bool showAchievementRate;
  SimaiCenterDisplayMode centerDisplayMode;
  bool showCornerInfo;
  bool showFps;
  bool showDetailedPerformanceInfo;
  final double chartRadiusRatio;
  final double gameplayContactRadiusRatio;
  VoidCallback? onPlaybackCompleted;
  ValueChanged<SimaiGameplayResult>? onGameplayCompleted;
  String? audioAsset;
  String? audioFilePath;
  ImageProvider? backgroundImageProvider;
  late final Stopwatch _monotonicClock;
  late final SoLoudAudioPlayer? _audioPlayer;
  double offset;
  StreamSubscription<SoLoudAudioClockSnapshot>? _clockSubscription;
  bool _audioClockAdvancing = false;
  bool _gameplayAudioCompleted = false;
  bool _gameplayCompletionSent = false;
  final SimaiGameplayEventClockMapper _eventClockMapper =
      SimaiGameplayEventClockMapper();
  int _chartAnchorClockUs = 0;
  double _chartAnchorTime = 0.0;
  final Map<int, Set<SimaiGameplayInputTarget>> _gameplayPointerInputs =
      <int, Set<SimaiGameplayInputTarget>>{};
  final Map<int, Offset> _gameplayPointerContacts = <int, Offset>{};
  bool _pendingSeekReset = false;
  bool _isSeeking = false;
  int _seekGeneration = 0;
  String _debugLastSeekReason = '';
  double _debugNextLogTime = 0.0;
  int _debugSeekCalls = 0;
  int _debugSeekResetsConsumed = 0;
  int _debugResizeCalls = 0;
  int _debugNotesAdded = 0;
  int _debugNotesRemoved = 0;
  int _debugAudioUpdates = 0;
  int _audioPositionUpdateCount = 0;
  int _debugAudioPosJumps = 0;
  int? _debugLastAudioPosMs;
  double _debugMaxAbsAudioError = 0.0;
  double _debugMaxAbsCorrection = 0.0;
  int _debugSfxPlayCalls = 0;
  int _debugSfxPoolPlays = 0;
  int _debugSfxFallbackPlays = 0;
  int _debugSfxPlayDrops = 0;
  int _debugFrameCount = 0;
  int _debugJank16Count = 0;
  int _debugJank32Count = 0;
  double _debugFrameTimeTotalMs = 0.0;
  double _debugMaxFrameTimeMs = 0.0;
  int _debugRenderCount = 0;
  double _debugRenderTimeTotalMs = 0.0;
  double _debugMaxRenderTimeMs = 0.0;
  int _debugVisibleCollections = 0;
  int _debugBatchedSprites = 0;
  int _debugBatchFlushes = 0;
  final List<double> _debugGameplayInputTimesMs = <double>[];
  double gameplayInputP95Ms = 0.0;
  double gameplayInputMaxMs = 0.0;
  final Stopwatch _cadenceClock = Stopwatch()..start();
  int _cadenceWindowStartUs = 0;
  int _cadenceLastRenderUs = 0;
  int _cadenceFrames = 0;
  int _cadenceFrozenFrames = 0;
  double? _cadenceLastChartTime;
  final List<double> _cadenceIntervalsMs = <double>[];
  final List<double> _cadenceMotionStepsMs = <double>[];
  double measuredFps = 0.0;
  double frameIntervalP95Ms = 0.0;
  double motionStepP95Ms = 0.0;
  double frozenFrameRatio = 0.0;
  int _debugPrecalcCompleted = 0;
  late final int _debugPrecalcTotal = chart.noteCollections.fold<int>(
    0,
    (total, collection) =>
        total +
        collection.fold<int>(0, (sum, note) => sum + note.slidePaths.length),
  );

  SoLoudAudioClockSnapshot? _audioClockSnapshot;
  bool isResourcesLoaded = false;

  PrecalcChartData precalcData = PrecalcChartData();
  late final ChartRuntimeIndex runtimeIndex = ChartRuntimeIndex.build(chart);
  late final double _contentDuration = computeChartContentEndTime(chart);
  late final double _visualDuration = _computeVisualDuration();

  static const double _hitSoundBaseOffsetSeconds = 0.0;
  static const double _sfxLookaheadSeconds = 0.080;
  static const double _sfxMaxLateSeconds = 0.045;
  static const int _sfxOverlapWindowMs = 80;
  List<int> _sfxEventTimesMs = const [];
  int _sfxEventIndex = 0;
  int _lastSfxCheckTimeMs = 0;
  SoLoud get _soloud => SoLoud.instance;
  AudioSource? _sfxSource;
  final Queue<SoundHandle> _sfxVoices = Queue<SoundHandle>();
  static const int _maxSfxVoices = 24;

  late final NoteAssetManager noteAssets;
  double noteScale = 1.0;
  double chartRadius = 0.0;
  Offset chartCenter = Offset.zero;

  SimaiGame({
    required this.chart,
    this.headlessExport = false,
    this.headlessExportCancelled,
    this.gameplaySession,
    this.displayFont,
    this.textStyleResolver,
    this.isPlaying = false,
    this.ringApproachTime = NoteMotion.defaultApproachTime,
    this.touchApproachTime =
        NoteMotion.defaultApproachTime * NoteMotion.touchApproachMultiplier,
    this.playbackRate = 1.0,
    this.musicVolume = 0.8,
    double hitSoundOffset = 0.0,
    this.hitSoundVolume = 0.72,
    bool hitSoundEnabled = true,
    this.backgroundMode = SimaiBackgroundMode.judgeLine,
    this.mirrorMode = SimaiMirrorMode.none,
    this.rotateSlideStar = true,
    this.pinkSlideStar = false,
    this.standardBreakSlide = false,
    this.highlightExNotes = false,
    this.showApproachLine = true,
    this.showHitEffects = true,
    this.showGameplayInputPartitions = false,
    this.showGameplayTouchIndicators = true,
    this.showAchievementRate = true,
    this.centerDisplayMode = SimaiCenterDisplayMode.achievement,
    this.showCornerInfo = true,
    this.showFps = true,
    this.showDetailedPerformanceInfo = false,
    this.chartRadiusRatio = 0.85,
    this.gameplayContactRadiusRatio =
        SimaiGameplayInputMapper.defaultContactRadiusRatio,
    this.onPlaybackCompleted,
    this.onGameplayCompleted,
    this.audioAsset,
    this.audioFilePath,
    this.backgroundImageProvider,
    double initialChartTime = 0.0,
    this.offset = 0.0,
  }) : assert(
         audioAsset == null || audioFilePath == null,
         'audioAsset and audioFilePath cannot both be set.',
       ),
       assert(
         chartRadiusRatio > 0 && chartRadiusRatio <= 1,
         'chartRadiusRatio must be within (0, 1].',
       ),
       assert(
         gameplayContactRadiusRatio.isFinite && gameplayContactRadiusRatio >= 0,
         'gameplayContactRadiusRatio must be finite and non-negative.',
       ),
       chartTime = initialChartTime,
       _hitSoundOffset = hitSoundOffset.isFinite ? hitSoundOffset : 0.0,
       _hitSoundEnabled = hitSoundEnabled {
    _monotonicClock = Stopwatch()..start();
    _audioPlayer = headlessExport ? null : SoLoudAudioPlayer(clock: _monotonicClock);
    _chartAnchorClockUs = _monotonicClock.elapsedMicroseconds;
    _chartAnchorTime = chartTime;
    // This package can host more than one player at a time. Keep Flame's image
    // ownership local to this game instead of using the process-wide cache.
    images = Images(prefix: 'assets/');
    noteAssets = NoteAssetManager(images: images);
    if (headlessExport) {
      measuredFps = 60.0;
      frameIntervalP95Ms = 1000.0 / 60.0;
      motionStepP95Ms = 1000.0 / 60.0;
      frozenFrameRatio = 0.0;
    }
    if (!isPlaying) {
      pauseEngine();
    }
  }

  bool get _hasAudio => audioAsset != null || audioFilePath != null;

  bool get hitSoundEnabled => _hitSoundEnabled;
  set hitSoundEnabled(bool value) {
    if (_hitSoundEnabled == value) return;
    _hitSoundEnabled = value;
    if (!value) {
      _stopSfxVoices();
    }
    _resyncSfxPosition();
  }

  double get hitSoundOffset => _hitSoundOffset;
  set hitSoundOffset(double value) {
    final safe = value.isFinite ? value : 0.0;
    if (_hitSoundOffset == safe) return;
    _hitSoundOffset = safe;
    _stopSfxVoices();
    _resyncSfxPosition();
  }

  TextStyle withDisplayFont(TextStyle style) {
    if (textStyleResolver != null) return textStyleResolver!(style);
    if (displayFont == null) return style;
    return style.copyWith(
      fontFamily: displayFont!.fontFamily,
      fontFamilyFallback: displayFont!.fontFamilyFallback,
    );
  }

  double get _effectiveHitSoundOffsetSeconds =>
      _hitSoundBaseOffsetSeconds + _hitSoundOffset;

  late final JudgeBackgroundComponent _backgroundComponent;
  late final NotesLayerComponent _notesComponent;
  ChartStatusTextComponent? _statusTextComponent;
  bool _notesReady = false;

  void refreshStatusText() => _statusTextComponent?.refreshNow();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    chartCenter = Offset(size.x / 2, size.y / 2);
    chartRadius = min(size.x, size.y) / 2 * chartRadiusRatio;
    noteScale = chartRadius / 300.0;

    // Use async context to rebuild assets
    final int rebuildGeneration = ++_assetRebuildGeneration;
    Future.microtask(() async {
      await _assetRebuildTask;
      if (rebuildGeneration != _assetRebuildGeneration) return;
      final task = noteAssets.rebuild(noteScale);
      _assetRebuildTask = task;
      await task;
      if (rebuildGeneration != _assetRebuildGeneration) return;
      invalidateNotes();
    });
  }

  int _assetRebuildGeneration = 0;
  Future<void>? _assetRebuildTask;

  @override
  Future<void> onLoad() async {
    ui.Image? sensorImage;
    try {
      sensorImage = await images.load('sensor.webp', package: 'simai_flutter');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sensor image load failed: $e');
      }
    }

    _backgroundComponent = JudgeBackgroundComponent(
      game: this,
      backgroundImageProvider: backgroundImageProvider,
      sensorImage: sensorImage,
    );
    _backgroundComponent.priority = -1;
    add(_backgroundComponent);

    _notesComponent = NotesLayerComponent(game: this);
    _notesReady = true;
    _notesComponent.priority = 1;
    add(_notesComponent);
    // Headless export advances by assigning an absolute chart time for every
    // frame while the game itself remains logically paused. A paused-layer
    // snapshot would therefore freeze the first rendered Note frame (often an
    // empty one) for the entire preview/export.
    _notesComponent.setSnapshotEnabled(!isPlaying && !headlessExport);

    if (!headlessExport) {
      final audioPlayer = _audioPlayer;
      if (audioPlayer != null) {
        _clockSubscription = audioPlayer.snapshots.listen((snapshot) {
          _debugAudioUpdates++;
          _audioPositionUpdateCount++;
          if (_isSeeking) return;
          final int ms = snapshot.position.inMilliseconds;

          final int? lastMs = _debugLastAudioPosMs;
          if (lastMs != null && (ms - lastMs).abs() > 500) {
            _debugAudioPosJumps++;
          }
          _debugLastAudioPosMs = ms;
          _audioClockSnapshot = snapshot;
          _audioClockAdvancing = snapshot.isAdvancing;
          if (snapshot.state == SoLoudAudioState.completed && isPlaying) {
            if (gameplaySession != null) {
              _gameplayAudioCompleted = true;
              _audioClockAdvancing = false;
              _audioClockSnapshot = null;
              _anchorChartClock();
            } else {
              setPlaying(false);
              onPlaybackCompleted?.call();
            }
          } else if (snapshot.state == SoLoudAudioState.error && isPlaying) {
            if (gameplaySession != null) {
              _gameplayAudioCompleted = true;
              _audioClockAdvancing = false;
              _audioClockSnapshot = null;
              _anchorChartClock();
            } else {
              setPlaying(false);
              onPlaybackCompleted?.call();
            }
          }
        });
      }

      try {
        await ensureSoLoudInitialized(_soloud);
        final assetPath = 'packages/simai_flutter/assets/answer.wav';
        try {
          if (kIsWeb) {
            _sfxSource = await _soloud.loadAsset(
              assetPath,
              mode: LoadMode.disk,
            );
          } else {
            _sfxSource = await _soloud.loadAsset(assetPath);
          }
          debugPrint('SFX: SoLoud loaded $assetPath');
        } catch (e) {
          debugPrint('SFX: SoLoud failed to load $assetPath: $e');
        }
      } catch (e) {
        debugPrint('SFX: SoLoud init failed: $e');
      }
      _rebuildSfxEventTimes();

      if (_hasAudio && audioPlayer != null) {
        try {
          if (audioFilePath != null) {
            await audioPlayer.loadFile(audioFilePath!);
          } else {
            await audioPlayer.loadAsset(audioAsset!);
          }
          await audioPlayer.setVolume(musicVolume);
          await audioPlayer.setRate(playbackRate);
          // Ensure state consistency if source set after isPlaying
          if (isPlaying) {
            unawaited(audioPlayer.play());
          }
        } catch (e) {
          debugPrint("Error loading audio source: $e");
          // 音乐时钟不可用时必须报告加载失败，不能继续等待时钟推进。
          rethrow;
        }
      }
    }

    if (gameplaySession == null) {
      final achievementIndex = CriticalAchievementIndex.build(chart);
      final counterIndex = ChartCounterIndex.build(chart);
      add(
        AchievementRateComponent(
          achievementIndex,
          comboAt: counterIndex.comboAt,
        )..priority = 0,
      );
      _statusTextComponent = ChartStatusTextComponent();
      add(_statusTextComponent!);
      add(
        ChartCounterOverlayComponent(
          counterIndex,
          achievementAt: achievementIndex.achievementAt,
        )..priority = 2,
      );
    } else {
      add(GameplayHudComponent(gameplaySession!)..priority = 3);
    }

    await _startPrecalculation();
    final session = gameplaySession;
    if (session != null && !session.isPrepared) {
      session.installSlideData(<String, SimaiGameplaySlideData>{
        for (final entry in precalcData.slides.entries)
          entry.key: entry.value.gameplay,
      });
    }
    // onGameResize schedules the scale-dependent image cache asynchronously.
    // Let that task register, then wait for it before exposing the first frame.
    await Future<void>.delayed(Duration.zero);
    await _assetRebuildTask;
    isResourcesLoaded = true;
    invalidateNotes(resetWindow: true);
    if (!headlessExport) {
      _requestPausedFrame();
    }
  }

  /// Initializes this game without attaching a [GameWidget]. This is used by
  /// the video exporter so the existing Flame renderer remains the single
  /// source of truth for live playback and encoded frames.
  Future<void> prepareHeadlessExport(Vector2 exportSize) async {
    if (!headlessExport) {
      throw StateError('prepareHeadlessExport requires headlessExport=true');
    }
    onGameResize(exportSize);
    // These lifecycle methods are public for Flame's embedding layer. Calling
    // them here gives headless export the same load/mount ordering as a widget.
    // ignore: invalid_use_of_internal_member
    await load();
    // ignore: invalid_use_of_internal_member
    mount();
    await ready();
    await _assetRebuildTask;
    await _backgroundComponent.waitUntilResolved();
    updateExportTime(chartTime, resetWindow: true);
  }

  void updateExportTime(double time, {bool resetWindow = false}) {
    if (!headlessExport) {
      throw StateError('updateExportTime requires headlessExport=true');
    }
    chartTime = time;
    if (resetWindow) {
      _pendingSeekReset = true;
      _notesComponent.invalidate(resetWindow: true);
    }
    super.update(1 / 60);
  }

  void disposeHeadlessExport() {
    if (!headlessExport) return;
    // ignore: invalid_use_of_internal_member
    finalizeRemoval();
  }

  int _precalcGeneration = 0;
  Future<void>? _precalcTask;
  SimaiMirrorMode? _requestedMirrorMode;
  final Map<SimaiMirrorMode, PrecalcChartData> _precalcCache = {};
  static const int _precalcCacheLimit = 2;

  Future<void> _startPrecalculation({
    SimaiMirrorMode? targetMirrorMode,
    bool atomicMirrorSwap = false,
  }) async {
    final targetMode = targetMirrorMode ?? mirrorMode;
    final generation = ++_precalcGeneration;
    final previousTask = _precalcTask;
    if (previousTask != null) {
      await previousTask;
      if (_precalculationCancelled(generation)) return;
    }

    final cached = _precalcCache[targetMode];
    if (cached != null) {
      // Refresh insertion order so the least recently used mode is evicted.
      _precalcCache
        ..remove(targetMode)
        ..[targetMode] = cached;
      if (atomicMirrorSwap) {
        _commitMirrorPrecalculation(targetMode, cached);
      } else {
        precalcData = cached;
        invalidateNotes();
      }
      return;
    }

    final targetData = PrecalcChartData();
    if (!atomicMirrorSwap) precalcData = targetData;

    final task = progressivePrecalcOnMain(
      chart,
      targetMode,
      (message) {
        if (_precalculationCancelled(generation)) return;
        targetData.merge(message);
        _debugPrecalcCompleted = targetData.slides.length;
        // A runtime mirror change keeps presenting the previous complete frame
        // until the requested mode is fully ready. Initial loading remains
        // progressive so large charts still reach first paint quickly.
        if (!atomicMirrorSwap) invalidateNotes();
      },
      () => _precalculationCancelled(generation),
      priorityTime: chartTime,
    );
    _precalcTask = task;
    await task;
    if (_precalculationCancelled(generation)) return;
    _precalcCache[targetMode] = targetData;
    while (_precalcCache.length > _precalcCacheLimit) {
      _precalcCache.remove(_precalcCache.keys.first);
    }
    _debugPrecalcCompleted = targetData.slides.length;
    if (atomicMirrorSwap) {
      _commitMirrorPrecalculation(targetMode, targetData);
    }
  }

  bool _precalculationCancelled(int generation) =>
      generation != _precalcGeneration ||
      (headlessExport && (headlessExportCancelled?.call() ?? false));

  void _commitMirrorPrecalculation(
    SimaiMirrorMode targetMode,
    PrecalcChartData targetData,
  ) {
    if (_requestedMirrorMode != null && _requestedMirrorMode != targetMode) {
      return;
    }
    mirrorMode = targetMode;
    _requestedMirrorMode = null;
    precalcData = targetData;
    _notesComponent.clearSlideCaches();
    _backgroundComponent.requestBackgroundRedraw();
    invalidateNotes(resetWindow: true);
  }

  @override
  void onRemove() {
    _precalcGeneration++;
    _assetRebuildGeneration++;
    _notesReady = false;
    noteAssets.dispose();
    images.clearCache();
    _precalcCache.clear();
    _cadenceIntervalsMs.clear();
    _cadenceMotionStepsMs.clear();
    _sfxEventTimesMs = const [];
    _clockSubscription?.cancel();
    final audioPlayer = _audioPlayer;
    if (audioPlayer != null) {
      unawaited(audioPlayer.dispose());
    }
    final src = _sfxSource;
    _sfxSource = null;
    _stopSfxVoices();
    if (src != null) {
      _soloud.disposeSource(src);
    }
    super.onRemove();
  }

  void setPlaying(bool playing) {
    if (isPlaying == playing) return;
    isPlaying = playing;
    if (playing) {
      _anchorChartClock();
      if (_notesReady) {
        _notesComponent.setSnapshotEnabled(false);
      }
      resumeEngine();
      _resetCadenceWindow();
      _stopSfxVoices();
      _resyncSfxPosition();
      final audioPlayer = _audioPlayer;
      if (_hasAudio && audioPlayer != null) {
        audioPlayer.play().catchError((e) {
          debugPrint("Audio resume failed: $e");
        });
      }
      // SoLoud state events start the clock only when playback is ready.
    } else {
      clearGameplayPointers();
      _stopSfxVoices();
      _resyncSfxPosition();
      final audioPlayer = _audioPlayer;
      if (_hasAudio && audioPlayer != null) {
        audioPlayer.pause();
      }
      if (_notesReady) {
        _notesComponent.setSnapshotEnabled(!headlessExport);
      }
      pauseEngine();
    }
  }

  Future<void> setPlaybackRate(double rate) async {
    final safe = rate.isFinite ? rate : 1.0;
    final clamped = safe.clamp(0.1, 3.0).toDouble();
    if (playbackRate == clamped) return;
    _anchorChartClock();
    playbackRate = clamped;
    _stopSfxVoices();
    _resyncSfxPosition();
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null) return;
    try {
      await audioPlayer.setRate(clamped);
    } catch (e) {
      debugPrint("Audio setPlaybackRate failed: $e");
    }
  }

  Future<void> setMusicVolume(double volume) async {
    final safe = volume.isFinite ? volume : 0.8;
    final clamped = safe.clamp(0.0, 1.0).toDouble();
    if (musicVolume == clamped) return;
    musicVolume = clamped;
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null) return;
    try {
      await audioPlayer.setVolume(clamped);
    } catch (e) {
      debugPrint("Audio setVolume failed: $e");
    }
  }

  void setHitSoundVolume(double volume) {
    final safe = volume.isFinite ? volume : 0.72;
    final clamped = safe.clamp(0.0, 1.0).toDouble();
    if (hitSoundVolume == clamped) return;
    hitSoundVolume = clamped;
  }

  void setBackgroundMode(SimaiBackgroundMode mode) {
    if (backgroundMode == mode) return;
    backgroundMode = mode;
    _backgroundComponent.requestBackgroundRedraw();
    _requestPausedFrame();
  }

  void setMirrorMode(SimaiMirrorMode mode) {
    if ((_requestedMirrorMode ?? mirrorMode) == mode) return;
    _requestedMirrorMode = mode;
    unawaited(
      _startPrecalculation(targetMirrorMode: mode, atomicMirrorSwap: true),
    );
  }

  void setAudioAsset(String? asset) {
    if (audioAsset == asset) return;
    audioAsset = asset;
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null) return;
    if (asset != null) {
      audioPlayer
          .loadAsset(asset)
          .then((_) {
            audioPlayer.setVolume(musicVolume);
            audioPlayer.setRate(playbackRate);
            if (isPlaying) {
              audioPlayer.play();
            }
          })
          .catchError((e) {
            debugPrint("Error setting audio source: $e");
          });
    } else {
      audioPlayer.stop();
    }
  }

  void setAudioFilePath(String? path) {
    if (audioFilePath == path) return;
    audioFilePath = path;
    final audioPlayer = _audioPlayer;
    if (audioPlayer == null) return;
    if (path != null) {
      audioAsset = null;
      audioPlayer
          .loadFile(path)
          .then((_) {
            audioPlayer.setVolume(musicVolume);
            audioPlayer.setRate(playbackRate);
            if (isPlaying) {
              audioPlayer.play();
            }
          })
          .catchError((e) {
            debugPrint("Error setting audio file: $e");
          });
    } else if (audioAsset == null) {
      audioPlayer.stop();
    }
  }

  Future<void> seek(double time, {bool syncAudio = true}) async {
    final int generation = ++_seekGeneration;
    double settledChartTime = time;
    _isSeeking = true;
    // 计算目标音频位置；保留 rawAudioPos 用于判断是否仍处于前奏负偏移区间。
    final double rawAudioPos = time - offset;
    final double audioPos = rawAudioPos < 0 ? 0.0 : rawAudioPos;

    chartTime = time;
    _pendingSeekReset = true;
    invalidateNotes(resetWindow: true);
    _debugSeekCalls++;
    _debugLastSeekReason = 'seek(syncAudio=$syncAudio)';
    _stopSfxVoices();
    _resyncSfxPosition();

    final audioPlayer = _audioPlayer;
    if (syncAudio && _hasAudio && audioPlayer != null) {
      final int targetAudioUs = (audioPos * 1000000).round();
      final bool wasPlaying = isPlaying;
      try {
        // 拖动时间轴或跳转音符前先暂停音频，避免异步解码器状态覆盖目标时间。
        await audioPlayer.pause();
        await audioPlayer.seek(Duration(microseconds: targetAudioUs));

        if (generation != _seekGeneration) return;

        // 仅在播放中且处于音频正片区间时同步解码器位置；暂停态保持精确的谱面时间，
        // 防止 MP3 帧对齐导致时间回退到音符之前。
        final settled = audioPlayer.latestSnapshot;
        if (settled != null) {
          _audioClockSnapshot = settled;
          if (wasPlaying && rawAudioPos >= 0) {
            settledChartTime =
                settled.position.inMicroseconds / 1000000.0 + offset;
          }
        }
        if (wasPlaying) {
          unawaited(audioPlayer.play());
        }
      } catch (e) {
        debugPrint("Seek failed: $e");
      }
    }

    // Audio backends and the game loop continue producing callbacks while the
    // asynchronous seek is in flight. Re-assert the target and visible window
    // after the backend has settled so stale playback state cannot win.
    if (generation == _seekGeneration) {
      chartTime = settledChartTime;
      _pendingSeekReset = true;
      invalidateNotes(resetWindow: true);
      _stopSfxVoices();
      _resyncSfxPosition();
      _isSeeking = false;
    }
  }

  void invalidateNotes({bool resetWindow = false}) {
    if (!_notesReady) return;
    _notesComponent.invalidate(resetWindow: resetWindow);
    if (isResourcesLoaded) {
      _requestPausedFrame();
    }
  }

  void _requestPausedFrame({double stepTime = 1 / 30}) {
    if (headlessExport) return;
    if (!isPlaying && paused) {
      stepEngine(stepTime: stepTime);
    }
  }

  double get totalDuration => _contentDuration;

  double get totalVisualDuration => _visualDuration;

  double _computeVisualDuration() {
    double maxTime = totalDuration;
    for (final collection in chart.noteCollections) {
      for (final note in collection) {
        if (note.location.group == NoteGroup.tap) continue;
        if ((note.styles & NoteStyles.fireworks) == 0) continue;

        final double eventTime =
            collection.time +
            ((note.type == NoteType.hold && (note.length ?? 0) > 0)
                ? (note.length ?? 0)
                : 0.0);
        final double visualEndTime =
            eventTime + NotesBatchRenderer.touchFireworksRippleDuration;
        if (visualEndTime > maxTime) {
          maxTime = visualEndTime;
        }
      }
    }
    return maxTime;
  }

  void setBackgroundImageProvider(ImageProvider? provider) {
    if (backgroundImageProvider == provider) return;
    backgroundImageProvider = provider;
    // Check if _backgroundComponent is initialized before using it.
    // It might be accessed before onLoad completes if setState happens early.
    try {
      _backgroundComponent.setBackgroundImageProvider(provider);
      _requestPausedFrame();
    } catch (e) {
      // Ignore if not initialized yet.
      // It will be rendered in onGameResize or render loop once initialized.
    }
  }

  double renderTime = 0.0;

  bool consumeSeekReset() {
    final v = _pendingSeekReset;
    _pendingSeekReset = false;
    if (v) _debugSeekResetsConsumed++;
    return v;
  }

  @override
  void update(double dt) {
    renderTime += dt;
    if (isPlaying) {
      if (_isSeeking) {
        super.update(0.0001);
        return;
      }
      if (kDebugMode || kProfileMode) {
        final frameMs = dt * 1000.0;
        _debugFrameCount++;
        _debugFrameTimeTotalMs += frameMs;
        if (frameMs > _debugMaxFrameTimeMs) _debugMaxFrameTimeMs = frameMs;
        if (frameMs > 16.7) _debugJank16Count++;
        if (frameMs > 33.3) _debugJank32Count++;
      }
      // Update chartTime first so components update against current time.
      // Sync logic:
      // 1. If we are in the intro period (chartTime < offset), accumulate dt.
      // 2. If we have a valid audio position, sync to it.
      // 3. Otherwise, accumulate dt.
      if (_hasAudio && !_gameplayAudioCompleted && chartTime >= offset) {
        final snapshot = _audioClockSnapshot;
        if (snapshot == null || !_audioClockAdvancing) {
          // Do not let visuals run ahead while audio is loading,
          // buffering, paused, or settling after a seek.
          if (snapshot != null) {
            chartTime = snapshot.position.inMicroseconds / 1000000.0 + offset;
          }
        } else {
          final position = snapshot.positionAt(
            _audioPlayer?.monotonicNow ?? _monotonicClock.elapsed,
          );
          final nextChartTime = position.inMicroseconds / 1000000.0 + offset;
          final double absError = (nextChartTime - chartTime).abs();
          chartTime = nextChartTime;
          if (absError > _debugMaxAbsAudioError) {
            _debugMaxAbsAudioError = absError;
          }
        }
      } else {
        // Fallback or intro period
        chartTime += dt * playbackRate;
      }

      _anchorChartClock();
      final session = gameplaySession;
      session?.advanceTo(chartTime);

      final double duration = totalVisualDuration;
      if (session == null &&
          shouldCompleteAtVisualEnd(hasAudio: _hasAudio) &&
          duration > 0 &&
          chartTime >= duration) {
        chartTime = duration;
        setPlaying(false);
        onPlaybackCompleted?.call();
      } else if (session != null &&
          !_gameplayCompletionSent &&
          (!_hasAudio || _gameplayAudioCompleted) &&
          session.isReadyForResult(chartTime)) {
        _gameplayCompletionSent = true;
        final result = session.buildResult();
        setPlaying(false);
        final callback = onGameplayCompleted;
        if (callback != null) {
          Future<void>.microtask(() => callback(result));
        }
      }

      // Only update logic when playing
      super.update(dt);
      if (session == null) _updateSfx();

      if ((kDebugMode || kProfileMode) && renderTime >= _debugNextLogTime) {
        gameplayInputP95Ms = _percentile95(_debugGameplayInputTimesMs);
        final avgFrameMs = _debugFrameCount == 0
            ? 0.0
            : _debugFrameTimeTotalMs / _debugFrameCount;
        final avgRenderMs = _debugRenderCount == 0
            ? 0.0
            : _debugRenderTimeTotalMs / _debugRenderCount;
        debugPrint(
          'SimaiPerf: t=${chartTime.toStringAsFixed(3)} '
          'cadence(fps=${measuredFps.toStringAsFixed(1)} '
          'intervalP95=${frameIntervalP95Ms.toStringAsFixed(2)}ms '
          'motionP95=${motionStepP95Ms.toStringAsFixed(2)}ms '
          'frozen=${(frozenFrameRatio * 100).toStringAsFixed(1)}%) '
          'frame(avg=${avgFrameMs.toStringAsFixed(2)}ms max=${_debugMaxFrameTimeMs.toStringAsFixed(2)}ms '
          'jank16=$_debugJank16Count jank32=$_debugJank32Count n=$_debugFrameCount) '
          'render(avg=${avgRenderMs.toStringAsFixed(2)}ms max=${_debugMaxRenderTimeMs.toStringAsFixed(2)}ms '
          'visible=$_debugVisibleCollections n=$_debugRenderCount '
          'batchSprites=$_debugBatchedSprites batchFlushes=$_debugBatchFlushes) '
          'precalc=$_debugPrecalcCompleted/$_debugPrecalcTotal '
          'seekCalls=$_debugSeekCalls seekResets=$_debugSeekResetsConsumed '
          'resizes=$_debugResizeCalls '
          'notes(+$_debugNotesAdded -$_debugNotesRemoved) '
          'audioUpdates=$_debugAudioUpdates audioJumps=$_debugAudioPosJumps '
          'maxErr=${_debugMaxAbsAudioError.toStringAsFixed(4)} '
          'maxCorr=${_debugMaxAbsCorrection.toStringAsFixed(4)} '
          'lastSeek=$_debugLastSeekReason '
          'input(p95=${gameplayInputP95Ms.toStringAsFixed(3)}ms '
          'max=${gameplayInputMaxMs.toStringAsFixed(3)}ms) '
          'sfx(calls=$_debugSfxPlayCalls soloud=$_debugSfxPoolPlays fb=$_debugSfxFallbackPlays drops=$_debugSfxPlayDrops enabled=${_sfxSource != null})',
        );
        _debugNextLogTime = renderTime + 1.0;
        _debugNotesAdded = 0;
        _debugNotesRemoved = 0;
        _debugAudioUpdates = 0;
        _debugAudioPosJumps = 0;
        _debugResizeCalls = 0;
        _debugMaxAbsAudioError = 0.0;
        _debugMaxAbsCorrection = 0.0;
        _debugSfxPlayCalls = 0;
        _debugSfxPoolPlays = 0;
        _debugSfxFallbackPlays = 0;
        _debugSfxPlayDrops = 0;
        _debugFrameCount = 0;
        _debugJank16Count = 0;
        _debugJank32Count = 0;
        _debugFrameTimeTotalMs = 0.0;
        _debugMaxFrameTimeMs = 0.0;
        _debugRenderCount = 0;
        _debugRenderTimeTotalMs = 0.0;
        _debugMaxRenderTimeMs = 0.0;
        _debugBatchedSprites = 0;
        _debugBatchFlushes = 0;
        _debugGameplayInputTimesMs.clear();
        gameplayInputP95Ms = 0.0;
        gameplayInputMaxMs = 0.0;
      }
    } else {
      // Paused games normally do not tick. This branch is reached only through
      // Flame's stepEngine() when a seek or setting change needs one fresh
      // frame, so components can update directly from the new absolute time.
      super.update(dt);
    }
  }

  void recordRenderMetrics({
    required double elapsedMs,
    required int visibleCollections,
    required int batchedSprites,
    required int batchFlushes,
  }) {
    _recordCadenceMetrics();
    if (!kDebugMode && !kProfileMode) return;
    _debugRenderCount++;
    _debugRenderTimeTotalMs += elapsedMs;
    if (elapsedMs > _debugMaxRenderTimeMs) {
      _debugMaxRenderTimeMs = elapsedMs;
    }
    _debugVisibleCollections = visibleCollections;
    _debugBatchedSprites += batchedSprites;
    _debugBatchFlushes += batchFlushes;
  }

  void _anchorChartClock() {
    _chartAnchorTime = chartTime;
    _chartAnchorClockUs = _monotonicClock.elapsedMicroseconds;
  }

  double gameplayChartTimeForEvent(Duration eventTimestamp) {
    final session = gameplaySession;
    if (session == null) return chartTime;
    final now = _monotonicClock.elapsed;
    final eventClock = _eventClockMapper.map(
      eventTimestamp: eventTimestamp,
      receiptTimestamp: now,
    );
    final eventClockUs = eventClock.inMicroseconds;

    double projected;
    final snapshot = _audioClockSnapshot;
    if (_hasAudio &&
        !_gameplayAudioCompleted &&
        snapshot != null &&
        snapshot.isAdvancing) {
      final position = snapshot.positionAt(eventClock);
      projected = position.inMicroseconds / 1000000.0 + offset;
    } else {
      projected =
          _chartAnchorTime +
          (eventClockUs - _chartAnchorClockUs) / 1000000.0 * playbackRate;
    }
    return projected + session.judgementOffsetSeconds;
  }

  @visibleForTesting
  SimaiGameplayLaneInput? gameplayInputAt(Offset position) {
    if (gameplaySession == null || chartRadius <= 0) return null;
    return SimaiGameplayLaneMapper.inputAt(
      position: position,
      center: chartCenter,
      radius: chartRadius,
      mirrorMode: mirrorMode,
    );
  }

  @visibleForTesting
  int? gameplayLaneAt(Offset position) => gameplayInputAt(position)?.lane;

  @visibleForTesting
  SimaiGameplayInputTarget? gameplayTargetAt(Offset position) {
    if (gameplaySession == null || chartRadius <= 0) return null;
    return SimaiGameplayInputMapper.targetAt(
      position: position,
      center: chartCenter,
      radius: chartRadius,
      mirrorMode: mirrorMode,
    );
  }

  @visibleForTesting
  Set<SimaiGameplayInputTarget> gameplayTargetsAt(Offset position) {
    if (gameplaySession == null || chartRadius <= 0) {
      return <SimaiGameplayInputTarget>{};
    }
    return SimaiGameplayInputMapper.targetsForContactCircle(
      position: position,
      center: chartCenter,
      radius: chartRadius,
      contactRadius: chartRadius * gameplayContactRadiusRatio,
      mirrorMode: mirrorMode,
    );
  }

  bool handleGameplayPointerDown({
    required int pointerId,
    required Offset position,
    required Duration eventTimestamp,
  }) {
    final startedAtUs = _monotonicClock.elapsedMicroseconds;
    try {
      final session = gameplaySession;
      if (session == null || !isPlaying) return false;
      final eventTime = gameplayChartTimeForEvent(eventTimestamp);
      _gameplayPointerContacts[pointerId] = position;
      final judged = _applyGameplayPointerTargets(
        session: session,
        pointerId: pointerId,
        targets: gameplayTargetsAt(position),
        eventTime: eventTime,
      );
      if (judged && hitSoundEnabled) _playDaSound();
      return judged;
    } finally {
      _recordGameplayInputTime(startedAtUs);
    }
  }

  void handleGameplayPointerMove({
    required int pointerId,
    required Offset position,
    required Duration eventTimestamp,
  }) {
    final startedAtUs = _monotonicClock.elapsedMicroseconds;
    try {
      final session = gameplaySession;
      if (session == null || !isPlaying) return;
      final eventTime = gameplayChartTimeForEvent(eventTimestamp);
      _gameplayPointerContacts[pointerId] = position;
      final judged = _applyGameplayPointerTargets(
        session: session,
        pointerId: pointerId,
        targets: gameplayTargetsAt(position),
        eventTime: eventTime,
      );
      if (judged && hitSoundEnabled) _playDaSound();
    } finally {
      _recordGameplayInputTime(startedAtUs);
    }
  }

  void handleGameplayPointerUp({
    required int pointerId,
    required Duration eventTimestamp,
  }) {
    final startedAtUs = _monotonicClock.elapsedMicroseconds;
    try {
      final session = gameplaySession;
      _gameplayPointerContacts.remove(pointerId);
      if (session == null) return;
      final judged = _applyGameplayPointerTargets(
        session: session,
        pointerId: pointerId,
        targets: <SimaiGameplayInputTarget>{},
        eventTime: gameplayChartTimeForEvent(eventTimestamp),
      );
      if (judged && hitSoundEnabled) _playDaSound();
    } finally {
      _recordGameplayInputTime(startedAtUs);
    }
  }

  bool _applyGameplayPointerTargets({
    required SimaiGameplaySession session,
    required int pointerId,
    required Set<SimaiGameplayInputTarget> targets,
    required double eventTime,
  }) {
    final previous =
        _gameplayPointerInputs[pointerId] ?? <SimaiGameplayInputTarget>{};
    if (setEquals(previous, targets)) return false;

    final judged = session.updatePointerTargets(
      pointerId: pointerId,
      releasedTargets: previous.difference(targets),
      pressedTargets: targets.difference(previous),
      chartTime: eventTime,
    );

    if (targets.isEmpty) {
      _gameplayPointerInputs.remove(pointerId);
    } else {
      _gameplayPointerInputs[pointerId] = Set<SimaiGameplayInputTarget>.of(
        targets,
      );
    }
    return judged;
  }

  void _recordGameplayInputTime(int startedAtUs) {
    if (!kDebugMode && !kProfileMode) return;
    final elapsedMs =
        (_monotonicClock.elapsedMicroseconds - startedAtUs) / 1000.0;
    _debugGameplayInputTimesMs.add(elapsedMs);
    if (elapsedMs > gameplayInputMaxMs) gameplayInputMaxMs = elapsedMs;
  }

  void clearGameplayPointers() {
    final session = gameplaySession;
    if (session == null) return;
    _gameplayPointerInputs.clear();
    _gameplayPointerContacts.clear();
    if (!session.isPrepared) return;
    session.clearPointers(chartTime);
  }

  int get audioPositionUpdateCount => _audioPositionUpdateCount;
  double? get latestAudioPositionSeconds {
    final snapshot = _audioClockSnapshot;
    if (snapshot == null) return null;
    final now = _audioPlayer?.monotonicNow ?? _monotonicClock.elapsed;
    return snapshot.positionAt(now).inMicroseconds / 1000000.0;
  }

  void _recordCadenceMetrics() {
    final nowUs = _cadenceClock.elapsedMicroseconds;
    if (_cadenceWindowStartUs == 0) _cadenceWindowStartUs = nowUs;

    if (_cadenceLastRenderUs != 0) {
      _cadenceIntervalsMs.add((nowUs - _cadenceLastRenderUs) / 1000.0);
    }
    _cadenceLastRenderUs = nowUs;
    _cadenceFrames++;

    final previousChartTime = _cadenceLastChartTime;
    if (previousChartTime != null) {
      final stepMs = (chartTime - previousChartTime).abs() * 1000.0;
      _cadenceMotionStepsMs.add(stepMs);
      if (stepMs < 0.05) _cadenceFrozenFrames++;
    }
    _cadenceLastChartTime = chartTime;

    final windowUs = nowUs - _cadenceWindowStartUs;
    if (windowUs < 1000000) return;

    measuredFps = _cadenceFrames * 1000000.0 / windowUs;
    frameIntervalP95Ms = _percentile95(_cadenceIntervalsMs);
    motionStepP95Ms = _percentile95(_cadenceMotionStepsMs);
    frozenFrameRatio = _cadenceMotionStepsMs.isEmpty
        ? 0.0
        : _cadenceFrozenFrames / _cadenceMotionStepsMs.length;

    _cadenceWindowStartUs = nowUs;
    _cadenceFrames = 0;
    _cadenceFrozenFrames = 0;
    _cadenceIntervalsMs.clear();
    _cadenceMotionStepsMs.clear();
  }

  void _resetCadenceWindow() {
    _cadenceWindowStartUs = _cadenceClock.elapsedMicroseconds;
    _cadenceLastRenderUs = 0;
    _cadenceFrames = 0;
    _cadenceFrozenFrames = 0;
    _cadenceLastChartTime = null;
    _cadenceIntervalsMs.clear();
    _cadenceMotionStepsMs.clear();
  }

  static double _percentile95(List<double> values) {
    if (values.isEmpty) return 0.0;
    final sorted = List<double>.of(values)..sort();
    final index = ((sorted.length - 1) * 0.95).round();
    return sorted[index];
  }

  void _updateSfx() {
    if (!hitSoundEnabled || playbackRate <= 0) return;
    final src = _sfxSource;
    if (src == null || !_soloud.isInitialized) return;

    final rate = playbackRate;
    final effectiveOffset = _effectiveHitSoundOffsetSeconds;
    final horizonChartSec =
        chartTime + (_sfxLookaheadSeconds - effectiveOffset) * rate;
    final horizonMs = (horizonChartSec * 1000).round();
    if (horizonMs < _lastSfxCheckTimeMs - 150) {
      _stopSfxVoices();
      _resyncSfxPosition();
    }
    _lastSfxCheckTimeMs = horizonMs;

    if (_sfxEventIndex >= _sfxEventTimesMs.length ||
        _sfxEventTimesMs[_sfxEventIndex] > horizonMs) {
      return;
    }

    Duration? engineNow;
    try {
      engineNow = _soloud.getEngineTime();
    } catch (_) {
      engineNow = null;
    }

    final windowChartMs = (_sfxOverlapWindowMs * rate).round().clamp(1, 5000);
    while (_sfxEventIndex < _sfxEventTimesMs.length &&
        _sfxEventTimesMs[_sfxEventIndex] <= horizonMs) {
      final eventMs = _sfxEventTimesMs[_sfxEventIndex];
      _sfxEventIndex++;
      _debugSfxPlayCalls++;

      final deltaRealSec =
          (eventMs / 1000.0 - chartTime) / rate + effectiveOffset;
      if (deltaRealSec < -_sfxMaxLateSeconds) {
        continue;
      }

      final startIdx = _lowerBound(_sfxEventTimesMs, eventMs - windowChartMs);
      final endIdx = _upperBound(_sfxEventTimesMs, eventMs);
      final overlap = max(1, endIdx - startIdx);
      final gain = hitSoundVoiceGain(overlap, baseGain: hitSoundVolume);

      final scheduledAt = engineNow != null && deltaRealSec > 0.002
          ? engineNow + Duration(microseconds: (deltaRealSec * 1000000).round())
          : null;
      _playSfxVoice(src, gain: gain, scheduledAt: scheduledAt);
    }
  }

  void _playDaSound() {
    _debugSfxPlayCalls++;
    final src = _sfxSource;
    if (src == null) {
      _debugSfxPlayDrops++;
      return;
    }
    _pruneSfxVoices();
    final gain = hitSoundVoiceGain(
      _sfxVoices.length + 1,
      baseGain: hitSoundVolume,
    );
    _playSfxVoice(src, gain: gain);
  }

  void _playSfxVoice(
    AudioSource src, {
    required double gain,
    Duration? scheduledAt,
  }) {
    if (gain <= 0.0) return;
    if (!identical(src, _sfxSource) || !_soloud.isInitialized) return;
    _pruneSfxVoices();

    while (_sfxVoices.length >= _maxSfxVoices) {
      final oldest = _sfxVoices.removeFirst();
      if (_soloud.getIsValidVoiceHandle(oldest)) {
        unawaited(_soloud.stop(oldest));
      }
    }

    SoundHandle handle;
    try {
      if (scheduledAt != null) {
        handle = _soloud.playScheduled(src, scheduledAt, volume: gain);
      } else {
        handle = _soloud.play(src, volume: gain);
      }
    } catch (e) {
      if (scheduledAt != null) {
        try {
          handle = _soloud.play(src, volume: gain);
        } catch (fallbackError) {
          debugPrint('SFX: SoLoud play failed: $fallbackError');
          _debugSfxPlayDrops++;
          return;
        }
      } else {
        debugPrint('SFX: SoLoud play failed: $e');
        _debugSfxPlayDrops++;
        return;
      }
    }

    if (handle.isError || !identical(src, _sfxSource)) {
      if (!handle.isError && _soloud.getIsValidVoiceHandle(handle)) {
        unawaited(_soloud.stop(handle));
      }
      _debugSfxPlayDrops++;
      return;
    }

    _sfxVoices.addLast(handle);
    _debugSfxPoolPlays++;
  }

  void _pruneSfxVoices() {
    _sfxVoices.removeWhere((handle) => !_soloud.getIsValidVoiceHandle(handle));
  }

  void _resyncSfxPosition() {
    final targetChartSec =
        chartTime - _effectiveHitSoundOffsetSeconds * playbackRate;
    final ms = (targetChartSec * 1000).round();
    _lastSfxCheckTimeMs = ms;
    _sfxEventIndex = _lowerBound(_sfxEventTimesMs, ms);
  }

  void _stopSfxVoices() {
    if (_sfxVoices.isEmpty || headlessExport || !_soloud.isInitialized) {
      _sfxVoices.clear();
      return;
    }
    for (final handle in _sfxVoices) {
      if (_soloud.getIsValidVoiceHandle(handle)) {
        unawaited(_soloud.stop(handle));
      }
    }
    _sfxVoices.clear();
  }

  void _rebuildSfxEventTimes() {
    final set = <int>{};
    for (final collection in chart.noteCollections) {
      set.add((collection.time * 1000).round());
      for (final note in collection) {
        if (note.type == NoteType.hold) {
          final len = note.length ?? 0.0;
          if (len > 0) {
            set.add(((collection.time + len) * 1000).round());
          }
        }
      }
    }
    final list = set.toList()..sort();
    _sfxEventTimesMs = list;
    _resyncSfxPosition();
  }

  static int _lowerBound(List<int> a, int x) {
    int lo = 0;
    int hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  static int _upperBound(List<int> a, int x) {
    int lo = 0;
    int hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] <= x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

class _GameplayInputVisualRegion {
  const _GameplayInputVisualRegion({
    required this.target,
    required this.path,
    required this.isOuterButton,
  });

  final SimaiGameplayInputTarget target;
  final Path path;
  final bool isOuterButton;
}

class JudgeBackgroundComponent extends PositionComponent {
  final SimaiGame game;

  ui.Picture? _backgroundPicture;
  ui.Image? _backgroundImage;
  ImageStream? _backgroundStream;
  ImageStreamListener? _backgroundStreamListener;
  Completer<void>? _backgroundResolutionCompleter;
  final ui.Image? _sensorImage;
  Vector2? _lastSize;
  Rect? _backgroundRect;
  Path? _backgroundClipPath;
  List<_GameplayInputVisualRegion> _gameplayInputRegions = const [];
  final Paint _sensorIdleFill = Paint()
    ..color = const Color(0x1239D8FF)
    ..style = PaintingStyle.fill;
  final Paint _sensorPressedFill = Paint()
    ..color = const Color(0x8839D8FF)
    ..style = PaintingStyle.fill;
  final Paint _sensorIdleStroke = Paint()
    ..color = const Color(0x7039D8FF)
    ..style = PaintingStyle.stroke;
  final Paint _sensorPressedStroke = Paint()
    ..color = const Color(0xFF9BEEFF)
    ..style = PaintingStyle.stroke;
  final Paint _buttonIdleFill = Paint()
    ..color = const Color(0x14FFD166)
    ..style = PaintingStyle.fill;
  final Paint _buttonPressedFill = Paint()
    ..color = const Color(0x88FFB300)
    ..style = PaintingStyle.fill;
  final Paint _buttonIdleStroke = Paint()
    ..color = const Color(0x70FFD166)
    ..style = PaintingStyle.stroke;
  final Paint _buttonPressedStroke = Paint()
    ..color = const Color(0xFFFFD166)
    ..style = PaintingStyle.stroke;
  final Paint _contactFill = Paint()
    ..color = const Color(0x20FFFFFF)
    ..style = PaintingStyle.fill;
  final Paint _contactStroke = Paint()
    ..color = const Color(0xA0FFFFFF)
    ..style = PaintingStyle.stroke;

  static final ColorFilter _dimBackgroundFilter = ColorFilter.matrix(
    const <double>[
      0.15,
      0,
      0,
      0,
      0,
      0,
      0.15,
      0,
      0,
      0,
      0,
      0,
      0.15,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ],
  );
  static final ColorFilter _sensorFilter = ColorFilter.matrix(const <double>[
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    1,
    1,
    1,
    0,
    0,
  ]);

  JudgeBackgroundComponent({
    required this.game,
    required ui.Image? sensorImage,
    this.backgroundImageProvider,
  }) : _sensorImage = sensorImage;

  ImageProvider? backgroundImageProvider;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_lastSize != null && (_lastSize! - size).length < 0.5) {
      return;
    }
    _lastSize = size.clone();
    this.size = size;
    game._debugResizeCalls++;
    _renderBackground();
    _rebuildGameplayInputRegions();
    _resolveBackgroundImage(force: true);
  }

  @override
  void onRemove() {
    _stopListeningBackgroundStream();
    _backgroundPicture?.dispose();
    _backgroundPicture = null;
    super.onRemove();
  }

  void setBackgroundImageProvider(ImageProvider? provider) {
    if (backgroundImageProvider == provider) return;
    backgroundImageProvider = provider;
    _resolveBackgroundImage(force: true);
  }

  void _stopListeningBackgroundStream() {
    final listener = _backgroundStreamListener;
    final stream = _backgroundStream;
    if (listener != null && stream != null) {
      stream.removeListener(listener);
    }
    _backgroundStreamListener = null;
    _backgroundStream = null;
  }

  void _resolveBackgroundImage({required bool force}) {
    final provider = backgroundImageProvider;
    if (!force && provider == null) return;

    _stopListeningBackgroundStream();
    _backgroundImage = null;
    _backgroundResolutionCompleter = Completer<void>();
    if (provider == null) {
      _backgroundResolutionCompleter!.complete();
      return;
    }

    final double devicePixelRatio =
        ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final config = ImageConfiguration(
      size: Size(size.x, size.y),
      devicePixelRatio: devicePixelRatio,
    );

    final stream = provider.resolve(config);
    _backgroundStream = stream;
    _backgroundStreamListener = ImageStreamListener(
      (info, _) {
        _backgroundImage = info.image;
        final completer = _backgroundResolutionCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
        game._requestPausedFrame();
      },
      onError: (error, stackTrace) {
        final completer = _backgroundResolutionCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete();
        }
        if (kDebugMode) {
          debugPrint('Background image resolve failed: $error');
        }
      },
    );
    stream.addListener(_backgroundStreamListener!);
  }

  Future<void> waitUntilResolved() async {
    await _backgroundResolutionCompleter?.future;
  }

  void _renderBackground() {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = min(size.x, size.y) / 2 * game.chartRadiusRatio;
    final rect = Rect.fromCircle(center: center, radius: radius * 1.05);
    _backgroundRect = rect;
    _backgroundClipPath = Path()..addOval(rect);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final mode = game.backgroundMode;

    if (mode != SimaiBackgroundMode.none) {
      final bool drawRing = mode != SimaiBackgroundMode.dots;
      _drawJudgeLine(canvas, center, radius, drawRing: drawRing);
    }

    _backgroundPicture?.dispose();
    _backgroundPicture = recorder.endRecording();
  }

  void requestBackgroundRedraw() {
    _renderBackground();
  }

  @override
  void render(Canvas canvas) {
    final bgImage = _backgroundImage;
    final sensorImage = _sensorImage;

    if (bgImage != null || sensorImage != null) {
      final rect = _backgroundRect;
      final clipPath = _backgroundClipPath;
      if (rect == null || clipPath == null) return;

      canvas.save();
      canvas.clipPath(clipPath);

      if (bgImage != null) {
        paintImage(
          canvas: canvas,
          rect: rect,
          image: bgImage,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          colorFilter: _dimBackgroundFilter,
        );
      }

      if (sensorImage != null &&
          game.backgroundMode == SimaiBackgroundMode.judgeZone &&
          game.gameplaySession == null) {
        paintImage(
          canvas: canvas,
          rect: rect,
          image: sensorImage,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          colorFilter: _sensorFilter,
        );
      }

      canvas.restore();
    }

    if (_backgroundPicture != null) {
      canvas.drawPicture(_backgroundPicture!);
    }

    _renderGameplayInputRegions(canvas);
  }

  void _rebuildGameplayInputRegions() {
    if (game.gameplaySession == null) {
      _gameplayInputRegions = const [];
      return;
    }
    final center = Offset(size.x / 2, size.y / 2);
    final radius = min(size.x, size.y) / 2 * game.chartRadiusRatio;
    final strokeWidth = max(
      1.0,
      1.8 * radius / NoteGeometry.referenceChartRadius,
    );
    _sensorIdleStroke.strokeWidth = strokeWidth;
    _buttonIdleStroke.strokeWidth = strokeWidth;
    _sensorPressedStroke.strokeWidth = strokeWidth * 1.8;
    _buttonPressedStroke.strokeWidth = strokeWidth * 1.8;
    _contactStroke.strokeWidth = strokeWidth;
    if (!game.showGameplayInputPartitions) {
      _gameplayInputRegions = const [];
      return;
    }
    final regions = <_GameplayInputVisualRegion>[];

    for (final location in SimaiGameplayInputMapper.allSensors()) {
      final target = SimaiGameplaySensorTarget(
        SimaiGameplayInputMapper.mirrorLocation(location, game.mirrorMode),
      );
      for (final polygon in SimaiGameplayInputMapper.normalizedSensorPolygons(
        location,
      )) {
        regions.add(
          _GameplayInputVisualRegion(
            target: target,
            path: Path()
              ..addPolygon(
                polygon
                    .map((point) => center + point * radius)
                    .toList(growable: false),
                true,
              ),
            isOuterButton: false,
          ),
        );
      }
    }

    const outerInnerRatio = SimaiGameplayInputMapper.touchPanelOuterRadiusRatio;
    const buttonOuterRatio = SimaiGameplayInputMapper.maximumRadiusRatio;
    const sensorOuterRatio =
        SimaiGameplayInputMapper.sensorExtensionOuterRadiusRatio;
    for (var index = 0; index < 8; index++) {
      final dCenter = (-90.0 + index * 45.0) * pi / 180;
      regions.add(
        _GameplayInputVisualRegion(
          target: SimaiGameplaySensorTarget(
            SimaiGameplayInputMapper.mirrorLocation(
              Location(index, NoteGroup.dSensor),
              game.mirrorMode,
            ),
          ),
          path: _annularSectorPath(
            center: center,
            innerRadius: radius * outerInnerRatio,
            outerRadius: radius * sensorOuterRatio,
            startAngle: dCenter - 8.0 * pi / 180,
            sweepAngle: 16.0 * pi / 180,
          ),
          isOuterButton: false,
        ),
      );

      final buttonCenter = (-67.5 + index * 45.0) * pi / 180;
      regions.add(
        _GameplayInputVisualRegion(
          target: SimaiGameplaySensorTarget(
            SimaiGameplayInputMapper.mirrorLocation(
              Location(index, NoteGroup.aSensor),
              game.mirrorMode,
            ),
          ),
          path: _annularSectorPath(
            center: center,
            innerRadius: radius * outerInnerRatio,
            outerRadius: radius * sensorOuterRatio,
            startAngle: buttonCenter - 14.5 * pi / 180,
            sweepAngle: 29.0 * pi / 180,
          ),
          isOuterButton: false,
        ),
      );
      regions.add(
        _GameplayInputVisualRegion(
          target: SimaiGameplayOuterButtonTarget(
            SimaiGameplayInputMapper.mirrorLocation(
              Location(index, NoteGroup.tap),
              game.mirrorMode,
            ).index,
          ),
          path: _annularSectorPath(
            center: center,
            innerRadius: radius * sensorOuterRatio,
            outerRadius: radius * buttonOuterRatio,
            startAngle: buttonCenter - 14.5 * pi / 180,
            sweepAngle: 29.0 * pi / 180,
          ),
          isOuterButton: true,
        ),
      );
    }
    _gameplayInputRegions = regions;
  }

  void _renderGameplayInputRegions(Canvas canvas) {
    final session = game.gameplaySession;
    if (session == null) return;

    if (game.showGameplayInputPartitions) {
      for (final region in _gameplayInputRegions) {
        final pressed = switch (region.target) {
          SimaiGameplayOuterButtonTarget(:final lane) => session.isInputPressed(
            lane,
            SimaiGameplayInputSource.outerButton,
          ),
          SimaiGameplaySensorTarget(:final location) => session.isSensorPressed(
            location,
          ),
        };
        final fillPaint = region.isOuterButton
            ? (pressed ? _buttonPressedFill : _buttonIdleFill)
            : (pressed ? _sensorPressedFill : _sensorIdleFill);
        final strokePaint = region.isOuterButton
            ? (pressed ? _buttonPressedStroke : _buttonIdleStroke)
            : (pressed ? _sensorPressedStroke : _sensorIdleStroke);

        canvas.drawPath(region.path, fillPaint);
        canvas.drawPath(region.path, strokePaint);
      }
    }

    if (!game.showGameplayTouchIndicators) return;
    final contactRadius = game.chartRadius * game.gameplayContactRadiusRatio;
    if (contactRadius <= 0) return;
    for (final position in game._gameplayPointerContacts.values) {
      canvas.drawCircle(position, contactRadius, _contactFill);
      canvas.drawCircle(position, contactRadius, _contactStroke);
    }
  }

  static Path _annularSectorPath({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
  }) {
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final endAngle = startAngle + sweepAngle;
    return Path()
      ..moveTo(
        center.dx + innerRadius * cos(startAngle),
        center.dy + innerRadius * sin(startAngle),
      )
      ..lineTo(
        center.dx + outerRadius * cos(startAngle),
        center.dy + outerRadius * sin(startAngle),
      )
      ..arcTo(outerRect, startAngle, sweepAngle, false)
      ..lineTo(
        center.dx + innerRadius * cos(endAngle),
        center.dy + innerRadius * sin(endAngle),
      )
      ..arcTo(innerRect, endAngle, -sweepAngle, false)
      ..close();
  }

  void _drawJudgeLine(
    Canvas canvas,
    Offset center,
    double radius, {
    bool drawRing = true,
  }) {
    final double scale = radius / 300.0;

    if (drawRing) {
      final paint = Paint()
        ..color = SimaiColors.judgeLine.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0 * scale;
      canvas.drawCircle(center, radius, paint);
    }

    final dotPaint = Paint()
      ..color = SimaiColors.judgeLine
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      double angle = (-67.5 + i * 45) * pi / 180;
      double dx = center.dx + radius * cos(angle);
      double dy = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 8.0 * scale, dotPaint);
    }
  }
}

class NotesLayerComponent extends PositionComponent with Snapshot {
  final SimaiGame game;

  int _visibleStartIndex = 0;
  int _visibleEndIndex = 0;
  Vector2? _lastSize;
  final Stopwatch _renderStopwatch = Stopwatch();

  NotesLayerComponent({required this.game}) {
    renderSnapshot = false;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_lastSize != null && (_lastSize! - size).length < 0.5) {
      return;
    }
    _lastSize = size.clone();
    this.size = size;
    invalidate();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.isResourcesLoaded) return;
    _syncVisibleWindow();
  }

  @override
  void render(Canvas canvas) {
    if (!game.isResourcesLoaded) return;

    if (game.isPlaying) {
      _renderStopwatch
        ..reset()
        ..start();
    }

    final batchMetrics = NotesBatchRenderer.renderVisibleNotes(
      canvas,
      game: game,
      visibleStartIndex: _visibleStartIndex,
      visibleEndIndex: _visibleEndIndex,
      runtimeIndex: game.runtimeIndex,
    );

    if (game.isPlaying) {
      _renderStopwatch.stop();
      game.recordRenderMetrics(
        elapsedMs: _renderStopwatch.elapsedMicroseconds / 1000.0,
        visibleCollections: _visibleEndIndex - _visibleStartIndex,
        batchedSprites: batchMetrics.spriteCount,
        batchFlushes: batchMetrics.flushCount,
      );
    }
  }

  void clearSlideCaches() => invalidate();

  void setSnapshotEnabled(bool enabled) {
    if (renderSnapshot == enabled) return;
    _disposeSnapshot();
    renderSnapshot = enabled;
  }

  void invalidate({bool resetWindow = false}) {
    if (resetWindow) _resetVisibleNotes();
    _disposeSnapshot();
  }

  void _disposeSnapshot() {
    if (hasSnapshot) {
      snapshot.dispose();
    }
    clearSnapshot();
  }

  void _resetVisibleNotes() {
    _visibleStartIndex = game.runtimeIndex.firstPotentiallyVisible(
      game.chartTime,
      tailPadding: game.gameplaySession == null ? 0.5 : 1.0,
    );
  }

  void _syncVisibleWindow() {
    if (game.consumeSeekReset()) {
      if (kDebugMode) {
        debugPrint(
          'NotesLayerComponent dbg: resetVisibleNotes t=${game.chartTime.toStringAsFixed(3)} reason=${game._debugLastSeekReason}',
        );
      }
      _resetVisibleNotes();
    }

    final endTimes = game.runtimeIndex.collectionEndTimes;
    final tailPadding = game.gameplaySession == null ? 0.5 : 1.0;
    while (_visibleStartIndex < endTimes.length) {
      if (endTimes[_visibleStartIndex] < game.chartTime - tailPadding) {
        _visibleStartIndex++;
      } else {
        break;
      }
    }

    final maxApproachTime = max(game.ringApproachTime, game.touchApproachTime);
    _visibleEndIndex = game.runtimeIndex.visibleEnd(
      game.chart,
      game.chartTime + maxApproachTime,
    );
    if (_visibleStartIndex > _visibleEndIndex) {
      _visibleStartIndex = _visibleEndIndex;
    }
  }

  @override
  void onRemove() {
    _disposeSnapshot();
    super.onRemove();
  }
}
