import 'package:flutter/material.dart';

import 'simai_visual_tokens.dart';

/// 旧公开色名，全部改为对 [SimaiVisualTokens] 的常量引用。
///
/// 保留这些名字是为了不破坏既有调用方；新代码优先直接用令牌。
class SimaiColors {
  // 点击
  static const Color tapNormal = SimaiVisualTokens.colorTapPink;
  static const Color tapEach = SimaiVisualTokens.colorSimultaneousGold;
  static const Color tapBreak = SimaiVisualTokens.colorBreakOrange;

  // 滑条（星）
  static const Color slideNormal = SimaiVisualTokens.colorSlideCyan;
  static const Color slideEach = SimaiVisualTokens.colorSlideSimultaneous;
  static const Color slideBreak = SimaiVisualTokens.colorBreakOrange;

  // 长条
  static const Color holdNormal = SimaiVisualTokens.colorHoldPink;
  static const Color holdEach = SimaiVisualTokens.colorSimultaneousGold;
  static const Color holdBreak = SimaiVisualTokens.colorHoldBreak;

  // 触摸
  static const Color touchNormal = SimaiVisualTokens.colorTouchCyan;
  static const Color touchEach = SimaiVisualTokens.colorTouchSimultaneous;
  static const Color touchBreak = SimaiVisualTokens.colorBreakOrange;

  // 触摸 Hold（四色，按方位取令牌）
  static const Color touchHoldTopLeft = SimaiVisualTokens.colorTouchHoldBlue;
  static const Color touchHoldTopRight = SimaiVisualTokens.colorTouchHoldRed;
  static const Color touchHoldBottomLeft =
      SimaiVisualTokens.colorTouchHoldGreen;
  static const Color touchHoldBottomRight =
      SimaiVisualTokens.colorTouchHoldYellow;

  static const Color judgeLine = SimaiVisualTokens.colorWhite;
}

/// 舞萌 DX「简洁（シンプル）」与「条形（バー）」皮肤专用深色化色板。
///
/// 相比经典/机台原始亮色令牌适当压低明度并保持高饱和，避免叠加高光后泛白刺眼。
abstract final class SimaiModernNoteColors {
  // 普通粉（Tap / Hold / Star-Tap）
  static const Color pinkLight = Color(0xFFF2549D);
  static const Color pinkMid = Color(0xFFDC1670);
  static const Color pinkDeep = Color(0xFFA80C54);
  static const Color pinkDot = Color(0xFFD91B73);

  // 同时押金黄（Each）
  static const Color eachLight = Color(0xFFF5CB38);
  static const Color eachMid = Color(0xFFDDA400);
  static const Color eachDeep = Color(0xFFB37D00);
  static const Color eachDot = Color(0xFFD99E00);

  // 绝赞橙（Break）
  static const Color breakLight = Color(0xFFF58B2E);
  static const Color breakMid = Color(0xFFDF5400);
  static const Color breakDeep = Color(0xFFAD3800);
  static const Color breakDot = Color(0xFFD94E00);

  // 滑星青（Slide Star）
  static const Color cyanLight = Color(0xFF4CDCE3);
  static const Color cyanMid = Color(0xFF00B8C4);
  static const Color cyanDeep = Color(0xFF008494);
  static const Color cyanDot = Color(0xFF00AAB8);

  // 触摸花瓣（Touch）
  static const Color touchCyanStart = Color(0xFF1AD6DE);
  static const Color touchCyanEnd = Color(0xFF0064CC);
  static const Color touchEachStart = Color(0xFFF2CF2C);
  static const Color touchEachEnd = Color(0xFFC98F00);
}

/// 参考 AstroDX `Design/Sample Skin` 提炼的「简洁」皮肤色板。
///
/// 特色：顶底提亮、左右深饱和的环面宝石渐变，搭配外环「白-彩-白」三层描边、
/// 镂空中心与高对比外缘彩框，兼顾辨识度与深邃质感。
abstract final class SimaiAstroSimpleColors {
  // Tap 普通粉（红宝石粉）
  static const Color tapPinkTop = Color(0xFFFDBCEF);
  static const Color tapPinkSide = Color(0xFFE81E42);
  static const Color tapPinkBottom = Color(0xFFFF8FBB);
  static const Color tapPinkBevel = Color(0xFFA70102);
  static const Color tapPinkRimTop = Color(0xFFFF9AD7);
  static const Color tapPinkRimSide = Color(0xFFFD64BD);
  static const Color tapPinkRimBottom = Color(0xFFFFA0FD);

