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
    required List<int> hitEventTimesUs,
  }) async => _unsupported();

  @override
  Future<bool> isSupported({required int width, required int height}) async =>
      false;

  @override
  Future<SimaiNativeVideoSession> start({
    required int width,
    required int height,
    required int videoBitrate,
    required String? outputPath,
    required String? audioAsset,
    required String? audioFilePath,
    required String audioMode,
    String? pvVideoPath,
    List<int>? pvRect,
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
