import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/service/CustomTagStore.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/widgets/AppSwitch.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import '../../service/Best50/PersonalizedBest50Service.dart';
import '../../service/PersonalizedScoreService.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../SongInfoPage.dart';
import '../../constant/VersionListConstant.dart';
import '../../service/Best50/PersonalizedBest50ConvertToImgService.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/manager/MaiTagsManager.dart';
import 'package:my_first_flutter_app/entity/DXRating/MaiTagsModel.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/Best50Ui.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';
import '../../utils/MusicDataIndex.dart';

class PersonalizedBest50Page extends StatefulWidget {
  const PersonalizedBest50Page({super.key});

  @override
  _PersonalizedBest50PageState createState() => _PersonalizedBest50PageState();
}

class _PersonalizedBest50PageState extends State<PersonalizedBest50Page> {
  List<Map<String, dynamic>> _personalizedSongs = [];
  List<Map<String, dynamic>> _remainingSongs = [];
  String? _remainingLabel;
  bool _isLoading = true; // 只表示首次进入，之后切换时旧内容留在屏幕上
  bool _fetchQueued = false;
  Future<void>? _activeFetch;
  int _resultVersion = 0; // 每换一批结果加一，新结果重新入场
  String _resultType = 'ap_plus_50'; // 屏幕上这批结果所属的类型
  String _selectedType = 'ap_plus_50'; // 默认选择AP+50
  String? _selectedCharter; // 选中的charter
  Map<String, int>? _charterCounts; // charter出现次数
  String? _selectedVersion; // 选中的版本
  Map<String, int>? _versionCounts; // 版本出现次数
  String? _selectedGenre; // 选中的流派
  Map<String, int>? _genreCounts; // 流派出现次数
  List<dynamic>? _maimaiMusicData;

  // 下拉选择的选项
  final List<Map<String, String>> _options = [
    {'value': 'ap_plus_50', 'label': 'AP+50'},
    {'value': 'ap_50', 'label': 'AP50'},
    {'value': 'fc_50', 'label': 'FC50'},
    {'value': 'fc_plus_50', 'label': 'FC+50'},
    {'value': 'fs_50', 'label': 'FS50'},
    {'value': 'fs_plus_50', 'label': 'FS+50'},
    {'value': 'fsd_50', 'label': 'FDX50'},
    {'value': 'fsdp_50', 'label': 'FDX+50'},
    {'value': 'cun_50', 'label': '寸50'},
    {'value': 'mingdao_50', 'label': '名刀50/锁血50'},
    {'value': 'cuniao_plus_50', 'label': '寸鸟加50'},
    {'value': 'suoxue_plus_50', 'label': '锁血鸟加50'},
    {'value': 'cuniao_50', 'label': '寸鸟50'},
    {'value': 'suoxue_50', 'label': '锁血鸟50'},
    {'value': 'charter_50', 'label': '谱师50'},
    {'value': 'genre_50', 'label': '流派50'},
    {'value': 'version_50', 'label': '版本50'},
    {'value': 'dx_50', 'label': 'DX50'},
    {'value': 'st_50', 'label': 'ST50'},
    {'value': 'star_50', 'label': '星数50'},
    {'value': 'tag_50', 'label': '标签50'},
    {'value': 'random_50', 'label': '随机50'},
    {'value': 'beyond_50', 'label': '越级50'},
    {'value': 'difficulty_50', 'label': '难度50'},
    {'value': 'level_50', 'label': '等级50'},
    {'value': 'best_n', 'label': 'Best N'},
    {'value': 'all_50', 'label': 'ALL50'},
    // 游玩次数最高的 50 张谱面；次数来自「同步成绩」的线路1（AWMC 网关）——
    // 详见 PersonalizedBest50Service.getPC50Data
    {'value': 'pc_50', 'label': 'PC50'},
  ];

  // 星数选项
  final List<Map<String, dynamic>> _starOptions = [
    {'value': 6, 'label': '\u27266', 'rate': 0.99},
    {'value': 5.5, 'label': '\u27265.5', 'rate': 0.98},
    {'value': 5, 'label': '\u27265', 'rate': 0.97},
    {'value': 4, 'label': '\u27264', 'rate': 0.95},
    {'value': 3, 'label': '\u27263', 'rate': 0.93},
    {'value': 2, 'label': '\u27262', 'rate': 0.90},
    {'value': 1, 'label': '\u27261', 'rate': 0.85},
    {'value': 0, 'label': '\u27260', 'rate': 0.0},
  ];

  String? _selectedStar; // 选中的星数
  int? _selectedTagId; // 选中的标签ID
  String? _selectedTagName; // 选中的标签名称
  int?
      _selectedDifficultyLevel; // 难度50 选中的难度（0=BASIC ... 4=Re:MASTER，UTAGE 走独立流程）
  String? _selectedLevel; // 等级50 选中的等级（如 "14+"）
  List<String> _levelOptions = []; // 等级选项，与个性化成绩查询共用同一份全量列表
  int _selectedN = 50; // Best N 选项选中的 N，默认 50
  late final TextEditingController _bestNController; // Best N 输入框 controller
  bool _isInclusiveMode = false; // 包容关系模式开关（仅对连击/同步50有效）

