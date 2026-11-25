import 'package:flutter/cupertino.dart' as ios;
import 'AwmcNet/PlayerConnectionPage.dart';
import '../l10n/LocalizationsExtension.dart';
import '../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';
import 'HubComponents.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../service/RankingList/AvgRankingListService.dart';
import 'UserScoreSearchPage.dart';
import 'PersonalizedScorePage.dart';
import 'History/ScoreImprovementHistoryPage.dart';
import 'History/RatingHistoryPage.dart';
import 'FriendComparePage.dart';
import 'ScoreInsightsPage.dart';
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
import '../utils/CurrentDataSourceNotifier.dart';

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
  int _overviewRequest = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 底部导航切换时 TickerMode 会变：每次切回这个标签就重读一次，
    // 刚同步完 / 换了账号都能看到最新数据。
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_visible) unawaited(_loadOverview());
    _visible = visible;
  }

  @override
  void initState() {
    super.initState();
    UserBest50Manager.dataRevision.addListener(_onDataChanged);
    CurrentDataSourceNotifier.instance.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    UserBest50Manager.dataRevision.removeListener(_onDataChanged);
    CurrentDataSourceNotifier.instance.removeListener(_onDataChanged);
    super.dispose();
  }

  /// 换数据源、刷新成绩时这个标签可能正开着，不能只靠切回标签重读。
  /// 看不见时不用读，切回来会重读。
  void _onDataChanged() {
    if (_visible) unawaited(_loadOverview());
  }

  Future<void> _loadOverview() async {
    final request = ++_overviewRequest;
    try {
      final data = await UserBest50Manager().getBest50ForDisplay();
      final key = await ChartHistoryStore.storageKey();
      final series =
          await ChartHistoryStore.instance.ratingSeries(sourceKey: key);
      final improvements =
          await ChartHistoryStore.instance.scoreImprovements(sourceKey: key);
      // 连续刷新时只认最新一次，旧结果不能覆盖新数据
      if (!mounted || request != _overviewRequest) return;
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
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(context.featureText('排行榜'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    tooltip: context.l10n.hubMoreActionsTooltip,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showRankingsSheet(context),
                    icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  LinkPill(
                    label: 'Rating',
                    onTap: () => _open(context, const RatingRankListPage()),
                  ),
                  LinkPill(
                    label: context.featureText('拟合总 Rating'),
                    onTap: () =>
                        _open(context, const FittedRatingRankingListPage()),
                  ),
                  LinkPill(
                    label: context.featureText('平均达成率'),
                    onTap: () => _open(
                        context,
                        const AvgScoreRankingListPage(
                            initialMetric: AvgMetric.achievement)),
                  ),
                  LinkPill(
                    label: context.featureText('平均DX分数达成率'),
                    onTap: () => _open(
                        context,
                        const AvgScoreRankingListPage(
                            initialMetric: AvgMetric.dx)),
                  ),
                  LinkPill(
                    label: context.featureText('特殊'),
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
              child: _goalTile(context, 'KALEIDXSCOPE',
                  Icons.color_lens_outlined, const KaleidXScopeSelectPage()),
            ),
          ],
        ),
        const SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _goalTile(context, '好友对比',
                  Icons.people_outline_rounded, const FriendComparePage()),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: _goalTile(context, context.l10n.featureCalculators2,
                  Icons.calculate_outlined, null),
            ),
          ],
        ),
      ],
    );
  }

  /// Best50 与成绩分析聚合面板：保留完整说明与星标收藏。
  void _showBest50Sheet(BuildContext context) {
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
    showHubGroupSheet(
      context,
      title: 'Best50 与分析',
      subtitle: '当前表现、拟合上限、标签筛选与制图',
      itemsBuilder: (sheet) => [
        item(sheet, 'Best50', '查看当前 Best35 与 Best15',
            Icons.leaderboard_rounded, const B50Page()),
        item(sheet, '拟合 Best50', '分析潜在 Rating 上限',
            Icons.auto_graph_rounded, const DiffBest50Page()),
        item(sheet, '个性化 Best50', '按标签筛选 Best50',
            Icons.filter_alt_outlined, const PersonalizedBest50Page()),
        item(sheet, '个性化拟合 Best50', '按标签查看拟合 Rating 上限',
            Icons.analytics_outlined, const PersonalizedDiffBest50Page()),
        item(sheet, '理想 Best50', '全员升一档后的 Best50 模拟',
            Icons.auto_fix_high_rounded, const IdealBest50Page()),
        item(sheet, '自定义 Best50', '手动填写 50 张成绩卡片',
            Icons.edit_note_rounded, const CustomBest50Page()),
        item(sheet, '成绩分析', '成绩全景 · B50 边缘巡检 · 弱项处方',
            Icons.insights_rounded, const ScoreInsightsPage()),
      ],
    );
  }

  /// 全部排行榜聚合面板：保留完整说明与星标收藏。
  void _showRankingsSheet(BuildContext context) {
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
    showHubGroupSheet(
      context,
      title: '全部排行榜',
      subtitle: 'Rating、达成率与特殊玩家榜单',
      itemsBuilder: (sheet) => [
        item(sheet, 'Rating 排行榜', '查看玩家 Rating 排行', Icons.public_rounded,
            const RatingRankListPage()),
        item(sheet, '拟合总Rating排行榜', '拟合总 Rating 站内排行',
            Icons.auto_graph_rounded, const FittedRatingRankingListPage()),
        item(
            sheet,
            '平均达成率排行榜',
            '按全量成绩的平均达成率排名',
            Icons.percent_rounded,
            const AvgScoreRankingListPage(
                initialMetric: AvgMetric.achievement)),
        item(sheet, '平均DX分数达成率排行榜', '按全量成绩的平均DX分数达成率排名',
            Icons.score_outlined,
            const AvgScoreRankingListPage(initialMetric: AvgMetric.dx)),
        item(sheet, '特殊排行榜', 'BPM 55？BPM 339？！',
            Icons.workspace_premium_outlined, const SpecialRankingListPage()),
      ],
    );
  }

  /// 「计算工具」小方块：三个计算器都在这里，带星标收藏。
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
    showHubGroupSheet(
      context,
      title: context.l10n.featureCalculators2,
      subtitle: 'Rating、达成率与判定反推',
      itemsBuilder: (sheet) => [
        item(
            sheet,
            '单曲 Rating 计算',
            context.l10n.featureCalculateASongRatingFromAchievement,
            Icons.calculate_outlined,
            const SingleRatingCalculator()),
        item(
            sheet,
            '达成率计算',
            context.l10n.featureCalculateAchievementFromJudgements,
            Icons.percent_rounded,
            const AchievementRateCalculator()),
        item(
            sheet,
            '达成率反推',
            context.l10n.featureInferBREAKDetailsFromJudgements,
            Icons.replay_rounded,
            const AchievementFullReverseCalculator()),
      ],
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
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Icon(icon, size: 18, color: tint.foreground),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              context.featureText(title),
              maxLines: 1,
              softWrap: false,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
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
            child: Text(context.l10n.featureTitleAliasIDArtistCharterBPM,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    TextStyle(fontSize: 15, color: scheme.onSurfaceVariant)),
          ),
          IconButton(
            tooltip: context.featureText('个性化成绩查询'),
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
            const labelWidth = 34.0, moreWidth = 26.0;
            final available =
                (constraints.maxWidth - labelWidth).clamp(0.0, double.infinity);
            final maxFull = (available / cell).floor();
            final fit = covers.length <= maxFull
                ? maxFull
                : ((available - moreWidth) / cell).floor().clamp(0, covers.length);
            final shown = covers.take(fit < 0 ? 0 : fit).toList();
            return Row(
              children: [
                SizedBox(
                  width: labelWidth,
                  child: Text(context.featureText(label),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant)),
                ),
                for (final (index, id) in shown.indexed)
                  Padding(
                    // 同一首歌的不同难度可能同时上榜，Key 要带上位置
                    key: ValueKey('$label-$index-$id'),
                    padding: const EdgeInsets.only(right: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CoverUtil.buildCoverWidgetWithContext(
                          context, id.toString(), 26),
                    ),
                  ),
                if (covers.length > shown.length) ...[
                  const Spacer(),
                  Text('+${covers.length - shown.length}',
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
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
            Text(context.featureText('刷新数据后这里会显示 Best35 与 Best15'),
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
                  label: context.featureText('拟合'),
                  onTap: () => _open(context, const DiffBest50Page())),
              LinkPill(
                  label: context.featureText('个性化'),
                  onTap: () =>
                      _open(context, const PersonalizedBest50Page())),
              LinkPill(
                  label: context.featureText('个性化拟合'),
                  onTap: () =>
                      _open(context, const PersonalizedDiffBest50Page())),
              LinkPill(
                  label: context.featureText('理想'),
                  onTap: () => _open(context, const IdealBest50Page())),
              LinkPill(
                  label: context.featureText('自定义'),
                  onTap: () => _open(context, const CustomBest50Page())),
              LinkPill(
                  label: context.l10n.awmcScoreInsights,
                  onTap: () => _open(context, const ScoreInsightsPage())),
              Tooltip(
                message: context.l10n.hubMoreActionsTooltip,
                child: Material(
                  color: AppSurfaces.inset(context),
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    splashFactory: NoSplash.splashFactory,
                    highlightColor: Colors.transparent,
                    onTap: () => _showBest50Sheet(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 30),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
          Text(context.featureText('Rating 历史'),
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
                  ? context.featureText('同步后开始记录')
                  : context.l10n.hubRatingRecords(series.last, series.length),
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
          Text(context.featureText('成绩提升'),
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
          Text(days.isEmpty ? context.featureText('同步后开始记录') : context.featureText('按日回顾'),
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
  Widget build(BuildContext context) => HubPageScaffold(
        title: '成绩',
        subtitle: '查成绩、看提升、比排名与追踪进度',
        icon: Icons.analytics_rounded,
        children: [
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
            ios.CupertinoListTile(
                leading: const Icon(ios.CupertinoIcons.link),
                title: Text(context.l10n.qqPlayerConnect),
                trailing: const ios.CupertinoListTileChevron(),
                onTap: () => PlayerConnectionPage.open(context)),
            const SizedBox(height: AppDesignTokens.cardGap),
          ],
          _buildOverview(context),
        ],
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
