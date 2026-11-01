import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ColorUtil.dart';
import '../utils/StringUtil.dart';

/// 2026-11 UI 重构（B 方案）的公共组件。
///
/// 设计语言：页面底 → 无描边的白卡片（[AppCard]）→ 卡内凹槽（[AppSurfaces.inset]）；
/// 数字用 [AppTheme.number]（Outfit 等宽数字），中文用全局思源黑体。
/// 颜色全部取自 ColorScheme / [AppColors]，跟随用户的主题色、深色与纯黑模式。
///
/// 新页面优先用这里的组件；需要新组件时也加在这个文件里，别在页面里各写一份。

// ---------------------------------------------------------------------------
// 卡片
// ---------------------------------------------------------------------------

/// 主内容卡片。默认无描边；放在用户自定义背景图上、需要更强边界时传 [outlined]。
///
/// 底色与水波纹画在自己这层 [Material] 上（原因见 `HubQuickAction` 的注释：
/// 用 Ink 会被画到滚动变换之外）。
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final bool outlined;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppDesignTokens.cardPadding,
    this.onTap,
    this.radius = AppDesignTokens.radiusCard,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(padding: padding, child: child);
    return Material(
      color: color ?? AppSurfaces.card(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: outlined
            ? BorderSide(color: scheme.outlineVariant)
            : BorderSide.none,
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// 卡片 / 分组上方的小标题行：标题 + 可选说明 + 右侧操作。
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(4, 0, 4, 8),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 徽章
// ---------------------------------------------------------------------------

/// 小号圆角徽章。[numeric] 为 true 时用数字字体（评级、FC 这类拉丁缩写）。
class AppBadge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final bool numeric;
  final double fontSize;

  const AppBadge({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
    this.numeric = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        style: numeric
            ? AppTheme.number(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: foreground,
              )
            : TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
      ),
    );
  }
}

/// 评级徽章（SSS+ / SS / S+ …），颜色见 [AppColors.rankBadge]。
class RankBadge extends StatelessWidget {
  final String rank;
  final double fontSize;

  const RankBadge({super.key, required this.rank, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.rankBadge(rank, Theme.of(context).brightness);
    return AppBadge(
      text: rank,
      background: c.background,
      foreground: c.foreground,
      fontSize: fontSize,
    );
  }
}

/// 连击（FC/AP）或同步（FS/FDX）徽章。
class ComboBadge extends StatelessWidget {
  final String text;
  final bool sync;

  const ComboBadge({super.key, required this.text, this.sync = false});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final c = sync
        ? AppColors.syncBadge(brightness)
        : AppColors.comboBadge(text, brightness);
    return AppBadge(
      text: text.toUpperCase(),
      background: c.background,
      foreground: c.foreground,
    );
  }
}

// ---------------------------------------------------------------------------
// 数字
// ---------------------------------------------------------------------------

/// 「标签 + 大数字」统计块。[card] 为 true 时自带白卡片底。
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool card;
  final double valueSize;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.card = false,
    this.valueSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.number(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: valueColor ?? scheme.onSurface,
          ),
        ),
      ],
    );
    if (!card) return body;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: body,
    );
  }
}

/// 两段占比条（例：B35 / B15 占总 Rating 的比例）。数值变化时平滑过渡。
class SplitBar extends StatelessWidget {
  final double fraction;
  final Color primary;
  final Color secondary;
  final double height;

