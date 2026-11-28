import 'dart:math';

import '../gameplay/gameplay_models.dart';
import '../structures/mai_chart.dart';
import '../structures/note_group.dart';
import '../structures/note_styles.dart';
import '../structures/note_type.dart';

/// 谱面观看与视频导出时的自动模拟游玩判定方式。
///
/// 仅影响判定表示、击打特效、达成率 / DX 分数 / 连击等模拟统计；
/// 不改变正解音的原始谱面播放时机。
enum SimaiAutoPlayMode {
  allCriticalPerfect('全 CP', '全部音符均为 Critical Perfect（理论 101% / 满 DX 分）'),
  allPerfect('全小P', '全部音符为小P（含绝赞小P，可展示 FAST/LATE）'),
  randomPerfect('随机小P', '全部音符在 CP 与小P之间随机分布'),
  breakRandomPerfect('仅绝赞随机小P', '非绝赞全 CP，绝赞在 2600 / 2550 / 2500 间随机'),
  allRandom('所有判定全随机', '在 CP / 小P / GREAT / GOOD / MISS 间随机分布'),
  allGreat('全 GREAT', '全部音符判定为 GREAT（粉色击打特效与约 80% 达成率）'),
  allGood('全 GOOD', '全部音符判定为 GOOD（绿色击打特效与约 50% 达成率）'),
  allMiss('全 MISS', '全部音符判定为 MISS（无击打特效，达成率与连击归零）');

  const SimaiAutoPlayMode(this.label, this.description);

  final String label;
  final String description;

  /// 该模拟游玩方式是否包含随机判定细节（等级、绝赞细分或 FAST/LATE）。
  bool get hasRandomDetails =>
      this != SimaiAutoPlayMode.allCriticalPerfect &&
      this != SimaiAutoPlayMode.allMiss;

  static SimaiAutoPlayMode fromName(
    Object? raw, {
    SimaiAutoPlayMode fallback = SimaiAutoPlayMode.allCriticalPerfect,
  }) {
    if (raw is SimaiAutoPlayMode) return raw;
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) return value;
      }
    } else if (raw is int && raw >= 0 && raw < values.length) {
      return values[raw];
    }
    return fallback;
  }
}

/// 某一谱面时刻对应的模拟游玩统计快照（前缀和 O(log N) 查询结果）。
class SimaiAutoPlaySnapshot {
  const SimaiAutoPlaySnapshot({
    required this.judgedCount,
    required this.totalEventCount,
    required this.achievementAdd,
    required this.achievement100Plus,
    required this.achievement101Subtract,
    required this.maxAchievement,
    required this.earnedDxScore,
    required this.lostDxScore,
    required this.maxDxScore,
    required this.combo,
    required this.totalCombo,
  });

  final int judgedCount;
  final int totalEventCount;
  final double achievementAdd;
  final double achievement100Plus;
  final double achievement101Subtract;
  final double maxAchievement;
  final int earnedDxScore;
  final int lostDxScore;
  final int maxDxScore;
  final int combo;
  final int totalCombo;

  int get remainingDxScore => max(0, maxDxScore - lostDxScore);
}

class _SimulatedNoteOutcome {
  const _SimulatedNoteOutcome({
    required this.grade,
    required this.band,
    required this.timing,
  });

  final SimaiJudgeGrade grade;
  final SimaiJudgeBand band;
  final SimaiJudgeTiming timing;
}

/// 针对 `(chart, mode)` 预计算的确定性自动游玩判定时间线。
///
/// - 使用确定性哈希生成每颗音符的模拟判定，拖动进度条、暂停与离线视频导出帧结果完全一致；
/// - 使用前缀和数组支撑 O(log N) 达成率 / DX 分数 / 连击查询，渲染热路径零堆分配；
/// - 提供 `headGradeFor(cIdx, nIdx)` 供击打特效与长条按压态 O(1) 查询。
class SimaiAutoPlayTimeline {
  SimaiAutoPlayTimeline._({
    required this.mode,
    required this.seed,
    required this.events,
    required List<double> eventTimes,
    required List<double> earnedBasePrefix,
    required List<double> lostBasePrefix,
    required List<double> earnedBreakPrefix,
    required List<double> lostBreakPrefix,
    required List<int> earnedDxPrefix,
    required List<int> lostDxPrefix,
    required List<int> comboPrefix,
    required Map<int, SimaiJudgeGrade> headGrades,
    required this.totalBaseWeight,
    required this.totalBreakCount,
    required this.criticalPerfectCount,
    required this.perfectCount,
    required this.greatCount,
    required this.goodCount,
    required this.missCount,
    required this.fastCount,
    required this.lateCount,
  }) : _eventTimes = eventTimes,
       _earnedBasePrefix = earnedBasePrefix,
       _lostBasePrefix = lostBasePrefix,
       _earnedBreakPrefix = earnedBreakPrefix,
       _lostBreakPrefix = lostBreakPrefix,
       _earnedDxPrefix = earnedDxPrefix,
       _lostDxPrefix = lostDxPrefix,
       _comboPrefix = comboPrefix,
       _headGrades = headGrades;

