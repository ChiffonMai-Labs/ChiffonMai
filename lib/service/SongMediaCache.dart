import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../utils/ApiClient.dart';

typedef MediaCacheProgress = void Function(
    double? progress, double bytesPerSecond, String status);

/// 播放、猜歌和导出共用音源缓存；PV 使用独立目录。
/// 只有完整文件才会发布到正式路径，同一资源的并发请求共用一次下载。
class SongMediaCache {
  SongMediaCache({
    Future<Directory> Function()? documents,
    Future<Directory> Function()? temporary,
    Future<http.StreamedResponse> Function(Uri, Map<String, String>)? fetch,
    this.readLegacyCache = true,
  })  : _documents = documents ?? getApplicationDocumentsDirectory,
        _temporary = temporary ?? getTemporaryDirectory,
        _fetch = fetch ??
            ((uri, headers) => ApiClient.getStream(uri, headers: headers));

  static final instance = SongMediaCache();
  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _temporary;
  final Future<http.StreamedResponse> Function(Uri, Map<String, String>) _fetch;
  final bool readLegacyCache;
  final Map<String, Future<File>> _inFlight = {};
  final Map<String, int> _generation = {'audio': 0, 'pv': 0};
  late final _legacy = CacheManager(Config('music_cache',
      stalePeriod: const Duration(days: 30), maxNrOfCacheObjects: 1000));

  static int audioIdFor(String songId) {
    final id = int.tryParse(songId.trim());
    return id == null || id <= 0 ? 0 : id % 10000;
  }

