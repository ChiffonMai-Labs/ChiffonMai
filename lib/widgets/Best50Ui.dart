import 'package:flutter/cupertino.dart' as ios;
import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ColorUtil.dart';
import '../utils/CoverUtil.dart';
import '../utils/RatingSegmentPreferences.dart';
import '../utils/StringUtil.dart';
import 'AppUi.dart';
import 'AppDialogs.dart';
import 'AppToast.dart';
import 'B50GameCardWidget.dart';
import 'MarqueeText.dart';

/// Best50 系列页共用的界面组件。
///
/// 页面结构：[Best50Hero]（大数字 + 构成条）→ B35 / B15 分段 → 一行摘要 →
/// [Best50Grid]（三种显示模式）；点卡片弹 [showBest50SongSheet]。
///
/// 曲绘卡和单列长条卡只用于屏幕显示；双列模式和导出图片用 `B50GameCardWidget`。

/// 一张曲绘卡需要的全部数据（各页面从自己的数据结构换算过来）。
class Best50CardData {
  final int songId;
  final String title;
  final int levelIndex;
  final String type;
  final int rating;
  final double ds;
  final bool isFitDiff;
  final double achievement;
  final String fc;
  final String fs;
  final String stars;
  final int dxScore;
  final int maxDxScore;

  /// 曲绘左下角的附加角标（PC50 的 `PC 1234`）。
  final String? badge;

  /// 打开歌曲详情。
  final VoidCallback onOpenSong;

  const Best50CardData({
    required this.songId,
    required this.title,
    required this.levelIndex,
    required this.type,
    required this.rating,
    required this.ds,
    required this.achievement,
    required this.fc,
    required this.fs,
    required this.stars,
    required this.dxScore,
    required this.maxDxScore,
    required this.onOpenSong,
    this.isFitDiff = false,
    this.badge,
  });

  bool get isUtage => songId.toString().length == 6;

  Color get difficultyColor =>
      isUtage ? AppColors.utageCard() : ColorUtil.getCardColor(levelIndex);

  String get difficultyLabel {
    if (isUtage) return ChartDifficulty.utageLabel;
    final labels = ChartDifficulty.labels;
    return levelIndex >= 0 && levelIndex < labels.length
        ? labels[levelIndex]
        : '';
  }

  String get dsText => ds.toStringAsFixed(isFitDiff ? 2 : 1);
  String get achievementText => '${achievement.toStringAsFixed(4)}%';
}

// ---------------------------------------------------------------------------
// 显示模式
// ---------------------------------------------------------------------------

/// Best50 系列页的显示模式。
enum Best50DisplayMode {
  cover('曲绘', Icons.grid_view_rounded),
  twoColumns('双列', Icons.view_module_rounded),
  oneColumn('单列', Icons.view_agenda_rounded);

  final String label;
  final IconData icon;

  const Best50DisplayMode(this.label, this.icon);
}

/// 当前显示模式。六个页面共用同一份，改一处其它页面同步，并记在本地。
class Best50DisplayPreference extends ValueNotifier<Best50DisplayMode> {
  Best50DisplayPreference._() : super(Best50DisplayMode.cover);

  static final Best50DisplayPreference instance = Best50DisplayPreference._();

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(CacheKeyConstant.best50DisplayMode);
    instance.value = Best50DisplayMode.values.firstWhere(
      (mode) => mode.name == name,
      orElse: () => Best50DisplayMode.cover,
    );
  }

  Future<void> set(Best50DisplayMode mode) async {
    if (mode == value) return;
    value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.best50DisplayMode, mode.name);
  }
}

