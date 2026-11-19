import 'dart:convert' show utf8, jsonDecode, jsonEncode;
import 'package:flutter/foundation.dart';
import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/entity/SongAliasModel.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';

/// yuzuchan 回退开关：只在 AWMC 两路别名都失败时才请求 yuzuchan。
///
/// 数据已整体换到 AWMC，这里保留一个发布周期兜底；确认线上稳定后，
/// 连同 [SongAliasManager._fetchFromSongAliasApi] 和 [ApiUrls.SongAliasApi] 一起删除。
const bool useYuzuchanAliasFallback = true;

class SongAliasManager {
  // 单例模式，全局唯一实例
  static final SongAliasManager instance = SongAliasManager._internal();
  SongAliasManager._internal();

  // 本地缓存的key（沿用旧键，历史缓存仍可读）
  static const _keyAliases = 'song_aliases';
  static const _keyLastUpdate = 'alias_last_update';

  // 内存中缓存的别名数据：key=歌曲名(String)，value=别名列表
  //
  // AWMC 两路接口都按曲目 id 返回，合并时先按 baseSongId（DX 去 10000、宴原样）
  // 归并去重，再经本地曲库的 id → 曲名映射转成曲名键——调用方一律按
  // `aliases[song.title]` 取值，对外形态不变。
  Map<String, List<String>> _aliases = {};

  /// 数据版本：网络刷新成功后自增，用来淘汰迟到的本地缓存解析。
  int _revision = 0;

  /// 正在进行的刷新任务，HomePage 与 HomeService 同时 init 时复用同一次请求。
  Future<bool>? _refreshFuture;

  // 对外暴露的别名数据（只读）
  Map<String, List<String>> get aliases => _aliases;

  /// 初始化方法：APP启动时调用
  Future<void> init() async {
    // 先从本地加载缓存
    await _loadFromLocal();
    debugPrint('SongAliasManager初始化完成，当前缓存${_aliases.length}首歌曲的别名');

    // 检查是否超过7天未更新，超过则后台自动刷新（不阻塞初始化流程）
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateTime = prefs.getInt(_keyLastUpdate) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const sevenDays = 7 * 24 * 60 * 60 * 1000;

    if (now - lastUpdateTime > sevenDays) {
      debugPrint('别名缓存已过期（超过7天），开始后台自动刷新...');
      // 不阻塞 init 完成，别名在后台异步更新
      fetchFromApi().then((_) {
        debugPrint('别名后台刷新完成');
      });
    } else {
      debugPrint(
          '别名缓存未过期，上次更新时间: ${DateTime.fromMillisecondsSinceEpoch(lastUpdateTime)}');
    }
  }

