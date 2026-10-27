import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/service/GuessChartGame/GuessChartSettingsStore.dart';
import 'package:my_first_flutter_app/utils/CommonCacheUtil.dart';

class _StatsStorage extends GuessChartSettingsStore {
  final values = <String, Object>{};
  final saved = <Map<String, Object>>[];
  Completer<void>? readGate, writeGate;
  final writeStarted = Completer<void>();
  int reads = 0;
  bool failNextWrite = false;

  @override
  Future<Map<String, Object?>> read(Set<String> keys) async {
    reads++;
    await readGate?.future;
    return {for (final key in keys) key: values[key]};
  }

  @override
  Future<void> write(Map<String, Object> changes) async {
    if (!writeStarted.isCompleted) writeStarted.complete();
    await writeGate?.future;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('测试写盘失败');
    }
    saved.add(Map.of(changes));
    values.addAll(changes);
  }
}

String _key(String game, String field) => 'guess_song_${game}_$field';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = DateTime(2026, 10, 27);
  late _StatsStorage storage;
  late CommonCacheUtil cache;

  setUp(() {
    storage = _StatsStorage();
    storage.values[_key('a', 'last_reset_date')] = '2026-10-27';
    cache = CommonCacheUtil.forTesting(storage: storage, now: () => today);
  });

  test('结算回调和读数不等待写盘，连续结算不会丢失，新实例能读取保存结果', () async {
    await cache.initCache('a');
    storage.writeGate = Completer<void>();
    final updated = Completer<Map<String, dynamic>>();
    var saved = false;
    final first = cache.recordGameResult('a',
        isWon: true, timeUsedInSeconds: 10, onUpdated: updated.complete)
      ..then((_) => saved = true);
    expect((await updated.future)['correct'], 1);
    await storage.writeStarted.future;
    expect(saved, false);
    expect((await cache.getStats('a'))['correct'], 1);

    final nextUpdated = Completer<Map<String, dynamic>>();
    final second = cache.recordGameResult('a',
        isWon: true, timeUsedInSeconds: 20, onUpdated: nextUpdated.complete);
    final next = await nextUpdated.future;
    expect(next['correct'], 2);
    expect(next['avgTime'], 15);
    expect(next['streak'], 2);
    expect((await cache.getStats('a'))['correct'], 2);

    storage.writeGate!.complete();
    await Future.wait([first, second]);
    final restarted =
        CommonCacheUtil.forTesting(storage: storage, now: () => today);
    expect(await restarted.getStats('a'), next);
  });

  test('写盘未完成时重置立即生效，随后新局不会被旧快照覆盖', () async {
    await cache.initCache('a');
    storage.writeGate = Completer<void>();
    final first =
        cache.recordGameResult('a', isWon: true, timeUsedInSeconds: 10);
    await storage.writeStarted.future;
    final resetUpdated = Completer<Map<String, dynamic>>();
    final reset = cache.resetStats('a', onUpdated: resetUpdated.complete);
    expect((await resetUpdated.future)['correct'], 0);
    final nextUpdated = Completer<Map<String, dynamic>>();
    final next = cache.recordGameResult('a',
        isWon: false, timeUsedInSeconds: 7, onUpdated: nextUpdated.complete);
    final stats = await nextUpdated.future;
    expect(stats['correct'], 0);
    expect(stats['wrong'], 1);
    expect(stats['streak'], 0);
    expect(stats['bestStreak'], 0);
    expect(stats['avgTime'], 7);
    storage.writeGate!.complete();
    await Future.wait([first, reset, next]);
    expect(
        storage.saved.map((row) => row[_key('a', 'correct_count')]), [1, 0, 0]);
    expect(storage.values[_key('a', 'wrong_count')], 1);
  });

  test('沿用旧存储键，统计快照与其它玩法相互隔离', () async {
    storage.values.addAll({
      _key('a', 'correct_count'): 2,
      _key('a', 'wrong_count'): 1,
      _key('a', 'total_time'): 30,
      _key('a', 'current_streak'): 1,
      _key('a', 'best_streak'): 2,
    });
    final stats = await cache.getStats('a');
    expect(stats['avgTime'], 10);
    expect(stats['accuracy'], closeTo(200 / 3, .00001));
    stats['correct'] = 999;
    expect((await cache.getStats('a'))['correct'], 2);
    expect((await cache.getStats('b'))['correct'], 0);
    await cache.recordGameResult('a', isWon: false, timeUsedInSeconds: -1);
    expect(storage.values[_key('a', 'correct_count')], 2);
    expect(storage.values[_key('a', 'wrong_count')], 2);
    expect(storage.values[_key('a', 'total_time')], 30);
    expect(storage.values[_key('a', 'current_streak')], 0);
    expect(storage.values[_key('a', 'best_streak')], 2);
  });

  test('跨日立即清空今日统计，旧日期的未完成写盘不能覆盖新一天', () async {
    var now = today;
    cache = CommonCacheUtil.forTesting(storage: storage, now: () => now);
    await cache.initCache('a');
    storage.writeGate = Completer<void>();
    final yesterday =
        cache.recordGameResult('a', isWon: true, timeUsedInSeconds: 20);
    await storage.writeStarted.future;
    now = DateTime(2026, 10, 28);
    expect((await cache.getStats('a'))['correct'], 0);
    final updated = Completer<Map<String, dynamic>>();
    final current = cache.recordGameResult('a',
        isWon: true, timeUsedInSeconds: 8, onUpdated: updated.complete);
    final stats = await updated.future;
    expect(stats['streak'], 1);
    expect(stats['bestStreak'], 1);
    expect(stats['avgTime'], 8);
    storage.writeGate!.complete();
    await Future.wait([yesterday, current]);
    expect(storage.values[_key('a', 'last_reset_date')], '2026-10-28');
    expect(storage.values[_key('a', 'correct_count')], 1);
  });

  test('写盘失败不回退已结算结果，下一次保存能补齐完整统计', () async {
    await cache.initCache('a');
    storage.failNextWrite = true;
    await expectLater(
        cache.recordGameResult('a', isWon: true, timeUsedInSeconds: 10),
        throwsStateError);
    expect((await cache.getStats('a'))['correct'], 1);
    await cache.recordGameResult('a', isWon: true, timeUsedInSeconds: 20);
    expect(storage.values[_key('a', 'correct_count')], 2);
    expect(storage.values[_key('a', 'average_time')], 15);
  });

  test('复用偏好存储后仍可读取旧统计并写回相同键与数值类型', () async {
    SharedPreferences.setMockInitialValues({
      _key('a', 'last_reset_date'): '2026-10-27',
      _key('a', 'correct_count'): 3,
      _key('a', 'wrong_count'): 1,
      _key('a', 'total_time'): 24,
      _key('a', 'current_streak'): 1,
      _key('a', 'best_streak'): 2,
    });
    final persisted = CommonCacheUtil.forTesting(
        storage: GuessChartSettingsStore(), now: () => today);
    expect((await persisted.getStats('a'))['avgTime'], 6);
    await persisted.recordGameResult('a', isWon: true, timeUsedInSeconds: 8);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(_key('a', 'correct_count')), 4);
    expect(prefs.getDouble(_key('a', 'accuracy')), 80);
    expect(prefs.getDouble(_key('a', 'average_time')), 6.4);
    expect(prefs.getInt(_key('a', 'total_time')), 32);
  });

  test('首次加载期间的多次结算与重置按调用顺序执行', () async {
    storage.readGate = Completer<void>();
    final first =
        cache.recordGameResult('a', isWon: true, timeUsedInSeconds: 10);
    final second =
        cache.recordGameResult('a', isWon: true, timeUsedInSeconds: 20);
    final reset = cache.resetStats('a');
    final next =
        cache.recordGameResult('a', isWon: false, timeUsedInSeconds: 5);
    storage.readGate!.complete();
    await Future.wait([first, second, reset, next]);
    expect(storage.reads, 1);
    final stats = await cache.getStats('a');
    expect(stats['correct'], 0);
    expect(stats['wrong'], 1);
    expect(stats['avgTime'], 5);
    expect(stats['streak'], 0);
    expect(stats['bestStreak'], 0);
  });
}
