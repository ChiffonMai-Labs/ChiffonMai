import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_app/utils/ChartDifficulty.dart';
import 'package:my_first_flutter_app/utils/DifficultyConstantFilter.dart';

void main() {
  test('单值精确匹配，区间包含两端，兼容空格与全角输入', () {
    final exact = DifficultyConstantRange.parse('13.7');
    expect(exact.contains(13.7), isTrue);
    expect(exact.contains(13.6), isFalse);
    for (final input in [
      '10.3-10.5',
      ' 10.3 - 10.5 ',
      '１０．３～１０．５',
      '10.3—10.5',
      '10.3至10.5'
    ]) {
      final range = DifficultyConstantRange.parse(input);
      expect(range.contains(10.3), isTrue, reason: input);
      expect(range.contains(10.5), isTrue, reason: input);
      expect(range.contains(10.4), isTrue, reason: input);
      expect(range.contains(10.6), isFalse, reason: input);
    }
    expect(DifficultyConstantRange.parse('14-14').contains(14), isTrue);
  });

  test('不接受残缺、倒置、负值、非有限数值或非定数格式', () {
    for (final input in [
      '',
      '13.4-',
      '-14',
      '14-13.4',
      '0',
      '-1',
      'NaN',
      'Infinity',
      '13+',
      '1e2',
      '13-14-15',
      '1 3.4'
    ]) {
      expect(() => DifficultyConstantRange.parse(input), throwsFormatException,
          reason: input);
    }
    final range = DifficultyConstantRange.parse('13-14');
    expect(range.contains(double.nan), isFalse);
    expect(range.contains(double.infinity), isFalse);
  });

  test('EXPERT 与 MASTER 必须同时命中，不能把多个条件当成任意一个', () {
    final filter = DifficultyConstantFilter.fromInputs({
      ChartDifficulty.expert: '10.3-10.5',
      ChartDifficulty.master: '13.4-14',
    });
    expect(filter.matches([3, 7, 10.4, 13.6], chartCount: 4, isUtage: false),
        isTrue);
    expect(filter.matches([3, 7, 10.3, 14], chartCount: 4, isUtage: false),
        isTrue);
    expect(filter.matches([3, 7, 10.5, 13.4], chartCount: 4, isUtage: false),
        isTrue);
    expect(filter.matches([3, 7, 10.6, 13.6], chartCount: 4, isUtage: false),
        isFalse);
    expect(filter.matches([3, 7, 10.4, 14.1], chartCount: 4, isUtage: false),
        isFalse);
    expect(
        filter.matchingChartIndices([3, 7, 10.4, 13.6],
            chartCount: 4, isUtage: false),
        [2, 3]);
  });

  test('同名 ST 与 DX 各自匹配，不能拼接两条歌曲记录的定数', () {
    final filter = DifficultyConstantFilter.fromInputs({
      ChartDifficulty.expert: '10.3-10.5',
      ChartDifficulty.master: '13.4-14',
    });
    final records = [
      [3, 7, 10.4, 14.2],
      [3, 7, 10.7, 13.6]
    ];
    expect(
        records
            .where((ds) => filter.matches(ds, chartCount: 4, isUtage: false)),
        isEmpty);
  });

  test('没有 Re:MASTER、缺少 chart、缺少定数或零值占位均不能命中', () {
    final remaster = DifficultyConstantFilter.fromInputs(
        {ChartDifficulty.reMaster: '14-15'});
    expect(remaster.matches([3, 7, 10, 14], chartCount: 4, isUtage: false),
        isFalse);
    expect(
        remaster.matches([3, 7, 10, 14, 14.5], chartCount: 4, isUtage: false),
        isFalse);
    expect(remaster.matches([3, 7, 10, 14], chartCount: 5, isUtage: false),
        isFalse);
    expect(remaster.matches([3, 7, 10, 14, 0], chartCount: 5, isUtage: false),
        isFalse);
    expect(
        remaster.matches([3, 7, 10, 14, 14.5], chartCount: 5, isUtage: false),
        isTrue);
  });

  test('UTAGE 识别歌曲身份并检查实际谱面索引，双人宴谱任一实际定数命中即可', () {
    final filter =
        DifficultyConstantFilter.fromInputs({ChartDifficulty.utage: '13.4-14'});
    expect(filter.matches([13.6], chartCount: 1, isUtage: true), isTrue);
    expect(filter.matches([12, 13.6], chartCount: 2, isUtage: true), isTrue);
    expect(
        filter.matchingChartIndices([12, 13.6], chartCount: 2, isUtage: true),
        [1]);
    expect(filter.matches([12, 13.6], chartCount: 1, isUtage: true), isFalse);
    expect(filter.matches([0, 0], chartCount: 2, isUtage: true), isFalse);
    expect(filter.matches([3, 7, 10, 13.6], chartCount: 4, isUtage: false),
        isFalse);
    final normal =
        DifficultyConstantFilter.fromInputs({ChartDifficulty.basic: '13.4-14'});
    expect(normal.matches([13.6], chartCount: 1, isUtage: true), isFalse);
  });

  test('互斥基于是否填写，错误输入也保留所属分组；两组同时填写时拒绝匹配', () {
    final partial =
        DifficultyConstantFilter.fromInputs({ChartDifficulty.utage: '13.4-'});
    expect(partial.hasUtageInput, isTrue);
    expect(partial.hasStandardInput, isFalse);
    expect(partial.isValid, isFalse);
    final mixed = DifficultyConstantFilter.fromInputs(
        {ChartDifficulty.expert: '10.4', ChartDifficulty.utage: '13.6'});
    expect(mixed.hasStandardInput, isTrue);
    expect(mixed.hasUtageInput, isTrue);
    expect(mixed.isValid, isFalse);
    expect(mixed.matches([13.6], chartCount: 1, isUtage: true), isFalse);
    expect(
        DifficultyConstantFilter.fromInputs({ChartDifficulty.utage: ''})
            .hasUtageInput,
        isFalse);
  });

  test('留空不加条件，解析结果是独立不可变快照', () {
    final empty =
        DifficultyConstantFilter.fromInputs({ChartDifficulty.basic: '  '});
    expect(empty.hasInput, isFalse);
    expect(empty.isValid, isTrue);
    expect(empty.matches([], chartCount: 0, isUtage: false), isTrue);
    expect(empty.matches([13.6], chartCount: 1, isUtage: true), isTrue);
    final inputs = {ChartDifficulty.master: '13.4-14'};
    final filter = DifficultyConstantFilter.fromInputs(inputs);
    inputs[ChartDifficulty.master] = '15';
    expect(filter.matches([3, 7, 10, 13.6], chartCount: 4, isUtage: false),
        isTrue);
    expect(() => filter.ranges.clear(), throwsUnsupportedError);
    expect(() => filter.activeDifficulties.clear(), throwsUnsupportedError);
  });
}
