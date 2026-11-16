import '../deserializer.dart';
import '../../lexical_analysis/token.dart';
import '../../lexical_analysis/token_type.dart';
import '../../errors/invalid_syntax_exception.dart';
import '../../errors/scope_mismatch_exception.dart';
import '../../errors/unexpected_character_exception.dart';
import '../../../structures/note.dart';
import '../../../structures/note_type.dart';
import '../../../structures/note_styles.dart';
import '../../../structures/note_appearance.dart';
import '../../../structures/slide_morph.dart';
import '../../../structures/note_group.dart';
import '../../../structures/location.dart';
import '../timing_change.dart';
import 'slide_reader.dart';

class NoteReader {
  static Note process(Deserializer parent, Token identityToken) {
    Location? noteLocation;
    if (!Deserializer.tryReadLocation(
      identityToken,
      (loc) => noteLocation = loc,
    )) {
      throw InvalidSyntaxException(identityToken.line, identityToken.character);
    }

    var currentNote = Note(parent.currentNoteCollection)
      ..location = noteLocation!;

    var overrideTiming = parent.timingChanges.last.clone();

    if (noteLocation!.group != NoteGroup.tap) {
      currentNote.type = NoteType.touch;
    }

    var manuallyMoved = false;

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
          decorateNote(token, currentNote);
          break;

        case TokenType.slide:
          if (currentNote.type == NoteType.hold) {
            currentNote.length = overrideTiming.secondsPerBar;
          }

          var slide = SlideReader.process(
            parent,
            currentNote,
            token,
            overrideTiming,
          );
          manuallyMoved = true;

          currentNote.slidePaths.add(slide);

          if (currentNote.type != NoteType.forceInvalidate) {
            currentNote.type = NoteType.slide;
          }
          break;

        case TokenType.duration:
          readDuration(parent.timingChanges.last, token, currentNote);
          break;

        case TokenType.slideJoiner:
          throw ScopeMismatchException(
            token.line,
            token.character,
            ScopeType.slide,
          );

        case TokenType.timeStep:
        case TokenType.eachDivider:
        case TokenType.endOfFile:
        case TokenType.location:
          // note terminates here
          return currentNote;

        case TokenType.none:
          break;
      }
    }

    return currentNote;
  }

  static void decorateNote(Token token, Note note) {
    var char = token.lexeme[0];
    switch (char) {
      case 'f':
        note.styles |= NoteStyles.fireworks;
        return;
      case 'b':
        note.styles |= NoteStyles.breakHead;
        if (note.type != NoteType.forceInvalidate) {
          note.type = NoteType.breakNote;
        }
        return;
      case 'x':
        note.styles |= NoteStyles.ex;
        return;
      case 'm':
        note.styles |= NoteStyles.mine;
        return;
      case 'h':
        if (note.type != NoteType.breakNote &&
            note.type != NoteType.forceInvalidate) {
          note.type = NoteType.hold;
        }
        note.length ??= 0;
        return;
      case '?':
        note.type = NoteType.forceInvalidate;
        note.slideMorph = SlideMorph.fadeIn;
        return;
      case '!':
        note.type = NoteType.forceInvalidate;
        note.slideMorph = SlideMorph.suddenIn;
        return;
      case '@':
        note.appearance = NoteAppearance.forceNormal;
        return;
      case '\$':
        note.appearance = note.appearance == NoteAppearance.forceStar
            ? NoteAppearance.forceStarSpinning
            : NoteAppearance.forceStar;
        return;
    }
  }

  static void readDuration(TimingChange timing, Token token, Note note) {
    if (note.type != NoteType.breakNote) {
      note.type = NoteType.hold;
    }

    final overrideTiming = timing.clone();
    var indexOfHash = token.lexeme.indexOf('#');

    if (indexOfHash == 0) {
      var explicitValue = double.tryParse(token.lexeme.substring(1));
      if (explicitValue == null) {
        throw UnexpectedCharacterException(
          token.line,
          token.character + 1,
          "0~9, or \".\"",
        );
      }

      note.length = explicitValue;
      return;
    }

    if (indexOfHash != -1) {
      var tempo = double.tryParse(token.lexeme.substring(0, indexOfHash));
      if (tempo == null) {
        throw UnexpectedCharacterException(
          token.line,
          token.character + 1,
          "0~9, or \".\"",
        );
      }

      overrideTiming.tempo = tempo;
    }

    var indexOfSeparator = token.lexeme.indexOf(':');
    var nominatorStr = token.lexeme.substring(
      indexOfHash + 1,
      indexOfSeparator,
    );
    var nominator = double.tryParse(nominatorStr);
    if (nominator == null) {
      throw UnexpectedCharacterException(
        token.line,
        token.character,
        "0~9, or \".\"",
      );
    }

    var denominatorStr = token.lexeme.substring(indexOfSeparator + 1);
    var denominator = double.tryParse(denominatorStr);
    if (denominator == null) {
      throw UnexpectedCharacterException(
        token.line,
        token.character + indexOfSeparator + 1,
        "0~9, or \".\"",
      );
    }

    note.length = overrideTiming.secondsPerBar / (nominator / 4) * denominator;
  }
}
