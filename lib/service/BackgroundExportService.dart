import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/AppToast.dart';
import '../widgets/ExportSuccessDialog.dart';

/// 在后台导出图片：不弹阻塞对话框，用户可以继续操作甚至离开页面，结束后在顶部提示。
///
/// 导出画布挂在根 Overlay 上，不依赖发起导出的页面。多个任务按顺序执行，
/// 单张长图的位图就有上百 MB，同时跑容易把低内存机撑爆。
class BackgroundExport {
  BackgroundExport._();

  /// 全 App 的 Navigator，由 `MaterialApp` 使用。
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> _queue = Future<void>.value();

  static const MethodChannel _notificationChannel =
      MethodChannel('com.example.app/export_notification');

  /// [label] 用在提示里；[task] 收到的 context 在任务期间一直有效，不要用页面的 context。
  /// 任务里不能依赖页面的 `widget`，需要的值在调用前取好。
  static void run({
    required String label,
    required Future<File?> Function(BuildContext context) task,
  }) {
    AppToast.show('正在后台导出$label，可以继续其它操作',
        tone: AppToastTone.info);
    _queue = _queue.then((_) => _runOne(label, task));
  }

  /// 导出可能在用户切走后才结束，再发一条系统通知。通知发不出去不影响导出结果。
  static Future<void> _notifySystem(String label) async {
    if (!Platform.isAndroid) return;
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) await Permission.notification.request();
      await _notificationChannel.invokeMethod<void>('notifyExportDone', {
        'title': '$label导出成功',
        'text': '图片已保存，点按回到 ChiffonMai',
      });
    } catch (error) {
      debugPrint('发送导出通知失败: $error');
    }
  }

  static Future<void> _runOne(
    String label,
    Future<File?> Function(BuildContext context) task,
  ) async {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      AppToast.show('$label导出失败，请重试', tone: AppToastTone.error);
      return;
    }
    // 在 Overlay 里面取一个 context，导出服务要从它往上找 Overlay。
    BuildContext? taskContext;
    final anchor = OverlayEntry(builder: (context) {
      taskContext = context;
      return const SizedBox.shrink();
    });
    overlay.insert(anchor);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final context = taskContext;
      if (context == null || !context.mounted) {
        throw StateError('导出画布未就绪');
      }
      final file = await task(context);
      if (file == null) {
        AppToast.show('$label导出失败，请检查存储权限后重试',
            tone: AppToastTone.error);
        return;
      }
      await _notifySystem(label);
      AppToast.show(
        '$label导出成功',
        tone: AppToastTone.success,
        actionLabel: '查看',
        duration: const Duration(seconds: 6),
        onAction: () {
          final current = navigatorKey.currentState?.overlay?.context;
          if (current == null) return;
          showExportSuccessDialog(
            current,
            filePath: file.path,
            fileName: file.path.split('/').last,
            // iOS 的图片存在应用文档目录，不进相册。
            showViewImage: Platform.isAndroid,
          );
        },
      );
    } catch (error) {
      debugPrint('后台导出失败（$label）: $error');
      AppToast.show('$label导出失败：$error', tone: AppToastTone.error);
    } finally {
      anchor.remove();
    }
  }
}
