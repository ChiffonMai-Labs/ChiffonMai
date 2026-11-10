import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

/// 上分潜力与达成率-得分对照表的分段方式。
enum RatingSegmentMode {
  /// 只用评级对应的标准达成率分段。
  standard,

  /// 在标准分段之外，反查每提升 1 Rating 需要的达成率。
  detailed,
}

/// 分段方式偏好，首次安装默认 [RatingSegmentMode.standard]。
class RatingSegmentPreferences extends ChangeNotifier {
  RatingSegmentPreferences._();
  static final instance = RatingSegmentPreferences._();

  RatingSegmentMode _mode = RatingSegmentMode.standard;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future<void>.value();

  RatingSegmentMode get mode => _mode;
  bool get isDetailed => _mode == RatingSegmentMode.detailed;
  bool get loaded => _loaded;

  Future<void> load() =>
      _loaded ? Future<void>.value() : (_loading ??= _load());

  Future<void> reload() async {
    await _loading;
    await _writes;
    _loaded = false;
    _loading = null;
    _mode = RatingSegmentMode.standard;
    await load();
  }

  Future<void> flush() => _writes;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mode = prefs.getString(CacheKeyConstant.ratingSegmentMode) ==
              RatingSegmentMode.detailed.name
          ? RatingSegmentMode.detailed
          : RatingSegmentMode.standard;
    } catch (error) {
      debugPrint('读取分段方式偏好失败: $error');
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setMode(RatingSegmentMode mode) async {
    await load();
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    // 内存立即更新，写盘串行执行，快速切换时最后一次选择仍能正确保存。
    _writes = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CacheKeyConstant.ratingSegmentMode, mode.name);
    }).catchError((Object error) {
      debugPrint('保存分段方式偏好失败: $error');
    });
    await _writes;
  }
}
