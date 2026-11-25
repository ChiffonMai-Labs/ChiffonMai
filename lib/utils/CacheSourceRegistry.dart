import '../l10n/AppMessages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/ApiUrls.dart';
import '../manager/SongAliasManager.dart';
import '../constant/CacheKeyConstant.dart';
import '../constant/CacheTimestampConstant.dart';

/// 应用内一个可被强制刷新的缓存源。
///
/// 设计要点：
/// - [cacheKey] / [timestampKey] 用作 SharedPreferences 查询；
///   cacheKey 用来判断"有没有缓存"，timestampKey 用来算剩余有效期。
/// - [ttlDays] = -1 表示该缓存永不过期（如 MaiTagsManager）；其它正整数 = 有效期天数。
/// - [groupKey] 把多个 UI 行映射到底层同一个缓存组（force refresh 时整组一起刷），
///   例如收藏品 6 类共享 CollectionsManager.refreshAllCollections。
class CacheSourceInfo {
  final String id;
  final String displayName;
  final String description;
  final String apiUrl;
  final String cacheKey;
  final String timestampKey;
  final int ttlDays;
  final String groupKey;

  const CacheSourceInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.apiUrl,
    required this.cacheKey,
    required this.timestampKey,
    required this.ttlDays,
    required this.groupKey,
  });
}

/// 全部缓存源注册表，按用户在「系统 → 刷新数据（高级）」看到的顺序。
///
/// 多个源共享同一 [groupKey] 时，任意一个被勾选强制刷新即触发整组刷新：
///   - 'songs'         歌曲数据（水鱼 + Union 合并写入 cachedSongs）
///   - 'aliases'       歌曲别名写入 song_aliases
///   - 'collections'   收藏品 6 类各自独立缓存但由 CollectionsManager 一并刷新
class CacheSourceRegistry {
  static const List<CacheSourceInfo> all = [
    // ── 歌曲数据 ─────────────────────────────────────────────
    CacheSourceInfo(
      id: 'songs_water_fish',
      displayName: '歌曲数据（水鱼）',
      description: '全量歌曲主库（diving-fish）',
      apiUrl: ApiUrls.MusicDataApi,
      cacheKey: CacheKeyConstant.cachedSongs,
      timestampKey: CacheKeyConstant.cachedSongsTimestamp,
      ttlDays: 7,
      groupKey: 'songs',
    ),
    CacheSourceInfo(
      id: 'songs_union',
      displayName: '歌曲数据（Union）',
      description: '补充独有歌曲（godserver）',
      apiUrl: ApiUrls.UnionMusicDataApi,
      cacheKey: CacheKeyConstant.cachedSongs,
      timestampKey: CacheKeyConstant.cachedSongsTimestamp,
      ttlDays: 7,
      groupKey: 'songs',
    ),

    // ── 难度数据 ─────────────────────────────────────────────
    CacheSourceInfo(
      id: 'diff',
      displayName: '难度数据',
      description: '谱面定数（diving-fish chart_stats）',
      apiUrl: ApiUrls.DiffMusicDataApi,
      cacheKey: CacheKeyConstant.diffMusicData,
      timestampKey: CacheKeyConstant.diffMusicDataTimestamp,
      ttlDays: 7,
      groupKey: 'diff',
    ),

    // ── 标签数据 ─────────────────────────────────────────────
    CacheSourceInfo(
      id: 'tags',
      displayName: '标签数据',
      description: 'DXRating 谱面标签',
      apiUrl: ApiUrls.TagDataApi,
      cacheKey: CacheKeyConstant.maiTagsCache,
      timestampKey: CacheKeyConstant.maiTagsCacheTimestamp,
      ttlDays: -1, // MaiTagsManager 内部标记为永不过期
      groupKey: 'tags',
    ),

    // ── 别名 ────────────────────────────────────────────────
    CacheSourceInfo(
      id: 'alias_yuzuchan',
      displayName: '别名数据',
      description: SongAliasManager.useAwmc ? 'AWMC' : 'yuzuchan.moe',
      apiUrl: SongAliasManager.useAwmc
          ? ApiUrls.AwmcCommunityAliasesApi
          : ApiUrls.SongAliasApi,
      cacheKey: 'song_aliases',
      timestampKey: 'alias_last_update',
      ttlDays: 7,
      groupKey: 'aliases',
    ),

    // ── 收藏品 ──────────────────────────────────────────────
    CacheSourceInfo(
      id: 'coll_travel_buddies',
      displayName: '收藏品-旅行伙伴',
      description: 'AWMC 旅行伙伴',
      apiUrl: '${ApiUrls.CollectionCatalogUrl}/travelBuddies',
      cacheKey: CacheKeyConstant.travelBuddiesCollectionsCacheData,
      timestampKey: CacheKeyConstant.travelBuddiesCollectionsTimestamp,
      ttlDays: CacheKeyConstant.collectionCatalogTtlDays,
      groupKey: 'collections',
    ),
    CacheSourceInfo(
      id: 'coll_partners',
      displayName: '收藏品-搭档',
      description: 'AWMC 搭档',
      apiUrl: '${ApiUrls.CollectionCatalogUrl}/partners',
      cacheKey: CacheKeyConstant.partnersCollectionsCacheData,
      timestampKey: CacheKeyConstant.partnersCollectionsTimestamp,
      ttlDays: CacheKeyConstant.collectionCatalogTtlDays,
      groupKey: 'collections',
    ),
    CacheSourceInfo(
      id: 'coll_trophies',
      displayName: '收藏品-称号',
      description: '落雪称号',
      apiUrl: '${ApiUrls.CollectionCatalogUrl}/trophies',
      cacheKey: CacheKeyConstant.trophiesCollectionsCacheData,
      timestampKey: 'trophies_collections_last_update',
      ttlDays: CacheKeyConstant.collectionCatalogTtlDays,
      groupKey: 'collections',
    ),
    CacheSourceInfo(
      id: 'coll_icons',
      displayName: '收藏品-头像',
      description: '落雪头像',
      apiUrl: '${ApiUrls.CollectionCatalogUrl}/icons',
      cacheKey: CacheKeyConstant.iconsCollectionsCacheData,
      timestampKey: 'icons_collections_last_update',
      ttlDays: CacheKeyConstant.collectionCatalogTtlDays,
      groupKey: 'collections',
    ),
    CacheSourceInfo(
      id: 'coll_plates',
      displayName: '收藏品-姓名框',
      description: '落雪姓名框',
      apiUrl: '${ApiUrls.CollectionCatalogUrl}/plates',
      cacheKey: CacheKeyConstant.platesCollectionsCacheData,
      timestampKey: 'plates_collections_last_update',
      ttlDays: CacheKeyConstant.collectionCatalogTtlDays,
      groupKey: 'collections',
    ),
    CacheSourceInfo(
      id: 'coll_frames',
      displayName: '收藏品-背景',
      description: '落雪背景',
      apiUrl: '${ApiUrls.CollectionCatalogUrl}/frames',
      cacheKey: CacheKeyConstant.framesCollectionsCacheData,
      timestampKey: 'frames_collections_last_update',
      ttlDays: CacheKeyConstant.collectionCatalogTtlDays,
      groupKey: 'collections',
    ),

    // ── Union 元数据 ─────────────────────────────────────
    CacheSourceInfo(
      id: 'union',
      displayName: 'Union 元数据',
      description: 'cn/jp 可游玩地区等',
      apiUrl: ApiUrls.UnionApi,
      cacheKey: CacheKeyConstant.unionCache,
      timestampKey: CacheKeyConstant.unionCacheTimestamp,
      ttlDays: 7,
      groupKey: 'union',
    ),

    // ── maidata（轻量目录索引，单曲谱面按需缓存） ───
    CacheSourceInfo(
      id: 'maidata',
      displayName: 'maidata',
      description: '谱面目录索引（单曲谱面按需缓存）',
      apiUrl: ApiUrls.MaidataCatalogUrl,
      cacheKey: CacheKeyConstant.maidataCatalogEtag,
      timestampKey: CacheKeyConstant.maidataCatalogTimestamp,
      ttlDays: CacheTimestampConstant.maidataCatalogCacheDays,
      groupKey: 'maidata',
    ),
  ];

