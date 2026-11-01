// 2026-11 UI 重构的布局回归：几个核心页面在窄屏 / 大字号 / 三套主题下不溢出。
//
// 设置环境变量 UI_PREVIEW_DIR 时会把每个场景渲染成 PNG 存到该目录，方便和设计稿对照：
//   UI_PREVIEW_DIR=build/ui_preview flutter test test/ui_canvas_layout_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/page/AchievementRateCalculatorPage.dart';
import 'package:my_first_flutter_app/page/ScoreHubPage.dart';
import 'package:my_first_flutter_app/utils/AppDesignTokens.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/widgets/AppUi.dart';
import 'package:my_first_flutter_app/widgets/Best50Ui.dart';

import 'support/real_fonts.dart';
import 'package:my_first_flutter_app/page/HomePage.dart';
import 'package:my_first_flutter_app/widgets/MainNavigationInsets.dart';
import 'package:my_first_flutter_app/utils/FavoriteFeaturesNotifier.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:my_first_flutter_app/page/UserScoreSearchPage.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';

const _boundary = ValueKey('preview-boundary');

final _records = [
  for (var i = 0; i < 12; i++)
    {
      'song_id': i == 0 ? 100 : 100 + i,
      'title': '示例曲 Neon Drift $i',
      'level_index': 3,
      'type': 'DX',
      'ds': 14.7 - i * 0.1,
      'achievements': 100.6 - i * 0.3,
      'ra': 330 - i,
      'dxScore': 2800,
      'fc': i % 3 == 0 ? 'fcp' : '',
      'fs': i % 4 == 0 ? 'fsp' : '',
      'rate': 'sssp',
    },
];

final _songs = [
  {
    'id': '100',
    'title': '示例曲 Neon Drift',
    'type': 'DX',
    'ds': [3.0, 7.0, 10.5, 14.7],
    'level': ['3', '7', '10+', '14+'],
    'cids': [1, 2, 3, 4],
    'charts': [
      for (var i = 0; i < 4; i++)
        {
          'notes': [300, 100, 50, 40, 20],
          'charter': '示例谱师',
        },
    ],
    'basic_info': {
      'title': '示例曲 Neon Drift',
      'artist': '示例曲师',
      'genre': 'maimai',
      'bpm': 180,
      'release_date': '',
      'from': 'PRiSM',
      'is_new': false,
    },
  },
];

/// Hub 页本身透明，背景在 AppShell 上；这里补一层页面底色。
class _Page extends StatelessWidget {
  final Widget child;

  const _Page({required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: child,
      );
}

Best50CardData _card(int i) => Best50CardData(
      songId: 100 + i,
      title: '示例曲 $i',
      levelIndex: i % 5,
      type: i.isEven ? 'DX' : 'SD',
      rating: 330 - i,
      ds: 14.7 - i * 0.1,
      achievement: 100.5123 - i * 0.2,
      fc: i % 3 == 0 ? 'fcp' : '',
      fs: i % 4 == 0 ? 'fs' : '',
      stars: '✦${(i % 5) + 1}',
      dxScore: 2800,
      maxDxScore: 3000,
      badge: i == 2 ? 'PC 123' : null,
      onOpenSong: () {},
    );

/// Best50 页的主体结构（页面本身要读缓存，这里只验证版式）。
Widget _best50Body() => Builder(
      builder: (context) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Best50Hero(
                total: 15049,
                label: '当前 Rating（平均 301.0）',
                best35Sum: 10670,
                best15Sum: 4379,
                trailing: Best50SwitchPill(
                    label: '理论值', value: false, onChanged: (_) {}),
              ),
              const SizedBox(height: 12),
              SegmentedTabs(
                inlineCaption: true,
                items: const [
                  SegmentedTabItem('B35', caption: '10670'),
                  SegmentedTabItem('B15', caption: '4379'),
                ],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
              const SizedBox(height: 8),
              Best50MetaLine(best50MetaText('非当前版本最好成绩', [301, 302, 330])),
              const SizedBox(height: AppDesignTokens.cardGap),
              Best50Grid(items: [for (var i = 0; i < 9; i++) _card(i)]),
            ],
          ),
        ),
      ),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required ThemeData theme,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        theme: theme,
        debugShowCheckedModeBanner: false,
        builder: (context, app) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: app!,
        ),
        home: child,
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UI_PREVIEW_DIR'];
  if (dir == null) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(dir).create(recursive: true);
    await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() {
    AppTheme.debugLocalFontFamily = true;
  });
  tearDownAll(() {
    AppTheme.debugLocalFontFamily = false;
  });

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({
      'userNickname': '小蛋糕',
      CacheKeyConstant.userPlayData: jsonEncode({'records': _records}),
      CacheKeyConstant.cachedSongs: jsonEncode(_songs),
      CacheKeyConstant.favoriteFeatures: [
        'Best50', '成绩查询', '拟合 Best50', '达成率计算', '每日推荐', '同步成绩到水鱼',
      ],
    });
  });

  final scenes = <String, Widget Function()>{
    'calc': () => const AchievementRateCalculator(),
    'best50': _best50Body,
    'scores': () => const UserScoreSearchPage(),
    'song': () => const SongInfoPage(
        songId: '100', initialLevelIndex: 3, isDefaultLevelIndex: false),
    'hub': () => const _Page(child: ScoreHubPage()),
    'home': () => _Page(
        child: MainNavigationInsets(
            bottom: 100,
            child: HomePage(onEntertainmentTap: () {}))),
  };
  final variants = <(String, ThemeData Function(), double, double)>[
    ('light390', AppTheme.lightTheme, 390, 1),
    ('dark390', AppTheme.darkTheme, 390, 1),
    ('light360', AppTheme.lightTheme, 360, 1),
    ('light360big', AppTheme.lightTheme, 360, 1.3),
  ];

  for (final scene in scenes.entries) {
    for (final v in variants) {
      testWidgets('${scene.key} ${v.$1} 不溢出', (tester) async {
        await tester.runAsync(loadRealFonts);
        await tester.runAsync(FavoriteFeaturesNotifier.load);
        await _pump(tester, scene.value(),
            theme: v.$2(), width: v.$3, textScale: v.$4);
        expect(tester.takeException(), isNull);
        await _shot(tester, '${scene.key}_${v.$1}');
        // 首页 / 歌曲详情里有延时任务，卸载后跑完，否则框架报 Timer 未结束。
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(minutes: 10));
      });
    }
  }
}
