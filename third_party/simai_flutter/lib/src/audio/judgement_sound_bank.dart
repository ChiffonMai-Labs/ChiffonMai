import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../gameplay/gameplay_models.dart';
import '../structures/mai_chart.dart';
import '../structures/note.dart';
import '../structures/note_group.dart';
import '../structures/note_styles.dart';
import '../ui/auto_play_mode.dart';
import '../ui/simai_game.dart' show simaiMaxHitSoundVolume;
import '../ui/utils/custom_file_probe.dart';
import 'soloud_audio_player.dart';

/// 街机式「判定时音效」音色分类（独立于正解音）。
enum SimaiJudgementSoundKind {
  perfect(
    'packages/simai_flutter/assets/sfx/judge_perfect.wav',
    'P',
    '普通 TAP / HOLD 命中',
  ),
  great(
    'packages/simai_flutter/assets/sfx/judge_great.wav',
    'Great',
    'Great 档位命中',
  ),
  good(
    'packages/simai_flutter/assets/sfx/judge_good.wav',
    'Good',
    'Good 档位命中',
  ),
  ex('packages/simai_flutter/assets/sfx/judge_ex.wav', 'EX', 'EX 音符命中'),
  touch(
    'packages/simai_flutter/assets/sfx/judge_touch.wav',
    'Touch',
    '普通 TOUCH 命中',
  ),
  breakCriticalPerfect(
    'packages/simai_flutter/assets/sfx/judge_break_cp.wav',
    '2600 绝赞',
    '绝赞 2600 Critical Perfect',
  ),
  breakPerfect(
    'packages/simai_flutter/assets/sfx/judge_break_p.wav',
    '2550 绝赞',
    '绝赞 2550 / 2500 Perfect',
  ),
  slide(
    'packages/simai_flutter/assets/sfx/judge_slide.wav',
    '滑星',
    'SLIDE 滑条启动',
  ),
  breakSlide(
    'packages/simai_flutter/assets/sfx/judge_break_slide.wav',
    '绝赞滑星',
    '绝赞 SLIDE 2600 欢呼',
  ),
  hanabi(
    'packages/simai_flutter/assets/sfx/judge_hanabi.wav',
    '烟花',
    '烟花 TOUCH 绽放叠加',
  );

  const SimaiJudgementSoundKind(this.assetPath, this.label, this.description);

  final String assetPath;
  final String label;
  final String description;
}

/// 各判定音色的自定义本地文件路径映射（仅替换已配置项，未配置项沿用内置机台音效）。
@immutable
class SimaiCustomJudgementSounds {
  static const SimaiCustomJudgementSounds empty =
      SimaiCustomJudgementSounds._(<String, String>{});

  static final Map<String, SimaiJudgementSoundKind> _byName =
      <String, SimaiJudgementSoundKind>{
        for (final kind in SimaiJudgementSoundKind.values) kind.name: kind,
      };

  final Map<String, String> soundPaths;

  const SimaiCustomJudgementSounds._(this.soundPaths);

  factory SimaiCustomJudgementSounds(Map<String, String> rawPaths) {
    if (rawPaths.isEmpty) return empty;
    final cleaned = <String, String>{};
    for (final kind in SimaiJudgementSoundKind.values) {
      final path = rawPaths[kind.name]?.trim();
      if (path != null && path.isNotEmpty) {
        cleaned[kind.name] = path;
      }
    }
    if (cleaned.isEmpty) return empty;
    return SimaiCustomJudgementSounds._(
      Map<String, String>.unmodifiable(cleaned),
    );
  }

  factory SimaiCustomJudgementSounds.fromJson(Object? raw) {
    if (raw is! Map) return empty;
    final map = <String, String>{};
    raw.forEach((key, value) {
      if (key is String && value is String && _byName.containsKey(key)) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          map[key] = trimmed;
        }
      }
    });
    return SimaiCustomJudgementSounds(map);
  }

  Map<String, String> toJson() => Map<String, String>.from(soundPaths);

  bool get isEmpty => soundPaths.isEmpty;

  bool get isNotEmpty => soundPaths.isNotEmpty;

  int get customizedCount => soundPaths.length;

  String? pathFor(SimaiJudgementSoundKind kind) => soundPaths[kind.name];

  SimaiCustomJudgementSounds withSound(
    SimaiJudgementSoundKind kind,
    String? path,
  ) {
    final next = Map<String, String>.from(soundPaths);
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      next.remove(kind.name);
    } else {
      next[kind.name] = trimmed;
    }
    return SimaiCustomJudgementSounds(next);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SimaiCustomJudgementSounds) return false;
    if (soundPaths.length != other.soundPaths.length) return false;
    for (final entry in soundPaths.entries) {
      if (other.soundPaths[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    for (final kind in SimaiJudgementSoundKind.values)
      if (soundPaths.containsKey(kind.name))
        Object.hash(kind.name, soundPaths[kind.name]),
  ]);
}

