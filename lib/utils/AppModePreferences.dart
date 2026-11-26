import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

/// 应用界面显示模式。
enum AppDisplayMode {
  /// 常规模式：展示全部 5 个主标签、概览卡片、背景装饰与完整功能列表。
  standard,

  /// 简洁模式：保留全部 5 个主标签，隐藏背景装饰、动效与冗余说明，合并游玩页分区并保持紧凑布局。
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

/// 向子树广播当前界面模式的轻量级作用域，避免几十个子组件各自监听偏好实例。
class AppModeScope extends InheritedWidget {
  final AppDisplayMode mode;

  const AppModeScope({
    super.key,
    required this.mode,
    required super.child,
  });

  /// 读取当前上下文是否为简洁模式；未挂载作用域时回落到全局偏好实例。
  static bool isSimpleOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppModeScope>();
    return (scope?.mode ?? AppModePreferences.instance.mode) ==
        AppDisplayMode.simple;
  }

  @override
  bool updateShouldNotify(AppModeScope oldWidget) => mode != oldWidget.mode;
}

/// 顶层全局模式提供器，放在路由之上统一驱动所有页面与弹窗。
class AppModeProvider extends StatelessWidget {
  final Widget child;

  const AppModeProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppModePreferences.instance,
      child: child,
      builder: (context, child) => AppModeScope(
        mode: AppModePreferences.instance.mode,
        child: child!,
      ),
    );
  }
}

/// 按可见性延迟同步模式的作用域：处于后台或离屏标签页时跳过重建，切回可见时再同步。
class DeferredAppModeScope extends StatefulWidget {
  final Widget child;

  const DeferredAppModeScope({super.key, required this.child});

  @override
  State<DeferredAppModeScope> createState() => _DeferredAppModeScopeState();
}

class _DeferredAppModeScopeState extends State<DeferredAppModeScope> {
  AppDisplayMode _mode = AppModePreferences.instance.mode;
  bool _active = false;

  @override
  void initState() {
    super.initState();
    AppModePreferences.instance.addListener(_onModeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    _active = active;
    if (active) {
      _mode = AppModePreferences.instance.mode;
    }
  }

  @override
  void dispose() {
    AppModePreferences.instance.removeListener(_onModeChanged);
    super.dispose();
  }

  void _onModeChanged() {
    if (!mounted || !_active) return;
    final next = AppModePreferences.instance.mode;
    if (_mode != next) {
      setState(() => _mode = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModeScope(
      mode: _mode,
      child: widget.child,
    );
  }
}
