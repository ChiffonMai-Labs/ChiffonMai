import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_first_flutter_app/service/PersonalizedScoreService.dart';
import 'package:my_first_flutter_app/service/PersonalizedScoreConvertToImgService.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/constant/VersionListConstant.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import 'package:my_first_flutter_app/widgets/SearchPickerDialog.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/ProgressUi.dart';
import '../widgets/AppDialogs.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';
import 'package:my_first_flutter_app/widgets/AppToast.dart';

class PersonalizedScorePage extends StatefulWidget {
  const PersonalizedScorePage({super.key});

  @override
  State<PersonalizedScorePage> createState() => _PersonalizedScorePageState();
}

class _PersonalizedScorePageState extends State<PersonalizedScorePage> {
  final PersonalizedScoreService _service = PersonalizedScoreService();

  // 选择状态
  List<String> _levelOptions = [];
  List<String> _titleTypeOptions = [];
  List<int> _difficultyOptions = [];

  // 缓存的全量等级选项（用于对话框）
  List<String> _allLevelOptionsCache = [];

  // 种类模式：'level' 等级模式, 'charter' 谱师模式
  String _mode = 'level';

  // 谱师相关
  Map<String, int>? _charterCounts;
  String? _selectedCharter;

  // 版本相关
  String? _selectedVersion;

  // 曲师相关
  Map<String, int>? _artistCounts;
  String? _selectedArtist;

  // 流派相关
  Map<String, int>? _genreCounts;
  String? _selectedGenre;

  String? _selectedLevel;
  String? _selectedTitleType;
  int? _selectedDifficulty;

  bool _isLoading = true;

  // 缓存的歌曲完成状态数据
  List<Map<String, dynamic>>? _cachedSongsWithStatus;
  bool _isSongsLoading = false;
  int _songLoadGeneration = 0;

  // 统计区显示的数字：加载中保留上一次的，新结果到了再滚动过去。
  ({int total, int completed, double average}) _summary =
      (total: 0, completed: 0, average: 0.0);

  bool get _loadingSongs => _isLoading || _isSongsLoading;


  // 显示模式：true 为列表模式，false 为仅曲绘模式
  bool _showListMode = true;

  // 分割线显示模式：true 使用等级显示（如 14, 14+），false 显示定数（如 14.0, 14.5）
  bool _useLevelDisplay = true;

  // 过滤模式：'all' 全部, 'completed' 已完成, 'uncompleted' 未完成
  String _filterMode = 'all';

  // 尺寸参数
  late double _textSizeM;
  late double _scaleFactor;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // 初始化数据
  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _titleTypeOptions = _service.getTitleTypeOptions();
      _difficultyOptions = _service.getDifficultyOptions();

      // 获取保存的用户选项
      final savedOptions = await _service.getSavedOptions();

      // 设置保存的选项，如果有效则使用，否则使用默认值
      if (_titleTypeOptions.isNotEmpty) {
        final savedTitleType = savedOptions['titleType'] as String;
        _selectedTitleType = _titleTypeOptions.contains(savedTitleType) &&
                savedTitleType.isNotEmpty
            ? savedTitleType
            : _titleTypeOptions[0];
      }
      if (_difficultyOptions.isNotEmpty) {
        final savedDifficulty = savedOptions['difficulty'] as int;
        _selectedDifficulty =
            _difficultyOptions.contains(savedDifficulty) ? savedDifficulty : -1;
      }

      // 获取全量等级选项并缓存
      _allLevelOptionsCache = await _service.getAllLevelOptions();

      // 获取谱师列表
      _charterCounts = await _service.getCharterCounts();

      // 获取曲师列表
      _artistCounts = await _service.getArtistCounts();

      // 更新等级选项
      await _updateLevelOptions();
      // 设置保存的等级选项
      if (_levelOptions.isNotEmpty) {
        final savedLevel = savedOptions['level'] as String;
        _selectedLevel =
            _levelOptions.contains(savedLevel) && savedLevel.isNotEmpty
                ? savedLevel
                : _levelOptions[0];
      }

