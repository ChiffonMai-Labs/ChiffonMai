import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/service/SongSearchService.dart';
import 'package:my_first_flutter_app/service/SongSearchHistoryStore.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/manager/SongAliasManager.dart';
import 'package:my_first_flutter_app/manager/MaiTagsManager.dart';
import 'package:my_first_flutter_app/entity/DXRating/MaiTagsModel.dart';
import 'dart:async';

import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/widgets/NoRipple.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import '../widgets/SongSearchEntry.dart';
import '../utils/SearchInteractionPreferences.dart';
import '../utils/DifficultyConstantFilter.dart';
import '../widgets/AnimatedChoiceBar.dart';
import '../widgets/MarqueeText.dart';
import 'package:my_first_flutter_app/constant/VersionListConstant.dart';
import 'package:my_first_flutter_app/constant/GenreListConstant.dart';
import '../widgets/AppUi.dart';
import '../utils/AppDesignTokens.dart';

enum _ConstantFilterMode { anyChart, perDifficulty }

class SongSearchPage extends StatefulWidget {
  /// 非国服入口严格按曲库的 isExtra 标记限定搜索范围。
  final bool extraOnly;

  const SongSearchPage({super.key, this.extraOnly = false});

  @override
  State<SongSearchPage> createState() => _SongSearchPageState();
}

class _SongSearchPageState extends State<SongSearchPage> {
  // 状态变量
  List<dynamic> _allSearchResults = []; // 所有搜索结果
  List<dynamic> _currentPageResults = []; // 当前页的结果
  bool _isSearching = false;
  String? _errorMessage;
  TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;
  final _historyStore = SongSearchHistoryStore();
  final _inlineSearchFocus = FocusNode();
  List<String> _inlineSearchHistory = [];
  int _historyRevision = 0;
  int _searchGeneration = 0;

  // 只按歌名搜索开关
  bool _searchByTitleOnly = false;

  // 分页相关
  int _currentPage = 1;
  int _pageSize = 15;
  int _totalItems = 0;
  int _totalPages = 0;

  // 筛选相关
  TextEditingController _minLevelController = TextEditingController();
  TextEditingController _maxLevelController = TextEditingController();
  _ConstantFilterMode _constantFilterMode = _ConstantFilterMode.anyChart;
  final _difficultyLevelControllers = <int, TextEditingController>{
    for (final index in ChartDifficulty.indices) index: TextEditingController(),
  };
  DifficultyConstantFilter _difficultyConstantFilter =
      DifficultyConstantFilter.fromInputs(const {});
  DifficultyConstantFilter? _appliedDifficultyConstantFilter;
  TextEditingController _minNotesController = TextEditingController();
  TextEditingController _maxNotesController = TextEditingController();
  TextEditingController _minBpmController = TextEditingController();
  TextEditingController _maxBpmController = TextEditingController();
  bool _showLevelFilter = false;
  bool _showNotesFilter = false;
  bool _showBpmFilter = false;
  bool _showVersionFilter = false;
  bool _showGenreFilter = false;
  bool _showTagFilter = false;
  /// 当前展开的筛选（胶囊的 key，见 [_filterShown]），null = 都收起。
  String? _activeFilter;
  bool _onlyDx = false;
  int? _songCount;

  static const List<String> _quickLevels = [
    '12',
    '12+',
    '13',
    '13+',
    '14',
    '14+',
    '15',
  ];
  List<String> _selectedVersions = [];
  List<String> _selectedGenres = [];
  List<int> _selectedTagIds = [];
  List<String> _selectedDifficulties = [];
  bool _showDifficultyFilter = false;
  String? _selectedCharter;
  String? _selectedArtist;

  static const List<String> _difficultyOptions = ChartDifficulty.labels;

  bool get _hasActiveLevelFilter =>
      _constantFilterMode == _ConstantFilterMode.perDifficulty
          ? _difficultyConstantFilter.hasInput
          : _minLevelController.text.isNotEmpty ||
              _maxLevelController.text.isNotEmpty;

  bool get _hasNonQueryFilters =>
      _onlyDx ||
      _hasActiveLevelFilter ||
      _minNotesController.text.isNotEmpty ||
      _maxNotesController.text.isNotEmpty ||
      _minBpmController.text.isNotEmpty ||
      _maxBpmController.text.isNotEmpty ||
      _selectedVersions.isNotEmpty ||
      _selectedGenres.isNotEmpty ||
      _selectedTagIds.isNotEmpty ||
      _selectedDifficulties.isNotEmpty ||
      _selectedCharter != null ||
      _selectedArtist != null;

  bool get _hasSearchCriteria =>
      _searchController.text.trim().isNotEmpty || _hasNonQueryFilters;

  // 标签数据
  Map<int, String> _tagIdToNameMap = {};
  Map<int, (String, int)> _tagIdToInfoMap = {};
  List<TagGroupItem> _tagGroups = [];
  bool _isLoadingTags = false;

  // 歌曲标签信息缓存
  Map<String, List<String>> _songTagInfoCache = {};
  MaiTagsEntity? _cachedTagsEntity;

  // 版本列表
  List<String> _versionList = VersionListConstant.versionOrderList;

  // 流派列表
  List<String> _genreList = GenreListConstant.genreList;

  // 谱师列表
  List<String> _charterList = [];
  bool _isLoadingCharters = false;

  // 曲师列表
  List<String> _artistList = [];
  bool _isLoadingArtists = false;

  @override
  void initState() {
    super.initState();
    SearchInteractionPreferences.instance
        .addListener(_onSearchInteractionChanged);
    SearchInteractionPreferences.instance.load();
    _inlineSearchFocus.addListener(_onSearchInteractionChanged);
    unawaited(_reloadSearchHistory());
    if (widget.extraOnly) {
      _versionList = [];
      _genreList = [];
    }
    _loadTagData();
    _loadFilterLists();
    unawaited(_loadSongCount());
  }

  Future<void> _loadSongCount() async {
    try {
      final songs = await SongSearchService.loadAllSongs() ?? [];
      if (!mounted) return;
      setState(() => _songCount = widget.extraOnly
          ? songs.where((song) => song.isExtra).length
          : songs.length);
    } catch (e) {
      debugPrint('读取曲库数量失败: $e');
    }
  }

  /// 等级快捷键对应的定数范围（与成绩查询的等级口径一致：x.0–x.5 / x.6–x.9）。
  (String, String) _quickLevelRange(String level) {
    if (level == '15') return ('15.0', '15.0');
    final plus = level.endsWith('+');
    final base = level.replaceAll('+', '');
    return plus ? ('$base.6', '$base.9') : ('$base.0', '$base.5');
  }

  bool _isQuickLevelSelected(String level) {
    if (_constantFilterMode != _ConstantFilterMode.anyChart) return false;
    final range = _quickLevelRange(level);
    return _minLevelController.text == range.$1 &&
        _maxLevelController.text == range.$2;
  }

  void _toggleQuickLevel(String level) {
    final selected = _isQuickLevelSelected(level);
    final range = _quickLevelRange(level);
    setState(() {
      _constantFilterMode = _ConstantFilterMode.anyChart;
      _minLevelController.text = selected ? '' : range.$1;
      _maxLevelController.text = selected ? '' : range.$2;
      _resetSearchResultState();
    });
    _performFilteredSearch();
  }

  /// 胶囊下面展开的筛选是否真的开着（筛选自己的标题行也能收起它）。
  bool get _filterShown => switch (_activeFilter) {
        'difficulty' => _showDifficultyFilter,
        'level' => _showLevelFilter,
        'notes' => _showNotesFilter,
        'bpm' => _showBpmFilter,
        'version' => _showVersionFilter,
        'genre' => _showGenreFilter,
        'tag' => _showTagFilter,
        'charter' || 'artist' => true,
        _ => false,
      };

