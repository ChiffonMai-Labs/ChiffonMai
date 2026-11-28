import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simai_flutter/simai_flutter.dart';

import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ColorUtil.dart';
import 'AppUi.dart';
import 'GuessSettingsUi.dart';

/// 谱面片段猜歌的流速、镜像、音符/判定线样式与倍速。
/// 枚举项在本地设置与多人房间中均以字符串形式保存和同步。
class ChartPeekPlayback {
  ChartPeekPlayback._();

  static const double minFlowSpeed = NoteMotion.minSpeed;
  static const double maxFlowSpeed = NoteMotion.sonicSpeedValue;
  static const int speedDivisions = NoteMotion.speedSliderDivisions;

  static const double minSlideDisplayTiming = NoteMotion.minSlideDisplayTiming;
  static const double maxSlideDisplayTiming = NoteMotion.maxSlideDisplayTiming;
  static const int slideTimingDivisions = NoteMotion.slideDisplayTimingDivisions;

  static const double minPlaybackRate = 0.1;
  static const double maxPlaybackRate = 3.0;
  static const int playbackRateDivisions = 58;
  static const List<double> playbackRatePresets = [
    0.5,
    0.75,
    1.0,
    1.5,
    2.0,
    3.0,
  ];

  static const Map<SimaiMirrorMode, String> mirrorLabels = {
    SimaiMirrorMode.none: '无',
    SimaiMirrorMode.horizontal: '左右反',
    SimaiMirrorMode.vertical: '上下反',
    SimaiMirrorMode.full: '全反',
  };

  static const Map<SimaiBackgroundMode, String> backgroundModeLabels = {
    SimaiBackgroundMode.none: '无',
    SimaiBackgroundMode.dots: '点',
    SimaiBackgroundMode.judgeLine: '线',
    SimaiBackgroundMode.judgeZone: '区',
  };

  static SimaiMirrorMode mirrorOf(String? name) =>
      SimaiMirrorMode.values.asNameMap()[name] ?? SimaiMirrorMode.none;

  static SimaiNoteStyle noteStyleOf(String? name) =>
      SimaiNoteStyle.fromName(name);

  static SimaiNoteStyle holdStyleOf(String? name) =>
      SimaiNoteStyle.fromHoldName(name);

  static SimaiBackgroundMode backgroundModeOf(String? name) =>
      SimaiBackgroundMode.values.asNameMap()[name] ??
      SimaiBackgroundMode.judgeLine;

  static double normalizeSpeed(num? value, {double fallback = 8.0}) =>
      NoteMotion.normalizeSpeed(
        value != null && value.isFinite ? value.toDouble() : fallback,
        fallback: fallback,
      );

  static double normalizeSlideTiming(num? value) =>
      NoteMotion.normalizeSlideDisplayTiming(
        value != null && value.isFinite ? value.toDouble() : 0.0,
      );

  static double normalizePlaybackRate(num? value) {
    final raw = value != null && value.isFinite ? value.toDouble() : 1.0;
    final clamped = raw.clamp(minPlaybackRate, maxPlaybackRate).toDouble();
    return ((clamped * 20.0).round() / 20.0).toDouble();
  }

  static bool isNonDefaultPlaybackRate(double rate) =>
      (rate - 1.0).abs() > 0.001;

  /// 8 → 8.00，10.25 → SONIC
  static String speedLabel(double speed) =>
      NoteMotion.formatSpeedLabel(speed, withPrefixX: false);

  static String slideTimingLabel(double value) =>
      NoteMotion.formatSlideDisplayTiming(value);

  static String rateLabel(double rate) {
    final normalized = normalizePlaybackRate(rate);
    var text = normalized.toStringAsFixed(2);
    while (text.contains('.') && (text.endsWith('0') || text.endsWith('.'))) {
      text = text.substring(0, text.length - 1);
    }
    return '${text}x';
  }
}

/// 播放区域右上角的小标签，显示这个片段实际用的流速和镜像，
/// 非 1 倍速时额外在右侧突出展示当前倍速。
class ChartPeekPlaybackTag extends StatelessWidget {
  final double speed;
  final SimaiMirrorMode mirror;
  final double playbackRate;

