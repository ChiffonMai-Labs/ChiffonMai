import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/Kop/KopQualifierService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/CoverUtil.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/EmptyState.dart';
import '../widgets/MarqueeText.dart';

/// KOP 8th Score Attack 预选：官方前 100 榜与本地最佳模拟。
///
/// 预选榜来自 sega 官网公开 JSON；国服不能参赛，所以本地成绩只做娱乐模拟。
/// 到期后入口在成绩 Hub 隐藏，但页面本身仍可直接打开查看最终榜。
class KopQualifierPage extends StatefulWidget {
  const KopQualifierPage({super.key});

  @override
  State<KopQualifierPage> createState() => _KopQualifierPageState();
}

class _KopQualifierPageState extends State<KopQualifierPage> {
  KopRegion _region = KopRegion.international;
  KopRankingSnapshot? _ranking;
  List<KopSongBest?> _bests = const [null, null, null];
  bool _loadingBests = true;
  bool _bestsFailed = false;
  bool _loadingRanking = false;
  bool _rankingFailed = false;
  DateTime _now = DateTime.now();
  Timer? _ticker;
  int _rankingRequest = 0;

  @override
  void initState() {
    super.initState();
    // 倒计时每秒刷新；越过截止时刻后界面自动切成已结束。
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _loadBests();
    _loadRanking();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadBests() async {
    setState(() {
      _loadingBests = true;
      _bestsFailed = false;
    });
    try {
      final bests = await KopQualifierService.loadLocalBests();
      if (!mounted) return;
      setState(() {
        _bests = bests;
        _loadingBests = false;
      });
    } catch (e) {
      debugPrint('读取 KOP 预选本地成绩失败: $e');
      if (!mounted) return;
      setState(() {
        _loadingBests = false;
        _bestsFailed = true;
      });
    }
  }

  Future<void> _loadRanking({bool force = false}) async {
    final region = _region;
    final request = ++_rankingRequest;
    setState(() {
      _loadingRanking = true;
      _rankingFailed = false;
    });
    try {
      final snapshot =
          await KopQualifierService.loadRanking(region, force: force);
      // 快速切服时旧请求不能覆盖新选择。
      if (!mounted || request != _rankingRequest) return;
      setState(() {
        _ranking = snapshot;
        _loadingRanking = false;
      });
    } catch (e) {
      debugPrint('读取 KOP 预选官方榜失败: $e');
      if (!mounted || request != _rankingRequest) return;
      setState(() {
        _loadingRanking = false;
        _rankingFailed = true;
      });
    }
  }

  void _switchRegion(int index) {
    if (index == _region.index) return;
    setState(() {
      _region = KopRegion.values[index];
      _ranking = null;
      _rankingFailed = false;
    });
    _loadRanking();
  }

  void _refresh() {
    _loadRanking(force: true);
    _loadBests();
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _clock(DateTime time) => '${_two(time.hour)}:${_two(time.minute)}';

  /// 官方 `2026/10/31 02:55:12` → `10/31 02:55`。
  static String _shortRecordDate(String raw) {
    final parts = raw.split(' ');
    if (parts.length != 2) return raw;
    final date = parts[0].split('/');
    final time = parts[1].split(':');
    if (date.length < 3 || time.length < 2) return raw;
    return '${date[1]}/${date[2]} ${time[0]}:${time[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = _now;
    final expired = KopQualifierService.isExpired(now);
    final entries = _ranking?.entries ?? const <KopRankingEntry>[];
    return BackgroundPageScaffold(
      title: l10n.kopQualifierTitle,
      actions: [
        IconButton(
          tooltip: l10n.kopRefresh,
          onPressed: _loadingRanking ? null : _refresh,
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 0),
            sliver: SliverList.list(children: [
              _buildCountdown(context, expired),
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildRegionCard(context),
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildSongsCard(context),
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildEstimateCard(context),
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildRankingHeader(context),
            ]),
          ),
          if (entries.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.gutter),
              sliver: SliverList.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) => _buildRankingRow(
                    context, entries[index], index, entries.length),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppDesignTokens.gutter,
                AppDesignTokens.cardGap, AppDesignTokens.gutter,
                AppDesignTokens.gutter + MediaQuery.paddingOf(context).bottom),
            sliver: SliverToBoxAdapter(child: _buildSourceNote(context)),
          ),
        ],
      ),
    );
  }

  // ===== 倒计时 =====

  Widget _buildCountdown(BuildContext context, bool expired) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final remaining = KopQualifierService.remaining(_now);
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;
    final countdown = expired
        ? l10n.kopStatusEnded
        : '${days > 0 ? '$days${l10n.kopDayUnit}' : ''}'
            '${_two(hours)}:${_two(minutes)}:${_two(seconds)}';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                expired ? Icons.event_busy_rounded : Icons.timer_outlined,
                size: 18,
                color: expired ? scheme.error : scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                expired ? l10n.kopStatusEnded : l10n.kopStatusLive,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: expired ? scheme.error : scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!expired) ...[
            Text(l10n.kopCountdownLabel,
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                countdown,
                style: AppTheme.number(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            l10n.kopDeadline(KopQualifierService.deadlineText()),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ===== 服务器切换与规则说明 =====

  Widget _buildRegionCard(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            items: [
              SegmentedTabItem(l10n.kopRegionInternational),
              SegmentedTabItem(l10n.kopRegionJapan),
            ],
            selectedIndex: _region.index,
            onChanged: _switchRegion,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius:
                  BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.kopRuleNotice,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 课题曲与本地最佳 =====

  Widget _buildSongsCard(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: l10n.kopSongsTitle,
            padding: EdgeInsets.zero,
            trailing: _loadingBests
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          if (_bestsFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.kopBestsFailed,
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            ),
          for (final (index, song) in kopQualifierSongs.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            _buildSongRow(
              context,
              song: song,
              best: index < _bests.length ? _bests[index] : null,
            ),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.kopLocalDataHint,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSongRow(
    BuildContext context, {
    required KopQualifierSong song,
    required KopSongBest? best,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final penalty =
        best == null ? 0.0 : KopQualifierService.difficultyPenalty(best.levelIndex);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          // 曲绘本地的命名按基础曲号；谱面文件 id 只用于匹配成绩。
          child: CoverUtil.buildCoverWidgetWithContext(
              context, '${song.baseSongId}', 56),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarqueeText(
                text: song.title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SongTypeBadge(songId: song.chartIdText, type: 'DX'),
                  ChartDifficultyBadge(
                    levelIndex: best?.levelIndex ?? ChartDifficulty.master,
                    songId: song.chartIdText,
                  ),
                  if (penalty > 0)
                    AppBadge(
                      text: l10n.kopPenalty(
                          penalty.toStringAsFixed(0)),
                      background: AppColors.syncBadge(
                              Theme.of(context).brightness)
                          .background,
                      foreground: AppColors.syncBadge(
                              Theme.of(context).brightness)
                          .foreground,
                      fontSize: 10,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              if (best == null)
                Text(
                  l10n.kopNoRecord,
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        l10n.kopBestAchievement(
                            best.achievement.toStringAsFixed(4)),
                        maxLines: 1,
                        style: AppTheme.number(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.kopCorrectedScore('${best.correctedScore}'),
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                Text(
                  l10n.kopDxScore('${best.dxScore}'),
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ===== 模拟排名 =====

  Widget _buildEstimateCard(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ranking = _ranking?.entries ?? const <KopRankingEntry>[];
    final estimate =
        KopQualifierService.estimate(bests: _bests, ranking: ranking);
    final missing = estimate.missingCount;

    String gapValue(int rank) {
      final gap = estimate.gaps[rank];
      if (gap == null) return '—';
      return gap < 0 ? l10n.kopAlreadyAhead : '$gap';
    }

    return EmphasisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.kopEstimateTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: estimate.complete
                      ? l10n.kopTotalScore
                      : l10n.kopTotalScorePartial,
                  value: estimate.totalScore?.toString() ?? '—',
                  valueSize: 22,
                  valueColor: scheme.primary,
                ),
              ),
              Expanded(
                child: StatTile(
                  label: l10n.kopTotalDx,
                  value: estimate.totalDx.toString(),
                  valueSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ranking.isEmpty)
            Text(
              l10n.kopEstimateWaiting,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            )
          else if (estimate.complete)
            Text(
              estimate.rank != null && estimate.rank! <= 100
                  ? l10n.kopRankSimulated(estimate.rank!)
                  : l10n.kopRankOutside,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: estimate.rank != null && estimate.rank! <= 100
                    ? scheme.primary
                    : scheme.error,
              ),
            )
          else
            Text(
              l10n.kopIncomplete,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          if (missing > 0 && estimate.requiredAchievement != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.kopRequiredAchievement(
                missing,
                estimate.requiredAchievement!.toStringAsFixed(4),
              ),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.warningOrange(Theme.of(context).brightness),
              ),
            ),
            if (estimate.requiredAchievement! > 101.0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.kopRequiredTooHigh,
                  style: TextStyle(
                      fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              for (final rank in const [1, 10, 50, 100])
                Expanded(
                  child: StatTile(
                    label: l10n.kopGapLabel('$rank'),
                    value: gapValue(rank),
                    centered: true,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.kopEstimateHint,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ===== 官方榜 =====

  Widget _buildRankingHeader(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ranking = _ranking;
    final warning = AppColors.warningOrange(Theme.of(context).brightness);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.kopLeaderboardTitle,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (_loadingRanking)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (ranking != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.kopOfficialUpdate(ranking.updateText),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            Text(
              l10n.kopFetchedAt(_clock(ranking.fetchedAt)),
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            if (ranking.stale) ...[
              const SizedBox(height: 6),
              Text(
                l10n.kopStaleNotice(_clock(ranking.fetchedAt)),
                style: TextStyle(fontSize: 12, color: warning),
              ),
            ],
          ],
          if (_rankingFailed && ranking == null) ...[
            const SizedBox(height: 12),
            EmptyState(
              icon: Icons.cloud_off_outlined,
              message: l10n.kopLoadFailed,
              actionLabel: l10n.flowRetry,
              actionIcon: Icons.refresh_rounded,
              onAction: _refresh,
            ),
          ] else if (ranking == null && _loadingRanking) ...[
            const SizedBox(height: 12),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            ),
          ] else if (ranking != null && ranking.entries.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.kopEmptyRanking,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ] else if (ranking != null) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 34,
                  child: Text(l10n.kopRankColumn,
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
                ),
                Expanded(
                  child: Text(l10n.kopPlayerColumn,
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
                ),
                Text(l10n.kopScoreColumn,
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankingRow(BuildContext context, KopRankingEntry entry,
      int index, int total) {
    final scheme = Theme.of(context).colorScheme;
    final top = index == 0;
    final bottom = index == total - 1;
    final radius = Radius.circular(AppDesignTokens.radiusCard);
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.vertical(
          top: top ? radius : Radius.zero,
          bottom: bottom ? radius : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '${entry.rank}',
              style: AppTheme.number(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: entry.rank <= 3 ? scheme.primary : scheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  _shortRecordDate(entry.recordDate),
                  style:
                      TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score}',
                style: AppTheme.number(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              Text(
                'DX ${entry.subScore}',
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      context.l10n.kopSource,
      style: TextStyle(fontSize: 11, height: 1.4, color: scheme.onSurfaceVariant),
    );
  }
}
