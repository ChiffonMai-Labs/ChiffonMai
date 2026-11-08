import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_first_flutter_app/service/PaiziProgressService.dart';
import 'package:my_first_flutter_app/service/PaiziProgressConvertToImgService.dart';
import 'package:my_first_flutter_app/entity/LuoXue/Collection.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/manager/LuoXue/CollectionsManager.dart';
import 'package:my_first_flutter_app/utils/CollectionsImageUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/page/Collection/CollectionInfoPage.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import '../utils/LuoXueToDivingFishUtil.dart';
import '../utils/SongDetailPreferences.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/ProgressUi.dart';
import '../widgets/AppDialogs.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';
import 'package:my_first_flutter_app/widgets/AppToast.dart';

// 根据 formatVersion2 的顺序定义首字顺序
const List<String> _firstCharOrder = [
  '真',
  '超',
  '檄',
  '橙',
  '暁',
  '桃',
  '櫻',
  '紫',
  '菫',
  '白',
  '雪',
  '輝',
  '熊',
  '華',
  '爽',
  '煌',
  '宙',
  '星',
  '祭',
  '祝',
  '双',
  '宴',
  '镜',
  '彩',
];

class PaiziProgressPage extends StatefulWidget {
  const PaiziProgressPage({super.key});

  @override
  State<PaiziProgressPage> createState() => _PaiziProgressPageState();
}

class _PaiziProgressPageState extends State<PaiziProgressPage> {
  final PaiziProgressService _service = PaiziProgressService();

  // 选择状态
  List<String> _firstCharOptions = [];
  List<String> _titleTypeOptions = [];
  List<int> _difficultyOptions = [];

  String? _selectedFirstChar;
  String? _selectedTitleType;
  int? _selectedDifficulty;

  Collection? _currentPlate;
  bool _isLoading = true;

  // 缓存的歌曲完成状态数据
  List<Map<String, dynamic>>? _cachedSongsWithStatus;
  bool _isSongsLoading = false;
  List<Song> _excludedSongs = [];
  int _songLoadGeneration = 0;

  // 统计区显示的数字：加载中保留上一次的，新结果到了再滚动过去。
  ({int total, int completed, double average}) _summary =
      (total: 0, completed: 0, average: 0.0);

  bool get _loadingSongs => _isLoading || _isSongsLoading;

  // 显示模式：true 为列表模式，false 为仅曲绘模式
  bool _showListMode = true;

  // 分割线显示模式：true 使用 _getLevelDisplay（如 15, 14+），false 直接显示定数（如 15.0, 14.5）
  bool _useLevelDisplay = true;

  // 筛选模式：'all' 全部, 'completed' 已完成, 'uncompleted' 未完成
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
      await SongDetailPreferences.instance.load();
      if (!mounted) return;
      _firstCharOptions = await _service.getFirstCharOptions();

      // 如果首字选项为空，可能是首次启动还未拉取过收藏品数据，
      // 或缓存损坏（API 调用失败时写入了空数据）。
      // 主动从网络拉取四种收藏品并写入缓存，再重新读取首字选项。
      if (_firstCharOptions.isEmpty) {
        debugPrint('牌子进度：首字选项为空，主动拉取四种收藏品数据');
        await CollectionsManager().refreshAllCollections();
        _firstCharOptions = await _service.getFirstCharOptions();
      }

      _titleTypeOptions = _service.getTitleTypeOptions(
          firstChar:
              _firstCharOptions.isNotEmpty ? _firstCharOptions[0] : null);

      // 获取保存的用户选项
      final savedOptions = await _service.getSavedOptions();

      // 设置保存的选项，如果有效则使用，否则使用默认值
      if (_firstCharOptions.isNotEmpty) {
        final savedFirstChar = savedOptions['firstChar'] as String;
        _selectedFirstChar = _firstCharOptions.contains(savedFirstChar) &&
                savedFirstChar.isNotEmpty
            ? savedFirstChar
            : (_firstCharOptions.contains('真') ? '真' : _firstCharOptions[0]);
      }

