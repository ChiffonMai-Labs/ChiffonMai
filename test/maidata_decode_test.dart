import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/utils/MaidataDecodeUtil.dart';

void main() {
  test('多行 inote 必须完整解析物量和四种 BREAK 绝赞', () {
    const content = '''
&title=解析测试
&shortid=12015
&lv_2=10.0
&inote_2=(180){1},
1,2,1b,2hb,3bx,4b[4:1],
E
''';

    final chart = MaidataDecodeUtil.decode(content).charts.single;

    expect(chart.stats?.tap, 2);
    expect(chart.stats?.breakNote, 4);
    expect(chart.breakStats?.trueZettaiTap, 1);
    expect(chart.breakStats?.trueZettaiHold, 1);
    expect(chart.breakStats?.protectedZettai, 1);
    expect(chart.breakStats?.star, 1);
    expect(chart.stats?.protectedNotes, 1);
    expect(chart.stats?.unprotectedNotes, 4);
  });

  test('保护套 NOTE 按已解析类别统计，不把其它含 x 的音符或绝赞星星算入', () {
    final stats = MaidataDecodeUtil.parseInote(
        '1x/2,3hx[4:1]/4h[4:1],5bx,6bhx[4:1],7b,8bh[4:1],'
        '1hb[4:1],2b[4:1],3?-5[4:1],C1,C2x,4xh[4:1],E');

    expect(stats.tap, 2);
    expect(stats.hold, 3);
    expect(stats.breakNote, 6);
    expect(stats.slide, 1);
    expect(stats.touch, 2);
    expect(stats.protectedNotes, 5);
    expect(stats.unprotectedNotes, 5);
    expect(stats.protectedNotes + stats.unprotectedNotes, 10);
    expect(stats.protectedTap, 1);
    expect(stats.protectedHold, 2);
    expect(stats.tap - stats.protectedTap, 1);
    expect(stats.hold - stats.protectedHold, 1);
  });

  test('保护套 NOTE 统计经过 isolate 数据转换后仍保留各难度的数值', () {
    const content = '''
&title=保护套统计测试
&shortid=12015
&lv_2=10.0
&inote_2=1x,2h[4:1],3bx,4b,E
&lv_3=11.0
&inote_3=1,2hx[4:1],3bh[4:1],E
''';
    final maps = MaidataDecodeUtil.batchDecodeForIsolate([content]);
    final decoded = MaidataDecodeUtil.fromIsolateMap(maps.single);

    expect(decoded.charts[0].stats?.protectedNotes, 2);
    expect(decoded.charts[0].stats?.unprotectedNotes, 2);
    expect(decoded.charts[1].stats?.protectedNotes, 1);
    expect(decoded.charts[1].stats?.unprotectedNotes, 2);
    expect(decoded.charts[0].stats?.protectedTap, 1);
    expect(decoded.charts[0].stats?.protectedHold, 0);
    expect(decoded.charts[1].stats?.protectedTap, 0);
    expect(decoded.charts[1].stats?.protectedHold, 1);
  });
}
