import 'package:my_first_flutter_app/l10n/FeatureLocalizations.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import '../../service/Best50/Best50ConvertToImgService.dart';
import '../../manager/DivingFish/UserBest50Manager.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../manager/DivingFish/UserPlayDataManager.dart';
import '../../manager/MaiTagsManager.dart';
import '../../entity/DXRating/MaiTagsModel.dart';
import '../SongInfoPage.dart';
import '../../utils/CoverUtil.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../service/AccountStore.dart';
import '../../service/AccountSwitchService.dart';
import '../../utils/SongFilterUtil.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';
import '../../widgets/Best50Ui.dart';
import '../../widgets/AppDialogs.dart';
import '../../widgets/AppToast.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';
import '../../utils/MusicDataIndex.dart';
import '../../utils/JsonIsolate.dart';
import '../../utils/Best50Order.dart';

class B50Page extends StatefulWidget {
  final Map<String, dynamic>? b50Data;

  const B50Page({super.key, this.b50Data});

  @override
  _B50PageState createState() => _B50PageState();
}

class _B50PageState extends State<B50Page> {
  Map<String, dynamic>? _b50Data;
  List<Map<String, dynamic>>? _maimaiMusicData;
  List<Map<String, dynamic>> _dxSongs = [];
  List<Map<String, dynamic>> _sdSongs = [];

  // 按新旧曲分组的完整成绩，用来找和榜单末位 RA 并列的谱面。
  List<Map<String, dynamic>> _oldRecords = [];
  List<Map<String, dynamic>> _newRecords = [];
  List<Map<String, dynamic>> _theoreticalDxSongs = [];
  List<Map<String, dynamic>> _theoreticalSdSongs = [];
  // 存储被截断的相同定数歌曲
  Map<String, dynamic>?
      _remainingSdSongsInfo; // {ds: 14.7, count: 5, songs: [...]}
  Map<String, dynamic>? _remainingDxSongsInfo;
  bool _isLoading = true;
  bool _isTheoreticalMode = false;

  // 标签统计相关
  MaiTagsEntity? _tagsEntity;
  Map<String, Map<String, int>> _tagStats = {}; // 标签分组 → (标签名 → 统计次数)
  bool _isLoadingTags = false;
  bool _isTagStatsExpanded = false; // 标签统计默认收起
  int _segment = 0; // 0 = B35，1 = B15

  @override
  void initState() {
    super.initState();
    _loadB50Data();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(B50Page oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.b50Data != null && widget.b50Data != oldWidget.b50Data) {
      _updateB50Data(widget.b50Data!, sortCharts: true);
    }
  }

