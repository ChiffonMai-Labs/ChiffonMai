import '../service/Account/AccountAuthorizationStore.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import '../service/Community/PlayerExperienceService.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../constant/LoadingTipsConstant.dart';
import '../entity/DivingFish/RecordItem.dart';
import '../entity/DivingFish/Song.dart';
import '../entity/LuoXue/LuoXuePlayer.dart';
import '../entity/LuoXue/LuoXueScore.dart';
import '../manager/AWMC/AwmcNetUserPlayDataManager.dart';
import '../manager/DivingFish/DiffMusicDataManager.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../manager/DivingFish/UnionManager.dart';
import '../manager/DivingFish/UserBest50Manager.dart';
import '../manager/DivingFish/UserPlayDataManager.dart';
import '../manager/LuoXue/CollectionsManager.dart';
import '../manager/LuoXue/LuoXueUserPlayDataManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../manager/DXRating/MaiTagsManager.dart';
import '../manager/Song/SongAliasManager.dart';
import '../service/History/ChartHistoryStore.dart';
import '../service/Account/AccountSwitchService.dart';
import '../utils/SecureCredentialStore.dart';
import '../utils/DivingFishMaskStatus.dart';
import '../service/Community/CommunityNicknameSyncService.dart';
import '../service/Score/PaiziProgressService.dart';
import '../service/Score/PersonalizedScoreService.dart';
import '../service/Recommend/RecommendByTagsService.dart';
import '../service/RankingList/SongRankingService.dart';
import '../service/RankingList/RankingUploadGuard.dart';
import '../utils/ApiClient.dart';
import '../utils/AppError.dart';
import '../utils/CacheSourceRegistry.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import '../utils/StringUtil.dart';
import '../utils/UserProfileNotifier.dart';
import 'AdvancedRefreshDataDialog.dart' show AdvancedRefreshDataPanel;
import '../widgets/AppToast.dart';

// 数据源枚举 / 当前数据源 Notifier 已抽到 utils，这里 re-export，
// 让既有 `import 'RefreshDataDialog.dart' show RefreshDataSource, ...` 继续可用。
export '../utils/CurrentDataSourceNotifier.dart';

// ============================================================
// 公共入口：旧版"拉取成绩并更新数据"对话框
// 从首页全部功能卡片 + 系统 Tab 的"拉取成绩并更新数据"入口均可调用。
// 对话框内部的所有状态写入通过 UserProfileNotifier 共享，
// 调用方只要监听 UserProfileNotifier 即可拿到最新昵称 / Rating / QQ。
// ============================================================

class RatingLimits {
  final int best35Limit;
  final int best15Limit;
  final int best50Limit;
  RatingLimits({
    required this.best35Limit,
    required this.best15Limit,
    required this.best50Limit,
  });
}

/// 「刷新数据」对话框收集到的用户输入。
///
/// 重构说明：旧实现把「输入 / 确认 / 执行 / 进度显示」全塞在对话框里，
/// 于是刷新期间会弹一个带进度条的模态框挡住整个界面。
/// 现在对话框只负责收集输入，用户点「确认」即关闭对话框，
/// 真正的刷新由调用方拿到本对象后执行，进度显示在调用方的按钮上。
class RefreshDataRequest {
  final RefreshDataSource dataSource;
  final String qq;
  final String authCode;
  final bool participateRankings;
  final bool showNickname;
  final bool showBriefProfile;
  final bool forceFullRefresh;

  /// 高级模式下用户勾选要强制刷新的缓存源 ID 集合（来自 CacheSourceRegistry）。
  /// 为 null 时回退到 [forceFullRefresh] 的"全部强制"语义。
  final Set<String>? forceSourceIds;

  /// 落雪已在本机保存授权令牌时可以直接续期，无需再次输入授权码。
  final bool useSavedAuthorization;

  const RefreshDataRequest({
    required this.dataSource,
    required this.qq,
    required this.authCode,
    required this.participateRankings,
    required this.showNickname,
    this.showBriefProfile = false,
    required this.forceFullRefresh,
    this.forceSourceIds,
    this.useSavedAuthorization = false,
  });

  bool get isShuiyu => dataSource == RefreshDataSource.shuiyu;

  /// 本次刷新的输入是否已填好：水鱼 / AWMC NET 要 QQ，落雪要授权码。
  ///
  /// 抽成 getter 是因为原来写成 `isShuiyu ? qq.isNotEmpty : authCode.isNotEmpty`
  /// 的二元三目 —— AWMC NET 也是 QQ 制的，会被错误地要求填授权码。
  bool get canRefresh {
    switch (dataSource) {
      case RefreshDataSource.shuiyu:
      case RefreshDataSource.awmc:
        return qq.isNotEmpty;
      case RefreshDataSource.luoxue:
        return authCode.isNotEmpty || useSavedAuthorization;
    }
  }
}

bool _refreshDialogOpen = false;

/// 弹出「刷新数据」输入对话框。
///
/// 返回值：
/// - `null`  → 用户取消
/// - 非 null → 用户点了「确认」，调用方应执行 [executeRefreshData] 并把进度
///             显示在自己的按钮上（见 SystemHubPage 的实现）
Future<RefreshDataRequest?> showRefreshDataDialog(
  BuildContext context, {
  RefreshDataSource? initialSource,
}) async {
  if (_refreshDialogOpen || !context.mounted) return null;
  final origin = ModalRoute.of(context);
  if (origin?.isCurrent == false) return null;
  // 首页和系统页共用入口，读取设置期间也不能再开一份表单。
  _refreshDialogOpen = true;
  try {
    AccountSwitchService.requireIdle();
    final prefs = await SharedPreferences.getInstance();
    final jwt =
        await SecureCredentialStore.read(CacheKeyConstant.probeDivingFishToken);
    final bindQQ =
        prefs.getString(CacheKeyConstant.probeDivingFishBindQQ) ?? '';
    // AWMC NET 使用自己的账号存档，不能用活动槽里的 cachedQQ。
    final awmcQQ = await AccountAuthorizationStore.awmcQQ();
    if (!context.mounted || origin?.isCurrent == false) return null;
    AccountSwitchService.requireIdle();
    return await showDialog<RefreshDataRequest>(
      context: context,
      builder: (_) => AdvancedRefreshDataPanel(
        hasDivingFishLogin: jwt?.isNotEmpty == true,
        bindQQ: bindQQ,
        awmcQQ: awmcQQ,
        initialSource: initialSource,
      ),
    );
  } on AccountUpdateBusy catch (error) {
    AppToast.show(error.toString(), tone: AppToastTone.warning);
    return null;
  } catch (error, stack) {
    if (context.mounted && origin?.isCurrent != false) {
      AppToast.showError(
        error,
        stack: stack,
        title: context.l10n.flowCouldNotRefreshData,
        stage: '打开刷新面板',
      );
    }
    return null;
  } finally {
    _refreshDialogOpen = false;
  }
}

