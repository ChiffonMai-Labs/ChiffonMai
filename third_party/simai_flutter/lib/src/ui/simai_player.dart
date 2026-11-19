import 'dart:async';
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
  bool _isPlaying = false;
  double _playbackRate = 1.0;
  double _musicVolume = 0.8;
  int _musicOffsetMs = 0;
  int _hitSoundOffsetMs = 0;
  bool _hitSoundEnabled = false;
  bool _isFullScreen = false;
  SimaiBackgroundMode _backgroundMode = SimaiBackgroundMode.judgeLine;
  SimaiMirrorMode _mirrorMode = SimaiMirrorMode.none;
  bool _rotateSlideStar = true;
  bool _pinkSlideStar = false;
  bool _standardBreakSlide = false;
  bool _highlightExNotes = false;
  bool _showApproachLine = true;
  bool _showHitEffects = true;
  bool _showAchievementRate = true;
  SimaiCenterDisplayMode _centerDisplayMode =
      SimaiCenterDisplayMode.achievement;
  bool _showCornerInfo = true;
  bool _showDetailedPerformanceInfo = false;

  double _chartTimeSnapshot = 0.0;
  int _seekGeneration = 0;
  double _totalDurationSnapshot = 0.0;
  late final int _noteCountSnapshot;
  bool _isDisposed = false;

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
  bool get isPlaying => _isPlaying;
  double get playbackRate => _playbackRate;
  double get musicVolume => _musicVolume;
  int get musicOffsetMs => _musicOffsetMs;
  int get hitSoundOffsetMs => _hitSoundOffsetMs;
  bool get hitSoundEnabled => _hitSoundEnabled;
  bool get isFullScreen => _isFullScreen;
  SimaiBackgroundMode get backgroundMode => _backgroundMode;
  SimaiMirrorMode get mirrorMode => _mirrorMode;
  bool get rotateSlideStar => _rotateSlideStar;
  bool get pinkSlideStar => _pinkSlideStar;
  bool get standardBreakSlide => _standardBreakSlide;
  bool get highlightExNotes => _highlightExNotes;
  bool get showApproachLine => _showApproachLine;
  bool get showHitEffects => _showHitEffects;
  bool get showAchievementRate => _showAchievementRate;
  SimaiCenterDisplayMode get centerDisplayMode => _centerDisplayMode;
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
      approachTime * NoteMotion.touchApproachMultiplier;

  double get effectiveMusicOffsetSeconds {
    return initialChartTime + _musicOffsetMs / 1000.0;
  }

  set speed(double value) {
    final safeValue = value.isFinite ? value : 8.0;
    final clamped = safeValue.clamp(3.0, 9.0).toDouble();
    final quantized = (clamped / 0.25).round() * 0.25;
    if (_speed == quantized) return;
    _speed = quantized;
    _applyToGame();
    notifyListeners();
  }

  set playbackRate(double value) {
    final safeValue = value.isFinite ? value : 1.0;
    final clamped = safeValue.clamp(0.1, 1.0).toDouble();
    if (_playbackRate == clamped) return;
    _playbackRate = clamped;
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
    _chartTimeSnapshot = clamped;
    timeNotifier.value = clamped;
    final game = _game;
    if (game == null) {
      notifyListeners();
      return;
    }
    await game.seek(clamped, syncAudio: syncAudio);
    if (generation != _seekGeneration) return;
    _chartTimeSnapshot = game.chartTime;
    timeNotifier.value = game.chartTime;
    // Don't notifyListeners here as it's just a time change
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

  double computePreviousNoteTime(double time) {
    if (chart.noteCollections.isEmpty) return time;
    const double tolerance = 0.1;

    int lo = 0;
    int hi = chart.noteCollections.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final t = chart.noteCollections[mid].time;
      if (t < time - tolerance) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    if (hi < 0) return 0.0;
    return chart.noteCollections[hi].time;
  }

  double computeNextNoteTime(double time) {
    if (chart.noteCollections.isEmpty) return time;
    final epsilon = 1e-6;

    int index = _findCollectionIndex(time);
    index++;

    if (index >= chart.noteCollections.length) return time;

    if (chart.noteCollections[index].time <= time + epsilon) {
      index++;
    }

    if (index >= chart.noteCollections.length) return time;
    return chart.noteCollections[index].time;
  }

  int _findCollectionIndex(double time) {
    int lo = 0;
    int hi = chart.noteCollections.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final t = chart.noteCollections[mid].time;
      if (t <= time) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return hi;
  }

  void _attachGame(SimaiGame game) {
    if (identical(_game, game)) return;
    _pollTimer?.cancel();
    _game = game;
    game.onPlaybackCompleted = _handlePlaybackCompleted;
    _applyToGame();
    _totalDurationSnapshot = game.totalDuration;
    _chartTimeSnapshot = game.chartTime;
    timeNotifier.value = game.chartTime;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      final g = _game;
      if (g == null) return;
      final t = g.chartTime;
      if ((_chartTimeSnapshot - t).abs() < 0.0001) return;
      _chartTimeSnapshot = t;
      timeNotifier.value = t;
      // notifyListeners(); // REMOVED to prevent full UI rebuilds
    });
    // Use a microtask to notify listeners to avoid "setState during build" errors
    // when called from initState or didUpdateWidget of a child widget.
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

  void _applyToGame({bool resyncAudio = false}) {
    final game = _game;
    if (game == null) return;
    final approach = approachTime;
    game.ringApproachTime = approach;
    game.touchApproachTime = touchApproachTime;
    game.offset = effectiveMusicOffsetSeconds;
    game.hitSoundOffset = _hitSoundOffsetMs / 1000.0;
    game.hitSoundEnabled = _hitSoundEnabled;
    game.setPlaying(_isPlaying);
    game.setAudioAsset(audioAsset);
    game.setAudioFilePath(audioFilePath);
    game.setBackgroundImageProvider(backgroundImageProvider);
    game.setPlaybackRate(_playbackRate);
    game.setMusicVolume(_musicVolume);
    game.setBackgroundMode(_backgroundMode);
    game.setMirrorMode(_mirrorMode);
    game.rotateSlideStar = _rotateSlideStar;
    game.pinkSlideStar = _pinkSlideStar;
    game.standardBreakSlide = _standardBreakSlide;
    game.highlightExNotes = _highlightExNotes;
    game.showApproachLine = _showApproachLine;
    game.showHitEffects = _showHitEffects;
    game.showAchievementRate = _showAchievementRate;
    game.centerDisplayMode = _centerDisplayMode;
    game.showCornerInfo = _showCornerInfo;
    game.showDetailedPerformanceInfo = _showDetailedPerformanceInfo;
    game.invalidateNotes();
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

  const SimaiPlayer({
    super.key,
    required this.controller,
    this.onReady,
    this.onError,
    this.displayFont,
  });

  @override
  State<SimaiPlayer> createState() => _SimaiPlayerState();
}

