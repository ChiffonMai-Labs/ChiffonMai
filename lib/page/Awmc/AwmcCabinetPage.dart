import 'package:flutter/material.dart';

import '../../l10n/FeatureLocalizations.dart';
import '../../l10n/LocalizationsExtension.dart';
import '../../manager/LuoXue/CollectionsManager.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcCabinetData.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppError.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../Collection/CollectionInfoPage.dart';
import 'AwmcUi.dart';

enum _Mode { regions, items }

/// 机台足迹与道具只读查询页面（游玩地区与已拥有道具）。
class AwmcCabinetPage extends StatefulWidget {
  const AwmcCabinetPage({super.key});

  @override
  State<AwmcCabinetPage> createState() => _AwmcCabinetPageState();
}

class _AwmcCabinetPageState extends State<AwmcCabinetPage> {
  static const _pageSize = 24;
  static const _collectionTypeBySlugPrefix = <String, String>{
    'plate': 'plates',
    'title': 'trophies',
    'icon': 'icons',
    'frame': 'frames',
  };
  _Mode _mode = _Mode.regions;
  bool _busy = false;
  bool _checking = false;
  bool _checkedPage = false;

  // 游玩地区与已拥有道具分别维护内存缓存状态，切模式时保留各自结果。
  Object? _regionsData;
  int? _regionsUpdatedAtMs;
  bool _regionsLoaded = false;

  Object? _itemsData;
  int? _itemsUpdatedAtMs;
  bool _itemsLoaded = false;

  String? _error;
  int _page = 0;
  final _verified = <String, bool>{};

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  /// 进入页面时异步加载两份无过期时间的本地缓存，有缓存则自动展示。
  Future<void> _loadCachedData() async {
    final results = await Future.wait([
      AwmcCabinetData.loadCachedRegions(),
      AwmcCabinetData.loadCachedOwnedItems(),
    ]);
    if (!mounted) return;
    final cachedRegions = results[0];
    final cachedItems = results[1];
    var changed = false;
    if (!_regionsLoaded && cachedRegions != null) {
      _regionsData = cachedRegions.data;
      _regionsUpdatedAtMs = cachedRegions.updatedAtMs;
      _regionsLoaded = true;
      changed = true;
    }
    if (!_itemsLoaded && cachedItems != null) {
      _itemsData = cachedItems.data;
      _itemsUpdatedAtMs = cachedItems.updatedAtMs;
      _itemsLoaded = true;
      changed = true;
    }
    if (changed) {
      setState(() {});
    }
  }

  bool get _currentLoaded => switch (_mode) {
        _Mode.regions => _regionsLoaded,
        _Mode.items => _itemsLoaded,
      };

  Object? get _currentData => switch (_mode) {
        _Mode.regions => _regionsData,
        _Mode.items => _itemsData,
      };

  int? get _currentUpdatedAtMs => switch (_mode) {
        _Mode.regions => _regionsUpdatedAtMs,
        _Mode.items => _itemsUpdatedAtMs,
      };

