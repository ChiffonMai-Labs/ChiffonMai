import 'dart:convert';

import '../api/ApiUrls.dart';
import '../utils/ApiClient.dart';
import '../utils/JsonIsolate.dart';

typedef DeliveryGroup = ({String label, int count, List<String> names});
typedef DeliveryItem = ({String title, List<String> songs});

/// [hidden] 是接口没有列出名字的条目数。
typedef DeliverySection = ({String label, List<DeliveryItem> items, int hidden});
typedef DeliverySummary = ({List<DeliverySection> sections, List<String> counted});

class CalendarDelivery {
  final String date;
  final String option;
  final int musicCount;
  final List<DeliveryGroup> groups;

  CalendarDelivery.fromJson(Map<String, dynamic> json)
      : date = json['date'] as String,
        option = json['option'] as String,
        musicCount = json['musicCount'] as int,
        groups = (json['groups'] as List<dynamic>).map((group) {
          final item = group as Map<String, dynamic>;
          return (
            label: item['label'] as String,
            count: item['count'] as int,
            names: (item['names'] as List<dynamic>).cast<String>(),
          );
        }).toList(growable: false);

  /// 给用户看的摘要：去掉活动编号和与其他内容重复的条目。
  DeliverySummary get summary {
    final maps = {
      for (final group in groups.where((g) => g.label == '地图'))
        for (final name in group.names) name.replaceFirst(_mapSuffix, 'ちほー'),
    };
    final events = {
      for (final group in groups.where((g) => g.label == '活动')) ...group.names,
    };
    final sections = <DeliverySection>[];
    final counted = <String>[];
    for (final group in groups) {
      if (group.names.isEmpty) {
        counted.add('${group.label} ${group.count} 项');
        continue;
      }
      final hidden = group.count - group.names.length;
      final items = switch (group.label) {
        '活动' => _eventItems(group.names, maps),
        // 公告基本是活动的另一份，只留活动里没有的；看不到全部名字时也不再提数量。
        '公告' => _eventItems(
            group.names.where((name) => !events.contains(name)), maps),
        _ => [for (final name in group.names) (title: name, songs: <String>[])],
      };
      final visibleHidden = group.label == '公告' ? 0 : hidden;
      if (items.isEmpty && visibleHidden <= 0) continue;
      sections.add((
        label: group.label,
        items: items,
        hidden: visibleHidden < 0 ? 0 : visibleHidden,
      ));
    }
    return (sections: sections, counted: counted);
  }
}

final _mapSuffix = RegExp(r'区域$');
final _eventCode = RegExp(r'^\d+(?:_\d+)*[：:]\s*');
final _eventSongs = RegExp(r'^(.*?)\s*《(.*)》\s*$');
final _eventUnlock = RegExp(r'\s*解禁$');

/// `261111_01_5：連動楽曲紹介《Lover's Trick》` → 標題「連動楽曲」+ 曲目。
/// 同一件事的「紹介」和「解禁」只留后者；只是介绍新地图的条目已由地图一栏说明。
List<DeliveryItem> _eventItems(Iterable<String> names, Set<String> maps) {
  final items = <String, DeliveryItem>{};
  for (final name in names) {
    final text = name.replaceFirst(_eventCode, '').trim();
    final match = _eventSongs.firstMatch(text);
    final title = (match?.group(1) ?? text).replaceAll('紹介', '').trim();
    final songs = match == null
        ? const <String>[]
        : match.group(2)!.split('、').map((song) => song.trim()).toList();
    if (songs.isEmpty && maps.contains(title)) continue;
    items[title.replaceFirst(_eventUnlock, '')] = (title: title, songs: songs);
  }
  return items.values.toList(growable: false);
}

Future<List<CalendarDelivery>> fetchCalendarDeliveries() async {
  final response = await ApiClient.get(Uri.parse(ApiUrls.UpdateCalendarUrl),
      timeout: const Duration(seconds: 5));
  if (response.statusCode != 200) {
    throw StateError('配信数据读取失败 (${response.statusCode})');
  }
  final body = await decodeJsonInBackground(utf8.decode(response.bodyBytes));
  if (body is! Map || body['success'] != true || body['waves'] is! List) {
    throw const FormatException('无效的配信数据');
  }
  return (body['waves'] as List)
      .map((item) => CalendarDelivery.fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
}
