import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/CacheKeyConstant.dart';
import 'AwmcApiService.dart';

/// AWMC 功能的本地状态：审计日志。
///
/// 网关开发者令牌只保存在服务端环境变量中，由服务端代理注入。
/// 这里保留同名接口是为了兼容旧版控制台代码，但不会读取、保存或返回
/// 任何客户端令牌，也不会要求普通用户填写 `gw_...` 密钥。
class AwmcCredentials {
  AwmcCredentials._();

  /// 兼容旧页面的加载接口；客户端没有需要加载的网关令牌。
  static Future<void> ensureLoaded() async {}

  /// 兼容旧页面：代理模式下服务是否可用由 `/api/awmc/v1/health` 决定。
  static String get token => '';
  static bool get hasToken => true;
  static const String tokenSource = '服务端安全代理';
  static const String maskedToken = '服务端保存';
  static const String buildTimeToken = '';

  /// 二维码格式校验与开发者令牌无关，保留给旧版输入组件使用。
  static bool isValidQrcode(String value) =>
      value.trim().startsWith('SGWCMAID') && value.trim().length > 20;

  /// 旧版调用的兼容空操作，防止把开发者密钥再次写入客户端。
  static Future<void> saveToken(String value) async {}
  static Future<void> clearToken() async {}
}

/// 本地审计日志：记录「时间 / 接口 / 消耗 / 结果」。
///
/// **绝不写入 qrcode、令牌或任何请求体** —— 这是官方文档的硬要求，
/// 也是出事之后唯一能自查的东西（谁在什么时候花了多少 Token、改了什么）。
class AwmcAuditLog {
  AwmcAuditLog._();

  static const int _maxEntries = 200;
  static final List<AwmcAuditEntry> _entries = [];
  static bool _loaded = false;

  static List<AwmcAuditEntry> get entries => List.unmodifiable(_entries);

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(CacheKeyConstant.awmcAuditLog);
      if (raw != null && raw.isNotEmpty) {
        final list = json.decode(raw);
        if (list is List) {
          _entries
            ..clear()
            ..addAll(list.whereType<Map>().map(
                (e) => AwmcAuditEntry.fromJson(e.cast<String, dynamic>())));
        }
      }
    } catch (e) {
      debugPrint('[AWMC] 审计日志读取失败（忽略）: ${AwmcApiService.redact('$e')}');
    }
    _loaded = true;
  }

  static Future<void> record(AwmcCallResult result, {String? note}) async {
    await ensureLoaded();
    _entries.insert(
      0,
      AwmcAuditEntry(
        timeMs: DateTime.now().millisecondsSinceEpoch,
        method: result.method,
        path: result.path,
        ok: result.ok,
        httpStatus: result.httpStatus,
        costTokens: result.ok ? result.costTokens : 0,
        // displayMessage 自带脱敏 + 限长（600 字符），可直接入库
        message: result.ok ? null : result.displayMessage,
        elapsedMs: result.elapsedMs,
        note: note == null ? null : AwmcApiService.redact(note),
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(CacheKeyConstant.awmcAuditLog,
          json.encode(_entries.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('[AWMC] 审计日志写入失败（忽略）: ${AwmcApiService.redact('$e')}');
    }
  }

  static Future<void> clear() async {
    _entries.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CacheKeyConstant.awmcAuditLog);
  }
}

/// 审计日志条目。字段刻意保持「无敏感信息」。
class AwmcAuditEntry {
  final int timeMs;
  final String method;
  final String path;
  final bool ok;
  final int httpStatus;
  final int costTokens;

  /// 失败原因（`AwmcCallResult.displayMessage`，**已脱敏、已限长**）。
  ///
  /// 为什么要存：只有 ok/httpStatus 时，事后根本分不清「回源超时（httpStatus 0）」
  /// 和「业务返回 returnCode 异常」，也没法判断是网关挂了还是凭据不对。
  final String? message;

  /// 这一次调用自己花了多久（毫秒）。旧记录没有这个字段，读出为 0。
  final int elapsedMs;

  final String? note;

  const AwmcAuditEntry({
    required this.timeMs,
    required this.method,
    required this.path,
    required this.ok,
    required this.httpStatus,
    required this.costTokens,
    this.message,
    this.elapsedMs = 0,
    this.note,
  });

  factory AwmcAuditEntry.fromJson(Map<String, dynamic> json) => AwmcAuditEntry(
        timeMs: json['timeMs'] ?? 0,
        method: json['method']?.toString() ?? '',
        path: json['path']?.toString() ?? '',
        ok: json['ok'] == true,
        httpStatus: json['httpStatus'] ?? 0,
        costTokens: json['costTokens'] ?? 0,
        message: json['message']?.toString(),
        elapsedMs: json['elapsedMs'] ?? 0,
        note: json['note']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'timeMs': timeMs,
        'method': method,
        'path': path,
        'ok': ok,
        'httpStatus': httpStatus,
        'costTokens': costTokens,
        if (message != null) 'message': message,
        'elapsedMs': elapsedMs,
        if (note != null) 'note': note,
      };

  DateTime get time => DateTime.fromMillisecondsSinceEpoch(timeMs);
}