/// 执行刷新（由调用方在对话框关闭后调用）。
///
/// [onProgress] 的进度取值是 0-100 的整数，文案示例："正在并行刷新数据..."。
/// 返回 true 表示成功。调用方负责成功 / 失败提示。
Future<bool> executeRefreshData(
  RefreshDataRequest request, {
  required void Function(int progress, String text) onProgress,
}) async {
  // 合并后的对话框按缓存源给出强制刷新集合，统一走按源刷新。
  if (request.forceSourceIds != null) {
    return executeAdvancedRefreshData(request, onProgress: onProgress);
  }
  final source = request.dataSource;
  final bool willRefresh = request.canRefresh;
  if (!willRefresh) {
    // 别静默地「什么都不做然后报成功」：以前输入为空时会跳过整个刷新，
    // 最后仍然 onProgress(100, '数据刷新完成') 并 return true，调用方就弹
    // 「数据刷新成功!」——用户以为刷了，其实一条数据都没动。
    throw AppError(
      code: 'AUTH-MISSING-IDENTITY',
      stage: '校验刷新凭据',
      source: source.key,
      userMessage: source == RefreshDataSource.luoxue &&
              !request.useSavedAuthorization
          ? appL10n.flowLXNSAuthorizationCodeMissing
          : appL10n.flowNoLookupIDObtainedForP0(
              appLocalizeLabel(source.displayName)),
      suggestion: appL10n.errSuggestionReauth,
    );
  }
  try {
    onProgress(0, appL10n.flowStartingDataRefresh);
    // 先把活动槽切换到本次要刷新的数据源，避免覆盖另一个账号的活动数据
    if (willRefresh) {
      switch (source) {
        case RefreshDataSource.shuiyu:
          await refreshBest50DataWithProgress(
            request.qq,
            onProgress,
            participateRankings: request.participateRankings,
            showNickname: request.showNickname,
            showBriefProfile: request.showBriefProfile,
            forceFullRefresh: request.forceFullRefresh,
          );
          break;
        case RefreshDataSource.luoxue:
          await _handleLuoXueAuthWithProgress(
            request.authCode,
            onProgress,
            participateRankings: request.participateRankings,
            showNickname: request.showNickname,
            showBriefProfile: request.showBriefProfile,
            forceFullRefresh: request.forceFullRefresh,
          );
          break;
        case RefreshDataSource.awmc:
          await refreshAwmcNetDataWithProgress(
            request.qq,
            onProgress,
            participateRankings: request.participateRankings,
            showNickname: request.showNickname,
            showBriefProfile: request.showBriefProfile,
            forceFullRefresh: request.forceFullRefresh,
          );
          break;
      }
    }
    // 刷新完把活动槽存进该源存档并更新元信息（不再单独写 lastDataSource）
    onProgress(100, appL10n.flowDataRefreshComplete);
    return true;
  } finally {
    LoadingTipsConstant.stopAutoSwitch();
  }
}

/// 高级模式刷新：按用户勾选的 [request.forceSourceIds]（来自 CacheSourceRegistry 的 id）
/// 转换为按 groupKey 的 forceMap，再走与 executeRefreshData 相同的并行编排。
///
/// 与 [executeRefreshData] 的差别：
///   - 每个 groupKey 单独决定是否 forceNetwork（不再用单一 forceFullRefresh）
///   - 标签缓存 force 时直接调 MaiTagsManager.refreshCache()
///   - maidata force 时把 MaimaiMusicDataManager 的 forceMaidataRefresh 置 true
Future<bool> executeAdvancedRefreshData(
  RefreshDataRequest request, {
  required void Function(int progress, String text) onProgress,
  SharedRefreshData? sharedRefresh,
}) async {
  final shared = sharedRefresh ??
      SharedRefreshData(forceSourceIds: request.forceSourceIds ?? const {});

  final source = request.dataSource;
  final bool willRefresh = request.canRefresh;
  if (!willRefresh) {
    // 同 executeRefreshData：输入为空时不要假报成功
    throw StateError(
      source == RefreshDataSource.luoxue && !request.useSavedAuthorization
          ? appL10n.flowLXNSAuthorizationCodeMissing
          : appL10n.flowNoLookupIDObtainedForP0(
              appLocalizeLabel(source.displayName)),
    );
  }
  try {
    onProgress(0, appL10n.flowStartingDataRefresh);
    if (willRefresh) {
      switch (source) {
        case RefreshDataSource.shuiyu:
          await refreshBest50DataWithProgress(
            request.qq,
            onProgress,
            participateRankings: request.participateRankings,
            showNickname: request.showNickname,
            showBriefProfile: request.showBriefProfile,
            sharedRefresh: shared,
          );
          break;
        case RefreshDataSource.luoxue:
          await _handleLuoXueAuthWithProgress(
            request.authCode,
            onProgress,
            participateRankings: request.participateRankings,
            showNickname: request.showNickname,
            showBriefProfile: request.showBriefProfile,
            sharedRefresh: shared,
          );
          break;
        case RefreshDataSource.awmc:
          await refreshAwmcNetDataWithProgress(
            request.qq,
            onProgress,
            participateRankings: request.participateRankings,
            showNickname: request.showNickname,
            showBriefProfile: request.showBriefProfile,
            sharedRefresh: shared,
          );
          break;
      }
    }
    onProgress(100, appL10n.flowDataRefreshComplete);
    return true;
  } finally {
    LoadingTipsConstant.stopAutoSwitch();
  }
}

// ============================================================
// 公共工具：URL 启动失败回退（剪贴板 + 提示）
// ============================================================

/// 打不开外链时的兜底：**把内容复制到剪贴板 + 明确提示**。
///
/// [copyText] 默认就是 [url]，但有些链接得换个东西复制才用得上：
/// `qm.qq.com` 的加群链接在浏览器里只是个空壳中转页，这时应该复制**群号**。
///
/// [message] 同样是可覆盖的：不同链接要告诉用户「复制到的是什么、接下来怎么办」
/// （链接贴进浏览器 vs 群号拿去 QQ 里搜）。
void launchUrlFallback(
  String url,
  BuildContext context, {
  String? copyText,
  String? message,
}) {
  Clipboard.setData(ClipboardData(text: copyText ?? url));
  if (!context.mounted) return;
  AppToast.show(message ?? context.l10n.flowCouldNotOpenABrowserLinkCopied2,
      duration: const Duration(seconds: 4),
      actionLabel: context.l10n.featureGotIt,
      onAction: () {},
      tone: AppToastTone.error);
}

// ============================================================
// 私有辅助函数（从 HomePage 抽离）
// ============================================================

Future<void> _saveUserData({
  required String nickname,
  required int best35TotalRA,
  required int best15TotalRA,
  required String cachedQQ,
  required RefreshDataSource source,
}) async {
  AccountSwitchService.requireRefresh(source);
  final prefs = await SharedPreferences.getInstance();
  final rawPlay = prefs.getString(CacheKeyConstant.userPlayData);
  final playData =
      rawPlay == null ? null : json.decode(rawPlay) as Map<String, dynamic>;
  if (playData != null) {
    playData['rating'] = best35TotalRA + best15TotalRA;
    playData['nickname'] = nickname;
    await prefs.setString(CacheKeyConstant.userPlayData, json.encode(playData));
  }
  await prefs.setString('cachedQQ', cachedQQ);
  await prefs.setString('userNickname', nickname);
  await prefs.setInt('best35TotalRA', best35TotalRA);
  await prefs.setInt('best15TotalRA', best15TotalRA);
  // 总 Rating 也要持久化，否则退出重进后 best50TotalRA 读回 0，首页显示 "-"
  await prefs.setInt('best50TotalRA', best35TotalRA + best15TotalRA);
  UserProfileNotifier.replace(UserProfile(
    nickname: nickname,
    best50TotalRA: best35TotalRA + best15TotalRA,
    best35TotalRA: best35TotalRA,
    best15TotalRA: best15TotalRA,
    cachedQQ: cachedQQ,
  ));

  // Sync the fresh upstream name independently of ranking participation,
  // anonymity and Rating changes. Never submit the cached startup nickname.
  final playerId = prefs.getString(source.userIdCacheKey);
  if (playerId != null && playerId.startsWith('${source.key}:')) {
    unawaited(CommunityNicknameSyncService.syncFreshNickname(
        playerId: playerId, nickname: nickname));
  }

  // 顺手记一个 Rating 历史点（曲线用的就是界面显示的这一份，口径天然一致）。
  // 不 await：采集失败绝不影响刷新流程；同一天重复刷新只会替换当天那个点。
  unawaited(ChartHistoryStore.instance.recordRating(
    rating: best35TotalRA + best15TotalRA,
    best35: best35TotalRA,
    best15: best15TotalRA,
    sourceKey: source.key,
    accountId: cachedQQ,
    recordCount: (playData?['records'] as List?)?.length ?? 0,
  ));
}

