import 'dart:math';

import '../structures/location.dart';
import '../structures/mai_chart.dart';
import '../structures/note.dart';
import '../structures/note_group.dart';
import '../structures/note_styles.dart';
import '../structures/note_type.dart';
import 'gameplay_models.dart';

typedef _NoteKey = ({int collectionIndex, int noteIndex});
typedef _SlideKey = ({int collectionIndex, int noteIndex, int slidePathIndex});

class SimaiGameplaySession {
  SimaiGameplaySession({
    required this.chart,
    required SimaiGameplaySettings settings,
  }) : settings = settings.normalized() {
    _buildIndex();
  }

  final MaiChart chart;
  final SimaiGameplaySettings settings;

  final List<List<_ManualHead>> _tapHeadsByLane = List.generate(
    8,
    (_) => <_ManualHead>[],
  );
  final List<List<_ManualHead>> _touchHeadsBySensor = List.generate(
    SimaiGameplayInputMapper.sensorCount,
    (_) => <_ManualHead>[],
  );
  final List<_ManualHead> _manualHeadsByDeadline = <_ManualHead>[];
  final List<_HoldRuntime> _holdsByResolution = <_HoldRuntime>[];
  final List<_SlideRuntime> _slides = <_SlideRuntime>[];
  final List<_SlideRuntime> _slidesByStart = <_SlideRuntime>[];
  final List<_SlideRuntime> _slidesByTimeout = <_SlideRuntime>[];
  final List<List<_SlideRuntime>> _slidesBySensor = List.generate(
    SimaiGameplayInputMapper.sensorCount,
    (_) => <_SlideRuntime>[],
  );
  final List<_ScoreSlot> _scoreSlots = <_ScoreSlot>[];
  final Map<_NoteKey, _ManualHead> _manualHeads = <_NoteKey, _ManualHead>{};
  final Map<_SlideKey, _SlideRuntime> _slideRuntimes =
      <_SlideKey, _SlideRuntime>{};
  final Map<_NoteKey, SimaiJudgementRecord> _headFeedback =
      <_NoteKey, SimaiJudgementRecord>{};
  final Map<_SlideKey, SimaiJudgementRecord> _slideFeedback =
      <_SlideKey, SimaiJudgementRecord>{};
  final List<SimaiJudgementRecord> _feedback = <SimaiJudgementRecord>[];

  final List<Set<int>> _outerPointers = List.generate(8, (_) => <int>{});
  final List<Set<int>> _sensorPointers = List.generate(
    SimaiGameplayInputMapper.sensorCount,
    (_) => <int>{},
  );
  final List<List<_PressInterval>> _laneIntervals = List.generate(
    8,
    (_) => <_PressInterval>[],
  );
  final List<double?> _laneOpenStarts = List<double?>.filled(8, null);
  final List<List<_PressInterval>> _sensorIntervals = List.generate(
    SimaiGameplayInputMapper.sensorCount,
    (_) => <_PressInterval>[],
  );
  final List<double?> _sensorOpenStarts = List<double?>.filled(
    SimaiGameplayInputMapper.sensorCount,
    null,
  );

  int _missCursor = 0;
  int _holdCursor = 0;
  int _slideStartCursor = 0;
  int _slideTimeoutCursor = 0;
  int _scoreCommitCursor = 0;
  int _sourceOrder = 0;
  double _currentTime = double.negativeInfinity;
  double _contentEndTime = 0.0;
  bool _slideDataInstalled = false;
  SimaiGameplayResult? _cachedResult;

  final List<SimaiJudgementRecord> _committed = <SimaiJudgementRecord>[];
  final Map<SimaiJudgeGrade, int> _gradeCounts = <SimaiJudgeGrade, int>{};
  final Map<SimaiGameplayScoringType, int> _typeCounts =
      <SimaiGameplayScoringType, int>{};
  int _currentCombo = 0;
  int _maxCombo = 0;
  int _fastCount = 0;
  int _lateCount = 0;
  int _autoAssistCount = 0;
  int _dxScore = 0;
  int _lostDxScore = 0;
  double _earnedWeightedPoints = 0.0;
  double _lostWeightedPoints = 0.0;
  double _breakExtras = 0.0;
  double _lostBreakExtras = 0.0;
  double _manualOffsetTotal = 0.0;
  int _manualOffsetCount = 0;
  int _totalWeightedPoints = 0;
  int _breakCount = 0;
  int _manualCount = 0;
  int _excludedCount = 0;

  int revision = 0;
  int debugCandidateChecks = 0;
  int debugSlideChecks = 0;

  static const double resultFeedbackTailSeconds = 0.8;
  static const double inputDeliveryGraceSeconds = 0.05;

  double get currentTime => _currentTime.isFinite ? _currentTime : 0.0;
  double get judgementOffsetSeconds => settings.judgementOffsetMs / 1000.0;
  double get contentEndTime => _contentEndTime;
  int get currentCombo => _currentCombo;
  int get maxCombo => _maxCombo;
  int get committedCount => _committed.length;
  int get totalScoringNotes => _scoreSlots.length;
  bool get hasPendingScores => _scoreCommitCursor < _scoreSlots.length;
  bool get isPrepared => _slideDataInstalled;

  double get achievement {
    final base = _totalWeightedPoints == 0
        ? 0.0
        : _earnedWeightedPoints * 100.0 / _totalWeightedPoints;
    final extra = _breakCount == 0 ? 0.0 : _breakExtras / _breakCount;
    return base + extra;
  }

  int get dxScore => _dxScore;
  int get totalDxScore => _scoreSlots.length * 3;
  int get remainingDxScore => max(0, totalDxScore - _lostDxScore);

  double get achievement100Remaining {
    if (_totalWeightedPoints == 0) return 100.0;
    final loss = _lostWeightedPoints * 100.0 / _totalWeightedPoints;
    return (100.0 - loss).clamp(0.0, 100.0).toDouble();
  }

  double get achievement101Remaining {
    final breakLoss = _breakCount == 0 ? 0.0 : _lostBreakExtras / _breakCount;
    return (achievement100Remaining + 1.0 - breakLoss)
        .clamp(0.0, 101.0)
        .toDouble();
  }

  SimaiGameplayChartSummary get summary => SimaiGameplayChartSummary(
    totalScoringNotes: _scoreSlots.length,
    manualNotes: _manualCount,
    autoAssistNotes: 0,
    excludedNotes: _excludedCount,
  );

