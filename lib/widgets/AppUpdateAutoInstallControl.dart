import '../l10n/LocalizationsExtension.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../service/AppUpdateAutoInstallSettings.dart';
import '../service/BackgroundAppUpdateService.dart';
import 'AppSwitch.dart';
import 'AppUi.dart';

/// 设置页和下载窗口共用，开关旁始终保留测试性标记和安装影响说明。
class AppUpdateAutoInstallControl extends StatefulWidget {
  const AppUpdateAutoInstallControl({super.key});

  @override
  State<AppUpdateAutoInstallControl> createState() =>
      _AppUpdateAutoInstallControlState();
}

class _AppUpdateAutoInstallControlState
    extends State<AppUpdateAutoInstallControl> with WidgetsBindingObserver {
  final _settings = AppUpdateAutoInstallSettings.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 构建过程中不向已挂载的其他设置组件发送通知。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_settings.load());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_settings.load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hint = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.6,
        );
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _settings.enabled,
            onChanged:
                _settings.loaded && _settings.supported && !_settings.busy
                    ? (value) async {
                        await _settings.setEnabled(value);
                        await BackgroundAppUpdateService.instance.refresh();
                      }
                    : null,
            title: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(context.l10n.autoInstall),
                AppBadge(
                  text: context.l10n.experimental,
                  numeric: false,
                  background: scheme.tertiaryContainer,
                  foreground: scheme.onTertiaryContainer,
                ),
              ],
            ),
          ),
          Text(context.l10n.autoInstallHint, style: hint),
          const SizedBox(height: 8),
          Text(context.l10n.autoInstallNote, style: hint),
          if (_settings.loaded && !_settings.supported)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.l10n.autoInstallUnsupported, style: hint),
            ),
          if (_settings.enabled && !_settings.canInstall)
            TextButton(
              onPressed: _settings.openPermission,
              child: Text(context.l10n.allowInstallSource),
            ),
          if (_settings.error != null) ...[
            const SizedBox(height: 8),
            Text(context.l10n.autoInstallSettingsError,
                style: hint?.copyWith(color: scheme.error)),
            TextButton(
                onPressed: _settings.busy ? null : _settings.load,
                child: Text(context.l10n.reloadSettings)),
          ],
        ],
      ),
    );
  }
}