  Future<void> _loadB50Data() async {
    try {
      _snapshotRevision = AccountSwitchService.revision;
      _snapshotKey = 'b50_snapshots_${await AccountStore.accountKey()}';
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
                .toList();
          });
        }
      } else {
        final maimaiContents =
            await rootBundle.loadString('assets/maimai_music_data.json');
        final maimaiJsonData = await decodeJsonInBackground(maimaiContents);

        if (!mounted) return;
        setState(() {
          _maimaiMusicData = maimaiJsonData;
        });
      }

      // 直接使用外部传入的B50数据
      if (widget.b50Data != null) {
        _updateB50Data(widget.b50Data!, sortCharts: true);
      } else {
        unawaited(_loadRecordsForTies());
        final data = await UserBest50Manager().getBest50ForDisplay();
        if (!mounted) return;
        if (data != null) {
          _updateB50Data(data);
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecordsForTies() async {
    try {
      final data = await UserPlayDataManager().getCachedUserPlayData();
      final records = data?['records'];
      if (records is! List || !mounted) return;
      final oldRecords = <Map<String, dynamic>>[];
      final newRecords = <Map<String, dynamic>>[];
      for (final raw in records) {
        if (raw is! Map) continue;
        final record = Map<String, dynamic>.from(raw);
        final songId = record['song_id'];
        if (songId is! int || record['ra'] == null) continue;
        (_isSongNew(songId) ? newRecords : oldRecords).add(record);
      }
      setState(() {
        _oldRecords = oldRecords;
        _newRecords = newRecords;
      });
    } catch (e) {
      debugPrint('读取并列谱面失败: $e');
    }
  }

  /// 不在榜上、RA 和榜单最后一首相同的成绩。
  List<Map<String, dynamic>> _tiedRecords(
      List<Map<String, dynamic>> shown, List<Map<String, dynamic>> records) {
    if (shown.isEmpty) return const [];
    final lastRa = shown.last['ra'];
    final shownKeys = {
      for (final s in shown) '${s['song_id']}_${s['level_index']}',
    };
    final order = Best50Order(_calculateMaxScore);
    return [
      for (final r in records)
        if (r['ra'] == lastRa &&
            !shownKeys.contains('${r['song_id']}_${r['level_index']}'))
          r,
    ]..sort(order.compareMaps);
  }

  /// 根据歌曲ID判断是否为新曲（is_new=true）
  bool _isSongNew(int songId) {
    if (_maimaiMusicData == null) return false;

    try {
      // 使用 where() 和 firstWhereOrNull 替代 orElse 返回 null
      var song =
          _maimaiMusicData![MusicDataIndex.indexOf(_maimaiMusicData!, songId)];

      if (song['basic_info'] != null) {
        return song['basic_info']['is_new'] == true;
      }
    } catch (e) {
      // 歌曲未找到时返回 false
      debugPrint('Song $songId not found in music data');
    }

    return false;
  }

  void _updateB50Data(Map<String, dynamic> newData, {bool sortCharts = false}) {
    final charts = newData['charts'] as Map? ?? const {};
    final dx = List<Map<String, dynamic>>.from(charts['dx'] as List? ?? []);
    final sd = List<Map<String, dynamic>>.from(charts['sd'] as List? ?? []);
    if (sortCharts) {
      final order = Best50Order(_calculateMaxScore);
      dx.sort(order.compareMaps);
      sd.sort(order.compareMaps);
    }
    setState(() {
      _b50Data = newData;
      _dxSongs = dx;
      _sdSongs = sd;
      _isLoading = false;
    });
    _calculateTheoreticalBest50();
    _loadTagDataAndCalculateStats();
  }

  // 计算理论Rating Best50
  void _calculateTheoreticalBest50() {
    if (_maimaiMusicData == null) return;

    List<Map<String, dynamic>> allSongs = [];

    for (var song in _maimaiMusicData!) {
      int songId = int.parse(song['id']);
      String type = song['type'];
      bool isNew = song['basic_info']?['is_new'] == true;
      List<dynamic> charts = song['charts'];
      List<dynamic> cids = song['cids'] ?? [];

      // 过滤条件：
      // 1. 过滤掉id为6位数的歌曲（songId >= 100000，宴会场谱面）
      // 2. 过滤掉从maidata追加的歌曲（cids全为0）
      // 3. 过滤掉 SongFilterUtil.theoreticalRatingExcludedIds 白名单里
      //    强制不参与理论 Rating 的曲目（如 #11879）
      bool isMaidataSong = cids.isNotEmpty && cids.every((cid) => cid == 0);
      bool isExtra = song['is_extra'] == true;
      if (songId >= 100000 ||
          isMaidataSong ||
          isExtra ||
          SongFilterUtil.isTheoreticalRatingExcluded(song['id'].toString())) {
        continue;
      }

      for (int levelIndex = 0; levelIndex < charts.length; levelIndex++) {
        dynamic chart = charts[levelIndex];
        List<dynamic> notes = chart['notes'];
        int notesSum = notes.fold(0, (sum, note) => sum + (note as int));
        int maxScore = notesSum * 3;
        double ds = double.parse(song['ds'][levelIndex].toString());

        // 计算理论Rating：ds * 0.224 * 100.5 向下取整
        int ra = (ds * 0.224 * 100.5).floor();

        allSongs.add({
          'song_id': songId,
          'title': song['title'],
          'type': type,
          'level_index': levelIndex,
          'ds': ds,
          'ra': ra,
          'achievements': 101.0,
          'dxScore': maxScore,
          'fc': 'app',
          'fs': 'fsdp',
          'rate': 'sssp',
          'is_new': isNew,
          'stars': '\u27266',
        });
      }
    }

    // 按is_new分组（DX新歌和SD老歌）
    List<Map<String, dynamic>> newSongs =
        allSongs.where((s) => s['is_new'] == true).toList();
    List<Map<String, dynamic>> oldSongs =
        allSongs.where((s) => s['is_new'] == false).toList();

    final order = Best50Order(_calculateMaxScore);
    newSongs.sort(order.compareMaps);
    oldSongs.sort(order.compareMaps);

    // 取Best15和Best35，并计算剩余相同定数的歌曲
    _theoreticalDxSongs = _takeWithRemaining(
        newSongs, 15, (info) => _remainingDxSongsInfo = info);
    _theoreticalSdSongs = _takeWithRemaining(
        oldSongs, 35, (info) => _remainingSdSongsInfo = info);
  }

  // 取前limit个元素，并计算剩余相同定数的歌曲
  List<Map<String, dynamic>> _takeWithRemaining(
    List<Map<String, dynamic>> songs,
    int limit,
    void Function(Map<String, dynamic>?) onRemaining,
  ) {
    if (songs.length <= limit) {
      onRemaining(null);
      return songs.toList();
    }

    // 取前limit个
    List<Map<String, dynamic>> taken = songs.take(limit).toList();

    // 获取最后一个元素的ds值
    double lastDs = taken.last['ds'] ?? 0.0;

    // 找出所有被截断的相同ds的歌曲
    List<Map<String, dynamic>> remaining = songs.skip(limit).where((s) {
      return (s['ds'] ?? 0.0) == lastDs;
    }).toList();

    if (remaining.isNotEmpty) {
      onRemaining({
        'ds': lastDs,
        'count': remaining.length,
        'songs': remaining,
      });
    } else {
      onRemaining(null);
    }

    return taken;
  }

  // 切换理论模式
  void _toggleTheoreticalMode() {
    setState(() {
      _isTheoreticalMode = !_isTheoreticalMode;
    });
  }

  // 加载标签数据并计算统计
  Future<void> _loadTagDataAndCalculateStats() async {
    setState(() {
      _isLoadingTags = true;
    });

    try {
      final maiTagsManager = MaiTagsManager();
      _tagsEntity = await maiTagsManager.getTags();

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

  // 计算各标签统计
  Future<void> _calculateTagGroupStats() async {
    if (_tagsEntity == null || _maimaiMusicData == null) {
      return;
    }

    final maiTagsManager = MaiTagsManager();
    final tagIdToNameMap = await maiTagsManager.getTagIdToNameMap();
    final groupIdToNameMap = await maiTagsManager.getGroupIdToNameMap();

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

    // 统计各标签的出现次数
    Map<String, Map<String, int>> stats = {};
    List<Map<String, dynamic>> allSongs = [
      ...(_isTheoreticalMode ? _theoreticalSdSongs : _sdSongs),
      ...(_isTheoreticalMode ? _theoreticalDxSongs : _dxSongs)
    ];

    for (var song in allSongs) {
      int songId = song['song_id'];
      int levelIndex = song['level_index'];

      int index = MusicDataIndex.indexOf(_maimaiMusicData!, songId);
      Map<String, dynamic> songData =
          index >= 0 ? _maimaiMusicData![index] : {};

      String songTitle = songData['basic_info']?['title'] ?? '';
      String songType = songData['type'] ?? 'SD';

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

  // 根据难度索引获取难度名称
  String _getDifficultyByIndex(int index) {
    return ChartDifficulty.apiNameOf(index, fallback: 'unknown');
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (_isLoading) {
      return const BackgroundPageScaffold(
        title: 'Best50',
        resizeToAvoidBottomInset: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_b50Data == null || (_dxSongs.isEmpty && _sdSongs.isEmpty)) {
      // 空状态与正常内容共用背景和顶部栏。
      return BackgroundPageScaffold(
        title: 'Best50',
        resizeToAvoidBottomInset: false,
        contentPadding:
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 64,
                color: AppColors.greyHint(brightness),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.flowNoBest50DataYet,
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.flowReturnHomeAndTapRefreshData,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final songs = _segment == 0
        ? (_isTheoreticalMode ? _theoreticalSdSongs : _sdSongs)
        : (_isTheoreticalMode ? _theoreticalDxSongs : _dxSongs);
    final theoreticalRemaining =
        _segment == 0 ? _remainingSdSongsInfo : _remainingDxSongsInfo;
    final List<Map<String, dynamic>> remaining = _isTheoreticalMode
        ? List<Map<String, dynamic>>.from(theoreticalRemaining?['songs'] ?? [])
        : _tiedRecords(songs, _segment == 0 ? _oldRecords : _newRecords);
    final remainingLabel = _isTheoreticalMode
        ? context.l10n.flowConstantP0(
            (((theoreticalRemaining?['ds'] ?? 0.0) as double)
                    .toStringAsFixed(1))
                .toString())
        : (songs.isEmpty ? null : 'RA ${songs.last['ra']}');

    return BackgroundPageScaffold(
      title: _isTheoreticalMode
          ? context.l10n.flowTheoreticalRatingBest50
          : 'Best50',
      resizeToAvoidBottomInset: false,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      actionsEndInset: 4,
      actions: [
        Best50IconAction(
          tooltip: context.l10n.flowSaveCurrentRecord,
          icon: Icons.bookmark_add_outlined,
          onPressed: _saveSnapshot,
        ),
        Best50IconAction(
          tooltip: context.l10n.flowHistory,
          icon: Icons.history_rounded,
          onPressed: () async {
            await _loadSnapshots();
            _showSnapshotDialog();
          },
        ),
        Best50IconAction(
          tooltip: context.l10n.flowExportAsImage,
          icon: Icons.image_outlined,
          onPressed: () async {
            debugPrint('=== EXPORT BUTTON CLICKED ===');
            try {
              await _exportToImage();
            } catch (e) {
              debugPrint('Error in export: $e');
            }
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 4,
            AppDesignTokens.gutter, AppDesignTokens.gutter + 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRatingSection(),
            if (!_isTheoreticalMode) ...[
              const SizedBox(height: AppDesignTokens.cardGap),
              _buildTagStatsSection(context),
            ],
            const SizedBox(height: AppDesignTokens.cardGap),
            Best50Grid(
              contentKey: '$_isTheoreticalMode-$_segment',
              items: [for (final s in songs) _cardData(s)],
              remaining: [for (final s in remaining) _cardData(s)],
              remainingLabel: remainingLabel,
            ),
          ],
        ),
      ),
    );
  }

  // Best50 历史快照
  int _snapshotRevision = -1;
  String? _snapshotKey;
  List<Map<String, dynamic>> _snapshots = [];

  Future<void> _loadSnapshots() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_snapshotKey == null) return;
      _snapshots = [];
      final jsonStr = prefs.getString(_snapshotKey!);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        _snapshots = (json.decode(jsonStr) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveSnapshot() async {
    if (_b50Data == null) return;
    if (AccountSwitchService.isBusy ||
        _snapshotRevision != AccountSwitchService.revision) {
      if (mounted) {
        AppToast.show(
            context.l10n.flowAccountDataChangedReopenBest50BeforeSaving,
            tone: AppToastTone.warning);
      }
      return;
    }
    try {
      await _loadSnapshots();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _snapshots.insert(0, {
        'date': dateStr,
        'timestamp': now.millisecondsSinceEpoch,
        'rating': _b50Data!['rating'] ?? 0,
        'charts': {'sd': _sdSongs, 'dx': _dxSongs},
      });
      // 最多保留 10 条
      if (_snapshots.length > 10) _snapshots = _snapshots.take(10).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_snapshotKey!, json.encode(_snapshots));
      if (mounted) {
        AppToast.show(
            context.l10n.flowBest50RecordSavedP0((dateStr).toString()),
            duration: Duration(seconds: 1));
      }
    } catch (e) {
      debugPrint('保存快照失败: $e');
    }
  }

  Future<void> _deleteSnapshot(int index) async {
    try {
      _snapshots.removeAt(index);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_snapshotKey!, json.encode(_snapshots));
    } catch (_) {}
  }

  void _showSnapshotDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dialogBrightness = Theme.of(ctx).brightness;
          return AppAlertDialog(
            title: Row(
              children: [
                Icon(Icons.history,
                    size: 22, color: Theme.of(ctx).colorScheme.onSurface),
                SizedBox(width: 8),
                Text(context.l10n.flowBest50History),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: _snapshots.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                          context.l10n.flowNoSavedRecordsTapSaveCurrentRecord,
                          style: TextStyle(
                              color:
                                  Theme.of(ctx).colorScheme.onSurfaceVariant)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _snapshots.length,
                      itemBuilder: (ctx, i) {
                        final s = _snapshots[i];
                        return Container(
                          margin: EdgeInsets.only(bottom: 6),
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: AppColors.tableBorder(dialogBrightness)),
                            borderRadius: BorderRadius.circular(
                                AppDesignTokens.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.bookmark,
                                  color: AppColors.linkBlue(dialogBrightness),
                                  size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Rating: ${s['rating']}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    Text(s['date'] ?? '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  _updateB50Data({
                                    'rating': s['rating'],
                                    'charts': s['charts'],
                                  }, sortCharts: true);
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.remove_red_eye,
                                      size: 18,
                                      color:
                                          AppColors.linkBlue(dialogBrightness)),
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await _deleteSnapshot(i);
                                  setDialogState(() {});
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(6),
                                  child: Icon(Icons.delete_outline,
                                      size: 18,
                                      color:
                                          AppColors.errorRed(dialogBrightness)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.featureClose)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingSection() {
    // 选择显示的数据
    List<Map<String, dynamic>> currentSdSongs =
        _isTheoreticalMode ? _theoreticalSdSongs : _sdSongs;
    List<Map<String, dynamic>> currentDxSongs =
        _isTheoreticalMode ? _theoreticalDxSongs : _dxSongs;

    // 计算Rating
    int best35Sum =
        currentSdSongs.fold(0, (sum, song) => sum + ((song['ra'] ?? 0) as int));

    int best15Sum =
        currentDxSongs.fold(0, (sum, song) => sum + ((song['ra'] ?? 0) as int));

    int rating =
        _isTheoreticalMode ? best35Sum + best15Sum : (_b50Data?['rating'] ?? 0);
    double ratingAverage = (best35Sum + best15Sum) / 50;

    // 理论模式下使用固定值
    double best50AchievementAverage;
    double best35AchievementAverage;
    double best15AchievementAverage;
    double best50ScoreRateAverage;
    double best35ScoreRateAverage;
    double best15ScoreRateAverage;

    if (_isTheoreticalMode) {
      best50AchievementAverage = 101.0;
      best35AchievementAverage = 101.0;
      best15AchievementAverage = 101.0;
      best50ScoreRateAverage = 1.0;
      best35ScoreRateAverage = 1.0;
      best15ScoreRateAverage = 1.0;
    } else {
      double sdAchievementsSum = currentSdSongs.fold(0.0,
          (sum, song) => sum + (double.parse(song['achievements'].toString())));
      double dxAchievementsSum = currentDxSongs.fold(0.0,
          (sum, song) => sum + (double.parse(song['achievements'].toString())));

      best50AchievementAverage = (sdAchievementsSum + dxAchievementsSum) /
          (currentSdSongs.length + currentDxSongs.length);
      best35AchievementAverage = currentSdSongs.isNotEmpty
          ? sdAchievementsSum / currentSdSongs.length
          : 0.0;
      best15AchievementAverage = currentDxSongs.isNotEmpty
          ? dxAchievementsSum / currentDxSongs.length
          : 0.0;

      double sdScoreRateSum = currentSdSongs.fold(0.0, (sum, song) {
        int songId = song['song_id'];
        int levelIndex = song['level_index'];
        int score = song['dxScore'];
        return sum + _calculateScoreRate(songId, levelIndex, score);
      });

      double dxScoreRateSum = currentDxSongs.fold(0.0, (sum, song) {
        int songId = song['song_id'];
        int levelIndex = song['level_index'];
        int score = song['dxScore'];
        return sum + _calculateScoreRate(songId, levelIndex, score);
      });

      best50ScoreRateAverage =
          (currentSdSongs.length + currentDxSongs.length) > 0
              ? (sdScoreRateSum + dxScoreRateSum) /
                  (currentSdSongs.length + currentDxSongs.length)
              : 0.0;

      best35ScoreRateAverage = currentSdSongs.isNotEmpty
          ? sdScoreRateSum / currentSdSongs.length
          : 0.0;
      best15ScoreRateAverage = currentDxSongs.isNotEmpty
          ? dxScoreRateSum / currentDxSongs.length
          : 0.0;
    }

    final segmentSongs = _segment == 0 ? currentSdSongs : currentDxSongs;
    final segmentName = _segment == 0
        ? (_isTheoreticalMode
            ? context.l10n.flowHighestConstantsFromOlderVersions
            : context.l10n.flowBestScoresFromOlderVersions)
        : (_isTheoreticalMode
            ? context.l10n.flowHighestConstantsFromThisVersion
            : context.l10n.flowBestScoresFromThisVersion);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Best50Hero(
          total: rating,
          label: _isTheoreticalMode
              ? context.l10n.flowTheoreticalRatingAverageP0(
                  (ratingAverage.toStringAsFixed(1)).toString())
              : context.l10n.flowCurrentRatingAverageP0(
                  (ratingAverage.toStringAsFixed(1)).toString()),
          best35Sum: best35Sum,
          best15Sum: best15Sum,
          trailing: Best50SwitchPill(
            label: context.l10n.flowTheoretical,
            value: _isTheoreticalMode,
            onChanged: (_) => _toggleTheoreticalMode(),
          ),
        ),
        const SizedBox(height: AppDesignTokens.cardGap),
        SegmentedTabs(
          inlineCaption: true,
          items: [
            SegmentedTabItem('B35', caption: '$best35Sum'),
            SegmentedTabItem('B15', caption: '$best15Sum'),
          ],
          selectedIndex: _segment,
          onChanged: (i) => setState(() => _segment = i),
        ),
        const SizedBox(height: 8),
        Best50MetaLine(best50MetaText(
            segmentName, segmentSongs.map((s) => (s['ra'] ?? 0) as int))),
        if (!_isTheoreticalMode) ...[
          const SizedBox(height: AppDesignTokens.cardGap),
          Best50AveragesCard(
            title: context.l10n.flowAverageAchievementDXScoreRate,
            rows: [
              Best50AverageRow(
                  'B50', best50AchievementAverage, best50ScoreRateAverage),
              Best50AverageRow(
                  'B35', best35AchievementAverage, best35ScoreRateAverage),
              Best50AverageRow(
                  'B15', best15AchievementAverage, best15ScoreRateAverage),
            ],
          ),
        ],
      ],
    );
  }

  // 构建标签统计区域
  Widget _buildTagStatsSection(BuildContext context) {
    final tagBrightness = Theme.of(context).brightness;
    final colorScheme = Theme.of(context).colorScheme;
    final canExpand = !_isLoadingTags && _tagStats.isNotEmpty;

    // 分组颜色映射
    Map<String, Color> groupColors = {
      '配置': AppColors.linkBlue(tagBrightness),
      '评价': colorScheme.tertiary,
      '难度': AppColors.linkBlue(tagBrightness),
    };

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: canExpand,
            expanded: canExpand ? _isTagStatsExpanded : null,
            label: context.l10n.flowTagStatistics,
            child: InkWell(
              onTap: canExpand
                  ? () => setState(() {
                        _isTagStatsExpanded = !_isTagStatsExpanded;
                      })
                  : null,
              child: Container(
                // 与 Best50AveragesCard 的标题行同高
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.flowTagStatistics,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (_isLoadingTags)
                      SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else if (_tagStats.isEmpty)
                      Text(
                        context.l10n.flowNoTagData,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      AnimatedRotation(
                        turns: _isTagStatsExpanded ? 0.5 : 0.0,
                        duration: AppDesignTokens.motion(
                            context, const Duration(milliseconds: 240)),
                        curve: Curves.easeOutCubic,
                        child: Icon(Icons.expand_more_rounded,
                            color: colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppDesignTokens.motion(
                context, const Duration(milliseconds: 260)),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: double.infinity,
              child: _isTagStatsExpanded && canExpand
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _tagStats.entries.map((groupEntry) {
                          String groupName = groupEntry.key;
                          Map<String, int> tagCounts = groupEntry.value;
                          Color groupColor = groupColors[groupName] ??
                              colorScheme.onSurfaceVariant;

                          // 对组内标签按数量降序排序
                          List<MapEntry<String, int>> sortedTags =
                              tagCounts.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value));

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                margin: EdgeInsets.only(top: 8.0),
                                decoration: BoxDecoration(
                                  color: groupColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppDesignTokens.radiusPill),
                                ),
                                child: Text(
                                  context.featureText(groupName),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: groupColor,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6.0),
                              ...sortedTags.map((tagEntry) {
                                double percentage = (tagEntry.value / 50) * 100;
                                Color barColor =
                                    groupColor.withValues(alpha: 0.7);

                                return Padding(
                                  padding: EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          context.featureText(tagEntry.key),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(width: 8.0),
                                      Expanded(
                                        flex: 6,
                                        child: SmoothLinearProgressIndicator(
                                          value: (percentage / 100)
                                              .clamp(0.0, 1.0),
                                          minHeight: 14.0,
                                          color: barColor,
                                          backgroundColor:
                                              AppSurfaces.inset(context),
                                          borderRadius: BorderRadius.circular(
                                              AppDesignTokens.radiusPill),
                                        ),
                                      ),
                                      SizedBox(width: 8.0),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          '${tagEntry.value}(${percentage.toStringAsFixed(0)}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              SizedBox(height: 4.0),
                            ],
                          );
                        }).toList(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Best50CardData _cardData(Map<String, dynamic> songData) {
    final achievementRate = double.parse(songData['achievements'].toString());
    final int score = songData['dxScore'];
    // 通过 ds 字符串的小数位数判断是否为拟合定数（>1 位小数视为拟合）
    final dsStr = songData['ds'].toString();
    final dotIdx = dsStr.indexOf('.');
    final int levelIndex = songData['level_index'];
    final int songId = songData['song_id'];
    // 理论模式下使用固定值
    final scoreRate = _isTheoreticalMode
        ? 1.0
        : _calculateScoreRate(songId, levelIndex, score);
    return Best50CardData(
      songId: songId,
      title: songData['title'],
      levelIndex: levelIndex,
      type: songData['type'],
      rating: songData['ra'],
      ds: double.parse(dsStr),
      isFitDiff: dotIdx >= 0 && (dsStr.length - dotIdx - 1) > 1,
      achievement: achievementRate,
      fc: songData['fc'] ?? '',
      fs: songData['fs'] ?? '',
      stars: _isTheoreticalMode ? '\u27266' : StringUtil.formatStars(scoreRate),
      dxScore: score,
      maxDxScore: _calculateMaxScore(songId, levelIndex),
      onOpenSong: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SongInfoPage(
            songId: songId.toString(),
            initialLevelIndex: levelIndex,
          ),
        ),
      ),
    );
  }

  // 获取难度标签
  String _getDifficultyLabel(int levelIndex) {
    List<String> labels = ChartDifficulty.standardLabels;
    return levelIndex >= 0 && levelIndex < labels.length
        ? labels[levelIndex]
        : 'Unknown';
  }

  int _calculateMaxScore(int songId, int levelIndex) {
    if (_maimaiMusicData == null) return 0;
    int songIndex = MusicDataIndex.indexOf(_maimaiMusicData!, songId);
    if (songIndex == -1) return 0;
    dynamic songData = _maimaiMusicData![songIndex];
    if (songData['charts'] == null) return 0;
    List<dynamic> charts = songData['charts'];
    if (levelIndex < 0 || levelIndex >= charts.length) return 0;
    dynamic chart = charts[levelIndex];
    if (chart['notes'] == null) return 0;
    List<dynamic> notes = chart['notes'];
    int notesSum = notes.fold(0, (sum, note) => sum + (note as int));
    return notesSum * 3;
  }

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

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    debugPrint('Page: _requestStoragePermission called');
    debugPrint('Page: Platform.isAndroid = ${Platform.isAndroid}');

    if (Platform.isAndroid) {
      debugPrint('Page: Running on Android');

      // 策略：同时请求 storage 和 photos 权限，确保覆盖所有 Android 版本
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

      // 请求权限：同时请求 storage 和 photos
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

  Future<void> _exportToImage() async {
    try {
      debugPrint('=== EXPORT TO IMAGE STARTED ===');
      debugPrint('Current context: $context');

      // 先请求存储权限
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

      // Show quality selector first
      final estimatedPngSize = ImageEncodeUtil.estimatePngSize(
          songCount: 50, hasHeader: true, hasUserInfo: !_isTheoreticalMode);
      final quality = await ExportQualitySelector.show(
        context,
        estimatedPngSize: estimatedPngSize,
        exportingLabel:
            _isTheoreticalMode ? context.l10n.flowTheoreticalBest50 : 'Best50',
        enableThunderMode: true,
        previewBuilder: (previewContext, previewQuality) =>
            B50ConvertToImg.buildPreviewWidget(
          previewContext,
          _b50Data,
          _isTheoreticalMode ? _theoreticalSdSongs : _sdSongs,
          _isTheoreticalMode ? _theoreticalDxSongs : _dxSongs,
          _maimaiMusicData,
          isTheoreticalMode: _isTheoreticalMode,
          thunderMode: previewQuality.thunderMode,
          thunderVertical: previewQuality.thunderVertical,
          theme: previewQuality.theme,
        ),
      );
      if (quality == null) return; // user cancelled

      // 导出期间可以继续操作，先把当前模式的数据取好。
      final isTheoretical = _isTheoreticalMode;
      final sdSongs = isTheoretical ? _theoreticalSdSongs : _sdSongs;
      final dxSongs = isTheoretical ? _theoreticalDxSongs : _dxSongs;
      final b50Data = _b50Data;
      final musicData = _maimaiMusicData;
      BackgroundExport.run(
        label: isTheoretical ? context.l10n.flowTheoreticalBest50 : 'Best50',
        task: (exportContext) => B50ConvertToImg.convertToImage(
          exportContext,
          b50Data,
          sdSongs,
          dxSongs,
          musicData,
          isTheoreticalMode: isTheoretical,
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
}
