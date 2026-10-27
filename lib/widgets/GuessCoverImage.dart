import 'package:flutter/material.dart';

import '../utils/CoverUtil.dart';

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
