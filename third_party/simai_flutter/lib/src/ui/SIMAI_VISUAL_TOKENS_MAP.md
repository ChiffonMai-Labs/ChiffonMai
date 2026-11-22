# simai_visual_tokens.dart ↔ constants.ts 逐值对照表

源：`/Users/wujian/Downloads/Maimai-Chart-Preview-main/src/chart/utils/constants.ts:1-189`（git `e16754f`）。
目标：`third_party/simai_flutter/lib/src/ui/simai_visual_tokens.dart`（`SimaiVisualTokens`，均为 Dart const）。

方法：逐行人工移植后用脚本双向核对——按 TS 常量名在 Dart 的 `TS: 原名（:行号）` 注释里定位声明，再把两边值规范化（`#RRGGBB` → `Color(0xFFRRGGBB)`、`rgba(r,g,b,a)` → `Color.fromRGBO(r,g,b,a)`、`Math.PI` → `math.pi`）逐值比较。

覆盖自检：TS 叶子常量 **92** 条（41 个顶层标量 + 3 张 const 表的 51 个成员），映射 **92** 条，遗漏 **0**，多余 **0**，值不一致 **0**。三张表（`TOUCH_SENSOR_RADII` 5 条、`COLORS` 37 条、`RENDER_ORDER` 9 条）按成员逐条列，另加 3 条表声明行，共 95 条数据行。


## 时间与拍子（constants.ts:1-18）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 2 | `BASE_APPROACH_TIME_MS` | `2250` | `baseApproachTimeMs` | `2250` | 18 |
| 5 | `BEATS_PER_MEASURE` | `4` | `beatsPerMeasure` | `4` | 21 |
| 8 | `POSITION_TICKS_PER_MEASURE` | `512` | `positionTicksPerMeasure` | `512` | 24 |
| 11 | `ANSWER_SOUND_BASE_OFFSET_MS` | `-50` | `answerSoundBaseOffsetMs` | `-50` | 27 |
| 14 | `NOTE_PLAY_WINDOW_MS` | `20` | `notePlayWindowMs` | `20` | 30 |
| 17 | `NOTE_VISIBILITY_AFTER_MS` | `0` | `noteVisibilityAfterMs` | `0` | 33 |

## 按钮与角度（constants.ts:19-30）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 20 | `BUTTON_COUNT` | `8` | `buttonCount` | `8` | 40 |
| 23 | `BUTTON_ANGLE_STEP` | `Math.PI / 4` | `buttonAngleStep` | `math.pi / 4` | 43 |
| 26 | `BUTTON_ANGLE_OFFSET` | `Math.PI / 8` | `buttonAngleOffset` | `math.pi / 8` | 46 |
| 29 | `BASE_ANGLE` | `-Math.PI / 2` | `baseAngle` | `-math.pi / 2` | 49 |

## Note 几何比例（constants.ts:31-45）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 32 | `NOTE_SIZE_RATIO` | `1 / 12.5` | `noteSizeRatio` | `1 / 12.5` | 56 |
| 35 | `TAP_INNER_RING_RATIO` | `0.65` | `tapInnerRingRatio` | `0.65` | 59 |
| 38 | `APPROACH_START_SCALE` | `0.25` | `approachStartScale` | `0.25` | 62 |
| 41 | `BUTTON_MARKER_RATIO` | `9 / 300` | `buttonMarkerRatio` | `9 / 300` | 65 |
| 44 | `NOTE_STROKE_WIDTH_RATIO` | `2 / 300` | `noteStrokeWidthRatio` | `2 / 300` | 68 |

## 滑条（constants.ts:46-70）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 47 | `JUDGMENT_LINE_WIDTH_RATIO` | `3 / 300` | `judgmentLineWidthRatio` | `3 / 300` | 71 |
| 50 | `SLIDE_ARROW_WIDTH_RATIO` | `12.8 / 300` | `slideArrowWidthRatio` | `12.8 / 300` | 78 |
| 53 | `SLIDE_ARROW_SPACING` | `26.896180742334582` | `slideArrowSpacing` | `26.896180742334582` | 81 |
| 56 | `SLIDE_CURVE_OFFSET_RATIO` | `0.4` | `slideCurveOffsetRatio` | `0.4` | 84 |
| 59 | `SLIDE_PP_CURVE_RADIUS_RATIO` | `0.45` | `slidePpCurveRadiusRatio` | `0.45` | 87 |
| 62 | `WIFI_ARROW_SPACING` | `46.64867217847119` | `wifiArrowSpacing` | `46.64867217847119` | 90 |
| 65 | `WIFI_ARROW_BASE_SIZE` | `20` | `wifiArrowBaseSize` | `20` | 93 |
| 68 | `WIFI_ARROW_MAX_SIZE` | `280` | `wifiArrowMaxSize` | `280` | 96 |

