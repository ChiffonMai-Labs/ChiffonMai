import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import '../Account/AccountSwitchService.dart';

// ignore_for_file: slash_for_doc_comments

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/entity/Recommend/RecommendationResult.dart';
import 'package:my_first_flutter_app/entity/DivingFish/RecordItem.dart';
import 'package:my_first_flutter_app/entity/DivingFish/UserPlayDataEntity.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/manager/DivingFish/UserPlayDataManager.dart';
import 'package:my_first_flutter_app/service/AWMC/AwmcChartTagService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/CacheKeyConstant.dart';
import 'RatingRecommendService.dart';

class RecommendByTagsService {
  static const int MAX_LIMIT = 70; // 最大推荐数
  static const int RA_RANGE_LIMIT = 20; // Rating极差上限

  /**
   * 预热本地已缓存的 AWMC 与自定义标签索引（后台尝试同步全量快照）。
   */
  static Future<void> initializeTags() async {
    await AwmcChartTagService.syncCatalog();
    await AwmcChartTagService.getTagsEntity();
  }

  static const Map<String, String> TYPE_MAP = {
    "SD": "std",
    "DX": "dx",
  };
  static const Map<int, String> LEVEL_INDEX_MAP = ChartDifficulty.apiNameByIndex;
  static const List<double> RATING_WEIGHT = [
    0.224,
    0.222,
    0.216,
    0.214,
    0.211,
    0.208,
    0.206,
    0.203,
    0.2,
    0.176,
    0.168,
    0.152,
    0.136,
    0.128,
    0.12,
    0.112,
    0.096,
    0.08,
    0.064,
    0.048,
    0.032,
    0.016,
  ];

  // Group names constants
  static const String GROUP_CONFIG = 'config';
  static const String GROUP_DIFFICULTY = 'difficulty';
  static const String GROUP_EVALUATION = 'evaluation';

  static String resolveSheetType(String rawType) {
    final mapped = TYPE_MAP[rawType];
    if (mapped != null) return mapped;
    final lower = rawType.trim().toLowerCase();
    if (lower == 'std' || lower == 'standard') return 'std';
    if (lower == 'dx') return 'dx';
    return '';
  }

  static Set<int> collectChartTagIds({
    required String songId,
    required String title,
    required String type,
    required int levelIndex,
    required Map<String, List<int>> chartKeyToTagIdsMap,
    required Map<String, List<int>> songIdToTagIdsMap,
  }) {
    final ids = <int>{};
    final awmcKey = AwmcChartTagService.chartKey(songId, levelIndex);
    if (awmcKey != null) {
      final byKey = chartKeyToTagIdsMap[awmcKey];
      if (byKey != null) ids.addAll(byKey);
    }
    final sheetType = resolveSheetType(type);
    final sheetDifficulty = LEVEL_INDEX_MAP[levelIndex] ?? '';
    if (sheetType.isNotEmpty && sheetDifficulty.isNotEmpty) {
      final songKey = '$title#$sheetType#$sheetDifficulty';
      final bySong = songIdToTagIdsMap[songKey];
      if (bySong != null) ids.addAll(bySong);
    }
    return ids;
  }
}

/**
 * 获取玩家游玩记录中的Records数组
 * @return Records数组（包含玩家游玩的所有谱面记录）
 */
Future<List<RecordItem>> getUserPlayDataRecords() async {
  try {
    // 直接从 UserPlayDataManager 获取数据
    final userPlayDataManager = UserPlayDataManager();
    final cachedUserData = await userPlayDataManager.getCachedUserPlayData();

    if (cachedUserData != null) {
      // 解析最外层的实体：UserPlayDataEntity
      UserPlayDataEntity userPlayData =
          UserPlayDataEntity.fromJson(cachedUserData);
      // 提取Records数组
      List<RecordItem> records = userPlayData.records;
      return records;
    } else {
      // 如果缓存中没有数据，返回空列表
      debugPrint('UserPlayDataManager 中没有缓存数据');
      return [];
    }
  } catch (e) {
    debugPrint('获取玩家游玩记录失败: $e');
    return [];
  }
}

/**
 * 筛选单曲Rating前MAX_LIMIT(70)个且Rating极差≤20的谱面数据
 * @param records 玩家游玩记录中的Records数组
 * @return 筛选后的 Record 列表（包含至多70个Rating最高的谱面，且Rating极差≤20）
 */
List<RecordItem> filterRecordsByRating(List<RecordItem> records) {
  if (records.isEmpty) return [];
  final sorted = List<RecordItem>.of(records)
    ..sort((a, b) => b.ra.compareTo(a.ra));

  // 找出最高的单曲Rating，并算出Rating极差的下限
  int maxRa = sorted[0].ra;
  int minRa = maxRa - RecommendByTagsService.RA_RANGE_LIMIT;

  // 筛选Rating前MAX_LIMIT(70)个且Rating极差≤20的谱面 -> filterRecords
  List<RecordItem> filteredRecords = [];
  for (var record in sorted) {
    if (record.ra >= minRa && record.ra <= maxRa) {
      filteredRecords.add(record);
    }
    if (filteredRecords.length >= RecommendByTagsService.MAX_LIMIT) {
      break;
    }
  }
  return filteredRecords;
}

/**
 * 按分组统计筛选后谱面中各标签的出现次数
 * @param filteredRecords 筛选后的 Record 列表（包含至多70个Rating最高的谱面，且Rating极差≤20）
 * @return 按分组统计的标签出现次数Map（键：分组名称，值：该分组下各标签的出现次数Map）
 */
