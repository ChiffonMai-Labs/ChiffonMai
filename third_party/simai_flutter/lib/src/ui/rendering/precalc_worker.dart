import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';
import '../../../simai_flutter.dart';
import '../painters/slide_path_generator.dart';
import '../utils/note_utils.dart';
import 'precalc_data.dart';

class PrecalcRequest {
  final MaiChart chart;
  final SimaiMirrorMode mirrorMode;

  PrecalcRequest({required this.chart, required this.mirrorMode});
}

/// 基于 [Expando] 的谱面预计算缓存，随 [MaiChart] 实例自动回收，
/// 供预览页、游玩页与再次游玩之间零重复预计算共享结果。
class PrecalcChartCache {
  const PrecalcChartCache._();

  static final Expando<Map<SimaiMirrorMode, PrecalcChartData>> _cache =
      Expando<Map<SimaiMirrorMode, PrecalcChartData>>('simai_precalc_chart');

  /// 读取指定谱面与镜像模式对应的缓存预计算结果。
  static PrecalcChartData? getCached(
    MaiChart chart,
    SimaiMirrorMode mirrorMode,
  ) => _cache[chart]?[mirrorMode];

  /// 写入指定谱面与镜像模式对应的完整预计算结果。
  static void putCached(
    MaiChart chart,
    SimaiMirrorMode mirrorMode,
    PrecalcChartData data,
  ) {
    final byMirror = _cache[chart] ??= <SimaiMirrorMode, PrecalcChartData>{};
    byMirror[mirrorMode] = data;
  }
}