  /// 从本地缓存加载别名数据
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyAliases);
    final aliasesAtStart = _aliases;
    final revisionAtStart = _revision;

    if (jsonString != null) {
      try {
        // 冷启动时别名可能有数千条，解析与列表转换一起放到后台，避免阻塞首页动画。
        final aliases = await compute(_decodeAliases, jsonString);
        // 解析期间若接口已经返回新数据，旧缓存不能再覆盖它。
        if (revisionAtStart == _revision && identical(_aliases, aliasesAtStart)) {
          _aliases = aliases;
        }
      } catch (e) {
        // 缓存解析失败则清空，避免脏数据
        if (revisionAtStart == _revision && identical(_aliases, aliasesAtStart)) {
          _aliases = {};
        }
        debugPrint('本地别名缓存解析失败：$e');
      }
    }
  }

  static Map<String, List<String>> _decodeAliases(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  /// 获取最新别名：AWMC 主接口 → AWMC 社区全量 → （开关打开时）yuzuchan。
  ///
  /// 并发的重复调用复用同一次请求，避免首页与后台初始化各拉一遍。
  Future<bool> fetchFromApi() {
    final active = _refreshFuture;
    if (active != null) return active;
    final future = _fetchFromApiOnce();
    _refreshFuture = future;
    future.whenComplete(() {
      if (identical(_refreshFuture, future)) _refreshFuture = null;
    });
    return future;
  }

  Future<bool> _fetchFromApiOnce() async {
    try {
      // 曲库可能还没加载完：先等它给出 id → 曲名映射，再决定是否请求。
      final idToTitle = await _buildBaseIdToTitle();
      // 曲库没就绪时不要改用 yuzuchan：它一成功就写入 alias_last_update，
      // 之后曲库就绪时 HomeService 的 init 会以为缓存仍新鲜而不再重试 AWMC。
      if (idToTitle.isEmpty) {
        debugPrint('曲库尚未就绪，本次跳过别名刷新');
        return false;
      }
      final revision = _revision;
      var newAliases = await _loadAwmcAliases(idToTitle);
      if ((newAliases == null || newAliases.isEmpty) &&
          useYuzuchanAliasFallback) {
        debugPrint('AWMC 别名不可用，回退 yuzuchan');
        newAliases = await _fetchFromSongAliasApi();
      }

      // 只有在成功获取到新数据时才更新缓存，否则保留原有数据
      if (newAliases == null || newAliases.isEmpty) {
        debugPrint('未获取到新的别名数据，保留原有缓存');
        return false;
      }

      // 更新内存数据（并让还在解析的旧缓存知道已被超越）
      if (revision != _revision) return false;
      _aliases = newAliases;
      _revision++;

      // 保存到本地缓存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAliases, jsonEncode(_aliases));
      await prefs.setInt(_keyLastUpdate, DateTime.now().millisecondsSinceEpoch);

      debugPrint('别名数据更新成功，共加载${_aliases.length}首歌曲的别名');
      return true;
    } catch (e) {
      // 捕获所有异常，避免崩溃，继续使用旧缓存
      debugPrint('获取别名API异常：$e');
      return false;
    }
  }

  /// 先请求 AWMC 主别名接口，落败再退到社区全量别名，仍为空则返回 null。
  Future<Map<String, List<String>>?> _loadAwmcAliases(
    Map<int, String> idToTitle,
  ) async {
    final bundle = await _fetchFromAwmcMaimaidxAlias() ??
        await _fetchFromAwmcCommunityAliases();
    if (bundle == null) return null;
    final byTitle = _mapToTitles(bundle, idToTitle);
    return byTitle.isEmpty ? null : byTitle;
  }

  /// AWMC 主别名接口：目录自带别名 + 社区 approved，记录含曲目 id 与别名数组。
  ///
  /// 解析容忍字符串 id、`null` 字段，以及 content 为「曲名 → 别名列表」的旧形态。
  Future<_AliasBundle?> _fetchFromAwmcMaimaidxAlias() async {
    try {
      final token = ApiUrls.AwmcAliasToken;
      final response = await ApiClient.get(
        Uri.parse(ApiUrls.AwmcMaimaidxAliasApi),
        headers: token.isEmpty ? null : {'X-Alias-Token': token},
      );
      if (response.statusCode != 200) {
        debugPrint('AWMC 主别名接口请求失败，状态码=${response.statusCode}');
        return null;
      }

      final dynamic jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonData is! Map) {
        debugPrint('AWMC 主别名接口格式异常，类型: ${jsonData.runtimeType}');
        return null;
      }
      final code = _asInt(jsonData['code']);
      if (code != null && code != 0) {
        debugPrint('AWMC 主别名接口返回失败，code=$code');
        return null;
      }

      final bundle = _AliasBundle();
      final dynamic content = jsonData['content'];
      if (content is List) {
        for (final entry in content) {
          if (entry is! Map) continue;
          // 该接口的 SongID 是谱面文件 id（DX 为 曲号 +10000，如 12025 是
          // 曲号 2025 的 DX 谱），必须归一成基础曲号后再挂曲名。
          final baseId = _toBaseSongId(_asInt(
            entry['SongID'] ??
                entry['songId'] ??
                entry['song_id'] ??
                entry['id'],
          ));
          if (baseId == null) continue;
          bundle.addBaseAliases(
            baseId,
            _asStrings(entry['Alias'] ?? entry['alias'] ?? entry['aliases']),
          );
        }
      } else if (content is Map) {
        content.forEach((title, value) {
          if (title is! String) return;
          bundle.addTitleAliases(title, _asStrings(value));
        });
      } else {
        debugPrint('AWMC 主别名接口缺少 content 字段');
        return null;
      }

      if (bundle.isEmpty) {
        debugPrint('AWMC 主别名接口未解析出别名');
        return null;
      }
      debugPrint('AWMC 主别名接口解析到${bundle.byBaseId.length}个 baseSongId、'
          '${bundle.byTitle.length}个曲名');
      return bundle;
    } catch (e) {
      debugPrint('获取 AWMC 主别名接口异常：$e');
      return null;
    }
  }

  /// AWMC 社区全量别名：`{ items: [{ songId, baseSongId?, text }] }`。
  ///
  /// 同一 baseSongId 会对应多个谱面和多条别名，按 baseSongId 合并去重。
  Future<_AliasBundle?> _fetchFromAwmcCommunityAliases() async {
    try {
      final response =
          await ApiClient.get(Uri.parse(ApiUrls.AwmcCommunityAliasesApi));
      if (response.statusCode != 200) {
        debugPrint('AWMC 社区别名接口请求失败，状态码=${response.statusCode}');
        return null;
      }

      final dynamic jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic rawItems = jsonData is Map ? jsonData['items'] : jsonData;
      if (rawItems is! List) {
        debugPrint('AWMC 社区别名接口格式异常，类型: ${jsonData.runtimeType}');
        return null;
      }

      final bundle = _AliasBundle();
      for (final entry in rawItems) {
        if (entry is! Map) continue;
        // baseSongId 已是基础曲号，直接用；只有缺字段时才把 songId 归一。
        final explicitBase = _asInt(entry['baseSongId']);
        final baseId = explicitBase ??
            _toBaseSongId(_asInt(entry['baseSongId'] ?? entry['songId']));
        if (baseId == null) continue;
        bundle.addBaseAliases(
          baseId,
          _asStrings(entry['text'] ?? entry['alias'] ?? entry['aliases']),
        );
      }

      if (bundle.isEmpty) {
        debugPrint('AWMC 社区别名接口未解析出别名');
        return null;
      }
      debugPrint('AWMC 社区别名接口解析到${bundle.byBaseId.length}个 baseSongId');
      return bundle;
    } catch (e) {
      debugPrint('获取 AWMC 社区别名接口异常：$e');
      return null;
    }
  }

  /// 建立 baseSongId → 曲名映射。
  ///
  /// 曲库可能仍在加载，先等它就绪（最多 10 秒）；仍为空就只能等下一次刷新。
  Future<Map<int, String>> _buildBaseIdToTitle() async {
    final songs = await _loadSongsForIndex();
    final idToTitle = <int, String>{};
    for (final song in songs) {
      final rawId = int.tryParse(song.id);
      // 曲库的 id 是谱面文件 id：DX 条目才有 +10000。不能只按数值区间归一，
      // 否则 ST 的 5 位新曲号（如 12025）会被错减成 2025。
      final baseId = rawIdToBase(rawId, song.type);
      // 键保留曲库里的原始标题，调用方就是按 `aliases[song.title]` 取的
      final title = song.title;
      if (baseId == null || title.trim().isEmpty) continue;
      // 同一 baseSongId 的 ST / DX 谱面共用曲名，只留第一条
      idToTitle.putIfAbsent(baseId, () => title);
    }
    if (idToTitle.isEmpty) debugPrint('曲库尚未就绪，暂不刷新别名');
    return idToTitle;
  }

  Future<List<Song>> _loadSongsForIndex() async {
    final manager = MaimaiMusicDataManager();
    // 首页提前 init 时曲库通常还没好，等 3 秒即可；真正的重试由 HomeService
    // 在曲库 Future.wait 之后的那次 init 负责，不必在这里空转 10 秒。
    for (var attempt = 0;; attempt++) {
      final songs = await manager.getCachedSongs();
      if (songs != null && songs.isNotEmpty) return songs;
      if (attempt >= 5) return const <Song>[];
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  /// 把按 baseSongId / 曲名收集的别名转成对外的曲名键，并按曲名去重。
  Map<String, List<String>> _mapToTitles(
    _AliasBundle bundle,
    Map<int, String> idToTitle,
  ) {
    final result = <String, List<String>>{};
    var skipped = 0;

    bundle.byTitle.forEach((title, aliases) {
      _appendAliases(result, title, aliases);
    });
    bundle.byBaseId.forEach((baseId, aliases) {
      final title = idToTitle[baseId];
      if (title == null) {
        skipped++;
        return;
      }
      _appendAliases(result, title, aliases);
    });

    if (skipped > 0) {
      debugPrint('$skipped个 baseSongId 在本地曲库里找不到曲名，已跳过');
    }
    return result;
  }

  void _appendAliases(
    Map<String, List<String>> target,
    String title,
    Iterable<String> aliases,
  ) {
    if (aliases.isEmpty) return;
    final list = target.putIfAbsent(title, () => <String>[]);
    for (final raw in aliases) {
      final alias = raw.trim();
      if (alias.isEmpty || alias == title || list.contains(alias)) continue;
      list.add(alias);
    }
    if (list.isEmpty) target.remove(title);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static Iterable<String> _asStrings(dynamic value) sync* {
    if (value is String) {
      yield value;
      return;
    }
    if (value is List) {
      for (final item in value) {
        if (item is String) yield item;
      }
    }
  }

  /// 按 AWMC 语义归一曲目 id：DX（10000–99999）去掉 10000，6 位宴谱与普通谱原样。
  static int? _toBaseSongId(int? songId) {
    if (songId == null) return null;
    if (songId >= 10000 && songId < 100000) return songId - 10000;
    return songId;
  }

  /// 曲库条目用明确的 `type` 判断：只有 DX 条目才减 10000，ST 条目即使 5 位也原样。
  static int? rawIdToBase(int? chartFileId, String type) {
    if (chartFileId == null) return null;
    if (type == 'DX' && chartFileId >= 10000 && chartFileId < 100000) {
      return chartFileId - 10000;
    }
    return chartFileId;
  }

  /// 从 yuzuchan 获取别名数据（临时回退源，返回曲名键）。
  Future<Map<String, List<String>>?> _fetchFromSongAliasApi() async {
    try {
      final url = ApiUrls.SongAliasApi;
      final response = await ApiClient.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);
        final aliasResponse = SongAliasResponse.fromJson(jsonData);

        if (aliasResponse.code == 0) {
          Map<String, List<String>> newAliases = {};
          for (var song in aliasResponse.content) {
            String songName = song.name;

            List<String> aliases = song.alias.map((alias) => alias).toList();

            newAliases[songName] = aliases;
          }
          debugPrint('成功从SongAliasApi加载${aliasResponse.content.length}首歌曲的别名');
          return newAliases;
        } else {
          debugPrint('SongAliasApi接口返回失败，code=${aliasResponse.code}');
        }
      } else {
        debugPrint('SongAliasApi请求失败，状态码=${response.statusCode}');
      }
    } catch (e) {
      debugPrint('获取SongAliasApi异常：$e');
    }
    return null;
  }

  /// 手动刷新别名（供按钮点击调用）
  Future<bool> refresh({bool forceNetwork = false}) async {
    if (!forceNetwork && await _isCacheValid()) {
      debugPrint('别名缓存有效，跳过网络刷新');
      return true;
    }
    return fetchFromApi();
  }

  Future<bool> _isCacheValid(
      {Duration maxAge = const Duration(days: 7)}) async {
    if (_aliases.isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastUpdateTime = prefs.getInt(_keyLastUpdate);
    if (lastUpdateTime == null) return false;
    return DateTime.now().millisecondsSinceEpoch - lastUpdateTime <=
        maxAge.inMilliseconds;
  }

  /// 根据用户输入的别名查找对应的歌曲名（忽略大小写）
  String? findSongNameByAlias(String input) {
    if (input.isEmpty) return null;
    final lowerInput = input.toLowerCase();

    for (final entry in _aliases.entries) {
      final songName = entry.key;
      final aliasList = entry.value;

      // 遍历别名列表，忽略大小写匹配
      if (aliasList.any((alias) => alias.toLowerCase() == lowerInput)) {
        return songName;
      }
    }
    return null; // 未找到对应歌曲名
  }

  /// 根据用户输入的歌曲名查找对应的别名列表
  List<String>? findAliasesBySongName(String songName) {
    return _aliases[songName];
  }
}

/// 单次接口解析结果：按 baseSongId 与按曲名两种索引。
///
/// 同一 baseSongId 的多个谱面会落到同一个集合里，天然完成别名去重。
class _AliasBundle {
  final Map<int, Set<String>> byBaseId = {};
  final Map<String, Set<String>> byTitle = {};

  bool get isEmpty => byBaseId.isEmpty && byTitle.isEmpty;

  void addBaseAliases(int baseId, Iterable<String> aliases) {
    final set = byBaseId.putIfAbsent(baseId, () => <String>{});
    for (final alias in aliases) {
      if (alias.trim().isNotEmpty) set.add(alias);
    }
    if (set.isEmpty) byBaseId.remove(baseId);
  }

  void addTitleAliases(String title, Iterable<String> aliases) {
    final set = byTitle.putIfAbsent(title, () => <String>{});
    for (final alias in aliases) {
      if (alias.trim().isNotEmpty) set.add(alias);
    }
    if (set.isEmpty) byTitle.remove(title);
  }
}
