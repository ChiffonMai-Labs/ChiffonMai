import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import '../../widgets/EmptyState.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import 'package:my_first_flutter_app/entity/Favorite/FavoriteFolder.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/service/Favorite/FavoriteFolderService.dart';
import 'package:my_first_flutter_app/service/Favorite/FavoriteTransferService.dart';
import 'package:my_first_flutter_app/utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/FavoriteImportFlow.dart';
import 'package:my_first_flutter_app/utils/ExportPathUtil.dart';
import 'package:my_first_flutter_app/widgets/BackgroundPageScaffold.dart';
import 'package:my_first_flutter_app/service/AWMC/AwmcChartTagService.dart';
import 'package:my_first_flutter_app/manager/DivingFish/UserPlayDataManager.dart';
import 'package:my_first_flutter_app/entity/DivingFish/RecordItem.dart';
import 'package:my_first_flutter_app/entity/DivingFish/UserPlayDataEntity.dart';
import 'package:my_first_flutter_app/entity/DXRating/MaiTagsModel.dart';
import '../song_info/SongInfoPage.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/MarqueeText.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import '../../widgets/ErrorMessageDialog.dart';
import '../../widgets/ExportSuccessDialog.dart';

/// 收藏夹管理页面：查看所有收藏夹、创建/重命名/删除收藏夹，浏览收藏夹内的谱面
class FavoriteFolderPage extends StatefulWidget {
  const FavoriteFolderPage({super.key});

  @override
  State<FavoriteFolderPage> createState() => _FavoriteFolderPageState();
}

class _FavoriteFolderPageState extends State<FavoriteFolderPage> {
  final FavoriteFolderService _service = FavoriteFolderService();
  List<FavoriteFolder> _folders = [];
  bool _isLoading = true;
  bool _isReorderMode = false;
  bool _isSwapMode = false;
  int? _swapFirstIndex;

