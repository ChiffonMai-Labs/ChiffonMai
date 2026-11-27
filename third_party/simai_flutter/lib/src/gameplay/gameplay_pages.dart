import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../audio/soloud_audio_player.dart';
import '../ui/fullscreen_utils.dart';
import '../ui/note_geometry.dart';
import '../ui/note_style.dart';
import '../ui/simai_colors.dart';
import '../ui/simai_game.dart';
import '../ui/simai_visual_tokens.dart';
import '../ui/simai_player.dart';
import 'gameplay_controller.dart';
import 'gameplay_models.dart';
import 'gameplay_session.dart';

String _formatSignedMs(int value) => value > 0 ? '+$value ms' : '$value ms';

String _formatSignedDecimalMs(double value) =>
    '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)} ms';

class SimaiGameplayFlowPage extends StatefulWidget {
  const SimaiGameplayFlowPage({
    super.key,
    required this.controller,
    this.disposeController = true,
    this.onCompleted,
    this.onExit,
    this.onEnterGameplay,
    this.onExitGameplay,
  });

  final SimaiGameplayController controller;
  final bool disposeController;
  final ValueChanged<SimaiGameplayResult>? onCompleted;
  final VoidCallback? onExit;
  final Future<void> Function()? onEnterGameplay;
  final Future<void> Function()? onExitGameplay;

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
        onEnterGameplay: widget.onEnterGameplay,
        onExitGameplay: widget.onExitGameplay,
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
        controller: widget.controller,
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

