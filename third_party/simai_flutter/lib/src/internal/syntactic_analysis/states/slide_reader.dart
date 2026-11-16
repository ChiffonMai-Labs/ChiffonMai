import '../deserializer.dart';
import '../../lexical_analysis/token.dart';
import '../../lexical_analysis/token_type.dart';
import '../../errors/scope_mismatch_exception.dart';
import '../../errors/unsupported_syntax_exception.dart';
import '../../errors/unexpected_character_exception.dart';
import '../../../structures/note.dart';
import '../../../structures/slide_path.dart';
import '../../../structures/slide_segment.dart';
import '../../../structures/slide_type.dart';
import '../../../structures/location.dart';
import '../../../structures/note_type.dart';
import '../timing_change.dart';

class SlideReader {
  static SlidePath process(
    Deserializer parent,
    Note currentNote,
    Token identityToken,
    TimingChange defaultTimingChange,
  ) {
    var path = SlidePath([])..delay = defaultTimingChange.secondsPerBar;

    readSegment(parent, identityToken, currentNote.location, path);

    var manuallyMoved = true;

    while (!parent.endOfFile && (manuallyMoved || parent.moveNext())) {
      var token = parent.enumerator.current;
      manuallyMoved = false;

      switch (token.type) {
        case TokenType.tempo:
        case TokenType.subdivision:
          throw ScopeMismatchException(
            token.line,
            token.character,
            ScopeType.global,
          );

        case TokenType.decorator:
          decorateSlide(token, path);
          break;

        case TokenType.slide:
          readSegment(parent, token, path.segments.last.vertices.last, path);
          manuallyMoved = true;
          break;

        case TokenType.duration:
          readDuration(parent.timingChanges.last, token, path);
          break;

        case TokenType.slideJoiner:
          parent.moveNext();
          return path;

        case TokenType.timeStep:
        case TokenType.eachDivider:
        case TokenType.endOfFile:
        case TokenType.location:
          // slide terminates here
          return path;

        case TokenType.none:
          break;
      }
    }

    return path;
  }

  static void readSegment(
    Deserializer parent,
    Token identityToken,
    Location startingLocation,
    SlidePath path,
  ) {
    var segment = SlideSegment(vertices: []);
    var length = identityToken.lexeme.length;
    assignVertices(parent, identityToken, segment);
    segment.slideType = identifySlideType(
      identityToken,
      startingLocation,
      segment,
      length,
    );

    path.segments.add(segment);
  }

  static void decorateSlide(Token token, SlidePath path) {
    switch (token.lexeme[0]) {
      case 'b':
        path.type = NoteType.breakNote;
        return;
      default:
        throw UnsupportedSyntaxException(token.line, token.character);
    }
  }

  static SlideType identifySlideType(
    Token identityToken,
    Location startingLocation,
    SlideSegment segment,
    int length,
  ) {
    var firstChar = identityToken.lexeme[0];
    switch (firstChar) {
      case '-':
        return SlideType.straightLine;
      case '>':
        return Deserializer.determineRingType(
          startingLocation,
          segment.vertices[0],
          1,
        );
      case '<':
        return Deserializer.determineRingType(
          startingLocation,
          segment.vertices[0],
          -1,
        );
      case '^':
        return Deserializer.determineRingType(
          startingLocation,
          segment.vertices[0],
        );
      case 'q':
        if (length == 2 && identityToken.lexeme[1] == 'q') {
          return SlideType.edgeCurveCw;
        }
        return SlideType.curveCw;
      case 'p':
        if (length == 2 && identityToken.lexeme[1] == 'p') {
          return SlideType.edgeCurveCcw;
        }
        return SlideType.curveCcw;
      case 'v':
        return SlideType.fold;
      case 'V':
        return SlideType.edgeFold;
      case 's':
        return SlideType.zigZagS;
      case 'z':
        return SlideType.zigZagZ;
      case 'w':
        return SlideType.fan;
      default:
        throw UnexpectedCharacterException(
          identityToken.line,
          identityToken.character,
          "-, >, <, ^, q, p, v, V, s, z, w",
        );
    }
  }

