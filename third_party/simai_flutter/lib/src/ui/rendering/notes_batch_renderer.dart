import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../simai_flutter.dart';
import '../components/notes/base_note_component.dart';
import '../note_geometry.dart';
import '../simai_colors.dart';
import '../simai_visual_tokens.dart';
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

enum _SpriteNoteKind { tap, slide, touch }

/// Pass 1 收集到 Pass 2 统一合批的音符精灵条目（帧内复用对象池，零每帧堆分配）。
class _DeferredSpriteNoteEntry {
  _SpriteNoteKind kind = _SpriteNoteKind.tap;
  Note? note;
  double noteTime = 0.0;
  int collectionIndex = 0;
  int noteIndex = 0;
  bool isEach = false;
  bool isOpposite = false;
  bool skipHead = false;
  double approachTime = 1.0;
  BaseNoteDrawState? state;
  Map<double, int>? slideStartCounts;

  void clearRefs() {
    note = null;
    state = null;
    slideStartCounts = null;
  }
}

/// Pass 1 收集到 Pass 2 统一合批的打击光环条目。
class _DeferredHitEffectEntry {
  Note? note;
  double effectTime = 0.0;
  double holdDuration = 0.0;
  Color effectColor = const Color(0xFFFFC83D);

  void clearRefs() {
    note = null;
  }
}

class NotesBatchRenderer {
  static const double touchFireworksRippleDuration = 0.65;

  static final List<_DeferredSpriteNoteEntry> _noteEntries =
      <_DeferredSpriteNoteEntry>[];
  static final List<_DeferredHitEffectEntry> _hitEffectEntries =
      <_DeferredHitEffectEntry>[];

  static _DeferredSpriteNoteEntry _acquireNoteEntry(int index) {
    if (index < _noteEntries.length) {
      return _noteEntries[index];
    }
    final entry = _DeferredSpriteNoteEntry();
    _noteEntries.add(entry);
    return entry;
  }

  static _DeferredHitEffectEntry _acquireHitEffectEntry(int index) {
    if (index < _hitEffectEntries.length) {
      return _hitEffectEntries[index];
    }
    final entry = _DeferredHitEffectEntry();
    _hitEffectEntries.add(entry);
    return entry;
  }

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

    int noteEntryCount = 0;
    int hitEffectCount = 0;