  final SimaiAutoPlayMode mode;
  final int seed;
  final List<SimaiJudgementRecord> events;
  final List<double> _eventTimes;
  final List<double> _earnedBasePrefix;
  final List<double> _lostBasePrefix;
  final List<double> _earnedBreakPrefix;
  final List<double> _lostBreakPrefix;
  final List<int> _earnedDxPrefix;
  final List<int> _lostDxPrefix;
  final List<int> _comboPrefix;
  final Map<int, SimaiJudgeGrade> _headGrades;
  final double totalBaseWeight;
  final int totalBreakCount;
  final int criticalPerfectCount;
  final int perfectCount;
  final int greatCount;
  final int goodCount;
  final int missCount;
  final int fastCount;
  final int lateCount;

  // 缓存最近一次已判定数量对应的快照，同帧多 HUD 查询与音符间隔期零分配复用。
  int _cachedJudgedCount = -1;
  SimaiAutoPlaySnapshot? _cachedSnapshot;

  int get eventCount => _eventTimes.length;
  int get maxDxScore => eventCount * 3;
  double get maxAchievement =>
      totalBaseWeight <= 0 ? 0.0 : (totalBreakCount > 0 ? 101.0 : 100.0);

  /// 整谱结束时的模拟最终达成率。
  double get finalAchievement {
    final double basePct = totalBaseWeight <= 0
        ? 0.0
        : (_earnedBasePrefix.last * 100.0 / totalBaseWeight);
    final double earnedBreakPct = totalBreakCount <= 0
        ? 0.0
        : (_earnedBreakPrefix.last / totalBreakCount);
    return basePct + earnedBreakPct;
  }

  /// 供设置区展示的随机判定分布摘要。
  String get summaryLabel {
    final achv = finalAchievement.toStringAsFixed(4);
    if (mode == SimaiAutoPlayMode.allPerfect ||
        mode == SimaiAutoPlayMode.allGreat ||
        mode == SimaiAutoPlayMode.allGood) {
      return '预计 $achv% · FAST $fastCount / LATE $lateCount';
    }
    if (greatCount == 0 && goodCount == 0 && missCount == 0) {
      return '预计 $achv% · CP $criticalPerfectCount / P $perfectCount · FAST $fastCount / LATE $lateCount';
    }
    return '预计 $achv% · CP $criticalPerfectCount / P $perfectCount / Gr $greatCount / Gd $goodCount / M $missCount';
  }

  /// 供打击特效与 Hold 按压辉光 O(1) 查询头部模拟判定。
  SimaiJudgeGrade headGradeFor(int collectionIndex, int noteIndex) {
    if (mode == SimaiAutoPlayMode.allCriticalPerfect) {
      return SimaiJudgeGrade.criticalPerfect;
    }
    return _headGrades[_headKey(collectionIndex, noteIndex)] ??
        SimaiJudgeGrade.criticalPerfect;
  }

