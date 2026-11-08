import '../../widgets/AnimatedReveal.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../service/SyncStatsService.dart';
import '../../utils/AppTheme.dart';
import '../../utils/SecureCredentialStore.dart';
import '../../utils/ExternalLaunchUtil.dart';
import '../../widgets/SyncDialogUi.dart';
import '../../widgets/QuickSyncOption.dart';

import '../../widgets/SyncStatsFooter.dart';
import '../../widgets/PostSyncRefreshOptions.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/RefreshDataDialog.dart'
    show RefreshDataRequest, RefreshDataSource;

/// 用户在「同步成绩到 AWMC NET」对话框里填的两样东西。
class AwmcNetSyncInput {
  /// `SGWCMAID` 开头的机台登入二维码。
  final String qr;
  final bool quickUpdate;

  /// 用户在 net.wmc.pub 设置页生成的成绩导入 Token。
  final String importToken;
  final RefreshDataRequest? refreshRequest;

  const AwmcNetSyncInput(
      {required this.qr,
      required this.importToken,
      this.refreshRequest,
      this.quickUpdate = false});
}

/// 打开「同步成绩到 AWMC NET」的**输入对话框**，返回用户填的内容（取消 = null）。
///
/// ⚠️ 这个对话框**只收集输入、点「开始同步」立刻关闭**：真正的导入由
/// `AwmcNetSyncFlow.run` 在对话框关掉之后跑，30 多秒的等待进度显示在
/// **按钮上**（与「同步成绩到水鱼 / 落雪」的交互完全一致）。
///
/// 早先它自己在对话框里转圈 + 数秒（`已等待 N 秒`），用户只能盯着一个模态框
/// 干等，而且和另外两个同步入口的交互不一样 —— 这次统一成按钮进度。
Future<AwmcNetSyncInput?> showAwmcNetSyncInputDialog(BuildContext context) {
  return showDialog<AwmcNetSyncInput>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const SyncToAwmcNetPage(),
  );
}

/// 「同步成绩到 AWMC NET」的输入对话框：机台二维码 + 成绩导入 Token。
///
/// 与「同步成绩到落雪」(`UpdateLuoXueScorePage`) 同构：粘贴/扫描机台登入二维码 +
/// 一个需要用户先在官网生成的凭据，然后提交。
///
/// AWMC NET 特有的两点（都只是**说明**，进度已经不在这里显示了）：
///   1. 导入要等约 36 秒（对方要登机台拉一整套成绩），所以按钮上的进度文案
///      会逐秒递增 —— 只转圈的话 30 多秒不动会被当成卡死；
///   2. 结果是**覆盖式**的（以机台为准重写已有成绩），所以警告放在**操作前**。
class SyncToAwmcNetPage extends StatefulWidget {
  const SyncToAwmcNetPage({super.key});

  @override
  State<SyncToAwmcNetPage> createState() => _SyncToAwmcNetPageState();
}