  // Tap 同时押（金橙宝石）
  static const Color tapEachTop = Color(0xFFFFF100);
  static const Color tapEachSide = Color(0xFFFF9500);
  static const Color tapEachBottom = Color(0xFFFFE900);
  static const Color tapEachBevel = Color(0xFFFF5B00);
  static const Color tapEachRimTop = Color(0xFFFFB03B);
  static const Color tapEachRimSide = Color(0xFFFFC446);
  static const Color tapEachRimBottom = Color(0xFFFFD533);

  // Tap 绝赞（赤红金橙）
  static const Color tapBreakTop = Color(0xFFFFD94E);
  static const Color tapBreakSide = Color(0xFFFF0000);
  static const Color tapBreakBottom = Color(0xFFFF9B03);
  static const Color tapBreakBevel = Color(0xFFD80000);
  static const Color tapBreakRimTop = Color(0xFFFF6B00);
  static const Color tapBreakRimSide = Color(0xFFFF2400);
  static const Color tapBreakRimBottom = Color(0xFFFF9200);

  // Hold 六边形长条（直接复用对应 Tap 的色板，与 Tap / EX Tap 保持完全一致）
  static const Color holdPinkRim = tapPinkRimSide;
  static const Color holdPinkRail = tapPinkSide;
  static const Color holdPinkCap = tapPinkBottom;
  static const Color holdPinkGlow = tapPinkTop;

  static const Color holdEachRim = tapEachRimSide;
  static const Color holdEachRail = tapEachSide;
  static const Color holdEachCap = tapEachBottom;
  static const Color holdEachGlow = tapEachTop;

  static const Color holdBreakRim = tapBreakRimSide;
  static const Color holdBreakRail = tapBreakSide;
  static const Color holdBreakCap = tapBreakBottom;
  static const Color holdBreakGlow = tapBreakTop;

  // Star 五角星（严格提取自 AstroDX `Design/Skinnable Elements 1.1_STAR*.ai`）
  static const Color starCyanRim = Color(0xFF00A2FF);
  static const Color starCyanInner = Color(0xFF3BEAFF);
  static const Color starCyanMid1 = Color(0xFF28D3FF);
  static const Color starCyanMid2 = Color(0xFF17BEFF);
  static const Color starCyanMid3 = Color(0xFF09ADFF);
  static const Color starCyanOuter = Color(0xFF00A2FF);

  static const Color starPinkRim = Color(0xFFFF6AE6);
  static const Color starPinkInner = Color(0xFFFB6DD1);
  static const Color starPinkOuter = Color(0xFFD10674);

  static const Color starEachRim = Color(0xFFFBAC00);
  static const Color starEachInner = Color(0xFFFFF200);
  static const Color starEachMid1 = Color(0xFFFFD400);
  static const Color starEachMid2 = Color(0xFFFFB900);
  static const Color starEachMid3 = Color(0xFFFFA300);
  static const Color starEachOuter = Color(0xFFFF9500);

  static const Color starBreakRim = Color(0xFFFB2E00);
  static const Color starBreakInner = Color(0xFFFFC90E);
  static const Color starBreakMid1 = Color(0xFFFFAC0A);
  static const Color starBreakMid2 = Color(0xFFFF8F07);
  static const Color starBreakMid3 = Color(0xFFFF7204);
  static const Color starBreakMid4 = Color(0xFFFF5402);
  static const Color starBreakMid5 = Color(0xFFFF3901);
  static const Color starBreakMid6 = Color(0xFFFF2100);
  static const Color starBreakOuter = Color(0xFFFF0000);

  // Touch 花瓣（白边 + 尖端深色渐变 + 尖端亮星点）
  static const Color touchCyanOuter = Color(0xFF00EDFE);
  static const Color touchCyanMid = Color(0xFF08CCF2);
  static const Color touchCyanTip = Color(0xFF1D4ED8);
  static const Color touchCyanGlow = Color(0xFF22EEFF);

  static const Color touchEachOuter = Color(0xFFFFFC00);
  static const Color touchEachMid = Color(0xFFFFE704);
  static const Color touchEachTip = Color(0xFFFF9500);
  static const Color touchEachGlow = Color(0xFFFFF040);

  static const Color touchBreakOuter = Color(0xFFFFA100);
  static const Color touchBreakMid = Color(0xFFFF3900);
  static const Color touchBreakTip = Color(0xFFFF0000);
  static const Color touchBreakGlow = Color(0xFFFF3300);

  // Slide 绝赞箭头（红框 + 左金橙右赤红双色）
  static const Color arrowBreakRim = Color(0xFFFF0000);
  static const Color arrowBreakLeftOuter = Color(0xFFFF4518);
  static const Color arrowBreakLeftInner = Color(0xFFFFBE1A);
  static const Color arrowBreakRightInner = Color(0xFFFE2A28);
  static const Color arrowBreakRightOuter = Color(0xFFA00A08);
}
