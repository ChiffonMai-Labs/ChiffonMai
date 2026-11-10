import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
/*
 * 随身听的全屏播放页：曲绘取色铺满页面，主体是可拖动的环形进度表盘。
 *
 * 入口：随身听列表顶部的「正在播放」条、悬浮球迷你卡片，以及歌曲详情页的「播放音乐」。
 *
 * ⚠️ 这一页**不持有播放器状态的所有权**：`leave` 时不动播放器，音乐继续放。
 * 这正是需求里「切出此页面也不会中断音乐」的关键 —— 旧 `SongPlayPage` 在
 * `dispose` 里把播放器 stop + dispose 了，所以退出即静音。
 *
 * 取色背景是这一页的全屏播放语义，所以不走 `ThemeAwareBackground`，
 * 明暗模式仍跟随 App；还没有当前曲目时退回标准页面壳。
 */
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../widgets/EmptyState.dart';
import '../../widgets/ExportSuccessDialog.dart';

import '../../entity/Portable/PortableSong.dart';
import '../../service/Portable/PortablePlayerController.dart';
import '../../service/Portable/PortableSongDownloadService.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/ExportPathUtil.dart';
import '../../utils/PortablePlayerScope.dart';
import '../../widgets/AppHeader.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/MarqueeText.dart';
import '../../widgets/NextPlayAddDialog.dart';
import '../../widgets/NowPlayingUi.dart';
import '../../widgets/PortablePlaybackModeButton.dart';
import '../SongInfoPage.dart';

class PortableNowPlayingPage extends StatefulWidget {
  /// 歌曲详情页进来时，音源还没就绪就先显示这首歌，避免先闪出别的曲目或空页面。
  final PortableSong? preparingSong;
  final String? preparationError;
  final VoidCallback? onRetryPreparation;

  /// 从某首歌的详情页「试听」进来时，那首歌的水鱼 id。
  /// 正在播放的仍是这首歌时，「查看歌曲详情」直接返回上一级，不再叠一层详情页。
  final String? sourceSongId;

  const PortableNowPlayingPage({
    super.key,
    this.preparingSong,
    this.preparationError,
    this.onRetryPreparation,
    this.sourceSongId,
  });

  @override
  State<PortableNowPlayingPage> createState() => _PortableNowPlayingPageState();
}

