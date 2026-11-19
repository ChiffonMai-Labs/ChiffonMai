import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/ApiClient.dart';
import '../utils/AwmcIdMap.dart';

/// AWMC 曲绘专用的磁盘缓存。
///
/// 主链的响应头是 `cache-control: public, max-age=31536000, immutable`，
/// 次链也带 `max-age=86400, s-maxage=2592000`。单开一个库，避免和头像等
/// 图片互相驱逐；按 30 天 / 1000 张存（webp 单张约 14~33 KB）。
final CacheManager awmcCoverCacheManager = CacheManager(
  Config(
    'awmc_covers_v1',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 1000,
  ),
);

/// 一个可用的曲绘出处（对应 AWMC 目录里的一条谱面记录）。
///
/// `imageRev` 是曲绘内容指纹，换图即换路径；拿不到（或主链已 404）时只走次链。
class AwmcCoverVariant {
  AwmcCoverVariant({
    required this.chartFileId,
    required this.type,
    required this.versionFolder,
    required this.folderName,
    this.imageRev,
  });

  final int chartFileId;

  /// `ST` / `DX` / `UTG`（raw=1 的记录没有 type 字段，由 shortid 区间推断）。
  final String type;

  final String versionFolder;
  final String folderName;
  String? imageRev;

  String get shortId => AwmcIdMap.shortIdFromChartFileId(chartFileId)!;

  String get baseSongId => '${AwmcIdMap.baseSongId(chartFileId)}';

  /// 主链（对象存储里的 webp）；没有 imageRev 时返回 null。
  String? primaryUrl(int width) {
    final rev = imageRev;
    if (rev == null || rev.isEmpty) return null;
    return '${AwmcCoverService.primaryBase}'
        '/${Uri.encodeComponent(versionFolder)}'
        '/${Uri.encodeComponent(folderName)}'
        '/${Uri.encodeComponent(rev)}'
        '/w${AwmcCoverService.nearestWidth(width)}.webp';
  }

  /// 次链（源站直接出图，并回填对象存储）。
  String secondaryUrl() {
    return '${AwmcCoverService.secondaryBase}'
        '/${Uri.encodeComponent(versionFolder)}'
        '/${Uri.encodeComponent(folderName)}'
        '?w=360&src=origin';
  }

  Map<String, Object?> toJson() => {
        'c': chartFileId,
        't': type,
        'vf': versionFolder,
        'fn': folderName,
        if (imageRev != null && imageRev!.isNotEmpty) 'rev': imageRev,
      };

  static AwmcCoverVariant? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['c'];
    final vf = raw['vf'];
    final fn = raw['fn'];
    if (id is! num || vf is! String || fn is! String) return null;
    if (vf.isEmpty || fn.isEmpty) return null;
    final chartFileId = id.toInt();
    if (!AwmcIdMap.isValidChartFileId(chartFileId)) return null;
    final declaredType = raw['t'];
    final rev = raw['rev'];
    return AwmcCoverVariant(
      chartFileId: chartFileId,
      type: declaredType is String && declaredType.isNotEmpty
          ? declaredType
          : _typeLabel(chartFileId),
      versionFolder: vf,
      folderName: fn,
      imageRev: rev is String && rev.isNotEmpty ? rev : null,
    );
  }
}

/// 曲绘候选：主链 / 次链，以及失败后要怎样自愈。
class AwmcCoverCandidate {
  const AwmcCoverCandidate({
    required this.url,
    required this.isPrimary,
    required this.variant,
  });

  final String url;
  final bool isPrimary;
  final AwmcCoverVariant variant;
}

/// AWMC 曲绘兜底（P2-02）。
///
/// 本地 assets 与水鱼主封面都拿不到时，`CoverUtil` 才走到这里：
///   1. 主链：`https://oss.awmc.cc/covers/{版本目录}/{曲目目录}/{imageRev}/w{240|360|480}.webp`；
///   2. 主链 404（imageRev 过期 / 文件缺失）→ 走次链
///      `https://download.wmc.pub/cdn/v1/img/{版本目录}/{曲目目录}?w=360&src=origin`，
///      同时按 `shortid` 重新拉一次单曲信息修好索引（自愈并落盘）；
///   3. 这首歌在 ST / DX 另一边有谱面时，按孪生 id 再试一次；
///   4. 全都不行由调用方收尾到默认曲绘 `assets/cover/0.webp`。
///
/// `imageRev` 不随包固化：随包索引由 `tool/gen_awmc_cover_index.cjs` 生成，
/// 运行时命中失败会更新 `SharedPreferences` 里的索引缓存，下次启动直接可用。
class AwmcCoverService {
  AwmcCoverService._();

  static final AwmcCoverService instance = AwmcCoverService._();

