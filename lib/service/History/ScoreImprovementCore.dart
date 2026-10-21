import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import '../../utils/StringUtil.dart';

/// 完整成绩快照；未知字段保留 null，避免把缺失值当作零分或未达成。
class ImprovementScore {
  ImprovementScore(this.data);

  final Map<String, dynamic> data;
  int get songId => data['song_id'] as int;
  int get levelIndex => data['level_index'] as int;
  String get type => data['type'] as String;
  String get title => data['title'] as String;
  String get level => data['level'] as String;
  double get ds => (data['ds'] as num).toDouble();
  double get achievement => (data['achievements'] as num).toDouble();
  int? get dxScore => data['dxScore'] as int?;
  int? get rating => data['ra'] as int?;
  String? get fc => data['fc'] as String?;
  String? get fs => data['fs'] as String?;
  String get rate => data['rate'] as String;
  int get maxDxScore => data['maxDxScore'] as int;
  bool get isUtage => type == ChartDifficulty.utageLabel || songId.toString().length == 6;
  String get key => '$songId/$levelIndex/$type';
  double? get dxRate =>
      maxDxScore > 0 && dxScore != null ? dxScore! / maxDxScore : null;
  String? get stars => maxDxScore > 0 && dxScore != null
      ? StringUtil.formatStars(dxScore! / maxDxScore)
      : null;

  static ImprovementScore? parse(dynamic raw, {int? maxDxScore}) {
    if (raw is! Map) return null;
    num? number(dynamic value) => num.tryParse('$value');
    String? badge(dynamic value) => value == null
        ? null
        : value.toString().trim().toLowerCase().replaceAll('+', 'p');
    final id = number(raw['song_id'])?.toInt();
    final index = number(raw['level_index'])?.toInt();
    final achievement = number(raw['achievements'])?.toDouble();
    if (id == null ||
        id <= 0 ||
        index == null ||
        index < 0 ||
        index > 5 ||
        achievement == null ||
        !achievement.isFinite ||
        achievement <= 0 ||
        achievement > 202) return null;
    var type = '${raw['type'] ?? 'SD'}'.toUpperCase();
    if (type == 'STANDARD' || type == 'ST') type = 'SD';
    if (id.toString().length == 6) type = ChartDifficulty.utageLabel;
    final ds = number(raw['ds'])?.toDouble() ?? 0;
    final roundedAchievement = double.parse(achievement.toStringAsFixed(4));
    return ImprovementScore({
      'song_id': id,
      'level_index': index,
      'type': type,
      'title': '${raw['title'] ?? '未知歌曲'}',
      'level': '${raw['level'] ?? ''}',
      'ds': ds.isFinite ? ds : 0.0,
      'achievements': roundedAchievement,
      'dxScore': number(raw['dxScore'])?.toInt(),
      'fc': badge(raw['fc']),
      'fs': badge(raw['fs']),
      'ra': type == ChartDifficulty.utageLabel ? 0 : number(raw['ra'])?.toInt(),
      'rate': StringUtil.rateCodeFromAchievement(roundedAchievement),
      'maxDxScore': maxDxScore ?? number(raw['maxDxScore'])?.toInt() ?? 0,
    });
  }

  static Map<String, ImprovementScore> records(dynamic raw,
      {Map<String, int> maxScores = const {}}) {
    final result = <String, ImprovementScore>{};
    if (raw is! List) return result;
    for (final item in raw) {
      final score = parse(item,
          maxDxScore: item is Map
              ? maxScores['${item['song_id']}/${item['level_index']}']
              : null);
      if (score == null) continue;
      final old = result[score.key];
      if (old == null ||
          score.achievement > old.achievement ||
          (score.achievement == old.achievement &&
              (score.dxScore ?? 0) > (old.dxScore ?? 0))) {
        result[score.key] = score;
      }
    }
    return result;
  }
}

enum ImprovementMetric {
  achievement('达成率'),
  rating('Rating'),
  rate('评级'),
  stars('星数'),
  dxScore('DX分数'),
  dxRate('DX分数达成率'),
  fc('连击'),
  fs('同步');

  const ImprovementMetric(this.label);
  final String label;

  Object? value(ImprovementScore score) => switch (this) {
        achievement => (score.achievement * 10000).round(),
        dxScore => score.dxScore,
        rate => score.rate,
        fc => score.fc,
        fs => score.fs,
        stars => score.stars,
        dxRate => score.dxRate,
        rating => score.rating,
      };

  String display(ImprovementScore? score) {
    if (score == null) return '未记录';
    final v = value(score);
    if (v == null) return '—';
    return switch (this) {
      achievement => '${score.achievement.toStringAsFixed(4)}%',
      rate => StringUtil.formatRate(score.rate),
      fc => v == '' ? '无' : StringUtil.formatFC('$v'),
      fs => v == '' ? '无' : StringUtil.formatFS('$v'),
      dxRate => '${(score.dxRate! * 100).toStringAsFixed(2)}%',
      _ => '$v',
    };
  }

  int compare(ImprovementScore before, ImprovementScore after) {
    final a = value(before), b = value(after);
    if (a == null || b == null || a == b) return 0;
    if (this == dxRate) return (b as double).compareTo(a as double);
    int rank(Object v) => switch (this) {
          rate => const [
              'd',
              'c',
              'b',
              'bb',
              'bbb',
              'a',
              'aa',
              'aaa',
              's',
              'sp',
              'ss',
              'ssp',
              'sss',
              'sssp'
            ].indexOf('$v'),
          fc => const ['', 'fc', 'fcp', 'ap', 'app'].indexOf('$v'),
          fs => const ['', 'sync', 'fs', 'fsp', 'fsd', 'fsdp'].indexOf('$v'),
          stars =>
            ((double.tryParse('$v'.replaceAll('✦', '')) ?? 0) * 2).round(),
          _ => (v as num).toInt(),
        };
    return rank(b).compareTo(rank(a));
  }
}

