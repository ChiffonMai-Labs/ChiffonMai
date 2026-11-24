// 歌曲搜索匹配规则单测。
//
// 规则来自乐曲查询页（`SongSearchPage`），需求要求随身听「照搬」它。
// 抽到 `utils/SongQueryMatcher.dart` 后两个调用点共用一份实现，
// 这个测试钉住字段集合与匹配方式（contains vs 精确），避免以后悄悄改掉。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/entity/Portable/PortableSong.dart';
import 'package:my_first_flutter_app/utils/SongQueryMatcher.dart';

Song _dfSong({
  required String id,
  required String title,
  String artist = 'artist',
  String genre = '舞萌',
  int bpm = 150,
  String from = 'maimai',
  List<Chart> charts = const <Chart>[],
}) {
  return Song(
    id: id,
    title: title,
    type: 'SD',
    ds: const <double>[12],
    level: const <String>['12'],
    cids: const <int>[1],
    charts: charts,
    basicInfo: BasicInfo(
      title: title,
      artist: artist,
      genre: genre,
      bpm: bpm,
      releaseDate: '',
      from: from,
      isNew: false,
    ),
  );
}

PortableSong _portableSong({
  int lxnsId = 1001,
  String divingFishId = '11001',
  String title = 'BLACK ROSE',
  String artist = 'artist',
  String genre = '舞萌',
  int bpm = 150,
}) {
  return PortableSong(
    lxnsId: lxnsId,
    divingFishId: divingFishId,
    audioId: lxnsId,
    title: title,
    artist: artist,
    genre: genre,
    bpm: bpm,
  );
}

/// 两个匹配函数收的是**已经规范化过**的查询串（生产代码里分别由
/// `SongSearchService.searchSongs` 的 `query.toLowerCase()` 和
/// `PortableSongLibrary.search` 的 [normalizeSongQuery] 负责这一步）。
/// 测试里统一走这个包装，避免误以为函数内部会自己转小写。
bool _dfMatch(Song song, String rawQuery, {List<String> aliases = const []}) =>
    matchesDivingFishSongQuery(song, normalizeSongQuery(rawQuery),
        aliases: aliases);

bool _portableMatch(
  PortableSong song,
  String rawQuery, {
  List<String> aliases = const [],
}) =>
    matchesPortableSongQuery(song, normalizeSongQuery(rawQuery),
        aliases: aliases);

