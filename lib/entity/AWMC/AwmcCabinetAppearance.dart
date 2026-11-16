import '../../service/CommunityTravelAppearanceStore.dart';

/// 只读取机台当前选中的装扮，不读取图鉴库存或账号进度。
class AwmcCabinetAppearance {
  final String userName;
  final int? avatarId, frameId, plateId, trophyId, partnerId;
  final List<int?>? travelSlots;

  const AwmcCabinetAppearance._({
    required this.userName,
    this.avatarId,
    this.frameId,
    this.plateId,
    this.trophyId,
    this.partnerId,
    this.travelSlots,
  });

  static AwmcCabinetAppearance? fromBusinessData(Object? data) {
    if (data is! Map || data['userData'] is! Map) return null;
    final user = data['userData'] as Map;

    int? collectible(String current, String legacy) {
      final primary = _id(user[current]), fallback = _id(user[legacy]);
      return primary == null || primary == 0 && (fallback ?? 0) > 0
          ? fallback
          : primary;
    }

    final rawSlots = user['charaSlot'];
    return AwmcCabinetAppearance._(
      userName:
          user['userName'] is String ? (user['userName'] as String).trim() : '',
      avatarId: _id(user['iconId']),
      frameId: _id(user['frameId']),
      plateId: collectible('plateId', 'nameplateId'),
      trophyId: collectible('titleId', 'trophyId'),
      partnerId: _id(user['partnerId']),
      travelSlots:
          rawSlots is List ? rawSlots.map(_id).toList(growable: false) : null,
    );
  }

  bool get hasCompleteTeam {
    final slots = travelSlots;
    return slots != null &&
        slots.length == CommunityTravelMember.slotCount &&
        slots.every((id) => id != null && id > 0) &&
        slots.toSet().length == slots.length;
  }

  bool get hasImportableChoices =>
      (avatarId ?? 0) > 0 ||
      frameId != null ||
      plateId != null ||
      trophyId != null ||
      (partnerId ?? 0) > 0 ||
      hasCompleteTeam;

  static int? _id(Object? value) {
    final id = switch (value) {
      int n => n,
      String text => int.tryParse(text),
      _ => null,
    };
    return id != null && id >= 0 && id <= 0xFFFFFFFF ? id : null;
  }
}
