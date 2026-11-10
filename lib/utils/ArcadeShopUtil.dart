import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:latlong2/latlong.dart';

import '../entity/nearcade/NearCadeShop.dart';

enum ArcadeOpenState { open, closed, unknown }

/// 机厅此刻的营业状态。[time] 是下一个变化时刻（打烊或开门），已格式化成 HH:mm。
class ArcadeOpenStatus {
  final ArcadeOpenState state;
  final String? time;

  /// 下一次开门不在今天。
  final bool nextDay;

  const ArcadeOpenStatus(this.state, {this.time, this.nextDay = false});

  static const unknown = ArcadeOpenStatus(ArcadeOpenState.unknown);
}

/// 最近的地铁站。
class ArcadeMetroInfo {
  final String station;
  final int walkMinutes;
  final List<ArcadeMetroLine> lines;

  const ArcadeMetroInfo(this.station, this.walkMinutes, this.lines);
}

class ArcadeMetroLine {
  final String name;
  final Color color;

  const ArcadeMetroLine(this.name, this.color);
}

/// 多家机厅都有多种机台时，地图标记优先用这些系列的颜色（音游在前）。
const arcadeMusicTitlePriority = [1, 3, 27, 4, 5, 31, 15, 34, 17];

enum ArcadeMapApp { amap, baidu, tencent, google, apple, system }

/// 拉起某个地图 App 的链接。[probe] 用来判断是否已安装，为空表示系统自带。
class ArcadeMapLink {
  final ArcadeMapApp app;
  final Uri uri;
  final Uri? probe;

  const ArcadeMapLink(this.app, this.uri, {this.probe});
}

extension ArcadeShopX on Shop {
  LatLng? get latLng {
    final c = location.coordinates;
    return c.length >= 2 ? LatLng(c[1], c[0]) : null;
  }

  int get machineCount => games.fold(0, (sum, g) => sum + g.quantity);

  /// 地图标记的代表系列：筛选中的系列优先，其次按音游优先级；没有机台时返回 -1。
  int primaryTitle(Set<int> selected) {
    for (final game in games) {
      if (selected.contains(game.titleId)) return game.titleId;
    }
    for (final title in arcadeMusicTitlePriority) {
      if (games.any((g) => g.titleId == title)) return title;
    }
    return games.isEmpty ? -1 : games.first.titleId;
  }

  /// 第 [weekday] 天（0 = 周一）的 [开门, 打烊]；只有一条时整周相同。
  List<OpeningHour>? hoursOn(int weekday) {
    final List<OpeningHour> day;
    if (openingHours.length == 1) {
      day = openingHours.first;
    } else if (openingHours.length == 7) {
      day = openingHours[weekday % 7];
    } else {
      return null;
    }
    return day.length >= 2 ? day : null;
  }

  /// 机厅所在时区的当前时刻；没有时区时用设备时间。
  DateTime localNow([DateTime? now]) {
    final current = now ?? DateTime.now();
    final offset = timezone?.offset;
    if (offset == null) return current;
    return current.toUtc().add(Duration(minutes: (offset * 60).round()));
  }

  /// 按营业时间现算：接口的 isOpen 是拉取那一刻的值，缓存后很快就过期了。
  ArcadeOpenStatus openStatus([DateTime? now]) {
    if (openingHours.isEmpty) return ArcadeOpenStatus.unknown;
    final local = localNow(now);
    final minute = local.hour * 60 + local.minute;
    final today = local.weekday - 1;

    // 昨天的营业时段可能跨到今天凌晨。
    final yesterday = hoursOn(today + 6);
    if (yesterday != null) {
      final (open, close) = _range(yesterday);
      if (close > 1440 && minute + 1440 >= open && minute + 1440 < close) {
        return ArcadeOpenStatus(ArcadeOpenState.open,
            time: formatArcadeMinutes(close - 1440));
      }
    }

    final hours = hoursOn(today);
    if (hours == null) return ArcadeOpenStatus.unknown;
    final (open, close) = _range(hours);
    if (minute >= open && minute < close) {
      return ArcadeOpenStatus(ArcadeOpenState.open,
          time: formatArcadeMinutes(close > 1440 ? close - 1440 : close));
    }
    if (minute < open) {
      return ArcadeOpenStatus(ArcadeOpenState.closed,
          time: formatArcadeMinutes(open));
    }
    final tomorrow = hoursOn(today + 1);
    if (tomorrow == null) return const ArcadeOpenStatus(ArcadeOpenState.closed);
    return ArcadeOpenStatus(ArcadeOpenState.closed,
        time: formatArcadeMinutes(_range(tomorrow).$1), nextDay: true);
  }

