import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../api/ApiUrls.dart';

typedef FontStreamDownloader = Future<FontDownloadPayload> Function(
  Uri uri,
  File tempFile,
);
typedef FontEngineRegistrar = Future<void> Function(
  String family,
  Uint8List bytes,
);

class FontDownloadPayload {
  const FontDownloadPayload({
    this.expectedSha256,
    this.expectedSize,
  });

  final String? expectedSha256;
  final int? expectedSize;
}

class _DigestAccumulator implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) {
    value = data;
  }

  @override
  void close() {}
}

/// 自托管中文字体管理服务（方案 B）：
///
/// - 拉丁与数字字体 `AppOutfit` 已随包本地内置（5 个静态字重，共约 240 KB）；
/// - 中文回落字体 `AppNotoSansSC` 使用单一可变字体文件 `NotoSansSC-VF.ttf`，
///   首次从自家后端下载校验并持久化至应用支持目录，之后本地秒级加载、零流量。
class AppFontService extends ChangeNotifier {
  AppFontService._({
    Future<Directory> Function()? supportDirProvider,
    FontStreamDownloader? downloader,
    FontEngineRegistrar? fontRegistrar,
    int? minValidBytes,
    DateTime Function()? now,
  })  : _supportDirProvider =
            supportDirProvider ?? getApplicationSupportDirectory,
        _downloader = downloader ?? _defaultDownload,
        _fontRegistrar = fontRegistrar ?? _defaultRegisterFont,
        _minValidBytes = minValidBytes ?? defaultMinValidBytes,
        _now = now ?? DateTime.now;

  static final AppFontService instance = AppFontService._();

  @visibleForTesting
  factory AppFontService.forTesting({
    required Future<Directory> Function() supportDirProvider,
    FontStreamDownloader? downloader,
    FontEngineRegistrar? fontRegistrar,
    int minValidBytes = 1024,
    DateTime Function()? now,
  }) {
    return AppFontService._(
      supportDirProvider: supportDirProvider,
      downloader: downloader,
      fontRegistrar: fontRegistrar,
      minValidBytes: minValidBytes,
      now: now,
    );
  }

  static const String primaryFamily = 'AppOutfit';
  static const String cjkFamily = 'AppNotoSansSC';
  static const String cjkFileName = 'NotoSansSC-VF.ttf';
  static const int defaultMinValidBytes = 1024 * 1024;
  static const int maxValidBytes = 32 * 1024 * 1024;
  static const Duration failureRetryCooldown = Duration(seconds: 30);

  final Future<Directory> Function() _supportDirProvider;
  final FontStreamDownloader _downloader;
  final FontEngineRegistrar _fontRegistrar;
  final int _minValidBytes;
  final DateTime Function() _now;

  bool _cjkLoaded = false;
  Future<bool>? _inFlight;
  DateTime? _lastFailureAt;

  bool get isCjkLoaded => _cjkLoaded;

  static bool hasValidFontMagic(List<int> bytes) {
    if (bytes.length < 4) return false;
    final isTtf = bytes[0] == 0x00 &&
        bytes[1] == 0x01 &&
        bytes[2] == 0x00 &&
        bytes[3] == 0x00;
    final isOtf = bytes[0] == 0x4F &&
        bytes[1] == 0x54 &&
        bytes[2] == 0x54 &&
        bytes[3] == 0x4F;
    return isTtf || isOtf;
  }

  Future<File> _resolveTargetFile() async {
    final base = await _supportDirProvider();
    return File('${base.path}/fonts/$cjkFileName');
  }

  static Future<void> _defaultRegisterFont(
    String family,
    Uint8List bytes,
  ) async {
    final loader = FontLoader(family);
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }

