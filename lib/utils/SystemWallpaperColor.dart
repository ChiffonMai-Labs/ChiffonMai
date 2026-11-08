import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 读取 Android 已生成的系统壁纸配色，不读取壁纸图片。
class SystemWallpaperColor {
  SystemWallpaperColor._();

  static const _channel = MethodChannel('com.example.app/wallpaper_color');

  /// 返回系统主色调；非 Android 或低于 Android 12 时返回 null。
  /// 系统若选用了固定配色，返回的也是当前系统配色。
  static Future<Color?> read() async {
    if (!Platform.isAndroid) return null;
    final argb = await _channel.invokeMethod<int>('getSystemWallpaperColor');
    return argb == null ? null : Color(argb);
  }
}
