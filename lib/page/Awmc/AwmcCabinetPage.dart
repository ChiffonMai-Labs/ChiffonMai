import 'package:flutter/material.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/AWMC/AwmcCabinetData.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import 'AwmcUi.dart';

enum _Mode { preview, items, regions }

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
        builder: (context) => AlertDialog(
          title: Text(info.title),
          content: SingleChildScrollView(
            child: Text(
                info.description.isEmpty ? l10n.flowNoData : info.description),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.flowConfirm)),
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
    return BackgroundPageScaffold(
      title: l10n.awmcCabinetTitle,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AnimatedChoiceBar<_Mode>(
            values: _Mode.values,
            value: _mode,
            label: _label,
            onChanged: _busy || _checking ? null : _setMode,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy || _checking ? null : _query,
            child: Text(
                '${l10n.flowEnterCabinetQRCode} · ${_mode == _Mode.preview ? 1 : 2} Token'),
          ),
          if (_busy) const SmoothLinearProgressIndicator(),
          if (_loaded && _error == null)
            ...switch (_mode) {
              _Mode.preview => _preview(),
              _Mode.items => _owned(),
              _Mode.regions => _regions(),
            },
          if (_error case final error?)
            Text(error,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
    );
  }

  List<Widget> _preview() {
    final row = AwmcCabinetData.preview(_data);
    if (row.name.isEmpty && row.rating.isEmpty && row.playCount.isEmpty) {
      return [Text(context.l10n.flowNoData)];
    }
    return [
      if (row.name.isNotEmpty)
        ListTile(title: Text(row.name), contentPadding: EdgeInsets.zero),
      if (row.rating.isNotEmpty) Text('Rating · ${row.rating}'),
      if (row.playCount.isNotEmpty)
        Text(context.l10n.flowPlayedP0Times(row.playCount)),
    ];
  }

  List<Widget> _regions() {
    final rows = AwmcCabinetData.regions(_data);
    if (rows.isEmpty) return [Text(context.l10n.flowNoData)];
    final maximum = rows.first.count ?? 0;
    return [
      for (final row in rows)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(row.name),
          trailing: Text(row.count?.toString() ?? '—'),
          subtitle: maximum > 0 && row.count != null
              ? SmoothLinearProgressIndicator(value: row.count! / maximum)
              : null,
        ),
    ];
  }

  List<Widget> _owned() {
    final l10n = context.l10n;
    final all = AwmcCabinetData.ownedItems(_data);
    if (all.isEmpty) return [Text(l10n.flowNoData)];
    final entries = all.skip(_page * _pageSize).take(_pageSize).toList();
    final pageCount = (all.length + _pageSize - 1) ~/ _pageSize;
    return [
      if (entries.any((item) => item.slug != null))
        TextButton(
          onPressed: _busy || _checking ? null : () => _checkItems(entries),
          child:
              Text(_checking ? l10n.flowLoading2 : l10n.awmcCheckCatalogPage),
        ),
      for (final item in entries)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(item.name.isEmpty ? '#${item.id}' : item.name),
          subtitle: Text([
            if (item.kind.isNotEmpty) item.kind,
            l10n.awmcOwnedItems,
            if (item.slug case final slug?)
              switch (_verified[slug]) {
                true => l10n.awmcCatalogExists,
                false => l10n.awmcCatalogMissing,
                null => _checkedPage ? l10n.awmcCatalogCheckUnknown : '',
              },
          ].where((value) => value.isNotEmpty).join(' · ')),
          onTap: _busy || _checking || item.slug == null
              ? null
              : () => _itemDetails(item.slug!),
        ),
      if (pageCount > 1)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: MaterialLocalizations.of(context).previousPageTooltip,
              onPressed: _page == 0 || _checking || _busy
                  ? null
                  : () => setState(() {
                        _page--;
                        _checkedPage = false;
                      }),
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${_page + 1} / $pageCount'),
            IconButton(
              tooltip: MaterialLocalizations.of(context).nextPageTooltip,
              onPressed: _page + 1 >= pageCount || _checking || _busy
                  ? null
                  : () => setState(() {
                        _page++;
                        _checkedPage = false;
                      }),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
    ];
  }
}