PrecalcSlideData calculateSingleSlideData(
  Note note,
  SlidePath slidePath,
  SimaiMirrorMode mirrorMode,
) {
  const Offset center = Offset.zero;
  const double radius = 300.0;

  final Path p = Path();
  Location currentStart = NoteUtils.mirrorLocation(note.location, mirrorMode);

  for (final segment in slidePath.segments) {
    final mirroredVertices = segment.vertices
        .map((v) => NoteUtils.mirrorLocation(v, mirrorMode))
        .toList();
    SlidePathGenerator.generatePath(
      NoteUtils.mirrorSlideType(segment.slideType, mirrorMode),
      currentStart,
      mirroredVertices,
      center,
      radius,
      path: p,
    );
    if (mirroredVertices.isNotEmpty) currentStart = mirroredVertices.last;
  }

  final metrics = p.computeMetrics().toList();
  final bool isFan = slidePath.segments.any(
    (s) => s.slideType == SlideType.fan,
  );
  // Fan/Wi-Fi paths contain center, left and right metrics. Animation progress
  // and arrow distances both use the center line; summing all three makes the
  // disappearing trail lag far behind the stars.
  final double totalLength = isFan && metrics.length >= 3
      ? metrics.first.length
      : metrics.fold(0.0, (sum, metric) => sum + metric.length);

  final List<double> arrowDistancesList = [];
  final List<double> arrowXList = [];
  final List<double> arrowYList = [];
  final List<double> arrowAnglesList = [];

  final List<double> fanLeftXList = [];
  final List<double> fanLeftYList = [];
  final List<double> fanCenterXList = [];
  final List<double> fanCenterYList = [];
  final List<double> fanRightXList = [];
  final List<double> fanRightYList = [];

  if (isFan && metrics.length >= 3) {
    final PathMetric centerMetric = metrics[0];
    final PathMetric leftMetric = metrics[1];
    final PathMetric rightMetric = metrics[2];

    final double baseLen = centerMetric.length;
    const double fanArrowSpacing = 40.0;

    if (baseLen > 0) {
      for (double d = 0; d <= baseLen; d += fanArrowSpacing) {
        final double pRatio = d / baseLen;

        final Offset pCenter =
            centerMetric
                .getTangentForOffset(centerMetric.length * pRatio)
                ?.position ??
            Offset.zero;
        final Offset pLeft =
            leftMetric
                .getTangentForOffset(leftMetric.length * pRatio)
                ?.position ??
            Offset.zero;
        final Offset pRight =
            rightMetric
                .getTangentForOffset(rightMetric.length * pRatio)
                ?.position ??
            Offset.zero;

        arrowDistancesList.add(d); // distance relative to center line
        fanCenterXList.add(pCenter.dx);
        fanCenterYList.add(pCenter.dy);
        fanLeftXList.add(pLeft.dx);
        fanLeftYList.add(pLeft.dy);
        fanRightXList.add(pRight.dx);
        fanRightYList.add(pRight.dy);
      }
    }
  } else {
    const double arrowSpacing = 25.0;
    double currentTotalDist = 0.0;

    for (final metric in metrics) {
      final double length = metric.length;
      for (double d = 0; d < length; d += arrowSpacing) {
        final Tangent? t = metric.getTangentForOffset(d);
        if (t != null) {
          arrowDistancesList.add(currentTotalDist + d);
          arrowXList.add(t.position.dx);
          arrowYList.add(t.position.dy);
          arrowAnglesList.add(t.angle);
        }
      }
      currentTotalDist += length;
    }
  }

  // Keep lookup interpolation smooth without allocating 1000 points for every
  // short slide. Long paths receive more samples, capped to bound memory.
  var numSamples = adaptiveStarSampleCount(totalLength);
  // A ring-to-ring v slide reaches C at exactly half its travel. Include
  // that point so the lookup does not cut across the corner between samples.
  final hasCenterTurn =
      note.location.group == NoteGroup.tap &&
      slidePath.segments.every((segment) => segment.vertices.isNotEmpty) &&
      ((slidePath.segments.length == 1 &&
              slidePath.segments.single.slideType == SlideType.fold &&
              slidePath.segments.single.vertices.last.group == NoteGroup.tap) ||
          (slidePath.segments.length == 2 &&
              slidePath.segments.every(
                (segment) => segment.slideType == SlideType.straightLine,
              ) &&
              slidePath.segments.first.vertices.last.group ==
                  NoteGroup.cSensor &&
              slidePath.segments.last.vertices.last.group == NoteGroup.tap));
  if (hasCenterTurn && numSamples.isEven) {
    numSamples += numSamples < 512 ? 1 : -1;
  }
  final List<double> starXList = [];
  final List<double> starYList = [];
  final List<double> starAnglesList = [];

  final List<double> fanStarLeftXList = [];
  final List<double> fanStarLeftYList = [];
  final List<double> fanStarLeftAnglesList = [];
  final List<double> fanStarCenterXList = [];
  final List<double> fanStarCenterYList = [];
  final List<double> fanStarCenterAnglesList = [];
  final List<double> fanStarRightXList = [];
  final List<double> fanStarRightYList = [];
  final List<double> fanStarRightAnglesList = [];

  if (isFan && metrics.length >= 3) {
    final PathMetric centerMetric = metrics[0];
    final PathMetric leftMetric = metrics[1];
    final PathMetric rightMetric = metrics[2];

    for (int i = 0; i < numSamples; i++) {
      double pRatio = i / (numSamples - 1);

      final Tangent? tCenter = centerMetric.getTangentForOffset(
        centerMetric.length * pRatio,
      );
      final Tangent? tLeft = leftMetric.getTangentForOffset(
        leftMetric.length * pRatio,
      );
      final Tangent? tRight = rightMetric.getTangentForOffset(
        rightMetric.length * pRatio,
      );

      fanStarCenterXList.add(tCenter?.position.dx ?? 0.0);
      fanStarCenterYList.add(tCenter?.position.dy ?? 0.0);
      fanStarCenterAnglesList.add(tCenter?.angle ?? 0.0);

      fanStarLeftXList.add(tLeft?.position.dx ?? 0.0);
      fanStarLeftYList.add(tLeft?.position.dy ?? 0.0);
      fanStarLeftAnglesList.add(tLeft?.angle ?? 0.0);

      fanStarRightXList.add(tRight?.position.dx ?? 0.0);
      fanStarRightYList.add(tRight?.position.dy ?? 0.0);
      fanStarRightAnglesList.add(tRight?.angle ?? 0.0);
    }
  } else {
    for (int i = 0; i < numSamples; i++) {
      double pRatio = i / (numSamples - 1);
      double targetDist = totalLength * pRatio;

      Tangent? tangent;
      double accumulated = 0.0;
      for (final metric in metrics) {
        if (targetDist <= accumulated + metric.length) {
          tangent = metric.getTangentForOffset(targetDist - accumulated);
          break;
        }
        accumulated += metric.length;
      }
      // fallback to last
      if (tangent == null && metrics.isNotEmpty) {
        tangent = metrics.last.getTangentForOffset(metrics.last.length);
      }

      starXList.add(tangent?.position.dx ?? 0.0);
      starYList.add(tangent?.position.dy ?? 0.0);
      starAnglesList.add(tangent?.angle ?? 0.0);
    }
  }

  final gameplay = _compileGameplaySlideData(
    note: note,
    slidePath: slidePath,
    mirrorMode: mirrorMode,
    metrics: metrics,
    totalLength: totalLength,
    arrowX: arrowXList,
    arrowY: arrowYList,
    fanLeftX: fanLeftXList,
    fanLeftY: fanLeftYList,
    fanCenterX: fanCenterXList,
    fanCenterY: fanCenterYList,
    fanRightX: fanRightXList,
    fanRightY: fanRightYList,
    isFan: isFan,
  );

  return PrecalcSlideData(
    totalLength: totalLength,
    arrowDistances: Float32List.fromList(arrowDistancesList),
    arrowX: isFan ? null : Float32List.fromList(arrowXList),
    arrowY: isFan ? null : Float32List.fromList(arrowYList),
    arrowAngles: isFan ? null : Float32List.fromList(arrowAnglesList),
    fanLeftX: isFan ? Float32List.fromList(fanLeftXList) : null,
    fanLeftY: isFan ? Float32List.fromList(fanLeftYList) : null,
    fanCenterX: isFan ? Float32List.fromList(fanCenterXList) : null,
    fanCenterY: isFan ? Float32List.fromList(fanCenterYList) : null,
    fanRightX: isFan ? Float32List.fromList(fanRightXList) : null,
    fanRightY: isFan ? Float32List.fromList(fanRightYList) : null,
    starX: isFan ? null : Float32List.fromList(starXList),
    starY: isFan ? null : Float32List.fromList(starYList),
    starAngles: isFan ? null : Float32List.fromList(starAnglesList),
    fanStarLeftX: isFan ? Float32List.fromList(fanStarLeftXList) : null,
    fanStarLeftY: isFan ? Float32List.fromList(fanStarLeftYList) : null,
    fanStarLeftAngles: isFan
        ? Float32List.fromList(fanStarLeftAnglesList)
        : null,
    fanStarCenterX: isFan ? Float32List.fromList(fanStarCenterXList) : null,
    fanStarCenterY: isFan ? Float32List.fromList(fanStarCenterYList) : null,
    fanStarCenterAngles: isFan
        ? Float32List.fromList(fanStarCenterAnglesList)
        : null,
    fanStarRightX: isFan ? Float32List.fromList(fanStarRightXList) : null,
    fanStarRightY: isFan ? Float32List.fromList(fanStarRightYList) : null,
    fanStarRightAngles: isFan
        ? Float32List.fromList(fanStarRightAnglesList)
        : null,
    gameplay: gameplay,
  );
}

