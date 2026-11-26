import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../simai_flutter.dart';
import 'chart_pattern_analyzer.dart';
import 'chart_timing_mapper.dart';
import 'simai_colors.dart';

class SimaiPlayerControls extends StatefulWidget {
  final SimaiPlayerController controller;
  final Widget? beforeTimeline;

  const SimaiPlayerControls({
    super.key,
    required this.controller,
    this.beforeTimeline,
  });

  @override
  State<SimaiPlayerControls> createState() => _SimaiPlayerControlsState();
}

class _SimaiPlayerControlsState extends State<SimaiPlayerControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(SimaiPlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    Widget sideButton(IconData icon, String tooltip, VoidCallback? onPressed) {
      return Flexible(
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          tooltip: tooltip,
          style: IconButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: onPressed,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.beforeTimeline != null) widget.beforeTimeline!,
          _SimaiTimeline(controller: controller, height: 140),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              sideButton(
                Icons.skip_previous,
                'Previous Measure',
                controller.previousMeasure,
              ),
              sideButton(
                Icons.navigate_before,
                'Previous Note',
                controller.previousNote,
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
                iconSize: 32,
                icon: Icon(
                  controller.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: controller.togglePlayPause,
              ),
              sideButton(Icons.navigate_next, 'Next Note', controller.nextNote),
              sideButton(
                Icons.skip_next,
                'Next Measure',
                controller.nextMeasure,
              ),
              sideButton(
                Icons.replay,
                'Replay Measure',
                controller.replayMeasure,
              ),
              sideButton(
                controller.isFullScreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen,
                controller.isFullScreen ? 'Exit Full Screen' : 'Full Screen',
                controller.onToggleFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TimelineCategory { tap, touch, each, slide, breakNote }

class _NoteEvent {
  final double time;
  final _TimelineCategory category;

  const _NoteEvent({required this.time, required this.category});
}

class _TimelineData {
  final double totalDuration;
  final List<_NoteEvent> events;
  final List<double> measureStartTimes;
  final List<_TempoMarker> tempoMarkers;
  final List<SimaiMeasureStatement> statements;

  const _TimelineData({
    required this.totalDuration,
    required this.events,
    required this.measureStartTimes,
    required this.tempoMarkers,
    required this.statements,
  });
}

class _TempoMarker {
  final double time;
  final double tempo;
  final bool increased;

  const _TempoMarker({
    required this.time,
    required this.tempo,
    required this.increased,
  });
}

List<double> _computeChartMeasureStartTimes(MaiChart chart, double total) {
  final starts = <double>[];
  const epsilon = 1e-6;

  void addStart(double t) {
    final clamped = t.clamp(0.0, total).toDouble();
    if (starts.isEmpty) {
      starts.add(clamped);
      return;
    }
    if ((clamped - starts.last).abs() <= 1e-4) return;
    if (clamped < starts.last - 1e-4) return;
    starts.add(clamped);
  }

  final totalSeconds = total.isFinite && total > 0 ? total : 0.0;
  final totalBeats = ChartTimingMapper.beatsAtTime(chart, totalSeconds);
  addStart(0.0);
  for (double b = 4.0; b <= totalBeats + epsilon; b += 4.0) {
    final t = ChartTimingMapper.timeAtBeats(chart, b);
    if (t > totalSeconds + epsilon) break;
    addStart(t);
  }
  return starts;
}

class _SimaiTimeline extends StatefulWidget {
  final SimaiPlayerController controller;
  final double height;

  const _SimaiTimeline({required this.controller, required this.height});

  @override
  State<_SimaiTimeline> createState() => _SimaiTimelineState();
}

class _SimaiTimelineState extends State<_SimaiTimeline> {
  double? _dragTime;
  double _totalDuration = 1.0;
  List<SimaiMeasureStatement> _statements = const [];

  @override
  void initState() {
    super.initState();
    _rebuildStatements();
  }

  @override
  void didUpdateWidget(_SimaiTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _dragTime = null;
      _rebuildStatements();
    }
  }

  void _rebuildStatements() {
    final controller = widget.controller;
    double total = controller.chartInfo.totalDuration > 0
        ? controller.chartInfo.totalDuration
        : 0.0;
    if (total <= 0) {
      double maxT = 0.0;
      for (final collection in controller.chart.noteCollections) {
        if (collection.isNotEmpty && collection.time > maxT) {
          maxT = collection.time;
        }
      }
      total = maxT <= 0 ? 1.0 : maxT;
    }
    final measureStartTimes = _computeChartMeasureStartTimes(
      controller.chart,
      total,
    );
    _totalDuration = total;
    _statements = SimaiChartPatternAnalyzer.buildStatements(
      controller.chart,
      measureStartTimes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final densityHeight = math.max(0.0, widget.height - 44.0);
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Column(
        children: [
          // 将谱面语句条与时间轴直方图拆成独立 RepaintBoundary，且仅在当前小节/音符索引变化时重建语句条。
          SizedBox(
            height: 44,
            width: double.infinity,
            child: RepaintBoundary(
              child: _SimaiStatementDisplay(
                controller: controller,
                statements: _statements,
                dragTime: _dragTime,
              ),
            ),
          ),
          Expanded(
            child: SimaiDensityTimeline(
              chart: controller.chart,
              totalDuration: _totalDuration,
              timeListenable: controller.timeNotifier,
              isPlaying: controller.isPlaying,
              onSeek: (time, {bool syncAudio = true}) =>
                  controller.seek(time, syncAudio: syncAudio),
              onPause: controller.pause,
              onPlay: controller.play,
              height: densityHeight,
              playbackRate: controller.playbackRate,
              onDragTimeChanged: (dragTime) {
                if (!mounted || _dragTime == dragTime) return;
                setState(() => _dragTime = dragTime);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 可复用的谱面密度直方图与进度条组件（含小节刻度、变速标记、播放头及点击/拖动定位）。
class SimaiDensityTimeline extends StatefulWidget {
  final MaiChart chart;
  final double totalDuration;
  final ValueListenable<double> timeListenable;
  final bool isPlaying;
  final FutureOr<void> Function(double time, {bool syncAudio}) onSeek;
  final FutureOr<void> Function() onPause;
  final FutureOr<void> Function() onPlay;
  final double height;
  final double playbackRate;
  final ValueChanged<double?>? onDragTimeChanged;

  const SimaiDensityTimeline({
    super.key,
    required this.chart,
    required this.totalDuration,
    required this.timeListenable,
    required this.isPlaying,
    required this.onSeek,
    required this.onPause,
    required this.onPlay,
    required this.height,
    this.playbackRate = 1.0,
    this.onDragTimeChanged,
  });

  @override
  State<SimaiDensityTimeline> createState() => _SimaiDensityTimelineState();
}

class _SimaiDensityTimelineState extends State<SimaiDensityTimeline> {
  bool _isDragging = false;
  bool _wasPlayingBeforeDrag = false;
  double _dragTime = 0.0;

  _TimelineData? _data;
  Object _staticLayerIdentity = Object();
  final _TimelineStaticLayerCache _staticLayerCache =
      _TimelineStaticLayerCache();
  double _lastWidth = 0.0;
  int _lastBinCount = 0;
  List<int> _tapBins = const [];
  List<int> _touchBins = const [];
  List<int> _eachBins = const [];
  List<int> _slideBins = const [];
  List<int> _breakBins = const [];
  int _maxBinSum = 1;

  @override
  void initState() {
    super.initState();
    _rebuildData();
    _dragTime = widget.timeListenable.value;
  }

  @override
  void dispose() {
    _staticLayerCache.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SimaiDensityTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.chart, oldWidget.chart) ||
        (widget.totalDuration - oldWidget.totalDuration).abs() > 1e-6) {
      _isDragging = false;
      _wasPlayingBeforeDrag = false;
      _lastWidth = 0.0;
      _lastBinCount = 0;
      _staticLayerCache.invalidate();
      _rebuildData();
      _dragTime = widget.timeListenable.value;
    }
  }

  void _rebuildData() {
    final total = widget.totalDuration.isFinite && widget.totalDuration > 0
        ? widget.totalDuration
        : 0.0;
    final events = <_NoteEvent>[];
    for (final collection in widget.chart.noteCollections) {
      final collectionTime = collection.time;
      for (final note in collection) {
        final category = _categorize(collection, note);
        events.add(_NoteEvent(time: collectionTime, category: category));
      }
    }
    final resolvedTotal = total > 0 ? total : _inferTotalFromEvents(events);
    final measureStartTimes = _computeChartMeasureStartTimes(
      widget.chart,
      resolvedTotal,
    );
    _data = _TimelineData(
      totalDuration: resolvedTotal,
      events: events,
      measureStartTimes: measureStartTimes,
      tempoMarkers: _computeTempoMarkers(widget.chart),
      statements: const [],
    );
    _staticLayerIdentity = Object();
  }

  static List<_TempoMarker> _computeTempoMarkers(MaiChart chart) {
    final changes = [...chart.timingChanges]
      ..sort((a, b) => a.time.compareTo(b.time));
    final markers = <_TempoMarker>[];
    double? previousTempo;
    for (final change in changes) {
      if (change.tempo <= 0) continue;
      if (previousTempo != null &&
          (change.tempo - previousTempo).abs() > 0.0001) {
        markers.add(
          _TempoMarker(
            time: change.time,
            tempo: change.tempo,
            increased: change.tempo > previousTempo,
          ),
        );
      }
      previousTempo = change.tempo;
    }
    return markers;
  }

  static double _inferTotalFromEvents(List<_NoteEvent> events) {
    double maxT = 0.0;
    for (final e in events) {
      if (e.time > maxT) maxT = e.time;
    }
    return maxT <= 0 ? 1.0 : maxT;
  }

  static _TimelineCategory _categorize(NoteCollection collection, Note note) {
    final isBreak =
        note.type == NoteType.breakNote ||
        (note.styles & NoteStyles.breakHead) != 0;
    if (isBreak) return _TimelineCategory.breakNote;
    final isEach =
        collection.eachStyle != EachStyle.forceBroken &&
        (collection.eachStyle == EachStyle.forEach || collection.length > 1);
    if (isEach) {
      return _TimelineCategory.each;
    }
    final isSlide = note.type == NoteType.slide || note.slidePaths.isNotEmpty;
    if (isSlide) return _TimelineCategory.slide;
    if (note.type == NoteType.touch) return _TimelineCategory.touch;
    return _TimelineCategory.tap;
  }

  void _ensureBinsForWidth(double width) {
    final data = _data;
    if (data == null) return;
    if (width <= 0) return;
    final binCount = (width / 3.0).floor().clamp(24, 600);
    final widthChanged = (width - _lastWidth).abs() >= 1.0;
    if (!widthChanged && binCount == _lastBinCount) return;
    _lastWidth = width;
    _lastBinCount = binCount;

    _tapBins = List<int>.filled(binCount, 0);
    _touchBins = List<int>.filled(binCount, 0);
    _eachBins = List<int>.filled(binCount, 0);
    _slideBins = List<int>.filled(binCount, 0);
    _breakBins = List<int>.filled(binCount, 0);

    final total = data.totalDuration > 0 ? data.totalDuration : 1.0;
    for (final e in data.events) {
      final ratio = (e.time / total).clamp(0.0, 1.0);
      final idx = (ratio * binCount).floor().clamp(0, binCount - 1);
      switch (e.category) {
        case _TimelineCategory.tap:
          _tapBins[idx] += 1;
          break;
        case _TimelineCategory.touch:
          _touchBins[idx] += 1;
          break;
        case _TimelineCategory.each:
          _eachBins[idx] += 1;
          break;
        case _TimelineCategory.slide:
          _slideBins[idx] += 1;
          break;
        case _TimelineCategory.breakNote:
          _breakBins[idx] += 1;
          break;
      }
    }

    int maxSum = 1;
    for (int i = 0; i < binCount; i++) {
      final sum =
          _tapBins[i] +
          _touchBins[i] +
          _eachBins[i] +
          _slideBins[i] +
          _breakBins[i];
      if (sum > maxSum) maxSum = sum;
    }
    _maxBinSum = maxSum;
    _staticLayerIdentity = Object();
  }

  Future<void> _finishDrag(double total) async {
    if (!_isDragging) return;
    final currentChart = widget.chart;
    final shouldResume = _wasPlayingBeforeDrag;
    final t = _dragTime.clamp(0.0, total).toDouble();
    _isDragging = false;
    _wasPlayingBeforeDrag = false;
    widget.onDragTimeChanged?.call(null);
    await widget.onSeek(t, syncAudio: true);
    if (!mounted || !identical(widget.chart, currentChart) || _isDragging) {
      return;
    }
    if (shouldResume) {
      await widget.onPlay();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureBinsForWidth(constraints.maxWidth);
        final data = _data;
        final total =
            data?.totalDuration ??
            (widget.totalDuration > 0 ? widget.totalDuration : 1.0);

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // 使用 onTapUp 避免按下瞬间与横向拖动手势抢跑触发带音频同步的 seek。
            onTapUp: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              final t = (local.dx / box.size.width * total)
                  .clamp(0.0, total)
                  .toDouble();
              widget.onSeek(t, syncAudio: true);
            },
            onHorizontalDragStart: (details) {
              _isDragging = true;
              _wasPlayingBeforeDrag = widget.isPlaying;
              _dragTime = widget.timeListenable.value;
              widget.onDragTimeChanged?.call(_dragTime);
              if (_wasPlayingBeforeDrag) widget.onPause();
              setState(() {});
            },
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              final t = (local.dx / box.size.width * total)
                  .clamp(0.0, total)
                  .toDouble();
              setState(() {
                _dragTime = t;
              });
              widget.onDragTimeChanged?.call(t);
              widget.onSeek(t, syncAudio: false);
            },
            onHorizontalDragEnd: (_) => unawaited(_finishDrag(total)),
            onHorizontalDragCancel: () => unawaited(_finishDrag(total)),
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: widget.timeListenable,
                builder: (context, notifiedTime, child) {
                  final displayTime = (_isDragging ? _dragTime : notifiedTime)
                      .clamp(0.0, total)
                      .toDouble();
                  return CustomPaint(
                    size: Size.infinite,
                    painter: _SimaiTimelinePainter(
                      staticCache: _staticLayerCache,
                      dataIdentity: _staticLayerIdentity,
                      displayFont: Theme.of(context).textTheme.bodySmall,
                      totalDuration: total,
                      currentTime: displayTime,
                      playbackRate: widget.playbackRate,
                      measureStartTimes: data?.measureStartTimes ?? const [],
                      tempoMarkers: data?.tempoMarkers ?? const [],
                      tapBins: _tapBins,
                      touchBins: _touchBins,
                      eachBins: _eachBins,
                      slideBins: _slideBins,
                      breakBins: _breakBins,
                      maxBinSum: _maxBinSum,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SimaiStatementDisplay extends StatefulWidget {
  final SimaiPlayerController controller;
  final List<SimaiMeasureStatement> statements;
  final double? dragTime;

  const _SimaiStatementDisplay({
    required this.controller,
    required this.statements,
    this.dragTime,
  });

  @override
  State<_SimaiStatementDisplay> createState() => _SimaiStatementDisplayState();
}

class _SimaiStatementDisplayState extends State<_SimaiStatementDisplay> {
  final ScrollController _scrollController = ScrollController();
  final Stopwatch _scrollClock = Stopwatch()..start();

  // 按小节复用的稳定 GlobalKey 映射：仅在切换小节时清空，确保配置块 Widget 不在播放期间反复销毁重建。
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};
  int _statementIndex = -1;
  int _tokenIndex = -1;
  int _lastActiveItemStart = -1;
  int _lastScrolledStatement = -1;
  int _lastOuterScrollAtUs = 0;
  bool _outerScrollQueued = false;

  @override
  void initState() {
    super.initState();
    widget.controller.timeNotifier.addListener(_onTimeChanged);
    _syncIndices(notify: false);
  }

  @override
  void didUpdateWidget(_SimaiStatementDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      oldWidget.controller.timeNotifier.removeListener(_onTimeChanged);
      widget.controller.timeNotifier.addListener(_onTimeChanged);
    }
    if (!identical(widget.statements, oldWidget.statements)) {
      _itemKeys.clear();
      _statementIndex = -1;
      _tokenIndex = -1;
      _lastActiveItemStart = -1;
      _lastScrolledStatement = -1;
    }
    _syncIndices(notify: false);
  }

  @override
  void dispose() {
    widget.controller.timeNotifier.removeListener(_onTimeChanged);
    _scrollClock.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTimeChanged() {
    if (widget.dragTime != null) return;
    _syncIndices(notify: true);
  }

  static int _binarySearchStatement(
    List<SimaiMeasureStatement> statements,
    double time,
  ) {
    int low = 0;
    int high = statements.length - 1;
    int result = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (statements[mid].startTime <= time + 1e-7) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }

  static int _binarySearchToken(List<SimaiStatementToken> tokens, double time) {
    int low = 0;
    int high = tokens.length - 1;
    int result = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (tokens[mid].time <= time + 1e-7) {
        result = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return result;
  }

  void _syncIndices({required bool notify}) {
    final statements = widget.statements;
    if (statements.isEmpty) {
      if (_statementIndex != -1 || _tokenIndex != -1) {
        _itemKeys.clear();
        _statementIndex = -1;
        _tokenIndex = -1;
        _lastActiveItemStart = -1;
        _lastScrolledStatement = -1;
        if (notify && mounted) setState(() {});
      }
      return;
    }

    final currentTime = widget.dragTime ?? widget.controller.timeNotifier.value;
    final nextStatementIndex = _binarySearchStatement(statements, currentTime);
    final tokens = statements[nextStatementIndex].tokens;
    final nextTokenIndex = tokens.isEmpty
        ? 0
        : _binarySearchToken(tokens, currentTime);

    if (nextStatementIndex == _statementIndex &&
        nextTokenIndex == _tokenIndex) {
      return;
    }

    if (nextStatementIndex != _statementIndex) {
      // 仅在真正切换到新小节时重建本小节条目 Key。
      _itemKeys.clear();
      _lastActiveItemStart = -1;
    }
    _statementIndex = nextStatementIndex;
    _tokenIndex = nextTokenIndex;

    if (notify && mounted) {
      setState(() {});
    }
  }

  static int _resolveActiveItemStart(
    SimaiMeasureStatement statement,
    int tokenIndex,
  ) {
    for (final pattern in statement.patterns) {
      if (tokenIndex >= pattern.start && tokenIndex < pattern.end) {
        return pattern.start;
      }
    }
    return tokenIndex;
  }

  void _scheduleOuterScrollIfNeeded(int statementIndex, int itemStart) {
    final statementChanged = statementIndex != _lastScrolledStatement;
    // 同配置块内部推进音符时不再重复滚动外层，避免与内层滚动动画互相打架。
    if (!statementChanged && itemStart == _lastActiveItemStart) return;
    _lastScrolledStatement = statementIndex;
    _lastActiveItemStart = itemStart;
    if (_outerScrollQueued) return;
    _outerScrollQueued = true;

    final int targetStatement = statementIndex;
    final int targetItemStart = itemStart;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _outerScrollQueued = false;
      if (!mounted || targetStatement != _statementIndex) return;
      if (!_scrollController.hasClients) return;
      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;

      final key = _itemKeys[targetItemStart];
      final renderObject = key?.currentContext?.findRenderObject();
      if (renderObject == null || !renderObject.attached) return;
      final viewport = RenderAbstractViewport.maybeOf(renderObject);
      if (viewport == null) return;

      final targetOffset = viewport
          .getOffsetToReveal(renderObject, 0.35)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      final delta = (targetOffset - position.pixels).abs();
      if (!statementChanged && delta <= 20.0) return;

      final nowUs = _scrollClock.elapsedMicroseconds;
      final highFreq = nowUs - _lastOuterScrollAtUs < 140000;
      _lastOuterScrollAtUs = nowUs;
      if (statementChanged || highFreq) {
        _scrollController.jumpTo(targetOffset);
      } else {
        unawaited(
          _scrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statements = widget.statements;
    if (statements.isEmpty ||
        _statementIndex < 0 ||
        _statementIndex >= statements.length) {
      return const SizedBox.shrink();
    }
    final statement = statements[_statementIndex];
    final tokenIndex = statement.tokens.isEmpty
        ? 0
        : _tokenIndex.clamp(0, statement.tokens.length - 1);
    final activeItemStart = _resolveActiveItemStart(statement, tokenIndex);
    _scheduleOuterScrollIfNeeded(_statementIndex, activeItemStart);

    const normalStyle = TextStyle(
      color: Colors.white60,
      fontSize: 12,
      height: 1.0,
      fontWeight: FontWeight.w600,
    );
    const activeStyle = TextStyle(
      color: Colors.black,
      fontSize: 12,
      height: 1.0,
      fontWeight: FontWeight.bold,
    );
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(5),
      ),
      child: ClipRect(
        child: Row(
          children: [
            Text('M${statement.measure + 1}  ', style: normalStyle),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildStatementItems(
                    statement,
                    tokenIndex,
                    normalStyle,
                    activeStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatementItems(
    SimaiMeasureStatement statement,
    int activeIndex,
    TextStyle normalStyle,
    TextStyle activeStyle,
  ) {
    final items = <Widget>[];
    int tokenIndex = 0;
    int patternIndex = 0;
    while (tokenIndex < statement.tokens.length) {
      if (items.isNotEmpty) {
        items.add(const Text(' , ', style: TextStyle(color: Colors.white60)));
      }
      final pattern = patternIndex < statement.patterns.length
          ? statement.patterns[patternIndex]
          : null;
      if (pattern != null && pattern.start == tokenIndex) {
        final containsActive =
            activeIndex >= pattern.start && activeIndex < pattern.end;
        final groupKey = _itemKeys.putIfAbsent(pattern.start, GlobalKey.new);
        items.add(
          _PatternTokenGroup(
            key: groupKey,
            pattern: pattern,
            tokens: statement.tokens.sublist(pattern.start, pattern.end),
            activeLocalIndex: containsActive
                ? activeIndex - pattern.start
                : null,
          ),
        );
        tokenIndex = pattern.end;
        patternIndex++;
        continue;
      }
      final active = tokenIndex == activeIndex;
      final itemKey = _itemKeys.putIfAbsent(tokenIndex, GlobalKey.new);
      items.add(
        Container(
          key: itemKey,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          decoration: active
              ? BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(2),
                )
              : null,
          child: Text(
            statement.tokens[tokenIndex].text,
            style: active ? activeStyle : normalStyle,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      );
      tokenIndex++;
    }
    return items;
  }
}

class _PatternTokenGroup extends StatefulWidget {
  final SimaiTokenPattern pattern;
  final List<SimaiStatementToken> tokens;
  final int? activeLocalIndex;

  const _PatternTokenGroup({
    super.key,
    required this.pattern,
    required this.tokens,
    required this.activeLocalIndex,
  });

  @override
  State<_PatternTokenGroup> createState() => _PatternTokenGroupState();
}

class _PatternTokenGroupState extends State<_PatternTokenGroup> {
  static const TextStyle _labelTextStyle = TextStyle(
    color: Color(0xFF81D4FA),
    fontSize: 9,
    height: 1,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle _activeTokenTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle _normalTokenTextStyle = TextStyle(
    color: Colors.white70,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  final ScrollController _controller = ScrollController();
  final Stopwatch _scrollClock = Stopwatch()..start();
  late List<GlobalKey> _tokenKeys;
  late double _boxWidth;
  TextStyle? _measuredBaseStyle;
  TextScaler _measuredTextScaler = TextScaler.noScaling;
  int? _lastActiveIndex;
  int _lastScrollAtUs = 0;
  bool _scrollQueued = false;

  @override
  void initState() {
    super.initState();
    _tokenKeys = List<GlobalKey>.generate(
      widget.tokens.length,
      (_) => GlobalKey(),
    );
    _boxWidth = _computeBoxWidth();
    _lastActiveIndex = widget.activeLocalIndex;
    if (_lastActiveIndex != null) {
      _scheduleScrollToActive();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final baseStyle = DefaultTextStyle.of(context).style;
    final textScaler = MediaQuery.textScalerOf(context);
    if (baseStyle != _measuredBaseStyle || textScaler != _measuredTextScaler) {
      _measuredBaseStyle = baseStyle;
      _measuredTextScaler = textScaler;
      _boxWidth = _computeBoxWidth(
        baseTextStyle: baseStyle,
        textScaler: textScaler,
      );
    }
  }

  @override
  void didUpdateWidget(_PatternTokenGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tokens.length != oldWidget.tokens.length) {
      _tokenKeys = List<GlobalKey>.generate(
        widget.tokens.length,
        (_) => GlobalKey(),
      );
    }
    if (widget.pattern.label != oldWidget.pattern.label ||
        !_sameTokenTexts(widget.tokens, oldWidget.tokens)) {
      _boxWidth = _computeBoxWidth(
        baseTextStyle: _measuredBaseStyle,
        textScaler: _measuredTextScaler,
      );
    }
    if (widget.activeLocalIndex != _lastActiveIndex) {
      _lastActiveIndex = widget.activeLocalIndex;
      if (_lastActiveIndex != null) {
        _scheduleScrollToActive();
      }
    }
  }

  static bool _sameTokenTexts(
    List<SimaiStatementToken> a,
    List<SimaiStatementToken> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].text != b[i].text) return false;
    }
    return true;
  }

  double _measureTextWidth(
    String text,
    TextStyle style,
    TextScaler textScaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: textScaler,
    );
    try {
      painter.layout();
      return painter.width;
    } finally {
      painter.dispose();
    }
  }

  /// 按标签与 token 内容计算紧凑宽度，避免短配置块右侧拖出大片空白。
  double _computeBoxWidth({
    TextStyle? baseTextStyle,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final resolvedLabelStyle =
        baseTextStyle?.merge(_labelTextStyle) ?? _labelTextStyle;
    final resolvedTokenStyle =
        baseTextStyle?.merge(_activeTokenTextStyle) ?? _activeTokenTextStyle;
    // 标题左右各 5px 内边距 + 外框左右各 1px 边框 + 2px 容错余量。
    final labelWidth =
        _measureTextWidth(
          widget.pattern.label,
          resolvedLabelStyle,
          textScaler,
        ) +
        14.0;
    final joinedTokens = widget.tokens.map((t) => t.text).join(',');
    // 每个 token 左右各 2px 内边距 + 外框左右各 1px 边框 + 4px 视觉余量。
    final tokensWidth =
        _measureTextWidth(joinedTokens, resolvedTokenStyle, textScaler) +
        widget.tokens.length * 4.0 +
        6.0;
    return math.max(labelWidth, tokensWidth).clamp(48.0, 196.0).toDouble();
  }

  @override
  void dispose() {
    _scrollClock.stop();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleScrollToActive() {
    if (_scrollQueued) return;
    _scrollQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollQueued = false;
      final activeIndex = widget.activeLocalIndex;
      if (!mounted ||
          activeIndex == null ||
          activeIndex < 0 ||
          activeIndex >= _tokenKeys.length) {
        return;
      }
      if (!_controller.hasClients) return;
      final position = _controller.position;
      if (!position.hasContentDimensions) return;

      final renderObject = _tokenKeys[activeIndex].currentContext
          ?.findRenderObject();
      if (renderObject == null || !renderObject.attached) return;
      final viewport = RenderAbstractViewport.maybeOf(renderObject);
      if (viewport == null) return;

      final targetOffset = viewport
          .getOffsetToReveal(renderObject, 0.45)
          .offset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((targetOffset - position.pixels).abs() <= 16.0) return;

      // 高频扫键/转圈时直接 jumpTo 避免 120ms 动画不断被下一次音符打断堆积。
      final nowUs = _scrollClock.elapsedMicroseconds;
      final highFreq = nowUs - _lastScrollAtUs < 120000;
      _lastScrollAtUs = nowUs;
      if (highFreq) {
        _controller.jumpTo(targetOffset);
      } else {
        unawaited(
          _controller.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _boxWidth,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0x2219B5FE),
        border: Border.all(color: const Color(0x884FC3F7)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 16,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              color: Color(0x334FC3F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Text(
              widget.pattern.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: _labelTextStyle,
            ),
          ),
          Expanded(
            child: ClipRect(
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: [
                    for (int i = 0; i < widget.tokens.length; i++) ...[
                      if (i > 0)
                        const Text(
                          ',',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      Container(
                        key: _tokenKeys[i],
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: i == widget.activeLocalIndex
                            ? BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(2),
                              )
                            : null,
                        child: Text(
                          widget.tokens[i].text,
                          maxLines: 1,
                          softWrap: false,
                          style: i == widget.activeLocalIndex
                              ? _activeTokenTextStyle
                              : _normalTokenTextStyle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 时间轴静态层与播放头小节号缓存，由 `_SimaiTimelineState` 持有并在 dispose 时释放。
class _TimelineStaticLayerCache {
  ui.Picture? _picture;
  Size? _size;
  Object? _dataIdentity;
  double? _totalDuration;
  double? _playbackRate;
  int? _maxBinSum;
  TextStyle? _displayFont;

  TextPainter? _playheadPainter;
  int? _playheadMeasure;
  TextStyle? _playheadFont;

  void invalidate() {
    _picture?.dispose();
    _picture = null;
    _size = null;
    _dataIdentity = null;
    _totalDuration = null;
    _playbackRate = null;
    _maxBinSum = null;
    _displayFont = null;
  }

  ui.Picture obtainStaticPicture({
    required Size size,
    required Object dataIdentity,
    required double totalDuration,
    required double playbackRate,
    required int maxBinSum,
    required TextStyle? displayFont,
    required void Function(Canvas canvas, Size size) builder,
  }) {
    if (_picture != null &&
        _size == size &&
        identical(_dataIdentity, dataIdentity) &&
        _totalDuration == totalDuration &&
        _playbackRate == playbackRate &&
        _maxBinSum == maxBinSum &&
        _displayFont == displayFont) {
      return _picture!;
    }
    _picture?.dispose();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    builder(canvas, size);
    _picture = recorder.endRecording();
    _size = size;
    _dataIdentity = dataIdentity;
    _totalDuration = totalDuration;
    _playbackRate = playbackRate;
    _maxBinSum = maxBinSum;
    _displayFont = displayFont;
    return _picture!;
  }

  TextPainter obtainPlayheadPainter({
    required int measure,
    required TextStyle? displayFont,
    required TextPainter Function() builder,
  }) {
    if (_playheadPainter != null &&
        _playheadMeasure == measure &&
        _playheadFont == displayFont) {
      return _playheadPainter!;
    }
    _playheadPainter?.dispose();
    final painter = builder();
    _playheadPainter = painter;
    _playheadMeasure = measure;
    _playheadFont = displayFont;
    return painter;
  }

  void dispose() {
    invalidate();
    _playheadPainter?.dispose();
    _playheadPainter = null;
    _playheadMeasure = null;
    _playheadFont = null;
  }
}

class _SimaiTimelinePainter extends CustomPainter {
  final _TimelineStaticLayerCache staticCache;
  final Object dataIdentity;
  final TextStyle? displayFont;
  final double totalDuration;
  final double currentTime;
  final double playbackRate;
  final List<double> measureStartTimes;
  final List<_TempoMarker> tempoMarkers;
  final List<int> tapBins;
  final List<int> touchBins;
  final List<int> eachBins;
  final List<int> slideBins;
  final List<int> breakBins;
  final int maxBinSum;

  static final Paint _playheadLinePaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 1.5;
  static final Paint _playheadBoxPaint = Paint()..color = Colors.white;

  const _SimaiTimelinePainter({
    required this.staticCache,
    required this.dataIdentity,
    required this.displayFont,
    required this.totalDuration,
    required this.currentTime,
    required this.playbackRate,
    required this.measureStartTimes,
    required this.tempoMarkers,
    required this.tapBins,
    required this.touchBins,
    required this.eachBins,
    required this.slideBins,
    required this.breakBins,
    required this.maxBinSum,
  });

  TextStyle _withDisplayFont(TextStyle style) => style.copyWith(
    fontFamily: displayFont?.fontFamily,
    fontFamilyFallback: displayFont?.fontFamilyFallback,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;
    final total = totalDuration > 0 ? totalDuration : 1.0;
    final clampedTime = currentTime.clamp(0.0, total).toDouble();

    // 静态直方图、时间刻度、小节号与变速标签按 (size, dataIdentity, playbackRate) 缓存为 ui.Picture，
    // 每 32ms 重绘仅 drawPicture + 播放头标线 + 1 个播放头标签。
    final staticPicture = staticCache.obtainStaticPicture(
      size: size,
      dataIdentity: dataIdentity,
      totalDuration: total,
      playbackRate: playbackRate,
      maxBinSum: maxBinSum,
      displayFont: displayFont,
      builder: (staticCanvas, staticSize) =>
          _paintStaticLayer(staticCanvas, staticSize, total),
    );
    canvas.drawPicture(staticPicture);
    _paintPlayhead(canvas, size, total, clampedTime);
  }

  void _paintStaticLayer(Canvas canvas, Size size, double total) {
    final w = size.width;
    final h = size.height;
    const topLabelHeight = 18.0;
    const bottomLabelHeight = 24.0;
    final barRect = Rect.fromLTWH(
      0,
      topLabelHeight,
      w,
      h - topLabelHeight - bottomLabelHeight,
    );

    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(8),
      ),
      bgPaint,
    );

    _paintTimeScale(canvas, size, total, topLabelHeight);
    _paintBars(canvas, barRect, total);
    _paintMeasureTicks(canvas, size, total, barRect.bottom, bottomLabelHeight);
    _paintTempoMarkers(canvas, barRect, total);
  }

  void _paintTimeScale(
    Canvas canvas,
    Size size,
    double total,
    double topLabelHeight,
  ) {
    final w = size.width;
    final tickPaint = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1.0;

    final resolvedStyle = _withDisplayFont(
      const TextStyle(color: Colors.white, fontSize: 10, height: 1.0),
    );

    const step = 30.0;
    for (double t = 0.0; t <= total + 1e-6; t += step) {
      final x = (t / total * w).clamp(0.0, w);
      canvas.drawLine(
        Offset(x, topLabelHeight - 4),
        Offset(x, topLabelHeight),
        tickPaint,
      );

      final tp = TextPainter(
        text: TextSpan(text: _formatTime(t), style: resolvedStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      try {
        final dx = (x - tp.width / 2).clamp(0.0, w - tp.width);
        tp.paint(canvas, Offset(dx, 0));
      } finally {
        tp.dispose();
      }
    }
  }

  void _paintBars(Canvas canvas, Rect barRect, double total) {
    final binCount = tapBins.length;
    if (binCount == 0) return;
    final barWidth = barRect.width / binCount;
    final maxSum = maxBinSum <= 0 ? 1 : maxBinSum;

    final tapPaint = Paint()..color = SimaiColors.tapNormal;
    final touchPaint = Paint()..color = SimaiColors.touchNormal;
    final eachPaint = Paint()..color = SimaiColors.tapEach;
    final slidePaint = Paint()..color = SimaiColors.slideNormal;
    final breakPaint = Paint()..color = SimaiColors.tapBreak;

    final gridPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    const gridLines = 3;
    for (int i = 1; i <= gridLines; i++) {
      final y = barRect.bottom - barRect.height * (i / (gridLines + 1));
      canvas.drawLine(
        Offset(barRect.left, y),
        Offset(barRect.right, y),
        gridPaint,
      );
    }

    for (int i = 0; i < binCount; i++) {
      final tap = tapBins[i];
      final touch = touchBins[i];
      final each = eachBins[i];
      final slide = slideBins[i];
      final brk = breakBins[i];
      final sum = tap + touch + each + slide + brk;
      if (sum <= 0) continue;

      final totalHeight = barRect.height * (sum / maxSum).clamp(0.0, 1.0);
      double y = barRect.bottom;

      void drawSegment(int count, Paint paint) {
        if (count <= 0) return;
        final segH = totalHeight * (count / sum);
        final rect = Rect.fromLTWH(
          barRect.left + i * barWidth,
          y - segH,
          barWidth,
          segH,
        );
        canvas.drawRect(rect, paint);
        y -= segH;
      }

      drawSegment(tap, tapPaint);
      drawSegment(touch, touchPaint);
      drawSegment(each, eachPaint);
      drawSegment(slide, slidePaint);
      drawSegment(brk, breakPaint);
    }
  }

  void _paintMeasureTicks(
    Canvas canvas,
    Size size,
    double total,
    double barBottomY,
    double bottomLabelHeight,
  ) {
    final w = size.width;
    final h = size.height;
    final minorTickPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.0;
    final majorTickPaint = Paint()
      ..color = Colors.lightBlue
      ..strokeWidth = 1.25;
    final majorLabelStyle = _withDisplayFont(
      const TextStyle(
        color: Colors.lightBlue,
        fontSize: 10,
        height: 1.0,
        fontWeight: FontWeight.w600,
      ),
    );

    final measureCount = measureStartTimes.length;

    const barToTickGap = 4.0;
    const tickToLabelGap = 3.0;
    const minorTickH = 3.0;
    const majorTickH = 6.0;

    double? lastMinorX;
    double? lastLabelRight;
    if (measureCount <= 1) return;
    for (int i = 0; i < measureCount; i++) {
      // 小节刻度按真实时间落点排列，高 BPM 段更密、低 BPM 段更宽。
      final x = (measureStartTimes[i] / total * w).clamp(0.0, w);
      final isMajor = i % 5 == 0;
      if (!isMajor && lastMinorX != null && x - lastMinorX < 3.0) continue;
      lastMinorX = x;
      final tickH = isMajor ? majorTickH : minorTickH;
      final startY = (barBottomY + barToTickGap).clamp(0.0, h);
      final endY = (startY + tickH).clamp(0.0, h);
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, endY),
        isMajor ? majorTickPaint : minorTickPaint,
      );

      if (isMajor) {
        final label = '$i';
        final tp = TextPainter(
          text: TextSpan(text: label, style: majorLabelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        try {
          final dx = (x - tp.width / 2).clamp(0.0, w - tp.width);
          if (lastLabelRight != null && dx < lastLabelRight + 4.0) continue;
          lastLabelRight = dx + tp.width;
          final labelY = (endY + tickToLabelGap).clamp(
            0.0,
            (h - tp.height).clamp(0.0, h),
          );
          tp.paint(canvas, Offset(dx, labelY));
        } finally {
          tp.dispose();
        }
      }
    }
  }

  void _paintTempoMarkers(Canvas canvas, Rect barRect, double total) {
    if (tempoMarkers.isEmpty) return;
    const increasedColor = Color(0xFFFF8A65);
    const decreasedColor = Color(0xFF64B5F6);
    final baseLabelStyle = _withDisplayFont(
      const TextStyle(fontSize: 9, height: 1.0, fontWeight: FontWeight.bold),
    );
    final markerLinePaint = Paint()..strokeWidth = 1.5;

    double lastLabelRight = -double.infinity;
    for (final marker in tempoMarkers) {
      if (marker.time < 0 || marker.time > total) continue;
      final x = (marker.time / total * barRect.width).clamp(0.0, barRect.width);
      final color = marker.increased ? increasedColor : decreasedColor;
      markerLinePaint.color = color.withValues(alpha: 0.8);
      canvas.drawLine(
        Offset(x, barRect.top),
        Offset(x, barRect.bottom),
        markerLinePaint,
      );

      final effectiveTempo = marker.tempo * playbackRate;
      final painter = TextPainter(
        text: TextSpan(
          text: '${marker.increased ? '▲' : '▼'}${_formatBpm(effectiveTempo)}',
          style: baseLabelStyle.copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      try {
        final dx = (x + 2).clamp(0.0, barRect.right - painter.width);
        if (dx >= lastLabelRight + 3.0) {
          painter.paint(canvas, Offset(dx, barRect.top + 2));
          lastLabelRight = dx + painter.width;
        }
      } finally {
        painter.dispose();
      }
    }
  }

  static String _formatBpm(double bpm) {
    final rounded = (bpm * 10).roundToDouble() / 10.0;
    return (rounded - rounded.roundToDouble()).abs() < 1e-6
        ? rounded.round().toString()
        : rounded.toStringAsFixed(1);
  }

  void _paintPlayhead(Canvas canvas, Size size, double total, double time) {
    final w = size.width;
    final h = size.height;
    final x = (time / total * w).clamp(0.0, w);
    canvas.drawLine(Offset(x, 0), Offset(x, h), _playheadLinePaint);

    final measure = _measureIndexForTime(time);
    final tp = staticCache.obtainPlayheadPainter(
      measure: measure,
      displayFont: displayFont,
      builder: () => TextPainter(
        text: TextSpan(
          text: '$measure',
          style: _withDisplayFont(
            const TextStyle(color: Colors.black, fontSize: 10, height: 1.0),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
    );

    const padding = 4.0;
    final boxW = tp.width + padding * 2;
    final boxH = tp.height + padding * 2;
    final dx = (x - boxW / 2).clamp(0.0, w - boxW);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, 2, boxW, boxH),
      const Radius.circular(6),
    );
    canvas.drawRRect(rect, _playheadBoxPaint);
    tp.paint(canvas, Offset(dx + padding, 2 + padding));
  }

  int _measureIndexForTime(double time) {
    if (measureStartTimes.isEmpty) return 0;
    int lo = 0;
    int hi = measureStartTimes.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final v = measureStartTimes[mid];
      if (v <= time) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return hi < 0 ? 0 : hi;
  }

  static String _formatTime(double seconds) {
    final s = seconds.isFinite ? seconds : 0.0;
    final totalSeconds = s.round().clamp(0, 999999);
    final m = totalSeconds ~/ 60;
    final r = totalSeconds % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(covariant _SimaiTimelinePainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        !identical(oldDelegate.dataIdentity, dataIdentity) ||
        oldDelegate.displayFont != displayFont ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.playbackRate != playbackRate ||
        oldDelegate.maxBinSum != maxBinSum;
  }
}
