import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/entity/DivingFish/UserBest50Entity.dart';
import 'package:my_first_flutter_app/entity/DivingFish/RecordItem.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import '../../utils/Best50Order.dart';
import 'UserPlayDataManager.dart';
import 'MaimaiMusicDataManager.dart';

class UserBest50Manager {
  static final UserBest50Manager _instance = UserBest50Manager._internal();
  factory UserBest50Manager() => _instance;
  UserBest50Manager._internal();

  static const _orderVersion = 1;

  /// 成绩或 Best50 缓存写入后递增，常驻的页面（成绩 Hub）靠它刷新。
  static final ValueNotifier<int> dataRevision = ValueNotifier<int>(0);

  Future<UserBest50Entity> getUserBest50(
    String qq, {
    Map<String, dynamic>? playData,
    List<Song>? songs,
  }) async {
    try {
      // OAuth 用户由 access token 决定，不能再调用按 QQ 查询的旧接口。
      final resolvedPlayData =
          playData ?? await UserPlayDataManager().fetchUserPlayData(qq);
      if (resolvedPlayData == null || resolvedPlayData['records'] is! List) {
        throw Exception('水鱼成绩接口未返回 records');
      }
      final resolvedSongs =
          songs ?? await MaimaiMusicDataManager().getCachedSongs();
      if (resolvedSongs == null || resolvedSongs.isEmpty) {
        throw Exception('缺少歌曲数据，无法区分当前版本歌曲');
      }
      final jsonData = _buildBest50(resolvedPlayData, resolvedSongs);
      await _cacheBest50Data(qq, jsonData);
      return _parseBest50Data(jsonData);
    } catch (e) {
      debugPrint('Error fetching best50 data: $e');
      rethrow;
    }
  }

  Future<void> _cacheBest50Data(String qq, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('best50_data_$qq', json.encode(data));
      await prefs.setString('last_used_qq', qq);
      dataRevision.value++;
    } catch (e) {
      debugPrint('Error caching best50 data: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedBest50Data() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastQQ = prefs.getString('last_used_qq');
      if (lastQQ == null) return null;
      final cacheKey = 'best50_data_$lastQQ';
      final cachedData = prefs.getString(cacheKey);
      if (cachedData == null) return null;
      final cached = json.decode(cachedData) as Map<String, dynamic>;
      if (cached['order_version'] == _orderVersion) return cached;

      // 旧榜单在截断时可能漏掉新的优先项，先尝试用完整成绩重新选曲。
      final playData = await UserPlayDataManager().getCachedUserPlayData();
      final songs = await MaimaiMusicDataManager().getCachedSongs() ?? <Song>[];
      if (prefs.getString('last_used_qq') != lastQQ ||
          prefs.getString(cacheKey) != cachedData) {
        return null;
      }
      final records = playData?['records'];
      if (records is List && records.isNotEmpty && songs.isNotEmpty) {
        try {
          return {...cached, ..._buildBest50(playData!, songs)};
        } catch (e) {
          debugPrint('用完整成绩重排旧 Best50 缓存失败: $e');
        }
      }

      final charts = cached['charts'] as Map? ?? const {};
      final order = Best50Order.fromSongs(songs);
      return {
        ...cached,
        'charts': {
          for (final group in ['sd', 'dx'])
            group: List<Map<String, dynamic>>.from(charts[group] as List? ?? [])
              ..sort(order.compareMaps),
        },
      };
    } catch (e) {
      debugPrint('Error getting cached best50 data: $e');
      return null;
    }
  }

  /// 取用于显示的 Best50：有缓存用缓存，没有就按成绩现算。
  ///
  /// 落雪不写 Best50 缓存（见 LuoXueUserPlayDataManager），只读缓存的地方
  /// 切到落雪后拿不到数据，这里和 Best50 详情页用同一套口径。
  Future<Map<String, dynamic>?> getBest50ForDisplay() async {
    final cached = await getCachedBest50Data();
    if (cached != null) return cached;
    try {
      final playData = await UserPlayDataManager().getCachedUserPlayData();
      final records = playData?['records'];
      if (records is! List || records.isEmpty) return null;
      final songs = await MaimaiMusicDataManager().getCachedSongs();
      return _buildBest50(playData!, songs ?? const []);
    } catch (e) {
      debugPrint('按成绩计算 Best50 失败: $e');
      return null;
    }
  }

  Map<String, dynamic> _buildBest50(
      Map<String, dynamic> playData, List<Song> songs) {
    final (:best35, :best15) = selectCharts(
      _parseRecordItems(playData['records'] as List),
      songs,
    );
    return {
      'order_version': _orderVersion,
      'rating': [...best35, ...best15].fold<int>(0, (sum, r) => sum + r.ra),
      'additional_rating':
          (playData['additional_rating'] as num?)?.toInt() ?? 0,
      'charts': {
        'sd': [for (final r in best35) r.toJson()],
        'dx': [for (final r in best15) r.toJson()],
      },
    };
  }

  static ({List<RecordItem> best35, List<RecordItem> best15}) selectCharts(
      List<RecordItem> records, List<Song> songs) {
    final newSongIds = {
      for (final song in songs)
        if (song.basicInfo.isNew) song.id
    };
    final order = Best50Order.fromSongs(songs);
    final oldSongs = <RecordItem>[];
    final newSongs = <RecordItem>[];
    for (final record in records) {
      (newSongIds.contains('${record.songId}') ? newSongs : oldSongs)
          .add(record);
    }
    oldSongs.sort(order.compareRecords);
    newSongs.sort(order.compareRecords);
    return (
      best35: oldSongs.take(35).toList(),
      best15: newSongs.take(15).toList()
    );
  }

  UserBest50Entity _parseBest50Data(Map<String, dynamic> jsonData) {
    final charts = jsonData['charts'] as Map<String, dynamic>? ?? {};
    return UserBest50Entity(
      additionalRating: (jsonData['additional_rating'] as num?)?.toInt() ?? 0,
      charts: Charts(
        dx: _parseRecordItems(charts['dx'] as List<dynamic>? ?? const []),
        sd: _parseRecordItems(charts['sd'] as List<dynamic>? ?? const []),
      ),
    );
  }

  List<RecordItem> _parseRecordItems(List<dynamic> records) => records
      .whereType<Map<String, dynamic>>()
      .map(RecordItem.fromJson)
      .toList();
}
