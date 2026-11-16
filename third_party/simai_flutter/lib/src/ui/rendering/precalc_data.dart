import 'dart:typed_data';

import '../../gameplay/gameplay_models.dart';

class PrecalcChartData {
  final Map<int, Map<double, int>> slideStartCounts;
  // Key: "${collectionIndex}_${noteIndex}_${slideIndex}"
  final Map<String, PrecalcSlideData> slides;

  PrecalcChartData({
    Map<int, Map<double, int>>? slideStartCounts,
    Map<String, PrecalcSlideData>? slides,
  }) : slideStartCounts = slideStartCounts ?? {},
       slides = slides ?? {};

  void merge(PrecalcChartData other) {
    slideStartCounts.addAll(other.slideStartCounts);
    slides.addAll(other.slides);
  }
}

class PrecalcSlideData {
  final double totalLength;

  // Normalized Arrow Points
  final Float32List arrowDistances;
  // For normal arrows
  final Float32List? arrowX;
  final Float32List? arrowY;
  final Float32List? arrowAngles;

  // For fan arrows
  final Float32List? fanLeftX;
  final Float32List? fanLeftY;
  final Float32List? fanCenterX;
  final Float32List? fanCenterY;
  final Float32List? fanRightX;
  final Float32List? fanRightY;

  // Normalized Star lookup table (1000 samples from 0.0 to 1.0 progress)
  final Float32List? starX;
  final Float32List? starY;
  final Float32List? starAngles;

  // For fan slides (3 stars):
  final Float32List? fanStarLeftX, fanStarLeftY, fanStarLeftAngles;
  final Float32List? fanStarCenterX, fanStarCenterY, fanStarCenterAngles;
  final Float32List? fanStarRightX, fanStarRightY, fanStarRightAngles;
  final SimaiGameplaySlideData gameplay;

  PrecalcSlideData({
    required this.totalLength,
    required this.arrowDistances,
    this.arrowX,
    this.arrowY,
    this.arrowAngles,
    this.fanLeftX,
    this.fanLeftY,
    this.fanCenterX,
    this.fanCenterY,
    this.fanRightX,
    this.fanRightY,
    this.starX,
    this.starY,
    this.starAngles,
    this.fanStarLeftX,
    this.fanStarLeftY,
    this.fanStarLeftAngles,
    this.fanStarCenterX,
    this.fanStarCenterY,
    this.fanStarCenterAngles,
    this.fanStarRightX,
    this.fanStarRightY,
    this.fanStarRightAngles,
    required this.gameplay,
  });
}
