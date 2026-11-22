import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/SongSearchService.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import 'AwmcCabinetPage.dart';

enum _Resource { music, rival }

class AwmcResourcesPage extends StatefulWidget {
  const AwmcResourcesPage({super.key});

  @override
  State<AwmcResourcesPage> createState() => _AwmcResourcesPageState();
}

class _AwmcResourcesPageState extends State<AwmcResourcesPage> {
  final _query = TextEditingController();
  _Resource _mode = _Resource.music;
  bool _busy = false;
  bool _loaded = false;
  String? _error;
  String? _source;
  List<({String id, String title, String? detail})> _rows = const [];

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _clear() {
    _error = null;
    _source = null;
    _rows = const [];
    _loaded = false;
  }

  Future<void> _fetch() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final query = _query.text.trim();
    final rivalId = int.tryParse(query);
    final l10n = context.l10n;
    if (_mode == _Resource.rival &&
        (rivalId == null || rivalId <= 0 || rivalId > 0xffffffff)) {
      setState(() {
        _clear();
        _error = l10n.awmcRivalIdHint;
      });
      return;
    }
    setState(() {
      _clear();
      _busy = true;
    });
    try {
      final response = switch (_mode) {
        _Resource.rival => await AwmcApiService.rivalData(rivalId!),
        _Resource.music when query.isEmpty =>
          await AwmcApiService.musicUnlockCandidates(),
        _Resource.music => await AwmcApiService.selectMusic(query),
      };
      if (!mounted) return;
      if (_mode == _Resource.music && response.httpStatus == 410) {
        final songs = query.isEmpty
            ? await SongSearchService.loadAllSongs()
            : await SongSearchService.searchSongs(query);
        if (!mounted) return;
        setState(() {
          _source = l10n.awmcLocalMusicFallback;
          _rows = [
            for (final song in (songs ?? []).take(50))
              (id: song.id, title: song.title, detail: null)
          ];
        });
      } else if (!response.ok) {
        setState(() => _error = response.displayMessage);
      } else {
        final payload = response.businessData;
        setState(() {
          _source = 'AWMC';
          _rows = _mode == _Resource.music ? _music(payload) : _rival(payload);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.awmcChartUnavailable);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _loaded = true;
        });
      }
    }
  }

  List<({String id, String title, String? detail})> _music(Object? payload) {
    if (payload is! Map) return const [];
    final rows = payload['candidates'] ?? payload['items'];
    if (rows is! List) return const [];
    return [
      for (final row in rows.whereType<Map>().take(100))
        if (row['name'] case final String name when name.isNotEmpty)
          (
            id: '${row['musicId'] ?? row['id'] ?? ''}',
            title: name,
            detail: row['versionName'] is String
                ? row['versionName'] as String
                : null
          ),
    ];
  }

  List<({String id, String title, String? detail})> _rival(Object? payload) {
    if (payload is! Map) return const [];
    final data = payload['data'] is Map ? payload['data'] as Map : payload;
    final user =
        data['userData'] ?? data['userRivalData'] ?? data['user'] ?? data;
    final profile = user is List ? user.firstOrNull : user;
    if (profile is! Map) return const [];
    final name = profile['userName'] ?? profile['nickname'] ?? profile['name'];
    final rating = profile['playerRating'] ?? profile['rating'];
    if (name is! String || name.trim().isEmpty) return const [];
    return [
      (id: '', title: name, detail: rating is num ? 'Rating $rating' : null)
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BackgroundPageScaffold(
      title: 'AWMC · ${l10n.awmcUnlockCandidates}',
      actions: [
        IconButton(
          tooltip: l10n.awmcCabinetTitle,
          icon: const Icon(Icons.point_of_sale_outlined),
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AwmcCabinetPage()),
            );
          },
        ),
      ],
      child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            AnimatedChoiceBar<_Resource>(
                values: _Resource.values,
                value: _mode,
                label: (mode) => mode == _Resource.music
                    ? l10n.awmcUnlockCandidates
                    : l10n.awmcRivalProfile,
                onChanged: _busy
                    ? null
                    : (mode) => setState(() {
                          _query.clear();
                          _clear();
                          _mode = mode;
                        })),
            const SizedBox(height: 12),
            TextField(
                controller: _query,
                enabled: !_busy,
                keyboardType: _mode == _Resource.rival
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: _mode == _Resource.rival
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                maxLength: _mode == _Resource.rival ? 10 : 100,
                decoration: InputDecoration(
                    labelText: _mode == _Resource.rival
                        ? l10n.awmcRivalIdHint
                        : l10n.flowSearchTitleArtistGenreAliasBPMID),
                onSubmitted: (_) => _fetch()),
            Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton(
                  onPressed: _busy ? null : _fetch,
                  child: Text(_busy
                      ? l10n.flowLoading2
                      : '${l10n.flowConfirm} · ${_mode == _Resource.music ? 1 : 2} Token'),
                )),
            if (_error case final error?)
              Text(error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_source case final source?) Text(source),
            if (_loaded && _error == null && _rows.isEmpty)
              Text(l10n.flowNoData),
            for (final row in _rows)
              ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(row.title),
                  subtitle: row.detail == null ? null : Text(row.detail!),
                  trailing: row.id.isEmpty ? null : Text(row.id)),
            if (_mode == _Resource.rival && _rows.isNotEmpty)
              Text(l10n.awmcRivalNoCombos),
          ]),
    );
  }
}
