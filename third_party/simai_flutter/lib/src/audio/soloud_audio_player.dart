import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../ui/utils/custom_file_probe.dart';

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

/// 基于引用计数的 SoLoud 音源共享池。
///
/// 按 `file:$path` / `asset:$asset` 复用同一份已解码的 [AudioSource]，支持并发加载
/// in-flight 去重，且仅在引用计数归零时调用 [SoLoud.disposeSource]，避免双实例重复
/// 注册断言、双倍 PCM 内存占用，以及退出游玩页时误销毁底层预览页的共享音源。
class SoLoudSourcePool {
  const SoLoudSourcePool._();

  static final Expando<_SoLoudPoolState> _states = Expando<_SoLoudPoolState>(
    'simai_soloud_source_pool',
  );

  static _SoLoudPoolState _stateFor(SoLoud soloud) =>
      _states[soloud] ??= _SoLoudPoolState();

  /// 获取或复用本地文件对应的 [AudioSource]，并递增引用计数。
  static Future<AudioSource> acquireFile(String path, [SoLoud? soloud]) {
    final instance = soloud ?? SoLoud.instance;
    return _acquire(
      key: 'file:$path',
      soloud: instance,
      loader: (engine) => engine.loadFile(path),
    );
  }

  /// 获取或复用资源包内音频对应的 [AudioSource]，并递增引用计数。
  static Future<AudioSource> acquireAsset(String asset, [SoLoud? soloud]) {
    final instance = soloud ?? SoLoud.instance;
    return _acquire(
      key: 'asset:$asset',
      soloud: instance,
      loader: (engine) => engine.loadAsset(asset),
    );
  }

  /// 释放由共享池获取的 [AudioSource] 引用；仅当引用计数归零时销毁底层音源。
  static Future<void> release(AudioSource source, [SoLoud? soloud]) async {
    final instance = soloud ?? SoLoud.instance;
    final state = _stateFor(instance);
    final entry = state.bySource[source];
    if (entry == null) return;
    entry.refCount--;
    if (entry.refCount > 0) return;

    state.bySource.remove(source);
    if (identical(state.byKey[entry.key], entry)) {
      state.byKey.remove(entry.key);
    }
    if (!instance.isInitialized) return;

    final disposeTask = _disposeNativeSource(instance, source);
    state.disposing[entry.key] = disposeTask;
    try {
      await disposeTask;
    } finally {
      if (identical(state.disposing[entry.key], disposeTask)) {
        state.disposing.remove(entry.key);
      }
    }
  }

  static Future<AudioSource> _acquire({
    required String key,
    required SoLoud soloud,
    required Future<AudioSource> Function(SoLoud engine) loader,
  }) {
    final state = _stateFor(soloud);
    if (!soloud.isInitialized && state.inFlight.isEmpty) {
      // 全局引擎若已被宿主反初始化，清空已失效的旧条目，防止复用悬空句柄。
      state.byKey.clear();
      state.bySource.clear();
    }

    final existing = state.byKey[key];
    if (existing != null && soloud.isInitialized) {
      existing.refCount++;
      return Future<AudioSource>.value(existing.source);
    }

    final pending = state.inFlight[key];
    if (pending != null) {
      pending.waiters++;
      return pending.future;
    }

    final completer = Completer<AudioSource>();
    final inFlight = _InFlightSourceLoad(completer.future);
    state.inFlight[key] = inFlight;
    _loadAndRegister(
      state: state,
      key: key,
      inFlight: inFlight,
      completer: completer,
      soloud: soloud,
      loader: loader,
    );
    return inFlight.future;
  }

  static Future<void> _loadAndRegister({
    required _SoLoudPoolState state,
    required String key,
    required _InFlightSourceLoad inFlight,
    required Completer<AudioSource> completer,
    required SoLoud soloud,
    required Future<AudioSource> Function(SoLoud engine) loader,
  }) async {
    try {
      // 若同一键名正处于异步释放中，先等旧音源释放完毕再重新加载，避免句柄竞态。
      final pendingDispose = state.disposing[key];
      if (pendingDispose != null) {
        await pendingDispose;
      }
      await ensureSoLoudInitialized(soloud);
      final source = await loader(soloud);
      // 在唤醒任何等待者之前一次性写入全部并发等待者的引用计数，
      // 防止先恢复的调用方立即 release 时将仍被其他等待者使用的音源提前销毁。
      final entry = _PooledAudioSource(
        key: key,
        source: source,
        refCount: inFlight.waiters,
      );
      state.inFlight.remove(key);
      state.byKey[key] = entry;
      state.bySource[source] = entry;
      completer.complete(source);
    } catch (e, st) {
      state.inFlight.remove(key);
      completer.completeError(e, st);
    }
  }

