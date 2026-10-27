import 'TrophyTitleBadge.dart';
import 'package:flutter/material.dart';
import '../entity/LuoXue/Collection.dart';
import '../utils/AppTheme.dart';
import 'LxnsAssetImage.dart';
import 'AnimatedChoiceBar.dart';
import 'SmoothLinearProgressIndicator.dart';

/// 社区装扮选择器：头像、姓名框、背景与称号，复用收藏品缓存并支持搜索。
/// 从 HomePage 中提取出来，方便在「我的」等其他页面复用。
class CollectionPickerSheet extends StatefulWidget {
  final TextEditingController? searchController;
  final bool isLoading;
  final List<Collection> avatarIcons;
  final List<Collection> avatarPlates;
  final List<Collection> frames, trophies;
  final int? selectedFrameId, selectedTrophyId;
  final ValueChanged<Collection?>? onFramePicked, onTrophyPicked;
  final VoidCallback? onClearPlate;
  final int? selectedAvatarId;
  final int? selectedPlateId;
  final ValueChanged<int> onAvatarPicked;
  final ValueChanged<int> onPlatePicked;

  const CollectionPickerSheet({
    super.key,
    this.searchController,
    this.isLoading = false,
    this.frames = const [],
    this.trophies = const [],
    this.selectedFrameId,
    this.selectedTrophyId,
    this.onFramePicked,
    this.onTrophyPicked,
    this.onClearPlate,
    required this.avatarIcons,
    required this.avatarPlates,
    required this.selectedAvatarId,
    required this.selectedPlateId,
    required this.onAvatarPicked,
    required this.onPlatePicked,
  });

  @override
  State<CollectionPickerSheet> createState() => _CollectionPickerSheetState();
}

