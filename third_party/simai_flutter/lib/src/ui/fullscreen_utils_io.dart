import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 平板 / 折叠屏展开态断点：最短边不短于 600 个逻辑像素。
///
/// 只按 `shortestSide` 判断，不看型号：iPhone Pro Max 横屏 956 宽、
/// 短边 440，仍然算手机，全屏时照常强制横屏。
bool get isWideScreenLayout {
  final view = WidgetsBinding.instance.platformDispatcher.implicitView;
  if (view == null) return false;
  final size = view.physicalSize / view.devicePixelRatio;
  return size.shortestSide >= 600;
}

Future<void> enterFullScreenImpl() async {
  // Android 的沉浸模式会把屏幕边缘手势用于唤出系统栏，改为保留系统导航。
  final mode = defaultTargetPlatform == TargetPlatform.android
      ? SystemUiMode.edgeToEdge
      : SystemUiMode.immersiveSticky;
  if (isWideScreenLayout) {
    // 宽屏方向本来就自由，只切系统栏，不强制横屏。
    await SystemChrome.setEnabledSystemUIMode(mode);
    return;
  }
  await Future.wait([
    SystemChrome.setEnabledSystemUIMode(mode),
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]),
  ]);
}

Future<void> exitFullScreenImpl() async {
  // 宽屏退出只复原沉浸；方向交给宿主按当前断点恢复，不锁 portraitUp。
  // 窄屏必须锁回竖屏：全屏按钮是手机唯一的横屏入口。
  final restoreOrientation = isWideScreenLayout
      ? null
      : SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Future.wait([
    ?restoreOrientation,
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
  ]);
}
