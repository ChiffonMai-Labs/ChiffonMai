import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../ui/fullscreen_utils.dart';
import '../ui/note_geometry.dart';
import '../ui/simai_colors.dart';
import '../ui/simai_game.dart';
import '../ui/simai_player.dart';
import 'gameplay_controller.dart';
import 'gameplay_models.dart';
import 'gameplay_session.dart';

class SimaiGameplayFlowPage extends StatefulWidget {
  const SimaiGameplayFlowPage({
    super.key,
    required this.controller,
    this.disposeController = true,
    this.onCompleted,
    this.onExit,
  });

  final SimaiGameplayController controller;
  final bool disposeController;
  final ValueChanged<SimaiGameplayResult>? onCompleted;
  final VoidCallback? onExit;

  @override
  State<SimaiGameplayFlowPage> createState() => _SimaiGameplayFlowPageState();
}

enum _GameplayFlowPhase { setup, gameplay, result }

class _SimaiGameplayFlowPageState extends State<SimaiGameplayFlowPage> {
  _GameplayFlowPhase _phase = _GameplayFlowPhase.setup;
  SimaiGameplayResult? _result;
  Key _gameplayKey = UniqueKey();

  @override
  void dispose() {
    if (widget.disposeController) widget.controller.dispose();
    super.dispose();
  }

  void _exit() {
    final callback = widget.onExit;
    if (callback != null) {
      callback();
    } else {
      Navigator.of(context).maybePop<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _GameplayFlowPhase.setup => SimaiGameplaySetupPage(
        controller: widget.controller,
        onStart: (settings) {
          widget.controller.updateSettings(settings);
          setState(() {
            _result = null;
            _gameplayKey = UniqueKey();
            _phase = _GameplayFlowPhase.gameplay;
          });
        },
        onBack: _exit,
      ),
      _GameplayFlowPhase.gameplay => SimaiGameplayPage(
        key: _gameplayKey,
        controller: widget.controller,
        onCompleted: (result) {
          widget.onCompleted?.call(result);
          if (!mounted) return;
          setState(() {
            _result = result;
            _phase = _GameplayFlowPhase.result;
          });
        },
        onExit: () {
          if (!mounted) return;
          setState(() => _phase = _GameplayFlowPhase.setup);
        },
      ),
      _GameplayFlowPhase.result => SimaiGameplayResultPage(
        result: _result!,
        title: widget.controller.title,
        onRetry: () {
          setState(() {
            _gameplayKey = UniqueKey();
            _phase = _GameplayFlowPhase.gameplay;
          });
        },
        onAdjustSettings: () {
          setState(() => _phase = _GameplayFlowPhase.setup);
        },
        onExit: _exit,
      ),
    };
  }
}

class SimaiGameplaySetupPage extends StatefulWidget {
  const SimaiGameplaySetupPage({
    super.key,
    required this.controller,
    required this.onStart,
    this.onBack,
  });

  final SimaiGameplayController controller;
  final ValueChanged<SimaiGameplaySettings> onStart;
  final VoidCallback? onBack;

  @override
  State<SimaiGameplaySetupPage> createState() => _SimaiGameplaySetupPageState();
}

