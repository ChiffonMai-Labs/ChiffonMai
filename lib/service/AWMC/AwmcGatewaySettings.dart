import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/CacheKeyConstant.dart';

/// AWMC 网关「同步前探活」的参数。
///
/// 线路1 在真正推送成绩前会先请求一次 `GET /v1/health`：超过这里设置的时间
/// 就视为网关不可用、直接取消同步（不消耗 Token）。默认 15 秒，
/// 用户可以在设置页「同步与网关」里自定义。
class AwmcGatewaySettings {
  AwmcGatewaySettings._();

  /// 默认探活超时（秒）。
  static const int defaultProbeTimeoutSeconds = 15;

  /// 允许用户设置的范围（秒）：太小容易把慢一点但可用的网关判死，
  /// 太大则用户要干等很久才能知道网关挂了。
  static const int minProbeTimeoutSeconds = 5;
  static const int maxProbeTimeoutSeconds = 60;

  static int clampSeconds(int seconds) {
    if (seconds < minProbeTimeoutSeconds) return minProbeTimeoutSeconds;
    if (seconds > maxProbeTimeoutSeconds) return maxProbeTimeoutSeconds;
    return seconds;
  }

  /// 读取探活超时（秒）；未设置或越界时回落到默认/合法值。
  static Future<int> loadProbeTimeoutSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(CacheKeyConstant.awmcGatewayProbeTimeoutSeconds);
    return saved == null ? defaultProbeTimeoutSeconds : clampSeconds(saved);
  }

  static Future<void> saveProbeTimeoutSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      CacheKeyConstant.awmcGatewayProbeTimeoutSeconds,
      clampSeconds(seconds),
    );
  }

  /// 直接传给 [AwmcApiService.health] 的超时。
  static Future<Duration> loadProbeTimeout() async =>
      Duration(seconds: await loadProbeTimeoutSeconds());
}
