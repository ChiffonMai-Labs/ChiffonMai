import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
/*
 * 全屏播放页的视觉组件：曲绘取色、曲绘背景、环形表盘、下一首条和播放队列。
 *
 * 表盘的外圈有 8 个按键位，进度走过就点亮；播放时按曲目 BPM 从曲绘向外飞音符。
 * 曲库只有 BPM，没有谱面的 first 偏移，所以音符只跟拍速一致，不保证对齐重拍。
 *
 * ⚠️ 播放进度每帧都在变：进度和音符只走 [CustomPaint] 的 repaint，曲绘只改变换，
 * 时间文字按整秒刷新。不要在位置回调里 setState 整页。
 */
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../entity/Portable/PortableSong.dart';
import '../service/Portable/PortablePlayerController.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'MarqueeText.dart';
import 'PortablePlayerBadge.dart';

String formatPlaybackTime(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

/// 曲绘图源和取色结果。取色要解码和量化图片，按曲目与明暗缓存最近几首。
class NowPlayingArt {
  NowPlayingArt._();

  static final LinkedHashMap<String, ColorScheme> _schemes =
      LinkedHashMap<String, ColorScheme>();
  static final Map<String, ImageProvider> _providers =
      <String, ImageProvider>{};

  /// 本地有曲绘就用本地，没有再走网络，和 [PortableCover] 的顺序一致。
  static Future<ImageProvider> providerFor(PortableSong song) async {
    final cached = _providers[song.portableKey];
    if (cached != null) return cached;
    ImageProvider provider;
    try {
      await rootBundle.load(song.coverAssetPath);
      provider = AssetImage(song.coverAssetPath);
    } catch (_) {
      provider = NetworkImage(song.coverNetworkUrl);
    }
    if (_providers.length >= 32) _providers.remove(_providers.keys.first);
    _providers[song.portableKey] = provider;
    return provider;
  }

  /// 取不到颜色时返回 null，页面继续用 App 主题色。
  static Future<ColorScheme?> schemeFor(
    PortableSong song,
    ImageProvider provider,
    Brightness brightness,
  ) async {
    final key = '${song.portableKey}|${brightness.name}';
    final cached = _schemes.remove(key);
    if (cached != null) {
      _schemes[key] = cached;
      return cached;
    }
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: provider,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).timeout(const Duration(seconds: 5));
      if (_schemes.length >= 16) _schemes.remove(_schemes.keys.first);
      _schemes[key] = scheme;
      return scheme;
    } catch (error) {
      debugPrint('曲绘取色失败: $error');
      return null;
    }
  }
}

/// 模糊放大的曲绘加一层主题底色渐变。内容不变时由 [RepaintBoundary] 缓存。
class NowPlayingBackdrop extends StatelessWidget {
  final ImageProvider? provider;

