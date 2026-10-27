import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/CacheKeyConstant.dart';
import '../../entity/AWMC/AwmcUserMusic.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import 'AwmcApiService.dart';
import 'AwmcQuickSyncService.dart';

/// 游玩次数（`playCount`）本地缓存 —— **按账号分开存**。
///
/// 数据来源：AWMC 网关独立的游玩次数接口（服务端内部调用 `/v1/user/music`，
/// 全部成绩，4 Token/次），
/// 每条记录的 `(musicId, level, playCount)` 都是机台真实数据，
/// `musicId` 与水鱼 songId 对齐，所以能直接和 App 里的曲库对上。
/// （AWMC NET 查分器**没有**逐谱面次数，只有 `/api/player/{qq}` 的账号总计，
/// 所以它给不了这里要的数据，见 `docs` 里那条结论。）
///
/// ── 为什么每个账号一份 ──
/// 账号系统里水鱼 / 落雪 / AWMC NET 是三类**互不相干**的账号（可以绑不同的 QQ、
/// 不同的机台账号）。游玩次数必须跟着账号走：
///   * prefs 键：`awmc_play_counts_v1_<source>`（[CacheKeyConstant.awmcPlayCountsPrefix]）；
///   * 写入时**显式指定**这份次数属于哪个账号（谁同步就写谁，见各调用点）；
///   * 读取时取**当前活动账号**那一份（`CurrentDataSourceNotifier`），
///     所以谱面详情 / PC50 显示的次数永远和正在看的成绩是同一个账号。
///
/// 旧版只有一个共享键 `awmc_play_counts_v1`，换账号后会显示上一个账号的次数 ——
/// 首次读取时会按 `last_data_source` 把它迁到对应账号名下再删掉。
///
/// 存两层：内存（[_bySource]，页面读取零成本）+ prefs（重启后仍在，
/// 不用为了看一眼游玩次数再花 4 Token）。属于「可重新拉取的缓存」，
/// 不进备份（[DataBackupService.isCacheKey] 为真）。
class AwmcPlayCountStore {
  AwmcPlayCountStore._();

  /// 存储格式版本，将来字段变了可以据此丢弃旧缓存。
  static const int _version = 1;

  /// sourceKey → (`'musicId/level'` → playCount)。**三个账号各一份，互不影响。**
  static final Map<String, Map<String, int>> _bySource = {};

  static final Map<String, int> _updatedAtBySource = {};
  static bool _loaded = false;
  static final Map<String, int> _generations = {};

  static String _key(int musicId, int level) => '$musicId/$level';

  /// 当前活动账号（读取端用它决定看哪一份次数）。
  static RefreshDataSource get activeSource =>
      CurrentDataSourceNotifier.instance.value;

  static String _prefsKeyOf(RefreshDataSource source) =>
      '${CacheKeyConstant.awmcPlayCountsPrefix}${source.key}';

  static Map<String, int> _countsOf(RefreshDataSource source) =>
      _bySource[source.key] ?? const {};

  /// 当前活动账号的那一份（读取端全走这里）。
  static Map<String, int> get _active => _countsOf(activeSource);

  /// 是否已经加载过 prefs（页面可据此决定要不要 await）。
  static bool get isLoaded => _loaded;

  /// **当前账号**缓存了多少条 (曲目, 难度) 记录。
  static int get size => _active.length;

  /// **当前账号**上次更新时间（毫秒时间戳；0 表示从未拉取过）。
  static int get updatedAtMs => _updatedAtBySource[activeSource.key] ?? 0;

  static bool get hasData => _active.isNotEmpty;

  static String get updatedAtText {
    final ms = updatedAtMs;
    if (ms <= 0) return '从未同步';
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }

