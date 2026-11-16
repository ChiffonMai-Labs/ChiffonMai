import 'location.dart';
import 'slide_type.dart';

class SlideSegment {
  /// Describes the target buttons
  List<Location> vertices;

  SlideType slideType;

  SlideSegment({List<Location>? vertices})
    : vertices = vertices ?? [],
      slideType = SlideType.straightLine;

  void writeTo(StringBuffer writer, Location startLocation) {
    switch (slideType) {
      case SlideType.straightLine:
        writer.write("-${vertices[0]}");
        break;
      case SlideType.ringCw:
        writer.write(
          (startLocation.index + 2) % 8 >= 4
              ? "<${vertices[0]}"
              : ">${vertices[0]}",
        );
        break;
      case SlideType.ringCcw:
        writer.write(
          (startLocation.index + 2) % 8 >= 4
              ? "<${vertices[0]}"
              : ">${vertices[0]}",
        );
        break;
      case SlideType.fold:
        writer.write("v${vertices[0]}");
        break;
      case SlideType.curveCw:
        writer.write("q${vertices[0]}");
        break;
      case SlideType.curveCcw:
        writer.write("pp${vertices[0]}");
        break;
      case SlideType.zigZagS:
        writer.write("s${vertices[0]}");
        break;
      case SlideType.zigZagZ:
        writer.write("z${vertices[0]}");
        break;
      case SlideType.edgeFold:
        writer.write("V${vertices[0]}${vertices[1]}");
        break;
      case SlideType.edgeCurveCw:
        writer.write("qq${vertices[0]}");
        break;
      case SlideType.edgeCurveCcw:
        writer.write("pp${vertices[0]}");
        break;
      case SlideType.fan:
        writer.write("w${vertices[0]}");
        break;
    }
  }
}