  const NowPlayingBackdrop({super.key, this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;
    final image = provider;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: surface),
        RepaintBoundary(
          child: AnimatedSwitcher(
            duration: AppDesignTokens.motion(
              context,
              const Duration(milliseconds: 700),
            ),
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            child: image == null
                ? const SizedBox.expand(key: ValueKey('empty'))
                : ClipRect(
                    key: ValueKey(image),
                    child: Transform.scale(
                      scale: 1.3,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 36,
                          sigmaY: 36,
                        ),
                        child: Image(
                          image: ResizeImage(image, width: 96, height: 96),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0, 0.45, 1],
              colors: [
                surface.withValues(alpha: isDark ? 0.34 : 0.28),
                surface.withValues(alpha: isDark ? 0.5 : 0.46),
                surface.withValues(alpha: isDark ? 0.94 : 0.9),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 表盘各圈的半径，绘制和手势判定共用。
class _DialGeometry {
  final double size;

  const _DialGeometry(this.size);

  double get radius => size / 2;
  double get keyRadius => radius - size * 0.018;
  double get keyStroke => size * 0.013;
  double get trackRadius => radius - size * 0.052;
  double get trackStroke => size * 0.024;
  double get coverRadius => radius * 0.74;

  /// 触摸点在曲绘外的圆环上才算拖进度，下限略微放宽，避免手指压线时拖不动。
  bool hitsRing(double distance) =>
      distance >= coverRadius - 6 && distance <= radius + 8;
}

/// 播放页的主视觉：外环拖动调进度，曲绘左右滑切歌，轻点曲绘播放 / 暂停。
class NowPlayingDial extends StatefulWidget {
  final PortableSong song;
  final ValueListenable<Duration> position;
  final Duration duration;
  final bool isPlaying;
  final bool isBusy;

  /// 曲绘切换时的滑入方向：1 从右，-1 从左。
  final double slideDirection;
  final bool canSwipePrevious;
  final bool canSwipeNext;
  final String? queueLabel;
  final Future<void> Function(Duration position) onSeek;
  final ValueChanged<bool> onChangeSong;
  final VoidCallback onTogglePlay;

  const NowPlayingDial({
    super.key,
    required this.song,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.isBusy,
    required this.slideDirection,
    required this.canSwipePrevious,
    required this.canSwipeNext,
    required this.queueLabel,
    required this.onSeek,
    required this.onChangeSong,
    required this.onTogglePlay,
  });

  @override
  State<NowPlayingDial> createState() => _NowPlayingDialState();
}

enum _DragMode { none, ring, cover }

class _NowPlayingDialState extends State<NowPlayingDial> {
  final ValueNotifier<int> _seconds = ValueNotifier<int>(0);
  _DragMode _dragMode = _DragMode.none;
  double? _scrub;
  double _coverDrag = 0;

  int get _totalMs => widget.duration.inMilliseconds;

  @override
  void initState() {
    super.initState();
    widget.position.addListener(_syncSeconds);
    _syncSeconds();
  }

  @override
  void didUpdateWidget(covariant NowPlayingDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      oldWidget.position.removeListener(_syncSeconds);
      widget.position.addListener(_syncSeconds);
      _syncSeconds();
    }
  }

  @override
  void dispose() {
    widget.position.removeListener(_syncSeconds);
    _seconds.dispose();
    super.dispose();
  }

  void _syncSeconds() => _seconds.value = widget.position.value.inSeconds;

  /// 以 12 点钟方向为起点、顺时针一圈的比例。
  double _ringValue(Offset local, double size) {
    final dx = local.dx - size / 2;
    final dy = local.dy - size / 2;
    final angle = math.atan2(dx, -dy);
    return (angle < 0 ? angle + 2 * math.pi : angle) / (2 * math.pi);
  }

  void _setScrub(double value) {
    final previous = _scrub;
    // 拖过 12 点时比例会从 0.99 跳到 0.01，这种跳变当作顶到头，不跨圈跳转。
    if (previous != null && (value - previous).abs() > 0.5) return;
    if (previous != null &&
        ((previous * 8 - 0.5).floor() != (value * 8 - 0.5).floor())) {
      HapticFeedback.selectionClick();
    }
    setState(() => _scrub = value);
  }

  Future<void> _commitScrub() async {
    final value = _scrub;
    if (value == null) return;
    try {
      await widget.onSeek(Duration(milliseconds: (value * _totalMs).round()));
    } finally {
      if (mounted) setState(() => _scrub = null);
    }
  }

  void _onPanStart(DragStartDetails details, _DialGeometry geometry) {
    final offset =
        details.localPosition - Offset(geometry.radius, geometry.radius);
    final distance = offset.distance;
    if (geometry.hitsRing(distance)) {
      if (_totalMs <= 0) return;
      _dragMode = _DragMode.ring;
      setState(() => _scrub = _ringValue(details.localPosition, geometry.size));
    } else if (distance < geometry.coverRadius) {
      _dragMode = _DragMode.cover;
    }
  }

  void _onPanUpdate(DragUpdateDetails details, _DialGeometry geometry) {
    switch (_dragMode) {
      case _DragMode.ring:
        _setScrub(_ringValue(details.localPosition, geometry.size));
      case _DragMode.cover:
        final limit = geometry.coverRadius * 0.7;
        final hasTarget = _coverDrag + details.delta.dx < 0
            ? widget.canSwipeNext
            : widget.canSwipePrevious;
        // 没有相邻曲目时只给一点阻尼，让用户知道到头了。
        final delta = details.delta.dx * (hasTarget ? 1 : 0.25);
        setState(() => _coverDrag = (_coverDrag + delta).clamp(-limit, limit));
      case _DragMode.none:
        break;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    final mode = _dragMode;
    _dragMode = _DragMode.none;
    if (mode == _DragMode.ring) {
      unawaited(_commitScrub());
    } else if (mode == _DragMode.cover) {
      final velocity = details.velocity.pixelsPerSecond.dx;
      if (_coverDrag.abs() > 40 || velocity.abs() > 300) {
        widget
            .onChangeSong(velocity.abs() > 300 ? velocity < 0 : _coverDrag < 0);
      }
      setState(() => _coverDrag = 0);
    }
  }

  void _onPanCancel() {
    _dragMode = _DragMode.none;
    setState(() {
      _scrub = null;
      _coverDrag = 0;
    });
  }

  void _onTapUp(TapUpDetails details, _DialGeometry geometry) {
    final distance =
        (details.localPosition - Offset(geometry.radius, geometry.radius))
            .distance;
    if (distance < geometry.coverRadius - 6) {
      widget.onTogglePlay();
    } else if (geometry.hitsRing(distance) && _totalMs > 0) {
      setState(() => _scrub = _ringValue(details.localPosition, geometry.size));
      unawaited(_commitScrub());
    }
  }

  String _semanticTime(int seconds, int total) {
    final clamped = seconds.clamp(0, math.max(total, 0)).toInt();
    return '${formatPlaybackTime(Duration(seconds: clamped))} / '
        '${formatPlaybackTime(widget.duration)}';
  }

  void _nudge(int seconds) {
    if (_totalMs <= 0) return;
    final target = widget.position.value + Duration(seconds: seconds);
    unawaited(widget.onSeek(
      Duration(milliseconds: target.inMilliseconds.clamp(0, _totalMs).toInt()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = math.min(constraints.maxWidth, constraints.maxHeight);
      final geometry = _DialGeometry(size);
      final scheme = Theme.of(context).colorScheme;
      final disableMotion = MediaQuery.disableAnimationsOf(context);
      final bpm = disableMotion ? 0 : widget.song.bpm;

      final dial = SizedBox.square(
        dimension: size,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (details) => _onPanStart(details, geometry),
          onPanUpdate: (details) => _onPanUpdate(details, geometry),
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          onTapUp: (details) => _onTapUp(details, geometry),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      end: widget.isPlaying && _scrub == null ? 1 : 0,
                    ),
                    duration: AppDesignTokens.motion(
                      context,
                      AppDesignTokens.mediumMotion,
                    ),
                    builder: (context, beat, _) => CustomPaint(
                      painter: _DialPainter(
                        position: widget.position,
                        totalMs: _totalMs,
                        scrub: _scrub,
                        bpm: bpm,
                        beatStrength: beat,
                        geometry: geometry,
                        trackColor: scheme.onSurface.withValues(alpha: 0.12),
                        idleKeyColor: scheme.onSurface.withValues(alpha: 0.2),
                        primary: scheme.primary,
                        tertiary: scheme.tertiary,
                        knobBorder: scheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
              _cover(geometry, bpm),
            ],
          ),
        ),
      );

      return Semantics(
        container: true,
        child: ValueListenableBuilder<int>(
          valueListenable: _seconds,
          builder: (context, seconds, child) {
            final total = widget.duration.inSeconds;
            final displaySeconds =
                _scrub == null ? seconds : (_scrub! * total).round();
            return Semantics(
              slider: true,
              label: context.l10n.flowPlaybackProgressDragTheOuterRingTo,
              value: _semanticTime(displaySeconds, total),
              increasedValue: _semanticTime(displaySeconds + 5, total),
              decreasedValue: _semanticTime(displaySeconds - 5, total),
              onIncrease: total > 0 ? () => _nudge(5) : null,
              onDecrease: total > 0 ? () => _nudge(-5) : null,
              // 四角数据贴着可用区域的边缘，表盘变小时也不会压到外环。
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    child!,
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: _CornerStat(
                        label: context.l10n.flowElapsed,
                        value: formatPlaybackTime(
                          Duration(seconds: displaySeconds),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: _CornerStat(
                        label: context.l10n.flowDuration2,
                        value: formatPlaybackTime(widget.duration),
                        alignEnd: true,
                      ),
                    ),
                    if (widget.song.bpm > 0)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: _CornerStat(
                          label: 'BPM',
                          value: '${widget.song.bpm}',
                        ),
                      ),
                    if (widget.queueLabel != null)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: _CornerStat(
                          label: context.l10n.flowQueue,
                          value: widget.queueLabel!,
                          alignEnd: true,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          child: dial,
        ),
      );
    });
  }

  Widget _cover(_DialGeometry geometry, int bpm) {
    final diameter = geometry.coverRadius * 2;
    final cover = RepaintBoundary(
      child: ClipOval(
        child: SizedBox.square(
          dimension: diameter,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              AnimatedContainer(
                duration: _dragMode == _DragMode.cover
                    ? Duration.zero
                    : AppDesignTokens.motion(
                        context,
                        AppDesignTokens.fastMotion,
                      ),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(_coverDrag, 0, 0),
                child: AnimatedSwitcher(
                  duration: AppDesignTokens.motion(
                    context,
                    AppDesignTokens.mediumMotion,
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(widget.slideDirection * 0.2, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: AppDesignTokens.emphasizedCurve,
                      )),
                      child: child,
                    ),
                  ),
                  child: PortableCover(
                    key: ValueKey(widget.song.portableKey),
                    song: widget.song,
                    size: diameter,
                    radius: 0,
                  ),
                ),
              ),
              _coverOverlay(),
            ],
          ),
        ),
      ),
    );
    if (bpm <= 0) return cover;
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.position,
      child: cover,
      builder: (context, position, child) {
        final kick = widget.isPlaying && _scrub == null
            ? _beatProgress(position, bpm)
            : 1.0;
        final strength = (1 - kick) * (1 - kick);
        return Transform.scale(scale: 1 + 0.014 * strength, child: child);
      },
    );
  }

  /// 拖进度时在曲绘上显示目标时间，暂停时显示播放图标。
  Widget _coverOverlay() {
    final scrub = _scrub;
    final showPaused = !widget.isPlaying && !widget.isBusy && scrub == null;
    final visible = scrub != null || showPaused;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: AppDesignTokens.motion(context, AppDesignTokens.fastMotion),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: scrub != null ? 0.58 : 0.26),
          child: Center(
            child: scrub != null
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatPlaybackTime(Duration(
                            milliseconds: (scrub * _totalMs).round(),
                          )),
                          style: AppTheme.number(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          '/ ${formatPlaybackTime(widget.duration)}',
                          style: AppTheme.number(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
          ),
        ),
      ),
    );
  }
}

class _CornerStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _CornerStat({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.2,
                color: scheme.onSurfaceVariant,
              ),
            ),
            // 上千首的队列序号也要留在外环之外，放不下时等比缩小。
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 72),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment:
                    alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTheme.number(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                    height: 1.2,
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

/// 当前拍内的进度（0–1）。
double _beatProgress(Duration position, int bpm) {
  final beats = position.inMicroseconds / 1e6 * bpm / 60;
  return beats - beats.floorToDouble();
}

/// 某一拍音符所在的键位。乘大质数打散，看起来不像循环。
int _beatLane(int beat) => (beat * 2654435761 >>> 7) % 8;

class _DialPainter extends CustomPainter {
  final ValueListenable<Duration> position;
  final int totalMs;
  final double? scrub;
  final int bpm;
  final double beatStrength;
  final _DialGeometry geometry;
  final Color trackColor;
  final Color idleKeyColor;
  final Color primary;
  final Color tertiary;
  final Color knobBorder;

  _DialPainter({
    required this.position,
    required this.totalMs,
    required this.scrub,
    required this.bpm,
    required this.beatStrength,
    required this.geometry,
    required this.trackColor,
    required this.idleKeyColor,
    required this.primary,
    required this.tertiary,
    required this.knobBorder,
  }) : super(repaint: position);

  /// 第 [lane] 个键位的角度：从 12 点起顺时针 22.5°、67.5°……
  static double _laneFraction(int lane) => (lane + 0.5) / 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final positionMs = position.value.inMilliseconds;
    final progress =
        scrub ?? (totalMs > 0 ? (positionMs / totalMs).clamp(0.0, 1.0) : 0.0);

    final beats =
        bpm > 0 ? position.value.inMicroseconds / 1e6 * bpm / 60 : 0.0;
    final beatIndex = beats.floor();
    final beatT = beats - beatIndex;
    final showBeats = bpm > 0 && beatStrength > 0;

    // 上一拍的音符刚到键位，给键位一个短促的闪光。
    final hitFlash = showBeats ? (1 - (beatT / 0.4)).clamp(0.0, 1.0) : 0.0;
    final hitLane = _beatLane(beatIndex - 1);
    final hitIsDouble = (beatIndex - 1) % 4 == 0;

    _paintKeys(canvas, center, progress, hitLane, hitIsDouble, hitFlash);
    _paintTrack(canvas, center, progress);
    if (showBeats) _paintNotes(canvas, center, beatIndex, beatT);
    _paintKnob(canvas, center, progress);
  }

  void _paintKeys(
    Canvas canvas,
    Offset center,
    double progress,
    int hitLane,
    bool hitIsDouble,
    double hitFlash,
  ) {
    final rect = Rect.fromCircle(center: center, radius: geometry.keyRadius);
    const sweep = 16 * math.pi / 180;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var lane = 0; lane < 8; lane++) {
      final fraction = _laneFraction(lane);
      final lit = progress >= fraction;
      final isHit =
          lane == hitLane || (hitIsDouble && lane == (hitLane + 4) % 8);
      final flash = isHit ? hitFlash * beatStrength : 0.0;
      final base = lit ? primary : idleKeyColor;
      paint
        ..color = Color.lerp(base, tertiary, flash)!
        ..strokeWidth = geometry.keyStroke * (1 + 0.8 * flash);
      canvas.drawArc(
        rect,
        -math.pi / 2 + fraction * 2 * math.pi - sweep / 2,
        sweep,
        false,
        paint,
      );
    }
  }

  void _paintTrack(Canvas canvas, Offset center, double progress) {
    final rect = Rect.fromCircle(center: center, radius: geometry.trackRadius);
    canvas.drawCircle(
      center,
      geometry.trackRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = geometry.trackStroke
        ..color = trackColor,
    );
    if (progress <= 0) return;
    final sweep = progress * 2 * math.pi;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = geometry.trackStroke
        ..shader = SweepGradient(
          transform: const GradientRotation(-math.pi / 2),
          stops: [0, math.max(progress, 0.001)],
          colors: [primary, Color.lerp(primary, tertiary, 0.75)!],
        ).createShader(rect),
    );
  }

  void _paintNotes(Canvas canvas, Offset center, int beatIndex, double beatT) {
    final from = geometry.coverRadius + geometry.size * 0.008;
    final to = geometry.keyRadius;
    final radius = geometry.size * 0.016;
    final travel = Curves.easeInQuad.transform(beatT);
    final distance = ui.lerpDouble(from, to, travel)!;
    final alpha = (beatT / 0.2).clamp(0.0, 1.0) * beatStrength;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = geometry.size * 0.008
      ..color = tertiary.withValues(alpha: alpha);

    void drawLane(int lane) {
      final angle = -math.pi / 2 + _laneFraction(lane) * 2 * math.pi;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        radius * (0.7 + 0.3 * travel),
        paint,
      );
    }

    final lane = _beatLane(beatIndex);
    drawLane(lane);
    // 每四拍来一次对称的双音符，避免节奏过于单调。
    if (beatIndex % 4 == 0) drawLane((lane + 4) % 8);
  }

  void _paintKnob(Canvas canvas, Offset center, double progress) {
    final angle = -math.pi / 2 + progress * 2 * math.pi;
    final knob = center +
        Offset(math.cos(angle), math.sin(angle)) * geometry.trackRadius;
    final radius = geometry.trackStroke * (scrub == null ? 0.9 : 1.35);
    canvas.drawCircle(
        knob, radius + geometry.size * 0.006, Paint()..color = knobBorder);
    canvas.drawCircle(knob, radius, Paint()..color = primary);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.position != position ||
      old.totalMs != totalMs ||
      old.scrub != scrub ||
      old.bpm != bpm ||
      old.beatStrength != beatStrength ||
      old.geometry.size != geometry.size ||
      old.trackColor != trackColor ||
      old.idleKeyColor != idleKeyColor ||
      old.primary != primary ||
      old.tertiary != tertiary ||
      old.knobBorder != knobBorder;
}

