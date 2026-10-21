import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../service/SongMediaCache.dart';

class LuoXueSongUtil {
  // 单例模式
  static final LuoXueSongUtil _instance = LuoXueSongUtil._internal();
  factory LuoXueSongUtil() => _instance;
  LuoXueSongUtil._internal();

  // 音乐文件基础URL
  static const String _baseUrl = 'https://assets2.lxns.net/maimai/music/';
  // 音乐文件扩展名
  static const String _fileExtension = '.mp3';

  /// 把**水鱼**歌曲 id 换成**落雪音源** id。
  ///
  /// 音源 URL 形如 `assets2.lxns.net/maimai/music/{id}.mp3`，其命名对**所有**
  /// 曲目都是「水鱼 id % 10000」——包括 6 位数的宴会场。
  ///
  /// 线上实测（1394 首全量 + 宴会场 62 首逐首请求）：
  /// - 5 位 DX 曲：11466 → 1466 命中，11466 本身 404
  /// - 6 位宴会场：100018 → 18 命中，100018 本身 404
  ///   （62 首取余后**全部** 200，原始 6 位**全部** 404）
  ///
  /// ⚠ 与 `LuoXueScoreUploadService.toLxnsSongId` 的区别：那个是给**成绩 API**
  /// 用的，宴会场在落雪曲库里确实另有 6 位 id（`song/list` 里存在 100018 这个
  /// 条目），所以那边原样保留；但**音频文件**没按那套命名，直接原样请求会 404，
  /// 在播放页表现为「静默无声」。
  ///
  /// 非法 id 返回 0，调用方应据此跳过播放（而不是拿 0 去请求）。
  ///
  /// ⚠ 注意与 `LuoXueScoreUploadService.toLxnsSongId`（成绩 API）的差别：
  /// 那个对 6 位宴会场 id **原样保留**，这个**一律取余**。两套规则不能混用。
  static int toLxnsMusicId(String? divingFishSongId) {
    final id = int.tryParse('${divingFishSongId ?? ''}'.trim());
    if (id == null || id <= 0) return 0;
    return id % 10000;
  }

  String getMusicUrl(String musicId) => '$_baseUrl$musicId$_fileExtension';

  Future<bool> isMusicCached(String musicId) async =>
      await SongMediaCache.instance
          .existingAudio(musicId, audioId: int.tryParse(musicId)) !=
      null;

  Future<File?> downloadAndCacheMusic(String musicId) => getMusicFile(musicId);

  Future<File?> getMusicFile(String musicId) async {
    try {
      return await SongMediaCache.instance.ensureAudio(musicId,
          audioId: int.tryParse(musicId), urls: [getMusicUrl(musicId)]);
    } catch (error) {
      debugPrint('读取猜歌音源失败: $error');
      return null;
    }
  }

  Future<void> clearMusicCache() => SongMediaCache.instance.clear('audio');

  Future<int> getCacheSize() async =>
      (await SongMediaCache.instance.audioUsage()).$1;
  // 格式化文件大小
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  // 获取歌曲时长
  Future<Duration?> getSongDuration(String musicId) async {
    try {
      final file = await getMusicFile(musicId);
      if (file == null) return null;

      final player = AudioPlayer();
      await player.setFilePath(file.path);
      final duration = await player.duration;
      await player.dispose();
      return duration;
    } catch (e) {
      debugPrint('Error getting song duration: $e');
      return null;
    }
  }
}
