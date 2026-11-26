import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../structures/location.dart';
import '../structures/note_group.dart';
import '../ui/note_motion.dart';
import '../ui/note_style.dart';
import '../ui/simai_game.dart' show simaiMaxHitSoundVolume;
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

/// 谱面游玩时的盘面中央显示模式（与预览态 11 种模式一一对应）。
enum SimaiGameplayCenterDisplayMode {
  achievementAdd('0%+'),
  achievement100Plus('100%+'),
  achievement101Subtract('101%-'),
  dxScoreAdd('DX分数+'),
  dxScoreSubtract('DX分数-'),
  dxStars('星数+x'),
  combo('连击数'),
  overS('超过S级'),
  overSS('超过SS级'),
  overSSS('超过SSS级'),
  none('什么都不显示');

  const SimaiGameplayCenterDisplayMode(this.label);

  /// 界面选择器展示的中文名称。
  final String label;

  /// 解析枚举名称并兼容历史旧键（`achievement` 与 `achievement100Subtract`）。
  static SimaiGameplayCenterDisplayMode fromNameOrLegacy(
    Object? raw, {
    SimaiGameplayCenterDisplayMode fallback =
        SimaiGameplayCenterDisplayMode.achievementAdd,
  }) {
    if (raw is SimaiGameplayCenterDisplayMode) return raw;
    if (raw is String) {
      if (raw == 'achievement') {
        return SimaiGameplayCenterDisplayMode.achievementAdd;
      }
      if (raw == 'achievement100Subtract') {
        return SimaiGameplayCenterDisplayMode.achievement100Plus;
      }
      for (final value in values) {
        if (value.name == raw) return value;
      }
    } else if (raw is int && raw >= 0 && raw < values.length) {
      return values[raw];
    }
    return fallback;
  }
}

