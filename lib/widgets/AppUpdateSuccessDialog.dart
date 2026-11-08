import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import 'AppDialogs.dart';

/// 只展示经原生核实的自动安装结果，版本信息取自当前已安装的应用。
class AppUpdateSuccessDialog extends StatelessWidget {
  final String version;
  final String buildNumber;
  final String updateLog;

  const AppUpdateSuccessDialog({
    super.key,
    required this.version,
    required this.buildNumber,
    this.updateLog = '',
  });

  @override
  Widget build(BuildContext context) => AppDialog(
        tone: AppDialogTone.success,
        title: context.l10n.autoUpdateSuccessTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.autoUpdateSuccessBody),
            const SizedBox(height: 12),
            Text(
                context.l10n.flowCurrentVersionP0BuildP1(version, buildNumber)),
            if (updateLog.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(context.l10n.autoUpdateChangesTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(updateLog, style: const TextStyle(height: 1.5)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.featureGotIt),
          ),
        ],
      );
}
