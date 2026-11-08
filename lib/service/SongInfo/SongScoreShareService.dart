import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/LxnsAssetImage.dart';
import 'package:my_first_flutter_app/widgets/ExportStatsUi.dart';

/// 徽章颜色数据
class _BadgeColors {
  final Color bg;
  final Color fg;
  final String label;
  const _BadgeColors({required this.bg, required this.fg, required this.label});
}

/// 单曲成绩分享卡片服务
/// 将歌曲信息和玩家最佳成绩渲染为精美的分享图片
class SongScoreShareService {
  /// 导出为图片的主方法
  static Future<File?> convertToImage(
    BuildContext context, {
    required String songId,
    required String songTitle,
    required String artist,
    required String songType,
    required int levelIndex,
    required String levelStr,
    required double ds,
    required String genre,
    required int bpm,
    required double achievements,
    required int ra,
    required int dxScore,
    required int maxDxScore,
    required String fc,
    required String fs,
    required String rawRate,
    int? jpegQuality,
    ExportImageTheme theme = ExportImageTheme.light,
  }) async {
    OverlayEntry? overlayEntry;
    try {
      debugPrint('=== SongScoreShare: STARTING IMAGE CONVERSION ===');

      // 请求存储权限
      final status = await _requestStoragePermission();
      debugPrint('Storage permission: $status');

      // 读取用户信息
      final prefs = await SharedPreferences.getInstance();
      final userNickname = prefs.getString('userNickname') ?? '';
      final totalRating = prefs.getInt('best50TotalRA') ?? 0;
      final avatarId = prefs.getInt('selectedAvatarId') ?? 1;
      final avatarUrl = avatarId > 0 ? lxnsIconUrl(avatarId) : null;

      // 创建GlobalKey用于截图
      GlobalKey globalKey = GlobalKey();

      // 构建分享卡片Widget
      Widget imageWidget = RepaintBoundary(
        key: globalKey,
        child: _buildShareCard(
          theme: theme,
          context: context,
          songId: songId,
          songTitle: songTitle,
          artist: artist,
          songType: songType,
          levelIndex: levelIndex,
          levelStr: levelStr,
          ds: ds,
          genre: genre,
          bpm: bpm,
          achievements: achievements,
          ra: ra,
          dxScore: dxScore,
          maxDxScore: maxDxScore,
          fc: fc,
          fs: fs,
          rawRate: rawRate,
          userNickname: userNickname,
          totalRating: totalRating,
          avatarUrl: avatarUrl,
        ),
      );

      // 创建离屏OverlayEntry
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -9999,
          top: -9999,
          width: 1200,
          child: Material(
            type: MaterialType.transparency,
            child: imageWidget,
          ),
        ),
      );

      // 插入到Overlay并等待渲染
      Overlay.of(context).insert(overlayEntry);
      await _waitForRender();

