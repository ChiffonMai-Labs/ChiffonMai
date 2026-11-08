import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../constant/AppLinks.dart';

class UpdateApkAsset {
  final String url;
  final int size;
  final String digest;

  const UpdateApkAsset(this.url, this.size, this.digest);
}

/// 下载只接受本项目 Releases 的 APK，安装前再由系统侧核对包名、版本和签名。
class AppUpdateDownloadService {
  static const channel = MethodChannel('com.example.app/app_update');
  static const defaultProxy = 'https://gh-proxy.com/';
  static const backupProxy = 'https://ghfast.top/';
  final Dio _dio;
  final CancelToken _cancel = CancelToken();

  AppUpdateDownloadService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                'User-Agent': 'ChiffonMai-Updater',
                'Accept': 'application/json'
              },
            ));

  void cancel() {
    if (!_cancel.isCancelled) _cancel.cancel('用户取消下载');
    _dio.close(force: true);
  }

  void _checkCancelled() {
    final error = _cancel.cancelError;
    if (error != null) throw error;
  }

  static List<String> proxyPrefixes(dynamic configured) {
    if (configured is! List) return [defaultProxy];
    return configured
        .whereType<String>()
        .where((value) {
          final uri = Uri.tryParse(value);
          return uri != null &&
              uri.scheme == 'https' &&
              uri.host.isNotEmpty &&
              uri.userInfo.isEmpty &&
              !uri.hasQuery &&
              !uri.hasFragment &&
              (uri.path.isEmpty || uri.path == '/');
        })
        .take(3)
        .map((value) => value.endsWith('/') ? value : '$value/')
        .toSet()
        .toList();
  }

  static List<String> downloadUrls(String original, List<String> proxies) =>
      [...proxies.map((prefix) => '$prefix$original'), original];

  static UpdateApkAsset selectAsset(
      Map<String, dynamic> release, List<String> abis) {
    if (release['draft'] == true) throw  FormatException(appL10n.flowThisVersionHasNotBeenPublishedYet);
    final assets = (release['assets'] as List? ?? [])
        .whereType<Map>()
        .where((asset) => '${asset['name']}'.toLowerCase().endsWith('.apk'))
        .toList();
    int rank(Map asset) {
      final name = '${asset['name']}'.toLowerCase();
      const architectures = ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'x86'];
      final architecture = architectures.where(name.contains).firstOrNull;
      if (architecture == null) return 0;
      final index = abis.indexOf(architecture);
      return index < 0 ? 999 : index + 1;
    }

    assets.sort((a, b) => rank(a).compareTo(rank(b)));
    if (assets.isEmpty ||
        rank(assets.first) == 999 ||
        (assets.length > 1 && rank(assets[0]) == rank(assets[1]))) {
      throw  FormatException(appL10n.flowCouldNotIdentifyASingleAPKFor);
    }
    final asset = assets.first;
    final url = Uri.tryParse('${asset['browser_download_url']}');
    final size = (asset['size'] as num?)?.toInt() ?? 0;
    final digest = '${asset['digest']}';
    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'github.com' ||
        url.userInfo.isNotEmpty ||
        !url.path
            .startsWith('/${AppLinks.githubRepository}/releases/download/') ||
        !url.path.toLowerCase().endsWith('.apk') ||
        size <= 0 ||
        size > 300 * 1024 * 1024 ||
        !RegExp(r'^sha256:[a-fA-F0-9]{64}$').hasMatch(digest)) {
      throw  FormatException(appL10n.flowReleaseAssetLacksValidAPKInformationOr);
    }
    return UpdateApkAsset(
        url.toString(), size, digest.substring(7).toLowerCase());
  }

  Future<Map<String, dynamic>> _release(String path, List<String> proxies,
      {String? tag}) async {
    final api = Uri.https('api.github.com', path);
    for (final url in downloadUrls(api.toString(), proxies)) {
      _checkCancelled();
      try {
        final response = await _dio.get(url,
            cancelToken: _cancel,
            options: Options(responseType: ResponseType.plain));
        final decoded = jsonDecode(response.data as String);
        if (decoded is! Map ||
            decoded['draft'] == true ||
            decoded['tag_name'] is! String ||
            (tag != null && decoded['tag_name'] != tag)) continue;
        return Map<String, dynamic>.from(decoded);
      } catch (_) {
        _checkCancelled();
      }
    }
    throw  FormatException(appL10n.flowCouldNotFetchGitHubReleaseInformation);
  }

  /// 版本和构建号由检查更新的结果传入，再按精确标签获取附件，不能改写期望版本。
  Future<Map<String, dynamic>> startBackgroundDownload(
      {required String version,
      required int build,
      String updateLog = '',
      String? releaseTag,
      dynamic configuredProxies,
      dynamic downloadProxies,
      required void Function(String message, int received, int? total)
          onProgress}) async {
    final proxies = proxyPrefixes(configuredProxies);
    // 线路选择只影响 APK 下载；部分文件加速节点不支持 GitHub API。
    final apkProxies =
        downloadProxies is List ? proxyPrefixes(downloadProxies) : proxies;
    final tag = releaseTag?.trim().isNotEmpty == true
        ? releaseTag!.trim()
        : 'v$version';
    onProgress(appL10n.flowFetchingAPKInformation, 0, null);
    final release = await _release(
        '/repos/${AppLinks.githubRepository}/releases/tags/$tag', proxies,
        tag: tag);
    final abis = await channel.invokeListMethod<String>('supportedAbis') ?? [];
    final asset = selectAsset(release, abis);
    _checkCancelled();
    final state =
        await channel.invokeMethod<String>('startBackgroundDownload', {
      'urls': downloadUrls(asset.url, apkProxies),
      'size': asset.size,
      'sha256': asset.digest,
      'version': version,
      'build': build,
      'updateLog': updateLog,
    });
    return Map<String, dynamic>.from(jsonDecode(state ?? '{}') as Map);
  }
}