/// 各判定音效的独立音量倍率映射（0.0 ~ [simaiMaxHitSoundVolume]，默认 1.0）。
///
/// 仅保存与默认值不同的项，便于序列化紧凑与后续扩展新音色时自动继承 100%。
@immutable
class SimaiJudgementSoundVolumes {
  static const double defaultVolume = 1.0;
  static const SimaiJudgementSoundVolumes defaults =
      SimaiJudgementSoundVolumes._(<String, double>{});

  static final Map<String, SimaiJudgementSoundKind> _byName =
      <String, SimaiJudgementSoundKind>{
        for (final kind in SimaiJudgementSoundKind.values) kind.name: kind,
      };

  final Map<String, double> _volumes;

  const SimaiJudgementSoundVolumes._(this._volumes);

  factory SimaiJudgementSoundVolumes(Map<String, double> rawVolumes) {
    if (rawVolumes.isEmpty) return defaults;
    final cleaned = <String, double>{};
    for (final kind in SimaiJudgementSoundKind.values) {
      final raw = rawVolumes[kind.name];
      if (raw == null) continue;
      final normalized = _normalizeVolume(raw);
      if ((normalized - defaultVolume).abs() >= 1e-6) {
        cleaned[kind.name] = normalized;
      }
    }
    if (cleaned.isEmpty) return defaults;
    return SimaiJudgementSoundVolumes._(
      Map<String, double>.unmodifiable(cleaned),
    );
  }

  /// 用统一音量填充所有音色，兼容旧版单一 `judgementSoundVolume` 持久化迁移。
  factory SimaiJudgementSoundVolumes.uniform(double volume) {
    final normalized = _normalizeVolume(volume);
    if ((normalized - defaultVolume).abs() < 1e-6) return defaults;
    return SimaiJudgementSoundVolumes(<String, double>{
      for (final kind in SimaiJudgementSoundKind.values) kind.name: normalized,
    });
  }

  factory SimaiJudgementSoundVolumes.fromJson(
    Object? raw, {
    Object? legacyVolume,
  }) {
    if (raw is Map) {
      final parsed = <String, double>{};
      raw.forEach((key, value) {
        if (key is String && _byName.containsKey(key) && value is num) {
          parsed[key] = value.toDouble();
        }
      });
      return SimaiJudgementSoundVolumes(parsed);
    }
    if (legacyVolume is num && legacyVolume.isFinite) {
      return SimaiJudgementSoundVolumes.uniform(legacyVolume.toDouble());
    }
    return defaults;
  }

  static double _normalizeVolume(double raw) {
    final safe = raw.isFinite ? raw : defaultVolume;
    final clamped = safe.clamp(0.0, simaiMaxHitSoundVolume).toDouble();
    // 对齐到 1% 步进，减少浮点尾数并在 100% 时自动回归默认值。
    return (clamped * 100).round() / 100.0;
  }

  Map<String, double> toJson() => <String, double>{
    for (final kind in SimaiJudgementSoundKind.values)
      if (_volumes.containsKey(kind.name)) kind.name: _volumes[kind.name]!,
  };

  bool get isAllDefault => _volumes.isEmpty;

  int get customizedCount => _volumes.length;

  double volumeFor(SimaiJudgementSoundKind kind) =>
      _volumes[kind.name] ?? defaultVolume;

  SimaiJudgementSoundVolumes withVolume(
    SimaiJudgementSoundKind kind,
    double volume,
  ) {
    final normalized = _normalizeVolume(volume);
    if ((volumeFor(kind) - normalized).abs() < 1e-6) return this;
    final next = Map<String, double>.from(_volumes);
    if ((normalized - defaultVolume).abs() < 1e-6) {
      next.remove(kind.name);
    } else {
      next[kind.name] = normalized;
    }
    return SimaiJudgementSoundVolumes(next);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SimaiJudgementSoundVolumes) return false;
    if (_volumes.length != other._volumes.length) return false;
    for (final entry in _volumes.entries) {
      if (other._volumes[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    for (final kind in SimaiJudgementSoundKind.values)
      if (_volumes.containsKey(kind.name))
        Object.hash(kind.name, _volumes[kind.name]),
  ]);
}

/// 自动模拟/视频导出使用的单条计划判定音效事件。
@immutable
class SimaiScheduledJudgeSfxEvent {
  final int timeUs;
  final SimaiJudgementSoundKind kind;
  final bool isHanabi;