  static void assignVertices(
    Deserializer parent,
    Token identityToken,
    SlideSegment segment,
  ) {
    do {
      if (!parent.enumerator.moveNext()) {
        throw UnexpectedCharacterException(
          identityToken.line,
          identityToken.character,
          "1, 2, 3, 4, 5, 6, 7, 8",
        );
      }

      var current = parent.enumerator.current;
      Location? location;
      if (Deserializer.tryReadLocation(current, (loc) => location = loc)) {
        segment.vertices.add(location!);
      }
    } while (parent.enumerator.current.type == TokenType.location);
  }

  static void readDuration(TimingChange timing, Token token, SlidePath path) {
    var startOfDurationDeclaration = 0;
    var overrideTiming =
        timing; // Reference copy? In Dart, classes are references.
    // In C# TimingChange is struct, so it's a copy.
    // In Dart I should clone it if I modify it.
    // But overrideTiming is modified below: overrideTiming.tempo = delayValue;
    // So I must clone.
    overrideTiming = timing.clone();

    var firstHashIndex = token.lexeme.indexOf('#');
    var statesIntroDelayDuration = firstHashIndex > -1;
    if (statesIntroDelayDuration) {
      startOfDurationDeclaration = token.lexeme.lastIndexOf('#') + 1;
      var lastHashIndex = startOfDurationDeclaration - 1;

      // [#seconds] specifies an explicit slide duration while preserving the
      // default intro delay. There is intentionally no value before '#'.
      if (firstHashIndex == 0 && lastHashIndex == 0) {
        final explicitDuration = double.tryParse(
          token.lexeme.substring(startOfDurationDeclaration),
        );
        if (explicitDuration == null) {
          throw UnexpectedCharacterException(
            token.line,
            token.character + startOfDurationDeclaration,
            "0~9, or \".\"",
          );
        }
        path.duration += explicitDuration;
        return;
      }

      var delayDeclaration = token.lexeme.substring(0, firstHashIndex);
      var isExplicitStatement = firstHashIndex != lastHashIndex;

      var delayValue = double.tryParse(delayDeclaration);
      if (delayValue == null) {
        throw UnexpectedCharacterException(
          token.line,
          token.character,
          "0~9, or \".\"",
        );
      }

      if (isExplicitStatement) {
        path.delay = delayValue;
      } else {
        overrideTiming.tempo = delayValue;
        path.delay = overrideTiming.secondsPerBar;
      }
    }

    var durationDeclaration = token.lexeme.substring(
      startOfDurationDeclaration,
    );
    var indexOfSeparator = durationDeclaration.indexOf(':');

    if (indexOfSeparator == -1) {
      var explicitValue = double.tryParse(durationDeclaration);
      if (explicitValue == null) {
        throw UnexpectedCharacterException(
          token.line,
          token.character + startOfDurationDeclaration,
          "0~9, or \".\"",
        );
      }

      path.duration += explicitValue;
      return;
    }

    var nominatorStr = durationDeclaration.substring(0, indexOfSeparator);
    var nominator = double.tryParse(nominatorStr);
    if (nominator == null) {
      throw UnexpectedCharacterException(
        token.line,
        token.character + startOfDurationDeclaration,
        "0~9, or \".\"",
      );
    }

    var denominatorStr = durationDeclaration.substring(indexOfSeparator + 1);
    var denominator = double.tryParse(denominatorStr);
    if (denominator == null) {
      throw UnexpectedCharacterException(
        token.line,
        token.character + startOfDurationDeclaration + indexOfSeparator + 1,
        "0~9, or \".\"",
      );
    }

    path.duration +=
        overrideTiming.secondsPerBar / (nominator / 4) * denominator;
  }
}