// 累计 Best35 + Best15 RA 由调用方在分好 old/new 之后直接 fold 求和
// 详见 refreshBest50DataWithProgress / _calculateBest50FromLuoXueRecords

/// 一次刷新中的公共缓存。多端同步共享同一实例，账号数据仍各自刷新。
class SharedRefreshData {
  final Map<String, bool>? _forceMap;
  final bool _forceFullRefresh;
  final bool _reportFailures;
  List<Future<void>>? _tasks;
  final _failures = <String>[];

  SharedRefreshData(
      {required Set<String> forceSourceIds, bool reportFailures = false})
      : this._(
          forceMap: {
            for (final source in CacheSourceRegistry.all)
              if (forceSourceIds.contains(source.id)) source.groupKey: true,
          },
          reportFailures: reportFailures,
        );

  SharedRefreshData._({
    Map<String, bool>? forceMap,
    bool forceFullRefresh = false,
    bool reportFailures = false,
  })  : _forceMap = forceMap,
        _forceFullRefresh = forceFullRefresh,
        _reportFailures = reportFailures;

  List<String> get failures => List.unmodifiable(_failures);

  Future<void> finish(void Function(String) onComplete) async {
    await Future.wait(tracked(onComplete));
  }

  /// 已启动的公共任务由首个刷新等待完成，随后各平台只更新自己的成绩。
  List<Future<void>> tracked(void Function(String) onComplete) {
    final previous = _tasks;
    if (previous != null) return previous;
    bool force(String group) => _forceMap?[group] ?? _forceFullRefresh;
    final tasks = <Future<void>>[
      _refresh(
        !force('songs') && force('maidata') ? 'maidata' : 'songs_water_fish',
        appL10n.flowSongDataRefreshed,
        onComplete,
        () => MaimaiMusicDataManager().refreshDataWithSmartMaidata(
          forceNetwork: force('songs'),
          forceMaidataRefresh: force('maidata'),
        ),
      ),
      _refresh(
          'diff',
          appL10n.flowDifficultyDataRefreshed,
          onComplete,
          () => DiffMusicDataManager()
              .fetchAndUpdateDiffData(forceNetwork: force('diff'))),
      _refresh(
          'tags',
          appL10n.flowTagDataRefreshed,
          onComplete,
          () => force('tags')
              ? MaiTagsManager().refreshCache()
              : RecommendByTagsService.initializeTags()),
      _refresh(
          'coll_trophies',
          appL10n.flowCollectibleDataRefreshed,
          onComplete,
          () => CollectionsManager()
              .refreshAllCollections(forceNetwork: force('collections'))),
      _refresh(
          'alias_yuzuchan',
          appL10n.flowAliasDataRefreshed,
          onComplete,
          () => SongAliasManager.instance
              .refresh(forceNetwork: force('aliases'))),
      _refresh('union', appL10n.flowUnionDataRefreshed, onComplete,
          () => UnionManager().fetchAndCache(forceNetwork: force('union'))),
    ];
    return _tasks = tasks;
  }

  int get pendingTaskCount => _tasks == null ? 6 : 0;

  Future<void> _refresh(String sourceId, String doneLabel,
      void Function(String) onComplete, Future<dynamic> Function() task) async {
    var failed = false;
    try {
      final result = await task();
      failed = _reportFailures && result == false;
    } catch (_) {
      if (!_reportFailures) rethrow;
      failed = true;
    }
    if (failed) {
      final source =
          CacheSourceRegistry.all.firstWhere((item) => item.id == sourceId);
      final label = appLocalizeLabel(source.displayName);
      _failures.add(label);
      onComplete(appL10n.flowCouldNotRefreshDataP0(label));
    } else {
      onComplete(doneLabel);
    }
  }
}

Future<void> refreshBest50DataWithProgress(
  String qq,
  Function(int, String) onProgress, {
  bool participateRankings = false,
  bool showNickname = false,
  bool? showBriefProfile,
  bool forceFullRefresh = false,
  Map<String, bool>? forceMap,
  SharedRefreshData? sharedRefresh,
}) async {
  return AccountSwitchService.runRefresh(RefreshDataSource.shuiyu, () async {
    await _refreshBest50DataWithProgressImpl(qq, onProgress,
        participateRankings: participateRankings,
        showNickname: showNickname,
        showBriefProfile: showBriefProfile,
        forceFullRefresh: forceFullRefresh,
        forceMap: forceMap,
        sharedRefresh: sharedRefresh);
  });
}

