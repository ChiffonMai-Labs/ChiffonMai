import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/DivingFish/Song.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/ColorUtil.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/PosterExportUtil.dart';
import '../../utils/StringUtil.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/ExportStatsUi.dart';
import '../GainRecommend/GainRecommendCore.dart';
import '../GainRecommend/GainRecommendService.dart';

/// 吃分推荐 & 每日推荐图片导出服务。
class RecommendExportService {
  RecommendExportService._();

  static const double _width = 1080;

  static Future<File?> convertGainToImage(
    BuildContext context, {
    required GainRecommendSnapshot snapshot,
    required GainPage page,
    required int batch,
    required String routeLabel,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_gain_recommend_b$batch',
        subDir: '吃分推荐',
        songIds: page.items.map((c) => '${c.songId}'),
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'GainRecommendExport',
        builder: (overlayContext) => buildGainExportWidget(
          overlayContext,
          snapshot: snapshot,
          page: page,
          batch: batch,
          routeLabel: routeLabel,
          theme: theme,
          background: background,
        ),
      );

  static Future<File?> convertDailyToImage(
    BuildContext context, {
    required List<Song> songs,
    required String dateLabel,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_daily_recommend',
        subDir: '每日推荐',
        songIds: songs.map((s) => s.id),
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'DailyRecommendExport',
        builder: (overlayContext) => buildDailyExportWidget(
          overlayContext,
          songs: songs,
          dateLabel: dateLabel,
          theme: theme,
          background: background,
        ),
      );

  static String _routeText(BuildContext context, GainRoute route) =>
      switch (route) {
        GainRoute.stable => context.l10n.gainRouteStable,
        GainRoute.challenge => context.l10n.gainRouteChallenge,
        GainRoute.explore => context.l10n.gainRouteExplore,
      };

  static Color _routeColor(GainRoute route, ExportPalette c) => switch (route) {
        GainRoute.stable => c.positive,
        GainRoute.challenge => const Color(0xFFD97706),
        GainRoute.explore => c.accent,
      };

  static String _reasonText(BuildContext context, GainCandidate c) {
    final l10n = context.l10n;
    final basis = c.basis;
    if (basis == null) {
      return l10n.gainExploreReason(
          c.target.toStringAsFixed(4), c.netGain.toString());
    }
    final grade = basis.targetGrade ?? l10n.gainBelowS;
    final gradeText = basis.raisesGrade
        ? l10n.gainRaiseTo(grade)
        : l10n.gainWithinGrade(grade);
    final String basisText;
    if (basis.memberRa != null) {
      basisText = l10n.gainBasisMember(gradeText, basis.zone,
          basis.memberRa.toString(), basis.targetRa.toString());
    } else if (basis.floorTitle != null) {
      basisText = l10n.gainBasisReplace(gradeText, basis.targetRa.toString(),
          basis.zone, basis.floorTitle!, basis.floorRa.toString());
    } else {
      basisText =
          l10n.gainBasisFill(gradeText, basis.targetRa.toString(), basis.zone);
    }
    final text = l10n.gainNetGainReason(c.netGain.toString(), basisText);
    final alt = c.alternativeTarget;
    if (alt == null) return text;
    return text +
        l10n.gainAlternativeChallenge(
            alt.toStringAsFixed(4), c.alternativeGain.toString());
  }

  static Widget buildGainExportWidget(
    BuildContext context, {
    required GainRecommendSnapshot snapshot,
    required GainPage page,
    required int batch,
    required String routeLabel,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
  }) {
    return ExportPage(
      theme: theme,
      background: background,
      width: _width,
      padding: const EdgeInsets.all(36),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final c = ExportPalette.of(context);
          final baseline = snapshot.result.baseline;
          final b35Sum = baseline.b35.fold<int>(0, (s, r) => s + r.ra);
          final b15Sum = baseline.b15.fold<int>(0, (s, r) => s + r.ra);
          final combined =
              combinedGainOfPage(snapshot.result.records, page.items);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportPosterHeader(
                title: l10n.featureRatingGainRecommendations,
                caption: 'Batch #$batch · $routeLabel',
                scale: 0.65,
              ),
              const SizedBox(height: 28),
              ExportStatsPanel(
                child: ExportUniformStatRow(
                  children: [
                    ExportHeroBlock.compact(
                      label: l10n.flowCurrentB50,
                      value: '${baseline.raSum}',
                      caption: routeLabel,
                    ),
                    ExportStatBlock.compact(
                      label: 'Best 35',
                      value: '$b35Sum',
                      caption: '底线 ${baseline.floor(false)}',
                    ),
                    ExportStatBlock.compact(
                      label: 'Best 15',
                      value: '$b15Sum',
                      caption: '底线 ${baseline.floor(true)}',
                    ),
                    if (combined != null && combined > 0)
                      ExportStatBlock.compact(
                        label: l10n.flowNetGain,
                        value: '+$combined',
                        caption: '本批 ${page.items.length} 曲',
                        positive: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ExportSectionTitle(
                  '$routeLabel · ${page.items.length}'),
              const SizedBox(height: 12),
              if (page.items.isEmpty)
                ExportStatsPanel(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(l10n.flowNoData,
                          style: TextStyle(fontSize: 20, color: c.muted)),
                    ),
                  ),
                )
              else
                ExportStatsPanel(
                  child: Column(
                    children: [
                      for (final (idx, item) in page.items.indexed) ...[
                        if (idx > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1, color: c.cardBorder),
                          ),
                        _candidateRow(context, item, c),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static Widget _candidateRow(
      BuildContext context, GainCandidate item, ExportPalette c) {
    final l10n = context.l10n;
    final routeColor = _routeColor(item.route, c);
    final achv = item.achievements;
    final songId = '${item.songId}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CoverUtil.buildCoverWidgetWithContext(context, songId, 60),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: routeColor.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusPill),
                    ),
                    child: Text(
                      _routeText(context, item.route),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: routeColor,
                      ),
                    ),
                  ),
                  SongTypeBadge(songId: songId, type: item.type),
                  ChartDifficultyBadge(
                    levelIndex: item.levelIndex,
                    songId: songId,
                    label:
                        '${ChartDifficulty.labelOf(item.levelIndex, isUtage: songId.length == 6)} ${item.ds.toStringAsFixed(1)}',
                    fontSize: 12,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                achv == null
                    ? l10n.flowNoScoreRecordedReferenceTargetP0(
                        item.target.toStringAsFixed(4))
                    : l10n.flowP0P1GainP2(
                        achv.toStringAsFixed(4),
                        item.target.toStringAsFixed(4),
                        item.need.toStringAsFixed(4)),
                style: AppTheme.number(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _reasonText(context, item),
                style: TextStyle(fontSize: 15, color: c.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${item.netGain}',
              style: AppTheme.number(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: routeColor,
              ),
            ),
            Text(l10n.flowNetGain,
                style: TextStyle(fontSize: 14, color: c.muted)),
          ],
        ),
      ],
    );
  }

  static Widget buildDailyExportWidget(
    BuildContext context, {
    required List<Song> songs,
    required String dateLabel,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
  }) {
    return ExportPage(
      theme: theme,
      background: background,
      width: _width,
      padding: const EdgeInsets.all(36),
      child: Builder(
        builder: (context) {
          final l10n = context.l10n;
          final c = ExportPalette.of(context);
          final pairs = <List<Song>>[];
          for (var i = 0; i < songs.length; i += 2) {
            pairs.add(songs.sublist(i, (i + 2).clamp(0, songs.length)));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportPosterHeader(
                title: l10n.featureDailyRecommendations,
                caption: dateLabel,
                scale: 0.65,
              ),
              const SizedBox(height: 24),
              ExportStatsPanel(
                child: ExportUniformStatRow(
                  children: [
                    ExportHeroBlock.compact(
                      label: l10n.flowTodaySRecommendations,
                      value: dateLabel,
                      caption: '每日精选歌单',
                      valueSize: 25,
                    ),
                    ExportStatBlock.compact(
                      label: '推荐曲数',
                      value: l10n.flowP0Songs2('${songs.length}'),
                      caption: _dailyTypeSummary(songs),
                      valueSize: 26,
                    ),
                    ExportStatBlock.compact(
                      label: '最高定数区间',
                      value: _dailyPeakDsRange(songs),
                      caption: _dailyBpmRange(songs),
                      valueSize: 26,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ExportSectionTitle(
                '${l10n.flowTodaySRecommendations} | ${l10n.flowP0Songs2('${songs.length}')}',
              ),
              const SizedBox(height: 14),
              if (songs.isEmpty)
                ExportStatsPanel(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(l10n.flowNoData,
                          style: TextStyle(fontSize: 20, color: c.muted)),
                    ),
                  ),
                )
              else if (songs.length == 1)
                _dailySongCard(context, songs.first, 0, c)
              else
                for (final (rowIndex, pair) in pairs.indexed) ...[
                  if (rowIndex > 0) const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _dailySongCard(
                              context, pair[0], rowIndex * 2, c),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: pair.length > 1
                              ? _dailySongCard(
                                  context, pair[1], rowIndex * 2 + 1, c)
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }

  static String _dailyTypeSummary(List<Song> songs) {
    if (songs.isEmpty) return '-';
    var dx = 0;
    var sd = 0;
    var utage = 0;
    for (final s in songs) {
      if (ChartDifficulty.isUtageSong(s.id, type: s.type)) {
        utage++;
      } else if (s.type.toUpperCase() == 'DX') {
        dx++;
      } else {
        sd++;
      }
    }
    final parts = <String>[
      if (dx > 0) 'DX $dx',
      if (sd > 0) 'ST $sd',
      if (utage > 0) '宴 $utage',
    ];
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  static String _dailyPeakDsRange(List<Song> songs) {
    double? minPeak;
    double? maxPeak;
    for (final song in songs) {
      double? peak;
      for (final d in song.ds) {
        if (d > 0 && (peak == null || d > peak)) peak = d;
      }
      if (peak == null) continue;
      if (minPeak == null || peak < minPeak) minPeak = peak;
      if (maxPeak == null || peak > maxPeak) maxPeak = peak;
    }
    if (minPeak == null || maxPeak == null) return '-';
    if ((minPeak - maxPeak).abs() < 0.05) return maxPeak.toStringAsFixed(1);
    return '${minPeak.toStringAsFixed(1)} ~ ${maxPeak.toStringAsFixed(1)}';
  }

  static String _dailyBpmRange(List<Song> songs) {
    int? minBpm;
    int? maxBpm;
    for (final song in songs) {
      final bpm = song.basicInfo.bpm;
      if (bpm <= 0) continue;
      if (minBpm == null || bpm < minBpm) minBpm = bpm;
      if (maxBpm == null || bpm > maxBpm) maxBpm = bpm;
    }
    if (minBpm == null || maxBpm == null) return '随机推荐';
    if (minBpm == maxBpm) return 'BPM $minBpm';
    return 'BPM $minBpm–$maxBpm';
  }

  static String _shortDifficultyName(int index, {required bool isUtage}) {
    if (isUtage) return '宴';
    return switch (index) {
      0 => 'BAS',
      1 => 'ADV',
      2 => 'EXP',
      3 => 'MAS',
      4 => 'Re:M',
      _ => '宴',
    };
  }

  static Widget _dailySongCard(
      BuildContext context, Song song, int index, ExportPalette c) {
    final l10n = context.l10n;
    final isUtage = ChartDifficulty.isUtageSong(song.id, type: song.type);
    final title =
        song.basicInfo.title.isNotEmpty ? song.basicInfo.title : song.title;
    final artist = song.basicInfo.artist.isEmpty
        ? l10n.flowUnknownArtist
        : song.basicInfo.artist;
    final versionLabel = song.basicInfo.from.isNotEmpty
        ? StringUtil.formatVersion2WithFlag(song.basicInfo.from, song.isExtra)
        : '';
    final genreLabel = song.basicInfo.genre;
    final metaParts = <String>[
      if (versionLabel.isNotEmpty) versionLabel,
      if (genreLabel.isNotEmpty) genreLabel,
    ];
    final validDiffs = <int>[
      for (var i = 0; i < song.ds.length; i++)
        if (song.ds[i] > 0) i,
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 116,
                height: 116,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverUtil.buildCoverWidgetWithContext(
                          context, song.id, 116),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: c.cardBorder, width: 1.5),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.heroDeep.withValues(alpha: 0.88),
                            borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: AppTheme.number(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUtage
                                ? AppColors.utageAccent(
                                    brightness: c.brightness)
                                : song.type.toUpperCase() == 'DX'
                                    ? const Color(0xFF0B8F86)
                                    : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            isUtage
                                ? '宴'
                                : (song.type.toUpperCase() == 'DX'
                                    ? 'DX'
                                    : 'ST'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            song.basicInfo.bpm > 0
                                ? 'ID ${song.id} · BPM ${song.basicInfo.bpm}'
                                : 'ID ${song.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.number(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: c.muted,
                      ),
                    ),
                    if (metaParts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        metaParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: c.cardBorder),
          ),
          if (validDiffs.isEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.inset,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                song.level.isNotEmpty ? song.level.join(' / ') : '--',
                textAlign: TextAlign.center,
                style: AppTheme.number(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.muted,
                ),
              ),
            )
          else
            Row(
              children: [
                for (final (idx, diffIndex) in validDiffs.indexed) ...[
                  if (idx > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final bg = isUtage
                            ? AppColors.utageAccent(brightness: c.brightness)
                            : ColorUtil.getCardColor(diffIndex);
                        final fg =
                            ThemeData.estimateBrightnessForColor(bg) ==
                                    Brightness.dark
                                ? Colors.white
                                : const Color(0xFF1F1A10);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 8),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _shortDifficultyName(
                                  diffIndex,
                                  isUtage: isUtage,
                                ),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: fg.withValues(alpha: 0.88),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                song.ds[diffIndex].toStringAsFixed(1),
                                style: AppTheme.number(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: fg,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
