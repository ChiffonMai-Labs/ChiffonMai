import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../manager/DivingFish/DivingFishOAuthManager.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../service/AWMC/AwmcQrSyncService.dart';
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../service/AccountAuthorizationStore.dart';
import '../service/SyncRouteStore.dart';
import '../service/SyncStatsService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../utils/SecureCredentialStore.dart';
import '../widgets/AppDialogs.dart';
import 'AccountAuthorizationDialog.dart';
import 'AccountBindingManager.dart' show StatusChip;
import 'AnimatedReveal.dart';
import 'AppToast.dart';
import 'AppUi.dart' hide AnimatedReveal;
import 'ErrorMessageDialog.dart';
import 'PostSyncRefreshOptions.dart';
import 'QuickSyncOption.dart';
import 'RefreshDataDialog.dart' show RefreshDataRequest, RefreshDataSource;
import 'SyncDialogUi.dart';

/// 已确认具备凭据的同步目标，由执行器依次执行。
class MultiScoreSyncInput {
  final String qrCode;
  final bool quickUpdate;
  final Set<SyncPlatform> platforms;
  final Map<SyncPlatform, RefreshDataRequest> refreshRequests;
  final String awmcQq;
  final String fishQq;
  final bool fishOAuthWrite;
  final bool lxOAuth;

  /// 所有目标共用的强制刷新选择。null 表示读取保存的默认配置。
  final Set<String>? forceSourceIds;

  MultiScoreSyncInput({
    required this.qrCode,
    this.quickUpdate = false,
    required Set<SyncPlatform> platforms,
    Map<SyncPlatform, int> routes = const {},
    Map<SyncPlatform, RefreshDataRequest> refreshRequests = const {},
    this.awmcQq = '',
    this.fishQq = '',
    this.fishOAuthWrite = false,
    this.lxOAuth = false,
    Set<String>? forceSourceIds,
  })  : platforms = Set.unmodifiable(platforms),
        refreshRequests = Map.unmodifiable(refreshRequests),
        forceSourceIds =
            forceSourceIds == null ? null : Set.unmodifiable(forceSourceIds);

  int routeOf(SyncPlatform platform) => SyncRouteStore.routeAwmc;

  bool quickUpdateFor(SyncPlatform platform) => quickUpdate;
}

Future<MultiScoreSyncInput?> showMultiScoreSyncInputDialog(
        BuildContext context) =>
    showDialog<MultiScoreSyncInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MultiScoreSyncDialog(),
    );

/// 选择多端同步目标并确认 OAuth 授权 / QQ 身份，网络同步由调用方在弹窗关闭后执行。
class MultiScoreSyncDialog extends StatefulWidget {
  const MultiScoreSyncDialog({super.key});

  @override
  State<MultiScoreSyncDialog> createState() => _MultiScoreSyncDialogState();
}

class _MultiScoreSyncDialogState extends State<MultiScoreSyncDialog> {
  static final _qqPattern = AwmcQrSyncService.qqPattern;
  final _qqController = TextEditingController();
  final _selected = <SyncPlatform>{};
  final _expanded = <SyncPlatform>{};
  final _errors = <SyncPlatform, String>{};
  String _qq = '';
  String _dfQq = '';
  bool _dfOAuthWrite = false;
  bool _lxOAuth = false;
  bool _hasLxFallbackKey = false;
  bool _openingAuth = false;
  String? _selectionError;
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;
  final _refreshKey = GlobalKey<PostSyncRefreshOptionsState>();
  bool _quickUpdate = false;
  SyncPlatform? _saving;
  int _credentialRevision = 0;

