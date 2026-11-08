import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_app/manager/LZYCheckUpdateManager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:my_first_flutter_app/service/AppUpdateDownloadService.dart';
import 'package:my_first_flutter_app/service/BackgroundAppUpdateService.dart';
import 'package:my_first_flutter_app/service/AppUpdateAutoInstallSettings.dart';

class _Adapter implements HttpClientAdapter {
  final ResponseBody Function(RequestOptions) respond;
  _Adapter(this.respond);
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream,
          Future<void>? cancelFuture) async =>
      respond(options);
  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _asset(
        {String name = 'ChiffonMai.apk',
        String repo = 'ChiffonMai-Labs/ChiffonMai'}) =>
    {
      'name': name,
      'size': 128,
      'browser_download_url':
          'https://github.com/$repo/releases/download/v9.0.0/$name',
      'digest': 'sha256:${sha256.convert(List<int>.generate(128, (i) => i))}',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel,
            (call) async {
      calls.add(call);
      if (call.method == 'supportedAbis') return ['arm64-v8a'];
      return jsonEncode(
          {'phase': 'downloading', 'downloadId': 123, 'build': 90});
    });
  });
  tearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(AppUpdateDownloadService.channel, null));

  AppUpdateDownloadService makeService(List<String> requests,
      {bool proxyFails = false,
      String tag = 'v9.0.0',
      Map<String, dynamic>? asset}) {
    final dio = Dio();
    dio.httpClientAdapter = _Adapter((options) {
      final url = options.uri.toString();
      requests.add(url);
      if (proxyFails && url.startsWith('https://proxy.test/'))
        return ResponseBody.fromString('limited', 403);
      return ResponseBody.fromString(
          jsonEncode({
            'tag_name': tag,
            'assets': [asset ?? _asset()]
          }),
          200);
    });
    return AppUpdateDownloadService(dio: dio);
  }

  test('读取自动安装设置不产生授权，低版本系统不能开启', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel,
            (call) async {
      calls.add(call);
      return {'enabled': false, 'supported': false, 'canInstall': true};
    });
    final settings = AppUpdateAutoInstallSettings();
    addTearDown(settings.dispose);
    expect(settings.enabled, isFalse);
    await settings.setEnabled(true);
    expect(calls, isEmpty, reason: '读取完成前不能修改授权');
    await settings.load();
    await settings.setEnabled(true);
    expect(settings.enabled, isFalse);
    expect(calls.map((c) => c.method), ['getAutoInstallSettings']);
  });

  test('只有明确开启才写入原生授权，保存失败保留原状态', () async {
    var reject = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel,
            (call) async {
      calls.add(call);
      if (call.method == 'setAutoInstallEnabled' && reject)
        throw PlatformException(code: 'APP_UPDATE_FAILED', message: '无法保存');
      return {
        'enabled': call.method == 'setAutoInstallEnabled'
            ? (call.arguments as Map)['enabled']
            : false,
        'supported': true,
        'canInstall': false,
      };
    });
    final settings = AppUpdateAutoInstallSettings();
    addTearDown(settings.dispose);
    await settings.load();
    expect(settings.enabled, isFalse);
    await settings.setEnabled(true);
    expect(settings.enabled, isTrue);
    expect(settings.canInstall, isFalse, reason: '开启开关不等同于系统安装来源授权');
    expect(calls.last.arguments, {'enabled': true});
    reject = true;
    await settings.setEnabled(false);
    expect(settings.enabled, isTrue);
    expect(settings.error, '无法保存');
  });

  test('选择通用或匹配架构的本仓库 APK，拒绝跨仓库、缺摘要和不兼容架构', () {
    expect(
        AppUpdateDownloadService.selectAsset({
          'assets': [_asset()]
        }, [
          'arm64-v8a'
        ]).size,
        128);
    for (final invalid in [
      _asset(repo: 'another/repo'),
      {..._asset(), 'digest': null},
      _asset(name: 'app-x86.apk'),
      _asset(name: 'app-x86_64.apk')
    ]) {
      expect(
          () => AppUpdateDownloadService.selectAsset({
                'assets': [invalid]
              }, [
                'arm64-v8a'
              ]),
          throwsFormatException);
    }
    expect(
        () => AppUpdateDownloadService.selectAsset({
              'assets': [_asset(name: 'app-x86_64.apk')]
            }, [
              'x86'
            ]),
        throwsFormatException);
    expect(
        AppUpdateDownloadService.selectAsset({
          'assets': [
            _asset(name: 'app-armeabi-v7a.apk'),
            _asset(name: 'app-arm64-v8a.apk')
          ]
        }, [
          'arm64-v8a',
          'armeabi-v7a'
        ]).url,
        contains('arm64-v8a'));
  });

  test('加速配置只接受 HTTPS 根地址，空列表禁用加速，最后保留直连', () {
    expect(AppUpdateDownloadService.proxyPrefixes(null),
        [AppUpdateDownloadService.defaultProxy]);
    expect(AppUpdateDownloadService.proxyPrefixes([]), isEmpty);
    expect(
        AppUpdateDownloadService.proxyPrefixes([
          'http://bad.test',
          'https://user:password@bad.test',
          'https://proxy.test/path',
          'https://proxy.test',
          'https://proxy.test/'
        ]),
        ['https://proxy.test/']);
    expect(
        AppUpdateDownloadService.downloadUrls(
            'https://github.com/file', ['https://proxy.test/']),
        [
          'https://proxy.test/https://github.com/file',
          'https://github.com/file'
        ]);
  });

  test('发布信息加速失败后回退；二进制下载及完整性参数一次性交给系统持有', () async {
    final requests = <String>[];
    final service = makeService(requests, proxyFails: true);
    addTearDown(service.cancel);
    final state = await service.startBackgroundDownload(
        version: '9.0.0',
        build: 90,
        updateLog: '本次版本更新内容',
        configuredProxies: ['https://proxy.test/'],
        onProgress: (_, __, ___) {});
    expect(state['downloadId'], 123);
    expect(requests.length, 2);
    expect(requests.every((url) => url.contains('api.github.com')), isTrue);
    final task = calls
        .singleWhere((c) => c.method == 'startBackgroundDownload')
        .arguments;
    expect(task['urls'], [
      'https://proxy.test/${_asset()['browser_download_url']}',
      _asset()['browser_download_url']
    ]);
    expect(task['sha256'], '${_asset()['digest']}'.substring(7));
    expect(task['size'], 128);
    expect(task['build'], 90);
    expect(task['updateLog'], '本次版本更新内容');
    service.cancel();
    expect(calls.where((c) => c.method == 'cancelBackgroundDownload'), isEmpty,
        reason: '释放页面侧请求不得取消系统持有的任务');
  });

  for (final unavailable in [false, true]) {
    test(
        unavailable
            ? '更新配置不可用时报告失败，不以 GitHub 最新发布兜底'
            : 'Android 版本、构建号和日志均取自更新配置，检查阶段不请求 GitHub', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      PackageInfo.setMockInitialValues(
          appName: 'ChiffonMai',
          packageName: 'cloud.chiffonmai.app',
          version: '3.0.0-beta',
          buildNumber: '54',
          buildSignature: '');
      final requests = <Uri>[];
      var unexpectedNetwork = 0;
      final manager = LZYCheckUpdateManager();
      final result = await HttpOverrides.runZoned(
        () => http.runWithClient(
          () => manager.checkUpdate(force: true),
          () => MockClient((request) async {
            requests.add(request.url);
            return http.Response(
                unavailable
                    ? ''
                    : jsonEncode({
                        'version': '3.0.0-beta',
                        'buildNumber': 55,
                        'updateLog': '来自 app_version.json 的更新日志',
                        'downloadUrl': 'https://chiffonmai.cloud/download',
                        'githubReleaseTag': 'beta-configured-tag',
                        'githubProxyPrefixes': ['https://proxy.test/'],
                      }),
                unavailable ? 503 : 200,
                headers: {'content-type': 'application/json; charset=utf-8'});
          }),
        ),
        createHttpClient: (_) {
          unexpectedNetwork++;
          throw StateError('检查更新不应额外请求 GitHub 或 APK');
        },
      );
      expect(requests, [Uri.parse(manager.pastebinRawUrl)]);
      expect(unexpectedNetwork, 0);
      expect(calls, isEmpty, reason: '检查阶段不读取 GitHub 附件或创建下载任务');
      if (unavailable) {
        expect(result['hasUpdate'], isFalse);
        expect(result['networkError'], isTrue);
      } else {
        expect(result['hasUpdate'], isTrue);
        expect(result['latestVersion'], '3.0.0-beta');
        expect(result['latestBuild'], 55);
        expect(result['updateLog'], '来自 app_version.json 的更新日志');
        expect(result['downloadUrl'], 'https://chiffonmai.cloud/download');
        expect(result['githubReleaseTag'], 'beta-configured-tag');
        expect(result['githubProxyPrefixes'], ['https://proxy.test/']);
        expect(result['updateSource'], 'config');
      }
    }, skip: LZYCheckUpdateManager.useGitHubForUpdateCheck);
  }

  for (final failure in ['none', 'range', 'tag', 'digest']) {
    test('临时 GitHub 更新来源：$failure', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      PackageInfo.setMockInitialValues(
          appName: 'ChiffonMai',
          packageName: 'cloud.chiffonmai.app',
          version: '3.0.0-beta',
          buildNumber: '54',
          buildSignature: '');
      final manifest =
          File('test/fixtures/update_apk_manifest.bin').readAsBytesSync();
      final archive = Archive()
        ..addFile(ArchiveFile('AndroidManifest.xml', manifest.length, manifest))
        ..addFile(
            ArchiveFile('assets/unrelated.bin', 200000, Uint8List(200000)));
      final apk = Uint8List.fromList(ZipEncoder().encode(archive, level: 0));
      final tag = failure == 'tag' ? 'v4.0.0' : 'v3.0.0-beta';
      final asset = {
        ..._asset(),
        'size': apk.length,
        'browser_download_url':
            'https://github.com/ChiffonMai-Labs/ChiffonMai/releases/download/$tag/ChiffonMai.apk',
        if (failure == 'digest') 'digest': null,
      };
      final release = {
        'tag_name': tag,
        'prerelease': true,
        'published_at': '2026-11-06T12:00:00Z',
        'body': 'GitHub 测试更新日志',
        'assets': [asset],
      };
      final requests = <http.Request>[];
      final manager = LZYCheckUpdateManager();
      Future<Map<String, dynamic>> check() => http.runWithClient(
            () => manager.checkUpdate(force: true),
            () => MockClient((request) async {
              requests.add(request);
              expect(request.url.toString(), isNot(manager.pastebinRawUrl));
              // 发布列表和 APK 范围读取均验证加速失败后的直连回退。
              if (request.url.host != 'api.github.com' &&
                  request.url.host != 'github.com') {
                return http.Response('', 403);
              }
              if (request.url.host == 'api.github.com') {
                return http.Response(
                    jsonEncode([
                      {...release, 'tag_name': 'v9.0.0', 'draft': true},
                      {...release, 'tag_name': 'v8.0.0', 'assets': []},
                      {
                        ...release,
                        'tag_name': 'v2.9.0',
                        'published_at': '2026-10-01T12:00:00Z'
                      },
                      release,
                    ]),
                    200,
                    headers: {
                      'content-type': 'application/json; charset=utf-8'
                    });
              }
              if (failure == 'range') return http.Response('', 200);
              final range = RegExp(r'^bytes=(\d+)-(\d+)$')
                  .firstMatch(request.headers['Range']!)!;
              final start = int.parse(range[1]!), end = int.parse(range[2]!);
              return http.Response.bytes(apk.sublist(start, end + 1), 206,
                  headers: {
                    'content-range': 'bytes $start-$end/${apk.length}'
                  });
            }),
          );
      final result = await check();
      expect(
          calls.where((c) => c.method == 'startBackgroundDownload'), isEmpty);
      if (failure != 'none') {
        expect(result['hasUpdate'], isFalse);
        expect(result['networkError'], isTrue);
        return;
      }
      expect(result['hasUpdate'], isTrue);
      expect(result['latestVersion'], '3.0.0-beta');
      expect(result['latestBuild'], 2054, reason: '必须读取 APK 实际构建号，不能从标签猜测');
      expect(result['githubReleaseTag'], tag);
      expect(result['updateLog'], 'GitHub 测试更新日志');
      expect(result['updateSource'], 'github');
      final byteRequests =
          requests.where((r) => r.headers.containsKey('Range'));
      expect(byteRequests, isNotEmpty);
      expect(
          byteRequests
              .every((r) => r.headers['Range'] != 'bytes=0-${apk.length - 1}'),
          isTrue);
      PackageInfo.setMockInitialValues(
          appName: 'ChiffonMai',
          packageName: 'cloud.chiffonmai.app',
          version: '3.0.0-beta',
          buildNumber: '2054',
          buildSignature: '');
      expect((await check())['hasUpdate'], isFalse, reason: '已安装同构建号不应反复提示更新');
    }, skip: !LZYCheckUpdateManager.useGitHubForUpdateCheck);
  }

  test('文件线路选择不改变发布信息来源，支持备用下载和纯直连', () async {
    for (final proxies in [
      [AppUpdateDownloadService.backupProxy],
      <String>[]
    ]) {
      final requests = <String>[];
      final service = makeService(requests);
      addTearDown(service.cancel);
      calls.clear();
      await service.startBackgroundDownload(
          version: '9.0.0',
          build: 90,
          downloadProxies: proxies,
          onProgress: (_, __, ___) {});
      expect(
          requests.single, startsWith(AppUpdateDownloadService.defaultProxy));
      final arguments = calls
          .singleWhere((call) => call.method == 'startBackgroundDownload')
          .arguments;
      expect(
          arguments['urls'],
          AppUpdateDownloadService.downloadUrls(
              '${_asset()['browser_download_url']}', proxies));
    }
  });

  test('版本不匹配或缺少摘要时不创建系统下载任务', () async {
    for (final service in [
      makeService([], tag: 'v8.0.0'),
      makeService([], asset: {..._asset(), 'digest': null})
    ]) {
      addTearDown(service.cancel);
      await expectLater(
          service.startBackgroundDownload(
              version: '9.0.0',
              build: 90,
              configuredProxies: [],
              onProgress: (_, __, ___) {}),
          throwsFormatException);
    }
    expect(calls.where((c) => c.method == 'startBackgroundDownload'), isEmpty);
  });

  test('取消发布信息准备后，不会继续创建后台任务', () async {
    final service = makeService([]);
    addTearDown(service.cancel);
    await expectLater(
        service.startBackgroundDownload(
            version: '9.0.0',
            build: 90,
            configuredProxies: [],
            onProgress: (_, __, ___) => service.cancel()),
        throwsA(isA<DioException>()
            .having((e) => e.type, '取消类型', DioExceptionType.cancel)));
    expect(calls, isEmpty);
  });

  test('取消后的旧状态查询不得把任务重新显示为下载中', () async {
    final pending = Completer<String>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel,
            (call) async {
      if (call.method == 'getUpdateState') return pending.future;
      if (call.method == 'cancelBackgroundDownload')
        return jsonEncode({'phase': 'cancelled'});
      return false;
    });
    final task = BackgroundAppUpdateService.instance;
    final refresh = task.refresh();
    await task.cancel();
    pending.complete(jsonEncode({'phase': 'downloading', 'downloadId': 123}));
    await refresh;
    expect(task.phase, 'cancelled');
    expect(task.active, isFalse);
  });

  test('恢复任务时移除旧配置遗留的较低版本安装包', () async {
    PackageInfo.setMockInitialValues(
        appName: 'ChiffonMai',
        packageName: 'cloud.chiffonmai.app',
        version: '3.0.0-beta',
        buildNumber: '54',
        buildSignature: '');
    var cancelled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel,
            (call) async {
      if (call.method == 'getUpdateState')
        return jsonEncode({
          'phase': 'ready',
          'version': '2.9.0',
          'build': 2052,
          'path': 'old-update.apk'
        });
      if (call.method == 'cancelBackgroundDownload') {
        cancelled = true;
        return jsonEncode({'phase': 'cancelled', 'version': '2.9.0'});
      }
      if (call.method == 'getPendingAutoInstallSuccess') return null;
      return false;
    });
    final task = BackgroundAppUpdateService.instance;
    await task.refresh();
    expect(cancelled, isTrue);
    expect(task.phase, 'cancelled');
    expect(task.state['path'], isNull);
  });

  test('系统拒绝创建任务时保留原生错误，避免误报后台下载成功', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel,
            (call) async {
      if (call.method == 'supportedAbis') return ['arm64-v8a'];
      throw PlatformException(code: 'APP_UPDATE_FAILED', message: '系统下载管理器不可用');
    });
    final service = makeService([]);
    addTearDown(service.cancel);
    await expectLater(
        service.startBackgroundDownload(
            version: '9.0.0',
            build: 90,
            configuredProxies: [],
            onProgress: (_, __, ___) {}),
        throwsA(isA<PlatformException>()
            .having((e) => e.message, '错误信息', contains('不可用'))));
  });
}
