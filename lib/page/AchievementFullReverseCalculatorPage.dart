import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/AppDialogs.dart';

/// 达成率反推：已知各档判定数量与总达成率，反推 BREAK 的 50落 / 100落 与
/// GREAT 的 80% / 60% / 50% 细分。
///
/// 2026-11 重构：输入改成「音符类型分段 + 计数行」，结果从一段纯文本改成
/// 结构化卡片。**搜索算法与旧版逐行一致**（见 [_search]）。
class AchievementFullReverseCalculator extends StatefulWidget {
  const AchievementFullReverseCalculator({super.key});

  @override
  State<AchievementFullReverseCalculator> createState() =>
      _AchievementFullReverseCalculatorState();
}

class _AchievementFullReverseCalculatorState
    extends State<AchievementFullReverseCalculator> {
  final GlobalKey<_AchievementReversePanelState> _panelKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.featureReverseAchievementCalculator,
      resizeToAvoidBottomInset: true,
      actions: [
        IconButton(
          tooltip: context.l10n.flowReset,
          onPressed: () => _panelKey.currentState?.reset(),
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
              AppDesignTokens.gutter, 24 + MediaQuery.paddingOf(context).bottom),
          children: [AchievementReversePanel(key: _panelKey)],
        ),
      ),
    );
  }
}

/// 反推的输入与结果，没有自己的滚动和页面外壳：
/// 独立页面和计算工具页（从歌曲详情进入）共用，放进外层的滚动列里即可。
class AchievementReversePanel extends StatefulWidget {
  /// 区块标题；给了就显示标题和重置键（独立页面的重置键在顶部栏）。
  final String? title;

  /// 五种音符的总数，默认全部算作 CRITICAL PERFECT。
  final List<int>? initialCounts;

  final String? initialRate;

  const AchievementReversePanel({
    super.key,
    this.title,
    this.initialCounts,
    this.initialRate,
  });

  @override
  State<AchievementReversePanel> createState() =>
      _AchievementReversePanelState();
}

class _ReverseResult {
  final bool found;
  final double target;
  final int p75;
  final int p50;
  final int g80;
  final int g60;
  final int g50;
  final double base;
  final double extra;
  final double total;
  final double error;

  const _ReverseResult({
    required this.found,
    required this.target,
    required this.p75,
    required this.p50,
    required this.g80,
    required this.g60,
    required this.g50,
    required this.base,
    required this.extra,
    required this.total,
    required this.error,
  });
}

class _AchievementReversePanelState extends State<AchievementReversePanel> {
  static const List<String> _types = ['TAP', 'HOLD', 'SLIDE', 'TOUCH', 'BREAK'];

  // 定义权重常量（与旧版一致）
  static const int TAP_WEIGHT = 1;
  static const int HOLD_WEIGHT = 2;
  static const int SLIDE_WEIGHT = 3;
  static const int TOUCH_WEIGHT = 1;
  static const int BREAK_WEIGHT = 5;

  static const List<(String, Color)> _judges = [
    ('CRITICAL PERFECT', AppColors.judgeCriticalPerfect),
    ('PERFECT', AppColors.judgePerfect),
    ('GREAT', AppColors.judgeGreat),
    ('GOOD', AppColors.judgeGood),
    ('MISS', AppColors.judgeMiss),
  ];

  /// 每种音符的 [CP, P, GREAT, GOOD, MISS]。
  final Map<String, List<int>> _counts = {
    for (final t in _types) t: List<int>.filled(5, 0),
  };

  final TextEditingController _rateController = TextEditingController();
  final GlobalKey _resultKey = GlobalKey();

  int _tab = 0;
  bool _calculating = false;
  _ReverseResult? _result;

