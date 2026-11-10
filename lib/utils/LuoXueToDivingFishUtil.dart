/**
 * 落雪数据 → 水鱼数据工具类
 * */
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_flutter_app/entity/DivingFish/RecordItem.dart';
import 'package:my_first_flutter_app/entity/LuoXue/Collection.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/entity/LuoXue/LuoXueScore.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'StringUtil.dart';

class LuoXueToDivingFishUtil {
  /// 同版本的国服曲库减去收藏品要求歌曲集；只用于展示，不参与进度统计。
  static Future<List<Song>> getConditionExcludedSongs(Collection collection,
      {Map<CollectionRequiredSong, Song?>? matched}) async {
    final requiredSongs = [
      for (final item in collection.required ?? <CollectionRequired>[])
        ...?item.songs,
    ];
    if (requiredSongs.isEmpty) return [];
    final map = matched ?? await getSongsFromCache(collection);
    final versions = map.values
        .whereType<Song>()
        .map((song) => StringUtil.formatVersion2(song.basicInfo.from))
        .toSet();
    if (versions.isEmpty) return [];
    String identity(String title, String type) =>
        '${decodeUnicode(title)}:${_getTypeLabel(type.toLowerCase()).toUpperCase()}';
    final requiredKeys =
        requiredSongs.map((song) => identity(song.title, song.type)).toSet();
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? [];
    final excluded = <String, Song>{};
    for (final song in songs) {
      if (song.isExtra ||
          !versions.contains(StringUtil.formatVersion2(song.basicInfo.from)) ||
          requiredKeys.contains(identity(song.title, song.type))) continue;
      excluded['${song.id}:${song.type}'] = song;
    }
    return excluded.values.toList()
      ..sort((a, b) =>
          (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
  }

  // 解码 Unicode 编码的字符串
  static String decodeUnicode(String input) {
    if (input.isEmpty) {
      return input;
    }

    RegExp unicodeRegExp = RegExp(r'\\u([0-9a-fA-F]{4})');
    return input.replaceAllMapped(unicodeRegExp, (match) {
      int code = int.parse(match.group(1)!, radix: 16);
      return String.fromCharCode(code);
    });
  }

  // 根据 Collection 对象中的 required.songs 列表，从缓存中查找相应的歌曲信息
  static Future<Map<CollectionRequiredSong, Song?>> getSongsFromCache(
      Collection collection) async {
    // 创建结果映射，键为 CollectionRequiredSong，值为对应的 Song 对象
    final Map<CollectionRequiredSong, Song?> result = {};

    // 检查 Collection 对象是否有 required 列表
    if (collection.required == null || collection.required!.isEmpty) {
      return result;
    }

    // 获取缓存的歌曲数据
    final songs = await MaimaiMusicDataManager().getCachedSongs();
    if (songs == null || songs.isEmpty) {
      return result;
    }

    // 先建索引：几百首条件曲目逐个遍历全曲库并解码，会卡住主线程。
    // putIfAbsent 保证同名同类型时仍取曲库里靠前的那首。
    final songsByTitleAndType = <String, Song>{};
    for (final song in songs) {
      final key =
          '${decodeUnicode(song.title)}|${decodeUnicode(song.type).toLowerCase()}';
      songsByTitleAndType.putIfAbsent(key, () => song);
    }

    // 遍历 required 列表
    for (final requiredItem in collection.required!) {
      // 检查是否有 songs 列表
      if (requiredItem.songs == null || requiredItem.songs!.isEmpty) {
        continue;
      }

      // 根据 title 和 type 查找对应的歌曲：
      // Collections 中的 standard 对应缓存中的 SD，dx 对应 DX
      for (final requiredSong in requiredItem.songs!) {
        final targetType = requiredSong.type.toLowerCase();
        final title = requiredSong.title;
        result[requiredSong] = (targetType == 'standard'
                ? songsByTitleAndType['$title|sd']
                : null) ??
            songsByTitleAndType['$title|$targetType'];
      }
    }

    return result;
  }

  // 简化版本：直接返回匹配的歌曲列表
  static Future<List<Song>> getMatchedSongs(Collection collection) async {
    final songMap = await getSongsFromCache(collection);
    final matchedList =
        songMap.values.where((song) => song != null).cast<Song>().toList();
    return matchedList;
  }

  // 根据 levelIndex 获取对应的难度标签
  static String _getLevelLabel(int levelIndex) {
    return ChartDifficulty.labelOf(levelIndex, fallback: '');
  }

  // 根据类型字符串获取标准化的类型标签
  static String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'standard':
        return 'SD';
      case 'dx':
        return 'DX';
      case 'utage':
        return ChartDifficulty.utageLabel;
      default:
        return type;
    }
  }

  // 转换 LuoXueScore 到 RecordItem 对象（同步版本，需要提前获取歌曲缓存）
  static RecordItem toRecordItem(LuoXueScore score, {Song? song}) {
    // 根据 levelIndex 生成难度标签
    String levelLabel = _getLevelLabel(score.levelIndex.toInt());

    // 根据 levelIndex 获取对应的 ds 值
    double ds = 0.0;
    if (song != null) {
      int index = score.levelIndex.toInt();
      if (index >= 0 && index < song.ds.length) {
        ds = song.ds[index];
      }
    }

    // 获取 songId：优先使用缓存中歌曲的 id，否则由落雪 id 换算。
    // 落雪的 id 是基础 id，谱面类型单独给出；水鱼的 DX 谱 id = 10000 + 基础 id。
    // 以前回退时直接用基础 id，DX 谱成绩就以不存在的标准谱 id 上传到了排行榜。
    int songId = score.id.toInt();
    if (score.type.toLowerCase() == 'dx' && songId > 0 && songId < 10000) {
      songId += 10000;
    }
    if (song != null && song.id.isNotEmpty) {
      int? parsedId = int.tryParse(song.id);
      if (parsedId != null) {
        songId = parsedId;
      }
    }

    return RecordItem(
      achievements: score.achievements,
      ds: ds,
      dxScore: score.dxScore.floor(),
      fc: score.fc ?? '',
      fs: score.fs ?? '',
      level: score.level,
      levelIndex: score.levelIndex.toInt(),
      levelLabel: levelLabel,
      ra: score.dxRating.toInt(),
      rate: score.rate,
      songId: songId,
      title: decodeUnicode(score.songName),
      type: _getTypeLabel(score.type),
    );
  }

  // 转换 LuoXueScore 到 RecordItem 对象（异步版本，自动从缓存查找歌曲）
  static Future<RecordItem> toRecordItemAsync(LuoXueScore score) async {
    // 从缓存中查找对应的歌曲
    Song? song;
    try {
      final songs = await MaimaiMusicDataManager().getCachedSongs();
      if (songs != null && songs.isNotEmpty) {
        song = songs.firstWhere(
          (s) =>
              s.basicInfo.title == score.songName &&
              s.type == _getTypeLabel(score.type),
          orElse: () => Song(
            id: '',
            title: '',
            type: '',
            ds: [],
            level: [],
            cids: [],
            charts: [],
            basicInfo: BasicInfo(
              title: '',
              artist: '',
              genre: '',
              bpm: 0,
              releaseDate: '',
              from: '',
              isNew: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('查找歌曲失败: $e');
    }

    return toRecordItem(score, song: song);
  }
}