  String _safe(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  String _audioKey(String songId, int? audioId) {
    final id = audioId ?? audioIdFor(songId);
    return id > 0 ? 'audio_$id.mp3' : 'chart_audio_${_safe(songId)}.mp3';
  }

  Future<File> _file(String kind, String key) async {
    final root = await _documents();
    final directory = Directory('${root.path}/portable_${kind}_cache');
    await directory.create(recursive: true);
    return File('${directory.path}/$key');
  }

  Future<bool> _valid(File file, String kind) async {
    try {
      if (!await file.exists() || await file.length() < 1024) return false;
      final input = await file.open();
      try {
        final head = await input.read(12);
        if (kind == 'pv') {
          return head.length >= 8 &&
              String.fromCharCodes(head.sublist(4, 8)) == 'ftyp';
        }
        return head.length >= 3 &&
            ((head[0] == 0x49 && head[1] == 0x44 && head[2] == 0x33) ||
                (head[0] == 0xff && (head[1] & 0xe0) == 0xe0));
      } finally {
        await input.close();
      }
    } catch (_) {
      return false;
    }
  }

  Future<File?> existingAudio(String songId, {int? audioId}) async {
    final generation = _generation['audio'];
    final target = await _file('audio', _audioKey(songId, audioId));
    if (await _valid(target, 'audio')) return target;
    final root = await _documents();
    final temporary = await _temporary();
    final id = audioId ?? audioIdFor(songId);
    final ids = {songId, if (id > 0) '$id', if (id > 0) '${id + 10000}'};
    final candidates = <File>[
      for (final raw in ids) ...[
        File('${root.path}/portable_audio_cache/chart_audio_${_safe(raw)}.mp3'),
        File('${temporary.path}/chart_audio_${_safe(raw)}.mp3'),
        File('${root.path}/music_cache/wmc_${_safe(raw)}.mp3'),
      ],
      if (id > 0) File('${root.path}/music_cache/$id.mp3'),
    ];
    if (readLegacyCache && id > 0) {
      try {
        final cached = await _legacy
            .getFileFromCache('https://assets2.lxns.net/maimai/music/$id.mp3');
        if (cached != null) candidates.add(cached.file);
      } catch (_) {}
    }
    for (final candidate in candidates) {
      if (!await _valid(candidate, 'audio')) continue;
      if (_generation['audio'] != generation) return null;
      // 使用单独的迁移文件，避免把复制中断的内容当成完整缓存。
      final migration = File(
          '${target.path}.${DateTime.now().microsecondsSinceEpoch}.migrate');
      try {
        await candidate.copy(migration.path);
        if (_generation['audio'] != generation) return null;
        if (await _valid(target, 'audio')) return target;
        if (await target.exists()) await target.delete();
        return await migration.rename(target.path);
      } catch (_) {
        // 旧文件仍可播放时，迁移失败不应迫使用户重新下载。
        if (_generation['audio'] == generation) return candidate;
      } finally {
        try {
          if (await migration.exists()) await migration.delete();
        } catch (_) {}
      }
    }
    return null;
  }

  Future<File?> existingPv(String songId) async {
    final file = await _file('pv', 'pv_${_safe(songId)}.mp4');
    return await _valid(file, 'pv') ? file : null;
  }

  Future<File> ensureAudio(
    String songId, {
    int? audioId,
    required List<String> urls,
    MediaCacheProgress? onProgress,
  }) =>
      _ensure('audio', _audioKey(songId, audioId), urls, const {},
          () => existingAudio(songId, audioId: audioId), onProgress);

  Future<File> ensurePv(
    String songId, {
    required String url,
    Map<String, String> headers = const {},
    MediaCacheProgress? onProgress,
  }) =>
      _ensure('pv', 'pv_${_safe(songId)}.mp4', [url], headers,
          () => existingPv(songId), onProgress);

  Future<File> _ensure(
      String kind,
      String key,
      List<String> urls,
      Map<String, String> headers,
      Future<File?> Function() existing,
      MediaCacheProgress? onProgress) async {
    final taskKey = '$kind/$key';
    final running = _inFlight[taskKey];
    if (running != null) return running;
    final generation = _generation[kind]!;
    final task = () async {
      final cached = await existing();
      if (_generation[kind] != generation) throw StateError('缓存已清理');
      if (cached != null) {
        onProgress?.call(1, 0, '已从本地缓存读取${kind == 'audio' ? '音频' : 'PV'}');
        return cached;
      }
      return _download(kind, key, urls, headers, generation, onProgress);
    }();
    _inFlight[taskKey] = task;
    try {
      return await task;
    } finally {
      _inFlight.remove(taskKey);
    }
  }

  Future<File> _download(
      String kind,
      String key,
      List<String> urls,
      Map<String, String> headers,
      int generation,
      MediaCacheProgress? onProgress) async {
    Object? lastError;
    final target = await _file(kind, key);
    for (final url in urls) {
      final part = File('${target.path}.part');
      try {
        onProgress?.call(null, 0, '正在下载${kind == 'audio' ? '音频文件' : 'PV'}…');
        // MP3/MP4 已压缩，避免媒体传输再走 gzip 解压，也便于校验文件长度。
        final response = await _fetch(
                Uri.parse(url), {'Accept-Encoding': 'identity', ...headers})
            .timeout(const Duration(seconds: 30));
        if (response.statusCode != 200) {
          await response.stream.drain<void>();
          throw HttpException('HTTP ${response.statusCode}');
        }
        final type = response.headers['content-type']?.toLowerCase() ?? '';
        if (type.contains('text/html') || type.contains('application/json')) {
          await response.stream.drain<void>();
          throw const FormatException('响应不是媒体文件');
        }
        final encoding = response.headers['content-encoding'];
        final total = encoding == null || encoding == 'identity'
            ? response.contentLength
            : null;
        var received = 0;
        var sampledBytes = 0;
        var sampledMicros = 0;
        final watch = Stopwatch()..start();
        final sink = part.openWrite();
        try {
          // addStream 保留磁盘写入的背压，避免高速下载时不断堆积待写数据。
          await sink.addStream(response.stream
              .timeout(const Duration(seconds: 30))
              .transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (chunk, output) {
              if (_generation[kind] != generation) {
                throw StateError('缓存已清理');
              }
              received += chunk.length;
              output.add(chunk);
              final now = watch.elapsedMicroseconds;
              final elapsed = now - sampledMicros;
              // 每秒最多更新四次界面，速度按最近一次采样区间计算。
              if (elapsed < 250000) return;
              final speed = (received - sampledBytes) * 1000000 / elapsed;
              sampledBytes = received;
              sampledMicros = now;
              onProgress?.call(
                  total != null && total > 0
                      ? (received / total).clamp(0.0, 1.0)
                      : null,
                  speed,
                  '正在下载${kind == 'audio' ? '音频文件' : 'PV'}…');
            },
          )));
          await sink.close();
        } catch (_) {
          // addStream 出错后底层文件可能已关闭，清理异常不能掩盖原始错误。
          try {
            await sink.close();
          } catch (_) {}
          rethrow;
        }
        if (_generation[kind] != generation) throw StateError('缓存已清理');
        if ((total != null && total > 0 && received != total) ||
            !await _valid(part, kind)) {
          throw const FormatException('媒体文件不完整或格式无效');
        }
        if (await target.exists()) await target.delete();
        final saved = await part.rename(target.path);
        onProgress?.call(1, 0, '文件已缓存');
        return saved;
      } catch (error) {
        lastError = error;
        if (_generation[kind] != generation) rethrow;
      } finally {
        if (await part.exists()) await part.delete();
      }
    }
    throw StateError('媒体下载失败：$lastError');
  }

  Future<(int, int)> audioUsage() async {
    final root = await _documents();
    final temporary = await _temporary();
    final files = <String, File>{};
    for (final directory in [
      Directory('${root.path}/portable_audio_cache'),
      Directory('${root.path}/music_cache'),
      Directory('${temporary.path}/music_cache')
    ]) {
      if (!await directory.exists()) continue;
      await for (final file in directory.list(followLinks: false)) {
        if (file is File) files[file.path] = file;
      }
    }
    if (await temporary.exists()) {
      await for (final file in temporary.list(followLinks: false)) {
        if (file is File &&
            file.uri.pathSegments.last.startsWith('chart_audio_'))
          files[file.path] = file;
      }
    }
    var bytes = 0;
    for (final file in files.values) {
      try {
        bytes += await file.length();
      } catch (_) {}
    }
    return (bytes, files.length);
  }

  Future<void> clear(String kind) async {
    _generation[kind] = _generation[kind]! + 1;
    await Future.wait(_inFlight.entries
        .where((e) => e.key.startsWith('$kind/'))
        .map((e) async {
      try {
        await e.value;
      } catch (_) {}
    }).toList());
    final root = await _documents();
    final directory = Directory('${root.path}/portable_${kind}_cache');
    if (await directory.exists()) await directory.delete(recursive: true);
    if (kind == 'audio') {
      final legacyDirectory = Directory('${root.path}/music_cache');
      if (await legacyDirectory.exists())
        await legacyDirectory.delete(recursive: true);
      if (readLegacyCache) await _legacy.emptyCache();
      final temporary = await _temporary();
      final oldFiles = Directory('${temporary.path}/music_cache');
      if (await oldFiles.exists()) await oldFiles.delete(recursive: true);
      await for (final file in temporary.list(followLinks: false)) {
        if (file is File &&
            file.uri.pathSegments.last.startsWith('chart_audio_'))
          await file.delete();
      }
    }
  }
}
