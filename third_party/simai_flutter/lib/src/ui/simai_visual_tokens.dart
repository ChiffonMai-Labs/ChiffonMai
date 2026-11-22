// 视觉令牌：逐值移植自 v.wmc.pub 预览站（git e16754f）
// `src/chart/utils/constants.ts:1-189`。
//
// 约定：
// - 命名直译 TS 常量语义，值保持精确；角度与比例保留原算式，避免提前四舍五入。
// - 每项注释标出 TS 原名与行号，方便和 SIMAI_VISUAL_TOKENS_MAP.md 逐行核对。
// - 本文件只做常量声明，不写渲染逻辑。

import 'dart:math' as math;
import 'dart:ui';

abstract final class SimaiVisualTokens {
  // ---------------------------------------------------------------------------
  // 时间与拍子
  // ---------------------------------------------------------------------------

  /// Note 接近判定线基础时间（毫秒）。TS: BASE_APPROACH_TIME_MS（:2）
  static const int baseApproachTimeMs = 2250;

  /// 标准拍子（4/4 拍子）。TS: BEATS_PER_MEASURE（:5）
  static const int beatsPerMeasure = 4;

  /// 小节内位置分辨率（0-511）。TS: POSITION_TICKS_PER_MEASURE（:8）
  static const int positionTicksPerMeasure = 512;

  /// 正解音基础偏移（毫秒）。TS: ANSWER_SOUND_BASE_OFFSET_MS（:11）
  static const int answerSoundBaseOffsetMs = -50;

  /// Note 声音播放窗口（毫秒）。TS: NOTE_PLAY_WINDOW_MS（:14）
  static const int notePlayWindowMs = 20;

  /// 默认 Note 超过判定线后不可见时间（毫秒）。TS: NOTE_VISIBILITY_AFTER_MS（:17）
  static const int noteVisibilityAfterMs = 0;

  // ---------------------------------------------------------------------------
  // 按钮与角度
  // ---------------------------------------------------------------------------

  /// 圆圈周围按钮数量。TS: BUTTON_COUNT（:20）
  static const int buttonCount = 8;

  /// 相邻按钮之间的角度（弧度）。TS: BUTTON_ANGLE_STEP（:23）
  static const double buttonAngleStep = math.pi / 4;

  /// 1 号键开始角度偏移（弧度）。TS: BUTTON_ANGLE_OFFSET（:26）
  static const double buttonAngleOffset = math.pi / 8;

  /// 基础角度（向上）。TS: BASE_ANGLE（:29）
  static const double baseAngle = -math.pi / 2;

  // ---------------------------------------------------------------------------
  // Note 几何比例
  // ---------------------------------------------------------------------------

  /// Note 圆圈大小比例。TS: NOTE_SIZE_RATIO（:32）
  static const double noteSizeRatio = 1 / 12.5;

  /// 点击 Note 内环比例。TS: TAP_INNER_RING_RATIO（:35）
  static const double tapInnerRingRatio = 0.65;

  /// Note 开始接近时大小比例。TS: APPROACH_START_SCALE（:38）
  static const double approachStartScale = 0.25;

  /// 按钮位置标记大小比例。TS: BUTTON_MARKER_RATIO（:41）
  static const double buttonMarkerRatio = 9 / 300;

  /// Note 线条宽度比例。TS: NOTE_STROKE_WIDTH_RATIO（:44）
  static const double noteStrokeWidthRatio = 2 / 300;

  /// 判定线宽度比例。TS: JUDGMENT_LINE_WIDTH_RATIO（:47）
  static const double judgmentLineWidthRatio = 3 / 300;

  // ---------------------------------------------------------------------------
  // 滑条
  // ---------------------------------------------------------------------------

  /// 滑条箭头线宽。TS: SLIDE_ARROW_WIDTH_RATIO（:50）
  static const double slideArrowWidthRatio = 12.8 / 300;

  /// 滑条箭头间距（基半径时像素）。TS: SLIDE_ARROW_SPACING（:53）
  static const double slideArrowSpacing = 26.896180742334582;

  /// 滑条 S/Z 曲线偏移比例。TS: SLIDE_CURVE_OFFSET_RATIO（:56）
  static const double slideCurveOffsetRatio = 0.4;

  /// 滑条 pp/qq 曲线半径比例。TS: SLIDE_PP_CURVE_RADIUS_RATIO（:59）
  static const double slidePpCurveRadiusRatio = 0.45;

