import 'ChartDifficulty.dart';

/// 单值或两端都包含的定数区间；空输入由筛选器处理。
class DifficultyConstantRange {
  final double minimum;
  final double maximum;

  const DifficultyConstantRange._(this.minimum, this.maximum);

  factory DifficultyConstantRange.parse(String input) {
    final normalized = String.fromCharCodes(input.runes.map(
            (code) => code >= 0xff10 && code <= 0xff19 ? code - 0xfee0 : code))
        .replaceAll('．', '.')
        .replaceAll(RegExp(r'[‐‑‒–—−－~～〜至]'), '-')
        .trim();
    final match =
        RegExp(r'^(\d+(?:\.\d+)?|\.\d+)\s*(?:-\s*(\d+(?:\.\d+)?|\.\d+))?$')
            .firstMatch(normalized);
    if (match == null) {
      throw const FormatException('请输入单值或完整区间，如 13.7 或 13.4-14');
    }
    final minimum = double.parse(match.group(1)!);
    final maximum = double.parse(match.group(2) ?? match.group(1)!);
    if (!minimum.isFinite ||
        !maximum.isFinite ||
        minimum <= 0 ||
        maximum <= 0) {
      throw const FormatException('定数必须是大于 0 的有限数字');
    }
    if (minimum > maximum) {
      throw const FormatException('区间下限不能大于上限');
    }
    return DifficultyConstantRange._(minimum, maximum);
  }

  bool contains(num value) =>
      value.isFinite && value > 0 && value >= minimum && value <= maximum;
}

/// 同一首歌内，多项普通难度必须全部满足；宴谱按实际的 0/1 等索引匹配。
/// 解析结果不可变，可直接作为一次异步搜索使用的条件快照。
class DifficultyConstantFilter {
  final Map<int, DifficultyConstantRange> ranges;
  final Map<int, String> errors;
  final Set<int> activeDifficulties;

  DifficultyConstantFilter._(this.ranges, this.errors, this.activeDifficulties);

  factory DifficultyConstantFilter.fromInputs(Map<int, String> inputs) {
    final ranges = <int, DifficultyConstantRange>{};
    final errors = <int, String>{};
    final active = <int>{};
    for (final entry in inputs.entries) {
      if (entry.value.trim().isEmpty) continue;
      active.add(entry.key);
      if (!ChartDifficulty.isValid(entry.key)) {
        errors[entry.key] = '未知难度';
        continue;
      }
      try {
        ranges[entry.key] = DifficultyConstantRange.parse(entry.value);
      } on FormatException catch (error) {
        errors[entry.key] = error.message;
      }
    }
    if (active.contains(ChartDifficulty.utage) &&
        active.any(ChartDifficulty.isStandard)) {
      errors[ChartDifficulty.utage] = 'UTAGE 不能与普通难度同时填写';
    }
    return DifficultyConstantFilter._(
      Map.unmodifiable(ranges),
      Map.unmodifiable(errors),
      Set.unmodifiable(active),
    );
  }

  bool get hasInput => activeDifficulties.isNotEmpty;
  bool get isValid => errors.isEmpty;
  bool get hasStandardInput =>
      activeDifficulties.any(ChartDifficulty.isStandard);
  bool get hasUtageInput => activeDifficulties.contains(ChartDifficulty.utage);

  bool matches(List<num> constants,
      {required int chartCount, required bool isUtage}) {
    if (!isValid) return false;
    if (!hasInput) return true;
    if (hasUtageInput) {
      return isUtage &&
          matchingChartIndices(constants, chartCount: chartCount, isUtage: true)
              .isNotEmpty;
    }
    if (isUtage) return false;
    return ranges.entries.every((entry) =>
        entry.key < chartCount &&
        entry.key < constants.length &&
        entry.value.contains(constants[entry.key]));
  }

  /// 仅返回实际存在且命中区间的谱面，用于结果中的匹配说明。
  Iterable<int> matchingChartIndices(List<num> constants,
      {required int chartCount, required bool isUtage}) sync* {
    if (!isValid || !hasInput || isUtage != hasUtageInput) return;
    if (isUtage) {
      final range = ranges[ChartDifficulty.utage]!;
      for (var i = 0; i < constants.length && i < chartCount; i++) {
        if (range.contains(constants[i])) yield i;
      }
    } else {
      for (final entry in ranges.entries) {
        if (entry.key < constants.length &&
            entry.key < chartCount &&
            entry.value.contains(constants[entry.key])) yield entry.key;
      }
    }
  }
}
