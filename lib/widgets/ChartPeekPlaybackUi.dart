import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simai_flutter/simai_flutter.dart';

import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ColorUtil.dart';
import 'AppUi.dart';
import 'GuessSettingsUi.dart';

/// 谱面片段猜歌的流速与镜像。设置里存字符串（[SimaiMirrorMode.name]），
/// 多人房间也按这个字符串传给服务端。
class ChartPeekPlayback {
  ChartPeekPlayback._();

  static const double minFlowSpeed = 3;
  static const double maxFlowSpeed = 9;

  static const Map<SimaiMirrorMode, String> mirrorLabels = {
    SimaiMirrorMode.none: '无',
    SimaiMirrorMode.horizontal: '左右反',
    SimaiMirrorMode.vertical: '上下反',
    SimaiMirrorMode.full: '全反',
  };

  static SimaiMirrorMode mirrorOf(String? name) =>
      SimaiMirrorMode.values.asNameMap()[name] ?? SimaiMirrorMode.none;

  /// 8 → 8.0，7.25 → 7.25
  static String speedLabel(double speed) {
    final text = speed.toStringAsFixed(2);
    return text.endsWith('0') ? text.substring(0, text.length - 1) : text;
  }
}

/// 播放区域右上角的小标签，显示这个片段实际用的流速和镜像。
class ChartPeekPlaybackTag extends StatelessWidget {
  final double speed;
  final SimaiMirrorMode mirror;

  const ChartPeekPlaybackTag({
    super.key,
    required this.speed,
    required this.mirror,
  });

  @override
  Widget build(BuildContext context) {
    final mirrorText = mirror == SimaiMirrorMode.none
        ? '无镜像'
        : ChartPeekPlayback.mirrorLabels[mirror]!;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '流速 ${ChartPeekPlayback.speedLabel(speed)} · $mirrorText',
          style: AppTheme.number(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// 播放区域左上角的倒计时，显示片段还剩多少秒，保留一位小数。
class ChartPeekCountdownTag extends StatelessWidget {
  /// 谱面当前时间（秒）。
  final ValueListenable<double> time;
  final double clipStart;
  final double clipEnd;

  const ChartPeekCountdownTag({
    super.key,
    required this.time,
    required this.clipStart,
    required this.clipEnd,
  });

  @override
  Widget build(BuildContext context) {
    final length = (clipEnd - clipStart).clamp(0.0, double.infinity);
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: ValueListenableBuilder<double>(
          valueListenable: time,
          builder: (context, value, _) => Text(
            '${(clipEnd - value).clamp(0.0, length).toStringAsFixed(1)}s',
            style: AppTheme.number(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// 流速滑条 + 镜像切换，单人设置和多人建房共用。
class ChartPeekPlaybackSettings extends StatelessWidget {
  final double speed;
  final SimaiMirrorMode mirror;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<SimaiMirrorMode> onMirrorChanged;

  const ChartPeekPlaybackSettings({
    super.key,
    required this.speed,
    required this.mirror,
    required this.onSpeedChanged,
    required this.onMirrorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final modes = ChartPeekPlayback.mirrorLabels.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuessSliderTile(
          label: '流速',
          valueText: ChartPeekPlayback.speedLabel(speed),
          value: speed,
          min: ChartPeekPlayback.minFlowSpeed,
          max: ChartPeekPlayback.maxFlowSpeed,
          divisions: 24,
          onChanged: onSpeedChanged,
        ),
        const SizedBox(height: 4),
        Text('镜像',
            style: TextStyle(fontSize: 13.5, color: scheme.onSurface)),
        const SizedBox(height: 8),
        SegmentedTabs(
          height: 40,
          items: [
            for (final mode in modes)
              SegmentedTabItem(ChartPeekPlayback.mirrorLabels[mode]!),
          ],
          selectedIndex: modes.indexOf(mirror),
          onChanged: (index) => onMirrorChanged(modes[index]),
        ),
      ],
    );
  }
}

/// 谱面难度随机池：每局从勾选的难度中随机抽一个，至少保留一个。
class ChartPeekDifficultyPool extends StatelessWidget {
  /// inote 编号（'2'..'6'）。
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const ChartPeekDifficultyPool({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('难度随机池',
            style: TextStyle(fontSize: 13.5, color: scheme.onSurface)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final index in ChartDifficulty.standardIndices)
              () {
                final inote = '${ChartDifficulty.toMaidataIndex(index)}';
                final color = ColorUtil.getCardColor(index);
                return GuessChoicePill(
                  label: ChartDifficulty.labelOf(index),
                  selected: selected.contains(inote),
                  selectedColor: color,
                  selectedForeground:
                      ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                  onTap: () {
                    final pool = List<String>.from(selected);
                    pool.contains(inote) ? pool.remove(inote) : pool.add(inote);
                    // 至少保留一个难度，否则抽谱时没有可播的谱面
                    if (pool.isNotEmpty) onChanged(pool);
                  },
                );
              }(),
          ],
        ),
      ],
    );
  }
}
