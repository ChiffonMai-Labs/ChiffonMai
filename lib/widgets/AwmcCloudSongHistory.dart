import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/AWMC/AwmcNetSongService.dart';
import '../service/Account/AccountStore.dart';
import '../service/History/ChartHistoryCore.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import 'AppUi.dart';

import 'package:my_first_flutter_app/widgets/ExpressiveLoadingIndicator.dart';
/// 歌曲详情页内嵌的 AWMC NET 云端历史卡片。
class AwmcCloudSongHistory extends StatefulWidget {
  const AwmcCloudSongHistory({
    super.key,
    required this.songId,
    required this.levelIndex,
  });

  final int songId;
  final int levelIndex;

  @override
  State<AwmcCloudSongHistory> createState() => _AwmcCloudSongHistoryState();
}

class _AwmcCloudSongHistoryState extends State<AwmcCloudSongHistory> {
  String? _qq;
  Map<int, List<ChartHistoryEvent>>? _history;
  int _generation = 0;
  int? _status;
  bool _loading = false;
  bool _expanded = false;
  DateTime? _retryAt;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    AccountStore.revision.addListener(_loadAccount);
    unawaited(_loadAccount());
  }

  @override
  void didUpdateWidget(AwmcCloudSongHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songId != widget.songId) _clearHistory();
    if (oldWidget.levelIndex != widget.levelIndex) _expanded = false;
  }

  @override
  void dispose() {
    AccountStore.revision.removeListener(_loadAccount);
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    final accounts = await AccountStore.loadAll();
    if (!mounted) return;
    final id = accounts[RefreshDataSource.awmc.key]?.id.trim() ?? '';
    final qq = AwmcNetSongService.isQq(id) ? id : null;
    if (qq == _qq) return;
    setState(() {
      _qq = qq;
      _clearHistory();
    });
  }

  void _clearHistory() {
    _generation++;
    _history = null;
    _status = null;
    _loading = false;
    _expanded = false;
  }

  int get _retrySeconds {
    final ms = _retryAt?.difference(DateTime.now()).inMilliseconds ?? 0;
    return ms <= 0 ? 0 : (ms + 999) ~/ 1000;
  }

  Future<void> _fetch() async {
    final qq = _qq;
    if (qq == null || _loading || _retrySeconds > 0) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _status = null;
    });
    try {
      final history = await AwmcNetSongService.publicHistory(qq, widget.songId);
      if (!mounted || generation != _generation) return;
      setState(() => _history = history);
    } on AwmcNetSongException catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _status = error.statusCode;
        final cooldown = error.retryAfter;
        if (cooldown != null) {
          _retryAt = DateTime.now().add(cooldown);
          _retryTimer?.cancel();
          _retryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_retrySeconds == 0) timer.cancel();
            if (mounted) setState(() {});
          });
        }
      });
    } on Exception {
      if (mounted && generation == _generation) setState(() => _status = 0);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_qq == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final history = _history;
    final events =
        (history?[widget.levelIndex] ?? const <ChartHistoryEvent>[])
            .reversed
            .toList();
    final locale = MaterialLocalizations.of(context);
    final seconds = _retrySeconds;

    return Padding(
      padding: const EdgeInsets.only(top: AppDesignTokens.cardGap),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: l10n.awmcNetSongHistory,
              padding: const EdgeInsets.only(bottom: 10),
            ),
            if (_loading)
              Row(
                children: [
                  const ExpressiveLoadingIndicator(size: 16),
                  const SizedBox(width: 10),
                  Text(
                    l10n.flowLoading2,
                    style:
                        TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              )
            else if (seconds > 0)
              _statusBanner(
                context,
                Icons.hourglass_bottom_rounded,
                l10n.awmcNetSongRetryIn('$seconds'),
              )
            else if (history == null) ...[
              if (_status == 404) ...[
                _statusBanner(
                  context,
                  Icons.lock_outline_rounded,
                  l10n.awmcNetSongHistoryHidden,
                ),
                const SizedBox(height: 10),
              ] else if (_status != null && _status != 404 && _status != 429) ...[
                _statusBanner(
                  context,
                  Icons.cloud_off_outlined,
                  l10n.awmcChartUnavailable,
                ),
                const SizedBox(height: 10),
              ],
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  onPressed: _fetch,
                  icon: Icon(
                    _status == null
                        ? Icons.history_rounded
                        : Icons.refresh_rounded,
                    size: 18,
                  ),
                  label: Text(_status == null
                      ? l10n.awmcNetViewSongHistory
                      : l10n.flowRetry),
                ),
              ),
            ] else if (events.isEmpty)
              Text(
                l10n.flowNoData,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              )
            else ...[
              for (final (index, event)
                  in (_expanded ? events : events.take(5)).indexed) ...[
                if (index > 0) const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppSurfaces.inset(context),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Text(
                        locale.formatShortDate(
                            DateTime.fromMillisecondsSinceEpoch(event.tMs)),
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Text(
                        '${event.achievement.toStringAsFixed(4)}%',
                        style: AppTheme.number(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      if (event.dxScore > 0) ...[
                        const SizedBox(width: 8),
                        AppBadge(
                          text: 'DX ${event.dxScore}',
                          background: AppSurfaces.card(context),
                          foreground: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (events.length > 5) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: LinkPill(
                    label: _expanded
                        ? l10n.flowCollapse
                        : l10n.flowShowAllP0Entries('${events.length}'),
                    onTap: () => setState(() => _expanded = !_expanded),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBanner(BuildContext context, IconData icon, String message) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
