import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import 'QrQuickFillButtons.dart';

/// 同步对话框（水鱼 / 落雪 / AWMC NET / 多端）共用的排版件。
///
/// 统一成「分区标题 + 内容」的结构：同步方式 → 机台二维码 → 凭据 →
/// 同步后刷新；分区之间用细分隔线隔开，提示与警告统一用 [SyncNoticeCard]。

/// 一个分区：小图标 + 标题（可带说明），下面是内容。
class SyncDialogSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? caption;
  final Widget child;

  /// 第一个分区上方不画分隔线。
  final bool first;

  const SyncDialogSection({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    required this.child,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!first)
          Divider(height: 28, thickness: 1, color: scheme.outlineVariant),
        Row(children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                )),
          ),
        ]),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(caption!,
              style: TextStyle(
                  fontSize: 12.5, height: 1.4, color: scheme.onSurfaceVariant)),
        ],
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// 机台二维码输入：快捷填充按钮 + 输入框，三个单平台对话框共用。
class SyncQrInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onFilled;

  const SyncQrInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.onFilled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        QrQuickFillButtons(controller: controller, onFilled: onFilled),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 3,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// 提示 / 警告卡片：浅色底 + 同色描边，图标与标题同一行。
class SyncNoticeCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? title;
  final Widget? trailing;
  final Widget? child;

  const SyncNoticeCard({
    super.key,
    required this.icon,
    required this.color,
    this.title,
    this.trailing,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: title == null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: title != null
                    ? Text(title!,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface))
                    : DefaultTextStyle.merge(
                        style: TextStyle(fontSize: 12, color: color),
                        child: child ?? const SizedBox.shrink()),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (title != null && child != null) ...[
            const SizedBox(height: 8),
            child!,
          ],
        ],
      ),
    );
  }
}

/// 同步对话框的主操作按钮：跟随主题色，不再写死蓝色。
class SyncStartButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SyncStartButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        icon: const Icon(Icons.send_rounded, size: 18),
        label: Text(label),
        onPressed: onPressed,
      );
}
