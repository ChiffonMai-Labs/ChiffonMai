import 'utils/CurrentDataSourceNotifier.dart';
import 'utils/AppLanguagePreferences.dart';
import 'utils/RatingSegmentPreferences.dart';
import 'utils/SongDetailPreferences.dart';
import 'l10n/app_localizations.dart';
import 'service/PlayerExperienceService.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:my_first_flutter_app/manager/LZYCheckUpdateManager.dart';
import 'package:my_first_flutter_app/page/AppEntryPage.dart';
import 'package:my_first_flutter_app/page/AppShell.dart';
import 'package:my_first_flutter_app/page/SplashPage.dart';
import 'package:my_first_flutter_app/service/Portable/PortablePlayerController.dart';
import 'package:my_first_flutter_app/utils/AppTheme.dart';
import 'package:my_first_flutter_app/utils/ExportSettings.dart';
import 'package:my_first_flutter_app/utils/FavoriteFeaturesNotifier.dart';
import 'package:my_first_flutter_app/utils/FavoriteImportFlow.dart';
import 'package:my_first_flutter_app/utils/LoginStateNotifier.dart';
import 'package:my_first_flutter_app/utils/SecureCredentialStore.dart';

import 'package:my_first_flutter_app/utils/ThemeManager.dart';
import 'package:my_first_flutter_app/utils/UpdateNotifier.dart';
import 'package:my_first_flutter_app/utils/UserProfileNotifier.dart';
import 'package:my_first_flutter_app/service/ConnectivityService.dart';
import 'package:my_first_flutter_app/widgets/PortablePlayerBadge.dart';
import 'package:my_first_flutter_app/utils/NavigationPreferences.dart';
import 'service/AccountSwitchService.dart';
import 'service/LogExportService.dart';
import 'utils/WindowDiagnostics.dart';
import 'widgets/AppToast.dart';
import 'package:my_first_flutter_app/widgets/Best50Ui.dart';
import 'package:my_first_flutter_app/service/BackgroundExportService.dart';
import 'package:my_first_flutter_app/service/CrashReportService.dart';
import 'service/BackgroundAppUpdateService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LogExportService.instance.install();
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(MyApp());
  // 首次引导只准备主题和引导状态，其他服务由入口页在引导结束后启动。
}

Future<void> _initStartupServices() async {
  try {
    await SecureCredentialStore.migrateLegacy();
    await AccountSwitchService.ensureMigrated();
    await CurrentDataSourceNotifier.load();
    await Future.wait([
      Best50DisplayPreference.load(),
      FavoriteFeaturesNotifier.load(),
      LoginStateNotifier.load(),
      UserProfileNotifier.load(),
      ExportSettings.load(),
      NavigationPreferences.instance.load(),
      SongDetailPreferences.instance.load(),
      RatingSegmentPreferences.instance.load(),
    ]);
  } catch (e) {
    debugPrint('[Startup] 后台初始化失败（不影响首页交互）: $e');
  }
  await _initBackgroundAudio();
}

/// 初始化随身听的后台播放（通知栏 / 锁屏 / 耳机按键控制）。
///
/// 必须先于任何 `AudioPlayer` 创建：先在 Android 侧注册 MediaSession 与前台服务。
/// 引导期间不创建播放器；进入主界面前完成初始化，确保通知栏仍能正常控制播放。
///
/// 依赖三处 Android 配置同时到位，缺一都会静默降级：
///   1. `AndroidManifest.xml` 声明 `com.ryanheise.audioservice.AudioService`
///      与 `MediaButtonReceiver`；
///   2. `MainActivity` 继承 `AudioServiceActivity`；
///   3. `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_MEDIA_PLAYBACK` / `WAKE_LOCK` 权限。
Future<void> _initBackgroundAudio() async {
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId:
          'com.example.my_first_flutter_app.channel.portable_audio',
      androidNotificationChannelName: '随身听播放',
      androidNotificationChannelDescription: '显示正在播放的曲目与播放控制',
      // 常驻通知：符合 QQ音乐那类播放器的行为，也避免被系统随手清掉
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    );
  } catch (e) {
    // 初始化失败不该拖垮整个 App：随身听退化成「只能前台播放」。
    debugPrint('[Portable] 后台播放初始化失败，退化为前台播放: $e');
  }
  PortablePlayerController().init();
}

