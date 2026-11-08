import '../l10n/LocalizationsExtension.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../utils/ImageEncodeUtil.dart';
import '../widgets/AppToast.dart';

/// 壁纸裁剪：取景框按屏幕比例固定，双指缩放、单指拖动图片。
///
/// 确认后返回裁好的 JPEG 字节；取消返回 null，旧壁纸不受影响。
class WallpaperCropPage extends StatefulWidget {
  final String imagePath;

  const WallpaperCropPage({super.key, required this.imagePath});

  @override
  State<WallpaperCropPage> createState() => _WallpaperCropPageState();
}

class _WallpaperCropPageState extends State<WallpaperCropPage> {
  /// 输出长边上限，和选图时的压缩上限一致。
  static const double _maxOutputSide = 2560;
  static const double _maxZoom = 5;

  ui.Image? _image;
  bool _failed = false;
  bool _saving = false;

  /// 图片的显示缩放（屏幕像素 / 图片像素）和左上角相对取景框的位置。
  double _scale = 1;
  Offset _offset = Offset.zero;
  Rect? _frame;

  double _gestureStartScale = 1;
  Offset _gestureStartFocal = Offset.zero;
  Offset _gestureStartOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      // 解码由系统完成：低版本 Android 不支持 HEIC 等格式时走下面的失败提示。
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (e) {
      debugPrint('读取壁纸图片失败: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  double _coverScale(ui.Image image, Size frame) =>
      math.max(frame.width / image.width, frame.height / image.height);

  /// 取景框必须始终被图片铺满。
  Offset _clampOffset(Offset offset, double scale, ui.Image image, Size frame) {
    return Offset(
      offset.dx.clamp(frame.width - image.width * scale, 0.0),
      offset.dy.clamp(frame.height - image.height * scale, 0.0),
    );
  }

  void _syncFrame(Rect frame, ui.Image image) {
    if (_frame == frame) return;
    final size = frame.size;
    if (_frame == null) {
      // 初始铺满并居中。
      _scale = _coverScale(image, size);
      _offset = Offset(
        (size.width - image.width * _scale) / 2,
        (size.height - image.height * _scale) / 2,
      );
    } else {
      _scale = _scale.clamp(
          _coverScale(image, size), _coverScale(image, size) * _maxZoom);
      _offset = _clampOffset(_offset, _scale, image, size);
    }
    _frame = frame;
  }

  void _onScaleStart(ScaleStartDetails details) {
    _gestureStartScale = _scale;
    _gestureStartFocal = details.localFocalPoint;
    _gestureStartOffset = _offset;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final image = _image;
    final frame = _frame;
    if (image == null || frame == null) return;
    final cover = _coverScale(image, frame.size);
    final scale =
        (_gestureStartScale * details.scale).clamp(cover, cover * _maxZoom);
    // 以手指中心为锚点缩放，再叠加拖动。
    final startFocal = _gestureStartFocal - frame.topLeft;
    final focal = details.localFocalPoint - frame.topLeft;
    final imagePoint = (startFocal - _gestureStartOffset) / _gestureStartScale;
    setState(() {
      _scale = scale;
      _offset =
          _clampOffset(focal - imagePoint * scale, scale, image, frame.size);
    });
  }

  Future<void> _confirm() async {
    final image = _image;
    final frame = _frame;
    if (image == null || frame == null || _saving) return;
    setState(() => _saving = true);
    try {
      final source = Rect.fromLTWH(
        -_offset.dx / _scale,
        -_offset.dy / _scale,
        frame.width / _scale,
        frame.height / _scale,
      );
      final ratio =
          math.min(1.0, _maxOutputSide / math.max(source.width, source.height));
      final width = (source.width * ratio).round().clamp(1, 1 << 14);
      final height = (source.height * ratio).round().clamp(1, 1 << 14);
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        image,
        source,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final output = await picture.toImage(width, height);
      picture.dispose();
      final Uint8List bytes;
      try {
        bytes = await ImageEncodeUtil.encodeJpeg(output, quality: 92);
      } finally {
        output.dispose();
      }
      if (mounted) Navigator.of(context).pop(bytes);
    } catch (e) {
      debugPrint('裁剪壁纸失败: $e');
      if (mounted) {
        AppToast.show(context.l10n.wallpaperCropFailed);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    final media = MediaQuery.of(context);
    // 裁剪工具栏属于深色全屏工具界面（AGENTS.md §11 的例外）。
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          SizedBox(height: media.padding.top + 12),
          Text(
            context.l10n.wallpaperCropHint,
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _failed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.wallpaperReadFailed,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 14, color: Colors.white70),
                      ),
                    ),
                  )
                : image == null
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final area = constraints.biggest;
                          final aspect = media.size.width / media.size.height;
                          final height = math.min(
                              area.height - 8, (area.width - 32) / aspect);
                          final frame = Rect.fromCenter(
                            center: area.center(Offset.zero),
                            width: height * aspect,
                            height: height,
                          );
                          _syncFrame(frame, image);
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onScaleStart: _onScaleStart,
                            onScaleUpdate: _onScaleUpdate,
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  left: frame.left + _offset.dx,
                                  top: frame.top + _offset.dy,
                                  width: image.width * _scale,
                                  height: image.height * _scale,
                                  child: RawImage(
                                    image: image,
                                    fit: BoxFit.fill,
                                    filterQuality: FilterQuality.medium,
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CropMaskPainter(frame),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, media.padding.bottom + 12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: image == null || _saving ? null : _confirm,
                      child: Text(_saving
                          ? context.l10n.processing
                          : context.l10n.setWallpaper),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 压暗取景框以外的区域，并画出取景框边线。
class _CropMaskPainter extends CustomPainter {
  final Rect frame;

  const _CropMaskPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(frame),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
    canvas.drawRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_CropMaskPainter oldDelegate) =>
      oldDelegate.frame != frame;
}