class _PortableNowPlayingPageState extends State<PortableNowPlayingPage>
    with SingleTickerProviderStateMixin {
  final PortablePlayerController _player = PortablePlayerController();
  final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];
  final ValueNotifier<Duration> _position =
      ValueNotifier<Duration>(Duration.zero);
  late final Ticker _ticker;

  bool _switching = false;
  double _slideDirection = 1;
  bool _downloading = false;
  double? _downloadProgress;
  double? _downloadSpeedBytesPerSecond;
  Duration? _lastDuration;
  PortableSong? _nextSong;

  /// 当前曲绘取色任务的标识，迟到的旧结果不得覆盖新曲目。
  String? _artKey;
  ImageProvider? _artProvider;
  ColorScheme? _artScheme;

  bool get _isPreparing => widget.preparingSong != null;
  PortableSong? get _song => widget.preparingSong ?? _player.currentSong;

  @override
  void initState() {
    super.initState();
    PortablePlayerScope.isNowPlayingPageOpen.value = true;
    _ticker = createTicker((_) => _publishPosition());
    _player.addListener(_onPlayerChanged);
    _subs.add(_player.currentIndexStream.listen((_) => _onPlayerChanged()));
    _subs.add(_player.playingStream.listen((_) => _onPlayerChanged()));
    _subs.add(_player.processingStateStream.listen((_) => _onPlayerChanged()));
    _subs.add(_player.positionStream.listen((_) {
      _publishPosition();
      // 位置不再驱动整页刷新，时长拿到新值时要单独补一次。
      if (_player.duration != _lastDuration) _onPlayerChanged();
    }));
    _publishPosition();
    _lastDuration = _player.duration;
    _refreshNextSong();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
    unawaited(_syncArt());
  }

  @override
  void didUpdateWidget(covariant PortableNowPlayingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
    unawaited(_syncArt());
    _publishPosition();
  }

  @override
  void dispose() {
    PortablePlayerScope.isNowPlayingPageOpen.value = false;
    _player.removeListener(_onPlayerChanged);
    for (final sub in _subs) {
      sub.cancel();
    }
    _ticker.dispose();
    _position.dispose();
    super.dispose();
  }

  void _publishPosition() {
    _position.value = _isPreparing ? Duration.zero : _player.position;
  }

  /// positionStream 约 200ms 一条，播放中改用逐帧读取，表盘才连贯。
  void _syncTicker() {
    final shouldRun = !_isPreparing &&
        _player.isPlaying &&
        !MediaQuery.disableAnimationsOf(context);
    if (shouldRun && !_ticker.isActive) {
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _refreshNextSong() {
    // 切歌途中播放器还没定位，保留上一次的结果，避免这一条闪一下。
    if (_player.isLoading) return;
    _nextSong = _player.nextSong;
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    _lastDuration = _player.duration;
    _refreshNextSong();
    _syncTicker();
    unawaited(_syncArt());
    _publishPosition();
    setState(() {});
  }

  Future<void> _syncArt() async {
    final song = _song;
    if (song == null) return;
    final brightness = Theme.of(context).brightness;
    final key = '${song.portableKey}|${brightness.name}';
    if (key == _artKey) return;
    _artKey = key;
    final provider = await NowPlayingArt.providerFor(song);
    if (!mounted || key != _artKey) return;
    setState(() => _artProvider = provider);
    final scheme = await NowPlayingArt.schemeFor(song, provider, brightness);
    if (!mounted || key != _artKey) return;
    setState(() => _artScheme = scheme);
  }

  ThemeData _themeWithArt(ThemeData base) {
    final art = _artScheme;
    if (art == null) return base;
    // 纯黑模式保留纯黑底，曲绘颜色只进入强调色和背景。
    final isPureBlack = base.colorScheme.surface.toARGB32() == 0xFF000000;
    return base.copyWith(
      colorScheme: isPureBlack ? art.copyWith(surface: Colors.black) : art,
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = _song;
    if (song == null) {
      return BackgroundPageScaffold(
        title: context.l10n.flowPlayMusic,
        child: SafeArea(
          top: false,
          child: _player.isLoading
              ? _preparing(Theme.of(context).colorScheme)
              : _empty(),
        ),
      );
    }

    return AnimatedTheme(
      data: _themeWithArt(Theme.of(context)),
      duration: AppDesignTokens.motion(context, AppDesignTokens.slowMotion),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            children: [
              NowPlayingBackdrop(provider: _artProvider),
              Column(
                children: [
                  AppHeader(
                    title: context.l10n.flowPlayMusic,
                    buttonBackground: _headerButtonColor(context),
                    actions: [
                      if (song != null && song.divingFishId.isNotEmpty)
                        IconButton(
                          tooltip: context.l10n.flowViewSongDetails,
                          icon: const Icon(Icons.library_music_outlined),
                          onPressed: () => _openSongDetail(song),
                        ),
                      _downloadControl(context, song),
                    ],
                  ),
                  if (widget.preparationError case final error?)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(error,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                )),
                          ),
                          TextButton(
                            onPressed: widget.onRetryPreparation,
                            child: Text(context.l10n.flowRetry),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      child: _content(context, song),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return EmptyState(
      icon: Icons.music_note,
      message: context.l10n.flowNothingPlayingYet,
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
            context.l10n.flowPreparingAudio,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// 跳到当前曲目的歌曲详情。从这首歌的详情页「试听」进来时直接返回上一级。
  void _openSongDetail(PortableSong song) {
    if (_isSameSong(widget.sourceSongId, song.divingFishId)) {
      Navigator.of(context).maybePop();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => SongInfoPage(songId: song.divingFishId)),
    );
  }

  /// ST 与 DX 谱面在水鱼上是两个 id（DX = 10000 + 基础 id），但属于同一首歌，
  /// 详情页里也能直接切换，所以按基础 id 比较。
  static bool _isSameSong(String? a, String b) {
    if (a == null || a.isEmpty) return false;
    final x = int.tryParse(a), y = int.tryParse(b);
    if (x == null || y == null) return a == b;
    int base(int id) => id >= 10000 && id < 100000 ? id % 10000 : id;
    return base(x) == base(y);
  }

  Future<void> _addToNextPlay(PortableSong song) async {
    final added = await showNextPlayAddDialog(
      context,
      songId: song.divingFishId,
      title: song.title,
      artist: song.artist,
      type: song.hasDx ? 'DX' : 'SD',
      coverId: song.audioId,
      difficulties: NextPlayDifficultyOption.standard(
        count: song.difficultyConstants.isEmpty
            ? 5
            : song.difficultyConstants.length,
        constants: song.difficultyConstants
            .map((value) => value.toStringAsFixed(1))
            .toList(),
      ),
    );
    if (mounted && added)
      AppToast.show(context.l10n.flowAddedToPlayNext,
          tone: AppToastTone.success);
  }

  Future<void> _downloadSong(PortableSong song) async {
    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '歌曲', title: context.l10n.flowChooseWhereToSaveTheSong)) {
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
          title: context.l10n.flowDownloaded,
          successPrefix: context.l10n.flowDownloaded2,
          fallbackPath: fallbackPath,
        );
      }
    } on AudioDownloadSourceException catch (e) {
      if (mounted) _showDownloadHint(e.message);
    } catch (e) {
      if (mounted)
        _showDownloadHint(context.l10n.flowDownloadFailedP02((e).toString()));
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
    AppToast.show(message, duration: const Duration(seconds: 4));
  }

  Widget _content(BuildContext context, PortableSong song) {
    final scheme = Theme.of(context).colorScheme;
    final queue = _player.queue;
    final showQueue = !_isPreparing && queue.length > 1;
    final busy = _isPreparing
        ? widget.preparationError == null
        : _player.isLoading || _player.isBuffering;

    return LayoutBuilder(builder: (context, constraints) {
      final textScaler = MediaQuery.textScalerOf(context);
      final width = math.min(constraints.maxWidth, 560.0);
      final titleHeight = textScaler.scale(26) * 1.35;
      final artistHeight = textScaler.scale(14) * 1.4;
      const controlsHeight = 76.0;
      final nextHeight = showQueue ? NowPlayingNextBar.height : 0.0;
      const gapsHeight = 8 + 16 + 4 + 18 + 18 + 12;
      final fixedHeight =
          titleHeight + artistHeight + controlsHeight + nextHeight + gapsHeight;
      final contentWidth = width - AppDesignTokens.gutter * 2;
      // 大字体或矮屏幕放不下时保住表盘的最小尺寸，改为整页滚动。
      final dialSize = math.max(
        220.0,
        math.min(contentWidth, constraints.maxHeight - fixedHeight),
      );
      final totalHeight =
          math.max(constraints.maxHeight, dialSize + fixedHeight);

      return Center(
        child: SingleChildScrollView(
          physics: totalHeight > constraints.maxHeight
              ? const ClampingScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: width,
            height: totalHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignTokens.gutter,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    width: contentWidth,
                    height: dialSize,
                    child: NowPlayingDial(
                      song: song,
                      position: _position,
                      duration: _isPreparing
                          ? Duration.zero
                          : _player.duration ?? Duration.zero,
                      isPlaying: !_isPreparing && _player.isPlaying,
                      isBusy: busy,
                      slideDirection: _slideDirection,
                      canSwipePrevious: !_isPreparing && _player.hasPrevious,
                      canSwipeNext: !_isPreparing && _player.hasNext,
                      queueLabel: showQueue ? _queueLabel(song) : null,
                      onSeek: (position) async {
                        if (!_isPreparing) await _player.seek(position);
                      },
                      onChangeSong: (next) => unawaited(_changeSong(next)),
                      onTogglePlay: _togglePlay,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: titleHeight,
                    child: Align(
                      alignment: Alignment.center,
                      child: Tooltip(
                        message: song.title,
                        child: MarqueeText(
                          key: ValueKey(song.portableKey),
                          text: song.title,
                          style: TextStyle(
                            fontSize: 26,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: artistHeight,
                    child: Align(
                      alignment: Alignment.center,
                      child: MarqueeText(
                        key: ValueKey('artist-${song.portableKey}'),
                        text: song.artist.isEmpty
                            ? context.l10n.flowUnknownArtist
                            : song.artist,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          letterSpacing: 0,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: controlsHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PortablePlaybackModeButton(
                          iconSize: 26,
                          color: scheme.onSurfaceVariant,
                          sequentialIcon: Icons.repeat_rounded,
                        ),
                        _skipButton(
                          scheme,
                          previous: true,
                          enabled: !_isPreparing && _player.hasPrevious,
                        ),
                        NowPlayingPlayButton(
                          isPlaying: !_isPreparing && _player.isPlaying,
                          isBusy: busy,
                          enabled: !_isPreparing && !_player.isLoading,
                          onPressed: _togglePlay,
                          size: controlsHeight,
                        ),
                        _skipButton(
                          scheme,
                          previous: false,
                          enabled: !_isPreparing && _player.hasNext,
                        ),
                        SizedBox(
                          width: 48,
                          child: IconButton(
                            tooltip: context.l10n.flowAddToPlayNext,
                            icon: Icon(
                              Icons.playlist_add_rounded,
                              size: 28,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () => _addToNextPlay(song),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showQueue) ...[
                    const Spacer(),
                    NowPlayingNextBar(
                      nextSong: _nextSong,
                      caption: _nextCaption(song),
                      onTap: () => unawaited(showNowPlayingQueueSheet(context)),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  String _queueLabel(PortableSong song) {
    final queue = _player.queue;
    final index = queue.indexWhere((s) => s.lxnsId == song.lxnsId);
    return '${index + 1}/${queue.length}';
  }

  String _nextCaption(PortableSong song) {
    final next = _nextSong;
    if (next == null) {
      return _player.isLoading
          ? context.l10n.flowSwitchingSongs
          : context.l10n.flowThisIsTheLastSong;
    }
    return next.lxnsId == song.lxnsId
        ? _player.playbackModeLabel
        : context.l10n.flowUpNext;
  }

  void _togglePlay() {
    if (_isPreparing || _player.isLoading) return;
    unawaited(_player.togglePlayPause());
  }

  Widget _skipButton(
    ColorScheme scheme, {
    required bool previous,
    required bool enabled,
  }) {
    return IconButton(
      iconSize: 34,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
      tooltip: previous ? context.l10n.flowPrevious2 : context.l10n.flowNext2,
      icon: Icon(
        previous ? Icons.skip_previous_rounded : Icons.skip_next_rounded,
        color: enabled
            ? scheme.onSurface
            : scheme.onSurface.withValues(alpha: 0.3),
      ),
      onPressed: enabled ? () => _changeSong(!previous) : null,
    );
  }

  Future<void> _changeSong(bool next) async {
    if (_switching ||
        _isPreparing ||
        _player.isLoading ||
        (next ? !_player.hasNext : !_player.hasPrevious)) {
      return;
    }
    setState(() {
      _switching = true;
      _slideDirection = next ? 1 : -1;
    });
    try {
      await (next ? _player.next() : _player.previous());
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  /// 放在顶部栏：下载时换成同尺寸的圆形进度，保持和其它顶部按钮对齐。
  /// 背景是曲绘取色，顶部按钮用文字色的淡色叠上去，明暗都能融进背景。
  Color _headerButtonColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1);

  Widget _downloadControl(BuildContext context, PortableSong song) {
    if (!_downloading) {
      return IconButton(
        tooltip: context.l10n.flowDownloadSong,
        icon: const Icon(Icons.download_outlined),
        onPressed: () => _downloadSong(song),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _headerButtonColor(context),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: _downloadProgress,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 1),
          SizedBox(
            width: 34,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _formatDownloadSpeed(_downloadSpeedBytesPerSecond),
                maxLines: 1,
                style: TextStyle(
                  fontSize: 8,
                  height: 1.1,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDownloadSpeed(double? bytesPerSecond) {
    if (bytesPerSecond == null || bytesPerSecond <= 0)
      return appL10n.flowCalculating;
    if (bytesPerSecond >= 1024 * 1024) {
      return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
  }
}
