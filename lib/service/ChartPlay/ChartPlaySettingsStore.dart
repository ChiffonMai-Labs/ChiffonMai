import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simai_flutter/simai_flutter.dart';

/// 播放前“加载音频”选项的记忆化。
///
/// 这是进入播放页前的资源选择，不属于播放器侧边栏设置，因此单独存储，
/// 避免在创建控制器前读取整份设置时产生耦合。
class ChartPlayAudioPreference {
  static const String _key = 'chart_play_load_audio';
  static bool? _cached;

  static Future<bool> load() async {
    if (_cached != null) return _cached!;
    try {
      final prefs = await SharedPreferences.getInstance();
      // 若读取落盘期间用户已通过 save() 改过值，则保留最新内存值。
      return _cached ??= prefs.getBool(_key) ?? true;
    } catch (_) {
      return _cached ?? true;
    }
  }

  static Future<void> save(bool value) async {
    _cached = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      // 落盘始终写入最新内存值，防止快点切换时旧写入覆盖新值。
      await prefs.setBool(_key, _cached ?? value);
    } catch (e) {
      debugPrint('[ChartPlayAudioPreference] 保存失败: $e');
    }
  }
}

/// 播放前“加载 PV 背景”选项的记忆化。
class ChartPlayPvPreference {
  static const String _key = 'chart_play_load_pv';
  static bool? _cached;

  static Future<bool> load() async {
    if (_cached != null) return _cached!;
    try {
      final prefs = await SharedPreferences.getInstance();
      // 若读取落盘期间用户已通过 save() 改过值，则保留最新内存值。
      return _cached ??= prefs.getBool(_key) ?? true;
    } catch (_) {
      return _cached ?? true;
    }
  }

  static Future<void> save(bool value) async {
    _cached = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      // 落盘始终写入最新内存值，防止快点切换时旧写入覆盖新值。
      await prefs.setBool(_key, _cached ?? value);
    } catch (e) {
      debugPrint('[ChartPlayPvPreference] 保存失败: $e');
    }
  }
}

/// 谱面播放页侧边栏设置的一份快照。
///
/// 字段与 `SimaiPlayerController` 暴露的 setter 一一对应；
/// 以后新增设置项时，记得同时改 [capture]、[apply] 和 [toJson]/[fromJson] 三处。
@immutable
class ChartPlaySettings {
  // ---- 显示设置 ----
  final SimaiMirrorMode mirrorMode;
  final SimaiBackgroundMode backgroundMode;
  final double backgroundOpacity;
  final double speed;
  final double touchSpeed;
  final double slideDisplayTiming;
  final SimaiAutoPlayMode autoPlayMode;
  final double playbackRate;
  final bool rotateSlideStar;
  final bool pinkSlideStar;
  final bool standardBreakSlide;
  final bool showApproachLine;
  final bool showHitEffects;
  final SimaiHitEffectStyle hitEffectStyle;
  final bool showJudgementDisplay;
  final SimaiJudgementDisplayMode judgementDisplayMode;
  final SimaiNoteStyle noteStyle;
  final SimaiNoteStyle holdStyle;
  final SimaiCenterDisplayMode centerDisplayMode;
  final SimaiCenterDisplayMode topRightDisplayMode;
  final bool showAchievementRate;
  final bool highlightExNotes;
  final bool showCornerInfo;
  final bool showDetailedPerformanceInfo;
  final bool metronomeEnabled;
  final double metronomeSpeed;

  // ---- 音频设置 ----
  final bool hitSoundEnabled;
  final bool metronomeSoundEnabled;
  final double musicVolume;
  final double hitSoundVolume;
  final int musicOffsetMs;
  final int hitSoundOffsetMs;
  final int pvOffsetMs;