@immutable
class SimaiGameplaySettings {
  const SimaiGameplaySettings({
    this.noteSpeed = 8.0,
    this.musicOffsetMs = 0,
    this.judgementOffsetMs = 0,
    this.musicVolume = 0.8,
    this.hitSoundVolume = 0.72,
    this.answerSoundEnabled = true,
    this.hitSoundEnabled = false,
    this.contactRadiusScale = 1.0,
    this.chartScale = 0.86,
    this.backgroundOpacity = 0.35,
    this.mirrorMode = SimaiMirrorMode.none,
    this.backgroundMode = SimaiBackgroundMode.judgeZone,
    this.judgementDisplayMode = SimaiJudgementDisplayMode.twoB,
    this.centerDisplayMode = SimaiGameplayCenterDisplayMode.achievementAdd,
    this.topRightDisplayMode = SimaiGameplayCenterDisplayMode.none,
    this.noteStyle = SimaiNoteStyle.arcade,
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

  /// 是否开启预调度正解音（与 BGM 同流混音，零相对延迟）。
  final bool answerSoundEnabled;

  /// 是否开启反应式打击音（命中时即时发声，移动端受音频输出缓冲延迟影响）。
  final bool hitSoundEnabled;

  /// 触摸接触圆半径缩放倍率（0.8 ~ 1.6）。
  final double contactRadiusScale;

  /// 游玩盘面半径占比（0.75 ~ 0.95）。
  final double chartScale;

  /// 曲绘/背景可见不透明度（0.0 ~ 1.0）。
  final double backgroundOpacity;

  final SimaiMirrorMode mirrorMode;
  final SimaiBackgroundMode backgroundMode;
  final SimaiJudgementDisplayMode judgementDisplayMode;
  final SimaiGameplayCenterDisplayMode centerDisplayMode;
  final SimaiGameplayCenterDisplayMode topRightDisplayMode;
  final SimaiNoteStyle noteStyle;
  final bool showApproachLine;
  final bool showHitEffects;
  final bool showInputPartitions;
  final bool showTouchIndicators;

  /// 统一与预览页一致的音符流速公式。
  double get approachTime => NoteMotion.approachTimeForSpeed(noteSpeed);

  /// 统一与预览页一致的 Touch 音符出现时长。
  double get touchApproachTime =>
      approachTime * NoteMotion.touchApproachMultiplier;

  SimaiGameplaySettings normalized() {
    final safeSpeed = noteSpeed.isFinite ? noteSpeed : 8.0;
    final speed = ((safeSpeed.clamp(3.0, 9.0) / 0.25).round() * 0.25)
        .toDouble();
    return copyWith(
      noteSpeed: speed,
      musicOffsetMs: musicOffsetMs.clamp(-2000, 2000),
      judgementOffsetMs: judgementOffsetMs.clamp(-500, 500),
      musicVolume: (musicVolume.isFinite ? musicVolume : 0.8)
          .clamp(0.0, 1.0)
          .toDouble(),
      hitSoundVolume: (hitSoundVolume.isFinite ? hitSoundVolume : 0.72)
          .clamp(0.0, simaiMaxHitSoundVolume)
          .toDouble(),
      contactRadiusScale:
          (contactRadiusScale.isFinite ? contactRadiusScale : 1.0)
              .clamp(0.8, 1.6)
              .toDouble(),
      chartScale: (chartScale.isFinite ? chartScale : 0.86)
          .clamp(0.75, 0.95)
          .toDouble(),
      backgroundOpacity: (backgroundOpacity.isFinite ? backgroundOpacity : 0.35)
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
    bool? answerSoundEnabled,
    bool? hitSoundEnabled,
    double? contactRadiusScale,
    double? chartScale,
    double? backgroundOpacity,
    SimaiMirrorMode? mirrorMode,
    SimaiBackgroundMode? backgroundMode,
    SimaiJudgementDisplayMode? judgementDisplayMode,
    SimaiGameplayCenterDisplayMode? centerDisplayMode,
    SimaiGameplayCenterDisplayMode? topRightDisplayMode,
    SimaiNoteStyle? noteStyle,
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
      answerSoundEnabled: answerSoundEnabled ?? this.answerSoundEnabled,
      hitSoundEnabled: hitSoundEnabled ?? this.hitSoundEnabled,
      contactRadiusScale: contactRadiusScale ?? this.contactRadiusScale,
      chartScale: chartScale ?? this.chartScale,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      mirrorMode: mirrorMode ?? this.mirrorMode,
      backgroundMode: backgroundMode ?? this.backgroundMode,
      judgementDisplayMode: judgementDisplayMode ?? this.judgementDisplayMode,
      centerDisplayMode: centerDisplayMode ?? this.centerDisplayMode,
      topRightDisplayMode: topRightDisplayMode ?? this.topRightDisplayMode,
      noteStyle: noteStyle ?? this.noteStyle,
      showApproachLine: showApproachLine ?? this.showApproachLine,
      showHitEffects: showHitEffects ?? this.showHitEffects,
      showInputPartitions: showInputPartitions ?? this.showInputPartitions,
      showTouchIndicators: showTouchIndicators ?? this.showTouchIndicators,
    );
  }

  Map<String, dynamic> toJson() {
    final safe = normalized();
    return <String, dynamic>{
      'noteSpeed': safe.noteSpeed,
      'musicOffsetMs': safe.musicOffsetMs,
      'judgementOffsetMs': safe.judgementOffsetMs,
      'musicVolume': safe.musicVolume,
      'hitSoundVolume': safe.hitSoundVolume,
      'answerSoundEnabled': safe.answerSoundEnabled,
      'hitSoundEnabled': safe.hitSoundEnabled,
      'contactRadiusScale': safe.contactRadiusScale,
      'chartScale': safe.chartScale,
      'backgroundOpacity': safe.backgroundOpacity,
      'mirrorMode': safe.mirrorMode.name,
      'backgroundMode': safe.backgroundMode.name,
      'judgementDisplayMode': safe.judgementDisplayMode.name,
      'centerDisplayMode': safe.centerDisplayMode.name,
      'topRightDisplayMode': safe.topRightDisplayMode.name,
      'noteStyle': safe.noteStyle.name,
      'showApproachLine': safe.showApproachLine,
      'showHitEffects': safe.showHitEffects,
      'showInputPartitions': safe.showInputPartitions,
      'showTouchIndicators': safe.showTouchIndicators,
    };
  }

  factory SimaiGameplaySettings.fromJson(Map<String, dynamic> json) {
    const defaults = SimaiGameplaySettings();
    return SimaiGameplaySettings(
      noteSpeed: _readDouble(json['noteSpeed'], defaults.noteSpeed),
      musicOffsetMs: _readInt(json['musicOffsetMs'], defaults.musicOffsetMs),
      judgementOffsetMs: _readInt(
        json['judgementOffsetMs'],
        defaults.judgementOffsetMs,
      ),
      musicVolume: _readDouble(json['musicVolume'], defaults.musicVolume),
      hitSoundVolume: _readDouble(
        json['hitSoundVolume'],
        defaults.hitSoundVolume,
      ),
      answerSoundEnabled: _readBool(
        json['answerSoundEnabled'],
        defaults.answerSoundEnabled,
      ),
      hitSoundEnabled: _readBool(
        json['hitSoundEnabled'],
        defaults.hitSoundEnabled,
      ),
      contactRadiusScale: _readDouble(
        json['contactRadiusScale'],
        defaults.contactRadiusScale,
      ),
      chartScale: _readDouble(json['chartScale'], defaults.chartScale),
      backgroundOpacity: _readDouble(
        json['backgroundOpacity'],
        defaults.backgroundOpacity,
      ),
      mirrorMode: _readEnum(
        json['mirrorMode'],
        SimaiMirrorMode.values,
        defaults.mirrorMode,
      ),
      backgroundMode: _readEnum(
        json['backgroundMode'],
        SimaiBackgroundMode.values,
        defaults.backgroundMode,
      ),
      judgementDisplayMode: _readEnum(
        json['judgementDisplayMode'],
        SimaiJudgementDisplayMode.values,
        defaults.judgementDisplayMode,
      ),
      centerDisplayMode: SimaiGameplayCenterDisplayMode.fromNameOrLegacy(
        json['centerDisplayMode'],
        fallback: defaults.centerDisplayMode,
      ),
      topRightDisplayMode: SimaiGameplayCenterDisplayMode.fromNameOrLegacy(
        json['topRightDisplayMode'],
        fallback: defaults.topRightDisplayMode,
      ),
      noteStyle: SimaiNoteStyle.fromName(
        json['noteStyle'],
        fallback: defaults.noteStyle,
      ),
      showApproachLine: _readBool(
        json['showApproachLine'],
        defaults.showApproachLine,
      ),
      showHitEffects: _readBool(
        json['showHitEffects'],
        defaults.showHitEffects,
      ),
      showInputPartitions: _readBool(
        json['showInputPartitions'],
        defaults.showInputPartitions,
      ),
      showTouchIndicators: _readBool(
        json['showTouchIndicators'],
        defaults.showTouchIndicators,
      ),
    ).normalized();
  }

  static double _readDouble(Object? raw, double fallback) {
    if (raw is num && raw.isFinite) return raw.toDouble();
    return fallback;
  }

  static int _readInt(Object? raw, int fallback) {
    if (raw is int) return raw;
    if (raw is num && raw.isFinite) return raw.round();
    return fallback;
  }

  static bool _readBool(Object? raw, bool fallback) {
    if (raw is bool) return raw;
    return fallback;
  }

  static T _readEnum<T extends Enum>(
    Object? raw,
    List<T> values,
    T fallback,
  ) {
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) return value;
      }
    } else if (raw is int && raw >= 0 && raw < values.length) {
      return values[raw];
    }
    return fallback;
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
          answerSoundEnabled == other.answerSoundEnabled &&
          hitSoundEnabled == other.hitSoundEnabled &&
          contactRadiusScale == other.contactRadiusScale &&
          chartScale == other.chartScale &&
          backgroundOpacity == other.backgroundOpacity &&
          mirrorMode == other.mirrorMode &&
          backgroundMode == other.backgroundMode &&
          judgementDisplayMode == other.judgementDisplayMode &&
          centerDisplayMode == other.centerDisplayMode &&
          topRightDisplayMode == other.topRightDisplayMode &&
          noteStyle == other.noteStyle &&
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
    answerSoundEnabled,
    hitSoundEnabled,
    contactRadiusScale,
    chartScale,
    backgroundOpacity,
    mirrorMode,
    backgroundMode,
    judgementDisplayMode,
    centerDisplayMode,
    topRightDisplayMode,
    noteStyle,
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

/// 将平台触控事件时间戳映射到本地单调时钟。
///
/// 采用最近 64 次校准样本的滑动窗口最小值，并在 `allowCalibration == false`
/// （如 Android `ACTION_MOVE` 重采样事件）时跳过窗口更新，避免重采样污染锚点。
class SimaiGameplayEventClockMapper {
  static const int _windowSize = 64;

