import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:convert';

/// 从上游 429 响应中提取配额恢复提示，避免客户端只显示笼统的“稍后重试”。
String quotaRetryHint(String body) {
  final fallback = appL10n.flowWaitForRetryAfterSecondsOrQuotaResetAtBefore;
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
      ? appL10n.flowRetryAfterSecondsP0S((retry.round()).toString())
      : 'retryAfterSeconds';
  final resetText = reset is String && reset.trim().isNotEmpty
      ? 'quota.resetAt（${reset.trim()}）'
      : 'quota.resetAt';
  if (retry == null && reset == null) return fallback;
  return appL10n.flowRetryAfterP0OrP1((retryText).toString(), (resetText).toString());
}