  /// 首次进入谱面播放页时应用的默认设置。
  const ChartPlaySettings({
    this.mirrorMode = SimaiMirrorMode.none,
    this.backgroundMode = SimaiBackgroundMode.judgeLine,
    // 与 SimaiGame.defaultBackgroundOpacity 保持一致。
    this.backgroundOpacity = 0.35,
    this.speed = 8.0,
    this.touchSpeed = 8.0,
    this.slideDisplayTiming = 0.0,
    this.autoPlayMode = SimaiAutoPlayMode.allCriticalPerfect,
    this.playbackRate = 1.0,
    this.rotateSlideStar = true,
    this.pinkSlideStar = false,
    this.standardBreakSlide = false,
    this.showApproachLine = true,
    this.showHitEffects = true,
    this.hitEffectStyle = SimaiHitEffectStyle.ring,
    this.showJudgementDisplay = false,
    this.judgementDisplayMode = SimaiJudgementDisplayMode.twoB,
    this.noteStyle = SimaiNoteStyle.arcade,
    this.holdStyle = SimaiNoteStyle.arcade,
    this.centerDisplayMode = SimaiCenterDisplayMode.achievementAdd,
    this.topRightDisplayMode = SimaiCenterDisplayMode.combo,
    this.showAchievementRate = true,
    this.highlightExNotes = true,
    this.showCornerInfo = true,
    this.showDetailedPerformanceInfo = false,
    this.metronomeEnabled = true,
    this.metronomeSpeed = 1.0,
    this.hitSoundEnabled = true,
    this.metronomeSoundEnabled = false,
    this.musicVolume = 0.5,
    this.hitSoundVolume = 2.0,
    this.musicOffsetMs = 0,
    this.hitSoundOffsetMs = 0,
    this.pvOffsetMs = 0,
  });

  /// 读取控制器当前的全部设置。
  factory ChartPlaySettings.capture(
    SimaiPlayerController c, {
    bool metronomeEnabled = true,
    double metronomeSpeed = 1.0,
    bool metronomeSoundEnabled = false,
  }) {
    final safeMetronomeSpeed = metronomeSpeed.isFinite
        ? metronomeSpeed.clamp(0.5, 3.0).toDouble()
        : 1.0;
    return ChartPlaySettings(
      mirrorMode: c.mirrorMode,
      backgroundMode: c.backgroundMode,
      backgroundOpacity: c.backgroundOpacity,
      speed: c.speed,
      touchSpeed: c.touchSpeed,
      slideDisplayTiming: c.slideDisplayTiming,
      autoPlayMode: c.autoPlayMode,
      playbackRate: c.playbackRate,
      rotateSlideStar: c.rotateSlideStar,
      pinkSlideStar: c.pinkSlideStar,
      standardBreakSlide: c.standardBreakSlide,
      showApproachLine: c.showApproachLine,
      showHitEffects: c.showHitEffects,
      hitEffectStyle: c.hitEffectStyle,
      showJudgementDisplay: c.showJudgementDisplay,
      judgementDisplayMode: c.judgementDisplayMode,
      noteStyle: c.noteStyle,
      holdStyle: SimaiNoteStyle.normalizeForHold(c.holdStyle),
      centerDisplayMode: c.centerDisplayMode,
      topRightDisplayMode: c.topRightDisplayMode,
      showAchievementRate: c.showAchievementRate,
      highlightExNotes: c.highlightExNotes,
      showCornerInfo: c.showCornerInfo,
      showDetailedPerformanceInfo: c.showDetailedPerformanceInfo,
      metronomeEnabled: metronomeEnabled,
      metronomeSpeed: safeMetronomeSpeed,
      hitSoundEnabled: c.hitSoundEnabled,
      metronomeSoundEnabled: metronomeSoundEnabled,
      musicVolume: c.musicVolume,
      hitSoundVolume: c.hitSoundVolume,
      musicOffsetMs: c.musicOffsetMs,
      hitSoundOffsetMs: c.hitSoundOffsetMs,
      pvOffsetMs: c.pvOffsetMs,
    );
  }

