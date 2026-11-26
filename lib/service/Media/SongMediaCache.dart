import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import '../../utils/AppTaskActivity.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../utils/ApiClient.dart';
import '../../utils/AppError.dart';

typedef MediaCacheProgress = void Function(
    double? progress, double bytesPerSecond, String status);

class _MediaCacheDownload {
  _MediaCacheDownload(Iterable<String> urls) : urls = urls.toSet();

  final Set<String> urls;
  late final Future<File> file;
  final _listeners = <MediaCacheProgress>[];
  (double?, double, String)? _latestProgress;

  void addListener(MediaCacheProgress listener) {
    _listeners.add(listener);
    if (_latestProgress case (final progress, final speed, final status)) {
      listener(progress, speed, status);
    }
  }

  void report(double? progress, double speed, String status) {
    _latestProgress = (progress, speed, status);
    final listenerCount = _listeners.length;
    for (var i = 0; i < listenerCount; i++) {
      _listeners[i](progress, speed, status);
    }
  }
}

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
            ((uri, headers) => ApiClient.getStream(
                  uri,
                  headers: headers,
                  timeout: const Duration(seconds: 30),
                ));

  static final instance = SongMediaCache();
  static const Map<String, String> _wmcDefaultHeaders = {
    'User-Agent': 'Mozilla/5.0 (Android) AppleWebKit/537.36',
    'Referer': 'https://download.wmc.pub/',
  };
  static final RegExp _httpStatusPattern = RegExp(r'^HTTP (\d{3})\b');
  final Future<Directory> Function() _documents;
  final Future<Directory> Function() _temporary;
  final Future<http.StreamedResponse> Function(Uri, Map<String, String>) _fetch;
  final bool readLegacyCache;
  final Map<String, _MediaCacheDownload> _inFlight = {};
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

  Map<String, String> _buildRequestHeaders(
    Uri uri,
    Map<String, String> headers,
  ) {
    // MP3/MP4 已压缩，避免媒体传输再走 gzip 解压，也便于校验文件长度。
    final merged = <String, String>{
      'Accept-Encoding': 'identity',
      ...headers,
    };
    if (uri.host.toLowerCase() == 'download.wmc.pub') {
      final lowerKeys = merged.keys.map((k) => k.toLowerCase()).toSet();
      for (final entry in _wmcDefaultHeaders.entries) {
        if (!lowerKeys.contains(entry.key.toLowerCase())) {
          merged[entry.key] = entry.value;
        }
      }
    }
    return merged;
  }

  bool _isRetryableDownloadError(Object error) {
    if (error is TimeoutException ||
        error is SocketException ||
        error is TlsException ||
        error is http.ClientException) {
      return true;
    }
    if (error is HttpException) {
      final match = _httpStatusPattern.firstMatch(error.message);
      if (match != null) {
        final status = int.tryParse(match.group(1)!);
        if (status != null && status >= 400 && status < 500) {
          return false;
        }
        return status != null && status >= 500;
      }
      // 底层连接中断等非 4xx 的传输层异常允许重试一次。
      return true;
    }
    return false;
  }

  Future<File> _ensure(
          String kind,
          String key,
          List<String> urls,
          Map<String, String> headers,
          Future<File?> Function() existing,
          MediaCacheProgress? onProgress) =>
      AppTaskActivity.run(() => _ensureInternal(
          kind, key, urls, headers, existing, onProgress));

  Future<File> _ensureInternal(
    String kind,
    String key,
    List<String> urls,
    Map<String, String> headers,
    Future<File?> Function() existing,
    MediaCacheProgress? onProgress,
  ) async {
    final taskKey = '$kind/$key';
    final generation = _generation[kind]!;
    final running = _inFlight[taskKey];
    if (running != null) {
      if (onProgress != null) running.addListener(onProgress);
      try {
        return await running.file;
      } catch (_) {
        if (_generation[kind] != generation) rethrow;
        final remainingUrls =
            urls.where((url) => !running.urls.contains(url)).toList();
        if (remainingUrls.isEmpty) rethrow;
        // 复用的在途任务失败且当前调用方还有未尝试的候选地址，针对剩余地址补试。
        return _ensureInternal(
            kind, key, remainingUrls, headers, existing, onProgress);
      }
    }
    final task = _MediaCacheDownload(urls);
    if (onProgress != null) task.addListener(onProgress);
    task.file = () async {
      try {
        final cached = await existing();
        if (_generation[kind] != generation) {
          throw AppError(
            code: 'DATA-MEDIA-CACHE-CLEARED',
            userMessage: '媒体缓存已被清理，请重试',
            stage: '读取媒体缓存',
            retryable: true,
          ).asStateError();
        }
        if (cached != null) {
          task.report(
              1,
              0,
              appL10n.svcLoadedP0FromTheLocalCache(
                  (kind == 'audio' ? appL10n.svcAudio : 'PV').toString()));
          return cached;
        }
        return await _download(
            kind, key, urls, headers, generation, task.report);
      } finally {
        if (identical(_inFlight[taskKey], task)) {
          _inFlight.remove(taskKey);
        }
      }
    }();
    _inFlight[taskKey] = task;
    return await task.file;
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
      final uri = Uri.parse(url);
      final requestHeaders = _buildRequestHeaders(uri, headers);
      for (var attempt = 0; attempt < 2; attempt++) {
        if (_generation[kind] != generation) {
          throw AppError(
            code: 'DATA-MEDIA-CACHE-CLEARED',
            userMessage: '媒体缓存已被清理，请重试',
            stage: '下载媒体资源',
            retryable: true,
          ).asStateError();
        }
        final part = File('${target.path}.part');
        var retryCurrentUrl = false;
        try {
          onProgress?.call(
              null,
              0,
              appL10n.svcDownloadingP0(
                  (kind == 'audio' ? appL10n.svcAudioFile : 'PV').toString()));
          final response = await _fetch(uri, requestHeaders)
              .timeout(const Duration(seconds: 30));
          if (response.statusCode != 200) {
            await response.stream.drain<void>();
            throw HttpException('HTTP ${response.statusCode}');
          }
          final type = response.headers['content-type']?.toLowerCase() ?? '';
          if (type.contains('text/html') || type.contains('application/json')) {
            await response.stream.drain<void>();
            throw FormatException(appL10n.svcTheResponseIsNotAMediaFile);
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
                  throw AppError(
                    code: 'DATA-MEDIA-CACHE-CLEARED',
                    userMessage: '媒体缓存已被清理，请重试',
                    stage: '写入媒体缓存',
                    retryable: true,
                  ).asStateError();
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
                    appL10n.svcDownloadingP0(
                        (kind == 'audio' ? appL10n.svcAudioFile : 'PV')
                            .toString()));
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
          if (_generation[kind] != generation) {
            throw AppError(
              code: 'DATA-MEDIA-CACHE-CLEARED',
              userMessage: '媒体缓存已被清理，请重试',
              stage: '校验媒体缓存',
              retryable: true,
            ).asStateError();
          }
          if ((total != null && total > 0 && received != total) ||
              !await _valid(part, kind)) {
            throw FormatException(appL10n.svcTheMediaFileIsIncompleteOrHas);
          }
          if (await target.exists()) await target.delete();
          final saved = await part.rename(target.path);
          onProgress?.call(1, 0, appL10n.svcFileCached);
          return saved;
        } catch (error) {
          lastError = error;
          if (_generation[kind] != generation) rethrow;
          if (attempt == 0 && _isRetryableDownloadError(error)) {
            retryCurrentUrl = true;
          }
        } finally {
          if (await part.exists()) await part.delete();
        }
        if (!retryCurrentUrl) break;
        // 瞬时网络抖动或 5xx 时短暂等待后重试一次。
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
    final mapped = AppErrorMapper.from(
      lastError ?? '未知下载错误',
      stage: '下载媒体资源',
    );
    throw AppError(
      code: 'NET-MEDIA-DOWNLOAD',
      userMessage: appL10n.svcMediaDownloadFailedP0(mapped.userMessage),
      stage: '下载媒体资源',
      httpStatus: mapped.httpStatus,
      requestId: mapped.requestId,
      technicalDetail: mapped.technicalDetail,
    ).asStateError();
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
        await e.value.file;
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
