import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import '../widgets/EmptyState.dart';
import '../widgets/NumberStepper.dart';
import '../widgets/DifficultyConstantLabel.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/service/RandomChartService.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import '../widgets/BackgroundPageScaffold.dart';
import '../widgets/RandomChartRollingResults.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppUi.dart';
import '../widgets/MarqueeText.dart';
import '../widgets/ProgressUi.dart';
import '../widgets/RecommendUi.dart';
import '../utils/AppTheme.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';

class RandomChartPage extends StatefulWidget {
  const RandomChartPage({super.key});

  @override
  State<RandomChartPage> createState() => _RandomChartPageState();
}

class _RandomChartPageState extends State<RandomChartPage> {
  final RandomChartService _service = RandomChartService();

  // 状态变量
  bool _isDrawing = false;
  bool _isRolling = false;
  List<Song> _pendingSongs = const [];
  List<Song> _previewCandidates = const [];
  bool _isApplyingPreset = false;
  int _drawRequest = 0;
  int _presetRequest = 0;
  int _resultRevision = 0;
  String _emptyMessage = '选好条件后，开始抽歌吧';
  List<Song> _drawnSongs = [];
  List<List<Song>> _history = [];

  // 筛选条件
  int _drawCount = RandomChartService.masterPresetCount;
  late final TextEditingController _drawCountController;
  String? _drawCountError;
  final List<DateTime> _historyTimes = [];

  @override
  void dispose() {
    _drawRequest++;
    _presetRequest++;
    _minDsController.dispose();
    _maxDsController.dispose();
    _drawCountController.dispose();
    super.dispose();
  }

  double? _minDs;
  double? _maxDs;
  List<String> _selectedVersions = [];
  List<String> _selectedGenres = [];
  bool _requireMaster = false;
  bool _excludeSixDigitId = false;

  // 版本和流派列表
  List<String> _versionList = [];
  List<String> _genreList = [];
  Future<void>? _filterOptionsLoading;

