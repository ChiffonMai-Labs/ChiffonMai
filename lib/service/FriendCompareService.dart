import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/ApiUrls.dart';
import '../entity/DivingFish/Song.dart';
import '../manager/AWMC/AwmcNetUserPlayDataManager.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../manager/DivingFish/UserPlayDataManager.dart';
import '../manager/LuoXue/LuoXueUserPlayDataManager.dart';
import '../utils/ApiClient.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import '../utils/LuoXueToDivingFishUtil.dart';
import '../utils/StringUtil.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/DivingFish/ProberException.dart';
import '../entity/FriendComparisonResult.dart';
import '../constant/CacheKeyConstant.dart';
import 'AccountStore.dart';

/// 好友战绩对比服务
/// 拉取当前用户和好友的游玩数据，进行谱面对比
class FriendCompareService {
  static final FriendCompareService _instance =
      FriendCompareService._internal();
  factory FriendCompareService() => _instance;
  FriendCompareService._internal();

  /// 与好友进行战绩对比。[mySource] 和 [friendSource] 可以不同：
  /// 三个数据源的成绩都归一化成水鱼结构，曲目 ID 和难度序号都以曲库为准，可以直接比。
  /// [friendId] 水鱼和 AWMC NET 是 QQ 号，落雪是好友码。
  /// 两次查询均不写活动槽，也不采集历史，好友请求无需覆盖/恢复自己的数据。
  Future<ComparisonResult> compareWithFriend(
    String friendId, {
    required RefreshDataSource mySource,
    required RefreshDataSource friendSource,
  }) async {
    final myId = await myAccountId(mySource);
    final mine = switch (mySource) {
      RefreshDataSource.shuiyu => await _fetchShuiyuMine(myId),
      RefreshDataSource.awmc => await _fetchAwmcMine(myId),
      RefreshDataSource.luoxue => await _fetchLuoXueMine(),
    };
    final friend = switch (friendSource) {
      RefreshDataSource.shuiyu => await _fetchShuiyuFriend(friendId),
      RefreshDataSource.awmc => await _fetchAwmcFriend(friendId),
      RefreshDataSource.luoxue => await _fetchLuoXueFriend(friendId),
    };
    final myRecords = mine['records'] as List<dynamic>;
    final myRating = (mine['rating'] as num?)?.toInt() ?? 0;
    final friendRecords = friend['records'] as List<dynamic>;
    // AWMC NET 没有昵称时是空串
    final nickname = friend['nickname']?.toString() ?? '';
    final friendNickname = nickname.isEmpty ? friendId : nickname;
    final friendRating = (friend['rating'] as num?)?.toInt() ?? 0;

    // 3. 构建查找 Map：key = "songId_levelIndex"
    final myMap = <String, Map<String, dynamic>>{};
    for (final record in myRecords) {
      final songId = record['song_id']?.toString() ?? '';
      final levelIndex = record['level_index']?.toString() ?? '';
      if (songId.isNotEmpty) {
        myMap['${songId}_$levelIndex'] = record as Map<String, dynamic>;
      }
    }

    final friendMap = <String, Map<String, dynamic>>{};
    for (final record in friendRecords) {
      final songId = record['song_id']?.toString() ?? '';
      final levelIndex = record['level_index']?.toString() ?? '';
      if (songId.isNotEmpty) {
        friendMap['${songId}_$levelIndex'] = record as Map<String, dynamic>;
      }
    }

    // 4. 取交集
    final commonKeys = myMap.keys.toSet().intersection(friendMap.keys.toSet());

    // 5. 构建对比项列表
    final commonCharts = <ChartComparisonItem>[];
    int myWinCount = 0, friendWinCount = 0, tieCount = 0;

    for (final key in commonKeys) {
      final myRecord = myMap[key]!;
      final friendRecord = friendMap[key]!;

      final myAchievements = _achievementOf(myRecord);
      final friendAchievements = _achievementOf(friendRecord);

      final item = ChartComparisonItem(
        songId: int.tryParse(myRecord['song_id']?.toString() ?? '0') ?? 0,
        songTitle: myRecord['title']?.toString() ?? '',
        levelIndex: _toInt(myRecord['level_index']),
        levelLabel: myRecord['level_label']?.toString() ?? '',
        ds: _toDouble(myRecord['ds']),
        type: myRecord['type']?.toString() ?? '',
        myAchievements: myAchievements,
        friendAchievements: friendAchievements,
        myRa: _toInt(myRecord['ra']),
        friendRa: _toInt(friendRecord['ra']),
        myRate: myRecord['rate']?.toString() ?? '',
        friendRate: friendRecord['rate']?.toString() ?? '',
        myFc: myRecord['fc']?.toString() ?? '',
        friendFc: friendRecord['fc']?.toString() ?? '',
        myFs: myRecord['fs']?.toString() ?? '',
        friendFs: friendRecord['fs']?.toString() ?? '',
        myDxScore: _toInt(myRecord['dxScore']),
        friendDxScore: _toInt(friendRecord['dxScore']),
      );

      commonCharts.add(item);

      if (item.isMyWin) {
        myWinCount++;
      } else if (item.isFriendWin) {
        friendWinCount++;
      } else {
        tieCount++;
      }
    }

    // 按定数降序排列
    commonCharts.sort((a, b) => b.ds.compareTo(a.ds));

    return ComparisonResult(
      myAccountId: myId,
      commonCharts: commonCharts,
      myTotalCharts: myRecords.length,
      friendTotalCharts: friendRecords.length,
      commonCount: commonKeys.length,
      myWinCount: myWinCount,
      friendWinCount: friendWinCount,
      tieCount: tieCount,
      friendNickname: friendNickname,
      friendRating: friendRating,
      myRating: myRating,
    );
  }