void main() {
  group('normalizeSongQuery', () {
    test('去首尾空白 + 转小写；中间空格保留', () {
      expect(normalizeSongQuery('  BLACK  '), 'black');
      // 「Link CoF」这类带空格的搜索要能按预期工作，所以不删中间空格
      expect(normalizeSongQuery('Link CoF'), 'link cof');
    });
  });

  group('水鱼 Song（乐曲查询页）', () {
    final song = _dfSong(
      id: '11466',
      title: '群青シグナル',
      artist: 'halca',
      genre: 'POPSアニメ',
      bpm: 178,
      from: 'BUDDiES',
      charts: <Chart>[
        Chart(notes: <int>[100, 10, 5, 2], charter: 'はっぴー'),
      ],
    );

    test('id 精确匹配', () {
      expect(_dfMatch(song, '11466'), isTrue);
      // 不是 contains：1146 不该命中 11466
      expect(_dfMatch(song, '1146'), isFalse);
    });

    test('曲名 / 艺术家 大小写不敏感 contains', () {
      expect(_dfMatch(song, '群青'), isTrue);
      expect(_dfMatch(song, 'halca'), isTrue);
      expect(_dfMatch(song, 'HALCA'), isTrue);
      expect(_dfMatch(song, '  Halca  '), isTrue);
    });

    test('BPM 精确匹配（不是 contains）', () {
      expect(_dfMatch(song, '178'), isTrue);
      expect(_dfMatch(song, '17'), isFalse);
    });

    test('谱师 / 流派 / 版本 contains', () {
      expect(_dfMatch(song, 'はっぴー'), isTrue);
      expect(_dfMatch(song, 'pops'), isTrue);
      expect(_dfMatch(song, 'BUDDiES'), isTrue);
    });

    test('别名只在显式传入时参与匹配', () {
      expect(_dfMatch(song, '群青信号'), isFalse);
      expect(_dfMatch(song, '群青信号', aliases: const ['群青信号']), isTrue);
    });

    test('命中不了就返回 false', () {
      expect(_dfMatch(song, 'zzzz'), isFalse);
    });
  });

  group('随身听条目', () {
    final song = _portableSong();

    test('两个 id 都支持精确匹配（用户看到的编号是哪个都不奇怪）', () {
      expect(_portableMatch(song, '11001'), isTrue);
      expect(_portableMatch(song, '1001'), isTrue);
      // 精确而非 contains
      expect(_portableMatch(song, '110'), isFalse);
    });

    test('曲名 / 艺术家 / 流派 contains，BPM 精确', () {
      expect(_portableMatch(song, 'black'), isTrue);
      expect(_portableMatch(song, 'BLACK'), isTrue);
      expect(_portableMatch(song, 'artist'), isTrue);
      expect(_portableMatch(song, '舞萌'), isTrue);
      expect(_portableMatch(song, '150'), isTrue);
      expect(_portableMatch(song, '15'), isFalse);
    });

    test('别名 participates', () {
      expect(_portableMatch(song, '黑玫瑰'), isFalse);
      expect(_portableMatch(song, '黑玫瑰', aliases: const ['黑玫瑰']), isTrue);
    });

    test('空查询视为命中（随身听空搜索框要显示全部）', () {
      expect(matchesPortableSongQuery(song, ''), isTrue);
      expect(matchesPortableSongQuery(song, normalizeSongQuery('   ')), isTrue);
    });
  });

  group('模糊搜索与特殊假名容错', () {
    test('促音后接长音符 ッー 不再抛出 Bad state: No element 且保留可检索性', () {
      final caramelldansen = _dfSong(
        id: '56',
        title: 'ウッーウッーウマウマ(ﾟ∀ﾟ)',
        artist: 'Caramell',
        bpm: 165,
      );

      expect(_dfMatch(caramelldansen, '白系'), isFalse);
      expect(_dfMatch(caramelldansen, 'うまうま'), isTrue);
      expect(_dfMatch(caramelldansen, 'umauma'), isTrue);
    });

    test('正常片假名长音仍保留平假名与罗马音模糊匹配', () {
      final song = _dfSong(id: '9001', title: 'オーバー');

      expect(_dfMatch(song, 'おうばあ'), isTrue);
      expect(_dfMatch(song, 'ooba'), isTrue);
    });

    test('带 emoji 代理对与极端长音组合不抛异常', () {
      final emojiSong = _dfSong(id: '9002', title: '🎵カード');
      final middleDotSong = _dfSong(id: '9003', title: 'テストッ・ーッーー');

      expect(_dfMatch(emojiSong, 'かあど'), isTrue);
      expect(_dfMatch(emojiSong, '白系'), isFalse);
      expect(_dfMatch(middleDotSong, '白系'), isFalse);
      expect(_dfMatch(middleDotSong, 'てすと'), isTrue);
    });

    test('遍历全量曲库 union-divingfish.json 搜索「白系」零异常', () {
      final raw =
          File('assets/others/union-divingfish.json').readAsStringSync();
      final decoded = jsonDecode(raw) as List<dynamic>;
      final songs = decoded
          .map((item) => Song.fromJson(item as Map<String, dynamic>))
          .toList(growable: false);
      expect(songs, isNotEmpty);

      final query = normalizeSongQuery('白系');
      for (final song in songs) {
        expect(() => matchesDivingFishSongQuery(song, query), returnsNormally,
            reason: 'song id=${song.id}, title=${song.title}');
      }
    });

    test('收紧拼音模糊匹配：搜「白系」或「baixi」不误命中 143/571/711/11106/11637', () {
      final cases = [
        (song: _dfSong(id: '143', title: 'Fragrance'), aliases: const ['白香芋']),
        (
          song: _dfSong(id: '571', title: 'Our Wrenally'),
          aliases: const ['白夏祭'],
        ),
        (
          song: _dfSong(id: '711', title: '拝啓ドッペルゲンガー'),
          aliases: const ['拜启'],
        ),
        (song: _dfSong(id: '11106', title: 'Valsqotch'), aliases: const ['迪拜熊']),
        (song: _dfSong(id: '11637', title: 'バグ'), aliases: const ['八夕']),
      ];

      for (final item in cases) {
        expect(
          _dfMatch(item.song, '白系', aliases: item.aliases),
          isFalse,
          reason: 'song ${item.song.id} (${item.song.title}) 不应被「白系」误命中',
        );
        expect(
          _dfMatch(item.song, 'baixi', aliases: item.aliases),
          isFalse,
          reason: 'song ${item.song.id} (${item.song.title}) 不应被「baixi」误命中',
        );
      }
    });

    test('拉丁拼音按完整音节搜中文曲名/别名与英文拼写容错仍正常命中', () {
      final fragrance = _dfSong(id: '143', title: 'Fragrance');
      final haikei = _dfSong(id: '711', title: '拝啓ドッペルゲンガー');
      final valsqotch = _dfSong(id: '11106', title: 'Valsqotch');
      final bug = _dfSong(id: '11637', title: 'バグ');
      final qunqing = _dfSong(id: '11466', title: '群青シグナル');

      // 完整音节拉丁拼音搜索
      expect(_dfMatch(fragrance, 'baixiangyu', aliases: const ['白香芋']), isTrue);
      expect(_dfMatch(haikei, 'baiqi', aliases: const ['拜启']), isTrue);
      expect(_dfMatch(bug, 'baxi', aliases: const ['八夕']), isTrue);
      expect(_dfMatch(qunqing, 'qunqing'), isTrue);

      // 英文拼写小手误仍允许编辑距离容错
      expect(_dfMatch(fragrance, 'fragrnce'), isTrue);
      expect(_dfMatch(valsqotch, 'valsqoch'), isTrue);
    });
  });
}