class _SimaiPlayerState extends State<SimaiPlayer> {
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
      playbackRate: controller.playbackRate,
      musicVolume: controller.musicVolume,
      hitSoundOffset: controller.hitSoundOffsetMs / 1000.0,
      hitSoundEnabled: controller.hitSoundEnabled,
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
      showDetailedPerformanceInfo: controller.showDetailedPerformanceInfo,
      initialChartTime: controller.initialChartTime,
      offset: controller.effectiveMusicOffsetSeconds,
      audioAsset: controller.audioAsset,
      audioFilePath: controller.audioFilePath,
      backgroundImageProvider: controller.backgroundImageProvider,
      displayFont: widget.displayFont,
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
    }
  }

  @override
  void dispose() {
    widget.controller._detachGame(_game);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget(
          game: _game,
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
                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollStartNotification &&
                            notification.dragDetails != null) {
                          _userControllingScroll = true;
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
                        padding: const EdgeInsets.symmetric(vertical: 24),
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

class SimaiPlayerPage extends StatefulWidget {
  final SimaiPlayerController controller;
  final SimaiGameplayController? gameplayController;
  final String? title;
  final VoidCallback? onBack;
  final bool disposeController;
  final SimaiVideoMetadata? videoExportMetadata;
  final SimaiVideoExportOptions videoExportOptions;
  final ValueChanged<SimaiVideoExportResult>? onVideoExported;
  final Widget? beforeTimeline;
  final TextStyle? displayFont;

  /// 全屏状态变化回调（进入为 true，退出 / 页面销毁为 false）。
  ///
  /// 宿主用它把全屏标志同步给系统栏偏好，播放器本身不依赖 App 层。
  final ValueChanged<bool>? onFullScreenChanged;

  const SimaiPlayerPage({
    super.key,
    required this.controller,
    this.gameplayController,
    this.title,
    this.onBack,
    this.disposeController = true,
    this.videoExportMetadata,
    this.videoExportOptions = const SimaiVideoExportOptions(),
    this.onVideoExported,
    this.beforeTimeline,
    this.displayFont,
    this.onFullScreenChanged,
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
    // 无条件复位：即使全屏状态已经和系统不同步，也把沉浸和方向交还给宿主。
    widget.controller.isFullScreen = false;
    widget.onFullScreenChanged?.call(false);
    unawaited(FullScreenUtils.exitFullScreen());
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
        musicOffsetMs: widget.controller.musicOffsetMs,
        musicVolume: widget.controller.musicVolume,
        mirrorMode: widget.controller.mirrorMode,
        backgroundMode: widget.controller.backgroundMode,
        centerDisplayMode:
            widget.controller.centerDisplayMode == SimaiCenterDisplayMode.combo
            ? SimaiGameplayCenterDisplayMode.combo
            : SimaiGameplayCenterDisplayMode.achievementAdd,
        showApproachLine: widget.controller.showApproachLine,
        showHitEffects: widget.controller.showHitEffects,
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
            task: SimaiVideoExporter.instance.activeTask,
            onVideoExported: (result) {
              onVideoExported?.call(result);
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('视频已导出：${result.path}')));
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
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SimaiGameplayFlowPage(
          controller: gameplayController,
          disposeController: false,
        ),
      ),
    );
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
    widget.onFullScreenChanged?.call(true);
    await FullScreenUtils.enterFullScreen();
    if (mounted && _isFullScreen) _startHideTimer();
  }

  Future<void> _exitFullScreen() async {
    setState(() {
      _isFullScreen = false;
    });
    widget.controller.isFullScreen = false;
    widget.onFullScreenChanged?.call(false);
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
                          label: '流速',
                          icon: Icons.speed,
                          value: controller.speed,
                          min: 3.0,
                          max: 9.0,
                          divisions: 24,
                          onChanged: (v) => controller.speed = v,
                          valueSuffix:
                              'x${controller.speed.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 16),
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
                          label: '标准色绝赞星星',
                          icon: Icons.star_border,
                          value: controller.standardBreakSlide,
                          onChanged: (v) => controller.standardBreakSlide = v,
                        ),
                        _buildSwitchSetting(
                          context,
                          label: 'Approach Line',
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
                        const SizedBox(height: 16),
                        _buildSegmentedSetting<SimaiCenterDisplayMode>(
                          context,
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
                          onChanged: (v) => controller.centerDisplayMode = v,
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

  Widget _buildSwitchSetting(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: Switch(value: value, onChanged: onChanged),
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

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    // 平板 / 展开态方向自由，转动不再自动进出全屏；手机仍以「横屏 = 全屏」
    // 兜底全屏按钮转屏过程中的状态。
    final wideScreen = MediaQuery.sizeOf(context).shortestSide >= 600;
    final canRotate =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    // _isManualExit 只在窄屏有意义：退出全屏后等系统转回竖屏期间保持沉浸布局，
    // 避免旋转动画里先闪出 AppBar。宽屏退出后方向不变，AppBar 必须立刻回来。
    final returningToPortrait =
        canRotate &&
        !wideScreen &&
        _isManualExit &&
        orientation == Orientation.landscape;

    // 宽屏不自动进出全屏，但朝向记录要继续跟随：否则展开期间冻结在
    // landscape，折回窄屏时会拿旧值把宿主刚申请的横屏改回竖屏。
    if (wideScreen) _observedOrientation = orientation;

    // 手动进入全屏时，等系统完成旋转；同一竖屏尺寸的重建不能撤销这次切换。
    if (!_isLoading &&
        canRotate &&
        !wideScreen &&
        _observedOrientation != orientation) {
      _observedOrientation = orientation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _observedOrientation != orientation) return;
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
            child: Center(child: AspectRatio(aspectRatio: 1.0, child: player)),
          ),
          SafeArea(
            top: false,
            child: SimaiPlayerControls(
              controller: widget.controller,
              beforeTimeline: widget.beforeTimeline,
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
              Center(child: AspectRatio(aspectRatio: 1.0, child: player)),
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
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_isFullScreen) {
            _isManualExit = true;
            _exitFullScreen();
          }
        },
      },
      child: Focus(
        autofocus: true,
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
