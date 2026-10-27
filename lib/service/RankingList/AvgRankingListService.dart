import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../constant/CacheTimestampConstant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'SongRankingService.dart' show parseDataSource;
import '../../utils/CommunityProfileUtil.dart';

/// 平均值排行榜的衡量指标
enum AvgMetric {
  achievement, // 平均达成率
  dx, // 平均DX得分达成率
}

/// 单个玩家在平均值排行榜中的条目
class AvgRankItem {
  int rank;
  final String playerId;
  final String playerName;
  final String dataSource;
  final double avgAchievement;
  final double avgDxAchievement;
  final int achievementCount;
  final int dxCount;
  final int updateTime;
  final int avatarId;

  AvgRankItem({
    this.rank = 0,
    required this.playerId,
    required this.playerName,
    required this.dataSource,
    required this.avgAchievement,
    required this.avgDxAchievement,
    required this.achievementCount,
    required this.dxCount,
    this.updateTime = 0,
    this.avatarId = CommunityProfileUtil.defaultAvatarId,
  });

  factory AvgRankItem.fromJson(Map<String, dynamic> json) {
    final playerId = (json['playerId'] ?? json['player_id'] ?? '').toString();
    return AvgRankItem(
      rank: (json['rank'] ?? 0) as int,
      playerId: playerId,
      playerName: (json['playerName'] ?? json['player_name'] ?? '').toString(),
      dataSource: (json['dataSource'] ?? json['data_source'] ?? '')
              .toString()
              .isNotEmpty
          ? (json['dataSource'] ?? json['data_source'] ?? '').toString()
          : _parseDataSource(playerId),
      avgAchievement:
          (json['avgAchievement'] ?? json['avg_achievement'] ?? 0).toDouble(),
      avgDxAchievement:
          (json['avgDxAchievement'] ?? json['avg_dx_achievement'] ?? 0)
              .toDouble(),
      achievementCount:
          (json['achievementCount'] ?? json['achievement_count'] ?? 0).toInt(),
      dxCount: (json['dxCount'] ?? json['dx_count'] ?? 0).toInt(),
      updateTime: (json['updateTime'] ?? json['update_time'] ?? 0).toInt(),
      avatarId: CommunityProfileUtil.avatarIdFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'playerId': playerId,
      'playerName': playerName,
      'dataSource': dataSource,
      'avgAchievement': avgAchievement,
      'avgDxAchievement': avgDxAchievement,
      'achievementCount': achievementCount,
      'dxCount': dxCount,
      'updateTime': updateTime,
      'avatarId': avatarId,
    };
  }
}

/// 根据 playerId 前缀推断数据源。
///
/// 直接用 [SongRankingService] 里那份唯一的实现，不要再抄一遍——
/// 原来这里和 FittedRatingRankingListService 各有一份 `_parseDataSource`，
/// 三份都只认 shuiyu / luoxue，加第三个源时必然漏改其中一两份。
String _parseDataSource(String playerId) => parseDataSource(playerId);

class AvgRankingListService {
  static int _cacheGeneration = 0;
  // 缓存有效期：从常量文件读取（分钟转秒）
  static int get _cacheExpirySeconds =>
      CacheTimestampConstant.computedRankingsCacheMinutes * 60;

  /// 测试专用：把排行榜请求打桩掉（见 [getAverages] 里的用法）。真机永远是 null。
  @visibleForTesting
  static Future<List<AvgRankItem>> Function()? debugRankingsLoader;

  // 获取所有玩家的平均值数据（原始、未排序），可读缓存
  static Future<List<AvgRankItem>> getAverages({bool refresh = false}) async {
    final generation = _cacheGeneration;
    final stub = debugRankingsLoader;
    if (stub != null) return stub();
    if (!refresh) {
      final cachedData = await _getCachedRankings();
      if (cachedData != null) {
        return cachedData;
      }
    }

    try {
      final url = Uri.parse('${ApiUrls.SongRankingsAveragesUrl}');
      final response = await ApiClient.get(
        url,
        headers: {'Content-Type': 'application/json'},
        timeout: const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true) {
          final items = (result['data'] as List<dynamic>)
              .map((e) => AvgRankItem.fromJson(e as Map<String, dynamic>))
              .toList();
          if (generation == _cacheGeneration) {
            await _cacheRankings(items,
                nextUpdateAt: (result['nextUpdateAt'] as num?)?.toInt());
          }
          return items;
        }
      }
      debugPrint('获取平均值排行榜失败: HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      debugPrint('获取平均值排行榜失败: $e');
    }
    return await _getCachedRankings(allowExpired: true) ?? [];
  }

  // 按指标排序并分配排名（并列名次，1,1,3,3,5 风格）
  static List<AvgRankItem> calculateRankedPositions(
    List<AvgRankItem> items,
    AvgMetric metric,
  ) {
    if (items.isEmpty) return items;

    double valueOf(AvgRankItem item) => metric == AvgMetric.achievement
        ? item.avgAchievement
        : item.avgDxAchievement;

    final sortedItems = List<AvgRankItem>.from(items)
      ..sort((a, b) => valueOf(b).compareTo(valueOf(a)));

    for (int i = 0; i < sortedItems.length; i++) {
      if (i == 0) {
        sortedItems[i].rank = 1;
      } else {
        if (valueOf(sortedItems[i]) == valueOf(sortedItems[i - 1])) {
          sortedItems[i].rank = sortedItems[i - 1].rank;
        } else {
          sortedItems[i].rank = i + 1;
        }
      }
    }

    return sortedItems;
  }

  // 从缓存读取平均值排行数据
  static Future<List<AvgRankItem>?> _getCachedRankings(
      {bool allowExpired = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(CacheKeyConstant.avgRankingsCache);
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map ||
          decoded['version'] != 3 ||
          decoded['items'] is! List ||
          decoded['nextUpdateAt'] is! num) return null;
      if (!allowExpired &&
          DateTime.now().millisecondsSinceEpoch >= decoded['nextUpdateAt'])
        return null;
      return (decoded['items'] as List)
          .map((row) => AvgRankItem.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  // 保存平均值排行数据到缓存
  static Future<void> _cacheRankings(List<AvgRankItem> items,
      {int? nextUpdateAt}) async {
    final generation = _cacheGeneration;
    final prefs = await SharedPreferences.getInstance();
    if (generation != _cacheGeneration) return;
    try {
      final jsonString = json.encode({
        // 旧版本曾混用公开昵称和匿名头像，升级后重新读取统一的公开资料。
        'version': 3,
        'items': items.map((item) => item.toJson()).toList(),
        'nextUpdateAt': nextUpdateAt ??
            DateTime.now().millisecondsSinceEpoch + _cacheExpirySeconds * 1000,
      });
      await prefs.setString(CacheKeyConstant.avgRankingsCache, jsonString);
      await prefs.setInt(
        CacheKeyConstant.avgRankingsCacheTimestamp,
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
    } catch (e) {
      debugPrint('保存平均值排行缓存失败: $e');
    }
  }

  // 清除平均值排行缓存（用于强制刷新）
  static Future<void> clearRankingsCache() async {
    // 清理前发出的响应不能重新写回旧头像与资料。
    _cacheGeneration++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CacheKeyConstant.avgRankingsCache);
    await prefs.remove(CacheKeyConstant.avgRankingsCacheTimestamp);
  }
}
