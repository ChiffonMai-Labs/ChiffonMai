import 'package:flutter/material.dart';
import 'HubComponents.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../utils/FeatureRegistry.dart';
import '../service/RankingList/AvgRankingListService.dart';
import 'UserScoreSearchPage.dart';
import 'PersonalizedScorePage.dart';
import 'History/ScoreImprovementHistoryPage.dart';
import 'History/RatingHistoryPage.dart';
import 'FriendComparePage.dart';
import 'PaiziProgressPage.dart';
import 'RankTable/RankTablePage.dart';
import 'KaleidXScope/KaleidXScopeSelectPage.dart';
import 'SingleRatingCalculatorPage.dart';
import 'AchievementRateCalculatorPage.dart';
import 'AchievementFullReverseCalculatorPage.dart';
import 'Best50/Best50Page.dart';
import 'Best50/DiffBest50Page.dart';
import 'Best50/PersonalizedBest50Page.dart';
import 'Best50/PersonalizedDiffBest50Page.dart';
import 'Best50/CustomBest50Page.dart';
import 'Best50/IdealBest50Page.dart';
import 'RankingList/AvgScoreRankingListPage.dart';
import 'RankingList/FittedRatingRankingListPage.dart';
import 'RankingList/RatingRankListPage.dart';
import 'RankingList/SpecialRankingListPage.dart';
import 'dart:async';
import '../manager/DivingFish/UserBest50Manager.dart';
import '../service/History/ChartHistoryStore.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';

class ScoreHubPage extends StatefulWidget {
  const ScoreHubPage({super.key});
  @override
  State<ScoreHubPage> createState() => _ScoreHubPageState();
}

