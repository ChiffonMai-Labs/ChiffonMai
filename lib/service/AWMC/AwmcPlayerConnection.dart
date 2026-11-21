import 'dart:convert';

import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';
import '../../utils/SecureCredentialStore.dart';
import '../../constant/CacheKeyConstant.dart';

class PlayerConnectionError implements Exception {
  final String code;
  const PlayerConnectionError(this.code);
}

class AwmcPlayerConnection {
  static Future<Map<String, dynamic>> request(String action,
      {Map<String, String> fields = const {}, String? token}) async {
    final response = await ApiClient.post(
        Uri.parse('${ApiUrls.AwmcNetBaseUrl}/api/mobile/qq/$action'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token'
        },
        body: jsonEncode(fields),
        timeout: Duration(seconds: action == 'preview' ? 135 : 30));
    Map<String, dynamic>? data;
    try {
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      if (value is Map<String, dynamic>) data = value;
    } on FormatException {/* 网关有时返回 HTML。 */}
    if (response.statusCode != 200 || data == null) {
      throw PlayerConnectionError(response.statusCode == 401
          ? 'expired_session'
          : response.statusCode == 429
              ? 'slow_down'
              : data?['detail'] is String
                  ? data!['detail']
                  : 'unavailable');
    }
    return data;
  }

  static Future<({String qq, String token})?> restore() async {
    final raw =
        await SecureCredentialStore.read(CacheKeyConstant.awmcPlayerSession);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map && data['qq'] is String && data['token'] is String) {
        return (qq: data['qq'] as String, token: data['token'] as String);
      }
    } on FormatException {/* 损坏的会话需要重新验证。 */}
    await forget();
    return null;
  }

  static Future<void> remember(String qq, String token) =>
      SecureCredentialStore.write(CacheKeyConstant.awmcPlayerSession,
          jsonEncode({'qq': qq, 'token': token}));
  static Future<void> disconnect() async {
    final session = await restore();
    if (session != null) {
      try {
        await request('logout', token: session.token);
      } on PlayerConnectionError catch (e) {
        if (e.code != 'expired_session') rethrow;
      }
    }
    await forget();
  }

  static Future<void> forget() =>
      SecureCredentialStore.delete(CacheKeyConstant.awmcPlayerSession);
}
