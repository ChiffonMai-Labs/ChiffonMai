import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/DivingFish/Song.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/PosterExportUtil.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/ExportStatsUi.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import 'RankCompletionStore.dart';
import 'RankTableService.dart';

/// 单首段位课题曲的导出快照。
class RankCourseSongExportItem {
  final int index;
  final String songId;
  final String title;
  final String songType;
  final int levelIndex;
  final double? achievement;
  final int? minDamage;

  const RankCourseSongExportItem({
    required this.index,
    required this.songId,
    required this.title,
    required this.songType,
    required this.levelIndex,
    this.achievement,
    this.minDamage,
  });

  factory RankCourseSongExportItem.fromData({
    required int index,
    required String songId,
    required int levelIndex,
    Song? song,
    required String achievementText,
    int? minDamage,
  }) {
    final parsed = double.tryParse(achievementText.replaceAll('%', ''));
    return RankCourseSongExportItem(
      index: index,
      songId: songId,
      title: song?.title ?? 'Track ${index + 1}',
      songType: song?.type ?? '',
      levelIndex: levelIndex,
      achievement: parsed,
      minDamage: minDamage,
    );
  }
}

/// 段位认定总览 & 单个段位详情海报导出服务。
class RankTableExportService {
  RankTableExportService._();

  static const double _width = 1080;