/// 播放键：暂停时是圆角方块，播放时变成圆形，加载时转圈。
class NowPlayingPlayButton extends StatefulWidget {
  final bool isPlaying;
  final bool isBusy;
  final bool enabled;
  final VoidCallback onPressed;
  final double size;

  const NowPlayingPlayButton({
    super.key,
    required this.isPlaying,
    required this.isBusy,
    required this.enabled,
    required this.onPressed,
    this.size = 76,
  });

  @override
  State<NowPlayingPlayButton> createState() => _NowPlayingPlayButtonState();
}

class _NowPlayingPlayButtonState extends State<NowPlayingPlayButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return Semantics(
      button: true,
      label: widget.isBusy
          ? context.l10n.flowLoadingAudio
          : (widget.isPlaying ? context.l10n.flowPause : context.l10n.flowPlay),
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _pressed ? 0.92 : 1,
            duration: AppDesignTokens.motion(
              context,
              AppDesignTokens.fastMotion,
            ),
            child: AnimatedContainer(
              duration: duration,
              curve: AppDesignTokens.emphasizedCurve,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(
                  widget.isPlaying ? size / 2 : AppDesignTokens.radiusLarge,
                ),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: duration,
                child: widget.isBusy
                    ? SizedBox.square(
                        key: const ValueKey('busy'),
                        dimension: size * 0.34,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Icon(
                        widget.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(widget.isPlaying),
                        size: size * 0.46,
                        color: scheme.onPrimary,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 表盘下方的「接下来」条，点开播放队列。
class NowPlayingNextBar extends StatelessWidget {
  final PortableSong? nextSong;
  final String caption;
  final VoidCallback onTap;

  static const double height = 56;

  const NowPlayingNextBar({
    super.key,
    required this.nextSong,
    required this.caption,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final song = nextSong;
    return Semantics(
      button: true,
      label: context.l10n.flowOpenPlaybackQueue,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: scheme.onSurface.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          ),
          child: Row(
            children: [
              if (song != null) ...[
                PortableCover(
                  key: ValueKey(song.portableKey),
                  song: song,
                  size: 36,
                  radius: AppDesignTokens.radiusSmall - 2,
                ),
                const SizedBox(width: 10),
              ] else
                const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caption,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (song != null)
                      SizedBox(
                        height: 20,
                        child: MarqueeText(
                          key: ValueKey('next-${song.portableKey}'),
                          text: song.title,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.queue_music_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// 播放队列抽屉。队列可能有上千首，按固定行高按需构建。
Future<void> showNowPlayingQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _NowPlayingQueueSheet(),
  );
}

class _NowPlayingQueueSheet extends StatefulWidget {
  const _NowPlayingQueueSheet();

  @override
  State<_NowPlayingQueueSheet> createState() => _NowPlayingQueueSheetState();
}

class _NowPlayingQueueSheetState extends State<_NowPlayingQueueSheet> {
  static const double _rowHeight = 64;

  final PortablePlayerController _player = PortablePlayerController();
  late final ScrollController _scroll;

  int get _currentIndex {
    final current = _player.currentSong;
    if (current == null) return -1;
    return _player.queue.indexWhere((s) => s.lxnsId == current.lxnsId);
  }

  @override
  void initState() {
    super.initState();
    // 打开时把当前曲目摆在第二行，上方留一首作为上下文。
    final offset = math.max(0, _currentIndex - 1) * _rowHeight;
    _scroll = ScrollController(initialScrollOffset: offset);
    _player.addListener(_refresh);
  }

  @override
  void dispose() {
    _player.removeListener(_refresh);
    _scroll.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final queue = _player.queue;
    final currentIndex = _currentIndex;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  context.l10n.flowPlaybackQueue,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.flowP0Songs2((queue.length).toString()),
                  style: AppTheme.number(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 16),
              itemExtent: _rowHeight,
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final song = queue[index];
                final selected = index == currentIndex;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap:
                      selected ? null : () => unawaited(_player.playAt(index)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        PortableCover(
                          song: song,
                          size: 44,
                          radius: AppDesignTokens.radiusSmall,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: 21,
                                child: MarqueeText(
                                  key: ValueKey('queue-${song.portableKey}'),
                                  text: song.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.4,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? scheme.primary
                                        : scheme.onSurface,
                                  ),
                                ),
                              ),
                              Text(
                                song.artist.isEmpty
                                    ? context.l10n.flowUnknownArtist
                                    : song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.graphic_eq_rounded,
                            size: 20,
                            color: scheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
