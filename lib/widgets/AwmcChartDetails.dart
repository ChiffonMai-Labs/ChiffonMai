import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/AWMC/AwmcChartDetailsService.dart';

class AwmcChartDetails extends StatefulWidget {
  final String chartKey;
  final AwmcChartDetailsSection section;

  const AwmcChartDetails(
      {super.key, required this.chartKey, required this.section});

  @override
  State<AwmcChartDetails> createState() => _AwmcChartDetailsState();
}

class _AwmcChartDetailsState extends State<AwmcChartDetails> {
  late Future<Map<String, dynamic>?> _request;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  @override
  void didUpdateWidget(covariant AwmcChartDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chartKey != oldWidget.chartKey ||
        widget.section != oldWidget.section) {
      _load(1);
    }
  }

  void _load(int page) {
    _page = page;
    _request = AwmcChartDetailsService.load(widget.chartKey, widget.section,
        page: page);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = switch (widget.section) {
      AwmcChartDetailsSection.analysis => l10n.awmcChartAnalysis,
      AwmcChartDetailsSection.ratings => l10n.awmcChartRatings,
      AwmcChartDetailsSection.comments => l10n.awmcChartComments,
      AwmcChartDetailsSection.community => l10n.awmcChartCommunityScores,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
        const SizedBox(height: 8),
        FutureBuilder<Map<String, dynamic>?>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Text(l10n.flowLoading2);
            }
            if (snapshot.hasError) {
              return Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(l10n.awmcChartUnavailable),
                    TextButton(
                        onPressed: () => setState(() => _load(_page)),
                        child: Text(l10n.flowRetry)),
                  ]);
            }
            final data = snapshot.data;
            if (data == null) return Text(l10n.flowNoData);
            return switch (widget.section) {
              AwmcChartDetailsSection.analysis => _analysis(data),
              AwmcChartDetailsSection.ratings => _ratings(data),
              AwmcChartDetailsSection.comments => _comments(data),
              AwmcChartDetailsSection.community => _community(data),
            };
          },
        ),
        const Divider(height: 20),
      ]),
    );
  }

  Widget _analysis(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final minBpm = data['minBpm'];
    final maxBpm = data['maxBpm'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (data['levelLabel'] case final String label when label.isNotEmpty)
        Text(label),
      if (minBpm is num && maxBpm is num)
        Text(
            'BPM ${_number(minBpm)}${minBpm == maxBpm ? '' : '–${_number(maxBpm)}'}'),
      if (data['playableNotes'] case final num count)
        Text('${l10n.awmcPlayableNotes}  ${_number(count)}'),
      Wrap(spacing: 16, runSpacing: 4, children: [
        for (final (label, key) in const [
          ('TAP', 'tapCount'),
          ('HOLD', 'holdCount'),
          ('SLIDE', 'slideCount'),
          ('TOUCH', 'touchCount'),
          ('BREAK', 'breakCount'),
          ('EX', 'exCount'),
          ('Peak NPS', 'peakNps'),
        ])
          if (data[key] case final num value) Text('$label ${_number(value)}'),
      ]),
    ]);
  }

  Widget _ratings(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final count = (data['ratingCount'] as num?)?.toInt() ?? 0;
    if (count == 0) return Text(l10n.flowNoRatingsYet);
    final distribution = data['distribution'];
    final bins = distribution is Map
        ? distribution.entries.toList()
        : const <MapEntry>[];
    if (bins.isNotEmpty) {
      bins.sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          '${_number(data['ratingAverage'])} / 5  ·  ${l10n.awmcSampleCount} $count'),
      if (bins.isNotEmpty)
        Wrap(spacing: 12, runSpacing: 4, children: [
          for (final bin in bins) Text('${bin.key} ★ · ${bin.value}'),
        ]),
    ]);
  }

  Widget _comments(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final items =
        (data['items'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final total = (data['total'] as num?)?.toInt() ?? 0;
    final hasNext = _page < 100 && _page * 20 < total;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (items.isEmpty) Text(l10n.flowNoCommentsYet),
      for (final item in items) ...[
        _byline(item),
        Text('${item['body'] ?? ''}'),
        const Divider(height: 16),
      ],
      if (_page > 1 || hasNext)
        Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                  onPressed:
                      _page > 1 ? () => setState(() => _load(_page - 1)) : null,
                  child: Text(l10n.flowPrevious)),
              Text('$_page'),
              TextButton(
                  onPressed:
                      hasNext ? () => setState(() => _load(_page + 1)) : null,
                  child: Text(l10n.flowNext)),
            ]),
    ]);
  }

  Widget _community(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final stats = data['stats'] as Map? ?? const {};
    final count = (stats['submissionCount'] as num?)?.toInt() ?? 0;
    final scores =
        (data['scores'] as List?)?.whereType<Map>().take(8) ?? const <Map>[];
    final corrections =
        (data['corrections'] as List?)?.whereType<Map>().take(8) ??
            const <Map>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          '${l10n.awmcSnapshot} ${_date(data['loadedAt'], includeTime: true)}'),
      if (count == 0)
        Text(l10n.flowNoData)
      else ...[
        Text('${l10n.awmcSampleCount} $count'),
        Text(
            '${l10n.flowAvgAchievement} ${_number(stats['averageAchievement'])}%'),
        for (final score in scores)
          Text(
              '${_number(score['achievement'])}%  ·  ${_date(score['createdAt'])}'),
      ],
      const SizedBox(height: 8),
      Text(l10n.awmcChartCorrections,
          style: Theme.of(context).textTheme.titleSmall),
      if (corrections.isEmpty) Text(l10n.flowNoData),
      for (final item in corrections) ...[
        _byline(item),
        Text(
            '${item['body'] ?? item['description'] ?? item['reason'] ?? item['status'] ?? l10n.awmcChartCorrections}'),
      ],
    ]);
  }

  Widget _byline(Map item) => Wrap(spacing: 10, children: [
        if (item['author'] case final String author when author.isNotEmpty)
          Text(author),
        Text(_date(item['createdAt']),
            style: Theme.of(context).textTheme.bodySmall),
      ]);

  String _date(Object? value, {bool includeTime = false}) {
    final date = value is String ? DateTime.tryParse(value)?.toLocal() : null;
    if (date == null) return '';
    final locale = MaterialLocalizations.of(context);
    final day = locale.formatShortDate(date);
    return includeTime
        ? '$day ${locale.formatTimeOfDay(TimeOfDay.fromDateTime(date))}'
        : day;
  }

  String _number(Object? value) => value is num
      ? value.toStringAsFixed(value == value.round() ? 0 : 2)
      : '–';
}
