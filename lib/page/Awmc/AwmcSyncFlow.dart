import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/CacheKeyConstant.dart';
import '../../manager/DivingFishProbeManager.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcGatewaySettings.dart';
import '../../service/AWMC/AwmcStore.dart';
import '../../service/AWMC/AwmcQuickSyncService.dart';
import '../../service/SyncStatsService.dart';
import '../../service/PostSyncRefreshService.dart';
import '../../utils/SecureCredentialStore.dart';
import '../../widgets/SyncScoreDialogs.dart'
    show showDivingFishSyncInputDialog, showLuoXueSyncInputDialog;
import '../../widgets/RefreshDataDialog.dart'
    show RefreshDataRequest, RefreshDataSource;

/// 「通过 AWMC 网关同步成绩」的目标平台。
enum AwmcSyncTarget {
  /// 同步到水鱼 Diving-Fish（`/v1/update-fish`）。
  divingFish(
    label: '水鱼',
    path: '/v1/update-fish',
    auditNote: '通过 AWMC 网关推送到水鱼',
  ),

  /// 同步到落雪 LXNS（`/v1/update-lx`）。
  luoXue(
    label: '落雪',
    path: '/v1/update-lx',
    auditNote: '通过 AWMC 网关推送到落雪',
  );

  const AwmcSyncTarget({
    required this.label,
    required this.path,
    required this.auditNote,
  });

  final String label;
  final String path;
  final String auditNote;

  int get syncCost => AwmcApiService.costOf(path);
}

class _AwmcQrInput {
  final String qrCode;
  final RefreshDataRequest? refreshRequest;
  final bool quickUpdate;
  const _AwmcQrInput(this.qrCode, this.refreshRequest, this.quickUpdate);
}

/// 一次 AWMC 同步的结果。
class AwmcSyncOutcome {
  final bool quickUpdate;

  /// 用户中途取消（未发出任何请求）。
  final bool cancelled;

  /// 同步接口是否成功。
  final bool ok;

  final AwmcCallResult? syncResult;

  /// 本次写入本地缓存的 (曲目, 难度) 条数。
  final int cachedRecords;

  /// 兼容旧版调用方的结果字段。普通同步已不再读取游玩次数，始终为 false。
  final bool playCountsRefreshed;

  /// 兼容旧版调用方的结果字段。普通同步已不再读取游玩次数，始终为 null。
  final String? readErrorMessage;

  final String? message;
  final String? refreshError;

  const AwmcSyncOutcome({
    this.quickUpdate = false,
    this.cancelled = false,
    this.ok = false,
    this.syncResult,
    this.cachedRecords = 0,
    this.playCountsRefreshed = false,
    this.readErrorMessage,
    this.message,
    this.refreshError,
  });

  static const AwmcSyncOutcome userCancelled = AwmcSyncOutcome(cancelled: true);
}

/// 「同步成绩到水鱼 / 落雪」的 **线路1 · AWMC 网关** 实现。
///
/// 与线路2（maimai Score Hub）的区别只在**数据通道**：
///   * 不走 Maimai Score Hub 探针（maimai.bakapiano.com），直接用机台二维码调 AWMC 网关；
///   * 只调一次 `/v1/update-fish` 或 `/v1/update-lx`（5 Token）推送成绩。
///     游玩次数由系统页里的独立功能读取，避免同一张二维码重复请求上游。
///
/// **交互与线路2 完全一致**：直接复用线路2 的两个对话框
/// （[showDivingFishSyncInputDialog] / [showLuoXueSyncInputDialog]），
/// 一行文案都不多写。凭据也沿用线路2 已经缓存好的：
///   * 水鱼：本机缓存的 **ImportToken**（`probe_diving_fish_import_token`，
///     由线路2 登录/绑定时写入）；
///   * 落雪：本机缓存的**个人 API 密钥**（`probe_lxns_import_token`，
///     落雪对话框在用户填写时自己落盘）。
///
/// 安全约束不变：二维码每次当场输入、用完即弃；写操作串行不自动重试；
/// 全程写审计日志。
class AwmcSyncFlow {
  AwmcSyncFlow._();

