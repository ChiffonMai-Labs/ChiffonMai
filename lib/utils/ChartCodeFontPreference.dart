import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

/// 谱面代码页的字体。
///
/// - [standard]：原来的样式（`Courier New`，安卓上没有该字体时回落到系统字体）；
/// - [inconsolata]：开源的 Consolas 风格等宽字体。Consolas 本身是微软专有字体，
///   安卓没有、也不能随包分发，所以用 Inconsolata 代替，由 google_fonts 运行时下载。
enum ChartCodeFont {
  standard,
  inconsolata;

  static ChartCodeFont fromKey(String? key) => ChartCodeFont.values
      .firstWhere((f) => f.name == key, orElse: () => ChartCodeFont.standard);

  TextStyle apply(TextStyle style) => switch (this) {
        ChartCodeFont.standard => style.copyWith(fontFamily: 'Courier New'),
        ChartCodeFont.inconsolata => GoogleFonts.inconsolata(textStyle: style),
      };
}

class ChartCodeFontPreference {
  ChartCodeFontPreference._();

  static Future<ChartCodeFont> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ChartCodeFont.fromKey(prefs.getString(CacheKeyConstant.chartCodeFont));
  }

  static Future<bool> save(ChartCodeFont font) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(CacheKeyConstant.chartCodeFont, font.name);
  }
}
