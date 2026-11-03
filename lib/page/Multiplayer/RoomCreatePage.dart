import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/entity/Multiplayer/GameType.dart';
import 'package:my_first_flutter_app/manager/MultiplayerManager.dart';
import 'package:my_first_flutter_app/utils/CommonWidgetUtil.dart';
import 'package:my_first_flutter_app/utils/SongFilterUtil.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/GuessChartByInfoService.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/GuessChartCommonSettingsService.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppToast.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/ChartPeekPlaybackUi.dart';
import '../../widgets/GuessAudioRateSlider.dart';
import '../../widgets/GuessSettingsUi.dart';
import 'package:simai_flutter/simai_flutter.dart';

class RoomCreatePage extends StatefulWidget {
  const RoomCreatePage({super.key});

  @override
  State<RoomCreatePage> createState() => _RoomCreatePageState();
}

class _RoomCreatePageState extends State<RoomCreatePage> {
  final MultiplayerManager _manager = MultiplayerManager();

  // 游戏类型
  GameType _gameType = GameType.info;

  // 房间基础设置
  int _maxPlayers = 4;
  int _timeLimit = 60;
  int _maxGuesses = 10;

  // 歌曲筛选设置
  List<String> _selectedVersions = [];
  double _masterMinDx = 1.0;
  double _masterMaxDx = 15.0;
  List<String> _selectedGenres = [];

  // 模式专属设置
  int _blurLevel = 50; // 模糊程度 (blurred 模式)
  double _audioRate = 1.25;
  int _playDuration = 5; // 音频播放时长秒 (audio 模式)
  int _songCount = 3; // 抽取歌曲数 (letters 模式)
  int _nonEnglishCharThreshold = 50; // 非英文字符过滤阈值 (letters 模式)
  int _flashDurationMs = 300; // 快闪时长毫秒 (flash 模式)
  int _tileCount = 1000; // 拼图切块数 (tileReveal 模式)
  int _tileRevealIntervalMs = 1500; // 拼图揭示间隔毫秒 (tileReveal 模式)
  int _peekDurationSeconds = 8; // 谱面片段时长秒 (chartPeek 模式)
  List<String> _peekDifficulties = ['4']; // 谱面难度随机池 (chartPeek 模式)
  double _peekFlowSpeed =
      GuessChartCommonSettingsService.defaultPeekFlowSpeed; // 谱面流速 (chartPeek 模式)
  SimaiMirrorMode _peekMirror = SimaiMirrorMode.none; // 谱面镜像 (chartPeek 模式)

  /// 房间可选的变速变调倍率（服务端只接受 0.5～1.5）。
  static const List<double> _audioRates = [.65, .75, .85, 1.15, 1.25, 1.35, 1.5];

