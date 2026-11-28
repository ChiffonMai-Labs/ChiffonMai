import 'dart:async';

import 'package:flutter/material.dart';

import '../../audio/judgement_sound_bank.dart';
import '../simai_game.dart' show simaiMaxHitSoundVolume;

/// 可折叠的「各判定音效独立音量调节」面板，支持分音色调节 0%~300% 音量、行内试听与一键重置。
class SimaiJudgementSoundVolumesPanel extends StatefulWidget {
  final SimaiJudgementSoundVolumes volumes;
  final SimaiCustomJudgementSounds customSounds;
  final void Function(SimaiJudgementSoundKind kind, double volume)
  onVolumeChanged;
  final VoidCallback onResetAll;
  final bool enabled;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry padding;

  const SimaiJudgementSoundVolumesPanel({
    super.key,
    required this.volumes,
    required this.customSounds,
    required this.onVolumeChanged,
    required this.onResetAll,
    this.enabled = true,
    this.initiallyExpanded = true,
    this.padding = const EdgeInsets.fromLTRB(16, 4, 16, 12),
  });

  @override
  State<SimaiJudgementSoundVolumesPanel> createState() =>
      _SimaiJudgementSoundVolumesPanelState();
}

class _SimaiJudgementSoundVolumesPanelState
    extends State<SimaiJudgementSoundVolumesPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final volumes = widget.volumes;
    final enabled = widget.enabled;
    final statusText = volumes.isAllDefault
        ? '全部 100%（独立于正解音）'
        : '已单独调节 ${volumes.customizedCount} 项';

    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.spatial_audio_outlined,
                      size: 20,
                      color: enabled
                          ? colorScheme.onSurfaceVariant
                          : theme.disabledColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '判定音效音量（分音色）',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: enabled ? null : theme.disabledColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: enabled
                                  ? colorScheme.onSurfaceVariant
                                  : theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!volumes.isAllDefault && enabled)
                      TextButton(
                        onPressed: widget.onResetAll,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('重置'),
                      ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              Divider(height: 1, color: colorScheme.outlineVariant),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  children: [
                    for (
                      int index = 0;
                      index < SimaiJudgementSoundKind.values.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(height: 4),
                      _buildKindRow(
                        theme,
                        colorScheme,
                        SimaiJudgementSoundKind.values[index],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKindRow(
    ThemeData theme,
    ColorScheme colorScheme,
    SimaiJudgementSoundKind kind,
  ) {
    final enabled = widget.enabled;
    final volume = widget.volumes.volumeFor(kind).clamp(
      0.0,
      simaiMaxHitSoundVolume,
    );
    final isDefault = (volume - SimaiJudgementSoundVolumes.defaultVolume).abs() < 1e-6;
    final customPath = widget.customSounds.pathFor(kind);
    final percentText = '${(volume * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: enabled
                  ? () => unawaited(
                      previewSimaiJudgementSound(
                        kind,
                        volume: volume,
                        customFilePath: customPath,
                      ),
                    )
                  : null,
              icon: const Icon(Icons.volume_up_rounded, size: 18),
              tooltip: '试听${kind.label}',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            const SizedBox(width: 4),
            Text(
              kind.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled ? null : theme.disabledColor,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                kind.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? colorScheme.onSurfaceVariant
                      : theme.disabledColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentText,
              style: theme.textTheme.labelMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
                color: !enabled
                    ? theme.disabledColor
                    : volume <= 0
                    ? colorScheme.outline
                    : isDefault
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
                fontWeight: isDefault ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: volume,
            min: 0.0,
            max: simaiMaxHitSoundVolume,
            divisions: 60,
            onChanged: enabled
                ? (v) => widget.onVolumeChanged(kind, v)
                : null,
          ),
        ),
      ],
    );
  }
}
