// 国服更新对照的口径测试。
//
// 这一层的风险不在"能不能跑"，而在**判据**：前沿算错一格（把宴会场算进去、
// 或者把国服超前上线的曲目算进来），整个页面的结论就反了 ——
// 要么所有常规新曲都被说成"国服已上线"，要么真正待补的那批被挡在候选之外。
// 所以每条规则都用构造数据钉一遍。
//
// ⚠️ 夹具刻意避开有特殊语义的 id：`11944/11945/11946` 在超前上线白名单里，
// 拿它们当"普通国服曲"会让测试测的其实是白名单那一条规则（踩过：白名单上线后
// 一批用 11946 当普通曲的夹具集体变红）。这里统一用 12000 这一档。
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_flutter_app/entity/DivingFish/Song.dart';
import 'package:my_first_flutter_app/service/Union/UnionUpdateCompareService.dart';

Song song(
  String id, {
  String title = '',
  String version = 'maimai でらっくす CiRCLE',
  String releaseDate = '',
  bool isExtra = false,
  List<int>? cids,
  String genre = 'ゲーム&バラエティ',
}) =>
    Song(
      id: id,
      title: title.isEmpty ? 'song-$id' : title,
      type: 'DX',
      ds: const [13.0],
      level: const ['13'],
      cids: cids ?? const [1],
      charts: const [],
      basicInfo: BasicInfo(
        title: title.isEmpty ? 'song-$id' : title,
        artist: 'artist',
        genre: genre,
        bpm: 180,
        releaseDate: releaseDate,
        from: version,
        isNew: false,
      ),
      isExtra: isExtra,
    );

