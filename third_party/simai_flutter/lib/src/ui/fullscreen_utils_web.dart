// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> enterFullScreenImpl() async {
  html.document.documentElement?.requestFullscreen();
}

Future<void> exitFullScreenImpl() async {
  if (html.document.fullscreenElement != null) {
    html.document.exitFullscreen();
  }
}
