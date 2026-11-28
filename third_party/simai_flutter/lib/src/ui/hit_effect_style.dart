/// 谱面预览、游玩与视频导出时的打击特效样式：
/// - [ring]：柔光环（轻量单层柔光圆环，连打时视野简洁）
/// - [arcadeBurst]：星芒光效（六边形击打光效，绝赞附带双层光环、八向星芒与星屑）
enum SimaiHitEffectStyle {
  ring('柔光环', '柔光环', '轻量单层柔光圆环，连打时视野简洁'),
  arcadeBurst(
    '星芒光效',
    '星芒',
    '六边形击打光效，绝赞附带双层光环、八向星芒与星屑',
  );

  const SimaiHitEffectStyle(this.label, this.shortLabel, this.description);

  /// 界面下拉选择器展示的完整中文名称。
  final String label;

  /// 分段按钮等紧凑控件使用的短名称。
  final String shortLabel;

  /// 设置项说明文案。
  final String description;

  /// 解析枚举名称或索引，未知或缺失值默认回退至 [fallback]。
  static SimaiHitEffectStyle fromName(
    Object? raw, {
    SimaiHitEffectStyle fallback = SimaiHitEffectStyle.ring,
  }) {
    if (raw is SimaiHitEffectStyle) return raw;
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
