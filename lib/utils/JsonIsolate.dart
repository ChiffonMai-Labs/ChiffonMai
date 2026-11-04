import 'dart:convert';

import 'package:flutter/foundation.dart';

dynamic _decode(String text) => json.decode(text);

/// 解析 JSON：大文本放到后台 isolate，不卡界面；小文本直接解析，省掉开 isolate 的开销。
Future<dynamic> decodeJsonInBackground(String text) async {
  if (text.length < 64 * 1024) return json.decode(text);
  return compute(_decode, text);
}
