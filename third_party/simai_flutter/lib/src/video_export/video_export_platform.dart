import 'dart:typed_data';

import 'video_export_platform_stub.dart'
    if (dart.library.io) 'video_export_platform_io.dart';

abstract class SimaiNativeVideoExportPlatform {
  static SimaiNativeVideoExportPlatform get instance =>
      createNativeVideoExportPlatform();

  Future<bool> isSupported({
    required int width,
    required int height,
    int fps = 60,
  });

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
  });

  Future<void> submitFrame({
    required int sessionId,
    required int slot,
    required int presentationTimeUs,
    int? pvTimeUs,
  });

  Future<void> validateStorage({
    required int sessionId,
    required int durationUs,
  });

  void copyFrameToSlot({
    required SimaiNativeVideoSession session,
    required int slot,
    required Uint8List rgbaBytes,
  });

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
  });

  Future<void> cancel(int sessionId);

  /// Copies an exported MP4 into the platform media library.
  ///
  /// Permission requests are intentionally left to the host application.
  /// Returns the platform asset/content identifier when available.
  /// Deletes [path] after the media-library copy succeeds.
  Future<String?> saveToGallery(String path);

  /// Opens the platform share sheet for an exported MP4 and then deletes
  /// [path]. Platforms may retain a separate temporary sharing copy.
  Future<void> shareVideo({required String path, String? text});
}

class SimaiNativeVideoSession {
  final int id;
  final List<int> bufferAddresses;
  final int bufferLength;
  final int audioDurationUs;
  final int hitSoundDurationUs;
  final String outputPath;

  const SimaiNativeVideoSession({
    required this.id,
    required this.bufferAddresses,
    required this.bufferLength,
    required this.audioDurationUs,
    this.hitSoundDurationUs = 100000,
    required this.outputPath,
  });
}

class SimaiNativeVideoFinishResult {
  final String outputPath;
  final int fileSizeBytes;
  final bool savedToGallery;
  final String? galleryUri;

  const SimaiNativeVideoFinishResult({
    required this.outputPath,
    required this.fileSizeBytes,
    this.savedToGallery = false,
    this.galleryUri,
  });
}
