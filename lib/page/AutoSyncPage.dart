import 'dart:async';

import 'package:flutter/material.dart';

import '../service/AutoSyncService.dart';
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../service/AWMC/AwmcQuickIdentityStore.dart';
import '../service/SyncStatsService.dart';
import '../utils/AppTheme.dart';
import '../utils/AutoSyncDisplay.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/ErrorMessageDialog.dart';
import '../widgets/FishIcon.dart';
import '../widgets/NoRipple.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';

class AutoSyncPage extends StatefulWidget {
  const AutoSyncPage({super.key});
  @override
  State<AutoSyncPage> createState() => _AutoSyncPageState();
}

class _SourceState {
  final AutoSyncTask? task;
  final AutoSyncRegistration? registration;
  final bool ready;
  final String reason;
  final String? error;
  const _SourceState(
      {this.task,
      this.registration,
      this.ready = false,
      this.reason = '请先输入二维码绑定机台身份，或完成一次普通二维码同步',
      this.error});
  bool get enabled => task?.enabled ?? registration?.lastKnownEnabled ?? false;
}

class _AutoSyncPageState extends State<AutoSyncPage>
    with WidgetsBindingObserver {
  final _service = AutoSyncService.instance;
  final Map<SyncPlatform, _SourceState> _sources = {};
  bool _loading = true;
  SyncPlatform? _saving;
  int _request = 0;
  bool _refreshing = false;
  Timer? _pollTimer;
  int _queueRevision = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _pollTimer?.cancel();
    if (state == AppLifecycleState.resumed) {
      if (!_loading && _saving == null && !_refreshing) _load(silent: true);
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _loading || _saving != null || _refreshing) return;
      _load(silent: true);
    });
  }

  Future<_SourceState> _loadSource(SyncPlatform platform) async {
    AutoSyncRegistration? registration;
    var ready = false;
    var reason = '请先设置该数据源的个人 key 和账号';
    try {
      await AwmcQuickSyncService.accountFor(platform, requireData: false);
      ready = await AwmcQuickIdentityStore.read() != null;
      reason = ready ? '同步凭据已就绪' : '请先输入二维码绑定机台身份，凭据可供三个数据源共用';
    } on StateError catch (error) {
      reason = '${error.message}';
    } catch (_) {
      reason = '同步凭据读取失败，请重试';
    }
    try {
      registration = await _service.registration(platform);
      final task = await _service.status(platform);
      return _SourceState(
          task: task, registration: registration, ready: ready, reason: reason);
    } catch (error) {
      return _SourceState(
          registration: registration,
          ready: ready,
          reason: reason,
          error: error is AutoSyncException ? error.message : '自动同步状态读取失败，请重试');
    }
  }

  Future<void> _load({bool silent = false}) async {
    final request = ++_request;
    _refreshing = true;
    if (!silent) setState(() => _loading = true);
    final states = await Future.wait(SyncPlatform.values.map(_loadSource));
    if (!mounted || request != _request) return;
    setState(() {
      _sources.addAll(Map.fromIterables(SyncPlatform.values, states));
      _queueRevision++;
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _setEnabled(SyncPlatform platform, bool enabled) async {
    if (_loading || _saving != null) return;
    ++_request;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _saving = platform);
    try {
      if (enabled) {
        final account =
            await AwmcQuickSyncService.accountFor(platform, requireData: false);
        final userId = await AwmcQuickIdentityStore.read();
        if (userId == null) {
          throw const AutoSyncException('请先输入二维码绑定机台身份，缓存同步凭据');
        }
        await _service.enable(
            platform: platform,
            source: account.source.key,
            accountId: account.id,
            credential: account.credential,
            userId: userId);
      } else {
        await _service.disable(platform);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(enabled
              ? '已开启${platform.label}自动同步，每天北京时间 08:00–24:00 分时处理'
              : '已关闭${platform.label}自动同步，并删除服务端托管凭据')));
    } catch (error) {
      if (!mounted) return;
      if (error is AutoSyncException &&
          (error.code == 'quota_wait' ||
              error.code == 'rate_limited' ||
              error.message.contains('retryAfterSeconds'))) {
        await showErrorMessageDialog(
          context,
          title: '自动同步暂时受限',
          message: error.message,
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is AutoSyncException
              ? error.message
              : '自动同步设置失败，请检查账号状态后重试')));
    } finally {
      if (mounted) {
        await _load();
        if (mounted) setState(() => _saving = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return BackgroundPageScaffold(
      title: '自动同步',
      actions: [
        IconButton(
            tooltip: '刷新状态',
            onPressed: _loading || _saving != null ? null : _load,
            icon: const Icon(Icons.refresh))
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        children: [
          _scheduleHeader(),
          if (_loading || _saving != null) ...[
            const SizedBox(height: 16),
            const SmoothLinearProgressIndicator(),
          ],
          const SizedBox(height: 24),
          _queueOverview(),
          Row(children: [
            Expanded(
                child: Text('同步数据源',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600))),
            Text(
                _loading
                    ? '正在读取…'
                    : '已开启 ${_sources.values.where((s) => s.enabled).length} / ${SyncPlatform.values.length}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 4),
          for (final platform in SyncPlatform.values) _sourceTile(platform),
          const SizedBox(height: 16),
          _statusLabel(Icons.info_outline_rounded, '同步说明', scheme.onSurface),
          const SizedBox(height: 12),
          Text(
              '输入二维码绑定机台身份后，同步凭据可供三个数据源共用；也可以通过一次普通二维码同步自动完成绑定。各数据源仍需配置各自的个人 key 和账号。\n\n每天在北京时间 08:00–24:00 分时安排快速同步：同一用户的三个数据源共用一份机台成绩读取结果，再分别读取目标成绩并上传变化。\n\n执行中会显示当前阶段、已读取页数、上传与已提交条数、已用时长；遇到上游等待会显示原因和预计重试时间。上轮结果会给出耗时、机台数据采集时间和下次重试时间。\n\n自动同步使用统一的上游请求预算和限流；遇到维护、配额不足或网络错误会暂停并显示原因，不会连续重试。\n\n正在执行时关闭，会停止后续批次，已经提交的成绩会保留；上传结果不确定时会先核对，不盲目重复提交。',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.7)),
        ],
      ),
    );
  }

  Widget _scheduleHeader() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.autorenew_rounded, size: 18, color: scheme.primary),
        const SizedBox(width: 7),
        Text('每天一次，分时自动更新',
            style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary)),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        _scheduleTime('08:00–24:00', '分时排队窗口', Icons.wb_sunny_outlined),
      ]),
      const SizedBox(height: 14),
      Text('北京时间（UTC+8） · 每天一次 · 仅快速同步',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Text(
          '每天分批排队处理；批次进行中或等待开始时新加入用户会排在当前批次末尾，批次结束后与其他用户一起进入下一轮随机排序；上游限流或队列较长时会顺延到后续窗口。',
          style: theme.textTheme.bodyMedium),
      const SizedBox(height: 8),
      Text(
          _roundTimeoutMinutes == null
              ? '单个用户批次有整体处理时限：上游慢响应、配额不足或大量上传超过时限时，会自动结束本轮并在上轮结果中说明原因，次日窗口继续（排队等待不计入）。'
              : '单个用户批次最长处理 $_roundTimeoutMinutes 分钟：上游慢响应、配额不足或大量上传超时会自动结束本轮并在上轮结果中说明原因，次日窗口继续（排队等待不计入）。',
          style: theme.textTheme.bodyMedium),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.verified_user_outlined,
            size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 7),
        Expanded(
            child: Text('开启后加密托管同步凭据，关闭即删除。',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5))),
      ]),
    ]);
  }

  Widget _scheduleTime(String time, String label, IconData icon) {
    final theme = Theme.of(context);
    return Flexible(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(time,
            style: theme.textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -1)),
        const SizedBox(height: 4),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ]),
      ]),
    );
  }

  Widget _sourceTile(SyncPlatform platform) {
    final state = _sources[platform] ?? const _SourceState();
    final task = state.task;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final registration = state.registration;
    final id = registration?.accountId;
    final accountLabel = id == null
        ? (state.ready ? '同步凭据已就绪' : '同步配置待完善')
        : '账号尾号 ${id.length <= 4 ? id : id.substring(id.length - 4)}';
    final disabled =
        _loading || _saving != null || (!state.enabled && !state.ready);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: switch (platform) {
              SyncPlatform.divingFish =>
                FishIcon(size: 24, color: scheme.primary),
              SyncPlatform.luoXue =>
                Icon(Icons.ac_unit_outlined, size: 24, color: scheme.primary),
              SyncPlatform.awmc =>
                Icon(Icons.cloud_outlined, size: 24, color: scheme.primary),
            },
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(platform.label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(_saving == platform ? '正在保存…' : accountLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          )),
          NoRipple(
              child: Semantics(
            label: '${platform.label}自动同步',
            child: Switch.adaptive(
              value: state.enabled,
              onChanged:
                  disabled ? null : (value) => _setEnabled(platform, value),
            ),
          )),
        ]),
        const SizedBox(height: 14),
        if (state.error != null) ...[
          _statusLabel(Icons.cloud_off_outlined, '状态暂未确认', scheme.error),
          const SizedBox(height: 6),
          Text(state.error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ] else if (task != null && task.enabled) ...[
          if (task.status == 'running') ...[
            _runningStatus(task, platform),
          ] else ...[
            _statusLabel(
                Icons.schedule_rounded,
                (task.queue?.userPosition ?? task.queue?.position) != null
                    ? '${task.queue!.upcoming ? '下轮' : '本轮'}排队 · 用户第 ${task.queue?.userPosition ?? task.queue?.position} 位'
                    : '已开启 · 等待定时执行',
                scheme.primary),
            const SizedBox(height: 7),
            Text(
                task.queue != null && !task.queue!.upcoming
                    ? '本轮开始：${_beijingTime(task.queue!.scheduledAt)}'
                    : '下次执行：${_beijingTime(task.nextRunAt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ] else
          Text(
              _loading
                  ? '正在读取同步状态…'
                  : state.ready
                      ? '未开启 · 可随时开启'
                      : state.reason,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
        if (task?.lastResult != null ||
            state.enabled && state.error == null) ...[
          const SizedBox(height: 14),
          _previousResult(task?.lastResult, nextRunAt: task?.nextRunAt),
        ],
        if (task?.queue?.longQueue == true) ...[
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded,
                size: 16, color: AppColors.warningOrange(theme.brightness)),
            const SizedBox(width: 7),
            Expanded(
                child: Text(task!.queue!.queueWarning ?? '当前排队人数较多，可能顺延到后续处理窗口',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warningOrange(theme.brightness),
                        height: 1.5))),
          ])
        ]
      ]),
    );
  }

  /// 执行中/等待上游时的详细状态：阶段、等待原因、预计重试、已用时长与采集时间。
  Widget _runningStatus(AutoSyncTask task, SyncPlatform platform) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final waitingColor = AppColors.warningOrange(theme.brightness);
    final waiting = task.waiting;
    final accent = waiting ? waitingColor : scheme.primary;
    final progress = task.progress;
    final waitLine = AutoSyncDisplay.waitLine(task.timing);
    final meta = AutoSyncDisplay.runningMeta(task);
    final progressLine = AutoSyncDisplay.progressLine(task, platform.label);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child: _statusLabel(
                waiting ? Icons.hourglass_top_rounded : Icons.sync_rounded,
                waiting
                    ? AutoSyncDisplay.waitReason(task.timing?.waitReason)
                    : '正在同步',
                accent)),
        if (progress?.value != null)
          Text('${(progress!.value! * 100).round()}%',
              style: theme.textTheme.titleSmall?.copyWith(color: accent)),
      ]),
      const SizedBox(height: 10),
      SmoothLinearProgressIndicator(value: progress?.value, minHeight: 5),
      const SizedBox(height: 7),
      Text(waiting ? '上次进度：$progressLine' : progressLine,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
      if (waitLine != null) ...[
        const SizedBox(height: 4),
        Text('$waitLine；等待期间不占用执行名额',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: waitingColor, height: 1.5)),
      ],
      if (meta != null) ...[
        const SizedBox(height: 4),
        Text(meta,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
      ],
    ]);
  }

  Widget _statusLabel(IconData icon, String label, Color color) => Text.rich(
        TextSpan(children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 7),
              child: Icon(icon, size: 16, color: color),
            ),
          ),
          TextSpan(text: label),
        ]),
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: color, fontWeight: FontWeight.w500),
      );

  Widget _previousResult(AutoSyncRunResult? result, {DateTime? nextRunAt}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final failed = result?.status == 'failed';
    final succeeded = result?.status == 'success';
    final color = failed
        ? scheme.error
        : succeeded
            ? AppColors.successForeground(theme.brightness)
            : scheme.onSurfaceVariant;
    final title = result == null
        ? '上轮 · 暂无执行记录'
        : succeeded
            ? (result.submitted == 0 && result.unchanged > 0
                ? '上轮已是最新 · 无需上传'
                : '上轮已完成 · 提交 ${result.submitted} 条')
            : failed
                ? '上轮未完成${result.submitted > 0 ? ' · 已提交 ${result.submitted} 条' : ''}'
                : '上轮 · ${_resultLabel(result)}';
    final stats = result == null ? null : AutoSyncDisplay.resultStats(result);
    final limitMinutes = AutoSyncDisplay.roundTimeoutMinutes(null, result);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
          border:
              Border(left: BorderSide(color: scheme.outlineVariant, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _statusLabel(
            failed
                ? Icons.error_outline_rounded
                : succeeded
                    ? Icons.check_circle_outline_rounded
                    : Icons.history_rounded,
            title,
            color),
        if (result != null) ...[
          const SizedBox(height: 4),
          Text('执行时间：${AutoSyncDisplay.resultTimeLine(result)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          if (result.collectedAt != null) ...[
            const SizedBox(height: 2),
            Text('机台数据采集：${AutoSyncDisplay.dateTime(result.collectedAt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          if (stats != null) ...[
            const SizedBox(height: 4),
            Text(stats,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          if (failed) ...[
            const SizedBox(height: 8),
            Text(_resultLabel(result),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.6)),
            if (result.error == 'run_timeout') ...[
              const SizedBox(height: 4),
              Text(
                  limitMinutes == null
                      ? '已超过单轮处理时限，被自动结束；未完成的部分会在下次定时时间继续。'
                      : '已超过单轮 $limitMinutes 分钟处理上限，被自动结束；未完成的部分会在下次定时时间继续。',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.6)),
            ],
          ],
          if (nextRunAt != null) ...[
            const SizedBox(height: 4),
            Text(
                '${failed ? '下次自动重试' : '下次执行'}：${AutoSyncDisplay.dateTime(nextRunAt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ],
      ]),
    );
  }

  Widget _queueOverview() {
    final tasks = _sources.values
        .map((s) => s.task)
        .whereType<AutoSyncTask>()
        .where((task) => task.enabled && task.queue != null)
        .toList();
    if (tasks.isEmpty) return const SizedBox.shrink();
    tasks.sort((a, b) => (a.status == 'running' ? 0 : 1)
                .compareTo(b.status == 'running' ? 0 : 1) !=
            0
        ? (a.status == 'running' ? 0 : 1)
            .compareTo(b.status == 'running' ? 0 : 1)
        : (a.queue!.scheduledAt?.millisecondsSinceEpoch ?? 0)
            .compareTo(b.queue!.scheduledAt?.millisecondsSinceEpoch ?? 0));
    final queue = tasks.first.queue!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    AutoSyncTask? waitingTask;
    for (final task in tasks) {
      if (task.waiting) {
        waitingTask = task;
        break;
      }
    }
    return Container(
        margin: const EdgeInsets.only(bottom: 28),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            border: Border(
          top: BorderSide(color: scheme.outlineVariant),
          bottom: BorderSide(color: scheme.outlineVariant),
        )),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text('${queue.upcoming ? '下轮' : '本轮'}队列',
                      style: theme.textTheme.titleSmall)),
              _statusDot('每 3 秒更新'),
            ]),
            const SizedBox(height: 4),
            Text(
                '${_beijingTime(queue.scheduledAt)}'
                '${_roundTimeoutMinutes == null ? '' : ' · 单轮上限 $_roundTimeoutMinutes 分钟'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(children: [
              _queueMetric(queue.waitingUsers, '排队人数'),
              _queueMetric(queue.waitingTasks, '待处理任务'),
              _queueMetric(queue.runningTasks, '处理中', active: true),
            ]),
            if (waitingTask != null) ...[
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 16, color: AppColors.warningOrange(theme.brightness)),
                const SizedBox(width: 7),
                Expanded(
                    child: Text(
                        AutoSyncDisplay.waitLine(waitingTask.timing) ??
                            '等待上游恢复',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warningOrange(theme.brightness),
                            height: 1.5))),
              ])
            ],
            if (queue.previousQueue != null) ...[
              const SizedBox(height: 18),
              Text('上轮队列处理', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Row(children: [
                _queueMetric(queue.previousQueue!.processedUsers, '已处理用户'),
                _queueMetric(queue.previousQueue!.successUsers, '成功用户'),
                _queueMetric(queue.previousQueue!.failedUsers, '失败用户'),
              ]),
              const SizedBox(height: 7),
              Text(
                  '提交 ${queue.previousQueue!.submitted} 条 · 跳过 ${queue.previousQueue!.skipped} 条 · ${_beijingTime(queue.previousQueue!.scheduledAt)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ],
        ));
  }

  Widget _statusDot(String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 5,
          height: 5,
          decoration:
              BoxDecoration(color: scheme.primary, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant)),
    ]);
  }

  Widget _queueMetric(int value, String label, {bool active = false}) {
    return Expanded(
      child: _QueueMetric(
        key: ValueKey(label),
        value: value,
        label: label,
        active: active,
        revision: _queueRevision,
      ),
    );
  }

  String _resultLabel(AutoSyncRunResult task) => switch (task.status) {
        'success' =>
          '已提交 ${task.submitted} 条${task.skipped > 0 ? '，跳过 ${task.skipped} 条不支持的谱面' : ''}',
        'running' => '同步中',
        'failed' =>
          '${AutoSyncService.errorMessage(task.error)}${task.submitted > 0 ? '（已确认提交 ${task.submitted} 条）' : ''}',
        _ => '等待定时执行',
      };

  /// 服务端当前整轮处理上限（分钟）；旧版本接口没有该字段时为 null，文案走通用说法。
  int? get _roundTimeoutMinutes {
    for (final state in _sources.values) {
      final minutes = AutoSyncDisplay.roundTimeoutMinutes(
          state.task?.timing, state.task?.lastResult);
      if (minutes != null) return minutes;
    }
    return null;
  }

  String _beijingTime(DateTime? value) {
    if (value == null) return '等待安排';
    final date = value.toUtc().add(const Duration(hours: 8));
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }
}

