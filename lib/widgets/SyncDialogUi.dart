import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/Sync/SyncStatsService.dart' show SyncPlatform;
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AnimatedReveal.dart';
import 'AppDialogs.dart';
import 'PostSyncRefreshOptions.dart';
import 'QrQuickFillButtons.dart';
import 'QuickSyncOption.dart';
import 'RefreshDataDialog.dart' show RefreshDataRequest, RefreshDataSource;

/// 同步对话框（水鱼 / 落雪 / AWMC NET / 多端）共用的排版件。
///
/// 统一成卡片式分区结构：同步方式 → 机台二维码 / 同步目标 → 同步后刷新；
/// 提示与警告统一用 [SyncNoticeCard]。

/// 一个分区：圆角浅底卡片 + 图标底块 + 标题（可带说明及右侧操作/徽章），下面是内容。
class SyncDialogSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? caption;
  final Widget? trailing;
  final Widget child;

  /// 第一个分区上方不留间距。
  final bool first;

  const SyncDialogSection({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    this.trailing,
    required this.child,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppSurfaces.inset(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: scheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (caption != null && caption!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          caption!,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// 机台二维码输入：紧凑快捷填充按钮 + 卡片底输入框，三个单平台对话框共用。
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
    final radius = BorderRadius.circular(AppDesignTokens.radiusSmall);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        QrQuickFillButtons(
          controller: controller,
          onFilled: onFilled,
          compact: true,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 3,
          onChanged: onFilled == null ? null : (_) => onFilled!(),
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            filled: true,
            fillColor: AppSurfaces.card(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: scheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// 三个单源同步成绩对话框（水鱼 / 落雪 / AWMC NET）共用的统一表单。
///
/// 仅包含：同步方式（可选）、机台二维码、同步成绩后刷新数据三个分区，
/// 并在切换同步方式和显示错误提示时保留平滑过渡动画。
class SingleSourceSyncDialog<T> extends StatefulWidget {
  final String title;
  final String subtitle;
  final SyncPlatform platform;
  final RefreshDataSource refreshSource;
  final bool allowQuickUpdate;
  final String qrCaption;
  final String qrHintText;
  final Future<T?> Function({
    required BuildContext context,
    required String qrCode,
    required bool quickUpdate,
    required RefreshDataRequest? refreshRequest,
    required void Function(String message) showError,
  }) onSubmit;

  const SingleSourceSyncDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.platform,
    required this.refreshSource,
    required this.allowQuickUpdate,
    required this.qrCaption,
    required this.qrHintText,
    required this.onSubmit,
  });

  @override
  State<SingleSourceSyncDialog<T>> createState() =>
      _SingleSourceSyncDialogState<T>();
}

class _SingleSourceSyncDialogState<T> extends State<SingleSourceSyncDialog<T>> {
  final TextEditingController _qrController = TextEditingController();
  final _refreshKey = GlobalKey<PostSyncRefreshOptionsState>();
  bool _quickUpdate = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final route = ModalRoute.of(context);
    if (_submitting || route == null || !route.isCurrent) return;
    final qrCode = _qrController.text.trim();
    if (!_quickUpdate && qrCode.isEmpty) {
      setState(
          () => _error = context.l10n.flowPasteTheMaimaiCHUNITHMLoginQRString);
      return;
    }
    if (!_quickUpdate && !qrCode.startsWith('SGWCMAID')) {
      setState(() => _error = context.l10n.flowInvalidQRCodeUseALoginQR);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final refreshRequest = await _refreshKey.currentState?.collectRequest();
      if (!mounted || !route.isCurrent) return;
      final value = await widget.onSubmit(
        context: context,
        qrCode: qrCode,
        quickUpdate: _quickUpdate,
        refreshRequest: refreshRequest,
        showError: (message) {
          if (mounted) setState(() => _error = message);
        },
      );
      if (value != null && mounted && route.isCurrent) {
        FocusManager.instance.primaryFocus?.unfocus();
        route.navigator!.pop(value);
      }
    } catch (_) {
      if (mounted && route.isCurrent) {
        setState(() => _error =
            context.l10n.flowCouldNotReadSavedCredentialsTryAgain);
      }
    } finally {
      if (mounted && route.isActive) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_submitting,
      child: AppAlertDialog(
        animateHeight: true,
        title: Text(widget.title),
        subtitle: widget.subtitle,
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: AbsorbPointer(
              absorbing: _submitting,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.allowQuickUpdate)
                    SyncDialogSection(
                      first: true,
                      icon: Icons.bolt_rounded,
                      title: context.l10n.syncDialogMode,
                      child: QuickSyncOption(
                        platforms: {widget.platform},
                        onChanged: (enabled) => setState(() {
                          _quickUpdate = enabled;
                          if (enabled) _error = null;
                        }),
                      ),
                    ),
                  AnimatedReveal(
                    visible: !_quickUpdate,
                    child: SyncDialogSection(
                      first: !widget.allowQuickUpdate,
                      icon: Icons.qr_code_2_rounded,
                      title: context.l10n.syncDialogQrCode,
                      caption: widget.qrCaption,
                      child: SyncQrInput(
                        controller: _qrController,
                        hintText: widget.qrHintText,
                        onFilled: () {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                    ),
                  ),
                  AnimatedReveal(
                    visible: _error != null,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 16, color: scheme.error),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _error ?? '',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SyncDialogSection(
                    icon: Icons.refresh_rounded,
                    title: context.l10n.flowRefreshDataAfterSync,
                    caption: context
                        .l10n.flowRefreshAutomaticallyAfterUploadRefreshErrorsAre,
                    child: PostSyncRefreshOptions(
                      key: _refreshKey,
                      source: widget.refreshSource,
                      showHeader: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting
                ? null
                : () {
                    final route = ModalRoute.of(context);
                    if (route != null && route.isCurrent) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      route.navigator!.pop();
                    }
                  },
            child: Text(context.l10n.featureCancel),
          ),
          SyncStartButton(
            label: context.l10n.flowStartSync,
            onPressed: _submitting ? null : _handleSubmit,
          ),
        ],
      ),
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
