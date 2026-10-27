import 'package:flutter/material.dart';
import '../manager/LuoXue/CollectionsManager.dart';
import '../utils/AppTheme.dart';
import 'MarqueeText.dart';

/// 社区称号共用的底图与文字。收藏品查询页维持原来的展示方式。
class TrophyTitleBadge extends StatelessWidget {
  final String name;
  final String? color;
  final int? trophyId;

  /// 以底图原始宽度为基准，仅微调无需滚动的文字位置。
  final double staticTextOffsetY;
  const TrophyTitleBadge(
      {super.key,
      required this.name,
      this.color,
      this.trophyId,
      this.staticTextOffsetY = 0});

  static const _types = ['Normal', 'Bronze', 'Silver', 'Gold', 'Rainbow'];
  static Future<Map<int, String>>? _legacyColors;

  static String? _typeOf(String? value) {
    for (final type in _types) {
      if (type.toLowerCase() == value?.trim().toLowerCase()) return type;
    }
    return null;
  }

  /// 旧社区资料只有称号 ID，没有底色。复用收藏品缓存，每进程最多补读一次。
  static Future<Map<int, String>> _loadLegacyColors() async {
    try {
      final data = await CollectionsManager().fetchTrophiesCollections();
      return {
        for (final item in data?.trophies ?? [])
          if (_typeOf(item.color) case final String type) item.id: type
      };
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _typeOf(color);
    if (type != null || trophyId == null)
      return _badge(context, type ?? 'Normal');
    return FutureBuilder<Map<int, String>>(
      future: _legacyColors ??= _loadLegacyColors(),
      builder: (context, snapshot) =>
          _badge(context, snapshot.data?[trophyId] ?? 'Normal'),
    );
  }

  Widget _badge(BuildContext context, String type) => Semantics(
        label: name,
        child: Tooltip(
            message: name,
            child: ExcludeSemantics(child: LayoutBuilder(
              builder: (context, constraints) {
                final width =
                    constraints.hasBoundedWidth ? constraints.maxWidth : 276.0;
                final scale = width / 276;
                final style = AppTheme.font(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w700,
                        height: 1.2)
                    .copyWith(color: Colors.white, shadows: [
                  // 描边随文字一起滚动，保持五种底图上的可读性。
                  for (final offset in const [
                    Offset(-1, -1),
                    Offset(0, -1),
                    Offset(1, -1),
                    Offset(-1, 0),
                    Offset(1, 0),
                    Offset(-1, 1),
                    Offset(0, 1),
                    Offset(1, 1),
                  ])
                    Shadow(color: Colors.black, offset: offset * (0.8 * scale)),
                ]);
                var textTop = 1 * scale;
                if (staticTextOffsetY != 0) {
                  // 与 MarqueeText 使用相同样式和字体缩放，避免误判滚动状态。
                  final painter = TextPainter(
                    text: TextSpan(
                        text: name,
                        style: DefaultTextStyle.of(context).style.merge(style)),
                    textDirection: Directionality.of(context),
                    textScaler: MediaQuery.textScalerOf(context),
                    maxLines: 1,
                  )..layout();
                  if (painter.width <= width - 24 * scale) {
                    textTop += staticTextOffsetY * scale;
                  }
                  painter.dispose();
                }
                // 底图的主色条是 y=7..27；不将上下透明留白、阴影及彩虹装饰算入文字中心。
                // 滚动视口固定留在两端圆角以内，文字和描边均不能越界。
                return SizedBox(
                    width: width,
                    height: 36 * scale,
                    child: Stack(children: [
                      Positioned.fill(
                          child: Image.asset('assets/title/$type.png',
                              fit: BoxFit.fill, excludeFromSemantics: true)),
                      Positioned(
                          left: 12 * scale,
                          right: 12 * scale,
                          // 默认相对主色条中心略上移 2px，补偿中文字形的视觉重心。
                          // 裁剪框必须在 Center 外，避免静态文字把它收缩到单行高度。
                          top: textTop,
                          height: 28 * scale,
                          child: ClipRect(
                              child: Center(
                                  child:
                                      MarqueeText(text: name, style: style)))),
                    ]));
              },
            ))),
      );
}
