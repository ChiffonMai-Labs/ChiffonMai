import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../simai_flutter.dart';
import 'chart_timing_mapper.dart';
import 'note_motion.dart';
import 'simai_game.dart';
import 'fullscreen_utils.dart';
import 'rendering/chart_runtime_index.dart';
import '../internal/syntactic_analysis/serializer.dart';

export 'simai_mirror.dart' show SimaiMirrorMode;

class SimaiChartInfo {
  final double totalDuration;
  final int noteCollectionCount;
  final int noteCount;
  final int timingChangeCount;

  const SimaiChartInfo({
    required this.totalDuration,
    required this.noteCollectionCount,
    required this.noteCount,
    required this.timingChangeCount,
  });
}

enum SimaiBackgroundMode {
  /// 无
  none,

  /// 判定点
  dots,

  /// 判定线 (判定点 + 判定环)
  judgeLine,

  /// 判定区 (判定点 + 判定环 + 传感分区)
  judgeZone,
}

class SimaiPlayerController extends ChangeNotifier {
  static const double defaultBackgroundOpacity =
      SimaiGame.defaultBackgroundOpacity;

  final MaiChart chart;
  String? audioAsset;
  String? audioFilePath;
  ImageProvider? backgroundImageProvider;
  final double initialChartTime;
  String? title;

  VoidCallback? onToggleFullScreen;

  SimaiGame? _game;
  Timer? _pollTimer;

  double _speed = 8.0;
  double _touchSpeed = 8.0;
  double _slideDisplayTiming = 0.0;
  SimaiAutoPlayMode _autoPlayMode = SimaiAutoPlayMode.allCriticalPerfect;
  int _autoPlaySeed = 0;
  SimaiAutoPlayTimeline? _cachedAutoPlayTimeline;
  static final math.Random _autoPlayRandom = math.Random();
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  double _musicVolume = 0.5;
  double _hitSoundVolume = 2.0;
  int _musicOffsetMs = 0;
  int _hitSoundOffsetMs = 0;
  int _pvOffsetMs = 0;
  bool _hitSoundEnabled = true;
  bool _isFullScreen = false;
  SimaiBackgroundMode _backgroundMode = SimaiBackgroundMode.judgeLine;
  double _backgroundOpacity = SimaiGame.defaultBackgroundOpacity;
  SimaiMirrorMode _mirrorMode = SimaiMirrorMode.none;
  bool _rotateSlideStar = true;
  bool _pinkSlideStar = false;
  bool _standardBreakSlide = false;
  bool _highlightExNotes = false;
  bool _showApproachLine = true;
  bool _showHitEffects = true;
  SimaiHitEffectStyle _hitEffectStyle = SimaiHitEffectStyle.ring;
  bool _showJudgementDisplay = false;
  SimaiJudgementDisplayMode _judgementDisplayMode =
      SimaiJudgementDisplayMode.twoB;
  bool _showAchievementRate = true;
  SimaiCenterDisplayMode _centerDisplayMode =
      SimaiCenterDisplayMode.achievementAdd;
  SimaiCenterDisplayMode _topRightDisplayMode = SimaiCenterDisplayMode.combo;
  SimaiNoteStyle _noteStyle = SimaiNoteStyle.arcade;
  SimaiNoteStyle _holdStyle = SimaiNoteStyle.arcade;
  SimaiCustomNoteSkin _customNoteSkin = SimaiCustomNoteSkin.empty;
  String? _customHitSoundPath;
  bool _showCornerInfo = true;
  bool _showDetailedPerformanceInfo = false;

  double _chartTimeSnapshot = 0.0;
  int _seekGeneration = 0;
  double _totalDurationSnapshot = 0.0;
  late final int _noteCountSnapshot;
  late final List<double> _noteTimes = _buildNoteTimes(chart);
  bool _isDisposed = false;
  bool _gameplaySuspended = false;

  final ValueNotifier<double> timeNotifier = ValueNotifier<double>(0.0);

  SimaiPlayerController({
    required this.chart,
    this.audioAsset,
    this.audioFilePath,
    this.backgroundImageProvider,
    this.initialChartTime = 0.0,
  }) : assert(
         audioAsset == null || audioFilePath == null,
         'audioAsset and audioFilePath cannot both be set.',
       ) {
    _totalDurationSnapshot = _computeTotalDuration(chart);
    _noteCountSnapshot = chart.noteCollections.fold<int>(
      0,
      (count, collection) => count + collection.length,
    );
    timeNotifier.value = initialChartTime;
  }

  double get speed => _speed;
  double get touchSpeed => _touchSpeed;
  double get slideDisplayTiming => _slideDisplayTiming;
  SimaiAutoPlayMode get autoPlayMode => _autoPlayMode;
  int get autoPlaySeed => _autoPlaySeed;

  /// 当前模拟游玩判定时间线，供设置面板展示预计达成率与判定分布。
  SimaiAutoPlayTimeline get autoPlayTimeline {
    final game = _game;
    if (game != null &&
        game.autoPlayMode == _autoPlayMode &&
        game.autoPlaySeed == _autoPlaySeed) {
      return _cachedAutoPlayTimeline = game.autoPlayTimeline;
    }
    final cached = _cachedAutoPlayTimeline;
    if (cached != null &&
        cached.mode == _autoPlayMode &&
        cached.seed == _autoPlaySeed) {
      return cached;
    }
    return _cachedAutoPlayTimeline = SimaiAutoPlayTimeline.build(
      chart,
      _autoPlayMode,
      seed: _autoPlaySeed,
    );
  }

  bool get isPlaying => _isPlaying;
  double get playbackRate => _playbackRate;
  double get musicVolume => _musicVolume;
  double get hitSoundVolume => _hitSoundVolume;
  int get musicOffsetMs => _musicOffsetMs;
  int get hitSoundOffsetMs => _hitSoundOffsetMs;
  int get pvOffsetMs => _pvOffsetMs;
  bool get hitSoundEnabled => _hitSoundEnabled;
  bool get isFullScreen => _isFullScreen;
  SimaiBackgroundMode get backgroundMode => _backgroundMode;
  double get backgroundOpacity => _backgroundOpacity;
  SimaiMirrorMode get mirrorMode => _mirrorMode;
  bool get rotateSlideStar => _rotateSlideStar;
  bool get pinkSlideStar => _pinkSlideStar;
  bool get standardBreakSlide => _standardBreakSlide;
  bool get highlightExNotes => _highlightExNotes;
  bool get showApproachLine => _showApproachLine;
  bool get showHitEffects => _showHitEffects;
  SimaiHitEffectStyle get hitEffectStyle => _hitEffectStyle;
  bool get showJudgementDisplay => _showJudgementDisplay;
  SimaiJudgementDisplayMode get judgementDisplayMode => _judgementDisplayMode;
  bool get showAchievementRate => _showAchievementRate;
  SimaiCenterDisplayMode get centerDisplayMode => _centerDisplayMode;
  SimaiCenterDisplayMode get topRightDisplayMode => _topRightDisplayMode;
  SimaiNoteStyle get noteStyle => _noteStyle;
  SimaiNoteStyle get holdStyle => _holdStyle;
  SimaiCustomNoteSkin get customNoteSkin => _customNoteSkin;
  String? get customHitSoundPath => _customHitSoundPath;
  bool get showCornerInfo => _showCornerInfo;
  bool get showDetailedPerformanceInfo => _showDetailedPerformanceInfo;

  double get chartTime => _game?.chartTime ?? _chartTimeSnapshot;

  @visibleForTesting
  int get debugAudioPositionUpdateCount => _game?.audioPositionUpdateCount ?? 0;

  @visibleForTesting
  double? get debugAudioPositionSeconds => _game?.latestAudioPositionSeconds;

  SimaiChartInfo get chartInfo {
    final total = _game?.totalDuration ?? _totalDurationSnapshot;
    return SimaiChartInfo(
      totalDuration: total,
      noteCollectionCount: chart.noteCollections.length,
      noteCount: _noteCountSnapshot,
      timingChangeCount: chart.timingChanges.length,
    );
  }

  double get approachTime {
    return NoteMotion.approachTimeForSpeed(_speed);
  }

  double get touchApproachTime =>
      NoteMotion.touchApproachTimeForSpeed(_touchSpeed);

  double get effectiveMusicOffsetSeconds {
    return initialChartTime + _musicOffsetMs / 1000.0;
  }

  set speed(double value) {
    final quantized = NoteMotion.normalizeSpeed(value);
    if (_speed == quantized) return;
    _speed = quantized;
    _applyToGame();
    notifyListeners();
  }

  set touchSpeed(double value) {
    final quantized = NoteMotion.normalizeSpeed(value);
    if (_touchSpeed == quantized) return;
    _touchSpeed = quantized;
    _applyToGame();
    notifyListeners();
  }

  set slideDisplayTiming(double value) {
    final quantized = NoteMotion.normalizeSlideDisplayTiming(value);
    if (_slideDisplayTiming == quantized) return;
    _slideDisplayTiming = quantized;
    _applyToGame();
    notifyListeners();
  }

  set autoPlayMode(SimaiAutoPlayMode value) {
    if (_autoPlayMode == value) return;
    _autoPlayMode = value;
    _cachedAutoPlayTimeline = null;
    _applyToGame();
    notifyListeners();
  }

