import 'AnimatedChoiceBar.dart';
import 'package:flutter/material.dart';

import '../service/SyncStatsService.dart';

/// 同步统计的展示组件。
///
/// 显示位置（线路1 AWMC / 线路2 maimai Score Hub 都有）：
///   * 水鱼、落雪入口的线路切换器下方分别显示普通、快速两行统计；
///   * AWMC NET 入口及对话框同样显示两行，没有线路切换器；
///   * 详情弹窗列出普通同步各线路和快速同步三个目标的独立统计；
///   * 「系统 → AWMC 网关 → 连通性与用量」里也有一行入口。
class SyncStatsView {
  SyncStatsView._();

  /// 一行统计摘要（未加载 / 无数据 / Redis 不可用都有对应文案）。
  ///
  /// 注意**必须够短**：这一行放在 tile footer 里，左边有图标、右边有箭头，
  /// 窄屏（360dp）可用宽度只有 300dp 左右。早先用「·」分隔 + 全角文字会顶出边界，
  /// 所以这里统一用 `/` 分隔并把「近 100 次」压成「近100次」。
  ///
  /// [tooltip] 是长按/悬停才显示的补充信息（例如「12 秒前更新」）——
  /// 统计是定时刷新的，用户需要一个不占地方的办法确认"这数字是刚拉的"。
  static Widget summaryLine(
    BuildContext context, {
    required SyncStats? stats,
    required VoidCallback onTap,
    bool loading = false,
    String? tooltip,
    String? label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final prefix = label == null ? '' : '$label ';
    final String text;
    if (loading) {
      text = '${prefix}统计加载中…';
    } else if (stats == null) {
      text = '${prefix}统计不可用';
    } else if (!stats.hasData) {
      text = '${prefix}近100次 / 暂无记录';
    } else {
      text = '${prefix}近100次 / ${stats.count}样本 / 平均${stats.avgText} / '
          '成功${stats.successRateText}';
    }

    final line = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          children: [
            Icon(Icons.insights_outlined,
                size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: FadeContent(
                  child: !loading && stats != null && stats.hasData
                      ? TweenAnimationBuilder<double>(
                          key: const ValueKey('sync-stats-values'),
                          tween: Tween<double>(end: stats.count.toDouble()),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          builder: (_, count, __) =>
                              TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: stats.avgMs),
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            builder: (_, avgMs, __) =>
                                TweenAnimationBuilder<double>(
                              tween:
                                  Tween<double>(end: stats.successRate * 100),
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 450),
                              curve: Curves.easeOutCubic,
                              builder: (_, rate, __) => Text(
                                '${prefix}近100次 / ${count.round()}样本 / 平均${SyncStats.formatDuration(avgMs.round())} / 成功${rate.round()}%',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ),
                        )
                      : Text(
                          text,
                          key: ValueKey(text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: TextStyle(
                              fontSize: 11.5, color: scheme.onSurfaceVariant),
                        )),
            ),
            Icon(Icons.chevron_right, size: 14, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
    if (tooltip == null || tooltip.isEmpty) return line;
    return Tooltip(message: tooltip, child: line);
  }

  /// 详情弹窗：所有槽位的耗时与成功率（按线路分组）。
  static Future<void> showDetail(BuildContext context) async {
    final stats = await SyncStatsService.loadMany(SyncStatsService.allSlots);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('同步统计'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '记录最近 ${SyncStatsService.windowSize} 次同步的耗时与成败'
                  '（所有使用者共享，仅含耗时/成败，不含二维码与账号信息）。',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                // 按 SyncLine 分组、组内平台取自 allSlots 而不是叉乘：
                // 二维码直传没有线路，叉乘会多出一堆永远「暂无记录」的行。
                for (final line in SyncLine.values)
                  if (_hasSlotFor(line)) ...[
                    Text(
                      line == SyncLine.quick
                          ? line.label
                          : '普通同步 · ${line.label}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    for (final (slotLine, platform)
                        in SyncStatsService.allSlots)
                      if (slotLine == line)
                        _row(
                          ctx,
                          platform.label,
                          stats[SyncStatsService.slotOf(line, platform)],
                        ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  static bool _hasSlotFor(SyncLine line) =>
      SyncStatsService.allSlots.any((slot) => slot.$1 == line);

  static Widget _row(BuildContext context, String name, SyncStats? stats) {
    final scheme = Theme.of(context).colorScheme;
    final s = stats ?? SyncStats.empty;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            if (!s.hasData)
              Text(
                stats == null ? '统计不可用' : '暂无记录',
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onSurfaceVariant,
                ),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _metricTile(context, '平均时长', s.avgText),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricTile(context, '成功率', s.successRateText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _recentMetricTile(context, s),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metricTile(
                        context, '成功样本', '${s.successCount}/${s.count}'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _metricTile(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return _metricTileFrame(
      context,
      label,
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  static Widget _recentMetricTile(BuildContext context, SyncStats stats) {
    final scheme = Theme.of(context).colorScheme;
    return _metricTileFrame(
      context,
      '最近一次',
      Row(
        children: [
          Flexible(
            child: Text(
              SyncStats.formatDuration(stats.lastMs),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          if (!stats.lastOk) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '失败',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _metricTileFrame(
      BuildContext context, String label, Widget value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: value,
          ),
        ],
      ),
    );
  }
}
