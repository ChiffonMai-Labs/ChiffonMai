import 'dart:convert';

import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../entity/DivingFish/Song.dart';
import '../../entity/DivingFish/RecordItem.dart';
import '../../utils/ChartDifficulty.dart';
import '../../utils/StringUtil.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../utils/ApiClient.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/SecureCredentialStore.dart';
import '../AccountStore.dart';
import '../SyncStatsService.dart';
import '../SongInfoService.dart';
import 'AwmcApiService.dart';
import 'AwmcGatewaySettings.dart';
import 'AwmcQuickIdentityStore.dart';
import 'AwmcStore.dart';
import 'AwmcQuickSyncCore.dart';

class AwmcQuickAccount {
  final RefreshDataSource source;
  final String id;
  final String credential;
  const AwmcQuickAccount(this.source, this.id, this.credential);
  String get key => '${source.key}:$id';
}

class AwmcQuickSyncResult {
  final int submitted;
  final int skipped;
  final int unchanged;
  const AwmcQuickSyncResult(this.submitted, this.skipped, {this.unchanged = 0});
}

/// 仅在一次多端同步中共享原始机台成绩；不会保存个人 key 或目标源标记。
class AwmcQuickReadSession {
  final _snapshots = <int, Future<List<AwmcQuickScore>>>{};

  Future<List<AwmcQuickScore>> _read(
          int userId, Future<List<AwmcQuickScore>> Function() load) =>
      _snapshots.putIfAbsent(userId, load);
}

/// 水鱼/落雪线路1与 AWMC NET 的快速同步，FC/FS 始终按同一目标账号合并。
class AwmcQuickSyncService {
  AwmcQuickSyncService._();
  static bool _running = false;
  static const _credentialKeys = {
    SyncPlatform.divingFish: CacheKeyConstant.probeDivingFishImportToken,
    SyncPlatform.luoXue: CacheKeyConstant.probeLxnsImportToken,
    SyncPlatform.awmc: CacheKeyConstant.awmcNetImportToken,
  };

  static RefreshDataSource sourceOf(SyncPlatform platform) =>
      switch (platform) {
        SyncPlatform.divingFish => RefreshDataSource.shuiyu,
        SyncPlatform.luoXue => RefreshDataSource.luoxue,
        SyncPlatform.awmc => RefreshDataSource.awmc,
      };

  static Future<AwmcQuickAccount> accountFor(SyncPlatform platform,
      {bool requireData = true}) async {
    final source = sourceOf(platform);
    final account = (await AccountStore.loadAll())[source.key];
    final credential =
        await SecureCredentialStore.read(_credentialKeys[platform]!);
    if (credential == null || credential.trim().isEmpty) {
      throw StateError('请先设置${platform.label}的同步凭据');
    }
    if (account == null || account.id.isEmpty) {
      throw StateError('请先设置${platform.label}账号');
    }
    if (requireData && !account.hasData) {
      throw StateError('请先刷新${platform.label}账号的数据，再使用快速同步');
    }
    return AwmcQuickAccount(source, account.id, credential.trim());
  }

  /// 普通二维码读取前捕获目标账号，后续回包不得绑定到新切换的账号上。
  static Future<AwmcQuickAccount?> captureIdentityAccount(
      RefreshDataSource source) async {
    try {
      final platform =
          SyncPlatform.values.firstWhere((p) => sourceOf(p) == source);
      return await accountFor(platform, requireData: false);
    } catch (_) {
      return null;
    }
  }

  /// 复用普通同步已有的响应缓存身份，不追加网络请求，也不影响普通同步结果。
  static Future<void> rememberIdentity(
      AwmcQuickAccount? account, dynamic businessData) async {
    if (account == null || businessData is! Map) return;
    final id = int.tryParse('${businessData['userId']}');
    if (id == null || id <= 0 || id > 0xFFFFFFFF) return;
    try {
      final current = await captureIdentityAccount(account.source);
      if (current == null ||
          current.key != account.key ||
          current.credential != account.credential) return;
      await AwmcQuickIdentityStore.write(id);
    } catch (_) {
      // 安全存储不可用时不伪装成已缓存，表单下次仍显示红色的未缓存状态。
    }
  }

  static Future<bool> hasIdentity(SyncPlatform platform) async {
    try {
      await accountFor(platform);
      return await AwmcQuickIdentityStore.read() != null;
    } catch (_) {
      return false;
    }
  }

  static Future<void> forgetIdentity() async {
    await AwmcQuickIdentityStore.forget();
  }