/// 应用根组件：有状态组件，配置MaterialApp基础属性并管理初始化
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = BackgroundExport.navigatorKey;
  Future<void>? _mainPreparation;
  bool _backgroundServicesStarted = false;
  bool _themeLoaded = false;
  bool _fontsPrepared = false;
  Size? _lastWindowPhysicalSize;
  double? _lastWindowPixelRatio;
  String? _lastWindowPadding;
  bool _windowMetricsReportScheduled = false;
  Timer? _windowRepaintTimer;

  /// 收藏夹「一键导入」通道，与 MainActivity.kt 中的 IMPORT_CHANNEL 对应
  static const MethodChannel _openFileChannel =
      MethodChannel('com.example.app/open_file');

  /// 正在处理导入（避免冷启动时 pending + 实时推送把同一个文件导两次）
  bool _handlingIncoming = false;
  bool _initialImportChecked = false;
  String? _lastHandledPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTheme();
  }

  Future<void> _prepareMain() => _mainPreparation ??= _initStartupServices();

  void _startMainBackgroundServices() {
    if (!mounted || _backgroundServicesStarted) return;
    setState(() => _backgroundServicesStarted = true);
    // 主界面已呈现后再开启轮询、更新和导入监听，不与首次引导争用平台线程。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ConnectivityService().start();
      unawaited(PlayerExperienceService.instance.start());
      unawaited(_initFileOpenHandling());
      _checkUpdateForBadge();
      unawaited(CrashReportService.checkPreviousCrash());
      BackgroundAppUpdateService.instance.initialize();
    });
  }

  @override
  void dispose() {
    _windowRepaintTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
        '[Window] 生命周期 $state，framesEnabled=${WidgetsBinding.instance.framesEnabled}');
    if (state == AppLifecycleState.resumed) {
      unawaited(NavigationPreferences.instance.applySystemUiMode());
    }
  }

  @override
  void didChangeMetrics() {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view == null) return;
    // 只关注实际窗口尺寸/像素比；键盘动画仅改变 inset，不逐帧刷诊断日志。
    // 尺寸不变时安全区也可能变（issue #4：小窗恢复后报出比窗口还高的顶部安全区）。
    final padding = WindowDiagnostics.padding(view.padding);
    if (view.physicalSize == _lastWindowPhysicalSize &&
        view.devicePixelRatio == _lastWindowPixelRatio) {
      if (padding != _lastWindowPadding) {
        _lastWindowPadding = padding;
        debugPrint('[Window] 安全区变化 ${WindowDiagnostics.view(view)}');
      }
      return;
    }
    _lastWindowPadding = padding;
    final isResize = _lastWindowPhysicalSize != null;
    _lastWindowPhysicalSize = view.physicalSize;
    _lastWindowPixelRatio = view.devicePixelRatio;
    if (_windowMetricsReportScheduled) return;
    _windowMetricsReportScheduled = true;
    debugPrint('[Window] 窗口变化 ${WindowDiagnostics.view(view)} '
        'framesEnabled=${WidgetsBinding.instance.framesEnabled}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _windowMetricsReportScheduled = false;
      if (!mounted) return;
      final renderObject = _navigatorKey.currentContext?.findRenderObject();
      debugPrint('[Window] 窗口变化后帧已完成，Navigator='
          '${renderObject is RenderBox && renderObject.hasSize ? WindowDiagnostics.size(renderObject.size) : "尚未布局"} '
          '${WindowDiagnostics.renderTree()}');
      if (isResize) _scheduleWindowRepaint();
    });
  }

  /// 小窗 / 分屏切换后补画（issue #4）。系统的窗口动画要过一会儿才结束，
  /// 所以这一帧和稍后各补一次；连续变化时只保留最后一次的延迟补画。
  void _scheduleWindowRepaint() {
    WindowDiagnostics.forceRepaint();
    _windowRepaintTimer?.cancel();
    _windowRepaintTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      WindowDiagnostics.forceRepaint();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        debugPrint('[Window] 补画后 ${WindowDiagnostics.renderTree()}');
      });
    });
  }

  /// App 进入时检查一次更新，把结果写进 [UpdateNotifier]。
  ///
  /// 作用只是**点亮「发现新版本」按钮**（系统 Hub 页的「检查更新」会变成绿色圆环
  /// 箭头），不弹窗 —— AppEntryPage 在引导、公告结束后按「3 天内不提示」
  /// 的规则处理弹窗；两处共用同一次网络请求（checkUpdate 内部做了去重）。
  ///
  /// 刻意**不 await**：检查要联网，不能拖慢启动。
  void _checkUpdateForBadge() {
    unawaited(() async {
      try {
        final info = await LZYCheckUpdateManager().checkUpdate();
        UpdateNotifier.setResult(info);
      } catch (e) {
        debugPrint('[Update] 启动检查更新失败（忽略）: $e');
        UpdateNotifier.setResult(null);
      }
    }());
  }

  /// 注册「文件管理器点开收藏夹文件」的处理。
  ///
  /// 两条来源都会汇到 [_handleIncomingFile]：
  ///   1. 冷启动：App 没在跑，MainActivity 把路径暂存，这里主动取走；
  ///   2. 热启动：App 已在后台，MainActivity 通过 onFileOpened 直接推过来。
  Future<void> _initFileOpenHandling() async {
    _openFileChannel.setMethodCallHandler((call) async {
      if (call.method == 'onFileOpened') {
        final path = call.arguments as String?;
        if (path != null && path.isNotEmpty) {
          await _handleIncomingFile(path);
        }
      }
      return null;
    });

    try {
      final initial =
          await _openFileChannel.invokeMethod<String>('getInitialImportPath');
      if (initial != null && initial.isNotEmpty) {
        await _handleIncomingFile(initial);
      }
    } on MissingPluginException {
      // 非 Android 平台没有这个通道，正常忽略
    } catch (e) {
      debugPrint('[open_file] 读取启动导入文件失败: $e');
    } finally {
      _initialImportChecked = true;
    }
  }

  /// 等到 Navigator 的 Overlay 就绪，并返回它的 context。
  ///
  /// 这里刻意不用 `navigatorKey.currentContext`：那是 Navigator 自己的 context，
  /// 而 `Navigator.of` / `showDialog` 都是从**祖先**里找 NavigatorState，
  /// 拿它当 context 会找不到 Navigator。Overlay 的 context 位于 Navigator 之下，
  /// 是弹窗和导航都能正常工作的安全选择。
  Future<BuildContext?> _awaitNavigatorContext() async {
    for (var i = 0; i < 30; i++) {
      final ctx = _navigatorKey.currentState?.overlay?.context;
      if (ctx != null && ctx.mounted) return ctx;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  Future<void> _handleIncomingFile(String path) async {
    if (_handlingIncoming || path == _lastHandledPath) return;
    _handlingIncoming = true;
    _lastHandledPath = path;

    try {
      final ctx = await _awaitNavigatorContext();
      if (ctx == null || !ctx.mounted) {
        debugPrint('[open_file] 界面还没准备好，忽略导入: $path');
        return;
      }
      await runFavoriteImportFlow(ctx, presetPath: path);
    } catch (e) {
      debugPrint('[open_file] 处理导入文件失败: $e');
    } finally {
      _handlingIncoming = false;
    }
  }

  Future<void> _initTheme() async {
    await Future.wait([
      ThemeManager().loadThemePreference(),
      AppLanguagePreferences.instance.load(),
    ]);
    if (mounted) {
      setState(() => _themeLoaded = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_prepareStartupFonts());
      });
    }
  }

  Future<void> _prepareStartupFonts() async {
    if (!AppTheme.debugLocalFontFamily) {
      try {
        // 保留在线字体；先准备常用字重，避免引导刚出现就开始替换字体。
        final styles = <TextStyle>[
          for (final weight in [
            FontWeight.w400,
            FontWeight.w500,
            FontWeight.w600,
            FontWeight.w700,
            FontWeight.w800,
          ]) ...[
            GoogleFonts.outfit(fontWeight: weight),
            GoogleFonts.notoSansSc(fontWeight: weight),
          ],
        ];
        await GoogleFonts.pendingFonts(styles)
            .timeout(const Duration(milliseconds: 1200));
      } catch (error) {
        debugPrint('[Startup] 在线字体准备未完成，继续启动: $error');
      }
    }
    if (mounted) setState(() => _fontsPrepared = true);
  }

  ThemeData _buildThemeWithFonts(ThemeData base) {
    if (!_fontsPrepared) return base;
    // 统一走 AppTheme.withGlobalFonts：除了 textTheme，它还会给
    // appBarTheme.titleTextStyle 补上字体族 —— 否则标准 AppBar 的标题会被
    // AppBar 自己那层 DefaultTextStyle 顶回系统字体。详见 AppTheme.font 注释。
    return AppTheme.withGlobalFonts(base);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeManager().notifier,
        ThemeManager().pureBlackNotifier,
        ThemeManager().seedColorNotifier,
        ThemeManager().customBackgroundPathNotifier,
        NavigationPreferences.instance,
        AppLanguagePreferences.instance,
      ]),
      builder: (context, _) {
        final themeMode = ThemeManager().isLoaded
            ? ThemeManager().themeMode
            : ThemeMode.system;
        final pureBlack = ThemeManager().pureBlackEnabled;
        final seedColor = ThemeManager().seedColor;
        final lightThemeData =
            _buildThemeWithFonts(AppTheme.lightTheme(seedColor: seedColor));
        final darkThemeData = _buildThemeWithFonts(
          pureBlack
              ? AppTheme.pureBlackTheme(seedColor: seedColor)
              : AppTheme.darkTheme(seedColor: seedColor),
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          navigatorObservers: [
            _FocusClearingNavigatorObserver(),
            BackgroundAppUpdateService.instance.navigationObserver,
          ],
          home: !_themeLoaded || !_fontsPrepared
              ? const SplashPage(showBrand: false)
              : AppEntryPage(
                  prepareMain: _prepareMain,
                  onFirstFrameRendered: _startMainBackgroundServices,
                  canPresentStartup: () =>
                      _initialImportChecked && !_handlingIncoming),
          theme: lightThemeData,
          darkTheme: darkThemeData,
          themeMode: themeMode,
          locale: AppLanguagePreferences.instance.locale,
          localeListResolutionCallback: AppLanguagePreferences.resolveLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            final theme = Theme.of(context);
            return MediaQuery(
              data: WindowDiagnostics.sanitizePadding(MediaQuery.of(context))
                  .copyWith(textScaleFactor: 1.0),
              child: AnnotatedRegion<SystemUiOverlayStyle>(
                value: AppTheme.systemUiOverlayStyle(
                  theme.brightness,
                  navigationBarColor: theme.colorScheme.surface,
                ),
                child: DefaultTextStyle(
                  style: _fontsPrepared ? AppTheme.font() : const TextStyle(),
                  // 随身听悬浮球挂在**这里**（MaterialApp.builder），而不是
                  // AppShell 的 body 里 —— 这是关键：
                  //   MaterialApp.builder 包住的是 Navigator，所以悬浮球在**所有
                  //   路由之上**，任何 push 出来的功能页（乐曲查询、Best50、随身听…）
                  //   都能看到它。
                  //   之前放在 AppShell.body 里，功能页是 push 到 AppShell 之上的
                  //   新路由，球会被完全盖住 —— 表现就是「进具体功能页只听到声音、
                  //   看不到球」。
                  child: Stack(
                    children: [
                      if (child != null) child,
                      // 随身听悬浮球：自己判断该不该显示（没在放歌、
                      // 或随身听页面正开着时都返回空盒子）。
                      if (_backgroundServicesStarted)
                        Positioned.fill(
                          child: PortablePlayerBall(
                            // 这里的 context（builder 的）在 Navigator **之上**，
                            // 弹层/跳转都得用 Navigator 自己的 overlay context，
                            // 否则 `Navigator.of` 会抛「does not include a
                            // Navigator」—— 表现就是「点球没反应」。
                            navigatorKey: _navigatorKey,
                            onOpenLibrary: () {
                              final navigatorContext =
                                  _navigatorKey.currentState?.overlay?.context;
                              if (navigatorContext == null) {
                                return Future<void>.value();
                              }
                              return AppShell.openPortablePlayerPage(
                                navigatorContext,
                              );
                            },
                          ),
                        ),
                      // 轻提示同样挂在 Navigator 之上，对话框打开时也看得到。
                      const Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AppToastHost(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FocusClearingNavigatorObserver extends NavigatorObserver {
  void _clearFocusForPageRoute(Route<dynamic>? route) {
    if (route is PageRoute<dynamic>) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _clearFocusForPageRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    FocusManager.instance.primaryFocus?.unfocus();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _clearFocusForPageRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
