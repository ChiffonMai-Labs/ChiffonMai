import 'package:flutter/foundation.dart';

/// 单个可自定义 NOTE 纹理槽位的元数据。
@immutable
class SimaiCustomNoteSlot {
  final String key;
  final String label;
  final String group;
  final List<String> aliases;
  final String hint;

  const SimaiCustomNoteSlot({
    required this.key,
    required this.label,
    required this.group,
    required this.aliases,
    this.hint = '',
  });
}

/// 谱面 NOTE 自定义纹理配置（仅替换已指定槽位，未指定槽位自动沿用内置皮肤）。
@immutable
class SimaiCustomNoteSkin {
  static const List<SimaiCustomNoteSlot> slots = <SimaiCustomNoteSlot>[
    SimaiCustomNoteSlot(
      key: 'tap_normal',
      label: '普通 TAP',
      group: 'TAP 音符',
      aliases: <String>['tap', 'tap_normal', 'tap_pink'],
      hint: '圆形或矩形透明底 PNG/WebP，默认建议正上方朝向一致',
    ),
    SimaiCustomNoteSlot(
      key: 'tap_each',
      label: '双押 TAP',
      group: 'TAP 音符',
      aliases: <String>['tap_each', 'each_tap'],
    ),
    SimaiCustomNoteSlot(
      key: 'tap_break',
      label: '绝赞 TAP',
      group: 'TAP 音符',
      aliases: <String>['tap_break', 'break_tap', 'break'],
    ),
    SimaiCustomNoteSlot(
      key: 'star_normal',
      label: '普通星星头',
      group: 'SLIDE 星星头',
      aliases: <String>['star', 'star_normal', 'slide_star'],
      hint: '默认朝右（向右滑星）或对称五角星贴图',
    ),
    SimaiCustomNoteSlot(
      key: 'star_each',
      label: '双押星星头',
      group: 'SLIDE 星星头',
      aliases: <String>['star_each', 'each_star'],
    ),
    SimaiCustomNoteSlot(
      key: 'star_break',
      label: '绝赞星星头',
      group: 'SLIDE 星星头',
      aliases: <String>['star_break', 'break_star'],
    ),
    SimaiCustomNoteSlot(
      key: 'star_tap_normal',
      label: '粉色星星头',
      group: 'SLIDE 星星头',
      aliases: <String>['star_pink', 'star_tap', 'star_tap_normal'],
    ),
    SimaiCustomNoteSlot(
      key: 'slide_arrow',
      label: '普通滑条箭头',
      group: 'SLIDE 滑条箭头',
      aliases: <String>['slide', 'slide_arrow', 'wifi'],
      hint: '箭头尖端朝右 (+X)，图集将保留原色渲染',
    ),
    SimaiCustomNoteSlot(
      key: 'slide_arrow_each',
      label: '双押滑条箭头',
      group: 'SLIDE 滑条箭头',
      aliases: <String>['slide_each', 'slide_arrow_each'],
    ),
    SimaiCustomNoteSlot(
      key: 'slide_arrow_break',
      label: '绝赞滑条箭头',
      group: 'SLIDE 滑条箭头',
      aliases: <String>['slide_break', 'slide_arrow_break'],
    ),
    SimaiCustomNoteSlot(
      key: 'touch_normal',
      label: '普通 TOUCH 花瓣',
      group: 'TOUCH 触摸音符',
      aliases: <String>['touch', 'touch_normal'],
      hint: '单瓣三角指向右 (+X)',
    ),
    SimaiCustomNoteSlot(
      key: 'touch_each',
      label: '双押 TOUCH 花瓣',
      group: 'TOUCH 触摸音符',
      aliases: <String>['touch_each'],
    ),
    SimaiCustomNoteSlot(
      key: 'touch_break',
      label: '绝赞 TOUCH 花瓣',
      group: 'TOUCH 触摸音符',
      aliases: <String>['touch_break'],
    ),
    SimaiCustomNoteSlot(
      key: 'touch_multi',
      label: '多押 TOUCH 花瓣',
      group: 'TOUCH 触摸音符',
      aliases: <String>['touch_multi'],
    ),
    SimaiCustomNoteSlot(
      key: 'touch_center',
      label: 'TOUCH 中心点',
      group: 'TOUCH 触摸音符',
      aliases: <String>['touch_center', 'touch_point'],
    ),
  ];

  static final Map<String, SimaiCustomNoteSlot> _slotByKey =
      <String, SimaiCustomNoteSlot>{
        for (final slot in slots) slot.key: slot,
      };

  static final Map<String, String> _aliasToKey = <String, String>{
    for (final slot in slots) ...<String, String>{
      slot.key: slot.key,
      for (final alias in slot.aliases) alias: slot.key,
    },
  };

  static const SimaiCustomNoteSkin empty =
      SimaiCustomNoteSkin._(<String, String>{});

  final Map<String, String> texturePaths;

  const SimaiCustomNoteSkin._(this.texturePaths);

  factory SimaiCustomNoteSkin(Map<String, String> rawPaths) {
    if (rawPaths.isEmpty) return empty;
    final cleaned = <String, String>{};
    for (final slot in slots) {
      final path = rawPaths[slot.key]?.trim();
      if (path != null && path.isNotEmpty) {
        cleaned[slot.key] = path;
      }
    }
    if (cleaned.isEmpty) return empty;
    return SimaiCustomNoteSkin._(Map<String, String>.unmodifiable(cleaned));
  }

  factory SimaiCustomNoteSkin.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final map = <String, String>{};
    raw.forEach((key, value) {
      if (key is String && value is String) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          map[key] = trimmed;
        }
      }
    });
    return SimaiCustomNoteSkin(map);
  }

  bool get isEmpty => texturePaths.isEmpty;

  bool get isNotEmpty => texturePaths.isNotEmpty;

  int get customizedCount => texturePaths.length;

  String? pathFor(String key) => texturePaths[key];

  SimaiCustomNoteSkin withSlot(String key, String? path) {
    if (!_slotByKey.containsKey(key)) return this;
    final next = Map<String, String>.from(texturePaths);
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      next.remove(key);
    } else {
      next[key] = trimmed;
    }
    return SimaiCustomNoteSkin(next);
  }

  SimaiCustomNoteSkin merge(Map<String, String> additions) {
    if (additions.isEmpty) return this;
    final next = Map<String, String>.from(texturePaths);
    additions.forEach((key, value) {
      if (_slotByKey.containsKey(key) && value.trim().isNotEmpty) {
        next[key] = value.trim();
      }
    });
    return SimaiCustomNoteSkin(next);
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(texturePaths);

  /// 从皮肤包文件名（不含路径与扩展名）匹配内置槽位键。
  static String? matchSlotKeyFromFileName(String fileName) {
    final slash = fileName.lastIndexOf(RegExp(r'[/\\]'));
    final base = slash >= 0 ? fileName.substring(slash + 1) : fileName;
    final dot = base.lastIndexOf('.');
    final stem = (dot > 0 ? base.substring(0, dot) : base)
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    if (stem.isEmpty) return null;
    return _aliasToKey[stem];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimaiCustomNoteSkin && mapEquals(texturePaths, other.texturePaths);

  @override
  int get hashCode => Object.hashAll(
    texturePaths.entries.map((e) => Object.hash(e.key, e.value)),
  );
}
