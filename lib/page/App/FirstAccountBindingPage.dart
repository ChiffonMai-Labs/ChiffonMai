import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constant/CacheKeyConstant.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../manager/DivingFish/DivingFishOAuthManager.dart';
import '../../manager/DivingFish/DivingFishProbeManager.dart';
import '../../service/Account/AccountAuthorizationStore.dart';
import '../../service/System/OnboardingStateStore.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTaskActivity.dart';
import '../../utils/AppTheme.dart';
import '../../utils/HomeRefreshNotifier.dart';
import '../../utils/LoginStateNotifier.dart';
import '../../utils/RefreshErrorPresenter.dart';
import '../../widgets/AccountAuthorizationDialog.dart';
import '../../widgets/AccountBindingManager.dart';
import '../../widgets/AccountAuthorizationStatus.dart';
import '../../widgets/AccountRegistrationGuideDialog.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/ConfettiEffect.dart';
import '../../widgets/DivingFishAuthorizationDialog.dart';
import '../../widgets/RefreshDataDialog.dart'
    show
        RefreshDataRequest,
        RefreshDataSource,
        SharedRefreshData,
        executeAdvancedRefreshData;
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../../widgets/SyncScoreDialogs.dart' show SyncCallbacks, SyncScoreDialogs;

/// 首次安装完成基础引导后的账号快速绑定引导页。
class FirstAccountBindingPage extends StatefulWidget {
  const FirstAccountBindingPage({super.key});

  @override
  State<FirstAccountBindingPage> createState() =>
      _FirstAccountBindingPageState();
}

