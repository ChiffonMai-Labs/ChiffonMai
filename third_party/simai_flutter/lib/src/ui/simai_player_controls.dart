import 'package:flutter/material.dart';
import '../../simai_flutter.dart';
import '../internal/syntactic_analysis/serializer.dart';
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
  final List<_MeasureStatement> statements;

  const _TimelineData({
    required this.totalDuration,
    required this.events,
    required this.measureStartTimes,
    required this.tempoMarkers,
    required this.statements,
  });
}

class _StatementToken {
  final double time;
  final String text;
  final String? patternKey;
  final int? ringIndex;

  const _StatementToken({
    required this.time,
    required this.text,
    required this.patternKey,
    required this.ringIndex,
  });
}

enum _TokenPatternType {
  vertical,
  alternating,
  pairedBeat,
  sweep,
  reversingSweep,
}

class _TokenPattern {
  final int start;
  final int end;
  final String subdivisionLabel;
  final _TokenPatternType type;

  const _TokenPattern({
    required this.start,
    required this.end,
    required this.subdivisionLabel,
    required this.type,
  });

  String get label {
    final typeLabel = switch (type) {
      _TokenPatternType.vertical => '纵连',
      _TokenPatternType.alternating => '交互',
      _TokenPatternType.pairedBeat => '对拍',
      _TokenPatternType.sweep => '扫键',
      _TokenPatternType.reversingSweep => '换向扫键',
    };
    return '$subdivisionLabel$typeLabel';
  }
}

class _MeasureStatement {
  final int measure;
  final double startTime;
  final List<_StatementToken> tokens;
  final List<_TokenPattern> patterns;

  const _MeasureStatement({
    required this.measure,
    required this.startTime,
    required this.tokens,
    required this.patterns,
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

class _SimaiTimeline extends StatefulWidget {
  final SimaiPlayerController controller;
  final double height;

  const _SimaiTimeline({required this.controller, required this.height});

  @override
  State<_SimaiTimeline> createState() => _SimaiTimelineState();
}

class _SimaiTimelineState extends State<_SimaiTimeline> {
  bool _isDragging = false;
  bool _wasPlayingBeforeDrag = false;
  double _dragTime = 0.0;

  _TimelineData? _data;
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
    _dragTime = widget.controller.chartTime;
  }

  @override
  void didUpdateWidget(_SimaiTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.controller, oldWidget.controller)) {
      _isDragging = false;
      _wasPlayingBeforeDrag = false;
      _lastWidth = 0.0;
      _lastBinCount = 0;
      _rebuildData();
      _dragTime = widget.controller.chartTime;
    }
  }

  void _rebuildData() {
    final controller = widget.controller;
    final total = controller.chartInfo.totalDuration > 0
        ? controller.chartInfo.totalDuration
        : 0.0;
    final events = <_NoteEvent>[];
    for (final collection in controller.chart.noteCollections) {
      final collectionTime = collection.time;
      for (final note in collection) {
        final category = _categorize(collection, note);
        events.add(_NoteEvent(time: collectionTime, category: category));
      }
    }
    final measureStartTimes = _computeMeasureStartTimes(
      controller.chart,
      total > 0 ? total : _inferTotalFromEvents(events),
    );
    _data = _TimelineData(
      totalDuration: total > 0 ? total : _inferTotalFromEvents(events),
      events: events,
      measureStartTimes: measureStartTimes,
      tempoMarkers: _computeTempoMarkers(controller.chart),
      statements: _computeStatements(controller.chart, measureStartTimes),
    );
  }

