import 'dart:convert' show json, utf8;
import 'package:flutter/foundation.dart';
import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:my_first_flutter_app/entity/LuoXue/Collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';

class CollectionsManager {
  // 单例模式
  static final CollectionsManager _instance = CollectionsManager._internal();
  factory CollectionsManager() => _instance;
  CollectionsManager._internal();

  static const _cacheKeys = {
    'trophies': CacheKeyConstant.trophiesCollectionsCacheData,
    'icons': CacheKeyConstant.iconsCollectionsCacheData,
    'plates': CacheKeyConstant.platesCollectionsCacheData,
    'frames': CacheKeyConstant.framesCollectionsCacheData,
    'travelBuddies': CacheKeyConstant.travelBuddiesCollectionsCacheData,
    'partners': CacheKeyConstant.partnersCollectionsCacheData,
  };
  static const _lxnsUrls = {
    'trophies': ApiUrls.TrophiesCollectionApi,
    'icons': ApiUrls.IconsCollectionApi,
    'plates': ApiUrls.PlatesCollectionApi,
    'frames': ApiUrls.FramesCollectionApi,
  };
  static const _awmcTypes = {
    'travelBuddies': 'TravelBuddy',
    'partners': 'Partner',
  };
  static const _cacheAge =
      Duration(days: CacheKeyConstant.collectionCatalogTtlDays);

  final _inFlight = <String, Future<CollectionData?>>{};

  Future<CollectionData?> fetchTrophiesCollections(
          {bool forceNetwork = false}) =>
      fetchCatalog('trophies', forceNetwork: forceNetwork);

  Future<CollectionData?> fetchIconsCollections({bool forceNetwork = false}) =>
      fetchCatalog('icons', forceNetwork: forceNetwork);

  Future<CollectionData?> fetchPlatesCollections({bool forceNetwork = false}) =>
      fetchCatalog('plates', forceNetwork: forceNetwork);

  Future<CollectionData?> fetchFramesCollections({bool forceNetwork = false}) =>
      fetchCatalog('frames', forceNetwork: forceNetwork);

  String _timestampKey(String type) => switch (type) {
        'travelBuddies' => CacheKeyConstant.travelBuddiesCollectionsTimestamp,
        'partners' => CacheKeyConstant.partnersCollectionsTimestamp,
        _ => '${type}_collections_last_update',
      };

  Future<CollectionData?> fetchCatalog(String type,
      {bool forceNetwork = false}) async {
    final cacheKey = _cacheKeys[type];
    if (cacheKey == null) return null;
    final timestampKey = _timestampKey(type);
    final updatedAt = await getLastUpdateTime(timestampKey);
    if (!forceNetwork &&
        updatedAt != null &&
        DateTime.now().millisecondsSinceEpoch - updatedAt <
            _cacheAge.inMilliseconds) {
      final cached = await _readCache(type, cacheKey);
      if (cached != null) return cached;
    }
    return _inFlight.putIfAbsent(
      type,
      () => _loadCatalog(type, cacheKey, timestampKey).whenComplete(() {
        _inFlight.remove(type);
      }),
    );
  }

  Future<CollectionData?> _loadCatalog(
      String type, String cacheKey, String timestampKey) async {
    CollectionData data;
    try {
      final json = await _fetchJson(
        Uri.parse('${ApiUrls.CollectionCatalogUrl}/$type'),
        timeout: const Duration(seconds: 4),
      );
      data = _parseCatalog(type, json);
    } catch (error) {
      debugPrint('图鉴缓存代理不可用 ($type): $error');
      try {
        data = await _fetchUpstream(type);
      } catch (upstreamError) {
        debugPrint('图鉴上游不可用 ($type): $upstreamError');
        return _readCache(type, cacheKey);
      }
    }
    await _saveToCache(data, cacheKey, timestampKey);
    return data;
  }

