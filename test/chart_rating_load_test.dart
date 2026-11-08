import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/service/SongInfoService.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => ApiClient.debugClient = null);

  test('评分读取保留小数字符串和本账号评分的兼容转换', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['levelIndex'], '0');
      return http.Response(
          jsonEncode({
            'success': true,
            'averageScore': '4.25',
            'totalVotes': 2,
            'userRating': {'score': '4.5'},
          }),
          200);
    });
    ApiClient.debugClient = client;
    addTearDown(client.close);
    final result =
        await SongInfoService.getChartRating(songId: '1', levelIndex: 0);
    expect(result['averageScore'], 4.25);
    expect(result['userRating']['score'], 4.5);
  });

  test('HTTP 失败返回明确失败状态，允许页面结束 Loading 并重试', () async {
    final client = MockClient((_) async => http.Response('{}', 503));
    ApiClient.debugClient = client;
    addTearDown(client.close);
    final result =
        await SongInfoService.getChartRating(songId: '1', levelIndex: 3);
    expect(result['success'], false);
  });

  testWidgets('源站一直不返回时，8 秒内结束读取，迟到响应不改变失败结果', (tester) async {
    final response = Completer<http.Response>();
    final client = MockClient((_) => response.future);
    ApiClient.debugClient = client;
    addTearDown(client.close);
    Map<String, dynamic>? result;
    final request = SongInfoService.getChartRating(songId: '1', levelIndex: 3)
        .then((value) => result = value);
    await tester.pump();
    expect(result, isNull);
    await tester.pump(SongInfoService.chartRatingTimeout);
    await request;
    expect(result?['success'], false);
    response.complete(http.Response('{"success":true,"averageScore":5}', 200));
    await tester.pump();
    expect(result?['success'], false);
  });
}
