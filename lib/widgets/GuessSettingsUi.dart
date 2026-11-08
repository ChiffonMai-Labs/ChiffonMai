import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';

/// 设置的一组内容（猜歌设置、系统设置共用）：图标底块 + 标题 + 控件。
///
/// 页面里传 [card] = true 铺成白卡片；对话框本身就是卡片，直接平铺。
class GuessSettingSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;
  final bool card;

  const GuessSettingSection({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
    this.card = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: scheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        for (final (index, child) in children.indexed) ...[
          if (index > 0) const SizedBox(height: 12),
          child,
        ],
      ],
    );
    return SizedBox(
      width: double.infinity,
      child: card
          ? AppCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: body,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: body,
            ),
    );
  }
}

/// 滑条一行：左边名称、右边当前值，下面是滑条。
class GuessSliderTile extends StatelessWidget {
  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int divisions;

  /// 为 null 时滑条不可用。
  final ValueChanged<double>? onChanged;
  final String? hint;

  const GuessSliderTile({
    super.key,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
              ),
            ),
            Text(
              valueText,
              style: AppTheme.number(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: valueText,
            onChanged: onChanged,
          ),
        ),
        if (hint != null)
          Text(
            hint!,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// 多选入口：一行显示已选摘要，点开底部面板选择；什么都不选表示全部。
class GuessMultiSelectTile extends StatelessWidget {
  final String label;
  final List<String> items;
  final List<String> selected;
  final String Function(String)? formatter;
  final ValueChanged<List<String>> onChanged;

  const GuessMultiSelectTile({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.formatter,
  });

  String _format(String item) => formatter?.call(item) ?? item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chosen = selected.where(items.contains).map(_format).toList();
    final summary = chosen.isEmpty ? context.l10n.flowAll : chosen.join('、');
    return PressScale(
      scale: 0.98,
      child: Semantics(
        button: true,
        label: '$label：$summary',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => _GuessMultiSelectSheet(
                title: label,
                items: items,
                initial: selected,
                format: _format,
                onChanged: onChanged,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    chosen.length > 2
                        ? context.l10n.flowP0Selected((chosen.length).toString())
                        : summary,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: chosen.isEmpty
                          ? scheme.onSurfaceVariant
                          : scheme.primary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuessMultiSelectSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<String> initial;
  final String Function(String) format;
  final ValueChanged<List<String>> onChanged;

  const _GuessMultiSelectSheet({
    required this.title,
    required this.items,
    required this.initial,
    required this.format,
    required this.onChanged,
  });

  @override
  State<_GuessMultiSelectSheet> createState() => _GuessMultiSelectSheetState();
}

class _GuessMultiSelectSheetState extends State<_GuessMultiSelectSheet> {
  late List<String> _selected = List<String>.from(widget.initial);

  void _update(List<String> next) {
    setState(() => _selected = next);
    widget.onChanged(List<String>.from(next));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.72),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 12 + media.padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _selected.isEmpty ? null : () => _update(const []),
                  child:  Text(context.l10n.flowSelectAll2),
                ),
              ],
            ),
            Text(
              _selected.isEmpty ? context.l10n.flowCurrentAll : context.l10n.flowP0SelectedNoneMeansAll((_selected.length).toString()),
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in widget.items)
                      GuessChoicePill(
                        label: widget.format(item),
                        selected: _selected.contains(item),
                        onTap: () => _update(_selected.contains(item)
                            ? (List<String>.from(_selected)..remove(item))
                            : [..._selected, item]),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child:  Text(context.l10n.featureDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个可选胶囊。选中时填充，按压时轻微缩放，没有波纹。
class GuessChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;
  final Color? selectedForeground;

  const GuessChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor,
    this.selectedForeground,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.fastMotion);
    return PressScale(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? (selectedColor ?? scheme.primary)
                  : AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
            ),
            child: AnimatedDefaultTextStyle(
              duration: duration,
              style: AppTheme.font(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? (selectedForeground ?? scheme.onPrimary)
                    : scheme.onSurface,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

/// 对话框和设置页底部的「恢复默认」。
class GuessSettingsResetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const GuessSettingsResetButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.restart_alt_rounded, size: 18),
        label:  Text(context.l10n.flowRestoreDefaults),
      ),
    );
  }
}
