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
