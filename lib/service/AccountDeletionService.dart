import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../utils/ApiClient.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import '../utils/SecureCredentialStore.dart';
import '../utils/UserProfileNotifier.dart';
import 'AccountStore.dart';
import 'AccountSwitchService.dart';
import 'CommunityProfileAuthorization.dart';
import 'RankingList/SongRankingService.dart';
import 'SongInfoService.dart';

/// 一个可删除的数据源账号。
class DeletionAccount {
  final RefreshDataSource source;
  final String id;
  final String nickname;

  const DeletionAccount({
    required this.source,
    required this.id,
    this.nickname = '',
  });

  String get playerId => '${source.key}:$id';
  String get label => nickname.trim().isNotEmpty ? nickname.trim() : id;
}

/// 删除结果。失败项只用于提示用户走邮件申请，不阻塞本地清理。
class AccountDeletionReport {
  int comments = 0;
  int ratings = 0;
  int rankings = 0;
  final List<String> failures = [];

  bool get hasFailures => failures.isNotEmpty;
}

/// 删除 App 内的账号数据。
///
/// 顺序固定：**先做服务端清理（需要令牌），再清本机**。服务端删除全部按尽力而为，
/// 失败的类别记进报告，由页面提供邮件申请入口。第三方平台账号本身不在这里删除。
class AccountDeletionService {
  AccountDeletionService._();

  static const int _batchConcurrency = 6;

