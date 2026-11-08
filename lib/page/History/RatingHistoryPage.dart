import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../service/AccountStore.dart';
import '../../service/History/AwmcNetTrendService.dart';
import '../../service/History/ChartHistoryCore.dart';
import '../../service/History/ChartHistoryStore.dart';
import '../../service/SongInfoService.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CommonWidgetUtil.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/ScoreInputValidator.dart';
import '../../utils/UserProfileNotifier.dart';
import '../../widgets/HistoryLineChart.dart';
import '../../widgets/HistoryPointDelete.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/AppHeader.dart';
import '../../widgets/HistoryDateTimeDialog.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';

/// Rating 历史曲线。
///
/// 数据来自本机采集（`ChartHistoryStore`），也支持手动补录；时间精确到秒。
///
/// ⚠️ 一个必须说清楚的事实：**没有任何公开接口能回填历史**。
/// 水鱼/落雪只给"当前成绩"，所以这条曲线只能从「开始记录」那天算起 ——
/// 页面上要如实写明首次记录时间，别让用户以为数据丢了。
class RatingHistoryPage extends StatefulWidget {
  const RatingHistoryPage({super.key});

  @override
  State<RatingHistoryPage> createState() => _RatingHistoryPageState();
}

class _ManualRatingInput {
  const _ManualRatingInput({
    required this.rating,
    required this.best35,
    required this.best15,
    required this.tMs,
  });

  final int rating;
  final int best35;
  final int best15;
  final int tMs;
}

class _RatingHistoryPageState extends State<RatingHistoryPage> {
  /// 0 = 全部。
  int _rangeDays = 90;

  int _loadGeneration = 0;
  bool _loading = true;
  List<RatingPoint> _all = const [];
  ChartHistorySummary? _summary;

  /// 从 AWMC NET 拉趋势的进行中标志。用来锁按钮、避免重复点击。
  bool _awmcSyncing = false;

  /// 当前理论 Rating / B35 / B15：手动录入的**上限**（不得超过）。
  ///
  /// 存档在页面 State 上、随 [_load] 刷新：算一次要遍历整个曲库，
  /// 不能每开一次弹窗都算。拿不到歌曲缓存时是 [unknownRatingLimits]（三档全 0），
  /// 此时弹窗退化成只校验硬上限。
  RatingLimits _limits = unknownRatingLimits;

  @override
  void initState() {
    super.initState();
    CurrentDataSourceNotifier.instance.addListener(_onSourceChanged);
    UserProfileNotifier.instance.addListener(_onSourceChanged);
    _load();
  }

  @override
  void dispose() {
    CurrentDataSourceNotifier.instance.removeListener(_onSourceChanged);
    UserProfileNotifier.instance.removeListener(_onSourceChanged);
    super.dispose();
  }

