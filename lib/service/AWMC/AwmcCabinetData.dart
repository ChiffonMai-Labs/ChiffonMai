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

  static const _collectionItemKinds = <int, ({String label, String? slugPrefix})>{
    1: (label: '姓名框', slugPrefix: 'plate'),
    2: (label: '称号', slugPrefix: 'title'),
    3: (label: '头像', slugPrefix: 'icon'),
    4: (label: '礼物', slugPrefix: null),
    5: (label: '乐曲解锁', slugPrefix: null),
    6: (label: 'MASTER 解锁', slugPrefix: null),
    7: (label: 'Re:MASTER 解锁', slugPrefix: null),
    8: (label: '活动道具', slugPrefix: null),
    10: (label: '搭档', slugPrefix: 'partner'),
    11: (label: '背景', slugPrefix: 'frame'),
    12: (label: '票券', slugPrefix: null),
    14: (label: '万花筒钥匙', slugPrefix: null),
  };

  static List<AwmcOwnedItem> ownedItems(Object? source) {
    final data = _unwrap(source);
    final rawRows = <Map>[];
    if (data is List) {
      rawRows.addAll(data.whereType<Map>());
    } else if (data is Map) {
      final direct = data['userItemList'] ?? data['itemList'] ?? data['items'];
      if (direct is List) {
        rawRows.addAll(direct.whereType<Map>());
      } else {
        for (final value in data.values) {
          if (value is Map && value['userItemList'] is List) {
            rawRows.addAll((value['userItemList'] as List).whereType<Map>());
          }
        }
      }
    }
    if (rawRows.isEmpty) return const [];

    final items = <(String, String), ({AwmcOwnedItem item, int? kindNum, int? idNum})>{};
    for (final row in rawRows) {
      if (row['isValid'] == false) continue;
      final id = _string(row['itemId'] ?? row['gameId'] ?? row['id']);
      if (id.isEmpty) continue;
      final rawKind = _string(row['itemKind'] ?? row['type']);
      final kindNum = int.tryParse(rawKind);
      final mapped = kindNum == null ? null : _collectionItemKinds[kindNum];
      final kindLabel = mapped?.label ?? rawKind;

      final explicitSlug = _string(row['slug']);
      String? slug = _slug.hasMatch(explicitSlug) ? explicitSlug : null;
      if (slug == null && mapped?.slugPrefix != null) {
        final candidate = '${mapped!.slugPrefix}-$id';
        if (_slug.hasMatch(candidate)) slug = candidate;
      }

      items[(rawKind, id)] = (
        item: (
          id: id,
          kind: kindLabel,
          name: _string(row['name'] ?? row['itemName']),
          slug: slug,
        ),
        kindNum: kindNum,
        idNum: int.tryParse(id),
      );
    }

    final sorted = items.values.toList()
      ..sort((a, b) {
        final aHasSlug = a.item.slug != null;
        final bHasSlug = b.item.slug != null;
        if (aHasSlug != bHasSlug) return aHasSlug ? -1 : 1;
        if (a.kindNum != null && b.kindNum != null && a.kindNum != b.kindNum) {
          return a.kindNum!.compareTo(b.kindNum!);
        }
        if (a.idNum != null && b.idNum != null && a.idNum != b.idNum) {
          return a.idNum!.compareTo(b.idNum!);
        }
        return 0;
      });
    return [for (final entry in sorted) entry.item];
  }

  static const _wahlapRegions = <int, String>{
    1: '北京',
    2: '重庆',
    3: '上海',
    4: '天津',
    5: '安徽',
    6: '福建',
    7: '甘肃',
    8: '广东',
    9: '贵州',
    10: '海南',
    11: '河北',
    12: '黑龙江',
    13: '河南',
    14: '湖北',
    15: '湖南',
    16: '江苏',
    17: '江西',
    18: '吉林',
    19: '辽宁',
    20: '青海',
    21: '陕西',
    22: '山东',
    23: '山西',
    24: '四川',
    26: '云南',
    27: '浙江',
    28: '广西',
    29: '内蒙古',
    30: '宁夏',
    31: '新疆',
    32: '西藏',
  };

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
      if (name.isEmpty) {
        final rawRegionId = _string(row['regionId']);
        if (rawRegionId.isNotEmpty) {
          final id = int.tryParse(rawRegionId);
          name = (id != null ? _wahlapRegions[id] : null) ?? '地区 #$rawRegionId';
        }
      }
      if (name.isEmpty) name = province;
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
