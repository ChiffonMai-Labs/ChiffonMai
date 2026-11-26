import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../structures/mai_chart.dart';
import '../../structures/note_styles.dart';
import '../../structures/note_type.dart';
import '../center_display_mode.dart';
import '../simai_game.dart';
import 'achievement_rate_component.dart';

class ChartCounterSnapshot {
  final int combo;
  final int totalCombo;
  final int breakCount;
  final int protectedBreakCount;
  final int totalBreakCount;

  const ChartCounterSnapshot({
    required this.combo,
    required this.totalCombo,
    required this.breakCount,
    required this.protectedBreakCount,
    required this.totalBreakCount,
  });
}

/// Immutable event index used by the player HUD.
class ChartCounterIndex {
  final List<double> _comboTimes;
  final List<double> _breakTimes;
  final List<double> _protectedBreakTimes;

  const ChartCounterIndex._(
    this._comboTimes,
    this._breakTimes,
    this._protectedBreakTimes,
  );

  factory ChartCounterIndex.build(MaiChart chart) {
    final comboTimes = <double>[];
    final breakTimes = <double>[];
    final protectedBreakTimes = <double>[];

    for (final collection in chart.noteCollections) {
      for (final note in collection) {
        final headTime = collection.time;
        comboTimes.add(headTime);

        final headIsBreak =
            note.type == NoteType.breakNote ||
            (note.styles & NoteStyles.breakHead) != 0;
        if (headIsBreak) {
          breakTimes.add(headTime);
          if (note.isEx) protectedBreakTimes.add(headTime);
        }

        for (final path in note.slidePaths) {
          final pathTime = headTime + path.delay + path.duration;
          comboTimes.add(pathTime);
          if (path.type == NoteType.breakNote) {
            breakTimes.add(pathTime);
          }
        }
      }
    }

    comboTimes.sort();
    breakTimes.sort();
    protectedBreakTimes.sort();
    return ChartCounterIndex._(
      List.unmodifiable(comboTimes),
      List.unmodifiable(breakTimes),
      List.unmodifiable(protectedBreakTimes),
    );
  }

  ChartCounterSnapshot at(double chartTime) {
    final time = chartTime.isFinite ? chartTime : 0.0;
    return ChartCounterSnapshot(
      combo: _upperBound(_comboTimes, time),
      totalCombo: _comboTimes.length,
      breakCount: _upperBound(_breakTimes, time),
      protectedBreakCount: _upperBound(_protectedBreakTimes, time),
      totalBreakCount: _breakTimes.length,
    );
  }

  int comboAt(double chartTime) {
    return _upperBound(_comboTimes, chartTime.isFinite ? chartTime : 0.0);
  }

  static int _upperBound(List<double> values, double target) {
    int low = 0;
    int high = values.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (values[mid] <= target) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

class ChartCounterOverlayComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  ChartCounterOverlayComponent(this.index, {required this.achievementIndex});

  final ChartCounterIndex index;
  final CriticalAchievementIndex achievementIndex;

  double get _exportScale {
    final minEdge = math.min(size.x, size.y);
    if (minEdge <= 0) return 1.0;
    return (minEdge / 984.0).clamp(0.25, 2.0);
  }

  Offset get _cornerPadding {
    if (game.headlessExport) {
      final scale = _exportScale;
      return Offset(22.0 * scale, 18.0 * scale);
    }
    return const Offset(8.0, 8.0);
  }

  TextStyle get _primaryStyle {
    final isExport = game.headlessExport;
    final scale = _exportScale;
    return TextStyle(
      color: Colors.white,
      fontSize: isExport ? 34.0 * scale : 14.0,
      height: 1.15,
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
      // 实时预览采用无模糊实色偏移阴影，避免高密刷新触发高频字形高斯模糊。
      shadows: [
        isExport
            ? Shadow(color: Colors.black87, blurRadius: 5.0 * scale)
            : const Shadow(color: Colors.black87, offset: Offset(0, 1)),
      ],
    );
  }

  TextStyle get _breakStyle {
    final isExport = game.headlessExport;
    final scale = _exportScale;
    return TextStyle(
      color: const Color(0xFFFFD54F),
      fontSize: isExport ? 34.0 * scale : 14.0,
      height: 1.15,
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: [
        isExport
            ? Shadow(color: Colors.black87, blurRadius: 5.0 * scale)
            : const Shadow(color: Colors.black87, offset: Offset(0, 1)),
      ],
    );
  }

  TextPainter? _topRightPainter;
  TextPainter? _breakPainter;
  TextPainter? _timePainter;
  int _lastCombo = -1;
  int _lastBreak = -1;
  int _lastProtectedBreak = -1;
  int _lastCentisecond = -1;
  double _lastExportScale = -1;
  String? _lastTopRightText;
  SimaiCenterDisplayMode? _lastTopRightMode;
  bool? _lastShowAchievementRate;
  double _counterRefreshElapsed = 0.05;
  double _timeRefreshElapsed = 0.05;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    // 非离线导出模式下角标字号恒定为 14px，无需因尺寸微调清空所有 TextPainter。
    if (game.headlessExport) {
      final scale = _exportScale;
      if ((scale - _lastExportScale).abs() > 1e-4) {
        _lastExportScale = scale;
        _lastCombo = -1;
        _lastTopRightText = null;
        _lastBreak = -1;
        _lastProtectedBreak = -1;
        _lastCentisecond = -1;
      }
    }
  }