      // 根据选中的首字更新称号类型选项（确保正确显示霸者按钮）
      _titleTypeOptions =
          _service.getTitleTypeOptions(firstChar: _selectedFirstChar);

      if (_titleTypeOptions.isNotEmpty) {
        final savedTitleType = savedOptions['titleType'] as String;
        _selectedTitleType = _titleTypeOptions.contains(savedTitleType) &&
                savedTitleType.isNotEmpty
            ? savedTitleType
            : _titleTypeOptions[0];
      }

      // 更新难度选项
      await _updateDifficultyOptions();

      // 设置保存的难度选项
      final savedDifficulty = savedOptions['difficulty'] as int;
      if (_difficultyOptions.contains(savedDifficulty)) {
        _selectedDifficulty = savedDifficulty;
      }

      // 设置保存的显示模式
      _showListMode = savedOptions['showListMode'] as bool;
      _useLevelDisplay = savedOptions['useLevelDisplay'] as bool;

      // 设置保存的筛选模式
      final savedFilterMode = savedOptions['filterMode'] as String;
      _filterMode =
          ['all', 'completed', 'uncompleted'].contains(savedFilterMode)
              ? savedFilterMode
              : 'all';

      await _loadCurrentPlate();
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

  @override
  void dispose() {
    // 保存用户选择的选项
    _service.saveSelectedOptions(
      firstChar: _selectedFirstChar,
      titleType: _selectedTitleType,
      difficulty: _selectedDifficulty,
      showListMode: _showListMode,
      useLevelDisplay: _useLevelDisplay,
      filterMode: _filterMode,
    );
    super.dispose();
  }

  // 更新难度选项
  Future<void> _updateDifficultyOptions() async {
    if (_selectedFirstChar != null && _selectedTitleType != null) {
      final newDifficultyOptions = await _service.getAvailableDifficulties(
        _selectedFirstChar!,
        _selectedTitleType!,
      );

      // 保存当前选中的难度
      final currentDifficulty = _selectedDifficulty;

      _difficultyOptions = newDifficultyOptions;

      // 如果当前选中的难度仍然在新列表中，则保持选中；否则选择第一个
      if (_difficultyOptions.isNotEmpty) {
        if (currentDifficulty != null &&
            _difficultyOptions.contains(currentDifficulty)) {
          _selectedDifficulty = currentDifficulty;
        } else {
          _selectedDifficulty = _difficultyOptions[0];
        }
      }
    }
  }

  // 加载当前选中的收藏品
  Future<void> _loadCurrentPlate() async {
    if (_selectedFirstChar != null && _selectedTitleType != null) {
      final firstChar = _selectedFirstChar, titleType = _selectedTitleType;
      final plate = await _service.getPlateBySelection(
        _selectedFirstChar!,
        _selectedTitleType!,
      );
      if (!mounted ||
          firstChar != _selectedFirstChar ||
          titleType != _selectedTitleType) return;
      setState(() {
        _currentPlate = plate;
      });
    }
  }

