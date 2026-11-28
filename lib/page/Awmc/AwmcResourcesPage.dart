import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/LocalizationsExtension.dart';
import '../../service/AWMC/AwmcApiService.dart';
import '../../service/Library/SongSearchService.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../widgets/AnimatedChoiceBar.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../song_info/SongInfoPage.dart';
import 'AwmcCabinetPage.dart';

import 'package:my_first_flutter_app/widgets/ExpressiveLoadingIndicator.dart';
enum _Resource { music, rival }

/// AWMC 资源候选与对手资料查询页面。
class AwmcResourcesPage extends StatefulWidget {
  const AwmcResourcesPage({super.key});

  /// 解析 `/v1/rival/data` 响应（兼容线上 `userRivalData.rivalName` 与 `userData`）。
  @visibleForTesting
  static List<({String id, String title, String? detail})> parseRivalProfile(
      Object? payload) {
    if (payload is! Map) return const [];
    final data = payload['data'] is Map ? payload['data'] as Map : payload;
    final user =
        data['userRivalData'] ?? data['userData'] ?? data['user'] ?? data;
    final profile = user is List ? user.firstOrNull : user;
    if (profile is! Map) return const [];
    final name = profile['rivalName'] ??
        profile['userName'] ??
        profile['nickname'] ??
        profile['name'];
    if (name is! String || name.trim().isEmpty) return const [];
    final rawId = profile['rivalId'] ?? profile['userId'] ?? data['userId'];
    final rawIdText =
        rawId is num || rawId is String ? rawId.toString().trim() : '';
    final rating = profile['playerRating'] ?? profile['rating'];
    return [
      (
        id: rawIdText.isEmpty ? '' : '#$rawIdText',
        title: name.trim(),
        detail: rating is num ? 'Rating $rating' : null,
      )
    ];
  }

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
          _rows = _mode == _Resource.music
              ? _music(payload)
              : AwmcResourcesPage.parseRivalProfile(payload);
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

  static List<({String id, String title, String? detail})> _music(
      Object? payload) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final tokenCost = _mode == _Resource.music ? 1 : 2;

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
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 24),
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
                    }),
          ),
          const SizedBox(height: AppDesignTokens.cardGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionHeader(
                  title: _mode == _Resource.music
                      ? l10n.awmcUnlockCandidates
                      : l10n.awmcRivalProfile,
                  padding: const EdgeInsets.only(bottom: 12),
                  trailing: AppBadge(
                    text: '$tokenCost Token',
                    background: AppSurfaces.inset(context),
                    foreground: scheme.onSurfaceVariant,
                  ),
                ),
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
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _mode == _Resource.rival
                        ? l10n.awmcRivalIdHint
                        : l10n.flowSearchTitleArtistGenreAliasBPMID,
                    filled: true,
                    fillColor: AppSurfaces.inset(context),
                    prefixIcon: Icon(
                      _mode == _Resource.rival
                          ? Icons.badge_outlined
                          : Icons.search_rounded,
                      size: 20,
                    ),
                    suffixIcon: _query.text.isNotEmpty && !_busy
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _query.clear()),
                          )
                        : null,
                  ).insetLabel(context),
                  onSubmitted: (_) => _fetch(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusMedium),
                      ),
                    ),
                    onPressed: _busy ? null : _fetch,
                    child: _busy
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ExpressiveLoadingIndicator(size: 16, color: scheme.onPrimary),
                              const SizedBox(width: 8),
                              Text(l10n.flowLoading2),
                            ],
                          )
                        : Text('${l10n.flowConfirm} · $tokenCost Token'),
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withValues(alpha: 0.45),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusSmall),
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
                            style: TextStyle(fontSize: 13, color: scheme.error),
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
            duration:
                AppDesignTokens.motion(context, AppDesignTokens.mediumMotion),
            child: KeyedSubtree(
              key: ValueKey((_mode, _loaded, _error, _rows.length)),
              child: _buildResultSection(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(BuildContext context) {
    if (!_loaded || _error != null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (_rows.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 32, color: scheme.outline),
              const SizedBox(height: 8),
              Text(
                l10n.flowNoData,
                style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: _source ?? 'AWMC',
            padding: const EdgeInsets.only(bottom: 12),
            trailing: AppBadge(
              text: '${_rows.length}',
              background: AppSurfaces.inset(context),
              foreground: scheme.onSurfaceVariant,
            ),
          ),
          if (_mode == _Resource.rival) ...[
            for (final (index, row) in _rows.indexed) ...[
              if (index > 0) const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppSurfaces.inset(context),
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusSmall),
                      ),
                      child: Icon(Icons.person_outline_rounded,
                          color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.title,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          if (row.id.isNotEmpty || row.detail != null) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (row.id.isNotEmpty)
                                  AppBadge(
                                    text: row.id,
                                    background: AppSurfaces.card(context),
                                    foreground: scheme.onSurfaceVariant,
                                  ),
                                if (row.detail != null)
                                  Text(
                                    row.detail!,
                                    style: AppTheme.number(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.awmcRivalNoCombos,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            for (final (index, row) in _rows.indexed) ...[
              if (index > 0) const SizedBox(height: 8),
              _buildMusicRow(context, row),
            ],
        ],
      ),
    );
  }

  Widget _buildMusicRow(
      BuildContext context, ({String id, String title, String? detail}) row) {
    final scheme = Theme.of(context).colorScheme;
    final isSongId = RegExp(r'^\d+$').hasMatch(row.id);
    return Material(
      color: AppSurfaces.inset(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: InkWell(
        onTap: isSongId
            ? () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SongInfoPage(songId: row.id),
                  ),
                );
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (row.detail != null && row.detail!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.detail!,
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              if (row.id.isNotEmpty) ...[
                const SizedBox(width: 8),
                AppBadge(
                  text: row.id,
                  background: AppSurfaces.card(context),
                  foreground: scheme.onSurfaceVariant,
                ),
              ],
              if (isSongId) ...[
                const SizedBox(width: 4),
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
