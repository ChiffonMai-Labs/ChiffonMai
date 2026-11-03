import 'package:flutter/material.dart';
import '../service/LoadingTipsStore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppSwitch.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import '../widgets/AnimatedChoiceBar.dart';
import '../widgets/EmptyState.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

class LoadingTipsPage extends StatefulWidget {
  const LoadingTipsPage({super.key});
  @override
  State<LoadingTipsPage> createState() => _LoadingTipsPageState();
}

class _LoadingTipsPageState extends State<LoadingTipsPage> {
  final _store = LoadingTipsStore.instance;
  bool _busy = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_changed);
    _load();
  }

  Future<void> _load() async {
    await _store.ensureLoaded();
    if (mounted) setState(() => _busy = false);
  }

  @override
  void dispose() {
    _store.removeListener(_changed);
    super.dispose();
  }

  void _changed() => mounted ? setState(() {}) : null;

  Future<void> _addTip({required bool cloud}) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _LoadingTipInputDialog(
        title: cloud ? '上传语录到云端' : '本地新增语录',
      ),
    );
    final value = text?.trim() ?? '';
    if (value.isEmpty || !mounted) return;
    if (cloud) {
      final id = await _store.submitCloudTip(value);
      if (mounted)
        AppToast.show(id == null ? '上传失败，请稍后重试' : '已提交审核（$id），审核通过后才会展示');
    } else {
      await _store.addLocalTip(value);
      if (mounted) {
        AppToast.show('本地语录添加成功');
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    final ok = await _store.refresh();
    if (mounted) {
      setState(() => _busy = false);
      if (!ok) {
        AppToast.show('获取加载语录失败，已保留本地缓存');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tips = _store.catalogue;
    final localTips = _store.localTips;
    final current = _tab == 0 ? localTips : tips;
    final total = _store.totalCount;
    return BackgroundPageScaffold(
      title: '加载语录管理',
      actions: [
        IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新语录'),
      ],
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (total > 0) ...[
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            RollingNumber(
                              value: _store.enabledCount,
                              style: AppTheme.number(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ $total 条已启用',
                              style: TextStyle(
                                  fontSize: 13, color: scheme.onSurfaceVariant),
                            ),
                            const Spacer(),
                            TextButton(
                                onPressed: () => _store.setAllEnabled(true),
                                child: const Text('全选')),
                            TextButton(
                                onPressed: () => _store.setAllEnabled(false),
                                child: const Text('全不选')),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SmoothLinearProgressIndicator(
                            value: _store.enabledCount / total,
                            minHeight: 6,
                            color: scheme.primary,
                            backgroundColor: AppSurfaces.inset(context),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.cardGap),
                ],
                SegmentedTabs(
                  items: [
                    SegmentedTabItem('本地语录 ${localTips.length}'),
                    SegmentedTabItem('云端语录 ${tips.length}'),
                  ],
                  selectedIndex: _tab,
                  onChanged: (index) => setState(() => _tab = index),
                ),
                const SizedBox(height: AppDesignTokens.cardGap),
              ],
            ),
          ),
          Expanded(
            child: _busy && tips.isEmpty && localTips.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : FadeContent(
                    child: current.isEmpty
                        ? EmptyState(key: ValueKey('empty-$_tab'))
                        : ListView.builder(
                            key: ValueKey(_tab),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppDesignTokens.gutter),
                            itemCount: current.length,
                            itemBuilder: (context, index) => EntranceAnimation(
                              index: index,
                              offset: const Offset(0, 8),
                              duration: const Duration(milliseconds: 300),
                              child: _tipTile(current[index]),
                            ),
                          ),
                  ),
          ),
          BottomActionBar(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addTip(cloud: false),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('本地新增'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addTip(cloud: true),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('上传到云端'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tipTile(LoadingTip tip) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = !_store.disabledIds.contains(tip.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        radius: AppDesignTokens.radiusMedium,
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: AppDesignTokens.motion(
                    context, const Duration(milliseconds: 180)),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                child: Text(tip.text),
              ),
            ),
            if (tip.id.startsWith('local_'))
              IconButton(
                tooltip: '删除本地语录',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.delete_outline,
                    size: 20, color: scheme.onSurfaceVariant),
                onPressed: () => _store.removeLocalTip(tip.id),
              ),
            const SizedBox(width: 4),
            Semantics(
              label: tip.text,
              child: AppSwitch(
                value: enabled,
                onChanged: (value) => _store.setEnabled(tip.id, value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 输入框控制器必须归属于对话框自身的 State。
///
/// 对话框取消时，路由仍可能在执行退出动画；在 showDialog 返回后立刻释放
/// 外部 controller 会让 TextField 仍持有它的依赖，触发 `_dependents.isEmpty`。
class _LoadingTipInputDialog extends StatefulWidget {
  final String title;

  const _LoadingTipInputDialog({required this.title});

  @override
  State<_LoadingTipInputDialog> createState() => _LoadingTipInputDialogState();
}

class _LoadingTipInputDialogState extends State<_LoadingTipInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppAlertDialog(
        title: Text(widget.title),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: 3,
          onChanged: (value) {
            final error = value.trim().isEmpty ? '语录内容不能为空' : null;
            if (error != _error) setState(() => _error = error);
          },
          decoration: InputDecoration(
            hintText: '输入加载语录',
            errorText: _error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final value = _controller.text.trim();
              if (value.isEmpty) {
                setState(() => _error = '语录内容不能为空');
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text('保存'),
          ),
        ],
      );
}
