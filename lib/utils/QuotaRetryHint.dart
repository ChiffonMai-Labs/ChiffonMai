import 'dart:convert';

/// 从上游 429 响应中提取配额恢复提示，避免客户端只显示笼统的“稍后重试”。
String quotaRetryHint(String body) {
  const fallback = '等待 retryAfterSeconds 或 quota.resetAt 后再重试';
  dynamic decoded;
  try {
    decoded = jsonDecode(body);
  } catch (_) {
    return fallback;
  }
  if (decoded is! Map) return fallback;

  final retry = decoded['retryAfterSeconds'];
  final quota = decoded['quota'];
  final reset = quota is Map ? quota['resetAt'] : null;
  final retryText = retry is num && retry.isFinite && retry >= 0
      ? 'retryAfterSeconds（${retry.round()} 秒）'
      : 'retryAfterSeconds';
  final resetText = reset is String && reset.trim().isNotEmpty
      ? 'quota.resetAt（${reset.trim()}）'
      : 'quota.resetAt';
  if (retry == null && reset == null) return fallback;
  return '等待 $retryText 或 $resetText 后再重试';
}
