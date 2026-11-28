import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/utils/SongVariantUtil.dart';
import 'package:simai_flutter/simai_flutter.dart';

Song _makeSong({
  required String id,
  required String title,
  required String type,
  required List<String> level,
  String genre = '舞萌',
  List<double>? ds,
}) {
  return Song(
    id: id,
    title: title,
    type: type,
    ds: ds ?? List<double>.filled(level.length, 14.0),
    level: level,
    cids: List<int>.filled(level.length, 1),
    charts: List<Chart>.generate(
      level.length,
      (_) => Chart(notes: const [100, 0, 0, 0, 0], charter: '-'),
    ),
    basicInfo: BasicInfo(
      title: title,
      artist: 't+pazolite',
      genre: genre,
      bpm: 256,
      releaseDate: '',
      from: 'maimai',
      isNew: false,
    ),
  );
}

void main() {
  group('SongVariantUtil', () {
    final catalog227PlusOthers = <Song>[
      _makeSong(
        id: '227',
        title: 'Garakuta Doll Play',
        type: 'SD',
        level: const ['6', '9', '13', '14', '14+'],
      ),
      _makeSong(
        id: '100227',
        title: '[は]Garakuta Doll Play',
        type: 'DX',
        genre: '宴会場',
        level: const ['14?'],
      ),
      _makeSong(
        id: '110227',
        title: '[J]Garakuta Doll Play',
        type: 'DX',
        genre: '宴会場',
        level: const ['14?'],
      ),
      _makeSong(
        id: '120227',
        title: '[r]Garakuta Doll Play',
        type: 'DX',
        genre: '宴会場',
        level: const ['14?'],
      ),
      _makeSong(
        id: '130227',
        title: '[玉]Garakuta Doll Play',
        type: 'DX',
        genre: '宴会場',
        level: const ['14+?'],
      ),
      _makeSong(
        id: '140227',
        title: '[某]Garakuta Doll Play',
        type: 'DX',
        genre: '宴会場',
        level: const ['14+?'],
      ),
      // ST + DX + UTAGE 三者共存曲（199）与纯多宴谱曲（429），验证不会互相串扰
      _makeSong(
        id: '199',
        title: 'チルノのパーフェクトさんすう教室',
        type: 'SD',
        level: const ['4', '7', '10', '12+', '13+'],
      ),
      _makeSong(
        id: '10199',
        title: 'チルノのパーフェクトさんすう教室',
        type: 'DX',
        level: const ['5', '7', '11', '13+'],
      ),
      _makeSong(
        id: '100199',
        title: '[蛸]チルノのパーフェクトさんすう教室',
        type: 'DX',
        genre: '宴会場',
        level: const ['13+?'],
      ),
      _makeSong(
        id: '110429',
        title: '[宴]Wonderland Wars　オープニング',
        type: 'UTAGE',
        genre: '宴会場',
        level: const ['13?'],
      ),
      _makeSong(
        id: '120429',
        title: '[宴]Wonderland Wars　オープニング',
        type: 'UTAGE',
        genre: '宴会場',
        level: const ['13?'],
      ),
    ];

    test('resolves song 227 with all 5 UTAGE charts in order', () {
      final variants = SongVariantUtil.resolveVariants(
        catalog227PlusOthers,
        currentSongId: '227',
        currentTitle: 'Garakuta Doll Play',
        currentType: 'SD',
      );

      expect(
        variants.map((v) => v.songId).toList(),
        ['227', '100227', '110227', '120227', '130227', '140227'],
      );
      expect(variants.first.kind, SongVariantKind.standard);
      final utages = variants.skip(1).toList();
      expect(utages.length, 5);
      expect(utages.every((v) => v.kind == SongVariantKind.utage), isTrue);
      expect(
        utages.map((v) => v.utageTag).toList(),
        ['は', 'J', 'r', '玉', '某'],
      );
      expect(
        utages.map((v) => v.levelLabel).toList(),
        ['14?', '14?', '14?', '14+?', '14+?'],
      );
    });

    test('resolves song 227 family starting from an UTAGE chart (130227)', () {
      final variants = SongVariantUtil.resolveVariants(
        catalog227PlusOthers,
        currentSongId: '130227',
        currentTitle: '[玉]Garakuta Doll Play',
        currentType: 'DX',
      );

      expect(
        variants.map((v) => v.songId).toList(),
        ['227', '100227', '110227', '120227', '130227', '140227'],
      );
      expect(variants.first.kind, SongVariantKind.standard);
      expect(variants.where((v) => v.songId != '130227').length, 5);
    });

    test('resolves ST + DX + UTAGE together for song 199 and UTAGE-only 429', () {
      final variants199 = SongVariantUtil.resolveVariants(
        catalog227PlusOthers,
        currentSongId: '100199',
        currentTitle: '[蛸]チルノのパーフェクトさんすう教室',
        currentType: 'DX',
      );
      expect(
        variants199.map((v) => (v.songId, v.kind)).toList(),
        [
          ('199', SongVariantKind.standard),
          ('10199', SongVariantKind.dx),
          ('100199', SongVariantKind.utage),
        ],
      );

      final variants429 = SongVariantUtil.resolveVariants(
        catalog227PlusOthers,
        currentSongId: '110429',
        currentTitle: '[宴]Wonderland Wars　オープニング',
        currentType: 'UTAGE',
      );
      expect(variants429.map((v) => v.songId).toList(), ['110429', '120429']);
    });
  });

  group('UTAGE video export metadata', () {
    test('builds metadata for UTAGE inote_7 and missing artist/lv_7 fallbacks', () {
      final dummyCover = MemoryImage(Uint8List(0));
      final completeUtage = SimaiFile('''
&title=[は]Garakuta Doll Play
&artist=t+pazolite
&lv_7=14?
&inote_7=(256){4}1,2,3,4,E
''');
      final metadata = SimaiVideoMetadata.fromSimaiFile(
        completeUtage,
        coverImageProvider: dummyCover,
        difficulty: SimaiChartDifficulty.utage,
        inoteKey: '7',
        fallbackTitle: '[は]Garakuta Doll Play',
        fallbackArtist: '',
        fallbackLevel: '?',
      );
      expect(metadata.difficulty, SimaiChartDifficulty.utage);
      expect(metadata.difficulty.simaiIndex, 7);
      expect(metadata.difficulty.label, 'UTAGE');
      expect(metadata.title, '[は]Garakuta Doll Play');
      expect(metadata.artist, 't+pazolite');
      expect(metadata.level, '14?');

      final minimalUtage = SimaiFile('''
&title=[某]Garakuta Doll Play
&inote_7=(256){4}1,2,3,4,E
''');
      final fallbackMeta = SimaiVideoMetadata.fromSimaiFile(
        minimalUtage,
        coverImageProvider: dummyCover,
        difficulty: SimaiChartDifficulty.utage,
        inoteKey: '7',
        fallbackTitle: '[某]Garakuta Doll Play',
        fallbackArtist: '',
        fallbackLevel: '?',
      );
      expect(fallbackMeta.difficulty, SimaiChartDifficulty.utage);
      expect(fallbackMeta.title, '[某]Garakuta Doll Play');
      expect(fallbackMeta.artist, '');
      expect(fallbackMeta.level, '?');
    });
  });
}
