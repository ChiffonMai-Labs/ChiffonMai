import 'package:flutter/material.dart';

import '../utils/ColorUtil.dart';
import '../utils/StringUtil.dart';
import 'SmoothLinearProgressIndicator.dart';

/// 导出图片里的统计区域。
///
/// 导出图固定 1200 宽、固定浅色，不跟随 App 主题，所以颜色写在这里而不是取
/// `ColorScheme`：同一份数据不管手机当时是什么主题，导出来都长一样。
class ExportStatsColors {
  static const accent = Color(0xFF006A6A);
  static const inset = Color(0xFFF0F4F3);
  static const track = Color(0xFFDFE6E4);
  static const ink = Color(0xFF16201F);
  static const muted = Color(0xFF5F6B6A);
  static const positive = Color(0xFF1E8E4E);
  static const negative = Color(0xFFD23C3C);
}

/// 统计区域的白底面板。
class ExportStatsPanel extends StatelessWidget {
  final Widget child;

  const ExportStatsPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: child,
    );
  }
}

/// 主角数值（Rating、完成率）：主题色实心块。
class ExportHeroBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;

  const ExportHeroBlock(
      {super.key, required this.label, required this.value, this.caption});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ExportStatsColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85))),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 72,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          if (caption != null)
            Text(caption!,
                style: TextStyle(
                    fontSize: 24, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }
}

/// 次要数值：浅底小块。
class ExportStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color valueColor;

  const ExportStatBlock({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor = ExportStatsColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ExportStatsColors.inset,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: ExportStatsColors.muted)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: valueColor)),
          ),
          if (caption != null)
            Text(caption!,
                style: const TextStyle(
                    fontSize: 20, color: ExportStatsColors.muted)),
        ],
      ),
    );
  }
}

/// 平均达成率 + DX 分数达成率 + 星级。
class ExportAchievementBlock extends StatelessWidget {
  final String label;
  final double achievement;

  /// 0–1。
  final double scoreRate;

  const ExportAchievementBlock({
    super.key,
    required this.label,
    required this.achievement,
    required this.scoreRate,
  });

  @override
  Widget build(BuildContext context) {
    final stars = StringUtil.formatStars(scoreRate);
    final starsColor = ColorUtil.getStarsColor(stars);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ExportStatsColors.inset,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: ExportStatsColors.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${achievement.toStringAsFixed(4)}%',
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: ExportStatsColors.ink)),
                const SizedBox(width: 14),
                Text('DX分数 ${(scoreRate * 100).toStringAsFixed(2)}%',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: ExportStatsColors.muted)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    // 没有星级时 getStarsColor 回落到白色，白底上看不见
                    color: starsColor == Colors.white
                        ? ExportStatsColors.track
                        : starsColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(stars,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F1A10))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 一个难度的完成进度。
class ExportDifficultyStat {
  final String name;
  final Color color;
  final int completed;
  final int total;
  final double rate;

  const ExportDifficultyStat({
    required this.name,
    required this.color,
    required this.completed,
    required this.total,
    required this.rate,
  });
}

/// 牌子进度 / 个性化成绩查询的统计区域。
class ExportCompletionPanel extends StatelessWidget {
  final String title;
  final int total;
  final int completed;
  final double completionRate;
  final double averageAchievement;

  /// 各难度进度条；为空时不显示这一段。
  final List<ExportDifficultyStat> difficultyStats;

  const ExportCompletionPanel({
    super.key,
    required this.title,
    required this.total,
    required this.completed,
    required this.completionRate,
    required this.averageAchievement,
    this.difficultyStats = const [],
  });

  Widget _bar(double value, Color color, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SmoothLinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        backgroundColor: ExportStatsColors.track,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: height,
        animate: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExportStatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: ExportStatsColors.ink)),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ExportHeroBlock(
                    label: '完成率',
                    value: '${completionRate.toStringAsFixed(1)}%',
                    caption: '$completed / $total',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                    flex: 2,
                    child: ExportStatBlock(label: '总歌曲数', value: '$total')),
                const SizedBox(width: 10),
                Expanded(
                    flex: 2,
                    child: ExportStatBlock(
                        label: '已完成',
                        value: '$completed',
                        valueColor: ExportStatsColors.positive)),
                const SizedBox(width: 10),
                Expanded(
                    flex: 2,
                    child: ExportStatBlock(
                        label: '未完成', value: '${total - completed}')),
                const SizedBox(width: 10),
                Expanded(
                    flex: 3,
                    child: ExportStatBlock(
                        label: '平均达成率',
                        value: '${averageAchievement.toStringAsFixed(2)}%')),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _bar(completionRate / 100, ExportStatsColors.accent, 14),
          if (difficultyStats.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final stat in difficultyStats)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(stat.name,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: stat.color)),
                    ),
                    Expanded(child: _bar(stat.rate, stat.color, 12)),
                    SizedBox(
                      width: 130,
                      child: Text('${stat.completed} / ${stat.total}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: ExportStatsColors.ink)),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