  /// WiFi 滑条间距（大于普通滑条）。TS: WIFI_ARROW_SPACING（:62）
  static const double wifiArrowSpacing = 46.64867217847119;

  /// WiFi 滑条基础大小。TS: WIFI_ARROW_BASE_SIZE（:65）
  static const double wifiArrowBaseSize = 20;

  /// WiFi 滑条最大大小。TS: WIFI_ARROW_MAX_SIZE（:68）
  static const double wifiArrowMaxSize = 280;

  // ---------------------------------------------------------------------------
  // 长条
  // ---------------------------------------------------------------------------

  /// 长条 Note 宽度比例。TS: HOLD_WIDTH_RATIO（:71）
  static const double holdWidthRatio = 1.5;

  /// 长条 Note 内环比例。TS: HOLD_INNER_RATIO（:74）
  static const double holdInnerRatio = 0.62;

  // ---------------------------------------------------------------------------
  // 触摸 Note
  // ---------------------------------------------------------------------------

  /// 触摸 Note 接近时间乘数。TS: TOUCH_APPROACH_MULTIPLIER（:77）
  static const double touchApproachMultiplier = 0.9;

  /// 触摸 Note 中心点大小比例。TS: TOUCH_CENTER_DOT_RATIO（:80）
  static const double touchCenterDotRatio = 1 / 37.5;

  /// 触摸 Note 开放时花瓣距离。TS: TOUCH_PETAL_OPEN_RATIO（:83）
  static const double touchPetalOpenRatio = 1 / 6.25;

  /// 触摸 Note 关闭时花瓣距离。TS: TOUCH_PETAL_CLOSED_RATIO（:86）
  static const double touchPetalClosedRatio = 1 / 12.5;

  /// 触摸 Hold 进度条宽度比例。TS: TOUCH_HOLD_PROGRESS_WIDTH_RATIO（:89）
  static const double touchHoldProgressWidthRatio = 1 / 31.25;

  /// 触摸传感器半径：外环。TS: TOUCH_SENSOR_RADII.A（:93）
  static const double touchSensorRadiusA = 0.9;

  /// 触摸传感器半径：内环。TS: TOUCH_SENSOR_RADII.B（:94）
  static const double touchSensorRadiusB = 0.465;

  /// 触摸传感器半径：中心。TS: TOUCH_SENSOR_RADII.C（:95）
  static const double touchSensorRadiusC = 0;

  /// 触摸传感器半径：按钮区域。TS: TOUCH_SENSOR_RADII.D（:96）
  static const double touchSensorRadiusD = 0.9;

  /// 触摸传感器半径：边缘。TS: TOUCH_SENSOR_RADII.E（:97）
  static const double touchSensorRadiusE = 0.66;

  /// 触摸传感器半径表（键与 TS 的 A-E 一致）。
  static const Map<String, double> touchSensorRadii = <String, double>{
    'A': touchSensorRadiusA,
    'B': touchSensorRadiusB,
    'C': touchSensorRadiusC,
    'D': touchSensorRadiusD,
    'E': touchSensorRadiusE,
  };

  // ---------------------------------------------------------------------------
  // 流速与播放速度
  // ---------------------------------------------------------------------------

  /// 最慢流速。TS: HI_SPEED_MIN（:101）
  static const int hiSpeedMin = 3;

  /// 最快流速。TS: HI_SPEED_MAX（:104）
  static const int hiSpeedMax = 9;

  /// 默认流速。TS: HI_SPEED_DEFAULT（:107）
  static const int hiSpeedDefault = 6;

  /// 流速转换因子。TS: HI_SPEED_CONVERSION_FACTOR（:110）
  static const double hiSpeedConversionFactor = (2 / 3) * 0.9;

  /// 最小播放速度。TS: PLAYBACK_SPEED_MIN（:113）
  static const double playbackSpeedMin = 0.1;

  /// 最大播放速度。TS: PLAYBACK_SPEED_MAX（:116）
  static const double playbackSpeedMax = 1.0;

  /// 默认播放速度。TS: PLAYBACK_SPEED_DEFAULT（:119）
  static const double playbackSpeedDefault = 1.0;

  // ---------------------------------------------------------------------------
  // 色表（TS: COLORS，:121-166；逐项标原行号）
  // ---------------------------------------------------------------------------

  /// 黑。TS: COLORS.BLACK（:122）
  static const Color colorBlack = Color(0xFF000000);

  /// 点击粉。TS: COLORS.TAP_PINK（:123）
  static const Color colorTapPink = Color(0xFFFF69B4);

