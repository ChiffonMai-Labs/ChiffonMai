import 'package:flutter/foundation.dart';

import '../../entity/DXRating/DXDataEntity.dart';
import '../../entity/DXRating/MaiTagsModel.dart';
import '../../entity/DivingFish/Song.dart';
import '../../manager/DXDataManager.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../manager/DivingFish/UserPlayDataManager.dart';
import '../../manager/MaiTagsManager.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/SongFilterUtil.dart';
import '../AWMC/AwmcChartTagService.dart';
import 'GainRecommendCore.dart';

typedef ChartCoverage = ({
  String level,
  int played,
  int total,
  List<GainExploreChart> missing,
});

typedef WeaknessPracticeChart = ({
  int songId,
  int levelIndex,
  String title,
  String level,
  double ds,
  double? achievements,
});

typedef WeaknessTagItem = ({
  String tag,
  int playedCount,
  double avgAchievement,
  double delta,
  int sssCount,
  List<WeaknessPracticeChart> practiceCharts,
});

typedef B50Edge = ({
  GainChartRecord record,
  bool selected,
  bool usesCurrentConstant,
  int floor,
  int raNeeded,
  double? target,
  int? gain,
});

typedef B50Audit = ({
  GainBaseline baseline,
  List<B50Edge> edges,
  int fallback,
  int ratingDifference,
});

enum CooperativeContributor { mine, friend, both }

class CooperativeBest50 {
  const CooperativeBest50(this.baseline, this.contributors);

  final GainBaseline baseline;
  final Map<GainChartKey, CooperativeContributor> contributors;

  static Future<CooperativeBest50?> fromComparison(
      List mine, List friend) async {
    try {
      final songs = await MaimaiMusicDataManager().getCachedSongs();
      if (songs == null || songs.isEmpty) return null;
      return await compute(_build, (mine, friend, songs));
    } on Exception {
      return null;
    }
  }

  static CooperativeBest50? _build((List, List, List<Song>) input) {
    final (mine, friend, songs) = input;
    final index = {for (final song in songs) int.tryParse(song.id): song};
    final myRecords = ScoreInsights.comparableRecords(mine, index);
    final friendRecords = ScoreInsights.comparableRecords(friend, index);
    if (myRecords.isEmpty || friendRecords.isEmpty) return null;
    final best = {for (final record in myRecords) record.key: record};
    final contributors = {
      for (final record in myRecords) record.key: CooperativeContributor.mine,
    };
    for (final record in friendRecords) {
      final previous = best[record.key];
      if (previous != null && previous.achievements == record.achievements) {
        contributors[record.key] = CooperativeContributor.both;
      } else if (previous == null ||
          record.achievements > previous.achievements) {
        best[record.key] = record;
        contributors[record.key] = CooperativeContributor.friend;
      }
    }
    final baseline = computeGainBaseline(normalizeGainRecords(best.values));
    return CooperativeBest50(baseline, {
      for (final record in [...baseline.b35, ...baseline.b15])
        record.key: contributors[record.key]!,
    });
  }
}

class ScoreInsights {
  const ScoreInsights({
    required this.records,
    required this.coverage,
    required this.coverageByGenre,
    required this.fullCombo,
    required this.sss,
    required this.history,
    this.weaknesses = const [],
    this.hasAwmcCachedTags = false,
  });

  final List<GainChartRecord> records;
  final List<ChartCoverage> coverage;
  final Map<String, List<ChartCoverage>> coverageByGenre;
  final int fullCombo;
  final int sss;
  final DXDataEntity? history;
  final List<WeaknessTagItem> weaknesses;
  final bool hasAwmcCachedTags;

  List<String> get historicalVersions {
    final versions = history?.versions.toList() ?? [];
    versions.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
    return {for (final version in versions) version.version}.toList();
  }

  static Future<ScoreInsights?> load() async {
    final data = await UserPlayDataManager().getCachedUserPlayData();
    final raw = data?['records'];
    if (raw is! List) return null;
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? [];
    if (songs.isEmpty) return null;

    Map<String, Set<String>> awmcTags = const {};
    MaiTagsEntity? maiTags;
    try {
      awmcTags = await AwmcChartTagService.loadAllCachedTagLabels();
    } catch (_) {}
    try {
      maiTags = await MaiTagsManager().getTags();
    } catch (_) {}

    final chartTags = _buildChartTags(songs, awmcTags, maiTags);
    final calculated = await compute(_build, (songs, raw, chartTags));
    return ScoreInsights(
      records: calculated.records,
      coverage: calculated.coverage,
      coverageByGenre: calculated.coverageByGenre,
      fullCombo: calculated.fullCombo,
      sss: calculated.sss,
      history: await DXDataManager().readCached(),
      weaknesses: calculated.weaknesses,
      hasAwmcCachedTags: awmcTags.isNotEmpty,
    );
  }

