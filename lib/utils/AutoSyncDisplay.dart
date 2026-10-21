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
    if (seconds < 60) return '$seconds 秒';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return rest == 0 ? '$minutes 分钟' : '$minutes 分 $rest 秒';
  }

  /// 从某个时刻到现在的已用时长（客户端时钟略快时显示「刚刚」而不是负数）。
  static String elapsedSince(DateTime? start, {DateTime? now}) {
    if (start == null) return '—';
    final elapsed = (now ?? DateTime.now()).toUtc().difference(start.toUtc());
    return elapsed.isNegative ? '刚刚' : duration(elapsed);
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
        'quota_unavailable' || 'quota_wait' => '等待上游配额恢复',
        'upstream_wait' => '等待上游服务恢复',
        'gateway_suspended' => '等待上游网关恢复',
        _ => '等待上游处理',
      };

  /// 等待状态的一行说明：原因 + 预计重试时间。
  static String? waitLine(AutoSyncTiming? timing) {
    final reason = timing?.waitReason;
    if (reason == null) return null;
    final retry = timing?.retryAt;
    return retry == null
        ? waitReason(reason)
        : '${waitReason(reason)}，预计 ${clock(retry)} 重试';
  }

  /// 失败原因短标签，用于 Hub 摘要这种一行宽度有限的场景。
  static String errorBrief(String? code) => switch (code) {
        'run_timeout' => '处理超时',
        'quota_unavailable' || 'quota_wait' => '配额不足',
        'upstream_wait' ||
        'gateway_suspended' ||
        'upstream_unavailable' =>
          '上游不可用',
        'upload_failed' || 'upload_uncertain' => '上传未完成',
        'upload_credential_invalid' => '上传凭据失效',
        'target_records_failed' => '目标成绩读取失败',
        'catalog_failed' => '曲库读取失败',
        'gateway_failed' => '机台读取失败',
        'no_scores' || 'no_matching_scores' => '没有可同步成绩',
        'interrupted' => '服务重启中断',
        'window_expired' => '处理窗口已结束',
        'snapshot_invalid' => '本轮数据已失效',
        'cancelled' => '任务已取消',
        _ => '同步失败',
      };

  /// 执行中的详细进度行（按目标源区分文案）。
  static String progressLine(AutoSyncTask task, String platformLabel) {
    final progress = task.progress;
    if (progress == null) return '正在准备快速同步…';
    return progress.detailLabel(platformLabel);
  }

  /// 执行中的补充信息：已用时长 / 上限、机台数据采集时间。
  static String? runningMeta(AutoSyncTask task, {DateTime? now}) {
    final timing = task.timing;
    final parts = <String>[];
    if (task.status == 'running') {
      if (timing?.startedAt != null) {
        final limit = roundTimeoutMinutes(timing, null);
        parts.add('处理已用 ${elapsedSince(timing!.startedAt, now: now)}'
            '${limit == null ? '' : ' / 上限 $limit 分钟'}');
      } else {
        parts.add('等待开始处理');
      }
    }
    if (timing?.collectedAt != null) {
      parts.add('机台数据采集 ${clock(timing!.collectedAt)}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// 汇总卡片的一行进度（Hub 摘要用，避免过长）。
  static String progressBrief(AutoSyncTask task) {
    final progress = task.progress;
    if (progress == null) return '正在同步…';
    return switch (progress.stage) {
      'uploading' => '上传 ${progress.completed}/${progress.total} 条'
          '${progress.submitted > 0 ? ' · 已提交 ${progress.submitted} 条' : ''}',
      'reading' => progress.completed > 0
          ? '读取机台成绩 · 第 ${progress.completed} 页'
          : '读取机台成绩…',
      _ => progress.label,
    };
  }

  /// 上次结果的数量明细；没有可展示的数量时返回 null。
  static String? resultStats(AutoSyncRunResult result) {
    final parts = <String>[
      if (result.submitted > 0) '提交 ${result.submitted} 条',
      if (result.skipped > 0) '跳过 ${result.skipped} 条不支持的谱面',
      if (result.unchanged > 0) '未变化 ${result.unchanged} 条',
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
    return spent == null ? begin : '$begin · 耗时 $spent';
  }
}
