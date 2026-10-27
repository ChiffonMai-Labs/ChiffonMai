import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_flutter_app/utils/FeatureRegistry.dart';

/// 弃用的 AWMC 控制台已移除，其他公开功能保持可用。
void main() {
  List<String> allTitles({required bool loggedIn}) =>
      FeatureRegistry.allCategories(loggedIn)
          .expand((c) => c.items)
          .map((i) => i.title)
          .toList();

  test('弃用的 AWMC 控制台不再出现在功能注册表中', () {
    for (final loggedIn in [true, false]) {
      expect(
        allTitles(loggedIn: loggedIn).contains('AWMC 网关'),
        isFalse,
        reason: '首页搜索 / 收藏 / 全部功能不应再出现弃用入口',
      );
    }
  });

  test('我的分类的其它入口不受影响', () {
    final system =
        FeatureRegistry.allCategories(true).firstWhere((c) => c.name == '我的');
    final titles = system.items.map((i) => i.title).toList();

    expect(titles, contains('同步成绩到水鱼'));
    expect(titles, contains('同步成绩到落雪'));
    expect(titles, contains('同步成绩到 AWMC NET'));
    expect(titles, contains('访问官方网站'));
    expect(titles, contains('加入 QQ 群'));
    expect(titles, contains('数据备份'));
    expect(titles, contains('系统设置'));
    expect(titles.length, 28, reason: '我的分类新增账号注册引导，其它入口保留');
  });
}
