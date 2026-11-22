import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef AwmcChartInfo = ({double constant, String designer});

class AwmcChartMetadata {
  static final _asset = _load();

  static Future<Map<int, AwmcChartInfo>> forSong(String songId) async {
    final id = int.tryParse(songId);
    if (id == null || id <= 0 || id >= 100000) return const {};
    return (await _asset)[id] ?? const {};
  }

  static Future<Map<int, Map<int, AwmcChartInfo>>> _load() async {
    try {
      final json =
          await rootBundle.loadString('assets/awmc_chart_metadata.json');
      return await compute(_decode, json);
    } catch (_) {
      return const {};
    }
  }

  static Map<int, Map<int, AwmcChartInfo>> _decode(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return {
      for (final entry in data.entries)
        int.parse(entry.key): {
          for (final chart in (entry.value as Map<String, dynamic>).entries)
            int.parse(chart.key): (
              constant: (chart.value[0] as num).toDouble(),
              designer: chart.value[1] as String,
            ),
        },
    };
  }
}