  SimaiAutoPlaySnapshot snapshotAt(double chartTime) {
    final safeTime = chartTime.isFinite ? chartTime : 0.0;
    final cached = _cachedSnapshot;
    final int judgedCount;
    if (cached != null &&
        (_cachedJudgedCount == 0 ||
            _eventTimes[_cachedJudgedCount - 1] <= safeTime) &&
        (_cachedJudgedCount >= _eventTimes.length ||
            safeTime < _eventTimes[_cachedJudgedCount])) {
      return cached;
    } else {
      judgedCount = _upperBound(_eventTimes, safeTime);
      if (cached != null && judgedCount == _cachedJudgedCount) {
        return cached;
      }
    }
    final earnedBase = _earnedBasePrefix[judgedCount];
    final lostBase = _lostBasePrefix[judgedCount];
    final earnedBreak = _earnedBreakPrefix[judgedCount];
    final lostBreak = _lostBreakPrefix[judgedCount];

    final double basePct = totalBaseWeight <= 0
        ? 0.0
        : (earnedBase * 100.0 / totalBaseWeight);
    final double lostBasePct = totalBaseWeight <= 0
        ? 0.0
        : (lostBase * 100.0 / totalBaseWeight);
    final double earnedBreakPct = totalBreakCount <= 0
        ? 0.0
        : (earnedBreak / totalBreakCount);
    final double lostBreakPct = totalBreakCount <= 0
        ? 0.0
        : (lostBreak / totalBreakCount);

    final double achievementAdd = basePct + earnedBreakPct;
    final double achievement100Plus = totalBaseWeight <= 0
        ? 100.0
        : max(0.0, 100.0 - lostBasePct + earnedBreakPct);
    final double achievement101Subtract = max(
      0.0,
      maxAchievement - lostBasePct - lostBreakPct,
    );

    final snapshot = SimaiAutoPlaySnapshot(
      judgedCount: judgedCount,
      totalEventCount: eventCount,
      achievementAdd: achievementAdd,
      achievement100Plus: achievement100Plus,
      achievement101Subtract: achievement101Subtract,
      maxAchievement: maxAchievement,
      earnedDxScore: _earnedDxPrefix[judgedCount],
      lostDxScore: _lostDxPrefix[judgedCount],
      maxDxScore: maxDxScore,
      combo: _comboPrefix[judgedCount],
      totalCombo: eventCount,
    );
    _cachedJudgedCount = judgedCount;
    _cachedSnapshot = snapshot;
    return snapshot;
  }

  static int _headKey(int collectionIndex, int noteIndex) =>
      (collectionIndex << 16) ^ noteIndex;

