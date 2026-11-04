import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/manager/DivingFish/ProberException.dart';
import 'package:my_first_flutter_app/service/FriendCompareService.dart';
import 'package:my_first_flutter_app/entity/FriendComparisonResult.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ExternalUrlPolicy.dart';
import 'package:my_first_flutter_app/utils/ExternalLaunchUtil.dart';
import 'SongInfoPage.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import '../widgets/AppUi.dart';
import '../widgets/MarqueeText.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

class FriendComparePage extends StatefulWidget {
  const FriendComparePage({super.key});

  @override
  State<FriendComparePage> createState() => _FriendComparePageState();
}

class _FriendComparePageState extends State<FriendComparePage> {
  final FriendCompareService _service = FriendCompareService();
  final TextEditingController _qqController = TextEditingController();

  /// 我的成绩固定用当前数据源。
  final RefreshDataSource _mySource = CurrentDataSourceNotifier.instance.value;

  /// 好友的数据源，可以和我的不同。水鱼和 AWMC NET 按 QQ 号查，落雪按好友码查。
  late RefreshDataSource _friendSource = _mySource;

  bool _isLoading = false;
  ComparisonResult? _result;
  String? _errorMessage;
  // ignore: unused_field
  String? _currentFriendQQ;

  // 筛选和分页
  int? _filterLevelIndex; // null=全部, 0-4=指定难度
  String? _filterResult; // null=全部, 'win'=我赢, 'tie'=平局, 'lose'=好友赢
  static const int _pageSize = 20;
  int _displayCount = _pageSize;

