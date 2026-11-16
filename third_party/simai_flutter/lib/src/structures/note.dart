import 'dart:math'; // for max
import 'note_collection.dart';
import 'location.dart';
import 'note_styles.dart';
import 'note_appearance.dart';
import 'note_type.dart';
import 'slide_morph.dart';
import 'slide_path.dart';
import 'note_group.dart';

class Note {
  NoteCollection? parentCollection;

  Location location;
  int styles;
  NoteAppearance appearance;
  NoteType type;

  double? length;

  SlideMorph slideMorph;
  List<SlidePath> slidePaths;

  Note([this.parentCollection])
    : slidePaths = [],
      location = Location(0, NoteGroup.tap),
      styles = NoteStyles.none,
      appearance = NoteAppearance.defaultAppearance,
      type = NoteType.tap,
      length = null,
      slideMorph = SlideMorph.fadeIn;

  bool get isEx => (styles & NoteStyles.ex) != 0;

  /// Touch holds retain their sensor location in every zone (A/B/C/D/E).
  /// A break decorator changes [type], but does not turn them into ring notes.
  bool get isTouchHold =>
      location.group != NoteGroup.tap &&
      (type == NoteType.hold || (type == NoteType.breakNote && length != null));

  bool get isStar =>
      appearance.index >= NoteAppearance.forceStar.index ||
      (slidePaths.isNotEmpty && appearance != NoteAppearance.forceNormal);

  double getVisibleDuration() {
    double baseValue = length ?? 0;

    if (slidePaths.isNotEmpty) {
      baseValue = slidePaths.map((s) => s.delay + s.duration).reduce(max);
    }

    return baseValue;
  }

  void writeTo(StringBuffer writer) {
    writer.write(location.toString());

    // decorations
    if (type == NoteType.breakNote || (styles & NoteStyles.breakHead) != 0) {
      writer.write('b');
    }
    if ((styles & NoteStyles.fireworks) != 0) writer.write('f');
    if ((styles & NoteStyles.ex) != 0) writer.write('x');

    if ((styles & NoteStyles.mine) != 0) writer.write('m');

    // types
    if (type == NoteType.forceInvalidate) {
      writer.write(slideMorph == SlideMorph.fadeIn ? '?' : '!');
    }

    switch (appearance) {
      case NoteAppearance.forceNormal:
        writer.write('@');
        break;
      case NoteAppearance.forceStarSpinning:
        writer.write("\$\$");
        break;
      case NoteAppearance.forceStar:
        writer.write('\$');
        break;
      default:
        break;
    }

    if (length != null) {
      writer.write("h[#${length!.toStringAsFixed(7)}]");
    }

    for (var i = 0; i < slidePaths.length; i++) {
      if (i > 0) writer.write('*');

      var slidePath = slidePaths[i];
      slidePath.writeTo(writer);
    }
  }
}
