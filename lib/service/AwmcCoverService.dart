import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/AwmcIdMap.dart';

/// AWMC 公共曲绘入口使用版本目录和曲目目录。对象存储地址由上游管理。
class AwmcCoverService {
  AwmcCoverService._();

  static final instance = AwmcCoverService._();
  static const _asset = 'assets/awmc_cover_index.json';

  Map<int, (String, String)> _paths = const {};
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

  static Map<int, (String, String)> _decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final paths = <int, (String, String)>{};
    for (final entry in data.entries) {
      final id = int.tryParse(entry.key);
      final path = entry.value;
      if (id != null &&
          path is List &&
          path.length == 3 &&
          path[1] is String &&
          path[2] is String) {
        paths[id] = (path[1] as String, path[2] as String);
      }
    }
    return paths;
  }

  String? coverUrlFor(String songId, {bool original = false}) {
    final id = int.tryParse(songId.trim());
    final mapped = id == null ? null : AwmcIdMap.fromSongId(id);
    final path = _paths[mapped?.baseSongId];
    if (path == null) return null;
    final (version, folder) = path;
    return Uri(
      scheme: 'https',
      host: 'download.wmc.pub',
      pathSegments: ['cdn', 'v1', 'img', version, folder],
      queryParameters: {'w': '360', if (original) 'src': 'origin'},
    ).toString();
  }
}
