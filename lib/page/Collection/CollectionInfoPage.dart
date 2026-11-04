import '../../service/PaiziProgressService.dart';
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
import '../../utils/AppDesignTokens.dart';
import '../../widgets/AppUi.dart';
import '../../widgets/MarqueeText.dart';
import '../../widgets/ProgressUi.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';

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
        showAppNoticeDialog(context, title: '权限不足', message: '需要存储权限才能保存图片到相册，请在设置中开启权限', tone: AppDialogTone.warning);
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
    AppToast.show(message, duration: Duration(seconds: 2));
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
      CollectionRequiredSong requiredSong, Song? song,
      {bool showDivider = false}) {
    final scheme = Theme.of(context).colorScheme;
    final songId = song?.id.toString() ?? requiredSong.id.toString();
    // 获取定数列表
    List<double> dsList = [];
    if (song != null && song.ds != null && song.ds is List) {
      dsList = song.ds;
    }
    return InkWell(
      onTap: () {
        // 跳转到歌曲详情页面，默认选择MASTER难度
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongInfoPage(
              songId: songId,
              initialLevelIndex: 3, // 3 代表 MASTER 难度
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(top: BorderSide(color: AppSurfaces.hairline(context)))
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: CoverUtil.buildCoverWidgetWithContext(context, songId, 48),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MarqueeText(
                    text: requiredSong.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 类型 | 版本
                  Text(
                    '${_getTypeDisplay(requiredSong.type)} | ${song != null ? StringUtil.formatVersion2WithFlag(song.basicInfo.from, song.isExtra) : '-'}',
                    style:
                        TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                  if (dsList.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    ChartConstantBadges(
                      constants: dsList,
                      isUtage: songId.length == 6,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 把一组歌曲摊成列表项。歌曲可能有几百首，每行单独按需构建，不能放回 Column。
  void _addSongRows(
    List<Widget Function(BuildContext)> entries,
    List<(CollectionRequiredSong, Song?)> songs,
  ) {
    for (var i = 0; i < songs.length; i++) {
      final (requiredSong, song) = songs[i];
      entries.add((_) => GroupedRowShell(
            first: i == 0,
            last: i == songs.length - 1,
            child: _buildCollectionSongCard(requiredSong, song,
                showDivider: i > 0),
          ));
    }
  }

  void _addExcludedSongEntries(List<Widget Function(BuildContext)> entries) {
    entries.add((_) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: AppSectionHeader(
            title: '条件外排除曲目',
            subtitle: '共 ${_excludedSongs.length} 首，不计入所需条件',
          ),
        ));
    _addSongRows(entries, [
      for (final song in _excludedSongs)
        (
          CollectionRequiredSong(
              id: int.tryParse(song.id) ?? 0,
              title: song.title,
              type: song.type),
          song,
        ),
    ]);
  }

  /// 去重后的歌曲列表：相同曲目组成的条件只显示一次，标题带歌曲总数。
  void _addSongListEntries(List<Widget Function(BuildContext)> entries,
      List<CollectionRequired> requiredList) {
    final seenSongLists = <String>{};
    final seenSongs = <String>{};
    final lists = <List<CollectionRequiredSong>>[];
    for (final requiredItem in requiredList) {
      final songs = requiredItem.songs;
      if (songs == null || songs.isEmpty) continue;
      final keys = songs.map((s) => '${s.id}:${s.title}:${s.type}');
      if (!seenSongLists.add(keys.join(','))) continue;
      seenSongs.addAll(keys);
      lists.add(songs);
    }
    if (seenSongs.isEmpty) return;
    entries.add((_) => AppSectionHeader(
          title: '歌曲列表',
          subtitle: '总计 ${seenSongs.length} 首歌曲',
        ));
    for (final songs in lists) {
      _addSongRows(entries, [
        for (final song in songs) (song, _songMap?[song]),
      ]);
      entries.add((_) => const SizedBox(height: AppDesignTokens.cardGap));
    }
  }

  /// 所需条件的一行：左边条件名，右边徽章。
  Widget _buildConditionRow(String label, List<Widget> badges) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: badges)),
        ],
      ),
    );
  }

  // 合并所需条件
  List<Widget> _getMergedRequiredConditions(
      List<CollectionRequired> requiredList) {
    final brightness = Theme.of(context).brightness;
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
      mergedConditions.add(_buildConditionRow('所需难度', [
        for (final d in sortedDifficulties)
          ChartDifficultyBadge(levelIndex: d, songId: '', fontSize: 14),
      ]));
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
        // 根据 RANK 级别确定所需最低达成率
        switch (match.group(1)) {
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
        Color rateColor = Theme.of(context).colorScheme.onSurface;
        if (requiredRate == '80%') {
          rateColor = AppColors.errorRed(brightness);
        } else if (['97%', '98%', '99%', '99.5%'].contains(requiredRate)) {
          rateColor = AppColors.linkBlue(brightness);
        } else if (['100%', '100.5%'].contains(requiredRate)) {
          rateColor = AppColors.warningOrange(brightness);
        }
        mergedConditions.add(_buildConditionRow('所需最低达成率', [
          AppBadge(
            text: requiredRate,
            fontSize: 14,
            background: rateColor.withValues(alpha: 0.12),
            foreground: rateColor,
          ),
        ]));
      }

      // 检查是否包含 SPEED SONIC 字样
      if (description.toLowerCase().contains('speed sonic')) {
        final sonic = AppColors.linkBlue(brightness);
        mergedConditions.add(_buildConditionRow('所需游玩流速', [
          AppBadge(
            text: 'SONIC',
            fontSize: 14,
            background: sonic.withValues(alpha: 0.12),
            foreground: sonic,
          ),
        ]));
      }
    }

    // 所需连击和同步：fc 字段里也可能是同步类型，归到所需同步
    const syncTypes = ['fs', 'fsp', 'fsd', 'fsdp', 'sync'];
    final fcValues = <String>{};
    final fsValues = <String>{};
    for (final requiredItem in requiredList) {
      final fc = requiredItem.fc;
      if (fc != null) (syncTypes.contains(fc) ? fsValues : fcValues).add(fc);
      if (requiredItem.fs != null) fsValues.add(requiredItem.fs!);
    }
    if (fcValues.isNotEmpty) {
      mergedConditions.add(_buildConditionRow('所需连击', [
        for (final fc in fcValues) ComboLabelBadge(raw: fc, fontSize: 14),
      ]));
    }
    if (fsValues.isNotEmpty) {
      mergedConditions.add(_buildConditionRow('所需同步', [
        for (final fs in fsValues) ComboLabelBadge(raw: fs, fontSize: 14),
      ]));
    }

    return mergedConditions;
  }

  Widget _buildCollectionPreview(BuildContext context) {
    if (widget.collectionType == 'trophies') return const SizedBox.shrink();

    final image = switch (widget.collectionType) {
      'icons' => CollectionsImageUtil.getIconImageURL(_collection!),
      'plates' => CollectionsImageUtil.getPlateImageURL(_collection!),
      'frames' => CollectionsImageUtil.getFrameImageURL(_collection!),
      _ => const SizedBox.shrink(),
    };
    final height = widget.collectionType == 'plates' ? 130.0 : 190.0;

    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppSurfaces.inset(context),
        borderRadius: BorderRadius.circular(AppDesignTokens.radiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
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
    final isTrophy = widget.collectionType == 'trophies';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 头部：预览、名称、操作
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCollectionPreview(context),
              if (isTrophy) ...[
                TrophyTitleBadge(
                    name: collection.name,
                    color: collection.color,
                    trophyId: collection.id,
                    staticTextOffsetY: 1),
                const SizedBox(height: 14),
              ],
              Text(
                collection.name,
                style: TextStyle(
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'ID ${widget.collectionId}',
                    style: AppTheme.number(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (isTrophy && collection.color != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
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
                        borderRadius:
                            BorderRadius.circular(AppDesignTokens.radiusPill),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text(
                        collection.color!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: collection.color == 'Rainbow'
                              ? Colors.white
                              : _getTextColorForBackground(collection.color!),
                        ),
                      ),
                    ),
                  ],
                ],
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
              if (!isTrophy) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSavingImage ? null : _saveImageToGallery,
                        icon: const Icon(Icons.save_alt, size: 18),
                        label: Text(_isSavingImage ? '保存中' : '保存到相册'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _copyImageUrl,
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('复制链接'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (collection.description != null) ...[
          const SizedBox(height: AppDesignTokens.cardGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(
                  title: '描述',
                  padding: EdgeInsets.only(bottom: 8),
                ),
                Text(
                  collection.description!,
                  style: TextStyle(
                      fontSize: 14, height: 1.5, color: colorScheme.onSurface),
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
              ],
            ),
          ),
        ],
        if (collection.required != null && collection.required!.isNotEmpty) ...[
          const SizedBox(height: AppDesignTokens.cardGap),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppSectionHeader(
                  title: '所需条件',
                  padding: EdgeInsets.zero,
                ),
                ..._getMergedRequiredConditions(collection.required!),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// 页面内容：头部一项，之后每首歌一项。
  List<Widget Function(BuildContext)> _buildEntries() {
    final collection = _collection!;
    final entries = <Widget Function(BuildContext)>[
      _buildCollectionDetails,
    ];
    final requiredList = collection.required;
    if (requiredList != null && requiredList.isNotEmpty) {
      _addSongListEntries(entries, requiredList);
      if (!_isLoadingSongs &&
          widget.collectionType == 'plates' &&
          PaiziProgressService().isProgressPlate(collection)) {
        _addExcludedSongEntries(entries);
      }
    }
    if (_isLoadingSongs) {
      entries.add((_) => const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(child: CircularProgressIndicator()),
          ));
    }
    return entries;
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
              : Builder(builder: (context) {
                  final entries = _buildEntries();
                  return ListView.builder(
                    key: ValueKey(
                        'collection_${widget.collectionId}_${widget.collectionType}'),
                    padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter,
                        4, AppDesignTokens.gutter, AppDesignTokens.gutter),
                    itemCount: entries.length,
                    itemBuilder: (context, index) => entries[index](context),
                  );
                }),
    );
  }
}
