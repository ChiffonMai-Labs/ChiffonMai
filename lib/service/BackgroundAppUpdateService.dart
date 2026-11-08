import 'package:my_first_flutter_app/l10n/NativeAppText.dart';
import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AppUpdateDownloadService.dart';
import 'BackgroundExportService.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUpdateDownloadDialog.dart';
import '../utils/AppVersion.dart';
import '../utils/AppTaskActivity.dart';
import '../utils/HomeRefreshNotifier.dart';
import 'Portable/PortablePlayerController.dart';
import 'AppUpdateAutoInstallSettings.dart';
import '../l10n/LocalizationsExtension.dart';
import '../widgets/AppUpdateInstallPrompt.dart';
import '../widgets/AppUpdateSuccessDialog.dart';

/// 全 App 共用任务状态，页面关闭只停止展示，不取消系统下载。
class BackgroundAppUpdateService extends ChangeNotifier
    with WidgetsBindingObserver {
  static final instance = BackgroundAppUpdateService._();
  BackgroundAppUpdateService._();

  Map<String, dynamic> state = {};
  AppUpdateDownloadService? _preparer;
  Timer? _poll;
  bool _initialized = false,
      _refreshing = false,
      _dialogOpen = false,
      _starting = false;
  Map<String, dynamic>? _lastInfo;
  bool _foreground = true;
  int _generation = 0;
  String? _lastNotice;
  bool? _reportedBusy;
  static const _promptPreference = 'app_update_foreground_prompt';
  final ValueNotifier<bool> _activityBusy = ValueNotifier(false);
  final _autoSettings = AppUpdateAutoInstallSettings.instance;
  bool _promptScheduled = false, _checkingPrompt = false, _promptOpen = false;
  String? _lastForegroundPrompt;
  Map<String, dynamic>? _installedUpdate;
  String? _lastSuccessPrompt;
  Animation<double>? _waitingEntrance;
  late final _updateObserver =
      _UpdatePromptNavigationObserver(_scheduleForegroundPrompt);
  NavigatorObserver get navigationObserver => _updateObserver;

  String get _downloadKey =>
      '${state['downloadId']}:${state['version']}:${state['build']}';

  String get phase => '${state['phase'] ?? ''}';
  bool get active => const [
        'preparing',
        'downloading',
        'verifying',
        'installing'
      ].contains(phase);

  void initialize() {
    if (!Platform.isAndroid || _initialized) return;
    _initialized = true;
    AppTaskActivity.count.addListener(_reportAppActivity);
    HomeRefreshNotifier.isBusy.addListener(_reportAppActivity);
    PortablePlayerController().addListener(_reportAppActivity);
    _autoSettings.addListener(_scheduleForegroundPrompt);
    unawaited(_autoSettings.load());
    _reportAppActivity();
    WidgetsBinding.instance.addObserver(this);
    AppUpdateDownloadService.channel.setMethodCallHandler((call) async {
      if (call.method == 'onUpdateAction') await refresh();
    });
    unawaited(refresh());
  }

  void _reportAppActivity() {
    final player = PortablePlayerController();
    final busy = AppTaskActivity.count.value > 0 ||
        HomeRefreshNotifier.isBusy.value ||
        player.isPlaying ||
        player.isLoading ||
        player.isBuffering;
    _activityBusy.value = busy;
    if (!busy) _scheduleForegroundPrompt();
    if (_reportedBusy == busy) return;
    _reportedBusy = busy;
    unawaited(AppUpdateDownloadService.channel.invokeMethod<void>(
        'setAppTaskBusy', {'busy': busy}).catchError((Object error) {
      if (_reportedBusy == busy) _reportedBusy = null;
      debugPrint('[AppUpdate] 上报任务状态失败: $error');
    }));
  }

  void _publish(Map<String, dynamic> next) {
    if (jsonEncode(state) != jsonEncode(next)) {
      state = next;
      notifyListeners();
    }
    _poll?.cancel();
    if (active && _foreground) {
      _poll = Timer(const Duration(seconds: 2), () => unawaited(refresh()));
    }
    final notice = '${state['build']}:$phase:${state['autoManualRequired']}';
    if (phase == 'ready') _scheduleForegroundPrompt();
    if (_foreground &&
        !_dialogOpen &&
        notice != _lastNotice &&
        (phase == 'ready' || phase == 'failed')) {
      _lastNotice = notice;
      if (phase != 'ready' ||
          !_autoSettings.enabled ||
          state['autoManualRequired'] == true) {
        AppToast.show(
            nativeAppText(
                '${state['message'] ?? appL10n.flowUpdateDownloadedInstallWhenConvenient}'),
            actionLabel: phase == 'ready'
                ? appL10n.flowViewInstallation
                : appL10n.flowView,
            onAction: showStatus);
      }
    }
  }

  bool get _canPrompt =>
      _foreground &&
      phase == 'ready' &&
      state['autoManualRequired'] != true &&
      state['downloadId'] is num &&
      !_dialogOpen &&
      !_promptOpen &&
      (_installedUpdate == null || _installedUpdate!['id'] == _lastSuccessPrompt) &&
      !_activityBusy.value;

  bool get _canShowInstalledUpdate =>
      _foreground &&
      _installedUpdate != null &&
      _installedUpdate!['id'] != _lastSuccessPrompt &&
      !_dialogOpen &&
      !_promptOpen;

  void _scheduleForegroundPrompt() {
    if (!_initialized ||
        _promptScheduled ||
        _checkingPrompt ||
        (!_canPrompt && !_canShowInstalledUpdate)) return;
    _promptScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptScheduled = false;
      unawaited(_canShowInstalledUpdate
          ? maybePromptForInstalledUpdate()
          : maybePromptForReadyUpdate());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _onEntranceStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _waitingEntrance?.removeStatusListener(_onEntranceStatus);
    _waitingEntrance = null;
    _scheduleForegroundPrompt();
  }

  bool get _pageReady {
    final route = _updateObserver.topRoute;
    if (route is! PageRoute || !route.isCurrent) return false;
    final entrance = route.animation;
    if (entrance != null && !entrance.isCompleted) {
      if (_waitingEntrance != entrance) {
        _waitingEntrance?.removeStatusListener(_onEntranceStatus);
        _waitingEntrance = entrance;
        entrance.addStatusListener(_onEntranceStatus);
      }
      return false;
    }
    return true;
  }

  /// 自动安装成功后的首次提示，主页面入场完成后显示，不与其它弹窗叠加。
  Future<void> maybePromptForInstalledUpdate() async {
    if (_checkingPrompt || !_canShowInstalledUpdate || !_pageReady) return;
    _checkingPrompt = true;
    final success = _installedUpdate!;
    final id = success['id'] as String;
    try {
      final installed = await PackageInfo.fromPlatform();
      // 后来又手动安装了别的版本时，旧的成功记录不再属于当前版本。
      if ('${success['build']}' != installed.buildNumber ||
          success['version'] != installed.version) {
        _lastSuccessPrompt = id;
        await _acknowledgeInstalledUpdate(id);
        return;
      }
      if (!_canShowInstalledUpdate ||
          !_pageReady ||
          _installedUpdate?['id'] != id) return;
      final context =
          BackgroundExport.navigatorKey.currentState?.overlay?.context;
      if (context == null || !context.mounted) return;
      _promptOpen = true;
      _lastSuccessPrompt = id;
      var acknowledging = false;
      await showDialog<void>(
        context: context,
        builder: (_) {
          if (!acknowledging) {
            acknowledging = true;
            // 弹窗真正构建后再确认，尚未展示的记录留给下次进入。
            WidgetsBinding.instance.addPostFrameCallback((_) {
              unawaited(_acknowledgeInstalledUpdate(id));
            });
          }
          return AppUpdateSuccessDialog(
            version: installed.version,
            buildNumber: installed.buildNumber,
            updateLog: '${success['updateLog'] ?? ''}',
          );
        },
      );
    } catch (error) {
      debugPrint('[AppUpdate] 自动更新成功提示失败: $error');
    } finally {
      _promptOpen = false;
      _checkingPrompt = false;
      _scheduleForegroundPrompt();
    }
  }

  Future<void> _acknowledgeInstalledUpdate(String id) async {
    try {
      final acknowledged = await AppUpdateDownloadService.channel
          .invokeMethod<bool>('acknowledgeAutoInstallSuccess', {'id': id});
      if (acknowledged == true && _installedUpdate?['id'] == id) {
        _installedUpdate = null;
      }
    } catch (error) {
      debugPrint('[AppUpdate] 保存自动更新提示状态失败: $error');
    }
  }

  Future<void> _readInstalledUpdate() async {
    try {
      final raw = await AppUpdateDownloadService.channel
          .invokeMethod<String>('getPendingAutoInstallSuccess');
      final decoded = raw == null ? null : jsonDecode(raw);
      _installedUpdate = decoded is Map &&
              decoded['id'] is String &&
              (decoded['id'] as String).isNotEmpty &&
              decoded['version'] is String &&
              decoded['build'] is num
          ? Map<String, dynamic>.from(decoded)
          : null;
    } on MissingPluginException {
      // 热重载到旧原生包时，原有下载与安装功能仍可继续使用。
    } catch (error) {
      debugPrint('[AppUpdate] 读取自动更新成功记录失败: $error');
    }
  }

  /// 下载完成或返回前台时检查；不叠在其它对话框上，同一下载只自动提示一次。
  Future<void> maybePromptForReadyUpdate() async {
    if (_checkingPrompt ||
        !_canPrompt ||
        !_pageReady ||
        _lastForegroundPrompt == _downloadKey) return;
    _checkingPrompt = true;
    final key = _downloadKey;
    try {
      final settings = await AppUpdateDownloadService.channel
          .invokeMapMethod<String, dynamic>('getAutoInstallSettings');
      if (settings?['enabled'] != true ||
          settings?['supported'] != true ||
          settings?['canInstall'] != true ||
          settings?['busy'] == true) return;
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getString(_promptPreference) == key) {
        _lastForegroundPrompt = key;
        return;
      }
      if (_lastForegroundPrompt == key ||
          !_canPrompt ||
          !_pageReady ||
          _downloadKey != key) return;
      final context =
          BackgroundExport.navigatorKey.currentState?.overlay?.context;
      if (context != null && context.mounted)
        await confirmForegroundInstall(context);
    } catch (error) {
      debugPrint('[AppUpdate] 前台更新提示准备失败: $error');
    } finally {
      _checkingPrompt = false;
      if (_downloadKey != key) _scheduleForegroundPrompt();
    }
  }

  void deferForegroundPrompt() {
    if (phase != 'ready') return;
    final key = _downloadKey;
    _lastForegroundPrompt = key;
    unawaited(() async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(_promptPreference, key);
      } catch (error) {
        debugPrint('[AppUpdate] 保存前台提示记录失败: $error');
      }
    }());
  }

  Future<bool> confirmForegroundInstall(BuildContext context) async {
    if (_promptOpen || phase != 'ready' || !_foreground) return false;
    final key = _downloadKey;
    final downloadId = state['downloadId'], build = state['build'];
    final version = '${state['version']}';
    _promptOpen = true;
    try {
      final choice = showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            AppUpdateInstallPrompt(version: version, busy: _activityBusy),
      );
      deferForegroundPrompt();
      if (await choice != true || !context.mounted) return false;
      if (!_foreground ||
          phase != 'ready' ||
          _downloadKey != key ||
          _activityBusy.value) {
        AppToast.show(context.l10n.foregroundUpdateChanged);
        return false;
      }
      final result = await AppUpdateDownloadService.channel
          .invokeMethod<String>('requestForegroundInstall',
              {'downloadId': downloadId, 'build': build});
      return result == 'requested';
    } catch (error) {
      debugPrint('[AppUpdate] 前台安装请求失败: $error');
      if (context.mounted) AppToast.show(context.l10n.foregroundUpdateFailed);
      return false;
    } finally {
      _promptOpen = false;
    }
  }

  Future<void> refresh() async {
    if (_refreshing || _preparer != null) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final raw = await AppUpdateDownloadService.channel
          .invokeMethod<String>('getUpdateState');
      if (generation != _generation) return;
      var next = Map<String, dynamic>.from(jsonDecode(raw ?? '{}') as Map);
      await _readInstalledUpdate();
      if (generation != _generation) return;
      if (const ['downloading', 'verifying', 'ready', 'installing']
              .contains(next['phase']) &&
          next['version'] is String) {
        final installed = await PackageInfo.fromPlatform();
        if (generation != _generation) return;
        if ((AppVersion.compare(next['version'], installed.version) ?? 0) < 0) {
          final cancelled = await AppUpdateDownloadService.channel
              .invokeMethod<String>('cancelBackgroundDownload');
          if (generation != _generation) return;
          next =
              Map<String, dynamic>.from(jsonDecode(cancelled ?? '{}') as Map);
        }
      }
      // 发布信息尚未交给系统时的失败也需要保留，便于用户返回后重试。
      if (!(next.isEmpty &&
          phase == 'failed' &&
          state['urls'] == null &&
          _lastInfo != null)) {
        _publish(next);
      }
      final pending = await AppUpdateDownloadService.channel
          .invokeMethod<bool>('takePendingUpdateAction');
      if (pending == true) showStatus();
    } catch (error) {
      debugPrint('[AppUpdate] 无法读取后台下载状态: $error');
    } finally {
      _refreshing = false;
      _scheduleForegroundPrompt();
      if (active && _foreground && _poll?.isActive != true) {
        _poll = Timer(const Duration(seconds: 2), () => unawaited(refresh()));
      }
    }
  }

  Future<void> start(Map<String, dynamic> info) =>
      AppTaskActivity.run(() async {
        initialize();
        if (_starting || _preparer != null) {
          showStatus();
          return;
        }
        _starting = true;
        await refresh();
        _starting = false;
        if (active) {
          showStatus();
          return;
        }
        if (phase == 'ready' && state['build'] == info['latestBuild']) {
          showStatus();
          return;
        }
        final generation = ++_generation;
        _lastInfo = Map<String, dynamic>.from(info);
        final service = AppUpdateDownloadService();
        _preparer = service;
        _lastNotice = null;
        _publish({
          'phase': 'preparing',
          'version': info['latestVersion'],
          'build': info['latestBuild'],
          'message': '正在准备后台下载…'
        });
        AppToast.show(appL10n.flowPreparingTheUpdateInTheBackgroundYou,
            actionLabel: appL10n.flowView, onAction: showStatus);
        try {
          final next = await service.startBackgroundDownload(
            version: '${info['latestVersion']}',
            build: (info['latestBuild'] as num).toInt(),
            updateLog: '${info['updateLog'] ?? ''}',
            releaseTag: info['githubReleaseTag'] as String?,
            configuredProxies: info['githubProxyPrefixes'],
            downloadProxies: info['githubDownloadProxyPrefixes'],
            onProgress: (message, _, __) {
              if (generation == _generation)
                _publish({...state, 'message': message});
            },
          );
          if (generation == _generation) _publish(next);
        } catch (error) {
          if (generation == _generation)
            _publish({
              ...state,
              'phase': 'failed',
              'message': error is FormatException
                  ? error.message
                  : error is PlatformException
                      ? error.message ?? '无法开始后台下载'
                      : '无法开始后台下载，请重试'
            });
        } finally {
          if (_preparer == service) _preparer = null;
          service.cancel(); // 只释放已完成的发布信息请求，系统下载由 DownloadManager 独立持有。
        }
      });

  Future<void> cancel() async {
    _generation++;
    _preparer?.cancel();
    _preparer = null;
    final raw = await AppUpdateDownloadService.channel
        .invokeMethod<String>('cancelBackgroundDownload');
    _publish(Map<String, dynamic>.from(jsonDecode(raw ?? '{}') as Map));
  }

  Future<void> retry() async {
    if (state['urls'] == null && _lastInfo != null) {
      await start(_lastInfo!);
      return;
    }
    final raw = await AppUpdateDownloadService.channel
        .invokeMethod<String>('retryBackgroundDownload');
    _lastNotice = null;
    _publish(Map<String, dynamic>.from(jsonDecode(raw ?? '{}') as Map));
  }

  void showStatus() {
    final context =
        BackgroundExport.navigatorKey.currentState?.overlay?.context;
    if (_dialogOpen || context == null || !context.mounted) return;
    _dialogOpen = true;
    showDialog(
        context: context,
        builder: (_) => const AppUpdateDownloadDialog()).whenComplete(() {
      _dialogOpen = false;
      _scheduleForegroundPrompt();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(refresh());
      _scheduleForegroundPrompt();
    } else {
      _poll?.cancel();
    }
  }
}

class _UpdatePromptNavigationObserver extends NavigatorObserver {
  final VoidCallback onChanged;
  Route<dynamic>? topRoute;
  _UpdatePromptNavigationObserver(this.onChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    topRoute = route;
    onChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    topRoute = previousRoute;
    onChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (topRoute == oldRoute) topRoute = newRoute;
    onChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (topRoute == route) topRoute = previousRoute;
    onChanged();
  }
}
