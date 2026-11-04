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
        heading('导航体验'),
        const NavigationControls(),
        const Divider(height: 24),
        heading('纸屑特效'),
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
      listenable: Listenable.merge(
          [manager.notifier, manager.lightOverlayNotifier, manager.pureBlackNotifier]),
      builder: (context, _) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return GuessSliderTile(
          label: '背景透明度',
          valueText: '${(manager.lightOverlayOpacity * 100).round()}%',
          value: manager.lightOverlayOpacity,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: dark && manager.pureBlackEnabled
              ? null
              : manager.setLightOverlayOpacity,
          hint: dark ? '数值越高背景越暗，0% 为原始背景图' : '数值越高背景越淡，0% 为原始背景图',
        );
      },
    );
  }
}

/// 浅色 / 深色 / 跟随系统，深色时多一个纯黑背景开关。
class ThemeModeControl extends StatelessWidget {
  const ThemeModeControl({super.key});

  static const _options = [
    (ThemeMode.light, Icons.light_mode_rounded, '浅色'),
    (ThemeMode.dark, Icons.dark_mode_rounded, '深色'),
    (ThemeMode.system, Icons.settings_suggest_rounded, '跟随系统'),
  ];

  @override
  Widget build(BuildContext context) {
    final manager = ThemeManager();
    return ListenableBuilder(
      listenable: Listenable.merge([manager.notifier, manager.pureBlackNotifier]),
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
                for (final (index, option) in _options.indexed) ...[
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                                Text(
                                  option.$3,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: manager.themeMode == option.$1
                                        ? scheme.onPrimary
                                        : scheme.onSurface,
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
                title: const Text('纯黑背景'),
                subtitle: const Text('使用真正的纯黑背景，隐藏背景图'),
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
            const Text('导航栏样式', style: TextStyle(fontSize: 13.5)),
            const SizedBox(height: 8),
            AnimatedChoiceBar<NavigationBarStyle>(
              values: NavigationBarStyle.values,
              value: navigation.barStyle,
              label: (style) => style.label,
              onChanged: navigation.loaded ? navigation.setBarStyle : null,
            ),
            const SizedBox(height: 6),
            Text(navigation.barStyle.description,
                style:
                    TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.transitionEnabled,
              onChanged: navigation.setTransitionEnabled,
              title: const Text('导航栏切换动画'),
              subtitle: const Text('切换主界面时使用淡入滑动过渡，并淡化图标状态'),
              secondary: Icon(Icons.animation_outlined, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.swipeEnabled,
              onChanged: navigation.setSwipeEnabled,
              title: const Text('左右滑动切换主界面'),
              subtitle: const Text('在主界面内容区域左右滑动即可切换底部导航项'),
              secondary: Icon(Icons.swipe_outlined, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.immersiveStatusBarEnabled,
              onChanged: navigation.setImmersiveStatusBarEnabled,
              title: const Text('沉浸式状态栏'),
              subtitle: const Text('隐藏顶部时间、电量等状态信息，保留底部系统导航'),
              secondary: Icon(Icons.fullscreen_rounded, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: navigation.busyHintEnabled,
              onChanged: navigation.setBusyHintEnabled,
              title: const Text('任务进行中提示'),
              subtitle: const Text('同步、刷新等任务进行中时，'
                  '在不可用入口下方用红字说明原因'),
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
      title: '自定义调和颜色',
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
              title: const Text('纸屑特效'),
              subtitle: const Text('刷新数据或同步成绩成功后播放彩纸礼炮'),
              secondary:
                  Icon(Icons.celebration_outlined, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: confetti.gravityEnabled,
              onChanged: confetti.setGravityEnabled,
              title: const Text('重力效果'),
              subtitle: const Text('纸屑沿弧线飘落，向上喷出的纸屑会回落'),
              secondary: Icon(Icons.south_rounded, color: scheme.primary),
            ),
            heading('调和颜色'),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _HarmonyColorChoice(
                  label: '主题色',
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
                  label: '自定义颜色',
                  color: confetti.harmonyColor ?? scheme.primary,
                  selected: confetti.harmonyColor != null &&
                      !_harmonyPresetColors.contains(confetti.harmonyColor),
                  onTap: _pickHarmonyColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            GuessSliderTile(
              label: '调和等级',
              valueText: '${(confetti.harmonyLevel * 100).round()}%',
              value: confetti.harmonyLevel,
              min: 0,
              max: 1,
              divisions: 20,
              onChanged: confetti.setHarmonyLevel,
              hint: '数值越高，彩纸颜色越接近调和颜色；0% 保留鲜艳的多彩效果',
            ),
            heading('彩纸类型'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in const [
                  (ConfettiPaperType.mixed, '缤纷混彩'),
                  (ConfettiPaperType.square, '方形纸片'),
                  (ConfettiPaperType.circle, '圆润纸片'),
                  (ConfettiPaperType.ribbon, '轻盈彩带'),
                ])
                  GuessChoicePill(
                    label: option.$2,
                    selected: confetti.paperType == option.$1,
                    onTap: () => confetti.setPaperType(option.$1),
                  ),
              ],
            ),
            heading('播放位置'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in const [
                  (ConfettiBurstPosition.topBottom, '上下星落'),
                  (ConfettiBurstPosition.leftRight, '左右流彩'),
                  (ConfettiBurstPosition.allEdges, '四方礼花'),
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
                label: const Text('立即播放预览'),
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
