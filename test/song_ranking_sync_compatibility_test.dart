import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_app/api/ApiUrls.dart';
import 'package:my_first_flutter_app/service/RankingList/SongRankingService.dart';
import 'package:my_first_flutter_app/utils/ApiClient.dart';

void main() {
  const player = 'awmc:123456';
  const records = [
    {'song_id': '1', 'level_index': 2, 'achievements': 99.1, 'dxScore': 800},
    {'song_id': '2', 'level_index': 2, 'achievements': 98.1, 'dxScore': 700},
  ];
  const stored = {
    'songId': '1',
    'difficultyIndex': 2,
    'achievementRate': 100.1,
    'dxScore': 900,
    'fc': 'fc',
    'maxDxScore': 1000,
    'updateTime': 1234,
  };

  for (final syncChanges in [false, true]) {
    test(syncChanges ? '新版接口上传变动及快照' : '旧版接口只上传新增和提升', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          expect(request.url.toString(),
              '${ApiUrls.SongRankingsPlayerUrl}/$player');
          return http.Response(
              jsonEncode({
                'success': true,
                if (syncChanges) 'syncChanges': true,
                'data': [stored],
              }),
              200);
        }
        expect(request.url.toString(), ApiUrls.SongRankingsBulkUpdateUrl);
        expect(request.headers['x-upload-ticket'], 'test-ticket');
        final body =
            jsonDecode(utf8.decode(gzip.decode(request.bodyBytes))) as Map;
        final uploaded = (body['records'] as List).cast<Map>();
        if (syncChanges) {
          expect(body['syncChanges'], isTrue);
          expect(request.headers['x-profile-qq'], '123456');
          expect(uploaded.map((item) => item['songId']), ['1', '2']);
          expect(uploaded.first['achievementRate'], 99.1);
          expect(uploaded.first['expected']['updateTime'], 1234);
        } else {
          expect(body.containsKey('syncChanges'), isFalse);
          expect(uploaded.single['songId'], '2');
          expect(uploaded.single.containsKey('expected'), isFalse);
        }
        return http.Response(
            jsonEncode({
              'success': true,
              if (syncChanges) 'syncChanges': true,
            }),
            200);
      });
      ApiClient.debugClient = client;
      addTearDown(() {
        ApiClient.debugClient = null;
        client.close();
      });
      expect(
          await SongRankingService().updateSongRankings(
            player,
            '测试',
            records,
            songs: [],
            uploadTicket: 'test-ticket',
          ),
          isTrue);
    });
  }

  test('快照请求失败时不退化为旧版写入', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      return http.Response('{}', 503);
    });
    ApiClient.debugClient = client;
    addTearDown(() {
      ApiClient.debugClient = null;
      client.close();
    });
    expect(
        await SongRankingService().updateSongRankings(
          player,
          '测试',
          records,
          songs: [],
        ),
        isFalse);
  });
}
