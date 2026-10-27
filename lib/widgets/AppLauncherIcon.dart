import 'package:flutter/material.dart';

/// 启动页与关于页共用的图标，前景留白与 Android 自适应图标保持一致。
class AppLauncherIcon extends StatelessWidget {
  const AppLauncherIcon({super.key, required this.size});

  final double size;

  // 对应 mipmap-anydpi-v26/ic_launcher.xml；Android 前景 108dp，桌面可视区 72dp。
  static const double foregroundInset = .17;
  static const double _viewportRatio = 72 / 108;
  static const Color _background = Color(0xFFAECB92);

  @override
  Widget build(BuildContext context) {
    final imageSize = size * (1 - 2 * foregroundInset) / _viewportRatio;
    final cacheWidth =
        (imageSize * MediaQuery.devicePixelRatioOf(context)).ceil();
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .24),
        child: ColoredBox(
          color: _background,
          child: Transform.scale(
            scale: 1 / _viewportRatio,
            child: Padding(
              padding: EdgeInsets.all(size * foregroundInset),
              child: Image.asset(
                'assets/icon.png',
                width: size,
                height: size,
                fit: BoxFit.contain,
                cacheWidth: cacheWidth,
                gaplessPlayback: true,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.image_not_supported_outlined,
                  size: size * .4,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
