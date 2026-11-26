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
    show RefreshDataRequest, RefreshDataSource, executeRefreshData;
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
  RefreshDataSource? _selectedSource;
  bool _busyAction = false;
  bool _refreshing = false;
  double _refreshProgress = 0;
  String _refreshText = '';
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _syncDefaultSelection();
    unawaited(_refreshBindingStatuses());
  }

  Future<void> _refreshBindingStatuses() async {
    await AccountAuthorizationStatus.refresh();
    if (!mounted) return;
    setState(_syncDefaultSelection);
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

  void _syncDefaultSelection() {
    final ready = _readySources;
    if (ready.isEmpty) {
      _selectedSource = null;
      return;
    }
    if (_selectedSource == null || !ready.contains(_selectedSource)) {
      _selectedSource = ready.first;
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

  Future<void> _handleAwmcAction() async {
    if (_busyAction || _refreshing) return;
    setState(() => _busyAction = true);
    try {
      final outcome =
          await showAccountAuthorizationDialog(context, luoxue: false);
      if (!mounted) return;
      if (outcome.saved && _isSourceReady(RefreshDataSource.awmc)) {
        setState(() => _selectedSource = RefreshDataSource.awmc);
      } else {
        setState(_syncDefaultSelection);
      }
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
            setState(() => _selectedSource = RefreshDataSource.shuiyu);
            return;
          }
        }
        final becameAuthorized =
            await showDivingFishAuthorizationDialog(context);
        if (!mounted) return;
        if (becameAuthorized || _isSourceReady(RefreshDataSource.shuiyu)) {
          setState(() => _selectedSource = RefreshDataSource.shuiyu);
        } else {
          setState(_syncDefaultSelection);
        }
        return;
      }

      final becameAuthorized = await showDivingFishAuthorizationDialog(context);
      if (!mounted) return;
      if (becameAuthorized && _isSourceReady(RefreshDataSource.shuiyu)) {
        setState(() => _selectedSource = RefreshDataSource.shuiyu);
      } else {
        setState(_syncDefaultSelection);
      }
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
      if (outcome.saved && _isSourceReady(RefreshDataSource.luoxue)) {
        setState(() => _selectedSource = RefreshDataSource.luoxue);
      } else {
        setState(_syncDefaultSelection);
      }
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
    if (_refreshing || _busyAction || _closing || ready.isEmpty) return;
    final source = (_selectedSource != null && ready.contains(_selectedSource))
        ? _selectedSource!
        : ready.first;

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _refreshing = true;
      _refreshProgress = 0;
      _refreshText = context.l10n.flowRefreshingData;
    });
    HomeRefreshNotifier.setBusy(true);
    var qq = '';
    try {
      qq = switch (source) {
        RefreshDataSource.awmc =>
          (await AccountAuthorizationStore.awmcQQ()).trim(),
        RefreshDataSource.shuiyu => await _resolveDivingFishBindQQ(),
        RefreshDataSource.luoxue => '',
      };
      final request = RefreshDataRequest(
        dataSource: source,
        qq: qq,
        authCode: '',
        participateRankings: false,
        showNickname: false,
        showBriefProfile: false,
        forceFullRefresh: false,
        useSavedAuthorization: source == RefreshDataSource.luoxue,
      );
      await AppTaskActivity.run(
        () => executeRefreshData(
          request,
          onProgress: (progress, text) {
            if (!mounted) return;
            setState(() {
              _refreshProgress = (progress / 100).clamp(0.0, 1.0);
              _refreshText = '$text $progress%';
            });
          },
        ),
      );
      if (!mounted) return;
      ConfettiEffect.show(context);
      AppToast.show(context.l10n.flowDataRefreshed, tone: AppToastTone.success);
      _closing = true;
      await OnboardingStateStore.instance.markAccountBindingGuideCompleted();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        await presentRefreshError(context, e, qq: qq);
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
            final activeSource =
                (_selectedSource != null && readySources.contains(_selectedSource))
                    ? _selectedSource
                    : (readySources.isNotEmpty ? readySources.first : null);
            final fishLoggedIn = LoginStateNotifier.instance.value;
            final fishReady = _isSourceReady(RefreshDataSource.shuiyu);
            final showFishAuthPrompt =
                readySources.isEmpty && fishLoggedIn && !fishReady;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: topInset + 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.gutter),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed:
                            _refreshing || _busyAction ? null : _skipAndClose,
                        child: Text(l10n.flowSkip),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EntranceAnimation(
                          offset: const Offset(0, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radiusMedium),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.link_rounded,
                                  size: 26,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Semantics(
                                header: true,
                                child: Text(
                                  l10n.firstBindTitle,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.firstBindSubtitle,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  height: 1.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        for (final (index, source)
                            in RefreshDataSource.values.indexed)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: EntranceAnimation(
                              index: index,
                              baseDelay: const Duration(milliseconds: 80),
                              offset: const Offset(0, 8),
                              duration: const Duration(milliseconds: 300),
                              child: _buildSourceCard(
                                context,
                                source: source,
                                readySources: readySources,
                                activeSource: activeSource,
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
                        const SizedBox(height: 4),
                        EntranceAnimation(
                          baseDelay: const Duration(milliseconds: 200),
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
                    activeSource: activeSource,
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
    required RefreshDataSource? activeSource,
  }) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final ready = _isSourceReady(source);
    final selected = ready && activeSource == source;
    final canSwitch = ready && !_refreshing && !_busyAction;

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
                        if (selected)
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
      onTap: canSwitch && readySources.length > 1
          ? () => setState(() => _selectedSource = source)
          : null,
      child: cardContent,
    );
  }

  Widget _buildBottomActionArea(
    BuildContext context, {
    required RefreshDataSource? activeSource,
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

    if (activeSource != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PressScale(
            scale: 0.98,
            child: FilledButton(
              onPressed: _busyAction ? null : _pullInitialDataAndFinish,
              child: Text(
                l10n.firstBindPullAndEnter(activeSource.displayName),
              ),
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
