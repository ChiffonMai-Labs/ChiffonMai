import 'package:flutter/material.dart';
import 'dart:async';
import '../../service/Collection/CollectionSearchService.dart';
import '../../entity/LuoXue/Collection.dart';
import '../../manager/LuoXue/CollectionsManager.dart';
import '../../utils/CollectionsImageUtil.dart';
import '../../utils/AppTheme.dart';
import 'CollectionInfoPage.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/ProgressUi.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../../widgets/TrophyTitleBadge.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppDialogs.dart';

class CollectionSearchPage extends StatefulWidget {
  const CollectionSearchPage({Key? key}) : super(key: key);

  @override
  _CollectionSearchPageState createState() => _CollectionSearchPageState();
}

class _CollectionSearchPageState extends State<CollectionSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final CollectionSearchService _searchService = CollectionSearchService();

  String _selectedType = 'trophies';
  List<Collection> _searchResults = [];
  List<Collection> _rawResults = []; // 未经过滤和排序的原始结果
  bool _isSearching = false;
  Timer? _debounceTimer;
  int _searchRequest = 0;

  // 筛选：仅显示需要歌曲要求的收藏品
  bool _filterSongRequired = false;
  // 排序：ID倒序（默认正序）
  bool _sortDescending = false;
  // 称号专用底色筛选，支持多选。
  final Set<String> _selectedColors = <String>{};
  static const List<String> _colorOptions = [
    'Normal',
    'Bronze',
    'Silver',
    'Gold',
    'Rainbow',
  ];

  // 收藏品类型选项
  static const List<Map<String, String>> _typeOptions = [
    {'value': 'trophies', 'label': '称号'},
    {'value': 'icons', 'label': '头像'},
    {'value': 'plates', 'label': '姓名框'},
    {'value': 'frames', 'label': '背景'},
  ];

  /// 只给首屏的列表项加入场动画，滚动时不反复播放。
  static const int _entranceItems = 10;

  static const LinearGradient _rainbow = LinearGradient(
    colors: [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ],
  );

  @override
  void initState() {
    super.initState();
    // 页面初始化时执行一次搜索，显示全部收藏品
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 执行搜索
  Future<void> _performSearch() async {
    if (!mounted) return;
    final request = ++_searchRequest;
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _searchService.searchCollections(
        _searchController.text,
        _selectedType,
      );
      if (!mounted || request != _searchRequest) return;
      setState(() {
        _rawResults = results;
        _applyFilterAndSort();
      });
    } catch (e) {
      if (!mounted || request != _searchRequest) return;
      debugPrint('搜索出错: $e');
      setState(() {
        _rawResults = [];
        _searchResults = [];
      });
    } finally {
      if (mounted && request == _searchRequest) {
        setState(() => _isSearching = false);
      }
    }
  }

  /// 应用筛选和排序，更新 _searchResults
  void _applyFilterAndSort() {
    List<Collection> results = List.from(_rawResults);

    // 筛选：仅显示需要歌曲要求的收藏品
    if (_filterSongRequired) {
      results = results.where(_requiresSongs).toList();
    }

    if (_selectedType == 'trophies' &&
        _selectedColors.isNotEmpty &&
        _selectedColors.length < _colorOptions.length) {
      results = results
          .where((collection) =>
              collection.color != null &&
              _selectedColors.contains(collection.color))
          .toList();
    }

    // 排序：按ID
    results.sort((a, b) =>
        _sortDescending ? b.id.compareTo(a.id) : a.id.compareTo(b.id));

    _searchResults = results;
  }

  static bool _requiresSongs(Collection collection) =>
      collection.required?.any((req) => req.songs?.isNotEmpty ?? false) ??
      false;

  /// 切换筛选是否需要歌曲要求
  void _toggleSongRequiredFilter() {
    setState(() {
      _filterSongRequired = !_filterSongRequired;
      _applyFilterAndSort();
    });
  }

  /// 切换ID排序方向
  void _toggleSortOrder() {
    setState(() {
      _sortDescending = !_sortDescending;
      _applyFilterAndSort();
    });
  }

  // 防抖搜索：输入时旧结果留在屏幕上，顶部显示细进度条
  void _debouncedSearch() {
    _debounceTimer?.cancel();
    setState(() {});
    _debounceTimer = Timer(const Duration(milliseconds: 300), _performSearch);
  }

  // 切换收藏品类型
  void _switchType(String type) {
    if (_selectedType == type) return;
    _debounceTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedType = type;
      // 换类型时旧结果没有意义，显示骨架屏。
      _rawResults = [];
      _searchResults = [];
      if (type != 'trophies') {
        _selectedColors.clear();
      }
    });
    _performSearch();
  }

  void _openCollection(Collection collection) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionInfoPage(
          collectionId: collection.id,
          collectionType: _selectedType,
        ),
      ),
    );
  }

  Widget _buildAnimatedColorLabel(
    BuildContext context,
    String color, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final fillColor =
        color == 'ALL' ? colorScheme.primary : _getColorFromType(color);
    final textColor = selected
        ? color == 'ALL'
            ? colorScheme.onPrimary
            : _getTextColorForBackground(color)
        : colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 38),
        decoration: BoxDecoration(
          color: AppSurfaces.inset(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
          border: Border.all(
            color: selected ? fillColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: selected ? 1 : 0),
                duration: AppDesignTokens.motion(
                    context, const Duration(milliseconds: 420)),
                curve: Curves.easeInOutCubic,
                builder: (context, progress, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color == 'Rainbow' ? null : fillColor,
                          gradient: color == 'Rainbow' ? _rainbow : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: AppTheme.font(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(color),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_rounded, size: 16, color: textColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showColorFilterDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final draft = Set<String>.from(_selectedColors);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AppAlertDialog(
              icon: const Icon(Icons.palette_outlined),
              title: const Text('筛选称号底色'),
              subtitle: '可同时选择多个底色',
              content: SingleChildScrollView(
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: [
                    for (final color in ['ALL', ..._colorOptions])
                      _buildAnimatedColorLabel(
                        context,
                        color,
                        selected: color == 'ALL'
                            ? draft.isEmpty ||
                                draft.length == _colorOptions.length
                            : draft.contains(color),
                        onTap: () {
                          setDialogState(() {
                            if (color == 'ALL') {
                              draft
                                ..clear()
                                ..addAll(_colorOptions);
                            } else if (!draft.add(color)) {
                              draft.remove(color);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => setDialogState(draft.clear),
                  child: const Text('清除选择'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, Set<String>.from(draft)),
                  child: const Text('应用'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _selectedColors
        ..clear()
        ..addAll(result);
      _applyFilterAndSort();
    });
  }

  // 清除缓存
  Future<void> _clearCache() async {
    try {
      await CollectionsManager().clearAllCache();
      AppToast.show('缓存已清除，重新加载数据中...');
      // 重新执行搜索
      await _performSearch();
    } catch (e) {
      debugPrint('清除缓存时出错: $e');
      AppToast.show('清除缓存失败');
    }
  }

  // 根据颜色类型获取背景色
  Color _getColorFromType(String colorType) {
    switch (colorType) {
      case 'Bronze':
        return const Color(0xFFCD7F32); // 棕色
      case 'Silver':
        return const Color(0xFFC0C0C0); // 银色
      case 'Gold':
        return const Color(0xFFFFD700); // 金色
      case 'Rainbow':
        return const Color(0xFF9400D3); // 炫彩（紫色作为代表）
      default:
        return Colors.white; // 其他情况使用白色
    }
  }

  // 根据背景色获取文本颜色
  Color _getTextColorForBackground(String colorType) {
    switch (colorType) {
      case 'Bronze':
      case 'Silver':
      case 'Gold':
      case 'Rainbow':
        return Colors.white; // 深色背景使用白色文本
      default:
        return Colors.grey; // 浅色背景使用灰色文本
    }
  }

  Widget _buildSearchField() {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: '搜索收藏品名称、描述或 ID',
        isDense: true,
        filled: true,
        fillColor: AppSurfaces.card(context),
        prefixIcon: Icon(Icons.search_rounded,
            size: 22, color: scheme.onSurfaceVariant),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: '清空',
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  _debounceTimer?.cancel();
                  _performSearch();
                },
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder:
            border.copyWith(borderSide: BorderSide(color: scheme.primary)),
      ),
      onChanged: (_) => _debouncedSearch(),
      onSubmitted: (_) {
        _debounceTimer?.cancel();
        _performSearch();
      },
    );
  }

  Widget _buildFilters() {
    final scheme = Theme.of(context).colorScheme;
    final colorCount = _selectedColors.length == _colorOptions.length
        ? 0
        : _selectedColors.length;
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                FilterPill(
                  label: '有歌曲要求',
                  selected: _filterSongRequired,
                  onTap: _toggleSongRequiredFilter,
                ),
                if (_selectedType == 'trophies') ...[
                  const SizedBox(width: 6),
                  FilterPill(
                    label: '底色',
                    value: colorCount > 0 ? '$colorCount 种' : null,
                    onTap: _showColorFilterDialog,
                  ),
                ],
                const SizedBox(width: 6),
                FilterPill(
                  label: _sortDescending ? 'ID 倒序' : 'ID 正序',
                  selected: _sortDescending,
                  onTap: _toggleSortOrder,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${_searchResults.length} 个',
          style: AppTheme.number(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _withEntrance(int index, Widget child) => index >= _entranceItems
      ? child
      : EntranceAnimation(
          index: index,
          offset: const Offset(0, 8),
          duration: const Duration(milliseconds: 300),
          child: child,
        );

  /// 收藏品卡片里都有的文字：名称、ID、底色、描述和条件提示。
  Widget _buildInfo(Collection collection, {bool showName = true}) {
    final scheme = Theme.of(context).colorScheme;
    final color = collection.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showName)
          Text(
            collection.name,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '#${collection.id}',
              style: AppTheme.number(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_selectedType == 'trophies' && color != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: color == 'Rainbow' ? null : _getColorFromType(color),
                  gradient: color == 'Rainbow' ? _rainbow : null,
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusPill),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  color,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _getTextColorForBackground(color),
                  ),
                ),
              ),
            if (_requiresSongs(collection))
              Text(
                '有歌曲要求',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              )
            else if (collection.required?.isNotEmpty ?? false)
              Text(
                '有达成条件',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
          ],
        ),
        if (collection.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(
            collection.description!,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildListCard(Collection collection, int index) {
    final Widget content;
    switch (_selectedType) {
      case 'icons':
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: SizedBox(
                width: 60,
                height: 60,
                child: CollectionsImageUtil.getIconImageURL(collection),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(collection)),
          ],
        );
      case 'plates':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              // 姓名框原图约 720×116
              child: AspectRatio(
                aspectRatio: 720 / 116,
                child: CollectionsImageUtil.getPlateImageURL(collection),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfo(collection),
          ],
        );
      case 'frames':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              // 背景原图约 1080×452，完整显示不裁切
              child: AspectRatio(
                aspectRatio: 1080 / 452,
                child: ColoredBox(
                  color: AppSurfaces.inset(context),
                  child: CollectionsImageUtil.getFrameImageURL(collection),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfo(collection),
          ],
        );
      default:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TrophyTitleBadge(
              name: collection.name,
              color: collection.color,
              trophyId: collection.id,
              staticTextOffsetY: 1,
            ),
            const SizedBox(height: 4),
            _buildInfo(collection, showName: false),
          ],
        );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _withEntrance(
        index,
        AppCard(
          radius: AppDesignTokens.radiusMedium,
          padding: const EdgeInsets.all(12),
          onTap: () => _openCollection(collection),
          child: content,
        ),
      ),
    );
  }

  Widget _buildResults() {
    final scheme = Theme.of(context).colorScheme;
    final bottom = AppDesignTokens.gutter + MediaQuery.paddingOf(context).bottom;
    const horizontal = AppDesignTokens.gutter;
    if (_searchResults.isEmpty) {
      if (_isSearching) {
        return const SingleChildScrollView(
          key: ValueKey('loading'),
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: ProgressListSkeleton(),
        );
      }
      return Center(
        key: const ValueKey('empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 40, color: scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              '未找到匹配的收藏品',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    final results = _searchResults;
    final key = ValueKey('$_selectedType-results');
    return ListView.builder(
      key: key,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, bottom),
      itemCount: results.length,
      itemBuilder: (context, index) => _buildListCard(results[index], index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: '收藏品查询',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _clearCache,
          tooltip: '清除缓存并重新加载',
        ),
      ],
      resizeToAvoidBottomInset: false, // 防止键盘弹出时调整布局
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchField(),
                const SizedBox(height: 10),
                SegmentedTabs(
                  height: 40,
                  items: [
                    for (final option in _typeOptions)
                      SegmentedTabItem(option['label']!),
                  ],
                  selectedIndex: _typeOptions
                      .indexWhere((o) => o['value'] == _selectedType),
                  onChanged: (index) =>
                      _switchType(_typeOptions[index]['value']!),
                ),
                const SizedBox(height: 8),
                _buildFilters(),
              ],
            ),
          ),
          // 刷新已有结果时不清屏，只亮一条细进度条。
          SizedBox(
            height: 2,
            child: _isSearching && _searchResults.isNotEmpty
                ? SmoothLinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(scheme.primary),
                  )
                : null,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppDesignTokens.motion(
                  context, const Duration(milliseconds: 220)),
              child: _buildResults(),
            ),
          ),
        ],
      ),
    );
  }
}
