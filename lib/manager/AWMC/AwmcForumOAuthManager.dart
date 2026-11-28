import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../service/Account/AccountAuthorizationStore.dart';
import '../../utils/ApiClient.dart';
import '../../utils/SecureCredentialStore.dart';

/// 一次 AWMC 论坛 OAuth 登录事务（由服务端签发 state 与 PKCE）。
class AwmcForumOAuthSession {
  final String sessionId;
  final String authorizeUrl;
  final int expiresInSeconds;

  const AwmcForumOAuthSession({
    required this.sessionId,
    required this.authorizeUrl,
    required this.expiresInSeconds,
  });
}

enum AwmcForumOAuthPollStatus {
  pending,
  completed,
  failed,
  expired,
}

class AwmcForumOAuthPollResult {
  final AwmcForumOAuthPollStatus status;
  final String qq;
  final String username;
  final String xfUserId;
  final String authToken;
  final int? tokenExpiresAt;
  final String? error;

  const AwmcForumOAuthPollResult({
    required this.status,
    this.qq = '',
    this.username = '',
    this.xfUserId = '',
    this.authToken = '',
    this.tokenExpiresAt,
    this.error,
  });
}

/// AWMC 论坛（bbs.wmc.pub）OAuth 2.0 + PKCE 客户端管理器。
///
/// 流程：App 调用后端 `/api/awmc/oauth/start` 取得授权链接 → 系统浏览器完成论坛授权并回调至
/// `https://chiffonmai.cloud/api/awmc/oauth/callback` → 后端换票并提取 `数字@qq.com` 对应 QQ
/// 及服务端签发的会话令牌 → App 轮询 `/api/awmc/oauth/status` 获取绑定 QQ 与令牌并存入安全存储
/// （论坛 access_token 仅在后端瞬时使用，不落盘）。
class AwmcForumOAuthManager {
  AwmcForumOAuthManager._();

  static final AwmcForumOAuthManager instance = AwmcForumOAuthManager._();
  static final RegExp _qqRe = RegExp(r'^[1-9]\d{4,11}$');

