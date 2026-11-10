import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';

import '../utils/AppDesignTokens.dart';
import 'AppUi.dart';

/// 全 App 共用的页面级空状态：图标、标题、说明和可选操作按钮。
///
/// 对话框内用 [AppDialogEmpty]。
///
/// 说明文字二选一：传 [message] 显示固定文案；传 [randomMessages] 从中随机显示一条。
/// 标题和说明都没传时显示默认的「啥都木有」。
/// 同一次展示内句子不变，页面重建或切换语言都不会换句；只有组件重新挂载
/// （换 Key、离开后再回到空状态）才会重新抽取。
class EmptyState extends StatefulWidget {
  /// 为空时显示默认的颜文字。
  final IconData? icon;
  final String? title;

  /// 固定说明，优先于 [randomMessages]。
  final String? message;

  /// 随机说明的候选文案，请在 build 时按当前语言生成，不要缓存。
  final List<String> randomMessages;

  /// [actionLabel] 和 [onAction] 都传了才显示按钮。
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.randomMessages = const [],
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> {
  // 记录抽取结果而不是句子本身，切换语言后仍是同一句的译文。
  final int _pick = Random().nextInt(1 << 31);

  String? _descriptionOf(BuildContext context) {
    final pool = widget.randomMessages;
    if (widget.message != null) return widget.message;
    if (pool.isNotEmpty) return pool[_pick % pool.length];
    return widget.title == null ? context.l10n.flowNothingHereYet : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final title = widget.title;
    final description = _descriptionOf(context);
    final actionLabel = widget.actionLabel;
    final onAction = widget.onAction;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDesignTokens.sectionGap),
        child: EntranceAnimation(
          duration: const Duration(milliseconds: 300),
          offset: const Offset(0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 42, color: scheme.outline)
              else
                ExcludeSemantics(
                  child: Text(
                    r'¯\_(ツ)_/¯',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              if (title != null) ...[
                const SizedBox(height: AppDesignTokens.itemGap),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ],
              if (description != null) ...[
                SizedBox(height: title != null ? 6 : AppDesignTokens.itemGap),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppDesignTokens.gutter),
                if (widget.actionIcon != null)
                  FilledButton.tonalIcon(
                    onPressed: onAction,
                    icon: Icon(widget.actionIcon),
                    label: Text(actionLabel),
                  )
                else
                  FilledButton.tonal(
                    onPressed: onAction,
                    child: Text(actionLabel),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