  Future<void> _openCalibrationWizard() async {
    final recommendedOffset = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _LatencyCalibrationDialog(
        currentOffsetMs: _settings.judgementOffsetMs,
        volume: _settings.hitSoundVolume,
      ),
    );
    if (!mounted || recommendedOffset == null) return;
    final updated = _settings
        .copyWith(judgementOffsetMs: recommendedOffset)
        .normalized();
    _update(updated);
    // 一键应用后立即写回控制器，便于宿主层同步持久化。
    widget.controller.updateSettings(updated);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('判定偏移已更新为 ${_formatSignedMs(updated.judgementOffsetMs)}'),
      ),
    );
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
          _NoteSpeedPreview(
            noteSpeed: _settings.noteSpeed,
            chartScale: _settings.chartScale,
            noteStyle: _settings.noteStyle,
          ),
          _SliderSetting(
            title: '音乐偏移',
            subtitle: '负值推迟音符以对齐延迟音频（修 Late），正值提前音符（修 Fast）',
            value: _settings.musicOffsetMs.toDouble(),
            min: -2000,
            max: 2000,
            divisions: 800,
            valueLabel: _formatSignedMs(_settings.musicOffsetMs),
            onChanged: (value) =>
                _update(_settings.copyWith(musicOffsetMs: value.round())),
          ),
          _OffsetNudgeRow(
            deltas: const [-50, -10, -5, 5, 10, 50],
            onNudge: (delta) => _update(
              _settings.copyWith(
                musicOffsetMs: (_settings.musicOffsetMs + delta).clamp(
                  -2000,
                  2000,
                ),
              ),
            ),
          ),
          _SliderSetting(
            title: '判定偏移',
            subtitle: '偏 Late 往负调（-），偏 Fast 往正调（+）',
            value: _settings.judgementOffsetMs.toDouble(),
            min: -500,
            max: 500,
            divisions: 200,
            valueLabel: _formatSignedMs(_settings.judgementOffsetMs),
            onChanged: (value) =>
                _update(_settings.copyWith(judgementOffsetMs: value.round())),
          ),
          _OffsetNudgeRow(
            deltas: const [-10, -5, 5, 10],
            onNudge: (delta) => _update(
              _settings.copyWith(
                judgementOffsetMs: (_settings.judgementOffsetMs + delta).clamp(
                  -500,
                  500,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: OutlinedButton.icon(
              onPressed: _openCalibrationWizard,
              icon: const Icon(Icons.timer_outlined),
              label: const Text('音频/触控延迟校准向导'),
            ),
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
            title: const Text('正解音（推荐，预调度与音乐零相对延迟）'),
            value: _settings.answerSoundEnabled,
            onChanged: (value) =>
                _update(_settings.copyWith(answerSoundEnabled: value)),
          ),
          SwitchListTile(
            title: const Text('打击音（按击触发，外放/蓝牙存在设备延迟）'),
            value: _settings.hitSoundEnabled,
            onChanged: (value) =>
                _update(_settings.copyWith(hitSoundEnabled: value)),
          ),
          _SliderSetting(
            title: '音效音量',
            value: _settings.hitSoundVolume,
            min: 0,
            max: simaiMaxHitSoundVolume,
            divisions: 60,
            enabled: _settings.answerSoundEnabled || _settings.hitSoundEnabled,
            valueLabel: '${(_settings.hitSoundVolume * 100).round()}%',
            onChanged: (value) =>
                _update(_settings.copyWith(hitSoundVolume: value)),
          ),
          _SliderSetting(
            title: '滑星触控灵敏度（接触半径）',
            value: _settings.contactRadiusScale,
            min: 0.8,
            max: 1.6,
            divisions: 16,
            valueLabel: '${(_settings.contactRadiusScale * 100).round()}%',
            onChanged: (value) =>
                _update(_settings.copyWith(contactRadiusScale: value)),
          ),
          _SliderSetting(
            title: '盘面大小',
            value: _settings.chartScale,
            min: 0.75,
            max: 0.95,
            divisions: 20,
            valueLabel: '${(_settings.chartScale * 100).round()}%',
            onChanged: (value) =>
                _update(_settings.copyWith(chartScale: value)),
          ),
          _SliderSetting(
            title: '背景透明度',
            value: _settings.backgroundOpacity,
            min: 0.0,
            max: 1.0,
            divisions: 100,
            valueLabel: '${(_settings.backgroundOpacity * 100).round()}%',
            onChanged: (value) =>
                _update(_settings.copyWith(backgroundOpacity: value)),
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
            title: const Text('NOTE 样式'),
            trailing: DropdownButton<SimaiNoteStyle>(
              value: _settings.noteStyle,
              items: SimaiNoteStyle.values
                  .map(
                    (style) =>
                        DropdownMenuItem(value: style, child: Text(style.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _update(_settings.copyWith(noteStyle: value));
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
          ListTile(
            title: const Text('右上角显示'),
            trailing: DropdownButton<SimaiGameplayCenterDisplayMode>(
              value: _settings.topRightDisplayMode,
              items: SimaiGameplayCenterDisplayMode.values
                  .map(
                    (mode) =>
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _update(_settings.copyWith(topRightDisplayMode: value));
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
    this.onEnterGameplay,
    this.onExitGameplay,
  });

  final SimaiGameplayController controller;
  final ValueChanged<SimaiGameplayResult> onCompleted;
  final VoidCallback? onExit;
  final Future<void> Function()? onEnterGameplay;
  final Future<void> Function()? onExitGameplay;

  @override
  State<SimaiGameplayPage> createState() => _SimaiGameplayPageState();
}

class _SimaiGameplayPageState extends State<SimaiGameplayPage>
    with WidgetsBindingObserver {
  static const _countdownOverlay = 'countdown';
  static const _pauseOverlay = 'pause';

  // 禁止 GameWidget 抢占焦点，避免 Flame 1.37.0 吞掉系统音量键与返回键。
  late final FocusNode _gameFocusNode = FocusNode(
    canRequestFocus: false,
    skipTraversal: true,
  );
  // 使用 ValueNotifier 局部刷新 3-2-1 倒计时覆盖层，避免每秒 setState 重建 GameWidget。
  final ValueNotifier<int> _countdownNotifier = ValueNotifier<int>(3);
  late final SimaiGameplaySession _session;
  late final SimaiGame _game;
  Timer? _countdownTimer;
  bool _ready = false;
  bool _paused = false;
  bool _completed = false;
  bool _mobileImmersive = false;
  bool _gameplayHooksEntered = false;
  bool _disposed = false;
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
      touchApproachTime: settings.touchApproachTime,
      playbackRate: 1.0,
      musicVolume: settings.musicVolume,
      hitSoundVolume: settings.hitSoundVolume,
      hitSoundEnabled: settings.hitSoundEnabled,
      gameplayAnswerSoundEnabled: settings.answerSoundEnabled,
      gameplayContactRadiusScale: settings.contactRadiusScale,
      backgroundMode: settings.backgroundMode,
      backgroundOpacity: settings.backgroundOpacity,
      mirrorMode: settings.mirrorMode,
      noteStyle: settings.noteStyle,
      showApproachLine: settings.showApproachLine,
      showHitEffects: settings.showHitEffects,
      showGameplayInputPartitions: settings.showInputPartitions,
      showGameplayTouchIndicators: settings.showTouchIndicators,
      showAchievementRate: false,
      showCornerInfo: false,
      showFps: false,
      chartRadiusRatio: settings.chartScale,
      initialChartTime: widget.controller.initialChartTime,
      offset:
          widget.controller.initialChartTime + settings.musicOffsetMs / 1000.0,
      audioAsset: widget.controller.audioAsset,
      audioFilePath: widget.controller.audioFilePath,
      backgroundImageProvider: widget.controller.backgroundImageProvider,
      onGameplayCompleted: _handleCompleted,
    );
    unawaited(_enterMobileImmersive());
    _game.loaded
        .then((_) async {
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted || _completed || _loadError != null) return;
          setState(() => _ready = true);
          _startCountdown();
        })
        .catchError((Object error, StackTrace stackTrace) {
          if (!mounted) return;
          // 先同步写入 _loadError，再触发退出恢复，确保进行中的 _enterMobileImmersive 立即中止。
          setState(() => _loadError = error);
          unawaited(_exitMobileImmersive());
        });
  }

  bool get _shouldAbortGameplayImmersive =>
      _disposed || !mounted || _completed || _loadError != null;

  Future<void> _enterMobileImmersive() async {
    if (_shouldAbortGameplayImmersive) {
      await _exitMobileImmersive();
      return;
    }
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobile) {
      _mobileImmersive = true;
      try {
        await FullScreenUtils.enterFullScreen();
      } catch (e) {
        debugPrint('进入游玩全屏失败: $e');
      }
    }
    if (_shouldAbortGameplayImmersive) {
      // 若进入全屏异步途中发生加载失败、结算或销毁，补做一次退出全屏，避免残留横屏或误触 onEnterGameplay。
      if (isMobile) _mobileImmersive = true;
      await _exitMobileImmersive();
      return;
    }
    if (!_gameplayHooksEntered) {
      _gameplayHooksEntered = true;
      try {
        await widget.onEnterGameplay?.call();
      } catch (e) {
        debugPrint('onEnterGameplay 执行失败: $e');
      }
      if (_shouldAbortGameplayImmersive) {
        // 确保在 onEnterGameplay 返回后补做一次退出恢复，防止异步乱序残留边沿保护或隐藏状态栏。
        _gameplayHooksEntered = true;
        if (isMobile) _mobileImmersive = true;
        await _exitMobileImmersive();
      }
    }
  }

  Future<void> _exitMobileImmersive() async {
    final shouldExitFullScreen = _mobileImmersive;
    final shouldExitHooks = _gameplayHooksEntered;
    if (!shouldExitFullScreen && !shouldExitHooks) return;
    _mobileImmersive = false;
    _gameplayHooksEntered = false;
    if (shouldExitFullScreen) {
      try {
        await FullScreenUtils.exitFullScreen();
      } catch (e) {
        debugPrint('退出游玩全屏失败: $e');
      }
    }
    if (shouldExitHooks) {
      try {
        await widget.onExitGameplay?.call();
      } catch (e) {
        debugPrint('onExitGameplay 执行失败: $e');
      }
    }
  }

  void _startCountdown() {
    if (!_ready || _completed) return;
    _countdownTimer?.cancel();
    _countdownNotifier.value = 3;
    _game.overlays.remove(_pauseOverlay);
    _game.overlays.add(_countdownOverlay);
    if (_paused) {
      setState(() => _paused = false);
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _completed) {
        timer.cancel();
        return;
      }
      final current = _countdownNotifier.value;
      if (current > 1) {
        _countdownNotifier.value = current - 1;
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
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _countdownNotifier.dispose();
    _game.onGameplayCompleted = null;
    _game.clearGameplayPointers();
    if (!_completed) widget.controller.abandonSession(_session);
    unawaited(_exitMobileImmersive());
    _gameFocusNode.dispose();
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
        // 去掉外层垂直 SafeArea 裁切，让触控层与游戏画布铺满整屏，避免 1/4/5/8 轨被裁切。
        body: Stack(
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
                  focusNode: _gameFocusNode,
                  autofocus: false,
                  loadingBuilder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return ColoredBox(
                      color: colorScheme.surface,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  overlayBuilderMap: {
                    _countdownOverlay: (context, game) => _CountdownOverlay(
                      countdownListenable: _countdownNotifier,
                    ),
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
              child: SafeArea(
                left: false,
                bottom: false,
                child: IconButton.filledTonal(
                  tooltip: '暂停',
                  onPressed: _ready && !_paused ? _pause : null,
                  icon: const Icon(Icons.pause),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimaiGameplayResultPage extends StatefulWidget {
  const SimaiGameplayResultPage({
    super.key,
    required this.result,
    this.title,
    this.controller,
    this.onRetry,
    this.onAdjustSettings,
    this.onExit,
  });

  final SimaiGameplayResult result;
  final String? title;
  final SimaiGameplayController? controller;
  final VoidCallback? onRetry;
  final VoidCallback? onAdjustSettings;
  final VoidCallback? onExit;

  @override
  State<SimaiGameplayResultPage> createState() =>
      _SimaiGameplayResultPageState();
}

class _SimaiGameplayResultPageState extends State<SimaiGameplayResultPage> {
  bool _offsetApplied = false;
  int? _appliedOffsetMs;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final achievementColor = isLight
        ? const Color(0xFFD97706)
        : const Color(0xFFFFD54F);
    final touchGroupColor = isLight
        ? const Color(0xFF00897B)
        : const Color(0xFF80CBC4);

    final manualJudgedCount = result.judgements
        .where(
          (record) =>
              !record.isAuto &&
              record.grade != SimaiJudgeGrade.miss &&
              !record.isGroupAssisted,
        )
        .length;
    final double? averageManualOffsetMs =
        manualJudgedCount > 0 && result.averageManualOffsetMs.isFinite
        ? result.averageManualOffsetMs
        : null;
    final controller = widget.controller;
    final canCalibrate =
        controller != null &&
        manualJudgedCount >= 5 &&
        averageManualOffsetMs != null;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.title ?? '游玩结算'),
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
                    value: _formatSignedDecimalMs(result.averageManualOffsetMs),
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
          if (canCalibrate)
            Builder(
              builder: (context) {
                final currentOffset = controller.settings.judgementOffsetMs;
                final newOffset = (currentOffset - averageManualOffsetMs.round())
                    .clamp(-500, 500);
                final tendency = averageManualOffsetMs > 1.0
                    ? '偏 Late'
                    : averageManualOffsetMs < -1.0
                    ? '偏 Fast'
                    : '接近精准';
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '判定偏移一键校准',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '本局平均偏差 ${_formatSignedDecimalMs(averageManualOffsetMs)}（$tendency，共 $manualJudgedCount 个手动判定样本）',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _offsetApplied && _appliedOffsetMs != null
                              ? '已将判定偏移更新为 ${_formatSignedMs(_appliedOffsetMs!)}'
                              : '建议判定偏移：${_formatSignedMs(currentOffset)} → ${_formatSignedMs(newOffset)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          onPressed: _offsetApplied
                              ? null
                              : () {
                                  final updated = controller.settings
                                      .copyWith(judgementOffsetMs: newOffset)
                                      .normalized();
                                  controller.updateSettings(updated);
                                  setState(() {
                                    _offsetApplied = true;
                                    _appliedOffsetMs =
                                        updated.judgementOffsetMs;
                                  });
                                  ScaffoldMessenger.maybeOf(context)
                                      ?.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '判定偏移已更新为 ${_formatSignedMs(updated.judgementOffsetMs)}',
                                          ),
                                        ),
                                      );
                                },
                          icon: Icon(
                            _offsetApplied
                                ? Icons.check_circle_outline
                                : Icons.auto_fix_high,
                          ),
                          label: Text(
                            _offsetApplied
                                ? '已应用（${_formatSignedMs(_appliedOffsetMs!)}）'
                                : '应用偏差到判定偏移',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (widget.onRetry != null)
                FilledButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.replay),
                  label: const Text('再次游玩'),
                ),
              if (widget.onAdjustSettings != null)
                OutlinedButton.icon(
                  onPressed: widget.onAdjustSettings,
                  icon: const Icon(Icons.tune),
                  label: const Text('调整设置'),
                ),
              if (widget.onExit != null)
                TextButton(onPressed: widget.onExit, child: const Text('退出')),
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
  const _NoteSpeedPreview({
    required this.noteSpeed,
    this.chartScale = 0.86,
    this.noteStyle = SimaiNoteStyle.arcade,
  });

  final double noteSpeed;
  final double chartScale;
  final SimaiNoteStyle noteStyle;

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
    final safeScale = (widget.chartScale.isFinite ? widget.chartScale : 0.86)
        .clamp(0.75, 0.95)
        .toDouble();
    final chartRadius = canvasShortSide / 2 * safeScale;
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
                          noteStyle: widget.noteStyle,
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
    required this.noteStyle,
    required this.staticPreview,
    required this.colorScheme,
  });

  final double elapsedSeconds;
  final double pixelsPerSecond;
  final double noteScale;
  final SimaiNoteStyle noteStyle;
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
    final strokeWidth = max(1.0, 2.0 * noteScale);
    if (noteStyle == SimaiNoteStyle.arcade) {
      final light = Color.lerp(
        SimaiVisualTokens.colorTapGradientStart,
        Colors.white,
        SimaiVisualTokens.noteLightenRatio,
      )!;
      final endColor = SimaiVisualTokens.colorTapGradientEnd;
      final midR = (outerRadius + innerRadius) * 0.5;
      final ringPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill;
      for (int i = 0; i < 4; i++) {
        final sAngle = i * (pi / 2);
        final eAngle = sAngle + (pi / 2);
        final p0 = position + Offset(cos(sAngle) * midR, sin(sAngle) * midR);
        final p1 = position + Offset(cos(eAngle) * midR, sin(eAngle) * midR);
        ringPaint.shader = LinearGradient(
          colors: [light, endColor],
        ).createShader(Rect.fromPoints(p0, p1));
        final sectorPath = Path()
          ..arcTo(
            Rect.fromCircle(center: position, radius: outerRadius),
            sAngle,
            pi / 2,
            false,
          )
          ..arcTo(
            Rect.fromCircle(center: position, radius: innerRadius),
            eAngle,
            -pi / 2,
            false,
          )
          ..close();
        canvas.drawPath(sectorPath, ringPaint);
      }
      final blackPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.black;
      canvas.drawCircle(position, outerRadius + strokeWidth, blackPaint);
      final innerBlackR = innerRadius - strokeWidth;
      if (innerBlackR > 0) {
        canvas.drawCircle(position, innerBlackR, blackPaint);
      }
      final whitePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white;
      canvas.drawCircle(position, outerRadius, whitePaint);
      canvas.drawCircle(position, innerRadius, whitePaint);
      canvas.drawCircle(
        position,
        outerRadius * 0.15,
        Paint()
          ..isAntiAlias = true
          ..color = SimaiColors.tapNormal,
      );
      return;
    }

    if (noteStyle == SimaiNoteStyle.simple) {
      final simpleInnerR = outerRadius * 0.58;
      final simpleStrokeW = max(1.2, 2.4 * noteScale);
      final ringPath = Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: position, radius: outerRadius))
        ..addOval(Rect.fromCircle(center: position, radius: simpleInnerR));
      final ringPaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = const RadialGradient(
          colors: [
            SimaiModernNoteColors.pinkLight,
            SimaiModernNoteColors.pinkMid,
            SimaiModernNoteColors.pinkDeep,
          ],
          stops: [0.58, 0.80, 1.0],
        ).createShader(Rect.fromCircle(center: position, radius: outerRadius));
      canvas.drawPath(ringPath, ringPaint);
      canvas.drawCircle(
        position,
        simpleInnerR + (outerRadius - simpleInnerR) * 0.34,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = (outerRadius - simpleInnerR) * 0.22
          ..color = Colors.white.withValues(alpha: 0.22),
      );
      final whitePaint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = simpleStrokeW
        ..color = Colors.white;
      canvas.drawCircle(position, outerRadius, whitePaint);
      canvas.drawCircle(position, simpleInnerR, whitePaint);
      final dotR = outerRadius * 0.16;
      canvas.drawCircle(
        position,
        dotR + 1.0 * noteScale,
        Paint()
          ..isAntiAlias = true
          ..color = Colors.white,
      );
      canvas.drawCircle(
        position,
        dotR,
        Paint()
          ..isAntiAlias = true
          ..color = SimaiModernNoteColors.pinkDot,
      );
      return;
    }

    if (noteStyle == SimaiNoteStyle.bar) {
      final radialThickness = outerRadius * 0.66;
      final tangentLength = outerRadius * 1.96;
      final barRect = Rect.fromCenter(
        center: position,
        width: radialThickness,
        height: tangentLength,
      );
      final barRRect = RRect.fromRectAndRadius(
        barRect,
        Radius.circular(radialThickness * 0.46),
      );
      canvas.drawRRect(
        barRRect,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..shader = const LinearGradient(
            colors: [
              SimaiModernNoteColors.pinkDeep,
              SimaiModernNoteColors.pinkLight,
              SimaiModernNoteColors.pinkMid,
              SimaiModernNoteColors.pinkDeep,
            ],
            stops: [0.0, 0.30, 0.70, 1.0],
          ).createShader(barRect),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: position,
            width: radialThickness * 0.24,
            height: tangentLength * 0.72,
          ),
          Radius.circular(radialThickness * 0.12),
        ),
        Paint()
          ..isAntiAlias = true
          ..color = Colors.white.withValues(alpha: 0.72),
      );
      canvas.drawRRect(
        barRRect,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = Colors.white,
      );
      return;
    }

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
      ..strokeWidth = strokeWidth
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
      oldDelegate.noteStyle != noteStyle ||
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

class _OffsetNudgeRow extends StatelessWidget {
  const _OffsetNudgeRow({required this.deltas, required this.onNudge});

  final List<int> deltas;
  final ValueChanged<int> onNudge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final delta in deltas)
            OutlinedButton(
              onPressed: () => onNudge(delta),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 32),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Text(delta > 0 ? '+$delta' : '$delta'),
            ),
        ],
      ),
    );
  }
}

