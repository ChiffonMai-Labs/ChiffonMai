import '../../utils/ChartDifficulty.dart';

/// rival 只提供达成率与 DX 分；缺少的标记保留 null，不伪造为“无”。
class AwmcQuickScore {
  final int songId;
  final int levelIndex;
  final int achievement;
  final int dxScore;
  final String? fc;
  final String? fs;
  const AwmcQuickScore(
      this.songId, this.levelIndex, this.achievement, this.dxScore,
      {this.fc, this.fs});

  String get type => songId >= 10000 ? 'DX' : 'SD';
  String get key => '$songId/$levelIndex/$type';
  double get percent => achievement / 10000;

  static int? _int(dynamic value) =>
      value is int ? value : int.tryParse('$value');

  static List<AwmcQuickScore> parse(dynamic businessData) {
    final result = <AwmcQuickScore>[];
    void visit(dynamic value, [int? parentSongId]) {
      if (value is List) {
        for (final item in value) {
          visit(item, parentSongId);
        }
      } else if (value is Map) {
        final id = _int(value['musicId'] ?? value['song_id']) ?? parentSongId;
        final level = _int(value['level'] ?? value['level_index']);
        final achievement = _int(value['achievement']);
        final dx = _int(value['deluxscoreMax'] ?? value['dxScore']);
        if (id != null &&
            id > 0 &&
            id < 100000 &&
            level != null &&
            ChartDifficulty.isStandard(level) &&
            achievement != null &&
            achievement > 0 &&
            achievement <= 1010000 &&
            dx != null &&
            dx >= 0) {
          result.add(AwmcQuickScore(id, level, achievement, dx,
              fc: _badge(value['fc'], false), fs: _badge(value['fs'], true)));
        }
        for (final entry in value.entries) {
          if (entry.value is List || entry.value is Map) visit(entry.value, id);
        }
      }
    }

    visit(businessData);
    return result;
  }

  static String? _badge(dynamic value, bool sync) {
    if (value is! String || value.trim().isEmpty) return null;
    final normalized = value.trim().toLowerCase().replaceAll('+', 'p');
    return (sync
                ? const ['fs', 'fsp', 'fsd', 'fsdp', 'sync']
                : const ['fc', 'fcp', 'ap', 'app'])
            .contains(normalized)
        ? normalized
        : null;
  }

  static num? _number(dynamic value) {
    if (value is! num && value is! String) return null;
    final number = value is num ? value : num.tryParse(value.trim());
    return number != null && number.isFinite ? number : null;
  }

  static String? _comparisonBadge(dynamic value, bool sync) {
    if (value == null) return '';
    if (value is! String) return null;
    final text = value.trim().toLowerCase();
    if (text.isEmpty || text == 'none') return '';
    return _badge(text, sync);
  }

  /// 先按目标源合并标记，再比较四项实际成绩；浮点达成率统一到万分之一百分点。
  bool matchesTarget(Map? target) {
    if (target == null ||
        !target.containsKey('fc') ||
        !target.containsKey('fs')) return false;
    final percent = _number(target['achievements']);
    final dx = _number(target['dxScore'] ?? target['dx_score']);
    if (percent == null ||
        percent < 0 ||
        percent > 101 ||
        dx == null ||
        dx < 0 ||
        dx != dx.round()) return false;
    return (percent * 10000).round() == achievement &&
        dx == dxScore &&
        _comparisonBadge(target['fc'], false) == (fc ?? '') &&
        _comparisonBadge(target['fs'], true) == (fs ?? '');
  }

  static Map<String, Map> indexTargets(List<dynamic> targetRecords) {
    final result = <String, Map>{};
    for (final raw in targetRecords) {
      if (raw is! Map) continue;
      final id = _int(raw['song_id']);
      final level = _int(raw['level_index']);
      if (id == null || level == null) continue;
      final type =
          '${raw['type'] ?? (id >= 10000 ? 'DX' : 'SD')}'.toUpperCase();
      result['$id/$level/$type'] = raw;
    }
    return result;
  }

  /// 调用方只能传入本次目标账号的成绩快照，不接受跨数据源的共享活动槽。
  static List<AwmcQuickScore> backfill(
      List<AwmcQuickScore> incoming, List<dynamic> targetRecords) {
    final badges = indexTargets(targetRecords);
    return incoming.map((score) {
      final old = badges[score.key];
      return AwmcQuickScore(
          score.songId, score.levelIndex, score.achievement, score.dxScore,
          fc: score.fc ?? _badge(old?['fc'], false),
          fs: score.fs ?? _badge(old?['fs'], true));
    }).toList();
  }
}
