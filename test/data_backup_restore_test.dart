// 数据备份恢复的回归测试。
//
// 背景（真机反馈方向）：恢复是「先 prefs.clear() 再逐键写回」，用户最怕两件事：
//   1. 导入之后 App「卡死」—— 恢复期间页面完全没有 loading，几百个键要写好久；
//   2. 恢复完之后，随手改一下笔记 / 收藏夹 / 星标，刚导入的数据就被旧的内存副本
//      整体覆盖回去（这些 Store 的保存都是「写整个列表」）。
//
// 这里锁住第 2 件事依赖的契约：restoreData 能正确往返 + clearFirst 的覆盖语义，
// 以及 reloadAfterRestore 确实把内存里的单例重新读了一遍。
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/service/DataBackupService.dart';
import 'package:my_first_flutter_app/utils/FavoriteFeaturesNotifier.dart';
import 'package:my_first_flutter_app/utils/UserProfileNotifier.dart';
import 'package:my_first_flutter_app/service/UserFileBackupService.dart';
import 'package:my_first_flutter_app/service/LogExportService.dart';
import 'package:my_first_flutter_app/utils/NavigationPreferences.dart';
import 'package:my_first_flutter_app/utils/SearchInteractionPreferences.dart';
import 'package:my_first_flutter_app/utils/SecureCredentialStore.dart';

/// 构造一条与导出格式一致的备份项。
Map<String, dynamic> _entry(String type, Object? value) =>
    {'type': type, 'value': value};

class _FailingPreferences extends InMemorySharedPreferencesStore {
  _FailingPreferences() : super.withData({'flutter.original': 'before'});
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.fail') return false;
    return super.setValue(type, key, value);
  }
}