/// 网格上方的显示模式切换。
class Best50DisplayModeBar extends StatelessWidget {
  const Best50DisplayModeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final preference = Best50DisplayPreference.instance;
    return ValueListenableBuilder<Best50DisplayMode>(
      valueListenable: preference,
      builder: (context, current, _) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 244,
          child: SegmentedTabs(
            height: 36,
            items: [
              for (final mode in Best50DisplayMode.values)
                SegmentedTabItem(switch (mode) {
                  Best50DisplayMode.cover => context.l10n.bestDisplayCover,
                  Best50DisplayMode.twoColumns =>
                    context.l10n.bestDisplayTwoColumns,
                  Best50DisplayMode.oneColumn =>
                    context.l10n.bestDisplayOneColumn,
                }),
            ],
            selectedIndex: current.index,
            onChanged: (index) =>
                preference.set(Best50DisplayMode.values[index]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 推分计算
// ---------------------------------------------------------------------------

/// 达成率档位：下限、乘数、评级。
const List<(double, double, String)> _ratingTiers = [
  (100.5, 22.4, 'SSS+'),
  (100.0, 21.6, 'SSS'),
  (99.5, 21.1, 'SS+'),
  (99.0, 20.8, 'SS'),
  (98.0, 20.3, 'S+'),
  (97.0, 20.0, 'S'),
  (94.0, 16.8, 'AAA'),
  (90.0, 15.2, 'AA'),
  (80.0, 13.6, 'A'),
];

int _ratingOf(double ds, double achievement) {
  for (final tier in _ratingTiers) {
    if (achievement >= tier.$1) {
      final capped = achievement > 100.5 ? 100.5 : achievement;
      return (ds * tier.$2 * capped / 100).floor();
    }
  }
  return 0;
}

/// 下一档评级能涨多少分：`(评级, 下限, 涨分)`；已到 SSS+ 或不足 A 时返回 null。
(String, double, int)? best50NextTier(CardRatingInput input) {
  (double, double, String)? next;
  for (final tier in _ratingTiers) {
    if (tier.$1 > input.achievement + 1e-9) next = tier;
  }
  if (next == null) return null;
  return (
    next.$3,
    next.$1,
    _ratingOf(input.ds, next.$1) - _ratingOf(input.ds, input.achievement),
  );
}

/// 详细分段：再多 1 Rating 需要的最低达成率（精确到 0.0001%），返回值同 [best50NextTier]。
(String, double, int)? best50NextRatingPoint(CardRatingInput input) {
  if (input.ds <= 0) return null;
  final current = _ratingOf(input.ds, input.achievement);
  final target = current + 1;
  final lower = input.achievement + 0.0001;
  // 从低档往高档找，Rating 随达成率单调不减，第一个满足的就是最低达成率。
  for (var index = _ratingTiers.length - 1; index >= 0; index--) {
    final (threshold, factor, rank) = _ratingTiers[index];
    final upper = index == 0 ? 100.5 : _ratingTiers[index - 1].$1 - 0.0001;
    if (upper < lower) continue;
    final required = target * 100 / (input.ds * factor);
    final start = math.max(threshold, math.max(lower, required));
    var units = (start * 10000 - 1e-6).ceil();
    // 浮点误差可能让刚好卡线的值差一点，往上补一格再判断。
    if (_ratingOf(input.ds, units / 10000) < target) units++;
    final achievement = units / 10000;
    if (achievement > upper + 1e-9) continue;
    final rating = _ratingOf(input.ds, achievement);
    if (rating >= target) return (rank, achievement, rating - current);
  }
  return null;
}

typedef CardRatingInput = ({double ds, double achievement});

// ---------------------------------------------------------------------------
// 头部
// ---------------------------------------------------------------------------

/// 大数字 + 说明 + 右侧控件（理论值开关 / 模式切换），下面是 B35 / B15 构成条。
class Best50Hero extends StatelessWidget {
  final int total;
  final String label;

  /// 相对基准的涨跌（拟合 / 理想页），null 不显示。
  final int? delta;
  final Widget? trailing;
  final int? best35Sum;
  final int? best15Sum;

  const Best50Hero({
    super.key,
    required this.total,
    required this.label,
    this.delta,
    this.trailing,
    this.best35Sum,
    this.best15Sum,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final b35 = best35Sum, b15 = best15Sum;
    final sum = (b35 ?? 0) + (b15 ?? 0);
    final d = delta;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Semantics(
                        label: '$label $total',
                        excludeSemantics: true,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: total.toDouble()),
                          duration: AppDesignTokens.motion(
                              context, const Duration(milliseconds: 900)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => Text(
                            '${value.round()}',
                            style: AppTheme.number(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              height: 0.95,
                              letterSpacing: -1.5,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      if (d != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          d >= 0 ? '+$d' : '$d',
                          style: AppTheme.number(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: d >= 0
                                ? AppColors.successGreen(theme.brightness)
                                : AppColors.errorRed(theme.brightness),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 4),
          // 说明独占一行，多长都完整显示。
          Text(label,
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: scheme.onSurfaceVariant)),
          if (b35 != null && b15 != null) ...[
            const SizedBox(height: 10),
            SplitBar(
              fraction: sum > 0 ? b35 / sum : 0.7,
              primary: scheme.primary,
              secondary: scheme.primary.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
  }
}

/// 顶部栏右侧的图标按钮（历史、导出……），圆形样式由 AppHeader 统一提供。
class Best50IconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const Best50IconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
    );
  }
}

/// 头部右侧的小胶囊：理论值开关。
class Best50SwitchPill extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const Best50SwitchPill({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return MergeSemantics(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label),
        const SizedBox(width: 6),
        ios.CupertinoSwitch(value: value, onChanged: onChanged),
      ]));
    }
    return Semantics(
      toggled: value,
      label: label,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: AppSurfaces.card(context),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Transform.scale(
                  scale: 0.72,
                  child: Switch(value: value, onChanged: onChanged),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 头部右侧的小胶囊：点击切换（拟合 Best50 的模式）。
class Best50ActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const Best50ActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppSurfaces.card(context),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 灰色的一行说明（分段下面的摘要、拟合模式说明等）。
class Best50MetaLine extends StatelessWidget {
  final String text;
  final Color? color;

  const Best50MetaLine(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: color ?? Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}

/// 把列表换算成分段下面的摘要：`往期版本 35 首 · 最低 301 · 平均 305.2`。
String best50MetaText(String name, Iterable<int> ratings) {
  if (ratings.isEmpty) return appL10n.flowP00Songs((name).toString());
  final list = ratings.toList();
  final min = list.reduce((a, b) => a < b ? a : b);
  final avg = list.fold<int>(0, (a, b) => a + b) / list.length;
  return appL10n.flowP0P1SongsMinP2AvgP3(
      (name).toString(),
      (list.length).toString(),
      (min).toString(),
      (avg.toStringAsFixed(1)).toString());
}

/// 平均达成率一行的数据。
class Best50AverageRow {
  final String label;
  final double achievement;

  /// DX 分数达成率，0~1。
  final double scoreRate;

  const Best50AverageRow(this.label, this.achievement, this.scoreRate);
}

/// 可折叠的「平均达成率」卡片：达成率 / DX 分数达成率 / 星级。
class Best50AveragesCard extends StatefulWidget {
  final List<Best50AverageRow> rows;
  final String title;

  const Best50AveragesCard({
    super.key,
    required this.rows,
    this.title = '平均达成率',
  });

  @override
  State<Best50AveragesCard> createState() => _Best50AveragesCardState();
}

class _Best50AveragesCardState extends State<Best50AveragesCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(context.featureText(widget.title),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppDesignTokens.motion(
                          context, AppDesignTokens.fastMotion),
                      child: Icon(Icons.expand_more_rounded,
                          color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration:
                AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
            curve: AppDesignTokens.emphasizedCurve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: [
                        for (var i = 0; i < widget.rows.length; i++) ...[
                          if (i > 0)
                            Divider(
                                height: 1,
                                color: AppSurfaces.hairline(context)),
                          _AverageLine(row: widget.rows[i]),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _AverageLine extends StatelessWidget {
  final Best50AverageRow row;

  const _AverageLine({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final numStyle = AppTheme.number(
        fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(row.label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${row.achievement.toStringAsFixed(4)}%',
                      style: numStyle),
                  const SizedBox(width: 12),
                  Text(
                      context.l10n.flowDXScoreP02(
                          ((row.scoreRate * 100).toStringAsFixed(2))
                              .toString()),
                      style: numStyle.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  StarBadge(stars: StringUtil.formatStars(row.scoreRate)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 页面主操作之外的按钮（选类型、选标签、再抽一次……）。
///
/// [primary] 为 true 用主题色实心，否则白卡片底。
class Best50ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  const Best50ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 14);
    return FilledButton(
      onPressed: onPressed,
      style: primary
          ? FilledButton.styleFrom(padding: padding)
          : FilledButton.styleFrom(
              padding: padding,
              backgroundColor: AppSurfaces.card(context),
              foregroundColor: scheme.onSurface,
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 曲绘网格
// ---------------------------------------------------------------------------

/// Best50 网格：上方切换显示模式，下方是三列曲绘卡或双列、单列的成绩卡。
///
/// [remaining] 是榜单截断后和最后一首并列的谱面，非空时最后一格显示「剩余 N 首」，
/// [remainingLabel] 写明并列的依据（RA 或定数）。
class Best50Grid extends StatelessWidget {
  final List<Best50CardData> items;
  final List<Best50CardData> remaining;
  final String? remainingLabel;
  final VoidCallback? onSelectTies;
  final int? tieSelectedCount;
  final int? tieTotalCount;
  final bool tieCustomized;

  /// 榜单内容的标识。换数据或换分段时传新值，新内容重新播放入场动画。
  final Object? contentKey;

  const Best50Grid({
    super.key,
    required this.items,
    this.remaining = const [],
    this.remainingLabel,
    this.onSelectTies,
    this.tieSelectedCount,
    this.tieTotalCount,
    this.tieCustomized = false,
    this.contentKey,
  });

  /// 网格布局（自定义 Best50 的网格也用它）。曲绘卡的高度按宽度和系统字号算，
  /// 不会被压扁；成绩卡按固定宽高比。
  static SliverGridDelegate delegate(BuildContext context, double maxWidth,
      {Best50DisplayMode mode = Best50DisplayMode.cover}) {
    const gap = 10.0;
    final wide = maxWidth >= 600;
    if (mode == Best50DisplayMode.oneColumn) {
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 2 : 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 6,
        mainAxisExtent: Best50StripCard.heightFor(context),
      );
    }
    if (mode == Best50DisplayMode.twoColumns) {
      const cardGap = 5.0;
      final columns = wide ? 3 : 2;
      final w = (maxWidth - cardGap * (columns - 1)) / columns;
      return SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: cardGap,
        mainAxisSpacing: cardGap,
        mainAxisExtent: w / B50GameCardWidget.designAspectRatio,
      );
    }
    final columns = wide ? 5 : 3;
    final w = (maxWidth - gap * (columns - 1)) / columns;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      mainAxisExtent: w + 17 + 39 * textScale,
    );
  }

  /// 供 CustomScrollView 按需构建的 Sliver 集合（替代外层 SingleChildScrollView + shrinkWrap GridView）。
  static List<Widget> buildSlivers({
    required BuildContext context,
    required Best50DisplayMode mode,
    required List<Best50CardData> items,
    List<Best50CardData> remaining = const [],
    String? remainingLabel,
    VoidCallback? onSelectTies,
    int? tieSelectedCount,
    int? tieTotalCount,
    bool tieCustomized = false,
    Object? contentKey,
  }) {
    final showTieBar = onSelectTies != null &&
        remaining.isNotEmpty &&
        tieSelectedCount != null &&
        tieTotalCount != null;
    final maxIdLength =
        items.any((item) => item.songId.toString().length == 6) ? 6 : 5;
    return [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTieBar) ...[
              Best50TiePickerBar(
                label: remainingLabel ?? '',
                selectedCount: tieSelectedCount,
                totalCount: tieTotalCount,
                customized: tieCustomized,
                onTap: onSelectTies,
              ),
              const SizedBox(height: 10),
            ],
            const Best50DisplayModeBar(),
            const SizedBox(height: 10),
          ],
        ),
      ),
      _Best50GridSliver(
        mode: mode,
        items: items,
        remaining: remaining,
        remainingLabel: remainingLabel,
        onSelectTies: onSelectTies,
        maxIdLength: maxIdLength,
        contentKey: contentKey,
      ),
    ];
  }

  static int _maxAnimatedIndexFor(Best50DisplayMode mode) => switch (mode) {
        Best50DisplayMode.oneColumn => 8,
        Best50DisplayMode.twoColumns => 10,
        Best50DisplayMode.cover => 12,
      };

  static Widget _wrapEntrance(
    ListEntrance entrance,
    Best50DisplayMode mode,
    Object? contentKey,
    int index,
    Widget child,
  ) {
    final isList = mode == Best50DisplayMode.oneColumn;
    return entrance.wrap(
      (mode, contentKey),
      index,
      child,
      maxAnimatedIndex: _maxAnimatedIndexFor(mode),
      duration: isList
          ? const Duration(milliseconds: 300)
          : const Duration(milliseconds: 420),
      offset: isList ? const Offset(0, 8) : const Offset(0, 14),
      scaleFrom: isList ? 1.0 : 0.96,
    );
  }

  static Widget _buildGridItem(
    BuildContext context, {
    required int index,
    required Best50DisplayMode mode,
    required List<Best50CardData> items,
    required List<Best50CardData> remaining,
    required String? remainingLabel,
    required VoidCallback? onSelectTies,
    required int maxIdLength,
    required bool animateEntrance,
  }) {
    if (index >= items.length) {
      final cell = _Best50RemainingCell(
        compact: mode == Best50DisplayMode.oneColumn,
        count: remaining.length,
        label: remainingLabel ?? '',
        onTap: onSelectTies ??
            () => showBest50RemainingDialog(
                  context,
                  items: remaining,
                  label: remainingLabel ?? '',
                ),
      );
      return animateEntrance ? EntranceAnimation(index: index, child: cell) : cell;
    }
    final data = items[index];
    void open() => showBest50SongSheet(context, data);
    return switch (mode) {
      Best50DisplayMode.cover => Best50CoverCard(
          data: data,
          rank: index + 1,
          entranceIndex: index,
          animateEntrance: animateEntrance,
          onTap: open,
        ),
      Best50DisplayMode.twoColumns => Best50ScoreCard(
          data: data,
          rank: index + 1,
          entranceIndex: index,
          animateEntrance: animateEntrance,
          maxIdLength: maxIdLength,
          onTap: open,
        ),
      Best50DisplayMode.oneColumn => Best50StripCard(
          data: data,
          rank: index + 1,
          entranceIndex: index,
          animateEntrance: animateEntrance,
          onTap: open,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final count = items.length + (remaining.isEmpty ? 0 : 1);
    final showTieBar = onSelectTies != null &&
        remaining.isNotEmpty &&
        tieSelectedCount != null &&
        tieTotalCount != null;
    final maxIdLength =
        items.any((item) => item.songId.toString().length == 6) ? 6 : 5;
    return ValueListenableBuilder<Best50DisplayMode>(
      valueListenable: Best50DisplayPreference.instance,
      builder: (context, mode, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTieBar) ...[
            Best50TiePickerBar(
              label: remainingLabel ?? '',
              selectedCount: tieSelectedCount!,
              totalCount: tieTotalCount!,
              customized: tieCustomized,
              onTap: onSelectTies!,
            ),
            const SizedBox(height: 10),
          ],
          const Best50DisplayModeBar(),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) => GridView.builder(
              // 换显示模式或换内容时重新入场，不复用上一批的格子。
              key: ValueKey((mode, contentKey)),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: delegate(context, constraints.maxWidth, mode: mode),
              itemCount: count,
              itemBuilder: (context, index) => _buildGridItem(
                context,
                index: index,
                mode: mode,
                items: items,
                remaining: remaining,
                remainingLabel: remainingLabel,
                onSelectTies: onSelectTies,
                maxIdLength: maxIdLength,
                animateEntrance: index < _maxAnimatedIndexFor(mode),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Best50GridSliver extends StatefulWidget {
  final Best50DisplayMode mode;
  final List<Best50CardData> items;
  final List<Best50CardData> remaining;
  final String? remainingLabel;
  final VoidCallback? onSelectTies;
  final int maxIdLength;
  final Object? contentKey;

  const _Best50GridSliver({
    required this.mode,
    required this.items,
    required this.remaining,
    required this.remainingLabel,
    required this.onSelectTies,
    required this.maxIdLength,
    required this.contentKey,
  });

  @override
  State<_Best50GridSliver> createState() => _Best50GridSliverState();
}

class _Best50GridSliverState extends State<_Best50GridSliver> {
  final ListEntrance _entrance = ListEntrance();

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length + (widget.remaining.isEmpty ? 0 : 1);
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverGrid.builder(
        // 换显示模式或换内容时重新入场，不复用上一批的格子。
        key: ValueKey((widget.mode, widget.contentKey)),
        gridDelegate: Best50Grid.delegate(context, constraints.crossAxisExtent,
            mode: widget.mode),
        itemCount: count,
        itemBuilder: (context, index) {
          final card = Best50Grid._buildGridItem(
            context,
            index: index,
            mode: widget.mode,
            items: widget.items,
            remaining: widget.remaining,
            remainingLabel: widget.remainingLabel,
            onSelectTies: widget.onSelectTies,
            maxIdLength: widget.maxIdLength,
            animateEntrance: false,
          );
          return Best50Grid._wrapEntrance(
            _entrance,
            widget.mode,
            widget.contentKey,
            index,
            card,
          );
        },
      ),
    );
  }
}

/// 单列模式的长条卡：左边曲绘，中间类型 + 歌名和达成率 + 徽章，右边 RA 和定数。
class Best50StripCard extends StatelessWidget {
  final Best50CardData data;
  final int rank;
  final VoidCallback onTap;

  /// 自定义 Best50 用来标出不合法的条目。
  final Color? outlineColor;
  final int entranceIndex;
  final bool animateEntrance;

  const Best50StripCard({
    super.key,
    required this.data,
    required this.rank,
    required this.onTap,
    this.outlineColor,
    this.entranceIndex = 0,
    this.animateEntrance = true,
  });

  static const double _coverSize = 52;

  /// 行高跟系统字号走，文字放大时不会被压住。
  static double heightFor(BuildContext context) =>
      16 + _coverSize * MediaQuery.textScalerOf(context).scale(1.0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final songId = data.songId.toString();
    final pillColor = data.difficultyColor;
    final pillForeground =
        ThemeData.estimateBrightnessForColor(pillColor) == Brightness.dark
            ? Colors.white
            : Colors.black87;
    final pressable = PressScale(
      scale: 0.98,
      child: Semantics(
        button: true,
        label: context.l10n.flowRankP0P1RatingP2((rank).toString(),
            (data.title).toString(), (data.rating).toString()),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppSurfaces.card(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
              border: outlineColor == null
                  ? null
                  : Border.all(color: outlineColor!, width: 2.5),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _coverSize,
                  height: _coverSize,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                        child: CoverUtil.buildCoverWidgetWithContext(
                            context, songId, _coverSize),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                          border: Border.all(color: pillColor, width: 2),
                        ),
                      ),
                      Positioned(
                        left: 3,
                        top: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '$rank',
                            style: AppTheme.number(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Transform.translate(
                            offset: const Offset(0, 2),
                            child: SongTypeBadge(
                                songId: songId,
                                type: data.type,
                                fontSize: 9.5),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: MarqueeText(
                              text: data.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data.achievementText,
                              maxLines: 1,
                              style: AppTheme.number(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 6),
                            RankBadge(
                              rank: StringUtil.formatRate(
                                  StringUtil.rateCodeFromAchievement(
                                      data.achievement)),
                              fontSize: 10,
                            ),
                            if (data.fc.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              ComboLabelBadge(raw: data.fc, fontSize: 10),
                            ],
                            if (data.fs.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              ComboLabelBadge(raw: data.fs, fontSize: 10),
                            ],
                            if (data.stars.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              StarBadge(stars: data.stars, fontSize: 10),
                            ],
                            if (data.badge != null) ...[
                              const SizedBox(width: 3),
                              _CoverPill(text: data.badge!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${data.rating}',
                      maxLines: 1,
                      style: AppTheme.number(
                        fontSize: 18,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Transform.translate(
                      offset: const Offset(1.5, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: pillColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.dsText,
                          maxLines: 1,
                          style: AppTheme.number(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: pillForeground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!animateEntrance) return pressable;
    return EntranceAnimation(
      index: entranceIndex,
      offset: const Offset(0, 8),
      duration: const Duration(milliseconds: 300),
      child: pressable,
    );
  }
}

/// 双列模式的成绩卡：和导出图片同一张 [B50GameCardWidget]。
class Best50ScoreCard extends StatelessWidget {
  final Best50CardData data;
  final int rank;
  final VoidCallback onTap;
  final int maxIdLength;

  /// 自定义 Best50 用来标出不合法的条目。
  final Color? outlineColor;
  final int entranceIndex;
  final bool animateEntrance;

  const Best50ScoreCard({
    super.key,
    required this.data,
    required this.rank,
    required this.onTap,
    this.maxIdLength = 5,
    this.outlineColor,
    this.entranceIndex = 0,
    this.animateEntrance = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget card = B50GameCardWidget(
      cardColor: data.difficultyColor,
      songName: data.title,
      achievementRate: data.achievement,
      difficulty: data.ds,
      dxMode: data.type == 'DX',
      isUtage: data.isUtage,
      score: data.dxScore,
      maxScore: data.maxDxScore,
      rating: data.rating,
      stars: data.stars,
      fc: data.fc,
      fs: data.fs,
      rate: StringUtil.rateCodeFromAchievement(data.achievement),
      songId: data.songId,
      starsColor: ColorUtil.getStarsColor(data.stars),
      maxIdLength: maxIdLength,
      isFitDiff: data.isFitDiff,
      palette: B50CardPalette.of(context),
    );
    final badge = data.badge;
    final pressable = PressScale(
      child: Semantics(
        button: true,
        label: context.l10n.flowRankP0P1RatingP2((rank).toString(),
            (data.title).toString(), (data.rating).toString()),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              badge == null
                  ? card
                  : B50GameCardWidget.withBadgeOverlay(
                      card: card, text: badge),
              if (outlineColor != null)
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                      border: Border.all(color: outlineColor!, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!animateEntrance) return pressable;
    return EntranceAnimation(
      index: entranceIndex,
      scaleFrom: 0.96,
      child: pressable,
    );
  }
}

/// 一张曲绘卡：曲绘（左上排名、右上难度点、左下连击 / 角标）+ RA + 定数 · 达成率。
class Best50CoverCard extends StatelessWidget {
  final Best50CardData data;
  final int rank;
  final VoidCallback onTap;

  /// 自定义 Best50 用来标出不合法的条目。
  final Color? outlineColor;

  /// 入场动画的错开序号。
  final int entranceIndex;
  final bool animateEntrance;

  const Best50CoverCard({
    super.key,
    required this.data,
    required this.rank,
    required this.onTap,
    this.outlineColor,
    this.entranceIndex = 0,
    this.animateEntrance = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Semantics(
      button: true,
      label: context.l10n.flowRankP0P1RatingP2(
          (rank).toString(), (data.title).toString(), (data.rating).toString()),
      excludeSemantics: true,
      child: Material(
        color: AppSurfaces.card(context),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          side: outlineColor == null
              ? BorderSide.none
              : BorderSide(color: outlineColor!, width: 2.5),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LayoutBuilder(
                      builder: (context, c) =>
                          CoverUtil.buildCoverWidgetWithContext(
                              context, data.songId.toString(), c.maxWidth),
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _CoverPill(text: '#$rank'),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: data.difficultyColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                    // PC50 角标、连击、同步排在曲绘左下角
                    Positioned(
                      left: 6,
                      right: 6,
                      bottom: 6,
                      child: Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: [
                          if (data.badge != null) _CoverPill(text: data.badge!),
                          if (data.fc.isNotEmpty)
                            ComboLabelBadge(raw: data.fc, fontSize: 10),
                          if (data.fs.isNotEmpty)
                            ComboLabelBadge(raw: data.fs, fontSize: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.rating}',
                        maxLines: 1,
                        style: AppTheme.number(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${data.dsText} · ${data.achievementText}',
                            maxLines: 1,
                            style: AppTheme.number(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final pressable = PressScale(child: card);
    if (!animateEntrance) return pressable;
    return EntranceAnimation(
      index: entranceIndex,
      scaleFrom: 0.96,
      child: pressable,
    );
  }
}

class _CoverPill extends StatelessWidget {
  final String text;

  const _CoverPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(
        text,
        style: AppTheme.number(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 点曲绘卡弹出：曲绘、难度、达成率、推分空间、连击同步星级、DX 分数、进详情。
Future<void> showBest50SongSheet(BuildContext context, Best50CardData data) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      final scheme = theme.colorScheme;
      final brightness = theme.brightness;
      final ratingInput = (ds: data.ds, achievement: data.achievement);
      final next = RatingSegmentPreferences.instance.isDetailed
          ? best50NextRatingPoint(ratingInput)
          : best50NextTier(ratingInput);
      final success = AppColors.comboBadge('FC', brightness);
      final rank = StringUtil.rateCodeFromAchievement(data.achievement);

      Widget tile({
        required String label,
        required String value,
        Color? background,
        Color? foreground,
      }) =>
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: background ?? AppSurfaces.inset(sheetContext),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(label,
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 11,
                            color: foreground ?? scheme.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: AppTheme.number(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: foreground ?? scheme.onSurface)),
                  ),
                ],
              ),
            ),
          );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CoverUtil.buildCoverWidgetWithContext(
                        sheetContext, data.songId.toString(), 64),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.title,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: data.difficultyColor,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.l10n.flowP0P1ConstantP2(
                                    (data.difficultyLabel).toString(),
                                    (StringUtil.formatSongType(data.type))
                                        .toString(),
                                    (data.dsText).toString()),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${data.rating}',
                      style: AppTheme.number(
                          fontSize: 28, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  tile(
                      label: context.l10n.flowAchievement2,
                      value: data.achievementText),
                  const SizedBox(width: 10),
                  next == null
                      ? tile(
                          label: context.l10n.flowRatingHeadroom,
                          value: context.l10n.flowSongLimitReached)
                      : tile(
                          label: context.l10n.flowRaiseToP0P1(
                              (next.$1).toString(), (next.$2).toString()),
                          value: '+${next.$3}',
                          background: success.background,
                          foreground: success.foreground,
                        ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (rank.isNotEmpty)
                    RankBadge(rank: rank.toUpperCase().replaceFirst('P', '+')),
                  if (data.fc.isNotEmpty) ComboLabelBadge(raw: data.fc),
                  if (data.fs.isNotEmpty) ComboLabelBadge(raw: data.fs),
                  if (data.stars.isNotEmpty) StarBadge(stars: data.stars),
                  if (data.maxDxScore > 0)
                    Text(
                        context.l10n.flowDXScoreP0P12((data.dxScore).toString(),
                            (data.maxDxScore).toString()),
                        style: AppTheme.number(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant)),
                  if (data.badge != null)
                    Text(data.badge!,
                        style: AppTheme.number(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    data.onOpenSong();
                  },
                  child: Text(context.l10n.flowViewSongDetails,
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// 网格最后一格：还有多少首和最后一首并列。
class _Best50RemainingCell extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  /// 单列模式的格子很矮，图标和文字改成横排。
  final bool compact;

  const _Best50RemainingCell({
    required this.count,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon =
        Icon(Icons.queue_music_rounded, size: 26, color: scheme.primary);
    final countText = Text(
      context.l10n.flowP0SongsRemaining((count).toString()),
      maxLines: 1,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    );
    final labelText = Text(
      label,
      maxLines: 1,
      style: AppTheme.number(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: scheme.primary,
      ),
    );
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Center(
        // 格子再小也只缩小内容，不出界。
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: compact
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 8),
                    countText,
                    const SizedBox(width: 8),
                    labelText,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(height: 8),
                    countText,
                    const SizedBox(height: 2),
                    labelText,
                  ],
                ),
        ),
      ),
    );
  }
}

/// 和最后一首并列的谱面列表，点行进歌曲详情。
Future<void> showBest50RemainingDialog(
  BuildContext context, {
  required List<Best50CardData> items,
  required String label,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AppAlertDialog(
      icon: const Icon(Icons.queue_music_rounded),
      title: Text(context.l10n.flowP0SongsRemaining((items.length).toString())),
      subtitle: context.l10n.flowP0EqualToTheLastChartOn((label).toString()),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final data = items[index];
            return AppDialogOption(
              title: data.title,
              titleWidget: Row(
                children: [
                  SongTypeBadge(
                      songId: data.songId.toString(), type: data.type),
                  const SizedBox(width: 6),
                  // 歌名只占一行，放不下时横向滚动
                  Expanded(
                    child: MarqueeText(
                      text: data.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: context.l10n.flowP0ConstantP1RAP2(
                  (data.difficultyLabel).toString(),
                  (data.dsText).toString(),
                  (data.rating).toString()),
              subtitleSingleLine: true,
              leading: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, data.songId.toString(), 44),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: data.onOpenSong,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(context.l10n.featureClose),
        ),
      ],
    ),
  );
}

/// 上分潜力的一档：推到 [achievement] 时 Rating 是 [rating]，能加 [gain] 分。
class Best50OpportunityTier {
  final double achievement;
  final String rank;
  final int rating;
  final int gain;

  const Best50OpportunityTier({
    required this.achievement,
    required this.rank,
    required this.rating,
    required this.gain,
  });
}

/// 分档展示从 100.5% 到最低可推分的达成率每一档的提升，[tiers] 按传入顺序显示。
Future<void> showBest50OpportunityDialog(
  BuildContext context, {
  required String note,
  required List<Best50OpportunityTier> tiers,
}) {
  const rowHeight = 44.0;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      final green = AppColors.successGreen(scheme.brightness);
      return AppDialog(
        title: context.l10n.flowRatingPotential,
        icon: Icons.trending_up_rounded,
        tone: AppDialogTone.success,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note),
            const SizedBox(height: 10),
            // 档数可能上百，按需构建；高度固定，列表自己滚动。
            SizedBox(
              height: math.min(tiers.length * rowHeight, rowHeight * 7.5),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: tiers.length,
                separatorBuilder: (_, __) => Divider(
                    height: 1, color: AppSurfaces.hairline(dialogContext)),
                itemBuilder: (_, index) {
                  final tier = tiers[index];
                  return SizedBox(
                    height: rowHeight - 1,
                    child: Row(
                      children: [
                        RankBadge(rank: tier.rank, uniformWidth: true),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${tier.achievement.toStringAsFixed(4)}%',
                              style: AppTheme.number(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'RA ${tier.rating}',
                          style: AppTheme.number(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '+${tier.gain}',
                            textAlign: TextAlign.end,
                            style: AppTheme.number(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.featureClose),
          ),
        ],
      );
    },
  );
}

// ---------------------------------------------------------------------------
// 末尾同分谱面自选
// ---------------------------------------------------------------------------

bool _sameStringSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

/// 榜单顶部的「末尾同分自选」入口条。
class Best50TiePickerBar extends StatelessWidget {
  final String label;
  final int selectedCount;
  final int totalCount;
  final bool customized;
  final VoidCallback onTap;

  const Best50TiePickerBar({
    super.key,
    required this.label,
    required this.selectedCount,
    required this.totalCount,
    required this.customized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return PressScale(
      scale: 0.985,
      child: Material(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.best50TieSelectEntry,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (customized) ...[
                            const SizedBox(width: 6),
                            AppBadge(
                              text: l10n.best50TieCustomizedBadge,
                              background:
                                  scheme.primary.withValues(alpha: 0.14),
                              foreground: scheme.primary,
                              numeric: false,
                              fontSize: 10.5,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.best50TieSelectSummary(
                            label, totalCount, selectedCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.best50TieSelectAction,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: scheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 弹出末尾同分谱面多选弹窗；取消返回 null，确认返回恰好含 [slotCount] 个键的集合。
Future<Set<String>?> showBest50TieSelectionDialog(
  BuildContext context, {
  required List<Best50CardData> candidates,
  required List<String> candidateKeys,
  required Set<String> initialSelectedKeys,
  required Set<String> defaultKeys,
  required int slotCount,
  required String label,
  String? segmentTitle,
}) {
  final selected = Set<String>.of(initialSelectedKeys);
  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final l10n = dialogContext.l10n;
        final scheme = Theme.of(dialogContext).colorScheme;
        final brightness = Theme.of(dialogContext).brightness;
        final complete = selected.length == slotCount;
        final isDefault = _sameStringSet(selected, defaultKeys);
        final titleText = segmentTitle != null && segmentTitle.isNotEmpty
            ? '$segmentTitle · ${l10n.best50TieSelectTitle}'
            : l10n.best50TieSelectTitle;
        return AppAlertDialog(
          icon: const Icon(Icons.tune_rounded),
          title: Text(titleText),
          subtitle: l10n.best50TieSelectDialogHint(
              slotCount, label, selected.length),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AppBadge(
                      text: '${selected.length} / $slotCount',
                      background: complete
                          ? scheme.primary.withValues(alpha: 0.14)
                          : AppColors.warningOrange(brightness)
                              .withValues(alpha: 0.15),
                      foreground: complete
                          ? scheme.primary
                          : AppColors.warningOrange(brightness),
                      fontSize: 12,
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: isDefault
                          ? null
                          : () => setDialogState(() {
                                selected
                                  ..clear()
                                  ..addAll(defaultKeys);
                              }),
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: Text(l10n.best50TieResetDefault),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.50,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, index) {
                      final data = candidates[index];
                      final key = candidateKeys[index];
                      final checked = selected.contains(key);
                      final sub =
                          '${data.difficultyLabel} ${data.dsText} · ${data.achievementText} · RA ${data.rating}'
                          '${data.badge != null ? ' · ${data.badge}' : ''}';
                      return Material(
                        color: checked
                            ? scheme.primary.withValues(alpha: 0.10)
                            : AppSurfaces.inset(ctx),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                          side: BorderSide(
                            color: checked
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          splashFactory: NoSplash.splashFactory,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            if (checked) {
                              setDialogState(() => selected.remove(key));
                            } else if (slotCount == 1) {
                              setDialogState(() {
                                selected
                                  ..clear()
                                  ..add(key);
                              });
                            } else if (selected.length < slotCount) {
                              setDialogState(() => selected.add(key));
                            } else {
                              AppToast.show(
                                l10n.best50TieSelectionFull(slotCount),
                                tone: AppToastTone.warning,
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radiusSmall),
                                  child: CoverUtil.buildCoverWidgetWithContext(
                                      ctx, data.songId.toString(), 44),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          SongTypeBadge(
                                            songId: data.songId.toString(),
                                            type: data.type,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: MarqueeText(
                                              text: data.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                                color: scheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sub,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: data.onOpenSong,
                                  tooltip: l10n.flowViewSongDetails,
                                  visualDensity: VisualDensity.compact,
                                  iconSize: 18,
                                  icon: Icon(
                                    Icons.open_in_new_rounded,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Icon(
                                  checked
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 22,
                                  color: checked
                                      ? scheme.primary
                                      : scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, null),
              child: Text(l10n.featureCancel),
            ),
            FilledButton(
              onPressed: complete
                  ? () => Navigator.pop(dialogContext, Set<String>.of(selected))
                  : null,
              child: Text(l10n.featureOK),
            ),
          ],
        );
      },
    ),
  );
}

/// 导出弹窗中一个分段的同分自选项。
class Best50ExportTieItem {
  final String segment;
  final String label;
  final int selectedCount;
  final int totalCount;
  final bool customized;
  final Future<void> Function() onTap;

  const Best50ExportTieItem({
    required this.segment,
    required this.label,
    required this.selectedCount,
    required this.totalCount,
    required this.customized,
    required this.onTap,
  });
}

/// 导出弹窗内的「末尾同分谱面组成」区域，样式与雷霆模式面板一致。
class Best50ExportTieSection extends StatelessWidget {
  final List<Best50ExportTieItem> items;
  final VoidCallback onUpdated;

  const Best50ExportTieSection({
    super.key,
    required this.items,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.best50TieExportSectionTitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, color: AppSurfaces.hairline(context)),
            InkWell(
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              onTap: () async {
                await items[i].onTap();
                onUpdated();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.best50TieExportSegmentSummary(
                          items[i].segment,
                          items[i].label,
                          items[i].selectedCount,
                          items[i].totalCount,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (items[i].customized) ...[
                      const SizedBox(width: 6),
                      AppBadge(
                        text: l10n.best50TieCustomizedBadge,
                        background: scheme.primary.withValues(alpha: 0.14),
                        foreground: scheme.primary,
                        numeric: false,
                        fontSize: 10,
                      ),
                    ],
                    const SizedBox(width: 6),
                    Text(
                      l10n.best50TieSelectAction,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
