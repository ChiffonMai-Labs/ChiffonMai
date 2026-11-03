import 'dart:async';

import 'package:flutter/material.dart';

import '../entity/chongxi/MaimaiServerStatusModel.dart';
import '../service/AutoSyncService.dart';
import '../service/HomeWidgetService.dart';
import '../service/SyncStatsService.dart';
import '../service/chongxi/MaimaiServerStatusService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/AutoSyncDisplay.dart';
import 'AppUi.dart';

/// 首页小组件的外观：图标、标题、一行结论、一行说明。
class _HomeStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String headline;
  final String detail;
  final Color accent;
  final VoidCallback onTap;

  const _HomeStatusCard({
    required this.icon,
    required this.title,
    required this.headline,
    required this.detail,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              headline,
              maxLines: 1,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              detail,
              maxLines: 1,
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// 定时刷新：只在页面可见且 App 在前台时轮询，离开后立刻停。
abstract class _PollingState<T extends StatefulWidget> extends State<T>
    with WidgetsBindingObserver {
  Duration get interval;
  Future<void> refresh();

  Timer? _timer;
  bool _visible = false;
  bool _active = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _active = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _visible) return;
    _visible = visible;
    _restart();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    if (!_visible || !_active) return;
    runRefresh();
    _timer = Timer.periodic(interval, (_) => runRefresh());
  }

  Future<void> runRefresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await refresh();
    } finally {
      _refreshing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// 自动同步：只显示结论，详情在自动同步页。
class HomeAutoSyncWidget extends StatefulWidget {
  final VoidCallback onTap;

  const HomeAutoSyncWidget({super.key, required this.onTap});

  @override
  State<HomeAutoSyncWidget> createState() => _HomeAutoSyncWidgetState();
}

class _HomeAutoSyncWidgetState extends _PollingState<HomeAutoSyncWidget> {
  Map<SyncPlatform, AutoSyncTask>? _tasks;
  bool _allFailed = false;

  @override
  Duration get interval => const Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    AutoSyncService.changes.addListener(runRefresh);
  }

  @override
  void dispose() {
    AutoSyncService.changes.removeListener(runRefresh);
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    final tasks = <SyncPlatform, AutoSyncTask>{};
    var failures = 0;
    await Future.wait(SyncPlatform.values.map((platform) async {
      try {
        tasks[platform] = await AutoSyncService.instance.status(platform);
      } catch (_) {
        failures++;
      }
    }));
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _allFailed = failures == SyncPlatform.values.length;
    });
    _pushToDesktop();
  }

  /// 同样的结论也给系统桌面小组件一份。
  void _pushToDesktop() {
    final tasks = _tasks;
    if (tasks == null) return;
    final summary = _summary();
    unawaited(HomeWidgetService.pushSync(
      headline: summary.headline,
      detail: summary.detail,
      tone: summary.tone,
      time: summary.time,
      sources: [
        for (final platform in SyncPlatform.values)
          _sourceBrief(platform, tasks[platform]),
      ],
    ));
  }

  (String, String, String) _sourceBrief(
      SyncPlatform platform, AutoSyncTask? task) {
    final String value;
    final String tone;
    final result = task?.lastResult;
    if (task == null) {
      value = '暂时未知';
      tone = 'off';
    } else if (!task.enabled) {
      value = '未开启';
      tone = 'off';
    } else if (task.status == 'running') {
      value = task.waiting ? '等待上游' : '同步中';
      tone = task.waiting ? 'warn' : 'active';
    } else if (result == null) {
      value = '已开启';
      tone = 'active';
    } else if (result.status == 'failed') {
      value = '上次未完成';
      tone = 'warn';
    } else if (result.submitted > 0) {
      value = '提交 ${result.submitted} 条';
      tone = 'ok';
    } else {
      value = '已是最新';
      tone = 'ok';
    }
    return (platform.label, value, tone);
  }

  /// 一句结论、一行说明、语气，以及不含时间的说明对应的时间。
  ({String headline, String detail, String tone, DateTime? time}) _summary() {
    final tasks = _tasks;
    if (tasks == null) {
      return (headline: '读取中…', detail: '正在获取同步状态', tone: 'off', time: null);
    }
    if (_allFailed) {
      return (headline: '状态未知', detail: '暂时读取不到', tone: 'warn', time: null);
    }
    final enabled = tasks.values.where((task) => task.enabled).toList();
    if (enabled.isEmpty) {
      return (headline: '未开启', detail: '点这里设置', tone: 'off', time: null);
    }
    final running = enabled.where((task) => task.status == 'running');
    if (running.isNotEmpty) {
      final task = running.first;
      return (
        headline: task.waiting ? '等待上游' : '同步中',
        detail: AutoSyncDisplay.progressBrief(task),
        tone: task.waiting ? 'warn' : 'active',
        time: null,
      );
    }
    final results = enabled
        .map((task) => task.lastResult)
        .whereType<AutoSyncRunResult>()
        .toList();
    DateTime? latest;
    for (final task in enabled) {
      final run = task.lastRunAt;
      if (run != null && (latest == null || run.isAfter(latest))) latest = run;
    }
    final failed = results.where((r) => r.status == 'failed').length;
    final submitted = results.fold<int>(0, (sum, r) => sum + r.submitted);
    final String headline;
    final String tone;
    if (results.isEmpty) {
      headline = '已开启';
      tone = 'active';
    } else if (failed > 0) {
      headline = '$failed 个未完成';
      tone = 'error';
    } else if (submitted > 0) {
      headline = '提交 $submitted 条';
      tone = 'ok';
    } else {
      headline = '已是最新';
      tone = 'ok';
    }
    return (
      headline: headline,
      detail: latest == null
          ? '${enabled.length} 个数据源 · 等待执行'
          : '${enabled.length} 个数据源',
      tone: tone,
      time: latest,
    );
  }

  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final clock = '${two(local.hour)}:${two(local.minute)}';
    return sameDay ? '今天 $clock' : '${local.month}月${local.day}日 $clock';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final summary = _summary();
    final accent = switch (summary.tone) {
      'ok' => AppColors.successForeground(theme.brightness),
      'warn' => AppColors.warningOrange(theme.brightness),
      'error' => scheme.error,
      'active' => scheme.primary,
      _ => scheme.outline,
    };
    final time = summary.time;
    return _HomeStatusCard(
      icon: Icons.autorenew_rounded,
      title: '自动同步',
      headline: summary.headline,
      detail: time == null
          ? summary.detail
          : '${summary.detail} · ${_timeLabel(time)}',
      accent: accent,
      onTap: widget.onTap,
    );
  }
}

