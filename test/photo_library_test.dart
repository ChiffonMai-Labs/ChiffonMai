import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/utils/PhotoLibrary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.example.app/photo_library');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('相册通道读取原始文件，保留导出的文件副本', () async {
    final directory = await Directory.systemTemp.createTemp('photo_test_');
    addTearDown(() => directory.delete(recursive: true));
    final file =
        await File('${directory.path}/export.jpg').writeAsBytes([1, 2]);
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'saveImage');
      expect(call.arguments, {'path': file.absolute.path});
      expect(await file.readAsBytes(), [1, 2]);
      return null;
    });

    await PhotoLibrary.saveFile(file);
    expect(await file.exists(), isTrue);
  });

  test('相册拒绝授权时清理临时文件并保留设置指引', () async {
    File? temporaryFile;
    messenger.setMockMethodCallHandler(channel, (call) async {
      temporaryFile = File(call.arguments['path'] as String);
      expect(await temporaryFile!.readAsBytes(), [3, 4]);
      throw PlatformException(code: 'PERMISSION_DENIED');
    });

    await expectLater(
      PhotoLibrary.saveBytes(Uint8List.fromList([3, 4]), 'cover.png'),
      throwsA(isA<PlatformException>().having(PhotoLibrary.failureMessage, '提示',
          appL10n.flowPhotoLibraryAddPermissionRequired)),
    );
    expect(await temporaryFile!.exists(), isFalse);
    expect(await temporaryFile!.parent.exists(), isFalse);
  });
}
