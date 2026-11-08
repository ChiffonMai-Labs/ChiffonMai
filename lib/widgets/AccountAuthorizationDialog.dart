import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/LocalizationsExtension.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../manager/LuoXue/LuoXueUserPlayDataManager.dart';
import '../service/AccountAuthorizationStore.dart';
import '../utils/AppTaskActivity.dart';
import '../utils/AppTheme.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'AppDialogs.dart';
import 'AppToast.dart';
import 'AppUi.dart';
import 'RefreshDataDialog.dart' show launchUrlFallback;

/// 账号配置只保存授权或查询账号，刷新由独立入口执行。
Future<void> showAccountAuthorizationDialog(BuildContext context,
        {required bool luoxue}) =>
    AppTaskActivity.run(() async {
      final qq = luoxue ? '' : await AccountAuthorizationStore.awmcQQ();
      final authorized = luoxue && await LuoXueOAuthManager().isLoggedIn();
      if (!context.mounted) return;
      await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _AccountAuthorizationDialog(
              luoxue: luoxue, initialQQ: qq, authorized: authorized));
    });

class _AccountAuthorizationDialog extends StatefulWidget {
  const _AccountAuthorizationDialog(
      {required this.luoxue,
      required this.initialQQ,
      required this.authorized});
  final bool luoxue;
  final String initialQQ;
  final bool authorized;
  @override
  State<_AccountAuthorizationDialog> createState() =>
      _AccountAuthorizationDialogState();
}

class _AccountAuthorizationDialogState
    extends State<_AccountAuthorizationDialog> {
  final authCodeController = TextEditingController();
  final awmcQqController = TextEditingController();
  bool _saving = false;
  late final bool _hasSavedLuoXueToken = widget.authorized;
  @override
  void initState() {
    super.initState();
    awmcQqController.text = widget.initialQQ;
  }

  @override
  void dispose() {
    authCodeController.dispose();
    awmcQqController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final value =
        (widget.luoxue ? authCodeController : awmcQqController).text.trim();
    if (widget.luoxue && value.isEmpty) {
      if (_hasSavedLuoXueToken)
        Navigator.of(context).pop();
      else
        AppToast.show(context.l10n.flowEnterYourLXNSAuthorizationCodeFirst);
      return;
    }
    if (!widget.luoxue && !RegExp(r'^\d{5,12}$').hasMatch(value)) {
      AppToast.show(context.l10n.flowInvalidQQID512DigitsRequired);
      return;
    }
    final failureMessage = context.l10n.accountAuthorizationFailed;
    setState(() => _saving = true);
    try {
      if (widget.luoxue) {
        final token = await LuoXueOAuthManager().exchangeCodeForToken(value);
        if (token == null) throw StateError(failureMessage);
      } else {
        await AccountAuthorizationStore.saveAwmcQQ(value);
      }
      if (!mounted) return;
      AppToast.show(context.l10n.accountConfigurationSaved,
          tone: AppToastTone.success);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted)
        AppToast.show(context.l10n.accountAuthorizationFailed,
            tone: AppToastTone.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_saving,
      child: AppAlertDialog(
        title: Text(widget.luoxue
            ? context.l10n.accountAuthorizeLXNS
            : context.l10n.accountLinkAWMC),
        content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
                child: AbsorbPointer(
                    absorbing: _saving,
                    child: widget.luoxue
                        ? _buildLuoXuePanel(Theme.of(context).brightness)
                        : _buildAwmcPanel(Theme.of(context).brightness)))),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
              child: Text(context.l10n.featureCancel)),
          FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                  _saving ? context.l10n.flowLoading2 : context.l10n.save)),
        ],
      ));

  Widget _buildLuoXuePanel(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasSavedLuoXueToken)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
                context.l10n.flowLXNSAuthorizationSavedItRenewsAutomaticallyNo,
                style: TextStyle(color: AppColors.successGreen(brightness))),
          ),
        ElevatedButton(
          onPressed: () async {
            final url = LuoXueUserPlayDataManager().getAuthorizationUrl();
            try {
              if (await ExternalLaunchUtil.openString(url)) {
                return;
              } else {
                if (!mounted) return;
                launchUrlFallback(url, context);
              }
            } catch (e) {
              debugPrint('打开落雪授权链接失败: $e');
              if (!mounted) return;
              launchUrlFallback(url, context);
            }
          },
          child: Text(context.l10n.flowAuthorize2),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningOrange(brightness).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color:
                    AppColors.warningOrange(brightness).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.warningOrange(brightness)),
                  const SizedBox(width: 6),
                  Text(context.l10n.flowAuthorizationButtonNotWorking,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warningOrange(brightness))),
                ],
              ),
              const SizedBox(height: 6),
              Text(context.l10n.flowCopyThisLinkAndOpenItManually,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.greyHint(brightness))),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: Text(context.l10n.flowCopyAuthorizationLink,
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () {
                  final url = LuoXueUserPlayDataManager().getAuthorizationUrl();
                  Clipboard.setData(ClipboardData(text: url));
                  AppToast.show(
                      context.l10n.flowAuthorizationLinkCopiedPasteItIntoYour,
                      tone: AppToastTone.warning);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(context.l10n.flowAfterAuthorizingCopyTheCodeShownOn,
            style:
                TextStyle(fontSize: 12, color: AppColors.greyHint(brightness))),
        const SizedBox(height: 8),
        TextField(
          controller: authCodeController,
          decoration: InputDecoration(
            labelText: context.l10n.flowEnterAuthorizationCode,
            hintText: context.l10n.flowPasteAuthorizationCode,
          ).insetLabel(context),
        ),
      ],
    );
  }

  Widget _buildAwmcPanel(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: awmcQqController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: context.l10n.flowQQID,
            hintText: context.l10n.flowEnterAQQIDAlreadyLinkedOn,
          ).insetLabel(context),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.linkBlue(brightness).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.linkBlue(brightness).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.linkBlue(brightness)),
                  const SizedBox(width: 6),
                  Text(context.l10n.flowNoSignInNeeded,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.linkBlue(brightness))),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.flowAWMCNETIsAThirdPartyScore,
                style: TextStyle(
                    fontSize: 12, color: AppColors.greyHint(brightness)),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(context.l10n.flowLinkQQUploadScoresOnAWMCNET,
                    style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () async {
                  const url = 'https://net.wmc.pub/';
                  try {
                    if (await ExternalLaunchUtil.openString(url)) {
                      return;
                    }
                  } catch (e) {
                    debugPrint('打开 AWMC NET 失败: $e');
                  }
                  if (!mounted) return;
                  launchUrlFallback(url, context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