class _BackupPaths extends PathProviderPlatform {
  _BackupPaths(this.root);
  final String root;
  @override
  Future<String> getApplicationDocumentsPath() async => '$root/documents';
  @override
  Future<String> getApplicationSupportPath() async => '$root/support';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = DataBackupService();
  late Directory root;
  late PathProviderPlatform originalPaths;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('chiffonmai_backup_');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _BackupPaths(root.path);
  });
  tearDown(() async {
    PathProviderPlatform.instance = originalPaths;
    await root.delete(recursive: true);
  });

  test('偏好写入失败时恢复旧偏好和历史文件，不留下半份 v3 备份', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _FailingPreferences();
    final original = File('${root.path}/support/history/original.json');
    await original.parent.create(recursive: true);
    await original.writeAsString('{"before":true}');
    await expectLater(
        service.restoreBackup({
          'version': 3,
          'files': {
            'history/new.json': {
              'content': base64Encode(utf8.encode('{}')),
              'originalPath': '/old/new.json'
            },
          },
          'data': {
            'ok': _entry('String', 'partial'),
            'fail': _entry('String', 'rejected')
          }
        }),
        throwsStateError);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('original'), 'before');
    expect(prefs.containsKey('ok'), isFalse);
    expect(prefs.containsKey('fail'), isFalse);
    expect(await original.readAsString(), '{"before":true}');
    expect(
        await File('${root.path}/support/history/new.json').exists(), isFalse);
  });

  test('全部无效的备份不会清空现有用户数据', () async {
    SharedPreferences.setMockInitialValues({'keep': 'original'});
    await expectLater(
        service.restoreBackup({
          'version': 2,
          'data': {'bad': _entry('int', 'not-a-number')}
        }),
        throwsFormatException);
    expect(
        (await SharedPreferences.getInstance()).getString('keep'), 'original');
  });

  test('旧备份中的可重建缓存和安全凭据不会重新注入', () async {
    SharedPreferences.setMockInitialValues({});
    final count = await service.restoreData({
      'navigation_bar_style': _entry('String', 'expandingPill'),
      CacheKeyConstant.maidataFullCache: _entry('String', '过期缓存'),
      CacheKeyConstant.autoSyncTasks: _entry('String', '敏感任务'),
    });
    expect(count, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('navigation_bar_style'), 'expandingPill');
    expect(prefs.containsKey(CacheKeyConstant.maidataFullCache), isFalse);
    expect(prefs.containsKey(CacheKeyConstant.autoSyncTasks), isFalse);
  });

  test('v3 收集历史、背景和谱面归档，排除音源和 maidata', () async {
    SharedPreferences.setMockInitialValues({});
    Future<File> create(String path, String value) async {
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      return file.writeAsString(value);
    }

    await create('support/history/luoxue_123.json', '{"schemaVersion":1}');
    await create('documents/custom_chart_play/archives/song.adx', '谱面包');
    await create('documents/portable_pv_cache/movie.mp4', '视频缓存');
    await create('documents/maidata_full_cache.json', '{}');
    final bg = await create('original/bg.png', '背景图');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(CacheKeyConstant.customBackgroundPath, bg.path);
    final files = await UserFileBackupService.collect(prefs);
    expect(files.keys.toSet(),
        {'history/luoxue_123.json', 'archives/song.adx', 'background/bg.png'});
  });

  test('v3 恢复用户文件并改写跨设备背景与谱面归档路径', () async {
    SharedPreferences.setMockInitialValues({});
    const oldBg = '/old-device/bg.png', oldChart = '/old-device/song.adx';
    final files = {
      'history/shuiyu_123.json': {
        'content': base64Encode(utf8.encode('{}')),
        'originalPath': '/old-device/shuiyu_123.json'
      },
      'background/bg.png': {
        'content': base64Encode([1, 2, 3]),
        'originalPath': oldBg
      },
      'archives/song.adx': {
        'content': base64Encode([4, 5, 6]),
        'originalPath': oldChart
      },
    };
    await service.restoreBackup({
      'version': 3,
      'files': files,
      'data': {
        CacheKeyConstant.customBackgroundPath: _entry('String', oldBg),
        'custom_chart_package_history_v1': _entry(
            'String',
            jsonEncode([
              {'archivedPath': oldChart}
            ])),
      }
    });
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(CacheKeyConstant.customBackgroundPath)!;
    expect(path, contains(root.path));
    expect(await File(path).readAsBytes(), [1, 2, 3]);
    final history =
        jsonDecode(prefs.getString('custom_chart_package_history_v1')!);
    expect(await File(history[0]['archivedPath']).readAsBytes(), [4, 5, 6]);
    expect(await File('${root.path}/support/history/shuiyu_123.json').exists(),
        isTrue);
  });

  test('用户文件恢复校验路径，并能回滚已覆盖的历史', () async {
    await expectLater(
        UserFileBackupService.prepare({'history/../escape.json': {}},
            clearFirst: true),
        throwsFormatException);
    final original = File('${root.path}/support/history/old.json');
    await original.parent.create(recursive: true);
    await original.writeAsString('{"old":true}');
    final restore = await UserFileBackupService.prepare({
      'history/new.json': {
        'content': base64Encode(utf8.encode('{"new":true}')),
        'originalPath': '/old/new.json'
      }
    }, clearFirst: true);
    await restore.apply();
    expect(await original.exists(), isFalse);
    await restore.rollback();
    expect(await original.readAsString(), '{"old":true}');
    expect(
        await File('${root.path}/support/history/new.json').exists(), isFalse);
  });

  test('导出日志隐藏凭据和二维码，同时保留窗口诊断', () {
    const stack = '#0 _PredictiveBackGestureDetectorState.handleStartBackGesture (package:flutter/src/widgets/navigator.dart:123:4)';
    expect(LogExportService.redact(stack), stack);
    final safe = LogExportService.redact(
        '[Window] 1080x2400 password=secret token=abc SGWCMAID123456 gw_abcdefg');
    expect(safe, contains('[Window] 1080x2400'));
    for (final secret in ['secret', 'abc', 'SGWCMAID123456', 'gw_abcdefg'])
      expect(safe, isNot(contains(secret)));
  });

  group('restoreData', () {
    test('四种基本类型 + List<String> 都能原样往返', () async {
      SharedPreferences.setMockInitialValues({});

      final backup = {
        'a_string': _entry('String', '落雪'),
        'a_int': _entry('int', 15234),
        'a_double': _entry('double', 0.8),
        'a_bool': _entry('bool', true),
        'a_list': _entry('List<String>', <String>['音乐', '收藏的功能']),
      };

      final count = await service.restoreData(backup);
      expect(count, 5);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('a_string'), '落雪');
      expect(prefs.getInt('a_int'), 15234);
      expect(prefs.getDouble('a_double'), 0.8);
      expect(prefs.getBool('a_bool'), isTrue);
      expect(prefs.getStringList('a_list'), ['音乐', '收藏的功能']);
    });

    test('clearFirst：备份里没有的键会被一并抹掉', () async {
      SharedPreferences.setMockInitialValues({
        'only_in_backup': '新值',
        'stale_key': '恢复后不该还在',
      });

      await service.restoreData({'only_in_backup': _entry('String', '新值')});

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('only_in_backup'), '新值');
      expect(prefs.containsKey('stale_key'), isFalse,
          reason: '覆盖恢复的语义就是「备份里没有的都不留」');
    });

    test('敏感键既不导出也不还原（别人分享的备份塞不进 AWMC 令牌）', () async {
      SharedPreferences.setMockInitialValues({
        CacheKeyConstant.awmcToken: 'gw_用户自己的令牌',
      });

      final count = await service.restoreData({
        'normal': _entry('String', 'ok'),
        CacheKeyConstant.awmcToken: _entry('String', 'gw_别人塞进来的'),
      });

      // 敏感键被跳过，所以只算 1 个
      expect(count, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey(CacheKeyConstant.awmcToken), isFalse,
          reason: '恢复不该把陌生人备份里的令牌写进本机');
      expect(await SecureCredentialStore.read(CacheKeyConstant.awmcToken), 'gw_用户自己的令牌',
          reason: '覆盖恢复保留本机原有授权，不采纳备份中的令牌');
    });

    test('类型对不上的坏数据只跳过那一条，不影响其余键', () async {
      SharedPreferences.setMockInitialValues({});

      final count = await service.restoreData({
        'good': _entry('String', 'ok'),
        'bad': _entry('int', '这不是数字'),
        'also_good': _entry('bool', false),
      });

      expect(count, 2);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('good'), 'ok');
      expect(prefs.getBool('also_good'), isFalse);
    });
  });

  group('reloadAfterRestore', () {
    test('星标（收藏的功能）与昵称会按恢复后的 prefs 重读', () async {
      SharedPreferences.setMockInitialValues({
        CacheKeyConstant.favoriteFeatures: <String>['旧收藏'],
        'userNickname': '旧昵称',
      });
      // 先把内存状态建立成「恢复前」的样子
      await FavoriteFeaturesNotifier.load();
      await UserProfileNotifier.load();
      expect(FavoriteFeaturesNotifier.titles, {'旧收藏'});
      expect(UserProfileNotifier.instance.value.nickname, '旧昵称');

      // 模拟恢复：prefs 被整体改写成备份里的内容
      await service.restoreData({
        CacheKeyConstant.favoriteFeatures:
            _entry('List<String>', <String>['新收藏']),
        'userNickname': _entry('String', '新昵称'),
      });

      await service.reloadAfterRestore();
      expect(
          NavigationPreferences.instance.barStyle, NavigationBarStyle.standard);
      expect(SearchInteractionPreferences.instance.usesOverlay, isTrue);

      expect(FavoriteFeaturesNotifier.titles, {'新收藏'},
          reason: '不重读的话，用户下一次点星标就会用旧集合整体覆盖恢复结果');
      expect(UserProfileNotifier.instance.value.nickname, '新昵称');
    });
  });
}
