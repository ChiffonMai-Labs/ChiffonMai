import 'package:flutter/material.dart';

/// 用原始指针事件响应短按、长按和划过，不依赖点击手势是否最终获胜。
class TouchSearchButton extends StatefulWidget {
  const TouchSearchButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<TouchSearchButton> createState() => _TouchSearchButtonState();
}

class _TouchSearchButtonState extends State<TouchSearchButton> {
  final _pointers = <int>{};
  bool _hovered = false;

  void _updatePointer(PointerEvent event, {bool released = false}) {
    final box = context.findRenderObject();
    final inside = box is RenderBox &&
        (Offset.zero & box.size).contains(event.localPosition);
    setState(() {
      if (released || !inside) {
        _pointers.remove(event.pointer);
      } else {
        _pointers.add(event.pointer);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _updatePointer,
        onPointerMove: _updatePointer,
        onPointerUp: (event) => _updatePointer(event, released: true),
        onPointerCancel: (event) => _updatePointer(event, released: true),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(
              _hovered || _pointers.isNotEmpty ? 12 : 24,
            ),
          ),
          child: IconButton(
            tooltip: '搜索',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: widget.onPressed,
            style: IconButton.styleFrom(
              foregroundColor: scheme.onPrimary,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.transparent,
            ),
            icon: const Icon(Icons.search),
          ),
        ),
      ),
    );
  }
}