  /// 打烊不晚于开门时视为跨午夜（包括 00:00–00:00 的全天营业）。
  (int, int) _range(List<OpeningHour> hours) {
    final open = hours[0].hour * 60 + hours[0].minute;
    var close = hours[1].hour * 60 + hours[1].minute;
    if (close <= open) close += 1440;
    return (open, close);
  }

  ArcadeMetroInfo? metroInfo(String languageCode) {
    final metro = transit?['metro'];
    if (metro is! Map) return null;
    String localized(Map source, String fallbackKey) {
      final names = source['names'];
      final name = names is Map ? names[languageCode] : null;
      return (name ?? source[fallbackKey] ?? '').toString();
    }

    final station = localized(metro, 'stationName');
    if (station.isEmpty) return null;
    final lines = <ArcadeMetroLine>[];
    final rawLines = metro['lines'];
    if (rawLines is List) {
      for (final line in rawLines.whereType<Map>()) {
        final name = localized(line, 'name');
        if (name.isEmpty) continue;
        lines.add(ArcadeMetroLine(
            name, _parseHexColor(line['color']) ?? const Color(0xFF6F8088)));
      }
    }
    final seconds = metro['walkSeconds'];
    final minutes = seconds is num ? (seconds / 60).ceil() : 0;
    return ArcadeMetroInfo(station, minutes, lines);
  }

  /// 可尝试拉起的地图 App，按当地常用程度排序。国内机厅的坐标与高德底图同系，
  /// 百度要声明 gcj02，否则会偏几百米。
  List<ArcadeMapLink> mapLinks({required bool isIOS}) {
    final point = latLng;
    if (point == null) return const [];
    final lat = point.latitude;
    final lng = point.longitude;
    final inChina = timezone?.name == 'Asia/Shanghai';
    final amapQuery = {
      'sourceApplication': 'ChiffonMai',
      'dlat': '$lat',
      'dlon': '$lng',
      'dname': name,
      'dev': '0',
      't': '1',
    };
    final amap = ArcadeMapLink(
      ArcadeMapApp.amap,
      isIOS
          ? Uri(scheme: 'iosamap', host: 'path', queryParameters: amapQuery)
          : Uri(
              scheme: 'amapuri',
              host: 'route',
              path: '/plan/',
              queryParameters: amapQuery),
      probe: Uri.parse(isIOS ? 'iosamap://' : 'amapuri://'),
    );
    final baidu = ArcadeMapLink(
      ArcadeMapApp.baidu,
      Uri(scheme: 'baidumap', host: 'map', path: '/direction', queryParameters: {
        'destination': 'name:$name|latlng:$lat,$lng',
        'coord_type': 'gcj02',
        'mode': 'transit',
        'src': '${isIOS ? 'ios' : 'andr'}.cloud.chiffonmai.ChiffonMai',
      }),
      probe: Uri.parse('baidumap://'),
    );
    final tencent = ArcadeMapLink(
      ArcadeMapApp.tencent,
      Uri(scheme: 'qqmap', host: 'map', path: '/routeplan', queryParameters: {
        'type': 'bus',
        'to': name,
        'tocoord': '$lat,$lng',
        'referer': 'ChiffonMai',
      }),
      probe: Uri.parse('qqmap://'),
    );
    final google = isIOS
        ? ArcadeMapLink(
            ArcadeMapApp.google,
            Uri(scheme: 'comgooglemaps', host: '', queryParameters: {
              'daddr': '$lat,$lng',
              'directionsmode': 'transit',
            }),
            probe: Uri.parse('comgooglemaps://'),
          )
        : ArcadeMapLink(
            ArcadeMapApp.google,
            Uri.parse('google.navigation:q=$lat,$lng'),
            probe: Uri.parse('google.navigation:q=0,0'),
          );
    final platformDefault = isIOS
        ? ArcadeMapLink(
            ArcadeMapApp.apple,
            Uri.https('maps.apple.com', '/', {
              'daddr': '$lat,$lng',
              'q': name,
              'dirflg': 'r',
            }),
          )
        : ArcadeMapLink(
            ArcadeMapApp.system,
            // 交给系统选择器，覆盖上面没列出的地图 App。
            Uri.parse('geo:$lat,$lng?q='
                '${Uri.encodeComponent('$lat,$lng($name)')}'),
            probe: Uri.parse('geo:0,0'),
          );
    return inChina
        ? [amap, baidu, tencent, google, platformDefault]
        : [google, amap, platformDefault];
  }