  const SimaiScheduledJudgeSfxEvent({
    required this.timeUs,
    required this.kind,
    required this.isHanabi,
  });
}

/// 根据谱面、自动模拟时间线与音效偏移生成升序排列的判定音效事件列表。
///
/// 与实时预览完全同源：普通滑条在启动时刻触发 `slide`，绝赞滑条在走完 CP 时额外触发 `breakSlide`。
List<SimaiScheduledJudgeSfxEvent> buildSimaiJudgementSoundEvents({
  required MaiChart chart,
  required SimaiAutoPlayTimeline autoPlayTimeline,
  int userOffsetMs = 0,
}) {
  final offsetSeconds = userOffsetMs / 1000.0;
  final list = <SimaiScheduledJudgeSfxEvent>[];
  for (final record in autoPlayTimeline.events) {
    if (record.collectionIndex < 0 ||
        record.collectionIndex >= chart.noteCollections.length) {
      continue;
    }
    final col = chart.noteCollections[record.collectionIndex];
    if (record.noteIndex < 0 || record.noteIndex >= col.length) continue;
    final note = col[record.noteIndex];
    final slideIdx = record.slidePathIndex;
    if (slideIdx != null) {
      if (record.grade == SimaiJudgeGrade.miss) continue;
      if (slideIdx >= 0 && slideIdx < note.slidePaths.length) {
        final startTime =
            col.time + math.max(0.0, note.slidePaths[slideIdx].delay);
        list.add(
          SimaiScheduledJudgeSfxEvent(
            timeUs: ((startTime + offsetSeconds) * 1000000).round(),
            kind: SimaiJudgementSoundKind.slide,
            isHanabi: false,
          ),
        );
      }
      final endKind = resolveSimaiJudgementSoundKind(
        record: record,
        note: note,
      );
      if (endKind != null) {
        list.add(
          SimaiScheduledJudgeSfxEvent(
            timeUs: ((record.judgedTime + offsetSeconds) * 1000000).round(),
            kind: endKind,
            isHanabi: false,
          ),
        );
      }
      continue;
    }
    final kind = resolveSimaiJudgementSoundKind(record: record, note: note);
    if (kind == null) continue;
    final bool isHanabi = shouldPlaySimaiHanabiSound(
      record: record,
      note: note,
    );
    list.add(
      SimaiScheduledJudgeSfxEvent(
        timeUs: ((record.judgedTime + offsetSeconds) * 1000000).round(),
        kind: kind,
        isHanabi: isHanabi,
      ),
    );
  }
  list.sort((a, b) => a.timeUs.compareTo(b.timeUs));
  return list;
}

/// 根据判定记录与音符属性映射走完判定时刻的音效；
/// 普通滑条在开始启动时播放 `slide`，故走完仅在绝赞滑条 2600 Critical Perfect 时发 `breakSlide`。
SimaiJudgementSoundKind? resolveSimaiJudgementSoundKind({
  required SimaiJudgementRecord record,
  required Note note,
}) {
  if (record.grade == SimaiJudgeGrade.miss) return null;
  final bool isSlide = record.slidePathIndex != null;
  final bool isBreak = record.scoringType == SimaiGameplayScoringType.breakNote;
  if (isSlide) {
    return (isBreak && record.grade == SimaiJudgeGrade.criticalPerfect)
        ? SimaiJudgementSoundKind.breakSlide
        : null;
  }
  final bool isEx = (note.styles & NoteStyles.ex) != 0;
  if (isBreak) {
    return switch (record.grade) {
      SimaiJudgeGrade.criticalPerfect =>
        SimaiJudgementSoundKind.breakCriticalPerfect,
      SimaiJudgeGrade.perfect => SimaiJudgementSoundKind.breakPerfect,
      SimaiJudgeGrade.great => SimaiJudgementSoundKind.great,
      SimaiJudgeGrade.good => SimaiJudgementSoundKind.good,
      SimaiJudgeGrade.miss => null,
    };
  }
  if (isEx) {
    return SimaiJudgementSoundKind.ex;
  }
  final bool isTouch = note.location.group != NoteGroup.tap;
  if (isTouch) {
    return switch (record.grade) {
      SimaiJudgeGrade.criticalPerfect ||
      SimaiJudgeGrade.perfect => SimaiJudgementSoundKind.touch,
      SimaiJudgeGrade.great => SimaiJudgementSoundKind.great,
      SimaiJudgeGrade.good => SimaiJudgementSoundKind.good,
      SimaiJudgeGrade.miss => null,
    };
  }
  return switch (record.grade) {
    SimaiJudgeGrade.criticalPerfect ||
    SimaiJudgeGrade.perfect => SimaiJudgementSoundKind.perfect,
    SimaiJudgeGrade.great => SimaiJudgementSoundKind.great,
    SimaiJudgeGrade.good => SimaiJudgementSoundKind.good,
    SimaiJudgeGrade.miss => null,
  };
}

/// 烟花属性 Touch 命中且未 Miss 时，叠加播放一次烟花绽放音效。
bool shouldPlaySimaiHanabiSound({
  required SimaiJudgementRecord record,
  required Note note,
}) {
  if (record.grade == SimaiJudgeGrade.miss) return false;
  if (record.slidePathIndex != null) return false;
  if (note.location.group == NoteGroup.tap) return false;
  return (note.styles & NoteStyles.fireworks) != 0;
}

/// 判定音效共享池控制器，负责全音色预加载、自定义覆盖加载、高密自动限幅与声道回收。
class SimaiJudgementSoundBank {
  SimaiJudgementSoundBank({
    SoLoud? soloud,
    SimaiCustomJudgementSounds customSounds = SimaiCustomJudgementSounds.empty,
  }) : _soloud = soloud ?? SoLoud.instance,
       _customSounds = customSounds;

