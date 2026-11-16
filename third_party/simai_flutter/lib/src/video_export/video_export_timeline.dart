import 'dart:math';

import '../structures/mai_chart.dart';
import '../structures/note_type.dart';

const double simaiHitSoundBaseOffsetSeconds = -0.17;
const double simaiHitSoundDurationSeconds = 17869 / 48000;

class SimaiVideoTimeline {
  final double chartStart;
  final double chartEnd;
  final int frameCount;

  const SimaiVideoTimeline({
    required this.chartStart,
    required this.chartEnd,
    required this.frameCount,
  });

  double get duration => max(0, chartEnd - chartStart);

  int get durationUs => (duration * 1000000).ceil();

  double chartTimeForFrame(int frameIndex) => chartStart + frameIndex / 60.0;

  int presentationTimeUsForFrame(int frameIndex) => frameIndex * 1000000 ~/ 60;

  factory SimaiVideoTimeline.calculate({
    required double visualEnd,
    required double musicOffset,
    required double audioDuration,
    required List<int> hitEventTimesUs,
    required bool includeMusic,
    required bool includeHitSounds,
  }) {
    final start = min(0.0, includeMusic ? musicOffset : 0.0);
    double end = max(visualEnd, 0.0);
    if (includeMusic) {
      end = max(end, musicOffset + audioDuration);
    }
    if (includeHitSounds && hitEventTimesUs.isNotEmpty) {
      end = max(
        end,
        hitEventTimesUs.last / 1000000.0 + simaiHitSoundDurationSeconds,
      );
    }
    final duration = max(0.0, end - start);
    return SimaiVideoTimeline(
      chartStart: start,
      chartEnd: end,
      frameCount: (duration * 60).ceil(),
    );
  }
}

List<int> buildSimaiHitSoundEventTimesUs(
  MaiChart chart, {
  required int userOffsetMs,
}) {
  final offsetSeconds = simaiHitSoundBaseOffsetSeconds + userOffsetMs / 1000.0;
  final events = <int>{};
  for (final collection in chart.noteCollections) {
    events.add(((collection.time + offsetSeconds) * 1000000).round());
    for (final note in collection) {
      if (note.type != NoteType.hold) continue;
      final length = note.length ?? 0;
      if (length <= 0) continue;
      events.add(
        ((collection.time + length + offsetSeconds) * 1000000).round(),
      );
    }
  }
  return events.toList()..sort();
}
