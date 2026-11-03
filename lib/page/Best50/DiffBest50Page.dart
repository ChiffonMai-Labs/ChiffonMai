// ignore: file_names
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import '../../service/Best50/DiffBest50Service.dart';
import '../../service/Best50/DiffBest50ConvertToImgService.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../SongInfoPage.dart';
import '../../utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/Best50Ui.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/ExportSuccessDialog.dart';

class DiffBest50Page extends StatefulWidget {
  const DiffBest50Page({super.key});

  @override
  _DiffBest50PageState createState() => _DiffBest50PageState();
}

class _DiffBest50PageState extends State<DiffBest50Page> {
  int _segment = 0; // 模式 B / C 下：0 = B35，1 = B15
  Map<String, dynamic>? _diffBest50Data;
  List<dynamic>? _maimaiMusicData;
  List<Map<String, dynamic>> _diffSongs = [];
  List<Map<String, dynamic>> _diffSdSongs = []; // Best35 - 非当前版本
  List<Map<String, dynamic>> _diffDxSongs = []; // Best15 - 当前版本
  bool _isLoading = true;

  // 拟合Best50模式：0为模式A，1为模式B，2为模式C
  int _currentMode = 0;

  // 尺寸相关变量
  late double screenWidth;
  late double screenHeight;
  late double cardPadding;
  late double fontSizeBase;

  @override
  void initState() {
    super.initState();
    _loadDiffBest50Data();
  }

  Future<void> _loadDiffBest50Data() async {
    try {
      // 加载maimai音乐数据
      // 直接使用缓存的API数据
      if (await MaimaiMusicDataManager().hasCachedData()) {
        final songs = await MaimaiMusicDataManager().getCachedSongs();
        if (songs != null && mounted) {
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
                .toList();
          });
        }
      }

      // 根据模式计算DiffBest50数据
      final diffBest50Service = DiffBest50Service();
      late final diffBest50Data;
      switch (_currentMode) {
        case 0:
          diffBest50Data = await diffBest50Service
              .calculateDiffBest50(); // 模式A：按拟合Rating重新排序
          break;
        case 1:
          diffBest50Data =
              await diffBest50Service.calculateDiffBest50ModeB(); // 模式B：保持原有排名
          break;
        case 2:
          diffBest50Data = await diffBest50Service
              .calculateDiffBest50ModeC(); // 模式C：分别在SD/DX中取前50
          break;
        default:
          diffBest50Data = await diffBest50Service.calculateDiffBest50();
      }

