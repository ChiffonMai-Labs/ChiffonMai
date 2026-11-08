import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
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
      label: context.l10n.flowSpeedPitchMultiplier,
      valueText: labelOf(rate),
      value: rate,
      min: GuessChartCommonSettingsService.minAudioRate,
      max: GuessChartCommonSettingsService.maxAudioRate,
      divisions: 98,
      onChanged: (value) => onChanged((value * 100).round() / 100),
      hint: context.l10n.flowChoose015SpeedAndPitch,
    );
  }
}
