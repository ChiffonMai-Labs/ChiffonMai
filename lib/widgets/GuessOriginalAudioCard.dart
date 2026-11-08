import 'package:my_first_flutter_app/l10n/LocalizationsExtension.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../service/GuessChartGame/GuessAudioService.dart';
import '../utils/AppDesignTokens.dart';
import '../utils/AppTheme.dart';
import 'AppUi.dart';

/// 结算后对照本轮题面试听原声；新回合或离页时释放播放器。
class GuessOriginalAudioCard extends StatefulWidget {
  const GuessOriginalAudioCard({
    super.key,
    required this.musicId,
    required this.mode,
    required this.duration,
    required this.rate,
    required this.seed,
    this.singlePlayer = false,
  });

  final String musicId;
  final GuessAudioMode mode;
  final int duration;
  final double rate;
  final String seed;
  final bool singlePlayer;

  @override
  State<GuessOriginalAudioCard> createState() => _GuessOriginalAudioCardState();
}

class _GuessOriginalAudioCardState extends State<GuessOriginalAudioCard> {
  AudioPlayer? _player;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completionSubscription;
  int _generation = 0;
  bool _busy = false;
  bool _playing = false;
  bool _finished = false;
  double _duration = 0;
  double _position = 0;
  String? _error;

  void _release() {
    _generation++;
    _positionSubscription?.cancel();
    _completionSubscription?.cancel();
    final player = _player;
    _player = null;
    unawaited(player?.dispose());
  }

  @override
  void didUpdateWidget(covariant GuessOriginalAudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.musicId != widget.musicId ||
        oldWidget.mode != widget.mode ||
        oldWidget.duration != widget.duration ||
        oldWidget.rate != widget.rate ||
        oldWidget.seed != widget.seed ||
        oldWidget.singlePlayer != widget.singlePlayer) {
      _release();
      _busy = _playing = _finished = false;
      _duration = _position = 0;
      _error = null;
    }
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_busy) return;
    final generation = _generation;
    bool current() => mounted && generation == _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_playing) {
        await _player?.pause();
        if (current()) setState(() => _playing = false);
        return;
      }
      if (_player == null) {
        final file = await GuessAudioService.excerpt(
          musicId: widget.musicId,
          mode: widget.mode,
          start: 0,
          duration: widget.duration,
          rate: widget.rate,
          seed: widget.seed,
          singlePlayer: widget.singlePlayer,
          original: true,
          trigger: context.l10n.flowResultOriginalAudio,
        );
        if (!current()) return;
        final duration = await GuessAudioService.readExcerptDuration(file);
        if (!current()) return;
        final player = AudioPlayer();
        _player = player;
        await player.setReleaseMode(ReleaseMode.stop);
        if (!current()) return;
        await player.setSource(DeviceFileSource(file.path));
        if (!current()) return;
        setState(() => _duration =
            duration.inMicroseconds / Duration.microsecondsPerSecond);
        _positionSubscription = player.onPositionChanged.listen((position) {
          if (!current() || !_playing) return;
          setState(() => _position =
              (position.inMicroseconds / Duration.microsecondsPerSecond)
                  .clamp(0.0, _duration));
        });
        _completionSubscription = player.onPlayerComplete.listen((_) {
          if (!current()) return;
          setState(() {
            _playing = false;
            _finished = true;
            _position = _duration;
          });
        });
      }
      if (_finished || _position >= _duration) {
        await _player!.seek(Duration.zero);
        if (!current()) return;
        setState(() {
          _position = 0;
          _finished = false;
        });
      }
      setState(() => _playing = true);
      await _player!.resume();
    } catch (error) {
      debugPrint('[GuessAudio][结算原声] 播放失败：$error');
      if (current()) {
        _release();
        setState(() {
          _busy = _playing = _finished = false;
          _duration = _position = 0;
          _error = context.l10n.flowOriginalAudioIsUnavailablePleaseRetry;
        });
      }
    } finally {
      if (current()) setState(() => _busy = false);
    }
  }

  Future<void> _seek(double value) async {
    final generation = _generation;
    try {
      await _player?.seek(Duration(
          microseconds: (value * Duration.microsecondsPerSecond).round()));
      if (mounted && generation == _generation) {
        setState(() => _finished = value >= _duration);
      }
    } catch (error) {
      debugPrint('[GuessAudio][结算原声] 定位失败：$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loading = _busy && _duration == 0;
    final label = _error != null
        ? context.l10n.flowRetry
        : _playing
            ? context.l10n.flowPause
            : _finished
                ? context.l10n.flowReplay
                : context.l10n.flowPlayOriginalAudio;
    final timeStyle =
        AppTheme.number(fontSize: 11.5, color: scheme.onSurfaceVariant);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      child: Row(
        children: [
          PressScale(
            child: Semantics(
              button: true,
              label: label,
              child: Tooltip(
                message: label,
                child: GestureDetector(
                  onTap: _busy ? null : _togglePlayback,
                  child: AnimatedContainer(
                    duration: AppDesignTokens.motion(
                        context, const Duration(milliseconds: 180)),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _busy
                          ? AppSurfaces.inset(context)
                          : scheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: loading
                        ? Padding(
                            padding: const EdgeInsets.all(15),
                            child: CircularProgressIndicator(
                                strokeWidth: 2.4, color: scheme.primary),
                          )
                        : AnimatedSwitcher(
                            duration: AppDesignTokens.motion(
                                context, const Duration(milliseconds: 180)),
                            transitionBuilder: (child, animation) =>
                                ScaleTransition(scale: animation, child: child),
                            child: Icon(
                              _error != null || _finished
                                  ? Icons.replay_rounded
                                  : _playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                              key: ValueKey(label),
                              size: 30,
                              color: _busy
                                  ? scheme.onSurfaceVariant
                                  : scheme.onPrimary,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.flowOriginalAudioExcerpt,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _error ??
                      (loading ? context.l10n.flowPreparingOriginalAudio : context.l10n.flowTheSameExcerptPlayedForwardAtOriginal),
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _error != null ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: SliderComponentShape.noOverlay,
                    inactiveTrackColor: AppSurfaces.inset(context),
                  ),
                  child: Slider(
                    value: _position.clamp(0.0, _duration),
                    max: _duration > 0 ? _duration : 1,
                    onChanged: _duration > 0 && !_busy
                        ? (value) => setState(() => _position = value)
                        : null,
                    onChangeEnd: _seek,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.l10n.flowP0Seconds2((_position.toStringAsFixed(1)).toString()), style: timeStyle),
                    Text(
                      _duration > 0 ? context.l10n.flowP0Seconds2((_duration.toStringAsFixed(1)).toString()) : '--',
                      style: timeStyle,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
