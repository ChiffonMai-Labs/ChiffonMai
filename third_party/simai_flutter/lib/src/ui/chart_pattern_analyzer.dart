import 'dart:math' as math;
import 'dart:ui';

import '../internal/syntactic_analysis/serializer.dart';
import '../structures/each_style.dart';
import '../structures/location.dart';
import '../structures/mai_chart.dart';
import '../structures/note_group.dart';
import '../structures/note_type.dart';
import '../structures/slide_type.dart';
import 'chart_timing_mapper.dart';
import 'utils/note_utils.dart';

/// 时间轴语句条中的单个节拍音符集群条目。
class SimaiStatementToken {
  final double time;
  final String text;
  final int measure;
  final double beat;

  const SimaiStatementToken({
    required this.time,
    required this.text,
    required this.measure,
    required this.beat,
  });
}

/// 谱面配置识别类型，覆盖单键、双押、定轴、阶梯、旋转、Touch 与 Slide 配置家族。
enum SimaiPatternType {
  doubleVertical('双押纵连'),
  doubleAlternating('双押交互'),
  symmetricDoubleSweep('对称双扫'),
  parallelDoubleSweep('同向双扫'),
  doubleSpin('双轨转圈'),
  vertical('纵连'),
  pairedBeat('对拍'),
  alternating('交互'),
  singleAxisSweep('单轴扫'),
  anchoredAlternating('定轴交互'),
  staircase3('三键楼梯'),
  staircase4('四键楼梯'),
  cycle3('三键循环'),
  cycle4('四键循环'),
  spin('转圈'),
  bidirectionalSpin('双向转圈'),
  sweep('扫键'),
  reversingSweep('换向扫键'),
  oscillatingSweep('往复扫键'),
  holdAccompaniedSweep('长按伴奏扫'),
  holdAccompaniedStream('长按伴奏流'),
  holdStream('连续长按'),
  touchRingSweep('Touch环扫'),
  touchSweep('Touch扫'),
  touchAlternating('Touch交互'),
  doubleTouchSweep('双Touch扫'),
  relaySlideChain('接力滑星'),
  doubleSlideChain('双星连滑'),
  wifiSlideChain('连续WiFi'),
  slideChain('连续滑星'),
  oneStrokeSlide('一笔画滑星'),
  forkSlide('分叉滑星');

  const SimaiPatternType(this.typeLabel);

  final String typeLabel;
}

/// 单个被高亮包裹的配置区间及节奏分音标识。
class SimaiTokenPattern {
  final int start;
  final int end;
  final String subdivisionLabel;
  final SimaiPatternType type;
  final bool continuesBefore;
  final bool continuesAfter;

  const SimaiTokenPattern({
    required this.start,
    required this.end,
    required this.subdivisionLabel,
    required this.type,
    this.continuesBefore = false,
    this.continuesAfter = false,
  });

  String get label {
    final prefix = continuesBefore ? '← ' : '';
    final suffix = continuesAfter ? ' →' : '';
    return '$prefix$subdivisionLabel${type.typeLabel}$suffix';
  }
}

/// 单个 4 拍小节对应的源码语句及其内部命中的配置切片。
class SimaiMeasureStatement {
  final int measure;
  final double startTime;
  final List<SimaiStatementToken> tokens;
  final List<SimaiTokenPattern> patterns;

  const SimaiMeasureStatement({
    required this.measure,
    required this.startTime,
    required this.tokens,
    required this.patterns,
  });
}

class _SlideSummary {
  final int startRing;
  final int? endRing;
  final int maxSegments;
  final bool hasFan;
  final bool hasHeadTap;

  const _SlideSummary({
    required this.startRing,
    required this.endRing,
    required this.maxSegments,
    required this.hasFan,
    required this.hasHeadTap,
  });
}

class _AnalyzedToken {
  final double time;
  final String text;
  final int measure;
  final double beat;

  /// 纯外环单键 Tap / Break（无长度、无滑星轨迹）。
  final int? singleTapRing;

  /// 单键定位键（纯单键外环 Tap 或内屏 Touch），用于跨类型纵连/交互判断。
  final String? singleLocationKey;

  /// 允许作为扫键/转圈收尾的带星头滑星所在键位（非无头星）。
  final int? trailingSlideHeadRing;

  /// 双押外环纯 Tap 键位对。
  final int? doubleTapA;
  final int? doubleTapB;
  final int doubleTapMask;

  /// 单颗外环 Hold + 单颗外环 Tap 的组合中剥离出的 Tap 键位。
  final int? holdAccompaniedTapRing;

  /// 当前时刻正处于按压期内的外环 Hold 键位掩码。
  int activeHoldMask = 0;

  /// 单颗纯外环 Hold。
  final bool isPureHold;

  /// 单颗纯内屏 Touch 坐标与传感器索引。
  final Location? singleTouchLoc;
  final Offset? singleTouchPos;

  /// 双押纯内屏 Touch 位置。
  final Location? doubleTouchLocA;
  final Location? doubleTouchLocB;
  final Offset? doubleTouchPosA;
  final Offset? doubleTouchPosB;

  /// 该集群携带的 Slide 信息（支持无头星）。
  final List<_SlideSummary> slides;
  final bool isPureSlideCollection;

  _AnalyzedToken({
    required this.time,
    required this.text,
    required this.measure,
    required this.beat,
    required this.singleTapRing,
    required this.singleLocationKey,
    required this.trailingSlideHeadRing,
    required this.doubleTapA,
    required this.doubleTapB,
    required this.doubleTapMask,
    required this.holdAccompaniedTapRing,
    required this.isPureHold,
    required this.singleTouchLoc,
    required this.singleTouchPos,
    required this.doubleTouchLocA,
    required this.doubleTouchLocB,
    required this.doubleTouchPosA,
    required this.doubleTouchPosB,
    required this.slides,
    required this.isPureSlideCollection,
  });

