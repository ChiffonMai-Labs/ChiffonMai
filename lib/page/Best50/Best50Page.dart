import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/utils/StringUtil.dart';
import 'package:my_first_flutter_app/utils/ColorUtil.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import '../../service/Best50/Best50ConvertToImgService.dart';
import '../../widgets/B50GameCardWidget.dart';
import '../../manager/DivingFish/UserBest50Manager.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../manager/DivingFish/UserPlayDataManager.dart';
import '../../manager/MaiTagsManager.dart';
import '../../entity/DXRating/MaiTagsModel.dart';
import '../SongInfoPage.dart';
import '../../utils/CoverUtil.dart';
import '../../entity/DivingFish/RecordItem.dart';
import 'package:my_first_flutter_app/utils/ExportQualitySelector.dart';
import 'package:my_first_flutter_app/utils/ImageEncodeUtil.dart';
import '../../widgets/BackgroundPageScaffold.dart';
import '../../service/AccountStore.dart';
import '../../service/AccountSwitchService.dart';
import '../../utils/SongFilterUtil.dart';
import '../../widgets/SmoothLinearProgressIndicator.dart';
import '../../widgets/AppUi.dart';
import '../../utils/AppDesignTokens.dart';

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
      _updateB50Data(widget.b50Data!);
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
        final maimaiJsonData = json.decode(maimaiContents);

        setState(() {
          _maimaiMusicData = maimaiJsonData;
        });
      }

      // 直接使用外部传入的B50数据
      if (widget.b50Data != null) {
        _updateB50Data(widget.b50Data!);
      } else {
        // 尝试加载缓存的Best50数据
        final best50Manager = UserBest50Manager();
        final cachedBest50Data = await best50Manager.getCachedBest50Data();

        if (cachedBest50Data != null) {
          _updateB50Data(cachedBest50Data);
        } else {
          // 尝试从用户游玩数据计算Best50（落雪数据源场景）
          await _calculateBest50FromPlayData();
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 从用户游玩数据计算Best50（落雪数据源场景）
  Future<void> _calculateBest50FromPlayData() async {
    try {
      final userPlayDataManager = UserPlayDataManager();
      final userPlayData = await userPlayDataManager.getCachedUserPlayData();

      if (userPlayData == null || userPlayData['records'] == null) {
        setState(() {
          _b50Data = null;
          _dxSongs = [];
          _sdSongs = [];
          _isLoading = false;
        });
        return;
      }

      final records = userPlayData['records'] as List;
      if (records.isEmpty) {
        setState(() {
          _b50Data = null;
          _dxSongs = [];
          _sdSongs = [];
          _isLoading = false;
        });
        return;
      }

      // 将records转换为RecordItem列表
      List<RecordItem> recordItems = records
          .map((item) => RecordItem.fromJson(item as Map<String, dynamic>))
          .toList();

      // 根据歌曲的is_new字段分组
      List<RecordItem> oldSongs = []; // is_new = false
      List<RecordItem> newSongs = []; // is_new = true

      for (var record in recordItems) {
        bool isNew = _isSongNew(record.songId);
        if (isNew) {
          newSongs.add(record);
        } else {
          oldSongs.add(record);
        }
      }

      // 按ra降序排序并取前N个
      oldSongs.sort((a, b) => b.ra.compareTo(a.ra));
      newSongs.sort((a, b) => b.ra.compareTo(a.ra));

      // Best35: is_new=false 的前35首
      List<RecordItem> best35 = oldSongs.take(35).toList();
      // Best15: is_new=true 的前15首
      List<RecordItem> best15 = newSongs.take(15).toList();

      // 计算总rating
      int totalRating = best35.fold(0, (sum, item) => sum + item.ra) +
          best15.fold(0, (sum, item) => sum + item.ra);

      // 转换为Map格式
      List<Map<String, dynamic>> sdSongsMap =
          best35.map((item) => item.toJson()).toList();
      List<Map<String, dynamic>> dxDongsMap =
          best15.map((item) => item.toJson()).toList();

      setState(() {
        _b50Data = {
          'rating': totalRating,
          'additional_rating': 0,
          'charts': {
            'sd': sdSongsMap,
            'dx': dxDongsMap,
          }
        };
        _sdSongs = sdSongsMap;
        _dxSongs = dxDongsMap;
        _isLoading = false;
      });

      _calculateTheoreticalBest50();
      _loadTagDataAndCalculateStats();

      debugPrint(
          '✅ 从游玩数据计算Best50完成: Best35=${best35.length}首, Best15=${best15.length}首, 总Rating=$totalRating');
    } catch (e) {
      debugPrint('Error calculating Best50 from play data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 根据歌曲ID判断是否为新曲（is_new=true）
  bool _isSongNew(int songId) {
    if (_maimaiMusicData == null) return false;

    try {
      // 使用 where() 和 firstWhereOrNull 替代 orElse 返回 null
      var song = _maimaiMusicData!.firstWhere(
        (item) => item['id'] == songId.toString(),
      );

      if (song['basic_info'] != null) {
        return song['basic_info']['is_new'] == true;
      }
    } catch (e) {
      // 歌曲未找到时返回 false
      debugPrint('Song $songId not found in music data');
    }

    return false;
  }

  void _updateB50Data(Map<String, dynamic> newData) {
    setState(() {
      _b50Data = newData;
      _dxSongs = newData['charts']?['dx'] != null
          ? List<Map<String, dynamic>>.from(newData['charts']['dx'])
          : [];
      _sdSongs = newData['charts']?['sd'] != null
          ? List<Map<String, dynamic>>.from(newData['charts']['sd'])
          : [];
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

    // 按ra降序排序
    newSongs.sort((a, b) => b['ra'].compareTo(a['ra']));
    oldSongs.sort((a, b) => b['ra'].compareTo(a['ra']));

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
      tagIdToGroupName[tag.id] = groupIdToNameMap[tag.groupId] ?? '未分类';
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

      int index =
          _maimaiMusicData!.indexWhere((m) => int.parse(m['id']) == songId);
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
          String tagName = tagIdToNameMap[tagId] ?? '未知标签';
          String groupName = tagIdToGroupName[tagId] ?? '未分类';

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
        title: 'Best50 查询',
        resizeToAvoidBottomInset: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_b50Data == null || (_dxSongs.isEmpty && _sdSongs.isEmpty)) {
      // 空状态与正常内容共用背景和顶部栏。
      return BackgroundPageScaffold(
        title: 'Best50 查询',
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
                '暂无Best50数据',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
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
        ),
      );
    }

    return BackgroundPageScaffold(
      title: _isTheoreticalMode ? '理论Rating Best50' : 'Best50查询',
      resizeToAvoidBottomInset: false,
      contentPadding:
          EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppDesignTokens.gutter, 8,
            AppDesignTokens.gutter, AppDesignTokens.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRatingSection(),
            SizedBox(height: 12.0),
            if (!_isTheoreticalMode) _buildTagStatsSection(context),
            if (!_isTheoreticalMode) SizedBox(height: 12.0),
            _buildActionButtons(),
            SizedBox(height: 12.0),
            _buildSectionTitle(
                _isTheoreticalMode
                    ? '理论Best35 | 非当前版本最高定数'
                    : 'Best35 | 非当前版本最好成绩',
                context),
            _buildDataCardGrid(
              _isTheoreticalMode ? _theoreticalSdSongs : _sdSongs,
              B50GameCardWidget.designAspectRatio,
              remainingInfo: _isTheoreticalMode ? _remainingSdSongsInfo : null,
            ),
            const SizedBox(height: AppDesignTokens.sectionGap - 12),
            _buildSectionTitle(
                _isTheoreticalMode
                    ? '理论Best15 | 当前版本最高定数'
                    : 'Best15 | 当前版本最好成绩',
                context),
            _buildDataCardGrid(
              _isTheoreticalMode ? _theoreticalDxSongs : _dxSongs,
              B50GameCardWidget.designAspectRatio,
              remainingInfo: _isTheoreticalMode ? _remainingDxSongsInfo : null,
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('账号数据已更新，请重新打开 Best50 后保存')));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Best50 记录已保存 ($dateStr)'),
            duration: Duration(seconds: 1)));
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
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.history,
                    size: 22, color: Theme.of(ctx).colorScheme.onSurface),
                SizedBox(width: 8),
                Text('Best50 历史记录'),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: _snapshots.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('暂无保存的记录，点击"保存当前记录"按钮保存',
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
                            borderRadius: BorderRadius.circular(8),
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
                                            fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text(s['date'] ?? '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Theme.of(ctx)
                                                .colorScheme
                                                .onSurfaceVariant),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final charts = s['charts'];
                                  setState(() {
                                    _b50Data = {
                                      'rating': s['rating'],
                                      'charts': charts
                                    };
                                    _sdSongs = List<Map<String, dynamic>>.from(
                                        charts['sd'] ?? []);
                                    _dxSongs = List<Map<String, dynamic>>.from(
                                        charts['dx'] ?? []);
                                  });
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
                  onPressed: () => Navigator.pop(ctx), child: Text('关闭')),
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
    double best35Average =
        currentSdSongs.isNotEmpty ? best35Sum / currentSdSongs.length : 0.0;

    int best15Sum =
        currentDxSongs.fold(0, (sum, song) => sum + ((song['ra'] ?? 0) as int));
    double best15Average =
        currentDxSongs.isNotEmpty ? best15Sum / currentDxSongs.length : 0.0;

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

    return Best50SummaryCard(
      label: _isTheoreticalMode ? '理论 Rating' : 'Rating',
      rating: rating,
      ratingAverage: ratingAverage,
      best35Sum: best35Sum,
      best35Average: best35Average,
      best15Sum: best15Sum,
      best15Average: best15Average,
      showTier: !_isTheoreticalMode,
      // 理论模式下平均值恒为 101% / 100%，不再单独列出
      averages: _isTheoreticalMode
          ? const []
          : [
              Best50AverageRow(
                  'B50', best50AchievementAverage, best50ScoreRateAverage),
              Best50AverageRow(
                  'B35', best35AchievementAverage, best35ScoreRateAverage),
              Best50AverageRow(
                  'B15', best15AchievementAverage, best15ScoreRateAverage),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: canExpand,
            expanded: canExpand ? _isTagStatsExpanded : null,
            label: '标签统计',
            child: InkWell(
              onTap: canExpand
                  ? () => setState(() {
                        _isTagStatsExpanded = !_isTagStatsExpanded;
                      })
                  : null,
              borderRadius:
                  BorderRadius.circular(AppDesignTokens.radiusSmall),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '标签统计',
                        style: TextStyle(
                          fontSize: 15,
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
                        '暂无标签数据',
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
                      padding: const EdgeInsets.only(top: 8.0),
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
                                groupName,
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
                                        tagEntry.key,
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

  Widget _buildSectionTitle(String title, BuildContext context) =>
      Best50SectionHeader(title);

  // 构建"查看剩余"卡片
  Widget _buildRemainingCard(Map<String, dynamic> remainingInfo) {
    final remainingBrightness = Theme.of(context).brightness;
    double ds = remainingInfo['ds'] ?? 0.0;
    int count = remainingInfo['count'] ?? 0;

    return AppCard(
      radius: AppDesignTokens.radiusSmall,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      onTap: () => _showRemainingSongsDialog(remainingInfo, ''),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.music_note,
                color: AppColors.linkBlue(remainingBrightness),
                size: MediaQuery.of(context).size.width * 0.06),
            SizedBox(height: 4.0),
            Text(
              '剩余$count首',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.03,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              ds.toStringAsFixed(1),
              style: AppTheme.number(
                fontSize: 13,
                color: AppColors.linkBlue(remainingBrightness),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示剩余歌曲对话框
  void _showRemainingSongsDialog(
      Map<String, dynamic> remainingInfo, String sectionName) {
    double ds = remainingInfo['ds'] ?? 0.0;
    List<Map<String, dynamic>> songs = remainingInfo['songs'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${sectionName}剩余谱面 (定数 ${ds.toStringAsFixed(1)})'),
        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: songs.length,
              itemBuilder: (context, index) {
                var song = songs[index];
                String difficultyLabel =
                    _getDifficultyLabel(song['level_index'] ?? 0);
                String type = song['type'] ?? '';
                bool isDxMode = type == 'DX';

                return ListTile(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  leading: CoverUtil.buildCoverWidgetWithContext(
                      context, song['song_id'].toString(), 50),
                  title: Row(
                    children: [
                      Text(
                        isDxMode ? 'DX' : 'ST',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          fontWeight: FontWeight.bold,
                          color: isDxMode
                              ? AppColors.warningOrange(
                                  Theme.of(context).brightness)
                              : AppColors.linkBlue(
                                  Theme.of(context).brightness),
                        ),
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          song['title'] ?? '未知歌曲',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                      '$difficultyLabel | ${song['ds']} | RA: ${song['ra']}'),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
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
    bool isFitDiff = false,
  }) {
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
      songId: songId ?? 0,
      starsColor: starsColor,
      maxIdLength: maxIdLength,
      // 字号按卡片**实际**宽度自适应（别拿屏幕宽度估：容器 padding / 网格间距
      // 都会从宽度里扣掉，估出来的值和真实格子差好几个百分点）。
      scale: B50GameCardWidget.autoScale,
      isFitDiff: isFitDiff,
    );
  }

  Widget _buildDataCardGrid(
      List<Map<String, dynamic>> songs, double childAspectRatio,
      {Map<String, dynamic>? remainingInfo}) {
    int itemCount = songs.length + (remainingInfo != null ? 1 : 0);
    // 按当前列表里实际最大 ID 位数作为占位宽度：无 6 位则严格用 5 位，5 位 ID 与 chip 之间不留空
    final int maxIdLength = songs.isEmpty
        ? 5
        : songs
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
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < songs.length) {
          return _buildDataGameCard(songs[index], maxIdLength: maxIdLength);
        } else {
          // 最后一个位置显示"查看剩余"卡片
          return _buildRemainingCard(remainingInfo!);
        }
      },
    );
  }

  Widget _buildDataGameCard(Map<String, dynamic> songData,
      {required int maxIdLength}) {
    double achievementRate = double.parse(songData['achievements'].toString());
    int score = songData['dxScore'];
    String fc = songData['fc'] ?? '';
    String fs = songData['fs'] ?? '';
    // 通过 ds 字符串的小数位数判断是否为拟合定数（>1 位小数视为拟合）
    String dsStr = songData['ds'].toString();
    int dotIdx = dsStr.indexOf('.');
    bool isFitDiff = dotIdx >= 0 && (dsStr.length - dotIdx - 1) > 1;
    double difficulty = double.parse(dsStr);
    String rate = songData['rate'];
    int levelIndex = songData['level_index'];
    int rating = songData['ra'];
    String type = songData['type'];
    String title = songData['title'];
    int songId = songData['song_id'];

    // 理论模式下使用固定值
    double scoreRate = _isTheoreticalMode
        ? 1.0
        : _calculateScoreRate(songId, levelIndex, score);
    String stars =
        _isTheoreticalMode ? '\u27266' : StringUtil.formatStars(scoreRate);
    Color starsColor =
        _isTheoreticalMode ? Colors.yellow : ColorUtil.getStarsColor(stars);

    Color cardColor;
    if (songId.toString().length == 6) {
      cardColor = AppColors.utageCard();
    } else {
      cardColor = ColorUtil.getCardColor(levelIndex);
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
        maxScore: _calculateMaxScore(songId, levelIndex),
        rating: rating,
        stars: stars,
        fc: fc,
        fs: fs,
        rate: rate,
        songId: songId,
        starsColor: starsColor,
        maxIdLength: maxIdLength,
        isFitDiff: isFitDiff,
      ),
    );
  }

  int _calculateMaxScore(int songId, int levelIndex) {
    if (_maimaiMusicData == null) return 0;
    int songIndex = _maimaiMusicData!.indexWhere(
      (item) => item['id'] == songId.toString(),
    );
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

  Widget _buildActionButtons() {
    const gap = AppDesignTokens.itemGap;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Best50ActionButton(
                icon: Icons.image_outlined,
                label: '导出为图片',
                primary: true,
                onPressed: () async {
                  debugPrint('=== EXPORT BUTTON CLICKED ===');
                  try {
                    await _exportToImage();
                  } catch (e) {
                    debugPrint('Error in export: $e');
                  }
                },
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Best50ActionButton(
                icon: _isTheoreticalMode
                    ? Icons.undo_rounded
                    : Icons.trending_up_rounded,
                label: _isTheoreticalMode ? '返回实际Best50' : '理论Rating B50',
                onPressed: _toggleTheoreticalMode,
              ),
            ),
          ],
        ),
        const SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: Best50ActionButton(
                icon: Icons.bookmark_add_outlined,
                label: '保存当前记录',
                onPressed: () => _saveSnapshot(),
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              child: Best50ActionButton(
                icon: Icons.history_rounded,
                label: '历史记录',
                onPressed: () async {
                  await _loadSnapshots();
                  _showSnapshotDialog();
                },
              ),
            ),
          ],
        ),
      ],
    );
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

      // Show quality selector first
      final estimatedPngSize = ImageEncodeUtil.estimatePngSize(
          songCount: 50, hasHeader: true, hasUserInfo: !_isTheoreticalMode);
      final quality = await ExportQualitySelector.show(
        context,
        estimatedPngSize: estimatedPngSize,
        exportingLabel: _isTheoreticalMode ? '拟合 Best50' : 'Best50',
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
        ),
      );
      if (quality == null) return; // user cancelled

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

      final file = await B50ConvertToImg.convertToImage(
        context,
        _b50Data,
        _isTheoreticalMode ? _theoreticalSdSongs : _sdSongs,
        _isTheoreticalMode ? _theoreticalDxSongs : _dxSongs,
        _maimaiMusicData,
        isTheoreticalMode: _isTheoreticalMode,
        jpegQuality: quality.jpegQuality,
        thunderMode: quality.thunderMode,
        thunderVertical: quality.thunderVertical,
      );

      // 先关闭"导出中"对话框
      Navigator.of(context, rootNavigator: true).pop();

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
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
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
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: Text('确定'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // 确保关闭任何打开的对话框
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('导出失败'),
          content: Text('图片导出失败：${e.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: Text('确定'),
            ),
          ],
        ),
      );
    }
  }
}
