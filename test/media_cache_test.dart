import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_first_flutter_app/constant/CacheKeyConstant.dart';
import 'package:my_first_flutter_app/entity/Portable/PortableSong.dart';
import 'package:my_first_flutter_app/manager/Song/MaidataManager.dart';
import 'package:my_first_flutter_app/service/Portable/CachedSongAudioSource.dart';
import 'package:my_first_flutter_app/service/Portable/PortableSongDownloadService.dart';
import 'package:my_first_flutter_app/service/Media/SongMediaCache.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';

class _Paths extends PathProviderPlatform {
  _Paths(this.path);
  final String path;
  @override
  Future<String> getApplicationDocumentsPath() async => '$path/documents';
  @override
  Future<String> getTemporaryPath() async => '$path/temporary';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Directory documents;
  late Directory temporary;
  late PathProviderPlatform originalPaths;
  late SongMediaCache cache;
  var requests = 0;
  final audio = <int>[0x49, 0x44, 0x33, ...List<int>.filled(2045, 1)];
  final video = <int>[
    0,
    0,
    0,
    24,
    ...ascii.encode('ftypmp42'),
    ...List<int>.filled(2036, 0)
  ];
  const song = PortableSong(
      lxnsId: 1466,
      divingFishId: '11466',
      audioId: 1466,
      title: '测试曲',
      artist: '测试',
      genre: '',
      bpm: 120);

  Future<http.StreamedResponse> fetch(
      Uri uri, Map<String, String> headers) async {
    requests++;
    final bytes = uri.path.endsWith('.mp4') ? video : audio;
    return http.StreamedResponse(Stream.value(bytes), 200,
        contentLength: bytes.length);
  }

  SongMediaCache freshCache() => SongMediaCache(
      documents: () async => documents,
      temporary: () async => temporary,
      fetch: fetch,
      readLegacyCache: false);

  Future<void> seed(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
  }

  setUp(() async {
    root = await Directory('.dart_tool/cache_fix').createTemp('media_test_');
    documents = await Directory('${root.path}/documents').create();
    temporary = await Directory('${root.path}/temporary').create();
    requests = 0;
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(root.absolute.path);
    SharedPreferences.setMockInitialValues({});
    cache = freshCache();
  });
  tearDown(() async {
    ApiClient.debugClient?.close();
    ApiClient.debugClient = null;
    PathProviderPlatform.instance = originalPaths;
    await root.delete(recursive: true);
  });

  test('同一音源并发请求只下载一次，重建缓存实例和切换 SD/DX 后仍复用文件', () async {
    final files = await Future.wait([
      cache.ensureAudio('11466', urls: song.audioUrls),
      cache.ensureAudio('1466', urls: song.audioUrls),
    ]);
    expect(requests, 1);
    expect(files[0].path, files[1].path);
    final reopened =
        await freshCache().ensureAudio('11466', urls: song.audioUrls);
    expect(await reopened.readAsBytes(), audio);
    expect(requests, 1);
  });

  test('旧谱面临时文件和参考时长文件可以迁移为共享缓存', () async {
    await seed('${temporary.path}/chart_audio_11466.mp3', audio);
    final migrated = await cache.ensureAudio('1466', urls: song.audioUrls);
    expect(migrated.path, contains('portable_audio_cache'));
    await seed('${documents.path}/music_cache/1467.mp3', audio);
    await cache.ensureAudio('11467', urls: ['https://probe.invalid/1467.mp3']);
    expect(requests, 0);
  });

  test('播放加入已有音源下载时也能收到当前进度和完成进度', () async {
    final started = Completer<void>();
    final response = Completer<http.StreamedResponse>();
    final pending = SongMediaCache(
      documents: () async => documents,
      temporary: () async => temporary,
      readLegacyCache: false,
      fetch: (_, __) {
        requests++;
        started.complete();
        return response.future;
      },
    );
    final first = pending.ensureAudio('11466', urls: song.audioUrls);
    await started.future;
    final progress = <double?>[];
    final playback = pending.ensureAudio(
      '1466',
      urls: song.audioUrls,
      onProgress: (value, _, __) => progress.add(value),
    );
    expect(progress, [null]);
    response.complete(http.StreamedResponse(
      Stream.value(audio),
      200,
      contentLength: audio.length,
    ));
    final files = await Future.wait([first, playback]);
    expect(files[0].path, files[1].path);
    expect(progress, [null, 1]);
    expect(requests, 1);
  });

