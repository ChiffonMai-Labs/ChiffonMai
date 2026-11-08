import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/AppUi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../constant/CacheKeyConstant.dart';
import 'AppDesignTokens.dart';
import 'AppTheme.dart';
import 'ExportImageTheme.dart';

export 'ExportImageTheme.dart';

/// 导出质量选择结果
class ExportQualityResult {
  /// JPEG 质量值 (0-100)，null 表示 PNG 无损
  final int? jpegQuality;

  /// 显示标签
  final String label;

  /// 抽屉里选项的名称和说明
  final String name;
  final String hint;

  /// Best50 导出时是否采用雷霆模式（单列 50 行或单行 50 列）。
  final bool thunderMode;
  final bool thunderVertical;

  /// 导出图片的主题。
  final ExportImageTheme theme;

  const ExportQualityResult({
    required this.jpegQuality,
    required this.label,
    this.name = '',
    this.hint = '',
    this.thunderMode = false,
    this.thunderVertical = true,
    this.theme = ExportImageTheme.light,
  });

  /// 预设选项列表
  static List<ExportQualityResult> get presets => [
        ExportQualityResult(
            jpegQuality: null,
            label: appL10n.flowPNGLosslessOriginalQuality,
            name: appL10n.flowPNGLossless,
            hint: appL10n.flowOriginalQuality),
        ExportQualityResult(
            jpegQuality: 95,
            label: appL10n.flowJPEGHighQuality,
            name: appL10n.flowJPEGHighQuality,
            hint: appL10n.flowClearImageSmallerFile),
        ExportQualityResult(
            jpegQuality: 85,
            label: appL10n.flowJPEGStandard,
            name: appL10n.flowJPEGStandard,
            hint: appL10n.flowGoodForSharing),
        ExportQualityResult(
            jpegQuality: 70,
            label: appL10n.flowJPEGCompressed,
            name: appL10n.flowJPEGCompressed,
            hint: appL10n.flowSmallestFile),
      ];

  /// 获取文件扩展名
  String get extension => jpegQuality != null ? 'jpg' : 'png';

  /// 获取格式名称
  String get formatName => jpegQuality != null ? 'JPEG (Q$jpegQuality)' : 'PNG';
}

