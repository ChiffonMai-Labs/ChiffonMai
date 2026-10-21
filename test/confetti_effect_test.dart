import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/utils/ConfettiPreferences.dart';
import 'package:my_first_flutter_app/widgets/ConfettiEffect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('纸屑偏好默认值和设置值都会保存', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = ConfettiPreferences.instance;
    await preferences.load();

    expect(preferences.enabled, isTrue);
    expect(preferences.harmonyColor, isNull);
    expect(preferences.harmonyLevel, closeTo(0.35, 0.001));
    expect(preferences.paperType, ConfettiPaperType.mixed);
    expect(preferences.position, ConfettiBurstPosition.allEdges);

    const harmonyColor = Color(0xFF7E8CE0);
    await preferences.setEnabled(false);
    await preferences.setHarmonyColor(harmonyColor);
    await preferences.setHarmonyLevel(0.8);
    await preferences.setPaperType(ConfettiPaperType.ribbon);
    await preferences.setPosition(ConfettiBurstPosition.leftRight);

    final saved = await SharedPreferences.getInstance();
    expect(saved.getBool(CacheKeyConstant.confettiEnabled), isFalse);
    expect(saved.getInt(CacheKeyConstant.confettiHarmonyColor),
        harmonyColor.toARGB32());
    expect(saved.getDouble(CacheKeyConstant.confettiHarmonyLevel),
        closeTo(0.8, 0.001));
    expect(saved.getString(CacheKeyConstant.confettiPaperType), 'ribbon');
    expect(saved.getString(CacheKeyConstant.confettiPosition), 'leftRight');
  });

  testWidgets('手动预览会插入纸屑动画并在动画结束后移除', (tester) async {
    BuildContext? capturedContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    await tester.pump();

    expect(capturedContext, isNotNull);
    final baselinePaintCount =
        tester.widgetList<CustomPaint>(find.byType(CustomPaint)).length;
    ConfettiEffect.show(capturedContext!, force: true);
    await tester.pump();
    expect(
      tester.widgetList<CustomPaint>(find.byType(CustomPaint)).length,
      greaterThan(baselinePaintCount),
    );

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    expect(
      tester.widgetList<CustomPaint>(find.byType(CustomPaint)).length,
      baselinePaintCount,
    );
  });
}