      // 设置保存的模式
      final savedMode = savedOptions['mode'] as String;
      _mode =
          ['level', 'charter', 'version', 'artist', 'genre'].contains(savedMode)
              ? savedMode
              : 'level';

      // 设置保存的谱师（如果谱师存在）
      final savedCharter = savedOptions['charter'] as String;
      if (savedCharter.isNotEmpty &&
          _charterCounts != null &&
          _charterCounts!.containsKey(savedCharter)) {
        _selectedCharter = savedCharter;
      } else if (_charterCounts != null && _charterCounts!.isNotEmpty) {
        _selectedCharter = _charterCounts!.keys.first;
      }

      // 设置保存的版本
      final savedVersion = savedOptions['version'] as String;
      if (savedVersion.isNotEmpty &&
          VersionListConstant.standardVersions.contains(savedVersion)) {
        _selectedVersion = savedVersion;
      } else if (VersionListConstant.standardVersions.isNotEmpty) {
        _selectedVersion = VersionListConstant.standardVersions.first;
      }

      // 设置保存的曲师
      final savedArtist = savedOptions['artist'] as String;
      if (savedArtist.isNotEmpty &&
          _artistCounts != null &&
          _artistCounts!.containsKey(savedArtist)) {
        _selectedArtist = savedArtist;
      } else if (_artistCounts != null && _artistCounts!.isNotEmpty) {
        _selectedArtist = _artistCounts!.keys.first;
      }

      // 获取流派列表
      _genreCounts = await _service.getGenreCounts();

      // 设置保存的流派
      final savedGenre = savedOptions['genre'] as String;
      if (savedGenre.isNotEmpty &&
          _genreCounts != null &&
          _genreCounts!.containsKey(savedGenre)) {
        _selectedGenre = savedGenre;
      } else if (_genreCounts != null && _genreCounts!.isNotEmpty) {
        _selectedGenre = _genreCounts!.keys.first;
      }

      // 设置保存的显示模式
      _showListMode = savedOptions['showListMode'] as bool;
      _useLevelDisplay = savedOptions['useLevelDisplay'] as bool;

