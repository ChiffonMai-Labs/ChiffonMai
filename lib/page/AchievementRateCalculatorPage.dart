import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import '../widgets/AppDialogs.dart';

/// 达成率计算器。
///
/// 2026-11 重构：从「填表 → 点按钮 → 弹窗出结果」改成**边填边算**。
/// 计算规则与旧版逐字一致（权重 TAP 1 / HOLD 2 / SLIDE 3 / TOUCH 1 / BREAK 5，
/// 基础分、奖励分各自四舍五入到 4 位小数后相加），见 [_compute]。
/// 旧版结果弹窗里的「单个音符判定损失」保留为 [_showSingleNoteLossDialog]。
class AchievementRateCalculator extends StatefulWidget {
  const AchievementRateCalculator({super.key});

  @override
  State<AchievementRateCalculator> createState() =>
      _AchievementRateCalculatorState();
}

class _AchievementResult {
  final double base;
  final double extra;
  final double total;
  final int totalWeight;
  final int breakNum;

  const _AchievementResult({
    required this.base,
    required this.extra,
    required this.total,
    required this.totalWeight,
    required this.breakNum,
  });
}

class _JudgeDef {
  final String label;
  final Color color;

  /// 基础分损失比例（相对该音符满分）。
  final double baseLoss;

  /// 奖励分损失比例（仅 BREAK）。
  final double bonusLoss;

  /// BREAK 行的说明，例如「基础 100% · 奖励 75%」。
  final String? note;

  const _JudgeDef(this.label, this.color, this.baseLoss,
      {this.bonusLoss = 0, this.note});
}

class _AchievementRateCalculatorState extends State<AchievementRateCalculator> {
  static const List<String> _types = ['TAP', 'HOLD', 'SLIDE', 'TOUCH', 'BREAK'];

  // 定义各种note的权重（与旧版一致）
  static const Map<String, int> _weights = {
    'TAP': 1,
    'HOLD': 2,
    'SLIDE': 3,
    'TOUCH': 1,
    'BREAK': 5,
  };

  static const List<_JudgeDef> _normalJudges = [
    _JudgeDef('CRITICAL PERFECT', AppColors.judgeCriticalPerfect, 0),
    _JudgeDef('PERFECT', AppColors.judgePerfect, 0),
    _JudgeDef('GREAT', AppColors.judgeGreat, 0.2),
    _JudgeDef('GOOD', AppColors.judgeGood, 0.5),
    _JudgeDef('MISS', AppColors.judgeMiss, 1),
  ];

  // 顺序与旧版字段一致：
  // _breakP, _break50, _break100, _break80, _break60, _break50g, _breakGo, _breakM
  static const List<_JudgeDef> _breakJudges = [
    _JudgeDef('CRITICAL PERFECT', AppColors.judgeCriticalPerfect, 0,
        note: '基础 100% · 奖励 100%'),
    _JudgeDef('PERFECT · 50落', AppColors.judgePerfect, 0,
        bonusLoss: 0.25, note: '基础 100% · 奖励 75%'),
    _JudgeDef('PERFECT · 100落', AppColors.judgePerfect, 0,
        bonusLoss: 0.5, note: '基础 100% · 奖励 50%'),
    _JudgeDef('GREAT · 80%', AppColors.judgeGreat, 0.2,
        bonusLoss: 0.6, note: '基础 80% · 奖励 40%'),
    _JudgeDef('GREAT · 60%', AppColors.judgeGreat, 0.4,
        bonusLoss: 0.6, note: '基础 60% · 奖励 40%'),
    _JudgeDef('GREAT · 50%', AppColors.judgeGreat, 0.5,
        bonusLoss: 0.6, note: '基础 50% · 奖励 40%'),
    _JudgeDef('GOOD', AppColors.judgeGood, 0.6,
        bonusLoss: 0.7, note: '基础 40% · 奖励 30%'),
    _JudgeDef('MISS', AppColors.judgeMiss, 1,
        bonusLoss: 1, note: '基础 0% · 奖励 0%'),
  ];

