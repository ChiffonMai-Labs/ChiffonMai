import 'dart:collection';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ApiUrls.dart';
import '../../utils/ApiClient.dart';

typedef AwmcOwnedItem = ({String id, String kind, String name, String? slug});
typedef AwmcPlayRegion = ({String name, int? count});

class AwmcCabinetData {
  static const _provinces = {
    '11': '北京',
    '12': '天津',
    '13': '河北',
    '14': '山西',
    '15': '内蒙古',
    '21': '辽宁',
    '22': '吉林',
    '23': '黑龙江',
    '31': '上海',
    '32': '江苏',
    '33': '浙江',
    '34': '安徽',
    '35': '福建',
    '36': '江西',
    '37': '山东',
    '41': '河南',
    '42': '湖北',
    '43': '湖南',
    '44': '广东',
    '45': '广西',
    '46': '海南',
    '50': '重庆',
    '51': '四川',
    '52': '贵州',
    '53': '云南',
    '54': '西藏',
    '61': '陕西',
    '62': '甘肃',
    '63': '青海',
    '64': '宁夏',
    '65': '新疆',
    '71': '台湾',
    '81': '香港',
    '82': '澳门',
  };

  static final _slug = RegExp(r'^[A-Za-z0-9_-]{1,120}$');
  static const _cachePrefix = 'awmc-collection-upstream:';
  static const _cacheLifetime = Duration(days: 7);
  static const _checkWindow = Duration(milliseconds: 60150);
  static final _recentChecks = Queue<DateTime>();

  static List<AwmcOwnedItem> ownedItems(Object? source) {
    final data = _unwrap(source);
    final rows = data is List
        ? data
        : data is Map
            ? data['userItemList'] ?? data['itemList'] ?? data['items']
            : null;
    if (rows is! List) return const [];
    final items = <(String, String), AwmcOwnedItem>{};
    for (final row in rows.whereType<Map>()) {
      final id = _string(row['itemId'] ?? row['gameId'] ?? row['id']);
      final kind = _string(row['itemKind'] ?? row['type']);
      if (id.isEmpty) continue;
      final slug = _string(row['slug']);
      items[(kind, id)] = (
        id: id,
        kind: kind,
        name: _string(row['name'] ?? row['itemName']),
        slug: _slug.hasMatch(slug) ? slug : null,
      );
    }
    return items.values.toList();
  }

  static List<AwmcPlayRegion> regions(Object? source) {
    final data = _unwrap(source);
    final rows = data is List
        ? data
        : data is Map
            ? data['userRegionList'] ?? data['regionList'] ?? data['regions']
            : null;
    if (rows is! List) return const [];
    final regions = <AwmcPlayRegion>[];
    for (final row in rows.whereType<Map>()) {
      var name =
          _string(row['regionName'] ?? row['provinceName'] ?? row['name']);
      final province = _string(row['provinceCode']);
      if (name.isEmpty && (province.length == 2 || province.length == 6)) {
        name = _provinces[province.substring(0, 2)] ?? '';
      }
      if (name.isEmpty) name = _string(row['regionId'] ?? province);
      if (name.isEmpty) continue;
      final count = int.tryParse(
          '${row['playCount'] ?? row['visitCount'] ?? row['playNum']}');
      regions
          .add((name: name, count: count != null && count >= 0 ? count : null));
    }
    return regions..sort((a, b) => (b.count ?? -1).compareTo(a.count ?? -1));
  }

  static ({String name, String rating, String playCount}) preview(
      Object? source) {
    final data = _unwrap(source);
    Object? row = data is Map ? data['userData'] ?? data['user'] ?? data : data;
    if (row is List) row = row.firstOrNull;
    if (row is! Map) return (name: '', rating: '', playCount: '');
    return (
      name: _string(row['userName'] ?? row['nickname']),
      rating: _string(row['playerRating'] ?? row['rating']),
      playCount: _string(row['playCount']),
    );
  }

  static Future<Map<String, bool>> checkVisible(
    Iterable<String> slugs, {
    required bool Function() isActive,
  }) async {
    final page = slugs.where(_slug.hasMatch).toSet().take(24).toList();
    final result = <String, bool>{};
    final prefs = await SharedPreferences.getInstance();
    for (var start = 0; start < page.length && isActive(); start += 2) {
      final pairs = await Future.wait(
        page.skip(start).take(2).map((slug) => _check(slug, prefs, isActive)),
      );
      for (final (slug, exists) in pairs) {
        if (exists != null) result[slug] = exists;
      }
    }
    return result;
  }

  static Future<(String, bool?)> _check(
      String slug, SharedPreferences prefs, bool Function() isActive) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = '$_cachePrefix$slug';
    final cached = prefs.getString(key)?.split(':');
    if (cached != null && cached.length == 2) {
      final expiry = int.tryParse(cached[0]);
      if (expiry != null && expiry > now) return (slug, cached[1] == '1');
    }
    try {
      if (!await _claimCheckSlot(isActive)) return (slug, null);
      final response = await ApiClient.get(_collectionUrl('upstream', slug));
      if (response.headers['x-chiffonmai-collection-proxy'] != '1') {
        return (slug, null);
      }
      final bool? exists;
      if (response.statusCode == 404) {
        exists = false;
      } else if (response.statusCode == 200) {
        final data = _unwrap(jsonDecode(utf8.decode(response.bodyBytes)));
        exists = data is Map && data['exists'] is bool
            ? data['exists'] as bool
            : null;
      } else {
        exists = null;
      }
      if (exists != null) {
        await prefs.setString(
            key, '${now + _cacheLifetime.inMilliseconds}:${exists ? 1 : 0}');
      }
      return (slug, exists);
    } on Exception {
      return (slug, null);
    }
  }

  static Future<bool> _claimCheckSlot(bool Function() isActive) async {
    while (isActive()) {
      final now = DateTime.now();
      while (_recentChecks.isNotEmpty &&
          now.difference(_recentChecks.first) >= _checkWindow) {
        _recentChecks.removeFirst();
      }
      if (_recentChecks.length < 30) {
        _recentChecks.add(now);
        return true;
      }
      await Future<void>.delayed(
          _recentChecks.first.add(_checkWindow).difference(now));
    }
    return false;
  }

  static Future<({String title, String description})?> item(String slug) async {
    if (!_slug.hasMatch(slug)) return null;
    final response = await ApiClient.get(_collectionUrl('item', slug));
    if (response.statusCode != 200) return null;
    var data = _unwrap(jsonDecode(utf8.decode(response.bodyBytes)));
    if (data is Map && data['item'] is Map) data = data['item'];
    if (data is! Map) return null;
    final title = _string(data['name'] ?? data['title']);
    if (title.isEmpty) return null;
    return (title: title, description: _string(data['description']));
  }

  static Uri _collectionUrl(String mode, String slug) => Uri.parse(
      '${ApiUrls.BackendBaseUrl}/api/awmc/api/collection/$mode/$slug');

  static Object? _unwrap(Object? value) =>
      value is Map && value['data'] != null ? value['data'] : value;

  static String _string(Object? value) =>
      value is String || value is num ? value.toString().trim() : '';
}
