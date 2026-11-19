import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/utils/AwmcIdMap.dart';

/// AWMC 编号映射（P0-07）的回归用例。
///
/// 口径来自接入清单 P0-03 / P0-07：shortid 区间 ≥100000 为宴谱、
/// 10000–99999 为 DX、其余为 ST；DX 与基础曲号双向相差 10000；
/// shortid 只对 ST / DX 补零到 6 位，宴谱原样。
void main() {
  group('ST：原样、补零、孪生 DX', () {
    const id = 383;

    test('类型判断', () {
      expect(AwmcIdMap.kindOfChartFileId(id), AwmcChartKind.standard);
      expect(AwmcIdMap.kindOfChartFileId(1), AwmcChartKind.standard);
      expect(AwmcIdMap.kindOfChartFileId(9999), AwmcChartKind.standard);
      expect(AwmcIdMap.kindOfShortId('000383'), AwmcChartKind.standard);
    });

    test('songId ↔ chartFileId 原样', () {
      expect(AwmcIdMap.chartFileIdFromSongId(id), id);
      expect(
        AwmcIdMap.chartFileIdFromSongId(id, kind: AwmcChartKind.standard),
        id,
      );
      expect(AwmcIdMap.songIdFromChartFileId(id), id);
      expect(AwmcIdMap.baseSongId(id), id);
      expect(AwmcIdMap.normalizeSongId(id), id);
    });

    test('shortid 补零到 6 位', () {
      expect(AwmcIdMap.shortIdFromChartFileId(id), '000383');
      expect(AwmcIdMap.shortIdFromChartFileId(8), '000008');
      expect(AwmcIdMap.chartFileIdFromShortId('000383'), id);
      expect(AwmcIdMap.chartFileIdFromShortId('383'), id);
      expect(AwmcIdMap.chartFileIdFromShortId(' 000383 '), id);
    });

    test('孪生候选是 DX', () {
      expect(AwmcIdMap.twinChartFileId(id), 10383);
      expect(AwmcIdMap.coverFallbackIds(id), [383, 10383]);
    });
  });

  group('DX：双向 ±10000、5 位补零', () {
    const base = 1209;
    const chartFileId = 11209;

    test('类型判断', () {
      expect(AwmcIdMap.kindOfChartFileId(chartFileId), AwmcChartKind.dx);
      expect(AwmcIdMap.kindOfChartFileId(10000), AwmcChartKind.dx);
      expect(AwmcIdMap.kindOfChartFileId(99999), AwmcChartKind.dx);
      expect(AwmcIdMap.kindOfShortId('011209'), AwmcChartKind.dx);
    });

    test('基础曲号 → 谱面文件 id 加 10000', () {
      expect(
        AwmcIdMap.chartFileIdFromSongId(base, kind: AwmcChartKind.dx),
        chartFileId,
      );
      // 10000 已经是 5 位谱面文件 id，不再加偏移。
      expect(
        AwmcIdMap.chartFileIdFromSongId(10000, kind: AwmcChartKind.dx),
        10000,
      );
      expect(
        AwmcIdMap.chartFileIdFromSongId(9999, kind: AwmcChartKind.dx),
        19999,
      );
    });

    test('已是谱面文件 id 时幂等，不重复加偏移', () {
      expect(
        AwmcIdMap.chartFileIdFromSongId(
          chartFileId,
          kind: AwmcChartKind.dx,
        ),
        chartFileId,
      );
    });

    test('明确的基础曲号转换不做幂等猜测：5 位新曲号也照加', () {
      // 12025 是曲号、数值又落在 DX 区间；玩家实际谱面文件 id 是 22025。
      expect(
        AwmcIdMap.chartFileIdOfBaseSong(12025, AwmcChartKind.dx),
        22025,
      );
      expect(
        AwmcIdMap.chartFileIdOfBaseSong(1209, AwmcChartKind.dx),
        chartFileId,
      );
      expect(
        AwmcIdMap.chartFileIdOfBaseSong(chartFileId, AwmcChartKind.standard),
        chartFileId,
      );
    });

    test('谱面文件 id → 基础曲号去 10000，且可往返', () {
      expect(AwmcIdMap.baseSongId(chartFileId), base);
      expect(AwmcIdMap.normalizeSongId(chartFileId), base);
      expect(AwmcIdMap.songIdFromChartFileId(chartFileId), base);
      expect(
        AwmcIdMap.chartFileIdFromSongId(
          AwmcIdMap.baseSongId(chartFileId),
          kind: AwmcChartKind.dx,
        ),
        chartFileId,
      );
    });

    test('shortid 补零到 6 位', () {
      expect(AwmcIdMap.shortIdFromChartFileId(chartFileId), '011209');
      expect(AwmcIdMap.chartFileIdFromShortId('011209'), chartFileId);
    });

    test('孪生候选是 ST，且互换对称', () {
      expect(AwmcIdMap.twinChartFileId(chartFileId), base);
      expect(AwmcIdMap.twinChartFileId(10383), 383);
      expect(
        AwmcIdMap.twinChartFileId(AwmcIdMap.twinChartFileId(chartFileId)),
        chartFileId,
      );
      expect(AwmcIdMap.coverFallbackIds(chartFileId), [11209, 1209]);
    });

    test('边界 10000 的孪生是 0', () {
      expect(AwmcIdMap.twinChartFileId(10000), 0);
      expect(AwmcIdMap.coverFallbackIds(10000), [10000, 0]);
    });
  });

  group('宴谱：原样、不补零、只给自身', () {
    const id = 100363;

    test('类型判断', () {
      expect(AwmcIdMap.kindOfChartFileId(id), AwmcChartKind.utage);
      expect(AwmcIdMap.kindOfChartFileId(100000), AwmcChartKind.utage);
      expect(AwmcIdMap.kindOfShortId('100363'), AwmcChartKind.utage);
    });

    test('songId ↔ chartFileId / baseSongId 都原样', () {
      expect(AwmcIdMap.chartFileIdFromSongId(id), id);
      expect(
        AwmcIdMap.chartFileIdFromSongId(id, kind: AwmcChartKind.utage),
        id,
      );
      expect(AwmcIdMap.songIdFromChartFileId(id), id);
      expect(AwmcIdMap.baseSongId(id), id);
      expect(AwmcIdMap.normalizeSongId(id), id);
    });

    test('shortid 原样、不补零', () {
      expect(AwmcIdMap.shortIdFromChartFileId(id), '100363');
      expect(AwmcIdMap.chartFileIdFromShortId('100363'), id);
    });

    test('没有孪生，只给自身', () {
      expect(AwmcIdMap.twinChartFileId(id), isNull);
      expect(AwmcIdMap.coverFallbackIds(id), [100363]);
    });
  });

  group('非法输入', () {
    test('id 必须是 1–999999', () {
      for (final id in [null, 0, -1, 1000000]) {
        expect(AwmcIdMap.isValidChartFileId(id), isFalse);
        expect(AwmcIdMap.kindOfChartFileId(id), isNull);
        expect(AwmcIdMap.baseSongId(id), isNull);
        expect(AwmcIdMap.normalizeSongId(id), isNull);
        expect(AwmcIdMap.songIdFromChartFileId(id), isNull);
        expect(AwmcIdMap.chartFileIdFromSongId(id), isNull);
        expect(AwmcIdMap.chartFileIdFromSongId(id, kind: AwmcChartKind.dx),
            isNull);
        expect(AwmcIdMap.shortIdFromChartFileId(id), isNull);
        expect(AwmcIdMap.twinChartFileId(id), isNull);
        expect(AwmcIdMap.coverFallbackIds(id), isEmpty);
      }
      expect(AwmcIdMap.isValidChartFileId(999999), isTrue);
    });

    test('shortid 只接受 1–6 位纯数字', () {
      for (final shortid in [
        null,
        '',
        ' ',
        'abc',
        '12a',
        '-5',
        '000000',
        '1000000',
        '1234567',
        '0',
      ]) {
        expect(AwmcIdMap.isValidShortId(shortid), isFalse, reason: '$shortid');
        expect(AwmcIdMap.chartFileIdFromShortId(shortid), isNull,
            reason: '$shortid');
        expect(AwmcIdMap.kindOfShortId(shortid), isNull, reason: '$shortid');
      }
      expect(AwmcIdMap.isValidShortId('000001'), isTrue);
      expect(AwmcIdMap.isValidShortId('999999'), isTrue);
    });
  });
}
