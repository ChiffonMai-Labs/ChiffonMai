import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/l10n/app_localizations.dart';
import 'package:my_first_flutter_app/service/AppUpdateDownloadService.dart';
import 'package:my_first_flutter_app/service/BackgroundAppUpdateService.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/widgets/AppDialogs.dart';
import 'package:my_first_flutter_app/widgets/AppToast.dart';
import 'package:my_first_flutter_app/widgets/AppUpdateInstallPrompt.dart';
import 'package:my_first_flutter_app/widgets/AppUpdateSuccessDialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final task = BackgroundAppUpdateService.instance;
  final calls = <MethodCall>[];
  var settings = <String, dynamic>{};
  var download = <String, dynamic>{};
  var nextId = 700;
  Map<String, dynamic>? installedUpdate;

  setUp(() {
    calls.clear();
    installedUpdate = null;
    AppTheme.debugLocalFontFamily = true;
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
        appName: 'ChiffonMai',
        packageName: 'cloud.chiffonmai.app',
        version: '3.0.0-beta',
        buildNumber: '54',
        buildSignature: '');
    settings = {
      'enabled': true,
      'supported': true,
      'canInstall': true,
      'busy': false
    };
    download = {
      'phase': 'ready',
      'downloadId': ++nextId,
      'build': 2054,
      'version': '3.0.0-beta',
      'autoManualRequired': false
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel,
            (call) async {
      calls.add(call);
      if (call.method == 'acknowledgeAutoInstallSuccess') {
        if ((call.arguments as Map)['id'] != installedUpdate?['id'])
          return false;
        installedUpdate = null;
        return true;
      }
      return switch (call.method) {
        'getAutoInstallSettings' => settings,
        'getUpdateState' => jsonEncode(download),
        'takePendingUpdateAction' => false,
        'getPendingAutoInstallSuccess' =>
          installedUpdate == null ? null : jsonEncode(installedUpdate),
        'requestForegroundInstall' => 'requested',
        _ => null,
      };
    });
  });

  tearDown(() {
    AppTheme.debugLocalFontFamily = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(AppUpdateDownloadService.channel, null);
  });

  Future<void> host(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      navigatorKey: BackgroundExport.navigatorKey,
      navigatorObservers: [task.navigationObserver],
      theme: AppTheme.lightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      builder: (_, child) => Stack(children: [
        child!,
        const Positioned(top: 0, left: 0, right: 0, child: AppToastHost())
      ]),
      home: const Scaffold(body: Text('当前页面')),
    ));
    await tester.pumpAndSettle();
    await task.refresh();
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  testWidgets('自动更新成功显示当前版本及该版本日志，展示后持久确认且不再重复提示', (tester) async {
    download = {};
    installedUpdate = {
      'id': '${++nextId}:54',
      'version': '3.0.0-beta',
      'build': 54,
      'updateLog': '修复谱面评分读取',
    };
    await host(tester);
    final prompt = task.maybePromptForInstalledUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateSuccessDialog), findsOneWidget);
    expect(find.text('自动更新成功'), findsOneWidget);
    expect(find.textContaining('3.0.0-beta'), findsOneWidget);
    expect(find.textContaining('54'), findsOneWidget);
    expect(find.text('修复谱面评分读取'), findsOneWidget);
    expect(installedUpdate, isNull);
    expect(
        calls.where((c) => c.method == 'acknowledgeAutoInstallSuccess').length,
        1);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    await prompt;
    await task.refresh();
    await task.maybePromptForInstalledUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateSuccessDialog), findsNothing);
    await close(tester);
  });

  testWidgets('没有自动安装成功记录或记录已不是当前版本时不报成功', (tester) async {
    download = {};
    await host(tester);
    await task.maybePromptForInstalledUpdate();
    expect(find.byType(AppUpdateSuccessDialog), findsNothing);
    installedUpdate = {
      'id': '${++nextId}:53',
      'version': '2.9.0',
      'build': 53,
    };
    await task.refresh();
    await task.maybePromptForInstalledUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateSuccessDialog), findsNothing);
    expect(installedUpdate, isNull);
    await close(tester);
  });

  testWidgets('其他弹窗期间保留成功记录，主页面恢复后再展示', (tester) async {
    download = {};
    installedUpdate = {
      'id': '${++nextId}:54',
      'version': '3.0.0-beta',
      'build': 54,
    };
    await host(tester);
    final context =
        BackgroundExport.navigatorKey.currentState!.overlay!.context;
    final other = showDialog<void>(
        context: context,
        builder: (context) =>
            AppAlertDialog(title: const Text('其它操作'), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('完成')),
            ]));
    await tester.pumpAndSettle();
    await task.maybePromptForInstalledUpdate();
    expect(find.byType(AppUpdateSuccessDialog), findsNothing);
    expect(installedUpdate, isNotNull);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await other;
    final prompt = task.maybePromptForInstalledUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateSuccessDialog), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();
    await prompt;
    await close(tester);
  });

  testWidgets('下载就绪只提示一次，稍后不会发起安装或取消后台规则', (tester) async {
    await host(tester);
    final check = task.maybePromptForReadyUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateInstallPrompt), findsOneWidget);
    expect(calls.where((c) => c.method == 'requestForegroundInstall'), isEmpty);
    await tester.tap(find.text('稍后'));
    await tester.pumpAndSettle();
    await check;
    await task.maybePromptForReadyUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateInstallPrompt), findsNothing);
    expect(
        calls.where((c) =>
            c.method == 'setAutoInstallEnabled' ||
            c.method == 'cancelBackgroundDownload' ||
            c.method == 'requestForegroundInstall'),
        isEmpty);
    expect(task.phase, 'ready');
    await close(tester);
  });

  testWidgets('只有明确确认后才传递当前下载编号和构建号', (tester) async {
    await host(tester);
    final check = task.maybePromptForReadyUpdate();
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出并更新'));
    await tester.pumpAndSettle();
    await check;
    final request =
        calls.singleWhere((c) => c.method == 'requestForegroundInstall');
    expect(request.arguments,
        {'downloadId': download['downloadId'], 'build': 2054});
    await close(tester);
  });

  testWidgets('未开启、无权限、正在忙或需要手动安装时不自动弹窗', (tester) async {
    await host(tester);
    for (final flags in [
      {...settings, 'enabled': false},
      {...settings, 'canInstall': false},
      {...settings, 'busy': true},
    ]) {
      settings = flags;
      await task.maybePromptForReadyUpdate();
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdateInstallPrompt), findsNothing);
    }
    settings = {'enabled': true, 'supported': true, 'canInstall': true};
    download['autoManualRequired'] = true;
    await task.refresh();
    await task.maybePromptForReadyUpdate();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateInstallPrompt), findsNothing);
    expect(calls.where((c) => c.method == 'requestForegroundInstall'), isEmpty);
    await close(tester);
  });

  testWidgets('其它弹窗显示期间不叠加更新提示', (tester) async {
    await host(tester);
    final context =
        BackgroundExport.navigatorKey.currentState!.overlay!.context;
    final other = showDialog<void>(
        context: context,
        builder: (context) => AppAlertDialog(
                title: const Text('其它操作'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('完成'))
                ]));
    await tester.pumpAndSettle();
    await task.maybePromptForReadyUpdate();
    expect(find.byType(AppUpdateInstallPrompt), findsNothing);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await other;
    await close(tester);
  });

  testWidgets('弹窗期间任务被替换后不能安装旧任务', (tester) async {
    await host(tester);
    final check = task.maybePromptForReadyUpdate();
    await tester.pumpAndSettle();
    download['downloadId'] = ++nextId;
    await task.refresh();
    await tester.pumpAndSettle();
    await tester.tap(find.text('退出并更新'));
    await tester.pumpAndSettle();
    await check;
    expect(calls.where((c) => c.method == 'requestForegroundInstall'), isEmpty);
    await close(tester);
  });
}
