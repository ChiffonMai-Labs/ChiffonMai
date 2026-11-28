import 'dart:math';
import 'dart:typed_data';

import '../structures/location.dart';
import '../structures/mai_chart.dart';
import '../structures/note.dart';
import '../structures/note_group.dart';
import '../structures/note_styles.dart';
import '../structures/note_type.dart';
import '../ui/center_display_mode.dart';
import 'gameplay_models.dart';

class SimaiGameplaySession {
  SimaiGameplaySession({
    required this.chart,
    required SimaiGameplaySettings settings,
  }) : settings = settings.normalized() {
    _buildIndex();
  }

  static const int _allSensorsMask =
      (1 << SimaiGameplayInputMapper.sensorBitCount) - 1;
  static const int _validInputMask =
      (1 << (SimaiGameplayInputMapper.outerLaneBitOffset + 8)) - 1;

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

  /// 按内屏 33 个传感器索引当前活跃中的滑星，将触控推进复杂度从 O(S_total) 降至 O(S_active)。
  final List<List<_SlideRuntime>> _activeSlidesBySensor = List.generate(
    SimaiGameplayInputMapper.sensorCount,
    (_) => <_SlideRuntime>[],
  );
  final List<_SlideRuntime> _slideCheckScratch = <_SlideRuntime>[];
  int _slideVisitStamp = 0;

  final List<_ScoreSlot> _scoreSlots = <_ScoreSlot>[];
  final Map<int, _ManualHead> _manualHeads = <int, _ManualHead>{};
  final Map<int, _SlideRuntime> _slideRuntimes = <int, _SlideRuntime>{};
  final Map<int, SimaiJudgementRecord> _headFeedback =
      <int, SimaiJudgementRecord>{};
  final Map<int, SimaiJudgementRecord> _slideFeedback =
      <int, SimaiJudgementRecord>{};
  final List<SimaiJudgementRecord> _feedback = <SimaiJudgementRecord>[];

  // 以 41-bit 位掩码与计数数组维护指针及按键/传感器按压状态，触控热路径零集合分配。
  final Map<int, int> _pointerMasks = <int, int>{};
  final Int32List _outerPointerCounts = Int32List(8);
  final Int32List _sensorPointerCounts = Int32List(
    SimaiGameplayInputMapper.sensorCount,
  );
  int _pressedOuterMask = 0;
  int _pressedSensorMask = 0;

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
  int _slideStartEventCount = 0;

  int revision = 0;
  int _scoreRevision = 0;
  int debugCandidateChecks = 0;
  int debugSlideChecks = 0;

  static const double resultFeedbackTailSeconds = 0.8;
  static const double inputDeliveryGraceSeconds = 0.05;

  /// 仅在达成率 / Combo / DX 分数实际提交变更时递增，避免触控微移引发 HUD 重排。
  int get scoreRevision => _scoreRevision;
  double get currentTime => _currentTime.isFinite ? _currentTime : 0.0;
  double get judgementOffsetSeconds => settings.judgementOffsetMs / 1000.0;
  double get contentEndTime => _contentEndTime;
  int get currentCombo => _currentCombo;
  int get maxCombo => _maxCombo;
  int get committedCount => _committed.length;
  int get feedbackCount => _feedback.length;
  SimaiJudgementRecord feedbackAt(int index) => _feedback[index];
  int get slideStartEventCount => _slideStartEventCount;
  int get totalScoringNotes => _scoreSlots.length;
  bool get hasPendingScores => _scoreCommitCursor < _scoreSlots.length;
  bool get isPrepared => _slideDataInstalled;

  static int _packNoteKey(int collectionIndex, int noteIndex) =>
      (collectionIndex << 20) | noteIndex;

  static int _packSlideKey(
    int collectionIndex,
    int noteIndex,
    int slideIndex,
  ) => (collectionIndex << 20) | (noteIndex << 8) | slideIndex;

  /// 本谱面理论满分达成率（含绝赞为 101%，无绝赞为 100%，空谱为 0%）。
  double get maxAchievement =>
      _totalWeightedPoints == 0 ? 0.0 : (_breakCount > 0 ? 101.0 : 100.0);

  /// 0%+ 模式达成率：基础得分百分比加已获得的绝赞奖励百分比。
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

  /// 100%+ 模式达成率：从 100% 起步扣除基础失分，并随绝赞判定累加奖励分。
  double get achievement100Plus {
    if (_totalWeightedPoints == 0) return 100.0;
    final lostBase = _lostWeightedPoints * 100.0 / _totalWeightedPoints;
    final earnedExtra = _breakCount == 0 ? 0.0 : _breakExtras / _breakCount;
    return (100.0 - lostBase + earnedExtra)
        .clamp(0.0, maxAchievement)
        .toDouble();
  }

