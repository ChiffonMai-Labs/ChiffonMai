class SimaiException implements Exception {
  final int line;
  final int character;

  /// [line] The line on which the error occurred
  /// [character] The first character involved in the error
  SimaiException(this.line, this.character);
}
