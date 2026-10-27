import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcMusicUtil.dart';

/// AWMC `POST /v1/user/music`（查询全部成绩）的响应实体。
///
/// 实测响应结构（2026-09 用调试二维码实测，4 Token/次）：
/// ```json
/// {
///   "returnCode": 1,
///   "businessData": {
///     "userId": 11728057,
///     "nextIndex": 0,
///     "userMusicList": [
///       {
///         "userMusicDetailList": [
///           {"musicId": 11663, "level": 3, "playCount": 51,
///            "achievement": 990195, "comboStatus": 0, "syncStatus": 5,
///            "deluxscoreMax": 3065, "scoreRank": 10,
///            "extNum1": 0, "extNum2": 0}
///         ],
///         "length": 1
///       }
///     ]
///   }
/// }
/// ```
///
/// 几个必须记住的口径（写错了不会报错，只会静默显示错数据）：
///   * `musicId` 与**水鱼 songId 对齐**（宴会场是 6 位 id，如 100018）；
///   * `level`：0 BASIC / 1 ADVANCED / 2 EXPERT / 3 MASTER / 4 Re:MASTER /
///     **10 宴会场**（不是 5）；
///   * `achievement` 是**乘了 10000 的整数**（`990195` → 99.0195%），
///     宴会场可以超过 1010000（内部多张子谱相加）；
///   * `deluxscoreMax` 就是 DX 分数（**全小写 s**，不是 `deluxScoreMax`）；
///   * `comboStatus` 0–4 → none/fc/fcp/ap/app；`syncStatus` 0–5 →
///     none/fs/fsp/fsd/fsdp/sync。
///
/// 解析一律**容错**：认不出来的部分留空/置 0，绝不抛异常——
/// 这类查询失败不该让上层页面崩掉。
class AwmcUserMusicResponse {
  /// 机台账号 id（同一二维码固定）。
  final int userId;

  /// 上游分页游标；实测全量返回时为 0（本 App 不做翻页，仅记录）。
  final int nextIndex;

  final List<AwmcUserMusicChunk> chunks;

  const AwmcUserMusicResponse({
    this.userId = 0,
    this.nextIndex = 0,
    this.chunks = const [],
  });

  /// 从网关响应的 `businessData` 解析（兼容直接给数组 / 各种字段命名）。
  factory AwmcUserMusicResponse.fromBusinessData(dynamic businessData) {
    if (businessData == null) return const AwmcUserMusicResponse();
    if (businessData is List) {
      return AwmcUserMusicResponse(
        chunks: [
          AwmcUserMusicChunk(records: AwmcUserMusicRecord.listFrom(businessData)),
        ],
      );
    }
    if (businessData is! Map) return const AwmcUserMusicResponse();

    final userId = AwmcMusicUtil.toInt(businessData['userId']) ?? 0;
    final nextIndex = AwmcMusicUtil.toInt(businessData['nextIndex']) ?? 0;

    // 线上形态：userMusicList 是「分组」数组，每组里再放 userMusicDetailList。
    // 兼容形态：顶层直接就是明细数组（userMusicDetailList / musicList）。
    final chunkSource = businessData['userMusicList'];
    final flatSource = businessData['userMusicDetailList'] ??
        businessData['userMusicDetail'] ??
        businessData['musicList'] ??
        businessData['list'];

    final chunks = <AwmcUserMusicChunk>[];
    if (chunkSource is List) {
      for (final item in chunkSource) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final hasNested = map.containsKey('userMusicDetailList') ||
            map.containsKey('userMusicDetail') ||
            map.containsKey('musicList') ||
            map.containsKey('list');
        chunks.add(hasNested
            ? AwmcUserMusicChunk.fromJson(map)
            : AwmcUserMusicChunk(
                records: AwmcUserMusicRecord.listFrom([map]),
              ));
      }
    } else if (flatSource is List) {
      chunks.add(
        AwmcUserMusicChunk(records: AwmcUserMusicRecord.listFrom(flatSource)),
      );
    }
    return AwmcUserMusicResponse(
      userId: userId,
      nextIndex: nextIndex,
      chunks: chunks,
    );
  }

  /// 全部成绩（把每个 chunk 里的明细摊平）。
  List<AwmcUserMusicRecord> get records =>
      [for (final c in chunks) ...c.records];

  int get recordCount => records.length;

  /// 不重复的曲目数（同一首歌的不同难度算一首）。
  int get songCount => records.map((r) => r.musicId).toSet().length;
}

/// 上游把成绩按「组」返回，每组带一个 `length`（与明细条数一致）。
class AwmcUserMusicChunk {
  final int length;
  final List<AwmcUserMusicRecord> records;

  const AwmcUserMusicChunk({this.length = 0, this.records = const []});

  factory AwmcUserMusicChunk.fromJson(Map<String, dynamic> json) {
    final raw = json['userMusicDetailList'] ??
        json['userMusicDetail'] ??
        json['musicList'] ??
        json['list'];
    return AwmcUserMusicChunk(
      length: AwmcMusicUtil.toInt(json['length']) ?? 0,
      records: AwmcUserMusicRecord.listFrom(raw),
    );
  }
}

