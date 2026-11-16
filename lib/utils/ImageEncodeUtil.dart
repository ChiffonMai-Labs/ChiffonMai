import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:image/image.dart' as img;
import 'ExportDiagnostics.dart';

/// GPU 单边纹理尺寸的安全上限。
///
/// 各机型实际值常见为 8192 / 16384，Dart 侧查不到，只能按较低的一档取。
/// 超过设备上限时，Impeller 只把画布缩小、不缩放内容（引擎的
/// `snapshot_controller_impeller.cc`），于是图片只剩左上角：nova 14 反馈 Best50
/// （约 3000 逻辑高，3 倍约 9000 像素）右侧和下侧被截断约 10%，比例正好对应
/// 8192 的上限。预览走的是屏幕渲染，不受影响。
const double kMaxCaptureTextureSize = 8192.0;

// 整张截图还有原生纹理、像素读回和编码缓冲，单边限制无法约束总内存。
const int _maxCapturePixels = 8000000;

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

void _runJpegExport((_JpegJob, SendPort) request) {
  Isolate.exit(request.$2, _rgbaToJpegWorker(request.$1));
}

/// 图片编码工具类
/// 提供导出截图的编码、文件大小预估等功能
class ImageEncodeUtil {
  /// 请求下一帧并等待绘制完成，避免静止页面只注册回调却没有新帧。
  static Future<void> waitForFrame() {
    final binding = WidgetsBinding.instance;
    binding.scheduleFrame();
    return binding.endOfFrame.timeout(const Duration(seconds: 15),
        onTimeout: () =>
            throw StateError(appL10n.svcTheExportCanvasIsNotReady));
  }

  static Future<void> waitForRender(
      {int frames = 2,
      Duration settle = const Duration(milliseconds: 500)}) async {
    for (var i = 0; i < frames; i++) {
      await waitForFrame();
    }
    await Future<void>.delayed(settle);
  }