  /// 按 [groupKey] 分组，便于 force refresh 时按组执行。
  static Map<String, List<CacheSourceInfo>> groupedByGroup() {
    final map = <String, List<CacheSourceInfo>>{};
    for (final s in all) {
      map.putIfAbsent(s.groupKey, () => []).add(s);
    }
    return map;
  }
}

/// 读取 [source] 对应缓存时间戳，并格式化为"剩余 X 天 Y 小时 / 已过期..."。
///
/// 返回格式：
///   - ttlDays == -1                       → "永不过期"
///   - 没有缓存                            → "无缓存"
///   - 有缓存但无时间戳                    → "无缓存时间戳"
///   - 在 TTL 内                           → "剩余 X 天 Y 小时"（按粒度截断到天/小时/分钟）
///   - 已过期                              → "已过期 X 天 Y 小时"
Future<String> formatRemainingValidity(CacheSourceInfo source) async {
  if (source.ttlDays == -1) return appL10n.flowCacheNeverExpires;
  final prefs = await SharedPreferences.getInstance();
  final ts = prefs.getInt(source.timestampKey);
  if (ts == null) {
    final hasCache = prefs.getString(source.cacheKey) != null;
    return hasCache ? appL10n.flowCacheNoTimestamp : appL10n.flowCacheAbsent;
  }
  final now = DateTime.now().millisecondsSinceEpoch;
  final ttlMs = source.ttlDays * 24 * 60 * 60 * 1000;
  final remainingMs = ts + ttlMs - now;
  if (remainingMs <= 0) {
    return appL10n.flowCacheExpired(_formatDurationShort(-remainingMs));
  }
  return appL10n.flowCacheRemaining(_formatDurationShort(remainingMs));
}

String _formatDurationShort(int ms) {
  final days = ms ~/ (24 * 60 * 60 * 1000);
  final hours = (ms % (24 * 60 * 60 * 1000)) ~/ (60 * 60 * 1000);
  final minutes = (ms % (60 * 60 * 1000)) ~/ (60 * 1000);
  if (days > 0) {
    return hours > 0
        ? appL10n.flowCacheDaysHours(days.toString(), hours.toString())
        : appL10n.flowCacheDays(days.toString());
  }
  if (hours > 0) {
    return minutes > 0
        ? appL10n.flowCacheHoursMinutes(hours.toString(), minutes.toString())
        : appL10n.flowCacheHours(hours.toString());
  }
  return appL10n.flowCacheMinutes(minutes.toString());
}