  set autoPlaySeed(int value) {
    if (_autoPlaySeed == value) return;
    _autoPlaySeed = value;
    _cachedAutoPlayTimeline = null;
    _applyToGame();
    notifyListeners();
  }

  /// 生成新的随机判定种子，立即重抽各音符模拟判定细节。
  void randomizeAutoPlaySeed() {
    var next = _autoPlayRandom.nextInt(0x7FFFFFFF);
    if (next == _autoPlaySeed) {
      next = (next + 1) & 0x7FFFFFFF;
    }
    autoPlaySeed = next;
  }

  set playbackRate(double value) {
    final safeValue = value.isFinite ? value : 1.0;
    final clamped = safeValue.clamp(0.1, 3.0).toDouble();
    final quantized = (clamped * 20).round() / 20.0;
    if (_playbackRate == quantized) return;
    _playbackRate = quantized;
    _applyToGame();
    notifyListeners();
  }

  set musicVolume(double value) {
    final safeValue = value.isFinite ? value : 0.8;
    final clamped = safeValue.clamp(0.0, 1.0).toDouble();
    if (_musicVolume == clamped) return;
    _musicVolume = clamped;
    _applyToGame();
    notifyListeners();
  }

  set hitSoundVolume(double value) {
    final safeValue = value.isFinite ? value : 0.72;
    final clamped = safeValue.clamp(0.0, simaiMaxHitSoundVolume).toDouble();
    if (_hitSoundVolume == clamped) return;
    _hitSoundVolume = clamped;
    _applyToGame();
    notifyListeners();
  }

  set musicOffsetMs(int value) {
    final clamped = value.clamp(-2000, 2000);
    if (_musicOffsetMs == clamped) return;
    _musicOffsetMs = clamped;
    _applyToGame(resyncAudio: true);
    notifyListeners();
  }

  set hitSoundOffsetMs(int value) {
    final clamped = value.clamp(-200, 200);
    if (_hitSoundOffsetMs == clamped) return;
    _hitSoundOffsetMs = clamped;
    _applyToGame();
    notifyListeners();
  }

  set pvOffsetMs(int value) {
    final clamped = value.clamp(-2000, 2000);
    if (_pvOffsetMs == clamped) return;
    _pvOffsetMs = clamped;
    notifyListeners();
  }

  set hitSoundEnabled(bool value) {
    if (_hitSoundEnabled == value) return;
    _hitSoundEnabled = value;
    _applyToGame();
    notifyListeners();
  }

  set isFullScreen(bool value) {
    if (_isFullScreen == value) return;
    _isFullScreen = value;
    notifyListeners();
  }

  set backgroundMode(SimaiBackgroundMode value) {
    if (_backgroundMode == value) return;
    _backgroundMode = value;
    _applyToGame();
    notifyListeners();
  }

  set backgroundOpacity(double value) {
    final safeValue = value.isFinite
        ? value
        : SimaiGame.defaultBackgroundOpacity;
    final clamped = safeValue.clamp(0.0, 1.0).toDouble();
    final quantized = (clamped * 100).round() / 100.0;
    if (_backgroundOpacity == quantized) return;
    _backgroundOpacity = quantized;
    _applyToGame();
    notifyListeners();
  }

  set mirrorMode(SimaiMirrorMode value) {
    if (_mirrorMode == value) return;
    _mirrorMode = value;
    _applyToGame();
    notifyListeners();
  }

  set rotateSlideStar(bool value) {
    if (_rotateSlideStar == value) return;
    _rotateSlideStar = value;
    _applyToGame();
    notifyListeners();
  }

  set pinkSlideStar(bool value) {
    if (_pinkSlideStar == value) return;
    _pinkSlideStar = value;
    _applyToGame();
    notifyListeners();
  }

  set standardBreakSlide(bool value) {
    if (_standardBreakSlide == value) return;
    _standardBreakSlide = value;
    _applyToGame();
    notifyListeners();
  }

  set highlightExNotes(bool value) {
    if (_highlightExNotes == value) return;
    _highlightExNotes = value;
    _applyToGame();
    notifyListeners();
  }

  set showApproachLine(bool value) {
    if (_showApproachLine == value) return;
    _showApproachLine = value;
    _applyToGame();
    notifyListeners();
  }

  set showHitEffects(bool value) {
    if (_showHitEffects == value) return;
    _showHitEffects = value;
    _applyToGame();
    notifyListeners();
  }

  set hitEffectStyle(SimaiHitEffectStyle value) {
    if (_hitEffectStyle == value) return;
    _hitEffectStyle = value;
    _applyToGame();
    notifyListeners();
  }

  set showJudgementDisplay(bool value) {
    if (_showJudgementDisplay == value) return;
    _showJudgementDisplay = value;
    _applyToGame();
    notifyListeners();
  }

  set judgementDisplayMode(SimaiJudgementDisplayMode value) {
    if (_judgementDisplayMode == value) return;
    _judgementDisplayMode = value;
    _applyToGame();
    notifyListeners();
  }

  set showAchievementRate(bool value) {
    if (_showAchievementRate == value) return;
    _showAchievementRate = value;
    _applyToGame();
    notifyListeners();
  }

  set centerDisplayMode(SimaiCenterDisplayMode value) {
    if (_centerDisplayMode == value) return;
    _centerDisplayMode = value;
    _applyToGame();
    notifyListeners();
  }

  set topRightDisplayMode(SimaiCenterDisplayMode value) {
    if (_topRightDisplayMode == value) return;
    _topRightDisplayMode = value;
    _applyToGame();
    notifyListeners();
  }

  set noteStyle(SimaiNoteStyle value) {
    if (_noteStyle == value) return;
    _noteStyle = value;
    _applyToGame();
    notifyListeners();
  }

  set holdStyle(SimaiNoteStyle value) {
    final normalized = SimaiNoteStyle.normalizeForHold(value);
    if (_holdStyle == normalized) return;
    _holdStyle = normalized;
    _applyToGame();
    notifyListeners();
  }

  set customNoteSkin(SimaiCustomNoteSkin value) {
    if (_customNoteSkin == value) return;
    _customNoteSkin = value;
    _applyToGame();
    notifyListeners();
  }

  set customHitSoundPath(String? value) {
    final normalized = (value != null && value.trim().isNotEmpty)
        ? value.trim()
        : null;
    if (_customHitSoundPath == normalized) return;
    _customHitSoundPath = normalized;
    _applyToGame();
    notifyListeners();
  }

  set showCornerInfo(bool value) {
    if (_showCornerInfo == value) return;
    _showCornerInfo = value;
    _applyToGame();
    notifyListeners();
  }

  set showDetailedPerformanceInfo(bool value) {
    if (_showDetailedPerformanceInfo == value) return;
    _showDetailedPerformanceInfo = value;
    _applyToGame();
    notifyListeners();
  }

  double get totalDurationSnapshot => _totalDurationSnapshot;

  Future<void> play() async {
    if (_isPlaying) return;
    final total = chartInfo.totalDuration;
    if (total > 0 && chartTime >= total - 1e-4) {
      await seek(0.0, syncAudio: true);
    }
    _isPlaying = true;
    _applyToGame();
    notifyListeners();
  }

  Future<void> pause() async {
    if (!_isPlaying) return;
    _isPlaying = false;
    _applyToGame();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(double time, {bool syncAudio = true}) async {
    final int generation = ++_seekGeneration;
    final total = chartInfo.totalDuration;
    final clamped = time.isFinite
        ? time.clamp(0.0, total > 0 ? total : double.infinity).toDouble()
        : 0.0;
    final game = _game;
    if (game == null) {
      _chartTimeSnapshot = clamped;
      timeNotifier.value = clamped;
      notifyListeners();
      return;
    }
    // 先启动 game.seek 同步写入 game.chartTime，再通知 timeNotifier，
    // 确保监听器在回调内读到最新的 chartTime。
    final seekFuture = game.seek(clamped, syncAudio: syncAudio);
    _chartTimeSnapshot = clamped;
    timeNotifier.value = clamped;
    await seekFuture;
    if (generation != _seekGeneration) return;
    _chartTimeSnapshot = game.chartTime;
    timeNotifier.value = game.chartTime;
    // 仅时间变化不触发 notifyListeners，避免引起整页重建。
  }

  Future<void> previousMeasure() async {
    final target = computePreviousMeasureTime(chartTime);
    await seek(target, syncAudio: true);
  }

  Future<void> nextMeasure() async {
    final target = computeNextMeasureTime(chartTime);
    await seek(target, syncAudio: true);
  }

  Future<void> replayMeasure() async {
    final target = computeCurrentMeasureStartTime(chartTime);
    await seek(target, syncAudio: true);
  }

  Future<void> previousNote() async {
    final target = computePreviousNoteTime(chartTime);
    await seek(target, syncAudio: true);
  }

  Future<void> nextNote() async {
    final target = computeNextNoteTime(chartTime);
    await seek(target, syncAudio: true);
  }

  double computePreviousMeasureTime(double time) {
    return _computeMeasureTime(time, forward: false);
  }

  double computeNextMeasureTime(double time) {
    return _computeMeasureTime(time, forward: true);
  }

  double computeCurrentMeasureStartTime(double time) {
    final t = time.isFinite ? time : 0.0;
    if (chart.timingChanges.isEmpty) return t;
    final beats = ChartTimingMapper.beatsAtTime(chart, t < 0 ? 0.0 : t);
    final targetBeats = (beats / 4.0).floorToDouble() * 4.0;
    final boundaryTime = ChartTimingMapper.timeAtBeats(chart, targetBeats);
    return boundaryTime < 0 ? 0.0 : boundaryTime;
  }

  static List<double> _buildNoteTimes(MaiChart chart) {
    final raw = <double>[
      for (final collection in chart.noteCollections)
        if (collection.isNotEmpty && collection.time.isFinite) collection.time,
    ]..sort();
    final unique = <double>[];
    for (final t in raw) {
      if (unique.isEmpty || (t - unique.last) > 1e-5) {
        unique.add(t);
      }
    }
    return unique;
  }

  double computePreviousNoteTime(double time) {
    if (_noteTimes.isEmpty) return time;
    final double tolerance = _isPlaying ? 0.08 : 1e-4;

    int lo = 0;
    int hi = _noteTimes.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_noteTimes[mid] < time - tolerance) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    if (hi < 0) return 0.0;
    return _noteTimes[hi];
  }

