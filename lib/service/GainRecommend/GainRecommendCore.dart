/// 吃分推荐核心（算法由 AWMC 提供，移植自 maimaiDX-QueryBot 的
/// `libraries/gain_recommend`）。
///
/// 纯函数：不读缓存、不联网，所有输入显式传入，便于单测。流程：
/// 1. 正规化成绩（同谱取最佳、剔除未知定数/达成率）；
/// 2. 按新旧曲分区权威重算 B35 + B15；
/// 3. 枚举目标：97/98/99/99.5/100/100.5 档位 + 下一有效 RA 跳点（二分反查，
///    向上量化到 0.0001 后复算）；
/// 4. 独立净收益 = 仅该谱提到目标后的 B50 总和 − 当前 B50 总和；≤0 不推；
/// 5. 三路线（稳妥 / 挑战 / 探索）每谱唯一目标，确定性软配额选页。
///
/// 这里只移植「个人基线」部分；bot 端的同段（全服档内分布）依据在 App
/// 侧拿不到，按原实现 `tier_refs=None` 的行为降级。
library;

const String gainRouteConfigVersion = 'gain-routes-v3';
const List<double> gainTargetLadder = [97.0, 98.0, 99.0, 99.5, 100.0, 100.5];
/// Rating 计算用的达成率封顶：超过 100.5% 一律按 100.5% 折算单曲 RA。
const double gainAchvCap = 100.5;

/// 成绩合法上限：舞萌达成率最高 101.0000%（AP+，全 PERFECT 且 BREAK 全 PERFECT）。
///
/// 注意别拿 [gainAchvCap] 当校验上界：那样会把所有 100.5% 以上的 AP+ 成绩
/// 当成脏数据整条丢掉，B35/B15 里最顶上的一批谱就没了，B50 总 Rating 会明显偏低。
const double gainAchvMaxValid = 101.0;
const double gainStableMaxNeed = 0.20; // 稳妥：提升 ≤ 0.20pp
const double gainChallengeMaxNeed = 0.80; // 挑战：提升 ≤ 0.80pp
const int gainPageSize = 12;
const int gainRouteQuotaFirst = 4; // 软配额：各路线先 4 条
const int gainB35Size = 35;
const int gainB15Size = 15;
const int gainExploreMinSample = 5; // 探索个性化：同 0.5 定数档最少谱数
const double gainStableNeedFloor = 0.05; // 稳妥排序：提升量按至少 0.05pp 计效率

enum GainRoute { stable, challenge, explore }

extension GainRouteLabel on GainRoute {
  String get label => switch (this) {
        GainRoute.stable => '稳妥吃分',
        GainRoute.challenge => '挑战突破',
        GainRoute.explore => '探索',
      };
}

/// 谱面键：(曲目 id, 难度索引)。
class GainChartKey implements Comparable<GainChartKey> {
  final int songId;
  final int levelIndex;
  const GainChartKey(this.songId, this.levelIndex);

  @override
  bool operator ==(Object other) =>
      other is GainChartKey &&
      other.songId == songId &&
      other.levelIndex == levelIndex;

  @override
  int get hashCode => Object.hash(songId, levelIndex);

  @override
  int compareTo(GainChartKey other) => songId != other.songId
      ? songId.compareTo(other.songId)
      : levelIndex.compareTo(other.levelIndex);

  String get storageKey => '${songId}_$levelIndex';

  static GainChartKey? tryParse(String raw) {
    final parts = raw.split('_');
    if (parts.length != 2) return null;
    final songId = int.tryParse(parts[0]);
    final levelIndex = int.tryParse(parts[1]);
    if (songId == null || levelIndex == null) return null;
    return GainChartKey(songId, levelIndex);
  }

  @override
  String toString() => storageKey;
}

/// 正规化后的单谱最佳成绩。isNew: true=B15 区 / false=B35 区 / null=未知。
class GainChartRecord {
  final int songId;
  final int levelIndex;
  final String title;
  final String level;
  final String type;
  final double ds;
  final double achievements;
  final bool? isNew;

