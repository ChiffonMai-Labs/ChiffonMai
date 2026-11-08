import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http_parser/http_parser.dart';

import '../api/ApiUrls.dart';
import '../entity/MaimaiHubOcrResult.dart';
import '../manager/DivingFishProbeManager.dart';
import '../utils/ApiClient.dart';

/// maimai Score Hub 结算画面识别（走 maimai Score Hub backend 代理）
///
/// 输入是**对着机台结算页面拍的照片**（不是手机截图），文案统一用「拍摄」。
///
/// ## 为什么要绕 backend
/// maimai Score Hub 的 OCR 是仓库里的独立 FastAPI 服务 `ocr-api/`，只监听 `127.0.0.1:19100`，
/// 通过 autossh 隧道转发给 backend 容器（`host.docker.internal:19100`）。
/// **App 直连不到它**，只能调 backend 的代理接口：
///
/// ```text
/// POST {maimai Score Hub API}/me/ocr/recognize
/// Authorization: Bearer <maimai Score Hub 用户 token>
/// Content-Type: multipart/form-data，字段名 images（可重复，1..20 张）
/// ```
///
/// ## 和自家后端 OCR 的区别
/// 自家 `POST /api/ocr/score` 返回**原始文本块**（百度/腾讯通用 OCR），字段要自己解析；
/// 这个是**面向舞萌成绩图的专用识别**，直接返回曲名候选/达成率/DX分/难度/FC/FS。
/// 识别只需要有效的 maimai Score Hub 登录 token，不依赖用户先完成一次成绩同步；
/// 识别结果是否再上传到水鱼或落雪由页面上的可选按钮单独决定。
class MaimaiHubOcrService {
  MaimaiHubOcrService._();
  static final MaimaiHubOcrService instance = MaimaiHubOcrService._();

  /// 单张图最大 8 MiB（服务端硬限制，超了返回 413）
  static const int maxImageBytes = 8 * 1024 * 1024;

  /// 一批最多 20 张（服务端硬限制，超了返回 400）
  static const int maxImagesPerBatch = 20;

  /// 识别比较慢（真实模型跑 GPU），给足超时
  static const Duration _timeout = Duration(seconds: 90);

  /// 当前是否有可用的 maimai Score Hub 登录态。
  ///
  /// 该接口必须带用户 token，未登录时直接返回 false，调用方应引导去登录
  /// （见系统页的 maimai Score Hub 扫码登录入口）。
  Future<bool> isAvailable() async =>
      await DivingFishProbeManager().ensureAuthToken() != null;

  /// 识别一张或多张结算画面图片。
  ///
  /// [imageFiles] 1..20 张，格式 JPEG/PNG/WebP，单张 ≤8 MiB。
  /// 未登录或 token 失效时抛 [MaimaiHubOcrException]，请先调 [isAvailable]。
  Future<MaimaiHubOcrBatch> recognize(List<File> imageFiles) async {
    if (imageFiles.isEmpty) {
      throw MaimaiHubOcrException(appL10n.svcChooseAtLeastOneResultScreenImage);
    }
    if (imageFiles.length > maxImagesPerBatch) {
      throw MaimaiHubOcrException(
          appL10n.svcUpToP0ImagesCanBeRecognized(maxImagesPerBatch.toString(), imageFiles.length.toString()));
    }

    for (final f in imageFiles) {
      if (!await f.exists()) {
        throw MaimaiHubOcrException(appL10n.svcFileNotFoundP0(f.path.toString()));
      }
      final len = await f.length();
      if (len > maxImageBytes) {
        throw MaimaiHubOcrException(
            appL10n.svcP0ExceedsThe8MiBLimitP1(f.uri.pathSegments.last.toString(), ((len / 1024 / 1024).toStringAsFixed(1)).toString()));
      }
    }

    final token = await DivingFishProbeManager().ensureAuthToken();
    if (token == null || token.isEmpty) {
      throw MaimaiHubOcrException(appL10n.svcNotSignedInToMaimaiScoreHub2,
          loginRequired: true);
    }

    final uri = Uri.parse(ApiUrls.MaimaiHubOcrRecognizeUrl);
    try {
      final resp = await ApiClient.postMultipart(
        uri,
        // 字段名必须是 images，且多张图共用同一个字段名
        files: [
          for (final f in imageFiles)
            (
              field: 'images',
              filePath: f.path,
              contentType: _contentTypeFor(f.path),
            ),
        ],
        headers: {'Authorization': 'Bearer $token'},
        timeout: _timeout,
      );

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw MaimaiHubOcrException(_describeError(resp.statusCode, resp.body),
            loginRequired: resp.statusCode == 401);
      }

      final Map<String, dynamic> body;
      try {
        body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      } catch (e) {
        throw MaimaiHubOcrException(appL10n.svcCouldNotParseTheRecognitionResultJSON(e.toString()));
      }
      return MaimaiHubOcrBatch.fromJson(body);
    } on MaimaiHubOcrException {
      rethrow;
    } catch (e) {
      throw MaimaiHubOcrException(appL10n.svcRecognitionRequestFailedP0(e.toString()));
    }
  }

  /// 按扩展名推断 mime（服务端只接受 JPEG/PNG/WebP，错类型返回 415）
  MediaType _contentTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  /// 把 HTTP 状态码翻译成人话（对照 ocr-api 文档里的错误表）
  String _describeError(int status, String body) {
    final detail = _extractMessage(body);
    switch (status) {
      case 400:
        return appL10n.svcNoImagesOrTooManyImagesP0((detail.isEmpty ? '' : '：$detail').toString());
      case 401:
        return appL10n.svcYourSignInHasExpiredSignIn;
      case 413:
        return appL10n.svcAnImageExceedsThe8MiBLimit;
      case 415:
        return appL10n.svcUnsupportedImageFormatOnlyJPEGPNGWebP;
      case 502:
        return appL10n.svcTheOCRServiceReturnedAResultThat;
      case 503:
        return appL10n.svcTheOCRServiceIsUnavailableTryAgain;
      case 504:
        return appL10n.svcOCRRecognitionTimedOutTryAgainLater;
      default:
        return appL10n.svcRecognitionFailedHTTPP0P1(status.toString(), (detail.isEmpty ? '' : '：$detail').toString());
    }
  }

  /// 从后端错误体里取可读信息（NestJS 用 message，FastAPI 用 detail）
  String _extractMessage(String body) {
    if (body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final m = decoded['message'] ?? decoded['detail'];
        if (m is String) return m;
        if (m is List && m.isNotEmpty) return m.first.toString();
      }
    } catch (_) {
      // 非 JSON，截断原始文本
    }
    return body.length > 120 ? '${body.substring(0, 120)}…' : body;
  }
}

class MaimaiHubOcrException implements Exception {
  final String message;

  /// 登录态缺失或失效；页面据此刷新登录提示，不再按文案判断。
  final bool loginRequired;
  MaimaiHubOcrException(this.message, {this.loginRequired = false});

  @override
  String toString() => 'MaimaiHubOcrException: $message';
}
