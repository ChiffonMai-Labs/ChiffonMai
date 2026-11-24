import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

/// 榜单截断后，和最后一首并列的谱面。
///
/// [sorted] 必须已按 [field] 降序排好；没有截断或没有并列时返回空列表。
List<T> tiedBeyondCut<T>(List<T> sorted, int limit, String field) {
  if (limit <= 0 || sorted.length <= limit) return <T>[];
  final last = (sorted[limit - 1] as Map)[field];
  if (last == null) return <T>[];
  return sorted.skip(limit).where((item) => (item as Map)[field] == last).toList();
}

String best50MapChartKey(Map<String, dynamic> item) =>
    '${item['song_id']}_${item['level_index']}';

/// 管理「榜单末尾同分并列区」的可选状态。
///
/// [locked] 是严格高于末尾分数的部分；[candidates] 按默认排序规则包含
/// 所有并列分数相同的谱面，前 [slotCount] 首为默认入榜谱面。
class Best50TiePool<T> {
  final List<T> locked;
  final List<T> candidates;
  final int slotCount;
  final Set<String> selectedKeys;
  final String Function(T item) keyOf;

  Best50TiePool._({
    required this.locked,
    required this.candidates,
    required this.slotCount,
    required Set<String> selectedKeys,
    required this.keyOf,
  }) : selectedKeys = Set<String>.unmodifiable(selectedKeys);

  factory Best50TiePool.fromSplit({
    required List<T> defaultShown,
    required List<T> defaultRemaining,
    required Object? Function(T item) tieValueOf,
    required String Function(T item) keyOf,
    Set<String>? savedKeys,
  }) {
    if (defaultShown.isEmpty || defaultRemaining.isEmpty) {
      return Best50TiePool<T>._(
        locked: List<T>.of(defaultShown),
        candidates: const [],
        slotCount: 0,
        selectedKeys: const {},
        keyOf: keyOf,
      );
    }

    final cutoff = tieValueOf(defaultShown.last);
    var splitIdx = defaultShown.length - 1;
    while (splitIdx > 0 && tieValueOf(defaultShown[splitIdx - 1]) == cutoff) {
      splitIdx--;
    }

    final locked = defaultShown.sublist(0, splitIdx);
    final defaultTail = defaultShown.sublist(splitIdx);
    final slotCount = defaultTail.length;

    final seen = <String>{};
    final candidates = <T>[];
    for (final item in [...defaultTail, ...defaultRemaining]) {
      final k = keyOf(item);
      if (seen.add(k)) {
        candidates.add(item);
      }
    }

    if (candidates.length <= slotCount) {
      return Best50TiePool<T>._(
        locked: List<T>.of(defaultShown),
        candidates: const [],
        slotCount: 0,
        selectedKeys: const {},
        keyOf: keyOf,
      );
    }

    final selected = <String>{};
    if (savedKeys != null) {
      for (final k in savedKeys) {
        if (seen.contains(k) && selected.length < slotCount) {
          selected.add(k);
        }
      }
    }
    for (final item in candidates) {
      if (selected.length >= slotCount) break;
      selected.add(keyOf(item));
    }

    return Best50TiePool<T>._(
      locked: List<T>.unmodifiable(locked),
      candidates: List<T>.unmodifiable(candidates),
      slotCount: slotCount,
      selectedKeys: selected,
      keyOf: keyOf,
    );
  }

  bool get hasTies => slotCount > 0 && candidates.length > slotCount;

  Set<String> get defaultKeys => {
        for (final item in candidates.take(slotCount)) keyOf(item),
      };

  bool get isCustomized =>
      hasTies &&
      !(defaultKeys.length == selectedKeys.length &&
          defaultKeys.containsAll(selectedKeys));

  List<T> get shown => hasTies
      ? [
          ...locked,
          for (final c in candidates)
            if (selectedKeys.contains(keyOf(c))) c,
        ]
      : List<T>.of(locked);

  List<T> get remaining => hasTies
      ? [
          for (final c in candidates)
            if (!selectedKeys.contains(keyOf(c))) c,
        ]
      : <T>[];

  Best50TiePool<T> withSelection(Set<String> nextKeys) {
    if (!hasTies) return this;
    final validSet = {for (final c in candidates) keyOf(c)};
    final sanitized = <String>{
      for (final k in nextKeys)
        if (validSet.contains(k)) k,
    };
    if (sanitized.length != slotCount) return this;
    return Best50TiePool<T>._(
      locked: locked,
      candidates: candidates,
      slotCount: slotCount,
      selectedKeys: sanitized,
      keyOf: keyOf,
    );
  }

  Best50TiePool<T> resetToDefault() => withSelection(defaultKeys);
}

/// 持久化各账号在各 Best50 榜单中的末尾同分自选结果。
class Best50TieSelectionStore {
  Best50TieSelectionStore._();

  static String _entryKey(String accountKey, String scopeKey) =>
      '$accountKey|$scopeKey';

  static Future<Map<String, List<String>>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(CacheKeyConstant.best50TieSelections);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return {};
      final result = <String, List<String>>{};
      for (final entry in decoded.entries) {
        final v = entry.value;
        if (v is List) {
          result[entry.key.toString()] = v.map((e) => e.toString()).toList();
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<Set<String>?> load(String accountKey, String scopeKey) async {
    final all = await _loadAll();
    final list = all[_entryKey(accountKey, scopeKey)];
    return list?.toSet();
  }

  static Future<void> save(
    String accountKey,
    String scopeKey,
    Set<String> keys,
  ) async {
    final all = await _loadAll();
    all[_entryKey(accountKey, scopeKey)] = keys.toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      CacheKeyConstant.best50TieSelections,
      json.encode(all),
    );
  }

  static Future<void> clear(String accountKey, String scopeKey) async {
    final all = await _loadAll();
    if (all.remove(_entryKey(accountKey, scopeKey)) == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      CacheKeyConstant.best50TieSelections,
      json.encode(all),
    );
  }

  static Future<void> saveOrClear(
    String accountKey,
    String scopeKey,
    Best50TiePool<dynamic> pool,
  ) async {
    if (pool.isCustomized) {
      await save(accountKey, scopeKey, pool.selectedKeys);
    } else {
      await clear(accountKey, scopeKey);
    }
  }
}