  // 所有版本和流派列表
  List<String> _allVersions = [];
  List<String> _allGenres = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadModeDefaults();
    _loadSongData();
  }

  /// 模式专属滑条的初始值取「已保存的单人猜歌设置」。
  ///
  /// 为什么要有这一步：单人「曲绘拼图/快闪/谱面片段」的设置和多人房间的参数
  /// 是两套（房间参数随房间走、由房主决定），但如果房间滑条永远从硬编码默认值
  /// 起步，用户刚在单人设置里把拼图调成 2500 块、进房间却看到 1000，
  /// 看起来就像「设置没生效/没同步」。这里只把它当**初值**，
  /// 房间真正的取值仍以房主在本页的设定为准（不会回写单人设置）。
  Future<void> _loadModeDefaults() async {
    try {
      final settings = await GuessChartCommonSettingsService().loadSettings();
      if (!mounted) return;
      setState(() => _applySettings(settings));
      debugPrint('[DEBUG][RoomCreatePage] 模式专属默认值已从单人设置载入: '
          'tileCount=$_tileCount, tileRevealIntervalMs=$_tileRevealIntervalMs, '
          'flashDurationMs=$_flashDurationMs, peekDurationSeconds=$_peekDurationSeconds');
    } catch (e) {
      debugPrint('[DEBUG][RoomCreatePage] 读取单人设置失败（沿用默认值）: $e');
    }
  }

  void _applySettings(Map<String, dynamic> settings) {
    // 房间倍率只有固定几档，单人设置里的自定义倍率取最接近的一档
    final rate = (settings['audioRate'] as num?)?.toDouble() ?? 1.25;
    _audioRate = _audioRates.reduce(
        (a, b) => (a - rate).abs() <= (b - rate).abs() ? a : b);
    _timeLimit = settings['timeLimit'] ?? _timeLimit;
    _maxGuesses = settings['maxGuesses'] ?? _maxGuesses;
    _selectedVersions = List<String>.from(settings['selectedVersions'] ?? []);
    _selectedGenres = List<String>.from(settings['selectedGenres'] ?? []);
    _masterMinDx = (settings['masterMinDx'] as num?)?.toDouble() ?? 1;
    _masterMaxDx = (settings['masterMaxDx'] as num?)?.toDouble() ?? 15;
    _blurLevel = (settings['blurLevel'] ?? _blurLevel).clamp(0, 100);
    _playDuration =
        (settings['playDurationSeconds'] ?? _playDuration).clamp(1, 30);
    _songCount = (settings['songCount'] ?? _songCount).clamp(1, 10);
    _nonEnglishCharThreshold =
        (settings['nonEnglishCharThreshold'] ?? _nonEnglishCharThreshold)
            .clamp(0, 100);
    _flashDurationMs =
        (settings['flashDurationMs'] ?? _flashDurationMs).clamp(100, 3000);
    _tileCount = (settings['tileCount'] ?? _tileCount).clamp(100, 10000);
    _tileRevealIntervalMs =
        (settings['tileRevealIntervalMs'] ?? _tileRevealIntervalMs)
            .clamp(100, 10000);
    _peekDurationSeconds =
        (settings['peekDurationSeconds'] ?? _peekDurationSeconds).clamp(3, 60);
    final pool = (settings['peekDifficulties'] as List?)?.cast<String>();
    if (pool != null && pool.isNotEmpty) {
      _peekDifficulties = List<String>.from(pool);
    }
    _peekFlowSpeed =
        (settings['peekFlowSpeed'] as num?)?.toDouble() ?? _peekFlowSpeed;
    _peekMirror =
        ChartPeekPlayback.mirrorOf(settings['peekMirror'] as String?);
  }

  void _resetSettings() {
    setState(() {
      _applySettings(GuessChartCommonSettingsService().defaultSettings());
      _maxPlayers = 4;
    });
    AppToast.show('已恢复默认设置');
  }

  Future<void> _loadSongData() async {
    setState(() => _isLoading = true);
    try {
      final allSongs = await GuessChartByInfoService.loadAllSongs();
      if (allSongs != null) {
        // 可选版本 / 可选流派统一走 SongFilterUtil.selectableFilters：
        // 它先剔除非正曲（SongFilterUtil.isExtra：宴会场 / maidata 追加 /
        // union 独有），再单独挡掉「宴会场」流派，最后把版本过一遍官方世代
        // 白名单并按世代排序。口径与抽曲池一致，否则列表里会出现
        // 勾了也永远抽不到的版本 / 流派（表现为「没有找到符合条件的乐曲」）。
        final SongFilterOptions filterOptions =
            SongFilterUtil.selectableFilters(allSongs);
        _allVersions = filterOptions.versions;
        _allGenres = filterOptions.genres;
      }
    } catch (e) {
      debugPrint('[ERROR][RoomCreatePage] 加载歌曲数据失败: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreateRoom() async {
    if (_isCreating) return;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isCreating = true);

    try {
      debugPrint(
          '[DEBUG][RoomCreatePage] 创建房间 - 选择的游戏模式: ${_gameType.name} (${_gameType.description})');

      final room = await _manager.createRoom(
        gameType: _gameType,
        maxPlayers: _maxPlayers,
        timeLimit: _timeLimit,
        maxGuesses: _maxGuesses,
        selectedVersions: _selectedVersions,
        masterMinDx: _masterMinDx,
        masterMaxDx: _masterMaxDx,
        selectedGenres: _selectedGenres,
        blurLevel: _blurLevel,
        playDuration: _playDuration,
        audioRate: _audioRate,
        songCount: _songCount,
        nonEnglishCharThreshold: _nonEnglishCharThreshold,
        flashDurationMs: _flashDurationMs,
        tileCount: _tileCount,
        tileRevealIntervalMs: _tileRevealIntervalMs,
        peekDurationSeconds: _peekDurationSeconds,
        peekDifficulties: _peekDifficulties,
        peekFlowSpeed: _peekFlowSpeed,
        peekMirror: _peekMirror.name,
      );

      if (!mounted) return;
      if (room != null) {
        Navigator.pop(context, room);
      } else {
        AppToast.show('创建房间失败');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show('创建房间失败: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  /// 当前游戏模式是否需要模式专属设置
  bool get _needsModeSettings {
    return _gameType == GameType.blurred ||
        _gameType.isAudio ||
        _gameType == GameType.letters ||
        _gameType == GameType.flash ||
        _gameType == GameType.tileReveal ||
        _gameType == GameType.chartPeek;
  }

  static IconData _iconOf(GameType type) => switch (type) {
        GameType.info => Icons.quiz_rounded,
        GameType.cover => Icons.image_rounded,
        GameType.blurred => Icons.blur_on_rounded,
        GameType.reverseAudio => Icons.history_rounded,
        GameType.pitchAudio => Icons.speed_rounded,
        GameType.audio => Icons.graphic_eq_rounded,
        GameType.alia => Icons.sell_rounded,
        GameType.letters => Icons.abc_rounded,
        GameType.flash => Icons.flash_on_rounded,
        GameType.tileReveal => Icons.grid_on_rounded,
        GameType.chartPeek => Icons.music_note_rounded,
      };

  /// 单个游戏模式：选中时实心主题色，点一下就切换。
  Widget _buildGameTypeCard(GameType type) {
    final scheme = Theme.of(context).colorScheme;
    final selected = type == _gameType;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.fastMotion);
    return PressScale(
      scale: 0.97,
      child: Semantics(
        button: true,
        selected: selected,
        label: type.name,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: selected || _isCreating
              ? null
              : () => setState(() => _gameType = type),
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            ),
            child: Row(
              children: [
                Icon(_iconOf(type),
                    size: 20,
                    color: selected ? scheme.onPrimary : scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type.name,
                    maxLines: 2,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 当前模式专属的设置项。
  List<Widget> _buildModeTiles() {
    Widget slider(
      String label,
      int value,
      double min,
      double max,
      int divisions,
      String suffix,
      void Function(int) onChanged,
    ) =>
        GuessSliderTile(
          label: label,
          valueText: '$value$suffix',
          value: value.toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: (v) => setState(() => onChanged(v.round())),
        );
    return [
      if (_gameType == GameType.blurred)
        slider('模糊程度', _blurLevel, 0, 100, 100, '%', (v) => _blurLevel = v),
      if (_gameType.isAudio)
        slider('播放时长', _playDuration, 1, 30, 29, ' 秒',
            (v) => _playDuration = v),
      if (_gameType == GameType.pitchAudio)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('变速变调倍率', style: TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rate in _audioRates)
                  GuessChoicePill(
                    label: GuessAudioRateSlider.labelOf(rate),
                    selected: rate == _audioRate,
                    onTap: () => setState(() => _audioRate = rate),
                  ),
              ],
            ),
          ],
        ),
      if (_gameType == GameType.letters) ...[
        slider('每次抽取歌曲数', _songCount, 1, 10, 9, ' 首', (v) => _songCount = v),
        slider('非英文字符过滤阈值', _nonEnglishCharThreshold, 0, 100, 100, '%',
            (v) => _nonEnglishCharThreshold = v),
      ],
      if (_gameType == GameType.flash)
        // 100ms 步进
        slider('快闪时长', _flashDurationMs, 100, 3000, 29, ' ms',
            (v) => _flashDurationMs = (v / 100).round() * 100),
      if (_gameType == GameType.tileReveal) ...[
        slider('切块数量', _tileCount, 100, 10000, 99, ' 块', (v) => _tileCount = v),
        slider('揭示间隔', _tileRevealIntervalMs, 100, 10000, 99, ' ms',
            (v) => _tileRevealIntervalMs = (v / 100).round() * 100),
      ],
      if (_gameType == GameType.chartPeek) ...[
        slider('片段时长', _peekDurationSeconds, 3, 60, 57, ' 秒',
            (v) => _peekDurationSeconds = v),
        ChartPeekPlaybackSettings(
          speed: _peekFlowSpeed,
          mirror: _peekMirror,
          onSpeedChanged: (value) => setState(() => _peekFlowSpeed = value),
          onMirrorChanged: (value) => setState(() => _peekMirror = value),
        ),
        // 池内每个难度各自的定数落在房间定数范围内即可入选
        ChartPeekDifficultyPool(
          selected: _peekDifficulties,
          onChanged: (pool) => setState(() => _peekDifficulties = pool),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const gap = SizedBox(height: AppDesignTokens.cardGap);
    final motion =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return BackgroundPageScaffold(
      title: '创建房间',
      resizeToAvoidBottomInset: false,
      actions: [
        IconButton(
          tooltip: '恢复默认设置',
          onPressed: _isCreating ? null : _resetSettings,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        AppDesignTokens.gutter,
                        4,
                        AppDesignTokens.gutter,
                        AppDesignTokens.gutter +
                            MediaQuery.viewInsetsOf(context).bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GuessSettingSection(
                          card: true,
                          title: '游戏模式',
                          icon: Icons.sports_esports_rounded,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // 两个一行；窄屏自动退成一列
                                const spacing = 8.0;
                                final width = constraints.maxWidth >= 300
                                    ? (constraints.maxWidth - spacing) / 2
                                    : constraints.maxWidth;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: [
                                    for (final type in GameType.values)
                                      SizedBox(
                                        width: width,
                                        child: _buildGameTypeCard(type),
                                      ),
                                  ],
                                );
                              },
                            ),
                            AnimatedSize(
                              duration: motion,
                              curve: AppDesignTokens.emphasizedCurve,
                              alignment: Alignment.topCenter,
                              child: FadeSwitcher(
                                value: _gameType,
                                sizeFollowsCurrent: true,
                                child: Text(
                                  _gameType.description,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        gap,
                        GuessSettingSection(
                          card: true,
                          title: '最大玩家数',
                          icon: Icons.group_rounded,
                          children: [
                            SegmentedTabs(
                              height: 42,
                              items: const [
                                SegmentedTabItem('2 人'),
                                SegmentedTabItem('3 人'),
                                SegmentedTabItem('4 人'),
                                SegmentedTabItem('5 人'),
                                SegmentedTabItem('6 人'),
                              ],
                              selectedIndex: _maxPlayers - 2,
                              onChanged: (index) =>
                                  setState(() => _maxPlayers = index + 2),
                            ),
                          ],
                        ),
                        // 切模式时这张卡片跟着伸缩，没有专属设置的模式就收起
                        AnimatedSize(
                          duration: motion,
                          curve: AppDesignTokens.emphasizedCurve,
                          alignment: Alignment.topCenter,
                          child: _needsModeSettings
                              ? Padding(
                                  padding: const EdgeInsets.only(
                                      top: AppDesignTokens.cardGap),
                                  child: GuessSettingSection(
                                    card: true,
                                    title: '${_gameType.name}设置',
                                    icon: _iconOf(_gameType),
                                    children: _buildModeTiles(),
                                  ),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                        gap,
                        CommonWidgetUtil.buildGuessChartSettingsWidget(
                          context,
                          _allVersions,
                          _allGenres,
                          _selectedVersions,
                          _masterMinDx,
                          _masterMaxDx,
                          _selectedGenres,
                          _maxGuesses,
                          _timeLimit,
                          (versions) =>
                              setState(() => _selectedVersions = versions),
                          (min, max) => setState(() {
                            _masterMinDx = min;
                            _masterMaxDx = max;
                          }),
                          (genres) => setState(() => _selectedGenres = genres),
                          (guesses) => setState(() => _maxGuesses = guesses),
                          (time) => setState(() => _timeLimit = time),
                          card: true,
                        ),
                      ],
                    ),
                  ),
                ),
                BottomActionBar(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _isCreating ? null : _handleCreateRoom,
                          child: _isCreating
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : const Text(
                                  '创建房间',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
