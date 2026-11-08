import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import 'AppDialogs.dart';

/// 前台安装必须由用户确认，明确说明退后台、结束旧进程及稍后的行为。
class AppUpdateInstallPrompt extends StatelessWidget {
  final String version;
  final ValueListenable<bool> busy;

  const AppUpdateInstallPrompt({
    super.key,
    required this.version,
    this.busy = const AlwaysStoppedAnimation(false),
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: busy,
        builder: (context, isBusy, _) => AppAlertDialog(
          icon: const Icon(Icons.system_update_rounded),
          title: Text(context.l10n.foregroundUpdateTitle),
          subtitle: 'v$version',
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.foregroundUpdateBody),
              const SizedBox(height: 12),
              Text(context.l10n.foregroundUpdateLaterHint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
              if (isBusy) ...[
                const SizedBox(height: 12),
                Text(context.l10n.foregroundUpdateBusy,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.updateLater),
            ),
            FilledButton(
              onPressed: isBusy ? null : () => Navigator.pop(context, true),
              child: Text(context.l10n.exitAndUpdate),
            ),
          ],
        ),
      );
}
