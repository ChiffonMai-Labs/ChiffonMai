import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../service/AWMC/AwmcGatewaySettings.dart';
import '../utils/AppTheme.dart';
import '../utils/CommonWidgetUtil.dart';
import '../utils/ExportSettings.dart';
import '../utils/ThemeManager.dart';
import '../utils/SearchInteractionPreferences.dart';
import '../widgets/AnimatedChoiceBar.dart';
import '../widgets/PageTopBar.dart';
import '../widgets/AppColorPickerDialog.dart';
import '../widgets/ThemePreferenceControls.dart';
import 'OnboardingPage.dart';

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

  /// AWMC 网关同步前探活超时（秒）。默认 15 秒，见「同步与网关」分区。
  int _awmcProbeTimeoutSeconds = AwmcGatewaySettings.defaultProbeTimeoutSeconds;

  @override
  void initState() {
    super.initState();
    SearchInteractionPreferences.instance.load();
    AwmcGatewaySettings.loadProbeTimeoutSeconds().then((seconds) {
      if (mounted) setState(() => _awmcProbeTimeoutSeconds = seconds);
    });
  }

  bool get _backgroundsDisabled =>
      Theme.of(context).brightness == Brightness.dark &&
      ThemeManager().pureBlackEnabled;

  /// 预设色板（覆盖常见色调；保留原默认灰青作为第一位）
  static const List<Color> _presetColors = [
    Color(0xFF546161), // 默认灰青
    Color(0xFF1976D2), // 蓝
    Color(0xFF388E3C), // 绿
    Color(0xFF7B1FA2), // 紫
    Color(0xFFE65100), // 橙
    Color(0xFFC2185B), // 粉
    Color(0xFFD32F2F), // 红
    Color(0xFF00796B), // 青
  ];

  // ============ 图片操作 ============

  /// 清空 custom_bg 目录下所有 background.* 文件
  /// 避免旧文件残留 + Flutter ImageCache 命中同一 path 时的解码陈旧
  Future<void> _clearOldBackgroundFiles(Directory dir) async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File &&
          p.basename(entity.path).toLowerCase().startsWith('background.')) {
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
    if (_pickingImage || _backgroundsDisabled) return;
    setState(() => _pickingImage = true);
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2560,
        maxHeight: 2560,
      );
      if (photo == null || !mounted || _backgroundsDisabled) return;

      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'custom_bg'));
      if (!await dir.exists()) await dir.create(recursive: true);

      // 先清空目录下所有旧 background.* 文件（包括当前生效的）
      // 原因 1：File.copy 在目标已存在时会抛异常；
      // 原因 2：Flutter ImageCache 按 path 缓存解码图，必须 evict 才能显示新内容
      final oldPath = ThemeManager().customBackgroundPath;
      if (oldPath != null) {
        PaintingBinding.instance.imageCache
            .evict(FileImage(File(oldPath)), includeLive: true);
      }
      await _clearOldBackgroundFiles(dir);

      final ext =
          p.extension(photo.path).isNotEmpty ? p.extension(photo.path) : '.jpg';
      final destPath = p.join(dir.path, 'background$ext');
      final destFile = File(destPath);

      // 先 writeAsBytes（覆盖写）而非 copy，避免同 path 残留时静默失败
      final bytes = await File(photo.path).readAsBytes();
      await destFile.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      await ThemeManager().setCustomBackgroundPath(destPath);
      if (mounted) {
        Fluttertoast.showToast(msg: '背景图已设置');
      }
    } catch (e) {
      if (mounted) Fluttertoast.showToast(msg: '选择图片失败: $e');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
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
    if (mounted) Fluttertoast.showToast(msg: '已恢复默认背景');
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
      title: '自定义主题色',
      initial: ThemeManager().seedColor ?? AppTheme.defaultLightSeed,
    );
    if (mounted && picked != null) {
      await ThemeManager().setSeedColor(picked);
      if (mounted) Fluttertoast.showToast(msg: '主题色已更新');
    }
  }

  /// 恢复默认主题色。
  Future<void> _resetSeed() async {
    await ThemeManager().setSeedColor(null);
    if (mounted) Fluttertoast.showToast(msg: '已恢复默认主题色');
  }

  Widget _buildSearchInteractionSettings() {
    final preferences = SearchInteractionPreferences.instance;
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('搜索框交互', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          AnimatedChoiceBar<SearchInteractionMode>(
            values: SearchInteractionMode.values,
            value: preferences.mode,
            label: (mode) =>
                mode == SearchInteractionMode.inline ? '原位输入' : '展开搜索',
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
                ? '首页功能和歌曲搜索使用展开搜索界面（当前默认）'
                : '直接在原搜索框输入，歌曲搜索历史显示在搜索框下方',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final c = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const SizedBox.expand()),
          CommonWidgetUtil.buildCommonBgWidget(),
          CommonWidgetUtil.buildCommonChiffonBgWidget(context),
          Column(
            children: [
              _buildTitleBar(sw, c),
              Expanded(
                child: ListenableBuilder(
                  listenable: Listenable.merge([
                    ThemeManager().seedColorNotifier,
                    ThemeManager().customBackgroundPathNotifier,
                    ThemeManager().chiffonOpacityNotifier,
                    ThemeManager().pureBlackNotifier,
                    ThemeManager().notifier,
                  ]),
                  builder: (context, _) {
                    final backgroundsDisabled = _backgroundsDisabled;
                    Widget backgroundControl(Widget child) => AbsorbPointer(
                          absorbing: backgroundsDisabled,
                          child: ExcludeFocus(
                            excluding: backgroundsDisabled,
                            child: Opacity(
                                opacity: backgroundsDisabled ? 0.38 : 1,
                                child: child),
                          ),
                        );
                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                          sw * 0.04, 8, sw * 0.04, 16 + safeBottom),
                      children: [
                        _buildPreviewCard(),
                        const SizedBox(height: 16),
                        _buildSectionTitle('主题色', c),
                        const SizedBox(height: 8),
                        _buildColorPalette(sw, c),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickCustomColor,
                                icon: const Icon(Icons.colorize),
                                label: const Text('自定义颜色'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _resetSeed,
                                icon: const Icon(Icons.refresh),
                                label: const Text('恢复默认'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('外观与导航', c),
                        const SizedBox(height: 8),
                        const ThemePreferenceControls(),
                        const Divider(height: 24),
                        _buildSearchInteractionSettings(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('功能引导', c),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const OnboardingPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu_book_outlined),
                          label: const Text('重新查看功能引导'),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle('背景图', c),
                        const SizedBox(height: 8),
                        if (backgroundsDisabled)
                          const Text('纯黑模式下背景图与装饰图调节不可用'),
                        backgroundControl(_buildBackgroundSection(sw, c,
                            enabled: !backgroundsDisabled)),
                        const SizedBox(height: 24),
                        _buildSectionTitle('装饰图透明度', c),
                        const SizedBox(height: 8),
                        backgroundControl(_buildChiffonSection(sw, c,
                            enabled: !backgroundsDisabled)),
                        const SizedBox(height: 24),
                        _buildSectionTitle('导出', c),
                        const SizedBox(height: 8),
                        _buildExportSection(sw, c),
                        const SizedBox(height: 24),
                        _buildSectionTitle('同步与网关', c),
                        const SizedBox(height: 8),
                        _buildAwmcGatewaySection(c),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 顶部栏统一走公共组件（标题样式对齐 Rating 排行榜页的 AppBar）
  Widget _buildTitleBar(double sw, Color c) => const PageTopBar(title: '系统设置');

  Widget _buildSectionTitle(String title, Color c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title,
          style: TextStyle(
              color: c.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5),
        ),
      );

  Widget _buildPreviewCard() {
    final scheme = Theme.of(context).colorScheme;
    final bgPath = ThemeManager().customBackgroundPath;
    Widget defaultBackground() => Image.asset(
          'assets/background.png',
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => ColoredBox(color: scheme.surface),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
            child: Text('预览效果',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 2.4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: scheme.surface),
                  if (_backgroundsDisabled)
                    const ColoredBox(color: Colors.black)
                  else if (bgPath != null)
                    Image.file(
                      File(bgPath),
                      key: ValueKey(bgPath),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => defaultBackground(),
                    )
                  else
                    defaultBackground(),
                  if (!_backgroundsDisabled)
                    ColoredBox(color: scheme.primary.withValues(alpha: 0.18)),
                  Center(
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ChiffonMai',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            final columns =
                (constraints.maxWidth / (70 * scale)).floor().clamp(1, 4);
            final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
            final swatches = [
              _previewSwatch('主色', scheme.primary, scheme.onPrimary),
              _previewSwatch('辅助色', scheme.secondary, scheme.onSecondary),
              _previewSwatch('强调色', scheme.tertiary, scheme.onTertiary),
              _previewSwatch('背景色', scheme.surface, scheme.onSurface),
            ];
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final swatch in swatches)
                  SizedBox(width: width, child: swatch),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _previewSwatch(String label, Color color, Color foreground) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildColorPalette(double sw, Color c) {
    final current = ThemeManager().seedColor;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _presetColors.map((color) {
        final isSelected =
            current != null && current.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () async {
            await ThemeManager().setSeedColor(color);
            if (mounted) Fluttertoast.showToast(msg: '主题色已更新');
          },
          child: Container(
            width: sw * 0.13,
            height: sw * 0.13,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? c : Colors.black12,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackgroundSection(double sw, Color c, {bool enabled = true}) {
    final bgPath = ThemeManager().customBackgroundPath;
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !enabled || _pickingImage ? null : _pickBackground,
                  icon: _pickingImage
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image),
                  label: Text(_pickingImage ? '处理中…' : '从相册选择'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      !enabled || bgPath == null ? null : _resetBackground,
                  icon: const Icon(Icons.restore),
                  label: const Text('恢复默认'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: sw * 0.5,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bgPath != null)
                    Image.file(File(bgPath),
                        fit: BoxFit.cover, gaplessPlayback: true)
                  else
                    Image.asset('assets/background.png',
                        fit: BoxFit.cover, gaplessPlayback: true),
                  // 浅色模式洗白 / 深色模式压暗
                  Container(
                    color: brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bgPath == null ? '当前：内置背景' : '当前：自定义图片',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '提示：自定义背景图会覆盖内置 background.png；浅色模式越接近纯白覆层，图片越淡。',
            style: TextStyle(
                color: c.withValues(alpha: 0.55), fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildChiffonSection(double sw, Color c, {bool enabled = true}) {
    final brightness = Theme.of(context).brightness;
    final opacity = ThemeManager().chiffonOpacity;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 预览：当前透明度下 chiffon 装饰图的效果
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: sw * 0.4,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/background.png',
                      fit: BoxFit.cover, gaplessPlayback: true),
                  Container(
                    color: brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                  Center(
                    child: Transform.translate(
                      offset: Offset(0, -sw * 0.4 * 0.03),
                      child: Image.asset(
                        'assets/chiffon2.png',
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        opacity: AlwaysStoppedAnimation(opacity),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('chiffon 装饰图透明度',
                  style: TextStyle(
                      color: c, fontSize: 14, fontWeight: FontWeight.w600)),
              Text('${(opacity * 100).round()}%',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: opacity,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(opacity * 100).round()}%',
            onChanged: !enabled
                ? null
                : (value) {
                    ThemeManager().setChiffonOpacity(value);
                  },
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !enabled || opacity == 0.0
                      ? null
                      : () => ThemeManager().setChiffonOpacity(0.0),
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('隐藏'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !enabled
                      ? null
                      : () => ThemeManager().setChiffonOpacity(0.40),
                  icon: const Icon(Icons.refresh),
                  label: const Text('恢复默认 (40%)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '提示：纯黑模式下自动隐藏；深浅模式共用同一透明度。',
            style: TextStyle(
                color: c.withValues(alpha: 0.55), fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  /// 导出说明。
  ///
  /// 这里**曾经**是「收藏夹导出后缀」的输入框，现已取消自定义：
  /// 用户把后缀改成 `.json` / `.zip` 这类常见后缀后，系统会把本 App 记成
  /// 该类型文件的默认/首要打开方式，等于劫持了这些后缀（见 ExportSettings 注释）。
  /// 后缀固定为 `.cmf`，所以这里只剩一段只读说明，告诉用户文件落在哪。
  Widget _buildExportSection(double sw, Color c) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description_outlined, size: 18, color: c),
              const SizedBox(width: 6),
              Text('收藏夹导出后缀',
                  style: TextStyle(
                      color: c, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              // 固定值，只读展示（不让改，避免劫持常见后缀的打开方式）
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ExportSettings.favoriteExtensionWithDot,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '导出收藏夹会生成 <名字>${ExportSettings.favoriteExtensionWithDot} 文件，'
            '放在 Download/ChiffonMai/收藏夹/ 下，文件管理器可以直接找到。\n'
            '后缀已固定：自定义后缀会把常见格式的默认打开方式抢过来，所以不再开放。\n'
            '导入按文件内容识别、与后缀无关，以前用别的后缀导出的备份照样能导回来。',
            style: TextStyle(
                color: c.withValues(alpha: 0.55), fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ============ 同步与网关 ============

  /// AWMC 网关「同步前探活」超时设置。
  Widget _buildAwmcGatewaySection(Color c) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(Icons.timer_outlined, size: 20, color: c),
        title: Text(
          'AWMC 网关检测超时',
          style: TextStyle(color: c, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            '线路1 同步前会先请求 GET /v1/health 探活；超过这个时间就取消同步（不消耗 Token）。',
            style: TextStyle(fontSize: 11.5, height: 1.4),
          ),
        ),
        trailing: Text(
          '$_awmcProbeTimeoutSeconds 秒',
          style: TextStyle(
            color: scheme.primary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: _editAwmcProbeTimeout,
      ),
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
    Fluttertoast.showToast(msg: 'AWMC 网关检测超时已设为 $_awmcProbeTimeoutSeconds 秒');
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
      setState(() => _error = '请输入整数秒数');
      return;
    }
    if (parsed < AwmcGatewaySettings.minProbeTimeoutSeconds ||
        parsed > AwmcGatewaySettings.maxProbeTimeoutSeconds) {
      setState(
          () => _error = '允许 ${AwmcGatewaySettings.minProbeTimeoutSeconds}–'
              '${AwmcGatewaySettings.maxProbeTimeoutSeconds} 秒');
      return;
    }
    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AWMC 网关检测超时'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '线路1 同步前会先请求 GET /v1/health 探活；超过这个时间视为网关不可用，'
            '直接取消同步（不会消耗 Token）。',
            style: TextStyle(fontSize: 12.5, height: 1.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '超时时间',
              suffixText: '秒',
              helperText:
                  '默认 ${AwmcGatewaySettings.defaultProbeTimeoutSeconds} 秒，'
                  '允许 ${AwmcGatewaySettings.minProbeTimeoutSeconds}–'
                  '${AwmcGatewaySettings.maxProbeTimeoutSeconds} 秒',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(
              context, AwmcGatewaySettings.defaultProbeTimeoutSeconds),
          child: const Text('恢复默认'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}
