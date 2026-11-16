import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';

import '../constant/AppLinks.dart';
import '../service/ChartPlaySettingsStore.dart';
import '../service/SongMaidataPageService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUi.dart';
import 'ChartPlayPage.dart';

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
  var loadAudio = await ChartPlayAudioPreference.load();
  if (!context.mounted || route?.isCurrent == false) return;
  FocusManager.instance.primaryFocus?.unfocus();
  String? selectedInote;
  if (inotes.isNotEmpty) {
    selectedInote = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        title: Text(dialogContext.l10n.flowSelectDifficulty),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  dialogContext.l10n.flowRenderedChartsAreForReferenceAndMay,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              StatefulBuilder(
                builder: (context, setDialogState) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: loadAudio,
                  title: Text(context.l10n.flowLoadAudio),
                  subtitle: Text(context.l10n.flowTurnOffToLoadTheChartWithout),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => loadAudio = value);
                    ChartPlayAudioPreference.save(value);
                  },
                ),
              ),
              for (final inote in inotes)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(inote),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          chartInoteColor(dialogContext, song, inote),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      textStyle: AppTheme.font(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                      ),
                    ),
                    child: Text(chartInoteLabel(song, inotes, inote)),
                  ),
                ),
              const SizedBox(height: 12),
              LinkPill(
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
            ],
          ),
        ),
      ),
    );
    if (selectedInote == null ||
        !context.mounted ||
        route?.isCurrent == false) {
      return;
    }
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
      ),
    ),
  );
}