SimaiGameplaySlideData _compileGameplaySlideData({
  required Note note,
  required SlidePath slidePath,
  required SimaiMirrorMode mirrorMode,
  required List<PathMetric> metrics,
  required double totalLength,
  required List<double> arrowX,
  required List<double> arrowY,
  required List<double> fanLeftX,
  required List<double> fanLeftY,
  required List<double> fanCenterX,
  required List<double> fanCenterY,
  required List<double> fanRightX,
  required List<double> fanRightY,
  required bool isFan,
}) {
  var nextGroupId = 0;
  if (isFan && metrics.length >= 3) {
    // 组合星尾接 WiFi（w）时取 WiFi 段自身的起点轨道，而非整条星星起头的 note.location.index。
    var fanStart = note.location.index;
    for (final segment in slidePath.segments) {
      if (segment.slideType == SlideType.fan) break;
      if (segment.vertices.isNotEmpty) {
        fanStart = segment.vertices.last.index;
      }
    }
    final specs = <PathMetric>[metrics[1], metrics[0], metrics[2]];
    final branches = <SimaiGameplaySlideInteractionBranch>[];
    final mutableBranches = <List<_MutableSlideGroup>>[];
    final entryProgresses = <double>[];
    for (var branchIndex = 0; branchIndex < specs.length; branchIndex++) {
      final metric = specs[branchIndex];
      final groups = _majdataFanInteractionGroups(metric, fanStart, mirrorMode);
      for (final group in groups) {
        group.visualGroupId = nextGroupId++;
      }
      mutableBranches.add(groups);
      branches.add(
        SimaiGameplaySlideInteractionBranch(
          groups: List.unmodifiable(groups.map((group) => group.freeze())),
        ),
      );
      entryProgresses.add(
        _finalGroupEntryProgress(
          <PathMetric>[metric],
          metric.length,
          groups.last.sensors,
          mirrorMode,
        ),
      );
    }
    return SimaiGameplaySlideData(
      stages: <SimaiGameplaySlideInteractionStage>[
        SimaiGameplaySlideInteractionStage(
          branches: List.unmodifiable(branches),
          isFan: true,
        ),
      ],
      judgementProgress: entryProgresses.fold<double>(0.0, max),
      arrowGroupIds: const <int>[],
      fanLeftGroupIds: _mapPointsToGroups(
        fanLeftX,
        fanLeftY,
        mutableBranches[0],
        mirrorMode,
      ),
      fanCenterGroupIds: _mapPointsToGroups(
        fanCenterX,
        fanCenterY,
        mutableBranches[1],
        mirrorMode,
      ),
      fanRightGroupIds: _mapPointsToGroups(
        fanRightX,
        fanRightY,
        mutableBranches[2],
        mirrorMode,
      ),
    );
  }

  final groups = _buildGameplayInteractionGroups(
    note: note,
    slidePath: slidePath,
    mirrorMode: mirrorMode,
    metrics: metrics,
    totalLength: totalLength,
  );
  if (groups.isEmpty) {
    groups.add(
      _MutableSlideGroup(<Location>[
        Location(note.location.index, NoteGroup.aSensor),
      ]),
    );
  }
  for (final group in groups) {
    group.visualGroupId = nextGroupId++;
  }
  final frozen = List<SimaiGameplaySlideInteractionGroup>.unmodifiable(
    groups.map((group) => group.freeze()),
  );
  return SimaiGameplaySlideData(
    stages: <SimaiGameplaySlideInteractionStage>[
      SimaiGameplaySlideInteractionStage(
        branches: <SimaiGameplaySlideInteractionBranch>[
          SimaiGameplaySlideInteractionBranch(groups: frozen),
        ],
        isFan: false,
      ),
    ],
    judgementProgress: _finalGroupEntryProgress(
      metrics,
      totalLength,
      groups.last.sensors,
      mirrorMode,
    ),
    arrowGroupIds: _mapPointsToGroups(arrowX, arrowY, groups, mirrorMode),
    fanLeftGroupIds: const <int>[],
    fanCenterGroupIds: const <int>[],
    fanRightGroupIds: const <int>[],
  );
}

/// 生成 WiFi 扇形星单分支的固定传感器队列，避免移动端细小采样导致的漏检。
List<_MutableSlideGroup> _majdataFanInteractionGroups(
  PathMetric metric,
  int start,
  SimaiMirrorMode mirrorMode,
) {
  int lane(int delta) => (start + delta + 8) % 8;
  _MutableSlideGroup group(Location sensor) =>
      _MutableSlideGroup(<Location>[sensor]);
  _MutableSlideGroup orGroup(Location first, Location second) =>
      _MutableSlideGroup(<Location>[first, second]);

  final endpoint = metric.getTangentForOffset(metric.length)?.position;
  final logicalEnd = endpoint == null
      ? lane(4)
      : _logicalSensorAt(endpoint, mirrorMode).index;
  if (logicalEnd == lane(3)) {
    return <_MutableSlideGroup>[
      group(Location(start, NoteGroup.aSensor)),
      group(Location(lane(1), NoteGroup.bSensor)),
      group(Location(lane(2), NoteGroup.bSensor)),
      orGroup(
        Location(lane(3), NoteGroup.aSensor),
        Location(lane(4), NoteGroup.dSensor),
      ),
    ];
  }
  if (logicalEnd == lane(5)) {
    return <_MutableSlideGroup>[
      group(Location(start, NoteGroup.aSensor)),
      group(Location(lane(-1), NoteGroup.bSensor)),
      group(Location(lane(-2), NoteGroup.bSensor)),
      orGroup(
        Location(lane(5), NoteGroup.aSensor),
        Location(lane(5), NoteGroup.dSensor),
      ),
    ];
  }
  final centerEnd = lane(4);
  return <_MutableSlideGroup>[
    group(Location(start, NoteGroup.aSensor)),
    group(Location(start, NoteGroup.bSensor)),
    group(Location(0, NoteGroup.cSensor)),
    // 放宽 WiFi 中支终点至相邻两侧 D 区，使手机双指扇形横扫可稳定完成三支。
    _MutableSlideGroup(<Location>[
      Location(centerEnd, NoteGroup.aSensor),
      Location(centerEnd, NoteGroup.bSensor),
      Location(centerEnd, NoteGroup.dSensor),
      Location((centerEnd + 1) % 8, NoteGroup.dSensor),
    ]),
  ];
}

