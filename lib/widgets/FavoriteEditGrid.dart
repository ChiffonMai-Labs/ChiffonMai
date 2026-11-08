import '../l10n/LocalizationsExtension.dart';
import '../l10n/FeatureLocalizations.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import 'AppUi.dart';

class FavoriteEditItem {
  /// 收藏键，排序和移除都按它。
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  /// 显示的标题，默认是 [title]（「检查更新」发现新版本时会变）。
  final String? displayTitle;
  final Color? titleColor;
  final bool loading;
  final double? progress;

  const FavoriteEditItem({
    required this.title,
    required this.icon,
    this.onTap,
    this.displayTitle,
    this.titleColor,
    this.loading = false,
    this.progress,
  });
}

/// 首页「常用」：所有收藏都显示成图标。
///
/// 正常态和编辑态是同一棵树，切换时格子不重新入场，只有叉号和删除区域过渡。
/// 编辑态直接拖动图标换位置，点叉号或拖到删除区域移除。
///
/// 拖动时其它图标滑到新位置，松手才写盘。整个网格共用一个 [DragTarget]，
/// 落点按手指位置算，不会因为格子移动而来回抖动。
class FavoriteEditGrid extends StatefulWidget {
  final List<FavoriteEditItem> items;

  /// 是否处于编辑态。
  final bool editing;
  final ValueChanged<List<String>> onReorder;
  final ValueChanged<String> onRemove;

  const FavoriteEditGrid({
    super.key,
    required this.items,
    required this.editing,
    required this.onReorder,
    required this.onRemove,
  });

  @override
  State<FavoriteEditGrid> createState() => _FavoriteEditGridState();
}

class _FavoriteEditGridState extends State<FavoriteEditGrid> {
  static const double _gap = 8;

  late List<String> _order = [for (final item in widget.items) item.title];
  String? _dragging;
  bool _overDelete = false;

  Map<String, FavoriteEditItem> get _itemsByTitle =>
      {for (final item in widget.items) item.title: item};