  /// 当前用户在该数据源的账号：水鱼和 AWMC NET 是 QQ，落雪是好友码。
  Future<String> myAccountId(RefreshDataSource source) async {
    if (source == RefreshDataSource.shuiyu) return getCachedQQ();
    final metas = await AccountStore.loadAll();
    return metas[source.key]?.id ?? '';
  }

  Map<String, dynamic> _requireRecords(Map<String, dynamic>? data, String error) {
    if (data == null || data['records'] is! List) throw Exception(error);
    return data;
  }

  Future<Map<String, dynamic>> _fetchShuiyuMine(String myQQ) async {
    if (myQQ.isEmpty) throw Exception('请先登录并绑定水鱼 QQ');
    return _requireRecords(await UserPlayDataManager().fetchUserPlayData(myQQ),
        '当前水鱼用户无游玩数据，请先刷新数据');
  }

  Future<Map<String, dynamic>> _fetchShuiyuFriend(String friendQQ) async {
    final Map<String, dynamic>? data;
    try {
      data = await UserPlayDataManager().fetchUserPlayData(friendQQ);
    } on ProberException catch (e) {
      if (e.code == 'CONSENT_REQUIRED') {
        final link = await DivingFishOAuthManager().startBinding(friendQQ);
        throw ProberException.consentRequired(
            bindingUrl: link.isEmpty ? null : link);
      }
      rethrow;
    }
    return _requireRecords(data, '未找到该好友的游玩数据，请检查 QQ 号是否正确');
  }

  Future<Map<String, dynamic>> _fetchAwmcMine(String myQQ) async {
    if (myQQ.isEmpty) throw Exception('请先在账号管理里添加 AWMC NET 的 QQ');
    return AwmcNetUserPlayDataManager().fetchUserPlayData(myQQ);
  }

  Future<Map<String, dynamic>> _fetchAwmcFriend(String friendQQ) =>
      AwmcNetUserPlayDataManager().fetchUserPlayData(friendQQ);

  /// 落雪成绩按「曲名 + 类型」对应到本地曲库，曲目 ID 和定数都以曲库为准。
  Future<Map<String, Song>> _songsByTitleAndType() async {
    final songs = await MaimaiMusicDataManager().getCachedSongs();
    return {
      for (final song in songs ?? const <Song>[])
        '${song.basicInfo.title}|${song.type}': song,
    };
  }

  static String _lxTypeLabel(String? type) => switch (type?.toLowerCase()) {
        'standard' => 'SD',
        'dx' => 'DX',
        'utage' => ChartDifficulty.utageLabel,
        _ => type ?? '',
      };

  Future<Map<String, dynamic>> _fetchLuoXueMine() async {
    final manager = LuoXueUserPlayDataManager();
    if (!await manager.isLoggedIn()) {
      throw Exception('请先登录落雪账号');
    }
    final player = await manager.getPlayerInfo();
    final scores = await manager.getPlayerRecords();
    if (player == null || scores == null) {
      throw Exception('读取你的落雪成绩失败，请稍后重试');
    }
    final songs = await _songsByTitleAndType();
    if (songs.isEmpty) throw Exception('曲库还没有加载好，请稍后重试');
    return {
      'rating': player.rating,
      'records': [
        for (final score in scores)
          // 对不上曲库的成绩只有落雪自己的 ID，可能撞上另一首歌，不参与对比
          if (songs['${score.songName}|${_lxTypeLabel(score.type)}']
              case final song?)
            LuoXueToDivingFishUtil.toRecordItem(score, song: song).toJson(),
      ],
    };
  }

