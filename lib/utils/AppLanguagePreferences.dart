import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  system(null, null),
  simplifiedChinese(Locale('zh'), '简体中文'),
  traditionalChinese(
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'), '繁體中文'),
  english(Locale('en'), 'English'),
  japanese(Locale('ja'), '日本語');

  const AppLanguage(this.locale, this.nativeName);
  final Locale? locale;
  final String? nativeName;
}

/// 设置页语言偏好。默认跟随系统，不支持的语言回落到简体中文。
class AppLanguagePreferences extends ChangeNotifier {
  AppLanguagePreferences._();
  static final instance = AppLanguagePreferences._();
  static const _key = 'app_language';
  AppLanguage _language = AppLanguage.system;
  AppLanguage _savedLanguage = AppLanguage.system;
  int _revision = 0;
  AppLanguage get language => _language;
  Locale? get locale => _language.locale;
  bool loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future.value();

  Future<void> load() => loaded ? Future.value() : (_loading ??= _load());

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_key);
      _language = AppLanguage.values.firstWhere((value) => value.name == stored,
          orElse: () => AppLanguage.system);
      _savedLanguage = _language;
    } catch (error) {
      debugPrint('读取语言偏好失败: $error');
    } finally {
      loaded = true;
      notifyListeners();
    }
  }

  Future<bool> setLanguage(AppLanguage value) async {
    await load();
    if (value == _language) return true;
    final revision = ++_revision;
    _language = value;
    notifyListeners();
    var saved = true;
    _writes = _writes.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setString(_key, value.name)) throw StateError(appL10n.svcSaveFailed);
        _savedLanguage = value;
      } catch (error) {
        saved = false;
        debugPrint('保存语言偏好失败: $error');
        // 连续切换时，旧请求失败不能覆盖用户的新选择。
        if (_revision == revision) {
          _language = _savedLanguage;
          notifyListeners();
        }
      }
    });
    await _writes;
    unawaited(_refreshNativeText());
    return saved;
  }

  Future<void> flush() => _writes;

  Future<void> reload() async {
    await _loading;
    await _writes;
    loaded = false;
    _loading = null;
    _language = AppLanguage.system;
    await load();
    unawaited(_refreshNativeText());
  }

  /// 只重绘原生可见文字，不重启应用，也不改变小组件的点击标识。
  Future<void> _refreshNativeText() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await const MethodChannel('com.example.app/home_widget')
          .invokeMethod<void>('refreshLanguage');
    } catch (_) {
      // 其它宿主或旧原生端不支持时，Flutter 语言切换仍然生效。
    }
  }

  static Locale resolveLocales(
      List<Locale>? locales, Iterable<Locale> supported) {
    for (final locale in locales ?? const <Locale>[]) {
      if (locale.languageCode == 'zh') {
        final traditional = locale.scriptCode == 'Hant' ||
            (locale.scriptCode != 'Hans' &&
                const ['TW', 'HK', 'MO'].contains(locale.countryCode));
        return traditional
            ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
            : const Locale('zh');
      }
      if (locale.languageCode == 'en' || locale.languageCode == 'ja') {
        return Locale(locale.languageCode);
      }
    }
    return const Locale('zh');
  }
}
