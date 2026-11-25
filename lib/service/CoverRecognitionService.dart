import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/CacheKeyConstant.dart';
import '../entity/DivingFish/Song.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../utils/ApiClient.dart';
import '../utils/CoverUtil.dart';
import 'AwmcCoverService.dart';
import 'DxRatingCoverService.dart';

/// 在后台 isolate 中完成照片解码、裁方形、缩放和 pHash，避免相册大图阻塞 UI。
Map<String, dynamic> _extractPhotoFeatures(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('无法解码照片');
  }

  final w = decoded.width;
  final h = decoded.height;
  final square = w > h
      ? img.copyCrop(decoded, x: (w - h) ~/ 2, y: 0, width: h, height: h)
      : h > w
          ? img.copyCrop(decoded, x: 0, y: (h - w) ~/ 2, width: w, height: w)
          : decoded;
  final resized = img.copyResize(square, width: 256, height: 256);

  int sumR = 0, sumG = 0, sumB = 0;
  const pixelCount = 256 * 256;
  for (int y = 0; y < 256; y++) {
    for (int x = 0; x < 256; x++) {
      final p = resized.getPixel(x, y);
      sumR += p.r.toInt();
      sumG += p.g.toInt();
      sumB += p.b.toInt();
    }
  }

  return <String, dynamic>{
    'hash': CoverRecognitionService._computePHashPure(resized),
    'r': sumR ~/ pixelCount,
    'g': sumG ~/ pixelCount,
    'b': sumB ~/ pixelCount,
  };
}

/// 曲绘识别服务（全量曲库 + coverId 去重索引版）
///
/// 与旧版相比：
///   - 索引直接覆盖全部随包曲绘与全量曲库（国服 + 非国服/Union + 宴会场）
///   - 按 `coverId` 建索引（v4），同一曲绘对应的 ST/DX/宴谱条目共享特征，
///     识别时再映射回全量曲库代表曲目
///   - 对未随包的少数曲目按 AWMC → DXRating → 水鱼 链异步补齐特征
class CoverRecognitionService {
  static final CoverRecognitionService instance = CoverRecognitionService._();
  CoverRecognitionService._();

  Map<String, Map<String, dynamic>>? _featureCache;
  Map<String, int>? _remoteAttempted;
  Set<String>? _bundledCoverIdsCache;

  static const int _cacheVersion = 4;
  static const int _batchSize = 32;
  static const int _remoteConcurrency = 6;
  static const Duration _remoteTimeout = Duration(seconds: 8);
  static const Duration _remoteRetryCooldown = Duration(hours: 24);
  static final RegExp _bundledCoverPattern =
      RegExp(r'^assets/cover/(\d+)\.webp$');

  // ─── 缓存文件 ──────────────────────────────────────────────

