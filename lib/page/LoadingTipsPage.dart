import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';
import '../service/LoadingTipsStore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppError.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppSwitch.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/SmoothLinearProgressIndicator.dart';
import '../widgets/AnimatedChoiceBar.dart';
import '../widgets/EmptyState.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/QuickSearchBar.dart';

class LoadingTipsPage extends StatefulWidget {
  const LoadingTipsPage({super.key});
  @override
  State<LoadingTipsPage> createState() => _LoadingTipsPageState();
}

class _LoadingTipsPageState extends State<LoadingTipsPage> {
  final _store = LoadingTipsStore.instance;
  final ListEntrance _entrance = ListEntrance();
  bool _busy = true;
  int _tab = 0;
  String _query = '';
  AppError? _loadError;

  @override
  void initState() {
    super.initState();
    _store.addListener(_changed);
    _load();
  }

  Future<void> _load() async {
    await _store.ensureLoaded();
    if (mounted) {
      setState(() {
        _loadError = _store.lastError;
        _busy = false;
      });
    }
  }

  @override
  void dispose() {
    _store.removeListener(_changed);
    super.dispose();
  }

  void _changed() => mounted ? setState(() {}) : null;

  Future<void> _addTip({required bool cloud}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _LoadingTipInputDialog(
        title: cloud ? context.l10n.flowSubmitALoadingQuote : context.l10n.flowAddALocalQuote,
      ),
    );
    final value = text?.trim() ?? '';
    if (value.isEmpty || !mounted) return;
    if (cloud) {
      final id = await _store.submitCloudTip(value);
      if (!mounted) return;
      if (id == null) {
        AppToast.showError(
          _store.lastError ??
              AppError(
                code: 'SRV-LOADING-TIPS-SUBMIT',
                userMessage: context.l10n.flowUploadFailedTryAgainLater,
                stage: '提交云端语录',
                source: 'chiffonmai',
              ),
          stage: '提交云端语录',
        );
      } else {
        AppToast.show(
          context.l10n.flowSubmittedForReviewP0ShownOnlyAfter((id).toString()),
          tone: AppToastTone.success,
        );
      }
    } else {
      await _store.addLocalTip(value);
      if (mounted) {
        AppToast.show(context.l10n.flowLocalQuoteAdded, tone: AppToastTone.success);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _loadError = null;
    });
    final ok = await _store.refresh();
    if (mounted) {
      setState(() {
        _busy = false;
        _loadError = ok ? null : _store.lastError;
      });
      if (!ok) {
        AppToast.showError(
          _store.lastError ??
              AppError(
                code: 'NET-LOADING-TIPS',
                userMessage: context.l10n.flowCouldNotFetchLoadingQuotesKeptThe,
                stage: '拉取加载语录',
                source: 'chiffonmai',
              ),
          stage: '拉取加载语录',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tips = _store.catalogue;
    final localTips = _store.localTips;
    final current = _tab == 0 ? localTips : tips;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? current
        : current.where((tip) => tip.text.toLowerCase().contains(q)).toList();
    final total = _store.totalCount;
    return BackgroundPageScaffold(
      title: context.l10n.featureLoadingQuotes,
      actions: [
        IconButton(
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.flowRefreshQuotes),
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
                              context.l10n.flowP0QuotesEnabled((total).toString()),
                              style: TextStyle(
                                  fontSize: 13, color: scheme.onSurfaceVariant),
                            ),
                            const Spacer(),
                            TextButton(
                                onPressed: () => _store.setAllEnabled(true),
                                child:  Text(context.l10n.flowSelectAll)),
                            TextButton(
                                onPressed: () => _store.setAllEnabled(false),
                                child:  Text(context.l10n.flowDeselectAll)),
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
                    SegmentedTabItem(context.l10n.flowLocalQuotesP0((localTips.length).toString())),
                    SegmentedTabItem(context.l10n.flowCloudQuotesP0((tips.length).toString())),
                  ],
                  selectedIndex: _tab,
                  onChanged: (index) {
                    if (index == _tab) return;
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _tab = index);
                  },
                ),
                const SizedBox(height: AppDesignTokens.cardGap),
                QuickSearchBar(
                  query: _query,
                  hintText: context.l10n.flowSearchLoadingQuotes,
                  padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
                  onChanged: (value) {
                    if (value == _query) return;
                    setState(() => _query = value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _busy && tips.isEmpty && localTips.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : FadeContent(
                    child: filtered.isEmpty
                        ? (q.isNotEmpty
                            ? EmptyState(
                                key: ValueKey('empty-search-$_tab'),
                                icon: Icons.search_off_rounded,
                                message:
                                    context.l10n.flowNoMatchingLoadingQuotes,
                              )
                            : EmptyState(
                                key: ValueKey('empty-$_tab'),
                                error: _tab == 1 ? _loadError : null,
                                onAction: _tab == 1 && _loadError != null
                                    ? _refresh
                                    : null,
                                actionLabel: _tab == 1 && _loadError != null
                                    ? context.l10n.flowRetry
                                    : null,
                              ))
                        : ListView.builder(
                            key: ValueKey(_tab),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              AppDesignTokens.gutter,
                              0,
                              AppDesignTokens.gutter,
                              MediaQuery.viewInsetsOf(context).bottom,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => _entrance.wrap(
                              _tab,
                              index,
                              _tipTile(filtered[index]),
                              enabled: q.isEmpty,
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
                  label:  Text(context.l10n.flowAddLocally),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _addTip(cloud: true),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label:  Text(context.l10n.flowUploadToCloud),
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
                style: AppTheme.font(
                  fontSize: 14,
                  height: 1.45,
                  color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
                child: Text(tip.text),
              ),
            ),
            if (tip.id.startsWith('local_'))
              IconButton(
                tooltip: context.l10n.flowDeleteLocalQuote,
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
            final error = value.trim().isEmpty ? context.l10n.flowQuoteCannotBeEmpty : null;
            if (error != _error) setState(() => _error = error);
          },
          decoration: InputDecoration(
            hintText: context.l10n.flowEnterALoadingQuote,
            errorText: _error,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:  Text(context.l10n.featureCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = _controller.text.trim();
              if (value.isEmpty) {
                setState(() => _error = context.l10n.flowQuoteCannotBeEmpty);
                return;
              }
              Navigator.of(context).pop(value);
            },
            child:  Text(context.l10n.save),
          ),
        ],
      );
}
