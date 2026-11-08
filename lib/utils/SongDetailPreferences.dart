import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ChartDifficulty.dart';

/// 仅用于没有明确谱面难度的歌曲入口，首次使用默认 MASTER。
class SongDetailPreferences extends ChangeNotifier {
  SongDetailPreferences._();
  static final instance = SongDetailPreferences._();
  static const _key = 'song_detail_default_difficulty';

  int _difficulty = ChartDifficulty.master;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  String? _error;

  int get difficulty => _difficulty;
  bool get loaded => _loaded;
  String? get error => _error;

  Future<void> flush() => _writes;

  Future<void> reload() async {
    await _loading;
    await _writes;
    _loaded = false;
    _loading = null;
    _difficulty = ChartDifficulty.master;
    _error = null;
    await load();
  }

  Future<void> load() => _loaded ? Future.value() : (_loading ??= _load());

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_key);
      if (value != null &&
          value >= ChartDifficulty.basic &&
          value <= ChartDifficulty.master) _difficulty = value;
    } catch (_) {
      // 读盘失败时仍以 MASTER 开始，不阻塞歌曲详情。
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> setDifficulty(int value) async {
    if (value < ChartDifficulty.basic || value > ChartDifficulty.master) return;
    await load();
    if (_difficulty == value && _error == null) return;
    _difficulty = value;
    _error = null;
    notifyListeners();
    // 内存即时生效，连续点击的写盘按顺序完成，最后一次选择不会被旧值覆盖。
    _writes = _writes.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setInt(_key, value)) throw StateError('保存失败');
      } catch (_) {
        _error = appL10n.flowYourSelectionIsActiveButCouldNot;
        notifyListeners();
      }
    });
    await _writes;
  }
}
