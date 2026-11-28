import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/PosterExportUtil.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/ExportStatsUi.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../GainRecommend/ScoreInsights.dart';

/// 成绩分析导出的页签视图类型。
enum ScoreInsightsExportTab { overview, audit, coverage }

/// 成绩深度分析图片导出服务：支持将「成绩全景 / 弱项处方」「B50 边缘巡检」「等级覆盖」
/// 导出为高清海报长图并写入相册 / 公开目录。
class ScoreInsightsExportService {
  ScoreInsightsExportService._();

  static const double _width = 1080;

  static Future<File?> convertToImage(
    BuildContext context, {
    required ScoreInsightsExportTab tab,
    required ScoreInsights score,
    B50Audit? audit,
    String? version,
    String genre = '',
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_insights_${tab.name}',
        subDir: '成绩分析',
        songIds: _collectSongIds(tab: tab, score: score, audit: audit),
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'ScoreInsightsExport',
        builder: (overlayContext) => buildExportWidget(
          overlayContext,
          tab: tab,
          score: score,
          audit: audit,
          version: version,
          genre: genre,
          theme: theme,
          background: background,
        ),
      );

  static Set<String> _collectSongIds({
    required ScoreInsightsExportTab tab,
    required ScoreInsights score,
    required B50Audit? audit,
  }) {
    final ids = <String>{};
    switch (tab) {
      case ScoreInsightsExportTab.overview:
        for (final item in score.weaknesses) {
          for (final chart in item.practiceCharts) {
            ids.add('${chart.songId}');
          }
        }
      case ScoreInsightsExportTab.audit:
        if (audit != null) {
          for (final edge in audit.edges) {
            ids.add('${edge.record.songId}');
          }
        }
      case ScoreInsightsExportTab.coverage:
        break;
    }
    return ids;
  }

  static Widget buildExportWidget(
    BuildContext context, {
    required ScoreInsightsExportTab tab,
    required ScoreInsights score,
    B50Audit? audit,
    String? version,
    String genre = '',
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
  }) {
    return ExportPage(
      theme: theme,
      background: background,
      width: _width,
      padding: const EdgeInsets.all(36),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final caption = switch (tab) {
            ScoreInsightsExportTab.overview => l10n.awmcScoreOverview,
            ScoreInsightsExportTab.audit =>
              '${l10n.awmcB50Audit} · ${version ?? l10n.awmcCurrentConstants}',
            ScoreInsightsExportTab.coverage => genre.isEmpty
                ? l10n.awmcChartCoverage
                : '${l10n.awmcChartCoverage} · $genre',
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportPosterHeader(
                title: l10n.awmcScoreInsights,
                caption: caption,
                scale: 0.65,
              ),
              const SizedBox(height: 28),
              switch (tab) {
                ScoreInsightsExportTab.overview =>
                  _buildOverviewSection(context, score),
                ScoreInsightsExportTab.audit =>
                  _buildAuditSection(context, audit, version),
                ScoreInsightsExportTab.coverage =>
                  _buildCoverageSection(context, score, genre),
              },
            ],
          );
        },
      ),
    );
  }

  static Widget _buildOverviewSection(
      BuildContext context, ScoreInsights score) {
    final l10n = context.l10n;
    final c = ExportPalette.of(context);
    final total = score.coverage.fold<int>(0, (sum, row) => sum + row.total);
    final played = score.coverage.fold<int>(0, (sum, row) => sum + row.played);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExportStatsPanel(
          child: ExportUniformStatRow(
            children: [
              ExportHeroBlock.compact(
                label: l10n.awmcChartCoverage,
                value: total > 0
                    ? '${(played / total * 100).toStringAsFixed(1)}%'
                    : '0.0%',
                caption: '$played / $total',
              ),
              ExportStatBlock.compact(
                label: '已玩 / 总数',
                value: '$played / $total',
                caption: '未玩 ${total - played}',
              ),
              ExportStatBlock.compact(
                label: 'SSS / SSS+',
                value: '${score.sss}',
                caption: total > 0
                    ? '${(score.sss / total * 100).toStringAsFixed(1)}%'
                    : null,
              ),
              ExportStatBlock.compact(
                label: 'FC / AP',
                value: '${score.fullCombo}',
                caption: total > 0
                    ? '${(score.fullCombo / total * 100).toStringAsFixed(1)}%'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ExportSectionTitle(l10n.awmcWeaknessPrescription),
        const SizedBox(height: 14),
        if (score.weaknesses.isEmpty)
          ExportStatsPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.awmcWeaknessNoData,
                style: TextStyle(fontSize: 20, color: c.muted),
              ),
            ),
          )
        else
          for (final (index, item) in score.weaknesses.indexed) ...[
            if (index > 0) const SizedBox(height: 14),
            ExportStatsPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.tag,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: c.ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (item.delta < 0 ? c.negative : c.positive)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${item.delta >= 0 ? '+' : ''}${item.delta.toStringAsFixed(2)}%',
                          style: AppTheme.number(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: item.delta < 0 ? c.negative : c.positive,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.awmcWeaknessStats(
                      '${item.playedCount}',
                      item.avgAchievement.toStringAsFixed(2),
                      '${item.sssCount}',
                    ),
                    style: TextStyle(fontSize: 18, color: c.muted),
                  ),
                  if (item.practiceCharts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final (i, chart) in item.practiceCharts.indexed) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.inset,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CoverUtil.buildCoverWidgetWithContext(
                                  context, '${chart.songId}', 48),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chart.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      color: c.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      ChartDifficultyBadge(
                                        levelIndex: chart.levelIndex,
                                        songId: '${chart.songId}',
                                        fontSize: 12,
                                      ),
                                      Text(
                                        '${chart.ds}',
                                        style: AppTheme.number(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: c.muted,
                                        ),
                                      ),
                                      Text(
                                        chart.achievements == null
                                            ? l10n.awmcUnplayed
                                            : '${chart.achievements!.toStringAsFixed(4)}%',
                                        style: AppTheme.number(
                                          fontSize: 16,
                                          color: c.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
      ],
    );
  }

  static Widget _buildAuditSection(
      BuildContext context, B50Audit? audit, String? version) {
    final l10n = context.l10n;
    final c = ExportPalette.of(context);
    if (audit == null) {
      return ExportStatsPanel(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(l10n.flowNoData,
                style: TextStyle(fontSize: 20, color: c.muted)),
          ),
        ),
      );
    }

    final b35Edges =
        audit.edges.where((e) => e.record.isNew != true).toList();
    final b15Edges =
        audit.edges.where((e) => e.record.isNew == true).toList();

    Widget edgeGroup(String title, List<B50Edge> edges) {
      if (edges.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExportSectionTitle('$title | ${edges.length}'),
          const SizedBox(height: 12),
          ExportStatsPanel(
            child: Column(
              children: [
                for (final (index, edge) in edges.indexed) ...[
                  if (index > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: c.cardBorder),
                    ),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CoverUtil.buildCoverWidgetWithContext(
                            context, '${edge.record.songId}', 52),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              edge.record.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ChartDifficultyBadge(
                                  levelIndex: edge.record.levelIndex,
                                  songId: '${edge.record.songId}',
                                  fontSize: 12,
                                ),
                                Text(
                                  '${edge.record.ds}',
                                  style: AppTheme.number(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: c.muted,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: edge.selected
                                        ? c.positive.withValues(alpha: 0.14)
                                        : c.inset,
                                    borderRadius: BorderRadius.circular(
                                        AppDesignTokens.radiusSmall),
                                  ),
                                  child: Text(
                                    edge.selected
                                        ? l10n.awmcB50InList
                                        : l10n.awmcRaToEnter('${edge.raNeeded}'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          edge.selected ? c.positive : c.muted,
                                    ),
                                  ),
                                ),
                                if (edge.target != null)
                                  Text(
                                    '${edge.target!.toStringAsFixed(4)}% · +${edge.gain}',
                                    style: AppTheme.number(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: c.accent,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${edge.record.ra}',
                            style: AppTheme.number(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                          Text(
                            '${edge.record.achievements.toStringAsFixed(4)}%',
                            style: AppTheme.number(
                              fontSize: 15,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExportStatsPanel(
          child: ExportUniformStatRow(
            children: [
              ExportHeroBlock.compact(
                label: 'B50 Rating',
                value: '${audit.baseline.raSum}',
                caption: version ?? l10n.awmcCurrentConstants,
              ),
              if (version != null)
                ExportStatBlock.compact(
                  label: 'Δ Rating',
                  value:
                      '${audit.ratingDifference > 0 ? '+' : ''}${audit.ratingDifference}',
                  caption: audit.ratingDifference == 0
                      ? '定数持平'
                      : (audit.ratingDifference > 0 ? '定数上升' : '定数下降'),
                  positive: audit.ratingDifference == 0
                      ? null
                      : audit.ratingDifference > 0,
                ),
              ExportStatBlock.compact(
                label: 'B35 / B15 底线',
                value:
                    '${audit.baseline.floor(false)} / ${audit.baseline.floor(true)}',
                caption: '入榜门槛',
              ),
              ExportStatBlock.compact(
                label: '边缘曲目',
                value: '${audit.edges.length}',
                caption: 'B35 ${b35Edges.length} · B15 ${b15Edges.length}',
              ),
            ],
          ),
        ),
        if (b35Edges.isNotEmpty) ...[
          const SizedBox(height: 24),
          edgeGroup('B35', b35Edges),
        ],
        if (b15Edges.isNotEmpty) ...[
          const SizedBox(height: 24),
          edgeGroup('B15', b15Edges),
        ],
      ],
    );
  }

  static Widget _buildCoverageSection(
      BuildContext context, ScoreInsights score, String genre) {
    final l10n = context.l10n;
    final c = ExportPalette.of(context);
    final rows = score.coverageByGenre[genre] ?? score.coverage;
    final total = rows.fold<int>(0, (sum, row) => sum + row.total);
    final played = rows.fold<int>(0, (sum, row) => sum + row.played);
    final overallPct = total > 0 ? played / total * 100 : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExportStatsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportUniformStatRow(
                children: [
                  ExportHeroBlock.compact(
                    label: genre.isEmpty ? l10n.awmcChartCoverage : genre,
                    value: '${overallPct.toStringAsFixed(1)}%',
                    caption: '$played / $total',
                  ),
                  ExportStatBlock.compact(
                    label: '已玩 / 总数',
                    value: '$played / $total',
                    caption: '未玩 ${total - played}',
                  ),
                  ExportStatBlock.compact(
                    label: 'SSS / SSS+',
                    value: '${score.sss}',
                    caption: total > 0
                        ? '${(score.sss / total * 100).toStringAsFixed(1)}%'
                        : null,
                  ),
                  ExportStatBlock.compact(
                    label: 'FC / AP',
                    value: '${score.fullCombo}',
                    caption: total > 0
                        ? '${(score.fullCombo / total * 100).toStringAsFixed(1)}%'
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SmoothLinearProgressIndicator(
                value: total > 0 ? played / total : 0.0,
                minHeight: 10,
                color: c.accent,
                backgroundColor: c.track,
                animate: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ExportSectionTitle(l10n.awmcChartCoverage),
        const SizedBox(height: 12),
        ExportStatsPanel(
          child: Column(
            children: [
              for (final (index, item) in rows.indexed) ...[
                if (index > 0) const SizedBox(height: 12),
                Builder(builder: (context) {
                  final pct = item.total > 0 ? item.played / item.total : 0.0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.level,
                            style: AppTheme.number(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: c.ink,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${item.played} / ${item.total}',
                            style: AppTheme.number(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: c.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '(${(pct * 100).toStringAsFixed(0)}%)',
                            style: AppTheme.number(fontSize: 18, color: c.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SmoothLinearProgressIndicator(
                        value: pct,
                        minHeight: 8,
                        backgroundColor: c.track,
                        color: c.accent,
                        animate: false,
                      ),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
