import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../note_geometry.dart';
import '../simai_colors.dart';

/// AstroDX `Design/Skinnable Elements 1.1_STAR*.ai` 的四种滑条头部星形变体。
enum AstroSimpleStarVariant {
  /// 普通蓝色星星（`STAR.ai`）。
  normal,

  /// 粉色星星变体（`STAR_ALT.ai`，对应粉色星星头开关）。
  alt,

  /// 黄色同时押星星（`STAR_EACH.ai`）。
  each,

  /// 橙红色绝赞星星（`STAR_BREAK.ai`）。
  breakNote,
}

class _RoundedStarArmSpec {
  const _RoundedStarArmSpec({
    required this.tipY,
    required this.c1x,
    required this.c1y,
    required this.c2x,
    required this.c2y,
    required this.tanX,
    required this.tanY,
    required this.valleyX,
    required this.valleyY,
  });

  final double tipY;
  final double c1x;
  final double c1y;
  final double c2x;
  final double c2y;
  final double tanX;
  final double tanY;
  final double valleyX;
  final double valleyY;
}

class _AstroStarPalette {
  const _AstroStarPalette({
    required this.rimColor,
    required this.gradientColors,
    required this.gradientStops,
  });

  final Color rimColor;
  final List<Color> gradientColors;
  final List<double> gradientStops;
}

/// 参照 AstroDX 官方 `Design/Skinnable Elements 1.1_STAR*.ai` 矢量源码复刻的简洁模式星形绘制器。
///
/// 局部坐标系约定：
/// - 原点为五角星五重旋转对称中心（原 `160×160pt` 画板中为 `(80.0, 75.3071)`），旋转无偏心晃动；
/// - 默认星尖朝上（`-Y`），与原 AI 文件方向一致；在图集预烘焙时按需旋转 `+π/2` 朝右；
/// - 全部 8 层轮廓路径按 160pt 原始单位静态缓存一次，绘制期通过统一缩放矩阵复用到任意尺寸。
abstract final class AstroSimpleStarPainter {
  /// AstroDX 原画板中普通 TAP 的实体外半径（pt），用于与简洁模式 TAP 保持一致的相对体量。
  static const double referenceTapOuterRadius = 53.45;

  /// 星体径向渐变在局部坐标系中的中心偏移（原画板中心 `(80, 80)` 相对旋转中心 `(80, 75.3071)`）。
  static const Offset _gradientCenter = Offset(0.0, -4.6929);

  /// 原 AI 文件 `Sh0` 径向渐变半径（pt）。
  static const double _gradientRadius = 50.6812859;

  /// 原 AI 文件中星体最外轮廓顶尖距旋转中心的距离（pt）。
  static const double outerTipRadius = 59.2153;

  /// 原 AI 文件中主影外扩与模糊参数（pt），拟合自 `Im0` / `Im1` / `Obj62` 通道。
  static const double _outerShadowExpandStroke = 6.0;
  static const double _outerShadowSigma = 2.0;
  static const double _innerShadowSigma = 1.0;
  static const double _innerGlowInwardStroke = 1.64;
  static const double _innerGlowSigma = 0.95;
  static const double _innerGlowOpacity = 0.60;

  // --- 从 `Skinnable Elements 1.1_STAR.ai` 提取的 4 层圆角外轮廓控制点 ---
  static const _RoundedStarArmSpec _outerBlackSpec = _RoundedStarArmSpec(
    tipY: -59.2153,
    c1x: -3.5860,
    c1y: -59.2153,
    c2x: -6.8100,
    c2y: -57.3683,
    tanX: -8.6250,
    tanY: -54.2763,
    valleyX: -22.3890,
    valleyY: -30.8163,
  );

  static const _RoundedStarArmSpec _outerColorSpec = _RoundedStarArmSpec(
    tipY: -58.2153,
    c1x: -3.0120,
    c1y: -58.2153,
    c2x: -6.0240,
    c2y: -56.7333,
    tanX: -7.7630,
    tanY: -53.7703,
    valleyX: -21.7480,
    valleyY: -29.9333,
  );

  static const _RoundedStarArmSpec _outerWhiteSpec = _RoundedStarArmSpec(
    tipY: -56.2154,
    c1x: -2.5110,
    c1y: -56.2154,
    c2x: -4.7680,
    c2y: -54.9224,
    tanX: -6.0380,
    tanY: -52.7584,
    valleyX: -20.4650,
    valleyY: -28.1674,
  );