/// 导出质量选择底部弹窗
///
/// 用法：
/// ```dart
/// final quality = await ExportQualitySelector.show(
///   context,
///   estimatedPngSize: ImageEncodeUtil.estimatePngSize(songCount: 50),
/// );
/// if (quality != null) {
///   // 使用 quality.jpegQuality 导出
/// }
/// ```
class ExportQualitySelector {
  /// 显示质量选择底部弹窗
  /// [context] BuildContext
  /// [estimatedPngSize] 预估的 PNG 文件大小（字节）
  /// 返回用户选择的质量，null 表示取消
  static Future<ExportQualityResult?> show(
    BuildContext context, {
    required int estimatedPngSize,
    String? exportingLabel,
    bool enableThunderMode = false,
    bool initialThunderMode = false,
    bool initialThunderVertical = true,
    FutureOr<Widget> Function(
            BuildContext context, ExportQualityResult quality)?
        previewBuilder,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    if (!context.mounted) return null;
    int? selectedIndex = (preferences.getInt('export_image_quality_index') ?? 0)
        .clamp(0, ExportQualityResult.presets.length - 1);
    var thunderMode = initialThunderMode;
    var thunderVertical = initialThunderVertical;
    // 不跟随 App 和系统：第一次是浅色，之后记住上次选的。
    var theme = ExportImageTheme.fromIndex(
        preferences.getInt(CacheKeyConstant.exportImageTheme));

    final result = await showModalBottomSheet<_ExportSelection>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final scheme = Theme.of(context).colorScheme;
            final selectedPreset =
                ExportQualityResult.presets[selectedIndex ?? 0];

            Widget option(int i) {
              final preset = ExportQualityResult.presets[i];
              return Expanded(
                child: _QualityOption(
                  name: preset.name,
                  hint: preset.hint,
                  size: _getEstimatedSize(estimatedPngSize, preset.jpegQuality),
                  selected: selectedIndex == i,
                  onTap: () {
                    if (selectedIndex == i) return;
                    setState(() => selectedIndex = i);
                    // 选择即记忆；关闭弹窗或取消导出也保留本次偏好。
                    unawaited(
                        preferences.setInt('export_image_quality_index', i));
                  },
                ),
              );
            }

            return ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.88),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    AppDesignTokens.gutter,
                    20,
                    AppDesignTokens.gutter,
                    MediaQuery.paddingOf(context).bottom + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.flowChooseExportQuality,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    if (exportingLabel != null &&
                        exportingLabel.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          context.l10n
                              .flowExportingP0((exportingLabel).toString()),
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              context.l10n.flowImageTheme,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SegmentedTabs(
                              height: 38,
                              items: [
                                for (final item in ExportImageTheme.values)
                                  SegmentedTabItem(switch (item) {
                                    ExportImageTheme.light =>
                                      context.l10n.lightMode,
                                    ExportImageTheme.dark =>
                                      context.l10n.darkMode,
                                    ExportImageTheme.black =>
                                      context.l10n.exportBlackTheme,
                                  }),
                              ],
                              selectedIndex: theme.index,
                              onChanged: (index) {
                                if (index == theme.index) return;
                                setState(() =>
                                    theme = ExportImageTheme.values[index]);
                                // 选择即记忆，和导出质量一样。
                                unawaited(preferences.setInt(
                                    CacheKeyConstant.exportImageTheme, index));
                              },
                            ),
                            const SizedBox(height: 12),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  option(0),
                                  const SizedBox(width: 8),
                                  option(1),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  option(2),
                                  const SizedBox(width: 8),
                                  option(3),
                                ],
                              ),
                            ),
                            if (enableThunderMode) ...[
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppSurfaces.inset(context),
                                  borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radiusMedium),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppSwitchListTile(
                                      value: thunderMode,
                                      onChanged: (value) =>
                                          setState(() => thunderMode = value),
                                      title: Text(context.l10n.flowThunderMode),
                                      subtitle: Text(context
                                          .l10n.flowArrangeCardsIn50RowsOr50),
                                    ),
                                    if (thunderMode)
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            12, 0, 12, 10),
                                        child: SegmentedTabs(
                                          height: 38,
                                          items: [
                                            SegmentedTabItem(
                                                context.l10n.flow50Rows1Column),
                                            SegmentedTabItem(
                                                context.l10n.flow1Row50Columns),
                                          ],
                                          selectedIndex:
                                              thunderVertical ? 0 : 1,
                                          onChanged: (index) => setState(() =>
                                              thunderVertical = index == 0),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            if (previewBuilder != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 46,
                                child: FilledButton.tonalIcon(
                                  onPressed: () {
                                    final q = ExportQualityResult(
                                      jpegQuality: selectedPreset.jpegQuality,
                                      label: selectedPreset.label,
                                      thunderMode: thunderMode,
                                      thunderVertical: thunderVertical,
                                      theme: theme,
                                    );
                                    // 对话框重建时复用同一次预览生成，避免反复构建长图。
                                    final preview = previewBuilder(context, q);
                                    showDialog<void>(
                                      context: context,
                                      builder: (previewContext) =>
                                          _ExportPreviewDialog(
                                        preview: preview,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.preview_rounded,
                                      size: 20),
                                  label: Text(context.l10n.flowExportPreview),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, null),
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(context.l10n.featureCancel,
                                      maxLines: 1)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: () => Navigator.pop(
                                ctx,
                                _ExportSelection(
                                  selectedIndex: selectedIndex!,
                                  thunderMode: thunderMode,
                                  thunderVertical: thunderVertical,
                                  theme: theme,
                                ),
                              ),
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(context.l10n.flowConfirmExport,
                                      maxLines: 1)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return null; // 用户取消
    }

    final preset = ExportQualityResult.presets[result.selectedIndex];
    return ExportQualityResult(
      jpegQuality: preset.jpegQuality,
      label: preset.label,
      thunderMode: result.thunderMode,
      thunderVertical: result.thunderVertical,
      theme: result.theme,
    );
  }

  static Widget _buildPreviewContent(FutureOr<Widget> preview) {
    if (preview is Widget) return preview;
    return FutureBuilder<Widget>(
      future: preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(appL10n
                .flowCouldNotGeneratePreviewP0((snapshot.error).toString())),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
    );
  }

  /// 获取预估文件大小的显示文本
  static String _getEstimatedSize(int pngSize, int? jpegQuality) {
    if (jpegQuality == null) {
      return ImageEncodeUtil.formatFileSize(pngSize);
    }
    final estimatedJpegSize =
        ImageEncodeUtil.estimateJpegSize(pngSize, jpegQuality);
    return ImageEncodeUtil.formatFileSize(estimatedJpegSize);
  }
}

/// 可缩放的导出效果图预览。
///
/// 内容以导出画布的自然尺寸布局，测量后通过变换适应窗口。
/// 缩放与平移共享完整画布边界，超长横图和竖图均可查看每个角落。
class _ExportPreviewDialog extends StatefulWidget {
  final FutureOr<Widget> preview;

  const _ExportPreviewDialog({required this.preview});

  @override
  State<_ExportPreviewDialog> createState() => _ExportPreviewDialogState();
}

class _ExportPreviewDialogState extends State<_ExportPreviewDialog> {
  late final TransformationController _transformationController;
  Size? _contentSize;
  Size _viewportSize = Size.zero;
  double _fitScale = 0.001;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _scaleBy(double factor) {
    if (_contentSize == null || _viewportSize.isEmpty) return;
    final current = _transformationController.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(_fitScale, 4.0).toDouble();
    if (next == _fitScale) {
      _fitContent();
      return;
    }
    // 围绕视口中心缩放，保留当前查看的位置。
    final scene = _transformationController
        .toScene(Offset(_viewportSize.width / 2, _viewportSize.height / 2));
    _transformationController.value = Matrix4.identity()
      ..translate(_viewportSize.width / 2 - scene.dx * next,
          _viewportSize.height / 2 - scene.dy * next)
      ..scale(next);
  }

  void _fitContent() {
    final content = _contentSize;
    if (content == null || content.isEmpty || _viewportSize.isEmpty) return;
    _transformationController.value = Matrix4.identity()
      ..translate((_viewportSize.width - content.width * _fitScale) / 2,
          (_viewportSize.height - content.height * _fitScale) / 2)
      ..scale(_fitScale);
  }

  void _updateGeometry(Size content, Size viewport) {
    if (!mounted ||
        content.isEmpty ||
        viewport.isEmpty ||
        (content == _contentSize && viewport == _viewportSize)) return;
    setState(() {
      _contentSize = content;
      _viewportSize = viewport;
      _fitScale = math.min(
          1.0,
          math.min(viewport.width / content.width,
              viewport.height / content.height));
      _fitContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget tool(String tooltip, IconData icon, VoidCallback onPressed) =>
        IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: AppSurfaces.inset(context),
            foregroundColor: scheme.onSurface,
          ),
          icon: Icon(icon, size: 20),
        );
    return Dialog(
      clipBehavior: Clip.antiAlias,
      backgroundColor: AppSurfaces.card(context),
      insetPadding: const EdgeInsets.all(AppDesignTokens.gutter),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 1000,
          maxHeight: 720,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.flowExportPreview,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _transformationController,
                          builder: (context, _) => Text(
                            '${(_transformationController.value.getMaxScaleOnAxis() * 100).round()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  tool(context.l10n.flowZoomOut, Icons.remove_rounded,
                      () => _scaleBy(0.8)),
                  const SizedBox(width: 4),
                  tool(context.l10n.flowZoomIn, Icons.add_rounded,
                      () => _scaleBy(1.25)),
                  const SizedBox(width: 4),
                  tool(context.l10n.flowFitToWindow, Icons.fit_screen_rounded,
                      _fitContent),
                  const SizedBox(width: 4),
                  tool(context.l10n.featureClose, Icons.close_rounded,
                      () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Flexible(
              child: LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth;
                final content = _contentSize;
                final defaultScale = content == null
                    ? 1.0
                    : math.min(1.0, width / content.width);
                // 短图按默认比例收紧高度，长图才使用当前窗口允许的上限。
                final height = math.min(constraints.maxHeight,
                    content == null ? 180.0 : content.height * defaultScale);
                final viewport = Size(width, height);
                if (_contentSize != null && viewport != _viewportSize) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _updateGeometry(_contentSize!, viewport));
                }
                return SizedBox(
                  width: width,
                  height: height,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    constrained: false,
                    alignment: Alignment.topLeft,
                    minScale: _fitScale,
                    maxScale: 4,
                    // 留足居中空间，同时让放大后的完整画布可以拖至视口内。
                    boundaryMargin: EdgeInsets.symmetric(
                        horizontal: viewport.width / _fitScale,
                        vertical: viewport.height / _fitScale),
                    child: _PreviewSizeReporter(
                      onSize: (size) => _updateGeometry(size, viewport),
                      child: ExportQualitySelector._buildPreviewContent(
                          widget.preview),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// 在自然尺寸布局后报告画布边界，不使用可能改变内容宽度的窗口约束。
class _PreviewSizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;
  const _PreviewSizeReporter({required this.onSize, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _PreviewSizeRenderBox(onSize);

  @override
  void updateRenderObject(
          BuildContext context, covariant _PreviewSizeRenderBox renderObject) =>
      renderObject.onSize = onSize;
}

class _PreviewSizeRenderBox extends RenderProxyBox {
  ValueChanged<Size> onSize;
  Size? _reported;
  _PreviewSizeRenderBox(this.onSize);

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    _reported = size;
    final measured = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(measured);
    });
  }
}

/// 抽屉里的一个质量选项：选中时主题色描边 + 对钩，没有波纹。
class _QualityOption extends StatelessWidget {
  final String name;
  final String hint;
  final String size;
  final bool selected;
  final VoidCallback onTap;

  const _QualityOption({
    required this.name,
    required this.hint,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.fastMotion);
    return PressScale(
      scale: 0.98,
      child: Semantics(
        button: true,
        selected: selected,
        label: context.l10n.flowP0P1EstimatedP2(
            (name).toString(), (hint).toString(), (size).toString()),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: duration,
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.1)
                  : AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
              border: Border.all(
                color: selected ? scheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: duration,
                      opacity: selected ? 1 : 0,
                      child: Icon(Icons.check_circle_rounded,
                          size: 18, color: scheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.flowAboutP0((size).toString()),
                  style: AppTheme.number(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExportSelection {
  final int selectedIndex;
  final bool thunderMode;
  final bool thunderVertical;
  final ExportImageTheme theme;

  const _ExportSelection({
    required this.selectedIndex,
    required this.thunderMode,
    required this.thunderVertical,
    required this.theme,
  });
}