void main() {
  group('国服更新前沿', () {
    test('没有日期时按 id 回退取水鱼（非 extra、非宴会）里的最新曲', () {
      final result = UnionUpdateCompareService.compare([
        song('11900', title: '旧曲'),
        song('12000', title: '国服最新曲'),
        song('11000'),
      ]);

      expect(result.frontier?.id, '12000');
      expect(result.frontier?.title, '国服最新曲');
      expect(result.cnSongCount, 3);
      expect(result.upcoming, isEmpty);
      expect(result.skipped, isEmpty);
    });

    test('筛选后的国服常规曲按首发日期从新到旧取前沿', () {
      final result = UnionUpdateCompareService.compare([
        song('12000', title: 'id 较大但日期较早', releaseDate: '2025-01-01'),
        song('11000', title: '日期最新', releaseDate: '2026-03-01'),
        song('11500', title: '中间日期', releaseDate: '2025-06-01'),
      ]);

      expect(result.frontier?.id, '11000');
      expect(result.cnSongs.map((s) => s.id), ['11000', '11500', '12000']);
    });

    test('宴会场（6 位 id）不参与前沿判定', () {
      // 关键陷阱：宴会 id 是 1xxxxx，若参与判定会把前沿顶到十万位，
      // 于是后面这些常规新曲全都会被误判成"国服已上线"。
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('100123', title: '宴会曲'),
        song('12001', title: '新曲', isExtra: true),
      ]);

      expect(result.frontier?.id, '12000');
      expect(result.upcoming.map((s) => s.id), ['12001']);
      expect(result.utage, isEmpty, reason: '水鱼的宴会场曲不算 union 独有');
    });

    test('maidata 追加曲（cids 全 0）不参与前沿判定', () {
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('900001', cids: const [0, 0], title: '自制谱追加'),
      ]);

      expect(result.frontier?.id, '12000');
      expect(result.cnSongCount, 1);
      expect(result.maidataCount, 1);
    });

    test('水鱼自己的宴会场算进"国服已上"，但不参与前沿判定', () {
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('100123', title: '国服宴会曲'),
      ]);

      expect(result.frontier?.id, '12000', reason: '6 位 id 不能顶到前沿上');
      expect(result.cnSongCount, 2, reason: '"国服已上"要含宴会场，否则账对不上');
      expect(result.cnRegularCount, 1);
      expect(result.totalCount, 2);
    });

    test('国服已上那段按 id 降序，第一首就是前沿', () {
      final result = UnionUpdateCompareService.compare([
        song('11000'),
        song('12000', title: '国服最新曲'),
        song('11500'),
        song('100123', title: '国服宴会曲'),
        song('12001', isExtra: true),
      ]);

      expect(result.cnSongs.map((s) => s.id), ['12000', '11500', '11000']);
      expect(result.cnSongs.first.id, result.frontier?.id,
          reason: '「国服已上」的第一行就是被标注的前沿，两处必须同一首');
      expect(result.cnSongs.map((s) => s.id), isNot(contains('100123')),
          reason: '宴会场不进这段（它不参与版本对照）');
    });

    test('id 解析不出来时按 0 处理：不会污染"最新"', () {
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('abc', title: '坏数据'),
      ]);

      expect(result.frontier?.id, '12000');
    });
  });

  group('待上线 / 被跳过 / 宴会场的切分', () {
    test('union 独有且 id 更大 → 待上线，按 id 升序', () {
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('12005', isExtra: true),
        song('12001', isExtra: true),
        song('12002', isExtra: true),
      ]);

      expect(result.upcoming.map((s) => s.id), ['12001', '12002', '12005'],
          reason: '缺少日期时回退到 id 判定，并按 id 稳定展示');
    });

    test('union 独有但 id 更小 → 被跳过（区域限定/国服没上）', () {
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('11000', isExtra: true, title: '日服独占联动'),
        song('12001', isExtra: true),
      ]);

      expect(result.skipped.map((s) => s.id), ['11000']);
      expect(result.upcoming.map((s) => s.id), ['12001']);
    });

    test('union 独有的宴会场单独一段，不算"待上线"', () {
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('100123', isExtra: true, title: '宴会曲'),
        song('12001', isExtra: true),
      ]);

      expect(result.utage.map((s) => s.id), ['100123']);
      expect(result.upcoming.map((s) => s.id), ['12001'],
          reason: '宴会 id 比前沿大，但它是宴会场，不该混进版本更新候选');
    });

    test('没有曲库数据时给出空态而不是抛异常', () {
      final result = UnionUpdateCompareService.compare(const []);

      expect(result.hasData, isFalse);
      expect(result.frontier, isNull);
      expect(result.upcoming, isEmpty);
      expect(result.upcomingByVersion, isEmpty);
    });

    test('记账合得上：union 全量 = 水鱼 + 三段 union 独有', () {
      // 真实数据的形状：union 1885 = 水鱼 1394（含宴会）+ 待上线 + 未收录 + 宴会
      final songs = <Song>[
        for (var i = 0; i < 1394; i++) song('${10000 + i}'),
        for (var i = 0; i < 92; i++) song('${11947 + i}', isExtra: true),
        for (var i = 0; i < 351; i++) song('${9000 + i}', isExtra: true),
        for (var i = 0; i < 48; i++) song('${120000 + i}', isExtra: true),
      ];
      final result = UnionUpdateCompareService.compare(songs);

      expect(result.cnSongCount, 1395,
          reason: '水鱼 1394 首，加上已确认超前上线但仍标为 extra 的 12025');
      expect(result.upcoming.length, 91);
      expect(result.skipped.length, 351);
      expect(result.utage.length, 48);
      expect(result.unionSongCount, 1885,
          reason: 'union 全量 = 水鱼 + 待上线 + 未收录 + 宴会，账必须合得上');
      expect(result.totalCount, result.unionSongCount);
      expect(result.frontier?.id, '11393');
    });
  });

  group('国服超前上线的曲目', () {
    test('超前上线不当前沿：前沿落到它下面那首', () {
      // 真实形状：国服已追上 11878，另外超前上线了 11919/11920/11944/11945/11946
      // （这些国服版本 PRiSM、日服版本 CiRCLE）
      final result = UnionUpdateCompareService.compare([
        song('11878', title: 'Pixel Galaxy'),
        song('11919', title: 'エンジェル ドリーム'),
        song('11920', title: 'Hurtling Boys'),
        song('11944', title: 'Restricted Access'),
        song('11945', title: '胡蝶乃舞'),
        song('11946', title: '零號車輛'),
        song('12025', title: '魔法仕掛けのファンタジア', isExtra: true, cids: []),
      ]);

      expect(result.frontier?.id, '11878');
      expect(result.earlyReleases.map((s) => s.id),
          ['11919', '11920', '11944', '11945', '11946', '12025']);
      expect(result.cnSongs.map((s) => s.id), ['11878'],
          reason: '超前上线的曲子不进「国服常规曲」那段');
      expect(result.cnSongCount, 7, reason: '它们仍然是国服已经有的曲子，账要算上');
      expect(result.upcoming, isEmpty,
          reason: '超前上线名单优先于 isExtra，12025 不应再进入待上线列表');
    });

    test('排除超前上线后，被它挡住的待上线曲目回到候选里', () {
      final result = UnionUpdateCompareService.compare([
        song('11878', title: 'Pixel Galaxy'),
        // 国服超前上线（国服已有 → isExtra 为 false）
        song('11920', title: 'Hurtling Boys'),
        song('11946', title: '零號車輛'),
        // 这三首才是真正待补的：id 比超前曲目小，
        // 前沿被顶到 11946 时它们会被算成"国服未收录的旧曲"
        song('11879', isExtra: true, title: '待补0'),
        song('11921', isExtra: true, title: '待补1'),
        song('11950', isExtra: true, title: '待补2'),
      ]);

      expect(result.frontier?.id, '11878');
      expect(result.upcoming.map((s) => s.id), ['11879', '11921', '11950'],
          reason: '缺少日期时参考 id，超前曲目不参与前沿');
      expect(result.skipped, isEmpty);
    });

    test('白名单按 id 精确匹配，不吃掉相邻 id', () {
      final result = UnionUpdateCompareService.compare([
        song('11878', title: '不在名单里'),
        song('11879', title: '不在名单里'),
        song('11919', title: '在名单里'),
        song('11920', title: '在名单里'),
        song('11943', title: '不在名单里'),
        song('11944', title: '在名单里'),
        song('11945', title: '在名单里'),
        song('11946', title: '在名单里'),
      ]);

      expect(result.frontier?.id, '11943',
          reason: '11943 不在名单里；11919/11920/11944~11946 都不参与前沿');
      expect(result.earlyReleases.map((s) => s.id),
          ['11919', '11920', '11944', '11945', '11946']);
    });
  });

  group('直接算作候选的曲目（11815~11821）', () {
    test('id 比前沿小也进候选，不再算"国服未收录旧曲"', () {
      // 真实形状：11815~11821 是日服 2025-07-11/12 的 PRiSM PLUS 批次，
      // id 比当前前沿（11878）小，但会随下次更新补上。
      final result = UnionUpdateCompareService.compare([
        song('11878', title: 'Pixel Galaxy'),
        song('11815', isExtra: true, title: 'IMBRUED:FLUX'),
        song('11820', isExtra: true, title: 'Xaleid◆scopiX'),
        song('11000', isExtra: true, title: '真·区域限定'),
      ]);

      expect(result.frontier?.id, '11878', reason: '这份名单不影响前沿');
      expect(result.upcoming.map((s) => s.id), ['11815', '11820'],
          reason: '要进候选，且按 id 升序排在最前面');
      expect(result.skipped.map((s) => s.id), ['11000'],
          reason: '没在名单里的、id 更小的曲目仍然留在"未收录旧曲"');
    });

    test('国服已经有了就不参与（只对 union 独有生效）', () {
      final result = UnionUpdateCompareService.compare([
        song('11815', title: '国服已上'), // 水鱼有 → isExtra 为 false
        song('11878', isExtra: true, title: '普通候选'),
      ]);

      expect(result.upcoming.map((s) => s.id), ['11878'],
          reason: '11878 按常规规则进候选；水鱼已有的 11815 不该被塞进来');
      expect(result.cnSongs.map((s) => s.id), ['11815']);
    });

    test('名单里两个源都没有的 id 不会凭空造出曲目', () {
      final result = UnionUpdateCompareService.compare([
        song('11878'),
        song('11815', isExtra: true),
      ]);

      expect(result.upcoming.map((s) => s.id), ['11815']);
      expect(result.upcoming.length, 1, reason: '11819 两边都没有，不该凭空出现');
    });
  });

  group('按首发日期补齐候选', () {
    test('11859、11876 比前沿 id 小，但首发更晚，仍纳入候选', () {
      final result = UnionUpdateCompareService.compare([
        song('11878', releaseDate: '20250801'),
        song('11859', releaseDate: '20250808', isExtra: true),
        song('11876', releaseDate: '2025-09-05', isExtra: true),
        song('11861', releaseDate: '20250801', isExtra: true),
        song('11790', releaseDate: '20250101', isExtra: true),
      ]);

      expect(result.frontier?.id, '11878');
      expect(result.upcoming.map((s) => s.id), ['11859', '11861', '11876']);
      expect(result.skipped.map((s) => s.id), ['11790']);
    });

    test('已确认待补批次下移日期起点，补齐同批及之后其他小 id 曲目', () {
      final result = UnionUpdateCompareService.compare([
        song('11878', releaseDate: '20250801'),
        song('11815', releaseDate: '20250711', isExtra: true),
        song('11827', releaseDate: '20250711', isExtra: true),
        song('11828', releaseDate: '20250716', isExtra: true),
        song('11826', releaseDate: '20250704', isExtra: true),
        song('100123', releaseDate: '20250716', isExtra: true),
        song('11944', releaseDate: '20250926', isExtra: true),
      ]);

      expect(result.upcoming.map((s) => s.id), ['11815', '11827', '11828']);
      expect(result.skipped.map((s) => s.id), ['11826']);
      expect(result.utage.map((s) => s.id), ['100123']);
      expect(result.earlyReleases.map((s) => s.id), ['11944']);
      expect(result.cnSongCount, 2);
      expect(result.totalCount, 7);
    });

    test('待补批次已被水鱼收录后，不再让参考起点停在旧日期', () {
      final result = UnionUpdateCompareService.compare([
        song('11878', releaseDate: '20250801'),
        song('11815', releaseDate: '20250711'),
        song('11828', releaseDate: '20250716', isExtra: true),
        song('11859', releaseDate: '20250808', isExtra: true),
      ]);

      expect(result.upcoming.map((s) => s.id), ['11859']);
      expect(result.skipped.map((s) => s.id), ['11828']);
      expect(result.cnSongCount, 2);
    });

    test('双方有有效日期时优先日期，不因较大的 id 把旧曲误认为新曲', () {
      final result = UnionUpdateCompareService.compare([
        song('11878', releaseDate: '20250801'),
        song('11900', releaseDate: '20250101', isExtra: true),
      ]);

      expect(result.upcoming, isEmpty);
      expect(result.skipped.map((s) => s.id), ['11900']);
    });

    test('缺少或异常日期时回退 id，已知待补曲仍保留', () {
      final result = UnionUpdateCompareService.compare([
        song('11878', releaseDate: '20250801'),
        song('11859', isExtra: true),
        song('11900', releaseDate: '20250230', isExtra: true),
        song('11815', releaseDate: '错误日期', isExtra: true),
        song('11828', releaseDate: '20250716', isExtra: true),
      ]);

      expect(result.upcoming.map((s) => s.id), ['11815', '11900']);
      expect(result.skipped.map((s) => s.id), ['11828', '11859']);
      final noFrontierDate = UnionUpdateCompareService.compare([
        song('11878'),
        song('11859', releaseDate: '20250808', isExtra: true),
        song('11900', releaseDate: '20250101', isExtra: true),
      ]);
      expect(noFrontierDate.upcoming.map((s) => s.id), ['11900']);
    });

    test('首发日期兼容两种格式，并拒绝越界日期及非日期内容', () {
      expect(UnionUpdateCompareService.releaseDateKey('20250808'), 20250808);
      expect(
          UnionUpdateCompareService.releaseDateKey(' 2025-08-08 '), 20250808);
      expect(UnionUpdateCompareService.releaseDateKey('2025-08-08T00:00:00Z'),
          20250808);
      expect(UnionUpdateCompareService.releaseDateKey('20240229'), 20240229);
      for (final raw in [
        '20250230',
        '20250229',
        '20251301',
        '20250001',
        '00000101',
        '202508',
        '批次20250808',
        ''
      ]) {
        expect(UnionUpdateCompareService.releaseDateKey(raw), 0, reason: raw);
      }
    });
  });

  group('待上线的版本分布', () {
    test('按版本分组，版本之间按该版本最小 id 排序', () {
      final result = UnionUpdateCompareService.compare([
        song('12000'),
        song('12001', version: 'maimai でらっくす CiRCLE', isExtra: true),
        song('12005', version: 'maimai でらっくす CiRCLE PLUS', isExtra: true),
        song('12006', version: 'maimai でらっくす CiRCLE PLUS', isExtra: true),
        song('12010', version: 'maimai でらっくす MAGiCAL', isExtra: true),
      ]);

      expect(
        result.upcomingByVersion.map((e) => '${e.version}=${e.count}'),
        [
          'maimai でらっくす CiRCLE=1',
          'maimai でらっくす CiRCLE PLUS=2',
          'maimai でらっくす MAGiCAL=1',
        ],
      );
    });
  });
}