  int? get tapOrTrailingSlideRing => singleTapRing ?? trailingSlideHeadRing;

  int? get holdStreamTapRing {
    if (singleTapRing != null && activeHoldMask != 0) {
      if ((activeHoldMask & (1 << singleTapRing!)) == 0) {
        return singleTapRing;
      }
    }
    return holdAccompaniedTapRing;
  }

  SimaiStatementToken toStatementToken() =>
      SimaiStatementToken(time: time, text: text, measure: measure, beat: beat);
}

class _HoldInterval {
  final int ringIndex;
  final double startTime;
  final double endTime;

  const _HoldInterval({
    required this.ringIndex,
    required this.startTime,
    required this.endTime,
  });
}

class _GlobalPattern {
  final int start;
  final int end;
  final String subdivisionLabel;
  final SimaiPatternType type;

  const _GlobalPattern({
    required this.start,
    required this.end,
    required this.subdivisionLabel,
    required this.type,
  });
}

/// 谱面时间轴配置解析器：在全局时间线上识别常见舞萌 DX 配置，并按小节投影切片。
class SimaiChartPatternAnalyzer {
  const SimaiChartPatternAnalyzer._();

  static const double _sweepMaxBeatGap = 0.28;
  static const double _sweepFallbackMaxTimeSec = 0.135;
  static const double _sweepHardMaxTimeSec = 0.22;

