import 'package:flutter/material.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../service/GainRecommend/GainRecommendCore.dart';
import '../../service/GainRecommend/ScoreInsights.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CoverUtil.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../SongInfoPage.dart';

/// 好友合作 Best50 页面：同谱取双方最高成绩重排 B35 + B15。
class CooperativeBest50Page extends StatelessWidget {
  const CooperativeBest50Page({
    super.key,
    required this.result,
    required this.mySource,
    required this.friendSource,
    required this.friendName,
  });

  final CooperativeBest50 result;
  final String mySource;
  final String friendSource;
  final String friendName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final baseline = result.baseline;

    var myCount = 0;
    var friendCount = 0;
    var sharedCount = 0;
    for (final contributor in result.contributors.values) {
      switch (contributor) {
        case CooperativeContributor.mine:
          myCount++;
        case CooperativeContributor.friend:
          friendCount++;
        case CooperativeContributor.both:
          sharedCount++;
      }
    }

    Widget statBox(String label, int value, Color? accent) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: StatTile(
              centered: true,
              label: label,
              value: '$value',
              valueColor: accent,
            ),
          ),
        );

    return BackgroundPageScaffold(
      title: l10n.awmcCoopBest50,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.awmcCoopBest50,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${baseline.raSum}',
                      style: AppTheme.number(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: Text(
                    '${l10n.flowMe} · $mySource  /  $friendName · $friendSource',
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    statBox(l10n.flowMe, myCount, scheme.primary),
                    const SizedBox(width: 8),
                    statBox(friendName, friendCount,
                        AppColors.linkBlue(brightness)),
                    const SizedBox(width: 8),
                    statBox(l10n.awmcSharedContribution, sharedCount,
                        AppColors.successGreen(brightness)),
                  ],
                ),
              ],
            ),
          ),
          for (final (name, group) in [
            ('B35', baseline.b35),
            ('B15', baseline.b15)
          ])
            if (group.isNotEmpty) ...[
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildGroupCard(context, name, group, brightness),
            ],
        ],
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    String name,
    List<GainChartRecord> group,
    Brightness brightness,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: name,
            padding: const EdgeInsets.only(bottom: 10),
            trailing: AppBadge(
              text: '${group.length}',
              background: AppSurfaces.inset(context),
              foreground: scheme.onSurfaceVariant,
            ),
          ),
          for (final (index, record) in group.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            _buildRecordRow(context, index + 1, record, brightness),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordRow(
    BuildContext context,
    int rank,
    GainChartRecord record,
    Brightness brightness,
  ) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final contributor = result.contributors[record.key];
    final (String ownerLabel, Color ownerColor) = switch (contributor) {
      CooperativeContributor.mine => (l10n.flowMe, scheme.primary),
      CooperativeContributor.friend => (
          friendName,
          AppColors.linkBlue(brightness)
        ),
      CooperativeContributor.both => (
          l10n.awmcSharedContribution,
          AppColors.successGreen(brightness)
        ),
      null => ('', scheme.onSurfaceVariant),
    };

    return Material(
      color: AppSurfaces.inset(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: InkWell(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SongInfoPage(
                songId: '${record.songId}',
                initialLevelIndex: record.levelIndex,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: AppTheme.number(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, '${record.songId}', 40),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ChartDifficultyBadge(
                          levelIndex: record.levelIndex,
                          songId: '${record.songId}',
                        ),
                        Text(
                          '${record.achievements.toStringAsFixed(4)}%',
                          style: AppTheme.number(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (ownerLabel.isNotEmpty)
                          AppBadge(
                            text: ownerLabel,
                            background: ownerColor.withValues(alpha: 0.14),
                            foreground: ownerColor,
                            numeric: false,
                            fontSize: 11,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${record.ra}',
                style: AppTheme.number(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
