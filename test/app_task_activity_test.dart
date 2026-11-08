import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/utils/AppTaskActivity.dart';

void main() {
  tearDown(() => expect(AppTaskActivity.count.value, 0));

  test('并发任务必须全部结束，提前完成的任务不能发布空闲状态', () async {
    final first = Completer<void>(), second = Completer<void>();
    final a = AppTaskActivity.run(() => first.future);
    final b = AppTaskActivity.run(() => second.future);
    expect(AppTaskActivity.count.value, 2);
    first.complete();
    await a;
    expect(AppTaskActivity.count.value, 1);
    second.complete();
    await b;
    expect(AppTaskActivity.count.value, 0);
  });

  test('同步抛错或异步失败都释放任务，不会永久阻止自动安装', () async {
    await expectLater(AppTaskActivity.run<void>(() => throw StateError('失败')),
        throwsStateError);
    final gate = Completer<void>();
    final task = AppTaskActivity.run(() => gate.future);
    expect(AppTaskActivity.count.value, 1);
    final check = expectLater(task, throwsStateError);
    gate.completeError(StateError('失败'));
    await check;
    expect(AppTaskActivity.count.value, 0);
  });

  test('嵌套任务保留外层保护，重复结束回调不会误释放其他任务', () async {
    final finish = AppTaskActivity.begin();
    await AppTaskActivity.run(() async {
      expect(AppTaskActivity.count.value, 2);
      finish();
      finish();
      expect(AppTaskActivity.count.value, 1);
    });
    expect(AppTaskActivity.count.value, 0);
  });
}
