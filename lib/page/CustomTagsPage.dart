import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/CustomTagStore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartDifficulty.dart';
import '../utils/CoverUtil.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/CustomTagUi.dart';
import 'SongInfoPage.dart';

/// 自定义标签：名称、颜色、谱面都由用户决定。
///
/// 标签会合并进现有标签系统（见 [CustomTagStore]），在乐曲查询的标签筛选、
/// 谱面详情、Best50 / 收藏夹标签统计和个性化 Best50「标签50」里都能用。
class CustomTagsPage extends StatefulWidget {
  const CustomTagsPage({super.key});

  @override
  State<CustomTagsPage> createState() => _CustomTagsPageState();
}

class _CustomTagsPageState extends State<CustomTagsPage> {
  final _store = CustomTagStore.instance;

  @override
  void initState() {
    super.initState();
    _store.ensureLoaded();
  }

  Future<void> _create() async {
    final result = await showCustomTagEditor(context);
    if (result == null || !mounted) return;
    try {
      final tag = await _store.create(result.name, result.color);
      if (!mounted) return;
      _openDetail(tag.id);
    } catch (_) {
      AppToast.show(context.l10n.customTagSaveFailed,
          tone: AppToastTone.error);
    }
  }

  void _openDetail(int id) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _CustomTagDetailPage(tagId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: l10n.customTagTitle,
      actions: [
        IconButton(
          tooltip: l10n.customTagCreate,
          icon: const Icon(Icons.add_rounded),
          onPressed: _create,
        ),
      ],
      child: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (!_store.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final tags = _store.tags;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 0,
                AppDesignTokens.gutter, 32),
            itemCount: tags.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
                  child: Text(l10n.customTagIntro,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: scheme.onSurfaceVariant)),
                );
              }
              final tag = tags[i - 1];
              final row = Padding(
                padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
                child: AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: () => _openDetail(tag.id),
                  child: Row(children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: Color(tag.color), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CustomTagChip(name: tag.name, color: tag.color),
                      ),
                    ),
                    Text(l10n.customTagChartCount(tag.charts.length),
                        style: TextStyle(
                            fontSize: 12.5, color: scheme.onSurfaceVariant)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant),
                  ]),
                ),
              );
              // 只给首屏的列表项加入场动画。
              return i <= 8
                  ? EntranceAnimation(index: i, child: row)
                  : row;
            },
          );
        },
      ),
    );
  }
}

class _CustomTagDetailPage extends StatelessWidget {
  final int tagId;
  const _CustomTagDetailPage({required this.tagId});

  Future<void> _guard(BuildContext context, Future<void> Function() a) async {
    try {
      await a();
    } catch (_) {
      AppToast.show(context.l10n.customTagSaveFailed,
          tone: AppToastTone.error);
    }
  }

  Future<void> _edit(BuildContext context, CustomTag tag) async {
    final result = await showCustomTagEditor(context, initial: tag);
    if (result == null || !context.mounted) return;
    await _guard(
        context,
        () => CustomTagStore.instance
            .update(tag.copyWith(name: result.name, color: result.color)));
  }

  Future<void> _delete(BuildContext context, CustomTag tag) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: Text(l10n.customTagDeleteTitle),
        content: Text(l10n.customTagDeleteMessage(tag.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.featureCancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.customTagDelete)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.pop(context);
    await _guard(context, () => CustomTagStore.instance.delete(tag.id));
  }

  Future<void> _addCharts(BuildContext context, CustomTag tag) async {
    final charts = await pickCustomTagCharts(context);
    if (charts == null || !context.mounted) return;
    await _guard(
        context, () => CustomTagStore.instance.addCharts(tag.id, charts));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: CustomTagStore.instance,
      builder: (context, _) {
        final tag = CustomTagStore.instance.byId(tagId);
        if (tag == null) {
          return BackgroundPageScaffold(
              title: l10n.customTagTitle, child: const SizedBox.shrink());
        }
        return BackgroundPageScaffold(
          title: tag.name,
          actions: [
            IconButton(
              tooltip: l10n.customTagEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, tag),
            ),
            IconButton(
              tooltip: l10n.customTagDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _delete(context, tag),
            ),
          ],
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 0,
                AppDesignTokens.gutter, 32),
            itemCount: tag.charts.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
                  child: Row(children: [
                    CustomTagChip(name: tag.name, color: tag.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.customTagChartCount(tag.charts.length),
                          style: TextStyle(
                              fontSize: 12.5, color: scheme.onSurfaceVariant)),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _addCharts(context, tag),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.customTagAddCharts),
                    ),
                  ]),
                );
              }
              final chart = tag.charts[i - 1];
              final utage = chart.sheetType == 'utage';
              final brightness = Theme.of(context).brightness;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(10),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SongInfoPage(
                        songId: chart.songId,
                        initialLevelIndex: chart.levelIndex,
                      ),
                    ),
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
                      child: CoverUtil.buildCoverWidget(chart.songId, 44),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chart.title,
                              maxLines: 2,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: utage
                                    ? scheme.tertiary
                                    : AppColors.difficultyForegroundByIndex(
                                        chart.levelIndex,
                                        brightness: brightness),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${chart.sheetType.toUpperCase() == 'STD' ? 'ST' : chart.sheetType.toUpperCase()} · ${ChartDifficulty.labelOf(chart.levelIndex, isUtage: utage)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant),
                            ),
                          ]),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.customTagRemoveChart,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => _guard(
                          context,
                          () => CustomTagStore.instance
                              .removeChart(tag.id, chart)),
                    ),
                  ]),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
