import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 导出或下载完成后的结果弹窗。
///
/// 路径区域使用当前主题的 surfaceContainerHighest，避免深色模式下出现白底；
/// [fallbackPath] 用于提示公开目录不可写时的备用路径。
Future<void> showExportSuccessDialog(
  BuildContext context, {
  required String filePath,
  required String fileName,
  String title = '导出成功',
  String successPrefix = '已导出',
  String? fallbackPath,
  String? warning,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ExportSuccessDialog(
      filePath: filePath,
      fileName: fileName,
      title: title,
      successPrefix: successPrefix,
      fallbackPath: fallbackPath,
      warning: warning,
    ),
  );
}

class _ExportSuccessDialog extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String title;
  final String successPrefix;
  final String? fallbackPath;
  final String? warning;

  const _ExportSuccessDialog({
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.successPrefix,
    this.fallbackPath,
    this.warning,
  });

  @override
  State<_ExportSuccessDialog> createState() => _ExportSuccessDialogState();
}

class _ExportSuccessDialogState extends State<_ExportSuccessDialog> {
  bool _copied = false;

  Future<void> _copyPath() async {
    await Clipboard.setData(ClipboardData(text: widget.filePath));
    if (!mounted) return;
    setState(() => _copied = true);
    AppToast.show('路径已复制到剪贴板');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasWarning = widget.fallbackPath != null || widget.warning != null;
    final warnColor = AppColors.warningOrange(Theme.of(context).brightness);
    final warnStyle =
        TextStyle(fontSize: 12, height: 1.4, color: scheme.onSurface);
    return AppDialog(
      title: widget.title,
      tone: AppDialogTone.success,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.successPrefix} ${widget.fileName}'),
          const SizedBox(height: 10),
          AppDialogCodeBlock(widget.filePath),
          // 公开目录不可写时必须橙色告警，不能静默把文件丢进沙箱（AGENTS.md §2）
          if (hasWarning) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: warnColor.withValues(alpha: 0.14),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.fallbackPath != null)
                    Text(
                      '公开目录不可写，文件已保存到备用路径：${widget.fallbackPath}',
                      style: warnStyle,
                    ),
                  if (widget.fallbackPath != null && widget.warning != null)
                    const SizedBox(height: 4),
                  if (widget.warning != null)
                    Text(widget.warning!, style: warnStyle),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        FilledButton.tonalIcon(
          onPressed: _copyPath,
          icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
          label: Text(_copied ? '已复制' : '复制路径'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
