import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../constant/CacheKeyConstant.dart';
import '../utils/ApiClient.dart';
import '../utils/SecureCredentialStore.dart';
import 'SyncStatsService.dart';
import 'AWMC/AwmcQuickIdentityStore.dart';
import 'AWMC/AwmcQuickSyncService.dart';
import 'AccountStore.dart';
import 'AccountSwitchService.dart';
import 'PostSyncRefreshService.dart';
import 'PlayerExperienceService.dart';
import '../utils/CurrentDataSourceNotifier.dart';

class AutoSyncException implements Exception {
  final String message;
  final String? code;
  const AutoSyncException(this.message, {this.code});
  @override
  String toString() => message;
}

DateTime? _syncDate(dynamic value) => value is num && value > 0
    ? DateTime.fromMillisecondsSinceEpoch(value.toInt(), isUtc: true)
    : null;

class AutoSyncQueue {
  final int waitingUsers;
  final int waitingTasks;
  final int runningTasks;
  final int? position;
  final int? userPosition;
  final DateTime? scheduledAt;
  final bool upcoming;
  final bool longQueue;
  final String? queueWarning;
  final AutoSyncPreviousQueue? previousQueue;
  const AutoSyncQueue(
      {required this.waitingUsers,
      required this.waitingTasks,
      required this.runningTasks,
      this.position,
      this.userPosition,
      this.scheduledAt,
      this.upcoming = false,
      this.longQueue = false,
      this.queueWarning,
      this.previousQueue});
  factory AutoSyncQueue.fromJson(Map data) => AutoSyncQueue(
      waitingUsers: (data['waitingUsers'] as num?)?.toInt() ?? 0,
      waitingTasks: (data['waitingTasks'] as num?)?.toInt() ?? 0,
      runningTasks: (data['runningTasks'] as num?)?.toInt() ?? 0,
      position: (data['position'] as num?)?.toInt(),
      userPosition: (data['userPosition'] as num?)?.toInt(),
      scheduledAt: _syncDate(data['scheduledAt']),
      upcoming: data['upcoming'] == true,
      longQueue: data['longQueue'] == true,
      queueWarning: data['queueWarning'] as String?,
      previousQueue: data['previousQueue'] is Map
          ? AutoSyncPreviousQueue.fromJson(data['previousQueue'])
          : null);
}

class AutoSyncPreviousQueue {
  final DateTime? scheduledAt;
  final int processedUsers;
  final int processedTasks;
  final int successUsers;
  final int failedUsers;
  final int submitted;
  final int skipped;
  final int unchanged;

  const AutoSyncPreviousQueue({
    this.scheduledAt,
    this.processedUsers = 0,
    this.processedTasks = 0,
    this.successUsers = 0,
    this.failedUsers = 0,
    this.submitted = 0,
    this.skipped = 0,
    this.unchanged = 0,
  });

  factory AutoSyncPreviousQueue.fromJson(Map data) => AutoSyncPreviousQueue(
        scheduledAt: _syncDate(data['scheduledAt']),
        processedUsers: (data['processedUsers'] as num?)?.toInt() ?? 0,
        processedTasks: (data['processedTasks'] as num?)?.toInt() ?? 0,
        successUsers: (data['successUsers'] as num?)?.toInt() ?? 0,
        failedUsers: (data['failedUsers'] as num?)?.toInt() ?? 0,
        submitted: (data['submitted'] as num?)?.toInt() ?? 0,
        skipped: (data['skipped'] as num?)?.toInt() ?? 0,
        unchanged: (data['unchanged'] as num?)?.toInt() ?? 0,
      );
}

class AutoSyncTiming {
  final DateTime? plannedAt;
  final DateTime? retryAt;
  final DateTime? collectedAt;

  /// 本轮第一次实际开始处理的时间；尚未开始时为空（排队等待不计入整轮时限）。
  final DateTime? startedAt;

