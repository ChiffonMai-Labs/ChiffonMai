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
import 'package:my_first_flutter_app/widgets/SongSearchOverlay.dart';
import '../widgets/TouchSearchButton.dart';
import 'package:my_first_flutter_app/constant/VersionListConstant.dart';
import 'package:my_first_flutter_app/constant/GenreListConstant.dart';

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
  final _searchFieldKey = GlobalKey();
  bool _searchOverlayOpen = false;
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
  bool _showAllFilters = true; // 控制是否显示所有筛选区域
  List<String> _selectedVersions = [];
  List<String> _selectedGenres = [];
  List<int> _selectedTagIds = [];
  List<String> _selectedDifficulties = [];
  bool _showDifficultyFilter = false;
  String? _selectedCharter;
  String? _selectedArtist;

  static const List<String> _difficultyOptions = ChartDifficulty.labels;

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
    if (widget.extraOnly) {
      _versionList = [];
      _genreList = [];
    }
    _loadTagData();
    _loadFilterLists();
  }

  // 加载谱师和曲师列表
  Future<void> _loadFilterLists() async {
    setState(() {
      _isLoadingCharters = true;
      _isLoadingArtists = true;
    });
    try {
      final charters = await SongSearchService.getCharterList(
          extraOnly: widget.extraOnly);
      final artists = await SongSearchService.getArtistList(
          extraOnly: widget.extraOnly);
      var versions = _versionList;
      var genres = _genreList;
      if (widget.extraOnly) {
        final songs = (await SongSearchService.loadAllSongs() ?? [])
            .where((song) => song.isExtra).toList();
        versions = songs.map((song) => song.basicInfo.from)
            .where((value) => value.trim().isNotEmpty).toSet().toList()
          ..sort((a, b) {
            final order = (VersionListConstant.japaneseVersionOrderMap[a.trim()] ?? 999)
                .compareTo(VersionListConstant.japaneseVersionOrderMap[b.trim()] ?? 999);
            return order != 0 ? order : a.compareTo(b);
          });
        genres = songs.map((song) => song.basicInfo.genre)
            .where((value) => value.trim().isNotEmpty).toSet().toList()..sort();
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
    _searchController.dispose();
    _minLevelController.dispose();
    _maxLevelController.dispose();
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
          onTap: () => setState(
              () => _showDifficultyFilter = !_showDifficultyFilter),
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
                          fontSize: screenWidth * 0.035,
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
                                fontSize: screenWidth * 0.03,
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
                  _showDifficultyFilter
                      ? Icons.expand_less
                      : Icons.expand_more,
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
                    ? AppColors.utageAccent(brightness: Theme.of(context).brightness)
                    : ColorUtil.getCardColor(index);
                final foreground = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                    ? Colors.white : Colors.black87;
                return NoRipple(child: FilterChip(
                  label: Text(
                    difficulty,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      color: selected ? foreground : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  selected: selected,
                  selectedColor: color,
                  checkmarkColor: foreground,
                  side: BorderSide(color: selected ? color : Theme.of(context).colorScheme.outlineVariant),
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
    // 检查是否所有筛选条件都为空
    bool allFiltersEmpty = query.isEmpty &&
        _minLevelController.text.isEmpty &&
        _maxLevelController.text.isEmpty &&
        _minNotesController.text.isEmpty &&
        _maxNotesController.text.isEmpty &&
        _minBpmController.text.isEmpty &&
        _maxBpmController.text.isEmpty &&
        _selectedVersions.isEmpty &&
        _selectedGenres.isEmpty &&
        _selectedTagIds.isEmpty &&
        _selectedDifficulties.isEmpty &&
        _selectedCharter == null &&
        _selectedArtist == null;

    if (allFiltersEmpty) {
      setState(() {
        _allSearchResults = [];
        _currentPageResults = [];
        _currentPage = 1;
        _totalItems = 0;
        _totalPages = 0;
        _isSearching = false;
        _errorMessage = null;
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

      // 应用筛选条件
      List<dynamic> filteredResults = widget.extraOnly
          ? results.where((song) => song.isExtra == true).toList()
          : results;

      // 难度筛选先限制歌曲必须存在指定难度；后面的定数、物量、谱师和标签
      // 筛选都会只检查这一张指定难度的谱面。
      if (_selectedDifficulties.isNotEmpty) {
        filteredResults =
            filteredResults.where(_songHasSelectedDifficulty).toList();
      }

      // 应用定数筛选
      if (_minLevelController.text.isNotEmpty ||
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
    _performSearch(_searchController.text);
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

  Future<void> _openSearchOverlay() async {
    if (_searchOverlayOpen) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final field = _searchFieldKey.currentContext?.findRenderObject();
    final overlay = navigator.overlay?.context.findRenderObject();
    if (field is! RenderBox || overlay is! RenderBox) return;
    final sourceRect =
        field.localToGlobal(Offset.zero, ancestor: overlay) & field.size;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _searchOverlayOpen = true);
    final route = SongSearchOverlay.route(
      sourceRect: sourceRect,
      initialQuery: _searchController.text,
      titleOnly: _searchByTitleOnly,
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
    try {
      final query = await navigator.push(route);
      if (mounted && query != null) {
        setState(() {
          _searchController.value = TextEditingValue(
            text: query,
            selection: TextSelection.collapsed(offset: query.length),
          );
        });
        _submitSearch(query);
      }
      // pop 的结果早于退出动画返回，等临时层收回后再显示原输入框。
      await route.completed;
    } finally {
      if (mounted) setState(() => _searchOverlayOpen = false);
    }
  }

  Widget _buildSearchEntry(double fontSize, double hintFontSize) {
    final colors = Theme.of(context).colorScheme;
    return Opacity(
      opacity: _searchOverlayOpen ? 0 : 1,
      child: Row(
        key: _searchFieldKey,
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              readOnly: true,
              enableInteractiveSelection: false,
              canRequestFocus: false,
              showCursor: false,
              onTap: _openSearchOverlay,
              decoration: InputDecoration(
                hintText: _searchByTitleOnly
                    ? '只按歌名搜索'
                    : '歌名/BPM/谱师/曲师/别名/歌曲ID/...',
                hintStyle: TextStyle(fontSize: hintFontSize),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          const SizedBox(width: 8),
          TouchSearchButton(
            onPressed: () => _submitSearch(_searchController.text),
          ),
        ],
      ),
    );
  }

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

  Widget _buildLevelFilter(double screenWidth, double screenHeight) {
    // 生成已选内容文本
    String selectedLevelText = '';
    if (_minLevelController.text.isNotEmpty ||
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
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (selectedLevelText.isNotEmpty)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Text(
                              selectedLevelText,
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
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
            child: Row(
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
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    ),
                    onChanged: (value) {
                      _debouncedFilter();
                    },
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: TextField(
                    controller: _maxLevelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '最大值',
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
                SizedBox(width: screenWidth * 0.02),
                ElevatedButton(
                  onPressed: _performFilteredSearch,
                  child: Text('搜索'),
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
                          fontSize: screenWidth * 0.035,
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
                                fontSize: screenWidth * 0.03,
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
                SizedBox(width: screenWidth * 0.02),
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
                SizedBox(width: screenWidth * 0.02),
                ElevatedButton(
                  onPressed: _performFilteredSearch,
                  child: Text('搜索'),
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
                          fontSize: screenWidth * 0.035,
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
                                fontSize: screenWidth * 0.03,
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
                SizedBox(width: screenWidth * 0.02),
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
                SizedBox(width: screenWidth * 0.02),
                ElevatedButton(
                  onPressed: _performFilteredSearch,
                  child: Text('搜索'),
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
    String selectedVersionsText =
        _selectedVersions.map((v) => StringUtil.formatVersionWithFlag(v, widget.extraOnly)).join(', ');

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
                          fontSize: screenWidth * 0.035,
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
                                fontSize: screenWidth * 0.03,
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
                    StringUtil.formatVersion2WithFlag(version, widget.extraOnly),
                    style: TextStyle(fontSize: screenWidth * 0.03),
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
                          fontSize: screenWidth * 0.035,
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
                                fontSize: screenWidth * 0.03,
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
                    style: TextStyle(fontSize: screenWidth * 0.03),
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
                          fontSize: screenWidth * 0.035,
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
                                fontSize: screenWidth * 0.03,
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
                              fontSize: screenWidth * 0.03,
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
                                    fontSize: screenWidth * 0.032,
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
                                          fontSize: screenWidth * 0.028),
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
                fontSize: screenWidth * 0.035,
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
                        fontSize: screenWidth * 0.03,
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
                            borderRadius: BorderRadius.circular(8),
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
    final brightness = Theme.of(context).brightness;

    return BackgroundPageScaffold(
      title: widget.extraOnly ? '非国服乐曲查询' : '歌曲搜索',
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 根据设备尺寸计算字体大小
            double screenWidth = MediaQuery.of(context).size.width;
            double screenHeight = MediaQuery.of(context).size.height;

            // 基础字体大小
            double baseFontSize = screenWidth * 0.04;
            double smallFontSize = screenWidth * 0.035;
            double tinyFontSize = screenWidth * 0.03;

            // 边距
            double padding = screenWidth * 0.04;

            return Column(
              children: [
                // 搜索输入框
                Padding(
                  padding: EdgeInsets.fromLTRB(padding, 8, padding, padding),
                  child: _buildSearchEntry(baseFontSize, smallFontSize),
                ),

                // 筛选条件、条目总数和搜索结果一起滚动
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                        left: padding, right: padding, bottom: padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 筛选按钮区域
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 260),
                          sizeCurve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          firstChild: Column(
                            children: [
                              // 只搜索歌名开关随筛选区一起展开、收起。
                              Row(
                                children: [
                                  Icon(
                                    Icons.text_fields,
                                    size: smallFontSize + 2,
                                    color: _searchByTitleOnly
                                        ? AppColors.linkBlue(brightness)
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '只搜索歌名',
                                    style: TextStyle(
                                      fontSize: smallFontSize,
                                      color: _searchByTitleOnly
                                          ? AppColors.linkBlue(brightness)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      fontWeight: _searchByTitleOnly
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Spacer(),
                                  Switch(
                                    value: _searchByTitleOnly,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchByTitleOnly = value;
                                      });
                                      // 切换后防抖触发搜索。
                                      _debouncedSearch(_searchController.text);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.005),

                              // 难度筛选
                              _buildDifficultyFilter(screenWidth),
                              SizedBox(height: screenHeight * 0.01),

                              // 定数筛选
                              _buildLevelFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),

                              // 物量筛选
                              _buildNotesFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),

                              // BPM 筛选
                              _buildBpmFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),

                              // 版本筛选
                              _buildVersionFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),

                              // 流派筛选
                              _buildGenreFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),

                              // 谱师筛选
                              _buildCharterFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),

                              // 曲师筛选
                              _buildArtistFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),

                              // 标签筛选
                              _buildTagFilter(screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.01),
                            ],
                          ),
                          secondChild: const SizedBox(width: double.infinity),
                          crossFadeState: _showAllFilters
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                        ),

                        // 搜索结果数量显示
                        if ((_searchController.text.isNotEmpty ||
                                _selectedVersions.isNotEmpty ||
                                _selectedGenres.isNotEmpty ||
                                _selectedTagIds.isNotEmpty ||
                                            _selectedDifficulties.isNotEmpty ||
                                _selectedCharter != null ||
                                _selectedArtist != null ||
                                _minLevelController.text.isNotEmpty ||
                                _maxLevelController.text.isNotEmpty ||
                                _minNotesController.text.isNotEmpty ||
                                _maxNotesController.text.isNotEmpty ||
                                _minBpmController.text.isNotEmpty ||
                                _maxBpmController.text.isNotEmpty) &&
                            !_isSearching &&
                            _errorMessage == null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '找到 $_totalItems 首乐曲，每页 15 首',
                                      style: TextStyle(
                                        fontSize: smallFontSize,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _minLevelController.clear();
                                        _maxLevelController.clear();
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
                                        _showAllFilters = true;
                                        _performSearch('');
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02,
                                        vertical: screenHeight * 0.005,
                                      ),
                                      minimumSize: Size(screenWidth * 0.15, 30),
                                      backgroundColor:
                                          AppColors.errorRed(brightness),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      '重置',
                                      style: TextStyle(fontSize: tinyFontSize),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _showAllFilters = !_showAllFilters;
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.02,
                                        vertical: screenHeight * 0.005,
                                      ),
                                      minimumSize: Size(screenWidth * 0.15, 30),
                                      backgroundColor:
                                          AppColors.linkBlue(brightness),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _showAllFilters
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _showAllFilters ? '收起筛选' : '展开筛选',
                                          style: TextStyle(
                                            fontSize: tinyFontSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                        SizedBox(height: screenHeight * 0.01),
                        // 加载状态
                        if (_isSearching)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(screenHeight * 0.1),
                              child: Column(
                                children: [
                                  CircularProgressIndicator(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Text(
                                    '正在搜索...',
                                    style: TextStyle(
                                        fontSize: baseFontSize,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          )
                        // 错误状态
                        else if (_errorMessage != null)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(screenHeight * 0.1),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: AppColors.errorRed(brightness),
                                    size: screenWidth * 0.12,
                                  ),
                                  SizedBox(height: screenHeight * 0.02),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.errorRed(brightness),
                                      fontSize: baseFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (_allSearchResults.isEmpty &&
                            _searchController.text.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(screenHeight * 0.1),
                              child: Text(
                                '未找到匹配的歌曲',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: baseFontSize,
                                ),
                              ),
                            ),
                          )
                        // 展示搜索结果
                        else if (_currentPageResults.isNotEmpty)
                          Column(
                            children: [
                              // 搜索结果列表
                              ..._currentPageResults
                                  .map((song) => _buildSongItem(song))
                                  .toList(),
                            ],
                          )
                        // 初始状态
                        else
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(screenHeight * 0.1),
                              child: Text(
                                '请输入搜索关键词',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: baseFontSize,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // 分页控件
                if (_totalPages > 1)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    // 底部安全区由 BackgroundPageScaffold 的 contentPadding 提供，
                    // 分页控件贴近安全区，避免视觉上被抬得过高。
                    margin: EdgeInsets.fromLTRB(
                      padding,
                      padding,
                      padding,
                      0,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.008,
                      horizontal: screenWidth * 0.05,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 上一页按钮
                        IconButton(
                          onPressed: _currentPage > 1
                              ? () => _goToPage(_currentPage - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),

                        // 页码显示
                        Text(
                          '$_currentPage / $_totalPages',
                          style: TextStyle(
                            fontSize: smallFontSize,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),

                        // 下一页按钮
                        IconButton(
                          onPressed: _currentPage < _totalPages
                              ? () => _goToPage(_currentPage + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 构建歌曲项
  Widget _buildSongItem(dynamic song) {
    final brightness = Theme.of(context).brightness;

    // 生成匹配信息
    List<Map<String, String>> matchInfo = _getMatchInfo(song);

    // 获取标签信息
    List<String> tagInfoList = _getTagInfoForSong(song);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(songId: song.id.toString()),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
              color: brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
                border: Border.all(
                    color: brightness == Brightness.dark
                        ? Colors.grey.shade700
                        : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CoverUtil.buildCoverWidget(song.id, 80),
              // child: Image.asset(
              //   coverUrl,
              //   fit: BoxFit.cover,
              //   errorBuilder: (context, error, stackTrace) {
              //     // 生成网络曲绘URL
              //     String coverId = song.id.toString();

              //     // 对于6位数的曲绘，只需要去除第一位
              //     if (coverId.length == 6) {
              //       // 去掉第一位
              //       coverId = coverId.substring(1);
              //     } else if (coverId.length < 5) {
              //       // 万位补1，其余位补0
              //       coverId = '1' + '0' * (4 - coverId.length) + coverId;
              //     }
              //     String networkCoverUrl = 'https://www.diving-fish.com/covers/$coverId.png';

              //     return Image.network(
              //       networkCoverUrl,
              //       fit: BoxFit.cover,
              //       errorBuilder: (context, error, stackTrace) {
              //         return Center(
              //           child: Text(
              //             '曲绘',
              //             style: TextStyle(
              //               fontSize: 14,
              //               color: Theme.of(context).colorScheme.onSurfaceVariant,
              //             ),
              //           ),
              //         );
              //       },
              //     );
              //   },
              // ),
            ),
            const SizedBox(width: 12),

            // 右侧信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 第一行：歌曲名和ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          song.basicInfo.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${song.id}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        song.id.toString().length == 6
                            ? ChartDifficulty.utageLabel
                            : (song.type == 'SD' ? 'ST' : 'DX'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: song.id.toString().length == 6
                              ? const Color(0xFFFF6B8B)
                              : (song.type == 'SD'
                                  ? AppColors.linkBlue(brightness)
                                  : AppColors.warningOrange(brightness)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 版本和流派
                      Expanded(
                        child: Text(
                          '${StringUtil.formatVersionWithFlag(song.basicInfo.from, song.isExtra)} | ${song.basicInfo.genre}',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 匹配信息
                  if (matchInfo.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: matchInfo
                          .map((info) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${info['type']}：${info['value']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.linkBlue(brightness),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ))
                          .toList(),
                    ),

                  if (tagInfoList.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: tagInfoList
                          .map((tagInfo) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  tagInfo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.linkBlue(brightness),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
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
    return _isUtageSong(song) ? ChartDifficulty.utageLabel : _getDifficultyDisplayName(index);
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
    if (_minLevelController.text.isNotEmpty ||
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
            'value':
                '${_getDifficultyDisplayNameForSong(song, index)}：$level',
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
      final matchedCharters = <String>{};
      for (final index in _selectedDifficultyIndices(song)) {
        if (index >= song.charts.length) continue;
        final chart = song.charts[index];
        if (chart.charter == _selectedCharter) {
          matchedCharters.add(chart.charter);
        }
      }
      for (final name in matchedCharters) {
        matchInfos.add({'type': '谱师', 'value': name});
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
        matchInfos.add({'type': '谱师', 'value': chart.charter});
        break; // 只添加第一个匹配的谱师
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
