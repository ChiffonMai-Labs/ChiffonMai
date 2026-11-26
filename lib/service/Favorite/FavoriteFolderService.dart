import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../entity/Favorite/FavoriteFolder.dart';

/// 收藏夹服务：管理收藏夹的增删改查，数据持久化到 SharedPreferences
class FavoriteFolderService {
  static final FavoriteFolderService _instance = FavoriteFolderService._internal();
  factory FavoriteFolderService() => _instance;
  FavoriteFolderService._internal();

  static const String _storageKey = 'favorite_folders_data';

  List<FavoriteFolder> _folders = [];
  bool _loaded = false;

  /// 丢弃内存里的收藏夹副本，下次读取时重新从 prefs 载入。
  ///
  /// 给「导入备份」用：保存是整体写回（[_saveFolders] 写整个列表），
  /// 恢复后若内存里还留着旧列表，下一次改动就会把恢复内容整体覆盖掉。
  void invalidateCache() {
    _folders = [];
    _loaded = false;
  }

  /// 从本地加载所有收藏夹
  Future<List<FavoriteFolder>> loadFolders() async {
    if (_loaded) return List.unmodifiable(_folders);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonStr) as List<dynamic>;
        _folders = jsonList
            .map((e) => FavoriteFolder.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _folders = [];
      }
      _loaded = true;
    } catch (e) {
      debugPrint('加载收藏夹数据失败: $e');
      _folders = [];
    }
    return List.unmodifiable(_folders);
  }

  /// 保存所有收藏夹到本地
  Future<void> _saveFolders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(_folders.map((f) => f.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('保存收藏夹数据失败: $e');
    }
  }

  /// 获取所有收藏夹
  Future<List<FavoriteFolder>> getFolders() async {
    if (!_loaded) {
      await loadFolders();
    }
    return List.unmodifiable(_folders);
  }

  /// 根据ID获取收藏夹
  Future<FavoriteFolder?> getFolderById(String id) async {
    if (!_loaded) await loadFolders();
    try {
      return _folders.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 创建收藏夹
  Future<FavoriteFolder> createFolder(String name) async {
    if (!_loaded) await loadFolders();
    final folder = FavoriteFolder(name: name);
    _folders.add(folder);
    await _saveFolders();
    return folder;
  }

  /// 重命名收藏夹
  Future<bool> renameFolder(String id, String newName) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == id);
      folder.name = newName;
      folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveFolders();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 删除收藏夹
  Future<bool> deleteFolder(String id) async {
    if (!_loaded) await loadFolders();
    final before = _folders.length;
    _folders.removeWhere((f) => f.id == id);
    if (_folders.length < before) {
      await _saveFolders();
      return true;
    }
    return false;
  }

  /// 向收藏夹中添加谱面
  /// [folderId] 收藏夹ID
  /// [chart] 要添加的谱面
  /// 返回 true 表示添加成功，false 表示该谱面已在收藏夹中
  Future<bool> addChartToFolder(String folderId, FavoriteChart chart) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      // 检查是否已存在
      final exists = folder.charts.any((c) => c.uniqueKey == chart.uniqueKey);
      if (exists) return false;
      folder.charts.add(chart);
      folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveFolders();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 从收藏夹中移除谱面
  Future<bool> removeChartFromFolder(String folderId, String uniqueKey) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      final before = folder.charts.length;
      folder.charts.removeWhere((c) => c.uniqueKey == uniqueKey);
      if (folder.charts.length < before) {
        folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveFolders();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 将谱面同时添加到多个收藏夹
  /// 返回成功添加到的收藏夹数量
  Future<int> addChartToMultipleFolders(
      List<String> folderIds, FavoriteChart chart) async {
    if (!_loaded) await loadFolders();
    int successCount = 0;
    for (final folderId in folderIds) {
      final added = await addChartToFolder(folderId, chart);
      if (added) successCount++;
    }
    return successCount;
  }

  /// 查找某个谱面存在于哪些收藏夹中
  /// 返回收藏夹ID列表
  Future<List<String>> findFoldersContainingChart(String uniqueKey) async {
    if (!_loaded) await loadFolders();
    final List<String> result = [];
    for (final folder in _folders) {
      final exists = folder.charts.any((c) => c.uniqueKey == uniqueKey);
      if (exists) {
        result.add(folder.id);
      }
    }
    return result;
  }

  /// 获取某个收藏夹中的所有谱面
  Future<List<FavoriteChart>> getChartsInFolder(String folderId) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      return List.unmodifiable(folder.charts);
    } catch (_) {
      return [];
    }
  }

  /// 批量从收藏夹中移除谱面
  /// 返回实际移除的数量
  Future<int> removeChartsFromFolder(
      String folderId, List<String> uniqueKeys) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      final before = folder.charts.length;
      folder.charts.removeWhere((c) => uniqueKeys.contains(c.uniqueKey));
      final removed = before - folder.charts.length;
      if (removed > 0) {
        folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveFolders();
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  /// 批量将谱面从一个收藏夹移动到另一个
  /// 返回成功移动的数量
  Future<int> moveChartsBetweenFolders(
      String sourceId, String targetId, List<String> uniqueKeys) async {
    if (!_loaded) await loadFolders();
    if (sourceId == targetId) return 0;
    try {
      final source = _folders.firstWhere((f) => f.id == sourceId);
      final target = _folders.firstWhere((f) => f.id == targetId);
      int moved = 0;
      final chartsToMove = source.charts
          .where((c) => uniqueKeys.contains(c.uniqueKey))
          .toList();
      for (final chart in chartsToMove) {
        final exists = target.charts.any((c) => c.uniqueKey == chart.uniqueKey);
        if (!exists) {
          target.charts.add(chart);
          moved++;
        }
      }
      if (moved > 0) {
        source.charts.removeWhere((c) => uniqueKeys.contains(c.uniqueKey));
        source.updatedAt = DateTime.now().millisecondsSinceEpoch;
        target.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveFolders();
      }
      return moved;
    } catch (_) {
      return 0;
    }
  }

  /// 更新收藏夹中谱面的成绩信息
  Future<void> updateChartAchievement(
      String folderId, String uniqueKey, double? achievement, int? playCount) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      final idx = folder.charts.indexWhere((c) => c.uniqueKey == uniqueKey);
      if (idx >= 0) {
        folder.charts[idx] = folder.charts[idx].copyWith(
          achievement: achievement,
          playCount: playCount,
        );
        folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveFolders();
      }
    } catch (_) {
      // 静默失败
    }
  }

  /// 对谱面列表排序
  List<FavoriteChart> sortCharts(
      List<FavoriteChart> charts, FavoriteSortOption sortBy) {
    final sorted = List<FavoriteChart>.from(charts);
    switch (sortBy) {
      case FavoriteSortOption.byDsDesc:
        sorted.sort((a, b) => b.ds.compareTo(a.ds));
        break;
      case FavoriteSortOption.byDsAsc:
        sorted.sort((a, b) => a.ds.compareTo(b.ds));
        break;
      case FavoriteSortOption.byDateNewest:
        sorted.sort((a, b) => b.addedAt.compareTo(a.addedAt));
        break;
      case FavoriteSortOption.byDateOldest:
        sorted.sort((a, b) => a.addedAt.compareTo(b.addedAt));
        break;
      case FavoriteSortOption.byTitle:
        sorted.sort((a, b) => a.songTitle
            .toLowerCase()
            .compareTo(b.songTitle.toLowerCase()));
        break;
      case FavoriteSortOption.custom:
        // 保留谱面列表的存储顺序
        break;
    }
    return sorted;
  }

  /// 按 ReorderableListView 语义（向下拖拽时 newIndex 含被移除项占位）重排列表
  bool _reorderList<T>(List<T> list, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= list.length) return false;
    var targetIndex = newIndex;
    if (oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    if (targetIndex < 0 ||
        targetIndex >= list.length ||
        oldIndex == targetIndex) {
      return false;
    }
    final item = list.removeAt(oldIndex);
    list.insert(targetIndex, item);
    return true;
  }

  /// 将列表中的元素从 [fromIndex] 移动到 0 基目标位置 [toIndex]
  bool _moveInList<T>(List<T> list, int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        fromIndex >= list.length ||
        toIndex < 0 ||
        toIndex >= list.length ||
        fromIndex == toIndex) {
      return false;
    }
    final item = list.removeAt(fromIndex);
    list.insert(toIndex, item);
    return true;
  }

  /// 交换列表中两个下标的元素
  bool _swapInList<T>(List<T> list, int indexA, int indexB) {
    if (indexA < 0 ||
        indexA >= list.length ||
        indexB < 0 ||
        indexB >= list.length ||
        indexA == indexB) {
      return false;
    }
    final temp = list[indexA];
    list[indexA] = list[indexB];
    list[indexB] = temp;
    return true;
  }

  /// 拖拽调整收藏夹顺序并持久化
  Future<void> reorderFolders(int oldIndex, int newIndex) async {
    if (!_loaded) await loadFolders();
    if (_reorderList(_folders, oldIndex, newIndex)) {
      await _saveFolders();
    }
  }

  /// 将收藏夹移动到指定 0 基序号并持久化
  Future<void> moveFolderTo(int fromIndex, int toIndex) async {
    if (!_loaded) await loadFolders();
    if (_moveInList(_folders, fromIndex, toIndex)) {
      await _saveFolders();
    }
  }

  /// 交换两个收藏夹的位置并持久化
  Future<void> swapFolders(int indexA, int indexB) async {
    if (!_loaded) await loadFolders();
    if (_swapInList(_folders, indexA, indexB)) {
      await _saveFolders();
    }
  }

  /// 设置并持久化收藏夹的排序方式
  Future<void> setFolderSortOption(
      String folderId, FavoriteSortOption option) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      if (folder.sortOption == option) return;
      folder.sortOption = option;
      folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveFolders();
    } catch (_) {
      // 收藏夹不存在时静默忽略
    }
  }

  /// 将指定的谱面顺序固化保存到收藏夹中
  Future<void> saveChartsOrder(
      String folderId, List<FavoriteChart> orderedCharts) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      folder.charts = List<FavoriteChart>.from(orderedCharts);
      folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _saveFolders();
    } catch (_) {
      // 收藏夹不存在时静默忽略
    }
  }

  /// 拖拽调整收藏夹内谱面顺序并持久化
  Future<void> reorderChartsInFolder(
      String folderId, int oldIndex, int newIndex) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      if (_reorderList(folder.charts, oldIndex, newIndex)) {
        folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveFolders();
      }
    } catch (_) {
      // 收藏夹不存在时静默忽略
    }
  }

  /// 将收藏夹内谱面移动到指定 0 基序号并持久化
  Future<void> moveChartInFolder(
      String folderId, int fromIndex, int toIndex) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      if (_moveInList(folder.charts, fromIndex, toIndex)) {
        folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveFolders();
      }
    } catch (_) {
      // 收藏夹不存在时静默忽略
    }
  }

  /// 交换收藏夹内两个谱面的位置并持久化
  Future<void> swapChartsInFolder(
      String folderId, int indexA, int indexB) async {
    if (!_loaded) await loadFolders();
    try {
      final folder = _folders.firstWhere((f) => f.id == folderId);
      if (_swapInList(folder.charts, indexA, indexB)) {
        folder.updatedAt = DateTime.now().millisecondsSinceEpoch;
        await _saveFolders();
      }
    } catch (_) {
      // 收藏夹不存在时静默忽略
    }
  }

  /// 批量导入收藏夹。
  ///
  /// - [replaceAll] 为 true 时先清空所有现有收藏夹（覆盖式导入）。
  /// - 否则按「合并」语义：先按名字、再按 id 找同目标收藏夹，命中就把谱面并进去
  ///   （按 uniqueKey 去重），都没命中才新建。
  ///
  /// 只在最后写一次 SharedPreferences，避免逐条保存带来的卡顿。
  Future<FavoriteImportStats> importFolders(
    List<FavoriteFolder> incoming, {
    bool replaceAll = false,
  }) async {
    if (!_loaded) await loadFolders();

    if (replaceAll) _folders = [];

    int foldersCreated = 0;
    int foldersMerged = 0;
    int chartsAdded = 0;
    int chartsSkipped = 0;

    for (final source in incoming) {
      // 1) 按名字找（用户视角的同一性）
      int index = _folders.indexWhere((f) => f.name == source.name);
      // 2) 名字没命中时再按 id 找（同一份数据被改过名的场景）
      if (index < 0 && source.id.isNotEmpty) {
        index = _folders.indexWhere((f) => f.id == source.id);
      }

      FavoriteFolder target;
      if (index >= 0) {
        target = _folders[index];
        foldersMerged++;
      } else {
        target = FavoriteFolder(
          id: source.id.isEmpty ? null : source.id,
          name: source.name,
          createdAt: source.createdAt,
          sortOption: source.sortOption,
        );
        _folders.add(target);
        foldersCreated++;
      }

      final existing = target.charts.map((c) => c.uniqueKey).toSet();
      for (final chart in source.charts) {
        if (existing.contains(chart.uniqueKey)) {
          chartsSkipped++;
          continue;
        }
        existing.add(chart.uniqueKey);
        target.charts.add(chart);
        chartsAdded++;
      }
      target.updatedAt = DateTime.now().millisecondsSinceEpoch;
    }

    await _saveFolders();

    return FavoriteImportStats(
      foldersCreated: foldersCreated,
      foldersMerged: foldersMerged,
      chartsAdded: chartsAdded,
      chartsSkipped: chartsSkipped,
    );
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    _folders = [];
    _loaded = true;
    await _saveFolders();
  }
}