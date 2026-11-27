import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';

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
  final String? error;

  const AwmcForumOAuthPollResult({
    required this.status,
    this.qq = '',
    this.username = '',
    this.xfUserId = '',
    this.error,
  });
}

/// AWMC 论坛（bbs.wmc.pub）OAuth 2.0 + PKCE 客户端管理器。
///
/// 流程：App 调用后端 `/api/awmc/oauth/start` 取得授权链接 → 系统浏览器完成论坛授权并回调至
/// `https://chiffonmai.cloud/api/awmc/oauth/callback` → 后端换票并提取 `数字@qq.com` 对应 QQ
/// → App 轮询 `/api/awmc/oauth/status` 获取绑定 QQ（论坛 token 仅在后端瞬时使用，不落盘）。
class AwmcForumOAuthManager {
  AwmcForumOAuthManager._();

  static final AwmcForumOAuthManager instance = AwmcForumOAuthManager._();

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
      final uri = Uri.parse(ApiUrls.AwmcOAuthStatusUrl)
          .replace(queryParameters: {'sessionId': sessionId});
      final response = await ApiClient.get(
        uri,
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
          if (RegExp(r'^\d{5,12}$').hasMatch(qq)) {
            return AwmcForumOAuthPollResult(
              status: AwmcForumOAuthPollStatus.completed,
              qq: qq,
              username: username,
              xfUserId: xfUserId,
            );
          }
          return const AwmcForumOAuthPollResult(
            status: AwmcForumOAuthPollStatus.failed,
            error: '授权响应缺少有效 QQ 号，请重试',
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
