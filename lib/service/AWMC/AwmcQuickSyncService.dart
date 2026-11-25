import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import '../../utils/AppTaskActivity.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../api/ApiUrls.dart';
import '../../constant/CacheKeyConstant.dart';
import '../../entity/DivingFish/Song.dart';
import '../../utils/ChartDifficulty.dart';
import '../../manager/DivingFish/MaimaiMusicDataManager.dart';
import '../../manager/LuoXue/LuoXueOAuthManager.dart';
import '../../utils/ApiClient.dart';
import '../../utils/AppError.dart';
import '../../utils/CurrentDataSourceNotifier.dart';
import '../../utils/SecureCredentialStore.dart';
import '../AccountStore.dart';
import '../SyncStatsService.dart';
import 'AwmcApiService.dart';
import 'AwmcGatewaySettings.dart';
import 'AwmcQrSyncService.dart';
import 'AwmcQuickIdentityStore.dart';
import 'AwmcStore.dart';
import 'AwmcQuickSyncCore.dart';

class AwmcQuickAccount {
  final RefreshDataSource source;
  final String id;
  final String? credential;
  final bool useOAuth;
  const AwmcQuickAccount(
    this.source,
    this.id,
    this.credential, {
    this.useOAuth = false,
  });
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

/// 水鱼（OAuth）/ 落雪（OAuth 优先）/ AWMC NET（Bot）的快速同步，FC/FS 始终按同一目标账号合并。
class AwmcQuickSyncService {
  AwmcQuickSyncService._();
  static bool _running = false;

  static RefreshDataSource sourceOf(SyncPlatform platform) =>
      switch (platform) {
        SyncPlatform.divingFish => RefreshDataSource.shuiyu,
        SyncPlatform.luoXue => RefreshDataSource.luoxue,
        SyncPlatform.awmc => RefreshDataSource.awmc,
      };

