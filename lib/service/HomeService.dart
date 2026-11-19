import 'dart:async';

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
import 'package:my_first_flutter_app/service/AwmcCoverService.dart';
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
      // 第一阶段：初始化基础管理器（必须串行）
      onProgress(appL10n.svcInitializingTheMaidataManager);
      final maidataManager = MaidataManager();
      await maidataManager.initialize();
      
      // 如果缓存未就绪或过期，获取全量maidata
      if (!maidataManager.isFullCacheReady ||
          !await maidataManager.isFullCacheValid()) {
        debugPrint('Maidata缓存未就绪，开始获取全量maidata...');
        onProgress(appL10n.svcFetchingAllMaidataTheFirstLoadMay);
        try {
          await maidataManager.fetchAndCacheFullMaidata();
        } catch (error) {
          // 谱面资源刷新失败时继续初始化曲库、难度和其它独立数据源。
          debugPrint('[HomeInit] 全量谱面刷新未完成: $error');
        }
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

      // 别名已换 AWMC，接口按曲目 id 返回、要经本地曲库换成曲名，
      // 所以必须等曲库就绪后再初始化（曲库未就绪时会自行短暂等待）。
      onProgress(appL10n.svcLoadingTheSongAliasDatabase);
      await SongAliasManager.instance.init();

      // 曲绘兜底索引很小（随包），提前读进内存，避免第一次解析曲绘时
      // 因 500ms 超时落回必然 404 的水鱼 DX 地址。
      unawaited(AwmcCoverService.instance.ensureLoaded());
      
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
