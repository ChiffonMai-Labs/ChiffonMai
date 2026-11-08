import 'package:my_first_flutter_app/l10n/NativeAppText.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/AppDialogs.dart';
import '../widgets/ExportSuccessDialog.dart';
import 'BackgroundExportService.dart';
import 'LogExportService.dart';

/// 上次崩溃后的善后：启动时自动导出日志、发系统通知、在 App 内提示。
///
/// 崩溃记录由 Android 侧的 `CrashReporter` 留下；iOS 暂时没有对应实现。
class CrashReportService {
  CrashReportService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.app/crash_report');

  static Future<void> checkPreviousCrash() async {
    if (!Platform.isAndroid) return;
    try {
      final crash =
          await _channel.invokeMapMethod<String, String>('takePendingCrash');
      if (crash == null) return;
      final reason = crash['reason'] ?? '应用崩溃';
      final time = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(crash['time'] ?? '') ?? 0);
      // 先写进日志，导出的文件里才有崩溃详情。
      debugPrint('[Crash] 上次异常退出：$reason，时间 ${time.toIso8601String()}\n'
          '${crash['detail'] ?? ''}');

      File? file;
      try {
        file = await LogExportService.instance.export();
      } catch (error) {
        debugPrint('[Crash] 自动导出日志失败: $error');
      }
      await _notify(file != null);
      await _showDialog(reason, file);
    } on MissingPluginException {
      // 原生部分还是旧版本时不处理。
    } catch (error) {
      debugPrint('[Crash] 崩溃检查失败: $error');
    }
  }

  static Future<void> _notify(bool exported) async {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) await Permission.notification.request();
      await _channel.invokeMethod<void>('notifyCrashReport', {
        'title': appL10n.flowChiffonMaiClosedUnexpectedlyLastTime,
        'text': exported ? appL10n.svcTheLogWasExportedAutomaticallyYouCan : appL10n.svcLogExportFailedYouCanExportIt,
      });
    } catch (error) {
      debugPrint('[Crash] 发送通知失败: $error');
    }
  }

  /// 等主界面出来后再弹，最多等 30 秒。
  static Future<void> _showDialog(String reason, File? file) async {
    BuildContext? context;
    for (var i = 0; i < 60 && context == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      context = BackgroundExport.navigatorKey.currentState?.overlay?.context;
    }
    if (context == null || !context.mounted) return;
    if (file == null) {
      await showAppNoticeDialog(
        context,
        title: appL10n.flowChiffonMaiClosedUnexpectedlyLastTime,
        message: appL10n.flowReasonP0AutomaticLogExportFailedExport(nativeAppText(reason)),
      );
      return;
    }
    await showExportSuccessDialog(
      context,
      title: appL10n.flowChiffonMaiClosedUnexpectedlyLastTime,
      successPrefix: appL10n.svcReasonP0TheLogWasExportedAutomatically((nativeAppText(reason)).toString()),
      filePath: file.path,
      fileName: file.path.split(RegExp(r'[/\\]')).last,
    );
  }
}
