import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:flutter/material.dart';

import '../constant/AppLinks.dart';
import '../entity/LuoXue/LuoXueSongEntity.dart';
import '../entity/Union/UnionSong.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../manager/DivingFish/UnionManager.dart';
import '../manager/LuoXue/LuoXueSongsManager.dart';
import '../service/UpdateCalendarService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/CoverUtil.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppUi.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/GuideLinkText.dart';
import '../widgets/MarqueeText.dart';
import '../widgets/ProgressUi.dart';
import 'SongInfoPage.dart';

/// 某一天上线的一首歌的一种谱面。
class UpdateCalendarEntry {
  /// 项目内统一的歌曲 ID（DX 谱带 1xxxx 前缀）。
  final String songId;
  final String title;

  /// `DX` / `SD`；宴谱由 [SongTypeBadge] 按 ID 判断。
  final String type;

  /// 这一天上线的难度序号和标签上显示的定数，从低到高。
  final List<({int level, String label})> levels;

  /// 这一天上线的谱面数。
  final int chartCount;

  const UpdateCalendarEntry({
    required this.songId,
    required this.title,
    required this.type,
    required this.levels,
    required this.chartCount,
  });
}

/// 把落雪曲目列表按谱面的 `release_date` 整理成「日期 → 当天上线的谱面」。
///
/// 日期按谱面记录，同一首歌的 ST、DX 谱和后加的 Re:MASTER 会落在不同的日子。
///
/// 落雪的宴谱没有定数（`level_value` 恒为 0），从 [utageDs]（歌曲 ID → 定数）取；
/// 没有时显示落雪的等级，如 `14+?`。
Map<String, List<UpdateCalendarEntry>> buildUpdateCalendar(
  LuoXueSongEntity entity, {
  Map<String, double> utageDs = const {},
}) {
  final calendar = <String, List<UpdateCalendarEntry>>{};

  void addCharts(
      String songId,
      String title,
      String type,
      Map<String, List<({int level, String label})>> levelsByDate,
      Map<String, int> countByDate) {
    countByDate.forEach((date, count) {
      (calendar[date] ??= []).add(UpdateCalendarEntry(
        songId: songId,
        title: title,
        type: type,
        levels: [...?levelsByDate[date]]
          ..sort((a, b) => a.level.compareTo(b.level)),
        chartCount: count,
      ));
    });
  }

  void addStandard(LuoXueSong song, String songId, String type,
      List<LuoXueSongDifficulty>? charts) {
    final levels = <String, List<({int level, String label})>>{};
    final counts = <String, int>{};
    for (final chart in charts ?? const <LuoXueSongDifficulty>[]) {
      final date = chart.releaseDate;
      if (date == null || date.isEmpty) continue;
      (levels[date] ??= []).add((
        level: chart.difficulty,
        label: chart.levelValue.toStringAsFixed(1),
      ));
      counts[date] = (counts[date] ?? 0) + 1;
    }
    addCharts(songId, song.title, type, levels, counts);
  }

  for (final song in entity.songs) {
    final id = song.id;
    addStandard(song, '$id', 'SD', song.difficulties.standard);
    // 落雪的 DX 谱和 ST 谱共用 ID，项目内 DX 谱的 ID 要加 1xxxx 前缀。
    addStandard(
        song, '${id < 10000 ? id + 10000 : id}', 'DX', song.difficulties.dx);
    final utageLevels = <String, List<({int level, String label})>>{};
    final counts = <String, int>{};
    for (final chart
        in song.difficulties.utage ?? const <LuoXueSongDifficultyUtage>[]) {
      final date = chart.releaseDate;
      if (date == null || date.isEmpty) continue;
      counts[date] = (counts[date] ?? 0) + 1;
      final label = utageDs['$id']?.toStringAsFixed(1) ?? chart.level;
      if (label != null) {
        (utageLevels[date] ??= []).add((level: 0, label: label));
      }
    }
    addCharts('$id', song.title, 'SD', utageLevels, counts);
  }
  for (final entries in calendar.values) {
    // 新歌的 ID 通常更大，排在前面。
    entries.sort((a, b) =>
        (int.tryParse(b.songId) ?? 0).compareTo(int.tryParse(a.songId) ?? 0));
  }
  return calendar;
}

/// 这些条目一共是多少首歌：同一首歌的 ST、DX 谱只算一首。
int _countSongs(Iterable<UpdateCalendarEntry> entries) => entries
    .map((entry) {
      final id = int.tryParse(entry.songId) ?? 0;
      return id >= 10000 && id < 100000 ? id - 10000 : id;
    })
    .toSet()
    .length;