  /// 格式化 4 位小数百分比，避免浮点接近 0 时出现 `-0.0000`。
  static String _formatPercent(double value) {
    final normalized = value.abs() < 0.00005 ? 0.0 : value;
    return normalized.toStringAsFixed(4);
  }

  bool _shouldHideTopRight(SimaiCenterDisplayMode mode) =>
      mode == SimaiCenterDisplayMode.none ||
      (!game.showAchievementRate &&
          CriticalAchievementIndex.isPercentageAchievementMode(mode));

  String? _buildTopRightText(
    SimaiCenterDisplayMode mode,
    ChartCounterSnapshot snapshot,
  ) {
    if (_shouldHideTopRight(mode)) return null;
    final chartTime = game.chartTime;
    final maxDxScore = achievementIndex.eventCount * 3;
    return switch (mode) {
      SimaiCenterDisplayMode.achievementAdd =>
        'ACHV ${_formatPercent(achievementIndex.achievementAt(chartTime))}%',
      SimaiCenterDisplayMode.achievement100Plus =>
        'ACHV ${_formatPercent(achievementIndex.achievement100PlusForBreakCount(achievementIndex.judgedBreakCountAt(achievementIndex.judgedCountAt(chartTime))))}%',
      SimaiCenterDisplayMode.achievement101Subtract =>
        'ACHV ${_formatPercent(achievementIndex.maxAchievement)}%',
      SimaiCenterDisplayMode.dxScoreAdd =>
        'DX ${achievementIndex.judgedCountAt(chartTime) * 3} / $maxDxScore',
      SimaiCenterDisplayMode.dxScoreSubtract => 'DX $maxDxScore',
      SimaiCenterDisplayMode.dxStars => formatSimaiDxStarBonus(
        maxDxScore,
        maxDxScore,
      ),
      SimaiCenterDisplayMode.combo =>
        'COMBO ${snapshot.combo} / ${snapshot.totalCombo}',
      SimaiCenterDisplayMode.overS =>
        'S ${_formatPercent(achievementIndex.maxAchievement - 97.0)}%',
      SimaiCenterDisplayMode.overSS =>
        'SS ${_formatPercent(achievementIndex.maxAchievement - 99.0)}%',
      SimaiCenterDisplayMode.overSSS =>
        'SSS ${_formatPercent(achievementIndex.maxAchievement - 100.0)}%',
      SimaiCenterDisplayMode.none => null,
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    // 隐藏角标时直接跳过所有索引查询与文本排版。
    if (!game.showCornerInfo) return;

    if (dt.isFinite && dt > 0) {
      _counterRefreshElapsed += dt;
      _timeRefreshElapsed += dt;
    }

    final snapshot = index.at(game.chartTime);
    final centisecond = (game.chartTime.clamp(0.0, double.infinity) * 100)
        .floor();

    final topRightMode = game.topRightDisplayMode;
    final bool topRightHidden = _shouldHideTopRight(topRightMode);
    final bool modeChanged =
        _lastTopRightMode != topRightMode ||
        _lastShowAchievementRate != game.showAchievementRate;
    final bool counterNeedsInit =
        _breakPainter == null ||
        modeChanged ||
        (!topRightHidden && _topRightPainter == null);
    final bool shouldRefreshCounters =
        counterNeedsInit ||
        game.headlessExport ||
        !game.isPlaying ||
        (snapshot.combo - _lastCombo).abs() > 15 ||
        snapshot.combo == snapshot.totalCombo ||
        _counterRefreshElapsed >= 0.05;

    if (shouldRefreshCounters) {
      _lastTopRightMode = topRightMode;
      _lastShowAchievementRate = game.showAchievementRate;
      _lastCombo = snapshot.combo;
      var counterUpdated = false;

      final topRightText = _buildTopRightText(topRightMode, snapshot);
      if (topRightText == null) {
        if (_topRightPainter != null || _lastTopRightText != null) {
          _topRightPainter?.dispose();
          _topRightPainter = null;
          _lastTopRightText = null;
          counterUpdated = true;
        }
      } else if (topRightText != _lastTopRightText ||
          _topRightPainter == null) {
        _lastTopRightText = topRightText;
        _topRightPainter?.dispose();
        _topRightPainter = _textPainter(topRightText, _primaryStyle);
        counterUpdated = true;
      }

      if (snapshot.breakCount != _lastBreak ||
          snapshot.protectedBreakCount != _lastProtectedBreak ||
          _breakPainter == null) {
        _lastBreak = snapshot.breakCount;
        _lastProtectedBreak = snapshot.protectedBreakCount;
        _breakPainter?.dispose();
        _breakPainter = _textPainter(
          'BREAK ${snapshot.breakCount} '
          '(+${snapshot.protectedBreakCount} EX) / ${snapshot.totalBreakCount}',
          _breakStyle,
        );
        counterUpdated = true;
      }

      if (counterUpdated) {
        _counterRefreshElapsed = 0.0;
      }
    }

    // 实时播放时将右下角计时文本限频至约 20Hz，暂停、跳转或离线导出时立即精确更新。
    final bool shouldRefreshTime =
        _timePainter == null ||
        game.headlessExport ||
        !game.isPlaying ||
        (centisecond - _lastCentisecond).abs() > 15 ||
        _timeRefreshElapsed >= 0.05;
    if (centisecond != _lastCentisecond && shouldRefreshTime) {
      _timeRefreshElapsed = 0.0;
      _lastCentisecond = centisecond;
      _timePainter?.dispose();
      _timePainter = _textPainter(_formatTime(centisecond), _primaryStyle);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.showCornerInfo) return;
    final padding = _cornerPadding;
    final topRight = _shouldHideTopRight(game.topRightDisplayMode)
        ? null
        : _topRightPainter;
    if (topRight != null) {
      topRight.paint(
        canvas,
        Offset(size.x - topRight.width - padding.dx, padding.dy),
      );
    }

    final breakText = _breakPainter;
    if (breakText != null) {
      breakText.paint(
        canvas,
        Offset(padding.dx, size.y - breakText.height - padding.dy),
      );
    }

    final time = _timePainter;
    if (time != null) {
      time.paint(
        canvas,
        Offset(
          size.x - time.width - padding.dx,
          size.y - time.height - padding.dy,
        ),
      );
    }
  }

  @override
  void onRemove() {
    _topRightPainter?.dispose();
    _breakPainter?.dispose();
    _timePainter?.dispose();
    _topRightPainter = null;
    _breakPainter = null;
    _timePainter = null;
    _lastTopRightText = null;
    super.onRemove();
  }

  TextPainter _textPainter(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: game.withDisplayFont(style)),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  static String _formatTime(int centisecond) {
    final minutes = centisecond ~/ 6000;
    final seconds = (centisecond ~/ 100) % 60;
    final fraction = centisecond % 100;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${fraction.toString().padLeft(2, '0')}';
  }
}