/// 构建常规/组合滑星的交互传感器队列。
///
/// 各段优先采用 Majdata 紧凑队列；某一段无法匹配标准队列时，仅对该缺失段独立回退
/// `_sampleInteractionGroups`，不连累整条组合星。组合星衔接点放行跨段连滑，
/// 但对折返顶点 `X -> Y -> X` 保留 `blocksSkip = true` 防止单事件连跳。
List<_MutableSlideGroup> _buildGameplayInteractionGroups({
  required Note note,
  required SlidePath slidePath,
  required SimaiMirrorMode mirrorMode,
  required List<PathMetric> metrics,
  required double totalLength,
}) {
  if (slidePath.segments.isEmpty) return <_MutableSlideGroup>[];
  final isCompound = slidePath.segments.length > 1;
  final result = <_MutableSlideGroup>[];
  var start = note.location;

  for (final segment in slidePath.segments) {
    if (segment.vertices.isEmpty) {
      return _sampleFallbackSlide(
        note: note,
        slidePath: slidePath,
        mirrorMode: mirrorMode,
        metrics: metrics,
        totalLength: totalLength,
        isCompound: isCompound,
      );
    }
    final end = segment.vertices.last;
    List<_MutableSlideGroup>? segmentGroups;
    if (segment.slideType == SlideType.straightLine &&
        start.group == NoteGroup.tap &&
        end.group == NoteGroup.cSensor) {
      segmentGroups = _singleSensorGroups(start.index, 1, [
        (0, NoteGroup.aSensor),
        (0, NoteGroup.bSensor),
        (0, NoteGroup.cSensor),
      ]);
    } else if (segment.slideType == SlideType.straightLine &&
        start.group == NoteGroup.cSensor &&
        end.group == NoteGroup.tap) {
      segmentGroups = _singleSensorGroups(end.index, 1, [
        (0, NoteGroup.cSensor),
        (0, NoteGroup.bSensor),
        (0, NoteGroup.aSensor),
      ]);
    } else if (start.group == NoteGroup.tap &&
        segment.vertices.every((vertex) => vertex.group == NoteGroup.tap)) {
      segmentGroups = _majdataSegmentInteractionGroups(start.index, segment);
    }

    if (segmentGroups == null || segmentGroups.isEmpty) {
      // 仅对缺失标准队列的当前段独立采样，不影响组合星其他段的紧凑队列。
      segmentGroups = _sampleSingleSegmentGroups(
        start: start,
        segment: segment,
        mirrorMode: mirrorMode,
        blockSkip: !isCompound,
      );
    }

    for (var index = 0; index < segmentGroups.length; index++) {
      final group = segmentGroups[index];
      if (result.isNotEmpty && index == 0 && _sameSensors(result.last, group)) {
        continue;
      }
      result.add(group);
    }
    start = end;
  }

  if (isCompound) {
    // 组合星整体允许跨段平滑连滑，但对折返顶点 X -> Y -> X 保留防连跳保护。
    for (var i = 0; i < result.length; i++) {
      final isReversalApex =
          i > 0 &&
          i < result.length - 1 &&
          _groupsOverlap(result[i - 1], result[i + 1]);
      result[i].blocksSkip = isReversalApex;
    }
  }
  return result;
}

List<_MutableSlideGroup> _sampleFallbackSlide({
  required Note note,
  required SlidePath slidePath,
  required SimaiMirrorMode mirrorMode,
  required List<PathMetric> metrics,
  required double totalLength,
  required bool isCompound,
}) {
  final groups = _sampleInteractionGroups(metrics, totalLength, mirrorMode);
  _applySpecialSlideRules(groups, note, slidePath, blockSkip: !isCompound);
  return groups;
}

List<_MutableSlideGroup> _sampleSingleSegmentGroups({
  required Location start,
  required SlideSegment segment,
  required SimaiMirrorMode mirrorMode,
  required bool blockSkip,
}) {
  final mirroredStart = NoteUtils.mirrorLocation(start, mirrorMode);
  final mirroredVertices = segment.vertices
      .map((v) => NoteUtils.mirrorLocation(v, mirrorMode))
      .toList(growable: false);
  final segmentPath = SlidePathGenerator.generatePath(
    NoteUtils.mirrorSlideType(segment.slideType, mirrorMode),
    mirroredStart,
    mirroredVertices,
    Offset.zero,
    300.0,
  );
  final segmentMetrics = segmentPath.computeMetrics().toList();
  final segmentLength = segmentMetrics.fold<double>(
    0.0,
    (sum, metric) => sum + metric.length,
  );
  final sampled = _sampleInteractionGroups(
    segmentMetrics,
    segmentLength,
    mirrorMode,
  );
  _applySegmentSpecialRules(
    sampled,
    start.index,
    segment,
    blockSkip: blockSkip,
  );
  return sampled;
}

