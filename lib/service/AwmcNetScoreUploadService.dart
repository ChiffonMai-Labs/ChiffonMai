import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import '../utils/AppTaskActivity.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../api/ApiUrls.dart';
import '../utils/ApiClient.dart';
import '../utils/QuotaRetryHint.dart';

/// AWMC NET 机台二维码导入的结果。
///
/// 接口是**一次同步调用**（实测约 36 秒），没有进度事件，所以这里只有最终统计。
class AwmcNetQrImportResult {
  /// 是否整体成功（HTTP 200）。
  final bool ok;

  /// 服务端把整套机台成绩拉下来后的总数。
  final int totalRecords;

  /// 本次**新增**的谱面数。
  final int imported;

  /// 本次**覆盖更新**的谱面数。
  final int updated;

  /// 本次跳过的谱面数（已有且没有更好）。
  final int skipped;

  /// 逐条失败的原因（多为「找不到歌曲」= AWMC NET 曲库还没收录）。
  /// **非空不代表整体失败** —— 实测 20 条失败时 HTTP 仍是 200。
  final List<String> errors;

  /// 失败时给用户看的中文文案（成功时为 null）。
  final String? errorMessage;

  /// 是不是「Token 无效」——调用方据此清掉本地存的 Token 并让用户重填。
  final bool tokenInvalid;

  final int elapsedMs;

  const AwmcNetQrImportResult({
    required this.ok,
    this.totalRecords = 0,
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
    this.errorMessage,
    this.tokenInvalid = false,
    this.elapsedMs = 0,
  });

  factory AwmcNetQrImportResult.failure(
    String message, {
    bool tokenInvalid = false,
    int elapsedMs = 0,
  }) =>
      AwmcNetQrImportResult(
        ok: false,
        errorMessage: message,
        tokenInvalid: tokenInvalid,
        elapsedMs: elapsedMs,
      );

  /// 成功时给用户看的一行摘要。
  String get summary =>
      appL10n.svcP0AddedP1UpdatedP2SkippedP3(imported.toString(), updated.toString(), skipped.toString(), totalRecords.toString());
}

/// AWMC NET（https://net.wmc.pub）「同步成绩到 AWMC NET」。
///
/// 本类负责让 AWMC NET 使用二维码拉取完整机台成绩。
/// 快速同步由 AwmcQuickSyncService 读取机台成绩、补齐该 AWMC NET 账号的标记，
/// 再转换成水鱼 RecordItem 数组上传；两种方式都使用用户自己的 Import-Token。
///
/// ── 两个实测要点 ──
///   1. **耗时约 36 秒且同步阻塞** —— 必须用 [timeout]（120s），
///      `ApiClient` 默认的 15s 会把成功判成超时；
///   2. **它是覆盖式的** —— 实测一次导入 `updated: 1106` / `skipped: 593`，
///      即以机台为准重写已有成绩，不是纯追加。UI 上要说清楚。
class AwmcNetScoreUploadService {
  AwmcNetScoreUploadService._();

  static final AwmcNetScoreUploadService instance =
      AwmcNetScoreUploadService._();

  /// 导入超时。实测 36 秒，留足余量（对方要登机台把整套成绩拉一遍）。
  static const Duration timeout = Duration(seconds: 120);

  /// 用机台登入二维码把成绩导入 AWMC NET。
  ///
  /// [importToken] 是用户在 net.wmc.pub **设置页最底部**「生成/轮换Token」生成、
  /// 自己保存的成绩导入 Token；[sgwcmaid] 是 `SGWCMAID` 开头的登入二维码字符串。
  ///
  /// 不抛异常：一切失败都收敛成 [AwmcNetQrImportResult.failure]，方便 UI 直接用。
  Future<AwmcNetQrImportResult> importByQr({
    required String importToken,
    required String sgwcmaid,
  }) =>
      AppTaskActivity.run(() async {
        final token = importToken.trim();
        final qr = sgwcmaid.trim();
        if (token.isEmpty) {
          return AwmcNetQrImportResult.failure(appL10n.svcTheAWMCNETScoreImportTokenHas);
        }
        if (qr.isEmpty) {
          return AwmcNetQrImportResult.failure(appL10n.svcPasteOrScanTheCabinetSignIn);
        }

        final uri = Uri.parse(ApiUrls.AwmcNetScoreQrApi);
        // 出口固定校验：杜绝把 Token 发到别的域名
        if (uri.host != Uri.parse(ApiUrls.AwmcNetBaseUrl).host) {
          return AwmcNetQrImportResult.failure(appL10n.svcRefusedARequestToANonAWMC(uri.host.toString()));
        }

        final sw = Stopwatch()..start();
        final http.Response response;
        try {
          response = await ApiClient.postMultipart(
            uri,
            // 走 multipart 文本字段：接口另有一个 `file`（二维码图片）字段，
            // 但 App 现有扫码流程拿到的是字符串，用 sgwcmaid 这条更直接。
            fields: {'sgwcmaid': qr},
            headers: {'Import-Token': token},
            timeout: timeout,
          );
        } on TimeoutException {
          return AwmcNetQrImportResult.failure(
            appL10n.svcImportTimedOutAfterP0SecondsLarge(timeout.inSeconds.toString()),
            elapsedMs: sw.elapsedMilliseconds,
          );
        } catch (e) {
          return AwmcNetQrImportResult.failure(
            appL10n.svcCouldNotConnectToAWMCNETP0((_redact(e.toString())).toString()),
            elapsedMs: sw.elapsedMilliseconds,
          );
        }
        final elapsed = sw.elapsedMilliseconds;
        return parseResponse(response, elapsed);
      });