  /// 点击渐变起点。TS: COLORS.TAP_GRADIENT_START（:124）
  static const Color colorTapGradientStart = Color(0xFFFD197D);

  /// 点击渐变终点。TS: COLORS.TAP_GRADIENT_END（:125）
  static const Color colorTapGradientEnd = Color(0xFFFF7DD5);

  /// 同时押金。TS: COLORS.SIMULTANEOUS_GOLD（:126）
  static const Color colorSimultaneousGold = Color(0xFFFFD700);

  /// 同时押渐变起点。TS: COLORS.SIMULTANEOUS_GRADIENT_START（:127）
  static const Color colorSimultaneousGradientStart = Color(0xFFFCB600);

  /// 同时押渐变终点。TS: COLORS.SIMULTANEOUS_GRADIENT_END（:128）
  static const Color colorSimultaneousGradientEnd = Color(0xFFFFFE00);

  /// Break 橙。TS: COLORS.BREAK_ORANGE（:129）
  static const Color colorBreakOrange = Color(0xFFFF8C00);

  /// Break 渐变起点。TS: COLORS.BREAK_GRADIENT_START（:130）
  static const Color colorBreakGradientStart = Color(0xFFFFB347);

  /// Break 渐变中点。TS: COLORS.BREAK_GRADIENT_MID（:131）
  static const Color colorBreakGradientMid = Color(0xFFFF8C00);

  /// Break 渐变终点。TS: COLORS.BREAK_GRADIENT_END（:132）
  static const Color colorBreakGradientEnd = Color(0xFFFF6600);

  /// 滑条青。TS: COLORS.SLIDE_CYAN（:134）
  static const Color colorSlideCyan = Color(0xFF01FBFD);

  /// 滑条箭头（右）。TS: COLORS.SLIDE_ARROW_RIGHT（:135）
  static const Color colorSlideArrowRight = Color(0xFFFF9001);

  /// 滑条粉。TS: COLORS.SLIDE_PINK（:136）
  static const Color colorSlidePink = Color(0xFFFF69B4);

  /// 滑条同时押。TS: COLORS.SLIDE_SIMULTANEOUS（:137）
  static const Color colorSlideSimultaneous = Color(0xFFFFED24);

  /// 长条粉。TS: COLORS.HOLD_PINK（:139）
  static const Color colorHoldPink = Color(0xFFFF69B4);

  /// 长条 Break。TS: COLORS.HOLD_BREAK（:140）
  static const Color colorHoldBreak = Color(0xFFFF8C00);

  /// 触摸青。TS: COLORS.TOUCH_CYAN（:142）
  static const Color colorTouchCyan = Color(0xFF00FFFF);

  /// 触摸蓝。TS: COLORS.TOUCH_BLUE（:143）
  static const Color colorTouchBlue = Color(0xFF0080FF);

  /// 触摸同时押。TS: COLORS.TOUCH_SIMULTANEOUS（:144）
  static const Color colorTouchSimultaneous = Color(0xFFFFD700);

  /// 触摸 Hold 红。TS: COLORS.TOUCH_HOLD_RED（:145）
  static const Color colorTouchHoldRed = Color(0xFFFF6B6B);

  /// 触摸 Hold 黄。TS: COLORS.TOUCH_HOLD_YELLOW（:146）
  static const Color colorTouchHoldYellow = Color(0xFFFFE66D);

  /// 触摸 Hold 绿。TS: COLORS.TOUCH_HOLD_GREEN（:147）
  static const Color colorTouchHoldGreen = Color(0xFF2ECC71);

  /// 触摸 Hold 蓝。TS: COLORS.TOUCH_HOLD_BLUE（:148）
  static const Color colorTouchHoldBlue = Color(0xFF3498DB);

  /// EX 覆层（Break）。TS: COLORS.EX_OVERLAY_BREAK（:150）
  static const Color colorExOverlayBreak = Color.fromRGBO(255, 200, 120, 0.8);

  /// EX 覆层（同时押）。TS: COLORS.EX_OVERLAY_SIMULTANEOUS（:151）
  static const Color colorExOverlaySimultaneous = Color.fromRGBO(
    255,
    245,
    150,
    0.8,
  );

  /// EX 覆层（普通）。TS: COLORS.EX_OVERLAY_NORMAL（:152）
  static const Color colorExOverlayNormal = Color.fromRGBO(255, 180, 210, 0.8);

  /// 白。TS: COLORS.WHITE（:154）
  static const Color colorWhite = Color(0xFFFFFFFF);