  /// 网页版地图，设备上没有可用的地图 App 时兜底。
  /// 国内走高德，其余走谷歌地图。
  Uri? get navigationUri {
    final point = latLng;
    if (point == null) return null;
    if (timezone?.name == 'Asia/Shanghai') {
      return Uri.https('uri.amap.com', '/marker', {
        'position': '${point.longitude},${point.latitude}',
        'name': name,
        'src': 'ChiffonMai',
        'coordinate': 'gaode',
        'callnative': '1',
      });
    }
    return Uri.https('www.google.com', '/maps/search/',
        {'api': '1', 'query': '${point.latitude},${point.longitude}'});
  }

  Uri get nearcadeUri => Uri.https('nearcade.cn', '/shops/$shopId');
}

Color? _parseHexColor(Object? raw) {
  if (raw is! String) return null;
  final hex = raw.replaceFirst('#', '');
  final value = int.tryParse(hex, radix: 16);
  if (value == null || hex.length != 6) return null;
  return Color(0xFF000000 | value);
}

String formatArcadeMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutes % 60).toString().padLeft(2, '0')}';

String formatArcadeHours(List<OpeningHour> hours) =>
    '${formatArcadeMinutes(hours[0].hour * 60 + hours[0].minute)}'
    ' – ${formatArcadeMinutes(hours[1].hour * 60 + hours[1].minute)}';

const Distance _distance = Distance();

double arcadeDistanceMeters(LatLng a, LatLng b) =>
    _distance.as(LengthUnit.Meter, a, b);

String formatArcadeDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  if (meters < 100000) return '${(meters / 1000).toStringAsFixed(1)} km';
  return '${(meters / 1000).round()} km';
}

/// 只用来排序的近似距离：比真实球面距离便宜，几千家机厅平移时也不卡。
double arcadeSortDistance(LatLng a, LatLng b) {
  final dLat = a.latitude - b.latitude;
  final dLng =
      (a.longitude - b.longitude) * math.cos(a.latitude * math.pi / 180);
  return dLat * dLat + dLng * dLng;
}

/// 写入本地缓存的 JSON，字段名必须和 [Shop.fromJson] 读取的一致。
Map<String, dynamic> arcadeShopToJson(Shop s) => {
      '_id': s.id,
      'id': s.shopId,
      'name': s.name,
      'comment': s.comment,
      'isClaimed': s.isClaimed,
      'isLocked': s.isLocked,
      'isOpen': s.isOpen,
      'ownerId': s.ownerId,
      'createdAt': s.createdAt.toIso8601String(),
      'updatedAt': s.updatedAt.toIso8601String(),
      'address': {
        'detailed': s.address.detailed,
        'general': s.address.general,
        'region': s.address.region,
      },
      'location': {'type': 'Point', 'coordinates': s.location.coordinates},
      'games': [
        for (final g in s.games)
          {
            'gameId': g.gameId,
            'name': g.name,
            'titleId': g.titleId,
            'version': g.version,
            'quantity': g.quantity,
            'comment': g.comment,
            'cost': g.cost,
          }
      ],
      'openingHours': [
        for (final day in s.openingHours)
          [
            for (final h in day) {'hour': h.hour, 'minute': h.minute}
          ]
      ],
      'timezone': s.timezone == null
          ? null
          : {'name': s.timezone!.name, 'offset': s.timezone!.offset},
      'transit': s.transit,
    };
