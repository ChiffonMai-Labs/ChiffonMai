import 'dart:io';
import 'package:http/http.dart' as http;

import '../../entity/Portable/PortableSong.dart';
import '../../utils/ExportPathUtil.dart';
import '../SongMediaCache.dart';

typedef AudioFileWriter = Future<File> Function(String fileName,
    Stream<List<int>> stream, void Function(String)? onFallback);

/// 导出先复用播放缓存，公开目录仍统一走 ExportPathUtil。
class PortableSongDownloadService {
  static final instance = PortableSongDownloadService();
  final SongMediaCache _cache;
  final AudioFileWriter _write;
  final Map<int, Future<File>> _inFlight = {};

  PortableSongDownloadService({
    Future<http.StreamedResponse> Function(Uri)? fetch,
    AudioFileWriter? write,
    SongMediaCache? cache,
  })  : _cache = cache ??
            (fetch == null
                ? SongMediaCache.instance
                : SongMediaCache(
                    fetch: (uri, _) => fetch(uri), readLegacyCache: false)),
        _write = write ?? _writePublicFile;

  static Future<File> _writePublicFile(String fileName,
          Stream<List<int>> stream, void Function(String)? onFallback) =>
      ExportPathUtil.writeExportStream(
          fileName: fileName,
          stream: stream,
          subDir: '歌曲',
          onFallback: onFallback);

  Future<File> download(PortableSong song,
      {void Function(double? progress)? onProgress,
      void Function(double bytesPerSecond)? onSpeed,
      void Function(String fallbackPath)? onFallback}) async {
    final existing = _inFlight[song.audioId];
    if (existing != null) return existing;
    final task = _download(song, onProgress, onSpeed, onFallback);
    _inFlight[song.audioId] = task;
    try {
      return await task;
    } finally {
      _inFlight.remove(song.audioId);
    }
  }

  Future<File> _download(PortableSong song, void Function(double?)? onProgress,
      void Function(double)? onSpeed, void Function(String)? onFallback) async {
    try {
      final cached = await _cache.ensureAudio(song.divingFishId,
          audioId: song.audioId,
          urls: song.audioUrls, onProgress: (progress, speed, _) {
        onProgress?.call(progress);
        onSpeed?.call(speed);
      });
      final file = await _write(
          '${ExportPathUtil.sanitizeFileName(song.title)}.mp3',
          cached.openRead(),
          onFallback);
      onProgress?.call(1);
      return file;
    } on FileSystemException {
      rethrow;
    } catch (error) {
      throw AudioDownloadSourceException('音源保存失败：$error');
    }
  }
}

class AudioDownloadSourceException implements Exception {
  final String message;
  const AudioDownloadSourceException(this.message);
  @override
  String toString() => message;
}
