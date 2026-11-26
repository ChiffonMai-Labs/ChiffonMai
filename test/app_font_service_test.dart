import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/service/System/AppFontService.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppFontService 下载、校验 SHA-256、持久化并支持后续直接命中本地缓存', () async {
    final dir = await Directory.systemTemp.createTemp('app-font-test-');
    addTearDown(() async => dir.delete(recursive: true));

    final fakeTtf = <int>[
      0x00,
      0x01,
      0x00,
      0x00,
      ...List<int>.filled(2048, 0x2A),
    ];
    final expectedSha = sha256.convert(fakeTtf).toString();
    var downloadCalls = 0;
    String? registeredFamily;

    final service = AppFontService.forTesting(
      supportDirProvider: () async => dir,
      minValidBytes: 1024,
      downloader: (_, tempFile) async {
        downloadCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await tempFile.writeAsBytes(fakeTtf);
        return FontDownloadPayload(
          expectedSha256: expectedSha,
          expectedSize: fakeTtf.length,
        );
      },
      fontRegistrar: (family, bytes) async {
        registeredFamily = family;
        expect(bytes.length, fakeTtf.length);
      },
    );

    expect(await service.loadCachedIfPresent(), isFalse);

    final concurrent = await Future.wait([
      service.ensureLoaded(),
      service.ensureLoaded(),
    ]);
    expect(concurrent, everyElement(isTrue));
    expect(downloadCalls, 1);
    expect(registeredFamily, AppFontService.cjkFamily);
    expect(service.isCjkLoaded, isTrue);

    final cachedFile = File('${dir.path}/fonts/${AppFontService.cjkFileName}');
    expect(await cachedFile.exists(), isTrue);

    // 模拟冷启动后新实例，直接读取本地已校验缓存，0 网络下载。
    final reopened = AppFontService.forTesting(
      supportDirProvider: () async => dir,
      minValidBytes: 1024,
      downloader: (_, __) async {
        fail('已有有效缓存不应再次下载');
      },
      fontRegistrar: (_, __) async {},
    );
    expect(await reopened.loadCachedIfPresent(), isTrue);
    expect(reopened.isCjkLoaded, isTrue);
  });

  test('AppFontService 拒绝魔数错误或 SHA-256 不匹配的字体并清理临时文件', () async {
    final dir = await Directory.systemTemp.createTemp('app-font-bad-');
    addTearDown(() async => dir.delete(recursive: true));

    final service = AppFontService.forTesting(
      supportDirProvider: () async => dir,
      minValidBytes: 1024,
      downloader: (_, tempFile) async {
        await tempFile.writeAsBytes(List<int>.filled(2048, 0x00));
        return const FontDownloadPayload(expectedSha256: 'deadbeef');
      },
      fontRegistrar: (_, __) async {},
    );

    expect(await service.ensureLoaded(), isFalse);
    expect(service.isCjkLoaded, isFalse);
    final fontFile = File('${dir.path}/fonts/${AppFontService.cjkFileName}');
    final tmpFile = File('${fontFile.path}.tmp');
    expect(await fontFile.exists(), isFalse);
    expect(await tmpFile.exists(), isFalse);
  });

  test('AppTheme.font 与 withGlobalFonts 显式设置 wght 轴（含 w400）并保留测试旁路', () {
    AppTheme.debugLocalFontFamily = false;
    final bodyStyle = AppTheme.font(fontWeight: FontWeight.w400);
    expect(bodyStyle.fontFamily, AppFontService.primaryFamily);
    expect(bodyStyle.fontVariations, const [FontVariation('wght', 400.0)]);

    final boldNumber = AppTheme.number(fontWeight: FontWeight.w700);
    expect(boldNumber.fontFamily, AppFontService.primaryFamily);
    expect(boldNumber.fontVariations, const [FontVariation('wght', 700.0)]);
    expect(boldNumber.fontFeatures, const [FontFeature.tabularFigures()]);

    final themed = AppTheme.withGlobalFonts(AppTheme.lightTheme());
    expect(themed.textTheme.bodyMedium?.fontFamily, AppFontService.primaryFamily);
    expect(
      themed.textTheme.bodyMedium?.fontVariations,
      const [FontVariation('wght', 400.0)],
    );

    AppTheme.debugLocalFontFamily = true;
    addTearDown(() => AppTheme.debugLocalFontFamily = false);
    final testBypass = AppTheme.font(fontWeight: FontWeight.w700);
    expect(testBypass.fontFamily, 'NotoSansSC_700');
  });
}
