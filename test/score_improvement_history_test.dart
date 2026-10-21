import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/service/History/ChartHistoryStore.dart';
import 'package:my_first_flutter_app/service/History/ScoreImprovementCore.dart';

Map<String, dynamic> score({
  int id = 1466,
  double achievement = 99,
  int dx = 2700,
  String fc = '',
  String fs = '',
  int rating = 300,
  double ds = 14,
}) =>
    {
      'song_id': id,
      'level_index': 3,
      'type': 'DX',
      'title': '群青讃歌',
      'level': '14',
      'ds': ds,
      'achievements': achievement,
      'dxScore': dx,
      'fc': fc,
      'fs': fs,
      'ra': rating,
    };

int at(int day, [int hour = 10]) =>
    DateTime(2026, 10, day, hour).millisecondsSinceEpoch;

void main() {
  test('首次建基线；重复刷新及浮点尾差不生成历史', () {
    final history = ScoreImprovementHistory();
    history.record([score()], atMs: at(17));
    history.record([score(achievement: 99.00000001)], atMs: at(17, 11));
    history.record([score()], atMs: at(18));
    expect(history.daily, isEmpty);
    expect(history.current, hasLength(1));
  });

  test('升级后可用同账号旧缓存作基线，首轮刷新就能发现提升', () {
    final history = ScoreImprovementHistory();
    history.record([score(achievement: 100)],
        previousRecords: [score()], atMs: at(17));
    expect(history.daily.values.single.before!.achievement, 99);
    expect(history.daily.values.single.after.achievement, 100);
  });

  test('同日多次合并、七项指标都保留，跨日重新计算当天增量', () {
    final history = ScoreImprovementHistory();
    const maxScores = {'1466/3': 3000};
    history.record([score()], atMs: at(16), maxScores: maxScores);
    history.record([score(achievement: 100, dx: 2800, fc: 'fc', rating: 310)],
        atMs: at(17), maxScores: maxScores);
    final end =
        score(achievement: 100.5, dx: 2970, fc: 'app', fs: 'fsdp', rating: 315);
    history.record([end], atMs: at(17, 13), maxScores: maxScores);
    history.record([end], atMs: at(17, 14), maxScores: maxScores);
    final event = history.daily.values.single;
    expect(event.changeCount, 2);
    expect(event.firstAtMs, at(17));
    expect(event.lastAtMs, at(17, 13));
    expect(event.before!.achievement, 99);
    expect(event.after.achievement, 100.5);
    expect(ImprovementMetric.values.every(event.changed), isTrue);
    expect(ImprovementMetric.fc.display(event.after), 'AP+');
    expect(ImprovementMetric.fs.display(event.after), 'FDX+');
    expect(event.after.stars, '✦6');
    history.record([
      score(achievement: 100.6, dx: 2970, fc: 'app', fs: 'fsdp', rating: 315)
    ], atMs: at(18), maxScores: maxScores);
    expect(history.daily, hasLength(2));
    expect(history.daily.values.last.before!.achievement, 100.5);
  });

  test('只提升连击或同步也要记录；零变化的新一天不新增分组', () {
    final history = ScoreImprovementHistory();
    history.record([score()], atMs: at(16));
    history.record([score(fc: 'ap')], atMs: at(17));
    history.record([score(fc: 'ap', fs: 'fsd')], atMs: at(17, 11));
    history.record([score(fc: 'ap', fs: 'fsd')], atMs: at(18));
    expect(history.daily.values.single.changeCount, 2);
    expect(
        ImprovementMetric.fc.display(history.daily.values.single.after), 'AP');
    expect(history.daily.values.single.hasImprovement, isTrue);
  });

  test('空响应或缺失谱面不删除基线，新谱面仅在基线建立后标记首次记录', () {
    final history = ScoreImprovementHistory();
    history.record([], atMs: at(15));
    expect(history.startedAtMs, 0);
    history.record([score()], atMs: at(16));
    history.record([score(id: 8)], atMs: at(17));
    history.record([], atMs: at(17, 11));
    history.record([score(), score(id: 8)], atMs: at(18));
    expect(history.current, hasLength(2));
    expect(history.daily.values.single.isNewChart, isTrue);
    expect(history.daily.values.single.after.songId, 8);
  });

  test('只改标题、定数或物量不冒充提升，未知指标不当零值比较', () {
    final history = ScoreImprovementHistory();
    history.record([score()], atMs: at(16), maxScores: {'1466/3': 3000});
    history.record(
        [
          {...score(ds: 14.1, rating: 302), 'title': '修改后的歌名'}
        ],
        atMs: at(17),
        maxScores: {'1466/3': 2900});
    expect(history.daily, isEmpty);
    final partial = {
      ...score(),
      'dxScore': null,
      'fc': null,
      'fs': null,
      'ra': null
    };
    final another = ScoreImprovementHistory();
    another.record([partial], atMs: at(16));
    another.record([score(fc: 'ap', fs: 'fsdp')], atMs: at(17));
    expect(another.daily, isEmpty);
  });

  test('回退明确作为调整保留，同日回到初值仍保留真实变化次数', () {
    final history = ScoreImprovementHistory();
    history.record([score(achievement: 100)], atMs: at(16));
    history.record([score()], atMs: at(17));
    expect(history.daily.values.single.hasImprovement, isFalse);
    history.record([score(achievement: 100)], atMs: at(17, 11));
    expect(history.daily.values.single.changeCount, 2);
    expect(ImprovementMetric.values.any(history.daily.values.single.changed),
        isFalse);
  });

  test('序列化后重启继续合并，不丢失当日原值或产生重复记录', () {
    final history = ScoreImprovementHistory();
    history.record([score()], atMs: at(16));
    history.record([score(achievement: 100)], atMs: at(17));
    final restored = ScoreImprovementHistory.fromJson(
        jsonDecode(jsonEncode(history.toJson())));
    restored.record([score(achievement: 100)], atMs: at(17, 11));
    restored.record([score(achievement: 100.5)], atMs: at(17, 12));
    expect(restored.daily.values.single.before!.achievement, 99);
    expect(restored.daily.values.single.changeCount, 2);
    expect(restored.daily.values.single.after.achievement, 100.5);
  });

  test('按数据源与账号隔离落盘，新增字段兼容已有 Rating 和单谱曲线', () async {
    final temp = await Directory.systemTemp.createTemp('score-improvement-');
    final store = ChartHistoryStore.instance;
    ChartHistoryStore.debugDirectoryOverride = temp.path;
    store.debugClearCache();
    addTearDown(() async {
      store.debugClearCache();
      ChartHistoryStore.debugDirectoryOverride = null;
      await temp.delete(recursive: true);
    });
    Future<void> record(String source, String account, double achievement) =>
        store.recordChartSnapshot({
          'records': [score(achievement: achievement)]
        }, sourceKey: source, accountId: account, nowMs: at(17));
    await store.recordRating(
        rating: 15000, sourceKey: 'shuiyu', accountId: 'a', nowMs: at(16));
    await record('shuiyu', 'a', 99);
    await record('shuiyu', 'a', 100);
    await record('shuiyu', 'b', 100.5);
    await record('luoxue', 'a', 100.5);
    store.debugClearCache();
    final a =
        await store.scoreImprovements(sourceKey: 'shuiyu', accountId: 'a');
    expect(a.entries.single.before!.achievement, 99);
    expect(a.entries.single.after.achievement, 100);
    expect(
        (await store.scoreImprovements(sourceKey: 'shuiyu', accountId: 'b'))
            .entries,
        isEmpty);
    expect(
        (await store.scoreImprovements(sourceKey: 'luoxue', accountId: 'a'))
            .entries,
        isEmpty);
    expect(
        (await store.ratingSeries(sourceKey: 'shuiyu', accountId: 'a'))
            .single
            .rating,
        15000);
    expect(
        await store.chartEvents(1466, 3, sourceKey: 'shuiyu', accountId: 'a'),
        hasLength(1));
  });
}
