import 'dart:async';

import 'package:flutter/material.dart';

import '../service/SongSearchHistoryStore.dart';
import 'TouchSearchButton.dart';
import 'SearchOverlaySurface.dart';

/// 从原输入框展开的临时搜索层。
class SongSearchOverlay extends StatefulWidget {
  const SongSearchOverlay._({
    required this.animation,
    required this.sourceRect,
    required this.initialQuery,
    required this.titleOnly,
    this.hintText,
    this.historyStore,
    this.queryResultsBuilder,
  });

  final Animation<double> animation;
  final Rect sourceRect;
  final String initialQuery;
  final bool titleOnly;
  final String? hintText;
  final SongSearchHistoryStore? historyStore;
  final Widget Function(BuildContext, String, VoidCallback)?
      queryResultsBuilder;

  static PageRouteBuilder<String> route({
    required Rect sourceRect,
    required String initialQuery,
    required bool titleOnly,
    required bool reduceMotion,
    String? hintText,
    SongSearchHistoryStore? historyStore,
    Widget Function(BuildContext, String, VoidCallback)? queryResultsBuilder,
  }) {
    return PageRouteBuilder<String>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
      reverseTransitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) =>
          SongSearchOverlay._(
        animation: animation,
        sourceRect: sourceRect,
        initialQuery: initialQuery,
        titleOnly: titleOnly,
        hintText: hintText,
        historyStore: historyStore,
        queryResultsBuilder: queryResultsBuilder,
      ),
    );
  }

  @override
  State<SongSearchOverlay> createState() => _SongSearchOverlayState();
}

class _SongSearchOverlayState extends State<SongSearchOverlay> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  late final SongSearchHistoryStore _historyStore;
  List<String> _history = [];
  bool _loadingHistory = true;
  bool _closing = false;
  bool _requestedFocus = false;
  int _historyRevision = 0;

  @override
  void initState() {
    super.initState();
    _historyStore = widget.historyStore ?? SongSearchHistoryStore();
    _controller = TextEditingController.fromValue(TextEditingValue(
      text: widget.initialQuery,
      selection: TextSelection.collapsed(offset: widget.initialQuery.length),
    ));
    widget.animation.addStatusListener(_onAnimationStatus);
    // 展开后再弹键盘，避免输入法动画与输入框展开互相挤压。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onAnimationStatus(widget.animation.status);
    });
    unawaited(_loadHistory());
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_closing && !_requestedFocus) {
      _requestedFocus = true;
      _focusNode.requestFocus();
    } else if (status == AnimationStatus.reverse) {
      if (!_closing) setState(() => _closing = true);
      _focusNode.unfocus();
    }
  }

  Future<void> _loadHistory() async {
    final revision = _historyRevision;
    try {
      final items = await _historyStore.load();
      if (!mounted || revision != _historyRevision) return;
      setState(() => _history = items);
    } catch (error) {
      debugPrint('读取搜索历史失败: $error');
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _changeHistory({String? remove, bool clear = false}) async {
    final revision = ++_historyRevision;
    final previous = List<String>.of(_history);
    setState(() {
      _history = clear ? [] : _history.where((item) => item != remove).toList();
    });
    try {
      final items = clear
          ? await _historyStore.clear()
          : await _historyStore.remove(remove!);
      if (mounted && revision == _historyRevision) {
        setState(() => _history = items);
      }
    } catch (error) {
      if (!mounted || revision != _historyRevision) return;
      // 写盘失败时重新读取，避免回滚掉随后已完成的删除操作。
      try {
        final items = await _historyStore.load();
        if (mounted && revision == _historyRevision) {
          setState(() => _history = items);
        }
      } catch (_) {
        if (mounted && revision == _historyRevision) {
          setState(() => _history = previous);
        }
      }
      if (mounted && !_closing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('搜索历史更新失败，请重试')),
        );
      }
    }
  }

  void _close({bool submit = true, String? query}) {
    if (_closing) return;
    setState(() => _closing = true);
    final result = submit ? (query ?? _controller.text).trim() : null;
    if (result != null) {
      _controller.value = TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length),
      );
    }
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_onAnimationStatus);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchOverlaySurface(
      animation: widget.animation,
      sourceRect: widget.sourceRect,
      closing: _closing,
      input: _buildInput(),
      onBackgroundTap: () => _close(),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        builder: (context, value, _) {
          final query = value.text.trim();
          if (query.isNotEmpty && widget.queryResultsBuilder != null) {
            return widget.queryResultsBuilder!(context, query, () => _close());
          }
          return _buildHistory();
        },
      ),
    );
  }

  Widget _buildInput() {
    final colors = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (query) => _close(query: query),
            style: TextStyle(fontSize: screenWidth * .04),
            decoration: InputDecoration(
              hintText: widget.hintText ??
                  (widget.titleOnly ? '只按歌名搜索' : '歌名/BPM/谱师/曲师/别名/歌曲ID/...'),
              hintStyle: TextStyle(fontSize: screenWidth * .035),
              prefixIcon: IconButton(
                tooltip: '收起搜索',
                onPressed: () => _close(submit: false),
                icon: const Icon(Icons.arrow_back),
              ),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: '清除输入',
                        onPressed: _controller.clear,
                        icon: const Icon(Icons.close, size: 20),
                      ),
              ),
              filled: true,
              fillColor: colors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TouchSearchButton(
          onPressed: () => _close(),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              const Expanded(child: Text('搜索历史')),
              if (_history.isNotEmpty)
                TextButton(
                  onPressed: () => _changeHistory(clear: true),
                  child: const Text('清空'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_history.isEmpty)
            Text(
              _loadingHistory ? '正在读取搜索历史…' : '暂无搜索历史',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          else
            for (final query in _history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.history_rounded, color: colors.onSurfaceVariant),
                title: Text(query,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  tooltip: '删除这条搜索历史',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _changeHistory(remove: query),
                ),
                onTap: () => _close(query: query),
              ),
        ],
      ),
    );
  }
}
