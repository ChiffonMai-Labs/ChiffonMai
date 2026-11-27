import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simai_flutter/simai_flutter.dart';

import '../../utils/AppTaskActivity.dart';

/// 谱面视频导出的宿主保活与 Android 通知栏进度同步服务。
class VideoExportBackgroundService {
  VideoExportBackgroundService._();

  static final VideoExportBackgroundService instance =
      VideoExportBackgroundService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.app/video_export_notification');
  static const Duration _progressThrottle = Duration(milliseconds: 400);

  /// 通知被点击且需要回到导出页时递增。
  final ValueNotifier<int> openExportRequestNonce = ValueNotifier<int>(0);

  bool _initialized = false;
  SimaiVideoExportTask? _trackedTask;

  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;

    if (_isAndroid) {
      _channel.setMethodCallHandler(_handleNativeCall);
      unawaited(_consumePendingOpenRequest());
    }

    SimaiVideoExporter.instance.activeTaskChanges.listen(_onTaskChanged);

    final active = SimaiVideoExporter.instance.activeTask;
    if (active != null) {
      _onTaskChanged(active);
    }
  }

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onCancelRequested':
        final task = SimaiVideoExporter.instance.activeTask;
        if (task != null) {
          unawaited(task.cancel());
          _pushProgress(task, task.currentProgress, cancelling: true);
        }
        break;
      case 'onOpenVideoExport':
        openExportRequestNonce.value++;
        break;
    }
  }

  Future<void> _consumePendingOpenRequest() async {
    try {
      final pending =
          await _channel.invokeMethod<bool>('takePendingOpenVideoExport');
      if (pending == true) {
        openExportRequestNonce.value++;
      }
    } catch (_) {
    }
  }

  void _onTaskChanged(SimaiVideoExportTask? task) {
    if (task == null || identical(_trackedTask, task)) return;
    _attachTask(task);
  }

  void _attachTask(SimaiVideoExportTask task) {
    _trackedTask = task;
    final finishTaskActivity = AppTaskActivity.begin();
    if (_isAndroid) {
      unawaited(_ensureNotificationPermission());
    }

    var lastSentAt = DateTime.fromMillisecondsSinceEpoch(0);
    SimaiVideoExportPhase? lastPhase;
    bool? lastCancelling;

    void sendThrottled(SimaiVideoExportProgress progress, {bool force = false}) {
      final now = DateTime.now();
      final cancelling = task.isCancelling;
      if (!force &&
          progress.phase == lastPhase &&
          cancelling == lastCancelling &&
          now.difference(lastSentAt) < _progressThrottle) {
        return;
      }
      lastSentAt = now;
      lastPhase = progress.phase;
      lastCancelling = cancelling;
      _pushProgress(task, progress, cancelling: cancelling);
    }

    sendThrottled(task.currentProgress, force: true);

    late final StreamSubscription<SimaiVideoExportProgress> progressSub;
    progressSub = task.progress.listen((progress) {
      sendThrottled(progress);
    });

    unawaited(
      task.result.then(
        (result) {
          _sendFinish(
            status: 'completed',
            title: task.metadata.title,
            message: result.savedToGallery ? '已直接保存到系统相册' : '点击返回保存或分享',
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          if (error is SimaiVideoExportCancelledException) {
            _sendFinish(status: 'cancelled', title: task.metadata.title);
          } else {
            _sendFinish(
              status: 'failed',
              title: task.metadata.title,
              message: error.toString(),
            );
          }
        },
      ).whenComplete(() async {
        await progressSub.cancel();
        if (identical(_trackedTask, task)) {
          _trackedTask = null;
        }
        finishTaskActivity();
      }),
    );
  }

  Future<void> _ensureNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {
    }
  }

  void _pushProgress(
    SimaiVideoExportTask task,
    SimaiVideoExportProgress progress, {
    required bool cancelling,
  }) {
    if (!_isAndroid) return;
    final permille = (progress.overallFraction * 1000).round().clamp(0, 1000);
    final percent = (progress.overallFraction * 100).clamp(0.0, 100.0);
    final phaseLabel = cancelling
        ? '正在取消导出…'
        : switch (progress.phase) {
            SimaiVideoExportPhase.preparing => '正在准备渲染资源',
            SimaiVideoExportPhase.rendering => '正在渲染并编码视频',
            SimaiVideoExportPhase.mixingAudio => '正在混合音乐和正解音',
            SimaiVideoExportPhase.muxing => '正在封装 MP4',
            SimaiVideoExportPhase.completed => '导出完成',
            SimaiVideoExportPhase.cancelled => '导出已取消',
            SimaiVideoExportPhase.failed => '导出失败',
          };

    final remaining = progress.estimatedRemaining;
    final detailParts = <String>[
      phaseLabel,
      if (!cancelling) '${percent.toStringAsFixed(0)}%',
      if (!cancelling && remaining != null) '剩余 ${_formatDuration(remaining)}',
    ];
    final subText = progress.totalFrames > 0
        ? '${progress.completedFrames} / ${progress.totalFrames} 帧'
        : null;
    final indeterminate = !cancelling &&
        (progress.phase == SimaiVideoExportPhase.preparing ||
            progress.totalFrames == 0);

    unawaited(
      _channel.invokeMethod<void>('updateProgress', <String, Object?>{
        'title': task.metadata.title,
        'detailText': detailParts.join(' · '),
        'subText': subText,
        'progressPermille': permille,
        'indeterminate': indeterminate,
        'cancelling': cancelling,
      }).catchError((_) {}),
    );
  }

  void _sendFinish({
    required String status,
    required String title,
    String? message,
  }) {
    if (!_isAndroid) return;
    unawaited(
      _channel.invokeMethod<void>('finish', <String, Object?>{
        'status': status,
        'title': title,
        'message': message,
      }).catchError((_) {}),
    );
  }

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 359999);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds ~/ 60) % 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) return '$hours时${minutes.toString().padLeft(2, '0')}分';
    if (minutes > 0) return '$minutes分${seconds.toString().padLeft(2, '0')}秒';
    return '$seconds秒';
  }
}