  factory SimaiAutoPlayTimeline.build(
    MaiChart chart,
    SimaiAutoPlayMode mode, {
    int seed = 0,
  }) {
    final records = <SimaiJudgementRecord>[];
    final headGrades = <int, SimaiJudgeGrade>{};
    final collections = chart.noteCollections;

    for (var cIdx = 0; cIdx < collections.length; cIdx++) {
      final collection = collections[cIdx];
      final baseTime = collection.time;
      if (!baseTime.isFinite) continue;

      for (var nIdx = 0; nIdx < collection.length; nIdx++) {
        final note = collection[nIdx];
        final isBreakHead =
            note.type == NoteType.breakNote ||
            (note.styles & NoteStyles.breakHead) != 0;

        if (note.type != NoteType.forceInvalidate) {
          final bool isHold =
              note.type == NoteType.hold ||
              note.isTouchHold ||
              note.length != null;
          final double hitTime = isHold
              ? baseTime + _nonNegativeFinite(note.length)
              : baseTime;
          if (hitTime.isFinite) {
            final SimaiGameplayScoringType scoringType;
            if (isBreakHead) {
              scoringType = SimaiGameplayScoringType.breakNote;
            } else if (isHold) {
              scoringType = SimaiGameplayScoringType.hold;
            } else if (note.location.group != NoteGroup.tap) {
              scoringType = SimaiGameplayScoringType.touch;
            } else {
              scoringType = SimaiGameplayScoringType.tap;
            }
            final outcome = _simulateOutcome(
              mode: mode,
              seed: seed,
              isBreak: isBreakHead,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              slidePathIndex: -1,
            );
            headGrades[_headKey(cIdx, nIdx)] = outcome.grade;
            records.add(
              SimaiJudgementRecord(
                collectionIndex: cIdx,
                noteIndex: nIdx,
                slidePathIndex: null,
                targetTime: hitTime,
                judgedTime: hitTime,
                offsetSeconds: _representativeOffset(outcome),
                grade: outcome.grade,
                band: outcome.band,
                timing: outcome.timing,
                scoringType: scoringType,
                isAuto: false,
              ),
            );
          }
        }

        for (var sIdx = 0; sIdx < note.slidePaths.length; sIdx++) {
          final slide = note.slidePaths[sIdx];
          final double endTime =
              baseTime +
              _nonNegativeFinite(slide.delay) +
              _nonNegativeFinite(slide.duration);
          if (!endTime.isFinite) continue;
          final isBreakSlide = slide.type == NoteType.breakNote;
          final outcome = _simulateOutcome(
            mode: mode,
            seed: seed,
            isBreak: isBreakSlide,
            collectionIndex: cIdx,
            noteIndex: nIdx,
            slidePathIndex: sIdx,
          );
          records.add(
            SimaiJudgementRecord(
              collectionIndex: cIdx,
              noteIndex: nIdx,
              slidePathIndex: sIdx,
              targetTime: endTime,
              judgedTime: endTime,
              offsetSeconds: _representativeOffset(outcome),
              grade: outcome.grade,
              band: outcome.band,
              timing: outcome.timing,
              scoringType: isBreakSlide
                  ? SimaiGameplayScoringType.breakNote
                  : SimaiGameplayScoringType.slide,
              isAuto: false,
            ),
          );
        }
      }
    }

    records.sort((a, b) => a.judgedTime.compareTo(b.judgedTime));

    final eventTimes = <double>[];
    final earnedBasePrefix = <double>[0.0];
    final lostBasePrefix = <double>[0.0];
    final earnedBreakPrefix = <double>[0.0];
    final lostBreakPrefix = <double>[0.0];
    final earnedDxPrefix = <int>[0];
    final lostDxPrefix = <int>[0];
    final comboPrefix = <int>[0];

    var totalBaseWeight = 0.0;
    var totalBreakCount = 0;
    var currentCombo = 0;
    var criticalPerfectCount = 0;
    var perfectCount = 0;
    var greatCount = 0;
    var goodCount = 0;
    var missCount = 0;
    var fastCount = 0;
    var lateCount = 0;

    for (final record in records) {
      eventTimes.add(record.judgedTime);
      switch (record.grade) {
        case SimaiJudgeGrade.criticalPerfect:
          criticalPerfectCount++;
        case SimaiJudgeGrade.perfect:
          perfectCount++;
        case SimaiJudgeGrade.great:
          greatCount++;
        case SimaiJudgeGrade.good:
          goodCount++;
        case SimaiJudgeGrade.miss:
          missCount++;
      }
      if (record.timing == SimaiJudgeTiming.fast) {
        fastCount++;
      } else if (record.timing == SimaiJudgeTiming.late) {
        lateCount++;
      }
      final isBreak =
          record.scoringType == SimaiGameplayScoringType.breakNote;
      final double weight = switch (record.scoringType) {
        SimaiGameplayScoringType.tap || SimaiGameplayScoringType.touch => 1.0,
        SimaiGameplayScoringType.hold => 2.0,
        SimaiGameplayScoringType.slide => 3.0,
        SimaiGameplayScoringType.breakNote => 5.0,
      };
      totalBaseWeight += weight;

      final double baseRatio = _baseScoreRatio(
        record.grade,
        record.band,
        isBreak: isBreak,
      );
      final double earnedBase = weight * baseRatio;
      final double lostBase = weight * (1.0 - baseRatio);

      double earnedBreak = 0.0;
      double lostBreak = 0.0;
      if (isBreak) {
        totalBreakCount++;
        final breakRatio = _breakBonusRatio(record.grade, record.band);
        earnedBreak = breakRatio;
        lostBreak = 1.0 - breakRatio;
      }

      final int earnedDx = _dxScoreForGrade(record.grade);
      final int lostDx = 3 - earnedDx;
      if (record.grade == SimaiJudgeGrade.miss) {
        currentCombo = 0;
      } else {
        currentCombo++;
      }

      earnedBasePrefix.add(earnedBasePrefix.last + earnedBase);
      lostBasePrefix.add(lostBasePrefix.last + lostBase);
      earnedBreakPrefix.add(earnedBreakPrefix.last + earnedBreak);
      lostBreakPrefix.add(lostBreakPrefix.last + lostBreak);
      earnedDxPrefix.add(earnedDxPrefix.last + earnedDx);
      lostDxPrefix.add(lostDxPrefix.last + lostDx);
      comboPrefix.add(currentCombo);
    }

    return SimaiAutoPlayTimeline._(
      mode: mode,
      seed: seed,
      events: List.unmodifiable(records),
      eventTimes: List.unmodifiable(eventTimes),
      earnedBasePrefix: List.unmodifiable(earnedBasePrefix),
      lostBasePrefix: List.unmodifiable(lostBasePrefix),
      earnedBreakPrefix: List.unmodifiable(earnedBreakPrefix),
      lostBreakPrefix: List.unmodifiable(lostBreakPrefix),
      earnedDxPrefix: List.unmodifiable(earnedDxPrefix),
      lostDxPrefix: List.unmodifiable(lostDxPrefix),
      comboPrefix: List.unmodifiable(comboPrefix),
      headGrades: headGrades,
      totalBaseWeight: totalBaseWeight,
      totalBreakCount: totalBreakCount,
      criticalPerfectCount: criticalPerfectCount,
      perfectCount: perfectCount,
      greatCount: greatCount,
      goodCount: goodCount,
      missCount: missCount,
      fastCount: fastCount,
      lateCount: lateCount,
    );
  }