  /// 由 [computeGainBaseline] 按达成率重算；上游 ra 字段不作权威。
  int ra = 0;

  GainChartRecord({
    required this.songId,
    required this.levelIndex,
    required this.title,
    required this.level,
    required this.ds,
    required this.achievements,
    required this.isNew,
    this.type = '',
  });

  GainChartKey get key => GainChartKey(songId, levelIndex);

  GainChartRecord copyWith({double? achievements}) => GainChartRecord(
        songId: songId,
        levelIndex: levelIndex,
        title: title,
        level: level,
        type: type,
        ds: ds,
        achievements: achievements ?? this.achievements,
        isNew: isNew,
      );
}

/// 缺记录探索候选（来自当前可游玩曲库，不是用户成绩）。
class GainExploreChart {
  final int songId;
  final int levelIndex;
  final String title;
  final String level;
  final String type;
  final double ds;
  final bool? isNew;

  const GainExploreChart({
    required this.songId,
    required this.levelIndex,
    required this.title,
    required this.level,
    required this.ds,
    required this.isNew,
    this.type = '',
  });

  GainChartKey get key => GainChartKey(songId, levelIndex);
}

/// 一次推荐的显式输入。
class GainInput {
  final List<GainChartRecord> records;

  /// 成绩列表是否为全量（水鱼/落雪的完整 records）。只有全量才开探索路线：
  /// 部分列表里缺的谱不能当「没打过」。
  final bool complete;
  final List<GainExploreChart> explorePool;

  const GainInput({
    required this.records,
    this.complete = false,
    this.explorePool = const [],
  });
}

/// 一条路线候选：谱面 + 唯一目标 + 独立净收益。
class GainCandidate {
  final GainRoute route;
  final GainChartRecord? record; // explore 时为 null
  final GainExploreChart? explore; // 非 explore 时为 null
  final double target;
  final int netGain;
  final double need;
  String reason;

  /// 同谱更高的挑战目标（与稳妥目标不累加）。
  double? alternativeTarget;
  int alternativeGain = 0;

  GainCandidate({
    required this.route,
    this.record,
    this.explore,
    required this.target,
    required this.netGain,
    required this.need,
    required this.reason,
  });

  GainChartKey get key => record?.key ?? explore!.key;
  int get songId => record?.songId ?? explore!.songId;
  int get levelIndex => record?.levelIndex ?? explore!.levelIndex;
  String get title => record?.title ?? explore!.title;
  String get level => record?.level ?? explore!.level;
  String get type => record?.type ?? explore!.type;
  double get ds => record?.ds ?? explore!.ds;
  bool? get isNew => record != null ? record!.isNew : explore!.isNew;

  /// 当前成绩；探索路线为 null（未记录成绩）。
  double? get achievements => record?.achievements;
}

// ---------------------------------------------------------------------------
// RA 与量化
// ---------------------------------------------------------------------------

/// 单曲 Rating（与 bot 端 computeRa 同公式）。
int gainRaOf(double ds, double achv) {
  final double base;
  if (achv < 50) {
    base = 7.0;
  } else if (achv < 60) {
    base = 8.0;
  } else if (achv < 70) {
    base = 9.6;
  } else if (achv < 75) {
    base = 11.2;
  } else if (achv < 80) {
    base = 12.0;
  } else if (achv < 90) {
    base = 13.6;
  } else if (achv < 94) {
    base = 15.2;
  } else if (achv < 97) {
    base = 16.8;
  } else if (achv < 98) {
    base = 20.0;
  } else if (achv < 99) {
    base = 20.3;
  } else if (achv < 99.5) {
    base = 20.8;
  } else if (achv < 100) {
    base = 21.1;
  } else if (achv < 100.5) {
    base = 21.6;
  } else {
    base = 22.4;
  }
  final ratio = achv >= 100.5 ? 1.005 : achv / 100;
  return (ds * ratio * base).floor();
}