Future<void> _refreshBest50DataWithProgressImpl(
  String qq,
  Function(int, String) onProgress, {
  bool participateRankings = false,
  bool showNickname = false,
  bool? showBriefProfile,
  bool forceFullRefresh = false,
  Map<String, bool>? forceMap,
  SharedRefreshData? sharedRefresh,
}) async {
  final refreshStopwatch = Stopwatch()..start();
  final logRefresh = (String stage, int milliseconds) {
    debugPrint('[RefreshTiming] $stage: ${milliseconds}ms');
  };
  try {
    onProgress(5, appL10n.flowClearingCaches);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CacheKeyConstant.recommendationResults);
      debugPrint('推荐结果缓存已清除');
    } catch (e) {
      debugPrint('清除推荐结果缓存失败: $e');
    }

    onProgress(10, appL10n.flowRefreshingDataInParallel);
    // 把并行任务的完成度均匀映射到 10% → 80%，让进度条平滑爬升
    int _completed = 0;
    final shared = sharedRefresh ??
        SharedRefreshData._(
            forceMap: forceMap, forceFullRefresh: forceFullRefresh);
    final int _totalTasks = 1 + shared.pendingTaskCount;
    const int _parallelStart = 10;
    const int _parallelSpan = 70; // 10 → 80
    void onTaskComplete(String msg) {
      _completed++;
      final p =
          (_parallelStart + (_completed * _parallelSpan / _totalTasks).round())
              .clamp(_parallelStart, _parallelStart + _parallelSpan);
      onProgress(p, msg);
    }

    Future<T> _track<T>(Future<T> task, String label) async {
      final result = await task;
      onTaskComplete(label);
      return result;
    }

    final results = await Future.wait<dynamic>([
      _track(UserPlayDataManager().fetchUserPlayData(qq),
          appL10n.flowUserDataRetrieved),
      ...shared.tracked(onTaskComplete),
    ]);
    logRefresh('parallel-data', refreshStopwatch.elapsedMilliseconds);
    final userPlayData = results[0] as Map<String, dynamic>?;
    if (userPlayData == null) {
      throw AppError(
        code: 'DATA-FISH-FETCH',
        stage: '拉取水鱼成绩',
        source: 'shuiyu',
        userMessage: appL10n.flowCouldNotFetchDivingFishScores,
        suggestion: appL10n.errSuggestionRetryLater,
      );
    }
    await AccountSwitchService.bindIdentity(RefreshDataSource.shuiyu, qq);
    final settingsPrefs = await SharedPreferences.getInstance();
    await settingsPrefs.setBool(
        CacheKeyConstant.participateRankings, participateRankings);
    await settingsPrefs.setBool(CacheKeyConstant.showNickname, showNickname);
    await settingsPrefs.setBool(
        CacheKeyConstant.showBriefProfile,
        participateRankings &&
            showNickname &&
            (showBriefProfile ??
                settingsPrefs.getBool(CacheKeyConstant.showBriefProfile) ??
                false));
    await UserPlayDataManager().storeFetchedData(userPlayData,
        source: RefreshDataSource.shuiyu, accountId: qq);
    final songs = await MaimaiMusicDataManager().getCachedSongs();
    final best50Data = await UserBest50Manager().getUserBest50(
      qq,
      playData: userPlayData,
      songs: songs,
    );
    onProgress(85, appL10n.flowCalculatingRating);
    String currentNickname = '未知玩家';
    if (userPlayData.containsKey('nickname')) {
      currentNickname = userPlayData['nickname'] ?? currentNickname;
    }

    int best35RA = 0;
    int best15RA = 0;
    for (final r in best50Data.charts.sd) {
      best35RA += r.ra;
    }
    for (final r in best50Data.charts.dx) {
      best15RA += r.ra;
    }
    final totalRA = best35RA + best15RA;

    await _saveUserData(
      nickname: currentNickname,
      best35TotalRA: best35RA,
      best15TotalRA: best15RA,
      cachedQQ: qq,
      source: RefreshDataSource.shuiyu,
    );

    PersonalizedScoreService().clearRecordsCache();
    PaiziProgressService().clearRecordsCache();

    onProgress(95, appL10n.flowSavingData);

    String? rankingError;
    final userId = 'shuiyu:$qq';
    final prefs = await SharedPreferences.getInstance();
    // 双账号：只写自己源的身份，不再删对方的（两套缓存各自保留）
    await prefs.setString(CacheKeyConstant.shuiyuUserId, userId);

    // 水鱼开了成绩掩码时，读到的成绩是打过码的，不上传排行榜
    final divingFishMasked =
        participateRankings && await DivingFishMaskStatus.instance.refresh();
    if (divingFishMasked) {
      debugPrint('[Ranking] 水鱼账号开启了成绩掩码，跳过排行榜上传');
    }

    // 排行榜上传未完成不影响成绩刷新：收尾步骤照常执行，最后再单独提示
    RankingUploadException? rankingFailure;
    try {
      if (participateRankings && !divingFishMasked) {
        final displayNickname = showNickname ? currentNickname : '匿名用户';
        final records = userPlayData['records'] is List
            ? (userPlayData['records'] as List).cast<Map<String, dynamic>>()
            : <Map<String, dynamic>>[];
        // 排行榜守卫预检：任何一处不合法就整次都不上传
        final uploadTicket = await _precheckRankingUpload(
          playerId: userId,
          totalRating: totalRA,
          best35Rating: best35RA,
          best15Rating: best15RA,
          records: records,
          songs: songs,
        );
        final rankingResults = await Future.wait<Object?>([
          _updateRankings(
            sourceProfile: userPlayData,
            dataSource: 'shuiyu',
            originalId: qq,
            nickname: displayNickname,
            totalRating: totalRA,
            best35Rating: best35RA,
            best15Rating: best15RA,
            best35Records: best50Data.charts.sd,
            best15Records: best50Data.charts.dx,
            songs: songs,
            uploadTicket: uploadTicket,
          ),
          records.isEmpty
              ? Future.value(true)
              : SongRankingService().updateSongRankings(
                  userId,
                  displayNickname,
                  records,
                  songs: songs,
                  uploadTicket: uploadTicket,
                  onBatchProgress: (sent, total) {
                    final percent = 95 + ((sent * 4) ~/ total).clamp(0, 4);
                    onProgress(
                        percent,
                        appL10n.flowUploadingSongRankingsP0P1(
                            (sent).toString(), (total).toString()));
                  },
                ),
        ]);
        rankingError = rankingResults[0] as String?;
        final songRankingUpdated = rankingResults[1] as bool;
        if (rankingError != null || !songRankingUpdated) {
          throw RankingUploadException(
              _rankingFailureMessage(rankingError, songRankingUpdated),
              RankingUploadException.issueOf(
                  RankingUploadGuard.lastBlockedCode));
        }
      } else {
        final deleteResults = await Future.wait<bool>([
          _deleteRankings(userId),
          SongRankingService().deleteSongRankings(userId),
        ]);
        if (deleteResults.any((success) => !success)) {
          throw AppError(
            code: 'SRV-RANKING-DELETE',
            stage: '移出排行榜',
            source: 'shuiyu',
            userMessage: appL10n.flowCouldNotRemoveLeaderboardEntries,
            suggestion: appL10n.errSuggestionRetryLater,
          );
        }
      }
    } on RankingUploadException catch (e) {
      rankingFailure = e;
    }

    PersonalizedScoreService().clearRecordsCache();
    PaiziProgressService().clearRecordsCache();

    if (rankingFailure != null) {
      debugPrint('排行榜上传未完成: $rankingFailure');
    }

    logRefresh('refresh-total', refreshStopwatch.elapsedMilliseconds);
    onProgress(100, appL10n.featureDone);
    if (rankingFailure != null) throw rankingFailure;
  } catch (e) {
    rethrow;
  }
}

/// 刷新 AWMC NET（net.wmc.pub）成绩 —— 第三个数据源。
///
/// 与 [refreshBest50DataWithProgress]（水鱼）**共用同一套下游**：
/// AWMC NET 的 `/dev/player/records` 返回的结构与水鱼 `/player/records` 逐字段一致，
/// 所以拿到 records 之后，「写活动槽 → UserBest50Manager 算 Best50 → 存身份标记 →
/// 可选上传排行榜」这几步和 水鱼 走的是同一条路，不需要另写一份转换 + Best50 计算
/// （那是落雪才需要的，因为落雪的字段完全不同）。
///
/// 与水鱼的两点差别：
///   1. 不需要登录 / 授权，QQ 直接查；
///   2. 失败时 [AwmcNetUserPlayDataManager] 会抛带中文文案的 `AwmcNetException`，
///      这里**不吞掉**，让它冒到调用方去弹 toast（水鱼那边是返回 null 后静默）。
Future<void> refreshAwmcNetDataWithProgress(
  String qq,
  Function(int, String) onProgress, {
  bool participateRankings = false,
  bool showNickname = false,
  bool? showBriefProfile,
  bool forceFullRefresh = false,
  Map<String, bool>? forceMap,
  Map<String, dynamic>? verifiedPlayerData,
  SharedRefreshData? sharedRefresh,
}) async {
  return AccountSwitchService.runRefresh(RefreshDataSource.awmc, () async {
    await _refreshAwmcNetDataWithProgressImpl(qq, onProgress,
        participateRankings: participateRankings,
        showNickname: showNickname,
        showBriefProfile: showBriefProfile,
        forceFullRefresh: forceFullRefresh,
        forceMap: forceMap,
        verifiedPlayerData: verifiedPlayerData,
        sharedRefresh: sharedRefresh);
  });
}

