import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:flutter/material.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import '../manager/DivingFish/UserPlayDataManager.dart';
import '../entity/DivingFish/Song.dart';

class UserScoreSearchService {
  // 单例模式
  static final UserScoreSearchService _instance = UserScoreSearchService._internal();
  factory UserScoreSearchService() => _instance;
  UserScoreSearchService._internal();

  // 从缓存获取用户游玩数据
  Future<Map<String, dynamic>?> getUserPlayData() async {
    final userPlayDataManager = UserPlayDataManager();
    return await userPlayDataManager.getCachedUserPlayData();
  }

  // 获取排序后的歌曲列表
  Future<List<dynamic>> getSortedSongs(Map<String, dynamic> userPlayData, String sortBy) async  {
    if (userPlayData.containsKey('records') && userPlayData['records'] is List) {
      List<dynamic> songs = List.from(userPlayData['records']);
      
      // 根据排序方式进行排序
      switch (sortBy) {
        case 'Rating':
          // 按 ra 降序排序
          songs.sort((a, b) => (b['ra'] ?? 0).compareTo(a['ra'] ?? 0));
          break;
        case '达成率':
          // 按 achievements 降序排序
          songs.sort((a, b) {
            double aAchievements = double.tryParse(a['achievements'].toString()) ?? 0;
            double bAchievements = double.tryParse(b['achievements'].toString()) ?? 0;
            return bAchievements.compareTo(aAchievements);
          });
          break;
        case '定数':
          // 按 ds 降序排序
          songs.sort((a, b) {
            double aDs = double.tryParse(a['ds'].toString()) ?? 0;
            double bDs = double.tryParse(b['ds'].toString()) ?? 0;
            return bDs.compareTo(aDs);
          });
          break;
        case 'DX分数达成率':
          // 初始化歌曲缓存
          await _initSongCache();
          
          // 先批量计算所有歌曲的DX达成率（异步）
          // 用Map存储 歌曲 -> 达成率，避免排序时重复计算
          Map<dynamic, double> dxRateMap = {};
          for (var song in songs) {
            double rate = await _calculateDXScoreRate(song);
            dxRateMap[song] = rate;
          }
          // 基于提前计算好的达成率同步排序
          songs.sort((a, b) {
            double aRate = dxRateMap[a] ?? 0;
            double bRate = dxRateMap[b] ?? 0;
            return bRate.compareTo(aRate); // 降序排序
          });
          break;
        default:
          // 默认按 ra 降序排序
          songs.sort((a, b) => (b['ra'] ?? 0).compareTo(a['ra'] ?? 0));
      }
      
      return songs;
    }
    return [];
  }
  
  // 缓存变量
  List<Song>? _cachedSongs;

  // 初始化歌曲缓存（公共方法）
  Future<void> initSongCache() async {
    if (_cachedSongs == null) {
      final manager = MaimaiMusicDataManager();
      if (await manager.hasCachedData()) {
        _cachedSongs = await manager.getCachedSongs();
        debugPrint('缓存初始化成功，共 ${_cachedSongs?.length ?? 0} 首歌曲');
      } else {
        debugPrint('无缓存数据，尝试从API获取...');
        // 尝试从API获取数据
        bool success = await manager.fetchAndUpdateMusicData();
        if (success) {
          _cachedSongs = await manager.getCachedSongs();
          debugPrint('从API获取数据成功，共 ${_cachedSongs?.length ?? 0} 首歌曲');
        } else {
          debugPrint('从API获取数据失败');
        }
      }
    }
  }

  // 初始化歌曲缓存（私有方法）
  Future<void> _initSongCache() async {
    await initSongCache();
  }

