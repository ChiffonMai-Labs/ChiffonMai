import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../chart_timing_mapper.dart';
import '../simai_game.dart';

@visibleForTesting
String? buildChartPerformanceText({
  required bool showFps,
  required bool showDetailedPerformanceInfo,
  required double measuredFps,
  required double frameIntervalP95Ms,
  required double motionStepP95Ms,
  required double frozenFrameRatio,
}) {
  if (!showFps && !showDetailedPerformanceInfo) return null;
  if (!showDetailedPerformanceInfo) {
    return 'FPS ${measuredFps.toStringAsFixed(1)}';
  }
  return 'FPS ${measuredFps.toStringAsFixed(1)}  '
      'P95 ${frameIntervalP95Ms.toStringAsFixed(1)}ms  '
      'Move ${motionStepP95Ms.toStringAsFixed(1)}ms  '
      'Frozen ${(frozenFrameRatio * 100).toStringAsFixed(0)}%';
}

/// Controls the short color pulse shown when the active chart BPM changes.
class BpmIndicatorColorTransition {
  static const Color idleColor = Colors.white70;
  static const Color increasedColor = Color(0xFFFF8A65);
  static const Color decreasedColor = Color(0xFF64B5F6);
  static const double holdDuration = 0.5;
  static const double recoveryDuration = 1.5;

  double _elapsed = holdDuration + recoveryDuration;
  Color _accent = idleColor;

  void trigger({required bool increased}) {
    _accent = increased ? increasedColor : decreasedColor;
    _elapsed = 0.0;
  }

  void update(double dt) {
    _elapsed = (_elapsed + dt).clamp(0.0, holdDuration + recoveryDuration);
  }

  Color get color {
    if (_elapsed <= holdDuration) return _accent;
    final progress = Curves.easeOutCubic.transform(
      ((_elapsed - holdDuration) / recoveryDuration).clamp(0.0, 1.0),
    );
    return Color.lerp(_accent, idleColor, progress)!;
  }
}

class ChartStatusTextComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  ChartStatusTextComponent({super.position});

  final BpmIndicatorColorTransition _bpmColor = BpmIndicatorColorTransition();
  TextPainter? _painter;
  double? _displayedBpm;
  double _refreshElapsed = 0.25;
  double _pulseRefreshElapsed = 0.0;

  // 记录上次排版输入，内容与宽度未变时跳过无谓的 TextPainter 重建与探测布局。
  bool? _lastShowCornerInfo;
  String? _lastBpmText;
  String? _lastDetailText;
  String? _lastPerformanceText;
  int? _lastBpmColorValue;
  double? _lastMaxLeftWidth;
  double? _lastExportScale;
  (int, int, int, double)? _lastProbeKey;
  bool _lastOverflowSingleLine = false;

  double get _exportScale {
    final minEdge = math.min(game.size.x, game.size.y);
    if (minEdge <= 0) return 1.0;
    return (minEdge / 984.0).clamp(0.25, 2.0);
  }

  Offset get _cornerPadding {
    if (game.headlessExport) {
      final scale = _exportScale;
      return Offset(22.0 * scale, 18.0 * scale);
    }
    return const Offset(10.0, 8.0);
  }

  TextStyle _resolvedBaseStyle() {
    final isExport = game.headlessExport;
    final scale = _exportScale;
    return game.withDisplayFont(
      TextStyle(
        color: BpmIndicatorColorTransition.idleColor,
        fontSize: isExport ? 32.0 * scale : 13.0,
        height: isExport ? 1.18 : 1.15,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final padding = _cornerPadding;
    position = Vector2(padding.dx, padding.dy);
    if (_displayedBpm != null &&
        (game.showCornerInfo || game.showDetailedPerformanceInfo)) {
      _rebuildPainter();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!game.showCornerInfo && !game.showDetailedPerformanceInfo) return;
    _bpmColor.update(dt);
    if (dt.isFinite && dt > 0) {
      _refreshElapsed += dt;
      _pulseRefreshElapsed += dt;
    }

    // 常规信息按 15Hz 刷新，BPM 变色脉冲期按 20Hz 刷新，避免每帧无谓重排文本。
    if (_refreshElapsed >= 1 / 15 || _painter == null) {
      _refreshElapsed = 0.0;
      _pulseRefreshElapsed = 0.0;
      _refreshText();
    } else if (_bpmColor.color != BpmIndicatorColorTransition.idleColor &&
        _pulseRefreshElapsed >= 1 / 20) {
      _pulseRefreshElapsed = 0.0;
      _rebuildPainter();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.showCornerInfo && !game.showDetailedPerformanceInfo) return;
    _painter?.paint(canvas, Offset.zero);
  }

  void refreshNow() => _refreshText();

  void _refreshText() {
    final timing = ChartTimingMapper.timingAtTime(game.chart, game.chartTime);
    final rawBpm = timing.tempo;
    // 无头导出固定按 1.0x 计算；预览播放按当前倍速同步展示实时 BPM。
    final effectiveBpm =
        rawBpm * (game.headlessExport ? 1.0 : game.playbackRate);
    final previousBpm = _displayedBpm;
    if (previousBpm != null && (effectiveBpm - previousBpm).abs() > 0.0001) {
      _bpmColor.trigger(increased: effectiveBpm > previousBpm);
    }
    _displayedBpm = effectiveBpm;
    _rebuildPainter(precomputedSubdivisions: timing.subdivisions);
  }

  void _rebuildPainter({double? precomputedSubdivisions}) {
    final bpm = _displayedBpm;
    if (bpm == null) return;
    final subdivisions =
        precomputedSubdivisions ??
        ChartTimingMapper.timingAtTime(game.chart, game.chartTime).subdivisions;
    final denom = subdivisions.round().clamp(1, 1024);
    final beats = _beatsAt(game.chartTime);
    final measure = (beats / 4.0).floor() + 1;
    final progress = _quarterProgressCodeForBeats(beats);
    final performanceText = buildChartPerformanceText(
      showFps: game.showFps,
      showDetailedPerformanceInfo: game.showDetailedPerformanceInfo,
      measuredFps: game.measuredFps,
      frameIntervalP95Ms: game.frameIntervalP95Ms,
      motionStepP95Ms: game.motionStepP95Ms,
      frozenFrameRatio: game.frozenFrameRatio,
    );
    final padding = _cornerPadding;
    final maxLeftWidth = game.size.x > 0
        ? math.max(
            80.0,
            (game.size.x - padding.dx * 2) *
                (game.headlessExport ? 0.60 : 0.56),
          )
        : double.infinity;
    final double currentExportScale = game.headlessExport ? _exportScale : 1.0;

    if (!game.showCornerInfo) {
      if (performanceText == null) {
        _painter?.dispose();
        _painter = null;
        _resetLastBuildState();
        size = Vector2.zero();
        return;
      }
      if (_painter != null &&
          _lastShowCornerInfo == false &&
          _lastPerformanceText == performanceText &&
          _lastMaxLeftWidth == maxLeftWidth &&
          _lastExportScale == currentExportScale) {
        return;
      }
      final baseStyle = _resolvedBaseStyle();
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(style: baseStyle, text: performanceText),
      )..layout(maxWidth: maxLeftWidth);
      _painter?.dispose();
      _painter = painter;
      _lastShowCornerInfo = false;
      _lastBpmText = null;
      _lastDetailText = null;
      _lastPerformanceText = performanceText;
      _lastBpmColorValue = null;
      _lastMaxLeftWidth = maxLeftWidth;
      _lastExportScale = currentExportScale;
      size = Vector2(_painter!.width, _painter!.height);
      return;
    }

    final bpmText = 'BPM ${bpm.toStringAsFixed(1)}';
    final detailText = 'M$measure  $progress  [1/$denom]';
    final bpmColor = _bpmColor.color;
    final bpmColorValue = bpmColor.toARGB32();

    // 内容、配色与排版宽度完全未变时直接复用现有 TextPainter，避免高频重复 layout。
    if (_painter != null &&
        _lastShowCornerInfo == true &&
        _lastBpmText == bpmText &&
        _lastDetailText == detailText &&
        _lastPerformanceText == performanceText &&
        _lastBpmColorValue == bpmColorValue &&
        _lastMaxLeftWidth == maxLeftWidth &&
        _lastExportScale == currentExportScale) {
      return;
    }

    final baseStyle = _resolvedBaseStyle();

    TextPainter buildPainter({required bool splitDetailLine}) {
      final secondPart = StringBuffer()
        ..write(splitDetailLine ? '\n' : '  ')
        ..write(detailText);
      if (performanceText != null) {
        secondPart
          ..write('\n')
          ..write(performanceText);
      }
      return TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(
              text: bpmText,
              style: baseStyle.copyWith(color: bpmColor),
            ),
            TextSpan(text: secondPart.toString()),
          ],
        ),
      )..layout(maxWidth: maxLeftWidth);
    }

    bool splitDetailLine = false;
    if (maxLeftWidth.isFinite) {
      final probeKey = (
        bpmText.length,
        detailText.length,
        maxLeftWidth.round(),
        currentExportScale,
      );
      if (_lastProbeKey != probeKey) {
        final singleLineProbe = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 1,
          text: TextSpan(style: baseStyle, text: '$bpmText  $detailText'),
        )..layout(maxWidth: maxLeftWidth);
        _lastOverflowSingleLine = singleLineProbe.didExceedMaxLines;
        singleLineProbe.dispose();
        _lastProbeKey = probeKey;
      }
      splitDetailLine = _lastOverflowSingleLine;
    } else {
      _lastProbeKey = null;
      _lastOverflowSingleLine = false;
    }

    final painter = buildPainter(splitDetailLine: splitDetailLine);

    _painter?.dispose();
    _painter = painter;
    _lastShowCornerInfo = true;
    _lastBpmText = bpmText;
    _lastDetailText = detailText;
    _lastPerformanceText = performanceText;
    _lastBpmColorValue = bpmColorValue;
    _lastMaxLeftWidth = maxLeftWidth;
    _lastExportScale = currentExportScale;
    size = Vector2(_painter!.width, _painter!.height);
  }

  void _resetLastBuildState() {
    _lastShowCornerInfo = null;
    _lastBpmText = null;
    _lastDetailText = null;
    _lastPerformanceText = null;
    _lastBpmColorValue = null;
    _lastMaxLeftWidth = null;
    _lastExportScale = null;
    _lastProbeKey = null;
    _lastOverflowSingleLine = false;
  }

  @override
  void onRemove() {
    _painter?.dispose();
    _painter = null;
    _resetLastBuildState();
    super.onRemove();
  }

  double _beatsAt(double time) =>
      ChartTimingMapper.beatsAtTime(game.chart, time);

  String _quarterProgressCodeForBeats(double beats) {
    final beatInMeasure = (beats - (beats / 4.0).floorToDouble() * 4.0).clamp(
      0.0,
      3.999999,
    );
    final beatIndex = beatInMeasure.floor().clamp(0, 3) + 1;
    final local = beatInMeasure - (beatIndex - 1);
    final pct = (local * 100).floor().clamp(0, 99);
    return '$beatIndex.${pct.toString().padLeft(2, '0')}';
  }
}
