/*
 * 随身听的全屏播放页（大曲绘 + 进度条 + 上一首/播放/下一首）。
 *
 * 入口：随身听列表顶部的「正在播放」条、悬浮球迷你卡片、以及旧播放页被接管后的跳转。
 *
 * ⚠️ 这一页**不持有播放器状态的所有权**：`leave` 时不动播放器，音乐继续放。
 * 这正是需求里「切出此页面也不会中断音乐」的关键 —— 旧 `SongPlayPage` 在
 * `dispose` 里把播放器 stop + dispose 了，所以退出即静音。
 */
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/ExportSuccessDialog.dart';

import '../../entity/Portable/PortableSong.dart';
import '../../service/Portable/PortablePlayerController.dart';
import '../../service/Portable/PortableSongDownloadService.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ExportPathUtil.dart';
import '../../utils/PortablePlayerScope.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/MarqueeText.dart';
import '../../widgets/PortablePlayerBadge.dart';
import '../../widgets/PortablePlaybackModeButton.dart';

class PortableNowPlayingPage extends StatefulWidget {
  const PortableNowPlayingPage({super.key});

  @override
  State<PortableNowPlayingPage> createState() => _PortableNowPlayingPageState();
}

class _PortableNowPlayingPageState extends State<PortableNowPlayingPage> {
  final PortablePlayerController _player = PortablePlayerController();
  final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];

  double? _dragValue;
  double _coverDrag = 0;
  bool _switching = false;
  double _slideDirection = 1;
  bool _downloading = false;
  double? _downloadProgress;
  double? _downloadSpeedBytesPerSecond;

  @override
  void initState() {
    super.initState();
    PortablePlayerScope.isNowPlayingPageOpen.value = true;
    _player.addListener(_safeSetState);
    _subs.add(_player.currentIndexStream.listen((_) => _safeSetState()));
    _subs.add(_player.playingStream.listen((_) => _safeSetState()));
    _subs.add(_player.processingStateStream.listen((_) => _safeSetState()));
    _subs.add(_player.positionStream.listen((_) {
      if (mounted && _dragValue == null) _safeSetState();
    }));
  }

  @override
  void dispose() {
    PortablePlayerScope.isNowPlayingPageOpen.value = false;
    _player.removeListener(_safeSetState);
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void _safeSetState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final inheritedTheme = Theme.of(context);
    // 保留播放器的独立视觉，明暗模式跟随应用主题。
    final scheme = AppColors.musicPlayerScheme(inheritedTheme.brightness);
    final playerTheme = inheritedTheme.copyWith(
      brightness: inheritedTheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: inheritedTheme.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
    );
    final song = _player.currentSong;

    return Theme(
      data: playerTheme,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (inheritedTheme.brightness == Brightness.dark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark)
            .copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: scheme.surface,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: scheme.surface,
          body: SafeArea(
            child: Builder(
              builder: (context) => song == null
                  ? (_player.isLoading ? _preparing(scheme) : _empty(scheme))
                  : _content(context, scheme, song),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note, size: 64, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            '还没有在放的音乐',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _preparing(ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            '正在准备音源…',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadSong(PortableSong song) async {
    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '歌曲', title: '选择歌曲保存位置')) {
      return;
    }
    setState(() {
      _downloading = true;
      _downloadProgress = null;
      _downloadSpeedBytesPerSecond = null;
    });
    String? fallbackPath;
    try {
      final file = await PortableSongDownloadService.instance.download(
        song,
        onProgress: (progress) {
          if (mounted) setState(() => _downloadProgress = progress);
        },
        onSpeed: (speed) {
          if (mounted) setState(() => _downloadSpeedBytesPerSecond = speed);
        },
        onFallback: (path) => fallbackPath = path,
      );
      if (mounted) {
        await showExportSuccessDialog(
          context,
          filePath: file.path,
          fileName: song.title,
          title: '下载成功',
          successPrefix: '已下载',
          fallbackPath: fallbackPath,
        );
      }
    } on AudioDownloadSourceException catch (e) {
      if (mounted) _showDownloadHint(e.message);
    } catch (e) {
      if (mounted) _showDownloadHint('下载失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadProgress = null;
          _downloadSpeedBytesPerSecond = null;
        });
      }
    }
  }

  void _showDownloadHint(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  Widget _content(
    BuildContext context,
    ColorScheme scheme,
    PortableSong song,
  ) {
    final theme = Theme.of(context);
    final duration = _player.duration ?? Duration.zero;
    final totalMs = duration.inMilliseconds;
    final value = _dragValue ??
        (totalMs > 0
            ? (_player.position.inMilliseconds / totalMs).clamp(0.0, 1.0)
            : 0.0);

    return LayoutBuilder(builder: (context, constraints) {
      // 参考图内容宽 484、曲绘宽 440；保留这个比例，不再限制成小曲绘。
      final width = math.min(constraints.maxWidth, 560.0);
      final scale = width / 484;
      final coverSize = 440 * scale;
      final progressHeight = math.max(48.0, 60 * scale);
      final playSize = 76 * scale;
      final textScaler = MediaQuery.textScalerOf(context);
      final titleHeight = textScaler.scale(28 * scale) * 1.4;
      final artistHeight = textScaler.scale(22 * scale) * 1.4;
      final fixedHeight =
          coverSize + progressHeight + titleHeight + artistHeight + playSize;
      // 小屏、横屏或大字体时允许滚动，保持曲绘正方形并让控制区可达。
      final height = math.max(constraints.maxHeight, fixedHeight + 80 * scale);
      final gapUnit = (height - fixedHeight) / 197;

      return Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          physics: height > constraints.maxHeight
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: width,
            height: height,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 22 * scale),
              child: Column(
                children: [
                  SizedBox(height: 54 * gapUnit),
                  _coverArtwork(song, coverSize, 22 * scale),
                  SizedBox(height: 57 * gapUnit),
                  SizedBox(
                    height: progressHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                      child: _progressRow(
                        scheme,
                        song,
                        duration,
                        value,
                        scale,
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * gapUnit),
                  SizedBox(
                    height: titleHeight,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                      child: Align(
                        alignment: Alignment.center,
                        child: Tooltip(
                          message: song.title,
                          child: MarqueeText(
                            key: ValueKey(song.portableKey),
                            text: song.title,
                            style: TextStyle(
                              fontSize: 28 * scale,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22 * gapUnit),
                  SizedBox(
                    height: artistHeight,
                    child: Center(
                      child: Text(
                        '${song.artist.isEmpty ? '未知艺术家' : song.artist} · Audio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22 * scale,
                          height: 1.4,
                          letterSpacing: 0,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 22 * gapUnit),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PortablePlaybackModeButton(
                          iconSize: 28 * scale,
                          color: scheme.onSurfaceVariant,
                          sequentialIcon: Icons.repeat_rounded,
                        ),
                        _skipButton(
                          theme,
                          scale: scale,
                          previous: true,
                          enabled: _player.hasPrevious,
                        ),
                        _playButton(theme, size: playSize),
                        _skipButton(
                          theme,
                          scale: scale,
                          previous: false,
                          enabled: _player.hasNext,
                        ),
                        SizedBox(
                          width: 48,
                          child: _downloadControl(scheme, song),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18 * gapUnit),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _progressRow(
    ColorScheme scheme,
    PortableSong song,
    Duration duration,
    double value,
    double scale,
  ) {
    final totalMs = duration.inMilliseconds;
    final timeStyle = TextStyle(
      fontSize: 20 * scale,
      height: 1,
      letterSpacing: 0,
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 44 * scale),
          child: Text(
            _fmt(Duration(milliseconds: (value * totalMs).round())),
            maxLines: 1,
            style: timeStyle,
          ),
        ),
        SizedBox(width: 20 * scale),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              // 粗圆角轨道、滑块两侧留缝、末端圆点均由同一个轨道形状绘制。
              trackShape: const GappedSliderTrackShape(),
              thumbShape: const HandleThumbShape(),
              trackHeight: 21 * scale,
              trackGap: 8 * scale,
              thumbSize: WidgetStatePropertyAll(Size(5 * scale, 60 * scale)),
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.surfaceContainerHighest,
              thumbColor: scheme.primary,
              disabledActiveTrackColor: scheme.primary,
              disabledInactiveTrackColor: scheme.surfaceContainerHighest,
              disabledThumbColor: scheme.primary,
              overlayShape: SliderComponentShape.noOverlay,
              overlayColor: Colors.transparent,
              showValueIndicator: ShowValueIndicator.never,
              padding: EdgeInsets.zero,
            ),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(song.portableKey),
              tween: Tween(begin: value, end: value),
              duration: _dragValue != null
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              builder: (context, animatedValue, _) => Slider(
                value: animatedValue,
                padding: EdgeInsets.zero,
                semanticFormatterCallback: (v) =>
                    _fmt(Duration(milliseconds: (v * totalMs).round())),
                onChanged:
                    totalMs <= 0 ? null : (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) async {
                  try {
                    await _player.seek(
                      Duration(milliseconds: (v * totalMs).round()),
                    );
                  } finally {
                    if (mounted) setState(() => _dragValue = null);
                  }
                },
              ),
            ),
          ),
        ),
        SizedBox(width: 20 * scale),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: 44 * scale),
          child: Text(
            _fmt(duration),
            maxLines: 1,
            textAlign: TextAlign.right,
            style: timeStyle,
          ),
        ),
      ],
    );
  }

  Widget _skipButton(
    ThemeData theme, {
    required double scale,
    required bool previous,
    required bool enabled,
  }) {
    final scheme = theme.colorScheme;
    return IconButton(
      iconSize: 30 * scale,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      tooltip: previous ? '上一首' : '下一首',
      icon: Icon(
        previous ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
        color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
      onPressed: enabled ? () => _changeSong(!previous) : null,
    );
  }

  Future<void> _changeSong(bool next) async {
    if (_switching ||
        _player.isLoading ||
        (next ? !_player.hasNext : !_player.hasPrevious)) {
      return;
    }
    setState(() {
      _switching = true;
      _slideDirection = next ? 1 : -1;
      _coverDrag = 0;
    });
    try {
      await (next ? _player.next() : _player.previous());
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Widget _coverArtwork(PortableSong song, double size, double radius) {
    return Semantics(
      image: true,
      label: '${song.title} 曲绘，可左右滑动切歌',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          if (!_switching) {
            setState(() => _coverDrag =
                (_coverDrag + details.delta.dx).clamp(-size / 3, size / 3));
          }
        },
        onHorizontalDragCancel: () => setState(() => _coverDrag = 0),
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (_coverDrag.abs() > 40 || velocity.abs() > 300) {
            final next = velocity.abs() > 300 ? velocity < 0 : _coverDrag < 0;
            unawaited(_changeSong(next));
          }
          setState(() => _coverDrag = 0);
        },
        child: SizedBox.square(
          dimension: size,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              transform: Matrix4.translationValues(_coverDrag, 0, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_slideDirection * .18, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                ),
                child: PortableCover(
                  key: ValueKey(song.portableKey),
                  song: song,
                  size: size,
                  radius: radius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playButton(ThemeData theme, {required double size}) {
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(size * 22 / 76);
    return Semantics(
      button: true,
      label: _player.isLoading ? '正在加载音源' : (_player.isPlaying ? '暂停' : '播放'),
      child: SizedBox.square(
        dimension: size,
        child: Material(
          color: scheme.primary,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: radius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            onTap: _player.isLoading ? null : () => _player.togglePlayPause(),
            child: Center(
              child: FadeContent(
                child: _player.isLoading || _player.isBuffering
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: size * .34,
                        height: size * .34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Icon(
                        _player.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(_player.isPlaying),
                        size: size * 32 / 76,
                        color: scheme.onPrimary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _downloadControl(ColorScheme scheme, PortableSong song) {
    if (!_downloading) {
      return IconButton(
        tooltip: '下载歌曲',
        icon: Icon(Icons.download_outlined, color: scheme.primary),
        onPressed: () => _downloadSong(song),
      );
    }
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: _downloadProgress,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatDownloadSpeed(_downloadSpeedBytesPerSecond),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  static String _formatDownloadSpeed(double? bytesPerSecond) {
    if (bytesPerSecond == null || bytesPerSecond <= 0) return '计算中';
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
  }

  static String _fmt(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
