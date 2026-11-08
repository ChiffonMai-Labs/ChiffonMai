import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../utils/AppTheme.dart';
import 'AnimatedStatMetric.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppDialogs.dart';

/// 单人猜歌共用的本局状态与每日统计，统计项保持两行四列。
class GuessGameStatusPanel extends StatefulWidget {
  const GuessGameStatusPanel({
    super.key,
    required this.roundLabel,
    required this.roundValue,
    required this.roundTotal,
    required this.stats,
    required this.onResetStats,
    required this.isGameOver,
    required this.isWon,
    this.timeLimit = 0,
    this.remainingTime = 0,
    this.answer,
    this.winMessage = '恭喜你猜对了！',
  });

  final String roundLabel;
  final String roundValue;
  final String roundTotal;
  final Map<String, dynamic> stats;
  final Future<void> Function() onResetStats;
  final bool isGameOver;
  final bool isWon;
  final int timeLimit;
  final int remainingTime;
  final String? answer;
  final String winMessage;

  @override
  State<GuessGameStatusPanel> createState() => _GuessGameStatusPanelState();
}

class _GuessGameStatusPanelState extends State<GuessGameStatusPanel> {
  bool _resetting = false;

  num _stat(String key) => widget.stats[key] as num? ?? 0;

  Future<void> _resetStats() async {
    if (_resetting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AppAlertDialog(
        title:  Text(context.l10n.flowResetTodaySStatistics),
        content:  Text(context.l10n.flowClearTodaySCorrectIncorrectGuessesTimes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:  Text(context.l10n.featureCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text(context.l10n.flowReset),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _resetting = true);
    try {
      await widget.onResetStats();
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final remaining = widget.remainingTime
        .clamp(0, widget.timeLimit > 0 ? widget.timeLimit : 0);
    final valueHeight = MediaQuery.textScalerOf(context).scale(32);
    const valueLabelSpacing = 1.0;
    final labelStyle =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final roundCount = int.tryParse(widget.roundValue)?.toDouble();
    final roundTotal = int.tryParse(widget.roundTotal);
    final remainingRatio =
        roundCount != null && roundTotal != null && roundTotal > 0
            ? (roundCount / roundTotal).clamp(0.0, 1.0)
            : null;
    final remainingColor = remainingRatio == null
        ? null
        : remainingRatio < .25
            ? AppColors.errorRed(theme.brightness)
            : remainingRatio < .5
                ? AppColors.warningOrange(theme.brightness)
                : null;
    Widget roundValue(String value) => Text.rich(
          TextSpan(text: value, children: [
            TextSpan(
              text: '/${widget.roundTotal}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.normal,
              ),
            ),
          ]),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600, color: remainingColor),
        );
    Widget metric(String key, String label,
            {int decimals = 0,
            String suffix = '',
            bool active = false,
            bool animateValue = false,
            Widget? labelLeading}) =>
        AnimatedStatMetric(
          key: ValueKey(key),
          value: _stat(key),
          label: label,
          labelLeading: labelLeading,
          labelSpacing: valueLabelSpacing,
          revision: 0,
          fractionDigits: decimals,
          suffix: suffix,
          active: active,
          animateValue: animateValue,
          valueStyle: theme.textTheme.titleMedium,
          trendDuration: const Duration(milliseconds: 2100),
        );
    final metrics = [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedStatMetric(
          key: const ValueKey('remaining'),
          value: roundCount,
          label: widget.roundLabel,
          revision: 0,
          labelSpacing: valueLabelSpacing,
          valueStyle: theme.textTheme.titleMedium,
          valueBuilder: (value) => roundValue(
              roundCount == null ? widget.roundValue : '${value.round()}'),
          semanticValue: '${widget.roundValue}/${widget.roundTotal}',
          increaseIsPositive: true,
          trendDuration: const Duration(milliseconds: 2100),
        ),
        if (widget.timeLimit > 0)
          Text(context.l10n.flowP0SRemaining((remaining).toString()),
              style: labelStyle?.copyWith(
                  color: remaining / widget.timeLimit <= .3
                      ? scheme.error
                      : scheme.onSurfaceVariant)),
      ]),
      metric('correct', context.l10n.flowCorrect2,
          labelLeading: Icon(Icons.check_rounded,
              size: 14, color: AppColors.successGreen(theme.brightness))),
      metric('wrong', '错误',
          labelLeading: Icon(Icons.close_rounded,
              size: 14, color: AppColors.errorRed(theme.brightness))),
      metric('accuracy', context.l10n.flowAccuracy, decimals: 1, suffix: '%', animateValue: true),
      metric('avgTime', context.l10n.flowAverageTime, decimals: 1, suffix: context.l10n.flowS, animateValue: true),
      metric('streak', context.l10n.flowCurrentStreak, active: true),
      metric('bestStreak', context.l10n.flowBestStreak, active: true),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: valueHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: context.l10n.flowResetTodaySStatistics2,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: _resetting ? null : _resetStats,
              icon: const Icon(Icons.restart_alt_rounded, size: 20),
            ),
          ),
        ),
        const SizedBox(height: valueLabelSpacing),
        Text(context.l10n.flowResetStatistics, style: labelStyle),
      ]),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var row = 0; row < 2; row++) ...[
            if (row > 0) const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var column = 0; column < 4; column++) ...[
                if (column > 0) const SizedBox(width: 8),
                Expanded(child: metrics[row * 4 + column]),
              ],
            ]),
          ],
          if (widget.isGameOver) ...[
            const SizedBox(height: 12),
            Text(widget.isWon ? widget.winMessage : context.l10n.flowThisGameHasEnded,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: widget.isWon
                      ? AppColors.successGreen(theme.brightness)
                      : scheme.error,
                  fontWeight: FontWeight.w600,
                )),
            if (!widget.isWon && widget.answer != null) ...[
              const SizedBox(height: 4),
              Text(context.l10n.flowAnswerP0((widget.answer).toString()), style: theme.textTheme.bodyMedium),
            ],
          ],
        ],
      ),
    );
  }
}
