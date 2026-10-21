import 'package:just_audio/just_audio.dart';

import '../../entity/Portable/PortableSong.dart';
import '../SongMediaCache.dart';

/// 队列音源只在平台实际请求时准备缓存，上一首/下一首/自动续播走同一入口。
class CachedSongAudioSource extends StreamAudioSource {
  CachedSongAudioSource(this.song, {super.tag, SongMediaCache? cache})
      : _cache = cache ?? SongMediaCache.instance;

  final PortableSong song;
  final SongMediaCache _cache;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final file = await _cache.ensureAudio(song.divingFishId,
        audioId: song.audioId, urls: song.audioUrls);
    final length = await file.length();
    final offset = start ?? 0;
    if (offset < 0 || offset > length)
      throw RangeError.range(offset, 0, length);
    final limit = (end ?? length).clamp(offset, length);
    return StreamAudioResponse(
      sourceLength: length,
      contentLength: limit - offset,
      offset: offset,
      stream: file.openRead(offset, limit),
      contentType: 'audio/mpeg',
    );
  }
}
