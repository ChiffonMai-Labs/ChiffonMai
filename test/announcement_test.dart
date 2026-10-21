import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/service/AnnouncementService.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:my_first_flutter_app/widgets/AnnouncementDialog.dart';

Map<String, dynamic> notice({String id = 'notice-1', int revision = 1}) => {
      'id': id,
      'revision': revision,
      'enabled': true,
      'title': '公告标题',
      'publishedAt': '2026-10-20T12:00:00+08:00',
      'blocks': [
        {'type': 'text', 'text': '测试公告正文'}
      ],
    };

http.Response response(Object? value, {String etag = '"one"'}) => http.Response(
    jsonEncode({'success': true, 'announcement': value}), 200,
    headers: {'etag': etag, 'content-type': 'application/json; charset=utf-8'});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AnnouncementService();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() {
    ApiClient.debugClient = null;
  });

  test('首次下载缓存，下一次携带ETag，304复用缓存', () async {
    var requests = 0;
    ApiClient.debugClient = MockClient((request) async {
      requests++;
      if (requests == 1) return response(notice());
      expect(request.headers['If-None-Match'], '"one"');
      return http.Response('', 304);
    });
    expect((await service.load())?.version, 'notice-1:1');
    expect((await service.load())?.title, '公告标题');
    expect(requests, 2);
  });

  test('不再提示仅作用于当前编号及版本，新版本和新公告仍显示', () async {
    final old = Announcement.fromJson(notice());
    expect(await service.shouldShow(old), isTrue);
    await service.dismiss(old);
    expect(await AnnouncementService().shouldShow(old), isFalse);
    expect(await service.shouldShow(Announcement.fromJson(notice(revision: 2))),
        isTrue);
    expect(
        await service.shouldShow(Announcement.fromJson(notice(id: 'notice-2'))),
        isTrue);
  });

  test('断网/非法响应回退有效缓存，过期及未生效缓存不会弹出', () async {
    final prefs = await SharedPreferences.getInstance();
    Future<void> seed(Map<String, dynamic> value) async {
      await prefs.setString(AnnouncementService.cacheKey,
          jsonEncode({'etag': '"one"', 'announcement': value}));
    }

    ApiClient.debugClient =
        MockClient((_) async => throw StateError('offline'));
    await seed(notice());
    expect((await service.load())?.id, 'notice-1');
    await seed({
      ...notice(),
      'endsAt': DateTime.now()
          .subtract(const Duration(seconds: 5))
          .toUtc()
          .toIso8601String()
    });
    expect(await service.load(), isNull);
    await seed({
      ...notice(),
      'startsAt':
          DateTime.now().add(const Duration(days: 1)).toUtc().toIso8601String()
    });
    expect(await service.load(), isNull);
    await seed(notice());
    ApiClient.debugClient =
        MockClient((_) async => http.Response('{broken', 200));
    expect((await service.load())?.id, 'notice-1');
  });

  test('撤下公告清正文和ETag，保留不再提示设置', () async {
    ApiClient.debugClient = MockClient((_) async => response(notice()));
    final value = (await service.load())!;
    await service.dismiss(value);
    ApiClient.debugClient = MockClient((_) async => response(null));
    expect(await service.load(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AnnouncementService.cacheKey), isNull);
    expect(await service.shouldShow(value), isFalse);
    ApiClient.debugClient = MockClient((request) async {
      expect(request.headers.containsKey('If-None-Match'), isFalse);
      return response(notice(revision: 2));
    });
    expect((await service.load())?.revision, 2);
  });

  test('新版本写入缓存，慢响应超时后不覆盖之前缓存', () async {
    ApiClient.debugClient =
        MockClient((_) async => response(notice(revision: 2)));
    expect((await service.load())?.revision, 2);
    final pending = Completer<http.Response>();
    ApiClient.debugClient = MockClient((_) => pending.future);
    expect((await service.load())?.revision, 2);
    pending.complete(response(notice(revision: 3)));
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(AnnouncementService.cacheKey)!);
    expect(saved['announcement']['revision'], 2);
  });

  test('损坏缓存重新请求；非法图片和时间拒绝解析', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AnnouncementService.cacheKey, '{broken');
    ApiClient.debugClient = MockClient((request) async {
      expect(request.headers.containsKey('If-None-Match'), isFalse);
      return response(notice());
    });
    expect((await service.load())?.revision, 1);
    for (final url in [
      'http://example.com/a.png',
      'https://user:password@example.com/a.png',
      'file:///a.png'
    ]) {
      expect(
          () => Announcement.fromJson({
                ...notice(),
                'blocks': [
                  {'type': 'image', 'url': url}
                ]
              }),
          throwsFormatException);
    }
    expect(
        () => Announcement.fromJson(
            {...notice(), 'startsAt': '2026-10-20T12:00:00'}),
        throwsFormatException);
    final value = Announcement.fromJson({
      ...notice(),
      'blocks': [
        {'type': 'text', 'text': '上段'},
        {'type': 'image', 'url': 'https://example.com/a.png', 'caption': '截图'},
        {'type': 'text', 'text': '下段'},
      ]
    });
    expect(value.blocks.map((b) => b.type), ['text', 'image', 'text']);
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showAnnouncementDialog(
                          context, Announcement.fromJson(notice())),
                      child: const Text('打开公告')),
                ))));
    await tester.tap(find.text('打开公告'));
    await tester.pumpAndSettle();
  }

  testWidgets('关闭未勾选公告不免提示，勾选后确认才持久化', (tester) async {
    final value = Announcement.fromJson(notice());
    await open(tester);
    expect(find.text('测试公告正文'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(await service.shouldShow(value), isTrue);
    await tester.tap(find.text('打开公告'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(await service.shouldShow(value), isTrue);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    expect(await service.shouldShow(value), isFalse);
  });

  testWidgets('勾选后按返回关闭不会误保存免提示', (tester) async {
    await open(tester);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(AlertDialog))).pop();
    await tester.pumpAndSettle();
    expect(await service.shouldShow(Announcement.fromJson(notice())), isTrue);
  });
}