## 长条（constants.ts:71-75）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 71 | `HOLD_WIDTH_RATIO` | `1.5` | `holdWidthRatio` | `1.5` | 103 |
| 74 | `HOLD_INNER_RATIO` | `0.62` | `holdInnerRatio` | `0.62` | 106 |

## 触摸 Note 与传感器（constants.ts:76-99）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 77 | `TOUCH_APPROACH_MULTIPLIER` | `0.9` | `touchApproachMultiplier` | `0.9` | 113 |
| 80 | `TOUCH_CENTER_DOT_RATIO` | `1 / 37.5` | `touchCenterDotRatio` | `1 / 37.5` | 116 |
| 83 | `TOUCH_PETAL_OPEN_RATIO` | `1 / 6.25` | `touchPetalOpenRatio` | `1 / 6.25` | 119 |
| 86 | `TOUCH_PETAL_CLOSED_RATIO` | `1 / 12.5` | `touchPetalClosedRatio` | `1 / 12.5` | 122 |
| 89 | `TOUCH_HOLD_PROGRESS_WIDTH_RATIO` | `1 / 31.25` | `touchHoldProgressWidthRatio` | `1 / 31.25` | 125 |
| 92 | `TOUCH_SENSOR_RADII`（对象声明） | — | `SimaiVisualTokens`（类内 const 表） | — | — |
| 93 | `TOUCH_SENSOR_RADII.A` | `0.9` | `touchSensorRadiusA` | `0.9` | 128 |
| 94 | `TOUCH_SENSOR_RADII.B` | `0.465` | `touchSensorRadiusB` | `0.465` | 131 |
| 95 | `TOUCH_SENSOR_RADII.C` | `0` | `touchSensorRadiusC` | `0` | 134 |
| 96 | `TOUCH_SENSOR_RADII.D` | `0.9` | `touchSensorRadiusD` | `0.9` | 137 |
| 97 | `TOUCH_SENSOR_RADII.E` | `0.66` | `touchSensorRadiusE` | `0.66` | 140 |

## 流速与播放速度（constants.ts:100-120）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 101 | `HI_SPEED_MIN` | `3` | `hiSpeedMin` | `3` | 156 |
| 104 | `HI_SPEED_MAX` | `9` | `hiSpeedMax` | `9` | 159 |
| 107 | `HI_SPEED_DEFAULT` | `6` | `hiSpeedDefault` | `6` | 162 |
| 110 | `HI_SPEED_CONVERSION_FACTOR` | `(2 / 3) * 0.9` | `hiSpeedConversionFactor` | `(2 / 3)* 0.9` | 165 |
| 113 | `PLAYBACK_SPEED_MIN` | `0.1` | `playbackSpeedMin` | `0.1` | 168 |
| 116 | `PLAYBACK_SPEED_MAX` | `1.0` | `playbackSpeedMax` | `1.0` | 171 |
| 119 | `PLAYBACK_SPEED_DEFAULT` | `1.0` | `playbackSpeedDefault` | `1.0` | 174 |

