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
import 'package:my_first_flutter_app/service/ConnectivityService.dart';

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

    // 检查网络连接
    final isOnline = await ConnectivityService().hasConnection();
    if (!isOnline) {
      final duration = DateTime.now().difference(startTime);
      debugPrint('离线模式：跳过后台数据初始化，使用缓存数据');
      return HomeInitResult(
        success: true,
        duration: duration,
        durationStr: appL10n.svcP0MsOfflineMode(duration.inMilliseconds.toString()),
      );
    }

    try {
      // 第一阶段：初始化基础管理器（必须串行）
      onProgress(appL10n.svcLoadingTheSongAliasDatabase);
      await SongAliasManager.instance.init();
      
      onProgress(appL10n.svcInitializingTheMaidataManager);
      final maidataManager = MaidataManager();
      await maidataManager.initialize();
      
      // 如果缓存未就绪或过期，获取全量maidata
      if (!maidataManager.isFullCacheReady) {
        debugPrint('Maidata缓存未就绪，开始获取全量maidata...');
        onProgress(appL10n.svcFetchingAllMaidataTheFirstLoadMay);
        await maidataManager.fetchAndCacheFullMaidata();
      } else {
        onProgress(appL10n.svcLoadingMaidataFromCache);
      }
      
      // 获取maidata文本列表用于追加
      List<String> maidataTexts = maidataManager.getAllMaidataTexts();
      debugPrint('已获取 ${maidataTexts.length} 首歌曲的maidata');
      
      // 第二阶段：并行获取音乐数据和难度数据
      onProgress(appL10n.svcSyncingSongInfoAndDifficultyData);
      final maimaiMusicManager = MaimaiMusicDataManager();
      final diffMusicManager = DiffMusicDataManager();
      
      await Future.wait([
        maimaiMusicManager.fetchAndUpdateMusicData(maidataTexts: maidataTexts),
        diffMusicManager.fetchAndUpdateDiffData(),
      ]);
      
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