  /// 只用二维码绑定机台身份，供快速同步首次启用时使用。
  ///
  /// `/v1/user/data` 只读取基础用户信息（含 userId），不会读取成绩、
  /// 游玩次数，也不会向任何目标查分器推送数据。二维码本身不落盘，
  /// 只把上游返回的 userId 写入安全存储。
  static Future<int> bindIdentityWithQr(String qrCode) async {
    final qrcode = qrCode.trim();
    if (!qrcode.startsWith('SGWCMAID') || qrcode.length <= 20) {
      throw const FormatException('无效的机台登入二维码');
    }
    final result = await AwmcApiService.userData(token: '', qrcode: qrcode);
    await AwmcAuditLog.record(result, note: '二维码绑定快速同步机台身份');
    if (!result.ok) {
      throw StateError('绑定机台身份失败：${result.displayMessage}');
    }
    final userId = _extractUserId(result.businessData);
    if (userId == null) {
      throw StateError('AWMC 返回成功但没有 userId，未缓存机台身份');
    }
    await AwmcQuickIdentityStore.write(userId);
    return userId;
  }

  static int? _extractUserId(dynamic value, [int depth = 0]) {
    if (depth > 8) return null;
    if (value is Map) {
      for (final entry in value.entries) {
        final key = '${entry.key}'.replaceAll('_', '').toLowerCase();
        if (key == 'userid') {
          final id = int.tryParse('${entry.value}');
          if (id != null && id > 0 && id <= 0xFFFFFFFF) return id;
        }
      }
      for (final child in value.values) {
        final id = _extractUserId(child, depth + 1);
        if (id != null) return id;
      }
    } else if (value is Iterable) {
      for (final child in value) {
        final id = _extractUserId(child, depth + 1);
        if (id != null) return id;
      }
    }
    return null;
  }

  static Future<AwmcQuickSyncResult> run({
    required SyncPlatform platform,
    void Function(double progress, String text)? onProgress,
    AwmcQuickReadSession? readSession,
  }) async {
    if (_running) throw StateError('快速同步正在进行中，请稍候');
    _running = true;
    SyncAttemptTracker? attempt;
    var syncOk = false;
    try {
      final account = await accountFor(platform);
      final userId = await AwmcQuickIdentityStore.read();
      if (userId == null) {
        throw StateError('用户凭据未缓存，请先输入二维码绑定机台身份');
      }
      // 先确认目标账号的本地归属，再读取同一目标服务，异步切换活动账号不改变回填来源。
      await AccountStore.recordsForAccount(account.source, account.id);
      // 集中在真实执行入口记一次，单端和多端共用；缺凭据等前置拒绝不计样本。
      attempt = SyncAttemptTracker(line: SyncLine.quick, platform: platform)
        ..start();
      onProgress?.call(.02, '正在读取${platform.label}已有的连击与同步标记…');
      final targetRecords = await _targetRecords(platform, account);
      final songs = await MaimaiMusicDataManager().getCachedSongs();
      if (songs == null || songs.isEmpty) throw StateError('请先更新曲库，再使用快速同步');
      onProgress?.call(.04, '正在核对${platform.label}支持的谱面…');
      final supportedCharts = await _targetCharts(platform);
      onProgress?.call(.05, '正在读取本轮机台成绩…');
      final incoming = readSession == null
          ? await _readScores(userId, onProgress)
          : await readSession._read(
              userId, () => _readScores(userId, onProgress));
      final records = AwmcQuickScore.backfill(incoming, targetRecords);
      final targetByKey = AwmcQuickScore.indexTargets(targetRecords);
      final byId = {for (final song in songs) int.tryParse(song.id): song};
      var submitted = 0;
      var skipped = 0;
      var unchanged = 0;
      final payload = <Map<String, dynamic>>[];
      for (final score in records) {
        final Song? song = byId[score.songId];
        if (song == null ||
            score.levelIndex >= song.charts.length ||
            !supportedCharts.contains(score.key)) {
          skipped++;
          continue;
        }
        if (score.matchesTarget(targetByKey[score.key])) {
          unchanged++;
          continue;
        }
        if (platform == SyncPlatform.awmc) {
          final index = score.levelIndex;
          final ds = index < song.ds.length ? song.ds[index] : 0.0;
          payload.add(RecordItem(
            achievements: score.percent,
            ds: ds,
            dxScore: score.dxScore,
            fc: score.fc ?? '',
            fs: score.fs ?? '',
            level: index < song.level.length ? song.level[index] : '',
            levelIndex: index,
            levelLabel: ChartDifficulty.legacyLabels[index],
            ra: SongInfoService().calculateSingleRating(ds, score.percent),
            rate: StringUtil.rateCodeFromAchievement(score.percent),
            songId: score.songId,
            title: song.title,
            type: score.type,
          ).toJson());
        } else {
          payload.add({
            'song_id': score.songId,
            'title': song.title,
            'type': score.type,
            'level_index': score.levelIndex,
            'achievements': score.percent,
            'dxScore': score.dxScore,
            if (score.fc != null) 'fc': score.fc,
            if (score.fs != null) 'fs': score.fs,
          });
        }
      }
      if (payload.isEmpty && unchanged == 0)
        throw StateError('有效成绩未匹配到本地曲库，未上传任何数据');
      // 每批串行上传；失败立即停止，不自动重试，避免不确定的重复写入。
      for (var start = 0; start < payload.length; start += 100) {
        final end = (start + 100).clamp(0, payload.length);
        onProgress?.call(.3 + .65 * start / payload.length,
            '正在更新${platform.label}成绩（$start/${payload.length}）…');
        await _upload(
            platform, account.credential, payload.sublist(start, end));
        submitted += end - start;
      }
      syncOk = true;
      onProgress?.call(
          1,
          '${submitted == 0 ? '成绩已是最新，无需上传' : '快速同步完成：更新 $submitted 条成绩'}'
          '${unchanged > 0 ? '，跳过 $unchanged 条未变化成绩' : ''}'
          '${skipped > 0 ? '，$skipped 条谱面未匹配或目标源不支持' : ''}');
      return AwmcQuickSyncResult(submitted, skipped, unchanged: unchanged);
    } finally {
      attempt?.finish(ok: syncOk);
      _running = false;
    }
  }

