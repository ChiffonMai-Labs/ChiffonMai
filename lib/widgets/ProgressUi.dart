import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ColorUtil.dart';
import '../utils/CoverUtil.dart';
import 'AppUi.dart';
import 'MarqueeText.dart';
import 'SmoothLinearProgressIndicator.dart';

/// 「个性化成绩查询」和「牌子进度」共用的部件：筛选行、完成度总览、展示切换、
/// 分组标题和歌曲行。两页的数据来源不同，但完成度的展示方式是同一套。

/// 筛选卡片里的小标题。
class ProgressFieldLabel extends StatelessWidget {
  final String text;

  const ProgressFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// 点开选择器的一行：凹槽底 + 当前值 + 箭头。
class ProgressPickerField extends StatelessWidget {
  final String value;
  final VoidCallback onTap;

  const ProgressPickerField(
      {super.key, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: AppSurfaces.inset(context),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: MarqueeText(
                  text: value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded,
                  size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// 称号类型胶囊：选中色比默认的次级容器色深一点，一眼能看出选了哪个。
class ProgressTitlePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ProgressTitlePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterPill(
      label: label,
      selected: selected,
      onTap: onTap,
      selectedColor: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.25), scheme.secondaryContainer),
    );
  }
}

/// 难度胶囊：选中时填充该难度的索引色，ALL（-1）用主题色。
class ProgressDifficultyPill extends StatelessWidget {
  final int difficulty;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ProgressDifficultyPill({
    super.key,
    required this.difficulty,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = difficulty < 0
        ? Theme.of(context).colorScheme.primary
        : ColorUtil.getCardColor(difficulty);
    return FilterPill(
      label: label,
      selected: selected,
      onTap: onTap,
      selectedColor: color,
      selectedForeground:
          ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white
              : Colors.black87,
    );
  }
}

/// 完成度总览：大号完成率 + 进度条 + 四项统计。
class ProgressSummaryCard extends StatelessWidget {
  static const double _statValueSize = 17;

  final String title;
  final int total;
  final int completed;
  final double averageAchievement;

  const ProgressSummaryCard({
    super.key,
    required this.title,
    required this.total,
    required this.completed,
    required this.averageAchievement,
  });

  Widget _rollingStat(String label, num value,
          {int fractionDigits = 0, String suffix = ''}) =>
      Builder(
        builder: (context) => StatTile(
          label: label,
          value: '${value.toStringAsFixed(fractionDigits)}$suffix',
          valueWidget: RollingNumber(
            value: value,
            fractionDigits: fractionDigits,
            suffix: suffix,
            style: AppTheme.number(
              fontSize: _statValueSize,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rate = total > 0 ? completed / total : 0.0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              RollingNumber(
                value: rate * 100,
                fractionDigits: 1,
                suffix: '%',
                style: AppTheme.number(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '完成率',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SmoothLinearProgressIndicator(
            value: rate,
            minHeight: 8,
            color: scheme.primary,
            backgroundColor: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _rollingStat('总数', total)),
              Expanded(child: _rollingStat('已完成', completed)),
              Expanded(child: _rollingStat('未完成', total - completed)),
              Expanded(
                  flex: 2,
                  child: _rollingStat('平均达成率', averageAchievement,
                      fractionDigits: 2, suffix: '%')),
            ],
          ),
        ],
      ),
    );
  }
}

/// 展示切换：完成状态筛选占一行，分组方式和列表 / 曲绘并排一行。
class ProgressDisplayControls extends StatelessWidget {
  /// `all` / `completed` / `uncompleted`。
  final String filterMode;
  final bool useLevelDisplay;
  final bool showListMode;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<bool> onLevelDisplayChanged;
  final ValueChanged<bool> onListModeChanged;

  const ProgressDisplayControls({
    super.key,
    required this.filterMode,
    required this.useLevelDisplay,
    required this.showListMode,
    required this.onFilterChanged,
    required this.onLevelDisplayChanged,
    required this.onListModeChanged,
  });

