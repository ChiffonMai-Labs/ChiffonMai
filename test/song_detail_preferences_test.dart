import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/manager/DivingFish/MaimaiMusicDataManager.dart';
import 'package:my_first_flutter_app/page/SongInfoPage.dart';
import 'package:my_first_flutter_app/service/SongInfoService.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:my_first_flutter_app/utils/SongDetailPreferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('首次使用默认 MASTER，四档偏好即时生效并按最后一次选择保存', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = SongDetailPreferences.instance;
    await preferences.load();
    expect(preferences.difficulty, ChartDifficulty.master);
    await Future.wait([
      preferences.setDifficulty(ChartDifficulty.basic),
      preferences.setDifficulty(ChartDifficulty.expert),
      preferences.setDifficulty(ChartDifficulty.advanced),
    ]);
    expect(preferences.difficulty, ChartDifficulty.advanced);
    final stored = await SharedPreferences.getInstance();
    expect(stored.getInt('song_detail_default_difficulty'),
        ChartDifficulty.advanced);
    await preferences.setDifficulty(ChartDifficulty.reMaster);
    expect(preferences.difficulty, ChartDifficulty.advanced);
    expect(stored.getInt('song_detail_default_difficulty'),
        ChartDifficulty.advanced);
    await stored.setInt(
        'song_detail_default_difficulty', ChartDifficulty.expert);
    await preferences.reload();
    expect(preferences.difficulty, ChartDifficulty.expert);
  });

  test('只有省略难度的入口使用偏好，显式 BASIC 和 Re:MASTER 均保留', () {
    const defaultEntry = SongInfoPage(songId: '1');
    const basicEntry =
        SongInfoPage(songId: '1', initialLevelIndex: ChartDifficulty.basic);
    const reMasterEntry =
        SongInfoPage(songId: '1', initialLevelIndex: ChartDifficulty.reMaster);
    expect(defaultEntry.isDefaultLevelIndex, isTrue);
    expect(basicEntry.isDefaultLevelIndex, isFalse);
    expect(basicEntry.initialLevelIndex, ChartDifficulty.basic);
    expect(reMasterEntry.isDefaultLevelIndex, isFalse);
    expect(reMasterEntry.initialLevelIndex, ChartDifficulty.reMaster);
  });

  test('冷启动缺少附加缓存时，本地歌曲和成绩可先返回，慢网络只影响附加数据', () async {
    SharedPreferences.setMockInitialValues({
      CacheKeyConstant.cachedSongs: jsonEncode([
        {
          'id': '1',
          'title': '冷启动测试',
          'type': 'SD',
          'level': ['1', '5', '9', '12'],
          'basic_info': {'title': '冷启动测试'},
        }
      ]),
      CacheKeyConstant.userPlayData: jsonEncode({'records': []}),
    });
    final music = MaimaiMusicDataManager()..invalidateCache();
    final slowResponse = Completer<http.Response>();
    final requested = Completer<void>();
    final requests = <Uri>[];
    final client = MockClient((request) async {
      requests.add(request.url);
      if (request.url.toString() == ApiUrls.DiffMusicDataApi) {
        requested.complete();
        return slowResponse.future;
      }
      return http.Response(
          jsonEncode({'tags': [], 'tagGroups': [], 'tagSongs': []}), 200);
    });
    ApiClient.debugClient = client;
    addTearDown(() {
      ApiClient.debugClient = null;
      client.close();
      music.invalidateCache();
    });
    final service = SongInfoService();
    final core = await service
        .loadData('1', includeSupplementaryData: false)
        .timeout(const Duration(seconds: 3));
    expect(core['songData']['id'], '1');
    expect(core['userData']['records'], isEmpty);
    expect(requests, isEmpty);

    var metadataFinished = false;
    final metadata = service.loadSupplementaryData('1').then((value) {
      metadataFinished = true;
      return value;
    });
    await requested.future.timeout(const Duration(seconds: 3));
    expect(metadataFinished, isFalse);
    // 源站一直不返回也不影响上面已经取得的歌曲与成绩。
    expect(core['songData']['title'], '冷启动测试');
    slowResponse.complete(http.Response('{"charts":{"1":[]}}', 200));
    final result = await metadata.timeout(const Duration(seconds: 3));
    expect(result['diffData'], isEmpty);
    expect(result['tagData'], isEmpty);
    expect(result['tagSongsData'], isEmpty);
    expect(requests.map((uri) => uri.toString()),
        [ApiUrls.DiffMusicDataApi, ApiUrls.TagDataApi]);
  });

  test('ALL、越界和缺失难度统一使用偏好，合法索引全数保留', () {
    for (final value in [null, -1, ChartDifficulty.utage, 99]) {
      final entry = SongInfoPage(songId: '1', initialLevelIndex: value);
      expect(entry.isDefaultLevelIndex, isTrue);
    }
    for (final value in ChartDifficulty.standardIndices) {
      final entry = SongInfoPage(songId: '1', initialLevelIndex: value);
      expect(entry.isDefaultLevelIndex, isFalse);
      expect(entry.initialLevelIndex, value);
    }
  });

  test('记录的空难度不被解析为 BASIC，数字字符串仍保留实际难度', () {
    for (final value in [null, '', -1, 99, 'unknown', 1.5, double.nan]) {
      expect(ChartDifficulty.parseStandardIndex(value), isNull);
    }
    expect(ChartDifficulty.parseStandardIndex(0), ChartDifficulty.basic);
    expect(ChartDifficulty.parseStandardIndex(0.0), ChartDifficulty.basic);
    expect(ChartDifficulty.parseStandardIndex('2'), ChartDifficulty.expert);
  });
}
