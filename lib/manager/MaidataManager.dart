import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../constant/CacheTimestampConstant.dart';

/// 谱面 maidata 按需加载与持久化管理器（单例）。
///
/// 采用「轻量目录索引 + 单曲按需拉取 + 单曲文件磁盘缓存 + 有界内存 LRU」架构：
/// - 启动与首页刷新不再抓取全库 maidata；
/// - 歌曲详情页、谱面播放、多人/单人看谱猜歌、BPM 历史仅按需拉取所需曲目；
/// - 单曲文件落盘于 `documents/maidata_cache/<songId>.txt`，过期自动清理。
class MaidataManager {
  static final MaidataManager _instance = MaidataManager._internal();
  factory MaidataManager() => _instance;
  MaidataManager._internal();

  @visibleForTesting
  MaidataManager.forTesting();

  static const int _memoryLruLimit = 64;
  static final RegExp _validSongIdRegex = RegExp(r'^\d{1,6}$');

  final LinkedHashMap<String, String> _memoryCache =
      LinkedHashMap<String, String>();
  final Set<String> _diskCachedIds = <String>{};
  final Map<String, String> _legacySingleMaidata = <String, String>{};
  final Map<String, String> _wmcFallbackCache = <String, String>{};

  Map<String, List<String>>? _catalog;
  Map<String, dynamic>? _indexData;

  bool _isInitialized = false;
  Future<void>? _initializing;
  Future<Map<String, List<String>>>? _catalogFetch;
  final Map<String, Future<String?>> _inFlightSongs =
      <String, Future<String?>>{};
  final Map<String, Future<String?>> _wmcRequests =
      <String, Future<String?>>{};
  final Set<Future<void>> _writes = <Future<void>>{};
  int _cacheGeneration = 0;

  String _cleanMaidataContent(String content) {
    var result = content.replaceAll(RegExp(r'\[DX\]'), '');
    result = result.replaceAll(RegExp(r'\[SD\]'), '');
    result = result.replaceAll(RegExp(r'\[宴\]'), '');
    result = result.replaceAll(r'$', '');
    return result;
  }

  /// 解码响应体为字符串。优先 UTF-8（覆盖绝大多数 maidata），失败回退 Shift-JIS。
  String _decodeContent(List<int> bytes) {
    final utf8Result = utf8.decode(bytes, allowMalformed: true);
    if (!utf8Result.contains('\uFFFD')) {
      return utf8Result;
    }

    try {
      final shiftJisResult = _decodeShiftJis(bytes);
      if (shiftJisResult.isNotEmpty && !shiftJisResult.contains('\uFFFD')) {
        return shiftJisResult;
      }
    } catch (_) {}

    return utf8Result;
  }

  String _decodeShiftJis(List<int> bytes) {
    final result = StringBuffer();
    var i = 0;
    while (i < bytes.length) {
      final byte1 = bytes[i] & 0xFF;

      if (byte1 < 0x80) {
        result.writeCharCode(byte1);
        i++;
      } else if ((byte1 >= 0x81 && byte1 <= 0x9F) ||
          (byte1 >= 0xE0 && byte1 <= 0xFC)) {
        if (i + 1 < bytes.length) {
          final byte2 = bytes[i + 1] & 0xFF;
          final code = _shiftJisToUnicode(byte1, byte2);
          if (code != 0) {
            result.writeCharCode(code);
          }
          i += 2;
        } else {
          result.writeCharCode(byte1);
          i++;
        }
      } else {
        result.writeCharCode(byte1);
        i++;
      }
    }
    return result.toString();
  }

  int _shiftJisToUnicode(int byte1, int byte2) {
    int offset;
    if (byte1 >= 0x81 && byte1 <= 0x9F) {
      offset = (byte1 - 0x81) * 0x100;
    } else if (byte1 >= 0xE0 && byte1 <= 0xFC) {
      offset = (byte1 - 0xC1) * 0x100;
    } else {
      return 0;
    }

    final sjis = offset + byte2;

    if (sjis >= 0x8140 && sjis <= 0x889E) {
      return 0x4E00 +
          (((sjis - 0x8140) ~/ 0x40) * 0x9F) +
          ((sjis - 0x8140) % 0x40) -
          (((sjis - 0x8140) ~/ 0x40) > 7 ? 1 : 0);
    }

    if (sjis >= 0x889F && sjis <= 0x9FFC) {
      return 0x4E00 +
          (((sjis - 0x889F) ~/ 0x40) * 0x9F) +
          ((sjis - 0x889F) % 0x40) +
          0x7D;
    }

    if (sjis >= 0xE040 && sjis <= 0xEAA4) {
      return 0xF900 + (sjis - 0xE040);
    }

    return 0;
  }