  // 计算DX分数达成率（私有方法）
  Future<double> _calculateDXScoreRate(dynamic record) async {
    if (record == null) return 0.0;
    
    // 获取DX分
    int dxScore = int.tryParse(record['dxScore'].toString()) ?? 0;

    // 获取歌曲ID和难度索引
    String songId = record['song_id'].toString();
    int levelIndex = int.tryParse(record['level_index'].toString()) ?? 0;
    
    // 计算最大DX分 (根据notes总和 * 3)
    int maxScore = 0;

    // 尝试从缓存获取notes信息
    try {
      // 初始化缓存
      await _initSongCache();
      
      if (_cachedSongs != null && _cachedSongs!.isNotEmpty) {
        // 查找对应乐曲
        var song = _cachedSongs!.where((s) => s.id == songId).firstOrNull;
        // 如果找到歌曲
        if (song != null) {
          // 检查ds数组长度
          if (song.ds.length == 2) {
            // 对于ds数组长度为2的特殊歌曲，计算两个难度谱面的最大分数之和
            if (song.charts.length >= 2) {
              // 计算第一个难度谱面的最大分数
              var chart1 = song.charts[0];
              int notesSum1 = chart1.notes.fold(0, (sum, note) => sum + note);
              int maxScore1 = notesSum1 * 3;
              
              // 计算第二个难度谱面的最大分数
              var chart2 = song.charts[1];
              int notesSum2 = chart2.notes.fold(0, (sum, note) => sum + note);
              int maxScore2 = notesSum2 * 3;
              
              // 总最大分数为两个难度谱面的最大分数之和
              maxScore = maxScore1 + maxScore2;
                                    }
          } else if (levelIndex >= 0 && levelIndex < song.charts.length) {
            // 对于普通歌曲，使用当前难度的最大分数
            // 获取对应难度的charts
            var chart = song.charts[levelIndex];
            // 计算notes总和
            int notesSum = chart.notes.fold(0, (sum, note) => sum + note);
            maxScore = notesSum * 3;
                    }
        } else {
          debugPrint('未找到歌曲: $songId');
        }
      } else {
        debugPrint('缓存未初始化或为空');
      }
    } catch (e) {
      debugPrint('从缓存获取notes信息时出错: $e');
    }
    // 计算DX分数达成率
    double rate = maxScore > 0 ? dxScore / maxScore : 0.0;
    // 仅在调试模式下打印
    // debugPrint('计算DX分数达成率: songId=$songId, levelIndex=$levelIndex, dxScore=$dxScore, maxScore=$maxScore, rate=$rate');
    return rate;
  }
  
  // 计算DX分数达成率（公共方法）
  Future<double> calculateDXScoreRate(dynamic record) async {
    return await _calculateDXScoreRate(record);
  }

  // 计算DX分数达成率（同步公共方法）
  double calculateDXScoreRateSync(dynamic record) {
    final maxScore = calculateMaxScoreSync(record);
    int dxScore = int.tryParse(record['dxScore'].toString()) ?? 0;
    return maxScore > 0 ? dxScore / maxScore : 0.0;
  }

  // 计算最大DX分（同步公共方法）：根据 notes 总和 * 3 得到满分。
  // 与 calculateDXScoreRateSync 共享同一份缓存逻辑，单独抽出来供 UI 卡片直接展示分数/满分。
  int calculateMaxScoreSync(dynamic record) {
    if (record == null) return 0;
    final String songId = record['song_id'].toString();
    final int levelIndex =
        int.tryParse(record['level_index'].toString()) ?? 0;

    try {
      if (_cachedSongs != null && _cachedSongs!.isNotEmpty) {
        final song =
            _cachedSongs!.where((s) => s.id == songId).firstOrNull;
        if (song != null) {
          if (song.ds.length == 2) {
            if (song.charts.length >= 2) {
              int maxScore1 = song.charts[0].notes.fold(0, (sum, n) => sum + n) * 3;
              int maxScore2 = song.charts[1].notes.fold(0, (sum, n) => sum + n) * 3;
              return maxScore1 + maxScore2;
            }
          } else if (levelIndex >= 0 && levelIndex < song.charts.length) {
            int notesSum =
                song.charts[levelIndex].notes.fold(0, (sum, n) => sum + n);
            return notesSum * 3;
          }
        }
      }
    } catch (e) {
      debugPrint('计算最大DX分时出错: $e');
    }
    return 0;
  }

  // 分页获取歌曲数据
  List<dynamic> getPagedSongs(List<dynamic> songs, int page, int pageSize) {
    int startIndex = (page - 1) * pageSize;
    int endIndex = startIndex + pageSize;
    if (startIndex >= songs.length) {
      return [];
    }
    if (endIndex > songs.length) {
      endIndex = songs.length;
    }
    return songs.sublist(startIndex, endIndex);
  }
  
