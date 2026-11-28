import 'dart:io';

import 'package:flutter/material.dart';

import '../../entity/Score/FriendComparisonResult.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/PosterExportUtil.dart';
import '../../utils/StringUtil.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/ExportStatsUi.dart';

/// 好友成绩对比图片导出服务：双方 Rating 对照、胜负比例条、合作 B50 及共同谱面明细。
class FriendCompareExportService {
  FriendCompareExportService._();

  static const double _width = 1080;
  static const int _maxCharts = 24;

  static Future<File?> convertToImage(
    BuildContext context, {
    required ComparisonResult result,
    required List<ChartComparisonItem> charts,
    required String myLabel,
    required String friendLabel,
    ExportImageTheme theme = ExportImageTheme.light,
    Best50ExportBackground background = Best50ExportBackground.none,
    int? jpegQuality,
  }) =>
      PosterExportUtil.captureAndSave(
        context,
        width: _width,
        filePrefix: 'chiffonmai_friend_compare',
        subDir: '好友对比',
        songIds: charts.take(_maxCharts).map((c) => '${c.songId}'),
        background: background,
        jpegQuality: jpegQuality,
        logTag: 'FriendCompareExport',
        builder: (overlayContext) => buildExportWidget(
          overlayContext,
          result: result,
          charts: charts,
          myLabel: myLabel,
          friendLabel: friendLabel,
          theme: theme,
          background: background,
        ),
      );

