import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 网络连接类型检测工具。
class NetworkTypeUtil {
  NetworkTypeUtil._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.app/network_type',
  );

  /// 检测当前活跃网络是否仅走移动蜂窝数据；桌面端、Web 端或异常时安全返回 `false`。
  static Future<bool> isCellularNetwork() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('isCellularNetwork') ?? false;
    } catch (_) {
      return false;
    }
  }
}
