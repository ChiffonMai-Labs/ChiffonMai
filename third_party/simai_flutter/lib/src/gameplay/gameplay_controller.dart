import 'package:flutter/widgets.dart';

import '../structures/mai_chart.dart';
import 'gameplay_models.dart';
import 'gameplay_session.dart';

class SimaiGameplayController extends ChangeNotifier {
  SimaiGameplayController({
    required this.chart,
    this.audioAsset,
    this.audioFilePath,
    this.backgroundImageProvider,
    this.initialChartTime = 0.0,
    this.title,
    SimaiGameplaySettings settings = const SimaiGameplaySettings(),
  }) : assert(
         audioAsset == null || audioFilePath == null,
         'audioAsset and audioFilePath cannot both be set.',
       ),
       _settings = settings.normalized();

  final MaiChart chart;
  final String? audioAsset;
  final String? audioFilePath;
  final ImageProvider? backgroundImageProvider;
  final double initialChartTime;
  final String? title;

  // 延迟到首次读取 chartSummary 时再构建统计，避免进预览页时提前构造废弃的 SimaiGameplaySession。
  SimaiGameplayChartSummary? _summary;
  SimaiGameplaySettings _settings;
  SimaiGameplaySession? _activeSession;
  SimaiGameplayResult? _lastResult;
  bool _disposed = false;

  SimaiGameplaySettings get settings => _settings;
  SimaiGameplayChartSummary get chartSummary => _summary ??=
      SimaiGameplaySession(chart: chart, settings: _settings).summary;
  SimaiGameplaySession? get activeSession => _activeSession;
  SimaiGameplayResult? get lastResult => _lastResult;

  void updateSettings(SimaiGameplaySettings value) {
    final normalized = value.normalized();
    if (_settings == normalized) return;
    _settings = normalized;
    notifyListeners();
  }

  SimaiGameplaySession startSession() {
    final session = SimaiGameplaySession(chart: chart, settings: _settings);
    _summary ??= session.summary;
    _activeSession = session;
    _lastResult = null;
    notifyListeners();
    return session;
  }

  void completeSession(SimaiGameplaySession session) {
    if (!identical(_activeSession, session)) return;
    _lastResult = session.buildResult();
    _activeSession = null;
    notifyListeners();
  }

  void abandonSession(SimaiGameplaySession session) {
    if (!identical(_activeSession, session)) return;
    _activeSession = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _activeSession = null;
    super.dispose();
  }
}
