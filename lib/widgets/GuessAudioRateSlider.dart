import 'package:flutter/material.dart';
import '../service/GuessChartGame/GuessChartCommonSettingsService.dart';

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Expanded(child: Text('变速变调倍率')),
            Text(labelOf(rate),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          Slider(
            value: rate,
            min: GuessChartCommonSettingsService.minAudioRate,
            max: GuessChartCommonSettingsService.maxAudioRate,
            divisions: 98,
            label: labelOf(rate),
            onChanged: (value) => onChanged((value * 100).round() / 100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text('0.1×'), Text('5×')],
          ),
          const SizedBox(height: 8),
          Text('速度与音高联动改变；音源不足设置时长时，按实际时长播放。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
