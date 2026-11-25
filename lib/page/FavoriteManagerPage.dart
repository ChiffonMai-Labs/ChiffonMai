import 'package:flutter/material.dart';

import '../entity/FeatureModels.dart';
import '../l10n/FeatureLocalizations.dart';
import '../l10n/LocalizationsExtension.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/FavoriteFeaturesNotifier.dart';
import '../utils/FeatureRegistry.dart';
import '../utils/LoginStateNotifier.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/NoRipple.dart';
import '../widgets/QuickSearchBar.dart';
import 'HubComponents.dart';

/// 首页「常用」功能管理页：支持关键词搜索、按分类/已收藏筛选，以及一键勾选或取消全部功能的星标。
class FavoriteManagerPage extends StatefulWidget {
  const FavoriteManagerPage({super.key});

  @override
  State<FavoriteManagerPage> createState() => _FavoriteManagerPageState();
}

class _FavoriteManagerPageState extends State<FavoriteManagerPage> {
  String _query = '';
  String? _selectedCategory;
  bool _onlyFavorited = false;

  bool _matches(String value, String query) {
    final text = value.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final keyword = query.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    if (text.contains(keyword)) return true;

    var cursor = 0;
    for (final rune in keyword.runes) {
      final index = text.indexOf(String.fromCharCode(rune), cursor);
      if (index < 0) return false;
      cursor = index + 1;
    }
    return keyword.isNotEmpty;
  }

  bool _itemMatches(BuildContext context, ButtonItem item, String query) {
    if (query.isEmpty) return true;
    return _matches(item.title, query) ||
        _matches(item.subtitle, query) ||
        _matches(context.featureText(item.title), query) ||
        _matches(context.featureText(item.subtitle), query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom + 24;

    return BackgroundPageScaffold(
      title: l10n.favoriteManagerTitle,
      resizeToAvoidBottomInset: false,
      child: ValueListenableBuilder<FavoritesPayload>(
        valueListenable: FavoriteFeaturesNotifier.instance,
        builder: (context, payload, _) {
          final favoriteTitles = payload.titles;
          final categories =
              FeatureRegistry.allCategories(LoginStateNotifier.instance.value);
          final itemsByTitle = <String, ButtonItem>{
            for (final category in categories)
              for (final item in category.items) item.title: item,
          };
          final categoryKeys = [
            for (final category in categories) category.name,
          ];

          // 组装当前筛选下可见的分组与功能项。
          final visibleSections = <({
            String category,
            FeatureSection section,
            List<ButtonItem> items,
          })>[];

          final activeCategories = _selectedCategory == null
              ? categoryKeys
              : [_selectedCategory!];

          for (final category in activeCategories) {
            final sections =
                FeatureRegistry.sections[category] ?? const <FeatureSection>[];
            for (final section in sections) {
              final matched = <ButtonItem>[];
              for (final title in section.titles) {
                final item = itemsByTitle[title];
                if (item == null) continue;
                if (_onlyFavorited && !favoriteTitles.contains(item.title)) {
                  continue;
                }
                if (!_itemMatches(context, item, _query)) continue;
                matched.add(item);
              }
              if (matched.isNotEmpty) {
                visibleSections.add((
                  category: category,
                  section: section,
                  items: matched,
                ));
              }
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 顶部搜索与筛选区固定在列表上方，避免输入时输入框重建失焦（§22.13）。
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDesignTokens.gutter,
                  4,
                  AppDesignTokens.gutter,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QuickSearchBar(
                      padding: EdgeInsets.zero,
                      query: _query,
                      hintText: l10n.favoriteManagerSearchHint,
                      onChanged: (value) {
                        if (mounted) setState(() => _query = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: NoRipple(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  FilterPill(
                                    label: l10n.flowAll,
                                    selected: _selectedCategory == null,
                                    onTap: () => setState(
                                        () => _selectedCategory = null),
                                  ),
                                  const SizedBox(width: 6),
                                  FilterPill(
                                    label: l10n.favoriteManagerOnlyFavorited,
                                    selected: _onlyFavorited,
                                    onTap: () => setState(
                                        () => _onlyFavorited = !_onlyFavorited),
                                  ),
                                  for (final category in categoryKeys) ...[
                                    const SizedBox(width: 6),
                                    FilterPill(
                                      label: context.featureText(category),
                                      selected: _selectedCategory == category,
                                      onTap: () => setState(() =>
                                          _selectedCategory =
                                              _selectedCategory == category
                                                  ? null
                                                  : category),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        l10n.favoriteManagerSelectedCount(favoriteTitles.length),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: visibleSections.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            context.featureText('未找到匹配的功能'),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: AppDesignTokens.pagePadding
                            .copyWith(top: 4, bottom: bottomInset),
                        itemCount: visibleSections.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final entry = visibleSections[index];
                          final sectionTitle = _selectedCategory == null
                              ? '${context.featureText(entry.category)} · ${context.featureText(entry.section.title)}'
                              : entry.section.title;
                          return HubSection(
                            title: sectionTitle,
                            icon: entry.section.icon,
                            compact: true,
                            children: [
                              for (final item in entry.items)
                                HubActionTile(
                                  title: item.title,
                                  subtitle: item.subtitle,
                                  icon: item.icon,
                                  isFavorited:
                                      favoriteTitles.contains(item.title),
                                  onToggleFavorite: () =>
                                      FavoriteFeaturesNotifier.toggle(
                                          item.title),
                                  onTap: () => FavoriteFeaturesNotifier.toggle(
                                      item.title),
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