Future<Map<String, Map<String, int>>> countTagsByGroup(
  List<RecordItem> filteredRecords, {
  Map<int, (String, int)>? tagIdToInfoMap,
  Map<String, List<int>>? chartKeyToTagIdsMap,
  Map<String, List<int>>? songIdToTagIdsMap,
}) async {
  // 构建分组ID到分组名称的映射，使用英文常量
  Map<int, String> groupIdToNameMap = {
    1: RecommendByTagsService.GROUP_CONFIG,
    2: RecommendByTagsService.GROUP_DIFFICULTY,
    3: RecommendByTagsService.GROUP_EVALUATION,
  };

  // 第二步：构建标签ID → (标签名称, 分组ID) 的映射, 如 22 -> (高物量, 3)
  final resolvedTagInfoMap =
      tagIdToInfoMap ?? await AwmcChartTagService.getTagIdToInfoMap();
  if (resolvedTagInfoMap.isEmpty) {
    debugPrint('标签ID到信息的映射为空');
    return {};
  }

  // 第三步：构建 chartKey / 谱面标识 → 标签ID列表 的映射
  final resolvedChartKeyMap =
      chartKeyToTagIdsMap ?? await AwmcChartTagService.getChartKeyToTagIdsMap();
  final resolvedSongIdMap =
      songIdToTagIdsMap ?? await AwmcChartTagService.getSongIdToTagIdsMap();

  // 第四步：遍历筛选后的RA谱面，按分组统计标签出现次数
  Map<String, Map<String, int>> groupTagCountMap = {};
  Set<String> processedCharts = {};
  for (var record in filteredRecords) {
    final dedupKey = '${record.songId}_${record.levelIndex}';
    if (!processedCharts.add(dedupKey)) {
      continue;
    }

    final tagIds = RecommendByTagsService.collectChartTagIds(
      songId: record.songId.toString(),
      title: record.title,
      type: record.type,
      levelIndex: record.levelIndex,
      chartKeyToTagIdsMap: resolvedChartKeyMap,
      songIdToTagIdsMap: resolvedSongIdMap,
    );
    for (var tagId in tagIds) {
      final tagInfo = resolvedTagInfoMap[tagId];
      if (tagInfo != null) {
        String tagName = tagInfo.$1;
        int groupId = tagInfo.$2;

        String? groupName = groupIdToNameMap[groupId];
        if (groupName != null) {
          final tagCountMap = groupTagCountMap.putIfAbsent(groupName, () => {});
          tagCountMap[tagName] = (tagCountMap[tagName] ?? 0) + 1;
        }
      }
    }
  }
  return groupTagCountMap;
}

/**
 * 计算玩家的能力向量(3个向量)
 * 频率 = 标签出现次数 / 该分组总标签数
 * @param filteredRecords 筛选后的谱面记录列表
 * @return 玩家的能力向量Map（键：分组名称，值：该分组下各标签的能力向量Map）
 */
Future<Map<String, Map<String, double>>> calculatePlayerAbilityVectors(
  List<RecordItem> filteredRecords, {
  Map<int, (String, int)>? tagIdToInfoMap,
  Map<String, List<int>>? chartKeyToTagIdsMap,
  Map<String, List<int>>? songIdToTagIdsMap,
}) async {
  Map<String, Map<String, double>> playerAbilityVectors = {};
  Map<String, Map<String, int>> groupTagCountMap = await countTagsByGroup(
    filteredRecords,
    tagIdToInfoMap: tagIdToInfoMap,
    chartKeyToTagIdsMap: chartKeyToTagIdsMap,
    songIdToTagIdsMap: songIdToTagIdsMap,
  );
  // 打印分组统计标签出现次数
  debugPrint('按分组统计标签出现次数:');
  groupTagCountMap.forEach((groupName, tagCounts) {
    debugPrint('  $groupName:');
    tagCounts.forEach((tagName, count) {
      debugPrint('    $tagName: $count');
    });
  });
  // 遍历每个分组，计算其下各标签的能力向量
  for (var groupName in groupTagCountMap.keys) {
    Map<String, int> tagCountMap = groupTagCountMap[groupName]!;
    int totalTagCount = tagCountMap.values.fold(0, (sum, count) => sum + count);
    if (totalTagCount <= 0) continue;
    playerAbilityVectors[groupName] = {};
    for (var tagName in tagCountMap.keys) {
      int tagCount = tagCountMap[tagName]!;
      double frequency = tagCount / totalTagCount;
      playerAbilityVectors[groupName]![tagName] = frequency;
    }
  }
  // 打印玩家能力向量
  debugPrint('玩家能力向量:');
  playerAbilityVectors.forEach((groupName, tagWeights) {
    debugPrint('  $groupName:');
    tagWeights.forEach((tagName, weight) {
      debugPrint('    $tagName: ${weight.toStringAsFixed(4)}');
    });
  });
  return playerAbilityVectors;
}

/**
 * 获取玩家的过往版本中的BestN个谱面或当前版本中的BestN个谱面
 * @param allRecords 所有谱面记录列表
 * @param n 要获取的谱面数量
 * @param isNewOnly 是否仅获取当前版本的BestN个谱面
 * @return 玩家的BestN个谱面记录列表
 */
Future<List<RecordItem>> getBestNRecords(
    List<RecordItem> allRecords, int n, bool isNewOnly) async {
  // 直接使用 MaimaiMusicDataManager 中的数据构建 songId 到 isNew 的映射
  final maimaiMusicDataManager = MaimaiMusicDataManager();
  Map<String, bool> songIdToIsNewMap = {};

  if (await maimaiMusicDataManager.hasCachedData()) {
    final songs = await maimaiMusicDataManager.getCachedSongs();
    if (songs != null) {
      // 构建 songId 到 isNew 的映射
      songIdToIsNewMap = {
        for (var song in songs) song.id: song.basicInfo.isNew,
      };
    }
  } else {
    debugPrint('MaimaiMusicDataManager 中没有缓存数据');
    return [];
  }

  // 3. 优化后的筛选+排序+取前 N 逻辑
  final List<RecordItem> bestRecords = allRecords
      // 筛选条件：显式处理空值，逻辑更清晰
      .where((record) {
    // 兜底：如果 songId 不在映射中，默认按 "非目标版本" 处理（返回 false）
    final bool? isNew = songIdToIsNewMap[record.songId.toString()];
    return (isNew ?? false) == isNewOnly;
  })
      // 按 Rating 降序排序
      .toList() // where 返回 Iterable，需先转 List 才能排序
    ..sort((a, b) => b.ra.compareTo(a.ra));

  // 取前 N 个
  return bestRecords.take(n).toList();
}

