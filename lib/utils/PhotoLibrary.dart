import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

import '../l10n/AppMessages.dart';

/// 将图片写入 iOS 照片图库，权限由 PhotoKit 请求。
class PhotoLibrary {
  static const _channel = MethodChannel('com.example.app/photo_library');

  static Future<void> saveFile(File file) =>
      _channel.invokeMethod<void>('saveImage', {'path': file.absolute.path});

  static Future<void> saveBytes(Uint8List bytes, String fileName) async {
    final directory =
        await Directory.systemTemp.createTemp('chiffonmai_photo_');
    try {
      final file =
          await File('${directory.path}/$fileName').writeAsBytes(bytes);
      await saveFile(file);
    } finally {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException catch (error) {
        debugPrint('清理相册导出临时文件失败：$error');
      }
    }
  }

  static String failureMessage(Object error) {
    if (error is PlatformException && error.code == 'PERMISSION_DENIED') {
      return appL10n.flowPhotoLibraryAddPermissionRequired;
    }
    return appL10n.flowCouldNotSaveToPhotoLibrary;
  }
}
