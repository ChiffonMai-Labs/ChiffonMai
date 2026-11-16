class Extensions {
  static String removeLineEndings(String value) {
    if (value.isEmpty) return value;
    const lineSeparator = '\u2028';
    const paragraphSeparator = '\u2029';
    return value
        .replaceAll("\r\n", "")
        .replaceAll("\n", "")
        .replaceAll("\r", "")
        .replaceAll(lineSeparator, "")
        .replaceAll(paragraphSeparator, "");
  }
}