  static Future<List<AwmcQuickScore>> _readScores(int userId,
      void Function(double progress, String text)? onProgress) async {
    onProgress?.call(.05, '正在检查 AWMC 网关…');
    // 探活超时用户在设置页「同步与网关」里调整，默认 15 秒。
    final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
    final health = await AwmcApiService.health(
        token: '', timeout: probeTimeout);
    if (!health.ok) throw StateError('AWMC 网关暂不可用：${health.displayMessage}');
    final incoming = <String, AwmcQuickScore>{};
    final visited = <int>{};
    while (true) {
      if (!visited.add(0) || visited.length > 1)
        throw StateError('成绩分页异常，已终止更新');
      onProgress?.call(.2, '正在快速读取机台成绩…');
      final result =
          await AwmcApiService.rivalMusic(rivalId: userId, nextIndex: 0);
      if (!result.ok) {
        if (result.httpStatus == 404)
          throw StateError('服务端尚未开放快速同步接口，请更新服务端代理');
        if (result.httpStatus == 410)
          throw StateError('当前网关上游不支持免二维码读取，请使用普通同步');
        throw StateError('快速读取失败：${result.displayMessage}');
      }
      for (final score in AwmcQuickScore.parse(result.businessData)) {
        final old = incoming[score.key];
        incoming[score.key] = old == null
            ? score
            : AwmcQuickScore(
                score.songId,
                score.levelIndex,
                old.achievement > score.achievement
                    ? old.achievement
                    : score.achievement,
                old.dxScore > score.dxScore ? old.dxScore : score.dxScore,
                fc: score.fc ?? old.fc,
                fs: score.fs ?? old.fs);
      }
      final data = result.businessData;
      final next =
          data is Map ? int.tryParse('${data['nextIndex'] ?? 0}') ?? 0 : 0;
      if (next < 0) throw StateError('AWMC 网关返回了无效的成绩分页游标');
      if (next != 0) {
        throw StateError('AWMC 网关返回了分页结果，本次已停止读取，避免连续请求');
      }
      break;
    }
    if (incoming.isEmpty) throw StateError('没有读取到有效成绩，未上传任何数据');
    return List.unmodifiable(incoming.values);
  }

