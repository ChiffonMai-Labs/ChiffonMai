import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

/// 纸屑特效的彩纸形状。
enum ConfettiPaperType {
  mixed,
  square,
  circle,
  ribbon,
}

/// 纸屑从屏幕哪几侧进入。
enum ConfettiBurstPosition {
  topBottom,
  leftRight,
  allEdges,
}

/// 纸屑特效偏好，供设置页和全局播放器共同使用。
class ConfettiPreferences extends ChangeNotifier {
  ConfettiPreferences._();

  static final ConfettiPreferences instance = ConfettiPreferences._();

  bool _enabled = true;
  bool _gravityEnabled = true;
  Color? _harmonyColor;
  double _harmonyLevel = 0.35;
  ConfettiPaperType _paperType = ConfettiPaperType.mixed;
  ConfettiBurstPosition _position = ConfettiBurstPosition.allEdges;
  bool _loaded = false;
  Future<void>? _loadFuture;

  bool get enabled => _enabled;
  bool get gravityEnabled => _gravityEnabled;
  Color? get harmonyColor => _harmonyColor;
  double get harmonyLevel => _harmonyLevel;
  ConfettiPaperType get paperType => _paperType;
  ConfettiBurstPosition get position => _position;
  bool get loaded => _loaded;

  Future<void> load() {
    if (_loaded) return Future<void>.value();
    final activeLoad = _loadFuture;
    if (activeLoad != null) return activeLoad;
    final future = _loadInternal();
    _loadFuture = future;
    return future.whenComplete(() => _loadFuture = null);
  }

  Future<void> reload() async {
    await _loadFuture;
    _loaded = false;
    await load();
  }

  Future<void> _loadInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(CacheKeyConstant.confettiEnabled) ?? true;
      _gravityEnabled =
          prefs.getBool(CacheKeyConstant.confettiGravityEnabled) ?? true;
      final colorValue = prefs.getInt(CacheKeyConstant.confettiHarmonyColor);
      _harmonyColor = colorValue == null ? null : Color(colorValue);
      _harmonyLevel =
          (prefs.getDouble(CacheKeyConstant.confettiHarmonyLevel) ?? 0.35)
              .clamp(0.0, 1.0);
      _paperType =
          _parsePaperType(prefs.getString(CacheKeyConstant.confettiPaperType));
      _position =
          _parsePosition(prefs.getString(CacheKeyConstant.confettiPosition));
    } catch (_) {
      // 读取失败时保留默认值，不影响页面和主流程使用。
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeyConstant.confettiEnabled, value);
    } catch (_) {}
  }

  Future<void> setGravityEnabled(bool value) async {
    if (_gravityEnabled == value) return;
    _gravityEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(CacheKeyConstant.confettiGravityEnabled, value);
    } catch (_) {}
  }

  Future<void> setHarmonyColor(Color? color) async {
    _harmonyColor = color;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (color == null) {
        await prefs.remove(CacheKeyConstant.confettiHarmonyColor);
      } else {
        await prefs.setInt(
            CacheKeyConstant.confettiHarmonyColor, color.toARGB32());
      }
    } catch (_) {}
  }

  Future<void> setHarmonyLevel(double value) async {
    _harmonyLevel = value.clamp(0.0, 1.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(
          CacheKeyConstant.confettiHarmonyLevel, _harmonyLevel);
    } catch (_) {}
  }

  Future<void> setPaperType(ConfettiPaperType value) async {
    if (_paperType == value) return;
    _paperType = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CacheKeyConstant.confettiPaperType, value.name);
    } catch (_) {}
  }

  Future<void> setPosition(ConfettiBurstPosition value) async {
    if (_position == value) return;
    _position = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CacheKeyConstant.confettiPosition, value.name);
    } catch (_) {}
  }

  ConfettiPaperType _parsePaperType(String? value) {
    return ConfettiPaperType.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ConfettiPaperType.mixed,
    );
  }

  ConfettiBurstPosition _parsePosition(String? value) {
    return ConfettiBurstPosition.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ConfettiBurstPosition.allEdges,
    );
  }
}
