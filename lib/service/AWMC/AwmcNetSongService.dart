import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:http/http.dart' as http;

import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AwmcIdMap.dart';
import '../History/ChartHistoryCore.dart';

class AwmcNetSongException implements Exception {
  const AwmcNetSongException(this.statusCode, {this.retryAfter});

  final int statusCode;
  final Duration? retryAfter;
}

class AwmcNetSongService {
  static final _qqPattern = RegExp(r'^\d{5,12}$');

  static bool isQq(String qq) => _qqPattern.hasMatch(qq);

  /// 公开历史按难度返回每日快照，以本机日期解释，不写入本地历史。
  static Future<Map<int, List<ChartHistoryEvent>>> publicHistory(
    String qq,
    int songId,
  ) async {
    if (!isQq(qq) || AwmcIdMap.fromSongId(songId) == null) {
      throw ArgumentError('Invalid AWMC NET song history lookup');
    }
    final response = await _readPublicHistory(qq, songId);
    _checkStatus(response);
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map || body['levels'] is! Map) {
      throw const FormatException('Invalid AWMC NET song history');
    }
    if (_int(body['song_id']) != songId || _int(body['qq']) != int.parse(qq)) {
      throw const FormatException('AWMC NET history belongs to another lookup');
    }
    final levels = body['levels'] as Map;
    final result = <int, List<ChartHistoryEvent>>{};
    for (final entry in levels.entries) {
      final level = _int(entry.key);
      final points = entry.value;
      if (level == null || level < 0 || points is! List) continue;
      final events = <int, ChartHistoryEvent>{};
      for (final point in points.whereType<Map>()) {
        final date = _localDay(point['date']);
        final achievement = _number(point['achievements']);
        if (date == null || achievement == null || achievement < 0) continue;
        final tMs = date.millisecondsSinceEpoch;
        events[tMs] = ChartHistoryEvent(
          tMs: tMs,
          achievement: achievement.toDouble(),
          dxScore: _int(point['dx_score']) ?? 0,
        );
      }
      result[level] = events.values.toList()
        ..sort((a, b) => a.tMs.compareTo(b.tMs));
    }
    return result;
  }

  static Future<http.Response> _readPublicHistory(String qq, int songId) async {
    if (ApiUrls.BackendApiKey.isNotEmpty) {
      final proxy = Uri.parse(
        '${ApiUrls.BackendBaseUrl}/api/awmc-net/public-song-history',
      ).replace(queryParameters: {'qq': qq, 'song_id': '$songId'});
      try {
        final response =
            await ApiClient.get(proxy, timeout: const Duration(seconds: 8));
        if (response.headers['x-awmc-net-public-history'] == '1' &&
            response.statusCode < 500) {
          return response;
        }
      } on Exception {
        // 代理不可用时仍可依赖 AWMC 的公开档案接口。
      }
    }
    return ApiClient.get(Uri.parse(
      '${ApiUrls.AwmcNetBaseUrl}/api/player/$qq/song/$songId/history',
    ));
  }

  /// 只查询当前 AWMC NET 账号的一首宴谱。开发者凭据由生产代理添加。
  static Future<Map<int, Map<String, dynamic>>> utageRecords(
    String qq,
    int songId,
  ) async {
    if (!isQq(qq) ||
        AwmcIdMap.fromSongId(songId)?.kind != AwmcChartKind.utage) {
      throw ArgumentError('Invalid AWMC NET UTAGE lookup');
    }
    final response = await ApiClient.post(
      Uri.parse('${ApiUrls.BackendBaseUrl}/api/awmc-net/record'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'qq': qq, 'song_id': songId}),
      timeout: const Duration(seconds: 45),
    );
    if (response.statusCode == 404) return const {};
    _checkStatus(response);
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map || body['records'] is! List) {
      throw const FormatException('Invalid AWMC NET song records');
    }
    final events = body['records'] as List;
    final records = <int, Map<String, dynamic>>{};
    for (final row in events.whereType<Map>()) {
      if (_int(row['song_id']) != songId) continue;
      final level = _int(row['level_index']);
      final achievement = _number(row['achievements']);
      if (level == null ||
          level < 0 ||
          achievement == null ||
          achievement < 0) {
        continue;
      }
      records[level] = {
        'song_id': songId,
        'level_index': level,
        'achievements': achievement.toDouble(),
        'dxScore': _int(row['dxScore'] ?? row['dx_score']) ?? 0,
        'ra': _int(row['ra']),
        'rate': row['rate'],
        'fc': row['fc'],
        'fs': row['fs'],
      };
    }
    return records;
  }

  static void _checkStatus(http.Response response) {
    if (response.statusCode == 200) return;
    if (response.statusCode == 429) {
      throw AwmcNetSongException(429, retryAfter: _retryAfter(response));
    }
    throw AwmcNetSongException(response.statusCode);
  }

  static Duration _retryAfter(http.Response response) {
    final retryAfter = response.headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null && seconds > 0) return Duration(seconds: seconds);
      try {
        final remaining = HttpDate.parse(retryAfter).difference(DateTime.now());
        if (remaining > Duration.zero) return remaining;
      } on Exception {
        // 部分上游只在 JSON 中提供限流时间。
      }
    }
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map) {
        final detail = body['detail'];
        final seconds = _int(body['retry_after'] ??
            body['retryAfterSeconds'] ??
            (detail is Map ? detail['retry_after'] : null));
        if (seconds != null && seconds > 0) return Duration(seconds: seconds);
      }
    } on FormatException {
      // 非 JSON 限流页使用短冷却时间。
    }
    return const Duration(seconds: 60);
  }

  static DateTime? _localDay(Object? value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final date = DateTime.tryParse(value);
    if (date == null || !date.toIso8601String().startsWith('${value}T')) {
      return null;
    }
    return date;
  }

  static num? _number(Object? value) {
    final n = value is num ? value : num.tryParse(value?.toString() ?? '');
    return n != null && n.isFinite ? n : null;
  }

  static int? _int(Object? value) {
    final n = _number(value);
    return n != null && n == n.toInt() ? n.toInt() : null;
  }
}