  void _onSourceChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    setState(() {
      _loading = true;
      _all = const [];
      _summary = null;
    });
    try {
      final sourceKey = await ChartHistoryStore.storageKey();
      final series =
          await ChartHistoryStore.instance.ratingSeries(sourceKey: sourceKey);
      final summary =
          await ChartHistoryStore.instance.summary(sourceKey: sourceKey);
      final limits = await _loadLimits();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _all = series;
        _summary = summary;
        _limits = limits;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[RatingHistory] 读取失败: $e');
      if (!mounted || generation != _loadGeneration) return;
      setState(() => _loading = false);
    }
  }

  /// 理论 Rating 三件套（全谱面 SSS+ 时的 B35 / B15 / 总和）。
  ///
  /// 单独兜一层异常：这条曲线跟理论值没有依赖关系，理论值读失败也**不能**
  /// 把整个页面拖进"读取失败"分支。
  Future<RatingLimits> _loadLimits() async {
    try {
      return await SongInfoService.getTheoreticalRatingParts();
    } catch (e) {
      debugPrint('[RatingHistory] 读取理论 Rating 失败（忽略）: $e');
      return unknownRatingLimits;
    }
  }

  Future<void> _addManualPoint() async {
    // 输入框的 controller 由弹窗自己持有（见 [_ManualRatingDialog]），
    // 这里**不要**去碰它们 —— 在 pop 那一刻就 dispose 会把弹窗的退场动画炸掉。
    final input = await showDialog<_ManualRatingInput>(
      context: context,
      builder: (_) => _ManualRatingDialog(limits: _limits),
    );
    if (!mounted || input == null) return;
    try {
      final sourceKey = await ChartHistoryStore.storageKey();
      await ChartHistoryStore.instance.recordManualRating(
        rating: input.rating,
        best35: input.best35,
        best15: input.best15,
        tMs: input.tMs,
        sourceKey: sourceKey,
      );
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        AppToast.show(context.l10n.flowCouldNotSaveHistoryP0((e).toString()),
            tone: AppToastTone.error);
      }
    }
  }

  /// 删掉一个记录点（按整秒匹配，自动采集与手动补录都删）。
  ///
  /// 先弹确认框：历史是删了就回不来的数据，误点一下少一个点太亏。
  Future<void> _deletePoint(RatingPoint point) async {
    final confirmed = await confirmDeleteHistoryPoint(
      context,
      pointLabel: '${_formatDate(point.tMs)}　Rating ${point.rating}'
          '${point.best35 > 0 ? '\nB35 ${point.best35} / B15 ${point.best15}' : ''}',
    );
    if (!mounted || !confirmed) return;
    try {
      final sourceKey = await ChartHistoryStore.storageKey();
      await ChartHistoryStore.instance
          .deleteRatingPoint(tMs: point.tMs, sourceKey: sourceKey);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) {
        AppToast.show(
            context.l10n.flowCouldNotDeleteDataPointP0((e).toString()),
            tone: AppToastTone.error);
      }
    }
  }

  /// 「从 AWMC NET 同步 Rating 趋势」按钮回调。
  ///
  /// 只在 [RefreshDataSource.awmc] 数据源下出现（其他源没有 AWMC NET 账号 → 没意义）。
  /// 流程：取该源的 QQ → 拉 `/api/player/{qq}/trend` → 用
  /// [ChartHistoryStore.recordRatingSeries] 批量并入 → 重新加载页面。
  ///
  /// ⚠️ **批量写入会按整秒压扁「连续同 rating」尾巴** —— 与单点 [recordRating] 的
  /// 行为不同；详见 `recordRatingSeries` 注释。回填完后如果曲线尾巴出现意外变化，
  /// 不要奇怪，那本来就是预期行为。
  Future<void> _syncFromAwmcNet() async {
    if (_awmcSyncing) return;
    if (CurrentDataSourceNotifier.instance.value != RefreshDataSource.awmc)
      return;

    // QQ 必须从**当前源**的账号存档拿，不能用活动槽里的 cachedQQ（详见
    // RefreshDataDialog._fetchCurrentAwmcNetQQ 注释）
    final metas = await AccountStore.loadAll();
    final awmcQQ = metas[RefreshDataSource.awmc.key]?.id ?? '';
    if (awmcQQ.isEmpty) {
      if (mounted) {
        AppToast.show(context.l10n.flowLinkYourQQThroughSyncScoresTo,
            tone: AppToastTone.warning);
      }
      return;
    }

    setState(() => _awmcSyncing = true);
    try {
      // 默认拉 90 天：与 [_rangeDays] 默认值一致；用户切到「近 30 天 / 全部」再点的话，
      // 不会把存量数据删掉（回填是**增量合并**，不是覆盖），所以拉窗口拉大点反而
      // 把背景画得长一点。
      final result = await fetchAwmcNetTrend(qqid: awmcQQ, days: 90);
      if (!mounted) return;

      if (result.points.isEmpty) {
        AppToast.show(
            context.l10n.flowNoRatingRecordsForQQP0On((awmcQQ).toString()),
            tone: AppToastTone.warning);
        return;
      }

      // 接口端的 `rating` 已经按 B35+B15 算好，直接存进 [RatingPoint]。
      // B35 / B15 / recordCount 三个字段接口不给，留 0（手动补录时仍可填）。
      final newPoints = result.points
          .map((p) => RatingPoint(
                tMs: p.tMs,
                rating: p.rating,
                best35: 0,
                best15: 0,
                recordCount: p.recordCount,
              ))
          .toList(growable: false);

      final sourceKey = await ChartHistoryStore.storageKey();
      final added = await ChartHistoryStore.instance.recordRatingSeries(
        newPoints: newPoints,
        sourceKey: sourceKey,
      );
      if (!mounted) return;

      await _load();
      if (!mounted) return;
      AppToast.show(
          added > 0
              ? context.l10n
                  .flowSyncedRatingHistoryFromAWMCNETAdded((added).toString())
              : context.l10n.flowNoNewAWMCNETPointsP0Already(
                  (result.points.length).toString()),
          tone: AppToastTone.success);
    } on AwmcNetTrendException catch (e) {
      if (mounted) {
        AppToast.show(context.l10n.flowSyncFailedP0((e.message).toString()),
            tone: AppToastTone.error);
      }
    } catch (e) {
      debugPrint('[RatingHistory] 从 AWMC NET 同步趋势失败：$e');
      if (mounted) {
        AppToast.show(context.l10n.flowSyncFailedP0((e).toString()),
            tone: AppToastTone.error);
      }
    } finally {
      if (mounted) {
        setState(() => _awmcSyncing = false);
      }
    }
  }

  /// 按时间范围裁剪（0 = 全部）。
  List<RatingPoint> get _visible {
    if (_rangeDays <= 0 || _all.isEmpty) return _all;
    final cutoff = DateTime.now()
        .subtract(Duration(days: _rangeDays))
        .millisecondsSinceEpoch;
    final filtered = _all.where((p) => p.tMs >= cutoff).toList(growable: false);
    // 范围里只剩一个点时，把范围前最后一个点也带上，曲线才有起点可比
    if (filtered.length == 1) {
      final idx = _all.indexOf(filtered.first);
      if (idx > 0) return [_all[idx - 1], filtered.first];
    }
    return filtered.isEmpty ? _all.sublist(_all.length - 1) : filtered;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final showAwmcSync =
        CurrentDataSourceNotifier.instance.value == RefreshDataSource.awmc;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          CommonWidgetUtil.buildCommonBgWidget(),
          CommonWidgetUtil.buildCommonChiffonBgWidget(context),
          Column(
            children: [
              AppHeader(
                title: context.l10n.featureRatingHistory,
                actions: [
                  // 仅 AWMC NET 数据源出现：拉取该 QQ 的 Rating 趋势并并入本地缓存。
                  if (showAwmcSync)
                    IconButton(
                      tooltip: context.l10n.flowSyncRatingHistoryFromAWMCNET,
                      icon: _awmcSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_sync_outlined),
                      onPressed: _awmcSyncing ? null : _syncFromAwmcNet,
                    ),
                  IconButton(
                    tooltip: context.l10n.flowAddHistoryRecord,
                    icon: const Icon(Icons.add_chart_outlined),
                    onPressed: _addManualPoint,
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppDesignTokens.gutter,
                    4,
                    AppDesignTokens.gutter,
                    AppDesignTokens.gutter +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  child: _loading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_all.isEmpty)
                              _buildEmpty(brightness)
                            else ...[
                              _buildOverviewCard(brightness),
                              const SizedBox(height: AppDesignTokens.cardGap),
                              _buildChartCard(brightness),
                              const SizedBox(height: AppDesignTokens.cardGap),
                              _buildPointList(brightness),
                            ],
                            const SizedBox(height: AppDesignTokens.cardGap),
                            _buildRecordNote(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 如实说明记录范围：曲线只能从首次记录那天算起，别让用户以为数据丢了。
  Widget _buildRecordNote() {
    final scheme = Theme.of(context).colorScheme;
    final source = CurrentDataSourceNotifier.instance.value;
    final summary = _summary;
    final style =
        TextStyle(fontSize: 12, height: 1.45, color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.flowCurrentSourceP0(
                (context.featureText(source.displayName)).toString()),
            style: style.copyWith(
                fontWeight: FontWeight.w700, color: scheme.onSurface),
          ),
          const SizedBox(height: 2),
          if (summary != null && summary.chartCount > 0)
            Text(
              context.l10n.flowBaselinesForP0ChartsP1ScoreChanges(
                  (summary.chartCount).toString(),
                  (summary.eventCount).toString()),
              style: style,
            ),
          Text(
            // 文案根据数据源动态化：AWMC 有趋势接口，可以回填；其他源只能从今天起攒。
            source == RefreshDataSource.awmc
                ? context.l10n.flowDivingFishLXNSAWMCNETHistoryIs(
                    (summary?.firstRecordedText ?? '').toString())
                : context.l10n.flowDivingFishLXNSAWMCNETHistoryIs2(
                    (summary?.firstRecordedText ?? '').toString()),
            style: style,
          ),
        ],
      ),
    );
  }

  /// 当前 Rating、所选范围内的变化、时间范围和最高值。
  Widget _buildOverviewCard(Brightness brightness) {
    const ranges = [30, 90, 0];
    final labels = [
      context.l10n.flowLast30Days,
      context.l10n.flowLast90Days,
      context.l10n.flowAll
    ];
    final scheme = Theme.of(context).colorScheme;
    final visible = _visible;
    final current = visible.last;
    final best = visible.reduce((a, b) => a.rating >= b.rating ? a : b);
    final delta =
        visible.length >= 2 ? visible.last.rating - visible.first.rating : 0;
    final deltaColor = delta > 0
        ? AppColors.successGreen(brightness)
        : (delta < 0
            ? AppColors.errorRed(brightness)
            : scheme.onSurfaceVariant);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.flowCurrent,
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${current.rating}',
                    maxLines: 1,
                    style: AppTheme.number(
                      fontSize: 40,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.14),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusPill),
                ),
                child: Text(
                  '${delta >= 0 ? '+' : ''}$delta',
                  style: AppTheme.number(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: deltaColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedTabs(
            height: 38,
            items: [for (final label in labels) SegmentedTabItem(label)],
            selectedIndex: ranges.indexOf(_rangeDays),
            onChanged: (index) => setState(() => _rangeDays = ranges[index]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  centered: true,
                  label: context.l10n.flowHighest,
                  value: '${best.rating}',
                ),
              ),
              Expanded(
                child: StatTile(
                  centered: true,
                  label: 'Best35',
                  value: current.best35 > 0 ? '${current.best35}' : '-',
                ),
              ),
              Expanded(
                child: StatTile(
                  centered: true,
                  label: 'Best15',
                  value: current.best15 > 0 ? '${current.best15}' : '-',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Brightness brightness) {
    final visible = _visible;

    final firstMs = visible.first.tMs;
    const dayMs = 24 * 3600 * 1000;
    // 只有一个点时**必须**退回"日"：三个刻度都落在同一个点上，
    // 秒级文案会互相压字并顶出画布。规则见 showSecondPrecisionAxis。
    final showTimeLabels =
        showSecondPrecisionAxis(firstMs, visible.last.tMs, visible.length);
    double x(RatingPoint p) => (p.tMs - firstMs) / dayMs;

    final ratings = visible.map((p) => p.rating).toList();
    final minR = ratings.reduce((a, b) => a < b ? a : b).toDouble();
    final maxR = ratings.reduce((a, b) => a > b ? a : b).toDouble();
    // 范围与刻度都对齐到整数档，避免轴上出现 16956 这种读数
    final axis = niceAxisRange(minR, maxR);

    final spots = [for (final p in visible) FlSpot(x(p), p.rating.toDouble())];
    final bestIdx = visible
        .indexWhere((p) => p.rating == ratings.reduce((a, b) => a > b ? a : b));

    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      child: HistoryLineChart(
        spots: spots,
        height: 220,
        minY: axis.min,
        maxY: axis.max,
        leftInterval: axis.interval,
        highlightIndex: bestIdx,
        interval: (x(visible.last) / 3).clamp(1, 9999),
        bottomLabel: (value) {
          // 只有一个点时横轴被撑成这个点前后各半天，左端会算出**没有数据的
          // 前一天**（9/1 的点 → 左端算出 8/31）。三个刻度统一标这个点自己的日期。
          if (visible.length == 1) return _formatDay(firstMs);
          final ms = firstMs + (value * dayMs).round();
          final d = DateTime.fromMillisecondsSinceEpoch(ms);
          String two(int v) => v.toString().padLeft(2, '0');
          return showTimeLabels
              ? '${d.month}/${d.day} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}'
              : _formatDay(ms);
        },
        tooltipLabel: (index) {
          final p = visible[index.clamp(0, visible.length - 1)];
          final d = DateTime.fromMillisecondsSinceEpoch(p.tMs);
          String two(int value) => value.toString().padLeft(2, '0');
          return '${d.year}/${two(d.month)}/${two(d.day)} '
              '${two(d.hour)}:${two(d.minute)}:${two(d.second)}\n'
              'Rating ${p.rating}'
              '${p.best35 > 0 ? '\nB35 ${p.best35} / B15 ${p.best15}' : ''}';
        },
      ),
    );
  }

  Widget _buildPointList(Brightness brightness) {
    final scheme = Theme.of(context).colorScheme;
    final visible = _visible.reversed.toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: context.l10n.flowDataPoints,
          subtitle: visible.length > 30
              ? context.l10n
                  .flowP0EntriesShowingTheLatest30((visible.length).toString())
              : context.l10n.flowP0Entries((visible.length).toString()),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (index, p) in visible.take(30).indexed)
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  decoration: BoxDecoration(
                    border: index == 0
                        ? null
                        : Border(
                            top: BorderSide(
                                color: AppSurfaces.hairline(context))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 系统字体放大时整段等比缩小，而不是换行或截断。
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatDate(p.tMs),
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 12.5, color: scheme.onSurface),
                              ),
                            ),
                            if (p.best35 > 0)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'B35 ${p.best35} / B15 ${p.best15}',
                                  maxLines: 1,
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: scheme.onSurfaceVariant),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${p.rating}',
                        maxLines: 1,
                        style: AppTheme.number(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      HistoryPointDeleteButton(
                        onPressed: () => _deletePoint(p),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(Brightness brightness) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.insights_rounded,
              size: 42, color: AppColors.greyHint(brightness)),
          const SizedBox(height: 12),
          Text(
            context.l10n.flowNoHistoryYet,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText(brightness)),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.flowEachDataRefreshRecordsAPointAutomatically,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5, color: AppColors.secondaryText(brightness)),
          ),
        ],
      ),
    );
  }

  static String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}/${two(d.month)}/${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  /// 横轴用的「月/日」（跨度到天以后就只标到这里）。
  static String _formatDay(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.month}/${d.day}';
  }
}

