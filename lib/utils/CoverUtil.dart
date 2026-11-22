/**
 * 曲绘路径工具类
 *
 * 负责构建曲绘（封面图）的本地 assets 路径、网络 URL，以及带多级 fallback 的 Widget。
 *
 * 本地路径构建规则（基于歌曲 ID 位数）：
 *   - <5 位：直接使用 `assets/cover/{songId}.webp`
 *   - 5 位：剔除第一个 '1' 及其后面连续的 '0'，直到遇到第一个非 '0' 数字
 *           例: 11312 → 1312, 10125 → 125, 10025 → 25
 *   - 6 位：剔除前两位及其后面连续的 '0'，直到遇到第一个非 '0' 数字
 *           例: 121634 → 1634, 110234 → 234, 100034 → 34
 *
 * 本地资源缺失时，曲绘组件依次尝试水鱼、AWMC、旧曲绘索引和默认图。
 */
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../service/AwmcCoverService.dart';
import '../service/DxRatingCoverService.dart';
import '../widgets/DxRatingCoverImage.dart';
import '../widgets/ImageLoadingIndicator.dart';

class CoverUtil {
  // ===========================================================================
  // 基础路径构建
  // ===========================================================================

  /// 构建曲绘 assets 路径（最基础方法，**不做 id 剔除**）
  /// [coverId] 曲绘 ID，为 null 时使用 '0'
  ///
  /// ⚠️ 这个方法是给「拼候选路径 / 探测资源」用的，**不要拿来直接显示**：
  /// 5、6 位 songId 的资源名是剔除后的 id（11312 → `1312.webp`、121634 → `1634.webp`），
  /// 直读原始 id 必然失败。显示请用 [buildCoverWidget] / [buildCoverWidgetWithContext]
  /// （多级 fallback），要真实存在的本地路径用 [getLocalCoverPath]。
  /// 曲绘识别页的「匹配曲绘 / Top10 缩略图」就是因为直读这个路径而显示空白。
  static String buildCoverPath(String? coverId) =>
      'assets/cover/${coverId ?? '0'}.webp';

  // ===========================================================================
  // 内部辅助
  // ===========================================================================

  /// 剔除开头的第一个 '1' 及其后面连续的 '0'，直到遇到第一个非 '0' 数字。
  /// 若剔除后为空串则返回 '0'。
  ///
  /// 例: 11312→1312, 10125→125, 10025→25, 10000→0
  static String _stripLeadingOneAndZeros(String id) {
    if (id.isEmpty) return id;
    String result = id;
    // 剔除第一个 '1'
    if (result[0] == '1') {
      result = result.substring(1);
    }
    // 剔除后面连续的 '0'
    result = result.replaceAll(RegExp(r'^0+'), '');
    return result.isEmpty ? '0' : result;
  }

  /// 剔除前两位及其后面连续的 '0'，直到遇到第一个非 '0' 数字。
  /// 若剔除后为空串则返回 '0'。
  ///
  /// 用于 6 位数 ID 处理。例: 121634→1634, 110234→234, 100000→0
  static String _stripFirstTwoAndLeadingZeros(String id) {
    if (id.length < 2) return id;
    String result = id.substring(2);
    // 剔除后面连续的 '0'
    result = result.replaceAll(RegExp(r'^0+'), '');
    return result.isEmpty ? '0' : result;
  }

  // ===========================================================================
  // 本地曲绘路径（多级 fallback）
  // ===========================================================================

  /// 本地曲绘路径（主路径）
  ///
  /// 规则：
  /// - <5 位：直接使用 songId
  /// - 5 位：剔除第一个 '1' 及后面连续的 '0'
  /// - 6 位：剔除前两位及后面连续的 '0'
  static String getLocalCoverPath(String songId) {
    if (songId.length == 5) {
      return buildCoverPath(_stripLeadingOneAndZeros(songId));
    }
    if (songId.length == 6) {
      return buildCoverPath(_stripFirstTwoAndLeadingZeros(songId));
    }
    // <5 位：直接使用
    return buildCoverPath(songId);
  }

  /// 本地曲绘路径（备用路径1）
  ///
  /// - 6 位：回退到 5 位规则（剔除第一个 '1' 及后面连续的 '0'）
  /// - 其他位数：与 [getLocalCoverPath] 相同
  static String getLocalCoverPathRetry1(String songId) {
    if (songId.length == 6) {
      // 方法2: 先剔除第一个 '1'，再应用 5 位规则
      final afterRemoveOne =
          songId[0] == '1' ? songId.substring(1) : songId;
      return buildCoverPath(_stripLeadingOneAndZeros(afterRemoveOne));
    }
    return getLocalCoverPath(songId);
  }

  /// 本地曲绘路径（备用路径2）
  ///
  /// - 6 位：从右往左找第一个 '0'，保留其右侧内容（兼容宴会场谱面）
  /// - 其他位数：与 [getLocalCoverPath] 相同
  static String getLocalCoverPathRetry2(String songId) {
    if (songId.length == 6) {
      for (int i = songId.length - 1; i >= 0; i--) {
        if (songId[i] == '0') {
          return buildCoverPath(songId.substring(i + 1));
        }
      }
    }
    return buildCoverPath(songId);
  }

