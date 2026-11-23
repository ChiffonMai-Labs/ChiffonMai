import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../service/AWMC/AwmcQrSyncService.dart';
import '../../service/AccountAuthorizationStore.dart';
import '../../service/SyncStatsService.dart';
import '../../utils/AppTheme.dart';
import '../../utils/ExternalLaunchUtil.dart';
import '../../widgets/AnimatedReveal.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/PostSyncRefreshOptions.dart';
import '../../widgets/QuickSyncOption.dart';
import '../../widgets/RefreshDataDialog.dart'
    show RefreshDataRequest, RefreshDataSource;
import '../../widgets/SyncDialogUi.dart';
import '../../widgets/SyncStatsFooter.dart';

/// 用户在「同步成绩到 AWMC NET」对话框里填的内容。
class AwmcNetSyncInput {
  /// `SGWCMAID` 开头的机台登入二维码。
  final String qr;
  final bool quickUpdate;

  /// 要同步的 AWMC NET 玩家 QQ（普通同步免导入 Token 路径使用）。
  final String qq;

  /// 可选旧版成绩导入 Token（仅快速同步或历史回退路径使用）。
  final String importToken;
  final RefreshDataRequest? refreshRequest;

  const AwmcNetSyncInput({
    required this.qr,
    this.qq = '',
    this.importToken = '',
    this.refreshRequest,
    this.quickUpdate = false,
  });
}

/// 打开「同步成绩到 AWMC NET」的**输入对话框**，返回用户填的内容（取消 = null）。
Future<AwmcNetSyncInput?> showAwmcNetSyncInputDialog(BuildContext context) {
  return showDialog<AwmcNetSyncInput>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SyncToAwmcNetPage(),
  );
}

/// 「同步成绩到 AWMC NET」的输入对话框：机台二维码 + 关联 QQ 号（免导入 Token）。
class SyncToAwmcNetPage extends StatefulWidget {
  const SyncToAwmcNetPage({super.key});

  @override
  State<SyncToAwmcNetPage> createState() => _SyncToAwmcNetPageState();
}

class _SyncToAwmcNetPageState extends State<SyncToAwmcNetPage> {
  bool _quickUpdate = false;
  int _credentialRevision = 0;
  bool _submitting = false;
  final TextEditingController _qrController = TextEditingController();
  final TextEditingController _qqController = TextEditingController();

