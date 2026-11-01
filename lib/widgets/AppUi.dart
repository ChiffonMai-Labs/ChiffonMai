import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ColorUtil.dart';

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
    if (onTap != null) {
      return PressScale(
        scale: 0.98,
        child: Material(
          color: color ?? AppSurfaces.card(context),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: outlined
                ? BorderSide(color: scheme.outlineVariant)
                : BorderSide.none,
          ),
          child: InkWell(onTap: onTap, child: content),
        ),
      );
    }
    return Material(
      color: color ?? AppSurfaces.card(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: outlined
            ? BorderSide(color: scheme.outlineVariant)
            : BorderSide.none,
      ),
      child: content,
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
    // 列表里的小徽章贴着文字；结果卡上的大徽章（字号 ≥ 14）撑开一些。
    final large = fontSize >= 14;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 5, vertical: large ? 3 : 0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(large ? 10 : 5),
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

  /// 紧跟在数值右边的内容（DX 分数达成率右边的星级）。
  final Widget? trailing;

  /// 自定义数值部件（数字滚动），优先于 [value] 的默认文字。
  final Widget? valueWidget;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.card = false,
    this.valueSize = 17,
    this.trailing,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 放不下时等比缩小，重要数据和说明都不用省略号截断。
    Widget fit(Widget child) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: child,
        );
    final valueText = valueWidget ??
        Text(
          value,
          maxLines: 1,
          style: AppTheme.number(
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            color: valueColor ?? scheme.onSurface,
          ),
        );
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        fit(FadeSwitcher(
          value: label,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
        )),
        const SizedBox(height: 2),
        fit(trailing == null
            ? valueText
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  valueText,
                  const SizedBox(width: 8),
                  trailing!,
                ],
              )),
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
        tween: Tween<double>(begin: 0, end: target),
        duration: AppDesignTokens.motion(context, AppDesignTokens.slowMotion),
        curve: AppDesignTokens.emphasizedCurve,
        builder: (context, value, _) {
          final left = (value * 1000).round().clamp(1, 999).toInt();
          return SizedBox(
            height: height,
            child: Row(
              // 没有 child 的 DecoratedBox 高度取约束下限，不拉伸就是 0 高。
              crossAxisAlignment: CrossAxisAlignment.stretch,
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

  /// 数值放在名称右边（Best50 的 `B35 10670`），默认放在下面。
  final bool inlineCaption;

  const SegmentedTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 48,
    this.inlineCaption = false,
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
        color: AppSurfaces.track(context),
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
                            child: Flex(
                              direction: inlineCaption
                                  ? Axis.horizontal
                                  : Axis.vertical,
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                if (inlineCaption && items[i].caption != null)
                                  const SizedBox(width: 6),
                                if (items[i].caption != null)
                                  Text(
                                    items[i].caption!,
                                    maxLines: 1,
                                    style: AppTheme.number(
                                      fontSize: inlineCaption ? 15 : 13,
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

/// 一排独立的选项块（选中反色）：名称 + 数值，用于计算器的音符类型。
class PillTabs extends StatelessWidget {
  final List<SegmentedTabItem> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PillTabs({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedBg = theme.brightness == Brightness.dark
        ? scheme.inverseSurface
        : scheme.onSurface;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.fastMotion);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: i == selectedIndex,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i != selectedIndex) onChanged(i);
                },
                child: AnimatedContainer(
                  duration: duration,
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? selectedBg
                        : AppSurfaces.card(context),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Builder(builder: (context) {
                    final fg = i == selectedIndex
                        ? scheme.onInverseSurface
                        : scheme.onSurfaceVariant;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: fg)),
                        if (items[i].caption != null)
                          Text(items[i].caption!,
                              maxLines: 1,
                              style: AppTheme.number(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: fg)),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ],
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
    return PressScale(
      scale: 0.9,
      child: SizedBox(
        width: 44,
        height: 44,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          iconSize: 20,
          // 这里的底色由外层凹槽提供，不继承顶部栏等处的圆形按钮样式
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            minimumSize: const Size(44, 44),
          ),
          icon: Icon(icon),
        ),
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
        // 浅色模式几乎是黑，比 inverseSurface 更压得住白字
        color: Theme.of(context).brightness == Brightness.dark
            ? scheme.inverseSurface
            : scheme.onSurface,
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
// Rating / 星级徽章
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

// ---------------------------------------------------------------------------
// 功能入口
// ---------------------------------------------------------------------------

/// 首页「常用」里的一格：彩色圆角图标块 + 标题。
///
/// 颜色按标题取（[AppColors.featureTint]），同一功能在各页同色。
class FeatureIconTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const FeatureIconTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = AppColors.featureTint(title, theme.brightness);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: title,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PressScale(
                  scale: 0.9,
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tint.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, size: 26, color: tint.foreground),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
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

/// 下划线样式的标签栏（歌曲详情的谱面 / 数据 / 社区 / 工具）。
class UnderlineTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// 下划线和选中文字的颜色，默认 onSurface。
  final Color? indicatorColor;

  const UnderlineTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = indicatorColor ?? scheme.onSurface;
    return SizedBox(
      height: 44,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / labels.length;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                    height: 1, color: AppSurfaces.hairline(context)),
              ),
              AnimatedPositioned(
                duration: AppDesignTokens.motion(
                    context, AppDesignTokens.mediumMotion),
                curve: AppDesignTokens.emphasizedCurve,
                left: selectedIndex * w,
                width: w,
                bottom: 0,
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
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
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: i == selectedIndex
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == selectedIndex
                                    ? accent
                                    : scheme.onSurfaceVariant,
                              ),
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

/// 可折叠的白卡片：默认收起的次要内容（详细统计等）。
class CollapsibleCard extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleCard({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  late bool _expanded = widget.initiallyExpanded;

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
                              fontSize: 13, fontWeight: FontWeight.w700)),
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// 筛选胶囊：名称 + 下拉箭头；有筛选值时高亮并显示当前值。
class FilterPill extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  /// 开关型胶囊（仅 DX、只搜歌名）：直接给选中状态，不显示箭头。
  final bool? selected;

  const FilterPill({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasValue = value != null && value!.isNotEmpty;
    final active = selected ?? hasValue;
    final fg = active ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
    return Material(
      color: active ? scheme.secondaryContainer : AppSurfaces.track(context),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 胶囊排在横向滚动里，已选条件再长也完整显示。
              Text(
                hasValue ? '$label：$value' : label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
              if (selected == null) ...[
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 一排胶囊入口里的一个（Best50 变体、排行榜）。
class LinkPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const LinkPill({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppSurfaces.inset(context),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

/// 接口里的 `fc` / `fs` 值 → 显示文字（`fcp` → `FC+`）。空值返回 null。
String? comboLabelOf(String raw) {
  switch (raw.toLowerCase()) {
    case '':
      return null;
    case 'app':
    case 'ap+':
      return 'AP+';
    case 'ap':
      return 'AP';
    case 'fcp':
    case 'fc+':
      return 'FC+';
    case 'fc':
      return 'FC';
    case 'fsp':
    case 'fs+':
      return 'FS+';
    case 'fs':
      return 'FS';
    case 'fsdp':
    case 'fdx+':
      return 'FDX+';
    case 'fsd':
    case 'fdx':
      return 'FDX';
    case 'sync':
      return 'SYNC';
    default:
      return raw.toUpperCase();
  }
}

/// 连击 / 同步徽章：FC 绿、AP 橙、FS 蓝、FDX 橙，颜色见
/// [AppColors.achievementBackground]。尺寸与 [RankBadge] 相同。
class ComboLabelBadge extends StatelessWidget {
  /// 接口原值（`fcp`、`fsd`……）或显示文字都可以。
  final String raw;
  final double fontSize;

  const ComboLabelBadge({super.key, required this.raw, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final label = comboLabelOf(raw);
    if (label == null) return const SizedBox.shrink();
    return AppBadge(
      text: label,
      background: AppColors.achievementBackground(label),
      foreground: AppColors.achievementForeground(label),
      fontSize: fontSize,
    );
  }
}

// ---------------------------------------------------------------------------
// 动效
// ---------------------------------------------------------------------------

/// 入场动画：淡入 + 位移 + 可选缩放，列表项按 [index] 错开。
///
/// 只在首次挂载时播放；想重播就换外层的 Key。系统开了「减少动态效果」时不播放。
/// 错开用 [Interval] 实现，不用定时器。
class EntranceAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration stagger;
  final Duration baseDelay;
  final int maxStaggerIndex;
  final Duration duration;
  final Offset offset;
  final double scaleFrom;

  const EntranceAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 28),
    this.baseDelay = Duration.zero,
    this.maxStaggerIndex = 14,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 14),
    this.scaleFrom = 1,
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, widget.maxStaggerIndex).toInt();
    final delay = widget.baseDelay + widget.stagger * steps;
    final total = delay + widget.duration;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppDesignTokens.emphasizedCurve,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      child: widget.child,
      builder: (context, child) {
        final t = _progress.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// 数字滚动：值变化时从旧值滚到新值，首次显示不滚动。
class RollingNumber extends StatelessWidget {
  final num value;
  final int fractionDigits;
  final String suffix;
  final TextStyle style;

  const RollingNumber({
    super.key,
    required this.value,
    required this.style,
    this.fractionDigits = 0,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: AppDesignTokens.motion(context, AppDesignTokens.slowMotion),
      curve: AppDesignTokens.emphasizedCurve,
      builder: (context, v, _) => Text(
        '${v.toStringAsFixed(fractionDigits)}$suffix',
        maxLines: 1,
        style: style,
      ),
    );
  }
}

/// [value] 变化时淡入淡出切换内容（文字说明、徽章）。
class FadeSwitcher extends StatelessWidget {
  final Object value;
  final Widget child;
  final AlignmentGeometry alignment;

  const FadeSwitcher({
    super.key,
    required this.value,
    required this.child,
    this.alignment = AlignmentDirectional.centerStart,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: alignment,
        children: [
          ...previous,
          if (current != null) current,
        ],
      ),
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}

/// 按下时轻微缩小。点击事件仍由 [child] 自己处理。
class PressScale extends StatefulWidget {
  final Widget child;
  final double scale;

  const PressScale({super.key, required this.child, this.scale = 0.95});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppDesignTokens.motion(
            context, const Duration(milliseconds: 150)),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
