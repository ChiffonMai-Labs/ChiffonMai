import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:image/image.dart' as img;

/// GPU 单边纹理尺寸的安全上限。
///
/// 各机型实际值常见为 8192 / 16384，Dart 侧查不到，只能按较低的一档取。
/// 超过设备上限时，Impeller 只把画布缩小、不缩放内容（引擎的
/// `snapshot_controller_impeller.cc`），于是图片只剩左上角：nova 14 反馈 Best50
/// （约 3000 逻辑高，3 倍约 9000 像素）右侧和下侧被截断约 10%，比例正好对应
/// 8192 的上限。预览走的是屏幕渲染，不受影响。
const double kMaxCaptureTextureSize = 8192.0;

/// 允许压到的最小 pixelRatio。
///
/// **不是 1.0**：如果下限取 1.0，那张「逻辑高度本身就超过上限」的图会被
/// clamp 顶回超限值，保护等于失效（原来的三份内联实现都是这个毛病）。
/// 宁可出一张略缩的图，也不要黑屏。实际导出（宽 1200/1700、高几千）远够不到
/// 这个下限，雷霆模式的单行 50 列（宽约 17500）会压到 0.47，仍在下限之上。
const double kMinCapturePixelRatio = 0.4;

/// 编码好的导出图片。
class EncodedImage {
  final Uint8List bytes;
  final String extension;

  const EncodedImage(this.bytes, this.extension);
}

class _JpegJob {
  final TransferableTypedData pixels;
  final int width;
  final int height;
  final int quality;

  const _JpegJob(this.pixels, this.width, this.height, this.quality);
}