  static const int _maxVoices = 24;
  static const int _overlapWindowUs = 80000;

  final SoLoud _soloud;
  SimaiCustomJudgementSounds _customSounds;
  final Map<SimaiJudgementSoundKind, AudioSource> _sources =
      <SimaiJudgementSoundKind, AudioSource>{};
  final Queue<SoundHandle> _voices = Queue<SoundHandle>();
  final Queue<int> _recentPlayTimesUs = Queue<int>();
  Future<void>? _loadingTask;
  int _loadGeneration = 0;
  bool _needsReload = true;
  bool _disposed = false;

  bool get isReady => _sources.isNotEmpty && !_disposed;

  Future<void> setCustomSounds(SimaiCustomJudgementSounds customSounds) {
    if (_disposed || _customSounds == customSounds) {
      return Future<void>.value();
    }
    _customSounds = customSounds;
    _needsReload = true;
    _loadGeneration++;
    _loadingTask = null;
    return ensureLoaded();
  }

  Future<void> ensureLoaded() {
    if (_disposed) return Future<void>.value();
    if (!_needsReload &&
        _sources.length == SimaiJudgementSoundKind.values.length) {
      return Future<void>.value();
    }
    return _loadingTask ??= _doLoad();
  }

  Future<void> _doLoad() async {
    final int generation = ++_loadGeneration;
    final SimaiCustomJudgementSounds targetCustom = _customSounds;
    try {
      await ensureSoLoudInitialized(_soloud);
      if (_disposed || generation != _loadGeneration) return;
      final loaded =
          await Future.wait<MapEntry<SimaiJudgementSoundKind, AudioSource?>>(
            SimaiJudgementSoundKind.values.map((kind) async {
              final customPath = targetCustom.pathFor(kind);
              if (!kIsWeb &&
                  customPath != null &&
                  customPath.isNotEmpty &&
                  customFileExists(customPath)) {
                try {
                  final customSrc = await SoLoudSourcePool.acquireFile(
                    customPath,
                    _soloud,
                  );
                  return MapEntry(kind, customSrc);
                } catch (e) {
                  debugPrint(
                    'JudgeSFX: 加载自定义 ${kind.name}($customPath) 失败，回退内置: $e',
                  );
                }
              }
              try {
                final src = await SoLoudSourcePool.acquireAsset(
                  kind.assetPath,
                  _soloud,
                );
                return MapEntry(kind, src);
              } catch (e) {
                debugPrint('JudgeSFX: 加载 ${kind.assetPath} 失败: $e');
                return MapEntry(kind, null);
              }
            }),
          );
      if (_disposed || generation != _loadGeneration) {
        for (final entry in loaded) {
          final src = entry.value;
          if (src != null) {
            unawaited(SoLoudSourcePool.release(src, _soloud));
          }
        }
        return;
      }
      for (final entry in loaded) {
        final src = entry.value;
        if (src == null) continue;
        final prev = _sources[entry.key];
        if (prev != null && !identical(prev, src)) {
          unawaited(SoLoudSourcePool.release(prev, _soloud));
        }
        _sources[entry.key] = src;
      }
      if (_customSounds == targetCustom) {
        _needsReload = false;
      }
    } catch (e) {
      debugPrint('JudgeSFX: SoLoud 初始化失败: $e');
    } finally {
      if (generation == _loadGeneration) {
        _loadingTask = null;
      }
    }
  }