  String? _extractSongId(String content) {
    final shortMatch = RegExp(r'&shortid=(\d+)').firstMatch(content);
    if (shortMatch != null) return shortMatch.group(1);
    final idMatch = RegExp(r'&id=(\d+)').firstMatch(content);
    if (idMatch != null) return idMatch.group(1);
    return null;
  }

  Future<Directory> _getSingleCacheDir() async {
    final dir = await getApplicationDocumentsDirectory();
    return Directory('${dir.path}/maidata_cache');
  }

  Future<File> _getSingleCacheFile(String songId) async {
    final dir = await _getSingleCacheDir();
    return File('${dir.path}/$songId.txt');
  }

  Future<File> _getCatalogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/maidata_catalog.json');
  }

  void _touchMemory(String songId, String content) {
    _memoryCache.remove(songId);
    _memoryCache[songId] = content;
    while (_memoryCache.length > _memoryLruLimit) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
  }

  bool _isTimestampValid(DateTime modified) {
    return DateTime.now().difference(modified).inMilliseconds <
        CacheTimestampConstant.songMaidataCacheMillis;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    final running = _initializing;
    if (running != null) return running;
    final task = Future.wait<void>([
      _cleanupLegacyFullCache(),
      _scanSingleDiskCache(),
      _loadLegacySinglePrefsCache(),
      _loadCatalogFromCache(),
    ]).then((_) {
      _isInitialized = true;
    });
    _initializing = task;
    try {
      await task;
    } finally {
      _initializing = null;
    }
  }

  /// 清理旧版全量缓存文件，释放磁盘占用，不再把整库 JSON 读进内存。
  Future<void> _cleanupLegacyFullCache() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final legacyFull = File('${dir.path}/maidata_full_cache.json');
      if (await legacyFull.exists()) await legacyFull.delete();
      final legacyUrlMap = File('${dir.path}/maidata_url_map.json');
      if (await legacyUrlMap.exists()) await legacyUrlMap.delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CacheKeyConstant.maidataFullCache);
      await prefs.remove(CacheKeyConstant.maidataFullCacheTimestamp);
    } catch (e) {
      debugPrint('[MaidataManager] 清理旧版全量缓存失败: $e');
    }
  }

  /// 扫描已有的单曲文件缓存目录，只登记可用 songId 并清理过期文件。
  Future<void> _scanSingleDiskCache() async {
    try {
      final dir = await _getSingleCacheDir();
      if (!await dir.exists()) return;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!name.endsWith('.txt')) continue;
        final songId = name.substring(0, name.length - 4);
        if (!_validSongIdRegex.hasMatch(songId)) continue;
        try {
          final stat = await entity.stat();
          if (_isTimestampValid(stat.modified)) {
            _diskCachedIds.add(songId);
          } else {
            await entity.delete();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[MaidataManager] 扫描单曲磁盘缓存失败: $e');
    }
  }

  /// 兼容读取旧版 SharedPreferences 单曲缓存，过期则删除。
  Future<void> _loadLegacySinglePrefsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (!key.startsWith(CacheKeyConstant.maidataCachePrefix)) continue;
        try {
          final raw = prefs.getString(key);
          if (raw == null) {
            await prefs.remove(key);
            continue;
          }
          final data = json.decode(raw) as Map<String, dynamic>;
          final id = key.substring(CacheKeyConstant.maidataCachePrefix.length);
          final content = data['content'] as String;
          final timestamp = data['timestamp'] as int;
          if (DateTime.now().millisecondsSinceEpoch - timestamp <
                  CacheTimestampConstant.songMaidataCacheMillis &&
              _extractSongId(content) == id) {
            _legacySingleMaidata[id] = content;
          } else {
            await prefs.remove(key);
          }
        } catch (_) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('[MaidataManager] 加载旧版单曲缓存失败: $e');
    }
  }

  Future<void> _loadCatalogFromCache() async {
    try {
      final file = await _getCatalogFile();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final decoded = await compute(_decodeCatalogPayload, raw);
      if (decoded.isNotEmpty) {
        _catalog = decoded;
      }
    } catch (e) {
      debugPrint('[MaidataManager] 加载轻量目录缓存失败: $e');
    }
  }

  static Map<String, List<String>> _decodeCatalogPayload(String raw) {
    final decoded = json.decode(raw);
    if (decoded is! Map) return <String, List<String>>{};
    final songsRaw = decoded['songs'] is Map ? decoded['songs'] as Map : decoded;
    final result = <String, List<String>>{};
    songsRaw.forEach((key, value) {
      if (key is String && value is List) {
        result[key] = value.map((e) => e.toString()).toList();
      }
    });
    return result;
  }

  Future<void> cacheMaidata(String songId, String content) async {
    if (!_validSongIdRegex.hasMatch(songId)) return;
    if (_extractSongId(content) != songId) return;
    final task = _writeSingleCache(songId, content);
    _writes.add(task);
    try {
      await task;
    } finally {
      _writes.remove(task);
    }
  }

  Future<void> _writeSingleCache(String songId, String content) async {
    final generation = _cacheGeneration;
    _touchMemory(songId, content);
    _diskCachedIds.add(songId);
    _legacySingleMaidata.remove(songId);

    final file = await _getSingleCacheFile(songId);
    if (_cacheGeneration != generation) return;
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.tmp');
    try {
      await temp.writeAsString(content);
      if (_cacheGeneration != generation) return;
      await temp.rename(file.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${CacheKeyConstant.maidataCachePrefix}$songId');
    } catch (_) {}
  }

  /// 同步读取内存中的原始缓存（已清理标记符号）。
  String? getMaidata(String songId) {
    final content = _memoryCache[songId] ?? _legacySingleMaidata[songId];
    if (content != null) {
      _touchMemory(songId, content);
      return _cleanMaidataContent(content);
    }
    return null;
  }

  /// 仅从本地（内存或磁盘单曲文件）读取指定曲目的 maidata，不发起网络请求。
  Future<String?> readCachedMaidata(String songId) async {
    await initialize();
    if (!_validSongIdRegex.hasMatch(songId)) return null;

    final memHit = _memoryCache[songId];
    if (memHit != null) {
      _touchMemory(songId, memHit);
      return _cleanMaidataContent(memHit);
    }

    final file = await _getSingleCacheFile(songId);
    if (await file.exists()) {
      try {
        final stat = await file.stat();
        if (_isTimestampValid(stat.modified)) {
          final content = await file.readAsString();
          if (_extractSongId(content) == songId) {
            _touchMemory(songId, content);
            _diskCachedIds.add(songId);
            return _cleanMaidataContent(content);
          }
        }
        await file.delete();
        _diskCachedIds.remove(songId);
      } catch (_) {}
    }

    final legacy = _legacySingleMaidata[songId];
    if (legacy != null) {
      await cacheMaidata(songId, legacy);
      return _cleanMaidataContent(legacy);
    }
    return null;
  }

  bool hasCachedMaidata(String songId) {
    return _memoryCache.containsKey(songId) ||
        _diskCachedIds.contains(songId) ||
        _legacySingleMaidata.containsKey(songId);
  }

  int get cachedCount => {
        ..._memoryCache.keys,
        ..._diskCachedIds,
        ..._legacySingleMaidata.keys,
      }.length;

  bool get isCacheReady =>
      cachedCount > 0 || (_catalog != null && _catalog!.isNotEmpty);

  List<String>? getCatalogInotes(String songId) => _catalog?[songId];

  Future<bool> isCatalogValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(CacheKeyConstant.maidataCatalogTimestamp);
      if (timestamp == null) return false;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp >= CacheTimestampConstant.maidataCatalogCacheMillis) {
        return false;
      }
      final file = await _getCatalogFile();
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  /// 获取轻量谱面目录（`songId -> 可用 inote 编号列表`），带本地文件缓存与 ETag 校验。
  Future<Map<String, List<String>>> getCatalog({
    bool forceRefresh = false,
  }) async {
    await initialize();
    if (!forceRefresh &&
        _catalog != null &&
        _catalog!.isNotEmpty &&
        await isCatalogValid()) {
      return _catalog!;
    }
    final running = _catalogFetch;
    if (running != null && !forceRefresh) return running;

    final task = _fetchCatalog(forceRefresh: forceRefresh);
    _catalogFetch = task;
    try {
      return await task;
    } finally {
      if (identical(_catalogFetch, task)) {
        _catalogFetch = null;
      }
    }
  }

  Future<Map<String, List<String>>> _fetchCatalog({
    required bool forceRefresh,
  }) async {
    final generation = _cacheGeneration;
    try {
      final prefs = await SharedPreferences.getInstance();
      final etag = forceRefresh
          ? null
          : prefs.getString(CacheKeyConstant.maidataCatalogEtag);
      final headers = <String, String>{};
      if (etag != null && etag.isNotEmpty && (_catalog?.isNotEmpty ?? false)) {
        headers['If-None-Match'] = etag;
      }

      final response = await ApiClient.get(
        Uri.parse(ApiUrls.MaidataCatalogUrl),
        headers: headers.isEmpty ? null : headers,
      );
      if (_cacheGeneration != generation) {
        return _catalog ?? const <String, List<String>>{};
      }

      if (response.statusCode == 304 &&
          _catalog != null &&
          _catalog!.isNotEmpty) {
        await prefs.setInt(
          CacheKeyConstant.maidataCatalogTimestamp,
          DateTime.now().millisecondsSinceEpoch,
        );
        return _catalog!;
      }

      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes, allowMalformed: true);
        final parsed = await compute(_decodeCatalogPayload, raw);
        if (_cacheGeneration != generation) {
          return _catalog ?? const <String, List<String>>{};
        }
        if (parsed.isNotEmpty) {
          _catalog = parsed;
          final file = await _getCatalogFile();
          final temp = File('${file.path}.tmp');
          try {
            await temp.writeAsString(json.encode(<String, dynamic>{
              'version': 1,
              'songs': parsed,
            }));
            if (_cacheGeneration == generation) {
              await temp.rename(file.path);
            }
          } finally {
            if (await temp.exists()) await temp.delete();
          }
          await prefs.setInt(
            CacheKeyConstant.maidataCatalogTimestamp,
            DateTime.now().millisecondsSinceEpoch,
          );
          final respEtag = response.headers['etag'];
          if (respEtag != null && respEtag.isNotEmpty) {
            await prefs.setString(
                CacheKeyConstant.maidataCatalogEtag, respEtag);
          }
          debugPrint('[MaidataManager] 轻量目录已更新，共 ${parsed.length} 首');
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('[MaidataManager] 获取轻量目录失败: $e');
    }
    return _catalog ?? const <String, List<String>>{};
  }

  /// 按需获取单首歌曲的 maidata 文本。
  ///
  /// 读取顺序：内存 LRU → 磁盘单曲缓存 → 自家 `/api/maidata/:songId` → `wmc.pub` 兜底。
  /// 返回清理过标记字符后的文本；同曲目并发请求自动合并去重。
  Future<String?> fetchMaidata(
    String songId, {
    bool forceNetwork = false,
  }) async {
    await initialize();
    if (!_validSongIdRegex.hasMatch(songId)) return null;

    if (!forceNetwork) {
      final cached = await readCachedMaidata(songId);
      if (cached != null) return cached;
    }

    final running = _inFlightSongs[songId];
    if (running != null) return running;

    final task = _fetchSingleSongFromNetwork(songId);
    _inFlightSongs[songId] = task;
    try {
      return await task;
    } finally {
      _inFlightSongs.remove(songId);
    }
  }

  Future<String?> _fetchSingleSongFromNetwork(String songId) async {
    final generation = _cacheGeneration;
    try {
      final response = await ApiClient.get(
        Uri.parse(ApiUrls.maidataSongUrl(songId)),
      );
      if (_cacheGeneration != generation) return null;
      if (response.statusCode == 200) {
        final content = _decodeContent(response.bodyBytes);
        if (_extractSongId(content) == songId) {
          await cacheMaidata(songId, content);
          return _cleanMaidataContent(content);
        }
      } else {
        debugPrint('[MaidataManager] 主源未命中 songId=$songId, '
            'status=${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[MaidataManager] 主源请求失败 songId=$songId: $e');
    }

    if (_cacheGeneration != generation) return null;
    return _fetchWmcMaidata(songId);
  }

  /// 按歌曲 ID 列表按需批量获取 maidata（并发去重，不触发目录扫描）。
  Future<List<String>> fetchMaidataForSongIds(List<String> songIds) async {
    await initialize();
    final uniqueIds = songIds.toSet().toList();
    final results = <String>[];
    const batchSize = 4;
    for (var i = 0; i < uniqueIds.length; i += batchSize) {
      final end = (i + batchSize < uniqueIds.length)
          ? i + batchSize
          : uniqueIds.length;
      final batch = uniqueIds.sublist(i, end);
      final fetched = await Future.wait(batch.map((id) => fetchMaidata(id)));
      for (final item in fetched) {
        if (item != null && item.isNotEmpty) {
          results.add(item);
        }
      }
    }
    return results;
  }

  /// 离线或目录缺失时，根据已有单曲缓存构造临时 `songId -> inotes` 映射供本地游乐功能兜底。
  Future<Map<String, List<String>>> buildOfflineCachedInotes() async {
    await initialize();
    final map = <String, List<String>>{};
    final ids = {
      ..._memoryCache.keys,
      ..._diskCachedIds,
      ..._legacySingleMaidata.keys,
    };
    for (final id in ids) {
      final content = await readCachedMaidata(id);
      if (content == null || content.isEmpty) continue;
      final inotes = <String>[];
      for (final m in RegExp(r'&inote_(\d+)').allMatches(content)) {
        final numStr = m.group(1)!;
        if (!inotes.contains(numStr)) inotes.add(numStr);
      }
      if (inotes.isNotEmpty) {
        inotes.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        map[id] = inotes;
      }
    }
    return map;
  }

  // ========== 兼容 index.json 映射（按需才拉，不在冷启动触发） ==========

  Future<Map<String, dynamic>> getIndex() async {
    if (_indexData != null && _indexData!.isNotEmpty) {
      return _indexData!;
    }
    await _loadIndexFromCache();
    if (_indexData != null && _indexData!.isNotEmpty) {
      return _indexData!;
    }
    await _fetchAndCacheIndex();
    return _indexData ?? <String, dynamic>{};
  }

  Future<void> _loadIndexFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(CacheKeyConstant.maidataIndexCache);
      final timestamp =
          prefs.getInt(CacheKeyConstant.maidataIndexCacheTimestamp);
      if (cachedData != null && timestamp != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp <
            CacheTimestampConstant.maidataCatalogCacheMillis) {
          _indexData =
              Map<String, dynamic>.from(json.decode(cachedData) as Map);
          return;
        }
      }
    } catch (e) {
      debugPrint('[MaidataManager] 加载 index 缓存失败: $e');
    }
  }

  Future<void> _fetchAndCacheIndex() async {
    try {
      final response = await ApiClient.get(
          Uri.parse('${ApiUrls.MaidataServerPortUrl}/index.json'));
      if (response.statusCode == 200) {
        final content = _decodeContent(response.bodyBytes);
        _indexData = Map<String, dynamic>.from(json.decode(content) as Map);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            CacheKeyConstant.maidataIndexCache, json.encode(_indexData));
        await prefs.setInt(CacheKeyConstant.maidataIndexCacheTimestamp,
            DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('[MaidataManager] 获取 index.json 失败: $e');
    }
  }

  List<String> findShortIdsForTitle(String title) {
    if (_indexData == null) return [];
    final sanitized = title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();
    final result = <String>[];
    for (final entry in _indexData!.entries) {
      final value = entry.value;
      var indexTitle = '';
      if (value is String) {
        indexTitle = value;
      } else if (value is Map) {
        indexTitle = (value['title'] ?? value['name'] ?? '').toString();
      }
      final sanitizedIndexTitle = indexTitle
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .replaceAll(RegExp(r'\s+'), '')
          .toUpperCase();
      if (sanitizedIndexTitle == sanitized ||
          sanitizedIndexTitle.contains(sanitized) ||
          sanitized.contains(sanitizedIndexTitle)) {
        result.add(entry.key);
      }
    }
    return result;
  }

  Future<List<String>> findShortIdsForTitleKana(String title) async {
    final result = findShortIdsForTitle(title);
    if (result.isNotEmpty) return result;
    try {
      final katakanaTitle = await _tryTransliterate(title);
      if (katakanaTitle != null && katakanaTitle != title) {
        final katakanaResult = findShortIdsForTitle(katakanaTitle);
        if (katakanaResult.isNotEmpty) return katakanaResult;
      }
    } catch (e) {
      debugPrint('[MaidataManager] 日语音读匹配异常: $e');
    }
    return [];
  }

  Future<String?> _tryTransliterate(String title) async {
    if (JpTransliterate.isKanji(input: title)) {
      final data = await JpTransliterate.transliterate(kanji: title);
      final katakana = data.katakana;
      if (katakana.isNotEmpty) {
        return katakana
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
            .replaceAll(RegExp(r'\s+'), '')
            .toUpperCase();
      }
    }
    return null;
  }

  String? getMaidataByShortIds(List<String> shortIds) {
    for (final sid in shortIds) {
      final content = getMaidata(sid);
      if (content != null) return content;
    }
    return null;
  }

  Future<void> clearCache() async {
    _cacheGeneration++;
    await _initializing;
    await Future.wait(_writes.toList());
    await _catalogFetch;
    await Future.wait(_inFlightSongs.values.toList());
    await Future.wait(_wmcRequests.values.toList());

    _memoryCache.clear();
    _diskCachedIds.clear();
    _legacySingleMaidata.clear();
    _wmcFallbackCache.clear();
    _catalog = null;
    _indexData = null;
    _isInitialized = false;

    try {
      final singleDir = await _getSingleCacheDir();
      if (await singleDir.exists()) {
        await singleDir.delete(recursive: true);
      }
      final catalogFile = await _getCatalogFile();
      if (await catalogFile.exists()) await catalogFile.delete();

      final dir = await getApplicationDocumentsDirectory();
      final legacyFull = File('${dir.path}/maidata_full_cache.json');
      if (await legacyFull.exists()) await legacyFull.delete();
      final legacyUrlMap = File('${dir.path}/maidata_url_map.json');
      if (await legacyUrlMap.exists()) await legacyUrlMap.delete();

      final prefs = await SharedPreferences.getInstance();
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith(CacheKeyConstant.maidataCachePrefix)) {
          await prefs.remove(key);
        }
      }
      await prefs.remove(CacheKeyConstant.maidataFullCache);
      await prefs.remove(CacheKeyConstant.maidataFullCacheTimestamp);
      await prefs.remove(CacheKeyConstant.maidataIndexCache);
      await prefs.remove(CacheKeyConstant.maidataIndexCacheTimestamp);
      await prefs.remove(CacheKeyConstant.maidataCatalogTimestamp);
      await prefs.remove(CacheKeyConstant.maidataCatalogEtag);
      debugPrint('[MaidataManager] 缓存已清空');
    } catch (e) {
      debugPrint('[MaidataManager] 清空缓存失败: $e');
    }
  }

  // ============== 单曲兜底（wmc.pub，内存与持久缓存） ==============

  Future<String?> getMaidataFromWmcFallback(String songId) async {
    await initialize();
    if (!_validSongIdRegex.hasMatch(songId)) return null;
    final persistent = await readCachedMaidata(songId);
    if (persistent != null) return persistent;

    final running = _wmcRequests[songId];
    if (running != null) return running;
    final task = _fetchWmcMaidata(songId);
    _wmcRequests[songId] = task;
    try {
      return await task;
    } finally {
      _wmcRequests.remove(songId);
    }
  }

  Future<String?> _fetchWmcMaidata(String songId) async {
    final generation = _cacheGeneration;
    final cached = _wmcFallbackCache[songId];
    if (cached != null) {
      return _cleanMaidataContent(cached);
    }
    try {
      final url = ApiUrls.wmcMaidataUrl(songId);
      final response = await ApiClient.get(Uri.parse(url));
      if (_cacheGeneration != generation) return null;
      if (response.statusCode == 200) {
        final content = _decodeContent(response.bodyBytes);
        if (_extractSongId(content) == songId) {
          _wmcFallbackCache[songId] = content;
          await cacheMaidata(songId, content);
          return _cleanMaidataContent(content);
        }
      }
    } catch (e) {
      debugPrint('[MaidataManager] wmc 兜底请求失败 songId=$songId: $e');
    }
    return null;
  }

  void clearWmcFallbackCache() {
    _wmcFallbackCache.clear();
  }

  int get wmcFallbackCacheCount => _wmcFallbackCache.length;

  /// 当前进程中 maidata 文本占用的 UTF-8 字节数（不含已落盘未读入内存的单曲文件）。
  int get memoryCacheBytes =>
      _memoryCache.values.fold<int>(
        0,
        (total, text) => total + utf8.encode(text).length,
      ) +
      _wmcFallbackCache.values.fold<int>(
        0,
        (total, text) => total + utf8.encode(text).length,
      ) +
      _legacySingleMaidata.values.fold<int>(
        0,
        (total, text) => total + utf8.encode(text).length,
      );
}
