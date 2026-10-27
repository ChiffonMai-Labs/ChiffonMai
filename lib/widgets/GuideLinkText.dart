import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../utils/AppTheme.dart';
import '../utils/ExternalLaunchUtil.dart';

/// 在引导段落内显示可换行的蓝色下划线链接，仅链接文字响应点击。
class GuideLinkText extends StatefulWidget {
  final String before;
  final String label;
  final String? url;
  final Future<void> Function()? onTap;
  final String after;
  final String? fallbackText;
  final String? fallbackMessage;
  final TextStyle? style;

  const GuideLinkText({
    super.key,
    this.before = '',
    required this.label,
    this.url,
    this.onTap,
    this.after = '',
    this.fallbackText,
    this.fallbackMessage,
    this.style,
  }) : assert(url != null || onTap != null);

  @override
  State<GuideLinkText> createState() => _GuideLinkTextState();
}

class _GuideLinkTextState extends State<GuideLinkText> {
  late final TapGestureRecognizer _tap;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _tap = TapGestureRecognizer()..onTap = _open;
  }

  Future<void> _open() async {
    if (_opening) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _opening = true;
    try {
      final action = widget.onTap;
      if (action != null) {
        await action();
        return;
      }
      final url = widget.url!;
      final fallback = widget.fallbackText ?? url;
      final message = widget.fallbackMessage;
      if (await ExternalLaunchUtil.openString(url) || !mounted) return;
      await ExternalLaunchUtil.copyFallback(context, fallback,
          message: message ?? '无法打开链接，链接已复制到剪贴板，请手动粘贴到浏览器打开');
    } finally {
      _opening = false;
    }
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blue = AppColors.linkBlue(Theme.of(context).brightness);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: widget.before),
        TextSpan(
          text: widget.label,
          style: TextStyle(
            color: blue,
            decoration: TextDecoration.underline,
            decorationColor: blue,
          ),
          recognizer: _tap,
          mouseCursor: SystemMouseCursors.click,
        ),
        TextSpan(text: widget.after),
      ]),
      style: widget.style,
    );
  }
}
