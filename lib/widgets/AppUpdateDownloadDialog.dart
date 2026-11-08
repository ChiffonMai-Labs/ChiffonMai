import 'package:my_first_flutter_app/l10n/NativeAppText.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../service/AppUpdateDownloadService.dart';
import '../service/BackgroundAppUpdateService.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../constant/AppLinks.dart';
import 'AppDialogs.dart';
import 'AppUpdateAutoInstallControl.dart';
import 'SmoothLinearProgressIndicator.dart';

/// 仅查看全局下载任务；关闭窗口不会停止后台下载。
class AppUpdateDownloadDialog extends StatefulWidget {
  const AppUpdateDownloadDialog({super.key});
  @override
  State<AppUpdateDownloadDialog> createState() =>
      _AppUpdateDownloadDialogState();
}

class _AppUpdateDownloadDialogState extends State<AppUpdateDownloadDialog>
    with WidgetsBindingObserver {
  final _task = BackgroundAppUpdateService.instance;
  bool _installing = false,
      _needsPermission = false,
      _waitingPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_task.refresh());
  }

  Future<void> _install() async {
    if (_installing || _task.phase != 'ready') return;
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      final settings = await AppUpdateDownloadService.channel
          .invokeMapMethod<String, dynamic>('getAutoInstallSettings');
      if (!mounted) return;
      if (settings?['enabled'] == true &&
          settings?['supported'] == true &&
          settings?['canInstall'] == true &&
          _task.state['autoManualRequired'] != true) {
        final requested = await _task.confirmForegroundInstall(context);
        if (requested && mounted) Navigator.of(context).pop();
        return;
      }
      final result = await AppUpdateDownloadService.channel
          .invokeMethod<String>('installApk', {
        'path': _task.state['path'],
        'build': _task.state['build'],
      });
      if (!mounted) return;
      if (result == 'permission_required') {
        setState(() {
          _needsPermission = true;
          _error = context.l10n.flowAllowChiffonMaiToInstallUpdates;
        });
      } else if (result == 'launched') {
        Navigator.of(context).pop();
      }
    } on PlatformException catch (error) {
      if (mounted) setState(() => _error = error.message ?? context.l10n.flowCouldNotOpenInstaller);
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  Future<void> _openPermission() async {
    try {
      _waitingPermission = true;
      await AppUpdateDownloadService.channel
          .invokeMethod('openInstallSettings');
    } on PlatformException catch (error) {
      _waitingPermission = false;
      if (mounted) setState(() => _error = error.message ?? context.l10n.flowCouldNotOpenInstallationPermissionSettings);
    }
  }

  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted)
        setState(() => _error = error is PlatformException
            ? error.message ?? context.l10n.flowActionFailedPleaseRetry
            : context.l10n.flowActionFailedPleaseRetry);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingPermission) {
      _waitingPermission = false;
      unawaited(_install());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _task,
        builder: (context, _) {
          final ready = _task.phase == 'ready';
          final installing = _task.phase == 'installing';
          final total = (_task.state['total'] as num?)?.toInt() ?? 0;
          final received = (_task.state['received'] as num?)?.toInt() ?? 0;
          return AppAlertDialog(
            title: Text(ready || installing ? context.l10n.flowInstallUpdate : context.l10n.flowDownloadUpdateInBackground),
            scrollable: true,
            subtitle: _task.state['version'] == null
                ? null
                : 'v${_task.state['version']}',
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(nativeAppText(_error ?? '${_task.state['message'] ?? context.l10n.flowNoDownloadTask}')),
                  if (_task.active) ...[
                    const SizedBox(height: 16),
                    SmoothLinearProgressIndicator(
                        value: _task.phase != 'downloading' || total <= 0
                            ? null
                            : (received / total).clamp(0.0, 1.0)),
                    if (total > 0 && !installing)
                      Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              '${(received / 1048576).toStringAsFixed(1)} / '
                              '${(total / 1048576).toStringAsFixed(1)} MB')),
                  ],
                  const SizedBox(height: 20),
                  const AppUpdateAutoInstallControl(),
                ]),
            actionColumns: 1,
            actions: [
              TextButton(
                  onPressed: () {
                    _task.deferForegroundPrompt();
                    Navigator.of(context).pop();
                  },
                  child: Text(_task.active ? context.l10n.flowKeepUsingTheApp : context.l10n.featureClose)),
              if (_task.active)
                TextButton(
                    onPressed: () => _perform(_task.cancel),
                    child: Text(installing ? context.l10n.flowCancelInstallationTask : context.l10n.flowCancelDownload)),
              if (_task.phase == 'failed' || _task.phase == 'cancelled') ...[
                TextButton(
                    onPressed: () => _perform(_task.retry),
                    child:  Text(context.l10n.flowDownloadAgain)),
                TextButton(
                    onPressed: () => ExternalLaunchUtil.open(
                        Uri.parse(AppLinks.latestReleaseUrl)),
                    child:  Text(context.l10n.flowOpenDownloadPage)),
              ],
              if (ready)
                TextButton(
                    onPressed: _installing
                        ? null
                        : _needsPermission
                            ? _openPermission
                            : _install,
                    child: Text(_needsPermission ? context.l10n.flowAllowInstallation : context.l10n.flowInstallNow)),
            ],
          );
        },
      );
}