  /// 根据物理边长和像素总量选择截图倍率，再应用 JPEG 档位的缩放比例。
  static double safeCapturePixelRatio(double width, double height,
      {double preferred = 3.0, int? jpegQuality}) {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      return preferred;
    }
    // 给向上取整预留一像素，确保物理尺寸和总面积都在预算以内。
    final edgeRatio = (kMaxCaptureTextureSize - 1) / math.max(width, height);
    final areaRatio = math.sqrt(
        (_maxCapturePixels - 2 * kMaxCaptureTextureSize) / (width * height));
    final baseRatio = math.min(preferred, math.min(edgeRatio, areaRatio));
    return jpegQuality == null
        ? baseRatio
        : baseRatio * _scaleForQuality(jpegQuality);
  }

  static Future<ui.Image> _capture(
      RenderRepaintBoundary boundary, double ratio) async {
    var timedOut = false;
    final pending = boundary.toImage(pixelRatio: ratio).then((image) {
      if (timedOut) image.dispose();
      return image;
    });
    return pending.timeout(const Duration(seconds: 30), onTimeout: () {
      timedOut = true;
      throw TimeoutException(appL10n.flowGeneratingImage);
    });
  }

  /// 把导出画布截成图片并编码。
  ///
  /// PNG 由引擎在后台线程编码。JPEG 直接按目标尺寸截图，再把原始像素转交给
  /// 后台 isolate 编码：不再经过「编 PNG → 解 PNG → 缩放」这三步，既快得多，
  /// 也比事后缩放更清晰（文字是按目标尺寸重新光栅化的）。
  static Future<EncodedImage> encodeBoundary(
    RenderRepaintBoundary boundary, {
    int? jpegQuality,
  }) =>
      ExportDiagnostics.run('图片生成', (log) async {
        final size = boundary.size;
        if (!size.isFinite || size.isEmpty) {
          throw StateError(appL10n.svcTheExportCanvasIsNotReady);
        }
        final ratio = safeCapturePixelRatio(size.width, size.height,
            jpegQuality: jpegQuality);
        final expectedWidth = (boundary.size.width * ratio).ceil();
        final expectedHeight = (boundary.size.height * ratio).ceil();
        log.note('格式=${jpegQuality == null ? "PNG无损" : "JPEG Q$jpegQuality"} '
            '逻辑尺寸=${boundary.size.width.toStringAsFixed(1)}x${boundary.size.height.toStringAsFixed(1)} '
            'pixelRatio=${ratio.toStringAsFixed(4)} '
            '预计像素=${expectedWidth}x$expectedHeight '
            '预计RGBA=${(expectedWidth * expectedHeight * 4 / 1048576).toStringAsFixed(1)}MiB');
        ui.Image image;
        try {
          image = await log.step('截图 toImage', () => _capture(boundary, ratio));
        } on TimeoutException {
          // 引擎没有取消截图的 API，超时后不要叠加同一张截图。
          rethrow;
        } catch (e) {
          debugPrint('导出截图失败，降低截图尺寸后重试: $e');
          await waitForFrame();
          image = await log.step(
              '缩小尺寸重试截图 toImage', () => _capture(boundary, ratio * 0.7));
        }
        final width = image.width;
        final height = image.height;
        final ByteData? data;
        try {
          log.note('实际像素=${image.width}x${image.height} '
              '像素数=${image.width * image.height} '
              'RGBA占用估算=${(image.width * image.height * 4 / 1048576).toStringAsFixed(1)}MiB');
          data = await log.step(
            jpegQuality == null ? 'PNG编码 toByteData' : 'RGBA读回 toByteData',
            () => image
                .toByteData(
                    format: jpegQuality == null
                        ? ui.ImageByteFormat.png
                        : ui.ImageByteFormat.rawRgba)
                .timeout(const Duration(seconds: 40)),
          );
        } finally {
          image.dispose();
          log.note('截图资源已释放');
        }
        if (data == null) throw Exception(appL10n.flowCouldNotReadImageData);
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        log.note('读回数据=${bytes.lengthInBytes}B');
        if (jpegQuality == null) {
          log.note('PNG编码结果=${bytes.lengthInBytes}B');
          return EncodedImage(bytes, 'png');
        }
        // 创建传输数据也需要复制像素，单独计时，避免混入后台编码耗时。
        final pixels = await log.step(
            '准备JPEG像素传输', () async => TransferableTypedData.fromList([bytes]));
        final jpeg = await log.step(
          'JPEG后台编码',
          () => _encodeJpegExport(_JpegJob(pixels, width, height, jpegQuality)),
        );
        log.note('JPEG编码结果=${jpeg.lengthInBytes}B');
        return EncodedImage(jpeg, 'jpg');
      });

  static Future<Uint8List> _encodeJpegExport(_JpegJob job) async {
    final result = ReceivePort();
    Isolate? worker;
    try {
      worker = await Isolate.spawn(
        _runJpegExport,
        (job, result.sendPort),
        onError: result.sendPort,
        onExit: result.sendPort,
        debugName: 'export-jpeg',
      );
      final message = await result.first.timeout(const Duration(seconds: 60));
      if (message is Uint8List) return message;
      if (message is List && message.length == 2) {
        throw RemoteError(message[0].toString(), message[1].toString());
      }
      throw StateError(appL10n.flowCouldNotReadImageData);
    } finally {
      worker?.kill(priority: Isolate.immediate);
      result.close();
    }
  }

  /// 把图片编码成 JPEG，编码放在后台 isolate。
  static Future<Uint8List> encodeJpeg(ui.Image image,
      {int quality = 92}) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) throw Exception(appL10n.flowCouldNotReadImageData);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return compute(
      _rgbaToJpegWorker,
      _JpegJob(TransferableTypedData.fromList([bytes]), image.width,
          image.height, quality),
    );
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
    final cardAspectRatio =
        cardsPerRow <= 1 ? 1.5 : (cardsPerRow <= 5 ? 0.85 : 1.0);
    final cardPhysicalHeight = cardPhysicalWidth * cardAspectRatio;
    // 单卡原始 RGBA 字节数
    final rawBytesPerCard =
        (cardPhysicalWidth * cardPhysicalHeight * 4).round();
    // 单卡 PNG 压缩后字节数
    final pngBytesPerCard = (rawBytesPerCard * pngCompressionRatio).round();

    // 基础开销：顶部/底部 padding + 背景（约 80 逻辑 px 高）
    final baseHeight = 80 * pixelRatio;
    final baseBytes =
        (physicalWidth * baseHeight * 4 * pngCompressionRatio).round();

    // Header 区域（标题 + 评分统计，约 350 逻辑 px 高）
    int headerBytes = 0;
    if (hasHeader) {
      final headerHeight = 350 * pixelRatio;
      headerBytes =
          (physicalWidth * headerHeight * 4 * pngCompressionRatio).round();
    }

    // 用户信息区域（头像 + 昵称 + 元信息，约 80 逻辑 px 高）
    int userInfoBytes = 0;
    if (hasUserInfo) {
      final userInfoHeight = 80 * pixelRatio;
      userInfoBytes =
          (physicalWidth * userInfoHeight * 4 * pngCompressionRatio).round();
    }

    // 行间距（每行约 12 逻辑 px 的间距）
    final rows = (songCount / cardsPerRow).ceil();
    final rowSpacingHeight = 12 * pixelRatio;
    final spacingBytes = rows *
        (physicalWidth * rowSpacingHeight * 4 * pngCompressionRatio).round();

    return baseBytes +
        headerBytes +
        userInfoBytes +
        spacingBytes +
        (songCount * pngBytesPerCard);
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