  static Future<void> _disposeNativeSource(
    SoLoud soloud,
    AudioSource source,
  ) async {
    try {
      await soloud.disposeSource(source);
    } catch (_) {
      // 全局 SoLoud 引擎可能已被宿主关闭，释放失败时静默忽略。
    }
  }
}

class _SoLoudPoolState {
  final Map<String, _PooledAudioSource> byKey = <String, _PooledAudioSource>{};
  final Map<AudioSource, _PooledAudioSource> bySource =
      Map<AudioSource, _PooledAudioSource>.identity();
  final Map<String, _InFlightSourceLoad> inFlight =
      <String, _InFlightSourceLoad>{};
  final Map<String, Future<void>> disposing = <String, Future<void>>{};
}

class _PooledAudioSource {
  _PooledAudioSource({
    required this.key,
    required this.source,
    required this.refCount,
  });

  final String key;
  final AudioSource source;
  int refCount;
}

class _InFlightSourceLoad {
  _InFlightSourceLoad(this.future);

  final Future<AudioSource> future;
  int waiters = 1;
}

@immutable
class SoLoudAudioClockSnapshot {
  const SoLoudAudioClockSnapshot({
    required this.position,
    required this.receivedAt,
    required this.rate,
    required this.state,
    this.segmentStartPosition = Duration.zero,
    this.error,
  });

  final Duration position;
  final Duration receivedAt;
  final double rate;
  final SoLoudAudioState state;

  /// 本段连续播放的起始位置，用于反向外推时的下限钳位。
  final Duration segmentStartPosition;
  final String? error;

  bool get isAdvancing => state == SoLoudAudioState.playing;