  void playImmediate(
    SimaiJudgementSoundKind kind, {
    required double volume,
    required int nowUs,
  }) {
    if (_disposed || volume <= 0 || !_soloud.isInitialized) return;
    final src = _sources[kind];
    if (src == null) return;
    final int windowStart = nowUs - _overlapWindowUs;
    while (_recentPlayTimesUs.isNotEmpty &&
        _recentPlayTimesUs.first < windowStart) {
      _recentPlayTimesUs.removeFirst();
    }
    _recentPlayTimesUs.addLast(nowUs);
    final double gain = _voiceGain(
      _recentPlayTimesUs.length,
      baseGain: volume.clamp(0.0, simaiMaxHitSoundVolume).toDouble() * 0.82,
    );
    _playVoice(src, gain: gain);
  }

  void playScheduled(
    SimaiJudgementSoundKind kind, {
    required double volume,
    required int overlap,
    Duration? scheduledAt,
  }) {
    if (_disposed || volume <= 0 || !_soloud.isInitialized) return;
    final src = _sources[kind];
    if (src == null) return;
    final double gain = _voiceGain(
      overlap,
      baseGain: volume.clamp(0.0, simaiMaxHitSoundVolume).toDouble() * 0.82,
    );
    _playVoice(src, gain: gain, scheduledAt: scheduledAt);
  }

  static double _voiceGain(int voiceCount, {required double baseGain}) {
    if (voiceCount <= 0) return 0.0;
    return baseGain / math.sqrt(voiceCount);
  }

  void _playVoice(
    AudioSource src, {
    required double gain,
    Duration? scheduledAt,
  }) {
    if (gain <= 0.0) return;
    if (_voices.length >= _maxVoices) {
      _voices.removeWhere((h) => !_soloud.getIsValidVoiceHandle(h));
    }
    while (_voices.length >= _maxVoices) {
      final oldest = _voices.removeFirst();
      if (_soloud.getIsValidVoiceHandle(oldest)) {
        unawaited(_soloud.stop(oldest));
      }
    }
    SoundHandle handle;
    try {
      handle = scheduledAt != null
          ? _soloud.playScheduled(src, scheduledAt, volume: gain)
          : _soloud.play(src, volume: gain);
    } catch (_) {
      try {
        handle = _soloud.play(src, volume: gain);
      } catch (_) {
        return;
      }
    }
    if (!handle.isError) {
      _voices.addLast(handle);
    }
  }

  void stopVoices() {
    _recentPlayTimesUs.clear();
    if (_voices.isEmpty || !_soloud.isInitialized) {
      _voices.clear();
      return;
    }
    for (final handle in _voices) {
      if (_soloud.getIsValidVoiceHandle(handle)) {
        unawaited(_soloud.stop(handle));
      }
    }
    _voices.clear();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _loadGeneration++;
    stopVoices();
    final entries = _sources.values.toList(growable: false);
    _sources.clear();
    for (final src in entries) {
      unawaited(SoLoudSourcePool.release(src, _soloud));
    }
  }
}

/// 在设置抽屉中试听指定判定音效（优先播放自定义文件，失败时回退内置机台音效）。
Future<void> previewSimaiJudgementSound(
  SimaiJudgementSoundKind kind, {
  double volume = 1.0,
  String? customFilePath,
}) async {
  final soloud = SoLoud.instance;
  await ensureSoLoudInitialized(soloud);
  AudioSource? source;
  final trimmed = customFilePath?.trim();
  if (!kIsWeb &&
      trimmed != null &&
      trimmed.isNotEmpty &&
      customFileExists(trimmed)) {
    try {
      source = await SoLoudSourcePool.acquireFile(trimmed, soloud);
    } catch (e) {
      debugPrint('JudgeSFX: 自定义试听加载失败，回退默认 ($trimmed): $e');
    }
  }
  source ??= await SoLoudSourcePool.acquireAsset(kind.assetPath, soloud);
  final acquiredSource = source;
  try {
    soloud.play(
      acquiredSource,
      volume: (volume.clamp(0.0, simaiMaxHitSoundVolume).toDouble() * 0.82),
    );
  } finally {
    Future<void>.delayed(const Duration(seconds: 2), () {
      unawaited(SoLoudSourcePool.release(acquiredSource, soloud));
    });
  }
}
