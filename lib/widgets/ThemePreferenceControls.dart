import '../l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/NavigationPreferences.dart';
import '../utils/ThemeManager.dart';
import '../utils/ConfettiPreferences.dart';
import 'ConfettiEffect.dart';
import 'AppColorPickerDialog.dart';
import 'AnimatedChoiceBar.dart';
import 'AppUi.dart';
import 'GuessSettingsUi.dart';

/// 首页主题弹窗显示的完整设置，所有修改写入同一份缓存。
/// 系统设置把下面几块拆开，分别放进不同的标签。
class ThemePreferenceControls extends StatefulWidget {
  const ThemePreferenceControls({super.key});

  @override
  State<ThemePreferenceControls> createState() =>
      _ThemePreferenceControlsState();
}

class _ThemePreferenceControlsState extends State<ThemePreferenceControls> {
  @override
  void initState() {
    super.initState();
    NavigationPreferences.instance.load();
    ConfettiPreferences.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: TextStyle(
                  color: scheme.onSurface, fontWeight: FontWeight.w600)),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BackgroundOverlayControl(),
        const Divider(height: 24),
        const ThemeModeControl(),
        const Divider(height: 24),
        heading(context.l10n.navigationExperience),
        const NavigationControls(),
        const Divider(height: 24),
        heading(context.l10n.confetti),
        const ConfettiControls(),
      ],
    );
  }
}

/// 背景透明度。
class BackgroundOverlayControl extends StatelessWidget {
  const BackgroundOverlayControl({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = ThemeManager();
    return ListenableBuilder(
      listenable: Listenable.merge([
        manager.notifier,
        manager.lightOverlayNotifier,
        manager.pureBlackNotifier
      ]),
      builder: (context, _) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return GuessSliderTile(
          label: context.l10n.backgroundOpacity,
          valueText: '${(manager.lightOverlayOpacity * 100).round()}%',
          value: manager.lightOverlayOpacity,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: dark && manager.pureBlackEnabled
              ? null
              : manager.setLightOverlayOpacity,
          hint: dark
              ? context.l10n.backgroundDarkHint
              : context.l10n.backgroundLightHint,
        );
      },
    );
  }
}

/// 浅色 / 深色 / 跟随系统，深色时多一个纯黑背景开关。
class ThemeModeControl extends StatelessWidget {
  const ThemeModeControl({super.key});

