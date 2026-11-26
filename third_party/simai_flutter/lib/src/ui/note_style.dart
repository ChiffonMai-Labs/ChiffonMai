/// 谱面预览、游玩与视频导出时的音符视觉样式。
enum SimaiNoteStyle {
  arcade('街机还原'),
  classic('经典扁平');

  const SimaiNoteStyle(this.label);

  /// 界面选择器展示的中文名称。
  final String label;

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
