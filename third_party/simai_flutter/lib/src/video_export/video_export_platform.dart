import 'dart:typed_data';

import 'video_export_platform_stub.dart'
    if (dart.library.io) 'video_export_platform_io.dart';

abstract class SimaiNativeVideoExportPlatform {
  static SimaiNativeVideoExportPlatform get instance =>
      createNativeVideoExportPlatform();

  Future<bool> isSupported({required int width, required int height});

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
    required List<int> hitEventTimesUs,
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
  final String outputPath;

  const SimaiNativeVideoSession({
    required this.id,
    required this.bufferAddresses,
    required this.bufferLength,
    required this.audioDurationUs,
    required this.outputPath,
  });
}

class SimaiNativeVideoFinishResult {
  final String outputPath;
  final int fileSizeBytes;

  const SimaiNativeVideoFinishResult({
    required this.outputPath,
    required this.fileSizeBytes,
  });
}
