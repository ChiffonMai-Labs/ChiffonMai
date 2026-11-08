import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
// 随身听的两个共享小部件：
//   * [PortableCover] —— 随身听专用的曲绘（本地 assets 优先，网络多级兜底）
//   * [PortablePlayerBall] —— 全 App 悬浮球 + 底部迷你播放卡片
//
// 为什么不复用 `CoverUtil.buildCoverWidget`：那个组件的兜底链是围绕**水鱼 id**
// 设计的（`getNetworkCoverUrl` 对 5/6 位 id 的补零规则与本项目实测的水鱼 covers
// 命名「规范水鱼 id 左补零 5 位」不一致，5/6 位曲目会拼出 404 的 URL）。
// 随身听手里同时有落雪 id 和规范水鱼 id，直接用**已验证过**的两条：
//   本地 `assets/cover/{落雪id}.webp` → 网络 `covers/{规范水鱼id 补零5位}.png`
//   → dxrating（`DxRatingCoverImage`，自带磁盘缓存与默认曲绘兜底）。
//
// 注意：文件开头的注释用 `//` 而不是 `/** */` —— 后者会被 analyzer 当成
// 「游离的库文档注释」（dangling_library_doc_comments）而报警告。
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../entity/Portable/PortableSong.dart';
import '../service/Portable/PortablePlayerController.dart';
import '../utils/PortablePlayerScope.dart';
import 'DxRatingCoverImage.dart';
import 'PortablePlaybackModeButton.dart';
import '../page/Portable/PortableNowPlayingPage.dart';
import '../widgets/AppDialogs.dart';
import 'AppUi.dart';
import 'MarqueeText.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';

// ===========================================================================
// 曲绘
// ===========================================================================

class PortableCover extends StatelessWidget {
  final PortableSong song;
  final double size;
  final double radius;

  const PortableCover({
    super.key,
    required this.song,
    required this.size,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size,
        height: size,
        // 曲绘本身可能是透明 PNG，垫个白底避免深色主题下发黑
        color: Colors.white,
        child: Image.asset(
          song.coverAssetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.network(
              song.coverNetworkUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return DxRatingCoverImage(songId: song.divingFishId);
              },
            );
          },
        ),
      ),
    );
  }
}

// ===========================================================================
// 悬浮球
// ===========================================================================

/// 全 App 悬浮球：有当前曲目时显示，可拖动，点一下弹出底部迷你卡片。
///
/// 位置（相对左上角的偏移）存在 `SharedPreferences` 里，重启后还在原处。
/// 随身听页面自己打开时由 [AppShell] 传 `null` 之外的回调控制隐藏 —— 那两个入口
/// （悬浮球 / 页面内列表）指向同一份播放状态，没必要同时出现。
///
/// ⚠️ [navigatorKey] 必须传：球挂在 `main.dart` 的 `MaterialApp.builder` 上，
/// 而 builder 拿到的 context 处在 **Navigator 之上**（Navigator 是 builder 的
/// child，不是祖先），`Navigator.of(context)` 一路往上找只会抛
/// 「does not include a Navigator」—— 表现就是**点球没反应**（release 下是被
/// 手势回调吞掉的 null check 异常，连日志都容易漏）。迷你卡片与「播放列表」
/// 都得用根 Navigator 的 overlay context。
class PortablePlayerBall extends StatefulWidget {
  /// 打开随身听曲库页（迷你卡片里的「播放列表」按钮用）。
  final Future<void> Function()? onOpenLibrary;

  /// 根 Navigator 的 key（即 `MaterialApp.navigatorKey` 那个）。
  final GlobalKey<NavigatorState>? navigatorKey;

  const PortablePlayerBall({
    super.key,
    this.onOpenLibrary,
    this.navigatorKey,
  });

  /// 球的直径。
  static const double ballSize = 48;

  /// 距离屏幕右/下边缘的最小留白。
  static const double edgeMargin = 12;

  @override
  State<PortablePlayerBall> createState() => _PortablePlayerBallState();
}

