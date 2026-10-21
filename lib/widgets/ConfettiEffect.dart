import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/ConfettiPreferences.dart';

/// 全局纸屑特效播放器。
class ConfettiEffect {
  ConfettiEffect._();

  static void show(BuildContext context, {bool force = false}) {
    if (!context.mounted) return;
    final preferences = ConfettiPreferences.instance;
    if (!preferences.loaded) {
      unawaited(_showAfterLoad(context, force: force));
      return;
    }
    _insert(context, preferences, force: force);
  }

  static Future<void> _showAfterLoad(BuildContext context,
      {required bool force}) async {
    final preferences = ConfettiPreferences.instance;
    await preferences.load();
    if (!context.mounted) return;
    _insert(context, preferences, force: force);
  }

  static void _insert(BuildContext context, ConfettiPreferences preferences,
      {required bool force}) {
    if (!force && !preferences.enabled) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: _ConfettiBurst(
            preferences: preferences,
            onFinished: () {
              if (entry.mounted) entry.remove();
            },
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }
}

class _ConfettiBurst extends StatefulWidget {
  final ConfettiPreferences preferences;
  final VoidCallback onFinished;

  const _ConfettiBurst({
    required this.preferences,
    required this.onFinished,
  });

  @override
  State<_ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<_ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _pieces = List.generate(
      110,
      (_) => _ConfettiPiece.random(random, widget.preferences.position),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onFinished();
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final harmonyColor = widget.preferences.harmonyColor ?? scheme.primary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _ConfettiPainter(
          progress: _controller.value,
          gravityEnabled: widget.preferences.gravityEnabled,
          pieces: _pieces,
          paperType: widget.preferences.paperType,
          position: widget.preferences.position,
          harmonyColor: harmonyColor,
          harmonyLevel: widget.preferences.harmonyLevel,
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  final double startX;
  final double startY;
  final double travelX;
  final double travelY;
  final double initialVelocityY;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final int colorIndex;
  final int shapeIndex;

  const _ConfettiPiece({
    required this.startX,
    required this.startY,
    required this.travelX,
    required this.travelY,
    required this.initialVelocityY,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.colorIndex,
    required this.shapeIndex,
  });

  factory _ConfettiPiece.random(
    math.Random random,
    ConfettiBurstPosition position,
  ) {
    final edge = switch (position) {
      ConfettiBurstPosition.topBottom => random.nextBool() ? 0 : 1,
      ConfettiBurstPosition.leftRight => random.nextBool() ? 2 : 3,
      ConfettiBurstPosition.allEdges => random.nextInt(4),
    };
    final travel = 0.85 + random.nextDouble() * 0.4;
    final drift = (random.nextDouble() - 0.5) * 0.34;
    final startX = switch (edge) {
      0 || 1 => random.nextDouble(),
      2 => -0.16 - random.nextDouble() * 0.14,
      _ => 1.16 + random.nextDouble() * 0.14,
    };
    final startY = switch (edge) {
      0 => -0.16 - random.nextDouble() * 0.14,
      1 => 1.16 + random.nextDouble() * 0.14,
      2 || 3 => random.nextDouble(),
      _ => 0.0,
    };
    final travelX = switch (edge) {
      0 => drift,
      1 => drift,
      2 => travel,
      _ => -travel,
    };
    final travelY = switch (edge) {
      0 => travel,
      1 => -travel,
      2 => drift,
      _ => drift,
    };
    return _ConfettiPiece(
      startX: startX,
      startY: startY,
      travelX: travelX,
      travelY: travelY,
      // 以整段动画为单位时间：底部保留足够上冲速度，侧边略向上喷射。
      initialVelocityY: switch (edge) {
        1 => travelY * 2.6,
        2 || 3 => -0.8 + drift,
        _ => travelY * 0.7,
      },
      size: 5 + random.nextDouble() * 8,
      rotation: random.nextDouble() * math.pi,
      rotationSpeed: (random.nextDouble() - 0.5) * 8,
      colorIndex: random.nextInt(6),
      shapeIndex: random.nextInt(3),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final bool gravityEnabled;
  final List<_ConfettiPiece> pieces;
  final ConfettiPaperType paperType;
  final ConfettiBurstPosition position;
  final Color harmonyColor;
  final double harmonyLevel;

  _ConfettiPainter({
    required this.progress,
    required this.gravityEnabled,
    required this.pieces,
    required this.paperType,
    required this.position,
    required this.harmonyColor,
    required this.harmonyLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final palette = [
      const Color(0xFFFF5C8A),
      const Color(0xFFFFC857),
      const Color(0xFF4DD0E1),
      const Color(0xFF7E8CE0),
      const Color(0xFF70C174),
      const Color(0xFFFF8A4C),
    ];
    final falling = Curves.easeIn.transform(progress);
    // 开启重力时，水平运动逐渐减速，竖直位移遵循 v₀t + ½gt²。
    final horizontal = gravityEnabled
        ? (1 - math.exp(-2 * progress)) / (1 - math.exp(-2))
        : falling;
    final gravity = gravityEnabled ? 1.8 * progress * progress : 0.0;
    final fade = progress > 0.78 ? (1 - progress) / 0.22 : 1.0;
    for (final piece in pieces) {
      final x = (piece.startX + piece.travelX * horizontal) * size.width;
      final y = (piece.startY +
              (gravityEnabled
                  ? piece.initialVelocityY * progress + gravity
                  : piece.travelY * falling)) *
          size.height;
      final color = Color.lerp(
        palette[piece.colorIndex],
        harmonyColor,
        harmonyLevel,
      )!
          .withValues(alpha: fade.clamp(0.0, 1.0));
      final paint = Paint()..color = color;
      final rotation = piece.rotation + piece.rotationSpeed * progress;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      switch (_shapeOf(piece)) {
        case ConfettiPaperType.circle:
          canvas.drawCircle(Offset.zero, piece.size * 0.55, paint);
          break;
        case ConfettiPaperType.ribbon:
          final path = Path()
            ..moveTo(-piece.size, -piece.size * 0.22)
            ..quadraticBezierTo(
                0, piece.size * 0.5, piece.size, -piece.size * 0.22)
            ..lineTo(piece.size * 0.72, piece.size * 0.36)
            ..quadraticBezierTo(
                0, -piece.size * 0.05, -piece.size * 0.72, piece.size * 0.36)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case ConfettiPaperType.square:
        case ConfettiPaperType.mixed:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.size * 1.25,
              height: piece.size * 0.72,
            ),
            paint,
          );
          break;
      }
      canvas.restore();
    }
  }

  ConfettiPaperType _shapeOf(_ConfettiPiece piece) {
    if (paperType != ConfettiPaperType.mixed) return paperType;
    return switch (piece.shapeIndex) {
      0 => ConfettiPaperType.square,
      1 => ConfettiPaperType.circle,
      _ => ConfettiPaperType.ribbon,
    };
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.gravityEnabled != gravityEnabled ||
      oldDelegate.paperType != paperType ||
      oldDelegate.position != position ||
      oldDelegate.harmonyColor != harmonyColor ||
      oldDelegate.harmonyLevel != harmonyLevel;
}
