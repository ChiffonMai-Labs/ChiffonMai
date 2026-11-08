import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import '../service/UserScoreSearchService.dart';
import '../manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'SongInfoPage.dart';
import '../utils/CoverUtil.dart';
import 'package:my_first_flutter_app/constant/VersionListConstant.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import '../widgets/AppUi.dart';
import '../widgets/GuessSettingsUi.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/MarqueeText.dart';
import '../widgets/AppDialogs.dart';

class UserScoreSearchPage extends StatefulWidget {
  /// 进入页面时直接打开搜索框（成绩 Hub 的搜索入口）。
  final bool openSearch;

  const UserScoreSearchPage({super.key, this.openSearch = false});

  @override
  State<UserScoreSearchPage> createState() => _UserScoreSearchPageState();
}

class _UserScoreSearchPageState extends State<UserScoreSearchPage> {
  final UserScoreSearchService _service = UserScoreSearchService();

  Map<String, dynamic>? _userPlayData;
  List<dynamic> _sortedSongs = [];
  List<dynamic> _pagedSongs = [];
  bool _isLoading = true;

  /// 分布卡片当前显示：0 = 评级，1 = 星数，2 = 连击，3 = 同步。
  int _distributionMode = 0;

  /// 点分布条选中的档位（下标对应 [_distributionLabels]），null = 不筛。
  int? _bucketFilter;
  static const List<String> _rankBuckets = ['SSS+', 'SSS', 'SS+', 'SS', 'S+以下'];
  static const List<String> _starBuckets = ['✦5', '✦4', '✦3', '✦2', '✦1', '✦0'];

  /// 连击和同步的每种评价单独一档，字段值与筛选用的是同一份。
  static const List<String> _comboBuckets = ['AP+', 'AP', 'FC+', 'FC', '无连击'];
  static const List<String> _syncBuckets = [
    'FDX+',
    'FDX',
    'FS+',
    'FS',
    'SYNC',
    '无同步',
  ];

  List<String> get _distributionLabels => switch (_distributionMode) {
        0 => _rankBuckets,
        1 => _starBuckets,
        2 => _comboBuckets,
        _ => _syncBuckets,
      };

  int _bucketOf(dynamic song) => switch (_distributionMode) {
        0 => _rankBucketOf(song),
        1 => _starBucketOf(song),
        2 => _evaluationBucketOf(song['fc'], _comboBuckets,
            UserScoreSearchService.comboFilterValues),
        _ => _evaluationBucketOf(
            song['fs'], _syncBuckets, UserScoreSearchService.syncFilterValues),
      };

  /// 没有评价或是没见过的值都算进最后一档（无评价）。
  static int _evaluationBucketOf(
      dynamic value, List<String> buckets, Map<String, String> values) {
    final code = value?.toString().toLowerCase() ?? '';
    final index = buckets.indexWhere((bucket) => values[bucket] == code);
    return index < 0 ? buckets.length - 1 : index;
  }

  /// 曲名 / 定数搜索。
  late bool _searchOpen = widget.openSearch;
  String _searchQuery = '';

  int _rankBucketOf(dynamic song) {
    final a = double.tryParse(song['achievements']?.toString() ?? '0') ?? 0;
    if (a >= 100.5) return 0;
    if (a >= 100) return 1;
    if (a >= 99.5) return 2;
    if (a >= 99) return 3;
    return 4;
  }

  /// 星数档位（✦5 含更高的 ✦5.5 / ✦6）。
  int _starBucketOf(dynamic song) {
    if (!song.containsKey('dxScore')) return 5;
    final rate = _dxRateCache[song] ??= _calculateDXScoreRate(song);
    if (rate >= 0.97) return 0;
    if (rate >= 0.95) return 1;
    if (rate >= 0.93) return 2;
    if (rate >= 0.90) return 3;
    if (rate >= 0.85) return 4;
    return 5;
  }

