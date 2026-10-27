import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NavigationBarStyle {
  standard,
  liquidGlass,
  expandingPill;

  String get label => switch (this) {
        standard => '经典悬浮',
        liquidGlass => '液态玻璃',
        expandingPill => '伸缩胶囊',
      };

  String get description => switch (this) {
        standard => '图标与文字上下排列，常驻显示全部分类名称',
        liquidGlass => '通透的玻璃质感，选中项带柔和高光',
        expandingPill => '选中项展开文字，其余项保留图标，切换时平滑伸缩',
      };
}

/// 主导航栏与系统栏的交互偏好。
///
/// 由 AppShell 和首页设置弹窗共同监听，保证修改后
/// 不需要重启应用就能立即看到效果。
class NavigationPreferences extends ChangeNotifier {
  NavigationPreferences._();

  static final NavigationPreferences instance = NavigationPreferences._();

  static const _transitionKey = 'navigation_transition_enabled';
  static const _swipeKey = 'navigation_swipe_enabled';
  static const _liquidGlassKey = 'navigation_liquid_glass_enabled';
  static const _barStyleKey = 'navigation_bar_style';
  static const _immersiveStatusBarKey = 'immersive_status_bar_enabled';
  static const _busyHintKey = 'hub_busy_hint_enabled';
  static const _systemUiChannel = MethodChannel('com.example.app/system_ui');

  bool _transitionEnabled = true;
  bool _swipeEnabled = true;
  NavigationBarStyle _barStyle = NavigationBarStyle.standard;
  bool _immersiveStatusBarEnabled = false;
  bool _busyHintEnabled = false;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _styleWrites = Future<void>.value();
  Future<void> _systemUiWrites = Future<void>.value();

  bool get transitionEnabled => _transitionEnabled;
  bool get swipeEnabled => _swipeEnabled;
  NavigationBarStyle get barStyle => _barStyle;
  bool get liquidGlassEnabled => _barStyle == NavigationBarStyle.liquidGlass;
  bool get immersiveStatusBarEnabled => _immersiveStatusBarEnabled;

  /// Hub 页在其它任务进行中时，是否在不可用入口下方显示红字原因提示。
  ///
  /// 默认**关闭**：任务进行中入口本来就会置灰、点击也点不动，红字属于补充说明，
  /// 不希望它默认占着版面。
  bool get busyHintEnabled => _busyHintEnabled;
  bool get loaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> reload() async {
    await _loading;
    await _styleWrites;
    _loaded = false;
    _loading = null;
    await load();
  }

  Future<void> flush() => _styleWrites;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _transitionEnabled = prefs.getBool(_transitionKey) ?? true;
      _swipeEnabled = prefs.getBool(_swipeKey) ?? true;
      final legacyStyle = (prefs.getBool(_liquidGlassKey) ?? false)
          ? NavigationBarStyle.liquidGlass
          : NavigationBarStyle.standard;
      final storedStyle = prefs.getString(_barStyleKey);
      _barStyle = NavigationBarStyle.values.firstWhere(
        (style) => style.name == storedStyle,
        orElse: () => legacyStyle,
      );
      _immersiveStatusBarEnabled =
          prefs.getBool(_immersiveStatusBarKey) ?? false;
      _busyHintEnabled = prefs.getBool(_busyHintKey) ?? false;
      await applySystemUiMode();
    } catch (_) {
      // 读取失败时保留默认值，不影响主界面启动。
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setTransitionEnabled(bool value) async {
    _transitionEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_transitionKey, value);
    } catch (_) {
      // 内存中的开关仍然生效，下次启动会回到默认值。
    }
  }

  Future<void> setSwipeEnabled(bool value) async {
    _swipeEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_swipeKey, value);
    } catch (_) {
      // 内存中的开关仍然生效，下次启动会回到默认值。
    }
  }

  Future<void> setLiquidGlassEnabled(bool value) => setBarStyle(
      value ? NavigationBarStyle.liquidGlass : NavigationBarStyle.standard);

  Future<void> setBarStyle(NavigationBarStyle value) async {
    if (!_loaded) await load();
    if (_barStyle == value) return;
    _barStyle = value;
    notifyListeners();
    // 内存立即更新，写盘串行；连续切换时最终保存最后一次选择。
    final write = _styleWrites.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_barStyleKey, value.name);
        // 保留旧键，旧版客户端仍可识别经典和玻璃两种样式。
        await prefs.setBool(
            _liquidGlassKey, value == NavigationBarStyle.liquidGlass);
      } catch (_) {
        // 写入失败时保留本次内存选择，下次启动按已保存的值恢复。
      }
    });
    _styleWrites = write;
    await write;
  }

  /// 应用当前的系统栏模式。
  ///
  /// 只隐藏顶部状态栏，保留底部系统导航，避免 immersiveSticky 抢走返回手势。
  /// targetSdk 36 下 Flutter 的 manual 模式不会生效，Android 由原生窗口
  /// 通道单独控制状态栏；其它平台保留原有系统栏行为。
  Future<void> applySystemUiMode() {
    // 模式切换与页面恢复可能同时发生；串行应用，且每次读取最新偏好。
    final result = _systemUiWrites.then((_) => _applySystemUiMode());
    _systemUiWrites = result;
    return result;
  }

  Future<void> _applySystemUiMode() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await _systemUiChannel.invokeMethod<void>(
        'setStatusBarHidden',
        {'hidden': _immersiveStatusBarEnabled},
      );
    } catch (error) {
      debugPrint('[SystemUI] 状态栏模式应用失败：$error');
    }
  }

  Future<void> setImmersiveStatusBarEnabled(bool value) async {
    _immersiveStatusBarEnabled = value;
    notifyListeners();
    await applySystemUiMode();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_immersiveStatusBarKey, value);
    } catch (_) {
      // 内存中的开关仍然生效，下次启动会回到默认值。
    }
  }

  Future<void> setBusyHintEnabled(bool value) async {
    if (_busyHintEnabled == value) return;
    _busyHintEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_busyHintKey, value);
    } catch (_) {
      // 内存中的开关仍然生效，下次启动按已保存的值恢复。
    }
  }
}