  static const String primaryBase = 'https://oss.awmc.cc/covers';
  static const String secondaryBase = 'https://download.wmc.pub/cdn/v1/img';
  static const String chartApi = 'https://download.wmc.pub/api/v1/charts';

  /// 随包索引（构建期由 `tool/gen_awmc_cover_index.cjs` 生成）。
  static const String bundledAssetPath = 'assets/awmc_cover_index.json';

  /// 运行时自愈后的索引缓存（覆盖随包索引里过期的 imageRev）。
  static const String prefsKey = 'awmc_cover_index_v1';

  static const int cacheVersion = 1;

  /// 主链可选宽度，取最接近的档位。
  static const List<int> widths = [240, 360, 480];

  static int nearestWidth(int width) {
    if (width <= widths.first) return widths.first;
    if (width >= widths.last) return widths.last;
    var best = widths.first;
    for (final candidate in widths) {
      if ((candidate - width).abs() < (best - width).abs()) best = candidate;
    }
    return best;
  }

  /// 基础 songId → 该歌的谱面出处（最多 ST / DX 两条）。
  Map<String, List<AwmcCoverVariant>> _index = {};
  bool _loaded = false;
  Future<void>? _loading;

  /// 本会话确认 AWMC 也没有的 baseSongId（避免反复请求）。
  final Set<String> _misses = {};

  /// 本会话确认坏掉的主链（`<chartFileId>:<imageRev>`）。只在内存里降级，
  /// 不把 rev 从索引抹掉：网络恢复或图片修复后下一轮仍能重新尝试主链。
  final Set<String> _brokenPrimary = {};

  /// 单飞：同一个 baseSongId 的补查只跑一次。
  final Map<String, Future<void>> _lookups = {};

  /// 单飞：同一张谱的主链修复只跑一次。
  final Map<int, Future<String?>> _heals = {};

  bool get isLoaded => _loaded;

  int get indexSize =>
      _index.values.fold(0, (sum, variants) => sum + variants.length);

  // ===========================================================================
  // 加载
  // ===========================================================================

