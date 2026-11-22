import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/GainRecommend/ScoreInsights.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ExportPathUtil.dart';
import '../widgets/AnimatedChoiceBar.dart';
import '../widgets/AppToast.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/ExportSuccessDialog.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import 'SongInfoPage.dart';

enum _View { overview, audit, coverage }

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

  Future<void> _export(B50Audit audit, String? version) async {
    if (_exporting) return;
    final l10n = context.l10n;
    setState(() => _exporting = true);
    final rows = <List<Object?>>[
      ['Version', version ?? l10n.awmcCurrentConstants],
      ['B35/B15', l10n.awmcCurrentChartPools],
      ['Current-constant fallbacks', audit.fallback],
      ['B50 Rating', audit.baseline.raSum],
      if (version != null) ['Rating change', audit.ratingDifference],
      [
        'Pool',
        'Song ID',
        'Chart',
        'Difficulty',
        'Constant',
        'Used current constant',
        'Achievement',
        'Rating',
        'Selected',
        'Cutoff',
        'Rating needed',
        'Next target',
        'Gain'
      ],
      for (final edge in audit.edges)
        [
          edge.record.isNew == true ? 'B15' : 'B35',
          edge.record.songId,
          edge.record.title,
          ChartDifficulty.labelOf(edge.record.levelIndex),
          edge.record.ds,
          edge.usesCurrentConstant,
          edge.record.achievements,
          edge.record.ra,
          edge.selected,
          edge.floor,
          edge.raNeeded,
          edge.target,
          edge.gain,
        ],
    ];
    String cell(Object? value) {
      var text = value?.toString() ?? '';
      if (value is String && RegExp(r'^\s*[=+@-]').hasMatch(text)) {
        text = "'$text";
      }
      return '"${text.replaceAll('"', '""')}"';
    }

    final csv =
        '\uFEFF${rows.map((row) => row.map(cell).join(',')).join('\r\n')}\r\n';
    final name = 'b50-audit-${DateTime.now().millisecondsSinceEpoch}.csv';
    try {
      String? fallback;
      final file = await ExportPathUtil.writeExportTextFile(
        fileName: name,
        content: csv,
        subDir: '成绩分析',
        onFallback: (path) => fallback = path,
      );
      if (mounted) {
        await showExportSuccessDialog(context,
            filePath: file.path, fileName: name, fallbackPath: fallback);
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(l10n.flowExportFailedTryAgain, tone: AppToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BackgroundPageScaffold(
      title: l10n.awmcScoreInsights,
      child: FutureBuilder(
        future: _source,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final score = snapshot.data;
          if (score == null) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() {
                  _source = ScoreInsights.load();
                  _audit = null;
                }),
                child: Text('${l10n.awmcInsightsNoCache} · ${l10n.flowRetry}'),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    if (view == _View.audit) _audit ??= score.audit(_version);
                  }),
                ),
              ),
              Expanded(
                child: switch (_view) {
                  _View.overview => _overview(score),
                  _View.audit => _auditView(score),
                  _View.coverage => _coverage(score),
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _overview(ScoreInsights score) {
    final l10n = context.l10n;
    final count = score.coverage.fold<int>(0, (sum, row) => sum + row.total);
    final played = score.coverage.fold<int>(0, (sum, row) => sum + row.played);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.awmcChartCoverage),
          trailing: Text('$played / $count'),
          onTap: () => setState(() => _view = _View.coverage),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('SSS / SSS+'),
          trailing: Text('${score.sss}'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('FC / FC+ / AP / AP+'),
          trailing: Text('${score.fullCombo}'),
        ),
        Text(l10n.awmcLocalScoreSnapshot,
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _auditView(ScoreInsights score) {
    final l10n = context.l10n;
    final version = _version;
    return FutureBuilder(
      future: _audit,
      builder: (context, snapshot) {
        final result = snapshot.connectionState == ConnectionState.done
            ? snapshot.data
            : null;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            DropdownButtonFormField<String>(
              initialValue: version ?? '',
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.awmcAuditConstants),
              items: [
                DropdownMenuItem(
                    value: '', child: Text(l10n.awmcCurrentConstants)),
                for (final version in score.historicalVersions)
                  DropdownMenuItem(value: version, child: Text(version)),
              ],
              onChanged: (value) => _selectVersion(
                  score, value?.isNotEmpty == true ? value : null),
            ),
            const SizedBox(height: 12),
            if (result case final audit?) ...[
              Text('B50 Rating  ${audit.baseline.raSum}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (version != null) ...[
                Text(
                    'Δ Rating  ${audit.ratingDifference > 0 ? '+' : ''}${audit.ratingDifference}'),
                Text(l10n.awmcCurrentChartPools),
                if (audit.fallback > 0)
                  Text(l10n.awmcHistoricalFallback('${audit.fallback}')),
              ],
              if (audit.edges.isEmpty) Text(l10n.flowNoData),
              for (final isNew in [false, true]) ...[
                const SizedBox(height: 12),
                Text(isNew ? 'B15' : 'B35',
                    style: Theme.of(context).textTheme.titleSmall),
                for (final edge
                    in audit.edges.where((edge) => edge.record.isNew == isNew))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(edge.record.title),
                    subtitle: Text([
                      '${ChartDifficulty.labelOf(edge.record.levelIndex)} · ${edge.record.ds}',
                      if (edge.usesCurrentConstant) l10n.awmcCurrentConstants,
                      if (edge.selected) l10n.awmcB50InList,
                      if (!edge.selected)
                        l10n.awmcRaToEnter('${edge.raNeeded}'),
                      if (edge.target != null)
                        '${edge.target!.toStringAsFixed(4)}% · +${edge.gain}',
                    ].join(' · ')),
                    trailing: Text('${edge.record.ra}'),
                    onTap: () =>
                        _showChart(edge.record.songId, edge.record.levelIndex),
                  ),
              ],
              if (audit.edges.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _export(audit, version),
                  icon: const Icon(Icons.ios_share),
                  label: Text(l10n.flowExport),
                ),
            ] else if (snapshot.hasError)
              TextButton(
                onPressed: () => _selectVersion(score, version),
                child: Text(l10n.flowRetry),
              )
            else
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Widget _coverage(ScoreInsights score) {
    final l10n = context.l10n;
    final rows = score.coverageByGenre[_genre] ?? score.coverage;
    final genres = score.coverageByGenre.keys.toList()..sort();
    return Column(
      children: [
        if (genres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: _genre,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.flowGenre),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.flowAll)),
                for (final genre in genres)
                  DropdownMenuItem(value: genre, child: Text(genre)),
              ],
              onChanged: (value) => setState(() => _genre = value ?? ''),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final item = rows[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.level),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: SmoothLinearProgressIndicator(
                      value: item.played / item.total),
                ),
                trailing: Text('${item.played} / ${item.total}'),
                onTap: item.missing.isEmpty ? null : () => _missingCharts(item),
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
          builder: (context) => BackgroundPageScaffold(
            title: '${item.level} · ${context.l10n.awmcNoRecordCharts}',
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: item.missing.length,
              itemBuilder: (context, index) {
                final chart = item.missing[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(chart.title),
                  subtitle: Text(
                      '${ChartDifficulty.labelOf(chart.levelIndex)} · ${chart.ds}'),
                  onTap: () => _showChart(chart.songId, chart.levelIndex),
                );
              },
            ),
          ),
        ),
      );
}