  static const _RoundedStarArmSpec _bodyOuterSpec = _RoundedStarArmSpec(
    tipY: -54.2159,
    c1x: -0.8610,
    c1y: -54.2159,
    c2x: -3.0050,
    c2y: -53.9739,
    tanX: -4.3130,
    tanY: -51.7459,
    valleyX: -19.1820,
    valleyY: -26.4019,
  );

  // --- 静态缓存的局部单位路径（构建一次，零重复解析与分配） ---
  static final Path _outerBlackContour = _buildRoundedStarContour(
    _outerBlackSpec,
  );
  static final Path _outerColorContour = _buildRoundedStarContour(
    _outerColorSpec,
  );
  static final Path _outerWhiteContour = _buildRoundedStarContour(
    _outerWhiteSpec,
  );
  static final Path _bodyOuterContour = _buildRoundedStarContour(
    _bodyOuterSpec,
  );

  static final Path _bodyInnerContour = _buildSharpStarContour(
    39.3349,
    21.7231,
  );
  static final Path _innerWhiteContour = _buildSharpStarContour(
    35.3833,
    19.5407,
  );
  static final Path _innerColorContour = _buildSharpStarContour(
    31.4313,
    17.3577,
  );
  static final Path _innerBlackContour = _buildSharpStarContour(
    29.4553,
    16.2667,
  );

  // 嵌套环带路径（统一以最终内孔或内界作镂空，消除相邻细边抗锯齿渗缝）。
  static final Path _silhouetteRing = _combineEvenOdd(
    _outerBlackContour,
    _innerBlackContour,
  );
  static final Path _coloredFrameRing = _combineEvenOdd(
    _outerColorContour,
    _innerColorContour,
  );
  static final Path _whiteFrameRing = _combineEvenOdd(
    _outerWhiteContour,
    _innerWhiteContour,
  );
  static final Path _bodyRing = _combineEvenOdd(
    _bodyOuterContour,
    _bodyInnerContour,
  );

  // 星体补集路径：用于生成裁剪在星体内部的边缘内发光（还原 AI `Fm0` + `HardLight 60%`）。
  static final Path _bodyComplement = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(const Rect.fromLTRB(-80.0, -80.0, 80.0, 80.0))
    ..addPath(_bodyRing, Offset.zero);

  static const Rect _localLayerBounds = Rect.fromLTRB(
    -76.0,
    -76.0,
    76.0,
    76.0,
  );

  static const _AstroStarPalette _normalPalette = _AstroStarPalette(
    rimColor: SimaiAstroSimpleColors.starCyanRim,
    gradientColors: <Color>[
      SimaiAstroSimpleColors.starCyanInner,
      SimaiAstroSimpleColors.starCyanInner,
      SimaiAstroSimpleColors.starCyanMid1,
      SimaiAstroSimpleColors.starCyanMid2,
      SimaiAstroSimpleColors.starCyanMid3,
      SimaiAstroSimpleColors.starCyanOuter,
    ],
    gradientStops: <double>[0.0, 0.40, 0.55, 0.70, 0.85, 1.0],
  );

  static const _AstroStarPalette _altPalette = _AstroStarPalette(
    rimColor: SimaiAstroSimpleColors.starPinkRim,
    gradientColors: <Color>[
      SimaiAstroSimpleColors.starPinkInner,
      SimaiAstroSimpleColors.starPinkInner,
      SimaiAstroSimpleColors.starPinkOuter,
    ],
    gradientStops: <double>[0.0, 0.60, 1.0],
  );

  static const _AstroStarPalette _eachPalette = _AstroStarPalette(
    rimColor: SimaiAstroSimpleColors.starEachRim,
    gradientColors: <Color>[
      SimaiAstroSimpleColors.starEachInner,
      SimaiAstroSimpleColors.starEachInner,
      SimaiAstroSimpleColors.starEachMid1,
      SimaiAstroSimpleColors.starEachMid2,
      SimaiAstroSimpleColors.starEachMid3,
      SimaiAstroSimpleColors.starEachOuter,
    ],
    gradientStops: <double>[0.0, 0.40, 0.55, 0.70, 0.85, 1.0],
  );

