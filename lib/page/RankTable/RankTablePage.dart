import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/service/RankTable/RankTableService.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/page/RankTable/RankTableDetailPage.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import '../../service/RankTable/RankCompletionStore.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/RankCompletionButton.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../../utils/AppDesignTokens.dart';

class RankListPage extends StatefulWidget {
  const RankListPage({super.key});

  @override
  State<RankListPage> createState() => _RankListPageState();
}

class _RankListPageState extends State<RankListPage> {
  final RankListService _service = RankListService();
  final _completion = RankCompletionStore.instance;
  int _group = 0;

  @override
  void initState() {
    super.initState();
    _completion.addListener(_changed);
    _completion.load();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _completion.removeListener(_changed);
    super.dispose();
  }

  bool _isCleared(String rank) {
    final status = _completion.status(rank);
    return status == RankCompletion.passed ||
        status == RankCompletion.redPassed;
  }

  /// 段位 / 真段位两组（两个皆传归在真段位），顺序跟着 [RankListService.getRankOptions]。
  List<(String, List<String>)> _groups() {
    final options = _service.getRankOptions();
    bool isShin(String rank) => rank.startsWith('真') || rank.endsWith('皆传');
    return [
      ('段位', options.where((r) => !isShin(r)).toList()),
      ('真段位', options.where(isShin).toList()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups();
    final (_, ranks) = groups[_group];
    return BackgroundPageScaffold(
      title: context.l10n.featureRankTable,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
            AppDesignTokens.gutter, AppDesignTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntranceAnimation(child: _buildSummary()),
            const SizedBox(height: AppDesignTokens.cardGap),
            SegmentedTabs(
              items: [
                for (final (label, members) in groups)
                  SegmentedTabItem(
                    '${context.featureText(label)} ${members.where(_isCleared).length}/${members.length}',
                  ),
              ],
              selectedIndex: _group,
              onChanged: (index) => setState(() => _group = index),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            for (final (index, rank) in ranks.indexed)
              EntranceAnimation(
                // 换分组时重播
                key: ValueKey('$_group-$rank'),
                index: index,
                offset: const Offset(0, 10),
                duration: const Duration(milliseconds: 340),
                child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
                  child: _buildRankCard(rank),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final scheme = Theme.of(context).colorScheme;
    final options = _service.getRankOptions();
    final cleared = options.where(_isCleared).length;
    final red = options
        .where((r) => _completion.status(r) == RankCompletion.redPassed)
        .length;
    final failed = options
        .where((r) => _completion.status(r) == RankCompletion.failed)
        .length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              RollingNumber(
                value: cleared,
                style: AppTheme.number(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.flowP0Passed((options.length).toString()),
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              if (red > 0) ...[
                Text(
                  context.l10n.flowRedPassP0((red).toString()),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color:
                        AppColors.warningOrange(Theme.of(context).brightness),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (failed > 0)
                Text(
                  context.l10n.flowFailedP0((failed).toString()),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SmoothLinearProgressIndicator(
            value: options.isEmpty ? 0 : cleared / options.length,
            minHeight: 8,
            color: scheme.primary,
            backgroundColor: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(String rank) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final rankData = _service.getRankData(rank);
    final accent = switch (_group) {
      0 => AppColors.medalColor('bronze'),
      _ => AppColors.difficultyForegroundByIndex(ChartDifficulty.master,
          brightness: brightness),
    };
    final tint = switch (_completion.status(rank)) {
      RankCompletion.passed => AppColors.successGreen(brightness),
      RankCompletion.failed => AppColors.errorRed(brightness),
      RankCompletion.redPassed => AppColors.warningOrange(brightness),
      RankCompletion.unplayed => null,
    };
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(12),
      color: tint == null
          ? null
          : Color.alphaBlend(
              tint.withValues(alpha: 0.1), AppSurfaces.card(context)),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RankDetailPage(rankName: rank),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppBadge(
                text: rank,
                background: accent.withValues(alpha: 0.14),
                foreground: accent,
                fontSize: 14,
              ),
              if (rankData != null) ...[
                const SizedBox(width: 8),
                Text(
                  'HP ${rankData.initialHp}',
                  style: AppTheme.number(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Spacer(),
              RankCompletionButton(rank: rank, showAchievement: false),
            ],
          ),
          if (rankData != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildCover(
                      rankData.songIds[i],
                      rankData.levelIndexes[i],
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

  /// 曲绘外圈用难度色，一眼看出每首打什么难度。
  Widget _buildCover(String songId, int levelIndex) {
    const ring = 2.5;
    final color = AppColors.difficultyForegroundByIndex(levelIndex,
        brightness: Theme.of(context).brightness);
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(ring),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(AppDesignTokens.radiusSmall - ring),
          child: LayoutBuilder(
            builder: (context, constraints) =>
                CoverUtil.buildCoverWidgetWithContext(
              context,
              songId.isNotEmpty ? songId : '0',
              constraints.maxWidth,
            ),
          ),
        ),
      ),
    );
  }
}
