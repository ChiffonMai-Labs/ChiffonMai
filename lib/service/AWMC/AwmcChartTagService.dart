import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AwmcIdMap.dart';

class AwmcChartTagService {
  static const cachePrefix = 'awmc_chart_tags_v1:';
  static const _cacheDuration = Duration(days: 30);

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

      final uri = Uri.parse(
          '${ApiUrls.BackendBaseUrl}/api/awmc-preview/charts/$chartKey/tags');
      try {
        final response = await ApiClient.get(uri);
        final Map tags;
        if (response.statusCode == 404) {
          final payload = jsonDecode(utf8.decode(response.bodyBytes));
          if (payload is! Map ||
              !payload.containsKey('tags') ||
              payload['tags'] != null) {
            return stale == null ? null : _group(stale);
          }
          tags = const {};
        } else if (response.statusCode == 200) {
          final payload = jsonDecode(utf8.decode(response.bodyBytes));
          final data = payload is Map ? payload['tags'] : null;
          if (data is! Map) return stale == null ? null : _group(stale);
          tags = data;
        } else {
          return stale == null ? null : _group(stale);
        }
        await prefs.setString(
            key,
            jsonEncode({
              'savedAt': DateTime.now().millisecondsSinceEpoch,
              'tags': tags,
            }));
        return _group(tags);
      } catch (_) {
        return stale == null ? null : _group(stale);
      }
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

  /// 读取本地已缓存的 AWMC 谱面标签（只保留配置与评价分组，供全局推荐与弱项分析复用）。
  static Future<Map<String, Set<String>>> loadAllCachedTagLabels() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawEntries = <String, String>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(cachePrefix)) continue;
        final value = prefs.getString(key);
        if (value != null) rawEntries[key] = value;
      }
      return decodeCachedTagLabels(rawEntries);
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
            ...?grouped[groupName]?.map((item) => item['name'] ?? '').where((s) => s.isNotEmpty),
        };
        if (labels.isNotEmpty) result[chartKey] = labels;
      } on FormatException {
        // 损坏条目静默跳过，避免影响其余谱面。
      }
    }
    return result;
  }
}
