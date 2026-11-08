import 'package:flutter/foundation.dart';

/// 会读写用户数据的长任务。自动安装等待这些任务全部结束后才开始空闲计时。
class AppTaskActivity {
  AppTaskActivity._();
  static final ValueNotifier<int> _count = ValueNotifier(0);
  static ValueListenable<int> get count => _count;

  /// 返回可重复调用的结束回调，适用于异步任务及排队的导出操作。
  static VoidCallback begin() {
    var finished = false;
    _count.value++;
    return () {
      if (finished) return;
      finished = true;
      _count.value--;
    };
  }

  static Future<T> run<T>(Future<T> Function() action) async {
    final finish = begin();
    try {
      return await action();
    } finally {
      finish();
    }
  }
}