  test('PV 首次缓存后重新进入不请求网络，并保留原始 songId', () async {
    final file =
        await cache.ensurePv('100018', url: 'https://probe.invalid/pv.mp4');
    expect(file.path, contains('pv_100018.mp4'));
    final reopened = await freshCache()
        .ensurePv('100018', url: 'https://probe.invalid/pv.mp4');
    expect(await reopened.readAsBytes(), video);
    expect(requests, 1);
  });

  test('不完整媒体文件不发布为缓存，临时文件会清理', () async {
    final broken = SongMediaCache(
        documents: () async => documents,
        temporary: () async => temporary,
        readLegacyCache: false,
        fetch: (_, __) async => http.StreamedResponse(Stream.value(audio), 200,
            contentLength: audio.length + 10));
    await expectLater(
        broken.ensureAudio('8', urls: ['https://probe.invalid/8.mp3']),
        throwsStateError);
    expect(await broken.existingAudio('8'), isNull);
    final files = await Directory('${documents.path}/portable_audio_cache')
        .list()
        .toList();
    expect(files, isEmpty);
  });

  test('错误页不缓存，自动尝试备用音源', () async {
    final sources = <String>[];
    final fallback = SongMediaCache(
        documents: () async => documents,
        temporary: () async => temporary,
        readLegacyCache: false,
        fetch: (uri, _) async {
          sources.add(uri.host);
          return uri.host == 'bad.invalid'
              ? http.StreamedResponse(Stream.value(utf8.encode('{}')), 200,
                  headers: {'content-type': 'application/json'})
              : http.StreamedResponse(Stream.value(audio), 200,
                  contentLength: audio.length);
        });
    final file = await fallback.ensureAudio('8',
        urls: ['https://bad.invalid/8.mp3', 'https://good.invalid/8.mp3']);
    expect(sources, ['bad.invalid', 'good.invalid']);
    expect(await file.readAsBytes(), audio);
  });

  test('队列的字节范围请求读取同一份缓存，不会再次下载', () async {
    await cache.ensureAudio(song.divingFishId, urls: song.audioUrls);
    final source = CachedSongAudioSource(song, cache: cache);
    final response = await source.request(2, 18);
    expect(response.offset, 2);
    expect(response.sourceLength, audio.length);
    expect(await response.stream.expand((chunk) => chunk).toList(),
        audio.sublist(2, 18));
    await source.request();
    expect(requests, 1);
  });

  test('导出 MP3 读取播放缓存而不是重新下载', () async {
    await cache.ensureAudio(song.divingFishId, urls: song.audioUrls);
    final service = PortableSongDownloadService(
        cache: cache,
        write: (name, stream, fallback) async {
          final file = File('${root.path}/$name');
          final sink = file.openWrite();
          await sink.addStream(stream);
          await sink.close();
          return file;
        });
    final file = await service.download(song);
    expect(await file.readAsBytes(), audio);
    expect(requests, 1);
  });

  test('清理期间在途下载不能重新写回音源缓存', () async {
    final started = Completer<void>();
    final response = Completer<http.StreamedResponse>();
    final pending = SongMediaCache(
        documents: () async => documents,
        temporary: () async => temporary,
        readLegacyCache: false,
        fetch: (_, __) {
          started.complete();
          return response.future;
        });
    final download =
        pending.ensureAudio('8', urls: ['https://probe.invalid/8.mp3']);
    final check = expectLater(download, throwsStateError);
    await started.future;
    final clearing = pending.clear('audio');
    response.complete(http.StreamedResponse(Stream.value(audio), 200,
        contentLength: audio.length));
    await check;
    await clearing;
    expect(await pending.existingAudio('8'), isNull);
  });

  test('音源统计和清理覆盖共享、旧目录及旧临时文件，PV 清理后重新下载', () async {
    await cache.ensureAudio('8', urls: ['https://probe.invalid/8.mp3']);
    await seed('${documents.path}/music_cache/9.mp3', audio);
    await seed('${temporary.path}/music_cache/old.mp3', audio);
    await seed('${temporary.path}/chart_audio_10.mp3', audio);
    expect(await cache.audioUsage(), (audio.length * 4, 4));
    await cache.clear('audio');
    expect(await cache.audioUsage(), (0, 0));
    await cache.ensurePv('8', url: 'https://probe.invalid/pv.mp4');
    await cache.clear('pv');
    expect(await cache.existingPv('8'), isNull);
    await cache.ensurePv('8', url: 'https://probe.invalid/pv.mp4');
    expect(requests, 3);
  });