  static Future<AwmcQuickAccount> accountFor(
    SyncPlatform platform, {
    bool requireData = true,
    bool forAutoSync = false,
  }) async {
    final source = sourceOf(platform);
    final account = (await AccountStore.loadAll())[source.key];
    final storedId = account?.id.trim() ?? '';

    if (platform == SyncPlatform.divingFish) {
      if (requireData) {
        if (account == null || account.id.isEmpty) {
          throw AppError(
            code: 'AUTH-SYNC-ACCOUNT-MISSING',
            userMessage: appL10n.svcSetUpYourP0AccountFirst(
                (appLocalizeLabel(platform.label)).toString()),
            stage: '校验快速同步账号',
            source: source.key,
            retryable: false,
          ).asStateError();
        }
        if (!account.hasData) {
          throw AppError(
            code: 'DATA-SYNC-NEED-REFRESH',
            userMessage: appL10n.svcRefreshYourP0AccountDataBeforeUsing(
                (appLocalizeLabel(platform.label)).toString()),
            stage: '校验快速同步缓存',
            source: source.key,
            retryable: false,
          ).asStateError();
        }
      }
      final qq = AwmcQrSyncService.normalizeDivingFishQq(storedId) ??
          await AwmcQrSyncService.resolveDivingFishQq();
      if (qq == null || qq.isEmpty) {
        throw AppError(
          code: 'AUTH-SYNC-ACCOUNT-MISSING',
          userMessage: appL10n.svcSetUpYourP0AccountFirst(
              (appLocalizeLabel(platform.label)).toString()),
          stage: '校验快速同步账号',
          source: source.key,
          retryable: false,
        ).asStateError();
      }
      return AwmcQuickAccount(
        source,
        storedId.isNotEmpty ? storedId : qq,
        null,
        useOAuth: true,
      );
    }

    if (platform == SyncPlatform.awmc) {
      if (requireData) {
        if (account == null || account.id.isEmpty) {
          throw AppError(
            code: 'AUTH-SYNC-ACCOUNT-MISSING',
            userMessage: appL10n.svcSetUpYourP0AccountFirst(
                (appLocalizeLabel(platform.label)).toString()),
            stage: '校验快速同步账号',
            source: source.key,
            retryable: false,
          ).asStateError();
        }
        if (!account.hasData) {
          throw AppError(
            code: 'DATA-SYNC-NEED-REFRESH',
            userMessage: appL10n.svcRefreshYourP0AccountDataBeforeUsing(
                (appLocalizeLabel(platform.label)).toString()),
            stage: '校验快速同步缓存',
            source: source.key,
            retryable: false,
          ).asStateError();
        }
      }
      final qq = AwmcQrSyncService.qqPattern.hasMatch(storedId)
          ? storedId
          : await AwmcQrSyncService.resolveAwmcNetQq();
      if (qq == null || !AwmcQrSyncService.qqPattern.hasMatch(qq)) {
        throw AppError(
          code: 'AUTH-SYNC-ACCOUNT-MISSING',
          userMessage: appL10n.svcSetUpYourP0AccountFirst(
              (appLocalizeLabel(platform.label)).toString()),
          stage: '校验快速同步账号',
          source: source.key,
          retryable: false,
        ).asStateError();
      }
      return AwmcQuickAccount(
        source,
        qq,
        null,
        useOAuth: true,
      );
    }

    // 落雪：自动同步由服务端执行，必须使用个人 API 密钥；手动快速同步优先使用官方 OAuth。
    if (account == null || account.id.isEmpty) {
      throw AppError(
        code: 'AUTH-SYNC-ACCOUNT-MISSING',
        userMessage: appL10n.svcSetUpYourP0AccountFirst(
            (appLocalizeLabel(platform.label)).toString()),
        stage: '校验快速同步账号',
        source: source.key,
        retryable: false,
      ).asStateError();
    }
    if (requireData && !account.hasData) {
      throw AppError(
        code: 'DATA-SYNC-NEED-REFRESH',
        userMessage: appL10n.svcRefreshYourP0AccountDataBeforeUsing(
            (appLocalizeLabel(platform.label)).toString()),
        stage: '校验快速同步缓存',
        source: source.key,
        retryable: false,
      ).asStateError();
    }
    final personalKey = (await SecureCredentialStore.read(
            CacheKeyConstant.probeLxnsImportToken))
        ?.trim();
    if (forAutoSync) {
      if (personalKey == null || personalKey.isEmpty) {
        throw AppError(
          code: 'AUTH-SYNC-CRED-MISSING',
          userMessage: appL10n.svcSetUpTheSyncCredentialsForP0(
              (appLocalizeLabel(platform.label)).toString()),
          stage: '校验自动同步凭据',
          source: source.key,
          retryable: false,
        ).asStateError();
      }
      return AwmcQuickAccount(source, account.id, personalKey);
    }
    if (await LuoXueOAuthManager().isLoggedIn()) {
      return AwmcQuickAccount(source, account.id, personalKey, useOAuth: true);
    }
    if (personalKey != null && personalKey.isNotEmpty) {
      return AwmcQuickAccount(source, account.id, personalKey);
    }
    throw AppError(
      code: 'AUTH-LXNS-NOT-AUTHORIZED',
      userMessage: appL10n.svcYourLXNSAccountIsNotAuthorizedComplete,
      stage: '校验落雪同步授权',
      source: source.key,
      suggestion: appL10n.errSuggestionReauth,
      retryable: false,
    ).asStateError();
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
      if (current == null || current.key != account.key) return;
      await AwmcQuickIdentityStore.write(id);
    } catch (_) {
      // 安全存储不可用时不伪装成已缓存，表单下次仍显示红色的未缓存状态。
    }
  }