  static List<SimaiMeasureStatement> buildStatements(
    MaiChart chart,
    List<double> measureStarts,
  ) {
    if (measureStarts.isEmpty) return const [];

    final tokens = <_AnalyzedToken>[];
    final holdIntervals = <_HoldInterval>[];
    final sourceStatements = chart.sourceNoteStatements;

    for (
      int collectionIndex = 0;
      collectionIndex < chart.noteCollections.length;
      collectionIndex++
    ) {
      final collection = chart.noteCollections[collectionIndex];
      if (collection.isEmpty) continue;
      final measure = _indexAtOrBefore(measureStarts, collection.time);
      final beat = ChartTimingMapper.beatsAtTime(chart, collection.time);
      final String text;
      if (sourceStatements != null &&
          collectionIndex < sourceStatements.length) {
        text = sourceStatements[collectionIndex]
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      } else {
        final writer = StringBuffer();
        Serializer.serializeNoteCollection(collection, writer);
        text = writer.toString();
      }

      for (final note in collection) {
        if (note.location.group == NoteGroup.tap &&
            note.length != null &&
            note.length! > 0 &&
            (note.type == NoteType.hold || note.type == NoteType.breakNote)) {
          holdIntervals.add(
            _HoldInterval(
              ringIndex: note.location.index,
              startTime: collection.time,
              endTime: collection.time + note.length!,
            ),
          );
        }
      }

      int? singleTapRing;
      String? singleLocationKey;
      int? trailingSlideHeadRing;
      bool isPureHold = false;
      Location? singleTouchLoc;
      Offset? singleTouchPos;

      if (collection.length == 1) {
        final n = collection.single;
        final isOuter = n.location.group == NoteGroup.tap;
        final isTapType =
            n.type == NoteType.tap || n.type == NoteType.breakNote;
        final isTouchType =
            n.type == NoteType.touch &&
            !n.isTouchHold &&
            n.length == null &&
            n.slidePaths.isEmpty;

        if (isOuter && isTapType && n.length == null && n.slidePaths.isEmpty) {
          singleTapRing = n.location.index;
          singleLocationKey = n.location.toString();
        } else if (isOuter &&
            n.type != NoteType.forceInvalidate &&
            n.length == null &&
            n.slidePaths.isNotEmpty) {
          trailingSlideHeadRing = n.location.index;
        } else if (isOuter &&
            n.length != null &&
            n.slidePaths.isEmpty &&
            (n.type == NoteType.hold || n.type == NoteType.breakNote)) {
          isPureHold = true;
        } else if (!isOuter && isTouchType) {
          singleTouchLoc = n.location;
          singleTouchPos = NoteUtils.getTouchPosition(
            Offset.zero,
            1.0,
            n.location,
          );
          singleLocationKey = n.location.toString();
        }
      }

      int? doubleTapA;
      int? doubleTapB;
      int doubleTapMask = 0;
      int? holdAccompaniedTapRing;
      Location? doubleTouchLocA;
      Location? doubleTouchLocB;
      Offset? doubleTouchPosA;
      Offset? doubleTouchPosB;

      if (collection.length == 2 &&
          collection.eachStyle != EachStyle.forceBroken) {
        final n0 = collection[0];
        final n1 = collection[1];
        bool isPureOuterTap(dynamic n) =>
            n.location.group == NoteGroup.tap &&
            (n.type == NoteType.tap || n.type == NoteType.breakNote) &&
            n.length == null &&
            n.slidePaths.isEmpty;
        bool isPureOuterHold(dynamic n) =>
            n.location.group == NoteGroup.tap &&
            n.length != null &&
            n.slidePaths.isEmpty &&
            (n.type == NoteType.hold || n.type == NoteType.breakNote);
        bool isPureInnerTouch(dynamic n) =>
            n.location.group != NoteGroup.tap &&
            n.type == NoteType.touch &&
            !n.isTouchHold &&
            n.length == null &&
            n.slidePaths.isEmpty;

        if (isPureOuterTap(n0) &&
            isPureOuterTap(n1) &&
            n0.location.index != n1.location.index) {
          final a = math.min(n0.location.index, n1.location.index);
          final b = math.max(n0.location.index, n1.location.index);
          doubleTapA = a;
          doubleTapB = b;
          doubleTapMask = (1 << a) | (1 << b);
        } else if (isPureOuterHold(n0) && isPureOuterTap(n1)) {
          holdAccompaniedTapRing = n1.location.index;
        } else if (isPureOuterHold(n1) && isPureOuterTap(n0)) {
          holdAccompaniedTapRing = n0.location.index;
        } else if (isPureInnerTouch(n0) &&
            isPureInnerTouch(n1) &&
            n0.location != n1.location) {
          doubleTouchLocA = n0.location;
          doubleTouchLocB = n1.location;
          doubleTouchPosA = NoteUtils.getTouchPosition(
            Offset.zero,
            1.0,
            n0.location,
          );
          doubleTouchPosB = NoteUtils.getTouchPosition(
            Offset.zero,
            1.0,
            n1.location,
          );
        }
      }

      final slides = <_SlideSummary>[];
      var allHaveSlides = true;
      for (final note in collection) {
        if (note.slidePaths.isEmpty) {
          allHaveSlides = false;
          continue;
        }
        int maxSeg = 0;
        var hasFan = false;
        int? endRing;
        for (final path in note.slidePaths) {
          if (path.segments.length > maxSeg) maxSeg = path.segments.length;
          for (final seg in path.segments) {
            if (seg.slideType == SlideType.fan) hasFan = true;
          }
          if (path.segments.isNotEmpty &&
              path.segments.last.vertices.isNotEmpty) {
            final endLoc = path.segments.last.vertices.last;
            if (endLoc.group == NoteGroup.tap) {
              endRing = endLoc.index;
            }
          }
        }
        slides.add(
          _SlideSummary(
            startRing: note.location.index,
            endRing: endRing,
            maxSegments: maxSeg,
            hasFan: hasFan,
            hasHeadTap: note.type != NoteType.forceInvalidate,
          ),
        );
      }

      tokens.add(
        _AnalyzedToken(
          time: collection.time,
          text: text,
          measure: measure,
          beat: beat,
          singleTapRing: singleTapRing,
          singleLocationKey: singleLocationKey,
          trailingSlideHeadRing: trailingSlideHeadRing,
          doubleTapA: doubleTapA,
          doubleTapB: doubleTapB,
          doubleTapMask: doubleTapMask,
          holdAccompaniedTapRing: holdAccompaniedTapRing,
          isPureHold: isPureHold,
          singleTouchLoc: singleTouchLoc,
          singleTouchPos: singleTouchPos,
          doubleTouchLocA: doubleTouchLocA,
          doubleTouchLocB: doubleTouchLocB,
          doubleTouchPosA: doubleTouchPosA,
          doubleTouchPosB: doubleTouchPosB,
          slides: slides,
          isPureSlideCollection: allHaveSlides && slides.isNotEmpty,
        ),
      );
    }

    if (tokens.isEmpty) return const [];

    // 回填每个时刻活跃中的 Hold 键位掩码，用于识别单手 Hold 伴奏流。
    for (final hold in holdIntervals) {
      int lo = _lowerBoundTime(tokens, hold.startTime + 1e-4);
      while (lo < tokens.length && tokens[lo].time < hold.endTime - 1e-4) {
        tokens[lo].activeHoldMask |= (1 << hold.ringIndex);
        lo++;
      }
    }

    final globalPatterns = _detectGlobalPatterns(chart, tokens);

    // 按小节分桶，保留全局起始索引到局部索引的映射以完成跨小节切片。
    final groupedIndices = <int, List<int>>{};
    for (int i = 0; i < tokens.length; i++) {
      groupedIndices.putIfAbsent(tokens[i].measure, () => <int>[]).add(i);
    }

    final measureEntries = groupedIndices.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // 建立全局索引 -> (小节, 局部索引) 映射。
    final globalToMeasure = List<int>.filled(tokens.length, 0);
    final globalToLocal = List<int>.filled(tokens.length, 0);
    for (final entry in measureEntries) {
      final list = entry.value;
      for (int local = 0; local < list.length; local++) {
        final g = list[local];
        globalToMeasure[g] = entry.key;
        globalToLocal[g] = local;
      }
    }

    final measureSlices = <int, List<SimaiTokenPattern>>{};
    for (final gp in globalPatterns) {
      int cursor = gp.start;
      while (cursor < gp.end) {
        final m = globalToMeasure[cursor];
        final sliceGlobalStart = cursor;
        while (cursor < gp.end && globalToMeasure[cursor] == m) {
          cursor++;
        }
        final sliceGlobalEnd = cursor;
        final localStart = globalToLocal[sliceGlobalStart];
        final localEnd = globalToLocal[sliceGlobalEnd - 1] + 1;
        measureSlices
            .putIfAbsent(m, () => <SimaiTokenPattern>[])
            .add(
              SimaiTokenPattern(
                start: localStart,
                end: localEnd,
                subdivisionLabel: gp.subdivisionLabel,
                type: gp.type,
                continuesBefore: sliceGlobalStart > gp.start,
                continuesAfter: sliceGlobalEnd < gp.end,
              ),
            );
      }
    }

    return measureEntries.map((entry) {
      final measure = entry.key;
      final statementTokens = [
        for (final g in entry.value) tokens[g].toStatementToken(),
      ];
      return SimaiMeasureStatement(
        measure: measure,
        startTime: measureStarts[measure],
        tokens: List<SimaiStatementToken>.unmodifiable(statementTokens),
        patterns: List<SimaiTokenPattern>.unmodifiable(
          measureSlices[measure] ?? const <SimaiTokenPattern>[],
        ),
      );
    }).toList(growable: false);
  }