  /// 把一次响应翻成结果。**抽成纯函数是为了能用真实响应体做单测**
  /// （下面的文案全部对着实测到的服务端原文写）。
  @visibleForTesting
  static AwmcNetQrImportResult parseResponse(
      http.Response response, int elapsedMs) {
    if (response.statusCode != 200) {
      debugPrint('[AWMC NET] QR 导入失败：HTTP ${response.statusCode} '
          '(${(elapsedMs / 1000).toStringAsFixed(1)}s)');
      return _failureForStatus(response, elapsedMs);
    }

    // 成功：解析统计。**响应体里不含 Token / 二维码**，可以安全 debugPrint。
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        return AwmcNetQrImportResult.failure(
          appL10n.svcAWMCNETReturnedUnrecognizedData,
          elapsedMs: elapsedMs,
        );
      }
      // 注意：`errors` 非空**不代表整体失败** —— 实测 20 条「找不到歌曲」时
      // HTTP 仍是 200，成绩也真的导进去了。
      final result = AwmcNetQrImportResult(
        ok: true,
        totalRecords: _asInt(decoded['total_records']),
        imported: _asInt(decoded['imported']),
        updated: _asInt(decoded['updated']),
        skipped: _asInt(decoded['skipped']),
        errors: (decoded['errors'] is List)
            ? (decoded['errors'] as List).map((e) => '$e').toList()
            : const [],
        elapsedMs: elapsedMs,
      );
      debugPrint('[AWMC NET] QR 导入成功：${result.summary} '
          '(${(elapsedMs / 1000).toStringAsFixed(1)}s, '
          '${result.errors.length} 条逐条失败)');
      return result;
    } catch (e) {
      return AwmcNetQrImportResult.failure(
        appL10n.svcCouldNotParseTheAWMCNETResponse(e.toString()),
        elapsedMs: elapsedMs,
      );
    }
  }

  /// 把非 200 的响应翻成给用户看的中文。
  ///
  /// 文案对着**实测**到的服务端原文写：
  ///   * 401 `程序上传需要提供 Import-Token` —— 没带 Token
  ///   * 401 `Import-Token 无效` —— Token 不对
  ///   * 400 `需要提供 sgwcmaid 或二维码图片` —— 二维码字段是空的
  static AwmcNetQrImportResult _failureForStatus(
      http.Response response, int elapsed) {
    var detail = '';
    try {
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        detail = (decoded['message'] ?? decoded['detail'] ?? '').toString();
      }
    } catch (_) {
      // 非 JSON（网关错误页等）：正文没参考价值
    }
    final clipped =
        detail.length > 200 ? '${detail.substring(0, 200)}…' : detail;

    if (response.statusCode == 401) {
      final invalid = !detail.contains('需要提供');
      return AwmcNetQrImportResult.failure(
        invalid
            ? appL10n.svcTheAWMCNETImportTokenIsInvalid2
            : appL10n.svcTheAWMCNETImportTokenIsMissing,
        tokenInvalid: invalid,
        elapsedMs: elapsed,
      );
    }
    // 实测上游以 502 包裹 Chime 业务码 3002。它并不能证明二维码已过期，
    // 也不代表导入 Token 无效；只展示已知错误，避免回显原文中的凭据或身份。
    if (detail.contains('Chime') && RegExp(r'\b3002\b').hasMatch(detail)) {
      debugPrint('[AWMC NET] 机台读取失败：upstream=Chime, code=3002');
      return AwmcNetQrImportResult.failure(
        appL10n.svcAWMCNETChimeUserReadFailed(response.statusCode.toString()),
        elapsedMs: elapsed,
      );
    }
    if (response.statusCode == 400) {
      return AwmcNetQrImportResult.failure(
        detail.contains('sgwcmaid') || detail.contains('二维码')
            ? appL10n.svcTheCabinetQRCodeIsInvalidOr
            : appL10n.svcAWMCNETRejectedTheRequestP0((clipped.isEmpty ? appL10n.svcInvalidParameters : clipped).toString()),
        elapsedMs: elapsed,
      );
    }
    if (response.statusCode == 429) {
      return AwmcNetQrImportResult.failure(
        appL10n.svcTooManyAWMCNETRequestsTryAgain((quotaRetryHint(utf8.decode(response.bodyBytes))).toString()),
        elapsedMs: elapsed,
      );
    }
    if (response.statusCode >= 500) {
      return AwmcNetQrImportResult.failure(
        appL10n.svcAWMCNETServerErrorHTTPP0Try(response.statusCode.toString()),
        elapsedMs: elapsed,
      );
    }
    return AwmcNetQrImportResult.failure(
      '${appL10n.svcAWMCNETReturnedHTTPP0(response.statusCode.toString())}'
      '${clipped.isEmpty ? '' : '：$clipped'}',
      elapsedMs: elapsed,
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  /// 异常文本里的长串一律打码：它们很可能就是 Token 本身。
  static String _redact(String input) =>
      input.replaceAllMapped(RegExp(r'[A-Za-z0-9_\-]{24,}'), (m) => '****');
}
