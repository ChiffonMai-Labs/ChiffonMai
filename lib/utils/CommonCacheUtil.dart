import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../service/GuessChartGame/GuessChartSettingsStore.dart';

class CommonCacheUtil {
  static final CommonCacheUtil _instance = CommonCacheUtil._internal();
  factory CommonCacheUtil() => _instance;
  CommonCacheUtil._internal()
      : _storage = GuessChartSettingsStore(),
        _now = DateTime.now;

  @visibleForTesting
  CommonCacheUtil.forTesting({
    required GuessChartSettingsStore storage,
    DateTime Function()? now,
  })  : _storage = storage,
        _now = now ?? DateTime.now;

  static const String _prefix = 'guess_song_';
  static const String _dateKey = 'last_reset_date';
  static const String _correctKey = 'correct_count';
  static const String _wrongKey = 'wrong_count';
  static const String _accuracyKey = 'accuracy';
  static const String _avgTimeKey = 'average_time';
  static const String _totalTimeKey = 'total_time';
  static const String _streakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';
  static const _fields = [
    _dateKey,
    _correctKey,
    _wrongKey,
    _accuracyKey,
    _avgTimeKey,
    _totalTimeKey,
    _streakKey,
    _bestStreakKey,
  ];

  final GuessChartSettingsStore _storage;
  final DateTime Function() _now;
  final _snapshots = <String, Map<String, Object>>{};
  final _loading = <String, Future<void>>{};
  Future<void> _pending = Future<void>.value();

  Future<void> flush() => _pending;

  Future<void> reload() async {
    await _pending;
    await Future.wait(_loading.values.toList());
    _snapshots.clear();
    _loading.clear();
  }

  String _key(String gameId, String field) => '$_prefix${gameId}_$field';
  String _today() => DateFormat('yyyy-MM-dd').format(_now());

  Map<String, Object> _empty() => {
        _dateKey: _today(),
        _correctKey: 0,
        _wrongKey: 0,
        _totalTimeKey: 0,
        _streakKey: 0,
        _bestStreakKey: 0,
      };

  Map<String, dynamic> _view(Map<String, Object> snapshot) {
    final correct = snapshot[_correctKey] as int;
    final wrong = snapshot[_wrongKey] as int;
    final total = correct + wrong;
    return {
      'correct': correct,
      'wrong': wrong,
      'accuracy': total == 0 ? 0.0 : correct / total * 100,
      'avgTime': total == 0 ? 0.0 : (snapshot[_totalTimeKey] as int) / total,
      'streak': snapshot[_streakKey],
      'bestStreak': snapshot[_bestStreakKey],
    };
  }

  Future<void> _load(String gameId) async {
    final stored = await _storage.read({
      for (final field in _fields) _key(gameId, field),
    });
    _snapshots[gameId] = {
      _dateKey: stored[_key(gameId, _dateKey)] as String? ?? '',
      for (final field in [
        _correctKey,
        _wrongKey,
        _totalTimeKey,
        _streakKey,
        _bestStreakKey,
      ])
        field: stored[_key(gameId, field)] as int? ?? 0,
    };
  }

  Future<void> _ready(String gameId) async {
    if (!_snapshots.containsKey(gameId)) {
      final loading = _loading.putIfAbsent(gameId, () => _load(gameId));
      try {
        await loading;
      } finally {
        if (identical(_loading[gameId], loading)) _loading.remove(gameId);
      }
    }
    if (_snapshots[gameId]![_dateKey] != _today()) {
      final snapshot = _empty();
      _snapshots[gameId] = snapshot;
      unawaited(_save(gameId, snapshot));
    }
  }

  /// 只串行化持久化，结算与读数使用内存快照，不等待前一局写盘。
  Future<void> _save(String gameId, Map<String, Object> snapshot) {
    final stats = _view(snapshot);
    final values = {
      for (final entry in snapshot.entries)
        _key(gameId, entry.key): entry.value,
      _key(gameId, _accuracyKey): stats['accuracy'] as double,
      _key(gameId, _avgTimeKey): stats['avgTime'] as double,
    };
    // 复用设置存储的 Android apply() 路径，避免大偏好文件的同步写盘阻塞帧绘制。
    final task = _pending.then((_) => _storage.write(values));
    _pending = task.then<void>((_) {}, onError: (Object error, StackTrace _) {
      debugPrint('[GuessStats] 统计保存失败，保留内存结果：$error');
    });
    return task;
  }

  Future<void> initCache(String gameId) => _ready(gameId);

  /// 先发布完整结算快照，再保存；连胜按每日已结算对局统计，失败或投降清零。
  Future<void> recordGameResult(
    String gameId, {
    required bool isWon,
    required int timeUsedInSeconds,
    ValueChanged<Map<String, dynamic>>? onUpdated,
  }) async {
    await _ready(gameId);
    final current = _snapshots[gameId]!;
    final streak = isWon ? (current[_streakKey] as int) + 1 : 0;
    final best = current[_bestStreakKey] as int;
    final next = {
      ...current,
      _correctKey: (current[_correctKey] as int) + (isWon ? 1 : 0),
      _wrongKey: (current[_wrongKey] as int) + (isWon ? 0 : 1),
      _totalTimeKey: (current[_totalTimeKey] as int) +
          (timeUsedInSeconds < 0 ? 0 : timeUsedInSeconds),
      _streakKey: streak,
      _bestStreakKey: streak > best ? streak : best,
    };
    _snapshots[gameId] = next;
    final saving = _save(gameId, next);
    onUpdated?.call(_view(next));
    await saving;
  }

  Future<Map<String, dynamic>> getStats(String gameId) async {
    await _ready(gameId);
    return _view(_snapshots[gameId]!);
  }

  Future<void> resetStats(String gameId,
      {ValueChanged<Map<String, dynamic>>? onUpdated}) async {
    await _ready(gameId);
    final next = _empty();
    _snapshots[gameId] = next;
    final saving = _save(gameId, next);
    onUpdated?.call(_view(next));
    await saving;
  }
}