  /// 把这份设置写回控制器。
  ///
  /// 控制器的 setter 自带「值没变就直接 return」，所以这里整体套用不会产生多余的重建。
  void apply(SimaiPlayerController c) {
    c.mirrorMode = mirrorMode;
    c.backgroundMode = backgroundMode;
    c.backgroundOpacity = backgroundOpacity;
    c.speed = speed;
    c.touchSpeed = touchSpeed;
    c.slideDisplayTiming = slideDisplayTiming;
    c.autoPlayMode = autoPlayMode;
    c.playbackRate = playbackRate;
    c.rotateSlideStar = rotateSlideStar;
    c.pinkSlideStar = pinkSlideStar;
    c.standardBreakSlide = standardBreakSlide;
    c.showApproachLine = showApproachLine;
    c.showHitEffects = showHitEffects;
    c.hitEffectStyle = hitEffectStyle;
    c.showJudgementDisplay = showJudgementDisplay;
    c.judgementDisplayMode = judgementDisplayMode;
    c.noteStyle = noteStyle;
    c.holdStyle = SimaiNoteStyle.normalizeForHold(holdStyle);
    c.centerDisplayMode = centerDisplayMode;
    c.topRightDisplayMode = topRightDisplayMode;
    c.showAchievementRate = showAchievementRate;
    c.highlightExNotes = highlightExNotes;
    c.showCornerInfo = showCornerInfo;
    c.showDetailedPerformanceInfo = showDetailedPerformanceInfo;
    c.hitSoundEnabled = hitSoundEnabled;
    c.musicVolume = musicVolume;
    c.hitSoundVolume = hitSoundVolume;
    c.musicOffsetMs = musicOffsetMs;
    c.hitSoundOffsetMs = hitSoundOffsetMs;
    c.pvOffsetMs = pvOffsetMs;
  }

  Map<String, dynamic> toJson() => {
        'mirrorMode': mirrorMode.name,
        'backgroundMode': backgroundMode.name,
        'backgroundOpacity': backgroundOpacity,
        'speed': speed,
        'touchSpeed': touchSpeed,
        'slideDisplayTiming': slideDisplayTiming,
        'autoPlayMode': autoPlayMode.name,
        'playbackRate': playbackRate,
        'rotateSlideStar': rotateSlideStar,
        'pinkSlideStar': pinkSlideStar,
        'standardBreakSlide': standardBreakSlide,
        'showApproachLine': showApproachLine,
        'showHitEffects': showHitEffects,
        'hitEffectStyle': hitEffectStyle.name,
        'showJudgementDisplay': showJudgementDisplay,
        'judgementDisplayMode': judgementDisplayMode.name,
        'noteStyle': noteStyle.name,
        'holdStyle': SimaiNoteStyle.normalizeForHold(holdStyle).name,
        'centerDisplayMode': centerDisplayMode.name,
        'topRightDisplayMode': topRightDisplayMode.name,
        'showAchievementRate': showAchievementRate,
        'highlightExNotes': highlightExNotes,
        'showCornerInfo': showCornerInfo,
        'showDetailedPerformanceInfo': showDetailedPerformanceInfo,
        'metronomeEnabled': metronomeEnabled,
        'metronomeSpeed': metronomeSpeed,
        'hitSoundEnabled': hitSoundEnabled,
        'metronomeSoundEnabled': metronomeSoundEnabled,
        'musicVolume': musicVolume,
        'hitSoundVolume': hitSoundVolume,
        'musicOffsetMs': musicOffsetMs,
        'hitSoundOffsetMs': hitSoundOffsetMs,
        'pvOffsetMs': pvOffsetMs,
      };

