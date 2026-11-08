import 'AnimatedReveal.dart';
import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'AnimatedChoiceBar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../service/AccountStore.dart';
import '../service/SyncStatsService.dart';
import '../service/SyncRouteStore.dart';
import '../utils/SyncRouteNotifier.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../utils/SecureCredentialStore.dart';
import 'ErrorMessageDialog.dart';
import 'QuickSyncOption.dart';
import 'PostSyncRefreshOptions.dart';
import 'RefreshDataDialog.dart' show RefreshDataRequest;
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../widgets/AppDialogs.dart';
import 'AppUi.dart' hide AnimatedReveal;
import 'AccountBindingManager.dart' show StatusChip;
import 'SyncDialogUi.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';

/// 已确认具备凭据的同步目标；顺序由执行器固定为水鱼 → 落雪 → AWMC NET。
class MultiScoreSyncInput {
  final String qrCode;
  final bool quickUpdate;
  final Set<SyncPlatform> platforms;
  final Map<SyncPlatform, int> routes;
  final Map<SyncPlatform, RefreshDataRequest> refreshRequests;

  MultiScoreSyncInput({
    required this.qrCode,
    this.quickUpdate = false,
    required Set<SyncPlatform> platforms,
    Map<SyncPlatform, int> routes = const {},
    Map<SyncPlatform, RefreshDataRequest> refreshRequests = const {},
  })  : platforms = Set.unmodifiable(platforms),
        refreshRequests = Map.unmodifiable(refreshRequests),
        routes = Map.unmodifiable(routes);

  /// 旧调用未传线路时沿用原来的线路2行为。
  int routeOf(SyncPlatform platform) =>
      routes[platform] ?? SyncRouteStore.routeScoreHub;

  bool quickUpdateFor(SyncPlatform platform) =>
      quickUpdate &&
      (platform == SyncPlatform.awmc ||
          routeOf(platform) == SyncRouteStore.routeAwmc);
}

Future<MultiScoreSyncInput?> showMultiScoreSyncInputDialog(
        BuildContext context) =>
    showDialog<MultiScoreSyncInput>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MultiScoreSyncDialog(),
    );

/// 输入和保存凭据在对话框内完成，网络同步由调用方在弹窗关闭后串行执行。
class MultiScoreSyncDialog extends StatefulWidget {
  const MultiScoreSyncDialog({super.key});

  @override
  State<MultiScoreSyncDialog> createState() => _MultiScoreSyncDialogState();
}

class _MultiScoreSyncDialogState extends State<MultiScoreSyncDialog> {
  static const _keys = {
    SyncPlatform.divingFish: CacheKeyConstant.probeDivingFishImportToken,
    SyncPlatform.luoXue: CacheKeyConstant.probeLxnsImportToken,
    SyncPlatform.awmc: CacheKeyConstant.awmcNetImportToken,
  };
  static final _qqPattern = RegExp(r'^\d{5,12}$');
  final _qqController = TextEditingController();
  final _tokenControllers = {
    for (final platform in SyncPlatform.values)
      platform: TextEditingController(),
  };
  final _tokens = <SyncPlatform, String>{};
  final _selected = <SyncPlatform>{};
  final _expanded = <SyncPlatform>{};
  final _errors = <SyncPlatform, String>{};
  final _routes = <SyncPlatform, int>{
    SyncPlatform.divingFish: SyncRouteStore.routeScoreHub,
    SyncPlatform.luoXue: SyncRouteStore.routeScoreHub,
  };
  String _qq = '';
  String? _selectionError;
  String? _loadError;
  bool _loading = true;
  bool _submitting = false;
  final _refreshKeys = {
    for (final platform in SyncPlatform.values)
      platform: GlobalKey<PostSyncRefreshOptionsState>(),
  };
  bool _quickUpdate = false;
  int _quickRevision = 0;
  final _routesBeforeQuick = <SyncPlatform, int>{};
  Set<SyncPlatform> get _quickPlatforms => _selected
      .where((platform) =>
          platform == SyncPlatform.awmc ||
          _routes[platform] == SyncRouteStore.routeAwmc)
      .toSet();
  SyncPlatform? _saving;