  Future<Map<String, dynamic>> _fetchJson(
    Uri uri, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final response = await ApiClient.get(uri, timeout: timeout);
    if (response.statusCode != 200) {
      throw StateError('HTTP ${response.statusCode}');
    }
    return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  CollectionData _parseCatalog(String type, Map<String, dynamic> data) {
    final entries = _catalogEntries(data[type]);
    if (entries.isEmpty ||
        entries.map((entry) => entry['id']).toSet().length != entries.length) {
      throw const FormatException('图鉴为空或 ID 重复');
    }
    return CollectionData.fromJson({type: entries});
  }

  List<Map<String, dynamic>> _catalogEntries(Object? value) {
    if (value is! List) throw const FormatException('缺少图鉴列表');
    return [
      for (final entry in value)
        if (entry is Map<String, dynamic> &&
            entry['id'] is int &&
            (entry['id'] as int) >= 0 &&
            entry['name'] is String)
          entry
        else
          throw const FormatException('图鉴条目无效'),
    ];
  }

  Future<CollectionData> _fetchUpstream(String type) async {
    final lxnsUrl = _lxnsUrls[type];
    if (lxnsUrl != null) {
      final responses = await Future.wait([
        for (final required in [false, true])
          _fetchJson(Uri.parse(lxnsUrl)
              .replace(queryParameters: {'required': '$required'})),
      ]);
      // 两批数据都完整时才替换缓存，同 ID 优先保留获取条件。
      final merged = {
        for (final response in responses)
          for (final entry in _catalogEntries(response[type]))
            entry['id']: entry,
      };
      return _parseCatalog(type, {type: merged.values.toList()});
    }

    final kind = _awmcTypes[type]!;
    final data =
        await _fetchJson(Uri.parse(ApiUrls.AwmcCollectionExportUrl).replace(
      queryParameters: {'format': 'json', 'type': kind},
    ));
    final items = data['items'];
    if (items is! List || items.length != data['total']) {
      throw const FormatException('AWMC 图鉴列表不完整');
    }
    final gameIdPattern = RegExp(r'^\d{1,9}$');
    return _parseCatalog(type, {
      type: [
        for (final item in items)
          if (item is Map<String, dynamic> &&
              item['type'] == kind &&
              gameIdPattern.hasMatch('${item['gameId']}'))
            {'id': int.parse('${item['gameId']}'), 'name': item['name']}
          else
            throw const FormatException('AWMC 图鉴条目无效'),
      ],
    });
  }

  Future<CollectionData?> _readCache(String type, String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(cacheKey);
      if (value == null) return null;
      final decoded = json.decode(value);
      // 兼容旧版保存的裸数组和按类型保存的对象。
      return _parseCatalog(type,
          decoded is List ? {type: decoded} : decoded as Map<String, dynamic>);
    } catch (error) {
      debugPrint('读取图鉴本地缓存失败 ($type): $error');
      return null;
    }
  }

  // 保存数据到缓存
  Future<void> _saveToCache(
      CollectionData collections, String cacheKey, String lastUpdateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(collections.toJson());
      await prefs.setString(cacheKey, jsonString);
      await prefs.setInt(lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('保存收藏品数据到缓存时出错: $e');
    }
  }

  // 检查是否有缓存数据
  Future<bool> hasCachedData(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(cacheKey);
    return jsonString != null && jsonString.isNotEmpty;
  }

  // 获取最后更新时间
  Future<int?> getLastUpdateTime(String lastUpdateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(lastUpdateKey);
    } catch (e) {
      debugPrint('获取最后更新时间时出错: $e');
      return null;
    }
  }

  // 清除缓存
  Future<void> clearCache(String cacheKey, String lastUpdateKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(cacheKey);
      await prefs.remove(lastUpdateKey);
    } catch (e) {
      debugPrint('清除收藏品数据缓存时出错: $e');
    }
  }

  // 清除前等已发出的读取结束，避免旧请求在清除后重新落盘。
  Future<void> clearAllCache() async {
    await Future.wait(_inFlight.values.toList());
    await Future.wait([
      for (final entry in _cacheKeys.entries)
        clearCache(entry.value, _timestampKey(entry.key)),
    ]);
  }

  Future<void> refreshAllCollections({bool forceNetwork = false}) async {
    await Future.wait([
      for (final type in _cacheKeys.keys)
        fetchCatalog(type, forceNetwork: forceNetwork),
    ]);
  }
}
