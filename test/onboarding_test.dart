import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/page/OnboardingPage.dart';
import 'package:my_first_flutter_app/service/OnboardingStateStore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const permissions = MethodChannel('flutter.baseflow.com/permissions/methods');
  var permissionRequests = 0;
  var appExits = 0;

  setUp(() {
    permissionRequests = appExits = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissions, (call) async {
      if (call.method == 'checkPermissionStatus') return 0;
      if (call.method == 'requestPermissions') {
        permissionRequests++;
        return {for (final id in call.arguments as List) id: 1};
      }
      return true;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') appExits++;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissions, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('新用户和未完成当前版本的用户需要显示引导', () async {
    SharedPreferences.setMockInitialValues({});
    final store = OnboardingStateStore.instance;

    expect(await store.shouldShow(), isTrue);
    await store.markCompleted(accepted: true, agreedAt: DateTime(2026, 10, 25));
    expect(await store.shouldShow(), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('onboarding_agreement_version'),
        OnboardingStateStore.agreementVersion);
    expect(prefs.getBool('onboarding_guardian_consent'), isFalse);
  });

  test('未同意时不能写入完成记录', () async {
    SharedPreferences.setMockInitialValues({});
    await expectLater(
        OnboardingStateStore.instance
            .markCompleted(accepted: false, agreedAt: DateTime.now()),
        throwsStateError);
    expect(await OnboardingStateStore.instance.shouldShow(), isTrue);
  });

  test('旧版本完成记录会在当前引导版本升级后重新显示', () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed_version': OnboardingStateStore.currentVersion - 1,
    });

    expect(await OnboardingStateStore.instance.shouldShow(), isTrue);
  });

  testWidgets('六页引导可以逐页浏览并完成返回', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(tester.element(find.byType(Scaffold))).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OnboardingPage(),
                ),
              ),
              child: const Text('打开引导'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开引导'));
    await tester.pumpAndSettle();

    expect(find.text('欢迎来到 ChiffonMai'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
    expect(find.text('跳过'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('先认识一下 ChiffonMai'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('先刷新数据，再开始探索'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('把体验调成你喜欢的样子'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('协议与权限'), findsOneWidget);
    expect(find.text('相册与媒体'), findsOneWidget);
    expect(find.text('相机'), findsOneWidget);
    expect(find.text('位置'), findsOneWidget);
    expect(find.text('通知'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);

    final next = find.widgetWithText(FilledButton, '下一步');
    final allow = find.widgetWithText(TextButton, '允许');
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    expect(
        tester
            .widgetList<TextButton>(allow)
            .every((button) => button.onPressed == null),
        isTrue);
    expect(permissionRequests, 0);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(next).onPressed, isNotNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.ensureVisible(allow.first);
    await tester.tap(allow.first);
    await tester.pumpAndSettle();
    expect(permissionRequests, 1);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('准备完成！'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '开始探索'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '开始探索'));
    await tester.pumpAndSettle();
    expect(find.text('打开引导'), findsOneWidget);
    expect(await OnboardingStateStore.instance.shouldShow(), isFalse);
  });

  testWidgets('监护人需要单独勾选确认，记录确认方式', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
    }
    final entry = find.text('未满14周岁，由监护人完成同意');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    final confirmation = find.widgetWithText(FilledButton, '监护人同意');
    expect(tester.widget<FilledButton>(confirmation).onPressed, isNull);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();
    await tester.tap(confirmation);
    await tester.pumpAndSettle();
    expect(find.text('监护人已单独同意'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('把体验调成你喜欢的样子'), findsOneWidget);
    expect(await OnboardingStateStore.instance.shouldShow(), isTrue);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('开始探索'));
    await tester.pumpAndSettle();
    expect(await OnboardingStateStore.instance.shouldShow(), isFalse);
    expect(
        (await SharedPreferences.getInstance())
            .getBool('onboarding_guardian_consent'),
        isTrue);
  });

  testWidgets('连续返回退出应用不会绕过确认或写入完成记录', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(appExits, 1);
    expect(await OnboardingStateStore.instance.shouldShow(), isTrue);
  });
}
