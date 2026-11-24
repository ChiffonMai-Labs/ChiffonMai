import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

/// 应用界面显示模式。
enum AppDisplayMode {
  /// 常规模式：展示全部 5 个主标签、概览卡片、背景装饰与完整功能列表。
  standard,

  /// 简洁模式：精简为 3 个核心标签，收敛视觉装饰并折叠低频功能。
  simple,
}

/// 界面模式偏好，默认 [AppDisplayMode.standard]。
///
/// 简洁模式只在展示层收敛信息与装饰，不覆盖常规模式下的背景图、
/// 透明度、纸屑特效和收藏配置；切回常规模式后原样恢复。
class AppModePreferences extends ChangeNotifier {
  AppModePreferences._();
  static final AppModePreferences instance = AppModePreferences._();

  AppDisplayMode _mode = AppDisplayMode.standard;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future<void>.value();

  AppDisplayMode get mode => _mode;
  bool get isSimple => _mode == AppDisplayMode.simple;
  bool get loaded => _loaded;

  Future<void> load() =>
      _loaded ? Future<void>.value() : (_loading ??= _load());

  Future<void> reload() async {
    await _loading;
    await _writes;
    _loaded = false;
    _loading = null;
    _mode = AppDisplayMode.standard;
    await load();
  }

  Future<void> flush() => _writes;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = prefs.getString(CacheKeyConstant.appDisplayMode) ==
              AppDisplayMode.simple.name
          ? AppDisplayMode.simple
          : AppDisplayMode.standard;
    } catch (error) {
      debugPrint('读取界面模式偏好失败: $error');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setMode(AppDisplayMode mode) async {
    await load();
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    // 内存立即更新，写盘串行执行，快速切换时最终保留最后一次选择。
    _writes = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CacheKeyConstant.appDisplayMode, mode.name);
    }).catchError((Object error) {
      debugPrint('保存界面模式偏好失败: $error');
    });
    await _writes;
  }
}