/// 120 BPM 音频/触控延迟校准弹窗。
///
/// 通过共享池加载 `answer.wav` 播放等间隔节拍音，采集用户 8～12 次点击偏差，
/// 去除极值后取中位数换算为推荐的 `judgementOffsetMs`。
class _LatencyCalibrationDialog extends StatefulWidget {
  const _LatencyCalibrationDialog({
    required this.currentOffsetMs,
    required this.volume,
  });

  final int currentOffsetMs;
  final double volume;

  @override
  State<_LatencyCalibrationDialog> createState() =>
      _LatencyCalibrationDialogState();
}

class _LatencyCalibrationDialogState extends State<_LatencyCalibrationDialog> {
  static const String _clickAsset = 'packages/simai_flutter/assets/answer.wav';
  static const int _beatIntervalUs = 500000; // 120 BPM（每拍 500 ms）
  static const int _minSamples = 8;
  static const int _targetSamples = 12;
  static const int _scheduleLookaheadUs = 120000;

  final Stopwatch _clock = Stopwatch();
  final SimaiGameplayEventClockMapper _clockMapper =
      SimaiGameplayEventClockMapper();
  final List<double> _samplesMs = <double>[];
  final List<SoundHandle> _activeHandles = <SoundHandle>[];

  AudioSource? _clickSource;
  Timer? _beatTimer;
  Timer? _pulseResetTimer;
  Duration? _engineBaseTime;
  int _clockBaseUs = 0;
  int _nextBeatToSchedule = 1;
  int _lastSampledBeatIndex = -1;
  double? _lastErrorMs;
  bool _loading = true;
  bool _running = false;
  bool _beatPulse = false;
  bool _disposed = false;
  String? _errorText;

