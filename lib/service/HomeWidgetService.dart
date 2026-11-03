import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/CommunityProfileUtil.dart';
import '../widgets/LxnsAssetImage.dart';

/// 把数据推给系统桌面小组件，并接收小组件上的点击。
///
/// 只有 Android 有小组件，其它平台全部是空操作。
class HomeWidgetService {
  HomeWidgetService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.app/home_widget');

  static Future<void> _push(Map<String, Object?> values) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('update', values);
    } catch (e) {
      // 小组件更新失败不影响 App 本身
      debugPrint('更新桌面小组件失败: $e');
    }
  }

  static Future<void> pushRating({
    required int total,
    required int b35,
    required int b15,
  }) =>
      _push({'rating': '$total', 'b35': b35, 'b15': b15});

  /// 头像用缓存里的文件路径传过去，原生侧不用联网。
  static Future<void> pushProfile({
    required String nickname,
    required int avatarId,
  }) async {
    await _push({'nickname': nickname});
    try {
      final file = await lxnsAssetCacheManager.getSingleFile(
          lxnsIconUrl(CommunityProfileUtil.normalizeAvatarId(avatarId)));
      await _push({'avatar_path': file.path});
    } catch (e) {
      debugPrint('读取小组件头像失败: $e');
    }
  }

  static Future<void> pushServer({
    required String headline,
    required String detail,
    required String tone,
  }) =>
      _push({
        'server': headline,
        'server_detail': detail,
        'server_tone': tone,
        'server_fetch_ms': DateTime.now().millisecondsSinceEpoch,
      });

  /// [sources] 依次是各数据源的（名称、结果、语气）。
  static Future<void> pushSync({
    required String headline,
    required String detail,
    required String tone,
    required DateTime? time,
    required List<(String, String, String)> sources,
  }) =>
      _push({
        'sync': headline,
        'sync_detail': detail,
        'sync_tone': tone,
        'sync_ms': time?.millisecondsSinceEpoch ?? 0,
        for (final (index, source) in sources.indexed) ...{
          'src${index + 1}_name': source.$1,
          'src${index + 1}_value': source.$2,
          'src${index + 1}_tone': source.$3,
        },
      });

  /// 注册点击回调：[onAction] 收到要打开的功能名。
  /// 注册之后才把冷启动时攒下的点击取回来，避免比页面先到。
  static Future<void> listen(void Function(String action) onAction) async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onAction' && call.arguments is String) {
        onAction(call.arguments as String);
      }
    });
    try {
      final pending = await _channel.invokeMethod<String>('takePendingAction');
      if (pending != null && pending.isNotEmpty) onAction(pending);
    } catch (e) {
      debugPrint('读取小组件点击失败: $e');
    }
  }
}
