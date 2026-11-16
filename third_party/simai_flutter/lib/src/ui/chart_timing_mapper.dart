import '../internal/syntactic_analysis/timing_change.dart';
import '../structures/mai_chart.dart';

/// Fast conversions between chart seconds and musical beats.
///
/// Timing data is compiled once per chart. Call [invalidate] after mutating an
/// existing chart's timing changes in place.
class ChartTimingMapper {
  static final Expando<_ChartTimingIndex> _indexes = Expando<_ChartTimingIndex>(
    'chart timing index',
  );

  static TimingChange timingAtTime(MaiChart chart, double time) {
    final index = _indexFor(chart);
    final segment = index.segmentAtTime(time.isFinite ? time : 0.0);
    return TimingChange(
      time: index.times[segment],
      tempo: index.tempos[segment],
      subdivisions: index.subdivisions[segment],
    );
  }

  static double beatsAtTime(MaiChart chart, double time) {
    final t = time.isFinite ? time : 0.0;
    if (t <= 0) return 0.0;
    final index = _indexFor(chart);
    final segment = index.segmentAtTime(t);
    return index.beatsAtStart[segment] +
        (t - index.times[segment]) * index.tempos[segment] / 60.0;
  }

  static double timeAtBeats(MaiChart chart, double beats) {
    final target = beats.isFinite ? beats : 0.0;
    if (target <= 0) return 0.0;
    final index = _indexFor(chart);
    final segment = index.segmentAtBeats(target);
    return index.times[segment] +
        (target - index.beatsAtStart[segment]) * 60.0 / index.tempos[segment];
  }

  static void invalidate(MaiChart chart) {
    _indexes[chart] = null;
  }

  static _ChartTimingIndex _indexFor(MaiChart chart) {
    final cached = _indexes[chart];
    if (cached != null && cached.matches(chart)) return cached;
    return _indexes[chart] = _ChartTimingIndex.build(chart);
  }
}

class _ChartTimingIndex {
  final List<TimingChange> source;
  final int sourceLength;
  final TimingChange? sourceFirst;
  final TimingChange? sourceLast;
  final List<double> times;
  final List<double> tempos;
  final List<double> subdivisions;
  final List<double> beatsAtStart;

  const _ChartTimingIndex({
    required this.source,
    required this.sourceLength,
    required this.sourceFirst,
    required this.sourceLast,
    required this.times,
    required this.tempos,
    required this.subdivisions,
    required this.beatsAtStart,
  });

  factory _ChartTimingIndex.build(MaiChart chart) {
    final source = chart.timingChanges;
    final changes = List<TimingChange>.of(source)
      ..sort((a, b) => a.time.compareTo(b.time));
    final fallbackTempo = changes.isNotEmpty && changes.first.tempo > 0
        ? changes.first.tempo
        : 120.0;

    final times = <double>[];
    final tempos = <double>[];
    final subdivisions = <double>[];
    if (changes.isEmpty || changes.first.time > 0.0) {
      times.add(0.0);
      tempos.add(fallbackTempo);
      subdivisions.add(4.0);
    }
    for (final change in changes) {
      final time = change.time < 0.0 ? 0.0 : change.time;
      final tempo = change.tempo > 0 ? change.tempo : 120.0;
      final subdivision = change.subdivisions > 0 ? change.subdivisions : 4.0;
      // For multiple changes at the same instant, the last one wins.
      if (times.isNotEmpty && times.last == time) {
        tempos[tempos.length - 1] = tempo;
        subdivisions[subdivisions.length - 1] = subdivision;
      } else {
        times.add(time);
        tempos.add(tempo);
        subdivisions.add(subdivision);
      }
    }
    if (times.isEmpty) {
      times.add(0.0);
      tempos.add(120.0);
      subdivisions.add(4.0);
    }

    final beatsAtStart = List<double>.filled(times.length, 0.0);
    for (int i = 1; i < times.length; i++) {
      beatsAtStart[i] =
          beatsAtStart[i - 1] +
          (times[i] - times[i - 1]) * tempos[i - 1] / 60.0;
    }
    return _ChartTimingIndex(
      source: source,
      sourceLength: source.length,
      sourceFirst: source.isEmpty ? null : source.first,
      sourceLast: source.isEmpty ? null : source.last,
      times: List.unmodifiable(times),
      tempos: List.unmodifiable(tempos),
      subdivisions: List.unmodifiable(subdivisions),
      beatsAtStart: List.unmodifiable(beatsAtStart),
    );
  }

  bool matches(MaiChart chart) {
    final current = chart.timingChanges;
    return identical(source, current) &&
        current.length == sourceLength &&
        (current.isEmpty ||
            (identical(current.first, sourceFirst) &&
                identical(current.last, sourceLast)));
  }

  int segmentAtTime(double value) => _lastAtOrBefore(times, value);

  int segmentAtBeats(double value) => _lastAtOrBefore(beatsAtStart, value);

  static int _lastAtOrBefore(List<double> values, double target) {
    int low = 0;
    int high = values.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (values[mid] <= target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return (low - 1).clamp(0, values.length - 1);
  }
}
