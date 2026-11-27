/// Timing ratios from Lxns-Network's maimai-chart-engine & maimai DX speed scale.
class NoteMotion {
  static const double baseApproachSeconds = 2.25;
  static const double hiSpeedConversionFactor = (2 / 3) * 0.9;
  static const double touchApproachMultiplier = 0.9;
  static const double initialRadiusRatio = 0.25;
  static const double scaleInProgressRatio = 0.5;

  /// 标准数值流速区间：1.00 ~ 10.00（步进 0.25）。
  static const double minSpeed = 1.0;
  static const double maxNumericSpeed = 10.0;
  static const double speedStep = 0.25;

  /// 紧跟 10.00 的下一档哨兵值：表示舞萌 DX 最高速档位「SONIC」。
  static const double sonicSpeedValue = 10.25;

  /// 滑块分段总数（1.00 ~ 10.00 共 36 段 + SONIC 1 段 = 37 段）。
  static const int speedSliderDivisions = 37;

  /// 舞萌 DX 机台 SONIC 对应的实际等效倍率（约 60 速，TAP 出现时长约 62.5ms ≈ 3.75 帧@60fps）。
  static const double sonicEffectiveSpeed = 60.0;

  static const double defaultApproachTime =
      baseApproachSeconds / (8 * hiSpeedConversionFactor);

  /// 将输入流速量化并限制到合法档位（1.00 ~ 10.00 或 SONIC=10.25）。
  static double normalizeSpeed(double speed, {double fallback = 8.0}) {
    final safe = speed.isFinite ? speed : fallback;
    final clamped = safe.clamp(minSpeed, sonicSpeedValue).toDouble();
    return ((clamped / speedStep).round() * speedStep).toDouble();
  }

  /// 判断是否为 SONIC 档位。
  static bool isSonicSpeed(double speed) =>
      speed.isFinite && speed >= maxNumericSpeed + speedStep * 0.5;

  /// 格式化流速展示文本：普通档位显示 `x8.00`（或 `8.00`），SONIC 显示 `SONIC`。
  static String formatSpeedLabel(double speed, {bool withPrefixX = true}) {
    final normalized = normalizeSpeed(speed);
    if (isSonicSpeed(normalized)) return 'SONIC';
    final text = normalized.toStringAsFixed(2);
    return withPrefixX ? 'x$text' : text;
  }

  /// 将存储值（支持数字或 `'SONIC'` 字符串）解析为规范化流速值。
  static double parseSpeed(Object? raw, {double fallback = 8.0}) {
    if (raw is String) {
      final trimmed = raw.trim().toLowerCase();
      if (trimmed == 'sonic') return sonicSpeedValue;
      final parsed = double.tryParse(trimmed);
      if (parsed != null) return normalizeSpeed(parsed, fallback: fallback);
      return normalizeSpeed(fallback);
    }
    if (raw is num) {
      return normalizeSpeed(raw.toDouble(), fallback: fallback);
    }
    return normalizeSpeed(fallback);
  }

  static double approachTimeForSpeed(double speed) {
    final normalized = normalizeSpeed(speed);
    final effectiveSpeed =
        isSonicSpeed(normalized) ? sonicEffectiveSpeed : normalized;
    return baseApproachSeconds / (effectiveSpeed * hiSpeedConversionFactor);
  }

  /// TOUCH 独立流速对应的出现时长（同速下与原 `approachTime * 0.9` 完全一致）。
  static double touchApproachTimeForSpeed(double touchSpeed) {
    return approachTimeForSpeed(touchSpeed) * touchApproachMultiplier;
  }

  /// SLIDE 显示时机范围：-1.0（更早显示轨道）~ +1.0（更晚显示轨道），步进 0.1，默认 0.0。
  static const double minSlideDisplayTiming = -1.0;
  static const double maxSlideDisplayTiming = 1.0;
  static const double slideDisplayTimingStep = 0.1;
  static const int slideDisplayTimingDivisions = 20;

  /// 将 SLIDE 显示时机规范化到 `[-1.0, +1.0]` 且保留 0.1 步进精度。
  static double normalizeSlideDisplayTiming(
    double value, {
    double fallback = 0.0,
  }) {
    final safe = value.isFinite ? value : fallback;
    final clamped =
        safe.clamp(minSlideDisplayTiming, maxSlideDisplayTiming).toDouble();
    final quantized = (clamped * 10.0).round() / 10.0;
    return quantized.abs() < 1e-6 ? 0.0 : quantized;
  }

  /// 格式化 SLIDE 显示时机文案：`-1.0` ~ `0.0` ~ `+1.0`。
  static String formatSlideDisplayTiming(double value) {
    final normalized = normalizeSlideDisplayTiming(value);
    if (normalized > 0) return '+${normalized.toStringAsFixed(1)}';
    return normalized.toStringAsFixed(1);
  }

  /// 计算 SLIDE 轨迹箭头提前于星头判定时间的出现时长（秒）。
  /// - 0.0：与星头同窗淡入（等于 [ringApproachTime]）
  /// - 负值（-1.0）：提早出现，最长扩至 `2.0 * ringApproachTime`
  /// - 正值（+1.0）：推迟出现，最短压至 `0.05 * ringApproachTime`（减少密集谱面遮挡）
  static double slideTrackApproachTime({
    required double ringApproachTime,
    required double slideDisplayTiming,
  }) {
    final safeRing = ringApproachTime.isFinite && ringApproachTime > 0.001
        ? ringApproachTime
        : defaultApproachTime;
    final normalized = normalizeSlideDisplayTiming(slideDisplayTiming);
    final factor = normalized <= 0.0
        ? 1.0 - normalized
        : (1.0 - normalized * 0.95).clamp(0.05, 1.0);
    return safeRing * factor;
  }
}