  void installSlideData(Map<String, SimaiGameplaySlideData> slides) {
    if (_slideDataInstalled) return;
    if (_scoreCommitCursor != 0 || _committed.isNotEmpty) {
      throw StateError('Slide data must be installed before gameplay starts.');
    }
    for (final runtime in _slides) {
      final data = slides[runtime.precalcKey];
      if (data == null || data.stages.isEmpty) {
        throw StateError(
          'Missing gameplay geometry for ${runtime.precalcKey}.',
        );
      }
      runtime.install(data);
      runtime.slot.targetTime = runtime.targetTime;
      _contentEndTime = max(_contentEndTime, runtime.logicalDeadline);
      final watched = <int>{};
      for (final stage in runtime.stages) {
        for (final branch in stage.branches) {
          for (final group in branch.groups) {
            for (final sensor in group.sensors) {
              final sensorIndex = SimaiGameplayInputMapper.sensorIndex(sensor);
              if (sensorIndex >= 0 && watched.add(sensorIndex)) {
                _slidesBySensor[sensorIndex].add(runtime);
              }
            }
          }
        }
      }
    }
    _slideDataInstalled = true;
    _sortRuntimeIndexes();
  }

  bool isLanePressed(int lane) {
    if (lane < 0 || lane >= 8) return false;
    final aIndex = SimaiGameplayInputMapper.sensorIndex(
      Location(lane, NoteGroup.aSensor),
    );
    return _outerPointers[lane].isNotEmpty ||
        _sensorPointers[aIndex].isNotEmpty;
  }

  bool isInputPressed(int lane, SimaiGameplayInputSource source) {
    if (lane < 0 || lane >= 8) return false;
    return switch (source) {
      SimaiGameplayInputSource.outerButton => _outerPointers[lane].isNotEmpty,
      SimaiGameplayInputSource.innerA => isSensorPressed(
        Location(lane, NoteGroup.aSensor),
      ),
    };
  }

  bool isSensorPressed(Location location) {
    final sensorIndex = SimaiGameplayInputMapper.sensorIndex(location);
    return sensorIndex >= 0 && _sensorPointers[sensorIndex].isNotEmpty;
  }

  bool isHeadResolved(int collectionIndex, int noteIndex) {
    final manual =
        _manualHeads[(collectionIndex: collectionIndex, noteIndex: noteIndex)];
    if (manual != null) return manual.headJudgement != null;
    return _headFeedback.containsKey((
      collectionIndex: collectionIndex,
      noteIndex: noteIndex,
    ));
  }

  SimaiJudgementRecord? headFeedbackFor(int collectionIndex, int noteIndex) {
    return _headFeedback[(
      collectionIndex: collectionIndex,
      noteIndex: noteIndex,
    )];
  }

  bool isSlideResolved(int collectionIndex, int noteIndex, int slidePathIndex) {
    return _slideRuntimes[(
              collectionIndex: collectionIndex,
              noteIndex: noteIndex,
              slidePathIndex: slidePathIndex,
            )]
            ?.resolved ??
        false;
  }

  bool isSlideInteractionGroupCleared(
    int collectionIndex,
    int noteIndex,
    int slidePathIndex,
    int visualGroupId,
  ) {
    final runtime =
        _slideRuntimes[(
          collectionIndex: collectionIndex,
          noteIndex: noteIndex,
          slidePathIndex: slidePathIndex,
        )];
    return runtime?.resolved == true ||
        (runtime?.clearedGroupIds.contains(visualGroupId) ?? false);
  }

  SimaiJudgementRecord? slideFeedbackFor(
    int collectionIndex,
    int noteIndex,
    int slidePathIndex,
  ) {
    return _slideFeedback[(
      collectionIndex: collectionIndex,
      noteIndex: noteIndex,
      slidePathIndex: slidePathIndex,
    )];
  }

  bool isHoldPressed(int collectionIndex, int noteIndex, double chartTime) {
    final head =
        _manualHeads[(collectionIndex: collectionIndex, noteIndex: noteIndex)];
    final hold = head?.hold;
    if (hold == null ||
        chartTime < hold.headTime ||
        chartTime >= hold.endTime) {
      return false;
    }
    return switch (hold.source) {
      _HoldSource.lane => isLanePressed(head!.lane),
      _HoldSource.sensor => isSensorPressed(head!.note.location),
    };
  }

  Iterable<SimaiJudgementRecord> recentFeedback(
    double chartTime, {
    double duration = resultFeedbackTailSeconds,
  }) sync* {
    for (var index = _feedback.length - 1; index >= 0; index--) {
      final record = _feedback[index];
      final age = chartTime - record.judgedTime;
      if (age < 0 || age > duration) continue;
      yield record;
    }
  }

  bool pressTarget({
    required SimaiGameplayInputTarget target,
    required int pointerId,
    required double chartTime,
    bool judgeHead = true,
  }) => updatePointerTargets(
    pointerId: pointerId,
    pressedTargets: <SimaiGameplayInputTarget>{target},
    chartTime: chartTime,
    judgeHead: judgeHead,
  );

  bool releaseTarget({
    required SimaiGameplayInputTarget target,
    required int pointerId,
    required double chartTime,
  }) => updatePointerTargets(
    pointerId: pointerId,
    releasedTargets: <SimaiGameplayInputTarget>{target},
    chartTime: chartTime,
  );

