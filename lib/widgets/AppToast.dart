import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';

/// 提示语气：决定图标和强调色。不传时按文案判断（见 [AppToast.show]）。
enum AppToastTone { info, success, warning, error }

class _ToastData {
  final int id;
  final String message;
  final AppToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final int count;

  const _ToastData({
    required this.id,
    required this.message,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    this.count = 1,
  });
}

/// 全 App 唯一的轻提示入口，取代 SnackBar 和 Fluttertoast。
///
/// 不需要 context，异步回调里离页后调用也安全。
/// 显示层是挂在 `MaterialApp.builder` 上的 [AppToastHost]，盖在所有路由和对话框之上；
/// 从顶部落下，不会被键盘、底部导航或贴底操作栏挡住。
class AppToast {
  AppToast._();

  static final ValueNotifier<_ToastData?> _current = ValueNotifier(null);
  static int _nextId = 0;

  static void show(
    String message, {
    AppToastTone? tone,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final previous = _current.value;
    final resolvedTone = tone ?? _inferTone(message);
    // 同一句话连续出现时只累计次数，不重新落下一遍。
    final repeated = previous != null &&
        previous.message == message &&
        previous.tone == resolvedTone;
    _current.value = _ToastData(
      id: repeated ? previous.id : _nextId++,
      message: message,
      tone: resolvedTone,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration ?? _defaultDuration(message, actionLabel != null),
      count: repeated ? previous.count + 1 : 1,
    );
  }

  static void hide() => _current.value = null;

  static AppToastTone _inferTone(String message) {
    const errors = ['失败', '错误', '无法', '异常', '出错', '超时', '不能', '未能'];
    const warnings = ['请', '未', '暂无', '不支持', '没有', '不足', '再按'];
    const successes = ['成功', '已', '完成'];
    if (errors.any(message.contains)) return AppToastTone.error;
    if (successes.any(message.startsWith) || message.contains('成功')) {
      return AppToastTone.success;
    }
    if (warnings.any(message.contains)) return AppToastTone.warning;
    return AppToastTone.info;
  }

  /// 按字数给够阅读时间，带操作按钮的多留一会儿。
  static Duration _defaultDuration(String message, bool hasAction) {
    final ms = 1800 + message.length * 60 + (hasAction ? 2000 : 0);
    return Duration(milliseconds: ms.clamp(2400, 7000));
  }
}

/// 放在 `MaterialApp.builder` 的 Stack 最上层，用 `Positioned(top/left/right: 0)` 包住。
class AppToastHost extends StatefulWidget {
  const AppToastHost({super.key});

