import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

/// `simai_flutter` 内部复用的 M3E 多边形变形加载器。
///
/// 避免直接依赖主工程组件产生循环引用，行为与主工程 `ExpressiveLoadingIndicator` 对齐。
class SimaiExpressiveLoadingIndicator extends StatefulWidget {
  final double? size;
  final bool contained;
  final Color? color;
  final Color? containerColor;
  final List<RoundedPolygon>? polygons;
  final String? semanticsLabel;
  final String? semanticsValue;

  const SimaiExpressiveLoadingIndicator({
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
          'polygons must contain at least 2 shapes',
        );

  const SimaiExpressiveLoadingIndicator.contained({
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
          'polygons must contain at least 2 shapes',
        );

  @override
  State<SimaiExpressiveLoadingIndicator> createState() =>
      _SimaiExpressiveLoadingIndicatorState();
}

class _SimaiExpressiveLoadingIndicatorState
    extends State<SimaiExpressiveLoadingIndicator>
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
  void didUpdateWidget(covariant SimaiExpressiveLoadingIndicator oldWidget) {
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
    _polygons = source.map((p) => p.normalized()).toList(growable: false);
    final morphs = <Morph>[];
    for (int i = 0; i < _polygons.length; i++) {
      final next = (i + 1) % _polygons.length;
      morphs.add(Morph(_polygons[i], _polygons[next]));
    }
    _morphSequence = morphs;
    _shapesScaleFactor = _calculateScaleFactor(_polygons);
  }

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
                  painter: _SimaiExpressiveMorphPainter(
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

class _SimaiExpressiveMorphPainter extends CustomPainter {
  final Morph morph;
  final double progress;
  final Color color;
  final double scaleFactor;

  const _SimaiExpressiveMorphPainter({
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
  bool shouldRepaint(covariant _SimaiExpressiveMorphPainter oldDelegate) {
    return !identical(oldDelegate.morph, morph) ||
        oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}
