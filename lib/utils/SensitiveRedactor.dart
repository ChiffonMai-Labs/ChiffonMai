/// 敏感信息脱敏工具：统一保护客户端错误展示、剪贴板诊断包、内存记录与导出日志。
class SensitiveRedactor {
  SensitiveRedactor._();

  static final RegExp _qrRegex = RegExp(r'SGWCMAID[A-Za-z0-9]+');
  static final RegExp _prefixedSecretRegex =
      RegExp(r'\b(?:gw_[A-Za-z0-9_.-]+|(?:sk|pk)_[A-Za-z0-9_-]{6,})');
  static final RegExp _jwtRegex =
      RegExp(r'\beyJ[A-Za-z0-9_-]{6,}(?:\.[A-Za-z0-9_-]+){1,2}');
  static final RegExp _bearerRegex =
      RegExp(r'\bBearer\s+[^\s,;}"\x27]+', caseSensitive: false);
  static final RegExp _dsnAuthRegex =
      RegExp(r'([a-zA-Z][a-zA-Z0-9+.-]*://)([^:\s/@]+):([^@\s/]+)@');
  static final RegExp _querySecretRegex = RegExp(
    r'([?&](?:token|code|secret|key|api[_-]?key|access_token|refresh_token|import[_-]?token|password|passwd)=)[^&\s#]+',
    caseSensitive: false,
  );
  static final RegExp _kvSecretRegex = RegExp(
    r'((?:password|passwd|token|authorization|cookie|api[_-]?key|import[_-]?token|x-prober-key|x-client-key|x-admin-key|x-auto-sync-token|client_secret|secret|refresh_token|access_token)["\x27]?\s*[:=]\s*["\x27]?)[^\s,;}"\x27]+',
    caseSensitive: false,
  );
  static final RegExp _stackFrameRegex =
      RegExp(r'^\s*(?:#\d+\b|package:|dart:)');
  // 保留 cm-xxx 与 req:xxx 等短请求标识，隐藏其余 32 位以上高熵串。
  static final RegExp _longOpaqueTokenRegex =
      RegExp(r'\b(?!cm-[A-Za-z0-9-]+)[A-Za-z0-9_-]{32,}\b');

  /// 对任意文本中的敏感凭据进行脱敏；保留调用栈帧与 `cm-` 请求编号以便定位。
  static String redact(String input) {
    if (input.isEmpty) return input;
    final safe = input
        .replaceAll(_qrRegex, '[二维码已隐藏]')
        .replaceAll(_prefixedSecretRegex, '[凭据已隐藏]')
        .replaceAll(_jwtRegex, '[JWT已隐藏]')
        .replaceAll(_bearerRegex, 'Bearer [已隐藏]')
        .replaceAllMapped(_dsnAuthRegex, (m) => '${m[1]}[用户已隐藏]:[密码已隐藏]@')
        .replaceAllMapped(_querySecretRegex, (m) => '${m[1]}[已隐藏]')
        .replaceAllMapped(_kvSecretRegex, (m) => '${m[1]}[已隐藏]');

    return safe.split('\n').map((line) {
      if (_stackFrameRegex.hasMatch(line)) return line;
      return line.replaceAll(_longOpaqueTokenRegex, '[长标识已隐藏]');
    }).join('\n');
  }

  /// 输出安全的 URL 摘要（仅含协议、主机、路径与脱敏后的参数）。
  static String redactUrl(Uri? uri) {
    if (uri == null) return '';
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    final base = '${uri.scheme}://${uri.host}$portPart${uri.path}';
    if (!uri.hasQuery) return base;
    return redact('$base?${uri.query}');
  }

  /// 只保留前 6 位 + 长度，用于 UI 展示或状态摘要。
  static String maskSecret(String? secret) {
    if (secret == null || secret.isEmpty) return '(未设置)';
    if (secret.length <= 8) return '****(len=${secret.length})';
    return '${secret.substring(0, 6)}****(len=${secret.length})';
  }
}
