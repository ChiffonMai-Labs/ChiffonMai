import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/AwmcIdMap.dart';

/// AWMC 公共曲绘入口使用版本目录和曲目目录。对象存储地址由上游管理。
class AwmcCoverService {
  AwmcCoverService._();

  static final instance = AwmcCoverService._();
  static const _asset = 'assets/awmc_cover_index.json';

  Map<int, List<(String, String)>> _paths = const {};
  Future<void>? _load;

  Future<void> ensureLoaded() => _load ??= _loadBundle();

  Future<void> _loadBundle() async {
    try {
      final json = await rootBundle.loadString(_asset);
      _paths = await compute(_decode, json);
    } catch (e) {
      debugPrint('[AWMC 曲绘] 读取随包索引失败: ${e.runtimeType}');
    }
  }

  static Map<int, List<(String, String)>> _decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final paths = <int, List<(String, String)>>{};
    for (final entry in data.entries) {
      final id = int.tryParse(entry.key);
      final raw = entry.value;
      if (id == null || raw is! List || raw.isEmpty) continue;
      final variants = raw.first is String ? [raw] : raw;
      final unique = <(String, String)>{};
      for (final path in variants) {
        if (path is List &&
            path.length == 3 &&
            path[1] is String &&
            path[2] is String) {
          unique.add((path[1] as String, path[2] as String));
        }
      }
      if (unique.isNotEmpty) paths[id] = unique.toList();
    }
    return paths;
  }

  String? coverUrlFor(String songId, {bool original = false}) {
    final path = _variants(songId).firstOrNull;
    return path == null ? null : _url(path, original: original);
  }

  Iterable<String> coverUrlsFor(String songId) sync* {
    for (final path in _variants(songId)) {
      yield _url(path);
      yield _url(path, original: true);
    }
  }

  List<(String, String)> _variants(String songId) {
    final id = int.tryParse(songId.trim());
    final mapped = id == null ? null : AwmcIdMap.fromSongId(id);
    return _paths[mapped?.baseSongId] ?? const [];
  }

  String _url((String, String) path, {bool original = false}) {
    final (version, folder) = path;
    return Uri(
      scheme: 'https',
      host: 'download.wmc.pub',
      pathSegments: ['cdn', 'v1', 'img', version, folder],
      queryParameters: {'w': '360', if (original) 'src': 'origin'},
    ).toString();
  }
}
