import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/service/DataBackupService.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ExportPathUtil.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/ExportSuccessDialog.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  final DataBackupService _service = DataBackupService();

  bool _isExporting = false;
  bool _isImporting = false;

  /// 已经确认、正在往 prefs 里写的那一段。
  ///
  /// 恢复是「先清空再逐键写入」，几百个键会明显卡一下。**这一段必须一直挂着
  /// loading 且禁用按钮**：既不给用户「点了没反应、是不是卡死了」的错觉，
  /// 也避免他连点两次、让两轮写入交错在同一份 prefs 上。
  bool _isRestoring = false;
  String? _lastExportPath;

  /// 任一导入/导出在进行中：两个按钮都要禁用，避免互相踩。
  bool get _busy => _isExporting || _isImporting;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return BackgroundPageScaffold(
      title: context.l10n.featureDataBackup,
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
            AppDesignTokens.gutter, AppDesignTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.linkBlue(brightness), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.flowBackupsExportFavoritesChartNotesAccountProfiles,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDesignTokens.cardGap),

            // 导出区域
            _buildSectionCard(
              icon: Icons.file_upload,
              title: context.l10n.flowExportBackup,
              subtitle: context.l10n.flowExportLocalDataAsAJSONFile,
              buttonText: _isExporting ? context.l10n.flowExporting3 : context.l10n.flowExportBackupFile,
              isLoading: _isExporting,
              onPressed: _busy ? null : _handleExport,
              emphasis: true,
            ),

            // 上次导出路径
            if (_lastExportPath != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppSurfaces.inset(context),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 18, color: AppColors.successGreen(brightness)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.flowExportedToP0((_lastExportPath).toString()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: AppDesignTokens.cardGap),

            // 导入区域
            _buildSectionCard(
              icon: Icons.file_download,
              title: context.l10n.flowImportBackup,
              subtitle: context.l10n.flowRestoreDataFromAJSONBackup,
              buttonText: _isRestoring
                  ? context.l10n.flowRestoringData
                  : (_isImporting ? context.l10n.flowImporting : context.l10n.flowChooseBackupFile),
              isLoading: _isImporting || _isRestoring,
              onPressed: _busy ? null : _handleImport,
              warningText: context.l10n.flowImportClearsAllCurrentLocalDataBefore,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required bool isLoading,
    required VoidCallback? onPressed,
    bool emphasis = false,
    String? warningText,
  }) {
    final scheme = Theme.of(context).colorScheme;
    // 导入会清空数据，不做成主按钮；危险提示由下方红字承担。
    final buttonBg = emphasis ? scheme.primary : scheme.primaryContainer;
    final buttonFg = emphasis ? scheme.onPrimary : scheme.onPrimaryContainer;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                child: Icon(icon, size: 24, color: scheme.onPrimaryContainer),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: buttonFg),
                    )
                  : Icon(
                      icon == Icons.file_upload
                          ? Icons.file_upload
                          : Icons.file_download,
                      color: buttonFg,
                    ),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonFg,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusMedium),
                ),
              ),
            ),
          ),
          if (warningText != null) ...[
            SizedBox(height: 12),
            Text(
              warningText,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.errorRed(Theme.of(context).brightness),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleExport() async {
    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '备份', title: context.l10n.flowChooseWhereToSaveTheBackup)) {
      return;
    }
    setState(() => _isExporting = true);

    try {
      String? fallbackPath;
      final path = await _service.exportToFile(
        onFallback: (value) => fallbackPath = value,
      );
      if (path != null && mounted) {
        setState(() {
          _lastExportPath = path;
          _isExporting = false;
        });
        await showExportSuccessDialog(
          context,
          filePath: path,
          fileName: '备份文件',
          warning: fallbackPath == null
              ? context.l10n.flowFindTheFileInDownloadsChiffonMaiIn
              : context.l10n.flowThePublicDirectoryIsNotWritableSaved3,
        );
      } else {
        if (mounted) {
          setState(() => _isExporting = false);
          AppToast.show(context.l10n.flowExportCancelled);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        AppToast.show(context.l10n.flowExportFailedP0((e.toString().replaceFirst("Exception: ", "")).toString()), tone: AppToastTone.error);
      }
    }
  }

  Future<void> _handleImport() async {
    setState(() => _isImporting = true);

    try {
      final backup = await _service.importFromFile();

      if (!mounted) return;
      setState(() => _isImporting = false);

      if (backup == null) {
        return; // 用户取消
      }

      // 显示确认对话框
      final exportedAt = backup['exportedAt'] ?? context.l10n.flowUnknown;
      final keyCount = backup['keyCount'] ?? 0;
      final version = backup['version'] ?? '?';
      final fileCount = backup['files'] is Map ? (backup['files'] as Map).length : 0;
      final skippedCacheKeys = backup['skippedCacheKeys'];

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AppAlertDialog(
          scrollable: true,
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.warningOrange(Theme.of(context).brightness),
                  size: 28),
              SizedBox(width: 8),
              Text(context.l10n.flowConfirmRestore),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.flowRestoringOverwritesCurrentLocalSettingsAndProfiles),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.flowBackupVersionVP0((version).toString()), style: TextStyle(fontSize: 13)),
                    Text(context.l10n.flowExportedP0((exportedAt).toString()), style: TextStyle(fontSize: 13)),
                    Text(context.l10n.flowContainsP0DataItems((keyCount).toString()), style: TextStyle(fontSize: 13)),
                    Text(context.l10n.flowUserFilesP0((fileCount).toString()), style: TextStyle(fontSize: 13)),
                    if (skippedCacheKeys != null)
                      Text(context.l10n.flowExcludedP0CacheItems((skippedCacheKeys).toString()),
                          style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                context.l10n.flowSongMaidataAndLeaderboardCachesAreExcluded,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.flowThisCannotBeUndoneContinue,
                style: TextStyle(
                  color: AppColors.errorRed(Theme.of(context).brightness),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.l10n.featureCancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.warningOrange(Theme.of(context).brightness),
                foregroundColor: Colors.white,
              ),
              child: Text(context.l10n.flowRestore),
            ),
          ],
        ),
      );

      if (confirm == true) {
        // 恢复期间一直挂 loading 并禁用按钮：这一段要逐键写 prefs，会明显卡一下，
        // 不给反馈的话用户会以为「导入卡死」，还可能连点触发第二轮写入。
        if (mounted) setState(() => _isRestoring = true);
        try {
          final count = await _service.restoreBackup(backup);
          // 把恢复到内存的各个单例重新读一遍：这些 Store 的保存都是整体写回，
          // 不重载的话用户恢复后随手改一下，就会用旧值把刚导入的数据盖掉。
          await _service.reloadAfterRestore();
          if (mounted) {
            AppToast.show(context.l10n.flowRestoredP0SettingsAndP1UserFiles((count).toString(), (fileCount).toString()), tone: AppToastTone.success);
          }
        } finally {
          if (mounted) setState(() => _isRestoring = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _isRestoring = false;
        });
        AppToast.show(context.l10n.flowImportFailedP02((e.toString().replaceFirst("Exception: ", "")).toString()), tone: AppToastTone.error);
      }
    }
  }
}