  String _formatTimestamp(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  String? _lastFetchedSubtitle(BuildContext context) {
    final updatedAtMs = _currentUpdatedAtMs;
    if (updatedAtMs == null) return null;
    return context.l10n.awmcLastFetchedTime(_formatTimestamp(updatedAtMs));
  }

  String _label(_Mode mode) {
    final l10n = context.l10n;
    return switch (mode) {
      _Mode.items => l10n.awmcOwnedItems,
      _Mode.regions => l10n.awmcPlayRegions,
    };
  }

  void _setMode(_Mode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      // 切模式时保留各自缓存结果，仅清理错误提示与翻页核对临时态。
      _error = null;
      _page = 0;
      _checkedPage = false;
      _verified.clear();
    });
  }

  Future<void> _query() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final l10n = context.l10n;
      final mode = _mode;
      final qr = await AwmcUi.askQrcode(context,
          title: _label(mode),
          body: '${l10n.flowQrPrivateNotice}\n2 Token');
      if (!mounted || qr == null) return;
      // 新查询前仅清除上次错误提示，保留已有缓存数据，避免查询失败时界面变空。
      setState(() {
        _error = null;
      });
      final response = await switch (mode) {
        _Mode.items => AwmcApiService.userItemList(token: '', qrcode: qr),
        _Mode.regions => AwmcApiService.userRegion(token: '', qrcode: qr),
      };
      if (!mounted) return;
      if (response.ok) {
        final data = response.businessData;
        final savedAt = await switch (mode) {
          _Mode.items => AwmcCabinetData.saveCachedOwnedItems(data),
          _Mode.regions => AwmcCabinetData.saveCachedRegions(data),
        };
        if (!mounted) return;
        final updatedAtMs = savedAt ?? DateTime.now().millisecondsSinceEpoch;
        setState(() {
          _error = null;
          switch (mode) {
            case _Mode.regions:
              _regionsData = data;
              _regionsUpdatedAtMs = updatedAtMs;
              _regionsLoaded = true;
            case _Mode.items:
              _itemsData = data;
              _itemsUpdatedAtMs = updatedAtMs;
              _itemsLoaded = true;
              _page = 0;
              _checkedPage = false;
              _verified.clear();
          }
        });
      } else {
        // 查询失败不覆盖本地缓存与内存已有结果，仅提示错误信息。
        setState(() {
          _error = response.displayMessage;
        });
      }
    } on Exception {
      if (mounted) setState(() => _error = context.l10n.awmcChartUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkItems(List<AwmcOwnedItem> items) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _checkedPage = false;
    });
    try {
      final checks = await AwmcCabinetData.checkVisible(
        items.map((item) => item.slug).whereType<String>(),
        isActive: () => mounted && _mode == _Mode.items,
      );
      if (mounted) setState(() => _verified.addAll(checks));
    } on Exception {
      // 失败的项目保留待核对状态。
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
          _checkedPage = true;
        });
      }
    }
  }

  Future<void> _itemDetails(AwmcOwnedItem item) async {
    final l10n = context.l10n;
    final slug = item.slug;
    if (slug == null) return;
    setState(() => _busy = true);
    try {
      final prefix = slug.split('-').first;
      final collectionType = _collectionTypeBySlugPrefix[prefix];
      final numericId = int.tryParse(item.id);
      if (collectionType != null && numericId != null) {
        final catalog = await CollectionsManager().fetchCatalog(collectionType);
        final exists = catalog
                ?.entriesFor(collectionType)
                ?.any((c) => c.id == numericId) ==
            true;
        if (exists && mounted) {
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CollectionInfoPage(
                collectionId: numericId,
                collectionType: collectionType,
              ),
            ),
          );
          return;
        }
      }

      final info = await AwmcCabinetData.item(slug);
      if (!mounted) return;
      if (info == null) {
        AppToast.showError(
          AppError(
            code: 'DATA-AWMC-ITEM-EMPTY',
            userMessage: l10n.awmcChartUnavailable,
            stage: '读取 AWMC 道具详情',
            source: 'awmc',
          ),
          stage: '读取 AWMC 道具详情',
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AppAlertDialog(
          icon: appDialogIconTile(
            Icons.inventory_2_outlined,
            Theme.of(dialogContext).colorScheme.primary,
          ),
          title: Text(info.title),
          content: SingleChildScrollView(
            child: Text(
                info.description.isEmpty ? l10n.flowNoData : info.description),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.flowConfirm),
            ),
          ],
        ),
      );
    } on Exception catch (e, stack) {
      if (mounted) {
        AppToast.showError(
          e,
          stack: stack,
          title: l10n.awmcChartUnavailable,
          stage: '读取 AWMC 道具详情',
          source: 'awmc',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    const tokenCost = 2;
    final ownedAll = _currentLoaded && _mode == _Mode.items
        ? AwmcCabinetData.ownedItems(_currentData)
        : const <AwmcOwnedItem>[];
    final ownedPageCount = (ownedAll.length + _pageSize - 1) ~/ _pageSize;

    return BackgroundPageScaffold(
      title: context.featureText('机台足迹与道具'),
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
              children: [
                AnimatedChoiceBar<_Mode>(
                  values: _Mode.values,
                  value: _mode,
                  label: _label,
                  onChanged: _busy || _checking ? null : _setMode,
                ),
                const SizedBox(height: AppDesignTokens.cardGap),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionHeader(
                        title: _label(_mode),
                        padding: const EdgeInsets.only(bottom: 8),
                        trailing: AppBadge(
                          text: '$tokenCost Token',
                          background: AppSurfaces.inset(context),
                          foreground: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        l10n.flowQrPrivateNotice,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppDesignTokens.radiusMedium),
                            ),
                          ),
                          onPressed: _busy || _checking ? null : _query,
                          icon: const Icon(Icons.qr_code_scanner_rounded,
                              size: 18),
                          label: Text(
                              '${l10n.flowEnterCabinetQRCode} · $tokenCost Token'),
                        ),
                      ),
                      if (_busy) ...[
                        const SizedBox(height: 12),
                        const ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          child: SmoothLinearProgressIndicator(minHeight: 5),
                        ),
                      ],
                      if (_error case final error?) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                scheme.errorContainer.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusSmall),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 18, color: scheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error,
                                  style: TextStyle(
                                      fontSize: 13, color: scheme.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignTokens.cardGap),
                AnimatedSwitcher(
                  duration: AppDesignTokens.motion(
                      context, AppDesignTokens.mediumMotion),
                  child: KeyedSubtree(
                    key: ValueKey(
                        (_mode, _currentLoaded, _currentUpdatedAtMs, _page)),
                    child: !_currentLoaded
                        ? const SizedBox.shrink()
                        : switch (_mode) {
                            _Mode.items => _owned(context, ownedAll),
                            _Mode.regions => _regions(context),
                          },
                  ),
                ),
              ],
            ),
          ),
          if (_currentLoaded &&
              _mode == _Mode.items &&
              ownedPageCount > 1)
            PagerBar(
              page: _page + 1,
              totalPages: ownedPageCount,
              onPrevious: _page == 0 || _checking || _busy
                  ? null
                  : () => setState(() {
                        _page--;
                        _checkedPage = false;
                      }),
              onNext: _page + 1 >= ownedPageCount || _checking || _busy
                  ? null
                  : () => setState(() {
                        _page++;
                        _checkedPage = false;
                      }),
            ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = _lastFetchedSubtitle(context);
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 32, color: scheme.outline),
            const SizedBox(height: 8),
            Text(
              context.l10n.flowNoData,
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _regions(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final rows = AwmcCabinetData.regions(_regionsData);
    if (rows.isEmpty) return _emptyCard(context);
    final maximum = rows.first.count ?? 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: l10n.awmcPlayRegions,
            subtitle: _lastFetchedSubtitle(context),
            padding: const EdgeInsets.only(bottom: 12),
            trailing: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AppBadge(
                text: '${rows.length}',
                background: AppSurfaces.inset(context),
                foreground: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final (index, row) in rows.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        row.count?.toString() ?? '—',
                        style: AppTheme.number(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (maximum > 0 && row.count != null) ...[
                    const SizedBox(height: 6),
                    SmoothLinearProgressIndicator(
                      value: row.count! / maximum,
                      minHeight: 5,
                      backgroundColor: AppSurfaces.track(context),
                      color: scheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _owned(BuildContext context, List<AwmcOwnedItem> all) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    if (all.isEmpty) return _emptyCard(context);
    final entries = all.skip(_page * _pageSize).take(_pageSize).toList();
    final hasCheckable = entries.any((item) => item.slug != null);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: l10n.awmcOwnedItems,
            subtitle: _lastFetchedSubtitle(context),
            padding: const EdgeInsets.only(bottom: 12),
            trailing: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBadge(
                    text: '${all.length}',
                    background: AppSurfaces.inset(context),
                    foreground: scheme.onSurfaceVariant,
                  ),
                  if (hasCheckable) ...[
                    const SizedBox(width: 8),
                    IgnorePointer(
                      ignoring: _busy || _checking,
                      child: Opacity(
                        opacity: _busy || _checking ? 0.5 : 1,
                        child: LinkPill(
                          label: _checking
                              ? l10n.flowLoading2
                              : l10n.awmcCheckCatalogPage,
                          onTap: () => _checkItems(entries),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          for (final (index, item) in entries.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            _buildOwnedItemRow(context, item, brightness),
          ],
        ],
      ),
    );
  }

  Widget _buildOwnedItemRow(
      BuildContext context, AwmcOwnedItem item, Brightness brightness) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final slug = item.slug;
    final verified = slug == null ? null : _verified[slug];

    Widget? statusBadge;
    if (slug != null) {
      if (verified == true) {
        final color = AppColors.successGreen(brightness);
        statusBadge = AppBadge(
          text: l10n.awmcCatalogExists,
          background: color.withValues(alpha: 0.14),
          foreground: color,
          numeric: false,
          fontSize: 11,
        );
      } else if (verified == false) {
        final color = AppColors.warningOrange(brightness);
        statusBadge = AppBadge(
          text: l10n.awmcCatalogMissing,
          background: color.withValues(alpha: 0.14),
          foreground: color,
          numeric: false,
          fontSize: 11,
        );
      } else if (_checkedPage) {
        statusBadge = AppBadge(
          text: l10n.awmcCatalogCheckUnknown,
          background: AppSurfaces.card(context),
          foreground: scheme.onSurfaceVariant,
          numeric: false,
          fontSize: 11,
        );
      }
    }

    return Material(
      color: AppSurfaces.inset(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: InkWell(
        onTap: _busy || _checking || slug == null
            ? null
            : () => _itemDetails(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name.isEmpty ? '#${item.id}' : item.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (item.kind.isNotEmpty)
                          AppBadge(
                            text: item.kind,
                            background: AppSurfaces.card(context),
                            foreground: scheme.onSurfaceVariant,
                            numeric: false,
                            fontSize: 11,
                          ),
                        if (statusBadge != null) statusBadge,
                      ],
                    ),
                  ],
                ),
              ),
              if (slug != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: scheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