  /// Applies every partition transition produced by one pointer event against
  /// a single sensor-state snapshot.
  ///
  /// Mobile contacts commonly cover several adjacent partitions. MajdataPlay
  /// updates all of those states before checking Slide queues; doing the same
  /// here keeps domino progression independent of set iteration order.
  bool updatePointerTargets({
    required int pointerId,
    required double chartTime,
    Set<SimaiGameplayInputTarget> pressedTargets = const {},
    Set<SimaiGameplayInputTarget> releasedTargets = const {},
    bool judgeHead = true,
  }) {
    if (!chartTime.isFinite) return false;
    _ensurePrepared();
    advanceTo(chartTime);

    final presses = Set<SimaiGameplayInputTarget>.of(pressedTargets);
    final releases = Set<SimaiGameplayInputTarget>.of(releasedTargets);
    final unchanged = presses.intersection(releases);
    presses.removeAll(unchanged);
    releases.removeAll(unchanged);

    final affectedLanes = <int>{};
    final affectedSensors = <int>{};
    final affectedOuterLanes = <int>{};
    for (final target in <SimaiGameplayInputTarget>{...releases, ...presses}) {
      switch (target) {
        case SimaiGameplayOuterButtonTarget(:final lane):
          if (lane < 0 || lane >= 8) continue;
          affectedOuterLanes.add(lane);
          affectedLanes.add(lane);
        case SimaiGameplaySensorTarget(:final location):
          final sensorIndex = SimaiGameplayInputMapper.sensorIndex(location);
          if (sensorIndex < 0) continue;
          affectedSensors.add(sensorIndex);
          if (location.group == NoteGroup.aSensor) {
            affectedLanes.add(location.index);
          }
      }
    }

    final laneWasPressed = <int, bool>{
      for (final lane in affectedLanes) lane: isLanePressed(lane),
    };
    final outerWasPressed = <int, bool>{
      for (final lane in affectedOuterLanes)
        lane: _outerPointers[lane].isNotEmpty,
    };
    final sensorWasPressed = <int, bool>{
      for (final sensorIndex in affectedSensors)
        sensorIndex: _sensorPointers[sensorIndex].isNotEmpty,
    };

    var changed = false;
    for (final target in releases) {
      switch (target) {
        case SimaiGameplayOuterButtonTarget(:final lane):
          if (lane >= 0 && lane < 8) {
            changed = _outerPointers[lane].remove(pointerId) || changed;
          }
        case SimaiGameplaySensorTarget(:final location):
          final sensorIndex = SimaiGameplayInputMapper.sensorIndex(location);
          if (sensorIndex >= 0) {
            changed = _sensorPointers[sensorIndex].remove(pointerId) || changed;
          }
      }
    }
    for (final target in presses) {
      switch (target) {
        case SimaiGameplayOuterButtonTarget(:final lane):
          if (lane >= 0 && lane < 8) {
            changed = _outerPointers[lane].add(pointerId) || changed;
          }
        case SimaiGameplaySensorTarget(:final location):
          final sensorIndex = SimaiGameplayInputMapper.sensorIndex(location);
          if (sensorIndex >= 0) {
            changed = _sensorPointers[sensorIndex].add(pointerId) || changed;
          }
      }
    }
    if (!changed) return false;

    final activatedOuterLanes = <int>[];
    for (final lane in affectedOuterLanes) {
      if (outerWasPressed[lane] == false && _outerPointers[lane].isNotEmpty) {
        activatedOuterLanes.add(lane);
      }
    }

    final activatedSensors = <int>[];
    final changedSensors = <int>[];
    for (final sensorIndex in affectedSensors) {
      final wasPressed = sensorWasPressed[sensorIndex] ?? false;
      final isPressed = _sensorPointers[sensorIndex].isNotEmpty;
      if (wasPressed == isPressed) continue;
      changedSensors.add(sensorIndex);
      if (isPressed) {
        _sensorOpenStarts[sensorIndex] = chartTime;
        activatedSensors.add(sensorIndex);
      } else {
        _closeSensorInterval(sensorIndex, chartTime);
      }
    }

    for (final lane in affectedLanes) {
      final wasPressed = laneWasPressed[lane] ?? false;
      final isPressed = isLanePressed(lane);
      if (wasPressed == isPressed) continue;
      if (isPressed) {
        _laneOpenStarts[lane] = chartTime;
      } else {
        _closeLaneInterval(lane, chartTime);
      }
    }

    var judged = false;
    if (judgeHead) {
      activatedOuterLanes.sort();
      for (final lane in activatedOuterLanes) {
        judged = _judgeNearestTap(lane, chartTime) != null || judged;
      }
      activatedSensors.sort();
      for (final sensorIndex in activatedSensors) {
        final location = SimaiGameplayInputMapper.sensorForIndex(sensorIndex);
        if (location.group == NoteGroup.aSensor) {
          final head = _judgeNearestTap(location.index, chartTime);
          if (head != null) {
            _queueInnerSlideHeadActivation(head, sensorIndex);
            judged = true;
          }
        }
        judged = _judgeNearestTouch(sensorIndex, chartTime) || judged;
      }
    }

    judged = _processSlidesForSensors(changedSensors, chartTime) || judged;
    if (judged) _flushResolvedScores();
    revision++;
    return judged;
  }

  bool pressLane({
    required int lane,
    required int pointerId,
    required double chartTime,
    SimaiGameplayInputSource source = SimaiGameplayInputSource.outerButton,
    bool judgeHead = true,
  }) {
    if (lane < 0 || lane >= 8) return false;
    return pressTarget(
      target: source == SimaiGameplayInputSource.outerButton
          ? SimaiGameplayOuterButtonTarget(lane)
          : SimaiGameplaySensorTarget(Location(lane, NoteGroup.aSensor)),
      pointerId: pointerId,
      chartTime: chartTime,
      judgeHead: judgeHead,
    );
  }

  bool releaseLane({
    required int lane,
    required int pointerId,
    required double chartTime,
    SimaiGameplayInputSource source = SimaiGameplayInputSource.outerButton,
  }) {
    if (lane < 0 || lane >= 8) return false;
    return releaseTarget(
      target: source == SimaiGameplayInputSource.outerButton
          ? SimaiGameplayOuterButtonTarget(lane)
          : SimaiGameplaySensorTarget(Location(lane, NoteGroup.aSensor)),
      pointerId: pointerId,
      chartTime: chartTime,
    );
  }

  void clearPointers(double chartTime) {
    if (!chartTime.isFinite) return;
    _ensurePrepared();
    advanceTo(chartTime);
    for (var lane = 0; lane < 8; lane++) {
      if (isLanePressed(lane)) _closeLaneInterval(lane, chartTime);
      _outerPointers[lane].clear();
    }
    for (
      var sensorIndex = 0;
      sensorIndex < SimaiGameplayInputMapper.sensorCount;
      sensorIndex++
    ) {
      if (_sensorPointers[sensorIndex].isNotEmpty) {
        _closeSensorInterval(sensorIndex, chartTime);
      }
      _sensorPointers[sensorIndex].clear();
    }
    for (final slide in _slides) {
      if (!slide.active || slide.resolved) continue;
      slide.resetArmedState();
    }
    revision++;
  }

  void advanceTo(double chartTime) {
    if (!chartTime.isFinite) return;
    _ensurePrepared();
    if (!_currentTime.isFinite || chartTime > _currentTime) {
      _currentTime = chartTime;
    }

    var changed = false;
    while (_slideStartCursor < _slidesByStart.length &&
        _slidesByStart[_slideStartCursor].startTime <= chartTime) {
      final slide = _slidesByStart[_slideStartCursor++];
      changed = _activateSlide(slide) || changed;
    }

    while (_missCursor < _manualHeadsByDeadline.length &&
        chartTime > _manualHeadsByDeadline[_missCursor].deliveryDeadline) {
      final head = _manualHeadsByDeadline[_missCursor++];
      if (head.headJudgement != null) continue;
      _resolveHeadAsMiss(head);
      changed = true;
    }

    while (_holdCursor < _holdsByResolution.length &&
        _holdsByResolution[_holdCursor].resolutionTime <= chartTime) {
      final hold = _holdsByResolution[_holdCursor++];
      if (hold.head.headJudgement == null) _resolveHeadAsMiss(hold.head);
      _resolveHold(hold, max(chartTime, hold.endTime));
      changed = true;
    }

    while (_slideTimeoutCursor < _slidesByTimeout.length &&
        _slidesByTimeout[_slideTimeoutCursor].deliveryDeadline < chartTime) {
      final slide = _slidesByTimeout[_slideTimeoutCursor++];
      if (slide.resolved) continue;
      _resolveSlideTimeout(slide);
      changed = true;
    }

    if (_flushResolvedScores()) changed = true;
    if (changed) revision++;
  }

  bool isReadyForResult(double chartTime) {
    advanceTo(chartTime);
    return !hasPendingScores &&
        chartTime >= _contentEndTime + resultFeedbackTailSeconds;
  }

