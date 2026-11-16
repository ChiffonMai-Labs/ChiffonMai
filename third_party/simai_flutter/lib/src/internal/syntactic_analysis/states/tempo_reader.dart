import '../deserializer.dart';
import '../../lexical_analysis/token.dart';
import '../../errors/unexpected_character_exception.dart';

class TempoReader {
  static void process(Deserializer parent, Token token) {
    var tempo = double.tryParse(token.lexeme);
    if (tempo == null) {
      throw UnexpectedCharacterException(
        token.line,
        token.character,
        "0~9, or \".\"",
      );
    }

    var newTimingChange = parent.timingChanges.last.clone();
    newTimingChange.tempo = tempo;
    newTimingChange.time = parent.currentTime;

    // If the new timing change is at the same time as the last one, overwrite it.
    if ((parent.timingChanges.last.time - parent.currentTime).abs() <= 1e-7) {
      parent.timingChanges.removeLast();
    }

    parent.timingChanges.add(newTimingChange);
  }
}
