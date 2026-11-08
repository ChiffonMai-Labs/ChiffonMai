import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../service/GuessChartGame/GuessChartCommonSettingsService.dart';
import '../../service/GuessChartGame/GuessChartByInfoService.dart';
import '../../utils/CommonWidgetUtil.dart';
import '../../utils/SongFilterUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/GuessAudioRateSlider.dart';
import '../../widgets/GuessSettingsUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/ChartPeekPlaybackUi.dart';

/// 猜歌设置统一入口，继续使用各模式原有的设置存储。
class GuessGameSettingsPage extends StatefulWidget {
  const GuessGameSettingsPage({super.key});
  @override
  State<GuessGameSettingsPage> createState() => _GuessGameSettingsPageState();
}

class _GuessGameSettingsPageState extends State<GuessGameSettingsPage> {
  final _service = GuessChartCommonSettingsService();
  Map<String, dynamic>? _settings;
  List<String> _versions = [], _genres = [];
  String? _error;
  Timer? _saveTimer;
  Future<void> _writes = Future.value();
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _service.loadSettings();
      final songs = await GuessChartByInfoService.loadAllSongs();
      if (!mounted) return;
      final filters = SongFilterUtil.selectableFilters(songs ?? []);
      setState(() {
        _settings = settings;
        _versions = filters.versions;
        _genres = filters.genres;
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = appL10n.flowCouldNotLoadSettingsPleaseRetry);
    }
  }

  void _change(String key, dynamic value) {
    setState(() => _settings![key] = value);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _save);
  }

  void _save() {
    final s = Map<String, dynamic>.from(_settings!);
    _writes = _writes
        .then((_) => _service.saveSettings(
              selectedVersions: List<String>.from(s['selectedVersions']),
              masterMinDx: (s['masterMinDx'] as num).toDouble(),
              masterMaxDx: (s['masterMaxDx'] as num).toDouble(),
              selectedGenres: List<String>.from(s['selectedGenres']),
              maxGuesses: s['maxGuesses'],
              timeLimit: s['timeLimit'],
              blurLevel: s['blurLevel'],
              pixelationLevel: s['pixelationLevel'],
              songCount: s['songCount'],
              nonEnglishCharThreshold: s['nonEnglishCharThreshold'],
              flashDurationMs: s['flashDurationMs'],
              tileCount: s['tileCount'],
              tileRevealIntervalMs: s['tileRevealIntervalMs'],
              peekDurationSeconds: s['peekDurationSeconds'],
              peekDifficulties: List<String>.from(s['peekDifficulties']),
              peekFlowSpeed: (s['peekFlowSpeed'] as num).toDouble(),
              peekMirror: s['peekMirror'] as String,
              playDurationSeconds: s['playDurationSeconds'],
              audioRate: (s['audioRate'] as num).toDouble(),
            ))
        .catchError((Object error) {
      _saveFailed = true;
      AppToast.show(appL10n.settingSaveFailed, tone: AppToastTone.error);
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_settings != null) {
      _save();
      // 等写盘结束再提示，保存失败时只提示失败
      _writes.whenComplete(() {
        if (!_saveFailed) {
          AppToast.show(appL10n.flowSettingsSavedLocally, tone: AppToastTone.success);
        }
      });
    }
    super.dispose();
  }

  Widget _slider(String title, String key, double min, double max,
      int divisions, String unit) {
    final value = (_settings![key] as num).toDouble();
    return GuessSliderTile(
      label: title,
      valueText: '${value.round()}$unit',
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: (value) => _change(key, value.round()),
    );
  }

  Widget _gap(int index, Widget child) => EntranceAnimation(
        index: index,
        offset: const Offset(0, 10),
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: context.l10n.featureSoloSongGameSettings,
      resizeToAvoidBottomInset: false,
      child: s == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TextButton(onPressed: _load, child: Text(_error!)))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  AppDesignTokens.gutter,
                  4,
                  AppDesignTokens.gutter,
                  MediaQuery.paddingOf(context).bottom +
                      MediaQuery.viewInsetsOf(context).bottom +
                      16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done_outlined,
                            size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.l10n.flowChangesSaveAutomaticallyAndApplyToThe,
                            style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CommonWidgetUtil.buildGuessChartSettingsWidget(
                    context,
                    _versions,
                    _genres,
                    List<String>.from(s['selectedVersions']),
                    (s['masterMinDx'] as num).toDouble(),
                    (s['masterMaxDx'] as num).toDouble(),
                    List<String>.from(s['selectedGenres']),
                    s['maxGuesses'],
                    s['timeLimit'],
                    (value) => _change('selectedVersions', value),
                    (min, max) {
                      _settings!['masterMinDx'] = min;
                      _change('masterMaxDx', max);
                    },
                    (value) => _change('selectedGenres', value),
                    (value) => _change('maxGuesses', value),
                    (value) => _change('timeLimit', value),
                    card: true,
                  ),
                  const SizedBox(height: AppDesignTokens.cardGap),
                  _gap(
                    0,
                    GuessSettingSection(
                      card: true,
                      title: context.l10n.flowSongExcerptsReverseAndSpeedPitch,
                      icon: Icons.graphic_eq_rounded,
                      children: [
                        _slider(context.l10n.flowExcerptPlaybackLength, 'playDurationSeconds', 1, 30, 29, context.l10n.flowS),
                        GuessAudioRateSlider(
                          value: (s['audioRate'] as num).toDouble(),
                          onChanged: (value) => _change('audioRate', value),
                        ),
                      ],
                    ),
                  ),
                  _gap(
                    1,
                    GuessSettingSection(
                      card: true,
                      title: context.l10n.flowChartExcerpt,
                      icon: Icons.music_note_rounded,
                      children: [
                        _slider(context.l10n.flowExcerptLength, 'peekDurationSeconds', 3, 60, 57, context.l10n.flowS),
                        ChartPeekPlaybackSettings(
                          speed: (s['peekFlowSpeed'] as num).toDouble(),
                          mirror: ChartPeekPlayback.mirrorOf(
                              s['peekMirror'] as String?),
                          onSpeedChanged: (value) =>
                              _change('peekFlowSpeed', value),
                          onMirrorChanged: (value) =>
                              _change('peekMirror', value.name),
                        ),
                        ChartPeekDifficultyPool(
                          selected: List<String>.from(s['peekDifficulties']),
                          onChanged: (pool) =>
                              _change('peekDifficulties', pool),
                        ),
                      ],
                    ),
                  ),
                  _gap(
                    2,
                    GuessSettingSection(
                      card: true,
                      title: context.l10n.flowCoverModes,
                      icon: Icons.image_outlined,
                      children: [
                        _slider(context.l10n.flowBlurredCoverBlur, 'blurLevel', 0, 100, 100, '%'),
                        _slider(context.l10n.flowPixelCoverDestruction, 'pixelationLevel', 0, 100, 100, '%'),
                        Text(context.l10n.flow0ShowsTheOriginalHigherValuesCreate,
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        _slider(context.l10n.flowFlashCoverDuration, 'flashDurationMs', 100, 3000, 29,
                            ' ms'),
                        _slider(context.l10n.flowTileRevealTileCount, 'tileCount', 100, 10000, 99, context.l10n.flowTiles),
                        _slider(context.l10n.flowTileRevealInterval, 'tileRevealIntervalMs', 100, 10000,
                            99, ' ms'),
                      ],
                    ),
                  ),
                  _gap(
                    3,
                    GuessSettingSection(
                      card: true,
                      title: context.l10n.flowRevealLetters,
                      icon: Icons.abc_rounded,
                      children: [
                        _slider(context.l10n.flowSongsPerGame, 'songCount', 1, 10, 9, context.l10n.flowSongs3),
                        _slider(context.l10n.flowNonEnglishCharacterThreshold, 'nonEnglishCharThreshold', 0, 100,
                            100, '%'),
                      ],
                    ),
                  ),
                  GuessSettingsResetButton(
                    onPressed: () {
                      setState(() => _settings = _service.defaultSettings());
                      _saveTimer?.cancel();
                      _save();
                      AppToast.show(context.l10n.flowDefaultSettingsRestored, tone: AppToastTone.success);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
