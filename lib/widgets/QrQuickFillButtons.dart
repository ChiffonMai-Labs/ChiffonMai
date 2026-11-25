import 'package:flutter/cupertino.dart' as ios;
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'AppHeader.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppError.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

/// 二维码「快速填入」三件套：读取剪贴板 / 从相册识别 / 扫描二维码。
///
/// 为什么要有这个组件：这套代码原来在 `SyncScoreDialogs`、`HomePage`、
/// `UpdateLuoXueScorePage` 里**各抄了一份**（3 份按钮实现 + 2 份扫码页），
/// 口径还不一致——「同步成绩到落雪」甚至只有剪贴板一个按钮，用户得先
/// 把二维码存到相册再手打。统一到这里之后，任何二维码输入框只要放一个
/// [QrQuickFillButtons] 就三件套齐全。
///
/// 用法（对话框里的输入框）：
/// ```dart
/// QrQuickFillButtons(
///   controller: qrController,
///   onFilled: () => setState(() => error = null), // 可选：填入后清旧的错误提示
/// )
/// ```
///
/// 约定：填入的字符串一律 `trim()`；识别失败/剪贴板为空只弹 toast，
/// 不改动输入框里已有的内容。
class QrQuickFillButtons extends StatelessWidget {
  /// 目标输入框控制器（由调用方持有，组件只负责写值）。
  final TextEditingController controller;

  /// 成功填入后的回调（例如清掉上次提交的红字错误）。
  final VoidCallback? onFilled;

  /// 置 false 时三个按钮都禁用（例如写入请求正在进行中）。
  final bool enabled;

  final double spacing;
  final double runSpacing;

  /// 对话框内使用紧凑单行等宽排布，避免折行参差不齐。
  final bool compact;

  const QrQuickFillButtons({
    super.key,
    required this.controller,
    this.onFilled,
    this.enabled = true,
    this.spacing = 8,
    this.runSpacing = 8,
    this.compact = false,
  });

  /// 只提取官方链接路径中的凭据，不向剪贴板里的地址发请求。
  static String? gameCode(String value) {
    final text = value.trim();
    if (RegExp(r'^SGWCMAID[0-9A-Za-z]{13,504}$').hasMatch(text)) return text;
    final url = Uri.tryParse(text);
    if (url == null ||
        !{'http', 'https'}.contains(url.scheme) ||
        url.host != 'wq.wahlap.net') return null;
    final match = RegExp(
            r'^/qrcode/(?:img/(MAID[A-Z0-9]{20,160})\.png|req/(MAID[A-Z0-9]{20,160})\.html)$',
            caseSensitive: false)
        .firstMatch(url.path);
    return match == null
        ? null
        : 'SGWC${(match[1] ?? match[2])!.toUpperCase()}';
  }

  void _fill(String text) {
    controller.text = gameCode(text) ?? text.trim();
    onFilled?.call();
  }