  void _setQuickUpdate(bool enabled) {
    if (_quickUpdate == enabled &&
        (!enabled ||
            _routes.values
                .every((route) => route == SyncRouteStore.routeAwmc))) {
      return;
    }
    setState(() {
      if (enabled) {
        _routesBeforeQuick
          ..clear()
          ..addAll(_routes);
        _routes.updateAll((_, __) => SyncRouteStore.routeAwmc);
      } else if (_routesBeforeQuick.isNotEmpty) {
        _routes
          ..clear()
          ..addAll(_routesBeforeQuick);
        _routesBeforeQuick.clear();
      }
      _quickUpdate = enabled;
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
    for (final controller in _tokenControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _ready(SyncPlatform platform) =>
      (_tokens[platform]?.isNotEmpty ?? false) &&
      (platform != SyncPlatform.awmc || _qqPattern.hasMatch(_qq));

  Future<void> _loadCredentials() async {
    try {
      final tokens = <SyncPlatform, String>{};
      for (final platform in SyncPlatform.values) {
        tokens[platform] =
            (await SecureCredentialStore.read(_keys[platform]!) ?? '').trim();
      }
      final accounts = await AccountStore.loadAll();
      final prefs = await SharedPreferences.getInstance();
      final routes = {
        SyncPlatform.divingFish: await SyncRouteStore.load(isDivingFish: true),
        SyncPlatform.luoXue: await SyncRouteStore.load(isDivingFish: false),
      };
      final marker = prefs.getString(CacheKeyConstant.awmcUserId) ?? '';
      // 只读取 AWMC 自己的 QQ，不能用活动槽 cachedQQ（可能属于水鱼或落雪）。
      final qqCandidates = [
        accounts['awmc']?.id ?? '',
        marker.startsWith('awmc:') ? marker.substring(5) : '',
        prefs.getString(CacheKeyConstant.awmcNetSyncQQ) ?? '',
      ];
      if (!mounted) return;
      setState(() {
        _tokens.addAll(tokens);
        _routes.addAll(routes);
        _qq = qqCandidates.map((value) => value.trim()).firstWhere(
              _qqPattern.hasMatch,
              orElse: () => '',
            );
        _selected.addAll(SyncPlatform.values.where(_ready));
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

  Future<void> _saveCredential(SyncPlatform platform) async {
    if (_saving != null) return;
    final needsToken = _tokens[platform]?.isNotEmpty != true;
    final token = needsToken
        ? _tokenControllers[platform]!.text.trim()
        : _tokens[platform]!;
    final needsQQ = platform == SyncPlatform.awmc && !_qqPattern.hasMatch(_qq);
    final qq = needsQQ ? _qqController.text.trim() : _qq;
    if (token.isEmpty || (needsQQ && !_qqPattern.hasMatch(qq))) {
      setState(() => _errors[platform] = token.isEmpty
          ? context.l10n.flowEnterP0((platform == SyncPlatform.luoXue
                  ? context.l10n.flowPersonalAPIKey
                  : 'ImportToken')
              .toString())
          : context.l10n.flowEnterA512DigitQQID);
      return;
    }
    setState(() {
      _saving = platform;
      _errors.remove(platform);
    });
    try {
      if (needsToken)
        await SecureCredentialStore.write(_keys[platform]!, token);
      if (needsQQ) {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setString(CacheKeyConstant.awmcNetSyncQQ, qq)) {
          throw StateError(context.l10n.flowCouldNotSaveQQID);
        }
      }
      if (!mounted) return;
      setState(() {
        _tokens[platform] = token;
        if (needsQQ) _qq = qq;
        _selected.add(platform);
        _expanded.remove(platform);
        _selectionError = null;
        _tokenControllers[platform]!.clear();
        if (needsQQ) _qqController.clear();
      });
    } catch (_) {
      // 存储插件的异常可能包含传入参数，不向 UI 回显任何密钥。
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
    final requests = <SyncPlatform, RefreshDataRequest>{};
    for (final platform in targets) {
      final request =
          await _refreshKeys[platform]?.currentState?.collectRequest();
      if (!mounted) return;
      if (request != null) requests[platform] = request;
    }
    Navigator.pop(
        context,
        MultiScoreSyncInput(
          // 普通同步的二维码改为执行时逐个目标询问：一张二维码只能处理
          // 一个请求，不能在这里提前收集后复用给多个目标。
          qrCode: '',
          quickUpdate: _quickUpdate,
          platforms: targets,
          routes: _routes,
          refreshRequests: requests,
        ));
  }

  Widget _buildRouteSelector(SyncPlatform platform) {
    final scheme = Theme.of(context).colorScheme;
    final route = _quickUpdate ? SyncRouteStore.routeAwmc : _routes[platform]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedChoiceBar<int>(
            values: const [
              SyncRouteStore.routeAwmc,
              SyncRouteStore.routeScoreHub
            ],
            value: route,
            label: (value) => value == SyncRouteStore.routeAwmc
                ? context.l10n.flowRoute1
                : context.l10n.flowRoute2,
            onChanged: !_quickUpdate && _saving == null
                ? (next) {
                    setState(() {
                      _routes[platform] = next;
                      _quickRevision++;
                    });
                    unawaited(
                        SyncRouteNotifier.instance.setRoute(platform, next));
                  }
                : null,
          ),
          const SizedBox(height: 6),
          FadeContent(
              child: Text(
            key: ValueKey(route),
            context.l10n.flowCurrentP0P1(
                (route == SyncRouteStore.routeAwmc
                        ? context.l10n.flowRoute1
                        : context.l10n.flowRoute2)
                    .toString(),
                (SyncRouteStore.routeName(route)).toString()),
            style: TextStyle(fontSize: 12, color: scheme.primary),
          )),
          AnimatedReveal(
              visible: _quickUpdate,
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(context.l10n.flowQuickSyncAlwaysUsesRoute1,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
              )),
        ],
      ),
    );
  }

  Widget _status(String label, bool exists) => StatusChip(
        done: exists,
        text:
            '$label · ${exists ? context.l10n.flowAvailable : context.l10n.flowMissing}',
      );

  Widget _buildSource(SyncPlatform platform) {
    final scheme = Theme.of(context).colorScheme;
    final hasToken = _tokens[platform]?.isNotEmpty ?? false;
    final ready = _ready(platform);
    final tokenLabel = platform == SyncPlatform.luoXue
        ? context.l10n.flowPersonalAPIKey
        : 'ImportToken';
    final saving = _saving == platform;
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
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              _status(tokenLabel, hasToken),
              if (platform == SyncPlatform.awmc)
                _status(context.l10n.flowQQID, _qqPattern.hasMatch(_qq)),
            ]),
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
        if (platform != SyncPlatform.awmc) _buildRouteSelector(platform),
        if (_selected.contains(platform))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.l10n.flowRefreshDataAfterSync,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                PostSyncRefreshOptions(
                    key: _refreshKeys[platform],
                    source: AwmcQuickSyncService.sourceOf(platform),
                    showHeader: false),
              ],
            ),
          ),
        if (!ready)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.flowFillInCredentialsToSelectThisSource,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              TextButton.icon(
                onPressed: _saving == null
                    ? () => setState(() => _expanded.contains(platform)
                        ? _expanded.remove(platform)
                        : _expanded.add(platform))
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
                      SyncPlatform.divingFish =>
                        context.l10n.flowGetYourImportTokenFromTheDivingFish,
                      SyncPlatform.luoXue =>
                        context.l10n.flowSignInToLXNSAndGetYour,
                      SyncPlatform.awmc =>
                        context.l10n.flowEnterTheQQLinkedToAWMCNET,
                    },
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
                TextButton(
                    onPressed: () => _openSource(platform),
                    child: Text(context.l10n.flowOpenWebsite)),
                if (platform == SyncPlatform.awmc &&
                    !_qqPattern.hasMatch(_qq)) ...[
                  TextField(
                    key: const ValueKey('multi-sync-qq'),
                    controller: _qqController,
                    enabled: _saving == null,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: context.l10n.flowAWMCNETQQID,
                    ).insetLabel(context),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!hasToken)
                  TextField(
                    key: ValueKey('multi-sync-token-${platform.key}'),
                    controller: _tokenControllers[platform],
                    enabled: _saving == null,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: tokenLabel,
                    ).insetLabel(context),
                  ),
                if (_errors[platform] != null)
                  Text(_errors[platform]!,
                      style: TextStyle(color: scheme.error)),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed:
                      _saving == null ? () => _saveCredential(platform) : null,
                  child: Text(saving
                      ? context.l10n.flowSaving
                      : context.l10n.flowSaveAndSelect),
                ),
              ],
            ]),
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
                        if (_quickPlatforms.isNotEmpty)
                          QuickSyncOption(
                            key: ValueKey(_quickRevision),
                            platforms: _quickPlatforms,
                            onChanged: _setQuickUpdate,
                          ),
                        AnimatedReveal(
                          visible: !_quickUpdate,
                          child: SyncNoticeCard(
                            icon: Icons.qr_code_2_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            child: Text(context
                                .l10n.flowNormalSyncRequiresANewCabinetQR),
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
                              child:
                                  Center(child: CircularProgressIndicator()))
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
