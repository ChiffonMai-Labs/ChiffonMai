import 'dart:math' as math;

import 'package:simai_flutter/simai_flutter.dart' show MaiChart, SimaiConvert;

typedef ChartBpmSegment = ({
  double bpm,
  double startSeconds,
  double endSeconds,
});

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

  /// 使用播放器的时间节点，区间以谱面时间为准。
  static List<ChartBpmSegment> parseTimeline(String inote) =>
      timelineForChart(SimaiConvert.deserialize(inote));

  static List<ChartBpmSegment> timelineForChart(MaiChart chart) {
    final finish = chart.finishTiming;
    if (finish == null || !finish.isFinite || finish <= 0) return const [];

    final changes = chart.timingChanges;
    final segments = <ChartBpmSegment>[];
    for (var i = 0; i < changes.length; i++) {
      final change = changes[i];
      final start = change.time;
      final end = i + 1 < changes.length
          ? math.min(changes[i + 1].time, finish)
          : finish;
      if (!start.isFinite || !end.isFinite || start < 0) return const [];
      if (start >= finish || end <= start) continue;
      final bpm = change.tempo;
      if (!bpm.isFinite || bpm <= 0) return const [];
      final previous = segments.lastOrNull;
      if (previous != null &&
          previous.endSeconds == start &&
          previous.bpm == bpm) {
        segments[segments.length - 1] = (
          bpm: bpm,
          startSeconds: previous.startSeconds,
          endSeconds: end,
        );
      } else {
        segments.add((bpm: bpm, startSeconds: start, endSeconds: end));
      }
    }
    return segments;
  }

  bool get hasChanges => values.length > 1;
  int get changeCount => values.isEmpty ? 0 : values.length - 1;
}
