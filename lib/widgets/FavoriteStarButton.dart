import 'package:flutter/material.dart';

/// 星标按钮：仅 UI，点击行为由父组件通过 onTap 控制
class FavoriteStarButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Semantics(
            label: isFavorited ? '取消收藏' : '收藏功能',
            toggled: isFavorited,
            child: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 480),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation.drive(
                  Tween<double>(begin: 0.0, end: 1.0).chain(
                    CurveTween(curve: Curves.easeInOutCubic),
                  ),
                ),
                child: RotationTransition(
                  turns: animation.drive(
                    Tween(begin: -0.04, end: 0.0).chain(
                      CurveTween(curve: Curves.easeOutCubic),
                    ),
                  ),
                  child: ScaleTransition(
                    scale: animation.drive(
                      Tween(begin: 0.78, end: 1.0).chain(
                        CurveTween(curve: Curves.easeOutBack),
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
              child: SizedBox(
                key: ValueKey(isFavorited),
                width: size,
                height: size,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: isFavorited ? Colors.amber : Colors.transparent,
                    shape: StarBorder(
                      innerRadiusRatio: 0.48,
                      pointRounding: 0.16,
                      valleyRounding: 0,
                      side: BorderSide(
                        width: 1.6,
                        color: isFavorited
                            ? Colors.amber
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
