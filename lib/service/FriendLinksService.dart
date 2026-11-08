import 'package:my_first_flutter_app/l10n/AppMessages.dart';
import 'dart:convert';

import '../api/ApiUrls.dart';
import '../utils/ApiClient.dart';

class FriendLinkRecord {
  final String name;
  final String description;
  final String url;
  final String iconType;
  final String iconColor;

  /// 配图地址；接口没给时为空，界面显示生成的封面。
  final String imageUrl;

  const FriendLinkRecord({
    required this.name,
    required this.description,
    required this.url,
    required this.iconType,
    required this.iconColor,
    this.imageUrl = '',
  });

  factory FriendLinkRecord.fromJson(Map<String, dynamic> json) {
    return FriendLinkRecord(
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      url: (json['url'] as String? ?? '').trim(),
      iconType: (json['icon_type'] as String? ?? 'web').trim(),
      iconColor: (json['icon_color'] as String? ?? '#5C6BC0').trim(),
      imageUrl: (json['image_url'] as String? ?? '').trim(),
    );
  }
}

class FriendLinksService {
  const FriendLinksService();

  /// 接口拿不到数据时显示的内置友链。
  static const List<FriendLinkRecord> fallback = [
    FriendLinkRecord(
      name: '中二查歌',
      description: '这是ChiffonChu，一站式中二工具',
      url: 'https://github.com/k4641321/chusearchsong_flutter',
      iconType: 'github',
      iconColor: '#7E57C2',
    ),
    FriendLinkRecord(
      name: '你画我猜',
      description: '来自AWMC社区出品的网页小游戏，持续迭代中！',
      url: 'https://v.wmc.pub/draw-guess',
      iconType: 'game',
      iconColor: '#26A69A',
    ),
    FriendLinkRecord(
      name: 'BeatRail',
      description: '融合铁路元素的创新音游',
      url: 'https://beatrail-suguang.rth1.xyz/',
      iconType: 'web',
      iconColor: '#5C6BC0',
    ),
    FriendLinkRecord(
      name: 'MaiScan Rev',
      description: '一个通过封面快速查询的离线本地maimai曲库',
      url: 'https://github.com/PojavAnge/MaiScan-Rev',
      iconType: 'github',
      iconColor: '#EF6C00',
    ),
  ];

  Future<List<FriendLinkRecord>> fetch() async {
    final response = await ApiClient.get(Uri.parse(ApiUrls.FriendLinksUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final raw = decoded is Map<String, dynamic> ? decoded['links'] : decoded;
    if (raw is! List) throw FormatException(appL10n.svcInvalidFriendLinkDataFormat);
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>) FriendLinkRecord.fromJson(item),
    ].where((item) => item.name.isNotEmpty && item.url.isNotEmpty).toList();
  }
}