  double get _clickVolume =>
      (widget.volume.isFinite && widget.volume > 0.15 ? widget.volume : 0.72)
          .clamp(0.15, simaiMaxHitSoundVolume)
          .toDouble();

  @override
  void initState() {
    super.initState();
    unawaited(_initAudioAndStart());
  }

  Future<void> _initAudioAndStart() async {
    try {
      await ensureSoLoudInitialized(SoLoud.instance);
      final source = await SoLoudSourcePool.acquireAsset(
        _clickAsset,
        SoLoud.instance,
      );
      if (_disposed) {
        unawaited(SoLoudSourcePool.release(source, SoLoud.instance));
        return;
      }
      _clickSource = source;
      if (!mounted) return;
      setState(() => _loading = false);
      _startMetronome();
    } catch (e) {
      if (_disposed || !mounted) return;
      setState(() {
        _loading = false;
        _errorText = '音频初始化失败：$e';
      });
    }
  }

  void _startMetronome() {
    if (_disposed || _clickSource == null) return;
    _stopMetronome();
    _samplesMs.clear();
    _lastErrorMs = null;
    _lastSampledBeatIndex = -1;
    _clockMapper.reset();
    _clock
      ..reset()
      ..start();
    _clockBaseUs = _clock.elapsedMicroseconds;
    try {
      _engineBaseTime = SoLoud.instance.getEngineTime();
    } catch (_) {
      _engineBaseTime = null;
    }
    _nextBeatToSchedule = 1;
    _running = true;

    // 使用高频轮询 + SoLoud 引擎前瞻调度，规避 Dart Timer 抖动和累积漂移。
    _beatTimer = Timer.periodic(const Duration(milliseconds: 20), (_) {
      if (_disposed || !_running) return;
      _tickMetronome();
    });
    _tickMetronome();
    if (mounted) setState(() {});
  }

