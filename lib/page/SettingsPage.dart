import '../l10n/LocalizationsExtension.dart';
import '../utils/AppLanguagePreferences.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../service/AWMC/AwmcGatewaySettings.dart';
import '../utils/AppTheme.dart';
import '../utils/ConfettiPreferences.dart';
import '../utils/ExportSettings.dart';
import '../utils/NavigationPreferences.dart';
import '../utils/ThemeManager.dart';
import '../utils/SystemWallpaperColor.dart';
import '../utils/RatingSegmentPreferences.dart';
import '../utils/SearchInteractionPreferences.dart';
import '../widgets/AnimatedChoiceBar.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/GuessSettingsUi.dart';
import '../widgets/ThemeAwareBackground.dart';
import '../widgets/AppColorPickerDialog.dart';
import '../widgets/ThemePreferenceControls.dart';
import 'OnboardingPage.dart';
import 'WallpaperCropPage.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppSwitch.dart';
import '../widgets/AppUpdateAutoInstallControl.dart';
import '../widgets/SongDetailDifficultySettings.dart';

/// 设置页（独立页面，从首页主题弹窗"更多设置"进入）
///
/// 提供：
///   - 主题色：8 个预设色 + 自定义 ColorPicker；通过 `ColorScheme.fromSeed`
///     派生整套配色，主色变化时 60+ 页面同步更新
///   - 背景图：从相册选图，复制到应用文档目录持久化；可恢复默认 asset
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ImagePicker _picker = ImagePicker();
  bool _pickingImage = false;
  bool _readingSystemWallpaperColor = false;
  int _tab = 0;
  final ScrollController _scrollController = ScrollController();

  /// AWMC 网关同步前探活超时（秒）。默认 15 秒，见「同步与网关」分区。
  int _awmcProbeTimeoutSeconds = AwmcGatewaySettings.defaultProbeTimeoutSeconds;

  @override
  void initState() {
    super.initState();
    AppLanguagePreferences.instance.load();
    SearchInteractionPreferences.instance.load();
    RatingSegmentPreferences.instance.load();
    NavigationPreferences.instance.load();
    ConfettiPreferences.instance.load();
    AwmcGatewaySettings.loadProbeTimeoutSeconds().then((seconds) {
      if (mounted) setState(() => _awmcProbeTimeoutSeconds = seconds);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _backgroundsDisabled =>
      Theme.of(context).brightness == Brightness.dark &&
      ThemeManager().pureBlackEnabled;

  /// 预设色板（覆盖常见色调；保留原默认灰青作为第一位）
  static const List<Color> _presetColors = [
    Color(0xFF006A6A), // 默认青绿
    Color(0xFF1976D2), // 蓝
    Color(0xFF388E3C), // 绿
    Color(0xFF7B1FA2), // 紫
    Color(0xFFE65100), // 橙
    Color(0xFFC2185B), // 粉
    Color(0xFFD32F2F), // 红
    Color(0xFF00796B), // 青
  ];

  // ============ 图片操作 ============

  /// 清空 custom_bg 目录下的旧壁纸文件（background.* 和 background_*），[keep] 除外
  /// 避免旧文件残留 + Flutter ImageCache 命中同一 path 时的解码陈旧
  Future<void> _clearOldBackgroundFiles(Directory dir, {String? keep}) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File &&
          entity.path != keep &&
          p.basename(entity.path).toLowerCase().startsWith('background')) {
        try {
          // 同步 evict Flutter 解码缓存
          PaintingBinding.instance.imageCache
              .evict(FileImage(entity), includeLive: true);
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _pickBackground() async {
    if (_pickingImage || _readingSystemWallpaperColor || _backgroundsDisabled) {
      return;
    }
    setState(() => _pickingImage = true);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2560,
        maxHeight: 2560,
      );
      if (photo == null || !mounted || _backgroundsDisabled) return;

      // 先裁剪，确认后才写入；取消时旧壁纸不受影响。
      final cropped = await Navigator.of(context).push<Uint8List>(
        MaterialPageRoute(
            builder: (_) => WallpaperCropPage(imagePath: photo.path)),
      );
      if (cropped == null || !mounted || _backgroundsDisabled) return;

      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'custom_bg'));
      if (!await dir.exists()) await dir.create(recursive: true);

      // 每次用新文件名：新壁纸写好并生效后才清理旧文件，
      // 中途失败不会丢掉旧壁纸，也不用处理同路径的解码缓存。
      final destPath = p.join(
          dir.path, 'background_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(destPath).writeAsBytes(cropped, flush: true);

      await ThemeManager().setCustomBackgroundPath(destPath);
      await _clearOldBackgroundFiles(dir, keep: destPath);
      final themed = await _applyWallpaperThemeColor(destPath);
      if (mounted) {
        AppToast.show(themed
            ? context.l10n.wallpaperAndThemeApplied
            : context.l10n.wallpaperApplied);
      }
    } catch (e) {
      if (mounted) AppToast.show(context.l10n.picturePickFailed('$e'));
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  /// 从新壁纸取色并设为主题色，失败时保留原主题色。
  ///
  /// 取色是纯 Dart 算法（`ColorScheme.fromImageProvider`），不依赖系统的动态取色，
  /// Android 各版本和 iOS 行为一致；图片先缩小再取色，不会卡界面。
  Future<bool> _applyWallpaperThemeColor(String path) async {
    try {
      final scheme = await ColorScheme.fromImageProvider(
        provider: ResizeImage(FileImage(File(path)), width: 128),
      );
      await ThemeManager().setSeedColor(scheme.primary);
      return true;
    } catch (e) {
      debugPrint('壁纸取色失败: $e');
      return false;
    }
  }

  /// 手动应用一次系统配色，并复用现有主题色的持久化流程。
  Future<void> _useSystemWallpaperColor() async {
    if (_readingSystemWallpaperColor || _pickingImage) return;
    final previousSeed = ThemeManager().seedColor;
    setState(() => _readingSystemWallpaperColor = true);
    try {
      final color = await SystemWallpaperColor.read();
      // 离页或用户已选择其他主题色时，丢弃这次迟到的结果。
      if (!mounted || ThemeManager().seedColor != previousSeed) return;
      if (color == null) {
        AppToast.show(context.l10n.wallpaperColorUnsupported);
        return;
      }
      await ThemeManager().setSeedColor(color);
      if (mounted) AppToast.show(context.l10n.wallpaperColorApplied);
    } catch (e) {
      debugPrint('读取系统壁纸配色失败: $e');
      if (mounted) AppToast.show(context.l10n.wallpaperColorFailed);
    } finally {
      if (mounted) setState(() => _readingSystemWallpaperColor = false);
    }
  }

  Future<void> _resetBackground() async {
    final current = ThemeManager().customBackgroundPath;
    await ThemeManager().setCustomBackgroundPath(null);
    // 删除已选文件 + evict 缓存
    if (current != null) {
      try {
        PaintingBinding.instance.imageCache
            .evict(FileImage(File(current)), includeLive: true);
        final f = File(current);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    // 同时清理目录下其他残留 background.*
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'custom_bg'));
      await _clearOldBackgroundFiles(dir);
    } catch (_) {}
    if (mounted) AppToast.show(context.l10n.backgroundReset);
  }

  // ============ 主题色操作 ============

  /// 弹出取色器选自定义主题色。
  ///
  /// 这里**换掉了 `flutter_colorpicker` 的 `ColorPicker`**：那个组件的取色区
  /// 宽度写死 `colorPickerWidth: 300`（见 colorpicker.dart 的 build），
  /// 而 AlertDialog 在手机上给 content 的宽度只有 280-40 ≈ 240dp ——
  /// 于是取色区**横向溢出**，右边一大块被裁掉/摸不到，用户只能在少数几个
  /// 恰好落在可见区域的位置取到色，表现就是「取色器用不了，只能用预设色」。
  ///
  /// 现在复用 `AppColorPickerDialog.dart`：宽度自适应，
  /// 颜色存在 dialog 自己的 state 里（不依赖外层闭包变量），拖动即刷新预览。
  Future<void> _pickCustomColor() async {
    final picked = await showAppColorPicker(
      context,
      title: context.l10n.customColor,
      initial: ThemeManager().seedColor ?? AppTheme.defaultLightSeed,
    );
    if (mounted && picked != null) {
      await ThemeManager().setSeedColor(picked);
      if (mounted) AppToast.show(context.l10n.themeColorUpdated);
    }
  }

  /// 恢复默认主题色。
  Future<void> _resetSeed() async {
    await ThemeManager().setSeedColor(null);
    if (mounted) AppToast.show(context.l10n.themeColorReset);
  }

  Widget _buildSearchInteractionSettings() {
    final preferences = SearchInteractionPreferences.instance;
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.homeSearchScope, style: TextStyle(fontSize: 13.5)),
          const SizedBox(height: 8),
          AnimatedChoiceBar<HomeSearchScope>(
            values: HomeSearchScope.values,
            value: preferences.homeSearchScope,
            label: (scope) => switch (scope) {
              HomeSearchScope.feature => context.l10n.searchFeatures,
              HomeSearchScope.song => context.l10n.searchSongs,
              HomeSearchScope.both => context.l10n.searchBoth,
            },
            onChanged: preferences.loaded
                ? (scope) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    preferences.setHomeSearchScope(scope);
                  }
                : null,
          ),
          const SizedBox(height: 12),
          Text(context.l10n.searchMode, style: TextStyle(fontSize: 13.5)),
          const SizedBox(height: 8),
          AnimatedChoiceBar<SearchInteractionMode>(
            values: SearchInteractionMode.values,
            value: preferences.mode,
            label: (mode) => mode == SearchInteractionMode.inline
                ? context.l10n.searchInline
                : context.l10n.searchOverlay,
            onChanged: preferences.loaded
                ? (mode) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    preferences.setMode(mode);
                  }
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            preferences.usesOverlay
                ? context.l10n.searchOverlayHint
                : context.l10n.searchInlineHint,
            style: _hintStyle(),
          ),
          const SizedBox(height: 8),
          AppSwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: preferences.showMatchInfo,
            onChanged: preferences.loaded ? preferences.setShowMatchInfo : null,
            secondary: Icon(Icons.manage_search_rounded,
                color: Theme.of(context).colorScheme.primary),
            title: Text(context.l10n.showMatchInfo),
            subtitle: Text(context.l10n.showMatchInfoHint),
          ),
          AppSwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: preferences.avoidKeyboard,
            onChanged: preferences.loaded ? preferences.setAvoidKeyboard : null,
            secondary: Icon(Icons.keyboard_alt_outlined,
                color: Theme.of(context).colorScheme.primary),
            title: Text(context.l10n.searchAvoidKeyboard),
            subtitle: Text(context.l10n.searchAvoidKeyboardHint),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSegmentSettings() {
    final preferences = RatingSegmentPreferences.instance;
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedChoiceBar<RatingSegmentMode>(
            values: RatingSegmentMode.values,
            value: preferences.mode,
            label: (mode) => mode == RatingSegmentMode.standard
                ? context.l10n.ratingSegmentStandard
                : context.l10n.ratingSegmentDetailed,
            onChanged: preferences.loaded ? preferences.setMode : null,
          ),
          const SizedBox(height: 8),
          Text(
            preferences.isDetailed
                ? context.l10n.ratingSegmentDetailedHint
                : context.l10n.ratingSegmentStandardHint,
            style: _hintStyle(),
          ),
        ],
      ),
    );
  }

  // ============ UI ============

  TextStyle _hintStyle() => TextStyle(
        fontSize: 12,
        height: 1.45,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  void _selectTab(int index) {
    if (index == _tab) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = index);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final motion =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return BackgroundPageScaffold(
      title: context.l10n.settingsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
            child: SegmentedTabs(
              height: 42,
              items: [
                SegmentedTabItem(context.l10n.appearance),
                SegmentedTabItem(context.l10n.interaction),
                SegmentedTabItem(context.l10n.effects),
                SegmentedTabItem(context.l10n.other),
              ],
              selectedIndex: _tab,
              onChanged: _selectTab,
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([
                ThemeManager().seedColorNotifier,
                ThemeManager().customBackgroundPathNotifier,
                ThemeManager().chiffonOpacityNotifier,
                ThemeManager().pureBlackNotifier,
                ThemeManager().notifier,
              ]),
              builder: (context, _) => ListView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                    AppDesignTokens.gutter,
                    4,
                    AppDesignTokens.gutter,
                    16 + MediaQuery.paddingOf(context).bottom),
                children: [
                  AnimatedSize(
                    duration: motion,
                    curve: AppDesignTokens.emphasizedCurve,
                    alignment: Alignment.topCenter,
                    child: FadeSwitcher(
                      value: _tab,
                      sizeFollowsCurrent: true,
                      alignment: Alignment.topCenter,
                      child: switch (_tab) {
                        0 => _buildAppearanceTab(),
                        1 => _buildInteractionTab(),
                        2 => _buildEffectsTab(),
                        _ => _buildOtherTab(),
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabColumn(List<Widget> sections) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, section) in sections.indexed)
            EntranceAnimation(
              index: index,
              offset: const Offset(0, 10),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: index == sections.length - 1
                        ? 0
                        : AppDesignTokens.cardGap),
                child: section,
              ),
            ),
        ],
      );

  Widget _buildAppearanceTab() {
    final disabled = _backgroundsDisabled;
    Widget backgroundControl(Widget child) => AbsorbPointer(
          absorbing: disabled,
          child: ExcludeFocus(
            excluding: disabled,
            child: AnimatedOpacity(
              opacity: disabled ? 0.38 : 1,
              duration:
                  AppDesignTokens.motion(context, AppDesignTokens.fastMotion),
              child: child,
            ),
          ),
        );
    return _tabColumn([
      _buildPreviewCard(),
      GuessSettingSection(
        card: true,
        title: context.l10n.themeMode,
        icon: Icons.contrast_rounded,
        children: [ThemeModeControl()],
      ),
      GuessSettingSection(
        card: true,
        title: context.l10n.themeColor,
        icon: Icons.palette_outlined,
        children: [_buildColorPalette()],
      ),
      GuessSettingSection(
        card: true,
        title: context.l10n.backgroundImage,
        icon: Icons.wallpaper_rounded,
        children: [
          if (disabled)
            Text(context.l10n.pureBlackBackgroundDisabled, style: _hintStyle()),
          backgroundControl(_buildBackgroundControls(enabled: !disabled)),
          if (Platform.isAndroid) ...[
            OutlinedButton.icon(
              onPressed: _readingSystemWallpaperColor || _pickingImage
                  ? null
                  : _useSystemWallpaperColor,
              icon: _readingSystemWallpaperColor
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.palette_outlined, size: 18),
              label: Text(_readingSystemWallpaperColor
                  ? context.l10n.reading
                  : context.l10n.useSystemWallpaperColor),
            ),
            Text(context.l10n.systemWallpaperHint, style: _hintStyle()),
          ],
          const BackgroundOverlayControl(),
        ],
      ),
      backgroundControl(GuessSettingSection(
        card: true,
        title: context.l10n.decorationImage,
        icon: Icons.auto_awesome_outlined,
        children: [_buildChiffonControls(enabled: !disabled)],
      )),
    ]);
  }

  Widget _buildInteractionTab() => _tabColumn([
        const SongDetailDifficultySettings(),
        GuessSettingSection(
          card: true,
          title: context.l10n.ratingSegmentTitle,
          icon: Icons.stacked_line_chart_rounded,
          children: [_buildRatingSegmentSettings()],
        ),
        GuessSettingSection(
          card: true,
          title: context.l10n.navigationExperience,
          icon: Icons.navigation_outlined,
          children: [NavigationControls()],
        ),
        GuessSettingSection(
          card: true,
          title: context.l10n.searchInteraction,
          icon: Icons.search_rounded,
          children: [_buildSearchInteractionSettings()],
        ),
      ]);

  Widget _buildEffectsTab() => _tabColumn([
        GuessSettingSection(
          card: true,
          title: context.l10n.confetti,
          icon: Icons.celebration_outlined,
          children: [ConfettiControls()],
        ),
      ]);

  Widget _buildOtherTab() => _tabColumn([
        _buildLanguageSection(),
        if (Platform.isAndroid)
          GuessSettingSection(
            card: true,
            title: context.l10n.appUpdate,
            icon: Icons.system_update_rounded,
            children: [AppUpdateAutoInstallControl()],
          ),
        GuessSettingSection(
          card: true,
          title: context.l10n.featureGuide,
          icon: Icons.menu_book_outlined,
          children: [
            Text(context.l10n.featureGuideHint, style: _hintStyle()),
            SizedBox(
              height: 46,
              child: FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OnboardingPage(),
                    ),
                  );
                },
                child: Text(context.l10n.reopenGuide),
              ),
            ),
          ],
        ),
        _buildExportSection(),
        _buildAwmcGatewaySection(),
      ]);

  Widget _buildLanguageSection() {
    final preferences = AppLanguagePreferences.instance;
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => GuessSettingSection(
        card: true,
        title: context.l10n.language,
        icon: Icons.language_rounded,
        children: [
          AppDialogOption(
            title: preferences.language.nativeName ?? context.l10n.followSystem,
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: preferences.loaded ? _chooseLanguage : null,
          ),
          Text(context.l10n.languageDescription, style: _hintStyle()),
          Text(context.l10n.languageTranslationDisclaimer,
              style: _hintStyle()),
        ],
      ),
    );
  }

  Future<void> _chooseLanguage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final preferences = AppLanguagePreferences.instance;
    final picked = await showDialog<AppLanguage>(
      context: context,
      builder: (dialogContext) => AppAlertDialog(
        title: Text(dialogContext.l10n.language),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final language in AppLanguage.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppDialogOption(
                    title:
                        language.nativeName ?? dialogContext.l10n.followSystem,
                    selected: language == preferences.language,
                    leading: Icon(language == preferences.language
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded),
                    onTap: () => Navigator.pop(dialogContext, language),
                  ),
                ),
              // 翻译准确性声明：非简体中文均为翻译文本。
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  dialogContext.l10n.languageTranslationDisclaimer,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Theme.of(dialogContext)
                          .colorScheme
                          .onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.cancel),
          )
        ],
      ),
    );
    if (picked == null || !mounted) return;
    final saved = await preferences.setLanguage(picked);
    if (!saved && mounted) AppToast.show(context.l10n.languageSaveFailed);
  }

  /// 实时预览：直接用页面背景组件，背景图、覆层、装饰图和主题色都是真实效果。
  Widget _buildPreviewCard() {
    final scheme = Theme.of(context).colorScheme;
    Widget swatch(String label, Color color) => Expanded(
          child: Column(
            children: [
              Container(
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                  border: Border.all(color: scheme.outlineVariant),
                ),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ],
          ),
        );
    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: ColoredBox(
                color: scheme.surface,
                child: ThemeAwareBackground(
                  child: Center(
                    child: Container(
                      width: 210,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppSurfaces.card(context),
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusCard),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(context.l10n.preview,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(
                            'ChiffonMai',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusSmall),
                            ),
                            child: Text(context.l10n.primaryButton,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              swatch(context.l10n.primaryColor, scheme.primary),
              const SizedBox(width: 8),
              swatch(context.l10n.secondaryColor, scheme.secondary),
              const SizedBox(width: 8),
              swatch(context.l10n.tertiaryColor, scheme.tertiary),
              const SizedBox(width: 8),
              swatch(context.l10n.surfaceColor, scheme.surface),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette() {
    final scheme = Theme.of(context).colorScheme;
    final current = ThemeManager().seedColor;
    final customSelected = current != null &&
        !_presetColors.any((c) => c.toARGB32() == current.toARGB32());
    Widget dot(double size, Color color, bool selected, VoidCallback onTap) =>
        PressScale(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration:
                  AppDesignTokens.motion(context, AppDesignTokens.fastMotion),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? scheme.onSurface : scheme.outlineVariant,
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: ThemeData.estimateBrightnessForColor(color) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    )
                  : null,
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 色点按可用宽度缩放，始终排在一行
        LayoutBuilder(builder: (context, constraints) {
          const gap = 8.0;
          final count = _presetColors.length + (customSelected ? 1 : 0);
          final size = ((constraints.maxWidth - gap * (count - 1)) / count)
              .floorToDouble()
              .clamp(24.0, 40.0);
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final (index, color) in _presetColors.indexed)
                dot(
                  size,
                  color,
                  // 没有自定义过时第一个就是默认色
                  current == null
                      ? index == 0
                      : current.toARGB32() == color.toARGB32(),
                  () async {
                    await ThemeManager().setSeedColor(color);
                    if (mounted) AppToast.show(context.l10n.themeColorUpdated);
                  },
                ),
              if (customSelected) dot(size, current, true, _pickCustomColor),
            ],
          );
        }),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickCustomColor,
                icon: const Icon(Icons.colorize_rounded, size: 18),
                label: Text(context.l10n.customColor),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: current == null ? null : _resetSeed,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.l10n.restoreDefaults),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundControls({required bool enabled}) {
    final scheme = Theme.of(context).colorScheme;
    final bgPath = ThemeManager().customBackgroundPath;
    Widget thumbnail() => Image.asset('assets/background.png',
        fit: BoxFit.cover,
        cacheWidth: 240,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => ColoredBox(color: scheme.surface));
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          child: SizedBox(
            width: 72,
            height: 100,
            child: bgPath == null
                ? thumbnail()
                : Image.file(
                    File(bgPath),
                    key: ValueKey(bgPath),
                    fit: BoxFit.cover,
                    cacheWidth: 240,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => thumbnail(),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bgPath == null
                    ? context.l10n.builtInBackground
                    : context.l10n.customBackground,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    !enabled || _pickingImage || _readingSystemWallpaperColor
                        ? null
                        : _pickBackground,
                icon: _pickingImage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_outlined, size: 18),
                label: Text(_pickingImage
                    ? context.l10n.processing
                    : context.l10n.chooseFromGallery),
              ),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: !enabled || bgPath == null ? null : _resetBackground,
                icon: const Icon(Icons.restore_rounded, size: 18),
                label: Text(context.l10n.restoreDefaults),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChiffonControls({required bool enabled}) {
    final opacity = ThemeManager().chiffonOpacity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuessSliderTile(
          label: context.l10n.decorationOpacity,
          valueText: '${(opacity * 100).round()}%',
          value: opacity,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: enabled ? ThemeManager().setChiffonOpacity : null,
          hint: context.l10n.decorationOpacityHint,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !enabled || opacity == 0.0
                    ? null
                    : () => ThemeManager().setChiffonOpacity(0.0),
                icon: const Icon(Icons.visibility_off_outlined, size: 18),
                label: Text(context.l10n.hide),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !enabled
                    ? null
                    : () => ThemeManager().setChiffonOpacity(0.40),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.l10n.restoreDefaults),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 导出说明。
  ///
  /// 这里**曾经**是「收藏夹导出后缀」的输入框，现已取消自定义：
  /// 用户把后缀改成 `.json` / `.zip` 这类常见后缀后，系统会把本 App 记成
  /// 该类型文件的默认/首要打开方式，等于劫持了这些后缀（见 ExportSettings 注释）。
  /// 后缀固定为 `.cmf`，所以这里只剩一段只读说明，告诉用户文件落在哪。
  Widget _buildExportSection() {
    final scheme = Theme.of(context).colorScheme;
    return GuessSettingSection(
      card: true,
      title: context.l10n.favoriteExportExtension,
      icon: Icons.description_outlined,
      // 固定值，只读展示（不让改，避免劫持常见后缀的打开方式）
      trailing: AppBadge(
        text: ExportSettings.favoriteExtensionWithDot,
        background: scheme.primary.withValues(alpha: 0.12),
        foreground: scheme.primary,
        fontSize: 13,
      ),
      children: [
        Text(
          context.l10n
              .exportDescription(ExportSettings.favoriteExtensionWithDot),
          style: _hintStyle(),
        ),
      ],
    );
  }

  // ============ 同步与网关 ============

  /// AWMC 网关「同步前探活」超时设置。
  Widget _buildAwmcGatewaySection() {
    final scheme = Theme.of(context).colorScheme;
    return GuessSettingSection(
      card: true,
      title: context.l10n.syncAndGateway,
      icon: Icons.sync_alt_rounded,
      children: [
        Semantics(
          button: true,
          label: context.l10n.gatewayTimeoutSemantics(_awmcProbeTimeoutSeconds),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _editAwmcProbeTimeout,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.gatewayTimeout,
                      style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
                    ),
                  ),
                  Text(
                    context.l10n.secondsValue(_awmcProbeTimeoutSeconds),
                    style: AppTheme.number(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        Text(
          context.l10n.gatewayTimeoutHint,
          style: _hintStyle(),
        ),
      ],
    );
  }

  Future<void> _editAwmcProbeTimeout() async {
    final seconds = await showDialog<int>(
      context: context,
      builder: (_) =>
          _AwmcProbeTimeoutDialog(initial: _awmcProbeTimeoutSeconds),
    );
    if (seconds == null || !mounted) return;
    await AwmcGatewaySettings.saveProbeTimeoutSeconds(seconds);
    if (!mounted) return;
    setState(() =>
        _awmcProbeTimeoutSeconds = AwmcGatewaySettings.clampSeconds(seconds));
    AppToast.show(context.l10n.gatewayTimeoutSaved(_awmcProbeTimeoutSeconds));
  }
}

/// AWMC 网关检测超时的输入对话框（默认 15 秒，允许 5–60 秒）。
class _AwmcProbeTimeoutDialog extends StatefulWidget {
  final int initial;

  const _AwmcProbeTimeoutDialog({required this.initial});

  @override
  State<_AwmcProbeTimeoutDialog> createState() =>
      _AwmcProbeTimeoutDialogState();
}

class _AwmcProbeTimeoutDialogState extends State<_AwmcProbeTimeoutDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.initial}');
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null) {
      setState(() => _error = context.l10n.enterIntegerSeconds);
      return;
    }
    if (parsed < AwmcGatewaySettings.minProbeTimeoutSeconds ||
        parsed > AwmcGatewaySettings.maxProbeTimeoutSeconds) {
      setState(() => _error = context.l10n.allowedSeconds(
          AwmcGatewaySettings.minProbeTimeoutSeconds,
          AwmcGatewaySettings.maxProbeTimeoutSeconds));
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AppAlertDialog(
      title: Text(context.l10n.gatewayTimeout),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.gatewayTimeoutDialogHint,
            style: TextStyle(fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: context.l10n.timeout,
              suffixText: context.l10n.secondsUnit,
              helperText: context.l10n.defaultSecondsHint(
                  AwmcGatewaySettings.defaultProbeTimeoutSeconds,
                  AwmcGatewaySettings.minProbeTimeoutSeconds,
                  AwmcGatewaySettings.maxProbeTimeoutSeconds),
              errorText: _error,
            ).insetLabel(context),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
              context, AwmcGatewaySettings.defaultProbeTimeoutSeconds),
          child: Text(context.l10n.restoreDefaults),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.l10n.save)),
      ],
    );
  }
}
