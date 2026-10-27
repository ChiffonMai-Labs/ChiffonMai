import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/service/CommunityProfileAuthorization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      CacheKeyConstant.probeDivingFishToken: 'synthetic-fish-session',
      CacheKeyConstant.autoSyncTasks: jsonEncode({
        'awmc': {
          'source': 'awmc',
          'accountId': '123456',
          'token': 'synthetic-awmc-management-token',
        },
        'fish': {
          'source': 'shuiyu',
          'accountId': '123456',
          'token': 'synthetic-fish-management-token',
        },
      }),
    });
  });

  test('AWMC 只发送目标 QQ，即使存在自动同步任务也不携带其凭据', () async {
    expect(await CommunityProfileAuthorization.ownerHeaders('awmc:123456'), {
      'X-Profile-Source': 'awmc',
      'X-Profile-QQ': '123456',
      'Content-Type': 'application/json',
    });
  });

  test('AWMC 没有自动同步记录也可生成相同的 QQ 身份头', () async {
    FlutterSecureStorage.setMockInitialValues({});
    expect(await CommunityProfileAuthorization.ownerHeaders('awmc:654321'), {
      'X-Profile-Source': 'awmc',
      'X-Profile-QQ': '654321',
      'Content-Type': 'application/json',
    });
  });

  test('AWMC QQ 格式无效时不生成账号身份头', () async {
    for (final player in ['awmc:012345', 'awmc:1234', 'awmc:abc']) {
      expect(await CommunityProfileAuthorization.ownerHeaders(player),
          {'Content-Type': 'application/json'});
    }
  });

  test('水鱼继续使用自己的登录态和管理凭据，不混用同 QQ 的 AWMC 凭据', () async {
    final headers =
        await CommunityProfileAuthorization.ownerHeaders('shuiyu:123456');
    expect(headers['Authorization'], 'Bearer synthetic-fish-session');
    expect(headers['X-Profile-Source'], 'shuiyu');
    expect(headers['X-Auto-Sync-Token'], 'synthetic-fish-management-token');
    expect(headers.containsKey('X-Profile-QQ'), false);
  });
}
