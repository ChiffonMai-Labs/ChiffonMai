import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'AppTaskActivity.dart';
import 'package:flutter/material.dart';

import '../service/FavoriteTransferService.dart';
import 'ExportSettings.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 导入方式
enum FavoriteImportMode { merge, replace }

/// 「导入收藏夹」的完整交互流程。
///
/// 抽成独立函数是因为它有两个入口：
///   1. 收藏夹列表页的「导入收藏夹」按钮（走系统文件选择器）
///   2. 在系统文件管理器里点开收藏夹文件、或「分享 → ChiffonMai」，
///      由 Android intent 唤起 App（此时路径已知，[presetPath] 非空）
///
/// [context] 必须是 **Navigator 之下** 的 context（例如 `navigatorKey.currentState.overlay.context`），
/// 因为 `showDialog` 是靠「向上找 Navigator」来定位的；传 Navigator 自身的 context 会找不到。
///
/// 返回 true 表示确实导入了数据。
Future<bool> runFavoriteImportFlow(
  BuildContext context, {
  String? presetPath,
}) =>
    AppTaskActivity.run(() async {
      final service = FavoriteTransferService();

      // ---- 1. 取得文件并解析 ----
      FavoriteImportBundle? bundle;
      try {
        bundle = presetPath != null
            ? await service.parseFile(presetPath)
            : await service.pickAndParse();
      } on FormatException catch (e) {
        if (context.mounted) {
          await _showMessageDialog(context, title: context.l10n.flowCannotImport, message: e.message);
        }
        return false;
      } catch (e) {
        if (context.mounted) {
          await _showMessageDialog(context, title: context.l10n.flowCannotImport, message: '$e');
        }
        return false;
      }

      // 用户取消选择
      if (bundle == null) return false;
      if (!context.mounted) return false;

      // ---- 2. 确认对话框（选合并 / 覆盖） ----
      final mode = await _showConfirmDialog(context, bundle);
      if (mode == null) return false;

      // ---- 3. 执行导入 ----
      try {
        final stats = await service.apply(
          bundle,
          replaceAll: mode == FavoriteImportMode.replace,
        );
        AppToast.show(context.l10n.flowImportCompleteP0((stats.describe()).toString()),
            duration: const Duration(seconds: 4));
        return true;
      } catch (e) {
        if (context.mounted) {
          await _showMessageDialog(context, title: context.l10n.flowImportFailed, message: '$e');
        }
        return false;
      }
    });

Future<FavoriteImportMode?> _showConfirmDialog(
  BuildContext context,
  FavoriteImportBundle bundle,
) {
  return showDialog<FavoriteImportMode>(
    context: context,
    builder: (ctx) {
      var mode = FavoriteImportMode.merge;
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final scheme = Theme.of(ctx).colorScheme;
          return AppAlertDialog(
            title:  Text(context.l10n.flowImportFavorites),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.flowP0FoldersP1Charts((bundle.folders.length).toString(), (bundle.chartCount).toString()),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  // 逐条列出收藏夹，让用户确认导入的确实是想要的内容
                  ...bundle.folders.take(8).map(
                        (f) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                            context.l10n.flowP0P1Charts2((f.name).toString(), (f.charts.length).toString()),
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  if (bundle.folders.length > 8)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        context.l10n.flowP0MoreFolders((bundle.folders.length - 8).toString()),
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const Divider(height: 24),
                  RadioListTile<FavoriteImportMode>(
                    value: FavoriteImportMode.merge,
                    groupValue: mode,
                    onChanged: (v) => setLocal(() => mode = v!),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title:  Text(context.l10n.flowMergeWithExistingFolders),
                    subtitle:  Text(
                      context.l10n.flowFoldersWithTheSameNameAreMerged,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  RadioListTile<FavoriteImportMode>(
                    value: FavoriteImportMode.replace,
                    groupValue: mode,
                    onChanged: (v) => setLocal(() => mode = v!),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title:  Text(context.l10n.flowReplaceExistingFavorites),
                    subtitle: Text(
                      context.l10n.flowClearAllCurrentFoldersThenImportThe,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child:  Text(context.l10n.featureCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(mode),
                child:  Text(context.l10n.flowImport),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AppAlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child:  Text(context.l10n.featureGotIt),
        ),
      ],
    ),
  );
}

/// 导入按钮的文字提示，带上固定的收藏夹后缀，让用户知道要选什么文件。
///
/// 提示里只认 `.cmf`，但**文件选择器不过滤后缀**（导入按内容识别），
/// 所以用户以前用自定义后缀导出的备份也照样能选、能导进来。
String favoriteImportHint() =>
    appL10n.flowSupportsChiffonMaiFavoritesFilesSuchAsP0((ExportSettings.favoriteExtensionWithDot).toString());

/// 导出文件名前缀，集中在这里方便以后调整。
const String favoriteExportPrefix = 'ChiffonMai_favorites';
