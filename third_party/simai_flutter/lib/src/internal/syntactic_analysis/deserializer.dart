import 'dart:math';
import '../../structures/mai_chart.dart';
import '../../structures/note_collection.dart';
import '../../structures/location.dart';
import '../../structures/note_group.dart';
import '../../structures/slide_type.dart';
import '../../structures/each_style.dart';
import '../lexical_analysis/token.dart';
import '../lexical_analysis/token_type.dart';
import '../errors/scope_mismatch_exception.dart';
import 'timing_change.dart';
import 'states/tempo_reader.dart';
import 'states/subdivision_reader.dart';
import 'states/note_reader.dart';

class Deserializer {
  final MaiChart _chart = MaiChart();
  final Iterator<Token> enumerator;

  final List<TimingChange> timingChanges = [];
  double _maxFinishTime = 0;
  double currentTime = 0;
  NoteCollection? currentNoteCollection;
  bool endOfFile = false;

  Deserializer(Iterable<Token> sequence) : enumerator = sequence.iterator {
    timingChanges.add(TimingChange());
    currentNoteCollection = null;
    currentTime = 0;
    endOfFile = false;
  }

  MaiChart getChart() {
    var noteCollections = <NoteCollection>[];

    // Some readers (e.g. NoteReader) moves the enumerator automatically.
    // We can skip moving the pointer if that's satisfied.
    var manuallyMoved = false;

    while (!endOfFile && (manuallyMoved || moveNext())) {
      var token = enumerator.current;
      manuallyMoved = false;

      switch (token.type) {
        case TokenType.tempo:
          TempoReader.process(this, token);
          break;
        case TokenType.subdivision:
          SubdivisionReader.process(this, token);
          break;
        case TokenType.location:
          currentNoteCollection ??= NoteCollection(currentTime);

          if (token.lexeme.startsWith('0')) {
            if (currentNoteCollection!.eachStyle != EachStyle.forceBroken) {
              currentNoteCollection!.eachStyle = EachStyle.forEach;
            }
            break;
          }

          var note = NoteReader.process(this, token);
          currentNoteCollection!.addNote(note);
          manuallyMoved = true;

          _maxFinishTime = max(
            _maxFinishTime,
            currentNoteCollection!.time + note.getVisibleDuration(),
          );
          break;
        case TokenType.timeStep:
          if (currentNoteCollection != null) {
            noteCollections.add(currentNoteCollection!);
            currentNoteCollection = null;
          }

          currentTime += timingChanges.last.secondsPerBeat;
          break;
        case TokenType.eachDivider:
          switch (token.lexeme[0]) {
            case '/':
              break;

            case '`':
              if (currentNoteCollection != null) {
                currentNoteCollection!.eachStyle = EachStyle.forceBroken;
              }
              break;
          }
          break;
        case TokenType.decorator:
          throw ScopeMismatchException(
            token.line,
            token.character,
            ScopeType.note,
          );
        case TokenType.slide:
          throw ScopeMismatchException(
            token.line,
            token.character,
            ScopeType.note,
          );
        case TokenType.duration:
          throw ScopeMismatchException(
            token.line,
            token.character,
            ScopeType.note | ScopeType.slide,
          );
        case TokenType.slideJoiner:
          throw ScopeMismatchException(
            token.line,
            token.character,
            ScopeType.slide,
          );
        case TokenType.endOfFile:
          _chart.finishTiming = currentTime;
          break;
        case TokenType.none:
          break;
      }
    }

    _chart.finishTiming ??= _maxFinishTime;

    if (currentNoteCollection != null) {
      noteCollections.add(currentNoteCollection!);
      currentNoteCollection = null;
    }

    _chart.noteCollections = noteCollections;
    _chart.timingChanges = timingChanges;

    return _chart;
  }

  /// [startLocation] The starting location.
  /// [endLocation] The ending location.
  /// [direction] 1: Right; -1: Left; Default: Shortest route.
  /// Returns The recommended ring type
  static SlideType determineRingType(
    Location startLocation,
    Location endLocation, [
    int direction = 0,
  ]) {
    switch (direction) {
      case 1:
        return (startLocation.index + 2) % 8 >= 4
            ? SlideType.ringCcw
            : SlideType.ringCw;
      case -1:
        return (startLocation.index + 2) % 8 >= 4
            ? SlideType.ringCw
            : SlideType.ringCcw;
      default:
        var difference = endLocation.index - startLocation.index;

        var rotation = difference >= 0
            ? difference > 4
                  ? -1
                  : 1
            : difference < -4
            ? 1
            : -1;

        return rotation > 0 ? SlideType.ringCw : SlideType.ringCcw;
    }
  }

  static bool tryReadLocation(Token token, Function(Location) outValue) {
    var isSensor =
        token.lexeme.codeUnitAt(0) >= 'A'.codeUnitAt(0) &&
        token.lexeme.codeUnitAt(0) <= 'E'.codeUnitAt(0);

    var indexRange = isSensor ? token.lexeme.substring(1) : token.lexeme;

    var group = NoteGroup.tap;

    if (isSensor) {
      group =
          NoteGroup.values[token.lexeme.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1];

      if (group == NoteGroup.cSensor) {
        outValue(Location(0, group));
        return true;
      }
    }

    var indexInGroup = int.tryParse(indexRange);
    if (indexInGroup == null) {
      outValue(Location(0, NoteGroup.tap)); // Default
      return false;
    }

    // Convert from 1-indexed to 0-indexed
    outValue(Location(indexInGroup - 1, group));
    return true;
  }

  bool moveNext() {
    endOfFile = !enumerator.moveNext();
    return !endOfFile;
  }
}
