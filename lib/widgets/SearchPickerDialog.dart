import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import '../widgets/AppDialogs.dart';
import '../utils/AppDesignTokens.dart';

/// 「带搜索框的单项选择弹窗」——谱师 / 曲师这类动辄几百条、需要现场筛选的列表共用。
///
/// 选中返回该项的名字；取消（或点遮罩关闭）返回 null，调用方保持原选择。
///
/// ⚠️ 搜索框的 controller 由**弹窗自己的 [State]** 持有并释放，**不要**改回
/// 「调用方建 controller、`showDialog(...).whenComplete(dispose)`」的写法：
/// `showDialog` 返回的 future 是 **`Route.popped`** —— pop 那一刻就完成，而弹窗
/// 此时还在**退场动画**里（真机上键盘收起会让它重建，`TextField` 会再读一次
/// controller）。于是必现「A TextEditingController was used after being
/// disposed」；异常又发生在卸载途中，元素树被撕成半死状态，紧接着刷出
/// `'_dependents.isEmpty': is not true` 与
/// 「Tried to build dirty widget in the wrong build scope」——用户看到的就是**红屏**。
///
/// 交给 [State.dispose] 就**结构上**不可能提前：它只在弹窗元素真正卸载后才跑。
/// 回归测试：`test/dialog_close_dispose_test.dart`。
Future<String?> showSearchPickerDialog(
  BuildContext context, {
  required String title,
  required String hintText,
  required String emptyText,
  required List<MapEntry<String, int>> entries,
  required String countSuffix,
  String? selected,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _SearchPickerDialog(
      title: title,
      hintText: hintText,
      emptyText: emptyText,
      entries: entries,
      countSuffix: countSuffix,
      selected: selected,
    ),
  );
}

class _SearchPickerDialog extends StatefulWidget {
  const _SearchPickerDialog({
    required this.title,
    required this.hintText,
    required this.emptyText,
    required this.entries,
    required this.countSuffix,
    required this.selected,
  });

  final String title;
  final String hintText;
  final String emptyText;

  /// 已经按出现次数排好序的条目（名字 → 数量）。
  final List<MapEntry<String, int>> entries;

  /// 条目里数量的单位后缀，如「谱面」「首」。
  final String countSuffix;

  /// 当前选中项（用于高亮），可为 null。
  final String? selected;

  @override
  State<_SearchPickerDialog> createState() => _SearchPickerDialogState();
}

class _SearchPickerDialogState extends State<_SearchPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final _searchKeys = [
    for (final entry in widget.entries) entry.key.toLowerCase()
  ];
  late List<MapEntry<String, int>> _filtered = widget.entries;
  String _keyword = '';

  void _updateFilter(String text) {
    final keyword = text.trim().toLowerCase();
    if (keyword == _keyword) return;

    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _keyword = keyword;
      _filtered = keyword.isEmpty
          ? widget.entries
          : [
              for (var i = 0; i < _searchKeys.length; i++)
                if (_searchKeys[i].contains(keyword)) widget.entries[i],
            ];
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAlertDialog(
      title: Text(widget.title),
      content: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  suffixIcon: _keyword.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _updateFilter('');
                          },
                        ),
                ),
                onChanged: _updateFilter,
              ),
            ),
          ),
          if (_filtered.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    widget.emptyText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final entry = _filtered[index];
                return ListTile(
                  title: Text(
                    '${entry.key} (${entry.value}${widget.countSuffix})',
                  ),
                  selected: widget.selected == entry.key,
                  onTap: () => Navigator.of(context).pop(entry.key),
                );
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          child: Text(context.l10n.featureCancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
