import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/ApiUrls.dart';
import '../utils/ApiClient.dart';

class AnnouncementBlock {
  const AnnouncementBlock(
      {required this.type, required this.content, this.caption = ''});
  final String type;
  final String content;
  final String caption;

  Map<String, dynamic> toJson() => type == 'text'
      ? {'type': type, 'text': content}
      : {'type': type, 'url': content, 'caption': caption};
}

class Announcement {
  const Announcement(
      {required this.id,
      required this.revision,
      required this.title,
      required this.blocks,
      this.publishedAt,
      this.startsAt,
      this.endsAt});
  final String id;
  final int revision;
  final String title;
  final List<AnnouncementBlock> blocks;
  final DateTime? publishedAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  String get version => '$id:$revision';

  bool activeAt(DateTime now) =>
      (startsAt == null || !now.isBefore(startsAt!)) &&
      (endsAt == null || now.isBefore(endsAt!));

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final revision = json['revision'];
    final title = json['title'];
    final rawBlocks = json['blocks'];
    if (json['enabled'] != true ||
        id is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(id) ||
        revision is! int ||
        revision < 1 ||
        revision > 9007199254740991 ||
        title is! String ||
        title.trim().isEmpty ||
        title.length > 160 ||
        rawBlocks is! List ||
        rawBlocks.isEmpty ||
        rawBlocks.length > 50) {
      throw const FormatException('公告格式无效');
    }
    DateTime? date(String field) {
      final raw = json[field];
      if (raw == null) return null;
      if (raw is! String || !RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(raw)) {
        throw const FormatException('公告时间无效');
      }
      return DateTime.parse(raw).toUtc();
    }

    final start = date('startsAt'), end = date('endsAt');
    if (start != null && end != null && !start.isBefore(end)) {
      throw const FormatException('公告时间范围无效');
    }
    final blocks = rawBlocks.map((block) {
      if (block is Map &&
          block['type'] == 'text' &&
          block['text'] is String &&
          (block['text'] as String).trim().isNotEmpty &&
          (block['text'] as String).length <= 10000) {
        return AnnouncementBlock(type: 'text', content: block['text']);
      }
      if (block is Map && block['type'] == 'image' && block['url'] is String) {
        final url = Uri.tryParse(block['url']);
        final caption = block['caption'] ?? '';
        if (url != null &&
            url.scheme == 'https' &&
            url.host.isNotEmpty &&
            url.userInfo.isEmpty &&
            url.toString().length <= 2048 &&
            caption is String &&
            caption.length <= 500) {
          return AnnouncementBlock(
              type: 'image', content: url.toString(), caption: caption);
        }
      }
      throw const FormatException('公告内容无效');
    }).toList(growable: false);
    return Announcement(
        id: id,
        revision: revision,
        title: title.trim(),
        blocks: blocks,
        publishedAt: date('publishedAt'),
        startsAt: start,
        endsAt: end);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'revision': revision,
        'title': title,
        'enabled': true,
        'publishedAt': publishedAt?.toIso8601String(),
        'startsAt': startsAt?.toIso8601String(),
        'endsAt': endsAt?.toIso8601String(),
        'blocks': blocks.map((b) => b.toJson()).toList()
      };
}

/// 每次启动检查服务器；正文与 ETag 同条存储，失败时回退有效缓存。
class AnnouncementService {
  static const cacheKey = 'announcement_cache_v1';
  static const dismissedKey = 'announcement_dismissed_v1';

  Future<Announcement?> load() async {
    final prefs = await SharedPreferences.getInstance();
    Announcement? cached;
    String? etag;
    try {
      final raw = jsonDecode(prefs.getString(cacheKey) ?? '{}');
      if (raw is Map && raw['announcement'] is Map) {
        cached = Announcement.fromJson(
            Map<String, dynamic>.from(raw['announcement']));
        if (raw['etag'] is String) etag = raw['etag'];
      }
    } catch (_) {/* 损坏缓存不影响重新查询。 */}
    try {
      final response = await ApiClient.get(Uri.parse(ApiUrls.AnnouncementUrl),
          headers: {if (etag != null) 'If-None-Match': etag},
          timeout: const Duration(seconds: 2));
      if (response.statusCode == 304 && cached != null) {
        return cached.activeAt(DateTime.now()) ? cached : null;
      }
      if (response.statusCode != 200 ||
          response.bodyBytes.length > 256 * 1024) {
        throw const FormatException('公告响应无效');
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map ||
          body['success'] != true ||
          !body.containsKey('announcement')) {
        throw const FormatException('公告响应无效');
      }
      if (body['announcement'] == null) {
        await prefs.remove(cacheKey);
        return null;
      }
      final value = Announcement.fromJson(
          Map<String, dynamic>.from(body['announcement']));
      // 写缓存失败也不丢弃刚取到的有效公告。
      try {
        await prefs.setString(
            cacheKey,
            jsonEncode({
              'etag': response.headers['etag'],
              'announcement': value.toJson()
            }));
      } catch (_) {/* 下次启动继续联网获取。 */}
      return value.activeAt(DateTime.now()) ? value : null;
    } catch (_) {
      return cached != null && cached.activeAt(DateTime.now()) ? cached : null;
    }
  }

  Future<bool> shouldShow(Announcement value) async {
    if (!value.activeAt(DateTime.now())) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getStringList(dismissedKey) ?? []).contains(value.version);
  }

  Future<void> dismiss(Announcement value) async {
    final prefs = await SharedPreferences.getInstance();
    final versions = (prefs.getStringList(dismissedKey) ?? []).toSet()
      ..add(value.version);
    // 只保留最近的免提示选择，避免长期增长。
    final recent = versions.toList();
    if (!await prefs.setStringList(dismissedKey,
        recent.length > 100 ? recent.sublist(recent.length - 100) : recent)) {
      throw StateError('公告设置保存失败');
    }
  }
}