  @override
  State<AppToastHost> createState() => _AppToastHostState();
}

class _AppToastHostState extends State<AppToastHost>
    with TickerProviderStateMixin {
  // 没有上下界：弹簧过冲时数值会略超过 1。
  late final AnimationController _motion =
      AnimationController.unbounded(vsync: this);
  // preserve：系统关闭动画时普通控制器会把时长压缩到 5%，提示会一闪而过。
  late final AnimationController _countdown = AnimationController(
      vsync: this, animationBehavior: AnimationBehavior.preserve);
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));

  _ToastData? _shown;
  double _drag = 0;

  /// 正在退场。这时来了新提示要重新进场，否则退场动画会把新提示一起带走。
  bool _leaving = false;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    AppToast._current.addListener(_onChanged);
    _countdown.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _shown != null) {
        AppToast.hide();
      }
    });
    // 宿主挂载前就发出的提示（启动流程里的）。
    if (AppToast._current.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onChanged();
      });
    }
  }

  @override
  void dispose() {
    AppToast._current.removeListener(_onChanged);
    _motion.dispose();
    _countdown.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _onChanged() {
    // 可能在别的页面 build 途中被调用，这时不能 setState。
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onChanged();
      });
      return;
    }
    final next = AppToast._current.value;
    if (next == null) {
      _leave();
      return;
    }
    final wasShown = _shown;
    setState(() {
      _shown = next;
      if (wasShown == null) _drag = 0;
    });
    if (wasShown == null || _motion.value < 0.5 || _leaving) {
      _leaving = false;
      _enter();
    } else if (wasShown.id == next.id && !_reduceMotion) {
      _pulse.forward(from: 0);
    }
    _startCountdown(next.duration);
  }

  void _startCountdown(Duration duration) {
    _countdown
      ..duration = duration
      ..value = 1
      ..reverse();
  }

  void _enter() {
    if (_reduceMotion) {
      _motion.value = 1;
      return;
    }
    _motion.animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 420, damping: 27),
      _motion.value,
      1,
      0,
    ));
  }

  Future<void> _leave() async {
    _countdown.stop();
    if (_shown == null) return;
    final leaving = _shown;
    _leaving = true;
    await _motion.animateTo(0,
        duration: AppDesignTokens.motion(
            context, const Duration(milliseconds: 190)),
        curve: Curves.easeInCubic);
    // 退场途中来了新提示就不要清空。
    if (!mounted || AppToast._current.value != null || _shown != leaving) {
      return;
    }
    _leaving = false;
    setState(() => _shown = null);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_drag < -22 || (details.primaryVelocity ?? 0) < -320) {
      AppToast.hide();
    } else {
      setState(() => _drag = 0);
      _countdown.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _shown;
    if (data == null) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, media.padding.top + 8, AppDesignTokens.gutter, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: AnimatedBuilder(
            animation: Listenable.merge([_motion, _pulse]),
            builder: (context, child) {
              final v = _motion.value;
              final bump = 1 + 0.035 * Curves.easeOut.transform(
                  _pulse.value < 0.4 ? _pulse.value / 0.4 : (1 - _pulse.value) / 0.6);
              return Opacity(
                opacity: (v * 1.6).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (v - 1) * (88 + media.padding.top) + _drag),
                  child: Transform.scale(
                    scale: (0.9 + 0.1 * v) * bump,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                ),
              );
            },
            child: Listener(
              onPointerDown: (_) => _countdown.stop(),
              onPointerUp: (_) {
                if (_shown != null && AppToast._current.value != null) {
                  _countdown.reverse();
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: AppToast.hide,
                onVerticalDragUpdate: (d) => setState(() {
                  final next = _drag + d.delta.dy;
                  // 往下拉只给一点阻尼感，往上跟手。
                  _drag = next > 0 ? next.clamp(0.0, 10.0) : next;
                }),
                onVerticalDragEnd: _onDragEnd,
                child: _ToastCard(data: data, countdown: _countdown),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastCard extends StatelessWidget {
  final _ToastData data;
  final Animation<double> countdown;

  const _ToastCard({required this.data, required this.countdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accent(theme, data.tone);
    final duration = AppDesignTokens.motion(
        context, const Duration(milliseconds: 240));
    return Semantics(
      liveRegion: true,
      container: true,
      label: data.message,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppSurfaces.card(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
            border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              AnimatedSize(
                duration: duration,
                curve: AppDesignTokens.emphasizedCurve,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: AppDesignTokens.emphasizedCurve,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.topCenter,
                    children: [...previous, if (current != null) current],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                              begin: const Offset(0, 0.28), end: Offset.zero)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(data.id),
                    child: _ToastBody(data: data, accent: accent),
                  ),
                ),
              ),
              // 剩余时间：贴在卡片底边、随时间收短的一条细线。
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: countdown,
                  builder: (context, _) => Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: countdown.value,
                      child: Container(
                          height: 2.5,
                          color: accent.withValues(alpha: 0.55)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _accent(ThemeData theme, AppToastTone tone) => switch (tone) {
        AppToastTone.info => theme.colorScheme.primary,
        AppToastTone.success => AppColors.successForeground(theme.brightness),
        AppToastTone.warning => AppColors.warningOrange(theme.brightness),
        AppToastTone.error => theme.colorScheme.error,
      };
}

class _ToastBody extends StatelessWidget {
  final _ToastData data;
  final Color accent;

  const _ToastBody({required this.data, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 12.5),
      child: Row(
        children: [
          // 图标块弹一下，进场的视线落点。
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.55, end: 1),
            duration: AppDesignTokens.motion(
                context, const Duration(milliseconds: 420)),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: _ToastIcon(tone: data.tone, color: accent),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: theme.colorScheme.onSurface),
            ),
          ),
          if (data.count > 1) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
              ),
              child: Text('×${data.count}',
                  style: AppTheme.number(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: accent)),
            ),
          ],
          if (data.actionLabel != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                AppToast.hide();
                data.onAction?.call();
              },
              child: PressScale(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusPill),
                  ),
                  child: Text(data.actionLabel!,
                      style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ThemeData.estimateBrightnessForColor(accent) ==
                                  Brightness.dark
                              ? Colors.white
                              : Colors.black87)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 提示图标的进场动画：对号和叉号一笔一笔画出来，感叹号先画竖线再落点，通知铃铛摇一下。
class _ToastIcon extends StatelessWidget {
  final AppToastTone tone;
  final Color color;

  const _ToastIcon({required this.tone, required this.color});

  @override
  Widget build(BuildContext context) {
    final duration = AppDesignTokens.motion(
        context, const Duration(milliseconds: 560));
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: const Interval(0.12, 1, curve: Curves.easeOutCubic),
      builder: (context, value, _) {
        if (tone == AppToastTone.info) {
          // 幅度随进度衰减，摇两下停住。
          final angle = math.sin(value * math.pi * 4) * (1 - value) * 0.45;
          return Transform.rotate(
            angle: angle,
            alignment: Alignment.topCenter,
            child: Icon(Icons.notifications_none_rounded,
                size: 20, color: color),
          );
        }
        return CustomPaint(
          size: const Size.square(20),
          painter: _ToastStrokePainter(
              tone: tone, color: color, progress: value),
        );
      },
    );
  }
}

class _ToastStrokePainter extends CustomPainter {
  final AppToastTone tone;
  final Color color;
  final double progress;

  const _ToastStrokePainter({
    required this.tone,
    required this.color,
    required this.progress,
  });

  /// 按总长度的进度依次画出 [strokes]，上一笔画完才开始下一笔。
  void _drawStrokes(Canvas canvas, Paint paint, List<Path> strokes) {
    final metrics = [
      for (final stroke in strokes) ...stroke.computeMetrics(),
    ];
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    var remaining = total * progress;
    for (final metric in metrics) {
      if (remaining <= 0) break;
      canvas.drawPath(
          metric.extractPath(0, math.min(remaining, metric.length)), paint);
      remaining -= metric.length;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 20;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (tone) {
      case AppToastTone.success:
        _drawStrokes(canvas, paint, [
          Path()
            ..moveTo(4 * s, 10.5 * s)
            ..lineTo(8.5 * s, 15 * s)
            ..lineTo(16 * s, 5.5 * s),
        ]);
      case AppToastTone.error:
        _drawStrokes(canvas, paint, [
          Path()
            ..moveTo(5 * s, 5 * s)
            ..lineTo(15 * s, 15 * s),
          Path()
            ..moveTo(15 * s, 5 * s)
            ..lineTo(5 * s, 15 * s),
        ]);
      case AppToastTone.warning:
        final line = (progress / 0.7).clamp(0.0, 1.0);
        canvas.drawLine(Offset(10 * s, 3.5 * s),
            Offset(10 * s, (3.5 + 8 * line) * s), paint);
        final dot = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
        if (dot > 0) {
          canvas.drawCircle(
            Offset(10 * s, 16 * s),
            1.5 * s * Curves.easeOutBack.transform(dot),
            Paint()..color = color,
          );
        }
      case AppToastTone.info:
        break;
    }
  }

  @override
  bool shouldRepaint(_ToastStrokePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.tone != tone;
}
