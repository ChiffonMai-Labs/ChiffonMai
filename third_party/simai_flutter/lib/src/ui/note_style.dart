/// 谱面预览、游玩与视频导出时的音符视觉样式：
/// - [arcade]：立体经典（クラシック，锐利黑白双描边与四象限立体渐变）
/// - [simple]：圆润简洁（シンプル，DX 默认圆润厚环与胶囊 Hold）
/// - [bar]：切向条形（バー，沿判定环切线方向的圆角条形音符）
/// - [classic]：经典扁平（早期简约扁平样式）
enum SimaiNoteStyle {
  arcade('立体经典', '经典'),
  simple('圆润简洁', '简洁'),
  bar('切向条形', '条形'),
  classic('经典扁平', '扁平');

  const SimaiNoteStyle(this.label, this.shortLabel);

  /// 界面下拉选择器展示的完整中文名称。
  final String label;

  /// 分段按钮等紧凑控件使用的短名称。
  final String shortLabel;

  /// 是否启用精细视觉特效（如绝赞双色滑星箭头、柔光描边等）。
  bool get usesEnhancedVisuals => this != SimaiNoteStyle.classic;

  /// HOLD 可选样式列表（不含条形）。
  static const List<SimaiNoteStyle> holdValues = <SimaiNoteStyle>[
    SimaiNoteStyle.arcade,
    SimaiNoteStyle.simple,
    SimaiNoteStyle.classic,
  ];

  /// 将样式规范化为 HOLD 允许的取值（条形回退至 [fallback]）。
  static SimaiNoteStyle normalizeForHold(
    SimaiNoteStyle style, {
    SimaiNoteStyle fallback = SimaiNoteStyle.arcade,
  }) {
    if (style != SimaiNoteStyle.bar) return style;
    return fallback == SimaiNoteStyle.bar ? SimaiNoteStyle.arcade : fallback;
  }

  /// 解析 HOLD 样式名称，未知或条形值回退至 [fallback]。
  static SimaiNoteStyle fromHoldName(
    Object? raw, {
    SimaiNoteStyle fallback = SimaiNoteStyle.arcade,
  }) {
    final safeFallback = normalizeForHold(fallback);
    if (raw == null) return safeFallback;
    return normalizeForHold(
      fromName(raw, fallback: safeFallback),
      fallback: safeFallback,
    );
  }

  /// 解析枚举名称，未知或历史缺失值默认回退至 [fallback]。
  static SimaiNoteStyle fromName(
    Object? raw, {
    SimaiNoteStyle fallback = SimaiNoteStyle.arcade,
  }) {
    if (raw is SimaiNoteStyle) return raw;
    if (raw is String) {
      for (final value in values) {
        if (value.name == raw) return value;
      }
    } else if (raw is int && raw >= 0 && raw < values.length) {
      return values[raw];
    }
    return fallback;
  }
}
