import 'dart:ui';

class NoteGeometry {
  static const double referenceChartRadius = 300.0;
  static const double tapStarHoldRadiusRatio = 0.125;
  static const double tapStarHoldRadius =
      referenceChartRadius * tapStarHoldRadiusRatio;
  static const double slideArrowHalfWidth = 20.0;
  static const double slideArrowChevronDepth = 20.0;
  // The chevrons run at roughly 45 degrees, so a 17-unit longitudinal gap
  // produces a visibly 12-unit-thick ribbon between them.
  static const double slideArrowBandDepth = 17.0;

  const NoteGeometry._();

  /// Builds the filled ribbon used by each regular Slide trajectory arrow.
  ///
  /// Its front and rear chevrons have identical amplitude and depth, with the
  /// two corresponding endpoints joined to form one closed shape.
  static Path buildSlideArrowPath(double scale) {
    if (!scale.isFinite || scale <= 0) return Path();
    final halfWidth = slideArrowHalfWidth * scale;
    final chevronDepth = slideArrowChevronDepth * scale;
    final bandDepth = slideArrowBandDepth * scale;
    final totalLength = chevronDepth + bandDepth;
    final rearBase = -totalLength / 2;
    final frontBase = rearBase + bandDepth;
    final rearTip = rearBase + chevronDepth;
    final frontTip = frontBase + chevronDepth;
    return Path()
      ..moveTo(rearBase, -halfWidth)
      ..lineTo(frontBase, -halfWidth)
      ..lineTo(frontTip, 0)
      ..lineTo(frontBase, halfWidth)
      ..lineTo(rearBase, halfWidth)
      ..lineTo(rearTip, 0)
      ..close();
  }
}
