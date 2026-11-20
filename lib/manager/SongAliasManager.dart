import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../entity/SongAliasModel.dart';
import '../utils/ApiClient.dart';
import '../utils/AwmcIdMap.dart';
import 'DivingFish/MaimaiMusicDataManager.dart';

class SongAliasManager {
  static final instance = SongAliasManager._();
  SongAliasManager._();

  static const _keyAliases = 'song_aliases';
  static const _keyLastUpdate = 'alias_last_update';
  static const _keySource = 'alias_cache_source_v1';
  static const _maxAge = Duration(days: 7);
  static const _timeout = Duration(seconds: 10);

  /// 柚子社回退保留一个发布周期，可在构建时显式切回。
  static const useAwmc =
      bool.fromEnvironment('AWMC_ALIASES', defaultValue: true);

  Map<String, List<String>> _aliases = const {};
  Future<bool>? _refreshing;

  Map<String, List<String>> get aliases => _aliases;

  Future<void> init({bool refreshFromNetwork = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (_aliases.isEmpty) {
      final cached = prefs.getString(_keyAliases);
      if (cached != null) {
        final before = _aliases;
        try {
          final decoded = await compute(_decodeCache, cached);
          if (identical(_aliases, before)) _aliases = decoded;
        } catch (e) {
          debugPrint('[别名] 旧缓存读取失败: ${e.runtimeType}');
        }
      }
    }

    if (refreshFromNetwork && !_isCacheValid(prefs)) {
      if (_aliases.isEmpty) {
        await fetchFromApi();
      } else {
        unawaited(fetchFromApi());
      }
    }
  }

  static Map<String, List<String>> _decodeCache(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map
        .map((title, aliases) => MapEntry(title, List<String>.from(aliases)));
  }

  bool _isCacheValid(SharedPreferences prefs) {
    final lastUpdate = prefs.getInt(_keyLastUpdate);
    return _aliases.isNotEmpty &&
        prefs.getString(_keySource) == (useAwmc ? 'awmc' : 'yuzuchan') &&
        lastUpdate != null &&
        DateTime.now().millisecondsSinceEpoch - lastUpdate <=
            _maxAge.inMilliseconds;
  }

  Future<bool> fetchFromApi() =>
      _refreshing ??= _fetch().whenComplete(() => _refreshing = null);

  Future<bool> _fetch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var source = useAwmc ? 'awmc' : 'yuzuchan';
      var fresh = useAwmc ? await _fetchAwmc() : await _fetchYuzuchan();
      if (useAwmc &&
          fresh.isEmpty &&
          _aliases.isEmpty &&
          !prefs.containsKey(_keyAliases)) {
        fresh = await _fetchYuzuchan();
        source = 'yuzuchan';
      }
      if (fresh.isEmpty) return false;
      if (!await prefs.setString(_keyAliases, jsonEncode(fresh))) return false;
      _aliases = fresh;
      await prefs.setString(_keySource, source);
      await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      debugPrint('[别名] 刷新失败: ${e.runtimeType}');
      return false;
    }
  }

  Future<Map<String, List<String>>> _fetchAwmc() async {
    final songs = await MaimaiMusicDataManager().getCachedSongs();
    if (songs == null || songs.isEmpty) return const {};
    final titles = <int, Set<String>>{};
    for (final song in songs) {
      final id = int.tryParse(song.id.trim());
      final mapped = id == null ? null : AwmcIdMap.fromSongId(id);
      if (mapped == null || song.title.isEmpty) continue;
      titles.putIfAbsent(mapped.baseSongId, () => {}).add(song.title);
    }
    try {
      final response = await ApiClient.get(
        Uri.parse(ApiUrls.AwmcCommunityAliasesApi),
        timeout: _timeout,
      );
      if (response.statusCode != 200) return const {};
      return compute(_decodeAwmc, (response.bodyBytes, titles));
    } catch (e) {
      debugPrint('[别名] AWMC 社区别名请求失败: ${e.runtimeType}');
      return const {};
    }
  }

  static Map<String, List<String>> _decodeAwmc(
    (Uint8List, Map<int, Set<String>>) input,
  ) {
    final (bytes, titles) = input;
    final payload = jsonDecode(utf8.decode(bytes));
    final items = payload is Map ? payload['items'] : null;
    if (items is! List) return const {};

    final aliasesById = <int, Set<String>>{};
    for (final item in items) {
      if (item is! Map) continue;
      final baseId = int.tryParse('${item['baseSongId']}');
      final alias = item['text'];
      if (baseId == null ||
          !titles.containsKey(baseId) ||
          alias is! String ||
          alias.trim().isEmpty) {
        continue;
      }
      aliasesById.putIfAbsent(baseId, () => {}).add(alias.trim());
    }

    // 先按基础 ID 去重，再投影到现有搜索与猜歌使用的曲名索引。
    final byTitle = <String, Set<String>>{};
    for (final entry in aliasesById.entries) {
      for (final title in titles[entry.key]!) {
        byTitle.putIfAbsent(title, () => {}).addAll(entry.value);
      }
    }
    return byTitle.map((title, aliases) => MapEntry(title, aliases.toList()));
  }

  Future<Map<String, List<String>>> _fetchYuzuchan() async {
    final response =
        await ApiClient.get(Uri.parse(ApiUrls.SongAliasApi), timeout: _timeout);
    if (response.statusCode != 200) return const {};
    final payload =
        SongAliasResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    if (payload.code != 0) return const {};
    return {
      for (final entry in payload.content)
        if (entry.alias.isNotEmpty) entry.name: entry.alias.toSet().toList(),
    };
  }

  Future<bool> refresh({bool forceNetwork = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!forceNetwork && _isCacheValid(prefs)) return true;
    return fetchFromApi();
  }

  String? findSongNameByAlias(String input) {
    if (input.isEmpty) return null;
    final lower = input.toLowerCase();
    for (final entry in _aliases.entries) {
      if (entry.value.any((alias) => alias.toLowerCase() == lower)) {
        return entry.key;
      }
    }
    return null;
  }

  List<String>? findAliasesBySongName(String title) => _aliases[title];
}
