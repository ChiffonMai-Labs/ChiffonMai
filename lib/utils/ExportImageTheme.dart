import 'package:flutter/material.dart';

/// 导出图片的主题。用户在导出抽屉里选，和 App 当前的主题、系统明暗都无关。
enum ExportImageTheme {
  light('浅色'),
  dark('深色'),
  black('纯黑');

  final String label;

  const ExportImageTheme(this.label);

  static ExportImageTheme fromIndex(int? index) =>
      values[(index ?? 0).clamp(0, values.length - 1)];
}

/// 导出图片的配色。颜色写死在这里而不是取 `ColorScheme`：
/// 同一份数据选同一个主题，不管手机当时是什么主题，导出来都长一样。
class ExportPalette {
  final Brightness brightness;
  final Color page;
  final Color panel;
  final Color inset;
  final Color track;
  final Color ink;

  /// 实心 [ink] 底上的文字（分区标题胶囊）。
  final Color onInk;
  final Color muted;
  final Color accent;
  final Color heroDeep;
  final Color heroLight;
  final Color positive;
  final Color negative;
  final Color cardBorder;

  const ExportPalette({
    required this.brightness,
    required this.page,
    required this.panel,
    required this.inset,
    required this.track,
    required this.ink,
    required this.onInk,
    required this.muted,
    required this.accent,
    required this.heroDeep,
    required this.heroLight,
    required this.positive,
    required this.negative,
    required this.cardBorder,
  });

  static const ExportPalette light = ExportPalette(
    brightness: Brightness.light,
    page: Color(0xFFEFF3F2),
    panel: Colors.white,
    inset: Color(0xFFF0F4F3),
    track: Color(0xFFDFE6E4),
    ink: Color(0xFF16201F),
    onInk: Colors.white,
    muted: Color(0xFF5F6B6A),
    accent: Color(0xFF006A6A),
    heroDeep: Color(0xFF00393B),
    heroLight: Color(0xFF0B8F86),
    positive: Color(0xFF1E8E4E),
    negative: Color(0xFFD23C3C),
    cardBorder: Color(0x14000000),
  );

  static const ExportPalette dark = ExportPalette(
    brightness: Brightness.dark,
    page: Color(0xFF0F1514),
    panel: Color(0xFF1A2120),
    inset: Color(0xFF242C2B),
    track: Color(0xFF35403E),
    ink: Color(0xFFE3EAE8),
    onInk: Color(0xFF0F1514),
    muted: Color(0xFFA3B0AE),
    accent: Color(0xFF4FD1C5),
    heroDeep: Color(0xFF002A2C),
    heroLight: Color(0xFF0A6F68),
    positive: Color(0xFF5BD08A),
    negative: Color(0xFFFF8A80),
    cardBorder: Color(0x14FFFFFF),
  );

  static const ExportPalette black = ExportPalette(
    brightness: Brightness.dark,
    page: Colors.black,
    panel: Color(0xFF111111),
    inset: Color(0xFF1C1C1C),
    track: Color(0xFF333333),
    ink: Colors.white,
    onInk: Colors.black,
    muted: Color(0xFFA6A6A6),
    accent: Color(0xFF4FD1C5),
    heroDeep: Color(0xFF001A1B),
    heroLight: Color(0xFF075550),
    positive: Color(0xFF5BD08A),
    negative: Color(0xFFFF8A80),
    cardBorder: Color(0x33FFFFFF),
  );

  bool get isLight => brightness == Brightness.light;

  static ExportPalette forTheme(ExportImageTheme theme) => switch (theme) {
        ExportImageTheme.light => light,
        ExportImageTheme.dark => dark,
        ExportImageTheme.black => black,
      };

  /// 取导出图片根部 [ExportThemeScope] 的配色；不在导出图片里时是浅色。
  static ExportPalette of(BuildContext context) =>
      forTheme(ExportThemeScope.maybeOf(context) ?? ExportImageTheme.light);
}

/// 把导出主题传给导出图片里的组件。
class ExportThemeScope extends InheritedWidget {
  final ExportImageTheme theme;

  const ExportThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  static ExportImageTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExportThemeScope>()?.theme;

  @override
  bool updateShouldNotify(ExportThemeScope oldWidget) =>
      oldWidget.theme != theme;
}
