import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'VideoExportPageTransitionsTheme.dart';

/// 集中式主题定义：提供浅色和暗色 ThemeData，以及主题感知的颜色访问器
class AppTheme {
  /// 应用默认系统栏样式。
  ///
  /// Android 15/16 的 edge-to-edge 模式下，状态栏背景色由页面内容决定，
  /// 因此不能依赖 Flutter 根据透明 AppBar 自动猜测图标亮度。统一按主题明确
  /// 指定亮暗，避免页面切换或窗口重新获得焦点后沿用上一页的样式。
  static SystemUiOverlayStyle systemUiOverlayStyle(
    Brightness brightness, {
    Color? navigationBarColor,
  }) {
    final dark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: navigationBarColor,
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  // ========== 字体 ==========

  /// 全 App 的字体：思源黑体（`google_fonts` 运行时从网络获取）。
  ///
  /// **凡是被组件自己套了 `DefaultTextStyle` 的样式，都必须走这里。**
  /// 全局字体的注入方式是「替换 `textTheme` + 根部 `DefaultTextStyle`」，
  /// 而组件自带的 `DefaultTextStyle` 会把这层顶掉 —— `AppBar` 就是典型：它用
  /// `appBarTheme.titleTextStyle` 给标题另套了一层样式，只要那份 `TextStyle`
  /// 不带 `fontFamily`，标题就会退回系统默认字体（Roboto），于是出现
  /// 「同一个页面里标题和正文不是同一套字」。
  ///
  /// ⚠️ google_fonts 的族名是**按字重分文件**的（`NotoSansSC_regular` /
  /// `NotoSansSC_700` …），所以字重必须一起传进来 ——
  /// 先取到族名再 `copyWith(fontWeight:)` 会拿到错的字重文件。
  ///
  /// ⚠️ **只能在 `build` 里调用**：它内部会走 `rootBundle`，
  /// 需要 `ServicesBinding` 已经初始化（`main()` 顶层、`test` 顶层调用会抛
  /// 「Binding has not yet been initialized」）。所以主题构造（[lightTheme] 等）
  /// 一律用裸 `TextStyle`，字体族由 [withGlobalFonts] 在运行时补上。
  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    TextDecorationStyle? decorationStyle,
    Color? decorationColor,
  }) {
    // 测试/探针旁路：测试环境没有网络、也没有 `NotoSansSC_*` 这些族，
    // 真去联网会失败，而 google_fonts 的失败挂在内部 future 上、外部接不住
    // （实测会把 golden 探针判失败）。旁路只换族名，字重映射规则与 google_fonts
    // 一致（w400 → `_regular`，其余 → 数字），所以出图效果与真机同口径。
    if (debugLocalFontFamily) {
      final weight = (fontWeight ?? FontWeight.w400).value;
      return TextStyle(
        fontFamily: weight == 400 ? 'NotoSansSC_regular' : 'NotoSansSC_$weight',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        decoration: decoration,
        decorationStyle: decorationStyle,
        decorationColor: decorationColor,
      );
    }
    return _outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    ).copyWith(
      fontStyle: fontStyle,
      decoration: decoration,
      decorationStyle: decorationStyle,
      decorationColor: decorationColor,
    );
  }

  /// 全 App 主字体 Outfit。它没有中文，中文按相同字重回落到思源黑体（不走系统字体）。
  static TextStyle _outfit({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    List<FontFeature>? fontFeatures,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: fontFeatures,
    ).copyWith(
      fontFamilyFallback: [
        GoogleFonts.notoSansSc(fontWeight: fontWeight).fontFamily!,
      ],
    );
  }

  /// 数字 / 拉丁展示字体：**Outfit**（几何无衬线，等宽数字）。
  ///
  /// 只用于 Rating、达成率、定数、物量这类**数字为主角**的位置；
  /// 中文正文继续走 [font]（思源黑体）。和 [font] 一样走 google_fonts、
  /// 字重必须随调用一起传入，并且**只能在 `build` 里调用**。
  ///
  /// 默认开启 `tabularFigures`：数字逐帧变化（计数动画、实时计算）时
  /// 宽度不抖。
  static TextStyle number({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    const features = [FontFeature.tabularFigures()];
    if (debugLocalFontFamily) {
      // 测试环境没有 Outfit：退回本地思源黑体，字重映射与 [font] 一致。
      final weight = (fontWeight ?? FontWeight.w600).value;
      return TextStyle(
        fontFamily: weight == 400 ? 'NotoSansSC_regular' : 'NotoSansSC_$weight',
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: features,
      );
    }
    return _outfit(
      fontSize: fontSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );
  }

  /// 测试/探针专用：让 [font] 返回本地已注册的 `NotoSansSC_*` 族，不联网。
  /// 真机（debug/release）永远是 false。
  @visibleForTesting
  static bool debugLocalFontFamily = false;

  /// 主题文字：Outfit，每一档的中文回落都用同字重的思源黑体。
  static TextTheme _outfitTextTheme(TextTheme base) {
    if (debugLocalFontFamily) {
      return base.apply(fontFamily: 'NotoSansSC_regular');
    }
    final outfit = GoogleFonts.outfitTextTheme(base);
    final noto = GoogleFonts.notoSansScTextTheme(base);
    TextStyle? merge(TextStyle? style, TextStyle? cjk) =>
        style?.copyWith(fontFamilyFallback: [
          if (cjk?.fontFamily != null) cjk!.fontFamily!,
        ]);
    return outfit.copyWith(
      displayLarge: merge(outfit.displayLarge, noto.displayLarge),
      displayMedium: merge(outfit.displayMedium, noto.displayMedium),
      displaySmall: merge(outfit.displaySmall, noto.displaySmall),
      headlineLarge: merge(outfit.headlineLarge, noto.headlineLarge),
      headlineMedium: merge(outfit.headlineMedium, noto.headlineMedium),
      headlineSmall: merge(outfit.headlineSmall, noto.headlineSmall),
      titleLarge: merge(outfit.titleLarge, noto.titleLarge),
      titleMedium: merge(outfit.titleMedium, noto.titleMedium),
      titleSmall: merge(outfit.titleSmall, noto.titleSmall),
      bodyLarge: merge(outfit.bodyLarge, noto.bodyLarge),
      bodyMedium: merge(outfit.bodyMedium, noto.bodyMedium),
      bodySmall: merge(outfit.bodySmall, noto.bodySmall),
      labelLarge: merge(outfit.labelLarge, noto.labelLarge),
      labelMedium: merge(outfit.labelMedium, noto.labelMedium),
      labelSmall: merge(outfit.labelSmall, noto.labelSmall),
    );
  }

  /// 把全局网络字体注入主题（与 [font] 同一个来源）。
  ///
  /// `textTheme` / `primaryTextTheme` 覆盖掉正文，`appBarTheme.titleTextStyle`
  /// 单独补族名 —— 否则**标准 `AppBar`（`Scaffold.appBar`）的标题**会被它自己那层
  /// `DefaultTextStyle` 顶回系统字体（`AppHeader` 不依赖这里，它自己调 [font]）。
  ///
  /// 运行时调用（`build` 里），不要在主题构造期调用。
  static ThemeData withGlobalFonts(ThemeData base) {
    final baseTitle = base.appBarTheme.titleTextStyle;
    TextStyle? withFont(TextStyle? style) => style == null
        ? null
        : font(
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            color: style.color,
            height: style.height,
            letterSpacing: style.letterSpacing,
          );
    final navigationLabel = base.navigationBarTheme.labelTextStyle;
    return base.copyWith(
      textTheme: _outfitTextTheme(base.textTheme),
      primaryTextTheme: _outfitTextTheme(base.primaryTextTheme),
      listTileTheme: base.listTileTheme.copyWith(
        titleTextStyle: withFont(base.listTileTheme.titleTextStyle),
        subtitleTextStyle: withFont(base.listTileTheme.subtitleTextStyle),
      ),
      navigationBarTheme: navigationLabel == null
          ? base.navigationBarTheme
          : base.navigationBarTheme.copyWith(
              labelTextStyle: WidgetStateProperty.resolveWith(
                  (states) => withFont(navigationLabel.resolve(states))),
            ),
      appBarTheme: baseTitle == null
          ? base.appBarTheme
          : base.appBarTheme.copyWith(
              titleTextStyle: font(
                fontSize: baseTitle.fontSize,
                fontWeight: baseTitle.fontWeight,
                color: baseTitle.color,
                height: baseTitle.height,
                letterSpacing: baseTitle.letterSpacing,
              ),
            ),
    );
  }

  // ========== 默认 seed 色（用户未自定义时使用） ==========
  static const Color defaultLightSeed = Color(0xFF006A6A);
  static const Color defaultDarkSeed = Color(0xFF006A6A);
  static const Color defaultPureBlackSeed = Color(0xFFE0E0E0);

  /// 派生浅色 ColorScheme（基于 seed 色）
  ///
  /// 页面底色取 `surfaceContainerLow`（比纯 surface 略灰），白卡片才浮得起来。
  static ColorScheme buildLightColorScheme({Color? seedColor}) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor ?? defaultLightSeed,
      brightness: Brightness.light,
    );
    return base.copyWith(surface: base.surfaceContainerLow);
  }

  /// 派生暗色 ColorScheme（基于 seed 色）
  static ColorScheme buildDarkColorScheme({Color? seedColor}) =>
      ColorScheme.fromSeed(
        seedColor: seedColor ?? defaultDarkSeed,
        brightness: Brightness.dark,
      );

  /// 派生纯黑 ColorScheme（基于 seed 色）
  /// 纯黑模式覆层更深，surface 趋近黑色
  static ColorScheme buildPureBlackColorScheme({Color? seedColor}) {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor ?? defaultPureBlackSeed,
      brightness: Brightness.dark,
    );
    return base.copyWith(
      surface: const Color(0xFF111111),
      surfaceContainerHighest: const Color(0xFF1A1A1A),
      outline: const Color(0xFF555555),
    );
  }

  // ========== ThemeData 构建 ==========

  /// 页面转场：**显式指定，不要用框架默认值**（默认值 = 预测性返回）。
  ///
  /// ## 为什么必须显式指定
  ///
  /// 这个 Flutter 版本把 Android 的默认转场换成了
  /// `PredictiveBackPageTransitionsBuilder`（见 `page_transitions_theme.dart`
  /// 的 `_defaultBuilders`）。它会往**每一条路由**里塞一个
  /// `_PredictiveBackGestureDetector`：返回手势一开始，框架就替系统"认领"这次
  /// 手势（`WidgetsBinding.handleStartBackGesture` 返回 true），于是
  ///   * 页面不再由系统画预览，而是**框架按手指进度自己缩放** —— 就是用户看到的
  ///     「页面从四个角向内缩」（缩到 0.90 + 32px 圆角 + 右下位移）；
  ///   * 框架**必须**等到平台发来 commit / cancel 才能退出这个状态。手势事件与
  ///     路由 pop 之间是异步竞态（pop 过程中路由连同它的 detector 一起被释放，
  ///     而 binding 里的观察者列表要到下一次手势开始才清空），一旦对不上，
  ///     页面就停在缩了一半的位置、事件也被 Navigator 的 AbsorbPointer 吞掉 ——
  ///     用户看到的就是「**返回手势之后 App 无法交互 / 卡死**」，而且
  ///     **只在手势路径上出现**：按键返回时 `backEvent.isButtonEvent == true`，
  ///     框架不认领，所以从来没出过事；「有概率」正是竞态的特征。
  ///
  /// ## 为什么换成 `FadeForwardsPageTransitionsBuilder`
  ///
  /// 它**就是框架自己在"没有手势"时的回落分支**：`PredictiveBackPageTransitionsBuilder
  /// .buildTransitions` 里 `route.popGestureInProgress == false` 时走的就是它。
  /// 所以普通 push / 返回按钮 / 手势提交之后的观感**一模一样**，只是不再参与
  /// 预测性返回的手势认领（配合 AndroidManifest 里
  /// `enableOnBackInvokedCallback="false"` 一起生效）。
  ///
  /// 回归测试：`test/page_transitions_test.dart`。
  static PageTransitionsTheme _backGestureSafeTransitions() {
    final builders = Map<TargetPlatform, PageTransitionsBuilder>.of(
      const PageTransitionsTheme().builders,
    );
    builders[TargetPlatform.android] =
        const FadeForwardsPageTransitionsBuilder();
    return VideoExportPageTransitionsTheme(builders: builders);
  }

  /// 复用 Material 3 开关：关闭时滑块在左侧显示叉号，开启时在右侧显示对钩。
  /// 不指定图标颜色，沿用主题对启用、禁用及明暗状态的配色。
  static const SwitchThemeData _switchTheme = SwitchThemeData(
        // 常量映射避免主题重建时反复创建图标和解析闭包，使开关画笔缓存可复用。
        thumbIcon: WidgetStateMapper<Icon?>({
          WidgetState.selected: Icon(Icons.check_rounded),
          WidgetState.any: Icon(Icons.close_rounded),
        }),
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      );

  /// 全局组件观感（2026-11 UI 重构）：三套主题共用一份。
  ///
  /// 没有单独改版的老页面也靠这里拿到同一套圆角、按钮和输入框。
  static ThemeData _canvasStyle(ThemeData base) {
    final scheme = base.colorScheme;
    final dark = base.brightness == Brightness.dark;
    final card = dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final inset = dark ? scheme.surfaceContainerHigh : scheme.surfaceContainer;
    final track =
        dark ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh;
    RoundedRectangleBorder radius(double r) =>
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
    OutlineInputBorder input(BorderSide side) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: side);
    const noOverlay = WidgetStatePropertyAll<Color>(Colors.transparent);
    return base.copyWith(
      // 所有点击都不要波纹和按下高亮，按压反馈用 PressScale（§19）。
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(overlayColor: noOverlay),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          overlayColor: Colors.transparent,
        ),
      ),
      checkboxTheme: const CheckboxThemeData(overlayColor: noOverlay),
      radioTheme: const RadioThemeData(overlayColor: noOverlay),
      cardTheme: base.cardTheme.copyWith(color: card, shape: radius(22)),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: radius(24),
        titleTextStyle: base.textTheme.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        contentTextStyle: base.textTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.5,
          color: scheme.onSurfaceVariant,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: radius(16),
      ),
      listTileTheme: base.listTileTheme.copyWith(shape: radius(16)),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: track,
        side: BorderSide.none,
        shape: radius(10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          overlayColor: Colors.transparent,
          shape: radius(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          overlayColor: Colors.transparent,
          shape: radius(16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          overlayColor: Colors.transparent,
          side: BorderSide(color: scheme.outlineVariant),
          shape: radius(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inset,
        border: input(BorderSide.none),
        enabledBorder: input(BorderSide.none),
        focusedBorder: input(BorderSide(color: scheme.primary, width: 2)),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        iconTheme: IconThemeData(color: scheme.onSurface),
        actionsIconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle:
            base.appBarTheme.titleTextStyle?.copyWith(color: scheme.onSurface),
      ),
    );
  }

  static ThemeData lightTheme({Color? seedColor}) =>
      _canvasStyle(_lightThemeBase(seedColor: seedColor));

  static ThemeData _lightThemeBase({Color? seedColor}) {
    final scheme = buildLightColorScheme(seedColor: seedColor);
    return ThemeData(
      useMaterial3: true,
      switchTheme: _switchTheme,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      pageTransitionsTheme: _backGestureSafeTransitions(),
      tabBarTheme: const TabBarThemeData(
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle:
            WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.primary),
        // 这里刻意用裸 TextStyle：主题构造期不能碰 google_fonts（需要 ServicesBinding）。
        // 字体族由 AppTheme.withGlobalFonts 在运行时补上（见那里的注释）。
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData darkTheme({Color? seedColor}) =>
      _canvasStyle(_darkThemeBase(seedColor: seedColor));

  static ThemeData _darkThemeBase({Color? seedColor}) {
    final scheme = buildDarkColorScheme(seedColor: seedColor);
    return ThemeData(
      useMaterial3: true,
      switchTheme: _switchTheme,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF121220),
      pageTransitionsTheme: _backGestureSafeTransitions(),
      tabBarTheme: const TabBarThemeData(
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle:
            WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.primary),
        // 这里刻意用裸 TextStyle：主题构造期不能碰 google_fonts（需要 ServicesBinding）。
        // 字体族由 AppTheme.withGlobalFonts 在运行时补上（见那里的注释）。
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }

  static ThemeData pureBlackTheme({Color? seedColor}) =>
      _canvasStyle(_pureBlackThemeBase(seedColor: seedColor));

  static ThemeData _pureBlackThemeBase({Color? seedColor}) {
    final scheme = buildPureBlackColorScheme(seedColor: seedColor);
    return ThemeData(
      useMaterial3: true,
      switchTheme: _switchTheme,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
      pageTransitionsTheme: _backGestureSafeTransitions(),
      tabBarTheme: const TabBarThemeData(
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle:
            WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w600)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: scheme.primary),
        // 这里刻意用裸 TextStyle：主题构造期不能碰 google_fonts（需要 ServicesBinding）。
        // 字体族由 AppTheme.withGlobalFonts 在运行时补上（见那里的注释）。
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
    );
  }
}

/// 主题感知的颜色访问器 — 新代码使用这些方法替代硬编码颜色
class AppColors {
  /// 全屏音乐播放器的独立配色，对齐参考图的深色背景与浅蓝控制按钮。
  static ColorScheme musicPlayerScheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFFADC7FF),
      brightness: brightness,
    ).copyWith(
      surface: dark ? const Color(0xFF0F131B) : const Color(0xFFF8F9FF),
      onSurface: dark ? const Color(0xFFE4E6EF) : const Color(0xFF191C25),
      onSurfaceVariant:
          dark ? const Color(0xFF91949E) : const Color(0xFF5D616D),
      primary: dark ? const Color(0xFFADC7FF) : const Color(0xFF405F99),
      onPrimary: dark ? const Color(0xFF102345) : Colors.white,
      surfaceContainerHighest:
          dark ? const Color(0xFF222633) : const Color(0xFFE0E4F0),
    );
  }

  /// 主文字色（标题、重要文本）
  static Color primaryText(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFB0C4C4)
          : const Color(0xFF546161);

  /// 次要文字色（辅助文本）
  static Color secondaryText(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF9EADAD)
          : const Color(0xFF6D7D7D);

  /// 卡片/容器背景色
  static Color cardBackground(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color.fromARGB(230, 30, 30, 46)
          : Colors.white;

  /// 半透明卡片背景（叠加在背景图上）
  static Color cardBackgroundTranslucent(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color.fromARGB(200, 30, 30, 46)
          : Colors.white.withValues(alpha: 0.9);

  /// Scaffold 纯色背景（暗色模式下替代透明背景）
  static Color scaffoldBackground(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF121220)
          : Colors.transparent;

  /// 首页按钮背景色
  static Color buttonBackground(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color.fromARGB(210, 100, 100, 80)
          : const Color.fromARGB(210, 227, 232, 125);

  /// 首页按钮边框色
  static Color buttonBorder(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color.fromARGB(199, 150, 140, 120)
          : const Color.fromARGB(199, 192, 133, 100);

  /// 默认阴影
  static BoxShadow defaultShadow(Brightness brightness) =>
      brightness == Brightness.dark
          ? BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          : BoxShadow(
              color: Colors.black12,
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            );

  /// 灰色文本/图标（根据主题调整深度）
  static Color greyHint(Brightness brightness, {int shade = 500}) =>
      brightness == Brightness.dark
          ? Colors.grey.shade500
          : Colors.grey.shade600;

  /// 表格/列表边框色
  static Color tableBorder(Brightness brightness) =>
      brightness == Brightness.dark
          ? Colors.grey.shade700
          : Colors.grey.shade300;

  /// 需要清晰分区的旧表格：浅色跟随主题描边，深色保留原有格线。
  static Color readableTableBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.light
        ? theme.colorScheme.outline
        : tableBorder(theme.brightness);
  }

  /// 语义红色（错误、危险）
  static Color errorRed(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFEF5350) : Colors.red;

  /// 语义绿色（成功）
  static Color successGreen(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF66BB6A) : Colors.green;

  // ========== 猜歌游戏颜色（主题感知） ==========

  /// 猜歌 - 正确（绿色）背景色
  static Color guessCorrectBg(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF2E7D32)
          : const Color(0xFF237A45);

  /// 猜歌 - 接近（琥珀色）背景色
  static Color guessCloseBg(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFFC8921C)
          : const Color(0xFFF0B429);

  /// 猜歌 - 不符（灰色）背景色
  static Color guessWrongBg(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF4A5453)
          : const Color(0xFFDCE3E2);

  /// 猜歌 - 答案卡片背景色（游戏结束后显示正确答案的区域）
  static Color guessAnswerCardBg(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF1B3820)
          : const Color(0xFFE8F5E9);

  // -------- 柔和语义底色 / 前景（成对使用，不要只取一半） --------
  // 多人房间页原先直接用 Colors.green[100] / Colors.yellow[50] / Colors.blue[100]
  // 这类硬编码浅色：浅色主题下正常，暗色主题下就是一块亮斑，与周围深色卡片严重
  // 不搭。这里按 Brightness 分成「深底 + 浅字」的一对，两套主题都能保证对比度。

  /// 柔和成功底色（答对横幅等），配 [successForeground] 使用
  static Color successSurface(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF1B3A22)
          : const Color(0xFFE7F6E9);

  /// 柔和成功前景色（答对文字）
  static Color successForeground(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF8BD48F)
          : const Color(0xFF2E7D32);

  /// 柔和信息底色（房主变更提示等），配 [infoForeground] 使用
  static Color infoSurface(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF1B2E3F)
          : const Color(0xFFE3F2FD);

  /// 柔和信息前景色
  static Color infoForeground(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF9CC7F0)
          : const Color(0xFF1565C0);

  /// 排行榜前三名底色（暖色点缀，暗色主题下降饱和）
  static Color podiumSurface(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF37301C)
          : const Color(0xFFFFF7E0);

  /// 语义蓝色（链接、信息）
  static Color linkBlue(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF4FD8D7)
          : const Color(0xFF006A6A);

  /// 歌曲列表里的等级小方块（BASIC … Re:MASTER），白卡片上文字也看得清。
  static ({Color background, Color foreground}) difficultyBadge(
      int index, Brightness brightness) {
    const light = [
      (background: Color(0xFFDDF1E3), foreground: Color(0xFF1B5E33)),
      (background: Color(0xFFFCE9CF), foreground: Color(0xFF7A3F0B)),
      (background: Color(0xFFFAD9E4), foreground: Color(0xFF8A1F48)),
      (background: Color(0xFFE8DDF7), foreground: Color(0xFF4B2C80)),
      (background: Color(0xFFF3E8FB), foreground: Color(0xFF7B3FA0)),
    ];
    const dark = [
      (background: Color(0xFF1E3A28), foreground: Color(0xFFA8E2BA)),
      (background: Color(0xFF43301E), foreground: Color(0xFFF2C9A2)),
      (background: Color(0xFF44222F), foreground: Color(0xFFF5B5CB)),
      (background: Color(0xFF332450), foreground: Color(0xFFCDB9F2)),
      (background: Color(0xFF3F2A4F), foreground: Color(0xFFE3C7F5)),
    ];
    final list = brightness == Brightness.dark ? dark : light;
    return list[index.clamp(0, list.length - 1)];
  }

  /// 物量分布条的色块，顺序：TAP / HOLD / SLIDE / BREAK / TOUCH。
  static const List<Color> noteDistribution = [
    Color(0xFF4A8FE0),
    Color(0xFFE39B2F),
    Color(0xFF38A3A0),
    Color(0xFFD9467A),
    Color(0xFF8C6CF0),
  ];

  /// 绝赞分布条的色块，顺序：真绝赞 TAP / 真绝赞 HOLD / 保护套绝赞 / 绝赞星星。
  static const List<Color> breakDistribution = [
    Color(0xFFD9467A),
    Color(0xFFEF8FB0),
    Color(0xFF4A8FE0),
    Color(0xFFE3B02F),
  ];

  /// 连击分布条的色块（AP+ / AP / FC+ / FC / 无）。
  static Color comboDistribution(int index, Brightness brightness) {
    const light = [
      Color(0xFFE8B400),
      Color(0xFFF0CF5A),
      Color(0xFF2E9E5B),
      Color(0xFF8FD3A5),
      Color(0xFFCBD3D2),
    ];
    const dark = [
      Color(0xFFE8B400),
      Color(0xFFB99A3A),
      Color(0xFF3FA76A),
      Color(0xFF2F6B48),
      Color(0xFF4A5453),
    ];
    return (brightness == Brightness.dark ? dark : light)[index];
  }

  /// 同步分布条的色块（FDX+ / FDX / FS+ / FS / SYNC / 无）。
  static Color syncDistribution(int index, Brightness brightness) {
    const light = [
      Color(0xFFE8B400),
      Color(0xFFF0CF5A),
      Color(0xFF3F7FD9),
      Color(0xFF93BAEF),
      Color(0xFFB39DDB),
      Color(0xFFCBD3D2),
    ];
    const dark = [
      Color(0xFFE8B400),
      Color(0xFFB99A3A),
      Color(0xFF4F8DE6),
      Color(0xFF2F5C9C),
      Color(0xFF7E68B5),
      Color(0xFF4A5453),
    ];
    return (brightness == Brightness.dark ? dark : light)[index];
  }

  /// 星数分布条的色块（✦5 / ✦4 / ✦3 / ✦2 / ✦1 / ✦0）。只当色块用，不能当字色。
  static Color starDistribution(int index, Brightness brightness) {
    const light = [
      Color(0xFFE8B400),
      Color(0xFFF2994A),
      Color(0xFFF7BE8A),
      Color(0xFF66BB6A),
      Color(0xFFA5D6A7),
      Color(0xFFCBD3D2),
    ];
    const dark = [
      Color(0xFFE8B400),
      Color(0xFFE08A3C),
      Color(0xFF9C6A3C),
      Color(0xFF5FA463),
      Color(0xFF3F7043),
      Color(0xFF4A5453),
    ];
    return (brightness == Brightness.dark ? dark : light)[index];
  }

  /// 评级分布条的色块（SSS+ / SSS / SS+ / SS / 其余）。
  static Color rankDistribution(int index, Brightness brightness) {
    const light = [
      Color(0xFFE8B400),
      Color(0xFFF0CF5A),
      Color(0xFF8FA3B8),
      Color(0xFFB6C3D1),
      Color(0xFFCBD3D2),
    ];
    const dark = [
      Color(0xFFE8B400),
      Color(0xFFB99A3A),
      Color(0xFF8FA3B8),
      Color(0xFF647486),
      Color(0xFF4A5453),
    ];
    return (brightness == Brightness.dark ? dark : light)[index];
  }

  /// 功能入口的图标底色（首页「常用」、成绩 Hub 小方块、功能列表）。
  ///
  /// 四组柔和色轮换；同一个功能在任何页面都是同一个颜色（按标题取）。
  static ({Color background, Color foreground}) featureTint(
      String title, Brightness brightness) {
    final index = title.codeUnits.fold<int>(0, (a, b) => a + b) % 4;
    const light = [
      (background: Color(0xFFD5ECEB), foreground: Color(0xFF00504F)),
      (background: Color(0xFFE4E0F5), foreground: Color(0xFF4A3F86)),
      (background: Color(0xFFF6E3D3), foreground: Color(0xFF7A3F0B)),
      (background: Color(0xFFF7DCE5), foreground: Color(0xFF8A1F48)),
    ];
    const dark = [
      (background: Color(0xFF1E3A39), foreground: Color(0xFFA5DAD8)),
      (background: Color(0xFF2E2A4A), foreground: Color(0xFFC9C2F2)),
      (background: Color(0xFF43301E), foreground: Color(0xFFF2C9A2)),
      (background: Color(0xFF44222F), foreground: Color(0xFFF5B5CB)),
    ];
    return (brightness == Brightness.dark ? dark : light)[index];
  }

  /// 语义橙色（警告）
  static Color warningOrange(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFFFFB74D) : Colors.orange;

  // ========== 语义颜色（不随主题变化 — 代表游戏内固定概念） ==========

  /// 难度等级前景色（文字/边框）
  static Color difficultyForeground(String level) {
    switch (level.toUpperCase()) {
      case ChartDifficulty.basicLabel:
        return const Color(0xFF4CAF50);
      case ChartDifficulty.advancedLabel:
        return const Color(0xFFFF9800);
      case ChartDifficulty.expertLabel:
        return const Color(0xFFE91E63);
      case ChartDifficulty.masterLabel:
        return const Color(0xFF9966CC);
      case ChartDifficulty.reMasterLabel:
      case 'REMASTER':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF546161);
    }
  }

  /// 难度等级背景色（浅色用于标签/徽章背景）
  static Color difficultyBackground(String level) {
    switch (level.toUpperCase()) {
      case ChartDifficulty.basicLabel:
        return const Color(0xFFE8F5E8);
      case ChartDifficulty.advancedLabel:
        return const Color(0xFFFFF8E1);
      case ChartDifficulty.expertLabel:
        return const Color(0xFFFCE4EC);
      case ChartDifficulty.masterLabel:
        return const Color(0xFFE9D8FF);
      case ChartDifficulty.reMasterLabel:
      case 'REMASTER':
        return const Color(0xFFF3E5F5);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  /// 难度等级二级背景色（稍深，用于交替行等）
  static Color difficultySecondaryBackground(String level) {
    switch (level.toUpperCase()) {
      case ChartDifficulty.basicLabel:
        return const Color(0xFFC8E6C9);
      case ChartDifficulty.advancedLabel:
        return const Color(0xFFFFE0B2);
      case ChartDifficulty.expertLabel:
        return const Color(0xFFF8BBD0);
      case ChartDifficulty.masterLabel:
        return const Color(0xFFD4BFFF);
      case ChartDifficulty.reMasterLabel:
      case 'REMASTER':
        return const Color(0xFFE1BEE7);
      default:
        return const Color(0xFFE0E0E0);
    }
  }

  /// utage（6位ID歌曲）主题色
  static Color utageAccent({Brightness brightness = Brightness.light}) {
    return brightness == Brightness.dark
        ? const Color(0xFFFF85B9)
        : const Color(0xFFFF69B4);
  }

  static Color utageCard({Brightness brightness = Brightness.light}) {
    return brightness == Brightness.dark
        ? const Color(0xFF5C3545)
        : const Color(0xFFFFB3D1);
  }

  static Color utageBackground({Brightness brightness = Brightness.light}) {
    return brightness == Brightness.dark
        ? const Color(0xFF3D2028)
        : const Color(0xFFFFE6F0);
  }

  static Color utageDeep({Brightness brightness = Brightness.light}) {
    return brightness == Brightness.dark
        ? const Color(0xFFFF5BA0)
        : const Color(0xFFFF1493);
  }

  static Color utageTag({Brightness brightness = Brightness.light}) {
    return brightness == Brightness.dark
        ? const Color(0xFFFF85A8)
        : const Color(0xFFFF6B8B);
  }

  /// 成就徽章前景色
  static Color achievementForeground(String type) {
    switch (type.toUpperCase()) {
      case 'AP':
      case 'AP+':
        return const Color(0xFFF57C00);
      case 'FC':
      case 'FC+':
        return const Color(0xFF2E7D32);
      case 'FS':
      case 'FS+':
        return const Color(0xFF1565C0);
      case 'FDX':
      case 'FDX+':
        return const Color(0xFFF57C00);
      case 'SYNC':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF666666);
    }
  }

  /// 成就徽章背景色
  static Color achievementBackground(String type) {
    switch (type.toUpperCase()) {
      case 'AP':
      case 'AP+':
        return const Color(0xFFFFF3E0);
      case 'FC':
      case 'FC+':
        return const Color(0xFFD4F4DD);
      case 'FS':
      case 'FS+':
        return const Color(0xFFE0F4FF);
      case 'FDX':
      case 'FDX+':
        return const Color(0xFFFFF3E0);
      case 'SYNC':
        return const Color(0xFFFFE0B2);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  /// 评级颜色（**深色底专用**）
  ///
  /// ⚠️ SSS/SSS+ 返回的是 `Colors.yellow`——那是给 SongInfoPage 评级分布图
  /// 那种深色背景用的。**放在浅色卡片上几乎看不见**。
  /// 浅色底请改用 [ratingColorOnSurface]。
  static Color ratingColor(String grade) {
    switch (grade.toUpperCase().replaceAll('+', '').trim()) {
      case 'SSS':
        return Colors.yellow;
      case 'SS':
        return const Color(0xFFFFAA00);
      case 'S':
        return const Color(0xFFFF9900);
      case 'AAA':
      case 'AA':
      case 'A':
        return const Color(0xFFFF4444);
      case 'BBB':
      case 'BB':
      case 'B':
        return const Color(0xFF44AAFF);
      case 'C':
      case 'D':
        return const Color(0xFFFF4444);
      default:
        return Colors.grey;
    }
  }

  /// 评级颜色（**浅色/深色背景通用**）
  ///
  /// [ratingColor] 给 SSS 用的是纯黄，只适合深色底；这个版本按 [brightness]
  /// 给两套色值——浅色底用深一档、深色底用亮一档，两边都能看清。
  ///
  /// 传 null 或未知评级时返回中性灰，不会抛异常。
  static Color ratingColorOnSurface(String? grade, Brightness brightness) {
    if (grade == null) {
      return brightness == Brightness.dark
          ? const Color(0xFFBDBDBD)
          : const Color(0xFF757575);
    }
    final isDark = brightness == Brightness.dark;
    switch (grade.toUpperCase().replaceAll('+', '').trim()) {
      case 'SSS':
        return isDark ? const Color(0xFFFFD54F) : const Color(0xFFF9A825);
      case 'SS':
        return isDark ? const Color(0xFFFFB74D) : const Color(0xFFEF6C00);
      case 'S':
        return isDark ? const Color(0xFFFF8A65) : const Color(0xFFE65100);
      case 'AAA':
      case 'AA':
      case 'A':
        return isDark ? const Color(0xFFEF9A9A) : const Color(0xFFD32F2F);
      case 'BBB':
      case 'BB':
      case 'B':
        return isDark ? const Color(0xFF90CAF9) : const Color(0xFF1976D2);
      default:
        return isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575);
    }
  }

  /// 奖牌颜色
  static Color medalColor(String medal) {
    switch (medal.toLowerCase()) {
      case 'bronze':
      case '铜':
        return const Color(0xFFCD7F32);
      case 'silver':
      case '银':
        return const Color(0xFFC0C0C0);
      case 'gold':
      case '金':
        return const Color(0xFFFFD700);
      case 'prism':
      case 'rainbow':
      case '彩虹':
        return const Color(0xFF9400D3);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  /// 难度索引 → 前景色（通过 index 0-4）
  static Color difficultyForegroundByIndex(int index,
      {Brightness brightness = Brightness.light}) {
    if (brightness == Brightness.dark) {
      const colors = [
        Color(0xFF81C784),
        Color(0xFFFFB74D),
        Color(0xFFF06292),
        Color(0xFFBA68C8),
        Color(0xFFCE93D8),
      ];
      return colors[
          index.clamp(ChartDifficulty.basic, ChartDifficulty.reMaster)];
    }
    const colors = [
      Color(0xFF4CAF50),
      Color(0xFFFF9800),
      Color(0xFFE91E63),
      Color(0xFF9966CC),
      Color(0xFF9C27B0),
    ];
    return colors[index.clamp(ChartDifficulty.basic, ChartDifficulty.reMaster)];
  }

  /// 难度索引 → 背景色（通过 index 0-4）
  static Color difficultyBackgroundByIndex(int index,
      {Brightness brightness = Brightness.light}) {
    if (brightness == Brightness.dark) {
      const colors = [
        Color(0xFF1B3D1B),
        Color(0xFF3D2E00),
        Color(0xFF4A2020),
        Color(0xFF2A1A3D),
        Color(0xFF3D1A3D),
      ];
      return colors[
          index.clamp(ChartDifficulty.basic, ChartDifficulty.reMaster)];
    }
    const colors = [
      Color(0xFFE8F5E8),
      Color(0xFFFFF8E1),
      Color(0xFFFCE4EC),
      Color(0xFFE9D8FF),
      Color(0xFFF3E5F5),
    ];
    return colors[index.clamp(ChartDifficulty.basic, ChartDifficulty.reMaster)];
  }

  /// 难度索引 → 二级背景色（通过 index 0-4）
  static Color difficultySecondaryBgByIndex(int index,
      {Brightness brightness = Brightness.light}) {
    if (brightness == Brightness.dark) {
      const colors = [
        Color(0xFF2E5C2E),
        Color(0xFF5C4A00),
        Color(0xFF6B3030),
        Color(0xFF3D2A5C),
        Color(0xFF5C2A5C),
      ];
      return colors[
          index.clamp(ChartDifficulty.basic, ChartDifficulty.reMaster)];
    }
    const colors = [
      Color(0xFFC8E6C9),
      Color(0xFFFFE0B2),
      Color(0xFFF8BBD0),
      Color(0xFFD4BFFF),
      Color(0xFFE1BEE7),
    ];
    return colors[index.clamp(ChartDifficulty.basic, ChartDifficulty.reMaster)];
  }

  // ========== 标签分组颜色 ==========

  /// 标签分组颜色
  static Color tagGroupBackground(String group, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (group) {
      case '配置':
        return Color(dark ? 0xFF17312B : 0xFFE8F4F8);
      case '评价':
        return Color(dark ? 0xFF302414 : 0xFFFFF3E0);
      case '难度':
        return Color(dark ? 0xFF351A26 : 0xFFFCE4EC);
      default:
        return Color(dark ? 0xFF261E3B : 0xFFF0E6FF);
    }
  }

  static Color tagGroupBorder(String group, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (group) {
      case '配置':
        return Color(dark ? 0xFF2C5A4E : 0xFFD1E7DD);
      case '评价':
        return Color(dark ? 0xFF5C4420 : 0xFFFFE0B2);
      case '难度':
        return Color(dark ? 0xFF66304A : 0xFFF8BBD0);
      default:
        return Color(dark ? 0xFF4A3A72 : 0xFFE0D0FF);
    }
  }

  static Color tagGroupText(String group, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    switch (group) {
      case '配置':
        return Color(dark ? 0xFF8FD6A8 : 0xFF388E3C);
      case '评价':
        return Color(dark ? 0xFFFFC078 : 0xFFF57C00);
      case '难度':
        return Color(dark ? 0xFFF8A0C0 : 0xFFD81B60);
      default:
        return Color(dark ? 0xFFC9B3FF : 0xFF664499);
    }
  }

  // ===================================================================
  // 2026-11 UI 重构新增：评级 / 判定 / 连击 / Rating 段位 的统一配色
  // 新页面一律从这里取色，不要再在页面里写 Colors.amber / Colors.pink。
  // ===================================================================

  /// 判定色（色条、圆点用）。浅色深色通用：只作为小面积标识，不承载文字。
  /// 相邻判定在**明度**上也拉开了，不只靠色相区分（色弱友好）。
  /// KALEIDXSCOPE 各门的强调色，未知的门返回 null（用主题色）。
  static Color? kaleidGateAccent(String color, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (color) {
      'blue' => dark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      'white' => dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      'purple' => dark ? const Color(0xFFC084FC) : const Color(0xFF9333EA),
      'black' => dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
      'yellow' => dark ? const Color(0xFFFACC15) : const Color(0xFFCA8A04),
      'red' => dark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      'prism' => dark ? const Color(0xFF22D3EE) : const Color(0xFF0891B2),
      'error' => dark ? const Color(0xFFA78BFA) : const Color(0xFF8B5CF6),
      'hope' => dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      'final' => dark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
      _ => null,
    };
  }

  static const Color judgeCriticalPerfect = Color(0xFFE8B400);
  static const Color judgePerfect = Color(0xFFF0CF5A);
  static const Color judgeGreat = Color(0xFFD9467A);
  static const Color judgeGood = Color(0xFF2F8F55);
  static const Color judgeMiss = Color(0xFF8A9493);

  /// 评级徽章（SSS+ / SS / S+ ...）的底色与字色，浅色深色各一套，
  /// 两边文字对比度都 ≥ 4.5:1。
  static ({Color background, Color foreground}) rankBadge(
      String? rank, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final r = (rank ?? '').toUpperCase().trim();
    if (r == 'SSS+') {
      return (
        background: const Color(0xFFF5C542),
        foreground: const Color(0xFF2B2100)
      );
    }
    if (r == 'SSS') {
      return (
        background: const Color(0xFFF7DE8C),
        foreground: const Color(0xFF2B2100)
      );
    }
    if (r.startsWith('SS')) {
      return dark
          ? (
              background: const Color(0xFF3A4652),
              foreground: const Color(0xFFE3EAF2)
            )
          : (
              background: const Color(0xFFDCE3EA),
              foreground: const Color(0xFF1F2A36)
            );
    }
    if (r.startsWith('S')) {
      return dark
          ? (
              background: const Color(0xFF5A3A24),
              foreground: const Color(0xFFFFDCC6)
            )
          : (
              background: const Color(0xFFF6D2BA),
              foreground: const Color(0xFF4A1F00)
            );
    }
    if (r.startsWith('A')) {
      return dark
          ? (
              background: const Color(0xFF5A2A2A),
              foreground: const Color(0xFFFFD9D9)
            )
          : (
              background: const Color(0xFFF4D6D6),
              foreground: const Color(0xFF6B1A1A)
            );
    }
    return dark
        ? (
            background: const Color(0xFF3A4241),
            foreground: const Color(0xFFDCE3E2)
          )
        : (
            background: const Color(0xFFE1E7E6),
            foreground: const Color(0xFF3F4948)
          );
  }

  /// 连击徽章（FC / FC+ / AP / AP+）。AP 系用金色，FC 系用绿色。
  static ({Color background, Color foreground}) comboBadge(
      String? combo, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final c = (combo ?? '').toLowerCase();
    if (c.startsWith('ap')) {
      return dark
          ? (
              background: const Color(0xFF4A3D10),
              foreground: const Color(0xFFF7DE8C)
            )
          : (
              background: const Color(0xFFF7DE8C),
              foreground: const Color(0xFF3D2E00)
            );
    }
    return dark
        ? (
            background: const Color(0xFF1E3A28),
            foreground: const Color(0xFFA8E2BA)
          )
        : (
            background: const Color(0xFFDDF1E3),
            foreground: const Color(0xFF1B5E33)
          );
  }

  /// 同步徽章（FS / FS+ / FDX / FDX+ / SYNC）。
  static ({Color background, Color foreground}) syncBadge(
      Brightness brightness) {
    return brightness == Brightness.dark
        ? (
            background: const Color(0xFF1F3047),
            foreground: const Color(0xFFB8D3F7)
          )
        : (
            background: const Color(0xFFDCE8FA),
            foreground: const Color(0xFF1F4F8F)
          );
  }

  /// Rating 段位（对应游戏里 Rating 框的颜色），用于首页总 Rating 旁的小标识。
  ///
  /// [colors] 至少两个色值，用于渐变；[foreground] 是压在渐变上的文字色。
  static ({String label, List<Color> colors, Color foreground}) ratingTier(
      int rating) {
    const dark = Color(0xFF1F1A10);
    const light = Color(0xFFFFFFFF);
    if (rating >= 15000) {
      return (
        label: appL10n.featureRainbow,
        colors: const [
          Color(0xFFFF5A5A),
          Color(0xFFFFB23F),
          Color(0xFF5BD48A),
          Color(0xFF45B6F0),
          Color(0xFF8C6CF0),
        ],
        foreground: light
      );
    }
    if (rating >= 14500) {
      return (
        label: appL10n.featurePlatinum,
        colors: const [Color(0xFFEDE8D8), Color(0xFFC9C2A8)],
        foreground: dark
      );
    }
    if (rating >= 14000) {
      return (
        label: appL10n.featureGold,
        colors: const [Color(0xFFF5C542), Color(0xFFD9A21B)],
        foreground: dark
      );
    }
    if (rating >= 13000) {
      return (
        label: appL10n.featureSilver,
        colors: const [Color(0xFFDDE3E8), Color(0xFFA9B3BC)],
        foreground: dark
      );
    }
    if (rating >= 12000) {
      return (
        label: appL10n.featureBronze,
        colors: const [Color(0xFFD9A27A), Color(0xFFA86B43)],
        foreground: dark
      );
    }
    if (rating >= 10000) {
      return (
        label: appL10n.featurePurple,
        colors: const [Color(0xFF9C76E0), Color(0xFF6A45A8)],
        foreground: light
      );
    }
    if (rating >= 7000) {
      return (
        label: appL10n.featureRed,
        colors: const [Color(0xFFE06060), Color(0xFFB03030)],
        foreground: light
      );
    }
    if (rating >= 4000) {
      return (
        label: appL10n.flowYellow,
        colors: const [Color(0xFFF5D45A), Color(0xFFE0B020)],
        foreground: dark
      );
    }
    if (rating >= 2000) {
      return (
        label: appL10n.featureGreen,
        colors: const [Color(0xFF5FBF7E), Color(0xFF2F8F55)],
        foreground: light
      );
    }
    if (rating >= 1000) {
      return (
        label: appL10n.featureBlue,
        colors: const [Color(0xFF5E9BE0), Color(0xFF2F6FB8)],
        foreground: light
      );
    }
    return (
      label: appL10n.featureWhite,
      colors: const [Color(0xFFF2F2F2), Color(0xFFD0D0D0)],
      foreground: dark
    );
  }
}