  /// 机台仍可能返回下架曲，union 也保留这些谱面；仅凭本地曲库会让落雪整批拒收。
  /// 各目标分别核对自己的最新曲库，不能用水鱼的曲库替其它源决定是否接收。
  static Future<Set<String>> _targetCharts(SyncPlatform platform) async {
    final url = switch (platform) {
      SyncPlatform.divingFish => ApiUrls.MusicDataApi,
      SyncPlatform.luoXue => ApiUrls.LuoXueSongsApi,
      SyncPlatform.awmc => ApiUrls.AwmcNetMusicDataApi,
    };
    final response = await ApiClient.get(Uri.parse(url),
        timeout: const Duration(seconds: 45));
    dynamic data;
    if (response.statusCode == 200) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {}
    }
    if (platform == SyncPlatform.luoXue && data is Map) data = data['songs'];
    if (data is! List) throw StateError('${platform.label}曲库读取失败，未上传成绩');
    final charts = <String>{};
    for (final song in data.whereType<Map>()) {
      final id = int.tryParse('${song['id']}');
      if (id == null || id <= 0 || id >= 100000) continue;
      if (platform == SyncPlatform.luoXue) {
        final difficulties = song['difficulties'];
        if (difficulties is! Map) continue;
        for (final type in ['standard', 'dx']) {
          final levels = difficulties[type];
          if (levels is! List) continue;
          final dx = type == 'dx';
          final songId = dx && id < 10000 ? id + 10000 : id;
          for (final level in levels.whereType<Map>()) {
            final index = int.tryParse('${level['difficulty']}');
            if (index != null && ChartDifficulty.isStandard(index)) {
              charts.add('$songId/$index/${dx ? 'DX' : 'SD'}');
            }
          }
        }
      } else {
        final levels = song['charts'];
        final type = '${song['type']}'.toUpperCase();
        if (levels is! List || (type != 'DX' && type != 'SD')) continue;
        for (var index = 0; index < levels.length; index++) {
          if (ChartDifficulty.isStandard(index)) charts.add('$id/$index/$type');
        }
      }
    }
    if (charts.isEmpty) throw StateError('${platform.label}曲库为空，未上传成绩');
    return charts;
  }

  /// 从目标服务读取最新标记；读取失败直接停止，不用其它源或旧缓存猜测。
  static Future<List<dynamic>> _targetRecords(
      SyncPlatform platform, AwmcQuickAccount account) async {
    final uri = switch (platform) {
      SyncPlatform.divingFish => Uri.parse(ApiUrls.UserPlayDataApi)
          .replace(queryParameters: {'qq': account.id}),
      SyncPlatform.luoXue => Uri.parse(ApiUrls.LuoXuePlayerScoresApi),
      SyncPlatform.awmc => Uri.parse(ApiUrls.AwmcNetRecordsProxyApi)
          .replace(queryParameters: {'qq': account.id}),
    };
    final response = await ApiClient.get(uri,
        headers: platform == SyncPlatform.luoXue
            ? {'X-User-Token': account.credential}
            : null,
        timeout: const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw StateError('${platform.label}现有成绩读取失败，未进行快速同步，请先检查该源的账号状态');
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {}
    for (var i = 0; i < 4 && data is Map; i++) {
      if (data['success'] == false) break;
      data = data['records'] ?? data['data'] ?? data['scores'];
    }
    if (data is! List) throw StateError('${platform.label}返回的成绩格式无效，未进行快速同步');
    // 兼容上传接口会把省略的标记视为空，不能把缺字段的异常响应当作“从未达成”。
    for (final record in data) {
      if (record is! Map ||
          int.tryParse(
                  '${record[platform == SyncPlatform.luoXue ? 'id' : 'song_id']}') ==
              null ||
          int.tryParse('${record['level_index']}') == null ||
          !record.containsKey('fc') ||
          !record.containsKey('fs')) {
        throw StateError('${platform.label}成绩缺少谱面或连击同步字段，未进行快速同步');
      }
    }
    if (platform != SyncPlatform.luoXue) return data;
    return data.whereType<Map>().map((record) {
      final id = int.tryParse('${record['id']}');
      final dx = '${record['type']}'.toLowerCase() == 'dx';
      return {
        'song_id': id == null ? null : (dx && id < 10000 ? id + 10000 : id),
        'level_index': record['level_index'],
        'type': dx ? 'DX' : 'SD',
        'fc': record['fc'],
        'fs': record['fs'],
        'achievements': record['achievements'],
        'dxScore': record['dx_score'] ?? record['dxScore'],
      };
    }).toList();
  }

  static Future<void> _upload(SyncPlatform platform, String credential,
      List<Map<String, dynamic>> records) async {
    final isLx = platform == SyncPlatform.luoXue;
    final url = switch (platform) {
      SyncPlatform.divingFish => ApiUrls.DivingFishUpdateRecordsApi,
      SyncPlatform.luoXue => ApiUrls.LuoXuePlayerScoresApi,
      SyncPlatform.awmc => ApiUrls.AwmcNetUpdateRecordsApi,
    };
    final body = isLx
        ? {
            'scores': records
                .map((r) => {
                      'id': (r['song_id'] as int) % 10000,
                      'type': r['type'] == 'DX' ? 'dx' : 'standard',
                      'level_index': r['level_index'],
                      'achievements': r['achievements'],
                      'dx_score': r['dxScore'],
                      if (r['fc'] != null) 'fc': r['fc'],
                      if (r['fs'] != null) 'fs': r['fs'],
                    })
                .toList()
          }
        : records;
    final response = await ApiClient.post(Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          isLx ? 'X-User-Token' : 'Import-Token': credential
        },
        body: jsonEncode(body),
        timeout: const Duration(seconds: 60));
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {}
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is! Map ||
        data['success'] == false ||
        data['status'] == 'error' ||
        (data['errors'] is List && (data['errors'] as List).isNotEmpty) ||
        (isLx && data['success'] != true)) {
      // 不回显第三方原始响应，避免请求凭据或机台身份被错误信息带出。
      throw StateError(
          '${platform.label}上传未成功（HTTP ${response.statusCode}），已停止后续批次；已提交批次可能已生效');
    }
  }
}