  static const _AstroStarPalette _breakPalette = _AstroStarPalette(
    rimColor: SimaiAstroSimpleColors.starBreakRim,
    gradientColors: <Color>[
      SimaiAstroSimpleColors.starBreakInner,
      SimaiAstroSimpleColors.starBreakInner,
      SimaiAstroSimpleColors.starBreakMid1,
      SimaiAstroSimpleColors.starBreakMid2,
      SimaiAstroSimpleColors.starBreakMid3,
      SimaiAstroSimpleColors.starBreakMid4,
      SimaiAstroSimpleColors.starBreakMid5,
      SimaiAstroSimpleColors.starBreakMid6,
      SimaiAstroSimpleColors.starBreakOuter,
    ],
    gradientStops: <double>[0.0, 0.40, 0.50, 0.60, 0.70, 0.80, 0.88, 0.94, 1.0],
  );

  /// 根据项目内星头基准颜色映射到 AstroDX 四种星形变体。
  static AstroSimpleStarVariant variantForColor(Color baseColor) {
    if (baseColor == SimaiColors.slideBreak ||
        baseColor == SimaiColors.tapBreak) {
      return AstroSimpleStarVariant.breakNote;
    }
    if (baseColor == SimaiColors.slideEach ||
        baseColor == SimaiColors.tapEach) {
      return AstroSimpleStarVariant.each;
    }
    if (baseColor == SimaiColors.tapNormal) {
      return AstroSimpleStarVariant.alt;
    }
    return AstroSimpleStarVariant.normal;
  }

  /// 将项目 `noteScale` 换算为 160pt 局部坐标的统一缩放系数。
  static double unitScaleForNoteScale(double noteScale) =>
      (NoteGeometry.tapStarHoldRadius * noteScale) / referenceTapOuterRadius;

  /// 按指定局部缩放系数在 [center] 处绘制 AstroDX 简洁模式星形 Note。
  ///
  /// - [unitScale]：局部 160pt 坐标到目标画布的等比缩放系数；
  /// - [rotation]：绕五重对称中心的弧度旋转（0 为星尖朝上，`+π/2` 为星尖朝右）。
  static void paint(
    Canvas canvas, {
    required Offset center,
    required double unitScale,
    required AstroSimpleStarVariant variant,
    double rotation = 0.0,
  }) {
    if (!unitScale.isFinite || unitScale <= 0) return;
    final palette = _paletteFor(variant);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (rotation != 0.0) {
      canvas.rotate(rotation);
    }
    canvas.scale(unitScale, unitScale);

    // 1) 主柔和黑影（`Im0`：先合成为单层实心外扩轮廓再统一做 σ=2pt 高斯模糊，避免多次叠加导致影圈过厚）。
    final Paint solidBlackFill = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Colors.black;
    canvas.saveLayer(
      _localLayerBounds,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: _outerShadowSigma,
          sigmaY: _outerShadowSigma,
          tileMode: TileMode.decal,
        ),
    );
    canvas.drawPath(_silhouetteRing, solidBlackFill);
    canvas.drawPath(
      _outerBlackContour,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outerShadowExpandStroke
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black,
    );
    canvas.drawPath(
      _innerBlackContour,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outerShadowExpandStroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeMiterLimit = 4.0
        ..color = Colors.black,
    );
    canvas.restore();

