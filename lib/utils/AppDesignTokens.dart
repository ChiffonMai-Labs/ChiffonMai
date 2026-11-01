import 'package:flutter/material.dart';

/// 全 App 共用的尺寸 / 间距 / 圆角 / 动效档位。
///
/// **新代码只从这里取值，不要再写死 8、10、11、14 这类零散圆角。**
/// 档位说明（2026-11 UI 重构定稿）：
///
/// | 圆角 | 用途 |
/// |---|---|
/// | [radiusSmall] 12 | 输入框、按钮、图标底块、小标签 |
/// | [radiusMedium] 16 | 列表分组卡片、次级卡片 |
/// | [radiusCard] 22 | 主内容卡片（白卡片） |
/// | [radiusLarge] 24 | 大号强调卡片（Rating 总览、计算结果） |
/// | [radiusPill] 999 | 胶囊（筛选标签、徽章） |
class AppDesignTokens {
  AppDesignTokens._();

  // ===== 页面布局 =====
  static const pagePadding = EdgeInsets.fromLTRB(16, 16, 16, 28);

  /// 详情页 / 工具页左右留白。
  static const double gutter = 16;
  static const sectionGap = 20.0;
  static const itemGap = 12.0;
  static const double cardGap = 12;
  static const cardPadding = EdgeInsets.all(16);

  // ===== 圆角 =====
  static const double radiusSmall = 12.0;
  static const radiusMedium = 16.0;
  static const double radiusCard = 22.0;
  static const radiusLarge = 24.0;
  static const double radiusPill = 999.0;

  // ===== 交互 =====
  static const minTouchTarget = 48.0;
  static const maxContentWidth = 1120.0;

  // ===== 动效 =====
  static const fastMotion = Duration(milliseconds: 180);
  static const Duration mediumMotion = Duration(milliseconds: 280);
  static const Duration slowMotion = Duration(milliseconds: 450);
  static const Curve emphasizedCurve = Cubic(0.2, 0.8, 0.2, 1);

  /// 系统开启「减少动态效果」时返回 [Duration.zero]。
  static Duration motion(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true
          ? Duration.zero
          : duration;
}

/// 主题感知的表面色。
///
/// B 方案的层级：页面底（主题底色 / 用户背景图）→ [card] 白卡片 → [inset] 卡内凹槽。
/// 用户设置了自定义背景图时，卡片保持不透明，保证文字可读；
/// 背景图本身的覆层透明度仍由「系统设置」控制，这里不改。
class AppSurfaces {
  static Color panel(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  static Color elevated(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  /// 主内容卡片：浅色模式接近纯白，深色 / 纯黑模式取比页面底亮一级的容器色。
  static Color card(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return theme.brightness == Brightness.dark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerLowest;
  }

  /// 卡片内的凹槽（输入框底、步进器底、物量格、胶囊入口）。
  static Color inset(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainer;
  }

  /// 页面上的轨道（分段切换的底、未选中的筛选胶囊）。比 [inset] 深一级。
  static Color track(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return theme.brightness == Brightness.dark
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerHigh;
  }

  /// 卡片之间、行之间的细分隔线。
  static Color hairline(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6);
}
