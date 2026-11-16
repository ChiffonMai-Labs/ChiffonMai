import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../entity/LuoXue/Collection.dart';

class CommunityTravelMember {
  static const slotCount = 5;
  static const maxLevel = 9999;
  static const maxSuperAwakening = 99;
  static const awakeningLevels = [9, 49, 99, 299, 999, 9999];

  final Collection character;
  final int level;
  final int superAwakening;

  const CommunityTravelMember(
    this.character, {
    this.level = 1,
    this.superAwakening = 0,
  });

  int get stars => superAwakening > 0
      ? awakeningLevels.length
      : awakeningLevels.where((threshold) => level >= threshold).length;

  bool get hasValidProgress =>
      level >= 1 &&
      level <= maxLevel &&
      superAwakening >= 0 &&
      superAwakening <= maxSuperAwakening;

  Map<String, Object> toJson() => {
        'id': character.id,
        'name': character.name,
        'level': level,
        'superAwakening': superAwakening,
      };
}

/// 按账号保留离线设置，社区装扮同步读取同一份设置。
class CommunityTravelAppearanceStore {
  final String accountKey;

  const CommunityTravelAppearanceStore(this.accountKey);

  String get _teamKey => 'community_travel_team_v1_$accountKey';
  String get _partnerKey => 'community_travel_partner_v1_$accountKey';

  static bool _validTeam(List<CommunityTravelMember> members) =>
      members.length == CommunityTravelMember.slotCount &&
      members.map((member) => member.character.id).toSet().length ==
          members.length &&
      members.every((member) => member.hasValidProgress);

  Future<({List<CommunityTravelMember>? members, Collection? partner})>
      load() async {
    final prefs = await SharedPreferences.getInstance();
    List<CommunityTravelMember>? members;
    Collection? partner;
    try {
      members = parseTeam(jsonDecode(prefs.getString(_teamKey) ?? 'null'));
    } catch (_) {
      // 损坏的队伍由图鉴默认编成恢复。
    }
    try {
      final saved = prefs.getString(_partnerKey);
      if (saved != null) partner = parseCharacter(jsonDecode(saved));
    } catch (_) {
      // 搭档可以独立回退到图鉴默认值。
    }
    return (members: members, partner: partner);
  }

  static Collection? parseCharacter(Object? value) {
    if (value is! Map || value['id'] is! int || (value['id'] as int) < 1) {
      return null;
    }
    return Collection(
        id: value['id'] as int, name: value['name']?.toString() ?? '');
  }

  static List<CommunityTravelMember>? parseTeam(Object? value) {
    if (value is! List || value.length != CommunityTravelMember.slotCount)
      return null;
    final members = <CommunityTravelMember>[];
    for (final row in value) {
      if (row is! Map) return null;
      final character = parseCharacter(row);
      final level = row['level'], count = row['superAwakening'];
      if (character == null || level is! int || count is! int) return null;
      members.add(CommunityTravelMember(character,
          level: level, superAwakening: count));
    }
    return _validTeam(members) ? members : null;
  }

  Future<void> saveTeam(List<CommunityTravelMember> members) async {
    if (!_validTeam(members)) throw ArgumentError('旅行伙伴编成无效');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_teamKey, jsonEncode(members))) {
      throw StateError('旅行伙伴编成保存失败');
    }
  }

  Future<void> savePartner(Collection partner) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(
      _partnerKey,
      jsonEncode({'id': partner.id, 'name': partner.name}),
    )) {
      throw StateError('搭档保存失败');
    }
  }
}
