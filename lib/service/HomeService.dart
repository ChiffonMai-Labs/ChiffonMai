import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:flutter/foundation.dart';
import 'package:my_first_flutter_app/manager/SongAliasManager.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/manager/DivingFish/DiffMusicDataManager.dart';
import 'package:my_first_flutter_app/manager/LZYCheckUpdateManager.dart';
import 'package:my_first_flutter_app/manager/LuoXue/CollectionsManager.dart';
import 'package:my_first_flutter_app/manager/LuoXue/LuoXueSongsManager.dart';
import 'package:my_first_flutter_app/manager/MaidataManager.dart';
import 'package:my_first_flutter_app/service/RecommendByTagsService.dart';
import 'package:my_first_flutter_app/manager/DivingFish/UnionManager.dart';

/// 首页服务类：处理首页相关的数据初始化和业务逻辑
class HomeService {
  static final HomeService _instance = HomeService._internal();
  
  factory HomeService() => _instance;
  
  HomeService._internal();
  
  /// 检查更新
  Future<Map<String, dynamic>?> checkUpdate() async {
    debugPrint("首页加载时自动检查更新");
    final updateManager = LZYCheckUpdateManager();
    try {
      if (await updateManager.shouldShowUpdateDialog()) {
        var updateInfo = await updateManager.checkUpdate();
        if (updateInfo['hasUpdate']) {
          return updateInfo;
        }
      }
    } catch (e) {
      debugPrint("自动检查更新失败：$e");
    }
    return null;
  }
  
  /// 后台初始化所有数据
  /// [onProgress] 进度回调函数，参数为进度消息
  Future<HomeInitResult> initializeDataInBackground({
    required Function(String) onProgress,
  }) async {
    final startTime = DateTime.now();

    try {
      // 第一阶段：仅做本地轻量初始化（单曲磁盘索引与已缓存轻量目录），不再抓取全量 maidata
      onProgress(appL10n.svcInitializingTheMaidataManager);
      await MaidataManager().initialize();

      // 第二阶段：并行获取音乐数据和难度数据
      onProgress(appL10n.svcSyncingSongInfoAndDifficultyData);
      final maimaiMusicManager = MaimaiMusicDataManager();
      final diffMusicManager = DiffMusicDataManager();

      await Future.wait([
        maimaiMusicManager.fetchAndUpdateMusicData(),
        diffMusicManager.fetchAndUpdateDiffData(),
      ]);
      onProgress(appL10n.svcLoadingTheSongAliasDatabase);
      await SongAliasManager.instance.init();
      
      // 第三阶段：并行初始化收藏品、标签、落雪歌曲、知识库等数据
      onProgress(appL10n.svcLoadingCollectiblesTagsSongsKnowledgeBaseAnd);
      final collectionsManager = CollectionsManager();
      final luoXueSongsManager = LuoXueSongsManager();

      await Future.wait([
        collectionsManager.fetchTrophiesCollections(),
        collectionsManager.fetchIconsCollections(),
        collectionsManager.fetchPlatesCollections(),
        collectionsManager.fetchFramesCollections(),
        RecommendByTagsService.initializeTags(),
        luoXueSongsManager.getLuoXueSongs(),
        UnionManager().fetchAndCache(),
      ]);
      
      // 建立落雪歌曲与缓存歌曲的映射
      onProgress(appL10n.svcBuildingSongMappings);
      if (await maimaiMusicManager.hasCachedData()) {
        final cachedSongs = await maimaiMusicManager.getCachedSongs();
        luoXueSongsManager.mapLuoXueSongsToCachedSongs(cachedSongs ?? []);
      }
      
      // 计算耗时
      final duration = DateTime.now().difference(startTime);
      final durationStr = '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}秒';
      
      debugPrint('✅ 所有数据初始化完成，用时$durationStr');
      
      return HomeInitResult(
        success: true,
        duration: duration,
        durationStr: durationStr,
        errorMessage: null,
      );
      
    } catch (e) {
      debugPrint('❌ 后台初始化失败: $e');
      return HomeInitResult(
        success: false,
        duration: DateTime.now().difference(startTime),
        durationStr: '',
        errorMessage: e.toString(),
      );
    }
  }
}

/// 首页初始化结果
class HomeInitResult {
  final bool success;
  final Duration duration;
  final String durationStr;
  final String? errorMessage;
  
  HomeInitResult({
    required this.success,
    required this.duration,
    required this.durationStr,
    this.errorMessage,
  });
}