class _CollectionPickerSheetState extends State<CollectionPickerSheet> {
  // 状态放到 State 字段里，跟 sheet 实例生命周期绑定
  int _activeTab = 0; // 头像、姓名框、背景、称号
  late final TextEditingController _searchController;
  @override
  void initState() {
    super.initState();
    _searchController = widget.searchController ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.searchController == null) _searchController.dispose();
    super.dispose();
  }

  /// 头像网格每行几列：默认 4 列，可用下方步进器在 3~10 之间调。
  ///
  /// 为什么有上下限：少于 3 列一屏看不了几个头像（默认 4 列已经比原来的 3 列密），
  /// 多于 10 列时单个头像比网格间隙还小，只剩一片糊在一起的小图。
  /// 姓名框 tab 不受它影响 —— 那是 6:1 的长条 banner，必须一行一个。
  static const int _kDefaultAvatarColumns = 4;
  static const int _kMinAvatarColumns = 3;
  static const int _kMaxAvatarColumns = 10;
  int _avatarColumns = _kDefaultAvatarColumns;

  void _setAvatarColumns(int value) {
    final next = value.clamp(_kMinAvatarColumns, _kMaxAvatarColumns);
    if (next == _avatarColumns) return;
    setState(() => _avatarColumns = next);
  }

  void _switchTab(int tab) {
    if (tab == _activeTab) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _activeTab = tab;
      _searchController.clear();
    });
  }

  /// 列数多时把网格间隙收窄：10 列时 8dp 间隙要吃掉 72dp（约两个半格子），
  /// 头像会缩得比间隙还小，看着像一堆孤立的点。
  double get _avatarGridGap => _avatarColumns >= 7 ? 4 : 8;

  /// 「每行 N 列」的 +/− 步进器（头像 tab 专用）。
  ///
  /// 用 IconButton 而不是自绘按钮：`onPressed: null` 时它**自己**会变灰且点不动，
  /// 触达区域、水波纹、tooltip 语义（无障碍）也都是现成的。
  Widget _buildColumnStepper(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '每行',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStepperButton(
                icon: Icons.remove,
                tooltip: '减少每行头像数',
                // 到下限就禁用（click 不会再进 _setAvatarColumns）
                onPressed: _avatarColumns > _kMinAvatarColumns
                    ? () => _setAvatarColumns(_avatarColumns - 1)
                    : null,
              ),
              // 数字框至少 26dp 宽：个位数变两位数时两边按钮不会跟着抖。
              // 用 minWidth 而不是死宽度 —— 系统字号放大到 2 倍时「10」需要更宽，
              // 死宽度会把字切掉。
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 26),
                child: Center(
                  child: Text(
                    '$_avatarColumns',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
              _buildStepperButton(
                icon: Icons.add,
                tooltip: '增加每行头像数',
                onPressed: _avatarColumns < _kMaxAvatarColumns
                    ? () => _setAvatarColumns(_avatarColumns + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 34, height: 32),
    );
  }

  static const _labels = ['头像', '姓名框', '背景', '称号'];
  void _pick(Collection? item) {
    FocusManager.instance.primaryFocus?.unfocus();
    switch (_activeTab) {
      case 0:
        if (item != null) widget.onAvatarPicked(item.id);
        break;
      case 1:
        if (item == null) {
          widget.onClearPlate?.call();
        } else {
          widget.onPlatePicked(item.id);
        }
        break;
      case 2:
        widget.onFramePicked?.call(item);
        break;
      case 3:
        widget.onTrophyPicked?.call(item);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final list = [
      widget.avatarIcons,
      widget.avatarPlates,
      widget.frames,
      widget.trophies
    ][_activeTab];
    final selected = [
      widget.selectedAvatarId,
      widget.selectedPlateId,
      widget.selectedFrameId,
      widget.selectedTrophyId
    ][_activeTab];
    final label = _labels[_activeTab],
        keyword = _searchController.text.trim().toLowerCase();
    final items = list
        .where((c) =>
            keyword.isEmpty ||
            c.name.toLowerCase().contains(keyword) ||
            (c.description?.toLowerCase().contains(keyword) ?? false) ||
            c.id.toString().contains(keyword))
        .toList();
    final selectedIndex = items.indexWhere((item) => item.id == selected);
    if (selectedIndex > 0) items.insert(0, items.removeAt(selectedIndex));
    Widget cell(Collection item) {
      final active = item.id == selected;
      return Semantics(
          button: true,
          selected: active,
          label: item.name,
          child: Tooltip(
              message: '${item.name} · #${item.id}',
              child: GestureDetector(
                  onTap: () => _pick(item),
                  child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: active
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                              width: active ? 3 : 1)),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LxnsAssetImage(
                              url: _activeTab == 0
                                  ? lxnsIconUrl(item.id)
                                  : _activeTab == 1
                                      ? lxnsPlateUrl(item.id)
                                      : lxnsFrameUrl(item.id),
                              fit: BoxFit.contain))))));
    }

    return Container(
        height: size.height * .72,
        decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16))),
        child: SafeArea(
            top: false,
            child: Column(children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(children: [
                    Expanded(
                        child: Text('选择装扮',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface))),
                    if (_activeTab == 0) _buildColumnStepper(context),
                    IconButton(
                        tooltip: '关闭',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ])),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedChoiceBar<int>(
                      values: const [0, 1, 2, 3],
                      value: _activeTab,
                      label: (i) => _labels[i],
                      onChanged: _switchTab)),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                          hintText: '搜索$label名称、描述或编号',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: '清空搜索',
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () =>
                                      setState(_searchController.clear)),
                          border: const OutlineInputBorder()))),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('共 ${items.length} 项',
                          style: TextStyle(
                              fontSize: 12, color: scheme.onSurfaceVariant)))),
              if (widget.isLoading) const SmoothLinearProgressIndicator(),
              const Divider(height: 1),
              Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                              keyword.isEmpty
                                  ? (widget.isLoading
                                      ? '正在加载$label…'
                                      : '暂无$label，请先刷新收藏品数据')
                                  : '未找到匹配的$label',
                              style: TextStyle(color: scheme.onSurfaceVariant)))
                      : _activeTab == 3
                          ? ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final item = items[i];
                                return ListTile(
                                    selected: item.id == selected,
                                    title: TrophyTitleBadge(
                                        name: item.name,
                                        color: item.color,
                                        trophyId: item.id),
                                    subtitle: Text('#${item.id}',
                                        style: const TextStyle(fontSize: 11)),
                                    trailing: SizedBox(
                                        width: 24,
                                        child: item.id == selected
                                            ? const Icon(Icons.check)
                                            : null),
                                    onTap: () => _pick(item));
                              })
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          _activeTab == 0 ? _avatarColumns : 1,
                                      crossAxisSpacing:
                                          _activeTab == 0 ? _avatarGridGap : 8,
                                      mainAxisSpacing:
                                          _activeTab == 0 ? _avatarGridGap : 8,
                                      childAspectRatio: _activeTab == 0
                                          ? 1
                                          : _activeTab == 1
                                              ? 6
                                              : 1080 / 452),
                              itemCount: items.length,
                              itemBuilder: (_, i) => cell(items[i]))),
            ])));
  }
}