  bool _matchesSearch(dynamic song) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return (song['title']?.toString() ?? '').toLowerCase().contains(q) ||
        (song['ds']?.toString() ?? '').startsWith(q) ||
        (song['song_id']?.toString() ?? '') == q;
  }

  /// 通过搜索后的成绩（评级分布的统计口径）。
  List<dynamic> get _searchedSongs =>
      _searchedCache ??= _sortedSongs.where(_matchesSearch).toList();
  List<dynamic>? _searchedCache;

  /// 各分布的档位计数（键是分布序号）。切换分布只读这里，来回切不用重新统计。
  final Map<int, List<int>> _distributionCounts = {};

  /// 成绩或搜索词变化后调用，下次用到时再重新计算。
  void _invalidateSongCaches() {
    _searchedCache = null;
    _visibleCache = null;
    _distributionCounts.clear();
  }

  /// 最终显示的成绩（再叠加分布条选中的档位）。
  List<dynamic> get _visibleSongs {
    final bucket = _bucketFilter;
    if (bucket == null) return _searchedSongs;
    return _visibleCache ??=
        _searchedSongs.where((s) => _bucketOf(s) == bucket).toList();
  }

  List<dynamic>? _visibleCache;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  int _pageSize = 50;
  final TextEditingController _pageSizeController =
      TextEditingController(text: '50');

  // 当前选中的按钮索引
  int _selectedButtonIndex = 0;

  // 缓存DX分数达成率，避免重复计算
  Map<dynamic, double> _dxRateCache = {};

  // 当前排序方式
  String _currentSortBy = 'Rating'; // 默认选择Rating

  // 显示模式：true为曲绘模式，false为列表模式
  bool _isCoverMode = false;

  // 筛选条件：每项都可多选，空列表表示全部
  final Map<String, List<String>> _filterConditions = {
    '版本筛选': [],
    '定数筛选': [],
    '难度筛选': [],
    '达成率筛选': [],
    '连击/同步筛选': [],
  };

  static const List<({String label, String range})> _achievementOptions = [
    (label: 'SSS+', range: '100.5-101'),
    (label: 'SSS', range: '100-100.4999'),
    (label: 'SS+', range: '99.5-99.9999'),
    (label: 'SS', range: '99-99.4999'),
    (label: 'S+', range: '98.0-98.9999'),
    (label: 'S', range: '97-97.9999'),
    (label: 'AAA', range: '94-96.9999'),
    (label: 'AA', range: '90-93.9999'),
    (label: 'A', range: '80-89.9999'),
  ];

  // 版本列表
  static List<String> _versionList = VersionListConstant.versionOrderList;

  // 处理版本字符串，使其在前端简化展示
  static String _formatVersion(String version) {
    return StringUtil.formatVersion2(version);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 初始化按钮尺寸变量

  int _loadRequest = 0;

  /// [silent] 用于筛选和排序变化：不换成整页转圈，分布卡片留在原地，
  /// 数字和分布条才能从旧值过渡到新值。
  Future<void> _loadData({bool silent = false}) async {
    final request = ++_loadRequest;
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final playData = await _service.getUserPlayData();
      if (playData != null) {
        // 初始化歌曲缓存，确保星数计算时缓存可用
        await _service.initSongCache();
        var songs = await _service.getSortedSongs(playData, _currentSortBy);
        // 应用筛选条件
        songs = await _service.filterSongs(songs, _filterConditions);
        // 连续改筛选时只认最新一次
        if (request != _loadRequest) return;
        _dxRateCache.clear();
        _sortedSongs = songs;
        _invalidateSongCaches();
      }
      if (request != _loadRequest) return;
      _userPlayData = playData;
      _updatePagedSongs();
    } catch (e) {
      debugPrint('加载数据出错: $e');
    }
    if (mounted && request == _loadRequest) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 显示排序方式对话框
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowChooseSortOrder),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text('Rating'),
                    value: 'Rating',
                    groupValue: _currentSortBy,
                    onChanged: (value) {
                      setState(() {
                        _currentSortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(context.l10n.flowAchievement2),
                    value: '达成率',
                    groupValue: _currentSortBy,
                    onChanged: (value) {
                      setState(() {
                        _currentSortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(context.l10n.flowConstant),
                    value: '定数',
                    groupValue: _currentSortBy,
                    onChanged: (value) {
                      setState(() {
                        _currentSortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(context.l10n.flowDXScoreRate),
                    value: 'DX分数达成率',
                    groupValue: _currentSortBy,
                    onChanged: (value) {
                      setState(() {
                        _currentSortBy = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.featureCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(context.l10n.flowConfirm),
              onPressed: () {
                Navigator.of(context).pop();
                _loadData(silent: true); // 重新加载数据
              },
            ),
          ],
        );
      },
    );
  }

  /// 应用一项筛选；对话框取消时返回 null，不做任何事。
  void _applyFilter(String key, List<String>? values) {
    if (values == null || !mounted) return;
    setState(() {
      _filterConditions[key] = values;
      _currentPage = 1; // 筛选条件变化时，切换到第1页
    });
    _loadData(silent: true); // 重新加载数据
  }

  /// 筛选胶囊上显示的已选内容。
  String? _filterSummary(String key, String Function(String) label) {
    final values = _filterConditions[key]!;
    return values.isEmpty ? null : values.map(label).join('、');
  }

  // 显示版本筛选对话框
  Future<void> _showVersionFilterDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _ChoiceFilterDialog(
        title: context.l10n.flowVersionFilter,
        initial: _filterConditions[context.l10n.flowVersionFilter]!,
        groups: [
          _ChoiceGroup(items: [
            for (final version in _versionList)
              _Choice(version, _formatVersion(version)),
          ]),
        ],
      ),
    );
    _applyFilter(context.l10n.flowVersionFilter, result);
  }

  // 根据定数计算等级显示（x或x+）
  String _getLevelDisplay(double ds) {
    if (ds >= 15.0) {
      return '15';
    }
    int integerPart = ds.floor();
    double decimalPart = ds - integerPart;
    if (decimalPart <= 0.5) {
      return '$integerPart';
    } else {
      return '${integerPart}+';
    }
  }

  // 获取等级选项（参考 PersonalizedScoreService.getAllLevelOptions）
  Future<List<String>> _getLevelOptions() async {
    final musicManager = MaimaiMusicDataManager();
    final songs = await musicManager.getCachedSongs();

    Set<String> levels = {};
    if (songs != null) {
      for (final song in songs) {
        if (song.id.length == 6 && int.tryParse(song.id) != null) {
          continue;
        }
        for (final ds in song.ds) {
          if (ds <= 0) continue;
          levels.add(_getLevelDisplay(ds));
        }
      }
    }

    if (levels.isEmpty) {
      for (int i = 1; i <= 14; i++) {
        levels.add('$i');
        levels.add('${i}+');
      }
      levels.add('15');
    }

    return levels.toList()
      ..sort((a, b) {
        double parseLevel(String level) {
          if (level == '15') return 15.0;
          if (level.endsWith('+')) {
            return double.parse(level.substring(0, level.length - 1)) + 0.5;
          }
          return double.tryParse(level) ?? 0.0;
        }

        return parseLevel(b).compareTo(parseLevel(a));
      });
  }

  /// 定数范围对应的等级名（14.0-14.5 → 14，14.6-14.9 → 14+），自定义范围原样显示。
  static String _dsRangeLabel(String range) {
    if (range == '15.0-15.0') return '15';
    final match = RegExp(r'^(\d+)\.(0|6)-(\d+)\.(5|9)$').firstMatch(range);
    if (match == null || match.group(1) != match.group(3)) return range;
    if (match.group(2) == '0' && match.group(4) == '5') return match.group(1)!;
    if (match.group(2) == '6' && match.group(4) == '9')
      return '${match.group(1)}+';
    return range;
  }

  static String _achievementRangeLabel(String range) {
    for (final option in _achievementOptions) {
      if (option.range == range) return option.label;
    }
    return range;
  }

  // 显示定数筛选对话框
  Future<void> _showDsFilterDialog() async {
    final levels = await _getLevelOptions();
    if (!mounted) return;
    final options = [
      for (final level in levels)
        () {
          final String range;
          if (level == '15') {
            range = '15.0-15.0';
          } else if (level.endsWith('+')) {
            final base = level.substring(0, level.length - 1);
            range = '$base.6-$base.9';
          } else {
            range = '$level.0-$level.5';
          }
          return (label: level, range: range);
        }(),
    ];
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _RangeFilterDialog(
        title: context.l10n.flowConstantFilter,
        options: options,
        initial: _filterConditions['定数筛选']!,
        minHint: '1.0',
        maxHint: '15.0',
        hint: context.l10n.flowUpToOneDecimalPlaceLeaveBlank,
      ),
    );
    _applyFilter('定数筛选', result);
  }

  // 显示难度筛选对话框
  Future<void> _showDifficultyFilterDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _ChoiceFilterDialog(
        title: context.l10n.flowDifficultyFilter,
        initial: _filterConditions['难度筛选']!,
        groups: [
          _ChoiceGroup(items: [
            for (final label in ChartDifficulty.labels)
              _Choice(
                label,
                label,
                color: ChartDifficulty.standardIndexByLabel[label] == null
                    ? AppColors.utageAccent(
                        brightness: Theme.of(context).brightness)
                    : ColorUtil.getCardColor(
                        ChartDifficulty.standardIndexByLabel[label]!),
              ),
          ]),
        ],
      ),
    );
    _applyFilter('难度筛选', result);
  }

  // 显示达成率筛选对话框
  Future<void> _showAchievementFilterDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _RangeFilterDialog(
        title: context.l10n.flowAchievementFilter,
        options: _achievementOptions,
        initial: _filterConditions['达成率筛选']!,
        minHint: '0',
        maxHint: '101',
        hint: context.l10n.flowUpToFourDecimalPlacesLeaveBlank,
      ),
    );
    _applyFilter('达成率筛选', result);
  }

  // 显示连击/同步筛选对话框
  Future<void> _showComboFilterDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _ChoiceFilterDialog(
        title: context.l10n.flowComboSyncFilter,
        subtitle: context.l10n.flowAnyOptionWithinAGroupMatchesWhen,
        initial: _filterConditions['连击/同步筛选']!,
        groups: [
          _ChoiceGroup(title: context.l10n.flowCombo, items: [
            for (final item in UserScoreSearchService.comboFilterValues.keys)
              _Choice(item, item),
          ]),
          _ChoiceGroup(title: context.l10n.flowSync, items: [
            for (final item in UserScoreSearchService.syncFilterValues.keys)
              _Choice(item, item),
          ]),
        ],
      ),
    );
    _applyFilter('连击/同步筛选', result);
  }

  void _updatePagedSongs() {
    _pagedSongs =
        _service.getPagedSongs(_visibleSongs, _currentPage, _pageSize);
  }

  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      _updatePagedSongs();
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _changePageSize() {
    int newPageSize = int.tryParse(_pageSizeController.text) ?? 50;
    if (newPageSize > 0) {
      setState(() {
        _pageSize = newPageSize;
        _currentPage = 1;
        _updatePagedSongs();
      });
    }
  }

  int _getTotalPages() {
    final count = _visibleSongs.length;
    return count == 0 ? 1 : (count / _pageSize).ceil();
  }

  // 使用UserScoreSearchService中的方法计算DX分数达成率
  double _calculateDXScoreRate(dynamic record) {
    return _service.calculateDXScoreRateSync(record);
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.featureScoreLookup,
      resizeToAvoidBottomInset: false, // 防止键盘弹出时调整布局
      actions: [
        IconButton(
          tooltip: _searchOpen
              ? context.l10n.flowCloseSearch
              : context.l10n.flowSearchSongTitleOrConstant,
          onPressed: () => setState(() {
            _searchOpen = !_searchOpen;
            if (!_searchOpen) _setSearchQuery('');
          }),
          icon: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Material(
            color: AppSurfaces.card(context),
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _showSortDialog,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(context.featureText(_currentSortBy),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userPlayData == null
              ? Center(
                  child: Text(context.l10n.flowNoCachedDataFound,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                            AppDesignTokens.gutter,
                            4,
                            AppDesignTokens.gutter,
                            AppDesignTokens.gutter),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_searchOpen) ...[
                              _buildSearchField(),
                              const SizedBox(height: AppDesignTokens.cardGap),
                            ],
                            _buildDistributionCard(),
                            const SizedBox(height: AppDesignTokens.cardGap),
                            _buildFilterRow(),
                            const SizedBox(height: AppDesignTokens.cardGap),
                            if (_isCoverMode) ...[
                              SegmentedTabs(
                                height: 40,
                                items: [
                                  SegmentedTabItem(context.l10n.flowGrade),
                                  SegmentedTabItem(context.l10n.flowCombo),
                                  SegmentedTabItem(context.l10n.flowSync),
                                  SegmentedTabItem(context.l10n.flowScore),
                                  SegmentedTabItem(context.l10n.flowStars),
                                  SegmentedTabItem(context.l10n.flowConstant),
                                ],
                                selectedIndex: _selectedButtonIndex,
                                onChanged: (i) =>
                                    setState(() => _selectedButtonIndex = i),
                              ),
                              const SizedBox(height: AppDesignTokens.cardGap),
                              ConstrainedBox(
                                // 设置最小高度确保内容显示
                                constraints:
                                    const BoxConstraints(minHeight: 300),
                                child: _buildCoverGrid(),
                              ),
                            ] else
                              _buildListGrid(),
                            const SizedBox(height: AppDesignTokens.cardGap),
                            _buildPageSizeRow(),
                          ],
                        ),
                      ),
                    ),
                    _buildPaginationBar(),
                  ],
                ),
    );
  }

  void _setSearchQuery(String query) {
    _searchQuery = query;
    _invalidateSongCaches();
    _currentPage = 1;
    _updatePagedSongs();
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: widget.openSearch,
      onChanged: (value) => setState(() => _setSearchQuery(value)),
      decoration: InputDecoration(
        hintText: context.l10n.featureFindScoresTitleConstantOrSongID,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        fillColor: AppSurfaces.card(context),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // 评级 / 星数 / 连击 / 同步分布：色块宽度 = 数量，点色块或下方数字按该档筛选
  Widget _buildDistributionCard() {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final songs = _searchedSongs;
    final labels = _distributionLabels;
    final filter = _bucketFilter;
    final counts = _distributionCounts.putIfAbsent(_distributionMode, () {
      final result = List<int>.filled(labels.length, 0);
      for (final s in songs) {
        result[_bucketOf(s)]++;
      }
      return result;
    });
    Color colorOf(int i) => switch (_distributionMode) {
          0 => AppColors.rankDistribution(i, brightness),
          1 => AppColors.starDistribution(i, brightness),
          2 => AppColors.comboDistribution(i, brightness),
          _ => AppColors.syncDistribution(i, brightness),
        };
    void pick(int i) => setState(() {
          _bucketFilter = filter == i ? null : i;
          _visibleCache = null;
          _currentPage = 1;
          _updatePagedSongs();
        });
    double opacityOf(int i) => filter == null || filter == i ? 1 : 0.3;
    final hintStyle = TextStyle(fontSize: 12, color: scheme.onSurfaceVariant);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabs(
            height: 38,
            items: [
              SegmentedTabItem(context.l10n.flowGrade),
              SegmentedTabItem(context.l10n.flowStars),
              SegmentedTabItem(context.l10n.flowCombo),
              SegmentedTabItem(context.l10n.flowSync),
            ],
            selectedIndex: _distributionMode,
            onChanged: (mode) {
              if (mode == _distributionMode) return;
              setState(() {
                _distributionMode = mode;
                // 切分布只换这张卡片。选中过档位时才影响歌曲列表：
                // 筛选跟着分布走，切走后不留一个看不见的筛选条件
                if (filter != null) {
                  _bucketFilter = null;
                  _visibleCache = null;
                  _currentPage = 1;
                  _updatePagedSongs();
                }
              });
            },
          ),
          const SizedBox(height: 10),
          FadeSwitcher(
            value: filter == null ? '' : labels[filter],
            child: filter == null
                ? Row(
                    children: [
                      Text(context.l10n.flowTapASegmentOrStatisticToFilter,
                          style: hintStyle),
                      RollingNumber(value: songs.length, style: hintStyle),
                      Text(context.l10n.flowEntries, style: hintStyle),
                    ],
                  )
                : Text(
                    context.l10n.flowFilteredByP0TapAgainToClear(
                        context.featureText(labels[filter])),
                    style: hintStyle),
          ),
          const SizedBox(height: 10),
          _buildDistributionBar(counts, labels, colorOf, opacityOf, pick),
          const SizedBox(height: 10),
          FadeSwitcher(
            value: _distributionMode,
            child: Row(
              children: [
                for (var i = 0; i < counts.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => pick(i),
                      child: AnimatedOpacity(
                        opacity: opacityOf(i),
                        duration: AppDesignTokens.motion(
                            context, AppDesignTokens.fastMotion),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 行高固定：中文和英文字母的字体行高不同，
                            // 否则下方的数字会高低不齐
                            SizedBox(
                              height: 16,
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorOf(i),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                          context.featureText(labels[i]),
                                          maxLines: 1,
                                          style: AppTheme.number(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onSurfaceVariant)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: RollingNumber(
                                value: counts[i],
                                style: AppTheme.number(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface),
                              ),
                            ),
                          ],
                        ),
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

  /// 分布条。始终摆满最多档位的格子数：切换分布或筛选变化时同一格的位置、宽度和颜色
  /// 一起过渡，看起来是色块变形成另一组；没有成绩的格子宽度为 0。
  Widget _buildDistributionBar(
    List<int> counts,
    List<String> labels,
    Color Function(int) colorOf,
    double Function(int) opacityOf,
    void Function(int) pick,
  ) {
    final motion =
        AppDesignTokens.motion(context, AppDesignTokens.mediumMotion);
    final curve = AppDesignTokens.emphasizedCurve;
    return SizedBox(
      height: 14,
      child: LayoutBuilder(builder: (context, constraints) {
        final widths = stackedBarWidths(counts, constraints.maxWidth,
            gap: _distributionBarGap);
        var left = 0.0;
        return Stack(
          children: [
            for (var i = 0; i < _maxDistributionBuckets; i++)
              () {
                final exists = i < counts.length;
                final width = exists ? widths[i] : 0.0;
                final position = left;
                if (width > 0) left += width + _distributionBarGap;
                return AnimatedPositioned(
                  key: ValueKey(i),
                  duration: motion,
                  curve: curve,
                  left: position,
                  top: 0,
                  bottom: 0,
                  width: width,
                  child: Semantics(
                    button: width > 0,
                    label: width > 0
                        ? context.l10n.flowP0P1EntriesTapToFilter(
                            context.featureText(labels[i]),
                            (counts[i]).toString())
                        : null,
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: width > 0 ? () => pick(i) : null,
                      child: AnimatedOpacity(
                        opacity: width > 0 && exists ? opacityOf(i) : 0,
                        duration: motion,
                        child: AnimatedContainer(
                          duration: motion,
                          curve: curve,
                          decoration: BoxDecoration(
                            // 收起的格子保持原色淡出，不闪成别的颜色
                            color: colorOf(exists ? i : counts.length - 1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }(),
          ],
        );
      }),
    );
  }

  static const double _distributionBarGap = 3;
  static const int _maxDistributionBuckets = 6;

  // 横向滑动的筛选胶囊
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          FilterPill(
            label: context.l10n.flowVersion,
            value: _filterSummary('版本筛选', _formatVersion),
            onTap: _showVersionFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: context.l10n.flowConstant,
            value: _filterSummary('定数筛选', _dsRangeLabel),
            onTap: _showDsFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: context.l10n.flowDifficulty,
            value: _filterSummary('难度筛选', (value) => value),
            onTap: _showDifficultyFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: context.l10n.flowAchievement2,
            value: _filterSummary('达成率筛选', _achievementRangeLabel),
            onTap: _showAchievementFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: context.l10n.flowComboSync,
            value: _filterSummary('连击/同步筛选', (value) => value),
            onTap: _showComboFilterDialog,
          ),
        ],
      ),
    );
  }

  // 每页数量
  Widget _buildPageSizeRow() {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(context.l10n.flowPerPage,
            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          height: 36,
          child: TextField(
            controller: _pageSizeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _changePageSize(),
            style: AppTheme.number(fontSize: 14),
            decoration: InputDecoration(
              fillColor: AppSurfaces.card(context),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const Spacer(),
        Text(context.l10n.flowP0Entries((_visibleSongs.length).toString()),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ],
    );
  }

  // 固定在底部的分页栏
  Widget _buildPaginationBar() {
    final scheme = Theme.of(context).colorScheme;
    final total = _getTotalPages();
    return BottomActionBar(
      children: [
        IconButton.filledTonal(
          tooltip: context.l10n.flowPrevious,
          onPressed:
              _currentPage > 1 ? () => _changePage(_currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Center(
            child: Text(
              '$_currentPage / $total',
              style: AppTheme.number(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: context.l10n.flowNext,
          onPressed:
              _currentPage < total ? () => _changePage(_currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _isCoverMode = !_isCoverMode),
          icon: Icon(_isCoverMode
              ? Icons.grid_view_rounded
              : Icons.view_agenda_outlined),
          label: Text(
              _isCoverMode ? context.l10n.flowCoverArt : context.l10n.flowList),
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDesignTokens.radiusSmall)),
          ),
        ),
      ],
    );
  }

  // 构建曲绘网格（5列）
  Widget _buildCoverGrid() {
    double screenWidth = MediaQuery.of(context).size.width;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(2),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: _pagedSongs.length,
      itemBuilder: (context, index) {
        final song = _pagedSongs[index];
        final levelIndex = song['level_index'] ?? 0;
        var borderColor = _service.getBorderColor(levelIndex);

        final songId = song['song_id']?.toString() ?? '';
        if (songId.length == 6 && int.tryParse(songId) != null) {
          borderColor = Color(0xFFFF69B4);
        }

        final itemSize = (screenWidth - 4 - (4 * 2)) / 5;

        String displayText = '';
        String displaySubText = '';
        Color displayColor = Colors.white;

        switch (_selectedButtonIndex) {
          case 0: // 评级
            if (song.containsKey('achievements')) {
              double achievements =
                  double.tryParse(song['achievements'].toString()) ?? 0;
              if (achievements >= 100.5) {
                displayText = 'SSS+';
                displayColor = Colors.yellow;
              } else if (achievements >= 100.0) {
                displayText = 'SSS';
                displayColor = Colors.yellow;
              } else if (achievements >= 99.5) {
                displayText = 'SS+';
                displayColor = Colors.orange;
              } else if (achievements >= 99.0) {
                displayText = 'SS';
                displayColor = Colors.orange;
              } else if (achievements >= 98.0) {
                displayText = 'S+';
                displayColor = Colors.orange;
              } else if (achievements >= 97.0) {
                displayText = 'S';
                displayColor = Colors.orange;
              } else if (achievements >= 94.0) {
                displayText = 'AAA';
                displayColor = Colors.red;
              } else if (achievements >= 90.0) {
                displayText = 'AA';
                displayColor = Colors.red;
              } else if (achievements >= 80.0) {
                displayText = 'A';
                displayColor = Colors.red;
              } else if (achievements >= 75.0) {
                displayText = 'BBB';
                displayColor = Colors.blue;
              } else if (achievements >= 70.0) {
                displayText = 'BB';
                displayColor = Colors.blue;
              } else if (achievements >= 60.0) {
                displayText = 'B';
                displayColor = Colors.blue;
              } else if (achievements >= 50.0) {
                displayText = 'C';
                displayColor = Colors.grey;
              } else {
                displayText = 'D';
                displayColor = Colors.grey;
              }
            }
            break;
          case 1: // 连击
            if (song.containsKey('fc')) {
              String fc = song['fc'].toString().toLowerCase();
              if (fc == 'app') {
                displayText = 'AP+';
                displayColor = Colors.yellow;
              } else if (fc == 'ap') {
                displayText = 'AP';
                displayColor = Colors.orange;
              } else if (fc == 'fcp') {
                displayText = 'FC+';
                displayColor = Colors.green;
              } else if (fc == 'fc') {
                displayText = 'FC';
                displayColor = Colors.blue;
              }
            }
            break;
          case 2: // 同步
            if (song.containsKey('fs')) {
              String fs = song['fs'].toString().toLowerCase();
              if (fs == 'fsdp') {
                displayText = 'FDX+';
                displayColor = Colors.yellow;
              } else if (fs == 'fsd') {
                displayText = 'FDX';
                displayColor = Colors.orange;
              } else if (fs == 'fsp') {
                displayText = 'FS+';
                displayColor = Colors.green;
              } else if (fs == 'fs') {
                displayText = 'FS';
                displayColor = Colors.blue;
              }
            }
            break;
          case 3: // 得分
            if (song.containsKey('ra')) {
              displayText = song['ra'].toString();
              displayColor = Colors.white;
            }
            break;
          case 4: // 星数
            if (song.containsKey('dxScore')) {
              double rate = 0.0;
              if (_dxRateCache.containsKey(song)) {
                rate = _dxRateCache[song]!;
              } else {
                rate = _calculateDXScoreRate(song);
                _dxRateCache[song] = rate;
              }

              String stars = '';
              if (rate >= 0.99) {
                stars = '\u2726 6';
                displayColor = Colors.yellow;
              } else if (rate >= 0.98) {
                stars = '\u2726 5.5';
                displayColor = Colors.yellow;
              } else if (rate >= 0.97) {
                stars = '\u2726 5';
                displayColor = Colors.yellow;
              } else if (rate >= 0.95) {
                stars = '\u2726 4';
                displayColor = Colors.orange;
              } else if (rate >= 0.93) {
                stars = '\u2726 3';
                displayColor = Colors.orange;
              } else if (rate >= 0.90) {
                stars = '\u2726 2';
                displayColor = Colors.green.shade200;
              } else if (rate >= 0.85) {
                stars = '\u2726 1';
                displayColor = Colors.green.shade200;
              } else {
                stars = '\u2726 0';
                displayColor = Colors.grey.shade300;
              }

              displayText = stars;
              displaySubText = '${(rate * 100).toStringAsFixed(2)}%';
            }
            break;
          case 5: // 定数
            if (song.containsKey('ds')) {
              displayText = song['ds'].toString();
              displayColor = Colors.white;
            }
            break;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongInfoPage(
                  songId: song['song_id'].toString(),
                  initialLevelIndex:
                      ChartDifficulty.parseStandardIndex(song['level_index']),
                ),
              ),
            );
          },
          child: Container(
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: Color(borderColor.value),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              color: Color(borderColor.value).withOpacity(0.3),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverUtil.buildCoverWidgetWithContextRRect(context,
                    song['song_id']?.toString() ?? '', double.infinity),
                if (displayText.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: _selectedButtonIndex == 4
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  displayText,
                                  style: TextStyle(
                                    color: displayColor,
                                    fontSize: itemSize * 0.18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (displaySubText.isNotEmpty)
                                  Text(
                                    displaySubText,
                                    style: TextStyle(
                                      color: displayColor,
                                      fontSize: itemSize * 0.15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            )
                          : Text(
                              displayText,
                              style: TextStyle(
                                color: displayColor,
                                fontSize: itemSize * 0.2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 构建列表网格（2列）
  Widget _buildListGrid() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        // 换页、筛选、排序后重播入场动画
        key: ValueKey(
            '$_currentPage-$_bucketFilter-$_currentSortBy-$_searchQuery'),
        children: [
          for (var i = 0; i < _pagedSongs.length; i++)
            EntranceAnimation(
              index: i,
              stagger: const Duration(milliseconds: 25),
              duration: const Duration(milliseconds: 300),
              offset: const Offset(0, 8),
              child: _buildListRow(_pagedSongs[i], showDivider: i > 0),
            ),
        ],
      ),
    );
  }

  Widget _buildListRow(dynamic song, {required bool showDivider}) {
    final scheme = Theme.of(context).colorScheme;
    final int songId = int.tryParse(song['song_id']?.toString() ?? '0') ?? 0;
    final int levelIndex = song['level_index'] ?? 0;
    final double difficulty =
        double.tryParse(song['ds']?.toString() ?? '0') ?? 0;
    final double achievement =
        double.tryParse(song['achievements']?.toString() ?? '0') ?? 0;
    final String fc = song['fc']?.toString() ?? '';
    final String fs = song['fs']?.toString() ?? '';

    // 取 DX 分达成率（同步缓存）与对应的星级显示
    double rateValue;
    if (_dxRateCache.containsKey(song)) {
      rateValue = _dxRateCache[song]!;
    } else {
      rateValue = _calculateDXScoreRate(song);
      _dxRateCache[song] = rateValue;
    }
    final stars = StringUtil.formatStars(rateValue);
    final rank = StringUtil.rateCodeFromAchievement(achievement)
        .toUpperCase()
        .replaceFirst('P', '+');
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongInfoPage(
            songId: songId.toString(),
            initialLevelIndex:
                ChartDifficulty.parseStandardIndex(song['level_index']),
          ),
        ),
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
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                    child: CoverUtil.buildCoverWidgetWithContext(
                        context, songId.toString(), 48),
                  ),
                  Positioned(
                    right: -3,
                    bottom: -3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: songId.toString().length == 6
                            ? AppColors.utageCard()
                            : ColorUtil.getCardColor(levelIndex),
                        border: Border.all(
                            color: AppSurfaces.card(context), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SongTypeBadge(
                        songId: songId.toString(),
                        type: song['type']?.toString().toUpperCase() == 'DX'
                            ? 'DX'
                            : 'SD',
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: MarqueeText(
                          text: song['title']?.toString() ??
                              context.l10n.flowUnknownSong,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text('${achievement.toStringAsFixed(4)}%',
                            style: AppTheme.number(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface)),
                        const SizedBox(width: 6),
                        RankBadge(rank: rank, fontSize: 10),
                        if (fc.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          ComboLabelBadge(raw: fc, fontSize: 10),
                        ],
                        if (fs.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          ComboLabelBadge(raw: fs, fontSize: 10),
                        ],
                        const SizedBox(width: 4),
                        StarBadge(stars: stars, fontSize: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${song['ra'] ?? 0}',
                    style: AppTheme.number(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
                Text(
                    context.l10n.flowConstantP0(
                        (difficulty.toStringAsFixed(1)).toString()),
                    style: AppTheme.number(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice {
  final String value;
  final String label;
  final Color? color;

  const _Choice(this.value, this.label, {this.color});
}

class _ChoiceGroup {
  final String? title;
  final List<_Choice> items;

  const _ChoiceGroup({this.title, required this.items});
}

/// 多选筛选对话框：点选胶囊，「全部」清空。确认时返回选中的值，取消返回 null。
class _ChoiceFilterDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<_ChoiceGroup> groups;
  final List<String> initial;

  const _ChoiceFilterDialog({
    required this.title,
    required this.groups,
    required this.initial,
    this.subtitle,
  });

  @override
  State<_ChoiceFilterDialog> createState() => _ChoiceFilterDialogState();
}

class _ChoiceFilterDialogState extends State<_ChoiceFilterDialog> {
  late final Set<String> _selected = widget.initial.toSet();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppAlertDialog(
      title: Text(widget.title),
      subtitle: widget.subtitle ??
          context.l10n.flowSelectMultipleAnySelectedOptionMatches,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GuessChoicePill(
            label: context.l10n.flowAll,
            selected: _selected.isEmpty,
            onTap: () => setState(_selected.clear),
          ),
          for (final group in widget.groups) ...[
            const SizedBox(height: 12),
            if (group.title != null) ...[
              Text(
                group.title!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in group.items)
                  GuessChoicePill(
                    label: item.label,
                    selected: _selected.contains(item.value),
                    selectedColor: item.color,
                    selectedForeground: item.color == null
                        ? null
                        : ThemeData.estimateBrightnessForColor(item.color!) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                    onTap: () => setState(() {
                      if (!_selected.remove(item.value)) {
                        _selected.add(item.value);
                      }
                    }),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
        TextButton(
          onPressed: () {
            // 按选项顺序返回，胶囊上的摘要不随点选顺序跳动
            Navigator.of(context).pop([
              for (final group in widget.groups)
                for (final item in group.items)
                  if (_selected.contains(item.value)) item.value,
            ]);
          },
          child: Text(context.l10n.flowConfirm),
        ),
      ],
    );
  }
}

/// 范围筛选对话框：快捷档可多选，另可填一个自定义范围，选中的范围取并集。
/// 输入框控制器由这里持有，退出动画期间不会被提前释放。
class _RangeFilterDialog extends StatefulWidget {
  final String title;
  final List<({String label, String range})> options;
  final List<String> initial;
  final String minHint;
  final String maxHint;
  final String hint;

  const _RangeFilterDialog({
    required this.title,
    required this.options,
    required this.initial,
    required this.minHint,
    required this.maxHint,
    required this.hint,
  });

  @override
  State<_RangeFilterDialog> createState() => _RangeFilterDialogState();
}

class _RangeFilterDialogState extends State<_RangeFilterDialog> {
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final known = widget.options.map((option) => option.range).toSet();
    _selected = widget.initial.where(known.contains).toSet();
    for (final range in widget.initial) {
      if (known.contains(range)) continue;
      final parts = range.split('-');
      if (parts.length == 2) {
        _minController.text = parts[0];
        _maxController.text = parts[1];
      }
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController controller, String label, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: context.l10n.flowClearP0((label).toString()),
                icon: const Icon(Icons.clear),
                onPressed: () => setState(controller.clear),
              ),
      ).insetLabel(context),
    );
  }

  void _confirm() {
    var min = _minController.text.trim();
    var max = _maxController.text.trim();
    final minValue = double.tryParse(min);
    final maxValue = double.tryParse(max);
    // 上下界填反时自动对调
    if (minValue != null && maxValue != null && minValue > maxValue) {
      (min, max) = (max, min);
    }
    Navigator.of(context).pop([
      for (final option in widget.options)
        if (_selected.contains(option.range)) option.range,
      if (min.isNotEmpty || max.isNotEmpty) '$min-$max',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final heading = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: scheme.onSurface,
    );
    return AppAlertDialog(
      title: Text(widget.title),
      subtitle: context.l10n.flowSelectMultipleAnySelectedOptionMatches,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.flowQuickOptions, style: heading),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in widget.options)
                GuessChoicePill(
                  label: option.label,
                  selected: _selected.contains(option.range),
                  onTap: () => setState(() {
                    if (!_selected.remove(option.range)) {
                      _selected.add(option.range);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(context.l10n.flowCustomRange, style: heading),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _field(_minController, context.l10n.flowLowerBound,
                      widget.minHint)),
              const SizedBox(width: 12),
              Expanded(
                  child: _field(_maxController, context.l10n.flowUpperBound,
                      widget.maxHint)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.hint,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
        TextButton(onPressed: _confirm, child: Text(context.l10n.flowConfirm)),
      ],
    );
  }
}
