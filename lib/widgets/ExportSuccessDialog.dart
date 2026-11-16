import 'dart:io';

import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ExportPathUtil.dart';
import 'AppDialogs.dart';
import 'BackgroundPageScaffold.dart';
import '../widgets/AppToast.dart';

/// 导出或下载完成后的结果弹窗。
///
/// 路径区域使用当前主题的 surfaceContainerHighest，避免深色模式下出现白底；
/// [fallbackPath] 用于提示公开目录不可写时的备用路径；
/// [showViewImage] 显示「查看图片」，适用于已写入文件的图片导出。
Future<void> showExportSuccessDialog(
  BuildContext context, {
  required String filePath,
  required String fileName,
  String title = '导出成功',
  String successPrefix = '已导出',
  String? description,
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
      description: description,
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
  final String? description;
  final String? fallbackPath;
  final String? warning;
  final bool showViewImage;

  const _ExportSuccessDialog({
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.successPrefix,
    this.description,
    this.fallbackPath,
    this.warning,
    this.showViewImage = false,
  });

  @override
  State<_ExportSuccessDialog> createState() => _ExportSuccessDialogState();
}

class _ExportSuccessDialogState extends State<_ExportSuccessDialog> {
  bool _copied = false;
  bool _openingFolder = false;

  Future<void> _copyPath() async {
    await Clipboard.setData(ClipboardData(text: widget.filePath));
    if (!mounted) return;
    setState(() => _copied = true);
    AppToast.show(context.l10n.flowPathCopiedToClipboard);
  }

  Future<void> _openFolder() async {
    setState(() => _openingFolder = true);
    final opened = await ExportPathUtil.openContainingFolder(widget.filePath);
    if (!mounted) return;
    setState(() => _openingFolder = false);
    if (!opened) {
      AppToast.show(context.l10n.flowCouldNotOpenExportFolder,
          tone: AppToastTone.warning);
    }
  }

  Future<void> _viewImage() async {
    if (Platform.isIOS) {
      await Navigator.of(context).push<void>(MaterialPageRoute(
        builder: (context) => BackgroundPageScaffold(
          title: context.l10n.flowViewImage,
          showDecorativeImage: false,
          child: InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Image.file(
                File(widget.filePath),
                fit: BoxFit.contain,
                cacheWidth: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .ceil()
                    .clamp(1, 1440),
                errorBuilder: (_, __, ___) => Text(
                  context.l10n.flowNoAppAvailableToViewImages,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ));
      return;
    }
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
    final canOpenFolder = ExportPathUtil.supportsOpeningFolder &&
        widget.fallbackPath == null &&
        !widget.filePath.startsWith('content://');
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
          if (widget.description case final description?) Text(description),
          const SizedBox(height: 10),
          AppDialogCodeBlock(widget.filePath),
          // 路径相关的次要操作放在路径下方，给主操作留出空间。
          if (widget.showViewImage || canOpenFolder)
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
          if (!canOpenFolder)
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
        if (canOpenFolder)
          FilledButton.icon(
            onPressed: _openingFolder ? null : _openFolder,
            icon: const Icon(Icons.folder_open_outlined, size: 16),
            label: Text(context.l10n.flowOpenExportFolder),
          ),
      ],
    );
  }
}
