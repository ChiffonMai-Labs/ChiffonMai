import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../structures/mai_chart.dart';
import '../../structures/note_styles.dart';
import '../../structures/note_type.dart';
import '../center_display_mode.dart';
import '../simai_game.dart';

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
  ChartCounterOverlayComponent(this.index, {required this.achievementAt});

  final ChartCounterIndex index;
  final double Function(double chartTime) achievementAt;

  double get _exportScale {
    final minEdge = math.min(size.x, size.y);
    if (minEdge <= 0) return 1.0;
    return (minEdge / 984.0).clamp(0.25, 2.0);
  }

  Offset get _cornerPadding {
    if (game.headlessExport) {
      final scale = _exportScale;
      return Offset(24.0 * scale, 20.0 * scale);
    }
    return const Offset(8.0, 8.0);
  }

  TextStyle get _primaryStyle {
    final isExport = game.headlessExport;
    final scale = _exportScale;
    return TextStyle(
      color: Colors.white,
      fontSize: isExport ? 28.0 * scale : 14.0,
      height: 1.15,
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: [Shadow(color: Colors.black87, blurRadius: isExport ? 5.0 * scale : 3.0)],
    );
  }

  TextStyle get _breakStyle {
    final isExport = game.headlessExport;
    final scale = _exportScale;
    return TextStyle(
      color: const Color(0xFFFFD54F),
      fontSize: isExport ? 28.0 * scale : 14.0,
      height: 1.15,
      fontWeight: FontWeight.bold,
      fontFeatures: const [FontFeature.tabularFigures()],
      shadows: [Shadow(color: Colors.black87, blurRadius: isExport ? 5.0 * scale : 3.0)],
    );
  }

  TextPainter? _comboPainter;
  TextPainter? _achievementPainter;
  TextPainter? _breakPainter;
  TextPainter? _timePainter;
  int _lastCombo = -1;
  String? _lastAchievementText;
  int _lastBreak = -1;
  int _lastProtectedBreak = -1;
  int _lastCentisecond = -1;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _lastCombo = -1;
    _lastAchievementText = null;
    _lastBreak = -1;
    _lastProtectedBreak = -1;
    _lastCentisecond = -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final snapshot = index.at(game.chartTime);
    final centisecond = (game.chartTime.clamp(0.0, double.infinity) * 100)
        .floor();

    if (snapshot.combo != _lastCombo) {
      _lastCombo = snapshot.combo;
      _comboPainter?.dispose();
      _comboPainter = _textPainter(
        'COMBO ${snapshot.combo} / ${snapshot.totalCombo}',
        _primaryStyle,
      );
    }
    if (game.centerDisplayMode == SimaiCenterDisplayMode.combo &&
        game.showAchievementRate) {
      final achievementText = achievementAt(game.chartTime).toStringAsFixed(4);
      if (achievementText != _lastAchievementText) {
        _lastAchievementText = achievementText;
        _achievementPainter?.dispose();
        _achievementPainter = _textPainter(
          'ACHV $achievementText%',
          _primaryStyle,
        );
      }
    }
    if (snapshot.breakCount != _lastBreak ||
        snapshot.protectedBreakCount != _lastProtectedBreak) {
      _lastBreak = snapshot.breakCount;
      _lastProtectedBreak = snapshot.protectedBreakCount;
      _breakPainter?.dispose();
      _breakPainter = _textPainter(
        'BREAK ${snapshot.breakCount} '
        '(+${snapshot.protectedBreakCount} EX) / ${snapshot.totalBreakCount}',
        _breakStyle,
      );
    }
    if (centisecond != _lastCentisecond) {
      _lastCentisecond = centisecond;
      _timePainter?.dispose();
      _timePainter = _textPainter(_formatTime(centisecond), _primaryStyle);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.showCornerInfo) return;
    final padding = _cornerPadding;
    final topRight = game.centerDisplayMode == SimaiCenterDisplayMode.combo
        ? (game.showAchievementRate ? _achievementPainter : null)
        : _comboPainter;
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
    _comboPainter?.dispose();
    _achievementPainter?.dispose();
    _breakPainter?.dispose();
    _timePainter?.dispose();
    _comboPainter = null;
    _achievementPainter = null;
    _breakPainter = null;
    _timePainter = null;
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
