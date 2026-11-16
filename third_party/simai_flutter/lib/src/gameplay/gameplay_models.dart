import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../structures/location.dart';
import '../structures/note_group.dart';
import '../ui/simai_mirror.dart';
import '../ui/simai_player.dart' show SimaiBackgroundMode;

enum SimaiJudgeGrade { criticalPerfect, perfect, great, good, miss }

enum SimaiJudgeBand {
  criticalPerfect,
  perfect1,
  perfect2,
  great1,
  great2,
  great3,
  good,
  miss,
}

enum SimaiJudgeTiming { fast, none, late }

enum SimaiGameplayScoringType { tap, touch, hold, slide, breakNote }

enum SimaiGameplayInputSource { outerButton, innerA }

sealed class SimaiGameplayInputTarget {
  const SimaiGameplayInputTarget();
}

@immutable
final class SimaiGameplayOuterButtonTarget extends SimaiGameplayInputTarget {
  const SimaiGameplayOuterButtonTarget(this.lane)
    : assert(lane >= 0 && lane < 8);

  final int lane;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimaiGameplayOuterButtonTarget && lane == other.lane;

  @override
  int get hashCode => Object.hash(SimaiGameplayOuterButtonTarget, lane);
}

@immutable
final class SimaiGameplaySensorTarget extends SimaiGameplayInputTarget {
  SimaiGameplaySensorTarget(Location location)
    : assert(location.group != NoteGroup.tap),
      location = Location(location.index, location.group);

  final Location location;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimaiGameplaySensorTarget && location == other.location;

  @override
  int get hashCode => Object.hash(SimaiGameplaySensorTarget, location);
}

@immutable
class SimaiGameplayLaneInput {
  const SimaiGameplayLaneInput({required this.lane, required this.source});

  final int lane;
  final SimaiGameplayInputSource source;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimaiGameplayLaneInput &&
          lane == other.lane &&
          source == other.source;

  @override
  int get hashCode => Object.hash(lane, source);
}

enum SimaiGameplayClearType {
  failed,
  clear,
  fullCombo,
  fullComboPlus,
  allPerfect,
  allPerfectPlus,
}

enum SimaiJudgementDisplayMode {
  oneA(1, 'A'),
  oneB(1, 'B'),
  oneC(1, 'C'),
  oneD(1, 'D'),
  oneE(1, 'E'),
  twoA(2, 'A'),
  twoB(2, 'B'),
  twoC(2, 'C'),
  twoD(2, 'D'),
  twoE(2, 'E'),
  threeA(3, 'A'),
  threeB(3, 'B'),
  threeC(3, 'C'),
  threeD(3, 'D');

  const SimaiJudgementDisplayMode(this.category, this.variant);

  final int category;
  final String variant;

  String get label => '$category-$variant';

  String get description {
    final precision = category == 1
        ? '所有 Perfect 合并显示'
        : '区分 Critical Perfect 与 Perfect';
    final timingScope = category == 3
        ? 'Perfect、Great、Good 可显示 Fast/Late'
        : 'Great、Good 可显示 Fast/Late';
    final variantRule = switch (variant) {
      'A' => '隐藏 Fast/Late',
      'B' => 'Fast/Late 与判定同色分行显示',
      'C' => '用蓝/红色表示 Fast/Late',
      'D' => '仅显示 Fast/Late',
      'E' => '同 B，Break Perfect 也显示 Fast/Late',
      _ => '',
    };
    return '$precision；$timingScope；$variantRule';
  }
}

enum SimaiGameplayCenterDisplayMode {
  achievementAdd('达成率 0%+'),
  achievement101Subtract('达成率 101%-'),
  achievement100Subtract('达成率 100%-'),
  combo('Combo'),
  dxScoreAdd('DX 分数 0+'),
  dxScoreSubtract('DX 分数 max-');

  const SimaiGameplayCenterDisplayMode(this.label);

  final String label;
}

@immutable
class SimaiGameplaySettings {
  const SimaiGameplaySettings({
    this.noteSpeed = 8.0,
    this.musicOffsetMs = 0,
    this.judgementOffsetMs = 0,
    this.musicVolume = 0.8,
    this.hitSoundVolume = 0.72,
    this.hitSoundEnabled = true,
    this.mirrorMode = SimaiMirrorMode.none,
    this.backgroundMode = SimaiBackgroundMode.judgeZone,
    this.judgementDisplayMode = SimaiJudgementDisplayMode.twoB,
    this.centerDisplayMode = SimaiGameplayCenterDisplayMode.achievementAdd,
    this.showApproachLine = true,
    this.showHitEffects = true,
    this.showInputPartitions = false,
    this.showTouchIndicators = true,
  });

  final double noteSpeed;
  final int musicOffsetMs;
  final int judgementOffsetMs;
  final double musicVolume;
  final double hitSoundVolume;
  final bool hitSoundEnabled;
  final SimaiMirrorMode mirrorMode;
  final SimaiBackgroundMode backgroundMode;
  final SimaiJudgementDisplayMode judgementDisplayMode;
  final SimaiGameplayCenterDisplayMode centerDisplayMode;
  final bool showApproachLine;
  final bool showHitEffects;
  final bool showInputPartitions;
  final bool showTouchIndicators;

  double get approachTime {
    final safeSpeed = noteSpeed.isFinite ? noteSpeed : 8.0;
    return 3.6 / safeSpeed.clamp(3.0, 9.0).toDouble();
  }

