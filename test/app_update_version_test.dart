import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/utils/ApkPublishedVersion.dart';
import 'package:my_first_flutter_app/utils/AppVersion.dart';

void main() {
  test('配置中的旧版本即使构建号更大也不能覆盖较新版本', () {
    expect(
        AppVersion.isNewer(
            remoteVersion: '2.9.0',
            remoteBuild: 2052,
            localVersion: '3.0.0-beta',
            localBuild: 54),
        isFalse);
    expect(
        AppVersion.isNewer(
            remoteVersion: '3.0.0-beta',
            remoteBuild: 2054,
            localVersion: '2.9.0',
            localBuild: 2052),
        isTrue);
  });
  test('同版本比较构建号，并正确处理稳定版和预发布编号', () {
    expect(
        AppVersion.isNewer(
            remoteVersion: '3.0.0-beta',
            remoteBuild: 2054,
            localVersion: '3.0.0-beta',
            localBuild: 2054),
        isFalse);
    expect(
        AppVersion.isNewer(
            remoteVersion: '3.0.0-beta',
            remoteBuild: 2055,
            localVersion: '3.0.0-beta',
            localBuild: 2054),
        isTrue);
    expect(AppVersion.compare('3.0.0', '3.0.0-beta'), greaterThan(0));
    expect(AppVersion.compare('3.0.0-beta.10', '3.0.0-beta.2'), greaterThan(0));
    expect(AppVersion.compare('v3.0.0-beta+54', '3.0.0-beta+2054'), 0);
    expect(
        AppVersion.isNewer(
            remoteVersion: 'invalid',
            remoteBuild: 9999,
            localVersion: '3.0.0',
            localBuild: 1),
        isFalse);
  });

  final manifest =
      File('test/fixtures/update_apk_manifest.bin').readAsBytesSync();
  test('解析真实公开 APK 的二进制清单，不从发布标签猜测 versionCode', () {
    final version = ApkPublishedVersion.fromManifest(manifest);
    expect(version.version, '3.0.0-beta');
    expect(version.build, 2054);
    expect(version.packageName, 'cloud.chiffonmai.app');
  });
  test('清单截断或分块损坏时拒绝读取版本', () {
    expect(
        () => ApkPublishedVersion.fromManifest(
            Uint8List.fromList(manifest.take(30).toList())),
        throwsFormatException);
    final damaged = Uint8List.fromList(manifest);
    ByteData.sublistView(damaged).setUint32(12, 0xffffffff, Endian.little);
    expect(
        () => ApkPublishedVersion.fromManifest(damaged), throwsFormatException);
  });

  test('按范围读取 ZIP 中的压缩清单，无需下载其余歌曲资源', () async {
    final archive = Archive()
      ..addFile(ArchiveFile('AndroidManifest.xml', manifest.length, manifest))
      ..addFile(ArchiveFile(
          'assets/unrelated.bin',
          200000,
          Uint8List.fromList(
              List<int>.generate(200000, (i) => (i * 11 + i ~/ 256) % 256))));
    final zip = Uint8List.fromList(ZipEncoder().encode(archive));
    final reads = <(int, int)>[];
    final version =
        await ApkPublishedVersion.read(zip.length, (offset, length) async {
      reads.add((offset, length));
      return Uint8List.sublistView(zip, offset, offset + length);
    });
    expect(version.build, 2054);
    expect(reads.length, 4);
    expect(reads[1].$2, lessThan(1024));
    expect(reads[2].$2, 30);
    expect(reads[3].$2, lessThan(manifest.length));
  });
  test('ZIP 损坏或范围返回不完整时不产生版本结果', () async {
    await expectLater(
        ApkPublishedVersion.read(100, (_, length) async => Uint8List(length)),
        throwsFormatException);
    await expectLater(
        ApkPublishedVersion.read(
            100, (_, length) async => Uint8List(length - 1)),
        throwsFormatException);
  });
}