  // 样式常量
  final double borderRadiusSmall = 8.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final folders = await _service.getFolders();
    if (mounted) {
      setState(() {
        _folders = List<FavoriteFolder>.from(folders);
        if (_folders.length < 2 && _isReorderMode) {
          _isReorderMode = false;
          _isSwapMode = false;
          _swapFirstIndex = null;
        }
        _isLoading = false;
      });
    }
  }

  /// 切换收藏夹排序模式
  void _toggleReorderMode() {
    if (_isLoading) return;
    if (_isReorderMode) {
      setState(() {
        _isReorderMode = false;
        _isSwapMode = false;
        _swapFirstIndex = null;
      });
      return;
    }
    if (_folders.length < 2) {
      AppToast.show(context.l10n.favoriteReorderUnavailableEmpty,
          tone: AppToastTone.info);
      return;
    }
    setState(() {
      _isReorderMode = true;
      _isSwapMode = false;
      _swapFirstIndex = null;
    });
  }

  /// 拖拽调整收藏夹顺序
  void _onReorderFolder(int oldIndex, int newIndex) {
    setState(() {
      _applyReorder(_folders, oldIndex, newIndex);
      _swapFirstIndex = null;
    });
    _service.reorderFolders(oldIndex, newIndex);
  }

  /// 将收藏夹移动到指定 0 基位置
  void _moveFolderTo(int fromIndex, int toIndex) {
    if (fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= _folders.length ||
        toIndex < 0 ||
        toIndex >= _folders.length) {
      return;
    }
    setState(() {
      _applyMoveTo(_folders, fromIndex, toIndex);
      _swapFirstIndex = null;
    });
    _service.moveFolderTo(fromIndex, toIndex);
  }

  /// 弹窗输入序号并移动收藏夹
  Future<void> _promptMoveFolderToIndex(int currentIndex) async {
    final targetPosition = await showDialog<int>(
      context: context,
      builder: (_) => _MoveToPositionDialog(
        currentPosition: currentIndex + 1,
        maxPosition: _folders.length,
      ),
    );
    if (!mounted || targetPosition == null) return;
    _moveFolderTo(currentIndex, targetPosition - 1);
  }

  /// 点选交换：点击收藏夹卡片或从菜单发起
  void _handleSwapTap(int index) {
    if (_swapFirstIndex == null) {
      setState(() => _swapFirstIndex = index);
      return;
    }
    if (_swapFirstIndex == index) {
      setState(() => _swapFirstIndex = null);
      return;
    }
    final firstIndex = _swapFirstIndex!;
    setState(() {
      _applySwap(_folders, firstIndex, index);
      _swapFirstIndex = null;
    });
    _service.swapFolders(firstIndex, index);
    AppToast.show(context.l10n.favoriteSwapCompleted,
        tone: AppToastTone.success);
  }

  /// 从单项菜单触发点选交换
  void _startSwapFromItem(int index) {
    if (!_isSwapMode) {
      setState(() {
        _isSwapMode = true;
        _swapFirstIndex = index;
      });
      return;
    }
    _handleSwapTap(index);
  }

  /// 从文件导入收藏夹（后缀可在设置页自定义，导入按内容校验而非后缀）
  Future<void> _importFolders() async {
    final imported = await runFavoriteImportFlow(context);
    if (imported && mounted) {
      await _loadData();
    }
  }

  /// 显示创建收藏夹对话框
  Future<void> _createFolder() async {
    // 输入框的 controller 由弹窗自己持有（见 [_FolderNameDialog]）：
    // 这里**不要**再自己建 controller —— 无论 pop 那一刻就 dispose，
    // 还是 `addPostFrameCallback` 里晚一帧 dispose，都还在弹窗的**退场动画**里，
    // 会读到已释放的 controller 并炸出红屏。
    final result = await showDialog<String>(
      context: context,
      builder: (_) =>  _FolderNameDialog(
        title: context.l10n.flowNewFavoritesFolder,
        hintText: context.l10n.flowEnterAFolderName,
        confirmLabel: context.l10n.flowCreate,
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _service.createFolder(result);
      await _loadData();
    }
  }

  /// 显示重命名收藏夹对话框
  Future<void> _renameFolder(FavoriteFolder folder) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _FolderNameDialog(
        title: context.l10n.flowRenameFavoritesFolder,
        hintText: context.l10n.flowEnterANewName,
        confirmLabel: context.l10n.flowConfirm,
        initialName: folder.name,
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _service.renameFolder(folder.id, result);
      await _loadData();
    }
  }

  /// 删除收藏夹
  Future<void> _deleteFolder(FavoriteFolder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title:  Text(context.l10n.flowDeleteFavoritesFolder),
        content: Text(
          context.l10n.flowDeleteP0ChartsWillRemainButWill((folder.name).toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:  Text(context.l10n.featureCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child:  Text(context.l10n.flowDelete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.deleteFolder(folder.id);
      await _loadData();
      if (mounted) {
        AppToast.show(context.l10n.flowDeletedP0((folder.name).toString()), tone: AppToastTone.success);
      }
    }
  }

  /// 查看收藏夹详情
  void _viewFolder(FavoriteFolder folder) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FavoriteFolderDetailPage(
          folderId: folder.id,
          folderName: folder.name,
        ),
      ),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: context.l10n.featureFavoriteFolders,
      actions: [
        IconButton(
          icon: Icon(
            _isReorderMode ? Icons.check_rounded : Icons.swap_vert_rounded,
            size: 22,
          ),
          tooltip: _isReorderMode
              ? context.l10n.favoriteReorderDone
              : context.l10n.favoriteReorderMode,
          onPressed: _toggleReorderMode,
        ),
      ],
      resizeToAvoidBottomInset: false,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(children: [
        Expanded(
            child: Column(
          children: [
            if (_isReorderMode)
              _ReorderBanner(
                isSwapMode: _isSwapMode,
                swapFirstIndex: _swapFirstIndex,
                onToggleSwapMode: (enabled) {
                  setState(() {
                    _isSwapMode = enabled;
                    _swapFirstIndex = null;
                  });
                },
              )
            else
              // 新建 / 导入按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createFolder,
                        icon: const Icon(Icons.add, size: 20),
                        label: Text(context.l10n.flowNewFavoritesFolder),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(borderRadiusSmall),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _importFolders,
                        icon: const Icon(Icons.file_download_outlined, size: 20),
                        label: Text(context.l10n.flowImportFavorites),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(borderRadiusSmall),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // 内容
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _folders.isEmpty
                      ? _buildEmptyState()
                      : _buildFolderList(),
            ),
          ],
        )),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.favorite_border,
      title: context.l10n.flowNoFavoritesFoldersYet,
      message: '${context.l10n.flowAddChartsToFavoritesFoldersFromSong}\n'
          '${context.l10n.flowOrUseImportFavoritesAboveP0((favoriteImportHint()).toString())}',
    );
  }

  Widget _buildFolderList() {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.all(12),
      itemCount: _folders.length,
      onReorder: _onReorderFolder,
      proxyDecorator: (child, index, animation) => _buildReorderProxyDecorator(
          child, animation, AppDesignTokens.radiusCard),
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return Padding(
          key: ValueKey('folder_${folder.id}'),
          padding: const EdgeInsets.only(bottom: AppDesignTokens.cardGap),
          child: _buildFolderCard(folder, index),
        );
      },
    );
  }

  Widget _buildFolderCard(FavoriteFolder folder, int index) {
    final chartCount = folder.charts.length;
    final isSwapSelected =
        _isReorderMode && _isSwapMode && _swapFirstIndex == index;
    final scheme = Theme.of(context).colorScheme;

    return ReorderableDelayedDragStartListener(
      index: index,
      enabled: _isReorderMode && !_isSwapMode,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color:
            isSwapSelected ? scheme.primaryContainer : AppSurfaces.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          side: isSwapSelected
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusCard),
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          onTap: _isReorderMode
              ? (_isSwapMode ? () => _handleSwapTap(index) : null)
              : () => _viewFolder(folder),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _isReorderMode ? 10 : 16,
              vertical: 14,
            ),
            child: Row(
              children: [
                if (_isReorderMode) ...[
                  _ReorderIndexChip(
                    index: index,
                    isSelected: isSwapSelected,
                    onTapIndex: () => _promptMoveFolderToIndex(index),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: _isReorderMode ? 40 : 48,
                  height: _isReorderMode ? 40 : 48,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppDesignTokens.radiusSmall),
                  ),
                  child: Icon(Icons.star_rounded,
                      color: scheme.onPrimaryContainer,
                      size: _isReorderMode ? 24 : 28),
                ),
                SizedBox(width: _isReorderMode ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.flowP0Charts((chartCount).toString()),
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (_isReorderMode) ...[
                  _ReorderTrailingControls(
                    index: index,
                    totalCount: _folders.length,
                    onMoveUp: () => _moveFolderTo(index, index - 1),
                    onMoveDown: () => _moveFolderTo(index, index + 1),
                    onMoveToTop: () => _moveFolderTo(index, 0),
                    onMoveToBottom: () =>
                        _moveFolderTo(index, _folders.length - 1),
                    onMoveToIndex: () => _promptMoveFolderToIndex(index),
                    onSwap: () => _startSwapFromItem(index),
                  ),
                  const SizedBox(width: 2),
                  ReorderableDragStartListener(
                    index: index,
                    enabled: !_isSwapMode,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 20,
                        color: _isSwapMode
                            ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ] else
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
                    onSelected: (value) {
                      switch (value) {
                        case 'rename':
                          _renameFolder(folder);
                          break;
                        case 'delete':
                          _deleteFolder(folder);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                          value: 'rename',
                          child: Text(context.l10n.flowRename)),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.l10n.flowDelete,
                            style: TextStyle(color: scheme.error)),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 收藏夹详情页：查看收藏夹内的谱面列表
class _FavoriteFolderDetailPage extends StatefulWidget {
  final String folderId;
  final String folderName;

  const _FavoriteFolderDetailPage({
    required this.folderId,
    required this.folderName,
  });

  @override
  State<_FavoriteFolderDetailPage> createState() =>
      _FavoriteFolderDetailPageState();
}

class _FavoriteFolderDetailPageState extends State<_FavoriteFolderDetailPage> {
  final FavoriteFolderService _service = FavoriteFolderService();
  List<FavoriteChart> _charts = [];
  List<FavoriteChart> _sortedCharts = const [];
  bool _isLoading = true;
  Map<String, Song> _songMap = {};
  Map<String, RecordItem> _bestRecordMap = {};

  // 标签统计相关
  MaiTagsEntity? _tagsEntity;
  Map<String, Map<String, int>> _tagStats = {};
  bool _isLoadingTags = false;

  // 排序与批量选择
  FavoriteSortOption _sortOption = FavoriteSortOption.byDsDesc;
  bool _initializedSortOption = false;
  bool _isReorderMode = false;
  bool _isSwapMode = false;
  int? _swapFirstIndex;
  bool _isBatchMode = false;
  final Set<String> _selectedKeys = {};

  /// 公开目录不可写时记录实际落盘的私有路径，用于在成功弹窗里提示用户
  String? _fallbackPath;

  // 样式常量
  final double borderRadiusSmall = 8.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _refreshSortedCharts() {
    _sortedCharts = _service.sortCharts(_charts, _sortOption);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final folder = await _service.getFolderById(widget.folderId);
    final charts = folder != null
        ? folder.charts
        : await _service.getChartsInFolder(widget.folderId);
    // 加载歌曲详细信息（曲师、版本、流派）
    final songs = await MaimaiMusicDataManager().getCachedSongs();
    final Map<String, Song> songMap = {};
    if (songs != null) {
      for (final song in songs) {
        songMap[song.id] = song;
      }
    }
    if (mounted) {
      setState(() {
        if (!_initializedSortOption) {
          _sortOption = folder?.sortOption ?? FavoriteSortOption.byDsDesc;
          _initializedSortOption = true;
        }
        _charts = List<FavoriteChart>.from(charts);
        if (_charts.length < 2 && _isReorderMode) {
          _isReorderMode = false;
          _isSwapMode = false;
          _swapFirstIndex = null;
        }
        _refreshSortedCharts();
        _songMap = songMap;
        _isLoading = false;
      });
    }
    // 加载标签统计数据
    await _loadTagDataAndCalculateStats();
    // 加载用户游玩数据以显示达成率
    await _loadAchievements();
  }

  /// 加载用户游玩数据并将达成率关联到收藏夹谱面
  Future<void> _loadAchievements() async {
    try {
      final rawData = await UserPlayDataManager().getCachedUserPlayData();
      if (rawData == null) return;

      final userData = UserPlayDataEntity.fromJson(rawData);
      final records = userData.records;
      final updatedByKey = <String, FavoriteChart>{};
      final bestRecordByKey = <String, RecordItem>{};
      for (final chart in _charts) {
        final matchedRecords = records.where((r) =>
            r.songId.toString() == chart.songId &&
            r.levelIndex == chart.levelIndex);
        if (matchedRecords.isNotEmpty) {
          final best = matchedRecords
              .reduce((a, b) => a.achievements > b.achievements ? a : b);
          bestRecordByKey[chart.uniqueKey] = best;
          updatedByKey[chart.uniqueKey] = chart.copyWith(
            achievement: best.achievements.toDouble(),
            playCount: matchedRecords.length,
          );
        }
      }
      if (mounted) {
        setState(() {
          _bestRecordMap = bestRecordByKey;
          if (updatedByKey.isNotEmpty) {
            for (int i = 0; i < _charts.length; i++) {
              final updated = updatedByKey[_charts[i].uniqueKey];
              if (updated != null) {
                _charts[i] = updated;
              }
            }
            _refreshSortedCharts();
          }
        });
      }
    } catch (e) {
      debugPrint('加载收藏夹成绩数据失败: $e');
    }
  }

  /// 切换谱面排序模式（进入时若非自定义排序则固化当前可见序并切至 custom）
  Future<void> _toggleReorderMode() async {
    if (_isLoading) return;
    if (_isReorderMode) {
      setState(() {
        _isReorderMode = false;
        _isSwapMode = false;
        _swapFirstIndex = null;
      });
      return;
    }
    if (_charts.length < 2) {
      AppToast.show(context.l10n.favoriteReorderUnavailableEmpty,
          tone: AppToastTone.info);
      return;
    }
    if (_sortOption != FavoriteSortOption.custom) {
      final visible = List<FavoriteChart>.from(_sortedCharts);
      setState(() {
        _isBatchMode = false;
        _selectedKeys.clear();
        _charts = visible;
        _sortOption = FavoriteSortOption.custom;
        _sortedCharts = List<FavoriteChart>.from(visible);
        _isReorderMode = true;
        _isSwapMode = false;
        _swapFirstIndex = null;
      });
      await _service.saveChartsOrder(widget.folderId, visible);
      await _service.setFolderSortOption(
          widget.folderId, FavoriteSortOption.custom);
      return;
    }
    setState(() {
      _isBatchMode = false;
      _selectedKeys.clear();
      _isReorderMode = true;
      _isSwapMode = false;
      _swapFirstIndex = null;
    });
  }

  /// 拖拽调整谱面顺序
  void _onReorderChart(int oldIndex, int newIndex) {
    setState(() {
      _applyReorder(_charts, oldIndex, newIndex);
      _refreshSortedCharts();
      _swapFirstIndex = null;
    });
    _service.reorderChartsInFolder(widget.folderId, oldIndex, newIndex);
  }

  /// 将谱面移动到指定 0 基位置
  void _moveChartTo(int fromIndex, int toIndex) {
    if (fromIndex == toIndex ||
        fromIndex < 0 ||
        fromIndex >= _charts.length ||
        toIndex < 0 ||
        toIndex >= _charts.length) {
      return;
    }
    setState(() {
      _applyMoveTo(_charts, fromIndex, toIndex);
      _refreshSortedCharts();
      _swapFirstIndex = null;
    });
    _service.moveChartInFolder(widget.folderId, fromIndex, toIndex);
  }

  /// 弹窗输入序号并移动谱面
  Future<void> _promptMoveChartToIndex(int currentIndex) async {
    final targetPosition = await showDialog<int>(
      context: context,
      builder: (_) => _MoveToPositionDialog(
        currentPosition: currentIndex + 1,
        maxPosition: _sortedCharts.length,
      ),
    );
    if (!mounted || targetPosition == null) return;
    _moveChartTo(currentIndex, targetPosition - 1);
  }

  /// 点选交换：点击谱面卡片或从菜单发起
  void _handleSwapTap(int index) {
    if (_swapFirstIndex == null) {
      setState(() => _swapFirstIndex = index);
      return;
    }
    if (_swapFirstIndex == index) {
      setState(() => _swapFirstIndex = null);
      return;
    }
    final firstIndex = _swapFirstIndex!;
    setState(() {
      _applySwap(_charts, firstIndex, index);
      _refreshSortedCharts();
      _swapFirstIndex = null;
    });
    _service.swapChartsInFolder(widget.folderId, firstIndex, index);
    AppToast.show(context.l10n.favoriteSwapCompleted,
        tone: AppToastTone.success);
  }

  /// 从单项菜单触发点选交换
  void _startSwapFromItem(int index) {
    if (!_isSwapMode) {
      setState(() {
        _isSwapMode = true;
        _swapFirstIndex = index;
      });
      return;
    }
    _handleSwapTap(index);
  }

  /// 从收藏夹中移除谱面
  Future<void> _removeChart(FavoriteChart chart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title:  Text(context.l10n.flowRemoveChart),
        content: Text(
          context.l10n.flowRemoveP1FromP0((widget.folderName).toString(), (chart.songTitle).toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:  Text(context.l10n.featureCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child:  Text(context.l10n.flowRemove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.removeChartFromFolder(widget.folderId, chart.uniqueKey);
      await _loadData();
      if (mounted) {
        AppToast.show(context.l10n.flowRemoved, tone: AppToastTone.success);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BackgroundPageScaffold(
      title: widget.folderName,
      headerOverride: _isBatchMode
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground(Theme.of(context).brightness),
              ),
              child: _buildBatchAppBar(),
            )
          : null,
      actions: [
        if (_isReorderMode)
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 22),
            tooltip: context.l10n.favoriteReorderDone,
            onPressed: _toggleReorderMode,
          )
        else ...[
          // 调整顺序按钮
          IconButton(
            icon: const Icon(Icons.swap_vert_rounded, size: 22),
            tooltip: context.l10n.favoriteReorderMode,
            onPressed: _toggleReorderMode,
          ),
          // 排序方式按钮
          PopupMenuButton<FavoriteSortOption>(
            icon: const Icon(Icons.sort, size: 22),
            tooltip: context.l10n.flowSortOrder,
            onSelected: (option) {
              setState(() {
                _sortOption = option;
                _refreshSortedCharts();
              });
              _service.setFolderSortOption(widget.folderId, option);
            },
            itemBuilder: (ctx) => [
              _buildSortMenuItem(
                FavoriteSortOption.custom,
                context.l10n.favoriteSortCustom,
                scheme,
              ),
              _buildSortMenuItem(
                FavoriteSortOption.byDsDesc,
                context.l10n.flowConstantHighLow,
                scheme,
              ),
              _buildSortMenuItem(
                FavoriteSortOption.byDsAsc,
                context.l10n.flowConstantLowHigh,
                scheme,
              ),
              _buildSortMenuItem(
                FavoriteSortOption.byDateNewest,
                context.l10n.flowAddedNewOld,
                scheme,
              ),
              _buildSortMenuItem(
                FavoriteSortOption.byDateOldest,
                context.l10n.flowAddedOldNew,
                scheme,
              ),
              _buildSortMenuItem(
                FavoriteSortOption.byTitle,
                context.l10n.flowSongTitleAZ,
                scheme,
              ),
            ],
          ),
          // 导出按钮
          IconButton(
            icon: const Icon(Icons.share, size: 22),
            tooltip: context.l10n.flowExportFavorites,
            onPressed: _exportFolder,
          ),
        ],
      ],
      resizeToAvoidBottomInset: false,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(children: [
        Expanded(
            child: Column(
          children: [
            if (_isReorderMode)
              _ReorderBanner(
                isSwapMode: _isSwapMode,
                swapFirstIndex: _swapFirstIndex,
                onToggleSwapMode: (enabled) {
                  setState(() {
                    _isSwapMode = enabled;
                    _swapFirstIndex = null;
                  });
                },
              )
            else
              // 标签统计按钮（样式、宽度与新建收藏夹一致）
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showTagStatistics,
                    icon: const Icon(Icons.label_outline, size: 18),
                    label: Text(context.l10n.flowTagStatistics),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadiusSmall),
                      ),
                    ),
                  ),
                ),
              ),
            // 内容
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _charts.isEmpty
                      ? _buildEmptyState()
                      : _buildChartList(),
            ),
          ],
        )),
      ]),
    );
  }

  PopupMenuItem<FavoriteSortOption> _buildSortMenuItem(
    FavoriteSortOption value,
    String label,
    ColorScheme scheme,
  ) {
    final selected = _sortOption == value;
    return PopupMenuItem<FavoriteSortOption>(
      value: value,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: selected
                  ? TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    )
                  : null,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, size: 18, color: scheme.primary),
          ],
        ],
      ),
    );
  }

  /// 显示标签统计对话框（基于 AWMC 与自定义标签系统）
  void _showTagStatistics() {
    if (_tagStats.isEmpty) {
      AppToast.show(context.l10n.flowNoTagData, tone: AppToastTone.warning);
      return;
    }

    // 分组颜色映射（与 Best50Page 一致）
    const Map<String, Color> groupColors = {
      '配置': Colors.blue,
      '评价': Colors.amber,
      '难度': Colors.indigo,
    };

    showDialog(
      context: context,
      builder: (ctx) => AppAlertDialog(
        scrollable: true,
        title: Row(
          children: [
            Icon(Icons.label,
                size: 22, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(context.l10n.flowTagStatistics,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints:
              BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: _isLoadingTags
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _tagStats.entries.map((groupEntry) {
                      final groupName = groupEntry.key;
                      final tagCounts = groupEntry.value;
                      final groupColor = groupColors[groupName] ?? Theme.of(context).colorScheme.onSurfaceVariant;
                      final total = tagCounts.values.fold(0, (a, b) => a + b);

                      // 对组内标签按数量降序排序
                      final sortedTags = tagCounts.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 分组标题
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: groupColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    groupName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: groupColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.l10n.flowP0Items3((total).toString()),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.greyHint(
                                            Theme.of(context).brightness)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 标签统计条
                            ...sortedTags.map((tagEntry) {
                              final percentage =
                                  tagEntry.value / _charts.length * 100;
                              final barColor = groupColor.withOpacity(0.7);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 48,
                                      child: Text(
                                        tagEntry.key,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
                                        child: SmoothLinearProgressIndicator(
                                          value:
                                              tagEntry.value / _charts.length,
                                          minHeight: 18,
                                          backgroundColor:
                                              AppSurfaces.track(context),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  barColor),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 60,
                                      child: Text(
                                        '${tagEntry.value} (${(percentage).toStringAsFixed(0)}%)',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:  Text(context.l10n.featureClose),
          ),
        ],
      ),
    );
  }

  // ========== 标签数据加载与统计（基于 AWMC 与自定义标签） ==========

  /// 加载标签数据并计算当前收藏夹各标签出现次数
  Future<void> _loadTagDataAndCalculateStats() async {
    setState(() {
      _isLoadingTags = true;
    });

    try {
      _tagsEntity = await AwmcChartTagService.getTagsEntity();

      if (_tagsEntity != null) {
        await _calculateTagGroupStats();
      }
    } catch (e) {
      debugPrint('Error loading tag data: $e');
    } finally {
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  /// 计算各标签分组下每个标签的出现次数
  Future<void> _calculateTagGroupStats() async {
    if (_tagsEntity == null) return;

    final tagIdToNameMap = await AwmcChartTagService.getTagIdToNameMap();
    final groupIdToNameMap = await AwmcChartTagService.getGroupIdToNameMap();

    // 构建标签ID → 分组名称 的映射
    Map<int, String> tagIdToGroupName = {};
    for (var tag in _tagsEntity!.tags) {
      tagIdToGroupName[tag.id] = groupIdToNameMap[tag.groupId] ?? context.l10n.flowUncategorized;
    }

    // 获取所有歌曲标题到标签的映射
    Map<String, Set<int>> songTitleToTagIds = {};
    for (var tagSong in _tagsEntity!.tagSongs) {
      String key =
          '${tagSong.songId}|${tagSong.sheetType}|${tagSong.sheetDifficulty}';
      if (!songTitleToTagIds.containsKey(key)) {
        songTitleToTagIds[key] = {};
      }
      songTitleToTagIds[key]!.add(tagSong.tagId);
    }

    // 遍历收藏夹内的谱面，匹配标签并统计
    Map<String, Map<String, int>> stats = {};
    for (var chart in _charts) {
      String songId = chart.songId;
      int levelIndex = chart.levelIndex;

      // 从 _songMap 获取歌曲信息（与 Best50Page 一致）
      String songTitle = _songMap[songId]?.basicInfo.title ?? '';
      String songType = chart.songType.isNotEmpty
          ? chart.songType
          : (_songMap[songId]?.type ?? 'SD');

      String sheetType = songType == 'DX' ? 'dx' : 'std';
      String difficulty = _getDifficultyByIndex(levelIndex);

      String key = '$songTitle|$sheetType|$difficulty';
      Set<int>? tagIds = songTitleToTagIds[key];

      if (tagIds != null && tagIds.isNotEmpty) {
        for (int tagId in tagIds) {
          String tagName = tagIdToNameMap[tagId] ?? context.l10n.flowUnknownTag;
          String groupName = tagIdToGroupName[tagId] ?? context.l10n.flowUncategorized;

          if (!stats.containsKey(groupName)) {
            stats[groupName] = {};
          }
          if (!stats[groupName]!.containsKey(tagName)) {
            stats[groupName]![tagName] = 0;
          }
          stats[groupName]![tagName] = stats[groupName]![tagName]! + 1;
        }
      }
    }

    setState(() {
      _tagStats = stats;
    });
  }

  /// 将难度索引映射为标签系统使用的难度字符串
  String _getDifficultyByIndex(int index) {
    return ChartDifficulty.apiNameOf(index, fallback: 'basic');
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.favorite_border,
      message: context.l10n.flowFavoritesFolderIsEmpty,
    );
  }

  Widget _buildChartList() {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.all(12),
      itemCount: _sortedCharts.length,
      onReorder: _onReorderChart,
      proxyDecorator: (child, index, animation) => _buildReorderProxyDecorator(
          child, animation, AppDesignTokens.radiusMedium),
      itemBuilder: (context, index) {
        final chart = _sortedCharts[index];
        return Padding(
          key: ValueKey('chart_${chart.uniqueKey}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildChartCard(chart, index),
        );
      },
    );
  }

  Widget _buildChartCover(
    BuildContext context,
    String songId,
    Color diffBorderColor,
    double size,
  ) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            child: CoverUtil.buildCoverWidgetWithContext(context, songId, size),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              border: Border.all(color: diffBorderColor, width: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(FavoriteChart chart, int index) {
    final levelNames = ChartDifficulty.labels;
    final bool isUtage = chart.songId.length == 6;
    final String levelName;
    if (isUtage) {
      levelName = ChartDifficulty.utageLabel;
    } else {
      levelName = chart.levelIndex >= 0 && chart.levelIndex < levelNames.length
          ? levelNames[chart.levelIndex]
          : 'Lv.${chart.levelIndex}';
    }

    // 获取歌曲详细信息与玩家最佳成绩
    final song = _songMap[chart.songId];
    final record = _bestRecordMap[chart.uniqueKey];
    final genre = song?.basicInfo.genre ?? '';
    final version = StringUtil.formatVersion2WithFlag(
        song?.basicInfo.from ?? '', song?.isExtra ?? false);
    final songType =
        chart.songType.isNotEmpty ? chart.songType : (song?.type ?? '');
    final double? achievement =
        record != null ? record.achievements.toDouble() : chart.achievement;
    final diffBorderColor = isUtage
        ? AppColors.utageCard()
        : ColorUtil.getCardColor(chart.levelIndex);

    if (_isReorderMode) {
      return _buildReorderChartCard(
        chart: chart,
        index: index,
        levelName: levelName,
        songType: songType,
        diffBorderColor: diffBorderColor,
        achievement: achievement,
        record: record,
      );
    }

    final isSelected = _selectedKeys.contains(chart.uniqueKey);
    final scheme = Theme.of(context).colorScheme;
    const double coverSize = 60;
    final metaLine = [
      if (record != null && record.ra > 0) 'RA ${record.ra}',
      if (version.isNotEmpty) version,
      if (genre.isNotEmpty) genre,
    ].join(' · ');

    return Material(
      color: isSelected ? scheme.primaryContainer : AppSurfaces.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
        side: isSelected
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        onTap: () {
          if (_isBatchMode) {
            setState(() {
              if (isSelected) {
                _selectedKeys.remove(chart.uniqueKey);
                if (_selectedKeys.isEmpty) _isBatchMode = false;
              } else {
                _selectedKeys.add(chart.uniqueKey);
              }
            });
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SongInfoPage(
                  songId: chart.songId,
                  initialLevelIndex: chart.levelIndex,
                ),
              ),
            );
          }
        },
        onLongPress: () {
          if (!_isBatchMode) {
            setState(() {
              _isReorderMode = false;
              _isSwapMode = false;
              _swapFirstIndex = null;
              _isBatchMode = true;
              _selectedKeys.add(chart.uniqueKey);
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              if (_isBatchMode) ...[
                Checkbox(
                  value: isSelected,
                  activeColor: scheme.primary,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedKeys.add(chart.uniqueKey);
                      } else {
                        _selectedKeys.remove(chart.uniqueKey);
                        if (_selectedKeys.isEmpty) _isBatchMode = false;
                      }
                    });
                  },
                ),
                const SizedBox(width: 4),
              ],
              // 左侧：带难度色框的曲绘（与 Best50StripCard 保持一致）
              _buildChartCover(context, chart.songId, diffBorderColor, coverSize),
              const SizedBox(width: 10),
              // 中间：标题 + 难度定数/成绩徽章 + 版本流派
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        SongTypeBadge(
                          songId: chart.songId,
                          type: songType,
                          fontSize: 9.5,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: MarqueeText(
                            text: chart.songTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChartDifficultyBadge(
                            levelIndex: chart.levelIndex,
                            songId: chart.songId,
                            label: '$levelName ${chart.ds.toStringAsFixed(1)}',
                            fontSize: 10,
                          ),
                          if (achievement != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${achievement.toStringAsFixed(4)}%',
                              maxLines: 1,
                              style: AppTheme.number(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 5),
                            RankBadge(
                              rank: StringUtil.formatRate(
                                StringUtil.rateCodeFromAchievement(
                                    achievement),
                              ),
                              fontSize: 9.5,
                            ),
                            if (record != null && record.fc.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              ComboLabelBadge(raw: record.fc, fontSize: 9.5),
                            ],
                            if (record != null && record.fs.isNotEmpty) ...[
                              const SizedBox(width: 3),
                              ComboLabelBadge(raw: record.fs, fontSize: 9.5),
                            ],
                          ],
                        ],
                      ),
                    ),
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metaLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (!_isBatchMode)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: scheme.error,
                  ),
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  tooltip: context.l10n.flowRemoveFromFavoritesFolder,
                  onPressed: () => _removeChart(chart),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 排序模式专用两段式单曲卡片：上段占满宽度展示曲名与核心成绩，下段集中摆放排序控件，避免信息区被左右挤压。
  Widget _buildReorderChartCard({
    required FavoriteChart chart,
    required int index,
    required String levelName,
    required String songType,
    required Color diffBorderColor,
    required double? achievement,
    required RecordItem? record,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isSwapSelected = _isSwapMode && _swapFirstIndex == index;

    return ReorderableDelayedDragStartListener(
      index: index,
      enabled: !_isSwapMode,
      child: Material(
        color:
            isSwapSelected ? scheme.primaryContainer : AppSurfaces.card(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          side: isSwapSelected
              ? BorderSide(color: scheme.primary, width: 1.5)
              : BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          onTap: _isSwapMode ? () => _handleSwapTap(index) : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 6, 8),
                child: Row(
                  children: [
                    _buildChartCover(context, chart.songId, diffBorderColor, 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              SongTypeBadge(
                                songId: chart.songId,
                                type: songType,
                                fontSize: 9.5,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: MarqueeText(
                                  text: chart.songTitle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              ChartDifficultyBadge(
                                levelIndex: chart.levelIndex,
                                songId: chart.songId,
                                label:
                                    '$levelName ${chart.ds.toStringAsFixed(1)}',
                                fontSize: 10,
                              ),
                              if (achievement != null) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${achievement.toStringAsFixed(4)}%',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.number(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                              if (record != null && record.ra > 0) ...[
                                const SizedBox(width: 6),
                                Text(
                                  'RA ${record.ra}',
                                  maxLines: 1,
                                  style: AppTheme.number(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    ReorderableDragStartListener(
                      index: index,
                      enabled: !_isSwapMode,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 10,
                        ),
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: 20,
                          color: _isSwapMode
                              ? scheme.onSurfaceVariant.withValues(alpha: 0.35)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                thickness: 0.5,
                color: AppSurfaces.hairline(context),
              ),
              Container(
                color: isSwapSelected
                    ? scheme.primary.withValues(alpha: 0.08)
                    : AppSurfaces.inset(context).withValues(alpha: 0.55),
                padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                child: Row(
                  children: [
                    Material(
                      color: isSwapSelected
                          ? scheme.primary
                          : AppSurfaces.card(context),
                      borderRadius:
                          BorderRadius.circular(AppDesignTokens.radiusPill),
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusPill),
                        splashFactory: NoSplash.splashFactory,
                        highlightColor: Colors.transparent,
                        onTap: () => _promptMoveChartToIndex(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusPill,
                            ),
                            border: Border.all(
                              color: isSwapSelected
                                  ? scheme.primary
                                  : scheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: AppTheme.number(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSwapSelected
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    _ReorderTrailingControls(
                      index: index,
                      totalCount: _sortedCharts.length,
                      onMoveUp: () => _moveChartTo(index, index - 1),
                      onMoveDown: () => _moveChartTo(index, index + 1),
                      onMoveToTop: () => _moveChartTo(index, 0),
                      onMoveToBottom: () =>
                          _moveChartTo(index, _sortedCharts.length - 1),
                      onMoveToIndex: () => _promptMoveChartToIndex(index),
                      onSwap: () => _startSwapFromItem(index),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 批量操作工具栏
  Widget _buildBatchAppBar() {
    return Row(
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              _isBatchMode = false;
              _selectedKeys.clear();
            });
          },
          child:  Text(context.l10n.featureCancel),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.flowP0Selected((_selectedKeys.length).toString()),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _selectedKeys.isEmpty ? null : _batchMoveCharts,
          icon: const Icon(Icons.drive_file_move, size: 18),
          label:  Text(context.l10n.flowMove),
        ),
        TextButton.icon(
          onPressed: _selectedKeys.isEmpty ? null : _batchRemoveCharts,
          icon: Icon(Icons.delete_outline,
              size: 18, color: Theme.of(context).colorScheme.error),
          label: Text(context.l10n.flowDelete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }

  /// 批量移除选中的谱面
  Future<void> _batchRemoveCharts() async {
    final count = _selectedKeys.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title:  Text(context.l10n.flowRemoveMultipleCharts),
        content: Text(context.l10n.flowRemoveP1ChartsFromP0((widget.folderName).toString(), (count).toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:  Text(context.l10n.featureCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child:  Text(context.l10n.flowRemove),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _service.removeChartsFromFolder(
          widget.folderId, _selectedKeys.toList());
      if (mounted) {
        AppToast.show(context.l10n.flowRemovedP0Charts((count).toString()), tone: AppToastTone.success);
      }
      _selectedKeys.clear();
      _isBatchMode = false;
      await _loadData();
    }
  }

  /// 批量移动选中的谱面到其他文件夹
  Future<void> _batchMoveCharts() async {
    final allFolders = await _service.getFolders();
    final otherFolders =
        allFolders.where((f) => f.id != widget.folderId).toList();
    if (otherFolders.isEmpty) {
      if (mounted) {
        AppToast.show(context.l10n.flowNoOtherFoldersToMoveTo, tone: AppToastTone.warning);
      }
      return;
    }

    final targetId = await showDialog<String>(
      context: context,
      builder: (ctx) => AppAlertDialog(
        title:  Text(context.l10n.flowMoveTo),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: otherFolders.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(otherFolders[i].name),
              subtitle: Text(context.l10n.flowP0Charts((otherFolders[i].charts.length).toString())),
              onTap: () => Navigator.of(ctx).pop(otherFolders[i].id),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:  Text(context.l10n.featureCancel),
          ),
        ],
      ),
    );

    if (targetId != null) {
      final count = await _service.moveChartsBetweenFolders(
          widget.folderId, targetId, _selectedKeys.toList());
      if (mounted) {
        AppToast.show(context.l10n.flowMovedP0Charts((count).toString()), tone: AppToastTone.success);
      }
      _selectedKeys.clear();
      _isBatchMode = false;
      await _loadData();
    }
  }

  /// 导出收藏夹为 ChiffonMai 自定义格式（可一键导回）
  ///
  /// 后缀取设置页里配置的值（默认 `.cmf`），文件落到公开的
  /// `Download/ChiffonMai/收藏夹/` 下，文件管理器可以直接找到。
  Future<void> _exportFolder() async {
    if (_charts.isEmpty) {
      AppToast.show(context.l10n.flowThisFolderIsEmptyThereAreNo, tone: AppToastTone.warning);
      return;
    }

    if (!await ExportPathUtil.prepareForExport(context,
        subDir: '收藏夹', title: context.l10n.flowChooseWhereToExportFavorites)) {
      return;
    }

    _fallbackPath = null;
    try {
      final folder = FavoriteFolder(
        id: widget.folderId,
        name: widget.folderName,
        charts: _sortedCharts,
        sortOption: _sortOption,
      );

      final file = await FavoriteTransferService().exportFolders(
        [folder],
        fileBaseName: '${favoriteExportPrefix}_${widget.folderName}',
        onFallback: (p) => _fallbackPath = p,
      );

      if (!mounted) return;
      await showExportSuccessDialog(
        context,
        filePath: file.path,
        fileName: file.uri.pathSegments.last,
        description: context.l10n.flowImportItInTheAppOrOpen,
        fallbackPath: _fallbackPath,
      );
    } catch (e, stack) {
      debugPrint('导出收藏夹失败: $e');
      if (mounted) {
        await showErrorMessageDialog(
          context,
          error: e,
          stack: stack,
          title: context.l10n.flowCouldNotExportP0('收藏夹'),
          stage: '导出收藏夹',
        );
      }
    }
  }
}

/// 「新建 / 重命名收藏夹」共用的输入名称弹窗：确定返回名称，取消返回 null。
///
/// ⚠️ 输入框的 controller 由**弹窗自己的 [State]** 持有并释放。
/// 原来的写法是调用方建 controller、等 `showDialog` 的 future 完成后在
/// `addPostFrameCallback` 里 dispose —— 那一帧弹窗仍在**退场动画**里（真机上
/// 键盘收起会让它重建，`TextField` 会再读一次 controller），于是必现
/// 「A TextEditingController was used after being disposed」；异常又发生在卸载
/// 途中，紧接着刷出 `'_dependents.isEmpty': is not true` 与
/// 「Tried to build dirty widget in the wrong build scope」——用户看到的就是**红屏**。
///
/// 交给 [State.dispose] 就**结构上**不可能提前：它只在弹窗元素真正卸载后才跑。
/// 回归测试：`test/dialog_close_dispose_test.dart`。
class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog({
    required this.title,
    required this.hintText,
    required this.confirmLabel,
    this.initialName = '',
  });

  final String title;
  final String hintText;
  final String confirmLabel;

  /// 重命名时带出原名字；新建时为空。
  final String initialName;

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _nameController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.flowFolderNameCannotBeEmpty);
      return;
    }
    Navigator.of(context).pop(name);
  }

  void _validateName(String value) {
    final error = value.trim().isEmpty ? context.l10n.flowFolderNameCannotBeEmpty : null;
    if (error != _nameError) setState(() => _nameError = error);
  }

  @override
  Widget build(BuildContext context) {
    return AppAlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        onChanged: _validateName,
        decoration: InputDecoration(
          hintText: widget.hintText,
          errorText: _nameError,
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
        inputFormatters: [LengthLimitingTextInputFormatter(30)],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:  Text(context.l10n.featureCancel),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// 按 ReorderableListView 语义（向下拖拽时 newIndex 含被移除项占位）重排列表
void _applyReorder<T>(List<T> list, int oldIndex, int newIndex) {
  if (oldIndex < 0 || oldIndex >= list.length) return;
  var targetIndex = newIndex;
  if (oldIndex < targetIndex) {
    targetIndex -= 1;
  }
  if (targetIndex < 0 ||
      targetIndex >= list.length ||
      oldIndex == targetIndex) {
    return;
  }
  final item = list.removeAt(oldIndex);
  list.insert(targetIndex, item);
}

/// 将列表元素从 [fromIndex] 移动到 0 基位置 [toIndex]
void _applyMoveTo<T>(List<T> list, int fromIndex, int toIndex) {
  if (fromIndex < 0 ||
      fromIndex >= list.length ||
      toIndex < 0 ||
      toIndex >= list.length ||
      fromIndex == toIndex) {
    return;
  }
  final item = list.removeAt(fromIndex);
  list.insert(toIndex, item);
}

/// 交换列表中两个下标的元素
void _applySwap<T>(List<T> list, int indexA, int indexB) {
  if (indexA < 0 ||
      indexA >= list.length ||
      indexB < 0 ||
      indexB >= list.length ||
      indexA == indexB) {
    return;
  }
  final temp = list[indexA];
  list[indexA] = list[indexB];
  list[indexB] = temp;
}

/// 拖拽浮起时的圆角与阴影装饰，避免原生白底方块遮挡卡片圆角
Widget _buildReorderProxyDecorator(
  Widget child,
  Animation<double> animation,
  double borderRadius,
) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, innerChild) {
      final elevation = 6.0 * animation.value;
      return Material(
        elevation: elevation,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: innerChild,
      );
    },
    child: child,
  );
}

/// 排序模式顶部说明条：展示当前操作提示与「点选交换」开关
class _ReorderBanner extends StatelessWidget {
  const _ReorderBanner({
    required this.isSwapMode,
    required this.swapFirstIndex,
    required this.onToggleSwapMode,
  });

  final bool isSwapMode;
  final int? swapFirstIndex;
  final ValueChanged<bool> onToggleSwapMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String hintText;
    if (!isSwapMode) {
      hintText = context.l10n.favoriteReorderHint;
    } else if (swapFirstIndex == null) {
      hintText = context.l10n.favoriteSwapHintIdle;
    } else {
      hintText = context.l10n.favoriteSwapHintSelected('${swapFirstIndex! + 1}');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: AnimatedContainer(
        duration: AppDesignTokens.motion(context, AppDesignTokens.fastMotion),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSwapMode
              ? scheme.primaryContainer.withValues(alpha: 0.7)
              : AppSurfaces.card(context),
          borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
          border: Border.all(
            color: isSwapMode ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSwapMode ? Icons.swap_horiz_rounded : Icons.drag_indicator_rounded,
              size: 18,
              color: isSwapMode ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hintText,
                style: TextStyle(
                  fontSize: 13,
                  color: isSwapMode
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: isSwapMode ? scheme.primary : AppSurfaces.inset(context),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                onTap: () => onToggleSwapMode(!isSwapMode),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 15,
                        color: isSwapMode ? scheme.onPrimary : scheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.favoriteSwapMode,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              isSwapMode ? scheme.onPrimary : scheme.onSurface,
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
    );
  }
}

/// 排序模式列表左侧可点击序号胶囊 `#1`
class _ReorderIndexChip extends StatelessWidget {
  const _ReorderIndexChip({
    required this.index,
    required this.isSelected,
    required this.onTapIndex,
  });

  final int index;
  final bool isSelected;
  final VoidCallback onTapIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected ? scheme.primary : AppSurfaces.inset(context),
      borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        onTap: onTapIndex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDesignTokens.radiusPill),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: Text(
            '#${index + 1}',
            style: AppTheme.number(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// 排序模式列表右侧控制区：上移、下移按钮 + 置顶/置底/输入序号/点选交换菜单
class _ReorderTrailingControls extends StatelessWidget {
  const _ReorderTrailingControls({
    required this.index,
    required this.totalCount,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onMoveToTop,
    required this.onMoveToBottom,
    required this.onMoveToIndex,
    required this.onSwap,
  });

  final int index;
  final int totalCount;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onMoveToTop;
  final VoidCallback onMoveToBottom;
  final VoidCallback onMoveToIndex;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canMoveUp = index > 0;
    final canMoveDown = index < totalCount - 1;
    const compactConstraints = BoxConstraints(minWidth: 30, minHeight: 32);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_upward_rounded, size: 18),
          tooltip: context.l10n.favoriteMoveUp,
          padding: EdgeInsets.zero,
          constraints: compactConstraints,
          visualDensity: VisualDensity.compact,
          onPressed: canMoveUp ? onMoveUp : null,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward_rounded, size: 18),
          tooltip: context.l10n.favoriteMoveDown,
          padding: EdgeInsets.zero,
          constraints: compactConstraints,
          visualDensity: VisualDensity.compact,
          onPressed: canMoveDown ? onMoveDown : null,
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18, color: scheme.onSurfaceVariant),
          padding: EdgeInsets.zero,
          constraints: compactConstraints,
          onSelected: (value) {
            switch (value) {
              case 'top':
                onMoveToTop();
                break;
              case 'bottom':
                onMoveToBottom();
                break;
              case 'index':
                onMoveToIndex();
                break;
              case 'swap':
                onSwap();
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem<String>(
              value: 'top',
              enabled: canMoveUp,
              child: Text(context.l10n.favoriteMoveToTop),
            ),
            PopupMenuItem<String>(
              value: 'bottom',
              enabled: canMoveDown,
              child: Text(context.l10n.favoriteMoveToBottom),
            ),
            PopupMenuItem<String>(
              value: 'index',
              child: Text(context.l10n.favoriteMoveToIndex),
            ),
            PopupMenuItem<String>(
              value: 'swap',
              child: Text(context.l10n.favoriteSwapMode),
            ),
          ],
        ),
      ],
    );
  }
}

/// 移动到指定序号弹窗（自管理 TextEditingController 并在 State.dispose 释放）
class _MoveToPositionDialog extends StatefulWidget {
  const _MoveToPositionDialog({
    required this.currentPosition,
    required this.maxPosition,
  });

  final int currentPosition;
  final int maxPosition;

  @override
  State<_MoveToPositionDialog> createState() => _MoveToPositionDialogState();
}

class _MoveToPositionDialogState extends State<_MoveToPositionDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.currentPosition}');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateText(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 1 || parsed > widget.maxPosition) {
      return context.l10n.favoriteMoveIndexInvalid('${widget.maxPosition}');
    }
    return null;
  }

  void _onChanged(String value) {
    final nextError = value.trim().isEmpty ? null : _validateText(value);
    if (nextError != _errorText) {
      setState(() => _errorText = nextError);
    }
  }

  void _confirm() {
    final error = _validateText(_controller.text);
    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    final target = int.parse(_controller.text.trim());
    Navigator.of(context).pop(target);
  }

  @override
  Widget build(BuildContext context) {
    final maxStr = '${widget.maxPosition}';
    return AppAlertDialog(
      title: Text(context.l10n.favoriteMoveIndexDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: _onChanged,
        onSubmitted: (_) => _confirm(),
        decoration: InputDecoration(
          hintText: context.l10n.favoriteMoveIndexDialogHint(maxStr),
          errorText: _errorText,
          errorBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.featureCancel),
        ),
        TextButton(
          onPressed: _confirm,
          child: Text(context.l10n.flowConfirm),
        ),
      ],
    );
  }
}
