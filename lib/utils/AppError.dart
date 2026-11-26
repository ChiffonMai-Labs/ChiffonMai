import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../l10n/AppMessages.dart';
import '../manager/AWMC/AwmcNetException.dart';
import '../manager/DivingFish/ProberException.dart';
import '../service/AWMC/AwmcNetSongService.dart';
import '../service/AWMC/AwmcPlayerConnection.dart';
import '../service/Account/AccountSwitchService.dart';
import '../service/Sync/AutoSyncService.dart';
import '../service/Sync/DivingFishScoreUploadService.dart';
import '../service/GainRecommend/GainRecommendService.dart';
import '../service/History/AwmcNetTrendService.dart';
import '../service/System/LogExportService.dart';
import '../service/Sync/LuoXueScoreUploadService.dart';
import '../service/Recognition/MaimaiHubOcrService.dart';
import '../service/Portable/PortableSongDownloadService.dart';
import '../service/RankingList/RankingUploadGuard.dart';
import '../widgets/SyncScoreDialogs.dart';
import 'CurrentDataSourceNotifier.dart';
import 'SensitiveRedactor.dart';

/// 全应用统一的结构化错误模型。
///
/// 既用于直接向用户展示人话提示与处理建议，也用于在截图诊断条、
/// 「复制排查信息」与运行日志里保留错误码、阶段、状态码和服务端请求号。
class AppError implements Exception {
  final String code;
  final String? title;
  final String userMessage;
  final String? suggestion;
  final String? stage;
  final String? source;
  final int? httpStatus;
  final String? requestId;
  final bool retryable;
  final String? technicalDetail;
  final DateTime timestamp;