  /// 从 JSON 还原。
  ///
  /// 单个字段坏掉不影响其它字段：枚举认不出来就退回默认值，
  /// 数值越界会按侧边栏滑块的区间夹回去（防止手改 prefs 后出现非法状态）。
  factory ChartPlaySettings.fromJson(Map<String, dynamic> json) {
    const fallback = ChartPlaySettings();
    final parsedSpeed = NoteMotion.parseSpeed(
      json['speed'],
      fallback: fallback.speed,
    );
    final parsedNoteStyle = SimaiNoteStyle.fromName(
      json['noteStyle'],
      fallback: fallback.noteStyle,
    );
    return ChartPlaySettings(
      mirrorMode: _enumByName(
          SimaiMirrorMode.values, json['mirrorMode'], fallback.mirrorMode),
      backgroundMode: _enumByName(SimaiBackgroundMode.values,
          json['backgroundMode'], fallback.backgroundMode),
      backgroundOpacity: _clampDouble(
          json['backgroundOpacity'], 0.0, 1.0, fallback.backgroundOpacity),
      speed: parsedSpeed,
      touchSpeed: NoteMotion.parseSpeed(
        json['touchSpeed'],
        fallback: parsedSpeed,
      ),
      slideDisplayTiming: NoteMotion.normalizeSlideDisplayTiming(
        json['slideDisplayTiming'] is num
            ? (json['slideDisplayTiming'] as num).toDouble()
            : fallback.slideDisplayTiming,
        fallback: fallback.slideDisplayTiming,
      ),
      autoPlayMode: SimaiAutoPlayMode.fromName(
        json['autoPlayMode'],
        fallback: fallback.autoPlayMode,
      ),
      playbackRate:
          _clampDouble(json['playbackRate'], 0.1, 3.0, fallback.playbackRate),
      rotateSlideStar: _bool(json['rotateSlideStar'], fallback.rotateSlideStar),
      pinkSlideStar: _bool(json['pinkSlideStar'], fallback.pinkSlideStar),
      standardBreakSlide:
          _bool(json['standardBreakSlide'], fallback.standardBreakSlide),
      showApproachLine:
          _bool(json['showApproachLine'], fallback.showApproachLine),
      showHitEffects: _bool(json['showHitEffects'], fallback.showHitEffects),
      hitEffectStyle: SimaiHitEffectStyle.fromName(
        json['hitEffectStyle'],
        fallback: fallback.hitEffectStyle,
      ),
      showJudgementDisplay:
          _bool(json['showJudgementDisplay'], fallback.showJudgementDisplay),
      judgementDisplayMode: _enumByName(
        SimaiJudgementDisplayMode.values,
        json['judgementDisplayMode'],
        fallback.judgementDisplayMode,
      ),
      noteStyle: parsedNoteStyle,
      holdStyle: SimaiNoteStyle.fromHoldName(
        json['holdStyle'],
        fallback: SimaiNoteStyle.normalizeForHold(parsedNoteStyle),
      ),
      centerDisplayMode: SimaiCenterDisplayMode.fromNameOrLegacy(
        json['centerDisplayMode'],
        fallback: fallback.centerDisplayMode,
      ),
      topRightDisplayMode: SimaiCenterDisplayMode.fromNameOrLegacy(
        json['topRightDisplayMode'],
        fallback: fallback.topRightDisplayMode,
      ),
      showAchievementRate:
          _bool(json['showAchievementRate'], fallback.showAchievementRate),
      highlightExNotes:
          _bool(json['highlightExNotes'], fallback.highlightExNotes),
      showCornerInfo: _bool(json['showCornerInfo'], fallback.showCornerInfo),
      showDetailedPerformanceInfo: _bool(json['showDetailedPerformanceInfo'],
          fallback.showDetailedPerformanceInfo),
      metronomeEnabled:
          _bool(json['metronomeEnabled'], fallback.metronomeEnabled),
      metronomeSpeed: _clampDouble(
          json['metronomeSpeed'], 0.5, 3.0, fallback.metronomeSpeed),
      hitSoundEnabled: _bool(json['hitSoundEnabled'], fallback.hitSoundEnabled),
      metronomeSoundEnabled:
          _bool(json['metronomeSoundEnabled'], fallback.metronomeSoundEnabled),
      musicVolume:
          _clampDouble(json['musicVolume'], 0.0, 1.0, fallback.musicVolume),
      hitSoundVolume: _clampDouble(json['hitSoundVolume'], 0.0,
          simaiMaxHitSoundVolume, fallback.hitSoundVolume),
      musicOffsetMs:
          _clampInt(json['musicOffsetMs'], -2000, 2000, fallback.musicOffsetMs),
      hitSoundOffsetMs: _clampInt(
          json['hitSoundOffsetMs'], -200, 200, fallback.hitSoundOffsetMs),
      pvOffsetMs:
          _clampInt(json['pvOffsetMs'], -2000, 2000, fallback.pvOffsetMs),
    );
  }

