import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/service/GainRecommend/GainFeedbackStore.dart';
import 'package:my_first_flutter_app/service/GainRecommend/GainRecommendCore.dart';

GainChartRecord rec(int id, double ds, double achv,
        {bool isNew = false, int level = 3}) =>
    GainChartRecord(
      songId: id,
      levelIndex: level,
      title: 's$id',
      level: '',
      ds: ds,
      achievements: achv,
      isNew: isNew,
    );

void main() {
  group('RA 与量化', () {
    // 期望值取自 bot 端 Python 同公式的输出。
    test('档位临界与 100.5 封顶', () {
      expect(gainRaOf(13.0, 96.9999), 211);
      expect(gainRaOf(13.0, 97.0), 252);
      expect(gainRaOf(13.0, 100.4999), 282);
      expect(gainRaOf(13.0, 100.5), 292);
      expect(gainRaOf(13.0, 101.0), 292);
    });

    test('十进制向上量化，刻度点不进位', () {
      expect(quantizeGainTarget(99.5), 99.5);
      expect(quantizeGainTarget(99.50001), 99.5001);
      expect(quantizeGainTarget(98.76543), 98.7655);
      expect(quantizeGainTarget(100.50001), isNull);
      expect(quantizeGainTarget(0), isNull);
    });
  });

  group('独立净收益', () {
    test('未满槽直接补空位', () {
      final records = normalizeGainRecords([rec(1, 13.0, 99.0)]);
      final base = computeGainBaseline(records);
      final missing = rec(2, 13.0, 0);
      expect(gainIndependentNetGain(base, missing, 100.0), gainRaOf(13.0, 100.0));
    });

    test('满槽槽外谱要超过底线才涨分', () {
      final records = normalizeGainRecords([
        for (var i = 0; i < gainB35Size; i++) rec(i + 1, 13.0, 100.0),
        rec(100, 12.0, 99.0),
      ]);
      final base = computeGainBaseline(records);
      final floor = base.floor(false);
      final outside = records.firstWhere((r) => r.songId == 100);
      expect(gainIndependentNetGain(base, outside, 100.5),
          gainRaOf(12.0, 100.5) - floor > 0 ? gainRaOf(12.0, 100.5) - floor : 0);
      // 槽外谱提到 99.5 仍低于底线 → 零收益，不会进入直接吃分路线。
      expect(gainIndependentNetGain(base, outside, 99.5), 0);
    });

    test('同谱只留最佳成绩，零收益不入候选', () {
      final result = buildGainCandidates(GainInput(records: [
        rec(1, 13.0, 98.0),
        rec(1, 13.0, 100.5),
      ]));
      expect(result.records.single.achievements, 100.5);
      expect(result.candidates, isEmpty);
    });
  });

  group('路线与选页', () {
    test('稳妥取最小正收益目标，挑战挂成可选项', () {
      final result = buildGainCandidates(
          GainInput(records: [rec(1, 14.0, 99.45)]));
      final c = result.candidates.single;
      expect(c.route, GainRoute.stable);
      expect(c.target, 99.5);
      expect(c.alternativeTarget, isNotNull);
      expect(c.alternativeTarget! > c.target, isTrue);
    });

    test('有 ≥12 合格候选时满页、同谱不重复、换批不重复', () {
      final records = [
        for (var i = 0; i < 40; i++)
          rec(i + 1, 12.0 + (i % 20) / 10, 99.3 + (i % 5) / 100,
              isNew: i % 4 == 0),
      ];
      final result = buildGainCandidates(GainInput(records: records));
      final sorted = sortGainCandidates(result.candidates);
      final first = selectGainPage(sorted);
      expect(first.items.length, gainPageSize);
      final keys = first.items.map((c) => c.key).toSet();
      expect(keys.length, gainPageSize);
      final second = selectGainPage(sorted, excluded: keys);
      expect(second.items.any((c) => keys.contains(c.key)), isFalse);
    });

    test('探索只用全量输入，且必须能进 B50', () {
      final records = [for (var i = 0; i < 6; i++) rec(i + 1, 13.0, 99.0)];
      const pool = [
        GainExploreChart(
            songId: 50, levelIndex: 3, title: 'x', level: '', ds: 13.2, isNew: false),
      ];
      final partial =
          buildGainCandidates(GainInput(records: records, explorePool: pool));
      expect(partial.count(GainRoute.explore), 0);
      final full = buildGainCandidates(
          GainInput(records: records, complete: true, explorePool: pool));
      expect(full.count(GainRoute.explore), 1);
    });

    test('本页合计按 B50 逐步重算', () {
      final records = [rec(1, 13.0, 99.45), rec(2, 13.0, 99.45)];
      final result = buildGainCandidates(GainInput(records: records));
      final page =
          selectGainPage(sortGainCandidates(result.candidates)).items;
      final sum = page.fold<int>(0, (s, c) => s + c.netGain);
      expect(combinedGainOfPage(records, page), sum);
    });
  });

  group('反馈', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      GainFeedbackStore.instance.debugReset();
    });

    test('卡住 14 天到期、不喜欢直到撤销、重载后仍在', () async {
      final store = GainFeedbackStore.instance;
      var now = DateTime(2026, 10, 1);
      store.clock = () => now;
      const a = GainChartKey(1, 3), b = GainChartKey(2, 3);
      await store.record(a, GainFeedbackKind.stuck, title: 'a', level: '13');
      await store.record(b, GainFeedbackKind.dislike, title: 'b', level: '13');
      expect(await store.excludedKeys(), {a, b});

      store.debugReset();
      store.clock = () => now;
      expect(await store.excludedKeys(), {a, b});

      now = now.add(const Duration(days: 14, seconds: 1));
      expect(await store.excludedKeys(), {b});

      await store.undo(b);
      expect(await store.excludedKeys(), isEmpty);
    });
  });
}
