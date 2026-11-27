import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../entity/DXRating/MaiTagsModel.dart';
import '../../l10n/AppMessages.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AwmcIdMap.dart';
import '../../utils/ChartDifficulty.dart';
import '../Library/CustomTagStore.dart';

class AwmcChartTagService {
  static const cachePrefix = 'awmc_chart_tags_v1:';
  static const _cacheDuration = Duration(days: 30);
  static const _catalogFileName = 'awmc_tags_catalog_v1.json';
  static const _catalogEtagKey = 'awmc_tags_catalog_etag_v1';
  static const _catalogSyncedAtKey = 'awmc_tags_catalog_synced_at_v1';
  static const _catalogSyncInterval = Duration(hours: 6);

  /// 本地缓存写入时递增，用于驱动聚合标签目录失效。
  static int _cacheRevision = 0;

  static int get cacheRevision => _cacheRevision;

  static Map<String, List<(int, String)>>? _catalogChartPairs;
  static int _catalogRevision = 0;
  static Future<bool>? _syncingCatalog;

  static MaiTagsEntity? _cachedEntity;
  static Map<String, List<int>>? _cachedSongIdToTagIdsMap;
  static Map<String, List<int>>? _cachedChartKeyToTagIdsMap;
  static int _entityCacheRev = -1;
  static int _entityCatalogRev = -1;
  static int _entityCustomRev = -1;
  static int _entitySongsCount = -1;

  static String? chartKey(String songId, int levelIndex) {
    final id = int.tryParse(songId.trim());
    final mapped = id == null ? null : AwmcIdMap.fromSongId(id);
    if (mapped == null ||
        mapped.kind == AwmcChartKind.utage ||
        levelIndex < 0 ||
        levelIndex > 4) {
      return null;
    }
    return '${mapped.baseSongId}:${mapped.kind.name}:${levelIndex + 2}';
  }

  /// 将 `baseSongId:standard|dx:level+2` 反解回 App 曲库 songId、类型和难度索引。
  static ({int songId, AwmcChartKind kind, int levelIndex})? parseChartKey(
      String chartKey) {
    final parts = chartKey.split(':');
    if (parts.length != 3) return null;
    final baseSongId = int.tryParse(parts[0]);
    final kind = switch (parts[1]) {
      'standard' => AwmcChartKind.standard,
      'dx' => AwmcChartKind.dx,
      _ => null,
    };
    final levelCode = int.tryParse(parts[2]);
    if (baseSongId == null || kind == null || levelCode == null) return null;
    final levelIndex = levelCode - 2;
    if (levelIndex < 0 || levelIndex > 4) return null;
    final mapped = AwmcIdMap.fromBaseSongId(baseSongId, kind);
    if (mapped == null) return null;
    return (songId: mapped.songId, kind: kind, levelIndex: levelIndex);
  }

  static void _invalidateAggregatedCache() {
    _cacheRevision++;
    _cachedEntity = null;
    _cachedSongIdToTagIdsMap = null;
    _cachedChartKeyToTagIdsMap = null;
  }

  static bool _isFreshCachedRaw(String? raw, int nowMs) {
    if (raw == null || raw.isEmpty) return false;
    try {
      final cached = jsonDecode(raw);
      if (cached is! Map || cached['tags'] is! Map) return false;
      final saved = cached['savedAt'];
      return saved is int && nowMs - saved < _cacheDuration.inMilliseconds;
    } on FormatException {
      return false;
    }
  }

