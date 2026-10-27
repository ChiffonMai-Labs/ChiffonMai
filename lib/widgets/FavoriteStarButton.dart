import 'package:flutter/material.dart';

/// 星标按钮：仅 UI，点击行为由父组件通过 onTap 控制。
///
/// 收藏状态切换时，只有星星本身有动画：点亮是**从星星中心向四周铺开**的
/// 圆形擦除（像灯从中间亮起来），取消收藏则反向收回中心。外层 tile / 卡片不受影响。
class FavoriteStarButton extends StatefulWidget {
  final bool isFavorited;
  final VoidCallback onTap;
  final double size;

  const FavoriteStarButton({
    super.key,
    this.size = 22,
    required this.isFavorited,
    required this.onTap,
  });

  @override
  State<FavoriteStarButton> createState() => _FavoriteStarButtonState();
}

class _FavoriteStarButtonState extends State<FavoriteStarButton>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 320);

  /// 0 = 完全空心（未收藏），1 = 整颗点亮（已收藏）。
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
    value: widget.isFavorited ? 1 : 0,
  );

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
  }

  @override
  void didUpdateWidget(FavoriteStarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorited == oldWidget.isFavorited) return;
    final target = widget.isFavorited ? 1.0 : 0.0;
    if (_reduceMotion) {
      _controller.value = target;
      return;
    }
    // 收藏：从中心向外点亮；取消：反向收回中心。
    _controller.animateTo(target, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildStar({required Color fill, required Color border}) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: StarBorder(
            innerRadiusRatio: 0.48,
            pointRounding: 0.16,
            valleyRounding: 0,
            side: BorderSide(width: 1.6, color: border),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outlineStar =
        _buildStar(fill: Colors.transparent, border: scheme.onSurfaceVariant);
    final litStar = _buildStar(fill: Colors.amber, border: Colors.amber);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Semantics(
            label: widget.isFavorited ? '取消收藏' : '收藏功能',
            toggled: widget.isFavorited,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final reveal = _controller.value;
                return SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 空心描边始终在底层，点亮过程中被逐渐覆盖。
                      outlineStar,
                      if (reveal > 0)
                        ClipPath(
                          clipper: _CenterRevealClipper(reveal),
                          child: litStar,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 以星星中心为圆心的圆形裁剪：progress 从 0 长到 1 时，
/// 半径从 0 扩到足够盖住整颗星，形成「从中间点亮」的擦除效果。
class _CenterRevealClipper extends CustomClipper<Path> {
  const _CenterRevealClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    // 星形外角落在边长一半的内切圆上，再多给一点余量盖住描边抗锯齿。
    final maxRadius = size.shortestSide / 2 + 1.5;
    return Path()
      ..addOval(Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: maxRadius * progress.clamp(0.0, 1.0),
      ));
  }

  @override
  bool shouldReclip(_CenterRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}
