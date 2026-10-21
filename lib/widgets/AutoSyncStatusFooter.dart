import 'dart:async';

import 'package:flutter/material.dart';

import '../service/AutoSyncService.dart';
import '../service/SyncStatsService.dart';
import '../utils/AppTheme.dart';
import '../utils/AutoSyncDisplay.dart';
import 'MarqueeText.dart';

/// 自动同步入口下方的个人结果摘要，与全站共享的同步耗时统计分开展示。
class AutoSyncStatusFooter extends StatefulWidget {
  final VoidCallback onTap;
  const AutoSyncStatusFooter({super.key, required this.onTap});

  @override
  State<AutoSyncStatusFooter> createState() => _AutoSyncStatusFooterState();
}

class _AutoSyncStatusFooterState extends State<AutoSyncStatusFooter>
    with WidgetsBindingObserver {
  final Map<SyncPlatform, AutoSyncTask> _tasks = {};
  final Set<SyncPlatform> _failed = {};
  bool _visible = false;
  bool _active = true;
  bool _loading = true;
  int _request = 0;
  Timer? _timer;
  bool _refreshing = false;
  bool _refreshAgain = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AutoSyncService.changes.addListener(_onSettingsChanged);
    _active = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (_visible == visible) return;
    _visible = visible;
    _scheduleRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    _timer?.cancel();
    if (!_visible || !_active) return;
    _refresh();
    // 只在可见且已开启任务时轮询，离开 Hub 或切到后台后停止。
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_refreshing) return;
      if (_tasks.values.any((task) => task.enabled) || _failed.isNotEmpty)
        _refresh();
    });
  }

  void _onSettingsChanged() {
    ++_request;
    if (_visible && _active) _refresh();
  }

  Future<void> _refresh() async {
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    final request = ++_request;
    final tasks = <SyncPlatform, AutoSyncTask>{};
    final failed = <SyncPlatform>{};
    await Future.wait(SyncPlatform.values.map((platform) async {
      try {
        tasks[platform] = await AutoSyncService.instance.status(platform);
      } catch (_) {
        failed.add(platform);
      }
    }));
    _refreshing = false;
    if (!mounted) return;
    if (_refreshAgain) {
      _refreshAgain = false;
      if (_visible && _active) {
        _refresh();
        return;
      }
    }
    if (request != _request) return;
    setState(() {
      _tasks.addAll(tasks);
      _failed
        ..clear()
        ..addAll(failed);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    AutoSyncService.changes.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        widget.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_queue != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                  '${_queue!.upcoming ? '下轮' : '本轮'}排队用户 ${_queue!.waitingUsers} 人 · 处理中 ${_queue!.runningTasks} 项',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          for (final platform in SyncPlatform.values) _label(platform)
        ],
      ),
    );
  }

  Widget _label(SyncPlatform platform) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final task = _tasks[platform];
    final failed = _failed.contains(platform);
    final waiting = task?.waiting == true;
    final warning = AppColors.warningOrange(theme.brightness);
    final status = failed
        ? '状态未确认'
        : _loading
            ? '读取中…'
            : _summary(task);
    final icon = failed
        ? Icons.cloud_off_outlined
        : _loading
            ? Icons.more_horiz
            : waiting
                ? Icons.hourglass_top_rounded
                : switch (task?.status) {
                    'success' => Icons.check_circle_outline,
                    'failed' => Icons.error_outline,
                    'running' => Icons.sync,
                    _ => Icons.schedule_outlined,
                  };
    final color = failed
        ? scheme.onSurfaceVariant
        : waiting
            ? warning
            : switch (task?.status) {
                'success' => AppColors.successGreen(theme.brightness),
                'failed' => scheme.error,
                'running' => scheme.primary,
                _ => scheme.onSurfaceVariant,
              };
    final time = _time(
        task?.status == 'running' && task?.timing?.retryAt != null
            ? task!.timing!.retryAt
            : task?.lastResult?.finishedAt ??
                task?.lastResult?.startedAt ??
                task?.lastRunAt);
    final detail = _detail(task, platform, failed: failed);
    final timeLabel = task?.status == 'running' && task?.timing?.retryAt != null
        ? '预计重试'
        : '最近执行';
    final textStyle = TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant);
    return Tooltip(
      message:
          '${platform.label}：$detail${time == null ? '' : '\n$timeLabel：$time（北京时间）'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(12) * 6,
            child: Text(platform.label,
                style: textStyle.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Expanded(child: LayoutBuilder(builder: (context, constraints) {
            final timeText = failed ? '待刷新' : time ?? '—';
            final timeStyle = textStyle.copyWith(fontSize: 10.5);
            // 窄屏或大字体时把时间换到下一行，优先让同步结果完整可读。
            if (constraints.maxWidth <
                MediaQuery.textScalerOf(context).scale(11.5) * 18) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status, style: textStyle.copyWith(color: color)),
                  if (time != null || failed) Text(timeText, style: timeStyle),
                ],
              );
            }
            return Row(children: [
              Expanded(
                  child: SizedBox(
                height: MediaQuery.textScalerOf(context).scale(11.5) * 1.6,
                child: MarqueeText(
                    text: status, style: textStyle.copyWith(color: color)),
              )),
              const SizedBox(width: 8),
              Text(timeText, style: timeStyle),
            ]);
          })),
        ]),
      ),
    );
  }

  /// Hub 摘要的详细说明（Tooltip / 窄屏展开用），比一行摘要多出等待、耗时与上轮明细。
  String _detail(AutoSyncTask? task, SyncPlatform platform,
      {required bool failed}) {
    if (failed) return '状态刷新失败，请点击查看或重试；此前结果不代表本次查询已确认';
    if (task == null) return '尚未读取到同步状态';
    final parts = <String>[];
    if (task.status == 'running') {
      final waitLine = AutoSyncDisplay.waitLine(task.timing);
      if (waitLine != null) parts.add(waitLine);
      final progressLine = AutoSyncDisplay.progressLine(task, platform.label);
      parts.add(task.waiting ? '上次进度：$progressLine' : progressLine);
      final meta = AutoSyncDisplay.runningMeta(task);
      if (meta != null) parts.add(meta);
    } else {
      parts.add(task.progress?.label ?? _summary(task));
    }
    final userPosition = task.queue?.userPosition ?? task.queue?.position;
    if (userPosition != null) {
      parts.add(
          '${task.queue!.upcoming ? '下轮' : '本轮'}用户第 $userPosition 位 / ${task.queue!.waitingUsers} 人');
    }
    if (task.lastResult != null) {
      parts.add('上轮：${_resultBrief(task.lastResult!)}');
    }
    if (task.status != 'running' && task.nextRunAt != null) {
      final retry = task.lastResult?.status == 'failed';
      parts.add(
          '${retry ? '下次自动重试' : '下次执行'}：${AutoSyncDisplay.dateTime(task.nextRunAt)}');
    }
    return parts.join('\n');
  }

  String _resultBrief(AutoSyncRunResult result) {
    final time = AutoSyncDisplay.resultTimeLine(result);
    if (result.status == 'success') {
      final stats = AutoSyncDisplay.resultStats(result) ?? '无变化';
      return '成功 · $stats · $time';
    }
    return '失败 · ${AutoSyncDisplay.errorBrief(result.error)} · $time';
  }

  String _summary(AutoSyncTask? task) {
    if (task == null || !task.enabled) return '未开启';
    if (task.status == 'running') {
      final waitLine = AutoSyncDisplay.waitLine(task.timing);
      if (waitLine != null) return waitLine;
      return AutoSyncDisplay.progressBrief(task);
    }
    final last = task.lastResult;
    final result = last == null
        ? '暂无记录'
        : last.status == 'success'
            ? (last.submitted == 0 && last.unchanged > 0
                ? '上轮已是最新 · 无需上传'
                : '上轮成功 · 提交 ${last.submitted} 条')
            : '上轮失败 · ${AutoSyncDisplay.errorBrief(last.error)}';
    final queue = task.queue;
    final userPosition = queue?.userPosition ?? queue?.position;
    if (userPosition != null)
      return '${queue!.upcoming ? '下轮' : '排队'}用户第 $userPosition 位 · $result';
    return result;
  }

  AutoSyncQueue? get _queue {
    final tasks = _tasks.values
        .where((task) => task.enabled && task.queue != null)
        .toList();
    if (tasks.isEmpty) return null;
    tasks.sort((a, b) {
      final active = (a.status == 'running' ? 0 : 1)
          .compareTo(b.status == 'running' ? 0 : 1);
      return active != 0
          ? active
          : (a.queue!.scheduledAt?.millisecondsSinceEpoch ?? 0)
              .compareTo(b.queue!.scheduledAt?.millisecondsSinceEpoch ?? 0);
    });
    return tasks.first.queue;
  }

  String? _time(DateTime? value) {
    if (value == null) return null;
    final date = value.toUtc().add(const Duration(hours: 8));
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }
}