  /// 服务端当前整轮处理时限（毫秒）；旧版本没有该字段时为空。
  final int? roundTimeoutMs;
  final String? waitReason;
  const AutoSyncTiming(
      {this.plannedAt,
      this.retryAt,
      this.collectedAt,
      this.startedAt,
      this.roundTimeoutMs,
      this.waitReason});
  bool get waiting => waitReason != null;
  factory AutoSyncTiming.fromJson(Map data) => AutoSyncTiming(
        plannedAt: _syncDate(data['plannedAt']),
        retryAt: _syncDate(data['retryAt']),
        collectedAt: _syncDate(data['collectedAt']),
        startedAt: _syncDate(data['startedAt']),
        roundTimeoutMs: (data['roundTimeoutMs'] as num?)?.toInt(),
        waitReason: data['waitReason'] as String?,
      );
}

class AutoSyncProgress {
  final String stage;
  final int completed;
  final int total;
  final int submitted;
  final int skipped;
  const AutoSyncProgress(
      {required this.stage,
      this.completed = 0,
      this.total = 0,
      this.submitted = 0,
      this.skipped = 0});
  factory AutoSyncProgress.fromJson(Map data) => AutoSyncProgress(
      stage: data['stage'] as String? ?? 'starting',
      completed: (data['completed'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      submitted: (data['submitted'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0);
  double? get value => total > 0 ? (completed / total).clamp(0.0, 1.0) : null;
  String get label => switch (stage) {
        'target_records' => '正在读取目标账号已有成绩…',
        'catalog' => '正在核对目标源支持的谱面…',
        'reading' => completed > 0 ? '正在读取机台成绩，已读取 $completed 页' : '正在读取机台成绩…',
        'preparing' => '正在整理谱面与连击、同步标记…',
        'uploading' =>
          '正在上传成绩（$completed / $total 条${submitted > 0 ? '，已提交 $submitted 条' : ''}）',
        'complete' => '同步完成',
        'waiting_quota' => '等待上游配额恢复…',
        'waiting_upstream' => '等待上游服务恢复…',
        _ => '正在准备快速同步…',
      };

  /// 按目标源细化的进度文案（页面详情用）：区分读取目标成绩、曲库、上传等阶段。
  String detailLabel(String platformLabel) => switch (stage) {
        'target_records' => '正在读取 $platformLabel 已有成绩…',
        'catalog' => '正在核对 $platformLabel 支持的谱面…',
        'reading' => completed > 0 ? '正在读取机台成绩，已读取 $completed 页' : '正在读取机台成绩…',
        'preparing' => '正在比对差异并整理上传内容…',
        'uploading' => '正在上传到$platformLabel：$completed / $total 条'
            '${submitted > 0 ? '，已提交 $submitted 条' : ''}',
        'complete' => '同步完成',
        'waiting_quota' => '等待上游配额恢复…',
        'waiting_upstream' => '等待上游服务恢复…',
        _ => '正在准备快速同步…',
      };
}

class AutoSyncRunResult {
  final String status;
  final String? error;
  final int submitted;
  final int skipped;
  final int unchanged;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  /// 本轮机台成绩快照的采集时间；没有采集到成绩时为空。
  final DateTime? collectedAt;

  /// 本轮结束时的整轮处理时限（毫秒），用于说明超时原因。
  final int? roundTimeoutMs;
  const AutoSyncRunResult(
      {required this.status,
      this.error,
      this.submitted = 0,
      this.skipped = 0,
      this.unchanged = 0,
      this.scheduledAt,
      this.startedAt,
      this.finishedAt,
      this.collectedAt,
      this.roundTimeoutMs});
  factory AutoSyncRunResult.fromJson(Map data) => AutoSyncRunResult(
      status: data['status'] as String? ?? 'failed',
      error: data['error'] as String?,
      submitted: (data['submitted'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
      unchanged: (data['unchanged'] as num?)?.toInt() ?? 0,
      scheduledAt: _syncDate(data['scheduledAt']),
      startedAt: _syncDate(data['startedAt']),
      finishedAt: _syncDate(data['finishedAt']),
      collectedAt: _syncDate(data['collectedAt']),
      roundTimeoutMs: (data['roundTimeoutMs'] as num?)?.toInt());
}

class AutoSyncTask {
  final bool enabled;
  final String status;
  final String? error;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final int submitted;
  final int skipped;
  final AutoSyncQueue? queue;
  final AutoSyncProgress? progress;
  final AutoSyncRunResult? lastResult;
  final AutoSyncTiming? timing;

  const AutoSyncTask(
      {this.enabled = false,
      this.status = 'disabled',
      this.error,
      this.nextRunAt,
      this.lastRunAt,
      this.submitted = 0,
      this.skipped = 0,
      this.queue,
      this.progress,
      this.lastResult,
      this.timing});

  /// 任务进程仍在运行，但当前是在等待上游（配额 / 服务恢复），不是在读写成绩。
  bool get waiting => status == 'running' && timing?.waitReason != null;

  factory AutoSyncTask.fromJson(Map<String, dynamic> data) {
    return AutoSyncTask(
        enabled: data['enabled'] == true,
        status: data['status'] as String? ?? 'disabled',
        error: data['error'] as String?,
        nextRunAt: _syncDate(data['nextRunAt']),
        lastRunAt: _syncDate(data['lastRunAt']),
        submitted: (data['submitted'] as num?)?.toInt() ?? 0,
        skipped: (data['skipped'] as num?)?.toInt() ?? 0,
        queue:
            data['queue'] is Map ? AutoSyncQueue.fromJson(data['queue']) : null,
        progress: data['progress'] is Map
            ? AutoSyncProgress.fromJson(data['progress'])
            : null,
        lastResult: data['lastResult'] is Map
            ? AutoSyncRunResult.fromJson(data['lastResult'])
            : ['success', 'failed'].contains(data['status']) &&
                    data['lastRunAt'] != null
                ? AutoSyncRunResult(
                    status: data['status'],
                    error: data['error'],
                    submitted: (data['submitted'] as num?)?.toInt() ?? 0,
                    skipped: (data['skipped'] as num?)?.toInt() ?? 0,
                    startedAt: _syncDate(data['lastRunAt']))
                : null,
        timing: data['timing'] is Map
            ? AutoSyncTiming.fromJson(data['timing'])
            : null);
  }
}

class AutoSyncRegistration {
  final SyncPlatform platform;
  final String source;
  final String accountId;
  final String _token;
  final bool lastKnownEnabled;
  final bool credentialPending;
  const AutoSyncRegistration(
      this.platform, this.source, this.accountId, this._token,
      {this.lastKnownEnabled = false, this.credentialPending = false});

  String get accountKey => '$source:$accountId';
  Map<String, dynamic> _toJson() => {
        'source': source,
        'accountId': accountId,
        'token': _token,
        'enabled': lastKnownEnabled,
        'credentialPending': credentialPending,
      };
}

/// 服务端托管定时任务；本机只在安全存储中保存独立的任务管理令牌。
/// 不使用共享开发者密钥，也不在偏好、备份或日志中保存任务令牌。
class AutoSyncService {
  AutoSyncService._();
  static final instance = AutoSyncService._();

  /// 设置变更后通知 Hub 摘要刷新；查询状态不会反复触发通知。
  static final changes = ValueNotifier<int>(0);

  /// 全站匿名队列汇总，不依赖本机是否绑定账号或开启任务。
  Future<AutoSyncQueue> queueOverview() async {
    try {
      final response = await ApiClient.get(
          Uri.parse(ApiUrls.AutoSyncOverviewUrl),
          timeout: const Duration(seconds: 15));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode != 200 ||
          data is! Map ||
          data['success'] != true ||
          data['queue'] is! Map) {
        throw const AutoSyncException('队列统计暂不可用，请稍后重试');
      }
      return AutoSyncQueue.fromJson(data['queue']);
    } catch (_) {
      throw const AutoSyncException('队列统计暂不可用，请稍后重试');
    }
  }

  Future<void> _writes = Future.value();
  final Map<SyncPlatform, Future<void>> _mutations = {};
  final Map<SyncPlatform, DateTime> _retryAfter = {};
  final Map<SyncPlatform, DateTime> _recoveryAfter = {};
  final Map<SyncPlatform, String> _credentialErrors = {};
  Future<void> _refreshQueue = Future<void>.value();
  final Set<String> _queuedRefreshes = {};
  final Map<SyncPlatform, String> _refreshErrors = {};
  String? refreshError(SyncPlatform platform) => _refreshErrors[platform];
  static const _personalKeys = {
    SyncPlatform.divingFish: CacheKeyConstant.probeDivingFishImportToken,
    SyncPlatform.luoXue: CacheKeyConstant.probeLxnsImportToken,
    SyncPlatform.awmc: CacheKeyConstant.awmcNetImportToken,
  };

  Future<T> _mutate<T>(SyncPlatform platform, Future<T> Function() action) {
    final next =
        (_mutations[platform] ?? Future<void>.value()).then((_) => action());
    _mutations[platform] = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<Map<String, dynamic>> _read() async {
    final raw =
        await SecureCredentialStore.read(CacheKeyConstant.autoSyncTasks);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    // 损坏的管理令牌不能被静默覆盖，否则会留下无法关闭的服务端任务。
    throw const AutoSyncException('自动同步设置读取失败，请保留本机数据后重试');
  }

  Future<void> _store(
      SyncPlatform platform, AutoSyncRegistration registration) {
    final next = _writes.then((_) async {
      final data = await _read();
      data[platform.key] = registration._toJson();
      await SecureCredentialStore.write(
          CacheKeyConstant.autoSyncTasks, jsonEncode(data));
    });
    _writes = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _remove(SyncPlatform platform) {
    final next = _writes.then((_) async {
      final data = await _read();
      data.remove(platform.key);
      if (data.isEmpty) {
        await SecureCredentialStore.delete(CacheKeyConstant.autoSyncTasks);
      } else {
        await SecureCredentialStore.write(
            CacheKeyConstant.autoSyncTasks, jsonEncode(data));
      }
    });
    _writes = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<AutoSyncRegistration?> registration(SyncPlatform platform) async {
    await _writes;
    final value = (await _read())[platform.key];
    if (value == null) return null;
    if (value is! Map ||
        value['token'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(value['token']) ||
        value['source'] is! String ||
        value['accountId'] is! String) {
      throw const AutoSyncException('自动同步凭据读取失败，请保留本机数据后重试');
    }
    return AutoSyncRegistration(
        platform, value['source'], value['accountId'], value['token'],
        lastKnownEnabled: value['enabled'] == true,
        credentialPending: value['credentialPending'] == true);
  }

  Future<AutoSyncTask> _request(
      String method, AutoSyncRegistration registration,
      {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse(
          '${ApiUrls.AutoSyncTaskUrl}${method == 'POST' ? '/credential' : ''}');
      final headers = {
        'Authorization': 'Bearer ${registration._token}',
        'Content-Type': 'application/json'
      };
      final response = switch (method) {
        'GET' => await ApiClient.get(uri,
            headers: headers, timeout: const Duration(seconds: 20)),
        'PUT' => await ApiClient.put(uri,
            headers: headers,
            body: body == null ? null : jsonEncode(body),
            timeout: const Duration(seconds: 90)),
        'POST' => await ApiClient.post(uri,
            headers: headers,
            body: jsonEncode(body),
            timeout: const Duration(seconds: 90)),
        _ => await ApiClient.delete(uri,
            headers: headers, timeout: const Duration(seconds: 20)),
      };
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {}
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          data is! Map ||
          data['success'] != true ||
          data['task'] is! Map ||
          data['task']['enabled'] is! bool) {
        final code = data is Map ? data['error']?.toString() : null;
        throw AutoSyncException(errorMessage(code), code: code);
      }
      final task =
          AutoSyncTask.fromJson(Map<String, dynamic>.from(data['task']));
      // Hub 会后台查询摘要，旧查询不能覆盖刚开启/关闭任务的本机凭据。
      if (method != 'GET') {
        if (!task.enabled) {
          await _remove(registration.platform);
        } else {
          await _store(
              registration.platform,
              AutoSyncRegistration(registration.platform, registration.source,
                  registration.accountId, registration._token,
                  lastKnownEnabled: true));
        }
        changes.value++;
        if (method == 'PUT' || method == 'POST') {
          unawaited(PlayerExperienceService.instance
              .onAccountAuthenticated(registration.accountKey));
        }
      }
      return task;
    } on AutoSyncException {
      rethrow;
    } catch (_) {
      // 不把 HTTP 异常或服务端原始响应带到 UI/日志中。
      throw const AutoSyncException('自动同步服务暂不可用，请检查网络后重试；设置状态尚未确认');
    }
  }

  Future<AutoSyncTask> status(SyncPlatform platform) async {
    final before = await registration(platform);
    final task = await _status(platform);
    final after = await registration(platform);
    if (after != null &&
        (before == null || before.accountKey == after.accountKey)) {
      // 状态轮询不等待完整刷新；同一轮只入队一次，所有源共享串行刷新队列。
      _observeCompleted(after, task);
    }
    return task;
  }

  void _observeCompleted(AutoSyncRegistration entry, AutoSyncTask task) {
    final result = task.lastResult;
    final finished = result?.finishedAt ?? result?.scheduledAt;
    final source = AwmcQuickSyncService.sourceOf(entry.platform);
    if (result?.status != 'success' ||
        finished == null ||
        entry.source != source.key ||
        CurrentDataSourceNotifier.instance.value != source) return;
    final stamp = '${entry.accountKey}:${finished.millisecondsSinceEpoch}';
    if (!_queuedRefreshes.add(stamp)) return;
    final revision = AccountSwitchService.revision;
    final next = _refreshQueue.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final marker = 'auto_sync_refreshed_${entry.platform.key}';
      if (prefs.getString(marker) == stamp ||
          CurrentDataSourceNotifier.instance.value != source ||
          AccountSwitchService.revision != revision) return;
      final current = (await AccountStore.loadAll())[source.key];
      final registration = await this.registration(entry.platform);
      if (current?.id != entry.accountId ||
          registration?._token != entry._token ||
          registration?.accountKey != entry.accountKey) return;
      final refresh = await PostSyncRefreshOperation.capture(source);
      if (AccountSwitchService.revision != revision ||
          CurrentDataSourceNotifier.instance.value != source) return;
      final error = await refresh.run(onProgress: (_, __) {});
      // 失败也记录本轮已处理，防止三秒轮询反复请求；用户仍可手动刷新。
      await prefs.setString(marker, stamp);
      if (error == null) {
        _refreshErrors.remove(entry.platform);
      } else {
        _refreshErrors[entry.platform] = error;
      }
      changes.value++;
    });
    _refreshQueue = next.then<void>((_) {
      _queuedRefreshes.remove(stamp);
    }, onError: (Object _) {
      _queuedRefreshes.remove(stamp);
      _refreshErrors[entry.platform] = '同步成功，本地数据刷新未完成，请手动刷新';
    });
  }

  Future<AutoSyncTask> _status(SyncPlatform platform) async {
    final entry = await registration(platform);
    if (entry == null)
      return await recoverIfAvailable(platform) ?? const AutoSyncTask();
    if (entry.credentialPending) {
      return _mutate(platform, () async {
        final latest = await registration(platform);
        if (latest == null) return const AutoSyncTask();
        if (!latest.credentialPending) return _request('GET', latest);
        if (_retryAfter[platform]?.isAfter(DateTime.now()) == true) {
          throw AutoSyncException(
              _credentialErrors[platform] ?? '个人 key 已保存在本机，定时任务待更新');
        }
        return _updatePersonalCredential(latest);
      });
    }
    return _request('GET', entry);
  }

  /// 本机管理令牌丢失后，用已保存的账号身份和机台 userId 找回任务。
  /// 没有匹配任务时短暂缓存结果，避免 Hub 轮询反复请求恢复接口。
  Future<AutoSyncTask?> _recoverIfAvailableUnserialized(
      SyncPlatform platform) async {
    if (_recoveryAfter[platform]?.isAfter(DateTime.now()) == true) {
      return null;
    }
    try {
      final account =
          await AwmcQuickSyncService.accountFor(platform, requireData: false);
      final userId = await AwmcQuickIdentityStore.read();
      if (userId == null) return null;
      final task = await _recoverTask(
          platform: platform,
          source: account.source.key,
          accountId: account.id,
          credential: account.credential,
          userId: userId);
      _recoveryAfter.remove(platform);
      return task;
    } on AutoSyncException catch (error) {
      if (error.code == 'task_not_found') {
        _recoveryAfter[platform] =
            DateTime.now().add(const Duration(seconds: 30));
        return null;
      }
      rethrow;
    } on StateError {
      _recoveryAfter[platform] =
          DateTime.now().add(const Duration(seconds: 30));
      return null;
    }
  }

  Future<AutoSyncTask?> recoverIfAvailable(SyncPlatform platform) =>
      _mutate(platform, () => _recoverIfAvailableUnserialized(platform));

  Future<AutoSyncTask> _updatePersonalCredential(
      AutoSyncRegistration entry) async {
    try {
      final account = (await AccountStore.loadAll())[entry.source];
      if (account != null && account.id != entry.accountId) {
        throw const AutoSyncException('账号已切换，请先关闭旧账号自动同步后重新开启');
      }
      final credential =
          await SecureCredentialStore.read(_personalKeys[entry.platform]!);
      if (credential == null || credential.trim().isEmpty) {
        throw const AutoSyncException('请重新保存该数据源的个人 key');
      }
      final task = await _request('POST', entry, body: {
        'platform': entry.platform.key,
        'accountId': entry.accountId,
        'credential': credential.trim(),
      });
      _retryAfter.remove(entry.platform);
      _credentialErrors.remove(entry.platform);
      return task;
    } catch (error) {
      final message =
          '个人 key 已保存在本机，定时任务待更新：${error is AutoSyncException ? error.message : '请检查网络后重试'}';
      _credentialErrors[entry.platform] = message;
      _retryAfter[entry.platform] =
          DateTime.now().add(const Duration(seconds: 30));
      throw AutoSyncException(message);
    }
  }

  Future<AutoSyncTask> _recoverTask({
    required SyncPlatform platform,
    required String source,
    required String accountId,
    required String credential,
    required int userId,
  }) async {
    final response = await ApiClient.post(
      Uri.parse('${ApiUrls.AutoSyncTaskUrl}/recover'),
      body: jsonEncode({
        'platform': platform.key,
        'accountId': accountId,
        'credential': credential,
        'userId': userId,
      }),
      headers: const {'Content-Type': 'application/json'},
      timeout: const Duration(seconds: 90),
    );
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {}
    final token = data is Map ? data['token']?.toString() : null;
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data is! Map ||
        data['success'] != true ||
        data['task'] is! Map ||
        data['task']['enabled'] is! bool ||
        token == null ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(token)) {
      final code = data is Map ? data['error']?.toString() : null;
      throw AutoSyncException(errorMessage(code), code: code);
    }
    await _store(
        platform,
        AutoSyncRegistration(platform, source, accountId, token,
            lastKnownEnabled: true));
    changes.value++;
    unawaited(PlayerExperienceService.instance
        .onAccountAuthenticated('$source:$accountId'));
    return AutoSyncTask.fromJson(Map<String, dynamic>.from(data['task']));
  }

  /// 先标记待更新，再保存新 key；断网或中途退出后仍可由状态查询恢复同步。
  Future<String> savePersonalCredential(SyncPlatform platform, String value) =>
      _mutate(platform, () async {
        final credential = value.trim();
        if (credential.isEmpty) throw const AutoSyncException('请输入个人 key');
        final entry = await registration(platform);
        if (entry != null) {
          await _store(
              platform,
              AutoSyncRegistration(
                  platform, entry.source, entry.accountId, entry._token,
                  lastKnownEnabled: entry.lastKnownEnabled,
                  credentialPending: true));
        }
        await SecureCredentialStore.write(_personalKeys[platform]!, credential);
        if (entry == null) return '个人 key 已保存';
        try {
          final task = await _updatePersonalCredential(entry);
          return task.enabled ? '个人 key 已保存，并已更新定时任务' : '个人 key 已保存，自动同步保持关闭';
        } on AutoSyncException catch (error) {
          changes.value++;
          return error.message;
        }
      });

  /// 先关闭托管任务，再删除本机 key；关闭失败时保留本机管理能力和凭据。
  Future<String> clearPersonalCredential(SyncPlatform platform) =>
      _mutate(platform, () async {
        var entry = await registration(platform);
        if (entry == null) {
          await _recoverIfAvailableUnserialized(platform);
          entry = await registration(platform);
        }
        if (entry != null) await _request('DELETE', entry);
        await SecureCredentialStore.delete(_personalKeys[platform]!);
        _retryAfter.remove(platform);
        _credentialErrors.remove(platform);
        return entry == null ? '个人 key 已清除' : '个人 key 已清除，并已关闭对应自动同步';
      });

  Future<AutoSyncTask> enable(
          {required SyncPlatform platform,
          required String source,
          required String accountId,
          required String credential,
          required int userId}) =>
      _mutate(platform, () async {
        var entry = await registration(platform);
        if (entry != null && entry.accountId != accountId) {
          await _request('DELETE', entry);
          entry = null;
        }
        if (entry == null) {
          final random = Random.secure();
          final token = base64UrlEncode(
                  List<int>.generate(32, (_) => random.nextInt(256)))
              .replaceAll('=', '');
          entry = AutoSyncRegistration(platform, source, accountId, token);
          // 先可靠保存，再请求服务器，网络超时后仍能查询或关闭已创建的任务。
          await _store(platform, entry);
        }
        try {
          return await _request('PUT', entry, body: {
            'platform': platform.key,
            'accountId': accountId,
            'credential': credential,
            'userId': userId
          });
        } on AutoSyncException catch (error) {
          if (error.code != 'already_registered') rethrow;
          return _recoverTask(
              platform: platform,
              source: source,
              accountId: accountId,
              credential: credential,
              userId: userId);
        }
      });

  Future<AutoSyncTask> disable(SyncPlatform platform) =>
      _mutate(platform, () async {
        var entry = await registration(platform);
        if (entry == null) {
          await _recoverIfAvailableUnserialized(platform);
          entry = await registration(platform);
        }
        if (entry == null) return const AutoSyncTask();
        return _request('DELETE', entry);
      });

  Future<void> disableForAccountKey(String accountKey) async {
    for (final platform in SyncPlatform.values) {
      final entry = await registration(platform);
      if (entry?.accountKey == accountKey) await disable(platform);
    }
  }

  Future<void> disableForSource(String source) async {
    for (final platform in SyncPlatform.values) {
      final entry = await registration(platform);
      if (entry?.source == source) await disable(platform);
    }
  }

  static String errorMessage(String? code) => switch (code) {
        'target_records_failed' => '目标账号成绩或同步凭据校验失败，请检查该数据源的账号状态',
        'already_registered' => '已有自动同步任务，正在尝试恢复当前用户的管理权限',
        'task_not_found' => '没有找到匹配的自动同步任务，请重新开启',
        'task_running' => '任务正在执行中，请稍后再恢复管理权限',
        'account_changed' => '任务绑定的账号已变化，请先关闭自动同步再重新开启',
        'invalid_config' => '快速同步凭据不完整，请先输入二维码绑定机台身份',
        'rate_limited' => '操作过于频繁，请稍后重试',
        'catalog_failed' => '目标数据源曲库读取失败，本次未继续同步',
        'upload_failed' => '成绩上传失败，部分批次可能已提交；本次不自动重试',
        'upload_credential_invalid' =>
          'AWMC NET 的 Import-Token 无效，请在账号管理重新保存有效 Token，已开启的定时任务会自动更新',
        'gateway_failed' => '机台成绩读取失败，请稍后重试',
        'unexpected_pagination' => '上游返回了分页成绩，本轮已停止读取，避免连续请求',
        'no_scores' || 'no_matching_scores' => '未读取到目标数据源支持的有效成绩',
        'interrupted' => '服务重启中断了上次同步，将在下次定时时间继续',
        'cancelled' => '自动同步设置已变化，请刷新状态',
        'run_timeout' => '本次同步处理超时，已停止并将在下次定时时间继续',
        'capacity_reached' => '当前自动同步容量已满，请稍后再开启',
        'quota_unavailable' || 'quota_wait' => '上游配额暂不可确认或已用尽，任务会在恢复后继续',
        'upstream_wait' || 'gateway_suspended' => '上游服务暂不可用，任务已暂停，恢复后继续',
        'window_expired' => '本次上午处理窗口已结束，将在下一轮继续',
        'upload_uncertain' => '上传结果暂不确定，下一轮会先核对后处理',
        _ => '自动同步服务暂不可用，请稍后重试',
      };
}