  test('按需单曲 maidata 落盘到独立文件，重新初始化后直接读取缓存且不再发请求', () async {
    ApiClient.debugClient = MockClient((request) async {
      requests++;
      expect(request.url.path, '/api/maidata/8');
      return http.Response('&shortid=8\n&inote_4=(120){4}1,2,3,4,E', 200);
    });
    final manager = MaidataManager.forTesting();
    final fetched = await manager.fetchMaidata('8');
    expect(fetched, contains('&shortid=8'));
    expect(
      await File('${documents.path}/maidata_cache/8.txt').exists(),
      isTrue,
    );

    final reopened = MaidataManager.forTesting();
    await reopened.initialize();
    expect(reopened.hasCachedMaidata('8'), isTrue);
    expect(await reopened.readCachedMaidata('8'), contains('&shortid=8'));
    expect(await reopened.fetchMaidata('8'), contains('&shortid=8'));
    expect(requests, 1);
  });

  test('轻量 catalog 拉取、ETag 304 复用及旧版全量缓存清理', () async {
    await seed('${documents.path}/maidata_full_cache.json', utf8.encode('{}'));
    await seed('${documents.path}/maidata_url_map.json', utf8.encode('{}'));

    var catalogCalls = 0;
    ApiClient.debugClient = MockClient((request) async {
      if (request.url.path == '/api/maidata/catalog') {
        catalogCalls++;
        if (request.headers['If-None-Match'] == '"cat-v1"') {
          return http.Response('', 304);
        }
        return http.Response(
          json.encode({
            'version': 1,
            'count': 1,
            'songs': {
              '8': ['2', '4', '5']
            },
          }),
          200,
          headers: {'etag': '"cat-v1"'},
        );
      }
      return http.Response('', 404);
    });

    final manager = MaidataManager.forTesting();
    final first = await manager.getCatalog();
    expect(first['8'], ['2', '4', '5']);
    expect(catalogCalls, 1);
    expect(
      await File('${documents.path}/maidata_full_cache.json').exists(),
      isFalse,
    );
    expect(
      await File('${documents.path}/maidata_url_map.json').exists(),
      isFalse,
    );

    final refreshed = await manager.getCatalog(forceRefresh: true);
    expect(refreshed['8'], ['2', '4', '5']);
    expect(catalogCalls, 2);
  });

  test('主源未命中时回落 WMC 兜底并持久化，clearCache 删除文件与内存', () async {
    ApiClient.debugClient = MockClient((request) async {
      requests++;
      if (request.url.host == 'chiffonmai.cloud') {
        return http.Response('not found', 404);
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
      return http.Response('&shortid=12025\n&inote_4=(120){4}1,2,3,4,E', 200);
    });
    final manager = MaidataManager.forTesting();
    final results = await Future.wait([
      manager.fetchMaidata('12025'),
      manager.fetchMaidata('12025'),
    ]);
    expect(results.every((v) => v != null && v.contains('&shortid=12025')),
        isTrue);
    expect(requests, 2); // 主源 1 次 + wmc 兜底 1 次（并发去重）

    final reopened = MaidataManager.forTesting();
    expect(await reopened.fetchMaidata('12025'), isNotNull);
    expect(requests, 2);

    await reopened.clearCache();
    expect(reopened.memoryCacheBytes, 0);
    expect(
      await File('${documents.path}/maidata_cache/12025.txt').exists(),
      isFalse,
    );
    final empty = MaidataManager.forTesting();
    await empty.initialize();
    expect(empty.hasCachedMaidata('12025'), isFalse);
  });

  test('过期单曲缓存不恢复，并删除对应持久记录', () async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${CacheKeyConstant.maidataCachePrefix}8';
    await prefs.setString(
        key,
        json.encode({
          'content': '&shortid=8\n&inote_4=1,E',
          'timestamp': DateTime.now()
              .subtract(const Duration(days: 31))
              .millisecondsSinceEpoch,
        }));
    final staleFile = File('${documents.path}/maidata_cache/9.txt');
    await staleFile.parent.create(recursive: true);
    await staleFile.writeAsString('&shortid=9\n&inote_4=1,E');
    await staleFile.setLastModified(
      DateTime.now().subtract(const Duration(days: 31)),
    );

    final manager = MaidataManager.forTesting();
    await manager.initialize();
    expect(manager.hasCachedMaidata('8'), isFalse);
    expect(manager.hasCachedMaidata('9'), isFalse);
    expect(prefs.getString(key), isNull);
    expect(await staleFile.exists(), isFalse);
  });
}
