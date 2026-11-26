import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/AWMC/AwmcChartDetailsService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';

/// 歌曲详情页内嵌的 AWMC 谱面分析、社区评分、评论与成绩纠错卡片。
class AwmcChartDetails extends StatefulWidget {
  final String chartKey;
  final AwmcChartDetailsSection section;
  final bool embedded;

  const AwmcChartDetails({
    super.key,
    required this.chartKey,
    required this.section,
    this.embedded = false,
  });

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
    final scheme = Theme.of(context).colorScheme;
    final title = switch (widget.section) {
      AwmcChartDetailsSection.analysis => l10n.awmcChartAnalysis,
      AwmcChartDetailsSection.ratings => l10n.awmcChartRatings,
      AwmcChartDetailsSection.comments => l10n.awmcChartComments,
      AwmcChartDetailsSection.community => l10n.awmcChartCommunityScores,
    };

    final body = FutureBuilder<Map<String, dynamic>?>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.flowLoading2,
                style:
                    TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  l10n.awmcChartUnavailable,
                  style: TextStyle(
                      fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              ),
              LinkPill(
                label: l10n.flowRetry,
                onTap: () => setState(() => _load(_page)),
              ),
            ],
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return Text(
            l10n.flowNoData,
            style:
                TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          );
        }
        return switch (widget.section) {
          AwmcChartDetailsSection.analysis => _analysis(data),
          AwmcChartDetailsSection.ratings => _ratings(data),
          AwmcChartDetailsSection.comments => _comments(data),
          AwmcChartDetailsSection.community => _community(data),
        };
      },
    );

    if (widget.embedded) return body;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: title,
            padding: const EdgeInsets.only(bottom: 10),
          ),
          body,
        ],
      ),
    );
  }

  Widget _analysis(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final minBpm = data['minBpm'];
    final maxBpm = data['maxBpm'];
    final hasBpm = minBpm is num && maxBpm is num;
    final playableNotes = data['playableNotes'];
    final peakNps = data['peakNps'];

    Widget metricBox(String label, String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          ),
          child: StatTile(label: label, value: value, valueSize: 15),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (data['levelLabel'] case final String label when label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppBadge(
                text: label,
                background: AppSurfaces.inset(context),
                foreground: scheme.primary,
                numeric: false,
              ),
            ),
          ),
        if (hasBpm || playableNotes is num || peakNps is num) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasBpm)
                metricBox(
                  'BPM',
                  '${_number(minBpm)}${minBpm == maxBpm ? '' : '–${_number(maxBpm)}'}',
                ),
              if (playableNotes is num)
                metricBox(l10n.awmcPlayableNotes, _number(playableNotes)),
              if (peakNps is num) metricBox('Peak NPS', _number(peakNps)),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, key) in const [
              ('TAP', 'tapCount'),
              ('HOLD', 'holdCount'),
              ('SLIDE', 'slideCount'),
              ('TOUCH', 'touchCount'),
              ('BREAK', 'breakCount'),
              ('EX', 'exCount'),
            ])
              if (data[key] case final num value)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _number(value),
                        style: AppTheme.number(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _ratings(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final count = (data['ratingCount'] as num?)?.toInt() ?? 0;
    if (count == 0) {
      return Text(
        l10n.flowNoRatingsYet,
        style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      );
    }
    final distribution = data['distribution'];
    final bins = distribution is Map
        ? distribution.entries.toList()
        : const <MapEntry>[];
    if (bins.isNotEmpty) {
      bins.sort((a, b) => a.key.toString().compareTo(b.key.toString()));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          ),
          child: Row(
            children: [
              Icon(Icons.star_rounded, size: 22, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                _number(data['ratingAverage']),
                style: AppTheme.number(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                ' / 5',
                style: AppTheme.number(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              AppBadge(
                text: '${l10n.awmcSampleCount} $count',
                background: AppSurfaces.card(context),
                foreground: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (bins.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final bin in bins)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: Text(
                    '${bin.key} ★ · ${bin.value}',
                    style: AppTheme.number(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _comments(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final items =
        (data['items'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final total = (data['total'] as num?)?.toInt() ?? 0;
    final hasNext = _page < 100 && _page * 20 < total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          Text(
            l10n.flowNoCommentsYet,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _byline(item),
                const SizedBox(height: 4),
                Text(
                  '${item['body'] ?? ''}',
                  style: const TextStyle(fontSize: 13.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
        if (_page > 1 || hasNext) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: l10n.flowPrevious,
                onPressed:
                    _page > 1 ? () => setState(() => _load(_page - 1)) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$_page',
                style: AppTheme.number(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              IconButton(
                tooltip: l10n.flowNext,
                onPressed:
                    hasNext ? () => setState(() => _load(_page + 1)) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _community(Map<String, dynamic> data) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final stats = data['stats'] as Map? ?? const {};
    final count = (stats['submissionCount'] as num?)?.toInt() ?? 0;
    final scores =
        (data['scores'] as List?)?.whereType<Map>().take(8).toList() ??
            const <Map>[];
    final corrections =
        (data['corrections'] as List?)?.whereType<Map>().take(8).toList() ??
            const <Map>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${l10n.awmcSnapshot} ${_date(data['loadedAt'], includeTime: true)}',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (count == 0)
          Text(
            l10n.flowNoData,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: StatTile(
                    centered: true,
                    label: l10n.awmcSampleCount,
                    value: '$count',
                    valueSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: StatTile(
                    centered: true,
                    label: l10n.flowAvgAchievement,
                    value: '${_number(stats['averageAchievement'])}%',
                    valueSize: 15,
                  ),
                ),
              ),
            ],
          ),
          if (scores.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final (index, score) in scores.indexed) ...[
              if (index > 0) const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppSurfaces.inset(context),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                child: Row(
                  children: [
                    Text(
                      '${_number(score['achievement'])}%',
                      style: AppTheme.number(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _date(score['createdAt']),
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
        const SizedBox(height: 14),
        Text(
          l10n.awmcChartCorrections,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (corrections.isEmpty)
          Text(
            l10n.flowNoData,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          )
        else
          for (final (index, item) in corrections.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _byline(item),
                  const SizedBox(height: 4),
                  Text(
                    '${item['body'] ?? item['description'] ?? item['reason'] ?? item['status'] ?? l10n.awmcChartCorrections}',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }

  Widget _byline(Map item) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        if (item['author'] case final String author when author.isNotEmpty)
          Expanded(
            child: Text(
              author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          )
        else
          const Spacer(),
        const SizedBox(width: 8),
        Text(
          _date(item['createdAt']),
          style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

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