/**
 * 获取玩家的Rating范围
 * @param records 玩家的谱面记录列表
 * @return (minRating, maxRating) 玩家的Rating范围
 */
(int, int) getRaRange(List<RecordItem> records) {
  if (records.isEmpty) {
    return (0, 0);
  }
  int minRating = records.first.ra;
  int maxRating = records.first.ra;
  for (var record in records) {
    minRating = min(minRating, record.ra);
    maxRating = max(maxRating, record.ra);
  }
  return (minRating, maxRating);
}

/**
 * 获取定数范围
 * @param minRating 最小Rating
 * @param maxRating 最大Rating
 * @return (minDs, maxDs) 定数范围
 */
(double, double) getDifficultyRange(int minRating, int maxRating) {
  double minDs = (minRating / (100.5 * 0.224) * 10).round() / 10;
  double maxDs = (maxRating / (100.0 * 0.216) * 10).round() / 10;
  return (minDs, maxDs);
}

/**
 * 计算单曲Rating
 * @param ds 谱面难度
 * @param achievement 玩家达成率 只考虑100.0 - 101.0的范围
 * @return 单曲Rating
 */
int calculateSingleRating(double ds, double achievement) {
  // 达成率大于等于100.5 SSS+
  if (achievement >= 100.5) {
    return (ds * 100.5 * RecommendByTagsService.RATING_WEIGHT[0]).truncate();
  }
  // 100.4999 SSS
  if (achievement == 100.4999) {
    return (ds * 100.4999 * RecommendByTagsService.RATING_WEIGHT[1]).truncate();
  }
  // 100.0 - 100.4998 SSS
  if (achievement >= 100.0 && achievement < 100.4999) {
    return (ds * achievement * RecommendByTagsService.RATING_WEIGHT[2])
        .truncate();
  }
  return 0;
}

/**
 * 计算单个谱面的向量
 */
Future<Map<String, Map<String, double>>> calculateChartVectors(
  RecordItem recordItem, {
  Map<int, (String, int)>? tagIdToInfoMap,
  Map<String, List<int>>? chartKeyToTagIdsMap,
  Map<String, List<int>>? songIdToTagIdsMap,
}) async {
  final resolvedTagInfoMap =
      tagIdToInfoMap ?? await AwmcChartTagService.getTagIdToInfoMap();
  final resolvedChartKeyMap =
      chartKeyToTagIdsMap ?? await AwmcChartTagService.getChartKeyToTagIdsMap();
  final resolvedSongIdMap =
      songIdToTagIdsMap ?? await AwmcChartTagService.getSongIdToTagIdsMap();

  Map<int, Map<String, int>> groupTagCounts = {1: {}, 2: {}, 3: {}};
  Map<int, int> groupTotalTags = {1: 0, 2: 0, 3: 0};

  final tagIds = RecommendByTagsService.collectChartTagIds(
    songId: recordItem.songId.toString(),
    title: recordItem.title,
    type: recordItem.type,
    levelIndex: recordItem.levelIndex,
    chartKeyToTagIdsMap: resolvedChartKeyMap,
    songIdToTagIdsMap: resolvedSongIdMap,
  );
  for (int tagId in tagIds) {
    final info = resolvedTagInfoMap[tagId];
    if (info == null) continue;
    final tagName = info.$1;
    final groupId = info.$2;
    if (tagName.isEmpty || !groupTagCounts.containsKey(groupId)) continue;
    groupTagCounts[groupId]![tagName] =
        (groupTagCounts[groupId]![tagName] ?? 0) + 1;
    groupTotalTags[groupId] = (groupTotalTags[groupId] ?? 0) + 1;
  }

  Map<String, double> normalizeGroup(int groupId) {
    final total = groupTotalTags[groupId] ?? 0;
    if (total <= 0) return const {};
    return {
      for (final entry in groupTagCounts[groupId]!.entries)
        entry.key: entry.value / total,
    };
  }

  return {
    RecommendByTagsService.GROUP_CONFIG: normalizeGroup(1),
    RecommendByTagsService.GROUP_DIFFICULTY: normalizeGroup(2),
    RecommendByTagsService.GROUP_EVALUATION: normalizeGroup(3),
  };
}

/**
 * 计算向量相似度（结合玩家常用标签亲和度与余弦相似度，适配 AWMC 细粒度标签分布）
 */
double calculateVectorSimilarity(
    Map<String, double> playerVector, Map<String, double> chartVector) {
  if (playerVector.isEmpty || chartVector.isEmpty) {
    return 0.0;
  }
  double dotProduct = 0.0;
  double maxPlayerWeight = 0.0;
  for (double value in playerVector.values) {
    if (value > maxPlayerWeight) maxPlayerWeight = value;
  }
  if (maxPlayerWeight <= 0.0) return 0.0;

  double affinitySum = 0.0;
  for (String key in chartVector.keys) {
    final pw = playerVector[key] ?? 0.0;
    if (pw > 0.0) {
      dotProduct += pw * chartVector[key]!;
      affinitySum += pw / maxPlayerWeight;
    }
  }
  if (affinitySum <= 0.0) return 0.0;

  double playerVectorLength = 0.0;
  for (double value in playerVector.values) {
    playerVectorLength += value * value;
  }
  playerVectorLength = sqrt(playerVectorLength);
  double chartVectorLength = 0.0;
  for (double value in chartVector.values) {
    chartVectorLength += value * value;
  }
  chartVectorLength = sqrt(chartVectorLength);

  if (playerVectorLength == 0.0 || chartVectorLength == 0.0) {
    return 0.0;
  }
  final cosine = dotProduct / (playerVectorLength * chartVectorLength);
  final affinity = affinitySum / chartVector.length;
  return (0.55 * affinity + 0.45 * cosine).clamp(0.0, 1.0);
}