  static Map<GainChartKey, Set<String>> _buildChartTags(
    List<Song> songs,
    Map<String, Set<String>> awmcTags,
    MaiTagsEntity? maiTags,
  ) {
    final maiSongTags = <String, Set<String>>{};
    if (maiTags != null) {
      final tagNames = <int, String>{
        for (final tag in maiTags.tags)
          // 跳过“难度”分组（groupId == 2），只分析配置与评价类弱项。
          if (tag.groupId != 2 && tag.localizedName.zhHans.trim().isNotEmpty)
            tag.id: tag.localizedName.zhHans.trim(),
      };
      for (final ts in maiTags.tagSongs) {
        final name = tagNames[ts.tagId];
        if (name == null) continue;
        final key = '${ts.songId}#${ts.sheetType}#${ts.sheetDifficulty}';
        (maiSongTags[key] ??= <String>{}).add(name);
      }
    }

    final result = <GainChartKey, Set<String>>{};
    for (final song in songs) {
      final id = int.tryParse(song.id);
      if (id == null ||
          SongFilterUtil.isExtra(song) ||
          ChartDifficulty.isUtageSong(id, type: song.type)) {
        continue;
      }
      final sheetType = song.type == 'DX' ? 'dx' : 'std';
      for (final (level, ds) in song.ds.indexed) {
        if (!ChartDifficulty.isStandard(level) || !ds.isFinite || ds <= 0) {
          continue;
        }
        final awmcKey = AwmcChartTagService.chartKey(song.id, level);
        final awmcLabels = awmcKey == null ? null : awmcTags[awmcKey];
        if (awmcLabels != null && awmcLabels.isNotEmpty) {
          result[GainChartKey(id, level)] = awmcLabels;
          continue;
        }
        final diffName = ChartDifficulty.apiNameByIndex[level];
        if (diffName == null) continue;
        final maiLabels = maiSongTags['${song.title}#$sheetType#$diffName'];
        if (maiLabels != null && maiLabels.isNotEmpty) {
          result[GainChartKey(id, level)] = maiLabels;
        }
      }
    }
    return result;
  }

  static ({
    List<GainChartRecord> records,
    List<ChartCoverage> coverage,
    Map<String, List<ChartCoverage>> coverageByGenre,
    int fullCombo,
    int sss,
    List<WeaknessTagItem> weaknesses,
  }) _build((List<Song>, List, Map<GainChartKey, Set<String>>) input) {
    final (songs, raw, chartTags) = input;
    final index = {for (final song in songs) int.tryParse(song.id): song};
    final saved = _readComparableRecords(raw, index);
    final records = normalizeGainRecords(saved);
    final played = saved.map((record) => record.key).toSet();
    final combos = <GainChartKey>{};
    for (final row in raw.whereType<Map>()) {
      final songId = int.tryParse('${row['song_id']}');
      final level = ChartDifficulty.parseStandardIndex(row['level_index']);
      if (songId == null || level == null) continue;
      final key = GainChartKey(songId, level);
      if (played.contains(key) &&
          const {'fc', 'fcp', 'ap', 'app'}
              .contains('${row['fc']}'.toLowerCase())) {
        combos.add(key);
      }
    }
    final totals = <String, Map<String, int>>{};
    final missing = <String, Map<String, List<GainExploreChart>>>{};
    for (final song in index.values) {
      final id = int.tryParse(song.id);
      if (id == null ||
          SongFilterUtil.isExtra(song) ||
          ChartDifficulty.isUtageSong(id, type: song.type)) {
        continue;
      }
      for (final (level, ds) in song.ds.indexed) {
        if (!ChartDifficulty.isStandard(level) ||
            !ds.isFinite ||
            ds <= 0 ||
            level >= song.level.length) {
          continue;
        }
        final label = song.level[level];
        if (label.isEmpty) continue;
        final genre = song.basicInfo.genre.trim();
        final chart = played.contains(GainChartKey(id, level))
            ? null
            : GainExploreChart(
                songId: id,
                levelIndex: level,
                title: song.title,
                level: label,
                ds: ds,
                isNew: song.basicInfo.isNew,
                type: song.type,
              );
        for (final group in ['', if (genre.isNotEmpty) genre]) {
          (totals[group] ??= {})
              .update(label, (count) => count + 1, ifAbsent: () => 1);
          if (chart != null) {
            ((missing[group] ??= {})[label] ??= []).add(chart);
          }
        }
      }
    }
    double order(String label) =>
        double.tryParse(label.replaceAll('+', '.5')) ?? -1;
    List<ChartCoverage> coverageFor(String genre) {
      final byLevel = totals[genre] ?? const <String, int>{};
      final levels = byLevel.keys.toList()
        ..sort((a, b) => order(b).compareTo(order(a)));
      return [
        for (final level in levels)
          (
            level: level,
            played: byLevel[level]! - (missing[genre]?[level]?.length ?? 0),
            total: byLevel[level]!,
            missing: missing[genre]?[level] ?? [],
          ),
      ];
    }

    return (
      records: records,
      coverage: coverageFor(''),
      coverageByGenre: {
        for (final genre in totals.keys.where((genre) => genre.isNotEmpty))
          genre: coverageFor(genre),
      },
      fullCombo: combos.length,
      sss: records.where((record) => record.achievements >= 100).length,
      weaknesses: computeWeaknesses(
        records: records,
        songs: songs,
        chartTags: chartTags,
      ),
    );
  }

