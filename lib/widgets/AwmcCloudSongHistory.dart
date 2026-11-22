import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/LocalizationsExtension.dart';
import '../service/AWMC/AwmcNetSongService.dart';
import '../service/AccountStore.dart';
import '../service/History/ChartHistoryCore.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import 'AppUi.dart';

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
    final history = _history;
    final events =
        (history?[widget.levelIndex] ?? const <ChartHistoryEvent>[]).reversed;
    final locale = MaterialLocalizations.of(context);
    final seconds = _retrySeconds;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.awmcNetSongHistory,
                style: Theme.of(context).textTheme.titleSmall),
            if (_loading)
              Text(l10n.flowLoading2)
            else if (seconds > 0)
              Text(l10n.awmcNetSongRetryIn('$seconds'))
            else if (history == null) ...[
              if (_status == 404) Text(l10n.awmcNetSongHistoryHidden),
              if (_status != null && _status != 404 && _status != 429)
                Text(l10n.awmcChartUnavailable),
              TextButton(
                onPressed: _fetch,
                child: Text(_status == null
                    ? l10n.awmcNetViewSongHistory
                    : l10n.flowRetry),
              ),
            ] else if (events.isEmpty)
              Text(l10n.flowNoData)
            else ...[
              for (final event in _expanded ? events : events.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${locale.formatShortDate(DateTime.fromMillisecondsSinceEpoch(event.tMs))} '
                    '· ${event.achievement.toStringAsFixed(4)}%'
                    '${event.dxScore > 0 ? " · DX ${event.dxScore}" : ""}',
                  ),
                ),
              if (events.length > 5)
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded
                      ? l10n.flowCollapse
                      : l10n.flowShowAllP0Entries('${events.length}')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