  SimaiGameplayResult buildResult() {
    _ensurePrepared();
    final cached = _cachedResult;
    if (cached != null) return cached;
    if (hasPendingScores) {
      throw StateError('Gameplay result requested before all notes resolved.');
    }
    final averageOffset = _manualOffsetCount == 0
        ? 0.0
        : _manualOffsetTotal * 1000.0 / _manualOffsetCount;
    final result = SimaiGameplayResult(
      settings: settings,
      judgements: List.unmodifiable(_committed),
      achievement: achievement,
      dxScore: _dxScore,
      totalDxScore: totalDxScore,
      maxCombo: _maxCombo,
      fastCount: _fastCount,
      lateCount: _lateCount,
      averageManualOffsetMs: averageOffset,
      autoAssistCount: _autoAssistCount,
      clearType: _evaluateClearType(),
      gradeCounts: Map.unmodifiable(_gradeCounts),
      typeCounts: Map.unmodifiable(_typeCounts),
    );
    _cachedResult = result;
    return result;
  }

  void _buildIndex() {
    _contentEndTime = max(0.0, chart.finishTiming ?? 0.0);
    for (
      var collectionIndex = 0;
      collectionIndex < chart.noteCollections.length;
      collectionIndex++
    ) {
      final collection = chart.noteCollections[collectionIndex];
      final headTime = _finite(collection.time);
      _contentEndTime = max(_contentEndTime, headTime);
      final touchGroupCandidates = <_ManualHead>[];

      for (var noteIndex = 0; noteIndex < collection.length; noteIndex++) {
        final note = collection[noteIndex];
        final excluded =
            note.type == NoteType.forceInvalidate ||
            (note.styles & NoteStyles.mine) != 0;
        if (excluded) {
          _excludedCount++;
          continue;
        }

        final hasHold = (note.length ?? 0.0) > 0.0;
        final holdLength = hasHold ? _nonNegative(note.length!) : 0.0;
        final endTime = headTime + holdLength;
        _contentEndTime = max(_contentEndTime, endTime);
        final isBreak =
            note.type == NoteType.breakNote ||
            (note.styles & NoteStyles.breakHead) != 0;
        final isTap = note.location.group == NoteGroup.tap;
        final scoringType = isBreak
            ? SimaiGameplayScoringType.breakNote
            : hasHold
            ? SimaiGameplayScoringType.hold
            : isTap
            ? SimaiGameplayScoringType.tap
            : SimaiGameplayScoringType.touch;
        final scoreTime = hasHold ? endTime : headTime;
        final slot = _addScoreSlot(
          targetTime: scoreTime,
          scoringType: scoringType,
        );
        final logicalWindow = isTap
            ? SimaiTapJudgementRules.maximumWindowSeconds
            : SimaiTouchJudgementRules.maximumLateWindowSeconds;
        final head = _ManualHead(
          collectionIndex: collectionIndex,
          noteIndex: noteIndex,
          note: note,
          kind: isTap ? _HeadKind.tap : _HeadKind.touch,
          lane: isTap ? note.location.index : -1,
          sensorIndex: isTap
              ? -1
              : SimaiGameplayInputMapper.sensorIndex(note.location),
          headTime: headTime,
          logicalDeadline: headTime + logicalWindow,
          deliveryDeadline:
              headTime + logicalWindow + inputDeliveryGraceSeconds,
          scoringType: scoringType,
          slot: slot,
        );
        _manualHeads[(collectionIndex: collectionIndex, noteIndex: noteIndex)] =
            head;
        _manualHeadsByDeadline.add(head);
        if (isTap) {
          _tapHeadsByLane[head.lane].add(head);
        } else if (head.sensorIndex >= 0) {
          _touchHeadsBySensor[head.sensorIndex].add(head);
          if (!hasHold) touchGroupCandidates.add(head);
        }

        if (hasHold) {
          final hold = _HoldRuntime(
            head: head,
            headTime: headTime,
            endTime: endTime,
            resolutionTime: max(endTime, head.deliveryDeadline),
            length: holdLength,
            source: isTap ? _HoldSource.lane : _HoldSource.sensor,
            slot: slot,
          );
          head.hold = hold;
          _holdsByResolution.add(hold);
        }

        for (
          var slidePathIndex = 0;
          slidePathIndex < note.slidePaths.length;
          slidePathIndex++
        ) {
          final path = note.slidePaths[slidePathIndex];
          final startTime = headTime + _nonNegative(path.delay);
          final pathEndTime = startTime + _nonNegative(path.duration);
          _contentEndTime = max(_contentEndTime, pathEndTime);
          final pathType = path.type == NoteType.breakNote
              ? SimaiGameplayScoringType.breakNote
              : SimaiGameplayScoringType.slide;
          final pathSlot = _addScoreSlot(
            targetTime: pathEndTime,
            scoringType: pathType,
          );
          final runtime = _SlideRuntime(
            collectionIndex: collectionIndex,
            noteIndex: noteIndex,
            slidePathIndex: slidePathIndex,
            startTime: startTime,
            pathEndTime: pathEndTime,
            duration: _nonNegative(path.duration),
            scoringType: pathType,
            slot: pathSlot,
          );
          head.slides.add(runtime);
          _slides.add(runtime);
          _slideRuntimes[(
                collectionIndex: collectionIndex,
                noteIndex: noteIndex,
                slidePathIndex: slidePathIndex,
              )] =
              runtime;
        }
      }
      _buildTouchGroups(touchGroupCandidates);
    }

    _manualCount = _scoreSlots.length;
    _totalWeightedPoints = _scoreSlots.fold<int>(
      0,
      (sum, slot) => sum + _weightFor(slot.scoringType),
    );
    _breakCount = _scoreSlots
        .where((slot) => slot.scoringType == SimaiGameplayScoringType.breakNote)
        .length;
    _slideDataInstalled = _slides.isEmpty;
    _sortRuntimeIndexes();
  }

  void _sortRuntimeIndexes() {
    for (final lane in _tapHeadsByLane) {
      lane.sort((a, b) => a.headTime.compareTo(b.headTime));
    }
    for (final sensor in _touchHeadsBySensor) {
      sensor.sort((a, b) => a.headTime.compareTo(b.headTime));
    }
    _manualHeadsByDeadline.sort(
      (a, b) => a.deliveryDeadline.compareTo(b.deliveryDeadline),
    );
    _holdsByResolution.sort(
      (a, b) => a.resolutionTime.compareTo(b.resolutionTime),
    );
    if (_slideDataInstalled) {
      _slidesByStart
        ..clear()
        ..addAll(_slides)
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      _slidesByTimeout
        ..clear()
        ..addAll(_slides)
        ..sort((a, b) => a.deliveryDeadline.compareTo(b.deliveryDeadline));
    }
    _scoreSlots.sort((a, b) {
      final time = a.targetTime.compareTo(b.targetTime);
      return time != 0 ? time : a.sourceOrder.compareTo(b.sourceOrder);
    });
  }

