import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';

enum AwmcChartDetailsSection { analysis, ratings, comments, community }

class AwmcChartDetailsService {
  static const _missingTtl = Duration(days: 30);
  static const _requestTimeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>?> load(
    String chartKey,
    AwmcChartDetailsSection section, {
    int page = 1,
  }) async {
    if (section == AwmcChartDetailsSection.community) {
      final results = await Future.wait([
        for (final path in ['scores/stats', 'scores', 'corrections'])
          _read(Uri.https('v.wmc.pub', '/api/chart-community/$path', {
            'chartKey': chartKey,
          })),
      ]);
      return {
        'stats': results[0],
        'scores': results[1],
        'corrections': results[2],
        'loadedAt': DateTime.now().toIso8601String()
      };
    }

    final missingKey = 'awmc_preview_missing_v1:${section.name}:$chartKey';
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final missingAt = prefs.getInt(missingKey);
    if (missingAt != null && now - missingAt < _missingTtl.inMilliseconds) {
      return null;
    }
    final uri = Uri.parse('${ApiUrls.BackendBaseUrl}/api/awmc-preview/charts/'
            '$chartKey/details/${section.name}')
        .replace(
            queryParameters: section == AwmcChartDetailsSection.comments
                ? {'page': '$page'}
                : null);
    final response = await ApiClient.get(uri, timeout: _requestTimeout);
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) throw const FormatException();
    if (response.statusCode == 404 && body['missing'] == true) {
      // 仅缓存代理明确确认的缺失，不把旧版代理的 404 当成上游空态。
      if (page == 1) await prefs.setInt(missingKey, now);
      return null;
    }
    if (response.statusCode != 200 || !body.containsKey('data')) {
      throw StateError('AWMC HTTP ${response.statusCode}');
    }
    return body['data'] as Map<String, dynamic>?;
  }

  static Future<dynamic> _read(Uri url) async {
    final response = await ApiClient.get(url, timeout: _requestTimeout);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw StateError('AWMC HTTP ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