/// 「添加 Rating 历史」弹窗本体。
///
/// ⚠️ 三个 controller 必须由**弹窗自己的 [State]** 持有并释放，不要在调用方
/// `await showDialog(...)` 之后再 dispose：`showDialog` 的 future 是
/// `Route.popped`，pop 那一刻就完成，而弹窗还要走完**退场动画**才从 overlay
/// 移除 —— 退场期间（真机上键盘收起会让弹窗重建）`TextField` 会再读一次
/// controller，于是必现「A TextEditingController was used after being
/// disposed」，紧接着框架卸载到一半就崩成一串断言
/// （`'_dependents.isEmpty': is not true` /
/// 「Tried to build dirty widget in the wrong build scope」），表现就是**红屏**。
/// 回归测试：`test/rating_history_page_test.dart` 的「取消关闭」两例。
///
/// 合法值校验（口径与自定义 Best50 一致，见 [checkNumberInput]）：
///   * Rating ≤ **当前理论 Rating**（全谱面 SSS+ 的总和）；
///   * Best35 ≤ 当前理论 B35、Best15 ≤ 当前理论 B15 —— 只卡总和是不够的，
///     用户完全可以把 B35 填成 99999 而总和看着"还行"；
///   * 拿不到理论值（没有歌曲缓存）时退化成 [ratingHardMax] 兜底，不挡用户录入。
class _ManualRatingDialog extends StatefulWidget {
  const _ManualRatingDialog({required this.limits});

