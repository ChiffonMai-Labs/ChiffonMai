import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'AppUpdateDownloadService.dart';

/// 以 Android 原生保存的授权为准；读取设置从不替用户开启安装。
class AppUpdateAutoInstallSettings extends ChangeNotifier {
  static final instance = AppUpdateAutoInstallSettings();

  bool enabled = false, supported = false, canInstall = false;
  bool loaded = false, busy = false;
  String? error;

  void _apply(Map<dynamic, dynamic>? value) {
    enabled = value?['enabled'] == true;
    supported = value?['supported'] == true;
    canInstall = value?['canInstall'] == true;
    loaded = true;
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      _apply(await AppUpdateDownloadService.channel
          .invokeMapMethod<dynamic, dynamic>('getAutoInstallSettings'));
    } catch (_) {
      error = appL10n.flowCouldNotReadAutomaticInstallationSettingsPlease;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (busy || !loaded || !supported || value == enabled) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      _apply(await AppUpdateDownloadService.channel
          .invokeMapMethod<dynamic, dynamic>(
              'setAutoInstallEnabled', {'enabled': value}));
    } on PlatformException catch (e) {
      error = e.message ?? appL10n.flowCouldNotSaveAutomaticInstallationSettingsPlease;
    } catch (_) {
      error = appL10n.flowCouldNotSaveAutomaticInstallationSettingsPlease;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> openPermission() async {
    try {
      await AppUpdateDownloadService.channel.invokeMethod('openInstallSettings');
    } catch (_) {
      error = appL10n.flowCouldNotOpenInstallationSourceSettingsAllow;
      notifyListeners();
    }
  }
}