  static T _enumByName<T extends Enum>(
      List<T> values, Object? raw, T fallback) {
    if (raw is! String) return fallback;
    for (final value in values) {
      if (value.name == raw) return value;
    }
    return fallback;
  }

  static bool _bool(Object? raw, bool fallback) => raw is bool ? raw : fallback;

  static double _clampDouble(
      Object? raw, double min, double max, double fallback) {
    if (raw is! num) return fallback;
    final value = raw.toDouble();
    if (value.isNaN || value.isInfinite) return fallback;
    return value.clamp(min, max).toDouble();
  }

  static int _clampInt(Object? raw, int min, int max, int fallback) {
    if (raw is! num) return fallback;
    return raw.toInt().clamp(min, max);
  }
}

/// 侧边栏设置的本地持久化。
///
/// 播放页每次进入时套用上次保存的值，用户改动后延迟落盘（防抖），
/// 退出页面或 App 切后台时立刻补写一次。
class ChartPlaySettingsStore {
  static final ChartPlaySettingsStore _instance =
      ChartPlaySettingsStore._internal();
  factory ChartPlaySettingsStore() => _instance;
  ChartPlaySettingsStore._internal();

  static const String _key = 'chart_play_settings_v1';

  ChartPlaySettings _settings = const ChartPlaySettings();
  bool _loaded = false;
  Future<ChartPlaySettings>? _loading;

  /// 当前缓存（未加载时是默认值）。
  ChartPlaySettings get settings => _settings;

  bool get isLoaded => _loaded;

  /// 从本地读取。可重复调用，并发调用会复用同一个 Future。
  Future<ChartPlaySettings> load() {
    if (_loaded) return Future.value(_settings);
    return _loading ??= _doLoad();
  }

  Future<ChartPlaySettings> _doLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          _settings = ChartPlaySettings.fromJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('[ChartPlaySettings] 读取失败，使用默认设置: $e');
      _settings = const ChartPlaySettings();
    }
    _loaded = true;
    _loading = null;
    debugPrint('[ChartPlaySettings] 已加载设置: speed=${_settings.speed} '
        'rate=${_settings.playbackRate} mirror=${_settings.mirrorMode.name}');
    return _settings;
  }

  /// 强制重新从本地读取（用于「导入备份」后让新设置立刻生效）。
  ///
  /// 与 [load] 的区别：**不做 `_loaded` 短路**。[load] 只读一次并长期缓存，
  /// 恢复备份后内存里还是旧设置；而 [persist] 是整体写回，用户下一次改侧边栏
  /// 就会把恢复的内容盖掉，所以必须先失效再重读。
  Future<ChartPlaySettings> reload() {
    _loaded = false;
    _loading = null;
    return load();
  }

  /// 把当前设置套用到控制器。
  void applyTo(SimaiPlayerController controller) {
    _settings.apply(controller);
  }

  /// 只更新内存中的当前值，不写盘。
  ///
  /// 配合防抖使用：值一改就立刻记下来（这样中途重建控制器也能拿到最新的），
  /// 写盘则推迟到用户停止操作之后。
  void remember(ChartPlaySettings settings) {
    _settings = settings;
    _loaded = true;
  }

  /// 把内存中的当前值写盘。
  Future<void> persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(_settings.toJson()));
    } catch (e) {
      debugPrint('[ChartPlaySettings] 保存失败: $e');
    }
  }

  /// 读取控制器当前值并落盘。控制器为 null 时忽略。
  Future<void> saveFrom(SimaiPlayerController? controller) async {
    if (controller == null) return;
    await save(ChartPlaySettings.capture(
      controller,
      metronomeEnabled: _settings.metronomeEnabled,
      metronomeSpeed: _settings.metronomeSpeed,
      metronomeSoundEnabled: _settings.metronomeSoundEnabled,
    ));
  }

  Future<void> save(ChartPlaySettings settings) async {
    remember(settings);
    await persist();
  }

  /// 清空，恢复默认。给设置页的「重置」留的口子。
  Future<void> reset() async {
    _settings = const ChartPlaySettings();
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[ChartPlaySettings] 重置失败: $e');
    }
  }
}