/// 向上量化到 0.0001 刻度；恰好落在刻度上的值不额外进一格。
///
/// 按十进制字符串取整（等价 bot 端 `Decimal(str(v)).quantize(ROUND_CEILING)`），
/// 避免 `v * 10000` 的二进制误差把 99.5 量成 99.5001。
double? quantizeGainTarget(double value) {
  if (!value.isFinite || value <= 0 || value > gainAchvCap) return null;
  final text = value.toString();
  if (text.contains('e') || text.contains('E')) {
    return (value * 10000).ceil() / 10000;
  }
  final dot = text.indexOf('.');
  final intPart = dot < 0 ? text : text.substring(0, dot);
  final frac = dot < 0 ? '' : text.substring(dot + 1);
  var units = int.parse(intPart) * 10000 +
      int.parse(frac.padRight(4, '0').substring(0, 4));
  if (frac.length > 4 && frac.substring(4).split('').any((c) => c != '0')) {
    units += 1;
  }
  final out = units / 10000;
  return out > gainAchvCap ? null : out;
}

// ---------------------------------------------------------------------------
// 正规化与基线
// ---------------------------------------------------------------------------

/// 去重（同谱取最佳）、剔除未知定数/达成率，按谱面键升序返回。
List<GainChartRecord> normalizeGainRecords(Iterable<GainChartRecord> raw) {
  final best = <GainChartKey, GainChartRecord>{};
  for (final r in raw) {
    if (!r.ds.isFinite ||
        !r.achievements.isFinite ||
        r.ds <= 0 ||
        r.achievements <= 0 ||
        r.achievements > gainAchvMaxValid) {
      continue;
    }
    final prev = best[r.key];
    if (prev == null || r.achievements > prev.achievements) {
      best[r.key] = r.copyWith();
    }
  }
  final out = best.values.toList()..sort((a, b) => a.key.compareTo(b.key));
  return out;
}

class GainBaseline {
  final List<GainChartRecord> b35;
  final List<GainChartRecord> b15;
  final int raSum;
  final bool hasUnknownPartition;

  const GainBaseline({
    required this.b35,
    required this.b15,
    required this.raSum,
    required this.hasUnknownPartition,
  });

  int get total => b35.length + b15.length;

  List<GainChartRecord> bucket(bool isNew) => isNew ? b15 : b35;
  int capacity(bool isNew) => isNew ? gainB15Size : gainB35Size;
  int floor(bool isNew) => bucket(isNew).isEmpty ? 0 : bucket(isNew).last.ra;
}

/// 完整重算 B35 + B15。任一谱分区未知 → hasUnknownPartition。
///
/// [records] 需先经 [normalizeGainRecords]（按键升序）；同 RA 时按键升序
/// 稳定排序，与 bot 端 Python `sorted` 的稳定性一致。
GainBaseline computeGainBaseline(List<GainChartRecord> records) {
  final hasUnknown = records.any((r) => r.isNew == null);
  for (final r in records) {
    r.ra = gainRaOf(r.ds, r.achievements);
  }
  List<GainChartRecord> top(bool isNew, int size) {
    final list = records.where((r) => r.isNew == isNew).toList();
    list.sort((a, b) {
      final byRa = b.ra.compareTo(a.ra);
      return byRa != 0 ? byRa : a.key.compareTo(b.key);
    });
    return list.take(size).toList();
  }

  final b35 = top(false, gainB35Size);
  final b15 = top(true, gainB15Size);
  return GainBaseline(
    b35: b35,
    b15: b15,
    raSum: [...b35, ...b15].fold(0, (sum, r) => sum + r.ra),
    hasUnknownPartition: hasUnknown,
  );
}

