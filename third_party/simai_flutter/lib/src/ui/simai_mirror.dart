import '../structures/location.dart';
import '../structures/note_group.dart';
import '../structures/slide_type.dart';

enum SimaiMirrorMode {
  /// 无
  none,

  /// 左右反
  horizontal,

  /// 上下反
  vertical,

  /// 全反（左右反 + 上下反）
  full,
}

/// Majdata-compatible mirror transforms shared by playback, gameplay input,
/// slide precomputation and video export.
class SimaiMirrorUtils {
  const SimaiMirrorUtils._();

  static Location mirrorLocation(Location location, SimaiMirrorMode mode) {
    // 无镜像或中心 C 传感器位置不变，直接返回原对象，消除每帧每音符的无谓构造开销。
    if (mode == SimaiMirrorMode.none || location.group == NoteGroup.cSensor) {
      return location;
    }

    var index = location.index;
    final shifted =
        location.group == NoteGroup.tap ||
        location.group == NoteGroup.aSensor ||
        location.group == NoteGroup.bSensor;

    // A/B/Tap 与 8 个外键同轴，D/E 错开半个扇区，分别使用 Majdata 对应镜像表。
    if (mode == SimaiMirrorMode.horizontal || mode == SimaiMirrorMode.full) {
      index = shifted ? 7 - index : (8 - index) % 8;
    }
    if (mode == SimaiMirrorMode.vertical || mode == SimaiMirrorMode.full) {
      index = shifted
          ? const <int>[3, 2, 1, 0, 7, 6, 5, 4][index]
          : const <int>[4, 3, 2, 1, 0, 7, 6, 5][index];
    }
    return Location(index, location.group);
  }

  static int mirrorTapLane(int lane, SimaiMirrorMode mode) {
    if (mode == SimaiMirrorMode.none) return lane;
    var index = lane;
    if (mode == SimaiMirrorMode.horizontal || mode == SimaiMirrorMode.full) {
      index = 7 - index;
    }
    if (mode == SimaiMirrorMode.vertical || mode == SimaiMirrorMode.full) {
      index = const <int>[3, 2, 1, 0, 7, 6, 5, 4][index];
    }
    return index;
  }

  static SlideType mirrorSlideType(SlideType type, SimaiMirrorMode mode) {
    // Two axis reflections preserve handedness; one axis reflection reverses
    // q/p, qq/pp, ring direction and s/z just like Majdata's text mirror.
    if (mode == SimaiMirrorMode.none || mode == SimaiMirrorMode.full) {
      return type;
    }
    return switch (type) {
      SlideType.ringCw => SlideType.ringCcw,
      SlideType.ringCcw => SlideType.ringCw,
      SlideType.curveCw => SlideType.curveCcw,
      SlideType.curveCcw => SlideType.curveCw,
      SlideType.edgeCurveCw => SlideType.edgeCurveCcw,
      SlideType.edgeCurveCcw => SlideType.edgeCurveCw,
      SlideType.zigZagS => SlideType.zigZagZ,
      SlideType.zigZagZ => SlideType.zigZagS,
      _ => type,
    };
  }
}
