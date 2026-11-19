import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 被本地屏蔽的评论作者。
class BlockedCommentUser {
  final String dataSource;
  final String originalId;
  final String nickname;

  const BlockedCommentUser({
    required this.dataSource,
    required this.originalId,
    this.nickname = '',
  });

  String get key => '$dataSource:$originalId';
  String get label => nickname.trim().isNotEmpty ? nickname.trim() : originalId;

  Map<String, dynamic> toJson() => {
        'dataSource': dataSource,
        'originalId': originalId,
        'nickname': nickname,
      };

  factory BlockedCommentUser.fromJson(Map<String, dynamic> json) =>
      BlockedCommentUser(
        dataSource: json['dataSource']?.toString() ?? '',
        originalId: json['originalId']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '',
      );
}

/// 评论作者屏蔽列表：只存本机，按「数据源 + 账号 ID」识别，不按昵称。
///
/// 屏蔽后其评论会从歌曲评论区与最近评论里过滤掉；评分是聚合数据，按作者隐藏不了。
class CommentBlockStore {
  CommentBlockStore._();

  static const String _key = 'comment_blocked_users_v1';
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<List<BlockedCommentUser>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final data = json.decode(raw);
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((e) => BlockedCommentUser.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.dataSource.isNotEmpty && e.originalId.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> isBlocked(String dataSource, String originalId) async {
    if (dataSource.isEmpty || originalId.isEmpty) return false;
    final all = await load();
    return all
        .any((e) => e.dataSource == dataSource && e.originalId == originalId);
  }

  static Future<void> block(BlockedCommentUser user) async {
    if (user.dataSource.isEmpty || user.originalId.isEmpty) return;
    final all = await load();
    if (all.any((e) => e.key == user.key)) return;
    all.add(user);
    await _save(all);
  }

  static Future<void> unblock(String dataSource, String originalId) async {
    final all = await load();
    all.removeWhere(
        (e) => e.dataSource == dataSource && e.originalId == originalId);
    await _save(all);
  }

  static Future<void> _save(List<BlockedCommentUser> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(all.map((e) => e.toJson()).toList()));
    revision.value++;
  }
}
