import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../gameplay/gameplay_models.dart';
import '../auto_play_mode.dart';
import '../gameplay/judgement_display.dart';
import '../gameplay/judgement_feedback_renderer.dart';
import '../simai_game.dart';

/// 谱面预览/导出模式下的自动判定表示层（支持全部 14 种判定表示模式与 8 种模拟游玩方式）。
///
/// 性能设计：
/// - 复用 [SimaiGame.autoPlayTimeline] 预排序事件时间线，切换模拟游玩方式即时生效；
/// - 正常单调推进播放时使用 O(1) 滑动游标，拖动回退、切换模式或大跨度跳转时自动回退二分；
/// - 关闭开关时主动释放 GPU 位图缓存，保持零显存与零渲染开销。
class PlaybackJudgementComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  PlaybackJudgementComponent();

  final SimaiJudgementFeedbackRenderer _renderer =
      SimaiJudgementFeedbackRenderer();
  final List<SimaiJudgementRecord> _activeBuffer = <SimaiJudgementRecord>[];

  int _windowStartIndex = 0;
  double _lastChartTime = double.negativeInfinity;
  SimaiAutoPlayMode? _lastAutoPlayMode;
  int? _lastAutoPlaySeed;
  bool _hasActiveCache = false;

  int _lowerBound(List<SimaiJudgementRecord> events, double targetTime) {
    var lo = 0;
    var hi = events.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (events[mid].judgedTime <= targetTime) {
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
    final timeline = game.autoPlayTimeline;
    final events = timeline.events;
    if (events.isEmpty) return;
    final double now = game.chartTime;
    if (!now.isFinite) return;
    final double windowStart = now - simaiJudgementFeedbackDuration;

    // 正常单调推进播放时 O(1) 滑动游标；切换模式、重抽种子、回退或跨度 > 1s 时自动回退二分。
    if (_lastAutoPlayMode != timeline.mode ||
        _lastAutoPlaySeed != timeline.seed ||
        now < _lastChartTime ||
        now - _lastChartTime > 1.0) {
      _windowStartIndex = _lowerBound(events, windowStart);
      _lastAutoPlayMode = timeline.mode;
      _lastAutoPlaySeed = timeline.seed;
    } else {
      while (_windowStartIndex < events.length &&
          events[_windowStartIndex].judgedTime <= windowStart) {
        _windowStartIndex++;
      }
    }
    _lastChartTime = now;

    var idx = _windowStartIndex;
    _activeBuffer.clear();
    while (idx < events.length && events[idx].judgedTime <= now) {
      _activeBuffer.add(events[idx]);
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
