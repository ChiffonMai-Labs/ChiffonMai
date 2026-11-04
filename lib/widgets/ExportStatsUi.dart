import 'package:flutter/material.dart';

import '../constant/AppLinks.dart';
import '../utils/ColorUtil.dart';
import '../utils/ExportImageTheme.dart';
import '../utils/ExportUserInfoWidget.dart';
import '../utils/StringUtil.dart';
import 'LxnsAssetImage.dart';
import 'SmoothLinearProgressIndicator.dart';

export '../utils/ExportImageTheme.dart';

/// 导出图片共用的页面底色、面板、标题和统计区域。
///
/// 配色见 [ExportPalette]，由 [ExportPage] 传下来，不跟随 App 主题。

/// 导出图片的根：铺页面底色，把主题传给里面所有组件。
class ExportPage extends StatelessWidget {
  final ExportImageTheme theme;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const ExportPage({
    super.key,
    required this.theme,
    this.width,
    this.height,
    this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ExportThemeScope(
      theme: theme,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        color: ExportPalette.forTheme(theme).page,
        child: child,
      ),
    );
  }
}

/// 导出图头部的渐变底：两个淡淡的大圆，右上和左下各一个。
class ExportHeroSurface extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final double radius;
  final EdgeInsetsGeometry padding;

  const ExportHeroSurface({
    super.key,
    required this.child,
    this.colors,
    this.radius = 36,
    this.padding = const EdgeInsets.all(40),
  });

  @override
  Widget build(BuildContext context) {
    final c = ExportPalette.of(context);
    Widget ring(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors ?? [c.heroDeep, c.heroLight],
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -120, top: -160, child: ring(520)),
            Positioned(left: -90, bottom: -180, child: ring(360)),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// 导出图头部：玩家头像、昵称、Rating、姓名框，右边是标题和数据来源。
///
/// [scale] 按导出宽度换算：1700 宽的 Best50 用 1，1200 宽的用 0.7。
/// [showUser] 为 false 时（理论 Best50）只显示标题和数据来源。
class ExportPosterHeader extends StatelessWidget {
  final String title;
  final String? caption;
  final bool showUser;
  final int? selectedPlateId;
  final double scale;

  const ExportPosterHeader({
    super.key,
    required this.title,
    this.caption,
    this.showUser = true,
    this.selectedPlateId,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ExportUserInfoWidget.loadUserInfo(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const <String, dynamic>{};
        return ExportHeroSurface(
          radius: 36 * scale,
          padding: EdgeInsets.all(36 * scale),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showUser) Expanded(flex: 3, child: _player(data)),
                if (showUser) SizedBox(width: 32 * scale),
                Expanded(flex: 2, child: _titleBlock(data)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _player(Map<String, dynamic> data) {
    final avatarUrl = data['avatarUrl'] as String? ?? '';
    final nickname = data['nickname'] as String? ?? '';
    final totalRating = data['totalRating'] as int? ?? 0;
    final best35 = data['best35Rating'] as int? ?? 0;
    final best15 = data['best15Rating'] as int? ?? 0;
    final plateId = selectedPlateId ?? data['plateId'] as int?;
    final avatarSize = 176 * scale;
    final avatarFallback = Icon(Icons.person_rounded,
        size: 96 * scale, color: ExportPalette.light.muted);
    return Row(
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36 * scale),
            border: Border.all(color: Colors.white, width: 6 * scale),
          ),
          child: avatarUrl.isEmpty
              ? avatarFallback
              : LxnsAssetImage(
                  url: avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: avatarFallback,
                  errorWidget: avatarFallback,
                ),
        ),
        SizedBox(width: 28 * scale),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  nickname.isNotEmpty ? nickname : '未知玩家',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 54 * scale,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8 * scale),
              Row(
                children: [
                  ColorUtil.buildRatingBadge(totalRating, height: 52 * scale),
                  SizedBox(width: 18 * scale),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'B35 $best35  ·  B15 $best15',
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 28 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (plateId != null) ...[
                SizedBox(height: 12 * scale),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: SizedBox(
                    height: 84 * scale,
                    child: LxnsAssetImage(
                      url: lxnsPlateUrl(plateId),
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      placeholder: const SizedBox.shrink(),
                      errorWidget: const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _titleBlock(Map<String, dynamic> data) {
    final source = data['dataSource'] as String? ?? '';
    final time = data['exportTime'] as String? ?? '';
    final metaStyle = TextStyle(
      fontSize: 22 * scale,
      height: 1.45,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.78),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          showUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            maxLines: 1,
            style: TextStyle(
              fontSize: 72 * scale,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: TextStyle(
              fontSize: 26 * scale,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        SizedBox(height: 14 * scale),
        for (final line in [
          '数据源 ${source.isNotEmpty ? source : '未知'}',
          time,
          'Generated by ChiffonMai · 交流群 ${AppLinks.qqGroupNumber}',
        ])
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(line, maxLines: 1, style: metaStyle),
          ),
      ],
    );
  }
}

/// 分区标题：实心胶囊 + 说明文字。标题里的 ` | ` 后半段显示成说明。
class ExportSectionTitle extends StatelessWidget {
  final String title;

  const ExportSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = ExportPalette.of(context);
    final parts = title.split(' | ');
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: c.ink,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              parts.first,
              style: TextStyle(
                fontSize: 34,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: c.onInk,
              ),
            ),
          ),
        ),
        if (parts.length > 1) ...[
          const SizedBox(width: 18),
          Flexible(
            child: Text(
              parts.sublist(1).join(' | '),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: c.muted,
              ),
            ),
          ),
        ],
      ],
    );
  }
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
        color: ExportPalette.of(context).panel,
        borderRadius: BorderRadius.circular(32),
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
    final c = ExportPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.heroDeep, c.heroLight],
        ),
        borderRadius: BorderRadius.circular(24),
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
  final Color? valueColor;

  /// 差值类的数字：true 用正向色，false 用负向色。
  final bool? positive;

  const ExportStatBlock({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.valueColor,
    this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final c = ExportPalette.of(context);
    final signed = positive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.inset,
        borderRadius: BorderRadius.circular(20),
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
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: c.muted)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                maxLines: 1,
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: valueColor ??
                        (signed == null
                            ? c.ink
                            : (signed ? c.positive : c.negative)))),
          ),
          if (caption != null)
            Text(caption!,
                style: TextStyle(
                    fontSize: 20, color: c.muted)),
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
    final c = ExportPalette.of(context);
    // 没有星级时底色是轨道色，深色下要配浅色字。
    final noStars = starsColor == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: c.inset,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: c.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${achievement.toStringAsFixed(4)}%',
                    style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: c.ink)),
                const SizedBox(width: 14),
                Text('DX分数 ${(scoreRate * 100).toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: c.muted)),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    // 没有星级时 getStarsColor 回落到白色，白底上看不见
                    color: noStars ? c.track : starsColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(stars,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: noStars ? c.ink : const Color(0xFF1F1A10))),
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

  Widget _bar(ExportPalette c, double value, Color color, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SmoothLinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        backgroundColor: c.track,
        valueColor: AlwaysStoppedAnimation<Color>(color),
        minHeight: height,
        animate: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = ExportPalette.of(context);
    return ExportStatsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: c.ink)),
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
                        positive: true)),
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
          _bar(c, completionRate / 100, c.accent, 14),
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
                    Expanded(child: _bar(c, stat.rate, stat.color, 12)),
                    SizedBox(
                      width: 130,
                      child: Text('${stat.completed} / ${stat.total}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: c.ink)),
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

/// 把 12 列曲绘摊成一行行，交给 [ExportProgressiveColumn] 分批挂载。
List<Widget> exportCoverRows(int count, IndexedWidgetBuilder cellBuilder) {
  const columns = 12;
  const gap = 8.0;
  return [
    for (var start = 0; start < count; start += columns)
      Padding(
        padding: EdgeInsets.only(top: start == 0 ? 0 : gap),
        child: Row(
          children: [
            for (var i = start; i < start + columns; i++) ...[
              if (i > start) const SizedBox(width: gap),
              Expanded(
                child: i < count
                    ? AspectRatio(
                        aspectRatio: 1,
                        child: Builder(
                            builder: (context) => cellBuilder(context, i)),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
  ];
}

/// 分批挂载内容的 Column：每帧只加几行，上千首曲绘也不会一帧堵住主线程。
/// 全部挂载后回调 [onComplete]，导出服务等它再截图。
class ExportProgressiveColumn extends StatefulWidget {
  final List<Widget> children;
  final VoidCallback? onComplete;

  const ExportProgressiveColumn(
      {super.key, required this.children, this.onComplete});

  @override
  State<ExportProgressiveColumn> createState() =>
      _ExportProgressiveColumnState();
}

class _ExportProgressiveColumnState extends State<ExportProgressiveColumn> {
  static const int _itemsPerFrame = 2;
  int _visible = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_visible >= widget.children.length) {
        widget.onComplete?.call();
        return;
      }
      setState(() => _visible += _itemsPerFrame);
      _scheduleNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = _visible.clamp(0, widget.children.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widget.children.sublist(0, count),
    );
  }
}
