import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
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
import '../../widgets/B50GameCardWidget.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';

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
  List<dynamic>? _maimaiMusicData;
  bool _isLoading = true;
  int? _selectedTagId;
  String? _selectedTagName;

  // 尺寸相关变量
  late double screenWidth;
  late double cardPadding;
  late double fontSizeBase;

  @override
  void initState() {
    super.initState();
    _loadMusicData();
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
    if (_selectedTagId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service = PersonalizedDiffBest50Service();
      final data = await service.getTagDiffBest50Data(_selectedTagId!);

      setState(() {
        _diffBest50Data = data;
        _diffSongs = List<Map<String, dynamic>>.from(data?['diffBest50'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading diff best50 data: $e');
      setState(() {
        _diffBest50Data = null;
        _diffSongs = [];
        _isLoading = false;
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
          return AlertDialog(
            title: Text('提示'),
            content: Text('没有找到标签数据'),
            actions: [
              TextButton(
                child: Text('确定'),
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
        return AlertDialog(
          title: Text('选择标签'),
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
                          subtitle: Text(tag.localizedDescription.zhHans,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          dense: true,
                          selected: _selectedTagId == tag.id,
                          onTap: () {
                            setState(() {
                              _selectedTagId = tag.id;
                              _selectedTagName = tag.localizedName.zhHans;
                            });
                            Navigator.of(context).pop();
                            _loadDiffBest50Data();
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
              child: Text('取消'),
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
      if (_diffSongs.isEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('提示'),
            content: Text('没有数据可导出'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
        return;
      }

      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('权限不足'),
            content: Text('需要存储权限才能导出图片到相册，请在设置中开启权限'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
        return;
      }

      // 先弹出质量选择器
      final quality = await ExportQualitySelector.show(
        context,
        estimatedPngSize:
            ImageEncodeUtil.estimatePngSize(songCount: _diffSongs.length),
        exportingLabel: '个性化拟合 Best50',
        enableThunderMode: true,
        previewBuilder: (previewContext, previewQuality) =>
            PersonalizedDiffBest50ConvertToImg.buildPreviewWidget(
          previewContext,
          '个性化拟合Best50 - ${_selectedTagName ?? '标签'}',
          _diffBest50Data,
          _diffSongs,
          _maimaiMusicData,
          thunderMode: previewQuality.thunderMode,
          thunderVertical: previewQuality.thunderVertical,
        ),
      );
      if (quality == null) return;

      // 显示加载指示器
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('导出中'),
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16.0),
              Text('正在生成图片...'),
            ],
          ),
        ),
      );

      String title = '个性化拟合Best50 - ${_selectedTagName ?? '标签'}';

      final file = await PersonalizedDiffBest50ConvertToImg.convertToImage(
        context,
        title,
        _diffBest50Data,
        _diffSongs,
        _maimaiMusicData,
        jpegQuality: quality.jpegQuality,
        thunderMode: quality.thunderMode,
        thunderVertical: quality.thunderVertical,
      );

      // 关闭加载指示器
      Navigator.pop(context);

      if (file != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('导出成功'),
            content: Text('图片已保存到：\n${file.path}'),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: file.path));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('路径已复制到剪贴板')),
                  );
                },
                child: Text('复制路径'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('导出失败'),
            content: Text('图片导出失败，请重试'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('导出失败'),
          content: Text('导出过程中出现错误：\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    cardPadding = screenWidth * 0.02;
    fontSizeBase = screenWidth * 0.035;

    return BackgroundPageScaffold(
      title: '个性化拟合Best50查询',
      resizeToAvoidBottomInset: false,
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
                      ? '选择标签: $_selectedTagName'
                      : '选择标签',
                  onPressed: _showTagSelectionDialog,
                ),
                SizedBox(height: 12.0),

                // 状态分支：未选标签 / 已选标签无数据 / 已选标签有数据
                // 空状态用 Expanded + Center 让内容垂直居中，避免下方留白
                if (!_isLoading && _selectedTagId == null)
                  Expanded(child: Center(child: _buildEmptyHint())),

                if (!_isLoading && _selectedTagId != null && _diffSongs.isEmpty)
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
                          SizedBox(height: 12.0),
                          _buildExportButton(),
                          SizedBox(height: 12.0),
                          _buildSectionTitle('基于拟合难度的个性化Best50', context),
                          _buildDataCardGrid(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 加载中遮罩（覆盖在卡片之上）
          if (_isLoading && _selectedTagId != null)
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
                          '正在计算个性化拟合Best50...',
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
            '请先选择一个标签',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            '选择标签后，将显示包含该标签且有游玩记录\n在拟合定数下RA前50的谱面',
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
            '暂无标签"$_selectedTagName"的拟合Best50数据',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            '该标签可能没有对应的游玩记录\n可尝试更换其他标签',
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
            label: const Text('更换标签'),
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
    final scheme = Theme.of(context).colorScheme;
    return Best50SummaryCard(
      label: '拟合总 Rating',
      rating: diffRatingSum,
      ratingAverage: diffRatingAverage,
      showTier: false,
      averages: [
        Best50AverageRow('平均', averageAchievement, averageScoreRate),
      ],
      footer: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            if (_selectedTagName != null)
              AppBadge(
                  text: '标签：$_selectedTagName',
                  numeric: false,
                  background: scheme.secondaryContainer,
                  foreground: scheme.onSecondaryContainer),
            AppBadge(
                text: '共${_diffSongs.length}张谱面',
                numeric: false,
                background: AppSurfaces.inset(context),
                foreground: scheme.onSurfaceVariant),
          ],
        ),
        if (noFitDiffCount > 0)
          Text(
            '$noFitDiffCount首暂无拟合定数，按照官方定数计算',
            style: TextStyle(
                fontSize: 12, color: AppColors.warningOrange(brightness)),
          ),
        Text(
          '在拟合定数下计算单曲Rating，取前50的谱面',
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  // 构建区域标题
  Widget _buildSectionTitle(String title, BuildContext context) =>
      Best50SectionHeader(title);

  // 构建数据卡片网格
  Widget _buildDataCardGrid() {
    // 按当前列表里实际最大 ID 位数作为占位宽度：无 6 位则严格用 5 位，5 位 ID 与 chip 之间不留空
    final int maxIdLength = _diffSongs.isEmpty
        ? 5
        : _diffSongs
            .map((s) => s['song_id'].toString().length)
            .reduce((a, b) => a > b ? a : b);
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: B50GameCardWidget.designAspectRatio,
      ),
      itemCount: _diffSongs.length,
      itemBuilder: (context, index) {
        return _buildDataGameCard(_diffSongs[index], maxIdLength: maxIdLength);
      },
    );
  }

  // 根据数据构建游戏卡片
  Widget _buildDataGameCard(Map<String, dynamic> songData,
      {required int maxIdLength}) {
    double achievementRate =
        double.tryParse(songData['achievements'].toString()) ?? 0.0;
    int score = songData['dxScore'] ?? 0;
    String fc = songData['fc'] ?? '';
    String fs = songData['fs'] ?? '';
    double difficulty = double.tryParse(songData['fit_diff'].toString()) ?? 0.0;
    String rate = songData['rate'] ?? '';
    int levelIndex = songData['level_index'] ?? 0;
    int rating = songData['diffRating'] ?? 0;
    String type = songData['type'] ?? '';
    String title = songData['title'] ?? '未知歌曲';
    int songId = songData['song_id'] ?? 0;

    // 计算星星等级
    double scoreRate = _calculateScoreRate(songId, levelIndex, score);
    String stars = StringUtil.formatStars(scoreRate);
    Color starsColor = ColorUtil.getStarsColor(stars);

    // 计算满分（notes * 3），通用卡片需要展示 分数/满分
    int maxScore = _calculateMaxScore(songId, levelIndex);

    // 获取卡片颜色
    Color cardColor;
    if (songId.toString().length == 6) {
      cardColor = AppColors.utageCard();
    } else {
      cardColor = _getCardColor(levelIndex);
    }

    bool dxMode = type == 'DX';
    bool isUtage = songId.toString().length == 6;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(
              songId: songId.toString(),
              initialLevelIndex: levelIndex,
              isDefaultLevelIndex: false,
            ),
          ),
        );
      },
      child: _buildGameCard(
        cardColor: cardColor,
        songName: title,
        achievementRate: achievementRate,
        difficulty: difficulty,
        dxMode: dxMode,
        isUtage: isUtage,
        score: score,
        maxScore: maxScore,
        rating: rating,
        stars: stars,
        fc: fc,
        fs: fs,
        rate: rate,
        songId: songId,
        starsColor: starsColor,
        maxIdLength: maxIdLength,
      ),
    );
  }

  // 构建游戏卡片（委托至通用 widget B50GameCardWidget，
  // 字号按卡片**实际**宽度自适应（`scale: autoScale`）。
  // 注：原 useOfficialDiff（黄星标记）已废弃，统一不在卡片中显示。
  Widget _buildGameCard({
    required Color cardColor,
    String songName = '未知歌曲',
    double achievementRate = 0.0,
    double difficulty = 0.0,
    bool dxMode = false,
    bool isUtage = false,
    int score = 0,
    int maxScore = 0,
    int rating = 0,
    String stars = '',
    String fc = '',
    String fs = '',
    String rate = '',
    int? songId,
    Color starsColor = Colors.white,
    int maxIdLength = 5,
  }) {
    final int id = songId ?? 0;

    return B50GameCardWidget(
      cardColor: cardColor,
      songName: songName,
      achievementRate: achievementRate,
      difficulty: difficulty,
      dxMode: dxMode,
      isUtage: isUtage,
      score: score,
      maxScore: maxScore,
      rating: rating,
      stars: stars,
      fc: fc,
      fs: fs,
      rate: rate,
      songId: id,
      starsColor: starsColor,
      maxIdLength: maxIdLength,
      // 字号按卡片**实际**宽度自适应：别拿屏幕宽度估（容器 padding /
      // 网格间距都会从可用宽里扣掉）。
      scale: B50GameCardWidget.autoScale,
    );
  }

  // 构建小数文本

  // 构建双小数文本

  // 根据level_index获取卡片颜色
  Color _getCardColor(int levelIndex) {
    List<Color> colors = [
      Colors.green,
      Colors.yellow,
      Colors.red,
      Colors.purple.shade400,
      Colors.purple.shade200,
    ];
    return colors[levelIndex.clamp(0, 4)];
  }

  // 计算scoreRate
  double _calculateScoreRate(int songId, int levelIndex, int score) {
    if (_maimaiMusicData == null) return 0.0;

    int songIndex = _maimaiMusicData!.indexWhere(
      (item) => item['id'] == songId.toString(),
    );

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
    final songIndex = _maimaiMusicData!.indexWhere(
      (item) => item['id'] == songId.toString(),
    );
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
  Widget _buildExportButton() {
    return Best50ActionButton(
      icon: Icons.image_outlined,
      label: '导出为图片',
      primary: true,
      onPressed: () async {
        try {
          await _exportToImage();
        } catch (e) {
          debugPrint('Error in personalized diff export: $e');
        }
      },
    );
  }
}
