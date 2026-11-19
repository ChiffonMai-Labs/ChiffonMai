import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';
import 'package:my_first_flutter_app/page/KopQualifierPage.dart';
import 'package:my_first_flutter_app/service/Kop/KopQualifierService.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('赛程按 JST 判定', () {
    expect(KopQualifierService.isAvailable(DateTime.utc(2026, 11, 19)), isTrue);
    expect(
        KopQualifierService.isAvailable(DateTime.utc(2026, 11, 23, 14, 59, 59)),
        isTrue);
    expect(KopQualifierService.isExpired(DateTime.utc(2026, 11, 23, 15)),
        isTrue);
  });

  test('缺成绩时给出每首所需达成率', () {
    final ranking = [
      for (var i = 1; i <= 100; i++)
        KopRankingEntry(
            rank: i,
            userName: 'p$i',
            score: 3030000 - i * 1000,
            subScore: 0,
            recordDate: ''),
    ];
    final estimate = KopQualifierService.estimate(
        bests: const [null, null, null], ranking: ranking);
    final threshold = ranking[99].score;
    expect(estimate.requiredAchievement,
        closeTo(threshold / 3 / 10000, 0.0001));
  });

  test('三首齐全时给出榜内名次，超不过末位则算榜外', () {
    final ranking = [
      for (var i = 1; i <= 100; i++)
        KopRankingEntry(
            rank: i,
            userName: 'p$i',
            score: 3030000 - i * 1000,
            subScore: 0,
            recordDate: ''),
    ];
    const top = KopSongBest(levelIndex: 3, achievement: 101, dxScore: 0);
    final inside = KopQualifierService.estimate(
        bests: const [top, top, top], ranking: ranking);
    expect(inside.complete, isTrue);
    expect(inside.rank, 1);

    const low = KopSongBest(levelIndex: 3, achievement: 90, dxScore: 0);
    final outside = KopQualifierService.estimate(
        bests: const [low, low, low], ranking: ranking);
    expect(outside.rank, isNull);
  });

  test('网络失败时抛错并可回退', () async {
    ApiClient.debugClient =
        MockClient((request) async => http.Response('', 500));
    final debug = await ApiClient.get(Uri.parse('https://example.com/x'))
        .timeout(const Duration(seconds: 5));
    // ignore: avoid_print
    print('debug status=${debug.statusCode}');
    KopQualifierService.clearCache();
    // ignore: avoid_print
    print('start load');
    final future = KopQualifierService.loadRanking(KopRegion.international);
    future.then((value) {
      // ignore: avoid_print
      print('load ok ${value.entries.length}');
    }, onError: (Object error) {
      // ignore: avoid_print
      print('load error $error');
    });
    await expectLater(future.timeout(const Duration(seconds: 5)),
        throwsA(isA<KopQualifierException>()));
    ApiClient.debugClient = null;
  });

  testWidgets('无成绩且无网络时显示未记录与失败态', (tester) async {
    SharedPreferences.setMockInitialValues({});
    ApiClient.debugClient = MockClient((request) async => http.Response('', 500));
    KopQualifierService.clearCache();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const KopQualifierPage(),
    ));
    await tester.pumpAndSettle();
    expect(find.text('未记录'), findsNWidgets(3));
    await tester.drag(
        find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // ignore: avoid_print
    print(tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((t) => t != null)
        .join(' | '));
    expect(find.text('官方榜读取失败'), findsOneWidget);
    ApiClient.debugClient = null;
  });
}
