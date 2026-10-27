import '../../service/PaiziProgressService.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';
import '../../service/Collection/CollectionInfoService.dart';
import '../../entity/LuoXue/Collection.dart';
import '../../utils/LuoXueToDivingFishUtil.dart';
import '../../utils/CollectionsImageUtil.dart';
import '../../utils/CoverUtil.dart';
import '../../utils/StringUtil.dart';
import '../../utils/TranslationUtil.dart';
import '../../utils/AppTheme.dart';
import '../SongInfoPage.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../widgets/LxnsAssetImage.dart';
import '../../widgets/TrophyTitleBadge.dart';
import '../../entity/DivingFish/Song.dart';

class CollectionInfoPage extends StatefulWidget {
  final int collectionId;
  final String collectionType;

  const CollectionInfoPage({
    Key? key,
    required this.collectionId,
    required this.collectionType,
  }) : super(key: key);

  @override
  _CollectionInfoPageState createState() => _CollectionInfoPageState();
}

class _CollectionInfoPageState extends State<CollectionInfoPage> {
  final CollectionInfoService _infoService = CollectionInfoService();
  Collection? _collection;
  bool _isLoading = true;
  Map<CollectionRequiredSong, dynamic>? _songMap;
  bool _isLoadingSongs = false;
  List<Song> _excludedSongs = [];
  String? _translatedName;
  String? _translatedDescription;
  bool _isTranslatingName = false;
  bool _isTranslatingDescription = false;
  bool _isSavingImage = false;