  static double _nonNegativeFinite(double? value) {
    if (value == null || !value.isFinite || value <= 0) return 0.0;
    return value;
  }

  /// 确定性整数混洗哈希，返回 `[0.0, 1.0)` 均匀分布伪随机数。
  static double _deterministicUnit(
    int cIdx,
    int nIdx,
    int sIdx,
    int salt,
    int seed,
  ) {
    var h = (cIdx * 0x9E3779B1) ^
        ((nIdx + 1) * 0x85EBCA77) ^
        ((sIdx + 7) * 0xC2B2AE3D) ^
        (salt * 0x27D4EB2F) ^
        (seed * 0x165667B1);
    h = ((h ^ (h >>> 16)) * 0x45D9F3B) & 0x7FFFFFFF;
    h = ((h ^ (h >>> 16)) * 0x45D9F3B) & 0x7FFFFFFF;
    h = (h ^ (h >>> 16)) & 0x7FFFFFFF;
    return h / 0x80000000;
  }

  static SimaiJudgeTiming _deterministicFastLate(
    int cIdx,
    int nIdx,
    int sIdx,
    int seed,
  ) {
    return _deterministicUnit(cIdx, nIdx, sIdx, 97, seed) < 0.5
        ? SimaiJudgeTiming.fast
        : SimaiJudgeTiming.late;
  }