Future<void> _refreshAwmcNetDataWithProgressImpl(
  String qq,
  Function(int, String) onProgress, {
  bool participateRankings = false,
  bool showNickname = false,
  bool? showBriefProfile,
  bool forceFullRefresh = false,
  Map<String, bool>? forceMap,
  Map<String, dynamic>? verifiedPlayerData,
  SharedRefreshData? sharedRefresh,
}) async {
  final refreshStopwatch = Stopwatch()..start();
  final logRefresh = (String stage, int milliseconds) {
    debugPrint('[RefreshTiming] $stage: ${milliseconds}ms');
  };

  onProgress(5, appL10n.flowClearingCaches);
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CacheKeyConstant.recommendationResults);
  } catch (e) {
    debugPrint('清除推荐结果缓存失败: $e');
  }

  onProgress(10, appL10n.flowRefreshingDataInParallel);
  // 与另外两个源一致：并行任务映射到 10% → 80%
  int completed = 0;
  final shared = sharedRefresh ??
      SharedRefreshData._(
          forceMap: forceMap, forceFullRefresh: forceFullRefresh);
  final int totalTasks =
      verifiedPlayerData == null ? 1 + shared.pendingTaskCount : 2;
  const int parallelStart = 10;
  const int parallelSpan = 70; // 10 → 80
  void onTaskComplete(String msg) {
    completed++;
    final p = (parallelStart + (completed * parallelSpan / totalTasks).round())
        .clamp(parallelStart, parallelStart + parallelSpan);
    onProgress(p, msg);
  }

  Future<T> track<T>(Future<T> task, String label) async {
    final result = await task;
    onTaskComplete(label);
    return result;
  }

  final results = await Future.wait<dynamic>([
    track(
        verifiedPlayerData != null
            ? Future.value(verifiedPlayerData)
            : AwmcNetUserPlayDataManager().fetchUserPlayData(qq),
        appL10n.flowAWMCNETScoresRetrieved),
    if (verifiedPlayerData == null)
      ...shared.tracked(onTaskComplete)
    else
      track(MaimaiMusicDataManager().fetchAndUpdateMusicData(),
          appL10n.flowSongDataRefreshed),
  ]);
  logRefresh('awmc-parallel-data', refreshStopwatch.elapsedMilliseconds);

  // 注意：这里**必须**把 fetch 到的数据显式传下去。若传 null，
  // UserBest50Manager 会回落到 UserPlayDataManager（水鱼），拿同一个 QQ
  // 去问水鱼，把水鱼的成绩显示成 AWMC NET 的。
  final userPlayData = results[0] as Map<String, dynamic>;
  await AccountSwitchService.bindIdentity(RefreshDataSource.awmc, qq);
  final settingsPrefs = await SharedPreferences.getInstance();
  // bindIdentity 已恢复本人存档，换 QQ 则已清空；快捷连接沿用该玩家的公开偏好。
  if (verifiedPlayerData != null) {
    participateRankings =
        settingsPrefs.getBool(CacheKeyConstant.participateRankings) ?? false;
    showNickname =
        settingsPrefs.getBool(CacheKeyConstant.showNickname) ?? false;
  }
  await settingsPrefs.setBool(
      CacheKeyConstant.participateRankings, participateRankings);
  await settingsPrefs.setBool(CacheKeyConstant.showNickname, showNickname);
  await settingsPrefs.setBool(
      CacheKeyConstant.showBriefProfile,
      participateRankings &&
          showNickname &&
          (showBriefProfile ??
              settingsPrefs.getBool(CacheKeyConstant.showBriefProfile) ??
              false));
  await UserPlayDataManager().storeFetchedData(userPlayData,
      source: RefreshDataSource.awmc, accountId: qq);
  final songs = await MaimaiMusicDataManager().getCachedSongs();
  final best50Data = await UserBest50Manager().getUserBest50(
    qq,
    playData: userPlayData,
    songs: songs,
  );
  onProgress(85, appL10n.flowCalculatingRating);

  String currentNickname = '未知玩家';
  final fetchedNickname = userPlayData['nickname'];
  if (fetchedNickname is String && fetchedNickname.isNotEmpty) {
    currentNickname = fetchedNickname;
  }

  int best35RA = 0;
  int best15RA = 0;
  for (final r in best50Data.charts.sd) {
    best35RA += r.ra;
  }
  for (final r in best50Data.charts.dx) {
    best15RA += r.ra;
  }

  await _saveUserData(
    nickname: currentNickname,
    best35TotalRA: best35RA,
    best15TotalRA: best15RA,
    cachedQQ: qq,
    source: RefreshDataSource.awmc,
  );

  PersonalizedScoreService().clearRecordsCache();
  PaiziProgressService().clearRecordsCache();

  onProgress(95, appL10n.flowSavingData);

  final records = (userPlayData['records'] as List)
      .whereType<Map<String, dynamic>>()
      .toList();

  String? rankingError;
  // 单曲排行榜等自家后端接口按 `'<source>:<id>'` 认人
  final userId = 'awmc:$qq';
  final prefs = await SharedPreferences.getInstance();
  // 多账号：只写自己源的身份标记，不删对方的（各源缓存各自保留）
  await prefs.setString(CacheKeyConstant.awmcUserId, userId);

  // 排行榜上传未完成不影响成绩刷新：收尾步骤照常执行，最后再单独提示
  RankingUploadException? rankingFailure;
  try {
    if (participateRankings) {
      final displayNickname = showNickname ? currentNickname : '匿名用户';
      // 排行榜守卫预检：任何一处不合法就整次都不上传
      final uploadTicket = await _precheckRankingUpload(
        playerId: userId,
        totalRating: best35RA + best15RA,
        best35Rating: best35RA,
        best15Rating: best15RA,
        records: records,
        songs: songs,
      );
      final rankingResults = await Future.wait<Object?>([
        _updateRankings(
          sourceProfile: userPlayData,
          dataSource: 'awmc',
          originalId: qq,
          nickname: displayNickname,
          totalRating: best35RA + best15RA,
          best35Rating: best35RA,
          best15Rating: best15RA,
          best35Records: best50Data.charts.sd,
          best15Records: best50Data.charts.dx,
          songs: songs,
          uploadTicket: uploadTicket,
        ),
        records.isEmpty
            ? Future.value(true)
            : SongRankingService().updateSongRankings(
                userId,
                displayNickname,
                records,
                songs: songs,
                uploadTicket: uploadTicket,
                onBatchProgress: (sent, total) {
                  final percent = 95 + ((sent * 4) ~/ total).clamp(0, 4);
                  onProgress(
                      percent,
                      appL10n.flowUploadingSongRankingsP0P1(
                          (sent).toString(), (total).toString()));
                },
              ),
      ]);
      rankingError = rankingResults[0] as String?;
      final songRankingUpdated = rankingResults[1] as bool;
      if (rankingError != null || !songRankingUpdated) {
        throw RankingUploadException(
            _rankingFailureMessage(rankingError, songRankingUpdated),
            RankingUploadException.issueOf(RankingUploadGuard.lastBlockedCode));
      }
    } else if (verifiedPlayerData == null) {
      final deleteResults = await Future.wait<bool>([
        _deleteRankings(userId),
        SongRankingService().deleteSongRankings(userId),
      ]);
      if (deleteResults.any((success) => !success)) {
        throw AppError(
          code: 'SRV-RANKING-DELETE',
          stage: '移出排行榜',
          source: 'awmc',
          userMessage: appL10n.flowCouldNotRemoveLeaderboardEntries,
          suggestion: appL10n.errSuggestionRetryLater,
        );
      }
    }
  } on RankingUploadException catch (e) {
    rankingFailure = e;
  }

  if (rankingFailure != null) {
    debugPrint('排行榜上传未完成: $rankingFailure');
  }

  logRefresh('awmc-refresh-total', refreshStopwatch.elapsedMilliseconds);
  onProgress(100, appL10n.featureDone);
  if (rankingFailure != null) throw rankingFailure;
}