  /// 评级下限（达成率 → 评级），从高到低。
  static const List<(double, String)> _rankTiers = [
    (100.5, 'SSS+'),
    (100.0, 'SSS'),
    (99.5, 'SS+'),
    (99.0, 'SS'),
    (98.0, 'S+'),
    (97.0, 'S'),
    (94.0, 'AAA'),
    (90.0, 'AA'),
    (80.0, 'A'),
    (75.0, 'BBB'),
    (70.0, 'BB'),
    (60.0, 'B'),
    (50.0, 'C'),
    (0.0, 'D'),
  ];

  final Map<String, List<int>> _counts = {
    'TAP': List<int>.filled(5, 0),
    'HOLD': List<int>.filled(5, 0),
    'SLIDE': List<int>.filled(5, 0),
    'TOUCH': List<int>.filled(5, 0),
    'BREAK': List<int>.filled(8, 0),
  };

  int _tab = 0;

  int _countOf(String type) => _counts[type]!.fold(0, (sum, n) => sum + n);

  bool get _hasAny => _types.any((t) => _countOf(t) > 0);

  static double _round4(double value) =>
      double.parse(value.toStringAsFixed(4));

  /// 与旧版 `_calculateAchievementRate` 相同的算法；没有音符时返回 null。
  _AchievementResult? _compute() {
    final breakNum = _countOf('BREAK');
    final totalWeight = _countOf('TAP') * _weights['TAP']! +
        _countOf('HOLD') * _weights['HOLD']! +
        _countOf('SLIDE') * _weights['SLIDE']! +
        _countOf('TOUCH') * _weights['TOUCH']! +
        breakNum * _weights['BREAK']!;
    if (totalWeight == 0) return null;

    double normalBase(String type) {
      final c = _counts[type]!;
      return _weights[type]! * (c[0] + c[1] + c[2] * 0.80 + c[3] * 0.50);
    }

    final b = _counts['BREAK']!;
    final baseBreakWeight = _weights['BREAK']! *
        (b[0] +
            (b[1] + b[2]) +
            b[3] * 0.80 +
            b[4] * 0.60 +
            b[5] * 0.50 +
            b[6] * 0.40);
    final baseWeight = normalBase('TAP') +
        normalBase('HOLD') +
        normalBase('SLIDE') +
        normalBase('TOUCH') +
        baseBreakWeight;

    // 基础部分 满分100 结果四舍五入保留四位小数
    final base = _round4(baseWeight / totalWeight * 100);

    // 额外评价部分 全由break决定 满分1 结果四舍五入保留四位小数
    final extraBreakWeight = b[0] +
        b[2] * 0.50 +
        b[1] * 0.75 +
        (b[3] + b[4] + b[5]) * 0.40 +
        b[6] * 0.30;
    final extra = breakNum == 0 ? 0.0 : _round4(extraBreakWeight / breakNum);

    return _AchievementResult(
      base: base,
      extra: extra,
      total: _round4(base + extra),
      totalWeight: totalWeight,
      breakNum: breakNum,
    );
  }

  /// 某一行判定当前造成的达成率损失（百分点）。
  double _rowLoss(String type, int index, _AchievementResult? result) {
    if (result == null) return 0;
    final count = _counts[type]![index];
    if (count == 0) return 0;
    if (type == 'BREAK') {
      final def = _breakJudges[index];
      final baseLoss =
          count * def.baseLoss * _weights['BREAK']! / result.totalWeight * 100;
      final bonusLoss =
          result.breakNum == 0 ? 0.0 : count * def.bonusLoss / result.breakNum;
      return baseLoss + bonusLoss;
    }
    final def = _normalJudges[index];
    return count * def.baseLoss * _weights[type]! / result.totalWeight * 100;
  }

  void _setCount(String type, int index, int value) {
    if (_counts[type]![index] == value) return;
    setState(() => _counts[type]![index] = value);
  }

  void _clearAll() {
    FocusScope.of(context).unfocus();
    setState(() {
      for (final list in _counts.values) {
        list.fillRange(0, list.length, 0);
      }
    });
  }

