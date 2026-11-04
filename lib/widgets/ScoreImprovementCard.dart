import 'package:flutter/material.dart';

import '../service/History/ScoreImprovementCore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';
import 'AppUi.dart';

/// 完整展示当前谱面信息，并将各项成绩逐行与当日初值对照。
class ScoreImprovementCard extends StatelessWidget {
  const ScoreImprovementCard({super.key, required this.entry, this.onOpen});

  final DailyScoreImprovement entry;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final score = entry.after;
    final songId = score.songId.toString();
    final statusColor = switch (entry.status) {
      ScoreChangeStatus.improvement => AppColors.successForeground(brightness),
      ScoreChangeStatus.regression => AppColors.errorRed(brightness),
      ScoreChangeStatus.unchanged => colors.onSurfaceVariant,
      ScoreChangeStatus.mixed => colors.onSurface,
    };
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, songId, 64),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SongTypeBadge(songId: songId, type: score.type),
                        ChartDifficultyBadge(
                            levelIndex: score.levelIndex, songId: songId),
                        Text(
                          ' ${score.ds.toStringAsFixed(1)}',
                          style: AppTheme.number(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        Text(
                          ' #$songId',
                          style: AppTheme.number(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onOpen != null)
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: colors.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.13),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusPill),
                ),
                child: Text(
                  entry.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              if (entry.isNewChart)
                Text('首次记录',
                    style: TextStyle(
                        fontSize: 12, color: colors.onSurfaceVariant)),
              Text(
                '${_time(entry.firstAtMs)}'
                '${entry.changeCount > 1 ? '–${_time(entry.lastAtMs)} · ${entry.changeCount} 次变化' : ' 记录'}',
                style: AppTheme.number(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Column(children: [
              for (final (index, metric) in ImprovementMetric.values.indexed)
                _metricRow(context, metric, showDivider: index > 0),
            ]),
          ),
          if (entry.changeCount > 1 &&
              !ImprovementMetric.values.any(entry.changed))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('日内成绩有过变化，最新值已回到当日初值。',
                  style:
                      TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
            ),
        ],
      ),
    );
  }

  Widget _metricRow(BuildContext context, ImprovementMetric metric,
      {required bool showDivider}) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final changed = entry.changed(metric);
    final direction =
        entry.before == null ? 1 : metric.compare(entry.before!, entry.after);
    // 语义色仅适配明暗，不跟随用户选择的主题色改变色相。
    final emphasis = direction < 0
        ? AppColors.errorRed(brightness)
        : direction > 0
            ? AppColors.successForeground(brightness)
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
      // 星级色放在白底上看不见，用实心徽章。
      if (metric == ImprovementMetric.stars && score?.stars != null) {
        return StarBadge(stars: score!.stars!, fontSize: 11);
      }
      return Text(
        display(score),
        style: AppTheme.number(
          fontSize: 13,
          fontWeight: !isBefore && changed ? FontWeight.w700 : FontWeight.w500,
          color: isBefore
              ? colors.onSurfaceVariant
              : changed
                  ? emphasis
                  : colors.onSurface,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: AppSurfaces.hairline(context)))
              : null),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(metric.label,
                  maxLines: 1,
                  softWrap: false,
                  style:
                      TextStyle(fontSize: 12, color: colors.onSurfaceVariant))),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (changed) ...[
                  value(entry.before, isBefore: true),
                  Icon(Icons.arrow_right_alt_rounded,
                      size: 16, color: colors.onSurfaceVariant),
                ],
                value(entry.after, isBefore: false),
                if (!changed)
                  Text(metric.value(entry.after) == null ? '暂无数据' : '无变化',
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant)),
                if (changed && entry.before != null)
                  Text(_delta(metric, direction),
                      style: AppTheme.number(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: emphasis)),
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
