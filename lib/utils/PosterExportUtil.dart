import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'CoverUtil.dart';
import 'ExportImageTheme.dart';
import 'ExportPathUtil.dart';
import 'ExportUserInfoWidget.dart';
import 'ImageEncodeUtil.dart';

/// 通用长图海报离线渲染与相册/目录保存工具，供各模块图片导出服务共用。
class PosterExportUtil {
  PosterExportUtil._();

  static ExportImageTheme themeFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? ExportImageTheme.dark
          : ExportImageTheme.light;

  static Future<bool> requestStoragePermission() async {
    if (Platform.isIOS) return false;
    final status = await Permission.storage.status;
    final photoStatus = await Permission.photos.status;
    if (status.isGranted || photoStatus.isGranted) return true;
    final results = await [
      Permission.storage,
      Permission.photos,
    ].request();
    return (results[Permission.storage]?.isGranted ?? false) ||
        (results[Permission.photos]?.isGranted ?? false);
  }

  static Future<void> precacheCovers(
      BuildContext context, Iterable<String> songIds) async {
    final ids = {
      for (final id in songIds)
        if (id.trim().isNotEmpty) id.trim(),
    };
    await Future.wait([
      ExportUserInfoWidget.precacheFrame(context),
      for (final id in ids)
        CoverUtil.resolveCoverProvider(id)
            .then((provider) =>
                context.mounted ? precacheImage(provider, context) : null)
            .catchError((_) {}),
    ]).timeout(const Duration(seconds: 6), onTimeout: () => const []);
  }

  static Future<File?> captureAndSave(
    BuildContext context, {
    required double width,
    required String filePrefix,
    required String subDir,
    required Iterable<String> songIds,
    required WidgetBuilder builder,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
    Duration settle = const Duration(milliseconds: 500),
    String logTag = 'PosterExport',
  }) async {
    OverlayEntry? overlayEntry;
    var overlayInserted = false;
    try {
      final hasPermission = await requestStoragePermission();
      if (context.mounted) {
        await Future.wait([
          precacheCovers(context, songIds),
          background.precache(context),
        ]);
      }
      if (!context.mounted) return null;

      final globalKey = GlobalKey();
      overlayEntry = OverlayEntry(
        builder: (overlayContext) => Positioned(
          left: -9999,
          top: -9999,
          width: width,
          child: Material(
            type: MaterialType.transparency,
            child: RepaintBoundary(
              key: globalKey,
              child: builder(overlayContext),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(overlayEntry);
      overlayInserted = true;
      await ImageEncodeUtil.waitForRender(settle: settle);

      final boundary = globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        overlayEntry.remove();
        overlayInserted = false;
        return null;
      }
      final encoded = await ImageEncodeUtil.encodeBoundary(
        boundary,
        jpegQuality: jpegQuality,
      );
      overlayEntry.remove();
      overlayInserted = false;
      return await saveImageBytes(
        encoded.bytes,
        hasPermission,
        filePrefix: filePrefix,
        subDir: subDir,
        extension: encoded.extension,
        logTag: logTag,
      );
    } catch (e) {
      debugPrint('[$logTag] 导出失败: $e');
      if (overlayInserted) overlayEntry?.remove();
      return null;
    }
  }

  static Future<File> saveImageBytes(
    Uint8List bytes,
    bool hasPermission, {
    required String filePrefix,
    required String subDir,
    String extension = 'png',
    String logTag = 'PosterExport',
  }) async {
    final fileName =
        '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    if (Platform.isAndroid && hasPermission) {
      try {
        const channel = MethodChannel('com.example.app/media_store');
        final String? galleryPath = await channel.invokeMethod('saveImage', {
          'imageBytes': bytes,
          'fileName': fileName,
        });
        if (galleryPath != null) {
          try {
            await MediaScanner.loadMedia(path: galleryPath);
          } catch (_) {}
          return File(galleryPath);
        }
      } catch (e) {
        debugPrint('[$logTag] MediaStore 保存失败: $e');
      }
    }
    return ExportPathUtil.writeExportFile(
      fileName: fileName,
      bytes: bytes,
      subDir: subDir,
    );
  }
}
