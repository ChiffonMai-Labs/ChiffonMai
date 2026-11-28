import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

/// Material 3 Expressive 多边形变形加载指示器。
///
/// 复刻官方 Android Compose M3E 运动规格：以弹簧阻尼驱动多边形序列平滑变形，
/// 每次切换叠加 90° 角度增量并配合全局旋转；外层通过边界归一化缩放保证
/// 在 12px～240px 任意尺寸下居中且不裁剪。
class ExpressiveLoadingIndicator extends StatefulWidget {
  /// 指示器外部占位尺寸（正方形边长）；传 null 时自动适配父级有界约束。
  final double? size;

  /// 是否带圆形背景容器（官方 Contained 变体，适合页面/卡片居中加载态）。
  final bool contained;

  /// 多边形前景颜色；未传时在 [contained] 下取 `onPrimaryContainer`，否则取主题色。
  final Color? color;

  /// [contained] 为 true 时的圆形背景色；未传时取 `primaryContainer`。
  final Color? containerColor;

  /// 参与循环变形的圆角多边形列表；未传时使用官方默认 7 形态序列。
  final List<RoundedPolygon>? polygons;

  /// 无障碍标签。
  final String? semanticsLabel;

  /// 无障碍状态文本。
  final String? semanticsValue;

  const ExpressiveLoadingIndicator({
    super.key,
    this.size,
    this.contained = false,
    this.color,
    this.containerColor,
    this.polygons,
    this.semanticsLabel,
    this.semanticsValue,
  }) : assert(
          polygons == null || polygons.length >= 2,
          'polygons 至少需要包含 2 个多边形才能执行变形动画',
        );

  /// 带圆形主题底壳的 M3E 变形加载器，默认 48dp，适合整页或卡片居中加载态。
  const ExpressiveLoadingIndicator.contained({
    super.key,
    this.size = 48.0,
    this.color,
    this.containerColor,
    this.polygons,
    this.semanticsLabel,
    this.semanticsValue,
  })  : contained = true,
        assert(
          polygons == null || polygons.length >= 2,
          'polygons 至少需要包含 2 个多边形才能执行变形动画',
        );

  @override
  State<ExpressiveLoadingIndicator> createState() =>
      _ExpressiveLoadingIndicatorState();
}

