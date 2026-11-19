import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/ApiUrls.dart';
import '../../manager/DivingFish/UserPlayDataManager.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AwmcIdMap.dart';
import '../../utils/ChartDifficulty.dart';

/// KOP 8th Score Attack 预选（快批）的只读数据服务。
///
/// 预选榜是 sega 官网公开 JSON，无需鉴权、只公开前 100 名；国服不能参赛，
/// 页面里的本地估算仅作娱乐模拟。这里集中处理：
/// - 两服榜的拉取、10 分钟内存缓存与失败回退（保留上次快照并标 stale）；
/// - 赛程与截止判断（一律按 JST，不能按本地时区）；
/// - 从本地成绩缓存里取三首课题曲的最佳成绩（按扣分规则换算）。
///
/// 计分规则：单曲达成率 × 10000，三首合计；非 MASTER 难度按
/// 绿 -3% / 黄 -2% / 红 -1% 扣达成率，每首取扣后最高难度；
/// 同分比 DX 分，再比达成先后（本地无法知道达成时间，模拟只比前两项）。

/// 赛程开始：2026-10-29 07:00 JST。
final DateTime kopQualifierStartUtc = DateTime.utc(2026, 10, 28, 22);

/// 赛程截止：2026-11-23 23:59:59 JST。
final DateTime kopQualifierDeadlineUtc = DateTime.utc(2026, 11, 23, 14, 59, 59);

/// 预选榜所属服务器。
enum KopRegion {
  international(ApiUrls.Kop8thInternationalRankingApi),
  japan(ApiUrls.Kop8thJapanRankingApi);

  const KopRegion(this.url);

  final String url;
}

/// 三首固定课题曲（DX / MASTER）。
///
/// 官方与查分器里的 `song_id` **已经是谱面文件 id**（DX = 曲号 +10000），
/// 11810 / 11745 / 12025 直接就是 DX 谱；12025 数值上像曲号，不能再用
/// [AwmcIdMap.chartFileIdOfBaseSong] 加一次 10000。曲绘按基础曲号查。
class KopQualifierSong {
  const KopQualifierSong({
    required this.chartFileId,
    required this.baseSongId,
    required this.title,
  });

  /// 谱面文件 id，读本地成绩用它。
  final int chartFileId;

  /// 基础曲号，曲绘与曲库查歌用它。
  final int baseSongId;

  final String title;

  String get chartIdText => '$chartFileId';
}

const List<({int chartFileId, String title})> _kopSongDefs = [
  (chartFileId: 11810, title: 'ATLAS RUSH'),
  (chartFileId: 11745, title: '氷滅の135小節'),
  (chartFileId: 12025, title: '魔法仕掛けのファンタジア'),
];

/// 课题曲列表，顺序固定。
final List<KopQualifierSong> kopQualifierSongs = [
  for (final def in _kopSongDefs)
    KopQualifierSong(
      chartFileId: def.chartFileId,
      baseSongId: AwmcIdMap.baseSongId(def.chartFileId)!,
      title: def.title,
    ),
];

/// 官方榜的一条记录。
class KopRankingEntry {
  const KopRankingEntry({
    required this.rank,
    required this.userName,
    required this.score,
    required this.subScore,
    required this.recordDate,
  });

  final int rank;
  final String userName;

  /// 三曲合计分。
  final int score;

  /// DX 分合计，同分时官方按它排序。
  final int subScore;

  /// 达成时间（JST 原文）。
  final String recordDate;
}

/// 某一服的官方榜单快照。
class KopRankingSnapshot {
  const KopRankingSnapshot({
    required this.region,
    required this.updateText,
    required this.entries,
    required this.fetchedAt,
    required this.stale,
  });

  final KopRegion region;

  /// 官方更新时间（JST，已去掉重复的时区后缀）。
  final String updateText;

  final List<KopRankingEntry> entries;

  /// 客户端读取成功的时间。
  final DateTime fetchedAt;

  /// 是否因为刷新失败而在展示上一次的快照。
  final bool stale;

  KopRankingSnapshot copyWith({bool? stale, DateTime? fetchedAt}) =>
      KopRankingSnapshot(
        region: region,
        updateText: updateText,
        entries: entries,
        fetchedAt: fetchedAt ?? this.fetchedAt,
        stale: stale ?? this.stale,
      );
}

/// 本地某首课题曲的最佳记录（已换算扣分）。
class KopSongBest {
  const KopSongBest({
    required this.levelIndex,
    required this.achievement,
    required this.dxScore,
  });

  final int levelIndex;

  /// 原始达成率（百分数，如 100.5）。
  final double achievement;

  final int dxScore;

  /// 扣分后的达成率。
  double get correctedAchievement =>
      (achievement - KopQualifierService.difficultyPenalty(levelIndex))
          .clamp(0, double.infinity);

