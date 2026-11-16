import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../simai_flutter.dart';
import '../components/notes/base_note_component.dart';
import '../note_geometry.dart';
import '../simai_colors.dart';
import '../utils/note_asset_manager.dart';
import '../utils/note_utils.dart';
import '../simai_game.dart';
import 'chart_runtime_index.dart';
import 'touch_hold_painter.dart';

part 'notes_batch_renderer_common.dart';
part 'notes_batch_renderer_hit_effect.dart';
part 'notes_batch_renderer_tap.dart';
part 'notes_batch_renderer_hold.dart';
part 'notes_batch_renderer_slide.dart';
part 'notes_batch_renderer_star.dart';
part 'notes_batch_renderer_touch.dart';

class NotesBatchRenderer {
  static const double touchFireworksRippleDuration = 0.65;

  static NoteBatchFrameMetrics renderVisibleNotes(
    Canvas canvas, {
    required SimaiGame game,
    required int visibleStartIndex,
    required int visibleEndIndex,
    required ChartRuntimeIndex runtimeIndex,
  }) {
    game.noteAssets.beginFrame();
    if (!game.isResourcesLoaded) {
      return game.noteAssets.endFrame();
    }

    try {
      final double maxApproachTime = max(
        game.ringApproachTime,
        game.touchApproachTime,
      );

      for (int cIdx = visibleStartIndex; cIdx < visibleEndIndex; cIdx++) {
        final collection = game.chart.noteCollections[cIdx];
        if (collection.time > game.chartTime + maxApproachTime) break;

        _drawTouchFireworksForCollection(
          canvas,
          game: game,
          collection: collection,
          collectionIndex: cIdx,
        );

        final bool isEach = runtimeIndex.collectionIsEach[cIdx];
        final oppositeNoteIndices = runtimeIndex.oppositeNoteIndices[cIdx];
        final slideStartCounts = runtimeIndex.slideStartCounts[cIdx];

        for (int nIdx = 0; nIdx < collection.length; nIdx++) {
          final note = collection[nIdx];
          final state = BaseNoteComponent.computeDrawState(
            game: game,
            note: note,
            noteTime: collection.time,
          );

          final bool isOpposite = oppositeNoteIndices.contains(nIdx);

          _drawHitEffect(
            canvas,
            game: game,
            note: note,
            noteTime: collection.time,
            collectionIndex: cIdx,
            noteIndex: nIdx,
          );

          if (note.location.group == NoteGroup.tap &&
              (note.type == NoteType.hold ||
                  (note.type == NoteType.breakNote && note.length != null))) {
            _drawHold(
              canvas,
              game: game,
              note: note,
              noteTime: collection.time,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              isEach: isEach,
              isOpposite: isOpposite,
              state: state,
            );
          } else if (note.isTouchHold || note.type == NoteType.touch) {
            _drawTouch(
              canvas,
              game: game,
              note: note,
              noteTime: collection.time,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              isEach: isEach,
              state: state,
            );
          } else if (note.type == NoteType.tap ||
              note.type == NoteType.breakNote) {
            _drawTap(
              canvas,
              game: game,
              note: note,
              noteTime: collection.time,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              isEach: isEach,
              isOpposite: isOpposite,
              state: state,
            );
          } else if (note.type == NoteType.slide) {
            _drawSlide(
              canvas,
              game: game,
              note: note,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              noteTime: collection.time,
              isEach: isEach,
              isOpposite: isOpposite,
              state: state,
              slideStartCounts: slideStartCounts,
            );
          } else {
            _drawTap(
              canvas,
              game: game,
              note: note,
              noteTime: collection.time,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              isEach: isEach,
              isOpposite: isOpposite,
              state: state,
            );
          }
        }
      }
    } finally {
      game.noteAssets.flush(canvas);
    }
    return game.noteAssets.endFrame();
  }

  static double slideApproachRotation({
    required double progress,
    required double pathLength,
    required double duration,
    double approachTime = 1.0,
  }) {
    return _slideApproachRotation(
      progress: progress,
      pathLength: pathLength,
      duration: duration,
      approachTime: approachTime,
    );
  }

  static double touchHoldRevealSweep(double progress) {
    return _touchHoldRevealSweep(progress);
  }

  static List<double> hitEffectPulseAges({
    required double elapsed,
    double holdDuration = 0.0,
  }) {
    return _hitEffectPulseAges(elapsed: elapsed, holdDuration: holdDuration);
  }

  static List<double> hitEffectPulseAgesForNote({
    required Note note,
    required double elapsed,
  }) {
    return _hitEffectPulseAges(
      elapsed: elapsed,
      holdDuration: _hitEffectHoldDuration(note),
    );
  }

  static double tapRadiusAfterJudge({
    required double chartRadius,
    required double approachTime,
    required double lateSeconds,
  }) {
    return _tapRadiusAfterJudge(
      chartRadius: chartRadius,
      approachTime: approachTime,
      lateSeconds: lateSeconds,
    );
  }

  static Color judgementEffectColor(SimaiJudgeGrade grade) =>
      _judgementEffectColor(grade);
}
