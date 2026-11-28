import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simai_flutter/simai_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:my_first_flutter_app/service/System/AppFontService.dart';
import 'package:my_first_flutter_app/service/ChartPlay/ChartPlaySettingsStore.dart';
import 'package:my_first_flutter_app/service/System/LoadingTipsStore.dart';
import 'package:my_first_flutter_app/service/Media/PvVideoStream.dart';
import 'package:my_first_flutter_app/service/Media/SongMediaCache.dart';
import 'package:my_first_flutter_app/service/Portable/PortablePlayerController.dart';
import 'package:my_first_flutter_app/service/ChartPlay/VideoExportBackgroundService.dart';
import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:my_first_flutter_app/utils/AppError.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/NavigationPreferences.dart';
import 'package:my_first_flutter_app/utils/NetworkTypeUtil.dart';
import 'package:my_first_flutter_app/utils/RefreshRateUtil.dart';
import 'package:my_first_flutter_app/widgets/SmoothLinearProgressIndicator.dart';
import 'package:my_first_flutter_app/widgets/MarqueeText.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppSwitch.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/ChartPlayCustomizationSheets.dart';
import '../../widgets/ChartPlayMetronome.dart';

class ChartPlayPage extends StatefulWidget {
  final String maidataContent;
  final String songTitle;
  final String songId;
  final String songType;
  final String? selectedInote;
  final String? bgImagePath;
  final String? audioFilePath;

  /// 是否在创建播放器时查找并加载音频。默认保持原有行为。
  final bool loadAudio;

  /// 是否在创建播放器时尝试加载 PV 作为机台圆形背景。
  final bool loadPv;

  const ChartPlayPage({
    super.key,
    required this.maidataContent,
    required this.songTitle,
    required this.songId,
    required this.songType,
    this.selectedInote,
    this.bgImagePath,
    this.audioFilePath,
    this.loadAudio = true,
    this.loadPv = false,
  });

  @override
  State<ChartPlayPage> createState() => _ChartPlayPageState();
}

