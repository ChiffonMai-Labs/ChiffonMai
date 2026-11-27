import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../gameplay/gameplay_models.dart';
import '../../structures/mai_chart.dart';
import '../../structures/note_group.dart';
import '../../structures/note_styles.dart';
import '../../structures/note_type.dart';
import '../gameplay/judgement_display.dart';
import '../gameplay/judgement_feedback_renderer.dart';
import '../simai_game.dart';

/// 谱面预览/导出模式下的自动判定表示层（支持全部 14 种判定表示模式）。
///
/// 性能设计：
/// - 加载期一次性构建按击中时间排序的事件时间线，避免渲染期遍历谱面；
/// - 正常单调推进播放时使用 O(1) 滑动游标，拖动回退或大跨度跳转时自动回退二分；
/// - 关闭开关时主动释放 GPU 位图缓存，保持零显存与零渲染开销。
class PlaybackJudgementComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  PlaybackJudgementComponent(MaiChart chart) : _events = _buildEvents(chart);

  final List<SimaiJudgementRecord> _events;
  final SimaiJudgementFeedbackRenderer _renderer =
      SimaiJudgementFeedbackRenderer();
  final List<SimaiJudgementRecord> _activeBuffer = <SimaiJudgementRecord>[];

  int _windowStartIndex = 0;
  double _lastChartTime = double.negativeInfinity;
  bool _hasActiveCache = false;

  static List<SimaiJudgementRecord> _buildEvents(MaiChart chart) {
    final events = <SimaiJudgementRecord>[];
    final collections = chart.noteCollections;
    for (var cIdx = 0; cIdx < collections.length; cIdx++) {
      final collection = collections[cIdx];
      final baseTime = collection.time;
      if (!baseTime.isFinite) continue;

      for (var nIdx = 0; nIdx < collection.length; nIdx++) {
        final note = collection[nIdx];
        final isBreakHead =
            note.type == NoteType.breakNote ||
            (note.styles & NoteStyles.breakHead) != 0;

        // 无头滑星（forceInvalidate）不产生头部判定，仅保留后续滑星轨迹终点判定。
        if (note.type != NoteType.forceInvalidate) {
          final bool isHold = note.type == NoteType.hold || note.isTouchHold;
          final double hitTime =
              isHold ? baseTime + (note.length ?? 0.0) : baseTime;
          if (hitTime.isFinite) {
            final SimaiGameplayScoringType scoringType;
            if (isBreakHead) {
              scoringType = SimaiGameplayScoringType.breakNote;
            } else if (isHold) {
              scoringType = SimaiGameplayScoringType.hold;
            } else if (note.location.group != NoteGroup.tap) {
              scoringType = SimaiGameplayScoringType.touch;
            } else {
              scoringType = SimaiGameplayScoringType.tap;
            }
            events.add(
              SimaiJudgementRecord(
                collectionIndex: cIdx,
                noteIndex: nIdx,
                slidePathIndex: null,
                targetTime: hitTime,
                judgedTime: hitTime,
                offsetSeconds: 0.0,
                grade: SimaiJudgeGrade.criticalPerfect,
                band: SimaiJudgeBand.criticalPerfect,
                timing: SimaiJudgeTiming.none,
                scoringType: scoringType,
                isAuto: false,
              ),
            );
          }
        }

        for (var sIdx = 0; sIdx < note.slidePaths.length; sIdx++) {
          final slide = note.slidePaths[sIdx];
          final double endTime = baseTime + slide.delay + slide.duration;
          if (!endTime.isFinite) continue;
          events.add(
            SimaiJudgementRecord(
              collectionIndex: cIdx,
              noteIndex: nIdx,
              slidePathIndex: sIdx,
              targetTime: endTime,
              judgedTime: endTime,
              offsetSeconds: 0.0,
              grade: SimaiJudgeGrade.criticalPerfect,
              band: SimaiJudgeBand.criticalPerfect,
              timing: SimaiJudgeTiming.none,
              scoringType: slide.type == NoteType.breakNote
                  ? SimaiGameplayScoringType.breakNote
                  : SimaiGameplayScoringType.slide,
              isAuto: false,
            ),
          );
        }
      }
    }
    events.sort((a, b) => a.judgedTime.compareTo(b.judgedTime));
    return events;
  }

  int _lowerBound(double targetTime) {
    var lo = 0;
    var hi = _events.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_events[mid].judgedTime <= targetTime) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
  }

  @override
  void onRemove() {
    _renderer.dispose();
    _hasActiveCache = false;
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (!game.showJudgementDisplay) {
      if (_hasActiveCache) {
        _renderer.dispose();
        _hasActiveCache = false;
      }
      return;
    }
    if (_events.isEmpty) return;
    final double now = game.chartTime;
    if (!now.isFinite) return;
    final double windowStart = now - simaiJudgementFeedbackDuration;

    // 正常单调推进播放时 O(1) 滑动游标；回退或跨度 > 1s 时自动回退二分。
    if (now < _lastChartTime || now - _lastChartTime > 1.0) {
      _windowStartIndex = _lowerBound(windowStart);
    } else {
      while (_windowStartIndex < _events.length &&
          _events[_windowStartIndex].judgedTime <= windowStart) {
        _windowStartIndex++;
      }
    }
    _lastChartTime = now;

    var idx = _windowStartIndex;
    _activeBuffer.clear();
    while (idx < _events.length && _events[idx].judgedTime <= now) {
      _activeBuffer.add(_events[idx]);
      idx++;
    }
    if (_activeBuffer.isEmpty) return;

    _hasActiveCache = true;
    _renderer.paintRecords(
      canvas,
      game: game,
      records: _activeBuffer,
      mode: game.judgementDisplayMode,
      skipAuto: false,
    );
  }
}
