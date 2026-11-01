// 「成绩趋势」板块的位置回归测试。
//
// 要求：成绩趋势（`ChartHistorySection`，达成率 / DX 分曲线）必须
//   * **不嵌在**「玩家最佳成绩」卡片内部；
//   * 作为**独立板块排在它的下方**。
//
// 以前它是「玩家最佳成绩」Container 里的一段，看起来像成绩卡的一部分，
// 但它其实是"这张谱面的历史"，粒度是谱面而不是这一次成绩。
//
// SongInfoPage 会联网、读缓存、拉一堆数据，widget 测试里跑不动；
// 所以这里用**结构断言**钉住：把 build 方法里两个锚点之间的源码抽出来看包含关系。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/service/History/ChartHistoryCore.dart';
import 'package:my_first_flutter_app/service/History/ChartHistoryStore.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/widgets/ChartHistorySection.dart';

/// SongInfoPage 在 2026-11 拆成了主文件 + `lib/page/song_info/*.dart` 若干 part 文件，
/// 结构断言要把它们拼在一起看。
String _src() {
  final files = <File>[
    File('lib/page/SongInfoPage.dart'),
    ...Directory('lib/page/song_info')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path)),
  ];
  return files.map((f) => f.readAsStringSync()).join('\n');
}

/// 只看主文件（build 方法所在处），用于判断板块在页面上的先后顺序。
String _mainSrc() => File('lib/page/SongInfoPage.dart').readAsStringSync();

/// 取出某个方法从签名到下一个同级方法之前的源码（粗略按 `\n  Widget ` 分段）。
String _methodBody(String src, String signature) {
  final start = src.indexOf(signature);
  expect(start, greaterThanOrEqualTo(0), reason: '找不到 $signature');
  final next = src.indexOf('\n  Widget ', start + signature.length);
  return src.substring(start, next < 0 ? src.length : next);
}

