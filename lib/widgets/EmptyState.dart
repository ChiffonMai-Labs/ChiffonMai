import 'dart:math';

import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppError.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';
import 'ErrorMessageDialog.dart';

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

  /// 结构化错误：传入后可自动显示人话原因、紧凑错误码与「查看详情」按钮。
  final AppError? error;

  const EmptyState({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.randomMessages = const [],
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.error,
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
    if (widget.error != null) return widget.error!.userMessage;
    if (pool.isNotEmpty) return pool[_pick % pool.length];
    return widget.title == null && widget.error?.title == null
        ? context.l10n.flowNothingHereYet
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final err = widget.error;
    final title = widget.title ?? err?.title;
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
              if (err != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
                  ),
                  child: Text(
                    err.compactBadge(),
                    textAlign: TextAlign.center,
                    style: AppTheme.number(
                      fontSize: 11.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if ((actionLabel != null && onAction != null) || err != null) ...[
                const SizedBox(height: AppDesignTokens.gutter),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (actionLabel != null && onAction != null)
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
                    if (err != null)
                      TextButton.icon(
                        onPressed: () => showErrorMessageDialog(
                          context,
                          appError: err,
                          onRetry: onAction,
                        ),
                        icon: const Icon(Icons.info_outline_rounded, size: 18),
                        label: Text(context.l10n.errViewDetails),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