  final List<int> _offsetWindow = List<int>.filled(_windowSize, 0);
  int _windowCount = 0;
  int _windowCursor = 0;
  int? _minimumOffsetUs;

  Duration map({
    required Duration eventTimestamp,
    required Duration receiptTimestamp,
    bool allowCalibration = true,
  }) {
    final receiptUs = receiptTimestamp.inMicroseconds;
    final eventUs = eventTimestamp.inMicroseconds;
    if (eventUs <= 0) return receiptTimestamp;
    final observedOffset = receiptUs - eventUs;
    if (allowCalibration) {
      final replaced = _windowCount == _windowSize
          ? _offsetWindow[_windowCursor]
          : null;
      _offsetWindow[_windowCursor] = observedOffset;
      _windowCursor = (_windowCursor + 1) % _windowSize;
      if (_windowCount < _windowSize) {
        _windowCount++;
      }
      final previousMin = _minimumOffsetUs;
      if (previousMin == null || observedOffset <= previousMin) {
        _minimumOffsetUs = observedOffset;
      } else if (replaced != null && replaced == previousMin) {
        var recomputed = _offsetWindow[0];
        for (var i = 1; i < _windowCount; i++) {
          final sample = _offsetWindow[i];
          if (sample < recomputed) recomputed = sample;
        }
        _minimumOffsetUs = recomputed;
      }
    }
    final mappedUs = eventUs + (_minimumOffsetUs ?? observedOffset);
    return Duration(microseconds: mappedUs.clamp(0, receiptUs));
  }

