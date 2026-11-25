import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';
import '../../utils/SensitiveRedactor.dart';

/// AWMC 网关代理客户端。
///
/// 开发者网关令牌只保存在服务端环境中，App 通过 `/api/awmc` 代理访问，
/// 不再把 `gw_...` 令牌放进 APK 或要求普通用户输入。
///
/// 设计原则（仅开放只读查询与第三方查分器同步，绝不写入官方机台数据）：
///   1. **出口固定**：只允许请求 [baseUrl]，杜绝 host 注入把令牌发给别的域名；
///   2. **不提供机台写入接口**：不实现购票/清票/成绩写入/删分/改门/道具写入等接口；
///   3. **成功判定以 `returnCode` 为准**（health 是 0，其余业务是 1），
///      `code == 0` 只是兼容字段；
///   4. **日志与报错一律脱敏**：绝不打印 qrcode 与令牌（官方文档明确要求）。
class AwmcApiService {
  AwmcApiService._();

  static final AwmcApiService instance = AwmcApiService._();

  /// 服务端代理根地址（常量，不允许来自用户输入/远程配置）。
  static const String baseUrl = '${ApiUrls.BackendBaseUrl}/api/awmc';

  /// 读取类请求超时。
  ///
  /// 65s：`/v1/user/music`（全部成绩）要在网关侧翻完整台机器的成绩，
  /// 慢的时候会接近 40s，45s 容易被误判成超时（不仅会写进审计日志，
  /// 还会白读一趟、游玩次数也刷不新）。
  static const Duration readTimeout = Duration(seconds: 65);

  // ==================== 计费表（官方文档 2.1 / 2.2） ====================
  /// 路径 → 本次成功调用扣除的 Token（0 表示不计费）。
  static const Map<String, int> costTable = {
    '/v1/health': 0,
    '/v1/user/preview': 1,
    '/v1/user/data': 2,
    '/v1/user/region': 2,
    '/v1/user/music': 4,
    // 服务端专门给游玩次数功能开的入口，内部只转发一次 /v1/user/music。
    '/play-count': 4,
    '/v1/rival/data': 2,
    '/v1/rival/music': 4,
    '/v1/select/music': 1,
    '/v1/select/music-unlock-plan': 1,
    '/v1/user/charge': 2,
    '/v1/user/item-list': 2,
    '/v1/user/kaleidx-scope': 2,
    '/v1/user/game-event': 2,
    '/v1/update-lx': 5,
    '/v1/update-fish': 5,
  };

  /// 该路径的预计消耗。
  static int costOf(String path) => costTable[path] ?? 0;

  // ==================== 难度 / 状态枚举（官方文档 3.4） ====================
  /// inote → 上游 level 编号。
  static const Map<String, int> levelByInote = ChartDifficulty.awmcLevelCodes;

  static const List<String> comboStatuses = [
    'none',
    'fc',
    'fcp',
    'ap',
    'app',
  ];

  static const List<String> syncStatuses = [
    'none',
    'fs',
    'fsp',
    'fsd',
    'fsdp',
    'sync',
  ];