class _ChartPlayPageState extends State<ChartPlayPage>
    with WidgetsBindingObserver {
  SimaiPlayerController? _controller;
  SimaiGameplayController? _gameplayController;
  SimaiVideoMetadata? _videoMetadata;
  SimaiVideoExportOptions _videoExportOptions = const SimaiVideoExportOptions();
  double _chartOffset = 0.0;
  Key _playerKey = UniqueKey();
  final _metronomeKey = GlobalKey();
  String? _audioUrl;
  List<String> _audioUrls = const <String>[];
  bool _audioLoadFailed = false;
  ImageProvider? _bgImageProvider;
  bool _isLeaving = false;
  bool _hasLoggedPlayerBuild = false;
  bool _metronomeEnabled = true;
  double _metronomeSpeed = 1.0;
  final ValueNotifier<double> _metronomeSpeedNotifier =
      ValueNotifier<double>(1.0);
  bool _metronomeSoundEnabled = false;
  Timer? _loadingDiagnosticTimer;
  Timer? _loadingTipTimer;
  String _loadingStage = appL10n.flowPreparingChart;
  double? _loadingProgress;
  double _loadingSpeed = 0;
  String _loadingTip = '';

  /// 设置落盘防抖：侧边栏每拖一下滑块都会 notifyListeners，
  /// 不防抖会写爆 SharedPreferences。
  Timer? _settingsSaveDebounce;
  Timer? _gameplaySettingsSaveDebounce;
  Timer? _videoExportSettingsSaveDebounce;
  SimaiGameplaySettings? _lastObservedGameplaySettings;
  bool _inGameplay = false;

  static const _pvHeaders = <String, String>{
    'User-Agent': 'Mozilla/5.0 (Android) AppleWebKit/537.36',
    'Referer': 'https://download.wmc.pub/',
  };
  static const Duration _pvSeekGraceWindow = Duration(milliseconds: 800);
  VideoPlayerController? _pvController;
  PvVideoStream? _pvVideoStream;
  String? _pvCachedFilePath;
  bool _pvReady = false;
  int _pvLoadGen = 0;
  bool _pvSyncing = false;
  bool _pvSyncPending = false;
  bool _pvForceSeek = false;
  bool _pvWantPlaying = false;
  DateTime? _pvLastSeekAt;
  bool _pvPausedSeekPending = false;
  double _lastPvObservedTime = double.nan;
  int _lastPvObservedOffsetMs = 0;
  int _lastPvObservedMusicOffsetMs = 0;
  bool _lastPvObservedPlaying = false;
  double _lastPvObservedPlaybackRate = 1.0;
  double _lastAppliedPvSpeed = 1.0;
  Timer? _pvPeriodicSyncTimer;
  Timer? _pvPausedSeekThrottle;
  String _pvLoadingStage = '';
  double? _pvLoadingProgress;
  double _pvLoadingSpeed = 0;
  bool _pvLoadingDone = false;
  bool _pvLoadingFailed = false;

  String get _trimmedSongId => widget.songId.trim();

  bool get _hasNumericSongId => RegExp(r'^\d+$').hasMatch(_trimmedSongId);

  bool get _isUtageChart =>
      widget.songType.toUpperCase() == 'UTAGE' ||
      (_trimmedSongId.length == 6 && _hasNumericSongId);

  bool get _canLoadRemotePv => widget.loadPv && _hasNumericSongId;

  bool _inPvSeekGraceWindow() =>
      _pvLastSeekAt != null &&
      DateTime.now().difference(_pvLastSeekAt!) < _pvSeekGraceWindow;

  void _cancelPvPausedSeekThrottle() {
    _pvPausedSeekThrottle?.cancel();
    _pvPausedSeekThrottle = null;
    _pvPausedSeekPending = false;
  }

  void _pausePortablePlayerIfNeeded() {
    if (!widget.loadAudio) return;
    final portable = PortablePlayerController();
    if (portable.isPlaying) {
      unawaited(portable.togglePlayPause());
    }
  }

  void _showMediaLoadFailureHintsIfNeeded() {
    if (!mounted || _isLeaving) return;
    final audioFailed = _audioLoadFailed;
    final pvFailed = _canLoadRemotePv && _pvLoadingFailed;
    if (audioFailed && pvFailed) {
      AppToast.show(
        '${context.l10n.chartPlayAudioLoadFailedHint}\n'
        '${context.l10n.chartPlayPvLoadFailedHint}',
        tone: AppToastTone.warning,
      );
    } else if (audioFailed) {
      AppToast.show(
        context.l10n.chartPlayAudioLoadFailedHint,
        tone: AppToastTone.warning,
      );
    } else if (pvFailed) {
      AppToast.show(
        context.l10n.chartPlayPvLoadFailedHint,
        tone: AppToastTone.warning,
      );
    }
  }

  bool _isPvNotFoundError(Object error) {
    if (error is AppStateError) {
      if (error.appError.httpStatus == 404) return true;
      final detail = error.appError.technicalDetail ?? '';
      if (detail.contains('HTTP 404')) return true;
    } else if (error is AppError) {
      if (error.httpStatus == 404) return true;
      final detail = error.technicalDetail ?? '';
      if (detail.contains('HTTP 404')) return true;
    }
    return error.toString().contains('HTTP 404');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    VideoExportBackgroundService.instance.ensureInitialized();
    VideoExportBackgroundService.instance.openExportRequestNonce
        .addListener(_handleOpenExportRequest);
    // 谱面播放对帧率敏感：Flutter 引擎不会主动向系统要高刷，
    // 不投这一票就会一直在「几秒 120 → 掉 60」之间反复。
    RefreshRateUtil.requestMax();
    // 默认竖屏，只有明确点击全屏才主动请求横屏。
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // 提前把上次的侧边栏、视频导出与游玩设置读进内存，等控制器建好就能直接套用
    ChartPlaySettingsStore().load();
    ChartVideoExportSettingsStore().load();
    ChartGameplaySettingsStore().load();
    // 短期心跳仅输出到调试日志：计时器也停住时，说明 Dart 主线程被阻塞，
    // 并非单纯某个资源 Future 没有完成。最多记录 20 秒，不持续轮询。
    final diagnosticWatch = Stopwatch()..start();
    _loadingDiagnosticTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      debugPrint(
        '[ChartPlay] heartbeat elapsed=${diagnosticWatch.elapsedMilliseconds}ms '
        'controller=${_controller != null}',
      );
      if (timer.tick >= 4) timer.cancel();
    });
    _loadingTip = LoadingTipsStore.instance.randomText();
    _loadingTipTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_controller != null || !mounted) {
        timer.cancel();
        if (identical(_loadingTipTimer, timer)) {
          _loadingTipTimer = null;
        }
        return;
      }
      final tip = LoadingTipsStore.instance.randomText();
      if (tip.isNotEmpty) setState(() => _loadingTip = tip);
    });
    unawaited(LoadingTipsStore.instance.ensureLoaded().then((_) {
      if (_controller != null || !mounted) return;
      final tip = LoadingTipsStore.instance.randomText();
      if (tip.isNotEmpty) setState(() => _loadingTip = tip);
    }));
    _loadChart();
  }

  void _setLoadingStatus(
    String stage, {
    double? progress,
    double speed = 0,
  }) {
    if (!mounted) return;
    setState(() {
      _loadingStage = stage;
      _loadingProgress = progress;
      _loadingSpeed = speed;
    });
  }

  void _setPvLoadingStatus(
    String stage, {
    double? progress,
    double speed = 0,
    bool? done,
    bool? failed,
  }) {
    if (!mounted) return;
    setState(() {
      _pvLoadingStage = stage;
      _pvLoadingProgress = progress;
      _pvLoadingSpeed = speed;
      if (done != null) _pvLoadingDone = done;
      if (failed != null) _pvLoadingFailed = failed;
    });
  }

  String _formatLoadingSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '';
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 从后台回来时渲染 Surface 可能已经重建，补投票一次；
      // 仅本页处于路由栈顶时才对齐 PV，防止游玩期间切后台再切回时底层隐藏页强制同步 PV。
      RefreshRateUtil.requestMax();
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        _pvWantPlaying = false;
        _pvForceSeek = true;
        unawaited(_syncPv());
      }
    } else if (state == AppLifecycleState.inactive) {
      // 失焦时提前落盘设置，避免分屏/切走或进程被系统终止时丢失修改。
      _flushSettingsNow();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _cancelPvPausedSeekThrottle();
      final pv = _pvController;
      if (_pvReady && pv != null && (pv.value.isPlaying || _pvWantPlaying)) {
        unawaited(pv.pause());
      }
      _pvWantPlaying = false;
      _pvLastSeekAt = null;
      // 切后台/被划掉前立刻把设置写下去，别等 dispose
      _flushSettingsNow();
    }
  }

  /// 建控制器：统一在这里套用上次保存的侧边栏设置并挂上变更监听。
  /// `_loadChart` 和 `_loadFallbackChart` 都走这里，避免两处漏改。
  SimaiPlayerController _createController(
    MaiChart chart,
    String? audioPath,
  ) {
    final controller = SimaiPlayerController(
      chart: chart,
      audioFilePath: audioPath,
      backgroundImageProvider: _bgImageProvider,
      initialChartTime: -_chartOffset,
    )..title = widget.songTitle;

    // 沿用上次的设置（控制器 setter 自带「值没变就 return」，不会有多余重建）
    ChartPlaySettingsStore().applyTo(controller);

    _lastPvObservedOffsetMs = controller.pvOffsetMs;
    _lastPvObservedMusicOffsetMs = controller.musicOffsetMs;
    _lastPvObservedPlaying = controller.isPlaying;
    _lastPvObservedPlaybackRate = controller.playbackRate;
    _lastPvObservedTime = controller.chartTime;

    // 用户改设置 → 控制器的 setter 会 notifyListeners → 防抖落盘
    controller.addListener(_scheduleSettingsSave);
    controller.addListener(_onControllerChangedForPv);
    controller.timeNotifier.addListener(_onChartTimeChangedForPv);
    return controller;
  }

  /// 计算游玩控制器的初始设置：优先恢复本地持久化配置，首次进入则从预览控制器继承核心参数。
  SimaiGameplaySettings _resolveInitialGameplaySettings(
    SimaiPlayerController controller,
  ) {
    final saved = ChartGameplaySettingsStore().savedSettings;
    if (saved != null) return saved;
    return SimaiGameplaySettings(
      noteSpeed: controller.speed,
      touchSpeed: controller.touchSpeed,
      musicOffsetMs: controller.musicOffsetMs,
      musicVolume: controller.musicVolume,
      hitSoundVolume: controller.hitSoundVolume,
      mirrorMode: controller.mirrorMode,
      backgroundMode: controller.backgroundMode,
      backgroundOpacity: controller.backgroundOpacity,
      noteStyle: controller.noteStyle,
      holdStyle: controller.holdStyle,
      judgementDisplayMode: controller.judgementDisplayMode,
      centerDisplayMode: SimaiGameplayCenterDisplayMode.fromNameOrLegacy(
        controller.centerDisplayMode.name,
      ),
      showApproachLine: controller.showApproachLine,
      showHitEffects: controller.showHitEffects,
      hitEffectStyle: controller.hitEffectStyle,
    ).normalized();
  }

  /// 建游玩控制器：统一套用持久化/继承设置并挂上变更监听，避免主流程与回退流程漏接。
  SimaiGameplayController _createGameplayController(
    MaiChart chart,
    String? audioPath,
    SimaiPlayerController controller,
  ) {
    final initialSettings = _resolveInitialGameplaySettings(controller);
    _lastObservedGameplaySettings = initialSettings;
    final gameplayController = SimaiGameplayController(
      chart: chart,
      audioFilePath: audioPath,
      backgroundImageProvider: _bgImageProvider,
      initialChartTime: -_chartOffset,
      title: widget.songTitle,
      settings: initialSettings,
    );
    gameplayController.addListener(_onGameplayControllerChanged);
    return gameplayController;
  }

  void _onGameplayControllerChanged() {
    final gameplayController = _gameplayController;
    if (gameplayController == null) return;
    final current = gameplayController.settings;
    if (current == _lastObservedGameplaySettings) return;
    _lastObservedGameplaySettings = current;

    // 同步记入内存，防抖仅推迟写盘，避免中途切后台或离页丢失最新设置。
    ChartGameplaySettingsStore().remember(current);
    _gameplaySettingsSaveDebounce?.cancel();
    _gameplaySettingsSaveDebounce =
        Timer(const Duration(milliseconds: 600), () {
      unawaited(ChartGameplaySettingsStore().persist());
    });
  }

  void _startPvPeriodicSyncTimer() {
    if (!mounted || _isLeaving || !_pvReady || _inGameplay) return;
    _pvPeriodicSyncTimer?.cancel();
    _pvPeriodicSyncTimer =
        Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!mounted || _isLeaving || !_pvReady || _inGameplay) return;
      if (_controller?.isPlaying == true) {
        unawaited(_syncPv());
      }
    });
  }

  void _stopPvPeriodicSyncTimer() {
    _pvPeriodicSyncTimer?.cancel();
    _pvPeriodicSyncTimer = null;
  }

  /// 进入横屏游玩前关闭后台 PV 轮询、隐藏状态栏并开启边沿防误触与高刷投票。
  Future<void> _handleEnterGameplay() async {
    _inGameplay = true;
    _stopPvPeriodicSyncTimer();
    await NavigationPreferences.instance.setGameplayStatusBarHidden(true);
    if (!mounted || _isLeaving || !_inGameplay) return;
    await RefreshRateUtil.setGameplayEdgeProtection(true);
    if (!mounted || _isLeaving || !_inGameplay) return;
    await RefreshRateUtil.requestMax();
  }

  /// 退出游玩后恢复边沿手势保护、状态栏与高刷投票，并按需重启 PV 周期对齐。
  Future<void> _handleExitGameplay() async {
    _inGameplay = false;
    await RefreshRateUtil.setGameplayEdgeProtection(false);
    await NavigationPreferences.instance.setGameplayStatusBarHidden(false);
    if (!mounted || _isLeaving || _inGameplay) return;
    await RefreshRateUtil.requestMax();
    if (_pvReady) {
      _startPvPeriodicSyncTimer();
    }
  }

  Future<void> _loadPvBackground() async {
    if (!_canLoadRemotePv || _isLeaving) return;
    final gen = ++_pvLoadGen;
    final songId = _trimmedSongId;
    final pvUrl = ApiUrls.wmcPvUrl(songId);
    _setPvLoadingStatus(
      appL10n.chartPlayPreparingPv,
      progress: null,
      speed: 0,
      done: false,
      failed: false,
    );
    VideoPlayerController? pv;
    PvVideoStream? stream;
    var sourceLabel = '';
    try {
      final options = VideoPlayerOptions(mixWithOthers: true);
      try {
        final pvFile = await SongMediaCache.instance.ensurePv(
          songId,
          url: pvUrl,
          headers: _pvHeaders,
          onProgress: (progress, speed, status) {
            if (!mounted || _isLeaving || gen != _pvLoadGen) return;
            _setPvLoadingStatus(status, progress: progress, speed: speed);
          },
        );
        if (!mounted || _isLeaving || gen != _pvLoadGen) return;
        _pvCachedFilePath = pvFile.path;
        _setPvLoadingStatus(
          appL10n.chartPlayInitializingPv,
          progress: 1.0,
          speed: 0,
        );
        pv = VideoPlayerController.file(
          pvFile,
          videoPlayerOptions: options,
          viewType: VideoViewType.textureView,
        );
        sourceLabel = 'path=${pvFile.path}';
      } catch (cacheError) {
        if (!mounted || _isLeaving || gen != _pvLoadGen) return;
        if (_isPvNotFoundError(cacheError)) rethrow;
        // 非 404 缓存下载失败时，自动回退到本地 Range 代理流式初始化，避免整文件断流直接跳过 PV。
        debugPrint('[ChartPlay] PV 缓存下载失败，回退流式加载: $cacheError');
        _setPvLoadingStatus(
          appL10n.chartPlayPvStreamingFallback,
          progress: null,
          speed: 0,
        );
        final pvUri = Uri.parse(pvUrl);
        var streamUri = pvUri;
        final proxy = PvVideoStream(pvUri, _pvHeaders);
        try {
          streamUri = await proxy.open();
          if (!mounted || _isLeaving || gen != _pvLoadGen) {
            proxy.close();
            return;
          }
          stream = proxy;
        } catch (proxyError) {
          proxy.close();
          debugPrint('[ChartPlay] 启动 PV 本地代理失败，改用直连流式加载: $proxyError');
        }
        pv = VideoPlayerController.networkUrl(
          streamUri,
          httpHeaders: stream == null ? _pvHeaders : const <String, String>{},
          videoPlayerOptions: options,
          viewType: VideoViewType.textureView,
        );
        sourceLabel =
            stream != null ? 'stream-proxy=$pvUrl' : 'stream-direct=$pvUrl';
      }

      await pv.initialize();
      await pv.setVolume(0.0);
      await pv.setLooping(false);
      await pv.seekTo(Duration.zero);
      if (!mounted || _isLeaving || gen != _pvLoadGen) {
        unawaited(pv.dispose());
        stream?.close();
        return;
      }
      final previous = _pvController;
      final previousStream = _pvVideoStream;
      _pvController = pv;
      _pvVideoStream = stream;
      _pvReady = true;
      _pvWantPlaying = false;
      _pvLastSeekAt = null;
      _pvForceSeek = true;
      _lastAppliedPvSpeed = 1.0;
      _startPvPeriodicSyncTimer();
      if (previous != null && !identical(previous, pv)) {
        unawaited(previous.dispose());
      }
      if (previousStream != null && !identical(previousStream, stream)) {
        previousStream.close();
      }
      _setPvLoadingStatus(
        appL10n.chartPlayPvReady,
        progress: 1.0,
        speed: 0,
        done: true,
        failed: false,
      );
      debugPrint('[ChartPlay] pv-ready $sourceLabel');
      final ctrl = _controller;
      if (ctrl != null) {
        _lastPvObservedOffsetMs = ctrl.pvOffsetMs;
        _lastPvObservedMusicOffsetMs = ctrl.musicOffsetMs;
        _lastPvObservedPlaying = ctrl.isPlaying;
        _lastPvObservedPlaybackRate = ctrl.playbackRate;
        _lastPvObservedTime = ctrl.chartTime;
        unawaited(_syncPv());
      }
    } catch (e) {
      debugPrint('[ChartPlay] pv-unavailable: $e');
      if (pv != null) {
        unawaited(pv.dispose());
      }
      stream?.close();
      if (mounted && !_isLeaving && gen == _pvLoadGen) {
        _setPvLoadingStatus(
          appL10n.chartPlayPvUnavailable,
          progress: 1.0,
          speed: 0,
          done: true,
          failed: true,
        );
      }
    }
  }

  void _onControllerChangedForPv() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final becamePlaying = !_lastPvObservedPlaying && ctrl.isPlaying;
    if (becamePlaying) {
      _pausePortablePlayerIfNeeded();
    }
    if (!_pvReady) {
      _lastPvObservedPlaying = ctrl.isPlaying;
      return;
    }

    // 仅响应影响 PV 同步的字段变化，避免拖动背景透明度、音量、流速等滑块干扰 PV。
    final offsetChanged = ctrl.pvOffsetMs != _lastPvObservedOffsetMs ||
        ctrl.musicOffsetMs != _lastPvObservedMusicOffsetMs;
    final playingChanged = ctrl.isPlaying != _lastPvObservedPlaying;
    final rateChanged =
        (ctrl.playbackRate - _lastPvObservedPlaybackRate).abs() > 1e-6;
    if (!offsetChanged && !playingChanged && !rateChanged) return;

    _lastPvObservedOffsetMs = ctrl.pvOffsetMs;
    _lastPvObservedMusicOffsetMs = ctrl.musicOffsetMs;
    _lastPvObservedPlaying = ctrl.isPlaying;
    _lastPvObservedPlaybackRate = ctrl.playbackRate;

    if (offsetChanged) {
      _pvForceSeek = true;
    }
    if (becamePlaying) {
      // 从暂停恢复播放时清除残留的拖动节流，由 !_pvWantPlaying 正常接管同步。
      _cancelPvPausedSeekThrottle();
      if (!offsetChanged) {
        _pvForceSeek = false;
      }
    }
    unawaited(_syncPv());
  }

  void _triggerPausedPvSeek() {
    _pvForceSeek = true;
    unawaited(_syncPv());
    _pvPausedSeekThrottle = Timer(const Duration(milliseconds: 120), () {
      _pvPausedSeekThrottle = null;
      if (!mounted || _isLeaving || !_pvReady) {
        _pvPausedSeekPending = false;
        return;
      }
      if (_pvPausedSeekPending) {
        _pvPausedSeekPending = false;
        if (_controller?.isPlaying == false) {
          _triggerPausedPvSeek();
        }
      }
    });
  }

  void _onChartTimeChangedForPv() {
    final ctrl = _controller;
    final pv = _pvController;
    if (!_pvReady || ctrl == null || pv == null) return;
    final nowTime = ctrl.chartTime;
    if (ctrl.isPlaying) {
      _cancelPvPausedSeekThrottle();
      final durationSec = pv.value.duration.inMilliseconds / 1000.0;
      final targetSec =
          (nowTime - ctrl.effectiveMusicOffsetSeconds) -
          (ctrl.pvOffsetMs / 1000.0);
      if (_lastPvObservedTime.isFinite &&
          (nowTime - _lastPvObservedTime).abs() > 0.35) {
        _pvForceSeek = true;
        unawaited(_syncPv());
      } else if (durationSec > 0 && targetSec >= 0 && targetSec < durationSec) {
        if (!_pvWantPlaying ||
            (!pv.value.isPlaying &&
                !pv.value.isBuffering &&
                !_inPvSeekGraceWindow())) {
          unawaited(_syncPv());
        }
      } else if (durationSec > 0 &&
          _pvWantPlaying &&
          (targetSec < 0 || targetSec >= durationSec)) {
        unawaited(_syncPv());
      }
      _lastPvObservedTime = nowTime;
      return;
    }
    _lastPvObservedTime = nowTime;
    // 暂停/拖动期间采用前缘 + 尾缘节流（120ms 冷却窗）：
    // 冷却期间绝不 cancel 定时器，避免持续拖动进度条时被防抖饿死。
    if (_pvPausedSeekThrottle == null) {
      _triggerPausedPvSeek();
    } else {
      _pvPausedSeekPending = true;
    }
  }

  Future<void> _syncPv() async {
    final pv = _pvController;
    if (!_pvReady || pv == null || !pv.value.isInitialized) return;
    _pvSyncPending = true;
    if (_pvSyncing) return;
    _pvSyncing = true;
    try {
      while (_pvSyncPending &&
          mounted &&
          !_isLeaving &&
          identical(_pvController, pv)) {
        _pvSyncPending = false;
        final ctrl = _controller;
        if (ctrl == null || !_pvReady || !pv.value.isInitialized) break;

        final durationMs = pv.value.duration.inMilliseconds;
        if (durationMs <= 0) continue;

        final targetSec =
            (ctrl.chartTime - ctrl.effectiveMusicOffsetSeconds) -
            (ctrl.pvOffsetMs / 1000.0);
        final durationSec = durationMs / 1000.0;
        final clampedSec = targetSec.clamp(0.0, durationSec).toDouble();
        final targetDur = Duration(milliseconds: (clampedSec * 1000).round());
        final forceSeek = _pvForceSeek;
        _pvForceSeek = false;

        if (!ctrl.isPlaying) {
          if (pv.value.isPlaying || _pvWantPlaying) {
            await pv.pause();
            _pvWantPlaying = false;
            if (!mounted || _isLeaving || !identical(_pvController, pv)) break;
          } else {
            _pvWantPlaying = false;
          }
          final currentPos = pv.value.position;
          if (forceSeek || (currentPos - targetDur).abs().inMilliseconds > 80) {
            await pv.seekTo(targetDur);
            _pvLastSeekAt = DateTime.now();
          }
          continue;
        }

        if (targetSec < 0 || targetSec >= durationSec) {
          if (pv.value.isPlaying || _pvWantPlaying) {
            await pv.pause();
            _pvWantPlaying = false;
            if (!mounted || _isLeaving || !identical(_pvController, pv)) break;
          } else {
            _pvWantPlaying = false;
          }
          final currentPos = pv.value.position;
          if (targetSec < 0 && currentPos.inMilliseconds > 80) {
            await pv.seekTo(Duration.zero);
            _pvLastSeekAt = DateTime.now();
          }
          continue;
        }

        // 播放态将 seekTo 与 play 解耦，配合缓冲态与 800ms 宽限期打破 ExoPlayer 解码活锁。
        final desiredSpeed = ctrl.playbackRate.clamp(0.25, 3.0).toDouble();
        final driftLimitMs = (220 * desiredSpeed).round().clamp(180, 450);
        final inSeekGrace = _inPvSeekGraceWindow();
        final currentPos = (!pv.value.isBuffering && !inSeekGrace)
            ? ((await pv.position) ?? pv.value.position)
            : pv.value.position;
        if (!mounted || _isLeaving || !identical(_pvController, pv)) break;
        if (!ctrl.isPlaying) {
          _pvSyncPending = true;
          continue;
        }

        final latestTargetSec =
            (ctrl.chartTime - ctrl.effectiveMusicOffsetSeconds) -
            (ctrl.pvOffsetMs / 1000.0);
        if (latestTargetSec < 0 || latestTargetSec >= durationSec) {
          _pvSyncPending = true;
          continue;
        }
        final latestTargetDur = Duration(
          milliseconds:
              (latestTargetSec.clamp(0.0, durationSec).toDouble() * 1000)
                  .round(),
        );
        final driftMs = (currentPos - latestTargetDur).abs().inMilliseconds;
        final isCompleted = pv.value.position >= pv.value.duration &&
            pv.value.duration > Duration.zero;
        final skipSeekForBuffering =
            !forceSeek && _pvWantPlaying && (pv.value.isBuffering || inSeekGrace);
        final shouldSeek = !skipSeekForBuffering &&
            (forceSeek ||
                (!_pvWantPlaying && driftMs > 80) ||
                (!pv.value.isBuffering && !inSeekGrace && driftMs > driftLimitMs) ||
                (isCompleted && latestTargetSec < durationSec - 0.1));

        if (shouldSeek) {
          await pv.seekTo(latestTargetDur);
          _pvLastSeekAt = DateTime.now();
          if (!mounted || _isLeaving || !identical(_pvController, pv)) break;
          if (!ctrl.isPlaying) {
            _pvSyncPending = true;
            continue;
          }
        }

        if (!_pvWantPlaying ||
            isCompleted ||
            (!pv.value.isPlaying && !pv.value.isBuffering)) {
          await pv.play();
          _pvWantPlaying = true;
          if (!mounted || _isLeaving || !identical(_pvController, pv)) break;
        }

        if ((_lastAppliedPvSpeed - desiredSpeed).abs() > 0.001) {
          try {
            await pv.setPlaybackSpeed(desiredSpeed);
            _lastAppliedPvSpeed = desiredSpeed;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[ChartPlay] PV 同步异常: $e');
    } finally {
      _pvSyncing = false;
    }
  }

  Widget? _buildPvBackground() {
    final pv = _pvController;
    if (!_pvReady || pv == null || !pv.value.isInitialized) return null;
    final videoSize = pv.value.size;
    final width = videoSize.width > 0 ? videoSize.width : 16.0;
    final height = videoSize.height > 0 ? videoSize.height : 9.0;
    // 暗化遮罩统一交由 SimaiPlayer 按 controller.backgroundOpacity 实时渲染。
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: height,
        child: VideoPlayer(pv),
      ),
    );
  }

  void _scheduleSettingsSave() {
    final controller = _controller;
    if (controller == null) return;

    // 同步抓取当前值并记进内存（防抖只推迟「写盘」，不推迟「记下来」），
    // 这样即使中途重建了控制器，也不会读到已经过期的旧设置。
    ChartPlaySettingsStore().remember(ChartPlaySettings.capture(
      controller,
      metronomeEnabled: _metronomeEnabled,
      metronomeSpeed: _metronomeSpeed,
      metronomeSoundEnabled: _metronomeSoundEnabled,
    ));

    _settingsSaveDebounce?.cancel();
    _settingsSaveDebounce = Timer(const Duration(milliseconds: 600), () {
      ChartPlaySettingsStore().persist();
    });
  }

  /// 立刻落盘（取消未到期的防抖），用于退出页面/切后台。
  void _flushSettingsNow() {
    _settingsSaveDebounce?.cancel();
    _settingsSaveDebounce = null;
    _gameplaySettingsSaveDebounce?.cancel();
    _gameplaySettingsSaveDebounce = null;
    _videoExportSettingsSaveDebounce?.cancel();
    _videoExportSettingsSaveDebounce = null;
    ChartPlaySettingsStore().saveFrom(_controller);
    unawaited(ChartGameplaySettingsStore().saveNow());
    unawaited(ChartVideoExportSettingsStore().saveNow());
  }

  void _onVideoExportSettingsChanged(SimaiVideoExportSettings settings) {
    ChartVideoExportSettingsStore().remember(settings);
    if (mounted) setState(() {});
    _videoExportSettingsSaveDebounce?.cancel();
    _videoExportSettingsSaveDebounce =
        Timer(const Duration(milliseconds: 500), () {
      unawaited(ChartVideoExportSettingsStore().persist());
    });
  }

  /// 导出视频时若玩家未开启播放音源，尝试按需读取本地缓存或拉取音源文件。
  Future<String?> _resolveVideoExportAudio() async {
    if (!mounted || _isLeaving) return null;
    final currentPath = _controller?.audioFilePath;
    if (currentPath != null &&
        currentPath.isNotEmpty &&
        await File(currentPath).exists()) {
      return currentPath;
    }
    final localPath = widget.audioFilePath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        await File(localPath).exists()) {
      return localPath;
    }
    if (!_hasNumericSongId) return null;
    final cached = await _findCachedAudio();
    if (cached != null && await cached.exists()) {
      _audioUrl = cached.path;
      _audioUrls = <String>[cached.path, ..._buildRemoteAudioUrls()];
      return cached.path;
    }
    final hasRemoteCandidate = _audioUrls.any(
      (url) => url.startsWith('http://') || url.startsWith('https://'),
    );
    if (!hasRemoteCandidate) {
      try {
        await _loadAudioUrl();
      } catch (e) {
        debugPrint('[ChartPlay] 导出补拉音源候选列表失败: $e');
        final candidates = _buildRemoteAudioUrls();
        _audioUrls = candidates;
        _audioUrl = candidates.isNotEmpty ? candidates.first : null;
      }
    }
    if (!mounted || _isLeaving) return null;
    return _downloadAudioFromUrls(_audioUrls, reportLoadingProgress: false);
  }

  /// 检查本地是否已缓存当前曲目的完整 PV 文件。
  Future<String?> _checkVideoExportCachedPv() async {
    if (!_hasNumericSongId) return null;
    final recorded = _pvCachedFilePath;
    if (recorded != null && recorded.isNotEmpty) {
      try {
        if (await File(recorded).exists()) return recorded;
      } catch (_) {}
      _pvCachedFilePath = null;
    }
    final cached = await SongMediaCache.instance.existingPv(_trimmedSongId);
    if (cached != null && await cached.exists()) {
      _pvCachedFilePath = cached.path;
      return cached.path;
    }
    return null;
  }

  /// 使用短超时 HEAD 快速探测当前曲目在源站是否存在可用 PV（视频正文下载量为 0 字节）。
  Future<({bool available, bool confirmedUnavailable, int? contentLengthBytes})>
      _probeVideoExportPv(String songId) async {
    try {
      final response = await ApiClient.headAbortable(
        Uri.parse(ApiUrls.wmcPvUrl(songId)),
        headers: {
          'Accept-Encoding': 'identity',
          ..._pvHeaders,
        },
        timeout: const Duration(seconds: 6),
      );
      if (response.statusCode == 404 || response.statusCode == 410) {
        return (
          available: false,
          confirmedUnavailable: true,
          contentLengthBytes: null,
        );
      }
      if (response.statusCode == 200 || response.statusCode == 206) {
        final contentType =
            response.headers['content-type']?.toLowerCase() ?? '';
        if (contentType.contains('text/html') ||
            contentType.contains('application/json')) {
          return (
            available: false,
            confirmedUnavailable: true,
            contentLengthBytes: null,
          );
        }
        final parsedLen = int.tryParse(response.headers['content-length'] ?? '');
        return (
          available: true,
          confirmedUnavailable: false,
          contentLengthBytes:
              parsedLen != null && parsedLen > 0 ? parsedLen : null,
        );
      }
    } catch (error) {
      debugPrint('[ChartPlay] 导出页 PV 探测失败: $error');
    }
    return (
      available: false,
      confirmedUnavailable: false,
      contentLengthBytes: null,
    );
  }

  String _formatPvSizeLabel(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// 导出页开启 PV 背景但未命中缓存时：
  /// 1. 先用短超时 HEAD 秒级确认源站是否存在 PV，无 PV 立即提示返回，避免久等转圈；
  /// 2. 仅移动网络下弹轻量流量确认，Wi-Fi 直接在导出页内以圆环进度条下载，不弹硬控对话框。
  Future<String?> _downloadVideoExportPv(
    BuildContext dialogContext, {
    SimaiPvDownloadProgressCallback? onProgress,
  }) async {
    final existing = await _checkVideoExportCachedPv();
    if (existing != null) return existing;
    if (!dialogContext.mounted) return null;
    if (!_hasNumericSongId) {
      AppToast.show(
        dialogContext.l10n.videoExportPvNotAvailable,
        tone: AppToastTone.warning,
      );
      return null;
    }

    onProgress?.call(progress: null, status: '正在检查 PV…');
    final probe = await _probeVideoExportPv(_trimmedSongId);
    if (!dialogContext.mounted) return null;
    if (probe.confirmedUnavailable) {
      AppToast.show(
        dialogContext.l10n.videoExportPvNotAvailable,
        tone: AppToastTone.warning,
      );
      return null;
    }
    if (!probe.available) {
      AppToast.show(
        dialogContext.l10n.videoExportPvDownloadFailed,
        tone: AppToastTone.warning,
      );
      return null;
    }

    final sizeText = probe.contentLengthBytes != null
        ? _formatPvSizeLabel(probe.contentLengthBytes!)
        : null;
    final isCellular = await NetworkTypeUtil.isCellularNetwork();
    if (!dialogContext.mounted) return null;

    if (isCellular) {
      final confirmed = await showDialog<bool>(
        context: dialogContext,
        builder: (ctx) {
          final l10n = ctx.l10n;
          final scheme = Theme.of(ctx).colorScheme;
          final warningColor =
              AppColors.warningOrange(Theme.of(ctx).brightness);
          return AppAlertDialog(
            icon: appDialogIconTile(
              Icons.warning_amber_rounded,
              warningColor,
            ),
            title: Text(l10n.videoExportPvNeedDownloadTitle),
            scrollable: true,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  sizeText != null
                      ? '${l10n.videoExportPvNeedDownloadBody}（约 $sizeText）'
                      : l10n.videoExportPvNeedDownloadBody,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: warningColor.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                    border: Border.all(
                      color: warningColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.signal_cellular_alt_rounded,
                        size: 18,
                        color: warningColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.videoExportPvCellularWarning,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.featureCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.videoExportPvDownloadAction),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !dialogContext.mounted) return null;
    }

    onProgress?.call(
      progress: null,
      status: sizeText != null ? '正在下载 PV（约 $sizeText）…' : '正在下载 PV…',
    );
    try {
      final file = await SongMediaCache.instance.ensurePv(
        _trimmedSongId,
        url: ApiUrls.wmcPvUrl(_trimmedSongId),
        headers: _pvHeaders,
        onProgress: (progress, speed, status) {
          final speedText = _formatLoadingSpeed(speed);
          final percentText =
              progress != null ? ' ${(progress * 100).round()}%' : '…';
          final suffix = speedText.isNotEmpty ? ' · $speedText' : '';
          onProgress?.call(
            progress: progress,
            status: '正在下载 PV$percentText$suffix',
          );
        },
      );
      _pvCachedFilePath = file.path;
      return file.path;
    } catch (error) {
      debugPrint('[ChartPlay] 导出页下载 PV 失败: $error');
      if (dialogContext.mounted) {
        final l10n = dialogContext.l10n;
        AppToast.show(
          _isPvNotFoundError(error)
              ? l10n.videoExportPvNotAvailable
              : l10n.videoExportPvDownloadFailed,
          tone: AppToastTone.warning,
        );
      }
      return null;
    }
  }

  Widget _buildVideoExportPvPreview(
    BuildContext context,
    String pvVideoPath,
    ValueListenable<double> timeListenable,
    bool isPlaying,
  ) {
    return _VideoExportPvPreview(
      pvVideoPath: pvVideoPath,
      timeListenable: timeListenable,
      isPlaying: isPlaying,
    );
  }

  /// 播放器仍在初始化时，重复点击左上角返回会让异步 GameWidget 与控制器
  /// 同时销毁。只接受第一次返回请求，避免重复 pop 叠加资源销毁。
  void _leavePlayerPage() {
    if (_isLeaving || !mounted) return;
    _isLeaving = true;
    unawaited(Navigator.of(context).maybePop<void>());
  }

  Future<void> _loadChart() async {
    debugPrint('[ChartPlay] load-start songId=$_trimmedSongId');
    _setLoadingStatus(appL10n.flowReadingChartSettings);
    if (widget.maidataContent.isEmpty) {
      debugPrint('[ChartPlay] load-abort: maidata content is empty');
      return;
    }

    // 必须等设置读完再建控制器。
    // _createController 是同步读内存里的设置的，如果这里不等，
    // 一旦 SharedPreferences 读得比建控制器慢，就会拿默认值建控制器，
    // 退出时再把默认值写回去——用户的设置就被默默清掉了。
    final results = await Future.wait<Object?>([
      ChartPlaySettingsStore().load(),
      ChartVideoExportSettingsStore().load(),
      ChartGameplaySettingsStore().load(),
    ]);
    final settings = results[0]! as ChartPlaySettings;
    if (!mounted || _isLeaving) return;
    _metronomeEnabled = settings.metronomeEnabled;
    _metronomeSpeed = settings.metronomeSpeed;
    _metronomeSpeedNotifier.value = _metronomeSpeed;
    _metronomeSoundEnabled = settings.metronomeSoundEnabled;
    debugPrint('[ChartPlay] settings-ready');
    final Future<void>? pvLoadFuture =
        _canLoadRemotePv ? _loadPvBackground() : null;

    _audioLoadFailed = false;
    if (widget.loadAudio) {
      _setLoadingStatus(appL10n.flowFindingAudio);
      try {
        await _loadAudioUrl();
      } catch (e) {
        debugPrint('[ChartPlay] 准备音源候选列表失败: $e');
        final candidates = _buildRemoteAudioUrls();
        _audioUrls = candidates;
        _audioUrl = candidates.isNotEmpty ? candidates.first : null;
      }
    } else {
      _audioUrl = null;
      _audioUrls = const <String>[];
      debugPrint('[ChartPlay] audio loading disabled by user');
    }

    if (!mounted || _isLeaving) return;
    debugPrint('[ChartPlay] audio-lookup-ready hasUrl=${_audioUrl != null}');

    // 加载曲绘
    _setLoadingStatus(appL10n.flowPreparingCoverArt);
    await _loadBackgroundImage();
    if (!mounted || _isLeaving) return;
    debugPrint(
      '[ChartPlay] background-ready hasProvider=${_bgImageProvider != null}',
    );

    try {
      _setLoadingStatus(appL10n.flowParsingChartData);
      var simaiFile = SimaiFile(widget.maidataContent);

      String? chartText;
      String? resolvedInote;
      String? firstStr;

      // 如果用户选择了难度，直接使用该难度
      if (widget.selectedInote != null) {
        chartText = simaiFile.getValue("inote_${widget.selectedInote}");
        if (chartText != null) {
          resolvedInote = widget.selectedInote;
          debugPrint("Found chart for selected inote_${widget.selectedInote}");
        } else {
          debugPrint(
              "No chart found for selected inote_${widget.selectedInote}");
        }
      } else {
        // 否则按优先级查找
        List<String> inotePriorities = ['4', '3', '5', '2', '6', '7', '1'];
        for (var inoteNum in inotePriorities) {
          chartText = simaiFile.getValue("inote_$inoteNum");
          if (chartText != null) {
            resolvedInote = inoteNum;
            debugPrint("Found chart for inote_$inoteNum");
            break;
          }
        }
      }

      if (chartText == null) {
        debugPrint("No chart found in maidata");
        await _loadFallbackChart(pvLoadFuture: pvLoadFuture);
        return;
      }

      firstStr = simaiFile.getValue("first");
      double offset = 0.0;
      if (firstStr != null) {
        offset = double.tryParse(firstStr) ?? 0.0;
      }

      final chart = SimaiConvert.deserialize(chartText);
      debugPrint(
        '[ChartPlay] chart-parsed notes=${chart.noteCollections.length} '
        'timings=${chart.timingChanges.length}',
      );

      // 确定音频来源：本地文件校验存在性后直接使用，远程音源一次性传入完整候选列表走持久缓存。
      String? audioPath;
      final localAudioPath = widget.audioFilePath;
      final hasExplicitLocalAudio = widget.loadAudio &&
          localAudioPath != null &&
          localAudioPath.isNotEmpty;
      if (hasExplicitLocalAudio) {
        if (await File(localAudioPath).exists()) {
          audioPath = localAudioPath;
        } else {
          debugPrint('[ChartPlay] 本地音频文件不存在: $localAudioPath');
        }
      } else if (widget.loadAudio && _audioUrls.isNotEmpty) {
        audioPath = await _downloadAudioFromUrls(_audioUrls);
      }
      if (!mounted || _isLeaving) return;
      _audioLoadFailed = widget.loadAudio &&
          audioPath == null &&
          (_hasNumericSongId || hasExplicitLocalAudio);

      final difficulty = _difficultyForInote(resolvedInote);
      final videoMetadata = _buildVideoMetadata(
        simaiFile,
        difficulty,
        inoteNum: resolvedInote,
      );
      final videoOutputPath = await _buildVideoOutputPath();
      if (!mounted || _isLeaving) return;

      if (pvLoadFuture != null) {
        if (!_pvLoadingDone) {
          _setLoadingStatus(appL10n.chartPlayWaitingForPv, progress: 1.0);
        }
        await pvLoadFuture;
        if (!mounted || _isLeaving) return;
      }

      _pausePortablePlayerIfNeeded();

      late final SimaiPlayerController controller;
      setState(() {
        _chartOffset = offset;
        _controller?.removeListener(_scheduleSettingsSave);
        _controller?.removeListener(_onControllerChangedForPv);
        _controller?.timeNotifier.removeListener(_onChartTimeChangedForPv);
        _controller?.dispose();
        _gameplayController?.removeListener(_onGameplayControllerChanged);
        _gameplayController?.dispose();
        controller = _createController(chart, audioPath);
        _controller = controller;
        // 控制器就绪后立即停止加载文案轮播，防止每 3 秒触发整页 setState 导致图集重建。
        _loadingTipTimer?.cancel();
        _loadingTipTimer = null;
        _gameplayController = _createGameplayController(
          chart,
          audioPath,
          controller,
        );
        _videoMetadata = videoMetadata;
        _videoExportOptions = SimaiVideoExportOptions(
          outputPath: videoOutputPath,
        );
        _playerKey = UniqueKey();
      });
      if (_pvReady) {
        _pvForceSeek = true;
        unawaited(_syncPv());
      }
      _showMediaLoadFailureHintsIfNeeded();
      debugPrint(
        '[ChartPlay] controller-published audioPath=${audioPath != null} '
        'background=${_bgImageProvider != null}',
      );
    } catch (e, stack) {
      debugPrint('[ChartPlay] chart-load-error: $e\n$stack');
      if (!mounted || _isLeaving) return;
      await _loadFallbackChart(pvLoadFuture: pvLoadFuture);
    }
  }

  SimaiChartDifficulty? _difficultyForInote(String? inoteNum) {
    if (_isUtageChart) {
      return SimaiChartDifficulty.utage;
    }
    switch (inoteNum) {
      case '1':
      case '2':
        return SimaiChartDifficulty.basic;
      case '3':
        return SimaiChartDifficulty.advanced;
      case '4':
        return SimaiChartDifficulty.expert;
      case '5':
        return SimaiChartDifficulty.master;
      case '6':
        return SimaiChartDifficulty.reMaster;
      case '7':
        return SimaiChartDifficulty.utage;
      default:
        return null;
    }
  }

  SimaiVideoMetadata? _buildVideoMetadata(
    SimaiFile simaiFile,
    SimaiChartDifficulty? difficulty, {
    String? inoteNum,
  }) {
    if (difficulty == null || _bgImageProvider == null) return null;
    try {
      return SimaiVideoMetadata.fromSimaiFile(
        simaiFile,
        coverImageProvider: _bgImageProvider!,
        difficulty: difficulty,
        inoteKey: inoteNum,
        fallbackTitle: widget.songTitle,
        fallbackArtist: '',
        fallbackLevel: difficulty == SimaiChartDifficulty.utage ? '?' : null,
      );
    } catch (e) {
      debugPrint("Video export metadata unavailable: $e");
      return null;
    }
  }

  void _handleOpenExportRequest() {
    if (!mounted || _isLeaving) return;
    final controller = _controller;
    final metadata = _videoMetadata;
    if (controller == null || metadata == null) return;
    if (SimaiVideoExporter.instance.isExportPageOpen) return;
    final task = SimaiVideoExporter.instance.activeTask ??
        SimaiVideoExporter.instance.lastCompletedTask;
    if (task == null) return;
    unawaited(controller.pause());
    unawaited(
      Navigator.of(context).push<SimaiVideoExportResult>(
        MaterialPageRoute(
          builder: (_) => SimaiVideoExportPage(
            controller: controller,
            metadata: metadata,
            initialOptions: _videoExportOptions,
            initialSettings: ChartVideoExportSettingsStore().savedSettings,
            onSettingsChanged: _onVideoExportSettingsChanged,
            resolveAudioFilePath: _resolveVideoExportAudio,
            checkCachedPvFilePath: _checkVideoExportCachedPv,
            downloadPvFilePath: _downloadVideoExportPv,
            pvPreviewBuilder: _buildVideoExportPvPreview,
            initialUsePvBackground: widget.loadPv,
            initialPvVideoPath: widget.loadPv ? _pvCachedFilePath : null,
            task: task,
            displayFont: AppTheme.font(fontWeight: FontWeight.w700),
            textStyleResolver: _resolveChartTextStyle,
            prepareFonts: _prepareChartFonts,
            customNoteSkinSettingBuilder: (_, c, onChanged) =>
                ChartPlayCustomNoteSkinTile(controller: c, onChanged: onChanged),
            customHitSoundSettingBuilder: (_, c, onChanged) =>
                ChartPlayCustomHitSoundTile(controller: c, onChanged: onChanged),
            onVideoExported: _onVideoExported,
          ),
        ),
      ),
    );
  }

  TextStyle _resolveChartTextStyle(TextStyle style) {
    final font = AppTheme.font(fontWeight: style.fontWeight ?? FontWeight.w400);
    return style.copyWith(
      fontFamily: font.fontFamily,
      fontFamilyFallback: font.fontFamilyFallback,
      fontVariations: font.fontVariations,
    );
  }

  Future<void> _prepareChartFonts() async {
    try {
      await AppFontService.instance
          .ensureLoaded()
          .timeout(const Duration(seconds: 6), onTimeout: () => false);
    } catch (e) {
      debugPrint('[ChartPlay] 准备导出字体失败（继续使用已加载字体）: $e');
    }
  }

  void _onVideoExported(SimaiVideoExportResult result) {
    final sizeMb = (result.fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
    debugPrint(
      'Video exported: ${result.width}x${result.height}@${result.fps}fps '
      '(${result.duration.inSeconds}s, $sizeMb MB, savedToGallery=${result.savedToGallery}) -> ${result.path}',
    );
    if (!mounted) return;
    if (result.savedToGallery) {
      AppToast.show(
        '视频已保存到相册（${result.width}×${result.height} · ${result.fps}fps · $sizeMb MB）',
        tone: AppToastTone.success,
      );
      return;
    }
    AppToast.show(
        context.l10n.flowVideoGeneratedTapSaveToPhotosOn(
            (result.width).toString(),
            (result.height).toString(),
            (sizeMb).toString()),
        tone: AppToastTone.warning);
  }

  // Android 11+ 的 Movies 是分区存储目录，第三方库直接在其中创建临时文件
  // 会被系统拒绝（EPERM）。让 simai_flutter 使用应用临时目录，再通过它的
  // “保存到相册”流程交给 MediaStore 写入公开媒体库。
  Future<String?> _buildVideoOutputPath() async {
    try {
      if (Platform.isAndroid) return null;

      final directory = await getApplicationDocumentsDirectory();
      final safeTitle = widget.songTitle.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      return '${directory.path}/simai_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    } catch (e) {
      debugPrint('构建视频输出路径失败: $e');
      return null;
    }
  }

  List<String> _buildRemoteAudioUrls() {
    if (!_hasNumericSongId) return const <String>[];
    final audioId = SongMediaCache.audioIdFor(_trimmedSongId);
    return <String>[
      if (audioId > 0) 'https://assets2.lxns.net/maimai/music/$audioId.mp3',
      ApiUrls.wmcAudioUrl(_trimmedSongId),
    ];
  }

  Future<void> _loadAudioUrl() async {
    _audioUrl = null;
    _audioUrls = const <String>[];

    // 优先使用本地音频文件
    final localPath = widget.audioFilePath;
    if (localPath != null && localPath.isNotEmpty) {
      _audioUrl = localPath;
      _audioUrls = <String>[localPath];
      debugPrint('[ChartPlay] 使用本地音频文件: $_audioUrl');
      return;
    }

    // 自定义谱面等非数字曲目 ID 无远程音源，直接跳过网络查找
    if (!_hasNumericSongId) {
      debugPrint('[ChartPlay] 非数字曲目 ID($_trimmedSongId)，跳过远程音源查找');
      return;
    }

    // 优先读取本地持久缓存，已有音源时离线也能进入播放页
    final cached = await _findCachedAudio();
    if (cached != null) {
      if (!mounted || _isLeaving) return;
      _audioUrl = cached.path;
      _audioUrls = <String>[cached.path, ..._buildRemoteAudioUrls()];
      _setLoadingStatus(appL10n.flowAudioLoadedFromLocalCache, progress: 1);
      debugPrint('[ChartPlay] 命中本地音源缓存: ${cached.path}');
      return;
    }

    // 与随身听、导出、参考时长统一：O(1) 推导落雪音源 ID 并保留落雪 + WMC 双源候选
    final candidates = _buildRemoteAudioUrls();
    _audioUrls = candidates;
    _audioUrl = candidates.isNotEmpty ? candidates.first : null;
    debugPrint(
      '[ChartPlay] 构建远程音源候选列表 songId=$_trimmedSongId '
      'count=${candidates.length}',
    );
  }

  Future<void> _loadBackgroundImage() async {
    // 优先使用本地背景图片
    if (widget.bgImagePath != null && widget.bgImagePath!.isNotEmpty) {
      _bgImageProvider = FileImage(File(widget.bgImagePath!));
      debugPrint('[ChartPlay] 使用本地背景图片: ${widget.bgImagePath}');
      return;
    }

    try {
      _bgImageProvider = await CoverUtil.resolveCoverProvider(_trimmedSongId);
      debugPrint(
          '[ChartPlay] 已解析歌曲曲绘背景 songId=$_trimmedSongId');
    } catch (e) {
      debugPrint('[ChartPlay] 加载曲绘背景失败: $e');
      _bgImageProvider = null;
    }
  }

  Future<File?> _findCachedAudio() {
    if (!_hasNumericSongId) return Future<File?>.value(null);
    final audioId = SongMediaCache.audioIdFor(_trimmedSongId);
    return SongMediaCache.instance.existingAudio(
      _trimmedSongId,
      audioId: audioId > 0 ? audioId : null,
    );
  }

  Future<String?> _downloadAudioFromUrls(
    List<String> urls, {
    bool reportLoadingProgress = true,
  }) async {
    if (!mounted || _isLeaving || urls.isEmpty) return null;

    final remoteUrls = <String>[];
    for (final url in urls) {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        remoteUrls.add(url);
      } else if (url.isNotEmpty && await File(url).exists()) {
        return url;
      }
    }
    if (remoteUrls.isEmpty || !_hasNumericSongId) return null;

    try {
      final audioId = SongMediaCache.audioIdFor(_trimmedSongId);
      final file = await SongMediaCache.instance.ensureAudio(
        _trimmedSongId,
        audioId: audioId > 0 ? audioId : null,
        urls: remoteUrls,
        onProgress: reportLoadingProgress
            ? (progress, speed, status) {
                if (!mounted || _isLeaving) return;
                _setLoadingStatus(status, progress: progress, speed: speed);
              }
            : null,
      );
      if (!mounted || _isLeaving) return null;
      return await file.exists() ? file.path : null;
    } catch (error) {
      debugPrint('[ChartPlay] 谱面音源准备失败: $error');
      return null;
    }
  }

  Future<void> _loadFallbackChart({Future<void>? pvLoadFuture}) async {
    if (!mounted || _isLeaving) return;
    const sampleChart = """
&inote_1=(140){4}
1,2,3,4,5,6,7,8,
1h[4:1],2h[4:1],3h[4:1],4h[4:1],
1b,2b,3b,4b,
C,A1,A2,A3,A4,A5,A6,A7,A8,
B1,B2,B3,B4,B5,B6,B7,B8,
1-4[4:1],2-5[4:1],
E
""";

    var simaiFile = SimaiFile(sampleChart);
    var chartText = simaiFile.getValue("inote_1");
    if (chartText != null) {
      final chart = SimaiConvert.deserialize(chartText);

      // 确定音频来源
      String? audioPath;
      final localAudioPath = widget.audioFilePath;
      final hasExplicitLocalAudio = widget.loadAudio &&
          localAudioPath != null &&
          localAudioPath.isNotEmpty;
      if (hasExplicitLocalAudio) {
        if (await File(localAudioPath).exists()) {
          audioPath = localAudioPath;
        } else {
          debugPrint('[ChartPlay] 回退谱面本地音频文件不存在: $localAudioPath');
        }
      } else if (widget.loadAudio && _audioUrls.isNotEmpty) {
        audioPath = await _downloadAudioFromUrls(_audioUrls);
      }
      if (!mounted || _isLeaving) return;
      _audioLoadFailed = widget.loadAudio &&
          audioPath == null &&
          (_hasNumericSongId || hasExplicitLocalAudio);

      if (pvLoadFuture != null) {
        if (!_pvLoadingDone) {
          _setLoadingStatus(appL10n.chartPlayWaitingForPv, progress: 1.0);
        }
        await pvLoadFuture;
        if (!mounted || _isLeaving) return;
      }

      _pausePortablePlayerIfNeeded();

      late final SimaiPlayerController controller;
      if (!mounted || _isLeaving) return;
      setState(() {
        _chartOffset = 0.0;
        _controller?.removeListener(_scheduleSettingsSave);
        _controller?.removeListener(_onControllerChangedForPv);
        _controller?.timeNotifier.removeListener(_onChartTimeChangedForPv);
        _controller?.dispose();
        _gameplayController?.removeListener(_onGameplayControllerChanged);
        _gameplayController?.dispose();
        controller = _createController(chart, audioPath);
        _controller = controller;
        // 回退谱面控制器就绪后同样停止加载文案轮播，避免周期重建。
        _loadingTipTimer?.cancel();
        _loadingTipTimer = null;
        _gameplayController = _createGameplayController(
          chart,
          audioPath,
          controller,
        );
        _videoMetadata = null;
        _playerKey = UniqueKey();
      });
      if (_pvReady) {
        _pvForceSeek = true;
        unawaited(_syncPv());
      }
      _showMediaLoadFailureHintsIfNeeded();
      debugPrint('[ChartPlay] fallback-controller-published');
    }
  }

  @override
  void dispose() {
    _isLeaving = true;
    _inGameplay = false;
    _pvLoadGen++;
    _stopPvPeriodicSyncTimer();
    _cancelPvPausedSeekThrottle();
    _loadingDiagnosticTimer?.cancel();
    _loadingTipTimer?.cancel();
    _loadingTipTimer = null;
    debugPrint('[ChartPlay] dispose');
    VideoExportBackgroundService.instance.openExportRequestNonce
        .removeListener(_handleOpenExportRequest);
    WidgetsBinding.instance.removeObserver(this);
    // 兜底恢复游玩期间开启的边沿手势保护与临时状态栏隐藏，避免异常离页残留。
    unawaited(RefreshRateUtil.setGameplayEdgeProtection(false));
    unawaited(NavigationPreferences.instance.setGameplayStatusBarHidden(false));
    // 离开播放页就把刷新率交还系统，避免整个 App 一直顶着高刷耗电
    RefreshRateUtil.restore();
    // 解除 initState 里的竖屏锁，让其它页面（视频播放等）能正常横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 先把设置读出来写下去，再拆控制器——saveFrom 需要读控制器的当前值。
    // 这里不能 await，但 saveFrom 是同步跑到第一个 await 才挂起的，
    // capture 一定发生在 dispose 之前。
    _flushSettingsNow();
    _controller?.removeListener(_scheduleSettingsSave);
    _controller?.removeListener(_onControllerChangedForPv);
    _controller?.timeNotifier.removeListener(_onChartTimeChangedForPv);
    final pv = _pvController;
    _pvController = null;
    _pvReady = false;
    _pvWantPlaying = false;
    _pvLastSeekAt = null;
    if (pv != null) {
      unawaited(pv.dispose());
    }
    final pvStream = _pvVideoStream;
    _pvVideoStream = null;
    pvStream?.close();
    _gameplayController?.removeListener(_onGameplayControllerChanged);
    _gameplayController?.dispose();
    _controller?.dispose();
    _metronomeSpeedNotifier.dispose();
    super.dispose();
  }

  /// 更新节拍器流速并实时通知抽屉滑块与节拍器轨道重绘，同时防抖落盘。
  void _onMetronomeSpeedChanged(double value) {
    if (!mounted || _isLeaving) return;
    final safeValue = value.isFinite ? value : 1.0;
    final quantized = ((safeValue.clamp(0.5, 3.0) * 10).round() / 10.0)
        .clamp(0.5, 3.0)
        .toDouble();
    if ((_metronomeSpeed - quantized).abs() < 1e-6) return;
    _metronomeSpeed = quantized;
    _metronomeSpeedNotifier.value = quantized;
    _scheduleSettingsSave();
  }

  /// 构建侧边栏「显示设置」中的节拍器流速滑块，确保抽屉打开时拖动实时丝滑刷新。
  Widget _buildMetronomeSpeedSetting() {
    return ValueListenableBuilder<double>(
      valueListenable: _metronomeSpeedNotifier,
      builder: (context, speed, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final clamped = speed.clamp(0.5, 3.0).toDouble();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.chartMetronomeSpeed,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      '${clamped.toStringAsFixed(1)}x',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Slider(
                value: clamped,
                min: 0.5,
                max: 3.0,
                divisions: 25,
                onChanged: _onMetronomeSpeedChanged,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null && !_hasLoggedPlayerBuild) {
      _hasLoggedPlayerBuild = true;
      debugPrint('[ChartPlay] SimaiPlayerPage-build');
    }
    final appBarTheme = AppBarTheme.of(context);
    final titleStyle = appBarTheme.titleTextStyle ??
        Theme.of(context).textTheme.titleLarge ??
        const TextStyle();
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller == null
          ? _buildLoadingView()
          : AppBarTheme(
              // 黑底上保留纯白的标题、返回键和操作按钮。
              data: appBarTheme.copyWith(
                iconTheme: (appBarTheme.iconTheme ?? const IconThemeData())
                    .copyWith(color: Colors.white, opacity: 1),
                actionsIconTheme:
                    (appBarTheme.actionsIconTheme ?? const IconThemeData())
                        .copyWith(color: Colors.white, opacity: 1),
                titleTextStyle: titleStyle.merge(AppTheme.font(
                  fontWeight: titleStyle.fontWeight,
                  color: Colors.white,
                )),
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
              child: SimaiPlayerPage(
                key: _playerKey,
                controller: _controller!,
                gameplayController: _gameplayController,
                onEnterGameplay: _handleEnterGameplay,
                onExitGameplay: _handleExitGameplay,
                backgroundVideo: _buildPvBackground(),
                hasPvBackground: _pvReady,
                initialExportUsePvBackground: widget.loadPv,
                initialExportPvVideoPath:
                    widget.loadPv ? _pvCachedFilePath : null,
                videoExportMetadata: _videoMetadata,
                videoExportOptions: _videoExportOptions,
                videoExportSettings:
                    ChartVideoExportSettingsStore().savedSettings,
                onVideoExportSettingsChanged: _onVideoExportSettingsChanged,
                resolveVideoExportAudio: _resolveVideoExportAudio,
                checkCachedPvFilePath: _checkVideoExportCachedPv,
                downloadPvFilePath: _downloadVideoExportPv,
                pvPreviewBuilder: _buildVideoExportPvPreview,
                onVideoExported: _onVideoExported,
                onBack: _leavePlayerPage,
                disposeController: false,
                displayFont: AppTheme.font(fontWeight: FontWeight.w700),
                textStyleResolver: _resolveChartTextStyle,
                prepareFonts: _prepareChartFonts,
                switchBuilder: (_, value, onChanged) => AppSwitch(
                  value: value,
                  onChanged: onChanged,
                ),
                extraDisplaySettings: _buildMetronomeSpeedSetting(),
                customNoteSkinSettingBuilder: (_, c, onChanged) =>
                    ChartPlayCustomNoteSkinTile(
                      controller: c,
                      onChanged: onChanged,
                    ),
                customHitSoundSettingBuilder: (_, c, onChanged) =>
                    ChartPlayCustomHitSoundTile(
                      controller: c,
                      onChanged: onChanged,
                    ),
                beforeTimeline: ValueListenableBuilder<double>(
                  valueListenable: _metronomeSpeedNotifier,
                  builder: (_, speed, __) => ChartPlayMetronome(
                    key: _metronomeKey,
                    controller: _controller!,
                    enabled: _metronomeEnabled,
                    soundEnabled: _metronomeSoundEnabled,
                    speed: speed,
                    onEnabledChanged: (enabled) {
                      setState(() => _metronomeEnabled = enabled);
                      _scheduleSettingsSave();
                    },
                    onSoundChanged: (enabled) {
                      setState(() => _metronomeSoundEnabled = enabled);
                      _scheduleSettingsSave();
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLoadingView() {
    final scheme = Theme.of(context).colorScheme;
    final speedText = _formatLoadingSpeed(_loadingSpeed);
    final pvSpeedText = _formatLoadingSpeed(_pvLoadingSpeed);
    final pvStageText = _pvLoadingStage.isEmpty
        ? context.l10n.chartPlayPreparingPv
        : _pvLoadingStage;
    return Stack(
      fit: StackFit.expand,
      children: [
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white70),
                onPressed: _leavePlayerPage,
              ),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.music_note_rounded,
                      color: Colors.white70, size: 42),
                  const SizedBox(height: 18),
                  Text(
                    _loadingStage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  SmoothLinearProgressIndicator(
                    value: _loadingProgress,
                    color: scheme.primary,
                    backgroundColor: Colors.white24,
                    minHeight: 5,
                  ),
                  if (speedText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(speedText,
                        style: AppTheme.number(
                            color: Colors.white70, fontSize: 12)),
                  ],
                  if (_canLoadRemotePv) ...[
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                            AppDesignTokens.radiusMedium),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.ondemand_video_rounded,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  pvStageText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                              if (_pvLoadingProgress != null &&
                                  !_pvLoadingFailed) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${(_pvLoadingProgress! * 100).round()}%',
                                  style: AppTheme.number(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          SmoothLinearProgressIndicator(
                            value: _pvLoadingProgress,
                            color: _pvLoadingFailed
                                ? Colors.white38
                                : scheme.primary,
                            backgroundColor: Colors.white24,
                            minHeight: 4,
                          ),
                          if (pvSpeedText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              pvSpeedText,
                              textAlign: TextAlign.right,
                              style: AppTheme.number(
                                fontSize: 11.5,
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (_loadingTip.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 20,
                      child: MarqueeText(
                        key: ValueKey(_loadingTip),
                        text: _loadingTip,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.5,
                        ),
                        gap: 28,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 视频导出预览页使用的静音 PV 播放器组件。
class _VideoExportPvPreview extends StatefulWidget {
  final String pvVideoPath;
  final ValueListenable<double> timeListenable;
  final bool isPlaying;

  const _VideoExportPvPreview({
    required this.pvVideoPath,
    required this.timeListenable,
    required this.isPlaying,
  });

  @override
  State<_VideoExportPvPreview> createState() => _VideoExportPvPreviewState();
}

class _VideoExportPvPreviewState extends State<_VideoExportPvPreview> {
  static const Duration _seekGraceWindow = Duration(milliseconds: 800);

  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _syncing = false;
  bool _syncPending = false;
  bool _wantPlaying = false;
  bool _forceSeek = true;
  bool _pausedSeekPending = false;
  DateTime? _lastSeekAt;
  Timer? _pausedSeekThrottle;
  int _loadGen = 0;

  @override
  void initState() {
    super.initState();
    widget.timeListenable.addListener(_onTimeChanged);
    unawaited(_initController());
  }

  @override
  void didUpdateWidget(_VideoExportPvPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.timeListenable != oldWidget.timeListenable) {
      oldWidget.timeListenable.removeListener(_onTimeChanged);
      widget.timeListenable.addListener(_onTimeChanged);
    }
    if (widget.pvVideoPath != oldWidget.pvVideoPath) {
      unawaited(_initController());
      return;
    }
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _cancelPausedSeekThrottle();
        _forceSeek = false;
      } else {
        _forceSeek = true;
      }
      unawaited(_sync());
    }
  }

  @override
  void dispose() {
    _loadGen++;
    _cancelPausedSeekThrottle();
    widget.timeListenable.removeListener(_onTimeChanged);
    final controller = _controller;
    _controller = null;
    _initialized = false;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  bool _inSeekGraceWindow() =>
      _lastSeekAt != null &&
      DateTime.now().difference(_lastSeekAt!) < _seekGraceWindow;

  void _cancelPausedSeekThrottle() {
    _pausedSeekThrottle?.cancel();
    _pausedSeekThrottle = null;
    _pausedSeekPending = false;
  }

  Future<void> _initController() async {
    final gen = ++_loadGen;
    _cancelPausedSeekThrottle();
    final old = _controller;
    _controller = null;
    _initialized = false;
    _wantPlaying = false;
    _lastSeekAt = null;
    _forceSeek = true;
    if (old != null) {
      unawaited(old.dispose());
    }

    final file = File(widget.pvVideoPath);
    if (!await file.exists()) return;
    final controller = VideoPlayerController.file(
      file,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      viewType: VideoViewType.textureView,
    );
    try {
      await controller.initialize();
      await controller.setVolume(0.0);
      await controller.setLooping(false);
      await controller.seekTo(Duration.zero);
      if (!mounted || gen != _loadGen) {
        unawaited(controller.dispose());
        return;
      }
      setState(() {
        _controller = controller;
        _initialized = true;
      });
      unawaited(_sync());
    } catch (e) {
      debugPrint('[ChartPlay] 导出预览 PV 初始化失败: $e');
      unawaited(controller.dispose());
    }
  }

  void _onTimeChanged() {
    if (!_initialized || _controller == null) return;
    if (widget.isPlaying) {
      _cancelPausedSeekThrottle();
      final pv = _controller!;
      final durationSec = pv.value.duration.inMilliseconds / 1000.0;
      final targetSec = widget.timeListenable.value;
      if (durationSec > 0 && targetSec >= 0 && targetSec < durationSec) {
        if (!_wantPlaying ||
            (!pv.value.isPlaying &&
                !pv.value.isBuffering &&
                !_inSeekGraceWindow())) {
          unawaited(_sync());
        }
      } else if (durationSec > 0 &&
          _wantPlaying &&
          (targetSec < 0 || targetSec >= durationSec)) {
        unawaited(_sync());
      }
      return;
    }
    if (_pausedSeekThrottle == null) {
      _triggerPausedSeek();
    } else {
      _pausedSeekPending = true;
    }
  }

  void _triggerPausedSeek() {
    _forceSeek = true;
    unawaited(_sync());
    _pausedSeekThrottle = Timer(const Duration(milliseconds: 120), () {
      _pausedSeekThrottle = null;
      if (!mounted || !_initialized) {
        _pausedSeekPending = false;
        return;
      }
      if (_pausedSeekPending) {
        _pausedSeekPending = false;
        if (!widget.isPlaying) {
          _triggerPausedSeek();
        }
      }
    });
  }

  Future<void> _sync() async {
    final pv = _controller;
    if (!_initialized || pv == null || !pv.value.isInitialized) return;
    _syncPending = true;
    if (_syncing) return;
    _syncing = true;
    try {
      while (_syncPending && mounted && identical(_controller, pv)) {
        _syncPending = false;
        final durationMs = pv.value.duration.inMilliseconds;
        if (durationMs <= 0) continue;
        final durationSec = durationMs / 1000.0;
        final targetSec = widget.timeListenable.value;
        final clampedSec = targetSec.clamp(0.0, durationSec).toDouble();
        final targetDur = Duration(milliseconds: (clampedSec * 1000).round());
        final forceSeek = _forceSeek;
        _forceSeek = false;

        if (!widget.isPlaying || targetSec < 0 || targetSec >= durationSec) {
          if (pv.value.isPlaying || _wantPlaying) {
            await pv.pause();
            _wantPlaying = false;
            if (!mounted || !identical(_controller, pv)) break;
          } else {
            _wantPlaying = false;
          }
          final currentPos = pv.value.position;
          if (targetSec < 0) {
            if (currentPos.inMilliseconds > 80) {
              await pv.seekTo(Duration.zero);
              _lastSeekAt = DateTime.now();
            }
          } else if (forceSeek ||
              (currentPos - targetDur).abs().inMilliseconds > 80) {
            await pv.seekTo(targetDur);
            _lastSeekAt = DateTime.now();
          }
          continue;
        }

        final inGrace = _inSeekGraceWindow();
        final currentPos = (!pv.value.isBuffering && !inGrace)
            ? ((await pv.position) ?? pv.value.position)
            : pv.value.position;
        if (!mounted || !identical(_controller, pv)) break;
        if (!widget.isPlaying) {
          _syncPending = true;
          continue;
        }

        final latestTargetSec = widget.timeListenable.value;
        if (latestTargetSec < 0 || latestTargetSec >= durationSec) {
          _syncPending = true;
          continue;
        }
        final latestTargetDur = Duration(
          milliseconds:
              (latestTargetSec.clamp(0.0, durationSec).toDouble() * 1000)
                  .round(),
        );
        final driftMs = (currentPos - latestTargetDur).abs().inMilliseconds;
        final isCompleted = pv.value.position >= pv.value.duration &&
            pv.value.duration > Duration.zero;
        final skipSeek =
            !forceSeek && _wantPlaying && (pv.value.isBuffering || inGrace);
        final shouldSeek = !skipSeek &&
            (forceSeek ||
                (!_wantPlaying && driftMs > 80) ||
                (!pv.value.isBuffering && !inGrace && driftMs > 250) ||
                (isCompleted && latestTargetSec < durationSec - 0.1));

        if (shouldSeek) {
          await pv.seekTo(latestTargetDur);
          _lastSeekAt = DateTime.now();
          if (!mounted || !identical(_controller, pv)) break;
          if (!widget.isPlaying) {
            _syncPending = true;
            continue;
          }
        }

        if (!_wantPlaying ||
            isCompleted ||
            (!pv.value.isPlaying && !pv.value.isBuffering)) {
          await pv.play();
          _wantPlaying = true;
          if (!mounted || !identical(_controller, pv)) break;
        }
      }
    } catch (e) {
      debugPrint('[ChartPlay] 导出预览 PV 同步异常: $e');
    } finally {
      _syncing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.timeListenable,
      builder: (context, pvTime, _) {
        final pv = _controller;
        if (!_initialized || pv == null || !pv.value.isInitialized) {
          return const SizedBox.shrink();
        }
        final durationSec = pv.value.duration.inMilliseconds / 1000.0;
        if (pvTime < 0 || (durationSec > 0 && pvTime >= durationSec)) {
          return const SizedBox.shrink();
        }
        final videoSize = pv.value.size;
        final width = videoSize.width > 0 ? videoSize.width : 16.0;
        final height = videoSize.height > 0 ? videoSize.height : 9.0;
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: width,
            height: height,
            child: VideoPlayer(pv),
          ),
        );
      },
    );
  }
}