  /// 已绑定/保存的 AWMC NET QQ（null = 还没设置）。
  String? _savedQq;
  bool _accountChecked = false;
  final _refreshKey = GlobalKey<PostSyncRefreshOptionsState>();

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _qrController.dispose();
    _qqController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final qq = await AwmcQrSyncService.resolveAwmcNetQq();
    if (!mounted) return;
    setState(() {
      _savedQq = qq;
      _accountChecked = true;
      _credentialRevision++;
    });
  }

  Future<void> _persistQq(String qq) async {
    await AccountAuthorizationStore.saveAwmcQQ(qq);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.awmcNetSyncQQ, qq);
  }

  Future<void> _saveQq() async {
    final qq = _qqController.text.trim();
    if (!AwmcQrSyncService.qqPattern.hasMatch(qq)) {
      AppToast.show(context.l10n.flowInvalidQQID512DigitsRequired,
          tone: AppToastTone.warning);
      return;
    }
    try {
      await _persistQq(qq);
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _savedQq = qq;
        _credentialRevision++;
        _qqController.clear();
      });
      AppToast.show(context.l10n.flowQQSaved);
    } catch (_) {
      if (mounted) {
        AppToast.show(context.l10n.flowCouldNotSaveQQID,
            tone: AppToastTone.error);
      }
    }
  }

  void _switchQq() {
    setState(() {
      _qqController.text = _savedQq ?? '';
      _savedQq = null;
      _credentialRevision++;
    });
  }

  /// 校验 + 落盘 QQ，然后把输入交回调用方并关闭对话框。
  Future<void> _submit() async {
    final route = ModalRoute.of(context);
    if (_submitting || route == null || !route.isCurrent) return;
    final qr = _qrController.text.trim();
    if (!_quickUpdate && qr.isEmpty) {
      AppToast.show(context.l10n.flowPasteOrScanACabinetLoginQR,
          tone: AppToastTone.warning);
      return;
    }
    if (!_quickUpdate && !qr.startsWith('SGWCMAID')) {
      AppToast.show(context.l10n.flowInvalidQRCodeUseALoginQR,
          tone: AppToastTone.warning);
      return;
    }
    final qq = _savedQq ?? _qqController.text.trim();
    if (!AwmcQrSyncService.qqPattern.hasMatch(qq)) {
      AppToast.show(context.l10n.flowEnterA512DigitQQID,
          tone: AppToastTone.warning);
      return;
    }
    setState(() => _submitting = true);
    try {
      if (_savedQq == null) {
        await _persistQq(qq);
      }
      final refreshRequest = await _refreshKey.currentState?.collectRequest();
      if (!mounted || !route.isCurrent) return;
      route.navigator!.pop(AwmcNetSyncInput(
        qr: qr,
        qq: qq,
        refreshRequest: refreshRequest,
        quickUpdate: _quickUpdate,
      ));
    } catch (_) {
      if (mounted && route.isCurrent) {
        AppToast.show(context.l10n.flowCouldNotSaveCredentialsTryAgain,
            tone: AppToastTone.error);
      }
    } finally {
      if (mounted && route.isActive) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return AppAlertDialog(
      title: Text(context.l10n.featureSyncToAWMCNET),
      subtitle: context.l10n.featureImportScoresToAWMCNETUsingA,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SyncDialogSection(
              first: true,
              icon: Icons.bolt_rounded,
              title: context.l10n.syncDialogMode,
              child: QuickSyncOption(
                platforms: const {SyncPlatform.awmc},
                credentialRevision: _credentialRevision,
                onChanged: (enabled) => setState(() => _quickUpdate = enabled),
              ),
            ),
            AnimatedReveal(
              visible: !_quickUpdate,
              child: SyncDialogSection(
                icon: Icons.qr_code_2_rounded,
                title: context.l10n.syncDialogQrCode,
                caption: context.l10n.flowRequestAndOpenALoginQRIn,
                child: SyncQrInput(
                  controller: _qrController,
                  hintText: context.l10n.flowMaimaiDXCHUNITHMLoginQRSGWCMAID3,
                ),
              ),
            ),

            // ── 关联 QQ 账号（普通同步与快速更新均免导入 Token） ──
            if (_accountChecked)
              SyncDialogSection(
                icon: Icons.person_outline_rounded,
                title: context.l10n.accountBindingAwmc,
                child: _buildAccountSection(brightness),
              ),

            // 覆盖式写入必须在点开始之前说明
            AnimatedReveal(
                visible: !_quickUpdate,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildOverwriteWarning(brightness),
                )),

            SyncDialogSection(
              icon: Icons.refresh_rounded,
              title: context.l10n.flowRefreshDataAfterSync,
              caption: context
                  .l10n.flowRefreshAutomaticallyAfterUploadRefreshErrorsAre,
              child: PostSyncRefreshOptions(
                key: _refreshKey,
                source: RefreshDataSource.awmc,
                showHeader: false,
              ),
            ),

            const SizedBox(height: 12),
            const SyncStatsFooter(slot: (SyncLine.direct, SyncPlatform.awmc)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final route = ModalRoute.of(context);
            if (route != null && route.isCurrent) route.navigator!.pop();
          },
          child: Text(context.l10n.featureCancel),
        ),
        SyncStartButton(
          label: context.l10n.flowStartSync,
          onPressed: _submitting ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildAccountSection(Brightness brightness) {
    final hasQq = _savedQq != null;
    final accent = hasQq
        ? AppColors.successGreen(brightness)
        : AppColors.warningOrange(brightness);

    return SyncNoticeCard(
      icon: hasQq ? Icons.check_circle : Icons.person_outline,
      color: accent,
      title: hasQq
          ? context.l10n.flowAWMCNETQQBoundP0(_savedQq!)
          : context.l10n.flowEnterAWMCNETQQNoTokenTitle,
      trailing: hasQq
          ? TextButton(
              onPressed: _switchQq,
              child: Text(context.l10n.flowChange,
                  style: const TextStyle(fontSize: 12)),
            )
          : null,
      child: hasQq
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.flowAWMCNETQQNoTokenHint,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.greyHint(brightness)),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _openAwmcNetHome,
                  child: Text(
                    ApiUrls.AwmcNetBaseUrl,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _qqController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          hintText: context.l10n.flowAWMCNETQQID,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveQq,
                      child: Text(context.l10n.save,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildOverwriteWarning(Brightness brightness) {
    return SyncNoticeCard(
      icon: Icons.info_outline,
      color: AppColors.warningOrange(brightness),
      child:
          Text(context.l10n.flowCabinetScoresTakePriorityAndOverwriteMatching),
    );
  }

  Future<void> _openAwmcNetHome() async {
    final uri = Uri.parse(ApiUrls.AwmcNetBaseUrl);
    try {
      if (await ExternalLaunchUtil.open(uri)) return;
    } catch (e) {
      debugPrint('打开 AWMC NET 官网失败: $e');
    }
    if (!mounted) return;
    AppToast.show(
        context.l10n.flowCouldNotOpenABrowserVisitP0(
            (ApiUrls.AwmcNetBaseUrl).toString()),
        tone: AppToastTone.warning);
  }
}