  /// 按同定数区间（±0.3）个人平均达成率为基线，定位偏弱标签并给出可练习谱面处方。
  static List<WeaknessTagItem> computeWeaknesses({
    required List<GainChartRecord> records,
    required List<Song> songs,
    required Map<GainChartKey, Set<String>> chartTags,
  }) {
    if (records.isEmpty || chartTags.isEmpty) return const [];
    final playedByKey = {for (final r in records) r.key: r};
    final overallMean =
        records.fold<double>(0, (s, r) => s + r.achievements) / records.length;

    final tagStats = <String, List<(GainChartRecord, double)>>{};
    for (final record in records) {
      final tags = chartTags[record.key];
      if (tags == null || tags.isEmpty) continue;
      double neighborSum = 0;
      int neighborCount = 0;
      for (final other in records) {
        if ((other.ds - record.ds).abs() <= 0.3) {
          neighborSum += other.achievements;
          neighborCount++;
        }
      }
      final expected =
          neighborCount >= 3 ? neighborSum / neighborCount : overallMean;
      final diff = record.achievements - expected;
      for (final tag in tags) {
        (tagStats[tag] ??= []).add((record, diff));
      }
    }

    final qualified = <({String tag, int count, double avg, double delta, int sss})>[];
    for (final entry in tagStats.entries) {
      final items = entry.value;
      if (items.length < 3) continue;
      var achvSum = 0.0;
      var diffSum = 0.0;
      var sss = 0;
      for (final (record, diff) in items) {
        achvSum += record.achievements;
        diffSum += diff;
        if (record.achievements >= 100.0) sss++;
      }
      qualified.add((
        tag: entry.key,
        count: items.length,
        avg: achvSum / items.length,
        delta: diffSum / items.length,
        sss: sss,
      ));
    }
    if (qualified.isEmpty) return const [];

    qualified.sort((a, b) {
      final c = a.delta.compareTo(b.delta);
      return c != 0 ? c : b.count.compareTo(a.count);
    });
    final weakOnly = qualified.where((e) => e.delta < -0.05).toList();
    final selectedTags = (weakOnly.isNotEmpty ? weakOnly : qualified).take(5);

    final baseline = computeGainBaseline(records);
    final b50 = [...baseline.b35, ...baseline.b15];
    final pool = b50.isNotEmpty ? b50 : records;
    final dsList = [for (final r in pool) r.ds]..sort();
    final comfortDs = dsList[dsList.length ~/ 2];

    final practiceByTag = <String, List<WeaknessPracticeChart>>{};
    for (final tagEntry in selectedTags) {
      practiceByTag[tagEntry.tag] = [];
    }

    for (final song in songs) {
      final id = int.tryParse(song.id);
      if (id == null ||
          SongFilterUtil.isExtra(song) ||
          ChartDifficulty.isUtageSong(id, type: song.type)) {
        continue;
      }
      for (final (level, ds) in song.ds.indexed) {
        if (!ChartDifficulty.isStandard(level) ||
            !ds.isFinite ||
            ds <= 0 ||
            level >= song.level.length ||
            ds < comfortDs - 0.5 ||
            ds > comfortDs + 0.3) {
          continue;
        }
        final key = GainChartKey(id, level);
        final tags = chartTags[key];
        if (tags == null || tags.isEmpty) continue;
        final played = playedByKey[key];
        if (played != null && played.achievements >= 100.0) continue;
        final candidate = (
          songId: id,
          levelIndex: level,
          title: song.title,
          level: song.level[level],
          ds: ds,
          achievements: played?.achievements,
        );
        for (final tag in tags) {
          practiceByTag[tag]?.add(candidate);
        }
      }
    }

    return [
      for (final item in selectedTags)
        (
          tag: item.tag,
          playedCount: item.count,
          avgAchievement: item.avg,
          delta: item.delta,
          sssCount: item.sss,
          practiceCharts: (() {
            final list = practiceByTag[item.tag] ?? const [];
            list.sort((a, b) {
              final d = (a.ds - comfortDs).abs().compareTo((b.ds - comfortDs).abs());
              if (d != 0) return d;
              return (a.achievements ?? -1).compareTo(b.achievements ?? -1);
            });
            return list.take(5).toList();
          })(),
        ),
    ];
  }