  static Future<({Map? tags, bool ok, bool rateLimited})> _fetchAndCache(
    String chartKey,
    SharedPreferences prefs,
  ) async {
    final uri = Uri.parse(
        '${ApiUrls.BackendBaseUrl}/api/awmc-preview/charts/$chartKey/tags');
    try {
      final response = await ApiClient.get(uri);
      if (response.statusCode == 429) {
        return const (tags: null, ok: false, rateLimited: true);
      }
      final Map tags;
      if (response.statusCode == 404) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        if (payload is! Map ||
            !payload.containsKey('tags') ||
            payload['tags'] != null) {
          return const (tags: null, ok: false, rateLimited: false);
        }
        tags = const {};
      } else if (response.statusCode == 200) {
        final payload = jsonDecode(utf8.decode(response.bodyBytes));
        final data = payload is Map ? payload['tags'] : null;
        if (data is! Map) {
          return const (tags: null, ok: false, rateLimited: false);
        }
        tags = data;
      } else {
        return const (tags: null, ok: false, rateLimited: false);
      }
      await prefs.setString(
          '$cachePrefix$chartKey',
          jsonEncode({
            'savedAt': DateTime.now().millisecondsSinceEpoch,
            'tags': tags,
          }));
      _invalidateAggregatedCache();
      return (tags: tags, ok: true, rateLimited: false);
    } catch (_) {
      return const (tags: null, ok: false, rateLimited: false);
    }
  }

  /// 为缺少本地标签缓存的谱面批量预热 AWMC 标签（自动受并发与请求预算限制）。
  static Future<int> prefetchMissing(
    Iterable<String> chartKeys, {
    int maxRequests = 16,
    int concurrency = 4,
  }) async {
    if (maxRequests <= 0) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final seen = <String>{};
      final pending = <String>[];
      for (final rawKey in chartKeys) {
        final key = rawKey.trim();
        if (key.isEmpty || !seen.add(key)) continue;
        if (_isFreshCachedRaw(prefs.getString('$cachePrefix$key'), nowMs)) {
          continue;
        }
        pending.add(key);
        if (pending.length >= maxRequests) break;
      }
      if (pending.isEmpty) return 0;

      final safeConcurrency = concurrency < 1 ? 1 : concurrency;
      var loadedCount = 0;
      for (var i = 0; i < pending.length; i += safeConcurrency) {
        final end =
            i + safeConcurrency > pending.length ? pending.length : i + safeConcurrency;
        final batch = pending.sublist(i, end);
        final results = await Future.wait([
          for (final key in batch) _fetchAndCache(key, prefs),
        ]);
        var batchSucceeded = false;
        var rateLimited = false;
        for (final result in results) {
          if (result.ok) {
            loadedCount++;
            batchSucceeded = true;
          }
          if (result.rateLimited) {
            rateLimited = true;
          }
        }
        if (rateLimited || !batchSucceeded) {
          break;
        }
      }
      return loadedCount;
    } catch (_) {
      return 0;
    }
  }

  static Future<Map<String, List<Map<String, String>>>?> load(
      String chartKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$cachePrefix$chartKey';
      final raw = prefs.getString(key);
      Map? stale;
      if (raw != null) {
        try {
          final cached = jsonDecode(raw);
          if (cached is Map && cached['tags'] is Map) {
            stale = cached['tags'] as Map;
            final saved = cached['savedAt'];
            if (saved is int &&
                DateTime.now().millisecondsSinceEpoch - saved <
                    _cacheDuration.inMilliseconds) {
              return _group(stale);
            }
          }
        } on FormatException {
          // 旧缓存损坏时按网络结果重新保存。
        }
      }

      final fetched = await _fetchAndCache(chartKey, prefs);
      if (fetched.tags != null) {
        return _group(fetched.tags!);
      }
      return stale == null ? null : _group(stale);
    } catch (_) {
      return null;
    }
  }

  static Map<String, List<Map<String, String>>> _group(Map data) {
    final groups = <String, List<Map<String, String>>>{};
    void add(String group, Object? entry, String valueKey) {
      if (entry is! Map || entry['label'] is! String) return;
      final label = (entry['label'] as String).trim();
      if (label.isEmpty) return;
      final items = groups.putIfAbsent(group, () => []);
      if (items.any((item) => item['name'] == label)) return;
      items.add({
        'name': label,
        'description': entry[valueKey]?.toString() ?? 'AWMC',
        'source': 'https://v.wmc.pub/',
      });
    }

    add('难度', data['difficultyClassification'], 'estimatedLevel');
    for (final (field, group, valueKey) in [
      ('radarTags', '配置', 'score'),
      ('evaluationTags', '评价', 'score'),
      ('patterns', '配置', 'count'),
    ]) {
      final items = data[field];
      if (items is! List) continue;
      for (final item in items) {
        add(group, item, valueKey);
      }
    }
    return groups;
  }

  static Future<File?> _catalogFile() async {
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}${Platform.pathSeparator}$_catalogFileName');
    } catch (_) {
      return null;
    }
  }

  static Map<String, List<(int, String)>> _decodeCompactCatalog(Object? raw) {
    if (raw is! Map) return const {};
    final rawTags = raw['tags'];
    final rawCharts = raw['charts'];
    if (rawTags is! List || rawCharts is! Map) return const {};

    final palette = <(int, String)?>[];
    for (final item in rawTags) {
      if (item is List && item.length >= 2) {
        final group = item[0]?.toString().trim() ?? '';
        final label = item[1]?.toString().trim() ?? '';
        if (group.isNotEmpty && label.isNotEmpty) {
          palette.add((_groupIdOf(group), label));
          continue;
        }
      }
      palette.add(null);
    }

    final chartPairs = <String, List<(int, String)>>{};
    for (final entry in rawCharts.entries) {
      final key = entry.key.toString().trim();
      final indices = entry.value;
      if (key.isEmpty || indices is! List) continue;
      final pairs = <(int, String)>[];
      for (final rawIndex in indices) {
        if (rawIndex is! int || rawIndex < 0 || rawIndex >= palette.length) {
          continue;
        }
        final pair = palette[rawIndex];
        if (pair != null) pairs.add(pair);
      }
      if (pairs.isNotEmpty) {
        chartPairs[key] = pairs;
      }
    }
    return chartPairs;
  }

  static Future<Map<String, List<(int, String)>>> _loadCatalogChartPairs() async {
    final cached = _catalogChartPairs;
    if (cached != null) return cached;
    try {
      final file = await _catalogFile();
      if (file == null || !await file.exists()) {
        return _catalogChartPairs = const {};
      }
      final raw = await file.readAsString();
      if (raw.isEmpty) return _catalogChartPairs = const {};
      final decoded = _decodeCompactCatalog(jsonDecode(raw));
      return _catalogChartPairs = decoded;
    } catch (_) {
      return _catalogChartPairs = const {};
    }
  }

  /// 当前本地全量 AWMC 聚合包覆盖的谱面数量（未拉取或未开启服务端聚合时为 0）。
  static Future<int> catalogChartCount() async {
    final catalog = await _loadCatalogChartPairs();
    return catalog.length;
  }

  /// 从自家后端同步全量 AWMC 谱面标签快照（支持 ETag 与本地间隔节流，失败静默降级）。
  static Future<bool> syncCatalog({bool force = false}) {
    return _syncingCatalog ??= _doSyncCatalog(force: force).whenComplete(() {
      _syncingCatalog = null;
    });
  }

  static Future<bool> _doSyncCatalog({bool force = false}) async {
    try {
      final file = await _catalogFile();
      if (file == null) return false;
      final prefs = await SharedPreferences.getInstance();
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final syncedAt = prefs.getInt(_catalogSyncedAtKey);
      if (!force &&
          syncedAt != null &&
          nowMs - syncedAt < _catalogSyncInterval.inMilliseconds &&
          await file.exists()) {
        return true;
      }

      final etag = await file.exists() ? prefs.getString(_catalogEtagKey) : null;
      final headers = <String, String>{
        if (etag != null && etag.isNotEmpty) 'If-None-Match': etag,
      };
      final uri = Uri.parse('${ApiUrls.BackendBaseUrl}/api/awmc-preview/tags/catalog');
      final response = await ApiClient.get(
        uri,
        headers: headers,
        timeout: const Duration(seconds: 20),
      );
      if (response.statusCode == 304) {
        await prefs.setInt(_catalogSyncedAtKey, nowMs);
        return true;
      }
      if (response.statusCode != 200) {
        return false;
      }

      final bodyText = utf8.decode(response.bodyBytes);
      final parsed = jsonDecode(bodyText);
      final decoded = _decodeCompactCatalog(parsed);
      if (decoded.isEmpty) return false;

      await file.parent.create(recursive: true);
      final tempFile = File('${file.path}.tmp');
      await tempFile.writeAsString(bodyText, flush: true);
      await tempFile.rename(file.path);

      final nextEtag = response.headers['etag'];
      if (nextEtag != null && nextEtag.isNotEmpty) {
        await prefs.setString(_catalogEtagKey, nextEtag);
      } else {
        await prefs.remove(_catalogEtagKey);
      }
      await prefs.setInt(_catalogSyncedAtKey, nowMs);

      _catalogChartPairs = decoded;
      _catalogRevision++;
      _invalidateAggregatedCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 读取本地已缓存的 AWMC 谱面标签（只保留配置与评价分组，供全局推荐与弱项分析复用）。
  static Future<Map<String, Set<String>>> loadAllCachedTagLabels() async {
    try {
      final result = <String, Set<String>>{};
      final catalog = await _loadCatalogChartPairs();
      for (final entry in catalog.entries) {
        final labels = <String>{
          for (final pair in entry.value)
            if (pair.$1 == _groupConfig || pair.$1 == _groupEvaluation) pair.$2,
        };
        if (labels.isNotEmpty) result[entry.key] = labels;
      }

      final prefs = await SharedPreferences.getInstance();
      final rawEntries = <String, String>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(cachePrefix)) continue;
        final value = prefs.getString(key);
        if (value != null) rawEntries[key] = value;
      }
      final local = decodeCachedTagLabels(rawEntries);
      result.addAll(local);
      return result;
    } catch (_) {
      return const {};
    }
  }

  @visibleForTesting
  static Map<String, Set<String>> decodeCachedTagLabels(
    Map<String, String> rawEntries, {
    int? nowMs,
  }) {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final result = <String, Set<String>>{};
    for (final entry in rawEntries.entries) {
      if (!entry.key.startsWith(cachePrefix)) continue;
      final chartKey = entry.key.substring(cachePrefix.length);
      if (chartKey.isEmpty) continue;
      try {
        final cached = jsonDecode(entry.value);
        if (cached is! Map || cached['tags'] is! Map) continue;
        final saved = cached['savedAt'];
        if (saved is! int || now - saved >= _cacheDuration.inMilliseconds) {
          continue;
        }
        final grouped = _group(cached['tags'] as Map);
        final labels = <String>{
          for (final groupName in const ['配置', '评价'])
            ...?grouped[groupName]
                ?.map((item) => item['name'] ?? '')
                .where((s) => s.isNotEmpty),
        };
        if (labels.isNotEmpty) result[chartKey] = labels;
      } on FormatException {
        // 损坏条目静默跳过，避免影响其余谱面。
      }
    }
    return result;
  }

  // ── 基于 AWMC 缓存与自定义标签的统一标签目录 ──────────────────────────────

  static const int _groupConfig = 1;
  static const int _groupDifficulty = 2;
  static const int _groupEvaluation = 3;

  static int _groupIdOf(String groupName) => switch (groupName) {
        '难度' => _groupDifficulty,
        '评价' => _groupEvaluation,
        _ => _groupConfig,
      };

  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode(input)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static int _allocateTagId(int groupId, String label, Set<int> usedIds) {
    // 保持在 [1, CustomTagStore.idBase - 1] 内，避免与自定义标签 ID 冲突。
    const maxId = CustomTagStore.idBase - 1;
    var candidate = (_fnv1a('$groupId:$label') % maxId) + 1;
    while (!usedIds.add(candidate)) {
      candidate = (candidate % maxId) + 1;
    }
    return candidate;
  }

  static LocalizedName _sameName(String text) =>
      LocalizedName(en: text, ja: text, ko: text, zhHans: text);

  static LocalizedDescription _sameDesc(String text) =>
      LocalizedDescription(en: text, ja: text, ko: text, zhHans: text);

  /// 聚合本地已缓存的 AWMC 谱面标签与用户自定义标签，生成全应用通用的标签目录。
  static Future<MaiTagsEntity?> getTagsEntity() async {
    try {
      final store = CustomTagStore.instance;
      await store.ensureLoaded();
      final songs = await MaimaiMusicDataManager().getCachedSongs() ?? const [];
      if (_cachedEntity != null &&
          _entityCacheRev == _cacheRevision &&
          _entityCatalogRev == _catalogRevision &&
          _entityCustomRev == store.revision &&
          _entitySongsCount == songs.length) {
        return _cachedEntity;
      }

      final catalog = await _loadCatalogChartPairs();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final songById = {for (final s in songs) s.id: s};

      // chartKey → 去重后的 (groupId, label) 列表，单曲详情新鲜缓存可覆盖全量包。
      final mergedByChartKey = <String, List<(int, String)>>{
        for (final entry in catalog.entries) entry.key: entry.value,
      };

      for (final prefKey in prefs.getKeys()) {
        if (!prefKey.startsWith(cachePrefix)) continue;
        final key = prefKey.substring(cachePrefix.length);
        if (key.isEmpty) continue;
        final raw = prefs.getString(prefKey);
        if (raw == null || raw.isEmpty) continue;
        try {
          final cached = jsonDecode(raw);
          if (cached is! Map || cached['tags'] is! Map) continue;
          final saved = cached['savedAt'];
          if (saved is! int || now - saved >= _cacheDuration.inMilliseconds) {
            continue;
          }
          final grouped = _group(cached['tags'] as Map);
          final pairs = <(int, String)>[];
          for (final entry in grouped.entries) {
            final gid = _groupIdOf(entry.key);
            for (final item in entry.value) {
              final label = (item['name'] ?? '').trim();
              if (label.isNotEmpty) pairs.add((gid, label));
            }
          }
          if (pairs.isEmpty) {
            mergedByChartKey.remove(key);
          } else {
            mergedByChartKey[key] = pairs;
          }
        } on FormatException {
          // 跳过损坏缓存条目。
        }
      }

      // (groupId, label) → 关联谱面的 chartKey 列表
      final tagCharts = <(int, String), List<String>>{};
      final chartKeyTags = <String, List<(int, String)>>{};
      for (final entry in mergedByChartKey.entries) {
        final key = entry.key;
        final pairs = entry.value;
        if (pairs.isEmpty) continue;
        chartKeyTags[key] = pairs;
        for (final pair in pairs) {
          (tagCharts[pair] ??= <String>[]).add(key);
        }
      }

      // 稳定排序后分配确定性 ID，确保同分自选缓存键跨重启稳定。
      final sortedPairs = tagCharts.keys.toList()
        ..sort((a, b) {
          final byGroup = a.$1.compareTo(b.$1);
          if (byGroup != 0) return byGroup;
          final byCount =
              (tagCharts[b]?.length ?? 0).compareTo(tagCharts[a]?.length ?? 0);
          if (byCount != 0) return byCount;
          return a.$2.compareTo(b.$2);
        });

      final usedIds = <int>{};
      final pairToId = <(int, String), int>{};
      final tagItems = <TagItem>[];
      final usedGroupIds = <int>{};

      for (final pair in sortedPairs) {
        final id = _allocateTagId(pair.$1, pair.$2, usedIds);
        pairToId[pair] = id;
        usedGroupIds.add(pair.$1);
        final count = tagCharts[pair]?.length ?? 0;
        tagItems.add(TagItem(
          id: id,
          localizedName: _sameName(pair.$2),
          localizedDescription: _sameDesc('AWMC · $count 张谱面'),
          groupId: pair.$1,
        ));
      }

      final tagGroups = <TagGroupItem>[
        if (usedGroupIds.contains(_groupConfig))
          TagGroupItem(
              id: _groupConfig,
              localizedName: _sameName('配置'),
              color: '#4CAF50'),
        if (usedGroupIds.contains(_groupDifficulty))
          TagGroupItem(
              id: _groupDifficulty,
              localizedName: _sameName('难度'),
              color: '#FF9800'),
        if (usedGroupIds.contains(_groupEvaluation))
          TagGroupItem(
              id: _groupEvaluation,
              localizedName: _sameName('评价'),
              color: '#2196F3'),
      ];

      final tagSongs = <TagSongItem>[];
      final chartKeyToIds = <String, List<int>>{};

      for (final entry in chartKeyTags.entries) {
        final key = entry.key;
        final ids = <int>[
          for (final pair in entry.value)
            if (pairToId[pair] != null) pairToId[pair]!,
        ];
        if (ids.isEmpty) continue;
        chartKeyToIds[key] = ids;

        final parsed = parseChartKey(key);
        if (parsed == null) continue;
        final song = songById[parsed.songId.toString()];
        if (song == null) continue;
        final sheetType = parsed.kind == AwmcChartKind.dx ? 'dx' : 'std';
        final sheetDifficulty = ChartDifficulty.apiNameOf(parsed.levelIndex);
        for (final tagId in ids) {
          tagSongs.add(TagSongItem(
            songId: song.title,
            sheetType: sheetType,
            sheetDifficulty: sheetDifficulty,
            tagId: tagId,
          ));
        }
      }

      final base = tagItems.isEmpty
          ? null
          : MaiTagsEntity(
              tags: tagItems,
              tagGroups: tagGroups,
              tagSongs: tagSongs,
            );

      final merged = (base == null && store.tags.isEmpty)
          ? null
          : store.mergeInto(base, appL10n.customTagGroupName);

      _cachedEntity = merged;
      _cachedChartKeyToTagIdsMap = chartKeyToIds;
      _cachedSongIdToTagIdsMap =
          merged == null ? const {} : buildSongIdToTagIdsMap(merged);
      _entityCacheRev = _cacheRevision;
      _entityCatalogRev = _catalogRevision;
      _entityCustomRev = store.revision;
      _entitySongsCount = songs.length;
      return merged;
    } catch (e) {
      debugPrint('聚合 AWMC 标签数据失败: $e');
      return null;
    }
  }

  /// `chartKey` (`baseSongId:standard|dx:level+2`) → AWMC 标签 ID 列表。
  static Future<Map<String, List<int>>> getChartKeyToTagIdsMap() async {
    await getTagsEntity();
    return _cachedChartKeyToTagIdsMap ?? const {};
  }

  /// `曲名#sheetType#sheetDifficulty` → 标签 ID 列表（含 AWMC 与自定义标签）。
  static Future<Map<String, List<int>>> getSongIdToTagIdsMap() async {
    final entity = await getTagsEntity();
    if (entity == null) return const {};
    return _cachedSongIdToTagIdsMap ?? buildSongIdToTagIdsMap(entity);
  }

  static Future<Map<int, String>> getGroupIdToNameMap() async {
    final entity = await getTagsEntity();
    if (entity == null) return const {};
    return {
      for (final group in entity.tagGroups)
        group.id: group.localizedName.zhHans,
    };
  }

  static Future<Map<int, String>> getTagIdToNameMap() async {
    final entity = await getTagsEntity();
    if (entity == null) return const {};
    return {
      for (final tag in entity.tags) tag.id: tag.localizedName.zhHans,
    };
  }

  static Future<Map<int, (String, int)>> getTagIdToInfoMap() async {
    final entity = await getTagsEntity();
    if (entity == null) return const {};
    return {
      for (final tag in entity.tags)
        tag.id: (tag.localizedName.zhHans, tag.groupId),
    };
  }

  static Map<String, List<int>> buildSongIdToTagIdsMap(
      MaiTagsEntity maiTagsEntity) {
    final songIdToTagIdsMap = <String, List<int>>{};
    for (final tagSong in maiTagsEntity.tagSongs) {
      final songKey =
          '${tagSong.songId}#${tagSong.sheetType}#${tagSong.sheetDifficulty}';
      (songIdToTagIdsMap[songKey] ??= []).add(tagSong.tagId);
    }
    return songIdToTagIdsMap;
  }
}
