// 回归：「提交二维码后弹窗 controller 被提前释放」。
//
// 症状（用户实测）：提交二维码 → 点「开始同步」→ 抛
//   A TextEditingController was used after being disposed.
// 但**同步照常进行**（结果早已从 pop 返回，所以只看到报错）。
//
// 原因：`showDialog` 返回的 future 是 `Route.popped` —— pop 那一刻就完成，
// 而弹窗还要走完**退场动画**才从 overlay 移除；此前在 future 完成后立刻
// `dispose()`，退场期间（真机上键盘收起会让弹窗重建）再读 controller 就炸。
// 修法：等 `Route.completed`（文档：退场动画结束、overlay 条目移除后才完成）。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/utils/SecureCredentialStore.dart';
import 'package:my_first_flutter_app/widgets/RefreshDataDialog.dart';
import 'package:my_first_flutter_app/widgets/SyncScoreDialogs.dart';

const String _qr = 'SGWCMAID0123456789012345678901234567890';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold(body: SizedBox.expand());
      }),
    ));
    return ctx;
  }

  /// pop 的瞬间 + 退场动画期间（模拟键盘收起触发的重建）都不能有异常。
  Future<void> expectCleanExit(WidgetTester tester) async {
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'pop 的瞬间不该读已释放的 controller');

    tester.view.viewInsets = const FakeViewPadding(bottom: 0);
    addTearDown(tester.view.reset);
    await tester.pump(const Duration(milliseconds: 40));
    expect(tester.takeException(), isNull,
        reason: '退场动画期间弹窗重建，同样不该读已释放的 controller');

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('水鱼二维码弹窗：提交后退场全程无异常，且返回值完好', (tester) async {
    final ctx = await pumpHost(tester);

    final future = showDivingFishSyncInputDialog(ctx);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _qr);
    await tester.pump();

    await tester.ensureVisible(find.text('开始同步'));
    await tester.pumpAndSettle();
    final submit = tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, '开始同步'),
        )
        .onPressed!;
    submit();
    submit();
    await expectCleanExit(tester);

    final result = await future;
    expect(result, isNotNull, reason: '退场不该影响返回值');
    expect(result!.qrCode, _qr);
  });

  testWidgets('落雪二维码弹窗：提交后退场全程无异常', (tester) async {
    final ctx = await pumpHost(tester);
    await SecureCredentialStore.write(
        CacheKeyConstant.probeLxnsImportToken, 'lxns-api-key-probe');

    final future = showLuoXueSyncInputDialog(ctx);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), _qr);
    await tester.pump();

    await tester.ensureVisible(find.text('开始同步'));
    await tester.pumpAndSettle();
    final submit = tester
        .widget<FilledButton>(
          find.widgetWithText(FilledButton, '开始同步'),
        )
        .onPressed!;
    submit();
    submit();
    await expectCleanExit(tester);

    final result = await future;
    expect(result, isNotNull);
    expect(result!.qrCode, _qr);
    expect(result.lxnsImportToken, 'lxns-api-key-probe');
  });

  testWidgets('取消（不填内容直接关）也要能安全释放', (tester) async {
    final ctx = await pumpHost(tester);

    final future = showDivingFishSyncInputDialog(ctx);
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消'));
    await expectCleanExit(tester);

    expect(await future, isNull);
  });

  testWidgets('刷新入口只打开一次，连点确认只关闭自己的弹窗', (tester) async {
    final ctx = await pumpHost(tester);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.awmcLookupQQ, '123456');
    final result =
        showRefreshDataDialog(ctx, initialSource: RefreshDataSource.awmc);
    final duplicate = showRefreshDataDialog(ctx);
    await tester.pumpAndSettle();
    expect(await duplicate, isNull);

    final confirm = tester
        .widget<TextButton>(
          find.widgetWithText(TextButton, '确认'),
        )
        .onPressed!;
    confirm();
    confirm();
    await expectCleanExit(tester);
    expect((await result)?.qq, '123456');
    expect(ModalRoute.of(ctx)?.isCurrent, isTrue);
  });
}