  static List<_GlobalPattern> _detectGlobalPatterns(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
  ) {
    final patterns = <_GlobalPattern>[];
    int i = 0;
    while (i < tokens.length) {
      // 1. 双押系（双押纵连 -> 双押交互 -> 对称双扫 -> 同向双扫 / 双轨转圈）
      final doublePattern = _tryDoubleTapPattern(chart, tokens, i);
      if (doublePattern != null) {
        patterns.add(doublePattern);
        i = doublePattern.end;
        continue;
      }

      // 2. 单键纵连（含 Tap 与同点 Touch）
      final firstKey = tokens[i].singleLocationKey;
      if (firstKey != null) {
        int end = i + 1;
        while (end < tokens.length && tokens[end].singleLocationKey == firstKey) {
          end++;
        }
        if (end - i >= 4 && _hasEvenBeatIntervals(tokens, i, end)) {
          patterns.add(
            _GlobalPattern(
              start: i,
              end: end,
              subdivisionLabel: _subdivisionLabelForRange(chart, tokens, i, end),
              type: SimaiPatternType.vertical,
            ),
          );
          i = end;
          continue;
        }
      }

      // 3. 对拍（成对相邻快拍）
      final pairedEnd = _pairedBeatEnd(tokens, i);
      if (pairedEnd >= i + 4) {
        final pairTimes = <double>[
          for (int pair = i; pair < pairedEnd; pair += 2) tokens[pair].time,
        ];
        final pairBeats = <double>[
          for (int pair = i; pair < pairedEnd; pair += 2) tokens[pair].beat,
        ];
        patterns.add(
          _GlobalPattern(
            start: i,
            end: pairedEnd,
            subdivisionLabel: _subdivisionLabelForSequences(
              chart,
              pairTimes,
              pairBeats,
            ),
            type: SimaiPatternType.pairedBeat,
          ),
        );
        i = pairedEnd;
        continue;
      }

      // 4. 严格双点交互（Tap 交互与 Touch 交互）
      if (firstKey != null && i + 1 < tokens.length) {
        final secondKey = tokens[i + 1].singleLocationKey;
        if (secondKey != null && secondKey != firstKey) {
          int end = i + 2;
          while (end < tokens.length &&
              tokens[end].singleLocationKey ==
                  ((end - i).isEven ? firstKey : secondKey)) {
            end++;
          }
          if (end - i >= 4 && _hasEvenBeatIntervals(tokens, i, end)) {
            final isTouchAlt = tokens[i].singleTouchLoc != null;
            patterns.add(
              _GlobalPattern(
                start: i,
                end: end,
                subdivisionLabel: _subdivisionLabelForRange(
                  chart,
                  tokens,
                  i,
                  end,
                ),
                type: isTouchAlt
                    ? SimaiPatternType.touchAlternating
                    : SimaiPatternType.alternating,
              ),
            );
            i = end;
            continue;
          }
        }
      }

      // 5. 定轴交互 / 单轴扫（奇数位或偶数位恒为同一外环锚点键）
      final anchoredPattern = _tryAnchoredPattern(chart, tokens, i);
      if (anchoredPattern != null) {
        patterns.add(anchoredPattern);
        i = anchoredPattern.end;
        continue;
      }

      // 6. 3~4 键阶梯 / 循环流
      final periodicPattern = _tryPeriodicPattern(chart, tokens, i);
      if (periodicPattern != null) {
        patterns.add(periodicPattern);
        i = periodicPattern.end;
        continue;
      }

      // 7. 外环连续旋转（转圈 / 双向转圈）与扫键（扫键 / 换向扫键 / 往复扫键）
      final sweepPattern = _tryRingSweepOrSpin(chart, tokens, i);
      if (sweepPattern != null) {
        patterns.add(sweepPattern);
        i = sweepPattern.end;
        continue;
      }

      // 8. 长按伴奏流与连续短长按
      final holdPattern = _tryHoldPattern(chart, tokens, i);
      if (holdPattern != null) {
        patterns.add(holdPattern);
        i = holdPattern.end;
        continue;
      }

      // 9. Touch 环扫 / 穿心弧扫 / 双 Touch 扫
      final touchPattern = _tryTouchSweepPattern(chart, tokens, i);
      if (touchPattern != null) {
        patterns.add(touchPattern);
        i = touchPattern.end;
        continue;
      }

      // 10. Slide 配置家族（接力连星、双星连滑、连续 WiFi、一笔画、分叉星）
      final slidePattern = _trySlidePattern(chart, tokens, i);
      if (slidePattern != null) {
        patterns.add(slidePattern);
        i = slidePattern.end;
        continue;
      }

      i++;
    }
    return patterns;
  }

  static _GlobalPattern? _tryDoubleTapPattern(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
  ) {
    final mask0 = tokens[start].doubleTapMask;
    if (mask0 == 0) return null;

    // 1a. 双押纵连（>= 3 组相同双押键位对）
    int end = start + 1;
    while (end < tokens.length && tokens[end].doubleTapMask == mask0) {
      end++;
    }
    if (end - start >= 3 && _hasEvenBeatIntervals(tokens, start, end)) {
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.doubleVertical,
      );
    }

