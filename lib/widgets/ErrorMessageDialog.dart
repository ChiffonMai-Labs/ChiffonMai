import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/FeatureLocalizations.dart';
import '../l10n/LocalizationsExtension.dart';
import '../service/LogExportService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppError.dart';
import '../utils/AppTheme.dart';
import 'AppDialogs.dart';
import 'AppToast.dart';
import 'AppUi.dart';
import 'ExportSuccessDialog.dart';

/// 统一的诊断型错误弹窗。
///
/// 兼顾三层信息：
/// 1. 人话原因与处理建议；
/// 2. 截屏即可定位的紧凑诊断条（错误码 · 阶段 · 状态码 · 请求号 · 版本）；
/// 3. 可折叠的技术详情，并提供「复制排查信息」与「导出完整日志」快捷入口。
Future<void> showErrorMessageDialog(
  BuildContext context, {
  String? message,
  Object? error,
  AppError? appError,
  String? title,
  String? stage,
  String? source,
  String? requestId,
  int? httpStatus,
  StackTrace? stack,
  VoidCallback? onRetry,
}) {
  final AppError resolved;
  if (appError != null) {
    resolved = appError.copyWith(
      title: title ?? appError.title,
      stage: stage ?? appError.stage,
      source: source ?? appError.source,
      requestId: requestId ?? appError.requestId,
      httpStatus: httpStatus ?? appError.httpStatus,
    );
  } else if (error != null) {
    final mapped = AppErrorMapper.from(
      error,
      stack: stack,
      title: title,
      stage: stage,
      source: source,
      requestId: requestId,
      httpStatus: httpStatus,
    );
    final overrideMessage = message?.trim();
    resolved = (overrideMessage != null && overrideMessage.isNotEmpty)
        ? mapped.copyWith(
            userMessage: AppErrorMapper.cleanText(overrideMessage),
          )
        : mapped;
  } else {
    resolved = AppErrorMapper.fromMessage(
      message ?? '',
      title: title,
      stage: stage,
      source: source,
      requestId: requestId,
      httpStatus: httpStatus,
    );
  }
  AppErrorRegistry.record(resolved);

  return showDialog<void>(
    context: context,
    builder: (ctx) => _DiagnosticErrorDialog(
      error: resolved,
      onRetry: onRetry,
    ),
  );
}

class _DiagnosticErrorDialog extends StatefulWidget {
  final AppError error;
  final VoidCallback? onRetry;

  const _DiagnosticErrorDialog({
    required this.error,
    this.onRetry,
  });

  @override
  State<_DiagnosticErrorDialog> createState() => _DiagnosticErrorDialogState();
}

class _DiagnosticErrorDialogState extends State<_DiagnosticErrorDialog> {
  bool _expanded = false;
  bool _exportingLogs = false;

  @override
  void initState() {
    super.initState();
    if (LogExportService.instance.cachedAppVersion == null) {
      LogExportService.instance.preloadAppInfo().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _copyDiagnostics() async {
    final text = widget.error.buildDiagnosticText(
      appVersion: LogExportService.instance.cachedAppVersion,
    );
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppToast.show(context.l10n.errDiagnosticCopied, tone: AppToastTone.success);
  }

  Future<void> _exportLogs() async {
    if (_exportingLogs) return;
    setState(() => _exportingLogs = true);
    try {
      final file = await LogExportService.instance.export();
      if (!mounted) return;
      await showExportSuccessDialog(
        context,
        title: context.l10n.flowLogsExported,
        filePath: file.path,
        fileName: file.uri.pathSegments.last,
      );
    } catch (e, st) {
      if (mounted) {
        AppToast.showError(
          e,
          stack: st,
          title: context.l10n.featureExportLogs,
          stage: '导出完整日志',
        );
      }
    } finally {
      if (mounted) setState(() => _exportingLogs = false);
    }
  }

  String _technicalBlockText() {
    final e = widget.error;
    final lines = <String>[
      '错误码: ${e.code}',
      if (e.stage != null && e.stage!.trim().isNotEmpty) '阶段: ${e.stage!.trim()}',
      if (e.source != null && e.source!.trim().isNotEmpty) '来源: ${e.source!.trim()}',
      if (e.httpStatus != null) '状态码: HTTP ${e.httpStatus}',
      if (e.requestId != null && e.requestId!.trim().isNotEmpty)
        '请求号: ${e.requestId!.trim()}',
      if (e.technicalDetail != null && e.technicalDetail!.trim().isNotEmpty)
        '详情:\n${e.technicalDetail!.trim()}',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final e = widget.error;
    final title = (e.title != null && e.title!.trim().isNotEmpty)
        ? e.title!.trim()
        : context.featureText('操作失败');
    final badge = e.compactBadge(
      appVersion: LogExportService.instance.cachedAppVersion,
    );

    return AppAlertDialog(
      icon: appDialogIconTile(
        AppDialog.toneIcon(AppDialogTone.error),
        AppDialog.toneColor(context, AppDialogTone.error),
      ),
      title: Text(title),
      scrollable: true,
      animateHeight: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectableText(
            e.userMessage,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurface,
            ),
          ),
          if (e.suggestion != null && e.suggestion!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 15,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    e.suggestion!.trim(),
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // 截屏直接可见的紧凑诊断条
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  badge,
                  style: AppTheme.number(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.errDiagnosticHint,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 可折叠技术详情（无水波纹，使用 PressScale）
          PressScale(
            scale: 0.985,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.errTechnicalDetails,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 6),
            AppDialogCodeBlock(_technicalBlockText()),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _exportingLogs ? null : _exportLogs,
                icon: const Icon(Icons.description_outlined, size: 15),
                label: Text(l10n.errExportFullLogs),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTheme.font(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _copyDiagnostics,
          child: Text(l10n.errCopyDiagnostic),
        ),
        if (widget.onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRetry?.call();
            },
            child: Text(l10n.flowRetry),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.featureText('知道了')),
        ),
      ],
    );
  }
}
