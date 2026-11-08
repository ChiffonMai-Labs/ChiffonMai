import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 导出或下载完成后的结果弹窗。
///
/// 路径区域使用当前主题的 surfaceContainerHighest，避免深色模式下出现白底；
/// [fallbackPath] 用于提示公开目录不可写时的备用路径；
/// [showViewImage] 显示「查看图片」，只有图片存进了相册才传 true。
Future<void> showExportSuccessDialog(
  BuildContext context, {
  required String filePath,
  required String fileName,
  String title = '导出成功',
  String successPrefix = '已导出',
  String? fallbackPath,
  String? warning,
  bool showViewImage = false,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ExportSuccessDialog(
      filePath: filePath,
      fileName: fileName,
      title: context.featureText(title),
      successPrefix: context.featureText(successPrefix),
      fallbackPath: fallbackPath,
      warning: warning,
      showViewImage: showViewImage,
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
  final bool showViewImage;

  const _ExportSuccessDialog({
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.successPrefix,
    this.fallbackPath,
    this.warning,
    this.showViewImage = false,
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
    AppToast.show(context.l10n.flowPathCopiedToClipboard);
  }

  Future<void> _viewImage() async {
    bool opened = false;
    try {
      opened = await const MethodChannel('com.example.app/media_store')
              .invokeMethod<bool>('viewImage', {'path': widget.filePath}) ??
          false;
    } on PlatformException catch (error) {
      debugPrint('查看图片失败: $error');
    } on MissingPluginException catch (error) {
      debugPrint('查看图片失败: $error');
    }
    if (!opened) {
      AppToast.show(context.l10n.flowNoAppAvailableToViewImages,
          tone: AppToastTone.error);
      return;
    }
    if (mounted) Navigator.of(context).pop();
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
          // 有「查看图片」时它是主操作，复制路径退到路径下面。
          if (widget.showViewImage)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _copyPath,
                icon: Icon(_copied ? Icons.check : Icons.copy, size: 14),
                label: Text(_copied
                    ? context.l10n.flowCopied
                    : context.l10n.flowCopyPath),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle:
                      AppTheme.font(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
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
                      context.l10n.flowPublicDirectoryIsNotWritableSavedTo(
                          (widget.fallbackPath).toString()),
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
        if (widget.showViewImage) ...[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.featureClose),
          ),
          FilledButton.icon(
            onPressed: _viewImage,
            icon: const Icon(Icons.image_outlined, size: 16),
            label: Text(context.l10n.flowViewImage),
          ),
        ] else ...[
          FilledButton.tonalIcon(
            onPressed: _copyPath,
            icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
            label: Text(
                _copied ? context.l10n.flowCopied : context.l10n.flowCopyPath),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.featureClose),
          ),
        ],
      ],
    );
  }
}