  /// 保存论坛 OAuth 授权得到的查分 QQ 与服务端会话令牌。
  static Future<void> saveAuthorizedSession({
    required String qq,
    required String authToken,
  }) async {
    final normalizedQq = qq.trim();
    final normalizedToken = authToken.trim();
    if (!_qqRe.hasMatch(normalizedQq) || !_isCurrentToken(normalizedToken)) {
      throw const FormatException('AWMC 论坛授权结果无效');
    }
    await SecureCredentialStore.write(
        CacheKeyConstant.awmcOAuthToken, normalizedToken);
    await SecureCredentialStore.write(
        CacheKeyConstant.awmcOAuthVerifiedQq, normalizedQq);
    await AccountAuthorizationStore.saveAwmcQQ(normalizedQq);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.awmcNetSyncQQ, normalizedQq);
    AccountAuthorizationStore.setAwmcOAuthAuthorized(true);
  }

  /// 读取本机安全存储中的 AWMC OAuth 会话令牌；校验与目标 QQ 一致。
  static Future<String?> readAuthToken({String? expectedQq}) async {
    try {
      final token =
          (await SecureCredentialStore.read(CacheKeyConstant.awmcOAuthToken))
                  ?.trim() ??
              '';
      if (!_isCurrentToken(token)) return null;
      final verifiedQq = (await SecureCredentialStore.read(
                  CacheKeyConstant.awmcOAuthVerifiedQq))
              ?.trim() ??
          '';
      final expected = expectedQq?.trim() ?? '';
      if (expected.isNotEmpty && verifiedQq != expected) {
        return null;
      }
      return token;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> hasValidOAuthSession({String? expectedQq}) async =>
      (await readAuthToken(expectedQq: expectedQq)) != null;

  static Future<Map<String, String>> authHeaders(String? qq) async {
    if (qq == null || !_qqRe.hasMatch(qq)) return const {};
    final token = await readAuthToken(expectedQq: qq);
    return token == null ? const {} : {'X-AWMC-OAuth-Token': token};
  }

  // 本机只检查版本与过期时间，签名和账号归属由服务端验证。
  static bool _isCurrentToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3 || parts[0] != 'awmc_v2') return false;
    try {
      final payload = jsonDecode(utf8.decode(base64Url.decode(
        base64Url.normalize(parts[1]),
      )));
      final exp = payload is Map ? payload['exp'] : null;
      return exp is int && exp * 1000 > DateTime.now().millisecondsSinceEpoch;
    } on FormatException {
      return false;
    }
  }

  /// 清除本机安全存储中的 AWMC OAuth 会话令牌与已验证 QQ 标记。
  static Future<void> clearAuthorizedSession() async {
    try {
      await SecureCredentialStore.delete(CacheKeyConstant.awmcOAuthToken);
      await SecureCredentialStore.delete(CacheKeyConstant.awmcOAuthVerifiedQq);
    } catch (_) {}
    AccountAuthorizationStore.setAwmcOAuthAuthorized(false);
  }

  Future<({AwmcForumOAuthSession? session, String? error})>
      startSession() async {
    try {
      final response = await ApiClient.post(
        Uri.parse(ApiUrls.AwmcOAuthStartUrl),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
        timeout: const Duration(seconds: 15),
      );
      final data = _tryDecodeMap(response.body);
      if (response.statusCode == 200 && data != null) {
        final sessionId = (data['sessionId'] as String?)?.trim() ?? '';
        final authorizeUrl = (data['authorizeUrl'] as String?)?.trim() ?? '';
        final expires = (data['expiresInSeconds'] as num?)?.toInt() ?? 600;
        if (sessionId.isNotEmpty && authorizeUrl.isNotEmpty) {
          return (
            session: AwmcForumOAuthSession(
              sessionId: sessionId,
              authorizeUrl: authorizeUrl,
              expiresInSeconds: expires,
            ),
            error: null,
          );
        }
      }
      final msg = _extractErrorMessage(data) ??
          '发起 AWMC 论坛授权失败（HTTP ${response.statusCode}）';
      return (session: null, error: msg);
    } catch (e) {
      debugPrint('发起 AWMC 论坛 OAuth 异常: $e');
      return (session: null, error: '网络请求失败，无法连接授权服务，请稍后重试');
    }
  }

  Future<AwmcForumOAuthPollResult> pollStatus(String sessionId) async {
    try {
      final response = await ApiClient.get(
        Uri.parse(ApiUrls.AwmcOAuthStatusUrl),
        headers: {'X-AWMC-OAuth-Session': sessionId},
        timeout: const Duration(seconds: 10),
      );
      final data = _tryDecodeMap(response.body);
      if (response.statusCode == 404 || data?['status'] == 'expired') {
        return AwmcForumOAuthPollResult(
          status: AwmcForumOAuthPollStatus.expired,
          error: _extractErrorMessage(data) ?? '授权会话已过期，请重新发起授权',
        );
      }
      if (response.statusCode == 200 && data != null) {
        final status = (data['status'] as String?) ?? '';
        if (status == 'completed') {
          final qq = (data['qq'] as String?)?.trim() ?? '';
          final username = (data['username'] as String?)?.trim() ?? '';
          final xfUserId = (data['xfUserId'] as String?)?.trim() ?? '';
          final authToken = (data['authToken'] as String?)?.trim() ?? '';
          final tokenExpiresAt = (data['tokenExpiresAt'] as num?)?.toInt();
          if (_qqRe.hasMatch(qq) && _isCurrentToken(authToken)) {
            return AwmcForumOAuthPollResult(
              status: AwmcForumOAuthPollStatus.completed,
              qq: qq,
              username: username,
              xfUserId: xfUserId,
              authToken: authToken,
              tokenExpiresAt: tokenExpiresAt,
            );
          }
          return const AwmcForumOAuthPollResult(
            status: AwmcForumOAuthPollStatus.failed,
            error: '授权响应未包含有效的账号会话，请重新授权',
          );
        }
        if (status == 'failed') {
          return AwmcForumOAuthPollResult(
            status: AwmcForumOAuthPollStatus.failed,
            error: _extractErrorMessage(data) ?? 'AWMC 论坛授权失败，请重试',
          );
        }
        return const AwmcForumOAuthPollResult(
          status: AwmcForumOAuthPollStatus.pending,
        );
      }
      // 临时网络抖动或 5xx 时保持 pending，避免切回应用瞬间误中断等待。
      return const AwmcForumOAuthPollResult(
        status: AwmcForumOAuthPollStatus.pending,
      );
    } catch (e) {
      debugPrint('轮询 AWMC 论坛 OAuth 状态异常: $e');
      return const AwmcForumOAuthPollResult(
        status: AwmcForumOAuthPollStatus.pending,
      );
    }
  }

  static Map<String, dynamic>? _tryDecodeMap(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = json.decode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String? _extractErrorMessage(Map<String, dynamic>? data) {
    if (data == null) return null;
    for (final key in const ['userMessage', 'message', 'error']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
