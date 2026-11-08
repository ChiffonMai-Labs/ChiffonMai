import '../utils/AppTaskActivity.dart';
import 'AnimatedReveal.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../service/AWMC/AwmcQuickIdentityStore.dart';
import '../service/AWMC/AwmcQuickSyncService.dart';
import '../service/SyncStatsService.dart';
import '../utils/AppTheme.dart';
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
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void didUpdateWidget(covariant QuickSyncOption oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.platforms, widget.platforms) ||
        oldWidget.credentialRevision != widget.credentialRevision) _check();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    return NoRipple(
        child: SwitchTheme(
      data: theme.switchTheme.copyWith(
          overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.flowQuickSync),
            subtitle: Text(_loading
                ? context.l10n.flowCheckingCachedUserCredentials
                : widget.platforms.isEmpty
                    ? context.l10n.flowChooseASyncSourceFirst
                    : !_identity
                        ? context.l10n.flowEnterAQRToLinkCabinetIdentity
                        : _issues.isNotEmpty
                            ? _issues.first
                            : context.l10n
                                .flowCabinetIdentityLinkedNoQRNeededThis),
            value: _enabled && !_loading,
            onChanged: _loading || _deleting || !_ready
                ? null
                : (value) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _enabled = value);
                    widget.onChanged(value);
                  },
          ),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(
                    _identity
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    size: 16,
                    color: _identity
                        ? AppColors.successGreen(brightness)
                        : AppColors.errorRed(brightness)),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        _identity
                            ? context.l10n.flowUserCredentialsCached
                            : context.l10n.flowUserCredentialsNotCached,
                        style: TextStyle(
                            fontSize: 12,
                            color: _identity
                                ? AppColors.successGreen(brightness)
                                : AppColors.errorRed(brightness)))),
              ]),
            ),
          // 机台身份已绑定但数据源自身未就绪：如实说明缺什么，不再要求重新扫码。
          if (!_loading && _identity)
            for (final issue in _issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.warningOrange(brightness)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(issue,
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.warningOrange(brightness)))),
                ]),
              ),
          if (!_loading && !_identity && widget.platforms.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _binding ? null : _bindIdentity,
                icon: const Icon(Icons.qr_code_2, size: 18),
                label: Text(_binding
                    ? context.l10n.flowValidatingQRCode
                    : context.l10n.flowLinkCabinetIdentityUsingQR),
              ),
            ),
          AnimatedReveal(
              visible: _enabled,
              child: Text(
                  context.l10n.flowUpdatesAchievementAndDXScoresComboAnd,
                  style: Theme.of(context).textTheme.bodySmall)),
          if (!_loading && _identity)
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
                        if (context.mounted)
                          AppToast.show(
                              context
                                  .l10n.flowCouldNotDeleteCredentialsTryAgain,
                              tone: AppToastTone.error);
                      } finally {
                        if (mounted) {
                          await _check();
                          if (mounted) setState(() => _deleting = false);
                        }
                      }
                    },
              child: Text(context.l10n.flowDeleteUserCredentials),
            ),
          if (!_loading && _identity)
            Text(context.l10n.flowAllThreeSourcesShareTheseCredentialsDeleting,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    ));
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
      if (!mounted) return;
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