      // 捕获为图片
      final boundary = globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('SongScoreShare: RenderRepaintBoundary not found');
        overlayEntry.remove();
        return null;
      }

      final encoded = await ImageEncodeUtil.encodeBoundary(boundary,
          jpegQuality: jpegQuality);
      final Uint8List finalBytes = encoded.bytes;
      final String extension = encoded.extension;
      overlayEntry.remove();

      // 保存图片
      return await _saveImage(finalBytes, songTitle, status.isGranted,
          extension: extension);
    } catch (e) {
      debugPrint('SongScoreShare: Error: $e');
      overlayEntry?.remove();
      return null;
    }
  }

  /// 构建与实际导出相同的预览 Widget。
  static Future<Widget> buildPreviewWidget({
    required BuildContext context,
    required String songId,
    required String songTitle,
    required String artist,
    required String songType,
    required int levelIndex,
    required String levelStr,
    required double ds,
    required String genre,
    required int bpm,
    required double achievements,
    required int ra,
    required int dxScore,
    required int maxDxScore,
    required String fc,
    required String fs,
    required String rawRate,
    ExportImageTheme theme = ExportImageTheme.light,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final avatarId = prefs.getInt('selectedAvatarId') ?? 1;
    return _buildShareCard(
      theme: theme,
      context: context,
      songId: songId,
      songTitle: songTitle,
      artist: artist,
      songType: songType,
      levelIndex: levelIndex,
      levelStr: levelStr,
      ds: ds,
      genre: genre,
      bpm: bpm,
      achievements: achievements,
      ra: ra,
      dxScore: dxScore,
      maxDxScore: maxDxScore,
      fc: fc,
      fs: fs,
      rawRate: rawRate,
      userNickname: prefs.getString('userNickname') ?? '',
      totalRating: prefs.getInt('best50TotalRA') ?? 0,
      avatarUrl: avatarId > 0 ? lxnsIconUrl(avatarId) : null,
    );
  }

  /// 构建分享卡片Widget
  static Widget _buildShareCard({
    required BuildContext context,
    required String songId,
    required String songTitle,
    required String artist,
    required String songType,
    required int levelIndex,
    required String levelStr,
    required double ds,
    required String genre,
    required int bpm,
    required double achievements,
    required int ra,
    required int dxScore,
    required int maxDxScore,
    required String fc,
    required String fs,
    required String rawRate,
    required String userNickname,
    required int totalRating,
    String? avatarUrl,
    ExportImageTheme theme = ExportImageTheme.light,
  }) {
    // UTAGE 宴会場检测（6位数ID的歌曲使用粉色主题）
    final bool isUtage = songId.length == 6;

    // 获取主题色（与 SongInfoPage 保持一致）
    final accentColor =
        isUtage ? Color(0xFFFF69B4) : ColorUtil.getCardColor(levelIndex);

    // 达成率百分比
    final achievementPercent = achievements;
    // 评级直接使用 API 返回的 rate 字段（与 userPlayDataManager 缓存一致）
    final rateDisplay = StringUtil.formatRate(rawRate);
    final typeLabel = StringUtil.formatSongType(songType);
    final dxScorePercent = maxDxScore > 0
        ? (dxScore / maxDxScore * 100).toStringAsFixed(2)
        : '0.00';

    // 难度名称（UTAGE 歌曲显示 ChartDifficulty.utageLabel，与 SongInfoPage 保持一致）
    final diffNames = ChartDifficulty.standardLabels;
    final diffName = isUtage
        ? ChartDifficulty.utageLabel
        : diffNames[levelIndex.clamp(0, 4)];

    // 星星等级（与 SongInfoPage._calculateStars 保持一致：带空格格式 "✦ 6"）
    final scoreRate = maxDxScore > 0 ? dxScore / maxDxScore : 0.0;
    final String starDisplay = _calcStars(scoreRate);
    // 星星 bonus（与 SongInfoPage._calculateStarsBonus 保持一致："✦ 6 +123"）
    final String starBonus = _calcStarsBonus(scoreRate, dxScore, maxDxScore);
    final Color starColor = _getStarColor(starDisplay);

    // FC/FS 颜色（与 SongInfoPage._buildBadge 保持一致）
    final fcColors = _getBadgeColors(fc);
    final fsColors = _getBadgeColors(fs);

    final hasUser = userNickname.isNotEmpty || totalRating > 0;
    final c = ExportPalette.forTheme(theme);
    // 连击、同步的前景色是配浅色底的，深色下提亮一些。
    Color onPanel(Color fg) =>
        c.isLight ? fg : Color.lerp(fg, Colors.white, 0.35)!;
    final heroForeground = Colors.white;
    Widget heroChip(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(text,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: heroForeground)),
        );

    return ExportPage(
      theme: theme,
      width: 1200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 头部：难度色渐变 + 曲绘 + 歌曲信息
          ExportHeroSurface(
            colors: [Color.lerp(accentColor, Colors.black, 0.5)!, accentColor],
            radius: 0,
            padding: const EdgeInsets.fromLTRB(44, 48, 44, 44),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 7),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: CoverUtil.buildCoverWidgetWithContext(
                      context, songId, 280),
                ),
                const SizedBox(width: 36),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(songTitle,
                          style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: heroForeground,
                              height: 1.18),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 10),
                      Text(artist,
                          style: TextStyle(
                              fontSize: 28,
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          heroChip(
                              isUtage ? ChartDifficulty.utageLabel : typeLabel),
                          heroChip('$diffName $levelStr'),
                          heroChip(context.l10n.flowConstantP0(
                              (ds.toStringAsFixed(1)).toString())),
                          heroChip('BPM $bpm'),
                          heroChip(genre),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 达成率：核心数据，大字突出
                      Expanded(
                        flex: 5,
                        child: ExportStatsPanel(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                        context.l10n.flowSongAchievement,
                                        style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w600,
                                            color: c.muted)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(rateDisplay,
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                    '${achievementPercent.toStringAsFixed(4)}%',
                                    maxLines: 1,
                                    style: TextStyle(
                                        fontSize: 96,
                                        height: 1.2,
                                        fontWeight: FontWeight.w900,
                                        color: c.ink,
                                        fontFeatures: [
                                          FontFeature.tabularFigures()
                                        ])),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasUser) ...[
                        const SizedBox(width: 14),
                        // 玩家
                        Expanded(
                          flex: 3,
                          child: ExportStatsPanel(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (avatarUrl != null) ...[
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                            avatarUrl,
                                            cacheManager:
                                                lxnsAssetCacheManager),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                                if (userNickname.isNotEmpty)
                                  Text(userNickname,
                                      style: TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          color: c.ink)),
                                if (totalRating > 0)
                                  Text(
                                      context.l10n.flowTotalRatingP0(
                                          (totalRating).toString()),
                                      style: TextStyle(
                                          fontSize: 24,
                                          color: c.muted,
                                          fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // 统计
                ExportStatsPanel(
                  child: Row(
                    children: [
                      _buildStatItem(
                        c: c,
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: ra.toString(),
                        accentColor: accentColor,
                      ),
                      _buildStatDivider(c),
                      _buildStatItem(
                        c: c,
                        icon: Icons.score_rounded,
                        label: context.l10n.flowDXScore2,
                        value: '$dxScore / $maxDxScore',
                        subtitle: '$dxScorePercent%',
                        accentColor: accentColor,
                      ),
                      _buildStatDivider(c),
                      _buildStatItem(
                        c: c,
                        icon: Icons.music_note_rounded,
                        label: context.l10n.flowCombo,
                        value: fcColors.label,
                        accentColor: accentColor,
                        valueColor: onPanel(fcColors.fg),
                      ),
                      _buildStatDivider(c),
                      _buildStatItem(
                        c: c,
                        icon: Icons.auto_awesome_rounded,
                        label: context.l10n.flowSync,
                        value: fsColors.label,
                        accentColor: accentColor,
                        valueColor: onPanel(fsColors.fg),
                      ),
                      _buildStatDivider(c),
                      // 星数（带 bonus 差值）
                      _buildStatItem(
                        c: c,
                        icon: Icons.stars_rounded,
                        label: context.l10n.flowStars,
                        value: starDisplay,
                        subtitle: starBonus,
                        accentColor: accentColor,
                        valueColor: starColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Generated by ChiffonMai',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
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

  /// 构建信息标签
  static Widget _buildInfoChip(String text, Color color,
      {bool filled = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        border: filled ? null : Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: filled ? Colors.white : color)),
    );
  }

  /// 构建统计项
  static Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color accentColor,
    required ExportPalette c,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: accentColor.withAlpha(180)),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              color: c.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: valueColor ?? c.ink,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 18,
                color: c.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 统计项分隔线
  static Widget _buildStatDivider(ExportPalette c) {
    return Container(
      width: 2,
      height: 80,
      color: c.track,
    );
  }

  // --- 星星和徽章颜色（与 SongInfoPage 保持一致）---

  /// 计算星星等级显示字符串（与 SongInfoPage._calculateStars 一致："✦ 6"）
  static String _calcStars(double scoreRate) {
    if (scoreRate >= 0.99) return '✦ 6';
    if (scoreRate >= 0.98) return '✦ 5.5';
    if (scoreRate >= 0.97) return '✦ 5';
    if (scoreRate >= 0.95) return '✦ 4';
    if (scoreRate >= 0.93) return '✦ 3';
    if (scoreRate >= 0.90) return '✦ 2';
    if (scoreRate >= 0.85) return '✦ 1';
    return '✦ 0';
  }

  /// 计算星星 bonus 差值（与 SongInfoPage._calculateStarsBonus 一致："✦ 6 +123"）
  static String _calcStarsBonus(double scoreRate, int score, int maxScore) {
    double starLevel = 0, minRate = 0.0;
    if (scoreRate >= 0.99) {
      starLevel = 6;
      minRate = 0.99;
    } else if (scoreRate >= 0.98) {
      starLevel = 5.5;
      minRate = 0.98;
    } else if (scoreRate >= 0.97) {
      starLevel = 5;
      minRate = 0.97;
    } else if (scoreRate >= 0.95) {
      starLevel = 4;
      minRate = 0.95;
    } else if (scoreRate >= 0.93) {
      starLevel = 3;
      minRate = 0.93;
    } else if (scoreRate >= 0.90) {
      starLevel = 2;
      minRate = 0.90;
    } else if (scoreRate >= 0.85) {
      starLevel = 1;
      minRate = 0.85;
    } else {
      starLevel = 0;
      minRate = 0.85;
    }

    int minScore = (maxScore * minRate).ceil();
    int difference = score - minScore;
    String symbol = difference >= 0 ? '+' : '';
    dynamic displayLevel = starLevel == 0 ? 1 : starLevel;
    final levelStr2 = displayLevel == displayLevel.roundToDouble()
        ? displayLevel.toInt().toString()
        : displayLevel.toString();
    return '✦ $levelStr2 $symbol$difference';
  }

  /// 获取星星颜色（与 SongInfoPage._getStarsColor 一致）
  static Color _getStarColor(String stars) {
    if (stars.startsWith('✦ 6') ||
        stars.startsWith('✦ 5.5') ||
        stars.startsWith('✦ 5')) return Colors.yellow;
    if (stars.startsWith('✦ 4') || stars.startsWith('✦ 3'))
      return Colors.orange;
    if (stars.startsWith('✦ 2') || stars.startsWith('✦ 1'))
      return Colors.green.shade300;
    if (stars.startsWith('✦ 0')) return Colors.grey;
    return Colors.white;
  }

  /// 获取徽章颜色（与 SongInfoPage._buildBadge 一致）
  static _BadgeColors _getBadgeColors(String text) {
    switch (text) {
      case 'app':
        return _BadgeColors(
            bg: Color(0xFFFFF3E0), fg: Color(0xFFF57C00), label: 'AP+');
      case 'ap':
        return _BadgeColors(
            bg: Color(0xFFFFF3E0), fg: Color(0xFFF57C00), label: 'AP');
      case 'fcp':
        return _BadgeColors(
            bg: Color(0xFFD4F4DD), fg: Color(0xFF2E7D32), label: 'FC+');
      case 'fc':
        return _BadgeColors(
            bg: Color(0xFFD4F4DD), fg: Color(0xFF2E7D32), label: 'FC');
      case 'fsp':
        return _BadgeColors(
            bg: Color.fromARGB(255, 224, 244, 255),
            fg: Color.fromARGB(255, 0, 135, 245),
            label: 'FS+');
      case 'fs':
        return _BadgeColors(
            bg: Color.fromARGB(255, 224, 244, 255),
            fg: Color.fromARGB(255, 0, 135, 245),
            label: 'FS');
      case 'sync':
        return _BadgeColors(
            bg: Color.fromARGB(255, 224, 244, 255),
            fg: Color.fromARGB(255, 0, 135, 245),
            label: 'SC');
      case 'fsd':
        return _BadgeColors(
            bg: Color(0xFFFFF3E0), fg: Color(0xFFF57C00), label: 'FDX');
      case 'fsdp':
        return _BadgeColors(
            bg: Color(0xFFFFF3E0), fg: Color(0xFFF57C00), label: 'FDX+');
      default:
        return _BadgeColors(
            bg: Colors.grey.shade200, fg: Colors.grey, label: '-');
    }
  }

  // --- 颜色辅助（与 SongInfoPage 一致）---

  // --- 权限和保存逻辑（复用现有模式）---

  static Future<PermissionStatus> _requestStoragePermission() async {
    final status = await Permission.storage.status;
    final photoStatus = await Permission.photos.status;
    final videoStatus = await Permission.videos.status;

    if (status.isGranted || photoStatus.isGranted || videoStatus.isGranted) {
      return status.isGranted ? status : photoStatus;
    }

    final results = await [
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ].request();

    return results[Permission.storage] ?? PermissionStatus.denied;
  }

  static Future<File?> _saveImage(
    Uint8List imageBytes,
    String songTitle,
    bool hasPermission, {
    String extension = 'png',
  }) async {
    Directory? directory;

    if (hasPermission) {
      try {
        String picturesPath = '/storage/emulated/0/Pictures';
        directory = Directory(picturesPath);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
        bool canWrite = await _checkDirectoryWritable(directory);
        if (!canWrite) {
          directory = null;
        }
      } catch (e) {
        debugPrint('SongScoreShare: Pictures dir error: $e');
        directory = null;
      }
    }

    if (directory == null) {
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (e) {
        try {
          directory = await getExternalStorageDirectory();
        } catch (e2) {
          debugPrint('SongScoreShare: No storage dir found');
          return null;
        }
      }
    }

    if (directory == null) return null;

    // Android: 尝试 MediaStore API
    if (Platform.isAndroid && hasPermission) {
      String? galleryPath = await _saveImageToGallery(
        imageBytes,
        'chiffonmai_${_sanitizeFileName(songTitle)}_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      if (galleryPath != null) {
        await _notifySystemGallery(galleryPath);
        return File(galleryPath);
      }
    }

    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final file = File(
      '${directory.path}/chiffonmai_${_sanitizeFileName(songTitle)}_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(imageBytes);

    if (Platform.isAndroid) {
      await _notifySystemGallery(file.path);
    }

    return file;
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(' ', '_');
  }

  static Future<String?> _saveImageToGallery(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      const MethodChannel channel =
          MethodChannel('com.example.app/media_store');
      final String? result = await channel.invokeMethod('saveImage', {
        'imageBytes': imageBytes,
        'fileName': fileName,
      });
      return result;
    } catch (e) {
      debugPrint('SongScoreShare: MediaStore error: $e');
      return null;
    }
  }

  static Future<void> _notifySystemGallery(String filePath) async {
    try {
      await MediaScanner.loadMedia(path: filePath);
    } catch (e) {
      debugPrint('SongScoreShare: MediaScanner error: $e');
    }
    try {
      const MethodChannel channel = MethodChannel('com.example.app/media_scan');
      await channel.invokeMethod('scanFile', {'path': filePath});
    } catch (e) {
      debugPrint('SongScoreShare: scanFile error: $e');
    }
    try {
      const MethodChannel channel = MethodChannel('com.example.app/media_scan');
      await channel.invokeMethod('scanImage', {'path': filePath});
    } catch (e) {
      debugPrint('SongScoreShare: scanImage error: $e');
    }
  }

  static Future<bool> _checkDirectoryWritable(Directory directory) async {
    try {
      String testFileName =
          'test_write_${DateTime.now().millisecondsSinceEpoch}.tmp';
      File testFile = File('${directory.path}/$testFileName');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _waitForRender() async {
    Completer<void> completer1 = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer1.complete());
    await completer1.future;

    Completer<void> completer2 = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer2.complete());
    await completer2.future;

    await Future.delayed(Duration(milliseconds: 500));
  }
}