  Future<void> _fromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!context.mounted) return;
    final text = data?.text ?? '';
    if (gameCode(text) != null) {
      _fill(text);
      AppToast.show(context.l10n.flowValidQRStringDetectedAndFilledIn,
          tone: AppToastTone.success);
      return;
    }
    if (text.trim().isEmpty) {
      AppToast.show(context.l10n.flowClipboardIsEmpty);
      return;
    }
    // 不是标准二维码串：让用户自己确认，避免把乱七八糟的内容填进去
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(context.l10n.featureNotice),
        content: Text(context.l10n.flowClipboardContentIsNotAValidLogin),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.featureCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.flowFillIn),
          ),
        ],
      ),
    );
    if (context.mounted && confirmed == true) _fill(text);
  }

  Future<void> _fromGallery(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxWidth: 2560,
        maxHeight: 2560,
      );
      if (!context.mounted || pickedFile == null) return;

      // 用 mobile_scanner 离线解析图片里的二维码
      final scanner = MobileScannerController();
      try {
        final barcodes = await scanner.analyzeImage(pickedFile.path);
        if (!context.mounted) return;
        if (barcodes == null || barcodes.barcodes.isEmpty) {
          AppToast.show(context.l10n.flowNoQRCodeFoundInTheImage,
              tone: AppToastTone.warning);
          return;
        }
        final qrText = barcodes.barcodes.first.rawValue ?? '';
        if (qrText.isEmpty) {
          AppToast.showError(
            AppError(
              code: 'DATA-QR-DECODE',
              userMessage: context.l10n.flowCouldNotReadQRContentFromThe,
              stage: '识别相册二维码',
              retryable: false,
            ),
            stage: '识别相册二维码',
          );
          return;
        }
        _fill(qrText);
        AppToast.show(context.l10n.flowQRCodeDetectedAndFilledIn,
            tone: AppToastTone.success);
      } finally {
        scanner.dispose();
      }
    } catch (e, stack) {
      if (!context.mounted) return;
      AppToast.showError(e, stack: stack, stage: '识别相册二维码');
    }
  }

  Future<void> _fromCamera(BuildContext context) async {
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const QrScannerPage()),
      );
      if (!context.mounted || result == null || result.trim().isEmpty) return;
      _fill(result);
      AppToast.show(context.l10n.flowQRCodeDetectedAndFilledIn,
          tone: AppToastTone.success);
    } catch (e, stack) {
      if (!context.mounted) return;
      AppToast.showError(e, stack: stack, stage: '扫码识别二维码');
    }
  }

  Widget _button({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      onPressed: onPressed,
    );
  }

  Widget _compactButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppSurfaces.card(context),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 38),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: scheme.primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final options = [
        (
          ios.CupertinoIcons.doc_on_clipboard,
          context.l10n.flowReadClipboard,
          _fromClipboard
        ),
        (
          ios.CupertinoIcons.photo,
          context.l10n.flowReadFromGallery,
          _fromGallery
        ),
        (ios.CupertinoIcons.camera, context.l10n.flowScanQRCode, _fromCamera),
      ];
      return ios.CupertinoListSection.insetGrouped(
        topMargin: 0,
        margin: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        children: [
          for (final (icon, label, action) in options)
            ios.CupertinoListTile(
                leading: Icon(icon, size: 21),
                title: Text(label),
                trailing: const ios.CupertinoListTileChevron(),
                onTap: enabled ? () => action(context) : null),
        ],
      );
    }
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: _compactButton(
              context,
              icon: Icons.paste,
              label: context.l10n.flowReadClipboard,
              onPressed: enabled ? () => _fromClipboard(context) : null,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _compactButton(
              context,
              icon: Icons.photo_library,
              label: context.l10n.flowReadFromGallery,
              onPressed: enabled ? () => _fromGallery(context) : null,
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: _compactButton(
              context,
              icon: Icons.qr_code_scanner,
              label: context.l10n.flowScanQRCode,
              onPressed: enabled ? () => _fromCamera(context) : null,
            ),
          ),
        ],
      );
    }
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: [
        _button(
          icon: Icons.paste,
          label: context.l10n.flowReadClipboard,
          onPressed: enabled ? () => _fromClipboard(context) : null,
        ),
        _button(
          icon: Icons.photo_library,
          label: context.l10n.flowReadFromGallery,
          onPressed: enabled ? () => _fromGallery(context) : null,
        ),
        _button(
          icon: Icons.qr_code_scanner,
          label: context.l10n.flowScanQRCode,
          onPressed: enabled ? () => _fromCamera(context) : null,
        ),
      ],
    );
  }
}

/// 摄像头扫二维码页面：识别到内容就 pop 回字符串。
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool _hasPopped = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // 顶部栏统一走公共组件（标题 = 思源黑体 20 / bold / primary / 居中），
      // 避免 `Scaffold.appBar` 里裸 `Text` 被顶回系统 Roboto。
      // 这里是相机页，所以 bar 必须留在 `appBar` 槽里 —— 它和相机预览之间
      // 不能有别的 widget（AppHeader 放 body 的 Column 里也一样是 AppBar，
      // 只是相机预览要拿 `Expanded` 撑满剩余空间）。
      appBar: AppHeader(
        title: context.l10n.flowScanQRCode,
        barBackground: Theme.of(context).colorScheme.surface,
      ),
      body: MobileScanner(
        onDetect: (BarcodeCapture capture) {
          if (_hasPopped) return;
          final barcode = capture.barcodes.firstOrNull;
          if (barcode != null &&
              barcode.rawValue != null &&
              barcode.rawValue!.isNotEmpty) {
            _hasPopped = true;
            Navigator.pop(context, barcode.rawValue);
          }
        },
        errorBuilder: (context, error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(context.l10n.flowCameraErrorP0((error).toString())),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.flowBack),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
