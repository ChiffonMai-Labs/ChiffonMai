import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';
import '../entity/DXRating/MaiTagsModel.dart';
import '../utils/ChartDifficulty.dart';

/// 自定义标签里的一张谱面。
///
/// 现有标签系统按「曲名 + 谱面类型 + 难度」关联谱面（见 [MaiTagsManager]），
/// 所以这里同时保存曲名和类型；songId 用于跳转、曲绘与去重。
@immutable
class CustomTagChart {
  final String songId;
  final String title;

  /// std / dx / utage，与 DXRating 的 sheet_type 一致。
  final String sheetType;
  final int levelIndex;

  const CustomTagChart({
    required this.songId,
    required this.title,
    required this.sheetType,
    required this.levelIndex,
  });

  /// 由歌曲类型推出 sheet_type：宴谱优先，其次 DX / 标准。
  static String sheetTypeOf(String songId, String songType) =>
      ChartDifficulty.isUtageSong(songId, type: songType)
          ? 'utage'
          : songType.toUpperCase() == 'DX'
              ? 'dx'
              : 'std';

  String get sheetDifficulty =>
      ChartDifficulty.apiNameOf(levelIndex, fallback: 'master');

  String get uniqueKey => '${songId}_$levelIndex';

  Map<String, dynamic> toJson() => {
        'songId': songId,
        'title': title,
        'sheetType': sheetType,
        'levelIndex': levelIndex,
      };

  static CustomTagChart? fromJson(Object? json) {
    if (json is! Map) return null;
    final songId = json['songId']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    final level = json['levelIndex'];
    if (songId.isEmpty || title.isEmpty || level is! int) return null;
    return CustomTagChart(
      songId: songId,
      title: title,
      sheetType: json['sheetType']?.toString() ?? 'std',
      levelIndex: level,
    );
  }
}

@immutable
class CustomTag {
  /// 与 DXRating 标签共用 int 编号空间，从 [CustomTagStore.idBase] 起分配，避免冲突。
  final int id;
  final String name;

  /// ARGB 颜色值。
  final int color;
  final List<CustomTagChart> charts;

  const CustomTag({
    required this.id,
    required this.name,
    required this.color,
    this.charts = const [],
  });

  CustomTag copyWith(
          {String? name, int? color, List<CustomTagChart>? charts}) =>
      CustomTag(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        charts: charts ?? this.charts,
      );

  bool contains(CustomTagChart chart) =>
      charts.any((c) => c.uniqueKey == chart.uniqueKey);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'charts': [for (final c in charts) c.toJson()],
      };

  static CustomTag? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final name = json['name']?.toString().trim() ?? '';
    final color = json['color'];
    if (id is! int || name.isEmpty || color is! int) return null;
    final charts = <CustomTagChart>[];
    final seen = <String>{};
    for (final raw in (json['charts'] as List?) ?? const []) {
      final chart = CustomTagChart.fromJson(raw);
      if (chart != null && seen.add(chart.uniqueKey)) charts.add(chart);
    }
    return CustomTag(id: id, name: name, color: color, charts: charts);
  }
}

/// 用户自定义标签：名称、颜色、谱面都由用户决定，并合并进现有标签系统。
///
/// 合并方式见 [MaiTagsManager.getTags]：自定义标签作为 [groupId] 分组下的
/// 普通标签出现，乐曲查询的标签筛选、Best50 / 收藏夹的标签统计、个性化
/// Best50 的「标签50」等现有入口都会直接看到它们。
class CustomTagStore extends ChangeNotifier {
  CustomTagStore._();
  static final CustomTagStore instance = CustomTagStore._();

  /// 自定义标签所在分组的编号（DXRating 只用 1–3）。
  static const int groupId = 900000;

  /// 自定义标签编号起点。
  static const int idBase = 900001;

  static const int maxNameLength = 20;

  List<CustomTag> _tags = const [];
  bool _loaded = false;
  Future<void>? _loading;

  /// 每次变更递增，[MaiTagsManager] 据此判断合并结果是否过期。
  int _revision = 0;
  int get revision => _revision;

  List<CustomTag> get tags => _tags;
  bool get loaded => _loaded;

  bool isCustomTagId(int id) => id >= idBase;