  static const _filters = ['all', 'completed', 'uncompleted'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedTabs(
          height: 40,
          items: const [
            SegmentedTabItem('全部'),
            SegmentedTabItem('已完成'),
            SegmentedTabItem('未完成'),
          ],
          selectedIndex: _filters.indexOf(filterMode).clamp(0, 2),
          onChanged: (index) => onFilterChanged(_filters[index]),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SegmentedTabs(
                height: 40,
                items: const [
                  SegmentedTabItem('按等级'),
                  SegmentedTabItem('按定数'),
                ],
                selectedIndex: useLevelDisplay ? 0 : 1,
                onChanged: (index) => onLevelDisplayChanged(index == 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SegmentedTabs(
                height: 40,
                items: const [
                  SegmentedTabItem('列表'),
                  SegmentedTabItem('曲绘'),
                ],
                selectedIndex: showListMode ? 0 : 1,
                onChanged: (index) => onListModeChanged(index == 0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 一组歌曲（同一等级 / 定数）的标题。
class ProgressGroupHeader extends StatelessWidget {
  final String title;
  final int count;

  const ProgressGroupHeader(
      {super.key, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Text(
            title,
            style: AppTheme.number(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const Spacer(),
          Text(
            '$count 首',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 列表模式的一行：曲绘 + 类型标签和曲名 + 难度标签和定数 + 完成状态。
/// 放在同一张白卡片里，除第一行外带分隔线（[showDivider]）。
class ProgressSongRow extends StatelessWidget {
  final String songId;
  final String title;

  /// 曲库的 `DX` / `SD`，或落雪的 `dx` / `standard`。
  final String songType;
  final int levelIndex;

  /// 已格式化的定数，没有时为空串。
  final String constant;
  final bool completed;

  /// 条件外曲目：不计入完成度，状态显示成「不计入条件」。
  final bool excluded;
  final bool showDivider;
  final VoidCallback onTap;

  const ProgressSongRow({
    super.key,
    required this.songId,
    required this.title,
    required this.songType,
    required this.levelIndex,
    required this.constant,
    required this.completed,
    required this.onTap,
    this.excluded = false,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusColor = completed && !excluded
        ? scheme.primary
        : scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: AppSurfaces.hairline(context)))
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: CoverUtil.buildCoverWidget(songId, 44),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SongTypeBadge(
                        songId: songId,
                        type: songType.toUpperCase() == 'DX' ? 'DX' : 'SD',
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: MarqueeText(
                          text: title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ChartDifficultyBadge(
                          levelIndex: levelIndex, songId: songId),
                      if (constant.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          constant,
                          style: AppTheme.number(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              excluded
                  ? Icons.remove_circle_outline
                  : (completed ? Icons.check_circle : Icons.circle_outlined),
              size: 18,
              color: statusColor,
            ),
            const SizedBox(width: 4),
            Text(
              excluded ? '不计入' : (completed ? '已完成' : '未完成'),
              style: TextStyle(fontSize: 11, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// 曲绘模式的一格：边框是难度色，已完成的盖一层半透明和对钩。
class ProgressCoverTile extends StatelessWidget {
  final String songId;
  final int levelIndex;
  final bool completed;
  final VoidCallback onTap;

  const ProgressCoverTile({
    super.key,
    required this.songId,
    required this.levelIndex,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDesignTokens.radiusSmall);
    return PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverUtil.buildCoverWidget(songId, constraints.maxWidth),
                if (completed)
                  ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Center(
                      child: Icon(Icons.check_circle_rounded,
                          color: Colors.white,
                          size: constraints.maxWidth * 0.42),
                    ),
                  ),
                // 难度边框放最上层，不被完成状态盖住
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                        color: ColorUtil.getCoverBorderColor(levelIndex),
                        width: 2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 曲绘模式的网格：一组一个，放在白卡片里。
class ProgressCoverGrid extends StatelessWidget {
  final List<Widget> children;

  const ProgressCoverGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      radius: AppDesignTokens.radiusMedium,
      child: GridView.count(
        crossAxisCount: 5,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

/// 按需构建的列表里，同一组的行各画一段白底，首尾带圆角，连起来就是一张卡片。
class GroupedRowShell extends StatelessWidget {
  final bool first;
  final bool last;
  final Widget child;

  const GroupedRowShell({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(AppDesignTokens.radiusMedium);
    return Material(
      color: AppSurfaces.card(context),
      clipBehavior: first || last ? Clip.antiAlias : Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: first ? radius : Radius.zero,
          bottom: last ? radius : Radius.zero,
        ),
      ),
      child: child,
    );
  }
}

/// 一个等级 / 定数分组。
class ProgressSongGroup {
  final String title;
  final List<Map<String, dynamic>> items;

  const ProgressSongGroup({required this.title, required this.items});
}

/// 分组歌曲列表（列表模式 / 曲绘模式）。
///
/// 只构建屏幕内的行：几千首也不会在结果到达时卡一下。放在 CustomScrollView 里用，
/// 不要包回 Column —— Column 会一次性布局全部歌曲，那正是之前卡顿的原因。
class ProgressSongSliver extends StatelessWidget {
  static const int _coversPerRow = 5;

  final List<ProgressSongGroup> groups;
  final bool showListMode;
  final Widget Function(Map<String, dynamic> item, bool showDivider) rowBuilder;
  final Widget Function(Map<String, dynamic> item) coverBuilder;

  const ProgressSongSliver({
    super.key,
    required this.groups,
    required this.showListMode,
    required this.rowBuilder,
    required this.coverBuilder,
  });

  Widget _coverRow(BuildContext context, List<Map<String, dynamic>> items,
      {required bool first, required bool last}) {
    const spacing = 6.0;
    const edge = 10.0;
    return LayoutBuilder(builder: (context, constraints) {
      final tile = (constraints.maxWidth -
              edge * 2 -
              spacing * (_coversPerRow - 1)) /
          _coversPerRow;
      final top = first ? edge : 0.0;
      final bottom = last ? edge : spacing;
      return GroupedRowShell(
        first: first,
        last: last,
        // 行高取整，相邻两段白底之间不会露出一条细缝。
        child: SizedBox(
          height: (top + tile + bottom).ceilToDouble(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(edge, top, edge, 0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: spacing),
                    SizedBox(
                        width: tile,
                        height: tile,
                        child: coverBuilder(items[i])),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = <Widget Function(BuildContext)>[];
    for (final group in groups) {
      entries.add((_) =>
          ProgressGroupHeader(title: group.title, count: group.items.length));
      final items = group.items;
      if (showListMode) {
        for (var i = 0; i < items.length; i++) {
          entries.add((context) => GroupedRowShell(
                first: i == 0,
                last: i == items.length - 1,
                child: rowBuilder(items[i], i > 0),
              ));
        }
      } else {
        for (var i = 0; i < items.length; i += _coversPerRow) {
          final end = (i + _coversPerRow).clamp(0, items.length).toInt();
          entries.add((context) => _coverRow(
                context,
                items.sublist(i, end),
                first: i == 0,
                last: end == items.length,
              ));
        }
      }
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.gutter),
      sliver: SliverList.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) => entries[index](context),
      ),
    );
  }
}

/// 换一批内容时整体淡入；[key] 变化时重播。
class ProgressSliverFade extends StatelessWidget {
  final Widget sliver;

  const ProgressSliverFade({super.key, required this.sliver});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          AppDesignTokens.motion(context, const Duration(milliseconds: 260)),
      curve: Curves.easeOut,
      builder: (context, value, child) =>
          SliverOpacity(opacity: value, sliver: child),
      child: sliver,
    );
  }
}

/// 歌曲列表加载中的骨架屏：统计区留在上面继续显示，等待时也能继续改筛选。
class ProgressListSkeleton extends StatefulWidget {
  const ProgressListSkeleton({super.key});

  @override
  State<ProgressListSkeleton> createState() => _ProgressListSkeletonState();
}

class _ProgressListSkeletonState extends State<ProgressListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
      vsync: this,
      lowerBound: 0.45,
      upperBound: 1,
      value: 1,
      duration: const Duration(milliseconds: 800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _bar(double? width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppSurfaces.inset(context),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );

  Widget _row(bool divider) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: divider
          ? BoxDecoration(
              border: Border(top: BorderSide(color: scheme.outlineVariant)))
          : null,
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(widthFactor: 0.7, child: _bar(null, 13)),
              const SizedBox(height: 8),
              FractionallySizedBox(widthFactor: 0.35, child: _bar(null, 10)),
            ],
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '正在加载',
      child: FadeTransition(
        opacity: _pulse,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              radius: AppDesignTokens.radiusMedium,
              child: Column(children: [
                for (var i = 0; i < 8; i++) _row(i > 0),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
