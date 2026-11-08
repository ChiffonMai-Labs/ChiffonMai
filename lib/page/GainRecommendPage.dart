import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../service/GainRecommend/GainFeedbackStore.dart';
import '../service/GainRecommend/GainRecommendCore.dart';
import '../service/GainRecommend/GainRecommendService.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';
import '../utils/StringUtil.dart';
import '../widgets/BackgroundPageScaffold.dart';
import 'SongInfoPage.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUi.dart';

/// 吃分推荐：按「仅这一张谱达标后 B50 涨多少」挑谱。算法由 AWMC 提供。
///
/// 会话语义（沿用 AWMC 方案）：
/// - 换一批：本页谱面记入「已见」，下一批只出未见候选，直到耗尽；
/// - 本次跳过：只在本次打开页面期间生效；
/// - 不喜欢 / 暂时卡住（14 天）：落盘，跨路线硬排除，可在反馈管理里撤销；
/// - 重新开始：清空已见与本次跳过，保留长期反馈。
class GainRecommendPage extends StatefulWidget {
  const GainRecommendPage({super.key});

  @override
  State<GainRecommendPage> createState() => _GainRecommendPageState();
}

/// null = 混合页（三路线软配额）。
typedef _RouteFilter = GainRoute?;

class _GainRecommendPageState extends State<GainRecommendPage> {
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  String? _error;
  GainRecommendSnapshot? _snapshot;

