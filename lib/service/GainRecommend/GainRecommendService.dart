import 'package:flutter/foundation.dart';

import '../../entity/DivingFish/RecordItem.dart';
import '../../entity/DivingFish/Song.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../manager/DivingFish/UserPlayDataManager.dart';
import '../../utils/SongFilterUtil.dart';
import 'GainRecommendCore.dart';

/// 一次吃分推荐所需的全部数据（已在后台 isolate 里算好候选）。
class GainRecommendSnapshot {
  final GainBuildResult result;
  final Map<GainRoute, List<GainCandidate>> sorted;

  /// 上游缓存里的 Rating（只做对照展示，不参与计算）。
  final int sourceRating;

  /// 成绩里找不到曲库条目、按旧曲（B35）处理的谱面数。
  final int unmatchedRecords;

  const GainRecommendSnapshot({
    required this.result,
    required this.sorted,
    required this.sourceRating,
    required this.unmatchedRecords,
  });
}

class GainRecommendLoadException implements Exception {
  final String message;
  const GainRecommendLoadException(this.message);
  @override
  String toString() => message;
}

class GainRecommendService {
  GainRecommendService._();

  /// 从本地缓存的成绩与曲库生成候选。缺数据时抛 [GainRecommendLoadException]。
  static Future<GainRecommendSnapshot> load() async {
    final userData = await UserPlayDataManager().getCachedUserPlayData();
    final rawRecords = userData?['records'];
    if (rawRecords is! List || rawRecords.isEmpty) {
      throw const GainRecommendLoadException('还没有成绩数据，请先登录并刷新数据');
    }
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? const [];
    if (songs.isEmpty) {
      throw const GainRecommendLoadException('曲库数据为空，请先刷新数据');
    }
    final sourceRating = userData?['rating'];
    final input = buildInput(
      [
        for (final item in rawRecords)
          if (item is Map<String, dynamic>) RecordItem.fromJson(item)
      ],
      songs,
    );
    final result = await compute(_build, input.$1);
    return GainRecommendSnapshot(
      result: result.$1,
      sorted: result.$2,
      sourceRating: sourceRating is int ? sourceRating : 0,
      unmatchedRecords: input.$2,
    );
  }

  static (GainBuildResult, Map<GainRoute, List<GainCandidate>>) _build(
      GainInput input) {
    final result = buildGainCandidates(input);
    return (result, sortGainCandidates(result.candidates));
  }

  /// 把 App 的成绩 / 曲库实体转换成核心输入。
  ///
  /// 新旧曲分区取曲库 `basic_info.is_new`；成绩里的曲目在曲库里找不到时
  /// 与 Best50 页一致按旧曲处理，并计数供页面提示。宴会场与非正曲剔除。
  /// 返回 (输入, 未匹配曲库的成绩数)。
  @visibleForTesting
  static (GainInput, int) buildInput(
      List<RecordItem> records, List<Song> songs) {
    final index = {for (final s in songs) s.id: s};
    var unmatched = 0;
    final chartRecords = <GainChartRecord>[];
    for (final r in records) {
      final id = r.songId.toString();
      if (SongFilterUtil.isUtageSong(id)) continue;
      final song = index[id];
      if (song != null && SongFilterUtil.isExtra(song)) continue;
      if (song == null) unmatched++;
      chartRecords.add(GainChartRecord(
        songId: r.songId,
        levelIndex: r.levelIndex,
        title: r.title,
        level: r.level,
        type: song?.type ?? r.type,
        ds: r.ds,
        achievements: r.achievements.toDouble(),
        isNew: song?.basicInfo.isNew ?? false,
      ));
    }
    final played = {for (final r in chartRecords) r.key};
    final pool = <GainExploreChart>[];
    for (final song in songs) {
      if (SongFilterUtil.isExtra(song)) continue;
      final songId = int.tryParse(song.id);
      if (songId == null) continue;
      for (var i = 0; i < song.ds.length; i++) {
        final ds = song.ds[i];
        if (ds <= 0 || played.contains(GainChartKey(songId, i))) continue;
        pool.add(GainExploreChart(
          songId: songId,
          levelIndex: i,
          title: song.basicInfo.title.isNotEmpty
              ? song.basicInfo.title
              : song.title,
          level: i < song.level.length ? song.level[i] : '',
          type: song.type,
          ds: ds,
          isNew: song.basicInfo.isNew,
        ));
      }
    }
    // 水鱼 / 落雪返回的是全量成绩列表，缺记录可视为「未记录成绩」。
    return (
      GainInput(records: chartRecords, complete: true, explorePool: pool),
      unmatched,
    );
  }
}