/// 一条谱面成绩。
class AwmcUserMusicRecord {
  /// 与水鱼 songId 对齐的曲目 id。
  final int musicId;

  /// 难度：0–4（BASIC…Re:MASTER）、10（宴会场）。
  final int level;

  /// 游玩次数。
  final int playCount;

  /// 达成率 ×10000（`990195` = 99.0195%）。
  final int achievement;

  /// 0 none / 1 fc / 2 fcp / 3 ap / 4 app。
  final int comboStatus;

  /// 0 none / 1 fs / 2 fsp / 3 fsd / 4 fsdp / 5 sync。
  final int syncStatus;

  /// DX 分数。
  final int deluxscoreMax;

  /// 评级 0–13。
  final int scoreRank;

  final int extNum1;
  final int extNum2;

  const AwmcUserMusicRecord({
    required this.musicId,
    required this.level,
    this.playCount = 0,
    this.achievement = 0,
    this.comboStatus = 0,
    this.syncStatus = 0,
    this.deluxscoreMax = 0,
    this.scoreRank = 0,
    this.extNum1 = 0,
    this.extNum2 = 0,
  });

  static const List<String> comboLabels = [
    'none',
    'fc',
    'fcp',
    'ap',
    'app',
  ];

  static const List<String> syncLabels = [
    'none',
    'fs',
    'fsp',
    'fsd',
    'fsdp',
    'sync',
  ];

  /// 从任意 JSON 列表解析出成绩条目（非 Map / 缺字段的条目直接跳过该字段）。
  static List<AwmcUserMusicRecord> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    final out = <AwmcUserMusicRecord>[];
    for (final item in raw) {
      if (item is Map) {
        out.add(AwmcUserMusicRecord.fromJson(item.cast<String, dynamic>()));
      }
    }
    return out;
  }

  factory AwmcUserMusicRecord.fromJson(Map<String, dynamic> json) {
    int pick(List<String> keys) {
      for (final k in keys) {
        final v = AwmcMusicUtil.toInt(json[k]);
        if (v != null) return v;
      }
      return 0;
    }

    return AwmcUserMusicRecord(
      musicId: pick(['musicId', 'music_id', 'songId', 'song_id', 'id']),
      level: pick(['level', 'diff', 'difficulty']),
      playCount: pick(['playCount', 'play_count', 'playNum', 'play_num']),
      achievement: pick(['achievement', 'achieve', 'achievements']),
      comboStatus: pick(['comboStatus', 'combo_status']),
      syncStatus: pick(['syncStatus', 'sync_status']),
      // 实测上游用的是全小写的 deluxscoreMax
      deluxscoreMax: pick(['deluxscoreMax', 'deluxScoreMax', 'dxScore', 'dx_score']),
      scoreRank: pick(['scoreRank', 'score_rank']),
      extNum1: pick(['extNum1']),
      extNum2: pick(['extNum2']),
    );
  }

  /// 达成率百分比（如 99.0195）。
  double get achievementPercent => achievement / 10000.0;

  /// 达成率展示（保留 4 位小数，与页面其它地方一致）。
  String get achievementText => achievementPercent.toStringAsFixed(4);

  String get levelName => AwmcMusicUtil.levelName(level);

  bool get isUtage => level == AwmcMusicUtil.levelCodes['宴会场'];

  String get comboLabel => comboStatus >= 0 && comboStatus < comboLabels.length
      ? comboLabels[comboStatus]
      : 'none';

  String get syncLabel => syncStatus >= 0 && syncStatus < syncLabels.length
      ? syncLabels[syncStatus]
      : 'none';

  /// 上游 level 编号 → 本 App 的难度下标（0–4，宴会场 5）。
  ///
  /// SongInfoPage 等页面用 `diffIndex`：0 BASIC … 4 Re:MASTER，6 位 id（宴会场）
  /// 的第 6 个难度是 index 5。
  static int levelToDiffIndex(int level) =>
      level == AwmcMusicUtil.levelCodes['宴会场'] ? 5 : level;

  /// 本 App 的难度下标 → 上游 level 编号。
  static int diffIndexToLevel(int diffIndex) => diffIndex >= 5 ? 10 : diffIndex;

  @override
  String toString() =>
      'AwmcUserMusicRecord($musicId/$levelName play=$playCount '
      'ach=$achievementText% dx=$deluxscoreMax)';
}

/// 供 `AwmcApiService.comboStatuses/syncStatuses` 之外的场景复用（写接口用字符串）。
const List<String> kAwmcComboStatuses = AwmcUserMusicRecord.comboLabels;
const List<String> kAwmcSyncStatuses = AwmcUserMusicRecord.syncLabels;

/// 便捷判断：该字符串是否是合法的 combo/sync 状态（写入前的校验用）。
bool isAwmcComboStatus(String value) =>
    AwmcApiService.comboStatuses.contains(value);