  /// 该数据源能否使用快速同步：可以时返回 null，否则返回具体原因（缺账号、缺 OAuth 写入授权或账号未刷新）。
  static Future<String?> accountIssue(SyncPlatform platform) async {
    try {
      final account = await accountFor(platform);
      if (platform == SyncPlatform.divingFish) {
        final qq = AwmcQrSyncService.normalizeDivingFishQq(account.id) ??
            await AwmcQrSyncService.resolveDivingFishQq();
        if (qq == null) {
          return appL10n.svcSetUpYourP0AccountFirst(
              (appLocalizeLabel(platform.label)).toString());
        }
        final writeAuth = await AwmcQrSyncService.checkFishWriteAuthorized(qq);
        if (writeAuth == false) {
          return appL10n.flowDivingFishWriteConsentRequiredMessage;
        }
      }
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
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
      throw AppError(
        code: 'SRV-AWMC-BIND-IDENTITY',
        userMessage: appL10n
            .flowCouldNotLinkCabinetIdentityP0(result.displayMessage.toString()),
        stage: '绑定机台身份',
        source: 'awmc',
        httpStatus: result.httpStatus > 0 ? result.httpStatus : null,
      ).asStateError();
    }
    final userId = _extractUserId(result.businessData);
    if (userId == null) {
      throw AppError(
        code: 'SRV-AWMC-USER-ID-MISSING',
        userMessage: appL10n.svcAWMCReportedSuccessWithoutAUserIdThe,
        stage: '解析机台身份',
        source: 'awmc',
      ).asStateError();
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
    AwmcQuickServerResponse? prefetchedServerQuickSync,
  }) =>
      AppTaskActivity.run(() async {
        if (_running) {
          throw AppError(
            code: 'SYNC-QUICK-BUSY',
            userMessage: appL10n.svcQuickSyncIsInProgressPleaseWait,
            stage: '启动快速同步',
            source: platform.name,
            retryable: true,
          ).asStateError();
        }
        _running = true;
        SyncAttemptTracker? attempt;
        var syncOk = false;
        try {
          final account = await accountFor(platform);
          final userId = await AwmcQuickIdentityStore.read();
          if (userId == null) {
            throw AppError(
              code: 'AUTH-QUICK-IDENTITY-MISSING',
              userMessage: appL10n.svcUserCredentialsAreNotCachedEnterA,
              stage: '读取机台身份',
              source: platform.name,
              retryable: false,
            ).asStateError();
          }
          // 先确认目标账号的本地归属，再读取同一目标服务，异步切换活动账号不改变回填来源。
          await AccountStore.recordsForAccount(account.source, account.id);
          // 集中在真实执行入口记一次，单端和多端共用；缺凭据等前置拒绝不计样本。
          attempt = SyncAttemptTracker(line: SyncLine.quick, platform: platform)
            ..start();

          if (platform == SyncPlatform.divingFish ||
              platform == SyncPlatform.awmc) {
            final fishQq = platform == SyncPlatform.divingFish
                ? (AwmcQrSyncService.normalizeDivingFishQq(account.id) ??
                    await AwmcQrSyncService.resolveDivingFishQq())
                : null;
            final awmcQq = platform == SyncPlatform.awmc ? account.id : null;
            onProgress?.call(.15, appL10n.flowQuicklyReadingCabinetScores);
            final serverRes = prefetchedServerQuickSync ??
                await AwmcQrSyncService.quickSyncViaServer(
                  userId: userId,
                  fishQq: fishQq,
                  awmcQq: awmcQq,
                );
            final targetRes = platform == SyncPlatform.divingFish
                ? serverRes.fish
                : serverRes.awmc;
            if (targetRes == null) {
              if (serverRes.fishConsentRequired) {
                throw AppError(
                  code: 'AUTH-FISH-CONSENT',
                  stage: 'AWMC 快速同步',
                  source: 'shuiyu',
                  httpStatus: serverRes.httpStatus,
                  requestId: serverRes.requestId,
                  userMessage: appL10n.flowDivingFishWriteConsentRequiredMessage,
                  suggestion: appL10n.errSuggestionReauth,
                ).asStateError();
              }
              if (serverRes.error != null) {
                throw serverRes.error!.asStateError();
              }
              throw AppError(
                code: serverRes.code != null
                    ? 'SYNC-${serverRes.code}'
                    : 'SYNC-QUICK-FAILED',
                stage: 'AWMC 快速同步',
                source: platform.name,
                httpStatus: serverRes.httpStatus > 0 ? serverRes.httpStatus : null,
                requestId: serverRes.requestId,
                userMessage: serverRes.errorMessage ??
                    appL10n.svcQuickReadFailedP0(
                        serverRes.code ?? 'HTTP ${serverRes.httpStatus}'),
              ).asStateError();
            }
            if (!targetRes.ok) {
              if (targetRes.code == 'FISH_CONSENT_REQUIRED') {
                throw AppError(
                  code: 'AUTH-FISH-CONSENT',
                  stage: '水鱼写入校验',
                  source: 'shuiyu',
                  httpStatus: targetRes.httpStatus,
                  requestId: serverRes.requestId,
                  userMessage: appL10n.flowDivingFishWriteConsentRequiredMessage,
                  suggestion: appL10n.errSuggestionReauth,
                ).asStateError();
              }
              throw AppError(
                code: targetRes.code != null
                    ? 'SYNC-${targetRes.code}'
                    : 'SYNC-TARGET-UPLOAD',
                stage: '上传至目标平台',
                source: platform.name,
                httpStatus: targetRes.httpStatus ?? 502,
                requestId: serverRes.requestId,
                userMessage: targetRes.message ??
                    appL10n.svcUploadToP0FailedHTTPP1Remaining(
                      appLocalizeLabel(platform.label),
                      '${targetRes.httpStatus ?? 502}',
                    ),
              ).asStateError();
            }
            syncOk = true;
            onProgress?.call(
                1,
                '${targetRes.submitted == 0 ? appL10n.flowScoresAreUpToDateNoUpload : appL10n.flowQuickSyncCompleteUpdatedP0Scores((targetRes.submitted).toString())}'
                '${targetRes.unchanged > 0 ? appL10n.flowSkippedP0UnchangedScores((targetRes.unchanged).toString()) : ''}'
                '${targetRes.skipped > 0 ? appL10n.flowP0ChartsUnmatchedOrUnsupported((targetRes.skipped).toString()) : ''}');
            return AwmcQuickSyncResult(
              targetRes.submitted,
              targetRes.skipped,
              unchanged: targetRes.unchanged,
            );
          }

          onProgress?.call(
              .02,
              appL10n.flowReadingComboAndSyncMarkersFromP0(
                  appLocalizeLabel(platform.label)));
          final targetRecords = await _targetRecords(platform, account);
          final songs = await MaimaiMusicDataManager().getCachedSongs();
          if (songs == null || songs.isEmpty) {
            throw AppError(
              code: 'DATA-SYNC-SONGS-EMPTY',
              userMessage: appL10n.svcUpdateTheSongLibraryBeforeUsingQuick,
              stage: '读取本地曲库',
              source: 'local',
              retryable: false,
            ).asStateError();
          }
          onProgress?.call(
              .04,
              appL10n.flowCheckingChartsSupportedByP02(
                  appLocalizeLabel(platform.label)));
          final supportedCharts = await _targetCharts(platform);
          onProgress?.call(.05, appL10n.flowReadingCabinetScoresForThisRound);
          final List<AwmcQuickScore> incoming;
          if (prefetchedServerQuickSync != null &&
              prefetchedServerQuickSync.lxScores.isNotEmpty) {
            incoming = prefetchedServerQuickSync.lxScores
                .map((s) => AwmcQuickScore(
                      s.songId,
                      s.levelIndex,
                      s.achievement,
                      s.dxScore,
                      fc: s.fc,
                      fs: s.fs,
                    ))
                .toList(growable: false);
          } else {
            incoming = readSession == null
                ? await _readScores(userId, onProgress)
                : await readSession._read(
                    userId, () => _readScores(userId, onProgress));
          }
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
          if (payload.isEmpty && unchanged == 0) {
            throw AppError(
              code: 'DATA-SYNC-NO-MATCH',
              userMessage: appL10n.svcNoValidScoresMatchedTheLocalSong,
              stage: '匹配本地曲库',
              source: platform.name,
            ).asStateError();
          }
          // 每批串行上传；失败立即停止，不自动重试，避免不确定的重复写入。
          for (var start = 0; start < payload.length; start += 100) {
            final end = (start + 100).clamp(0, payload.length);
            onProgress?.call(
                .3 + .65 * start / payload.length,
                appL10n.flowUpdatingP0ScoresP1P2(
                    appLocalizeLabel(platform.label),
                    (start).toString(),
                    (payload.length).toString()));
            await _upload(account, payload.sublist(start, end));
            submitted += end - start;
          }
          syncOk = true;
          onProgress?.call(
              1,
              '${submitted == 0 ? appL10n.flowScoresAreUpToDateNoUpload : appL10n.flowQuickSyncCompleteUpdatedP0Scores((submitted).toString())}'
              '${unchanged > 0 ? appL10n.flowSkippedP0UnchangedScores((unchanged).toString()) : ''}'
              '${skipped > 0 ? appL10n.flowP0ChartsUnmatchedOrUnsupported((skipped).toString()) : ''}');
          return AwmcQuickSyncResult(submitted, skipped, unchanged: unchanged);
        } finally {
          attempt?.finish(ok: syncOk);
          _running = false;
        }
      });