  /// 统一用当前曲库的谱面定数和分区，以便比较来自不同查分器的成绩。
  static List<GainChartRecord> comparableRecords(
    List raw,
    Map<int?, Song> songs,
  ) =>
      normalizeGainRecords(_readComparableRecords(raw, songs));

  static List<GainChartRecord> _readComparableRecords(
    List raw,
    Map<int?, Song> songs,
  ) {
    final parsed = <GainChartRecord>[];
    for (final row in raw.whereType<Map>()) {
      final songId = int.tryParse('${row['song_id']}');
      final level = ChartDifficulty.parseStandardIndex(row['level_index']);
      final achievement = double.tryParse('${row['achievements']}');
      final song = songs[songId];
      if (songId == null ||
          level == null ||
          achievement == null ||
          !achievement.isFinite ||
          achievement < 0 ||
          achievement > gainAchvMaxValid ||
          song == null ||
          SongFilterUtil.isExtra(song) ||
          ChartDifficulty.isUtageSong(songId, type: song.type) ||
          level >= song.ds.length) {
        continue;
      }
      final constant = song.ds[level];
      if (!constant.isFinite || constant <= 0) continue;
      parsed.add(GainChartRecord(
        songId: songId,
        levelIndex: level,
        title: song.title,
        level: level < song.level.length ? song.level[level] : '',
        ds: constant,
        achievements: achievement,
        isNew: song.basicInfo.isNew,
        type: song.type,
      ));
    }
    return parsed;
  }

  Future<B50Audit> audit(String? version) =>
      compute(_audit, (records, version == null ? null : history, version));

  static B50Audit _audit(
    (List<GainChartRecord>, DXDataEntity?, String?) input,
  ) {
    final (current, history, version) = input;
    final constants = <(GainChartKey, String), double>{};
    final ambiguous = <(GainChartKey, String)>{};
    (GainChartKey, String) keyFor(GainChartRecord record) =>
        (record.key, record.type == 'DX' ? 'dx' : 'std');
    final names = {
      'basic': 0,
      'advanced': 1,
      'expert': 2,
      'master': 3,
      'remaster': 4
    };
    if (history != null && version != null) {
      for (final song in history.songs) {
        for (final sheet in song.sheets) {
          final level = names[sheet.difficulty.toLowerCase()];
          final id = sheet.internalId;
          if (level == null || sheet.isSpecial || id <= 0 || id >= 100000) {
            continue;
          }
          final value = sheet.multiverInternalLevelValue[version] ??
              (sheet.version == version ? sheet.internalLevelValue : null);
          if (value == null || !value.isFinite || value <= 0) continue;
          final key = (GainChartKey(id, level), sheet.type);
          if (constants.containsKey(key) && constants[key] != value) {
            ambiguous.add(key);
          }
          constants[key] = value;
        }
      }
    }
    final fallback = <GainChartKey>{};
    final records = <GainChartRecord>[];
    for (final record in current) {
      final key = keyFor(record);
      final historical = ambiguous.contains(key) ? null : constants[key];
      if (version != null && historical == null) fallback.add(record.key);
      records.add(record.copyWith(ds: historical));
    }
    final baseline = computeGainBaseline(records);
    final edges = <B50Edge>[];
    for (final isNew in [false, true]) {
      final bucket = baseline.bucket(isNew);
      final selected = bucket.map((record) => record.key).toSet();
      final outsiders = records
          .where((record) =>
              record.isNew == isNew && !selected.contains(record.key))
          .toList()
        ..sort((a, b) {
          final ra = b.ra.compareTo(a.ra);
          return ra == 0 ? a.key.compareTo(b.key) : ra;
        });
      final floor = baseline.floor(isNew);
      final boundary = bucket.reversed.take(3).toList().reversed;
      for (final record in [...boundary, ...outsiders.take(5)]) {
        final inside = selected.contains(record.key);
        final sameRaEnters =
            bucket.isNotEmpty && record.key.compareTo(bucket.last.key) < 0;
        final target = enumerateGainTargets(record, baseline).firstOrNull;
        edges.add((
          record: record,
          selected: inside,
          usesCurrentConstant: fallback.contains(record.key),
          floor: floor,
          raNeeded: inside ? 0 : floor + (sameRaEnters ? 0 : 1) - record.ra,
          target: target?.$1,
          gain: target?.$2,
        ));
      }
    }
    final currentRating = version == null
        ? baseline.raSum
        : computeGainBaseline(
                current.map((record) => record.copyWith()).toList())
            .raSum;
    return (
      baseline: baseline,
      edges: edges,
      fallback: fallback.length,
      ratingDifference: baseline.raSum - currentRating,
    );
  }
}
