import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'package:flutter/material.dart';

import '../utils/NavigationPreferences.dart';
import '../utils/ThemeManager.dart';
import '../utils/ConfettiPreferences.dart';
import 'ConfettiEffect.dart';
import 'AppColorPickerDialog.dart';
import 'AnimatedChoiceLabel.dart';
import 'AnimatedChoiceBar.dart';

/// 首页主题弹窗与「系统设置」共用的控件和状态，所有修改写入同一份缓存。
class ThemePreferenceControls extends StatefulWidget {
  const ThemePreferenceControls({super.key});

  @override
  State<ThemePreferenceControls> createState() =>
      _ThemePreferenceControlsState();
}

class _ThemePreferenceControlsState extends State<ThemePreferenceControls> {
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
  void initState() {
    super.initState();
    NavigationPreferences.instance.load();
    ConfettiPreferences.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final manager = ThemeManager();
    final navigation = NavigationPreferences.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        manager.notifier,
        manager.lightOverlayNotifier,
        manager.pureBlackNotifier,
        navigation,
        ConfettiPreferences.instance,
      ]),
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final dark = Theme.of(context).brightness == Brightness.dark;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: Text('背景透明度')),
                    Text('${(manager.lightOverlayOpacity * 100).round()}%',
                        style: TextStyle(color: scheme.primary)),
                  ]),
                  Slider(
                    value: manager.lightOverlayOpacity,
                    divisions: 20,
                    label: '${(manager.lightOverlayOpacity * 100).round()}%',
                    onChanged: dark && manager.pureBlackEnabled ? null : manager.setLightOverlayOpacity,
                  ),
                  Text(
                    dark ? '数值越高背景越暗，0% 为原始背景图' : '数值越高背景越淡，0% 为原始背景图',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Divider(),
            for (final option in const [
              (ThemeMode.light, Icons.light_mode, '浅色模式', '始终使用浅色主题'),
              (ThemeMode.dark, Icons.dark_mode, '深色模式', '始终使用深色主题'),
              (ThemeMode.system, Icons.settings_suggest, '跟随系统', '根据系统设置自动切换'),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(option.$2,
                    color: manager.themeMode == option.$1
                        ? scheme.primary
                        : scheme.onSurface),
                title: Text(option.$3),
                subtitle: Text(option.$4),
                selected: manager.themeMode == option.$1,
                trailing: manager.themeMode == option.$1
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => manager.setThemeMode(option.$1),
              ),
            if (dark)
              AppSwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('纯黑背景'),
                subtitle: const Text('使用真正的纯黑背景，隐藏背景图'),
                value: manager.pureBlackEnabled,
                onChanged: manager.setPureBlackEnabled,
              ),
            const Divider(),
            Text('导航体验',
                style: TextStyle(
                    color: scheme.onSurface, fontWeight: FontWeight.w600)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('导航栏样式'),
                  const SizedBox(height: 8),
                  AnimatedChoiceBar<NavigationBarStyle>(
                    values: NavigationBarStyle.values,
                    value: navigation.barStyle,
                    label: (style) => style.label,
                    onChanged: navigation.loaded ? navigation.setBarStyle : null,
                  ),
                  const SizedBox(height: 6),
                  Text(navigation.barStyle.description,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
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
                  '在不可用入口下方用红字说明原因（默认关闭）'),
              secondary:
                  Icon(Icons.error_outline_rounded, color: scheme.primary),
            ),
            const Divider(),
            Text('纸屑特效',
                style: TextStyle(
                    color: scheme.onSurface, fontWeight: FontWeight.w600)),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: ConfettiPreferences.instance.enabled,
              onChanged: ConfettiPreferences.instance.setEnabled,
              title: const Text('纸屑特效'),
              subtitle: const Text('刷新数据或同步成绩成功后播放彩纸礼炮'),
              secondary:
                  Icon(Icons.celebration_outlined, color: scheme.primary),
            ),
            AppSwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: ConfettiPreferences.instance.gravityEnabled,
              onChanged: ConfettiPreferences.instance.setGravityEnabled,
              title: const Text('重力效果'),
              subtitle: const Text('纸屑沿弧线飘落，向上喷出的纸屑会回落'),
              secondary: Icon(Icons.south_rounded, color: scheme.primary),
            ),
            Text('调和颜色',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _HarmonyColorChoice(
                  label: '主题色',
                  color: scheme.primary,
                  selected: ConfettiPreferences.instance.harmonyColor == null,
                  onTap: () =>
                      ConfettiPreferences.instance.setHarmonyColor(null),
                ),
                for (final color in _harmonyPresetColors)
                  _HarmonyColorChoice(
                    label: '',
                    color: color,
                    selected:
                        ConfettiPreferences.instance.harmonyColor == color,
                    onTap: () =>
                        ConfettiPreferences.instance.setHarmonyColor(color),
                  ),
                _HarmonyColorChoice(
                  label: '自定义颜色',
                  color: ConfettiPreferences.instance.harmonyColor ??
                      scheme.primary,
                  selected: ConfettiPreferences.instance.harmonyColor != null &&
                      !_harmonyPresetColors
                          .contains(ConfettiPreferences.instance.harmonyColor),
                  onTap: _pickHarmonyColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              const Expanded(child: Text('调和等级')),
              Text(
                  '${(ConfettiPreferences.instance.harmonyLevel * 100).round()}%',
                  style: TextStyle(color: scheme.primary)),
            ]),
            Slider(
              value: ConfettiPreferences.instance.harmonyLevel,
              divisions: 20,
              label:
                  '${(ConfettiPreferences.instance.harmonyLevel * 100).round()}%',
              onChanged: ConfettiPreferences.instance.setHarmonyLevel,
            ),
            Text(
              '数值越高，彩纸颜色越接近调和颜色；0% 保留鲜艳的多彩效果',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text('彩纸类型',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
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
                  AnimatedChoiceLabel(
                    label: option.$2,
                    selected:
                        ConfettiPreferences.instance.paperType == option.$1,
                    onTap: () =>
                        ConfettiPreferences.instance.setPaperType(option.$1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('播放位置',
                style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in const [
                  (ConfettiBurstPosition.topBottom, '上下星落'),
                  (ConfettiBurstPosition.leftRight, '左右流彩'),
                  (ConfettiBurstPosition.allEdges, '四方礼花'),
                ])
                  AnimatedChoiceLabel(
                    label: option.$2,
                    selected:
                        ConfettiPreferences.instance.position == option.$1,
                    onTap: () =>
                        ConfettiPreferences.instance.setPosition(option.$1),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => ConfettiEffect.show(context, force: true),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('立即播放预览'),
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
