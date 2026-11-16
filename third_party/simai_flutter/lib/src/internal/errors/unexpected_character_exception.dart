import 'simai_exception.dart';

class UnexpectedCharacterException extends SimaiException {
  final String expected;

  /// This is thrown when reading a character that is not fit for the expected syntax
  /// This issue is commonly caused by a typo or a syntax error.
  ///
  /// [line] The line on which the error occurred
  /// [character] The first character involved in the error
  /// [expected] The expected syntax
  UnexpectedCharacterException(super.line, super.character, this.expected);
}