/// [compute] 的 worker。**必须是顶层函数**（闭包不能跨 isolate 传递）。
Uint8List _rgbaToJpegWorker(_JpegJob job) {
  final image = img.Image.fromBytes(
    width: job.width,
    height: job.height,
    bytes: job.pixels.materialize(),
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  return img.encodeJpg(image, quality: job.quality);
}

/// 图片编码工具类
/// 提供导出截图的编码、文件大小预估等功能
class ImageEncodeUtil {
  /// 把导出画布截成图片并编码。
  ///
  /// PNG 由引擎在后台线程编码。JPEG 直接按目标尺寸截图，再把原始像素转交给
  /// 后台 isolate 编码：不再经过「编 PNG → 解 PNG → 缩放」这三步，既快得多，
  /// 也比事后缩放更清晰（文字是按目标尺寸重新光栅化的）。
  static Future<EncodedImage> encodeBoundary(
    RenderRepaintBoundary boundary, {
    int? jpegQuality,
  }) async {
    var ratio = safeCapturePixelRatio(boundary.size.width, boundary.size.height);
    if (jpegQuality != null) {
      ratio = math.max(
          ratio * _scaleForQuality(jpegQuality), kMinCapturePixelRatio);
    }
    ui.Image image;
    try {
      image = await boundary.toImage(pixelRatio: ratio);
    } catch (e) {
      debugPrint('导出截图失败，重试一次: $e');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      image = await boundary.toImage(pixelRatio: ratio);
    }
    try {
      final data = await image.toByteData(
          format: jpegQuality == null
              ? ui.ImageByteFormat.png
              : ui.ImageByteFormat.rawRgba);
      if (data == null) throw Exception('无法读取图片数据');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      if (jpegQuality == null) return EncodedImage(bytes, 'png');
      // 转交而不是复制：上百 MB 的像素复制一次也会让界面顿一下。
      final jpeg = await compute(
        _rgbaToJpegWorker,
        _JpegJob(TransferableTypedData.fromList([bytes]), image.width,
            image.height, jpegQuality),
      );
      return EncodedImage(jpeg, 'jpg');
    } finally {
      image.dispose();
    }
  }

  /// 导出截图该用的 pixelRatio：优先 [preferred]，但**保证物理尺寸不超过
  /// [kMaxCaptureTextureSize]**。
  ///
  /// 为什么必须有这道闸：B50 导出图很高（50 行，约 3600×7400 @3.0），
  /// 物理边长一旦超过机型 GPU 的最大纹理尺寸，`toImage` 就会返回**空白/黑图**
  /// —— 这就是「部分用户导出黑屏」；而同一次分配的位图可达上百 MB，
  /// 又会把 App 拖死。机型越差越容易中，所以表现为「有人有问题有人没有」。
  ///
  /// 已经有 3 个导出服务（PaiziProgress / SongInfo / PersonalizedScore）
  /// 各自内联过同一段逻辑，这里收成一份，别再抄第 7 份。
  static double safeCapturePixelRatio(
    double width,
    double height, {
    double preferred = 3.0,
  }) {
    if (width <= 0 || height <= 0) return preferred;
    var ratio = preferred;
    if (width * ratio > kMaxCaptureTextureSize) {
      ratio = kMaxCaptureTextureSize / width;
    }
    if (height * ratio > kMaxCaptureTextureSize) {
      ratio = kMaxCaptureTextureSize / height;
    }
    // 下限刻意低于 1.0：见 [kMinCapturePixelRatio] 的注释
    return ratio.clamp(kMinCapturePixelRatio, preferred);
  }

  /// 根据 JPEG 质量计算缩放因子。
  ///
  /// JPEG 对 UI 截图（纯色块 + 文字）压缩效率有限，
  /// 通过降分辨率来真正减小文件体积：缩放因子 s 会让像素数减少 s²。
  /// - quality 95 → 85% 宽度（72% 像素）
  /// - quality 85 → 65% 宽度（42% 像素）
  /// - quality 70 → 50% 宽度（25% 像素）
  static double _scaleForQuality(int quality) {
    if (quality >= 95) return 0.85;
    if (quality >= 90) return 0.75;
    if (quality >= 85) return 0.65;
    if (quality >= 80) return 0.58;
    if (quality >= 70) return 0.50;
    return 0.42;
  }

  /// 根据 PNG 预估大小和 JPEG quality 估算 JPEG 文件大小。
  ///
  /// 估算同时考虑两个因素：
  /// 1. **缩放**：降分辨率使像素数减少 scale²
  /// 2. **JPEG 编码**：在缩放后的基础上进一步压缩
  ///
  /// [pngSize] 是 [estimatePngSize] 的返回值（已含 PNG 压缩比 ~18% of raw）
  static int estimateJpegSize(int pngSize, int quality) {
    final scale = _scaleForQuality(quality);
    // 面积随线性缩放平方减少
    final scaleFactor = scale * scale;

    // JPEG 编码在缩放后基础上的进一步压缩比
    double jpegRatio;
    if (quality >= 95) {
      jpegRatio = 0.70;
    } else if (quality >= 90) {
      jpegRatio = 0.60;
    } else if (quality >= 85) {
      jpegRatio = 0.50;
    } else if (quality >= 80) {
      jpegRatio = 0.48;
    } else if (quality >= 70) {
      jpegRatio = 0.42;
    } else {
      jpegRatio = 0.38;
    }
    return (pngSize * scaleFactor * jpegRatio).round();
  }

  /// 根据数据条目数和渲染参数预估 PNG 文件大小
  ///
  /// 基于实际渲染参数计算：
  /// - 容器宽度: 1200 逻辑像素
  /// - 默认 pixelRatio: 3.0（与导出代码 toImage(pixelRatio: 3.0) 一致）
  /// - 物理宽度 = 1200 × pixelRatio = 3600px
  /// - 5 列布局卡片较大（含曲绘），每卡约 240×240 逻辑 px → 720×720 物理 px
  /// - 12 列布局卡片较小（纯文字），每卡约 100×60 逻辑 px → 300×180 物理 px
  /// - PNG 对 UI 混合内容（纯色+文字+曲绘）的压缩比约 18%
  ///
  /// [songCount] 歌曲/数据条目数量
  /// [hasHeader] 是否有标题/评分区域
  /// [hasUserInfo] 是否有用户信息区域
  /// [cardsPerRow] 每行卡片数（默认5列B50布局，牌子/成绩页为12列）
  /// [pixelRatio] 设备像素比（默认3.0，与导出代码 toImage(pixelRatio: 3.0) 一致）
  static int estimatePngSize({
    required int songCount,
    bool hasHeader = true,
    bool hasUserInfo = true,
    double cardsPerRow = 5,
    double pixelRatio = 3.0,
  }) {
    const double containerWidth = 1200.0; // 导出容器固定宽度
    const double pngCompressionRatio = 0.18; // PNG 对 UI 混合内容的典型压缩比

    final physicalWidth = containerWidth * pixelRatio;

    // 每张卡片的物理像素尺寸
    final cardPhysicalWidth = physicalWidth / cardsPerRow;
    // 卡片宽高比：单列详情页较高，多列卡片依布局而定
    // 12列曲绘网格为正方形(childAspectRatio:1.0)，5列列表含曲绘约0.85
    final cardAspectRatio = cardsPerRow <= 1 ? 1.5 : (cardsPerRow <= 5 ? 0.85 : 1.0);
    final cardPhysicalHeight = cardPhysicalWidth * cardAspectRatio;
    // 单卡原始 RGBA 字节数
    final rawBytesPerCard = (cardPhysicalWidth * cardPhysicalHeight * 4).round();
    // 单卡 PNG 压缩后字节数
    final pngBytesPerCard = (rawBytesPerCard * pngCompressionRatio).round();

    // 基础开销：顶部/底部 padding + 背景（约 80 逻辑 px 高）
    final baseHeight = 80 * pixelRatio;
    final baseBytes = (physicalWidth * baseHeight * 4 * pngCompressionRatio).round();

    // Header 区域（标题 + 评分统计，约 350 逻辑 px 高）
    int headerBytes = 0;
    if (hasHeader) {
      final headerHeight = 350 * pixelRatio;
      headerBytes = (physicalWidth * headerHeight * 4 * pngCompressionRatio).round();
    }

    // 用户信息区域（头像 + 昵称 + 元信息，约 80 逻辑 px 高）
    int userInfoBytes = 0;
    if (hasUserInfo) {
      final userInfoHeight = 80 * pixelRatio;
      userInfoBytes = (physicalWidth * userInfoHeight * 4 * pngCompressionRatio).round();
    }

    // 行间距（每行约 12 逻辑 px 的间距）
    final rows = (songCount / cardsPerRow).ceil();
    final rowSpacingHeight = 12 * pixelRatio;
    final spacingBytes = rows * (physicalWidth * rowSpacingHeight * 4 * pngCompressionRatio).round();

    return baseBytes + headerBytes + userInfoBytes + spacingBytes + (songCount * pngBytesPerCard);
  }

  /// 格式化文件大小为可读字符串
  /// 例如：1024 → "1.00 KB", 1048576 → "1.00 MB"
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