  double computeNextNoteTime(double time) {
    if (_noteTimes.isEmpty) return time;
    const double epsilon = 1e-4;

    int lo = 0;
    int hi = _noteTimes.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_noteTimes[mid] <= time + epsilon) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    if (lo >= _noteTimes.length) return time;
    return _noteTimes[lo];
  }

  /// 挂起或恢复预览轮询定时器，避免游玩期间底层预览页持续 32ms 空转。
  void setGameplaySuspended(bool suspended) {
    if (_gameplaySuspended == suspended) return;
    _gameplaySuspended = suspended;
    if (suspended) {
      _pollTimer?.cancel();
      _pollTimer = null;
    } else if (!_isDisposed && _game != null) {
      final t = _game!.chartTime;
      if ((_chartTimeSnapshot - t).abs() >= 0.0001) {
        _chartTimeSnapshot = t;
        timeNotifier.value = t;
      }
      _startPollTimer();
    }
  }

  void _startPollTimer() {
    if (_isDisposed || _gameplaySuspended || _game == null) return;
    _pollTimer ??= Timer.periodic(const Duration(milliseconds: 32), (_) {
      final g = _game;
      if (g == null) return;
      final t = g.chartTime;
      if ((_chartTimeSnapshot - t).abs() < 0.0001) return;
      _chartTimeSnapshot = t;
      timeNotifier.value = t;
    });
  }

  void _attachGame(SimaiGame game) {
    if (identical(_game, game)) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    _game = game;
    game.onPlaybackCompleted = _handlePlaybackCompleted;
    _applyToGame();
    _totalDurationSnapshot = game.totalDuration;
    _chartTimeSnapshot = game.chartTime;
    timeNotifier.value = game.chartTime;
    _startPollTimer();
    // 使用微任务通知监听者，避免在子组件 initState 或 didUpdateWidget 中触发 setState during build。
    Future.microtask(() => notifyListeners());
  }

  void _detachGame(SimaiGame game) {
    if (!identical(_game, game)) return;
    game.onPlaybackCompleted = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _game = null;
  }

  void _handlePlaybackCompleted() {
    if (!_isPlaying) return;
    _isPlaying = false;
    final game = _game;
    if (game != null) {
      _chartTimeSnapshot = game.chartTime;
      timeNotifier.value = game.chartTime;
    }
    notifyListeners();
  }

  Future<void> waitForNoteAssetsReady() =>
      _game?.waitForNoteAssetsReady() ?? Future<void>.value();

  void _applyToGame({bool resyncAudio = false}) {
    final game = _game;
    if (game == null) return;
    final approach = approachTime;
    game.ringApproachTime = approach;
    game.touchApproachTime = touchApproachTime;
    game.setSlideDisplayTiming(_slideDisplayTiming);
    game.setAutoPlayMode(_autoPlayMode);
    game.setAutoPlaySeed(_autoPlaySeed);
    game.offset = effectiveMusicOffsetSeconds;
    game.hitSoundOffset = _hitSoundOffsetMs / 1000.0;
    game.hitSoundEnabled = _hitSoundEnabled;
    game.setPlaying(_isPlaying);
    game.setAudioAsset(audioAsset);
    game.setAudioFilePath(audioFilePath);
    game.setBackgroundImageProvider(backgroundImageProvider);
    game.setPlaybackRate(_playbackRate);
    game.setMusicVolume(_musicVolume);
    game.setHitSoundVolume(_hitSoundVolume);
    game.setBackgroundMode(_backgroundMode);
    game.setBackgroundOpacity(_backgroundOpacity);
    game.setMirrorMode(_mirrorMode);
    game.rotateSlideStar = _rotateSlideStar;
    game.pinkSlideStar = _pinkSlideStar;
    game.standardBreakSlide = _standardBreakSlide;
    game.highlightExNotes = _highlightExNotes;
    game.showApproachLine = _showApproachLine;
    game.showHitEffects = _showHitEffects;
    game.hitEffectStyle = _hitEffectStyle;
    game.showJudgementDisplay = _showJudgementDisplay;
    game.judgementDisplayMode = _judgementDisplayMode;
    game.showAchievementRate = _showAchievementRate;
    game.centerDisplayMode = _centerDisplayMode;
    game.topRightDisplayMode = _topRightDisplayMode;
    final bool assetRebuildPending =
        game.noteStyle != _noteStyle || game.customNoteSkin != _customNoteSkin;
    game.setNoteStyle(_noteStyle);
    game.setHoldStyle(_holdStyle);
    game.setCustomNoteSkin(_customNoteSkin);
    game.setCustomHitSoundPath(_customHitSoundPath);
    game.showCornerInfo = _showCornerInfo;
    game.showDetailedPerformanceInfo = _showDetailedPerformanceInfo;
    if (!assetRebuildPending) {
      game.invalidateNotes();
    }
    if (resyncAudio) {
      game.seek(game.chartTime, syncAudio: true);
    }
  }

  double _computeMeasureTime(double time, {required bool forward}) {
    final t = time.isFinite ? time : 0.0;
    if (chart.timingChanges.isEmpty) {
      return t;
    }
    final epsilon = 1e-6;
    final clampedTime = t < 0 ? 0.0 : t;

    if (forward) {
      final beats = ChartTimingMapper.beatsAtTime(chart, clampedTime);
      double boundaryBeats = (beats / 4.0).floorToDouble() * 4.0 + 4.0;
      double boundaryTime = ChartTimingMapper.timeAtBeats(chart, boundaryBeats);
      if (boundaryTime <= clampedTime + epsilon) {
        boundaryBeats += 4.0;
        boundaryTime = ChartTimingMapper.timeAtBeats(chart, boundaryBeats);
      }
      return boundaryTime;
    } else {
      const double tolerance = 0.2;
      final beats = ChartTimingMapper.beatsAtTime(
        chart,
        (clampedTime - tolerance).clamp(0.0, double.infinity),
      );
      final targetBeats = (beats / 4.0).floorToDouble() * 4.0;
      final boundaryTime = ChartTimingMapper.timeAtBeats(chart, targetBeats);
      return boundaryTime < 0 ? 0.0 : boundaryTime;
    }
  }

  static double _computeTotalDuration(MaiChart chart) {
    return computeChartContentEndTime(chart);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isPlaying = false;
    _applyToGame();
    _pollTimer?.cancel();
    _pollTimer = null;
    _game = null;
    timeNotifier.dispose();
    super.dispose();
  }
}

class SimaiPlayer extends StatefulWidget {
  final SimaiPlayerController controller;
  final VoidCallback? onReady;
  final ValueChanged<Object>? onError;
  final TextStyle? displayFont;
  final SimaiTextStyleResolver? textStyleResolver;
  final Widget? backgroundVideo;

  const SimaiPlayer({
    super.key,
    required this.controller,
    this.onReady,
    this.onError,
    this.displayFont,
    this.textStyleResolver,
    this.backgroundVideo,
  });

  @override
  State<SimaiPlayer> createState() => _SimaiPlayerState();
}

