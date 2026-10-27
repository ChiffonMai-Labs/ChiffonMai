import 'package:flutter/material.dart';
import '../service/CommunityAvatarStore.dart';

/// 按落笔顺序描出状态图标；状态不变时不会因页面重建而重播。
class CommunitySyncStatusIcon extends StatelessWidget {
  final AvatarSyncLevel level;
  final Color color;
  const CommunitySyncStatusIcon(
      {super.key, required this.level, required this.color});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(level),
          tween: Tween(begin: 0, end: 1),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          builder: (context, progress, _) => CustomPaint(
            size: const Size.square(14),
            painter: _StatusStrokePainter(level, color, progress),
          ),
        ),
      );
}

class _StatusStrokePainter extends CustomPainter {
  final AvatarSyncLevel level;
  final Color color;
  final double progress;
  _StatusStrokePainter(this.level, this.color, this.progress);

  static Path _cloud() => Path()
    ..moveTo(6, 19)
    ..cubicTo(0, 19, 0, 11, 5, 10)
    ..cubicTo(5, 2, 17, 2, 18, 10)
    ..cubicTo(24, 10, 24, 19, 18, 19)
    ..lineTo(6, 19);

  // 外轮廓先画，含义笔画后画；对钩沿左上→左下→右上连贯勾出。
  static final _paths = <AvatarSyncLevel, List<Path>>{
    AvatarSyncLevel.synced: [
      _cloud(),
      Path()
        ..moveTo(8, 12)
        ..lineTo(11, 15)
        ..lineTo(16, 9),
    ],
    AvatarSyncLevel.pending: [
      _cloud(),
      Path()
        ..moveTo(12, 17)
        ..lineTo(12, 9),
      Path()
        ..moveTo(8.5, 12.5)
        ..lineTo(12, 9)
        ..lineTo(15.5, 12.5),
    ],
    AvatarSyncLevel.syncing: [
      Path()
        ..moveTo(4, 9)
        ..cubicTo(7, 1, 19, 2, 21, 10),
      Path()
        ..moveTo(21, 5)
        ..lineTo(21, 10)
        ..lineTo(16, 10),
      Path()
        ..moveTo(20, 15)
        ..cubicTo(17, 23, 5, 22, 3, 14),
      Path()
        ..moveTo(3, 19)
        ..lineTo(3, 14)
        ..lineTo(8, 14),
    ],
    AvatarSyncLevel.error: [
      Path()..addOval(const Rect.fromLTWH(2, 2, 20, 20)),
      Path()
        ..moveTo(12, 7)
        ..lineTo(12, 13),
      Path()
        ..moveTo(12, 17)
        ..lineTo(12, 17.2),
    ],
    AvatarSyncLevel.localOnly: [
      Path()
        ..addRRect(RRect.fromRectAndRadius(
            const Rect.fromLTWH(6, 2, 12, 20), const Radius.circular(2))),
      Path()
        ..moveTo(11, 18.5)
        ..lineTo(13, 18.5),
    ],
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paths = _paths[level]!;
    for (var i = 0; i < paths.length; i++) {
      final portion = (progress * paths.length - i).clamp(0.0, 1.0);
      if (portion <= 0) break;
      if (portion >= 1) {
        canvas.drawPath(paths[i], paint);
      } else {
        final metrics = paths[i].computeMetrics().toList();
        var remaining =
            metrics.fold<double>(0, (sum, m) => sum + m.length) * portion;
        for (final metric in metrics) {
          if (remaining <= 0) break;
          canvas.drawPath(
              metric.extractPath(0, remaining.clamp(0, metric.length)), paint);
          remaining -= metric.length;
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StatusStrokePainter oldDelegate) =>
      oldDelegate.level != level ||
      oldDelegate.color != color ||
      oldDelegate.progress != progress;
}
