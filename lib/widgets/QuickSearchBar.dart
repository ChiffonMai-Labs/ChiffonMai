import '../l10n/FeatureLocalizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';

/// 功能搜索栏，可在首页或功能分类页复用。
class QuickSearchBar extends StatefulWidget {
  /// 搜索文本变化回调
  final ValueChanged<String> onChanged;
  final VoidCallback? onTap;
  final String? query;
  final EdgeInsetsGeometry padding;

  /// 输入框提示，默认「搜点什么...」。
  final String? hintText;

  const QuickSearchBar({
    super.key,
    required this.onChanged,
    this.onTap,
    this.query,
    this.padding = const EdgeInsets.only(bottom: 8),
    this.hintText,
  });

  @override
  State<QuickSearchBar> createState() => _QuickSearchBarState();
}

class _QuickSearchBarState extends State<QuickSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.query ?? '';
  }

  @override
  void didUpdateWidget(QuickSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final query = widget.query;
    if (query != null && query != _controller.text) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // 立即刷新清除按钮，实际筛选仍按短防抖后的值触发。
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      widget.onChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hintColor = scheme.onSurfaceVariant;
    final iconColor = scheme.primary;

    return Padding(
      padding: widget.padding,
      child: TextField(
        controller: _controller,
        onChanged: widget.onTap == null ? _onChanged : null,
        onTap: widget.onTap,
        readOnly: widget.onTap != null,
        canRequestFocus: widget.onTap == null,
        enableInteractiveSelection: widget.onTap == null,
        showCursor: widget.onTap == null ? null : false,
        style: TextStyle(
          fontSize: 15,
          color: scheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: context.featureText(widget.hintText ?? '搜点什么...'),
          hintStyle: TextStyle(color: hintColor, fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded, color: hintColor, size: 20),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  tooltip: context.featureText('清空'),
                  icon: Icon(Icons.close_rounded, color: hintColor, size: 18),
                  onPressed: () {
                    _debounceTimer?.cancel();
                    _controller.clear();
                    setState(() {});
                    widget.onChanged('');
                  },
                )
              : null,
          // B 方案：白底、无描边、16 圆角；聚焦时才出现主题色描边。
          filled: true,
          fillColor: AppSurfaces.card(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            borderSide: BorderSide(color: iconColor, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        ),
      ),
    );
  }
}
