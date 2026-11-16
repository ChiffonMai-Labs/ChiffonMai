import 'fullscreen_utils_io.dart'
    if (dart.library.html) 'fullscreen_utils_web.dart';

abstract class FullScreenUtils {
  static Future<void> enterFullScreen() => enterFullScreenImpl();
  static Future<void> exitFullScreen() => exitFullScreenImpl();
}
