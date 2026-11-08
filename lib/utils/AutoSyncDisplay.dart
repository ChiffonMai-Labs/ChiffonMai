import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import '../service/AutoSyncService.dart';

/// 自动同步状态的统一展示文案：时间、耗时、等待原因、进度与结果摘要。
///
/// 自动同步页面与 Hub 入口摘要共用同一套口径，避免两处对同一个状态给出不同说法。
/// 所有时间均按北京时间（UTC+8）展示，与页面既有文案一致。
class AutoSyncDisplay {
  AutoSyncDisplay._();

  static const Duration _beijingOffset = Duration(hours: 8);

  /// 北京时间 HH:mm。
  static String clock(DateTime? value) {
    if (value == null) return '—';
    final date = value.toUtc().add(_beijingOffset);
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.hour)}:${two(date.minute)}';
  }

  /// 北京时间 MM-dd HH:mm。
  static String dateTime(DateTime? value) {
    if (value == null) return '—';
    final date = value.toUtc().add(_beijingOffset);
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  /// 耗时文案。单轮上限只有 10 分钟，精确到秒即可。
  static String duration(Duration? value) {
    if (value == null || value.isNegative) return '—';
    final seconds = value.inSeconds;
    if (seconds < 60) return appL10n.flowP0Seconds2((seconds).toString());
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0
        ? appL10n.flowP0Minutes((minutes).toString())
        : appL10n.flowP0MinP1Sec((minutes).toString(), (rest).toString());
  }

  /// 从某个时刻到现在的已用时长（客户端时钟略快时显示「刚刚」而不是负数）。
  static String elapsedSince(DateTime? start, {DateTime? now}) {
    if (start == null) return '—';
    final elapsed = (now ?? DateTime.now()).toUtc().difference(start.toUtc());
    return elapsed.isNegative ? appL10n.flowJustNow : duration(elapsed);
  }

  /// 服务端下发的整轮处理上限（毫秒 → 分钟）；旧版本或历史结果没有该字段时返回 null。
  static int? roundTimeoutMinutes(
      AutoSyncTiming? timing, AutoSyncRunResult? result) {
    final milliseconds = timing?.roundTimeoutMs ?? result?.roundTimeoutMs;
    if (milliseconds != null && milliseconds > 0) {
      return (milliseconds / 60000).round();
    }
    return null;
  }

  /// 等待原因（服务端 waitReason 码）。
  static String waitReason(String? code) => switch (code) {
        'quota_unavailable' ||
        'quota_wait' =>
          appL10n.flowWaitingForUpstreamQuota,
        'upstream_wait' => appL10n.flowWaitingForUpstreamService,
        'gateway_suspended' => appL10n.flowWaitingForUpstreamGateway,
        _ => appL10n.flowWaitingForUpstreamProcessing,
      };

  /// 等待状态的一行说明：原因 + 预计重试时间。
  static String? waitLine(AutoSyncTiming? timing) {
    final reason = timing?.waitReason;
    if (reason == null) return null;
    final retry = timing?.retryAt;
    return retry == null
        ? waitReason(reason)
        : appL10n.flowP0RetryAroundP1(
            (waitReason(reason)).toString(), (clock(retry)).toString());
  }

  /// 失败原因短标签，用于 Hub 摘要这种一行宽度有限的场景。
  static String errorBrief(String? code) => switch (code) {
        'run_timeout' => appL10n.flowProcessingTimedOut,
        'quota_unavailable' || 'quota_wait' => appL10n.flowQuotaInsufficient,
        'upstream_wait' ||
        'gateway_suspended' ||
        'upstream_unavailable' =>
          appL10n.flowUpstreamUnavailable,
        'upload_failed' || 'upload_uncertain' => appL10n.flowUploadIncomplete,
        'upload_credential_invalid' => appL10n.flowUploadCredentialsExpired,
        'target_records_failed' => appL10n.flowCouldNotReadTargetScores,
        'catalog_failed' => appL10n.flowCouldNotReadLibrary,
        'gateway_failed' => appL10n.flowCouldNotReadCabinetData,
        'no_scores' || 'no_matching_scores' => appL10n.flowNoScoresToSync,
        'interrupted' => appL10n.flowInterruptedByServiceRestart,
        'window_expired' => appL10n.flowProcessingWindowEnded,
        'snapshot_invalid' => appL10n.flowRoundDataExpired,
        'cancelled' => appL10n.flowTaskCancelled,
        _ => appL10n.featureSyncFailed,
      };

  /// 执行中的详细进度行（按目标源区分文案）。
  static String progressLine(AutoSyncTask task, String platformLabel) {
    final progress = task.progress;
    if (progress == null) return appL10n.flowPreparingQuickSync;
    return progress.detailLabel(platformLabel);
  }

  /// 执行中的补充信息：已用时长 / 上限、机台数据采集时间。
  static String? runningMeta(AutoSyncTask task, {DateTime? now}) {
    final timing = task.timing;
    final parts = <String>[];
    if (task.status == 'running') {
      if (timing?.startedAt != null) {
        final limit = roundTimeoutMinutes(timing, null);
        parts.add(appL10n.flowElapsedP0P1(
            (elapsedSince(timing!.startedAt, now: now)).toString(),
            (limit == null ? '' : appL10n.flowLimitP0Min((limit).toString()))
                .toString()));
      } else {
        parts.add(appL10n.flowWaitingForProcessingToStart);
      }
    }
    if (timing?.collectedAt != null) {
      parts.add(appL10n.flowCabinetDataCollectedP02(
          (clock(timing!.collectedAt)).toString()));
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// 汇总卡片的一行进度（Hub 摘要用，避免过长）。
  static String progressBrief(AutoSyncTask task) {
    final progress = task.progress;
    if (progress == null) return appL10n.featureSyncing2;
    return switch (progress.stage) {
      'uploading' => appL10n.flowUploadingP0P1P2(
          (progress.completed).toString(),
          (progress.total).toString(),
          (progress.submitted > 0
                  ? appL10n.flowSubmittedP0((progress.submitted).toString())
                  : '')
              .toString()),
      'reading' => progress.completed > 0
          ? appL10n
              .flowReadingCabinetScoresPageP0((progress.completed).toString())
          : appL10n.featureReadingCabinetScores,
      _ => progress.label,
    };
  }

  /// 上次结果的数量明细；没有可展示的数量时返回 null。
  static String? resultStats(AutoSyncRunResult result) {
    final parts = <String>[
      if (result.submitted > 0)
        appL10n.flowSubmittedP02((result.submitted).toString()),
      if (result.skipped > 0)
        appL10n.flowSkippedP0UnsupportedCharts2((result.skipped).toString()),
      if (result.unchanged > 0)
        appL10n.flowUnchangedP0((result.unchanged).toString()),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// 上次结果的执行时间与耗时。
  static String resultTimeLine(AutoSyncRunResult result) {
    final start = result.startedAt;
    final finish = result.finishedAt;
    if (start == null && finish == null) return '—';
    final begin = dateTime(start ?? finish);
    final spent = start != null && finish != null
        ? duration(finish.difference(start))
        : null;
    return spent == null
        ? begin
        : appL10n.flowP0TookP1((begin).toString(), (spent).toString());
  }
}