      // 加载歌曲完成状态数据
      await _loadSongsWithStatus();
    } catch (e) {
      debugPrint('初始化数据时出错: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 持久化保存当前所有选项到 SharedPreferences
  void _saveOptions() {
    _service.saveSelectedOptions(
      level: _selectedLevel,
      titleType: _selectedTitleType,
      difficulty: _selectedDifficulty,
      showListMode: _showListMode,
      useLevelDisplay: _useLevelDisplay,
      mode: _mode,
      charter: _selectedCharter,
      version: _selectedVersion,
      artist: _selectedArtist,
      genre: _selectedGenre,
    );
  }

  @override
  void dispose() {
    _saveOptions();
    super.dispose();
  }

  // 更新等级选项
  Future<void> _updateLevelOptions() async {
    if (_selectedDifficulty == null) {
      return;
    }

    List<String> newLevelOptions;

    // ALL模式下使用全量等级选项
    if (_selectedDifficulty == -1) {
      newLevelOptions = _allLevelOptionsCache;
    } else {
      newLevelOptions = await _service.getLevelOptions(_selectedDifficulty!);
    }

    setState(() {
      _levelOptions = newLevelOptions;
    });
  }

  // 加载歌曲完成状态（带缓存）
  Future<void> _loadSongsWithStatus() async {
    if (_selectedTitleType == null || _selectedDifficulty == null) {
      if (_isSongsLoading && mounted) setState(() => _isSongsLoading = false);
      return;
    }

    final generation = ++_songLoadGeneration;
    setState(() {
      _isSongsLoading = true;
    });

    try {
      // 清除记录缓存，确保每次变更筛选条件都重新加载最新游玩数据
      _service.clearRecordsCache();

      List<Map<String, dynamic>> result;

      if (_mode == 'level') {
        if (_selectedLevel == null) return;
        result = await _service.getSongsByLevel(
          _selectedLevel!,
          _selectedTitleType!,
          _selectedDifficulty!,
        );
      } else if (_mode == 'version') {
        if (_selectedVersion == null) return;
        result = await _service.getSongsByVersion(
          _selectedVersion!,
          _selectedTitleType!,
          _selectedDifficulty!,
        );
      } else if (_mode == 'artist') {
        if (_selectedArtist == null) return;
        result = await _service.getSongsByArtist(
          _selectedArtist!,
          _selectedTitleType!,
          _selectedDifficulty!,
        );
      } else if (_mode == 'genre') {
        if (_selectedGenre == null) return;
        result = await _service.getSongsByGenre(
          _selectedGenre!,
          _selectedTitleType!,
          _selectedDifficulty!,
        );
      } else {
        // 谱师模式
        if (_selectedCharter == null) return;
        result = await _service.getSongsByCharter(
          _selectedCharter!,
          _selectedTitleType!,
          _selectedDifficulty!,
        );
      }

      if (!mounted || generation != _songLoadGeneration) return;
      setState(() {
        _cachedSongsWithStatus = result;
      });
    } catch (e) {
      if (!mounted || generation != _songLoadGeneration) return;
      setState(() {
        _cachedSongsWithStatus = null;
      });
    } finally {
      if (mounted && generation == _songLoadGeneration) {
        setState(() {
          _isSongsLoading = false;
        });
      }
    }
  }

  // 获取难度显示名称
  String _getDifficultyName(int difficulty) {
    return _service.getDifficultyName(difficulty);
  }

  // 根据定数获取等级显示（精确到0.1）
  String _getDsLevelDisplay(double ds) {
    return ds.toStringAsFixed(1);
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

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // 初始化尺寸参数
    final screenWidth = MediaQuery.of(context).size.width;
    _scaleFactor = screenWidth / 375.0;
    _textSizeM = 12.0 * _scaleFactor;

    return BackgroundPageScaffold(
      title: '个性化成绩查询',
      resizeToAvoidBottomInset: false,
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppDesignTokens.gutter, 8, AppDesignTokens.gutter, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 选择区域
                  _buildSelectionSection(),

                  const SizedBox(height: 10),

                  // 导出为图片按钮
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('导出为图片'),
                    onPressed: () async {
                      debugPrint(
                          '=== PERSONALIZED SCORE EXPORT BUTTON CLICKED ===');
                      try {
                        await _exportToImage();
                      } catch (e) {
                        debugPrint('Error in export: $e');
                      }
                    },
                  ),

                  const SizedBox(height: AppDesignTokens.cardGap),
                ],
              ),
            ),
          ),

          // 曲绘和完成情况显示区域
          if (_loadingSongs || _cachedSongsWithStatus?.isNotEmpty == true)
            _boxSliver(_buildSummarySection()),
          ProgressSliverFade(
            key: ValueKey(
                _loadingSongs ? 'loading' : 'done-$_songLoadGeneration'),
            sliver: SliverMainAxisGroup(slivers: _buildSongSlivers()),
          ),
          const SliverToBoxAdapter(
              child: SizedBox(height: AppDesignTokens.gutter)),
        ],
      ),
    );
  }

  Widget _boxSliver(Widget child) => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.gutter),
        sliver: SliverToBoxAdapter(child: child),
      );

  // 构建选择区域
  Widget _buildSelectionSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 选择种类
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ProgressFieldLabel('种类'),
                    ProgressPickerField(
                      value: _mode == 'level'
                          ? '等级'
                          : _mode == 'charter'
                              ? '谱师'
                              : _mode == 'version'
                                  ? '版本'
                                  : _mode == 'genre'
                                      ? '流派'
                                      : '曲师',
                      onTap: () => _showModeDialog(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 选择等级/谱师/版本/曲师/流派
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProgressFieldLabel(
                      _mode == 'level'
                          ? '等级'
                          : _mode == 'charter'
                              ? '谱师'
                              : _mode == 'version'
                                  ? '版本'
                                  : _mode == 'genre'
                                      ? '流派'
                                      : '曲师',
                    ),
                    ProgressPickerField(
                      value: _mode == 'level'
                          ? (_selectedLevel != null
                              ? 'Lv.${_selectedLevel}'
                              : '请选择等级')
                          : _mode == 'charter'
                              ? (_selectedCharter != null
                                  ? _selectedCharter!
                                  : '请选择谱师')
                              : _mode == 'version'
                                  ? (_selectedVersion != null
                                      ? StringUtil.formatVersion2(
                                          _selectedVersion!)
                                      : '请选择版本')
                                  : _mode == 'genre'
                                      ? (_selectedGenre != null
                                          ? _selectedGenre!
                                          : '请选择流派')
                                      : (_selectedArtist != null
                                          ? _selectedArtist!
                                          : '请选择曲师'),
                      onTap: () {
                        if (_mode == 'level') {
                          _showLevelDialog();
                        } else if (_mode == 'charter') {
                          _showCharterDialog();
                        } else if (_mode == 'version') {
                          _showVersionDialog();
                        } else if (_mode == 'genre') {
                          _showGenreDialog();
                        } else {
                          _showArtistDialog();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 选择称号类型
          const ProgressFieldLabel('称号类型'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _titleTypeOptions.map((type) {
              return ProgressTitlePill(
                label: type,
                selected: _selectedTitleType == type,
                onTap: () async {
                  setState(() {
                    _selectedTitleType = type;
                    _cachedSongsWithStatus = null;
                    _isSongsLoading = true;
                  });
                  await _loadSongsWithStatus();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 选择难度
          const ProgressFieldLabel('难度'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _difficultyOptions.map((diff) {
              return ProgressDifficultyPill(
                difficulty: diff,
                label: _getDifficultyName(diff),
                selected: _selectedDifficulty == diff,
                onTap: () async {
                  setState(() {
                    _selectedDifficulty = diff;
                    _cachedSongsWithStatus = null;
                    _isSongsLoading = true;
                  });
                  await _updateLevelOptions();
                  // 更新选中的等级
                  if (_levelOptions.contains(_selectedLevel)) {
                    // 保持当前选中
                  } else if (_levelOptions.isNotEmpty) {
                    setState(() {
                      _selectedLevel =
                          _levelOptions.isNotEmpty ? _levelOptions[0] : null;
                    });
                  }
                  await _loadSongsWithStatus();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 显示模式选择对话框
  void _showModeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Center(child: Text('选择种类')),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Center(child: Text('等级')),
                  selected: _mode == 'level',
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _mode = 'level';
                      _cachedSongsWithStatus = null;
                      _isSongsLoading = true;
                    });
                    _saveOptions();
                    await _loadSongsWithStatus();
                  },
                ),
                ListTile(
                  title: Center(child: Text('谱师')),
                  selected: _mode == 'charter',
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _mode = 'charter';
                      _cachedSongsWithStatus = null;
                      _isSongsLoading = true;
                    });
                    if (_selectedCharter == null &&
                        _charterCounts != null &&
                        _charterCounts!.isNotEmpty) {
                      setState(() {
                        _selectedCharter = _charterCounts!.keys.first;
                      });
                    }
                    _saveOptions();
                    await _loadSongsWithStatus();
                  },
                ),
                ListTile(
                  title: Center(child: Text('版本')),
                  selected: _mode == 'version',
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _mode = 'version';
                      _cachedSongsWithStatus = null;
                      _isSongsLoading = true;
                    });
                    if (_selectedVersion == null &&
                        VersionListConstant.standardVersions.isNotEmpty) {
                      setState(() {
                        _selectedVersion =
                            VersionListConstant.standardVersions.first;
                      });
                    }
                    _saveOptions();
                    await _loadSongsWithStatus();
                  },
                ),
                ListTile(
                  title: Center(child: Text('曲师')),
                  selected: _mode == 'artist',
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _mode = 'artist';
                      _cachedSongsWithStatus = null;
                      _isSongsLoading = true;
                    });
                    if (_selectedArtist == null &&
                        _artistCounts != null &&
                        _artistCounts!.isNotEmpty) {
                      setState(() {
                        _selectedArtist = _artistCounts!.keys.first;
                      });
                    }
                    _saveOptions();
                    await _loadSongsWithStatus();
                  },
                ),
                ListTile(
                  title: Center(child: Text('流派')),
                  selected: _mode == 'genre',
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _mode = 'genre';
                      _cachedSongsWithStatus = null;
                      _isSongsLoading = true;
                    });
                    if (_selectedGenre == null &&
                        _genreCounts != null &&
                        _genreCounts!.isNotEmpty) {
                      setState(() {
                        _selectedGenre = _genreCounts!.keys.first;
                      });
                    }
                    _saveOptions();
                    await _loadSongsWithStatus();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 显示谱师选择对话框
  Future<void> _showCharterDialog() async {
    if (_charterCounts == null || _charterCounts!.isEmpty) {
      showAppNoticeDialog(context, title: '提示', message: '没有找到谱师数据');
      return;
    }

    // 按出现次数排序
    List<MapEntry<String, int>> sortedCharters = _charterCounts!.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 搜索框的 controller 由弹窗自己释放（见 SearchPickerDialog 的说明）：
    // 在这里 `.whenComplete(dispose)` 会在 pop 那一刻就释放，把弹窗的退场动画炸掉。
    final picked = await showSearchPickerDialog(
      context,
      title: '选择谱师',
      hintText: '搜索谱师',
      emptyText: '没有匹配的谱师',
      entries: sortedCharters,
      countSuffix: '谱面',
      selected: _selectedCharter,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedCharter = picked;
      _cachedSongsWithStatus = null;
      _isSongsLoading = true;
    });
    _saveOptions();
    await _loadSongsWithStatus();
  }

  // 显示版本选择对话框
  void _showVersionDialog() {
    final versions = VersionListConstant.versionOrderList;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Center(child: Text('选择版本')),
          content: SingleChildScrollView(
            child: ListBody(
              children: versions.map((version) {
                return ListTile(
                  title:
                      Center(child: Text(StringUtil.formatVersion2(version))),
                  selected: _selectedVersion == version,
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedVersion = version;
                      _cachedSongsWithStatus = null;
                      _isSongsLoading = true;
                    });
                    _saveOptions();
                    await _loadSongsWithStatus();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 显示曲师选择对话框
  Future<void> _showArtistDialog() async {
    if (_artistCounts == null || _artistCounts!.isEmpty) {
      showAppNoticeDialog(context, title: '提示', message: '没有找到曲师数据');
      return;
    }

    // 按出现次数排序
    List<MapEntry<String, int>> sortedArtists = _artistCounts!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 搜索框的 controller 由弹窗自己释放（见 SearchPickerDialog 的说明）：
    // 在这里 `.whenComplete(dispose)` 会在 pop 那一刻就释放，把弹窗的退场动画炸掉。
    final picked = await showSearchPickerDialog(
      context,
      title: '选择曲师',
      hintText: '搜索曲师',
      emptyText: '没有匹配的曲师',
      entries: sortedArtists,
      countSuffix: '首',
      selected: _selectedArtist,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedArtist = picked;
      _cachedSongsWithStatus = null;
      _isSongsLoading = true;
    });
    _saveOptions();
    await _loadSongsWithStatus();
  }

  // 显示流派选择对话框
  void _showGenreDialog() {
    if (_genreCounts == null || _genreCounts!.isEmpty) {
      showAppNoticeDialog(context, title: '提示', message: '没有找到流派数据');
      return;
    }

    // 按出现次数排序
    List<MapEntry<String, int>> sortedGenres = _genreCounts!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Center(child: Text('选择流派')),
          content: SingleChildScrollView(
            child: ListBody(
              children: sortedGenres.map((entry) {
                return ListTile(
                  title: Center(child: Text('${entry.key} (${entry.value}首)')),
                  selected: _selectedGenre == entry.key,
                  onTap: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedGenre = entry.key;
                      _cachedSongsWithStatus = null;
                      _isSongsLoading = true;
                    });
                    _saveOptions();
                    await _loadSongsWithStatus();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 显示等级选择对话框（使用缓存的全量等级选项）
  void _showLevelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Center(child: Text('选择等级')),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: _allLevelOptionsCache.length,
              itemBuilder: (context, index) {
                final level = _allLevelOptionsCache[index];
                return Container(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLevel == level
                          ? Theme.of(context).colorScheme.primary
                          : AppSurfaces.inset(context),
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(4),
                      minimumSize: Size(50, 40),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedLevel = level;
                        _cachedSongsWithStatus = null;
                        _isSongsLoading = true;
                      });
                      _saveOptions();
                      // 更新等级选项（确保当前选中的等级在选项列表中）
                      await _updateLevelOptions();
                      await _loadSongsWithStatus();
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Lv.$level',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedLevel == level
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 构建歌曲列表区域
  /// 按定数分组，组按定数降序。
  List<ProgressSongGroup> _groupSongs(List<Map<String, dynamic>> songs) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in songs) {
      final song = item['song'] as Song;
      final diffIndex = item['difficulty'] as int;
      String dsKey = '未知';
      if (song.ds != null && song.ds.length > diffIndex) {
        dsKey = _useLevelDisplay
            ? _getLevelDisplay(song.ds[diffIndex])
            : _getDsLevelDisplay(song.ds[diffIndex]);
      }
      grouped.putIfAbsent(dsKey, () => []).add(item);
    }

    double parseDs(String ds) {
      if (_useLevelDisplay && ds.endsWith('+')) {
        return double.parse(ds.substring(0, ds.length - 1)) + 0.5;
      }
      return double.tryParse(ds) ?? 0.0;
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) => parseDs(b).compareTo(parseDs(a)));
    return [
      for (final key in keys)
        ProgressSongGroup(
          title: '${_useLevelDisplay ? 'Lv.' : ''}$key',
          items: grouped[key]!,
        ),
    ];
  }

  String get _emptyHint => _mode == 'level'
      ? '当前等级没有匹配的歌曲'
      : _mode == 'charter'
          ? '当前谱师没有匹配的歌曲'
          : _mode == 'version'
              ? '当前版本没有匹配的歌曲'
              : _mode == 'genre'
                  ? '当前流派没有匹配的歌曲'
                  : '当前曲师没有匹配的歌曲';

  /// 统计和展示切换。加载中也留在原位，数字才能滚动变化。
  Widget _buildSummarySection() {
    final songsWithStatus =
        _cachedSongsWithStatus ?? const <Map<String, dynamic>>[];
    if (!_loadingSongs) {
    // 计算完成统计
    final totalCount = songsWithStatus.length;
    final completedCount =
        songsWithStatus.where((item) => item['completed'] as bool).length;

    // 计算平均达成率
    double totalAchievement = 0.0;
    for (final item in songsWithStatus) {
      final song = item['song'] as Song;
      final diff = item['difficulty'] as int;
      if (diff == -1) {
        // ALL模式下取所有符合条件难度的平均达成率
        double songTotalAchievement = 0.0;
        int count = 0;
        for (int i = 0; i < song.ds.length; i++) {
          if (_getLevelDisplay(song.ds[i]) == _selectedLevel) {
            songTotalAchievement +=
                _service.getSongAchievement(int.parse(song.id), i);
            count++;
          }
        }
        if (count > 0) {
          totalAchievement += songTotalAchievement / count;
        }
      } else {
        totalAchievement +=
            _service.getSongAchievement(int.parse(song.id), diff);
      }
    }
    final averageAchievement =
        totalCount > 0 ? totalAchievement / totalCount : 0.0;

      _summary = (
        total: totalCount,
        completed: completedCount,
        average: averageAchievement,
      );
    }

    // 获取难度显示名称
    final difficultyName = _selectedDifficulty == -1
        ? 'ALL'
        : _getDifficultyName(_selectedDifficulty ?? 3);

    // 根据模式获取标题
    String title;
    if (_mode == 'level') {
      title =
          'Lv.${_selectedLevel}(${difficultyName})的${_selectedTitleType}称号统计';
    } else if (_mode == 'charter') {
      title =
          '谱师${_selectedCharter}(${difficultyName})的${_selectedTitleType}称号统计';
    } else if (_mode == 'version') {
      title =
          '版本${StringUtil.formatVersion2(_selectedVersion ?? '')}(${difficultyName})的${_selectedTitleType}称号统计';
    } else if (_mode == 'genre') {
      title =
          '流派${_selectedGenre}(${difficultyName})的${_selectedTitleType}称号统计';
    } else {
      title =
          '曲师${_selectedArtist}(${difficultyName})的${_selectedTitleType}称号统计';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 统计区域
        ProgressSummaryCard(
          title: title,
          total: _summary.total,
          completed: _summary.completed,
          averageAchievement: _summary.average,
        ),
        const SizedBox(height: AppDesignTokens.cardGap),

        // 切换显示模式
        ProgressDisplayControls(
          filterMode: _filterMode,
          useLevelDisplay: _useLevelDisplay,
          showListMode: _showListMode,
          onFilterChanged: (mode) => setState(() => _filterMode = mode),
          onLevelDisplayChanged: (value) =>
              setState(() => _useLevelDisplay = value),
          onListModeChanged: (value) => setState(() => _showListMode = value),
        ),

      ],
    );
  }

  List<Widget> _buildSongSlivers() {
    if (_loadingSongs) {
      return [_boxSliver(const ProgressListSkeleton())];
    }

    // 检查缓存数据
    if (_cachedSongsWithStatus == null || _cachedSongsWithStatus!.isEmpty) {
      return [
        _boxSliver(Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            _emptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _textSizeM,
              color: AppColors.greyHint(Theme.of(context).brightness),
            ),
          ),
        )),
      ];
    }

    final songsWithStatus = _cachedSongsWithStatus!;

    // 根据过滤模式过滤歌曲
    List<Map<String, dynamic>> filteredSongs = songsWithStatus;
    if (_filterMode == 'completed') {
      filteredSongs =
          songsWithStatus.where((item) => item['completed'] as bool).toList();
    } else if (_filterMode == 'uncompleted') {
      filteredSongs = songsWithStatus
          .where((item) => !(item['completed'] as bool))
          .toList();
    }

    return [
      if (filteredSongs.isEmpty)
        _boxSliver(Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              _filterMode == 'completed'
                  ? '暂无已完成歌曲'
                  : _filterMode == 'uncompleted'
                      ? '暂无未完成歌曲'
                      : _emptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )),
      ProgressSongSliver(
        groups: _groupSongs(filteredSongs),
        showListMode: _showListMode,
        rowBuilder: (item, showDivider) =>
            _buildSongRow(item, showDivider: showDivider),
        coverBuilder: (item) => ProgressCoverTile(
          songId: (item['song'] as Song).id,
          // 使用条目自己的难度索引
          levelIndex: item['difficulty'] as int,
          completed: item['completed'] as bool,
          onTap: () =>
              _openSong((item['song'] as Song).id, item['difficulty'] as int),
        ),
      ),
    ];
  }

  /// 列表模式的一行。
  Widget _buildSongRow(Map<String, dynamic> item, {bool showDivider = false}) {
    final song = item['song'] as Song;
    final diffIndex = item['difficulty'] as int;
    final songDs = song.ds != null && song.ds.length > diffIndex
        ? song.ds[diffIndex].toStringAsFixed(1)
        : '';
    return ProgressSongRow(
      songId: song.id,
      title: song.title,
      songType: song.type,
      levelIndex: diffIndex,
      constant: songDs,
      completed: item['completed'] as bool,
      showDivider: showDivider,
      onTap: () => _openSong(song.id, diffIndex),
    );
  }

  void _openSong(String songId, int levelIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongInfoPage(
          songId: songId,
          initialLevelIndex: levelIndex,
        ),
      ),
    );
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    debugPrint('PersonalizedScorePage: _requestStoragePermission called');

    if (Platform.isAndroid) {
      debugPrint('PersonalizedScorePage: Running on Android');

      PermissionStatus storageStatus = await Permission.storage.status;
      PermissionStatus photosStatus = await Permission.photos.status;
      PermissionStatus videosStatus = await Permission.videos.status;

      debugPrint('PersonalizedScorePage: Storage status = $storageStatus');
      debugPrint('PersonalizedScorePage: Photos status = $photosStatus');
      debugPrint('PersonalizedScorePage: Videos status = $videosStatus');

      if (storageStatus.isGranted ||
          photosStatus.isGranted ||
          videosStatus.isGranted) {
        debugPrint(
            'PersonalizedScorePage: At least one permission already granted');
        return true;
      }

      debugPrint(
          'PersonalizedScorePage: Requesting storage, photos and videos permissions...');
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();

      bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      bool videosGranted = statuses[Permission.videos]?.isGranted ?? false;

      debugPrint('PersonalizedScorePage: Storage granted = $storageGranted');
      debugPrint('PersonalizedScorePage: Photos granted = $photosGranted');
      debugPrint('PersonalizedScorePage: Videos granted = $videosGranted');

      return storageGranted || photosGranted || videosGranted;
    } else {
      debugPrint('PersonalizedScorePage: Non-Android platform');
      PermissionStatus status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> _exportToImage() async {
    try {
      debugPrint('=== PERSONALIZED SCORE EXPORT TO IMAGE STARTED ===');
      debugPrint('Current context: $context');

      debugPrint('Step 1: Requesting storage permission from page...');
      bool hasPermission = await _requestStoragePermission();
      debugPrint('Step 1 completed: hasPermission = $hasPermission');

      if (!hasPermission) {
        showAppNoticeDialog(context, title: '权限不足', message: '需要存储权限才能导出图片到相册，请在设置中开启权限', tone: AppDialogTone.warning);
        return;
      }


      final songCount = _cachedSongsWithStatus?.length ?? 0;
      final quality = await ExportQualitySelector.show(
        context,
        estimatedPngSize: ImageEncodeUtil.estimatePngSize(
            songCount: songCount, cardsPerRow: 12),
        exportingLabel: '个性化成绩',
        previewBuilder: (previewContext, previewQuality) =>
            PersonalizedScoreConvertToImg.buildPreviewWidget(
          previewContext,
          theme: previewQuality.theme,
          selectedLevel: _selectedLevel,
          selectedCharter: _selectedCharter,
          selectedVersion: _selectedVersion,
          selectedArtist: _selectedArtist,
          selectedGenre: _selectedGenre,
          mode: _mode,
          selectedTitleType: _selectedTitleType,
          selectedDifficulty: _selectedDifficulty,
          cachedSongsWithStatus: _cachedSongsWithStatus,
          filterMode: _filterMode,
          getDifficultyName: _getDifficultyName,
          getLevelDisplay: _getLevelDisplay,
          getSongAchievement: _service.getSongAchievement,
          useLevelDisplay: _useLevelDisplay,
        ),
      );
      if (quality == null) return;

      BackgroundExport.run(
        label: '个性化成绩',
        task: (exportContext) => PersonalizedScoreConvertToImg.convertToImage(
          exportContext,
        selectedLevel: _selectedLevel,
        selectedCharter: _selectedCharter,
        selectedVersion: _selectedVersion,
        selectedArtist: _selectedArtist,
        selectedGenre: _selectedGenre,
        mode: _mode,
        selectedTitleType: _selectedTitleType,
        selectedDifficulty: _selectedDifficulty,
        cachedSongsWithStatus: _cachedSongsWithStatus,
        filterMode: _filterMode,
        getDifficultyName: _getDifficultyName,
        getLevelDisplay: _getLevelDisplay,
        useLevelDisplay: _useLevelDisplay,
        jpegQuality: quality.jpegQuality,
        theme: quality.theme,
        getSongAchievement: _service.getSongAchievement,
      ),
      );
    } catch (e) {
      AppToast.show('导出失败：$e');
    }
  }
}
