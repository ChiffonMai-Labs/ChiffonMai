import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/utils/UpdateNotifier.dart';
import 'package:my_first_flutter_app/utils/ExternalLaunchUtil.dart';
import '../constant/AppLinks.dart';
import '../utils/AppDesignTokens.dart';
import '../widgets/AppDialogs.dart';
import '../widgets/AppToast.dart';
import '../widgets/AppUpdateAutoInstallControl.dart';
import '../service/BackgroundAppUpdateService.dart';
import '../service/AppUpdateDownloadService.dart';
import '../utils/AppVersion.dart';
import '../utils/ApkPublishedVersion.dart';

void _updateLog(String message) {
  if (kDebugMode) debugPrint(message);
}

class LZYCheckUpdateManager {
  static final LZYCheckUpdateManager _instance =
      LZYCheckUpdateManager._internal();
  factory LZYCheckUpdateManager() => _instance;
  LZYCheckUpdateManager._internal();

  // ==================== 检查更新配置 =====================
  final String pastebinRawUrl = ApiUrls.checkUpdateApi;
  final bool forceUpdate = false;

  /// 默认以 app_version.json 为准；仅显式启用测试参数时改用 GitHub。
  /// 临时测试可通过 --dart-define=CHIFFONMAI_TEST_GITHUB_UPDATE=true 开启。
  static const bool useGitHubForUpdateCheck = bool.fromEnvironment(
    'CHIFFONMAI_TEST_GITHUB_UPDATE',
    defaultValue: false,
  );

  /// 兜底下载地址（检查更新失败时仍可复制）
  static const String defaultDownloadUrl =
      'https://wward.lanzouw.com/chiffonmai';

  /// 当前系统的兜底下载地址：iOS 下载无签名 IPA。
  static String get platformDownloadUrl =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? AppLinks.iosDownloadUrl
          : defaultDownloadUrl;
  // ======================================================