  void _tickMetronome() {
    final source = _clickSource;
    if (source == null || !SoLoud.instance.isInitialized) return;
    final nowUs = _clock.elapsedMicroseconds;
    final engineBase = _engineBaseTime;
    final lookaheadUs = engineBase != null ? _scheduleLookaheadUs : 0;

    while (_clockBaseUs + _nextBeatToSchedule * _beatIntervalUs <=
        nowUs + lookaheadUs) {
      final beatIndex = _nextBeatToSchedule++;
      final beatClockUs = _clockBaseUs + beatIndex * _beatIntervalUs;
      SoundHandle? handle;
      try {
        if (engineBase != null) {
          final scheduledAt =
              engineBase + Duration(microseconds: beatIndex * _beatIntervalUs);
          handle = SoLoud.instance.playScheduled(
            source,
            scheduledAt,
            volume: _clickVolume,
          );
        } else {
          handle = SoLoud.instance.play(source, volume: _clickVolume);
        }
      } catch (_) {
        try {
          handle = SoLoud.instance.play(source, volume: _clickVolume);
        } catch (_) {
          handle = null;
        }
      }
      if (handle != null && !handle.isError) {
        _activeHandles.add(handle);
        if (_activeHandles.length > 16) {
          _activeHandles.removeRange(0, _activeHandles.length - 16);
        }
      }
      final pulseDelayUs = max(0, beatClockUs - nowUs);
      unawaited(
        Future<void>.delayed(Duration(microseconds: pulseDelayUs), () {
          if (_disposed || !_running || !mounted) return;
          setState(() => _beatPulse = true);
          _pulseResetTimer?.cancel();
          _pulseResetTimer = Timer(const Duration(milliseconds: 110), () {
            if (_disposed || !mounted) return;
            setState(() => _beatPulse = false);
          });
        }),
      );
    }
  }