  List<(ThemeMode, IconData, String)> _options(BuildContext context) => [
        (ThemeMode.light, Icons.light_mode_rounded, context.l10n.lightMode),
        (ThemeMode.dark, Icons.dark_mode_rounded, context.l10n.darkMode),
        (
          ThemeMode.system,
          Icons.settings_suggest_rounded,
          context.l10n.followSystem
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final manager = ThemeManager();
    return ListenableBuilder(
      listenable:
          Listenable.merge([manager.notifier, manager.pureBlackNotifier]),
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final dark = Theme.of(context).brightness == Brightness.dark;
        final duration =
            AppDesignTokens.motion(context, AppDesignTokens.fastMotion);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (final (index, option) in _options(context).indexed) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: PressScale(
                      child: Semantics(
                        button: true,
                        selected: manager.themeMode == option.$1,
                        label: option.$3,
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => manager.setThemeMode(option.$1),
                          child: AnimatedContainer(
                            duration: duration,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 6),
                            decoration: BoxDecoration(
                              color: manager.themeMode == option.$1
                                  ? scheme.primary
                                  : AppSurfaces.inset(context),
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusMedium),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  option.$2,
                                  size: 22,
                                  color: manager.themeMode == option.$1
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 4),
                                // 日语「システムに従う」等长文案放不下时等比缩小，不换行。
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    option.$3,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: manager.themeMode == option.$1
                                          ? scheme.onPrimary
                                          : scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (dark) ...[
              const SizedBox(height: 6),
              AppSwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.pureBlack),
                subtitle: Text(context.l10n.pureBlackHint),
                value: manager.pureBlackEnabled,
                onChanged: manager.setPureBlackEnabled,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// 导航栏样式与导航相关开关。
class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = NavigationPreferences.instance;
    return ListenableBuilder(
      listenable: navigation,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.navigationStyle,
                style: TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            AnimatedChoiceBar<NavigationBarStyle>(
              values: NavigationBarStyle.values,
              value: navigation.barStyle,
              label: (style) => switch (style) {
                NavigationBarStyle.standard => context.l10n.navigationClassic,
                NavigationBarStyle.liquidGlass => context.l10n.navigationGlass,
                NavigationBarStyle.expandingPill => context.l10n.navigationPill,
              },
              onChanged: navigation.loaded ? navigation.setBarStyle : null,
            ),
            const SizedBox(height: 6),
            Text(
                switch (navigation.barStyle) {
                  NavigationBarStyle.standard =>
                    context.l10n.navigationClassicHint,
                  NavigationBarStyle.liquidGlass =>
                    context.l10n.navigationGlassHint,
                  NavigationBarStyle.expandingPill =>
                    context.l10n.navigationPillHint,
                },
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.transitionEnabled,
              onChanged: navigation.setTransitionEnabled,
              title: Text(context.l10n.navigationAnimation),
              subtitle: Text(context.l10n.navigationAnimationHint),
              secondary: Icon(Icons.animation_outlined, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.swipeEnabled,
              onChanged: navigation.setSwipeEnabled,
              title: Text(context.l10n.swipeNavigation),
              subtitle: Text(context.l10n.swipeNavigationHint),
              secondary: Icon(Icons.swipe_outlined, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.immersiveStatusBarEnabled,
              onChanged: navigation.setImmersiveStatusBarEnabled,
              title: Text(context.l10n.immersiveStatusBar),
              subtitle: Text(context.l10n.immersiveStatusBarHint),
              secondary: Icon(Icons.fullscreen_rounded, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.busyHintEnabled,
              onChanged: navigation.setBusyHintEnabled,
              title: Text(context.l10n.busyHint),
              subtitle: Text(context.l10n.busyHintDescription),
              secondary:
                  Icon(Icons.error_outline_rounded, color: scheme.primary),
            ),
          ],
        );
      },
    );
  }
}

/// 纸屑特效的全部设置。
class ConfettiControls extends StatefulWidget {
  const ConfettiControls({super.key});

  @override
  State<ConfettiControls> createState() => _ConfettiControlsState();
}

class _ConfettiControlsState extends State<ConfettiControls> {
  static const _harmonyPresetColors = [
    Color(0xFFFF6B8B),
    Color(0xFFFFC857),
    Color(0xFF4DD0E1),
    Color(0xFF7E8CE0),
    Color(0xFF70C174),
  ];

  Future<void> _pickHarmonyColor() async {
    final preferences = ConfettiPreferences.instance;
    await preferences.load();
    if (!mounted) return;
    final picked = await showAppColorPicker(
      context,
      title: context.l10n.customHarmonyColor,
      initial:
          preferences.harmonyColor ?? Theme.of(context).colorScheme.primary,
    );
    if (mounted && picked != null) await preferences.setHarmonyColor(picked);
  }

  @override
  Widget build(BuildContext context) {
    final confetti = ConfettiPreferences.instance;
    return ListenableBuilder(
      listenable: confetti,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        Widget heading(String text) => Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(text, style: const TextStyle(fontSize: 13.5)),
            );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: confetti.enabled,
              onChanged: confetti.setEnabled,
              title: Text(context.l10n.confetti),
              subtitle: Text(context.l10n.confettiHint),
              secondary:
                  Icon(Icons.celebration_outlined, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: confetti.gravityEnabled,
              onChanged: confetti.setGravityEnabled,
              title: Text(context.l10n.gravityEffect),
              subtitle: Text(context.l10n.gravityEffectHint),
              secondary: Icon(Icons.south_rounded, color: scheme.primary),
            ),
            heading(context.l10n.harmonyColor),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _HarmonyColorChoice(
                  label: context.l10n.themeColor,
                  color: scheme.primary,
                  selected: confetti.harmonyColor == null,
                  onTap: () => confetti.setHarmonyColor(null),
                ),
                for (final color in _harmonyPresetColors)
                  _HarmonyColorChoice(
                    label: '',
                    color: color,
                    selected: confetti.harmonyColor == color,
                    onTap: () => confetti.setHarmonyColor(color),
                  ),
                _HarmonyColorChoice(
                  label: context.l10n.customColor,
                  color: confetti.harmonyColor ?? scheme.primary,
                  selected: confetti.harmonyColor != null &&
                      !_harmonyPresetColors.contains(confetti.harmonyColor),
                  onTap: _pickHarmonyColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GuessSliderTile(
              label: context.l10n.harmonyLevel,
              valueText: '${(confetti.harmonyLevel * 100).round()}%',
              value: confetti.harmonyLevel,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: confetti.setHarmonyLevel,
              hint: context.l10n.harmonyHint,
            ),
            heading(context.l10n.paperType),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in [
                  (ConfettiPaperType.mixed, context.l10n.paperMixed),
                  (ConfettiPaperType.square, context.l10n.paperSquare),
                  (ConfettiPaperType.circle, context.l10n.paperCircle),
                  (ConfettiPaperType.ribbon, context.l10n.paperRibbon),
                ])
                  GuessChoicePill(
                    label: option.$2,
                    selected: confetti.paperType == option.$1,
                    onTap: () => confetti.setPaperType(option.$1),
                  ),
              ],
            ),
            heading(context.l10n.burstPosition),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in [
                  (
                    ConfettiBurstPosition.topBottom,
                    context.l10n.burstTopBottom
                  ),
                  (
                    ConfettiBurstPosition.leftRight,
                    context.l10n.burstLeftRight
                  ),
                  (ConfettiBurstPosition.allEdges, context.l10n.burstAllEdges),
                ])
                  GuessChoicePill(
                    label: option.$2,
                    selected: confetti.position == option.$1,
                    onTap: () => confetti.setPosition(option.$1),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: FilledButton.tonalIcon(
                onPressed: () => ConfettiEffect.show(context, force: true),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(context.l10n.previewNow),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HarmonyColorChoice extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _HarmonyColorChoice({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(
                color: selected ? scheme.onSurface : scheme.outlineVariant,
                width: selected ? 3 : 1,
              ),
            ),
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ]),
      ),
    );
  }
}