  void reset() {
    _windowCount = 0;
    _windowCursor = 0;
    _minimumOffsetUs = null;
  }
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

class _FastSensorPolygon {
  _FastSensorPolygon({
    required this.visualBit,
    required this.bonusRadius,
    required this.polygon,
  }) : left = _minX(polygon),
       top = _minY(polygon),
       right = _maxX(polygon),
       bottom = _maxY(polygon);

  final int visualBit;
  final double bonusRadius;
  final List<Offset> polygon;
  final double left;
  final double top;
  final double right;
  final double bottom;

  static double _minX(List<Offset> poly) {
    var value = double.infinity;
    for (final p in poly) {
      if (p.dx < value) value = p.dx;
    }
    return value;
  }

  static double _minY(List<Offset> poly) {
    var value = double.infinity;
    for (final p in poly) {
      if (p.dy < value) value = p.dy;
    }
    return value;
  }

  static double _maxX(List<Offset> poly) {
    var value = double.negativeInfinity;
    for (final p in poly) {
      if (p.dx > value) value = p.dx;
    }
    return value;
  }

  static double _maxY(List<Offset> poly) {
    var value = double.negativeInfinity;
    for (final p in poly) {
      if (p.dy > value) value = p.dy;
    }
    return value;
  }
}

class _SensorRadialLayer {
  const _SensorRadialLayer({
    required this.minRadius,
    required this.maxRadius,
    required this.maxBonus,
    required this.polygons,
  });

  final double minRadius;
  final double maxRadius;
  final double maxBonus;
  final List<_FastSensorPolygon> polygons;
}

class SimaiGameplayInputMapper {
  static const double _radiusEpsilon = 1e-12;

  /// MajdataPlay 默认模拟触点半径（相对 4.8 单位判定圈）。
  static const double defaultContactRadiusRatio = 0.5 / 4.8;

