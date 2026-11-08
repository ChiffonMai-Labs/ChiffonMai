import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 部分曲绘猜歌的选区：排除纯黑、纯白及只有少量压缩噪点的空块。
class GuessCoverCrop {
  GuessCoverCrop._();

  /// 返回相对于实际显示的居中正方形曲绘的选区；没有有效选区时返回 null。
  static Future<ui.Rect?> select(
      ImageProvider provider, ImageConfiguration configuration) async {
    // 保留宽高比，低分辨率像素只用于检测，显示仍复用原图。
    final stream = ResizeImage(provider,
            width: 256, height: 256, policy: ResizeImagePolicy.fit)
        .resolve(configuration);
    final completer = Completer<ImageInfo>();
    final listener = ImageStreamListener(
      (info, _) {
        if (completer.isCompleted) {
          info.dispose();
        } else {
          completer.complete(info);
        }
      },
      onError: (Object error, StackTrace? stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    ImageInfo? imageInfo;
    stream.addListener(listener);
    try {
      imageInfo = await completer.future.timeout(const Duration(seconds: 15));
      final image = imageInfo.image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw StateError(appL10n.flowCouldNotReadCoverPixels);
      return await compute(_choose, (
        pixels: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        width: image.width,
        height: image.height,
      ));
    } finally {
      stream.removeListener(listener);
      imageInfo?.dispose();
    }
  }

  static ui.Rect? _choose(({Uint8List pixels, int width, int height}) image) {
    final random = Random();
    final side = min(image.width, image.height);
    // 与 GuessCoverImage 的 BoxFit.cover 一致，非正方形图片先按中心取正方形。
    final originX = (image.width - side) ~/ 2;
    final originY = (image.height - side) ~/ 2;

    bool hasContent(ui.Rect rect) {
      final left = originX + (rect.left * side).floor();
      final top = originY + (rect.top * side).floor();
      final right = originX + (rect.right * side).ceil().clamp(1, side);
      final bottom = originY + (rect.bottom * side).ceil().clamp(1, side);
      var black = 0;
      var white = 0;
      var sumR = 0, sumG = 0, sumB = 0, squared = 0, dominant = 0;
      final colors = <int, int>{};
      for (var y = top; y < bottom; y++) {
        for (var x = left; x < right; x++) {
          final offset = (y * image.width + x) * 4;
          final r = image.pixels[offset];
          final g = image.pixels[offset + 1];
          final b = image.pixels[offset + 2];
          if (r <= 12 && g <= 12 && b <= 12) black++;
          if (r >= 243 && g >= 243 && b >= 243) white++;
          sumR += r;
          sumG += g;
          sumB += b;
          squared += r * r + g * g + b * b;
          // 忽略细小压缩色差，少量噪点不能让大片纯色背景通过检测。
          final key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
          final count = (colors[key] ?? 0) + 1;
          colors[key] = count;
          dominant = max(dominant, count);
        }
      }
      final count = (right - left) * (bottom - top);
      final blankThreshold = count * 0.98;
      final variance = squared / count -
          (sumR * sumR + sumG * sumG + sumB * sumB) / (count * count);
      return black < blankThreshold && white < blankThreshold &&
          dominant < blankThreshold && variance >= 48;
    }

    for (var attempt = 0; attempt < 48; attempt++) {
      final width = 0.1 + random.nextDouble() * 0.3;
      final height = 0.1 + random.nextDouble() * 0.3;
      final rect = ui.Rect.fromLTWH(random.nextDouble() * (1 - width),
          random.nextDouble() * (1 - height), width, height);
      if (hasContent(rect)) return rect;
    }

    // 大面积黑白留白时再覆盖扫描，避免随机重选仍一直漏掉有内容的区域。
    for (var y = 0; y < 8; y++) {
      for (var x = 0; x < 8; x++) {
        final rect = ui.Rect.fromLTWH(x * 0.1, y * 0.1, 0.3, 0.3);
        if (hasContent(rect)) return rect;
      }
    }
    return null;
  }
}