  /// 执行一次同步。会自行弹输入对话框 / 结果面板。
  ///
  /// [onBusy] / [onIdle] 用于让调用方在**真正的网络请求期间**切换按钮进度
  /// （输入框阶段不切换，避免按钮上显示进度却又弹着对话框）。
  static Future<AwmcSyncOutcome> run(
    BuildContext context, {
    required AwmcSyncTarget target,
    Future<bool> Function()? onMissingCredential,
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    // 1. 凭据：读本机缓存（线路2 已经存好的那份）。
    //    先查这个：没缓存就直接提示，别让用户白填一遍二维码。
    var credential = await _resolveCredential(target);
    if (credential == null) {
      if (onMissingCredential != null) {
        final recovered = await onMissingCredential();
        if (!recovered) return AwmcSyncOutcome.userCancelled;
        credential = await _resolveCredential(target);
        if (credential == null) return AwmcSyncOutcome.userCancelled;
      }
    }
    if (credential == null) {
      if (context.mounted) {
        Fluttertoast.showToast(msg: _missingCredentialHint(target));
      }
      return AwmcSyncOutcome(
        message: _missingCredentialHint(target),
      );
    }

    // 2. 探活：`/v1/health`（由服务端注入开发者网关令牌）。
    //
    // 放在**问二维码之前**：网关不健康时，让用户先去机台上拍一张二维码、
    // 回来再失败，是白折腾（而且失败原因还看不出来）。实测网关出现过
    // 「带有效令牌的请求直接不回包」，这一探能在花掉任何 Token 之前挡住。
    if (!context.mounted) return AwmcSyncOutcome.userCancelled;
    final gatewayError = await _checkGateway(onBusy: onBusy);
    onIdle?.call();
    if (gatewayError != null) return AwmcSyncOutcome(message: gatewayError);

    // 4. 二维码 / 排行榜选项：走线路2 的同款对话框
    if (!context.mounted) return AwmcSyncOutcome.userCancelled;
    final input = await _askQrCode(context, target);
    if (input == null) return AwmcSyncOutcome.userCancelled;
    if (input.quickUpdate) {
      final refresh = await PostSyncRefreshOperation.capture(
          target == AwmcSyncTarget.divingFish
              ? RefreshDataSource.shuiyu
              : RefreshDataSource.luoxue,
          request: input.refreshRequest);
      onBusy?.call('正在快速同步…');
      try {
        final result = await AwmcQuickSyncService.run(
          platform: target == AwmcSyncTarget.divingFish
              ? SyncPlatform.divingFish
              : SyncPlatform.luoXue,
          onProgress: (p, text) {
            onBusy?.call(text);
            onProgress?.call(p, text);
          },
        );
        final refreshError = await refresh.run(onProgress: (p, text) {
          onBusy?.call(text);
          onProgress?.call(.7 + p * .003, text);
        });
        return AwmcSyncOutcome(
            ok: true,
            quickUpdate: true,
            cachedRecords: result.submitted,
            refreshError: refreshError);
      } catch (error) {
        return AwmcSyncOutcome(message: '$error');
      } finally {
        onIdle?.call();
      }
    }
    return _executeWithInput(
      qrCode: input.qrCode,
      target: target,
      credential: credential,
      refreshRequest: input.refreshRequest,
      onBusy: onBusy,
      onProgress: onProgress,
      onIdle: onIdle,
    );
  }

  /// toast 用的短原因：`displayMessage` 最多 600 字，整段塞进 toast 看不清。
  static String _shortReason(AwmcCallResult r) {
    final msg = r.displayMessage.replaceAll(RegExp(r'\s+'), ' ').trim();
    const max = 40;
    return msg.length <= max ? msg : '${msg.substring(0, max)}…';
  }

  /// 多端同步复用已输入的二维码；不再弹输入对话框，也不重复要求凭据。
  static Future<AwmcSyncOutcome> runWithInput({
    required String qrCode,
    required AwmcSyncTarget target,
    RefreshDataRequest? refreshRequest,
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    if (!qrCode.startsWith('SGWCMAID')) {
      return const AwmcSyncOutcome(message: '无效的机台登入二维码');
    }
    try {
      final credential = await _resolveCredential(target);
      if (credential == null) {
        return AwmcSyncOutcome(message: _missingCredentialHint(target));
      }
      final gatewayError = await _checkGateway(onBusy: onBusy);
      if (gatewayError != null) return AwmcSyncOutcome(message: gatewayError);
      return await _executeWithInput(
        qrCode: qrCode,
        target: target,
        credential: credential,
        refreshRequest: refreshRequest,
        onBusy: onBusy,
        onProgress: onProgress,
      );
    } finally {
      onIdle?.call();
    }
  }

  static Future<String?> _checkGateway({
    void Function(String label)? onBusy,
  }) async {
    onBusy?.call('正在检查 AWMC 网关...');
    // 短超时探活在任何付费写入之前完成，失败时不自动切换线路或重试。
    // 超时阈值用户可调（设置页「同步与网关」，默认 15 秒）。
    final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
    final health = await AwmcApiService.health(
      token: '',
      timeout: probeTimeout,
    );
    await AwmcAuditLog.record(health, note: '同步前的网关探活');
    if (health.ok) return null;
    debugPrint('[AWMC] 网关探活失败，已取消同步: ${health.displayMessage}');
    return 'AWMC 网关当前不可用（${_shortReason(health)}），已取消同步、未消耗 Token';
  }

  /// 两个入口共用读取次数、推送、刷新和统计流程，避免线路1行为分叉。
  static Future<AwmcSyncOutcome> _executeWithInput({
    required String qrCode,
    required AwmcSyncTarget target,
    required String credential,
    RefreshDataRequest? refreshRequest,
    void Function(String label)? onBusy,
    void Function(double progress, String text)? onProgress,
    VoidCallback? onIdle,
  }) async {
    final qrcode = qrCode;
    final refresh = await PostSyncRefreshOperation.capture(
        target == AwmcSyncTarget.divingFish
            ? RefreshDataSource.shuiyu
            : RefreshDataSource.luoxue,
        request: refreshRequest);

    // 5. 直接推送成绩。游玩次数已从普通同步中拆出，不能复用这张二维码再读一次。
    const cached = 0;
    final stopwatch = Stopwatch()..start();

    // 6. 推送
    onBusy?.call('正在通过 AWMC 网关同步到${target.label}...');
    final AwmcCallResult result;
    if (target == AwmcSyncTarget.divingFish) {
      result = await AwmcApiService.updateFish(
        token: '',
        qrcode: qrcode,
        fishToken: credential,
      );
    } else {
      result = await AwmcApiService.updateLx(
        token: '',
        qrcode: qrcode,
        key: credential,
      );
    }
    await AwmcAuditLog.record(result, note: target.auditNote);
    stopwatch.stop();
    String? refreshError;
    if (result.ok) {
      refreshError = await refresh.run(onProgress: (p, text) {
        onBusy?.call(text);
        onProgress?.call(.7 + p * .003, text);
      });
    }
    onIdle?.call();

    // 统计（Redis，尽力而为：失败也不影响同步结果）
    unawaited(SyncStatsService.record(
      line: SyncLine.awmc,
      platform: target == AwmcSyncTarget.divingFish
          ? SyncPlatform.divingFish
          : SyncPlatform.luoXue,
      durationMs: stopwatch.elapsedMilliseconds,
      ok: result.ok,
    ));

    // 与线路2 保持一致：**只给一个小提示（toast）**，不弹结果抽屉——
    // 抽屉留给控制台里的只读查询用。结果详情随时可在「调用日志」里查。
    return AwmcSyncOutcome(
      ok: result.ok,
      syncResult: result,
      cachedRecords: cached,
      message: result.ok ? null : '同步失败：${result.displayMessage}',
      refreshError: refreshError,
    );
  }

  /// 同步成功后的小提示文案（与线路2 的口径一致）。
  static String successToast(AwmcSyncTarget target, AwmcSyncOutcome outcome) {
    if (outcome.quickUpdate) {
      return outcome.cachedRecords == 0
          ? '${target.label}成绩已是最新，无需上传'
          : '快速同步完成，已向${target.label}提交 ${outcome.cachedRecords} 条变化成绩';
    }
    final prefix =
        outcome.cachedRecords > 0 ? '共 ${outcome.cachedRecords} 条成绩' : '成绩';
    final suffix = target == AwmcSyncTarget.divingFish
        ? '已通过 AWMC 网关推送到水鱼'
        : '已通过 AWMC 网关导出到落雪';
    return '同步完成！$prefix$suffix';
  }

  /// 复用输入对话框，仅线路1开放免二维码快速同步。
  /// 排行榜选项由对话框自己落盘，线路1不使用。
  static Future<_AwmcQrInput?> _askQrCode(
    BuildContext context,
    AwmcSyncTarget target,
  ) async {
    if (target == AwmcSyncTarget.divingFish) {
      final input =
          await showDivingFishSyncInputDialog(context, allowQuickUpdate: true);
      return input == null
          ? null
          : _AwmcQrInput(input.qrCode, input.refreshRequest, input.quickUpdate);
    }
    final input =
        await showLuoXueSyncInputDialog(context, allowQuickUpdate: true);
    return input == null
        ? null
        : _AwmcQrInput(input.qrCode, input.refreshRequest, input.quickUpdate);
  }

  /// 取本机缓存的第三方凭据（与线路2 用的是同一份）。
  static Future<String?> _resolveCredential(AwmcSyncTarget target) async {
    final prefs = await SharedPreferences.getInstance();
    if (target == AwmcSyncTarget.divingFish) {
      // 优先用现成的读取接口（它自己也做了一次脱敏日志）
      final cached =
          await DivingFishProbeManager().getCachedDivingFishImportToken();
      if (cached != null && cached.isNotEmpty) return cached;
      final again =
          prefs.getString(CacheKeyConstant.probeDivingFishImportToken);
      return (again == null || again.isEmpty) ? null : again;
    }
    // 落雪对话框和账号页都写入安全存储。旧版本可能还留在
    // SharedPreferences，作为一次性兼容回退并立即迁移，避免升级后误报未设置。
    final secure = await SecureCredentialStore.read(
      CacheKeyConstant.probeLxnsImportToken,
    );
    if (secure != null && secure.isNotEmpty) return secure;
    final legacy = prefs.getString(CacheKeyConstant.probeLxnsImportToken);
    if (legacy != null && legacy.isNotEmpty) {
      await SecureCredentialStore.write(
        CacheKeyConstant.probeLxnsImportToken,
        legacy,
      );
      await prefs.remove(CacheKeyConstant.probeLxnsImportToken);
      return legacy;
    }
    return null;
  }

  /// 凭证缺失时给用户的指引（如实说明去哪儿补）。
  static String _missingCredentialHint(AwmcSyncTarget target) {
    if (target == AwmcSyncTarget.divingFish) {
      return '本机还没有缓存水鱼 ImportToken：请先用线路2（maimai Score Hub）'
          '登录并同步一次，它会自动把 ImportToken 存到本机。';
    }
    return '本机还没有缓存落雪个人 API 密钥：请先同步一次并填好密钥（会保存在本机）。';
  }
}