  /// 移动端内圈传感器接触半径加成；B 区增加柔和宽容以改善手机窄内环 q/p 转圈断星。
  static const double bSensorContactRadiusBonusRatio = 0.12 / 4.8;
  static const double cSensorContactRadiusBonusRatio = 0.25 / 4.8;
  static const double dSensorContactRadiusBonusRatio = 0.20 / 4.8;
  static const double eSensorContactRadiusBonusRatio = 0.10 / 4.8;

  /// 内屏触摸面板外沿半径比例（5.4 / 4.8）。
  static const double touchPanelOuterRadiusRatio = 5.4 / 4.8;

  /// 兼容旧版输入 API 的内屏半径别名。
  static const double innerPlayfieldRadiusRatio = touchPanelOuterRadiusRatio;

  /// A/D 传感器外延区域的外沿半径比例。
  static const double sensorExtensionOuterRadiusRatio = 1.20;

  /// 兼容旧版 D 外延命名。
  static const double dExtensionOuterRadiusRatio =
      sensorExtensionOuterRadiusRatio;

  /// 外圈物理按键最外沿半径比例。
  static const double maximumRadiusRatio = 1.35;

  static const int sensorCount = 33;

  /// 41-bit 输入位掩码布局：低 33 位（0..32）为内屏传感器，高 8 位（33..40）为外圈按键。
  static const int sensorBitCount = 33;
  static const int outerLaneBitOffset = 33;

  static const double _dExtensionHalfAngle = 8.0 * pi / 180;
  static const double _aAndOuterHalfAngle = 14.5 * pi / 180;

  static final List<Offset> _sensorCenters = _buildSensorCenters();
  static final List<List<int>> _mirroredBitMasks = _buildMirroredBitMasks();
  static final List<_SensorRadialLayer> _innerRadialLayers =
      _buildInnerRadialLayers();
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

  /// 将单个内屏传感器索引（0..32）编码为位掩码。
  static int sensorBit(int sensorIndex) =>
      sensorIndex >= 0 && sensorIndex < sensorBitCount ? 1 << sensorIndex : 0;

  /// 将单个外圈按键轨道（0..7）编码为位掩码。
  static int outerLaneBit(int lane) =>
      lane >= 0 && lane < 8 ? 1 << (outerLaneBitOffset + lane) : 0;

  /// 将单个 [SimaiGameplayInputTarget] 编码为 41-bit 位掩码。
  static int maskForTarget(SimaiGameplayInputTarget target) => switch (target) {
    SimaiGameplayOuterButtonTarget(:final lane) => outerLaneBit(lane),
    SimaiGameplaySensorTarget(:final location) => sensorBit(
      sensorIndex(location),
    ),
  };

  /// 将目标集合编码为 41-bit 位掩码。
  static int maskForTargets(Iterable<SimaiGameplayInputTarget> targets) {
    var mask = 0;
    for (final target in targets) {
      mask |= maskForTarget(target);
    }
    return mask;
  }