  static Future<File?> convertOverviewToImage(
    BuildContext context, {
    required List<(String label, List<String> ranks)> groups,
    required Map<String, RankCompletion> completions,
    required Map<String, RankData?> rankDataMap,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_ranks_overview',
        subDir: '段位进度',
        songIds: [
          for (final data in rankDataMap.values)
            if (data != null) ...data.songIds,
        ],
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'RankOverviewExport',
        builder: (overlayContext) => buildOverviewExportWidget(
          overlayContext,
          groups: groups,
          completions: completions,
          rankDataMap: rankDataMap,
          theme: theme,
          background: background,
        ),
      );

  static Future<File?> convertDetailToImage(
    BuildContext context, {
    required RankData rankData,
    required RankCompletion completion,
    required List<RankCourseSongExportItem> songs,
    double? totalAchievement,
    int? remainingHp,
    bool? isDead,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_rank_${rankData.name}',
        subDir: '段位进度',
        songIds: rankData.songIds,
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'RankDetailExport',
        builder: (overlayContext) => buildDetailExportWidget(
          overlayContext,
          rankData: rankData,
          completion: completion,
          songs: songs,
          totalAchievement: totalAchievement,
          remainingHp: remainingHp,
          isDead: isDead,
          theme: theme,
          background: background,
        ),
      );

  static bool _isCleared(RankCompletion? status) =>
      status == RankCompletion.passed || status == RankCompletion.redPassed;

  static String _completionLabel(BuildContext context, RankCompletion status) {
    final l10n = context.l10n;
    return switch (status) {
      RankCompletion.passed => l10n.flowPassed,
      RankCompletion.redPassed => '赤合格',
      RankCompletion.failed => l10n.flowFailed2,
      RankCompletion.unplayed => l10n.flowUnplayed,
    };
  }

  static Color _completionColor(ExportPalette c, RankCompletion status) =>
      switch (status) {
        RankCompletion.passed => c.positive,
        RankCompletion.redPassed => const Color(0xFFD97706),
        RankCompletion.failed => c.negative,
        RankCompletion.unplayed => c.muted,
      };

  static Widget buildOverviewExportWidget(
    BuildContext context, {
    required List<(String label, List<String> ranks)> groups,
    required Map<String, RankCompletion> completions,
    required Map<String, RankData?> rankDataMap,
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
          final allRanks = [for (final (_, r) in groups) ...r];
          final cleared =
              allRanks.where((r) => _isCleared(completions[r])).length;
          final passed = allRanks
              .where((r) => completions[r] == RankCompletion.passed)
              .length;
          final red = allRanks
              .where((r) => completions[r] == RankCompletion.redPassed)
              .length;
          final failed = allRanks
              .where((r) => completions[r] == RankCompletion.failed)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportPosterHeader(
                title: l10n.featureRankTable,
                caption: l10n.flowDanCertification,
                scale: 0.65,
              ),
              const SizedBox(height: 28),
              ExportStatsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ExportHeroBlock(
                            centered: true,
                            label: l10n.flowDanCertification,
                            value: '$cleared / ${allRanks.length}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ExportStatBlock(
                            centered: true,
                            label: l10n.flowPassed,
                            value: '$passed',
                            positive: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ExportStatBlock(
                            centered: true,
                            label: '赤合格',
                            value: '$red',
                            valueColor: const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ExportStatBlock(
                            centered: true,
                            label: l10n.flowFailed2,
                            value: '$failed',
                            positive: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SmoothLinearProgressIndicator(
                      value: allRanks.isEmpty ? 0 : cleared / allRanks.length,
                      minHeight: 10,
                      color: c.accent,
                      backgroundColor: c.track,
                    ),
                  ],
                ),
              ),
              for (final (groupLabel, ranks) in groups) ...[
                const SizedBox(height: 24),
                ExportSectionTitle(
                    '$groupLabel · ${ranks.where((r) => _isCleared(completions[r])).length}/${ranks.length}'),
                const SizedBox(height: 12),
                _rankGrid(context, ranks, completions, rankDataMap),
              ],
            ],
          );
        },
      ),
    );
  }

  static Widget _rankGrid(
    BuildContext context,
    List<String> ranks,
    Map<String, RankCompletion> completions,
    Map<String, RankData?> rankDataMap,
  ) {
    final c = ExportPalette.of(context);
    final rows = <List<String>>[];
    for (var i = 0; i < ranks.length; i += 3) {
      rows.add(ranks.sublist(i, (i + 3).clamp(0, ranks.length)));
    }
    return Column(
      children: [
        for (final (rIndex, row) in rows.indexed) ...[
          if (rIndex > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: i < row.length
                      ? _rankTile(
                          context,
                          row[i],
                          completions[row[i]] ?? RankCompletion.unplayed,
                          rankDataMap[row[i]],
                          c,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  static Widget _rankTile(
    BuildContext context,
    String rank,
    RankCompletion status,
    RankData? data,
    ExportPalette c,
  ) {
    final statusColor = _completionColor(c, status);
    final isUnplayed = status == RankCompletion.unplayed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnplayed
            ? c.panel
            : Color.alphaBlend(statusColor.withValues(alpha: 0.12), c.panel),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnplayed ? c.cardBorder : statusColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rank,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _completionLabel(context, status),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (data != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppColors.difficultyForegroundByIndex(
                              data.levelIndexes[i],
                              brightness: c.brightness),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CoverUtil.buildCoverWidgetWithContext(
                            context,
                            data.songIds[i],
                            64,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget buildDetailExportWidget(
    BuildContext context, {
    required RankData rankData,
    required RankCompletion completion,
    required List<RankCourseSongExportItem> songs,
    double? totalAchievement,
    int? remainingHp,
    bool? isDead,
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
          final statusColor = _completionColor(c, completion);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportPosterHeader(
                title: rankData.name,
                caption: l10n.flowDanCertification,
                scale: 0.65,
              ),
              const SizedBox(height: 28),
              ExportStatsPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ExportHeroBlock(
                            centered: true,
                            label: rankData.name,
                            value: _completionLabel(context, completion),
                            caption: 'HP ${rankData.initialHp}',
                          ),
                        ),
                        if (totalAchievement != null && remainingHp != null) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: ExportStatBlock(
                              centered: true,
                              label: l10n.flowTotalAchievement,
                              value: '${totalAchievement.toStringAsFixed(4)}%',
                              positive: totalAchievement >= 400,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ExportStatBlock(
                              centered: true,
                              label: l10n.flowRemainingLife,
                              value: '$remainingHp / ${rankData.initialHp}',
                              positive: !(isDead ?? false) && remainingHp > 0,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: ExportStatBlock(
                              centered: true,
                              label: l10n.flowMyChallenges,
                              value: _completionLabel(context, completion),
                              valueColor: statusColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (remainingHp != null && rankData.initialHp > 0) ...[
                      const SizedBox(height: 14),
                      SmoothLinearProgressIndicator(
                        value: (remainingHp / rankData.initialHp)
                            .clamp(0.0, 1.0)
                            .toDouble(),
                        minHeight: 10,
                        color: (isDead ?? false) ? c.negative : c.positive,
                        backgroundColor: c.track,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ExportSectionTitle(l10n.flowDanCourseSongs),
              const SizedBox(height: 12),
              ExportStatsPanel(
                child: Column(
                  children: [
                    for (final (i, song) in songs.indexed) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: c.cardBorder),
                        ),
                      _courseSongRow(context, song, c),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ExportSectionTitle(l10n.flowLifeSettings),
              const SizedBox(height: 12),
              ExportStatsPanel(
                child: Row(
                  children: [
                    Expanded(
                      child: ExportStatBlock(
                        centered: true,
                        label: l10n.flowStartingLife,
                        value: '${rankData.initialHp}',
                        positive: true,
                        valueSize: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ExportStatBlock(
                        centered: true,
                        label: 'GREAT',
                        value: '-${rankData.greatDamage}',
                        valueColor: const Color(0xFFD97706),
                        valueSize: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ExportStatBlock(
                        centered: true,
                        label: 'GOOD',
                        value: '-${rankData.goodDamage}',
                        positive: false,
                        valueSize: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ExportStatBlock(
                        centered: true,
                        label: 'MISS',
                        value: '-${rankData.missDamage}',
                        positive: false,
                        valueSize: 30,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ExportStatBlock(
                        centered: true,
                        label: l10n.flowClearRecovery,
                        value: '+${rankData.healAmount}',
                        positive: true,
                        valueSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static Widget _courseSongRow(
      BuildContext context, RankCourseSongExportItem song, ExportPalette c) {
    final l10n = context.l10n;
    final diffColor = AppColors.difficultyForegroundByIndex(song.levelIndex,
        brightness: c.brightness);
    return Row(
      children: [
        SizedBox(
          width: 68,
          height: 68,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverUtil.buildCoverWidgetWithContext(
                    context, song.songId.isNotEmpty ? song.songId : '0', 68),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: diffColor, width: 2.5),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: diffColor,
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      '${song.index + 1}',
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
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
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (song.songType.isNotEmpty)
                    SongTypeBadge(songId: song.songId, type: song.songType),
                  ChartDifficultyBadge(
                    levelIndex: song.levelIndex,
                    songId: song.songId,
                    fontSize: 12,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                song.achievement != null
                    ? '${song.achievement!.toStringAsFixed(4)}%'
                    : l10n.flowUnplayed,
                style: song.achievement != null
                    ? AppTheme.number(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: song.achievement! >= 100 ? c.positive : c.ink,
                      )
                    : TextStyle(fontSize: 17, color: c.muted),
              ),
            ],
          ),
        ),
        if (song.minDamage != null) ...[
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${song.minDamage}',
                style: AppTheme.number(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: song.minDamage! > 0 ? c.negative : c.muted,
                ),
              ),
              Text(
                l10n.flowEstimatedMinimumLifeLoss,
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
