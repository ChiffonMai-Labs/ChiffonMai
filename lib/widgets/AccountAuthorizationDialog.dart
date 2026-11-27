import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constant/CacheKeyConstant.dart';
import '../l10n/LocalizationsExtension.dart';
import '../manager/LuoXue/LuoXueOAuthManager.dart';
import '../manager/LuoXue/LuoXueUserPlayDataManager.dart';
import '../service/AWMC/AwmcQrSyncService.dart';
import '../service/Account/AccountAuthorizationStore.dart';
import '../utils/AppTaskActivity.dart';
import '../utils/AppTheme.dart';
import '../utils/ExternalLaunchUtil.dart';
import 'AppDialogs.dart';
import 'AppToast.dart';
import 'AppUi.dart';
import 'RefreshDataDialog.dart' show launchUrlFallback;

/// 账号授权/绑定对话框的操作结果。
class AccountAuthorizationResult {
  /// 本次是否在对话框内新保存了有效的授权或绑定信息。
  final bool saved;

  /// 打开前处于无或未成功状态，且本次新保存变为成功状态时为 true。
  final bool becameSuccessful;

  /// AWMC NET 绑定的 QQ 号（落雪场景为空）。
  final String awmcQQ;

  const AccountAuthorizationResult({
    required this.saved,
    required this.becameSuccessful,
    required this.awmcQQ,
  });
}

/// 账号配置只保存授权或查询账号，刷新由独立入口执行。
Future<AccountAuthorizationResult> showAccountAuthorizationDialog(
  BuildContext context, {
  required bool luoxue,
}) =>
    AppTaskActivity.run<AccountAuthorizationResult>(() async {
      final qq = luoxue ? '' : await AccountAuthorizationStore.awmcQQ();
      final authorized = luoxue && await LuoXueOAuthManager().isLoggedIn();
      if (!context.mounted) {
        return const AccountAuthorizationResult(
          saved: false,
          becameSuccessful: false,
          awmcQQ: '',
        );
      }
      final hadBefore =
          luoxue ? authorized : RegExp(r'^\d{5,12}$').hasMatch(qq);
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _AccountAuthorizationDialog(
          luoxue: luoxue,
          initialQQ: qq,
          authorized: authorized,
        ),
      );
      final saved = result != null && result.isNotEmpty;
      final becameSuccessful = saved && !hadBefore;
      final savedAwmcQQ = !luoxue && saved ? result : qq;
      if (luoxue && becameSuccessful && context.mounted) {
        await maybeOfferReverseMigrationToLuoXue(context);
      }
      return AccountAuthorizationResult(
        saved: saved,
        becameSuccessful: becameSuccessful,
        awmcQQ: savedAwmcQQ,
      );
    });