/// 更新日历：按日期查看国服每次更新上线了哪些谱面。
class UpdateCalendarPage extends StatefulWidget {
  /// 测试用，默认读落雪曲目列表。
  final Future<LuoXueSongEntity?> Function()? songsLoader;

  /// 测试用，默认从水鱼曲库和 union 读宴谱定数。
  final Future<Map<String, double>> Function()? utageDsLoader;

  const UpdateCalendarPage({super.key, this.songsLoader, this.utageDsLoader});

  @override
  State<UpdateCalendarPage> createState() => _UpdateCalendarPageState();
}

class _UpdateCalendarPageState extends State<UpdateCalendarPage> {
  List<String> get _weekdays {
    final days = MaterialLocalizations.of(context).narrowWeekdays;
    return [...days.skip(1), days.first];
  }

  Map<String, List<UpdateCalendarEntry>> _calendar = const {};
  Map<String, List<CalendarDelivery>> _deliveries = const {};
  List<String> _dates = const [];

  /// 有更新的月份，从早到晚。切换月份时跳过没有更新的月份。
  List<DateTime> _months = const [];
  int _monthIndex = 0;

  /// 切换方向：1 是新月份从右边滑入，-1 是从左边滑入。
  int _slideDirection = 1;
  double _monthDragDistance = 0;
  String? _selectedDate;
  bool _loading = true;
  bool _loadingDeliveries = false;
  bool _deliveryError = false;
  bool _followLatest = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadDeliveries();
  }

  /// 宴谱的定数（歌曲 ID → 定数）：优先水鱼曲库，水鱼还没收录的用 union 补上。
  /// 两边都读不到时宴谱退回显示等级。
  Future<Map<String, double>> _loadUtageDs() async {
    final union = await UnionManager().getLookup();
    final songs = await MaimaiMusicDataManager().getCachedSongs() ?? const [];
    return {
      for (final song in union.values)
        for (final entry in (song.ut ?? const <String, Difficulty>{}).entries)
          if (entry.value.levelValue > 0) entry.key: entry.value.levelValue,
      for (final song in songs)
        if (song.id.length == 6 && song.ds.isNotEmpty) song.id: song.ds.first,
    };
  }

  Future<void> _load() async {
    if (!_loading) setState(() => _loading = true);
    LuoXueSongEntity? entity;
    var utageDs = const <String, double>{};
    try {
      entity = await (widget.songsLoader?.call() ??
          LuoXueSongsManager().getLuoXueSongs());
      utageDs = await (widget.utageDsLoader?.call() ?? _loadUtageDs());
    } catch (e) {
      debugPrint('读取更新日历失败: $e');
    }
    if (!mounted) return;
    final calendar = entity == null
        ? const <String, List<UpdateCalendarEntry>>{}
        : buildUpdateCalendar(entity, utageDs: utageDs);
    setState(() {
      _calendar = calendar;
      _syncDates();
      _loading = false;
    });
  }

  Future<void> _loadDeliveries() async {
    if (_loadingDeliveries) return;
    setState(() {
      _loadingDeliveries = true;
      _deliveryError = false;
    });
    try {
      final deliveries = await fetchCalendarDeliveries();
      if (!mounted) return;
      final byDate = <String, List<CalendarDelivery>>{};
      for (final delivery in deliveries) {
        (byDate[delivery.date] ??= []).add(delivery);
      }
      setState(() {
        _deliveries = byDate;
        _syncDates();
        _loadingDeliveries = false;
      });
    } catch (e) {
      debugPrint('读取配信数据失败: $e');
      if (!mounted) return;
      setState(() {
        _loadingDeliveries = false;
        _deliveryError = true;
      });
    }
  }

  void _syncDates() {
    _dates = {..._calendar.keys, ..._deliveries.keys}.toList()..sort();
    final months = <DateTime>[];
    for (final date in _dates) {
      final parsed = DateTime.tryParse(date);
      if (parsed == null) continue;
      final month = DateTime(parsed.year, parsed.month);
      if (months.isEmpty || months.last != month) months.add(month);
    }
    _months = months;
    if (_followLatest || !_dates.contains(_selectedDate)) {
      _selectedDate = _dates.isEmpty ? null : _dates.last;
    }
    final monthIndex = _months.indexWhere((month) =>
        _selectedDate?.startsWith(_dateKey(month).substring(0, 8)) ?? false);
    _monthIndex = monthIndex < 0 ? 0 : monthIndex;
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 某个月的更新次数和歌曲数。
  ({int updates, int songs}) _monthStats(DateTime month) {
    final prefix = _dateKey(month).substring(0, 8);
    final dates = _calendar.keys.where((d) => d.startsWith(prefix)).toList();
    return (
      updates: dates.length,
      songs: _countSongs(dates.expand((date) => _calendar[date]!)),
    );
  }

  /// 选择年月：只列出有更新的月份。
  Future<void> _pickMonth() async {
    final index = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _MonthPickerDialog(
        months: _months,
        selectedIndex: _monthIndex,
        stats: [for (final month in _months) _monthStats(month)],
      ),
    );
    if (index == null || index == _monthIndex || !mounted) return;
    _switchMonth(index);
  }

  /// 切到另一个月份时选中该月最后一次更新。
  void _switchMonth(int index) {
    _slideDirection = index > _monthIndex ? 1 : -1;
    final month = _months[index];
    final prefix = _dateKey(month).substring(0, 8);
    final dates = _dates.where((d) => d.startsWith(prefix)).toList();
    setState(() {
      _followLatest = false;
      _monthIndex = index;
      _selectedDate = dates.isEmpty ? null : dates.last;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.featureUpdateCalendar,
      child: _months.isNotEmpty
          ? _buildContent()
          : _loading || _loadingDeliveries
              ? const Center(child: CircularProgressIndicator())
              : _buildEmpty(),
    );
  }

  Widget _buildEmpty() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 0),
          child: _buildSource(),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.flowUpdateDataTemporarilyUnavailable,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _load();
                    _loadDeliveries();
                  },
                  child: Text(context.l10n.flowRetry),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final entries = _calendar[_selectedDate] ?? const <UpdateCalendarEntry>[];
    final deliveries = _deliveries[_selectedDate] ?? const <CalendarDelivery>[];
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppDesignTokens.gutter, 4, AppDesignTokens.gutter, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSource(),
                const SizedBox(height: AppDesignTokens.cardGap),
                _buildCalendarCard(),
                const SizedBox(height: 16),
                _buildDayHeader(entries),
                const SizedBox(height: 8),
                if (deliveries.isNotEmpty) ...[
                  CollapsibleCard(
                    key: ValueKey(_selectedDate),
                    title: context.l10n.flowReleaseContents,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final delivery in deliveries)
                          _buildDelivery(delivery),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.cardGap),
                ],
                if (_deliveryError)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _loadDeliveries,
                      child:
                          Text(context.l10n.flowCouldNotLoadReleaseDataRetry),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
              AppDesignTokens.gutter,
              0,
              AppDesignTokens.gutter,
              MediaQuery.paddingOf(context).bottom + 24),
          // 首发那天有上千张谱面，必须按需构建。
          sliver: SliverList.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) => GroupedRowShell(
              first: index == 0,
              last: index == entries.length - 1,
              child: _buildEntryRow(entries[index], showDivider: index > 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDelivery(CalendarDelivery delivery) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    final summary = delivery.summary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.itemGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.sections.isEmpty && summary.counted.isEmpty)
            Text(context.l10n.flowNoContentDetails, style: secondary),
          for (final section in summary.sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                section.label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            for (final item in section.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (item.songs.isNotEmpty)
                      Text(item.songs.join('、'), style: secondary),
                  ],
                ),
              ),
            if (section.hidden > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                    context.l10n
                        .flowP0OtherItemsNotShown((section.hidden).toString()),
                    style: secondary),
              ),
          ],
          if (summary.counted.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(summary.counted.join(' · '), style: secondary),
            ),
        ],
      ),
    );
  }

  /// 分别标注谱面日期和配信数据的来源。
  Widget _buildSource() {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideLinkText(
          before: context.l10n.flowChartDateSource,
          label: context.l10n.flowLXNSMaimaiDXScoreTracker,
          url: AppLinks.luoXueRegistrationUrl,
          style: style,
        ),
        const SizedBox(height: 4),
        GuideLinkText(
          before: context.l10n.flowReleaseDataSource,
          label: 'Michaelwucoc',
          url: AppLinks.michaelwucocGitHubUrl,
          style: style,
        ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    final scheme = Theme.of(context).colorScheme;
    final month = _months[_monthIndex];
    final stats = _monthStats(month);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: context.l10n.flowPreviousMonthWithUpdates,
                onPressed: _monthIndex > 0
                    ? () => _switchMonth(_monthIndex - 1)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: PressScale(
                  child: Semantics(
                    button: true,
                    label: context.l10n.flowChooseYearAndMonthCurrentP0P1(
                        (month.year).toString(), (month.month).toString()),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickMonth,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    context.l10n.flowP0P1(
                                        (month.year).toString(),
                                        (month.month).toString()),
                                    style: AppTheme.number(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down_rounded,
                                  size: 22, color: scheme.onSurfaceVariant),
                            ],
                          ),
                          Text(
                            stats.updates == 0
                                ? context.l10n.flowReleaseRecordOnly
                                : context.l10n.flowP0UpdatesP1Songs(
                                    (stats.updates).toString(),
                                    (stats.songs).toString()),
                            style: TextStyle(
                                fontSize: 11, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: context.l10n.flowNextMonthWithUpdates,
                onPressed: _monthIndex < _months.length - 1
                    ? () => _switchMonth(_monthIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final day in _weekdays)
                Expanded(
                  child: Center(
                    child: Text(day,
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _buildSlidingMonth(month),
        ],
      ),
    );
  }

  /// 月份切换用横向滑动，高度随周数平滑变化；左右滑动日历也能切换。
  Widget _buildSlidingMonth(DateTime month) {
    final duration =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _monthDragDistance = 0,
      onHorizontalDragUpdate: (details) =>
          _monthDragDistance += details.primaryDelta ?? 0,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (_monthDragDistance.abs() < 40 && velocity.abs() < 300) return;
        // 手指向左滑看下一个月。
        final swipeLeft =
            velocity.abs() >= 300 ? velocity < 0 : _monthDragDistance < 0;
        final target = _monthIndex + (swipeLeft ? 1 : -1);
        if (target >= 0 && target < _months.length) _switchMonth(target);
      },
      child: ClipRect(
        child: AnimatedSize(
          duration: duration,
          curve: AppDesignTokens.emphasizedCurve,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: duration,
            switchInCurve: AppDesignTokens.emphasizedCurve,
            // 离场用翻转的同一条曲线，新旧两个月始终相隔整整一屏，不会叠在一起。
            switchOutCurve: AppDesignTokens.emphasizedCurve.flipped,
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, if (current != null) current],
            ),
            // AnimatedSwitcher 不会为离场的月份重新调用这里，
            // 方向和进退场要在动画里实时取，否则离场方向是它入场时的旧值。
            transitionBuilder: (child, animation) => AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (context, child) {
                final incoming = child?.key == ValueKey(_months[_monthIndex]);
                final side = _slideDirection * (incoming ? 1 : -1);
                return FractionalTranslation(
                  translation: Offset(side * (1 - animation.value), 0),
                  child: child,
                );
              },
            ),
            child: KeyedSubtree(
              key: ValueKey(month),
              child: _buildMonthGrid(month),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month) {
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    // 周一开头：weekday 1~7 → 前面空 0~6 格。
    final leading = month.weekday - 1;
    final rows = ((leading + dayCount) / 7).ceil();
    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(child: () {
                  final day = row * 7 + column - leading + 1;
                  if (day < 1 || day > dayCount) {
                    return const SizedBox.shrink();
                  }
                  return _buildDayCell(DateTime(month.year, month.month, day));
                }()),
            ],
          ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date) {
    final scheme = Theme.of(context).colorScheme;
    final key = _dateKey(date);
    final count = _countSongs(_calendar[key] ?? const []);
    final hasDelivery = _deliveries.containsKey(key);
    final hasUpdate = count > 0 || hasDelivery;
    final selected = key == _selectedDate;
    final foreground = selected
        ? scheme.onPrimary
        : hasUpdate
            ? scheme.primary
            : scheme.onSurfaceVariant.withValues(alpha: 0.6);
    final cell = AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary
              : hasUpdate
                  ? scheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${date.day}',
                  style: AppTheme.number(
                    fontSize: 14,
                    fontWeight: hasUpdate ? FontWeight.w800 : FontWeight.w500,
                    color: foreground,
                  ),
                ),
                if (hasUpdate)
                  Text(
                    count > 0 ? '$count' : context.l10n.flowRelease,
                    style: AppTheme.number(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!hasUpdate) return cell;
    return PressScale(
      child: Semantics(
        button: true,
        selected: selected,
        label: context.l10n.flowP0P1P2P3(
            (date.month).toString(),
            (date.day).toString(),
            (count > 0 ? context.l10n.flowP0Songs((count).toString()) : '')
                .toString(),
            (hasDelivery ? context.l10n.flowReleaseRecorded : '').toString()),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (selected) return;
            setState(() {
              _followLatest = false;
              _selectedDate = key;
            });
          },
          child: cell,
        ),
      ),
    );
  }

  Widget _buildDayHeader(List<UpdateCalendarEntry> entries) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime.tryParse(_selectedDate ?? '');
    final title = date == null
        ? context.l10n.flowUpdatesOnThisDay
        : context.l10n.flowP0P1P2((date.month).toString(),
            (date.day).toString(), (_weekdays[date.weekday - 1]).toString());
    final charts = entries.fold<int>(0, (sum, e) => sum + e.chartCount);
    // 落雪会提前录入下一次更新的日期。
    final upcoming =
        entries.isNotEmpty && date != null && date.isAfter(DateTime.now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              text: title,
              children: [
                if (upcoming)
                  TextSpan(
                    text: context.l10n.flowNotReleasedYet,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ),
        Text(
          entries.isEmpty
              ? context.l10n.flowReleaseRecord
              : context.l10n.flowP0SongsP1Charts(
                  (_countSongs(entries)).toString(), (charts).toString()),
          style: AppTheme.number(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildEntryRow(UpdateCalendarEntry entry,
      {required bool showDivider}) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SongInfoPage(songId: entry.songId)),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: AppSurfaces.hairline(context)))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: SizedBox(
                width: 44,
                height: 44,
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, entry.songId, 44),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SongTypeBadge(songId: entry.songId, type: entry.type),
                      const SizedBox(width: 5),
                      Expanded(
                        child: MarqueeText(
                          text: entry.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (entry.levels.isEmpty)
                        ChartDifficultyBadge(
                            levelIndex: 0, songId: entry.songId)
                      else
                        for (final chart in entry.levels)
                          ChartDifficultyBadge(
                            levelIndex: chart.level,
                            songId: entry.songId,
                            label: chart.label,
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 选择年月的对话框：按年分组，只有有更新的月份才出现。
class _MonthPickerDialog extends StatelessWidget {
  final List<DateTime> months;
  final int selectedIndex;
  final List<({int updates, int songs})> stats;

  const _MonthPickerDialog({
    required this.months,
    required this.selectedIndex,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 新的年份在上面，月份从小到大。
    final indicesByYear = <int, List<int>>{};
    for (var i = 0; i < months.length; i++) {
      (indicesByYear[months[i].year] ??= []).add(i);
    }
    final years = indicesByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    Widget monthChip(int index) {
      final selected = index == selectedIndex;
      return PressScale(
        child: Semantics(
          button: true,
          selected: selected,
          label: context.l10n.flowP0P1((months[index].year).toString(),
              (months[index].month).toString()),
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? scheme.primary : AppSurfaces.inset(context),
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n
                          .flowMonthP0((months[index].month).toString()),
                      style: AppTheme.number(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? scheme.onPrimary : scheme.onSurface,
                      ),
                    ),
                    Text(
                      stats[index].updates == 0
                          ? context.l10n.flowReleaseRecordOnly
                          : context.l10n.flowP0UpdatesP1Songs(
                              (stats[index].updates).toString(),
                              (stats[index].songs).toString()),
                      maxLines: 1,
                      style: AppTheme.number(
                        fontSize: 11,
                        color: selected
                            ? scheme.onPrimary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // 每格要放下「x 次更新 y 首歌曲」，两列。
    const columns = 2;
    return AppAlertDialog(
      title: Text(context.l10n.flowChooseYearAndMonth),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final year in years) ...[
            Padding(
              padding:
                  EdgeInsets.only(top: year == years.first ? 0 : 14, bottom: 6),
              child: Text(
                context.l10n.flowYearP0((year).toString()),
                style: AppTheme.number(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            for (var start = 0;
                start < indicesByYear[year]!.length;
                start += columns)
              Padding(
                padding: EdgeInsets.only(top: start == 0 ? 0 : 6),
                child: Row(
                  children: [
                    for (var i = start; i < start + columns; i++) ...[
                      if (i > start) const SizedBox(width: 6),
                      Expanded(
                        child: i < indicesByYear[year]!.length
                            ? monthChip(indicesByYear[year]![i])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
      ],
    );
  }
}
