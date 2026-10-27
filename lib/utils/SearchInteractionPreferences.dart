import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

enum SearchInteractionMode { inline, overlay }

/// 首页功能搜索与歌曲搜索共用的交互偏好。
class SearchInteractionPreferences extends ChangeNotifier {
  SearchInteractionPreferences._();
  static final instance = SearchInteractionPreferences._();

  SearchInteractionMode _mode = SearchInteractionMode.overlay;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future<void>.value();
  SearchInteractionMode get mode => _mode;
  bool get usesOverlay => _mode == SearchInteractionMode.overlay;
  bool get loaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> reload() async {
    await _loading;
    await _writes;
    _loaded = false;
    _loading = null;
    await load();
  }

  Future<void> flush() => _writes;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode =
          prefs.getString(CacheKeyConstant.searchInteractionMode) == 'inline'
              ? SearchInteractionMode.inline
              : SearchInteractionMode.overlay;
    } catch (error) {
      debugPrint('读取搜索框交互偏好失败: $error');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setMode(SearchInteractionMode mode) async {
    await load();
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    // 内存立即更新，写盘串行执行，快速切换时最后一次选择仍能正确保存。
    _writes = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CacheKeyConstant.searchInteractionMode, mode.name);
    }).catchError((Object error) {
      debugPrint('保存搜索框交互偏好失败: $error');
    });
    await _writes;
  }
}
