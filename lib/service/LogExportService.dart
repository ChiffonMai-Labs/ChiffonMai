import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/ExportPathUtil.dart';

/// 轻量日志环形缓存。只保留最近 2000 行，用户主动点击时写到公开目录。
class LogExportService {
  LogExportService._();
  static final instance = LogExportService._();
  static const _maxLines = 2000;
  final List<String> _lines = [];
  bool _installed = false;
  final _startedAt = DateTime.now();
  int _characters = 0;
  Timer? _flushTimer;
  Future<void> _writes = Future<void>.value();
  Future<void>? _ready;
  File? _sessionFile;
  String _previousSession = '';

  @visibleForTesting
  static String redact(String text) {
    final safe = text
        .replaceAll(RegExp(r'SGWCMAID[A-Za-z0-9]+'), '[二维码已隐藏]')
        .replaceAll(RegExp(r'\b(?:gw_|eyJ)[A-Za-z0-9_.-]+'), '[凭据已隐藏]')
        .replaceAllMapped(
          RegExp(
              r'''(password|passwd|token|authorization|cookie|api[_-]?key|import[_-]?token)["']?\s*[:=]\s*["']?[^\s,;}"']+''',
              caseSensitive: false),
          (match) => '${match[1]}=[已隐藏]',
        );
    // 调用栈中的类名也可能很长；保留栈帧，避免脱敏把定位信息一起抹掉。
    return safe.split('\n').map((line) {
      if (RegExp(r'^\s*(?:#\d+\b|package:|dart:)').hasMatch(line)) return line;
      return line.replaceAll(RegExp(r'\b[A-Za-z0-9_-]{32,}\b'), '[长标识已隐藏]');
    }).join('\n');
  }

  Future<void> _prepareSession() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _sessionFile = File('${dir.path}/recent-diagnostic-log.txt');
      if (await _sessionFile!.exists() &&
          await _sessionFile!.length() <= 1024 * 1024) {
        _previousSession = redact(await _sessionFile!.readAsString());
      }
    } catch (_) {
      // 日志持久化不可用时继续保留本次内存日志。
    }
  }

  Future<void> _persist() {
    final text = _lines.join('\n');
    _writes = _writes.then((_) async {
      await _ready;
      final file = _sessionFile;
      if (file == null) return;
      try {
        await file.writeAsString(text, flush: true);
      } catch (_) {}
    });
    return _writes;
  }

  void install() {
    if (_installed) return;
    // 必须在替换全局回调之前捕获原始实现。late 延迟读取会在第一次日志
    // 到来时再次读到包装器本身，形成递归，debug 模式下很快就会堆栈溢出。
    final original = debugPrint;
    _installed = true;
    _ready = _prepareSession();
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.isNotEmpty) {
        var safe = redact(message);
        if (safe.length > 6000) safe = '${safe.substring(0, 6000)}…[已截断]';
        final line = '${DateTime.now().toIso8601String()} $safe';
        _lines.add(line);
        _characters += line.length;
        while (_lines.length > _maxLines || _characters > 256 * 1024) {
          _characters -= _lines.removeAt(0).length;
        }
        if (_flushTimer?.isActive != true) {
          _flushTimer =
              Timer(const Duration(seconds: 2), () => unawaited(_persist()));
        }
      }
      original(message, wrapWidth: wrapWidth);
    };
    // Release 版布局错误的 ErrorWidget 可能只呈现一块灰黑区域。
    // 保留原错误处理，同时把异常和调用栈纳入应用内导出的日志，避免仅看
    // logcat 的 Surface 警告就误判小窗黑屏的原因。
    final originalFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      debugPrint(
          '[FlutterError] ${details.exceptionAsString()}\n${details.stack ?? ""}');
      originalFlutterError?.call(details);
    };
    final originalPlatformError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('[UnhandledError] $error\n$stack');
      return originalPlatformError?.call(error, stack) ?? false;
    };
  }

  Future<File> export({void Function(String path)? onFallback}) async {
    await _ready;
    await _persist();
    final info = await PackageInfo.fromPlatform();
    final prefs = await SharedPreferences.getInstance();
    final report = StringBuffer()
      ..writeln('ChiffonMai 日志导出')
      ..writeln('时间: ${DateTime.now().toIso8601String()}')
      ..writeln('版本: ${info.version}+${info.buildNumber}')
      ..writeln('本次启动: ${_startedAt.toIso8601String()}')
      ..writeln(
          '平台: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}')
      ..writeln('生命周期: ${WidgetsBinding.instance.lifecycleState}')
      ..writeln('允许帧调度: ${WidgetsBinding.instance.framesEnabled}')
      ..writeln(
          '导航样式: ${prefs.getString('navigation_bar_style') ?? 'standard'}')
      ..writeln(
          '页面动画: ${prefs.getBool('navigation_transition_enabled') ?? true}')
      ..writeln(
          '沉浸式状态栏: ${prefs.getBool('immersive_status_bar_enabled') ?? false}');
    for (final view in PlatformDispatcher.instance.views) {
      report.writeln(
          '窗口: physical=${view.physicalSize}, dpr=${view.devicePixelRatio}, '
          'logical=${view.physicalSize / view.devicePixelRatio}, padding=${view.padding}, '
          'insets=${view.viewInsets}, refreshRate=${view.display.refreshRate}');
    }
    report
      ..writeln('说明: 此文件是应用日志；Android 原生 Surface/Vulkan/系统窗口问题仍需完整 adb logcat。')
      ..writeln('--- 上次会话末尾日志（如有） ---')
      ..writeln(_previousSession)
      ..writeln('--- 本次最近日志 ---')
      ..writeln(_lines.join('\n'));
    return ExportPathUtil.writeExportTextFile(
        fileName: 'chiffonmai-log-${DateTime.now().millisecondsSinceEpoch}.txt',
        content: report.toString(),
        subDir: '日志',
        onFallback: onFallback,
        allowPrivateFallback: false);
  }
}