  _RouteFilter _route;
  final Set<GainChartKey> _seen = {};
  final Set<GainChartKey> _skipped = {};
  final Set<GainChartKey> _shown = {};
  Set<GainChartKey> _feedbackExcluded = {};
  GainPage? _page;
  int _batch = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await GainRecommendService.load();
      final excluded = await GainFeedbackStore.instance.excludedKeys();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _feedbackExcluded = excluded;
        _loading = false;
        _selectPage();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is GainRecommendLoadException ? e.message : appL10n.flowCouldNotGenerateRecommendationsP0((e).toString());
      });
    }
  }

  void _selectPage() {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    final route = _route;
    final sorted = route == null
        ? snapshot.sorted
        : {route: snapshot.sorted[route] ?? const <GainCandidate>[]};
    _page = selectGainPage(
      sorted,
      excluded: {..._seen, ..._skipped, ..._feedbackExcluded},
    );
    _shown.addAll(_page!.items.map((c) => c.key));
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _nextBatch() {
    final page = _page;
    if (page == null) return;
    setState(() {
      _seen.addAll(page.items.map((c) => c.key));
      _batch++;
      _selectPage();
    });
    _scrollToTop();
  }

  void _restart() {
    setState(() {
      _seen.clear();
      _skipped.clear();
      _shown.clear();
      _batch = 1;
      _selectPage();
    });
    _scrollToTop();
  }

  void _switchRoute(_RouteFilter route) {
    if (route == _route) return;
    setState(() {
      _route = route;
      _selectPage();
    });
    _scrollToTop();
  }

  /// 反馈只把这张卡从本页拿掉，不自动补位，避免「点一下换了半页」。
  void _removeFromPage(GainChartKey key) {
    final page = _page;
    if (page == null) return;
    _page = GainPage(
      page.items.where((c) => c.key != key).toList(),
      page.partialCount,
      page.remaining,
    );
  }

  Future<void> _onFeedback(GainCandidate c, String action) async {
    final label = '${c.title} [${c.level}]';
    if (action == 'skip') {
      setState(() {
        _skipped.add(c.key);
        _removeFromPage(c.key);
      });
      AppToast.show(context.l10n.flowSkippedP0ForThisSession((label).toString()), tone: AppToastTone.success);
      return;
    }
    final kind =
        action == 'dislike' ? GainFeedbackKind.dislike : GainFeedbackKind.stuck;
    try {
      await GainFeedbackStore.instance
          .record(c.key, kind, title: c.title, level: c.level);
    } catch (e) {
      AppToast.show(context.l10n.flowCouldNotSaveFeedbackP0((e).toString()), tone: AppToastTone.error);
      return;
    }
    if (!mounted) return;
    setState(() {
      _feedbackExcluded = {..._feedbackExcluded, c.key};
      _removeFromPage(c.key);
    });
    AppToast.show(kind == GainFeedbackKind.dislike
          ? context.l10n.flowStoppedRecommendingP0UndoInFeedbackManagement((label).toString())
          : context.l10n.flowPausedRecommendationsForP0For14Days((label).toString()), actionLabel: context.l10n.flowUndo, onAction: () => _undoFeedback(c.key));
  }

  /// 撤销后谱面不会自动插回当前批，下一次换批 / 重新开始时才可能再出现。
  Future<void> _undoFeedback(GainChartKey key) async {
    await GainFeedbackStore.instance.undo(key);
    final excluded = await GainFeedbackStore.instance.excludedKeys();
    if (!mounted) return;
    setState(() {
      _feedbackExcluded = excluded;
      // 本次已展示过的谱记入已见，保持「撤销不重插当前批」。
      if (_shown.contains(key)) _seen.add(key);
    });
  }

  Future<void> _openFeedbackManager() async {
    final records = await GainFeedbackStore.instance.list();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _FeedbackSheet(
        initial: records,
        onUndo: _undoFeedback,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.featureRatingGainRecommendations,
      actions: [
        IconButton(
          tooltip: context.l10n.flowManageFeedback,
          icon: const Icon(Icons.rule_rounded),
          onPressed: _openFeedbackManager,
        ),
      ],
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _error;
    if (error != null) {
      return _CenteredMessage(
        message: error,
        actionLabel: context.l10n.flowRetry,
        onAction: _load,
      );
    }
    final snapshot = _snapshot!;
    final page = _page!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
                AppDesignTokens.gutter, AppDesignTokens.gutter),
            children: [
              EntranceAnimation(child: _SummaryCard(snapshot: snapshot)),
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildRouteSelector(context, snapshot),
              const SizedBox(height: AppDesignTokens.cardGap),
              if (page.items.isEmpty)
                _CenteredMessage(
                  message: _route == null && snapshot.result.candidates.isEmpty
                      ? context.l10n.flowNoChartsCanDirectlyRaiseYourRating
                      : context.l10n.flowNoUnseenCandidatesMatchStartOverOr,
                  actionLabel: context.l10n.flowStartOver,
                  onAction: _restart,
                )
              else ...[
                _buildPageHeader(context, snapshot, page),
                for (final (index, c) in page.items.indexed)
                  EntranceAnimation(
                    // 换批或换路线时重播
                    key: ValueKey('$_batch-$_route-${c.songId}-${c.levelIndex}'),
                    index: index,
                    offset: const Offset(0, 10),
                    duration: const Duration(milliseconds: 340),
                    child: _CandidateCard(
                      candidate: c,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongInfoPage(
                            songId: c.songId.toString(),
                            initialLevelIndex: c.levelIndex,
                          ),
                        ),
                      ),
                      onFeedback: (action) => _onFeedback(c, action),
                    ),
                  ),
                if (page.partialCount != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      page.remaining == 0
                          ? context.l10n.gainFillNoteExhausted(
                              page.partialCount.toString())
                          : context.l10n.gainFillNoteFiltered(
                              page.partialCount.toString()),
                      textAlign: TextAlign.center,
                      style: _hintStyle(context),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              const _Disclaimer(),
            ],
          ),
        ),
        _buildBottomBar(context, page),
      ],
    );
  }

  Widget _buildRouteSelector(
      BuildContext context, GainRecommendSnapshot snapshot) {
    final result = snapshot.result;
    final options = <(_RouteFilter, String)>[
      (null, context.l10n.flowMixed),
      for (final route in GainRoute.values)
        (route, '${_routeLabel(context, route)} ${result.count(route)}'),
    ];
    return PillTabs(
      items: [for (final (_, label) in options) SegmentedTabItem(label)],
      selectedIndex: options.indexWhere((option) => option.$1 == _route),
      onChanged: (index) {
        // 再点当前选项不重新加载
        if (options[index].$1 != _route) _switchRoute(options[index].$1);
      },
    );
  }

  Widget _buildPageHeader(
      BuildContext context, GainRecommendSnapshot snapshot, GainPage page) {
    final combined = combinedGainOfPage(snapshot.result.records, page.items);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (combined != null && combined > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Row(
                children: [
                  Text(
                    '+$combined',
                    style: AppTheme.number(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.flowTotalGainIfAllTargetsOnThis,
                      style: TextStyle(fontSize: 12, color: scheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            context.l10n.flowBatchP0P1EntriesEachGainIs((_batch).toString(), (page.items.length).toString()),
            style: _hintStyle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, GainPage page) {
    return BottomActionBar(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
            label:  Text(context.l10n.flowStartOver),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed:
                page.items.isEmpty || page.remaining == 0 ? null : _nextBatch,
            icon: const Icon(Icons.autorenew_rounded),
            label: Text(page.remaining == 0 ? context.l10n.flowNoMore : context.l10n.flowAnotherBatch),
          ),
        ),
      ],
    );
  }
}

TextStyle _hintStyle(BuildContext context) => TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

Color _routeColor(GainRoute route, Brightness brightness) => switch (route) {
      GainRoute.stable => AppColors.successGreen(brightness),
      GainRoute.challenge => AppColors.warningOrange(brightness),
      GainRoute.explore => AppColors.linkBlue(brightness),
    };

class _SummaryCard extends StatelessWidget {
  final GainRecommendSnapshot snapshot;
  const _SummaryCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final baseline = snapshot.result.baseline;
    final scheme = Theme.of(context).colorScheme;
    final b35Sum = baseline.b35.fold<int>(0, (s, r) => s + r.ra);
    final b15Sum = baseline.b15.fold<int>(0, (s, r) => s + r.ra);
    final notes = <String>[
      if (snapshot.sourceRating > 0 && snapshot.sourceRating != baseline.raSum)
        context.l10n.flowSourceRatingP0DiffersFromTheLocally((snapshot.sourceRating).toString()),
      if (snapshot.unmatchedRecords > 0)
        context.l10n.flowP0ScoresAreMissingFromTheSong((snapshot.unmatchedRecords).toString()),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.flowCurrentB50, style: _hintStyle(context)),
          RollingNumber(
            value: baseline.raSum,
            style: AppTheme.number(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  card: true,
                  label: context.l10n.flowB35CutoffP0((baseline.floor(false)).toString()),
                  value: '$b35Sum',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  card: true,
                  label: context.l10n.flowB15CutoffP0((baseline.floor(true)).toString()),
                  value: '$b15Sum',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.flowCountedB35P0P1B15P2P3((baseline.b35.length).toString(), (gainB35Size).toString(), (baseline.b15.length).toString(), (gainB15Size).toString()),
            style: _hintStyle(context),
          ),
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.warningOrange(Theme.of(context).brightness),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final GainCandidate candidate;
  final VoidCallback onTap;
  final ValueChanged<String> onFeedback;

  const _CandidateCard({
    required this.candidate,
    required this.onTap,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final routeColor = _routeColor(c.route, brightness);
    final achv = c.achievements;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
      child: AppCard(
        radius: AppDesignTokens.radiusMedium,
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                  child: CoverUtil.buildCoverWidget(c.songId.toString(), 56),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _Tag(text: _routeLabel(context, c.route), color: routeColor),
                          _Tag(
                            text:
                                '${StringUtil.formatSongType(c.type)} ${c.ds.toStringAsFixed(1)}',
                            color: AppColors.difficultyForegroundByIndex(
                                c.levelIndex,
                                brightness: brightness),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${c.netGain}',
                      style: AppTheme.number(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: routeColor,
                      ),
                    ),
                    Text(context.l10n.flowNetGain, style: _hintStyle(context)),
                  ],
                ),
                PopupMenuButton<String>(
                  tooltip: context.l10n.flowFeedback,
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.more_vert_rounded,
                      size: 20, color: scheme.onSurfaceVariant),
                  onSelected: onFeedback,
                  itemBuilder: (_) =>  [
                    PopupMenuItem(value: 'skip', child: Text(context.l10n.flowSkipThisTime)),
                    PopupMenuItem(value: 'stuck', child: Text(context.l10n.flowTemporarilyStuck14Days)),
                    PopupMenuItem(value: 'dislike', child: Text(context.l10n.flowDislikeThisChart)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      achv == null
                          ? context.l10n.flowNoScoreRecordedReferenceTargetP0((c.target.toStringAsFixed(4)).toString())
                          : context.l10n.flowP0P1GainP2((achv.toStringAsFixed(4)).toString(), (c.target.toStringAsFixed(4)).toString(), (c.need.toStringAsFixed(4)).toString()),
                      maxLines: 1,
                      style: AppTheme.number(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(_reasonText(context, c), style: _hintStyle(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      text: text,
      background: color.withValues(alpha: 0.12),
      foreground: color,
      fontSize: 11,
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final style = _hintStyle(context);
    return Column(
      children: [
        Text(
          context.l10n.flowSteadyTargetImprovement020Challenge0,
          textAlign: TextAlign.center,
          style: style,
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.flowRatingGainRecommendationsPoweredByAWMC,
          textAlign: TextAlign.center,
          style: style.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _CenteredMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.greyHint(Theme.of(context).brightness),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  final List<GainFeedbackRecord> initial;
  final Future<void> Function(GainChartKey key) onUndo;

  const _FeedbackSheet({required this.initial, required this.onUndo});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  late List<GainFeedbackRecord> _records = widget.initial;

  @override
  Widget build(BuildContext context) {
    final style = _hintStyle(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.flowManageFeedback,
                style: Theme.of(context).textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(context.l10n.flowUndoingDoesNotInsertChartsBackInto,
                  textAlign: TextAlign.center, style: style),
            ),
            if (_records.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(context.l10n.flowNoFeedbackYet, style: style),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in _records)
                      ListTile(
                        title: Text('${r.title} [${r.level}]',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(r.kind == GainFeedbackKind.dislike
                            ? context.l10n.flowDislikedUntilUndone
                            : context.l10n.flowTemporarilyStuckClearsAutomaticallyOnP0((_formatDate(r.expiresAt!)).toString())),
                        trailing: TextButton(
                          onPressed: () async {
                            await widget.onUndo(r.key);
                            if (!mounted) return;
                            setState(() {
                              _records =
                                  _records.where((e) => e.key != r.key).toList();
                            });
                          },
                          child:  Text(context.l10n.flowUndo),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      appL10n.flowP0P12((d.month).toString(), (d.day).toString());
}

/// 推荐路线的显示名；枚举本身不带译文。
String _routeLabel(BuildContext context, GainRoute route) => switch (route) {
      GainRoute.stable => context.l10n.gainRouteStable,
      GainRoute.challenge => context.l10n.gainRouteChallenge,
      GainRoute.explore => context.l10n.gainRouteExplore,
    };

/// 推分理由：核心只给数据，这里按当前语言拼句。
String _reasonText(BuildContext context, GainCandidate c) {
  final l10n = context.l10n;
  final basis = c.basis;
  if (basis == null) {
    return l10n.gainExploreReason(
        c.target.toStringAsFixed(4), c.netGain.toString());
  }
  final grade = basis.targetGrade ?? l10n.gainBelowS;
  final gradeText =
      basis.raisesGrade ? l10n.gainRaiseTo(grade) : l10n.gainWithinGrade(grade);
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