  static List<_MeasureStatement> _computeStatements(
    MaiChart chart,
    List<double> measureStarts,
  ) {
    if (measureStarts.isEmpty) return const [];
    final grouped = <int, List<_StatementToken>>{};
    for (
      int collectionIndex = 0;
      collectionIndex < chart.noteCollections.length;
      collectionIndex++
    ) {
      final collection = chart.noteCollections[collectionIndex];
      if (collection.isEmpty) continue;
      final measure = _indexAtOrBefore(measureStarts, collection.time);
      final sourceStatements = chart.sourceNoteStatements;
      String text;
      if (sourceStatements != null &&
          collectionIndex < sourceStatements.length) {
        // The timeline is a single-line view; retain source syntax while
        // folding formatting whitespace used by multiline maidata files.
        text = sourceStatements[collectionIndex]
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      } else {
        final writer = StringBuffer();
        Serializer.serializeNoteCollection(collection, writer);
        text = writer.toString();
      }
      grouped
          .putIfAbsent(measure, () => [])
          .add(
            _StatementToken(
              time: collection.time,
              text: text,
              patternKey: collection.length == 1
                  ? collection.single.location.toString()
                  : null,
              ringIndex:
                  collection.length == 1 &&
                      collection.single.location.group == NoteGroup.tap
                  ? collection.single.location.index
                  : null,
            ),
          );
    }
    return grouped.entries.map((entry) {
      entry.value.sort((a, b) => a.time.compareTo(b.time));
      return _MeasureStatement(
        measure: entry.key,
        startTime: measureStarts[entry.key],
        tokens: List.unmodifiable(entry.value),
        patterns: List.unmodifiable(_detectPatterns(chart, entry.value)),
      );
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  static List<_TokenPattern> _detectPatterns(
    MaiChart chart,
    List<_StatementToken> tokens,
  ) {
    final patterns = <_TokenPattern>[];
    int i = 0;
    while (i <= tokens.length - 4) {
      final first = tokens[i].patternKey;
      if (first == null) {
        i++;
        continue;
      }
      var end = i + 1;
      while (end < tokens.length && tokens[end].patternKey == first) {
        end++;
      }
      if (end - i >= 4 && _hasEvenIntervals(tokens, i, end)) {
        patterns.add(
          _TokenPattern(
            start: i,
            end: end,
            subdivisionLabel: _patternSubdivisionLabel(chart, tokens, i, end),
            type: _TokenPatternType.vertical,
          ),
        );
        i = end;
        continue;
      }

      final pairedBeatEnd = _pairedBeatEnd(tokens, i);
      if (pairedBeatEnd >= i + 4) {
        final pairStartTimes = <double>[
          for (int pair = i; pair < pairedBeatEnd; pair += 2) tokens[pair].time,
        ];
        patterns.add(
          _TokenPattern(
            start: i,
            end: pairedBeatEnd,
            subdivisionLabel: _subdivisionLabelForTimes(chart, pairStartTimes),
            type: _TokenPatternType.pairedBeat,
          ),
        );
        i = pairedBeatEnd;
        continue;
      }

      final second = tokens[i + 1].patternKey;
      if (second != null && second != first) {
        end = i + 2;
        while (end < tokens.length &&
            tokens[end].patternKey == ((end - i).isEven ? first : second)) {
          end++;
        }
        if (end - i >= 4 && _hasEvenIntervals(tokens, i, end)) {
          patterns.add(
            _TokenPattern(
              start: i,
              end: end,
              subdivisionLabel: _patternSubdivisionLabel(chart, tokens, i, end),
              type: _TokenPatternType.alternating,
            ),
          );
          i = end;
          continue;
        }
      }

      final sweepEnd = _sweepEnd(tokens, i);
      if (sweepEnd > i + 1) {
        final directions = <int>[];
        for (int j = i + 1; j < sweepEnd; j++) {
          directions.add(_ringDirection(tokens[j - 1], tokens[j]));
        }
        final reversing = directions
            .skip(1)
            .any((direction) => direction != directions.first);
        patterns.add(
          _TokenPattern(
            start: i,
            end: sweepEnd,
            subdivisionLabel: _patternSubdivisionLabel(
              chart,
              tokens,
              i,
              sweepEnd,
            ),
            type: reversing
                ? _TokenPatternType.reversingSweep
                : _TokenPatternType.sweep,
          ),
        );
        i = sweepEnd;
        continue;
      }
      i++;
    }
    return patterns;
  }

  static bool _hasEvenIntervals(
    List<_StatementToken> tokens,
    int start,
    int end,
  ) {
    final interval = tokens[start + 1].time - tokens[start].time;
    if (interval <= 1e-6) return false;
    for (int i = start + 2; i < end; i++) {
      if (((tokens[i].time - tokens[i - 1].time) - interval).abs() > 1e-4) {
        return false;
      }
    }
    return true;
  }

  static int _ringDirection(_StatementToken from, _StatementToken to) {
    if (from.ringIndex == null || to.ringIndex == null) return 0;
    final difference = (to.ringIndex! - from.ringIndex!) % 8;
    if (difference == 1) return 1;
    if (difference == 7) return -1;
    return 0;
  }

  static int _pairedBeatEnd(List<_StatementToken> tokens, int start) {
    if (start + 3 >= tokens.length) return start;
    int end = start;
    while (end + 1 < tokens.length) {
      final first = tokens[end];
      final second = tokens[end + 1];
      if (_ringDirection(first, second) == 0 ||
          !_isClosePairGap(first, second)) {
        break;
      }
      if (end > start) {
        final previousPairEnd = tokens[end - 1];
        final interPairGap = first.time - previousPairEnd.time;
        final intraPairGap = second.time - first.time;
        final hasTemporalBoundary =
            interPairGap > intraPairGap * 1.5 + 1e-4 && interPairGap > 0.01;
        final hasSpatialBoundary = _ringDirection(previousPairEnd, first) == 0;
        if (!hasTemporalBoundary && !hasSpatialBoundary) {
          break;
        }
      }
      end += 2;
    }
    return end >= start + 4 ? end : start;
  }

  static bool _isClosePairGap(_StatementToken first, _StatementToken second) {
    final gap = second.time - first.time;
    return gap > 1e-6 && gap <= 0.050001;
  }

  static int _sweepEnd(List<_StatementToken> tokens, int start) {
    if (start + 1 >= tokens.length) return start;
    int direction = 0;
    bool reversed = false;
    int end = start + 1;
    while (end < tokens.length) {
      final stepDirection = _ringDirection(tokens[end - 1], tokens[end]);
      if (stepDirection == 0 ||
          !_isSmallSweepGap(tokens[end - 1], tokens[end])) {
        break;
      }
      if (direction == 0) {
        direction = stepDirection;
      } else if (stepDirection != direction) {
        if (reversed) break;
        reversed = true;
        direction = stepDirection;
      }
      end++;
    }
    final noteCount = end - start;
    if (noteCount < 2) return start;
    final firstGap = tokens[start + 1].time - tokens[start].time;
    final startGapLimit = switch (noteCount) {
      2 => 0.075,
      3 => 0.100,
      4 => 0.125,
      _ => 0.150,
    };
    return firstGap <= startGapLimit + 1e-6 ? end : start;
  }

  static bool _isSmallSweepGap(_StatementToken from, _StatementToken to) {
    final gap = to.time - from.time;
    return gap > 1e-6 && gap <= 0.150001;
  }

  static String _patternSubdivisionLabel(
    MaiChart chart,
    List<_StatementToken> tokens,
    int start,
    int end,
  ) {
    final subdivisions = <int>[];
    for (int i = start + 1; i < end; i++) {
      final interval = tokens[i].time - tokens[i - 1].time;
      final bpm = ChartTimingMapper.timingAtTime(
        chart,
        tokens[i - 1].time,
      ).tempo;
      if (interval <= 0 || bpm <= 0) continue;
      subdivisions.add((240.0 / (bpm * interval)).round().clamp(1, 1024));
    }
    if (subdivisions.isEmpty) return '4分';
    final unique = <int>[];
    for (final value in subdivisions) {
      if (unique.isEmpty || unique.last != value) unique.add(value);
    }
    if (unique.length == 1) return '${unique.single}分';
    return '${unique.join('→')}分变速';
  }

  static String _subdivisionLabelForTimes(MaiChart chart, List<double> times) {
    if (times.length < 2) return '4分';
    final subdivisions = <int>[];
    for (int i = 1; i < times.length; i++) {
      final interval = times[i] - times[i - 1];
      final bpm = ChartTimingMapper.timingAtTime(chart, times[i - 1]).tempo;
      if (interval <= 0 || bpm <= 0) continue;
      subdivisions.add((240.0 / (bpm * interval)).round().clamp(1, 1024));
    }
    if (subdivisions.isEmpty) return '4分';
    final unique = <int>[];
    for (final value in subdivisions) {
      if (unique.isEmpty || unique.last != value) unique.add(value);
    }
    if (unique.length == 1) return '${unique.single}分';
    return '${unique.join('→')}分变速';
  }

  static int _indexAtOrBefore(List<double> values, double time) {
    int lo = 0;
    int hi = values.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (values[mid] <= time + 1e-7) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return hi.clamp(0, values.length - 1);
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

  static List<double> _computeMeasureStartTimes(MaiChart chart, double total) {
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _ensureBinsForWidth(constraints.maxWidth);
        final data = _data;
        final controller = widget.controller;
        final total =
            data?.totalDuration ??
            (controller.chartInfo.totalDuration > 0
                ? controller.chartInfo.totalDuration
                : 1.0);

        return SizedBox(
          height: widget.height,
          width: double.infinity,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.globalPosition);
              final t = (local.dx / box.size.width * total)
                  .clamp(0.0, total)
                  .toDouble();
              controller.seek(t, syncAudio: true);
            },
            onHorizontalDragStart: (details) {
              _isDragging = true;
              _wasPlayingBeforeDrag = controller.isPlaying;
              _dragTime = controller.chartTime;
              if (_wasPlayingBeforeDrag) controller.pause();
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
              controller.seek(t, syncAudio: false);
            },
            onHorizontalDragEnd: (_) async {
              final t = _dragTime.clamp(0.0, total).toDouble();
              _isDragging = false;
              await controller.seek(t, syncAudio: true);
              if (_wasPlayingBeforeDrag) controller.play();
              if (mounted) setState(() {});
            },
            child: ValueListenableBuilder<double>(
              valueListenable: controller.timeNotifier,
              builder: (context, notifiedTime, child) {
                final displayTime = (_isDragging ? _dragTime : notifiedTime)
                    .clamp(0.0, total)
                    .toDouble();
                return Column(
                  children: [
                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: _SimaiStatementDisplay(
                        statements: data?.statements ?? const [],
                        currentTime: displayTime,
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _SimaiTimelinePainter(
                          displayFont: Theme.of(context).textTheme.bodySmall,
                          totalDuration: total,
                          currentTime: displayTime,
                          measureStartTimes:
                              data?.measureStartTimes ?? const [],
                          tempoMarkers: data?.tempoMarkers ?? const [],
                          tapBins: _tapBins,
                          touchBins: _touchBins,
                          eachBins: _eachBins,
                          slideBins: _slideBins,
                          breakBins: _breakBins,
                          maxBinSum: _maxBinSum,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SimaiStatementDisplay extends StatefulWidget {
  final List<_MeasureStatement> statements;
  final double currentTime;

  const _SimaiStatementDisplay({
    required this.statements,
    required this.currentTime,
  });

  @override
  State<_SimaiStatementDisplay> createState() => _SimaiStatementDisplayState();
}

class _SimaiStatementDisplayState extends State<_SimaiStatementDisplay> {
  final ScrollController _scrollController = ScrollController();
  GlobalKey _activeTokenKey = GlobalKey();
  int _lastStatementIndex = -1;
  int _lastTokenIndex = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statements = widget.statements;
    if (statements.isEmpty) return const SizedBox.shrink();
    var statementIndex = 0;
    for (int i = 1; i < statements.length; i++) {
      if (statements[i].startTime <= widget.currentTime + 1e-7) {
        statementIndex = i;
      } else {
        break;
      }
    }
    final statement = statements[statementIndex];
    var tokenIndex = 0;
    for (int i = 1; i < statement.tokens.length; i++) {
      if (statement.tokens[i].time <= widget.currentTime + 1e-7) {
        tokenIndex = i;
      } else {
        break;
      }
    }

    if (statementIndex != _lastStatementIndex ||
        tokenIndex != _lastTokenIndex) {
      _lastStatementIndex = statementIndex;
      _lastTokenIndex = tokenIndex;
      _activeTokenKey = GlobalKey();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeContext = _activeTokenKey.currentContext;
        if (!mounted || activeContext == null) return;
        Scrollable.ensureVisible(
          activeContext,
          alignment: 0.35,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    }

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
    _MeasureStatement statement,
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
        items.add(
          _PatternTokenGroup(
            key: containsActive ? _activeTokenKey : null,
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
      items.add(
        Container(
          key: active ? _activeTokenKey : null,
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
  final _TokenPattern pattern;
  final List<_StatementToken> tokens;
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
  final ScrollController _controller = ScrollController();
  GlobalKey _activeKey = GlobalKey();
  int? _lastActiveIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_lastActiveIndex != widget.activeLocalIndex) {
      _lastActiveIndex = widget.activeLocalIndex;
      _activeKey = GlobalKey();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final activeContext = _activeKey.currentContext;
        if (!mounted || activeContext == null) return;
        Scrollable.ensureVisible(
          activeContext,
          alignment: 0.45,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      });
    }
    return Container(
      width: 176,
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
              style: const TextStyle(
                color: Color(0xFF81D4FA),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.bold,
              ),
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
                        key: i == widget.activeLocalIndex ? _activeKey : null,
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
                          style: TextStyle(
                            color: i == widget.activeLocalIndex
                                ? Colors.black
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: i == widget.activeLocalIndex
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
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

class _SimaiTimelinePainter extends CustomPainter {
  final TextStyle? displayFont;
  final double totalDuration;
  final double currentTime;
  final List<double> measureStartTimes;
  final List<_TempoMarker> tempoMarkers;
  final List<int> tapBins;
  final List<int> touchBins;
  final List<int> eachBins;
  final List<int> slideBins;
  final List<int> breakBins;
  final int maxBinSum;

  const _SimaiTimelinePainter({
    required this.displayFont,
    required this.totalDuration,
    required this.currentTime,
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
    _paintPlayhead(canvas, size, total, clampedTime);
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

    final labelStyle = const TextStyle(
      color: Colors.white,
      fontSize: 10,
      height: 1.0,
    );

    final step = 30.0;
    for (double t = 0.0; t <= total + 1e-6; t += step) {
      final x = (t / total * w).clamp(0.0, w);
      canvas.drawLine(
        Offset(x, topLabelHeight - 4),
        Offset(x, topLabelHeight),
        tickPaint,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: _formatTime(t),
          style: _withDisplayFont(labelStyle),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x - tp.width / 2).clamp(0.0, w - tp.width);
      tp.paint(canvas, Offset(dx, 0));
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
    final gridLines = 3;
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
    final majorLabelStyle = const TextStyle(
      color: Colors.lightBlue,
      fontSize: 10,
      height: 1.0,
      fontWeight: FontWeight.w600,
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
      // Measures occupy their real location in time. This makes high-BPM
      // sections denser and low-BPM sections wider on the fixed time axis.
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
          text: TextSpan(text: label, style: _withDisplayFont(majorLabelStyle)),
          textDirection: TextDirection.ltr,
        )..layout();
        final dx = (x - tp.width / 2).clamp(0.0, w - tp.width);
        if (lastLabelRight != null && dx < lastLabelRight + 4.0) continue;
        lastLabelRight = dx + tp.width;
        final labelY = (endY + tickToLabelGap).clamp(
          0.0,
          (h - tp.height).clamp(0.0, h),
        );
        tp.paint(canvas, Offset(dx, labelY));
      }
    }
  }

  void _paintTempoMarkers(Canvas canvas, Rect barRect, double total) {
    if (tempoMarkers.isEmpty) return;
    const increasedColor = Color(0xFFFF8A65);
    const decreasedColor = Color(0xFF64B5F6);
    const labelStyle = TextStyle(
      fontSize: 9,
      height: 1.0,
      fontWeight: FontWeight.bold,
    );

    double lastLabelRight = -double.infinity;
    for (final marker in tempoMarkers) {
      if (marker.time < 0 || marker.time > total) continue;
      final x = (marker.time / total * barRect.width).clamp(0.0, barRect.width);
      final color = marker.increased ? increasedColor : decreasedColor;
      canvas.drawLine(
        Offset(x, barRect.top),
        Offset(x, barRect.bottom),
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..strokeWidth = 1.5,
      );

      final painter = TextPainter(
        text: TextSpan(
          text: '${marker.increased ? '▲' : '▼'}${_formatBpm(marker.tempo)}',
          style: _withDisplayFont(labelStyle).copyWith(color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x + 2).clamp(0.0, barRect.right - painter.width);
      if (dx >= lastLabelRight + 3.0) {
        painter.paint(canvas, Offset(dx, barRect.top + 2));
        lastLabelRight = dx + painter.width;
      }
    }
  }

  static String _formatBpm(double bpm) => bpm == bpm.roundToDouble()
      ? bpm.round().toString()
      : bpm.toStringAsFixed(1);

  void _paintPlayhead(Canvas canvas, Size size, double total, double time) {
    final w = size.width;
    final h = size.height;
    final x = (time / total * w).clamp(0.0, w);
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);

    final measure = _measureIndexForTime(time);
    final label = '$measure';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: _withDisplayFont(
          const TextStyle(color: Colors.black, fontSize: 10, height: 1.0),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const padding = 4.0;
    final boxW = tp.width + padding * 2;
    final boxH = tp.height + padding * 2;
    final dx = (x - boxW / 2).clamp(0.0, w - boxW);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, 2, boxW, boxH),
      const Radius.circular(6),
    );
    final boxPaint = Paint()..color = Colors.white;
    canvas.drawRRect(rect, boxPaint);
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
        oldDelegate.displayFont != displayFont ||
        oldDelegate.totalDuration != totalDuration ||
        oldDelegate.maxBinSum != maxBinSum ||
        oldDelegate.tapBins != tapBins ||
        oldDelegate.touchBins != touchBins ||
        oldDelegate.eachBins != eachBins ||
        oldDelegate.slideBins != slideBins ||
        oldDelegate.breakBins != breakBins ||
        oldDelegate.measureStartTimes != measureStartTimes ||
        oldDelegate.tempoMarkers != tempoMarkers;
  }
}
