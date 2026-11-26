import '../utils/AppTaskActivity.dart';
import 'AnimatedReveal.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../service/AWMC/AwmcQuickIdentityStore.dart';
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../service/Sync/SyncStatsService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AccountBindingManager.dart' show StatusChip;
import 'NoRipple.dart';
import 'QrQuickFillButtons.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 各同步表单共用的快速同步选项。绑定安全机台身份后才允许开启。
class QuickSyncOption extends StatefulWidget {
  final Set<SyncPlatform> platforms;
  final ValueChanged<bool> onChanged;
  final int credentialRevision;
  const QuickSyncOption(
      {super.key,
      required this.platforms,
      required this.onChanged,
      this.credentialRevision = 0});
  @override
  State<QuickSyncOption> createState() => _QuickSyncOptionState();
}

class _QuickSyncOptionState extends State<QuickSyncOption> {
  bool _enabled = false;
  bool _ready = false;
  bool _loading = true;
  bool _deleting = false;
  bool _binding = false;

  /// 三个数据源共用的机台身份是否已缓存。
  bool _identity = false;

  /// 各数据源自身的阻塞原因（缺个人 Token / 账号等），与机台身份分开显示。
  List<String> _issues = const [];
  Set<SyncPlatform> _lastPlatforms = const {};
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _lastPlatforms = Set<SyncPlatform>.of(widget.platforms);
    _check();
  }

  @override
  void didUpdateWidget(covariant QuickSyncOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 拷贝一份已检查平台快照，避免调用方原地修改 Set 时 setEquals 误判未变化。
    if (!setEquals(_lastPlatforms, widget.platforms) ||
        oldWidget.credentialRevision != widget.credentialRevision) {
      _lastPlatforms = Set<SyncPlatform>.of(widget.platforms);
      _check();
    }
  }

  Future<void> _check() async {
    final request = ++_request;
    setState(() => _loading = true);
    final platforms = widget.platforms.toList();
    bool identity;
    try {
      identity = await AwmcQuickIdentityStore.read() != null;
    } catch (_) {
      identity = false;
    }
    final issues = await Future.wait(
        platforms.map(AwmcQuickSyncService.accountIssue));
    if (!mounted || request != _request) return;
    setState(() {
      _loading = false;
      _identity = identity;
      _issues = issues.whereType<String>().toSet().toList();
      _ready = platforms.isNotEmpty && identity && _issues.isEmpty;
      if (!_ready) _enabled = false;
    });
    widget.onChanged(_enabled);
  }

  void _toggle(bool value) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _enabled = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brightness = theme.brightness;
    final interactive = !_loading && !_deleting && _ready;
    final subtitleText = _loading
        ? context.l10n.flowCheckingCachedUserCredentials
        : widget.platforms.isEmpty
            ? context.l10n.flowChooseASyncSourceFirst
            : !_identity
                ? context.l10n.flowEnterAQRToLinkCabinetIdentity
                : _issues.isNotEmpty
                    ? _issues.first
                    : context.l10n.flowCabinetIdentityLinkedNoQRNeededThis;

    return NoRipple(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: AppSurfaces.card(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              side: BorderSide(
                color: _enabled && interactive
                    ? scheme.primary.withValues(alpha: 0.55)
                    : scheme.outlineVariant,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: interactive ? () => _toggle(!_enabled) : null,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                context.l10n.flowQuickSync,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                              if (!_loading)
                                StatusChip(
                                  done: _identity,
                                  text: _identity
                                      ? context.l10n.flowUserCredentialsCached
                                      : context
                                          .l10n.flowUserCredentialsNotCached,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitleText,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AppSwitch(
                      value: _enabled && !_loading,
                      onChanged: interactive ? _toggle : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 机台身份已绑定但多个数据源均缺自身凭据时，补充展示其余阻塞原因。
          if (!_loading && _identity && _issues.length > 1)
            for (final issue in _issues.skip(1))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 15,
                      color: AppColors.warningOrange(brightness),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        issue,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warningOrange(brightness),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          if (!_loading && !_identity && widget.platforms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _binding ? null : _bindIdentity,
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: Text(_binding
                    ? context.l10n.flowValidatingQRCode
                    : context.l10n.flowLinkCabinetIdentityUsingQR),
              ),
            ),
          AnimatedReveal(
            visible: _enabled,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.l10n.flowUpdatesAchievementAndDXScoresComboAnd,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (!_loading && _identity)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context
                          .l10n.flowAllThreeSourcesShareTheseCredentialsDeleting,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _deleting
                        ? null
                        : () async {
                            setState(() {
                              _deleting = true;
                              _enabled = false;
                            });
                            widget.onChanged(false);
                            try {
                              await AwmcQuickSyncService.forgetIdentity();
                            } catch (_) {
                              if (context.mounted) {
                                AppToast.show(
                                    context.l10n
                                        .flowCouldNotDeleteCredentialsTryAgain,
                                    tone: AppToastTone.error);
                              }
                            } finally {
                              if (mounted) {
                                await _check();
                                if (mounted) setState(() => _deleting = false);
                              }
                            }
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 34),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.flowDeleteUserCredentials,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _bindIdentity() async {
    setState(() => _binding = true);
    try {
      await showBindCabinetIdentityDialog(context);
      if (mounted) await _check();
    } finally {
      if (mounted) setState(() => _binding = false);
    }
  }
}

Future<void> showBindCabinetIdentityDialog(BuildContext context) =>
    AppTaskActivity.run(() => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _BindQuickIdentityDialog()));

class _BindQuickIdentityDialog extends StatefulWidget {
  const _BindQuickIdentityDialog();

  @override
  State<_BindQuickIdentityDialog> createState() =>
      _BindQuickIdentityDialogState();
}

class _BindQuickIdentityDialogState extends State<_BindQuickIdentityDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final value = _controller.text.trim();
    if (!value.startsWith('SGWCMAID') || value.length <= 20) {
      setState(
          () => _error = context.l10n.flowEnterAValidSGWCMAIDCabinetLoginQR);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await AwmcQuickSyncService.bindIdentityWithQr(value);
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      AppToast.show(context.l10n.flowCabinetIdentityCachedQuickSyncIsReady,
          tone: AppToastTone.success);
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted)
        setState(() => _error =
            context.l10n.flowCouldNotLinkCabinetIdentityP0(error.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: AppAlertDialog(
        title: Text(context.l10n.flowLinkCabinetIdentity),
        content: AbsorbPointer(
            absorbing: _saving,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.flowReadsOnlyUserIdForQuickSyncDoes),
                  const SizedBox(height: 12),
                  QrQuickFillButtons(
                    controller: _controller,
                    onFilled: () => setState(() => _error = null),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          context.l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID2,
                      errorText: _error,
                    ),
                  ),
                ],
              ),
            )),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: Text(context.l10n.featureCancel),
          ),
          FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving
                  ? context.l10n.flowValidatingQRCode
                  : context.l10n.flowVerifyAndSave)),
        ],
      ));
}
