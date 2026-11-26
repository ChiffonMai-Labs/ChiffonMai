import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../service/Media/AwmcCoverService.dart';
import '../service/Media/DxRatingCoverService.dart';
import 'ImageLoadingIndicator.dart';

/// 网络备用曲绘专用磁盘缓存，复用旧缓存以保留已经下载的曲绘。
final CacheManager dxRatingCoverCacheManager = CacheManager(
  Config(
    'dxrating_covers_v1',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 1000,
  ),
);

/// 水鱼曲绘加载失败时，依次尝试 AWMC 缩略图、AWMC 原图和旧曲绘索引。
class DxRatingCoverImage extends StatefulWidget {
  /// 歌曲 id（水鱼 / union / 落雪口径都可以，内部会归一化）。
  final String songId;

  /// 与其它曲绘一致的填充方式。
  final BoxFit fit;

  /// 目标解码宽度（物理像素）；为 null 时按原图解码。
  final int? cacheWidth;

  const DxRatingCoverImage({
    super.key,
    required this.songId,
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  /// 与 `CoverUtil.buildCoverPath('0')` 一致（不 import 它，避免循环依赖）。
  static const String defaultCoverAsset = 'assets/cover/0.webp';

  @override
  State<DxRatingCoverImage> createState() => _DxRatingCoverImageState();
}

class _DxRatingCoverImageState extends State<DxRatingCoverImage> {
  static List<String> _collectUrls(String id) => [
        ...AwmcCoverService.instance.coverUrlsFor(id),
        if (DxRatingCoverService.instance.coverUrlFor(id) case final url?) url,
      ];

  late List<String> _urls = _collectUrls(widget.songId);

  @override
  void initState() {
    super.initState();
    if (_urls.isEmpty || !DxRatingCoverService.instance.isLoaded) {
      _resolve();
    }
  }

  @override
  void didUpdateWidget(covariant DxRatingCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) {
      _urls = _collectUrls(widget.songId);
      if (_urls.isEmpty || !DxRatingCoverService.instance.isLoaded) {
        _resolve();
      }
    }
  }

  Future<void> _resolve() async {
    final id = widget.songId;
    final awmc = AwmcCoverService.instance;
    final legacy = DxRatingCoverService.instance;
    await Future.wait([awmc.ensureLoaded(), legacy.ensureLoaded(allowNetwork: false)]);
    if (!mounted || widget.songId != id) return;
    final next = _collectUrls(id);
    if (!listEquals(_urls, next)) {
      setState(() => _urls = next);
    }
  }

  @override
  Widget build(BuildContext context) => _coverAt(0);

  Widget _coverAt(int index) {
    if (index >= _urls.length) {
      // 没有映射：显示默认曲绘；_resolve 拿到映射后会自动换成真曲绘
      return Image.asset(
        DxRatingCoverImage.defaultCoverAsset,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
    return CachedNetworkImage(
      key: ValueKey(_urls[index]),
      imageUrl: _urls[index],
      cacheManager: dxRatingCoverCacheManager,
      memCacheWidth: widget.cacheWidth,
      fit: widget.fit,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, _) => const ImageLoadingIndicator(),
      errorWidget: (context, _, __) => _coverAt(index + 1),
    );
  }
}