  @override
  void initState() {
    super.initState();
    _fillInitial();
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  void _fillInitial() {
    for (final (i, type) in _types.indexed) {
      final list = _counts[type]!;
      list.fillRange(0, list.length, 0);
      list[0] = widget.initialCounts?[i] ?? 0;
    }
    _rateController.text = widget.initialRate ?? '';
  }

  int _sum(String type) => _counts[type]!.fold(0, (s, n) => s + n);

  void _setCount(String type, int index, int value) {
    if (_counts[type]![index] == value) return;
    setState(() {
      _counts[type]![index] = value;
      _result = null;
    });
  }

  void reset() {
    if (_calculating) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _fillInitial();
      _result = null;
      _calculating = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AppAlertDialog(
        title:  Text(context.l10n.flowInputError),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text(context.l10n.featureOK),
          ),
        ],
      ),
    );
  }

  Future<void> _calculateFullReverse() async {
    FocusScope.of(context).unfocus();
    final input = _rateController.text;
    if (input.isEmpty) {
      _showErrorDialog(context.l10n.flowEnterTargetAchievement);
      return;
    }
    final targetRate = double.tryParse(input);
    if (targetRate == null) {
      _showErrorDialog(context.l10n.flowInvalidAchievementEnterANumberSuchAs);
      return;
    }
    if (targetRate < 0 || targetRate > 101) {
      _showErrorDialog(context.l10n.flowEnterAchievementBetween0And101);
      return;
    }

    setState(() {
      _calculating = true;
      _result = null;
    });
    // 让出一帧，按钮先显示「计算中」再开始遍历
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    final result = _search(targetRate);
    setState(() {
      _calculating = false;
      _result = result;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resultContext = _resultKey.currentContext;
      if (!mounted || resultContext == null) return;
      Scrollable.ensureVisible(
        resultContext,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
        curve: AppDesignTokens.emphasizedCurve,
      );
    });
  }

  /// 核心计算逻辑（移植自旧版 Java 代码，算法不变）。
  _ReverseResult _search(double targetRate) {
    final tap = _counts['TAP']!;
    final hold = _counts['HOLD']!;
    final slide = _counts['SLIDE']!;
    final touch = _counts['TOUCH']!;
    final brk = _counts['BREAK']!;
    final breakCp = brk[0], breakP = brk[1], breakG = brk[2];
    final breakGo = brk[3];

    // 目标达成率（保留4位小数）
    final totalScoreTarget = double.parse(targetRate.toStringAsFixed(4));

    final breakNum = _sum('BREAK');
    final totalWeight = _sum('TAP') * TAP_WEIGHT +
        _sum('HOLD') * HOLD_WEIGHT +
        _sum('SLIDE') * SLIDE_WEIGHT +
        _sum('TOUCH') * TOUCH_WEIGHT +
        breakNum * BREAK_WEIGHT;

    double nonBreak(List<int> c, int weight) =>
        weight * (c[0] + c[1] + c[2] * 0.8 + c[3] * 0.5);
    final baseNonBreak = nonBreak(tap, TAP_WEIGHT) +
        nonBreak(hold, HOLD_WEIGHT) +
        nonBreak(slide, SLIDE_WEIGHT) +
        nonBreak(touch, TOUCH_WEIGHT);

    const errorThreshold = 0.0001; // 误差阈值
    var bestP75 = 0, bestP50 = 0, bestG80 = 0, bestG60 = 0, bestG50 = 0;
    var bestBase = 0.0, bestExtra = 0.0, bestTotal = 0.0;
    var minError = double.infinity;

    for (var breakP75 = 0; breakP75 <= breakP; breakP75++) {
      final breakP50 = breakP - breakP75;
      for (var breakG80 = 0; breakG80 <= breakG; breakG80++) {
        for (var breakG60 = 0; breakG60 <= breakG - breakG80; breakG60++) {
          final breakG50 = breakG - breakG80 - breakG60;

          final baseBreak = BREAK_WEIGHT *
              (breakCp +
                  breakP +
                  breakG80 * 0.8 +
                  breakG60 * 0.6 +
                  breakG50 * 0.5 +
                  breakGo * 0.4);
          var baseScore = (baseNonBreak + baseBreak) / totalWeight * 100;
          baseScore = double.parse(baseScore.toStringAsFixed(4));

          final extraBreak = breakCp +
              breakP75 * 0.75 +
              breakP50 * 0.5 +
              breakG * 0.4 +
              breakGo * 0.3;
          var extraScore = breakNum == 0 ? 0.0 : extraBreak / breakNum;
          extraScore = double.parse(extraScore.toStringAsFixed(4));

          final totalScore =
              double.parse((baseScore + extraScore).toStringAsFixed(4));
          final error = (totalScore - totalScoreTarget).abs();

          if (error < minError) {
            minError = error;
            bestP75 = breakP75;
            bestP50 = breakP50;
            bestG80 = breakG80;
            bestG60 = breakG60;
            bestG50 = breakG50;
            bestBase = baseScore;
            bestExtra = extraScore;
            bestTotal = totalScore;
          }
          if (error <= errorThreshold) {
            return _ReverseResult(
              found: true,
              target: totalScoreTarget,
              p75: breakP75,
              p50: breakP50,
              g80: breakG80,
              g60: breakG60,
              g50: breakG50,
              base: baseScore,
              extra: extraScore,
              total: totalScore,
              error: error,
            );
          }
        }
      }
    }
    return _ReverseResult(
      found: false,
      target: totalScoreTarget,
      p75: bestP75,
      p50: bestP50,
      g80: bestG80,
      g60: bestG60,
      g50: bestG50,
      base: bestBase,
      extra: bestExtra,
      total: bestTotal,
      error: minError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = _types[_tab];

    return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title != null)
              AppSectionHeader(
                title: widget.title!,
                trailing: TextButton(
                  onPressed: reset,
                  child:  Text(context.l10n.flowReset),
                ),
              ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.flowTargetAchievement,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _rateController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,4}')),
                    ],
                    onChanged: (_) {
                      if (_result != null) setState(() => _result = null);
                    },
                    style: AppTheme.number(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface),
                    decoration: InputDecoration(
                      hintText: context.l10n.flowEG1005000,
                      hintStyle: TextStyle(
                          fontSize: 15,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                      suffixText: '%',
                      filled: true,
                      fillColor: AppSurfaces.inset(context),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
             AppSectionHeader(
              title: context.l10n.flowJudgmentDetails,
              subtitle: context.l10n.flowForBREAKEnterTheMainJudgmentCounts,
            ),
            SegmentedTabs(
              items: [
                for (final t in _types) SegmentedTabItem(t, caption: '${_sum(t)}'),
              ],
              selectedIndex: _tab,
              onChanged: (i) {
                FocusScope.of(context).unfocus();
                setState(() => _tab = i);
              },
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < _judges.length; i++)
                    JudgeCountRow(
                      key: ValueKey('$type-$i'),
                      label: _judges[i].$1,
                      color: _judges[i].$2,
                      value: _counts[type]![i],
                      showDivider: i > 0,
                      onChanged: (v) => _setCount(type, i, v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _calculating ? null : _calculateFullReverse,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusMedium),
                  ),
                  textStyle: AppTheme.font(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: _calculating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: scheme.onPrimary),
                          ),
                          const SizedBox(width: 10),
                           Text(context.l10n.flowCalculating2),
                        ],
                      )
                    :  Text(context.l10n.flowCalculateBREAKDetails),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              KeyedSubtree(key: _resultKey, child: _buildResult(_result!)),
            ],
          ],
    );
  }

  Widget _buildResult(_ReverseResult r) {
    final scheme = Theme.of(context).colorScheme;
    final onCard = scheme.onSurface;
    final muted = onCard.withValues(alpha: 0.72);
    Widget cell(String label, int value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: muted)),
              Text('$value',
                  style: AppTheme.number(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: onCard)),
            ],
          ),
        );

    return EmphasisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                r.found
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  r.found ? context.l10n.flowSolutionFoundError00001 : context.l10n.flowNoExactSolutionShowingTheClosestResult,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('BREAK PERFECT', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 4),
          Row(children: [cell(context.l10n.flow50PointLoss2, r.p75), cell(context.l10n.flow100PointLoss2, r.p50)]),
          const SizedBox(height: 12),
          Text('BREAK GREAT', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 4),
          Row(children: [
            cell('80%', r.g80),
            cell('60%', r.g60),
            cell('50%', r.g50),
          ]),
          const SizedBox(height: 14),
          Divider(height: 1, color: onCard.withValues(alpha: 0.18)),
          const SizedBox(height: 10),
          Text(
            context.l10n.flowTargetP0BaseP1ExtraP2((r.target).toString(), (r.base).toString(), (r.extra).toString()),
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.flowTotalAchievementP0P1P2((r.total).toString(), (r.found ? context.l10n.flowError2 : context.l10n.flowMinimumError).toString(), (r.error).toString()),
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    );
  }
}