enum ScoreChangeStatus {
  improvement('成绩提升'),
  regression('成绩回退'),
  unchanged('成绩无变化'),
  mixed('成绩变化');

  const ScoreChangeStatus(this.label);
  final String label;
}

/// 同日同谱面的聚合：保留第一次变化前与最后一次变化后的完整值。
class DailyScoreImprovement {
  const DailyScoreImprovement({
    required this.day,
    required this.before,
    required this.after,
    required this.firstAtMs,
    required this.lastAtMs,
    this.changeCount = 1,
  });

  final String day;
  final ImprovementScore? before;
  final ImprovementScore after;
  final int firstAtMs;
  final int lastAtMs;
  final int changeCount;
  bool get isNewChart => before == null;
  bool get hasImprovement =>
      before == null ||
      ImprovementMetric.values.any((m) => m.compare(before!, after) > 0);
  bool get hasRegression =>
      before != null &&
      ImprovementMetric.values.any((m) => m.compare(before!, after) < 0);
  ScoreChangeStatus get status {
    final improved = hasImprovement;
    final regressed = hasRegression;
    if (improved && regressed) return ScoreChangeStatus.mixed;
    if (improved) return ScoreChangeStatus.improvement;
    if (regressed) return ScoreChangeStatus.regression;
    return ScoreChangeStatus.unchanged;
  }

  bool changed(ImprovementMetric metric) =>
      before == null ||
      (metric.value(before!) != null &&
          metric.value(after) != null &&
          metric.value(before!) != metric.value(after));

  DailyScoreImprovement append(ImprovementScore score, int at) =>
      DailyScoreImprovement(
          day: day,
          before: before,
          after: score,
          firstAtMs: firstAtMs,
          lastAtMs: at,
          changeCount: changeCount + 1);

  Map<String, dynamic> toJson() => {
        'day': day,
        'before': before?.data,
        'after': after.data,
        'firstAt': firstAtMs,
        'lastAt': lastAtMs,
        'count': changeCount,
      };

  static DailyScoreImprovement? parse(dynamic raw) {
    if (raw is! Map) return null;
    final score = ImprovementScore.parse(raw['after']);
    if (score == null ||
        raw['day'] is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw['day']) ||
        raw['firstAt'] is! num ||
        raw['lastAt'] is! num) return null;
    return DailyScoreImprovement(
      day: raw['day'],
      before: ImprovementScore.parse(raw['before']),
      after: score,
      firstAtMs: (raw['firstAt'] as num).toInt(),
      lastAtMs: (raw['lastAt'] as num).toInt(),
      changeCount: (raw['count'] as num?)?.toInt() ?? 1,
    );
  }
}

class ScoreImprovementHistory {
  int startedAtMs = 0;
  final Map<String, ImprovementScore> current = {};
  final Map<String, DailyScoreImprovement> daily = {};

  /// 空响应不清基线；缺失的谱面也保留，避免下次出现时被当作首次游玩。
  void record(dynamic records,
      {required int atMs,
      dynamic previousRecords,
      Map<String, int> maxScores = const {}}) {
    final incoming = ImprovementScore.records(records, maxScores: maxScores);
    if (incoming.isEmpty) return;
    if (startedAtMs == 0) {
      startedAtMs = atMs;
      current.addAll(
          ImprovementScore.records(previousRecords, maxScores: maxScores));
      if (current.isEmpty) {
        current.addAll(incoming);
        return;
      }
    }
    final date = DateTime.fromMillisecondsSinceEpoch(atMs);
    String two(int v) => v.toString().padLeft(2, '0');
    // 分组日期在采集时冻结，之后切时区不会把旧记录挪到另一天。
    final day = '${date.year}-${two(date.month)}-${two(date.day)}';
    for (final entry in incoming.entries) {
      final old = current[entry.key];
      final score = entry.value;
      final changed = old == null ||
          ImprovementMetric.values.any((metric) {
            // 星数取决于曲库物量，Rating 也可能只因定数修订而变化。
            if (metric == ImprovementMetric.stars ||
                metric == ImprovementMetric.dxRate) return false;
            if (metric == ImprovementMetric.rating && old!.ds != score.ds)
              return false;
            return old != null &&
                metric.value(old) != null &&
                metric.value(score) != null &&
                metric.value(old) != metric.value(score);
          });
      current[entry.key] = score;
      if (!changed) continue;
      final key = '$day/${entry.key}';
      daily[key] = daily[key]?.append(score, atMs) ??
          DailyScoreImprovement(
            day: day,
            before: old,
            after: score,
            firstAtMs: atMs,
            lastAtMs: atMs,
          );
    }
  }

  Map<String, dynamic> toJson() => {
        'startedAt': startedAtMs,
        'current': {for (final e in current.entries) e.key: e.value.data},
        'daily': daily.values.map((e) => e.toJson()).toList(),
      };

  static ScoreImprovementHistory fromJson(dynamic raw) {
    final history = ScoreImprovementHistory();
    if (raw is! Map) return history;
    history.startedAtMs = (raw['startedAt'] as num?)?.toInt() ?? 0;
    if (raw['current'] is Map) {
      for (final item in (raw['current'] as Map).values) {
        final score = ImprovementScore.parse(item);
        if (score != null) history.current[score.key] = score;
      }
    }
    if (raw['daily'] is List) {
      for (final item in raw['daily']) {
        final event = DailyScoreImprovement.parse(item);
        if (event != null)
          history.daily['${event.day}/${event.after.key}'] = event;
      }
    }
    return history;
  }
}