  @override
  void initState() {
    super.initState();
    _bestNController = TextEditingController(text: _selectedN.toString());
    _loadPersonalizedData();
  }

  @override
  void dispose() {
    _bestNController.dispose();
    super.dispose();
  }

  Future<void> _loadPersonalizedData() async {
    try {
      // 加载maimai音乐数据
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
          });
        }
      } else {
        // 如果API数据不存在，尝试从资产文件加载JSON数据作为 fallback
        final maimaiContents =
            await rootBundle.loadString('assets/maimai_music_data.json');
        final maimaiJsonData = json.decode(maimaiContents);

        setState(() {
          _maimaiMusicData = maimaiJsonData as List<dynamic>;
        });
      }

      // 加载charter出现次数、版本出现次数和流派出现次数
      final service = PersonalizedBest50Service();
      _charterCounts = await service.getCharterCounts();
      _versionCounts = await service.getVersionCounts();
      _genreCounts = await service.getGenreCounts();
      _levelOptions = await PersonalizedScoreService().getAllLevelOptions();

      // 加载个性化数据
      await _fetchPersonalizedData();
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 判断当前选中类型是否为连击类型（FC/FC+/AP/AP+）
  bool _isComboType() {
    return _getComboValue() != null;
  }

  // 获取当前选中类型对应的fc字段值
  String? _getComboValue() {
    switch (_selectedType) {
      case 'fc_50':
        return 'fc';
      case 'fc_plus_50':
        return 'fcp';
      case 'ap_50':
        return 'ap';
      case 'ap_plus_50':
        return 'app';
      default:
        return null;
    }
  }

  // 判断当前选中类型是否为同步类型（FS/FS+/FDX/FDX+）
  bool _isSyncType() {
    return _getSyncValue() != null;
  }

  // 获取当前选中类型对应的fs字段值
  String? _getSyncValue() {
    switch (_selectedType) {
      case 'fs_50':
        return 'fs';
      case 'fs_plus_50':
        return 'fsp';
      case 'fsd_50':
        return 'fsd';
      case 'fsdp_50':
        return 'fsdp';
      default:
        return null;
    }
  }

  // 判断当前选中类型是否支持包容关系模式（连击或同步类型）
  bool _supportsInclusiveMode() {
    return _isComboType() || _isSyncType();
  }

  // 难度 level → 人类可读标签
  String _difficultyLabel(int level) {
    const labels = ChartDifficulty.labels;
    return (level >= 0 && level < labels.length) ? labels[level] : context.l10n.flowUnknown;
  }

  // 包容关系模式下显示的标签
  String _getInclusiveModeLabel() {
    if (_isComboType()) {
      const labels = {'fc': 'FC', 'fcp': 'FC+', 'ap': 'AP', 'app': 'AP+'};
      const hierarchy = ['fc', 'fcp', 'ap', 'app'];
      final base = _getComboValue()!;
      final startIndex = hierarchy.indexOf(base);
      final included =
          hierarchy.sublist(startIndex).map((v) => labels[v]!).join('/');
      return context.l10n.flowIncludesP0((included).toString());
    } else if (_isSyncType()) {
      const labels = {'fs': 'FS', 'fsp': 'FS+', 'fsd': 'FDX', 'fsdp': 'FDX+'};
      const hierarchy = ['fs', 'fsp', 'fsd', 'fsdp'];
      final base = _getSyncValue()!;
      final startIndex = hierarchy.indexOf(base);
      final included =
          hierarchy.sublist(startIndex).map((v) => labels[v]!).join('/');
      return context.l10n.flowIncludesP0((included).toString());
    }
    return '';
  }

  // 切换时页面不再被转圈挡住，上一次还没算完就可能又换了选项。
  // 服务是单例，lastRemaining 被同时进行的请求共用，所以串行执行，只采用最后一次的结果。
  Future<void> _fetchPersonalizedData() {
    _fetchQueued = true;
    return _activeFetch ??=
        _drainFetches().whenComplete(() => _activeFetch = null);
  }

  Future<void> _drainFetches() async {
    while (_fetchQueued && mounted) {
      _fetchQueued = false;
      await _fetchOnce();
    }
  }

  void _applyResult(
    String type,
    List<Map<String, dynamic>> songs,
    List<Map<String, dynamic>> remaining,
    String? remainingLabel,
  ) {
    if (!mounted || _fetchQueued) return; // 选项已经又变了，这批结果作废
    setState(() {
      _personalizedSongs = songs;
      _remainingSongs = remaining;
      _remainingLabel = remainingLabel;
      _resultType = type;
      _resultVersion++;
      _isLoading = false;
    });
  }

  Future<void> _fetchOnce() async {
    final requestType = _selectedType;
    try {
      final service = PersonalizedBest50Service();
      service.lastRemaining = const [];
      service.lastRemainingLabel = null;
      Map<String, dynamic>? data;

      // 根据选择的类型获取数据
      switch (_selectedType) {
        case 'ap_plus_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveCombo50Data('app');
          } else {
            data = await service.getAPPlus50Data();
          }
          break;
        case 'ap_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveCombo50Data('ap');
          } else {
            data = await service.getAP50Data();
          }
          break;
        case 'fc_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveCombo50Data('fc');
          } else {
            data = await service.getFC50Data();
          }
          break;
        case 'fc_plus_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveCombo50Data('fcp');
          } else {
            data = await service.getFCPlus50Data();
          }
          break;
        case 'cun_50':
          data = await service.getCun50Data();
          break;
        case 'mingdao_50':
          data = await service.getMingDao50Data();
          break;
        case 'charter_50':
          if (_selectedCharter != null) {
            data = await service.getCharter50Data(_selectedCharter!);
          }
          break;
        case 'version_50':
          if (_selectedVersion != null) {
            data = await service.getVersion50Data(_selectedVersion!);
          }
          break;
        case 'dx_50':
          data = await service.getDX50Data();
          break;
        case 'st_50':
          data = await service.getST50Data();
          break;
        case 'fs_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveSync50Data('fs');
          } else {
            data = await service.getFS50Data();
          }
          break;
        case 'fs_plus_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveSync50Data('fsp');
          } else {
            data = await service.getFSPlus50Data();
          }
          break;
        case 'fsd_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveSync50Data('fsd');
          } else {
            data = await service.getFDX50Data();
          }
          break;
        case 'fsdp_50':
          if (_isInclusiveMode) {
            data = await service.getInclusiveSync50Data('fsdp');
          } else {
            data = await service.getFDXPlus50Data();
          }
          break;
        case 'cuniao_plus_50':
          data = await service.getCuniaoPlus50Data();
          break;
        case 'suoxue_plus_50':
          data = await service.getSuoxuePlus50Data();
          break;
        case 'cuniao_50':
          data = await service.getCuniao50Data();
          break;
        case 'suoxue_50':
          data = await service.getSuoxue50Data();
          break;
        case 'genre_50':
          if (_selectedGenre != null) {
            data = await service.getGenre50Data(_selectedGenre!);
          }
          break;
        case 'star_50':
          if (_selectedStar != null) {
            data = await service.getStar50Data(_selectedStar!);
          }
          break;
        case 'tag_50':
          if (_selectedTagId != null) {
            data = await service.getTag50Data(_selectedTagId!);
          }
          break;
        case 'random_50':
          data = await service.getRandom50Data();
          break;
        case 'beyond_50':
          data = await service.getBeyond50Data();
          break;
        case 'difficulty_50':
          if (_selectedDifficultyLevel == 5) {
            // UTAGE：按 ds 降序取前 50
            data = await service.getUtage50Data();
          } else if (_selectedDifficultyLevel != null) {
            data = await service.getDifficulty50Data(_selectedDifficultyLevel!);
          }
          break;
        case 'level_50':
          if (_selectedLevel != null) {
            data = await service.getLevel50Data(_selectedLevel!);
          }
          break;
        case 'best_n':
          data = await service.getBestNData(_selectedN);
          break;
        case 'all_50':
          data = await service.getAll50Data();
          break;
        case 'pc_50':
          data = await service.getPC50Data();
          break;
      }

      if (data != null) {
        // 为记录添加歌曲信息
        final enrichedRecords = await service.enrichRecordsWithSongInfo(
            (data['records'] is List ? data['records'] : []) as List<dynamic>);
        final remainingLabel = service.lastRemainingLabel;
        final enrichedRemaining =
            await service.enrichRecordsWithSongInfo(service.lastRemaining);

        _applyResult(
            requestType, enrichedRecords, enrichedRemaining, remainingLabel);
      } else {
        _applyResult(requestType, [], [], null);
      }
    } catch (e) {
      debugPrint('Error fetching personalized data: $e');
      _applyResult(requestType, [], [], null);
    }
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
      // 等切换中的结果到位，避免按新标题导出旧列表。
      await _activeFetch;
      if (!mounted) return;
      if (_personalizedSongs.isEmpty) {
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
        estimatedPngSize: ImageEncodeUtil.estimatePngSize(
          songCount:
              _personalizedSongs.isNotEmpty ? _personalizedSongs.length : 50,
        ),
        exportingLabel: context.l10n.featureCustomBest50Analysis,
        enableThunderMode: true,
        previewBuilder: (previewContext, previewQuality) =>
            PersonalizedB50ConvertToImg.buildPreviewWidget(
          previewContext,
          _selectedType == 'level_50' && _selectedLevel != null
              ? context.l10n.flowLevel50P0('Lv.$_selectedLevel')
              : _selectedType == 'charter_50' && _selectedCharter != null
              ? context.l10n
                  .flowChartDesigner50P0((_selectedCharter!).toString())
              : _selectedType == 'version_50' && _selectedVersion != null
                  ? context.l10n.flowVersion50P0(
                      (StringUtil.formatVersion2(_selectedVersion!)).toString())
                  : _selectedType == 'genre_50' && _selectedGenre != null
                      ? context.l10n.flowGenre50P0((_selectedGenre!).toString())
                      : _selectedType == 'star_50' && _selectedStar != null
                          ? context.l10n
                              .flowStar50P0((_selectedStar!).toString())
                          : _selectedType == 'tag_50' &&
                                  _selectedTagName != null
                              ? context.l10n
                                  .flowTag50P0((_selectedTagName!).toString())
                              : context.l10n.flowPersonalizedBest50P0(context
                                  .featureText(_options.firstWhere((option) =>
                                      option['value'] ==
                                      _selectedType)['label']!)),
          _personalizedSongs,
          _maimaiMusicData,
          null,
          null,
          thunderMode: previewQuality.thunderMode,
          thunderVertical: previewQuality.thunderVertical,
          theme: previewQuality.theme,
        ),
      );
      if (quality == null) {
        return; // 用户取消
      }

      String title = _selectedType == 'level_50' && _selectedLevel != null
          ? context.l10n.flowLevel50P0('Lv.$_selectedLevel')
          : _selectedType == 'charter_50' && _selectedCharter != null
          ? context.l10n.flowChartDesigner50P0((_selectedCharter!).toString())
          : _selectedType == 'version_50' && _selectedVersion != null
              ? context.l10n.flowVersion50P0(
                  (StringUtil.formatVersion2(_selectedVersion!)).toString())
              : _selectedType == 'genre_50' && _selectedGenre != null
                  ? context.l10n.flowGenre50P0((_selectedGenre!).toString())
                  : _selectedType == 'star_50' && _selectedStar != null
                      ? context.l10n.flowStar50P0((_selectedStar!).toString())
                      : _selectedType == 'tag_50' && _selectedTagName != null
                          ? context.l10n
                              .flowTag50P0((_selectedTagName!).toString())
                          : context.l10n.flowPersonalizedBest50P0(context
                              .featureText(_options.firstWhere((option) =>
                                  option['value'] == _selectedType)['label']!));

      BackgroundExport.run(
        label: context.l10n.featureCustomBest50Analysis,
        task: (exportContext) => PersonalizedB50ConvertToImg.convertToImage(
          exportContext,
          title,
          _personalizedSongs,
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
    if (_isLoading) {
      return BackgroundPageScaffold(
        title: context.l10n.featureCustomBest50Analysis,
        resizeToAvoidBottomInset: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return BackgroundPageScaffold(
      title: context.l10n.featureCustomBest50Analysis,
      resizeToAvoidBottomInset: false,
      actionsEndInset: 4,
      actions: [
        Best50IconAction(
          tooltip: context.l10n.flowExportAsImage,
          icon: Icons.image_outlined,
          onPressed: () async {
            try {
              await _exportToImage();
            } catch (e) {
              debugPrint('Error in personalized export: $e');
            }
          },
        ),
      ],
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
            AppDesignTokens.gutter, AppDesignTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 选择按钮
            Best50ActionButton(
              icon: Icons.tune_rounded,
              onPressed: _showTypeSelectionDialog,
              label: (_selectedType == 'level_50' && _selectedLevel != null
                  ? context.l10n.flowCategoryLevel50P0('Lv.$_selectedLevel')
                  : _selectedType == 'charter_50' && _selectedCharter != null
                  ? context.l10n.flowCategoryChartDesigner50P0(
                      (_selectedCharter!).toString())
                  : _selectedType == 'version_50' && _selectedVersion != null
                      ? context.l10n.flowCategoryVersion50P0(
                          (StringUtil.formatVersion2(_selectedVersion!))
                              .toString())
                      : _selectedType == 'genre_50' && _selectedGenre != null
                          ? context.l10n.flowCategoryGenre50P0(
                              (_selectedGenre!).toString())
                          : _selectedType == 'star_50' && _selectedStar != null
                              ? context.l10n.flowCategoryStar50P0(
                                  (_selectedStar!).toString())
                              : _selectedType == 'tag_50' &&
                                      _selectedTagName != null
                                  ? context.l10n.flowCategoryTag50P0(
                                      (_selectedTagName!).toString())
                                  : _selectedType == 'random_50'
                                      ? context.l10n.flowCategoryRandom50
                                      : _selectedType == 'beyond_50'
                                          ? context.l10n.flowCategoryOverreach50
                                          : _selectedType == 'difficulty_50' &&
                                                  _selectedDifficultyLevel !=
                                                      null
                                              ? context.l10n.flowCategoryDifficulty50P0(
                                                  (_difficultyLabel(_selectedDifficultyLevel!))
                                                      .toString())
                                              : _selectedType == 'best_n'
                                                  ? context.l10n.flowCategoryBestP0(
                                                      (_selectedN).toString())
                                                  : context.l10n.flowCategoryP0(
                                                      context.featureText(
                                                          _options.firstWhere((option) => option['value'] == _selectedType)['label']!))),
            ),
            SizedBox(height: 12.0),

            // 包容关系模式开关（仅对连击/同步50类型显示）
            if (_supportsInclusiveMode()) _buildInclusiveModeToggle(),
            if (_supportsInclusiveMode()) SizedBox(height: 12.0),

            // 数据统计区域
            _buildStatsSection(),
            SizedBox(height: 12.0),

            // 随机50 专属：再抽一次按钮
            if (_selectedType == 'random_50') _buildRerollButton(),
            if (_selectedType == 'random_50') SizedBox(height: 12.0),

            // Best N 专属：输入框 + 生成按钮
            if (_selectedType == 'best_n') _buildBestNInputRow(),
            if (_selectedType == 'best_n') SizedBox(height: 12.0),

            // 歌曲列表
            _buildSongList(),
          ],
        ),
      ),
    );
  }

  // 显示类型选择对话框
  void _showTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowChooseCategory),
          content: SingleChildScrollView(
            child: ListBody(
              children: _options.map((option) {
                return ListTile(
                  title: Text(context.featureText(option['label']!)),
                  selected: _selectedType == option['value'],
                  onTap: () {
                    if (option['value'] == 'charter_50') {
                      // 显示charter选择对话框
                      Navigator.of(context).pop();
                      _showCharterSelectionDialog();
                    } else if (option['value'] == 'version_50') {
                      // 显示版本选择对话框
                      Navigator.of(context).pop();
                      _showVersionSelectionDialog();
                    } else if (option['value'] == 'genre_50') {
                      // 显示流派选择对话框
                      Navigator.of(context).pop();
                      _showGenreSelectionDialog();
                    } else if (option['value'] == 'star_50') {
                      // 显示星数选择对话框
                      Navigator.of(context).pop();
                      _showStarSelectionDialog();
                    } else if (option['value'] == 'tag_50') {
                      // 显示标签选择对话框
                      Navigator.of(context).pop();
                      _showTagSelectionDialog();
                    } else if (option['value'] == 'difficulty_50') {
                      // 显示难度选择对话框
                      Navigator.of(context).pop();
                      _showDifficultySelectionDialog();
                    } else if (option['value'] == 'level_50') {
                      // 显示等级选择对话框
                      Navigator.of(context).pop();
                      _showLevelSelectionDialog();
                    } else if (_selectedType == option['value']) {
                      Navigator.of(context).pop();
                    } else {
                      setState(() {
                        _selectedType = option['value']!;
                        _isInclusiveMode = false; // 切换类型时重置包容关系模式
                        _selectedCharter = null;
                        _selectedVersion = null;
                        _selectedGenre = null;
                        _selectedStar = null;
                        _selectedTagId = null;
                        _selectedTagName = null;
                        _selectedDifficultyLevel = null;
                        _selectedLevel = null;
                        // Best N：切回时把 controller 文本同步成当前的 N
                        if (option['value'] == 'best_n') {
                          _bestNController.text = _selectedN.toString();
                        }
                      });
                      Navigator.of(context).pop();
                      _fetchPersonalizedData();
                    }
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.featureCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 显示等级选择对话框：与个性化成绩查询的等级对话框同样的 5 列网格
  void _showLevelSelectionDialog() {
    if (_levelOptions.isEmpty) {
      showAppNoticeDialog(context,
          title: context.l10n.featureNotice,
          message: context.l10n.flowNoData);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Center(child: Text(context.l10n.flowSelectLevel)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          content: SizedBox(
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
              itemCount: _levelOptions.length,
              itemBuilder: (context, index) {
                final level = _levelOptions[index];
                final selected =
                    _selectedType == 'level_50' && _selectedLevel == level;
                return Container(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selected
                          ? Theme.of(context).colorScheme.primary
                          : AppSurfaces.inset(context),
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(4),
                      minimumSize: Size(50, 40),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      // 再次点当前选中的等级不重新加载
                      if (selected) return;
                      setState(() {
                        _selectedType = 'level_50';
                        _selectedLevel = level;
                        _isInclusiveMode = false;
                      });
                      _fetchPersonalizedData();
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Lv.$level',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selected
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

  // 显示版本选择对话框
  void _showVersionSelectionDialog() {
    if (_versionCounts == null || _versionCounts!.isEmpty) {
      // 没有版本数据
      showAppNoticeDialog(context,
          title: context.l10n.featureNotice,
          message: context.l10n.flowNoVersionDataFound);
      return;
    }

    // 按版本顺序排序
    List<MapEntry<String, int>> sortedVersions =
        _versionCounts!.entries.toList()
          ..sort((a, b) {
            int indexA = VersionListConstant.versionOrderList.indexOf(a.key);
            int indexB = VersionListConstant.versionOrderList.indexOf(b.key);
            if (indexA != -1 && indexB != -1) {
              return indexA.compareTo(indexB);
            } else if (indexA != -1) {
              return -1;
            } else if (indexB != -1) {
              return 1;
            } else {
              // 如果都不在顺序列表中，按字符串排序
              return a.key.compareTo(b.key);
            }
          });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowSelectVersion),
          content: SingleChildScrollView(
            child: ListBody(
              children: sortedVersions.map((entry) {
                return ListTile(
                  title: Text(context.l10n.flowP0P1Songs2(
                      (StringUtil.formatVersion2(entry.key)).toString(),
                      (entry.value).toString())),
                  selected: _selectedVersion == entry.key,
                  onTap: () {
                    if (_selectedType == 'version_50' &&
                        _selectedVersion == entry.key) {
                      Navigator.of(context).pop();
                      return;
                    }
                    setState(() {
                      _selectedType = 'version_50';
                      _selectedVersion = entry.key;
                    });
                    Navigator.of(context).pop();
                    _fetchPersonalizedData();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.featureCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 显示流派选择对话框
  void _showGenreSelectionDialog() {
    if (_genreCounts == null || _genreCounts!.isEmpty) {
      // 没有流派数据
      showAppNoticeDialog(context,
          title: context.l10n.featureNotice,
          message: context.l10n.flowNoGenreDataFound);
      return;
    }

    // 按出现次数排序
    List<MapEntry<String, int>> sortedGenres = _genreCounts!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowSelectGenre),
          content: SingleChildScrollView(
            child: ListBody(
              children: sortedGenres.map((entry) {
                return ListTile(
                  title: Text(context.l10n.flowP0P1Songs2(
                      (entry.key).toString(), (entry.value).toString())),
                  selected: _selectedGenre == entry.key,
                  onTap: () {
                    if (_selectedType == 'genre_50' &&
                        _selectedGenre == entry.key) {
                      Navigator.of(context).pop();
                      return;
                    }
                    setState(() {
                      _selectedType = 'genre_50';
                      _selectedGenre = entry.key;
                    });
                    Navigator.of(context).pop();
                    _fetchPersonalizedData();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.featureCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 显示星数选择对话框
  void _showStarSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowSelectStars),
          content: SingleChildScrollView(
            child: ListBody(
              children: _starOptions.map((option) {
                return ListTile(
                  title: Text(context.featureText(option['label']!)),
                  selected: _selectedStar == option['label'],
                  onTap: () {
                    if (_selectedType == 'star_50' &&
                        _selectedStar == option['label']) {
                      Navigator.of(context).pop();
                      return;
                    }
                    setState(() {
                      _selectedType = 'star_50';
                      _selectedStar = option['label'];
                    });
                    Navigator.of(context).pop();
                    _fetchPersonalizedData();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.featureCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Best N 输入行 + 生成按钮（仅在 _selectedType == 'best_n' 时显示）
  Widget _buildBestNInputRow() {
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Text('N =', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _bestNController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: AppSurfaces.inset(context),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDesignTokens.radiusSmall),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Best50ActionButton(
              icon: Icons.search_rounded,
              label: context.l10n.flowGenerateBestN,
              primary: true,
              onPressed: _triggerBestN,
            ),
          ),
        ],
      ),
    );
  }

  /// Best N 生成按钮：读 controller，校验后写回 _selectedN 并拉数据
  void _triggerBestN() {
    final v = int.tryParse(_bestNController.text.trim());
    if (v == null || v < 1) {
      AppToast.show(context.l10n.flowEnterAnIntegerOf1OrMore,
          tone: AppToastTone.warning);
      return;
    }
    setState(() {
      _selectedN = v.clamp(1, 500);
      _bestNController.text = _selectedN.toString();
    });
    _fetchPersonalizedData();
  }

  // 显示难度选择对话框（难度50）
  void _showDifficultySelectionDialog() {
    const options = [
      _DifficultyOption(ChartDifficulty.basicLabel, ChartDifficulty.basic),
      _DifficultyOption(
          ChartDifficulty.advancedLabel, ChartDifficulty.advanced),
      _DifficultyOption(ChartDifficulty.expertLabel, ChartDifficulty.expert),
      _DifficultyOption(ChartDifficulty.masterLabel, ChartDifficulty.master),
      _DifficultyOption(
          ChartDifficulty.reMasterLabel, ChartDifficulty.reMaster),
      _DifficultyOption(ChartDifficulty.utageLabel,
          ChartDifficulty.utage), // UTAGE 走 ds 排序的独立服务
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowSelectDifficulty),
          content: SingleChildScrollView(
            child: ListBody(
              children: options.map((opt) {
                return ListTile(
                  title: Text(opt.label),
                  onTap: () {
                    Navigator.of(context).pop();
                    if (_selectedType == 'difficulty_50' &&
                        _selectedDifficultyLevel == opt.level) {
                      return;
                    }
                    setState(() {
                      _selectedType = 'difficulty_50';
                      _selectedDifficultyLevel = opt.level;
                    });
                    _fetchPersonalizedData();
                  },
                );
              }).toList(),
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

  // 显示标签选择对话框
  void _showTagSelectionDialog() async {
    // 加载标签数据
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
                            if (_selectedType == 'tag_50' &&
                                _selectedTagId == tag.id) {
                              Navigator.of(context).pop();
                              return;
                            }
                            setState(() {
                              _selectedType = 'tag_50';
                              _selectedTagId = tag.id;
                              // 自定义标签可能与 DXRating 标签同名，显示时加标记区分。
                              _selectedTagName = CustomTagStore.instance
                                      .isCustomTagId(tag.id)
                                  ? context.l10n.customTagMarked(
                                      tag.localizedName.zhHans)
                                  : tag.localizedName.zhHans;
                            });
                            Navigator.of(context).pop();
                            _fetchPersonalizedData();
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

  // 显示charter选择对话框
  void _showCharterSelectionDialog() {
    if (_charterCounts == null || _charterCounts!.isEmpty) {
      // 没有charter数据
      showAppNoticeDialog(context,
          title: context.l10n.featureNotice,
          message: context.l10n.flowNoMatchingChartDesigners);
      return;
    }

    // 按出现次数排序
    List<MapEntry<String, int>> sortedCharters = _charterCounts!.entries
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(context.l10n.flowSelectCharter),
          content: SingleChildScrollView(
            child: ListBody(
              children: sortedCharters.map((entry) {
                return ListTile(
                  title: Text(context.l10n.flowP0P1Charts(
                      (entry.key).toString(), (entry.value).toString())),
                  selected: _selectedCharter == entry.key,
                  onTap: () {
                    if (_selectedType == 'charter_50' &&
                        _selectedCharter == entry.key) {
                      Navigator.of(context).pop();
                      return;
                    }
                    setState(() {
                      _selectedType = 'charter_50';
                      _selectedCharter = entry.key;
                    });
                    Navigator.of(context).pop();
                    _fetchPersonalizedData();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              child: Text(context.l10n.featureCancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 构建统计区域
  Widget _buildStatsSection() {
    // 计算各项指标
    int totalSongs = _personalizedSongs.length;
    int totalRa = _personalizedSongs.fold(
        0, (sum, song) => sum + ((song['ra'] ?? 0) as int));
    double averageRa = totalSongs > 0 ? totalRa / totalSongs : 0.0;

    double totalAchievement = _personalizedSongs.fold(0.0, (sum, song) {
      return sum + (double.tryParse(song['achievements'].toString()) ?? 0.0);
    });
    double averageAchievement =
        totalSongs > 0 ? totalAchievement / totalSongs : 0.0;

    final title = _selectedType == 'level_50' && _selectedLevel != null
        ? context.l10n.flowP0Statistics(
            context.l10n.flowLevel50P0('Lv.$_selectedLevel'))
        : _selectedType == 'charter_50' && _selectedCharter != null
        ? context.l10n
            .flowChartDesigner50P0Statistics((_selectedCharter!).toString())
        : _selectedType == 'version_50' && _selectedVersion != null
            ? context.l10n.flowVersion50P0Statistics(
                (StringUtil.formatVersion2(_selectedVersion!)).toString())
            : _selectedType == 'genre_50' && _selectedGenre != null
                ? context.l10n
                    .flowGenre50P0Statistics((_selectedGenre!).toString())
                : _selectedType == 'star_50' && _selectedStar != null
                    ? context.l10n
                        .flowStar50P0Statistics((_selectedStar!).toString())
                    : _selectedType == 'tag_50' && _selectedTagName != null
                        ? context.l10n.flowTag50P0Statistics(
                            (_selectedTagName!).toString())
                        : context.l10n.flowP0Statistics(context.featureText(
                            _options.firstWhere((option) =>
                                option['value'] == _selectedType)['label']!));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Best50Hero(total: totalRa, label: title),
        const SizedBox(height: AppDesignTokens.cardGap),
        AppCard(
          child: Row(
            children: [
              Expanded(
                  child: StatTile(
                      label: context.l10n.flowTotalCharts,
                      value: '$totalSongs')),
              Expanded(
                  child: StatTile(
                      label: context.l10n.flowAverageRA,
                      value: averageRa.toStringAsFixed(1))),
              Expanded(
                  child: StatTile(
                      label: context.l10n.featureAverageAchievement,
                      value: '${averageAchievement.toStringAsFixed(2)}%')),
            ],
          ),
        ),
      ],
    );
  }

  // 构建包容关系模式开关
  Widget _buildInclusiveModeToggle() {
    final brightness = Theme.of(context).brightness;
    return AppCard(
      radius: AppDesignTokens.radiusMedium,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.flowInclusionMode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.0),
                Text(
                  _getInclusiveModeLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.linkBlue(brightness),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AppSwitch(
            value: _isInclusiveMode,
            onChanged: (value) {
              setState(() {
                _isInclusiveMode = value;
              });
              _fetchPersonalizedData();
            },
          ),
        ],
      ),
    );
  }

  // 「再抽一次」按钮（仅随机50 显示）
  Widget _buildRerollButton() {
    return Best50ActionButton(
      icon: Icons.casino_outlined,
      label: context.l10n.flowDrawAgain,
      onPressed: _fetchPersonalizedData,
    );
  }

  // 构建导出按钮

  // 构建歌曲列表
  Widget _buildSongList() {
    if (_personalizedSongs.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16),
            Text(
              _selectedType == 'level_50' && _selectedLevel != null
                  ? context.l10n.flowNoP0DataYet(
                      context.l10n.flowLevel50P0('Lv.$_selectedLevel'))
                  : _selectedType == 'charter_50' && _selectedCharter != null
                  ? context.l10n.flowNoChartDesigner50DataForP0(
                      (_selectedCharter!).toString())
                  : _selectedType == 'version_50' && _selectedVersion != null
                      ? context.l10n.flowNoVersion50DataForP0(
                          (StringUtil.formatVersion2(_selectedVersion!))
                              .toString())
                      : _selectedType == 'genre_50' && _selectedGenre != null
                          ? context.l10n.flowNoGenre50DataForP0(
                              (_selectedGenre!).toString())
                          : _selectedType == 'star_50' && _selectedStar != null
                              ? context.l10n.flowNoStar50DataForP0(
                                  (_selectedStar!).toString())
                              : context.l10n.flowNoP0DataYet(context
                                  .featureText(_options.firstWhere((option) =>
                                      option['value'] ==
                                      _selectedType)['label']!)),
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              // PC50 的次数由「我的」页的独立功能读取，缺数据时给出明确入口。
              _selectedType == 'pc_50'
                  ? context.l10n.flowRefreshArcadePlayCountsFromMeBefore
                  : context.l10n.flowReturnHomeAndTapRefreshData,
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

    return Best50Grid(
      items: [for (final s in _personalizedSongs) _cardData(s)],
      remaining: [for (final s in _remainingSongs) _cardData(s)],
      remainingLabel: _remainingLabel,
      contentKey: _resultVersion,
    );
  }

  // 根据数据构建游戏卡片
  Best50CardData _cardData(Map<String, dynamic> songData) {
    final int score = songData['dxScore'] ?? 0;
    final int levelIndex = songData['level_index'] ?? 0;
    final int songId = songData['song_id'] ?? 0;
    // 沿用 _calculateScoreRate 的查表逻辑算满分。
    final songIndex = _maimaiMusicData == null
        ? -1
        : MusicDataIndex.indexOf(_maimaiMusicData!, songId);
    final dynamic matchedSong =
        songIndex >= 0 ? _maimaiMusicData![songIndex] : null;
    // PC50：卡片上挂一枚游玩次数角标 —— 这个模式的排序依据就是它，
    // 不显示的话列表看起来和 ALL50 只差一个顺序。
    final int? playCount = (songData['playCount'] as num?)?.toInt();
    return Best50CardData(
      songId: songId,
      title: songData['title'] ?? context.l10n.flowUnknownSong,
      levelIndex: levelIndex,
      type: songData['type'] ?? '',
      rating: songData['ra'] ?? 0,
      ds: songData['ds'] is double
          ? songData['ds']
          : (double.tryParse(songData['ds'].toString()) ?? 0.0),
      achievement: double.tryParse(songData['achievements'].toString()) ?? 0.0,
      fc: songData['fc'] ?? '',
      fs: songData['fs'] ?? '',
      stars: StringUtil.formatStars(
          _calculateScoreRate(songId, levelIndex, score)),
      dxScore: score,
      // 只显示当前难度的满分（notes * 3），不用 DX 双难度总和
      maxDxScore:
          matchedSong == null ? 0 : _calculateMaxScore(matchedSong, levelIndex),
      badge: _resultType == 'pc_50' && playCount != null
          ? 'PC $playCount'
          : null,
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

  // 构建游戏卡片（委托至通用 widget B50GameCardWidget，
  // 字号按卡片**实际**宽度自适应（`scale: autoScale`）。

  // 计算scoreRate
  double _calculateScoreRate(int songId, int levelIndex, int score) {
    if (_maimaiMusicData == null) return 0.0;

    // 查找对应的歌曲
    int songIndex = MusicDataIndex.indexOf(_maimaiMusicData!, songId);

    if (songIndex == -1) return 0.0;
    dynamic songData = _maimaiMusicData![songIndex];

    int maxScore = _calculateMaxDxScore(songData, levelIndex);

    // 计算scoreRate
    return maxScore > 0 ? score / maxScore : 0.0;
  }

  // 计算最大DX分
  // 当ds数组长度为2时，返回两个难度谱面DX分之和
  // 否则返回当前难度的最大分数
  int _calculateMaxDxScore(dynamic songData, int levelIndex) {
    if (songData == null) return 0;

    // 检查ds数组长度
    List<dynamic> ds = songData['ds'];
    if (ds.length == 2) {
      // 计算两个难度谱面的最大分数之和
      int maxScore1 = _calculateMaxScore(songData, 0);
      int maxScore2 = _calculateMaxScore(songData, 1);
      return maxScore1 + maxScore2;
    } else {
      // 返回当前难度的最大分数
      return _calculateMaxScore(songData, levelIndex);
    }
  }

  // 计算单个难度的最大分数
  int _calculateMaxScore(dynamic songData, int levelIndex) {
    if (songData == null) return 0;

    if (songData['charts'] == null) return 0;

    // 查找对应的charts
    List<dynamic> charts = songData['charts'];
    if (levelIndex < 0 || levelIndex >= charts.length) return 0;

    dynamic chart = charts[levelIndex];
    if (chart['notes'] == null) return 0;

    // 计算maxScore
    List<dynamic> notes = chart['notes'];
    int notesSum = notes.fold(0, (sum, note) => sum + (note as int));
    return notesSum * 3;
  }
}

/// 难度 50 对话框选项，强类型避免 map value 推断为 Object。
class _DifficultyOption {
  final String label;
  final int level;
  const _DifficultyOption(this.label, this.level);
}