  /// 扣分后的单曲分（达成率 × 10000）。
  int get correctedScore => (correctedAchievement * 10000).round();

  bool isBetterThan(KopSongBest other) {
    if (correctedScore != other.correctedScore) {
      return correctedScore > other.correctedScore;
    }
    // 同分先比 DX 分，再比原始达成率（官方同分也是比 DX 分）。
    if (dxScore != other.dxScore) {
      return dxScore > other.dxScore;
    }
    return achievement > other.achievement;
  }
}

/// 模拟排名结果。
class KopEstimate {
  const KopEstimate({
    required this.complete,
    required this.totalScore,
    required this.totalDx,
    required this.rank,
    required this.gaps,
    required this.missingCount,
    required this.requiredAchievement,
  });

  /// 三首是否都有成绩。
  final bool complete;

  /// 已记录曲目的合计分；一首都没有时为 null。
  final int? totalScore;

  final int totalDx;

  /// 模拟名次；成绩不齐或超不过榜尾时为 null。
  final int? rank;

  /// 到 #1 / #10 / #50 / #100 的分差；null 表示榜单不足或没有合计分。
  final Map<int, int?> gaps;

  final int missingCount;

  /// 缺成绩时，进入前 100 每首大致需要的达成率（MASTER，未扣分）。
  final double? requiredAchievement;

  bool get completeAll => complete;
}

