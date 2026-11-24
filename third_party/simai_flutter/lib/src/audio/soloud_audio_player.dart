import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

enum SoLoudAudioState {
  idle,
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

Future<void> ensureSoLoudInitialized([SoLoud? soloud]) {
  final instance = soloud ?? SoLoud.instance;
  if (instance.isInitialized) return Future<void>.value();
  return SoLoudAudioPlayer._ensureInitialized(instance);
}

@immutable
class SoLoudAudioClockSnapshot {
  const SoLoudAudioClockSnapshot({
    required this.position,
    required this.receivedAt,
    required this.rate,
    required this.state,
    this.error,
  });

  final Duration position;
  final Duration receivedAt;
  final double rate;
  final SoLoudAudioState state;
  final String? error;

  bool get isAdvancing => state == SoLoudAudioState.playing;

  Duration positionAt(Duration now) {
    if (!isAdvancing || now <= receivedAt) return position;
    final elapsedUs = now.inMicroseconds - receivedAt.inMicroseconds;
    return Duration(
      microseconds: position.inMicroseconds + (elapsedUs * rate).round(),
    );
  }
}

@visibleForTesting
double correctedAudioClockRate({
  required Duration sampled,
  required Duration projected,
  required double playbackRate,
  Duration convergenceTime = const Duration(seconds: 2),
  double maximumRelativeAdjustment = 0.03,
}) {
  if (convergenceTime <= Duration.zero || playbackRate <= 0) {
    return playbackRate;
  }
  final errorSeconds =
      (sampled.inMicroseconds - projected.inMicroseconds) / 1000000.0;
  final convergenceSeconds =
      convergenceTime.inMicroseconds / Duration.microsecondsPerSecond;
  final correction = errorSeconds / convergenceSeconds;
  final maximumCorrection = playbackRate * maximumRelativeAdjustment;
  return playbackRate + correction.clamp(-maximumCorrection, maximumCorrection);
}

/// Small SoLoud-backed music player that exposes a monotonic playback clock.
class SoLoudAudioPlayer {
  SoLoudAudioPlayer({Stopwatch? clock, SoLoud? soloud})
    : _clock = clock ?? (Stopwatch()..start()),
      _soloud = soloud ?? SoLoud.instance {
    if (!_clock.isRunning) _clock.start();
  }

  static Future<void>? _initFuture;

  final Stopwatch _clock;
  final SoLoud _soloud;
  final StreamController<SoLoudAudioClockSnapshot> _controller =
      StreamController<SoLoudAudioClockSnapshot>.broadcast(sync: true);

  AudioSource? _source;
  SoundHandle? _handle;
  StreamSubscription<StreamSoundEvent>? _sourceEvents;
  Timer? _pollTimer;
  SoLoudAudioClockSnapshot? _latest;
  int _loadGeneration = 0;
  Duration _position = Duration.zero;
  double _rate = 1.0;
  double _volume = 0.8;
  bool _disposed = false;
  bool _sourceLoaded = false;

  Stream<SoLoudAudioClockSnapshot> get snapshots => _controller.stream;
  SoLoudAudioClockSnapshot? get latestSnapshot => _latest;
  Duration get monotonicNow => _clock.elapsed;

  Future<void> loadAsset(String asset) async {
    _ensureUsable();
    await _replaceSource(() => _soloud.loadAsset(asset));
  }

  Future<void> loadFile(String path) async {
    _ensureUsable();
    await _replaceSource(() => _soloud.loadFile(path));
  }

  Future<void> play() async {
    _ensureUsable();
    if (!_sourceLoaded) return;
    await ensureSoLoudInitialized(_soloud);
    final source = _source;
    if (source == null) return;

    var handle = _handle;
    if (handle == null || handle.isError) {
      handle = _soloud.play(source, volume: _volume, paused: true);
      _handle = handle;
      _soloud.setRelativePlaySpeed(handle, _rate);
      if (_position > Duration.zero) {
        _soloud.seek(handle, _position);
      }
    }

    _soloud.setVolume(handle, _volume);
    _soloud.setRelativePlaySpeed(handle, _rate);
    _soloud.setPause(handle, false);
    _emit(SoLoudAudioState.playing, position: _readPosition(handle));
    _startPolling();
  }

  Future<void> pause() async {
    _ensureUsable();
    final handle = _handle;
    if (handle != null && !handle.isError && _soloud.isInitialized) {
      _position = _readPosition(handle);
      _soloud.setPause(handle, true);
    }
    _emit(_sourceLoaded ? SoLoudAudioState.paused : SoLoudAudioState.idle);
  }

  Future<void> stop() async {
    _ensureUsable();
    await _stopHandle();
    _position = Duration.zero;
    _emit(_sourceLoaded ? SoLoudAudioState.ready : SoLoudAudioState.idle);
  }

  Future<void> seek(Duration position) async {
    _ensureUsable();
    _position = position.isNegative ? Duration.zero : position;
    final handle = _handle;
    if (handle != null && !handle.isError && _soloud.isInitialized) {
      _soloud.seek(handle, _position);
      _position = _readPosition(handle);
    }
    final state = _latest?.state == SoLoudAudioState.playing
        ? SoLoudAudioState.playing
        : (_sourceLoaded ? SoLoudAudioState.paused : SoLoudAudioState.idle);
    _emit(state);
  }

  Future<void> setRate(double rate) async {
    _ensureUsable();
    _rate = rate.clamp(0.1, 3.0).toDouble();
    final handle = _handle;
    Duration? position;
    if (handle != null && !handle.isError && _soloud.isInitialized) {
      _soloud.setRelativePlaySpeed(handle, _rate);
      position = _readPosition(handle);
    }
    _emit(_latest?.state ?? SoLoudAudioState.idle, position: position);
  }