  const SplitBar({
    super.key,
    required this.fraction,
    required this.primary,
    required this.secondary,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final target = fraction.isFinite ? fraction.clamp(0.0, 1.0).toDouble() : 0.0;
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target),
        duration: AppDesignTokens.motion(context, AppDesignTokens.slowMotion),
        curve: AppDesignTokens.emphasizedCurve,
        builder: (context, value, _) {
          final left = (value * 1000).round().clamp(1, 999).toInt();
          return SizedBox(
            height: height,
            child: Row(
              children: [
                Expanded(
                  flex: left,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  flex: 1000 - left,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: secondary,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 分段切换
// ---------------------------------------------------------------------------

class SegmentedTabItem {
  final String label;

  /// 第二行的小数字（例：该音符类型的数量）。
  final String? caption;

  const SegmentedTabItem(this.label, {this.caption});
}

/// 带滑动指示块的分段切换。系统开启「减少动态效果」时直接跳到目标位置。
class SegmentedTabs extends StatelessWidget {
  final List<SegmentedTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;

  const SegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final selectedColor =
        dark ? scheme.secondaryContainer : AppSurfaces.card(context);
    final selectedText = dark ? scheme.onSecondaryContainer : scheme.onSurface;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / items.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: duration,
                curve: AppDesignTokens.emphasizedCurve,
                left: selectedIndex * w,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == selectedIndex,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (i != selectedIndex) onChanged(i);
                          },
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  items[i].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: i == selectedIndex
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: i == selectedIndex
                                        ? selectedText
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                if (items[i].caption != null)
                                  Text(
                                    items[i].caption!,
                                    maxLines: 1,
                                    style: AppTheme.number(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: i == selectedIndex
                                          ? selectedText
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 数量输入
// ---------------------------------------------------------------------------

/// 「− 数字 +」计数输入：既能点按加减，也能直接点数字打字。
///
/// 受控组件：数值由页面持有，[onChanged] 回调后页面 setState 即可。
/// 打字过程中允许暂时为空，失焦时空值补回 0（与旧表格输入的行为一致）。
class CountField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int max;

  /// 读屏用的名字，例如「TAP GREAT 数量」。
  final String semanticLabel;

  const CountField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.max = 99999,
  });

  @override
  State<CountField> createState() => _CountFieldState();
}

class _CountFieldState extends State<CountField> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant CountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shown = int.tryParse(_controller.text);
    final editingEmpty = _controller.text.isEmpty && _focus.hasFocus;
    if (!editingEmpty && shown != widget.value) {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      if (widget.value == 0) {
        _controller.clear();
      } else {
        _controller.selection = TextSelection(
            baseOffset: 0, extentOffset: _controller.text.length);
      }
    } else if (_controller.text.isEmpty) {
      _controller.text = '0';
      if (widget.value != 0) widget.onChanged(0);
    }
  }

  void _step(int delta) {
    final next = (widget.value + delta).clamp(0, widget.max).toInt();
    if (next == widget.value) return;
    _controller.text = '$next';
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: '${widget.semanticLabel}减一',
            onPressed: widget.value > 0 ? () => _step(-1) : null,
          ),
          SizedBox(
            width: 58,
            child: Semantics(
              label: widget.semanticLabel,
              textField: true,
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                ],
                style: AppTheme.number(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.value == 0
                      ? scheme.onSurfaceVariant
                      : scheme.onSurface,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (text) {
                  final parsed = int.tryParse(text) ?? 0;
                  widget.onChanged(parsed.clamp(0, widget.max).toInt());
                },
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: '${widget.semanticLabel}加一',
            onPressed: widget.value < widget.max ? () => _step(1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icon),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 判定行
// ---------------------------------------------------------------------------

/// 计算器里的一行：左侧判定色条 + 名称 + 说明，右侧数量输入。
class JudgeCountRow extends StatelessWidget {
  final String label;
  final String? detail;
  final Color? detailColor;
  final Color color;
  final int value;
  final ValueChanged<int> onChanged;
  final bool showDivider;

  const JudgeCountRow({
    super.key,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
    this.detail,
    this.detailColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: showDivider
            ? Border(top: BorderSide(color: AppSurfaces.hairline(context)))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 8, 6),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(3)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: detailColor ?? scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            CountField(
              value: value,
              onChanged: onChanged,
              semanticLabel: '$label 数量',
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 底部操作栏
// ---------------------------------------------------------------------------

/// 贴底操作栏：白底 + 顶部柔和阴影，自动让出系统手势条。
class BottomActionBar extends StatelessWidget {
  final List<Widget> children;

  const BottomActionBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: Row(children: children),
    );
  }
}

/// 计算结果这类「强调卡片」：反色底（浅色模式深底白字，深色模式浅底深字）。
class EmphasisCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const EmphasisCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusLarge),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: scheme.onInverseSurface),
        child: IconTheme.merge(
          data: IconThemeData(color: scheme.onInverseSurface),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 拼贴入口
// ---------------------------------------------------------------------------

/// Hub 页顶部「卡片拼贴」里的一格：图标 + 标题 + 一行说明。
///
/// [emphasis] 为 true 时用反色底（与 [EmphasisCard] 同色），整块拼贴里只给
/// 最主要的那个入口用；[compact] 用于一行三格的小方块（图标在上、只留标题）。
/// 高度由外层决定（`SizedBox` / `Expanded`），内容贴底对齐。
class AppCollageTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool emphasis;
  final bool compact;

  const AppCollageTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.emphasis = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = emphasis ? scheme.onInverseSurface : scheme.onSurface;
    final muted = emphasis
        ? scheme.onInverseSurface.withValues(alpha: 0.72)
        : scheme.onSurfaceVariant;
    final iconBg = emphasis
        ? scheme.onInverseSurface.withValues(alpha: 0.12)
        : scheme.primaryContainer;
    final iconFg = emphasis ? scheme.onInverseSurface : scheme.onPrimaryContainer;

    return Semantics(
      button: true,
      label: subtitle == null ? title : '$title，$subtitle',
      excludeSemantics: true,
      child: AppCard(
        onTap: onTap,
        color: emphasis ? scheme.inverseSurface : null,
        radius: emphasis
            ? AppDesignTokens.radiusLarge
            : AppDesignTokens.radiusCard,
        padding: compact
            ? const EdgeInsets.fromLTRB(12, 14, 12, 12)
            : const EdgeInsets.all(16),
        child: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                child: Icon(icon, size: compact ? 18 : 20, color: iconFg),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: emphasis ? 20 : (compact ? 13 : 15),
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              if (subtitle != null && !compact) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: emphasis ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, height: 1.3, color: muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Best50 系列
// ---------------------------------------------------------------------------

/// Rating 段位小标签（渐变底），首页总览卡与 Best50 汇总卡共用。
class RatingTierChip extends StatelessWidget {
  final int rating;

  const RatingTierChip({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final tier = AppColors.ratingTier(rating);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: tier.colors),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(
        tier.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: tier.foreground,
        ),
      ),
    );
  }
}

/// [Best50SummaryCard] 下方的一行平均值：达成率 / DX 分数达成率 / 星级。
class Best50AverageRow {
  final String label;
  final double achievement;

  /// DX 分数达成率，0~1。
  final double scoreRate;

  const Best50AverageRow(this.label, this.achievement, this.scoreRate);
}

/// Best50 系列页顶部的汇总卡：大号总 Rating + B35 / B15 构成条 + 平均值。
///
/// 只负责展示，数值由各页面自己算好传进来（各页的口径略有不同：
/// 理论模式、拟合定数、个性化筛选），这里不做任何计算。
class Best50SummaryCard extends StatelessWidget {
  final String label;
  final int rating;
  final double ratingAverage;
  /// B35 / B15 构成；任一为 null 时不显示构成条（例如拟合 Best50 模式 A）。
  final int? best35Sum;
  final double? best35Average;
  final int? best15Sum;
  final double? best15Average;
  final List<Best50AverageRow> averages;

  /// 卡片最下方的附加内容（差值、说明文字等），按顺序竖排。
  final List<Widget> footer;

  /// 是否显示段位标签（拟合 / 理论这类非官方口径传 false）。
  final bool showTier;

  /// 「B35 / B15」的叫法，个性化 BestN 页可以改成别的。
  final String best35Label;
  final String best15Label;

  const Best50SummaryCard({
    super.key,
    this.label = 'Rating',
    required this.rating,
    required this.ratingAverage,
    this.best35Sum,
    this.best35Average,
    this.best15Sum,
    this.best15Average,
    this.averages = const [],
    this.footer = const [],
    this.showTier = true,
    this.best35Label = 'B35',
    this.best15Label = 'B15',
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b35 = best35Sum, b15 = best15Sum;
    final hasSplit = b35 != null && b15 != null;
    final total = hasSplit ? b35 + b15 : 0;
    final secondary = scheme.primary.withValues(alpha: 0.32);

    Widget metric(String name, int sum, double avg, Color dot) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(name,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(width: 6),
            Text('$sum',
                style: AppTheme.number(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface)),
            const SizedBox(width: 4),
            Text('均 ${avg.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
          ],
        );

    return AppCard(
      radius: AppDesignTokens.radiusLarge,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant)),
              if (showTier && rating > 0) ...[
                const SizedBox(width: 8),
                RatingTierChip(rating: rating),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$rating',
                style: AppTheme.number(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -1,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text('平均 ${ratingAverage.toStringAsFixed(1)}',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
          if (hasSplit) ...[
            const SizedBox(height: 10),
            SplitBar(
              fraction: total > 0 ? b35 / total : 0.7,
              primary: scheme.primary,
              secondary: secondary,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                metric(best35Label, b35, best35Average ?? 0, scheme.primary),
                metric(best15Label, b15, best15Average ?? 0, secondary),
              ],
            ),
          ],
          if (averages.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusMedium),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < averages.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: AppSurfaces.hairline(context)),
                    _Best50AverageLine(row: averages[i]),
                  ],
                ],
              ),
            ),
          ],
          for (final w in footer) ...[
            const SizedBox(height: 10),
            w,
          ],
        ],
      ),
    );
  }
}

