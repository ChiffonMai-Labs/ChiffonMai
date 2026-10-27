import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/AnimatedChoiceBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';

/// 导出质量选择结果
class ExportQualityResult {
  /// JPEG 质量值 (0-100)，null 表示 PNG 无损
  final int? jpegQuality;

  /// 显示标签
  final String label;

  /// Best50 导出时是否采用雷霆模式（单列 50 行或单行 50 列）。
  final bool thunderMode;
  final bool thunderVertical;

  const ExportQualityResult({
    required this.jpegQuality,
    required this.label,
    this.thunderMode = false,
    this.thunderVertical = true,
  });

  /// 预设选项列表
  static const List<ExportQualityResult> presets = [
    ExportQualityResult(jpegQuality: null, label: 'PNG 无损（原始画质）'),
    ExportQualityResult(jpegQuality: 95, label: 'JPEG 高质量'),
    ExportQualityResult(jpegQuality: 85, label: 'JPEG 标准'),
    ExportQualityResult(jpegQuality: 70, label: 'JPEG 压缩'),
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

    final result = await showModalBottomSheet<_ExportSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selectedPreset =
                ExportQualityResult.presets[selectedIndex ?? 0];
            return Theme(
              data: Theme.of(context)
                  .copyWith(splashFactory: NoSplash.splashFactory),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 拖拽手柄
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // 标题
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        '选择导出质量',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (exportingLabel != null &&
                        exportingLabel.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: Text(
                          '当前正在导出：$exportingLabel',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    const Divider(),
                    // 选项列表
                    ...List.generate(
                      ExportQualityResult.presets.length,
                      (i) {
                        final preset = ExportQualityResult.presets[i];
                        final estimatedSize = _getEstimatedSize(
                            estimatedPngSize, preset.jpegQuality);
                        final isSelected = selectedIndex == i;

                        return AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8)),
                            child: ListTile(
                              selected: isSelected,
                              selectedTileColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              leading: FadeContent(
                                  child: Icon(
                                key: ValueKey(isSelected),
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              )),
                              title: Text(
                                preset.label,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '预计大小: $estimatedSize',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    )
                                  : null,
                              onTap: () {
                                if (selectedIndex == i) return;
                                setState(() => selectedIndex = i);
                                // 选择即记忆；关闭弹窗或取消导出也保留本次偏好。
                                unawaited(preferences.setInt(
                                    'export_image_quality_index', i));
                              },
                            ));
                      },
                    ),
                    if (previewBuilder != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final q = ExportQualityResult(
                              jpegQuality: selectedPreset.jpegQuality,
                              label: selectedPreset.label,
                              thunderMode: thunderMode,
                              thunderVertical: thunderVertical,
                            );
                            // 对话框重建时复用同一次预览生成，避免反复构建长图。
                            final preview = previewBuilder(context, q);
                            showDialog<void>(
                              context: context,
                              builder: (previewContext) => _ExportPreviewDialog(
                                preview: preview,
                              ),
                            );
                          },
                          icon: const Icon(Icons.preview_outlined),
                          label: const Text('导出效果图'),
                        ),
                      ),
                    ],
                    if (enableThunderMode) ...[
                      const Divider(),
                      AppSwitchListTile(
                        value: thunderMode,
                        onChanged: (value) =>
                            setState(() => thunderMode = value),
                        title: const Text('雷霆模式'),
                        subtitle: const Text('将歌曲卡片改为单列 50 行或单行 50 列，适合超长图片'),
                      ),
                      if (thunderMode)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                  value: true, label: Text('单列 50 行')),
                              ButtonSegment<bool>(
                                  value: false, label: Text('单行 50 列')),
                            ],
                            selected: {thunderVertical},
                            onSelectionChanged: (values) =>
                                setState(() => thunderVertical = values.first),
                          ),
                        ),
                    ],
                    const Divider(),
                    // 底部按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx, null),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                '取消',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => Navigator.pop(
                                ctx,
                                _ExportSelection(
                                  selectedIndex: selectedIndex!,
                                  thunderMode: thunderMode,
                                  thunderVertical: thunderVertical,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                '确认导出',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
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
            child: Text('预览生成失败：${snapshot.error}'),
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
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '导出效果图',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: '缩小',
                    onPressed: () => _scaleBy(0.8),
                    icon: const Icon(Icons.zoom_out),
                  ),
                  IconButton(
                    tooltip: '放大',
                    onPressed: () => _scaleBy(1.25),
                    icon: const Icon(Icons.zoom_in),
                  ),
                  IconButton(
                    tooltip: '适应窗口',
                    onPressed: _fitContent,
                    icon: const Icon(Icons.fit_screen),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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

class _ExportSelection {
  final int selectedIndex;
  final bool thunderMode;
  final bool thunderVertical;

  const _ExportSelection({
    required this.selectedIndex,
    required this.thunderMode,
    required this.thunderVertical,
  });
}