/// 视频导出页配置的本地持久化。
///
/// 首次未保存过时 [savedSettings] 返回 null，使导出页继续沿用当前播放器快照；
/// 一旦用户在导出页调整任意选项或开始导出，后续再次打开均恢复上次配置。
class ChartVideoExportSettingsStore {
  static final ChartVideoExportSettingsStore _instance =
      ChartVideoExportSettingsStore._internal();
  factory ChartVideoExportSettingsStore() => _instance;
  ChartVideoExportSettingsStore._internal();

  static const String _key = 'chart_video_export_settings_v1';

  SimaiVideoExportSettings? _settings;
  bool _loaded = false;
  Future<SimaiVideoExportSettings?>? _loading;

  SimaiVideoExportSettings? get savedSettings => _settings;

  bool get isLoaded => _loaded;

  Future<SimaiVideoExportSettings?> load() {
    if (_loaded) return Future.value(_settings);
    return _loading ??= _doLoad();
  }

  Future<SimaiVideoExportSettings?> _doLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          _settings = _fromJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('[ChartVideoExportSettings] 读取失败，使用默认继承: $e');
      _settings = null;
    }
    _loaded = true;
    _loading = null;
    return _settings;
  }

  Future<SimaiVideoExportSettings?> reload() {
    _loaded = false;
    _loading = null;
    _settings = null;
    return load();
  }

  /// 同步记入内存，避免防抖写盘前退出或重建丢失最新修改。
  void remember(SimaiVideoExportSettings settings) {
    _settings = settings;
    _loaded = true;
  }

  Future<void> persist() async {
    final current = _settings;
    if (current == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(_toJson(current)));
    } catch (e) {
      debugPrint('[ChartVideoExportSettings] 保存失败: $e');
    }
  }

  Future<void> saveNow() => persist();

  Future<void> reset() async {
    _settings = null;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[ChartVideoExportSettings] 重置失败: $e');
    }
  }

  static Map<String, dynamic> _toJson(SimaiVideoExportSettings s) => {
        'quality': s.quality.name,
        'frameRate': s.frameRate.name,
        'showHeader': s.showHeader,
        'includeMusic': s.includeMusic,
        'mirrorMode': s.mirrorMode.name,
        'backgroundMode': s.backgroundMode.name,
        'speed': s.speed,
        'touchSpeed': s.touchSpeed,
        'slideDisplayTiming': s.slideDisplayTiming,
        'autoPlayMode': s.autoPlayMode.name,
        'rotateSlideStar': s.rotateSlideStar,
        'pinkSlideStar': s.pinkSlideStar,
        'standardBreakSlide': s.standardBreakSlide,
        'showApproachLine': s.showApproachLine,
        'showHitEffects': s.showHitEffects,
        'hitEffectStyle': s.hitEffectStyle.name,
        'showJudgementDisplay': s.showJudgementDisplay,
        'judgementDisplayMode': s.judgementDisplayMode.name,
        'noteStyle': s.noteStyle.name,
        'holdStyle': SimaiNoteStyle.normalizeForHold(s.holdStyle).name,
        'centerDisplayMode': s.centerDisplayMode.name,
        'topRightDisplayMode': s.topRightDisplayMode.name,
        'showAchievementRate': s.showAchievementRate,
        'highlightExNotes': s.highlightExNotes,
        'showCornerInfo': s.showCornerInfo,
        'showDetailedPerformanceInfo': s.showDetailedPerformanceInfo,
        'hitSoundEnabled': s.hitSoundEnabled,
        'musicVolume': s.musicVolume,
        'hitSoundVolume': s.hitSoundVolume,
        'musicOffsetMs': s.musicOffsetMs,
        'hitSoundOffsetMs': s.hitSoundOffsetMs,
      };

  static SimaiVideoExportSettings _fromJson(Map<String, dynamic> json) {
    const fallback = SimaiVideoExportSettings();
    final parsedSpeed = NoteMotion.parseSpeed(
      json['speed'],
      fallback: fallback.speed,
    );
    final parsedNoteStyle = SimaiNoteStyle.fromName(
      json['noteStyle'],
      fallback: fallback.noteStyle,
    );
    return SimaiVideoExportSettings(
      quality: ChartPlaySettings._enumByName(
          SimaiVideoQuality.values, json['quality'], fallback.quality),
      frameRate: ChartPlaySettings._enumByName(
          SimaiVideoFrameRate.values, json['frameRate'], fallback.frameRate),
      showHeader:
          ChartPlaySettings._bool(json['showHeader'], fallback.showHeader),
      includeMusic:
          ChartPlaySettings._bool(json['includeMusic'], fallback.includeMusic),
      mirrorMode: ChartPlaySettings._enumByName(
          SimaiMirrorMode.values, json['mirrorMode'], fallback.mirrorMode),
      backgroundMode: ChartPlaySettings._enumByName(SimaiBackgroundMode.values,
          json['backgroundMode'], fallback.backgroundMode),
      speed: parsedSpeed,
      touchSpeed: NoteMotion.parseSpeed(
        json['touchSpeed'],
        fallback: parsedSpeed,
      ),
      slideDisplayTiming: NoteMotion.normalizeSlideDisplayTiming(
        json['slideDisplayTiming'] is num
            ? (json['slideDisplayTiming'] as num).toDouble()
            : fallback.slideDisplayTiming,
        fallback: fallback.slideDisplayTiming,
      ),
      autoPlayMode: SimaiAutoPlayMode.fromName(
        json['autoPlayMode'],
        fallback: fallback.autoPlayMode,
      ),
      rotateSlideStar: ChartPlaySettings._bool(
          json['rotateSlideStar'], fallback.rotateSlideStar),
      pinkSlideStar: ChartPlaySettings._bool(
          json['pinkSlideStar'], fallback.pinkSlideStar),
      standardBreakSlide: ChartPlaySettings._bool(
          json['standardBreakSlide'], fallback.standardBreakSlide),
      showApproachLine: ChartPlaySettings._bool(
          json['showApproachLine'], fallback.showApproachLine),
      showHitEffects: ChartPlaySettings._bool(
          json['showHitEffects'], fallback.showHitEffects),
      hitEffectStyle: SimaiHitEffectStyle.fromName(
        json['hitEffectStyle'],
        fallback: fallback.hitEffectStyle,
      ),
      showJudgementDisplay: ChartPlaySettings._bool(
          json['showJudgementDisplay'], fallback.showJudgementDisplay),
      judgementDisplayMode: ChartPlaySettings._enumByName(
        SimaiJudgementDisplayMode.values,
        json['judgementDisplayMode'],
        fallback.judgementDisplayMode,
      ),
      noteStyle: parsedNoteStyle,
      holdStyle: SimaiNoteStyle.fromHoldName(
        json['holdStyle'],
        fallback: SimaiNoteStyle.normalizeForHold(parsedNoteStyle),
      ),
      centerDisplayMode: SimaiCenterDisplayMode.fromNameOrLegacy(
        json['centerDisplayMode'],
        fallback: fallback.centerDisplayMode,
      ),
      topRightDisplayMode: SimaiCenterDisplayMode.fromNameOrLegacy(
        json['topRightDisplayMode'],
        fallback: fallback.topRightDisplayMode,
      ),
      showAchievementRate: ChartPlaySettings._bool(
          json['showAchievementRate'], fallback.showAchievementRate),
      highlightExNotes: ChartPlaySettings._bool(
          json['highlightExNotes'], fallback.highlightExNotes),
      showCornerInfo: ChartPlaySettings._bool(
          json['showCornerInfo'], fallback.showCornerInfo),
      showDetailedPerformanceInfo: ChartPlaySettings._bool(
          json['showDetailedPerformanceInfo'],
          fallback.showDetailedPerformanceInfo),
      hitSoundEnabled: ChartPlaySettings._bool(
          json['hitSoundEnabled'], fallback.hitSoundEnabled),
      musicVolume: ChartPlaySettings._clampDouble(
          json['musicVolume'], 0.0, 1.0, fallback.musicVolume),
      hitSoundVolume: ChartPlaySettings._clampDouble(json['hitSoundVolume'],
          0.0, simaiMaxHitSoundVolume, fallback.hitSoundVolume),
      musicOffsetMs: ChartPlaySettings._clampInt(
          json['musicOffsetMs'], -2000, 2000, fallback.musicOffsetMs),
      hitSoundOffsetMs: ChartPlaySettings._clampInt(
          json['hitSoundOffsetMs'], -200, 200, fallback.hitSoundOffsetMs),
    );
  }
}