  /// 兼容历史命名，等价于 [achievement100Plus]。
  double get achievement100Remaining => achievement100Plus;

  /// 101%- 模式达成率：从理论满分起步，实时扣除基础失分与绝赞奖励失分。
  double get achievement101Remaining {
    if (_totalWeightedPoints == 0) return 101.0;
    final lostBase = _lostWeightedPoints * 100.0 / _totalWeightedPoints;
    final lostExtra = _breakCount == 0 ? 0.0 : _lostBreakExtras / _breakCount;
    return (maxAchievement - lostBase - lostExtra)
        .clamp(0.0, maxAchievement)
        .toDouble();
  }

  /// 距离 S 级（97%）的剩余容错达成率（101% 满分谱面从 4.0000% 起减）。
  double get achievementOverS => achievement101Remaining - 97.0;

  /// 距离 SS 级（99%）的剩余容错达成率（101% 满分谱面从 2.0000% 起减）。
  double get achievementOverSS => achievement101Remaining - 99.0;

  /// 距离 SSS 级（100%）的剩余容错达成率（101% 满分谱面从 1.0000% 起减）。
  double get achievementOverSSS => achievement101Remaining - 100.0;

  /// 按剩余可得 DX 分数计算的星级与门槛差值文案。
  String get dxStarBonusText =>
      formatSimaiDxStarBonus(remainingDxScore, totalDxScore);

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
    }
    _slideDataInstalled = true;
    _sortRuntimeIndexes();
  }

  bool isLanePressed(int lane) {
    if (lane < 0 || lane >= 8) return false;
    final bit = 1 << lane;
    return ((_pressedOuterMask | _pressedSensorMask) & bit) != 0;
  }

  bool isInputPressed(int lane, SimaiGameplayInputSource source) {
    if (lane < 0 || lane >= 8) return false;
    final bit = 1 << lane;
    return switch (source) {
      SimaiGameplayInputSource.outerButton => (_pressedOuterMask & bit) != 0,
      SimaiGameplayInputSource.innerA => (_pressedSensorMask & bit) != 0,
    };
  }

  bool isSensorPressed(Location location) {
    final sensorIndex = SimaiGameplayInputMapper.sensorIndex(location);
    return sensorIndex >= 0 && (_pressedSensorMask & (1 << sensorIndex)) != 0;
  }

  bool isHeadResolved(int collectionIndex, int noteIndex) {
    final key = _packNoteKey(collectionIndex, noteIndex);
    final manual = _manualHeads[key];
    if (manual != null) return manual.headJudgement != null;
    return _headFeedback.containsKey(key);
  }

  SimaiJudgementRecord? headFeedbackFor(int collectionIndex, int noteIndex) {
    return _headFeedback[_packNoteKey(collectionIndex, noteIndex)];
  }

  /// 按打包整型键 O(1) 查询滑星运行时句柄，供渲染层避免在箭头循环中反复查表。
  Object? findSlideRuntime(
    int collectionIndex,
    int noteIndex,
    int slideIndex,
  ) {
    return _slideRuntimes[_packSlideKey(
      collectionIndex,
      noteIndex,
      slideIndex,
    )];
  }

  /// 直接基于 [findSlideRuntime] 返回的运行时句柄判断指定视觉分组是否已消除。
  bool isSlideGroupClearedForRuntime(Object? runtime, int visualGroupId) {
    if (runtime is! _SlideRuntime) return false;
    return runtime.isGroupCleared(visualGroupId);
  }

  bool isSlideResolved(int collectionIndex, int noteIndex, int slidePathIndex) {
    return _slideRuntimes[_packSlideKey(
              collectionIndex,
              noteIndex,
              slidePathIndex,
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
    return isSlideGroupClearedForRuntime(
      findSlideRuntime(collectionIndex, noteIndex, slidePathIndex),
      visualGroupId,
    );
  }

  SimaiJudgementRecord? slideFeedbackFor(
    int collectionIndex,
    int noteIndex,
    int slidePathIndex,
  ) {
    return _slideFeedback[_packSlideKey(
      collectionIndex,
      noteIndex,
      slidePathIndex,
    )];
  }

  bool isHoldPressed(int collectionIndex, int noteIndex, double chartTime) {
    final head = _manualHeads[_packNoteKey(collectionIndex, noteIndex)];
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
    double? displayTime,
    bool judgeHead = true,
    bool allowOuterButtonHeadJudge = true,
  }) => updatePointerMask(
    pointerId: pointerId,
    releasedMask: 0,
    pressedMask: SimaiGameplayInputMapper.maskForTarget(target),
    chartTime: chartTime,
    displayTime: displayTime,
    judgeHead: judgeHead,
    allowOuterButtonHeadJudge: allowOuterButtonHeadJudge,
  );

  bool releaseTarget({
    required SimaiGameplayInputTarget target,
    required int pointerId,
    required double chartTime,
    double? displayTime,
  }) => updatePointerMask(
    pointerId: pointerId,
    releasedMask: SimaiGameplayInputMapper.maskForTarget(target),
    pressedMask: 0,
    chartTime: chartTime,
    displayTime: displayTime,
  );

  /// 应用单次触控事件带来的全部分区状态变化（兼容旧版集合签名）。
  bool updatePointerTargets({
    required int pointerId,
    required double chartTime,
    Set<SimaiGameplayInputTarget> pressedTargets = const {},
    Set<SimaiGameplayInputTarget> releasedTargets = const {},
    bool judgeHead = true,
    double? displayTime,
    bool allowOuterButtonHeadJudge = true,
  }) {
    return updatePointerMask(
      pointerId: pointerId,
      releasedMask: SimaiGameplayInputMapper.maskForTargets(releasedTargets),
      pressedMask: SimaiGameplayInputMapper.maskForTargets(pressedTargets),
      chartTime: chartTime,
      displayTime: displayTime,
      judgeHead: judgeHead,
      allowOuterButtonHeadJudge: allowOuterButtonHeadJudge,
    );
  }

  /// 零堆分配位掩码热路径：以 41-bit 位掩码更新单指按压状态并驱动判定与滑星推进。
  ///
  /// - [chartTime] 为判定时钟（已叠加判定偏移），用于窗口比对与超时推进；
  /// - [displayTime] 为视觉时钟（缺省退回 [chartTime]），用于记录 `judgedTime` 供 HUD 与打击特效即刻呈现；
  /// - [allowOuterButtonHeadJudge] 传 `false`（如 `PointerMove`）时禁止外键触发 Tap 判定，内屏 A 与 Touch 保留蹭键。
  bool updatePointerMask({
    required int pointerId,
    required int releasedMask,
    required int pressedMask,
    required double chartTime,
    double? displayTime,
    bool judgeHead = true,
    bool allowOuterButtonHeadJudge = true,
  }) {
    if (!chartTime.isFinite) return false;
    _ensurePrepared();
    final visualTime = (displayTime != null && displayTime.isFinite)
        ? displayTime
        : chartTime;
    advanceTo(chartTime, displayTime: visualTime);

    final maskedRelease = releasedMask & _validInputMask;
    final maskedPress = pressedMask & _validInputMask;
    final unchanged = maskedRelease & maskedPress;
    final cleanRelease = maskedRelease & ~unchanged;
    final cleanPress = maskedPress & ~unchanged;

    final oldPtrMask = _pointerMasks[pointerId] ?? 0;
    final effectiveRelease = cleanRelease & oldPtrMask;
    final effectivePress = cleanPress & ~oldPtrMask;
    if (effectiveRelease == 0 && effectivePress == 0) return false;

    final newPtrMask = (oldPtrMask & ~effectiveRelease) | effectivePress;
    if (newPtrMask == 0) {
      _pointerMasks.remove(pointerId);
    } else {
      _pointerMasks[pointerId] = newPtrMask;
    }

    final releaseSensorMask = effectiveRelease & _allSensorsMask;
    final pressSensorMask = effectivePress & _allSensorsMask;
    final releaseOuterMask =
        (effectiveRelease >> SimaiGameplayInputMapper.outerLaneBitOffset) &
        0xFF;
    final pressOuterMask =
        (effectivePress >> SimaiGameplayInputMapper.outerLaneBitOffset) & 0xFF;

    final prevLaneMask = _pressedOuterMask | (_pressedSensorMask & 0xFF);

    // 1. 更新外圈按键计数与全局掩码
    var activatedOuterMask = 0;
    var bits = releaseOuterMask;
    while (bits != 0) {
      final lowBit = bits & -bits;
      final lane = lowBit.bitLength - 1;
      bits ^= lowBit;
      final nextCount = _outerPointerCounts[lane] - 1;
      _outerPointerCounts[lane] = nextCount;
      if (nextCount == 0) {
        _pressedOuterMask &= ~lowBit;
      }
    }
    bits = pressOuterMask;
    while (bits != 0) {
      final lowBit = bits & -bits;
      final lane = lowBit.bitLength - 1;
      bits ^= lowBit;
      final prevCount = _outerPointerCounts[lane];
      _outerPointerCounts[lane] = prevCount + 1;
      if (prevCount == 0) {
        _pressedOuterMask |= lowBit;
        activatedOuterMask |= lowBit;
      }
    }

    // 2. 更新内屏 33 个传感器计数、全局掩码与 Hold 区间
    var activatedSensorMask = 0;
    bits = releaseSensorMask;
    while (bits != 0) {
      final lowBit = bits & -bits;
      final sensorIndex = lowBit.bitLength - 1;
      bits ^= lowBit;
      final nextCount = _sensorPointerCounts[sensorIndex] - 1;
      _sensorPointerCounts[sensorIndex] = nextCount;
      if (nextCount == 0) {
        _pressedSensorMask &= ~lowBit;
        _closeSensorInterval(sensorIndex, chartTime);
      }
    }
    bits = pressSensorMask;
    while (bits != 0) {
      final lowBit = bits & -bits;
      final sensorIndex = lowBit.bitLength - 1;
      bits ^= lowBit;
      final prevCount = _sensorPointerCounts[sensorIndex];
      _sensorPointerCounts[sensorIndex] = prevCount + 1;
      if (prevCount == 0) {
        _pressedSensorMask |= lowBit;
        _sensorOpenStarts[sensorIndex] = chartTime;
        activatedSensorMask |= lowBit;
      }
    }

    // 3. 更新 8 轨合集（外键 OR 内屏 A）的 Hold 按压区间
    final nextLaneMask = _pressedOuterMask | (_pressedSensorMask & 0xFF);
    var changedLaneMask = prevLaneMask ^ nextLaneMask;
    while (changedLaneMask != 0) {
      final lowBit = changedLaneMask & -changedLaneMask;
      final lane = lowBit.bitLength - 1;
      changedLaneMask ^= lowBit;
      if ((nextLaneMask & lowBit) != 0) {
        _laneOpenStarts[lane] = chartTime;
      } else {
        _closeLaneInterval(lane, chartTime);
      }
    }

    // 4. 判定 Tap/星头与 Touch：
    //    P1-1：内屏 A 传感器优先于外键判定星头，避免同时命中时跳过内屏滑星首区预激活；
    //    P1-4：移动态可传 allowOuterButtonHeadJudge = false，防止外键滑擦误吃邻轨 Tap。
    var judged = false;
    if (judgeHead) {
      var judgedTapLaneMask = 0;
      bits = activatedSensorMask;
      while (bits != 0) {
        final lowBit = bits & -bits;
        final sensorIndex = lowBit.bitLength - 1;
        bits ^= lowBit;
        if (sensorIndex < 8) {
          final head = _judgeNearestTap(
            sensorIndex,
            chartTime,
            displayTime: visualTime,
          );
          if (head != null) {
            judgedTapLaneMask |= lowBit;
            _activateHeadSlides(
              head,
              chartTime,
              displayTime: visualTime,
              innerSensorIndex: sensorIndex,
            );
            judged = true;
          }
        }
        if (_judgeNearestTouch(
          sensorIndex,
          chartTime,
          displayTime: visualTime,
        )) {
          judged = true;
        }
      }

      if (allowOuterButtonHeadJudge) {
        bits = activatedOuterMask & ~judgedTapLaneMask;
        while (bits != 0) {
          final lowBit = bits & -bits;
          final lane = lowBit.bitLength - 1;
          bits ^= lowBit;
          final head = _judgeNearestTap(
            lane,
            chartTime,
            displayTime: visualTime,
          );
          if (head != null) {
            final innerAlsoPressed = (_pressedSensorMask & lowBit) != 0;
            _activateHeadSlides(
              head,
              chartTime,
              displayTime: visualTime,
              innerSensorIndex: innerAlsoPressed ? lane : null,
            );
            judged = true;
          }
        }
      }
    }

    // 5. P1-2：记录本指针新进入/新离开的传感器掩码，即使已有其他手指按住
    //    （Hold / 汇聚双星），也派发推进脉冲，防止互相劫持锁死。
    final touchedSensorMask = pressSensorMask | releaseSensorMask;
    if (touchedSensorMask != 0) {
      final pointerCurrentSensorMask = newPtrMask & _allSensorsMask;
      judged =
          _processSlidesForSensorMask(
            touchedSensorMask,
            chartTime,
            displayTime: visualTime,
            pointerEnteredSensorMask: pressSensorMask,
            pointerReleasedSensorMask: releaseSensorMask,
            pointerCurrentSensorMask: pointerCurrentSensorMask,
          ) ||
          judged;
    }

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
    double? displayTime,
  }) {
    if (lane < 0 || lane >= 8) return false;
    return pressTarget(
      target: source == SimaiGameplayInputSource.outerButton
          ? SimaiGameplayOuterButtonTarget(lane)
          : SimaiGameplaySensorTarget(Location(lane, NoteGroup.aSensor)),
      pointerId: pointerId,
      chartTime: chartTime,
      displayTime: displayTime,
      judgeHead: judgeHead,
    );
  }

  bool releaseLane({
    required int lane,
    required int pointerId,
    required double chartTime,
    SimaiGameplayInputSource source = SimaiGameplayInputSource.outerButton,
    double? displayTime,
  }) {
    if (lane < 0 || lane >= 8) return false;
    return releaseTarget(
      target: source == SimaiGameplayInputSource.outerButton
          ? SimaiGameplayOuterButtonTarget(lane)
          : SimaiGameplaySensorTarget(Location(lane, NoteGroup.aSensor)),
      pointerId: pointerId,
      chartTime: chartTime,
      displayTime: displayTime,
    );
  }

  void clearPointers(double chartTime, {double? displayTime}) {
    if (!chartTime.isFinite) return;
    _ensurePrepared();
    final visualTime = (displayTime != null && displayTime.isFinite)
        ? displayTime
        : chartTime;
    advanceTo(chartTime, displayTime: visualTime);
    for (var lane = 0; lane < 8; lane++) {
      if (isLanePressed(lane)) _closeLaneInterval(lane, chartTime);
      _outerPointerCounts[lane] = 0;
    }
    for (
      var sensorIndex = 0;
      sensorIndex < SimaiGameplayInputMapper.sensorCount;
      sensorIndex++
    ) {
      if (_sensorPointerCounts[sensorIndex] > 0) {
        _closeSensorInterval(sensorIndex, chartTime);
      }
      _sensorPointerCounts[sensorIndex] = 0;
    }
    _pressedOuterMask = 0;
    _pressedSensorMask = 0;
    _pointerMasks.clear();
    for (final slide in _slides) {
      if (!slide.active || slide.resolved) continue;
      slide.resetArmedState();
    }
    revision++;
  }

  /// 按判定时钟 [chartTime] 推进滑星激活、漏判截止与 Hold 结算；
  /// 所有生成的判定记录均使用视觉时钟 [displayTime]（默认退回 [chartTime]）写入 `judgedTime`。
  void advanceTo(double chartTime, {double? displayTime}) {
    if (!chartTime.isFinite) return;
    _ensurePrepared();
    final visualTime = (displayTime != null && displayTime.isFinite)
        ? displayTime
        : chartTime;
    if (!_currentTime.isFinite || chartTime > _currentTime) {
      _currentTime = chartTime;
    }

    var changed = false;
    while (_slideStartCursor < _slidesByStart.length &&
        _slidesByStart[_slideStartCursor].activationTime <= chartTime) {
      final slide = _slidesByStart[_slideStartCursor++];
      changed =
          _activateSlide(
            slide,
            slide.activationTime,
            displayTime: visualTime,
          ) ||
          changed;
    }

    while (_missCursor < _manualHeadsByDeadline.length &&
        chartTime > _manualHeadsByDeadline[_missCursor].deliveryDeadline) {
      final head = _manualHeadsByDeadline[_missCursor++];
      if (head.headJudgement != null) continue;
      _resolveHeadAsMiss(head, judgedTime: visualTime);
      changed = true;
    }

    while (_holdCursor < _holdsByResolution.length &&
        _holdsByResolution[_holdCursor].resolutionTime <= chartTime) {
      final hold = _holdsByResolution[_holdCursor++];
      if (hold.head.headJudgement == null) {
        _resolveHeadAsMiss(hold.head, judgedTime: visualTime);
      }
      _resolveHold(hold, visualTime);
      changed = true;
    }

    while (_slideTimeoutCursor < _slidesByTimeout.length &&
        _slidesByTimeout[_slideTimeoutCursor].deliveryDeadline < chartTime) {
      final slide = _slidesByTimeout[_slideTimeoutCursor++];
      if (slide.resolved) continue;
      _resolveSlideTimeout(slide, judgedTime: visualTime);
      changed = true;
    }

    if (_flushResolvedScores()) changed = true;
    if (changed) revision++;
  }

  bool isReadyForResult(double chartTime, {double? displayTime}) {
    advanceTo(chartTime, displayTime: displayTime);
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
        final isMine = (note.styles & NoteStyles.mine) != 0;
        if (isMine) {
          _excludedCount++;
          continue;
        }

        // P2-3：支持无头星（? / !）：forceInvalidate 且含滑星路径时跳过星头 Tap 计分，
        // 仅保留 slidePaths 的游玩与计分。
        final isHeadlessSlide =
            note.type == NoteType.forceInvalidate && note.slidePaths.isNotEmpty;
        if (note.type == NoteType.forceInvalidate && !isHeadlessSlide) {
          _excludedCount++;
          continue;
        }

        _ManualHead? head;
        if (!isHeadlessSlide) {
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
          final createdHead = _ManualHead(
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
          head = createdHead;
          _manualHeads[_packNoteKey(collectionIndex, noteIndex)] = createdHead;
          _manualHeadsByDeadline.add(createdHead);
          if (isTap) {
            _tapHeadsByLane[createdHead.lane].add(createdHead);
          } else if (createdHead.sensorIndex >= 0) {
            _touchHeadsBySensor[createdHead.sensorIndex].add(createdHead);
            if (!hasHold) touchGroupCandidates.add(createdHead);
          }

          if (hasHold) {
            final hold = _HoldRuntime(
              head: createdHead,
              headTime: headTime,
              endTime: endTime,
              resolutionTime: max(endTime, createdHead.deliveryDeadline),
              length: holdLength,
              source: isTap ? _HoldSource.lane : _HoldSource.sensor,
              slot: slot,
            );
            createdHead.hold = hold;
            _holdsByResolution.add(hold);
          }
        }

        for (
          var slidePathIndex = 0;
          slidePathIndex < note.slidePaths.length;
          slidePathIndex++
        ) {
          final path = note.slidePaths[slidePathIndex];
          final startTime = headTime + _nonNegative(path.delay);
          final pathEndTime = startTime + _nonNegative(path.duration);
          // P0-2：将滑星传感器跟踪激活时机提前到星头早判起点，消除 1 拍等待期内提前滑过的箭头被吞。
          final activationTime =
              headTime - SimaiTapJudgementRules.maximumWindowSeconds;
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
            headTime: headTime,
            activationTime: activationTime,
            startTime: startTime,
            pathEndTime: pathEndTime,
            duration: _nonNegative(path.duration),
            scoringType: pathType,
            slot: pathSlot,
          );
          head?.slides.add(runtime);
          _slides.add(runtime);
          _slideRuntimes[_packSlideKey(
                collectionIndex,
                noteIndex,
                slidePathIndex,
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
        ..sort((a, b) => a.activationTime.compareTo(b.activationTime));
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

  _ManualHead? _judgeNearestTap(
    int lane,
    double eventTime, {
    required double displayTime,
  }) {
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
    _resolveHead(best, judgement, displayTime);
    return best;
  }

  /// 星头命中后立即确保对应滑星处于激活态；若由内屏 A 触发且尚未激活则登记首区预激活。
  void _activateHeadSlides(
    _ManualHead head,
    double eventTime, {
    required double displayTime,
    int? innerSensorIndex,
  }) {
    if (head.slides.isEmpty) return;
    for (final slide in head.slides) {
      if (slide.resolved) continue;
      if (!slide.active) {
        if (innerSensorIndex != null &&
            innerSensorIndex >= 0 &&
            innerSensorIndex < SimaiGameplayInputMapper.sensorBitCount) {
          slide.pendingHeadActivationMask |= 1 << innerSensorIndex;
        }
        _activateSlide(slide, eventTime, displayTime: displayTime);
      }
    }
  }

  bool _judgeNearestTouch(
    int sensorIndex,
    double eventTime, {
    required double displayTime,
  }) {
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
    _resolveHead(best, judgement, displayTime);
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

  void _resolveHeadAsMiss(_ManualHead head, {required double judgedTime}) {
    if (head.headJudgement != null) return;
    final offset = head.kind == _HeadKind.tap
        ? SimaiTapJudgementRules.maximumWindowSeconds
        : SimaiTouchJudgementRules.maximumLateWindowSeconds;
    final record = SimaiJudgementRecord(
      collectionIndex: head.collectionIndex,
      noteIndex: head.noteIndex,
      slidePathIndex: null,
      targetTime: head.headTime,
      judgedTime: judgedTime,
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
    _headFeedback[_packNoteKey(head.collectionIndex, head.noteIndex)] = record;
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
    // 二分查找直接跳过 end <= start 的历史区间，避免长谱后期从下标 0 线性扫描。
    var index = _lowerBoundIntervalEnd(intervals, start);
    while (index < intervals.length) {
      final interval = intervals[index++];
      if (interval.start >= end) break;
      if (interval.end <= start) continue;
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

  void _registerActiveSlide(_SlideRuntime slide) {
    if (slide.inActiveIndex || slide.resolved) return;
    slide.inActiveIndex = true;
    var mask = slide.watchedSensorMask;
    while (mask != 0) {
      final lowBit = mask & -mask;
      final sensorIndex = lowBit.bitLength - 1;
      mask ^= lowBit;
      _activeSlidesBySensor[sensorIndex].add(slide);
    }
  }

  void _unregisterActiveSlide(_SlideRuntime slide) {
    if (!slide.inActiveIndex) return;
    slide.inActiveIndex = false;
    var mask = slide.watchedSensorMask;
    while (mask != 0) {
      final lowBit = mask & -mask;
      final sensorIndex = lowBit.bitLength - 1;
      mask ^= lowBit;
      final bucket = _activeSlidesBySensor[sensorIndex];
      for (var i = 0; i < bucket.length; i++) {
        if (identical(bucket[i], slide)) {
          final last = bucket.removeLast();
          if (i < bucket.length) bucket[i] = last;
          break;
        }
      }
    }
  }

  bool _processSlidesForSensorMask(
    int sensorMask,
    double eventTime, {
    required double displayTime,
    int pointerEnteredSensorMask = 0,
    int pointerReleasedSensorMask = 0,
    int pointerCurrentSensorMask = 0,
  }) {
    final scratch = _slideCheckScratch;
    scratch.clear();
    final stamp = ++_slideVisitStamp;

    var bits = sensorMask;
    while (bits != 0) {
      final lowBit = bits & -bits;
      final sensorIndex = lowBit.bitLength - 1;
      bits ^= lowBit;
      final bucket = _activeSlidesBySensor[sensorIndex];
      for (var i = 0; i < bucket.length; i++) {
        final slide = bucket[i];
        if (slide.visitStamp == stamp) continue;
        slide.visitStamp = stamp;
        scratch.add(slide);
      }
    }

    var judged = false;
    try {
      for (var i = 0; i < scratch.length; i++) {
        final slide = scratch[i];
        if (!slide.active || slide.resolved) continue;
        debugSlideChecks++;
        if (eventTime > slide.logicalDeadline + 1e-9) {
          _resolveSlideTimeout(slide, judgedTime: displayTime);
          judged = true;
          continue;
        }
        judged =
            _processSlide(
              slide,
              eventTime,
              displayTime: displayTime,
              virtualPressedMask: pointerEnteredSensorMask,
              pointerReleasedSensorMask: pointerReleasedSensorMask,
              pointerCurrentSensorMask: pointerCurrentSensorMask,
            ) ||
            judged;
      }
    } finally {
      scratch.clear();
    }
    return judged;
  }

  bool _activateSlide(
    _SlideRuntime slide,
    double eventTime, {
    required double displayTime,
  }) {
    if (slide.active || slide.resolved) return false;
    slide.active = true;
    _registerActiveSlide(slide);
    final pendingMask = slide.pendingHeadActivationMask;
    slide.pendingHeadActivationMask = 0;
    var changed = pendingMask != 0;

    // 若星头内屏触发在激活前已抬手，回放一次首区脉冲确保轨迹首组正常推进。
    var bits = pendingMask;
    while (bits != 0) {
      final lowBit = bits & -bits;
      bits ^= lowBit;
      if ((_pressedSensorMask & lowBit) != 0) continue;
      changed =
          _processSlide(
            slide,
            eventTime,
            displayTime: displayTime,
            virtualPressedMask: lowBit,
          ) ||
          changed;
      if (slide.resolved) return true;
      changed =
          _processSlide(slide, eventTime, displayTime: displayTime) || changed;
      if (slide.resolved) return true;
    }

    changed =
        _processSlide(slide, eventTime, displayTime: displayTime) || changed;
    return changed;
  }

  bool _processSlide(
    _SlideRuntime slide,
    double eventTime, {
    required double displayTime,
    int virtualPressedMask = 0,
    int pointerReleasedSensorMask = 0,
    int pointerCurrentSensorMask = 0,
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
              virtualPressedMask: virtualPressedMask,
              pointerReleasedSensorMask: pointerReleasedSensorMask,
              pointerCurrentSensorMask: pointerCurrentSensorMask,
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
      _resolveSlide(slide, eventTime, judgedTime: displayTime);
      return true;
    }
    return false;
  }

  bool _processSlideBranch(
    _SlideRuntime slide,
    _SlideBranchRuntime branch, {
    int virtualPressedMask = 0,
    int pointerReleasedSensorMask = 0,
    int pointerCurrentSensorMask = 0,
  }) {
    final activeSensorMask = _pressedSensorMask | virtualPressedMask;
    var changed = false;
    while (!branch.complete) {
      final cursor = branch.cursor;
      final current = branch.groups[cursor];
      final currentMask = branch.groupSensorMasks[cursor];
      final currentOn = (activeSensorMask & currentMask) != 0;

      // P0-1：终点组进入即消除并推进完成，不再强制等待 ON -> OFF 抬手。
      if (cursor == branch.groups.length - 1) {
        if (currentOn) {
          slide.markGroupCleared(current.visualGroupId);
          if (!slide.slideStarted) {
            slide.slideStarted = true;
            _slideStartEventCount++;
          }
          branch.cursor++;
          branch.armed = false;
          changed = true;
        }
        break;
      }

      if (branch.armed) {
        // P1-2：若全局传感器已被其他手指（如 Hold）按住，只要当前指针刚离开本组传感器，
        // 仍按 ON -> OFF 脉冲推进，避免跨 Hold / 汇聚双星死锁。
        final pointerExitedGroup =
            (pointerReleasedSensorMask & currentMask) != 0 &&
            (pointerCurrentSensorMask & currentMask) == 0;
        if (!currentOn || pointerExitedGroup) {
          slide.markGroupCleared(current.visualGroupId);
          if (!slide.slideStarted) {
            slide.slideStarted = true;
            _slideStartEventCount++;
          }
          branch.cursor++;
          branch.armed = false;
          changed = true;
          continue;
        }
      } else if (currentOn) {
        branch.armed = true;
        changed = true;
      }

      if (!current.blocksSkip && cursor + 1 < branch.groups.length) {
        final nextMask = branch.groupSensorMasks[cursor + 1];
        if ((activeSensorMask & nextMask) != 0) {
          slide.markGroupCleared(current.visualGroupId);
          if (!slide.slideStarted) {
            slide.slideStarted = true;
            _slideStartEventCount++;
          }
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

  void _resolveSlide(
    _SlideRuntime slide,
    double eventTime, {
    required double judgedTime,
  }) {
    if (slide.resolved) return;
    final judgement = SimaiSlideJudgementRules.judge(
      eventTime - slide.targetTime,
      finalZoneDwellSeconds: slide.finalZoneDwellSeconds,
    );
    if (judgement == null) {
      _resolveSlideTimeout(slide, judgedTime: judgedTime);
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

  void _resolveSlideTimeout(_SlideRuntime slide, {required double judgedTime}) {
    if (slide.resolved) return;
    final remaining = slide.remainingGroupCount;
    final grade = remaining <= 1 ? SimaiJudgeGrade.good : SimaiJudgeGrade.miss;
    final record = SimaiJudgementRecord(
      collectionIndex: slide.collectionIndex,
      noteIndex: slide.noteIndex,
      slidePathIndex: slide.slidePathIndex,
      targetTime: slide.targetTime,
      judgedTime: judgedTime,
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
    _unregisterActiveSlide(slide);
    _slideFeedback[_packSlideKey(
          slide.collectionIndex,
          slide.noteIndex,
          slide.slidePathIndex,
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
    _scoreRevision++;
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

  static int _lowerBoundIntervalEnd(
    List<_PressInterval> intervals,
    double target,
  ) {
    var low = 0;
    var high = intervals.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (intervals[mid].end <= target) {
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
    required this.headTime,
    required this.activationTime,
    required this.startTime,
    required this.pathEndTime,
    required this.duration,
    required this.scoringType,
    required this.slot,
  });

  final int collectionIndex;
  final int noteIndex;
  final int slidePathIndex;
  final double headTime;
  final double activationTime;
  final double startTime;
  final double pathEndTime;
  final double duration;
  final SimaiGameplayScoringType scoringType;
  final _ScoreSlot slot;

  int clearedGroupMask = 0;
  Set<int>? _overflowClearedGroupIds;
  int pendingHeadActivationMask = 0;
  int watchedSensorMask = 0;
  int visitStamp = 0;
  bool inActiveIndex = false;

  List<_SlideStageRuntime> stages = const <_SlideStageRuntime>[];
  double targetTime = 0.0;
  double finalZoneDwellSeconds = 0.0;
  double logicalDeadline = 0.0;
  double deliveryDeadline = 0.0;
  int stageIndex = 0;
  bool active = false;
  bool slideStarted = false;
  bool resolved = false;

  String get precalcKey => '${collectionIndex}_${noteIndex}_$slidePathIndex';

  void markGroupCleared(int visualGroupId) {
    if (visualGroupId >= 0 && visualGroupId < 62) {
      clearedGroupMask |= 1 << visualGroupId;
    } else {
      (_overflowClearedGroupIds ??= <int>{}).add(visualGroupId);
    }
  }

  bool isGroupCleared(int visualGroupId) {
    if (resolved) return true;
    if (visualGroupId >= 0 && visualGroupId < 62) {
      return (clearedGroupMask & (1 << visualGroupId)) != 0;
    }
    return _overflowClearedGroupIds?.contains(visualGroupId) ?? false;
  }

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
    var watched = 0;
    stages = List.unmodifiable(
      data.stages.map(
        (stage) => _SlideStageRuntime(
          branches: List.unmodifiable(
            stage.branches.map((branch) {
              final groups = List<SimaiGameplaySlideInteractionGroup>.unmodifiable(
                branch.groups,
              );
              final masks = List<int>.filled(groups.length, 0);
              for (var i = 0; i < groups.length; i++) {
                var groupMask = 0;
                for (final sensor in groups[i].sensors) {
                  final sensorIndex = SimaiGameplayInputMapper.sensorIndex(
                    sensor,
                  );
                  if (sensorIndex >= 0) {
                    groupMask |= 1 << sensorIndex;
                  }
                }
                masks[i] = groupMask;
                watched |= groupMask;
              }
              return _SlideBranchRuntime(
                groups: groups,
                groupSensorMasks: masks,
              );
            }),
          ),
        ),
      ),
    );
    watchedSensorMask = watched;
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
  _SlideBranchRuntime({
    required this.groups,
    required this.groupSensorMasks,
  });

  final List<SimaiGameplaySlideInteractionGroup> groups;
  final List<int> groupSensorMasks;
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