  void _stopMetronome() {
    _running = false;
    _beatPulse = false;
    _beatTimer?.cancel();
    _beatTimer = null;
    _pulseResetTimer?.cancel();
    _pulseResetTimer = null;
    _clock.stop();
    _stopActiveHandles();
  }

  void _stopActiveHandles() {
    if (_activeHandles.isEmpty || !SoLoud.instance.isInitialized) {
      _activeHandles.clear();
      return;
    }
    for (final handle in _activeHandles) {
      try {
        if (SoLoud.instance.getIsValidVoiceHandle(handle)) {
          unawaited(SoLoud.instance.stop(handle));
        }
      } catch (_) {}
    }
    _activeHandles.clear();
  }

  void _handleTap(Duration eventTimestamp) {
    if (!_running || _samplesMs.length >= _targetSamples) return;
    final mapped = _clockMapper.map(
      eventTimestamp: eventTimestamp,
      receiptTimestamp: _clock.elapsed,
      allowCalibration: true,
    );
    final tapUs = mapped.inMicroseconds;
    final relativeUs = tapUs - _clockBaseUs;
    final nearestBeatIndex = (relativeUs / _beatIntervalUs).round();
    if (nearestBeatIndex < 1 || nearestBeatIndex == _lastSampledBeatIndex) {
      return;
    }
    final beatUs = _clockBaseUs + nearestBeatIndex * _beatIntervalUs;
    final errorMs = (tapUs - beatUs) / 1000.0;
    // 忽略超出半拍范围的误触。
    if (errorMs.abs() > 250.0) return;

    _lastSampledBeatIndex = nearestBeatIndex;
    _samplesMs.add(errorMs);
    _lastErrorMs = errorMs;
    if (_samplesMs.length >= _targetSamples) {
      _stopMetronome();
    }
    setState(() {});
  }

