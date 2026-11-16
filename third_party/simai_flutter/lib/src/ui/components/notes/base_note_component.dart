import 'dart:math';
import 'dart:ui';

import '../../../../simai_flutter.dart';
import '../../simai_game.dart';
import '../../note_motion.dart';
import '../../utils/note_utils.dart';

class BaseNoteDrawState {
  final double approachTime;
  final double progress;
  final double currentRadius;
  final double drawScale;
  final double drawAngle;
  final Offset drawPosition;

  const BaseNoteDrawState({
    required this.approachTime,
    required this.progress,
    required this.currentRadius,
    required this.drawScale,
    required this.drawAngle,
    required this.drawPosition,
  });
}

class BaseNoteComponent {
  static const double initialRadiusRatio = NoteMotion.initialRadiusRatio;
  static const double scaleInProgressRatio = NoteMotion.scaleInProgressRatio;

  static BaseNoteDrawState computeDrawState({
    required SimaiGame game,
    required Note note,
    required double noteTime,
  }) {
    final double approachTime = (note.location.group != NoteGroup.tap)
        ? game.touchApproachTime
        : game.ringApproachTime;
    final double safeApproachTime = max(approachTime, 0.001);

    final double progress =
        1.0 - (noteTime - game.chartTime) / safeApproachTime;

    final double startRadius = game.chartRadius * initialRadiusRatio;

    double currentRadius;
    double drawScale;
    if (progress < scaleInProgressRatio) {
      currentRadius = startRadius;
      drawScale = (progress / scaleInProgressRatio).clamp(0.0, 1.0);
    } else {
      final double moveProgress =
          ((progress - scaleInProgressRatio) / (1.0 - scaleInProgressRatio))
              .clamp(0.0, 1.0);
      currentRadius =
          startRadius + (game.chartRadius - startRadius) * moveProgress;
      drawScale = 1.0;
    }

    final Location mirroredLoc = NoteUtils.mirrorLocation(
      note.location,
      game.mirrorMode,
    );
    final double drawAngle = (-67.5 + mirroredLoc.index * 45) * pi / 180;

    final Offset drawPosition = Offset(
      game.chartCenter.dx + currentRadius * cos(drawAngle),
      game.chartCenter.dy + currentRadius * sin(drawAngle),
    );

    return BaseNoteDrawState(
      approachTime: safeApproachTime,
      progress: progress,
      currentRadius: currentRadius,
      drawScale: drawScale,
      drawAngle: drawAngle,
      drawPosition: drawPosition,
    );
  }
}
