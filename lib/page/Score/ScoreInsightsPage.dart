import 'package:flutter/material.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../service/GainRecommend/ScoreInsights.dart';
import '../../service/Score/ScoreInsightsExportService.dart';
import '../../service/System/BackgroundExportService.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/ExportQualitySelector.dart';
import '../../utils/ImageEncodeUtil.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../song_info/SongInfoPage.dart';

import 'package:my_first_flutter_app/widgets/ExpressiveLoadingIndicator.dart';
enum _View { overview, audit, coverage }

/// 成绩深度分析页：成绩全景、弱项处方、B50 边缘巡检与等级覆盖。
class ScoreInsightsPage extends StatefulWidget {
  const ScoreInsightsPage({super.key});

  @override
  State<ScoreInsightsPage> createState() => _ScoreInsightsPageState();
}

class _ScoreInsightsPageState extends State<ScoreInsightsPage> {
  late Future<ScoreInsights?> _source = ScoreInsights.load();
  Future<B50Audit>? _audit;
  _View _view = _View.overview;
  String? _version;
  String _genre = '';
  bool _exporting = false;

  void _showChart(int songId, int levelIndex) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongInfoPage(
          songId: '$songId',
          initialLevelIndex: levelIndex,
        ),
      ),
    );
  }

  void _selectVersion(ScoreInsights score, String? version) {
    setState(() {
      _version = version;
      _audit = score.audit(version);
    });
  }

  Future<void> _exportImage(ScoreInsights score, {B50Audit? audit}) async {
    if (_exporting) return;
    final l10n = context.l10n;
    final view = _view;
    final version = _version;
    final genre = _genre;
    B50Audit? resolvedAudit = audit;
    if (view == _View.audit && resolvedAudit == null) {
      setState(() => _exporting = true);
      try {
        resolvedAudit = await (_audit ??= score.audit(version));
      } catch (_) {
        if (mounted) {
          AppToast.show(l10n.flowExportFailedTryAgain, tone: AppToastTone.error);
          setState(() => _exporting = false);
        }
        return;
      }
      if (!mounted) return;
      setState(() => _exporting = false);
    }

    final tab = switch (view) {
      _View.overview => ScoreInsightsExportTab.overview,
      _View.audit => ScoreInsightsExportTab.audit,
      _View.coverage => ScoreInsightsExportTab.coverage,
    };
    final label = switch (view) {
      _View.overview => '${l10n.awmcScoreInsights} · ${l10n.awmcScoreOverview}',
      _View.audit => '${l10n.awmcScoreInsights} · ${l10n.awmcB50Audit}',
      _View.coverage => '${l10n.awmcScoreInsights} · ${l10n.awmcChartCoverage}',
    };
    final estimatedCount = switch (view) {
      _View.overview => 16,
      _View.audit => (resolvedAudit?.edges.length ?? 12).clamp(6, 30),
      _View.coverage => 18,
    };
    final quality = await ExportQualitySelector.show(
      context,
      estimatedPngSize: ImageEncodeUtil.estimatePngSize(songCount: estimatedCount),
      exportingLabel: label,
      enableBest50Background: true,
      previewBuilder: (previewContext, previewQuality) =>
          ScoreInsightsExportService.buildExportWidget(
        previewContext,
        tab: tab,
        score: score,
        audit: resolvedAudit,
        version: version,
        genre: genre,
        theme: previewQuality.theme,
        background: previewQuality.background,
      ),
    );
    if (quality == null || !mounted) return;
    BackgroundExport.run(
      label: label,
      task: (exportContext) => ScoreInsightsExportService.convertToImage(
        exportContext,
        tab: tab,
        score: score,
        audit: resolvedAudit,
        version: version,
        genre: genre,
        theme: quality.theme,
        background: quality.background,
        jpegQuality: quality.jpegQuality,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder(
      future: _source,
      builder: (context, snapshot) {
        final score = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        return BackgroundPageScaffold(
          title: l10n.awmcScoreInsights,
          actions: [
            if (score != null)
              IconButton(
                onPressed: _exporting ? null : () => _exportImage(score),
                tooltip: l10n.flowExport,
                icon: const Icon(Icons.ios_share, size: 20),
              ),
          ],
          contentPadding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: snapshot.connectionState != ConnectionState.done
              ? const Center(child: ExpressiveLoadingIndicator.contained(size: 48))
              : score == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDesignTokens.gutter),
                        child: AppCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.insights_rounded,
                                  size: 40, color: scheme.onSurfaceVariant),
                              const SizedBox(height: 10),
                              Text(
                                l10n.awmcInsightsNoCache,
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.tonalIcon(
                                onPressed: () => setState(() {
                                  _source = ScoreInsights.load();
                                  _audit = null;
                                }),
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(l10n.flowRetry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppDesignTokens.gutter,
                              4,
                              AppDesignTokens.gutter,
                              8),
                          child: AnimatedChoiceBar<_View>(
                            values: _View.values,
                            value: _view,
                            label: (view) => switch (view) {
                              _View.overview => l10n.awmcScoreOverview,
                              _View.audit => l10n.awmcB50Audit,
                              _View.coverage => l10n.awmcChartCoverage,
                            },
                            onChanged: (view) => setState(() {
                              _view = view;
                              if (view == _View.audit) {
                                _audit ??= score.audit(_version);
                              }
                            }),
                          ),
                        ),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: AppDesignTokens.motion(
                                context, AppDesignTokens.mediumMotion),
                            child: KeyedSubtree(
                              key: ValueKey<_View>(_view),
                              child: switch (_view) {
                                _View.overview => _overview(score),
                                _View.audit => _auditView(score),
                                _View.coverage => _coverage(score),
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _overview(ScoreInsights score) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final count = score.coverage.fold<int>(0, (sum, row) => sum + row.total);
    final played = score.coverage.fold<int>(0, (sum, row) => sum + row.played);

    Widget statCell({
      required String label,
      required String value,
      VoidCallback? onTap,
    }) {
      final child = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: StatTile(centered: true, label: label, value: value),
      );
      return Expanded(
        child: Material(
          color: AppSurfaces.inset(context),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          ),
          child: onTap != null
              ? InkWell(onTap: onTap, child: child)
              : child,
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(
                title: l10n.awmcScoreOverview,
                padding: const EdgeInsets.only(bottom: 12),
              ),
              Row(
                children: [
                  statCell(
                    label: l10n.awmcChartCoverage,
                    value: '$played / $count',
                    onTap: () => setState(() => _view = _View.coverage),
                  ),
                  const SizedBox(width: 8),
                  statCell(label: 'SSS / SSS+', value: '${score.sss}'),
                  const SizedBox(width: 8),
                  statCell(label: 'FC / AP', value: '${score.fullCombo}'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l10n.awmcLocalScoreSnapshot,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDesignTokens.sectionGap),
        AppSectionHeader(
          title: l10n.awmcWeaknessPrescription,
          subtitle: l10n.awmcWeaknessSubtitle,
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        ),
        if (score.weaknesses.isEmpty)
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.awmcWeaknessNoData,
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final (index, item) in score.weaknesses.indexed) ...[
            if (index > 0) const SizedBox(height: AppDesignTokens.cardGap),
            _buildWeaknessCard(context, item, brightness),
          ],
      ],
    );
  }

  Widget _buildWeaknessCard(
      BuildContext context, WeaknessTagItem item, Brightness brightness) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final deltaColor = item.delta < 0
        ? AppColors.errorRed(brightness)
        : AppColors.successGreen(brightness);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.tag,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              AppBadge(
                text:
                    '${item.delta >= 0 ? '+' : ''}${item.delta.toStringAsFixed(2)}%',
                background: deltaColor.withValues(alpha: 0.14),
                foreground: deltaColor,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.awmcWeaknessStats(
              '${item.playedCount}',
              item.avgAchievement.toStringAsFixed(2),
              '${item.sssCount}',
            ),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          if (item.practiceCharts.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final (i, chart) in item.practiceCharts.indexed) ...[
              if (i > 0) const SizedBox(height: 6),
              Material(
                color: AppSurfaces.inset(context),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                child: InkWell(
                  onTap: () => _showChart(chart.songId, chart.levelIndex),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CoverUtil.buildCoverWidgetWithContext(
                              context, '${chart.songId}', 36),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chart.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ChartDifficultyBadge(
                                    levelIndex: chart.levelIndex,
                                    songId: '${chart.songId}',
                                  ),
                                  Text(
                                    '${chart.ds}',
                                    style: AppTheme.number(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    chart.achievements == null
                                        ? l10n.awmcUnplayed
                                        : '${chart.achievements!.toStringAsFixed(4)}%',
                                    style: AppTheme.number(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _auditView(ScoreInsights score) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final version = _version;
    return FutureBuilder(
      future: _audit,
      builder: (context, snapshot) {
        final result = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: version ?? '',
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.awmcAuditConstants,
                      filled: true,
                      fillColor: AppSurfaces.inset(context),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ).insetLabel(context),
                    items: [
                      DropdownMenuItem(
                          value: '', child: Text(l10n.awmcCurrentConstants)),
                      for (final v in score.historicalVersions)
                        DropdownMenuItem(value: v, child: Text(v)),
                    ],
                    onChanged: (value) => _selectVersion(
                        score, value?.isNotEmpty == true ? value : null),
                  ),
                  if (result case final audit?) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppSurfaces.inset(context),
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusSmall),
                            ),
                            child: StatTile(
                              centered: true,
                              label: 'B50 Rating',
                              value: '${audit.baseline.raSum}',
                            ),
                          ),
                        ),
                        if (version != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppSurfaces.inset(context),
                                borderRadius: BorderRadius.circular(
                                    AppDesignTokens.radiusSmall),
                              ),
                              child: StatTile(
                                centered: true,
                                label: 'Δ Rating',
                                value:
                                    '${audit.ratingDifference > 0 ? '+' : ''}${audit.ratingDifference}',
                                valueColor: audit.ratingDifference < 0
                                    ? AppColors.errorRed(brightness)
                                    : audit.ratingDifference > 0
                                        ? AppColors.successGreen(brightness)
                                        : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (version != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: AppSurfaces.inset(context),
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.awmcCurrentChartPools,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant),
                            ),
                            if (audit.fallback > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                l10n.awmcHistoricalFallback(
                                    '${audit.fallback}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warningOrange(brightness),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (audit.edges.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: FilledButton.tonalIcon(
                          onPressed: _exporting
                              ? null
                              : () => _exportImage(score, audit: audit),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: Text(l10n.flowExport),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            if (result case final audit?) ...[
              if (audit.edges.isEmpty)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        l10n.flowNoData,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                )
              else
                for (final isNew in [false, true]) ...[
                  _buildEdgeGroup(
                    context,
                    title: isNew ? 'B15' : 'B35',
                    edges: audit.edges
                        .where((edge) => edge.record.isNew == isNew)
                        .toList(),
                    brightness: brightness,
                  ),
                  if (!isNew) const SizedBox(height: AppDesignTokens.cardGap),
                ],
            ] else if (snapshot.hasError)
              AppCard(
                child: Center(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _selectVersion(score, version),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(l10n.flowRetry),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: ExpressiveLoadingIndicator.contained(size: 48)),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEdgeGroup(
    BuildContext context, {
    required String title,
    required List<B50Edge> edges,
    required Brightness brightness,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    if (edges.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: title,
            padding: const EdgeInsets.only(bottom: 10),
            trailing: AppBadge(
              text: '${edges.length}',
              background: AppSurfaces.inset(context),
              foreground: scheme.onSurfaceVariant,
            ),
          ),
          for (final (index, edge) in edges.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            Material(
              color: AppSurfaces.inset(context),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: InkWell(
                onTap: () =>
                    _showChart(edge.record.songId, edge.record.levelIndex),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CoverUtil.buildCoverWidgetWithContext(
                            context, '${edge.record.songId}', 38),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              edge.record.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                ChartDifficultyBadge(
                                  levelIndex: edge.record.levelIndex,
                                  songId: '${edge.record.songId}',
                                ),
                                Text(
                                  '${edge.record.ds}',
                                  style: AppTheme.number(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                AppBadge(
                                  text: edge.selected
                                      ? l10n.awmcB50InList
                                      : l10n.awmcRaToEnter('${edge.raNeeded}'),
                                  background: edge.selected
                                      ? AppColors.successGreen(brightness)
                                          .withValues(alpha: 0.14)
                                      : AppSurfaces.card(context),
                                  foreground: edge.selected
                                      ? AppColors.successGreen(brightness)
                                      : scheme.onSurfaceVariant,
                                  numeric: false,
                                  fontSize: 11,
                                ),
                                if (edge.usesCurrentConstant)
                                  AppBadge(
                                    text: l10n.awmcCurrentConstants,
                                    background:
                                        AppColors.warningOrange(brightness)
                                            .withValues(alpha: 0.14),
                                    foreground:
                                        AppColors.warningOrange(brightness),
                                    numeric: false,
                                    fontSize: 11,
                                  ),
                                if (edge.target != null)
                                  Text(
                                    '${edge.target!.toStringAsFixed(4)}% · +${edge.gain}',
                                    style: AppTheme.number(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${edge.record.ra}',
                        style: AppTheme.number(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _coverage(ScoreInsights score) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final rows = score.coverageByGenre[_genre] ?? score.coverage;
    final genres = score.coverageByGenre.keys.toList()..sort();
    return Column(
      children: [
        if (genres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: DropdownButtonFormField<String>(
                initialValue: _genre,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.flowGenre,
                  filled: true,
                  fillColor: AppSurfaces.inset(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ).insetLabel(context),
                items: [
                  DropdownMenuItem(value: '', child: Text(l10n.flowAll)),
                  for (final genre in genres)
                    DropdownMenuItem(value: genre, child: Text(genre)),
                ],
                onChanged: (value) => setState(() => _genre = value ?? ''),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              final pct = item.total > 0 ? item.played / item.total : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  radius: AppDesignTokens.radiusMedium,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  onTap: item.missing.isEmpty
                      ? null
                      : () => _missingCharts(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.level,
                            style: AppTheme.number(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${item.played} / ${item.total}',
                            style: AppTheme.number(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${(pct * 100).toStringAsFixed(0)}%)',
                            style: AppTheme.number(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (item.missing.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded,
                                size: 18, color: scheme.onSurfaceVariant),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      SmoothLinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: AppSurfaces.track(context),
                        color: scheme.primary,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _missingCharts(ChartCoverage item) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return BackgroundPageScaffold(
              title: '${item.level} · ${context.l10n.awmcNoRecordCharts}',
              contentPadding: EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                    AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
                itemCount: item.missing.length,
                itemBuilder: (context, index) {
                  final chart = item.missing[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard(
                      radius: AppDesignTokens.radiusMedium,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      onTap: () => _showChart(chart.songId, chart.levelIndex),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CoverUtil.buildCoverWidgetWithContext(
                                context, '${chart.songId}', 40),
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
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    ChartDifficultyBadge(
                                      levelIndex: chart.levelIndex,
                                      songId: '${chart.songId}',
                                    ),
                                    Text(
                                      '${chart.ds}',
                                      style: AppTheme.number(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 18, color: scheme.onSurfaceVariant),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
}
