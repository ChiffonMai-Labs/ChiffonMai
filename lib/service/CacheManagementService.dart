import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../manager/MaidataManager.dart';
import '../constant/CacheKeyConstant.dart';
import 'SongMediaCache.dart';

enum AppCacheKind { audio, pv, maidata }

class CacheUsage {
  const CacheUsage({
    required this.audioBytes,
    required this.audioFiles,
    required this.pvBytes,
    required this.pvFiles,
    required this.maidataBytes,
    required this.maidataFiles,
    required this.maidataMemoryBytes,
  });

  final int audioBytes;
  final int audioFiles;
  final int pvBytes;
  final int pvFiles;
  final int maidataBytes;
  final int maidataFiles;
  final int maidataMemoryBytes;

  int get bytesForAll => audioBytes + pvBytes + maidataBytes;
}

class CacheManagementService {
  CacheManagementService._();
  static final instance = CacheManagementService._();

  Future<CacheUsage> inspect() async {
    final maidataManager = MaidataManager();
    await maidataManager.initialize();
    final documents = await getApplicationDocumentsDirectory();
    final audio = await SongMediaCache.instance.audioUsage();
    final pv = await _measureDirectory(
      Directory('${documents.path}/portable_pv_cache'),
    );
    final maidata = await _measureFiles(
      documents,
      (file) =>
          file.path.endsWith('maidata_full_cache.json') ||
          file.path.endsWith('maidata_url_map.json'),
    );
    final prefs = await SharedPreferences.getInstance();
    var preferenceBytes = 0;
    var preferenceCount = 0;
    for (final key in prefs.getKeys()) {
      if (key.startsWith(CacheKeyConstant.maidataCachePrefix) ||
          key == CacheKeyConstant.maidataIndexCache ||
          key == CacheKeyConstant.maidataFullCache) {
        final value = prefs.getString(key);
        if (value != null) {
          preferenceBytes += utf8.encode(value).length;
          preferenceCount++;
        }
      }
    }
    return CacheUsage(
      audioBytes: audio.$1,
      audioFiles: audio.$2,
      pvBytes: pv.$1,
      pvFiles: pv.$2,
      maidataBytes: maidata.$1 + preferenceBytes,
      maidataFiles: maidata.$2 + preferenceCount,
      maidataMemoryBytes: maidataManager.memoryCacheBytes,
    );
  }

  Future<void> clear(
    AppCacheKind kind, {
    required void Function(double progress) onProgress,
  }) async {
    onProgress(0);
    final documents = await getApplicationDocumentsDirectory();
    switch (kind) {
      case AppCacheKind.audio:
        await SongMediaCache.instance.clear('audio');
      case AppCacheKind.pv:
        await SongMediaCache.instance.clear('pv');
      case AppCacheKind.maidata:
        await MaidataManager().clearCache();
        final urlMap = File('${documents.path}/maidata_url_map.json');
        if (await urlMap.exists()) await urlMap.delete();
    }
    // 删除通常瞬间完成，保留几个平滑的阶段，让用户明确看到操作已完成。
    onProgress(.55);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    onProgress(.82);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    onProgress(1);
  }

  Future<(int, int)> _measureDirectory(Directory directory) async {
    if (!await directory.exists()) return (0, 0);
    return _measureFiles(directory, (_) => true);
  }

  Future<(int, int)> _measureFiles(
    Directory root,
    bool Function(File file) include,
  ) async {
    var bytes = 0;
    var files = 0;
    try {
      await for (final entity
          in root.list(recursive: true, followLinks: false)) {
        if (entity is! File || !include(entity)) continue;
        try {
          bytes += await entity.length();
          files++;
        } catch (_) {}
      }
    } catch (_) {}
    return (bytes, files);
  }
}