    // 2) 贴边锐利黑影（`Im1`：无外扩，σ=1pt 高斯模糊，增强内孔与边缘立体深度）。
    canvas.drawPath(
      _silhouetteRing,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = Colors.black
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          _innerShadowSigma,
        ),
    );

    // 3) 最外与最内 1pt 纯黑轮廓描边（嵌套整环填充，消除拼缝）。
    canvas.drawPath(_silhouetteRing, solidBlackFill);

    // 4) 外侧与内侧 2pt 彩色边缘环带。
    canvas.drawPath(
      _coloredFrameRing,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = palette.rimColor,
    );

    // 5) 外侧与内侧 2pt 纯白高亮边线。
    canvas.drawPath(
      _whiteFrameRing,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = Colors.white,
    );

    // 6) 星体主环带：按变体独立的径向渐变（中心对齐原 AI `(80, 80)`）。
    canvas.drawPath(
      _bodyRing,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.radial(
          _gradientCenter,
          _gradientRadius,
          palette.gradientColors,
          palette.gradientStops,
        ),
    );

    // 7) 星体边缘白色内发光（还原 AI `Fm0` + `HardLight 60%` 倒置模糊蒙版）：
    //    先在离屏层对星体补集做单次高斯模糊，再用 dstIn 严格裁回 `_bodyRing`，最后以 HardLight 60% 混合。
    canvas.saveLayer(
      _localLayerBounds,
      Paint()
        ..blendMode = BlendMode.hardLight
        ..color = Color.fromARGB((_innerGlowOpacity * 255).round(), 255, 255, 255),
    );
    canvas.saveLayer(
      _localLayerBounds,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: _innerGlowSigma,
          sigmaY: _innerGlowSigma,
          tileMode: TileMode.decal,
        ),
    );
    canvas.drawPath(
      _bodyComplement,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = Colors.white,
    );
    canvas.drawPath(
      _bodyOuterContour,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = _innerGlowInwardStroke
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    canvas.drawPath(
      _bodyInnerContour,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = _innerGlowInwardStroke
        ..strokeJoin = StrokeJoin.miter
        ..strokeMiterLimit = 4.0
        ..color = Colors.white,
    );
    canvas.restore();
    canvas.drawPath(
      _bodyComplement,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.clear,
    );
    canvas.restore();

    canvas.restore();
  }

  /// 为简洁模式 EX 星头绘制贴合圆角外廓的外圈光晕环。
  static void paintExHighlight(
    Canvas canvas, {
    required Offset position,
    required Color color,
    required double noteScale,
    required double scale,
    required int alpha,
    required double rotation,
  }) {
    final double unitScale = unitScaleForNoteScale(noteScale * scale);
    if (!unitScale.isFinite || unitScale <= 0) return;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    // 传入的 `rotation` 基于图集朝右坐标系，叠加 `+π/2` 对齐局部朝上坐标。
    canvas.rotate(rotation + math.pi / 2);
    canvas.scale(unitScale, unitScale);
    canvas.drawPath(
      _outerBlackContour,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11.0
        ..strokeJoin = StrokeJoin.round
        ..color = color.withAlpha((alpha * 0.72).round().clamp(0, 255)),
    );
    canvas.restore();
  }

  static _AstroStarPalette _paletteFor(AstroSimpleStarVariant variant) =>
      switch (variant) {
        AstroSimpleStarVariant.normal => _normalPalette,
        AstroSimpleStarVariant.alt => _altPalette,
        AstroSimpleStarVariant.each => _eachPalette,
        AstroSimpleStarVariant.breakNote => _breakPalette,
      };

  static Path _combineEvenOdd(Path outer, Path inner) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(outer, Offset.zero)
      ..addPath(inner, Offset.zero);
  }

  static Offset _rotate(double x, double y, double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return Offset(x * c - y * s, x * s + y * c);
  }

  /// 按五重旋转对称构造圆角五角星轮廓（精确复现原 AI 贝塞尔尖角与锐利内凹谷）。
  static Path _buildRoundedStarContour(_RoundedStarArmSpec spec) {
    final path = Path()..moveTo(0.0, spec.tipY);
    for (int k = 0; k < 5; k++) {
      final double a0 = -k * (2.0 * math.pi / 5.0);
      final double a1 = -(k + 1) * (2.0 * math.pi / 5.0);

      // 当前星尖左半段圆弧（tip -> tanL）
      final c1L = _rotate(spec.c1x, spec.c1y, a0);
      final c2L = _rotate(spec.c2x, spec.c2y, a0);
      final tanL = _rotate(spec.tanX, spec.tanY, a0);
      path.cubicTo(c1L.dx, c1L.dy, c2L.dx, c2L.dy, tanL.dx, tanL.dy);

      // 左侧边直线到内凹谷
      final valley = _rotate(spec.valleyX, spec.valleyY, a0);
      path.lineTo(valley.dx, valley.dy);

      // 内凹谷直线到下一星尖右侧切点（镜像 x 取反再旋转至下一臂）
      final tanRNext = _rotate(-spec.tanX, spec.tanY, a1);
      path.lineTo(tanRNext.dx, tanRNext.dy);

      // 下一星尖右半段圆弧（tanRNext -> nextTip）
      final c2RNext = _rotate(-spec.c2x, spec.c2y, a1);
      final c1RNext = _rotate(-spec.c1x, spec.c1y, a1);
      final tipNext = _rotate(0.0, spec.tipY, a1);
      path.cubicTo(
        c2RNext.dx,
        c2RNext.dy,
        c1RNext.dx,
        c1RNext.dy,
        tipNext.dx,
        tipNext.dy,
      );
    }
    path.close();
    return path;
  }

  /// 构造内部尖角五角星轮廓（原 AI 内侧轮廓为 10 顶点锐利五角星）。
  static Path _buildSharpStarContour(double tipRadius, double valleyRadius) {
    final path = Path();
    const double startAngle = -math.pi / 2.0;
    const double step = math.pi / 5.0;
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? tipRadius : valleyRadius;
      final double angle = startAngle - i * step;
      final double x = r * math.cos(angle);
      final double y = r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }
}
