import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../constant/CacheKeyConstant.dart';
import '../l10n/AppMessages.dart';
import '../utils/CurrentDataSourceNotifier.dart';
import 'AccountStore.dart';

/// AWMC 查询账号与成绩缓存分开保存，绑定时不切换活动账号或刷新成绩。
class AccountAuthorizationStore {
  AccountAuthorizationStore._();
  static final ValueNotifier<String> _awmcAccount = ValueNotifier('');
  static ValueListenable<String> get awmcAccount => _awmcAccount;
  static int _revision = 0;
  static int _readRequest = 0;

  static Future<String> awmcQQ() async {
    final request = ++_readRequest;
    final revision = _revision;
    final prefs = await SharedPreferences.getInstance();
    final qq = prefs.getString(CacheKeyConstant.awmcLookupQQ) ??
        (await AccountStore.loadAll())[RefreshDataSource.awmc.key]?.id ??
        '';
    if (revision == _revision && request == _readRequest) {
      _awmcAccount.value = qq;
    }
    return qq;
  }

  static Future<void> saveAwmcQQ(String qq) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(CacheKeyConstant.awmcLookupQQ, qq)) {
      throw StateError(appL10n.flowCouldNotSaveQQID);
    }
    _revision++;
    _awmcAccount.value = qq;
  }
}