class _SyncToAwmcNetPageState extends State<SyncToAwmcNetPage> {
  bool _quickUpdate = false;
  int _credentialRevision = 0;
  final TextEditingController _qrController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  /// 已保存的导入 Token（null = 还没设置）。
  String? _savedToken;
  bool _tokenChecked = false;
  final _refreshKey = GlobalKey<PostSyncRefreshOptionsState>();

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  void dispose() {
    _qrController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final token =
        await SecureCredentialStore.read(CacheKeyConstant.awmcNetImportToken);
    if (!mounted) return;
    setState(() {
      _savedToken = (token != null && token.isNotEmpty) ? token : null;
      _tokenChecked = true;
      _credentialRevision++;
    });
  }

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      AppToast.show(context.l10n.flowEnterYourAWMCNETScoreImportToken2,
          tone: AppToastTone.warning);
      return;
    }
    await SecureCredentialStore.write(
        CacheKeyConstant.awmcNetImportToken, token);
    if (!mounted) return;
    setState(() {
      _savedToken = token;
      _credentialRevision++;
      _tokenController.clear();
    });
    AppToast.show(context.l10n.flowImportTokenSaved);
  }

  Future<void> _clearToken() async {
    await SecureCredentialStore.delete(CacheKeyConstant.awmcNetImportToken);
    if (!mounted) return;
    setState(() {
      _savedToken = null;
      _quickUpdate = false;
      _credentialRevision++;
    });
  }

  /// 校验 + 落盘 Token，然后**把输入交回调用方并关闭对话框**。
  ///
  /// 这里刻意不发请求：等待进度要显示在按钮上，所以真正的导入由
  /// `AwmcNetSyncFlow.run` 在对话框关闭后跑。
  Future<void> _submit() async {
    final qr = _qrController.text.trim();
    if (!_quickUpdate && qr.isEmpty) {
      AppToast.show(context.l10n.flowPasteOrScanACabinetLoginQR,
          tone: AppToastTone.warning);
      return;
    }
    final token = _savedToken ?? _tokenController.text.trim();
    if (token.isEmpty) {
      AppToast.show(context.l10n.flowSetYourAWMCNETScoreImportToken,
          tone: AppToastTone.warning);
      return;
    }
    // 用户是直接在输入框里填的（没点保存）：顺手存下来，下次不用再填
    if (_savedToken == null) {
      await SecureCredentialStore.write(
          CacheKeyConstant.awmcNetImportToken, token);
    }
    final refreshRequest = await _refreshKey.currentState?.collectRequest();
    if (!mounted) return;
    Navigator.of(context).pop(AwmcNetSyncInput(
      qr: qr,
      importToken: token,
      refreshRequest: refreshRequest,
      quickUpdate: _quickUpdate,
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final scheme = Theme.of(context).colorScheme;

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

            // ── 导入 Token ──
            if (_tokenChecked)
              SyncDialogSection(
                icon: Icons.key_outlined,
                title: context.l10n.featureAccountManagement,
                child: _buildTokenSection(brightness, scheme),
              ),

            // 覆盖式写入这件事必须**在点开始之前**说：等导入完了再提醒就晚了
            AnimatedReveal(
                visible: !_quickUpdate,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildOverwriteWarning(brightness),
                )),

            SyncDialogSection(
              icon: Icons.refresh_rounded,
              title: context.l10n.flowRefreshDataAfterSync,
              caption: context.l10n
                  .flowRefreshAutomaticallyAfterUploadRefreshErrorsAre,
              child: PostSyncRefreshOptions(
                key: _refreshKey,
                source: RefreshDataSource.awmc,
                showHeader: false,
              ),
            ),

            // ── 近 100 次统计（所有使用者共享；点开看详情）──
            // 二维码直传没有线路可选，所以这里只有统计、没有线路切换器。
            const SizedBox(height: 12),
            const SyncStatsFooter(slot: (SyncLine.direct, SyncPlatform.awmc)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
        SyncStartButton(
          label: context.l10n.flowStartSync,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildTokenSection(Brightness brightness, ColorScheme scheme) {
    final hasToken = _savedToken != null;
    final accent = hasToken
        ? AppColors.successGreen(brightness)
        : AppColors.warningOrange(brightness);

    return SyncNoticeCard(
      icon: hasToken ? Icons.check_circle : Icons.vpn_key,
      color: accent,
      title: hasToken
          ? context.l10n.flowScoreImportTokenSet
          : context.l10n.flowSetAWMCNETScoreImportToken,
      trailing: hasToken
          ? TextButton(
              onPressed: _clearToken,
              child: Text(context.l10n.flowChange,
                  style: const TextStyle(fontSize: 12)),
            )
          : null,
      child: hasToken
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _howToGetToken(brightness),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tokenController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: context.l10n.flowPasteScoreImportToken,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saveToken,
                      child: Text(context.l10n.save,
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _howToGetToken(Brightness brightness) {
    final hintStyle =
        TextStyle(fontSize: 12, color: AppColors.greyHint(brightness));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.flowGenerateYourOwnTokenOnAWMCNET,
          style: hintStyle,
        ),
        const SizedBox(height: 4),
        Text(context.l10n.flow1OpenTheAWMCNETSettingsLink, style: hintStyle),
        Text(context.l10n.flow2ScrollToTheBottomAndGenerate, style: hintStyle),
        Text(context.l10n.flow3CopyTheTokenAndPasteIt, style: hintStyle),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openSettingsPage(),
          child: Text(
            ApiUrls.AwmcNetSettingsUrl,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverwriteWarning(Brightness brightness) {
    return SyncNoticeCard(
      icon: Icons.info_outline,
      color: AppColors.warningOrange(brightness),
      child: Text(
          context.l10n.flowCabinetScoresTakePriorityAndOverwriteMatching),
    );
  }

  /// 打开设置页（Token 在页面最底部生成）。
  ///
  /// 失败时给个 toast —— 之前这里是**静默** return 的，用户点了链接没反应
  /// 只会以为是 App 卡了。顺带兜一句路径，免得浏览器没打开时用户不知道去哪。
  Future<void> _openSettingsPage() async {
    final uri = Uri.parse(ApiUrls.AwmcNetSettingsUrl);
    try {
      if (await ExternalLaunchUtil.open(uri)) {
        return;
      }
    } catch (e) {
      debugPrint('打开 AWMC NET 设置页失败: $e');
    }
    if (!mounted) return;
    AppToast.show(
        context.l10n.flowCouldNotOpenABrowserVisitP0(
            (ApiUrls.AwmcNetSettingsUrl).toString()),
        tone: AppToastTone.warning);
  }
}
