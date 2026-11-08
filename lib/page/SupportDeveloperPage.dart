import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/AppTheme.dart';
import '../utils/ExternalLaunchUtil.dart';
import '../utils/ExportPathUtil.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 支持开发者页面：展示赞赏码与爱发电链接。
class SupportDeveloperPage extends StatefulWidget {
  const SupportDeveloperPage({super.key});

  @override
  State<SupportDeveloperPage> createState() => _SupportDeveloperPageState();
}

class _SupportDeveloperPageState extends State<SupportDeveloperPage> {
  static const String _afdianUrl = 'https://ifdian.net/a/chiffonmai/plan';
  bool _saving = false;

  Future<void> _downloadCode() async {
    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '图片', title: context.l10n.flowChooseWhereToSaveTheSupportQR)) {
      return;
    }
    setState(() => _saving = true);
    try {
      final data = await rootBundle.load('assets/qrcode/zanshangma.jpg');
      String? fallback;
      final file = await ExportPathUtil.writeExportFile(
          fileName: 'ChiffonMai_微信赞赏码.jpg',
          bytes:
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          subDir: '图片',
          onFallback: (path) => fallback = path);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (ctx) => AppAlertDialog(
                  title:  Text(context.l10n.flowSupportQRCodeSaved),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(file.path),
                        if (fallback != null) ...[
                          const SizedBox(height: 12),
                          Text(context.l10n.flowThePublicDirectoryIsNotWritableSaved2,
                              style: TextStyle(
                                  color: AppColors.warningOrange(
                                      Theme.of(ctx).brightness)))
                        ],
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child:  Text(context.l10n.featureGotIt))
                  ]));
    } catch (e) {
      if (mounted)
        AppToast.show(context.l10n.flowSaveFailedP0((e).toString()), tone: AppToastTone.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAfdian() async {
    final uri = Uri.parse(_afdianUrl);
    try {
      if (await ExternalLaunchUtil.open(uri)) {
        return;
      } else {
        _launchUrlFallback(_afdianUrl);
      }
    } catch (e) {
      debugPrint('打开爱发电链接失败: $e');
      _launchUrlFallback(_afdianUrl);
    }
  }

  void _launchUrlFallback(String url) {
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      AppToast.show(context.l10n.flowCouldNotOpenABrowserLinkCopied2, duration: const Duration(seconds: 3), actionLabel: context.l10n.featureGotIt, onAction: () {}, tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: context.l10n.featureSupportDevelopment,
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
            AppDesignTokens.gutter, AppDesignTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 开场卡片
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusLarge),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.onPrimary.withValues(alpha: 0.16),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                    ),
                    child: Icon(Icons.favorite_rounded,
                        color: scheme.onPrimary, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.l10n.flowChiffonMaiIsAFreeOpenSourceTool,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            // 微信赞赏码
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   AppSectionHeader(
                    title: context.l10n.flowWeChatSupportQRCode,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        // 二维码要白底才好扫，深色模式也一样
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusMedium),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/qrcode/zanshangma.jpg',
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _downloadCode,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(_saving ? context.l10n.flowSaving : context.l10n.flowDownloadQRImage),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.cardGap),
            // 爱发电
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   AppSectionHeader(
                    title: context.l10n.flowOrSupportMeOnAfdian,
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  FilledButton.icon(
                    onPressed: _openAfdian,
                    icon: const Icon(Icons.favorite),
                    label:  Text(context.l10n.flowOpenAfdian),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.flowYourSupportKeepsDevelopmentAndMaintenanceGoing,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