/**
 * 计算玩家的能力向量和谱面的向量的综合相似度（按有效命中分组自适应归一化）
 */
double calculateSimilarity(
    Map<String, Map<String, double>> playerAbilityVectors,
    Map<String, Map<String, double>> chartVectors) {
  const weights = <(String, double)>[
    (RecommendByTagsService.GROUP_CONFIG, 0.5),
    (RecommendByTagsService.GROUP_DIFFICULTY, 0.3),
    (RecommendByTagsService.GROUP_EVALUATION, 0.2),
  ];

  double playerWeightSum = 0.0;
  double activeWeightSum = 0.0;
  double weightedSum = 0.0;

  for (final (group, weight) in weights) {
    final pv = playerAbilityVectors[group];
    if (pv == null || pv.isEmpty) continue;
    playerWeightSum += weight;
    final cv = chartVectors[group];
    if (cv == null || cv.isEmpty) continue;
    activeWeightSum += weight;
    weightedSum += calculateVectorSimilarity(pv, cv) * weight;
  }

  if (activeWeightSum <= 0.0) return 0.0;
  final base = weightedSum / activeWeightSum;
  final coverage =
      playerWeightSum > 0.0 ? (activeWeightSum / playerWeightSum) : 1.0;
  return (base * (0.85 + 0.15 * coverage)).clamp(0.0, 1.0);
}

/**
 * 计算推荐结果
 * 基于玩家的能力向量和谱面记录，计算推荐结果
 *  @param allRecords 所有谱面记录列表
 *  @param playerAbilityVectors 玩家的能力向量Map（键：分组名称，值：该分组下各标签的能力向量Map）
 *  @param minDs 目标定数下限
 *  @param maxDs 目标定数上限
 *  @param minRating 目标Rating下限
 *  @param maxRating 目标Rating上限
 *  @param best35minRating 玩家的Best35谱面记录列表中最小Rating
 *  @param best35maxRating 玩家的Best35谱面记录列表中最大Rating
 *  @param isNewOnly 是否仅推荐当前版本的谱面
 *  @return 推荐结果列表
 */
class _ChartStructuralFeatures {
  const _ChartStructuralFeatures({
    required this.values,
    required this.charter,
    required this.isDx,
  });

  /// 连续特征向量：[tapRatio, holdRatio, slideRatio, touchRatio, breakRatio, noteVolumeNorm, bpmNorm]
  final List<double> values;
  final String charter;
  final bool isDx;

  static _ChartStructuralFeatures? fromSong(Song song, int levelIndex) {
    if (levelIndex < 0 || levelIndex >= song.charts.length) return null;
    final chart = song.charts[levelIndex];
    final notes = chart.notes;
    if (notes.length < 4) return null;

    final double tap = notes[0].toDouble();
    final double hold = notes[1].toDouble();
    final double slide = notes[2].toDouble();
    final double touch = notes.length >= 5 ? notes[3].toDouble() : 0.0;
    final double brk =
        notes.length >= 5 ? notes[4].toDouble() : notes[3].toDouble();
    final double total = tap + hold + slide + touch + brk;
    if (total <= 0) return null;

    final rawCharter = chart.charter.trim().toLowerCase();
    final charter = (rawCharter.isEmpty || rawCharter == '-') ? '' : rawCharter;
    final bpmNorm = (song.basicInfo.bpm > 0 ? song.basicInfo.bpm / 200.0 : 0.85)
        .clamp(0.3, 1.6);

    return _ChartStructuralFeatures(
      values: <double>[
        tap / total,
        hold / total,
        slide / total,
        touch / total,
        brk / total,
        (total / 1000.0).clamp(0.0, 1.6),
        bpmNorm,
      ],
      charter: charter,
      isDx: song.type == 'DX',
    );
  }
}

class _PlayerStructuralProfile {
  const _PlayerStructuralProfile({
    required this.means,
    required this.stds,
    required this.charterAffinity,
    required this.dxRatio,
  });

  static const List<double> _featureWeights = <double>[
    2.0, // tapRatio
    1.8, // holdRatio
    2.4, // slideRatio
    1.4, // touchRatio
    1.2, // breakRatio
    1.4, // noteVolumeNorm
    1.6, // bpmNorm
  ];
  static const double _totalFeatureWeight = 11.8;

  final List<double> means;
  final List<double> stds;
  final Map<String, double> charterAffinity;
  final double dxRatio;

  static _PlayerStructuralProfile? fromRecords(
    List<RecordItem> records,
    Map<String, Song> songById,
  ) {
    final samples = <_ChartStructuralFeatures>[];
    final seen = <String>{};
    for (final record in records) {
      final key = '${record.songId}_${record.levelIndex}';
      if (!seen.add(key)) continue;
      final song = songById[record.songId.toString()];
      if (song == null) continue;
      final features =
          _ChartStructuralFeatures.fromSong(song, record.levelIndex);
      if (features != null) samples.add(features);
    }
    if (samples.isEmpty) return null;

    const dim = 7;
    final means = List<double>.filled(dim, 0.0);
    final charterCounts = <String, int>{};
    var dxCount = 0;
    for (final sample in samples) {
      for (int i = 0; i < dim; i++) {
        means[i] += sample.values[i];
      }
      if (sample.charter.isNotEmpty) {
        charterCounts[sample.charter] =
            (charterCounts[sample.charter] ?? 0) + 1;
      }
      if (sample.isDx) dxCount++;
    }
    for (int i = 0; i < dim; i++) {
      means[i] /= samples.length;
    }

    final variances = List<double>.filled(dim, 0.0);
    for (final sample in samples) {
      for (int i = 0; i < dim; i++) {
        final d = sample.values[i] - means[i];
        variances[i] += d * d;
      }
    }
    final stds = List<double>.generate(dim, (i) {
      final minFloor = i < 5 ? 0.06 : 0.15;
      return max(minFloor, sqrt(variances[i] / samples.length));
    });

    final maxCharter = charterCounts.values.fold<int>(0, max);
    final charterAffinity = maxCharter > 0
        ? {
            for (final e in charterCounts.entries) e.key: e.value / maxCharter,
          }
        : const <String, double>{};

    return _PlayerStructuralProfile(
      means: means,
      stds: stds,
      charterAffinity: charterAffinity,
      dxRatio: dxCount / samples.length,
    );
  }

