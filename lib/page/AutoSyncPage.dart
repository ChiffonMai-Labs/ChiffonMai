import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
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
import '../widgets/AppToast.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/QrQuickFillButtons.dart';

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
      this.reason = '',
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

  /// 还没绑定机台身份。三个数据源共用一份，所以表单放在数据源列表上面。
  bool _identityMissing = false;

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
    var reason = '';
    try {
      account = (await AccountStore.loadAll())[source.key];
      final key = await SecureCredentialStore.read(_personalKeyOf(platform));
      missingKey = key == null || key.trim().isEmpty;
      if (missingKey) {
        reason = context.l10n.flowEnterYourPersonalKeyAboveToEnable;
      } else if (account == null || account.id.isEmpty) {
        reason = context.l10n
            .flowNoP0AccountYetSignInThrough(appLocalizeLabel(platform.label));
      } else {
        await AwmcQuickSyncService.accountFor(platform, requireData: false);
        ready = await AwmcQuickIdentityStore.read() != null;
        reason = ready
            ? context.l10n.flowSyncCredentialsReady
            : context.l10n.flowLinkTheCabinetIdentityAboveToEnable;
      }
    } on StateError catch (error) {
      reason = '${error.message}';
    } catch (_) {
      reason = context.l10n.flowCouldNotReadSyncCredentialsTryAgain;
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
          error: error is AutoSyncException
              ? error.message
              : context.l10n.flowCouldNotReadAutoSyncStatusTry);
    }
  }

  Future<void> _load({bool silent = false}) async {
    unawaited(_loadQueue());
    final request = ++_request;
    _refreshing = true;
    if (!silent) setState(() => _loading = true);
    final states = await Future.wait(SyncPlatform.values.map(_loadSource));
    bool identityMissing = _identityMissing;
    try {
      identityMissing = await AwmcQuickIdentityStore.read() == null;
    } catch (_) {
      // 安全存储读取失败时保持上一次的判断
    }
    if (!mounted || request != _request) return;
    setState(() {
      _identityMissing = identityMissing;
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
          throw AutoSyncException(
              context.l10n.flowLinkCabinetIdentityAboveFirst);
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
      AppToast.show(
          enabled
              ? context.l10n.flowP0AutoSyncEnabledScheduledDailyBetween(
                  appLocalizeLabel(platform.label))
              : context.l10n.flowP0AutoSyncDisabledHostedCredentialsDeleted(
                  appLocalizeLabel(platform.label)),
          tone: AppToastTone.success);
    } catch (error) {
      if (!mounted) return;
      if (error is AutoSyncException &&
          (error.code == 'quota_wait' ||
              error.code == 'rate_limited' ||
              error.message.contains('retryAfterSeconds'))) {
        await showErrorMessageDialog(
          context,
          title: context.l10n.flowAutoSyncTemporarilyLimited,
          message: error.message,
        );
        return;
      }
      AppToast.show(
          error is AutoSyncException
              ? error.message
              : context.l10n.flowCouldNotConfigureAutoSyncCheckYour,
          tone: AppToastTone.error);
    } finally {
      if (mounted) {
        await _load();
        if (mounted) setState(() => _saving = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.featureAutoSync,
      actions: [
        IconButton(
            tooltip: context.l10n.flowRefreshStatus,
            onPressed: _loading || _saving != null ? null : _load,
            icon: const Icon(Icons.refresh))
      ],
      // 不用 ListView：滚出屏幕的个人 key 输入框不能被回收，否则没保存的内容会丢。
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            AppDesignTokens.gutter,
            4,
            AppDesignTokens.gutter,
            28 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EntranceAnimation(index: 0, child: _overviewCard()),
            const SizedBox(height: 20),
            AppSectionHeader(title: context.l10n.flowQueueStatus),
            EntranceAnimation(index: 1, child: _queueOverview()),
            const SizedBox(height: 20),
            AppSectionHeader(title: context.l10n.flowSyncSources),
            if (_identityMissing) ...[
              _IdentityBindCard(onBound: () => _load(silent: true)),
              const SizedBox(height: AppDesignTokens.cardGap),
            ],
            for (final (index, platform) in SyncPlatform.values.indexed)
              EntranceAnimation(
                index: index + 2,
                child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
                  child: _sourceTile(platform),
                ),
              ),
            EntranceAnimation(index: 5, child: _guideCard()),
          ],
        ),
      ),
    );
  }

  /// 顶部概览：一眼看到开了几个、什么时候跑、每个数据源现在的状态。
  Widget _overviewCard() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = _sources.values.where((s) => s.enabled).length;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_loading && _sources.isEmpty ? '–' : '$enabled',
              style: AppTheme.number(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: enabled > 0 ? scheme.primary : scheme.onSurface)),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('/ ${SyncPlatform.values.length}',
                style: AppTheme.number(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                  _loading
                      ? context.l10n.flowLoading
                      : context.l10n.flowSourcesEnabled,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child:
                Icon(Icons.autorenew_rounded, size: 24, color: scheme.primary),
          ),
        ]),
        if (_saving != null) ...[
          const SizedBox(height: 12),
          const SmoothLinearProgressIndicator(),
        ],
        const SizedBox(height: 14),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final platform in SyncPlatform.values) _sourceChip(platform),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppSurfaces.inset(context),
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.wb_sunny_outlined,
                  size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: 7),
              Text('08:00–24:00',
                  style: AppTheme.number(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface)),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(context.l10n.flowScheduledQueueWindow,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant))),
            ]),
            const SizedBox(height: 5),
            Text(context.l10n.flowChinaTimeUTC8OnceDailyQuick,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ]),
        ),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_user_outlined,
              size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
              child: Text(
                  context.l10n.flowCredentialsAreEncryptedAndHostedWhileEnabled,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4))),
        ]),
      ]),
    );
  }

  /// 概览里每个数据源一枚小胶囊：开启绿、同步中主题色、等待上游橙、未开启灰。
  Widget _sourceChip(SyncPlatform platform) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = _sources[platform] ?? const _SourceState();
    final task = state.task;
    final color = state.error != null
        ? scheme.error
        : !state.enabled
            ? scheme.outline
            : task?.status == 'running'
                ? (task!.waiting
                    ? AppColors.warningOrange(theme.brightness)
                    : scheme.primary)
                : AppColors.successForeground(theme.brightness);
    return AnimatedContainer(
      duration:
          AppDesignTokens.motion(context, const Duration(milliseconds: 220)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: state.enabled ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(context.featureText(platform.label),
            style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: state.enabled ? color : scheme.onSurfaceVariant)),
      ]),
    );
  }

  /// 规则说明默认收起，内容一条不少。
  Widget _guideCard() {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.7);
    return CollapsibleCard(
      title: context.l10n.flowAboutSync,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.flowUsersAreProcessedInDailyBatchesNew, style: style),
        const SizedBox(height: 8),
        Text(
            _roundTimeoutMinutes == null
                ? context.l10n.flowEachUserBatchHasAProcessingLimit
                : context.l10n.flowAfterReadingCabinetScoresEachUserHas(
                    (_roundTimeoutMinutes).toString()),
            style: style),
        const SizedBox(height: 8),
        Text(context.l10n.flowLinkYourCabinetIdentityUsingAQR, style: style),
      ]),
    );
  }

  /// 卡片里的凹槽分区。
  Widget _insetPanel(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppSurfaces.inset(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        ),
        child: child,
      );

  Widget _sourceTile(SyncPlatform platform) {
    final state = _sources[platform] ?? const _SourceState();
    final task = state.task;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final registration = state.registration;
    final id = state.accountId ?? registration?.accountId;
    final accountLabel = id == null
        ? (state.ready
            ? context.l10n.flowSyncCredentialsReady
            : context.l10n.flowSyncSetupIncomplete)
        : context.l10n.flowAccountEndingInP0(
            (id.length <= 4 ? id : id.substring(id.length - 4)).toString());
    final disabled =
        _loading || _saving != null || (!state.enabled && !state.ready);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall)),
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
              Text(context.featureText(platform.label),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(_saving == platform ? context.l10n.flowSaving : accountLabel,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          )),
          NoRipple(
              child: Semantics(
            label:
                context.l10n.flowP0AutoSync(appLocalizeLabel(platform.label)),
            child: AppSwitch(
              value: state.enabled,
              onChanged:
                  disabled ? null : (value) => _setEnabled(platform, value),
            ),
          )),
        ]),
        const SizedBox(height: 12),
        if (!_loading && state.missingKey) ...[
          _insetPanel(_PersonalKeyForm(
            key: ValueKey('${platform.key}:${state.accountId}'),
            platform: platform,
            accountId: state.accountId ?? '',
            onSaved: () => _load(silent: true),
          )),
          const SizedBox(height: 14),
        ],
        _insetPanel(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (state.error != null) ...[
            _statusLabel(Icons.cloud_off_outlined,
                context.l10n.flowStatusNotConfirmedYet, scheme.error),
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
                      ? context.l10n.flowP0QueueUserPositionP1(
                          (task.queue!.upcoming
                                  ? context.l10n.flowNextRound
                                  : context.l10n.flowThisRound)
                              .toString(),
                          (task.queue?.userPosition ?? task.queue?.position)
                              .toString())
                      : context.l10n.flowEnabledWaitingForSchedule,
                  scheme.primary),
              const SizedBox(height: 7),
              Text(
                  task.queue != null && !task.queue!.upcoming
                      ? context.l10n.flowRoundStartedP0(
                          (_beijingTime(task.queue!.scheduledAt)).toString())
                      : context.l10n.flowNextRunP0(
                          (_beijingTime(task.nextRunAt)).toString()),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ] else
            Text(
                _loading
                    ? context.l10n.flowLoadingSyncStatus
                    : state.ready
                        ? context.l10n.flowOffEnableAnytime
                        : state.reason,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
        ])),
        if (task?.lastResult != null ||
            state.enabled && state.error == null) ...[
          const SizedBox(height: 8),
          _previousResult(task?.lastResult, nextRunAt: task?.nextRunAt),
        ],
        if (_service.refreshError(platform) case final String error) ...[
          const SizedBox(height: 8),
          Text(
              context.l10n.flowSyncSucceededButLocalRefreshWasIncomplete(
                  (error).toString()),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
        ],
        if (task?.queue?.longQueue == true) ...[
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded,
                size: 16, color: AppColors.warningOrange(theme.brightness)),
            const SizedBox(width: 7),
            Expanded(
                child: Text(
                    task!.queue!.queueWarning ??
                        context.l10n.flowTheQueueIsBusyYourRunMay,
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
                    : context.l10n.flowSyncing2,
                accent)),
        if (progress?.value != null)
          Text('${(progress!.value! * 100).round()}%',
              style: theme.textTheme.titleSmall?.copyWith(color: accent)),
      ]),
      const SizedBox(height: 10),
      SmoothLinearProgressIndicator(value: progress?.value, minHeight: 5),
      const SizedBox(height: 7),
      Text(
          waiting
              ? context.l10n.flowLastProgressP0((progressLine).toString())
              : progressLine,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5)),
      if (waitLine != null) ...[
        const SizedBox(height: 4),
        Text(
            context.l10n
                .flowP0NoExecutionSlotIsUsedWhile((waitLine).toString()),
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
        ? context.l10n.flowPreviousRoundNoRunYet
        : succeeded
            ? (result.submitted == 0 && result.unchanged > 0
                ? context.l10n.flowPreviousRoundUpToDateNoUpload
                : context.l10n.flowPreviousRoundCompleteSubmittedP0(
                    (result.submitted).toString()))
            : failed
                ? context.l10n.flowPreviousRoundIncompleteP0(
                    (result.submitted > 0
                            ? context.l10n
                                .flowSubmittedP0((result.submitted).toString())
                            : '')
                        .toString())
                : context.l10n
                    .flowPreviousRoundP0((_resultLabel(result)).toString());
    final stats = result == null ? null : AutoSyncDisplay.resultStats(result);
    final limitMinutes = AutoSyncDisplay.roundTimeoutMinutes(null, result);
    return _insetPanel(
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          Text(
              context.l10n.flowRunTimeP0(
                  (AutoSyncDisplay.resultTimeLine(result)).toString()),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          if (result.collectedAt != null) ...[
            const SizedBox(height: 2),
            Text(
                context.l10n.flowCabinetDataCollectedP0(
                    (AutoSyncDisplay.dateTime(result.collectedAt)).toString()),
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
                      ? context.l10n.flowTheRoundExceededItsTimeLimitAnd
                      : context.l10n.flowTheRoundExceededItsP0MinuteLimit(
                          (limitMinutes).toString()),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.6)),
            ],
          ],
          if (nextRunAt != null) ...[
            const SizedBox(height: 4),
            Text(
                '${failed ? context.l10n.flowNextAutomaticRetry : context.l10n.flowNextRun}：${AutoSyncDisplay.dateTime(nextRunAt)}',
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
    return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(
                      context.l10n.flowP0Queue((queue?.upcoming == true
                              ? context.l10n.flowNextRound
                              : context.l10n.flowThisRound)
                          .toString()),
                      style: theme.textTheme.titleSmall)),
              _statusDot(
                  _queueError,
                  _queueLoading
                      ? context.l10n.flowLoadingStatistics
                      : _queueError
                          ? context.l10n.flowUpdateFailed
                          : context.l10n.flowUpdatesEvery3Seconds),
            ]),
            const SizedBox(height: 4),
            Text(
                '${queue?.scheduledAt == null ? context.l10n.flowChinaTimeUTC8 : _beijingTime(queue!.scheduledAt)}'
                '${_roundTimeoutMinutes == null ? '' : context.l10n.flowLimitP0MinutesPerRound((_roundTimeoutMinutes).toString())}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(children: [
              _queueMetric(queue?.waitingUsers, context.l10n.flowQueuedUsers),
              _queueMetric(queue?.waitingTasks, context.l10n.flowPendingTasks),
              _queueMetric(queue?.runningTasks, context.l10n.flowProcessing2,
                  active: true),
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
                            context.l10n.flowWaitingForUpstreamRecovery,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.warningOrange(theme.brightness),
                            height: 1.5))),
              ])
            ],
            ...[
              const SizedBox(height: 14),
              Divider(height: 1, color: scheme.outlineVariant),
              const SizedBox(height: 14),
              Text(context.l10n.flowPreviousRoundQueue,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Row(children: [
                _queueMetric(previous?.processedUsers ?? empty,
                    context.l10n.flowProcessedUsers),
                _queueMetric(previous?.successUsers ?? empty,
                    context.l10n.flowSuccessfulUsers),
                _queueMetric(previous?.failedUsers ?? empty,
                    context.l10n.flowFailedUsers),
              ]),
              const SizedBox(height: 7),
              Text(
                  previous == null
                      ? (_queueLoading
                          ? context.l10n.flowLoadingPreviousRoundStatistics
                          : _queueError && queue == null
                              ? context.l10n
                                  .flowStatisticsUnavailableRetryingAutomatically
                              : context.l10n.flowNoPreviousRound)
                      : context.l10n.flowSubmittedP0SkippedP1P2(
                          (previous.submitted).toString(),
                          (previous.skipped).toString(),
                          (_beijingTime(previous.scheduledAt)).toString()),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ],
        ));
  }

  Widget _statusDot(bool failed, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
              color: failed ? scheme.error : scheme.primary,
              shape: BoxShape.circle)),
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
        'success' => context.l10n.flowSubmittedP0P1(
            (task.submitted).toString(),
            (task.skipped > 0
                    ? context.l10n.flowSkippedP0UnsupportedCharts(
                        (task.skipped).toString())
                    : '')
                .toString()),
        'running' => context.l10n.featureSyncing,
        'failed' =>
          '${AutoSyncService.errorMessage(task.error)}${task.submitted > 0 ? context.l10n.flowConfirmedP0Submitted((task.submitted).toString()) : ''}',
        _ => context.l10n.flowWaitingForScheduledRun,
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
    if (value == null) return context.l10n.flowWaitingToBeScheduled;
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

