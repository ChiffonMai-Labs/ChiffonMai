import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../constant/LoadingTipsConstant.dart';
import '../service/SongMediaCache.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';

/// 歌曲 PV 播放页。
///
/// 优先复用已有完整缓存，否则由播放器按播放位置流式加载。
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

  Timer? _tipTimer;
  String _loadingTip = LoadingTipsConstant.getRandomLoadingTip();
  bool _usingLocalFile = false;

  String get _loadingStatus => _usingLocalFile ? '正在读取本地视频…' : '正在缓冲视频…';

  bool _isSeeking = false;
  double _seekDragOffset = 0;
  Duration _seekStartPosition = Duration.zero;
  Duration? _seekPreviewPosition;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
    _initializeFuture = _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final file = await SongMediaCache.instance.existingPv(widget.songId);
    if (!mounted) return;
    _usingLocalFile = file != null;
    // 不再启动整文件下载，远程视频的缓冲和拖动请求交给原生播放器。
    _controller = file != null
        ? VideoPlayerController.file(file)
        : VideoPlayerController.networkUrl(_videoUri,
            httpHeaders: _videoHeaders);
    _controllerCreated = true;
    await _controller.initialize();
    if (!mounted) return;
    await _controller.setLooping(false);
    if (!mounted) return;
    // 只播放 PV 画面，保持静音。
    await _controller.setVolume(0);
    if (!mounted) return;
    await _controller.play();
  }

  @override
  void dispose() {
    _tipTimer?.cancel();

    if (_controllerCreated) _controller.dispose();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.songTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
    );
  }

  Widget _playerView() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final aspectRatio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
        final shownPosition = _seekPreviewPosition ?? value.position;
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        VideoPlayer(_controller),
                        if (value.isBuffering) _bufferingOverlay(),
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onHorizontalDragStart: (_) => _startSeeking(value),
                            onHorizontalDragUpdate: (details) =>
                                _updateSeeking(details, value),
                            onHorizontalDragEnd: (_) => _finishSeeking(),
                            onHorizontalDragCancel: _cancelSeeking,
                            onTap: () {
                              _togglePlayback(value.isPlaying);
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
              ),
              _controls(value, shownPosition),
            ],
          ),
        );
      },
    );
  }

  Widget _controls(VideoPlayerValue value, Duration shownPosition) {
    final duration = value.duration;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: value.isPlaying ? '暂停' : '播放',
                color: Colors.white,
                icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  _togglePlayback(value.isPlaying);
                },
              ),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
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
            ],
          ),
          if (value.isBuffering) _bufferStatus(value),
        ],
      ),
    );
  }

  Widget _loadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SmoothLinearProgressIndicator(color: Colors.white),
            const SizedBox(height: 12),
            Text(_loadingStatus, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            Text(
              _loadingTip,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bufferingOverlay() {
    return IgnorePointer(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .34),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SmoothLinearProgressIndicator(color: Colors.white),
                const SizedBox(height: 12),
                Text(_loadingStatus,
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 12),
                Text(
                  _loadingTip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
            : '$_loadingStatus 已向前缓冲 ${bufferedAhead.inSeconds} 秒',
        style: const TextStyle(color: Colors.white60, fontSize: 11),
      ),
    );
  }

  Widget _seekPreviewOverlay(Duration position) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(8),
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
    await _controller.seekTo(target);
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
            const Text(
              'PV 加载失败，请检查网络后重试',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回歌曲详情'),
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