  CustomTag? byId(int id) {
    for (final tag in _tags) {
      if (tag.id == id) return tag;
    }
    return null;
  }

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _read().whenComplete(() => _loading = null);
  }

  Future<void> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(CacheKeyConstant.customTags);
    final tags = <CustomTag>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        final seen = <int>{};
        for (final item in decoded is List ? decoded : const []) {
          final tag = CustomTag.fromJson(item);
          if (tag != null && tag.id >= idBase && seen.add(tag.id)) {
            tags.add(tag);
          }
        }
      } catch (e) {
        debugPrint('读取自定义标签失败: $e');
      }
    }
    _tags = List.unmodifiable(tags);
    _loaded = true;
    _revision++;
    notifyListeners();
  }

  /// 恢复备份后重新读取。
  Future<void> reload() {
    _loaded = false;
    return ensureLoaded();
  }

  Future<void> _save(List<CustomTag> next) async {
    // 内存先更新，界面立即响应；写盘失败时抛出给调用方提示。
    _tags = List.unmodifiable(next);
    _revision++;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final ok = await prefs.setString(CacheKeyConstant.customTags,
        jsonEncode([for (final t in next) t.toJson()]));
    if (!ok) throw StateError('custom tags not saved');
  }

  Future<CustomTag> create(String name, int color) async {
    await ensureLoaded();
    final nextId = _tags.fold<int>(idBase - 1, (m, t) => t.id > m ? t.id : m) + 1;
    final tag = CustomTag(id: nextId, name: name.trim(), color: color);
    await _save([..._tags, tag]);
    return tag;
  }

  Future<void> update(CustomTag tag) async {
    await ensureLoaded();
    await _save([for (final t in _tags) t.id == tag.id ? tag : t]);
  }

  Future<void> delete(int id) async {
    await ensureLoaded();
    await _save(_tags.where((t) => t.id != id).toList());
  }

  Future<void> addCharts(int tagId, Iterable<CustomTagChart> charts) async {
    final tag = byId(tagId);
    if (tag == null) return;
    final next = [...tag.charts];
    for (final chart in charts) {
      if (!next.any((c) => c.uniqueKey == chart.uniqueKey)) next.add(chart);
    }
    await update(tag.copyWith(charts: next));
  }

  Future<void> removeChart(int tagId, CustomTagChart chart) async {
    final tag = byId(tagId);
    if (tag == null) return;
    await update(tag.copyWith(
        charts:
            tag.charts.where((c) => c.uniqueKey != chart.uniqueKey).toList()));
  }

  /// 给一张谱面打上或取消某个标签。
  Future<void> toggleChart(int tagId, CustomTagChart chart) async {
    final tag = byId(tagId);
    if (tag == null) return;
    tag.contains(chart)
        ? await removeChart(tagId, chart)
        : await addCharts(tagId, [chart]);
  }

  /// 某张谱面已有的自定义标签。
  List<CustomTag> tagsOf(String songId, int levelIndex) => [
        for (final tag in _tags)
          if (tag.charts
              .any((c) => c.songId == songId && c.levelIndex == levelIndex))
            tag,
      ];

  // ── 接入现有标签系统 ──

  /// 把自定义标签合并进 DXRating 标签数据（返回新对象，不改动 [base]）。
  MaiTagsEntity mergeInto(MaiTagsEntity? base, String groupName) {
    LocalizedName same(String text) =>
        LocalizedName(en: text, ja: text, ko: text, zhHans: text);
    final blank = LocalizedDescription(en: '', ja: '', ko: '', zhHans: '');
    final baseTags = base?.tags ?? const <TagItem>[];
    final baseGroups = base?.tagGroups ?? const <TagGroupItem>[];
    final baseSongs = base?.tagSongs ?? const <TagSongItem>[];
    if (_tags.isEmpty && base != null) return base;
    return MaiTagsEntity(
      tags: [
        ...baseTags,
        for (final tag in _tags)
          TagItem(
            id: tag.id,
            localizedName: same(tag.name),
            localizedDescription: blank,
            groupId: groupId,
          ),
      ],
      tagGroups: [
        ...baseGroups,
        if (_tags.isNotEmpty)
          TagGroupItem(id: groupId, localizedName: same(groupName), color: ''),
      ],
      tagSongs: [
        ...baseSongs,
        for (final tag in _tags)
          for (final chart in tag.charts)
            TagSongItem(
              songId: chart.title,
              sheetType: chart.sheetType,
              sheetDifficulty: chart.sheetDifficulty,
              tagId: tag.id,
            ),
      ],
    );
  }
}