  /// 正常发布从 app_version.json 读取版本、构建号、日志和下载配置。
  Future<Map<String, dynamic>?> _getCloudConfig() async {
    try {
      // 创建自定义客户端，添加超时和User-Agent
      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse(pastebinRawUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final jsonStr = response.body.trim();
          _updateLog('获取更新配置成功（已隐藏响应正文）');
          return jsonDecode(jsonStr);
        } else {
          _updateLog("获取配置失败，状态码：${response.statusCode}");
        }
      } on SocketException catch (e) {
        _updateLog("网络连接失败：$e");
      } on HttpException catch (e) {
        _updateLog("HTTP异常：$e");
      } on FormatException catch (e) {
        _updateLog("数据格式错误：$e");
      } catch (e) {
        _updateLog("获取配置失败：$e");
      } finally {
        client.close();
      }
    } catch (e) {
      _updateLog("获取配置失败：$e");
    }
    return null;
  }

  Future<Map<String, dynamic>> _getGitHubConfig(PackageInfo installed) async {
    final client = http.Client();
    final proxies = AppUpdateDownloadService.proxyPrefixes(null);
    const headers = {
      'User-Agent': 'ChiffonMai-Updater',
      'Accept': 'application/vnd.github+json',
    };
    try {
      // 使用发布列表，测试版也参与检查；草稿和没有 APK 的发布不参与。
      final api = Uri.https('api.github.com',
          '/repos/${AppLinks.githubRepository}/releases', {'per_page': '20'});
      List<Map<String, dynamic>>? releases;
      for (final url
          in AppUpdateDownloadService.downloadUrls(api.toString(), proxies)) {
        try {
          final response = await client
              .get(Uri.parse(url), headers: headers)
              .timeout(const Duration(seconds: 10));
          if (response.statusCode != 200) continue;
          final decoded = jsonDecode(response.body);
          if (decoded is! List) continue;
          releases = decoded
              .whereType<Map>()
              .map((r) => Map<String, dynamic>.from(r))
              .where((r) =>
                  r['draft'] != true &&
                  AppVersion.compare('${r['tag_name']}', '0.0.0') != null &&
                  (r['assets'] as List? ?? []).whereType<Map>().any(
                      (a) => '${a['name']}'.toLowerCase().endsWith('.apk')))
              .toList();
          break;
        } catch (error) {
          _updateLog('GitHub 发布列表读取失败，尝试下一线路: $error');
        }
      }
      if (releases == null || releases.isEmpty) {
        throw FormatException(appL10n.svcCouldNotGetTheAPKVersionsPublished);
      }
      releases.sort((a, b) {
        DateTime published(Map release) =>
            DateTime.tryParse('${release['published_at']}') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final byDate = published(b).compareTo(published(a));
        return byDate != 0
            ? byDate
            : AppVersion.compare('${b['tag_name']}', '${a['tag_name']}')!;
      });
      final release = releases.first;
      final tag = release['tag_name'] as String;
      final abis = defaultTargetPlatform == TargetPlatform.android
          ? await AppUpdateDownloadService.channel
                  .invokeListMethod<String>('supportedAbis') ??
              []
          : ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];
      final asset = AppUpdateDownloadService.selectAsset(release, abis);
      if (Uri.parse(asset.url).pathSegments[4] != tag) {
        throw const FormatException('GitHub 附件与发布标签不一致');
      }
      final version =
          await ApkPublishedVersion.read(asset.size, (offset, length) async {
        for (final url
            in AppUpdateDownloadService.downloadUrls(asset.url, proxies)) {
          try {
            final request = http.Request('GET', Uri.parse(url))
              ..headers.addAll({
                'User-Agent': headers['User-Agent']!,
                'Accept': 'application/octet-stream',
                'Accept-Encoding': 'identity',
                'Range': 'bytes=$offset-${offset + length - 1}',
              });
            final response =
                await client.send(request).timeout(const Duration(seconds: 10));
            if (response.statusCode != 206 ||
                response.headers['content-range'] !=
                    'bytes $offset-${offset + length - 1}/${asset.size}') {
              // 不接受忽略 Range 的整包响应，检查阶段不得偷偷下载整个 APK。
              await response.stream.listen(null).cancel();
              continue;
            }
            final bytes = BytesBuilder(copy: false);
            await for (final chunk
                in response.stream.timeout(const Duration(seconds: 10))) {
              if (bytes.length + chunk.length > length) {
                throw const FormatException('APK 范围响应过大');
              }
              bytes.add(chunk);
            }
            if (bytes.length == length) return bytes.takeBytes();
          } catch (error) {
            _updateLog('GitHub APK 版本读取失败，尝试下一线路: $error');
          }
        }
        throw FormatException(appL10n.svcCouldNotReadTheActualVersionOf);
      });
      if (version.packageName != installed.packageName ||
          AppVersion.compare(version.version, tag) != 0) {
        throw FormatException(appL10n.svcTheAppOrVersionOfTheGitHub);
      }
      return {
        'version': version.version,
        'buildNumber': version.build,
        'updateLog': release['body'] ?? appL10n.svcExperienceImprovements,
        'downloadUrl': Uri.https(
                'github.com', '/${AppLinks.githubRepository}/releases/tag/$tag')
            .toString(),
        'githubReleaseTag': tag,
        'githubProxyPrefixes': proxies,
      };
    } finally {
      client.close();
    }
  }

  /// 检查更新
  ///
  /// 带**请求去重**：App 启动时（`main.dart` 为了点亮「发现新版本」按钮）和首页
  /// 加载时（`HomePage._autoCheckUpdate`）都会调到这里，不去重就会白打两次网络。
  /// 同一次检查结果在 [checkUpdateCooldown] 内复用。
  Future<Map<String, dynamic>> checkUpdate({bool force = false}) async {
    if (!force) {
      final cached = _cachedResult;
      final at = _cachedAt;
      if (cached != null &&
          at != null &&
          DateTime.now().difference(at) < checkUpdateCooldown) {
        _updateLog("检查更新：命中缓存，跳过网络请求");
        return cached;
      }
      final inFlight = _inFlight;
      if (inFlight != null) {
        _updateLog("检查更新：已有请求在飞，复用同一个 Future");
        return inFlight;
      }
    }
    final future = _checkUpdateOnce();
    _inFlight = future;
    try {
      final result = await future;
      _cachedResult = result;
      _cachedAt = DateTime.now();
      return result;
    } finally {
      _inFlight = null;
    }
  }

  /// 同一次检查结果的复用时长。
  ///
  /// 取值只需覆盖「启动到首页 initState」这段窗口（几百毫秒），
  /// 用户手动点「检查更新」时走 `force: true` 强制走网络，所以这个值不影响手动检查。
  static const Duration checkUpdateCooldown = Duration(minutes: 5);

  Map<String, dynamic>? _cachedResult;
  DateTime? _cachedAt;
  Future<Map<String, dynamic>>? _inFlight;

  Future<Map<String, dynamic>> _checkUpdateOnce() async {
    _updateLog("开始检查更新...");
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int localBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      _updateLog("当前版本：${packageInfo.version} (build: $localBuild)");

      final cloudConfig = useGitHubForUpdateCheck
          ? await _getGitHubConfig(packageInfo)
          : await _getCloudConfig();

      // 临时测试模式只认 GitHub；关闭开关后恢复配置为准，不混用两边的构建号。
      // 如果网络请求失败，返回网络错误状态
      if (cloudConfig == null) {
        _updateLog("无法获取云端配置，可能是网络问题");
        return {
          "hasUpdate": false,
          "networkError": true, // 标记网络错误
          "message": appL10n.svcNetworkConnectionFailedCheckYourNetworkAnd,
        };
      }

      String latestVersion = cloudConfig["version"] ?? "";
      int latestBuild = int.tryParse('${cloudConfig["buildNumber"]}') ?? 0;
      String updateLog = cloudConfig["updateLog"] ?? appL10n.svcExperienceImprovements;
      String downloadUrl = cloudConfig["downloadUrl"] ?? "";

      _updateLog("最新版本：$latestVersion (build: $latestBuild)");

      if (AppVersion.isNewer(
          remoteVersion: latestVersion,
          remoteBuild: latestBuild,
          localVersion: packageInfo.version,
          localBuild: localBuild)) {
        _updateLog("发现新版本");
        return {
          "hasUpdate": true,
          "currentVersion": packageInfo.version,
          "currentBuild": localBuild,
          "latestVersion": latestVersion,
          "latestBuild": latestBuild,
          "updateLog": updateLog,
          "downloadUrl": downloadUrl,
          "githubProxyPrefixes": cloudConfig['githubProxyPrefixes'],
          "githubReleaseTag": cloudConfig['githubReleaseTag'],
          "updateSource": useGitHubForUpdateCheck ? 'github' : 'config',
        };
      } else {
        _updateLog("已是最新版本");
        // 返回版本信息，以便在弹窗中显示
        return {
          "hasUpdate": false,
          "currentVersion": packageInfo.version,
          "currentBuild": localBuild,
          "latestVersion": latestVersion,
          "latestBuild": latestBuild,
          "updateLog": updateLog,
          "downloadUrl": downloadUrl,
          "githubProxyPrefixes": cloudConfig['githubProxyPrefixes'],
          "githubReleaseTag": cloudConfig['githubReleaseTag'],
          "updateSource": useGitHubForUpdateCheck ? 'github' : 'config',
        };
      }
    } catch (e) {
      _updateLog("检查更新失败：$e");
      return {
        "hasUpdate": false,
        "networkError": true,
        "message": appL10n.svcUpdateCheckFailedP0(e.toString()),
      };
    }
  }

  /// 实际使用的下载地址：云端配置的是安卓包，iOS 固定用无签名 IPA。
  String downloadUrlFor(String? cloudUrl) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppLinks.iosDownloadUrl;
    }
    return cloudUrl == null || cloudUrl.isEmpty ? defaultDownloadUrl : cloudUrl;
  }

  /// 打开下载页
  Future<void> openDownloadPage(String url) async {
    final uri = Uri.parse(url);
    if (uri.scheme == 'https' &&
        (const {'wward.lanzouw.com', 'wward.lanzn.com', 'chiffonmai.cloud'}
                .contains(uri.host) ||
            (uri.host == 'github.com' &&
                uri.path
                    .startsWith('/${AppLinks.githubRepository}/releases/'))) &&
        await ExternalLaunchUtil.open(uri)) {
      return;
    }
  }

  /// 复制下载链接到剪贴板
  void copyDownloadUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
  }

  /// 构建复制下载链接按钮
  Widget _buildCopyDownloadButton(BuildContext c, String url) {
    return TextButton(
      onPressed: () {
        copyDownloadUrl(url);
        Navigator.pop(c);
        AppToast.show(c.l10n.featureDownloadLinkCopied, duration: Duration(seconds: 2));
      },
      child:  Text(c.l10n.featureCopyDownloadLink),
    );
  }

  /// 跳转到最新 GitHub Releases 的按钮。
  Widget buildReleasesButton(BuildContext c) {
    return TextButton.icon(
      onPressed: () {
        Navigator.pop(c);
        ExternalLaunchUtil.open(Uri.parse(AppLinks.latestReleaseUrl));
      },
      icon: const FaIcon(FontAwesomeIcons.github, size: 16),
      // 两列排布时放不下，等比缩小，不换行。
      label: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('GitHub Releases', maxLines: 1, softWrap: false),
      ),
    );
  }

  Future<bool> shouldShowUpdateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDismissTime = prefs.getInt('lastUpdateDismissTime');
    if (lastDismissTime != null) {
      final threeDaysAgo =
          DateTime.now().subtract(Duration(days: 3)).millisecondsSinceEpoch;
      if (lastDismissTime > threeDaysAgo) return false;
    }
    return true;
  }

  Future<void> recordDismissTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'lastUpdateDismissTime', DateTime.now().millisecondsSinceEpoch);
  }

  /// Android 每次下载前都让用户选择方式，不预选或记住上次选项。
  Future<void> _chooseDownloadMethod(
      BuildContext context, Map<String, dynamic> info) async {
    final inApp = await showDialog<bool>(
      context: context,
      builder: (c) => AppAlertDialog(
        title:  Text(context.l10n.flowChooseDownloadMethod),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppDialogOption(
              title: context.l10n.flowDownloadInBrowser,
              subtitle: context.l10n.flowOpenDownloadPage,
              leading: const Icon(Icons.open_in_browser_rounded),
              onTap: () => Navigator.pop(c, false),
            ),
            const SizedBox(height: 10),
            AppDialogOption(
              title: context.l10n.flowDownloadInApp,
              subtitle: context.l10n.flowDownloadInTheBackgroundWhileYouKeep,
              leading: const Icon(Icons.download_rounded),
              onTap: () => Navigator.pop(c, true),
            ),
            const SizedBox(height: 20),
            const AppUpdateAutoInstallControl(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child:  Text(context.l10n.featureCancel),
          ),
        ],
      ),
    );
    if (!context.mounted || inApp == null) return;
    if (!inApp) {
      await openDownloadPage(downloadUrlFor(info['downloadUrl']));
      return;
    }
    final proxies = await _chooseDownloadRoute(context, info);
    if (!context.mounted || proxies == null) return;
    await BackgroundAppUpdateService.instance.start({
      ...info,
      'githubDownloadProxyPrefixes': proxies,
    });
  }

  /// 不预选线路；自动模式依次尝试已配置加速节点、备用节点和官方直连。
  Future<List<String>?> _chooseDownloadRoute(
      BuildContext context, Map<String, dynamic> info) {
    final configured =
        AppUpdateDownloadService.proxyPrefixes(info['githubProxyPrefixes']);
    final automatic = configured.isEmpty
        ? <String>[]
        : {...configured, AppUpdateDownloadService.backupProxy}
            .take(3)
            .toList();
    final routes = [
      (appL10n.svcSwitchRoutesAutomatically, appL10n.svcTriesTheMirrorRoutesThenTheOfficial, Icons.swap_horiz_rounded, automatic),
      (
        'GH-Proxy',
        appL10n.svcCommonMirrorRoute,
        Icons.speed_rounded,
        [AppUpdateDownloadService.defaultProxy]
      ),
      (
        'GHfast',
        appL10n.svcBackupMirrorRoute,
        Icons.bolt_rounded,
        [AppUpdateDownloadService.backupProxy]
      ),
      (appL10n.svcGitHubDirect, appL10n.svcDownloadDirectlyFromGitHub, Icons.public_rounded, <String>[]),
    ];
    return showDialog<List<String>>(
      context: context,
      builder: (c) => AppAlertDialog(
        title:  Text(context.l10n.flowChooseDownloadRoute),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < routes.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              AppDialogOption(
                title: routes[i].$1,
                subtitle: routes[i].$2,
                leading: Icon(routes[i].$3),
                onTap: () => Navigator.pop(c, routes[i].$4),
              ),
            ],
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child:  Text(context.l10n.featureCancel))
        ],
      ),
    );
  }

  /// 显示更新弹窗
  /// [force] 为 true 时强制显示，忽略3天内不提示的设置
  Future<void> showUpdateDialog(BuildContext context,
      {bool force = false}) async {
    // 手动打开更新入口时直接查看现有任务，不再要求用户重复检查或选择下载方式。
    if (force && defaultTargetPlatform == TargetPlatform.android) {
      final task = BackgroundAppUpdateService.instance;
      task.initialize();
      await task.refresh();
      if (!context.mounted) return;
      if (task.active || task.phase == 'ready') {
        task.showStatus();
        return;
      }
    }
    if (!force && !await shouldShowUpdateDialog()) return;

    // force=true（用户点了「检查更新」/「发现新版本」）时强制走网络，
    // 否则会命中启动时那次检查的 5 分钟缓存，用户会觉得「点了没反应」。
    var info = await checkUpdate(force: force);

    // 顺手刷新「发现新版本」按钮的状态：用户手动点过之后，按钮形态必须和刚查到
    // 的结果一致（比如已经更新到最新了，按钮要变回「检查更新」）。
    // 网络失败时不覆盖：一次断网不该把已确认的「有新版本」提示抹掉。
    if (info["networkError"] != true) {
      UpdateNotifier.setResult(info);
    }

    // 如果上下文已销毁，直接返回
    if (!context.mounted) return;

    // 使用 Completer 确保 Future 在对话框关闭后才完成
    final completer = Completer<void>();

    // 如果有网络错误或其他异常，显示错误提示
    if (info["networkError"] == true) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) => AppAlertDialog(
          title: Text(context.l10n.featureCouldNotCheckForUpdates),
          // 单列按原顺序排，确定在最下面。
          actionColumns: 1,
          content: Text(info["message"] ?? context.l10n.flowCouldNotConnectToTheServerCheck),
          actions: [
            _buildCopyDownloadButton(c, platformDownloadUrl),
            buildReleasesButton(c),
            TextButton(
              onPressed: () {
                Navigator.pop(c);
              },
              child: Text(context.l10n.featureOK),
            ),
          ],
        ),
      ).then((_) {
        if (!completer.isCompleted) completer.complete();
      });
      return completer.future;
    }

    // 如果没有更新，显示已是最新版本提示（仅在强制检查时显示）
    if (!info["hasUpdate"] && force) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) => AppAlertDialog(
          title: Text(context.l10n.featureCheckForUpdates),
          // 单列按原顺序排，确定在最下面。
          actionColumns: 1,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.flowYouAreUpToDate),
              SizedBox(height: 10),
              Text(
                  context.l10n.flowCurrentVersionP0BuildP1((info["currentVersion"]).toString(), (info["currentBuild"]).toString())),
              Text(
                  context.l10n.flowLatestVersionP0BuildP1((info["latestVersion"]).toString(), (info["latestBuild"]).toString())),
              SizedBox(height: 10),
              Container(
                constraints: BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(context.l10n.flowLatestChangesP0((info["updateLog"]).toString())),
                ),
              ),
            ],
          ),
          actions: [
            _buildCopyDownloadButton(c, downloadUrlFor(info["downloadUrl"])),
            buildReleasesButton(c),
            TextButton(
              onPressed: () {
                Navigator.pop(c);
              },
              child: Text(context.l10n.featureOK),
            ),
          ],
        ),
      ).then((_) {
        if (!completer.isCompleted) completer.complete();
      });
      return completer.future;
    }

    // 如果有更新，显示更新提示
    if (info["hasUpdate"]) {
      showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (c) => AppAlertDialog(
          title:  Text(context.l10n.featureUpdateAvailable),
          subtitle: "${info["currentVersion"]} → ${info["latestVersion"]}",
          actionColumns: 2,
          // 更新内容占据按钮以外的全部高度，内容短时对话框也跟着变矮。
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppSurfaces.inset(c),
              borderRadius: BorderRadius.circular(AppDesignTokens.radiusSmall),
            ),
            child: SingleChildScrollView(
              child: Text("${info["updateLog"]}"),
            ),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text(context.l10n.updateLater),
              ),
            if (!forceUpdate)
              TextButton(
                onPressed: () async {
                  await recordDismissTime();
                  Navigator.pop(c);
                },
                child: Text(context.l10n.flowHideFor3Days),
              ),
            _buildCopyDownloadButton(c, downloadUrlFor(info["downloadUrl"])),
            // 立即下载放最后：它是主按钮，单独占满一行。
            buildReleasesButton(c),
            TextButton(
              onPressed: () {
                Navigator.pop(c);
                if (defaultTargetPlatform == TargetPlatform.android) {
                  _chooseDownloadMethod(context, info);
                } else {
                  openDownloadPage(downloadUrlFor(info["downloadUrl"]));
                }
              },
              child:  Text(context.l10n.flowDownloadNow),
            ),
          ],
        ),
      ).then((_) {
        if (!completer.isCompleted) completer.complete();
      });
      return completer.future;
    }

    // 如果没有显示任何对话框，直接完成
    completer.complete();
    return completer.future;
  }
}
