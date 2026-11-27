import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../gameplay/gameplay_models.dart';
import '../../gameplay/gameplay_session.dart';
import '../simai_game.dart';
import 'judgement_display.dart';
import 'judgement_feedback_renderer.dart';

class GameplayHudComponent extends PositionComponent
    with HasGameReference<SimaiGame> {
  GameplayHudComponent(this.session);

  final SimaiGameplaySession session;
  final SimaiJudgementFeedbackRenderer _feedbackRenderer =
      SimaiJudgementFeedbackRenderer();

  // 中心与右上角显示仅监听 scoreRevision 与模式/尺寸变化，并按实际文案差量重建。
  int _lastScoreRevision = -1;
  double _lastDimension = -1;
  SimaiGameplayCenterDisplayMode? _lastCenterMode;
  SimaiGameplayCenterDisplayMode? _lastTopRightMode;
  int _lastAutoAssistNotes = -1;
  String? _lastCenterValueText;
  String? _lastCenterLabelText;
  double _lastCenterValueSize = -1;
  String? _lastTopRightText;
  TextPainter? _centerValuePainter;
  TextPainter? _centerLabelPainter;
  TextPainter? _topRightPainter;
  TextPainter? _autoPainter;

  static const TextStyle _hudStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w800,
    fontSize: 17,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
  );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _lastDimension = -1;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final dimension = min(size.x, size.y);
    final scoreRevision = session.scoreRevision;
    final mode = session.settings.centerDisplayMode;
    final topRightMode = session.settings.topRightDisplayMode;
    final autoAssistNotes = session.summary.autoAssistNotes;
    if (_lastScoreRevision == scoreRevision &&
        _lastDimension == dimension &&
        _lastCenterMode == mode &&
        _lastTopRightMode == topRightMode &&
        _lastAutoAssistNotes == autoAssistNotes) {
      return;
    }
    final bool autoAssistChanged = _lastAutoAssistNotes != autoAssistNotes;
    _lastScoreRevision = scoreRevision;
    _lastDimension = dimension;
    _lastCenterMode = mode;
    _lastTopRightMode = topRightMode;
    _lastAutoAssistNotes = autoAssistNotes;
    _rebuildCenterDisplay(dimension);
    _rebuildTopRightDisplay(topRightMode);

    if (autoAssistChanged) {
      _autoPainter?.dispose();
      if (autoAssistNotes > 0) {
        _autoPainter = _text(
          'AUTO ASSIST $autoAssistNotes',
          _hudStyle.copyWith(color: const Color(0xFF80CBC4), fontSize: 12),
        );
      } else {
        _autoPainter = null;
      }
    }
  }

  /// 格式化 4 位小数百分比，避免浮点误差产生 `-0.0000%`。
  static String _formatPercent(double value) {
    final normalized = value.abs() < 0.00005 ? 0.0 : value;
    return '${normalized.toStringAsFixed(4)}%';
  }

  void _rebuildCenterDisplay(double dimension) {
    final mode = session.settings.centerDisplayMode;
    if (mode == SimaiGameplayCenterDisplayMode.none) {
      _centerValuePainter?.dispose();
      _centerLabelPainter?.dispose();
      _centerValuePainter = null;
      _centerLabelPainter = null;
      _lastCenterValueText = null;
      _lastCenterLabelText = null;
      _lastCenterValueSize = -1;
      return;
    }
    final value = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd => _formatPercent(
        session.achievement,
      ),
      SimaiGameplayCenterDisplayMode.achievement100Plus => _formatPercent(
        session.achievement100Plus,
      ),
      SimaiGameplayCenterDisplayMode.achievement101Subtract => _formatPercent(
        session.achievement101Remaining,
      ),
      SimaiGameplayCenterDisplayMode.dxScoreAdd => session.dxScore.toString(),
      SimaiGameplayCenterDisplayMode.dxScoreSubtract =>
        session.remainingDxScore.toString(),
      SimaiGameplayCenterDisplayMode.dxStars => session.dxStarBonusText,
      SimaiGameplayCenterDisplayMode.combo => session.currentCombo.toString(),
      SimaiGameplayCenterDisplayMode.overS => _formatPercent(
        session.achievementOverS,
      ),
      SimaiGameplayCenterDisplayMode.overSS => _formatPercent(
        session.achievementOverSS,
      ),
      SimaiGameplayCenterDisplayMode.overSSS => _formatPercent(
        session.achievementOverSSS,
      ),
      SimaiGameplayCenterDisplayMode.none => '',
    };
    final label = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd ||
      SimaiGameplayCenterDisplayMode.achievement100Plus ||
      SimaiGameplayCenterDisplayMode.achievement101Subtract => 'ACHIEVEMENT',
      SimaiGameplayCenterDisplayMode.dxScoreAdd ||
      SimaiGameplayCenterDisplayMode.dxScoreSubtract => 'DX SCORE',
      SimaiGameplayCenterDisplayMode.dxStars => 'DX STAR',
      SimaiGameplayCenterDisplayMode.combo => 'COMBO',
      SimaiGameplayCenterDisplayMode.overS => 'S BORDER',
      SimaiGameplayCenterDisplayMode.overSS => 'SS BORDER',
      SimaiGameplayCenterDisplayMode.overSSS => 'SSS BORDER',
      SimaiGameplayCenterDisplayMode.none => '',
    };
    final valueSize = (dimension * 0.065).clamp(22.0, 42.0).toDouble();
    final bool sizeChanged = valueSize != _lastCenterValueSize;
    if (sizeChanged || value != _lastCenterValueText || _centerValuePainter == null) {
      _centerValuePainter?.dispose();
      _centerValuePainter = _text(
        value,
        _hudStyle.copyWith(
          fontSize: valueSize,
          color: Colors.white.withValues(alpha: 0.88),
          letterSpacing: -0.5,
        ),
      );
      _lastCenterValueText = value;
    }
    if (sizeChanged || label != _lastCenterLabelText || _centerLabelPainter == null) {
      _centerLabelPainter?.dispose();
      _centerLabelPainter = _text(
        label,
        _hudStyle.copyWith(
          fontSize: (valueSize * 0.34).clamp(9.0, 13.0).toDouble(),
          color: Colors.white.withValues(alpha: 0.62),
          letterSpacing: 1.2,
        ),
      );
      _lastCenterLabelText = label;
    }
    _lastCenterValueSize = valueSize;
  }

  /// 构建游玩态右上角 11 模式统计文本。
  void _rebuildTopRightDisplay(SimaiGameplayCenterDisplayMode mode) {
    if (mode == SimaiGameplayCenterDisplayMode.none) {
      if (_topRightPainter != null || _lastTopRightText != null) {
        _topRightPainter?.dispose();
        _topRightPainter = null;
        _lastTopRightText = null;
      }
      return;
    }
    final text = switch (mode) {
      SimaiGameplayCenterDisplayMode.achievementAdd =>
        'ACHV ${_formatPercent(session.achievement)}',
      SimaiGameplayCenterDisplayMode.achievement100Plus =>
        'ACHV ${_formatPercent(session.achievement100Plus)}',
      SimaiGameplayCenterDisplayMode.achievement101Subtract =>
        'ACHV ${_formatPercent(session.achievement101Remaining)}',
      SimaiGameplayCenterDisplayMode.dxScoreAdd =>
        'DX ${session.dxScore} / ${session.totalDxScore}',
      SimaiGameplayCenterDisplayMode.dxScoreSubtract =>
        'DX ${session.remainingDxScore}',
      SimaiGameplayCenterDisplayMode.dxStars => session.dxStarBonusText,
      SimaiGameplayCenterDisplayMode.combo =>
        'COMBO ${session.currentCombo} / ${session.totalScoringNotes}',
      SimaiGameplayCenterDisplayMode.overS =>
        'S ${_formatPercent(session.achievementOverS)}',
      SimaiGameplayCenterDisplayMode.overSS =>
        'SS ${_formatPercent(session.achievementOverSS)}',
      SimaiGameplayCenterDisplayMode.overSSS =>
        'SSS ${_formatPercent(session.achievementOverSSS)}',
      SimaiGameplayCenterDisplayMode.none => '',
    };
    if (text.isEmpty) {
      if (_topRightPainter != null || _lastTopRightText != null) {
        _topRightPainter?.dispose();
        _topRightPainter = null;
        _lastTopRightText = null;
      }
      return;
    }
    if (text == _lastTopRightText && _topRightPainter != null) return;
    _lastTopRightText = text;
    _topRightPainter?.dispose();
    _topRightPainter = _text(
      text,
      _hudStyle.copyWith(fontSize: 14, color: Colors.white),
    );
  }

  @override
  void onRemove() {
    _centerValuePainter?.dispose();
    _centerLabelPainter?.dispose();
    _topRightPainter?.dispose();
    _autoPainter?.dispose();
    _centerValuePainter = null;
    _centerLabelPainter = null;
    _topRightPainter = null;
    _autoPainter = null;
    _lastCenterValueText = null;
    _lastCenterLabelText = null;
    _lastCenterValueSize = -1;
    _lastTopRightText = null;
    _feedbackRenderer.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    _paintCenterDisplay(canvas);

    final topRight = _topRightPainter;
    var autoTop = 12.0;
    if (topRight != null) {
      topRight.paint(canvas, Offset(size.x - topRight.width - 12, 12));
      autoTop = 12.0 + topRight.height + 4.0;
    }

    final auto = _autoPainter;
    if (auto != null) {
      auto.paint(canvas, Offset(size.x - auto.width - 12, autoTop));
    }

    _feedbackRenderer.paintRecords(
      canvas,
      game: game,
      records: session.recentFeedback(
        game.chartTime,
        duration: simaiJudgementFeedbackDuration,
      ),
      mode: session.settings.judgementDisplayMode,
      skipAuto: true,
    );
  }

  void _paintCenterDisplay(Canvas canvas) {
    final value = _centerValuePainter;
    final label = _centerLabelPainter;
    if (value == null || label == null) return;
    final valueOffset = Offset(
      (size.x - value.width) / 2,
      (size.y - value.height) / 2,
    );
    final labelOffset = Offset(
      (size.x - label.width) / 2,
      valueOffset.dy - label.height - max(2.0, value.height * 0.05),
    );
    label.paint(canvas, labelOffset);
    value.paint(canvas, valueOffset);
  }

  static TextPainter _text(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }
}