    // 1b. 双押交互（>= 4 组 A-B-A-B）
    if (start + 1 < tokens.length &&
        tokens[start + 1].doubleTapMask != 0 &&
        tokens[start + 1].doubleTapMask != mask0) {
      final mask1 = tokens[start + 1].doubleTapMask;
      end = start + 2;
      while (end < tokens.length &&
          tokens[end].doubleTapMask == ((end - start).isEven ? mask0 : mask1)) {
        end++;
      }
      if (end - start >= 4 && _hasEvenBeatIntervals(tokens, start, end)) {
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: SimaiPatternType.doubleAlternating,
        );
      }
    }

    // 1c/1d. 对称蝴蝶双扫 (+1, -1) 与同向双轨扫 (+1, +1 / -1, -1)
    if (start + 2 >= tokens.length || tokens[start + 1].doubleTapMask == 0) {
      return null;
    }

    final a0 = tokens[start].doubleTapA!;
    final b0 = tokens[start].doubleTapB!;
    final a1 = tokens[start + 1].doubleTapA!;
    final b1 = tokens[start + 1].doubleTapB!;

    // 枚举所有满足两手步进 (+1/-1) 的双射初态：(dirA, dirB, curA, curB)
    for (final (curA, curB) in [(a1, b1), (b1, a1)]) {
      final dirA = _ringStepDir(a0, curA);
      final dirB = _ringStepDir(b0, curB);
      if (dirA == 0 || dirB == 0) continue;
      if (!_isSweepStep(tokens[start], tokens[start + 1])) continue;

      final isSymmetric = dirA == -dirB;
      var trackedA = curA;
      var trackedB = curB;
      end = start + 2;
      while (end < tokens.length) {
        final next = tokens[end];
        if (next.doubleTapMask == 0) break;
        if (!_isSweepStep(tokens[end - 1], next)) break;
        final expA = (trackedA + dirA + 8) % 8;
        final expB = (trackedB + dirB + 8) % 8;
        if (expA == expB) break;
        if (next.doubleTapMask == ((1 << expA) | (1 << expB))) {
          trackedA = expA;
          trackedB = expB;
          end++;
        } else {
          break;
        }
      }
      if (end - start >= 3 &&
          _hasEvenBeatIntervals(
            tokens,
            start,
            end,
            maxBeatGap: 0.55,
            maxTimeGap: 0.25,
          )) {
        final len = end - start;
        final SimaiPatternType type;
        if (isSymmetric) {
          type = SimaiPatternType.symmetricDoubleSweep;
        } else if (len >= 5) {
          type = SimaiPatternType.doubleSpin;
        } else {
          type = SimaiPatternType.parallelDoubleSweep;
        }
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: type,
        );
      }
    }
    return null;
  }

  static _GlobalPattern? _tryAnchoredPattern(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
  ) {
    if (start + 5 >= tokens.length) return null;
    if (tokens[start].singleTapRing == null ||
        tokens[start + 1].singleTapRing == null) {
      return null;
    }

    // 尝试两种相位：anchorAtEven=true 表示 start, start+2, ... 为锚点；false 表示 start+1, start+3, ... 为锚点。
    for (final anchorAtEven in const [true, false]) {
      final anchorRing = anchorAtEven
          ? tokens[start].singleTapRing!
          : tokens[start + 1].singleTapRing!;
      final movingRings = <int>[];
      int end = start;
      while (end < tokens.length) {
        final ring = tokens[end].singleTapRing;
        if (ring == null) break;
        final isAnchorSlot = ((end - start).isEven) == anchorAtEven;
        if (isAnchorSlot) {
          if (ring != anchorRing) break;
        } else {
          if (ring == anchorRing) break;
          movingRings.add(ring);
        }
        end++;
      }

      // 将尾部悬空的单锚点收掉，保证移动侧也有对应落点（或偶数配对更工整）。
      if (end - start >= 6 && movingRings.length >= 3) {
        // 如果移动侧恒定，则应该已在 alternating 被捕获；这里要求至少出现 2 个不同非锚点键位。
        final distinctMoving = movingRings.toSet();
        if (distinctMoving.length < 2) continue;
        if (!_hasEvenBeatIntervals(
          tokens,
          start,
          end,
          maxBeatGap: 0.55,
          maxTimeGap: 0.25,
        )) {
          continue;
        }

        // 检查移动侧是否单调步进 ±1 mod 8。
        int dir = 0;
        bool monotonicSweep = true;
        for (int k = 1; k < movingRings.length; k++) {
          final step = _ringStepDir(movingRings[k - 1], movingRings[k]);
          if (step == 0) {
            monotonicSweep = false;
            break;
          }
          if (dir == 0) {
            dir = step;
          } else if (step != dir) {
            monotonicSweep = false;
            break;
          }
        }

        if (monotonicSweep) {
          return _GlobalPattern(
            start: start,
            end: end,
            subdivisionLabel: _subdivisionLabelForRange(
              chart,
              tokens,
              start,
              end,
            ),
            type: SimaiPatternType.singleAxisSweep,
          );
        }
        if (end - start >= 8) {
          return _GlobalPattern(
            start: start,
            end: end,
            subdivisionLabel: _subdivisionLabelForRange(
              chart,
              tokens,
              start,
              end,
            ),
            type: SimaiPatternType.anchoredAlternating,
          );
        }
      }
    }
    return null;
  }

  static _GlobalPattern? _tryPeriodicPattern(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
  ) {
    if (start + 5 >= tokens.length) return null;
    for (final period in const [4, 3]) {
      final minLen = period == 3 ? 6 : 6;
      if (start + minLen > tokens.length) continue;

      bool periodValid = true;
      final cycle = <int>[];
      for (int k = 0; k < period; k++) {
        final r = tokens[start + k].singleTapRing;
        if (r == null) {
          periodValid = false;
          break;
        }
        cycle.add(r);
      }
      if (!periodValid || cycle.toSet().length != period) continue;

      int end = start + period;
      while (end < tokens.length &&
          tokens[end].singleTapRing == cycle[(end - start) % period]) {
        end++;
      }
      if (end - start < minLen) continue;
      if (!_hasEvenBeatIntervals(
        tokens,
        start,
        end,
        maxBeatGap: 0.55,
        maxTimeGap: 0.25,
      )) {
        continue;
      }

      // 判断周期内是否全向 ±1 邻接推进（例如 1-2-3 或 8-7-6-5），是则为楼梯，否则需至少 2 整周期才标循环。
      int stepDir = 0;
      bool isStaircase = true;
      for (int k = 1; k < period; k++) {
        final step = _ringStepDir(cycle[k - 1], cycle[k]);
        if (step == 0) {
          isStaircase = false;
          break;
        }
        if (stepDir == 0) {
          stepDir = step;
        } else if (step != stepDir) {
          isStaircase = false;
          break;
        }
      }

      if (isStaircase) {
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: period == 3
              ? SimaiPatternType.staircase3
              : SimaiPatternType.staircase4,
        );
      }

      if (end - start >= period * 2) {
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: period == 3 ? SimaiPatternType.cycle3 : SimaiPatternType.cycle4,
        );
      }
    }
    return null;
  }

  static _GlobalPattern? _tryRingSweepOrSpin(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
  ) {
    final firstRing = tokens[start].singleTapRing;
    if (firstRing == null || start + 1 >= tokens.length) return null;

    int prevDir = 0;
    int reversals = 0;
    final segmentStepCounts = <int>[];
    int currentSegSteps = 0;
    final visitedRings = <int>{firstRing};

    int end = start + 1;
    int prevRing = firstRing;
    while (end < tokens.length) {
      final token = tokens[end];
      // 允许最末一颗使用“带星头的 Slide”以便捕获经典“转圈尾接滑星”。
      final int? nextRing = token.singleTapRing ?? token.trailingSlideHeadRing;
      if (nextRing == null) break;
      final stepDir = _ringStepDir(prevRing, nextRing);
      if (stepDir == 0 || !_isSweepStep(tokens[end - 1], token)) break;

      if (prevDir == 0) {
        prevDir = stepDir;
        currentSegSteps = 1;
      } else if (stepDir != prevDir) {
        reversals++;
        segmentStepCounts.add(currentSegSteps);
        currentSegSteps = 1;
        prevDir = stepDir;
      } else {
        currentSegSteps++;
      }

      visitedRings.add(nextRing);
      prevRing = nextRing;
      end++;
      if (token.trailingSlideHeadRing != null) {
        // 尾接滑星只允许作为收尾边界，不继续向后拼单键。
        break;
      }
    }

    final noteCount = end - start;
    if (noteCount < 2) return null;
    if (currentSegSteps > 0) segmentStepCounts.add(currentSegSteps);

    final firstGapTime = tokens[start + 1].time - tokens[start].time;
    final firstGapBeat = tokens[start + 1].beat - tokens[start].beat;

    if (noteCount == 2) {
      if (!(firstGapBeat <= 0.14 || firstGapTime <= 0.080)) return null;
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.sweep,
      );
    }
    if (noteCount == 3 && reversals == 0) {
      if (!(firstGapBeat <= 0.20 || firstGapTime <= 0.115)) return null;
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.sweep,
      );
    }

    final SimaiPatternType type;
    if (reversals == 0) {
      type = noteCount >= 6 ? SimaiPatternType.spin : SimaiPatternType.sweep;
    } else if (reversals == 1) {
      final minSegNotes =
          math.min(segmentStepCounts[0], segmentStepCounts[1]) + 1;
      type = minSegNotes >= 5
          ? SimaiPatternType.bidirectionalSpin
          : SimaiPatternType.reversingSweep;
    } else {
      // 多次往复须至少涉及 3 个键位且总长 >= 5，避免纯 2 键抖动混入。
      if (noteCount < 5 || visitedRings.length < 3) return null;
      type = SimaiPatternType.oscillatingSweep;
    }

    return _GlobalPattern(
      start: start,
      end: end,
      subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
      type: type,
    );
  }

  static _GlobalPattern? _tryHoldPattern(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
  ) {
    final first = tokens[start];

    // 8a. 连续短 Hold 流（>= 4 颗等拍距纯 Hold）
    if (first.isPureHold) {
      int end = start + 1;
      while (end < tokens.length && tokens[end].isPureHold) {
        end++;
      }
      if (end - start >= 4 && _hasEvenBeatIntervals(tokens, start, end)) {
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: SimaiPatternType.holdStream,
        );
      }
    }

    // 8b. 单手 Hold 伴奏流（起手为 Hold+Tap 双押，后续为处于活跃 Hold 区间内的单键 Tap）
    final firstRing = first.holdAccompaniedTapRing;
    if (firstRing == null) return null;

    final rings = <int>[firstRing];
    int end = start + 1;
    while (end < tokens.length) {
      final r = tokens[end].holdStreamTapRing;
      if (r == null) break;
      rings.add(r);
      end++;
    }
    if (rings.length < 4) return null;
    if (!_hasEvenBeatIntervals(
      tokens,
      start,
      end,
      maxBeatGap: 0.55,
      maxTimeGap: 0.25,
    )) {
      return null;
    }

    bool allSweepSteps = true;
    int prevDir = 0;
    int rev = 0;
    for (int k = 1; k < rings.length; k++) {
      final d = _ringStepDir(rings[k - 1], rings[k]);
      if (d == 0 || !_isSweepStep(tokens[start + k - 1], tokens[start + k])) {
        allSweepSteps = false;
        break;
      }
      if (prevDir == 0) {
        prevDir = d;
      } else if (d != prevDir) {
        rev++;
        prevDir = d;
      }
    }
    if (allSweepSteps && rev <= 2) {
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.holdAccompaniedSweep,
      );
    }

    return _GlobalPattern(
      start: start,
      end: end,
      subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
      type: SimaiPatternType.holdAccompaniedStream,
    );
  }

  static _GlobalPattern? _tryTouchSweepPattern(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
  ) {
    final first = tokens[start];

    // 9a. 双 Touch 同步滑动（如 B1/B8 -> B2/B7 -> B3/B6）
    if (first.doubleTouchPosA != null &&
        first.doubleTouchLocA!.group == first.doubleTouchLocB!.group &&
        first.doubleTouchLocA!.group != NoteGroup.cSensor) {
      int end = start + 1;
      while (end < tokens.length) {
        final cur = tokens[end];
        if (cur.doubleTouchLocA == null || cur.doubleTouchLocB == null) break;
        if (cur.doubleTouchLocA!.group != first.doubleTouchLocA!.group ||
            cur.doubleTouchLocB!.group != first.doubleTouchLocB!.group) {
          break;
        }
        final prev = tokens[end - 1];
        if (!_isTouchSweepGap(prev, cur)) break;
        final da = (cur.doubleTouchLocA!.index - prev.doubleTouchLocA!.index) % 8;
        final db = (cur.doubleTouchLocB!.index - prev.doubleTouchLocB!.index) % 8;
        final daValid = da == 1 || da == 7;
        final dbValid = db == 1 || db == 7;
        final reverseMatch =
            ((cur.doubleTouchLocA!.index - prev.doubleTouchLocB!.index) % 8 == 1 ||
                (cur.doubleTouchLocA!.index - prev.doubleTouchLocB!.index) % 8 ==
                    7) &&
            ((cur.doubleTouchLocB!.index - prev.doubleTouchLocA!.index) % 8 == 1 ||
                (cur.doubleTouchLocB!.index - prev.doubleTouchLocA!.index) % 8 ==
                    7);
        if (!(daValid && dbValid) && !reverseMatch) break;
        end++;
      }
      if (end - start >= 3) {
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: SimaiPatternType.doubleTouchSweep,
        );
      }
    }

    final firstPos = first.singleTouchPos;
    final firstLoc = first.singleTouchLoc;
    if (firstPos == null || firstLoc == null) return null;

    // 9b. 同圈内 Touch 环扫（全 A/B/D/E 同圈相邻索引连续推进）
    if (firstLoc.group != NoteGroup.cSensor) {
      int ringDir = 0;
      int end = start + 1;
      while (end < tokens.length) {
        final loc = tokens[end].singleTouchLoc;
        if (loc == null || loc.group != firstLoc.group) break;
        if (!_isTouchSweepGap(tokens[end - 1], tokens[end])) break;
        final prevLoc = tokens[end - 1].singleTouchLoc!;
        final diff = (loc.index - prevLoc.index) % 8;
        final step = diff == 1 ? 1 : (diff == 7 ? -1 : 0);
        if (step == 0) break;
        if (ringDir == 0) {
          ringDir = step;
        } else if (step != ringDir) {
          break;
        }
        end++;
      }
      if (end - start >= 3) {
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: SimaiPatternType.touchRingSweep,
        );
      }
    }

    // 9c. 基于 33 传感器单位圆坐标的穿心 / 跨区连续 Touch 扫
    int end = start + 1;
    Offset? prevVec;
    while (end < tokens.length) {
      final pos = tokens[end].singleTouchPos;
      if (pos == null) break;
      if (!_isTouchSweepGap(tokens[end - 1], tokens[end])) break;
      final stepVec = pos - tokens[end - 1].singleTouchPos!;
      final dist = stepVec.distance;
      if (dist < 0.16 || dist > 0.72) break;
      if (prevVec != null) {
        final dot =
            (prevVec.dx * stepVec.dx + prevVec.dy * stepVec.dy) /
            (prevVec.distance * dist);
        // 余弦 >= 0.55（约 56° 以内），覆盖直线穿心与平缓内屏弧扫，屏蔽随机折线。
        if (dot < 0.55) break;
      }
      prevVec = stepVec;
      end++;
    }
    if (end - start >= 3) {
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.touchSweep,
      );
    }
    return null;
  }

  static _GlobalPattern? _trySlidePattern(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
  ) {
    if (!tokens[start].isPureSlideCollection) return null;

    int end = start + 1;
    while (end < tokens.length && tokens[end].isPureSlideCollection) {
      final beatGap = tokens[end].beat - tokens[end - 1].beat;
      if (beatGap <= 1e-4 || beatGap > 2.05) break;
      end++;
    }
    final count = end - start;

    // 统计连续段内的形态分布
    int maxSeg = 0;
    int maxBranches = 0;
    int wifiCount = 0;
    int doubleSlideFrames = 0;
    int forkFrames = 0;
    for (int k = start; k < end; k++) {
      final slides = tokens[k].slides;
      if (slides.length >= 2) {
        doubleSlideFrames++;
        forkFrames++;
      }
      if (slides.length > maxBranches) maxBranches = slides.length;
      if (slides.any((s) => s.hasFan)) wifiCount++;
      for (final s in slides) {
        if (s.maxSegments > maxSeg) maxSeg = s.maxSegments;
      }
    }

    if (count >= 2 && doubleSlideFrames == count) {
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.doubleSlideChain,
      );
    }

    if (count >= 3 && wifiCount == count) {
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.wifiSlideChain,
      );
    }

    // 检查是否构成了首尾相接或相邻（距离 <= 1）的接力滑星链
    if (count >= 3) {
      int chainLen = 1;
      for (int k = start + 1; k < end; k++) {
        final prevSlides = tokens[k - 1].slides;
        final curSlides = tokens[k].slides;
        bool linked = false;
        for (final ps in prevSlides) {
          final pe = ps.endRing;
          if (pe == null) continue;
          for (final cs in curSlides) {
            if (_ringDistance(pe, cs.startRing) <= 1) {
              linked = true;
              break;
            }
          }
          if (linked) break;
        }
        if (linked) chainLen++;
      }
      if (chainLen >= 3) {
        return _GlobalPattern(
          start: start,
          end: end,
          subdivisionLabel: _subdivisionLabelForRange(
            chart,
            tokens,
            start,
            end,
          ),
          type: SimaiPatternType.relaySlideChain,
        );
      }
    }

    if (count >= 3 &&
        _hasEvenBeatIntervals(
          tokens,
          start,
          end,
          maxBeatGap: 2.05,
          maxTimeGap: 1.5,
        )) {
      return _GlobalPattern(
        start: start,
        end: end,
        subdivisionLabel: _subdivisionLabelForRange(chart, tokens, start, end),
        type: SimaiPatternType.slideChain,
      );
    }

    // 单颗或两颗的高难度多段折线滑星（>= 3 段）或三分叉及以上同头滑星
    if (maxSeg >= 3) {
      return _GlobalPattern(
        start: start,
        end: count >= 2 ? end : start + 1,
        subdivisionLabel: '',
        type: SimaiPatternType.oneStrokeSlide,
      );
    }
    if ((count >= 2 && forkFrames == count) || maxBranches >= 3) {
      return _GlobalPattern(
        start: start,
        end: count >= 2 ? end : start + 1,
        subdivisionLabel: '',
        type: SimaiPatternType.forkSlide,
      );
    }
    return null;
  }

  static int _pairedBeatEnd(List<_AnalyzedToken> tokens, int start) {
    if (start + 3 >= tokens.length) return start;
    int end = start;
    while (end + 1 < tokens.length) {
      final first = tokens[end];
      final second = tokens[end + 1];
      final r1 = first.singleTapRing;
      final r2 = second.singleTapRing;
      if (r1 == null || r2 == null || _ringStepDir(r1, r2) == 0) break;
      if (!_isClosePairGap(first, second)) break;
      if (end > start) {
        final prevEnd = tokens[end - 1];
        final interGap = first.time - prevEnd.time;
        final intraGap = second.time - first.time;
        final hasTemporalBoundary =
            interGap > intraGap * 1.5 + 1e-4 && interGap > 0.01;
        final hasSpatialBoundary =
            prevEnd.singleTapRing == null ||
            _ringStepDir(prevEnd.singleTapRing!, r1) == 0;
        if (!hasTemporalBoundary && !hasSpatialBoundary) break;
      }
      end += 2;
    }
    return end >= start + 4 ? end : start;
  }

  static bool _isClosePairGap(_AnalyzedToken first, _AnalyzedToken second) {
    final beatGap = second.beat - first.beat;
    final timeGap = second.time - first.time;
    return timeGap > 1e-6 && (beatGap <= 0.14 || timeGap <= 0.055);
  }

  static bool _hasEvenBeatIntervals(
    List<_AnalyzedToken> tokens,
    int start,
    int end, {
    double maxBeatGap = 1.05,
    double maxTimeGap = 0.65,
  }) {
    if (end - start < 2) return false;
    final b0 = tokens[start + 1].beat - tokens[start].beat;
    final t0 = tokens[start + 1].time - tokens[start].time;
    if (b0 <= 1e-4 || b0 > maxBeatGap || t0 <= 1e-6 || t0 > maxTimeGap) {
      return false;
    }
    final tolerance = math.max(0.015, b0 * 0.08);
    for (int i = start + 2; i < end; i++) {
      final bi = tokens[i].beat - tokens[i - 1].beat;
      final ti = tokens[i].time - tokens[i - 1].time;
      if (ti <= 1e-6 || ti > maxTimeGap) return false;
      if ((bi - b0).abs() > tolerance) return false;
    }
    return true;
  }

  static bool _isSweepStep(_AnalyzedToken from, _AnalyzedToken to) {
    final beatGap = to.beat - from.beat;
    final timeGap = to.time - from.time;
    if (beatGap <= 1e-4 || timeGap <= 1e-6 || timeGap > _sweepHardMaxTimeSec) {
      return false;
    }
    return beatGap <= _sweepMaxBeatGap || timeGap <= _sweepFallbackMaxTimeSec;
  }

  static bool _isTouchSweepGap(_AnalyzedToken from, _AnalyzedToken to) {
    final beatGap = to.beat - from.beat;
    final timeGap = to.time - from.time;
    if (beatGap <= 1e-4 || timeGap <= 1e-6 || timeGap > 0.35) {
      return false;
    }
    return beatGap <= 0.52 || timeGap <= 0.18;
  }

  static int _ringStepDir(int from, int to) {
    final diff = (to - from) % 8;
    if (diff == 1) return 1;
    if (diff == 7) return -1;
    return 0;
  }

  static int _ringDistance(int a, int b) {
    final d = (a - b).abs() % 8;
    return math.min(d, 8 - d);
  }

  static String _subdivisionLabelForRange(
    MaiChart chart,
    List<_AnalyzedToken> tokens,
    int start,
    int end,
  ) {
    if (end - start < 2) return '';
    final subdivisions = <int>[];
    for (int i = start + 1; i < end; i++) {
      final beatDelta = tokens[i].beat - tokens[i - 1].beat;
      if (beatDelta > 1e-4) {
        subdivisions.add((4.0 / beatDelta).round().clamp(1, 1024));
      } else {
        final interval = tokens[i].time - tokens[i - 1].time;
        final bpm = ChartTimingMapper.timingAtTime(
          chart,
          tokens[i - 1].time,
        ).tempo;
        if (interval > 0 && bpm > 0) {
          subdivisions.add((240.0 / (bpm * interval)).round().clamp(1, 1024));
        }
      }
    }
    return _formatSubdivisions(subdivisions);
  }

  static String _subdivisionLabelForSequences(
    MaiChart chart,
    List<double> times,
    List<double> beats,
  ) {
    if (times.length < 2) return '4分';
    final subdivisions = <int>[];
    for (int i = 1; i < times.length; i++) {
      final beatDelta = beats[i] - beats[i - 1];
      if (beatDelta > 1e-4) {
        subdivisions.add((4.0 / beatDelta).round().clamp(1, 1024));
      } else {
        final interval = times[i] - times[i - 1];
        final bpm = ChartTimingMapper.timingAtTime(chart, times[i - 1]).tempo;
        if (interval > 0 && bpm > 0) {
          subdivisions.add((240.0 / (bpm * interval)).round().clamp(1, 1024));
        }
      }
    }
    return _formatSubdivisions(subdivisions);
  }

  static String _formatSubdivisions(List<int> subdivisions) {
    if (subdivisions.isEmpty) return '4分';
    final unique = <int>[];
    for (final value in subdivisions) {
      if (unique.isEmpty || unique.last != value) unique.add(value);
    }
    if (unique.length == 1) return '${unique.single}分';
    if (unique.length <= 3) return '${unique.join('→')}分变速';
    return '${unique.first}→${unique.last}分变速';
  }

  static int _indexAtOrBefore(List<double> values, double time) {
    int lo = 0;
    int hi = values.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (values[mid] <= time + 1e-7) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return hi.clamp(0, values.length - 1);
  }

  static int _lowerBoundTime(List<_AnalyzedToken> tokens, double target) {
    int lo = 0;
    int hi = tokens.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (tokens[mid].time < target) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
