enum TokenType {
  none,
  tempo,
  subdivision,

  /// Touch locations (A~E + 1~8) and tap locations (1~8)
  /// Takes either only a number (1 ~ 8) or a character (A ~ E) followed by a number (1 ~ 8 for A, B, D, E and 1 or 2 for C)
  location,

  /// Applies note styles and note types
  decorator,

  /// Takes a [SlideType] and target vertices
  slide,

  /// Usually denotes the length of a hold or a [SlidePath]
  duration,

  /// Allows multiple slides to share the same parent note
  slideJoiner,

  /// Progresses the time by 1 beat
  timeStep,

  eachDivider,
  endOfFile,
}
