import 'dart:math';

import '../../../simai_flutter.dart';

double computeChartContentEndTime(MaiChart chart) {
  double endTime = chart.finishTiming ?? 0.0;
  for (final collection in chart.noteCollections) {
    if (collection.time.isFinite) endTime = max(endTime, collection.time);
    for (final note in collection) {
      final holdEnd = collection.time + (note.length ?? 0.0);
      if (holdEnd.isFinite) endTime = max(endTime, holdEnd);
      for (final slide in note.slidePaths) {
        final slideEnd = collection.time + slide.delay + slide.duration;
        if (slideEnd.isFinite) endTime = max(endTime, slideEnd);
      }
    }
  }
  return endTime;
}

/// Immutable metadata used by the render loop.
///
/// Building this once avoids repeatedly walking every note and slide while a
/// chart is playing.
class ChartRuntimeIndex {
  final List<double> collectionEndTimes;
  final List<bool> collectionIsEach;
  final List<Set<int>> oppositeNoteIndices;
  final List<Map<double, int>?> slideStartCounts;

  ChartRuntimeIndex._({
    required this.collectionEndTimes,
    required this.collectionIsEach,
    required this.oppositeNoteIndices,
    required this.slideStartCounts,
  });

  factory ChartRuntimeIndex.build(MaiChart chart) {
    final endTimes = <double>[];
    final eachFlags = <bool>[];
    final opposites = <Set<int>>[];
    final startCounts = <Map<double, int>?>[];

    for (final collection in chart.noteCollections) {
      double maxDuration = 0.0;
      bool isEach =
          collection.length > 1 || collection.eachStyle == EachStyle.forEach;
      if (collection.eachStyle == EachStyle.forceBroken) isEach = false;

      final opposite = <int>{};
      final counts = <double, int>{};
      for (int i = 0; i < collection.length; i++) {
        final note = collection[i];
        maxDuration = max(maxDuration, note.length ?? 0.0);
        for (final slide in note.slidePaths) {
          maxDuration = max(maxDuration, slide.delay + slide.duration);
          final key = ((collection.time + slide.delay) * 1000).round() / 1000.0;
          counts[key] = (counts[key] ?? 0) + 1;
        }

        if (!isEach || note.location.group != NoteGroup.tap) continue;
        for (int j = i + 1; j < collection.length; j++) {
          final other = collection[j];
          if (other.location.group == NoteGroup.tap &&
              (note.location.index - other.location.index).abs() == 4) {
            opposite.add(i);
            opposite.add(j);
          }
        }
      }

      final endTime = collection.time + maxDuration;
      endTimes.add(endTimes.isEmpty ? endTime : max(endTimes.last, endTime));
      eachFlags.add(isEach);
      opposites.add(Set<int>.unmodifiable(opposite));
      startCounts.add(counts.isEmpty ? null : Map.unmodifiable(counts));
    }

    return ChartRuntimeIndex._(
      collectionEndTimes: List.unmodifiable(endTimes),
      collectionIsEach: List.unmodifiable(eachFlags),
      oppositeNoteIndices: List.unmodifiable(opposites),
      slideStartCounts: List.unmodifiable(startCounts),
    );
  }

  int firstPotentiallyVisible(double time, {double tailPadding = 0.5}) {
    final threshold = time - tailPadding;
    int low = 0;
    int high = collectionEndTimes.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (collectionEndTimes[mid] < threshold) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  int visibleEnd(MaiChart chart, double maxTime) {
    int low = 0;
    int high = chart.noteCollections.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (chart.noteCollections[mid].time <= maxTime) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}
