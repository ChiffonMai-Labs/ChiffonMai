import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<void> enterFullScreenImpl() async {
  // Android 的沉浸模式会把屏幕边缘手势用于唤出系统栏，改为保留系统导航。
  await Future.wait([
    SystemChrome.setEnabledSystemUIMode(
      defaultTargetPlatform == TargetPlatform.android
          ? SystemUiMode.edgeToEdge
          : SystemUiMode.immersiveSticky,
    ),
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  ]);
}

Future<void> exitFullScreenImpl() async {
  // Keep portrait locked after leaving fullscreen. Re-enabling landscape in
  // the same callback can happen before the platform has applied this request,
  // leaving the preview visibly stuck in landscape.
  await Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
  ]);
}
