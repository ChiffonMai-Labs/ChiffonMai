import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../service/GuessChartGame/GuessAudioService.dart';
import 'SmoothLinearProgressIndicator.dart';

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
          trigger: '结算原声',
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
          _error = '原声片段暂时无法播放，请重试';
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.music_note_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text('原声片段', style: Theme.of(context).textTheme.titleSmall),
          ]),
          const SizedBox(height: 6),
          Text('本轮同一段音源，按原速正向播放',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: SmoothLinearProgressIndicator(),
            )
          else
            Slider(
              value: _position.clamp(0.0, _duration),
              max: _duration > 0 ? _duration : 1,
              onChanged: _duration > 0 && !_busy
                  ? (value) => setState(() => _position = value)
                  : null,
              onChangeEnd: _seek,
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!, style: TextStyle(color: scheme.error)),
            ),
          Row(children: [
            Expanded(
              child: Text(
                _duration > 0
                    ? '${_position.toStringAsFixed(1)} / ${_duration.toStringAsFixed(1)} 秒'
                    : loading
                        ? '正在准备原声…'
                        : '点击播放试听',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : _togglePlayback,
              icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
              label: Text(_error != null
                  ? '重试'
                  : _playing
                      ? '暂停'
                      : _finished
                          ? '重新播放'
                          : '播放原声'),
            ),
          ]),
        ],
      ),
    );
  }
}