void _applySegmentSpecialRules(
  List<_MutableSlideGroup> groups,
  int segmentStart,
  SlideSegment segment, {
  required bool blockSkip,
}) {
  if (segment.vertices.isEmpty) return;
  if (segment.slideType == SlideType.straightLine) {
    _markThreeLaneMiddle(
      groups,
      segmentStart,
      segment.vertices.last.index,
      includeB: true,
      blockSkip: blockSkip,
      searchStart: 0,
    );
  } else if (segment.slideType == SlideType.ringCw ||
      segment.slideType == SlideType.ringCcw) {
    _markThreeLaneMiddle(
      groups,
      segmentStart,
      segment.vertices.last.index,
      includeB: false,
      blockSkip: blockSkip,
      searchStart: 0,
    );
  } else if (segment.slideType == SlideType.edgeFold &&
      segment.vertices.length >= 2) {
    final nextSearch = _markThreeLaneMiddle(
      groups,
      segmentStart,
      segment.vertices[0].index,
      includeB: true,
      blockSkip: blockSkip,
      searchStart: 0,
    );
    _markThreeLaneMiddle(
      groups,
      segment.vertices[0].index,
      segment.vertices[1].index,
      includeB: true,
      blockSkip: blockSkip,
      searchStart: nextSearch,
    );
  }
}

List<_MutableSlideGroup>? _majdataSegmentInteractionGroups(
  int start,
  SlideSegment segment,
) {
  final end = segment.vertices.last.index;
  return switch (segment.slideType) {
    SlideType.straightLine => _majdataStraightGroups(start, end),
    SlideType.ringCw => _majdataRingGroups(start, end, 1),
    SlideType.ringCcw => _majdataRingGroups(start, end, -1),
    SlideType.fold => _majdataFoldGroups(start, end),
    SlideType.curveCw => _majdataCurveGroups(start, end, mirrored: true),
    SlideType.curveCcw => _majdataCurveGroups(start, end, mirrored: false),
    SlideType.zigZagS => _majdataZigZagGroups(start, mirrored: false),
    SlideType.zigZagZ => _majdataZigZagGroups(start, mirrored: true),
    SlideType.edgeFold =>
      segment.vertices.length < 2
          ? null
          : _majdataEdgeFoldGroups(start, segment.vertices.first.index, end),
    SlideType.edgeCurveCw => _majdataEdgeCurveGroups(
      start,
      end,
      mirrored: true,
    ),
    SlideType.edgeCurveCcw => _majdataEdgeCurveGroups(
      start,
      end,
      mirrored: false,
    ),
    SlideType.fan => null,
  };
}

List<_MutableSlideGroup>? _majdataStraightGroups(int start, int end) {
  final delta = _laneDelta(start, end);
  return switch (delta) {
    1 => <_MutableSlideGroup>[
      _relativeGroup(start, 1, [(0, NoteGroup.aSensor)], blocksSkip: true),
      _relativeGroup(start, 1, [(1, NoteGroup.aSensor)]),
    ],
    2 => <_MutableSlideGroup>[
      _relativeGroup(start, 1, [(0, NoteGroup.aSensor)]),
      _relativeGroup(start, 1, [
        (1, NoteGroup.aSensor),
        (1, NoteGroup.bSensor),
      ], blocksSkip: true),
      _relativeGroup(start, 1, [(2, NoteGroup.aSensor)]),
    ],
    3 => _singleSensorGroups(start, 1, [
      (0, NoteGroup.aSensor),
      (1, NoteGroup.bSensor),
      (2, NoteGroup.bSensor),
      (3, NoteGroup.aSensor),
    ]),
    4 => _singleSensorGroups(start, 1, [
      (0, NoteGroup.aSensor),
      (0, NoteGroup.bSensor),
      (0, NoteGroup.cSensor),
      (4, NoteGroup.bSensor),
      (4, NoteGroup.aSensor),
    ]),
    5 => _singleSensorGroups(start, 1, [
      (0, NoteGroup.aSensor),
      (-1, NoteGroup.bSensor),
      (-2, NoteGroup.bSensor),
      (5, NoteGroup.aSensor),
    ]),
    6 => <_MutableSlideGroup>[
      _relativeGroup(start, 1, [(0, NoteGroup.aSensor)]),
      _relativeGroup(start, 1, [
        (-1, NoteGroup.aSensor),
        (-1, NoteGroup.bSensor),
      ], blocksSkip: true),
      _relativeGroup(start, 1, [(-2, NoteGroup.aSensor)]),
    ],
    7 => <_MutableSlideGroup>[
      _relativeGroup(start, 1, [(0, NoteGroup.aSensor)], blocksSkip: true),
      _relativeGroup(start, 1, [(-1, NoteGroup.aSensor)]),
    ],
    _ => null,
  };
}

List<_MutableSlideGroup> _majdataRingGroups(int start, int end, int direction) {
  var steps = direction > 0 ? _laneDelta(start, end) : _laneDelta(end, start);
  if (steps == 0) steps = 8;
  return <_MutableSlideGroup>[
    for (var step = 0; step <= steps; step++)
      _relativeGroup(start, direction, [
        (step, NoteGroup.aSensor),
      ], blocksSkip: (steps == 1 && step == 0) || (steps == 2 && step == 1)),
  ];
}

List<_MutableSlideGroup> _majdataFoldGroups(int start, int end) {
  final delta = _laneDelta(start, end);
  return _singleSensorGroups(start, 1, [
    (0, NoteGroup.aSensor),
    (0, NoteGroup.bSensor),
    (0, NoteGroup.cSensor),
    (delta, NoteGroup.bSensor),
    (delta, NoteGroup.aSensor),
  ]);
}

