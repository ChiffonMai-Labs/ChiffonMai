import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 复用原生 M3 交互，以缓存图像绘制叉号和对钩，避免滑动动画逐帧排版字体图标。
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final MaterialTapTargetSize? materialTapTargetSize;

  const AppSwitch(
      {super.key,
      required this.value,
      required this.onChanged,
      this.materialTapTargetSize});

  // 非空占位保留 M3 带图标的滑块尺寸，同时绕过原生画笔的 TextPainter 分支。
  static const _noFontIcon = WidgetStatePropertyAll<Icon?>(Icon(null));

  static ({ImageProvider active, ImageProvider inactive}) _images(
      BuildContext context, bool enabled) {
    final scheme = Theme.of(context).colorScheme;
    final scale = MediaQuery.devicePixelRatioOf(context);
    return (
      active: _SwitchThumbImage(
          true,
          enabled
              ? scheme.onPrimaryContainer
              : scheme.onSurface.withValues(alpha: .38),
          scale),
      inactive: _SwitchThumbImage(
          false,
          enabled
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHighest.withValues(alpha: .38),
          scale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images(context, onChanged != null);
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: materialTapTargetSize,
      thumbIcon: _noFontIcon,
      activeThumbImage: images.active,
      inactiveThumbImage: images.inactive,
    );
  }
}

/// 整行点击、焦点、拖动及无障碍语义继续由原生 SwitchListTile 处理。
class AppSwitchListTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final Widget? secondary;
  final EdgeInsetsGeometry? contentPadding;

  const AppSwitchListTile(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.title,
      this.subtitle,
      this.secondary,
      this.contentPadding});

  @override
  Widget build(BuildContext context) {
    final images = AppSwitch._images(context, onChanged != null);
    return SwitchListTile(
      title: title,
      subtitle: subtitle,
      secondary: secondary,
      contentPadding: contentPadding,
      value: value,
      onChanged: onChanged,
      thumbIcon: AppSwitch._noFontIcon,
      activeThumbImage: images.active,
      inactiveThumbImage: images.inactive,
    );
  }
}

/// Flutter ImageCache 按形状、主题颜色和像素密度复用；仅在首次使用时画一次路径。
class _SwitchThumbImage extends ImageProvider<_SwitchThumbImage> {
  final bool checked;
  final Color color;
  final double scale;
  const _SwitchThumbImage(this.checked, this.color, this.scale);

  @override
  Future<_SwitchThumbImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
      _SwitchThumbImage key, ImageDecoderCallback decode) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(key.scale);
    final paint = Paint()
      ..color = key.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    if (key.checked) {
      path.moveTo(6.5, 12);
      path.lineTo(10, 15.5);
      path.lineTo(17.5, 8);
    } else {
      path.moveTo(8, 8);
      path.lineTo(16, 16);
      path.moveTo(16, 8);
      path.lineTo(8, 16);
    }
    canvas.drawPath(path, paint);
    final picture = recorder.endRecording();
    final image =
        picture.toImageSync((24 * key.scale).ceil(), (24 * key.scale).ceil());
    picture.dispose();
    return OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: image, scale: key.scale)));
  }

  @override
  bool operator ==(Object other) =>
      other is _SwitchThumbImage &&
      checked == other.checked &&
      color == other.color &&
      scale == other.scale;
  @override
  int get hashCode => Object.hash(checked, color, scale);
}