  static Future<List<AwmcQuickScore>> _readScores(int userId,
      void Function(double progress, String text)? onProgress) async {
    onProgress?.call(.05, appL10n.flowCheckingAWMCGateway2);
    // 探活超时用户在设置页「同步与网关」里调整，默认 15 秒。
    final probeTimeout = await AwmcGatewaySettings.loadProbeTimeout();
    final health =
        await AwmcApiService.health(token: '', timeout: probeTimeout);
    if (!health.ok) {
      throw AppError(
        code: 'SRV-AWMC-GATEWAY',
        userMessage: appL10n
            .svcTheAWMCGatewayIsUnavailableP0(health.displayMessage.toString()),
        stage: '检查 AWMC 网关',
        source: 'awmc',
        httpStatus: health.httpStatus > 0 ? health.httpStatus : null,
      ).asStateError();
    }
    final incoming = <String, AwmcQuickScore>{};
    final visited = <int>{};
    while (true) {
      if (!visited.add(0) || visited.length > 1) {
        throw AppError(
          code: 'SYNC-QUICK-PAGING',
          userMessage: appL10n.svcScorePagingWasAbnormalTheUpdateStopped,
          stage: '读取机台成绩分页',
          source: 'awmc',
        ).asStateError();
      }
      onProgress?.call(.2, appL10n.flowQuicklyReadingCabinetScores);
      final result =
          await AwmcApiService.rivalMusic(rivalId: userId, nextIndex: 0);
      if (!result.ok) {
        if (result.httpStatus == 404) {
          throw AppError(
            code: 'SRV-AWMC-UNSUPPORTED',
            userMessage: appL10n.svcTheServerDoesNotOfferQuickSync,
            stage: '读取机台成绩',
            source: 'awmc',
            httpStatus: 404,
            retryable: false,
          ).asStateError();
        }
        if (result.httpStatus == 410) {
          throw AppError(
            code: 'SRV-AWMC-QR-REQUIRED',
            userMessage: appL10n.svcTheCurrentGatewayUpstreamCannotReadWithout,
            stage: '读取机台成绩',
            source: 'awmc',
            httpStatus: 410,
            retryable: false,
          ).asStateError();
        }
        throw AppError(
          code: 'SRV-AWMC-GATEWAY',
          userMessage:
              appL10n.svcQuickReadFailedP0(result.displayMessage.toString()),
          stage: '读取机台成绩',
          source: 'awmc',
          httpStatus: result.httpStatus > 0 ? result.httpStatus : null,
        ).asStateError();
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
      if (next < 0) {
        throw AppError(
          code: 'SRV-AWMC-INVALID-DATA',
          userMessage: appL10n.svcTheAWMCGatewayReturnedAnInvalidScore,
          stage: '解析机台成绩',
          source: 'awmc',
        ).asStateError();
      }
      if (next != 0) {
        throw AppError(
          code: 'SYNC-QUICK-PAGING',
          userMessage: appL10n.svcTheAWMCGatewayReturnedPagedResultsReading,
          stage: '解析机台成绩分页',
          source: 'awmc',
        ).asStateError();
      }
      break;
    }
    if (incoming.isEmpty) {
      throw AppError(
        code: 'DATA-SYNC-NO-SCORES',
        userMessage: appL10n.svcNoValidScoresWereReadNothingWas,
        stage: '解析机台成绩',
        source: 'awmc',
      ).asStateError();
    }
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
    if (data is! List) {
      throw AppError(
        code: 'SRV-SYNC-SONG-LIST',
        userMessage: appL10n.svcCouldNotReadTheP0SongLibrary(
            (appLocalizeLabel(platform.label)).toString()),
        stage: '读取目标曲库',
        source: sourceOf(platform).key,
        httpStatus: response.statusCode != 200 ? response.statusCode : null,
        requestId: ApiClient.requestIdOf(response),
      ).asStateError();
    }
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
    if (charts.isEmpty) {
      throw AppError(
        code: 'DATA-SYNC-SONG-LIST-EMPTY',
        userMessage: appL10n.svcTheP0SongLibraryIsEmptyNo(
            (appLocalizeLabel(platform.label)).toString()),
        stage: '校验目标曲库',
        source: sourceOf(platform).key,
      ).asStateError();
    }
    return charts;
  }

  static Future<Map<String, String>> _lxAuthHeaders(AwmcQuickAccount account,
      {bool forceRefresh = false}) async {
    if (account.useOAuth) {
      final token = forceRefresh
          ? (await LuoXueOAuthManager().refreshToken())?.accessToken
          : await LuoXueOAuthManager().getAccessToken();
      if (token != null && token.isNotEmpty) {
        return {'Authorization': 'Bearer $token'};
      }
    }
    final fallbackKey = account.credential?.trim();
    if (fallbackKey != null && fallbackKey.isNotEmpty) {
      return {'X-User-Token': fallbackKey};
    }
    throw AppError(
      code: 'AUTH-LXNS-EXPIRED',
      userMessage: appL10n.svcLXNSAuthorizationExpiredOrTheKeyIs,
      stage: '校验落雪同步授权',
      source: 'luoxue',
      suggestion: appL10n.errSuggestionReauth,
      retryable: false,
    ).asStateError();
  }

  /// 从落雪读取最新标记；读取失败直接停止，不用其它源或旧缓存猜测。
  static Future<List<dynamic>> _targetRecords(
      SyncPlatform platform, AwmcQuickAccount account) async {
    final uri = Uri.parse(ApiUrls.LuoXuePlayerScoresApi);
    var headers = await _lxAuthHeaders(account);
    var response = await ApiClient.get(uri,
        headers: headers, timeout: const Duration(seconds: 45));
    if (account.useOAuth && response.statusCode == 401) {
      headers = await _lxAuthHeaders(account, forceRefresh: true);
      response = await ApiClient.get(uri,
          headers: headers, timeout: const Duration(seconds: 45));
    }
    if (response.statusCode != 200) {
      throw AppError(
        code: 'SRV-LXNS-READ-SCORES',
        userMessage: appL10n.svcCouldNotReadExistingP0ScoresSo(
            (appLocalizeLabel(platform.label)).toString()),
        stage: '读取目标已有成绩',
        source: 'luoxue',
        httpStatus: response.statusCode,
        requestId: ApiClient.requestIdOf(response),
      ).asStateError();
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {}
    for (var i = 0; i < 4 && data is Map; i++) {
      if (data['success'] == false) break;
      data = data['records'] ?? data['data'] ?? data['scores'];
    }
    if (data is! List) {
      throw AppError(
        code: 'SRV-LXNS-INVALID-SCORES',
        userMessage: appL10n.svcP0ReturnedScoresInAnInvalidFormat(
            (appLocalizeLabel(platform.label)).toString()),
        stage: '解析目标已有成绩',
        source: 'luoxue',
      ).asStateError();
    }
    // 兼容上传接口会把省略的标记视为空，不能把缺字段的异常响应当作“从未达成”。
    for (final record in data) {
      if (record is! Map ||
          int.tryParse('${record['id']}') == null ||
          int.tryParse('${record['level_index']}') == null ||
          !record.containsKey('fc') ||
          !record.containsKey('fs')) {
        throw AppError(
          code: 'SRV-LXNS-INCOMPLETE-SCORES',
          userMessage: appL10n.svcP0ScoresAreMissingChartOrCombo(
              (appLocalizeLabel(platform.label)).toString()),
          stage: '校验目标已有成绩字段',
          source: 'luoxue',
        ).asStateError();
      }
    }
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

  static Future<void> _upload(
      AwmcQuickAccount account, List<Map<String, dynamic>> records) async {
    final uri = Uri.parse(ApiUrls.LuoXuePlayerScoresApi);
    final body = jsonEncode({
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
    });
    Future<http.Response> send(Map<String, String> authHeaders) => ApiClient.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            ...authHeaders,
          },
          body: body,
          timeout: const Duration(seconds: 60),
        );
    var response = await send(await _lxAuthHeaders(account));
    if (account.useOAuth && response.statusCode == 401) {
      response = await send(await _lxAuthHeaders(account, forceRefresh: true));
    }
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {}
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is! Map ||
        data['success'] != true) {
      // 不回显第三方原始响应，避免请求凭据或机台身份被错误信息带出。
      throw AppError(
        code: 'SRV-LXNS-UPLOAD',
        userMessage: appL10n.svcUploadToP0FailedHTTPP1Remaining(
            (appLocalizeLabel(SyncPlatform.luoXue.label)).toString(),
            response.statusCode.toString()),
        stage: '上传成绩至落雪',
        source: 'luoxue',
        httpStatus: response.statusCode,
        requestId: ApiClient.requestIdOf(response),
      ).asStateError();
    }
  }
}