  /// 连击 / 同步筛选项对应的成绩字段值（空串表示没有该评价）。
  static const Map<String, String> comboFilterValues = {
    '无连击': '',
    'FC': 'fc',
    'FC+': 'fcp',
    'AP': 'ap',
    'AP+': 'app',
  };
  static const Map<String, String> syncFilterValues = {
    '无同步': '',
    'SYNC': 'sync',
    'FS': 'fs',
    'FS+': 'fsp',
    'FDX': 'fsd',
    'FDX+': 'fsdp',
  };

  static bool _inAnyRange(
      double value, List<String> ranges, double defaultMin, double defaultMax) {
    return ranges.any((range) {
      final parts = range.split('-');
      if (parts.length != 2) return true;
      final min = double.tryParse(parts[0]) ?? defaultMin;
      final max = double.tryParse(parts[1]) ?? defaultMax;
      return value >= min && value <= max;
    });
  }

  static bool _matchesDifficulty(dynamic song, String difficulty) {
    final songId = song['song_id'].toString();
    final isUtage = songId.length == 6 && int.tryParse(songId) != null;
    if (difficulty == ChartDifficulty.utageLabel) return isUtage;
    final levelIndex = ChartDifficulty.standardIndexByLabel[difficulty];
    if (levelIndex == null) return true;
    if (song['level_index'] != levelIndex) return false;
    // 选择 BASIC 时，过滤掉 ID 为 6 位数的歌曲
    return !(difficulty == ChartDifficulty.basicLabel && isUtage);
  }

  /// 筛选歌曲。同一条件内多选取并集（满足任意一项），不同条件之间取交集。
  /// 连击和同步是两个维度，分开取并集后再取交集，例如「AP + FDX」。
  Future<List<dynamic>> filterSongs(
      List<dynamic> songs, Map<String, List<String>> filterConditions) async {
    // 初始化缓存
    await _initSongCache();
    final versions = filterConditions['版本筛选'] ?? const <String>[];
    final dsRanges = filterConditions['定数筛选'] ?? const <String>[];
    final difficulties = filterConditions['难度筛选'] ?? const <String>[];
    final achievementRanges = filterConditions['达成率筛选'] ?? const <String>[];
    final combos = filterConditions['连击/同步筛选'] ?? const <String>[];
    final fcValues = {
      for (final item in combos)
        if (comboFilterValues[item] case final value?) value,
    };
    final fsValues = {
      for (final item in combos)
        if (syncFilterValues[item] case final value?) value,
    };

    return songs.where((song) {
      // 版本筛选：从缓存的音乐数据中获取版本信息
      if (versions.isNotEmpty) {
        final songId = song['song_id'].toString();
        final found = _cachedSongs?.where((s) => s.id == songId).firstOrNull;
        if (found == null ||
            found.isExtra ||
            !versions.contains(found.basicInfo.from)) {
          return false;
        }
      }

      if (dsRanges.isNotEmpty &&
          !_inAnyRange(double.tryParse(song['ds'].toString()) ?? 0, dsRanges,
              1.0, 15.0)) {
        return false;
      }

      if (difficulties.isNotEmpty &&
          !difficulties.any((item) => _matchesDifficulty(song, item))) {
        return false;
      }

      if (achievementRanges.isNotEmpty &&
          !_inAnyRange(double.tryParse(song['achievements'].toString()) ?? 0,
              achievementRanges, 0, 101)) {
        return false;
      }

      if (fcValues.isNotEmpty &&
          !fcValues.contains(song['fc']?.toString().toLowerCase() ?? '')) {
        return false;
      }
      if (fsValues.isNotEmpty &&
          !fsValues.contains(song['fs']?.toString().toLowerCase() ?? '')) {
        return false;
      }
      return true;
    }).toList();
  }

  // 根据 level_index 获取对应的颜色
  Color getBorderColor(int levelIndex) {
    switch (levelIndex) {
      case ChartDifficulty.basic: // BASIC
        return Colors.green;
      case ChartDifficulty.advanced: // ADVANCED
        return Colors.yellow;
      case ChartDifficulty.expert: // EXPERT
        return Colors.red;
      case ChartDifficulty.master: // MASTER
        return Colors.purple.shade400;
      case ChartDifficulty.reMaster: // Re:MASTER
        return Colors.purple.shade200; 
      default:
        return Colors.grey;
    }
  }
}