/// 官方榜请求失败（没有可回退的快照时抛出）。
class KopQualifierException implements Exception {
  KopQualifierException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class KopQualifierService {
  /// 刷新缓存的有效期。
  static const Duration cacheTtl = Duration(minutes: 10);

  static final Map<KopRegion, KopRankingSnapshot> _snapshots = {};
  static final Map<KopRegion, DateTime> _fetchedAt = {};
  static final Map<KopRegion, Future<KopRankingSnapshot>> _inFlight = {};

  /// 赛程是否在进行中（按 UTC 与 JST 截止时刻比较）。
  static bool isAvailable(DateTime now) {
    final utc = now.toUtc();
    return !utc.isBefore(kopQualifierStartUtc) &&
        !utc.isAfter(kopQualifierDeadlineUtc);
  }

  /// 是否已经截止。
  static bool isExpired(DateTime now) => now.toUtc().isAfter(kopQualifierDeadlineUtc);

  /// 距截止还有多久；已截止时返回 [Duration.zero]。
  static Duration remaining(DateTime now) {
    final left = kopQualifierDeadlineUtc.difference(now.toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  /// 官方截止时间（JST 文案）。
  static String deadlineText() {
    final jst = kopQualifierDeadlineUtc.add(const Duration(hours: 9));
    String two(int value) => value.toString().padLeft(2, '0');
    return '${jst.year}-${two(jst.month)}-${two(jst.day)} '
        '${two(jst.hour)}:${two(jst.minute)}:${two(jst.second)} JST';
  }

  /// 非 MASTER 难度的达成率扣分（百分数）。
  static double difficultyPenalty(int levelIndex) => switch (levelIndex) {
        ChartDifficulty.basic => 3,
        ChartDifficulty.advanced => 2,
        ChartDifficulty.expert => 1,
        _ => 0,
      };

  /// 读取某一服的榜单。命中 10 分钟缓存就直接返回；失败时保留上次快照并标
  /// stale，连上次快照都没有才抛出。
  static Future<KopRankingSnapshot> loadRanking(
    KopRegion region, {
    bool force = false,
  }) {
    final cached = _snapshots[region];
    final fetchedAt = _fetchedAt[region];
    if (!force &&
        cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < cacheTtl) {
      return Future.value(cached);
    }
    final inFlight = _inFlight[region];
    if (inFlight != null) return inFlight;
    final future = _load(region);
    _inFlight[region] = future;
    return future;
  }

  static Future<KopRankingSnapshot> _load(KopRegion region) async {
    try {
      final snapshot = await _fetch(region);
      _snapshots[region] = snapshot;
      _fetchedAt[region] = DateTime.now();
      return snapshot;
    } catch (error) {
      final last = _snapshots[region];
      if (last != null) {
        debugPrint('KOP 预选榜刷新失败，沿用上次快照: $error');
        return last.copyWith(stale: true);
      }
      throw error is KopQualifierException
          ? error
          : KopQualifierException('$error');
    } finally {
      _inFlight.remove(region);
    }
  }

  static Future<KopRankingSnapshot> _fetch(KopRegion region) async {
    final response =
        await ApiClient.get(Uri.parse(region.url), timeout: const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw KopQualifierException('HTTP ${response.statusCode}');
    }
    // 官网响应不带 charset，用原始字节按 UTF-8 解码，避免日文名乱码。
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw KopQualifierException('榜单结构不是对象');
    }
    final rawRanking = decoded['ranking'];
    if (rawRanking is! List) {
      throw KopQualifierException('榜单缺少 ranking 数组');
    }
    final entries = <KopRankingEntry>[];
    for (final raw in rawRanking) {
      if (raw is! Map) continue;
      final rank = _toInt(raw['rank']);
      final score = _toInt(raw['score']);
      final subScore = _toInt(raw['subScore']);
      if (rank == null || score == null || subScore == null) continue;
      entries.add(KopRankingEntry(
        rank: rank,
        userName: (raw['userName'] ?? '').toString(),
        score: score,
        subScore: subScore,
        recordDate: (raw['recordDate'] ?? '').toString(),
      ));
    }
    // 官方赛前 / 清榜时 ranking 可能合法为空，交给页面显示空态，
    // 不要当请求失败并去回退旧快照。
    entries.sort((a, b) => a.rank.compareTo(b.rank));
    final updateText = (decoded['update'] ?? '')
        .toString()
        .replaceAll('(JST)', '')
        .trim();
    return KopRankingSnapshot(
      region: region,
      updateText: updateText,
      entries: List.unmodifiable(entries),
      fetchedAt: DateTime.now(),
      stale: false,
    );
  }

  /// 读本地缓存里三首课题曲的最佳成绩，按 [kopQualifierSongs] 顺序返回；
  /// 没有成绩的位置为 null。同一谱面有重复记录时取扣后分最高的一条。
  static Future<List<KopSongBest?>> loadLocalBests() async {
    final data = await UserPlayDataManager().getCachedUserPlayData();
    final records = data?['records'];
    final targetIds = {for (final song in kopQualifierSongs) song.chartFileId};
    final bestByChart = <int, KopSongBest>{};
    if (records is List) {
      for (final raw in records) {
        if (raw is! Map) continue;
        final songId = _toInt(raw['song_id']);
        if (songId == null || !targetIds.contains(songId)) continue;
        final levelIndex = _toInt(raw['level_index']);
        if (levelIndex == null ||
            levelIndex < ChartDifficulty.basic ||
            levelIndex > ChartDifficulty.reMaster) {
          continue;
        }
        final achievement = _toDouble(raw['achievements']);
        if (achievement == null) continue;
        final candidate = KopSongBest(
          levelIndex: levelIndex,
          achievement: achievement,
          dxScore: _toInt(raw['dxScore']) ?? 0,
        );
        final current = bestByChart[songId];
        if (current == null || candidate.isBetterThan(current)) {
          bestByChart[songId] = candidate;
        }
      }
    }
    return [for (final song in kopQualifierSongs) bestByChart[song.chartFileId]];
  }

  /// 按本地成绩和官方榜做娱乐模拟：总分、榜内名次、到各名次的分差，
  /// 以及缺成绩时进入前 100 所需的大致达成率。
  static KopEstimate estimate({
    required List<KopSongBest?> bests,
    required List<KopRankingEntry> ranking,
  }) {
    var total = 0;
    var totalDx = 0;
    var missing = 0;
    for (final best in bests) {
      if (best == null) {
        missing++;
        continue;
      }
      total += best.correctedScore;
      totalDx += best.dxScore;
    }
    final complete = missing == 0;
    final totalScore = missing == bests.length ? null : total;
    final threshold =
        ranking.length >= 100 ? ranking[99].score : (ranking.isEmpty ? null : ranking.last.score);
    int? rank;
    if (complete && totalScore != null) {
      final position = ranking
              .where((entry) =>
                  entry.score > total ||
                  (entry.score == total && entry.subScore > totalDx))
              .length +
          1;
      // 超不过第 100 名就是榜外，和 QueryBot 的口径一致。
      rank = position <= ranking.length ? position : null;
    }
    final gaps = <int, int?>{};
    for (final target in const [1, 10, 50, 100]) {
      final entry = ranking.length >= target ? ranking[target - 1] : null;
      gaps[target] =
          entry == null || totalScore == null ? null : entry.score - totalScore;
    }
    double? requiredAchievement;
    if (missing > 0 && threshold != null) {
      final need = threshold - (totalScore ?? 0);
      requiredAchievement =
          need <= 0 ? 0 : need / missing / 10000;
    }
    return KopEstimate(
      complete: complete,
      totalScore: totalScore,
      totalDx: totalDx,
      rank: rank,
      gaps: gaps,
      missingCount: missing,
      requiredAchievement: requiredAchievement,
    );
  }

  /// 测试用：清空缓存。
  @visibleForTesting
  static void clearCache() {
    _snapshots.clear();
    _fetchedAt.clear();
    _inFlight.clear();
  }

  static int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '');
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(
        value?.toString().trim().replaceAll('%', '') ?? '');
  }
}