  // ==================== 调用结果 ====================
  /// 一次调用结果。**不含请求体与 qrcode**，可以安全地进日志/审计。
  static AwmcCallResult _parse(
    String method,
    String path,
    int httpStatus,
    String body,
    int elapsedMs,
    int cost,
  ) {
    int? returnCode;
    int? code;
    String? msg;
    dynamic businessData;
    try {
      final decoded = json.decode(body);
      if (decoded is Map) {
        returnCode = _asInt(decoded['returnCode']);
        code = _asInt(decoded['code']);
        msg = decoded['msg']?.toString() ??
            decoded['returnMessage']?.toString() ??
            decoded['error']?.toString();
        businessData = decoded['businessData'];
      } else {
        businessData = decoded;
      }
    } catch (_) {
      // 上游偶尔返回非 JSON（502 网关页等）：保留原始文本前 200 字便于排查
      msg = body.length > 200 ? '${body.substring(0, 200)}…' : body;
    }

    final bool businessOk = path == '/v1/health'
        ? returnCode == 0
        : (returnCode == 1 || (returnCode == null && code == 0));
    final bool httpOk = httpStatus >= 200 && httpStatus < 300;

    return AwmcCallResult(
      method: method,
      path: path,
      httpStatus: httpStatus,
      returnCode: returnCode,
      code: code,
      msg: msg,
      businessData: businessData,
      ok: httpOk && businessOk,
      costTokens: cost,
      elapsedMs: elapsedMs,
    );
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  // ==================== 底层请求 ====================
  static Future<AwmcCallResult> _call(
    String method,
    String path, {
    required String token,
    Map<String, dynamic>? body,
    Duration? timeoutOverride,
  }) async {
    final int cost = costOf(path);
    final uri = Uri.parse('$baseUrl$path');
    // 出口固定校验：任何拼装错误都在这里拦下，避免令牌被发到别的域名
    if (uri.host != Uri.parse(baseUrl).host) {
      return AwmcCallResult.failure(
        method: method,
        path: path,
        message: appL10n.flowRefusedRequestToANonGatewayAddress((uri.host).toString()),
      );
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    final payload = body == null ? null : json.encode(body);
    final Duration timeout = timeoutOverride ?? readTimeout;

    final int started = DateTime.now().millisecondsSinceEpoch;
    int sinceStart() => DateTime.now().millisecondsSinceEpoch - started;
    try {
      late final int status;
      late final String text;
      switch (method) {
        case 'GET':
          final r =
              await ApiClient.get(uri, headers: headers, timeout: timeout);
          status = r.statusCode;
          text = r.body;
          break;
        case 'POST':
          final r = await ApiClient.post(uri,
              headers: headers, body: payload, timeout: timeout);
          status = r.statusCode;
          text = r.body;
          break;
        default:
          return AwmcCallResult.failure(
            method: method,
            path: path,
            message: appL10n.flowUnsupportedMethodP0((method).toString()),
          );
      }
      final elapsed = sinceStart();
      // 只打印路径与状态，绝不打印 body / 令牌
      debugPrint(
          '[AWMC] $method $path → HTTP $status (${elapsed}ms, cost=$cost)');
      return _parse(method, path, status, text, elapsed, cost);
    } on TimeoutException {
      return AwmcCallResult.failure(
        method: method,
        path: path,
        message: appL10n.flowRequestTimedOutP0S((timeout.inSeconds).toString()),
        // 超时是最需要看耗时的情况：不记的话审计日志里这一栏是空的
        elapsedMs: sinceStart(),
      );
    } catch (e) {
      // 异常文本里可能带 URI（不含令牌），统一走脱敏
      return AwmcCallResult.failure(
        method: method,
        path: path,
        message: describeTransportError(e),
        elapsedMs: sinceStart(),
      );
    }
  }

  /// 把底层传输异常翻译成人话（纯函数，便于测试）。
  ///
  /// 为什么需要：网关前面的 SpeedOnline CDN 出错时，错误页的响应头是
  /// `Content-Type: text/html; charset=utf-8;` —— **末尾多一个分号**，
  /// 按 RFC 是非法 media type，`package:http` 在解析响应头时就抛
  /// `FormatException: Invalid media type...`。结果我们既拿不到 HTTP 状态码、
  /// 也拿不到 CDN 的错误页，用户只看到一句 `Error on line 1, column 26: ...`。
  /// 实测 2026-09-17：网关回源超时时 100% 复现（curl 能容忍，Dart 不能）。
  @visibleForTesting
  static String describeTransportError(Object error) {
    final text = error.toString();
    if (text.contains('Invalid media type')) {
      return appL10n.svcTheGatewayCouldNotReachItsOrigin;
    }
    return appL10n.svcRequestFailedP0((redact(text)).toString());
  }

  // ==================== 只读接口 ====================
  /// 网关探活（0 Token）。
  ///
  /// [timeout] 用于**同步前的快速探活**：读写默认超时（45s / 180s）在网关
  /// 挂住时会白等，探活宁可快速失败。
  static Future<AwmcCallResult> health({
    required String token,
    Duration? timeout,
  }) =>
      _call('GET', '/v1/health', token: token, timeoutOverride: timeout);

  static Future<AwmcCallResult> userData({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/data', token: token, body: {'qrcode': qrcode});

  static Future<AwmcCallResult> userPreview({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/preview', token: token, body: {'qrcode': qrcode});

  static Future<AwmcCallResult> userRegion({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/region', token: token, body: {'qrcode': qrcode});

  static Future<AwmcCallResult> userMusic({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/music', token: token, body: {'qrcode': qrcode});

  /// 独立的游玩次数读取入口。
  ///
  /// 服务端会把这次请求转发到上游 `/v1/user/music`；普通成绩同步不再调用
  /// 上游读取接口，避免同一张机台二维码被重复使用。
  static Future<AwmcCallResult> userPlayCounts({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/play-count', token: token, body: {'qrcode': qrcode});

  static Future<AwmcCallResult> musicUnlockCandidates() =>
      _call('POST', '/v1/select/music-unlock-plan', token: '', body: {'category': 'music'});

  static Future<AwmcCallResult> selectMusic(String query) =>
      _call('POST', '/v1/select/music', token: '', body: {'query': query, 'limit': 50});

  static Future<AwmcCallResult> rivalData(int rivalId) =>
      _call('POST', '/v1/rival/data', token: '', body: {'rivalId': rivalId});

  /// 免二维码读取成绩；机台身份只放在 HTTPS 请求体中。
  static Future<AwmcCallResult> rivalMusic({
    required int rivalId,
    int nextIndex = 0,
  }) =>
      _call('POST', '/v1/rival/music', token: '', body: {
        'rivalId': rivalId,
        'nextIndex': nextIndex,
        // 上游实测不接受 maxCount=1000；沿用默认批量大小，按 nextIndex 翻页。
        'includeUtage': false,
      });

  static Future<AwmcCallResult> userCharge({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/charge', token: token, body: {'qrcode': qrcode});

  static Future<AwmcCallResult> userItemList({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/item-list',
          token: token, body: {'qrcode': qrcode});

  static Future<AwmcCallResult> userKaleidxScope({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/kaleidx-scope',
          token: token, body: {'qrcode': qrcode});

  static Future<AwmcCallResult> userGameEvent({
    required String token,
    required String qrcode,
  }) =>
      _call('POST', '/v1/user/game-event',
          token: token, body: {'qrcode': qrcode});

  // ==================== 第三方同步（读取成绩后推送，属读分类） ====================
  /// 同步到落雪 LXNS。[key] 为落雪 API Key。
  static Future<AwmcCallResult> updateLx({
    required String token,
    required String qrcode,
    required String key,
  }) =>
      _call('POST', '/v1/update-lx',
          token: token, body: {'qrcode': qrcode, 'key': key});

  /// 同步到 Diving-Fish。[fishToken] 为水鱼开发者 Token。
  static Future<AwmcCallResult> updateFish({
    required String token,
    required String qrcode,
    required String fishToken,
  }) =>
      _call('POST', '/v1/update-fish',
          token: token, body: {'qrcode': qrcode, 'token': fishToken});

  // ==================== 用量 / 配额 / 令牌管理（0 消耗） ====================
  static Future<AwmcCallResult> myUsage({
    required String token,
    int limit = 50,
    int offset = 0,
  }) =>
      _call('GET', '/me/usage?limit=$limit&offset=$offset', token: token);

  static Future<AwmcCallResult> myUsageStats({
    required String token,
    int days = 7,
  }) =>
      _call('GET', '/me/usage/stats?days=$days', token: token);

  static Future<AwmcCallResult> myQuota({required String token}) =>
      _call('GET', '/me/quota', token: token);

  static Future<AwmcCallResult> myFailureRate({required String token}) =>
      _call('GET', '/me/usage/failure-rate', token: token);

  static Future<AwmcCallResult> globalFailureRate({required String token}) =>
      _call('GET', '/usage/failure-rate', token: token);

  static Future<AwmcCallResult> listApiTokens({required String token}) =>
      _call('GET', '/me/api-tokens', token: token);

  // ==================== 脱敏 ====================
  /// 统一脱敏：令牌 / qrcode / 任何长串。
  ///
  /// 官方文档要求「切勿在日志中记录二维码与第三方 Token」，
  /// 所以本文件内所有日志、错误文案都必须经过它。
  static String redact(String input) => SensitiveRedactor.redact(input);

  /// 只保留前 6 位 + 长度，用于 UI 展示。
  static String maskSecret(String? secret) =>
      SensitiveRedactor.maskSecret(secret);
}

/// 一次 AWMC 调用的结果。
///
/// 刻意**不保存请求体**（里面可能有 qrcode），只留可安全展示/审计的字段。
class AwmcCallResult {
  final String method;
  final String path;
  final int httpStatus;
  final int? returnCode;
  final int? code;
  final String? msg;
  final dynamic businessData;
  final bool ok;
  final int costTokens;
  final int elapsedMs;
  final String? errorMessage;

  AwmcCallResult({
    required this.method,
    required this.path,
    required this.httpStatus,
    required this.returnCode,
    required this.code,
    required this.msg,
    required this.businessData,
    required this.ok,
    required this.costTokens,
    required this.elapsedMs,
    this.errorMessage,
  });

  factory AwmcCallResult.failure({
    required String method,
    required String path,
    required String message,
    int elapsedMs = 0,
  }) =>
      AwmcCallResult(
        method: method,
        path: path,
        httpStatus: 0,
        returnCode: null,
        code: null,
        msg: null,
        businessData: null,
        ok: false,
        costTokens: 0,
        elapsedMs: elapsedMs,
        errorMessage: message,
      );

  /// 失败时给用户看的文案（已脱敏）。
  ///
  /// **必须限长**：有的网关会把整页 HTML / 超长堆栈塞进 `msg`，
  /// 原样返回会让轻提示、对话框、结果抽屉被撑出屏幕（几十万像素的溢出）。
  String get displayMessage {
    if (ok) return appL10n.svcSuccess;
    if (errorMessage != null) {
      return _clip(AwmcApiService.redact(errorMessage!));
    }
    if (httpStatus == 503 && msg == 'awmc_gateway_not_configured') {
      return appL10n.svcTheServerHasNoAWMCDeveloperKey;
    }
    if (httpStatus == 401) return appL10n.svcHTTP401TokenMissingOrInvalid;
    if (httpStatus == 403) return appL10n.svcHTTP403InsufficientBalanceRedeemTokensIn;
    if (httpStatus >= 500) return appL10n.svcHTTPP0TheGatewayOrUpstreamFailed(httpStatus.toString());
    final parts = <String>[
      'HTTP $httpStatus',
      if (returnCode != null) 'returnCode=$returnCode',
      if (code != null) 'code=$code',
      if (msg != null && msg!.isNotEmpty) AwmcApiService.redact(msg!),
    ];
    return _clip(parts.join(' · '));
  }

  /// 展示用文案的最大长度。
  static const int displayMessageMaxChars = 600;

  static String _clip(String text) => text.length <= displayMessageMaxChars
      ? text
      : '${text.substring(0, displayMessageMaxChars)}…'
          '（完整内容共 ${text.length} 字符，可在结果里查看）';

  /// 计费说明：只有「HTTP 2xx 且业务成功」才扣 Token。
  String get billingNote =>
      ok ? appL10n.svcUsedP0Tokens(costTokens.toString()) : appL10n.svcTheRequestDidNotSucceedNoTokens;

  /// 完整的 businessData 文本（缩进 JSON）。**可能很大**，
  /// 只在用户主动「查看完整数据」时才调用，避免每次弹结果都序列化几 MB。
  String businessDataText() {
    if (businessData == null) return '(无 businessData)';
    try {
      return const JsonEncoder.withIndent('  ').convert(businessData);
    } catch (_) {
      return businessData.toString();
    }
  }

  /// 便于展示的 businessData JSON（截断，避免刷屏）。
  String businessDataPreview({int maxChars = 4000}) {
    final text = businessDataText();
    return text.length <= maxChars ? text : '${text.substring(0, maxChars)}…';
  }
}