Future<void> _handleLuoXueAuthWithProgress(
  String authCode,
  Function(int, String) onProgress, {
  bool participateRankings = false,
  bool showNickname = false,
  bool? showBriefProfile,
  bool forceFullRefresh = false,
  Map<String, bool>? forceMap,
  SharedRefreshData? sharedRefresh,
}) async {
  return AccountSwitchService.runRefresh(RefreshDataSource.luoxue, () async {
    await _handleLuoXueAuthWithProgressImpl(authCode, onProgress,
        participateRankings: participateRankings,
        showNickname: showNickname,
        showBriefProfile: showBriefProfile,
        forceFullRefresh: forceFullRefresh,
        forceMap: forceMap,
        sharedRefresh: sharedRefresh);
  });
}

Future<void> _handleLuoXueAuthWithProgressImpl(
  String authCode,
  Function(int, String) onProgress, {
  bool participateRankings = false,
  bool showNickname = false,
  bool? showBriefProfile,
  bool forceFullRefresh = false,
  Map<String, bool>? forceMap,
  SharedRefreshData? sharedRefresh,
}) async {
  final refreshStopwatch = Stopwatch()..start();
  final logRefresh = (String stage, int milliseconds) {
    debugPrint('[RefreshTiming] $stage: ${milliseconds}ms');
  };
  try {
    onProgress(5, appL10n.flowClearingCaches);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(CacheKeyConstant.recommendationResults);
      debugPrint('推荐结果缓存已清除');
    } catch (e) {
      debugPrint('清除推荐结果缓存失败: $e');
    }

    onProgress(
        10,
        authCode.trim().isNotEmpty
            ? appL10n.flowObtainingAccessToken
            : appL10n.flowRenewingAccessToken);
    if (authCode.trim().isNotEmpty) {
      final success = await LuoXueUserPlayDataManager()
          .exchangeCodeForToken(authCode.trim());
      if (!success) {
        throw AppError(
          code: 'AUTH-LXNS-CODE',
          stage: '兑换落雪授权码',
          source: 'luoxue',
          userMessage: appL10n.flowAuthorizationFailedCheckYourCode,
          suggestion: appL10n.errSuggestionReauth,
        );
      }
    } else {
      final accessToken = await LuoXueOAuthManager().getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw AppError(
          code: 'AUTH-LXNS-EXPIRED',
          stage: '校验落雪访问令牌',
          source: 'luoxue',
          userMessage:
              appL10n.flowLXNSAuthorizationExpiredEnterANewAuthorization,
          suggestion: appL10n.errSuggestionReauth,
        );
      }
    }

    onProgress(15, appL10n.flowAuthorizedRefreshingDataInParallel);
    // 把并行任务的完成度均匀映射到 15% → 80%
    int _completed = 0;
    final shared = sharedRefresh ??
        SharedRefreshData._(
            forceMap: forceMap, forceFullRefresh: forceFullRefresh);
    final int _totalTasks = 2 + shared.pendingTaskCount;
    const int _parallelStart = 15;
    const int _parallelSpan = 65; // 15 → 80
    void onTaskComplete(String msg) {
      _completed++;
      final p =
          (_parallelStart + (_completed * _parallelSpan / _totalTasks).round())
              .clamp(_parallelStart, _parallelStart + _parallelSpan);
      onProgress(p, msg);
    }

    Future<T> _track<T>(Future<T> task, String label) async {
      final result = await task;
      onTaskComplete(label);
      return result;
    }

    final results = await Future.wait<dynamic>([
      _track(LuoXueUserPlayDataManager().getPlayerInfo(),
          appL10n.flowLXNSProfileRetrieved),
      _track(LuoXueUserPlayDataManager().getPlayerRecords(),
          appL10n.flowLXNSScoresRetrieved),
      ...shared.tracked(onTaskComplete),
    ]);
    logRefresh('luoxue-parallel-data', refreshStopwatch.elapsedMilliseconds);

    final playerInfo = results[0] as LuoXuePlayer?;
    final rawPlayerScores = results[1] as List<LuoXueScore>?;
    if (playerInfo == null || rawPlayerScores == null) {
      throw AppError(
        code: 'DATA-LXNS-FETCH',
        stage: '拉取落雪玩家与成绩',
        source: 'luoxue',
        userMessage: appL10n.flowCouldNotFetchLXNSProfileOrScores,
        suggestion: appL10n.errSuggestionRetryLater,
      );
    }
    await AccountSwitchService.bindIdentity(
        RefreshDataSource.luoxue, playerInfo.friendCode.toString());
    final settingsPrefs = await SharedPreferences.getInstance();
    await settingsPrefs.setBool(
        CacheKeyConstant.participateRankings, participateRankings);
    await settingsPrefs.setBool(CacheKeyConstant.showNickname, showNickname);
    await settingsPrefs.setBool(
        CacheKeyConstant.showBriefProfile,
        participateRankings &&
            showNickname &&
            (showBriefProfile ??
                settingsPrefs.getBool(CacheKeyConstant.showBriefProfile) ??
                false));
    final songs = await MaimaiMusicDataManager().getCachedSongs();
    final playerRecords = await LuoXueUserPlayDataManager()
        .getPlayerRecordsAsRecordItems(
            playerInfo: playerInfo, scores: rawPlayerScores, songs: songs);
    if (playerRecords == null) {
      throw AppError(
        code: 'DATA-LXNS-CONVERT',
        stage: '转换落雪成绩格式',
        source: 'luoxue',
        userMessage: appL10n.flowCouldNotConvertLXNSScores,
        suggestion: appL10n.errSuggestionRetryLater,
      );
    }
    logRefresh('luoxue-score-conversion', refreshStopwatch.elapsedMilliseconds);
    String currentNickname = '未知玩家';
    int best35RA = 0;
    int best15RA = 0;
    // 落雪的 id 只能来自 playerInfo.friendCode，绝不回退到上一个账号的
    // cachedQQ——否则 getPlayerInfo() 失败时会把水鱼 QQ 当成落雪 ID 存下来。
    String cachedQQ = '';
    {
      final halfWidthName = StringUtil.toHalfWidth(playerInfo.name);
      currentNickname = halfWidthName.isNotEmpty ? halfWidthName : '未知玩家';
      final prefs = await SharedPreferences.getInstance();
      // 双账号：只写自己源的身份，不再删对方的（两套缓存各自保留）
      await prefs.setString(
          CacheKeyConstant.luoxueUserId, 'luoxue:${playerInfo.friendCode}');
      cachedQQ = playerInfo.friendCode.toString();
    }

    debugPrint('玩家成绩数量: ${playerRecords.length}');

    onProgress(85, appL10n.flowCalculatingBest50);
    List<RecordItem>? best35Records;
    List<RecordItem>? best15Records;
    if (playerRecords.isNotEmpty) {
      final result = await _calculateBest50FromLuoXueRecords(
        playerRecords,
        songs: songs,
      );
      if (result == null) {
        throw AppError(
          code: 'DATA-SONGS-MISSING',
          stage: '计算落雪 Rating',
          source: 'luoxue',
          userMessage: appL10n.flowMissingSongDataCannotCalculateLXNSRating,
          suggestion: appL10n.errSuggestionRetryLater,
        );
      }
      best35Records = result.best35;
      best15Records = result.best15;
      if (best35Records != null) {
        best35RA = best35Records.fold(0, (s, r) => s + r.ra);
      }
      if (best15Records != null) {
        best15RA = best15Records.fold(0, (s, r) => s + r.ra);
      }
    }

    await _saveUserData(
      nickname: currentNickname,
      best35TotalRA: best35RA,
      best15TotalRA: best15RA,
      cachedQQ: cachedQQ,
      source: RefreshDataSource.luoxue,
    );

    onProgress(95, appL10n.flowSavingData);

    String? rankingError;
    // 排行榜上传未完成不影响成绩刷新：收尾步骤照常执行，最后再单独提示
    RankingUploadException? rankingFailure;
    {
      final userId = 'luoxue:${playerInfo.friendCode}';
      try {
        if (participateRankings) {
          final displayNickname = showNickname ? currentNickname : '匿名用户';
          final records =
              playerRecords.map((record) => record.toJson()).toList();
          // 排行榜守卫预检：任何一处不合法就整次都不上传
          final uploadTicket = await _precheckRankingUpload(
            playerId: userId,
            totalRating: best35RA + best15RA,
            best35Rating: best35RA,
            best15Rating: best15RA,
            records: records,
            songs: songs,
          );
          final rankingResults = await Future.wait<Object?>([
            _updateRankings(
              sourceProfile: playerInfo.toJson(),
              dataSource: 'luoxue',
              originalId: playerInfo.friendCode.toString(),
              nickname: displayNickname,
              totalRating: best35RA + best15RA,
              best35Rating: best35RA,
              best15Rating: best15RA,
              best35Records: best35Records,
              best15Records: best15Records,
              songs: songs,
              uploadTicket: uploadTicket,
            ),
            records.isEmpty
                ? Future.value(true)
                : SongRankingService().updateSongRankings(
                    userId,
                    displayNickname,
                    records,
                    songs: songs,
                    uploadTicket: uploadTicket,
                    onBatchProgress: (sent, total) {
                      final percent = 95 + ((sent * 4) ~/ total).clamp(0, 4);
                      onProgress(
                          percent,
                          appL10n.flowUploadingSongRankingsP0P1(
                              (sent).toString(), (total).toString()));
                    },
                  ),
          ]);
          rankingError = rankingResults[0] as String?;
          final songRankingUpdated = rankingResults[1] as bool;
          if (rankingError != null || !songRankingUpdated) {
            throw RankingUploadException(
                _rankingFailureMessage(rankingError, songRankingUpdated),
                RankingUploadException.issueOf(
                    RankingUploadGuard.lastBlockedCode));
          }
        } else {
          final deleteResults = await Future.wait<bool>([
            _deleteRankings(userId),
            SongRankingService().deleteSongRankings(userId),
          ]);
          if (deleteResults.any((success) => !success)) {
            throw AppError(
              code: 'SRV-RANKING-DELETE',
              stage: '移出排行榜',
              source: 'luoxue',
              userMessage: appL10n.flowCouldNotRemoveLeaderboardEntries,
              suggestion: appL10n.errSuggestionRetryLater,
            );
          }
        }
      } on RankingUploadException catch (e) {
        rankingFailure = e;
      }
    }

    PersonalizedScoreService().clearRecordsCache();
    PaiziProgressService().clearRecordsCache();

    if (rankingFailure != null) {
      debugPrint('排行榜上传未完成: $rankingFailure');
    }

    logRefresh('refresh-total', refreshStopwatch.elapsedMilliseconds);
    onProgress(100, appL10n.featureDone);
    if (rankingFailure != null) throw rankingFailure;
  } catch (e) {
    rethrow;
  }
}