class _Best50AverageLine extends StatelessWidget {
  final Best50AverageRow row;

  const _Best50AverageLine({required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stars = StringUtil.formatStars(row.scoreRate);
    final numStyle = AppTheme.number(
        fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
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
                  StarBadge(stars: stars),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Best50 页里 Best35 / Best15 网格上方的标题。
///
/// 旧标题是一整行 `Best35 | 非当前版本最好成绩`：按 ` | ` 拆成标题 + 说明，
/// 没有分隔符时整行当标题。
class Best50SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const Best50SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final parts = title.split(' | ');
    return AppSectionHeader(
      title: parts.first.trim(),
      subtitle: parts.length > 1 ? parts.sublist(1).join(' | ').trim() : null,
      trailing: trailing,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
    );
  }
}

/// Best50 系列页的操作按钮（保存 / 历史 / 导出图片 / 切换模式）。
///
/// [primary] 为 true 用主题色实心按钮（每页只给最主要的「导出」），
/// 其余用白卡片底的次级按钮。
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
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium));
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 14);
    final child = Row(
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
    );
    return FilledButton(
      onPressed: onPressed,
      style: primary
          ? FilledButton.styleFrom(shape: shape, padding: padding)
          : FilledButton.styleFrom(
              shape: shape,
              padding: padding,
              backgroundColor: AppSurfaces.card(context),
              foregroundColor: scheme.onSurface,
            ),
      child: child,
    );
  }
}

/// 星级徽章（`✦5` 这类）：底色取游戏内的星级配色（[ColorUtil.getStarsColor]），
/// 字固定深色。
///
/// 不直接把星级色当字色：黄 / 金 / 浅绿放在白卡片上几乎看不见。
class StarBadge extends StatelessWidget {
  final String stars;
  final double fontSize;

  const StarBadge({super.key, required this.stars, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final bg = ColorUtil.getStarsColor(stars);
    // 没有星级（getStarsColor 回落到白色）时用凹槽色，免得白底上一块白
    final isEmpty = bg == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: isEmpty ? AppSurfaces.inset(context) : bg,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Text(
        stars,
        style: AppTheme.number(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: isEmpty
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : const Color(0xFF1F1A10),
        ),
      ),
    );
  }
}
