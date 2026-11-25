import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simai_flutter/simai_flutter.dart';

import '../l10n/LocalizationsExtension.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import '../utils/ChartBpmInfo.dart';

enum _NoteAccent { tap, touch, sustain, breakNote }

typedef _RhythmMark = ({double time, _NoteAccent accent, bool simultaneous});

/// 同一时刻的音符共用一个标记。时间轴与谱面播放、BPM 区间使用同一份解析结果。
class _RhythmTimeline {
  _RhythmTimeline(MaiChart chart)
      : segments = ChartBpmInfo.timelineForChart(chart) {
    var beats = 0.0;
    for (final segment in segments) {
      _beatsAtStart.add(beats);
      beats += (segment.endSeconds - segment.startSeconds) * segment.bpm / 60;
    }
    final notesAtTime = <double, _RhythmMark>{};
    for (final collection in chart.noteCollections) {
      if (collection.isEmpty || !collection.time.isFinite) continue;
      final time = collection.time;
      final existing = notesAtTime[time];
      var accent = existing?.accent ?? _NoteAccent.tap;
      for (final note in collection) {
        final kind = _accentFor(note);
        if (kind.index > accent.index) accent = kind;
      }
      notesAtTime[time] = (
        time: time,
        accent: accent,
        simultaneous: existing != null || collection.length > 1,
      );
    }
    marks = notesAtTime.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final noteBeats = marks.map((mark) => _beatsAt(mark.time)).toList();
    labels = [
      for (var i = 0; i < noteBeats.length; i++)
        if (i + 1 < noteBeats.length)
          _subdivision(
            (noteBeats[i + 1] - noteBeats[i]) / 4,
            marks[i + 1].time - marks[i].time,
          )
        else
          null,
    ];
  }

  final List<ChartBpmSegment> segments;
  final List<double> _beatsAtStart = [];
  late final List<_RhythmMark> marks;
  late final List<String?> labels;

  static _NoteAccent _accentFor(Note note) {
    if (note.type == NoteType.breakNote ||
        (note.styles & NoteStyles.breakHead) != 0) {
      return _NoteAccent.breakNote;
    }
    if (note.length != null || note.slidePaths.isNotEmpty) {
      return _NoteAccent.sustain;
    }
    return note.location.group == NoteGroup.tap
        ? _NoteAccent.tap
        : _NoteAccent.touch;
  }

  static String _subdivision(double wholeNotes, double seconds) {
    if (wholeNotes.isFinite && wholeNotes > 0) {
      // 用连分数还原时值，保留跨多格的节奏（例如 5/192）和高分度切分。
      var remainder = wholeNotes;
      var previousNumerator = 0;
      var numerator = 1;
      var previousDenominator = 1;
      var denominator = 0;
      while (remainder.isFinite) {
        final integer = remainder.floor();
        if (denominator > 0 &&
            integer > (4096 - previousDenominator) ~/ denominator) {
          break;
        }
        final nextDenominator = integer * denominator + previousDenominator;
        final nextNumerator = integer * numerator + previousNumerator;
        if (nextNumerator > 0 &&
            (wholeNotes - nextNumerator / nextDenominator).abs() < 1e-9) {
          if (nextNumerator == 1) return '$nextDenominator';
          final powerOfTwo = (nextDenominator & (nextDenominator - 1)) == 0;
          if (powerOfTwo && nextNumerator == 3 && nextDenominator >= 2) {
            return '${nextDenominator ~/ 2}.';
          }
          if (powerOfTwo && nextNumerator == 7 && nextDenominator >= 4) {
            return '${nextDenominator ~/ 4}..';
          }
          return '$nextNumerator/$nextDenominator';
        }
        previousNumerator = numerator;
        numerator = nextNumerator;
        previousDenominator = denominator;
        denominator = nextDenominator;
        remainder = 1 / (remainder - integer);
      }
    }
    return '${(seconds * 1000).toStringAsFixed(1)} ms';
  }