  void _toggleFilter(String key) {
    final open = !(_activeFilter == key && _filterShown);
    setState(() {
      _activeFilter = open ? key : null;
      _showDifficultyFilter = open && key == 'difficulty';
      _showLevelFilter = open && key == 'level';
      _showNotesFilter = open && key == 'notes';
      _showBpmFilter = open && key == 'bpm';
      _showVersionFilter = open && key == 'version';
      _showGenreFilter = open && key == 'genre';
      _showTagFilter = open && key == 'tag';
    });
  }

  void _resetAllFilters() {
    _searchTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _searchController.clear();
      _minLevelController.clear();
      _maxLevelController.clear();
      for (final controller in _difficultyLevelControllers.values) {
        controller.clear();
      }
      _difficultyConstantFilter = _readDifficultyConstants();
      _minNotesController.clear();
      _maxNotesController.clear();
      _minBpmController.clear();
      _maxBpmController.clear();
      _selectedVersions.clear();
      _selectedGenres.clear();
      _selectedTagIds.clear();
      _selectedDifficulties.clear();
      _selectedCharter = null;
      _selectedArtist = null;
      _onlyDx = false;
      _activeFilter = null;
    });
    _performSearch('');
  }

  // 加载谱师和曲师列表
  Future<void> _loadFilterLists() async {
    setState(() {
      _isLoadingCharters = true;
      _isLoadingArtists = true;
    });
    try {
      final charters =
          await SongSearchService.getCharterList(extraOnly: widget.extraOnly);
      final artists =
          await SongSearchService.getArtistList(extraOnly: widget.extraOnly);
      var versions = _versionList;
      var genres = _genreList;
      if (widget.extraOnly) {
        final songs = (await SongSearchService.loadAllSongs() ?? [])
            .where((song) => song.isExtra)
            .toList();
        versions = songs
            .map((song) => song.basicInfo.from)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) {
            final order =
                (VersionListConstant.japaneseVersionOrderMap[a.trim()] ?? 999)
                    .compareTo(
                        VersionListConstant.japaneseVersionOrderMap[b.trim()] ??
                            999);
            return order != 0 ? order : a.compareTo(b);
          });
        genres = songs
            .map((song) => song.basicInfo.genre)
            .where((value) => value.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
      }
      if (mounted) {
        setState(() {
          _charterList = charters;
          _artistList = artists;
          _versionList = versions;
          _genreList = genres;
          _isLoadingCharters = false;
          _isLoadingArtists = false;
        });
      }
    } catch (e) {
      debugPrint('加载筛选列表失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingCharters = false;
          _isLoadingArtists = false;
        });
      }
    }
  }

  @override
  void dispose() {
    SearchInteractionPreferences.instance
        .removeListener(_onSearchInteractionChanged);
    _inlineSearchFocus.removeListener(_onSearchInteractionChanged);
    _inlineSearchFocus.dispose();
    _searchController.dispose();
    _minLevelController.dispose();
    _maxLevelController.dispose();
    for (final controller in _difficultyLevelControllers.values) {
      controller.dispose();
    }
    _minNotesController.dispose();
    _maxNotesController.dispose();
    _minBpmController.dispose();
    _maxBpmController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  // 加载标签数据
  Future<void> _loadTagData() async {
    setState(() {
      _isLoadingTags = true;
    });
    try {
      final maiTagsEntity = await MaiTagsManager().getTags();
      if (maiTagsEntity != null) {
        _tagGroups = maiTagsEntity.tagGroups;
        _tagIdToNameMap = await MaiTagsManager().getTagIdToNameMap();
        _tagIdToInfoMap = await MaiTagsManager().getTagIdToInfoMap();
      }
    } catch (e) {
      debugPrint('加载标签数据失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTags = false;
        });
      }
    }
  }

  bool _isUtageSong(dynamic song) {
    return ChartDifficulty.isUtageSong(song.id, type: song.type.toString());
  }

  /// 返回当前难度筛选对应的谱面索引。没有选择难度时返回歌曲所有谱面。
  Iterable<int> _selectedDifficultyIndices(dynamic song) {
    if (_selectedDifficulties.isEmpty) {
      return Iterable<int>.generate(song.charts.length);
    }

    final isUtage = _isUtageSong(song);
    const indices = ChartDifficulty.standardIndexByLabel;
    final result = <int>{};
    for (final difficulty in _selectedDifficulties) {
      if (difficulty == ChartDifficulty.utageLabel) {
        if (isUtage && song.charts.isNotEmpty) result.add(0);
        continue;
      }
      if (isUtage) continue;
      final index = indices[difficulty];
      if (index != null && index < song.charts.length) result.add(index);
    }
    return result;
  }

  bool _songHasSelectedDifficulty(dynamic song) {
    if (_selectedDifficulties.isEmpty) return true;
    return _selectedDifficultyIndices(song)
        .any((index) => index < song.ds.length);
  }

  Widget _buildDifficultyFilter(double screenWidth) {
    final selectedText = _selectedDifficulties.join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _showDifficultyFilter = !_showDifficultyFilter),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        '难度筛选',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Text(
                              selectedText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showDifficultyFilter ? Icons.expand_less : Icons.expand_more,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        _buildFilterExpansion(
          visible: _showDifficultyFilter,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
            child: Wrap(
              spacing: screenWidth * 0.02,
              runSpacing: screenWidth * 0.02,
              children: _difficultyOptions.map((difficulty) {
                final index = ChartDifficulty.indexOf(difficulty)!;
                final selected = _selectedDifficulties.contains(difficulty);
                final color = index == ChartDifficulty.utage
                    ? AppColors.utageAccent(
                        brightness: Theme.of(context).brightness)
                    : ColorUtil.getCardColor(index);
                final foreground =
                    ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black87;
                return NoRipple(
                    child: FilterChip(
                  label: Text(
                    difficulty,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? foreground
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selected: selected,
                  selectedColor: color,
                  checkmarkColor: foreground,
                  side: BorderSide(
                      color: selected
                          ? color
                          : Theme.of(context).colorScheme.outlineVariant),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDifficulties.add(difficulty);
                      } else {
                        _selectedDifficulties.remove(difficulty);
                      }
                    });
                    _debouncedFilter();
                  },
                ));
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 执行搜索
  Future<void> _performSearch(String query) async {
    query = query.trim();
    final generation = ++_searchGeneration;
    if (!mounted) return;
    final difficultyFilter =
        _constantFilterMode == _ConstantFilterMode.perDifficulty
            ? _difficultyConstantFilter
            : null;
    if (difficultyFilter != null && !difficultyFilter.isValid) {
      setState(() => _resetSearchResultState(error: '请先修正按难度组合的定数输入'));
      return;
    }
    // 检查是否所有筛选条件都为空
    bool allFiltersEmpty = query.isEmpty && !_hasNonQueryFilters;

    if (allFiltersEmpty) {
      setState(() {
        _resetSearchResultState();
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });

      // 调用搜索服务
      List<dynamic> results;
      if (query.isEmpty) {
        // 当输入框为空时，获取所有歌曲
        results = await MaimaiMusicDataManager().getCachedSongs() ?? [];
      } else {
        // 当输入框不为空时，执行搜索
        results = await SongSearchService.searchSongs(query,
            titleOnly: _searchByTitleOnly);
      }
      if (!mounted || generation != _searchGeneration) return;

      // 应用筛选条件
      List<dynamic> filteredResults = widget.extraOnly
          ? results.where((song) => song.isExtra == true).toList()
          : results;
      if (_onlyDx) {
        filteredResults =
            filteredResults.where((song) => song.type == 'DX').toList();
      }

      // 难度多选依然是独立条件，并限定任意定数、物量、谱师和标签的检查范围。
      // 按难度组合则明确检查每个已填写的难度，不受这个多选范围限制。
      if (_selectedDifficulties.isNotEmpty) {
        filteredResults =
            filteredResults.where(_songHasSelectedDifficulty).toList();
      }

      // 应用定数筛选
      if (difficultyFilter != null) {
        if (difficultyFilter.hasInput) {
          filteredResults = filteredResults
              .where((song) => difficultyFilter.matches(
                    song.ds,
                    chartCount: song.charts.length,
                    isUtage: _isUtageSong(song),
                  ))
              .toList();
        }
      } else if (_minLevelController.text.isNotEmpty ||
          _maxLevelController.text.isNotEmpty) {
        // 处理边界值
        double? minLevel = double.tryParse(_minLevelController.text);
        double? maxLevel = double.tryParse(_maxLevelController.text);

        // 如果没写下界但写了上界，则将下界设为1.0
        if (minLevel == null && maxLevel != null) {
          minLevel = 1.0;
        }
        // 如果写了下界但没写上界，则将上界设为15.0
        if (minLevel != null && maxLevel == null) {
          maxLevel = 15.0;
        }

        filteredResults = filteredResults.where((song) {
          // 只检查当前选中的难度；未选择时保留原来的任意难度匹配。
          final indices = _selectedDifficultyIndices(song);
          for (final index in indices) {
            if (index >= song.ds.length) continue;
            final ds = song.ds[index];
            bool meetsMin = minLevel == null || ds >= minLevel;
            bool meetsMax = maxLevel == null || ds <= maxLevel;
            if (meetsMin && meetsMax) {
              return true;
            }
          }
          return false;
        }).toList();
      }

      // 应用物量筛选（任意难度的总音符数落在区间内即匹配）
      if (_minNotesController.text.isNotEmpty ||
          _maxNotesController.text.isNotEmpty) {
        int? minNotes = int.tryParse(_minNotesController.text);
        int? maxNotes = int.tryParse(_maxNotesController.text);
        if (minNotes == null && maxNotes != null) {
          minNotes = 0;
        }
        if (minNotes != null && maxNotes == null) {
          maxNotes = 99999;
        }

        filteredResults = filteredResults.where((song) {
          for (final index in _selectedDifficultyIndices(song)) {
            if (index >= song.charts.length) continue;
            final chart = song.charts[index];
            if (chart.notes.isEmpty) continue;
            int total = chart.notes.fold(0, (sum, n) => sum + n);
            bool meetsMin = minNotes == null || total >= minNotes;
            bool meetsMax = maxNotes == null || total <= maxNotes;
            if (meetsMin && meetsMax) {
              return true;
            }
          }
          return false;
        }).toList();
      }

      // 应用 BPM 筛选
      if (_minBpmController.text.isNotEmpty ||
          _maxBpmController.text.isNotEmpty) {
        int? minBpm = int.tryParse(_minBpmController.text);
        int? maxBpm = int.tryParse(_maxBpmController.text);
        if (minBpm == null && maxBpm != null) {
          minBpm = 0;
        }
        if (minBpm != null && maxBpm == null) {
          maxBpm = 99999;
        }

        filteredResults = filteredResults.where((song) {
          final bpm = song.basicInfo.bpm;
          bool meetsMin = minBpm == null || bpm >= minBpm;
          bool meetsMax = maxBpm == null || bpm <= maxBpm;
          return meetsMin && meetsMax;
        }).toList();
      }

      // 应用版本筛选
      if (_selectedVersions.isNotEmpty) {
        filteredResults = filteredResults.where((song) {
          return _selectedVersions.contains(song.basicInfo.from);
        }).toList();
        // 普通入口沿用原范围，非国服入口保留已限定的 extra 曲库。
        if (!widget.extraOnly) {
          filteredResults =
              filteredResults.where((song) => !song.isExtra).toList();
        }
      }

      // 应用流派筛选
      if (_selectedGenres.isNotEmpty) {
        filteredResults = filteredResults.where((song) {
          return _selectedGenres.contains(song.basicInfo.genre);
        }).toList();
      }

      // 应用谱师筛选（歌曲的任意谱面包含所选谱师即可）
      if (_selectedCharter != null) {
        filteredResults = filteredResults.where((song) {
          return _selectedDifficultyIndices(song).any((index) =>
              index < song.charts.length &&
              song.charts[index].charter == _selectedCharter);
        }).toList();
      }

      // 应用曲师筛选
      if (_selectedArtist != null) {
        filteredResults = filteredResults.where((song) {
          return song.basicInfo.artist == _selectedArtist;
        }).toList();
      }

      // 应用标签筛选
      if (_selectedTagIds.isNotEmpty) {
        debugPrint('=== 标签筛选开始 ===');
        debugPrint('所选标签ID: $_selectedTagIds');

        // 获取标签数据
        final maiTagsManager = MaiTagsManager();
        final tagsEntity = await maiTagsManager.getTags();

        // 缓存标签数据供后续使用
        _cachedTagsEntity = tagsEntity;

        if (tagsEntity != null) {
          debugPrint('标签数据加载成功，tagSongs数量: ${tagsEntity.tagSongs.length}');

          // 预构建高效的搜索映射：(songId, sheetType, sheetDifficulty) -> List<tagId>
          Map<String, Set<int>> tagMap = {};
          for (var tagSong in tagsEntity.tagSongs) {
            String key =
                '${tagSong.songId}|${tagSong.sheetType}|${tagSong.sheetDifficulty}';
            if (!tagMap.containsKey(key)) {
              tagMap[key] = {};
            }
            tagMap[key]!.add(tagSong.tagId);
          }
          debugPrint('构建了 ${tagMap.length} 个谱面的标签映射');

          // 构建所选标签的集合
          Set<int> selectedTagSet = Set.from(_selectedTagIds);

          // 获取标签名称映射
          final tagIdToNameMap = await maiTagsManager.getTagIdToNameMap();

          // 清空并重建歌曲标签信息缓存
          _songTagInfoCache.clear();

          int matchCount = 0;
          filteredResults = filteredResults.where((song) {
            // 获取歌曲标题和类型
            final String songTitle = song.basicInfo.title;

            // 根据歌曲类型确定sheetType（支持std, dx, utage）
            String sheetType;
            if (song.type == 'DX') {
              sheetType = 'dx';
            } else if (_isUtageSong(song)) {
              // UTAGE 歌曲通常是 6 位 ID，也兼容 type 直接标记为 UTAGE 的数据。
              sheetType = 'utage';
            } else {
              sheetType = 'std';
            }

            // 为当前歌曲构建标签信息
            List<String> tagInfoList = [];

            // 只检查当前选中的难度；未选择时遍历所有难度。
            for (final i in _selectedDifficultyIndices(song)) {
              if (i >= song.level.length) continue;
              // 根据难度索引确定难度名称
              String sheetDifficulty = _getDifficultyByIndexForSong(song, i);
              String difficultyDisplayName =
                  _getDifficultyDisplayNameForSong(song, i);

              // 构建查找键
              String key = '$songTitle|$sheetType|$sheetDifficulty';
              Set<int>? tagIds = tagMap[key];

              if (tagIds != null && tagIds.isNotEmpty) {
                // 构建该难度的标签信息（只显示用户所选的标签）
                List<String> tagNames = [];
                for (int tagId in tagIds) {
                  if (selectedTagSet.contains(tagId)) {
                    String? tagName = tagIdToNameMap[tagId];
                    if (tagName != null) {
                      tagNames.add(tagName);
                    }
                  }
                }

                if (tagNames.isNotEmpty) {
                  tagInfoList
                      .add('${difficultyDisplayName}：${tagNames.join('、')}');
                }

                // 检查是否有交集
                for (int tagId in selectedTagSet) {
                  if (tagIds.contains(tagId)) {
                    matchCount++;
                    debugPrint(
                        '匹配成功: 歌曲[$songTitle], 类型[$sheetType], 难度[$sheetDifficulty], 标签ID[$tagId]');
                    // 缓存标签信息
                    _songTagInfoCache[songTitle] = tagInfoList;
                    return true;
                  }
                }
              }
            }

            // 即使不匹配筛选条件，也缓存标签信息
            if (tagInfoList.isNotEmpty) {
              _songTagInfoCache[songTitle] = tagInfoList;
            }

            return false;
          }).toList();

          debugPrint('标签筛选完成，匹配到 $matchCount 首歌曲');
        } else {
          debugPrint('标签数据加载失败！');
          filteredResults = [];
        }

        debugPrint('=== 标签筛选结束 ===');
      }

      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _appliedDifficultyConstantFilter = difficultyFilter;
        _allSearchResults = filteredResults;
        _totalItems = filteredResults.length;
        _totalPages = (_totalItems + _pageSize - 1) ~/ _pageSize; // 计算总页数
        _currentPage = 1; // 重置到第一页
        _updateCurrentPageResults(); // 更新当前页结果
        _isSearching = false;
      });
      if (query.isNotEmpty) {
        try {
          await _historyStore.remember(query);
          unawaited(_reloadSearchHistory());
        } catch (e) {
          debugPrint('保存搜索历史失败: $e');
        }
      }
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _errorMessage = '搜索失败：$e';
        _isSearching = false;
      });
    }
  }

  // 更新当前页的结果
  void _updateCurrentPageResults() {
    int startIndex = (_currentPage - 1) * _pageSize;
    int endIndex = startIndex + _pageSize;
    if (endIndex > _totalItems) {
      endIndex = _totalItems;
    }
    _currentPageResults = _allSearchResults.sublist(startIndex, endIndex);
  }

  // 切换到指定页码
  void _goToPage(int page) {
    if (page < 1) page = 1;
    if (page > _totalPages) page = _totalPages;
    setState(() {
      _currentPage = page;
      _updateCurrentPageResults();
    });
  }

  // 防抖搜索
  void _debouncedSearch(String query) {
    _searchGeneration++;
    setState(() {});
    // 取消之前的定时器
    _searchTimer?.cancel();

    // 设置新的定时器，1000毫秒后执行搜索
    _searchTimer = Timer(const Duration(milliseconds: 1000), () {
      _performSearch(query);
    });
  }

  // 执行筛选搜索
  void _performFilteredSearch() {
    _submitSearch(_searchController.text);
  }

  // 防抖筛选
  void _debouncedFilter() {
    _searchGeneration++;
    // 取消之前的定时器
    _searchTimer?.cancel();

    // 设置新的定时器，1000毫秒后执行筛选
    _searchTimer = Timer(const Duration(milliseconds: 1000), () {
      // 即使没有输入内容也执行搜索
      _performSearch(_searchController.text);
    });
  }

  void _submitSearch(String query) {
    _searchTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    unawaited(_performSearch(query));
  }

  void _onSearchInteractionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _reloadSearchHistory() async {
    final revision = ++_historyRevision;
    try {
      final history = await _historyStore.load();
      if (mounted && revision == _historyRevision) {
        setState(() => _inlineSearchHistory = history);
      }
    } catch (error) {
      debugPrint('加载搜索历史失败: $error');
    }
  }

  Future<void> _removeSearchHistory([String? query]) async {
    try {
      if (query == null) {
        await _historyStore.clear();
      } else {
        await _historyStore.remove(query);
      }
      await _reloadSearchHistory();
    } catch (error) {
      debugPrint('清理搜索历史失败: $error');
    }
  }

  Widget _buildInlineSearchHistory() {
    if (_inlineSearchHistory.isEmpty || _hasSearchCriteria) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('最近搜索',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant)),
              ),
              TextButton(
                onPressed: () => _removeSearchHistory(),
                style: TextButton.styleFrom(
                    minimumSize: const Size(44, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('清空', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final query in _inlineSearchHistory)
                InputChip(
                  label:
                      Text(query, maxLines: 1, overflow: TextOverflow.ellipsis),
                  labelStyle: const TextStyle(fontSize: 13),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: scheme.outlineVariant),
                  shape: const StadiumBorder(),
                  deleteIconColor: scheme.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _searchController.value = TextEditingValue(
                      text: query,
                      selection: TextSelection.collapsed(offset: query.length),
                    );
                    _submitSearch(query);
                  },
                  onDeleted: () => _removeSearchHistory(query),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEntry(double fontSize, double hintFontSize) =>
      SongSearchEntry(
        controller: _searchController,
        focusNode: _inlineSearchFocus,
        titleOnly: _searchByTitleOnly,
        fontSize: fontSize,
        hintFontSize: hintFontSize,
        onChanged: (query) {
          setState(() {});
          _debouncedSearch(query);
        },
        onSubmitted: _submitSearch,
      );

  Widget _buildFilterExpansion({
    required bool visible,
    required Widget child,
  }) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: visible ? child : const SizedBox.shrink(),
    );
  }

  void _resetSearchResultState({String? error}) {
    _allSearchResults = [];
    _currentPageResults = [];
    _currentPage = 1;
    _totalItems = 0;
    _totalPages = 0;
    _isSearching = false;
    _errorMessage = error;
    _appliedDifficultyConstantFilter = null;
  }

  DifficultyConstantFilter _readDifficultyConstants() =>
      DifficultyConstantFilter.fromInputs({
        for (final entry in _difficultyLevelControllers.entries)
          entry.key: entry.value.text,
      });

  void _setConstantFilterMode(_ConstantFilterMode mode) {
    if (_constantFilterMode == mode) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _searchTimer?.cancel();
    setState(() {
      _constantFilterMode = mode;
      _difficultyConstantFilter = _readDifficultyConstants();
      _resetSearchResultState();
    });
    unawaited(_performSearch(_searchController.text));
  }

  void _onDifficultyConstantChanged() {
    _searchTimer?.cancel();
    ++_searchGeneration; // 输入尚未完成时，旧请求也不能再发布结果。
    setState(() {
      _difficultyConstantFilter = _readDifficultyConstants();
      _resetSearchResultState(
          error: _difficultyConstantFilter.isValid ? null : '请先修正按难度组合的定数输入');
      _isSearching = _difficultyConstantFilter.isValid && _hasSearchCriteria;
    });
    if (_difficultyConstantFilter.isValid) _debouncedFilter();
  }

  void _clearActiveLevelFilter() {
    setState(() {
      if (_constantFilterMode == _ConstantFilterMode.perDifficulty) {
        for (final controller in _difficultyLevelControllers.values) {
          controller.clear();
        }
        _difficultyConstantFilter = _readDifficultyConstants();
      } else {
        _minLevelController.clear();
        _maxLevelController.clear();
      }
      _resetSearchResultState();
    });
    _performFilteredSearch();
  }

  Widget _buildDifficultyConstantFields() {
    final scheme = Theme.of(context).colorScheme;
    final utageActive = _difficultyConstantFilter.hasUtageInput;
    final standardActive = _difficultyConstantFilter.hasStandardInput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('填写的普通难度须全部满足，留空不限制。支持单值 13.7 或闭区间 13.4-14。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        Text('与上方「难度」及其它筛选条件取交集。',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        if (utageActive || standardActive) ...[
          Text(
              utageActive
                  ? '已填写 UTAGE，普通难度暂不可用；清空后恢复。'
                  : '已填写普通难度，UTAGE 暂不可用；全部清空后恢复。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.primary)),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 340 ? 2 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              for (final index in ChartDifficulty.indices)
                SizedBox(
                  width: width,
                  child: Builder(builder: (context) {
                    final enabled = index == ChartDifficulty.utage
                        ? !standardActive
                        : !utageActive;
                    final controller = _difficultyLevelControllers[index]!;
                    final color = index == ChartDifficulty.utage
                        ? AppColors.utageAccent(
                            brightness: Theme.of(context).brightness)
                        : ColorUtil.getCardColor(index);
                    final border = OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                      borderSide: BorderSide(color: scheme.outlineVariant),
                    );
                    return TextField(
                      key: ValueKey('difficulty-constant-$index'),
                      controller: controller,
                      enabled: enabled,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      textInputAction: TextInputAction.search,
                      scrollPadding: EdgeInsets.fromLTRB(24, 24, 24,
                          MediaQuery.viewInsetsOf(context).bottom + 24),
                      onChanged: (_) => _onDifficultyConstantChanged(),
                      onSubmitted: (_) => _performFilteredSearch(),
                      decoration: InputDecoration(
                        labelText: ChartDifficulty.labelOf(index),
                        labelStyle: TextStyle(
                            color: enabled ? color : scheme.onSurfaceVariant),
                        hintText: '如 13.4-14',
                        errorText: _difficultyConstantFilter.errors[index],
                        errorMaxLines: 3,
                        border: border,
                        enabledBorder: border,
                        disabledBorder: border,
                        filled: !enabled,
                        fillColor: scheme.surfaceContainerLow,
                        suffixIcon: controller.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip:
                                    '清空${ChartDifficulty.labelOf(index)}定数',
                                onPressed: () {
                                  controller.clear();
                                  _onDifficultyConstantChanged();
                                },
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                      ),
                    );
                  }),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLevelFilter(double screenWidth, double screenHeight) {
    // 生成已选内容文本
    String selectedLevelText = '';
    if (_constantFilterMode == _ConstantFilterMode.perDifficulty) {
      selectedLevelText = _difficultyConstantFilter.activeDifficulties
          .map(
            (index) =>
                '${ChartDifficulty.labelOf(index)} ${_difficultyLevelControllers[index]!.text.trim()}',
          )
          .join(' · ');
    } else if (_minLevelController.text.isNotEmpty ||
        _maxLevelController.text.isNotEmpty) {
      selectedLevelText =
          '${_minLevelController.text.isEmpty ? '1.0' : _minLevelController.text} - ${_maxLevelController.text.isEmpty ? '15.0' : _maxLevelController.text}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showLevelFilter = !_showLevelFilter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        '定数筛选',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedLevelText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: MarqueeText(
                              text: selectedLevelText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showLevelFilter ? Icons.expand_less : Icons.expand_more,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        _buildFilterExpansion(
          visible: _showLevelFilter,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedChoiceBar<_ConstantFilterMode>(
                  values: _ConstantFilterMode.values,
                  value: _constantFilterMode,
                  label: (mode) =>
                      mode == _ConstantFilterMode.anyChart ? '任意难度' : '按难度组合',
                  onChanged: _setConstantFilterMode,
                ),
                if (_constantFilterMode == _ConstantFilterMode.anyChart) ...[
                  const SizedBox(height: 10),
                  _buildQuickLevels(),
                ],
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _hasActiveLevelFilter
                          ? _clearActiveLevelFilter
                          : null,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('清空定数'),
                    )),
                if (_constantFilterMode == _ConstantFilterMode.perDifficulty)
                  _buildDifficultyConstantFields()
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minLevelController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '最小值',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                          ),
                          onChanged: (value) {
                            _debouncedFilter();
                          },
                        ),
                      ),
                      const Text(' - '),
                      Expanded(
                        child: TextField(
                          controller: _maxLevelController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '最大值',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 10),
                          ),
                          onChanged: (value) {
                            _debouncedFilter();
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建物量筛选组件
  Widget _buildNotesFilter(double screenWidth, double screenHeight) {
    // 生成已选内容文本
    String selectedNotesText = '';
    if (_minNotesController.text.isNotEmpty ||
        _maxNotesController.text.isNotEmpty) {
      selectedNotesText =
          '${_minNotesController.text.isEmpty ? '0' : _minNotesController.text} - ${_maxNotesController.text.isEmpty ? '不限' : _maxNotesController.text}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showNotesFilter = !_showNotesFilter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        '物量筛选',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedNotesText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Text(
                              selectedNotesText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showNotesFilter ? Icons.expand_less : Icons.expand_more,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        _buildFilterExpansion(
          visible: _showNotesFilter,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minNotesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '最少物量',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                    onChanged: (value) {
                      _debouncedFilter();
                    },
                  ),
                ),
                const Text(' - '),
                Expanded(
                  child: TextField(
                    controller: _maxNotesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '最多物量',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                    onChanged: (value) {
                      _debouncedFilter();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建 BPM 筛选组件
  Widget _buildBpmFilter(double screenWidth, double screenHeight) {
    // 生成已选内容文本
    String selectedBpmText = '';
    if (_minBpmController.text.isNotEmpty ||
        _maxBpmController.text.isNotEmpty) {
      selectedBpmText =
          '${_minBpmController.text.isEmpty ? '0' : _minBpmController.text} - ${_maxBpmController.text.isEmpty ? '不限' : _maxBpmController.text}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showBpmFilter = !_showBpmFilter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        'BPM筛选',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedBpmText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Text(
                              selectedBpmText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showBpmFilter ? Icons.expand_less : Icons.expand_more,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        _buildFilterExpansion(
          visible: _showBpmFilter,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minBpmController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '最小 BPM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                    onChanged: (value) {
                      _debouncedFilter();
                    },
                  ),
                ),
                const Text(' - '),
                Expanded(
                  child: TextField(
                    controller: _maxBpmController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '最大 BPM',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                    onChanged: (value) {
                      _debouncedFilter();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 构建版本筛选组件
  Widget _buildVersionFilter(double screenWidth, double screenHeight) {
    // 生成已选内容文本
    String selectedVersionsText = _selectedVersions
        .map((v) => StringUtil.formatVersionWithFlag(v, widget.extraOnly))
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showVersionFilter = !_showVersionFilter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        '版本筛选',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedVersionsText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Text(
                              selectedVersionsText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showVersionFilter ? Icons.expand_less : Icons.expand_more,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        _buildFilterExpansion(
          visible: _showVersionFilter,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            child: Wrap(
              spacing: screenWidth * 0.02,
              runSpacing: screenHeight * 0.01,
              children: _versionList.map((version) {
                return FilterChip(
                  label: Text(
                    StringUtil.formatVersion2WithFlag(
                        version, widget.extraOnly),
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: _selectedVersions.contains(version),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedVersions.add(version);
                      } else {
                        _selectedVersions.remove(version);
                      }
                    });
                    // 防抖筛选
                    _debouncedFilter();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 构建流派筛选组件
  Widget _buildGenreFilter(double screenWidth, double screenHeight) {
    // 生成已选内容文本
    String selectedGenresText = _selectedGenres.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showGenreFilter = !_showGenreFilter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        '流派筛选',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedGenresText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Text(
                              selectedGenresText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showGenreFilter ? Icons.expand_less : Icons.expand_more,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        _buildFilterExpansion(
          visible: _showGenreFilter,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            child: Wrap(
              spacing: screenWidth * 0.02,
              runSpacing: screenHeight * 0.01,
              children: _genreList.map((genre) {
                return FilterChip(
                  label: Text(
                    genre,
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: _selectedGenres.contains(genre),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                    // 防抖筛选
                    _debouncedFilter();
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 构建标签筛选组件
  Widget _buildTagFilter(double screenWidth, double screenHeight) {
    // 生成已选内容文本
    String selectedTagsText = _selectedTagIds
        .map((tagId) => _tagIdToNameMap[tagId] ?? '未知标签')
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showTagFilter = !_showTagFilter;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Text(
                        '标签筛选',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedTagsText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Text(
                              selectedTagsText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _showTagFilter ? Icons.expand_less : Icons.expand_more,
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
        _buildFilterExpansion(
          visible: _showTagFilter,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            child: _isLoadingTags
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(screenHeight * 0.02),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  )
                : _tagGroups.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(screenHeight * 0.02),
                          child: Text(
                            '暂无标签数据',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: _tagGroups.length,
                        itemBuilder: (context, groupIndex) {
                          TagGroupItem group = _tagGroups[groupIndex];
                          // 获取该分组下的所有标签
                          List<int> tagsInGroup = _tagIdToInfoMap.entries
                              .where((entry) => entry.value.$2 == group.id)
                              .map((entry) => entry.key)
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 分组标题
                              Padding(
                                padding: EdgeInsets.only(
                                  top: groupIndex == 0
                                      ? 0
                                      : screenHeight * 0.005,
                                  bottom: screenHeight * 0.008,
                                ),
                                child: Text(
                                  group.localizedName.zhHans,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              // 分组下的标签
                              Wrap(
                                spacing: screenWidth * 0.02,
                                runSpacing: screenHeight * 0.008,
                                children: tagsInGroup.map((tagId) {
                                  String tagName =
                                      _tagIdToNameMap[tagId] ?? '未知标签';
                                  return FilterChip(
                                    label: Text(
                                      tagName,
                                      style: TextStyle(
                                          fontSize: 11),
                                    ),
                                    selected: _selectedTagIds.contains(tagId),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedTagIds.add(tagId);
                                        } else {
                                          _selectedTagIds.remove(tagId);
                                        }
                                      });
                                      // 防抖筛选
                                      _debouncedFilter();
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  // 构建谱师筛选组件（点击弹出对话框，单选，支持搜索）
  Widget _buildCharterFilter(double screenWidth, double screenHeight) {
    return _buildDialogFilterRow(
      screenWidth: screenWidth,
      label: '谱师筛选',
      displayValue: _selectedCharter,
      placeholder: '请选择谱师',
      dialogTitle: '选择谱师',
      searchHint: '搜索谱师',
      dialogSearchHint: '输入谱师名称筛选...',
      isLoadingList: _isLoadingCharters,
      fullList: _charterList,
      onSelected: (value) {
        setState(() => _selectedCharter = value);
        _debouncedFilter();
      },
      onClear: () {
        setState(() => _selectedCharter = null);
        _debouncedFilter();
      },
    );
  }

  // 构建曲师筛选组件（点击弹出对话框，单选，支持搜索）
  Widget _buildArtistFilter(double screenWidth, double screenHeight) {
    return _buildDialogFilterRow(
      screenWidth: screenWidth,
      label: '曲师筛选',
      displayValue: _selectedArtist,
      placeholder: '请选择曲师',
      dialogTitle: '选择曲师',
      searchHint: '搜索曲师',
      dialogSearchHint: '输入曲师名称筛选...',
      isLoadingList: _isLoadingArtists,
      fullList: _artistList,
      onSelected: (value) {
        setState(() => _selectedArtist = value);
        _debouncedFilter();
      },
      onClear: () {
        setState(() => _selectedArtist = null);
        _debouncedFilter();
      },
    );
  }

  /// 通用的「点击弹出对话框单选」筛选行
  Widget _buildDialogFilterRow({
    required double screenWidth,
    required String label,
    required String? displayValue,
    required String placeholder,
    required String dialogTitle,
    required String searchHint,
    required String dialogSearchHint,
    required bool isLoadingList,
    required List<String> fullList,
    required ValueChanged<String?> onSelected,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: () => _showSingleSelectDialog(
        title: dialogTitle,
        searchHint: dialogSearchHint,
        selectedValue: displayValue,
        fullList: fullList,
        isLoadingList: isLoadingList,
        onSelected: onSelected,
        onClear: onClear,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      displayValue ?? placeholder,
                      style: TextStyle(
                        fontSize: 12,
                        color: displayValue != null
                            ? AppColors.linkBlue(Theme.of(context).brightness)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (displayValue != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onClear,
                      child: Icon(Icons.close,
                          size: screenWidth * 0.04,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                  Icon(Icons.chevron_right,
                      size: screenWidth * 0.04,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 弹出单选搜索对话框
  void _showSingleSelectDialog({
    required String title,
    required String searchHint,
    required String? selectedValue,
    required List<String> fullList,
    required bool isLoadingList,
    required ValueChanged<String?> onSelected,
    required VoidCallback onClear,
  }) {
    final searchController = TextEditingController();
    String filterQuery = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final query = filterQuery.toLowerCase();
            final filtered = query.isEmpty
                ? fullList
                : fullList
                    .where((e) => e.toLowerCase().contains(query))
                    .toList();

            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: searchHint,
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                        ),
                        onChanged: (v) => setDialogState(() => filterQuery = v),
                      ),
                      const SizedBox(height: 12),
                      if (isLoadingList)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: ListView.builder(
                            shrinkWrap: false,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final isSelected = item == selectedValue;
                              return ListTile(
                                title: Text(item,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.linkBlue(
                                              Theme.of(context).brightness)
                                          : null,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : null,
                                    )),
                                trailing: isSelected
                                    ? Icon(Icons.check,
                                        color: AppColors.linkBlue(
                                            Theme.of(context).brightness))
                                    : null,
                                onTap: () {
                                  onSelected(item);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                        ),
                      if (selectedValue != null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              onClear();
                              Navigator.pop(ctx);
                            },
                            child: const Text('清除选择'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: widget.extraOnly ? '非国服乐曲查询' : '歌曲搜索',
      resizeToAvoidBottomInset: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    const gutter = AppDesignTokens.gutter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(gutter, 4, gutter, 12),
          child: _buildSearchEntry(15, 15),
        ),
        _buildFilterPillRow(),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter,
                gutter + bottomInset + media.viewInsets.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_activeFilter != null && _filterShown) ...[
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                    child: _buildActiveFilter(),
                  ),
                  const SizedBox(height: AppDesignTokens.cardGap),
                ],
                _buildInlineSearchHistory(),
                _buildResults(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilter() {
    final size = MediaQuery.sizeOf(context);
    return switch (_activeFilter) {
      'difficulty' => _buildDifficultyFilter(size.width),
      'level' => _buildLevelFilter(size.width, size.height),
      'notes' => _buildNotesFilter(size.width, size.height),
      'bpm' => _buildBpmFilter(size.width, size.height),
      'version' => _buildVersionFilter(size.width, size.height),
      'genre' => _buildGenreFilter(size.width, size.height),
      'tag' => _buildTagFilter(size.width, size.height),
      'charter' => _buildCharterFilter(size.width, size.height),
      'artist' => _buildArtistFilter(size.width, size.height),
      _ => const SizedBox.shrink(),
    };
  }

  // 等级快捷键（圆形胶囊，点一下筛这个等级，再点取消）
  Widget _buildQuickLevels() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedBg = theme.brightness == Brightness.dark
        ? scheme.inverseSurface
        : scheme.onSurface;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final level in _quickLevels)
          Builder(builder: (context) {
            final selected = _isQuickLevelSelected(level);
            return Semantics(
              button: true,
              selected: selected,
              label: '等级 $level',
              excludeSemantics: true,
              child: Material(
                color: selected ? selectedBg : AppSurfaces.inset(context),
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  onTap: () => _toggleQuickLevel(level),
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Text(level,
                          style: AppTheme.number(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? scheme.onInverseSurface
                                  : scheme.onSurface)),
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  String? _rangeText(TextEditingController min, TextEditingController max) {
    if (min.text.isEmpty && max.text.isEmpty) return null;
    return '${min.text}-${max.text}';
  }

  String? _countText(int count) => count == 0 ? null : '$count 项';

  // 筛选胶囊：点开后展开在下面，已选的条件直接显示在胶囊上
  Widget _buildFilterPillRow() {
    Widget pill(String key, String label, String? value) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterPill(
            label: label,
            value: value,
            onTap: () => _toggleFilter(key),
          ),
        );
    final String? levelText =
        _constantFilterMode == _ConstantFilterMode.perDifficulty
            ? (_difficultyConstantFilter.hasInput ? '按难度' : null)
            : _rangeText(_minLevelController, _maxLevelController);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.gutter),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterPill(
              label: '仅 DX 谱面',
              selected: _onlyDx,
              onTap: () {
                setState(() {
                  _onlyDx = !_onlyDx;
                  _resetSearchResultState();
                });
                _performFilteredSearch();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterPill(
              label: '只搜歌名',
              selected: _searchByTitleOnly,
              onTap: () {
                setState(() => _searchByTitleOnly = !_searchByTitleOnly);
                // 切换后防抖触发搜索。
                _debouncedSearch(_searchController.text);
              },
            ),
          ),
          pill('difficulty', '难度', _selectedDifficulties.join('、')),
          pill('level', '定数', levelText),
          pill('version', '版本', _countText(_selectedVersions.length)),
          pill('genre', '流派', _countText(_selectedGenres.length)),
          pill('bpm', 'BPM', _rangeText(_minBpmController, _maxBpmController)),
          pill('notes', '物量',
              _rangeText(_minNotesController, _maxNotesController)),
          pill('tag', '标签', _countText(_selectedTagIds.length)),
          pill('charter', '谱师', _selectedCharter),
          pill('artist', '曲师', _selectedArtist),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    Widget message(Widget child) => AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Center(child: child),
        );
    if (_isSearching) {
      return message(Column(
        children: [
          CircularProgressIndicator(color: scheme.onSurface),
          const SizedBox(height: 12),
          Text('正在搜索...',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
        ],
      ));
    }
    if (_errorMessage != null) {
      final error = AppColors.errorRed(brightness);
      return message(Column(
        children: [
          Icon(Icons.error_outline, color: error, size: 40),
          const SizedBox(height: 12),
          Text(_errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: error)),
        ],
      ));
    }
    if (!_hasSearchCriteria) {
      return message(Text(
          _songCount == null ? '请输入搜索关键词' : '曲库共 $_songCount 首，请输入搜索关键词',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 0, 4),
          child: Row(
            children: [
              Expanded(
                child: Text('找到 $_totalItems 首乐曲，每页 15 首',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
              ),
              TextButton(
                onPressed: _resetAllFilters,
                style: TextButton.styleFrom(
                    minimumSize: const Size(44, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('重置', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),
        if (_allSearchResults.isEmpty)
          message(Column(
            children: [
              const Text('没有符合条件的歌曲',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('试试放宽定数或清空筛选',
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
            ],
          ))
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              key: ValueKey('$_searchGeneration-$_currentPage'),
              children: [
                for (var i = 0; i < _currentPageResults.length; i++)
                  EntranceAnimation(
                    index: i,
                    stagger: const Duration(milliseconds: 25),
                    duration: const Duration(milliseconds: 320),
                    offset: const Offset(-10, 0),
                    child: _buildSongItem(_currentPageResults[i],
                        showDivider: i > 0),
                  ),
              ],
            ),
          ),
        if (_totalPages > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filledTonal(
                  tooltip: '上一页',
                  onPressed: _currentPage > 1
                      ? () => _goToPage(_currentPage - 1)
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const SizedBox(width: 12),
                Text('$_currentPage / $_totalPages',
                    style: AppTheme.number(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface)),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: '下一页',
                  onPressed: _currentPage < _totalPages
                      ? () => _goToPage(_currentPage + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 构建歌曲项
  Widget _buildSongItem(dynamic song, {required bool showDivider}) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isUtage = song.id.toString().length == 6;
    final isSd = song.type == 'SD';
    final typeColors = isUtage
        ? AppColors.difficultyBadge(2, brightness)
        : (isSd
            ? AppColors.syncBadge(brightness)
            : AppColors.difficultyBadge(1, brightness));

    // 生成匹配信息
    List<Map<String, String>> matchInfo = _getMatchInfo(song);

    // 获取标签信息
    List<String> tagInfoList = _getTagInfoForSong(song);
    final List<String> levels = List<String>.from(song.level);
    final highlight =
        TextStyle(fontSize: 12, height: 1.35, color: scheme.primary);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(songId: song.id.toString()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: AppSurfaces.hairline(context)))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: CoverUtil.buildCoverWidget(song.id, 52),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      AppBadge(
                        text: isUtage
                            ? ChartDifficulty.utageLabel
                            : (isSd ? 'ST' : 'DX'),
                        background: typeColors.background,
                        foreground: typeColors.foreground,
                        fontSize: 10,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: MarqueeText(
                          text: song.basicInfo.title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  MarqueeText(
                    text: song.basicInfo.artist,
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    '#${song.id} · ${StringUtil.formatVersionWithFlag(song.basicInfo.from, song.isExtra)} · ${song.basicInfo.genre}',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                  // 匹配信息
                  for (final info in matchInfo)
                    Text('${info['type']}：${info['value']}', style: highlight),
                  for (final tagInfo in tagInfoList)
                    Text(tagInfo, style: highlight),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 等级小方块：四个一行，Re:MASTER 换到第二行
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (var i = 0; i < levels.length; i++)
                    Builder(builder: (context) {
                      final c = isUtage
                          ? AppColors.difficultyBadge(2, brightness)
                          : AppColors.difficultyBadge(i, brightness);
                      // 不用 Container.alignment：它会把方块撑满 Wrap 的宽度。
                      return Container(
                        constraints:
                            const BoxConstraints(minWidth: 22, minHeight: 22),
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          widthFactor: 1,
                          heightFactor: 1,
                          child: Text(levels[i],
                              style: AppTheme.number(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: c.foreground)),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 获取歌曲的标签信息（显示每个难度与用户所选标签的交集）
  List<String> _getTagInfoForSong(dynamic song) {
    List<String> tagInfoList = [];

    // 如果没有缓存的标签实体，返回空
    if (_cachedTagsEntity == null) {
      return tagInfoList;
    }

    // 如果没有选择任何标签，返回空
    if (_selectedTagIds.isEmpty) {
      return tagInfoList;
    }

    // 构建所选标签的集合
    Set<int> selectedTagSet = Set.from(_selectedTagIds);

    // 获取标签名称映射
    Map<int, String> tagIdToNameMap = {};
    for (var tag in _cachedTagsEntity!.tags) {
      tagIdToNameMap[tag.id] = tag.localizedName.zhHans;
    }

    // 获取歌曲信息
    final String songTitle = song.basicInfo.title;
    String sheetType;
    if (song.type == 'DX') {
      sheetType = 'dx';
    } else if (_isUtageSong(song)) {
      sheetType = 'utage';
    } else {
      sheetType = 'std';
    }

    // 只显示当前选中的难度；未选择时显示所有难度。
    for (final i in _selectedDifficultyIndices(song)) {
      if (i >= song.level.length) continue;
      String sheetDifficulty = _getDifficultyByIndexForSong(song, i);

      // 查找当前谱面的标签
      final List<TagSongItem> tagSongs = _cachedTagsEntity!.tagSongs
          .where((tagSong) =>
              tagSong.songId == songTitle &&
              tagSong.sheetType == sheetType &&
              tagSong.sheetDifficulty == sheetDifficulty)
          .toList();

      if (tagSongs.isNotEmpty) {
        // 获取该难度下与所选标签的交集
        List<String> tagNames = [];
        for (var tagSong in tagSongs) {
          if (selectedTagSet.contains(tagSong.tagId)) {
            String? tagName = tagIdToNameMap[tagSong.tagId];
            if (tagName != null) {
              tagNames.add(tagName);
            }
          }
        }

        // 如果有交集，显示该难度的标签信息
        if (tagNames.isNotEmpty) {
          String difficultyName = _getDifficultyDisplayNameForSong(song, i);
          tagInfoList.add('${difficultyName}：${tagNames.join('、')}');
        }
      }
    }

    return tagInfoList;
  }

  // 获取难度显示名称
  String _getDifficultyDisplayName(int index) {
    return ChartDifficulty.labelOf(index, fallback: 'Unknown');
  }

  String _getDifficultyDisplayNameForSong(dynamic song, int index) {
    return _isUtageSong(song)
        ? ChartDifficulty.utageLabel
        : _getDifficultyDisplayName(index);
  }

  String _getDifficultyByIndexForSong(dynamic song, int index) {
    return _isUtageSong(song) ? 'utage' : _getDifficultyByIndex(index);
  }

  // 获取匹配信息
  List<Map<String, String>> _getMatchInfo(dynamic song) {
    List<Map<String, String>> matchInfos = [];
    String query = _searchController.text.toLowerCase();
    bool hasQuery = query.isNotEmpty;

    // 难度筛选：显示歌曲实际命中的难度。
    if (_selectedDifficulties.isNotEmpty) {
      final matchedDifficulties = <String>{};
      for (final index in _selectedDifficultyIndices(song)) {
        if (index >= song.level.length) continue;
        matchedDifficulties.add(
          _getDifficultyDisplayNameForSong(song, index),
        );
      }
      for (final difficulty in matchedDifficulties) {
        matchInfos.add({'type': '难度', 'value': difficulty});
      }
    }

    // 定数区间筛选：显示通过筛选的难度和定数。
    if (_constantFilterMode == _ConstantFilterMode.perDifficulty) {
      final filter = _appliedDifficultyConstantFilter;
      if (filter != null) {
        final matches = <String>{};
        for (final index in filter.matchingChartIndices(song.ds,
            chartCount: song.charts.length, isUtage: _isUtageSong(song))) {
          matches.add(
              '${_getDifficultyDisplayNameForSong(song, index)}：${song.ds[index]}');
        }
        for (final value in matches) {
          matchInfos.add({'type': '定数', 'value': value});
        }
      }
    } else if (_minLevelController.text.isNotEmpty ||
        _maxLevelController.text.isNotEmpty) {
      double? minLevel = double.tryParse(_minLevelController.text);
      double? maxLevel = double.tryParse(_maxLevelController.text);
      if (minLevel == null && maxLevel != null) minLevel = 1.0;
      if (minLevel != null && maxLevel == null) maxLevel = 15.0;

      for (final index in _selectedDifficultyIndices(song)) {
        if (index >= song.ds.length || index >= song.level.length) continue;
        final level = song.ds[index];
        final meetsMin = minLevel == null || level >= minLevel;
        final meetsMax = maxLevel == null || level <= maxLevel;
        if (meetsMin && meetsMax) {
          matchInfos.add({
            'type': '定数',
            'value': '${_getDifficultyDisplayNameForSong(song, index)}：$level',
          });
        }
      }
    }

    // 物量区间筛选：显示通过的难度与物量
    if (_minNotesController.text.isNotEmpty ||
        _maxNotesController.text.isNotEmpty) {
      int? minNotes = int.tryParse(_minNotesController.text);
      int? maxNotes = int.tryParse(_maxNotesController.text);
      if (minNotes == null && maxNotes != null) minNotes = 0;
      if (minNotes != null && maxNotes == null) maxNotes = 99999;

      for (final i in _selectedDifficultyIndices(song)) {
        if (i >= song.level.length) continue;
        final chart = song.charts[i];
        if (chart.notes.isEmpty) continue;
        int total = chart.notes.fold(0, (sum, n) => sum + n);
        bool meetsMin = minNotes == null || total >= minNotes;
        bool meetsMax = maxNotes == null || total <= maxNotes;
        if (meetsMin && meetsMax) {
          matchInfos.add({
            'type': '物量',
            'value': '${_getDifficultyDisplayNameForSong(song, i)}：$total',
          });
        }
      }
    }

    // BPM 筛选：显示歌曲的 BPM
    if (_minBpmController.text.isNotEmpty ||
        _maxBpmController.text.isNotEmpty) {
      int? minBpm = int.tryParse(_minBpmController.text);
      int? maxBpm = int.tryParse(_maxBpmController.text);
      if (minBpm == null && maxBpm != null) minBpm = 0;
      if (minBpm != null && maxBpm == null) maxBpm = 99999;

      int bpm = song.basicInfo.bpm;
      bool meetsMin = minBpm == null || bpm >= minBpm;
      bool meetsMax = maxBpm == null || bpm <= maxBpm;
      if (meetsMin && meetsMax) {
        matchInfos.add({'type': 'BPM', 'value': bpm.toString()});
      }
    }

    // 谱师筛选：列出歌曲中命中的谱师
    if (_selectedCharter != null) {
      for (final index in _selectedDifficultyIndices(song)) {
        if (index >= song.charts.length) continue;
        final chart = song.charts[index];
        if (chart.charter == _selectedCharter) {
          matchInfos.add({
            'type':
                '${ChartDifficulty.labelOf(index, isUtage: _isUtageSong(song))}谱师',
            'value': chart.charter
          });
        }
      }
    }

    // 流派筛选：列出歌曲命中的流派
    if (_selectedGenres.isNotEmpty &&
        _selectedGenres.contains(song.basicInfo.genre)) {
      matchInfos.add({'type': '流派', 'value': song.basicInfo.genre});
    }

    // 版本筛选：显示歌曲命中的版本。
    if (_selectedVersions.contains(song.basicInfo.from)) {
      matchInfos.add({
        'type': '版本',
        'value':
            StringUtil.formatVersionWithFlag(song.basicInfo.from, song.isExtra),
      });
    }

    // 曲师筛选：列出歌曲命中的曲师
    if (_selectedArtist != null && song.basicInfo.artist == _selectedArtist) {
      matchInfos.add({'type': '曲师', 'value': song.basicInfo.artist});
    }

    if (!hasQuery) return matchInfos;

    // 检查歌曲ID匹配
    if (song.id.toString() == _searchController.text) {
      matchInfos.add({'type': '歌曲ID', 'value': song.id.toString()});
    }
    // 检查标题匹配
    if (song.basicInfo.title.toLowerCase().contains(query)) {
      matchInfos.add({'type': '歌名', 'value': song.basicInfo.title});
    }
    // 检查艺术家匹配
    if (song.basicInfo.artist.toLowerCase().contains(query)) {
      matchInfos.add({'type': '艺术家', 'value': song.basicInfo.artist});
    }
    // 检查BPM匹配
    if (song.basicInfo.bpm.toString().contains(query)) {
      matchInfos.add({'type': 'BPM', 'value': song.basicInfo.bpm.toString()});
    }
    // 检查谱师匹配
    for (final index in _selectedDifficultyIndices(song)) {
      if (index >= song.charts.length) continue;
      final chart = song.charts[index];
      if (chart.charter.toLowerCase().contains(query)) {
        matchInfos.add({
          'type':
              '${ChartDifficulty.labelOf(index, isUtage: _isUtageSong(song))}谱师',
          'value': chart.charter
        });
      }
    }
    // 检查流派匹配
    if (song.basicInfo.genre.toLowerCase().contains(query)) {
      matchInfos.add({'type': '流派', 'value': song.basicInfo.genre});
    }
    // 检查版本匹配
    if (song.basicInfo.from.toLowerCase().contains(query)) {
      matchInfos.add({
        'type': '版本',
        'value':
            StringUtil.formatVersionWithFlag(song.basicInfo.from, song.isExtra)
      });
    }
    // 检查别名匹配
    final aliases = SongAliasManager.instance.aliases[song.title] ?? [];
    final matchingAliases =
        aliases.where((alias) => alias.toLowerCase().contains(query)).toList();
    if (matchingAliases.isNotEmpty) {
      matchInfos.add({'type': '别名', 'value': matchingAliases.join('，')});
    }
    // 检查物量匹配（任意难度的总音符数包含 query）
    for (final i in _selectedDifficultyIndices(song)) {
      if (i >= song.level.length) continue;
      final chart = song.charts[i];
      if (chart.notes.isEmpty) continue;
      int total = chart.notes.fold(0, (sum, n) => sum + n);
      if (total.toString().contains(query)) {
        matchInfos.add({
          'type': '物量',
          'value': '${_getDifficultyDisplayNameForSong(song, i)}：$total',
        });
        break; // 只显示第一个匹配的难度
      }
    }
    return matchInfos;
  }

  // 根据难度索引获取难度名称（标签数据中使用的格式）
  String _getDifficultyByIndex(int index) {
    return ChartDifficulty.apiNameOf(index, fallback: 'unknown');
  }
}