  /// 零堆分配热路径：返回接触圆覆盖的全部输入分区的 41-bit 位掩码。
  ///
  /// 低 33 位（0..32）表示内屏 A/B/C/D/E 传感器，高 8 位（33..40）表示外圈 8 个物理按键。
  /// 外圈 24 个扩展与按键扇区采用 `(r, theta)` 极坐标 O(1) 解析求交，内屏 33 个多边形
  /// 按半径分为 C / B / E / A+D 四层剪枝检测。
  static int maskForContactCircle({
    required Offset position,
    required Offset center,
    required double radius,
    required double contactRadius,
    SimaiMirrorMode mirrorMode = SimaiMirrorMode.none,
  }) {
    if (!radius.isFinite || radius <= 0 || !contactRadius.isFinite) {
      return 0;
    }
    final safeContactRadius = max(0.0, contactRadius);
    if (safeContactRadius <= _radiusEpsilon) {
      final target = targetAt(
        position: position,
        center: center,
        radius: radius,
        mirrorMode: mirrorMode,
      );
      return target == null ? 0 : maskForTarget(target);
    }

    final normalizedCenter = (position - center) / radius;
    final cx = normalizedCenter.dx;
    final cy = normalizedCenter.dy;
    final radialDist = sqrt(cx * cx + cy * cy);
    final normalizedRadius = safeContactRadius / radius;
    final mirrorBits = _mirroredBitMasks[mirrorMode.index];
    var mask = 0;

    // 1. 外圈 24 个扩展/外键环形扇区：极坐标 (r, theta) O(1) 解析求交。
    final maxOuterBonus = dSensorContactRadiusBonusRatio;
    if (radialDist + normalizedRadius + maxOuterBonus >=
            touchPanelOuterRadiusRatio - _radiusEpsilon &&
        radialDist - normalizedRadius - maxOuterBonus <=
            maximumRadiusRatio + _radiusEpsilon) {
      final angle = atan2(cy, cx);

      // D 外延环（1.125R ~ 1.20R，半角 8°）
      final dRadius = normalizedRadius + dSensorContactRadiusBonusRatio;
      if (radialDist + dRadius >= touchPanelOuterRadiusRatio - _radiusEpsilon &&
          radialDist - dRadius <=
              sensorExtensionOuterRadiusRatio + _radiusEpsilon) {
        final nearestD = _nearestIndex(angle, firstAngleDegrees: -90.0);
        if (dRadius >= touchPanelOuterRadiusRatio) {
          for (var i = 0; i < 8; i++) {
            final dCenter = (-90.0 + i * 45.0) * pi / 180;
            if (_circleIntersectsAnnularSector(
              radialDist,
              angle,
              dRadius,
              touchPanelOuterRadiusRatio,
              sensorExtensionOuterRadiusRatio,
              dCenter,
              _dExtensionHalfAngle,
            )) {
              mask |= mirrorBits[17 + i];
            }
          }
        } else {
          for (var offset = -1; offset <= 1; offset++) {
            final i = (nearestD + offset) & 7;
            final dCenter = (-90.0 + i * 45.0) * pi / 180;
            if (_circleIntersectsAnnularSector(
              radialDist,
              angle,
              dRadius,
              touchPanelOuterRadiusRatio,
              sensorExtensionOuterRadiusRatio,
              dCenter,
              _dExtensionHalfAngle,
            )) {
              mask |= mirrorBits[17 + i];
            }
          }
        }
      }

      // A 外延环（1.125R ~ 1.20R）与外圈物理按键环（1.20R ~ 1.35R），半角 14.5°
      final checkAExt =
          radialDist + normalizedRadius >=
              touchPanelOuterRadiusRatio - _radiusEpsilon &&
          radialDist - normalizedRadius <=
              sensorExtensionOuterRadiusRatio + _radiusEpsilon;
      final checkOuterBtn =
          radialDist + normalizedRadius >=
              sensorExtensionOuterRadiusRatio - _radiusEpsilon &&
          radialDist - normalizedRadius <= maximumRadiusRatio + _radiusEpsilon;
      if (checkAExt || checkOuterBtn) {
        final nearestA = _nearestIndex(angle, firstAngleDegrees: -67.5);
        if (normalizedRadius >= touchPanelOuterRadiusRatio) {
          for (var i = 0; i < 8; i++) {
            final aCenter = (-67.5 + i * 45.0) * pi / 180;
            if (checkAExt &&
                _circleIntersectsAnnularSector(
                  radialDist,
                  angle,
                  normalizedRadius,
                  touchPanelOuterRadiusRatio,
                  sensorExtensionOuterRadiusRatio,
                  aCenter,
                  _aAndOuterHalfAngle,
                )) {
              mask |= mirrorBits[i];
            }
            if (checkOuterBtn &&
                _circleIntersectsAnnularSector(
                  radialDist,
                  angle,
                  normalizedRadius,
                  sensorExtensionOuterRadiusRatio,
                  maximumRadiusRatio,
                  aCenter,
                  _aAndOuterHalfAngle,
                )) {
              mask |= mirrorBits[outerLaneBitOffset + i];
            }
          }
        } else {
          for (var offset = -1; offset <= 1; offset++) {
            final i = (nearestA + offset) & 7;
            final aCenter = (-67.5 + i * 45.0) * pi / 180;
            if (checkAExt &&
                _circleIntersectsAnnularSector(
                  radialDist,
                  angle,
                  normalizedRadius,
                  touchPanelOuterRadiusRatio,
                  sensorExtensionOuterRadiusRatio,
                  aCenter,
                  _aAndOuterHalfAngle,
                )) {
              mask |= mirrorBits[i];
            }
            if (checkOuterBtn &&
                _circleIntersectsAnnularSector(
                  radialDist,
                  angle,
                  normalizedRadius,
                  sensorExtensionOuterRadiusRatio,
                  maximumRadiusRatio,
                  aCenter,
                  _aAndOuterHalfAngle,
                )) {
              mask |= mirrorBits[outerLaneBitOffset + i];
            }
          }
        }
      }
    }

    // 2. 内屏 33 个多边形：按 C / B / E / A+D 四层半径范围剪枝。
    for (var layerIndex = 0; layerIndex < _innerRadialLayers.length; layerIndex++) {
      final layer = _innerRadialLayers[layerIndex];
      final maxReach = normalizedRadius + layer.maxBonus;
      if (radialDist + maxReach < layer.minRadius - _radiusEpsilon ||
          radialDist - maxReach > layer.maxRadius + _radiusEpsilon) {
        continue;
      }
      final polygons = layer.polygons;
      for (var i = 0; i < polygons.length; i++) {
        final region = polygons[i];
        final mappedBit = mirrorBits[region.visualBit];
        if ((mask & mappedBit) != 0) continue;
        final regionRadius = normalizedRadius + region.bonusRadius;
        if (cx + regionRadius < region.left ||
            cx - regionRadius > region.right ||
            cy + regionRadius < region.top ||
            cy - regionRadius > region.bottom) {
          continue;
        }
        if (_circleIntersectsPolygon(
          normalizedCenter,
          regionRadius,
          region.polygon,
        )) {
          mask |= mappedBit;
        }
      }
    }

    return mask;
  }