      if (!mounted) return;
      setState(() {
        _diffBest50Data = diffBest50Data;
        _diffSongs =
            List<Map<String, dynamic>>.from(diffBest50Data['diffBest50'] ?? []);
        _diffSdSongs = List<Map<String, dynamic>>.from(
            diffBest50Data['diffSdSongs'] ?? []);
        _diffDxSongs = List<Map<String, dynamic>>.from(
            diffBest50Data['diffDxSongs'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _diffBest50Data = null;
          _diffSongs = [];
          _diffSdSongs = [];
          _diffDxSongs = [];
          _isLoading = false;
        });
      }
    }
  }

  // 切换拟合模式
  void _toggleMode() {
    setState(() {
      _currentMode = (_currentMode + 1) % 3;
      _isLoading = true;
    });
    _loadDiffBest50Data();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // 初始化尺寸相关变量
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    cardPadding = screenWidth * 0.02;
    fontSizeBase = screenWidth * 0.035;

    return BackgroundPageScaffold(
      title: '拟合 Best50',
      resizeToAvoidBottomInset: false,
      actionsEndInset: 4,
      actions: [
        Best50IconAction(
          tooltip: '导出为图片',
          icon: Icons.image_outlined,
          onPressed: () async {
            debugPrint('=== DIFF EXPORT BUTTON CLICKED ===');
            try {
              await _exportToImage();
            } catch (e) {
              debugPrint('Error in diff export: $e');
            }
          },
        ),
      ],
      contentPadding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 加载中状态（覆盖层）
          if (_isLoading)
            Container(
              color: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onSurface),
                    SizedBox(height: 16),
                    Text(
                      '正在计算拟合Best50...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 内容
          if (!_isLoading) _buildContent(brightness),
        ],
      ),
    );
  }

  // 构建内容区域
  Widget _buildContent(Brightness brightness) {
    // 如果没有数据，显示空状态
    if (_diffBest50Data == null || _diffSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              size: 64,
              color: AppColors.greyHint(brightness),
            ),
            SizedBox(height: 16),
            Text(
              '暂无拟合Best50数据',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '请返回首页点击"刷新数据"按钮获取',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // 模式 A 不分 B35 / B15，模式 B / C 才有分段。
    final List<dynamic> songs = _currentMode == 0
        ? _diffSongs
        : (_segment == 0 ? _diffSdSongs : _diffDxSongs);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppDesignTokens.gutter,
        4,
        AppDesignTokens.gutter,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRatingSection(),
          const SizedBox(height: AppDesignTokens.cardGap),
          Best50Grid(
            key: ValueKey('$_currentMode-$_segment'),
            items: [
              for (final s in songs) _cardData(Map<String, dynamic>.from(s))
            ],
            remaining: [
              for (final s in (_diffBest50Data?[_currentMode == 0
                      ? 'remaining'
                      : (_segment == 0 ? 'sdRemaining' : 'dxRemaining')] as List?) ??
                  const [])
                _cardData(Map<String, dynamic>.from(s as Map))
            ],
            remainingLabel:
                songs.isEmpty ? null : 'RA ${_toInt(songs.last['diffRating'])}',
          ),
        ],
      ),
    );
  }

  // 构建评分区域
  Widget _buildRatingSection() {
    // 计算各项指标
    int diffRatingSum = _toInt(_diffBest50Data?['diffRatingSum']);
    int best50Diff = _toInt(_diffBest50Data?['best50Diff']);
    double diffRatingAverage =
        _diffSongs.isNotEmpty ? diffRatingSum / _diffSongs.length : 0.0;

    // 计算平均达成率
    double achievementsSum = _diffSongs.fold(
        0.0, (sum, song) => sum + _toDouble(song['achievements']));
    double diffBest50AchievementAverage =
        _diffSongs.isNotEmpty ? achievementsSum / _diffSongs.length : 0.0;

    // 计算平均scoreRate
    double scoreRateSum = _diffSongs.fold(0.0, (sum, song) {
      int songId = _toInt(song['song_id']);
      int levelIndex = _toInt(song['level_index']);
      int score = _toInt(song['dxScore']);
      return sum + _calculateScoreRate(songId, levelIndex, score);
    });

    double diffBest50ScoreRateAverage =
        _diffSongs.isNotEmpty ? scoreRateSum / _diffSongs.length : 0.0;

    // 计算暂无拟合定数的歌曲数量（使用官方定数的歌曲）
    int noFitDiffCount = _diffSongs.where((song) {
      return song['use_official_diff'] ?? false;
    }).length;

    final ratingBrightness = Theme.of(context).brightness;
    const modeNotes = [
      '模式A：不分类Best35和Best15，直接获取拟合定数下的Rating前50的谱面',
      '模式B：将您的Best35和Best15中的所有谱面的定数都替换为其拟合定数，然后计算Rating并降序排序',
      '模式C：在非当前版本中取拟合定数下的Rating前35的谱面，在当前版本中取拟合定数下Rating前15的谱面',
    ];
    int sumOf(List<dynamic> list) =>
        list.fold<int>(0, (sum, s) => sum + _toInt(s['diffRating']));
    final b35 = sumOf(_diffSdSongs);
    final b15 = sumOf(_diffDxSongs);
    final split = _currentMode != 0;
    final segmentSongs = _segment == 0 ? _diffSdSongs : _diffDxSongs;
    final segmentName = _segment == 0
        ? (_currentMode == 1 ? '非当前版本最好成绩' : '非当前版本前 35')
        : (_currentMode == 1 ? '当前版本最好成绩' : '当前版本前 15');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Best50Hero(
          total: diffRatingSum,
          label:
              '拟合总 Rating · 较 Best50（平均 ${diffRatingAverage.toStringAsFixed(1)}）',
          delta: best50Diff,
          best35Sum: split ? b35 : null,
          best15Sum: split ? b15 : null,
          trailing: Best50ActionPill(
            icon: Icons.tune_rounded,
            label: '模式 ${['A', 'B', 'C'][_currentMode]}',
            onTap: _toggleMode,
          ),
        ),
        const SizedBox(height: AppDesignTokens.cardGap),
        if (split) ...[
          SegmentedTabs(
            inlineCaption: true,
            items: [
              SegmentedTabItem('B35', caption: '$b35'),
              SegmentedTabItem('B15', caption: '$b15'),
            ],
            selectedIndex: _segment,
            onChanged: (i) => setState(() => _segment = i),
          ),
          const SizedBox(height: 8),
          Best50MetaLine(best50MetaText(segmentName,
              segmentSongs.map((s) => _toInt(s['diffRating'])))),
          const SizedBox(height: 4),
        ],
        Best50MetaLine(modeNotes[_currentMode]),
        if (noFitDiffCount > 0) ...[
          const SizedBox(height: 4),
          Best50MetaLine('$noFitDiffCount首暂无拟合定数，按照官方定数计算',
              color: AppColors.warningOrange(ratingBrightness)),
        ],
        const SizedBox(height: AppDesignTokens.cardGap),
        Best50AveragesCard(
          rows: [
            Best50AverageRow('B50', diffBest50AchievementAverage,
                diffBest50ScoreRateAverage),
          ],
        ),
      ],
    );
  }

  // 构建区域标题

  // 构建游戏卡片（委托至通用 widget B50GameCardWidget，
  // 字号按卡片**实际**宽度自适应（`scale: autoScale`）。
  // 注：原 useOfficialDiff（黄星标记）已废弃，统一不在卡片中显示。


  // 构建小数文本，整数部分字号大，小数部分和百分号字号小且底部对齐

  // 构建双小数文本，如 "100.1234/97.54"

  // 构建数据驱动的卡片网格


  // 根据数据构建游戏卡片


  // 根据level_index获取卡片颜色


  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  // 计算scoreRate
  double _calculateScoreRate(int songId, int levelIndex, int score) {
    if (_maimaiMusicData == null) return 0.0;

    // 查找对应的歌曲
    int songIndex = _maimaiMusicData!.indexWhere(
      (item) => item['id'] == songId.toString(),
    );

    if (songIndex == -1) return 0.0;
    dynamic songData = _maimaiMusicData![songIndex];

    if (songData['charts'] == null) return 0.0;

    // 查找对应的charts
    List<dynamic> charts = songData['charts'];
    if (levelIndex < 0 || levelIndex >= charts.length) return 0.0;

    dynamic chart = charts[levelIndex];
    if (chart['notes'] == null) return 0.0;

    // 计算maxScore
    List<dynamic> notes = chart['notes'];
    int notesSum = notes.fold(0, (sum, note) => sum + _toInt(note));
    int maxScore = notesSum * 3;

    // 计算scoreRate
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
    final notesSum = notes.fold<int>(0, (sum, note) => sum + _toInt(note));
    return notesSum * 3;
  }

  // 构建导出按钮


  Best50CardData _cardData(Map<String, dynamic> songData) {
    final score = _toInt(songData['dxScore']);
    final levelIndex = _toInt(songData['level_index']);
    final songId = _toInt(songData['song_id']);
    return Best50CardData(
      songId: songId,
      title: songData['title']?.toString() ?? '未知歌曲',
      levelIndex: levelIndex,
      type: songData['type']?.toString() ?? '',
      rating: _toInt(songData['diffRating']),
      ds: _toDouble(songData['fit_diff']),
      isFitDiff: true,
      achievement: _toDouble(songData['achievements']),
      fc: songData['fc']?.toString() ?? '',
      fs: songData['fs']?.toString() ?? '',
      stars: StringUtil.formatStars(
          _calculateScoreRate(songId, levelIndex, score)),
      dxScore: score,
      maxDxScore: _calculateMaxScore(songId, levelIndex),
      onOpenSong: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongInfoPage(
            songId: songId.toString(),
            initialLevelIndex: levelIndex,
            isDefaultLevelIndex: false,
          ),
        ),
      ),
    );
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    debugPrint('Page: _requestStoragePermission called');
    debugPrint('Page: Platform.isAndroid = ${Platform.isAndroid}');

    if (Platform.isAndroid) {
      debugPrint('Page: Running on Android');

      // 策略：同时请求 storage、photos 和 videos 权限，确保覆盖所有 Android 版本
      // Android 13+ 需要 photos/videos 权限
      // Android 12 及以下需要 storage 权限

      // 先检查已有权限状态
      debugPrint('Page: Checking existing permissions...');
      PermissionStatus storageStatus = await Permission.storage.status;
      PermissionStatus photosStatus = await Permission.photos.status;
      PermissionStatus videosStatus = await Permission.videos.status;

      debugPrint('Page: Storage status = $storageStatus');
      debugPrint('Page: Photos status = $photosStatus');
      debugPrint('Page: Videos status = $videosStatus');

      // 如果任何一个权限已授予，直接返回成功
      if (storageStatus.isGranted ||
          photosStatus.isGranted ||
          videosStatus.isGranted) {
        debugPrint('Page: At least one permission already granted');
        return true;
      }

      // 请求权限：同时请求 storage、photos 和 videos
      debugPrint('Page: Requesting storage, photos and videos permissions...');
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.photos,
        Permission.videos,
      ].request();

      bool storageGranted = statuses[Permission.storage]?.isGranted ?? false;
      bool photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      bool videosGranted = statuses[Permission.videos]?.isGranted ?? false;

      debugPrint('Page: Storage granted = $storageGranted');
      debugPrint('Page: Photos granted = $photosGranted');
      debugPrint('Page: Videos granted = $videosGranted');

      return storageGranted || photosGranted || videosGranted;
    } else {
      // 非 Android 平台
      debugPrint('Page: Non-Android platform');
      PermissionStatus status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  // 导出为图片
  Future<void> _exportToImage() async {
    try {
      // 先请求存储权限
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        showAppNoticeDialog(context, title: '权限不足', message: '需要存储权限才能导出图片到相册，请在设置中开启权限', tone: AppDialogTone.warning);
        return;
      }

      // 显示质量选择器
      final quality = await ExportQualitySelector.show(
        context,
        estimatedPngSize: ImageEncodeUtil.estimatePngSize(songCount: 50),
        exportingLabel: '拟合 Best50',
        enableThunderMode: true,
        previewBuilder: (previewContext, previewQuality) =>
            DiffBest50ConvertToImg.buildPreviewWidget(
          previewContext,
          _diffBest50Data,
          _diffSongs,
          _maimaiMusicData,
          currentMode: _currentMode,
          thunderMode: previewQuality.thunderMode,
          thunderVertical: previewQuality.thunderVertical,
        ),
      );
      if (quality == null) return;

      // 显示加载指示器
      showAppProgressDialog(context, title: '导出中', message: '正在生成图片...');

      // 调用导出方法
      final file = await DiffBest50ConvertToImg.convertToImage(
        context,
        _diffBest50Data,
        _diffSongs,
        _maimaiMusicData,
        currentMode: _currentMode,
        jpegQuality: quality.jpegQuality,
        thunderMode: quality.thunderMode,
        thunderVertical: quality.thunderVertical,
      );

      // 关闭加载指示器
      Navigator.pop(context);

      // 显示导出结果
      if (file != null) {
        showExportSuccessDialog(context, filePath: file.path, fileName: file.path.split('/').last);
      } else {
        showAppNoticeDialog(context, title: '导出失败', message: '图片导出失败，请重试', tone: AppDialogTone.error);
      }
    } catch (e) {
      // 关闭加载指示器
      Navigator.pop(context);

      // 显示错误信息
      showAppNoticeDialog(context, title: '导出失败', message: '导出过程中出现错误：\n$e', tone: AppDialogTone.error);
    }
  }
}
