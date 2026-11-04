import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'CurrentDataSourceNotifier.dart';

/// 导出图片共用的个人信息（头部 `ExportPosterHeader` 和雷霆长图在用）。
class ExportUserInfoWidget {
  /// 在截图前读取账号数据。
  static Future<Map<String, dynamic>> loadUserInfo() => _loadUserInfo(DateTime.now());

  /// 从 SharedPreferences 加载用户信息
  static Future<Map<String, dynamic>> _loadUserInfo(DateTime exportTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarId = prefs.getInt('selectedAvatarId') ?? 1;
      final avatarUrl = 'https://assets2.lxns.net/maimai/icon/$avatarId.png';
      final nickname = prefs.getString('userNickname') ?? '';
      final best35Rating = prefs.getInt('best35TotalRA') ?? 0;
      final best15Rating = prefs.getInt('best15TotalRA') ?? 0;
      final totalRating =
          prefs.getInt('best50TotalRA') ?? (best35Rating + best15Rating);
      final plateId = prefs.getInt(CacheKeyConstant.selectedPlateIdCache);

      // 读取数据源
      final dataSource = RefreshDataSource.displayNameOfKey(
          prefs.getString(CacheKeyConstant.lastDataSource));

      // 格式化导出时间
      final exportTimeStr =
          '${exportTime.year}-${exportTime.month.toString().padLeft(2, '0')}-${exportTime.day.toString().padLeft(2, '0')} '
          '${exportTime.hour.toString().padLeft(2, '0')}:${exportTime.minute.toString().padLeft(2, '0')}:${exportTime.second.toString().padLeft(2, '0')}';

      return {
        'avatarUrl': avatarUrl,
        'nickname': nickname,
        'best35Rating': best35Rating,
        'best15Rating': best15Rating,
        'totalRating': totalRating,
        'dataSource': dataSource,
        'exportTime': exportTimeStr,
        'plateId': plateId,
      };
    } catch (e) {
      debugPrint('加载用户信息失败: $e');
      return {
        'avatarUrl': '',
        'nickname': '',
        'best35Rating': 0,
        'best15Rating': 0,
        'totalRating': 0,
        'dataSource': '',
        'exportTime': '',
        'plateId': null,
      };
    }
  }
}