/// 绑定机台身份：只用二维码换 userId，二维码本身不保存。
class _IdentityBindCard extends StatefulWidget {
  final Future<void> Function() onBound;

  const _IdentityBindCard({required this.onBound});

  @override
  State<_IdentityBindCard> createState() => _IdentityBindCardState();
}

class _IdentityBindCardState extends State<_IdentityBindCard> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bind() async {
    if (_saving) return;
    final value = _controller.text.trim();
    if (value.isEmpty) {
      setState(() => _error = context.l10n.flowEnterACabinetLoginQRCodeFirst);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AwmcQuickSyncService.bindIdentityWithQr(value);
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      _controller.clear();
      AppToast.show(context.l10n.flowCabinetIdentityLinked);
      await widget.onBound();
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _error = context.l10n.flowLinkFailedCheckTheQRHasNot);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.flowLinkCabinetIdentityFirst,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            context.l10n.flowRequestAndOpenALoginQRCode2,
            style: TextStyle(
                fontSize: 12.5, height: 1.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          QrQuickFillButtons(controller: _controller, enabled: !_saving),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            enabled: !_saving,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: context.l10n.flowCabinetLoginQRCode,
              hintText: 'SGWCMAID...',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              errorText: _error,
            ).insetLabel(context),
            onSubmitted: (_) => _bind(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving ? null : _bind,
            child: Text(_saving
                ? context.l10n.flowLinking2
                : context.l10n.flowLinkCabinetIdentity),
          ),
        ],
      ),
    );
  }
}

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
      setState(() => _error = context.l10n.flowEnterYourPersonalKeyFirst);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final source = AwmcQuickSyncService.sourceOf(widget.platform);
      final account = (await AccountStore.loadAll())[source.key];
      if (widget.accountId.isNotEmpty && account?.id != widget.accountId) {
        throw AutoSyncException(
            context.l10n.flowAccountChangedRefreshThisPageAndEnter);
      }
      final message = await AutoSyncService.instance
          .savePersonalCredential(widget.platform, value);
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      _controller.clear();
      AppToast.show(message);
      await widget.onSaved();
    } catch (error) {
      if (mounted)
        setState(() => _error = error is AutoSyncException
            ? error.message
            : context.l10n.flowCouldNotSaveYourPersonalKeyTry);
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
      SyncPlatform.divingFish => context.l10n.flow1SignInThroughMeSignIn,
      SyncPlatform.luoXue => context.l10n.flowAndScrollToTheBottomToGet,
      SyncPlatform.awmc => context.l10n.flowToGenerateOrRotateYourTokenAt,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
          context.l10n.flowEnterYourP0PersonalKeyToo(
              (widget.platform.label).toString()),
          style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 6),
      if (widget.platform == SyncPlatform.divingFish)
        Text(guide,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))
      else
        GuideLinkText(
          before: context.l10n.flowVisit2,
          label: url,
          url: url,
          after: guide,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
      TextButton.icon(
        onPressed: () => ExternalLaunchUtil.open(Uri.parse(url)),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(widget.platform == SyncPlatform.divingFish
            ? context.l10n.flowOpenDivingFish
            : context.l10n.flowOpenKeyPage),
      ),
      TextField(
        controller: _controller,
        enabled: !_saving,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: context.l10n.flowPersonalKey,
          hintText: switch (widget.platform) {
            SyncPlatform.divingFish => context.l10n.flowPasteImportToken,
            SyncPlatform.luoXue => context.l10n.flowPasteYourLXNSPersonalAPIKey,
            SyncPlatform.awmc =>
              context.l10n.flowPasteYourAWMCNETScoreImportToken,
          },
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          errorText: _error,
        ).insetLabel(context),
        onSubmitted: (_) => _save(),
      ),
      const SizedBox(height: 8),
      FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving
              ? context.l10n.flowSaving
              : context.l10n.flowSavePersonalKey)),
    ]);
  }
}

/// 只有新快照中的数值变化才显示趋势；重复快照会停止箭头动画。