List<_MutableSlideGroup> _majdataCurveGroups(
  int start,
  int end, {
  required bool mirrored,
}) {
  final actualDelta = _laneDelta(start, end);
  final direction = mirrored ? -1 : 1;
  final tableDelta = mirrored ? (-actualDelta) % 8 : actualDelta;
  final offsets = switch (tableDelta) {
    0 => <int>[-1, -2, -3, -4, 3, 2, 1],
    1 => <int>[-1, -2, -3, -4, 3, 2],
    2 => <int>[-1, -2, -3, -4, 3],
    3 => <int>[-1, -2, -3, -4],
    4 => <int>[-1, -2, -3],
    5 => <int>[-1, -2, -3, -4, 3, 2, 1, 0, -1, -2],
    6 => <int>[-1, -2, -3, -4, 3, 2, 1, 0, -1],
    _ => <int>[-1, -2, -3, -4, 3, 2, 1, 0],
  };
  return _singleSensorGroups(start, direction, [
    (0, NoteGroup.aSensor),
    for (final offset in offsets) (offset, NoteGroup.bSensor),
    (tableDelta, NoteGroup.aSensor),
  ]);
}

List<_MutableSlideGroup> _majdataEdgeCurveGroups(
  int start,
  int end, {
  required bool mirrored,
}) {
  final actualDelta = _laneDelta(start, end);
  final direction = mirrored ? -1 : 1;
  final tableDelta = mirrored ? (-actualDelta) % 8 : actualDelta;
  final specs = switch (tableDelta) {
    0 => <List<(int, NoteGroup)>>[
      [(0, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(3, NoteGroup.bSensor)],
      [(2, NoteGroup.aSensor)],
      [(1, NoteGroup.aSensor)],
      [(0, NoteGroup.aSensor)],
    ],
    1 => <List<(int, NoteGroup)>>[
      [(0, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(3, NoteGroup.bSensor)],
      [(2, NoteGroup.aSensor)],
      [(1, NoteGroup.aSensor)],
    ],
    2 => <List<(int, NoteGroup)>>[
      [(0, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(3, NoteGroup.bSensor)],
      [(2, NoteGroup.aSensor)],
    ],
    3 || 4 => <List<(int, NoteGroup)>>[
      [(0, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(3, NoteGroup.bSensor)],
      [(2, NoteGroup.aSensor)],
      [(1, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(tableDelta, NoteGroup.bSensor)],
      [(tableDelta, NoteGroup.aSensor)],
    ],
    5 => <List<(int, NoteGroup)>>[
      [(0, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(3, NoteGroup.bSensor)],
      [(2, NoteGroup.aSensor)],
      [(1, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor), (-1, NoteGroup.bSensor)],
      [(-2, NoteGroup.bSensor), (-3, NoteGroup.bSensor)],
      [(5, NoteGroup.aSensor)],
    ],
    6 => <List<(int, NoteGroup)>>[
      [(0, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(3, NoteGroup.bSensor)],
      [(2, NoteGroup.aSensor)],
      [(1, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(-1, NoteGroup.bSensor)],
      [(6, NoteGroup.aSensor)],
    ],
    _ => <List<(int, NoteGroup)>>[
      [(0, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor)],
      [(0, NoteGroup.cSensor)],
      [(3, NoteGroup.bSensor)],
      [(2, NoteGroup.aSensor)],
      [(1, NoteGroup.aSensor)],
      [(0, NoteGroup.bSensor), (0, NoteGroup.aSensor)],
      [(-1, NoteGroup.aSensor)],
    ],
  };
  return <_MutableSlideGroup>[
    for (final sensors in specs) _relativeGroup(start, direction, sensors),
  ];
}

List<_MutableSlideGroup> _majdataZigZagGroups(
  int start, {
  required bool mirrored,
}) {
  return _singleSensorGroups(start, mirrored ? -1 : 1, [
    (0, NoteGroup.aSensor),
    (-1, NoteGroup.bSensor),
    (-2, NoteGroup.bSensor),
    (0, NoteGroup.cSensor),
    (2, NoteGroup.bSensor),
    (3, NoteGroup.bSensor),
    (4, NoteGroup.aSensor),
  ]);
}

List<_MutableSlideGroup>? _majdataEdgeFoldGroups(int start, int turn, int end) {
  final turnDelta = _laneDelta(start, turn);
  final actualEndDelta = _laneDelta(start, end);
  final mirrored = turnDelta == 2;
  if (!mirrored && turnDelta != 6) return null;
  final direction = mirrored ? -1 : 1;
  final tableEndDelta = mirrored ? (-actualEndDelta) % 8 : actualEndDelta;

  final prefix = <_MutableSlideGroup>[
    _relativeGroup(start, direction, [(0, NoteGroup.aSensor)]),
    _relativeGroup(start, direction, [
      (-1, NoteGroup.bSensor),
      (-1, NoteGroup.aSensor),
    ], blocksSkip: true),
    _relativeGroup(start, direction, [(-2, NoteGroup.aSensor)]),
  ];
  final suffix = switch (tableEndDelta) {
    1 => <_MutableSlideGroup>[
      _relativeGroup(start, direction, [(-1, NoteGroup.bSensor)]),
      _relativeGroup(start, direction, [(0, NoteGroup.bSensor)]),
      _relativeGroup(start, direction, [(1, NoteGroup.aSensor)]),
    ],
    2 => <_MutableSlideGroup>[
      _relativeGroup(start, direction, [(-2, NoteGroup.bSensor)]),
      _relativeGroup(start, direction, [(0, NoteGroup.cSensor)]),
      _relativeGroup(start, direction, [(2, NoteGroup.bSensor)]),
      _relativeGroup(start, direction, [(2, NoteGroup.aSensor)]),
    ],
    3 => <_MutableSlideGroup>[
      _relativeGroup(start, direction, [(-3, NoteGroup.bSensor)]),
      _relativeGroup(start, direction, [(-4, NoteGroup.bSensor)]),
      _relativeGroup(start, direction, [(3, NoteGroup.aSensor)]),
    ],
    4 => <_MutableSlideGroup>[
      _relativeGroup(start, direction, [
        (-3, NoteGroup.bSensor),
        (-3, NoteGroup.aSensor),
      ], blocksSkip: true),
      _relativeGroup(start, direction, [(4, NoteGroup.aSensor)]),
    ],
    _ => null,
  };
  if (suffix == null) return null;
  return <_MutableSlideGroup>[...prefix, ...suffix];
}

List<_MutableSlideGroup> _singleSensorGroups(
  int start,
  int direction,
  List<(int, NoteGroup)> sensors,
) => <_MutableSlideGroup>[
  for (final sensor in sensors) _relativeGroup(start, direction, [sensor]),
];

_MutableSlideGroup _relativeGroup(
  int start,
  int direction,
  List<(int, NoteGroup)> sensors, {
  bool blocksSkip = false,
}) => _MutableSlideGroup(<Location>[
  for (final sensor in sensors)
    Location(
      sensor.$2 == NoteGroup.cSensor ? 0 : (start + direction * sensor.$1) % 8,
      sensor.$2,
    ),
], blocksSkip: blocksSkip);

int _laneDelta(int start, int end) => (end - start) % 8;

bool _sameSensors(_MutableSlideGroup first, _MutableSlideGroup second) {
  if (first.sensors.length != second.sensors.length) return false;
  return first.sensors.every(second.contains);
}

bool _groupsOverlap(_MutableSlideGroup first, _MutableSlideGroup second) =>
    first.sensors.any(second.contains);

List<_MutableSlideGroup> _sampleInteractionGroups(
  List<PathMetric> metrics,
  double totalLength,
  SimaiMirrorMode mirrorMode,
) {
  if (metrics.isEmpty || totalLength <= 0) return <_MutableSlideGroup>[];
  final result = <_MutableSlideGroup>[];
  const spacing = 25.0;
  for (double distance = 0; distance <= totalLength; distance += spacing) {
    final point = _pointAtDistance(metrics, min(distance, totalLength));
    if (point == null) continue;
    _appendSensor(result, _logicalSensorAt(point, mirrorMode));
  }
  final end = _pointAtDistance(metrics, totalLength);
  if (end != null) _appendSensor(result, _logicalSensorAt(end, mirrorMode));
  return result;
}

void _appendSensor(List<_MutableSlideGroup> groups, Location sensor) {
  if (groups.isNotEmpty && groups.last.contains(sensor)) return;
  groups.add(_MutableSlideGroup(<Location>[sensor]));
}

void _applySpecialSlideRules(
  List<_MutableSlideGroup> groups,
  Note note,
  SlidePath slidePath, {
  required bool blockSkip,
}) {
  if (slidePath.segments.isEmpty) return;
  var segmentStart = note.location.index;
  var searchStart = 0;
  for (final segment in slidePath.segments) {
    if (segment.vertices.isEmpty) continue;
    if (segment.slideType == SlideType.straightLine) {
      searchStart = _markThreeLaneMiddle(
        groups,
        segmentStart,
        segment.vertices.last.index,
        includeB: true,
        blockSkip: blockSkip,
        searchStart: searchStart,
      );
    } else if (segment.slideType == SlideType.ringCw ||
        segment.slideType == SlideType.ringCcw) {
      searchStart = _markThreeLaneMiddle(
        groups,
        segmentStart,
        segment.vertices.last.index,
        includeB: false,
        blockSkip: blockSkip,
        searchStart: searchStart,
      );
    } else if (segment.slideType == SlideType.edgeFold &&
        segment.vertices.length >= 2) {
      searchStart = _markThreeLaneMiddle(
        groups,
        segmentStart,
        segment.vertices[0].index,
        includeB: true,
        blockSkip: blockSkip,
        searchStart: searchStart,
      );
      searchStart = _markThreeLaneMiddle(
        groups,
        segment.vertices[0].index,
        segment.vertices[1].index,
        includeB: true,
        blockSkip: blockSkip,
        searchStart: searchStart,
      );
    }
    segmentStart = segment.vertices.last.index;
  }
}

int _markThreeLaneMiddle(
  List<_MutableSlideGroup> groups,
  int start,
  int end, {
  required bool includeB,
  required bool blockSkip,
  required int searchStart,
}) {
  final clockwise = (end - start + 8) % 8;
  final counterClockwise = (start - end + 8) % 8;
  if (min(clockwise, counterClockwise) != 2) return searchStart;
  final step = clockwise == 2 ? 1 : -1;
  final middle = (start + step + 8) % 8;
  for (var index = searchStart; index < groups.length; index++) {
    final group = groups[index];
    final hasMiddle = group.sensors.any(
      (sensor) =>
          sensor.index == middle &&
          (sensor.group == NoteGroup.aSensor ||
              sensor.group == NoteGroup.bSensor),
    );
    if (!hasMiddle) continue;
    group
      ..sensors = <Location>[
        Location(middle, NoteGroup.aSensor),
        if (includeB) Location(middle, NoteGroup.bSensor),
      ]
      ..blocksSkip = blockSkip;
    return index + 1;
  }
  return searchStart;
}

List<int> _mapPointsToGroups(
  List<double> xs,
  List<double> ys,
  List<_MutableSlideGroup> groups,
  SimaiMirrorMode mirrorMode,
) {
  if (groups.isEmpty) return List<int>.filled(xs.length, -1);
  final result = <int>[];
  var cursor = 0;
  for (var index = 0; index < min(xs.length, ys.length); index++) {
    final sensor = _logicalSensorAt(Offset(xs[index], ys[index]), mirrorMode);
    var found = -1;
    for (var groupIndex = cursor; groupIndex < groups.length; groupIndex++) {
      if (groups[groupIndex].contains(sensor)) {
        found = groupIndex;
        break;
      }
    }
    if (found < 0) {
      for (var groupIndex = 0; groupIndex < cursor; groupIndex++) {
        if (groups[groupIndex].contains(sensor)) {
          found = groupIndex;
          break;
        }
      }
    }
    if (found >= 0) cursor = max(cursor, found);
    result.add(groups[(found < 0 ? cursor : found)].visualGroupId);
  }
  return List.unmodifiable(result);
}

double _finalGroupEntryProgress(
  List<PathMetric> metrics,
  double totalLength,
  List<Location> finalSensors,
  SimaiMirrorMode mirrorMode,
) {
  if (metrics.isEmpty || totalLength <= 0 || finalSensors.isEmpty) return 1.0;
  bool isFinal(double progress) {
    final point = _pointAtDistance(metrics, totalLength * progress);
    if (point == null) return false;
    final visual = SimaiGameplayInputMapper.sensorForNormalizedPoint(
      point / 300.0,
    );
    if (visual == null) return false;
    final sensor = SimaiGameplayInputMapper.mirrorLocation(visual, mirrorMode);
    return finalSensors.any((candidate) => candidate == sensor);
  }

  if (!isFinal(1.0)) return 1.0;
  const coarseSteps = 128;
  var high = 1.0;
  var low = 0.0;
  for (var step = coarseSteps - 1; step >= 0; step--) {
    final progress = step / coarseSteps;
    if (!isFinal(progress)) {
      low = progress;
      high = (step + 1) / coarseSteps;
      break;
    }
  }
  for (var iteration = 0; iteration < 24; iteration++) {
    final middle = (low + high) / 2;
    if (isFinal(middle)) {
      high = middle;
    } else {
      low = middle;
    }
  }
  return high.clamp(0.0, 1.0).toDouble();
}

Offset? _pointAtDistance(List<PathMetric> metrics, double distance) {
  var remaining = max(0.0, distance);
  for (final metric in metrics) {
    if (remaining <= metric.length) {
      return metric.getTangentForOffset(remaining)?.position;
    }
    remaining -= metric.length;
  }
  if (metrics.isEmpty) return null;
  return metrics.last.getTangentForOffset(metrics.last.length)?.position;
}

Location _logicalSensorAt(
  Offset normalized300Point,
  SimaiMirrorMode mirrorMode,
) {
  final visual = SimaiGameplayInputMapper.nearestSensorForNormalizedPoint(
    normalized300Point / 300.0,
  );
  return SimaiGameplayInputMapper.mirrorLocation(visual, mirrorMode);
}

class _MutableSlideGroup {
  _MutableSlideGroup(this.sensors, {this.blocksSkip = false});

  List<Location> sensors;
  int visualGroupId = -1;
  bool blocksSkip;

  bool contains(Location sensor) =>
      sensors.any((candidate) => candidate == sensor);

  SimaiGameplaySlideInteractionGroup freeze() =>
      SimaiGameplaySlideInteractionGroup(
        sensors: sensors,
        visualGroupId: visualGroupId,
        blocksSkip: blocksSkip,
      );
}

int adaptiveStarSampleCount(double pathLength) {
  if (!pathLength.isFinite || pathLength <= 0) return 128;
  return (pathLength / 2.5).ceil().clamp(128, 512);
}

Future<void> progressivePrecalcOnMain(
  MaiChart chart,
  SimaiMirrorMode mirrorMode,
  void Function(PrecalcChartData) onChunk,
  bool Function() isCancelled, {
  double priorityTime = 0.0,
}) async {
  Map<int, Map<double, int>> currentSlideStartCounts = {};
  Map<String, PrecalcSlideData> currentSlides = {};
  var sliceWatch = Stopwatch()..start();

  void sendChunk() {
    if (currentSlideStartCounts.isEmpty && currentSlides.isEmpty) return;

    onChunk(
      PrecalcChartData(
        slideStartCounts: currentSlideStartCounts,
        slides: currentSlides,
      ),
    );

    currentSlideStartCounts = {};
    currentSlides = {};
  }

  int priorityIndex = 0;
  while (priorityIndex < chart.noteCollections.length &&
      chart.noteCollections[priorityIndex].time < priorityTime) {
    priorityIndex++;
  }
  final order = <int>[
    for (int i = priorityIndex; i < chart.noteCollections.length; i++) i,
    for (int i = 0; i < priorityIndex; i++) i,
  ];

  for (final cIdx in order) {
    if (isCancelled()) return;

    var collection = chart.noteCollections[cIdx];
    Map<double, int> counts = {};
    for (var note in collection) {
      if (note.slidePaths.isNotEmpty) {
        for (var slide in note.slidePaths) {
          double startTime = collection.time + slide.delay;
          double key = (startTime * 1000).round() / 1000.0;
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    if (counts.isNotEmpty) {
      currentSlideStartCounts[cIdx] = counts;
    }

    for (int nIdx = 0; nIdx < collection.length; nIdx++) {
      final note = collection[nIdx];
      if (note.slidePaths.isEmpty) continue;

      for (int sIdx = 0; sIdx < note.slidePaths.length; sIdx++) {
        final slidePath = note.slidePaths[sIdx];
        final String key = '${cIdx}_${nIdx}_$sIdx';

        currentSlides[key] = calculateSingleSlideData(
          note,
          slidePath,
          mirrorMode,
        );
      }
    }

    // Keep main-isolate work in short slices. Geometry based on dart:ui Path
    // cannot be moved wholesale to a background isolate on every platform.
    if (sliceWatch.elapsedMicroseconds >= 4000) {
      sendChunk();
      await Future.delayed(Duration.zero); // yield to UI thread
      sliceWatch = Stopwatch()..start();
    }
  }

  // Send remaining items
  sendChunk();
}
