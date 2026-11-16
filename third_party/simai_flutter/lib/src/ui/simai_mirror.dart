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
    if (mode == SimaiMirrorMode.none || location.group == NoteGroup.cSensor) {
      return Location(location.index, location.group);
    }

    var index = location.index;
    final shifted =
        location.group == NoteGroup.tap ||
        location.group == NoteGroup.aSensor ||
        location.group == NoteGroup.bSensor;

    // A/B/Tap use the eight button axes. D/E are half a sector shifted and
    // therefore use Majdata's special mirror maps.
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

  static int mirrorTapLane(int lane, SimaiMirrorMode mode) =>
      mirrorLocation(Location(lane, NoteGroup.tap), mode).index;

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