  void _showSingleNoteLossDialog(_AchievementResult result) {
    String loss(double ratio, int weight) =>
        '${_round4(ratio * 100.00 * weight / result.totalWeight)}%';
    showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final cellStyle = AppTheme.number(
            fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface);
        Widget judgePill(String label, Color color) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusPill),
                ),
                child: Text(label,
                    style: AppTheme.number(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            );
        Widget valueCell(String value) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: cellStyle, maxLines: 1),
              ),
            );
        return AppAlertDialog(
          title: const Text('单个音符的判定损失'),
          content: SingleChildScrollView(
            child: Table(
              columnWidths: const {0: FixedColumnWidth(58)},
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(children: [
                  const SizedBox.shrink(),
                  judgePill('GREAT', AppColors.judgeGreat),
                  judgePill('GOOD', AppColors.judgeGood),
                  judgePill('MISS', AppColors.judgeMiss),
                ]),
                for (final type in const ['TAP', 'HOLD', 'SLIDE', 'TOUCH'])
                  TableRow(
                    decoration: BoxDecoration(
                      border: type == 'TAP'
                          ? null
                          : Border(
                              top: BorderSide(color: scheme.outlineVariant)),
                    ),
                    children: [
                      Text(type,
                          style: AppTheme.number(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant)),
                      valueCell(loss(0.20, _weights[type]!)),
                      valueCell(loss(0.50, _weights[type]!)),
                      valueCell(loss(1.00, _weights[type]!)),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _compute();
    final type = _types[_tab];
    final isBreak = type == 'BREAK';
    final judges = isBreak ? _breakJudges : _normalJudges;
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final keyboardOpen = keyboardInset > 0;

    // ⚠️ 键盘弹出前后这棵树的结构不能变：曾经按可用高度把结果卡在「固定顶部」和
    // 「跟列表一起滚」之间切换，切换时输入框被销毁 → 丢焦点 → 键盘立刻收回，
    // 表现就是一点输入框键盘就闪退。键盘只影响结果卡的详略和下方留白。
    return BackgroundPageScaffold(
      title: '达成率计算器',
      resizeToAvoidBottomInset: false,
      actions: [
        TextButton(
          onPressed: _hasAny ? _clearAll : null,
          child: const Text('清空',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部高度有上限，再矮的屏幕（横屏 + 键盘）也不会溢出。
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight:
                      ((constraints.maxHeight - keyboardInset) * 0.6)
                          .clamp(120.0, double.infinity)
                          .toDouble(),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildResultCard(result, compact: keyboardOpen),
                      const SizedBox(height: AppDesignTokens.cardGap),
                      PillTabs(
                        items: [
                          for (final t in _types)
                            SegmentedTabItem(t, caption: '${_countOf(t)}'),
                        ],
                        selectedIndex: _tab,
                        onChanged: (i) {
                          FocusScope.of(context).unfocus();
                          setState(() => _tab = i);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // 不用 ListView：懒加载会把滚出视口的输入框销毁，同样会收起键盘。
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppDesignTokens.gutter,
                      AppDesignTokens.cardGap,
                      AppDesignTokens.gutter,
                      AppDesignTokens.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < judges.length; i++)
                              _buildJudgeRow(type, i, judges[i], result),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          isBreak
                              ? 'BREAK 共 ${_countOf('BREAK')} 个 · 每行下方是基础分 / 奖励分比例'
                              : '$type 共 ${_countOf(type)} 个 · 红字是这一档判定丢掉的达成率',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (keyboardOpen)
                SizedBox(height: keyboardInset)
              else
                Padding(
                  padding: EdgeInsets.fromLTRB(
                      AppDesignTokens.gutter,
                      0,
                      AppDesignTokens.gutter,
                      media.padding.bottom + 12),
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: result == null
                          ? null
                          : () => _showSingleNoteLossDialog(result),
                      child: const Text('查看单音符损失',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJudgeRow(
      String type, int index, _JudgeDef def, _AchievementResult? result) {
    final scheme = Theme.of(context).colorScheme;
    final loss = _rowLoss(type, index, result);
    final lossText = loss > 0.00005 ? '−${loss.toStringAsFixed(4)}%' : null;
    final String? detail;
    if (def.note != null) {
      detail = lossText == null ? def.note : '${def.note}  $lossText';
    } else {
      detail = lossText ?? '无损失';
    }
    return JudgeCountRow(
      key: ValueKey('$type-$index'),
      label: def.label,
      color: def.color,
      detail: detail,
      detailColor: lossText != null ? scheme.error : null,
      value: _counts[type]![index],
      showDivider: index > 0,
      onChanged: (v) => _setCount(type, index, v),
    );
  }

  Widget _buildResultCard(_AchievementResult? result, {bool compact = false}) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final onCard = scheme.onInverseSurface;
    final muted = onCard.withValues(alpha: 0.72);
    final normalNum = _countOf('TAP') +
        _countOf('HOLD') +
        _countOf('SLIDE') +
        _countOf('TOUCH');

    if (result == null && compact) {
      return EmphasisCard(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          children: [
            Expanded(
              child: Text('实时达成率',
                  style: TextStyle(fontSize: 12, color: muted)),
            ),
            Text('—',
                style: AppTheme.number(
                    fontSize: 24, fontWeight: FontWeight.w700, color: onCard)),
          ],
        ),
      );
    }

    if (result == null) {
      return EmphasisCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('实时达成率', style: TextStyle(fontSize: 12, color: muted)),
            const SizedBox(height: 8),
            Text('—',
                style: AppTheme.number(
                    fontSize: 46, fontWeight: FontWeight.w700, color: onCard)),
            if (!compact) ...[
              const SizedBox(height: 6),
              Text('在下方填写各档判定数量，结果会自动算出来',
                  style: TextStyle(fontSize: 12, color: muted)),
            ],
          ],
        ),
      );
    }

    final total = result.total;
    final tierIndex = _rankTiers.indexWhere((t) => total >= t.$1);
    final tier = _rankTiers[tierIndex < 0 ? _rankTiers.length - 1 : tierIndex];
    final next = tierIndex > 0 ? _rankTiers[tierIndex - 1] : null;
    final band = next == null
        ? 1.0
        : ((total - tier.$1) / (next.$1 - tier.$1)).clamp(0.0, 1.0).toDouble();
    final rankColors = AppColors.rankBadge(tier.$2, brightness);
    final fixed = total.toStringAsFixed(4);
    final dot = fixed.indexOf('.');

    return EmphasisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('实时达成率',
                    style: TextStyle(fontSize: 12, color: muted)),
              ),
              Text('$normalNum + ${result.breakNum} BREAK',
                  style: TextStyle(fontSize: 12, color: muted)),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: '总达成率 $fixed%，评级 ${tier.$2}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: fixed.substring(0, dot),
                          style: AppTheme.number(
                              fontSize: 46,
                              fontWeight: FontWeight.w700,
                              color: onCard,
                              height: 1),
                        ),
                        TextSpan(
                          text: '${fixed.substring(dot)}%',
                          style: AppTheme.number(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: onCard,
                              height: 1),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                RankBadge(rank: tier.$2, fontSize: 16),
              ],
            ),
          ),
          // 键盘弹出时空间紧张，结果卡只留达成率和评级。
          if (!compact) ...[
          const SizedBox(height: 8),
          Text('基础 ${result.base.toStringAsFixed(4)}% · 奖励 ${result.extra.toStringAsFixed(4)}%',
              style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SmoothLinearProgressIndicator(
              value: band,
              minHeight: 6,
              backgroundColor: onCard.withValues(alpha: 0.16),
              color: rankColors.background,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? '已经是最高评级 SSS+'
                : '距 ${next.$2}（${next.$1}%）还差 ${(next.$1 - total).toStringAsFixed(4)}%',
            style: TextStyle(fontSize: 12, color: onCard.withValues(alpha: 0.86)),
          ),
          ],
        ],
      ),
    );
  }
}