/// 游玩模式配置的本地持久化。
///
/// 首次未保存过时 [savedSettings] 返回 null，使播放页从当前预览控制器继承核心参数；
/// 一旦用户在游玩设置或结算校准中修改任意选项，后续再次进入均恢复上次配置。
class ChartGameplaySettingsStore {
  static final ChartGameplaySettingsStore _instance =
      ChartGameplaySettingsStore._internal();
  factory ChartGameplaySettingsStore() => _instance;
  ChartGameplaySettingsStore._internal();

  static const String _key = 'chart_gameplay_settings_v1';

  SimaiGameplaySettings? _settings;
  bool _loaded = false;
  Future<SimaiGameplaySettings?>? _loading;
  int _loadGen = 0;

  SimaiGameplaySettings? get savedSettings => _settings;

  bool get isLoaded => _loaded;

  /// 从本地读取。可重复调用，并发调用会复用同一个 Future。
  Future<SimaiGameplaySettings?> load() {
    if (_loaded) return Future.value(_settings);
    return _loading ??= _doLoad();
  }

  Future<SimaiGameplaySettings?> _doLoad() async {
    final gen = ++_loadGen;
    SimaiGameplaySettings? loaded;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (gen != _loadGen) return _settings;
      final raw = prefs.getString(_key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map<String, dynamic>) {
          loaded = SimaiGameplaySettings.fromJson(decoded);
        } else if (decoded is Map) {
          loaded = SimaiGameplaySettings.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
    } catch (e) {
      if (gen != _loadGen) return _settings;
      debugPrint('[ChartGameplaySettings] 读取失败，使用默认继承: $e');
      loaded = null;
    }
    if (gen != _loadGen) return _settings;
    _settings = loaded;
    _loaded = true;
    _loading = null;
    return _settings;
  }

  /// 强制重新从本地读取（用于「导入备份」后让新设置立刻生效）。
  Future<SimaiGameplaySettings?> reload() {
    _loadGen++;
    _loaded = false;
    _loading = null;
    _settings = null;
    return load();
  }

  /// 同步记入内存，避免防抖写盘前退出或重建丢失最新修改。
  void remember(SimaiGameplaySettings settings) {
    _loadGen++;
    _settings = settings.normalized();
    _loaded = true;
    _loading = null;
  }

  /// 把内存中的当前值写盘。
  Future<void> persist() async {
    final current = _settings;
    if (current == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(current.toJson()));
    } catch (e) {
      debugPrint('[ChartGameplaySettings] 保存失败: $e');
    }
  }

  Future<void> saveNow() => persist();

  Future<void> reset() async {
    _loadGen++;
    _settings = null;
    _loaded = true;
    _loading = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[ChartGameplaySettings] 重置失败: $e');
    }
  }
}
