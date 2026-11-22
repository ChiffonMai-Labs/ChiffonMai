import 'dart:convert';

import 'package:flutter/material.dart';

import '../../api/ApiUrls.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../utils/ApiClient.dart';
import '../../widgets/BackgroundPageScaffold.dart';

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
    return BackgroundPageScaffold(
      title: 'AWMC NET · ${l10n.flowRatingDistribution}',
      child: FutureBuilder(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: TextButton(
                    onPressed: () => setState(() => _request = _load()),
                    child: Text(
                        '${l10n.awmcChartUnavailable} · ${l10n.flowRetry}')));
          }
          final data = snapshot.data;
          if (data == null || data.count == 0) {
            return Center(child: Text(l10n.flowNoData));
          }
          final locale = MaterialLocalizations.of(context);
          final maximum = data.bins.values.reduce((a, b) => a > b ? a : b);
          final keys = data.bins.keys.toList()..sort((a, b) => b.compareTo(a));
          final colors = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                  '${l10n.featureRatingLeaderboard} #1–#${data.count} · AWMC NET'),
              Text('${l10n.awmcSnapshot} ${locale.formatShortDate(data.time)} '
                  '${locale.formatTimeOfDay(TimeOfDay.fromDateTime(data.time))}'),
              const SizedBox(height: 16),
              for (final key in keys) ...[
                Row(children: [
                  Expanded(child: Text('$key–${key + _binSize - 1}')),
                  Text('${data.bins[key]}')
                ]),
                const SizedBox(height: 4),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4)),
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                      widthFactor: data.bins[key]! / maximum,
                      heightFactor: 1,
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(4)))),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}
