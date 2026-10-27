import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:my_first_flutter_app/utils/SecureCredentialStore.dart';
import 'package:my_first_flutter_app/entity/LuoXue/Collection.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/service/CommunityAvatarStore.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = CommunityAvatarStore.instance;
  Future<void> flush() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    store.value = const AvatarSyncState();
    FlutterSecureStorage.setMockInitialValues(
        {CacheKeyConstant.probeDivingFishToken: 'test-session'});
    ApiClient.debugClient = MockClient((_) async => http.Response('{}', 503));
    SharedPreferences.setMockInitialValues({
      CacheKeyConstant.lastDataSource: 'shuiyu',
      CacheKeyConstant.shuiyuUserId: 'shuiyu:12345',
      CacheKeyConstant.probeDivingFishToken: 'test-session',
    });
  });

  test('AWMC 按活动玩家 QQ 同步装扮，不依赖自动同步或串用其它来源', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.lastDataSource, 'awmc');
    await prefs.setString(CacheKeyConstant.awmcUserId, 'awmc:12345');
    await SecureCredentialStore.write(
        CacheKeyConstant.autoSyncTasks,
        jsonEncode({
          'awmc': {
            'source': 'awmc',
            'accountId': '12345',
            'token': 'synthetic-management-credential'
          }
        }));
    final writes = <Map<String, dynamic>>[];
    ApiClient.debugClient = MockClient((req) async {
      expect(req.url.scheme, 'https');
      expect(req.headers['X-Profile-Source'], 'awmc');
      expect(req.headers['X-Profile-QQ'], '12345');
      expect(req.headers.containsKey('Authorization'), false);
      expect(req.headers.containsKey('X-Auto-Sync-Token'), false);
      if (req.method == 'PUT') {
        writes.add(jsonDecode(req.body) as Map<String, dynamic>);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'awmc:12345',
              'avatarId': req.method == 'PUT'
                  ? (jsonDecode(req.body) as Map)['avatarId'] ?? 1
                  : 1,
              'profileRevision': '2',
            }
          }),
          200);
    });
    await store.activate();
    await flush();
    await store.select(73);
    await flush();
    expect(writes.single['playerId'], 'awmc:12345');
    expect(writes.single['avatarId'], 73);
    expect(store.value.pending, false);
    expect(store.value.avatarId, 73);
  });

  test('水鱼已登录但未刷新成绩时，按绑定 QQ 上传头像', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CacheKeyConstant.shuiyuUserId);
    await prefs.setString(CacheKeyConstant.probeDivingFishBindQQ, '12345');
    final puts = <Map<String, dynamic>>[];
    ApiClient.debugClient = MockClient((req) async {
      expect(req.headers['X-Profile-Source'], 'shuiyu');
      expect(req.headers['Authorization'], 'Bearer test-session');
      if (req.method == 'PUT') {
        puts.add(jsonDecode(req.body) as Map<String, dynamic>);
      } else {
        expect(req.url.queryParameters['playerId'], 'shuiyu:12345');
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'shuiyu:12345',
              'avatarId': req.method == 'PUT'
                  ? (jsonDecode(req.body) as Map)['avatarId'] ?? 1
                  : 1,
              'profileRevision': '2'
            },
          }),
          200);
    });
    await store.activate();
    await flush();
    expect(store.value.playerId, 'shuiyu:12345');
    await store.select(73);
    await flush();
    expect(puts.single['playerId'], 'shuiyu:12345');
    expect(puts.single['avatarId'], 73);
    expect(store.value.pending, false);
    expect(store.value.message, '社区装扮已同步');
  });

  test('未登录时的本机选择在登录后自动归属绑定 QQ 并上传', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(CacheKeyConstant.shuiyuUserId);
    await SecureCredentialStore.delete(CacheKeyConstant.probeDivingFishToken);
    await prefs.setString(CacheKeyConstant.cachedQQ, '99999');
    await store.activate();
    await flush();
    expect(store.value.playerId, isNull);
    expect(store.value.message, contains('登录水鱼后自动同步'));
    await store.select(73);
    await flush();
    final puts = <Map<String, dynamic>>[];
    ApiClient.debugClient = MockClient((req) async {
      if (req.method == 'PUT') {
        puts.add(jsonDecode(req.body) as Map<String, dynamic>);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'shuiyu:67890',
              'avatarId': req.method == 'PUT'
                  ? (jsonDecode(req.body) as Map)['avatarId'] ?? 1
                  : 1,
              'profileRevision': '2'
            },
          }),
          200);
    });
    await SecureCredentialStore.write(
        CacheKeyConstant.probeDivingFishToken, 'new-session');
    await prefs.setString(CacheKeyConstant.probeDivingFishBindQQ, '67890');
    await store.activate();
    await flush();
    expect(store.value.playerId, 'shuiyu:67890');
    expect(puts.single['playerId'], 'shuiyu:67890');
    expect(puts.single['avatarId'], 73);
    expect(store.value.avatarId, 73);
    expect(store.value.pending, false);
  });

  test('绑定 QQ 不替代已有玩家标记，也不借给落雪或 AWMC', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.probeDivingFishBindQQ, '67890');
    await prefs.setString(CacheKeyConstant.cachedQQ, '99999');
    ApiClient.debugClient = MockClient((req) async {
      expect(req.url.queryParameters['playerId'], 'shuiyu:12345');
      return http.Response('{}', 403);
    });
    await store.activate();
    await flush();
    expect(store.value.playerId, 'shuiyu:12345');
    var requests = 0;
    ApiClient.debugClient = MockClient((req) async {
      requests++;
      return http.Response('{}', 503);
    });
    for (final source in ['luoxue', 'awmc']) {
      await prefs.setString(CacheKeyConstant.lastDataSource, source);
      await store.activate();
      await flush();
      expect(store.value.playerId, isNull);
    }
    expect(requests, 0);
    await prefs.setString(CacheKeyConstant.lastDataSource, 'shuiyu');
    await prefs.remove(CacheKeyConstant.shuiyuUserId);
    await SecureCredentialStore.delete(CacheKeyConstant.probeDivingFishToken);
    await store.activate();
    await flush();
    expect(store.value.playerId, isNull);
    expect(requests, 0);
  });
  tearDown(() async {
    await flush();
    ApiClient.debugClient = null;
  });

  test('姓名框迁移后加入同步，局部选择保留服务器其它装扮且支持清除', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(CacheKeyConstant.selectedPlateIdCache, 101);
    final writes = <Map<String, dynamic>>[];
    final remote = <String, dynamic>{
      'playerId': 'shuiyu:12345',
      'avatarId': 73,
      'nameplate': null,
      'frame': {'id': 100101, 'name': '背景'},
      'trophy': {'id': 7, 'name': '称号'},
      'profileRevision': '1'
    };
    ApiClient.debugClient = MockClient((req) async {
      expect(req.url.path, '/api/me/appearance');
      if (req.method == 'PUT') {
        final patch = jsonDecode(req.body) as Map<String, dynamic>;
        writes.add(patch);
        for (final key in ['avatarId', 'nameplate', 'frame', 'trophy']) {
          if (patch.containsKey(key)) remote[key] = patch[key];
        }
        remote['profileRevision'] =
            '${int.parse(remote['profileRevision'] as String) + 1}';
      }
      return http.Response.bytes(
          utf8.encode(jsonEncode({'success': true, 'data': remote})), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    await store.activate();
    await flush();
    expect(writes.single['nameplate']['id'], 101);
    expect(writes.single.containsKey('avatarId'), false);
    expect(store.value.frameId, 100101);
    expect(store.value.trophyId, 7);
    await store.selectTrophy(Collection(id: 8, name: '新称号', color: 'Gold'));
    await flush();
    expect(writes.last.containsKey('frame'), false);
    expect(store.value.plateId, 101);
    expect(store.value.trophy?['name'], '新称号');
    expect(writes.last['trophy']['color'], 'Gold');
    expect(store.value.trophy?['color'], 'Gold');
    await store.selectPlate(null);
    await flush();
    expect(store.value.plateId, null);
    expect(prefs.containsKey(CacheKeyConstant.selectedPlateIdCache), false);
    expect(store.value.frameId, 100101);
    expect(store.value.message, '社区装扮已同步');
  });

  test('背景上传期间选择称号会合并待发字段，旧响应不覆盖新选择', () async {
    final first = Completer<void>(), started = Completer<void>();
    final writes = <Map<String, dynamic>>[];
    final remote = <String, dynamic>{
      'playerId': 'shuiyu:12345',
      'avatarId': 1,
      'profileRevision': '1'
    };
    ApiClient.debugClient = MockClient((req) async {
      if (req.method == 'PUT') {
        final patch = jsonDecode(req.body) as Map<String, dynamic>;
        writes.add(patch);
        if (writes.length == 1) {
          started.complete();
          await first.future;
        }
        for (final key in ['avatarId', 'nameplate', 'frame', 'trophy']) {
          if (patch.containsKey(key)) remote[key] = patch[key];
        }
        remote['profileRevision'] = '${writes.length + 1}';
      }
      return http.Response.bytes(
          utf8.encode(jsonEncode({'success': true, 'data': remote})), 200,
          headers: {'content-type': 'application/json; charset=utf-8'});
    });
    await store.activate();
    await flush();
    await store.selectFrame(Collection(id: 100101, name: '背景'));
    await started.future;
    await store.selectTrophy(Collection(id: 7, name: '称号'));
    first.complete();
    await flush();
    expect(writes.last['frame']['id'], 100101);
    expect(writes.last['trophy']['id'], 7);
    expect(store.value.frameId, 100101);
    expect(store.value.trophyId, 7);
    expect(store.value.pending, false);
  });

  test('状态级别随同步结果变化，供 Hub 页按语义着色', () async {
    ApiClient.debugClient = MockClient((req) async => http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'playerId': 'shuiyu:12345',
            'avatarId': req.method == 'PUT'
                ? (jsonDecode(req.body) as Map)['avatarId'] ?? 1
                : 1,
            'profileRevision': '2',
          }
        }),
        200));
    await store.activate();
    await flush();
    expect(store.value.message, '社区装扮已同步');
    expect(store.value.level, AvatarSyncLevel.synced);
    await store.select(73);
    await flush();
    expect(store.value.level, AvatarSyncLevel.synced);
    // 凭据失效：文案仍为「待同步」，但级别必须是异常（红色），不是黄色。
    ApiClient.debugClient = MockClient((_) async => http.Response('{}', 403));
    await store.select(74);
    await flush();
    expect(store.value.pending, true);
    expect(store.value.level, AvatarSyncLevel.error);
    expect(store.value.message, contains('待同步'));
  });

  test('服务端未确认头像时保留待同步，重试确认后才使排行榜缓存过期', () async {
    var acknowledge = false;
    ApiClient.debugClient = MockClient((req) async {
      final chosen =
          req.method == 'PUT' ? (jsonDecode(req.body) as Map)['avatarId'] : 1;
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'shuiyu:12345',
              'avatarId': acknowledge ? chosen : 1,
              'profileRevision': '3',
            },
          }),
          200);
    });
    await store.activate();
    await flush();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.avgRankingsCache, 'stale');
    await prefs.setString('${CacheKeyConstant.totalRankingsCache}_v2', 'stale');
    await store.select(73);
    await flush();
    expect(store.value.avatarId, 73);
    expect(store.value.pending, true);
    expect(store.value.level, AvatarSyncLevel.error);
    expect(prefs.getString(CacheKeyConstant.avgRankingsCache), 'stale');
    acknowledge = true;
    await store.retry();
    await flush();
    expect(store.value.pending, false);
    expect(store.value.avatarId, 73);
    expect(prefs.containsKey(CacheKeyConstant.avgRankingsCache), false);
    expect(
        prefs.containsKey('${CacheKeyConstant.totalRankingsCache}_v2'), false);
  });

  test('迁移全局旧头像只归当前玩家；切账号和换同源玩家不串头像', () async {
    final prefs = await SharedPreferences.getInstance();
    await SecureCredentialStore.delete(CacheKeyConstant.probeDivingFishToken);
    await prefs.setInt('selectedAvatarId', 73);
    await store.activate();
    await flush();
    expect(store.value.avatarId, 73);
    expect(store.value.pending, true);
    await prefs.setString(CacheKeyConstant.lastDataSource, 'awmc');
    await prefs.setString(CacheKeyConstant.awmcUserId, 'awmc:12345');
    await store.activate();
    await flush();
    expect(store.value.avatarId, 1);
    await store.select(99);
    await flush();
    await prefs.setString(CacheKeyConstant.lastDataSource, 'shuiyu');
    await store.activate();
    await flush();
    expect(store.value.avatarId, 73);
    await prefs.setString(CacheKeyConstant.shuiyuUserId, 'shuiyu:67890');
    await store.activate();
    await flush();
    expect(store.value.avatarId, 1);
  });

  test('离线选择持久保留，恢复后重试按 HTTPS 写入且使评论缓存过期', () async {
    var fail = true;
    final puts = <Map<String, dynamic>>[];
    ApiClient.debugClient = MockClient((req) async {
      expect(req.url.scheme, 'https');
      if (fail) return http.Response('{}', 503);
      if (req.method == 'PUT') {
        puts.add(jsonDecode(req.body) as Map<String, dynamic>);
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'shuiyu:12345',
              'avatarId': req.method == 'PUT'
                  ? (jsonDecode(req.body) as Map)['avatarId'] ?? 1
                  : 1,
              'profileRevision': '2',
            }
          }),
          200);
    });
    await store.activate();
    await flush();
    await store.select(73);
    await flush();
    expect(store.value.avatarId, 73);
    expect(store.value.pending, true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        '${CacheKeyConstant.songCommentsCacheTimestampPrefix}test', 123);
    fail = false;
    await store.retry();
    await flush();
    expect(puts.single['avatarId'], 73);
    expect(store.value.pending, false);
    expect(
        prefs.containsKey(
            '${CacheKeyConstant.songCommentsCacheTimestampPrefix}test'),
        false);
  });

  test('连续选择期间旧响应不能清掉新选择或写到切换后的账号', () async {
    final firstPut = Completer<void>();
    final started = Completer<void>();
    final puts = <Map<String, dynamic>>[];
    ApiClient.debugClient = MockClient((req) async {
      if (req.method == 'PUT') {
        puts.add(jsonDecode(req.body) as Map<String, dynamic>);
        if (puts.length == 1) {
          started.complete();
          await firstPut.future;
        }
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'shuiyu:12345',
              'avatarId': req.method == 'PUT'
                  ? (jsonDecode(req.body) as Map)['avatarId'] ?? 1
                  : 1,
              'profileRevision': '3',
            }
          }),
          200);
    });
    await store.activate();
    await flush();
    await store.select(73);
    await started.future;
    await store.select(99);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.lastDataSource, 'awmc');
    await prefs.setString(CacheKeyConstant.awmcUserId, 'awmc:12345');
    await store.activate();
    firstPut.complete();
    await flush();
    expect(puts.map((e) => e['avatarId']).toList(), [73, 99]);
    expect(puts.every((e) => e['playerId'] == 'shuiyu:12345'), true);
    expect(store.value.playerId, 'awmc:12345');
    expect(store.value.avatarId, 1);
    final stored =
        jsonDecode(prefs.getString('community_avatar_v1_shuiyu:12345')!) as Map;
    expect(stored['avatarId'], 99);
    expect(stored['pending'], false);
  });

  test('落雪读取服务端四项收藏品，本机默认头像和旧姓名框不作为修改上传', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.lastDataSource, 'luoxue');
    await prefs.setString(CacheKeyConstant.luoxueUserId, 'luoxue:678901');
    await prefs.setInt('selectedAvatarId', 1);
    await prefs.setInt(CacheKeyConstant.selectedPlateIdCache, 999);
    await SecureCredentialStore.write(
        CacheKeyConstant.luoxueAccessToken, 'synthetic-luoxue-token');
    var reads = 0, writes = 0;
    var avatar = 150103;
    ApiClient.debugClient = MockClient((req) async {
      expect(req.headers['X-Profile-Source'], 'luoxue');
      expect(req.url.queryParameters['playerId'], 'luoxue:678901');
      if (req.method == 'PUT') writes++;
      reads++;
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'luoxue:678901',
              'avatarId': avatar,
              'nameplate': {'id': 458013},
              'frame': {'id': 250740},
              'trophy': {'id': 5132, 'color': 'Gold'},
              'profileRevision': '5',
            }
          }),
          200);
    });
    await store.activate();
    await flush();
    expect(writes, 0);
    expect(store.value.avatarId, 150103);
    expect(store.value.plateId, 458013);
    expect(store.value.frameId, 250740);
    expect(store.value.trophyId, 5132);
    expect(store.value.pending, false);
    expect(prefs.getInt('selectedAvatarId'), 150103);
    expect(prefs.getInt(CacheKeyConstant.selectedPlateIdCache), 458013);
    avatar = 99;
    await store.activate();
    await flush();
    expect(reads, 2);
    expect(writes, 0);
    expect(store.value.avatarId, 99);
  });

  test('409 冲突重取版本但保留用户选择；凭据与活动账号不符时保持待同步', () async {
    var mismatch = false;
    final revisions = <String>[];
    ApiClient.debugClient = MockClient((req) async {
      if (mismatch) return http.Response('{}', 403);
      if (req.method == 'PUT') {
        final body = jsonDecode(req.body) as Map;
        revisions.add(body['expectedProfileRevision'] as String);
        if (revisions.length == 1) {
          return http.Response(
              jsonEncode({
                'success': false,
                'data': {'playerId': 'shuiyu:12345', 'profileRevision': '4'},
              }),
              409);
        }
      }
      return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'playerId': 'shuiyu:12345',
              'avatarId': req.method == 'PUT'
                  ? (jsonDecode(req.body) as Map)['avatarId'] ?? 1
                  : 1,
              'profileRevision': '2',
            }
          }),
          200);
    });
    await store.activate();
    await flush();
    await store.select(73);
    await flush();
    expect(revisions, ['2', '4']);
    expect(store.value.avatarId, 73);
    expect(store.value.pending, false);
    mismatch = true;
    await store.select(99);
    await flush();
    expect(store.value.pending, true);
    expect(store.value.avatarId, 99);
  });
}
