import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';

void main() {
  testWidgets('静止画布主动请求两帧后继续导出', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.binding.hasScheduledFrame, isFalse);
    final rendering = ImageEncodeUtil.waitForRender(settle: Duration.zero);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump();
    await tester.pump(Duration.zero);
    await rendering;
  });

  testWidgets('同一画布生成 PNG 无损和两档可解码 JPEG', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 80,
            height: 40,
            child: ColoredBox(color: Color(0xff3266ac)),
          ),
        ),
      ),
    );
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(key));

    for (final (quality, width, height) in [
      (null, 240, 120),
      (95, 204, 102),
      (85, 156, 78),
    ]) {
      final result = (await tester.runAsync(
        () => ImageEncodeUtil.encodeBoundary(boundary, jpegQuality: quality),
      ))!;
      expect(result.extension, quality == null ? 'png' : 'jpg');
      final decoded = (quality == null
          ? img.decodePng(result.bytes)
          : img.decodeJpg(result.bytes))!;
      expect((decoded.width, decoded.height), (width, height));
      final pixel = decoded.getPixel(0, 0);
      final tolerance = quality == null ? 0 : 3;
      expect(pixel.r, closeTo(0x32, tolerance));
      expect(pixel.g, closeTo(0x66, tolerance));
      expect(pixel.b, closeTo(0xac, tolerance));
    }
  });
}
