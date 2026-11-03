import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 桌面小组件和通知栏的布局只能用 RemoteViews 白名单里的控件。
///
/// 用了别的（比如 View、Space）编译和 `flutter analyze` 都发现不了，到桌面上才会
/// 整块加载失败，表现为一片空白。Gradle 构建也不会报错，所以在这里拦住。
const _allowed = {
  'FrameLayout',
  'LinearLayout',
  'RelativeLayout',
  'GridLayout',
  'AnalogClock',
  'Button',
  'Chronometer',
  'ImageButton',
  'ImageView',
  'ProgressBar',
  'TextClock',
  'TextView',
  'ViewFlipper',
  'ListView',
  'GridView',
  'StackView',
  'AdapterViewFlipper',
};

void main() {
  final layouts = Directory('android/app/src/main/res/layout')
      .listSync()
      .whereType<File>()
      .where((file) => RegExp(r'[\\/](home_widget|portable_notification)[^\\/]*\.xml$')
          .hasMatch(file.path))
      .toList();

  test('能找到小组件和通知栏布局', () {
    expect(layouts.length, greaterThanOrEqualTo(6));
  });

  for (final file in layouts) {
    test('${file.uri.pathSegments.last} 只用 RemoteViews 支持的控件', () {
      final tags = RegExp(r'<([A-Za-z][\w.]*)')
          .allMatches(file.readAsStringSync())
          .map((match) => match.group(1)!)
          .toSet();
      expect(tags.difference(_allowed), isEmpty);
    });
  }
}