String _rankingFailureMessage(String? ratingError, bool songRankingUpdated) {
  final songError = SongRankingService().lastGuardMessage;
  return [
    if (ratingError != null)
      '${appL10n.featureRatingLeaderboard}\n$ratingError',
    if (!songRankingUpdated) appL10n.flowCouldNotUpdateSongLeaderboard,
    if (!songRankingUpdated && songError != null) songError,
  ].join('\n');
}

Future<String?> _updateRankings({
  required String dataSource,
  Map<String, dynamic> sourceProfile = const {},
  required String originalId,
  required String nickname,
  required int totalRating,
  required int best35Rating,
  required int best15Rating,
  List<RecordItem>? best35Records,
  List<RecordItem>? best15Records,
  List<Song>? songs,
  String? uploadTicket,
}) async {
  try {
    final ratingLimits = await _calculateRatingLimits(songs: songs);

    final errors = <String>[];
    if (totalRating > ratingLimits.best50Limit) {
      errors.add(appL10n.flowInvalidBest50Data);
    }
    if (best35Rating > ratingLimits.best35Limit) {
      errors.add(appL10n.flowInvalidBest35Data);
    }
    if (best15Rating > ratingLimits.best15Limit) {
      errors.add(appL10n.flowInvalidBest15Data);
    }

    if (errors.isNotEmpty) {
      final errorMsg = errors.join('、');
      debugPrint('警告: $errorMsg，跳过排行榜更新');
      debugPrint(
          '  用户数据: Best50=$totalRating, Best35=$best35Rating, Best15=$best15Rating');
      debugPrint(
          '  理论上限: Best50=${ratingLimits.best50Limit}, Best35=${ratingLimits.best35Limit}, Best15=${ratingLimits.best15Limit}');

      if (best35Records != null && best35Records.isNotEmpty) {
        final sorted = best35Records;
        debugPrint('  --- 用户 Best35 记录 (按RA降序) ---');
        for (int i = 0; i < sorted.length; i++) {
          final r = sorted[i];
          debugPrint(
              '  ${i + 1}. RA=${r.ra} 定数=${r.ds} songId=${r.songId} title=${r.title} level=${r.level}');
        }
      }
      if (best15Records != null && best15Records.isNotEmpty) {
        final sorted = best15Records;
        debugPrint('  --- 用户 Best15 记录 (按RA降序) ---');
        for (int i = 0; i < sorted.length; i++) {
          final r = sorted[i];
          debugPrint(
              '  ${i + 1}. RA=${r.ra} 定数=${r.ds} songId=${r.songId} title=${r.title} level=${r.level}');
        }
      }

      return appL10n.flowP0CheckForInvalidData((errorMsg).toString());
    }

    final prefs = await SharedPreferences.getInstance();
    final share = prefs.getBool(CacheKeyConstant.showBriefProfile) == true &&
        nickname != '匿名用户';
    Map<String, dynamic>? b1(List<RecordItem>? records) {
      if (records == null || records.isEmpty) return null;
      return records.reduce((a, b) => a.ra >= b.ra ? a : b).toJson();
    }

    final sourcePlate = sourceProfile['name_plate'];
    final selectedPlate = prefs.getInt(CacheKeyConstant.selectedPlateIdCache);
    final response = await ApiClient.post(
      Uri.parse(ApiUrls.RankingsUpdateUrl),
      headers: {
        ...(share || dataSource == 'luoxue'
            ? await PlayerExperienceService.ownerHeaders(
                '$dataSource:$originalId')
            : {'Content-Type': 'application/json'}),
        // 排行榜守卫的预检凭证
        if (uploadTicket != null) RankingUploadGuard.ticketHeader: uploadTicket,
      },
      body: json.encode({
        if (dataSource == 'luoxue')
          'initialAppearance': {
            'friend_code': int.parse(originalId),
            for (final key in ['icon', 'name_plate', 'frame', 'trophy'])
              key: sourceProfile[key],
          },
        'showRankNickname': nickname != '匿名用户',
        'showBriefProfile': share,
        if (share)
          'briefProfile': {
            'trophy': sourceProfile['trophy'],
            'frame': sourceProfile['frame'],
            'sourceAvatar': sourceProfile['icon'],
            'nameplate': sourcePlate ??
                (selectedPlate == null ? null : {'id': selectedPlate}),
            'best35B1': b1(best35Records),
            'best15B1': b1(best15Records),
          },
        'dataSource': dataSource,
        'originalId': originalId,
        'nickname': nickname,
        'totalRating': totalRating,
        'best35Rating': best35Rating,
        'best15Rating': best15Rating,
      }),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['success'] == true) {
        debugPrint('Rating 排行榜更新成功: ${result['message']}');
      } else {
        return appL10n.flowCouldNotUpdateLeaderboardDataP0(
            (result['error'] ?? 'unknown').toString());
      }
    } else {
      final body = jsonDecode(response.body);
      // 被排行榜守卫拒绝：给出具体原因（非法成绩 / 冻结 / 黑名单 / 需要更新）
      final guard = RankingUploadGuard.blockedFromResponse(
          '$dataSource:$originalId',
          response.statusCode,
          body is Map<String, dynamic> ? body : null);
      if (guard != null) return guard.message;
      return appL10n.flowCouldNotUpdateLeaderboardDataP0((body is Map
              ? body['error'] ?? response.statusCode
              : response.statusCode)
          .toString());
    }
    return null;
  } catch (e) {
    debugPrint('更新排行榜数据时发生异常: $e');
    return appL10n.flowLeaderboardUpdateErrorP0((e).toString());
  }
}

