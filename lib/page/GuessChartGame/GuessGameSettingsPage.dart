import 'dart:async';
import 'package:flutter/material.dart';
import '../../service/GuessChartGame/GuessChartCommonSettingsService.dart';
import '../../service/GuessChartGame/GuessChartByInfoService.dart';
import '../../utils/CommonWidgetUtil.dart';
import '../../utils/SongFilterUtil.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/ColorUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/NoRipple.dart';
import '../../widgets/GuessAudioRateSlider.dart';

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
      if (mounted) setState(() => _error = '设置加载失败，请重试');
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
              songCount: s['songCount'],
              nonEnglishCharThreshold: s['nonEnglishCharThreshold'],
              flashDurationMs: s['flashDurationMs'],
              tileCount: s['tileCount'],
              tileRevealIntervalMs: s['tileRevealIntervalMs'],
              peekDurationSeconds: s['peekDurationSeconds'],
              peekDifficulties: List<String>.from(s['peekDifficulties']),
              playDurationSeconds: s['playDurationSeconds'],
              audioRate: (s['audioRate'] as num).toDouble(),
            ))
        .catchError((Object error) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('设置保存失败，请重试')));
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_settings != null) _save();
    super.dispose();
  }

  Widget _slider(String title, String key, double min, double max,
      int divisions, String unit) {
    final value = (_settings![key] as num).toDouble().clamp(min, max);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text(title)),
            Text('${value.round()}$unit',
                style: const TextStyle(fontWeight: FontWeight.w600))
          ]),
          Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (value) => _change(key, value.round())),
        ]));
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      NoRipple(
          child: ExpansionTile(
        initiallyExpanded: true,
        // 收起后保留控件状态，避免再次展开时重建输入与筛选区域。
        maintainState: true,
        expansionAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : const AnimationStyle(
                duration: Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                reverseCurve: Curves.easeInOutCubic,
              ),
        leading: Icon(icon),
        title: Text(title),
        shape: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
        collapsedShape: Border(
            bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
        children: children,
      ));

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return BackgroundPageScaffold(
      title: '单人猜歌游戏设置',
      resizeToAvoidBottomInset: false,
      child: s == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : TextButton(onPressed: _load, child: Text(_error!)))
          : ListView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 16),
              children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text('修改会自动保存，并在下一局单人游戏中生效。',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant))),
                  _section('共用设置', Icons.tune, [
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
                    )
                  ]),
                  _section('歌曲片段、倒放与变速变调', Icons.graphic_eq, [
                    _slider('片段播放时长', 'playDurationSeconds', 1, 30, 29, ' 秒'),
                    GuessAudioRateSlider(
                      value: (s['audioRate'] as num).toDouble(),
                      onChanged: (value) => _change('audioRate', value),
                    ),
                  ]),
                  _section('模糊曲绘', Icons.blur_on,
                      [_slider('模糊程度', 'blurLevel', 0, 100, 100, '%')]),
                  _section('开字母', Icons.text_fields, [
                    _slider('每次抽取歌曲数', 'songCount', 1, 10, 9, ' 首'),
                    _slider('非英文字符过滤阈值', 'nonEnglishCharThreshold', 0, 100, 100,
                        '%'),
                  ]),
                  _section('曲绘快闪', Icons.flash_on, [
                    _slider('快闪时长', 'flashDurationMs', 100, 3000, 29, ' ms')
                  ]),
                  _section('曲绘拼图', Icons.grid_on, [
                    _slider('切块数量', 'tileCount', 100, 10000, 99, ' 块'),
                    _slider(
                        '揭示间隔', 'tileRevealIntervalMs', 100, 10000, 99, ' ms'),
                  ]),
                  _section('谱面片段', Icons.music_note, [
                    _slider('片段时长', 'peekDurationSeconds', 3, 60, 57, ' 秒'),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: NoRipple(
                            child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: ChartDifficulty.standardIndices
                                    .map((index) {
                                  final inote =
                                      '${ChartDifficulty.toMaidataIndex(index)}';
                                  final selected =
                                      (s['peekDifficulties'] as List)
                                          .contains(inote);
                                  final color = ColorUtil.getCardColor(index);
                                  final foreground =
                                      ThemeData.estimateBrightnessForColor(
                                                  color) ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.black87;
                                  return FilterChip(
                                    label: Text(ChartDifficulty.labelOf(index)),
                                    selected: selected,
                                    selectedColor: color,
                                    checkmarkColor: foreground,
                                    labelStyle: TextStyle(
                                        color: selected
                                            ? foreground
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface),
                                    side: BorderSide(
                                        color: selected
                                            ? color
                                            : Theme.of(context)
                                                .colorScheme
                                                .outlineVariant),
                                    onSelected: (selected) {
                                      final pool = List<String>.from(
                                          s['peekDifficulties']);
                                      final inote =
                                          '${ChartDifficulty.toMaidataIndex(index)}';
                                      selected
                                          ? pool.add(inote)
                                          : pool.remove(inote);
                                      if (pool.isNotEmpty)
                                        _change('peekDifficulties', pool);
                                    },
                                  );
                                }).toList()))),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('恢复默认设置'),
                      onPressed: () {
                        setState(() => _settings = _service.defaultSettings());
                        _saveTimer?.cancel();
                        _save();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已恢复默认设置')));
                      },
                    ),
                  ),
                ]),
    );
  }
}
