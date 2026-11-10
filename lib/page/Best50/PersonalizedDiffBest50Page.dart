import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/service/CustomTagStore.dart';
import '../../utils/ChartDifficulty.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import '../../service/Best50/PersonalizedDiffBest50Service.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../SongInfoPage.dart';
import '../../service/Best50/PersonalizedDiffBest50ConvertToImgService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/manager/MaiTagsManager.dart';
import 'package:my_first_flutter_app/entity/DXRating/MaiTagsModel.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/Best50Ui.dart';
import '../../widgets/AppDialogs.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';
import 'package:my_first_flutter_app/widgets/AppToast.dart';
import '../../utils/MusicDataIndex.dart';

class PersonalizedDiffBest50Page extends StatefulWidget {
  const PersonalizedDiffBest50Page({super.key});

  @override
  _PersonalizedDiffBest50PageState createState() =>
      _PersonalizedDiffBest50PageState();
}

class _PersonalizedDiffBest50PageState
    extends State<PersonalizedDiffBest50Page> {
  Map<String, dynamic>? _diffBest50Data;
  List<Map<String, dynamic>> _diffSongs = [];
  List<Map<String, dynamic>> _remaining = [];
  List<dynamic>? _maimaiMusicData;
  bool _isLoading = true; // 只表示读取曲库，换标签时旧内容留在屏幕上
  bool _isRefreshing = false;
  int _loadGeneration = 0;
  int _resultVersion = 0; // 每换一批结果加一，新结果重新入场
  Future<void>? _activeLoad;
  int? _selectedTagId;
  String? _selectedTagName;

  // 尺寸相关变量
  late double screenWidth;
  late double cardPadding;
  late double fontSizeBase;

  @override
  void initState() {
    super.initState();
    _loadMusicData().then((_) => _selectFirstTag());
  }

  /// 进页面默认选中标签列表里的第一个（与选择对话框的顺序一致），而不是停在空状态。
  Future<void> _selectFirstTag() async {
    if (_selectedTagId != null) return;
    try {
      final tagsEntity = await MaiTagsManager().getTags();
      if (!mounted || _selectedTagId != null) return;
      final tags = tagsEntity?.tags;
      if (tags == null || tags.isEmpty) return;
      _selectTag(tags.first);
    } catch (e) {
      debugPrint('Error selecting default tag: $e');
    }
  }

  /// 选中标签并加载对应数据。自定义标签可能与 DXRating 标签同名，显示时加标记区分。
  void _selectTag(TagItem tag) {
    setState(() {
      _selectedTagId = tag.id;
      _selectedTagName = CustomTagStore.instance.isCustomTagId(tag.id)
          ? context.l10n.customTagMarked(tag.localizedName.zhHans)
          : tag.localizedName.zhHans;
    });
    _activeLoad = _loadDiffBest50Data();
  }

  Future<void> _loadMusicData() async {
    try {
      if (await MaimaiMusicDataManager().hasCachedData()) {
        final songs = await MaimaiMusicDataManager().getCachedSongs();
        if (songs != null) {
          setState(() {
            _maimaiMusicData = songs
                .map((song) => {
                      'id': song.id,
                      'title': song.title,
                      'type': song.type,
                      'ds': song.ds,
                      'level': song.level,
                      'cids': song.cids,
                      'is_extra': song.isExtra,
                      'charts': song.charts
                          .map((chart) =>
                              {'notes': chart.notes, 'charter': chart.charter})
                          .toList(),
                      'basic_info': {
                        'title': song.basicInfo.title,
                        'artist': song.basicInfo.artist,
                        'genre': song.basicInfo.genre,
                        'bpm': song.basicInfo.bpm,
                        'release_date': song.basicInfo.releaseDate,
                        'from': song.basicInfo.from,
                        'is_new': song.basicInfo.isNew
                      }
                    })
                .toList() as List<dynamic>;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading music data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDiffBest50Data() async {
    final tagId = _selectedTagId;
    if (tagId == null) return;

    final generation = ++_loadGeneration;
    setState(() {
      _isRefreshing = true;
    });

    try {
      final service = PersonalizedDiffBest50Service();
      final data = await service.getTagDiffBest50Data(tagId);
      if (!mounted || generation != _loadGeneration) return;

      setState(() {
        _diffBest50Data = data;
        _diffSongs = List<Map<String, dynamic>>.from(data?['diffBest50'] ?? []);
        _remaining = List<Map<String, dynamic>>.from(data?['remaining'] ?? []);
        _resultVersion++;
        _isRefreshing = false;
      });
    } catch (e) {
      debugPrint('Error loading diff best50 data: $e');
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _diffBest50Data = null;
        _diffSongs = [];
        _remaining = [];
        _resultVersion++;
        _isRefreshing = false;
      });
    }
  }

  // 显示标签选择对话框
  void _showTagSelectionDialog() async {
    final tagsEntity = await MaiTagsManager().getTags();
    if (tagsEntity == null || tagsEntity.tags.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AppAlertDialog(
            title: Text(context.l10n.featureNotice),
            content: Text(context.l10n.flowNoTagDataFound),
            actions: [
              TextButton(
                child: Text(context.l10n.featureOK),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    // 构建分组ID → 分组名称映射
    final Map<int, String> groupIdToName = {};
    for (var group in tagsEntity.tagGroups) {
      groupIdToName[group.id] = group.localizedName.zhHans;
    }

    // 按分组整理标签
    final Map<String, List<TagItem>> groupedTags = {};
    for (var tag in tagsEntity.tags) {
      final groupName = groupIdToName[tag.groupId] ?? '其他';
      groupedTags.putIfAbsent(groupName, () => []);
      groupedTags[groupName]!.add(tag);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowSelectTag),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: groupedTags.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ...entry.value.map((tag) {
                        return ListTile(
                          title: Text(tag.localizedName.zhHans),
                          subtitle: Text(tag.localizedDescription.zhHans),
                          dense: true,
                          selected: _selectedTagId == tag.id,
                          onTap: () {
                            if (_selectedTagId == tag.id) {
                              Navigator.of(context).pop();
                              return;
                            }
                            Navigator.of(context).pop();
                            _selectTag(tag);
                          },
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.featureCancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      PermissionStatus storageStatus = await Permission.storage.status;
      PermissionStatus photosStatus = await Permission.photos.status;
      PermissionStatus videosStatus = await Permission.videos.status;

      if (storageStatus.isGranted ||
          photosStatus.isGranted ||
          videosStatus.isGranted) {
        return true;
      }

      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();

      bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      bool videosGranted = statuses[Permission.videos]?.isGranted ?? false;

      return storageGranted || photosGranted || videosGranted;
    } else {
      PermissionStatus status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  // 导出为图片
  Future<void> _exportToImage() async {
    try {
      // 等切换中的结果到位，避免按新标签名导出旧列表。
      await _activeLoad;
      if (!mounted) return;
      if (_diffSongs.isEmpty) {
        showAppNoticeDialog(context,
            title: context.l10n.featureNotice,
            message: context.l10n.flowNoDataToExport);
        return;
      }

      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        showAppNoticeDialog(context,
            title: context.l10n.flowPermissionRequired,
            message: context.l10n.flowStoragePermissionIsRequiredToExportImages,
            tone: AppDialogTone.warning);
        return;
      }

      // 先弹出质量选择器
      final quality = await ExportQualitySelector.show(
        context,
        estimatedPngSize:
            ImageEncodeUtil.estimatePngSize(songCount: _diffSongs.length),
        exportingLabel: context.l10n.featureCustomFittedBest50,
        enableThunderMode: true,
        previewBuilder: (previewContext, previewQuality) =>
            PersonalizedDiffBest50ConvertToImg.buildPreviewWidget(
          previewContext,
          context.l10n.flowPersonalizedFittedBest50P0(
              (_selectedTagName ?? context.l10n.flowTags).toString()),
          _diffBest50Data,
          _diffSongs,
          _maimaiMusicData,
          thunderMode: previewQuality.thunderMode,
          thunderVertical: previewQuality.thunderVertical,
          theme: previewQuality.theme,
        ),
      );
      if (quality == null) return;

      String title = context.l10n.flowPersonalizedFittedBest50P0(
          (_selectedTagName ?? context.l10n.flowTags).toString());

      BackgroundExport.run(
        label: context.l10n.featureCustomFittedBest50,
        task: (exportContext) =>
            PersonalizedDiffBest50ConvertToImg.convertToImage(
          exportContext,
          title,
          _diffBest50Data,
          _diffSongs,
          _maimaiMusicData,
          jpegQuality: quality.jpegQuality,
          theme: quality.theme,
          thunderMode: quality.thunderMode,
          thunderVertical: quality.thunderVertical,
        ),
      );
    } catch (e) {
      AppToast.show(context.l10n.flowExportFailedP02((e).toString()),
          tone: AppToastTone.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    cardPadding = screenWidth * 0.02;
    fontSizeBase = screenWidth * 0.035;

    return BackgroundPageScaffold(
      title: context.l10n.featureCustomFittedBest50,
      resizeToAvoidBottomInset: false,
      actionsEndInset: 4,
      actions: [
        if (_selectedTagId != null && _diffSongs.isNotEmpty) ...[
          Best50IconAction(
            tooltip: context.l10n.flowExportAsImage,
            icon: Icons.image_outlined,
            onPressed: () async {
              try {
                await _exportToImage();
              } catch (e) {
                debugPrint('Error in personalized diff export: $e');
              }
            },
          ),
        ],
      ],
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Stack(
        children: [
          // 内容区域 - 卡片占满可用高度，空状态内容居中显示
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
                AppDesignTokens.gutter, AppDesignTokens.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标签选择按钮（始终在顶部）
                Best50ActionButton(
                  icon: Icons.sell_outlined,
                  label: _selectedTagName != null
                      ? context.l10n
                          .flowSelectTagP0((_selectedTagName).toString())
                      : context.l10n.flowSelectTag,
                  onPressed: _showTagSelectionDialog,
                ),
                SizedBox(height: 12.0),

                // 状态分支：未选标签 / 已选标签无数据 / 已选标签有数据
                // 空状态用 Expanded + Center 让内容垂直居中，避免下方留白
                if (!_isLoading && !_isRefreshing && _selectedTagId == null)
                  Expanded(child: Center(child: _buildEmptyHint())),

                if (!_isLoading &&
                    !_isRefreshing &&
                    _selectedTagId != null &&
                    _diffSongs.isEmpty)
                  Expanded(child: Center(child: _buildNoDataHint())),

                // 有数据时滚动展示
                if (!_isLoading &&
                    _selectedTagId != null &&
                    _diffSongs.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildRatingSection(),
                          const SizedBox(height: AppDesignTokens.cardGap),
                          Best50Grid(
                            items: [
                              for (final s in _diffSongs)
                                _cardData(Map<String, dynamic>.from(s))
                            ],
                            remaining: [
                              for (final s in _remaining)
                                _cardData(Map<String, dynamic>.from(s))
                            ],
                            remainingLabel:
                                'RA ${_diffSongs.last['diffRating']}',
                            contentKey: _resultVersion,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 还没有内容可留时才显示转圈；有旧内容时留到新结果到达
          if ((_isLoading || _isRefreshing) &&
              _selectedTagId != null &&
              _diffSongs.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surface
                      .withValues(alpha: 0.5),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                            color: Theme.of(context).colorScheme.onSurface),
                        SizedBox(height: 16),
                        Text(
                          context.l10n.flowCalculatingPersonalizedFittedBest50,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 未选择标签时的提示
  Widget _buildEmptyHint() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.label_outline,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 12),
          Text(
            context.l10n.flowSelectATagFirst,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.flowSelectATagToShowYourTop,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 无数据提示
  Widget _buildNoDataHint() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.refresh,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 12),
          Text(
            context.l10n
                .flowNoFittedBest50DataForTagP0((_selectedTagName).toString()),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.flowNoMatchingPlayRecordsMayExistTry,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showTagSelectionDialog,
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: Text(context.l10n.flowChangeTag),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.linkBlue(Theme.of(context).brightness),
            ),
          ),
        ],
      ),
    );
  }

  // 构建评分区域
  Widget _buildRatingSection() {
    int diffRatingSum = _diffBest50Data?['diffRatingSum'] ?? 0;
    double diffRatingAverage =
        _diffSongs.isNotEmpty ? diffRatingSum / _diffSongs.length : 0.0;

    // 计算平均达成率
    double achievementsSum = _diffSongs.fold(
        0.0,
        (sum, song) =>
            sum + (double.tryParse(song['achievements'].toString()) ?? 0.0));
    double averageAchievement =
        _diffSongs.isNotEmpty ? achievementsSum / _diffSongs.length : 0.0;

    // 计算平均scoreRate
    double scoreRateSum = _diffSongs.fold(0.0, (sum, song) {
      int songId = song['song_id'] ?? 0;
      int levelIndex = song['level_index'] ?? 0;
      int score = song['dxScore'] ?? 0;
      return sum + _calculateScoreRate(songId, levelIndex, score);
    });
    double averageScoreRate =
        _diffSongs.isNotEmpty ? scoreRateSum / _diffSongs.length : 0.0;

    // 计算暂无拟合定数的歌曲数量
    int noFitDiffCount = _diffSongs.where((song) {
      return song['use_official_diff'] ?? false;
    }).length;

    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Best50Hero(
          total: diffRatingSum,
          label: context.l10n.flowFittedTotalRatingDifferenceFromThisTag(
              (diffRatingAverage.toStringAsFixed(1)).toString()),
          delta: (_diffBest50Data?['best50Diff'] as num?)?.toInt(),
        ),
        const SizedBox(height: 8),
        Best50MetaLine(context.l10n.flowTagP0P1ChartsTop50By(
            (_selectedTagName ?? '').toString(),
            (_diffSongs.length).toString())),
        if (noFitDiffCount > 0) ...[
          const SizedBox(height: 4),
          Best50MetaLine(
              context.l10n.flowP0ChartsHaveNoFittedConstantOfficial(
                  (noFitDiffCount).toString()),
              color: AppColors.warningOrange(brightness)),
        ],
        const SizedBox(height: AppDesignTokens.cardGap),
        Best50AveragesCard(
          rows: [
            Best50AverageRow(
                context.l10n.flowAverage, averageAchievement, averageScoreRate),
          ],
        ),
      ],
    );
  }

  // 构建区域标题

  // 构建数据卡片网格
  Best50CardData _cardData(Map<String, dynamic> songData) {
    final int score = songData['dxScore'] ?? 0;
    final int levelIndex = songData['level_index'] ?? 0;
    final int songId = songData['song_id'] ?? 0;
    return Best50CardData(
      songId: songId,
      title: songData['title'] ?? context.l10n.flowUnknownSong,
      levelIndex: levelIndex,
      type: songData['type'] ?? '',
      rating: songData['diffRating'] ?? 0,
      ds: double.tryParse(songData['fit_diff'].toString()) ?? 0.0,
      isFitDiff: true,
      achievement: double.tryParse(songData['achievements'].toString()) ?? 0.0,
      fc: songData['fc'] ?? '',
      fs: songData['fs'] ?? '',
      stars: StringUtil.formatStars(
          _calculateScoreRate(songId, levelIndex, score)),
      dxScore: score,
      maxDxScore: _calculateMaxScore(songId, levelIndex),
      onOpenSong: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongInfoPage(
            songId: songId.toString(),
            initialLevelIndex:
                ChartDifficulty.parseStandardIndex(songData['level_index']),
          ),
        ),
      ),
    );
  }

  // 根据数据构建游戏卡片

  // 构建游戏卡片（委托至通用 widget B50GameCardWidget，
  // 字号按卡片**实际**宽度自适应（`scale: autoScale`）。
  // 注：原 useOfficialDiff（黄星标记）已废弃，统一不在卡片中显示。

  // 构建小数文本

  // 构建双小数文本

  // 根据level_index获取卡片颜色

  // 计算scoreRate
  double _calculateScoreRate(int songId, int levelIndex, int score) {
    if (_maimaiMusicData == null) return 0.0;

    int songIndex = MusicDataIndex.indexOf(_maimaiMusicData!, songId);

    if (songIndex == -1) return 0.0;
    dynamic songData = _maimaiMusicData![songIndex];

    if (songData['charts'] == null) return 0.0;

    List<dynamic> charts = songData['charts'];
    if (levelIndex < 0 || levelIndex >= charts.length) return 0.0;

    dynamic chart = charts[levelIndex];
    if (chart['notes'] == null) return 0.0;

    List<dynamic> notes = chart['notes'];
    int notesSum = notes.fold(0, (sum, note) => sum + (note as int));
    int maxScore = notesSum * 3;

    return maxScore > 0 ? score / maxScore : 0.0;
  }

  // 计算指定歌曲/难度的满分（notes * 3），供通用卡片展示 分数/满分
  int _calculateMaxScore(int songId, int levelIndex) {
    if (_maimaiMusicData == null) return 0;
    final songIndex = MusicDataIndex.indexOf(_maimaiMusicData!, songId);
    if (songIndex == -1) return 0;
    final songData = _maimaiMusicData![songIndex];
    if (songData['charts'] == null) return 0;
    final List<dynamic> charts = songData['charts'];
    if (levelIndex < 0 || levelIndex >= charts.length) return 0;
    final chart = charts[levelIndex];
    if (chart['notes'] == null) return 0;
    final List<dynamic> notes = chart['notes'];
    final notesSum = notes.fold<int>(0, (sum, note) => sum + (note as int));
    return notesSum * 3;
  }

  // 构建导出按钮
}
