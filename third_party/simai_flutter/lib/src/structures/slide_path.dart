import 'location.dart';
import 'slide_segment.dart';
import 'note_type.dart';
import 'note_group.dart';

class SlidePath {
  Location startLocation;
  List<SlideSegment> segments;

  /// The intro delay of a slide before it starts moving.
  double delay;

  double duration;

  NoteType type;

  SlidePath(this.segments)
    : startLocation = Location(0, NoteGroup.tap),
      delay = 0,
      duration = 0,
      type = NoteType.slide;

  void writeTo(StringBuffer writer) {
    for (var segment in segments) {
      segment.writeTo(writer, startLocation);
    }

    if (type == NoteType.breakNote) {
      writer.write('b');
    }

    writer.write(
      "[${delay.toStringAsFixed(7)}##${duration.toStringAsFixed(7)}]",
    );
  }
}