  /// 找出本机保存过身份或凭据的账号，按数据源顺序展示。
  static Future<List<DeletionAccount>> loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final metas = await AccountStore.loadAll();
    final current = CurrentDataSourceNotifier.instance.value;
    final result = <DeletionAccount>[];
    for (final source in RefreshDataSource.values) {
      var id = metas[source.key]?.id ?? '';
      id = id.trim();
      if (id.isEmpty) {
        id = RefreshDataSource.parseUserIdMarker(
                prefs.getString(source.userIdCacheKey)) ??
            '';
      }
      if (id.isEmpty && source == RefreshDataSource.shuiyu) {
        id = prefs.getString(CacheKeyConstant.probeDivingFishBindQQ)?.trim() ??
            (current == source
                ? prefs.getString(CacheKeyConstant.cachedQQ)?.trim()
                : null) ??
            '';
      }
      if (id.isEmpty && source == RefreshDataSource.awmc) {
        id = prefs.getString(CacheKeyConstant.awmcLookupQQ)?.trim() ?? '';
      }
      if (id.isEmpty) continue;

      final hasMeta = metas.containsKey(source.key);
      final hasCache = await AccountStore.hasCache(source.key);
      var hasCredential = false;
      switch (source) {
        case RefreshDataSource.shuiyu:
          hasCredential =
              await _hasCredential(CacheKeyConstant.probeDivingFishToken);
        case RefreshDataSource.luoxue:
          hasCredential =
              await _hasCredential(CacheKeyConstant.luoxueAccessToken);
        case RefreshDataSource.awmc:
          hasCredential = await _hasCredential(CacheKeyConstant.awmcToken) ||
              await _hasCredential(CacheKeyConstant.awmcNetImportToken);
      }
      if (!hasMeta && !hasCache && !hasCredential) continue;

      result.add(DeletionAccount(
        source: source,
        id: id,
        nickname: metas[source.key]?.nickname ?? '',
      ));
    }
    return result;
  }

  static Future<bool> _hasCredential(String key) async {
    try {
      final value = await SecureCredentialStore.read(key);
      return value != null && value.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// 删除全部账号。调用前应确认 [accounts] 已加载。
  static Future<AccountDeletionReport> deleteAll(
    List<DeletionAccount> accounts, {
    void Function(String label)? onProgress,
  }) async {
    final report = AccountDeletionReport();
    for (final account in accounts) {
      final name = '${account.source.displayName} ${account.label}';
      onProgress?.call(name);

      await _deleteComments(account, report);
      await _deleteRatings(account, report);
      await _deleteRankings(account, report);
      await _clearLocal(account.source, report);
    }

    // 兜底清掉可能残留的凭据与账号快照。
    try {
      await SecureCredentialStore.deleteAll();
    } catch (error) {
      report.failures.add('凭据清理：$error');
    }
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      CacheKeyConstant.cachedQQ,
      CacheKeyConstant.userNickname,
      CacheKeyConstant.commentDataSource,
      CacheKeyConstant.commentOriginalId,
      CacheKeyConstant.commentNickname,
    ]) {
      await prefs.remove(key);
    }
    await CurrentDataSourceNotifier.instance.set(RefreshDataSource.defaultSource);
    return report;
  }

  // ───────────────────────── 服务端清理 ─────────────────────────

  static Future<void> _deleteComments(
      DeletionAccount account, AccountDeletionReport report) async {
    final headers =
        await CommunityProfileAuthorization.ownerHeaders(account.playerId);
    final listUri = Uri.parse(
        '${ApiUrls.CommentsByUserUrl}/${Uri.encodeComponent(account.playerId)}');
    List<Map<String, dynamic>> items;
    try {
      final response = await ApiClient.get(listUri, headers: headers);
      if (response.statusCode != 200) {
        report.failures.add('${account.source.displayName} 评论读取失败');
        return;
      }
      final data = json.decode(response.body);
      final raw = data is Map ? data['data'] : null;
      items = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [];
    } catch (error) {
      report.failures.add('${account.source.displayName} 评论读取失败：$error');
      return;
    }
    if (items.isEmpty) return;

    final bulkUri =
        Uri.parse(ApiUrls.CommentsByUserUrl).replace(queryParameters: {
      'dataSource': account.source.key,
      'originalId': account.id,
    });
    try {
      final bulk = await ApiClient.delete(
        bulkUri,
        headers: headers,
        body: json.encode({
          'dataSource': account.source.key,
          'originalId': account.id,
        }),
      );
      if (bulk.statusCode == 200) {
        final body = json.decode(bulk.body);
        if (body is! Map || body['success'] != false) {
          report.comments += items.length;
          return;
        }
      }
    } catch (error) {
      debugPrint('[DeleteAccount] 批量删除评论失败，改为逐条删除: $error');
    }

    var cursor = 0;
    while (cursor < items.length) {
      final end = (cursor + _batchConcurrency).clamp(0, items.length);
      final batch = items.sublist(cursor, end);
      final results = await Future.wait(batch.map((item) async {
        final commentId = (item['id'] as num?)?.toInt() ?? 0;
        final songId = (item['songId'] ?? item['song_id'])?.toString() ?? '';
        final levelIndex = (item['levelIndex'] ?? item['level_index']) is num
            ? ((item['levelIndex'] ?? item['level_index']) as num).toInt()
            : null;
        if (commentId == 0 || songId.isEmpty) return false;
        final result = await SongInfoService.deleteComment(
          commentId: commentId,
          songId: songId,
          levelIndex: levelIndex,
          dataSource: account.source.key,
          originalId: account.id,
        );
        return result['success'] == true;
      }));
      report.comments += results.where((ok) => ok).length;
      cursor = end;
    }
  }

  static Future<void> _deleteRatings(
      DeletionAccount account, AccountDeletionReport report) async {
    final targets = await _ratingTargets(account.source);
    if (targets.isEmpty) return;
    final headers =
        await CommunityProfileAuthorization.ownerHeaders(account.playerId);

    var cursor = 0;
    while (cursor < targets.length) {
      final end = (cursor + _batchConcurrency).clamp(0, targets.length);
      final batch = targets.sublist(cursor, end);
      final results = await Future.wait(batch.map((target) async {
        final uri = Uri.parse(
                '${ApiUrls.RatingsDeleteUrl}/${target.songId}/${target.levelIndex}')
            .replace(queryParameters: {'userId': account.playerId});
        try {
          final response = await ApiClient.delete(
            uri,
            headers: headers,
            body: json.encode({
              'dataSource': account.source.key,
              'originalId': account.id,
            }),
          );
          if (response.statusCode != 200) return false;
          final body = json.decode(response.body);
          return body is Map && body['success'] == true;
        } catch (_) {
          return false;
        }
      }));
      report.ratings += results.where((ok) => ok).length;
      cursor = end;
    }
  }

  static Future<void> _deleteRankings(
      DeletionAccount account, AccountDeletionReport report) async {
    final headers =
        await CommunityProfileAuthorization.ownerHeaders(account.playerId);
    try {
      final response = await ApiClient.delete(
        Uri.parse(
            '${ApiUrls.RankingsBaseUrl}/user/${Uri.encodeComponent(account.playerId)}'),
        headers: headers,
        body: json.encode({
          'dataSource': account.source.key,
          'originalId': account.id,
        }),
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body is Map && body['success'] == true) report.rankings++;
      }
    } catch (_) {
      // 未上榜或未授权都不影响后续。
    }
    try {
      if (await SongRankingService().deleteSongRankings(account.playerId)) {
        report.rankings++;
      }
    } catch (_) {
      // 同上。
    }
  }

  /// 从本机成绩存档里收集「歌曲 + 难度」，作为评分删除的目标。
  /// 评分必须先有成绩，所以成绩覆盖到的谱面就是可能的评分集合。
  static Future<List<_RatingTarget>> _ratingTargets(
      RefreshDataSource source) async {
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs
        .getString('${CacheKeyConstant.accountArchivePlayPrefix}${source.key}');
    if (CurrentDataSourceNotifier.instance.value == source) {
      raw = prefs.getString(CacheKeyConstant.userPlayData) ?? raw;
    } else if (raw != null) {
      try {
        final archive = json.decode(raw);
        if (archive is Map) {
          raw = archive[CacheKeyConstant.userPlayData]?.toString() ?? raw;
        }
      } catch (_) {}
    }
    if (raw == null || raw.isEmpty) return const [];

    dynamic data;
    try {
      data = json.decode(raw);
      if (data is String) data = json.decode(data);
    } catch (_) {
      return const [];
    }
    final records = data is Map ? data['records'] : null;
    if (records is! List) return const [];

    final seen = <String>{};
    final result = <_RatingTarget>[];
    for (final item in records.whereType<Map>()) {
      final songId =
          (item['song_id'] ?? item['songId'] ?? item['musicId'])?.toString();
      final rawLevel = item['level_index'] ?? item['levelIndex'];
      if (songId == null || songId.isEmpty || rawLevel is! num) continue;
      final level = rawLevel.toInt();
      if (level < 0 || level > 6) continue;
      if (!seen.add('$songId|$level')) continue;
      result.add(_RatingTarget(songId, level));
    }
    return result;
  }

  // ───────────────────────── 本机清理 ─────────────────────────

  static Future<void> _clearLocal(
      RefreshDataSource source, AccountDeletionReport report) async {
    try {
      if (source == RefreshDataSource.shuiyu) {
        await UserProfileNotifier.clearShuiyuAccountCache();
        return;
      }
      await AccountSwitchService.clearAccountData(
        source,
        clearCredentials: () async {
          final prefs = await SharedPreferences.getInstance();
          switch (source) {
            case RefreshDataSource.luoxue:
              await SecureCredentialStore.delete(
                  CacheKeyConstant.luoxueAccessToken);
              await SecureCredentialStore.delete(
                  CacheKeyConstant.luoxueRefreshToken);
              await SecureCredentialStore.delete(
                  CacheKeyConstant.probeLxnsImportToken);
              await prefs.remove(CacheKeyConstant.luoxueUserId);
              break;
            case RefreshDataSource.awmc:
              await SecureCredentialStore.delete(CacheKeyConstant.awmcToken);
              await SecureCredentialStore.delete(
                  CacheKeyConstant.awmcNetImportToken);
              await prefs.remove(CacheKeyConstant.awmcUserId);
              await prefs.remove(CacheKeyConstant.awmcLookupQQ);
              break;
            case RefreshDataSource.shuiyu:
              break;
          }
        },
      );
    } catch (error) {
      report.failures.add('${source.displayName} 本机数据清理失败：$error');
    }
  }
}

class _RatingTarget {
  final String songId;
  final int levelIndex;

  const _RatingTarget(this.songId, this.levelIndex);
}
