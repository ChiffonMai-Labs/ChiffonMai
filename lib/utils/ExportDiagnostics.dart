import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../service/LogExportService.dart';

/// 仅在导出任务期间记录阶段、内存与帧响应；嵌套调用共用任务编号。
class ExportDiagnostics {
  ExportDiagnostics._(this.id, this.label);

  static final Object _zoneKey = Object();
  static int _nextId = 0;

  final int id;
  final String label;
  final Stopwatch _clock = Stopwatch()..start();
  String _stage = '准备';
  Timer? _timer;
  bool _active = true;
  int _lastBeatMs = 0;
  int _maxLoopDelayMs = 0;
  int _frames = 0;
  int _maxBuildUs = 0;
  int _maxRasterUs = 0;
  int? _frameRequestedAt;

  static Future<T> run<T>(
      String label, Future<T> Function(ExportDiagnostics log) action) async {
    final existing = Zone.current[_zoneKey] as ExportDiagnostics?;
    if (existing != null) return action(existing);
    final log = ExportDiagnostics._(++_nextId, label);
    log.note('任务开始，${_memory()}');
    WidgetsBinding.instance.addTimingsCallback(log._onTimings);
    log._timer = Timer.periodic(const Duration(seconds: 3), (_) => log._beat());
    try {
      return await runZoned(() => action(log), zoneValues: {_zoneKey: log});
    } catch (error, stack) {
      log.note('任务异常：$error\n$stack');
      rethrow;
    } finally {
      log._active = false;
      log._timer?.cancel();
      WidgetsBinding.instance.removeTimingsCallback(log._onTimings);
      log._recordLoopDelay();
      log.note('任务结束，最大心跳延迟=${log._maxLoopDelayMs}ms，${_memory()}');
      await LogExportService.instance.flush();
    }
  }

  void note(String message) => debugPrint(
      '[Export:$id] $label 阶段=$_stage 总耗时=${_clock.elapsedMilliseconds}ms $message');

  Future<T> step<T>(String stage, Future<T> Function() action) async {
    final previous = _stage;
    _stage = stage;
    final watch = Stopwatch()..start();
    note('开始');
    // 进入截图等可能卡住的调用前先落盘，避免 UI 停顿时两秒防抖来不及写。
    await LogExportService.instance.flush();
    watch.reset();
    try {
      final result = await action();
      note('完成，阶段耗时=${watch.elapsedMilliseconds}ms');
      return result;
    } catch (error, stack) {
      note('失败，阶段耗时=${watch.elapsedMilliseconds}ms：$error\n$stack');
      rethrow;
    } finally {
      _stage = previous;
    }
  }

  void _onTimings(List<ui.FrameTiming> timings) {
    for (final timing in timings) {
      _frames++;
      _maxBuildUs = math.max(_maxBuildUs, timing.buildDuration.inMicroseconds);
      _maxRasterUs =
          math.max(_maxRasterUs, timing.rasterDuration.inMicroseconds);
    }
  }

  int _recordLoopDelay() {
    final now = _clock.elapsedMilliseconds;
    final gap = now - _lastBeatMs;
    _maxLoopDelayMs = math.max(_maxLoopDelayMs, math.max(0, gap - 3000));
    _lastBeatMs = now;
    return gap;
  }

  void _beat() {
    final binding = WidgetsBinding.instance;
    final gap = _recordLoopDelay();
    final frameWait = _frameRequestedAt;
    note('心跳：间隔=${gap}ms lifecycle=${binding.lifecycleState?.name} '
        'framesEnabled=${binding.framesEnabled} 已回报帧=$_frames '
        '最大UI=${(_maxBuildUs / 1000).toStringAsFixed(1)}ms '
        '最大Raster=${(_maxRasterUs / 1000).toStringAsFixed(1)}ms '
        '待响应帧=${frameWait == null ? "无" : "${_clock.elapsedMilliseconds - frameWait}ms"} '
        '${_memory()}');
    _frames = _maxBuildUs = _maxRasterUs = 0;
    // 只在前台且仍在导出时，每个心跳最多请求一帧，避免把静止页面误判为卡死。
    // 上一帧未响应时不再添加回调，任务结束后停止探测。
    if (frameWait == null &&
        binding.framesEnabled &&
        binding.lifecycleState == AppLifecycleState.resumed) {
      final requestedAt = _clock.elapsedMilliseconds;
      _frameRequestedAt = requestedAt;
      binding.addPostFrameCallback((_) {
        if (!_active) return;
        _frameRequestedAt = null;
        note('诊断帧框架回调已响应，等待=${_clock.elapsedMilliseconds - requestedAt}ms');
      });
      binding.scheduleFrame();
    }
  }

  static String _memory() {
    try {
      return '进程RSS=${(ProcessInfo.currentRss / 1048576).toStringAsFixed(1)}MiB '
          '峰值RSS=${(ProcessInfo.maxRss / 1048576).toStringAsFixed(1)}MiB';
    } catch (_) {
      return '进程内存统计不可用';
    }
  }
}
