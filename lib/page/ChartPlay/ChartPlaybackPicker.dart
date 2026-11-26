import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';

import '../../constant/AppLinks.dart';
import '../../service/ChartPlay/ChartPlaySettingsStore.dart';
import '../../service/ChartPlay/SongMaidataPageService.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/ExternalLaunchUtil.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppSwitch.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';
import 'ChartPlayPage.dart';

class ChartPlaybackChoice {
  final String inote;
  final bool loadAudio;
  final bool loadPv;

  const ChartPlaybackChoice({
    required this.inote,
    required this.loadAudio,
    required this.loadPv,
  });
}

String? _extractInoteLevel(String maidataContent, String inote) {
  final match = RegExp(
    '^&lv_${RegExp.escape(inote)}\\s*=\\s*(.+)\\r?\$',
    multiLine: true,
  ).firstMatch(maidataContent);
  final raw = match?.group(1)?.trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

/// 统一的谱面播放前难度与资源选择对话框。
Future<ChartPlaybackChoice?> showChartDifficultyDialog(
  BuildContext context, {
  required String songTitle,
  required String maidataContent,
  required List<String> inotes,
  required String Function(String inote) labelBuilder,
  required Color Function(BuildContext dialogContext, String inote) colorBuilder,
  required bool initialLoadAudio,
  required ValueChanged<bool> onLoadAudioChanged,
  bool showPvOption = false,
  bool initialLoadPv = false,
  ValueChanged<bool>? onLoadPvChanged,
  bool showCredit = true,
}) {
  var loadAudio = initialLoadAudio;
  var loadPv = initialLoadPv;
  return showDialog<ChartPlaybackChoice>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final l10n = dialogContext.l10n;
      return AppAlertDialog(
        icon: appDialogIconTile(
          Icons.play_circle_outline_rounded,
          scheme.primary,
        ),
        title: Text(l10n.flowSelectDifficulty),
        subtitle: songTitle,
        scrollable: true,
        content: StatefulBuilder(
          builder: (innerContext, setDialogState) {
            Widget optionRow({
              required IconData icon,
              required String title,
              required String subtitle,
              required bool value,
              required ValueChanged<bool> onToggle,
            }) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onToggle(!value),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      AppSwitch(value: value, onChanged: onToggle),
                    ],
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.chartPlayDifficultySection,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (final (index, inote) in inotes.indexed) ...[
                  if (index > 0) const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final color = colorBuilder(dialogContext, inote);
                      final level = _extractInoteLevel(maidataContent, inote);
                      return PressScale(
                        child: Material(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            AppDesignTokens.radiusSmall,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            splashFactory: NoSplash.splashFactory,
                            highlightColor: Colors.transparent,
                            onTap: () => Navigator.of(dialogContext).pop(
                              ChartPlaybackChoice(
                                inote: inote,
                                loadAudio: loadAudio,
                                loadPv: loadPv,
                              ),
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 48),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        labelBuilder(inote),
                                        style: AppTheme.font(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (level != null) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(
                                            AppDesignTokens.radiusPill,
                                          ),
                                        ),
                                        child: Text(
                                          'Lv.$level',
                                          style: AppTheme.number(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  l10n.chartPlayOptionsSection,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(dialogContext),
                    borderRadius: BorderRadius.circular(
                      AppDesignTokens.radiusMedium,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      optionRow(
                        icon: Icons.music_note_rounded,
                        title: l10n.flowLoadAudio,
                        subtitle: l10n.flowTurnOffToLoadTheChartWithout,
                        value: loadAudio,
                        onToggle: (value) {
                          setDialogState(() => loadAudio = value);
                          onLoadAudioChanged(value);
                        },
                      ),
                      if (showPvOption) ...[
                        Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: scheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                        optionRow(
                          icon: Icons.ondemand_video_rounded,
                          title: l10n.chartPlayLoadPv,
                          subtitle: l10n.chartPlayLoadPvSubtitle,
                          value: loadPv,
                          onToggle: (value) {
                            setDialogState(() => loadPv = value);
                            onLoadPvChanged?.call(value);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.flowRenderedChartsAreForReferenceAndMay,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (showCredit) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LinkPill(
                      label: '${AppLinks.simaiFlutterCreditName} · MIT',
                      onTap: () async {
                        const url = AppLinks.simaiFlutterProjectUrl;
                        final opened = await ExternalLaunchUtil.openString(url);
                        if (!opened && dialogContext.mounted) {
                          AppToast.show(
                            dialogContext.l10n.flowCouldNotOpenLinkP0(url),
                            tone: AppToastTone.error,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.featureCancel),
          ),
        ],
      );
    },
  );
}

bool _isUtage(SongMaidataPageService song) =>
    song.genre == '宴会場' ||
    song.songType == 'UTAGE' ||
    (song.songId.length == 6 && int.tryParse(song.songId) != null);

String chartInoteLabel(
    SongMaidataPageService song, List<String> inotes, String inote) {
  if (!_isUtage(song)) {
    return SongMaidataPageService.inoteDifficultyMap[inote] ?? inote;
  }
  final index = inotes.indexOf(inote);
  return inotes.length > 1 && index >= 0
      ? '${ChartDifficulty.utageLabel} ${index + 1}'
      : ChartDifficulty.utageLabel;
}

Color chartInoteColor(
    BuildContext context, SongMaidataPageService song, String inote) {
  if (_isUtage(song)) {
    return AppColors.utageAccent(brightness: Theme.of(context).brightness);
  }
  return Color(SongMaidataPageService.inoteColorMap[inote] ?? 0xFF9E9E9E);
}

/// 谱面代码和歌曲详情共用同一个播放入口。
Future<void> showChartPlayback(
  BuildContext context, {
  required SongMaidataPageService song,
  required String content,
  required List<String> inotes,
}) async {
  if (content.isEmpty) return;
  final route = ModalRoute.of(context);
  final prefs = await Future.wait<bool>([
    ChartPlayAudioPreference.load(),
    ChartPlayPvPreference.load(),
  ]);
  var loadAudio = prefs[0];
  var loadPv = prefs[1];
  if (!context.mounted || route?.isCurrent == false) return;
  FocusManager.instance.primaryFocus?.unfocus();
  String? selectedInote;
  if (inotes.isNotEmpty) {
    final choice = await showChartDifficultyDialog(
      context,
      songTitle: song.songTitle,
      maidataContent: content,
      inotes: inotes,
      labelBuilder: (inote) => chartInoteLabel(song, inotes, inote),
      colorBuilder: (dialogContext, inote) =>
          chartInoteColor(dialogContext, song, inote),
      initialLoadAudio: loadAudio,
      onLoadAudioChanged: (value) {
        loadAudio = value;
        ChartPlayAudioPreference.save(value);
      },
      showPvOption: true,
      initialLoadPv: loadPv,
      onLoadPvChanged: (value) {
        loadPv = value;
        ChartPlayPvPreference.save(value);
      },
      showCredit: true,
    );
    if (choice == null || !context.mounted || route?.isCurrent == false) {
      return;
    }
    selectedInote = choice.inote;
    loadAudio = choice.loadAudio;
    loadPv = choice.loadPv;
  }
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ChartPlayPage(
        maidataContent: content,
        songTitle: song.songTitle,
        songId: song.songId,
        songType: song.songType,
        selectedInote: selectedInote,
        loadAudio: loadAudio,
        loadPv: loadPv,
      ),
    ),
  );
}
