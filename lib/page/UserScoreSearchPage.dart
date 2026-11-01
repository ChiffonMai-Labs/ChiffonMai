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
import '../utils/AppDesignTokens.dart';

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
  Map<String, int>? _stats; // 存储统计数据

  /// 点评级分布条选中的评级（下标对应 [_rankBuckets]），null = 不筛。
  int? _rankFilter;
  static const List<String> _rankBuckets = ['SSS+', 'SSS', 'SS+', 'SS', 'S+以下'];

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

  bool _matchesSearch(dynamic song) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return (song['title']?.toString() ?? '').toLowerCase().contains(q) ||
        (song['ds']?.toString() ?? '').startsWith(q) ||
        (song['song_id']?.toString() ?? '') == q;
  }

  /// 通过搜索后的成绩（评级分布的统计口径）。
  List<dynamic> get _searchedSongs =>
      _sortedSongs.where(_matchesSearch).toList();

  /// 最终显示的成绩（再叠加评级筛选）。
  List<dynamic> get _visibleSongs => _rankFilter == null
      ? _searchedSongs
      : _searchedSongs.where((s) => _rankBucketOf(s) == _rankFilter).toList();
  
  int _currentPage = 1;
  int _pageSize = 50;
  final TextEditingController _pageSizeController = TextEditingController(text: '50');

  // 当前选中的按钮索引
  int _selectedButtonIndex = 0;
  
  // 缓存DX分数达成率，避免重复计算
  Map<dynamic, double> _dxRateCache = {};
  
  // 当前排序方式
  String _currentSortBy = 'Rating'; // 默认选择Rating
  
  // 显示模式：true为曲绘模式，false为列表模式
  bool _isCoverMode = false;
  
  // 筛选条件
  Map<String, String> _filterConditions = {
    '版本筛选': '',
    '定数筛选': '',
    '难度筛选': '',
    '达成率筛选': '',
    '连击/同步筛选': '',
  };
  
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _userPlayData = await _service.getUserPlayData();
      if (_userPlayData != null) {
        // 初始化歌曲缓存，确保星数计算时缓存可用
        await _service.initSongCache();
        _sortedSongs = await _service.getSortedSongs(_userPlayData!, _currentSortBy);
        // 应用筛选条件
        _sortedSongs = await _service.filterSongs(_sortedSongs, _filterConditions);
        _updatePagedSongs();
        // 计算统计数据
        _stats = await _calculateStats();
      }
    } catch (e) {
      debugPrint('加载数据出错: $e');
    } finally {
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
        return AlertDialog(
          title: Text('选择排序方式'),
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
                    title: Text('达成率'),
                    value: '达成率',
                    groupValue: _currentSortBy,
                    onChanged: (value) {
                      setState(() {
                        _currentSortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('定数'),
                    value: '定数',
                    groupValue: _currentSortBy,
                    onChanged: (value) {
                      setState(() {
                        _currentSortBy = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text('DX分数达成率'),
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
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                Navigator.of(context).pop();
                _loadData(); // 重新加载数据
              },
            ),
          ],
        );
      },
    );
  }
  
  // 显示版本筛选对话框
  void _showVersionFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedVersion = _filterConditions['版本筛选'] ?? '';
        return AlertDialog(
          title: Text('版本筛选'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: Text('全部'),
                        value: '',
                        groupValue: selectedVersion,
                        onChanged: (value) {
                          setState(() {
                            selectedVersion = value!;
                          });
                        },
                      ),
                      ..._versionList.map((version) {
                        return RadioListTile<String>(
                          title: Text(_formatVersion(version)),
                          value: version,
                          groupValue: selectedVersion,
                          onChanged: (value) {
                            setState(() {
                              selectedVersion = value!;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                setState(() {
                  _filterConditions['版本筛选'] = selectedVersion;
                  _currentPage = 1; // 筛选条件变化时，切换到第1页
                });
                Navigator.of(context).pop();
                _loadData(); // 重新加载数据
              },
            ),
          ],
        );
      },
    );
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
    
    return levels.toList()..sort((a, b) {
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
  
  // 显示定数筛选对话框
  void _showDsFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final brightness = Theme.of(context).brightness;
        final scheme = Theme.of(context).colorScheme;
        return FutureBuilder<List<String>>(
          future: _getLevelOptions(),
          builder: (context, snapshot) {
            List<Map<String, String>> quickOptions = [];
            if (snapshot.hasData) {
              for (String level in snapshot.data!) {
                double minDs, maxDs;
                if (level == '15') {
                  minDs = 15.0;
                  maxDs = 15.0;
                } else if (level.endsWith('+')) {
                  int base = int.parse(level.substring(0, level.length - 1));
                  minDs = base + 0.6;
                  maxDs = base + 0.9;
                } else {
                  int base = int.parse(level);
                  minDs = base.toDouble();
                  maxDs = base + 0.5;
                }
                quickOptions.add({
                  'label': level,
                  'min': minDs.toStringAsFixed(1),
                  'max': maxDs.toStringAsFixed(1),
                });
              }
            }
            
            String currentRange = _filterConditions['定数筛选'] ?? '';
            TextEditingController minController = TextEditingController();
            TextEditingController maxController = TextEditingController();
            
            if (currentRange.contains('-')) {
              List<String> parts = currentRange.split('-');
              if (parts.length == 2) {
                minController.text = parts[0];
                maxController.text = parts[1];
              }
            }
            
            return AlertDialog(
              title: Text('定数筛选'),
              content: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: minController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: '下界',
                                  hintText: '1.0',
                                  suffixIcon: minController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: '清除下界',
                                          icon: Icon(Icons.clear),
                                          onPressed: () {
                                            minController.clear();
                                            setState(() {});
                                          },
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: maxController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: '上界',
                                  hintText: '15.0',
                                  suffixIcon: maxController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: '清除上界',
                                          icon: Icon(Icons.clear),
                                          onPressed: () {
                                            maxController.clear();
                                            setState(() {});
                                          },
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('最多一位小数，留空表示默认值', style: TextStyle(fontSize: 12, color: AppColors.secondaryText(brightness))),
                        SizedBox(height: 16),
                        Text('快捷选项:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: quickOptions.map((option) {
                            return ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  minController.text = option['min']!;
                                  maxController.text = option['max']!;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primaryContainer,
                                foregroundColor: scheme.onPrimaryContainer,
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                textStyle: TextStyle(fontSize: 12),
                              ),
                              child: Text(option['label']!),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('确认'),
                  onPressed: () {
                    String minText = minController.text.trim();
                    String maxText = maxController.text.trim();
                    String range = '';

                    if (minText.isNotEmpty || maxText.isNotEmpty) {
                      range = '$minText-$maxText';
                    }

                    setState(() {
                      _filterConditions['定数筛选'] = range;
                      _currentPage = 1;
                    });
                    Navigator.of(context).pop();
                    _loadData();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // 显示难度筛选对话框
  void _showDifficultyFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedDifficulty = _filterConditions['难度筛选'] ?? '';
        List<String> difficulties = ['', ...ChartDifficulty.labels];
        return AlertDialog(
          title: Text('难度筛选'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: difficulties.map((difficulty) {
                  return RadioListTile<String>(
                    title: Text(difficulty.isEmpty ? '全部' : difficulty),
                    value: difficulty,
                    groupValue: selectedDifficulty,
                    onChanged: (value) {
                      setState(() {
                        selectedDifficulty = value!;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                setState(() {
                  _filterConditions['难度筛选'] = selectedDifficulty;
                  _currentPage = 1; // 筛选条件变化时，切换到第1页
                });
                Navigator.of(context).pop();
                _loadData(); // 重新加载数据
              },
            ),
          ],
        );
      },
    );
  }
  
  // 显示达成率筛选对话框
  void _showAchievementFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final brightness = Theme.of(context).brightness;
        final scheme = Theme.of(context).colorScheme;
        // 达成率快捷选项
        List<Map<String, String>> quickOptions = [
          {'label': 'SSS+', 'min': '100.5', 'max': '101'},
          {'label': 'SSS', 'min': '100', 'max': '100.4999'},
          {'label': 'SS+', 'min': '99.5', 'max': '99.9999'},
          {'label': 'SS', 'min': '99', 'max': '99.4999'},
          {'label': 'S+', 'min': '98.0', 'max': '98.9999'},
          {'label': 'S', 'min': '97', 'max': '97.9999'},
          {'label': 'AAA', 'min': '94', 'max': '96.9999'},
          {'label': 'AA', 'min': '90', 'max': '93.9999'},
          {'label': 'A', 'min': '80', 'max': '89.9999'},
        ];
        
        String currentRange = _filterConditions['达成率筛选'] ?? '';
        TextEditingController minController = TextEditingController();
        TextEditingController maxController = TextEditingController();
        
        // 解析当前范围
        if (currentRange.contains('-')) {
          List<String> parts = currentRange.split('-');
          if (parts.length == 2) {
            minController.text = parts[0];
            maxController.text = parts[1];
          }
        }
        
        return AlertDialog(
          title: Text('达成率筛选'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: '下界',
                              hintText: '0',
                              suffixIcon: minController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: '清除下界',
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        minController.clear();
                                        setState(() {});
                                      },
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: '上界',
                              hintText: '101',
                              suffixIcon: maxController.text.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: '清除上界',
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        maxController.clear();
                                        setState(() {});
                                      },
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('最多四位小数，留空表示默认值', style: TextStyle(fontSize: 12, color: AppColors.secondaryText(brightness))),
                    SizedBox(height: 16),
                    Text('快捷选项:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickOptions.map((option) {
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              minController.text = option['min']!;
                              maxController.text = option['max']!;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primaryContainer,
                            foregroundColor: scheme.onPrimaryContainer,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            textStyle: TextStyle(fontSize: 12),
                          ),
                          child: Text(option['label']!),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                String minText = minController.text.trim();
                String maxText = maxController.text.trim();
                String range = '';

                if (minText.isNotEmpty || maxText.isNotEmpty) {
                  range = '$minText-$maxText';
                }

                setState(() {
                  _filterConditions['达成率筛选'] = range;
                  _currentPage = 1; // 筛选条件变化时，切换到第1页
                });
                Navigator.of(context).pop();
                _loadData(); // 重新加载数据
              },
            ),
          ],
        );
      },
    );
  }
  
  // 显示连击/同步筛选对话框
  void _showComboFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedFilter = _filterConditions['连击/同步筛选'] ?? '';
        List<String> filters = ['全部', '无连击评价', 'FC', 'FC+', 'AP', 'AP+', '无同步评价', 'SYNC', 'FS', 'FS+', 'FDX', 'FDX+'];
        List<String> filterValues = ['全部', '无连击评价', 'FC', 'FC+', 'AP', 'AP+', '无同步评价', 'SYNC', 'FS', 'FS+', 'FDX', 'FDX+'];
        return AlertDialog(
          title: Text('连击/同步筛选'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(filters.length, (index) {
                      return RadioListTile<String>(
                        title: Text(filters[index]),
                        value: filterValues[index],
                        groupValue: selectedFilter,
                        onChanged: (value) {
                          setState(() {
                            selectedFilter = value!;
                          });
                        },
                      );
                    }),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确认'),
              onPressed: () {
                setState(() {
                  _filterConditions['连击/同步筛选'] = selectedFilter;
                  _currentPage = 1; // 筛选条件变化时，切换到第1页
                });
                Navigator.of(context).pop();
                _loadData(); // 重新加载数据
              },
            ),
          ],
        );
      },
    );
  }
  
  void _updatePagedSongs() {
    _pagedSongs = _service.getPagedSongs(_visibleSongs, _currentPage, _pageSize);
  }
  
  void _changePage(int page) {
    setState(() {
      _currentPage = page;
      _updatePagedSongs();
    });
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

  // 计算统计数据
  Future<Map<String, int>> _calculateStats() async {
    if (_sortedSongs.isEmpty) {
      return {
        'total': 0,
        'sssp': 0,
        'sss': 0,
        'fc': 0,
        'ap': 0,
        'fs': 0,
        'fdx': 0,
        'star5': 0,
        'star4': 0,
        'star3': 0,
        'star2': 0,
        'star1': 0,
      };
    }
    
    List<dynamic> records = _sortedSongs;
    int total = records.length;
    int sssp = 0; // ≥SSS+
    int sss = 0;  // ≥SSS
    int fc = 0;   // FC/FC+
    int ap = 0;   // AP/AP+
    int fs = 0;   // FS/FS+
    int fdx = 0;  // FDX/FDX+
    int star5 = 0; // 5星
    int star4 = 0; // 4星
    int star3 = 0; // 3星
    int star2 = 0; // 2星
    int star1 = 0; // 1星
    
    // 计算星数时，先缓存DX分数达成率，避免重复计算
    Map<dynamic, double> dxRateMap = {};
    
    for (var record in records) {
      // 统计成绩等级
      if (record.containsKey('achievements')) {
        double achievements = double.tryParse(record['achievements'].toString()) ?? 0;
        if (achievements >= 100.5) {
          sssp++;
        } else if (achievements >= 100.0) {
          sss++;
        }
      }
      
      // 统计FC/AP
      if (record.containsKey('fc')) {
        String fcValue = record['fc'].toString().toLowerCase();
        if (fcValue == 'fc' || fcValue == 'fcp') {
          fc++;
        }
        if (fcValue == 'ap' || fcValue == 'app') {
          ap++;
        }
      }
      
      // 统计FS/FDX
      if (record.containsKey('fs')) {
        String fsValue = record['fs'].toString().toLowerCase();
        if (fsValue == 'fs' || fsValue == 'fsp') {
          fs++;
        }
        if (fsValue == 'fsd' || fsValue == 'fsdp') {
          fdx++;
        }
      }
    }
    
    // 单独计算星数，避免在主循环中阻塞
    for (var record in records) {
      // 统计星数
      if (record.containsKey('dxScore')) {
        // ignore: unused_local_variable
        int dxScore = int.tryParse(record['dxScore'].toString()) ?? 0;
        // 计算DX分数达成率
        double rate;
        if (dxRateMap.containsKey(record)) {
          rate = dxRateMap[record]!;
        } else {
          rate = await _calculateDXScoreRate(record);
          dxRateMap[record] = rate;
        }
        if (rate >= 0.97) {
          star5++;
        } else if (rate >= 0.95) {
          star4++;
        } else if (rate >= 0.93) {
          star3++;
        } else if (rate >= 0.90) {
          star2++;
        } else if (rate >= 0.85) {
          star1++;
        }
      }
    }
    
    return {
      'total': total,
      'sssp': sssp,
      'sss': sss,
      'fc': fc,
      'ap': ap,
      'fs': fs,
      'fdx': fdx,
      'star5': star5,
      'star4': star4,
      'star3': star3,
      'star2': star2,
      'star1': star1,
    };
  }
  
  // 使用UserScoreSearchService中的方法计算DX分数达成率
  double _calculateDXScoreRate(dynamic record) {
    return _service.calculateDXScoreRateSync(record);
  }
  
  // 构建星数统计项
  Widget _buildStarStatItem(String stars, int value) {
    return _statCell(StarBadge(stars: stars, fontSize: 11), value);
  }
  
  // 获取星星颜色

  // 构建统计项
  Widget _buildStatItem(String label, int value) {
    return _statCell(
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      value,
    );
  }

  Widget _statCell(Widget label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          label,
          const SizedBox(height: 4),
          Text(
            '$value',
            maxLines: 1,
            style: AppTheme.number(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final stats =  _calculateStats();

    return BackgroundPageScaffold(
      title: '成绩查询',
      resizeToAvoidBottomInset: false, // 防止键盘弹出时调整布局
      actions: [
        IconButton(
          tooltip: _searchOpen ? '关闭搜索' : '搜索曲名或定数',
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
                    Text(_currentSortBy,
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
                  child: Text('没有找到缓存数据',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
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
                                items: const [
                                  SegmentedTabItem('评级'),
                                  SegmentedTabItem('连击'),
                                  SegmentedTabItem('同步'),
                                  SegmentedTabItem('得分'),
                                  SegmentedTabItem('星数'),
                                  SegmentedTabItem('定数'),
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
                            const SizedBox(height: AppDesignTokens.cardGap),
                            CollapsibleCard(
                              title: '详细统计',
                              child: _buildStatsGrid(),
                            ),
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
    _currentPage = 1;
    _updatePagedSongs();
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: widget.openSearch,
      onChanged: (value) => setState(() => _setSearchQuery(value)),
      decoration: InputDecoration(
        hintText: '查成绩：曲名、定数、曲目 ID',
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

  // 评级分布：色块宽度 = 数量，点色块或下方数字按评级筛选
  Widget _buildDistributionCard() {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final songs = _searchedSongs;
    final counts = List<int>.filled(_rankBuckets.length, 0);
    for (final s in songs) {
      counts[_rankBucketOf(s)]++;
    }
    void pick(int i) => setState(() {
          _rankFilter = _rankFilter == i ? null : i;
          _currentPage = 1;
          _updatePagedSongs();
        });
    double opacityOf(int i) =>
        _rankFilter == null || _rankFilter == i ? 1 : 0.3;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(
                child: Text('评级分布',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              Text(
                _rankFilter == null
                    ? '点色块筛选 · 共 ${songs.length} 条'
                    : '已筛选 ${_rankBuckets[_rankFilter!]} · 再点取消',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 14,
            child: Row(
              children: [
                for (var i = 0; i < counts.length; i++)
                  if (counts[i] > 0)
                    Expanded(
                      flex: counts[i],
                      child: Semantics(
                        button: true,
                        label: '${_rankBuckets[i]} ${counts[i]} 条，点按筛选',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => pick(i),
                          child: AnimatedOpacity(
                            opacity: opacityOf(i),
                            duration: AppDesignTokens.motion(
                                context, AppDesignTokens.fastMotion),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.rankDistribution(i, brightness),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < counts.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => pick(i),
                    child: Opacity(
                      opacity: opacityOf(i),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      AppColors.rankDistribution(i, brightness),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(_rankBuckets[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.number(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant)),
                              ),
                            ],
                          ),
                          Text('${counts[i]}',
                              style: AppTheme.number(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 详细统计（总数 / 连击同步 / 星数）
  Widget _buildStatsGrid() {
    final s = _stats!;
    Widget row(List<Widget> cells) => Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: cells[i]),
            ],
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row([
          _buildStatItem('总谱面数', s['total']!),
          _buildStatItem('SSS+', s['sssp']!),
          _buildStatItem('SSS', s['sss']!),
        ]),
        const SizedBox(height: 8),
        row([
          _buildStatItem('FC/FC+', s['fc']!),
          _buildStatItem('AP/AP+', s['ap']!),
          _buildStatItem('FS/FS+', s['fs']!),
          _buildStatItem('FDX/FDX+', s['fdx']!),
        ]),
        const SizedBox(height: 8),
        row([
          for (final n in [5, 4, 3, 2, 1])
            _buildStarStatItem('✦$n', s['star$n']!),
        ]),
      ],
    );
  }

  // 横向滑动的筛选胶囊
  Widget _buildFilterRow() {
    final version = _filterConditions['版本筛选'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          FilterPill(
            label: '版本',
            value: version != null && version.isNotEmpty
                ? _formatVersion(version)
                : null,
            onTap: _showVersionFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: '定数',
            value: _filterConditions['定数筛选'],
            onTap: _showDsFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: '难度',
            value: _filterConditions['难度筛选'],
            onTap: _showDifficultyFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: '达成率',
            value: _filterConditions['达成率筛选'],
            onTap: _showAchievementFilterDialog,
          ),
          const SizedBox(width: 6),
          FilterPill(
            label: '连击/同步',
            value: _filterConditions['连击/同步筛选'],
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
        Text('每页显示',
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
        Text('共 ${_visibleSongs.length} 条',
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
          tooltip: '上一页',
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
          tooltip: '下一页',
          onPressed: _currentPage < total
              ? () => _changePage(_currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _isCoverMode = !_isCoverMode),
          icon: Icon(_isCoverMode
              ? Icons.grid_view_rounded
              : Icons.view_agenda_outlined),
          label: Text(_isCoverMode ? '曲绘' : '列表'),
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
              double achievements = double.tryParse(song['achievements'].toString()) ?? 0;
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
                  initialLevelIndex: levelIndex,
                  isDefaultLevelIndex: false,
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
              borderRadius: BorderRadius.circular(8),
              color: Color(borderColor.value).withOpacity(0.3),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CoverUtil.buildCoverWidgetWithContextRRect(
                  context,
                  song['song_id']?.toString() ?? '',
                  double.infinity
                ),
                if (displayText.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: _selectedButtonIndex == 4 ?
                        Column(
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
                      :
                        Text(
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
        children: [
          for (var i = 0; i < _pagedSongs.length; i++)
            _buildListRow(_pagedSongs[i], showDivider: i > 0),
        ],
      ),
    );
  }

  Widget _buildListRow(dynamic song, {required bool showDivider}) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
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
    final syncColors = AppColors.syncBadge(brightness);
    String label(String raw) => raw
        .toUpperCase()
        .replaceAll('APP', 'AP+')
        .replaceAll('FCP', 'FC+')
        .replaceAll('FSDP', 'FDX+')
        .replaceAll('FSD', 'FDX')
        .replaceAll('FSP', 'FS+');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongInfoPage(
            songId: songId.toString(),
            initialLevelIndex: levelIndex,
            isDefaultLevelIndex: false,
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
                  Text(
                    song['title']?.toString() ?? '未知歌曲',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
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
                          AppBadge(
                            text: label(fc),
                            background:
                                AppColors.comboBadge(label(fc), brightness)
                                    .background,
                            foreground:
                                AppColors.comboBadge(label(fc), brightness)
                                    .foreground,
                            fontSize: 10,
                          ),
                        ],
                        if (fs.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          AppBadge(
                            text: label(fs),
                            background: syncColors.background,
                            foreground: syncColors.foreground,
                            fontSize: 10,
                          ),
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
                Text('定数 ${difficulty.toStringAsFixed(1)}',
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
