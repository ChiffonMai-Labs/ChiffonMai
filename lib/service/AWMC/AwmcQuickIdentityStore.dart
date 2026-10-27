import 'dart:convert';

import '../../constant/CacheKeyConstant.dart';
import '../../utils/SecureCredentialStore.dart';
import '../AutoSyncService.dart';
import '../SyncStatsService.dart';

/// 二维码获取的 userId 由三个数据源共用；各数据源个人 key 仍独立保存。
/// 只使用系统安全存储，不保存二维码，也不进入普通备份。
class AwmcQuickIdentityStore {
  AwmcQuickIdentityStore._();
  static Future<void> _writes = Future.value();

  static Future<T> _serialized<T>(Future<T> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static int? _validId(dynamic value) =>
      value is int && value > 0 && value <= 0xFFFFFFFF ? value : null;

  static Future<Map<String, dynamic>> _read() async {
    final raw =
        await SecureCredentialStore.read(CacheKeyConstant.awmcQuickIdentities);
    if (raw == null) return {};
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } catch (_) {
      return {};
    }
  }

  static Future<void> _save(int userId) => SecureCredentialStore.write(
      CacheKeyConstant.awmcQuickIdentities,
      jsonEncode({'version': 2, 'userId': userId}));

  static Future<int?> _sharedId(Map<String, dynamic> data) async {
    if (data.containsKey('userId')) return _validId(data['userId']);
    // 兼容旧的逐源缓存。旧记录有不同身份时不猜测，重新扫一次二维码即可统一。
    final ids = data.values
        .whereType<Map>()
        .map((item) => _validId(item['userId']))
        .whereType<int>()
        .toSet();
    if (ids.length != 1) return null;
    final id = ids.single;
    await _save(id);
    return id;
  }

  static Future<int?> read() async {
    await _writes;
    final data = await _read();
    if (data.containsKey('userId')) return _validId(data['userId']);
    if (data.isEmpty) return null;
    // 普通读取不进入写队列；只有旧缓存迁移需要串行，并在写前重新读取。
    return _serialized(() async => _sharedId(await _read()));
  }

  static Future<void> write(int userId) {
    if (_validId(userId) == null) throw const FormatException('无效的同步凭据');
    return _serialized(() => _save(userId));
  }

  /// 删除共用凭据前撤销所有依赖它的自动同步；撤销失败则保留凭据以便重试。
  static Future<void> forget() => _serialized(() async {
        for (final platform in SyncPlatform.values) {
          await AutoSyncService.instance.disable(platform);
        }
        await SecureCredentialStore.delete(
            CacheKeyConstant.awmcQuickIdentities);
      });

  /// 清理某个数据源只撤销它的任务，不能删除其它数据源仍在使用的共用凭据。
  static Future<void> forgetSource(String source) => _serialized(() async {
        await AutoSyncService.instance.disableForSource(source);
        final data = await _read();
        if (await _sharedId(data) != null || data.containsKey('userId')) return;
        data.removeWhere((key, _) => key.startsWith('$source:'));
        if (data.isEmpty) {
          await SecureCredentialStore.delete(
              CacheKeyConstant.awmcQuickIdentities);
        } else {
          await SecureCredentialStore.write(
              CacheKeyConstant.awmcQuickIdentities, jsonEncode(data));
        }
      });
}