  int _segmentIndex(double time) {
    var low = 0;
    var high = segments.length;
    while (high - low > 1) {
      final mid = (low + high) ~/ 2;
      if (segments[mid].startSeconds <= time) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return low;
  }

  double? bpmAt(double time) =>
      segments.isEmpty ? null : segments[_segmentIndex(time)].bpm;

  double _beatsAt(double time) {
    if (segments.isEmpty) return 0;
    final index = _segmentIndex(time);
    final segment = segments[index];
    return _beatsAtStart[index] +
        (time - segment.startSeconds) * segment.bpm / 60;
  }

  int firstAtOrAfter(double time) {
    var low = 0;
    var high = marks.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (marks[mid].time < time) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }
}

typedef _RhythmLabelLayout = ({List<TextPainter?> labels, double edgePadding});

class ChartPlayMetronome extends StatefulWidget {
  const ChartPlayMetronome({
    super.key,
    required this.controller,
    required this.enabled,
    required this.soundEnabled,
    required this.onEnabledChanged,
    required this.onSoundChanged,
  });

  final SimaiPlayerController controller;
  final bool enabled;
  final bool soundEnabled;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onSoundChanged;

  @override
  State<ChartPlayMetronome> createState() => _ChartPlayMetronomeState();
}

class _ChartPlayMetronomeState extends State<ChartPlayMetronome>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late _RhythmTimeline _timeline;
  late final _frames = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  final _clock = Stopwatch()..start();
  ModalRoute<dynamic>? _route;
  late ColorScheme _scheme;
  bool _foreground = true;
  bool _wasPlaying = false;
  double? _lastChartTime;
  int _lastSampleMicros = 0;
  double? _bpm;
  final _labels = <String, TextPainter>{};
  _RhythmLabelLayout? _labelLayout;
  double? _labelScale;
  TextStyle? _labelStyle;
  TextScaler? _labelScaler;

  Future<void>? _soundLoad;
  AudioPlayer? _audio;
  bool _soundUnavailable = false;
  bool _clickPending = false;

  bool get _canPlay =>
      mounted &&
      _foreground &&
      (_route?.isCurrent ?? true) &&
      widget.enabled &&
      widget.controller.isPlaying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _timeline = _RhythmTimeline(widget.controller.chart);
    if (widget.enabled) _listen(widget.controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final theme = Theme.of(context);
    _scheme = theme.brightness == Brightness.dark
        ? theme.colorScheme
        : AppTheme.buildDarkColorScheme(seedColor: theme.colorScheme.primary);
    _syncFrames();
  }

