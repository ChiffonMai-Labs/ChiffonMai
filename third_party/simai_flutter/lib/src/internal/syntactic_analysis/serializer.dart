import '../../structures/mai_chart.dart';
import '../../structures/note_collection.dart';
import '../../structures/each_style.dart';

class Serializer {
  int _currentTimingChange = 0;
  int _currentNoteCollection = 0;
  double _currentTime = 0;

  void serialize(MaiChart chart, StringBuffer writer) {
    writer.write("(${chart.timingChanges[_currentTimingChange].tempo})");
    writer.write("{${chart.timingChanges[_currentTimingChange].subdivisions}}");

    while (_currentTime <= (chart.finishTiming ?? 0)) {
      if (_currentTimingChange < chart.timingChanges.length - 1 &&
          (chart.timingChanges[_currentTimingChange + 1].time - _currentTime)
                  .abs() <
              1e-7) {
        _currentTimingChange++;

        if ((chart.timingChanges[_currentTimingChange].tempo -
                    chart.timingChanges[_currentTimingChange - 1].tempo)
                .abs() >
            1e-7) {
          writer.write("(${chart.timingChanges[_currentTimingChange].tempo})");
        }

        if ((chart.timingChanges[_currentTimingChange].subdivisions -
                    chart.timingChanges[_currentTimingChange - 1].subdivisions)
                .abs() >
            1e-7) {
          writer.write(
            "{${chart.timingChanges[_currentTimingChange].subdivisions}}",
          );
        }
      }

      if (_currentNoteCollection < chart.noteCollections.length &&
          (chart.noteCollections[_currentNoteCollection].time - _currentTime)
                  .abs() <=
              1e-7) {
        serializeNoteCollection(
          chart.noteCollections[_currentNoteCollection],
          writer,
        );

        _currentNoteCollection++;
      }

      var timingChange = chart.timingChanges[_currentTimingChange];
      _currentTime += timingChange.secondsPerBeat;
      writer.write(',');
    }
    writer.write('E');
  }

  static void serializeNoteCollection(
    NoteCollection notes,
    StringBuffer writer,
  ) {
    var separator = notes.eachStyle == EachStyle.forceBroken ? '`' : '/';

    if (notes.eachStyle == EachStyle.forEach) {
      writer.write("0/");
    }

    for (var i = 0; i < notes.length; i++) {
      notes[i].writeTo(writer);

      if (i != notes.length - 1) {
        writer.write(separator);
      }
    }
  }
}