  /// 当前理论 Rating / B35 / B15；[unknownRatingLimits] = 拿不到。
  final RatingLimits limits;

  @override
  State<_ManualRatingDialog> createState() => _ManualRatingDialogState();
}

class _ManualRatingDialogState extends State<_ManualRatingDialog> {
  /// 拿不到理论值（没有歌曲缓存）时的上限提示：如实说明在按硬上限兜底。
  static String get _unknownLimitHint => appL10n
      .flowLimitP0TheoreticalValueUnavailable((ratingHardMax).toString());

  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _best35Controller = TextEditingController();
  final TextEditingController _best15Controller = TextEditingController();
  DateTime _selectedAt = DateTime.now();

  String? _ratingError;
  String? _best35Error;
  String? _best15Error;

  @override
  void dispose() {
    _ratingController.dispose();
    _best35Controller.dispose();
    _best15Controller.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _ratingController.text.trim().isNotEmpty &&
      _ratingError == null &&
      _best35Error == null &&
      _best15Error == null;

  /// 逐格校验，错误挂到对应的输入框上。
  ///
  /// ⚠️ **保存时也要再跑一次**：真实输入在 controller 里，只信 `onChanged`
  /// 存下来的值会出现"框里写着 100.55、存进去的是 100.5"。
  void _revalidate() {
    final limits = widget.limits;
    setState(() {
      _ratingError = checkNumberInput(
        _ratingController.text,
        hardMax: ratingHardMax,
        limit: limits.total,
        limitLabel: context.l10n.flowCurrentTheoreticalRating,
      ).error;
      _best35Error = checkNumberInput(
        _best35Controller.text,
        hardMax: ratingHardMax,
        limit: limits.best35,
        limitLabel: context.l10n.flowCurrentTheoreticalB35,
        allowZero: true,
      ).error;
      _best15Error = checkNumberInput(
        _best15Controller.text,
        hardMax: ratingHardMax,
        limit: limits.best15,
        limitLabel: context.l10n.flowCurrentTheoreticalB15,
        allowZero: true,
      ).error;
    });
  }

  Future<void> _pickDateTime() async {
    final picked = await showHistoryDateTimeDialog(
      context,
      initial: _selectedAt,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedAt = picked);
  }

  void _save() {
    _revalidate();
    if (!_canSave) return;
    // 先按 double 解再取整（与自定义 Best50 的 DX 输入同一处理）：
    // 校验是按 double 过的，这里再 `int.tryParse` 会把 "16353.6" 解析成 null，
    // 于是点保存什么都不发生 —— 用户只会觉得按钮坏了。
    final rating = double.tryParse(_ratingController.text.trim())?.round();
    final best35 = double.tryParse(_best35Controller.text.trim())?.round() ?? 0;
    final best15 = double.tryParse(_best15Controller.text.trim())?.round() ?? 0;
    if (rating == null || rating <= 0 || best35 < 0 || best15 < 0) return;
    Navigator.of(context).pop(_ManualRatingInput(
      rating: rating,
      best35: best35,
      best15: best15,
      tMs: _selectedAt.millisecondsSinceEpoch,
    ));
  }

  static String _formatDateTime(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${value.year}/${two(value.month)}/${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final limits = widget.limits;
    return AppAlertDialog(
      title: Text(context.l10n.flowAddRatingHistory),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ratingController,
              autofocus: true,
              keyboardType: TextInputType.number,
              onChanged: (_) => _revalidate(),
              decoration: InputDecoration(
                labelText: 'Rating',
                helperText: limitHelperText(limits.total,
                        context.l10n.flowCurrentTheoreticalRating) ??
                    _unknownLimitHint,
                helperMaxLines: 3,
                helperStyle: const TextStyle(fontSize: 11),
                errorText: _ratingError,
                errorMaxLines: 3,
                errorStyle: const TextStyle(fontSize: 11),
              ).insetLabel(context),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _best35Controller,
              keyboardType: TextInputType.number,
              onChanged: (_) => _revalidate(),
              decoration: InputDecoration(
                labelText: context.l10n.flowBest35Optional,
                helperText: limitHelperText(limits.best35,
                        context.l10n.flowCurrentTheoreticalB35) ??
                    _unknownLimitHint,
                helperMaxLines: 3,
                helperStyle: const TextStyle(fontSize: 11),
                errorText: _best35Error,
                errorMaxLines: 3,
                errorStyle: const TextStyle(fontSize: 11),
              ).insetLabel(context),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _best15Controller,
              keyboardType: TextInputType.number,
              onChanged: (_) => _revalidate(),
              decoration: InputDecoration(
                labelText: context.l10n.flowBest15Optional,
                helperText: limitHelperText(limits.best15,
                        context.l10n.flowCurrentTheoreticalB15) ??
                    _unknownLimitHint,
                helperMaxLines: 3,
                helperStyle: const TextStyle(fontSize: 11),
                errorText: _best15Error,
                errorMaxLines: 3,
                errorStyle: const TextStyle(fontSize: 11),
              ).insetLabel(context),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.event_outlined),
                label: Text(_formatDateTime(_selectedAt)),
                onPressed: _pickDateTime,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
        FilledButton(
          // 空值 / 非法值都不给点：弹窗里没有别的提示位，最省事的是按钮直接灰掉
          onPressed: _canSave ? _save : null,
          child: Text(context.l10n.save),
        ),
      ],
    );
  }
}