  /// 好友成绩读自家后端的 song_rankings，身份标识是 `luoxue:好友码`。
  /// 这份数据来自好友同步到 ChiffonMai 的成绩，上面的曲目 ID 已经是曲库 ID。
  Future<Map<String, dynamic>> _fetchLuoXueFriend(String friendCode) async {
    if (!RegExp(r'^\d+$').hasMatch(friendCode)) {
      throw Exception('好友码只能是数字，请检查后重试');
    }
    final playerId = 'luoxue:$friendCode';
    final response = await ApiClient.get(
        Uri.parse('${ApiUrls.SongRankingsPlayerUrl}/$playerId'));
    if (response.statusCode != 200) {
      throw Exception('查询好友成绩失败（HTTP ${response.statusCode}）');
    }
    final body = json.decode(utf8.decode(response.bodyBytes));
    final rows = body is Map ? body['data'] : null;
    final records = <Map<String, dynamic>>[
      for (final row in rows is List ? rows : const [])
        // 只有 DX 分数、没有达成率的行无法比较
        if (row is Map && _toDouble(row['achievementRate']) > 0)
          {
            'song_id': row['songId'],
            'level_index': row['difficultyIndex'],
            'achievements': _toDouble(row['achievementRate']),
            'rate': StringUtil.rateCodeFromAchievement(
                _toDouble(row['achievementRate'])),
            'dxScore': row['dxScore'],
            'fc': row['fc'],
          },
    ];
    if (records.isEmpty) {
      throw Exception('没有这位好友的落雪成绩，好友需要在 ChiffonMai 参与排行榜并刷新过数据');
    }

    // 接口按玩家的公开设置返回；旧版后端没有这个字段时显示好友码
    final player = body['player'];
    final nickname = player is Map ? player['displayName'] as String? : null;
    final rating = player is Map ? (player['rating'] as num?)?.toInt() : null;
    return {'nickname': nickname, 'rating': rating, 'records': records};
  }

  /// 获取当前用户的 QQ
  Future<String> getCachedQQ() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(CacheKeyConstant.probeDivingFishBindQQ) ?? '';
    } catch (_) {
      return '';
    }
  }

  // --- 历史记录 ---

  Future<String> _historyKey(RefreshDataSource source,
      {String? accountId}) async {
    final id = accountId ?? await myAccountId(source);
    final owner =
        await AccountStore.accountKey(sourceKey: source.key, accountId: id);
    return 'friend_compare_history_$owner';
  }

  /// 保存对比记录
  Future<void> saveHistory(String friendQQ, ComparisonResult result,
      {required RefreshDataSource source,
      required RefreshDataSource friendSource}) async {
    try {
      final key = await _historyKey(source, accountId: result.myAccountId);
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(key);
      final List<dynamic> history = jsonStr != null ? json.decode(jsonStr) : [];

      // 移除同一好友的旧记录
      history.removeWhere(
          (e) => _isSameFriend(e, friendQQ, friendSource, source));

      // 插入新记录到最前面
      history.insert(0, {
        'friendQQ': friendQQ,
        'friendSource': friendSource.key,
        'friendNickname': result.friendNickname,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'myRating': result.myRating,
        'friendRating': result.friendRating,
        'commonCount': result.commonCount,
        'myWinCount': result.myWinCount,
        'friendWinCount': result.friendWinCount,
        'tieCount': result.tieCount,
      });

      // 最多保留 20 条
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      await prefs.setString(key, json.encode(history));
    } catch (e) {
      debugPrint('FriendCompare: 保存历史失败: $e');
    }
  }

  /// 同一个 ID 在不同数据源是不同的好友。
  /// 旧记录没有 friendSource，那时只能比同数据源，所以按 [source] 算。
  bool _isSameFriend(dynamic entry, String friendQQ,
          RefreshDataSource friendSource, RefreshDataSource source) =>
      entry['friendQQ'] == friendQQ &&
      (entry['friendSource'] ?? source.key) == friendSource.key;

  /// 加载历史记录。[source] 是我的数据源，历史跟着我的账号走。
  Future<List<Map<String, dynamic>>> loadHistory(
      {required RefreshDataSource source}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(await _historyKey(source));
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// 删除历史记录
  Future<void> deleteHistory(String friendQQ,
      {required RefreshDataSource source,
      required RefreshDataSource friendSource}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(await _historyKey(source));
      if (jsonStr == null) return;
      final List<dynamic> history = json.decode(jsonStr);
      history.removeWhere(
          (e) => _isSameFriend(e, friendQQ, friendSource, source));
      await prefs.setString(await _historyKey(source), json.encode(history));
    } catch (e) {
      debugPrint('FriendCompare: 删除历史失败: $e');
    }
  }

  /// 清空全部历史
  Future<void> clearHistory({required RefreshDataSource source}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _historyKey(source));
  }

  /// 达成率统一到四位小数：各数据源的存储精度不同，同一成绩不能因为浮点误差分出胜负。
  double _achievementOf(Map<String, dynamic> record) =>
      (_toDouble(record['achievements']) * 10000).round() / 10000;

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
