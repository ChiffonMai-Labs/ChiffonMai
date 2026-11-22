import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/ApiClient.dart';
import '../utils/AwmcIdMap.dart';

typedef _CoverVariant = ({
  String shortId,
  String versionFolder,
  String folderName,
});

/// AWMC 曲绘索引与 CDN 解析：主链走 OSS WebP（带运行时 imageRev），404 自动回退二级源站。
class AwmcCoverService {
  AwmcCoverService._();

  static final instance = AwmcCoverService._();
  static const _asset = 'assets/awmc_cover_index.json';
  static const _prefsRevsKey = 'awmc_cover_revs_v1';
  static const _prefsRevsAtKey = 'awmc_cover_revs_at_v1';
  static const _revTtl = Duration(hours: 24);
  static const _allowedWidths = {240, 360, 480};
  static final _shortIdPattern = RegExp(r'^\d{6}$');
  static final _revPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  Map<int, List<_CoverVariant>> _paths = const {};
  Map<String, String> _revs = const {};
  int _revsSavedAt = 0;
  Future<void>? _load;
  Future<bool>? _revRefresh;

  bool get hasRevisions => _revs.isNotEmpty;

  Future<void> ensureLoaded({bool allowNetwork = true}) async {
    await (_load ??= _loadBundleAndRevs());
    if (allowNetwork && _isRevsStale()) {
      unawaited(refreshRevisions());
    }
  }

  bool _isRevsStale() =>
      _revs.isEmpty ||
      DateTime.now().millisecondsSinceEpoch - _revsSavedAt >
          _revTtl.inMilliseconds;

  Future<void> _loadBundleAndRevs() async {
    try {
      final json = await rootBundle.loadString(_asset);
      _paths = await compute(_decode, json);
    } catch (e) {
      debugPrint('[AWMC 曲绘] 读取随包索引失败: ${e.runtimeType}');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsRevsKey);
      if (raw != null) {
        _revs = _decodeRevs(raw);
        _revsSavedAt = prefs.getInt(_prefsRevsAtKey) ?? 0;
      }
    } catch (e) {
      debugPrint('[AWMC 曲绘] 读取修订缓存失败: ${e.runtimeType}');
    }
  }

  static Map<String, String> _decodeRevs(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map) return const {};
    return {
      for (final entry in data.entries)
        if (entry.key is String &&
            entry.value is String &&
            _shortIdPattern.hasMatch(entry.key as String) &&
            _revPattern.hasMatch(entry.value as String))
          entry.key as String: entry.value as String,
    };
  }

  static Map<int, List<_CoverVariant>> _decode(String source) {
    final data = jsonDecode(source) as Map<String, dynamic>;
    final paths = <int, List<_CoverVariant>>{};
    for (final entry in data.entries) {
      final id = int.tryParse(entry.key);
      final raw = entry.value;
      if (id == null || raw is! List || raw.isEmpty) continue;
      final variants = raw.first is String ? [raw] : raw;
      final unique = <_CoverVariant>{};
      for (final path in variants) {
        if (path is List &&
            path.length == 3 &&
            path[0] is String &&
            path[1] is String &&
            path[2] is String &&
            _shortIdPattern.hasMatch(path[0] as String)) {
          unique.add((
            shortId: path[0] as String,
            versionFolder: path[1] as String,
            folderName: path[2] as String,
          ));
        }
      }
      if (unique.isNotEmpty) paths[id] = unique.toList();
    }
    return paths;
  }

  Future<bool> refreshRevisions() =>
      _revRefresh ??= _fetchRevisions().whenComplete(() => _revRefresh = null);

  Future<bool> _fetchRevisions() async {
    try {
      final first = await _fetchCatalogPage(1);
      if (first == null) return false;
      final revs = <String, String>{};
      _collectRevs(first['charts'], revs);
      final pages = first['pages'] as int;
      final matched = first['matched'] as int?;
      for (var page = 2; page <= pages; page++) {
        final next = await _fetchCatalogPage(page);
        if (next == null ||
            next['pages'] != pages ||
            (matched != null && next['matched'] != matched)) {
          return false;
        }
        _collectRevs(next['charts'], revs);
      }
      if (revs.isEmpty) return false;
      final now = DateTime.now().millisecondsSinceEpoch;
      _revs = revs;
      _revsSavedAt = now;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsRevsKey, jsonEncode(revs));
      await prefs.setInt(_prefsRevsAtKey, now);
      return true;
    } catch (e) {
      debugPrint('[AWMC 曲绘] 刷新修订失败: ${e.runtimeType}');
      return false;
    }
  }

  Future<Map<String, dynamic>?> _fetchCatalogPage(int page) async {
    final uri = Uri(
      scheme: 'https',
      host: 'download.wmc.pub',
      pathSegments: const ['api', 'v1', 'charts'],
      queryParameters: {'raw': '1', 'limit': '500', 'page': '$page'},
    );
    final response = await ApiClient.get(uri, timeout: const Duration(seconds: 20));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic>) return null;
    final pages = data['pages'];
    if (data['charts'] is! List || pages is! int || pages < 1 || pages > 30) {
      return null;
    }
    return data;
  }

  static void _collectRevs(Object? rows, Map<String, String> out) {
    if (rows is! List) return;
    for (final row in rows) {
      if (row is! Map) continue;
      final shortId = row['shortid'];
      final rev = row['imageRev'];
      if (shortId is String &&
          rev is String &&
          _shortIdPattern.hasMatch(shortId) &&
          _revPattern.hasMatch(rev)) {
        out[shortId] = rev;
      }
    }
  }

  String? coverUrlFor(
    String songId, {
    bool original = false,
    int width = 360,
  }) {
    final variant = _variants(songId).firstOrNull;
    if (variant == null) return null;
    final w = _resolveWidth(width);
    return original
        ? _fallbackUrl(variant, width: w)
        : (coverUrlsFor(songId, width: w).firstOrNull);
  }

  Iterable<String> coverUrlsFor(String songId, {int width = 360}) sync* {
    final w = _resolveWidth(width);
    for (final variant in _variants(songId)) {
      final rev = _revs[variant.shortId];
      if (rev != null && rev.isNotEmpty) {
        yield _ossWebpUrl(variant, rev, width: w);
      }
      yield _fallbackUrl(variant, width: w);
    }
  }

  static int _resolveWidth(int width) =>
      _allowedWidths.contains(width) ? width : 360;

  List<_CoverVariant> _variants(String songId) {
    final id = int.tryParse(songId.trim());
    final mapped = id == null ? null : AwmcIdMap.fromSongId(id);
    return _paths[mapped?.baseSongId] ?? const [];
  }

  String _ossWebpUrl(_CoverVariant variant, String rev, {required int width}) {
    final vf = Uri.encodeComponent(variant.versionFolder);
    final fn = Uri.encodeComponent(variant.folderName);
    final rv = Uri.encodeComponent(rev);
    return 'https://oss.awmc.cc/covers/$vf/$fn/$rv/w$width.webp';
  }

  String _fallbackUrl(_CoverVariant variant, {required int width}) => Uri(
        scheme: 'https',
        host: 'download.wmc.pub',
        pathSegments: [
          'cdn',
          'v1',
          'img',
          variant.versionFolder,
          variant.folderName,
        ],
        queryParameters: {'w': '$width', 'src': 'origin'},
      ).toString();

  @visibleForTesting
  void resetForTest() {
    _paths = const {};
    _revs = const {};
    _revsSavedAt = 0;
    _load = null;
    _revRefresh = null;
  }
}
