import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../Account/AccountStore.dart';
import 'CommunityProfileAuthorization.dart';

/// 被屏蔽的评论作者（本地缓存 + 已登录账号云端同步）。
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

/// 评论作者屏蔽列表：本地即时生效，已鉴权账号尽力与服务端同步。
///
/// 屏蔽后其评论会从歌曲评论区与最近评论里过滤掉；评分是聚合数据，按作者隐藏不了。
class CommentBlockStore {
  CommentBlockStore._();

  static const String _key = 'comment_blocked_users_v1';
  static const String _migratedPrefix = 'comment_blocked_users_synced_';
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<String?> _resolveActivePlayerId() async {
    await CurrentDataSourceNotifier.load();
    final prefs = await SharedPreferences.getInstance();
    final accounts = await AccountStore.loadAll();
    final current = CurrentDataSourceNotifier.instance.value;
    final ordered = <RefreshDataSource>[
      current,
      ...RefreshDataSource.values.where((s) => s != current),
    ];
    for (final source in ordered) {
      final marker = prefs.getString(source.userIdCacheKey);
      final validMarker = marker?.startsWith('${source.key}:') == true &&
              RefreshDataSource.parseUserIdMarker(marker) != null
          ? marker
          : null;
      final archivedId = accounts[source.key]?.id.trim();
      final archivedMarker = archivedId == null || archivedId.isEmpty
          ? null
          : '${source.key}:$archivedId';
      final playerId = source == current
          ? validMarker ?? archivedMarker
          : archivedMarker ?? validMarker;
      if (playerId != null && playerId.isNotEmpty) return playerId;
    }
    return null;
  }

  static Future<Map<String, String>?> _authorizedHeaders(
      String playerId) async {
    final headers = await CommunityProfileAuthorization.ownerHeaders(playerId);
    final hasAuth = headers.containsKey('Authorization') ||
        headers.containsKey('X-Profile-QQ') ||
        headers.containsKey('X-Auto-Sync-Token');
    return hasAuth ? headers : null;
  }

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

  /// 与服务端同步屏蔽列表；未登录或网络异常时优雅退回本地列表。
  static Future<List<BlockedCommentUser>> syncWithServer() async {
    final local = await load();
    try {
      final playerId = await _resolveActivePlayerId();
      if (playerId == null) return local;
      final headers = await _authorizedHeaders(playerId);
      if (headers == null) return local;

      final uri = Uri.parse(ApiUrls.CommunityBlocksUrl)
          .replace(queryParameters: {'playerId': playerId});
      final response = await ApiClient.get(
        uri,
        headers: headers,
        timeout: const Duration(seconds: 6),
      );
      if (response.statusCode != 200) return local;

      final decoded = json.decode(response.body);
      if (decoded is! Map || decoded['success'] != true) return local;
      final rawList = decoded['data'];
      if (rawList is! List) return local;

      final remote = rawList
          .whereType<Map>()
          .map((e) => BlockedCommentUser.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.dataSource.isNotEmpty && e.originalId.isNotEmpty)
          .toList();

      final prefs = await SharedPreferences.getInstance();
      final migratedKey = '$_migratedPrefix$playerId';
      final alreadyMigrated = prefs.getBool(migratedKey) == true;

      if (!alreadyMigrated) {
        final remoteKeys = remote.map((e) => e.key).toSet();
        final toUpload =
            local.where((e) => !remoteKeys.contains(e.key)).toList();
        for (final user in toUpload) {
          await _pushBlock(playerId, headers, user);
        }
        final merged = <String, BlockedCommentUser>{};
        for (final user in remote) {
          merged[user.key] = user;
        }
        for (final user in local) {
          merged.putIfAbsent(user.key, () => user);
        }
        final result = merged.values.toList();
        await prefs.setBool(migratedKey, true);
        await _saveIfChanged(prefs, result);
        return result;
      }

      await _saveIfChanged(prefs, remote);
      return remote;
    } catch (_) {
      return local;
    }
  }

  static Future<void> _pushBlock(
    String playerId,
    Map<String, String> headers,
    BlockedCommentUser user,
  ) async {
    try {
      await ApiClient.post(
        Uri.parse(ApiUrls.CommunityBlocksUrl),
        headers: headers,
        body: json.encode({
          'playerId': playerId,
          'dataSource': user.dataSource,
          'originalId': user.originalId,
          'nickname': user.nickname,
        }),
        timeout: const Duration(seconds: 6),
      );
    } catch (_) {}
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
    if (!all.any((e) => e.key == user.key)) {
      all.add(user);
      await _save(all);
    }
    try {
      final playerId = await _resolveActivePlayerId();
      if (playerId == null) return;
      final headers = await _authorizedHeaders(playerId);
      if (headers == null) return;
      await _pushBlock(playerId, headers, user);
    } catch (_) {}
  }

  static Future<void> unblock(String dataSource, String originalId) async {
    final all = await load();
    all.removeWhere(
        (e) => e.dataSource == dataSource && e.originalId == originalId);
    await _save(all);
    try {
      final playerId = await _resolveActivePlayerId();
      if (playerId == null) return;
      final headers = await _authorizedHeaders(playerId);
      if (headers == null) return;
      final target = Uri.encodeComponent('$dataSource:$originalId');
      final uri = Uri.parse('${ApiUrls.CommunityBlocksUrl}/$target')
          .replace(queryParameters: {'playerId': playerId});
      await ApiClient.delete(
        uri,
        headers: headers,
        timeout: const Duration(seconds: 6),
      );
    } catch (_) {}
  }

  static Future<void> clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(_migratedPrefix)) {
        await prefs.remove(key);
      }
    }
    revision.value++;
  }

  static Future<void> _saveIfChanged(
    SharedPreferences prefs,
    List<BlockedCommentUser> all,
  ) async {
    final encoded = json.encode(all.map((e) => e.toJson()).toList());
    if (prefs.getString(_key) == encoded) return;
    await prefs.setString(_key, encoded);
    revision.value++;
  }

  static Future<void> _save(List<BlockedCommentUser> all) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, json.encode(all.map((e) => e.toJson()).toList()));
    revision.value++;
  }
}