  AppError({
    required this.code,
    required this.userMessage,
    this.title,
    this.suggestion,
    this.stage,
    this.source,
    this.httpStatus,
    this.requestId,
    this.retryable = true,
    this.technicalDetail,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  AppError copyWith({
    String? code,
    String? title,
    String? userMessage,
    String? suggestion,
    String? stage,
    String? source,
    int? httpStatus,
    String? requestId,
    bool? retryable,
    String? technicalDetail,
    DateTime? timestamp,
  }) =>
      AppError(
        code: code ?? this.code,
        title: title ?? this.title,
        userMessage: userMessage ?? this.userMessage,
        suggestion: suggestion ?? this.suggestion,
        stage: stage ?? this.stage,
        source: source ?? this.source,
        httpStatus: httpStatus ?? this.httpStatus,
        requestId: requestId ?? this.requestId,
        retryable: retryable ?? this.retryable,
        technicalDetail: technicalDetail ?? this.technicalDetail,
        timestamp: timestamp ?? this.timestamp,
      );

  /// 供截图直接排查的紧凑诊断条。
  String compactBadge({String? appVersion}) {
    final parts = <String>[code];
    if (stage != null && stage!.trim().isNotEmpty) {
      parts.add(stage!.trim());
    }
    if (httpStatus != null) {
      parts.add('HTTP $httpStatus');
    }
    if (requestId != null && requestId!.trim().isNotEmpty) {
      final rid = requestId!.trim();
      final shortRid = rid.length > 16 ? rid.substring(0, 16) : rid;
      parts.add('req:$shortRid');
    }
    final ver = appVersion?.trim();
    if (ver != null && ver.isNotEmpty) {
      parts.add(ver.startsWith('v') ? ver : 'v$ver');
    }
    return SensitiveRedactor.redact(parts.join(' · '));
  }

  /// 生成可直接粘贴发给开发者的脱敏排查文本包。
  String buildDiagnosticText({
    String? appVersion,
    String? dataSource,
    List<String>? recentLogs,
  }) {
    final buf = StringBuffer()
      ..writeln('ChiffonMai 问题排查信息')
      ..writeln('错误码: $code');
    if (title != null && title!.trim().isNotEmpty) {
      buf.writeln('场景: ${title!.trim()}');
    }
    if (stage != null && stage!.trim().isNotEmpty) {
      buf.writeln('阶段: ${stage!.trim()}');
    }
    buf.writeln('提示: $userMessage');
    if (httpStatus != null) {
      buf.writeln('状态码: HTTP $httpStatus');
    }
    if (requestId != null && requestId!.trim().isNotEmpty) {
      buf.writeln('请求号: ${requestId!.trim()}');
    }
    if (source != null && source!.trim().isNotEmpty) {
      buf.writeln('来源: ${source!.trim()}');
    }
    final ver = appVersion?.trim() ?? LogExportService.instance.cachedAppVersion;
    final src = dataSource ?? CurrentDataSourceNotifier.instance.value.key;
    buf
      ..writeln('环境: ${ver != null ? 'v$ver' : '未知版本'} / ${Platform.operatingSystem} / 数据源=$src')
      ..writeln('时间: ${timestamp.toIso8601String()}');
    if (technicalDetail != null && technicalDetail!.trim().isNotEmpty) {
      buf.writeln('技术详情: ${technicalDetail!.trim()}');
    }
    final logs = recentLogs ?? LogExportService.instance.recentLines(maxLines: 12);
    if (logs.isNotEmpty) {
      buf.writeln('--- 最近日志(${logs.length}行) ---');
      for (final line in logs) {
        buf.writeln(line);
      }
    }
    return SensitiveRedactor.redact(buf.toString().trimRight());
  }

  AppStateError asStateError() => AppStateError(this);

  @override
  String toString() => userMessage;
}

/// 兼容既有 `on StateError` / `throwsStateError` 契约的结构化错误。
///
/// 既能被既有业务与回归测试按 [StateError] 捕获，又能被 [AppErrorMapper.from]
/// 还原为完整的 [AppError]（错误码、阶段、状态码、请求号、技术详情），
/// 且 [toString] 不再输出 `Bad state:` 前缀。
class AppStateError extends StateError {
  final AppError appError;

  AppStateError(this.appError) : super(appError.userMessage);

  @override
  String toString() => appError.userMessage;
}

class _OutboundRequestMark {
  final String host;
  final String path;
  final String requestId;
  final DateTime at;

  const _OutboundRequestMark(this.host, this.path, this.requestId, this.at);
}

/// 在内存中保留最近出错上下文和出站请求编号，方便超时或日志导出时关联定位。
class AppErrorRegistry {
  AppErrorRegistry._();

  static final List<AppError> _recentErrors = [];
  static final List<_OutboundRequestMark> _recentRequests = [];

  static List<AppError> get recentErrors => List.unmodifiable(_recentErrors);

  static void noteOutboundRequest(String host, String path, String requestId) {
    _recentRequests.add(
      _OutboundRequestMark(host, path, requestId, DateTime.now()),
    );
    if (_recentRequests.length > 16) {
      _recentRequests.removeAt(0);
    }
  }

  static String? recentRequestId({
    String? host,
    Duration maxAge = const Duration(seconds: 65),
  }) {
    final now = DateTime.now();
    for (var i = _recentRequests.length - 1; i >= 0; i--) {
      final item = _recentRequests[i];
      if (now.difference(item.at) > maxAge) break;
      if (host == null || item.host == host) return item.requestId;
    }
    return null;
  }

  static AppError record(AppError error) {
    final duplicate = _recentErrors.isNotEmpty &&
        _recentErrors.last.code == error.code &&
        _recentErrors.last.userMessage == error.userMessage &&
        _recentErrors.last.requestId == error.requestId &&
        error.timestamp.difference(_recentErrors.last.timestamp).inSeconds < 2;
    if (!duplicate) {
      _recentErrors.add(error);
      if (_recentErrors.length > 12) {
        _recentErrors.removeAt(0);
      }
      final parts = <String>[
        '[AppError] code=${error.code}',
        if (error.stage != null && error.stage!.isNotEmpty) 'stage=${error.stage}',
        if (error.httpStatus != null) 'http=${error.httpStatus}',
        if (error.requestId != null && error.requestId!.isNotEmpty) 'req=${error.requestId}',
        'msg=${error.userMessage}',
      ];
      debugPrint(SensitiveRedactor.redact(parts.join(' ')));
    }
    return error;
  }
}

/// 把各类异常、状态码和原始提示收口为 [AppError]，彻底消除裸露 `Bad state:` 等报错。
class AppErrorMapper {
  AppErrorMapper._();

  static AppError from(
    Object error, {
    StackTrace? stack,
    String? title,
    String? stage,
    String? source,
    http.Response? response,
    String? requestId,
    int? httpStatus,
    String? fallbackCode,
  }) {
    if (error is AppError) {
      return error.copyWith(
        title: error.title ?? title,
        stage: error.stage ?? stage,
        source: error.source ?? source,
        httpStatus: error.httpStatus ?? httpStatus ?? response?.statusCode,
        requestId: error.requestId ?? requestId ?? _responseRequestId(response),
      );
    }
    if (error is AppStateError) {
      final inner = error.appError;
      return inner.copyWith(
        title: inner.title ?? title,
        stage: inner.stage ?? stage,
        source: inner.source ?? source,
        httpStatus: inner.httpStatus ?? httpStatus ?? response?.statusCode,
        requestId: inner.requestId ?? requestId ?? _responseRequestId(response),
      );
    }

    final resolvedStatus = httpStatus ?? response?.statusCode;
    final resolvedRequestId = requestId ?? _responseRequestId(response);
    final frame = _firstAppFrame(stack);
    final rawSafe = SensitiveRedactor.redact('$error').trim();

    if (error is AccountUpdateBusy) {
      return AppError(
        code: 'SYNC-ACCOUNT-BUSY',
        title: title,
        userMessage: error.toString(),
        suggestion: appL10n.errSuggestionRetryLater,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        retryable: true,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is RankingUploadException) {
      return AppError(
        code: switch (error.issue) {
          RankingUploadIssue.rejected => 'SRV-RANKING-REJECTED',
          RankingUploadIssue.frozen => 'SRV-RANKING-FROZEN',
          RankingUploadIssue.blacklisted => 'SRV-RANKING-BLACKLISTED',
          RankingUploadIssue.upgradeRequired => 'APP-UPGRADE-REQUIRED',
          RankingUploadIssue.failed => 'SRV-RANKING-UPLOAD',
        },
        title: title,
        userMessage: SensitiveRedactor.redact(error.message),
        stage: stage ?? '排行榜上传',
        source: source,
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        retryable: error.issue == RankingUploadIssue.failed,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is ProberException) {
      final code = switch (error.code) {
        'CONSENT_REQUIRED' => 'AUTH-FISH-CONSENT',
        'UNAUTHORIZED' => 'AUTH-FISH-UNAUTHORIZED',
        'FORBIDDEN' => 'AUTH-FISH-FORBIDDEN',
        'QUOTA_EXCEEDED' => 'SRV-PROBER-QUOTA',
        'BIND_FAILED' => 'SRV-PROBER-BIND',
        _ => 'SRV-PROBER-ERROR',
      };
      return AppError(
        code: code,
        title: title,
        userMessage: SensitiveRedactor.redact(error.message),
        suggestion: error.code == 'CONSENT_REQUIRED' || error.code == 'UNAUTHORIZED'
            ? appL10n.errSuggestionReauth
            : appL10n.errSuggestionRetryLater,
        stage: stage ?? '水鱼 OAuth',
        source: source ?? 'shuiyu',
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        retryable: error.code == 'QUOTA_EXCEEDED' || error.code == 'UNKNOWN',
        technicalDetail: _joinDetail(['ProberException(${error.code})', rawSafe, frame]),
      );
    }

    if (error is AutoSyncException) {
      return AppError(
        code: error.code != null && error.code!.isNotEmpty
            ? 'SYNC-AUTO-${error.code!.toUpperCase().replaceAll('_', '-')}'
            : 'SYNC-AUTO-ERROR',
        title: title,
        userMessage: SensitiveRedactor.redact(error.message),
        suggestion: appL10n.errSuggestionRetryLater,
        stage: error.stage ?? stage ?? '自动同步',
        source: source,
        httpStatus: error.httpStatus ?? resolvedStatus,
        requestId: error.requestId ?? resolvedRequestId,
        technicalDetail: _joinDetail([
          if (error.code != null) 'code=${error.code}',
          rawSafe,
          frame,
        ]),
      );
    }

    if (error is AwmcNetException ||
        error is ScoreUploadException ||
        error is LuoXueUploadException ||
        error is GainRecommendLoadException ||
        error is AudioDownloadSourceException ||
        error is SyncFlowException) {
      final code = switch (error) {
        AwmcNetException() => 'DATA-AWMC-NET',
        ScoreUploadException() => 'SYNC-FISH-UPLOAD',
        LuoXueUploadException() => 'SYNC-LXNS-UPLOAD',
        GainRecommendLoadException() => 'DATA-RECOMMEND-EMPTY',
        AudioDownloadSourceException() => 'EXP-AUDIO-SAVE',
        SyncFlowException() => 'SYNC-FLOW-ERROR',
        _ => fallbackCode ?? 'APP-ERROR',
      };
      return AppError(
        code: code,
        title: title,
        userMessage: _cleanPrefix(rawSafe),
        suggestion: appL10n.errSuggestionRetryLater,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail([error.runtimeType.toString(), rawSafe, frame]),
      );
    }

    if (error is MaimaiHubOcrException) {
      return AppError(
        code: error.loginRequired ? 'AUTH-MAIMAI-HUB' : 'SRV-OCR-ERROR',
        title: title,
        userMessage: SensitiveRedactor.redact(error.message),
        suggestion: error.loginRequired
            ? appL10n.errSuggestionReauth
            : appL10n.errSuggestionRetryLater,
        stage: stage ?? 'OCR 识别',
        source: source,
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is AwmcNetSongException) {
      final status = error.statusCode;
      return AppError(
        code: status == 429 ? 'SRV-RATE-LIMITED' : 'SRV-AWMC-NET-$status',
        title: title,
        userMessage: status == 429
            ? appL10n.errRateLimited
            : 'AWMC NET 曲目历史请求失败（HTTP $status）',
        suggestion: appL10n.errSuggestionRetryLater,
        stage: stage ?? 'AWMC NET 历史',
        source: source ?? 'awmc',
        httpStatus: status,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail(['AwmcNetSongException($status)', frame]),
      );
    }

    if (error is PlayerConnectionError) {
      return AppError(
        code: 'AUTH-AWMC-PLAYER-${error.code.toUpperCase()}',
        title: title,
        userMessage: error.code == 'unauthorized'
            ? appL10n.errUnauthorized
            : '玩家账号连接校验失败（${error.code}）',
        suggestion: error.code == 'unauthorized'
            ? appL10n.errSuggestionReauth
            : appL10n.errSuggestionRetryLater,
        stage: stage ?? '玩家连接',
        source: source ?? 'awmc',
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail(['PlayerConnectionError(${error.code})', frame]),
      );
    }

    if (error is AwmcNetTrendException) {
      return AppError(
        code: 'DATA-AWMC-TREND',
        title: title,
        userMessage: SensitiveRedactor.redact(error.message),
        suggestion: appL10n.errSuggestionRetryLater,
        stage: stage ?? 'AWMC NET 趋势',
        source: source ?? 'awmc',
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is TimeoutException) {
      final rid = resolvedRequestId ??
          AppErrorRegistry.recentRequestId(host: 'chiffonmai.cloud');
      return AppError(
        code: 'NET-TIMEOUT',
        title: title,
        userMessage: appL10n.errNetworkTimeout,
        suggestion: appL10n.errSuggestionCheckNetwork,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: rid,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is HandshakeException || error is TlsException) {
      final rid = resolvedRequestId ??
          AppErrorRegistry.recentRequestId(host: 'chiffonmai.cloud');
      return AppError(
        code: 'NET-TLS',
        title: title,
        userMessage: appL10n.errNetworkTls,
        suggestion: appL10n.errSuggestionCheckNetwork,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: rid,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is SocketException) {
      final rid = resolvedRequestId ??
          AppErrorRegistry.recentRequestId(host: 'chiffonmai.cloud');
      return AppError(
        code: 'NET-OFFLINE',
        title: title,
        userMessage: appL10n.errNetworkOffline,
        suggestion: appL10n.errSuggestionCheckNetwork,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: rid,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is HttpException || error is http.ClientException) {
      final rid = resolvedRequestId ??
          AppErrorRegistry.recentRequestId(host: 'chiffonmai.cloud');
      return AppError(
        code: 'NET-CLIENT',
        title: title,
        userMessage: appL10n.errNetworkInterrupted,
        suggestion: appL10n.errSuggestionCheckNetwork,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: rid,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is FormatException) {
      return AppError(
        code: 'DATA-FORMAT',
        title: title,
        userMessage: appL10n.errDataParseFailed,
        suggestion: appL10n.errSuggestionRetryLater,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is FileSystemException) {
      return AppError(
        code: 'EXP-FILE-IO',
        title: title,
        userMessage: appL10n.errFileIoFailed,
        suggestion: appL10n.errSuggestionCheckStorage,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail([rawSafe, frame]),
      );
    }

    if (error is PlatformException) {
      return AppError(
        code: 'APP-PLATFORM-${(error.code).toUpperCase().replaceAll('_', '-')}',
        title: title,
        userMessage: (error.message?.trim().isNotEmpty == true)
            ? SensitiveRedactor.redact(error.message!.trim())
            : appL10n.featureOperationFailed,
        suggestion: appL10n.errSuggestionContactDev,
        stage: stage,
        source: source,
        httpStatus: resolvedStatus,
        requestId: resolvedRequestId,
        technicalDetail: _joinDetail(['PlatformException(${error.code})', rawSafe, frame]),
      );
    }

    return fromMessage(
      rawSafe,
      title: title,
      stage: stage,
      source: source,
      code: fallbackCode,
      requestId: resolvedRequestId,
      httpStatus: resolvedStatus,
      technicalDetail: _joinDetail([error.runtimeType.toString(), rawSafe, frame]),
    );
  }

  static AppError fromMessage(
    String rawMessage, {
    String? title,
    String? stage,
    String? source,
    String? code,
    String? requestId,
    int? httpStatus,
    String? technicalDetail,
  }) {
    final cleaned = _cleanPrefix(SensitiveRedactor.redact(rawMessage));
    final lower = cleaned.toLowerCase();

    if (cleaned.isEmpty || lower == 'null') {
      return AppError(
        code: code ?? 'APP-UNKNOWN',
        title: title,
        userMessage: appL10n.featureUnknownError,
        suggestion: appL10n.errSuggestionContactDev,
        stage: stage,
        source: source,
        httpStatus: httpStatus,
        requestId: requestId,
        technicalDetail: technicalDetail,
      );
    }

    // 把常见的内部技术串或裸英文提示转换为友好人话。
    if (cleaned == 'save_qq_failed') {
      return AppError(
        code: code ?? 'DATA-SAVE-QQ',
        title: title,
        userMessage: '保存 QQ 号失败，请检查应用存储权限后重试',
        suggestion: appL10n.errSuggestionRetryLater,
        stage: stage,
        source: source,
        httpStatus: httpStatus,
        requestId: requestId,
        technicalDetail: technicalDetail ?? cleaned,
      );
    }
    if (cleaned == 'Growth canvas not ready') {
      return AppError(
        code: code ?? 'EXP-CANVAS-NOT-READY',
        title: title,
        userMessage: appL10n.errExportCanvasNotReady,
        suggestion: appL10n.errSuggestionRetryLater,
        stage: stage,
        source: source,
        httpStatus: httpStatus,
        requestId: requestId,
        technicalDetail: technicalDetail ?? cleaned,
      );
    }
    if (cleaned == 'Unable to save local aliases') {
      return AppError(
        code: code ?? 'DATA-SAVE-ALIASES',
        title: title,
        userMessage: '保存本地歌曲别名缓存失败',
        suggestion: appL10n.errSuggestionCheckStorage,
        stage: stage,
        source: source,
        httpStatus: httpStatus,
        requestId: requestId,
        technicalDetail: technicalDetail ?? cleaned,
      );
    }

    final httpMatch = RegExp(r'^(?:AWMC\s+)?HTTP\s+(\d{3})$', caseSensitive: false)
        .firstMatch(cleaned);
    if (httpMatch != null) {
      final status = httpStatus ?? int.tryParse(httpMatch.group(1)!);
      return AppError(
        code: code ?? 'NET-HTTP-${status ?? 'ERR'}',
        title: title,
        userMessage: _friendlyStatusMessage(status),
        suggestion: status == 401 || status == 403
            ? appL10n.errSuggestionReauth
            : appL10n.errSuggestionRetryLater,
        stage: stage,
        source: source,
        httpStatus: status,
        requestId: requestId,
        technicalDetail: technicalDetail ?? cleaned,
      );
    }

    if (lower.contains('socketexception') || lower.contains('failed host lookup')) {
      return AppError(
        code: code ?? 'NET-OFFLINE',
        title: title,
        userMessage: appL10n.errNetworkOffline,
        suggestion: appL10n.errSuggestionCheckNetwork,
        stage: stage,
        source: source,
        httpStatus: httpStatus,
        requestId: requestId,
        technicalDetail: technicalDetail ?? cleaned,
      );
    }
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return AppError(
        code: code ?? 'NET-TIMEOUT',
        title: title,
        userMessage: appL10n.errNetworkTimeout,
        suggestion: appL10n.errSuggestionCheckNetwork,
        stage: stage,
        source: source,
        httpStatus: httpStatus,
        requestId: requestId,
        technicalDetail: technicalDetail ?? cleaned,
      );
    }

    return AppError(
      code: code ?? 'APP-STATE',
      title: title,
      userMessage: cleaned,
      suggestion: appL10n.errSuggestionContactDev,
      stage: stage,
      source: source,
      httpStatus: httpStatus,
      requestId: requestId,
      technicalDetail: technicalDetail ?? (cleaned != rawMessage.trim() ? rawMessage.trim() : null),
    );
  }

  static String _friendlyStatusMessage(int? status) {
    if (status == null) return appL10n.errServerBusy;
    if (status == 401) return appL10n.errUnauthorized;
    if (status == 403) return appL10n.errForbidden;
    if (status == 404) return appL10n.errNotFound;
    if (status == 429) return appL10n.errRateLimited;
    if (status >= 500) return '${appL10n.errServerInternal} (HTTP $status)';
    return '请求失败 (HTTP $status)';
  }

  /// 去掉裸露异常前缀（包含文首及冒号后内嵌的 `Bad state:` / `Exception:`），并做脱敏处理。
  static String cleanText(String text) =>
      _cleanPrefix(SensitiveRedactor.redact(text));

  static String _cleanPrefix(String text) {
    var out = text.trim();
    while (true) {
      if (out.startsWith('Bad state: ')) {
        out = out.substring('Bad state: '.length).trim();
      } else if (out.startsWith('Exception: ')) {
        out = out.substring('Exception: '.length).trim();
      } else if (out.startsWith('Invalid argument(s): ')) {
        out = out.substring('Invalid argument(s): '.length).trim();
      } else {
        break;
      }
    }
    return out.replaceAllMapped(
      RegExp(r'([：:]\s*)(?:Bad state:\s*|Exception:\s*|Invalid argument\(s\):\s*)+'),
      (m) => m[1]!,
    );
  }

  static String? _responseRequestId(http.Response? response) {
    if (response == null) return null;
    for (final entry in response.headers.entries) {
      if (entry.key.toLowerCase() == 'x-request-id' && entry.value.trim().isNotEmpty) {
        return entry.value.trim();
      }
    }
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final rid = decoded['requestId'] ?? decoded['request_id'];
        if (rid is String && rid.trim().isNotEmpty) return rid.trim();
      }
    } catch (_) {}
    return null;
  }

  static String? _firstAppFrame(StackTrace? stack) {
    if (stack == null) return null;
    for (final line in stack.toString().split('\n')) {
      final trimmed = line.trim();
      if (trimmed.contains('package:my_first_flutter_app/')) {
        return trimmed;
      }
    }
    return null;
  }

  static String? _joinDetail(List<String?> parts) {
    final nonEmpty = parts
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (nonEmpty.isEmpty) return null;
    return SensitiveRedactor.redact(nonEmpty.join('\n'));
  }
}
