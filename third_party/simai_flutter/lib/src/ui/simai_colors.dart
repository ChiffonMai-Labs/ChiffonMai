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
