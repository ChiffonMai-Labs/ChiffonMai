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

  static const TextStyle _primaryStyle = TextStyle(
    color: Colors.white,
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
    shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
  );
  static const TextStyle _breakStyle = TextStyle(
    color: Color(0xFFFFD54F),
    fontSize: 14,
    height: 1,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
    shadows: [Shadow(color: Colors.black87, blurRadius: 3)],
  );

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
  }

  @override
  void update(double dt) {
    super.update(dt);
    final snapshot = index.at(game.chartTime);
    final centisecond = (game.chartTime.clamp(0.0, double.infinity) * 100)
        .floor();

    if (snapshot.combo != _lastCombo) {
      _lastCombo = snapshot.combo;
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
      _breakPainter = _textPainter(
        'BREAK ${snapshot.breakCount} '
        '(+${snapshot.protectedBreakCount} EX) / ${snapshot.totalBreakCount}',
        _breakStyle,
      );
    }
    if (centisecond != _lastCentisecond) {
      _lastCentisecond = centisecond;
      _timePainter = _textPainter(_formatTime(centisecond), _primaryStyle);
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.showCornerInfo) return;
    const padding = 8.0;
    final topRight = game.centerDisplayMode == SimaiCenterDisplayMode.combo
        ? (game.showAchievementRate ? _achievementPainter : null)
        : _comboPainter;
    if (topRight != null) {
      topRight.paint(
        canvas,
        Offset(size.x - topRight.width - padding, padding),
      );
    }

    final breakText = _breakPainter;
    if (breakText != null) {
      breakText.paint(
        canvas,
        Offset(padding, size.y - breakText.height - padding),
      );
    }

    final time = _timePainter;
    if (time != null) {
      time.paint(
        canvas,
        Offset(size.x - time.width - padding, size.y - time.height - padding),
      );
    }
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