  /// 连接线金。TS: COLORS.CONNECTOR_GOLD（:155）
  static const Color colorConnectorGold = Color(0xFFFFD700);

  /// 打击效果金。TS: COLORS.HIT_EFFECT_GOLD（:156）
  static const Color colorHitEffectGold = Color(0xFFF5EA72);

  // DDR 判定颜色

  /// DDR 判定色：1/1（节拍内）。TS: COLORS.DDR_RED（:159）
  static const Color colorDdrRed = Color(0xFFFF0000);

  /// DDR 判定色：1/2。TS: COLORS.DDR_BLUE（:160）
  static const Color colorDdrBlue = Color(0xFF0066FF);

  /// DDR 判定色：1/4。TS: COLORS.DDR_YELLOW（:161）
  static const Color colorDdrYellow = Color(0xFFFFFF00);

  /// DDR 判定色：1/8+。TS: COLORS.DDR_GREEN（:162）
  static const Color colorDdrGreen = Color(0xFF00FF00);

  /// DDR 判定色：1/8（扩展）。TS: COLORS.DDR_ORANGE（:163）
  static const Color colorDdrOrange = Color(0xFFFF8800);

  /// DDR 判定色：1/6（扩展）。TS: COLORS.DDR_CYAN（:164）
  static const Color colorDdrCyan = Color(0xFF00DDFF);

  /// DDR 判定色：1/12（扩展）。TS: COLORS.DDR_PINK（:165）
  static const Color colorDdrPink = Color(0xFFFF44AA);

  // ---------------------------------------------------------------------------
  // 材质与效果
  // ---------------------------------------------------------------------------

  /// 街机风点击材质的提亮比例。TS: NOTE_LIGHTEN_RATIO（:169）
  static const double noteLightenRatio = 0.18;

  /// DDR 模式压暗比例。TS: DDR_DARKEN_RATIO（:170）
  static const double ddrDarkenRatio = 0.25;

  /// 淡入效果持续时间（毫秒）。TS: FADE_IN_DURATION_MS（:173）
  static const int fadeInDurationMs = 150;

  /// 彩虹 BPM 动画速度（每秒角度数）。TS: RAINBOW_SPEED_DEG_PER_SEC（:176）
  static const double rainbowSpeedDegPerSec = 60;

  // ---------------------------------------------------------------------------
  // 渲染顺序（TS: RENDER_ORDER，:179-189；数值越小越先画）
  // ---------------------------------------------------------------------------

  /// 判定线。TS: RENDER_ORDER.JUDGMENT_LINE（:180）
  static const int renderOrderJudgmentLine = 0;

  /// 滑条轨道。TS: RENDER_ORDER.SLIDE_TRACKS（:181）
  static const int renderOrderSlideTracks = 1;

  /// 滑条轨道上的星。TS: RENDER_ORDER.SLIDE_TRACKS_STARS（:182）
  static const int renderOrderSlideTracksStars = 2;

  /// 连接线。TS: RENDER_ORDER.CONNECTORS（:183）
  static const int renderOrderConnectors = 3;

  /// 长条。TS: RENDER_ORDER.HOLD_NOTES（:184）
  static const int renderOrderHoldNotes = 4;

  /// 触摸 Note。TS: RENDER_ORDER.TOUCH_NOTES（:185）
  static const int renderOrderTouchNotes = 5;

  /// 滑条起手。TS: RENDER_ORDER.SLIDE_STARTS（:186）
  static const int renderOrderSlideStarts = 6;

  /// 点击 Note。TS: RENDER_ORDER.TAP_NOTES（:187）
  static const int renderOrderTapNotes = 7;

  /// UI 覆层。TS: RENDER_ORDER.UI_OVERLAY（:188）
  static const int renderOrderUiOverlay = 8;

  /// 渲染顺序表（键为 Dart 常量名去掉 `renderOrder` 前缀）。
  static const Map<String, int> renderOrder = <String, int>{
    'JUDGMENT_LINE': renderOrderJudgmentLine,
    'SLIDE_TRACKS': renderOrderSlideTracks,
    'SLIDE_TRACKS_STARS': renderOrderSlideTracksStars,
    'CONNECTORS': renderOrderConnectors,
    'HOLD_NOTES': renderOrderHoldNotes,
    'TOUCH_NOTES': renderOrderTouchNotes,
    'SLIDE_STARTS': renderOrderSlideStarts,
    'TAP_NOTES': renderOrderTapNotes,
    'UI_OVERLAY': renderOrderUiOverlay,
  };
}