  // 加载歌曲完成状态（带缓存）
  Future<void> _loadSongsWithStatus() async {
    if (_selectedFirstChar == null ||
        _selectedTitleType == null ||
        _selectedDifficulty == null) {
      if (_isSongsLoading && mounted) setState(() => _isSongsLoading = false);
      return;
    }

    final generation = ++_songLoadGeneration;
    final plate = _currentPlate;
    setState(() {
      _excludedSongs = [];
      _isSongsLoading = true;
    });

    try {
      final result = await _service.getSongsWithCompletionStatus(
        _selectedFirstChar!,
        _selectedTitleType!,
        _selectedDifficulty!,
      );
      final excluded = plate == null
          ? <Song>[]
          : await LuoXueToDivingFishUtil.getConditionExcludedSongs(plate);
      if (!mounted || generation != _songLoadGeneration) return;
      setState(() {
        _excludedSongs = excluded;
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

  // 根据定数计算等级显示
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
      title: context.l10n.featureVersionTitleProgress,
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
                    label: Text(context.l10n.flowExportAsImage),
                    onPressed: () async {
                      debugPrint('=== PAIZI EXPORT BUTTON CLICKED ===');
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
          // 第一个选择：第一个字（点击弹出对话框）
          ProgressFieldLabel(context.l10n.flowFirstCharacter),
          ProgressPickerField(
            value: _selectedFirstChar ?? context.l10n.flowSelectAFirstCharacter,
            onTap: () => _showFirstCharDialog(),
          ),
          const SizedBox(height: 12),

          // 第二个选择：称号类型
          ProgressFieldLabel(context.l10n.flowTitleType),
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
                    _cachedSongsWithStatus = null; // 清空缓存
                    _isSongsLoading = true;
                  });
                  await _updateDifficultyOptions();
                  await _loadCurrentPlate();
                  await _loadSongsWithStatus(); // 加载新数据
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // 第三个选择：难度
          ProgressFieldLabel(context.l10n.flowDifficulty),
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
                    _cachedSongsWithStatus = null; // 清空缓存
                    _isSongsLoading = true;
                  });
                  await _loadSongsWithStatus(); // 加载新数据
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 获取按顺序排列的首字选项（"舞"始终置于最后）
  List<String> _getOrderedFirstCharOptions() {
    // 按照 formatVersion2 的顺序排列
    final ordered = <String>[];
    for (final char in _firstCharOrder) {
      if (_firstCharOptions.contains(char)) {
        ordered.add(char);
      }
    }
    // 添加不在顺序列表中的其他首字
    for (final char in _firstCharOptions) {
      if (!ordered.contains(char) && char != '舞') {
        ordered.add(char);
      }
    }
    // 将"舞"始终置于最后
    if (_firstCharOptions.contains('舞')) {
      ordered.add('舞');
    }
    return ordered;
  }

  // 显示首字选择对话框
  void _showFirstCharDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Center(child: Text(context.l10n.flowSelectFirstCharacter)),
          content: Container(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 2.0,
              ),
              itemCount: _getOrderedFirstCharOptions().length,
              itemBuilder: (context, index) {
                final char = _getOrderedFirstCharOptions()[index];
                return Container(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedFirstChar == char
                          ? Theme.of(context).colorScheme.primary
                          : AppSurfaces.inset(context),
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(4),
                      minimumSize: Size(50, 50),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedFirstChar = char;
                        _cachedSongsWithStatus = null; // 清空缓存
                        _isSongsLoading = true;
                        // 更新称号类型选项
                        _titleTypeOptions =
                            _service.getTitleTypeOptions(firstChar: char);
                        // 如果当前选中的称号类型不在新选项中，重置为第一个选项
                        if (_selectedTitleType != null &&
                            !_titleTypeOptions.contains(_selectedTitleType)) {
                          _selectedTitleType = _titleTypeOptions.isNotEmpty
                              ? _titleTypeOptions[0]
                              : null;
                        }
                      });
                      await _updateDifficultyOptions();
                      await _loadCurrentPlate();
                      await _loadSongsWithStatus(); // 加载新数据
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        char,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _selectedFirstChar == char
                              ? Theme.of(context).colorScheme.onPrimary
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

  void _openSong(String songId, int? levelIndex) {
    FocusManager.instance.primaryFocus?.unfocus();
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

  Widget _buildProgressSongCard(Map<String, dynamic> item,
      {bool excluded = false, bool showDivider = false}) {
    final dynamic song = item['song'];
    final isCompleted = item['completed'] as bool;

    // 获取歌曲ID（支持 Song 和 CollectionRequiredSong）
    String songId;
    String songTitle;
    String songType;
    String songDs = '';
    final initialLevelIndex = item['usesDefaultDifficulty'] == true
        ? null
        : ChartDifficulty.parseStandardIndex(item['difficulty']) ??
            ChartDifficulty.parseStandardIndex(_selectedDifficulty);
    if (song is Song) {
      songId = song.id;
      songTitle = song.title;
      songType = song.type;
      // 获取当前难度对应的定数
      final diffIndex = item['difficulty'] as int;
      if (song.ds != null && song.ds.length > diffIndex) {
        songDs = song.ds[diffIndex].toStringAsFixed(1);
      }
    } else if (song is CollectionRequiredSong) {
      songId = song.id.toString();
      songTitle = song.title;
      songType = song.type;
    } else {
      songId = '';
      songTitle = context.l10n.flowUnknown;
      songType = '';
    }

    return ProgressSongRow(
      songId: songId,
      title: songTitle,
      songType: songType,
      levelIndex:
          initialLevelIndex ?? SongDetailPreferences.instance.difficulty,
      constant: songDs,
      completed: isCompleted,
      excluded: excluded,
      showDivider: showDivider,
      onTap: () => _openSong(songId, initialLevelIndex),
    );
  }

  Widget _buildProgressCoverCard(Map<String, dynamic> item) {
    final dynamic song = item['song'];

    String songId = '';
    final initialLevelIndex = item['usesDefaultDifficulty'] == true
        ? null
        : ChartDifficulty.parseStandardIndex(item['difficulty']) ??
            ChartDifficulty.parseStandardIndex(_selectedDifficulty);
    if (song is Song) {
      songId = song.id;
    } else if (song is CollectionRequiredSong) {
      songId = song.id.toString();
    }

    return ProgressCoverTile(
      songId: songId,
      levelIndex:
          initialLevelIndex ?? SongDetailPreferences.instance.difficulty,
      completed: item['completed'] as bool,
      onTap: () => _openSong(songId, initialLevelIndex),
    );
  }

  Widget _buildExcludedSongSection() {
    // 条件外曲目每首展示一次，随页面切换列表 / 曲绘模式，不混入完成率统计。
    final items = _excludedSongs.map((song) {
      final selected = _selectedDifficulty;
      final preferred = selected == null || selected < 0
          ? SongDetailPreferences.instance.difficulty
          : selected;
      final difficulty =
          song.ds.isEmpty ? 0 : preferred.clamp(0, song.ds.length - 1).toInt();
      return <String, dynamic>{
        'song': song,
        'difficulty': difficulty,
        'usesDefaultDifficulty': selected == null || selected < 0,
        'completed': false
      };
    }).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        AppSectionHeader(
          title: context.l10n.flowExcludedSongs,
          subtitle: context.l10n
              .flowP0SongsExcludedFromPlateProgress((items.length).toString()),
        ),
        if (_showListMode)
          AppCard(
            padding: EdgeInsets.zero,
            radius: AppDesignTokens.radiusMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++)
                  _buildProgressSongCard(items[i],
                      excluded: true, showDivider: i > 0),
              ],
            ),
          )
        else
          ProgressCoverGrid(
            children: [
              for (final item in items) _buildProgressCoverCard(item),
            ],
          ),
      ],
    );
  }

  /// 按等级 / 定数分组，组和组内都按定数降序。
  List<ProgressSongGroup> _groupSongs(List<Map<String, dynamic>> songs) {
    double dsOf(Map<String, dynamic> item) {
      final dynamic song = item['song'];
      final diffIndex = item['difficulty'] as int;
      if (song is Song && song.ds != null && song.ds.length > diffIndex) {
        return song.ds[diffIndex];
      }
      return 0.0;
    }

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in songs) {
      final dynamic song = item['song'];
      final diffIndex = item['difficulty'] as int;
      String levelKey = context.l10n.flowUnknown;
      if (song is Song && song.ds != null && song.ds.length > diffIndex) {
        final ds = song.ds[diffIndex];
        // 根据显示模式选择分组方式
        levelKey =
            _useLevelDisplay ? _getLevelDisplay(ds) : ds.toStringAsFixed(1);
      }
      grouped.putIfAbsent(levelKey, () => []).add(item);
    }

    double parseLevel(String level) {
      if (_useLevelDisplay && level.endsWith('+')) {
        return double.parse(level.substring(0, level.length - 1)) + 0.5;
      }
      return double.tryParse(level) ?? 0.0;
    }

    final keys = grouped.keys.toList()
      ..sort((a, b) => parseLevel(b).compareTo(parseLevel(a)));
    return [
      for (final key in keys)
        ProgressSongGroup(
          title: '${_useLevelDisplay ? 'Lv.' : ''}$key',
          items: grouped[key]!..sort((a, b) => dsOf(b).compareTo(dsOf(a))),
        ),
    ];
  }

  /// 牌子信息、统计和展示切换。加载中也留在原位，数字才能滚动变化。
  Widget _buildSummarySection() {
    final songsWithStatus =
        _cachedSongsWithStatus ?? const <Map<String, dynamic>>[];
    if (!_loadingSongs) {
      // 计算统计数据
      final totalCount = songsWithStatus.length;
      final completedCount =
          songsWithStatus.where((item) => item['completed'] as bool).length;

      // 计算平均达成率
      double totalAchievement = 0.0;
      for (final item in songsWithStatus) {
        final dynamic song = item['song'];
        final diff = item['difficulty'] as int;
        if (song is Song) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 当前牌子：图片（可点击跳转）+ 名称
        if (_currentPlate != null) ...[
          AppCard(
            child: Column(
              children: [
                // 真将和真大将不显示图片
                if (!(_selectedFirstChar == '真' &&
                    (_selectedTitleType == '将' ||
                        _selectedTitleType == '大将'))) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CollectionInfoPage(
                            collectionId: _currentPlate!.id,
                            collectionType: 'plates',
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 280 * _scaleFactor,
                      height: 140 * _scaleFactor,
                      child:
                          CollectionsImageUtil.getPlateImageURL(_currentPlate!),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // 收藏品名称
                Text(
                  _selectedFirstChar == '真' &&
                          (_selectedTitleType == '将' ||
                              _selectedTitleType == '大将')
                      ? '${_selectedFirstChar}${_selectedTitleType}'
                      : _currentPlate!.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignTokens.cardGap),
        ],

        // 统计区域
        ProgressSummaryCard(
          title: context.l10n.flowP0P1P2Statistics(
              (_selectedFirstChar).toString(),
              (_selectedTitleType).toString(),
              (_getDifficultyName(_selectedDifficulty ?? 3)).toString()),
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

  // 构建歌曲列表区域
  List<Widget> _buildSongSlivers() {
    if (_loadingSongs) {
      return [_boxSliver(const ProgressListSkeleton())];
    }

    Widget emptyHint(String text) => _boxSliver(Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _textSizeM,
              color: AppColors.greyHint(Theme.of(context).brightness),
            ),
          ),
        ));

    if (_currentPlate == null ||
        _currentPlate!.required == null ||
        _currentPlate!.required!.isEmpty) {
      return [emptyHint(context.l10n.flowNoData)];
    }

    // 检查缓存数据
    if (_cachedSongsWithStatus == null || _cachedSongsWithStatus!.isEmpty) {
      return [emptyHint(context.l10n.flowNoSongsMatchThisDifficulty)];
    }

    final songsWithStatus = _cachedSongsWithStatus!;

    // 根据筛选模式过滤歌曲
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
      ProgressSongSliver(
        groups: _groupSongs(filteredSongs),
        showListMode: _showListMode,
        rowBuilder: (item, showDivider) =>
            _buildProgressSongCard(item, showDivider: showDivider),
        coverBuilder: _buildProgressCoverCard,
      ),
      if (_currentPlate != null) _boxSliver(_buildExcludedSongSection()),
    ];
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    debugPrint('PaiziProgressPage: _requestStoragePermission called');

    if (Platform.isAndroid) {
      debugPrint('PaiziProgressPage: Running on Android');

      PermissionStatus storageStatus = await Permission.storage.status;
      PermissionStatus photosStatus = await Permission.photos.status;
      PermissionStatus videosStatus = await Permission.videos.status;

      debugPrint('PaiziProgressPage: Storage status = $storageStatus');
      debugPrint('PaiziProgressPage: Photos status = $photosStatus');
      debugPrint('PaiziProgressPage: Videos status = $videosStatus');

      if (storageStatus.isGranted ||
          photosStatus.isGranted ||
          videosStatus.isGranted) {
        debugPrint(
            'PaiziProgressPage: At least one permission already granted');
        return true;
      }

      debugPrint(
          'PaiziProgressPage: Requesting storage, photos and videos permissions...');
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();

      bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      bool videosGranted = statuses[Permission.videos]?.isGranted ?? false;

      debugPrint('PaiziProgressPage: Storage granted = $storageGranted');
      debugPrint('PaiziProgressPage: Photos granted = $photosGranted');
      debugPrint('PaiziProgressPage: Videos granted = $videosGranted');

      return storageGranted || photosGranted || videosGranted;
    } else {
      debugPrint('PaiziProgressPage: Non-Android platform');
      PermissionStatus status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  Future<void> _exportToImage() async {
    try {
      debugPrint('=== PAIZI EXPORT TO IMAGE STARTED ===');
      debugPrint('Current context: $context');

      debugPrint('Step 1: Requesting storage permission from page...');
      bool hasPermission = await _requestStoragePermission();
      debugPrint('Step 1 completed: hasPermission = $hasPermission');

      if (!hasPermission) {
        showAppNoticeDialog(context,
            title: context.l10n.flowPermissionRequired,
            message: context.l10n.flowStoragePermissionIsRequiredToExportImages,
            tone: AppDialogTone.warning);
        return;
      }

      final songCount = _cachedSongsWithStatus?.length ?? 0;
      final quality = await ExportQualitySelector.show(
        context,
        estimatedPngSize: ImageEncodeUtil.estimatePngSize(
            songCount: songCount, cardsPerRow: 12),
        exportingLabel: context.l10n.featureVersionTitleProgress,
        previewBuilder: (previewContext, previewQuality) =>
            PaiziProgressConvertToImg.buildPreviewWidget(
          previewContext,
          theme: previewQuality.theme,
          currentPlate: _currentPlate,
          cachedSongsWithStatus: _cachedSongsWithStatus,
          selectedFirstChar: _selectedFirstChar,
          selectedTitleType: _selectedTitleType,
          selectedDifficulty: _selectedDifficulty,
          useLevelDisplay: _useLevelDisplay,
          filterMode: _filterMode,
          getDifficultyName: _getDifficultyName,
          getLevelDisplay: _getLevelDisplay,
          getSongAchievement: _service.getSongAchievement,
        ),
      );
      if (quality == null) return;

      BackgroundExport.run(
        label: context.l10n.featureVersionTitleProgress,
        task: (exportContext) => PaiziProgressConvertToImg.convertToImage(
          exportContext,
          currentPlate: _currentPlate,
          cachedSongsWithStatus: _cachedSongsWithStatus,
          selectedFirstChar: _selectedFirstChar,
          selectedTitleType: _selectedTitleType,
          selectedDifficulty: _selectedDifficulty,
          useLevelDisplay: _useLevelDisplay,
          filterMode: _filterMode,
          getDifficultyName: _getDifficultyName,
          getLevelDisplay: _getLevelDisplay,
          getSongAchievement: _service.getSongAchievement,
          jpegQuality: quality.jpegQuality,
          theme: quality.theme,
        ),
      );
    } catch (e) {
      AppToast.show(context.l10n.flowExportFailedP02((e).toString()),
          tone: AppToastTone.error);
    }
  }
}