/// 服务器状态：每 3 分钟自己刷新一次。
class HomeServerStatusWidget extends StatefulWidget {
  final VoidCallback onTap;

  const HomeServerStatusWidget({super.key, required this.onTap});

  @override
  State<HomeServerStatusWidget> createState() => _HomeServerStatusWidgetState();
}

class _HomeServerStatusWidgetState
    extends _PollingState<HomeServerStatusWidget> {
  MaimaiServerStatusEntity? _status;
  bool _failed = false;

  @override
  Duration get interval => const Duration(minutes: 3);

  @override
  Future<void> refresh() async {
    MaimaiServerStatusEntity? status;
    try {
      status = await MaimaiServerStatusService.getServerStatus();
    } catch (e) {
      debugPrint('[HomeServerStatusWidget] 加载失败: $e');
    }
    if (!mounted) return;
    setState(() {
      // 刷新失败时保留上一次的结果，只有从没成功过才显示失败。
      if (status != null) _status = status;
      _failed = status == null;
    });
    if (status != null) {
      unawaited(HomeWidgetService.pushServer(
        headline: _headlineOf(status),
        detail: _detailOf(status),
        tone: status.status == 'normal' ? 'ok' : 'warn',
      ));
    }
  }

  /// 接口的 `status_text` 只有「好」「坏」一个字，`verdict_text` 才是一句描述。
  String _headlineOf(MaimaiServerStatusEntity status) {
    if (status.verdictText.isNotEmpty) return status.verdictText;
    return status.statusText.isEmpty ? '暂时未知' : status.statusText;
  }

  String _detailOf(MaimaiServerStatusEntity status) {
    final total = status.services.length;
    final healthy = status.services.where((s) => s.isHealthy).length;
    final latency = status.latency.currentMs;
    final speed = [
      if (status.latency.loadText.isNotEmpty) status.latency.loadText,
      if (latency != null) '$latency ms',
    ].join(' ');
    return [
      if (total > 0) '$healthy/$total 正常',
      if (speed.isNotEmpty) speed,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = _status;

    String headline;
    String detail;
    Color accent;
    if (status == null) {
      headline = _failed ? '状态未知' : '读取中…';
      detail = _failed ? '暂时读取不到，稍后自动重试' : '正在获取服务器状态';
      accent = _failed
          ? AppColors.warningOrange(theme.brightness)
          : scheme.outline;
    } else {
      headline = _headlineOf(status);
      detail = _detailOf(status);
      accent = status.status == 'normal'
          ? AppColors.successForeground(theme.brightness)
          : AppColors.warningOrange(theme.brightness);
    }
    return _HomeStatusCard(
      icon: Icons.dns_outlined,
      title: '服务器状态',
      headline: headline,
      detail: detail.isEmpty ? '暂无详情' : detail,
      accent: accent,
      onTap: widget.onTap,
    );
  }
}