  /// 确保索引可用。重复调用安全（单飞），只读随包索引与本地缓存。
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    final bundled = await _readBundled();
    final cached = await _readCached();
    // 本地缓存是自愈产物；随包索引更新后应以随包为准。
    final chosen = _prefer(cached, bundled);
    if (chosen != null) _index = chosen;
    _loaded = true;
  }

  /// 两份索引按 `savedAt` / `generatedAt` 取新的；一样新时用本地缓存。
  Map<String, List<AwmcCoverVariant>>? _prefer(
    _IndexSource? cached,
    _IndexSource? bundled,
  ) {
    if (cached == null) return bundled?.index;
    if (bundled == null) return cached.index;
    final cachedAt = cached.at;
    final bundledAt = bundled.at;
    if (bundledAt != null && cachedAt != null && bundledAt.isAfter(cachedAt)) {
      return bundled.index;
    }
    return cached.index;
  }

  Future<_IndexSource?> _readBundled() async {
    try {
      return _parseIndex(await rootBundle.loadString(bundledAssetPath));
    } catch (_) {
      // 占位索引不存在时按空索引处理
      return null;
    }
  }

  Future<_IndexSource?> _readCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(prefsKey);
      if (text == null || text.isEmpty) return null;
      return _parseIndex(text);
    } catch (e) {
      debugPrint('[AwmcCover] 读取索引缓存失败（忽略）: $e');
      return null;
    }
  }

  _IndexSource? _parseIndex(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map || decoded['v'] != cacheVersion) return null;
      final raw = decoded['covers'];
      if (raw is! Map) return null;
      final index = <String, List<AwmcCoverVariant>>{};
      for (final entry in raw.entries) {
        final base = '${entry.key}';
        final list = entry.value;
        if (list is! List) continue;
        final variants = <AwmcCoverVariant>[];
        for (final item in list) {
          final variant = AwmcCoverVariant.fromJson(item);
          if (variant == null) continue;
          if (variant.baseSongId != base) continue;
          if (variants.any((v) => v.chartFileId == variant.chartFileId)) {
            continue;
          }
          variants.add(variant);
        }
        if (variants.isEmpty) continue;
        _sortVariants(variants, null);
        index[base] = variants;
      }
      if (index.isEmpty) return null;
      // 随包索引写 `generatedAt`（ISO），运行时缓存写 `savedAt`（毫秒）
      final savedMs = decoded['savedAt'];
      final generatedAt = decoded['generatedAt'];
      final at = savedMs is num
          ? DateTime.fromMillisecondsSinceEpoch(savedMs.toInt())
          : (generatedAt is String ? DateTime.tryParse(generatedAt) : null);
      return (index: index, at: at);
    } catch (e) {
      debugPrint('[AwmcCover] 解析索引失败（忽略）: $e');
      return null;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefsKey,
        jsonEncode({
          'v': cacheVersion,
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'covers': {
            for (final entry in _index.entries)
              entry.key: [for (final v in entry.value) v.toJson()],
          },
        }),
      );
    } catch (e) {
      debugPrint('[AwmcCover] 写入索引缓存失败（忽略）: $e');
    }
  }

  // ===========================================================================
  // 查询
  // ===========================================================================

  /// 请求的谱面优先，孪生 id 在后。
  void _sortVariants(List<AwmcCoverVariant> variants, int? preferred) {
    const order = {'ST': 0, 'DX': 1, 'UTG': 2};
    variants.sort((a, b) {
      if (a.chartFileId == preferred) return -1;
      if (b.chartFileId == preferred) return 1;
      final byType = (order[a.type] ?? 9).compareTo(order[b.type] ?? 9);
      if (byType != 0) return byType;
      return a.chartFileId.compareTo(b.chartFileId);
    });
  }

  List<AwmcCoverVariant> _variantsFor(String songId) {
    final preferred = AwmcIdMap.chartFileIdFromShortId(songId.trim());
    if (preferred == null) return const [];
    final baseId = AwmcIdMap.baseSongId(preferred);
    if (baseId == null) return const [];
    final variants = _index['$baseId'];
    if (variants == null) return const [];
    if (variants.length > 1 && variants.first.chartFileId != preferred) {
      final sorted = List<AwmcCoverVariant>.of(variants);
      _sortVariants(sorted, preferred);
      return sorted;
    }
    return variants;
  }

  /// 索引就绪时的最佳同步 URL（供 `ImageProvider` 使用；拿不到返回 null）。
  String? coverUrlFor(String songId, {int width = 360}) {
    if (!_loaded) return null;
    final variants = _variantsFor(songId);
    for (final variant in variants) {
      final primary = variant.primaryUrl(width);
      if (primary != null && !_isPrimaryBroken(variant)) return primary;
    }
    for (final variant in variants) {
      return variant.secondaryUrl();
    }
    return null;
  }

  bool _isPrimaryBroken(AwmcCoverVariant variant) {
    final rev = variant.imageRev;
    return rev != null && _brokenPrimary.contains('${variant.chartFileId}:$rev');
  }

  /// 按顺序给出所有候选：请求的谱面 / 孪生谱面的主链、次链。
  ///
  /// 索引里没有这首歌时会补查一次单曲接口（每首最多一次 / 会话）。
  Future<List<AwmcCoverCandidate>> coverCandidates(
    String songId, {
    int width = 360,
  }) async {
    final chartFileId = AwmcIdMap.chartFileIdFromShortId(songId.trim());
    if (chartFileId == null) return const [];
    final baseId = AwmcIdMap.baseSongId(chartFileId);
    if (baseId == null) return const [];
    final base = '$baseId';

    await ensureLoaded();
    if (!_index.containsKey(base) && !_misses.contains(base)) {
      await (_lookups[base] ??=
          _lookup(chartFileId).whenComplete(() => _lookups.remove(base)));
    }

    final candidates = <AwmcCoverCandidate>[];
    for (final variant in _variantsFor(songId)) {
      final primary = variant.primaryUrl(width);
      if (primary != null && !_isPrimaryBroken(variant)) {
        candidates.add(AwmcCoverCandidate(
          url: primary,
          isPrimary: true,
          variant: variant,
        ));
      }
      candidates.add(AwmcCoverCandidate(
        url: variant.secondaryUrl(),
        isPrimary: false,
        variant: variant,
      ));
    }
    return candidates;
  }

  /// 主链失败：本会话先停用这条 imageRev，再按 shortid 重拉一次目录自愈。
  /// 返回修复后的主链 URL；修不好返回 null（调用方继续走次链）。
  ///
  /// 注意**不把 rev 写空**：离线 / 5xx 也可能触发失败，抹掉 rev 后下次启动
  /// 就再也拿不到主链候选，自愈也失去了由头。
  Future<String?> reportBrokenPrimary(AwmcCoverVariant variant) {
    final rev = variant.imageRev;
    if (rev != null) _brokenPrimary.add('${variant.chartFileId}:$rev');
    return _heals[variant.chartFileId] ??= _heal(variant.chartFileId)
        .whenComplete(() => _heals.remove(variant.chartFileId));
  }

  Future<String?> _heal(int chartFileId) async {
    final fresh = await _fetchVariant(chartFileId);
    if (fresh == null || fresh.imageRev == null) return null;
    final base = fresh.baseSongId;
    final variants = _index[base] ?? <AwmcCoverVariant>[];
    final at = variants.indexWhere((v) => v.chartFileId == chartFileId);
    if (at >= 0) {
      final oldRev = variants[at].imageRev;
      if (oldRev != null) {
        _brokenPrimary.remove('$chartFileId:$oldRev');
      }
      _brokenPrimary.remove('$chartFileId:${fresh.imageRev}');
      variants[at].imageRev = fresh.imageRev;
      // 曲目目录也可能被重命名（换图常伴随改名），一并更新。
      final replaced = AwmcCoverVariant(
        chartFileId: chartFileId,
        type: fresh.type,
        versionFolder: fresh.versionFolder,
        folderName: fresh.folderName,
        imageRev: fresh.imageRev,
      );
      variants[at] = replaced;
      _index[base] = variants;
      await _persist();
      return replaced.primaryUrl(360);
    }
    // 索引里本来没有这条（请求的是孪生 id），补进去。
    variants.add(fresh);
    _sortVariants(variants, chartFileId);
    _index[base] = variants;
    await _persist();
    return fresh.primaryUrl(360);
  }

  /// 按谱面 id 补查目录；返回解析出的出处，失败返回 null。
  ///
  /// [onDefinitive] 告诉调用方这次失败是不是「谱面确实不在」：404 / 410 算
  /// 确定缺席，可以记负面缓存；网络异常与非 404 状态码只算暂时失败，
  /// 恢复后还应当重试。
  Future<AwmcCoverVariant?> _fetchVariant(
    int chartFileId, {
    void Function(bool definitive)? onDefinitive,
  }) async {
    final shortId = AwmcIdMap.shortIdFromChartFileId(chartFileId);
    if (shortId == null) return null;
    try {
      final response = await ApiClient.get(
        Uri.parse('$chartApi/$shortId?raw=1'),
      );
      if (response.statusCode != 200) {
        onDefinitive?.call(
            response.statusCode == 404 || response.statusCode == 410);
        return null;
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return null;
      final chart = decoded['chart'] ?? decoded;
      if (chart is! Map) return null;
      final vf = chart['versionFolder'];
      final fn = chart['folderName'];
      if (vf is! String || fn is! String || vf.isEmpty || fn.isEmpty) {
        return null;
      }
      final rev = chart['imageRev'];
      return AwmcCoverVariant(
        chartFileId: chartFileId,
        type: _typeLabel(chartFileId),
        versionFolder: vf,
        folderName: fn,
        imageRev: rev is String && rev.isNotEmpty ? rev : null,
      );
    } catch (e) {
      debugPrint('[AwmcCover] 补查 $shortId 失败（忽略）: $e');
      return null;
    }
  }

  /// 索引缺这首歌：请求的谱面先查，再试 ST / DX 孪生 id。
  Future<void> _lookup(int chartFileId) async {
    final baseId = AwmcIdMap.baseSongId(chartFileId);
    if (baseId == null) return;
    final base = '$baseId';
    final found = <AwmcCoverVariant>[];
    var allDefinitive = true;
    for (final twin in AwmcIdMap.coverFallbackIds(chartFileId)) {
      final variant = await _fetchVariant(
        twin,
        onDefinitive: (definitive) {
          if (!definitive) allDefinitive = false;
        },
      );
      if (variant == null) continue;
      if (variant.baseSongId != base) continue;
      found.add(variant);
    }
    if (found.isEmpty) {
      // 只有接口明确说「没有」才记负面缓存；断网时下次仍要重试。
      if (allDefinitive) _misses.add(base);
      return;
    }
    found.sort((a, b) => a.chartFileId.compareTo(b.chartFileId));
    final variants = _index[base] ?? <AwmcCoverVariant>[];
    for (final variant in found) {
      if (variants.any((v) => v.chartFileId == variant.chartFileId)) continue;
      variants.add(variant);
    }
    _sortVariants(variants, chartFileId);
    _index[base] = variants;
    await _persist();
  }

  // ===========================================================================
  // 测试辅助
  // ===========================================================================

  /// 仅供测试：直接注入索引。
  @visibleForTesting
  void debugSetIndex(Map<String, List<AwmcCoverVariant>> index) {
    _index = Map.unmodifiable(index);
    _loaded = true;
  }

  /// 仅供测试：复位内存状态（不动磁盘缓存与随包索引）。
  @visibleForTesting
  void debugResetForTest() {
    _index = {};
    _loaded = false;
    _loading = null;
    _misses.clear();
    _lookups.clear();
    _heals.clear();
  }
}

typedef _IndexSource = ({
  Map<String, List<AwmcCoverVariant>> index,
  DateTime? at,
});

/// 谱面文件 id → 索引里记录的简短类型（只用于诊断与排序）。
String _typeLabel(int chartFileId) =>
    switch (AwmcIdMap.kindOfChartFileId(chartFileId)) {
      AwmcChartKind.dx => 'DX',
      AwmcChartKind.utage => 'UTG',
      _ => 'ST',
    };
