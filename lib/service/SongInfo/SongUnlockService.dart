import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../utils/ApiClient.dart';

/// 单首歌曲（或单谱面）的国服解禁条件明细。
class SongUnlockInfo {
  final int songId;
  final String category;
  final String summary;
  final String detail;
  final String? mapName;
  final String? kaleidGateColor;
  final String? kaleidGateTitle;

  const SongUnlockInfo({
    required this.songId,
    required this.category,
    required this.summary,
    required this.detail,
    this.mapName,
    this.kaleidGateColor,
    this.kaleidGateTitle,
  });

  factory SongUnlockInfo.fromJson(Map<String, dynamic> json,
      {String? fallbackKey}) {
    final parsedId = (json['songId'] as num?)?.toInt() ??
        int.tryParse(fallbackKey ?? '') ??
        0;
    final rawMap = (json['mapName'] as String?)?.trim();
    final rawColor = (json['kaleidGateColor'] as String?)?.trim();
    final rawTitle = (json['kaleidGateTitle'] as String?)?.trim();
    return SongUnlockInfo(
      songId: parsedId,
      category: (json['category'] as String?)?.trim() ?? '',
      summary: (json['summary'] as String?)?.trim() ?? '',
      detail: (json['detail'] as String?)?.trim() ?? '',
      mapName: (rawMap != null && rawMap.isNotEmpty) ? rawMap : null,
      kaleidGateColor:
          (rawColor != null && rawColor.isNotEmpty) ? rawColor : null,
      kaleidGateTitle:
          (rawTitle != null && rawTitle.isNotEmpty) ? rawTitle : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'category': category,
        'summary': summary,
        'detail': detail,
        if (mapName != null) 'mapName': mapName,
        if (kaleidGateColor != null) 'kaleidGateColor': kaleidGateColor,
        if (kaleidGateTitle != null) 'kaleidGateTitle': kaleidGateTitle,
      };
}

/// 从自家服务端读取结构化的国服歌曲解禁条件明细，并带内存与本地 6 小时缓存。
class SongUnlockService {
  SongUnlockService._internal();
  static final SongUnlockService _instance = SongUnlockService._internal();
  factory SongUnlockService() => _instance;

  static const Duration _cacheTtl = Duration(hours: 6);

  Map<String, SongUnlockInfo>? _memoryCache;
  DateTime? _memoryLoadedAt;
  Future<Map<String, SongUnlockInfo>>? _inFlight;

  Future<SongUnlockInfo?> getUnlockInfo(String songId) async {
    final key = songId.trim();
    if (key.isEmpty) return null;
    final map = await _getAll();
    return map[key];
  }

  Future<void> clearCache() async {
    _memoryCache = null;
    _memoryLoadedAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CacheKeyConstant.songUnlocksCache);
      await prefs.remove(CacheKeyConstant.songUnlocksCacheTimestamp);
    } catch (e) {
      debugPrint('[SongUnlockService] 清理缓存失败: $e');
    }
  }

  Future<Map<String, SongUnlockInfo>> _getAll() async {
    final cached = _memoryCache;
    final loadedAt = _memoryLoadedAt;
    if (cached != null &&
        loadedAt != null &&
        DateTime.now().difference(loadedAt) < _cacheTtl) {
      return cached;
    }

    final pending = _inFlight;
    if (pending != null) return pending;

    final future = _load();
    _inFlight = future;
    try {
      return await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<Map<String, SongUnlockInfo>> _load() async {
    final disk = await _readFromDisk();
    if (disk != null && disk.isFresh) {
      _memoryCache = disk.items;
      _memoryLoadedAt = disk.savedAt;
      return disk.items;
    }

    try {
      final response = await ApiClient.get(
        Uri.parse(ApiUrls.SongUnlocksUrl),
        timeout: const Duration(seconds: 6),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> &&
            decoded['success'] == true &&
            decoded['items'] is Map) {
          final parsed = _parseItems(decoded['items'] as Map);
          final now = DateTime.now();
          _memoryCache = parsed;
          _memoryLoadedAt = now;
          await _writeToDisk(parsed, now);
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('[SongUnlockService] 拉取解禁明细失败: $e');
    }

    // 网络失败或服务端异常时优先回退旧缓存，绝不阻塞歌曲详情展示。
    if (disk != null) {
      _memoryCache = disk.items;
      _memoryLoadedAt = DateTime.now();
      return disk.items;
    }
    return const {};
  }

  Map<String, SongUnlockInfo> _parseItems(Map<dynamic, dynamic> rawItems) {
    final result = <String, SongUnlockInfo>{};
    rawItems.forEach((rawKey, rawValue) {
      if (rawValue is! Map) return;
      final key = rawKey.toString().trim();
      if (key.isEmpty) return;
      final info = SongUnlockInfo.fromJson(
        Map<String, dynamic>.from(rawValue),
        fallbackKey: key,
      );
      if (info.summary.isNotEmpty || info.detail.isNotEmpty) {
        result[key] = info;
      }
    });
    return result;
  }

  Future<({Map<String, SongUnlockInfo> items, DateTime savedAt, bool isFresh})?>
      _readFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(CacheKeyConstant.songUnlocksCache);
      final ts = prefs.getInt(CacheKeyConstant.songUnlocksCacheTimestamp);
      if (rawJson == null || rawJson.isEmpty || ts == null) return null;
      final decoded = jsonDecode(rawJson);
      if (decoded is! Map) return null;
      final savedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final isFresh = DateTime.now().difference(savedAt) < _cacheTtl;
      return (
        items: _parseItems(decoded),
        savedAt: savedAt,
        isFresh: isFresh,
      );
    } catch (e) {
      debugPrint('[SongUnlockService] 读取本地缓存失败: $e');
      return null;
    }
  }

  Future<void> _writeToDisk(
      Map<String, SongUnlockInfo> items, DateTime savedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = {
        for (final entry in items.entries) entry.key: entry.value.toJson(),
      };
      await prefs.setString(
          CacheKeyConstant.songUnlocksCache, jsonEncode(serialized));
      await prefs.setInt(CacheKeyConstant.songUnlocksCacheTimestamp,
          savedAt.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[SongUnlockService] 写入本地缓存失败: $e');
    }
  }
}
