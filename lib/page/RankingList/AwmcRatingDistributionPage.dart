import 'dart:convert';

import 'package:flutter/material.dart';

import '../../api/ApiUrls.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';

/// AWMC NET 全服 Rating 分布页面。
class AwmcRatingDistributionPage extends StatefulWidget {
  const AwmcRatingDistributionPage({super.key});

  @override
  State<AwmcRatingDistributionPage> createState() =>
      _AwmcRatingDistributionPageState();
}

class _AwmcRatingDistributionPageState
    extends State<AwmcRatingDistributionPage> {
  static const _pageSize = 500;
  static const _binSize = 500;
  late Future<({int count, DateTime time, Map<int, int> bins})> _request =
      _load();

  Future<({int count, DateTime time, Map<int, int> bins})> _load() async {
    final bins = <int, int>{};
    var count = 0;
    for (var page = 1; page <= 2; page++) {
      final uri = Uri.parse('${ApiUrls.AwmcNetBaseUrl}/api/rating_ranking')
          .replace(queryParameters: {'page': '$page', 'size': '$_pageSize'});
      final response = await ApiClient.get(uri);
      if (response.statusCode != 200) {
        throw StateError('AWMC HTTP ${response.statusCode}');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! List) throw const FormatException();
      for (final row in data.take(_pageSize).whereType<Map>()) {
        final rating = row['ra'];
        if (rating is! int || rating < 0) continue;
        final bin = rating ~/ _binSize * _binSize;
        bins.update(bin, (n) => n + 1, ifAbsent: () => 1);
        count++;
      }
      if (data.length < _pageSize) break;
    }
    return (count: count, time: DateTime.now(), bins: bins);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: 'AWMC NET · ${l10n.flowRatingDistribution}',
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: FutureBuilder(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.gutter),
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off_outlined,
                          size: 40, color: scheme.onSurfaceVariant),
                      const SizedBox(height: 10),
                      Text(
                        l10n.awmcChartUnavailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => setState(() => _request = _load()),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(l10n.flowRetry),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          final data = snapshot.data;
          if (data == null || data.count == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.gutter),
                child: AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bar_chart_rounded,
                            size: 36, color: scheme.outline),
                        const SizedBox(height: 8),
                        Text(
                          l10n.flowNoData,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          final locale = MaterialLocalizations.of(context);
          final peakEntry = data.bins.entries
              .reduce((a, b) => a.value >= b.value ? a : b);
          final maximum = peakEntry.value;
          final keys = data.bins.keys.toList()..sort((a, b) => b.compareTo(a));
          final snapshotTime =
              '${locale.formatShortDate(data.time)} '
              '${locale.formatTimeOfDay(TimeOfDay.fromDateTime(data.time))}';

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(
                      title:
                          '${l10n.featureRatingLeaderboard} #1–#${data.count}',
                      subtitle: '${l10n.awmcSnapshot} $snapshotTime',
                      padding: const EdgeInsets.only(bottom: 12),
                      trailing: AppBadge(
                        text: 'AWMC NET',
                        background: AppSurfaces.inset(context),
                        foreground: scheme.primary,
                        numeric: false,
                      ),
                    ),
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
                              label: l10n.awmcSampleCount,
                              value: '${data.count}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
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
                              label:
                                  '${peakEntry.key}–${peakEntry.key + _binSize - 1}',
                              value: '$maximum',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.cardGap),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(
                      title: l10n.flowRatingDistribution,
                      padding: const EdgeInsets.only(bottom: 12),
                    ),
                    for (final (index, key) in keys.indexed) ...[
                      if (index > 0) const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$key–${key + _binSize - 1}',
                              style: AppTheme.number(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            '${data.bins[key]}',
                            style: AppTheme.number(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${(data.bins[key]! * 100 / data.count).toStringAsFixed(1)}%)',
                            style: AppTheme.number(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      SmoothLinearProgressIndicator(
                        value: data.bins[key]! / maximum,
                        minHeight: 7,
                        backgroundColor: AppSurfaces.track(context),
                        color: scheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