  const ChartPeekPlaybackTag({
    super.key,
    required this.speed,
    required this.mirror,
    this.playbackRate = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final mirrorText = mirror == SimaiMirrorMode.none
        ? context.l10n.flowNoMirror
        : context.featureText(ChartPeekPlayback.mirrorLabels[mirror]!);
    final showRate = ChartPeekPlayback.isNonDefaultPlaybackRate(playbackRate);
    return IgnorePointer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.l10n.flowNoteSpeedP0P1(
                ChartPeekPlayback.speedLabel(speed),
                mirrorText,
              ),
              style: AppTheme.number(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          if (showRate) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                ChartPeekPlayback.rateLabel(playbackRate),
                style: AppTheme.number(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
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

/// 谱面片段播放设置面板（流速 / 显示时机 / 倍速 / 样式 / 镜像），
/// 单人设置和多人建房共用。
class ChartPeekPlaybackSettings extends StatelessWidget {
  final double speed;
  final double touchSpeed;
  final double slideDisplayTiming;
  final double playbackRate;
  final SimaiMirrorMode mirror;
  final SimaiNoteStyle noteStyle;
  final SimaiNoteStyle holdStyle;
  final SimaiBackgroundMode backgroundMode;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onTouchSpeedChanged;
  final ValueChanged<double> onSlideDisplayTimingChanged;
  final ValueChanged<double> onPlaybackRateChanged;
  final ValueChanged<SimaiMirrorMode> onMirrorChanged;
  final ValueChanged<SimaiNoteStyle> onNoteStyleChanged;
  final ValueChanged<SimaiNoteStyle> onHoldStyleChanged;
  final ValueChanged<SimaiBackgroundMode> onBackgroundModeChanged;

  const ChartPeekPlaybackSettings({
    super.key,
    required this.speed,
    required this.touchSpeed,
    required this.slideDisplayTiming,
    required this.playbackRate,
    required this.mirror,
    required this.noteStyle,
    required this.holdStyle,
    required this.backgroundMode,
    required this.onSpeedChanged,
    required this.onTouchSpeedChanged,
    required this.onSlideDisplayTimingChanged,
    required this.onPlaybackRateChanged,
    required this.onMirrorChanged,
    required this.onNoteStyleChanged,
    required this.onHoldStyleChanged,
    required this.onBackgroundModeChanged,
  });

  Widget _segmentGroup<T>({
    required BuildContext context,
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final idx = values.indexOf(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: TextStyle(fontSize: 13.5, color: scheme.onSurface)),
        const SizedBox(height: 8),
        SegmentedTabs(
          height: 38,
          items: [for (final v in values) SegmentedTabItem(labelOf(v))],
          selectedIndex: idx < 0 ? 0 : idx,
          onChanged: (index) => onChanged(values[index]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final modes = ChartPeekPlayback.mirrorLabels.keys.toList();
    final noteStyles = SimaiNoteStyle.values;
    final holdStyles = SimaiNoteStyle.holdValues;
    final bgModes = ChartPeekPlayback.backgroundModeLabels.keys.toList();
    final safeSpeed = ChartPeekPlayback.normalizeSpeed(speed);
    final safeTouchSpeed = ChartPeekPlayback.normalizeSpeed(touchSpeed);
    final safeTiming =
        ChartPeekPlayback.normalizeSlideTiming(slideDisplayTiming);
    final safeRate = ChartPeekPlayback.normalizePlaybackRate(playbackRate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuessSliderTile(
          label: 'TAP/HOLD 流速',
          valueText: ChartPeekPlayback.speedLabel(safeSpeed),
          value: safeSpeed,
          min: ChartPeekPlayback.minFlowSpeed,
          max: ChartPeekPlayback.maxFlowSpeed,
          divisions: ChartPeekPlayback.speedDivisions,
          onChanged: (v) => onSpeedChanged(ChartPeekPlayback.normalizeSpeed(v)),
        ),
        GuessSliderTile(
          label: 'TOUCH 流速',
          valueText: ChartPeekPlayback.speedLabel(safeTouchSpeed),
          value: safeTouchSpeed,
          min: ChartPeekPlayback.minFlowSpeed,
          max: ChartPeekPlayback.maxFlowSpeed,
          divisions: ChartPeekPlayback.speedDivisions,
          onChanged: (v) =>
              onTouchSpeedChanged(ChartPeekPlayback.normalizeSpeed(v)),
        ),
        GuessSliderTile(
          label: 'SLIDE 显示时机',
          valueText: ChartPeekPlayback.slideTimingLabel(safeTiming),
          value: safeTiming,
          min: ChartPeekPlayback.minSlideDisplayTiming,
          max: ChartPeekPlayback.maxSlideDisplayTiming,
          divisions: ChartPeekPlayback.slideTimingDivisions,
          onChanged: (v) => onSlideDisplayTimingChanged(
              ChartPeekPlayback.normalizeSlideTiming(v)),
        ),
        GuessSliderTile(
          label: '播放倍速',
          valueText: ChartPeekPlayback.rateLabel(safeRate),
          value: safeRate,
          min: ChartPeekPlayback.minPlaybackRate,
          max: ChartPeekPlayback.maxPlaybackRate,
          divisions: ChartPeekPlayback.playbackRateDivisions,
          onChanged: (v) =>
              onPlaybackRateChanged(ChartPeekPlayback.normalizePlaybackRate(v)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in ChartPeekPlayback.playbackRatePresets)
              GuessChoicePill(
                label: ChartPeekPlayback.rateLabel(preset),
                selected: (safeRate - preset).abs() < 0.001,
                onTap: () => onPlaybackRateChanged(preset),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _segmentGroup<SimaiNoteStyle>(
          context: context,
          title: 'TAP / SLIDE 头部样式',
          values: noteStyles,
          selected: noteStyle,
          labelOf: (v) => v.shortLabel,
          onChanged: onNoteStyleChanged,
        ),
        const SizedBox(height: 12),
        _segmentGroup<SimaiNoteStyle>(
          context: context,
          title: 'HOLD 样式',
          values: holdStyles,
          selected: SimaiNoteStyle.normalizeForHold(holdStyle),
          labelOf: (v) => v.shortLabel,
          onChanged: onHoldStyleChanged,
        ),
        const SizedBox(height: 12),
        _segmentGroup<SimaiBackgroundMode>(
          context: context,
          title: '判定线样式',
          values: bgModes,
          selected: backgroundMode,
          labelOf: (v) => ChartPeekPlayback.backgroundModeLabels[v]!,
          onChanged: onBackgroundModeChanged,
        ),
        const SizedBox(height: 12),
        _segmentGroup<SimaiMirrorMode>(
          context: context,
          title: context.l10n.flowMirror,
          values: modes,
          selected: mirror,
          labelOf: (v) => context.featureText(ChartPeekPlayback.mirrorLabels[v]!),
          onChanged: onMirrorChanged,
        ),
        if (ChartPeekPlayback.isNonDefaultPlaybackRate(safeRate)) ...[
          const SizedBox(height: 8),
          Text(
            '当前为 ${ChartPeekPlayback.rateLabel(safeRate)} 非原速播放，播放页右上角将同步标注倍速',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
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
        Text(context.l10n.flowRandomDifficultyPool,
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
