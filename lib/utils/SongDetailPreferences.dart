import 'dart:async';
import 'dart:convert';

import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ChartDifficulty.dart';

typedef RememberedSongDifficulty = ({String title, String type, int index});

/// 保存歌曲详情的默认难度和各歌曲上次浏览的难度。
class SongDetailPreferences extends ChangeNotifier {
  SongDetailPreferences._();
  static final instance = SongDetailPreferences._();
  static const _key = 'song_detail_default_difficulty';
  static const _memoryKey = 'song_detail_difficulty_memory';

  int _difficulty = ChartDifficulty.master;
  bool _loaded = false;
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  String? _error;
  bool _rememberEnabled = false;
  bool _memorySaveFailed = false;
  int _memoryRevision = 0;
  final _remembered = <String, RememberedSongDifficulty>{};

  int get difficulty => _difficulty;
  bool get loaded => _loaded;
  String? get error => _error;
  bool get rememberEnabled => _rememberEnabled;
  bool get memorySaveFailed => _memorySaveFailed;
  Map<String, RememberedSongDifficulty> get remembered =>
      Map.unmodifiable(_remembered);

  Future<void> flush() => _writes;

  Future<void> reload() async {
    await _loading;
    await _writes;
    _loaded = false;
    _loading = null;
    _difficulty = ChartDifficulty.master;
    _error = null;
    _rememberEnabled = false;
    _memorySaveFailed = false;
    _remembered.clear();
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
      final raw = prefs.getString(_memoryKey);
      if (raw != null) {
        final memory = jsonDecode(raw);
        if (memory is Map<String, dynamic>) {
          _rememberEnabled = memory['enabled'] == true;
          final songs = memory['songs'];
          if (songs is Map<String, dynamic>) {
            for (final MapEntry(key: songId, value: song) in songs.entries) {
              if (songId.isEmpty || song is! Map<String, dynamic>) continue;
              final index = ChartDifficulty.parseStandardIndex(song['index']);
              if (index == null) continue;
              _remembered[songId] = (
                title: song['title']?.toString() ?? songId,
                type: song['type']?.toString() ?? '',
                index: index,
              );
            }
          }
        }
      }
    } catch (_) {
      // 读盘失败时仍以 MASTER 开始，不阻塞歌曲详情。
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  int openingDifficulty(
    String songId, {
    required int chartCount,
    int? specified,
    bool isUtage = false,
  }) {
    if (chartCount <= 0) return ChartDifficulty.basic;
    if (specified != null && ChartDifficulty.isStandard(specified)) {
      return specified.clamp(0, chartCount - 1);
    }
    final rememberedIndex =
        _rememberEnabled ? _remembered[songId]?.index : null;
    if (rememberedIndex != null && rememberedIndex < chartCount) {
      return rememberedIndex;
    }
    return isUtage
        ? ChartDifficulty.basic
        : _difficulty.clamp(0, chartCount - 1);
  }

  Future<void> setRememberEnabled(bool enabled) async {
    if (!_loaded) await load();
    if (_rememberEnabled == enabled && !_memorySaveFailed) return;
    _rememberEnabled = enabled;
    await _saveDifficultyMemory();
  }

  Future<void> rememberDifficulty(
      String songId, RememberedSongDifficulty song) async {
    if (!_loaded) await load();
    if (!_rememberEnabled ||
        songId.isEmpty ||
        !ChartDifficulty.isStandard(song.index)) return;
    if (_remembered[songId] == song) return;
    _remembered.remove(songId);
    _remembered[songId] = song;
    await _saveDifficultyMemory(deferNotification: true);
  }

  Future<void> clearRememberedDifficulties(Set<String> songIds) async {
    if (!_loaded) await load();
    for (final songId in songIds) {
      _remembered.remove(songId);
    }
    await _saveDifficultyMemory();
  }

  Future<void> retryMemorySave() => _saveDifficultyMemory();

  Future<void> _saveDifficultyMemory({bool deferNotification = false}) {
    final revision = ++_memoryRevision;
    final snapshot = jsonEncode({
      'enabled': _rememberEnabled,
      'songs': _remembered.map((id, song) => MapEntry(id, {
            'title': song.title,
            'type': song.type,
            'index': song.index,
          })),
    });
    _memorySaveFailed = false;
    _writes = _writes.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setString(_memoryKey, snapshot)) {
          throw StateError('保存难度记忆失败');
        }
      } catch (_) {
        if (revision != _memoryRevision) return;
        _memorySaveFailed = true;
        notifyListeners();
      }
    });
    // 离开歌曲页时可能正在卸载视图，下一轮再通知其他界面。
    if (deferNotification) {
      scheduleMicrotask(notifyListeners);
    } else {
      notifyListeners();
    }
    return _writes;
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
