import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../api/ApiUrls.dart';
import '../constant/LoadingTipsConstant.dart';
import '../service/Portable/PortablePlayerController.dart';
import '../service/PvVideoStream.dart';
import '../service/SongMediaCache.dart';
import '../utils/NavigationPreferences.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppHeader.dart';
import '../widgets/AppUi.dart' show PressScale;
import '../widgets/SmoothLinearProgressIndicator.dart';
import '../utils/AppDesignTokens.dart';

/// 歌曲 PV 播放页。
///
/// 优先复用已有完整缓存，否则流式加载。无音轨的 PV 使用同曲音源。
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

  late final VideoPlayerController _controller;
  late final Future<void> _initializeFuture;
  late final Uri _videoUri;
  bool _controllerCreated = false;
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
  bool _playbackControlsVisible = true;
  Timer? _hideControlsTimer;
  static const _portrait = [DeviceOrientation.portraitUp];
  static const _landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  PvVideoStream? _videoStream;
  Timer? _speedTimer;
  double? _bytesPerSecond;

  Timer? _tipTimer;
  String _loadingTip = LoadingTipsConstant.getRandomLoadingTip();
  bool _usingLocalFile = false;

  String get _loadingStatus => _usingLocalFile
      ? appL10n.flowReadingLocalVideo
      : appL10n.flowBufferingVideo;

  bool _isSeeking = false;
  double _seekDragOffset = 0;
  Duration _seekStartPosition = Duration.zero;
  Duration? _seekPreviewPosition;

  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations(_portrait));
    _videoUri = Uri.parse(
      'https://download.wmc.pub/s/${widget.songId}/pv.mp4',
    );
    _tipTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        final next = LoadingTipsConstant.nextTip();
        if (next.isNotEmpty) _loadingTip = next;
      });
    });
    _initializeFuture = _initializeVideo().catchError((Object error) {
      _speedTimer?.cancel();
      _videoStream?.close();
      throw error;
    });
  }

  Future<void> _initializeVideo() async {
    final file = await SongMediaCache.instance.existingPv(widget.songId);
    if (!mounted) return;
    _usingLocalFile = file != null;
    var uri = _videoUri;
    if (file == null) {
      final stream = PvVideoStream(_videoUri, _videoHeaders);
      _videoStream = stream;
      try {
        uri = await stream.open();
        if (!mounted) return;
        _startSpeedSampling(stream);
      } catch (error) {
        if (!mounted) return;
        stream.close();
        _videoStream = null;
        debugPrint('[SongPV] 无法启动网速计量，直接加载视频: $error');
      }
    }
    // 不再启动整文件下载，远程视频的缓冲和拖动请求交给原生播放器。
    _controller = file != null
        ? VideoPlayerController.file(file)
        : VideoPlayerController.networkUrl(uri,
            httpHeaders: _videoStream == null ? _videoHeaders : const {});
    _controllerCreated = true;
    await _controller.initialize();
    if (!mounted) return;
    await _controller.setLooping(false);
    if (!mounted) return;
    final portable = PortablePlayerController();
    if (portable.isPlaying) await portable.togglePlayPause();
    if (!mounted) return;
    await _controller.play();
    if (mounted && _controller.isAudioTrackSupportAvailable()) {
      unawaited(_loadFallbackAudio());
    }
  }

  void _startSpeedSampling(PvVideoStream stream) {
    final clock = Stopwatch()..start();
    var lastBytes = 0;
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final count = stream.receivedBytes;
      final speed = (count - lastBytes) * 1000000 / clock.elapsedMicroseconds;
      lastBytes = count;
      clock.reset();
      if (!mounted) return;
      _bytesPerSecond = speed;
      if (!_controllerCreated ||
          !_controller.value.isInitialized ||
          _controller.value.isBuffering) {
        setState(() {});
      }
    });
  }

  Future<void> _loadFallbackAudio() async {
    try {
      if ((await _controller.getAudioTracks()).isNotEmpty || !mounted) return;
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
      if (!mounted) return;
      setState(() => _audioReady = true);
      _controller.addListener(_onVideoStateChanged);
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
    final video = _controller.value;
    return video.isPlaying &&
        !video.isBuffering &&
        !video.isCompleted &&
        !video.hasError &&
        !_seekInProgress;
  }

  void _onVideoStateChanged() {
    if (!_audioReady) return;
    final shouldPlay = _videoIsPlaying &&
        _controller.value.position.inMilliseconds >= _audioDelayMs;
    if (shouldPlay == _audioShouldPlay) return;
    _audioShouldPlay = shouldPlay;
    unawaited(_syncAudio());
  }

  // 以视频为时钟。暂停、缓冲和跳转期间停止音频，播放中定期校正漂移。
  Future<void> _syncAudio() async {
    final player = _audio;
    if (player == null) return;
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
            await _controller.position ?? _controller.value.position;
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
    _controller.removeListener(_onVideoStateChanged);
    final player = _audio;
    _audio = null;
    unawaited(player?.dispose());
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _speedTimer?.cancel();
    _hideControlsTimer?.cancel();
    _videoStream?.close();

    if (_controllerCreated) {
      _releaseAudio();
      unawaited(_controller.dispose());
    }
    if (!_leaving) {
      unawaited(SystemChrome.setPreferredOrientations(_portrait));
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
        SystemChrome.setPreferredOrientations(enabled ? _landscape : _portrait),
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
        SystemChrome.setPreferredOrientations(_portrait),
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
      if (mounted && _controller.value.isPlaying) {
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
    final speed = _bytesPerSecond;
    if (speed == null) return null;
    return speed >= 1024 * 1024
        ? '${(speed / (1024 * 1024)).toStringAsFixed(1)} MB/s'
        : '${(speed / 1024).toStringAsFixed(0)} KB/s';
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
              if (snapshot.connectionState != ConnectionState.done ||
                  !_controller.value.isInitialized) {
                return _loadingView();
              }
              return _playerView();
            },
          ),
        ));
  }

  Widget _playerView() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final aspectRatio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
        final shownPosition = _seekPreviewPosition ?? value.position;
        final showControls = !_fullscreen ||
            _playbackControlsVisible ||
            !value.isPlaying ||
            value.isBuffering;
        return Column(
          children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        if (value.isBuffering && !_isSeeking)
                          _bufferingOverlay(),
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
                                setState(() => _playbackControlsVisible = true);
                                _scheduleHideControls();
                              } else {
                                _togglePlayback(value.isPlaying);
                              }
                            },
                            child: const SizedBox.expand(),
                          ),
                        ),
                        if (_isSeeking && _seekPreviewPosition != null)
                          _seekPreviewOverlay(shownPosition),
                      ],
                    ),
                  ),
                ),
                if (_fullscreen && showControls) ...[
                  Positioned.fill(
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: _controlButton(Icons.arrow_back,
                            context.l10n.pvExitFullscreen, _handleBack),
                      ),
                    ),
                  ),
                  Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                          top: false, child: _controls(value, shownPosition))),
                ],
              ]),
            ),
            if (!_fullscreen)
              SafeArea(top: false, child: _controls(value, shownPosition)),
          ],
        );
      },
    );
  }

  Widget _controls(VideoPlayerValue value, Duration shownPosition) {
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
                        _controller,
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
          if (value.isBuffering) _bufferStatus(value),
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
    return Center(child: _bufferingPanel(showTip: true));
  }

  Widget _bufferingOverlay() {
    return IgnorePointer(
      child: Center(child: _bufferingPanel()),
    );
  }

  Widget _bufferingPanel({bool showTip = false}) {
    final speed = _speedLabel;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          width: showTip ? 260 : 200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xE6212121),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (speed != null) ...[
                const SizedBox(height: 4),
                _speedText(speed),
              ],
              const SizedBox(height: 10),
              const SizedBox(
                width: 88,
                child: SmoothLinearProgressIndicator(
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                  minHeight: 3,
                ),
              ),
              if (showTip && _loadingTip.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _loadingTip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _speedText(String speed) => Text(
        speed,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );

  Widget _bufferStatus(VideoPlayerValue value) {
    var bufferedAhead = Duration.zero;
    for (final range in value.buffered) {
      if (range.start <= value.position && range.end > value.position) {
        bufferedAhead = range.end - value.position;
        break;
      }
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _usingLocalFile
            ? _loadingStatus
            : context.l10n.flowP0P1SBufferedAhead((_loadingStatus).toString(),
                (bufferedAhead.inSeconds).toString()),
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
    if (isPlaying) {
      unawaited(_controller.pause());
    } else {
      unawaited(_controller.play());
    }
    _scheduleHideControls();
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
    if (_seekInProgress) return;
    _seekInProgress = true;
    _onVideoStateChanged();
    try {
      await _controller.seekTo(position);
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
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(context.l10n.flowBackToSongDetails),
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