  static _SimulatedNoteOutcome _simulateOutcome({
    required SimaiAutoPlayMode mode,
    required int seed,
    required bool isBreak,
    required int collectionIndex,
    required int noteIndex,
    required int slidePathIndex,
  }) {
    final u = _deterministicUnit(
      collectionIndex,
      noteIndex,
      slidePathIndex,
      13,
      seed,
    );
    final sub = _deterministicUnit(
      collectionIndex,
      noteIndex,
      slidePathIndex,
      41,
      seed,
    );

    switch (mode) {
      case SimaiAutoPlayMode.allCriticalPerfect:
        return const _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.criticalPerfect,
          band: SimaiJudgeBand.criticalPerfect,
          timing: SimaiJudgeTiming.none,
        );
      case SimaiAutoPlayMode.allPerfect:
        return _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.perfect,
          band: isBreak && sub >= 0.65
              ? SimaiJudgeBand.perfect2
              : SimaiJudgeBand.perfect1,
          timing: _deterministicFastLate(
            collectionIndex,
            noteIndex,
            slidePathIndex,
            seed,
          ),
        );
      case SimaiAutoPlayMode.randomPerfect:
        if (u < 0.65) {
          return const _SimulatedNoteOutcome(
            grade: SimaiJudgeGrade.criticalPerfect,
            band: SimaiJudgeBand.criticalPerfect,
            timing: SimaiJudgeTiming.none,
          );
        }
        return _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.perfect,
          band: isBreak && sub >= 0.6
              ? SimaiJudgeBand.perfect2
              : SimaiJudgeBand.perfect1,
          timing: _deterministicFastLate(
            collectionIndex,
            noteIndex,
            slidePathIndex,
            seed,
          ),
        );
      case SimaiAutoPlayMode.breakRandomPerfect:
        if (!isBreak || u < 0.45) {
          return const _SimulatedNoteOutcome(
            grade: SimaiJudgeGrade.criticalPerfect,
            band: SimaiJudgeBand.criticalPerfect,
            timing: SimaiJudgeTiming.none,
          );
        }
        return _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.perfect,
          band: u < 0.78 ? SimaiJudgeBand.perfect1 : SimaiJudgeBand.perfect2,
          timing: _deterministicFastLate(
            collectionIndex,
            noteIndex,
            slidePathIndex,
            seed,
          ),
        );
      case SimaiAutoPlayMode.allRandom:
        if (u < 0.36) {
          return const _SimulatedNoteOutcome(
            grade: SimaiJudgeGrade.criticalPerfect,
            band: SimaiJudgeBand.criticalPerfect,
            timing: SimaiJudgeTiming.none,
          );
        }
        if (u < 0.58) {
          return _SimulatedNoteOutcome(
            grade: SimaiJudgeGrade.perfect,
            band: sub < 0.6
                ? SimaiJudgeBand.perfect1
                : SimaiJudgeBand.perfect2,
            timing: _deterministicFastLate(
              collectionIndex,
              noteIndex,
              slidePathIndex,
              seed,
            ),
          );
        }
        if (u < 0.78) {
          final band = sub < 0.45
              ? SimaiJudgeBand.great1
              : (sub < 0.78 ? SimaiJudgeBand.great2 : SimaiJudgeBand.great3);
          return _SimulatedNoteOutcome(
            grade: SimaiJudgeGrade.great,
            band: band,
            timing: _deterministicFastLate(
              collectionIndex,
              noteIndex,
              slidePathIndex,
              seed,
            ),
          );
        }
        if (u < 0.90) {
          return _SimulatedNoteOutcome(
            grade: SimaiJudgeGrade.good,
            band: SimaiJudgeBand.good,
            timing: _deterministicFastLate(
              collectionIndex,
              noteIndex,
              slidePathIndex,
              seed,
            ),
          );
        }
        return const _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.miss,
          band: SimaiJudgeBand.miss,
          timing: SimaiJudgeTiming.none,
        );
      case SimaiAutoPlayMode.allGreat:
        final band = isBreak
            ? (sub < 0.45
                  ? SimaiJudgeBand.great1
                  : (sub < 0.78
                        ? SimaiJudgeBand.great2
                        : SimaiJudgeBand.great3))
            : SimaiJudgeBand.great1;
        return _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.great,
          band: band,
          timing: _deterministicFastLate(
            collectionIndex,
            noteIndex,
            slidePathIndex,
            seed,
          ),
        );
      case SimaiAutoPlayMode.allGood:
        return _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.good,
          band: SimaiJudgeBand.good,
          timing: _deterministicFastLate(
            collectionIndex,
            noteIndex,
            slidePathIndex,
            seed,
          ),
        );
      case SimaiAutoPlayMode.allMiss:
        return const _SimulatedNoteOutcome(
          grade: SimaiJudgeGrade.miss,
          band: SimaiJudgeBand.miss,
          timing: SimaiJudgeTiming.none,
        );
    }
  }

  static double _representativeOffset(_SimulatedNoteOutcome outcome) {
    final sign = switch (outcome.timing) {
      SimaiJudgeTiming.fast => -1.0,
      SimaiJudgeTiming.late => 1.0,
      SimaiJudgeTiming.none => 0.0,
    };
    return switch (outcome.grade) {
      SimaiJudgeGrade.criticalPerfect => 0.0,
      SimaiJudgeGrade.perfect => sign * 0.032,
      SimaiJudgeGrade.great => sign * 0.075,
      SimaiJudgeGrade.good => sign * 0.120,
      SimaiJudgeGrade.miss => 0.150,
    };
  }

  static double _baseScoreRatio(
    SimaiJudgeGrade grade,
    SimaiJudgeBand? band, {
    required bool isBreak,
  }) {
    return switch (grade) {
      SimaiJudgeGrade.criticalPerfect || SimaiJudgeGrade.perfect => 1.0,
      SimaiJudgeGrade.great => isBreak
          ? switch (band) {
              SimaiJudgeBand.great1 => 0.8,
              SimaiJudgeBand.great2 => 0.6,
              SimaiJudgeBand.great3 => 0.5,
              _ => 0.8,
            }
          : 0.8,
      SimaiJudgeGrade.good => isBreak ? 0.4 : 0.5,
      SimaiJudgeGrade.miss => 0.0,
    };
  }

  static double _breakBonusRatio(SimaiJudgeGrade grade, SimaiJudgeBand? band) {
    return switch (grade) {
      SimaiJudgeGrade.criticalPerfect => 1.0,
      SimaiJudgeGrade.perfect =>
        band == SimaiJudgeBand.perfect2 ? 0.50 : 0.75,
      SimaiJudgeGrade.great => 0.40,
      SimaiJudgeGrade.good => 0.30,
      SimaiJudgeGrade.miss => 0.0,
    };
  }

  static int _dxScoreForGrade(SimaiJudgeGrade grade) => switch (grade) {
    SimaiJudgeGrade.criticalPerfect => 3,
    SimaiJudgeGrade.perfect => 2,
    SimaiJudgeGrade.great => 1,
    SimaiJudgeGrade.good || SimaiJudgeGrade.miss => 0,
  };

  static int _upperBound(List<double> values, double target) {
    var low = 0;
    var high = values.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (values[mid] <= target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