  // ══════════════════════════════════════════════════════════════════════
  //  读取
  // ══════════════════════════════════════════════════════════════════════

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await _migrateLegacySharedKey(prefs);
      for (final source in RefreshDataSource.values) {
        await _readBucket(prefs, source);
      }
    } catch (e) {
      debugPrint('[AWMC] 游玩次数缓存读取失败（忽略）: ${AwmcApiService.redact('$e')}');
    }
    _loaded = true;
  }

  static Future<void> _readBucket(
      SharedPreferences prefs, RefreshDataSource source) async {
    _bySource.remove(source.key);
    _updatedAtBySource.remove(source.key);
    final raw = prefs.getString(_prefsKeyOf(source));
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return;
      // 旧版次数缓存不需要机台身份；移除其明文副本，快速更新另用安全存储。
      if (decoded.containsKey('userId')) {
        decoded.remove('userId');
        await prefs.setString(_prefsKeyOf(source), json.encode(decoded));
      }
      if (decoded['version'] != _version) {
        debugPrint('[AWMC] 游玩次数缓存版本不匹配'
            '（${source.key}: ${decoded['version']}），已忽略');
        return;
      }
      _updatedAtBySource[source.key] =
          (decoded['updatedAt'] as num?)?.toInt() ?? 0;
      final counts = decoded['counts'];
      if (counts is Map) {
        final bucket = <String, int>{};
        counts.forEach((k, v) {
          final value = (v as num?)?.toInt();
          if (value != null) bucket['$k'] = value;
        });
        _bySource[source.key] = bucket;
      }
    } catch (e) {
      debugPrint('[AWMC] 游玩次数缓存解析失败（${source.key}，忽略）: '
          '${AwmcApiService.redact('$e')}');
    }
  }

  /// 把旧版的**共享**键迁到「当时那个账号」名下，然后删掉它。
  ///
  /// 归属判断用 `last_data_source`：旧版写入时活动的就是那个源。
  /// 认不出来（键不存在/值坏了）就什么都不做 —— 宁可让用户重新同步一次，
  /// 也不能把别人的次数塞给当前账号。
  static Future<void> _migrateLegacySharedKey(SharedPreferences prefs) async {
    final legacy = prefs.getString(CacheKeyConstant.awmcPlayCountsLegacy);
    if (legacy == null || legacy.isEmpty) return;
    final source = RefreshDataSource.fromKey(
      prefs.getString(CacheKeyConstant.lastDataSource),
    );
    final targetKey = _prefsKeyOf(source);
    if (!prefs.containsKey(targetKey)) {
      await prefs.setString(targetKey, legacy);
      debugPrint('[AWMC] 旧的共享游玩次数已迁移到 ${source.key} 名下');
    }
    await prefs.remove(CacheKeyConstant.awmcPlayCountsLegacy);
  }

  /// 查某个难度的游玩次数；没有该难度的记录时返回 null。
  ///
  /// 注意「没有记录」和「记录为 0」是两回事：上游不会返回 playCount=0 的条目，
  /// 所以 null 表示**这台机台的账号没有这张谱面的成绩**，UI 应当不显示这一行，
  /// 而不是显示 0。
  static int? playCountOf(int musicId, int level) =>
      _active[_key(musicId, level)];

  /// 按本 App 的难度下标查（0–4 → BASIC…Re:MASTER，5 → 宴会场）。
  static int? playCountOfDiffIndex(int musicId, int diffIndex) =>
      playCountOf(musicId, AwmcUserMusicRecord.diffIndexToLevel(diffIndex));

  /// 该曲目所有难度的游玩次数之和（没有记录时返回 0）。
  static int totalPlayCountOf(int musicId) {
    var sum = 0;
    final prefix = '$musicId/';
    _active.forEach((k, v) {
      if (k.startsWith(prefix)) sum += v;
    });
    return sum;
  }

  // ══════════════════════════════════════════════════════════════════════
  //  写入
  // ══════════════════════════════════════════════════════════════════════

  /// 用 `/v1/user/music` 的 `businessData` 覆盖**某个账号**的缓存。
  ///
  /// [source] 不传时写入**当前活动账号**（网关控制台这类没有账号上下文的入口）；
  /// 同步 / 刷新流程请显式传自己的目标源，别让它落到别人名下。
  ///
  /// 返回写入的条数。**解析不出来时返回 0 且不动旧数据**——
  /// 宁可显示上一次的数据，也不能因为一次异常响应把缓存清空。
  static Future<int> saveFromBusinessData(
    dynamic businessData, {
    RefreshDataSource? source,
  }) async {
    final target = source ?? activeSource;
    final parsed = AwmcUserMusicResponse.fromBusinessData(businessData);
    final records = parsed.records;
    if (records.isEmpty) {
      debugPrint('[AWMC] 游玩次数：响应里没有解析出任何成绩，保留旧缓存');
      return 0;
    }

    final bucket = <String, int>{};
    for (final r in records) {
      if (r.musicId <= 0) continue;
      bucket[_key(r.musicId, r.level)] = r.playCount;
    }
    _bySource[target.key] = bucket;
    _updatedAtBySource[target.key] = DateTime.now().millisecondsSinceEpoch;
    _loaded = true;
    await _persist(target);
    debugPrint('[AWMC] 游玩次数缓存已更新（${target.key}）：${bucket.length} 条 / '
        '${parsed.songCount} 首');
    return bucket.length;
  }

  /// 拉取独立的游玩次数接口并写进 [source]（默认当前账号）的缓存；
  /// 返回原始调用结果（供 UI 展示/审计）。
  ///
  /// 是否计费、是否成功都由调用方判断：本方法只在成功时写缓存。
  static Future<AwmcCallResult> refreshFromGateway({
    required String token,
    required String qrcode,
    RefreshDataSource? source,
  }) async {
    final target = source ?? activeSource;
    final generation = _generations[target.key] ?? 0;
    final identityAccount =
        await AwmcQuickSyncService.captureIdentityAccount(target);
    final result = await AwmcApiService.userPlayCounts(
      token: token,
      qrcode: qrcode,
    );
    if (result.ok && generation == (_generations[target.key] ?? 0)) {
      await saveFromBusinessData(result.businessData, source: target);
      await AwmcQuickSyncService.rememberIdentity(
          identityAccount, result.businessData);
    }
    return result;
  }

  // 刻意不再提供「同步后顺手拿同一张二维码刷新游玩次数」的接口：
  // 上游已限制一张二维码只能处理一个请求，游玩次数改由独立功能
  // （AwmcPlayCountSyncFlow）用新二维码单独读取。

  static Future<void> _persist(RefreshDataSource source) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKeyOf(source),
        json.encode({
          'version': _version,
          'updatedAt': _updatedAtBySource[source.key] ?? 0,
          'counts': _bySource[source.key] ?? const <String, int>{},
        }),
      );
    } catch (e) {
      debugPrint('[AWMC] 游玩次数缓存写入失败（忽略）: ${AwmcApiService.redact('$e')}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  //  清理
  // ══════════════════════════════════════════════════════════════════════

  /// 清空**某个账号**的缓存（内存 + prefs）；[source] 默认当前活动账号。
  static Future<void> clear({RefreshDataSource? source}) async {
    final target = source ?? activeSource;
    _generations[target.key] = (_generations[target.key] ?? 0) + 1;
    _bySource.remove(target.key);
    _updatedAtBySource.remove(target.key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyOf(target));
  }

  /// 清空**全部三个账号**的缓存（排查数据异常 / 备份导入前用）。
  static Future<void> clearAll() async {
    for (final source in RefreshDataSource.values) {
      await clear(source: source);
    }
  }

  /// 仅供测试：复位内存与「已加载」标志（**不动 prefs**），
  /// 以便验证「重启后再从 prefs 读回来」这条路径。
  @visibleForTesting
  static void debugResetForTest() {
    _generations.clear();
    _bySource.clear();
    _updatedAtBySource.clear();
    _loaded = false;
  }
}