class _FirstAccountBindingPageState extends State<FirstAccountBindingPage> {
  final Set<RefreshDataSource> _selectedSources = <RefreshDataSource>{};
  final Set<RefreshDataSource> _knownReadySources = <RefreshDataSource>{};
  RefreshDataSource? _lastInteractedSource;
  bool _busyAction = false;
  bool _refreshing = false;
  double _refreshProgress = 0;
  String _refreshText = '';
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _syncSelectionWithReady();
    accountBindingChanges.addListener(_onBindingsChanged);
    unawaited(_refreshBindingStatuses());
  }

  @override
  void dispose() {
    accountBindingChanges.removeListener(_onBindingsChanged);
    super.dispose();
  }

  void _onBindingsChanged() {
    if (!mounted) return;
    setState(_syncSelectionWithReady);
  }

  Future<void> _refreshBindingStatuses() async {
    await AccountAuthorizationStatus.refresh();
    if (!mounted) return;
    setState(_syncSelectionWithReady);
  }

  bool _isSourceReady(RefreshDataSource source) => switch (source) {
        RefreshDataSource.awmc => AccountBindingTarget.awmc.done,
        RefreshDataSource.shuiyu => AccountBindingTarget.divingFishAuth.done,
        RefreshDataSource.luoxue => AccountBindingTarget.lxns.done,
      };

  List<RefreshDataSource> get _readySources => [
        for (final source in RefreshDataSource.values)
          if (_isSourceReady(source)) source,
      ];

  /// 同步已就绪平台集合：新就绪的平台默认纳入批量拉取，同时保留用户的手动取消勾选。
  void _syncSelectionWithReady() {
    final ready = _readySources.toSet();
    _selectedSources.removeWhere((s) => !ready.contains(s));
    for (final s in ready) {
      if (!_knownReadySources.contains(s)) {
        _selectedSources.add(s);
      }
    }
    _knownReadySources
      ..clear()
      ..addAll(ready);
  }

  List<RefreshDataSource> _effectiveSelectedTargets(
      List<RefreshDataSource> ready) {
    return [
      for (final source in ready)
        if (_selectedSources.contains(source)) source,
    ];
  }

  void _markNewlyBound(RefreshDataSource source) {
    _syncSelectionWithReady();
    if (_isSourceReady(source)) {
      _selectedSources.add(source);
      _lastInteractedSource = source;
    }
  }

  SyncCallbacks get _syncCallbacks => SyncCallbacks(
        onSaveQQ: (qq) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(CacheKeyConstant.probeDivingFishBindQQ, qq);
        },
        onRefreshAfterSync: ({
          required String qq,
          required void Function(double progress, String text) onProgress,
          required bool participateRankings,
          required bool showNickname,
        }) async {},
        onLoginStateChanged: () async {
          LoginStateNotifier.setLoggedIn(true);
        },
      );

  Future<String> _resolveDivingFishBindQQ() async {
    final prefs = await SharedPreferences.getInstance();
    final cached =
        prefs.getString(CacheKeyConstant.probeDivingFishBindQQ)?.trim() ?? '';
    if (cached.isNotEmpty) return cached;
    return (await DivingFishProbeManager().fetchBindQQ())?.trim() ?? '';
  }

  Future<String> _resolveQqForSource(RefreshDataSource source) async =>
      switch (source) {
        RefreshDataSource.awmc =>
          (await AccountAuthorizationStore.awmcQQ()).trim(),
        RefreshDataSource.shuiyu => await _resolveDivingFishBindQQ(),
        RefreshDataSource.luoxue => '',
      };

  Future<void> _handleAwmcAction() async {
    if (_busyAction || _refreshing) return;
    setState(() => _busyAction = true);
    try {
      final outcome =
          await showAccountAuthorizationDialog(context, luoxue: false);
      if (!mounted) return;
      setState(() {
        if (outcome.saved && _isSourceReady(RefreshDataSource.awmc)) {
          _markNewlyBound(RefreshDataSource.awmc);
        } else {
          _syncSelectionWithReady();
        }
      });
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _handleDivingFishAction() async {
    if (_busyAction || _refreshing) return;
    setState(() => _busyAction = true);
    try {
      if (!LoginStateNotifier.instance.value) {
        final loggedIn = await SyncScoreDialogs.showDivingFishLoginDialog(
            context, _syncCallbacks);
        if (!mounted || !loggedIn) return;
        final bindQQ = await _resolveDivingFishBindQQ();
        if (bindQQ.isNotEmpty) {
          final authorized =
              await DivingFishOAuthManager().checkAuthorization(bindQQ);
          if (!mounted) return;
          if (authorized == true) {
            setState(() => _markNewlyBound(RefreshDataSource.shuiyu));
            return;
          }
        }
        final becameAuthorized =
            await showDivingFishAuthorizationDialog(context);
        if (!mounted) return;
        setState(() {
          if (becameAuthorized || _isSourceReady(RefreshDataSource.shuiyu)) {
            _markNewlyBound(RefreshDataSource.shuiyu);
          } else {
            _syncSelectionWithReady();
          }
        });
        return;
      }

      final becameAuthorized = await showDivingFishAuthorizationDialog(context);
      if (!mounted) return;
      setState(() {
        if (becameAuthorized && _isSourceReady(RefreshDataSource.shuiyu)) {
          _markNewlyBound(RefreshDataSource.shuiyu);
        } else {
          _syncSelectionWithReady();
        }
      });
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _handleLxnsAction() async {
    if (_busyAction || _refreshing) return;
    setState(() => _busyAction = true);
    try {
      final outcome =
          await showAccountAuthorizationDialog(context, luoxue: true);
      if (!mounted) return;
      setState(() {
        if (outcome.saved && _isSourceReady(RefreshDataSource.luoxue)) {
          _markNewlyBound(RefreshDataSource.luoxue);
        } else {
          _syncSelectionWithReady();
        }
      });
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _skipAndClose() async {
    if (_refreshing || _busyAction || _closing) return;
    _closing = true;
    FocusManager.instance.primaryFocus?.unfocus();
    await OnboardingStateStore.instance.markAccountBindingGuideCompleted();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pullInitialDataAndFinish() async {
    final ready = _readySources;
    final targets = _effectiveSelectedTargets(ready);
    if (_refreshing || _busyAction || _closing || targets.isEmpty) return;

    // 把用户最后交互过的平台放到末尾，拉取完成后它自然保留为首页当前活动源。
    final orderedTargets = List<RefreshDataSource>.of(targets);
    if (orderedTargets.length > 1 &&
        _lastInteractedSource != null &&
        orderedTargets.contains(_lastInteractedSource)) {
      orderedTargets
        ..remove(_lastInteractedSource!)
        ..add(_lastInteractedSource!);
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _refreshing = true;
      _refreshProgress = 0;
      _refreshText = context.l10n.flowRefreshingData;
    });
    HomeRefreshNotifier.setBusy(true);

    // 多个平台共享同一份公共曲库与定数刷新任务，避免重复请求公共数据源。
    final shared = SharedRefreshData(forceSourceIds: const {});
    final succeeded = <RefreshDataSource>[];
    final failures = <({RefreshDataSource source, Object error, String qq})>[];

    try {
      await AppTaskActivity.run(() async {
        final total = orderedTargets.length;
        for (var i = 0; i < total; i++) {
          final source = orderedTargets[i];
          var qq = '';
          try {
            qq = await _resolveQqForSource(source);
            final request = RefreshDataRequest(
              dataSource: source,
              qq: qq,
              authCode: '',
              participateRankings: false,
              showNickname: false,
              showBriefProfile: false,
              forceFullRefresh: false,
              forceSourceIds: const {},
              useSavedAuthorization: source == RefreshDataSource.luoxue,
            );
            await executeAdvancedRefreshData(
              request,
              sharedRefresh: shared,
              onProgress: (progress, text) {
                if (!mounted) return;
                final combined = ((i * 100 + progress) / (total * 100))
                    .clamp(0.0, 1.0);
                setState(() {
                  _refreshProgress = combined;
                  _refreshText = total > 1
                      ? '[${i + 1}/$total ${source.displayName}] $text $progress%'
                      : '$text $progress%';
                });
              },
            );
            succeeded.add(source);
          } catch (e) {
            failures.add((source: source, error: e, qq: qq));
          }
        }
      });

      if (!mounted) return;
      if (failures.isEmpty) {
        ConfettiEffect.show(context);
        AppToast.show(context.l10n.flowDataRefreshed,
            tone: AppToastTone.success);
        _closing = true;
        await OnboardingStateStore.instance.markAccountBindingGuideCompleted();
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      if (succeeded.isNotEmpty) {
        // 已拉取成功的平台取消勾选，方便用户只针对失败平台重试或直接跳过进入首页。
        setState(() {
          for (final done in succeeded) {
            _selectedSources.remove(done);
          }
        });
        final failedNames =
            failures.map((f) => f.source.displayName).join('、');
        AppToast.show(
          context.l10n.firstBindPartialFailure(
            succeeded.length,
            orderedTargets.length,
            failedNames,
          ),
          tone: AppToastTone.warning,
        );
        return;
      }

      await presentRefreshError(
        context,
        failures.first.error,
        qq: failures.first.qq,
      );
      if (mounted && failures.length > 1) {
        final failedNames =
            failures.map((f) => f.source.displayName).join('、');
        AppToast.show(
          context.l10n.firstBindPartialFailure(
            0,
            orderedTargets.length,
            failedNames,
          ),
          tone: AppToastTone.warning,
        );
      }
    } finally {
      HomeRefreshNotifier.setBusy(false);
      if (mounted) {
        setState(() {
          _refreshing = false;
          _refreshProgress = 0;
          _refreshText = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final topInset = MediaQuery.paddingOf(context).top;

    return PopScope(
      canPop: !_refreshing && !_busyAction,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_closing) {
          _closing = true;
          unawaited(
              OnboardingStateStore.instance.markAccountBindingGuideCompleted());
        }
      },
      child: BackgroundPageScaffold(
        title: l10n.firstBindTitle,
        showBack: false,
        headerOverride: const SizedBox.shrink(),
        contentPadding: EdgeInsets.zero,
        child: ListenableBuilder(
          listenable: accountBindingChanges,
          builder: (context, _) {
            final readySources = _readySources;
            final selectedTargets = _effectiveSelectedTargets(readySources);
            final fishLoggedIn = LoginStateNotifier.instance.value;
            final fishReady = _isSourceReady(RefreshDataSource.shuiyu);
            final showFishAuthPrompt =
                readySources.isEmpty && fishLoggedIn && !fishReady;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topInset + 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.gutter),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.link_rounded,
                          size: 22,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            l10n.firstBindTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _refreshing || _busyAction ? null : _skipAndClose,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(l10n.flowSkip),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppDesignTokens.gutter, 8, AppDesignTokens.gutter, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EntranceAnimation(
                          offset: const Offset(0, 8),
                          child: Text(
                            l10n.firstBindSubtitle,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final (index, source)
                            in RefreshDataSource.values.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: EntranceAnimation(
                              index: index,
                              baseDelay: const Duration(milliseconds: 60),
                              offset: const Offset(0, 8),
                              duration: const Duration(milliseconds: 280),
                              child: _buildSourceCard(
                                context,
                                source: source,
                                readySources: readySources,
                              ),
                            ),
                          ),
                        if (readySources.length > 1)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              l10n.firstBindTapToSelectSource,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        const SizedBox(height: 2),
                        EntranceAnimation(
                          baseDelay: const Duration(milliseconds: 180),
                          offset: const Offset(0, 8),
                          child: AppCard(
                            radius: AppDesignTokens.radiusMedium,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            onTap: _refreshing || _busyAction
                                ? null
                                : () => showAccountRegistrationGuide(context),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color:
                                        scheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppDesignTokens.radiusSmall),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.menu_book_outlined,
                                    size: 20,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.firstBindNoAccountTitle,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.firstBindNoAccountSubtitle,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            l10n.firstBindLaterHint,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
                      AppDesignTokens.gutter, 16 + safeBottom),
                  child: _buildBottomActionArea(
                    context,
                    readySources: readySources,
                    selectedTargets: selectedTargets,
                    showFishAuthPrompt: showFishAuthPrompt,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSourceCard(
    BuildContext context, {
    required RefreshDataSource source,
    required List<RefreshDataSource> readySources,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final ready = _isSourceReady(source);
    final selected = ready && _selectedSources.contains(source);
    final canToggle = ready && readySources.length > 1 && !_refreshing && !_busyAction;

    final IconData icon;
    final String title;
    final String description;
    final String statusText;
    final bool statusDone;
    final String actionLabel;
    final VoidCallback onAction;
    final bool isRecommended = source == RefreshDataSource.awmc;

    switch (source) {
      case RefreshDataSource.awmc:
        final qq = AccountAuthorizationStore.awmcAccount.value.trim();
        icon = Icons.link_outlined;
        title = l10n.accountBindingAwmc;
        description = l10n.firstBindAwmcDesc;
        statusDone = ready;
        statusText = ready ? 'QQ $qq' : l10n.accountBindingUnlinked;
        actionLabel = ready ? l10n.firstBindActionEdit : l10n.firstBindActionLink;
        onAction = _handleAwmcAction;
      case RefreshDataSource.shuiyu:
        final loggedIn = LoginStateNotifier.instance.value;
        icon = Icons.water_outlined;
        title = l10n.featureFish;
        description = l10n.firstBindFishDesc;
        statusDone = ready;
        if (ready) {
          statusText = l10n.firstBindReady;
          actionLabel = l10n.firstBindActionAuthStatus;
        } else if (loggedIn) {
          statusText = l10n.firstBindNeedAuth;
          actionLabel = l10n.firstBindActionAuthorize;
        } else {
          statusText = l10n.accountBindingSignedOut;
          actionLabel = l10n.firstBindActionSignIn;
        }
        onAction = _handleDivingFishAction;
      case RefreshDataSource.luoxue:
        icon = Icons.ac_unit_outlined;
        title = l10n.featureLxns;
        description = l10n.firstBindLxnsDesc;
        statusDone = ready;
        statusText =
            ready ? l10n.accountBindingAuthorized : l10n.accountBindingUnauthorized;
        actionLabel = ready
            ? l10n.firstBindActionReauthorize
            : l10n.firstBindActionAuthorize;
        onAction = _handleLxnsAction;
    }

    final cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 21, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        if (isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l10n.firstBindRecommended,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusChip(
                          done: statusDone,
                          text: statusText,
                          highlighted: selected,
                        ),
                        if (ready && readySources.length > 1)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 15,
                                color: selected
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                              if (selected) ...[
                                const SizedBox(width: 3),
                                Text(
                                  l10n.firstBindSelectedForPull,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AppColors.successForeground(brightness),
                                  ),
                                ),
                              ],
                            ],
                          )
                        else if (selected)
                          Text(
                            l10n.firstBindSelectedForPull,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successForeground(brightness),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _refreshing || _busyAction ? null : onAction,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(0, 36),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: EdgeInsets.zero,
      onTap: canToggle
          ? () => setState(() {
                if (_selectedSources.contains(source)) {
                  _selectedSources.remove(source);
                } else {
                  _selectedSources.add(source);
                  _lastInteractedSource = source;
                }
              })
          : null,
      child: cardContent,
    );
  }

  Widget _buildBottomActionArea(
    BuildContext context, {
    required List<RefreshDataSource> readySources,
    required List<RefreshDataSource> selectedTargets,
    required bool showFishAuthPrompt,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    if (_refreshing) {
      return AppCard(
        radius: AppDesignTokens.radiusMedium,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _refreshText.isEmpty ? l10n.flowRefreshingData : _refreshText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SmoothLinearProgressIndicator(value: _refreshProgress),
          ],
        ),
      );
    }

    if (readySources.isNotEmpty) {
      final buttonLabel = switch (selectedTargets.length) {
        0 => l10n.firstBindSelectSourceToPull,
        1 => l10n.firstBindPullAndEnter(selectedTargets.first.displayName),
        final count => l10n.firstBindPullMultipleAndEnter(count),
      };
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressScale(
            scale: 0.98,
            child: FilledButton(
              onPressed: (_busyAction || selectedTargets.isEmpty)
                  ? null
                  : _pullInitialDataAndFinish,
              child: Text(buttonLabel),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: _busyAction ? null : _skipAndClose,
            child: Text(l10n.firstBindSkipPullEnter),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showFishAuthPrompt)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.firstBindFishAuthPrompt,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.warningOrange(brightness),
              ),
            ),
          ),
        PressScale(
          scale: 0.98,
          child: FilledButton.tonal(
            onPressed: _busyAction ? null : _skipAndClose,
            child: Text(l10n.firstBindSkipForNow),
          ),
        ),
      ],
    );
  }
}
