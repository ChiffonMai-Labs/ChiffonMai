import 'simai_exception.dart';

class UnsupportedSyntaxException extends SimaiException {
  /// This is thrown when an unsupported syntax is encountered when attempting to tokenize or deserialize the simai file.
  ///
  /// [line] The line on which the error occurred
  /// [character] The first character involved in the error
  UnsupportedSyntaxException(super.line, super.character);
}
