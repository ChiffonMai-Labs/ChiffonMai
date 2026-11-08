import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// 窗口诊断（issue #4 小窗内容空白）。
///
/// ⚠️ release 包会去掉 dart:ui 和 Flutter 框架类的 toString，`'$size'` 只会打出
/// `Instance of 'by'`，所以这里一律手动取数值。
class WindowDiagnostics {
  WindowDiagnostics._();

  static String size(Size value) =>
      '${value.width.toStringAsFixed(1)}x${value.height.toStringAsFixed(1)}';

  static String padding(ui.ViewPadding value) =>
      'L${value.left.toStringAsFixed(0)} T${value.top.toStringAsFixed(0)} '
      'R${value.right.toStringAsFixed(0)} B${value.bottom.toStringAsFixed(0)}';

  static String view(ui.FlutterView view) {
    final ratio = view.devicePixelRatio;
    return 'physical=${size(view.physicalSize)} dpr=$ratio '
        'logical=${size(view.physicalSize / ratio)} '
        'padding=${padding(view.padding)} insets=${padding(view.viewInsets)} '
        'refreshRate=${view.display.refreshRate.toStringAsFixed(1)}';
  }

  static String? _lastSanitized;

  /// 去掉明显不合理的安全区（issue #4）。
  ///
  /// HyperOS 小窗恢复后会报出比窗口还高的顶部安全区（实测 T1989 物理像素，窗口只有
  /// 1728），页面内容整体被推到窗口外，只剩底部导航栏。真实的状态栏、刘海和导航栏
  /// 不会超过窗口对应边长的三分之一，超过的一侧按 0 处理。
  static MediaQueryData sanitizePadding(MediaQueryData data) {
    final size = data.size;
    EdgeInsets fix(EdgeInsets value) => EdgeInsets.fromLTRB(
          value.left > size.width / 3 ? 0 : value.left,
          value.top > size.height / 3 ? 0 : value.top,
          value.right > size.width / 3 ? 0 : value.right,
          value.bottom > size.height / 3 ? 0 : value.bottom,
        );
    final padding = fix(data.padding);
    final viewPadding = fix(data.viewPadding);
    if (padding == data.padding && viewPadding == data.viewPadding) {
      _lastSanitized = null;
      return data;
    }
    final note = '${data.viewPadding.top.toStringAsFixed(0)}/'
        '${data.viewPadding.bottom.toStringAsFixed(0)}@${size.height.toStringAsFixed(0)}';
    if (note != _lastSanitized) {
      _lastSanitized = note;
      debugPrint('[Window] 安全区异常已忽略：logical=${WindowDiagnostics.size(size)} '
          'viewPadding=T${data.viewPadding.top.toStringAsFixed(0)} '
          'B${data.viewPadding.bottom.toStringAsFixed(0)}');
    }
    return data.copyWith(padding: padding, viewPadding: viewPadding);
  }

  /// 统计渲染树，用来区分内容是「布局不对」还是「布局正常却没画出来」。
  static String renderTree() {
    final renderViews = WidgetsBinding.instance.renderViews;
    if (renderViews.isEmpty) return '渲染树为空';
    final root = renderViews.first;
    final window = Offset.zero & root.size;
    var nodes = 0,
        emptyBoxes = 0,
        texts = 0,
        textsInWindow = 0,
        images = 0,
        offstage = 0,
        hiddenOpacity = 0;

    void visit(RenderObject object) {
      nodes++;
      if (object is RenderOffstage && object.offstage) {
        offstage++;
        // 离屏子树不绘制，继续统计只会把数字搅乱
        return;
      }
      if (object is RenderOpacity && object.opacity == 0) hiddenOpacity++;
      if (object is RenderAnimatedOpacity && object.opacity.value == 0) {
        hiddenOpacity++;
      }
      if (object is RenderImage) images++;
      if (object is RenderBox && object.hasSize) {
        if (object.size.isEmpty) emptyBoxes++;
        if (object is RenderParagraph) {
          texts++;
          final rect = object.localToGlobal(Offset.zero) & object.size;
          if (rect.overlaps(window)) textsInWindow++;
        }
      }
      object.visitChildren(visit);
    }

    visit(root);
    return '根=${size(root.size)} 节点=$nodes 空尺寸=$emptyBoxes '
        '文字=$texts 窗口内文字=$textsInWindow 图片=$images '
        '离屏=$offstage 透明=$hiddenOpacity';
  }

  /// 窗口尺寸变化后把整棵树标记为重建和重绘，并强制出一帧；State 不受影响。
  ///
  /// 小窗的宽度和全屏一样，只有高度变了：宽度不变的子树可能沿用旧图层、不重新
  /// 绘制。这是针对 issue #4 的预测性修复，还没有在出问题的设备上验证。
  static void forceRepaint() {
    void mark(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(mark);
    }

    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    final binding = WidgetsBinding.instance;
    binding.rootElement?.visitChildren(rebuild);
    binding.renderViews.forEach(mark);
    binding.scheduleForcedFrame();
  }
}