  Duration positionAt(Duration now) {
    if (!isAdvancing) return position;
    final deltaUs = now.inMicroseconds - receivedAt.inMicroseconds;
    final projectedUs = position.inMicroseconds + (deltaUs * rate).round();
    if (deltaUs < 0) {
      // 允许在 now < receivedAt 时线性反向外推，还原晚到达触控事件的历史音频时刻，
      // 并将下限钳位到本段连续播放起点（且不小于 0，且不超过当前锚点位置）。
      final segmentFloorUs = segmentStartPosition.inMicroseconds > 0
          ? segmentStartPosition.inMicroseconds
          : 0;
      final positionFloorUs = position.inMicroseconds > 0
          ? position.inMicroseconds
          : 0;
      final lowerBoundUs = segmentFloorUs <= positionFloorUs
          ? segmentFloorUs
          : positionFloorUs;
      return Duration(
        microseconds: projectedUs < lowerBoundUs ? lowerBoundUs : projectedUs,
      );
    }
    return Duration(microseconds: projectedUs < 0 ? 0 : projectedUs);
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

/// 基于 SoLoud 的单调时钟音频播放器。
class SoLoudAudioPlayer {
  SoLoudAudioPlayer({Stopwatch? clock, SoLoud? soloud})
    : _clock = clock ?? (Stopwatch()..start()),
      _soloud = soloud ?? SoLoud.instance {
    if (!_clock.isRunning) _clock.start();
  }

  /// 采样与投影偏差超过 40ms 时直接重锚，避免 2s 慢速 PLL 长时间拖尾。
  static const int _reanchorErrorThresholdUs = 40000;

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
  Duration _segmentStartPosition = Duration.zero;
  bool _awaitingFirstNonZeroSample = true;
  double _rate = 1.0;
  double _volume = 0.8;
  bool _disposed = false;
  bool _sourceLoaded = false;

  Stream<SoLoudAudioClockSnapshot> get snapshots => _controller.stream;
  SoLoudAudioClockSnapshot? get latestSnapshot => _latest;
  Duration get monotonicNow => _clock.elapsed;

  Future<void> loadAsset(String asset) async {
    _ensureUsable();
    await _replaceSource(() => SoLoudSourcePool.acquireAsset(asset, _soloud));
  }

  Future<void> loadFile(String path) async {
    _ensureUsable();
    await _replaceSource(() => SoLoudSourcePool.acquireFile(path, _soloud));
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
      if (!handle.isError) {
        try {
          // 保护 BGM 声道，防止极端高密度正解音触发声道上限时抢占主音轨。
          _soloud.setProtectVoice(handle, true);
        } catch (e) {
          debugPrint('SFX: setProtectVoice failed: $e');
        }
      }
      _soloud.setRelativePlaySpeed(handle, _rate);
      if (_position > Duration.zero) {
        _soloud.seek(handle, _position);
      }
    }

    _soloud.setVolume(handle, _volume);
    _soloud.setRelativePlaySpeed(handle, _rate);
    _soloud.setPause(handle, false);
    final currentPos = _readPosition(handle);
    _segmentStartPosition = currentPos.isNegative ? Duration.zero : currentPos;
    _awaitingFirstNonZeroSample = currentPos <= Duration.zero;
    _emit(SoLoudAudioState.playing, position: currentPos);
    _startPolling();
  }

  Future<void> pause() async {
    _ensureUsable();
    // 暂停后立即停止 16ms FFI 轮询，防止后台实例持续抢占音频引擎锁。
    _pollTimer?.cancel();
    _pollTimer = null;
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
    _segmentStartPosition = Duration.zero;
    _awaitingFirstNonZeroSample = true;
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
    _segmentStartPosition = _position.isNegative ? Duration.zero : _position;
    _awaitingFirstNonZeroSample = _position <= Duration.zero;
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
    final anchor = position ?? _position;
    _segmentStartPosition = anchor.isNegative ? Duration.zero : anchor;
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
    await _disposeCurrentSource();
    await _controller.close();
  }

  Future<void> _replaceSource(Future<AudioSource> Function() load) async {
    final generation = ++_loadGeneration;
    _pollTimer?.cancel();
    _pollTimer = null;
    _sourceLoaded = false;
    _position = Duration.zero;
    _segmentStartPosition = Duration.zero;
    _awaitingFirstNonZeroSample = true;
    _emit(SoLoudAudioState.loading);

    try {
      await ensureSoLoudInitialized(_soloud);
      await _sourceEvents?.cancel();
      await _stopHandle();
      await _disposeCurrentSource();
      final source = await load();
      if (_disposed || generation != _loadGeneration) {
        await SoLoudSourcePool.release(source, _soloud);
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
    var preferredBufferSize = 512;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // 查询 Android 硬件原生采样率与 burst 帧数，避免掉出 FastTrack 或触发系统重采样。
      try {
        final config = await const MethodChannel(
          'simai_flutter/audio',
        ).invokeMapMethod<String, dynamic>('getAndroidAudioOutputConfig');
        final nativeRate = _parsePositiveInt(config?['sampleRate']);
        if (nativeRate != null && nativeRate >= 8000 && nativeRate <= 192000) {
          sampleRate = nativeRate;
        }
        final framesPerBuffer = _parsePositiveInt(config?['framesPerBuffer']);
        if (framesPerBuffer != null) {
          preferredBufferSize = _selectAndroidBufferSize(framesPerBuffer);
        }
        debugPrint(
          'SFX: Android audio config sampleRate=$sampleRate '
          'framesPerBuffer=$framesPerBuffer '
          'preferredBufferSize=$preferredBufferSize',
        );
      } on MissingPluginException {
        // 测试环境或未注册原生音频通道时安全回退默认值。
      } catch (e) {
        debugPrint('SFX: getAndroidAudioOutputConfig failed: $e');
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      // SoLoud 的 CoreAudio 后端要求宿主先激活音频会话。
      final deviceSampleRate = await const MethodChannel(
        'simai_flutter/audio',
      ).invokeMethod<int>('activateAudioSession');
      if (deviceSampleRate != null && deviceSampleRate > 0) {
        sampleRate = deviceSampleRate;
      }
      debugPrint('SFX: iOS audio session active, sampleRate=$sampleRate');
    }

    try {
      await soloud.init(
        sampleRate: sampleRate,
        bufferSize: preferredBufferSize,
      );
    } on SoLoudException {
      var initialized = false;
      if (preferredBufferSize != 512) {
        debugPrint(
          'SFX: retrying audio initialization with bufferSize=512 '
          '(sampleRate=$sampleRate)',
        );
        try {
          await soloud.init(sampleRate: sampleRate, bufferSize: 512);
          initialized = true;
        } on SoLoudException {
          initialized = false;
        }
      }
      if (!initialized) {
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
    }
    try {
      soloud.setMaxActiveVoiceCount(32);
    } catch (e) {
      debugPrint('SFX: setMaxActiveVoiceCount failed: $e');
    }
  }

  /// 在 `[256, 512]` 区间内选取 [framesPerBuffer] 的最小正整数倍；无法命中时回退 512。
  static int _selectAndroidBufferSize(int framesPerBuffer) {
    if (framesPerBuffer <= 0 || framesPerBuffer > 512) return 512;
    final multiplier = (256 + framesPerBuffer - 1) ~/ framesPerBuffer;
    final candidate = framesPerBuffer * multiplier;
    if (candidate >= 256 && candidate <= 512) {
      return candidate;
    }
    return 512;
  }

  static int? _parsePositiveInt(Object? raw) {
    if (raw is int && raw > 0) return raw;
    if (raw is num && raw.isFinite && raw > 0) return raw.round();
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  void _handleSoundEvent(StreamSoundEvent event) {
    if (_disposed || event.handle != _handle) return;
    if (event.event == SoundEventType.handleIsNoMoreValid) {
      _handle = null;
      _position = Duration.zero;
      _segmentStartPosition = Duration.zero;
      _awaitingFirstNonZeroSample = true;
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
      // 播放结束时句柄可能已失效，安全忽略。
    }
  }

  Future<void> _disposeCurrentSource() async {
    final source = _source;
    _source = null;
    if (source == null) return;
    await SoLoudSourcePool.release(source, _soloud);
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
      final errorUs = (anchorPosition.inMicroseconds - projected.inMicroseconds)
          .abs();
      final isFirstNonZeroSample =
          _awaitingFirstNonZeroSample && anchorPosition > Duration.zero;
      if (isFirstNonZeroSample) {
        _awaitingFirstNonZeroSample = false;
      }
      if (isFirstNonZeroSample || errorUs > _reanchorErrorThresholdUs) {
        // 起播首个非零样本或偏差超过 40ms 时直接重锚，避免 2s 慢速 PLL 爬行导致开局判定漂移。
        clockRate = _rate;
        if (anchorPosition < _segmentStartPosition) {
          _segmentStartPosition = anchorPosition.isNegative
              ? Duration.zero
              : anchorPosition;
        }
      } else {
        clockRate = correctedAudioClockRate(
          sampled: anchorPosition,
          projected: projected,
          playbackRate: _rate,
        );
        // 常规微小偏差保持投影位置连续，仅通过微调时钟速率平滑收敛。
        anchorPosition = projected;
      }
    } else if (state == SoLoudAudioState.playing) {
      if (anchorPosition > Duration.zero) {
        _awaitingFirstNonZeroSample = false;
      }
      _segmentStartPosition = anchorPosition.isNegative
          ? Duration.zero
          : anchorPosition;
    }
    final snapshot = SoLoudAudioClockSnapshot(
      position: anchorPosition,
      receivedAt: now,
      rate: clockRate,
      state: state,
      segmentStartPosition: _segmentStartPosition,
      error: error,
    );
    _latest = snapshot;
    _controller.add(snapshot);
  }

  void _ensureUsable() {
    if (_disposed) throw StateError('SoLoudAudioPlayer is already disposed.');
  }
}

/// 使用全局 SoLoud 音源共享池试听一次正解音（优先播放自定义音频文件，失败时回退内置正解音）。
Future<void> previewSimaiHitSound({
  String? customFilePath,
  double volume = 1.0,
}) async {
  final soloud = SoLoud.instance;
  await ensureSoLoudInitialized(soloud);
  const defaultAsset = 'packages/simai_flutter/assets/answer.wav';
  final path = customFilePath?.trim();
  AudioSource source;
  if (!kIsWeb && path != null && path.isNotEmpty && customFileExists(path)) {
    try {
      source = await SoLoudSourcePool.acquireFile(path, soloud);
    } catch (_) {
      source = await SoLoudSourcePool.acquireAsset(defaultAsset, soloud);
    }
  } else {
    source = await SoLoudSourcePool.acquireAsset(defaultAsset, soloud);
  }
  try {
    soloud.play(source, volume: volume.clamp(0.0, 3.0).toDouble());
  } finally {
    Future<void>.delayed(const Duration(seconds: 3), () {
      unawaited(SoLoudSourcePool.release(source, soloud));
    });
  }
}
