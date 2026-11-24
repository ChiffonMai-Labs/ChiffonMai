import 'package:flutter/material.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcCabinetData.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import 'AwmcUi.dart';

enum _Mode { preview, items, regions }

/// AWMC 机台只读查询页面（账号预览、已拥有道具与游玩地区）。
class AwmcCabinetPage extends StatefulWidget {
  const AwmcCabinetPage({super.key});

  @override
  State<AwmcCabinetPage> createState() => _AwmcCabinetPageState();
}

class _AwmcCabinetPageState extends State<AwmcCabinetPage> {
  static const _pageSize = 24;
  _Mode _mode = _Mode.preview;
  bool _busy = false;
  bool _loaded = false;
  bool _checking = false;
  bool _checkedPage = false;
  Object? _data;
  String? _error;
  int _page = 0;
  final _verified = <String, bool>{};

  String _label(_Mode mode) {
    final l10n = context.l10n;
    return switch (mode) {
      _Mode.preview => l10n.awmcCabinetPreview,
      _Mode.items => l10n.awmcOwnedItems,
      _Mode.regions => l10n.awmcPlayRegions,
    };
  }

  void _setMode(_Mode mode) {
    setState(() {
      _mode = mode;
      _loaded = false;
      _data = null;
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
          body:
              '${l10n.flowQrPrivateNotice}\n${mode == _Mode.preview ? 1 : 2} Token');
      if (!mounted || qr == null) return;
      setState(() {
        _loaded = false;
        _data = null;
        _error = null;
        _page = 0;
        _checkedPage = false;
        _verified.clear();
      });
      final response = await switch (mode) {
        _Mode.preview => AwmcApiService.userPreview(token: '', qrcode: qr),
        _Mode.items => AwmcApiService.userItemList(token: '', qrcode: qr),
        _Mode.regions => AwmcApiService.userRegion(token: '', qrcode: qr),
      };
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _data = response.ok ? response.businessData : null;
        _error = response.ok ? null : response.displayMessage;
      });
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

  Future<void> _itemDetails(String slug) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final info = await AwmcCabinetData.item(slug);
      if (!mounted) return;
      if (info == null) {
        AppToast.show(l10n.awmcChartUnavailable, tone: AppToastTone.error);
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
    } on Exception {
      if (mounted) {
        AppToast.show(l10n.awmcChartUnavailable, tone: AppToastTone.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tokenCost = _mode == _Mode.preview ? 1 : 2;
    final ownedAll = _loaded && _error == null && _mode == _Mode.items
        ? AwmcCabinetData.ownedItems(_data)
        : const <AwmcOwnedItem>[];
    final ownedPageCount = (ownedAll.length + _pageSize - 1) ~/ _pageSize;

    return BackgroundPageScaffold(
      title: l10n.awmcCabinetTitle,
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
                    key: ValueKey((_mode, _loaded, _error, _page)),
                    child: !_loaded || _error != null
                        ? const SizedBox.shrink()
                        : switch (_mode) {
                            _Mode.preview => _preview(context),
                            _Mode.items => _owned(context, ownedAll),
                            _Mode.regions => _regions(context),
                          },
                  ),
                ),
              ],
            ),
          ),
          if (_loaded &&
              _error == null &&
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
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final row = AwmcCabinetData.preview(_data);
    if (row.name.isEmpty && row.rating.isEmpty && row.playCount.isEmpty) {
      return _emptyCard(context);
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (row.name.isNotEmpty)
            AppSectionHeader(
              title: row.name,
              padding: const EdgeInsets.only(bottom: 12),
              trailing: AppBadge(
                text: l10n.awmcCabinetPreview,
                background: AppSurfaces.inset(context),
                foreground: scheme.onSurfaceVariant,
                numeric: false,
              ),
            ),
          if (row.rating.isNotEmpty || row.playCount.isNotEmpty)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (row.rating.isNotEmpty)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppSurfaces.inset(context),
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                        ),
                        child: StatTile(label: 'Rating', value: row.rating),
                      ),
                    ),
                  if (row.rating.isNotEmpty && row.playCount.isNotEmpty)
                    const SizedBox(width: 10),
                  if (row.playCount.isNotEmpty)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppSurfaces.inset(context),
                          borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.confirmation_number_outlined,
                                size: 18, color: scheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  l10n.flowPlayedP0Times(row.playCount),
                                  style: AppTheme.number(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _regions(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final rows = AwmcCabinetData.regions(_data);
    if (rows.isEmpty) return _emptyCard(context);
    final maximum = rows.first.count ?? 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: l10n.awmcPlayRegions,
            padding: const EdgeInsets.only(bottom: 12),
            trailing: AppBadge(
              text: '${rows.length}',
              background: AppSurfaces.inset(context),
              foreground: scheme.onSurfaceVariant,
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
            padding: const EdgeInsets.only(bottom: 12),
            trailing: Row(
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
            : () => _itemDetails(slug),
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
