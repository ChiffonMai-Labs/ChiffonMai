import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/service/AutoSyncService.dart';
import 'package:my_first_flutter_app/service/AccountSwitchService.dart';
import 'package:my_first_flutter_app/service/AWMC/AwmcQuickIdentityStore.dart';
import 'package:my_first_flutter_app/service/AWMC/AwmcQuickSyncService.dart';
import 'package:my_first_flutter_app/service/SyncStatsService.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:my_first_flutter_app/utils/CurrentDataSourceNotifier.dart';
import 'package:my_first_flutter_app/utils/SecureCredentialStore.dart';
// 编译实际页面入口；以下用例仅检查状态与凭据逻辑。
// ignore: unused_import
import 'package:my_first_flutter_app/page/AutoSyncPage.dart';
// 编译账号管理的实际保存和轮换入口。
// ignore: unused_import
import 'package:my_first_flutter_app/page/HomePage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final service = AutoSyncService.instance;
  final headers = <String>[];
  final methods = <String>[];
  var failDelete = false;
  var failPut = false;
  var enabled = false;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    headers.clear();
    methods.clear();
    failDelete = false;
    failPut = false;
    enabled = false;
    ApiClient.debugClient = MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.path, '/api/auto-sync/task');
      final auth = request.headers['Authorization']!;
      expect(auth, matches(r'^Bearer [A-Za-z0-9_-]{43}$'));
      headers.add(auth);
      methods.add(request.method);
      // 收到网络请求前，管理令牌必须已经安全落盘。
      expect(await SecureCredentialStore.read(CacheKeyConstant.autoSyncTasks),
          isNotNull);
      if ((request.method == 'DELETE' && failDelete) ||
          (request.method == 'PUT' && failPut)) {
        throw const FormatException('synthetic-sensitive-response');
      }
      if (request.method == 'PUT') {
        final body = jsonDecode(request.body);
        expect(body['credential'], 'synthetic-user-credential');
        enabled = true;
      }
      if (request.method == 'DELETE') enabled = false;
      return http.Response(
          jsonEncode({
            'success': true,
            'task': {
              'enabled': enabled,
              'status': enabled ? 'waiting' : 'disabled',
              'nextRunAt': 1792339200000
            }
          }),
          200);
    });
  });
  tearDown(() {
    ApiClient.debugClient?.close();
    ApiClient.debugClient = null;
  });

  Future<AutoSyncTask> enable() => service.enable(
      platform: SyncPlatform.divingFish,
      source: 'shuiyu',
      accountId: '12345678',
      credential: 'synthetic-user-credential',
      userId: 12345);

  test('AWMC 上传鉴权错误明确提示更新个人 Token', () {
    final message = AutoSyncService.errorMessage('upload_credential_invalid');
    expect(message, contains('Import-Token 无效'));
    expect(message, contains('定时任务会自动更新'));
  });

  test('运行中的实时进度与上一轮结果独立解析，队列只含汇总和自己的位次', () {
    final task = AutoSyncTask.fromJson({
      'enabled': true,
      'status': 'running',
      'queue': {
        'waitingUsers': 12,
        'waitingTasks': 18,
        'runningTasks': 2,
        'position': null,
        'scheduledAt': 1792382400000,
        'upcoming': false
      },
      'progress': {'stage': 'uploading', 'completed': 100, 'total': 250},
      'lastResult': {
        'status': 'failed',
        'error': 'upload_failed',
        'submitted': 50,
        'startedAt': 1792339200000,
        'finishedAt': 1792339300000
      },
    });
    expect(task.progress!.value, .4);
    expect(task.queue!.waitingUsers, 12);
    expect(task.queue!.position, isNull);
    expect(task.lastResult!.submitted, 50);
    expect(task.lastResult!.status, 'failed');
    expect(task.lastResult!.finishedAt!.isUtc, true);
  });

  test('未知总页数不伪造百分比，旧接口缺少队列字段仍能显示已有结果', () {
    expect(
        const AutoSyncProgress(stage: 'reading', completed: 3).value, isNull);
    final task = AutoSyncTask.fromJson({
      'enabled': true,
      'status': 'success',
      'submitted': 100,
      'lastRunAt': 1792339200000
    });
    expect(task.queue, isNull);
    expect(task.progress, isNull);
    expect(task.lastResult!.submitted, 100);
    expect(task.lastResult!.unchanged, 0);
  });

  test('全部成绩未变化的定时任务仍按成功解析并保留跳过数量', () {
    final task = AutoSyncTask.fromJson({
      'enabled': true,
      'status': 'success',
      'lastResult': {'status': 'success', 'submitted': 0, 'unchanged': 1690}
    });
    expect(task.lastResult!.status, 'success');
    expect(task.lastResult!.submitted, 0);
    expect(task.lastResult!.unchanged, 1690);
  });

  test('默认关闭且不请求网络；任务管理凭据不会进入偏好或备份', () async {
    expect((await service.status(SyncPlatform.divingFish)).enabled, false);
    expect(methods, isEmpty);
    await enable();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(CacheKeyConstant.autoSyncTasks), isNull);
    expect(
        SecureCredentialStore.isCredentialKey(CacheKeyConstant.autoSyncTasks),
        true);
    final secured =
        await SecureCredentialStore.read(CacheKeyConstant.autoSyncTasks);
    expect(secured, isNot(contains('synthetic-user-credential')));
    expect((await service.status(SyncPlatform.divingFish)).enabled, true);
    expect(headers[0], headers[1]);
  });

  test('创建请求超时仍保留管理令牌，重试查询复用相同令牌', () async {
    failPut = true;
    await expectLater(enable(), throwsA(isA<AutoSyncException>()));
    expect(await service.registration(SyncPlatform.divingFish), isNotNull);
    failPut = false;
    await enable();
    expect(headers[0], headers[1]);
  });

  test('关闭失败不伪装为已关闭；确认关闭后清理管理令牌，重新开启使用新令牌', () async {
    await enable();
    final previous = headers.first;
    failDelete = true;
    await expectLater(service.disable(SyncPlatform.divingFish),
        throwsA(isA<AutoSyncException>()));
    expect(
        (await service.registration(SyncPlatform.divingFish))!.lastKnownEnabled,
        true);
    failDelete = false;
    expect((await service.disable(SyncPlatform.divingFish)).enabled, false);
    expect(await service.registration(SyncPlatform.divingFish), isNull);
    await enable();
    expect(headers.last, isNot(previous));
  });

  test('三个自动同步共用 userId，分别提交个人 key，不要求缓存本机成绩', () async {
    const sources = ['shuiyu', 'luoxue', 'awmc'];
    const keys = [
      CacheKeyConstant.probeDivingFishImportToken,
      CacheKeyConstant.probeLxnsImportToken,
      CacheKeyConstant.awmcNetImportToken
    ];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        CacheKeyConstant.accountStore,
        jsonEncode({
          for (var i = 0; i < 3; i++)
            sources[i]: {
              'source': sources[i],
              'id': '1234567$i',
              'hasData': false
            },
        }));
    await AwmcQuickIdentityStore.write(12345);
    for (var i = 0; i < 3; i++) {
      await SecureCredentialStore.write(keys[i], 'personal-key-$i');
    }
    final payloads = <Map>[];
    ApiClient.debugClient = MockClient((request) async {
      payloads.add(jsonDecode(request.body) as Map);
      return http.Response('{"success":true,"task":{"enabled":true}}', 200);
    });
    for (final platform in SyncPlatform.values) {
      final account =
          await AwmcQuickSyncService.accountFor(platform, requireData: false);
      await service.enable(
          platform: platform,
          source: account.source.key,
          accountId: account.id,
          credential: account.credential,
          userId: (await AwmcQuickIdentityStore.read())!);
    }
    expect(payloads.map((p) => p['userId']), [12345, 12345, 12345]);
    expect(payloads.map((p) => p['credential']),
        ['personal-key-0', 'personal-key-1', 'personal-key-2']);
    expect(payloads.map((p) => p['accountId']),
        ['12345670', '12345671', '12345672']);
  });

  test('删除共用凭据前关闭全部任务；服务不可用时保留凭据以便重试', () async {
    await AwmcQuickIdentityStore.write(12345);
    for (final platform in SyncPlatform.values) {
      await service.enable(
          platform: platform,
          source: AwmcQuickSyncService.sourceOf(platform).key,
          accountId: '12345678',
          credential: 'synthetic-user-credential',
          userId: 12345);
    }
    failDelete = true;
    await expectLater(
        AwmcQuickIdentityStore.forget(), throwsA(isA<AutoSyncException>()));
    expect(await AwmcQuickIdentityStore.read(), 12345);
    failDelete = false;
    await AwmcQuickIdentityStore.forget();
    expect(await AwmcQuickIdentityStore.read(), isNull);
    expect(await service.registration(SyncPlatform.divingFish), isNull);
    expect(await service.registration(SyncPlatform.luoXue), isNull);
    expect(await service.registration(SyncPlatform.awmc), isNull);
  });

  test('登出前撤销失败时，不清除本机账号凭据', () async {
    await enable();
    failDelete = true;
    var cleared = false;
    await expectLater(
        AccountSwitchService.clearAccountData(RefreshDataSource.shuiyu,
            clearCredentials: () async {
          cleared = true;
        }),
        throwsA(isA<AutoSyncException>()));
    expect(cleared, false);
    expect(
        (await service.registration(SyncPlatform.divingFish))!.lastKnownEnabled,
        true);
    expect(AccountSwitchService.isBusy, false);
  });

  test('三源个人 key 保存分别更新已有任务，复用管理令牌且不传 userId', () async {
    for (final platform in SyncPlatform.values) {
      await service.enable(
          platform: platform,
          source: AwmcQuickSyncService.sourceOf(platform).key,
          accountId: '12345678',
          credential: 'synthetic-user-credential',
          userId: 12345);
    }
    final tokens = List<String>.from(headers);
    final posted = <Map>[];
    ApiClient.debugClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/auto-sync/task/credential');
      final body = jsonDecode(request.body) as Map;
      posted.add(body);
      final platform =
          SyncPlatform.values.firstWhere((p) => p.key == body['platform']);
      expect(request.headers['Authorization'], tokens[platform.index]);
      expect((await service.registration(platform))!.credentialPending, true);
      expect(body.containsKey('userId'), false);
      return http.Response('{"success":true,"task":{"enabled":true}}', 200);
    });
    for (final platform in SyncPlatform.values) {
      final message = await service.savePersonalCredential(
          platform, 'synthetic-new-key-${platform.key}');
      expect(message, contains('已更新定时任务'));
      expect((await service.registration(platform))!.credentialPending, false);
    }
    expect(posted.map((p) => p['credential']),
        SyncPlatform.values.map((p) => 'synthetic-new-key-${p.key}'));
    expect(posted.map((p) => p['platform']),
        SyncPlatform.values.map((p) => p.key));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(CacheKeyConstant.autoSyncTasks), isNull);
  });

  test('未开启时只保存本机 key，不发送网络请求或创建任务', () async {
    expect(
        await service.savePersonalCredential(
            SyncPlatform.awmc, 'synthetic-new-key'),
        contains('已保存'));
    expect(methods, isEmpty);
    expect(await service.registration(SyncPlatform.awmc), isNull);
    expect(
        await SecureCredentialStore.read(CacheKeyConstant.awmcNetImportToken),
        'synthetic-new-key');
  });

  test('更新失败保留新 key 和待同步标记，相同 key 重新保存仍可重试', () async {
    await enable();
    var fail = true;
    ApiClient.debugClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body)['credential'], 'synthetic-rotated-key');
      if (fail) throw const FormatException('synthetic-sensitive-response');
      return http.Response('{"success":true,"task":{"enabled":true}}', 200);
    });
    final message = await service.savePersonalCredential(
        SyncPlatform.divingFish, 'synthetic-rotated-key');
    expect(message, contains('定时任务待更新'));
    expect(message, isNot(contains('synthetic-sensitive-response')));
    expect(
        await SecureCredentialStore.read(
            CacheKeyConstant.probeDivingFishImportToken),
        'synthetic-rotated-key');
    expect(
        (await service.registration(SyncPlatform.divingFish))!
            .credentialPending,
        true);
    fail = false;
    await service.savePersonalCredential(
        SyncPlatform.divingFish, 'synthetic-rotated-key');
    expect(
        (await service.registration(SyncPlatform.divingFish))!
            .credentialPending,
        false);
  });

  test('重新进入查询时恢复安全存储中的待更新任务；服务端已关闭则保持关闭', () async {
    await enable();
    await SecureCredentialStore.write(
        CacheKeyConstant.probeDivingFishImportToken, 'synthetic-rotated-key');
    final raw = jsonDecode(
            (await SecureCredentialStore.read(CacheKeyConstant.autoSyncTasks))!)
        as Map;
    raw['fish']['credentialPending'] = true;
    await SecureCredentialStore.write(
        CacheKeyConstant.autoSyncTasks, jsonEncode(raw));
    ApiClient.debugClient = MockClient((request) async {
      expect(request.method, 'POST');
      expect(jsonDecode(request.body)['credential'], 'synthetic-rotated-key');
      return http.Response('{"success":true,"task":{"enabled":false}}', 200);
    });
    expect((await service.status(SyncPlatform.divingFish)).enabled, false);
    expect(await service.registration(SyncPlatform.divingFish), isNull);
  });

  test('删除个人 key 前撤销任务，失败时不删除本机凭据', () async {
    await enable();
    await SecureCredentialStore.write(
        CacheKeyConstant.probeDivingFishImportToken,
        'synthetic-user-credential');
    failDelete = true;
    await expectLater(service.clearPersonalCredential(SyncPlatform.divingFish),
        throwsA(isA<AutoSyncException>()));
    expect(
        await SecureCredentialStore.read(
            CacheKeyConstant.probeDivingFishImportToken),
        'synthetic-user-credential');
    expect(await service.registration(SyncPlatform.divingFish), isNotNull);
    failDelete = false;
    expect(await service.clearPersonalCredential(SyncPlatform.divingFish),
        contains('已关闭'));
    expect(
        await SecureCredentialStore.read(
            CacheKeyConstant.probeDivingFishImportToken),
        isNull);
    expect(await service.registration(SyncPlatform.divingFish), isNull);
  });

  test('快速连续轮换与关闭按顺序执行，旧请求不会覆盖新 key 或重新开启任务', () async {
    await enable();
    final began = Completer<void>(), release = Completer<void>();
    final sent = <String>[];
    ApiClient.debugClient = MockClient((request) async {
      if (request.method == 'POST') {
        final key = jsonDecode(request.body)['credential'] as String;
        sent.add(key);
        if (sent.length == 1) {
          began.complete();
          await release.future;
        }
        return http.Response('{"success":true,"task":{"enabled":true}}', 200);
      }
      sent.add('DELETE');
      return http.Response('{"success":true,"task":{"enabled":false}}', 200);
    });
    final first = service.savePersonalCredential(
        SyncPlatform.divingFish, 'synthetic-first-key');
    await began.future;
    final second = service.savePersonalCredential(
        SyncPlatform.divingFish, 'synthetic-second-key');
    final clear = service.clearPersonalCredential(SyncPlatform.divingFish);
    release.complete();
    await Future.wait([first, second, clear]);
    expect(sent, ['synthetic-first-key', 'synthetic-second-key', 'DELETE']);
    expect(
        await SecureCredentialStore.read(
            CacheKeyConstant.probeDivingFishImportToken),
        isNull);
    expect(await service.registration(SyncPlatform.divingFish), isNull);
  });
}
