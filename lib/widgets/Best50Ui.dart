import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/ColorUtil.dart';
import '../utils/CoverUtil.dart';
import '../utils/StringUtil.dart';
import 'AppUi.dart';

/// Best50 系列页共用的界面组件。
///
/// 页面结构：[Best50Hero]（大数字 + 构成条）→ B35 / B15 分段 → 一行摘要 →
/// [Best50Grid]（三列曲绘卡）；点卡片弹 [showBest50SongSheet]。
///
/// 卡片只用于屏幕显示。导出图片仍由 `B50GameCardWidget` 绘制，两者互不影响。

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
              Flexible(
                flex: 3,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    label: '$label $total',
                    excludeSemantics: true,
                    child: Text(
                      '$total',
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
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (d != null)
                        Text(
                          d >= 0 ? '+$d' : '$d',
                          style: AppTheme.number(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: d >= 0
                                ? AppColors.successGreen(theme.brightness)
                                : AppColors.errorRed(theme.brightness),
                          ),
                        ),
                      Text(label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)),
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

/// 顶部栏右侧的圆形图标按钮（历史、导出……）。
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: AppSurfaces.card(context),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          fixedSize: const Size(44, 44),
        ),
        icon: Icon(icon, size: 20),
      ),
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
  if (ratings.isEmpty) return '$name 0 首';
  final list = ratings.toList();
  final min = list.reduce((a, b) => a < b ? a : b);
  final avg = list.fold<int>(0, (a, b) => a + b) / list.length;
  return '$name ${list.length} 首 · 最低 $min · 平均 ${avg.toStringAsFixed(1)} · 点卡片看推分空间';
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
                      child: Text(widget.title,
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
                  Text('DX ${(row.scoreRate * 100).toStringAsFixed(2)}%',
                      style:
                          numStyle.copyWith(color: scheme.onSurfaceVariant)),
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

/// 三列曲绘卡网格。卡片高度按宽度和系统字号算，不会被压扁。
///
/// [extraCell] 放在最后一格（理论模式的「查看剩余」）。
class Best50Grid extends StatelessWidget {
  final List<Best50CardData> items;
  final Widget? extraCell;

  const Best50Grid({super.key, required this.items, this.extraCell});

  /// 单元格高度（自定义 Best50 的网格也用它）。
  static SliverGridDelegate delegate(
      BuildContext context, double maxWidth) {
    const gap = 10.0;
    final columns = maxWidth >= 600 ? 5 : 3;
    final w = (maxWidth - gap * (columns - 1)) / columns;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      crossAxisSpacing: gap,
      mainAxisSpacing: gap,
      mainAxisExtent: w + 17 + 39 * textScale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = items.length + (extraCell == null ? 0 : 1);
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: delegate(context, constraints.maxWidth),
        itemCount: count,
        itemBuilder: (context, index) {
          if (index >= items.length) return extraCell!;
          final data = items[index];
          return Best50CoverCard(
            data: data,
            rank: index + 1,
            onTap: () => showBest50SongSheet(context, data),
          );
        },
      ),
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

  const Best50CoverCard({
    super.key,
    required this.data,
    required this.rank,
    required this.onTap,
    this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fcLabel = _comboLabel(data.fc);
    return Semantics(
      button: true,
      label: '第 $rank 名，${data.title}，Rating ${data.rating}',
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
                    if (data.badge != null || fcLabel != null)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: _CoverPill(text: data.badge ?? fcLabel!),
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

/// 接口里的 `fc` / `fs` 值 → 显示文字（`fcp` → `FC+`）。
String? _comboLabel(String raw) {
  switch (raw) {
    case '':
      return null;
    case 'app':
      return 'AP+';
    case 'ap':
      return 'AP';
    case 'fcp':
      return 'FC+';
    case 'fc':
      return 'FC';
    case 'fsp':
      return 'FS+';
    case 'fs':
      return 'FS';
    case 'fsdp':
      return 'FDX+';
    case 'fsd':
      return 'FDX';
    case 'sync':
      return 'SYNC';
    default:
      return raw.toUpperCase();
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
      final next = best50NextTier((ds: data.ds, achievement: data.achievement));
      final success = AppColors.comboBadge('FC', brightness);
      final rank = StringUtil.rateCodeFromAchievement(data.achievement);
      final fcLabel = _comboLabel(data.fc);
      final fsLabel = _comboLabel(data.fs);
      final syncColors = AppColors.syncBadge(brightness);

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
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: foreground ?? scheme.onSurfaceVariant)),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                                '${data.difficultyLabel} · ${data.type} · 定数 ${data.dsText}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                  tile(label: '达成率', value: data.achievementText),
                  const SizedBox(width: 10),
                  next == null
                      ? tile(label: '推分空间', value: '已到单曲上限')
                      : tile(
                          label: '推到 ${next.$1}（${next.$2}%）',
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
                  if (fcLabel != null) ComboBadge(text: fcLabel),
                  if (fsLabel != null)
                    AppBadge(
                      text: fsLabel,
                      background: syncColors.background,
                      foreground: syncColors.foreground,
                    ),
                  if (data.stars.isNotEmpty) StarBadge(stars: data.stars),
                  if (data.maxDxScore > 0)
                    Text('DX ${data.dxScore} / ${data.maxDxScore}',
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
                  child: const Text('查看歌曲详情',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
