import '../widgets/AnimatedStatMetric.dart';
import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../service/AutoSyncService.dart';
import '../service/AccountStore.dart';
import '../constant/CacheKeyConstant.dart';
import '../utils/SecureCredentialStore.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../service/AWMC/AwmcQuickIdentityStore.dart';
import '../service/SyncStatsService.dart';
import '../utils/AppTheme.dart';
import '../utils/AutoSyncDisplay.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/ErrorMessageDialog.dart';
import '../widgets/FishIcon.dart';
import '../widgets/GuideLinkText.dart';
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
  final String? accountId;
  final bool missingKey;
  const _SourceState(
      {this.task,
      this.registration,
      this.ready = false,
      this.reason = '请先输入二维码绑定机台身份，或完成一次普通二维码同步',
      this.error,
      this.accountId,
      this.missingKey = false});
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
  AutoSyncQueue? _queue;
  bool _queueLoading = true;
  bool _queueRefreshing = false;
  bool _queueError = false;

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
      unawaited(_loadQueue());
      if (!_loading && _saving == null && !_refreshing) _load(silent: true);
      _startPolling();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      unawaited(_loadQueue());
      if (_loading || _saving != null || _refreshing) return;
      _load(silent: true);
    });
  }

  Future<_SourceState> _loadSource(SyncPlatform platform) async {
    AutoSyncRegistration? registration;
    final source = AwmcQuickSyncService.sourceOf(platform);
    AccountMeta? account;
    var missingKey = false;
    var ready = false;
    var reason = '请先设置该数据源的个人 key 和账号';
    try {
      account = (await AccountStore.loadAll())[source.key];
      final key = await SecureCredentialStore.read(_personalKeyOf(platform));
      missingKey = account != null &&
          account.id.isNotEmpty &&
          (key == null || key.trim().isEmpty);
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
          task: task,
          registration: registration,
          ready: ready,
          reason: reason,
          accountId: account?.id,
          missingKey: missingKey);
    } catch (error) {
      return _SourceState(
          registration: registration,
          ready: ready,
          reason: reason,
          accountId: account?.id,
          missingKey: missingKey,
          error: error is AutoSyncException ? error.message : '自动同步状态读取失败，请重试');
    }
  }

  Future<void> _load({bool silent = false}) async {
    unawaited(_loadQueue());
    final request = ++_request;
    _refreshing = true;
    if (!silent) setState(() => _loading = true);
    final states = await Future.wait(SyncPlatform.values.map(_loadSource));
    if (!mounted || request != _request) return;
    setState(() {
      _sources.addAll(Map.fromIterables(SyncPlatform.values, states));
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _loadQueue() async {
    if (_queueRefreshing) return;
    _queueRefreshing = true;
    try {
      final queue = await _service.queueOverview();
      if (!mounted) return;
      setState(() {
        _queue = queue;
        _queueLoading = false;
        _queueError = false;
        _queueRevision++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _queueLoading = false;
        _queueError = true;
        _queueRevision++;
      });
    } finally {
      _queueRefreshing = false;
    }
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
          if (_saving != null) ...[
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
              : '机台成绩读取完成后，单个用户最多处理 $_roundTimeoutMinutes 分钟；读取前的排队和额度等待不计入。超出处理时限或当天服务窗口会结束本轮，次日窗口继续。',
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
    final id = state.accountId ?? registration?.accountId;
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
            child: AppSwitch(
              value: state.enabled,
              onChanged:
                  disabled ? null : (value) => _setEnabled(platform, value),
            ),
          )),
        ]),
        const SizedBox(height: 14),
        if (!_loading && state.missingKey) ...[
          _PersonalKeyForm(
            key: ValueKey('${platform.key}:${state.accountId}'),
            platform: platform,
            accountId: state.accountId!,
            onSaved: () => _load(silent: true),
          ),
          const SizedBox(height: 14),
        ],
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
        if (_service.refreshError(platform) case final String error) ...[
          const SizedBox(height: 8),
          Text('同步已成功，本地刷新未完成：$error',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
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
    final queue = _queue;
    final previous = queue?.previousQueue;
    // 有成功快照时保留已有数字；首次失败显示占位，不把读取失败当作零任务。
    final empty = queue == null ? null : 0;
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
                  child: Text('${queue?.upcoming == true ? '下轮' : '本轮'}队列',
                      style: theme.textTheme.titleSmall)),
              _statusDot(_queueLoading
                  ? '统计加载中'
                  : _queueError
                      ? '更新失败'
                      : '每 3 秒更新'),
            ]),
            const SizedBox(height: 4),
            Text(
                '${queue?.scheduledAt == null ? '北京时间（UTC+8）' : _beijingTime(queue!.scheduledAt)}'
                '${_roundTimeoutMinutes == null ? '' : ' · 单轮上限 $_roundTimeoutMinutes 分钟'}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(children: [
              _queueMetric(queue?.waitingUsers, '排队人数'),
              _queueMetric(queue?.waitingTasks, '待处理任务'),
              _queueMetric(queue?.runningTasks, '处理中', active: true),
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
            ...[
              const SizedBox(height: 18),
              Text('上轮队列处理', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Row(children: [
                _queueMetric(previous?.processedUsers ?? empty, '已处理用户'),
                _queueMetric(previous?.successUsers ?? empty, '成功用户'),
                _queueMetric(previous?.failedUsers ?? empty, '失败用户'),
              ]),
              const SizedBox(height: 7),
              Text(
                  previous == null
                      ? (_queueLoading
                          ? '上轮统计读取中…'
                          : _queueError && queue == null
                              ? '统计暂不可用，将自动重试'
                              : '暂无上轮记录')
                      : '提交 ${previous.submitted} 条 · 跳过 ${previous.skipped} 条 · ${_beijingTime(previous.scheduledAt)}',
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

  Widget _queueMetric(int? value, String label, {bool active = false}) {
    return Expanded(
      child: AnimatedStatMetric(
        key: ValueKey(label),
        value: value,
        label: label,
        active: active,
        revision: _queueRevision,
        loading: _queueLoading,
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

String _personalKeyOf(SyncPlatform platform) => switch (platform) {
      SyncPlatform.divingFish => CacheKeyConstant.probeDivingFishImportToken,
      SyncPlatform.luoXue => CacheKeyConstant.probeLxnsImportToken,
      SyncPlatform.awmc => CacheKeyConstant.awmcNetImportToken,
    };

/// 控制器跟随输入区域自身的生命周期，轮询不会清空尚未保存的输入。
class _PersonalKeyForm extends StatefulWidget {
  final SyncPlatform platform;
  final String accountId;
  final Future<void> Function() onSaved;
  const _PersonalKeyForm(
      {super.key,
      required this.platform,
      required this.accountId,
      required this.onSaved});

  @override
  State<_PersonalKeyForm> createState() => _PersonalKeyFormState();
}

class _PersonalKeyFormState extends State<_PersonalKeyForm> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = '请先填写个人 key');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final source = AwmcQuickSyncService.sourceOf(widget.platform);
      final account = (await AccountStore.loadAll())[source.key];
      if (account?.id != widget.accountId) {
        throw const AutoSyncException('账号已变化，请刷新页面后重新填写');
      }
      final message = await AutoSyncService.instance
          .savePersonalCredential(widget.platform, value);
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      _controller.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      await widget.onSaved();
    } catch (error) {
      if (mounted)
        setState(() => _error =
            error is AutoSyncException ? error.message : '个人 key 保存失败，请重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = switch (widget.platform) {
      SyncPlatform.divingFish => 'https://www.diving-fish.com/maimaidx/prober/',
      SyncPlatform.luoXue =>
        'https://maimai.lxns.net/user/profile?tab=thirdparty',
      SyncPlatform.awmc => 'https://net.wmc.pub/settings/',
    };
    final guide = switch (widget.platform) {
      SyncPlatform.divingFish =>
        '① 在「我的 → 登录水鱼」输入你的 Diving-Fish 水鱼账号密码以获取 ImportToken。\n'
        '② 打开「账号管理 → 水鱼-个人信息」，在 ImportToken 一行点击复制。\n'
        '③ 回到这里粘贴并保存。',
      SyncPlatform.luoXue => '，滑到最底部获取密钥。',
      SyncPlatform.awmc => '，在页面底部生成或轮换Token。',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('还需填写${widget.platform.label}个人 key',
          style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 6),
      if (widget.platform == SyncPlatform.divingFish)
        Text(guide,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))
      else
        GuideLinkText(
          before: '访问 ',
          label: url,
          url: url,
          after: guide,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
      TextButton.icon(
        onPressed: () => ExternalLaunchUtil.open(Uri.parse(url)),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(widget.platform == SyncPlatform.divingFish
            ? '打开水鱼查分器'
            : '打开获取页面'),
      ),
      TextField(
        controller: _controller,
        enabled: !_saving,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: '个人 key',
          hintText: switch (widget.platform) {
            SyncPlatform.divingFish => '在此粘贴 ImportToken...',
            SyncPlatform.luoXue => '在此粘贴落雪个人 API 密钥...',
            SyncPlatform.awmc => '在此粘贴 AWMC NET 成绩导入 Token...',
          },
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          errorText: _error,
        ),
        onSubmitted: (_) => _save(),
      ),
      const SizedBox(height: 8),
      FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? '正在保存…' : '保存个人 key')),
    ]);
  }
}

/// 只有新快照中的数值变化才显示趋势；重复快照会停止箭头动画。