  @override
  void didUpdateWidget(FavoriteEditGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragging != null) return;
    final next = [for (final item in widget.items) item.title];
    final current = next.toSet();
    // 保留本地顺序，只同步增删，写盘回来时不会闪回旧顺序。
    _order = [
      for (final title in _order)
        if (current.contains(title)) title,
      for (final title in next)
        if (!_order.contains(title)) title,
    ];
  }

  void _moveTo(int target) {
    final dragging = _dragging;
    if (dragging == null) return;
    final from = _order.indexOf(dragging);
    final to = target.clamp(0, _order.length - 1);
    if (from < 0 || from == to) return;
    setState(() {
      _order.removeAt(from);
      _order.insert(to, dragging);
    });
  }

  void _endDrag() {
    if (_dragging == null) return;
    setState(() {
      _dragging = null;
      _overDelete = false;
    });
    widget.onReorder(List<String>.of(_order));
  }

  void _remove(String title) {
    setState(() {
      _dragging = null;
      _overDelete = false;
      _order.remove(title);
    });
    widget.onRemove(title);
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsByTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 6 : 4;
          final cellWidth =
              (constraints.maxWidth - _gap * (columns - 1)) / columns;
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          // 图标 60 + 上下留白 + 两行标题，所有格子等高才能排成整齐的网格。
          final cellHeight = 80 + 34 * textScale;
          final rows = (_order.length / columns).ceil();
          final duration = AppDesignTokens.motion(
              context, const Duration(milliseconds: 220));
          return DragTarget<String>(
            onWillAcceptWithDetails: (_) => true,
            onMove: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box == null) return;
              final local = box.globalToLocal(details.offset);
              final col = ((local.dx + cellWidth / 2) / (cellWidth + _gap))
                  .floor()
                  .clamp(0, columns - 1);
              final row = ((local.dy + cellHeight / 2) / (cellHeight + _gap))
                  .floor()
                  .clamp(0, rows - 1);
              _moveTo(row * columns + col);
            },
            builder: (context, _, __) => SizedBox(
              height: rows * cellHeight + (rows - 1) * _gap,
              child: Stack(
                children: [
                  for (final title in _order)
                    if (items[title] case final item?)
                      AnimatedPositioned(
                        key: ValueKey(title),
                        duration: title == _dragging ? Duration.zero : duration,
                        curve: AppDesignTokens.emphasizedCurve,
                        left: (_order.indexOf(title) % columns) *
                            (cellWidth + _gap),
                        top: (_order.indexOf(title) ~/ columns) *
                            (cellHeight + _gap),
                        width: cellWidth,
                        height: cellHeight,
                        // 只在首次挂载时入场，切换编辑态不会重播。
                        child: EntranceAnimation(
                          index: _order.indexOf(title),
                          stagger: const Duration(milliseconds: 60),
                          baseDelay: const Duration(milliseconds: 200),
                          duration: const Duration(milliseconds: 500),
                          offset: const Offset(0, 12),
                          child: _buildCell(item, cellWidth, cellHeight),
                        ),
                      ),
                ],
              ),
            ),
          );
        }),
        AnimatedReveal(
          visible: widget.editing,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildDeleteZone(),
          ),
        ),
      ],
    );
  }

  Widget _buildCell(FavoriteEditItem item, double width, double height) {
    final scheme = Theme.of(context).colorScheme;
    final editing = widget.editing;
    Widget tile() => FeatureIconTile(
          title: item.title,
          displayTitle: context.featureText(item.displayTitle ?? item.title),
          icon: item.icon,
          loading: item.loading,
          progress: item.progress,
          titleColor: item.titleColor,
          // 编辑态点击不打开功能，也不显示成禁用。
          onTap: editing ? () {} : item.onTap,
        );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Draggable<String>(
            data: item.title,
            // 正常态不接管拖动，页面照常滚动。
            maxSimultaneousDrags: editing ? null : 0,
            onDragStarted: () => setState(() => _dragging = item.title),
            onDragEnd: (_) => _endDrag(),
            onDraggableCanceled: (_, __) => _endDrag(),
            feedback: SizedBox(
              width: width,
              height: height,
              child: Theme(
                data: Theme.of(context),
                child: Material(
                  type: MaterialType.transparency,
                  child: Transform.scale(scale: 1.08, child: tile()),
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: tile()),
            child: tile(),
          ),
        ),
        Positioned(
          top: 0,
          right: 2,
          // 叉号弹入 / 缩回，不让格子重新入场。
          child: IgnorePointer(
            ignoring: !editing || _dragging == item.title,
            child: AnimatedScale(
              scale: editing && _dragging != item.title ? 1 : 0,
              duration: AppDesignTokens.motion(
                  context, AppDesignTokens.mediumMotion),
              curve: AppDesignTokens.emphasizedCurve,
              child: Semantics(
              button: true,
              label: context.l10n.homeRemoveFavorite(context.featureText(item.title)),
              onTap: () => _remove(item.title),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _remove(item.title),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppSurfaces.card(context), width: 2),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 13, color: scheme.onError),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteZone() {
    final scheme = Theme.of(context).colorScheme;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.fastMotion);
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) {
        setState(() => _overDelete = true);
        return true;
      },
      onLeave: (_) => setState(() => _overDelete = false),
      onAcceptWithDetails: (details) => _remove(details.data),
      builder: (context, _, __) => AnimatedContainer(
        duration: duration,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _overDelete
              ? scheme.error.withValues(alpha: 0.18)
              : AppSurfaces.inset(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          border: Border.all(
            color: _dragging != null ? scheme.error : scheme.outlineVariant,
            width: _overDelete ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded,
                size: 20,
                color: _dragging != null
                    ? scheme.error
                    : scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              context.featureText(_overDelete ? '松手移除收藏' : '拖到这里移除收藏'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _dragging != null
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
