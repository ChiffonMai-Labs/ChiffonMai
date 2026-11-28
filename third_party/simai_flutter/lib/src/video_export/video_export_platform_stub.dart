import 'dart:typed_data';

import 'video_export_platform.dart';

SimaiNativeVideoExportPlatform createNativeVideoExportPlatform() =>
    const _UnsupportedVideoExportPlatform();

class _UnsupportedVideoExportPlatform
    implements SimaiNativeVideoExportPlatform {
  const _UnsupportedVideoExportPlatform();

  Never _unsupported() => throw UnsupportedError(
    'Simai video export is supported only on Android and iOS.',
  );

  @override
  Future<void> cancel(int sessionId) async {}

  @override
  void copyFrameToSlot({
    required SimaiNativeVideoSession session,
    required int slot,
    required Uint8List rgbaBytes,
  }) => _unsupported();

  @override
  Future<SimaiNativeVideoFinishResult> finish({
    required int sessionId,
    required int durationUs,
    required int timelineStartUs,
    required int musicOffsetUs,
    required double musicVolume,
    double hitSoundVolume = 2.0,
    required List<int> hitEventTimesUs,
    List<int> judgementEventTimesUs = const <int>[],
    List<String> judgementEventKinds = const <String>[],
    List<double> judgementEventVolumes = const <double>[],
  }) async => _unsupported();

  @override
  Future<bool> isSupported({
    required int width,
    required int height,
    int fps = 60,
  }) async => false;

  @override
  Future<SimaiNativeVideoSession> start({
    required int width,
    required int height,
    int fps = 60,
    required int videoBitrate,
    required String? outputPath,
    required String? audioAsset,
    required String? audioFilePath,
    String? hitSoundFilePath,
    Map<String, String>? judgementSoundAssetPaths,
    Map<String, String>? judgementSoundFilePaths,
    required String audioMode,
    String? pvVideoPath,
    List<int>? pvRect,
    bool saveToGallery = false,
    String? displayName,
  }) async => _unsupported();

  @override
  Future<void> submitFrame({
    required int sessionId,
    required int slot,
    required int presentationTimeUs,
    int? pvTimeUs,
  }) async => _unsupported();

  @override
  Future<void> validateStorage({
    required int sessionId,
    required int durationUs,
  }) async => _unsupported();

  @override
  Future<String?> saveToGallery(String path) async => _unsupported();

  @override
  Future<void> shareVideo({required String path, String? text}) async =>
      _unsupported();
}
