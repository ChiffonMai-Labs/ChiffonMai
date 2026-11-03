import '../entity/KaleidXScope/KaleidXScopeGate.dart';

/// 万花镜日期统一按 2026 年展示。接口历史上同时出现过 ISO、斜线、点号和中文格式，
/// 不能把无法解析的值静默当成 1 月 1 日，否则整页会误报当前时间段。
class KaleidDateUtil {
  /// 今天所处的阶段，没有进行中的阶段时返回 null。
  static ChallengePhase? currentPhase(
      Iterable<KaleidXScopeChallenge> challenges) {
    final today = DateTime(2026, DateTime.now().month, DateTime.now().day);
    for (final challenge in challenges) {
      for (final phase in challenge.phases) {
        final start = parse(phase.startDate);
        final end = phase.endDate == null ? null : parse(phase.endDate!);
        if (start != null &&
            !today.isBefore(start) &&
            (end == null || !today.isAfter(end))) {
          return phase;
        }
      }
    }
    return null;
  }

  static DateTime? parse(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    final chinese =
        RegExp(r'^(?:2026年)?\s*(\d{1,2})月\s*(\d{1,2})日').firstMatch(value);
    if (chinese != null)
      return _safe(int.parse(chinese.group(1)!), int.parse(chinese.group(2)!));
    final iso =
        RegExp(r'^(?:\d{4}[-/.])?(\d{1,2})[-/.](\d{1,2})').firstMatch(value);
    if (iso != null)
      return _safe(int.parse(iso.group(1)!), int.parse(iso.group(2)!));
    final md = RegExp(r'^(\d{1,2})\s*[月/.\-]\s*(\d{1,2})').firstMatch(value);
    if (md != null)
      return _safe(int.parse(md.group(1)!), int.parse(md.group(2)!));
    return null;
  }

  static DateTime? _safe(int month, int day) {
    final date = DateTime(2026, month, day);
    return date.year == 2026 && date.month == month && date.day == day
        ? date
        : null;
  }

  static String format(String raw) {
    final date = parse(raw);
    return date == null ? '日期待更新' : '${date.month}月${date.day}日';
  }

  static String range(String start, String? end) =>
      '${format(start)} - ${end == null || end.trim().isEmpty ? '后续' : format(end)}';
}
