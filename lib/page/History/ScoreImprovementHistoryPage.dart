import 'dart:async';

import 'package:flutter/material.dart';

import '../../service/AccountStore.dart';
import '../../service/History/ChartHistoryStore.dart';
import '../../service/History/ScoreImprovementCore.dart';
import '../../service/SongSearchService.dart';
import '../../utils/AppDesignTokens.dart';
import '../../utils/AppTheme.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/UserProfileNotifier.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/ScoreImprovementCard.dart';
import '../../widgets/SongSearchEntry.dart';
import '../SongInfoPage.dart';
import '../../widgets/AppDialogs.dart';

class ScoreImprovementHistoryPage extends StatefulWidget {
  const ScoreImprovementHistoryPage({super.key});

  @override
  State<ScoreImprovementHistoryPage> createState() =>
      _ScoreImprovementHistoryPageState();
}

class _ScoreImprovementHistoryPageState
    extends State<ScoreImprovementHistoryPage> {
  final _search = TextEditingController();
  Timer? _searchTimer;
  bool _searchLoading = false;
  String? _searchError;
  Set<int>? _searchMatchIds;
  int _searchGeneration = 0;
  List<DailyScoreImprovement> _entries = [];
  bool _loading = true;
  String? _error;
  String _accountLabel = '';
  int _startedAtMs = 0;
  int _generation = 0;
  String? _selectedDay;
  String? _historyKey;
  int _limit = 60;

  @override
  void initState() {
    super.initState();
    CurrentDataSourceNotifier.instance.addListener(_sourceChanged);
    UserProfileNotifier.instance.addListener(_profileChanged);
    _load();
  }

  @override
  void dispose() {
    CurrentDataSourceNotifier.instance.removeListener(_sourceChanged);
    UserProfileNotifier.instance.removeListener(_profileChanged);
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _sourceChanged() {
    _resetSearch();
    _selectedDay = null;
    _load();
  }

  void _profileChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final source = CurrentDataSourceNotifier.instance.value;
    setState(() {
      _loading = true;
      _error = null;
      _entries = [];
      _accountLabel = '';
      _startedAtMs = 0;
      _limit = 60;
    });
    try {
      final key = await ChartHistoryStore.storageKey(sourceKey: source.key);
      final history =
          await ChartHistoryStore.instance.scoreImprovements(sourceKey: key);
      final accounts = await AccountStore.loadAll();
      if (!mounted || generation != _generation) return;
      final name = accounts[source.key]?.nickname ?? '';
      final days = history.entries.map((entry) => entry.day).toSet().toList()
        ..sort((a, b) => b.compareTo(a));
      setState(() {
        // 同一账号刷新时保留所选日期，切换账号或旧日期消失时选最新日期。
        if (_historyKey != key || !days.contains(_selectedDay)) {
          _selectedDay = days.firstOrNull;
        }
        if (_historyKey != null && _historyKey != key) _resetSearch();
        _historyKey = key;
        _accountLabel =
            '${source.displayName}${name.isEmpty ? '' : ' · $name'}';
        _startedAtMs = history.startedAtMs;
        _entries = history.entries;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = '读取提升历史失败：$error';
        _loading = false;
      });
    }
  }

  void _resetSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    _searchTimer?.cancel();
    _searchGeneration++;
    _search.clear();
    _searchMatchIds = null;
    _searchLoading = false;
    _searchError = null;
  }

  void _submitSearch(String query) {
    _searchTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    if (_search.text != query) _search.text = query;
    unawaited(_performSearch(query));
  }

  void _searchChanged(String query) {
    _searchTimer?.cancel();
    _searchGeneration++;
    if (query.trim().isEmpty) {
      unawaited(_performSearch(query));
      return;
    }
    setState(() {
      _searchLoading = true;
      _searchError = null;
      _searchMatchIds = null;
      _limit = 60;
    });
    _searchTimer = Timer(const Duration(milliseconds: 300),
        () => unawaited(_performSearch(query)));
  }

  Future<void> _performSearch(String query) async {
    query = query.trim();
    final generation = ++_searchGeneration;
    setState(() {
      _searchMatchIds = null;
      _searchError = null;
      _searchLoading = query.isNotEmpty;
      _limit = 60;
    });
    if (query.isEmpty) return;
    try {
      // 与乐曲查询的普通模式共用匹配规则，搜索结果仍限定在所选日期。
      final songs =
          await SongSearchService.searchSongs(query, titleOnly: false);
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchMatchIds =
            songs.map((song) => int.tryParse(song.id)).whereType<int>().toSet();
        _searchLoading = false;
      });
    } catch (error) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _searchError = '搜索失败：$error';
        _searchLoading = false;
      });
    }
  }

  Widget _buildSearchEntry() => SongSearchEntry(
        controller: _search,
        onChanged: _searchChanged,
        onSubmitted: _submitSearch,
      );

  void _showHelp() {
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog<void>(
        context: context,
        builder: (context) => AppAlertDialog(
              title: const Text('关于成绩提升历史'),
              content: const SingleChildScrollView(
                  child: Text('成功刷新自己的成绩时自动记录，水鱼、落雪和 AWMC NET 按数据源与账号分别保存。\n\n'
                      '首次没有旧成绩可比时仅建立基线；刷新无变化不新增记录。当天同一谱面的多次变化合成一张卡，展示首次变化前到最新值。\n\n'
                      '按刷新时的本地日期归档，时间代表发现变化的时间，并非实际游玩时间。卡片按前后值标为成绩提升、成绩回退、成绩无变化，或有升有降的成绩变化；首次出现的谱面另注明首次记录。\n\n'
                      'Rating 是该谱面的 Rating，不代表总 Rating 的增量。历史仅在本机保存，不会自动回填启用前的旧成绩。')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('知道了'))
              ],
            ));
  }

  /// 所选日期的概况：账号、记录起点和当天的变化数量。
  Widget _buildOverview(List<DailyScoreImprovement> dayEntries) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final improved = dayEntries
        .where((entry) => entry.status == ScoreChangeStatus.improvement)
        .length;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _accountLabel.isEmpty ? '当前账号的本地成绩历史' : _accountLabel,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _startedAtMs == 0
                ? '刷新数据后开始记录；首次无旧成绩时仅建立基线。'
                : '${_date(DateTime.fromMillisecondsSinceEpoch(_startedAtMs))} 起记录 · 同日同谱面自动合并',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          if (dayEntries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    centered: true,
                    label: '谱面',
                    value: '${dayEntries.length}',
                  ),
                ),
                Expanded(
                  child: StatTile(
                    centered: true,
                    label: '提升',
                    value: '$improved',
                    valueColor: AppColors.successGreen(brightness),
                  ),
                ),
                Expanded(
                  child: StatTile(
                    centered: true,
                    label: '变化次数',
                    value:
                        '${dayEntries.fold<int>(0, (n, e) => n + e.changeCount)}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayPills(List<String> days) {
    return SingleChildScrollView(
      key: ValueKey(_historyKey),
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          FilterPill(
            label: days[i],
            selected: days[i] == _selectedDay,
            onTap: () {
              if (days[i] == _selectedDay) return;
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {
                _selectedDay = days[i];
                _limit = 60;
              });
            },
          ),
        ],
      ]),
    );
  }

  Widget _buildStateMessage(IconData? icon, String title, String? detail,
      {VoidCallback? onRetry}) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 42, color: colors.onSurfaceVariant),
              const SizedBox(height: 12),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('重试')),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _entries.map((entry) => entry.day).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final query = _search.text.trim().toLowerCase();
    final dayEntries =
        _entries.where((entry) => entry.day == _selectedDay).toList();
    final filtered = dayEntries.where((entry) {
      return query.isEmpty ||
          (_searchMatchIds?.contains(entry.after.songId) ?? false) ||
          // 曲库移除或改名后的历史仍可按快照曲名、完整 ID 找到。
          entry.after.title.toLowerCase().contains(query) ||
          entry.after.songId.toString() == query;
    }).toList();
    final shown = filtered.take(_limit).toList();
    return BackgroundPageScaffold(
      title: '成绩提升历史',
      actions: [
        IconButton(
            onPressed: _showHelp,
            tooltip: '记录规则',
            icon: const Icon(Icons.info_outline))
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
                    AppDesignTokens.gutter, AppDesignTokens.cardGap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverview(dayEntries),
                    if (days.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _buildDayPills(days),
                    ],
                    const SizedBox(height: 10),
                    _buildSearchEntry(),
                  ],
                ),
              ),
              Expanded(
                child: _loading || _searchLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null || _searchError != null
                        ? _buildStateMessage(null, (_error ?? _searchError)!,
                            null,
                            onRetry: _error != null
                                ? _load
                                : () => _submitSearch(_search.text))
                        : filtered.isEmpty
                            ? _buildStateMessage(
                                Icons.auto_graph_rounded,
                                _entries.isEmpty ? '还没有成绩提升记录' : '没有符合条件的记录',
                                _entries.isEmpty
                                    ? '成功刷新后，发生变化的最佳成绩会出现在这里。'
                                    : '试试其他关键词或日期。')
                            : ListView.builder(
                                key: ValueKey(_selectedDay),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding: EdgeInsets.fromLTRB(
                                    AppDesignTokens.gutter,
                                    0,
                                    AppDesignTokens.gutter,
                                    AppDesignTokens.gutter +
                                        MediaQuery.paddingOf(context).bottom),
                                itemCount: shown.length +
                                    (filtered.length > _limit ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == shown.length) {
                                    return TextButton(
                                        onPressed: () =>
                                            setState(() => _limit += 60),
                                        child: Text(
                                            '加载当天更多记录（剩余 ${filtered.length - _limit} 张）'));
                                  }
                                  final entry = shown[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: AppDesignTokens.cardGap),
                                    child: EntranceAnimation(
                                      index: index % 8,
                                      offset: const Offset(0, 8),
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: ScoreImprovementCard(
                                          entry: entry,
                                          onOpen: () {
                                            FocusManager.instance.primaryFocus
                                                ?.unfocus();
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        SongInfoPage(
                                                            songId: entry
                                                                .after.songId
                                                                .toString(),
                                                            initialLevelIndex:
                                                                entry.after
                                                                    .levelIndex,
                                                            isDefaultLevelIndex:
                                                                false)));
                                          }),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
