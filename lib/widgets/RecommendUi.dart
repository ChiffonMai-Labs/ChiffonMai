import 'package:flutter/material.dart';

import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';
import 'AppUi.dart';
import 'MarqueeText.dart';

/// 目标 Rating / 定数区间 / 标签三个推荐页共用的部件。

/// 推荐页输入框：卡片里的凹槽底，无描边。
InputDecoration recommendInputDecoration(BuildContext context,
    {String? label, String? hint}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
    borderSide: BorderSide.none,
  );
  final decoration = InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: AppSurfaces.inset(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: border,
    enabledBorder: border,
  );
  return label == null ? decoration : decoration.insetLabel(context);
}

/// 一条推荐结果：曲绘 + 曲名 + 类型 / 难度 / 定数 + 说明行，右边是这条推荐的主要数值。
class RecommendResultCard extends StatelessWidget {
  final String songId;
  final String title;
  final String type;
  final int levelIndex;

  /// 等级（14+），显示在难度色徽章上。
  final String level;
  final double ds;

  /// 主要数值和它的名称（`99.50%` / 平均达成）。
  final String metricValue;
  final String metricLabel;
  final Color? metricColor;

  /// 说明行，每条一行，放不下时换行。
  final List<String> details;

  /// 每条说明都保持一行，放不下时等比缩小。
  final bool singleLineDetails;
  final Color? detailColor;

  /// 紧跟在主要数值下面的高亮文字（可提升的 Rating）。
  final String? highlight;
  final VoidCallback onTap;

  const RecommendResultCard({
    super.key,
    required this.songId,
    required this.title,
    required this.type,
    required this.levelIndex,
    required this.level,
    required this.ds,
    required this.metricValue,
    required this.metricLabel,
    required this.onTap,
    this.metricColor,
    this.details = const [],
    this.singleLineDetails = false,
    this.detailColor,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            child: CoverUtil.buildCoverWidget(songId, 68),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MarqueeText(
                  text: title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    SongTypeBadge(songId: songId, type: type),
                    const SizedBox(width: 4),
                    ChartDifficultyBadge(
                        levelIndex: levelIndex, songId: songId, label: level),
                    const SizedBox(width: 6),
                    Text(
                      ds.toStringAsFixed(1),
                      style: AppTheme.number(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                for (final detail in details)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: () {
                      final text = Text(
                        detail,
                        maxLines: singleLineDetails ? 1 : null,
                        softWrap: !singleLineDetails,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.3,
                          color: detailColor ?? scheme.onSurfaceVariant,
                        ),
                      );
                      return singleLineDetails
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: text,
                            )
                          : text;
                    }(),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metricValue,
                style: AppTheme.number(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: metricColor ?? scheme.onSurface,
                ),
              ),
              Text(
                metricLabel,
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
              if (highlight != null) ...[
                const SizedBox(height: 4),
                Text(
                  highlight!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        AppColors.successGreen(Theme.of(context).brightness),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