class _SimaiPlayerState extends State<SimaiPlayer> {
  // 禁止 GameWidget 抢占焦点，避免 Flame 1.37.0 吞掉系统音量键与返回键。
  late final FocusNode _gameFocusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );
  late SimaiGame _game;
  bool _showSourceOverlay = false;
  bool _loadErrorReported = false;
  int _loadGeneration = 0;

  void toggleSourceOverlay() {
    setState(() => _showSourceOverlay = !_showSourceOverlay);
  }

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _loadErrorReported = false;
    final loadGeneration = ++_loadGeneration;
    final controller = widget.controller;
    _game = SimaiGame(
      chart: controller.chart,
      isPlaying: controller.isPlaying,
      ringApproachTime: controller.approachTime,
      touchApproachTime: controller.touchApproachTime,
      slideDisplayTiming: controller.slideDisplayTiming,
      autoPlayMode: controller.autoPlayMode,
      autoPlaySeed: controller.autoPlaySeed,
      playbackRate: controller.playbackRate,
      musicVolume: controller.musicVolume,
      hitSoundVolume: controller.hitSoundVolume,
      hitSoundOffset: controller.hitSoundOffsetMs / 1000.0,
      hitSoundEnabled: controller.hitSoundEnabled,
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
      customHitSoundPath: controller.customHitSoundPath,
      showCornerInfo: controller.showCornerInfo,
      showDetailedPerformanceInfo: controller.showDetailedPerformanceInfo,
      hasVideoBackground: widget.backgroundVideo != null,
      initialChartTime: controller.initialChartTime,
      offset: controller.effectiveMusicOffsetSeconds,
      audioAsset: controller.audioAsset,
      audioFilePath: controller.audioFilePath,
      backgroundImageProvider: controller.backgroundImageProvider,
      displayFont: widget.displayFont,
      textStyleResolver: widget.textStyleResolver,
    );
    controller._attachGame(_game);
    unawaited(
      _game.loaded.then(
        (_) async {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || loadGeneration != _loadGeneration) return;
          widget.onReady?.call();
        },
        onError: (Object error, StackTrace stackTrace) {
          // 加载错误由 GameWidget 的 errorBuilder 显示。
          debugPrint('Simai player load failed: $error');
          if (!mounted || loadGeneration != _loadGeneration) return;
          widget.onError?.call(error);
        },
      ),
    );
  }

  @override
  void didUpdateWidget(SimaiPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller._detachGame(_game);
      _initializeGame();
    } else if ((widget.backgroundVideo != null) !=
        (oldWidget.backgroundVideo != null)) {
      _game.setHasVideoBackground(widget.backgroundVideo != null);
    }
  }

  @override
  void dispose() {
    widget.controller._detachGame(_game);
    _gameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        if (widget.backgroundVideo != null)
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter =
                  math.min(constraints.maxWidth, constraints.maxHeight) *
                  _game.chartRadiusRatio *
                  1.05;
              return Center(
                child: SizedBox.square(
                  dimension: diameter,
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.backgroundVideo!,
                        // 用纯色遮罩调节视频背景亮度，避免 Opacity 触发离屏 saveLayer。
                        ListenableBuilder(
                          listenable: widget.controller,
                          builder: (context, _) {
                            final opacity = widget.controller.backgroundOpacity
                                .clamp(0.0, 1.0)
                                .toDouble();
                            if (opacity >= 1.0) {
                              return const SizedBox.shrink();
                            }
                            return ColoredBox(
                              color: Colors.black.withValues(
                                alpha: (1.0 - opacity)
                                    .clamp(0.0, 1.0)
                                    .toDouble(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        GameWidget(
          game: _game,
          focusNode: _gameFocusNode,
          autofocus: false,
          errorBuilder: (context, error) {
            // Flame 的 loaded 只在成功时完成，失败必须从加载器入口上报。
            if (!_loadErrorReported) {
              _loadErrorReported = true;
              final generation = _loadGeneration;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || generation != _loadGeneration) return;
                widget.onError?.call(error);
              });
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '谱面预览加载失败，请退出后重试。\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        ),
        if (_showSourceOverlay)
          _SimaiSourceOverlay(
            controller: widget.controller,
            onClose: () => setState(() => _showSourceOverlay = false),
          ),
      ],
    );
  }
}

class _SourceMeasure {
  final int measure;
  final double time;
  final List<_SourceToken> tokens;

  const _SourceMeasure({
    required this.measure,
    required this.time,
    required this.tokens,
  });

  String get source => tokens.map((token) => token.text).join(',');
}

class _SourceToken {
  final double time;
  final String text;

  const _SourceToken({required this.time, required this.text});
}

class _SimaiSourceOverlay extends StatefulWidget {
  final SimaiPlayerController controller;
  final VoidCallback onClose;

  const _SimaiSourceOverlay({required this.controller, required this.onClose});

  @override
  State<_SimaiSourceOverlay> createState() => _SimaiSourceOverlayState();
}

class _SimaiSourceOverlayState extends State<_SimaiSourceOverlay> {
  late final List<_SourceMeasure> _measures = _buildMeasures();
  late final ScrollController _scrollController;
  late final List<GlobalKey> _measureKeys;
  int _lastCurrentIndex = -1;
  bool _userControllingScroll = false;
  int _jumpGeneration = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _measureKeys = List.generate(_measures.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_SourceMeasure> _buildMeasures() {
    final chart = widget.controller.chart;
    final grouped = <int, List<_SourceToken>>{};
    for (int i = 0; i < chart.noteCollections.length; i++) {
      final collection = chart.noteCollections[i];
      if (collection.isEmpty) continue;
      final measure =
          (ChartTimingMapper.beatsAtTime(chart, collection.time) / 4).floor();
      String text;
      final source = chart.sourceNoteStatements;
      if (source != null && i < source.length) {
        text = source[i].replaceAll(RegExp(r'\s+'), ' ').trim();
      } else {
        final writer = StringBuffer();
        Serializer.serializeNoteCollection(collection, writer);
        text = writer.toString();
      }
      grouped
          .putIfAbsent(measure, () => [])
          .add(_SourceToken(time: collection.time, text: text));
    }
    return grouped.entries.map((entry) {
      entry.value.sort((a, b) => a.time.compareTo(b.time));
      return _SourceMeasure(
        measure: entry.key,
        time: ChartTimingMapper.timeAtBeats(chart, entry.key * 4.0),
        tokens: List.unmodifiable(entry.value),
      );
    }).toList()..sort((a, b) => a.time.compareTo(b.time));
  }

  int _currentMeasureIndex(double time) {
    if (_measures.isEmpty) return 0;
    int lo = 0;
    int hi = _measures.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_measures[mid].time <= time + 1e-7) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return hi.clamp(0, _measures.length - 1);
  }

  void _followCurrent(int index) {
    if (index == _lastCurrentIndex) return;
    _lastCurrentIndex = index;
    if (_userControllingScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final targetContext = _measureKeys[index].currentContext;
      if (targetContext == null) return;
      Scrollable.ensureVisible(
        targetContext,
        alignment: 0.45,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// 一键跳回当前正在播放的小节；若目标小节已滚出 ListView 视口，
  /// 先按比例估算跳入附近区域，再在帧后最多收敛 3 次直到精准对齐。
  void _jumpToCurrentMeasure() {
    if (!mounted || _measures.isEmpty || !_scrollController.hasClients) return;
    final currentIndex = _currentMeasureIndex(
      widget.controller.timeNotifier.value,
    );
    _userControllingScroll = false;
    _lastCurrentIndex = currentIndex;
    final int generation = ++_jumpGeneration;

    final targetContext = _measureKeys[currentIndex].currentContext;
    if (targetContext != null) {
      unawaited(
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.45,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;
    final totalExtent = position.maxScrollExtent + position.viewportDimension;
    final estimatedOffset =
        (((currentIndex + 0.5) / _measures.length) * totalExtent -
                position.viewportDimension * 0.45)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
    _scrollController.jumpTo(estimatedOffset);
    _convergeJumpToMeasure(generation, 3);
  }

  void _convergeJumpToMeasure(int generation, int remainingAttempts) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _jumpGeneration ||
          _userControllingScroll ||
          !_scrollController.hasClients ||
          _measures.isEmpty) {
        return;
      }
      final targetIndex = _currentMeasureIndex(
        widget.controller.timeNotifier.value,
      );
      _lastCurrentIndex = targetIndex;

      final targetContext = _measureKeys[targetIndex].currentContext;
      if (targetContext != null) {
        unawaited(
          Scrollable.ensureVisible(
            targetContext,
            alignment: 0.45,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
        );
        return;
      }
      if (remainingAttempts <= 0) return;

      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;

      // 扫描当前已挂载小节的下标区间与平均高度，沿目标方向步进逼近。
      int? minMounted;
      int? maxMounted;
      double mountedHeightSum = 0.0;
      int mountedCount = 0;
      for (int i = 0; i < _measureKeys.length; i++) {
        final box =
            _measureKeys[i].currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.attached || !box.hasSize) continue;
        minMounted ??= i;
        maxMounted = i;
        mountedHeightSum += box.size.height;
        mountedCount++;
      }

      double nextOffset;
      if (minMounted != null && maxMounted != null) {
        if (targetIndex >= minMounted && targetIndex <= maxMounted) {
          return;
        }
        final double avgItemHeight = mountedCount > 0
            ? (mountedHeightSum / mountedCount).clamp(32.0, 600.0).toDouble()
            : 80.0;
        final double midMounted = (minMounted + maxMounted) / 2.0;
        final double indexDelta = targetIndex - midMounted;
        final double rawStep = indexDelta * avgItemHeight;
        final double minStep = position.viewportDimension * 0.5;
        final double step = rawStep.abs() < minStep
            ? (indexDelta < 0 ? -minStep : minStep)
            : rawStep;
        nextOffset = position.pixels + step;
      } else {
        final totalExtent =
            position.maxScrollExtent + position.viewportDimension;
        nextOffset =
            ((targetIndex + 0.5) / _measures.length) * totalExtent -
            position.viewportDimension * 0.45;
      }

      final clampedOffset = nextOffset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((clampedOffset - position.pixels).abs() < 1.0) return;
      _scrollController.jumpTo(clampedOffset);
      _convergeJumpToMeasure(generation, remainingAttempts - 1);
    });
  }

  void _snapToNearestMeasure() {
    if (!mounted || _measures.isEmpty) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;
    final overlayCenter = overlayBox
        .localToGlobal(Offset(0, overlayBox.size.height / 2))
        .dy;
    int? nearestIndex;
    double nearestDistance = double.infinity;
    for (int i = 0; i < _measureKeys.length; i++) {
      final box =
          _measureKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final center = box.localToGlobal(Offset(0, box.size.height / 2)).dy;
      final distance = (center - overlayCenter).abs();
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }
    if (nearestIndex == null) return;
    if (nearestDistance < 1.0) return;
    final targetContext = _measureKeys[nearestIndex].currentContext;
    if (targetContext == null) return;
    Scrollable.ensureVisible(
      targetContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onClose,
        child: SafeArea(
          child: _measures.isEmpty
              ? const Center(
                  child: Text(
                    'No source mapping',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ValueListenableBuilder<double>(
                  valueListenable: widget.controller.timeNotifier,
                  builder: (context, time, _) {
                    final currentIndex = _currentMeasureIndex(time);
                    _followCurrent(currentIndex);
                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollStartNotification &&
                                notification.dragDetails != null) {
                              _userControllingScroll = true;
                              _jumpGeneration++;
                            } else if (notification is ScrollEndNotification) {
                              final wasUserControlled = _userControllingScroll;
                              _userControllingScroll = false;
                              if (wasUserControlled) _snapToNearestMeasure();
                            }
                            return false;
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(0, 24, 0, 76),
                            itemCount: _measures.length,
                            itemBuilder: (context, index) => KeyedSubtree(
                              key: _measureKeys[index],
                              child: _buildMeasure(
                                context,
                                _measures[index],
                                time,
                                index == currentIndex,
                              ),
                            ),
                          ),
                        ),
                        // 悬浮定位按钮：外层拦截点击避免冒泡触发背景关闭浮层。
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: FilledButton.tonalIcon(
                              onPressed: _jumpToCurrentMeasure,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(
                                  0xFF1F2937,
                                ).withValues(alpha: 0.94),
                                foregroundColor: const Color(0xFFFFD54F),
                                side: BorderSide(
                                  color: const Color(
                                    0xFFFFD54F,
                                  ).withValues(alpha: 0.55),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: const StadiumBorder(),
                                elevation: 4,
                                shadowColor: Colors.black87,
                                splashFactory: NoSplash.splashFactory,
                              ),
                              icon: const Icon(
                                Icons.my_location_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                '跳转到当前',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildMeasure(
    BuildContext context,
    _SourceMeasure measure,
    double time,
    bool current,
  ) {
    int activeToken = 0;
    for (int i = 1; i < measure.tokens.length; i++) {
      if (measure.tokens[i].time <= time + 1e-7) activeToken = i;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onClose,
      onLongPress: () async {
        final messenger = ScaffoldMessenger.maybeOf(context);
        await Clipboard.setData(ClipboardData(text: measure.source));
        if (!mounted) return;
        messenger?.showSnackBar(
          SnackBar(
            content: Text('已复制 M${measure.measure + 1}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: current
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: current ? Border.all(color: Colors.white38, width: 1) : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 66,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatOverlayTime(measure.time),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'M${measure.measure + 1}',
                    style: TextStyle(
                      color: current ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (int i = 0; i < measure.tokens.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 2,
                      ),
                      decoration: current && i == activeToken
                          ? BoxDecoration(
                              color: const Color(0xFFFFD54F),
                              borderRadius: BorderRadius.circular(3),
                            )
                          : null,
                      child: Text(
                        '${measure.tokens[i].text}${i == measure.tokens.length - 1 ? '' : ','}',
                        style: TextStyle(
                          color: current && i == activeToken
                              ? Colors.black
                              : current
                              ? Colors.white
                              : Colors.white54,
                          fontSize: 12,
                          fontWeight: current && i == activeToken
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: '从此处播放',
              onPressed: () async {
                await widget.controller.seek(measure.time, syncAudio: true);
                widget.controller.play();
              },
              icon: const Icon(Icons.play_arrow, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatOverlayTime(double seconds) {
    final value = seconds.clamp(0.0, double.infinity).round();
    return '${value ~/ 60}:${(value % 60).toString().padLeft(2, '0')}';
  }
}

typedef SimaiCustomSettingBuilder = Widget Function(
  BuildContext context,
  SimaiPlayerController controller,
  VoidCallback onChanged,
);

typedef SimaiSwitchBuilder = Widget Function(
  BuildContext context,
  bool value,
  ValueChanged<bool>? onChanged,
);

class SimaiPlayerPage extends StatefulWidget {
  final SimaiPlayerController controller;
  final SimaiGameplayController? gameplayController;
  final String? title;
  final VoidCallback? onBack;
  final bool disposeController;
  final SimaiVideoMetadata? videoExportMetadata;
  final SimaiVideoExportOptions videoExportOptions;
  final SimaiVideoExportSettings? videoExportSettings;
  final ValueChanged<SimaiVideoExportSettings>? onVideoExportSettingsChanged;
  final Future<String?> Function()? resolveVideoExportAudio;
  final Future<String?> Function()? checkCachedPvFilePath;
  final SimaiVideoExportPvDownloader? downloadPvFilePath;
  final Widget Function(
    BuildContext context,
    String pvVideoPath,
    ValueListenable<double> timeListenable,
    bool isPlaying,
  )?
  pvPreviewBuilder;
  final ValueChanged<SimaiVideoExportResult>? onVideoExported;
  final Widget? beforeTimeline;
  final Widget? extraDisplaySettings;
  final SimaiCustomSettingBuilder? customNoteSkinSettingBuilder;
  final SimaiCustomSettingBuilder? customHitSoundSettingBuilder;
  final TextStyle? displayFont;
  final SimaiTextStyleResolver? textStyleResolver;
  final Future<void> Function()? prepareFonts;
  final SimaiSwitchBuilder? switchBuilder;
  final Widget? backgroundVideo;
  final bool hasPvBackground;
  final bool initialExportUsePvBackground;
  final String? initialExportPvVideoPath;
  final Future<void> Function()? onEnterGameplay;
  final Future<void> Function()? onExitGameplay;

  const SimaiPlayerPage({
    super.key,
    required this.controller,
    this.gameplayController,
    this.title,
    this.onBack,
    this.disposeController = true,
    this.videoExportMetadata,
    this.videoExportOptions = const SimaiVideoExportOptions(),
    this.videoExportSettings,
    this.onVideoExportSettingsChanged,
    this.resolveVideoExportAudio,
    this.checkCachedPvFilePath,
    this.downloadPvFilePath,
    this.pvPreviewBuilder,
    this.onVideoExported,
    this.beforeTimeline,
    this.extraDisplaySettings,
    this.customNoteSkinSettingBuilder,
    this.customHitSoundSettingBuilder,
    this.displayFont,
    this.textStyleResolver,
    this.prepareFonts,
    this.switchBuilder,
    this.backgroundVideo,
    this.hasPvBackground = false,
    this.initialExportUsePvBackground = false,
    this.initialExportPvVideoPath,
    this.onEnterGameplay,
    this.onExitGameplay,
  });

  @override
  State<SimaiPlayerPage> createState() => _SimaiPlayerPageState();
}

class _SimaiPlayerPageState extends State<SimaiPlayerPage> {
  bool _isLoading = true;
  Object? _loadError;
  bool _showControls = true;
  Timer? _hideTimer;
  bool _isFullScreen = false;
  bool _isLocked = false;
  bool _isManualExit = false;
  Orientation? _observedOrientation;
  bool _videoExportAvailable = false;
  bool _videoExportSupportChecking = false;
  bool _videoExportInProgress = false;
  int _videoSupportGeneration = 0;
  SimaiGameplayController? _ownedGameplayController;
  late final GlobalKey<_SimaiPlayerState> _playerKey;

  @override
  void initState() {
    super.initState();
    _playerKey = GlobalKey<_SimaiPlayerState>();
    widget.controller.onToggleFullScreen = _toggleFullScreen;
    widget.controller.addListener(_onControllerChanged);
    _startHideTimer();
    _checkVideoExportSupport();
  }

  @override
  void didUpdateWidget(SimaiPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _disposeOwnedGameplayController();
      oldWidget.controller.removeListener(_onControllerChanged);
      oldWidget.controller.onToggleFullScreen = null;
      widget.controller.addListener(_onControllerChanged);
      widget.controller.onToggleFullScreen = _toggleFullScreen;
      _isLoading = true;
    }
    if (widget.gameplayController != oldWidget.gameplayController) {
      _disposeOwnedGameplayController();
    }
    if (widget.videoExportMetadata != oldWidget.videoExportMetadata) {
      _checkVideoExportSupport();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposeOwnedGameplayController();
    widget.controller.removeListener(_onControllerChanged);
    widget.controller.onToggleFullScreen = null;
    if (_isFullScreen) {
      widget.controller.isFullScreen = false;
      unawaited(FullScreenUtils.exitFullScreen());
    }
    if (widget.disposeController) {
      widget.controller.dispose();
    }
    super.dispose();
  }

  void _disposeOwnedGameplayController() {
    _ownedGameplayController?.dispose();
    _ownedGameplayController = null;
  }

  SimaiGameplayController _resolveGameplayController() {
    final supplied = widget.gameplayController;
    if (supplied != null) return supplied;
    return _ownedGameplayController ??= SimaiGameplayController(
      chart: widget.controller.chart,
      audioAsset: widget.controller.audioAsset,
      audioFilePath: widget.controller.audioFilePath,
      backgroundImageProvider: widget.controller.backgroundImageProvider,
      initialChartTime: widget.controller.initialChartTime,
      title: widget.title ?? widget.controller.title,
      settings: SimaiGameplaySettings(
        noteSpeed: widget.controller.speed,
        touchSpeed: widget.controller.touchSpeed,
        musicOffsetMs: widget.controller.musicOffsetMs,
        musicVolume: widget.controller.musicVolume,
        hitSoundVolume: widget.controller.hitSoundVolume,
        mirrorMode: widget.controller.mirrorMode,
        backgroundMode: widget.controller.backgroundMode,
        backgroundOpacity: widget.controller.backgroundOpacity,
        centerDisplayMode: SimaiGameplayCenterDisplayMode.fromNameOrLegacy(
          widget.controller.centerDisplayMode.name,
        ),
        noteStyle: widget.controller.noteStyle,
        holdStyle: widget.controller.holdStyle,
        showApproachLine: widget.controller.showApproachLine,
        showHitEffects: widget.controller.showHitEffects,
        hitEffectStyle: widget.controller.hitEffectStyle,
      ),
    );
  }

  void _onControllerChanged() {
    setState(() {});
  }

  void _onPlayerReady() {
    if (!mounted || !_isLoading) return;
    setState(() => _isLoading = false);
    _startHideTimer();
  }

  Future<void> _checkVideoExportSupport() async {
    final generation = ++_videoSupportGeneration;
    if (widget.videoExportMetadata == null) {
      if (mounted && (_videoExportAvailable || _videoExportSupportChecking)) {
        setState(() {
          _videoExportAvailable = false;
          _videoExportSupportChecking = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() => _videoExportSupportChecking = true);
    }
    final exporter = SimaiVideoExporter.instance;
    final supported720 = await exporter.isSupported(
      quality: SimaiVideoQuality.hd720,
    );
    bool supported = supported720;
    if (!supported) {
      supported = await exporter.isSupported(
        quality: SimaiVideoQuality.fullHd1080,
      );
    }
    if (!mounted || generation != _videoSupportGeneration) return;
    setState(() {
      _videoExportAvailable = supported;
      _videoExportSupportChecking = false;
    });
  }

  Future<void> _startVideoExport() async {
    if (_videoExportInProgress) return;
    final metadata = widget.videoExportMetadata;
    if (metadata == null) return;
    final onVideoExported = widget.onVideoExported;
    setState(() => _videoExportInProgress = true);
    try {
      await Navigator.of(context).push<SimaiVideoExportResult>(
        MaterialPageRoute(
          builder: (context) => SimaiVideoExportPage(
            controller: widget.controller,
            metadata: metadata,
            initialOptions: widget.videoExportOptions,
            initialSettings: widget.videoExportSettings,
            onSettingsChanged: widget.onVideoExportSettingsChanged,
            resolveAudioFilePath: widget.resolveVideoExportAudio,
            checkCachedPvFilePath: widget.checkCachedPvFilePath,
            downloadPvFilePath: widget.downloadPvFilePath,
            pvPreviewBuilder: widget.pvPreviewBuilder,
            initialUsePvBackground: widget.initialExportUsePvBackground,
            initialPvVideoPath: widget.initialExportPvVideoPath,
            customNoteSkinSettingBuilder: widget.customNoteSkinSettingBuilder,
            customHitSoundSettingBuilder: widget.customHitSoundSettingBuilder,
            task:
                SimaiVideoExporter.instance.activeTask ??
                SimaiVideoExporter.instance.lastCompletedTask,
            displayFont: widget.displayFont,
            textStyleResolver: widget.textStyleResolver,
            prepareFonts: widget.prepareFonts,
            onVideoExported: (result) {
              if (onVideoExported != null) {
                onVideoExported(result);
                return;
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result.savedToGallery
                        ? '视频已直接保存到系统相册'
                        : '视频已导出：${result.path}',
                  ),
                ),
              );
            },
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _videoExportInProgress = false);
    }
  }

  Future<void> _openVideoExportFromDrawer(BuildContext drawerContext) async {
    Navigator.of(drawerContext).pop();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await _startVideoExport();
  }

  Future<void> _openGameplayFromDrawer(BuildContext drawerContext) async {
    final gameplayController = _resolveGameplayController();
    Navigator.of(drawerContext).pop();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await widget.controller.pause();
    if (!mounted) return;
    // 进入游玩流程前挂起预览轮询，退出后在 finally 中恢复。
    widget.controller.setGameplaySuspended(true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => SimaiGameplayFlowPage(
            controller: gameplayController,
            disposeController: false,
            onEnterGameplay: widget.onEnterGameplay,
            onExitGameplay: widget.onExitGameplay,
          ),
        ),
      );
    } finally {
      widget.controller.setGameplaySuspended(false);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _toggleLock() {
    setState(() {
      _isLocked = !_isLocked;
      _showControls = true;
    });
    _startHideTimer();
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      _isManualExit = true;
      _exitFullScreen();
    } else {
      _isManualExit = false;
      _enterFullScreen();
    }
  }

  Future<void> _enterFullScreen() async {
    setState(() {
      _isFullScreen = true;
      _showControls = true;
      _isManualExit = false;
    });
    widget.controller.isFullScreen = true;
    await FullScreenUtils.enterFullScreen();
    if (mounted && _isFullScreen) _startHideTimer();
  }

  Future<void> _exitFullScreen() async {
    setState(() {
      _isFullScreen = false;
    });
    widget.controller.isFullScreen = false;
    await FullScreenUtils.exitFullScreen();
  }

  Widget _buildSettingsDrawer(BuildContext context) {
    final controller = widget.controller;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );
    final hostTheme = Theme.of(context);

    return Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: colorScheme,
        switchTheme: hostTheme.switchTheme,
        splashFactory: hostTheme.splashFactory,
        splashColor: hostTheme.splashColor,
        highlightColor: hostTheme.highlightColor,
        textTheme: hostTheme.textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
      ),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          return Drawer(
            backgroundColor: colorScheme.surface,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
                    child: Text(
                      '设置',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (controller.title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 16, 20),
                      child: Text(
                        controller.title!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildSectionHeader(context, '功能'),
                        ListTile(
                          leading: const Icon(Icons.sports_esports),
                          title: const Text('谱面游玩'),
                          subtitle: Text(
                            widget.gameplayController == null
                                ? '使用当前谱面和播放器设置开始挑战'
                                : '进入游玩设置并开始挑战',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openGameplayFromDrawer(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        if (widget.videoExportMetadata != null)
                          ListTile(
                            leading: _videoExportInProgress
                                ? const SizedBox.square(
                                    dimension: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.video_file_outlined),
                            title: const Text('视频导出'),
                            subtitle: Text(
                              _videoExportSupportChecking
                                  ? '正在检查设备导出能力'
                                  : _videoExportAvailable
                                  ? '配置并导出谱面预览视频'
                                  : '当前设备暂不支持视频导出',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap:
                                _videoExportAvailable && !_videoExportInProgress
                                ? () => _openVideoExportFromDrawer(context)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(),
                        ),
                        _buildSectionHeader(context, '显示设置'),
                        _buildSegmentedSetting<SimaiMirrorMode>(
                          context,
                          label: '镜像',
                          icon: Icons.flip,
                          value: controller.mirrorMode,
                          segments: const [
                            ButtonSegment(
                              value: SimaiMirrorMode.none,
                              label: Text('无'),
                            ),
                            ButtonSegment(
                              value: SimaiMirrorMode.horizontal,
                              label: Text('左右'),
                            ),
                            ButtonSegment(
                              value: SimaiMirrorMode.vertical,
                              label: Text('上下'),
                            ),
                            ButtonSegment(
                              value: SimaiMirrorMode.full,
                              label: Text('全反'),
                            ),
                          ],
                          onChanged: (v) => controller.mirrorMode = v,
                        ),
                        const SizedBox(height: 16),
                        _buildSegmentedSetting<SimaiNoteStyle>(
                          context,
                          label: 'TAP / SLIDE 头部样式',
                          icon: Icons.style_outlined,
                          value: controller.noteStyle,
                          segments: [
                            for (final style in SimaiNoteStyle.values)
                              ButtonSegment<SimaiNoteStyle>(
                                value: style,
                                label: Text(style.shortLabel),
                              ),
                          ],
                          onChanged: (v) => controller.noteStyle = v,
                        ),
                        const SizedBox(height: 16),
                        _buildSegmentedSetting<SimaiNoteStyle>(
                          context,
                          label: 'HOLD 样式',
                          icon: Icons.hexagon_outlined,
                          value: SimaiNoteStyle.normalizeForHold(
                            controller.holdStyle,
                          ),
                          segments: [
                            for (final style in SimaiNoteStyle.holdValues)
                              ButtonSegment<SimaiNoteStyle>(
                                value: style,
                                label: Text(style.shortLabel),
                              ),
                          ],
                          onChanged: (v) => controller.holdStyle = v,
                        ),
                        if (widget.customNoteSkinSettingBuilder != null) ...[
                          const SizedBox(height: 12),
                          widget.customNoteSkinSettingBuilder!(
                            context,
                            controller,
                            () {},
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildSegmentedSetting<SimaiBackgroundMode>(
                          context,
                          label: '判定线',
                          icon: Icons.blur_on,
                          value: controller.backgroundMode,
                          segments: const [
                            ButtonSegment(
                              value: SimaiBackgroundMode.none,
                              label: Text('无'),
                            ),
                            ButtonSegment(
                              value: SimaiBackgroundMode.dots,
                              label: Text('点'),
                            ),
                            ButtonSegment(
                              value: SimaiBackgroundMode.judgeLine,
                              label: Text('线'),
                            ),
                            ButtonSegment(
                              value: SimaiBackgroundMode.judgeZone,
                              label: Text('区'),
                            ),
                          ],
                          onChanged: (v) => controller.backgroundMode = v,
                        ),
                        _buildSliderSetting(
                          context,
                          label: '背景透明度',
                          icon: Icons.opacity,
                          value: controller.backgroundOpacity,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          onChanged: (v) => controller.backgroundOpacity = v,
                          valueSuffix:
                              '${(controller.backgroundOpacity * 100).round()}%',
                        ),
                        _buildSliderSetting(
                          context,
                          label: 'TAP/HOLD 流速',
                          icon: Icons.speed,
                          value: controller.speed,
                          min: NoteMotion.minSpeed,
                          max: NoteMotion.sonicSpeedValue,
                          divisions: NoteMotion.speedSliderDivisions,
                          onChanged: (v) => controller.speed = v,
                          valueSuffix: NoteMotion.formatSpeedLabel(
                            controller.speed,
                          ),
                        ),
                        _buildSliderSetting(
                          context,
                          label: 'TOUCH 流速',
                          icon: Icons.touch_app_outlined,
                          value: controller.touchSpeed,
                          min: NoteMotion.minSpeed,
                          max: NoteMotion.sonicSpeedValue,
                          divisions: NoteMotion.speedSliderDivisions,
                          onChanged: (v) => controller.touchSpeed = v,
                          valueSuffix: NoteMotion.formatSpeedLabel(
                            controller.touchSpeed,
                          ),
                        ),
                        _buildSliderSetting(
                          context,
                          label: 'SLIDE 显示时机',
                          icon: Icons.schedule,
                          value: controller.slideDisplayTiming,
                          min: NoteMotion.minSlideDisplayTiming,
                          max: NoteMotion.maxSlideDisplayTiming,
                          divisions: NoteMotion.slideDisplayTimingDivisions,
                          onChanged: (v) => controller.slideDisplayTiming = v,
                          valueSuffix: NoteMotion.formatSlideDisplayTiming(
                            controller.slideDisplayTiming,
                          ),
                        ),
                        _buildSliderSetting(
                          context,
                          label: '播放倍速',
                          icon: Icons.slow_motion_video,
                          value: controller.playbackRate.clamp(0.1, 3.0),
                          min: 0.1,
                          max: 3.0,
                          divisions: 58,
                          onChanged: (v) => controller.playbackRate = v,
                          valueSuffix:
                              '${controller.playbackRate.toStringAsFixed(2)}x',
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final rate in const [
                                0.5,
                                0.75,
                                1.0,
                                1.5,
                                2.0,
                                3.0,
                              ])
                                _buildPlaybackRateChip(
                                  context,
                                  rate: rate,
                                  selected:
                                      (controller.playbackRate - rate).abs() <
                                      0.001,
                                  onTap: () => controller.playbackRate = rate,
                                ),
                            ],
                          ),
                        ),
                        if (widget.extraDisplaySettings != null)
                          widget.extraDisplaySettings!,
                        const SizedBox(height: 8),
                        _buildSwitchSetting(
                          context,
                          label: '星星旋转',
                          icon: Icons.rotate_right,
                          value: controller.rotateSlideStar,
                          onChanged: (v) => controller.rotateSlideStar = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '粉色星星头',
                          icon: Icons.star,
                          value: controller.pinkSlideStar,
                          onChanged: (v) => controller.pinkSlideStar = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '绝赞星星使用普通配色',
                          subtitle: '开启后，绝赞 SLIDE 头部与滑条改为普通蓝/黄配色，不显示绝赞橙红色',
                          icon: Icons.star_border,
                          value: controller.standardBreakSlide,
                          onChanged: (v) => controller.standardBreakSlide = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '引导线',
                          icon: Icons.timeline,
                          value: controller.showApproachLine,
                          onChanged: (v) => controller.showApproachLine = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '打击特效',
                          icon: Icons.auto_awesome,
                          value: controller.showHitEffects,
                          onChanged: (v) => controller.showHitEffects = v,
                        ),
                        if (controller.showHitEffects)
                          _buildDropdownSetting<SimaiHitEffectStyle>(
                            context,
                            label: '打击特效样式',
                            icon: Icons.flare,
                            value: controller.hitEffectStyle,
                            helperText: controller.hitEffectStyle.description,
                            itemHeight: null,
                            selectedItemBuilder: (context) => [
                              for (final style in SimaiHitEffectStyle.values)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: kMinInteractiveDimension,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(style.label),
                                  ),
                                ),
                            ],
                            items: [
                              for (final style in SimaiHitEffectStyle.values)
                                DropdownMenuItem<SimaiHitEffectStyle>(
                                  value: style,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          style.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          style.description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (v) => controller.hitEffectStyle = v,
                          ),
                        _buildSwitchSetting(
                          context,
                          label: '判定表示',
                          icon: Icons.fact_check_outlined,
                          value: controller.showJudgementDisplay,
                          onChanged: (v) => controller.showJudgementDisplay = v,
                        ),
                        if (controller.showJudgementDisplay)
                          _buildDropdownSetting<SimaiJudgementDisplayMode>(
                            context,
                            label: '判定表示类型',
                            icon: Icons.tune,
                            value: controller.judgementDisplayMode,
                            helperText:
                                controller.judgementDisplayMode.description,
                            itemHeight: null,
                            selectedItemBuilder: (context) => [
                              for (final mode
                                  in SimaiJudgementDisplayMode.values)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: kMinInteractiveDimension,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(mode.label),
                                  ),
                                ),
                            ],
                            items: [
                              for (final mode
                                  in SimaiJudgementDisplayMode.values)
                                DropdownMenuItem<SimaiJudgementDisplayMode>(
                                  value: mode,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          mode.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          mode.description,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (v) =>
                                controller.judgementDisplayMode = v,
                          ),
                        const SizedBox(height: 8),
                        _buildDropdownSetting<SimaiAutoPlayMode>(
                          context,
                          label: '模拟游玩方式',
                          icon: Icons.smart_toy_outlined,
                          value: controller.autoPlayMode,
                          helperText: controller.autoPlayMode.description,
                          itemHeight: null,
                          selectedItemBuilder: (context) => [
                            for (final mode in SimaiAutoPlayMode.values)
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: kMinInteractiveDimension,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(mode.label),
                                ),
                              ),
                          ],
                          items: [
                            for (final mode in SimaiAutoPlayMode.values)
                              DropdownMenuItem<SimaiAutoPlayMode>(
                                value: mode,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        mode.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        mode.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                          onChanged: (v) => controller.autoPlayMode = v,
                        ),
                        if (controller.autoPlayMode.hasRandomDetails) ...[
                          const SizedBox(height: 8),
                          _buildAutoPlayRandomPanel(context),
                        ],
                        const SizedBox(height: 16),
                        _buildDropdownSetting<SimaiCenterDisplayMode>(
                          context,
                          label: '中央显示',
                          icon: Icons.swap_vert,
                          value: controller.centerDisplayMode,
                          items: [
                            for (final mode in SimaiCenterDisplayMode.values)
                              DropdownMenuItem<SimaiCenterDisplayMode>(
                                value: mode,
                                child: Text(mode.label),
                              ),
                          ],
                          onChanged: (v) => controller.centerDisplayMode = v,
                        ),
                        _buildDropdownSetting<SimaiCenterDisplayMode>(
                          context,
                          label: '右上角显示',
                          icon: Icons.north_east_rounded,
                          value: controller.topRightDisplayMode,
                          items: [
                            for (final mode in SimaiCenterDisplayMode.values)
                              DropdownMenuItem<SimaiCenterDisplayMode>(
                                value: mode,
                                child: Text(mode.label),
                              ),
                          ],
                          onChanged: (v) => controller.topRightDisplayMode = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '显示达成率',
                          icon: Icons.percent,
                          value: controller.showAchievementRate,
                          onChanged: (v) => controller.showAchievementRate = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '高亮保护套',
                          icon: Icons.brightness_high,
                          value: controller.highlightExNotes,
                          onChanged: (v) => controller.highlightExNotes = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '四角信息',
                          icon: Icons.dashboard_customize_outlined,
                          value: controller.showCornerInfo,
                          onChanged: (v) => controller.showCornerInfo = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: '详细性能信息',
                          icon: Icons.monitor_heart_outlined,
                          value: controller.showDetailedPerformanceInfo,
                          onChanged: (v) =>
                              controller.showDetailedPerformanceInfo = v,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(),
                        ),
                        _buildSectionHeader(context, '音频设置'),
                        _buildSwitchSetting(
                          context,
                          label: '正解音播放',
                          icon: Icons.music_note,
                          value: controller.hitSoundEnabled,
                          onChanged: (v) => controller.hitSoundEnabled = v,
                        ),
                        if (widget.customHitSoundSettingBuilder != null)
                          widget.customHitSoundSettingBuilder!(
                            context,
                            controller,
                            () {},
                          ),
                        _buildSliderSetting(
                          context,
                          label: '音乐音量',
                          icon: Icons.volume_up,
                          value: controller.musicVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 100,
                          onChanged: (v) => controller.musicVolume = v,
                          valueSuffix:
                              '${(controller.musicVolume * 100).toInt()}%',
                        ),
                        _buildSliderSetting(
                          context,
                          label: '正解音音量',
                          icon: Icons.graphic_eq,
                          value: controller.hitSoundVolume.clamp(
                            0.0,
                            simaiMaxHitSoundVolume,
                          ),
                          min: 0.0,
                          max: simaiMaxHitSoundVolume,
                          divisions: 60,
                          onChanged: (v) => controller.hitSoundVolume = v,
                          valueSuffix:
                              '${(controller.hitSoundVolume * 100).round()}%',
                        ),
                        _buildSliderSetting(
                          context,
                          label: '音乐偏移',
                          icon: Icons.audiotrack,
                          value: controller.musicOffsetMs.toDouble(),
                          min: -2000,
                          max: 2000,
                          divisions: 400,
                          onChanged: (v) =>
                              controller.musicOffsetMs = v.toInt(),
                          valueSuffix: '${controller.musicOffsetMs}ms',
                        ),
                        _buildSliderSetting(
                          context,
                          label: '正解音偏移',
                          icon: Icons.timer,
                          value: controller.hitSoundOffsetMs.toDouble(),
                          min: -200,
                          max: 200,
                          divisions: 40,
                          onChanged: (v) =>
                              controller.hitSoundOffsetMs = v.toInt(),
                          valueSuffix: '${controller.hitSoundOffsetMs}ms',
                        ),
                        if (widget.hasPvBackground) ...[
                          _buildSliderSetting(
                            context,
                            label: 'PV 延迟',
                            icon: Icons.ondemand_video_outlined,
                            value: controller.pvOffsetMs.toDouble(),
                            min: -2000,
                            max: 2000,
                            divisions: 400,
                            onChanged: (v) =>
                                controller.pvOffsetMs = v.round(),
                            valueSuffix:
                                '${controller.pvOffsetMs > 0 ? '+' : ''}${controller.pvOffsetMs}ms',
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final delta in const [-50, -10, 0, 10, 50])
                                  _buildOffsetQuickChip(
                                    context,
                                    label: delta == 0
                                        ? '0ms'
                                        : '${delta > 0 ? '+' : ''}${delta}ms',
                                    selected:
                                        delta == 0 && controller.pvOffsetMs == 0,
                                    onTap: () => controller.pvOffsetMs =
                                        delta == 0
                                        ? 0
                                        : (controller.pvOffsetMs + delta)
                                              .clamp(-2000, 2000),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// 构建“随机判定明细 + 重新随机判定”区域，仅在含随机判定的模拟模式下展示。
  Widget _buildAutoPlayRandomPanel(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              controller.autoPlayTimeline.summaryLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: controller.randomizeAutoPlaySeed,
                icon: const Icon(Icons.shuffle_rounded, size: 16),
                label: const Text('重新随机判定'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedSetting<T>(
    BuildContext context, {
    required String label,
    required IconData icon,
    required T value,
    required List<ButtonSegment<T>> segments,
    required ValueChanged<T> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
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
            onSelectionChanged: (Set<T> newSelection) {
              onChanged(newSelection.first);
            },
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
        ),
      ],
    );
  }

  /// 构建侧边栏下拉选择项（用于选项较多的模式切换，避免分段按钮横向溢出）。
  Widget _buildDropdownSetting<T>(
    BuildContext context, {
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
    String? helperText,
    DropdownButtonBuilder? selectedItemBuilder,
    double? itemHeight = kMinInteractiveDimension,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                itemHeight: itemHeight,
                selectedItemBuilder: selectedItemBuilder,
                dropdownColor: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                items: items,
                onChanged: (selected) {
                  if (selected != null) {
                    onChanged(selected);
                  }
                },
              ),
            ),
          ),
          if (helperText != null && helperText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0, left: 4.0, right: 4.0),
              child: Text(
                helperText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    BuildContext context, {
    required String label,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.bodyLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing:
          widget.switchBuilder?.call(context, value, onChanged) ??
          Switch(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    );
  }

  Widget _buildSliderSetting(
    BuildContext context, {
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    String? valueSuffix,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
                if (valueSuffix != null)
                  Text(
                    valueSuffix,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
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
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildOffsetQuickChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.onSurface.withValues(alpha: 0.08),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackRateChip(
    BuildContext context, {
    required double rate,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.onSurface.withValues(alpha: 0.08),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            '${rate}x',
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent == true;
    final orientation = MediaQuery.of(context).orientation;
    final canRotate = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final returningToPortrait = canRotate &&
        _isManualExit &&
        orientation == Orientation.landscape;

    // 手动进入全屏时，等系统完成旋转；同一竖屏尺寸的重建不能撤销这次切换。
    // 仅当前页面位于路由栈顶时响应横竖屏切换，杜绝横屏游玩期间底层预览页误入全屏。
    if (!_isLoading &&
        isCurrentRoute &&
        canRotate &&
        _observedOrientation != orientation) {
      _observedOrientation = orientation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _observedOrientation != orientation ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        if (orientation == Orientation.landscape &&
            !_isFullScreen &&
            !_isManualExit) {
          _enterFullScreen();
        } else if (orientation == Orientation.portrait) {
          if (_isFullScreen) {
            _exitFullScreen();
          }
          if (_isManualExit) {
            setState(() {
              _isManualExit = false;
            });
          }
        }
      });
    }

    final player = SimaiPlayer(
      key: _playerKey,
      controller: widget.controller,
      displayFont: widget.displayFont,
      textStyleResolver: widget.textStyleResolver,
      backgroundVideo: widget.backgroundVideo,
      onReady: _onPlayerReady,
      onError: (error) {
        if (!mounted) return;
        setState(() => _loadError = error);
      },
    );

    Widget body;
    PreferredSizeWidget? appBar;

    if (_isLoading) {
      appBar = AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              widget.onBack ?? () => Navigator.of(context).maybePop<void>(),
        ),
      );
      body = Stack(
        fit: StackFit.expand,
        children: [
          Offstage(
            offstage: true,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(aspectRatio: 1.0, child: player),
                  ),
                ),
                SimaiPlayerControls(controller: widget.controller),
              ],
            ),
          ),
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: _loadError == null
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '谱面预览加载失败，请退出后重试。\n$_loadError',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
            ),
          ),
        ],
      );
    } else if (!_isFullScreen && !returningToPortrait) {
      appBar = AppBar(
        title: Text(widget.title ?? widget.controller.title ?? ''),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context) || widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Simai 源码',
            icon: const Icon(Icons.lyrics_outlined),
            onPressed: () => _playerKey.currentState?.toggleSourceOverlay(),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      );

      body = Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: RepaintBoundary(child: player),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: RepaintBoundary(
              child: SimaiPlayerControls(
                controller: widget.controller,
                beforeTimeline: widget.beforeTimeline,
              ),
            ),
          ),
        ],
      );
    } else {
      body = MouseRegion(
        onHover: (_) {
          if (!_showControls) {
            setState(() {
              _showControls = true;
            });
          }
          _startHideTimer();
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: RepaintBoundary(child: player),
                ),
              ),
              // Top Bar
              IgnorePointer(
                ignoring: !_showControls || _isLocked,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: (_showControls && !_isLocked) ? 1.0 : 0.0,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                        child: Row(
                          children: [
                            if (Navigator.canPop(context) ||
                                widget.onBack != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                                onPressed:
                                    widget.onBack ??
                                    () => Navigator.of(context).pop(),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.title ?? widget.controller.title ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Simai 源码',
                              icon: const Icon(
                                Icons.lyrics_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () => _playerKey.currentState
                                  ?.toggleSourceOverlay(),
                            ),
                            Builder(
                              builder: (context) => IconButton(
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Scaffold.of(context).openEndDrawer();
                                  _hideTimer
                                      ?.cancel(); // Don't hide while drawer is open
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showControls || _isLocked,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: (_showControls && !_isLocked) ? 1.0 : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: RepaintBoundary(
                            child: SimaiPlayerControls(
                              controller: widget.controller,
                              beforeTimeline: widget.beforeTimeline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Lock Button
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: SafeArea(
                  left: false,
                  top: false,
                  bottom: false,
                  child: Center(
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _showControls ? 1.0 : 0.0,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                            ),
                            icon: Icon(
                              _isLocked ? Icons.lock : Icons.lock_open,
                            ),
                            onPressed: _toggleLock,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        if (_isFullScreen)
          const SingleActivator(LogicalKeyboardKey.escape): () {
            _isManualExit = true;
            _exitFullScreen();
          },
      },
      child: Focus(
        autofocus: !canRotate,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: appBar,
          endDrawer: _isLoading ? null : _buildSettingsDrawer(context),
          body: body,
        ),
      ),
    );
  }
}