## 色表 COLORS（constants.ts:121-166）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 121 | `COLORS`（对象声明） | — | `SimaiVisualTokens`（类内 const 表） | — | — |
| 122 | `COLORS.BLACK` | `'#000000'` | `colorBlack` | `Color(0xFF000000)` | 181 |
| 123 | `COLORS.TAP_PINK` | `'#ff69b4'` | `colorTapPink` | `Color(0xFFFF69B4)` | 184 |
| 124 | `COLORS.TAP_GRADIENT_START` | `'#FD197D'` | `colorTapGradientStart` | `Color(0xFFFD197D)` | 187 |
| 125 | `COLORS.TAP_GRADIENT_END` | `'#FF7DD5'` | `colorTapGradientEnd` | `Color(0xFFFF7DD5)` | 190 |
| 126 | `COLORS.SIMULTANEOUS_GOLD` | `'#FFD700'` | `colorSimultaneousGold` | `Color(0xFFFFD700)` | 193 |
| 127 | `COLORS.SIMULTANEOUS_GRADIENT_START` | `'#FCB600'` | `colorSimultaneousGradientStart` | `Color(0xFFFCB600)` | 196 |
| 128 | `COLORS.SIMULTANEOUS_GRADIENT_END` | `'#FFFE00'` | `colorSimultaneousGradientEnd` | `Color(0xFFFFFE00)` | 199 |
| 129 | `COLORS.BREAK_ORANGE` | `'#FF8C00'` | `colorBreakOrange` | `Color(0xFFFF8C00)` | 202 |
| 130 | `COLORS.BREAK_GRADIENT_START` | `'#FFB347'` | `colorBreakGradientStart` | `Color(0xFFFFB347)` | 205 |
| 131 | `COLORS.BREAK_GRADIENT_MID` | `'#FF8C00'` | `colorBreakGradientMid` | `Color(0xFFFF8C00)` | 208 |
| 132 | `COLORS.BREAK_GRADIENT_END` | `'#FF6600'` | `colorBreakGradientEnd` | `Color(0xFFFF6600)` | 211 |
| 134 | `COLORS.SLIDE_CYAN` | `'#01FBFD'` | `colorSlideCyan` | `Color(0xFF01FBFD)` | 214 |
| 135 | `COLORS.SLIDE_ARROW_RIGHT` | `'#FF9001'` | `colorSlideArrowRight` | `Color(0xFFFF9001)` | 217 |
| 136 | `COLORS.SLIDE_PINK` | `'#ff69b4'` | `colorSlidePink` | `Color(0xFFFF69B4)` | 220 |
| 137 | `COLORS.SLIDE_SIMULTANEOUS` | `'#FFED24'` | `colorSlideSimultaneous` | `Color(0xFFFFED24)` | 223 |
| 139 | `COLORS.HOLD_PINK` | `'#ff69b4'` | `colorHoldPink` | `Color(0xFFFF69B4)` | 226 |
| 140 | `COLORS.HOLD_BREAK` | `'#FF8C00'` | `colorHoldBreak` | `Color(0xFFFF8C00)` | 229 |
| 142 | `COLORS.TOUCH_CYAN` | `'#00FFFF'` | `colorTouchCyan` | `Color(0xFF00FFFF)` | 232 |
| 143 | `COLORS.TOUCH_BLUE` | `'#0080FF'` | `colorTouchBlue` | `Color(0xFF0080FF)` | 235 |
| 144 | `COLORS.TOUCH_SIMULTANEOUS` | `'#FFD700'` | `colorTouchSimultaneous` | `Color(0xFFFFD700)` | 238 |
| 145 | `COLORS.TOUCH_HOLD_RED` | `'#FF6B6B'` | `colorTouchHoldRed` | `Color(0xFFFF6B6B)` | 241 |
| 146 | `COLORS.TOUCH_HOLD_YELLOW` | `'#FFE66D'` | `colorTouchHoldYellow` | `Color(0xFFFFE66D)` | 244 |
| 147 | `COLORS.TOUCH_HOLD_GREEN` | `'#2ECC71'` | `colorTouchHoldGreen` | `Color(0xFF2ECC71)` | 247 |
| 148 | `COLORS.TOUCH_HOLD_BLUE` | `'#3498DB'` | `colorTouchHoldBlue` | `Color(0xFF3498DB)` | 250 |
| 150 | `COLORS.EX_OVERLAY_BREAK` | `'rgba(255, 200, 120, 0.8)'` | `colorExOverlayBreak` | `Color.fromRGBO(255,200,120,0.8)` | 253 |
| 151 | `COLORS.EX_OVERLAY_SIMULTANEOUS` | `'rgba(255, 245, 150, 0.8)'` | `colorExOverlaySimultaneous` | `Color.fromRGBO(255,245,150,0.8)` | 256 |
| 152 | `COLORS.EX_OVERLAY_NORMAL` | `'rgba(255, 180, 210, 0.8)'` | `colorExOverlayNormal` | `Color.fromRGBO(255,180,210,0.8)` | 264 |
| 154 | `COLORS.WHITE` | `'#ffffff'` | `colorWhite` | `Color(0xFFFFFFFF)` | 267 |
| 155 | `COLORS.CONNECTOR_GOLD` | `'#FFD700'` | `colorConnectorGold` | `Color(0xFFFFD700)` | 270 |
| 156 | `COLORS.HIT_EFFECT_GOLD` | `'#F5EA72'` | `colorHitEffectGold` | `Color(0xFFF5EA72)` | 273 |
| 159 | `COLORS.DDR_RED` | `'#FF0000'` | `colorDdrRed` | `Color(0xFFFF0000)` | 278 |
| 160 | `COLORS.DDR_BLUE` | `'#0066FF'` | `colorDdrBlue` | `Color(0xFF0066FF)` | 281 |
| 161 | `COLORS.DDR_YELLOW` | `'#FFFF00'` | `colorDdrYellow` | `Color(0xFFFFFF00)` | 284 |
| 162 | `COLORS.DDR_GREEN` | `'#00FF00'` | `colorDdrGreen` | `Color(0xFF00FF00)` | 287 |
| 163 | `COLORS.DDR_ORANGE` | `'#FF8800'` | `colorDdrOrange` | `Color(0xFFFF8800)` | 290 |
| 164 | `COLORS.DDR_CYAN` | `'#00DDFF'` | `colorDdrCyan` | `Color(0xFF00DDFF)` | 293 |
| 165 | `COLORS.DDR_PINK` | `'#FF44AA'` | `colorDdrPink` | `Color(0xFFFF44AA)` | 296 |

