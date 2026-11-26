/// 谱面预览与视频导出时的盘面中央显示模式。
enum SimaiCenterDisplayMode {
  achievementAdd('0%+'),
  achievement100Plus('100%+'),
  achievement101Subtract('101%-'),
  dxScoreAdd('DX分数+'),
  dxScoreSubtract('DX分数-'),
  dxStars('星数+x'),
  combo('连击数'),
  overS('超过S级'),
  overSS('超过SS级'),
  overSSS('超过SSS级'),
  none('什么都不显示');

  const SimaiCenterDisplayMode(this.label);

  /// 界面选择器展示的中文名称。
  final String label;

  /// 解析枚举名称并兼容历史旧键（`achievement` 与 `achievement100Subtract`）。
  static SimaiCenterDisplayMode fromNameOrLegacy(
    Object? raw, {
    SimaiCenterDisplayMode fallback = SimaiCenterDisplayMode.achievementAdd,
  }) {
    if (raw is SimaiCenterDisplayMode) return raw;
    if (raw is String) {
      if (raw == 'achievement') return SimaiCenterDisplayMode.achievementAdd;
      if (raw == 'achievement100Subtract') {
        return SimaiCenterDisplayMode.achievement100Plus;
      }
      for (final value in values) {
        if (value.name == raw) return value;
      }
    } else if (raw is int && raw >= 0 && raw < values.length) {
      return values[raw];
    }
    return fallback;
  }
}

/// 格式化 DX 分数星级与距离当前星级门槛的差值（如 `✦6 +3`、`✦1 -5`）。
///
/// 阈值与歌曲详情页 `SongInfoLoaders._calculateStarsBonus` 保持一致。
String formatSimaiDxStarBonus(int score, int maxDxScore) {
  if (maxDxScore <= 0) return '✦ 0 +0';
  final rate = score / maxDxScore;
  final String star;
  final double minRate;
  if (rate >= 0.99) {
    star = '6';
    minRate = 0.99;
  } else if (rate >= 0.98) {
    star = '5.5';
    minRate = 0.98;
  } else if (rate >= 0.97) {
    star = '5';
    minRate = 0.97;
  } else if (rate >= 0.95) {
    star = '4';
    minRate = 0.95;
  } else if (rate >= 0.93) {
    star = '3';
    minRate = 0.93;
  } else if (rate >= 0.90) {
    star = '2';
    minRate = 0.90;
  } else {
    // 低于 85%（0 星）时仍展示与 1 星门槛的负差距。
    star = '1';
    minRate = 0.85;
  }
  final minScore = (maxDxScore * minRate).ceil();
  final diff = score - minScore;
  final sign = diff >= 0 ? '+' : '';
  return '✦$star $sign$diff';
}