  /// 圆与环形扇区（极坐标解析）的精确相交判定。
  static bool _circleIntersectsAnnularSector(
    double r,
    double theta,
    double circleRadius,
    double innerRadius,
    double outerRadius,
    double centerAngle,
    double halfAngle,
  ) {
    if (r + circleRadius < innerRadius - _radiusEpsilon ||
        r - circleRadius > outerRadius + _radiusEpsilon) {
      return false;
    }
    final angularDiff = _angularDistance(theta, centerAngle);
    if (angularDiff <= halfAngle + _radiusEpsilon) {
      return true;
    }
    final phi = angularDiff - halfAngle;
    final u = r * cos(phi);
    final v = r * sin(phi);
    final clampedX = u < innerRadius
        ? innerRadius
        : (u > outerRadius ? outerRadius : u);
    final dx = u - clampedX;
    return dx * dx + v * v <= circleRadius * circleRadius + _radiusEpsilon;
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
        SimaiGameplaySensorTarget(:final location) => _sensorBonusForGroup(
          location.group,
        ),
        SimaiGameplayOuterButtonTarget() => 0.0,
      };

  static double _sensorBonusForGroup(NoteGroup group) => switch (group) {
    NoteGroup.bSensor => bSensorContactRadiusBonusRatio,
    NoteGroup.cSensor => cSensorContactRadiusBonusRatio,
    NoteGroup.dSensor => dSensorContactRadiusBonusRatio,
    NoteGroup.eSensor => eSensorContactRadiusBonusRatio,
    NoteGroup.aSensor || NoteGroup.tap => 0.0,
  };

  static List<Offset> _buildSensorCenters() {
    final centers = List<Offset>.filled(sensorCount, Offset.zero);
    for (var i = 0; i < sensorCount; i++) {
      final location = sensorForIndex(i);
      if (location.group == NoteGroup.cSensor) {
        centers[i] = Offset.zero;
        continue;
      }
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
      centers[i] = Offset(radialRatio * cos(angle), radialRatio * sin(angle));
    }
    return List<Offset>.unmodifiable(centers);
  }