  double similarityTo(_ChartStructuralFeatures features) {
    double weightedDistSq = 0.0;
    for (int i = 0; i < means.length; i++) {
      final z = (features.values[i] - means[i]) / stds[i];
      weightedDistSq += _featureWeights[i] * z * z;
    }
    final continuousSim = exp(-weightedDistSq / (_totalFeatureWeight * 1.45));
    final charterBonus =
        0.10 * (charterAffinity[features.charter] ?? 0.0);
    final typeBonus = 0.04 * (features.isDx ? dxRatio : (1.0 - dxRatio));
    return (continuousSim * 0.88 + charterBonus + typeBonus).clamp(0.0, 0.96);
  }
}

Future<List<RecommendationResult>> calculateRecommendations(
  List<RecordItem> allRecords,
  Map<String, Map<String, double>> playerAbilityVectors,
  double minDs,
  double maxDs,
  int minRating,
  int maxRating,
  int best35minRating,
  int best35maxRating,
  bool isNewOnly,
  Map<String, int> bestRecordRaMap, {
  List<Song>? cachedSongs,
  Map<int, (String, int)>? tagIdToInfoMap,
  Map<String, List<int>>? chartKeyToTagIdsMap,
  Map<String, List<int>>? songIdToTagIdsMap,
}) =>
    _calculateRecommendationsInternal(
      allRecords,
      playerAbilityVectors,
      minDs,
      maxDs,
      minRating,
      maxRating,
      best35minRating,
      best35maxRating,
      isNewOnly,
      bestRecordRaMap,
      cachedSongs: cachedSongs,
      tagIdToInfoMap: tagIdToInfoMap,
      chartKeyToTagIdsMap: chartKeyToTagIdsMap,
      songIdToTagIdsMap: songIdToTagIdsMap,
    );

