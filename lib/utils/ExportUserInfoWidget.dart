import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import '../service/Community/CommunityAvatarStore.dart';
import '../widgets/LxnsAssetImage.dart';
import 'CurrentDataSourceNotifier.dart';

/// 导出图片共用的个人信息（头部 `ExportPosterHeader` 和雷霆长图在用）。
class ExportUserInfoWidget {
  @visibleForTesting
  static Map<String, dynamic>? debugUserInfoOverride;

  /// 在截图前读取账号数据。
  static Future<Map<String, dynamic>> loadUserInfo() {
    final override = debugUserInfoOverride;
    if (override != null) return Future<Map<String, dynamic>>.value(override);
    return _loadUserInfo(DateTime.now());
  }

  /// 预加载用户已选背景图到内存缓存，确保离屏截图首帧即命中，失败时静默回退纯色。
  static Future<void> precacheFrame(BuildContext context) async {
    try {
      await CommunityAvatarStore.instance.activate();
      final frameId = CommunityAvatarStore.instance.value.frameId;
      if (frameId == null || !context.mounted) return;
      final url = lxnsFrameUrl(frameId);
      final provider = CachedNetworkImageProvider(
        collectionAssetProxyUrl(url),
        cacheKey: collectionAssetCacheKey(url),
        cacheManager: lxnsAssetCacheManager,
      );
      await precacheImage(provider, context)
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('预加载导出头部背景失败（将回退纯色）: $e');
    }
  }

  /// 从 SharedPreferences 加载用户信息
  static Future<Map<String, dynamic>> _loadUserInfo(DateTime exportTime) async {
    try {
      await CommunityAvatarStore.instance.activate();
      final prefs = await SharedPreferences.getInstance();
      final avatarId = prefs.getInt('selectedAvatarId') ?? 1;
      final avatarUrl = lxnsIconUrl(avatarId);
      final nickname = prefs.getString('userNickname') ?? '';
      final best35Rating = prefs.getInt('best35TotalRA') ?? 0;
      final best15Rating = prefs.getInt('best15TotalRA') ?? 0;
      final totalRating =
          prefs.getInt('best50TotalRA') ?? (best35Rating + best15Rating);
      final plateId = prefs.getInt(CacheKeyConstant.selectedPlateIdCache);
      final frameId = CommunityAvatarStore.instance.value.frameId;
      final frameUrl = frameId == null ? '' : lxnsFrameUrl(frameId);

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
        'frameId': frameId,
        'frameUrl': frameUrl,
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
        'frameId': null,
        'frameUrl': '',
      };
    }
  }
}