  // 输入控制器
  final TextEditingController _minDsController = TextEditingController();
  final TextEditingController _maxDsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _drawCountController = TextEditingController(text: '$_drawCount');
    _loadFilterOptions();
  }

  void _onDrawCountChanged(String raw) {
    final count = int.tryParse(raw);
    setState(() {
      if (count == null) {
        _drawCountError = '请输入 2–100 之间的整数';
      } else if (count < RandomChartService.minimumDrawCount ||
          count > RandomChartService.maximumDrawCount) {
        _drawCountError = '抽取数量需在 2–100 之间';
      } else {
        _drawCount = count;
        _drawCountError = null;
      }
    });
  }

  void _setDrawCount(int value) {
    final count = value.clamp(RandomChartService.minimumDrawCount,
        RandomChartService.maximumDrawCount);
    _drawCountController.value = TextEditingValue(
      text: '$count',
      selection: TextSelection.collapsed(offset: '$count'.length),
    );
    setState(() {
      _drawCount = count;
      _drawCountError = null;
    });
  }

  // 加载版本和流派列表
  Future<void> _loadFilterOptions() async {
    if (_filterOptionsLoading != null) return _filterOptionsLoading!;
    _filterOptionsLoading = () async {
      try {
        final results = await Future.wait([
          _service.getVersionList(),
          _service.getGenreList(),
        ]);
        if (!mounted) return;
        setState(() {
          _versionList = results[0];
          _genreList = results[1];
        });
      } catch (e) {
        debugPrint('[RandomChartPage] 筛选列表加载失败: $e');
      } finally {
        _filterOptionsLoading = null;
      }
    }();
    return _filterOptionsLoading!;
  }

  Future<void> _applyMasterPreset({required bool advanced}) async {
    if (_isDrawing || _isApplyingPreset) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final request = ++_presetRequest;
    setState(() => _isApplyingPreset = true);
    try {
      if (_versionList.isEmpty || _genreList.isEmpty) {
        await _loadFilterOptions();
      }
      if (!mounted || request != _presetRequest) return;
      setState(() {
        _drawCount = RandomChartService.masterPresetCount;
        _drawCountController.text = '$_drawCount';
        _drawCountError = null;
        _minDsController.text = advanced ? '14.5' : '13.2';
        _maxDsController.text = advanced ? '14.9' : '14.4';
        _requireMaster = true;
        _excludeSixDigitId = true;
        _selectedVersions = List.from(_versionList);
        _selectedGenres = _genreList.where((genre) => genre != '宴会场').toList();
      });
    } finally {
      if (mounted && request == _presetRequest) {
        setState(() => _isApplyingPreset = false);
      }
    }
  }

  // 开始时确定本轮结果，轮播期间保持参数锁定，按停后才提交历史。
  Future<void> _drawSongs() async {
    if (_isDrawing || _isApplyingPreset) return;
    if (_drawCountError != null ||
        _drawCount < RandomChartService.minimumDrawCount ||
        _drawCount > RandomChartService.maximumDrawCount) {
      setState(() => _drawCountError = '抽取数量需在 2–100 之间');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final request = ++_drawRequest;
    final count = _drawCount;
    final versions = List<String>.from(_selectedVersions);
    final genres = List<String>.from(_selectedGenres);
    var candidates = <Song>[];
    setState(() => _isDrawing = true);
    try {
      _minDs = double.tryParse(_minDsController.text);
      _maxDs = double.tryParse(_maxDsController.text);
      final songs = await _service.randomDrawSongs(
        count: count,
        minDs: _minDs,
        maxDs: _maxDs,
        versions: versions.isEmpty ? null : versions,
        genres: genres.isEmpty ? null : genres,
        requireMaster: _requireMaster,
        excludeSixDigitId: _excludeSixDigitId,
        onPreviewCandidates: (value) => candidates = value,
      );
      if (!mounted ||
          request != _drawRequest ||
          ModalRoute.of(context)?.isCurrent != true) return;
      setState(() {
        _pendingSongs = songs;
        _previewCandidates = List<Song>.of(candidates)..shuffle();
        _isRolling = songs.isNotEmpty;
        _resultRevision++;
        if (songs.isEmpty) {
          _drawnSongs = const [];
          _emptyMessage = '没有符合条件的歌曲，请调整筛选条件';
        }
      });
    } catch (error) {
      if (mounted && request == _drawRequest) {
        AppToast.show('抽取失败：$error');
      }
    } finally {
      if (mounted && request == _drawRequest && !_isRolling) {
        setState(() => _isDrawing = false);
      }
    }
  }

  void _stopDraw() {
    if (!_isRolling) return;
    setState(() {
      _isRolling = false;
      _isDrawing = false;
      _drawnSongs = _pendingSongs;
      _pendingSongs = const [];
      _previewCandidates = const [];
      _resultRevision++;
      _history.insert(0, _drawnSongs);
      _historyTimes.insert(0, DateTime.now());
      if (_history.length > 5) {
        _history = _history.take(5).toList();
        _historyTimes.removeRange(5, _historyTimes.length);
      }
    });
  }

  // 删除历史记录
  void _deleteHistory(int index) {
    setState(() {
      _history.removeAt(index);
      _historyTimes.removeAt(index);
    });
  }

  // 显示版本选择对话框
  void _showVersionSelector() {
    if (_isDrawing || _isApplyingPreset) return;
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelected = List.from(_selectedVersions);

        return AppAlertDialog(
          title: Text('选择版本'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: double.maxFinite,
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 全选/全不选按钮
                      Row(
                        children: [
                          Checkbox(
                            value: tempSelected.length == _versionList.length,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  tempSelected = List.from(_versionList);
                                } else {
                                  tempSelected.clear();
                                }
                              });
                            },
                          ),
                          Text('全选'),
                        ],
                      ),
                      Divider(),
                      // 版本列表
                      Column(
                        children: _versionList.map((version) {
                          return CheckboxListTile(
                            title: Text(StringUtil.formatVersion2(version)),
                            value: tempSelected.contains(version),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  tempSelected.add(version);
                                } else {
                                  tempSelected.remove(version);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVersions = tempSelected;
                });
                Navigator.of(context).pop();
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 显示类型选择对话框
  void _showGenreSelector() {
    if (_isDrawing || _isApplyingPreset) return;
    FocusManager.instance.primaryFocus?.unfocus();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelected = List.from(_selectedGenres);

        return AppAlertDialog(
          title: Text('选择类型'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: double.maxFinite,
                height: 300,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 全选/全不选按钮
                      Row(
                        children: [
                          Checkbox(
                            value: tempSelected.length == _genreList.length,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  tempSelected = List.from(_genreList);
                                } else {
                                  tempSelected.clear();
                                }
                              });
                            },
                          ),
                          Text('全选'),
                        ],
                      ),
                      Divider(),
                      // 类型列表
                      Column(
                        children: _genreList.map((genre) {
                          return CheckboxListTile(
                            title: Text(genre),
                            value: tempSelected.contains(genre),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  tempSelected.add(genre);
                                } else {
                                  tempSelected.remove(genre);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedGenres = tempSelected;
                });
                Navigator.of(context).pop();
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  Widget _songCard(Song song) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.all(10),
      onTap: _isDrawing
          ? null
          : () {
              FocusManager.instance.primaryFocus?.unfocus();
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          SongInfoPage(songId: song.id, initialLevelIndex: 0)));
            },
      child: Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            child: CoverUtil.buildCoverWidgetWithContext(context, song.id, 72)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Row(children: [
                SongTypeBadge(songId: song.id, type: song.type),
                const SizedBox(width: 6),
                Expanded(
                  child: MarqueeText(
                    text: song.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              MarqueeText(
                text: song.basicInfo.artist.isEmpty
                    ? '未知艺术家'
                    : song.basicInfo.artist,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < song.ds.length; index++)
                      Padding(
                        padding: EdgeInsets.only(
                            right: index == song.ds.length - 1 ? 0 : 6),
                        child: DifficultyConstantLabel(
                            constant: song.ds[index],
                            difficultyIndex: index,
                            utage: song.id.length >= 6 ||
                                song.type == ChartDifficulty.utageLabel),
                      ),
                  ],
                ),
              ),
            ])),
      ]),
    );
  }

  // 曲绘加载使用CoverPathUtil工具类

  Widget _dsField(TextEditingController controller, String hint, bool busy) {
    return TextField(
      enabled: !busy,
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 14),
      decoration: recommendInputDecoration(context, hint: hint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = _isDrawing || _isApplyingPreset;
    // 淡出中的旧列表也继续使用自己的快照，避免新结果更少时越界。
    final drawnSongs = _drawnSongs;
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return BackgroundPageScaffold(
      title: '随机乐曲',
      resizeToAvoidBottomInset: false, // 解决输入法挤压背景的问题
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
            AppDesignTokens.gutter, AppDesignTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 筛选条件区域
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 抽取数量
                  Row(
                    children: [
                      Text(
                        '抽取数量',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Theme(
                        data: theme.copyWith(
                          inputDecorationTheme:
                              theme.inputDecorationTheme.copyWith(
                            filled: true,
                            fillColor: AppSurfaces.inset(context),
                          ),
                        ),
                        child: NumberStepper(
                            value: _drawCount,
                            suffix: ' 首',
                            controller: _drawCountController,
                            errorText: _drawCountError,
                            onTextChanged: _onDrawCountChanged,
                            minimum: RandomChartService.minimumDrawCount,
                            maximum: RandomChartService.maximumDrawCount,
                            onChanged: busy ? null : _setDrawCount),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 版本 / 类型筛选
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ProgressFieldLabel('版本筛选'),
                            ProgressPickerField(
                              value: _selectedVersions.isEmpty
                                  ? '全部版本'
                                  : '已选 ${_selectedVersions.length} 个版本',
                              onTap: () {
                                if (!busy) _showVersionSelector();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const ProgressFieldLabel('类型筛选'),
                            ProgressPickerField(
                              value: _selectedGenres.isEmpty
                                  ? '全部类型'
                                  : '已选 ${_selectedGenres.length} 个类型',
                              onTap: () {
                                if (!busy) _showGenreSelector();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 定数范围
                  const ProgressFieldLabel('定数范围'),
                  Row(
                    children: [
                      Expanded(child: _dsField(_minDsController, '最小值', busy)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('~',
                            style: TextStyle(color: scheme.onSurfaceVariant)),
                      ),
                      Expanded(child: _dsField(_maxDsController, '最大值', busy)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 快捷选项
                  const ProgressFieldLabel('快捷选项'),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: busy
                              ? null
                              : () => _applyMasterPreset(advanced: false),
                          child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('MASTER 上级')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: busy
                              ? null
                              : () => _applyMasterPreset(advanced: true),
                          child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('MASTER 超上级')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 抽奖按钮
                  FilledButton(
                    onPressed: _isRolling
                        ? _stopDraw
                        : busy || _drawCountError != null
                            ? null
                            : _drawSongs,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      textStyle: AppTheme.font(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: _isDrawing && !_isRolling
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: scheme.onSurfaceVariant,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('准备中…'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_isRolling
                                  ? Icons.stop_rounded
                                  : Icons.casino_outlined),
                              const SizedBox(width: 8),
                              Text(_isRolling ? '停！' : '开始抽奖'),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 歌曲抽取区域
            AppSectionHeader(
              title: '抽取结果',
              trailing: !_isRolling && drawnSongs.isNotEmpty
                  ? Text(
                      '本次抽取 ${drawnSongs.length} 首',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    )
                  : null,
            ),
            AnimatedSwitcher(
              reverseDuration: Duration.zero,
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              child: _isRolling
                  ? RandomChartRollingResults(
                      key: ValueKey(_resultRevision),
                      count: _pendingSongs.length,
                      candidates: _previewCandidates,
                    )
                  : drawnSongs.isEmpty
                      ? AppCard(
                          key: ValueKey(_resultRevision),
                          child: EmptyState(message: _emptyMessage),
                        )
                      : Column(
                          key: ValueKey(_resultRevision),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < drawnSongs.length; i++)
                              EntranceAnimation(
                                index: i,
                                duration: const Duration(milliseconds: 300),
                                offset: const Offset(0, 8),
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _songCard(drawnSongs[i]),
                                ),
                              ),
                          ],
                        ),
            ),

            const SizedBox(height: 20),

            // 历史记录区域
            const AppSectionHeader(title: '历史抽取记录'),
            if (_history.isEmpty)
              AppCard(
                child: Text(
                  '暂无历史记录',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              )
            else
              for (var index = 0; index < _history.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    radius: AppDesignTokens.radiusMedium,
                    padding: const EdgeInsets.fromLTRB(12, 4, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _historyTimes[index]
                                    .toString()
                                    .substring(0, 16),
                                style: AppTheme.number(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: '删除这条记录',
                              onPressed: () => _deleteHistory(index),
                              icon: const Icon(Icons.delete_outline),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GridView.count(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 5,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            children: _history[index].map((song) {
                              return GestureDetector(
                                onTap: _isDrawing
                                    ? null
                                    : () {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SongInfoPage(
                                              songId: song.id.toString(),
                                              initialLevelIndex: 0,
                                            ),
                                          ),
                                        );
                                      },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radiusSmall),
                                  child: CoverUtil.buildCoverWidgetWithContext(
                                      context, song.id, 64),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
