import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../api/ApiUrls.dart';
import '../../constant/LoadingTipsConstant.dart';
import '../../service/Portable/PortablePlayerController.dart';
import '../../service/Media/SongMediaCache.dart';
import '../../utils/AppTheme.dart';
import '../../utils/NavigationPreferences.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppHeader.dart';
import '../../widgets/AppUi.dart' show PressScale;
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../../utils/AppDesignTokens.dart';

/// 歌曲 PV 播放页。
///
/// 优先复用已有完整缓存，否则直接下载完整 PV 后播放。无音轨的 PV 使用同曲音源。
class SongPvPage extends StatefulWidget {
  const SongPvPage({
    super.key,
    required this.songId,
    required this.songTitle,
  });

  final String songId;
  final String songTitle;

  @override
  State<SongPvPage> createState() => _SongPvPageState();
}

class _SongPvPageState extends State<SongPvPage> {
  static const _videoHeaders = <String, String>{
    'User-Agent': 'Mozilla/5.0 (Android) AppleWebKit/537.36',
    'Referer': 'https://download.wmc.pub/',
  };

  VideoPlayerController? _controller;
  late Future<void> _initializeFuture;
  AudioPlayer? _audio;
  bool _audioReady = false;
  Duration? _audioDuration;
  Timer? _audioSyncTimer;
  bool _audioUnavailable = false;
  bool _syncingAudio = false;
  bool _audioSyncPending = false;
  bool _seekInProgress = false;
  bool _audioShouldPlay = false;
  static const _maxDelayMs = 2000;
  static const _delaySliderStepMs = 10;
  int _audioDelayMs = 0;
  SharedPreferences? _preferences;
  String get _delayKey => 'pv_audio_delay_ms_${widget.songId}';
  bool _forceAudioSeek = false;

  bool _fullscreen = false;
  bool _leaving = false;
  bool _changingFullscreen = false;
  bool? _isTablet;
  bool _playbackControlsVisible = true;
  Timer? _hideControlsTimer;
  static const _portrait = [DeviceOrientation.portraitUp];
  static const _landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const _allOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  List<DeviceOrientation> get _defaultOrientations =>
      (_isTablet ?? false) ? _allOrientations : _portrait;

  List<DeviceOrientation> get _activeOrientations => (_isTablet ?? false)
      ? _allOrientations
      : (_fullscreen ? _landscape : _portrait);

  double? _downloadProgress;
  double _downloadSpeed = 0;
  String _downloadStage = '';
  bool _downloading = false;

  Timer? _tipTimer;
  String _loadingTip = LoadingTipsConstant.getRandomLoadingTip();
  bool _usingLocalFile = false;

  String get _loadingStatus => _usingLocalFile
      ? appL10n.flowReadingLocalVideo
      : (_downloadStage.isEmpty
          ? appL10n.videoExportPvDownloading
          : _downloadStage);

  bool _isSeeking = false;
  double _seekDragOffset = 0;
  Duration _seekStartPosition = Duration.zero;
  Duration? _seekPreviewPosition;