/// 只有新快照中的数值变化才显示趋势；重复快照会停止箭头动画。
class _QueueMetric extends StatefulWidget {
  const _QueueMetric(
      {super.key,
      required this.value,
      required this.label,
      required this.revision,
      this.active = false});

  final int value;
  final String label;
  final int revision;
  final bool active;

  @override
  State<_QueueMetric> createState() => _QueueMetricState();
}

class _QueueMetricState extends State<_QueueMetric>
    with TickerProviderStateMixin {
  late final AnimationController _numberController;
  late final AnimationController _arrowController;
  late IntTween _numberTween;
  int _direction = 0;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400), value: 1);
    _arrowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _numberTween = IntTween(begin: widget.value, end: widget.value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _numberController.value = 1;
      _stopArrow();
    }
  }

  @override
  void didUpdateWidget(_QueueMetric oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      // 新结果到来时从当前显示值继续计数，避免动画中途跳回旧目标。
      final current = _numberTween.evaluate(_numberController);
      _numberTween = IntTween(begin: current, end: widget.value);
      if (_reduceMotion) {
        _numberController.value = 1;
        _stopArrow();
      } else {
        _numberController.duration = Duration(
            milliseconds:
                ((widget.value - current).abs() * 80).clamp(240, 600));
        _numberController.forward(from: 0);
        _direction = widget.value > oldWidget.value ? 1 : -1;
        _arrowController.repeat();
      }
    } else if (widget.revision != oldWidget.revision) {
      _stopArrow();
    }
  }

  void _stopArrow() {
    _direction = 0;
    _arrowController.stop();
    _arrowController.reset();
  }

  @override
  void dispose() {
    _numberController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Semantics(
        label:
            '${widget.label} ${widget.value}${_direction > 0 ? '，增加' : _direction < 0 ? '，减少' : ''}',
        excludeSemantics: true,
        child: Row(children: [
          Flexible(
              child: AnimatedBuilder(
            animation: _numberController,
            builder: (context, _) => Text(
              '${_numberTween.evaluate(_numberController)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.active ? theme.colorScheme.primary : null,
              ),
            ),
          )),
          // 保留箭头位置，趋势出现和消失时不挤动数字。
          SizedBox(
              width: 23,
              height: 28,
              child: _direction == 0
                  ? null
                  : AnimatedBuilder(
                      animation: _arrowController,
                      builder: (context, _) => Transform.translate(
                        offset: Offset(
                            0,
                            -_direction *
                                (Curves.easeInOut
                                            .transform(_arrowController.value) *
                                        4 -
                                    2)),
                        child: Icon(
                            _direction > 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 18,
                            color: _direction > 0
                                ? AppColors.errorRed(theme.brightness)
                                : AppColors.successForeground(
                                    theme.brightness)),
                      ),
                    )),
        ]),
      ),
      const SizedBox(height: 3),
      Text(widget.label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}
