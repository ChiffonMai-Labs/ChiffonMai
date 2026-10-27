import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';

/// AWMC 成绩数据的解析/规整工具。
///
/// 上游 `businessData` 的字段命名在各接口间并不完全统一
/// （我们只能从文档与实测响应里推断），因此这里的解析**必须容错**：
/// 拿不到就返回空列表，让 UI 退化成「展示原始 JSON」，
/// 绝不能因为猜错字段名而误判成「该成绩不存在」——那会导致用户
/// 以为没成绩而重复上传，或以为有成绩而做错删除决策。
class AwmcMusicUtil {
  AwmcMusicUtil._();

  /// 上游 level 编号 → 可读难度名（官方文档 3.4）。
  static const Map<int, String> levelNames = ChartDifficulty.awmcLevelNames;

  /// 可读难度名 → 上游 level 编号。
  static const Map<String, int> levelCodes = ChartDifficulty.awmcLevelCodes;

  static String levelName(dynamic level) {
    final code = toInt(level);
    if (code == null) return level?.toString() ?? '?';
    return levelNames[code] ?? 'level=$code';
  }

  static int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  /// 从任意 `businessData` 里尽力取出「成绩条目列表」。
  ///
  /// 依次尝试：直接就是数组 / 常见 key（musicList、musicData、music、list、
  /// data、scores）/ 这些 key 里再套一层 Map。
  static List<Map<String, dynamic>> extractEntries(dynamic businessData) {
    if (businessData is List) {
      return _asMapList(businessData);
    }
    if (businessData is Map) {
      const candidateKeys = [
        'musicList',
        'musicData',
        'music',
        'list',
        'data',
        'scores',
        'items',
      ];
      for (final key in candidateKeys) {
        final v = businessData[key];
        if (v is List) return _asMapList(v);
        if (v is Map) {
          for (final inner in candidateKeys) {
            final innerV = v[inner];
            if (innerV is List) return _asMapList(innerV);
          }
        }
      }
    }
    return const [];
  }

  static List<Map<String, dynamic>> _asMapList(List<dynamic> raw) => raw
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList(growable: false);

  /// 条目所属的曲目 ID（各接口字段名可能是 musicId / id / songId）。
  static String? entryMusicId(Map<String, dynamic> entry) {
    for (final key in ['musicId', 'music_id', 'id', 'songId', 'song_id']) {
      final v = entry[key];
      if (v != null) return normalizeMusicId(v);
    }
    return null;
  }

  static int? entryLevel(Map<String, dynamic> entry) {
    for (final key in ['level', 'diff', 'difficulty']) {
      final v = entry[key];
      if (v != null) {
        final code = toInt(v);
        if (code != null) return code;
        final byName = levelCodes[v.toString()];
        if (byName != null) return byName;
      }
    }
    return null;
  }

  /// 曲目 ID 归一化：去掉前导零，便于用户输入 `001000` 与 `1000` 都能匹配。
  static String normalizeMusicId(dynamic id) {
    final text = id?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return text;
    final stripped = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    return stripped;
  }

  /// 在条目列表中查找指定曲目 + 难度的现有成绩（找不到返回 null）。
  static Map<String, dynamic>? findEntry(
    List<Map<String, dynamic>> entries,
    String musicId,
    int level,
  ) {
    final wantId = normalizeMusicId(musicId);
    for (final entry in entries) {
      if (entryMusicId(entry) == wantId && entryLevel(entry) == level) {
        return entry;
      }
    }
    return null;
  }

  /// 从现有成绩条目里取一个字段（兼容多种命名）。
  static dynamic pick(Map<String, dynamic> entry, List<String> keys) {
    for (final key in keys) {
      if (entry.containsKey(key) && entry[key] != null) return entry[key];
    }
    return null;
  }

  /// 达成率：可能是 101.0000 这种百分数，也可能是 0.0101 这种小数。
  static String formatAchievement(dynamic value) {
    final d = toDouble(value);
    if (d == null) return value?.toString() ?? '-';
    return d.toStringAsFixed(4);
  }

  /// 模糊模式（fuzzy=true）下 dxScore 是星级 0–5，不是真实 DX 分。
  static String formatDxScore(dynamic value, {required bool fuzzy}) {
    final d = toDouble(value);
    if (d == null) return value?.toString() ?? '-';
    if (fuzzy) return '★${d.toStringAsFixed(0)}（模糊）';
    return d.toStringAsFixed(0);
  }
}