  static List<List<int>> _buildMirroredBitMasks() {
    return List<List<int>>.unmodifiable(
      SimaiMirrorMode.values.map((mode) {
        final table = List<int>.filled(outerLaneBitOffset + 8, 0);
        for (var i = 0; i < sensorBitCount; i++) {
          final logical = mirrorLocation(sensorForIndex(i), mode);
          table[i] = 1 << sensorIndex(logical);
        }
        for (var lane = 0; lane < 8; lane++) {
          final logicalLane = SimaiMirrorUtils.mirrorTapLane(lane, mode);
          table[outerLaneBitOffset + lane] =
              1 << (outerLaneBitOffset + logicalLane);
        }
        return List<int>.unmodifiable(table);
      }),
    );
  }

  static List<_SensorRadialLayer> _buildInnerRadialLayers() {
    _SensorRadialLayer buildLayer(List<NoteGroup> groups) {
      final polygons = <_FastSensorPolygon>[];
      var minRadius = double.infinity;
      var maxRadius = 0.0;
      var maxBonus = 0.0;
      for (final group in groups) {
        final bonus = _sensorBonusForGroup(group);
        if (bonus > maxBonus) maxBonus = bonus;
        final count = group == NoteGroup.cSensor ? 1 : 8;
        for (var index = 0; index < count; index++) {
          final location = Location(index, group);
          final bit = sensorIndex(location);
          for (final polygon in normalizedSensorPolygons(location)) {
            polygons.add(
              _FastSensorPolygon(
                visualBit: bit,
                bonusRadius: bonus,
                polygon: polygon,
              ),
            );
            if (_containsPolygon(polygon, Offset.zero)) {
              minRadius = 0.0;
            }
            for (var pIndex = 0; pIndex < polygon.length; pIndex++) {
              final start = polygon[pIndex];
              final end = polygon[(pIndex + 1) % polygon.length];
              final vertexDist = start.distance;
              if (vertexDist > maxRadius) maxRadius = vertexDist;
              if (minRadius > 0.0) {
                final edgeDist = sqrt(
                  _distanceSquaredToSegment(Offset.zero, start, end),
                );
                if (edgeDist < minRadius) minRadius = edgeDist;
              }
            }
          }
        }
      }
      return _SensorRadialLayer(
        minRadius: minRadius.isFinite ? minRadius : 0.0,
        maxRadius: maxRadius,
        maxBonus: maxBonus,
        polygons: List<_FastSensorPolygon>.unmodifiable(polygons),
      );
    }

    return List<_SensorRadialLayer>.unmodifiable(<_SensorRadialLayer>[
      buildLayer(const <NoteGroup>[NoteGroup.cSensor]),
      buildLayer(const <NoteGroup>[NoteGroup.bSensor]),
      buildLayer(const <NoteGroup>[NoteGroup.eSensor]),
      buildLayer(const <NoteGroup>[NoteGroup.aSensor, NoteGroup.dSensor]),
    ]);
  }

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
    final index = sensorIndex(location);
    if (index >= 0) return _sensorCenters[index];
    final angle = (-67.5 + location.index * 45.0) * pi / 180;
    return Offset(cos(angle), sin(angle));
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
    var nearestIndex = 0;
    var nearestDistanceSquared = double.infinity;
    final px = point.dx;
    final py = point.dy;
    // 直接查预计算常量表，消除预计算阶段十几万次 cos/sin 重复调用。
    for (var i = 0; i < sensorCount; i++) {
      final center = _sensorCenters[i];
      final dx = px - center.dx;
      final dy = py - center.dy;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared < nearestDistanceSquared - 1e-12) {
        nearestIndex = i;
        nearestDistanceSquared = distanceSquared;
      }
    }
    return sensorForIndex(nearestIndex);
  }

  static Location mirrorLocation(Location location, SimaiMirrorMode mode) {
    return SimaiMirrorUtils.mirrorLocation(location, mode);
  }
}