  static Widget buildExportWidget(
    BuildContext context, {
    required ComparisonResult result,
    required List<ChartComparisonItem> charts,
    required String myLabel,
    required String friendLabel,
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
          final shown = charts.take(_maxCharts).toList(growable: false);
          final omitted = charts.length - shown.length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExportPosterHeader(
                title: l10n.featureFriendComparison,
                caption: '$myLabel VS $friendLabel',
                scale: 0.65,
              ),
              const SizedBox(height: 28),
              _summaryPanel(context, result, myLabel: myLabel, friendLabel: friendLabel),
              const SizedBox(height: 24),
              ExportSectionTitle(
                  '${l10n.flowSharedCharts} · ${charts.length}'),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                ExportStatsPanel(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        l10n.flowNoMatchingCharts,
                        style: TextStyle(fontSize: 20, color: c.muted),
                      ),
                    ),
                  ),
                )
              else
                ExportStatsPanel(
                  child: Column(
                    children: [
                      for (final (index, item) in shown.indexed) ...[
                        if (index > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: c.cardBorder),
                          ),
                        _chartRow(context, item,
                            myLabel: myLabel, friendLabel: friendLabel),
                      ],
                      if (omitted > 0) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: c.cardBorder),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '... 共 ${charts.length} 首（已展示前 ${shown.length} 首）',
                            style: TextStyle(fontSize: 17, color: c.muted),
                          ),
                        ),
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

  static Widget _summaryPanel(
    BuildContext context,
    ComparisonResult result, {
    required String myLabel,
    required String friendLabel,
  }) {
    final l10n = context.l10n;
    final c = ExportPalette.of(context);
    final friendKnown = result.friendRating > 0;
    final diff = friendKnown ? result.myRating - result.friendRating : 0;
    final totalCompare = result.myWinCount + result.tieCount + result.friendWinCount;
    final tieColor = const Color(0xFFD97706);

    Widget playerBlock(String name, int rating, bool leading) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: c.inset,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: c.muted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rating > 0 ? '$rating' : '-',
                  style: AppTheme.number(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: leading ? c.accent : c.ink,
                  ),
                ),
              ],
            ),
          ),
        );

    return ExportStatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              playerBlock(myLabel, result.myRating, friendKnown && diff > 0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: AppTheme.number(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !friendKnown
                          ? l10n.flowPrivate
                          : diff == 0
                              ? l10n.flowSameScore
                              : '${diff > 0 ? '+' : ''}$diff',
                      style: AppTheme.number(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: !friendKnown || diff == 0
                            ? c.muted
                            : (diff > 0 ? c.positive : c.negative),
                      ),
                    ),
                  ],
                ),
              ),
              playerBlock(
                  friendLabel, result.friendRating, friendKnown && diff < 0),
            ],
          ),
          if (totalCompare > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (result.myWinCount > 0)
                      Expanded(
                        flex: result.myWinCount,
                        child: ColoredBox(color: c.positive),
                      ),
                    if (result.tieCount > 0)
                      Expanded(
                        flex: result.tieCount,
                        child: ColoredBox(color: tieColor),
                      ),
                    if (result.friendWinCount > 0)
                      Expanded(
                        flex: result.friendWinCount,
                        child: ColoredBox(color: c.negative),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ExportStatBlock(
                  centered: true,
                  label: l10n.flowMyWins,
                  value: '${result.myWinCount}',
                  positive: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExportStatBlock(
                  centered: true,
                  label: l10n.flowTie,
                  value: '${result.tieCount}',
                  valueColor: tieColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExportStatBlock(
                  centered: true,
                  label: l10n.flowFriendSWins,
                  value: '${result.friendWinCount}',
                  positive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ExportStatBlock(
                  centered: true,
                  label: l10n.flowMyCharts,
                  value: '${result.myTotalCharts}',
                  valueSize: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExportStatBlock(
                  centered: true,
                  label: l10n.flowFriendSCharts,
                  value: '${result.friendTotalCharts}',
                  valueSize: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ExportStatBlock(
                  centered: true,
                  label: l10n.flowSharedCharts,
                  value: '${result.commonCount}',
                  valueSize: 30,
                ),
              ),
              if (result.cooperativeBest50 case final joint?) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ExportStatBlock(
                    centered: true,
                    label: l10n.awmcCoopBest50,
                    value: '${joint.baseline.raSum}',
                    valueSize: 30,
                    valueColor: c.accent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static Widget _chartRow(
    BuildContext context,
    ChartComparisonItem item, {
    required String myLabel,
    required String friendLabel,
  }) {
    final l10n = context.l10n;
    final c = ExportPalette.of(context);
    final diff = item.myAchievements - item.friendAchievements;
    final diffColor = item.isTie
        ? const Color(0xFFD97706)
        : (item.isMyWin ? c.positive : c.negative);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CoverUtil.buildCoverWidgetWithContext(
              context, '${item.songId}', 52),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.songTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SongTypeBadge(songId: '${item.songId}', type: item.type),
                  ChartDifficultyBadge(
                    levelIndex: item.levelIndex,
                    songId: '${item.songId}',
                    label:
                        '${ChartDifficulty.labelOf(item.levelIndex, isUtage: '${item.songId}'.length == 6)} ${item.ds.toStringAsFixed(1)}',
                    fontSize: 12,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$myLabel ${item.myAchievements.toStringAsFixed(4)}%',
                  style: AppTheme.number(
                    fontSize: 17,
                    fontWeight: item.isMyWin || item.isTie
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: item.isMyWin || item.isTie ? c.ink : c.muted,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusPill),
                    ),
                    child: Text(
                      item.isTie
                          ? l10n.flowTie
                          : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(4)}%',
                      style: AppTheme.number(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: diffColor,
                      ),
                    ),
                  ),
                ),
                Text(
                  '$friendLabel ${item.friendAchievements.toStringAsFixed(4)}%',
                  style: AppTheme.number(
                    fontSize: 17,
                    fontWeight: item.isFriendWin || item.isTie
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: item.isFriendWin || item.isTie ? c.ink : c.muted,
                  ),
                ),
              ],
            ),
            if (item.myRate.isNotEmpty || item.friendRate.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                '${item.myRate.isEmpty ? '-' : StringUtil.formatRate(item.myRate)} vs ${item.friendRate.isEmpty ? '-' : StringUtil.formatRate(item.friendRate)}',
                style: AppTheme.number(fontSize: 13, color: c.muted),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