  /// 从 songId 中提取曲绘 ID
  ///
  /// 规则：
  /// - <5 位：直接返回 songId
  /// - 5 位：剔除第一个 '1' 及后面连续的 '0'（如 11312→1312, 10125→125, 10025→25）
  /// - 6 位（宴会场）：剔除前两位及后面连续的 '0'（如 121634→1634, 100018→18, 110234→234）
  ///
  /// 当返回 '0' 时表示无法映射到有效 cover id。
  static String extractCoverId(String songId) {
    if (songId.length == 5) {
      return _stripLeadingOneAndZeros(songId);
    }
    if (songId.length == 6) {
      return _stripFirstTwoAndLeadingZeros(songId);
    }
    return songId;
  }

  // ===========================================================================
  // 网络曲绘 URL
  // ===========================================================================

  /// 构建网络曲绘 URL（所有本地加载均失败时的最终 fallback）
  ///
  /// 规则：
  /// - 6 位 ID：剔除前两位及后面连续的 '0'
  /// - 不足 5 位：前面补 '0' 至 5 位
  /// - 目标 URL：https://www.diving-fish.com/covers/{coverId}.png
  static String getNetworkCoverUrl(String songId) {
    String coverId = songId;

    // 6 位数：剔除前两位及后面连续的 '0'
    if (coverId.length == 6) {
      coverId = _stripFirstTwoAndLeadingZeros(coverId);
    }
    // 不足 5 位：前面补 0 至 5 位
    if (coverId.length < 5) {
      coverId = coverId.padLeft(5, '0');
    }

    return 'https://www.diving-fish.com/covers/$coverId.png';
  }

  // ===========================================================================
  // 曲绘资源解析（供 ImageProvider / 视频导出等需要真实可加载资源处使用）
  // ===========================================================================

  /// 优先加载本地曲绘，单一 ImageProvider 的网络候选取 AWMC、旧曲绘索引或水鱼。
  /// 索引只读随包或已有文件，避免在谱面播放器初始化时下载目录。
  static Future<ImageProvider> resolveCoverProvider(String songId) async {
    final localCandidates = <String>[
      buildCoverPath(songId),
      getLocalCoverPath(songId),
      getLocalCoverPathRetry1(songId),
      getLocalCoverPathRetry2(songId),
    ];
    for (final path in localCandidates) {
      try {
        await rootBundle.load(path);
        return AssetImage(path);
      } catch (_) {
        // 本地资源不存在，继续尝试下一条候选路径
      }
    }
    final awmc = AwmcCoverService.instance;
    await awmc.ensureLoaded(allowNetwork: false);
    final legacy = DxRatingCoverService.instance;
    await legacy.ensureLoaded(allowNetwork: false);
    final coverUrl = awmc.coverUrlFor(songId) ?? legacy.coverUrlFor(songId);
    if (coverUrl != null) {
      return CachedNetworkImageProvider(
        coverUrl,
        cacheManager: dxRatingCoverCacheManager,
      );
    }
    return NetworkImage(getNetworkCoverUrl(songId));
  }

  // ===========================================================================
  // 曲绘 Widget（带多级 fallback）
  // ===========================================================================

  /// 多级 fallback 链（两个公开方法共用一份，别再各抄一份嵌套 errorBuilder）。
  ///
  /// 顺序：原始路径 → 主路径 → 备用1 → 备用2 → 水鱼 → AWMC → 旧曲绘索引 → 默认曲绘。
  static Widget _buildFallbackChain(String songId, double size) {
    // 原图 256×256。按导出用的 3 倍清晰度解码，小曲绘的列表省下大半解码量，
    // 导出图和高分屏也不会变糊；放大显示时仍用原图。
    final target = size.isFinite ? (size * 3).ceil() : 256;
    final int? cacheWidth = target > 0 && target < 256 ? target : null;
    return Image.asset(
      buildCoverPath(songId),
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          getLocalCoverPath(songId),
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              getLocalCoverPathRetry1(songId),
              fit: BoxFit.cover,
              cacheWidth: cacheWidth,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  getLocalCoverPathRetry2(songId),
                  fit: BoxFit.cover,
                  cacheWidth: cacheWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      getNetworkCoverUrl(songId),
                      fit: BoxFit.cover,
                      cacheWidth: cacheWidth,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const ImageLoadingIndicator(),
                      errorBuilder: (context, error, stackTrace) {
                        // AWMC 曲绘和旧缓存的网络兜底。
                        return DxRatingCoverImage(songId: songId);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  /// 构建曲绘 Widget
  ///
  /// 加载顺序：
  /// 1. 原始 songId 路径
  /// 2. 本地主路径
  /// 3. 本地备用路径1
  /// 4. 本地备用路径2
  /// 5. 网络加载（diving-fish）
  /// 6. AWMC 和旧索引（带磁盘缓存）
  /// 7. 默认曲绘 0.webp
  static Widget buildCoverWidget(String songId, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white),
      child: _buildFallbackChain(songId, size),
    );
  }

  /// 构建曲绘 Widget（带 BuildContext）
  ///
  /// 加载顺序与 [buildCoverWidget] 相同。
  static Widget buildCoverWidgetWithContext(
      BuildContext context, String songId, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white),
      child: _buildFallbackChain(songId, size),
    );
  }

  /// 构建曲绘 Widget（带 BuildContext + 圆角矩形）
  static Widget buildCoverWidgetWithContextRRect(
      BuildContext context, String songId, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: buildCoverWidgetWithContext(context, songId, size),
    );
  }
}