class _SimaiGameplaySetupPageState extends State<SimaiGameplaySetupPage> {
  late SimaiGameplaySettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.controller.settings;
  }

  @override
  void didUpdateWidget(SimaiGameplaySetupPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      _settings = widget.controller.settings;
    }
  }

  void _update(SimaiGameplaySettings settings) {
    setState(() => _settings = settings.normalized());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = widget.controller.chartSummary;
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.controller.title ?? '谱面游玩设置'),
        leading: widget.onBack == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('谱面信息', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('计分 Note：${summary.totalScoringNotes}'),
                  Text('手动判定：${summary.manualNotes}'),
                  if (summary.autoAssistNotes > 0)
                    Text('AUTO ASSIST：${summary.autoAssistNotes}'),
                  if (summary.excludedNotes > 0)
                    Text('暂不计分：${summary.excludedNotes}'),
                ],
              ),
            ),
          ),
          _SliderSetting(
            title: 'Note 速度',
            value: _settings.noteSpeed,
            min: 3,
            max: 9,
            divisions: 24,
            valueLabel: _settings.noteSpeed.toStringAsFixed(2),
            onChanged: (value) => _update(_settings.copyWith(noteSpeed: value)),
          ),
          _NoteSpeedPreview(noteSpeed: _settings.noteSpeed),
          _SliderSetting(
            title: '音乐偏移',
            value: _settings.musicOffsetMs.toDouble(),
            min: -2000,
            max: 2000,
            divisions: 160,
            valueLabel: '${_settings.musicOffsetMs} ms',
            onChanged: (value) =>
                _update(_settings.copyWith(musicOffsetMs: value.round())),
          ),
          _SliderSetting(
            title: '判定偏移',
            subtitle: '正值会把输入视为更晚，可用于修正偏 Fast 的设备或习惯。',
            value: _settings.judgementOffsetMs.toDouble(),
            min: -200,
            max: 200,
            divisions: 80,
            valueLabel: '${_settings.judgementOffsetMs} ms',
            onChanged: (value) =>
                _update(_settings.copyWith(judgementOffsetMs: value.round())),
          ),
          _SliderSetting(
            title: '音乐音量',
            value: _settings.musicVolume,
            min: 0,
            max: 1,
            divisions: 20,
            valueLabel: '${(_settings.musicVolume * 100).round()}%',
            onChanged: (value) =>
                _update(_settings.copyWith(musicVolume: value)),
          ),
          SwitchListTile(
            title: const Text('打击音'),
            value: _settings.hitSoundEnabled,
            onChanged: (value) =>
                _update(_settings.copyWith(hitSoundEnabled: value)),
          ),
          _SliderSetting(
            title: '打击音音量',
            value: _settings.hitSoundVolume,
            min: 0,
            max: 1,
            divisions: 20,
            enabled: _settings.hitSoundEnabled,
            valueLabel: '${(_settings.hitSoundVolume * 100).round()}%',
            onChanged: (value) =>
                _update(_settings.copyWith(hitSoundVolume: value)),
          ),
          ListTile(
            title: const Text('镜像'),
            trailing: DropdownButton<SimaiMirrorMode>(
              value: _settings.mirrorMode,
              items: const [
                DropdownMenuItem(value: SimaiMirrorMode.none, child: Text('无')),
                DropdownMenuItem(
                  value: SimaiMirrorMode.horizontal,
                  child: Text('左右反'),
                ),
                DropdownMenuItem(
                  value: SimaiMirrorMode.vertical,
                  child: Text('上下反'),
                ),
                DropdownMenuItem(
                  value: SimaiMirrorMode.full,
                  child: Text('全反'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  _update(_settings.copyWith(mirrorMode: value));
                }
              },
            ),
          ),
          ListTile(
            title: const Text('背景显示'),
            trailing: DropdownButton<SimaiBackgroundMode>(
              value: _settings.backgroundMode,
              items: SimaiBackgroundMode.values
                  .map(
                    (mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(_backgroundModeLabel(mode)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _update(_settings.copyWith(backgroundMode: value));
                }
              },
            ),
          ),
          ListTile(
            title: const Text('判定表示'),
            subtitle: Text(_settings.judgementDisplayMode.description),
            trailing: DropdownButton<SimaiJudgementDisplayMode>(
              value: _settings.judgementDisplayMode,
              items: SimaiJudgementDisplayMode.values
                  .map(
                    (mode) =>
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _update(_settings.copyWith(judgementDisplayMode: value));
                }
              },
            ),
          ),
          ListTile(
            title: const Text('屏幕中央显示'),
            trailing: DropdownButton<SimaiGameplayCenterDisplayMode>(
              value: _settings.centerDisplayMode,
              items: SimaiGameplayCenterDisplayMode.values
                  .map(
                    (mode) =>
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _update(_settings.copyWith(centerDisplayMode: value));
                }
              },
            ),
          ),
          SwitchListTile(
            title: const Text('显示判定线'),
            value: _settings.showApproachLine,
            onChanged: (value) =>
                _update(_settings.copyWith(showApproachLine: value)),
          ),
          SwitchListTile(
            title: const Text('显示命中特效'),
            value: _settings.showHitEffects,
            onChanged: (value) =>
                _update(_settings.copyWith(showHitEffects: value)),
          ),
          SwitchListTile(
            title: const Text('显示触摸分区'),
            subtitle: const Text('显示内屏传感器与外键的判定范围'),
            value: _settings.showInputPartitions,
            onChanged: (value) =>
                _update(_settings.copyWith(showInputPartitions: value)),
          ),
          SwitchListTile(
            title: const Text('显示触摸指示'),
            subtitle: const Text('显示当前触点及其覆盖半径'),
            value: _settings.showTouchIndicators,
            onChanged: (value) =>
                _update(_settings.copyWith(showTouchIndicators: value)),
          ),
          const SizedBox(height: 12),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const ValueKey('simai_gameplay_start_button'),
              onPressed: summary.totalScoringNotes == 0
                  ? null
                  : () => widget.onStart(_settings.normalized()),
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始游玩'),
            ),
          ),
        ),
      ),
    );
  }

  static String _backgroundModeLabel(SimaiBackgroundMode mode) =>
      switch (mode) {
        SimaiBackgroundMode.none => '无',
        SimaiBackgroundMode.dots => '判定点',
        SimaiBackgroundMode.judgeLine => '判定线',
        SimaiBackgroundMode.judgeZone => '判定区',
      };
}