  @override
  void initState() {
    super.initState();
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        final next = LoadingTipsConstant.nextTip();
        if (next.isNotEmpty) _loadingTip = next;
      });
    });
    _initializeFuture = _initializeVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    if (_isTablet != isTablet) {
      _isTablet = isTablet;
      if (!_leaving) {
        unawaited(SystemChrome.setPreferredOrientations(_activeOrientations));
      }
    }
  }

  Future<void> _initializeVideo() async {
    final previousController = _controller;
    if (previousController != null) {
      _releaseAudio();
      _controller = null;
      unawaited(previousController.dispose());
    }
    final cached = await SongMediaCache.instance.existingPv(widget.songId);
    if (!mounted || _leaving) return;
    final File file;
    if (cached != null) {
      setState(() {
        _usingLocalFile = true;
        _downloading = false;
        _downloadProgress = 1.0;
        _downloadSpeed = 0;
        _downloadStage = appL10n.flowReadingLocalVideo;
      });
      file = cached;
    } else {
      setState(() {
        _usingLocalFile = false;
        _downloading = true;
        _downloadProgress = null;
        _downloadSpeed = 0;
        _downloadStage = appL10n.videoExportPvDownloading;
      });
      file = await SongMediaCache.instance.ensurePv(
        widget.songId,
        url: ApiUrls.wmcPvUrl(widget.songId),
        headers: _videoHeaders,
        onProgress: (progress, speed, status) {
          if (!mounted || _leaving) return;
          setState(() {
            _downloadProgress = progress;
            _downloadSpeed = speed;
            _downloadStage = status;
          });
        },
      );
      if (!mounted || _leaving) return;
      setState(() {
        _usingLocalFile = true;
        _downloading = false;
        _downloadProgress = 1.0;
        _downloadSpeed = 0;
        _downloadStage = appL10n.flowReadingLocalVideo;
      });
    }
    if (!mounted || _leaving) return;
    final controller = VideoPlayerController.file(file);
    _controller = controller;
    await controller.initialize();
    if (!mounted || _leaving) return;
    await controller.setLooping(false);
    if (!mounted || _leaving) return;
    final portable = PortablePlayerController();
    if (portable.isPlaying) await portable.togglePlayPause();
    if (!mounted || _leaving) return;
    await controller.play();
    if (mounted && !_leaving && controller.isAudioTrackSupportAvailable()) {
      unawaited(_loadFallbackAudio());
    }
  }

  void _retryInitialize() {
    if (!mounted || _leaving) return;
    setState(() {
      _audioUnavailable = false;
      _downloadProgress = null;
      _downloadSpeed = 0;
      _downloadStage = '';
      _downloading = false;
      _usingLocalFile = false;
      _initializeFuture = _initializeVideo();
    });
  }

  Future<void> _loadFallbackAudio() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if ((await controller.getAudioTracks()).isNotEmpty || !mounted) return;
      try {
        _preferences = await SharedPreferences.getInstance();
        _audioDelayMs = (_preferences?.getInt(_delayKey) ?? 0)
            .clamp(-_maxDelayMs, _maxDelayMs);
      } catch (error) {
        debugPrint('[SongPV] 读取音频延迟失败: $error');
      }
      if (!mounted) return;
      final file = await SongMediaCache.instance.existingAudio(widget.songId);
      if (!mounted) return;
      final player = AudioPlayer();
      _audio = player;
      // 视频播放器持有 Android 音频焦点，独立音源不能抢占它。
      await player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ));
      if (!mounted) return;
      await player.setReleaseMode(ReleaseMode.stop);
      if (!mounted) return;
      if (file != null) {
        try {
          await player.setSource(DeviceFileSource(file.path));
        } catch (_) {
          if (!mounted) return;
          await _setRemoteAudioSource(player);
        }
      } else {
        await _setRemoteAudioSource(player);
      }
      if (!mounted) return;
      _audioDuration = await player.getDuration();
      if (!mounted || !identical(_controller, controller)) return;
      setState(() => _audioReady = true);
      controller.addListener(_onVideoStateChanged);
      _audioSyncTimer = Timer.periodic(
          const Duration(seconds: 1), (_) => unawaited(_syncAudio()));
      _onVideoStateChanged();
    } catch (error) {
      if (mounted) _handleAudioError(error);
    }
  }

  Future<void> _setRemoteAudioSource(AudioPlayer player) async {
    try {
      await player.setSource(UrlSource(ApiUrls.wmcAudioUrl(widget.songId)));
    } catch (_) {
      final id = SongMediaCache.audioIdFor(widget.songId);
      if (!mounted || id == 0) rethrow;
      await player.setSource(
          UrlSource('https://assets2.lxns.net/maimai/music/$id.mp3'));
    }
  }

  bool get _videoIsPlaying {
    final controller = _controller;
    if (controller == null) return false;
    final video = controller.value;
    return video.isPlaying &&
        !video.isBuffering &&
        !video.isCompleted &&
        !video.hasError &&
        !_seekInProgress;
  }

  void _onVideoStateChanged() {
    final controller = _controller;
    if (!_audioReady || controller == null) return;
    final shouldPlay = _videoIsPlaying &&
        controller.value.position.inMilliseconds >= _audioDelayMs;
    if (shouldPlay == _audioShouldPlay) return;
    _audioShouldPlay = shouldPlay;
    unawaited(_syncAudio());
  }

  // 以视频为时钟。暂停、缓冲和跳转期间停止音频，播放中定期校正漂移。
  Future<void> _syncAudio() async {
    final player = _audio;
    final controller = _controller;
    if (player == null || controller == null) return;
    _audioSyncPending = true;
    if (_syncingAudio) return;
    _syncingAudio = true;
    try {
      while (_audioSyncPending && identical(_audio, player)) {
        _audioSyncPending = false;
        final playing = player.state == PlayerState.playing;
        final duration = _audioDuration;
        if (!_videoIsPlaying) {
          if (playing) await player.pause();
          continue;
        }
        final audioPosition =
            playing ? await player.getCurrentPosition() : null;
        if (!identical(_audio, player) || !_videoIsPlaying) continue;
        final videoPosition =
            await controller.position ?? controller.value.position;
        if (!identical(_audio, player) || !_videoIsPlaying) continue;
        final position = videoPosition - Duration(milliseconds: _audioDelayMs);
        if (position.isNegative || (duration != null && position >= duration)) {
          if (playing) await player.pause();
          continue;
        }
        if (_forceAudioSeek ||
            audioPosition == null ||
            (position - audioPosition).abs() >
                const Duration(milliseconds: 250)) {
          _forceAudioSeek = false;
          await player.seek(position);
        }
        if (identical(_audio, player) && _videoIsPlaying && !playing) {
          await player.resume();
        }
      }
    } catch (error) {
      if (identical(_audio, player) && mounted) _handleAudioError(error);
    } finally {
      _syncingAudio = false;
    }
  }

  void _handleAudioError(Object error) {
    debugPrint('[SongPV] 音源播放失败: $error');
    _releaseAudio();
    setState(() => _audioUnavailable = true);
  }

  void _releaseAudio() {
    _audioReady = false;
    _audioSyncTimer?.cancel();
    _controller?.removeListener(_onVideoStateChanged);
    final player = _audio;
    _audio = null;
    unawaited(player?.dispose());
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _hideControlsTimer?.cancel();

    final controller = _controller;
    if (controller != null) {
      _releaseAudio();
      _controller = null;
      unawaited(controller.dispose());
    }
    if (!_leaving) {
      unawaited(SystemChrome.setPreferredOrientations(_defaultOrientations));
      unawaited(NavigationPreferences.instance.setPvFullscreen(false));
    }
    super.dispose();
  }

  Future<void> _setFullscreen(bool enabled) async {
    if (_leaving || _changingFullscreen) return;
    _changingFullscreen = true;
    _hideControlsTimer?.cancel();
    setState(() {
      _fullscreen = enabled;
      _playbackControlsVisible = true;
    });
    try {
      await Future.wait([
        SystemChrome.setPreferredOrientations(_activeOrientations),
        NavigationPreferences.instance.setPvFullscreen(enabled),
      ]);
    } finally {
      if (mounted && !_leaving) {
        setState(() => _changingFullscreen = false);
        if (enabled) _scheduleHideControls();
      }
    }
  }

  Future<void> _handleBack() async {
    if (_changingFullscreen) return;
    if (_fullscreen) {
      await _setFullscreen(false);
      return;
    }
    if (_leaving) return;
    _leaving = true;
    try {
      await Future.wait([
        SystemChrome.setPreferredOrientations(_defaultOrientations),
        NavigationPreferences.instance.setPvFullscreen(false),
      ]);
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_fullscreen) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _playbackControlsVisible = false);
      }
    });
  }

  Future<void> _adjustAudioDelay() async {
    _hideControlsTimer?.cancel();
    final labels = context.l10n;
    var delay = _audioDelayMs;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, updateDialog) {
            void change(int value) {
              if (value == delay) return;
              updateDialog(() => delay = value);
              _audioDelayMs = value;
              _forceAudioSeek = true;
              unawaited(_syncAudio());
            }

            return AppAlertDialog(
              title: Text(labels.pvAudioDelay),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(labels.pvAudioDelayHint),
                  Row(
                    children: [
                      PressScale(
                        child: IconButton(
                          icon: const Icon(Icons.remove),
                          tooltip:
                              labels.flowDecreaseP0ByOne(labels.pvAudioDelay),
                          onPressed: delay > -_maxDelayMs
                              ? () => change(delay - 1)
                              : null,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _signedDelay(delay),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      PressScale(
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          tooltip:
                              labels.flowIncreaseP0ByOne(labels.pvAudioDelay),
                          onPressed: delay < _maxDelayMs
                              ? () => change(delay + 1)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: (delay / _delaySliderStepMs).roundToDouble() *
                        _delaySliderStepMs,
                    min: -_maxDelayMs.toDouble(),
                    max: _maxDelayMs.toDouble(),
                    divisions: 2 * _maxDelayMs ~/ _delaySliderStepMs,
                    label: _signedDelay(delay),
                    semanticFormatterCallback: (value) =>
                        _signedDelay(value.round()),
                    onChanged: (value) => change(value.round()),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => change(0), child: Text(labels.flowReset)),
                FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(labels.featureOK)),
              ],
            );
          },
        ),
      );
      await _preferences?.setInt(_delayKey, delay);
    } catch (error) {
      debugPrint('[SongPV] 保存音频延迟失败: $error');
    } finally {
      if (mounted && !_leaving) {
        setState(() {});
        _scheduleHideControls();
      }
    }
  }

  String _signedDelay(int value) => '${value > 0 ? '+' : ''}$value ms';

  String? get _speedLabel {
    if (_downloadSpeed <= 0) return null;
    return _downloadSpeed >= 1024 * 1024
        ? '${(_downloadSpeed / (1024 * 1024)).toStringAsFixed(1)} MB/s'
        : '${(_downloadSpeed / 1024).toStringAsFixed(0)} KB/s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_fullscreen && !_changingFullscreen && !_leaving,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_handleBack());
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: _fullscreen
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(AppHeader.toolbarHeight),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        surface: Colors.black,
                        onSurface: Colors.white,
                      ),
                    ),
                    child: AppHeader(
                      title: widget.songTitle,
                      onBack: _handleBack,
                      buttonBackground: Colors.white24,
                    ),
                  ),
                ),
          body: FutureBuilder<void>(
            future: _initializeFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) return _errorView(context);
              final controller = _controller;
              if (snapshot.connectionState != ConnectionState.done ||
                  controller == null ||
                  !controller.value.isInitialized) {
                return _loadingView();
              }
              return _playerView(controller);
            },
          ),
        ));
  }

  Widget _playerView(VideoPlayerController controller) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final aspectRatio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
        final shownPosition = _seekPreviewPosition ?? value.position;
        final showControls = !_fullscreen || _playbackControlsVisible;
        return Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: VideoPlayer(controller),
                    ),
                  ),
                  // 覆盖全屏区域的点击与横向滑动层，支持点击画面或四周留黑处切换控制器显隐。
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => _startSeeking(value),
                      onHorizontalDragUpdate: (details) =>
                          _updateSeeking(details, value),
                      onHorizontalDragEnd: (_) => _finishSeeking(),
                      onHorizontalDragCancel: _cancelSeeking,
                      onTap: () {
                        if (_fullscreen) {
                          if (_playbackControlsVisible) {
                            _hideControlsTimer?.cancel();
                            setState(() => _playbackControlsVisible = false);
                          } else {
                            setState(() => _playbackControlsVisible = true);
                            if (value.isPlaying) {
                              _scheduleHideControls();
                            }
                          }
                        } else {
                          _togglePlayback(value.isPlaying);
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                  if (value.isBuffering && !_isSeeking) _bufferingOverlay(),
                  if (_isSeeking && _seekPreviewPosition != null)
                    Center(child: _seekPreviewOverlay(shownPosition)),
                  if (_fullscreen) ...[
                    Positioned(
                      left: 0,
                      top: 0,
                      child: IgnorePointer(
                        ignoring: !showControls,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: showControls ? 1.0 : 0.0,
                          child: SafeArea(
                            bottom: false,
                            right: false,
                            child: _controlButton(
                              Icons.arrow_back,
                              context.l10n.pvExitFullscreen,
                              _handleBack,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        ignoring: !showControls,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: showControls ? 1.0 : 0.0,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: SafeArea(
                              top: false,
                              child: _controls(controller, value, shownPosition),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_fullscreen)
              SafeArea(
                  top: false,
                  child: _controls(controller, value, shownPosition)),
          ],
        );
      },
    );
  }

  Widget _controls(
    VideoPlayerController controller,
    VideoPlayerValue value,
    Duration shownPosition,
  ) {
    final duration = value.duration;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.black.withValues(alpha: _fullscreen ? .72 : 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _controlButton(
                value.isPlaying ? Icons.pause : Icons.play_arrow,
                value.isPlaying
                    ? context.l10n.flowPause
                    : context.l10n.flowPlay,
                () => _togglePlayback(value.isPlaying),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    void seek(double x) {
                      if (constraints.maxWidth <= 0) return;
                      unawaited(_seekTo(duration *
                          (x / constraints.maxWidth).clamp(0.0, 1.0)));
                    }

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => seek(details.localPosition.dx),
                      onHorizontalDragEnd: (details) =>
                          seek(details.localPosition.dx),
                      child: VideoProgressIndicator(
                        controller,
                        allowScrubbing: false,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatDuration(shownPosition)} / ${_formatDuration(duration)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (_audioReady)
                _controlButton(
                    Icons.sync_alt,
                    _audioDelayMs == 0
                        ? context.l10n.pvAudioDelay
                        : '${context.l10n.pvAudioDelay} · ${_signedDelay(_audioDelayMs)}',
                    _adjustAudioDelay),
              _controlButton(
                _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                _fullscreen
                    ? context.l10n.pvExitFullscreen
                    : context.l10n.pvFullscreen,
                () => _setFullscreen(!_fullscreen),
              ),
            ],
          ),
          if (value.isBuffering) _bufferStatus(),
          if (_audioUnavailable)
            Text(context.l10n.flowAudioIsTemporarilyUnavailable,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return PressScale(
      child: IconButton(
        tooltip: tooltip,
        color: Colors.white,
        style: IconButton.styleFrom(overlayColor: Colors.transparent),
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _loadingView() {
    final scheme = Theme.of(context).colorScheme;
    final speed = _speedLabel;
    final progressValue = _downloading ? _downloadProgress : null;
    final percentText = _downloading && _downloadProgress != null
        ? '${(_downloadProgress! * 100).round()}%'
        : null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusLarge),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _downloading
                                ? Icons.downloading_rounded
                                : Icons.ondemand_video_rounded,
                            size: 18,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _loadingStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (percentText != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            percentText,
                            style: AppTheme.number(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    SmoothLinearProgressIndicator(
                      value: progressValue,
                      color: scheme.primary,
                      backgroundColor: Colors.white24,
                      minHeight: 5,
                    ),
                    if (_downloading && speed != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        speed,
                        textAlign: TextAlign.right,
                        style: AppTheme.number(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_loadingTip.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  _loadingTip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bufferingOverlay() {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xE6212121),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _loadingStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 96,
                  child: SmoothLinearProgressIndicator(
                    color: scheme.primary,
                    backgroundColor: Colors.white24,
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bufferStatus() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _loadingStatus,
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }

  Widget _seekPreviewOverlay(Duration position) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            _formatDuration(position),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  void _togglePlayback(bool isPlaying) {
    final controller = _controller;
    if (controller == null) return;
    if (isPlaying) {
      _hideControlsTimer?.cancel();
      setState(() => _playbackControlsVisible = true);
      unawaited(controller.pause());
    } else {
      setState(() => _playbackControlsVisible = true);
      unawaited(controller.play());
      _scheduleHideControls();
    }
  }

  void _startSeeking(VideoPlayerValue value) {
    if (value.duration <= Duration.zero) return;
    _seekStartPosition = value.position;
    _seekDragOffset = 0;
    setState(() {
      _isSeeking = true;
      _seekPreviewPosition = _seekStartPosition;
    });
  }

  void _updateSeeking(DragUpdateDetails details, VideoPlayerValue value) {
    if (!_isSeeking || value.duration <= Duration.zero) return;
    _seekDragOffset += details.primaryDelta ?? 0;
    final width = MediaQuery.sizeOf(context).width;
    final deltaMs = value.duration.inMilliseconds *
        _seekDragOffset /
        width.clamp(1.0, 10000.0);
    final targetMs = (_seekStartPosition.inMilliseconds + deltaMs.round())
        .clamp(0, value.duration.inMilliseconds);
    setState(() {
      _seekPreviewPosition = Duration(milliseconds: targetMs);
    });
  }

  Future<void> _finishSeeking() async {
    final target = _seekPreviewPosition;
    if (target == null) return;
    setState(() {
      _isSeeking = false;
      _seekPreviewPosition = null;
    });
    await _seekTo(target);
  }

  Future<void> _seekTo(Duration position) async {
    final controller = _controller;
    if (_seekInProgress || controller == null) return;
    _seekInProgress = true;
    _onVideoStateChanged();
    try {
      await controller.seekTo(position);
    } catch (error) {
      debugPrint('[SongPV] 视频定位失败: $error');
    } finally {
      _seekInProgress = false;
      if (mounted) _onVideoStateChanged();
    }
  }

  void _cancelSeeking() {
    if (!mounted) return;
    setState(() {
      _isSeeking = false;
      _seekPreviewPosition = null;
    });
  }

  Widget _errorView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              context.l10n.flowCouldNotLoadThePVCheckYour,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _handleBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(context.l10n.flowBackToSongDetails),
                ),
                FilledButton.icon(
                  onPressed: _retryInitialize,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.l10n.flowRetry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
