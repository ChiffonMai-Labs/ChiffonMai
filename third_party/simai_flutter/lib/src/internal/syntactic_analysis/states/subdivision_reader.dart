import '../deserializer.dart';
import '../../lexical_analysis/token.dart';
import '../../errors/unexpected_character_exception.dart';

class SubdivisionReader {
  static void process(Deserializer parent, Token token) {
    if (token.lexeme.startsWith('#')) {
      var explicitTempo = double.tryParse(token.lexeme.substring(1));
      if (explicitTempo == null) {
        throw UnexpectedCharacterException(
          token.line,
          token.character + 1,
          "0~9, or \".\"",
        );
      }

      var newTimingChange = parent.timingChanges.last.clone();
      newTimingChange.setSeconds(explicitTempo);
      newTimingChange.time = parent.currentTime;

      if ((parent.timingChanges.last.time - parent.currentTime).abs() <= 1e-7) {
        parent.timingChanges.removeLast();
      }

      parent.timingChanges.add(newTimingChange);
      return;
    }

    var subdivision = double.tryParse(token.lexeme);
    if (subdivision == null) {
      throw UnexpectedCharacterException(
        token.line,
        token.character,
        "0~9, or \".\"",
      );
    }

    var newTimingChange = parent.timingChanges.last.clone();
    newTimingChange.subdivisions = subdivision;
    newTimingChange.time = parent.currentTime;

    if ((parent.timingChanges.last.time - parent.currentTime).abs() <= 1e-7) {
      parent.timingChanges.removeLast();
    }

    parent.timingChanges.add(newTimingChange);
  }
}
