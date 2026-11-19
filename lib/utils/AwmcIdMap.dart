/// AWMC 曲目编号映射工具：shortid / chartFileId / baseSongId / 本地 songId。
///
/// **两套编号，别混用：**
/// - **谱面文件 id（chartFileId）**：AWMC 站点用它的 6 位补零写法（shortid）
///   标识单张谱面。项目本地 songId 与它同一套：ST 用曲号、DX 用曲号 +10000、
///   宴谱用原号；DX 的谱面文件 id 必然是 5 位数（10000–99999）。
/// - **基础曲号（baseSongId）**：去掉 DX 前缀（+10000）后的曲号，AWMC 的
///   `/api/v1/charts/{songId}:{kind}:{difficulty}` 等接口、别名索引和曲绘索引
///   用它（P2-02 的 `normalizeSongId` 就是这件事）。
///
/// **类型区间依据 P0-03：** `?raw=1` 的目录记录没有 `type` 字段，只能按
/// shortid 数值区间判断——≥100000 宴谱、10000–99999 DX、1–9999 ST；
/// `[DX]` / `[宴]` 前缀只在能拿到 displayName 时作补充。因此本工具的类型
/// 判断只认数值，不看调用方传入的 kind。
///
/// **补零规则：** shortid 是 chartFileId 补零到 6 位的字符串
/// （8 → `000008`、11209 → `011209`）；宴谱本来就是 6 位，原样返回、不补零。
///
/// **非法输入：** 解析 / 查询类函数返回 `null`（shortid 不是 1–6 位纯数字、
/// id 不在 1–999999 等），列表类返回空列表；不会把非法 id 悄悄折算成 0。
/// 已知边界：DX 10000 的孪生 id 是 0，作为“候选”正常返回。
abstract final class AwmcIdMap {
  /// DX 谱相对基础曲号的偏移。
  static const int dxOffset = 10000;

  /// 宴谱 shortid 的下界。
  static const int utageMin = 100000;

  /// 6 位 shortid 能表示的最大 id。
  static const int maxChartFileId = 999999;

  static final RegExp _shortIdPattern = RegExp(r'^\d{1,6}$');

  /// 是否是合法的谱面文件 id：1–999999 的整数。
  static bool isValidChartFileId(int? chartFileId) =>
      chartFileId != null && chartFileId > 0 && chartFileId <= maxChartFileId;

  /// 是否是合法的 shortid：1–6 位纯数字，且数值是合法 id。
  static bool isValidShortId(String? shortid) =>
      chartFileIdFromShortId(shortid) != null;

  /// 按数值区间判断类型；非法 id 返回 null。
  static AwmcChartKind? kindOfChartFileId(int? chartFileId) {
    if (!isValidChartFileId(chartFileId)) return null;
    final id = chartFileId!;
    if (id >= utageMin) return AwmcChartKind.utage;
    if (id >= dxOffset) return AwmcChartKind.dx;
    return AwmcChartKind.standard;
  }

  /// 按 shortid 的数值区间判断类型；非法 shortid 返回 null。
  static AwmcChartKind? kindOfShortId(String? shortid) =>
      kindOfChartFileId(chartFileIdFromShortId(shortid));

  /// shortid → 数值 id：兼容补零与不补零写法（`000008` / `8` 都是 8）。
  /// 非法 shortid 返回 null。
  static int? chartFileIdFromShortId(String? shortid) {
    final text = shortid?.trim() ?? '';
    if (!_shortIdPattern.hasMatch(text)) return null;
    final id = int.tryParse(text);
    return isValidChartFileId(id) ? id : null;
  }

  /// 数值 id → shortid：ST/DX 补零到 6 位，宴谱原样不补零。
  /// 非法 id 返回 null。
  static String? shortIdFromChartFileId(int? chartFileId) {
    if (!isValidChartFileId(chartFileId)) return null;
    final id = chartFileId!;
    // 宴谱本身就是 6 位，原样返回；其余补零到 6 位。
    if (id >= utageMin) return '$id';
    return id.toString().padLeft(6, '0');
  }

