/// Timing ratios from Lxns-Network's maimai-chart-engine.
class NoteMotion {
  static const double baseApproachSeconds = 2.25;
  static const double hiSpeedConversionFactor = (2 / 3) * 0.9;
  static const double touchApproachMultiplier = 0.9;
  static const double initialRadiusRatio = 0.25;
  static const double scaleInProgressRatio = 0.5;
  static const double defaultApproachTime =
      baseApproachSeconds / (8 * hiSpeedConversionFactor);

  static double approachTimeForSpeed(double speed) {
    final safeSpeed = speed.isFinite ? speed.clamp(3.0, 9.0) : 8.0;
    return baseApproachSeconds / (safeSpeed * hiSpeedConversionFactor);
  }
}
