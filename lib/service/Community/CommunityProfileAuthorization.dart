import 'dart:convert';
import '../../constant/CacheKeyConstant.dart';
import '../../utils/SecureCredentialStore.dart';
import '../../manager/AWMC/AwmcForumOAuthManager.dart';
import '../../manager/LuoXue/LuoXueOAuthManager.dart';

/// 资料、排行榜与签到接口共用各数据源的身份头。
abstract final class CommunityProfileAuthorization {
  static Future<Map<String, String>?> legacyHeaders(String player) async {
    final source = player.split(':').first;
    if (source == 'awmc') {
      if (!player.startsWith('awmc:')) return null;
      final qq = player.substring('awmc:'.length);
      final token = await AwmcForumOAuthManager.readAuthToken(expectedQq: qq);
      if (token == null || qq.isEmpty) return null;
      return {
        'Authorization': 'Bearer $token',
        'X-Profile-Source': 'awmc',
        'Content-Type': 'application/json'
      };
    }
    final String? token;
    if (source == 'shuiyu') {
      token = await SecureCredentialStore.read(
          CacheKeyConstant.probeDivingFishToken);
    } else if (source == 'luoxue') {
      token = await LuoXueOAuthManager().getAccessToken();
    } else {
      return null;
    }
    if (token == null || token.isEmpty) return null;
    return {
      'Authorization': 'Bearer $token',
      'X-Profile-Source': source,
      'Content-Type': 'application/json'
    };
  }

  static Future<Map<String, String>> ownerHeaders(String playerId) async {
    final result =
        Map<String, String>.from(await legacyHeaders(playerId) ?? const {});
    result['Content-Type'] = 'application/json';
    // AWMC 资料操作仅使用论坛授权令牌。
    if (playerId.startsWith('awmc:')) return result;
    final raw =
        await SecureCredentialStore.read(CacheKeyConstant.autoSyncTasks);
    if (raw != null) {
      dynamic data;
      try {
        data = jsonDecode(raw);
      } on FormatException {
        data = null;
      }
      if (data is Map) {
        for (final entry in data.values.whereType<Map>()) {
          if ('${entry['source']}:${entry['accountId']}' == playerId &&
              entry['token'] is String) {
            result['X-Auto-Sync-Token'] = entry['token'] as String;
            break;
          }
        }
      }
    }
    return result;
  }
}