  Future<void> setVolume(double volume) async {
    _ensureUsable();
    _volume = volume.clamp(0.0, 1.0).toDouble();
    final handle = _handle;
    if (handle != null && !handle.isError && _soloud.isInitialized) {
      _soloud.setVolume(handle, _volume);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _sourceEvents?.cancel();
    await _stopHandle();
    await _disposeSource();
    await _controller.close();
  }

  Future<void> _replaceSource(Future<AudioSource> Function() load) async {
    final generation = ++_loadGeneration;
    _sourceLoaded = false;
    _position = Duration.zero;
    _emit(SoLoudAudioState.loading);

    try {
      await ensureSoLoudInitialized(_soloud);
      await _sourceEvents?.cancel();
      await _stopHandle();
      await _disposeSource();
      final source = await load();
      if (_disposed || generation != _loadGeneration) {
        await _soloud.disposeSource(source);
        return;
      }
      _source = source;
      _sourceLoaded = true;
      _sourceEvents = source.soundEvents.listen(_handleSoundEvent);
      _emit(SoLoudAudioState.ready);
    } catch (e) {
      _emit(SoLoudAudioState.error, error: e.toString());
      rethrow;
    }
  }

  static Future<void> _ensureInitialized(SoLoud soloud) {
    if (soloud.isInitialized) return Future<void>.value();
    return _initFuture ??= _initializeEngine(soloud).whenComplete(() {
      _initFuture = null;
    });
  }

  static Future<void> _initializeEngine(SoLoud soloud) async {
    var sampleRate = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 48000
        : 44100;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // SoLoud 的 CoreAudio 后端要求宿主先激活音频会话。
      final deviceSampleRate = await const MethodChannel(
        'simai_flutter/audio',
      ).invokeMethod<int>('activateAudioSession');
      if (deviceSampleRate != null && deviceSampleRate > 0) {
        sampleRate = deviceSampleRate;
      }
      debugPrint('SFX: iOS audio session active, sampleRate=$sampleRate');
    }
    const int preferredBufferSize = 512;
    try {
      await soloud.init(
        sampleRate: sampleRate,
        bufferSize: preferredBufferSize,
      );
    } on SoLoudException {
      debugPrint(
        'SFX: retrying audio initialization with default bufferSize '
        '(sampleRate=$sampleRate)',
      );
      try {
        await soloud.init(sampleRate: sampleRate);
      } on SoLoudBackendNotInitedException {
        if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) rethrow;
        // iOS 设备启动失败时重试保守配置，不使用无声时钟掩盖错误。
        debugPrint(
          'SFX: retrying iOS audio initialization with lowLatency=false',
        );
        await soloud.init(sampleRate: sampleRate, lowLatency: false);
      }
    }
    try {
      soloud.setMaxActiveVoiceCount(32);
    } catch (e) {
      debugPrint('SFX: setMaxActiveVoiceCount failed: $e');
    }
  }

  void _handleSoundEvent(StreamSoundEvent event) {
    if (_disposed || event.handle != _handle) return;
    if (event.event == SoundEventType.handleIsNoMoreValid) {
      _handle = null;
      _position = Duration.zero;
      _pollTimer?.cancel();
      _pollTimer = null;
      _emit(SoLoudAudioState.completed);
    }
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final handle = _handle;
      if (_disposed ||
          handle == null ||
          handle.isError ||
          !_soloud.isInitialized) {
        return;
      }
      _emit(
        _soloud.getPause(handle)
            ? SoLoudAudioState.paused
            : SoLoudAudioState.playing,
        position: _readPosition(handle),
        preserveProjectedProgress: true,
      );
    });
  }

  Duration _readPosition(SoundHandle handle) {
    try {
      _position = _soloud.getPosition(handle);
    } catch (_) {
      return _position;
    }
    return _position;
  }

  Future<void> _stopHandle() async {
    final handle = _handle;
    _handle = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (handle == null || handle.isError || !_soloud.isInitialized) return;
    try {
      await _soloud.stop(handle);
    } catch (_) {
      // Handles can become invalid as playback completes.
    }
  }

  Future<void> _disposeSource() async {
    final source = _source;
    _source = null;
    if (source == null || !_soloud.isInitialized) return;
    try {
      await _soloud.disposeSource(source);
    } catch (_) {
      // The global SoLoud engine may be torn down by the host app.
    }
  }

  void _emit(
    SoLoudAudioState state, {
    Duration? position,
    String? error,
    bool preserveProjectedProgress = false,
  }) {
    if (_disposed) return;
    final now = _clock.elapsed;
    var anchorPosition = position ?? _position;
    var clockRate = _rate;
    final previous = _latest;
    if (preserveProjectedProgress &&
        state == SoLoudAudioState.playing &&
        previous?.state == SoLoudAudioState.playing) {
      final projected = previous!.positionAt(now);
      clockRate = correctedAudioClockRate(
        sampled: anchorPosition,
        projected: projected,
        playbackRate: _rate,
      );
      // Keep position continuous and converge by imperceptibly varying only
      // the visual clock rate. Explicit seeks do not use this path.
      anchorPosition = projected;
    }
    final snapshot = SoLoudAudioClockSnapshot(
      position: anchorPosition,
      receivedAt: now,
      rate: clockRate,
      state: state,
      error: error,
    );
    _latest = snapshot;
    _controller.add(snapshot);
  }

  void _ensureUsable() {
    if (_disposed) throw StateError('SoLoudAudioPlayer is already disposed.');
  }
}