/// 若用户已绑定 AWMC NET，首次完成落雪授权后可选一次性将 AWMC NET 成绩迁入落雪。
Future<void> maybeOfferReverseMigrationToLuoXue(BuildContext context) async {
  try {
    final awmcQq = await AwmcQrSyncService.resolveAwmcNetQq();
    if (awmcQq == null || !AwmcQrSyncService.qqPattern.hasMatch(awmcQq)) return;
    final prefs = await SharedPreferences.getInstance();
    final prompted =
        prefs.getStringList(CacheKeyConstant.proberReverseMigrationPrompted) ??
            const <String>[];
    final key = 'lx:$awmcQq';
    if (prompted.contains(key)) return;
    await prefs.setStringList(
      CacheKeyConstant.proberReverseMigrationPrompted,
      [...prompted, key],
    );
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: const Text('同步已有成绩到落雪？'),
        content: const Text(
          '检测到你已绑定 AWMC NET，是否将 AWMC NET 上已有的成绩一次性迁移至刚授权的落雪账号？（不会消耗机台二维码）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('暂不'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('立即迁移'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    AppToast.show('正在从 AWMC NET 迁移成绩至落雪…');
    final res = await AwmcQrSyncService.migrateAwmcToLuoXue(awmcQq: awmcQq);
    if (!context.mounted) return;
    if (res.ok) {
      AppToast.show(
        '已迁移 ${res.totalRecords} 条成绩到落雪'
        '${res.skipped > 0 ? '（跳过 ${res.skipped} 条）' : ''}',
        tone: AppToastTone.success,
      );
    } else {
      AppToast.show(
        res.message ?? '迁移至落雪失败',
        tone: AppToastTone.error,
      );
    }
  } catch (_) {}
}

/// 若用户已绑定 AWMC NET，首次完成水鱼写入授权后可选一次性将 AWMC NET 成绩迁入水鱼。
Future<void> maybeOfferReverseMigrationToFish(
  BuildContext context, {
  required String fishQq,
}) async {
  try {
    final awmcQq = await AwmcQrSyncService.resolveAwmcNetQq();
    if (awmcQq == null || !AwmcQrSyncService.qqPattern.hasMatch(awmcQq)) return;
    final prefs = await SharedPreferences.getInstance();
    final prompted =
        prefs.getStringList(CacheKeyConstant.proberReverseMigrationPrompted) ??
            const <String>[];
    final key = 'fish:$fishQq';
    if (prompted.contains(key)) return;
    await prefs.setStringList(
      CacheKeyConstant.proberReverseMigrationPrompted,
      [...prompted, key],
    );
    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: const Text('同步已有成绩到水鱼？'),
        content: const Text(
          '检测到你已绑定 AWMC NET，是否将 AWMC NET 上已有的成绩一次性迁移至刚授权的水鱼账号？（不会消耗机台二维码）',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('暂不'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('立即迁移'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    AppToast.show('正在从 AWMC NET 迁移成绩至水鱼…');
    final res = await AwmcQrSyncService.migrateAwmcToFish(
      awmcQq: awmcQq,
      fishQq: fishQq,
    );
    if (!context.mounted) return;
    if (res.ok) {
      AppToast.show(
        '已迁移 ${res.totalRecords} 条成绩到水鱼'
        '${res.skipped > 0 ? '（跳过 ${res.skipped} 条）' : ''}',
        tone: AppToastTone.success,
      );
    } else {
      AppToast.show(
        res.message ?? '迁移至水鱼失败',
        tone: AppToastTone.error,
      );
    }
  } catch (_) {}
}

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
  bool _initializingProfile = false;
  String? _boundFishQq;
  bool _hasLxAuth = false;
  late final bool _hasSavedLuoXueToken = widget.authorized;
  @override
  void initState() {
    super.initState();
    awmcQqController.text = widget.initialQQ;
    if (!widget.luoxue) {
      _loadExternalSources();
    }
  }

  Future<void> _loadExternalSources() async {
    try {
      final fishQq = await AwmcQrSyncService.resolveDivingFishQq();
      final lxAuth = await AwmcQrSyncService.hasLuoXueSyncAuth();
      if (!mounted) return;
      setState(() {
        _boundFishQq = fishQq;
        _hasLxAuth = lxAuth;
      });
    } catch (_) {}
  }

  Future<void> _initAwmcFromExternal({required bool fromFish}) async {
    if (_saving || _initializingProfile) return;
    final qq = awmcQqController.text.trim();
    if (!RegExp(r'^\d{5,12}$').hasMatch(qq)) {
      AppToast.show(context.l10n.flowInvalidQQID512DigitsRequired);
      return;
    }
    setState(() {
      _saving = true;
      _initializingProfile = true;
    });
    try {
      await AccountAuthorizationStore.saveAwmcQQ(qq);
      final res = fromFish
          ? await AwmcQrSyncService.initAwmcProfileFromFish(
              awmcQq: qq,
              fishQq: _boundFishQq!,
            )
          : await AwmcQrSyncService.initAwmcProfileFromLuoXue(awmcQq: qq);
      if (!mounted) return;
      if (res.ok) {
        AppToast.show(
          '已用${fromFish ? '水鱼' : '落雪'}成绩初始化 AWMC NET 档案（${res.totalRecords} 条）',
          tone: AppToastTone.success,
        );
        Navigator.of(context).pop<String?>(qq);
      } else {
        AppToast.show(
          res.message ?? '初始化 AWMC NET 档案失败',
          tone: AppToastTone.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _initializingProfile = false;
        });
      }
    }
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
      if (_hasSavedLuoXueToken) {
        Navigator.of(context).pop<String?>('');
      } else {
        AppToast.show(context.l10n.flowEnterYourLXNSAuthorizationCodeFirst);
      }
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
      Navigator.of(context).pop<String?>(widget.luoxue ? 'ok' : value);
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
                '${context.l10n.flowAWMCNETIsAThirdPartyScore}\n支持直接扫码同步自动建档，也可直接使用已绑定的水鱼/落雪成绩一键初始化档案。',
                style: TextStyle(
                    fontSize: 12, color: AppColors.greyHint(brightness)),
              ),
              if (_boundFishQq != null || _hasLxAuth) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_boundFishQq != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: Text(
                          _initializingProfile ? '正在初始化…' : '用水鱼成绩初始化档案',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onPressed: _saving
                            ? null
                            : () => _initAwmcFromExternal(fromFish: true),
                      ),
                    if (_hasLxAuth)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sync_alt, size: 16),
                        label: Text(
                          _initializingProfile ? '正在初始化…' : '用落雪成绩初始化档案',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                        ),
                        onPressed: _saving
                            ? null
                            : () => _initAwmcFromExternal(fromFish: false),
                      ),
                  ],
                ),
              ],
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