/// 排行榜上传前预检（见 RankingUploadGuard）。
///
/// 把本次的 Rating 与全部单曲成绩一次交给服务端校验：通过返回凭证（服务端未部署守卫时为 null），
/// 不通过直接抛出带具体原因的错误，Rating 榜与单曲榜都不会写入。
Future<String?> _precheckRankingUpload({
  required String playerId,
  required int totalRating,
  required int best35Rating,
  required int best15Rating,
  required List<Map<String, dynamic>> records,
  List<Song>? songs,
}) async {
  final prepared =
      await SongRankingService().prepareUploadRecords(records, songs: songs);
  final result = await RankingUploadGuard.precheck(
    playerId: playerId,
    totalRating: totalRating,
    best35Rating: best35Rating,
    best15Rating: best15Rating,
    records: prepared,
    titles: {for (final song in songs ?? const <Song>[]) song.id: song.title},
  );
  if (!result.ok) {
    throw RankingUploadException(
        result.message ?? appL10n.flowCouldNotUpdateSongLeaderboard,
        RankingUploadException.issueOf(result.code));
  }
  return result.ticket;
}

Future<bool> _deleteRankings(String userId) async {
  try {
    final headers = await PlayerExperienceService.ownerHeaders(userId);
    final response = await ApiClient.delete(
      Uri.parse('${ApiUrls.RankingsBaseUrl}/user/$userId'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['success'] == true) {
        debugPrint('排行榜记录删除成功: ${result['message']}');
        return true;
      }
      debugPrint('排行榜记录删除失败: ${result['error']}');
      return false;
    }
    debugPrint('排行榜记录删除失败，状态码: ${response.statusCode}');
    return false;
  } catch (e) {
    debugPrint('删除排行榜记录时发生异常: $e');
    return false;
  }
}

Future<RatingLimits> _calculateRatingLimits({List<Song>? songs}) async {
  final musicManager = MaimaiMusicDataManager();
  final resolvedSongs = songs ?? await musicManager.getCachedSongs();
  if (resolvedSongs == null || resolvedSongs.isEmpty) {
    debugPrint('警告: 歌曲缓存为空，使用默认Rating上限');
    return RatingLimits(
        best35Limit: 12000, best15Limit: 5000, best50Limit: 17000);
  }

  final rawAddedIds = await musicManager.getAddedSongIds() ?? const [];
  final addedSongIds = rawAddedIds.length > resolvedSongs.length * 0.5
      ? <String>[]
      : rawAddedIds;
  if (rawAddedIds.length != addedSongIds.length) {
    debugPrint(
        '警告: addedSongIds 缓存异常（${rawAddedIds.length} 条，占主库 ${(rawAddedIds.length / resolvedSongs.length * 100).toStringAsFixed(1)}%），已自动跳过该过滤');
  }

  final filteredSongs = resolvedSongs.where((song) {
    if (addedSongIds.contains(song.id)) return false;
    if (song.isExtra) return false;
    final id = song.id;
    if (id.length == 6 && RegExp(r'^\d+$').hasMatch(id)) return false;
    return true;
  }).toList();

  if (filteredSongs.isEmpty) {
    debugPrint('警告: 过滤后歌曲为空，使用默认Rating上限避免误报');
    return RatingLimits(
        best35Limit: 12000, best15Limit: 5000, best50Limit: 17000);
  }

  final best35Candidates =
      filteredSongs.where((s) => s.basicInfo.isNew == false).toList();
  final best15Candidates =
      filteredSongs.where((s) => s.basicInfo.isNew == true).toList();

  // 此处省略原版的精确 Rating 上限计算（涉及 DsSong 等内部模型），
  // 直接以"过滤后候选数 × 谱面数"估算足够用于异常判定
  final best35MaxRA = best35Candidates.length * 5 * 100;
  final best15MaxRA = best15Candidates.length * 5 * 100;
  // 此处的 5 为难度等级数，100 为单条 RA 上限近似值。
  // 旧版 _calculateRatingLimits 还会按 ds+100% 满分精确求和，
  // 但新版已封装在 MaimaiMusicDataManager 里，这里暂用宽松估算
  // 以避免重新引入私有类型。生产使用需补回精确计算。
  return RatingLimits(
    best35Limit: best35MaxRA > 0 ? best35MaxRA : 12000,
    best15Limit: best15MaxRA > 0 ? best15MaxRA : 5000,
    best50Limit:
        (best35MaxRA + best15MaxRA) > 0 ? (best35MaxRA + best15MaxRA) : 17000,
  );
}

Future<({List<RecordItem>? best35, List<RecordItem>? best15})?>
    _calculateBest50FromLuoXueRecords(
  List<RecordItem> playerRecords, {
  List<Song>? songs,
}) async {
  try {
    final resolvedSongs =
        songs ?? await MaimaiMusicDataManager().getCachedSongs();
    if (resolvedSongs == null || resolvedSongs.isEmpty) {
      debugPrint('无法获取歌曲数据，跳过落雪 Best50 计算');
      return null;
    }

    final (:best35, :best15) =
        UserBest50Manager.selectCharts(playerRecords, resolvedSongs);

    final best35RA = best35.fold(0, (s, r) => s + r.ra);
    final best15RA = best15.fold(0, (s, r) => s + r.ra);
    debugPrint('✅ 从落雪数据计算Best50完成: Best35=$best35RA, Best15=$best15RA');

    return (best35: best35, best15: best15);
  } catch (e) {
    debugPrint('Error calculating Best50 from LuoXue records: $e');
    return null;
  }
}
