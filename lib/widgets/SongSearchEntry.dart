import '../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/SearchInteractionPreferences.dart';
import 'SongSearchOverlay.dart';

/// 乐曲查询与成绩历史共用的搜索入口，统一输入框、搜索按钮和展开交互。
class SongSearchEntry extends StatefulWidget {
  const SongSearchEntry({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.focusNode,
    this.titleOnly = false,
    this.fontSize,
    this.hintFontSize,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged, onSubmitted;
  final bool titleOnly;
  final double? fontSize, hintFontSize;

  @override
  State<SongSearchEntry> createState() => _SongSearchEntryState();
}

class _SongSearchEntryState extends State<SongSearchEntry> {
  final _fieldKey = GlobalKey();
  bool _overlayOpen = false;

  @override
  void initState() {
    super.initState();
    SearchInteractionPreferences.instance.load();
  }

  Future<void> _openOverlay() async {
    if (_overlayOpen) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final field = _fieldKey.currentContext?.findRenderObject();
    final overlay = navigator.overlay?.context.findRenderObject();
    if (field is! RenderBox || overlay is! RenderBox) return;
    final rect =
        field.localToGlobal(Offset.zero, ancestor: overlay) & field.size;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _overlayOpen = true);
    final route = SongSearchOverlay.route(
      sourceRect: rect,
      initialQuery: widget.controller.text,
      titleOnly: widget.titleOnly,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    try {
      final query = await navigator.push(route);
      if (mounted && query != null) {
        widget.controller.value = TextEditingValue(
            text: query,
            selection: TextSelection.collapsed(offset: query.length));
        widget.onSubmitted(query);
      }
      await route.completed;
    } finally {
      if (mounted) setState(() => _overlayOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: SearchInteractionPreferences.instance,
        builder: (context, _) {
          final usesOverlay = SearchInteractionPreferences.instance.usesOverlay;
          final colors = Theme.of(context).colorScheme;
          final fontSize =
              widget.fontSize ?? MediaQuery.sizeOf(context).width * .04;
          final border = OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
              borderSide: BorderSide.none);
          return Opacity(
            opacity: _overlayOpen ? 0 : 1,
            child: Row(key: _fieldKey, children: [
              Expanded(
                  child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                readOnly: usesOverlay,
                enableInteractiveSelection: !usesOverlay,
                canRequestFocus: !usesOverlay,
                showCursor: !usesOverlay,
                onTap: usesOverlay ? _openOverlay : null,
                onChanged: usesOverlay ? null : widget.onChanged,
                onSubmitted: usesOverlay ? null : widget.onSubmitted,
                textInputAction: TextInputAction.search,
                style: TextStyle(fontSize: fontSize),
                decoration: InputDecoration(
                    hintText: widget.titleOnly
                        ? context.featureText('只按歌名搜索')
                        : context.featureText('曲名、别名、ID、曲师、谱师、BPM'),
                    hintStyle: TextStyle(
                        fontSize: widget.hintFontSize ?? fontSize * .875),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 15),
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 20, color: colors.onSurfaceVariant),
                    // 有内容时清空，没内容时是搜索键（和键盘上的搜索同一个动作）。
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: widget.controller,
                      builder: (context, value, _) => value.text.isEmpty
                          ? IconButton(
                              tooltip: context.featureText('搜索'),
                              onPressed: () =>
                                  widget.onSubmitted(widget.controller.text),
                              icon: Icon(Icons.arrow_forward_rounded,
                                  size: 20, color: colors.onSurfaceVariant),
                            )
                          : IconButton(
                              tooltip: context.featureText('清空搜索'),
                              onPressed: () {
                                widget.controller.clear();
                                widget.onSubmitted('');
                              },
                              icon: Icon(Icons.close_rounded,
                                  size: 18, color: colors.onSurfaceVariant),
                            ),
                    ),
                    filled: true,
                    fillColor: AppSurfaces.card(context),
                    border: border,
                    enabledBorder: border),
              )),
            ]),
          );
        },
      );
}