class _PortablePlayerBallState extends State<PortablePlayerBall>
    with SingleTickerProviderStateMixin {
  final PortablePlayerController _player = PortablePlayerController();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// null = 还没量到尺寸 / 还没读到位。用 null 表示「先不画」，避免首帧闪一下。
  Offset? _offset;
  bool _dragging = false;

  /// 迷你卡片是否开着。卡片弹在**根 Navigator** 里、而球画在 Navigator 之上，
  /// 不把球收起来的话它会浮在卡片的遮罩之上，再点一下还能叠出第二张卡片。
  bool _miniCardOpen = false;

  /// 进度环靠它推进。**必须**订阅 positionStream：控制器只在切歌/播放暂停时
  /// notifyListeners，光靠监听器的话进度环会一直停在切入时的位置不动。
  /// just_audio 的 positionStream 默认约 200ms 一跳，5fps 重建一个 48px 的小部件
  /// 开销可以忽略。
  StreamSubscription<Duration>? _positionSub;

  @override
  void initState() {
    super.initState();
    _player.addListener(_onPlayerChanged);
    // 随身听曲库页开/关时要重新决定显不显示（不能用 ValueListenableBuilder 包
    // build 的返回值：外层是 Positioned.fill，中间夹一层非 Positioned 的 widget
    // 会报 "Incorrect use of ParentDataWidget"）
    PortablePlayerScope.isLibraryPageOpen.addListener(_onPlayerChanged);
    PortablePlayerScope.isNowPlayingPageOpen.addListener(_onPlayerChanged);
    // 同理：SongInfoPage 的「播放音乐」流程压住悬浮球时也要刷一下。
    PortablePlayerScope.isSongInfoPlayback.addListener(_onPlayerChanged);
    // 用户从迷你卡片中隐藏悬浮球后，继续播放仍要保留后台状态。
    PortablePlayerScope.isBallHidden.addListener(_onPlayerChanged);
    _positionSub = _player.positionStream.listen((_) {
      if (mounted && _player.isPlaying) setState(() {});
    });
    _restoreOffset();
    _syncPulse();
  }

  @override
  void dispose() {
    PortablePlayerScope.isBallDragging.value = false;
    PortablePlayerScope.isLibraryPageOpen.removeListener(_onPlayerChanged);
    PortablePlayerScope.isNowPlayingPageOpen.removeListener(_onPlayerChanged);
    PortablePlayerScope.isSongInfoPlayback.removeListener(_onPlayerChanged);
    PortablePlayerScope.isBallHidden.removeListener(_onPlayerChanged);
    _positionSub?.cancel();
    _player.removeListener(_onPlayerChanged);
    _pulse.dispose();
    super.dispose();
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    // 随身听曲库页是在自己的 `initState` 里置位 `isLibraryPageOpen` 的
    // （push 出来的第一帧、正处在 build 阶段），此刻直接 setState 会报
    // 「setState() called during build」。推迟到本帧结束再刷。
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshFromPlayer();
      });
      return;
    }
    _refreshFromPlayer();
  }

  void _refreshFromPlayer() {
    setState(() {});
    _syncPulse();
  }

  void _syncPulse() {
    if (_player.isPlaying && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_player.isPlaying && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  Future<void> _restoreOffset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(CacheKeyConstant.portableBallOffset);
      if (raw == null || !mounted) return;
      final parts = raw.split(',');
      if (parts.length != 2) return;
      final dx = double.tryParse(parts[0]);
      final dy = double.tryParse(parts[1]);
      if (dx == null || dy == null) return;
      setState(() => _offset = Offset(dx, dy));
    } catch (_) {
      // 读不到就用默认位置，不算错误
    }
  }

  Future<void> _saveOffset(Offset offset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        CacheKeyConstant.portableBallOffset,
        '${offset.dx},${offset.dy}',
      );
    } catch (_) {
      // 存不下下次回默认位置，不影响播放
    }
  }

  /// 根 Navigator 的 overlay context（`Navigator.of` / `showModalBottomSheet`
  /// 都能正常工作的那个 context，见 [PortablePlayerBall.navigatorKey] 的注释）。
  BuildContext? get _rootNavigatorContext =>
      widget.navigatorKey?.currentState?.overlay?.context;

  Future<void> _openMiniCard() async {
    final navigatorContext = _rootNavigatorContext;
    // 取不到（key 没传 / Navigator 还没挂好）就先不开，总好过抛异常
    if (navigatorContext == null) return;
    setState(() => _miniCardOpen = true);
    try {
      await showModalBottomSheet<void>(
        context: navigatorContext,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => PortableMiniCard(onOpenLibrary: widget.onOpenLibrary),
      );
    } finally {
      if (mounted) setState(() => _miniCardOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 卡片开着时先把球收起来（理由见 [_miniCardOpen]）
    if (_miniCardOpen) return const SizedBox.shrink();
    if (PortablePlayerScope.isBallHidden.value) {
      return const SizedBox.shrink();
    }
    // 随身听曲库页自己就是播放入口，球在那上面只会碍事。
    // 这个判断刻意放在**球自己**身上（而不是让外面的 AppShell 包一层
    // ValueListenableBuilder）——球的宿主是 `main.dart` 的 MaterialApp.builder，
    // 它需要自己决定显不显示，宿主越薄越不容易忘。
    if (PortablePlayerScope.isLibraryPageOpen.value ||
        PortablePlayerScope.isNowPlayingPageOpen.value) {
      return const SizedBox.shrink();
    }
    // SongInfoPage 的「播放音乐」流程压住球：用户没主动进随身听，
    // 球突然冒出来会很突兀；不压的话他会以为随身听被「强制打开」了。
    if (PortablePlayerScope.isSongInfoPlayback.value) {
      return const SizedBox.shrink();
    }
    final song = _player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const size = PortablePlayerBall.ballSize;
        const margin = PortablePlayerBall.edgeMargin;
        final maxX = (constraints.maxWidth - size - margin).clamp(0.0, 1e6);
        final maxY = (constraints.maxHeight - size - margin).clamp(0.0, 1e6);
        // 默认位置：右侧偏下（拇指好够到），不挡底部导航栏
        final effective = _offset ??
            Offset(maxX, (constraints.maxHeight * 0.62).clamp(0.0, maxY));
        final clamped = Offset(
          effective.dx.clamp(0.0, maxX),
          effective.dy.clamp(0.0, maxY),
        );

        return Stack(
          children: [
            Positioned(
              left: clamped.dx,
              top: clamped.dy,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onTap: _openMiniCard,
                onPanStart: (_) {
                  PortablePlayerScope.isBallDragging.value = true;
                  setState(() {
                    _offset = clamped;
                    _dragging = true;
                  });
                },
                onPanUpdate: (details) {
                  final current = _offset ?? clamped;
                  final next = Offset(
                    (current.dx + details.delta.dx).clamp(0.0, maxX),
                    (current.dy + details.delta.dy).clamp(0.0, maxY),
                  );
                  setState(() => _offset = next);
                },
                onPanEnd: (_) {
                  PortablePlayerScope.isBallDragging.value = false;
                  setState(() => _dragging = false);
                  final settled = _offset ?? clamped;
                  _saveOffset(settled);
                },
                onPanCancel: () {
                  PortablePlayerScope.isBallDragging.value = false;
                  if (!mounted) return;
                  setState(() => _dragging = false);
                },
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final scale = 1 + _pulse.value * 0.04;
                    return Transform.scale(
                      scale: _dragging ? 1.08 : scale,
                      child: child,
                    );
                  },
                  child: _BallFace(
                    song: song,
                    isPlaying: _player.isPlaying,
                    progress: _progress(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 环形进度（0~1）。拿不到时长时返回 0。
  double _progress() {
    final total = _player.duration?.inMilliseconds ?? 0;
    if (total <= 0) return 0;
    return (_player.position.inMilliseconds / total).clamp(0.0, 1.0);
  }
}

class _BallFace extends StatelessWidget {
  final PortableSong song;
  final bool isPlaying;
  final double progress;

  const _BallFace({
    required this.song,
    required this.isPlaying,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = PortablePlayerBall.ballSize;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 曲绘铺满圆（略小一圈，留出进度环的位置）
          ClipOval(
            child: SizedBox(
              width: size - 6,
              height: size - 6,
              child: PortableCover(song: song, size: size - 6, radius: 0),
            ),
          ),
          // 半透明遮罩 + 播放中时轻微压暗，让中心的图标看得清
          ClipOval(
            child: Container(
              width: size - 6,
              height: size - 6,
              color: Colors.black.withValues(alpha: isPlaying ? 0.22 : 0.34),
            ),
          ),
          Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 22,
            color: Colors.white,
          ),
          // 环形进度：跟随播放位置
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.4,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// 底部迷你卡片
// ===========================================================================

/// 点悬浮球后从底部弹出的迷你播放卡片。
///
/// 结构参考 QQ音乐那种迷你条：曲绘 + 歌名/艺术家 + 进度条 + 上一首/播放/下一首，
/// 点曲绘或标题进全屏播放页。
class PortableMiniCard extends StatefulWidget {
  /// 打开随身听曲库页；为 null 时不显示「播放列表」按钮。
  final Future<void> Function()? onOpenLibrary;

  const PortableMiniCard({super.key, this.onOpenLibrary});

  @override
  State<PortableMiniCard> createState() => _PortableMiniCardState();
}

class _PortableMiniCardState extends State<PortableMiniCard> {
  final PortablePlayerController _player = PortablePlayerController();
  final List<StreamSubscription<dynamic>> _subs =
      <StreamSubscription<dynamic>>[];

  /// 拖动进度条期间的本地值；null = 没在拖，用播放器的真实位置。
  double? _dragValue;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.currentIndexStream.listen((_) => _safeSetState()));
    _subs.add(_player.playingStream.listen((_) => _safeSetState()));
    _subs.add(_player.positionStream.listen((_) {
      // 只有卡片开着时才重建（pop 之后 stream 已取消）
      if (mounted && _dragValue == null) _safeSetState();
    }));
  }

  @override
  void dispose() {
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
    final scheme = Theme.of(context).colorScheme;
    final song = _player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final duration = _player.duration ?? Duration.zero;
    final totalMs = duration.inMilliseconds;
    final positionMs = _player.position.inMilliseconds;
    final value = _dragValue ??
        (totalMs > 0 ? (positionMs / totalMs).clamp(0.0, 1.0) : 0.0);

    final position = Duration(milliseconds: (value * totalMs).round());
    final timeStyle =
        AppTheme.number(fontSize: 11.5, color: scheme.onSurfaceVariant);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: AppSurfaces.card(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // 曲绘和歌名：点这一块进正在播放页
            PressScale(
              scale: 0.98,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openNowPlaying(context),
                child: Row(
                  children: [
                    PortableCover(
                      song: song,
                      size: 64,
                      radius: AppDesignTokens.radiusMedium,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _player.isPlaying
                                    ? Icons.graphic_eq_rounded
                                    : Icons.pause_rounded,
                                size: 13,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _player.isPlaying
                                    ? context.l10n.flowNowPlaying
                                    : context.l10n.flowPaused,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          MarqueeText(
                            text: song.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          MarqueeText(
                            text: song.artist.isEmpty
                                ? context.l10n.flowUnknownArtist
                                : song.artist,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
                inactiveTrackColor: AppSurfaces.inset(context),
              ),
              child: Slider(
                value: value,
                onChanged:
                    totalMs <= 0 ? null : (v) => setState(() => _dragValue = v),
                onChangeEnd: (v) async {
                  final target = Duration(milliseconds: (v * totalMs).round());
                  setState(() => _dragValue = null);
                  await _player.seek(target);
                },
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_fmt(position), style: timeStyle),
                Text(_fmt(duration), style: timeStyle),
              ],
            ),
            const SizedBox(height: 2),
            // 控制条：播放模式 | 上一首 播放 下一首 | 播放列表
            Row(
              children: [
                // 播放模式（顺序/随机/单曲 + 循环次数）：和随身听曲库页共用同一个
                // 控制器单例，所以在哪儿改都是同一份状态。
                PortablePlaybackModeButton(
                  iconButtonKey:
                      const Key('portableMiniCardPlaybackModeButton'),
                  iconSize: 22,
                  density: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.flowPrevious2,
                  iconSize: 30,
                  icon: Icon(Icons.skip_previous_rounded,
                      color: _player.hasPrevious
                          ? scheme.onSurface
                          : scheme.outlineVariant),
                  onPressed:
                      _player.hasPrevious ? () => _player.previous() : null,
                ),
                const SizedBox(width: 4),
                PressScale(
                  child: Semantics(
                    button: true,
                    label: _player.isPlaying
                        ? context.l10n.flowPause
                        : context.l10n.flowPlay,
                    child: Tooltip(
                      message: _player.isPlaying
                          ? context.l10n.flowPause
                          : context.l10n.flowPlay,
                      child: GestureDetector(
                        onTap: () => _player.togglePlayPause(),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedSwitcher(
                            duration: AppDesignTokens.motion(
                                context, const Duration(milliseconds: 180)),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              _player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              key: ValueKey(_player.isPlaying),
                              size: 32,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: context.l10n.flowNext2,
                  iconSize: 30,
                  icon: Icon(Icons.skip_next_rounded,
                      color: _player.hasNext
                          ? scheme.onSurface
                          : scheme.outlineVariant),
                  onPressed: _player.hasNext ? () => _player.next() : null,
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.flowHideFloatingPlayer,
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.visibility_off_outlined,
                      color: scheme.onSurfaceVariant),
                  onPressed: () => _confirmHideBall(context),
                ),
              ],
            ),
            if (widget.onOpenLibrary != null) ...[
              const SizedBox(height: 8),
              PressScale(
                scale: 0.98,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onOpenLibrary!();
                  },
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppSurfaces.inset(context),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.queue_music_rounded,
                            size: 18, color: scheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.flowPlaylist,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PortableNowPlayingPage()),
    );
  }

  Future<void> _confirmHideBall(BuildContext context) async {
    final choice = await showDialog<_BallHideChoice>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        title: Text(context.l10n.flowHideFloatingPlayer),
        content: Text(context.l10n.flowKeepPlayingAndReopenTheFloatingPlayer),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext)
                .pop(_BallHideChoice.continuePlaying),
            child: Text(context.l10n.flowKeepPlaying),
          ),
          FilledButton.tonal(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_BallHideChoice.pausePlaying),
            child: Text(context.l10n.flowPauseAndRemove),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    Navigator.of(context).pop();
    PortablePlayerScope.hideBall();
    if (choice == _BallHideChoice.pausePlaying) {
      await _player.stop();
    }
  }

  static String _fmt(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

enum _BallHideChoice { continuePlaying, pausePlaying }
