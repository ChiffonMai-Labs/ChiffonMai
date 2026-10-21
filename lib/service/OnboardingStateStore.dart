import 'package:shared_preferences/shared_preferences.dart';

/// 首次使用引导的版本化显示状态。
class OnboardingStateStore {
  OnboardingStateStore._();

  static final OnboardingStateStore instance = OnboardingStateStore._();

  // 权限设置页加入后，已有用户需要重新看到一次完整引导。
  static const int currentVersion = 2;
  static const String _completedVersionKey = 'onboarding_completed_version';

  Future<bool> shouldShow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedVersion = prefs.getInt(_completedVersionKey) ?? 0;
      return completedVersion < currentVersion;
    } catch (_) {
      // 无法读取时宁可展示引导，也不要让用户错过关键入口说明。
      return true;
    }
  }

  Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_completedVersionKey, currentVersion);
    } catch (_) {}
  }

  Future<void> clearForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedVersionKey);
  }
}