  static Future<FontDownloadPayload> _defaultDownload(
    Uri uri,
    File tempFile,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..autoUncompress = true;
    try {
      final request = await client.getUrl(uri).timeout(
            const Duration(seconds: 15),
          );
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
      request.headers.set(HttpHeaders.userAgentHeader, 'ChiffonMai-AppFont');
      final apiKey = ApiUrls.BackendApiKey;
      if (apiKey.isNotEmpty) {
        request.headers.set('x-prober-key', apiKey);
      }

      final response = await request.close().timeout(
            const Duration(seconds: 60),
          );
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }

      final sink = tempFile.openWrite();
      var total = 0;
      try {
        await for (final chunk in response.timeout(const Duration(seconds: 60))) {
          total += chunk.length;
          if (total > maxValidBytes) {
            throw const FormatException('Font payload exceeded size limit');
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      final expectedSize =
          int.tryParse(response.headers.value('x-font-uncompressed-size') ?? '');
      final expectedSha256 =
          response.headers.value('x-font-sha256')?.trim().toLowerCase();
      return FontDownloadPayload(
        expectedSha256:
            expectedSha256 != null && expectedSha256.isNotEmpty
                ? expectedSha256
                : null,
        expectedSize: expectedSize,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> _validateFileAndLoad(
    File file, {
    String? expectedSha256,
    int? expectedSize,
  }) async {
    if (!await file.exists()) return false;
    final stat = await file.stat();
    if (stat.size < _minValidBytes || stat.size > maxValidBytes) {
      return false;
    }
    if (expectedSize != null && stat.size != expectedSize) {
      return false;
    }

    final bytes = await file.readAsBytes();
    if (bytes.length < _minValidBytes ||
        bytes.length > maxValidBytes ||
        !hasValidFontMagic(bytes)) {
      return false;
    }

    if (expectedSha256 != null && expectedSha256.isNotEmpty) {
      final digestSink = _DigestAccumulator();
      final input = sha256.startChunkedConversion(digestSink);
      input.add(bytes);
      input.close();
      final actualSha = digestSink.value?.toString().toLowerCase();
      if (actualSha != expectedSha256.toLowerCase()) {
        return false;
      }
    }

    await _fontRegistrar(cjkFamily, bytes);
    return true;
  }

  /// 仅检查本地已缓存字体；有效则注册进引擎并返回 true，不发起网络请求。
  Future<bool> loadCachedIfPresent() async {
    if (_cjkLoaded) return true;
    try {
      final file = await _resolveTargetFile();
      if (!await file.exists()) return false;
      final ok = await _validateFileAndLoad(file);
      if (ok) {
        _cjkLoaded = true;
        notifyListeners();
        return true;
      }
      await file.delete().catchError((_) => file);
    } catch (e) {
      debugPrint('[AppFont] 读取本地缓存字体失败: $e');
    }
    return false;
  }

  /// 确保自托管可变中文字体已加载；本地未命中则从自家服务器下载并校验落盘。
  Future<bool> ensureLoaded({bool forceRetry = false}) async {
    if (_cjkLoaded) return true;
    final cachedOk = await loadCachedIfPresent();
    if (cachedOk) return true;

    final running = _inFlight;
    if (running != null) return running;

    final lastFail = _lastFailureAt;
    if (!forceRetry &&
        lastFail != null &&
        _now().difference(lastFail) < failureRetryCooldown) {
      return false;
    }

    final task = _downloadAndRegister();
    _inFlight = task;
    try {
      return await task;
    } finally {
      if (identical(_inFlight, task)) {
        _inFlight = null;
      }
    }
  }

  Future<bool> _downloadAndRegister() async {
    File? tempFile;
    try {
      final target = await _resolveTargetFile();
      await target.parent.create(recursive: true);
      tempFile = File('${target.path}.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final meta = await _downloader(
        Uri.parse(ApiUrls.NotoSansScVfFontUrl),
        tempFile,
      );
      final valid = await _validateFileAndLoad(
        tempFile,
        expectedSha256: meta.expectedSha256,
        expectedSize: meta.expectedSize,
      );
      if (!valid) {
        throw const FormatException('Downloaded font failed validation');
      }

      if (await target.exists()) {
        await target.delete();
      }
      await tempFile.rename(target.path);
      tempFile = null;
      _cjkLoaded = true;
      _lastFailureAt = null;
      notifyListeners();
      debugPrint('[AppFont] 自托管思源黑体可变字体加载成功');
      return true;
    } catch (e) {
      _lastFailureAt = _now();
      debugPrint('[AppFont] 下载或加载思源黑体失败: $e');
      return false;
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete().catchError((_) => tempFile!);
      }
    }
  }
}
