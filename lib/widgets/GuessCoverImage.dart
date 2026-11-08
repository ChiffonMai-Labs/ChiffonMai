import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../utils/CoverUtil.dart';
import '../utils/GuessPixelation.dart';

/// 按破坏程度降低曲绘采样网格，再用最近邻放大，形成清晰的像素马赛克。
/// 单人和多人使用相同网格；计时前由页面预解码，展示时绝不回退到原图。
class GuessPixelatedCover extends StatelessWidget {
  const GuessPixelatedCover({super.key, required this.image, this.size = 200});
  final ImageProvider image;
  final double size;

  static ImageProvider provider(ImageProvider original,
      {int destructionLevel = GuessPixelation.defaultLevel}) {
    if (GuessPixelation.normalize(destructionLevel) == 0) return original;
    final pixels = GuessPixelation.pixelsForLevel(destructionLevel);
    return ResizeImage(original,
        width: pixels, height: pixels, allowUpscaling: false);
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Image(
            image: image,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            excludeFromSemantics: true,
            errorBuilder: (_, __, ___) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: SizedBox.square(
                      dimension: size,
                      child:  Center(child: Text(context.l10n.flowCouldNotLoadCoverArt2))),
                )),
      );
}

/// 猜歌曲绘只在歌曲变化时解析资源，倒计时和统计刷新沿用已解析的图片。
class GuessCoverImage extends StatefulWidget {
  const GuessCoverImage({
    super.key,
    required this.songId,
    required this.size,
    this.provider,
  });

  final String songId;
  final double size;
  final ImageProvider? provider;

  @override
  State<GuessCoverImage> createState() => _GuessCoverImageState();
}

class _GuessCoverImageState extends State<GuessCoverImage> {
  ImageProvider? _provider;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant GuessCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId ||
        oldWidget.provider != widget.provider) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final generation = ++_generation;
    _provider = widget.provider;
    _failed = false;
    if (_provider != null) return;
    try {
      final provider = await CoverUtil.resolveCoverProvider(widget.songId);
      if (!mounted || generation != _generation) return;
      setState(() => _provider = provider);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _failed = true);
    }
  }

  Widget _fallback() => CoverUtil.buildCoverWidgetWithContext(
      context, widget.songId, widget.size);

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: _failed
            ? _fallback()
            : provider == null
                ? ColoredBox(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  )
                : Image(
                    key: ValueKey(widget.songId),
                    image: provider,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  ),
      ),
    );
  }
}
