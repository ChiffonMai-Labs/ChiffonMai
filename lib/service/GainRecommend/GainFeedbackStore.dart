import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'GainRecommendCore.dart';

/// 吃分推荐的长期反馈（不喜欢 / 暂时卡住）。
///
/// 语义沿用 AWMC 方案：
/// - 不喜欢：具体谱面（曲目 id + 难度），直到用户撤销；跨路线硬排除。
/// - 暂时卡住：同一谱面 14 天，到期自动解除，也可立即撤销。
/// - 「这次跳过」只在当前页面会话里生效，不落盘，不在这里管理。
///
/// 反馈只服务本机推荐，不上传。
enum GainFeedbackKind { dislike, stuck }

class GainFeedbackRecord {
  final GainChartKey key;
  final GainFeedbackKind kind;
  final String title;
  final String level;
  final DateTime createdAt;

  /// null = 直到撤销（不喜欢）。
  final DateTime? expiresAt;

  const GainFeedbackRecord({
    required this.key,
    required this.kind,
    required this.title,
    required this.level,
    required this.createdAt,
    this.expiresAt,
  });

  bool isActive(DateTime now) => expiresAt == null || expiresAt!.isAfter(now);

  Map<String, dynamic> toJson() => {
        'key': key.storageKey,
        'kind': kind.name,
        'title': title,
        'level': level,
        'created_at': createdAt.millisecondsSinceEpoch,
        if (expiresAt != null) 'expires_at': expiresAt!.millisecondsSinceEpoch,
      };

  static GainFeedbackRecord? tryParse(Map raw) {
    final key = GainChartKey.tryParse('${raw['key']}');
    final kind = GainFeedbackKind.values
        .where((k) => k.name == raw['kind'])
        .firstOrNull;
    final created = raw['created_at'];
    if (key == null || kind == null || created is! int) return null;
    final expires = raw['expires_at'];
    return GainFeedbackRecord(
      key: key,
      kind: kind,
      title: '${raw['title'] ?? key.songId}',
      level: '${raw['level'] ?? ''}',
      createdAt: DateTime.fromMillisecondsSinceEpoch(created),
      expiresAt:
          expires is int ? DateTime.fromMillisecondsSinceEpoch(expires) : null,
    );
  }
}

class GainFeedbackStore {
  static final instance = GainFeedbackStore._();
  GainFeedbackStore._();

  static const _key = 'gain_recommend_feedback_v1';
  static const stuckTtl = Duration(days: 14);

  /// 测试注入时钟。
  @visibleForTesting
  DateTime Function() clock = DateTime.now;

  final Map<GainChartKey, GainFeedbackRecord> _records = {};
  Future<void>? _loading;
  bool _loaded = false;

  @visibleForTesting
  void debugReset() {
    _records.clear();
    _loading = null;
    _loaded = false;
    clock = DateTime.now;
  }

  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _records.clear();
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        if (list is List) {
          for (final item in list) {
            if (item is! Map) continue;
            final rec = GainFeedbackRecord.tryParse(item);
            if (rec != null) _records[rec.key] = rec;
          }
        }
      } catch (e) {
        debugPrint('读取吃分推荐反馈失败: $e');
      }
    }
    _loaded = true;
    _purgeExpired();
  }

  void _purgeExpired() {
    final now = clock();
    _records.removeWhere((_, rec) => !rec.isActive(now));
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode([for (final r in _records.values) r.toJson()]));
  }

  /// 当前生效的反馈，新的在前。
  Future<List<GainFeedbackRecord>> list() async {
    await ensureLoaded();
    _purgeExpired();
    return _records.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 推荐时必须硬排除的谱面。
  Future<Set<GainChartKey>> excludedKeys() async {
    await ensureLoaded();
    _purgeExpired();
    return _records.keys.toSet();
  }

  /// 记录反馈。同类重复提交幂等（不刷新期限）；换类别则覆盖为新类别。
  Future<void> record(GainChartKey key, GainFeedbackKind kind,
      {required String title, required String level}) async {
    await ensureLoaded();
    _purgeExpired();
    final existing = _records[key];
    if (existing != null && existing.kind == kind) return;
    final now = clock();
    _records[key] = GainFeedbackRecord(
      key: key,
      kind: kind,
      title: title,
      level: level,
      createdAt: now,
      expiresAt: kind == GainFeedbackKind.stuck ? now.add(stuckTtl) : null,
    );
    await _persist();
  }

  Future<void> undo(GainChartKey key) async {
    await ensureLoaded();
    if (_records.remove(key) != null) await _persist();
  }
}
