import 'package:flutter/material.dart';

import '../utils/SearchInteractionPreferences.dart';
import 'SongSearchOverlay.dart';
import 'TouchSearchButton.dart';

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
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.outlineVariant));
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
                        ? '只按歌名搜索'
                        : '歌名/BPM/谱师/曲师/别名/歌曲ID/...',
                    hintStyle: TextStyle(
                        fontSize: widget.hintFontSize ?? fontSize * .875),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: colors.surfaceContainerLow,
                    border: border,
                    enabledBorder: border),
              )),
              const SizedBox(width: 8),
              TouchSearchButton(
                  onPressed: () => widget.onSubmitted(widget.controller.text)),
            ]),
          );
        },
      );
}
