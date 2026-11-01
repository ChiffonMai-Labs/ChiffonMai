import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';

/// 等宽选项切换：背景滑动，文字颜色淡入淡出，状态仍由页面持有。
class AnimatedChoiceBar<T> extends StatelessWidget {
  final List<T> values;
  final T value;
  final String Function(T) label;
  final ValueChanged<T>? onChanged;
  final bool compact;
  final bool enableRipple;
  const AnimatedChoiceBar(
      {super.key,
      required this.values,
      required this.value,
      required this.label,
      required this.onChanged,
      this.compact = false,
      this.enableRipple = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // 与 SegmentedTabs 同一观感：凹槽底 + 白色滑块，深色下滑块改用容器色。
    final dark = theme.brightness == Brightness.dark;
    final thumbColor =
        dark ? scheme.secondaryContainer : AppSurfaces.card(context);
    final thumbText = dark ? scheme.onSecondaryContainer : scheme.onSurface;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final index = values.indexOf(value).clamp(0, values.length - 1);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : values.length * 82.0;
      return SizedBox(
          width: width,
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: AppSurfaces.track(context),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusMedium)),
              child: Stack(children: [
                AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeInOutCubic,
                    left: index * width / values.length + 3,
                    top: 3,
                    bottom: 3,
                    width: width / values.length - 6,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color: thumbColor,
                            borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusSmall)))),
                Row(children: [
                  for (final option in values)
                    Expanded(
                        child: Semantics(
                            selected: option == value,
                            button: true,
                            child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    splashFactory: enableRipple
                                        ? null
                                        : NoSplash.splashFactory,
                                    highlightColor: enableRipple
                                        ? null
                                        : Colors.transparent,
                                    onTap: onChanged == null
                                        ? null
                                        : () {
                                            if (option != value)
                                              onChanged!(option);
                                          },
                                    child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: compact ? 4 : 6,
                                            vertical: compact ? 6 : 12),
                                        child: AnimatedDefaultTextStyle(
                                            duration: duration,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge!
                                                .copyWith(
                                                    fontSize:
                                                        compact ? 11 : null,
                                                    color: option == value
                                                        ? thumbText
                                                        : scheme
                                                            .onSurfaceVariant,
                                                    fontWeight: option == value
                                                        ? FontWeight.bold
                                                        : FontWeight.w500),
                                            // 放不下时缩小，不截断选项名。
                                            child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(label(option),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1))))))))
                ]),
              ])));
    });
  }
}

/// 文案、图标和内容切换共用的淡化过渡。
class FadeContent extends StatelessWidget {
  final Widget child;
  const FadeContent({super.key, required this.child});
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child);
}