  @override
  void didUpdateWidget(ChartPlayMetronome oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;
    if (controllerChanged || oldWidget.enabled != widget.enabled) {
      if (oldWidget.enabled) _unlisten(oldWidget.controller);
      if (controllerChanged) {
        _timeline = _RhythmTimeline(widget.controller.chart);
        _clearLabels();
      }
      if (widget.enabled) _listen(widget.controller);
      _syncFrames();
    }
    if (widget.enabled &&
        widget.soundEnabled &&
        (!oldWidget.enabled || !oldWidget.soundEnabled)) {
      _prepareClick();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _wasPlaying = false;
    _lastChartTime = null;
    _syncFrames();
  }

  void _syncFrames() {
    if (_canPlay && _timeline.marks.isNotEmpty) {
      if (!_frames.isAnimating) _frames.repeat();
    } else if (_frames.isAnimating) {
      _frames.stop();
    }
  }

  void _listen(SimaiPlayerController controller) {
    _wasPlaying = false;
    _lastChartTime = null;
    _bpm = _timeline.bpmAt(controller.timeNotifier.value);
    controller.timeNotifier.addListener(_updatePlayback);
    controller.addListener(_updatePlayback);
  }

  void _unlisten(SimaiPlayerController controller) {
    controller.timeNotifier.removeListener(_updatePlayback);
    controller.removeListener(_updatePlayback);
  }

  void _updatePlayback() {
    final controller = widget.controller;
    final time = controller.timeNotifier.value;
    if (!time.isFinite) return;
    final bpm = _timeline.bpmAt(time);
    final now = _clock.elapsedMicroseconds;
    final previousTime = _lastChartTime;
    final playing = _canPlay;
    final elapsed = (now - _lastSampleMicros) / Duration.microsecondsPerSecond;
    // 定位时更新节奏轨，但不补播跳过的音符。允许播放器轮询有少量抖动。
    final continuous = previousTime != null &&
        time >= previousTime &&
        time - previousTime <= elapsed * controller.playbackRate + 0.065;
    if (playing &&
        widget.soundEnabled &&
        !_soundUnavailable &&
        _timeline.marks.isNotEmpty) {
      _prepareClick();
      if (!_wasPlaying || continuous) {
        // 高频音符在同一轮询内到达时，只播放最近的一声，避免拖动或卡顿后补响。
        final index = _timeline.firstAtOrAfter(time + 1e-7) - 1;
        if (index >= 0) {
          final mark = _timeline.marks[index];
          final crossed = _wasPlaying
              ? mark.time > previousTime! + 1e-7
              : time - mark.time <= 0.035;
          if (crossed) {
            unawaited(_playClick(
                mark.accent == _NoteAccent.breakNote || mark.simultaneous));
          }
        }
      }
    }
    _wasPlaying = playing;
    _lastChartTime = time;
    _lastSampleMicros = now;
    _syncFrames();
    if (bpm != _bpm) setState(() => _bpm = bpm);
  }

  void _prepareClick() {
    _soundLoad ??= _loadClick();
  }

  Future<void> _loadClick() async {
    final player = AudioPlayer()..positionUpdater = null;
    try {
      await player.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await player.setPlayerMode(PlayerMode.lowLatency);
      }
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource('chart_metronome.wav'));
      _audio = player;
    } catch (error) {
      debugPrint('[ChartPlay] 节拍音准备失败: $error');
      if (mounted) setState(() => _soundUnavailable = true);
      await _disposeAudio(player);
    }
  }

  Future<void> _playClick(bool accent) async {
    final audio = _audio;
    if (audio == null || _clickPending) return;
    _clickPending = true;
    try {
      await audio.stop();
      if (!_canPlay || !widget.soundEnabled) return;
      await audio.setVolume(accent ? 0.68 : 0.40);
      if (_canPlay && widget.soundEnabled) await audio.resume();
    } catch (error) {
      if (mounted) {
        debugPrint('[ChartPlay] 节拍音播放失败: $error');
        setState(() => _soundUnavailable = true);
      }
    } finally {
      _clickPending = false;
    }
  }

  Future<void> _disposeAudio(AudioPlayer player) async {
    try {
      await player.dispose();
    } catch (error) {
      debugPrint('[ChartPlay] 释放节拍音失败: $error');
    }
  }

  @override
  void dispose() {
    if (widget.enabled) _unlisten(widget.controller);
    WidgetsBinding.instance.removeObserver(this);
    _clock.stop();
    _frames.dispose();
    _clearLabels();
    unawaited(_soundLoad?.then<void>((_) async {
      final player = _audio;
      if (player != null) await _disposeAudio(player);
    }));
    super.dispose();
  }

  void _clearLabels() {
    for (final label in _labels.values) {
      label.dispose();
    }
    _labels.clear();
    _labelLayout = null;
    _labelScale = null;
  }

  TextPainter _rhythmLabel(String text) => _labels.putIfAbsent(
        text,
        () => TextPainter(
          text: TextSpan(text: text, style: _labelStyle),
          textDirection: TextDirection.ltr,
          textScaler: _labelScaler!,
        )..layout(),
      );

  _RhythmLabelLayout _layoutLabels(double scale) {
    if (_labelScale == scale && _labelLayout != null) return _labelLayout!;
    final marks = _timeline.marks;
    final labels = List<TextPainter?>.filled(marks.length, null);
    var right = double.negativeInfinity;
    var edgePadding = 9.0;
    // 在整张谱面上只排一次。数字跟随音符滚动，移出视口时自然裁切。
    for (var i = 0; i < marks.length; i++) {
      final subdivision = _timeline.labels[i];
      if (subdivision == null) continue;
      final text = _rhythmLabel(subdivision);
      final center = marks[i].time * scale;
      final halfWidth = text.width / 2;
      if (center - halfWidth < right + 5) continue;
      labels[i] = text;
      right = center + halfWidth;
      edgePadding = math.max(edgePadding, halfWidth);
    }
    _labelScale = scale;
    return _labelLayout = (labels: labels, edgePadding: edgePadding);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = _scheme;
    final available = _timeline.marks.isNotEmpty;
    final enabled = widget.enabled && available;
    final sound = widget.soundEnabled && !_soundUnavailable;
    final bpm = _bpm;
    final labelStyle = AppTheme.number(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    final labelScaler = MediaQuery.textScalerOf(context);
    if (labelStyle != _labelStyle || labelScaler != _labelScaler) {
      _clearLabels();
      _labelStyle = labelStyle;
      _labelScaler = labelScaler;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: AppDesignTokens.minTouchTarget,
          child: Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Semantics(
                  selected: enabled,
                  child: TextButton.icon(
                    onPressed: available
                        ? () => widget.onEnabledChanged(!enabled)
                        : null,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor:
                          enabled ? scheme.primary : scheme.onSurfaceVariant,
                      splashFactory: NoSplash.splashFactory,
                      overlayColor: Colors.transparent,
                    ),
                    icon: const Icon(Icons.timer_outlined, size: 18),
                    label: Text(l10n.chartMetronome),
                  ),
                ),
              ),
            ),
            if (enabled) ...[
              if (bpm != null)
                Flexible(
                  fit: FlexFit.tight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      'BPM ${bpm.toStringAsFixed(bpm == bpm.roundToDouble() ? 0 : 1)}',
                      style: AppTheme.number(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              IconButton(
                tooltip: _soundUnavailable
                    ? l10n.chartMetronomeSoundUnavailable
                    : l10n.chartMetronomeSound,
                isSelected: sound,
                onPressed: _soundUnavailable
                    ? null
                    : () => widget.onSoundChanged(!widget.soundEnabled),
                icon: Icon(Icons.volume_off_outlined,
                    size: 19, color: scheme.onSurfaceVariant),
                selectedIcon: Icon(Icons.volume_up_outlined,
                    size: 19, color: scheme.primary),
              ),
            ],
          ]),
        ),
        if (enabled)
          SizedBox(
            width: double.infinity,
            height: 58 + labelScaler.scale(10) - 10,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _RhythmTrackPainter(
                  timeline: _timeline,
                  controller: widget.controller,
                  frames: _frames,
                  scheme: scheme,
                  layoutLabels: _layoutLabels,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RhythmTrackPainter extends CustomPainter {
  _RhythmTrackPainter({
    required this.timeline,
    required this.controller,
    required this.frames,
    required this.scheme,
    required this.layoutLabels,
  }) : super(repaint: Listenable.merge([frames, controller.timeNotifier]));

  final _RhythmTimeline timeline;
  final SimaiPlayerController controller;
  final AnimationController frames;
  final ColorScheme scheme;
  final _RhythmLabelLayout Function(double) layoutLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final time = frames.isAnimating
        ? controller.chartTime
        : controller.timeNotifier.value;
    if (!time.isFinite || size.width < 32) return;
    const noteY = 23.0;
    final headX = math.min(36.0, size.width * 0.14);
    final scale = (size.width - headX) / 2.1;
    final paint = Paint();
    final guide = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawLine(const Offset(0, noteY), Offset(size.width, noteY), guide);
    final marks = timeline.marks;
    final layout = layoutLabels(scale);
    final start = timeline.firstAtOrAfter(
      time - (headX + layout.edgePadding) / scale,
    );
    var hit = false;
    for (var i = start; i < marks.length; i++) {
      final mark = marks[i];
      final x = headX + (mark.time - time) * scale;
      if (x > size.width + layout.edgePadding) break;
      final nextGap = i + 1 < marks.length
          ? (marks[i + 1].time - mark.time) * scale
          : double.infinity;
      final previousGap =
          i > 0 ? (mark.time - marks[i - 1].time) * scale : double.infinity;
      final past = mark.time < time;
      final nearHead = (x - headX).abs() < 5;
      hit |= nearHead;
      final accent = switch (mark.accent) {
        _NoteAccent.tap => scheme.primary,
        _NoteAccent.touch => scheme.secondary,
        _NoteAccent.sustain => scheme.tertiary,
        _NoteAccent.breakNote => scheme.error,
      };
      final radius = (math.min(nextGap, previousGap) * .35).clamp(1.5, 6.0);
      final center = Offset(x, noteY);
      paint.color = accent.withValues(alpha: past && !nearHead ? .35 : 1);
      if (mark.simultaneous && radius > 3) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(center, radius + 2, paint);
        paint.style = PaintingStyle.fill;
      }
      canvas.drawCircle(center, radius, paint);

      final text = layout.labels[i];
      if (text != null) {
        text.paint(
          canvas,
          Offset(x - text.width / 2, size.height - text.height - 7),
        );
      }
    }
    final headPaint = Paint()
      ..color = hit ? scheme.primary : scheme.onSurfaceVariant
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(headX, 8), Offset(headX, 38), headPaint);
    canvas.drawCircle(Offset(headX, noteY), 9, headPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RhythmTrackPainter oldDelegate) =>
      timeline != oldDelegate.timeline ||
      controller != oldDelegate.controller ||
      scheme != oldDelegate.scheme ||
      layoutLabels != oldDelegate.layoutLabels;
}