class _ScoreHubPageState extends State<ScoreHubPage> {
  void _open(BuildContext context, Widget page) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  // ===== 概览数据（都读本地缓存；读不到就显示空态，不影响下面的功能列表） =====
  int _rating = 0;
  List<int> _b35Covers = const [];
  List<int> _b15Covers = const [];
  List<int> _ratingSeries = const [];
  List<int> _dailyImprovements = const [];
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 底部导航切换时 TickerMode 会变：每次切回这个标签就重读一次，
    // 刚同步完 / 换了账号都能看到最新数据。
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_visible) unawaited(_loadOverview());
    _visible = visible;
  }

  Future<void> _loadOverview() async {
    try {
      final data = await UserBest50Manager().getCachedBest50Data();
      final key = await ChartHistoryStore.storageKey();
      final series =
          await ChartHistoryStore.instance.ratingSeries(sourceKey: key);
      final improvements =
          await ChartHistoryStore.instance.scoreImprovements(sourceKey: key);
      if (!mounted) return;
      List<int> ids(dynamic list) => [
            for (final s in (list as List? ?? const []))
              (s['song_id'] as num?)?.toInt() ?? 0,
          ];
      setState(() {
        _rating = (data?['rating'] as num?)?.toInt() ?? 0;
        _b35Covers = ids(data?['charts']?['sd']);
        _b15Covers = ids(data?['charts']?['dx']);
        _ratingSeries = [for (final p in series) p.rating];
        // entries 是按日期倒序的，取最近 7 天再翻成从旧到新。
        _dailyImprovements = [
          for (final e in improvements.entries.take(7).toList().reversed)
            e.changeCount,
        ];
      });
    } catch (e) {
      debugPrint('成绩页概览读取失败: $e');
    }
  }

  Widget _buildOverview(BuildContext context) {
    const gap = AppDesignTokens.cardGap;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchEntry(context),
        const SizedBox(height: gap),
        _buildBest50Card(context),
        const SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildRatingHistoryCard(context)),
              const SizedBox(width: gap),
              Expanded(child: _buildImprovementCard(context)),
            ],
          ),
        ),
        const SizedBox(height: gap),
        AppCard(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('排行榜',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  LinkPill(
                    label: 'Rating',
                    onTap: () => _open(context, const RatingRankListPage()),
                  ),
                  LinkPill(
                    label: '拟合总 Rating',
                    onTap: () =>
                        _open(context, const FittedRatingRankingListPage()),
                  ),
                  LinkPill(
                    label: '平均达成率',
                    onTap: () => _open(
                        context,
                        const AvgScoreRankingListPage(
                            initialMetric: AvgMetric.achievement)),
                  ),
                  LinkPill(
                    label: '平均 DX 达成率',
                    onTap: () => _open(
                        context,
                        const AvgScoreRankingListPage(
                            initialMetric: AvgMetric.dx)),
                  ),
                  LinkPill(
                    label: '特殊',
                    onTap: () =>
                        _open(context, const SpecialRankingListPage()),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _goalTile(context, '牌子进度',
                  Icons.workspace_premium_outlined, const PaiziProgressPage()),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: _goalTile(context, '段位表',
                  Icons.arrow_circle_up_rounded, const RankListPage()),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: _goalTile(
                  context, '计算工具', Icons.calculate_outlined, null),
            ),
          ],
        ),
      ],
    );
  }

  /// 「计算工具」小方块：三个计算器都在这里，功能列表里也各有入口。
  void _showCalculators(BuildContext context) {
    Widget item(BuildContext sheet, String title, String subtitle,
            IconData icon, Widget page) =>
        HubActionTile(
          title: title,
          subtitle: subtitle,
          icon: icon,
          isFavorited: _isFavorited(title),
          onToggleFavorite: () => _toggleFavorite(title),
          onTap: () {
            Navigator.of(sheet).pop();
            _open(context, page);
          },
        );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ValueListenableBuilder<FavoritesPayload>(
          valueListenable: FavoriteFeaturesNotifier.instance,
          builder: (sheet, _, __) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item(sheet, '单曲 Rating 计算', '根据达成率计算单首 rating',
                  Icons.calculate_outlined, const SingleRatingCalculator()),
              item(sheet, '达成率计算', '根据判定详情算出达成率', Icons.percent_rounded,
                  const AchievementRateCalculator()),
              item(sheet, '达成率反推', '根据判定详情推出绝赞详情', Icons.replay_rounded,
                  const AchievementFullReverseCalculator()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalTile(
      BuildContext context, String title, IconData icon, Widget? page) {
    final tint = AppColors.featureTint(title, Theme.of(context).brightness);
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () =>
          page == null ? _showCalculators(context) : _open(context, page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tint.foreground),
          ),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSearchEntry(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      onTap: () => _open(context, const UserScoreSearchPage(openSearch: true)),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text('查成绩：曲名、定数、曲目 ID',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 15, color: scheme.onSurfaceVariant)),
          ),
          IconButton(
            tooltip: '个性化成绩查询',
            onPressed: () => _open(context, const PersonalizedScorePage()),
            style: IconButton.styleFrom(
              backgroundColor: AppSurfaces.track(context),
              foregroundColor: scheme.onSurface,
              fixedSize: const Size(36, 36),
              minimumSize: const Size(36, 36),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall)),
            ),
            icon: const Icon(Icons.tune_rounded, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBest50Card(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget strip(String label, List<int> covers) => LayoutBuilder(
          builder: (context, constraints) {
            const cell = 30.0; // 26 + 间距 4
            const labelWidth = 34.0, moreWidth = 32.0;
            final fit =
                ((constraints.maxWidth - labelWidth - moreWidth) / cell).floor();
            final shown = covers.take(fit < 0 ? 0 : fit).toList();
            return Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant)),
                ),
                for (final id in shown)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CoverUtil.buildCoverWidgetWithContext(
                          context, id.toString(), 26),
                    ),
                  ),
                if (covers.length > shown.length)
                  Text('+${covers.length - shown.length}',
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            );
          },
        );
    return AppCard(
      onTap: () => _open(context, const B50Page()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Text('Best50',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Text(_rating == 0 ? '-' : '$_rating',
                  style: AppTheme.number(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
            ],
          ),
          const SizedBox(height: 12),
          if (_b35Covers.isEmpty && _b15Covers.isEmpty)
            Text('刷新数据后这里会显示 Best35 与 Best15',
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
          else ...[
            strip('B35', _b35Covers),
            const SizedBox(height: 4),
            strip('B15', _b15Covers),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              LinkPill(
                  label: '拟合',
                  onTap: () => _open(context, const DiffBest50Page())),
              LinkPill(
                  label: '个性化',
                  onTap: () =>
                      _open(context, const PersonalizedBest50Page())),
              LinkPill(
                  label: '个性化拟合',
                  onTap: () =>
                      _open(context, const PersonalizedDiffBest50Page())),
              LinkPill(
                  label: '理想',
                  onTap: () => _open(context, const IdealBest50Page())),
              LinkPill(
                  label: '自定义',
                  onTap: () => _open(context, const CustomBest50Page())),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHistoryCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final series = _ratingSeries;
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _open(context, const RatingHistoryPage()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Rating 历史',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (series.length >= 2) ...[
            SizedBox(
              height: 56,
              child: CustomPaint(
                painter:
                    _SparklinePainter(series: series, color: scheme.primary),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
              series.isEmpty
                  ? '同步后开始记录'
                  : '最新 ${series.last} · 共 ${series.length} 次记录',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildImprovementCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = _dailyImprovements;
    final peak = days.isEmpty ? 1 : days.reduce((a, b) => a > b ? a : b);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _open(context, const ScoreImprovementHistoryPage()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('成绩提升',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (days.isNotEmpty) ...[
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Expanded(
                    child: FractionallySizedBox(
                      heightFactor:
                          peak == 0 ? 0.1 : (days[i] / peak).clamp(0.1, 1.0),
                      alignment: Alignment.bottomCenter,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
            const SizedBox(height: 8),
          ],
          Text(days.isEmpty ? '同步后开始记录' : '按日回顾',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  bool _isFavorited(String title) =>
      FavoriteFeaturesNotifier.titles.contains(title);

  Future<void> _toggleFavorite(String title) =>
      FavoriteFeaturesNotifier.toggle(title);

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) {
          final features = <String, Widget>{
            '成绩查询': HubActionTile(
              title: '成绩查询',
              subtitle: '浏览全部游玩记录与筛选结果',
              icon: Icons.score_outlined,
              isFavorited: _isFavorited('成绩查询'),
              onToggleFavorite: () => _toggleFavorite('成绩查询'),
              onTap: () => _open(context, const UserScoreSearchPage()),
            ),
            '个性化成绩查询': HubActionTile(
              title: '个性化成绩查询',
              subtitle: '按等级或谱师查看成绩',
              icon: Icons.tune_rounded,
              isFavorited: _isFavorited('个性化成绩查询'),
              onToggleFavorite: () => _toggleFavorite('个性化成绩查询'),
              onTap: () => _open(context, const PersonalizedScorePage()),
            ),
            '成绩提升历史': HubActionTile(
              title: '成绩提升历史',
              subtitle: '按日回顾最佳成绩的变化与提升',
              icon: Icons.auto_graph_rounded,
              isFavorited: _isFavorited('成绩提升历史'),
              onToggleFavorite: () => _toggleFavorite('成绩提升历史'),
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
                _open(context, const ScoreImprovementHistoryPage());
              },
            ),
            'Rating 历史': HubActionTile(
              title: 'Rating 历史',
              subtitle: '看 Rating 随时间的变化',
              icon: Icons.timeline_rounded,
              isFavorited: _isFavorited('Rating 历史'),
              onToggleFavorite: () => _toggleFavorite('Rating 历史'),
              onTap: () => _open(context, const RatingHistoryPage()),
            ),
            '好友对比': HubActionTile(
              title: '好友对比',
              subtitle: '看看你和好友的成绩差异',
              icon: Icons.people_outline_rounded,
              isFavorited: _isFavorited('好友对比'),
              onToggleFavorite: () => _toggleFavorite('好友对比'),
              onTap: () => _open(context, const FriendComparePage()),
            ),
            'Best50': HubActionTile(
              title: 'Best50',
              subtitle: '查看当前 Best35 与 Best15',
              icon: Icons.leaderboard_rounded,
              isFavorited: _isFavorited('Best50'),
              onToggleFavorite: () => _toggleFavorite('Best50'),
              onTap: () => _open(context, const B50Page()),
            ),
            '拟合 Best50': HubActionTile(
              title: '拟合 Best50',
              subtitle: '分析潜在 Rating 上限',
              icon: Icons.auto_graph_rounded,
              isFavorited: _isFavorited('拟合 Best50'),
              onToggleFavorite: () => _toggleFavorite('拟合 Best50'),
              onTap: () => _open(context, const DiffBest50Page()),
            ),
            '个性化 Best50': HubActionTile(
              title: '个性化 Best50',
              subtitle: '按标签筛选 Best50',
              icon: Icons.filter_alt_outlined,
              isFavorited: _isFavorited('个性化 Best50'),
              onToggleFavorite: () => _toggleFavorite('个性化 Best50'),
              onTap: () => _open(context, const PersonalizedBest50Page()),
            ),
            '个性化拟合 Best50': HubActionTile(
              title: '个性化拟合 Best50',
              subtitle: '按标签查看拟合 Rating 上限',
              icon: Icons.analytics_outlined,
              isFavorited: _isFavorited('个性化拟合 Best50'),
              onToggleFavorite: () => _toggleFavorite('个性化拟合 Best50'),
              onTap: () => _open(context, const PersonalizedDiffBest50Page()),
            ),
            '理想 Best50': HubActionTile(
              title: '理想 Best50',
              subtitle: '全员升一档后的 Best50 模拟',
              icon: Icons.auto_fix_high_rounded,
              isFavorited: _isFavorited('理想 Best50'),
              onToggleFavorite: () => _toggleFavorite('理想 Best50'),
              onTap: () => _open(context, const IdealBest50Page()),
            ),
            '自定义 Best50': HubActionTile(
              title: '自定义 Best50',
              subtitle: '手动填写 50 张成绩卡片',
              icon: Icons.edit_note_rounded,
              isFavorited: _isFavorited('自定义 Best50'),
              onToggleFavorite: () => _toggleFavorite('自定义 Best50'),
              onTap: () => _open(context, const CustomBest50Page()),
            ),
            'Rating 排行榜': HubActionTile(
              title: 'Rating 排行榜',
              subtitle: '查看玩家 Rating 排行',
              icon: Icons.public_rounded,
              isFavorited: _isFavorited('Rating 排行榜'),
              onToggleFavorite: () => _toggleFavorite('Rating 排行榜'),
              onTap: () => _open(context, const RatingRankListPage()),
            ),
            '拟合总Rating排行榜': HubActionTile(
              title: '拟合总Rating排行榜',
              subtitle: '拟合总 Rating 站内排行',
              icon: Icons.auto_graph_rounded,
              isFavorited: _isFavorited('拟合总Rating排行榜'),
              onToggleFavorite: () => _toggleFavorite('拟合总Rating排行榜'),
              onTap: () => _open(context, const FittedRatingRankingListPage()),
            ),
            '平均达成率排行榜': HubActionTile(
              title: '平均达成率排行榜',
              subtitle: '按全量成绩的平均达成率排名',
              icon: Icons.percent_rounded,
              isFavorited: _isFavorited('平均达成率排行榜'),
              onToggleFavorite: () => _toggleFavorite('平均达成率排行榜'),
              onTap: () => _open(
                  context,
                  const AvgScoreRankingListPage(
                      initialMetric: AvgMetric.achievement)),
            ),
            '平均DX分数达成率排行榜': HubActionTile(
              title: '平均DX分数达成率排行榜',
              subtitle: '按全量成绩的平均DX得分达成率排名',
              icon: Icons.score_outlined,
              isFavorited: _isFavorited('平均DX分数达成率排行榜'),
              onToggleFavorite: () => _toggleFavorite('平均DX分数达成率排行榜'),
              onTap: () => _open(context,
                  const AvgScoreRankingListPage(initialMetric: AvgMetric.dx)),
            ),
            '特殊排行榜': HubActionTile(
              title: '特殊排行榜',
              subtitle: 'BPM 55？BPM 339？！',
              icon: Icons.workspace_premium_outlined,
              isFavorited: _isFavorited('特殊排行榜'),
              onToggleFavorite: () => _toggleFavorite('特殊排行榜'),
              onTap: () => _open(context, const SpecialRankingListPage()),
            ),
            '牌子进度': HubActionTile(
              title: '牌子进度',
              subtitle: '查看各版本与目标牌子',
              icon: Icons.workspace_premium_outlined,
              isFavorited: _isFavorited('牌子进度'),
              onToggleFavorite: () => _toggleFavorite('牌子进度'),
              onTap: () => _open(context, const PaiziProgressPage()),
            ),
            '段位表': HubActionTile(
              title: '段位表',
              subtitle: '挑战你的下一段位',
              icon: Icons.arrow_circle_up_rounded,
              isFavorited: _isFavorited('段位表'),
              onToggleFavorite: () => _toggleFavorite('段位表'),
              onTap: () => _open(context, const RankListPage()),
            ),
            'KALEIDXSCOPE': HubActionTile(
              title: 'KALEIDXSCOPE',
              subtitle: '探索独特的舞萌玩法',
              icon: Icons.color_lens_outlined,
              isFavorited: _isFavorited('KALEIDXSCOPE'),
              onToggleFavorite: () => _toggleFavorite('KALEIDXSCOPE'),
              onTap: () => _open(context, const KaleidXScopeSelectPage()),
            ),
            '单曲 Rating 计算': HubActionTile(
              title: '单曲 Rating 计算',
              subtitle: '根据达成率计算单首 rating',
              icon: Icons.calculate_outlined,
              isFavorited: _isFavorited('单曲 Rating 计算'),
              onToggleFavorite: () => _toggleFavorite('单曲 Rating 计算'),
              onTap: () => _open(context, const SingleRatingCalculator()),
            ),
            '达成率计算': HubActionTile(
              title: '达成率计算',
              subtitle: '根据判定详情算出达成率',
              icon: Icons.percent_rounded,
              isFavorited: _isFavorited('达成率计算'),
              onToggleFavorite: () => _toggleFavorite('达成率计算'),
              onTap: () => _open(context, const AchievementRateCalculator()),
            ),
            '达成率反推': HubActionTile(
              title: '达成率反推',
              subtitle: '根据判定详情推出绝赞详情',
              icon: Icons.replay_rounded,
              isFavorited: _isFavorited('达成率反推'),
              onToggleFavorite: () => _toggleFavorite('达成率反推'),
              onTap: () =>
                  _open(context, const AchievementFullReverseCalculator()),
            ),
          };

          final sections = FeatureRegistry.sections['成绩']!;
          return HubPageScaffold(
            title: '成绩',
            subtitle: '查成绩、看提升、比排名与追踪进度',
            icon: Icons.analytics_rounded,
            hero: _buildOverview(context),
            children: [
              const AppSectionHeader(
                title: '全部功能',
                subtitle: '点星标加入首页「常用」',
              ),
              const SizedBox(height: 4),
              for (final section in sections) ...[
                HubSection(
                  title: section.title,
                  subtitle: section.subtitle,
                  icon: section.icon,
                  badgeCount: section.titles.length,
                  children: [
                    for (final title in section.titles) features[title]!
                  ],
                ),
                if (section != sections.last) const SizedBox(height: 24),
              ],
            ],
          );
        },
      );
}

/// 概览卡片里的 Rating 走势：折线 + 下方淡色填充。
class _SparklinePainter extends CustomPainter {
  final List<int> series;
  final Color color;

  const _SparklinePainter({required this.series, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final minV = series.reduce((a, b) => a < b ? a : b).toDouble();
    final maxV = series.reduce((a, b) => a > b ? a : b).toDouble();
    final span = maxV - minV;
    const pad = 3.0;
    Offset at(int i) => Offset(
          size.width * i / (series.length - 1),
          span == 0
              ? size.height / 2
              : pad + (size.height - pad * 2) * (1 - (series[i] - minV) / span),
        );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < series.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.10));
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.color != color || old.series != series;
}
