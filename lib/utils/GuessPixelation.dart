import 'dart:math' as math;

/// 单人和多人共用的马赛克强度：50% 延续原有的 16×16 曲绘。
abstract final class GuessPixelation {
  static const defaultLevel = 50;

  static int normalize(num? level) => level == null || !level.isFinite
      ? defaultLevel
      : level.round().clamp(0, 100);

  /// 0% 由调用方直接展示原图，其余按指数缩减采样网格，100% 只保留一个色块。
  static int pixelsForLevel(int level) =>
      math.pow(256, 1 - normalize(level) / 100).round().clamp(1, 256);
}
