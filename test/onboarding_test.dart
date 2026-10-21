import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/page/OnboardingPage.dart';
import 'package:my_first_flutter_app/service/OnboardingStateStore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('新用户和未完成当前版本的用户需要显示引导', () async {
    SharedPreferences.setMockInitialValues({});
    final store = OnboardingStateStore.instance;

    expect(await store.shouldShow(), isTrue);
    await store.markCompleted();
    expect(await store.shouldShow(), isFalse);
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
    expect(find.text('设置权限'), findsOneWidget);
    expect(find.text('相册与媒体'), findsOneWidget);
    expect(find.text('相机'), findsOneWidget);
    expect(find.text('位置'), findsOneWidget);
    expect(find.text('通知'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('准备完成！'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '开始探索'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '开始探索'));
    await tester.pumpAndSettle();
    expect(find.text('打开引导'), findsOneWidget);
    expect(await OnboardingStateStore.instance.shouldShow(), isFalse);
  });
}
