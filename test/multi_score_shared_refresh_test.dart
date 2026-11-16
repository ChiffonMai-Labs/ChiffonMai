import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';
import 'package:my_first_flutter_app/widgets/RefreshDataDialog.dart';

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.documents);

  final String documents;

  @override
  Future<String> getApplicationDocumentsPath() async => documents;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('同一批次的三个平台共用强制刷新，失败只汇总一次', () async {
    final documents = await Directory.systemTemp.createTemp('shared-refresh-');
    final maidata = File('${documents.path}/maidata_full_cache.json');
    final previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestPaths(documents.path);
    addTearDown(() async {
      PathProviderPlatform.instance = previousPaths;
      if (await maidata.exists()) await maidata.delete();
      await documents.delete();
    });
    await maidata.writeAsString('{}');
    SharedPreferences.setMockInitialValues({
      CacheKeyConstant.maidataFullCacheTimestamp:
          DateTime.now().millisecondsSinceEpoch,
    });
    final calls = <Uri, int>{};
    ApiClient.debugClient = MockClient((request) async {
      calls.update(request.url, (count) => count + 1, ifAbsent: () => 1);
      return http.Response('{}', 503);
    });
    addTearDown(() => ApiClient.debugClient = null);

    final batch = SharedRefreshData(
      forceSourceIds: {'songs_water_fish', 'songs_union', 'diff'},
      reportFailures: true,
    );
    expect(calls, isEmpty);
    final progress = <String>[];
    for (final _ in RefreshDataSource.values) {
      await Future.wait(batch.tracked(progress.add));
    }
    await batch.finish(progress.add);

    expect(calls[Uri.parse(ApiUrls.MusicDataApi)], 1);
    expect(calls[Uri.parse(ApiUrls.UnionMusicDataApi)], 1);
    expect(calls[Uri.parse(ApiUrls.DiffMusicDataApi)], 1);
    expect(calls[Uri.parse(ApiUrls.UnionApi)], 1);
    expect(progress, hasLength(6));
    expect(batch.failures, hasLength(4));
  });
}