  void _setQuickUpdate(bool enabled) {
    if (_quickUpdate == enabled) return;
    setState(() {
      _quickUpdate = enabled;
      _selected.removeWhere((p) => !_ready(p));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _qqController.dispose();
    super.dispose();
  }

  bool _hasFishOAuthWrite() =>
      _qqPattern.hasMatch(_dfQq) && _dfOAuthWrite;

  bool _ready(SyncPlatform platform) => switch (platform) {
        SyncPlatform.awmc => _qqPattern.hasMatch(_qq),
        SyncPlatform.divingFish => _hasFishOAuthWrite(),
        SyncPlatform.luoXue => _lxOAuth || _hasLxFallbackKey,
      };

  Future<void> _loadCredentials() async {
    try {
      final lxKey = (await SecureCredentialStore.read(
                  CacheKeyConstant.probeLxnsImportToken) ??
              '')
          .trim();
      final awmcQq = await AwmcQrSyncService.resolveAwmcNetQq() ?? '';
      final dfQq = await AwmcQrSyncService.resolveDivingFishQq() ?? '';
      final lxOAuth = await LuoXueOAuthManager().isLoggedIn();
      var dfOAuthWrite = false;
      if (_qqPattern.hasMatch(dfQq)) {
        dfOAuthWrite =
            await AwmcQrSyncService.checkFishWriteAuthorized(dfQq) == true;
      }
      if (!mounted) return;
      setState(() {
        _hasLxFallbackKey = lxKey.isNotEmpty;
        _qq = awmcQq;
        _dfQq = dfQq;
        _dfOAuthWrite = dfOAuthWrite;
        _lxOAuth = lxOAuth;
        _selected
          ..clear()
          ..addAll(SyncPlatform.values.where(_ready));
        _credentialRevision++;
        _loading = false;
        _loadError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = context.l10n.flowCouldNotReadSavedCredentialsTryAgain;
      });
    }
  }

  Future<void> _refreshOAuthState(SyncPlatform platform) async {
    setState(() => _openingAuth = true);
    try {
      if (platform == SyncPlatform.divingFish) {
        final dfQq = await AwmcQrSyncService.resolveDivingFishQq() ?? '';
        final writeOk = _qqPattern.hasMatch(dfQq) &&
            await AwmcQrSyncService.checkFishWriteAuthorized(dfQq) == true;
        if (!mounted) return;
        setState(() {
          _dfQq = dfQq;
          _dfOAuthWrite = writeOk;
          _credentialRevision++;
          if (_ready(SyncPlatform.divingFish)) {
            _selected.add(SyncPlatform.divingFish);
            _expanded.remove(SyncPlatform.divingFish);
          }
        });
      } else if (platform == SyncPlatform.luoXue) {
        final lxOk = await LuoXueOAuthManager().isLoggedIn();
        if (!mounted) return;
        setState(() {
          _lxOAuth = lxOk;
          _credentialRevision++;
          if (_ready(SyncPlatform.luoXue)) {
            _selected.add(SyncPlatform.luoXue);
            _expanded.remove(SyncPlatform.luoXue);
          }
        });
      }
    } finally {
      if (mounted) setState(() => _openingAuth = false);
    }
  }

  Future<void> _openFishOAuth() async {
    if (_openingAuth || !_qqPattern.hasMatch(_dfQq)) return;
    setState(() => _openingAuth = true);
    try {
      final opened = await DivingFishOAuthManager().openBindingLink(_dfQq);
      if (!mounted) return;
      AppToast.show(
        opened
            ? context.l10n.flowAuthorizationOpenedCompleteItInYourBrowser
            : context.l10n.flowCouldNotStartAuthorizationTryAgain,
        tone: opened ? AppToastTone.success : AppToastTone.error,
      );
    } finally {
      if (mounted) setState(() => _openingAuth = false);
    }
  }

  Future<void> _openLuoXueOAuth() async {
    if (_openingAuth) return;
    await showAccountAuthorizationDialog(context, luoxue: true);
    if (mounted) await _refreshOAuthState(SyncPlatform.luoXue);
  }

  Future<void> _saveAwmcQq() async {
    if (_saving != null) return;
    final qq = _qqController.text.trim();
    if (!_qqPattern.hasMatch(qq)) {
      setState(() =>
          _errors[SyncPlatform.awmc] = context.l10n.flowEnterA512DigitQQID);
      return;
    }
    setState(() {
      _saving = SyncPlatform.awmc;
      _errors.remove(SyncPlatform.awmc);
    });
    try {
      await AccountAuthorizationStore.saveAwmcQQ(qq);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(CacheKeyConstant.awmcNetSyncQQ, qq)) {
        throw StateError('save_qq_failed');
      }
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _qq = qq;
        _credentialRevision++;
        if (_ready(SyncPlatform.awmc)) _selected.add(SyncPlatform.awmc);
        _expanded.remove(SyncPlatform.awmc);
        _selectionError = null;
        _qqController.clear();
      });
    } catch (_) {
      if (mounted) {
        await showErrorMessageDialog(context,
            message: context.l10n.flowCouldNotSaveCredentialsTryAgain);
      }
    } finally {
      if (mounted) setState(() => _saving = null);
    }
  }

  Future<void> _openSource(SyncPlatform platform) async {
    final url = switch (platform) {
      SyncPlatform.divingFish => ApiUrls.DivingFishProberHomeUrl,
      SyncPlatform.luoXue => ApiUrls.LuoXueBaseUrl,
      SyncPlatform.awmc => ApiUrls.AwmcNetSettingsUrl,
    };
    try {
      if (await ExternalLaunchUtil.open(Uri.parse(url))) return;
    } catch (_) {}
    if (mounted) {
      await showErrorMessageDialog(context,
          message:
              context.l10n.flowCouldNotOpenTheWebsiteVisitP0((url).toString()));
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final targets = _selected.where(_ready).toSet();
    setState(() {
      _selectionError = targets.isEmpty
          ? context.l10n.flowSelectAtLeastOneSourceWithCredentials
          : null;
    });
    if (_selectionError != null) return;
    setState(() => _submitting = true);
    final sources = targets.map(AwmcQuickSyncService.sourceOf).toSet();
    final requests =
        await _refreshKey.currentState?.collectSyncRequests(sources) ??
            <RefreshDataSource, RefreshDataRequest>{};
    if (!mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      setState(() => _submitting = false);
      return;
    }
    Navigator.pop(
        context,
        MultiScoreSyncInput(
          qrCode: '',
          quickUpdate: _quickUpdate,
          platforms: targets,
          awmcQq: _qq,
          fishQq: _dfQq,
          fishOAuthWrite: _hasFishOAuthWrite(),
          lxOAuth: _lxOAuth,
          forceSourceIds: requests.values.firstOrNull?.forceSourceIds,
          refreshRequests: {
            for (final platform in targets)
              if (requests[AwmcQuickSyncService.sourceOf(platform)]
                  case final request?)
                platform: request,
          },
        ));
  }

  Widget _status(String label, bool done, String stateText) => StatusChip(
        done: done,
        text: '$label · $stateText',
      );

  void _togglePlatform(SyncPlatform platform) {
    if (!_ready(platform) || _saving != null) return;
    setState(() {
      if (!_selected.remove(platform)) {
        _selected.add(platform);
      }
      _selectionError = null;
    });
  }

  Widget _buildSource(SyncPlatform platform) {
    final scheme = Theme.of(context).colorScheme;
    final ready = _ready(platform);
    final selected = _selected.contains(platform);
    final expanded = _expanded.contains(platform);
    final saving = _saving == platform;
    final isFirst = platform == SyncPlatform.values.first;

    final statusChip = switch (platform) {
      SyncPlatform.awmc => () {
          final linked = _qqPattern.hasMatch(_qq);
          return _status(
            context.l10n.flowQQID,
            linked,
            linked
                ? context.l10n.accountBindingLinked
                : context.l10n.accountBindingUnlinked,
          );
        }(),
      SyncPlatform.divingFish => () {
          final authorized = _hasFishOAuthWrite();
          return _status(
            context.l10n.flowDivingFishOAuthWriteChip,
            authorized,
            authorized
                ? context.l10n.accountBindingAuthorized
                : context.l10n.accountBindingUnauthorized,
          );
        }(),
      SyncPlatform.luoXue => _lxOAuth
          ? _status(
              context.l10n.flowLXNSOAuthChip,
              true,
              context.l10n.accountBindingAuthorized,
            )
          : _hasLxFallbackKey
              ? _status(
                  context.l10n.flowPersonalAPIKey,
                  true,
                  context.l10n.flowSet,
                )
              : _status(
                  context.l10n.flowLXNSOAuthChip,
                  false,
                  context.l10n.accountBindingUnauthorized,
                ),
    };

    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppSurfaces.card(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.45)
                : scheme.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: ready && _saving == null
                      ? () => _togglePlatform(platform)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 10, 12, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: selected,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: ready && _saving == null
                              ? (_) => _togglePlatform(platform)
                              : null,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  context.featureText(platform.label),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: ready
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                  ),
                                ),
                                statusChip,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedReveal(
                visible: !ready,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context).withValues(alpha: 0.55),
                    border: Border(
                      top: BorderSide(
                        color: scheme.outlineVariant.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context
                                  .l10n.flowFillInCredentialsToSelectThisSource,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _saving == null
                                ? () {
                                    if (expanded) {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    }
                                    setState(() {
                                      if (!_expanded.remove(platform)) {
                                        _expanded.add(platform);
                                      }
                                    });
                                  }
                                : null,
                            icon: AnimatedRotation(
                              turns: expanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                              ),
                            ),
                            label: Text(expanded
                                ? context.l10n.flowCollapse
                                : context.l10n.flowFillInMissingCredentials),
                          ),
                        ],
                      ),
                      AnimatedReveal(
                        visible: expanded,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                switch (platform) {
                                  SyncPlatform.divingFish =>
                                    _qqPattern.hasMatch(_dfQq)
                                        ? context.l10n
                                            .flowMultiFishOAuthWriteMissingHint
                                        : context
                                            .l10n.flowNoDivingFishQqBoundHint,
                                  SyncPlatform.luoXue =>
                                    context.l10n.flowMultiLxnsOAuthMissingHint,
                                  SyncPlatform.awmc =>
                                    context.l10n.flowAWMCNETQQNoTokenHint,
                                },
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (platform == SyncPlatform.divingFish) ...[
                                    if (_qqPattern.hasMatch(_dfQq))
                                      FilledButton.tonal(
                                        onPressed: _openingAuth
                                            ? null
                                            : _openFishOAuth,
                                        child: Text(context
                                            .l10n.flowOpenAuthorizationLink),
                                      ),
                                    OutlinedButton(
                                      onPressed: _openingAuth
                                          ? null
                                          : () => _refreshOAuthState(
                                              SyncPlatform.divingFish),
                                      child: Text(
                                          context.l10n.accountBindingRecheck),
                                    ),
                                  ],
                                  if (platform == SyncPlatform.luoXue)
                                    FilledButton.tonal(
                                      onPressed: _openingAuth
                                          ? null
                                          : _openLuoXueOAuth,
                                      child: Text(
                                          context.l10n.accountAuthorizeLXNS),
                                    ),
                                  TextButton(
                                    onPressed: () => _openSource(platform),
                                    child: Text(context.l10n.flowOpenWebsite),
                                  ),
                                ],
                              ),
                              if (platform == SyncPlatform.awmc &&
                                  !_qqPattern.hasMatch(_qq)) ...[
                                const SizedBox(height: 10),
                                TextField(
                                  key: const ValueKey('multi-sync-qq'),
                                  controller: _qqController,
                                  enabled: _saving == null,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  decoration: InputDecoration(
                                    labelText: context.l10n.flowAWMCNETQQID,
                                    filled: true,
                                    fillColor: AppSurfaces.card(context),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                  ).insetLabel(context),
                                ),
                                AnimatedReveal(
                                  visible: _errors[platform] != null,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      _errors[platform] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FilledButton.tonal(
                                    onPressed:
                                        _saving == null ? _saveAwmcQq : null,
                                    child: Text(saving
                                        ? context.l10n.flowSaving
                                        : context.l10n.flowSaveAndSelect),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSelection = !_loading && _selected.isNotEmpty;
    return AppAlertDialog(
      animateHeight: true,
      title: Text(context.l10n.featureSyncToMultiplePlatforms),
      subtitle: context.l10n.featureSendTheSameScoresToMultipleTrackers,
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SyncDialogSection(
                first: true,
                icon: Icons.bolt_rounded,
                title: context.l10n.syncDialogMode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuickSyncOption(
                      platforms: _loading
                          ? const {}
                          : Set<SyncPlatform>.unmodifiable(_selected),
                      credentialRevision: _credentialRevision,
                      onChanged: _setQuickUpdate,
                    ),
                    AnimatedReveal(
                      visible: !_quickUpdate,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SyncNoticeCard(
                          icon: Icons.qr_code_2_rounded,
                          color: scheme.primary,
                          child: Text(context
                              .l10n.flowOneCabinetQRForAllSelectedRoute1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SyncDialogSection(
                icon: Icons.devices_other_outlined,
                title: context.l10n.flowSyncSources,
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasSelection
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _loading
                        ? '--'
                        : '${_selected.length}/${SyncPlatform.values.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasSelection
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                caption:
                    context.l10n.flowSourcesWithSavedCredentialsAreSelectedBy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_loadError != null) ...[
                      Text(
                        _loadError!,
                        style: TextStyle(color: scheme.error),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() => _loading = true);
                            _loadCredentials();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(context.l10n.flowReloadCredentials),
                        ),
                      ),
                    ] else
                      ...SyncPlatform.values.map(_buildSource),
                    AnimatedReveal(
                      visible: _selectionError != null,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _selectionError ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SyncDialogSection(
                icon: Icons.refresh_rounded,
                title: context.l10n.flowRefreshDataAfterSync,
                caption: context
                    .l10n.flowRefreshAutomaticallyAfterUploadRefreshErrorsAre,
                child: PostSyncRefreshOptions.multi(
                  key: _refreshKey,
                  syncSources:
                      _selected.map(AwmcQuickSyncService.sourceOf).toSet(),
                  awmcSyncQQ: _qq,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving == null ? () => Navigator.pop(context) : null,
          child: Text(context.l10n.featureCancel),
        ),
        SyncStartButton(
          label: context.l10n.flowStartSyncP0((_selected.length).toString()),
          onPressed:
              _loading || _loadError != null || _saving != null || _submitting
                  ? null
                  : _submit,
        ),
      ],
    );
  }
}
