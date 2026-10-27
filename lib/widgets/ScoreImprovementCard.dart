import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';

import '../service/History/ScoreImprovementCore.dart';
import '../utils/AppTheme.dart';
import '../utils/ColorUtil.dart';
import '../utils/CoverUtil.dart';
import 'B50GameCardWidget.dart';

/// 完整展示当前谱面信息，并将各项成绩逐行与当日初值对照。
class ScoreImprovementCard extends StatelessWidget {
  const ScoreImprovementCard({super.key, required this.entry, this.onOpen});

  final DailyScoreImprovement entry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final score = entry.after;
    // 白底 B50 的固定标签色仅用于浅色，深色使用亮蓝、亮橙和宴谱粉色。
    final typeLabel = theme.brightness == Brightness.dark
        ? Text(
            score.isUtage ? 'UT' : (score.type == 'DX' ? 'DX' : 'ST'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
              color: score.isUtage
                  ? AppColors.utageAccent(brightness: theme.brightness)
                  : score.type == 'DX'
                      ? AppColors.warningOrange(theme.brightness)
                      : AppColors.linkBlue(theme.brightness),
            ),
          )
        : B50GameCardWidget.buildTypeChip(
            score.isUtage, score.type == 'DX', 12);
    final accent = score.isUtage
        ? AppColors.utageAccent(brightness: theme.brightness)
        : AppColors.difficultyForegroundByIndex(score.levelIndex,
            brightness: theme.brightness);
    final statusColor = switch (entry.status) {
      ScoreChangeStatus.improvement =>
        AppColors.successForeground(theme.brightness),
      ScoreChangeStatus.regression => AppColors.errorRed(theme.brightness),
      ScoreChangeStatus.unchanged => colors.onSurfaceVariant,
      ScoreChangeStatus.mixed => colors.onSurface,
    };
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 3, child: ColoredBox(color: accent)),
          Material(
            color: accent.withValues(alpha: .07),
            child: InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CoverUtil.buildCoverWidgetWithContext(
                          context, score.songId.toString(), 66),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(score.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(ImprovementMetric.achievement.display(score),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ])),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('#${score.songId}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant)),
                              typeLabel,
                              Text(
                                  '${ChartDifficulty.labelOf(score.levelIndex, isUtage: score.isUtage)}'
                                  ' ${score.level}  定数 ${score.ds.toStringAsFixed(1)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onOpen != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 20, color: colors.onSurfaceVariant),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(entry.status.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor, fontWeight: FontWeight.w700)),
                if (entry.isNewChart)
                  Text('首次记录',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                Text(
                    '${_time(entry.firstAtMs)}'
                    '${entry.changeCount > 1 ? '–${_time(entry.lastAtMs)} · ${entry.changeCount} 次变化' : ' 记录'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Column(children: [
              for (final metric in ImprovementMetric.values)
                _metricRow(context, metric),
              if (entry.changeCount > 1 &&
                  !ImprovementMetric.values.any(entry.changed))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('日内成绩有过变化，最新值已回到当日初值。',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(BuildContext context, ImprovementMetric metric) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final changed = entry.changed(metric);
    final direction =
        entry.before == null ? 1 : metric.compare(entry.before!, entry.after);
    // 语义色仅适配明暗，不跟随用户选择的主题色改变色相。
    final emphasis = direction < 0
        ? AppColors.errorRed(theme.brightness)
        : direction > 0
            ? AppColors.successForeground(theme.brightness)
            : colors.onSurfaceVariant;
    String display(ImprovementScore? score) {
      if (metric == ImprovementMetric.dxScore &&
          score?.dxScore != null &&
          score!.maxDxScore > 0) {
        return '${score.dxScore} / ${score.maxDxScore}';
      }
      return metric.display(score);
    }

    Widget value(ImprovementScore? score, {required bool isBefore}) {
      final text = display(score);
      final style = theme.textTheme.bodySmall?.copyWith(
          color: isBefore
              ? colors.onSurfaceVariant
              : changed
                  ? emphasis
                  : colors.onSurface,
          fontWeight: !isBefore && changed ? FontWeight.w700 : FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()]);
      if (score?.stars != null && metric == ImprovementMetric.stars) {
        return Text(text,
            style: style?.copyWith(
                color: score!.stars == '✦0'
                    ? style.color
                    : ColorUtil.getStarsColor(score.stars!)));
      }
      return Text(text, style: style);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: .55),
                  width: .5))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(metric.label,
                  maxLines: 1,
                  softWrap: false,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant))),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (changed) ...[
                  value(entry.before, isBefore: true),
                  Icon(Icons.arrow_right_alt,
                      size: 16, color: colors.onSurfaceVariant),
                ],
                value(entry.after, isBefore: false),
                if (!changed)
                  Text(metric.value(entry.after) == null ? '暂无数据' : '无变化',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant)),
                if (changed && entry.before != null)
                  Text(_delta(metric, direction),
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: emphasis, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _delta(ImprovementMetric metric, int direction) {
    final before = entry.before!;
    if (metric == ImprovementMetric.achievement) {
      final delta = entry.after.achievement - before.achievement;
      return '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(4)}%';
    }
    if (metric == ImprovementMetric.dxRate) {
      final delta = (entry.after.dxRate! - before.dxRate!) * 100;
      return '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(2)}%';
    }
    if (metric == ImprovementMetric.dxScore ||
        metric == ImprovementMetric.rating) {
      final delta =
          (metric.value(entry.after) as num) - (metric.value(before) as num);
      return '${delta > 0 ? '+' : ''}$delta';
    }
    return direction > 0
        ? '提升'
        : direction < 0
            ? '回退'
            : '变化';
  }

  static String _time(int atMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(atMs);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