  /// 把任一编号归一化为基础曲号：DX 减去 10000，ST 与宴谱原样。
  /// 非法 id 返回 null。
  static int? baseSongId(int? chartFileId) {
    final kind = kindOfChartFileId(chartFileId);
    if (kind == null) return null;
    return kind == AwmcChartKind.dx ? chartFileId! - dxOffset : chartFileId;
  }

  /// [baseSongId] 的同义词，对应接入清单 P2-02 的 `normalizeSongId`。
  static int? normalizeSongId(int? songId) => baseSongId(songId);

  /// [baseSongId] 的反方向叫法：谱面文件 id → 基础曲号。
  /// 与 [baseSongId] 完全等价，供 `songId ↔ chartFileId` 成对书写。
  static int? songIdFromChartFileId(int? chartFileId) =>
      baseSongId(chartFileId);

  /// 基础曲号 → 谱面文件 id：DX 加 10000，ST 与宴谱原样。
  ///
  /// ⚠️ 基础曲号超过 9999 后与「已转换的 DX id」在数值上重叠
  /// （如 12025 既是曲号，也落在 DX 区间），光看数字分不出来：
  /// 已经拿到谱面文件 id / shortid 的调用方不要用本方法；明确知道
  /// 「这是基础曲号 + 类型」时用这里并显式传 [kind]。
  ///
  /// - DX 的基础曲号必须显式传 [AwmcChartKind.dx] 才会加偏移；
  /// - 传入已经是 5 位数的谱面文件 id（如 11209）时原样返回，重复调用幂等；
  /// - 省略 [kind] 时只做补偏移，类型按数值区间推断。
  ///
  /// 非法 songId 返回 null。
  static int? chartFileIdFromSongId(int? songId, {AwmcChartKind? kind}) {
    if (!isValidChartFileId(songId)) return null;
    final id = songId!;
    final target = kind ?? kindOfChartFileId(id)!;
    if (target == AwmcChartKind.dx && id < dxOffset) {
      return id + dxOffset;
    }
    return id;
  }

  /// 「确定是基础曲号」时的转换：DX 无条件加 10000（含 12025 这类
  /// 数字上落在 DX 区间的新曲号），ST 与宴谱原样。
  ///
  /// 与 [chartFileIdFromSongId] 的区别只有一点：这个方法不做幂等猜测，
  /// 传入已转换的 DX id 会被再加一次，所以只能喂基础曲号。
  static int? chartFileIdOfBaseSong(int? baseSongId, AwmcChartKind kind) {
    if (!isValidChartFileId(baseSongId)) return null;
    final id = baseSongId!;
    return kind == AwmcChartKind.dx ? id + dxOffset : id;
  }

  /// ST / DX 孪生谱面的谱面文件 id：ST 加 10000，DX 减 10000。
  ///
  /// 同一首歌的 ST / DX 共用曲绘，主曲绘缺图时可以拿孪生 id 再试一次。
  /// 宴谱没有孪生关系，返回 null；非法 id 也返回 null。
  static int? twinChartFileId(int? chartFileId) {
    final kind = kindOfChartFileId(chartFileId);
    return switch (kind) {
      AwmcChartKind.standard => chartFileId! + dxOffset,
      AwmcChartKind.dx => chartFileId! - dxOffset,
      AwmcChartKind.utage || null => null,
    };
  }

  /// 曲绘缺图时按顺序尝试的 id：自身在前，其次是 ST / DX 孪生 id；
  /// 宴谱只有自身。非法 id 返回空列表。
  static List<int> coverFallbackIds(int? chartFileId) {
    final kind = kindOfChartFileId(chartFileId);
    if (kind == null) return const [];
    final id = chartFileId!;
    final twin = twinChartFileId(id);
    return twin == null ? [id] : [id, twin];
  }
}

/// AWMC 谱面类型，数值区间见 [AwmcIdMap] 的库级说明。
enum AwmcChartKind {
  /// 标准谱（shortid 1–9999）。
  standard,

  /// DX 谱（shortid 10000–99999）。
  dx,

  /// 宴谱（shortid ≥ 100000）。
  utage,
}