## 材质与效果（constants.ts:167-177）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 169 | `NOTE_LIGHTEN_RATIO` | `0.18` | `noteLightenRatio` | `0.18` | 303 |
| 170 | `DDR_DARKEN_RATIO` | `0.25` | `ddrDarkenRatio` | `0.25` | 306 |
| 173 | `FADE_IN_DURATION_MS` | `150` | `fadeInDurationMs` | `150` | 309 |
| 176 | `RAINBOW_SPEED_DEG_PER_SEC` | `60` | `rainbowSpeedDegPerSec` | `60` | 312 |

## 渲染顺序 RENDER_ORDER（constants.ts:178-189）

| TS 行 | TS 常量 | TS 值 | Dart 常量 | Dart 值 | Dart 行 |
|---|---|---|---|---|---|
| 179 | `RENDER_ORDER`（对象声明） | — | `SimaiVisualTokens`（类内 const 表） | — | — |
| 180 | `RENDER_ORDER.JUDGMENT_LINE` | `0` | `renderOrderJudgmentLine` | `0` | 319 |
| 181 | `RENDER_ORDER.SLIDE_TRACKS` | `1` | `renderOrderSlideTracks` | `1` | 322 |
| 182 | `RENDER_ORDER.SLIDE_TRACKS_STARS` | `2` | `renderOrderSlideTracksStars` | `2` | 325 |
| 183 | `RENDER_ORDER.CONNECTORS` | `3` | `renderOrderConnectors` | `3` | 328 |
| 184 | `RENDER_ORDER.HOLD_NOTES` | `4` | `renderOrderHoldNotes` | `4` | 331 |
| 185 | `RENDER_ORDER.TOUCH_NOTES` | `5` | `renderOrderTouchNotes` | `5` | 334 |
| 186 | `RENDER_ORDER.SLIDE_STARTS` | `6` | `renderOrderSlideStarts` | `6` | 337 |
| 187 | `RENDER_ORDER.TAP_NOTES` | `7` | `renderOrderTapNotes` | `7` | 340 |
| 188 | `RENDER_ORDER.UI_OVERLAY` | `8` | `renderOrderUiOverlay` | `8` | 343 |

## simai_colors.dart 旧名 → 令牌（保留公开名）

| 旧公开名 | 新 token |
|---|---|
| `SimaiColors.tapNormal` | `SimaiVisualTokens.colorTapPink` |
| `SimaiColors.tapEach` | `SimaiVisualTokens.colorSimultaneousGold` |
| `SimaiColors.tapBreak` | `SimaiVisualTokens.colorBreakOrange` |
| `SimaiColors.slideNormal` | `SimaiVisualTokens.colorSlideCyan` |
| `SimaiColors.slideEach` | `SimaiVisualTokens.colorSlideSimultaneous` |
| `SimaiColors.slideBreak` | `SimaiVisualTokens.colorBreakOrange` |
| `SimaiColors.holdNormal` | `SimaiVisualTokens.colorHoldPink` |
| `SimaiColors.holdEach` | `SimaiVisualTokens.colorSimultaneousGold` |
| `SimaiColors.holdBreak` | `SimaiVisualTokens.colorHoldBreak` |
| `SimaiColors.touchNormal` | `SimaiVisualTokens.colorTouchCyan` |
| `SimaiColors.touchEach` | `SimaiVisualTokens.colorTouchSimultaneous` |
| `SimaiColors.touchBreak` | `SimaiVisualTokens.colorBreakOrange` |
| `SimaiColors.touchHoldTopLeft` | `SimaiVisualTokens.colorTouchHoldBlue` |
| `SimaiColors.touchHoldTopRight` | `SimaiVisualTokens.colorTouchHoldRed` |
| `SimaiColors.touchHoldBottomLeft` | `SimaiVisualTokens.colorTouchHoldGreen` |
| `SimaiColors.touchHoldBottomRight` | `SimaiVisualTokens.colorTouchHoldYellow` |
| `SimaiColors.judgeLine` | `SimaiVisualTokens.colorWhite` |

> 旧值的十六进制若与新令牌不同（如 `tapEach` 旧 `#FFD900` → `SIMULTANEOUS_GOLD` `#FFD700`），以 TS 令牌为准；保留旧名只为不破坏调用方。