Future<List<RecommendationResult>> _calculateRecommendationsInternal(
  List<RecordItem> allRecords,
  Map<String, Map<String, double>> playerAbilityVectors,
  double minDs,
  double maxDs,
  int minRating,
  int maxRating,
  int best35minRating,
  int best35maxRating,
  bool isNewOnly,
  Map<String, int> bestRecordRaMap, {
  List<Song>? cachedSongs,
  Map<int, (String, int)>? tagIdToInfoMap,
  Map<String, List<int>>? chartKeyToTagIdsMap,
  Map<String, List<int>>? songIdToTagIdsMap,
  _PlayerStructuralProfile? playerStructuralProfile,
}) async {
  List<RecommendationResult> recommendations = [];
  List<Song>? songs = cachedSongs;
  if (songs == null) {
    final maimaiMusicDataManager = MaimaiMusicDataManager();
    if (await maimaiMusicDataManager.hasCachedData()) {
      songs = await maimaiMusicDataManager.getCachedSongs();
    } else {
      debugPrint('MaimaiMusicDataManager 中没有缓存数据');
      return [];
    }
  }
  if (songs == null || songs.isEmpty) return [];

  final resolvedTagInfoMap =
      tagIdToInfoMap ?? await AwmcChartTagService.getTagIdToInfoMap();
  final resolvedChartKeyMap =
      chartKeyToTagIdsMap ?? await AwmcChartTagService.getChartKeyToTagIdsMap();
  final resolvedSongIdMap =
      songIdToTagIdsMap ?? await AwmcChartTagService.getSongIdToTagIdsMap();

  final songById = {for (final s in songs) s.id: s};
  final structuralProfile = playerStructuralProfile ??
      _PlayerStructuralProfile.fromRecords(
        filterRecordsByRating(allRecords),
        songById,
      );

  Map<String, RecordItem> playerRecordMap = {};
  for (var record in allRecords) {
    String key = '${record.songId}_${record.levelIndex}';
    playerRecordMap[key] = record;
  }

  int songIterCount = 0;
  for (var song in songs) {
    if (++songIterCount % 25 == 0) {
      await Future.delayed(Duration.zero);
    }
    if (song.cids.isNotEmpty && song.cids.every((cid) => cid == 0)) {
      continue;
    }
    if (song.isExtra) {
      continue;
    }
    if (song.basicInfo.isNew != isNewOnly) {
      continue;
    }
    final numericSongId = int.tryParse(song.id);
    if (numericSongId == null) continue;

    for (int i = 0; i < song.ds.length; i++) {
      double ds = song.ds[i];
      if (ds >= minDs && ds <= maxDs) {
        String recordKey = '${numericSongId}_$i';
        RecordItem? existingRecord = playerRecordMap[recordKey];
        if (existingRecord != null && existingRecord.achievements > 100.5) {
          continue;
        }

        double currentAchievement =
            double.tryParse(existingRecord?.achievements.toString() ?? '0.0') ??
                0.0;
        double minAchievements = 0.0;
        if (isNewOnly == false) {
          minAchievements =
              calculateMinAchievements(ds, best35minRating, currentAchievement);
        }
        if (isNewOnly == true) {
          minAchievements =
              calculateMinAchievements(ds, minRating, currentAchievement);
        }

        if (minAchievements > 100.5) {
          continue;
        }

        bool ableRiseTotalRating = false;
        int riseToatalRating = 0;

        RecordItem recordItem = RecordItem(
          achievements: 0.0,
          ds: ds,
          dxScore: 0,
          fc: '',
          fs: '',
          level: '',
          levelIndex: i,
          levelLabel: '',
          ra: 0,
          rate: '',
          songId: numericSongId,
          title: song.basicInfo.title,
          type: song.type,
        );

        Map<String, Map<String, double>> songVectors =
            await calculateChartVectors(
          recordItem,
          tagIdToInfoMap: resolvedTagInfoMap,
          chartKeyToTagIdsMap: resolvedChartKeyMap,
          songIdToTagIdsMap: resolvedSongIdMap,
        );
        final double tagSimilarity =
            calculateSimilarity(playerAbilityVectors, songVectors);
        final features = _ChartStructuralFeatures.fromSong(song, i);
        final double? structuralSimilarity =
            (structuralProfile != null && features != null)
                ? structuralProfile.similarityTo(features)
                : null;

        final bool hasTagMatch =
            tagSimilarity > 0.0 && playerAbilityVectors.isNotEmpty;
        final double similarity;
        final bool eligible;
        if (hasTagMatch) {
          similarity = structuralSimilarity != null
              ? (0.72 * tagSimilarity + 0.28 * structuralSimilarity)
                  .clamp(0.0, 1.0)
              : tagSimilarity;
          eligible = tagSimilarity >= 0.15 || similarity >= 0.35;
        } else if (structuralSimilarity != null) {
          // 尚未命中 AWMC 标签的谱面，利用物量构成/BPM/谱师特征作为混合兜底。
          similarity = (structuralSimilarity * 0.88).clamp(0.0, 0.85);
          eligible = similarity >= 0.45;
        } else {
          similarity = 0.0;
          eligible = false;
        }

        if (eligible) {
          int minAchievementsRating =
              calculateSingleRating(ds, minAchievements);
          String bestLookupKey = '${numericSongId}_$i';
          int existingBestRa = bestRecordRaMap[bestLookupKey] ?? 0;
          int fallbackBaseRating = isNewOnly ? minRating : best35minRating;
          int baseRating = existingBestRa > 0 ? existingBestRa : fallbackBaseRating;
          if (minAchievementsRating > baseRating) {
            ableRiseTotalRating = true;
            riseToatalRating = minAchievementsRating - baseRating;
          }

          RecordItem? playerRecord = playerRecordMap[recordKey] ?? recordItem;
          double targetAchievement = minAchievements;
          if (playerRecord.achievements >= minAchievements) {
            targetAchievement = playerRecord.achievements + 0.001;
          }
          recommendations.add(RecommendationResult(
            songTitle: song.basicInfo.title,
            level: i < RatingRecommendService.LEVEL_LABELS.length
                ? RatingRecommendService.LEVEL_LABELS[i]
                : '',
            ds: ds,
            similarity: similarity,
            nowAchievement:
                double.tryParse(playerRecord.achievements.toString()) ?? 0.0,
            minAchievement: targetAchievement,
            ableRiseTotalRating: ableRiseTotalRating,
            riseTotalRating: ableRiseTotalRating
                ? "+" + riseToatalRating.toString()
                : '无Rating提升,推荐练习',
            songId: song.id,
            levelIndex: i,
            type: song.type,
            difficultyCount: song.ds.length,
          ));
        }
      }
    }
  }
  recommendations.sort((a, b) => b.similarity.compareTo(a.similarity));
  return recommendations.take(100).toList();
}

/**
 * 计算能落入rating区间的最低达成率
 * 先算100%，如果无法落入区间则算100.5%，都不行则返回101.0（后续会被过滤）
 * @param ds 谱面定数
 * @param targetRa 目标Rating
 * @param currentAchievement 当前达成率
 * @return 能落入rating区间的最低达成率，始终大于当前达成率
 */
double calculateMinAchievements(double ds, int targetRa, double currentAchievement) {
  double minAchievement = currentAchievement + 0.001; // 确保大于当前达成率

  // 尝试100%达成率
  if (minAchievement <= 100.0 && calculateSingleRating(ds, 100.0) >= targetRa) {
    return 100.0;
  }

  // 尝试100.5%达成率
  if (calculateSingleRating(ds, 100.5) >= targetRa) {
    return minAchievement > 100.5 ? minAchievement : 100.5;
  }

  // 无法落入目标区间，返回一个会被 filter 剔除的值
  return 101.0;
}



({int taggedCount, List<String> missingKeys}) _inspectRangeTagCoverage({
  required List<Song> songs,
  required Map<String, RecordItem> playerRecordMap,
  required Map<String, List<int>> chartKeyToTagIdsMap,
  required Map<String, List<int>> songIdToTagIdsMap,
  required double minDs,
  required double maxDs,
  required bool isNewOnly,
}) {
  final midDs = (minDs + maxDs) * 0.5;
  int taggedCount = 0;
  final scoredMissing = <(double dist, String chartKey)>[];
  for (final song in songs) {
    if (song.cids.isNotEmpty && song.cids.every((cid) => cid == 0)) continue;
    if (song.isExtra || song.basicInfo.isNew != isNewOnly) continue;
    final numericSongId = int.tryParse(song.id);
    if (numericSongId == null) continue;
    for (int i = 0; i < song.ds.length; i++) {
      final ds = song.ds[i];
      if (ds < minDs || ds > maxDs) continue;
      final existing = playerRecordMap['${numericSongId}_$i'];
      if (existing != null && existing.achievements > 100.5) continue;
      final ids = RecommendByTagsService.collectChartTagIds(
        songId: song.id,
        title: song.basicInfo.title,
        type: song.type,
        levelIndex: i,
        chartKeyToTagIdsMap: chartKeyToTagIdsMap,
        songIdToTagIdsMap: songIdToTagIdsMap,
      );
      if (ids.isNotEmpty) {
        taggedCount++;
      } else {
        final awmcKey = AwmcChartTagService.chartKey(song.id, i);
        if (awmcKey != null) {
          scoredMissing.add(((ds - midDs).abs(), awmcKey));
        }
      }
    }
  }
  scoredMissing.sort((a, b) => a.$1.compareTo(b.$1));
  return (
    taggedCount: taggedCount,
    missingKeys: [for (final item in scoredMissing) item.$2],
  );
}

