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
import '../utils/AppTheme.dart';
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

  Widget _status(String label, bool exists) => StatusChip(
        done: exists,
        text:
            '$label · ${exists ? context.l10n.flowAvailable : context.l10n.flowMissing}',
      );

  Widget _buildSource(SyncPlatform platform) {
    final scheme = Theme.of(context).colorScheme;
    final ready = _ready(platform);
    final saving = _saving == platform;

    final chips = <Widget>[
      switch (platform) {
        SyncPlatform.awmc =>
          _status(context.l10n.flowQQID, _qqPattern.hasMatch(_qq)),
        SyncPlatform.divingFish => _status(
            context.l10n.flowDivingFishOAuthWriteChip, _hasFishOAuthWrite()),
        SyncPlatform.luoXue => _lxOAuth
            ? _status(context.l10n.flowLXNSOAuthChip, true)
            : _hasLxFallbackKey
                ? _status(context.l10n.flowPersonalAPIKey, true)
                : _status(context.l10n.flowLXNSOAuthChip, false),
      },
    ];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        CheckboxListTile(
          value: _selected.contains(platform),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          title: Text(context.featureText(platform.label),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Wrap(spacing: 6, runSpacing: 6, children: chips),
          ),
          onChanged: ready && _saving == null
              ? (value) {
                  setState(() {
                    value == true
                        ? _selected.add(platform)
                        : _selected.remove(platform);
                    _selectionError = null;
                  });
                }
              : null,
        ),
        AppDialogAnimatedHeight(
          child: ready
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            context
                                .l10n.flowFillInCredentialsToSelectThisSource,
                            style: TextStyle(
                                fontSize: 12, color: scheme.onSurfaceVariant)),
                        TextButton.icon(
                          onPressed: _saving == null
                              ? () {
                                  if (_expanded.contains(platform)) {
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
                          icon: Icon(
                              _expanded.contains(platform)
                                  ? Icons.expand_less
                                  : Icons.edit_outlined,
                              size: 18),
                          label: Text(_expanded.contains(platform)
                              ? context.l10n.flowCollapse
                              : context.l10n.flowFillInMissingCredentials),
                        ),
                        if (_expanded.contains(platform)) ...[
                          Text(
                              switch (platform) {
                                SyncPlatform.divingFish => _qqPattern
                                        .hasMatch(_dfQq)
                                    ? context.l10n
                                        .flowMultiFishOAuthWriteMissingHint
                                    : context.l10n.flowNoDivingFishQqBoundHint,
                                SyncPlatform.luoXue =>
                                    context.l10n.flowMultiLxnsOAuthMissingHint,
                                SyncPlatform.awmc =>
                                    context.l10n.flowAWMCNETQQNoTokenHint,
                              },
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            if (platform == SyncPlatform.divingFish) ...[
                              if (_qqPattern.hasMatch(_dfQq))
                                FilledButton.tonal(
                                  onPressed:
                                      _openingAuth ? null : _openFishOAuth,
                                  child: Text(
                                      context.l10n.flowOpenAuthorizationLink),
                                ),
                              OutlinedButton(
                                onPressed: _openingAuth
                                    ? null
                                    : () => _refreshOAuthState(
                                        SyncPlatform.divingFish),
                                child:
                                    Text(context.l10n.accountBindingRecheck),
                              ),
                            ],
                            if (platform == SyncPlatform.luoXue)
                              FilledButton.tonal(
                                onPressed:
                                    _openingAuth ? null : _openLuoXueOAuth,
                                child: Text(context.l10n.accountAuthorizeLXNS),
                              ),
                            TextButton(
                                onPressed: () => _openSource(platform),
                                child: Text(context.l10n.flowOpenWebsite)),
                          ]),
                          if (platform == SyncPlatform.awmc &&
                              !_qqPattern.hasMatch(_qq)) ...[
                            const SizedBox(height: 8),
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
                              ).insetLabel(context),
                            ),
                            if (_errors[platform] != null) ...[
                              const SizedBox(height: 6),
                              Text(_errors[platform]!,
                                  style: TextStyle(color: scheme.error)),
                            ],
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: _saving == null ? _saveAwmcQq : null,
                              child: Text(saving
                                  ? context.l10n.flowSaving
                                  : context.l10n.flowSaveAndSelect),
                            ),
                          ],
                        ],
                      ]),
                ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => AppAlertDialog(
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
                          platforms: _selected,
                          onChanged: _setQuickUpdate,
                        ),
                        AnimatedReveal(
                          visible: !_quickUpdate,
                          child: SyncNoticeCard(
                            icon: Icons.qr_code_2_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            child: Text(context
                                .l10n.flowOneCabinetQRForAllSelectedRoute1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SyncDialogSection(
                    icon: Icons.devices_other_outlined,
                    title: context.l10n.flowSyncSources,
                    caption: context
                        .l10n.flowSourcesWithSavedCredentialsAreSelectedBy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_loading)
                          const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()))
                        else if (_loadError != null) ...[
                          Text(_loadError!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                          TextButton(
                              onPressed: () {
                                setState(() => _loading = true);
                                _loadCredentials();
                              },
                              child: Text(context.l10n.flowReloadCredentials)),
                        ] else
                          ...SyncPlatform.values.map(_buildSource),
                        if (_selectionError != null) ...[
                          const SizedBox(height: 8),
                          Text(_selectionError!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error)),
                        ],
                      ],
                    ),
                  ),
                  SyncDialogSection(
                    icon: Icons.refresh_rounded,
                    title: context.l10n.flowRefreshDataAfterSync,
                    caption: context.l10n
                        .flowRefreshAutomaticallyAfterUploadRefreshErrorsAre,
                    child: PostSyncRefreshOptions.multi(
                      key: _refreshKey,
                      syncSources:
                          _selected.map(AwmcQuickSyncService.sourceOf).toSet(),
                      awmcSyncQQ: _qq,
                    ),
                  ),
                  AnimatedReveal(
                      visible: !_quickUpdate &&
                          _selected.contains(SyncPlatform.awmc),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SyncNoticeCard(
                          icon: Icons.info_outline,
                          color: AppColors.warningOrange(
                              Theme.of(context).brightness),
                          child: Text(context.l10n
                              .flowAWMCNETOverwritesMatchingRecordsWithCabinet),
                        ),
                      )),
                ]),
          ),
        ),
        actions: [
          TextButton(
              onPressed: _saving == null ? () => Navigator.pop(context) : null,
              child: Text(context.l10n.featureCancel)),
          SyncStartButton(
              label:
                  context.l10n.flowStartSyncP0((_selected.length).toString()),
              onPressed: _loading ||
                      _loadError != null ||
                      _saving != null ||
                      _submitting
                  ? null
                  : _submit),
        ],
      );
}