  void _buildTouchGroups(List<_ManualHead> candidates) {
    final unvisited = candidates.toSet();
    while (unvisited.isNotEmpty) {
      final root = unvisited.first;
      unvisited.remove(root);
      final component = <_ManualHead>[root];
      final queue = <_ManualHead>[root];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        final neighbors = unvisited
            .where(
              (candidate) => _touchLocationsAdjacent(
                current.note.location,
                candidate.note.location,
              ),
            )
            .toList();
        for (final neighbor in neighbors) {
          unvisited.remove(neighbor);
          component.add(neighbor);
          queue.add(neighbor);
        }
      }
      if (component.length <= 1) continue;
      final group = _TouchGroupRuntime(component);
      for (final head in component) {
        head.touchGroup = group;
      }
    }
  }

  static bool _touchLocationsAdjacent(Location first, Location second) {
    if (first.group == NoteGroup.bSensor && second.group == NoteGroup.bSensor) {
      final difference = (first.index - second.index).abs();
      return difference == 1 || difference == 7;
    }
    if ((first.group == NoteGroup.bSensor &&
            second.group == NoteGroup.cSensor) ||
        (first.group == NoteGroup.cSensor &&
            second.group == NoteGroup.bSensor)) {
      return true;
    }
    if (first.group == NoteGroup.bSensor && second.group == NoteGroup.eSensor) {
      return second.index == first.index ||
          second.index == (first.index + 1) % 8;
    }
    if (first.group == NoteGroup.eSensor && second.group == NoteGroup.bSensor) {
      return first.index == second.index ||
          first.index == (second.index + 1) % 8;
    }
    return false;
  }

  _ScoreSlot _addScoreSlot({
    required double targetTime,
    required SimaiGameplayScoringType scoringType,
  }) {
    final slot = _ScoreSlot(
      targetTime: targetTime,
      scoringType: scoringType,
      sourceOrder: _sourceOrder++,
    );
    _scoreSlots.add(slot);
    return slot;
  }

  _ManualHead? _judgeNearestTap(int lane, double eventTime) {
    final candidates = _tapHeadsByLane[lane];
    final best = _nearestHead(
      candidates,
      eventTime - SimaiTapJudgementRules.maximumWindowSeconds,
      eventTime + SimaiTapJudgementRules.maximumWindowSeconds,
      eventTime,
    );
    if (best == null) return null;
    final judgement = SimaiTapJudgementRules.judge(
      eventTime - best.headTime,
      isEx: best.note.isEx,
    );
    if (judgement == null) return null;
    _resolveHead(best, judgement, eventTime);
    return best;
  }

  void _queueInnerSlideHeadActivation(_ManualHead head, int sensorIndex) {
    for (final slide in head.slides) {
      if (slide.active || slide.resolved) continue;
      slide.pendingHeadActivationSensors.add(sensorIndex);
    }
  }

  bool _judgeNearestTouch(int sensorIndex, double eventTime) {
    final candidates = _touchHeadsBySensor[sensorIndex];
    final best = _nearestHead(
      candidates,
      eventTime - SimaiTouchJudgementRules.maximumLateWindowSeconds,
      eventTime + SimaiTouchJudgementRules.earlyWindowSeconds,
      eventTime,
    );
    if (best == null) return false;
    final judgement = SimaiTouchJudgementRules.judge(eventTime - best.headTime);
    if (judgement == null) return false;
    _resolveHead(best, judgement, eventTime);
    return true;
  }

  _ManualHead? _nearestHead(
    List<_ManualHead> candidates,
    double minimumTargetTime,
    double maximumTargetTime,
    double eventTime,
  ) {
    if (candidates.isEmpty) return null;
    var index = _lowerBoundHeads(candidates, minimumTargetTime);
    _ManualHead? best;
    var bestDistance = double.infinity;
    while (index < candidates.length &&
        candidates[index].headTime <= maximumTargetTime) {
      final candidate = candidates[index++];
      debugCandidateChecks++;
      if (candidate.headJudgement != null) continue;
      final distance = (eventTime - candidate.headTime).abs();
      if (distance < bestDistance - 1e-9 ||
          ((distance - bestDistance).abs() <= 1e-9 &&
              (best == null || candidate.headTime < best.headTime))) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }

  void _resolveHead(
    _ManualHead head,
    SimaiTapJudgement judgement,
    double judgedTime, {
    bool groupAssisted = false,
  }) {
    if (head.headJudgement != null) return;
    final record = SimaiJudgementRecord(
      collectionIndex: head.collectionIndex,
      noteIndex: head.noteIndex,
      slidePathIndex: null,
      targetTime: head.headTime,
      judgedTime: judgedTime,
      offsetSeconds: judgement.offsetSeconds,
      grade: judgement.grade,
      band: judgement.band,
      timing: judgement.timing,
      scoringType: head.scoringType,
      isAuto: false,
      isGroupAssisted: groupAssisted,
    );
    _storeHeadRecord(head, record);
    if (!groupAssisted) _resolveTouchGroupIfReady(head, record);
  }

  void _resolveHeadAsMiss(_ManualHead head) {
    if (head.headJudgement != null) return;
    final offset = head.kind == _HeadKind.tap
        ? SimaiTapJudgementRules.maximumWindowSeconds
        : SimaiTouchJudgementRules.maximumLateWindowSeconds;
    final record = SimaiJudgementRecord(
      collectionIndex: head.collectionIndex,
      noteIndex: head.noteIndex,
      slidePathIndex: null,
      targetTime: head.headTime,
      judgedTime: head.logicalDeadline,
      offsetSeconds: offset,
      grade: SimaiJudgeGrade.miss,
      band: SimaiJudgeBand.miss,
      timing: SimaiJudgeTiming.none,
      scoringType: head.scoringType,
      isAuto: false,
    );
    _storeHeadRecord(head, record);
    _resolveTouchGroupIfReady(head, record);
  }

  void _storeHeadRecord(_ManualHead head, SimaiJudgementRecord record) {
    head.headJudgement = record;
    _headFeedback[(
          collectionIndex: head.collectionIndex,
          noteIndex: head.noteIndex,
        )] =
        record;
    _addFeedback(record);
    if (head.hold == null) head.slot.record = record;
  }

  void _resolveTouchGroupIfReady(
    _ManualHead head,
    SimaiJudgementRecord latestDirect,
  ) {
    final group = head.touchGroup;
    if (group == null || !group.directlyResolved.add(head)) return;
    if (group.directlyResolved.length * 2 <= group.members.length) return;
    for (final member in group.members) {
      if (member.headJudgement != null) continue;
      final inherited = SimaiTapJudgement(
        grade: latestDirect.grade,
        band: latestDirect.band ?? SimaiJudgeBand.miss,
        timing: latestDirect.timing,
        offsetSeconds: latestDirect.offsetSeconds,
      );
      _resolveHead(
        member,
        inherited,
        latestDirect.judgedTime,
        groupAssisted: true,
      );
    }
  }

  void _resolveHold(_HoldRuntime hold, double judgedTime) {
    if (hold.slot.record != null) return;
    final headRecord = hold.head.headJudgement!;
    final ratio = _holdPressRatio(hold);
    final grade = adjustHoldGrade(headRecord.grade, ratio);
    final adjusted = grade != headRecord.grade;
    final record = SimaiJudgementRecord(
      collectionIndex: hold.head.collectionIndex,
      noteIndex: hold.head.noteIndex,
      slidePathIndex: null,
      targetTime: hold.endTime,
      judgedTime: judgedTime,
      offsetSeconds: headRecord.offsetSeconds,
      grade: grade,
      band: adjusted ? null : headRecord.band,
      timing: grade == SimaiJudgeGrade.miss
          ? SimaiJudgeTiming.none
          : headRecord.timing,
      scoringType: hold.head.scoringType,
      isAuto: false,
      holdAdjusted: adjusted,
    );
    hold.slot.record = record;
    _addFeedback(record);
  }

  double _holdPressRatio(_HoldRuntime hold) {
    final isTouchHold = hold.source == _HoldSource.sensor;
    final shortFrames = isTouchHold ? 27 : 18;
    if (hold.length < shortFrames * SimaiTapJudgementRules.frameSeconds) {
      return hold.head.headJudgement!.grade == SimaiJudgeGrade.miss ? 0.0 : 1.0;
    }
    final headIgnoreFrames = isTouchHold ? 15 : 6;
    final start =
        hold.headTime + headIgnoreFrames * SimaiTapJudgementRules.frameSeconds;
    final end = hold.endTime - 12 * SimaiTapJudgementRules.frameSeconds;
    final duration = max(0.0, end - start);
    if (duration <= 1e-9) {
      return hold.head.headJudgement!.grade == SimaiJudgeGrade.miss ? 0.0 : 1.0;
    }

    final intervals = isTouchHold
        ? _sensorIntervals[hold.head.sensorIndex]
        : _laneIntervals[hold.head.lane];
    final openStart = isTouchHold
        ? _sensorOpenStarts[hold.head.sensorIndex]
        : _laneOpenStarts[hold.head.lane];
    var pressed = 0.0;
    for (final interval in intervals) {
      if (interval.end <= start) continue;
      if (interval.start >= end) break;
      pressed += max(0.0, min(interval.end, end) - max(interval.start, start));
    }
    if (openStart != null && openStart < end) {
      pressed += max(0.0, min(currentTime, end) - max(openStart, start));
    }
    return (pressed / duration).clamp(0.0, 1.0).toDouble();
  }

  static SimaiJudgeGrade adjustHoldGrade(
    SimaiJudgeGrade headGrade,
    double pressRatio,
  ) {
    final ratio = pressRatio.isFinite ? pressRatio.clamp(0.0, 1.0) : 0.0;
    if (ratio >= 1.0 - 1e-9) {
      return switch (headGrade) {
        SimaiJudgeGrade.good => SimaiJudgeGrade.great,
        SimaiJudgeGrade.miss => SimaiJudgeGrade.good,
        _ => headGrade,
      };
    }
    if (ratio >= 0.67) {
      return switch (headGrade) {
        SimaiJudgeGrade.criticalPerfect => SimaiJudgeGrade.perfect,
        SimaiJudgeGrade.good => SimaiJudgeGrade.great,
        SimaiJudgeGrade.miss => SimaiJudgeGrade.good,
        _ => headGrade,
      };
    }
    if (ratio >= 0.33) {
      return switch (headGrade) {
        SimaiJudgeGrade.criticalPerfect ||
        SimaiJudgeGrade.perfect => SimaiJudgeGrade.great,
        SimaiJudgeGrade.miss => SimaiJudgeGrade.good,
        _ => headGrade,
      };
    }
    if (ratio >= 0.05) return SimaiJudgeGrade.good;
    return switch (headGrade) {
      SimaiJudgeGrade.criticalPerfect ||
      SimaiJudgeGrade.perfect ||
      SimaiJudgeGrade.great => SimaiJudgeGrade.good,
      _ => headGrade,
    };
  }

  bool _processSlidesForSensors(Iterable<int> sensorIndexes, double eventTime) {
    var judged = false;
    final candidates = <_SlideRuntime>{};
    final sortedIndexes = sensorIndexes.toSet().toList()..sort();
    for (final sensorIndex in sortedIndexes) {
      if (sensorIndex < 0 || sensorIndex >= _slidesBySensor.length) continue;
      candidates.addAll(_slidesBySensor[sensorIndex]);
    }
    for (final slide in candidates) {
      if (!slide.active || slide.resolved) continue;
      debugSlideChecks++;
      if (eventTime > slide.logicalDeadline + 1e-9) {
        _resolveSlideTimeout(slide);
        judged = true;
        continue;
      }
      judged = _processSlide(slide, eventTime) || judged;
    }
    return judged;
  }

  bool _activateSlide(_SlideRuntime slide) {
    slide.active = true;
    final pending = slide.pendingHeadActivationSensors.toList()..sort();
    slide.pendingHeadActivationSensors.clear();
    var changed = pending.isNotEmpty;

    // An inner-A hit on the Slide head is a real sensor activation. If that
    // contact was released before the path became active, replay its pulse at
    // activation time so the first matching trajectory group still receives
    // the same ON -> OFF transition. A contact that is still held is handled
    // by the real sensor snapshot below and remains armed until release.
    for (final sensorIndex in pending) {
      if (sensorIndex < 0 || sensorIndex >= _sensorPointers.length) continue;
      if (_sensorPointers[sensorIndex].isNotEmpty) continue;
      changed =
          _processSlide(
            slide,
            slide.startTime,
            virtualPressedSensors: <int>{sensorIndex},
          ) ||
          changed;
      if (slide.resolved) return true;
      changed = _processSlide(slide, slide.startTime) || changed;
      if (slide.resolved) return true;
    }

    changed = _processSlide(slide, slide.startTime) || changed;
    return changed;
  }

  bool _processSlide(
    _SlideRuntime slide,
    double eventTime, {
    Set<int> virtualPressedSensors = const <int>{},
  }) {
    if (!slide.active || slide.resolved) return false;
    while (slide.stageIndex < slide.stages.length) {
      final stage = slide.stages[slide.stageIndex];
      var stageChanged = false;
      for (final branch in stage.branches) {
        stageChanged =
            _processSlideBranch(
              slide,
              branch,
              virtualPressedSensors: virtualPressedSensors,
            ) ||
            stageChanged;
      }
      if (stage.branches.every((branch) => branch.complete)) {
        slide.stageIndex++;
        stageChanged = true;
        continue;
      }
      if (!stageChanged) break;
      break;
    }
    if (slide.stageIndex >= slide.stages.length) {
      _resolveSlide(slide, eventTime);
      return true;
    }
    return false;
  }

  bool _processSlideBranch(
    _SlideRuntime slide,
    _SlideBranchRuntime branch, {
    Set<int> virtualPressedSensors = const <int>{},
  }) {
    bool isOn(SimaiGameplaySlideInteractionGroup group) =>
        group.sensors.any((sensor) {
          final sensorIndex = SimaiGameplayInputMapper.sensorIndex(sensor);
          return virtualPressedSensors.contains(sensorIndex) ||
              isSensorPressed(sensor);
        });

    var changed = false;
    while (!branch.complete) {
      final current = branch.groups[branch.cursor];
      final currentOn = isOn(current);
      if (branch.armed) {
        if (!currentOn) {
          slide.clearedGroupIds.add(current.visualGroupId);
          branch.cursor++;
          branch.armed = false;
          changed = true;
          continue;
        }
      } else if (currentOn) {
        branch.armed = true;
        changed = true;
      }

      if (!current.blocksSkip && branch.cursor + 1 < branch.groups.length) {
        final next = branch.groups[branch.cursor + 1];
        if (isOn(next)) {
          slide.clearedGroupIds.add(current.visualGroupId);
          branch.cursor++;
          branch.armed = true;
          changed = true;
          continue;
        }
      }
      break;
    }
    return changed;
  }

  void _resolveSlide(_SlideRuntime slide, double judgedTime) {
    if (slide.resolved) return;
    final judgement = SimaiSlideJudgementRules.judge(
      judgedTime - slide.targetTime,
      finalZoneDwellSeconds: slide.finalZoneDwellSeconds,
    );
    if (judgement == null) {
      _resolveSlideTimeout(slide);
      return;
    }
    final record = SimaiJudgementRecord(
      collectionIndex: slide.collectionIndex,
      noteIndex: slide.noteIndex,
      slidePathIndex: slide.slidePathIndex,
      targetTime: slide.targetTime,
      judgedTime: judgedTime,
      offsetSeconds: judgement.offsetSeconds,
      grade: judgement.grade,
      band: judgement.band,
      timing: judgement.timing,
      scoringType: slide.scoringType,
      isAuto: false,
    );
    _storeSlideRecord(slide, record);
  }

  void _resolveSlideTimeout(_SlideRuntime slide) {
    if (slide.resolved) return;
    final remaining = slide.remainingGroupCount;
    final grade = remaining <= 1 ? SimaiJudgeGrade.good : SimaiJudgeGrade.miss;
    final record = SimaiJudgementRecord(
      collectionIndex: slide.collectionIndex,
      noteIndex: slide.noteIndex,
      slidePathIndex: slide.slidePathIndex,
      targetTime: slide.targetTime,
      judgedTime: slide.logicalDeadline,
      offsetSeconds: SimaiSlideJudgementRules.maximumWindowSeconds,
      grade: grade,
      band: grade == SimaiJudgeGrade.good
          ? SimaiJudgeBand.good
          : SimaiJudgeBand.miss,
      timing: grade == SimaiJudgeGrade.good
          ? SimaiJudgeTiming.late
          : SimaiJudgeTiming.none,
      scoringType: slide.scoringType,
      isAuto: false,
    );
    _storeSlideRecord(slide, record);
  }

  void _storeSlideRecord(_SlideRuntime slide, SimaiJudgementRecord record) {
    slide
      ..resolved = true
      ..slot.record = record;
    _slideFeedback[(
          collectionIndex: slide.collectionIndex,
          noteIndex: slide.noteIndex,
          slidePathIndex: slide.slidePathIndex,
        )] =
        record;
    _addFeedback(record);
  }

  void _closeLaneInterval(int lane, double chartTime) {
    final start = _laneOpenStarts[lane];
    if (start != null) {
      _laneIntervals[lane].add(_PressInterval(start, max(start, chartTime)));
    }
    _laneOpenStarts[lane] = null;
  }

  void _closeSensorInterval(int sensorIndex, double chartTime) {
    final start = _sensorOpenStarts[sensorIndex];
    if (start != null) {
      _sensorIntervals[sensorIndex].add(
        _PressInterval(start, max(start, chartTime)),
      );
    }
    _sensorOpenStarts[sensorIndex] = null;
  }

  bool _flushResolvedScores() {
    var changed = false;
    while (_scoreCommitCursor < _scoreSlots.length) {
      final record = _scoreSlots[_scoreCommitCursor].record;
      if (record == null) break;
      _scoreCommitCursor++;
      _commit(record);
      changed = true;
    }
    return changed;
  }

  void _commit(SimaiJudgementRecord record) {
    _committed.add(record);
    _gradeCounts[record.grade] = (_gradeCounts[record.grade] ?? 0) + 1;
    _typeCounts[record.scoringType] =
        (_typeCounts[record.scoringType] ?? 0) + 1;
    if (record.isAuto) _autoAssistCount++;
    final weight = _weightFor(record.scoringType);
    final basePoints = _basePointsFor(record.grade);
    _earnedWeightedPoints += basePoints * weight;
    _lostWeightedPoints += (1.0 - basePoints) * weight;
    if (record.scoringType == SimaiGameplayScoringType.breakNote) {
      final breakExtra = _breakExtraFor(record);
      _breakExtras += breakExtra;
      _lostBreakExtras += 1.0 - breakExtra;
    }
    final dxPoints = _dxPointsFor(record.grade);
    _dxScore += dxPoints;
    _lostDxScore += 3 - dxPoints;

    if (record.grade == SimaiJudgeGrade.miss) {
      _currentCombo = 0;
    } else {
      _currentCombo++;
      _maxCombo = max(_maxCombo, _currentCombo);
    }

    if (!record.isAuto && record.grade != SimaiJudgeGrade.miss) {
      if (record.timing == SimaiJudgeTiming.fast) _fastCount++;
      if (record.timing == SimaiJudgeTiming.late) _lateCount++;
      if (!record.isGroupAssisted) {
        _manualOffsetTotal += record.offsetSeconds;
        _manualOffsetCount++;
      }
    }
  }

  SimaiGameplayClearType _evaluateClearType() {
    if (achievement < 80.0) return SimaiGameplayClearType.failed;
    if ((_gradeCounts[SimaiJudgeGrade.miss] ?? 0) > 0) {
      return SimaiGameplayClearType.clear;
    }
    if ((_gradeCounts[SimaiJudgeGrade.good] ?? 0) > 0) {
      return SimaiGameplayClearType.fullCombo;
    }
    if ((_gradeCounts[SimaiJudgeGrade.great] ?? 0) > 0) {
      return SimaiGameplayClearType.fullComboPlus;
    }
    if (_breakCount == 0) return SimaiGameplayClearType.allPerfect;
    final criticalBreaks = _committed.where(
      (record) =>
          record.scoringType == SimaiGameplayScoringType.breakNote &&
          record.grade == SimaiJudgeGrade.criticalPerfect,
    );
    return criticalBreaks.length == _breakCount
        ? SimaiGameplayClearType.allPerfectPlus
        : SimaiGameplayClearType.allPerfect;
  }

  void _addFeedback(SimaiJudgementRecord record) {
    _feedback.add(record);
    if (_feedback.length > 128) _feedback.removeRange(0, 32);
  }

  void _ensurePrepared() {
    if (!_slideDataInstalled) {
      throw StateError('Slide gameplay data has not been installed yet.');
    }
  }

  static int _lowerBoundHeads(List<_ManualHead> values, double target) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (values[mid].headTime < target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  static int _weightFor(SimaiGameplayScoringType type) => switch (type) {
    SimaiGameplayScoringType.tap || SimaiGameplayScoringType.touch => 1,
    SimaiGameplayScoringType.hold => 2,
    SimaiGameplayScoringType.slide => 3,
    SimaiGameplayScoringType.breakNote => 5,
  };

  static double _basePointsFor(SimaiJudgeGrade grade) => switch (grade) {
    SimaiJudgeGrade.criticalPerfect || SimaiJudgeGrade.perfect => 1.0,
    SimaiJudgeGrade.great => 0.8,
    SimaiJudgeGrade.good => 0.5,
    SimaiJudgeGrade.miss => 0.0,
  };

  static int _dxPointsFor(SimaiJudgeGrade grade) => switch (grade) {
    SimaiJudgeGrade.criticalPerfect => 3,
    SimaiJudgeGrade.perfect => 2,
    SimaiJudgeGrade.great => 1,
    SimaiJudgeGrade.good || SimaiJudgeGrade.miss => 0,
  };

  static double _breakExtraFor(SimaiJudgementRecord record) {
    return switch (record.grade) {
      SimaiJudgeGrade.criticalPerfect => 1.0,
      SimaiJudgeGrade.perfect =>
        record.offsetSeconds.abs() <=
                2 * SimaiTapJudgementRules.frameSeconds + 1e-9
            ? 0.75
            : 0.5,
      SimaiJudgeGrade.great => 0.4,
      SimaiJudgeGrade.good => 0.3,
      SimaiJudgeGrade.miss => 0.0,
    };
  }

  static double _finite(double value) => value.isFinite ? value : 0.0;
  static double _nonNegative(double value) =>
      value.isFinite && value > 0.0 ? value : 0.0;
}

enum _HeadKind { tap, touch }

class _ManualHead {
  _ManualHead({
    required this.collectionIndex,
    required this.noteIndex,
    required this.note,
    required this.kind,
    required this.lane,
    required this.sensorIndex,
    required this.headTime,
    required this.logicalDeadline,
    required this.deliveryDeadline,
    required this.scoringType,
    required this.slot,
  });

  final int collectionIndex;
  final int noteIndex;
  final Note note;
  final _HeadKind kind;
  final int lane;
  final int sensorIndex;
  final double headTime;
  final double logicalDeadline;
  final double deliveryDeadline;
  final SimaiGameplayScoringType scoringType;
  final _ScoreSlot slot;
  SimaiJudgementRecord? headJudgement;
  final List<_SlideRuntime> slides = <_SlideRuntime>[];
  _HoldRuntime? hold;
  _TouchGroupRuntime? touchGroup;
}

enum _HoldSource { lane, sensor }

class _HoldRuntime {
  _HoldRuntime({
    required this.head,
    required this.headTime,
    required this.endTime,
    required this.resolutionTime,
    required this.length,
    required this.source,
    required this.slot,
  });

  final _ManualHead head;
  final double headTime;
  final double endTime;
  final double resolutionTime;
  final double length;
  final _HoldSource source;
  final _ScoreSlot slot;
}

class _TouchGroupRuntime {
  _TouchGroupRuntime(this.members);

  final List<_ManualHead> members;
  final Set<_ManualHead> directlyResolved = <_ManualHead>{};
}

class _SlideRuntime {
  _SlideRuntime({
    required this.collectionIndex,
    required this.noteIndex,
    required this.slidePathIndex,
    required this.startTime,
    required this.pathEndTime,
    required this.duration,
    required this.scoringType,
    required this.slot,
  });

  final int collectionIndex;
  final int noteIndex;
  final int slidePathIndex;
  final double startTime;
  final double pathEndTime;
  final double duration;
  final SimaiGameplayScoringType scoringType;
  final _ScoreSlot slot;
  final Set<int> clearedGroupIds = <int>{};
  final Set<int> pendingHeadActivationSensors = <int>{};
  List<_SlideStageRuntime> stages = const <_SlideStageRuntime>[];
  double targetTime = 0.0;
  double finalZoneDwellSeconds = 0.0;
  double logicalDeadline = 0.0;
  double deliveryDeadline = 0.0;
  int stageIndex = 0;
  bool active = false;
  bool resolved = false;

  String get precalcKey => '${collectionIndex}_${noteIndex}_$slidePathIndex';

  void install(SimaiGameplaySlideData data) {
    final progress = data.judgementProgress.isFinite
        ? data.judgementProgress.clamp(0.0, 1.0).toDouble()
        : 1.0;
    targetTime = startTime + duration * progress;
    finalZoneDwellSeconds = duration * (1.0 - progress);
    logicalDeadline =
        targetTime + SimaiSlideJudgementRules.maximumWindowSeconds;
    deliveryDeadline =
        logicalDeadline + SimaiGameplaySession.inputDeliveryGraceSeconds;
    stages = List.unmodifiable(
      data.stages.map(
        (stage) => _SlideStageRuntime(
          branches: List.unmodifiable(
            stage.branches.map(
              (branch) =>
                  _SlideBranchRuntime(groups: List.unmodifiable(branch.groups)),
            ),
          ),
        ),
      ),
    );
  }

  int get remainingGroupCount {
    if (resolved) return 0;
    var count = 0;
    for (var index = stageIndex; index < stages.length; index++) {
      final stage = stages[index];
      for (final branch in stage.branches) {
        count += branch.groups.length - branch.cursor;
      }
    }
    return count;
  }

  void resetArmedState() {
    if (stageIndex >= stages.length) return;
    for (final branch in stages[stageIndex].branches) {
      branch.armed = false;
    }
  }
}

class _SlideStageRuntime {
  const _SlideStageRuntime({required this.branches});

  final List<_SlideBranchRuntime> branches;
}

class _SlideBranchRuntime {
  _SlideBranchRuntime({required this.groups});

  final List<SimaiGameplaySlideInteractionGroup> groups;
  int cursor = 0;
  bool armed = false;

  bool get complete => cursor >= groups.length;
}

class _ScoreSlot {
  _ScoreSlot({
    required this.targetTime,
    required this.scoringType,
    required this.sourceOrder,
  });

  double targetTime;
  final SimaiGameplayScoringType scoringType;
  final int sourceOrder;
  SimaiJudgementRecord? record;
}

class _PressInterval {
  const _PressInterval(this.start, this.end);

  final double start;
  final double end;
}
