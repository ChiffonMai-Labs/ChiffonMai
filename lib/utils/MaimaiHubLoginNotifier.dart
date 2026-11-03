import 'package:flutter/foundation.dart';

/// maimai Score Hub 登录状态。
///
/// 主导航的标签页一直挂着，只在 initState 读一次的话，别的页面（结算画面识别、
/// 线路 2 同步）登录后「我的」页不会更新，所以登录态变化都从这里广播。
class MaimaiHubLoginNotifier {
  MaimaiHubLoginNotifier._();

  static final ValueNotifier<bool> instance = ValueNotifier(false);
}
