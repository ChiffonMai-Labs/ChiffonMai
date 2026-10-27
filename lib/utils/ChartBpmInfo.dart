/// 谱面 BPM 的顺序信息。相邻重复标记不算变速，恢复到旧 BPM 仍算一次变化。
class ChartBpmInfo {
  final List<double> values;
  const ChartBpmInfo(this.values);

  static List<double> parse(String inote) {
    final values = <double>[];
    final source = inote.replaceAll(RegExp(r'\|\|[^\r\n]*'), '');
    for (final match in RegExp(r'\((\d+(?:\.\d+)?)\)').allMatches(source)) {
      final value = double.tryParse(match.group(1)!);
      if (value != null &&
          value.isFinite &&
          value > 0 &&
          (values.isEmpty || values.last != value)) values.add(value);
    }
    return values;
  }

  bool get hasChanges => values.length > 1;
  int get changeCount => values.isEmpty ? 0 : values.length - 1;
}