class SimaiGameplayPage extends StatefulWidget {
  const SimaiGameplayPage({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.onExit,
  });

  final SimaiGameplayController controller;
  final ValueChanged<SimaiGameplayResult> onCompleted;
  final VoidCallback? onExit;

  @override
  State<SimaiGameplayPage> createState() => _SimaiGameplayPageState();
}

class _SimaiGameplayPageState extends State<SimaiGameplayPage>
    with WidgetsBindingObserver {
  static const _countdownOverlay = 'countdown';
  static const _pauseOverlay = 'pause';

  late final SimaiGameplaySession _session;
  late final SimaiGame _game;
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _ready = false;
  bool _paused = false;
  bool _completed = false;
  bool _mobileImmersive = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _session = widget.controller.startSession();
    final settings = _session.settings;
    _game = SimaiGame(
      chart: widget.controller.chart,
      gameplaySession: _session,
      isPlaying: false,
      ringApproachTime: settings.approachTime,
      touchApproachTime: settings.approachTime,
      playbackRate: 1.0,
      musicVolume: settings.musicVolume,
      hitSoundVolume: settings.hitSoundVolume,
      hitSoundEnabled: settings.hitSoundEnabled,
      backgroundMode: settings.backgroundMode,
      mirrorMode: settings.mirrorMode,
      showApproachLine: settings.showApproachLine,
      showHitEffects: settings.showHitEffects,
      showGameplayInputPartitions: settings.showInputPartitions,
      showGameplayTouchIndicators: settings.showTouchIndicators,
      showAchievementRate: false,
      showCornerInfo: false,
      showFps: false,
      // Keep the judge ring at 95% of the playfield short edge. Input regions
      // may extend beyond the original square playfield up to 1.35R.
      chartRadiusRatio: 0.95,
      initialChartTime: widget.controller.initialChartTime,
      offset:
          widget.controller.initialChartTime + settings.musicOffsetMs / 1000.0,
      audioAsset: widget.controller.audioAsset,
      audioFilePath: widget.controller.audioFilePath,
      backgroundImageProvider: widget.controller.backgroundImageProvider,
      onGameplayCompleted: _handleCompleted,
    );
    _enterMobileImmersive();
    _game.loaded
        .then((_) async {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return;
          setState(() => _ready = true);
          _startCountdown();
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!mounted) return;
          setState(() => _loadError = error);
        });
  }

  Future<void> _enterMobileImmersive() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    _mobileImmersive = true;
    await FullScreenUtils.enterFullScreen();
  }

  Future<void> _exitMobileImmersive() async {
    if (!_mobileImmersive) return;
    _mobileImmersive = false;
    await FullScreenUtils.exitFullScreen();
  }

  void _startCountdown() {
    if (!_ready || _completed) return;
    _countdownTimer?.cancel();
    _game.overlays.remove(_pauseOverlay);
    _game.overlays.add(_countdownOverlay);
    setState(() {
      _paused = false;
      _countdown = 3;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _completed) {
        timer.cancel();
        return;
      }
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        _game.overlays.remove(_countdownOverlay);
        _game.setPlaying(true);
      }
    });
  }

  void _pause() {
    if (!_ready || _paused || _completed) return;
    _countdownTimer?.cancel();
    _game.setPlaying(false);
    _game.clearGameplayPointers();
    _game.overlays.remove(_countdownOverlay);
    _game.overlays.add(_pauseOverlay);
    setState(() => _paused = true);
  }

  Future<void> _handleCompleted(SimaiGameplayResult result) async {
    if (_completed) return;
    _completed = true;
    _countdownTimer?.cancel();
    widget.controller.completeSession(_session);
    await _exitMobileImmersive();
    if (!mounted) return;
    widget.onCompleted(result);
  }

  Future<void> _requestExit() async {
    if (_completed) return;
    _pause();
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出游玩？'),
        content: const Text('本次成绩不会保存。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('继续'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldExit == true) {
      _completed = true;
      widget.controller.abandonSession(_session);
      await _exitMobileImmersive();
      if (!mounted) return;
      final callback = widget.onExit;
      if (callback != null) {
        callback();
      } else {
        Navigator.of(context).maybePop<void>();
      }
    } else {
      _startCountdown();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _game.onGameplayCompleted = null;
    _game.clearGameplayPointers();
    if (!_completed) widget.controller.abandonSession(_session);
    unawaited(_exitMobileImmersive());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                Text('游玩资源加载失败：$_loadError'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed:
                      widget.onExit ?? () => Navigator.of(context).maybePop(),
                  child: const Text('返回'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestExit());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  key: const ValueKey('simai_gameplay_input_surface'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    if (event.kind == PointerDeviceKind.mouse &&
                        event.buttons != kPrimaryMouseButton) {
                      return;
                    }
                    _game.handleGameplayPointerDown(
                      pointerId: event.pointer,
                      position: event.localPosition,
                      eventTimestamp: event.timeStamp,
                    );
                  },
                  onPointerMove: (event) => _game.handleGameplayPointerMove(
                    pointerId: event.pointer,
                    position: event.localPosition,
                    eventTimestamp: event.timeStamp,
                  ),
                  onPointerUp: (event) => _game.handleGameplayPointerUp(
                    pointerId: event.pointer,
                    eventTimestamp: event.timeStamp,
                  ),
                  onPointerCancel: (event) => _game.handleGameplayPointerUp(
                    pointerId: event.pointer,
                    eventTimestamp: event.timeStamp,
                  ),
                  child: GameWidget<SimaiGame>(
                    game: _game,
                    loadingBuilder: (context) {
                      final colorScheme = Theme.of(context).colorScheme;
                      return ColoredBox(
                        color: colorScheme.surface,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    overlayBuilderMap: {
                      _countdownOverlay: (context, game) =>
                          _CountdownOverlay(value: _countdown),
                      _pauseOverlay: (context, game) => _PauseOverlay(
                        onResume: _startCountdown,
                        onExit: _requestExit,
                      ),
                    },
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton.filledTonal(
                  tooltip: '暂停',
                  onPressed: _ready && !_paused ? _pause : null,
                  icon: const Icon(Icons.pause),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SimaiGameplayResultPage extends StatelessWidget {
  const SimaiGameplayResultPage({
    super.key,
    required this.result,
    this.title,
    this.onRetry,
    this.onAdjustSettings,
    this.onExit,
  });

  final SimaiGameplayResult result;
  final String? title;
  final VoidCallback? onRetry;
  final VoidCallback? onAdjustSettings;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final achievementColor = isLight
        ? const Color(0xFFD97706)
        : const Color(0xFFFFD54F);
    final touchGroupColor = isLight
        ? const Color(0xFF00897B)
        : const Color(0xFF80CBC4);
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(title ?? '游玩结算'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (result.isAutoAssisted)
            Card(
              color: colorScheme.tertiaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'AUTO ASSIST：${result.autoAssistCount} 个 Note 自动判定',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '${_clearTypeLabel(result.clearType)}${result.isAutoAssisted ? ' · AUTO' : ''}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${result.achievement.toStringAsFixed(4)}%',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: achievementColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('DX SCORE  ${result.dxScore} / ${result.totalDxScore}'),
                  Text('MAX COMBO  ${result.maxCombo}'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: SimaiJudgeGrade.values
                    .map(
                      (grade) => _ResultRow(
                        label: _gradeLabel(grade),
                        value: result.countForGrade(grade).toString(),
                        color: _gradeColor(grade, theme.brightness),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ResultRow(
                    label: 'FAST',
                    value: result.fastCount.toString(),
                    color: const Color(0xFF42A5F5),
                  ),
                  _ResultRow(
                    label: 'LATE',
                    value: result.lateCount.toString(),
                    color: const Color(0xFFEF5350),
                  ),
                  _ResultRow(
                    label: '平均手动偏差',
                    value:
                        '${result.averageManualOffsetMs >= 0 ? '+' : ''}${result.averageManualOffsetMs.toStringAsFixed(2)} ms',
                  ),
                  if (result.touchGroupAssistCount > 0)
                    _ResultRow(
                      label: 'TOUCH GROUP',
                      value: result.touchGroupAssistCount.toString(),
                      color: touchGroupColor,
                    ),
                  _ResultRow(
                    label: '判定表示',
                    value: result.settings.judgementDisplayMode.label,
                  ),
                  _ResultRow(
                    label: '中央显示',
                    value: result.settings.centerDisplayMode.label,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay),
                  label: const Text('再次游玩'),
                ),
              if (onAdjustSettings != null)
                OutlinedButton.icon(
                  onPressed: onAdjustSettings,
                  icon: const Icon(Icons.tune),
                  label: const Text('调整设置'),
                ),
              if (onExit != null)
                TextButton(onPressed: onExit, child: const Text('退出')),
            ],
          ),
        ],
      ),
    );
  }

  static String _clearTypeLabel(SimaiGameplayClearType type) => switch (type) {
    SimaiGameplayClearType.failed => 'FAILED',
    SimaiGameplayClearType.clear => 'CLEAR',
    SimaiGameplayClearType.fullCombo => 'FULL COMBO',
    SimaiGameplayClearType.fullComboPlus => 'FULL COMBO+',
    SimaiGameplayClearType.allPerfect => 'ALL PERFECT',
    SimaiGameplayClearType.allPerfectPlus => 'ALL PERFECT+',
  };

  static String _gradeLabel(SimaiJudgeGrade grade) => switch (grade) {
    SimaiJudgeGrade.criticalPerfect => 'CRITICAL PERFECT',
    SimaiJudgeGrade.perfect => 'PERFECT',
    SimaiJudgeGrade.great => 'GREAT',
    SimaiJudgeGrade.good => 'GOOD',
    SimaiJudgeGrade.miss => 'MISS',
  };

  static Color _gradeColor(SimaiJudgeGrade grade, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return switch (grade) {
      SimaiJudgeGrade.criticalPerfect =>
        isLight ? const Color(0xFFD97706) : const Color(0xFFFFD54F),
      SimaiJudgeGrade.perfect =>
        isLight ? const Color(0xFFCA8A04) : const Color(0xFFFFC107),
      SimaiJudgeGrade.great =>
        isLight ? const Color(0xFFD81B60) : const Color(0xFFEC6BAA),
      SimaiJudgeGrade.good =>
        isLight ? const Color(0xFF2E7D32) : const Color(0xFF66BB6A),
      SimaiJudgeGrade.miss =>
        isLight ? const Color(0xFF616161) : const Color(0xFFBDBDBD),
    };
  }
}

class _NoteSpeedPreview extends StatefulWidget {
  const _NoteSpeedPreview({required this.noteSpeed});

  final double noteSpeed;

  @override
  State<_NoteSpeedPreview> createState() => _NoteSpeedPreviewState();
}

class _NoteSpeedPreviewState extends State<_NoteSpeedPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animationsDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    if (disabled) {
      _controller.stop();
    } else {
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void didUpdateWidget(_NoteSpeedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteSpeed == widget.noteSpeed) return;
    if (!_animationsDisabled) {
      _controller
        ..reset()
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canvasShortSide = MediaQuery.of(context).size.shortestSide;
    final chartRadius = canvasShortSide / 2 * 0.95;
    final safeSpeed = (widget.noteSpeed.isFinite ? widget.noteSpeed : 8.0)
        .clamp(3.0, 9.0)
        .toDouble();
    final pixelsPerSecond = chartRadius * safeSpeed / 3.6;
    final gameplayNoteScale = chartRadius / NoteGeometry.referenceChartRadius;
    final gameplayTapDiameter =
        NoteGeometry.tapStarHoldRadius * 2 * gameplayNoteScale;
    final previewHeight = (gameplayTapDiameter + 32).clamp(96.0, 160.0);
    final previewNoteScale = min(
      gameplayNoteScale,
      (previewHeight - 24) / (NoteGeometry.tapStarHoldRadius * 2),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Semantics(
        key: const ValueKey('simai_note_speed_preview'),
        container: true,
        label:
            'Note 速度预览，当前 ${widget.noteSpeed.toStringAsFixed(2)}，'
            '实际游玩速度 ${pixelsPerSecond.round()} 像素每秒',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '预览 · 实际游玩速度 ${pixelsPerSecond.round()} px/s',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: RepaintBoundary(
                  child: SizedBox(
                    width: double.infinity,
                    height: previewHeight,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => CustomPaint(
                        painter: _NoteSpeedPreviewPainter(
                          elapsedSeconds:
                              (_controller.lastElapsedDuration ?? Duration.zero)
                                  .inMicroseconds /
                              Duration.microsecondsPerSecond,
                          pixelsPerSecond: pixelsPerSecond,
                          noteScale: previewNoteScale,
                          staticPreview: _animationsDisabled,
                          colorScheme: theme.colorScheme,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteSpeedPreviewPainter extends CustomPainter {
  const _NoteSpeedPreviewPainter({
    required this.elapsedSeconds,
    required this.pixelsPerSecond,
    required this.noteScale,
    required this.staticPreview,
    required this.colorScheme,
  });

  final double elapsedSeconds;
  final double pixelsPerSecond;
  final double noteScale;
  final bool staticPreview;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final outerRadius = NoteGeometry.tapStarHoldRadius * noteScale;
    if (outerRadius <= 0 || size.width <= 0) return;

    final trackPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = max(1.5, noteScale * 2)
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.72);
    canvas.drawLine(
      Offset(outerRadius, centerY),
      Offset(size.width - outerRadius, centerY),
      trackPaint,
    );

    final travelDistance = size.width + outerRadius * 2;
    final centerX = staticPreview
        ? size.width / 2
        : (elapsedSeconds * pixelsPerSecond) % travelDistance - outerRadius;
    final position = Offset(centerX, centerY);
    const innerRatio = 0.65;
    final innerRadius = outerRadius * innerRatio;
    final tapPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = SimaiColors.tapNormal;
    final tapPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: position, radius: outerRadius))
      ..addOval(Rect.fromCircle(center: position, radius: innerRadius));
    canvas.drawPath(tapPath, tapPaint);

    final outlinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, 2.0 * noteScale)
      ..color = Colors.white;
    canvas.drawCircle(position, outerRadius, outlinePaint);
    canvas.drawCircle(position, innerRadius, outlinePaint);
    canvas.drawCircle(position, 4.0 * noteScale, tapPaint);
  }

  @override
  bool shouldRepaint(_NoteSpeedPreviewPainter oldDelegate) =>
      oldDelegate.elapsedSeconds != elapsedSeconds ||
      oldDelegate.pixelsPerSecond != pixelsPerSecond ||
      oldDelegate.noteScale != noteScale ||
      oldDelegate.staticPreview != staticPreview ||
      oldDelegate.colorScheme != colorScheme;
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) Text(subtitle!),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: valueLabel,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
              SizedBox(width: 72, child: Text(valueLabel)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.38),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            shadows: const [Shadow(color: Colors.black, blurRadius: 12)],
          ),
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onExit});

  final VoidCallback onResume;
  final Future<void> Function() onExit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.94),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle, size: 56, color: colorScheme.primary),
            const SizedBox(height: 16),
            FilledButton(onPressed: onResume, child: const Text('继续游玩')),
            TextButton(
              onPressed: () => unawaited(onExit()),
              child: const Text('退出'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: color)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