ChartHistoryEvent ev(DateTime t, double ach, int dx) => ChartHistoryEvent(
      tMs: t.millisecondsSinceEpoch,
      achievement: ach,
      dxScore: dx,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ChartHistoryStore.instance.debugClearCache();
  });

  tearDown(() => ChartHistoryStore.instance.debugClearCache());

  /// 注入 loader：真实文件 I/O 在 widget 测试的 fake async 里永远不会完成。
  void seed(List<ChartHistoryEvent> events) {
    ChartHistoryStore.debugChartEventsLoader =
        (songId, levelIndex) async => events;
    ChartHistoryStore.debugChartBaselineLoader =
        (songId, levelIndex) async => null;
  }

  test('成绩趋势不再是「玩家最佳成绩」卡片内的子节点', () {
    final src = _src();
    // 2026-11 起成绩卡由 _buildBestScoreCard + _buildBestScoreBody 两个方法组成
    for (final sig in const [
      'Widget _buildBestScoreCard(',
      'Widget _buildBestScoreBody(',
    ]) {
      final body = _methodBody(src, sig);
      expect(body.contains("'玩家最佳成绩'") || sig.contains('Body'), isTrue);
      expect(body.contains('ChartHistorySection('), isFalse,
          reason: '成绩趋势还在「玩家最佳成绩」卡片里面（$sig）');
      expect(body.contains('_buildChartHistoryCard('), isFalse,
          reason: '成绩趋势还在「玩家最佳成绩」卡片里面（$sig）');
    }
  });

  test('成绩趋势卡片排在「玩家最佳成绩」下方', () {
    final main = _mainSrc();
    // ⚠️ 要找的是 build 里的**调用点**，不是方法定义。
    final cardCall = main.indexOf('_buildBestScoreCard(');
    final callIdx = main.indexOf('_buildChartHistoryCard(),');
    expect(cardCall, greaterThan(0), reason: 'build 里没有调用成绩卡');
    expect(callIdx, greaterThan(0), reason: '方法没有被调用');
    expect(_src().indexOf('Widget _buildChartHistoryCard()'), greaterThan(0),
        reason: '方法定义不见了');
    expect(callIdx, greaterThan(cardCall), reason: '独立板块必须出现在「玩家最佳成绩」之后');
  });

  test('独立板块复用 ChartHistorySection，并给足卡片内边距', () {
    final src = _src();
    final idx = src.indexOf('Widget _buildChartHistoryCard()');
    expect(idx, greaterThan(0));
    final body = src.substring(idx, idx + 1300);
    expect(body.contains('ChartHistorySection('), isTrue);
    expect(body.contains('cardStyle: true'), isTrue, reason: '独立板块要有自己的卡片外观');
    expect(body.contains('emptyPadding: EdgeInsets.zero'), isTrue,
        reason: '没有历史时必须整块 0 高，不能凭空撑出一块空白');
    expect(body.contains('songId: songId'), isTrue);
    expect(body.contains('levelIndex: _currentDiffIndex'), isTrue);
    expect(body.contains('textPadding'), isTrue);
    expect(body.contains('chartPadding'), isTrue);
  });

  test('两张卡片之间有显式间隔（用户反馈原来贴在一起）', () {
    final src = _src();
    final main = _mainSrc();
    final call = main.indexOf('_buildChartHistoryCard(),');
    expect(call, greaterThan(0));
    // 调用点**前面**必须紧挨着一个 SizedBox —— 卡片之间原本没有任何间距 widget
    // （旧代码里那个 12dp 在「玩家最佳成绩」卡片内部、垫在标题行下面）。
    final before = main.substring(call - 120, call);
    expect(before.contains('SizedBox(height:'), isTrue,
        reason: '「成绩趋势」和上方成绩卡之间必须有显式间隔');
    // 而且这个间隔在函数体内不该被复制一份，避免双重留白
    // （先去掉行注释：函数注释里就写了 `SizedBox(height: 10)` 作说明）
    final idx = src.indexOf('Widget _buildChartHistoryCard()');
    final body = src.substring(idx, idx + 1300).split('\n').map((l) {
      final c = l.indexOf('//');
      return c < 0 ? l : l.substring(0, c);
    }).join('\n');
    expect(body.contains('SizedBox(height'), isFalse,
        reason: '曲线为空时整块高度 0，函数体外层不许垫固定高度');
  });

  test('「玩家最佳成绩」四项数值齐全且顺序不变', () {
    // 2026-11 起四行文字改成两行两列的数值块（StatTile），
    // 间距由布局统一控制；这里钉住「四项都在、顺序不变」。
    final body = _methodBody(_src(), 'Widget _buildBestScoreBody(');
    final rows = <String, int>{
      'Rating': body.indexOf("label: 'Rating'"),
      '游玩次数': body.indexOf("label: '游玩次数'"),
      'DX分数': body.indexOf("label: 'DX分数（MAX"),
      'DX分数达成率': body.indexOf("label: 'DX分数达成率'"),
    };
    for (final e in rows.entries) {
      expect(e.value, greaterThan(0), reason: '找不到「${e.key}」这一项');
    }
    final ordered = rows.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    expect(ordered.map((e) => e.key).toList(),
        ['Rating', '游玩次数', 'DX分数', 'DX分数达成率']);
  });

  group('ChartHistorySection 的三种形态与内边距', () {
    Future<void> pump(
      WidgetTester tester, {
      required bool cardStyle,
      EdgeInsets emptyPadding = EdgeInsets.zero,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChartHistorySection(
              songId: 1,
              levelIndex: 0,
              cardStyle: cardStyle,
              emptyPadding: emptyPadding,
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('cardStyle=true 且无历史时：显示手动录入入口', (tester) async {
      seed(const []);
      await pump(tester, cardStyle: true);
      expect(find.text('添加成绩历史'), findsOneWidget);
      expect(tester.getSize(find.byType(ChartHistorySection)).height,
          greaterThan(0));
    });

    testWidgets('cardStyle 是纯外观参数：不改变空形态的高度口径', (tester) async {
      seed(const []);
      await pump(tester, cardStyle: false);
      expect(tester.getSize(find.byType(ChartHistorySection)).height,
          greaterThan(0));
    });

    testWidgets('有曲线时：卡片内边距真的生效（曲线不贴边）', (tester) async {
      seed([
        ev(DateTime(2026, 9, 1), 99.5, 2800),
        ev(DateTime(2026, 9, 10), 100.1, 2950),
        ev(DateTime(2026, 9, 18), 100.5, 3000),
      ]);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChartHistorySection(
              songId: 11312,
              levelIndex: 3,
              maxDxScore: 3375,
              cardStyle: true,
              emptyPadding: EdgeInsets.zero,
              textPadding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              chartPadding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final section = tester.getRect(find.byType(ChartHistorySection));
      final title = tester.getRect(find.textContaining('成绩历史（3 次变化）'));
      // 卡片内部：标题离卡片顶留出 chartPadding.top
      expect(title.top - section.top, greaterThanOrEqualTo(4),
          reason: '曲线不该贴着卡片上边缘');
      expect(title.left - section.left, greaterThanOrEqualTo(16));
    });
  });
}