  SimaiGameplaySettings normalized() {
    final safeSpeed = noteSpeed.isFinite ? noteSpeed : 8.0;
    final speed = ((safeSpeed.clamp(3.0, 9.0) / 0.25).round() * 0.25)
        .toDouble();
    return copyWith(
      noteSpeed: speed,
      musicOffsetMs: musicOffsetMs.clamp(-2000, 2000),
      judgementOffsetMs: judgementOffsetMs.clamp(-200, 200),
      musicVolume: (musicVolume.isFinite ? musicVolume : 0.8)
          .clamp(0.0, 1.0)
          .toDouble(),
      hitSoundVolume: (hitSoundVolume.isFinite ? hitSoundVolume : 0.72)
          .clamp(0.0, 1.0)
          .toDouble(),
    );
  }

  SimaiGameplaySettings copyWith({
    double? noteSpeed,
    int? musicOffsetMs,
    int? judgementOffsetMs,
    double? musicVolume,
    double? hitSoundVolume,
    bool? hitSoundEnabled,
    SimaiMirrorMode? mirrorMode,
    SimaiBackgroundMode? backgroundMode,
    SimaiJudgementDisplayMode? judgementDisplayMode,
    SimaiGameplayCenterDisplayMode? centerDisplayMode,
    bool? showApproachLine,
    bool? showHitEffects,
    bool? showInputPartitions,
    bool? showTouchIndicators,
  }) {
    return SimaiGameplaySettings(
      noteSpeed: noteSpeed ?? this.noteSpeed,
      musicOffsetMs: musicOffsetMs ?? this.musicOffsetMs,
      judgementOffsetMs: judgementOffsetMs ?? this.judgementOffsetMs,
      musicVolume: musicVolume ?? this.musicVolume,
      hitSoundVolume: hitSoundVolume ?? this.hitSoundVolume,
      hitSoundEnabled: hitSoundEnabled ?? this.hitSoundEnabled,
      mirrorMode: mirrorMode ?? this.mirrorMode,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      judgementDisplayMode: judgementDisplayMode ?? this.judgementDisplayMode,
      centerDisplayMode: centerDisplayMode ?? this.centerDisplayMode,
      showApproachLine: showApproachLine ?? this.showApproachLine,
      showHitEffects: showHitEffects ?? this.showHitEffects,
      showInputPartitions: showInputPartitions ?? this.showInputPartitions,
      showTouchIndicators: showTouchIndicators ?? this.showTouchIndicators,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimaiGameplaySettings &&
          noteSpeed == other.noteSpeed &&
          musicOffsetMs == other.musicOffsetMs &&
          judgementOffsetMs == other.judgementOffsetMs &&
          musicVolume == other.musicVolume &&
          hitSoundVolume == other.hitSoundVolume &&
          hitSoundEnabled == other.hitSoundEnabled &&
          mirrorMode == other.mirrorMode &&
          backgroundMode == other.backgroundMode &&
          judgementDisplayMode == other.judgementDisplayMode &&
          centerDisplayMode == other.centerDisplayMode &&
          showApproachLine == other.showApproachLine &&
          showHitEffects == other.showHitEffects &&
          showInputPartitions == other.showInputPartitions &&
          showTouchIndicators == other.showTouchIndicators;

  @override
  int get hashCode => Object.hash(
    noteSpeed,
    musicOffsetMs,
    judgementOffsetMs,
    musicVolume,
    hitSoundVolume,
    hitSoundEnabled,
    mirrorMode,
    backgroundMode,
    judgementDisplayMode,
    centerDisplayMode,
    showApproachLine,
    showHitEffects,
    showInputPartitions,
    showTouchIndicators,
  );
}

@immutable
class SimaiJudgementRecord {
  const SimaiJudgementRecord({
    required this.collectionIndex,
    required this.noteIndex,
    required this.slidePathIndex,
    required this.targetTime,
    required this.judgedTime,
    required this.offsetSeconds,
    required this.grade,
    required this.band,
    required this.timing,
    required this.scoringType,
    required this.isAuto,
    this.holdAdjusted = false,
    this.isGroupAssisted = false,
  });

  final int collectionIndex;
  final int noteIndex;
  final int? slidePathIndex;
  final double targetTime;
  final double judgedTime;
  final double offsetSeconds;
  final SimaiJudgeGrade grade;
  final SimaiJudgeBand? band;
  final SimaiJudgeTiming timing;
  final SimaiGameplayScoringType scoringType;
  final bool isAuto;
  final bool holdAdjusted;
  final bool isGroupAssisted;

  bool get isMiss => grade == SimaiJudgeGrade.miss;
}

@immutable
class SimaiGameplayResult {
  const SimaiGameplayResult({
    required this.settings,
    required this.judgements,
    required this.achievement,
    required this.dxScore,
    required this.totalDxScore,
    required this.maxCombo,
    required this.fastCount,
    required this.lateCount,
    required this.averageManualOffsetMs,
    required this.autoAssistCount,
    required this.clearType,
    required this.gradeCounts,
    required this.typeCounts,
  });

  final SimaiGameplaySettings settings;
  final List<SimaiJudgementRecord> judgements;
  final double achievement;
  final int dxScore;
  final int totalDxScore;
  final int maxCombo;
  final int fastCount;
  final int lateCount;
  final double averageManualOffsetMs;
  final int autoAssistCount;
  final SimaiGameplayClearType clearType;
  final Map<SimaiJudgeGrade, int> gradeCounts;
  final Map<SimaiGameplayScoringType, int> typeCounts;

  int get totalNoteCount => judgements.length;
  bool get isAutoAssisted => autoAssistCount > 0;
  int get touchGroupAssistCount =>
      judgements.where((record) => record.isGroupAssisted).length;

  int countForGrade(SimaiJudgeGrade grade) => gradeCounts[grade] ?? 0;

  int countForType(SimaiGameplayScoringType type) => typeCounts[type] ?? 0;
}

class SimaiGameplayChartSummary {
  const SimaiGameplayChartSummary({
    required this.totalScoringNotes,
    required this.manualNotes,
    required this.autoAssistNotes,
    required this.excludedNotes,
  });

  final int totalScoringNotes;
  final int manualNotes;
  final int autoAssistNotes;
  final int excludedNotes;
}

class SimaiTapJudgement {
  const SimaiTapJudgement({
    required this.grade,
    required this.band,
    required this.timing,
    required this.offsetSeconds,
  });

  final SimaiJudgeGrade grade;
  final SimaiJudgeBand band;
  final SimaiJudgeTiming timing;
  final double offsetSeconds;
}

class SimaiTapJudgementRules {
  static const double frameSeconds = 1 / 60;
  static const double maximumWindowSeconds = 9 * frameSeconds;

  const SimaiTapJudgementRules._();

  static SimaiTapJudgement? judge(double offsetSeconds, {bool isEx = false}) {
    if (!offsetSeconds.isFinite) return null;
    final absolute = offsetSeconds.abs();
    const epsilon = 1e-9;
    if (absolute > maximumWindowSeconds + epsilon) return null;

    if (isEx) {
      return SimaiTapJudgement(
        grade: SimaiJudgeGrade.criticalPerfect,
        band: SimaiJudgeBand.criticalPerfect,
        timing: SimaiJudgeTiming.none,
        offsetSeconds: offsetSeconds,
      );
    }

    final timing = offsetSeconds < -epsilon
        ? SimaiJudgeTiming.fast
        : offsetSeconds > epsilon
        ? SimaiJudgeTiming.late
        : SimaiJudgeTiming.none;

    if (absolute <= frameSeconds + epsilon) {
      return SimaiTapJudgement(
        grade: SimaiJudgeGrade.criticalPerfect,
        band: SimaiJudgeBand.criticalPerfect,
        timing: SimaiJudgeTiming.none,
        offsetSeconds: offsetSeconds,
      );
    }

    final frame = (absolute / frameSeconds - epsilon).ceil();
    final (grade, band) = switch (frame) {
      2 => (SimaiJudgeGrade.perfect, SimaiJudgeBand.perfect1),
      3 => (SimaiJudgeGrade.perfect, SimaiJudgeBand.perfect2),
      4 => (SimaiJudgeGrade.great, SimaiJudgeBand.great1),
      5 => (SimaiJudgeGrade.great, SimaiJudgeBand.great2),
      6 => (SimaiJudgeGrade.great, SimaiJudgeBand.great3),
      _ => (SimaiJudgeGrade.good, SimaiJudgeBand.good),
    };
    return SimaiTapJudgement(
      grade: grade,
      band: band,
      timing: timing,
      offsetSeconds: offsetSeconds,
    );
  }
}

class SimaiTouchJudgementRules {
  static const double earlyWindowSeconds =
      9 * SimaiTapJudgementRules.frameSeconds;
  static const double maximumLateWindowSeconds =
      18 * SimaiTapJudgementRules.frameSeconds;

  const SimaiTouchJudgementRules._();

  static SimaiTapJudgement? judge(double offsetSeconds) {
    if (!offsetSeconds.isFinite) return null;
    const epsilon = 1e-9;
    if (offsetSeconds < -earlyWindowSeconds - epsilon ||
        offsetSeconds > maximumLateWindowSeconds + epsilon) {
      return null;
    }
    if (offsetSeconds <= 9 * SimaiTapJudgementRules.frameSeconds + epsilon) {
      return SimaiTapJudgement(
        grade: SimaiJudgeGrade.criticalPerfect,
        band: SimaiJudgeBand.criticalPerfect,
        timing: SimaiJudgeTiming.none,
        offsetSeconds: offsetSeconds,
      );
    }
    if (offsetSeconds <= 12 * SimaiTapJudgementRules.frameSeconds + epsilon) {
      return SimaiTapJudgement(
        grade: SimaiJudgeGrade.perfect,
        band: SimaiJudgeBand.perfect1,
        timing: SimaiJudgeTiming.late,
        offsetSeconds: offsetSeconds,
      );
    }
    if (offsetSeconds <= 15 * SimaiTapJudgementRules.frameSeconds + epsilon) {
      return SimaiTapJudgement(
        grade: SimaiJudgeGrade.great,
        band: SimaiJudgeBand.great1,
        timing: SimaiJudgeTiming.late,
        offsetSeconds: offsetSeconds,
      );
    }
    return SimaiTapJudgement(
      grade: SimaiJudgeGrade.good,
      band: SimaiJudgeBand.good,
      timing: SimaiJudgeTiming.late,
      offsetSeconds: offsetSeconds,
    );
  }
}

class SimaiSlideJudgementRules {
  static const double maximumWindowSeconds =
      36 * SimaiTapJudgementRules.frameSeconds;

  const SimaiSlideJudgementRules._();

  static SimaiTapJudgement? judge(
    double offsetSeconds, {
    required double finalZoneDwellSeconds,
  }) {
    if (!offsetSeconds.isFinite || !finalZoneDwellSeconds.isFinite) {
      return null;
    }
    const epsilon = 1e-9;
    if (offsetSeconds > maximumWindowSeconds + epsilon) return null;

    final frame = SimaiTapJudgementRules.frameSeconds;
    final extensionFrames = max(0.0, finalZoneDwellSeconds / frame) / 4.0;
    final cpFrames = min(36.0, 14.0 + extensionFrames);
    final cpSeconds = cpFrames * frame;
    if (offsetSeconds.abs() <= cpSeconds + epsilon) {
      return SimaiTapJudgement(
        grade: SimaiJudgeGrade.criticalPerfect,
        band: SimaiJudgeBand.criticalPerfect,
        timing: SimaiJudgeTiming.none,
        offsetSeconds: offsetSeconds,
      );
    }

    final timing = offsetSeconds < 0
        ? SimaiJudgeTiming.fast
        : SimaiJudgeTiming.late;
    if (offsetSeconds.abs() <= 26 * frame + epsilon) {
      return SimaiTapJudgement(
        grade: SimaiJudgeGrade.great,
        band: SimaiJudgeBand.great1,
        timing: timing,
        offsetSeconds: offsetSeconds,
      );
    }
    return SimaiTapJudgement(
      grade: SimaiJudgeGrade.good,
      band: SimaiJudgeBand.good,
      timing: timing,
      offsetSeconds: offsetSeconds,
    );
  }
}

@immutable
class SimaiGameplaySlideInteractionGroup {
  SimaiGameplaySlideInteractionGroup({
    required Iterable<Location> sensors,
    required this.visualGroupId,
    this.blocksSkip = false,
  }) : sensors = List.unmodifiable(
         sensors.map((sensor) => Location(sensor.index, sensor.group)),
       );

  final List<Location> sensors;
  final int visualGroupId;
  final bool blocksSkip;
}

@immutable
class SimaiGameplaySlideInteractionBranch {
  const SimaiGameplaySlideInteractionBranch({required this.groups});

  final List<SimaiGameplaySlideInteractionGroup> groups;
}

@immutable
class SimaiGameplaySlideInteractionStage {
  const SimaiGameplaySlideInteractionStage({
    required this.branches,
    required this.isFan,
  });

  final List<SimaiGameplaySlideInteractionBranch> branches;
  final bool isFan;
}

@immutable
class SimaiGameplaySlideData {
  const SimaiGameplaySlideData({
    required this.stages,
    required this.judgementProgress,
    required this.arrowGroupIds,
    required this.fanLeftGroupIds,
    required this.fanCenterGroupIds,
    required this.fanRightGroupIds,
  });

  final List<SimaiGameplaySlideInteractionStage> stages;
  final double judgementProgress;
  final List<int> arrowGroupIds;
  final List<int> fanLeftGroupIds;
  final List<int> fanCenterGroupIds;
  final List<int> fanRightGroupIds;
}

class SimaiGameplayEventClockMapper {
  int? _minimumOffsetUs;

  Duration map({
    required Duration eventTimestamp,
    required Duration receiptTimestamp,
  }) {
    final receiptUs = receiptTimestamp.inMicroseconds;
    final eventUs = eventTimestamp.inMicroseconds;
    if (eventUs <= 0) return receiptTimestamp;
    final observedOffset = receiptUs - eventUs;
    final previous = _minimumOffsetUs;
    if (previous == null || observedOffset < previous) {
      _minimumOffsetUs = observedOffset;
    }
    final mappedUs = eventUs + (_minimumOffsetUs ?? observedOffset);
    return Duration(microseconds: mappedUs.clamp(0, receiptUs));
  }

  void reset() => _minimumOffsetUs = null;
}

class SimaiGameplayLaneMapper {
  const SimaiGameplayLaneMapper._();

  static const double minimumRadiusRatio = 0.72;
  static const double innerAOuterRadiusRatio = 1.20;
  static const double maximumRadiusRatio = 1.35;

  static SimaiGameplayLaneInput? inputAt({
    required Offset position,
    required Offset center,
    required double radius,
    required SimaiMirrorMode mirrorMode,
    double minimumRadiusRatio = SimaiGameplayLaneMapper.minimumRadiusRatio,
    double innerAOuterRadiusRatio =
        SimaiGameplayLaneMapper.innerAOuterRadiusRatio,
    double maximumRadiusRatio = SimaiGameplayLaneMapper.maximumRadiusRatio,
  }) {
    if (!radius.isFinite || radius <= 0) return null;
    final delta = position - center;
    final radialRatio = delta.distance / radius;
    if (radialRatio < minimumRadiusRatio || radialRatio > maximumRadiusRatio) {
      return null;
    }
    final visualLane =
        (((atan2(delta.dy, delta.dx) + 67.5 * pi / 180) / (pi / 4)).round() %
                8 +
            8) %
        8;
    return SimaiGameplayLaneInput(
      lane: _mirrorTapLane(visualLane, mirrorMode),
      source: radialRatio < innerAOuterRadiusRatio
          ? SimaiGameplayInputSource.innerA
          : SimaiGameplayInputSource.outerButton,
    );
  }

  static int? laneAt({
    required Offset position,
    required Offset center,
    required double radius,
    required SimaiMirrorMode mirrorMode,
    double minimumRadiusRatio = SimaiGameplayLaneMapper.minimumRadiusRatio,
    double maximumRadiusRatio = SimaiGameplayLaneMapper.maximumRadiusRatio,
  }) {
    return inputAt(
      position: position,
      center: center,
      radius: radius,
      mirrorMode: mirrorMode,
      minimumRadiusRatio: minimumRadiusRatio,
      maximumRadiusRatio: maximumRadiusRatio,
    )?.lane;
  }

  static int _mirrorTapLane(int lane, SimaiMirrorMode mode) {
    return SimaiMirrorUtils.mirrorTapLane(lane, mode);
  }
}

class _NormalizedGameplayInputRegion {
  _NormalizedGameplayInputRegion({
    required this.visualTarget,
    required this.polygon,
  }) : bounds = _computeBounds(polygon);

  final SimaiGameplayInputTarget visualTarget;
  final List<Offset> polygon;
  final Rect bounds;

  static Rect _computeBounds(List<Offset> polygon) {
    var left = double.infinity;
    var top = double.infinity;
    var right = double.negativeInfinity;
    var bottom = double.negativeInfinity;
    for (final point in polygon) {
      left = min(left, point.dx);
      top = min(top, point.dy);
      right = max(right, point.dx);
      bottom = max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class SimaiGameplayInputMapper {
  static const double _radiusEpsilon = 1e-12;

  /// MajdataPlay's default simulated finger radius is 0.5 units against a
  /// 4.8-unit judge-line radius.
  static const double defaultContactRadiusRatio = 0.5 / 4.8;

  /// MajdataPlay enlarges the simulated mobile contact for the compact inner
  /// sensor groups. A/B keep the base finger radius.
  static const double cSensorContactRadiusBonusRatio = 0.25 / 4.8;
  static const double dSensorContactRadiusBonusRatio = 0.20 / 4.8;
  static const double eSensorContactRadiusBonusRatio = 0.10 / 4.8;

  /// MajdataPlay uses a 4.8-unit judge line and starts its simulated outer
  /// button ring past 5.4 units.
  static const double touchPanelOuterRadiusRatio = 5.4 / 4.8;

  /// Kept for source compatibility with the first gameplay input API.
  static const double innerPlayfieldRadiusRatio = touchPanelOuterRadiusRatio;

  /// A/D touch-panel sectors extend beyond the illustrated mesh to keep the
  /// enlarged playfield comfortable to touch.
  static const double sensorExtensionOuterRadiusRatio = 1.20;

  /// Kept for compatibility with the earlier D-only extension name.
  static const double dExtensionOuterRadiusRatio =
      sensorExtensionOuterRadiusRatio;

  /// Physical button sectors extend farther towards the display edge so they
  /// remain comfortable to hit with the enlarged gameplay circle.
  static const double maximumRadiusRatio = 1.35;

  static const int sensorCount = 33;
  static final List<_NormalizedGameplayInputRegion> _contactRegions =
      _buildContactRegions();

  // JudgeAreas.fbx is scaled by 0.021432761 in MajdataPlay while its imported
  // mesh hierarchy has a scale of 100. The gameplay judge line is 4.8 units.
  // Keeping the source mesh coordinates here makes the partition auditable
  // against MajdataPlay/ArtMaterials/JudgeAreas.blend.
  static const double _meshToChartRadius = 100 * 0.021432761 / 4.8;

  static const List<Offset> _aPolygon = <Offset>[
    Offset(1.430501, 0.410449),
    Offset(1.593672, 0.245906),
    Offset(2.463311, 0.363903),
    Offset(2.433419, 0.540234),
    Offset(2.313523, 0.923573),
    Offset(2.120256, 1.299280),
    Offset(2.004719, 1.478614),
    Offset(1.300943, 0.952039),
    Offset(1.300530, 0.727795),
    Offset(1.336207, 0.641237),
    Offset(1.371884, 0.554679),
    Offset(1.401192, 0.482564),
  ];

  static const List<Offset> _bPolygon = <Offset>[
    Offset(0.633842, 0.267105),
    Offset(0.877328, 0.021679),
    Offset(0.949844, 0.021679),
    Offset(1.038919, 0.021679),
    Offset(1.300919, 0.279573),
    Offset(1.213297, 0.490707),
    Offset(1.115504, 0.725222),
    Offset(1.073558, 0.725222),
    Offset(0.756555, 0.725222),
    Offset(0.633842, 0.600329),
    Offset(0.633842, 0.490707),
    Offset(0.633842, 0.376373),
  ];

  static const List<Offset> _cHalfPolygon = <Offset>[
    Offset(0.029968, -0.480311),
    Offset(0.200254, -0.480311),
    Offset(0.482047, -0.199425),
    Offset(0.482047, 0.200260),
    Offset(0.200254, 0.479532),
    Offset(0.029968, 0.479532),
  ];

  static const List<Offset> _dPolygon = <Offset>[
    Offset(1.635722, -0.197556),
    Offset(2.067223, -0.263554),
    Offset(2.475411, -0.315664),
    Offset(2.491906, 0.000249),
    Offset(2.471876, 0.320876),
    Offset(2.067223, 0.262140),
    Offset(1.635153, 0.199343),
    Offset(1.829966, 0.000122),
  ];

  static const List<Offset> _ePolygon = <Offset>[
    Offset(1.098899, 0.0),
    Offset(1.433727, -0.334828),
    Offset(1.768555, 0.0),
    Offset(1.433727, 0.334828),
  ];

  const SimaiGameplayInputMapper._();

  static SimaiGameplayInputTarget? targetAt({
    required Offset position,
    required Offset center,
    required double radius,
    required SimaiMirrorMode mirrorMode,
  }) {
    if (!radius.isFinite || radius <= 0) return null;
    final delta = position - center;
    final radialRatio = delta.distance / radius;
    if (radialRatio > maximumRadiusRatio + _radiusEpsilon) return null;
    final normalized = delta / radius;
    if (radialRatio > sensorExtensionOuterRadiusRatio + _radiusEpsilon) {
      final visualTarget = _outerRingTargetAt(normalized);
      if (visualTarget is! SimaiGameplayOuterButtonTarget) return null;
      return SimaiGameplayOuterButtonTarget(
        mirrorLocation(
          Location(visualTarget.lane, NoteGroup.tap),
          mirrorMode,
        ).index,
      );
    }
    if (radialRatio > touchPanelOuterRadiusRatio + _radiusEpsilon) {
      final visualTarget = _outerRingTargetAt(normalized);
      return switch (visualTarget) {
        SimaiGameplayOuterButtonTarget(:final lane) =>
          SimaiGameplaySensorTarget(
            mirrorLocation(Location(lane, NoteGroup.aSensor), mirrorMode),
          ),
        SimaiGameplaySensorTarget(:final location) => SimaiGameplaySensorTarget(
          mirrorLocation(location, mirrorMode),
        ),
      };
    }

    final sensor = sensorForNormalizedPoint(normalized);
    if (sensor == null) return null;
    return SimaiGameplaySensorTarget(mirrorLocation(sensor, mirrorMode));
  }

  /// Returns every input partition intersected by a circular touch contact.
  /// The returned set is deterministic and preserves visual partition order.
  static Set<SimaiGameplayInputTarget> targetsForContactCircle({
    required Offset position,
    required Offset center,
    required double radius,
    required double contactRadius,
    required SimaiMirrorMode mirrorMode,
  }) {
    if (!radius.isFinite || radius <= 0 || !contactRadius.isFinite) {
      return <SimaiGameplayInputTarget>{};
    }
    final safeContactRadius = max(0.0, contactRadius);
    if (safeContactRadius <= _radiusEpsilon) {
      final target = targetAt(
        position: position,
        center: center,
        radius: radius,
        mirrorMode: mirrorMode,
      );
      return target == null
          ? <SimaiGameplayInputTarget>{}
          : <SimaiGameplayInputTarget>{target};
    }

    final normalizedCenter = (position - center) / radius;
    final normalizedRadius = safeContactRadius / radius;
    final result = <SimaiGameplayInputTarget>{};
    for (final region in _contactRegions) {
      final regionRadius =
          normalizedRadius + _contactRadiusBonusRatio(region.visualTarget);
      final bounds = region.bounds;
      if (normalizedCenter.dx + regionRadius < bounds.left ||
          normalizedCenter.dx - regionRadius > bounds.right ||
          normalizedCenter.dy + regionRadius < bounds.top ||
          normalizedCenter.dy - regionRadius > bounds.bottom) {
        continue;
      }
      if (!_circleIntersectsPolygon(
        normalizedCenter,
        regionRadius,
        region.polygon,
      )) {
        continue;
      }
      result.add(_mirrorTarget(region.visualTarget, mirrorMode));
    }
    return result;
  }

  static double _contactRadiusBonusRatio(SimaiGameplayInputTarget target) =>
      switch (target) {
        SimaiGameplaySensorTarget(:final location) => switch (location.group) {
          NoteGroup.cSensor => cSensorContactRadiusBonusRatio,
          NoteGroup.dSensor => dSensorContactRadiusBonusRatio,
          NoteGroup.eSensor => eSensorContactRadiusBonusRatio,
          NoteGroup.aSensor || NoteGroup.bSensor || NoteGroup.tap => 0.0,
        },
        SimaiGameplayOuterButtonTarget() => 0.0,
      };

  static SimaiGameplayInputTarget _outerRingTargetAt(Offset point) {
    final angle = atan2(point.dy, point.dx);
    final dIndex = _nearestIndex(angle, firstAngleDegrees: -90.0);
    final dCenter = (-90.0 + dIndex * 45.0) * pi / 180;
    if (_angularDistance(angle, dCenter) <= 8.0 * pi / 180 + 1e-12) {
      return SimaiGameplaySensorTarget(Location(dIndex, NoteGroup.dSensor));
    }
    final buttonIndex = _nearestIndex(angle, firstAngleDegrees: -67.5);
    return SimaiGameplayOuterButtonTarget(buttonIndex);
  }

  static List<_NormalizedGameplayInputRegion> _buildContactRegions() {
    final regions = <_NormalizedGameplayInputRegion>[];
    for (final location in allSensors()) {
      for (final polygon in normalizedSensorPolygons(location)) {
        regions.add(
          _NormalizedGameplayInputRegion(
            visualTarget: SimaiGameplaySensorTarget(location),
            polygon: polygon,
          ),
        );
      }
    }

    for (var index = 0; index < 8; index++) {
      final dCenter = (-90.0 + index * 45.0) * pi / 180;
      regions.add(
        _NormalizedGameplayInputRegion(
          visualTarget: SimaiGameplaySensorTarget(
            Location(index, NoteGroup.dSensor),
          ),
          polygon: _annularSectorPolygon(
            innerRadius: touchPanelOuterRadiusRatio,
            outerRadius: sensorExtensionOuterRadiusRatio,
            startAngle: dCenter - 8.0 * pi / 180,
            sweepAngle: 16.0 * pi / 180,
          ),
        ),
      );

      final aCenter = (-67.5 + index * 45.0) * pi / 180;
      regions.add(
        _NormalizedGameplayInputRegion(
          visualTarget: SimaiGameplaySensorTarget(
            Location(index, NoteGroup.aSensor),
          ),
          polygon: _annularSectorPolygon(
            innerRadius: touchPanelOuterRadiusRatio,
            outerRadius: sensorExtensionOuterRadiusRatio,
            startAngle: aCenter - 14.5 * pi / 180,
            sweepAngle: 29.0 * pi / 180,
          ),
        ),
      );
      regions.add(
        _NormalizedGameplayInputRegion(
          visualTarget: SimaiGameplayOuterButtonTarget(index),
          polygon: _annularSectorPolygon(
            innerRadius: sensorExtensionOuterRadiusRatio,
            outerRadius: maximumRadiusRatio,
            startAngle: aCenter - 14.5 * pi / 180,
            sweepAngle: 29.0 * pi / 180,
          ),
        ),
      );
    }
    return List<_NormalizedGameplayInputRegion>.unmodifiable(regions);
  }

  static List<Offset> _annularSectorPolygon({
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
  }) {
    const segmentCount = 12;
    final points = <Offset>[];
    for (var segment = 0; segment <= segmentCount; segment++) {
      final angle = startAngle + sweepAngle * segment / segmentCount;
      points.add(Offset(outerRadius * cos(angle), outerRadius * sin(angle)));
    }
    for (var segment = segmentCount; segment >= 0; segment--) {
      final angle = startAngle + sweepAngle * segment / segmentCount;
      points.add(Offset(innerRadius * cos(angle), innerRadius * sin(angle)));
    }
    return List<Offset>.unmodifiable(points);
  }

  static SimaiGameplayInputTarget _mirrorTarget(
    SimaiGameplayInputTarget target,
    SimaiMirrorMode mirrorMode,
  ) => switch (target) {
    SimaiGameplayOuterButtonTarget(:final lane) =>
      SimaiGameplayOuterButtonTarget(
        mirrorLocation(Location(lane, NoteGroup.tap), mirrorMode).index,
      ),
    SimaiGameplaySensorTarget(:final location) => SimaiGameplaySensorTarget(
      mirrorLocation(location, mirrorMode),
    ),
  };

  static bool _circleIntersectsPolygon(
    Offset circleCenter,
    double circleRadius,
    List<Offset> polygon,
  ) {
    if (_containsPolygon(polygon, circleCenter)) return true;
    final radiusSquared = circleRadius * circleRadius;
    for (var index = 0; index < polygon.length; index++) {
      final start = polygon[index];
      final end = polygon[(index + 1) % polygon.length];
      if ((start - circleCenter).distanceSquared <=
          radiusSquared + _radiusEpsilon) {
        return true;
      }
      if (_distanceSquaredToSegment(circleCenter, start, end) <=
          radiusSquared + _radiusEpsilon) {
        return true;
      }
    }
    return false;
  }

  static double _distanceSquaredToSegment(
    Offset point,
    Offset start,
    Offset end,
  ) {
    final edge = end - start;
    final lengthSquared = edge.distanceSquared;
    if (lengthSquared <= _radiusEpsilon) {
      return (point - start).distanceSquared;
    }
    final relative = point - start;
    final projection =
        (relative.dx * edge.dx + relative.dy * edge.dy) / lengthSquared;
    final clamped = projection.clamp(0.0, 1.0);
    final closest = start + edge * clamped;
    return (point - closest).distanceSquared;
  }

  static int _nearestIndex(double angle, {required double firstAngleDegrees}) {
    final index = ((angle - firstAngleDegrees * pi / 180) / (pi / 4)).round();
    return ((index % 8) + 8) % 8;
  }

  static double _angularDistance(double first, double second) {
    final difference = (first - second).abs() % (2 * pi);
    return min(difference, 2 * pi - difference);
  }

  static Iterable<Location> allSensors() sync* {
    for (final group in const <NoteGroup>[
      NoteGroup.aSensor,
      NoteGroup.bSensor,
    ]) {
      for (var index = 0; index < 8; index++) {
        yield Location(index, group);
      }
    }
    yield Location(0, NoteGroup.cSensor);
    for (final group in const <NoteGroup>[
      NoteGroup.dSensor,
      NoteGroup.eSensor,
    ]) {
      for (var index = 0; index < 8; index++) {
        yield Location(index, group);
      }
    }
  }

  static int sensorIndex(Location location) => switch (location.group) {
    NoteGroup.aSensor => location.index,
    NoteGroup.bSensor => 8 + location.index,
    NoteGroup.cSensor => 16,
    NoteGroup.dSensor => 17 + location.index,
    NoteGroup.eSensor => 25 + location.index,
    NoteGroup.tap => -1,
  };

  static Location sensorForIndex(int index) {
    if (index < 0 || index >= sensorCount) {
      throw RangeError.range(index, 0, sensorCount - 1, 'index');
    }
    if (index < 8) return Location(index, NoteGroup.aSensor);
    if (index < 16) return Location(index - 8, NoteGroup.bSensor);
    if (index == 16) return Location(0, NoteGroup.cSensor);
    if (index < 25) return Location(index - 17, NoteGroup.dSensor);
    return Location(index - 25, NoteGroup.eSensor);
  }

  static Offset normalizedSensorCenter(Location location) {
    if (location.group == NoteGroup.cSensor) return Offset.zero;
    final shifted =
        location.group == NoteGroup.aSensor ||
        location.group == NoteGroup.bSensor;
    final radialRatio = switch (location.group) {
      NoteGroup.aSensor => 4.0 / 4.8,
      NoteGroup.bSensor => 2.2 / 4.8,
      NoteGroup.dSensor => 4.1 / 4.8,
      NoteGroup.eSensor => 3.1 / 4.8,
      NoteGroup.cSensor => 0.0,
      NoteGroup.tap => 1.0,
    };
    final angleDegrees = (shifted ? -67.5 : -90.0) + location.index * 45.0;
    final angle = angleDegrees * pi / 180;
    return Offset(radialRatio * cos(angle), radialRatio * sin(angle));
  }

  /// Returns the exact visual polygons used by [sensorForNormalizedPoint], in
  /// chart-radius coordinates. C is represented by its two hardware halves
  /// plus the narrow logical bridge accepted by desktop pointer input.
  static List<List<Offset>> normalizedSensorPolygons(Location location) {
    List<Offset> transform(List<Offset> source, double rotation) => source
        .map((point) => _rotate(point, rotation) * _meshToChartRadius)
        .toList(growable: false);

    return switch (location.group) {
      NoteGroup.aSensor => <List<Offset>>[
        transform(_aPolygon, (location.index * 45.0 - 90.0) * pi / 180),
      ],
      NoteGroup.bSensor => <List<Offset>>[
        transform(_bPolygon, (location.index * 45.0 - 90.0) * pi / 180),
      ],
      NoteGroup.cSensor => <List<Offset>>[
        transform(_cHalfPolygon, 0),
        transform(
          _cHalfPolygon.map((point) => -point).toList(growable: false),
          0,
        ),
        transform(<Offset>[
          Offset(
            -_cHalfPolygon.first.dx,
            _cHalfPolygon.map((point) => point.dy).reduce(min),
          ),
          Offset(
            _cHalfPolygon.first.dx,
            _cHalfPolygon.map((point) => point.dy).reduce(min),
          ),
          Offset(
            _cHalfPolygon.first.dx,
            _cHalfPolygon.map((point) => point.dy).reduce(max),
          ),
          Offset(
            -_cHalfPolygon.first.dx,
            _cHalfPolygon.map((point) => point.dy).reduce(max),
          ),
        ], 0),
      ],
      NoteGroup.dSensor => <List<Offset>>[
        transform(_dPolygon, (location.index * 45.0 - 90.0) * pi / 180),
      ],
      NoteGroup.eSensor => <List<Offset>>[
        transform(_ePolygon, (location.index * 45.0 - 90.0) * pi / 180),
      ],
      NoteGroup.tap => const <List<Offset>>[],
    };
  }

  /// Returns the actual touch-panel partition containing [point]. Unlike
  /// [nearestSensorForNormalizedPoint], gaps between physical panels are not
  /// assigned to a sensor.
  static Location? sensorForNormalizedPoint(Offset point) {
    final raw = point / _meshToChartRadius;

    // C1 and C2 are distinct hardware panels but one logical Simai C sensor.
    // Fill their narrow separator so a point-like desktop pointer behaves like
    // a real touch contact instead of missing exactly at the screen centre.
    if (_containsPolygon(_cHalfPolygon, raw) ||
        _containsPolygon(_cHalfPolygon, -raw) ||
        (raw.dx.abs() <= _cHalfPolygon.first.dx &&
            raw.dy >= _cHalfPolygon.first.dy &&
            raw.dy <= _cHalfPolygon.last.dy)) {
      return Location(0, NoteGroup.cSensor);
    }

    final aIndex = _nearestIndex(
      atan2(point.dy, point.dx),
      firstAngleDegrees: -67.5,
    );
    final abRaw = _rotate(raw, (90.0 - aIndex * 45.0) * pi / 180);
    if (_containsPolygon(_aPolygon, abRaw)) {
      return Location(aIndex, NoteGroup.aSensor);
    }
    if (_containsPolygon(_bPolygon, abRaw)) {
      return Location(aIndex, NoteGroup.bSensor);
    }

    final deIndex = _nearestIndex(
      atan2(point.dy, point.dx),
      firstAngleDegrees: -90.0,
    );
    final deRaw = _rotate(raw, (90.0 - deIndex * 45.0) * pi / 180);
    if (_containsPolygon(_dPolygon, deRaw)) {
      return Location(deIndex, NoteGroup.dSensor);
    }
    if (_containsPolygon(_ePolygon, deRaw)) {
      return Location(deIndex, NoteGroup.eSensor);
    }
    return null;
  }

  static Offset _rotate(Offset point, double radians) {
    final cosine = cos(radians);
    final sine = sin(radians);
    return Offset(
      point.dx * cosine - point.dy * sine,
      point.dx * sine + point.dy * cosine,
    );
  }

  static bool _containsPolygon(List<Offset> polygon, Offset point) {
    var inside = false;
    for (
      var currentIndex = 0, previousIndex = polygon.length - 1;
      currentIndex < polygon.length;
      previousIndex = currentIndex++
    ) {
      final current = polygon[currentIndex];
      final previous = polygon[previousIndex];
      if (_isOnSegment(point, previous, current)) return true;
      final crosses =
          (current.dy > point.dy) != (previous.dy > point.dy) &&
          point.dx <
              (previous.dx - current.dx) *
                      (point.dy - current.dy) /
                      (previous.dy - current.dy) +
                  current.dx;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  static bool _isOnSegment(Offset point, Offset start, Offset end) {
    const epsilon = 1e-9;
    final edgeX = end.dx - start.dx;
    final edgeY = end.dy - start.dy;
    final pointX = point.dx - start.dx;
    final pointY = point.dy - start.dy;
    final cross = edgeX * pointY - edgeY * pointX;
    if (cross.abs() > epsilon) return false;
    final dot = pointX * edgeX + pointY * edgeY;
    if (dot < -epsilon) return false;
    final squaredLength = edgeX * edgeX + edgeY * edgeY;
    return dot <= squaredLength + epsilon;
  }

  static Location nearestSensorForNormalizedPoint(Offset point) {
    Location? nearest;
    var nearestDistanceSquared = double.infinity;
    for (final sensor in allSensors()) {
      final center = normalizedSensorCenter(sensor);
      final dx = point.dx - center.dx;
      final dy = point.dy - center.dy;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared < nearestDistanceSquared - 1e-12) {
        nearest = sensor;
        nearestDistanceSquared = distanceSquared;
      }
    }
    return nearest!;
  }

  static Location mirrorLocation(Location location, SimaiMirrorMode mode) {
    return SimaiMirrorUtils.mirrorLocation(location, mode);
  }
}
