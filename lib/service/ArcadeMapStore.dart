import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../entity/nearcade/NearCadeShop.dart';
import '../utils/ArcadeShopUtil.dart';
import '../utils/JsonIsolate.dart';

class ArcadeMapSnapshot {
  final List<Shop> shops;
  final DateTime? fetchedAt;

  /// 旧版缓存把机厅 ID 写错了字段，读回来全是 0，也没有地铁信息，要更新一次。
  final bool isLegacy;

  const ArcadeMapSnapshot(this.shops, this.fetchedAt, this.isLegacy);
}

/// 全球机厅地图的本地数据。
///
/// 机厅全量数据有十几 MB，放文件而不是 SharedPreferences：后者启动时会把
/// 整个文件读进内存，不打开地图的用户也要付这份代价，还会被带进数据备份。
class ArcadeMapStore {
  ArcadeMapStore._();

  static const _fileName = 'nearcade_shops_v2.json';
  static const _legacyCacheKey = 'nearcade_shops_cache';
  static const _legacyTimeKey = 'nearcade_shops_cache_time';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  static Future<ArcadeMapSnapshot?> load() async {
    final file = await _file();
    final prefs = await SharedPreferences.getInstance();
    String? text;
    if (await file.exists()) {
      text = await file.readAsString();
    } else {
      text = await _migrateLegacy(prefs, file);
    }
    if (text == null) return null;

    final decoded = await decodeJsonInBackground(text);
    if (decoded is! Map<String, dynamic>) return null;
    final shops = NearCadeShop.fromJson(decoded).shops;
    final time = decoded['fetchedAt'];
    return ArcadeMapSnapshot(
      shops,
      time is int && time > 0 ? DateTime.fromMillisecondsSinceEpoch(time) : null,
      shops.isNotEmpty && shops.every((shop) => shop.shopId == 0),
    );
  }

  /// 把 SharedPreferences 里的旧缓存搬到文件，并释放原来的键。
  static Future<String?> _migrateLegacy(
      SharedPreferences prefs, File file) async {
    final legacy = prefs.getString(_legacyCacheKey);
    if (legacy == null) return null;
    final fetchedAt = prefs.getInt(_legacyTimeKey);
    final merged = legacy.replaceFirst('{', '{"fetchedAt":${fetchedAt ?? 0},');
    await _writeAtomically(file, merged);
    await prefs.remove(_legacyCacheKey);
    await prefs.remove(_legacyTimeKey);
    return merged;
  }

  static Future<void> save(List<Shop> shops, DateTime fetchedAt) async {
    final payload = {
      'fetchedAt': fetchedAt.millisecondsSinceEpoch,
      'totalCount': shops.length,
      'shops': [for (final shop in shops) arcadeShopToJson(shop)],
    };
    final text = await compute(jsonEncode, payload);
    await _writeAtomically(await _file(), text);
  }

  /// 先写临时文件再改名，写到一半被杀进程也不会留下损坏的缓存。
  static Future<void> _writeAtomically(File file, String text) async {
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(text, flush: true);
    await temp.rename(file.path);
  }

  static Future<Set<int>> loadFavorites() =>
      _loadIds(CacheKeyConstant.arcadeMapFavorites);

  static Future<void> saveFavorites(Set<int> ids) =>
      _saveIds(CacheKeyConstant.arcadeMapFavorites, ids);

  static Future<Set<int>> loadSelectedTitles() =>
      _loadIds(CacheKeyConstant.arcadeMapSelectedTitles);

  static Future<void> saveSelectedTitles(Set<int> ids) =>
      _saveIds(CacheKeyConstant.arcadeMapSelectedTitles, ids);

  static Future<Set<int>> _loadIds(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final raw in prefs.getStringList(key) ?? const <String>[])
        if (int.tryParse(raw) case final id?) id
    };
  }

  static Future<void> _saveIds(String key, Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, [for (final id in ids) '$id']);
  }
}