class _ExpressiveLoadingIndicatorState extends State<ExpressiveLoadingIndicator>
    with TickerProviderStateMixin {
  static final List<RoundedPolygon> _defaultPolygons = <RoundedPolygon>[
    MaterialShapes.softBurst,
    MaterialShapes.cookie9Sided,
    MaterialShapes.pentagon,
    MaterialShapes.pill,
    MaterialShapes.sunny,
    MaterialShapes.cookie4Sided,
    MaterialShapes.oval,
  ];

  static const int _globalRotationDurationMs = 4666;
  static const int _morphIntervalMs = 650;
  static const double _fullRotation = 360.0;
  static const double _quarterRotation = _fullRotation / 4.0;

  late List<RoundedPolygon> _polygons;
  late List<Morph> _morphSequence;
  late double _shapesScaleFactor;

  late final AnimationController _morphController;
  late final AnimationController _globalRotationController;
  int _currentMorphIndex = 0;
  double _morphRotationTargetAngle = _quarterRotation;
  Timer? _morphTimer;
  bool _animationsDisabled = false;

  final SpringSimulation _morphSpring = SpringSimulation(
    SpringDescription.withDampingRatio(
      ratio: 0.6,
      stiffness: 200.0,
      mass: 1.0,
    ),
    0.0,
    1.0,
    5.0,
    snapToEnd: true,
  );

  @override
  void initState() {
    super.initState();
    _initMorphSequence();
    _morphController = AnimationController.unbounded(vsync: this);
    _globalRotationController = AnimationController(
      duration: const Duration(milliseconds: _globalRotationDurationMs),
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (disabled != _animationsDisabled ||
        (!disabled && _morphTimer == null)) {
      _animationsDisabled = disabled;
      _syncAnimationState();
    }
  }

  @override
  void didUpdateWidget(covariant ExpressiveLoadingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.polygons, widget.polygons)) {
      _initMorphSequence();
      _currentMorphIndex = 0;
      _morphRotationTargetAngle = _quarterRotation;
      if (!_animationsDisabled) {
        _startMorphCycle();
      }
    }
  }

  @override
  void dispose() {
    _morphTimer?.cancel();
    _morphTimer = null;
    _morphController.dispose();
    _globalRotationController.dispose();
    super.dispose();
  }

  void _initMorphSequence() {
    final source = widget.polygons ?? _defaultPolygons;
    // 归一化到 [0, 1] x [0, 1]，确保自定义多边形与官方 MaterialShapes 使用同一基准。
    _polygons = source.map((p) => p.normalized()).toList(growable: false);
    final morphs = <Morph>[];
    for (int i = 0; i < _polygons.length; i++) {
      final next = (i + 1) % _polygons.length;
      morphs.add(Morph(_polygons[i], _polygons[next]));
    }
    _morphSequence = morphs;
    _shapesScaleFactor = _calculateScaleFactor(_polygons);
  }

  /// 结合旋转外接最大包络与轴对齐包围盒计算统一安全缩放比例，防止旋转裁边。
  static double _calculateScaleFactor(List<RoundedPolygon> polygons) {
    var scaleFactor = 1.0;
    for (final polygon in polygons) {
      final bounds = polygon.calculateBounds();
      final maxBounds = polygon.calculateMaxBounds();
      final boundsWidth = bounds[2] - bounds[0];
      final boundsHeight = bounds[3] - bounds[1];
      final maxBoundsWidth = maxBounds[2] - maxBounds[0];
      final maxBoundsHeight = maxBounds[3] - maxBounds[1];
      if (maxBoundsWidth <= 0 || maxBoundsHeight <= 0) continue;
      final scaleX = boundsWidth / maxBoundsWidth;
      final scaleY = boundsHeight / maxBoundsHeight;
      scaleFactor = math.min(scaleFactor, math.max(scaleX, scaleY));
    }
    return scaleFactor;
  }

  void _syncAnimationState() {
    if (_animationsDisabled) {
      _morphTimer?.cancel();
      _morphTimer = null;
      _globalRotationController.stop();
      _morphController.stop();
      _morphController.value = 0.0;
      _morphRotationTargetAngle = 0.0;
      return;
    }
    if (!_globalRotationController.isAnimating) {
      _globalRotationController.repeat();
    }
    _morphTimer ??= Timer.periodic(
      const Duration(milliseconds: _morphIntervalMs),
      (_) => _startMorphCycle(),
    );
    _startMorphCycle();
  }

  void _startMorphCycle() {
    if (!mounted || _animationsDisabled) return;
    _currentMorphIndex = (_currentMorphIndex + 1) % _morphSequence.length;
    _morphRotationTargetAngle =
        (_morphRotationTargetAngle + _quarterRotation) % _fullRotation;
    _morphController
      ..value = 0.0
      ..animateWith(_morphSpring);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.size != null) {
      return _buildSized(context, widget.size!);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final resolved = shortest.isFinite
            ? shortest
            : (widget.contained ? 48.0 : 36.0);
        return _buildSized(context, resolved);
      },
    );
  }

  Widget _buildSized(BuildContext context, double boxSize) {
    final scheme = Theme.of(context).colorScheme;
    final indicatorTheme = ProgressIndicatorTheme.of(context);
    final activeColor = widget.color ??
        (widget.contained
            ? scheme.onPrimaryContainer
            : (indicatorTheme.color ?? scheme.primary));
    // Contained 沿用官方 38:48 的图形容器比；无底壳小尺寸略提高占比以维持辨识度。
    final double activeAreaSize = widget.contained
        ? boxSize * (38.0 / 48.0)
        : (boxSize <= 24.0 ? boxSize * 0.90 : boxSize * 0.84);

    Widget content = SizedBox.square(
      dimension: boxSize,
      child: Center(
        child: SizedBox.square(
          dimension: activeAreaSize,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _morphController,
              _globalRotationController,
            ]),
            builder: (context, _) {
              final double morphProgress =
                  _morphController.value.clamp(0.0, 1.0);
              final double totalRotationDegrees = _animationsDisabled
                  ? 0.0
                  : morphProgress * _quarterRotation +
                      _morphRotationTargetAngle +
                      _globalRotationController.value * _fullRotation;
              return Transform.rotate(
                angle: totalRotationDegrees * (math.pi / 180.0),
                child: CustomPaint(
                  painter: _ExpressiveMorphPainter(
                    morph: _morphSequence[_currentMorphIndex],
                    progress: morphProgress,
                    color: activeColor,
                    scaleFactor: _shapesScaleFactor,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ),
    );

    if (widget.contained) {
      content = DecoratedBox(
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          color: widget.containerColor ?? scheme.primaryContainer,
        ),
        child: content,
      );
    }

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: widget.semanticsLabel,
        value: widget.semanticsValue,
      ),
      child: RepaintBoundary(child: content),
    );
  }
}

class _ExpressiveMorphPainter extends CustomPainter {
  final Morph morph;
  final double progress;
  final Color color;
  final double scaleFactor;

  const _ExpressiveMorphPainter({
    required this.morph,
    required this.progress,
    required this.color,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    if (side <= 0) return;
    final rawPath = morph.toPath(progress: progress);
    final Matrix4 scaleMatrix = Matrix4.diagonal3Values(
      side * scaleFactor,
      side * scaleFactor,
      1.0,
    );
    final Path scaledPath = rawPath.transform(scaleMatrix.storage);
    final Rect bounds = scaledPath.getBounds();
    final Offset centerShift =
        Offset(size.width / 2.0, size.height / 2.0) - bounds.center;
    canvas.drawPath(
      scaledPath.shift(centerShift),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ExpressiveMorphPainter oldDelegate) {
    return !identical(oldDelegate.morph, morph) ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}
