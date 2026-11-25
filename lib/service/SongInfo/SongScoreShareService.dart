import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:my_first_flutter_app/utils/ExportUserInfoWidget.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../../widgets/LxnsAssetImage.dart';
import 'package:my_first_flutter_app/widgets/ExportStatsUi.dart';

/// 徽章配色数据
class _BadgeColors {
  final Color bg;
  final Color fg;
  final String label;
  final String assetKey;
  const _BadgeColors({
    required this.bg,
    required this.fg,
    required this.label,
    required this.assetKey,
  });
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
    String? bpmText,
    String? charter,
    int? jpegQuality,
    ExportImageTheme theme = ExportImageTheme.light,
  }) async {
    OverlayEntry? overlayEntry;
    var overlayInserted = false;
    try {
      debugPrint('=== SongScoreShare: STARTING IMAGE CONVERSION ===');

      // 请求存储权限
      final status = await _requestStoragePermission();
      debugPrint('Storage permission: $status');

      // 统一读取玩家信息（昵称、Rating、头像、数据源、导出时间）
      final userInfo = await ExportUserInfoWidget.loadUserInfo();
      final userNickname = userInfo['nickname'] as String? ?? '';
      final totalRating = userInfo['totalRating'] as int? ?? 0;
      final avatarUrl = userInfo['avatarUrl'] as String? ?? '';
      final dataSource = userInfo['dataSource'] as String? ?? '';
      final exportTime = userInfo['exportTime'] as String? ?? '';

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
          bpmText: bpmText,
          charter: charter,
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
          dataSource: dataSource,
          exportTime: exportTime,
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
      overlayInserted = true;
      await ImageEncodeUtil.waitForRender();

      // 捕获为图片
      final boundary = globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('SongScoreShare: RenderRepaintBoundary not found');
        overlayEntry.remove();
        overlayInserted = false;
        return null;
      }

      final encoded = await ImageEncodeUtil.encodeBoundary(boundary,
          jpegQuality: jpegQuality);
      final Uint8List finalBytes = encoded.bytes;
      final String extension = encoded.extension;
      overlayEntry.remove();
      overlayInserted = false;

      // 保存图片
      return await _saveImage(finalBytes, songTitle, status.isGranted,
          extension: extension);
    } catch (e) {
      debugPrint('SongScoreShare: Error: $e');
      if (overlayInserted) overlayEntry?.remove();
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
    String? bpmText,
    String? charter,
    ExportImageTheme theme = ExportImageTheme.light,
  }) async {
    final userInfo = await ExportUserInfoWidget.loadUserInfo();
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
      bpmText: bpmText,
      charter: charter,
      achievements: achievements,
      ra: ra,
      dxScore: dxScore,
      maxDxScore: maxDxScore,
      fc: fc,
      fs: fs,
      rawRate: rawRate,
      userNickname: userInfo['nickname'] as String? ?? '',
      totalRating: userInfo['totalRating'] as int? ?? 0,
      avatarUrl: userInfo['avatarUrl'] as String? ?? '',
      dataSource: userInfo['dataSource'] as String? ?? '',
      exportTime: userInfo['exportTime'] as String? ?? '',
    );
  }

  /// 构建分享卡片 Widget（曲绘氛围海报风）
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
    String? bpmText,
    String? charter,
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
    String dataSource = '',
    String exportTime = '',
    ExportImageTheme theme = ExportImageTheme.light,
  }) {
    final c = ExportPalette.forTheme(theme);
    final bool isUtage = songId.length == 6;
    final bool isReMaster = !isUtage && levelIndex == ChartDifficulty.reMaster;
    final Color accentColor =
        ColorUtil.getExportCardColor(levelIndex, isUtage: isUtage);

    // 压暗头图底色，确保包括 Re:MASTER / ADVANCED 在内的所有难度都有清晰的白字对比度。
    final Color heroDeep = Color.lerp(accentColor, Colors.black, 0.74)!;
    final Color heroLight = Color.lerp(accentColor, Colors.black, 0.40)!;
    final Color ratingInk = c.isLight
        ? Color.lerp(accentColor, Colors.black,
            (levelIndex == 1 || isReMaster) ? 0.48 : 0.22)!
        : Color.lerp(accentColor, Colors.white, 0.36)!;

    final String typeText = isUtage ? 'UT' : (songType == 'DX' ? 'DX' : 'ST');
    final Color typeBg = isUtage
        ? const Color(0xFFD81B3C)
        : (songType == 'DX'
            ? const Color(0xFFC95A12)
            : const Color(0xFF1F4FA5));

    final diffNames = ChartDifficulty.standardLabels;
    final diffName = isUtage
        ? ChartDifficulty.utageLabel
        : diffNames[levelIndex.clamp(0, 4)];

    final String rateKey = _resolveRateKey(rawRate, achievements);
    final String rateDisplay = rawRate.trim().isNotEmpty
        ? StringUtil.formatRate(rawRate)
        : rateKey.replaceAll('p', '+').toUpperCase();

    final String achStr = achievements.toStringAsFixed(4);
    final int dotIdx = achStr.indexOf('.');
    final String achInt = dotIdx >= 0 ? achStr.substring(0, dotIdx) : achStr;
    final String achFrac = dotIdx >= 0 ? '${achStr.substring(dotIdx)}%' : '%';

    final _BadgeColors? fcBadge = _getBadgeColors(fc, isLight: c.isLight);
    final _BadgeColors? fsBadge = _getBadgeColors(fs, isLight: c.isLight);

    final double scoreRate =
        maxDxScore > 0 ? (dxScore / maxDxScore).clamp(0.0, 1.0) : 0.0;
    final String dxScorePercent = maxDxScore > 0
        ? (dxScore / maxDxScore * 100).toStringAsFixed(2)
        : '0.00';
    final int starTargetMin = _starMinScore(scoreRate, maxDxScore);
    final int starDiff = dxScore - starTargetMin;
    final String starDiffText =
        '${starDiff >= 0 ? '+' : ''}$starDiff';
    final _StarVisual starVisual = _starVisual(scoreRate, c);

    final bool hasUser = userNickname.isNotEmpty || totalRating > 0;
    final String trimmedGenre = genre.trim();
    final String trimmedCharter = charter?.trim() ?? '';
    final String bpmDisplay =
        (bpmText != null && bpmText.trim().isNotEmpty) ? bpmText.trim() : '$bpm';
    final List<String> metaParts = [
      if (trimmedGenre.isNotEmpty) trimmedGenre,
      'BPM $bpmDisplay',
      if (trimmedCharter.isNotEmpty && trimmedCharter != '-') trimmedCharter,
    ];

    Widget heroTag(String text, {Color? bg, Color? fg}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: bg ?? Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 21,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: fg ?? Colors.white,
            ),
          ),
        );

    Widget heroRing(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        );

    return ExportPage(
      theme: theme,
      width: 1200,
      padding: const EdgeInsets.all(28),
      child: Container(
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: c.cardBorder, width: 1.5),
          boxShadow: c.isLight
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 区块 1：曲绘氛围头图
              Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [heroDeep, heroLight],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      child: Transform.scale(
                        scale: 1.18,
                        child: ImageFiltered(
                          imageFilter:
                              ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                          child: Opacity(
                            opacity: 0.45,
                            child: SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: 320,
                                  height: 320,
                                  child: CoverUtil.buildCoverWidgetWithContext(
                                      context, songId, 320),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 双层渐变暗遮罩，保障白字在任意亮色曲绘下均有高对比度。
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withValues(alpha: 0.46),
                            Colors.black.withValues(alpha: 0.62),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.14),
                            Colors.black.withValues(alpha: 0.48),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(right: -110, top: -150, child: heroRing(460)),
                  Positioned(left: -90, bottom: -160, child: heroRing(340)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(44, 44, 44, 40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 256,
                          height: 256,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.38),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.72),
                                width: 4,
                              ),
                            ),
                            child: CoverUtil.buildCoverWidgetWithContext(
                                context, songId, 256),
                          ),
                        ),
                        const SizedBox(width: 36),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  heroTag(typeText, bg: typeBg),
                                  heroTag(
                                    '$diffName $levelStr',
                                    bg: accentColor,
                                    fg: isReMaster
                                        ? const Color(0xFF3B1D5E)
                                        : Colors.white,
                                  ),
                                  heroTag(context.l10n.flowConstantP0(
                                      ds.toStringAsFixed(1))),
                                  Text(
                                    '#$songId',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color:
                                          Colors.white.withValues(alpha: 0.82),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                songTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 48,
                                  height: 1.16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.45),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              if (artist.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Text(
                                metaParts.join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.78),
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 区块 2：核心成绩舞台 + DX 分数进度条
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 主角成绩卡
                    Container(
                      padding: const EdgeInsets.fromLTRB(32, 26, 32, 26),
                      decoration: BoxDecoration(
                        color: c.inset,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        context.l10n.flowSongAchievement,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: c.muted,
                                        ),
                                      ),
                                      const Spacer(),
                                      _buildRankVisual(
                                          rateKey, rateDisplay, c.brightness),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: achInt,
                                            style: TextStyle(
                                              fontSize: 92,
                                              height: 1.05,
                                              fontWeight: FontWeight.w900,
                                              color: c.ink,
                                              letterSpacing: -1,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures()
                                              ],
                                            ),
                                          ),
                                          TextSpan(
                                            text: achFrac,
                                            style: TextStyle(
                                              fontSize: 64,
                                              height: 1.05,
                                              fontWeight: FontWeight.w800,
                                              color: c.ink,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures()
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (fcBadge != null ||
                                      fsBadge != null ||
                                      achievements >= 80.0) ...[
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 10,
                                      children: [
                                        if (fcBadge != null)
                                          _buildAchievementPill(fcBadge),
                                        if (fsBadge != null)
                                          _buildAchievementPill(fsBadge),
                                        if (fcBadge == null &&
                                            fsBadge == null &&
                                            achievements >= 80.0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 18, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: c.track,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'CLEAR',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                color: c.muted,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            // 单曲 Rating 焦点卡
                            Container(
                              width: 248,
                              padding:
                                  const EdgeInsets.fromLTRB(22, 22, 22, 22),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(
                                    alpha: c.isLight ? 0.12 : 0.22),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: accentColor.withValues(
                                      alpha: c.isLight ? 0.36 : 0.45),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'RATING',
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.4,
                                      color: c.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$ra',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 66,
                                        height: 1.08,
                                        fontWeight: FontWeight.w900,
                                        color: ratingInk,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$diffName $levelStr · ${ds.toStringAsFixed(1)}',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w600,
                                        color: c.muted,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures()
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // DX 分数与星级卡片
                    Container(
                      padding: const EdgeInsets.fromLTRB(30, 22, 30, 22),
                      decoration: BoxDecoration(
                        color: c.inset,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        context.l10n.flowDXScore2,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: c.muted,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        '$dxScore / $maxDxScore',
                                        style: TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w800,
                                          color: c.ink,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                      if (maxDxScore > 0) ...[
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: c.track,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            dxScore > maxDxScore
                                                ? 'MAX +${dxScore - maxDxScore}'
                                                : 'MAX -${maxDxScore - dxScore}',
                                            style: TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              color: c.ink,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures()
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(width: 12),
                                      Text(
                                        '$dxScorePercent%',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: c.muted,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures()
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildStarSummary(
                                starVisual: starVisual,
                                diffText: starDiffText,
                                c: c,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildDxScoreProgressBar(
                            scoreRate: scoreRate,
                            fillColor: starVisual.barColor,
                            c: c,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 区块 3：底部玩家名片与落款条
              Padding(
                padding: const EdgeInsets.fromLTRB(36, 0, 36, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(height: 1.5, color: c.track),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: hasUser
                              ? Row(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color: c.inset,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                            color: c.track, width: 1.5),
                                      ),
                                      child: (avatarUrl != null &&
                                              avatarUrl.isNotEmpty)
                                          ? LxnsAssetImage(
                                              url: avatarUrl,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              placeholder: Icon(
                                                Icons.person_rounded,
                                                size: 34,
                                                color: c.muted,
                                              ),
                                              errorWidget: Icon(
                                                Icons.person_rounded,
                                                size: 34,
                                                color: c.muted,
                                              ),
                                            )
                                          : Icon(
                                              Icons.person_rounded,
                                              size: 34,
                                              color: c.muted,
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (userNickname.isNotEmpty)
                                                Flexible(
                                                  child: Text(
                                                    userNickname,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 28,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: c.ink,
                                                    ),
                                                  ),
                                                ),
                                              if (userNickname.isNotEmpty &&
                                                  totalRating > 0)
                                                const SizedBox(width: 12),
                                              if (totalRating > 0)
                                                ColorUtil.buildRatingBadge(
                                                  totalRating,
                                                  height: 34,
                                                ),
                                            ],
                                          ),
                                          if (dataSource.isNotEmpty ||
                                              exportTime.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (dataSource.isNotEmpty)
                                                  dataSource,
                                                if (exportTime.isNotEmpty)
                                                  exportTime,
                                              ].join(' · '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w500,
                                                color: c.muted,
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures()
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  exportTime,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w500,
                                    color: c.muted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                        ),
                        const SizedBox(width: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'ChiffonMai',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: c.accent,
                              ),
                            ),
                            Text(
                              'Generated by ChiffonMai',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据 rawRate 或达成率解析官方评级资源键名。
  static String _resolveRateKey(String rawRate, double achievements) {
    final normalized = rawRate.trim().toLowerCase().replaceAll('+', 'p');
    const validKeys = {
      'sssp',
      'sss',
      'ssp',
      'ss',
      'sp',
      's',
      'aaa',
      'aa',
      'a',
      'bbb',
      'bb',
      'b',
      'c',
      'd',
    };
    if (validKeys.contains(normalized)) return normalized;
    if (achievements >= 100.5) return 'sssp';
    if (achievements >= 100.0) return 'sss';
    if (achievements >= 99.5) return 'ssp';
    if (achievements >= 99.0) return 'ss';
    if (achievements >= 98.0) return 'sp';
    if (achievements >= 97.0) return 's';
    if (achievements >= 94.0) return 'aaa';
    if (achievements >= 90.0) return 'aa';
    if (achievements >= 80.0) return 'a';
    if (achievements >= 75.0) return 'bbb';
    if (achievements >= 70.0) return 'bb';
    if (achievements >= 60.0) return 'b';
    if (achievements >= 50.0) return 'c';
    return 'd';
  }

  /// 官方评级图，离线或缺失时自动回退高对比度文本胶囊。
  static Widget _buildRankVisual(
      String rateKey, String rateDisplay, Brightness brightness) {
    final fallbackColors = AppColors.rankBadge(rateDisplay, brightness);
    return Image.asset(
      'assets/gamrank/$rateKey.png',
      height: 48,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: fallbackColors.background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          rateDisplay,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: fallbackColors.foreground,
          ),
        ),
      ),
    );
  }

  /// 连击 / 同步徽章胶囊（官方小图标 + 统一配色文字）。
  static Widget _buildAchievementPill(_BadgeColors badge) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
      decoration: BoxDecoration(
        color: badge.bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: badge.fg.withValues(alpha: 0.24), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/grade/${badge.assetKey}.png',
            width: 34,
            height: 34,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Text(
            badge.label,
            style: TextStyle(
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: badge.fg,
            ),
          ),
        ],
      ),
    );
  }

  /// 右侧星级摘要：整数 1–5 星直接显示星图 + 差值，避免重复写等级；
  /// 半星 / 6 星 / 0 星使用矢量星标图标，避免部分系统字体缺少 `✦` 字符变成方框。
  static Widget _buildStarSummary({
    required _StarVisual starVisual,
    required String diffText,
    required ExportPalette c,
  }) {
    final int? intStar = starVisual.intStar;
    Widget starPill({
      required String numberText,
      required Color bg,
      required Color fg,
      double fontSize = 22,
    }) =>
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: fontSize + 2, color: fg),
              const SizedBox(width: 4),
              Text(
                numberText,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (intStar != null) ...[
          Image.asset(
            'assets/dxstars/$intStar.png',
            height: 36,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => starPill(
              numberText: starVisual.shortValue,
              bg: starVisual.pillBg,
              fg: starVisual.pillFg,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            diffText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: starVisual.diffColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ] else if (starVisual.stars == 0) ...[
          starPill(
            numberText: '0',
            bg: c.track,
            fg: c.muted,
            fontSize: 21,
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '距 ',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: c.muted,
                ),
              ),
              Icon(Icons.star_rounded, size: 22, color: c.muted),
              Text(
                '1 $diffText',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: c.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ] else ...[
          starPill(
            numberText: starVisual.shortValue,
            bg: starVisual.pillBg,
            fg: starVisual.pillFg,
          ),
          const SizedBox(width: 8),
          Text(
            diffText,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: starVisual.diffColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }

  /// DX 分数进度条：按星级阈值画精细刻度。
  static Widget _buildDxScoreProgressBar({
    required double scoreRate,
    required Color fillColor,
    required ExportPalette c,
  }) {
    const thresholds = [0.85, 0.90, 0.93, 0.95, 0.97];
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: SizedBox(
        height: 14,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalW = constraints.maxWidth;
            final fillW = (totalW * scoreRate.clamp(0.0, 1.0)).clamp(0.0, totalW);
            return Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: c.track)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: fillW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ),
                for (final t in thresholds)
                  Positioned(
                    left: (totalW * t) - 1,
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: ColoredBox(color: c.panel.withValues(alpha: 0.72)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  static int _starMinScore(double scoreRate, int maxScore) {
    if (maxScore <= 0) return 0;
    final double minRate;
    if (scoreRate >= 0.99) {
      minRate = 0.99;
    } else if (scoreRate >= 0.98) {
      minRate = 0.98;
    } else if (scoreRate >= 0.97) {
      minRate = 0.97;
    } else if (scoreRate >= 0.95) {
      minRate = 0.95;
    } else if (scoreRate >= 0.93) {
      minRate = 0.93;
    } else if (scoreRate >= 0.90) {
      minRate = 0.90;
    } else {
      minRate = 0.85;
    }
    return (maxScore * minRate).ceil();
  }

  static _StarVisual _starVisual(double scoreRate, ExportPalette c) {
    final double stars;
    final String shortValue;
    int? intStar;
    if (scoreRate >= 0.99) {
      stars = 6;
      shortValue = '6';
    } else if (scoreRate >= 0.98) {
      stars = 5.5;
      shortValue = '5.5';
    } else if (scoreRate >= 0.97) {
      stars = 5;
      intStar = 5;
      shortValue = '5';
    } else if (scoreRate >= 0.95) {
      stars = 4;
      intStar = 4;
      shortValue = '4';
    } else if (scoreRate >= 0.93) {
      stars = 3;
      intStar = 3;
      shortValue = '3';
    } else if (scoreRate >= 0.90) {
      stars = 2;
      intStar = 2;
      shortValue = '2';
    } else if (scoreRate >= 0.85) {
      stars = 1;
      intStar = 1;
      shortValue = '1';
    } else {
      stars = 0;
      shortValue = '0';
    }

    if (stars >= 5) {
      return _StarVisual(
        stars: stars,
        intStar: intStar,
        shortValue: shortValue,
        pillBg: const Color(0xFFF5C542),
        pillFg: const Color(0xFF2B2100),
        diffColor: c.isLight ? const Color(0xFF9C6500) : const Color(0xFFF5C542),
        barColor: const Color(0xFFE8B400),
      );
    }
    if (stars >= 3) {
      return _StarVisual(
        stars: stars,
        intStar: intStar,
        shortValue: shortValue,
        pillBg: const Color(0xFFE8852A),
        pillFg: Colors.white,
        diffColor: c.isLight ? const Color(0xFFB35400) : const Color(0xFFFFB26B),
        barColor: const Color(0xFFE8852A),
      );
    }
    if (stars >= 1) {
      return _StarVisual(
        stars: stars,
        intStar: intStar,
        shortValue: shortValue,
        pillBg: const Color(0xFF2E9E5B),
        pillFg: Colors.white,
        diffColor: c.isLight ? const Color(0xFF1E7A44) : const Color(0xFF7BE0A0),
        barColor: const Color(0xFF2E9E5B),
      );
    }
    return _StarVisual(
      stars: 0,
      intStar: null,
      shortValue: '0',
      pillBg: c.track,
      pillFg: c.muted,
      diffColor: c.muted,
      barColor: c.accent,
    );
  }

  /// 获取连击 / 同步徽章颜色（SYNC 采用机台冰青底 + 深青蓝字配色）。
  static _BadgeColors? _getBadgeColors(String text, {required bool isLight}) {
    switch (text.trim().toLowerCase()) {
      case 'app':
      case 'ap+':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFFFF3E0) : const Color(0xFF473010),
          fg: isLight ? const Color(0xFFD96B00) : const Color(0xFFFFC978),
          label: 'AP+',
          assetKey: 'app',
        );
      case 'ap':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFFFF3E0) : const Color(0xFF473010),
          fg: isLight ? const Color(0xFFD96B00) : const Color(0xFFFFC978),
          label: 'AP',
          assetKey: 'ap',
        );
      case 'fcp':
      case 'fc+':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFD4F4DD) : const Color(0xFF193C26),
          fg: isLight ? const Color(0xFF2E7D32) : const Color(0xFF8CE2A6),
          label: 'FC+',
          assetKey: 'fcp',
        );
      case 'fc':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFD4F4DD) : const Color(0xFF193C26),
          fg: isLight ? const Color(0xFF2E7D32) : const Color(0xFF8CE2A6),
          label: 'FC',
          assetKey: 'fc',
        );
      case 'fsp':
      case 'fs+':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFE0F4FF) : const Color(0xFF1A3557),
          fg: isLight ? const Color(0xFF1565C0) : const Color(0xFF8CC5FF),
          label: 'FS+',
          assetKey: 'fsp',
        );
      case 'fs':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFE0F4FF) : const Color(0xFF1A3557),
          fg: isLight ? const Color(0xFF1565C0) : const Color(0xFF8CC5FF),
          label: 'FS',
          assetKey: 'fs',
        );
      case 'sync':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFDFF7F5) : const Color(0xFF143A42),
          fg: isLight ? const Color(0xFF0A5C6E) : const Color(0xFF7CEBF0),
          label: 'SYNC',
          assetKey: 'sync',
        );
      case 'fsd':
      case 'fdx':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFFFF3E0) : const Color(0xFF473010),
          fg: isLight ? const Color(0xFFD96B00) : const Color(0xFFFFC978),
          label: 'FDX',
          assetKey: 'fsd',
        );
      case 'fsdp':
      case 'fdx+':
        return _BadgeColors(
          bg: isLight ? const Color(0xFFFFF3E0) : const Color(0xFF473010),
          fg: isLight ? const Color(0xFFD96B00) : const Color(0xFFFFC978),
          label: 'FDX+',
          assetKey: 'fsdp',
        );
      default:
        return null;
    }
  }

  // --- 颜色辅助（与 SongInfoPage 一致）---

  // --- 权限和保存逻辑（复用现有模式）---

  static Future<PermissionStatus> _requestStoragePermission() async {
    if (Platform.isIOS) return PermissionStatus.denied; // 先保存到应用文档。

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
}

/// 星级呈现样式数据。
class _StarVisual {
  final double stars;
  final int? intStar;
  final String shortValue;
  final Color pillBg;
  final Color pillFg;
  final Color diffColor;
  final Color barColor;

  const _StarVisual({
    required this.stars,
    required this.intStar,
    required this.shortValue,
    required this.pillBg,
    required this.pillFg,
    required this.diffColor,
    required this.barColor,
  });
}
