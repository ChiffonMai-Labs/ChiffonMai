import 'package:shared_preferences/shared_preferences.dart';

/// 首次使用引导的版本化显示状态。
class OnboardingStateStore {
  OnboardingStateStore._();

  static final OnboardingStateStore instance = OnboardingStateStore._();

  // 协议确认加入后，旧的“完成/跳过”记录不能代替本次明确同意。
  static const int currentVersion = 3;
  static const String agreementVersion = '2026-10-25';
  static const String _completedVersionKey = 'onboarding_completed_version';
  static const String _agreementVersionKey = 'onboarding_agreement_version';
  static const String _agreedAtKey = 'onboarding_agreed_at';
  static const String _guardianConsentKey = 'onboarding_guardian_consent';

  Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedVersion = prefs.getInt(_completedVersionKey) ?? 0;
      return completedVersion < currentVersion ||
          prefs.getString(_agreementVersionKey) != agreementVersion ||
          prefs.getInt(_agreedAtKey) == null;
    } catch (_) {
      // 无法读取时宁可展示引导，也不要让用户错过关键入口说明。
      return true;
    }
  }

  Future<void> markCompleted({
    required bool accepted,
    required DateTime agreedAt,
    bool guardianConsent = false,
  }) async {
    if (!accepted) throw StateError('请先阅读并同意用户协议和隐私政策');
    final prefs = await SharedPreferences.getInstance();
    final saved = await Future.wait([
      prefs.setString(_agreementVersionKey, agreementVersion),
      prefs.setInt(_agreedAtKey, agreedAt.millisecondsSinceEpoch),
      prefs.setBool(_guardianConsentKey, guardianConsent),
    ]);
    if (saved.any((value) => !value) ||
        !await prefs.setInt(_completedVersionKey, currentVersion)) {
      throw StateError('无法保存引导确认记录，请重试');
    }
  }

  Future<void> clearForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedVersionKey);
    await prefs.remove(_agreementVersionKey);
    await prefs.remove(_agreedAtKey);
    await prefs.remove(_guardianConsentKey);
  }
}