    try {
      final double maxApproachTime = max(
        game.ringApproachTime,
        game.touchApproachTime,
      );
      final double ringApproachTime = max(game.ringApproachTime, 0.001);
      final double touchApproachTime = max(game.touchApproachTime, 0.001);
      final double chartTime = game.chartTime;
      final session = game.gameplaySession;
      final bool showHitEffects = game.showHitEffects;

      // === Pass 1：底层矢量层（烟花波纹、引导线、Hold/TouchHold 身体、WiFi 滑星条、EX 光晕）===
      for (int cIdx = visibleStartIndex; cIdx < visibleEndIndex; cIdx++) {
        final collection = game.chart.noteCollections[cIdx];
        if (collection.time > chartTime + maxApproachTime) break;

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
          final bool isHeadlessSlide =
              note.type == NoteType.forceInvalidate &&
              note.slidePaths.isNotEmpty;
          // 忽略不含滑星路径的无效占位音符，避免误落入普通 Tap 分支。
          if (note.type == NoteType.forceInvalidate && !isHeadlessSlide) {
            continue;
          }

          // 收集仍处于播放期内的打击特效（不依赖 computeDrawState，放到 Pass 2 统一合批）。
          if (showHitEffects && !isHeadlessSlide) {
            final hitEntry = _acquireHitEffectEntry(hitEffectCount);
            if (_collectHitEffect(
              game: game,
              session: session,
              note: note,
              noteTime: collection.time,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              out: hitEntry,
            )) {
              hitEffectCount++;
            }
          }

          // 1) 普通 Hold（含带长度的 Break Hold）：即便头部已判定，尾段仍需继续绘制。
          if (note.location.group == NoteGroup.tap &&
              (note.type == NoteType.hold ||
                  (note.type == NoteType.breakNote && note.length != null))) {
            final double duration = note.length ?? 0.0;
            if (chartTime >= collection.time + duration) continue;
            if (collection.time - chartTime > ringApproachTime) continue;

            final state = BaseNoteComponent.computeDrawState(
              game: game,
              note: note,
              noteTime: collection.time,
            );
            _drawHold(
              canvas,
              game: game,
              note: note,
              noteTime: collection.time,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              isEach: isEach,
              isOpposite: oppositeNoteIndices.contains(nIdx),
              state: state,
            );
            continue;
          }

          // 2) TouchHold：纯矢量绘制，留在 Pass 1 完成，无需 computeDrawState。
          if (note.isTouchHold) {
            final double n = collection.time - chartTime;
            if (n > touchApproachTime) continue;
            if (chartTime > collection.time + (note.length ?? 0.0) + 0.05) {
              continue;
            }
            TouchHoldPainter.paint(
              canvas,
              center: NoteUtils.getTouchPosition(
                game.chartCenter,
                game.chartRadius,
                NoteUtils.mirrorLocation(note.location, game.mirrorMode),
              ),
              scale: game.noteScale,
              timeUntilHead: n,
              approachTime: touchApproachTime,
              duration: note.length ?? 0.0,
              isEach: isEach,
              noteStyle: game.noteStyle,
            );
            continue;
          }

          // 3) 普通 Touch：已判定时提前跳过，避免进入 Pass 2 与无谓几何计算。
          if (note.type == NoteType.touch) {
            if (session != null && session.isHeadResolved(cIdx, nIdx)) {
              continue;
            }
            final double n = collection.time - chartTime;
            if (n > touchApproachTime) continue;
            if (session == null && n <= 0.0) continue;

            _acquireNoteEntry(noteEntryCount++)
              ..kind = _SpriteNoteKind.touch
              ..note = note
              ..noteTime = collection.time
              ..collectionIndex = cIdx
              ..noteIndex = nIdx
              ..isEach = isEach
              ..isOpposite = false
              ..skipHead = false
              ..approachTime = touchApproachTime
              ..state = null
              ..slideStartCounts = null;
            continue;
          }

          // 4) Slide 与无头星（forceInvalidate + 非空 slidePaths）：
          //    头部已判定或无头星时跳过 computeDrawState，但仍绘制滑星轨道与移动滑星。
          if (note.type == NoteType.slide || isHeadlessSlide) {
            if (collection.time - chartTime >= ringApproachTime) continue;

            final bool headResolved =
                isHeadlessSlide ||
                (session?.isHeadResolved(cIdx, nIdx) ?? false);
            final bool headPotentiallyVisible =
                !headResolved &&
                (chartTime < collection.time ||
                    (session != null &&
                        chartTime <=
                            collection.time +
                                SimaiTapJudgementRules.maximumWindowSeconds));

            BaseNoteDrawState? state;
            if (headPotentiallyVisible) {
              state = BaseNoteComponent.computeDrawState(
                game: game,
                note: note,
                noteTime: collection.time,
              );
            }

            final bool isOpposite = oppositeNoteIndices.contains(nIdx);
            _drawSlideVectorPass(
              canvas,
              game: game,
              note: note,
              collectionIndex: cIdx,
              noteIndex: nIdx,
              noteTime: collection.time,
              isEach: isEach,
              isOpposite: isOpposite,
              approachTime: ringApproachTime,
              state: state,
              skipHead: isHeadlessSlide,
              slideStartCounts: slideStartCounts,
            );

            _acquireNoteEntry(noteEntryCount++)
              ..kind = _SpriteNoteKind.slide
              ..note = note
              ..noteTime = collection.time
              ..collectionIndex = cIdx
              ..noteIndex = nIdx
              ..isEach = isEach
              ..isOpposite = isOpposite
              ..skipHead = isHeadlessSlide
              ..approachTime = ringApproachTime
              ..state = state
              ..slideStartCounts = slideStartCounts;
            continue;
          }

          // 5) 普通 Tap / Break Tap：头部已判定或超时时提前跳过 computeDrawState。
          if (session != null && session.isHeadResolved(cIdx, nIdx)) {
            continue;
          }
          if (collection.time - chartTime > ringApproachTime) continue;
          if (session == null && chartTime >= collection.time) continue;
          if (session != null &&
              chartTime >
                  collection.time +
                      SimaiTapJudgementRules.maximumWindowSeconds) {
            continue;
          }

          final state = BaseNoteComponent.computeDrawState(
            game: game,
            note: note,
            noteTime: collection.time,
          );
          final bool isOpposite = oppositeNoteIndices.contains(nIdx);

          _drawTapVectorPass(
            canvas,
            game: game,
            note: note,
            noteTime: collection.time,
            isEach: isEach,
            isOpposite: isOpposite,
            state: state,
          );

          _acquireNoteEntry(noteEntryCount++)
            ..kind = _SpriteNoteKind.tap
            ..note = note
            ..noteTime = collection.time
            ..collectionIndex = cIdx
            ..noteIndex = nIdx
            ..isEach = isEach
            ..isOpposite = isOpposite
            ..skipHead = false
            ..approachTime = ringApproachTime
            ..state = state
            ..slideStartCounts = null;
        }
      }

