import 'package:flutter/material.dart';
import '../service/GuessChartGame/GuessChartCommonSettingsService.dart';
import 'GuessSettingsUi.dart';

/// 统一设置页与游戏内设置使用同一倍率范围、步长和说明。
class GuessAudioRateSlider extends StatelessWidget {
  const GuessAudioRateSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  static String labelOf(double value) =>
      '${value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}×';

  @override
  Widget build(BuildContext context) {
    final rate = GuessChartCommonSettingsService.normalizeAudioRate(value);
    return GuessSliderTile(
      label: '变速变调倍率',
      valueText: labelOf(rate),
      value: rate,
      min: GuessChartCommonSettingsService.minAudioRate,
      max: GuessChartCommonSettingsService.maxAudioRate,
      divisions: 98,
      onChanged: (value) => onChanged((value * 100).round() / 100),
      hint: '可选 0.1× 至 5×，速度与音高联动改变；音源不足设置时长时，按实际时长播放。',
    );
  }
}
