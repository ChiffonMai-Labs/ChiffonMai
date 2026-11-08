import 'package:my_first_flutter_app/l10n/AppMessages.dart';
/// 水鱼 OAuth 代理（/api/prober）返回的错误，用于区分「未授权需绑定」等场景。
class ProberException implements Exception {
  /// 错误码：CONSENT_REQUIRED / UNAUTHORIZED / FORBIDDEN / QUOTA_EXCEEDED / BIND_FAILED / UNKNOWN
  final String code;
  final String message;

  /// 需引导绑定时的授权链接（仅 CONSENT_REQUIRED 场景会携带）
  final String? bindingUrl;

  ProberException(this.code, this.message, {this.bindingUrl});

  static ProberException consentRequired({String? bindingUrl}) =>
      ProberException(
        'CONSENT_REQUIRED',
        appL10n.svcThisUserHasNotAuthorizedTheApp,
        bindingUrl: bindingUrl,
      );

  static ProberException unauthorized() =>
      ProberException('UNAUTHORIZED', appL10n.svcAuthenticationFailedTryAgain);

  static ProberException forbidden() =>
      ProberException('FORBIDDEN', appL10n.svcNoPermissionToAccessThisUserS);

  static ProberException quotaExceeded({String? retryHint}) => ProberException(
        'QUOTA_EXCEEDED',
        '${appL10n.svcTodaySQueryLimitHasBeenReached}'
            '${retryHint == null ? '' : '\n$retryHint'}',
      );

  static ProberException unknown(int statusCode) =>
      ProberException('UNKNOWN', appL10n.svcRequestFailedStatusCodeP0(statusCode.toString()));

  @override
  String toString() => message;
}