      // === Pass 2：精灵合批层（全量入同一个 SpriteBatch，帧末统一 flush 提交 GPU）===
      // 2a. 先绘制全部常规滑星轨道箭头，置于移动滑星与各音符主体之下。
      for (int i = 0; i < noteEntryCount; i++) {
        final entry = _noteEntries[i];
        if (entry.kind == _SpriteNoteKind.slide) {
          _drawSlideArrowsSpritePass(
            canvas,
            game: game,
            note: entry.note!,
            collectionIndex: entry.collectionIndex,
            noteIndex: entry.noteIndex,
            noteTime: entry.noteTime,
            isEach: entry.isEach,
            approachTime: entry.approachTime,
            slideStartCounts: entry.slideStartCounts,
          );
        }
      }

      // 2b. 绘制全部音符主体精灵（Tap、滑星星头与移动滑星、单/多押 Touch 花瓣与中心点）。
      for (int i = 0; i < noteEntryCount; i++) {
        final entry = _noteEntries[i];
        switch (entry.kind) {
          case _SpriteNoteKind.tap:
            _drawTap(
              canvas,
              game: game,
              note: entry.note!,
              noteTime: entry.noteTime,
              collectionIndex: entry.collectionIndex,
              noteIndex: entry.noteIndex,
              isEach: entry.isEach,
              isOpposite: entry.isOpposite,
              state: entry.state!,
            );
            break;
          case _SpriteNoteKind.slide:
            _drawSlideStarsSpritePass(
              canvas,
              game: game,
              note: entry.note!,
              collectionIndex: entry.collectionIndex,
              noteIndex: entry.noteIndex,
              noteTime: entry.noteTime,
              isEach: entry.isEach,
              approachTime: entry.approachTime,
              state: entry.state,
              skipHead: entry.skipHead,
              slideStartCounts: entry.slideStartCounts,
            );
            break;
          case _SpriteNoteKind.touch:
            _drawTouchSpritePass(
              canvas,
              game: game,
              note: entry.note!,
              noteTime: entry.noteTime,
              isEach: entry.isEach,
              approachTime: entry.approachTime,
            );
            break;
        }
      }

      // 2c. 统一合批绘制全部命中光环特效。
      for (int i = 0; i < hitEffectCount; i++) {
        final entry = _hitEffectEntries[i];
        _drawCollectedHitEffect(canvas, game: game, entry: entry);
      }
    } finally {
      for (int i = 0; i < noteEntryCount; i++) {
        _noteEntries[i].clearRefs();
      }
      for (int i = 0; i < hitEffectCount; i++) {
        _hitEffectEntries[i].clearRefs();
      }
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
