import 'dart:io';
import '../../entity/Portable/PortableSong.dart';
import '../SongMediaCache.dart';

typedef PortableAudioProgress = MediaCacheProgress;

/// 随身听沿用统一音源缓存，不再维护一份独立下载实现。
class PortableAudioCache {
  PortableAudioCache._();
  static final instance = PortableAudioCache._();

  Future<File?> existing(PortableSong song) => SongMediaCache.instance
      .existingAudio(song.divingFishId, audioId: song.audioId);

  Future<File> ensure(PortableSong song, {PortableAudioProgress? onProgress}) =>
      SongMediaCache.instance.ensureAudio(song.divingFishId,
          audioId: song.audioId, urls: song.audioUrls, onProgress: onProgress);
}
