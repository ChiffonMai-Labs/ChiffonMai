import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/CacheKeyConstant.dart';

/// 保存会话令牌和导入密钥。旧版本使用 SharedPreferences，首次启动时会自动迁移。
class SecureCredentialStore {
  SecureCredentialStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keys = <String>{
    CacheKeyConstant.autoSyncTasks,
    CacheKeyConstant.awmcQuickIdentities,
    CacheKeyConstant.luoxueAccessToken,
    CacheKeyConstant.luoxueRefreshToken,
    CacheKeyConstant.probeAuthToken,
    CacheKeyConstant.probeDivingFishToken,
    CacheKeyConstant.probeDivingFishImportToken,
    CacheKeyConstant.probeLxnsImportToken,
    CacheKeyConstant.awmcToken,
    CacheKeyConstant.awmcNetImportToken,
    CacheKeyConstant.awmcPlayerSession,
    CacheKeyConstant.awmcOAuthToken,
    CacheKeyConstant.awmcOAuthVerifiedQq,
  };

  /// 每次写入或删除后递增，让展示凭据状态的界面即时重新读取。
  static final ValueNotifier<int> revision = ValueNotifier(0);

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (error) {
      // 只记录键名和异常类型；异常照常抛给调用方处理。
      debugPrint('[SecureStore] 读取 $key 失败: ${error.runtimeType}');
      rethrow;
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (error) {
      debugPrint('[SecureStore] 写入 $key 失败: ${error.runtimeType}');
      rethrow;
    }
    revision.value++;
  }

  static Future<void> delete(String key) async {
    await _storage.delete(key: key);
    revision.value++;
  }

  /// 删除全部已知凭据。删除账号时使用；单个键失败不影响其余键。
  static Future<void> deleteAll() async {
    for (final key in _keys) {
      try {
        await _storage.delete(key: key);
      } catch (error) {
        debugPrint('[SecureStore] 删除 $key 失败: ${error.runtimeType}');
      }
    }
    revision.value++;
  }

  /// 将旧版明文偏好迁移到系统安全存储；重复执行是安全的。
  static Future<void> migrateLegacy() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _keys) {
        final existing = await read(key);
        var migrated = existing != null && existing.isNotEmpty;
        if (!migrated) {
          final legacy = prefs.getString(key);
          if (legacy != null && legacy.isNotEmpty) {
            await write(key, legacy);
            migrated = true;
          }
        }
        // 只有确认安全存储已有值，才删除旧的明文副本。
        if (migrated && prefs.containsKey(key)) await prefs.remove(key);
      }
    } catch (e) {
      // 安全存储不可用时保留旧值，让应用仍能启动；下次启动继续迁移。
      debugPrint('安全凭据迁移失败，将在下次启动重试: $e');
    }
  }

  static bool isCredentialKey(String key) => _keys.contains(key);
}