/// 仅把 [record] 提到 [target] 后的 B50 增量（等价完整重排）。
///
/// 已入槽替换自身；未入槽替换满槽底线（未满槽直接补空位）。
int gainIndependentNetGain(
    GainBaseline baseline, GainChartRecord record, double target) {
  final isNew = record.isNew;
  if (baseline.hasUnknownPartition || isNew == null) return 0;
  final targetRa = gainRaOf(record.ds, target);
  final bucket = baseline.bucket(isNew);
  final member = _findByKey(bucket, record.key);
  if (member != null) return _positive(targetRa - member.ra);
  final floor = bucket.length >= baseline.capacity(isNew) ? bucket.last.ra : 0;
  return _positive(targetRa - floor);
}

int _positive(int v) => v > 0 ? v : 0;

GainChartRecord? _findByKey(List<GainChartRecord> bucket, GainChartKey key) {
  for (final r in bucket) {
    if (r.key == key) return r;
  }
  return null;
}

// ---------------------------------------------------------------------------
// 目标枚举
// ---------------------------------------------------------------------------

/// 返回 [(target, netGain)]（按目标升序）：档位 + 下一有效 RA 跳点。
List<(double, int)> enumerateGainTargets(
    GainChartRecord record, GainBaseline baseline) {
  final isNew = record.isNew;
  if (!record.ds.isFinite ||
      record.ds <= 0 ||
      !record.achievements.isFinite ||
      record.achievements < 0 ||
      record.achievements >= gainAchvCap ||
      isNew == null) {
    return const [];
  }
  final out = <(double, int)>[];
  final seen = <double>{};

  void tryTarget(double target) {
    final q = quantizeGainTarget(target);
    if (q == null || q <= record.achievements || seen.contains(q)) return;
    seen.add(q);
    final net = gainIndependentNetGain(baseline, record, q);
    if (net > 0) out.add((q, net));
  }

  for (final t in gainTargetLadder) {
    if (t > record.achievements) tryTarget(t);
  }
  // 满槽且不在槽内时，要跨过分区底线才算跳点，而不只是超过本谱自己的 RA。
  var threshold = gainRaOf(record.ds, record.achievements);
  final bucket = baseline.bucket(isNew);
  if (bucket.length >= baseline.capacity(isNew) &&
      _findByKey(bucket, record.key) == null) {
    final floor = baseline.floor(isNew);
    if (floor > threshold) threshold = floor;
  }
  var lo = record.achievements;
  var hi = gainAchvCap;
  for (var i = 0; i < 60; i++) {
    if (hi - lo < 1e-6) break;
    final mid = (lo + hi) / 2;
    if (gainRaOf(record.ds, mid) > threshold) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  if (hi < gainAchvCap) tryTarget(hi);
  out.sort((a, b) => a.$1.compareTo(b.$1));
  return out;
}

// ---------------------------------------------------------------------------
// 路线与候选
// ---------------------------------------------------------------------------

const List<(double, String)> _gradeLadder = [
  (100.5, 'SSS+'),
  (100.0, 'SSS'),
  (99.5, 'SS+'),
  (99.0, 'SS'),
  (98.0, 'S+'),
  (97.0, 'S'),
];

String gainGradeOf(double achv) {
  for (final (bound, label) in _gradeLadder) {
    if (achv >= bound - 1e-9) return label;
  }
  return '未达 S';
}

/// 推分依据：目标评级、单曲 RA 变化与被顶替的分区最低谱。
String gainBasis(GainChartRecord record, GainBaseline baseline, double target) {
  final isNew = record.isNew ?? false;
  final targetRa = gainRaOf(record.ds, target);
  final bucket = baseline.bucket(isNew);
  final zone = isNew ? 'B15' : 'B35';
  final member = _findByKey(bucket, record.key);
  final targetGrade = gainGradeOf(target);
  final grade = targetGrade != gainGradeOf(record.achievements)
      ? '冲上 $targetGrade'
      : '$targetGrade 档内提分';
  if (member != null) return '$grade；$zone 内单曲 RA ${member.ra}→$targetRa';
  if (bucket.length >= baseline.capacity(isNew)) {
    final floor = bucket.last;
    return '$grade；RA $targetRa 顶替 $zone 最低《${floor.title}》RA ${floor.ra}';
  }
  return '$grade；RA $targetRa 补入 $zone 空位';
}

List<GainCandidate> _targetRoutes(
    GainChartRecord record, GainBaseline baseline) {
  final targets = enumerateGainTargets(record, baseline);
  final out = <GainCandidate>[];
  if (targets.isEmpty) return out;
  // 稳妥：最小达成率的正收益目标（提升 ≤ 0.20）。
  final (firstTarget, firstNet) = targets.first;
  if (firstTarget - record.achievements <= gainStableMaxNeed) {
    out.add(GainCandidate(
      route: GainRoute.stable,
      record: record,
      target: firstTarget,
      netGain: firstNet,
      need: firstTarget - record.achievements,
      reason: '独立净收益+$firstNet（${gainBasis(record, baseline, firstTarget)}）',
    ));
  }
  // 挑战：≤ 0.80 内净收益最大，并列取提升最小。
  (double, int)? best;
  for (final t in targets) {
    if (t.$1 - record.achievements > gainChallengeMaxNeed) continue;
    if (best == null ||
        t.$2 > best.$2 ||
        (t.$2 == best.$2 && t.$1 < best.$1)) {
      best = t;
    }
  }
  if (best != null) {
    final (target, net) = best;
    out.add(GainCandidate(
      route: GainRoute.challenge,
      record: record,
      target: target,
      netGain: net,
      need: target - record.achievements,
      reason: '独立净收益+$net（${gainBasis(record, baseline, target)}）',
    ));
  }
  return out;
}

/// 探索目标上界：个人同 0.5 定数档（≥5 谱）最佳成绩的中位数。
double? gainExploreCeiling(List<GainChartRecord> records, double ds) {
  final bucket = records
      .where((r) => (r.ds - ds).abs() < 0.5 && r.isNew != null)
      .map((r) => r.achievements)
      .toList()
    ..sort();
  if (bucket.length < gainExploreMinSample) return null;
  final mid = bucket.length ~/ 2;
  return bucket.length.isOdd ? bucket[mid] : (bucket[mid - 1] + bucket[mid]) / 2;
}

class GainBuildResult {
  final List<GainCandidate> candidates;
  final GainBaseline baseline;
  final List<GainChartRecord> records;
  final int unknownPartition;
  final int exploreFilteredNoGain;

  const GainBuildResult({
    required this.candidates,
    required this.baseline,
    required this.records,
    required this.unknownPartition,
    required this.exploreFilteredNoGain,
  });

  int count(GainRoute route) =>
      candidates.where((c) => c.route == route).length;
}

/// 生成三路线候选：每谱每路线唯一目标，同谱只占一张卡（稳妥优先，
/// 更高的挑战目标作为可选项挂在稳妥卡上，不累加收益）。
GainBuildResult buildGainCandidates(GainInput input) {
  final records = normalizeGainRecords(input.records);
  final baseline = computeGainBaseline(records);
  var unknownPartition = 0;
  var exploreNoGain = 0;
  final perChart = <GainChartKey, Map<GainRoute, GainCandidate>>{};

  for (final record in records) {
    if (record.isNew == null) {
      unknownPartition++;
      continue;
    }
    final routes = _targetRoutes(record, baseline);
    if (routes.isEmpty) continue;
    final slot = perChart.putIfAbsent(record.key, () => {});
    for (final c in routes) {
      slot[c.route] = c;
    }
  }

  // 探索只用全量输入：缺记录才能算「未记录成绩」，并且打到参考目标必须
  // 真能进 B50（独立净收益 > 0）。
  if (input.complete) {
    final played = {for (final r in records) r.key};
    for (final chart in input.explorePool) {
      if (played.contains(chart.key) || chart.isNew == null) continue;
      if (!chart.ds.isFinite || chart.ds <= 0) continue;
      final ceilingRaw = gainExploreCeiling(records, chart.ds);
      final ceiling = ceilingRaw == null ? null : quantizeGainTarget(ceilingRaw);
      if (ceiling == null) continue;
      final missing = GainChartRecord(
        songId: chart.songId,
        levelIndex: chart.levelIndex,
        title: chart.title,
        level: chart.level,
        type: chart.type,
        ds: chart.ds,
        achievements: 0,
        isNew: chart.isNew,
      );
      final net = gainIndependentNetGain(baseline, missing, ceiling);
      if (net <= 0) {
        exploreNoGain++;
        continue;
      }
      perChart.putIfAbsent(chart.key, () => {})[GainRoute.explore] =
          GainCandidate(
        route: GainRoute.explore,
        explore: chart,
        target: ceiling,
        netGain: net,
        need: 0,
        reason: '个人同档最佳成绩中位参考 ${ceiling.toStringAsFixed(4)}% · '
            '独立净收益+$net（条件估算；不是下次成功率）',
      );
    }
  }

  final keys = perChart.keys.toList()..sort();
  final candidates = <GainCandidate>[];
  for (final key in keys) {
    final routes = perChart[key]!;
    final stable = routes[GainRoute.stable];
    final challenge = routes[GainRoute.challenge];
    if (stable != null) {
      if (challenge != null &&
          challenge.target > stable.target &&
          challenge.netGain > stable.netGain) {
        stable.alternativeTarget = challenge.target;
        stable.alternativeGain = challenge.netGain;
        stable.reason += '；挑战可选 ${challenge.target.toStringAsFixed(4)}%'
            '（独立净收益+${challenge.netGain}，不与稳妥目标累加）';
      }
      candidates.add(stable);
    } else if (challenge != null) {
      candidates.add(challenge);
    }
    final explore = routes[GainRoute.explore];
    if (explore != null && stable == null) candidates.add(explore);
  }
  return GainBuildResult(
    candidates: candidates,
    baseline: baseline,
    records: records,
    unknownPartition: unknownPartition,
    exploreFilteredNoGain: exploreNoGain,
  );
}

/// 各路线内排序。
/// - 稳妥：每 pp 收益高 → 提升小 → 谱面键；
/// - 挑战：收益大 → 提升小 → 谱面键；
/// - 探索：收益大 → 谱面键。
Map<GainRoute, List<GainCandidate>> sortGainCandidates(
    List<GainCandidate> candidates) {
  int byKey(GainCandidate a, GainCandidate b) => a.key.compareTo(b.key);
  double efficiency(GainCandidate c) =>
      c.netGain / (c.need > gainStableNeedFloor ? c.need : gainStableNeedFloor);

  int stable(GainCandidate a, GainCandidate b) {
    var r = efficiency(b).compareTo(efficiency(a));
    if (r == 0) r = a.need.compareTo(b.need);
    return r != 0 ? r : byKey(a, b);
  }

  int challenge(GainCandidate a, GainCandidate b) {
    var r = b.netGain.compareTo(a.netGain);
    if (r == 0) r = a.need.compareTo(b.need);
    return r != 0 ? r : byKey(a, b);
  }

  int explore(GainCandidate a, GainCandidate b) {
    final r = b.netGain.compareTo(a.netGain);
    return r != 0 ? r : byKey(a, b);
  }

  final comparators = {
    GainRoute.stable: stable,
    GainRoute.challenge: challenge,
    GainRoute.explore: explore,
  };
  return {
    for (final route in GainRoute.values)
      route: candidates.where((c) => c.route == route).toList()
        ..sort(comparators[route]),
  };
}

class GainPage {
  final List<GainCandidate> items;

  /// 不足一页时的说明；满页为空串。
  final String fillNote;

  /// 本页之外仍可换批的合格候选数。
  final int remaining;

  const GainPage(this.items, this.fillNote, this.remaining);
}

/// 确定性软配额选页：各路线先 4 条，剩余按 稳妥→挑战→探索 轮转补满。
///
/// 多样性均为软优先：先「同歌曲最多一谱」，不够再放宽；满页后若旧/新分区
/// 缺席而有合格候选，替换多数分区的末位一条。[excluded] 里的谱面（已见 /
/// 反馈屏蔽）先行剔除；绝不放宽资格、不重复同谱。
GainPage selectGainPage(
  Map<GainRoute, List<GainCandidate>> sorted, {
  Set<GainChartKey> excluded = const {},
  int pageSize = gainPageSize,
}) {
  const order = GainRoute.values;
  final queues = {
    for (final route in order)
      route: [
        for (final c in sorted[route] ?? const <GainCandidate>[])
          if (!excluded.contains(c.key)) c
      ],
  };
  final page = <GainCandidate>[];
  final picked = <GainChartKey>{};

  bool take(GainRoute route, bool distinctSong) {
    final songs = {for (final c in page) c.songId};
    for (final c in queues[route]!) {
      if (picked.contains(c.key)) continue;
      if (distinctSong && songs.contains(c.songId)) continue;
      page.add(c);
      picked.add(c.key);
      return true;
    }
    return false;
  }

  for (final distinctSong in [true, false]) {
    if (distinctSong) {
      for (final route in order) {
        for (var i = 0; i < gainRouteQuotaFirst; i++) {
          if (page.length >= pageSize || !take(route, true)) break;
        }
      }
    }
    var idle = 0;
    var idx = 0;
    while (page.length < pageSize && idle < order.length) {
      final took = take(order[idx % order.length], distinctSong);
      idx++;
      idle = took ? 0 : idle + 1;
    }
  }

  // 旧/新分区软优先。
  for (final wantNew in [false, true]) {
    if (page.isEmpty || page.any((c) => c.isNew == wantNew)) continue;
    final pool = [
      for (final route in order)
        for (final c in queues[route]!)
          if (!picked.contains(c.key) && c.isNew == wantNew) c
    ];
    if (pool.isEmpty) continue;
    final victims = [
      for (var i = 0; i < page.length; i++)
        if (page[i].isNew != wantNew) i
    ];
    if (victims.length < 2) continue;
    final victim = victims.last;
    final songs = {
      for (var i = 0; i < page.length; i++)
        if (i != victim) page[i].songId
    };
    final incoming = pool.firstWhere((c) => !songs.contains(c.songId),
        orElse: () => pool.first);
    picked.remove(page[victim].key);
    page[victim] = incoming;
    picked.add(incoming.key);
  }

  var remaining = 0;
  for (final route in order) {
    for (final c in queues[route]!) {
      if (!picked.contains(c.key)) remaining++;
    }
  }
  final note = page.length < pageSize
      ? '合格未见候选 ${page.length} 条'
          '${remaining == 0 ? '，已全部耗尽' : '，其余被反馈/资格过滤'}'
      : '';
  return GainPage(page, note, remaining);
}

/// 本页正收益候选全部达成主目标后的 B50 总变化（逐步重算，已扣除互相
/// 顶替，不是 +N 直接相加）。分区未知时返回 null。
int? combinedGainOfPage(
    List<GainChartRecord> records, List<GainCandidate> page) {
  final normalized = normalizeGainRecords(records);
  final before = computeGainBaseline(normalized);
  if (before.hasUnknownPartition) return null;
  final after = {for (final r in normalized) r.key: r};
  for (final c in page) {
    if (c.netGain <= 0 || c.isNew == null) continue;
    final prev = after[c.key];
    if (prev != null && prev.achievements >= c.target) continue;
    after[c.key] = GainChartRecord(
      songId: c.songId,
      levelIndex: c.levelIndex,
      title: c.title,
      level: c.level,
      type: c.type,
      ds: c.ds,
      achievements: c.target,
      isNew: c.isNew,
    );
  }
  final afterList = after.values.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return computeGainBaseline(afterList).raSum - before.raSum;
}