  double? _computeTrimmedMedianErrorMs() {
    if (_samplesMs.length < _minSamples) return null;
    final sorted = List<double>.of(_samplesMs)..sort();
    // 去除首尾极值后取中位数，抵抗偶发误触。
    final trim = sorted.length >= 10 ? 2 : 1;
    final trimmed = sorted.sublist(trim, sorted.length - trim);
    final mid = trimmed.length ~/ 2;
    return trimmed.length.isOdd
        ? trimmed[mid]
        : (trimmed[mid - 1] + trimmed[mid]) / 2.0;
  }

  @override
  void dispose() {
    _disposed = true;
    _stopMetronome();
    final source = _clickSource;
    _clickSource = null;
    if (source != null) {
      unawaited(SoLoudSourcePool.release(source, SoLoud.instance));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final medianErrorMs = _computeTrimmedMedianErrorMs();
    // 偏 Late（errorMs > 0）对应负判定偏移，偏 Fast（errorMs < 0）对应正判定偏移。
    final int? recommendedOffsetMs = medianErrorMs == null
        ? null
        : (-medianErrorMs).round().clamp(-500, 500);
    final completed = _samplesMs.length >= _targetSamples;

    return AlertDialog(
      title: const Text('音频/触控延迟校准'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 340,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('正在准备节拍音…'),
                    ],
                  ),
                )
              : _errorText != null
              ? Text(_errorText!)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '请跟随 120 BPM 节拍音，稳定点击下方节拍区 8～12 次。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (event) => _handleTap(event.timeStamp),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 90),
                        height: 132,
                        decoration: BoxDecoration(
                          color: completed
                              ? colorScheme.secondaryContainer
                              : _beatPulse
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _beatPulse
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            width: _beatPulse ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                completed
                                    ? Icons.check_circle
                                    : Icons.touch_app,
                                size: 36,
                                color: completed
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                completed ? '采集完成' : '按节拍点击此处',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '已采集 ${_samplesMs.length} / $_targetSamples 次'
                                '${_samplesMs.length < _minSamples ? '（至少 $_minSamples 次可应用）' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_lastErrorMs != null)
                      Text(
                        '最近一次偏差：${_formatSignedDecimalMs(_lastErrorMs!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (medianErrorMs != null &&
                        recommendedOffsetMs != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '去极值中位数延迟：${_formatSignedDecimalMs(medianErrorMs)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '推荐判定偏移：${_formatSignedMs(recommendedOffsetMs)}'
                        '（当前 ${_formatSignedMs(widget.currentOffsetMs)}）',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
      actions: [
        if (!_loading && _errorText == null)
          TextButton(onPressed: _startMetronome, child: const Text('重新校准')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        FilledButton(
          onPressed: recommendedOffsetMs == null
              ? null
              : () => Navigator.of(context).pop(recommendedOffsetMs),
          child: const Text('应用推荐值'),
        ),
      ],
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.countdownListenable});

  final ValueListenable<int> countdownListenable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.38),
      child: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: countdownListenable,
          builder: (context, value, _) => Text(
            '$value',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              shadows: const [Shadow(color: Colors.black, blurRadius: 12)],
            ),
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
