import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:my_first_flutter_app/manager/DivingFish/ProberException.dart';
import 'package:my_first_flutter_app/service/AutoSyncService.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:my_first_flutter_app/utils/AppError.dart';
import 'package:my_first_flutter_app/utils/SensitiveRedactor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
        const [
      Locale('zh'),
    ];
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearLocalesTestValue();
  });

  test('SensitiveRedactor 对凭据脱敏并保留 requestId 与堆栈帧', () {
    const raw = '''
qr=SGWCMAID1234567890ABCDEF
token: gw_1234567890abcdef
Authorization: Bearer my-secret-bearer-token
jwt=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjMifQ.sig123456
x-prober-key=super_secret_gateway_key
https://example.com/callback?code=authcode999&safe=ok
req=cm-1a2b3c-9f0e
#0      SomeClass.method (package:my_first_flutter_app/page/HomePage.dart:123:45)
''';
    final safe = SensitiveRedactor.redact(raw);
    expect(safe, isNot(contains('SGWCMAID1234567890')));
    expect(safe, isNot(contains('gw_1234567890')));
    expect(safe, isNot(contains('my-secret-bearer-token')));
    expect(safe, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
    expect(safe, isNot(contains('super_secret_gateway_key')));
    expect(safe, isNot(contains('authcode999')));
    expect(safe, contains('cm-1a2b3c-9f0e'));
    expect(safe, contains('package:my_first_flutter_app/page/HomePage.dart:123:45'));
  });

  test('AppErrorMapper 自动剥离 Bad state / Exception 前缀并识别常见异常', () {
    final badState = AppErrorMapper.from(
      StateError('全量谱面下载未完成，请稍后重试'),
      stage: '下载谱面',
    );
    expect(badState.userMessage, '全量谱面下载未完成，请稍后重试');
    expect(badState.userMessage, isNot(contains('Bad state:')));
    expect(
      AppErrorMapper.cleanText('同步成功，但刷新数据失败：Bad state: Exception: 超时'),
      '同步成功，但刷新数据失败：超时',
    );
    expect(badState.compactBadge(appVersion: '3.0.1+42'),
        'APP-STATE · 下载谱面 · v3.0.1+42');

    final qqSave = AppErrorMapper.from(StateError('save_qq_failed'));
    expect(qqSave.code, 'DATA-SAVE-QQ');
    expect(qqSave.userMessage, contains('QQ'));

    final netErr = AppErrorMapper.from(const SocketException('Failed host lookup'));
    expect(netErr.code, 'NET-OFFLINE');

    final timeoutErr = AppErrorMapper.from(TimeoutException('waiting'));
    expect(timeoutErr.code, 'NET-TIMEOUT');

    final proberErr = AppErrorMapper.from(ProberException.unauthorized());
    expect(proberErr.code, 'AUTH-FISH-UNAUTHORIZED');

    final autoErr = AppErrorMapper.from(const AutoSyncException(
      '队列繁忙',
      code: 'rate_limited',
      requestId: 'cm-aa11bb-2233',
      httpStatus: 429,
      stage: '自动同步 PUT',
    ));
    expect(autoErr.code, 'SYNC-AUTO-RATE-LIMITED');
    expect(autoErr.requestId, 'cm-aa11bb-2233');
    expect(autoErr.httpStatus, 429);

    final diag = autoErr.buildDiagnosticText(
      appVersion: '3.0.1+42',
      dataSource: 'awmc',
      recentLogs: ['2026-11-25T12:00:00Z token=secret_val'],
    );
    expect(diag, contains('错误码: SYNC-AUTO-RATE-LIMITED'));
    expect(diag, contains('请求号: cm-aa11bb-2233'));
    expect(diag, isNot(contains('secret_val')));
  });

  test('ApiClient.generateRequestId 与 ApiClient.parseError 兼容新旧错误结构', () {
    final id = ApiClient.generateRequestId();
    expect(RegExp(r'^cm-[0-9a-f]{6}-[0-9a-f]{4}$').hasMatch(id), isTrue);

    final newResp = http.Response.bytes(
      utf8.encode(jsonEncode({
        'success': false,
        'error': '获取失败',
        'errorCode': 'SRV-KALEID-LIST',
        'userMessage': '获取万花镜门列表失败，请稍后重试',
        'stage': 'mysql_query',
        'requestId': 'req-xyz-123',
      })),
      500,
      headers: {'x-request-id': 'req-xyz-123'},
    );
    final parsedNew = ApiClient.parseError(newResp, title: '加载失败');
    expect(parsedNew.code, 'SRV-KALEID-LIST');
    expect(parsedNew.userMessage, '获取万花镜门列表失败，请稍后重试');
    expect(parsedNew.stage, 'mysql_query');
    expect(parsedNew.requestId, 'req-xyz-123');
    expect(parsedNew.httpStatus, 500);

    final legacyResp = http.Response.bytes(
      utf8.encode(jsonEncode({'code': 'UPSTREAM_ERROR'})),
      502,
      headers: {'x-request-id': 'req-legacy-999'},
    );
    final parsedLegacy = ApiClient.parseError(legacyResp);
    expect(parsedLegacy.code, 'SRV-UPSTREAM-ERROR');
    expect(parsedLegacy.requestId, 'req-legacy-999');
    expect(parsedLegacy.httpStatus, 502);
  });

  test('AppError.asStateError 保持 StateError 兼容性并保留完整诊断字段', () {
    final base = AppError(
      code: 'SYNC-QUICK-PAGING',
      userMessage: '机台成绩分页异常，已停止同步',
      stage: '读取机台成绩分页',
      source: 'awmc',
      requestId: 'cm-112233-4455',
      httpStatus: 502,
      technicalDetail: 'nextIndex=-1',
    );
    final err = base.asStateError();
    expect(err, isA<StateError>());
    expect(err.message, '机台成绩分页异常，已停止同步');
    expect(err.toString(), '机台成绩分页异常，已停止同步');
    expect(err.toString(), isNot(contains('Bad state:')));

    final mapped = AppErrorMapper.from(err);
    expect(mapped.code, 'SYNC-QUICK-PAGING');
    expect(mapped.stage, '读取机台成绩分页');
    expect(mapped.source, 'awmc');
    expect(mapped.requestId, 'cm-112233-4455');
    expect(mapped.httpStatus, 502);
    expect(mapped.technicalDetail, 'nextIndex=-1');
  });
}
