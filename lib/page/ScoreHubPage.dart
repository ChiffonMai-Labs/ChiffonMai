import 'package:flutter/material.dart';
import 'HubComponents.dart';
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
            children: [
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
