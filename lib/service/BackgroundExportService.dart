import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../widgets/AppToast.dart';
import '../widgets/ExportSuccessDialog.dart';
import '../utils/AppTaskActivity.dart';
import '../utils/ExportDiagnostics.dart';

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
    AppToast.show(
        appL10n.flowExportingP0InTheBackgroundYouCan((label).toString()),
        tone: AppToastTone.info);
    final finish = AppTaskActivity.begin();
    final queued = Stopwatch()..start();
    debugPrint('[ExportQueue] 图片导出入队：$label');
    _queue = _queue
        .then((_) => ExportDiagnostics.run(label, (log) {
              log.note('开始执行，排队耗时=${queued.elapsedMilliseconds}ms');
              return _runOne(label, task, log);
            }))
        .whenComplete(finish);
  }

  /// 导出可能在用户切走后才结束，再发一条系统通知。通知发不出去不影响导出结果。
  static Future<void> _notifySystem(String label, ExportDiagnostics log) async {
    if (!Platform.isAndroid) {
      log.note('非Android平台，跳过系统导出通知');
      return;
    }
    try {
      final status =
          await log.step('查询通知权限', () => Permission.notification.status);
      log.note('当前通知权限=$status');
      if (status.isDenied) {
        final requested =
            await log.step('请求通知权限', () => Permission.notification.request());
        log.note('请求后通知权限=$requested');
      }
      await log.step(
          '发送系统导出通知',
          () => _notificationChannel.invokeMethod<void>('notifyExportDone', {
                'title': appL10n.flowP0Exported(label.toString()),
                'text': appL10n.flowImageSavedTapToReturnToChiffonMai,
              }));
    } catch (error, stack) {
      log.note('发送导出通知失败，继续显示完成提示：$error\n$stack');
    }
  }

  static Future<void> _runOne(
    String label,
    Future<File?> Function(BuildContext context) task,
    ExportDiagnostics log,
  ) async {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) {
      log.note('导出取消：根Overlay不可用');
      AppToast.show(appL10n.flowCouldNotExportP0PleaseRetry((label).toString()),
          tone: AppToastTone.error);
      return;
    }
    // 在 Overlay 里面取一个 context，导出服务要从它往上找 Overlay。
    BuildContext? taskContext;
    final anchor = OverlayEntry(builder: (context) {
      taskContext = context;
      return const SizedBox.shrink();
    });
    overlay.insert(anchor);
    log.note('导出上下文Overlay已挂载');
    try {
      await log.step('等待导出上下文首帧', () => WidgetsBinding.instance.endOfFrame);
      final context = taskContext;
      if (context == null || !context.mounted) {
        throw StateError(appL10n.svcTheExportCanvasIsNotReady);
      }
      final file = await log.step('生成并保存图片', () => task(context));
      if (file == null) {
        log.note('导出失败：生成服务返回空文件');
        AppToast.show(
            appL10n
                .flowCouldNotExportP0CheckStoragePermission((label).toString()),
            tone: AppToastTone.error);
        return;
      }
      log.note('生成服务已返回文件：${file.path}');
      await _notifySystem(label, log);
      log.note('开始显示应用内导出完成提示');
      AppToast.show(
        appL10n.flowP0Exported((label).toString()),
        tone: AppToastTone.success,
        actionLabel: appL10n.flowView,
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
      log.note('应用内导出完成提示已提交');
    } catch (error, stack) {
      log.note('后台导出失败：$error\n$stack');
      AppToast.show(
          appL10n.flowCouldNotExportP0P1(
              (label).toString(), (error).toString()),
          tone: AppToastTone.error);
    } finally {
      log.note('开始移除导出上下文Overlay');
      anchor.remove();
      log.note('导出上下文Overlay已移除');
    }
  }
}