  // 历史记录
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadCachedQQ();
    _loadHistory();
  }

  Future<void> _loadCachedQQ() async {
    if (_friendSource != RefreshDataSource.shuiyu) return;
    final qq = await _service.getCachedQQ();
    if (mounted && _friendSource == RefreshDataSource.shuiyu) {
      _qqController.text = qq;
    }
  }

  Future<void> _loadHistory() async {
    final history = await _service.loadHistory(source: _mySource);
    if (mounted) setState(() => _history = history);
  }

  void _selectSource(RefreshDataSource source) {
    if (source == _friendSource || _isLoading) return;
    setState(() {
      _friendSource = source;
      _result = null;
      _errorMessage = null;
      _qqController.clear();
    });
    _loadCachedQQ();
  }

  String get _idLabel => _friendSource.idIsQQ ? 'QQ 号' : '好友码';

  bool get _isCrossSource => _friendSource != _mySource;

  /// 旧历史没有 friendSource，那时只能比同数据源。
  RefreshDataSource _friendSourceOf(Map<String, dynamic> entry) {
    final key = entry['friendSource'] as String?;
    return key == null ? _mySource : RefreshDataSource.fromKey(key);
  }

  @override
  void dispose() {
    _qqController.dispose();
    super.dispose();
  }

  Future<void> _startCompare() async {
    final friendQQ = _qqController.text.trim();
    if (friendQQ.isEmpty) {
      setState(() => _errorMessage = '请输入好友的$_idLabel');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final friendSource = _friendSource;
      final result = await _service.compareWithFriend(
        friendQQ,
        mySource: _mySource,
        friendSource: friendSource,
      );
      if (mounted) {
        setState(() {
          _result = result;
          _currentFriendQQ = friendQQ;
          _isLoading = false;
          _displayCount = _pageSize;
          _filterLevelIndex = null;
          _filterResult = null;
        });
        // 保存到历史记录
        await _service.saveHistory(friendQQ, result,
            source: _mySource, friendSource: friendSource);
        _loadHistory();
      }
    } on ProberException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
      // 好友未授权时，自动打开绑定链接引导其授权一次
      if (e.code == 'CONSENT_REQUIRED' &&
          e.bindingUrl != null &&
          e.bindingUrl!.isNotEmpty) {
        final uri = Uri.tryParse(e.bindingUrl!);
        if (uri != null && ExternalUrlPolicy.isAllowed(uri)) {
          final opened = await ExternalLaunchUtil.open(uri);
          if (!opened && mounted) {
            await Clipboard.setData(ClipboardData(text: uri.toString()));
            AppToast.show('无法打开授权页，链接已复制到剪贴板');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result;
    return BackgroundPageScaffold(
      title: '好友对比',
      resizeToAvoidBottomInset: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppDesignTokens.gutter,
          4,
          AppDesignTokens.gutter,
          AppDesignTokens.gutter +
              MediaQuery.paddingOf(context).bottom +
              MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchCard(),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildErrorCard(),
            ],
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      '正在拉取好友数据并对比…',
                      style: TextStyle(
                          fontSize: 13.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            if (result != null) ...[
              const SizedBox(height: AppDesignTokens.cardGap),
              EntranceAnimation(
                offset: const Offset(0, 12),
                child: _buildSummaryCard(result),
              ),
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildFilters(result),
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildComparisonList(result),
            ],
            if (result == null && !_isLoading && _errorMessage == null) ...[
              const SizedBox(height: 20),
              if (_history.isNotEmpty) _buildHistory() else _buildEmptyState(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    final scheme = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      borderSide: BorderSide.none,
    );
    const sources = RefreshDataSource.values;
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Text(
              '用我的${_mySource.displayName}成绩，对比好友在这里的成绩',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
          SegmentedTabs(
            height: 40,
            items: [
              for (final source in sources)
                SegmentedTabItem(source.shortDisplayName),
            ],
            selectedIndex: sources.indexOf(_friendSource),
            onChanged: (index) => _selectSource(sources[index]),
          ),
          const SizedBox(height: 10),
          Row(
        children: [
          Expanded(
            child: TextField(
              controller: _qqController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _startCompare(),
              style: AppTheme.number(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: '输入好友的$_idLabel',
                isDense: true,
                filled: true,
                fillColor: AppSurfaces.inset(context),
                prefixIcon: Icon(Icons.person_search_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: border,
                enabledBorder: border,
                focusedBorder: border.copyWith(
                    borderSide: BorderSide(color: scheme.primary, width: 2)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _startCompare,
              child: const Text('开始对比'),
            ),
          ),
        ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                  fontSize: 13.5, height: 1.4, color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_alt_rounded,
                size: 34, color: scheme.primary),
          ),
          const SizedBox(height: 14),
          Text(
            '和好友比比看',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '输入好友的$_idLabel开始对比\n好友需要在${_friendSource.displayName}有数据',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, height: 1.5, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空全部历史记录吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('清空',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
        ],
      ),
    );
    if (confirm == true) {
      await _service.clearHistory(source: _mySource);
      _loadHistory();
    }
  }

  Widget _buildHistory() {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: '历史对比',
          trailing: TextButton(
            onPressed: _confirmClearHistory,
            child: Text('清空',
                style: TextStyle(fontSize: 13, color: scheme.error)),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (index, entry) in _history.indexed)
                _buildHistoryItem(entry, showDivider: index > 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h, {required bool showDivider}) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = scheme.brightness;
    final qq = h['friendQQ'] ?? '';
    final nick = h['friendNickname'] ?? qq;
    final date = h['date'] ?? '';
    final common = h['commonCount'] ?? 0;
    final int win = h['myWinCount'] ?? 0;
    final int tie = h['tieCount'] ?? 0;
    final int lose = h['friendWinCount'] ?? 0;
    final friendSource = _friendSourceOf(h);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_isLoading) return;
        setState(() => _friendSource = friendSource);
        _qqController.text = qq;
        _startCompare();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: scheme.outlineVariant))
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarqueeText(
                    text: '$nick',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${friendSource.shortDisplayName} · $date · 共同 $common 首',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  StackedBar(
                    height: 6,
                    gap: 2,
                    segments: [
                      (count: win, color: AppColors.successGreen(brightness)),
                      (count: tie, color: AppColors.warningOrange(brightness)),
                      (count: lose, color: AppColors.errorRed(brightness)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$win : $lose',
              style: AppTheme.number(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            IconButton(
              tooltip: '删除这条记录',
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                await _service.deleteHistory(qq,
                    source: _mySource, friendSource: friendSource);
                _loadHistory();
              },
              icon: Icon(Icons.close_rounded,
                  size: 18, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// 结果总览：双方 Rating、胜负比例和谱面数量。
  Widget _buildSummaryCard(ComparisonResult result) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = scheme.brightness;
    // 好友未公开 Rating 时是 0，这时不比较，也不显示分差
    final friendRatingKnown = result.friendRating > 0;
    final ratingDiff =
        friendRatingKnown ? result.myRating - result.friendRating : 0;

    Widget player(String name, int rating, bool leading, CrossAxisAlignment align) =>
        Expanded(
          child: Column(
            crossAxisAlignment: align,
            children: [
              SizedBox(
                height: 18,
                child: MarqueeText(
                  text: name,
                  style: TextStyle(
                      fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 2),
              if (rating > 0)
                RollingNumber(
                  value: rating,
                  style: AppTheme.number(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: leading ? scheme.primary : scheme.onSurface,
                  ),
                )
              else
                Text(
                  '-',
                  style: AppTheme.number(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );

    Widget legend(String label, int count, Color color) => Expanded(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
              RollingNumber(
                value: count,
                style: AppTheme.number(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              player(
                  _isCrossSource ? '我 · ${_mySource.shortDisplayName}' : '我',
                  result.myRating,
                  ratingDiff > 0,
                  CrossAxisAlignment.start),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: AppTheme.number(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !friendRatingKnown
                          ? '未公开'
                          : ratingDiff == 0
                              ? '同分'
                              : '${ratingDiff > 0 ? '+' : ''}$ratingDiff',
                      style: AppTheme.number(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: ratingDiff == 0
                            ? scheme.onSurfaceVariant
                            : ratingDiff > 0
                                ? AppColors.successGreen(brightness)
                                : AppColors.errorRed(brightness),
                      ),
                    ),
                  ],
                ),
              ),
              player(
                  _isCrossSource
                      ? '${result.friendNickname} · ${_friendSource.shortDisplayName}'
                      : result.friendNickname,
                  result.friendRating,
                  ratingDiff < 0,
                  CrossAxisAlignment.end),
            ],
          ),
          const SizedBox(height: 14),
          StackedBar(
            segments: [
              (
                count: result.myWinCount,
                color: AppColors.successGreen(brightness)
              ),
              (
                count: result.tieCount,
                color: AppColors.warningOrange(brightness)
              ),
              (
                count: result.friendWinCount,
                color: AppColors.errorRed(brightness)
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              legend('我赢', result.myWinCount,
                  AppColors.successGreen(brightness)),
              legend('平局', result.tieCount,
                  AppColors.warningOrange(brightness)),
              legend('好友赢', result.friendWinCount,
                  AppColors.errorRed(brightness)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: scheme.outlineVariant),
          ),
          Row(
            children: [
              Expanded(
                child: StatTile(
                    centered: true,
                    label: '我的谱面',
                    value: '${result.myTotalCharts}'),
              ),
              Expanded(
                child: StatTile(
                    centered: true,
                    label: '好友谱面',
                    value: '${result.friendTotalCharts}'),
              ),
              Expanded(
                child: StatTile(
                    centered: true,
                    label: '共同谱面',
                    value: '${result.commonCount}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _matchesResult(ChartComparisonItem item, String? filter) =>
      switch (filter) {
        'win' => item.isMyWin,
        'tie' => item.isTie,
        'lose' => item.isFriendWin,
        _ => true,
      };

  /// 胜负切换（数字随难度筛选变化）+ 难度筛选。
  Widget _buildFilters(ComparisonResult result) {
    const keys = <String?>[null, 'win', 'tie', 'lose'];
    const labels = ['全部', '我赢', '平局', '好友赢'];
    final byLevel = _filterLevelIndex == null
        ? result.commonCharts
        : result.commonCharts
            .where((c) => c.levelIndex == _filterLevelIndex)
            .toList();
    void pickLevel(int? level) => setState(() {
          _filterLevelIndex = level;
          _displayCount = _pageSize;
        });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedTabs(
          items: [
            for (var i = 0; i < keys.length; i++)
              SegmentedTabItem(
                labels[i],
                caption:
                    '${byLevel.where((c) => _matchesResult(c, keys[i])).length}',
              ),
          ],
          selectedIndex: keys.indexOf(_filterResult),
          onChanged: (i) => setState(() {
            _filterResult = keys[i];
            _displayCount = _pageSize;
          }),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              FilterPill(
                label: '全部难度',
                selected: _filterLevelIndex == null,
                onTap: () => pickLevel(null),
              ),
              for (var i = 0; i < ChartDifficulty.standardLabels.length; i++) ...[
                const SizedBox(width: 6),
                FilterPill(
                  label: ChartDifficulty.standardLabels[i],
                  selected: _filterLevelIndex == i,
                  selectedColor: ColorUtil.getCardColor(i),
                  selectedForeground:
                      ThemeData.estimateBrightnessForColor(
                                  ColorUtil.getCardColor(i)) ==
                              Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                  onTap: () => pickLevel(i),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonList(ComparisonResult result) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = result.commonCharts.where((c) {
      if (_filterLevelIndex != null && c.levelIndex != _filterLevelIndex) {
        return false;
      }
      return _matchesResult(c, _filterResult);
    }).toList();
    final total = filtered.length;
    final shown = _displayCount > total ? total : _displayCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Text(
            '按定数从高到低 · 显示 $shown / $total',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
        ),
        if (total == 0)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '没有符合条件的谱面',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
            ),
          )
        else ...[
          for (var i = 0; i < shown; i++)
            Padding(
              key: ValueKey('${filtered[i].songId}-${filtered[i].levelIndex}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: EntranceAnimation(
                index: i % _pageSize,
                offset: const Offset(0, 8),
                duration: const Duration(milliseconds: 300),
                child: _buildComparisonItem(filtered[i]),
              ),
            ),
          if (shown < total)
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _displayCount += _pageSize),
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: Text('加载更多（$shown / $total）'),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildComparisonItem(ChartComparisonItem item) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = scheme.brightness;
    final diff = item.myAchievements - item.friendAchievements;
    final diffColor = item.isTie
        ? AppColors.warningOrange(brightness)
        : item.isMyWin
            ? AppColors.successGreen(brightness)
            : AppColors.errorRed(brightness);

    Widget side(String name, double achievement, String rate, bool leading,
            CrossAxisAlignment align) =>
        Expanded(
          child: Column(
            crossAxisAlignment: align,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 11, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${achievement.toStringAsFixed(4)}%',
                  style: AppTheme.number(
                    fontSize: 15,
                    fontWeight: leading ? FontWeight.w800 : FontWeight.w500,
                    color: leading ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (rate.isNotEmpty) ...[
                const SizedBox(height: 3),
                RankBadge(rank: StringUtil.formatRate(rate), fontSize: 10.5),
              ],
            ],
          ),
        );

    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(
              songId: item.songId.toString(),
              initialLevelIndex: item.levelIndex,
              isDefaultLevelIndex: false,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                child: CoverUtil.buildCoverWidgetWithContext(
                    context, item.songId.toString(), 44),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarqueeText(
                      text: item.songTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SongTypeBadge(
                            songId: item.songId.toString(), type: item.type),
                        const SizedBox(width: 4),
                        ChartDifficultyBadge(
                          levelIndex: item.levelIndex,
                          songId: item.songId.toString(),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.ds.toStringAsFixed(1),
                          style: AppTheme.number(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: Row(
              children: [
                side('我', item.myAchievements, item.myRate,
                    item.isMyWin || item.isTie, CrossAxisAlignment.start),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: diffColor.withValues(alpha: 0.14),
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusPill),
                  ),
                  child: Text(
                    item.isTie
                        ? '平局'
                        : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(4)}%',
                    style: AppTheme.number(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                ),
                side('好友', item.friendAchievements, item.friendRate,
                    item.isFriendWin || item.isTie, CrossAxisAlignment.end),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
