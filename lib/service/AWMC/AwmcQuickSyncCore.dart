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

  bool get isUtage => songId >= 100000;
  String get type => isUtage ? 'UTAGE' : (songId >= 10000 ? 'DX' : 'SD');
  String get key => '$songId/$levelIndex/$type';
  double get percent => achievement / 10000;

  static int? _int(dynamic value) =>
      value is int ? value : int.tryParse('$value');

  static int? _normalizeLevel(int songId, int? rawLevel) {
    if (rawLevel == null) return null;
    if (songId >= 100000 && rawLevel == 10) return 0;
    return ChartDifficulty.isStandard(rawLevel) ? rawLevel : null;
  }

  static List<AwmcQuickScore> parse(dynamic businessData) {
    final result = <AwmcQuickScore>[];
    void visit(dynamic value, [int? parentSongId]) {
      if (value is List) {
        for (final item in value) {
          visit(item, parentSongId);
        }
      } else if (value is Map) {
        final id = _int(value['musicId'] ?? value['song_id']) ?? parentSongId;
        final rawLevel = _int(value['level'] ?? value['level_index']);
        final level = id == null ? null : _normalizeLevel(id, rawLevel);
        final achievement = _int(value['achievement']);
        final dx = _int(value['deluxscoreMax'] ?? value['dxScore']);
        final maxAch = (id != null && id >= 100000) ? 2020000 : 1010000;
        if (id != null &&
            id > 0 &&
            level != null &&
            achievement != null &&
            achievement > 0 &&
            achievement <= maxAch &&
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
    final maxPercent = isUtage ? 202 : 101;
    if (percent == null ||
        percent < 0 ||
        percent > maxPercent ||
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
      final rawLevel = _int(raw['level_index']);
      if (id == null || rawLevel == null) continue;
      final rawType = '${raw['type'] ?? ''}'.trim().toUpperCase();
      final genre = '${raw['genre'] ?? ''}'.trim();
      final isUtage = id >= 100000 ||
          rawType == 'UTAGE' ||
          rawType == 'UTAGE2P' ||
          genre == '宴会場' ||
          genre == '宴会场';
      final level = isUtage && rawLevel == 10 ? 0 : rawLevel;
      final type = isUtage
          ? 'UTAGE'
          : (rawType.isNotEmpty ? rawType : (id >= 10000 ? 'DX' : 'SD'));
      result['$id/$level/$type'] = raw;
    }
    return result;
  }

  /// 调用方只能传入本次目标账号的成绩快照，不接受跨数据源的共享活动槽。
  ///
  /// 合并时保留目标源已有 FC/FS 标记，并对达成率与 DX 分取最大值，
  /// 避免 rival 偶发返回低分或旧数据时反向覆盖目标已有更高记录。
  static List<AwmcQuickScore> backfill(
      List<AwmcQuickScore> incoming, List<dynamic> targetRecords) {
    final badges = indexTargets(targetRecords);
    return incoming.map((score) {
      final old = badges[score.key];
      var achievement = score.achievement;
      var dxScore = score.dxScore;
      final maxPercent = score.isUtage ? 202 : 101;
      if (old != null) {
        final oldPercent = _number(old['achievements']);
        if (oldPercent != null && oldPercent >= 0 && oldPercent <= maxPercent) {
          final oldAch = (oldPercent * 10000).round();
          if (oldAch > achievement) achievement = oldAch;
        }
        final oldDx = _number(old['dxScore'] ?? old['dx_score']);
        if (oldDx != null && oldDx >= 0 && oldDx == oldDx.round()) {
          final oldDxInt = oldDx.toInt();
          if (oldDxInt > dxScore) dxScore = oldDxInt;
        }
      }
      return AwmcQuickScore(score.songId, score.levelIndex, achievement, dxScore,
          fc: score.fc ?? _badge(old?['fc'], false),
          fs: score.fs ?? _badge(old?['fs'], true));
    }).toList();
  }
}
