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
        subDir: '图片', title: '选择赞赏码保存位置')) {
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
                  title: const Text('赞赏码已保存'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(file.path),
                        if (fallback != null) ...[
                          const SizedBox(height: 12),
                          Text('公开目录不可写，已保存到应用文档目录。可通过分享或应用文件访问。',
                              style: TextStyle(
                                  color: AppColors.warningOrange(
                                      Theme.of(ctx).brightness)))
                        ],
                      ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('知道了'))
                  ]));
    } catch (e) {
      if (mounted)
        AppToast.show('保存失败：$e');
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
      AppToast.show('无法打开浏览器，链接已复制到剪贴板，请手动粘贴到浏览器打开', duration: const Duration(seconds: 3), actionLabel: '知道了', onAction: () {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: '支持开发者',
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
                      'ChiffonMai 是一款完全免费的开源工具，如果它帮到了你，欢迎支持开发者！',
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
                  const AppSectionHeader(
                    title: '微信赞赏码',
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
                    label: Text(_saving ? '正在保存…' : '下载赞赏码图片'),
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
                  const AppSectionHeader(
                    title: '或通过爱发电支持我',
                    padding: EdgeInsets.only(bottom: 12),
                  ),
                  FilledButton.icon(
                    onPressed: _openAfdian,
                    icon: const Icon(Icons.favorite),
                    label: const Text('前往爱发电'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '你的支持是我持续维护与开发的动力，感谢！❤️',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
