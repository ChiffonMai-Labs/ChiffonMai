import 'package:flutter/cupertino.dart' as ios;
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';

/// 等宽选项切换：背景滑动，文字颜色淡入淡出，状态仍由页面持有。
class AnimatedChoiceBar<T extends Object> extends StatelessWidget {
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
    if (theme.platform == TargetPlatform.iOS && values.length > 1) {
      return LayoutBuilder(
          builder: (context, constraints) => SizedBox(
                width:
                    constraints.hasBoundedWidth ? constraints.maxWidth : null,
                child: ios.CupertinoSlidingSegmentedControl<T>(
                  groupValue: value,
                  disabledChildren: onChanged == null ? values.toSet() : <T>{},
                  onValueChanged: (selected) {
                    if (selected != null && selected != value)
                      onChanged?.call(selected);
                  },
                  children: {
                    for (final option in values)
                      option: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: compact ? 2 : 6),
                        child: Text(label(option),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: compact ? 12 : 14,
                                color: scheme.onSurface)),
                      ),
                  },
                ),
              ));
    }
    // 与 SegmentedTabs 同一观感：凹槽底 + 白色滑块，深色下滑块改用容器色。
    final dark = theme.brightness == Brightness.dark;
    final thumbColor =
        dark ? scheme.secondaryContainer : AppSurfaces.card(context);
    final thumbText = dark ? scheme.onSecondaryContainer : scheme.onSurface;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final index = values.indexOf(value).clamp(0, values.length - 1);
    return RepaintBoundary(
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : values.length * 82.0;
        final baseLabelStyle = theme.textTheme.labelLarge!;
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
                      child: RepaintBoundary(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                color: thumbColor,
                                borderRadius: BorderRadius.circular(
                                    AppDesignTokens.radiusSmall))),
                      )),
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
                                          // 仅对颜色做过渡，避免可变字体字重逐帧插值触发文本重排与字形缓存抖动。
                                          child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: TweenAnimationBuilder<
                                                  Color?>(
                                                tween: ColorTween(
                                                  end: option == value
                                                      ? thumbText
                                                      : scheme
                                                          .onSurfaceVariant,
                                                ),
                                                duration: duration,
                                                curve: Curves.easeInOutCubic,
                                                builder: (context, color, _) {
                                                  final selected =
                                                      option == value;
                                                  final targetWeight = selected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500;
                                                  return Text(
                                                    label(option),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    style: baseLabelStyle
                                                        .copyWith(
                                                      fontSize:
                                                          compact ? 11 : null,
                                                      color: color ??
                                                          (selected
                                                              ? thumbText
                                                              : scheme
                                                                  .onSurfaceVariant),
                                                      fontWeight: targetWeight,
                                                      fontVariations:
                                                          baseLabelStyle
                                                                      .fontVariations !=
                                                                  null
                                                              ? [
                                                                  FontVariation(
                                                                    'wght',
                                                                    targetWeight
                                                                        .value
                                                                        .toDouble(),
                                                                  ),
                                                                ]
                                                              : null,
                                                    ),
                                                  );
                                                },
                                              )))))))
                  ]),
                ])));
      }),
    );
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