/**
 * 推荐算法实现 
 * 设计思想：根据单曲Rating最高的70个谱面，计算玩家的能力向量(3个向量)，
 * 并根据玩家的能力向量，推荐玩家能够推分的谱面
 * Best55 部分兼顾推分和基础
 * Best15 部分专注于推分
 */
Future<Map<String, List<RecommendationResult>>> recommendSongs({
  double? minDsOverride,
  double? maxDsOverride,
}) async {
  final revision = AccountSwitchService.revision;
  // 定义兜底返回值，确保异常时也能返回规范格式
  final defaultResult = {
    'Best55': <RecommendationResult>[],
    'Best15': <RecommendationResult>[]
  };

  try {
    // 优先同步后端全量 AWMC 聚合标签快照（失败静默降级），再加载本地与自定义标签。
    await AwmcChartTagService.syncCatalog();
    await AwmcChartTagService.getTagsEntity();
    debugPrint('标签数据初始化完成');

    // 使用已经筛选的单曲Rating最高的70个谱面
    List<RecordItem> userPlayDataRecords = await getUserPlayDataRecords();
    debugPrint('获取到 ${userPlayDataRecords.length} 条玩家游玩记录');
    if (userPlayDataRecords.isEmpty) return defaultResult;

    List<RecordItem> filteredRecords =
        filterRecordsByRating(userPlayDataRecords);
    debugPrint('筛选后得到 ${filteredRecords.length} 条记录');
    if (filteredRecords.isEmpty) return defaultResult;

    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? const <Song>[];
    if (songs.isEmpty) return defaultResult;

    // 获取玩家的过往版本中的Best55和当前版本中的Best15
    List<RecordItem> best55 =
        await getBestNRecords(userPlayDataRecords, 55, false);
    debugPrint('获取到 ${best55.length} 条Best55记录');

    List<RecordItem> best15 =
        await getBestNRecords(userPlayDataRecords, 15, true);
    debugPrint('获取到 ${best15.length} 条Best15记录');

    // 计算过往版本中的Best35用于判断Best55推荐结果是否能够增长总Rating
    List<RecordItem> best35 =
        await getBestNRecords(userPlayDataRecords, 35, false);
    debugPrint('获取到 ${best35.length} 条Best35记录');

    Map<String, int> best35RaMap = {
      for (var r in best35) '${r.songId}_${r.levelIndex}': r.ra,
    };
    Map<String, int> best15RaMap = {
      for (var r in best15) '${r.songId}_${r.levelIndex}': r.ra,
    };

    int best55minRating = 0;
    int best55maxRating = 0;
    (best55minRating, best55maxRating) = getRaRange(best55);
    debugPrint('Best55 Rating范围: $best55minRating - $best55maxRating');

    int best15minRating = 0;
    int best15maxRating = 0;
    (best15minRating, best15maxRating) = getRaRange(best15);
    debugPrint('Best15 Rating范围: $best15minRating - $best15maxRating');

    int best35minRating = 0;
    int best35maxRating = 0;
    (best35minRating, best35maxRating) = getRaRange(best35);
    debugPrint('Best35 Rating范围: $best35minRating - $best35maxRating');

    double best55minDs = 0.0;
    double best55maxDs = 0.0;
    (best55minDs, best55maxDs) =
        getDifficultyRange(best55minRating, best55maxRating);
    if (minDsOverride != null && maxDsOverride != null) {
      best55minDs = minDsOverride;
      best55maxDs = maxDsOverride;
    }
    if (best55maxDs < best55minDs) best55maxDs = best55minDs;
    debugPrint('Best55 定数范围: $best55minDs - $best55maxDs');

    double best15minDs = 0.0;
    double best15maxDs = 0.0;
    (best15minDs, best15maxDs) =
        getDifficultyRange(best15minRating, best15maxRating);
    if (minDsOverride != null && maxDsOverride != null) {
      best15minDs = minDsOverride;
      best15maxDs = maxDsOverride;
    }
    if (best15maxDs < best15minDs) best15maxDs = best15minDs;
    debugPrint('Best15 定数范围: $best15minDs - $best15maxDs');

    // 若本地已同步后端全量 AWMC 标签目录（≥200 张谱面），无需逐张向代理补拉。
    var chartKeyToTagIdsMap = await AwmcChartTagService.getChartKeyToTagIdsMap();
    var songIdToTagIdsMap = await AwmcChartTagService.getSongIdToTagIdsMap();
    final hasBulkCatalog =
        await AwmcChartTagService.catalogChartCount() >= 200 ||
        chartKeyToTagIdsMap.length >= 200;

    if (!hasBulkCatalog) {
      int playerTaggedCount = 0;
      final missingPlayerKeys = <String>[];
      for (final record in filteredRecords) {
        final ids = RecommendByTagsService.collectChartTagIds(
          songId: record.songId.toString(),
          title: record.title,
          type: record.type,
          levelIndex: record.levelIndex,
          chartKeyToTagIdsMap: chartKeyToTagIdsMap,
          songIdToTagIdsMap: songIdToTagIdsMap,
        );
        if (ids.isNotEmpty) {
          playerTaggedCount++;
        } else {
          final awmcKey = AwmcChartTagService.chartKey(
            record.songId.toString(),
            record.levelIndex,
          );
          if (awmcKey != null) missingPlayerKeys.add(awmcKey);
        }
      }

      int prefetchUsed = 0;
      const int totalPrefetchBudget = 16;
      if (playerTaggedCount < 12 && missingPlayerKeys.isNotEmpty) {
        final budget = min(8, totalPrefetchBudget);
        prefetchUsed += await AwmcChartTagService.prefetchMissing(
          missingPlayerKeys,
          maxRequests: budget,
        );
        if (prefetchUsed > 0) {
          chartKeyToTagIdsMap =
              await AwmcChartTagService.getChartKeyToTagIdsMap();
          songIdToTagIdsMap = await AwmcChartTagService.getSongIdToTagIdsMap();
        }
      }

      final Map<String, RecordItem> playerRecordMap = {
        for (final record in userPlayDataRecords)
          '${record.songId}_${record.levelIndex}': record,
      };
      final best55Coverage = _inspectRangeTagCoverage(
        songs: songs,
        playerRecordMap: playerRecordMap,
        chartKeyToTagIdsMap: chartKeyToTagIdsMap,
        songIdToTagIdsMap: songIdToTagIdsMap,
        minDs: best55minDs,
        maxDs: best55maxDs,
        isNewOnly: false,
      );
      final best15Coverage = _inspectRangeTagCoverage(
        songs: songs,
        playerRecordMap: playerRecordMap,
        chartKeyToTagIdsMap: chartKeyToTagIdsMap,
        songIdToTagIdsMap: songIdToTagIdsMap,
        minDs: best15minDs,
        maxDs: best15maxDs,
        isNewOnly: true,
      );

      final remainingBudget = totalPrefetchBudget - prefetchUsed;
      if (remainingBudget > 0 &&
          (best55Coverage.taggedCount < 15 || best15Coverage.taggedCount < 8)) {
        final interleavedKeys = <String>[];
        final b55Missing = best55Coverage.missingKeys;
        final b15Missing = best15Coverage.missingKeys;
        final maxLen = max(b55Missing.length, b15Missing.length);
        for (int i = 0; i < maxLen; i++) {
          if (i < b55Missing.length) interleavedKeys.add(b55Missing[i]);
          if (i < b15Missing.length) interleavedKeys.add(b15Missing[i]);
          if (interleavedKeys.length >= remainingBudget * 2) break;
        }
        await AwmcChartTagService.prefetchMissing(
          interleavedKeys,
          maxRequests: remainingBudget,
        );
      }
    }

    // 预热完成后统一刷新一次完整映射并计算玩家向量与候选推荐。
    final tagIdToInfoMap = await AwmcChartTagService.getTagIdToInfoMap();
    chartKeyToTagIdsMap = await AwmcChartTagService.getChartKeyToTagIdsMap();
    songIdToTagIdsMap = await AwmcChartTagService.getSongIdToTagIdsMap();

    final songById = {for (final s in songs) s.id: s};
    final playerStructuralProfile =
        _PlayerStructuralProfile.fromRecords(filteredRecords, songById);

    Map<String, Map<String, double>> playerAbilityVectors =
        await calculatePlayerAbilityVectors(
      filteredRecords,
      tagIdToInfoMap: tagIdToInfoMap,
      chartKeyToTagIdsMap: chartKeyToTagIdsMap,
      songIdToTagIdsMap: songIdToTagIdsMap,
    );
    debugPrint('计算得到玩家能力向量: ${playerAbilityVectors.keys.toList()}');

    final Future<List<RecommendationResult>> best55Future =
        _calculateRecommendationsInternal(
      userPlayDataRecords,
      playerAbilityVectors,
      best55minDs,
      best55maxDs,
      best55minRating,
      best55maxRating,
      best35minRating,
      best35maxRating,
      false,
      best35RaMap,
      cachedSongs: songs,
      tagIdToInfoMap: tagIdToInfoMap,
      chartKeyToTagIdsMap: chartKeyToTagIdsMap,
      songIdToTagIdsMap: songIdToTagIdsMap,
      playerStructuralProfile: playerStructuralProfile,
    );

    final Future<List<RecommendationResult>> best15Future =
        _calculateRecommendationsInternal(
      userPlayDataRecords,
      playerAbilityVectors,
      best15minDs,
      best15maxDs,
      best15minRating,
      best15maxRating,
      best35minRating,
      best35maxRating,
      true,
      best15RaMap,
      cachedSongs: songs,
      tagIdToInfoMap: tagIdToInfoMap,
      chartKeyToTagIdsMap: chartKeyToTagIdsMap,
      songIdToTagIdsMap: songIdToTagIdsMap,
      playerStructuralProfile: playerStructuralProfile,
    );

    final best55Recommendations = await best55Future;
    debugPrint('计算得到 ${best55Recommendations.length} 条Best55推荐结果');

    final best15Recommendations = await best15Future;
    debugPrint('计算得到 ${best15Recommendations.length} 条Best15推荐结果');

    // 保存推荐结果到缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultMap = {
        'Best55': best55Recommendations.map((r) => r.toJson()).toList(),
        'Best15': best15Recommendations.map((r) => r.toJson()).toList(),
      };
      final resultJson = json.encode(resultMap);
      if (AccountSwitchService.isBusy || revision != AccountSwitchService.revision) {
        return defaultResult;
      }
      await prefs.setString(CacheKeyConstant.recommendationResults, resultJson);
      debugPrint('推荐结果已保存到缓存');
    } catch (e) {
      debugPrint('保存推荐结果到缓存失败: $e');
    }

    // 返回推荐结果
    return {
      'Best55': best55Recommendations,
      'Best15': best15Recommendations,
    };
  } catch (e, stackTrace) {
    // 全局异常捕获，打印详细错误信息便于排查
    debugPrint('推荐算法执行异常: $e');
    debugPrint('异常堆栈信息: $stackTrace');
    // 异常时返回空的推荐结果，避免崩溃
    return defaultResult;
  }
}