  Future<File> _getCacheFile({int version = _cacheVersion}) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/cover_features_v$version.json');
  }

  Future<({Map<String, Map<String, dynamic>> features, Map<String, int> attempted})>
      _loadCacheStateFromFile() async {
    try {
      final file = await _getCacheFile();
      if (!await file.exists()) {
        return (
          features: <String, Map<String, dynamic>>{},
          attempted: <String, int>{},
        );
      }
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is Map && decoded['v'] == _cacheVersion) {
        final rawData = decoded['data'];
        final features = <String, Map<String, dynamic>>{};
        if (rawData is Map) {
          for (final entry in rawData.entries) {
            if (entry.value is Map) {
              features['${entry.key}'] =
                  Map<String, dynamic>.from(entry.value as Map);
            }
          }
        }
        final rawAttempted = decoded['remoteAttempted'];
        final attempted = <String, int>{};
        if (rawAttempted is Map) {
          for (final entry in rawAttempted.entries) {
            if (entry.value is num) {
              attempted['${entry.key}'] = (entry.value as num).toInt();
            }
          }
        }
        return (features: features, attempted: attempted);
      }
    } catch (e) {
      debugPrint('读取曲绘特征缓存失败: $e');
    }
    return (
      features: <String, Map<String, dynamic>>{},
      attempted: <String, int>{},
    );
  }

  Future<void> _saveCacheToFile(
    Map<String, Map<String, dynamic>> features,
    Map<String, int> attempted,
  ) async {
    try {
      final file = await _getCacheFile();
      final payload = jsonEncode({
        'v': _cacheVersion,
        'data': features,
        'remoteAttempted': attempted,
      });
      await file.writeAsString(payload);
      // 同步写一个时间戳，便于外部观测构建时间
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(CacheKeyConstant.coverHashCacheTimestamp,
          DateTime.now().millisecondsSinceEpoch);
      final legacyFile = await _getCacheFile(version: 3);
      if (await legacyFile.exists()) {
        await legacyFile.delete();
      }
    } catch (e) {
      debugPrint('保存曲绘特征缓存失败: $e');
    }
  }

  /// 枚举应用包内所有数字 ID 曲绘（排除 `0.webp` 默认占位图）。
  Future<Set<String>> _listBundledCoverIds() async {
    if (_bundledCoverIdsCache != null) return _bundledCoverIdsCache!;
    final ids = <String>{};
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final assetPath in manifest.listAssets()) {
        final match = _bundledCoverPattern.firstMatch(assetPath);
        if (match == null) continue;
        final cid = match.group(1)!;
        if (cid.isNotEmpty && cid != '0') {
          ids.add(cid);
        }
      }
    } catch (e) {
      debugPrint('[CoverRecognition] 读取 AssetManifest 失败，退回 cover_manifest: $e');
    }

    if (ids.isEmpty) {
      try {
        final manifestJson =
            await rootBundle.loadString('assets/cover_manifest.json');
        final songIds = jsonDecode(manifestJson) as List<dynamic>;
        for (final raw in songIds) {
          final cid = CoverUtil.extractCoverId('$raw');
          if (cid.isNotEmpty && cid != '0') {
            ids.add(cid);
          }
        }
      } catch (e) {
        debugPrint('[CoverRecognition] 读取 cover_manifest 失败: $e');
      }
    }

    _bundledCoverIdsCache = Set<String>.unmodifiable(ids);
    return _bundledCoverIdsCache!;
  }

  /// 将全量曲库（含国服 + 非国服/Union + 宴会场）按 `coverId` 归并，
  /// 并为每个 `coverId` 选出最合适的代表曲目。
  Map<String, Song> _buildCoverToSongMap(List<Song> songs) {
    final map = <String, Song>{};
    for (final song in songs) {
      final coverId = CoverUtil.extractCoverId(song.id);
      if (coverId.isEmpty || coverId == '0') continue;
      final existing = map[coverId];
      if (existing == null || _songPriorityCompare(song, existing) < 0) {
        map[coverId] = song;
      }
    }
    return map;
  }

  /// 负数表示 [a] 比 [b] 更适合作为同一 `coverId` 的代表曲目：
  /// 1) 常规谱优于宴会场（6位ID） 2) 国服优于非国服 3) DX 优于 SD 4) ID 数值更小优先
  static int _songPriorityCompare(Song a, Song b) {
    final aUtage = a.id.length >= 6 ? 1 : 0;
    final bUtage = b.id.length >= 6 ? 1 : 0;
    if (aUtage != bUtage) return aUtage - bUtage;

    final aExtra = a.isExtra ? 1 : 0;
    final bExtra = b.isExtra ? 1 : 0;
    if (aExtra != bExtra) return aExtra - bExtra;

    final aDx = a.type.toUpperCase() == 'DX' ? 0 : 1;
    final bDx = b.type.toUpperCase() == 'DX' ? 0 : 1;
    if (aDx != bDx) return aDx - bDx;

    final aNum = int.tryParse(a.id) ?? 1 << 30;
    final bNum = int.tryParse(b.id) ?? 1 << 30;
    if (aNum != bNum) return aNum.compareTo(bNum);

    return a.id.compareTo(b.id);
  }

  bool _isWithinRetryCooldown(int? lastAttemptMs, int nowMs) {
    if (lastAttemptMs == null) return false;
    return nowMs - lastAttemptMs < _remoteRetryCooldown.inMilliseconds;
  }

  Future<bool> isHashCacheValid() async {
    try {
      Map<String, Map<String, dynamic>> features;
      Map<String, int> attempted;
      if (_featureCache != null && _remoteAttempted != null) {
        features = _featureCache!;
        attempted = _remoteAttempted!;
      } else {
        final state = await _loadCacheStateFromFile();
        features = state.features;
        attempted = state.attempted;
        if (features.isNotEmpty) {
          _featureCache = features;
          _remoteAttempted = attempted;
        }
      }
      if (features.isEmpty) return false;

      final bundledIds = await _listBundledCoverIds();
      for (final cid in bundledIds) {
        if (!features.containsKey(cid)) return false;
      }

      final songs = await MaimaiMusicDataManager().getCachedSongs();
      if (songs != null && songs.isNotEmpty) {
        final nowMs = DateTime.now().millisecondsSinceEpoch;
        for (final song in songs) {
          final cid = CoverUtil.extractCoverId(song.id);
          if (cid.isEmpty || cid == '0') continue;
          if (!features.containsKey(cid) &&
              !_isWithinRetryCooldown(attempted[cid], nowMs)) {
            return false;
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── 索引构建（全量曲库 + 后台 isolate + 批处理 + 增量） ───────

  /// 预计算 / 增量补齐全量曲绘的 pHash 和颜色特征
  Future<void> precomputeHashes({
    void Function(int current, int total)? onProgress,
  }) async {
    // 1. 读取已有特征与失败冷却记录
    final state = await _loadCacheStateFromFile();
    final existing = state.features;
    final attempted = state.attempted;
    _featureCache = existing;
    _remoteAttempted = attempted;

    // 2. 枚举全部随包曲绘 + 获取全量曲库（只读缓存，若空则拉取一次）
    final bundledIds = await _listBundledCoverIds();
    final musicManager = MaimaiMusicDataManager();
    var songs = await musicManager.getCachedSongs();
    if (songs == null || songs.isEmpty) {
      await musicManager.fetchAndUpdateMusicData();
      songs = await musicManager.getCachedSongs();
    }
    final coverToSong = _buildCoverToSongMap(songs ?? const <Song>[]);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final missingLocal = bundledIds
        .where((cid) => !existing.containsKey(cid))
        .toList(growable: false);
    final missingRemote = coverToSong.keys
        .where((cid) =>
            !bundledIds.contains(cid) &&
            !existing.containsKey(cid) &&
            !_isWithinRetryCooldown(attempted[cid], nowMs))
        .toList(growable: false);

    if (missingLocal.isEmpty && missingRemote.isEmpty) {
      onProgress?.call(existing.length, existing.length);
      debugPrint(
          '[CoverRecognition] 缓存已覆盖全量 ${existing.length} 张曲绘，跳过构建');
      return;
    }

    final total = missingLocal.length + missingRemote.length;
    int processed = 0;
    onProgress?.call(0, total);
    debugPrint(
        '[CoverRecognition] 增量构建：本地缺失 ${missingLocal.length}，远程补齐 ${missingRemote.length}');

    // 3. 主线程预加载本地随包曲绘 bytes（rootBundle 必须在 main isolate）
    final localTasks = <({String coverId, Uint8List bytes})>[];
    for (final coverId in missingLocal) {
      try {
        final byteData = await rootBundle.load('assets/cover/$coverId.webp');
        localTasks.add(
            (coverId: coverId, bytes: byteData.buffer.asUint8List()));
      } catch (_) {
        processed++;
      }
    }

    // 4. 分批后台 isolate 计算本地随包曲绘特征
    for (int i = 0; i < localTasks.length; i += _batchSize) {
      final batch = localTasks.skip(i).take(_batchSize).toList();
      final batchResults = await compute(_processBatchIsolate, batch);
      for (final entry in batchResults.entries) {
        existing[entry.key] = entry.value;
        attempted.remove(entry.key);
      }
      processed += batch.length;
      onProgress?.call(math.min(processed, total), total);
      await Future.delayed(Duration.zero);
    }

    // 5. 对未随包的曲目按 AWMC → DXRating → 水鱼 链下载曲绘并提取特征
    if (missingRemote.isNotEmpty) {
      await AwmcCoverService.instance.ensureLoaded(allowNetwork: false);
      await DxRatingCoverService.instance.ensureLoaded(allowNetwork: false);

      final remoteTasks = <({String coverId, Uint8List bytes})>[];
      int cursor = 0;
      Future<void> worker() async {
        while (true) {
          if (cursor >= missingRemote.length) break;
          final coverId = missingRemote[cursor++];
          final song = coverToSong[coverId];
          final bytes =
              song == null ? null : await _downloadCoverBytes(song);
          if (bytes != null && bytes.isNotEmpty) {
            remoteTasks.add((coverId: coverId, bytes: bytes));
          } else {
            attempted[coverId] = nowMs;
            processed++;
            onProgress?.call(math.min(processed, total), total);
          }
        }
      }

      final workerCount = math.min(_remoteConcurrency, missingRemote.length);
      await Future.wait(
        List<Future<void>>.generate(workerCount, (_) => worker()),
      );

      for (int i = 0; i < remoteTasks.length; i += _batchSize) {
        final batch = remoteTasks.skip(i).take(_batchSize).toList();
        final batchResults = await compute(_processBatchIsolate, batch);
        for (final entry in batchResults.entries) {
          existing[entry.key] = entry.value;
          attempted.remove(entry.key);
        }
        processed += batch.length;
        onProgress?.call(math.min(processed, total), total);
        await Future.delayed(Duration.zero);
      }
    }

    // 6. 合并 + 写文件
    _featureCache = existing;
    _remoteAttempted = attempted;
    onProgress?.call(total, total);
    await _saveCacheToFile(existing, attempted);
    debugPrint('[CoverRecognition] 完成，共 ${existing.length} 张曲绘特征');
  }

  Future<Uint8List?> _downloadCoverBytes(Song song) async {
    final urls = <String>[
      ...AwmcCoverService.instance.coverUrlsFor(song.id, width: 240),
      if (DxRatingCoverService.instance.coverUrlFor(song.id)
          case final String dxUrl)
        dxUrl,
      CoverUtil.getNetworkCoverUrl(song.id),
    ];
    for (final rawUrl in urls) {
      try {
        final response = await ApiClient.get(
          Uri.parse(rawUrl),
          timeout: _remoteTimeout,
        );
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          return response.bodyBytes;
        }
      } catch (_) {
        // 继续尝试下一条候选源
      }
    }
    return null;
  }

  /// 单批特征提取（运行在后台 isolate）。
  /// 输入：coverId → image bytes
  /// 输出：coverId → {ph, r, g, b}
  static Map<String, Map<String, dynamic>> _processBatchIsolate(
      List<({String coverId, Uint8List bytes})> batch) {
    final result = <String, Map<String, dynamic>>{};
    for (final task in batch) {
      try {
        final image = img.decodeImage(task.bytes);
        if (image == null) continue;
        // 缩放至 256×256（DCT 输入）
        final resized = img.copyResize(image, width: 256, height: 256);

        // 平均颜色
        int sumR = 0, sumG = 0, sumB = 0;
        const pixelCount = 256 * 256;
        for (int y = 0; y < 256; y++) {
          for (int x = 0; x < 256; x++) {
            final p = resized.getPixel(x, y);
            sumR += p.r.toInt();
            sumG += p.g.toInt();
            sumB += p.b.toInt();
          }
        }
        final avgR = sumR ~/ pixelCount;
        final avgG = sumG ~/ pixelCount;
        final avgB = sumB ~/ pixelCount;

        // pHash
        final ph = _computePHashPure(resized);

        result[task.coverId] = {
          'ph': ph,
          'r': avgR,
          'g': avgG,
          'b': avgB,
        };
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  /// 纯函数版 pHash（不依赖实例状态，可被 isolate 直接调用）
  /// 算法：缩放256×256 → 灰度 → 降采样32×32 → DCT(左上8×8) → 中位数 → 64-bit hash
  static String _computePHashPure(img.Image resized) {
    // 灰度
    final gray = Float64List(256 * 256);
    for (int y = 0; y < 256; y++) {
      for (int x = 0; x < 256; x++) {
        final p = resized.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        gray[y * 256 + x] = 0.299 * r + 0.587 * g + 0.114 * b;
      }
    }

    // 降采样到 32×32
    final small = Float64List(32 * 32);
    for (int y = 0; y < 32; y++) {
      for (int x = 0; x < 32; x++) {
        double sum = 0;
        for (int dy = 0; dy < 8; dy++) {
          for (int dx = 0; dx < 8; dx++) {
            sum += gray[(y * 8 + dy) * 256 + (x * 8 + dx)];
          }
        }
        small[y * 32 + x] = sum / 64.0;
      }
    }

    // 2D DCT：取左上 8×8
    final dct8x8 = Float64List(64);
    for (int v = 0; v < 8; v++) {
      for (int u = 0; u < 8; u++) {
        double sum = 0;
        for (int y = 0; y < 32; y++) {
          final cosV = math.cos((2 * y + 1) * v * math.pi / 64);
          for (int x = 0; x < 32; x++) {
            final cosU = math.cos((2 * x + 1) * u * math.pi / 64);
            sum += small[y * 32 + x] * cosU * cosV;
          }
        }
        dct8x8[v * 8 + u] = sum;
      }
    }

    // 中位数（64 个系数）
    final sorted = dct8x8.toList()..sort();
    final median = sorted[32];

    // 64-bit 哈希 → 16 个 hex
    final buffer = StringBuffer();
    for (int i = 0; i < 64; i += 4) {
      int nibble = 0;
      for (int j = 0; j < 4; j++) {
        if (dct8x8[i + j] > median) {
          nibble |= (1 << (3 - j));
        }
      }
      buffer.write(nibble.toRadixString(16));
    }
    return buffer.toString();
  }

  /// 重建曲绘索引
  Future<void> rebuildCache({
    void Function(int current, int total)? onProgress,
  }) async {
    await clearCache();
    await precomputeHashes(onProgress: onProgress);
  }

  Future<void> clearCache() async {
    try {
      for (final version in const [_cacheVersion, 3]) {
        final file = await _getCacheFile(version: version);
        if (await file.exists()) await file.delete();
      }
      _featureCache = null;
      _remoteAttempted = null;
    } catch (e) {
      debugPrint('清除曲绘特征缓存失败: $e');
    }
  }

  // ─── 运行时特征缓存访问 ─────────────────────────────────────

  Future<Map<String, Map<String, dynamic>>> getCachedFeatures() async {
    if (_featureCache != null) return _featureCache!;
    final state = await _loadCacheStateFromFile();
    _featureCache = state.features;
    _remoteAttempted = state.attempted;
    return _featureCache!;
  }

  // ─── 识别入口（保持原有 API） ─────────────────────────────────

  /// 识别照片中最匹配的曲绘
  Future<Map<String, dynamic>?> recognizeCover(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('照片文件不存在: $imagePath');
        return null;
      }
      final bytes = await file.readAsBytes();
      final photoFeatures = await compute(_extractPhotoFeatures, bytes);
      final photoHash = photoFeatures['hash'] as String;
      final photoR = photoFeatures['r'] as int;
      final photoG = photoFeatures['g'] as int;
      final photoB = photoFeatures['b'] as int;

      // 读缓存
      final cachedFeatures = await getCachedFeatures();
      if (cachedFeatures.isEmpty) {
        debugPrint('曲绘特征缓存为空，请先预计算');
        return null;
      }

      // 比对所有曲绘（缓存键为 coverId）
      final allMatches = <Map<String, dynamic>>[];
      for (final entry in cachedFeatures.entries) {
        final feat = entry.value;
        final refHash = feat['ph'] as String;
        final refR = feat['r'] as int;
        final refG = feat['g'] as int;
        final refB = feat['b'] as int;

        final hashDist = _hammingDistance(photoHash, refHash);
        final colorDist =
            _colorDistance(photoR, photoG, photoB, refR, refG, refB);

        final hashSim = (64 - hashDist) / 64.0;
        final colorSim = 1.0 - (colorDist / 441.67);

        final combinedSim = 0.55 * hashSim + 0.45 * colorSim;

        allMatches.add({
          'coverId': entry.key,
          'hashDistance': hashDist,
          'hashSimilarity': hashSim * 100,
          'colorSimilarity': colorSim * 100,
          'combinedSimilarity': combinedSim,
        });
      }

      allMatches.sort((a, b) => (b['combinedSimilarity'] as double)
          .compareTo(a['combinedSimilarity'] as double));
      final topCandidates = allMatches.take(50).toList();
      if (topCandidates.isEmpty) {
        debugPrint('曲绘特征缓存没有可用条目');
        return null;
      }

      // 填充全量歌曲信息（水鱼 + Union 非国服）
      final musicManager = MaimaiMusicDataManager();
      var songs = await musicManager.getCachedSongs();
      if (songs == null || songs.isEmpty) {
        await musicManager.fetchAndUpdateMusicData();
        songs = await musicManager.getCachedSongs();
      }
      final coverToSong = _buildCoverToSongMap(songs ?? const <Song>[]);

      for (final match in topCandidates) {
        final coverId = match['coverId'] as String;
        final combinedSim = match['combinedSimilarity'] as double;
        match['similarity'] = combinedSim * 100;
        final song = coverToSong[coverId];
        if (song != null) {
          match['songId'] = song.id;
          match['songTitle'] = song.title;
          match['artist'] = song.basicInfo.artist;
          match['isExtra'] = song.isExtra;
        } else {
          match['songId'] = coverId;
          match['songTitle'] = '歌曲 #$coverId';
          match['artist'] = '';
          match['isExtra'] = false;
        }
      }

      final validCandidates = topCandidates.where((m) {
        final title = m['songTitle'] as String? ?? '';
        return title.isNotEmpty && !title.startsWith('歌曲 #');
      }).toList();

      final best = validCandidates.isNotEmpty
          ? validCandidates.first
          : topCandidates.first;
      final bestSim = best['similarity'] as double;

      const lowConfidenceThreshold = 50.0;
      final lowConfidence = bestSim < lowConfidenceThreshold;

      if (lowConfidence) {
        debugPrint(
            '最佳匹配综合相似度过低 ($bestSim% < $lowConfidenceThreshold%)，可能并非曲绘照片');
      }

      return {
        'songId': best['songId'],
        'similarity': bestSim,
        'hashSimilarity': best['hashSimilarity'],
        'colorSimilarity': best['colorSimilarity'],
        'songTitle': best['songTitle'],
        'artist': best['artist'],
        'topMatches': topCandidates,
        'lowConfidence': lowConfidence,
      };
    } catch (e) {
      debugPrint('曲绘识别失败: $e');
      return null;
    }
  }

  // ─── 距离计算 ────────────────────────────────────────────────

  int _hammingDistance(String hash1, String hash2) {
    if (hash1.length != hash2.length) return 64;
    int distance = 0;
    for (int i = 0; i < hash1.length; i++) {
      try {
        final v1 = int.parse(hash1[i], radix: 16);
        final v2 = int.parse(hash2[i], radix: 16);
        distance += _popCount(v1 ^ v2);
      } catch (e) {
        return 64;
      }
    }
    return distance;
  }

  double _colorDistance(int r1, int g1, int b1, int r2, int g2, int b2) {
    final dr = (r1 - r2).toDouble();
    final dg = (g1 - g2).toDouble();
    final db = (b1 - b2).toDouble();
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  int _popCount(int n) {
    int count = 0;
    int v = n;
    while (v != 0) {
      v &= (v - 1);
      count++;
    }
    return count;
  }
}