  // 获取图片URL
  String? _getImageUrl() {
    if (_collection == null) return null;
    const String imageBaseUrl = 'https://assets2.lxns.net/maimai';
    switch (widget.collectionType) {
      case 'icons':
        return '$imageBaseUrl/icon/${_collection!.id}.png';
      case 'plates':
        return '$imageBaseUrl/plate/${_collection!.id}.png';
      case 'frames':
        return '$imageBaseUrl/frame/${_collection!.id}.png';
      default:
        return null;
    }
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

  // 保存图片到相册
  Future<void> _saveImageToGallery() async {
    String? imageUrl = _getImageUrl();
    if (imageUrl == null) {
      _showToast('该收藏品没有图片');
      return;
    }

    setState(() {
      _isSavingImage = true;
    });

    try {
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('权限不足'),
            content: Text('需要存储权限才能保存图片到相册，请在设置中开启权限'),
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

      // 保存也复用收藏品缓存，避免同一张图片再次从第三方下载。
      Uint8List imageBytes = await lxnsAssetCacheManager.readBytes(imageUrl);

      // 保存到相册
      Directory? directory;
      if (Platform.isAndroid) {
        String picturesPath = '/storage/emulated/0/Pictures';
        directory = Directory(picturesPath);
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File(
          '${directory.path}/collection_${_collection!.id}_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(imageBytes);

      // 通知系统刷新相册
      if (Platform.isAndroid) {
        await MediaScanner.loadMedia(path: file.path);
      }

      _showToast('图片已保存到相册');
    } catch (e) {
      debugPrint('保存图片失败: $e');
      _showToast('保存图片失败: $e');
    } finally {
      setState(() {
        _isSavingImage = false;
      });
    }
  }

  // 显示Toast提示
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 复制图片链接到剪贴板
  Future<void> _copyImageUrl() async {
    String? imageUrl = _getImageUrl();
    if (imageUrl == null) {
      _showToast('该收藏品没有图片链接');
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: imageUrl));
      _showToast('链接已复制到剪贴板');
    } catch (e) {
      debugPrint('复制链接失败: $e');
      _showToast('复制链接失败');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCollectionInfo();
  }

  // 加载收藏品详情
  Future<void> _loadCollectionInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final collection = await _infoService.getCollectionById(
        widget.collectionId,
        widget.collectionType,
      );

      if (!mounted) return;
      setState(() {
        _collection = collection;
      });

      // 如果有达成条件，加载相关歌曲信息
      if (collection != null &&
          collection.required != null &&
          collection.required!.isNotEmpty) {
        _loadSongInfo(collection);
      }
    } catch (e) {
      debugPrint('加载收藏品详情时出错: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  // 检测是否为英文或日文字符
  bool _isEnglishOrJapanese(String text) {
    // 检查是否包含拉丁字母或日文字符（平假名、片假名）
    final englishRegex = RegExp(r'[a-zA-Z]');
    final japaneseHiraganaKatakanaRegex =
        RegExp(r'[\u3040-\u309F\u30A0-\u30FF]');

    return englishRegex.hasMatch(text) ||
        japaneseHiraganaKatakanaRegex.hasMatch(text);
  }

  // 检测是否为英文
  bool _isEnglish(String text) {
    // 检查是否包含拉丁字母
    final englishRegex = RegExp(r'[a-zA-Z]');
    return englishRegex.hasMatch(text);
  }

  // 检测是否为日语
  bool _isJapanese(String text) {
    // 检查是否包含日文字符（平假名、片假名）
    final japaneseHiraganaKatakanaRegex =
        RegExp(r'[\u3040-\u309F\u30A0-\u30FF]');
    return japaneseHiraganaKatakanaRegex.hasMatch(text);
  }

  // 检测是否同时包含英语和日语
  bool _isEnglishAndJapanese(String text) {
    return _isEnglish(text) && _isJapanese(text);
  }

  // 翻译收藏品名称
  Future<void> _translateName() async {
    if (_collection?.name == null) return;

    setState(() {
      _isTranslatingName = true;
    });

    try {
      String? translated = await TranslateService.translate(_collection!.name,
          from: 'auto', to: 'zh');
      if (translated != null) {
        setState(() {
          _translatedName = translated;
        });
      }
    } catch (e) {
      debugPrint('翻译名称失败: $e');
    } finally {
      setState(() {
        _isTranslatingName = false;
      });
    }
  }

  // 翻译收藏品描述
  Future<void> _translateDescription() async {
    if (_collection?.description == null) return;

    setState(() {
      _isTranslatingDescription = true;
    });

    try {
      String? translated = await TranslateService.translate(
          _collection!.description!,
          from: 'auto',
          to: 'zh');
      if (translated != null) {
        setState(() {
          _translatedDescription = translated;
        });
      }
    } catch (e) {
      debugPrint('翻译描述失败: $e');
    } finally {
      setState(() {
        _isTranslatingDescription = false;
      });
    }
  }

  // 加载相关歌曲信息
  Future<void> _loadSongInfo(Collection collection) async {
    setState(() {
      _isLoadingSongs = true;
    });

    try {
      final songMap =
          await LuoXueToDivingFishUtil.getSongsFromCache(collection);
      final excluded = widget.collectionType == 'plates' &&
              PaiziProgressService().isProgressPlate(collection)
          ? await LuoXueToDivingFishUtil.getConditionExcludedSongs(collection,
              matched: songMap)
          : <Song>[];
      if (!mounted) return;
      setState(() {
        _excludedSongs = excluded;
        _songMap = songMap;
      });
    } catch (e) {
      debugPrint('加载歌曲信息时出错: $e');
    } finally {
      if (mounted)
        setState(() {
          _isLoadingSongs = false;
        });
    }
  }

  // 获取类型标签
  String _getTypeLabel() {
    switch (widget.collectionType) {
      case 'trophies':
        return '称号';
      case 'icons':
        return '头像';
      case 'plates':
        return '姓名框';
      case 'frames':
        return '背景';
      default:
        return '';
    }
  }

  // 获取歌曲类型显示
  String _getTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'dx':
        return 'DX';
      case 'standard':
        return 'ST';
      case 'sd':
        return 'ST';
      default:
        return type;
    }
  }

  // 获取定数显示（第3,4,5个定数，第5个没有显示为-）
  String _getDsDisplay(List<double>? dsList) {
    if (dsList == null || dsList.isEmpty) {
      return '- / - / -';
    }
    String ds3 = dsList.length > 2 ? dsList[2].toStringAsFixed(1) : '-';
    String ds4 = dsList.length > 3 ? dsList[3].toStringAsFixed(1) : '-';
    String ds5 = dsList.length > 4 ? dsList[4].toStringAsFixed(1) : '-';
    return '$ds3 / $ds4 / $ds5';
  }

  // 获取难度显示
  Widget _getDifficultiesDisplay(List<int> difficulties) {
    final Map<int, Map<String, dynamic>> difficultyMap = {
      for (final index in ChartDifficulty.standardIndices)
        index: {
          'label': ChartDifficulty.labelOf(index),
          'color': AppColors.difficultyForegroundByIndex(index),
          'bgColor': AppColors.difficultyBackgroundByIndex(index),
        },
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: difficulties.map((d) {
        final difficultyInfo = difficultyMap[d] ??
            {
              'label': d.toString(),
              'color': Colors.grey,
              'bgColor': Colors.grey[100]
            };
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: difficultyInfo['bgColor'],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: difficultyInfo['color'], width: 1),
          ),
          child: Text(
            difficultyInfo['label'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: difficultyInfo['color'],
            ),
          ),
        );
      }).toList(),
    );
  }

  // 获取FC显示
  Widget _getFcDisplay(String fc) {
    final Map<String, Map<String, dynamic>> fcMap = {
      'ap': {
        'label': 'AP',
        'color': AppColors.achievementForeground('AP'),
        'bgColor': AppColors.achievementBackground('AP')
      },
      'app': {
        'label': 'AP+',
        'color': AppColors.achievementForeground('AP+'),
        'bgColor': AppColors.achievementBackground('AP+')
      },
      'fc': {
        'label': 'FC',
        'color': AppColors.achievementForeground('FC'),
        'bgColor': AppColors.achievementBackground('FC')
      },
      'fcp': {
        'label': 'FC+',
        'color': AppColors.achievementForeground('FC+'),
        'bgColor': AppColors.achievementBackground('FC+')
      },
    };

    final fcInfo = fcMap[fc] ??
        {'label': fc, 'color': Colors.grey, 'bgColor': Colors.grey[100]};
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fcInfo['bgColor'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fcInfo['color'], width: 1),
      ),
      child: Text(
        fcInfo['label'],
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: fcInfo['color'],
        ),
      ),
    );
  }

  // 获取FS显示
  Widget _getFsDisplay(String fs) {
    final Map<String, Map<String, dynamic>> fsMap = {
      'fs': {
        'label': 'FS',
        'color': AppColors.achievementForeground('FS'),
        'bgColor': AppColors.achievementBackground('FS')
      },
      'fsp': {
        'label': 'FS+',
        'color': AppColors.achievementForeground('FS+'),
        'bgColor': AppColors.achievementBackground('FS+')
      },
      'fsd': {
        'label': 'FDX',
        'color': AppColors.achievementForeground('FDX'),
        'bgColor': AppColors.achievementBackground('FDX')
      },
      'fsdp': {
        'label': 'FDX+',
        'color': AppColors.achievementForeground('FDX+'),
        'bgColor': AppColors.achievementBackground('FDX+')
      },
      'sync': {
        'label': 'SYNC',
        'color': AppColors.achievementForeground('SYNC'),
        'bgColor': AppColors.achievementBackground('SYNC')
      },
    };

    final fsInfo = fsMap[fs] ??
        {'label': fs, 'color': Colors.grey, 'bgColor': Colors.grey[100]};
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: fsInfo['bgColor'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fsInfo['color'], width: 1),
      ),
      child: Text(
        fsInfo['label'],
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: fsInfo['color'],
        ),
      ),
    );
  }

  // 根据颜色类型获取背景色
  Color _getColorFromType(String colorType) {
    switch (colorType) {
      case 'Bronze':
        return Color(0xFFCD7F32); // 棕色
      case 'Silver':
        return Color(0xFFC0C0C0); // 银色
      case 'Gold':
        return Color(0xFFFFD700); // 金色
      case 'Rainbow':
        return Color(0xFF9400D3); // 炫彩（紫色作为代表）
      default:
        return Colors.white; // 其他情况使用白色
    }
  }

  // 根据背景色获取文本颜色
  Color _getTextColorForBackground(String colorType) {
    switch (colorType) {
      case 'Bronze':
      case 'Silver':
      case 'Gold':
      case 'Rainbow':
        return Colors.white; // 深色背景使用白色文本
      default:
        return Colors.grey; // 浅色背景使用灰色文本
    }
  }

  Widget _buildCollectionSongCard(
      CollectionRequiredSong requiredSong, Song? song) {
    // 获取定数列表
    List<double> dsList = [];
    if (song != null && song.ds != null && song.ds is List) {
      dsList = song.ds;
    }
    return GestureDetector(
      onTap: () {
        // 跳转到歌曲详情页面，默认选择MASTER难度
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(
              songId: song?.id.toString() ?? requiredSong.id.toString(),
              initialLevelIndex: 3, // 3 代表 MASTER 难度
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 曲绘
            Container(
              width: 40,
              height: 40,
              child: CoverUtil.buildCoverWidgetWithContext(
                context,
                song?.id.toString() ?? requiredSong.id.toString(),
                40,
              ),
            ),
            SizedBox(width: 6),
            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    requiredSong.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  // 第二行：类型|版本
                  Text(
                    '${_getTypeDisplay(requiredSong.type)} | ${song != null ? StringUtil.formatVersion2WithFlag(song.basicInfo.from, song.isExtra) : '-'}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  // 第三行：第3,4,5个定数（EXPERT/MASTER/Re:MASTER）
                  Text(
                    _getDsDisplay(dsList),
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExcludedSongSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
            context, Icons.playlist_remove_outlined, '条件外排除曲目'),
        const SizedBox(height: 8),
        Text('共 ${_excludedSongs.length} 首，不计入所需条件',
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 2,
              mainAxisExtent: 54),
          itemCount: _excludedSongs.length,
          itemBuilder: (context, index) {
            final song = _excludedSongs[index];
            return _buildCollectionSongCard(
                CollectionRequiredSong(
                    id: int.tryParse(song.id) ?? 0,
                    title: song.title,
                    type: song.type),
                song);
          },
        ),
      ],
    );
  }

  // 获取唯一的歌曲列表
  List<Widget> _getUniqueSongLists(List<CollectionRequired> requiredList) {
    final Set<String> seenSongLists = {};
    final Set<String> seenSongs = {}; // 用于统计唯一歌曲数量
    final List<Widget> uniqueSongLists = [];

    for (final requiredItem in requiredList) {
      if (requiredItem.songs != null && requiredItem.songs!.isNotEmpty) {
        // 将歌曲列表转换为唯一字符串，用于去重
        final songListKey = requiredItem.songs!
            .map((song) => '${song.id}:${song.title}:${song.type}')
            .join(',');

        if (!seenSongLists.contains(songListKey)) {
          seenSongLists.add(songListKey);

          // 统计唯一歌曲数量
          for (final song in requiredItem.songs!) {
            seenSongs.add('${song.id}:${song.title}:${song.type}');
          }

          uniqueSongLists.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 4, // 进一步减小横向间距
                    mainAxisSpacing: 4, // 进一步减小纵向间距
                    childAspectRatio: 2.0, // 与 mainAxisExtent 一起给出固定格子高度
                    mainAxisExtent: 54, // 给曲绘、上下内边距和边框留出完整空间，避免卡片底部溢出
                  ),
                  itemCount: requiredItem.songs!.length,
                  itemBuilder: (context, index) => _buildCollectionSongCard(
                      requiredItem.songs![index],
                      _songMap?[requiredItem.songs![index]]),
                ),
                SizedBox(height: 12), // 减小底部间距
              ],
            ),
          );
        }
      }
    }

    // 添加歌曲数量显示
    if (seenSongs.isNotEmpty) {
      uniqueSongLists.insert(
          0,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '总计 ${seenSongs.length} 首歌曲',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              // 距离下方歌曲卡片的小间距（原为 16，配合 GridView 的固定格子高度收紧）
              SizedBox(height: 6),
            ],
          ));
    }

    return uniqueSongLists;
  }

  // 合并所需条件
  List<Widget> _getMergedRequiredConditions(
      List<CollectionRequired> requiredList) {
    final Set<String> seenFc = {};
    final Set<String> seenFs = {};
    final Set<int> allDifficulties = {};
    final List<Widget> mergedConditions = [];

    // 收集所有难度
    for (final requiredItem in requiredList) {
      if (requiredItem.difficulties != null &&
          requiredItem.difficulties!.isNotEmpty) {
        allDifficulties.addAll(requiredItem.difficulties!);
      }
    }

    // 显示合并后的难度
    if (allDifficulties.isNotEmpty) {
      final sortedDifficulties = allDifficulties.toList()..sort();
      mergedConditions.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '所需难度:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              _getDifficultiesDisplay(sortedDifficulties),
            ],
          ),
        ),
      );
    }

    // 检查描述中是否包含 RANK 信息
    if (_collection?.description != null) {
      final description = _collection!.description!;
      final rankRegex = RegExp(r'RANK\s*(S+\+?)');
      final match = rankRegex.firstMatch(description);
      String requiredRate = '';

      // 检查是否包含 CLEAR 字样
      bool hasClear = description.toLowerCase().contains('clear');
      // 检查是否包含 RANK A 字样
      bool hasRankA = description.toLowerCase().contains('rank a');

      if (match != null) {
        final rank = match.group(1);

        // 根据 RANK 级别确定所需最低达成率
        switch (rank) {
          case 'S':
            requiredRate = '97%';
            break;
          case 'S+':
            requiredRate = '98%';
            break;
          case 'SS':
            requiredRate = '99%';
            break;
          case 'SS+':
            requiredRate = '99.5%';
            break;
          case 'SSS':
            requiredRate = '100%';
            break;
          case 'SSS+':
            requiredRate = '100.5%';
            break;
        }
      } else if (hasClear || hasRankA) {
        // 如果没有 RANK 信息但有 CLEAR 或 RANK A 字样，设置为 80%
        requiredRate = '80%';
      }

      if (requiredRate.isNotEmpty) {
        // 根据达成率确定颜色
        Color rateColor = Colors.grey[800]!;
        if (requiredRate == '80%') {
          rateColor = AppColors.errorRed(Theme.of(context).brightness);
        } else if (['97%', '98%', '99%', '99.5%'].contains(requiredRate)) {
          rateColor = AppColors.linkBlue(Theme.of(context).brightness);
        } else if (['100%', '100.5%'].contains(requiredRate)) {
          rateColor = AppColors.warningOrange(Theme.of(context).brightness);
        }

        mergedConditions.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '所需最低达成率:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: rateColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: rateColor, width: 1),
                  ),
                  child: Text(
                    requiredRate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: rateColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // 检查是否包含 SPEED SONIC 字样
      bool hasSpeedSonic = description.toLowerCase().contains('speed sonic');
      if (hasSpeedSonic) {
        mergedConditions.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '所需游玩流速:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.linkBlue(Theme.of(context).brightness)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.linkBlue(Theme.of(context).brightness),
                        width: 1),
                  ),
                  child: Text(
                    'SONIC',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.linkBlue(Theme.of(context).brightness),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // 处理所需连击和同步
    for (final requiredItem in requiredList) {
      // 处理fc字段
      if (requiredItem.fc != null) {
        // 定义同步类型的fc值
        final syncTypes = ['fs', 'fsp', 'fsd', 'fsdp', 'sync'];

        if (syncTypes.contains(requiredItem.fc!)) {
          // fc字段是同步类型，显示到所需同步里
          if (!seenFs.contains(requiredItem.fc!)) {
            seenFs.add(requiredItem.fc!);
            mergedConditions.add(
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '所需同步:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    _getFsDisplay(requiredItem.fc!),
                  ],
                ),
              ),
            );
          }
        } else {
          // fc字段是连击类型，显示到所需连击里
          if (!seenFc.contains(requiredItem.fc!)) {
            seenFc.add(requiredItem.fc!);
            mergedConditions.add(
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '所需连击:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    _getFcDisplay(requiredItem.fc!),
                  ],
                ),
              ),
            );
          }
        }
      }

      // 处理所需同步（fs字段）
      if (requiredItem.fs != null) {
        if (!seenFs.contains(requiredItem.fs!)) {
          seenFs.add(requiredItem.fs!);
          mergedConditions.add(
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '所需同步:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  _getFsDisplay(requiredItem.fs!),
                ],
              ),
            ),
          );
        }
      }
    }

    // 添加底部间距
    if (mergedConditions.isNotEmpty) {
      mergedConditions.add(SizedBox(height: 16));
    }

    return mergedConditions;
  }

  Widget _buildSectionHeading(
      BuildContext context, IconData icon, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool primary,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor =
        primary ? colorScheme.onPrimary : colorScheme.onSurface;
    final backgroundColor =
        primary ? colorScheme.primary : colorScheme.surfaceContainerHighest;

    return Expanded(
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionPreview(BuildContext context) {
    if (widget.collectionType == 'trophies') return const SizedBox.shrink();

    final image = switch (widget.collectionType) {
      'icons' => CollectionsImageUtil.getIconImageURL(_collection!),
      'plates' => CollectionsImageUtil.getPlateImageURL(_collection!),
      'frames' => CollectionsImageUtil.getFrameImageURL(_collection!),
      _ => const SizedBox.shrink(),
    };
    final height = widget.collectionType == 'plates' ? 150.0 : 200.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: image,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionButton(
              context: context,
              icon: Icons.save_alt,
              label: _isSavingImage ? '保存中' : '保存到相册',
              onPressed: _isSavingImage ? null : _saveImageToGallery,
              primary: true,
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              context: context,
              icon: Icons.link,
              label: '复制链接',
              onPressed: _copyImageUrl,
              primary: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTranslationBlock({
    required BuildContext context,
    required String? translatedText,
    required bool isTranslating,
    required VoidCallback onTranslate,
    required String sourceLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (translatedText != null)
          Text(
            translatedText,
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (isTranslating)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (translatedText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '由百度大模型翻译自$sourceLabel',
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          )
        else
          TextButton(
            onPressed: onTranslate,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: const Text('翻译为中文'),
          ),
      ],
    );
  }

  Widget _buildCollectionDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final collection = _collection!;
    final nameNeedsTranslation = _isEnglishOrJapanese(collection.name);
    final descriptionNeedsTranslation = collection.description != null &&
        _isEnglishOrJapanese(collection.description!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          collection.name,
          style: TextStyle(
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'ID: ${widget.collectionId}',
          style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
        ),
        if (nameNeedsTranslation) ...[
          const SizedBox(height: 8),
          _buildTranslationBlock(
            context: context,
            translatedText: _translatedName,
            isTranslating: _isTranslatingName,
            onTranslate: _translateName,
            sourceLabel: _isEnglishAndJapanese(collection.name)
                ? '日语+英语'
                : _isEnglish(collection.name)
                    ? '英语'
                    : '日语',
          ),
        ],
        const SizedBox(height: 24),
        if (widget.collectionType == 'trophies') ...[
          _buildSectionHeading(context, Icons.badge_outlined, '称号展示预览'),
          const SizedBox(height: 10),
          TrophyTitleBadge(
              name: collection.name,
              color: collection.color,
              trophyId: collection.id,
              staticTextOffsetY: 1),
          const SizedBox(height: 24),
        ],
        if (widget.collectionType == 'trophies' &&
            collection.color != null) ...[
          _buildSectionHeading(context, Icons.palette_outlined, '底色'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: collection.color == 'Rainbow'
                  ? const LinearGradient(
                      colors: [
                        Colors.red,
                        Colors.orange,
                        Colors.yellow,
                        Colors.green,
                        Colors.blue,
                        Colors.indigo,
                        Colors.purple,
                      ],
                    )
                  : null,
              color: collection.color == 'Rainbow'
                  ? null
                  : _getColorFromType(collection.color!),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Text(
              collection.color!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: collection.color == 'Rainbow'
                    ? Colors.white
                    : _getTextColorForBackground(collection.color!),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (collection.description != null) ...[
          _buildSectionHeading(context, Icons.notes_outlined, '描述'),
          const SizedBox(height: 10),
          Text(
            collection.description!,
            style: TextStyle(
                fontSize: 16, height: 1.5, color: colorScheme.onSurface),
          ),
          if (descriptionNeedsTranslation) ...[
            const SizedBox(height: 8),
            _buildTranslationBlock(
              context: context,
              translatedText: _translatedDescription,
              isTranslating: _isTranslatingDescription,
              onTranslate: _translateDescription,
              sourceLabel: _isEnglishAndJapanese(collection.description!)
                  ? '日语+英语'
                  : _isEnglish(collection.description!)
                      ? '英语'
                      : '日语',
            ),
          ],
          const SizedBox(height: 24),
        ],
        if (collection.required != null && collection.required!.isNotEmpty) ...[
          _buildSectionHeading(context, Icons.checklist_outlined, '所需条件'),
          const SizedBox(height: 4),
          ..._getMergedRequiredConditions(collection.required!),
          const SizedBox(height: 8),
          _buildSectionHeading(context, Icons.library_music_outlined, '歌曲列表'),
          const SizedBox(height: 8),
          ..._getUniqueSongLists(collection.required!),
          if (!_isLoadingSongs &&
              widget.collectionType == 'plates' &&
              _collection != null &&
              PaiziProgressService().isProgressPlate(_collection!))
            _buildExcludedSongSection(),
        ],
        if (_isLoadingSongs)
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundPageScaffold(
      title: '${_getTypeLabel()}详情',
      resizeToAvoidBottomInset: false,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collection == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      const Text('未找到收藏品信息'),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ListView(
                    key: ValueKey(
                        'collection_${widget.collectionId}_${widget.collectionType}'),
                    padding: EdgeInsets.zero,
                    children: [
                      _buildCollectionPreview(context),
                      if (widget.collectionType != 'trophies')
                        const SizedBox(height: 24),
                      _buildCollectionDetails(context),
                    ],
                  ),
                ),
    );
  }
}
