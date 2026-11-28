import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';

import 'video_export_platform.dart';

SimaiNativeVideoExportPlatform createNativeVideoExportPlatform() =>
    _MethodChannelVideoExportPlatform();

class _MethodChannelVideoExportPlatform
    implements SimaiNativeVideoExportPlatform {
  static const MethodChannel _channel = MethodChannel(
    'simai_flutter/video_export',
  );

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  void copyFrameToSlot({
    required SimaiNativeVideoSession session,
    required int slot,
    required Uint8List rgbaBytes,
  }) {
    if (slot < 0 || slot >= session.bufferAddresses.length) {
      throw RangeError.index(slot, session.bufferAddresses, 'slot');
    }
    if (rgbaBytes.lengthInBytes != session.bufferLength) {
      throw ArgumentError.value(
        rgbaBytes.lengthInBytes,
        'rgbaBytes.lengthInBytes',
        'Expected ${session.bufferLength} bytes',
      );
    }
    final target = Pointer<Uint8>.fromAddress(
      session.bufferAddresses[slot],
    ).asTypedList(session.bufferLength);
    target.setAll(0, rgbaBytes);
  }

  @override
  Future<bool> isSupported({
    required int width,
    required int height,
    int fps = 60,
  }) async {
    if (!_isMobile) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported', {
            'width': width,
            'height': height,
            'fps': fps,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

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
  }) async {
    if (!_isMobile) {
      throw UnsupportedError(
        'Simai video export is supported only on Android and iOS.',
      );
    }
    final result = await _channel.invokeMapMethod<String, Object?>('start', {
      'width': width,
      'height': height,
      'fps': fps,
      'videoBitrate': videoBitrate,
      'outputPath': outputPath,
      'audioAsset': audioAsset,
      'audioFilePath': audioFilePath,
      'hitSoundFilePath': hitSoundFilePath,
      'judgementSoundAssetPaths': judgementSoundAssetPaths,
      'judgementSoundFilePaths': judgementSoundFilePaths,
      'audioMode': audioMode,
      'pvVideoPath': pvVideoPath,
      'pvRect': pvRect,
      'saveToGallery': saveToGallery,
      'displayName': displayName,
    });
    if (result == null) {
      throw PlatformException(
        code: 'invalid_native_result',
        message: 'Native video exporter returned no session.',
      );
    }
    return SimaiNativeVideoSession(
      id: result['sessionId']! as int,
      bufferAddresses: (result['bufferAddresses']! as List<Object?>)
          .cast<int>(),
      bufferLength: result['bufferLength']! as int,
      audioDurationUs: result['audioDurationUs']! as int,
      hitSoundDurationUs: result['hitSoundDurationUs'] as int? ?? 100000,
      outputPath: result['outputPath']! as String,
    );
  }

  @override
  Future<void> submitFrame({
    required int sessionId,
    required int slot,
    required int presentationTimeUs,
    int? pvTimeUs,
  }) {
    return _channel.invokeMethod<void>('submitFrame', {
      'sessionId': sessionId,
      'slot': slot,
      'presentationTimeUs': presentationTimeUs,
      'pvTimeUs': pvTimeUs,
    });
  }

  @override
  Future<void> validateStorage({
    required int sessionId,
    required int durationUs,
  }) {
    return _channel.invokeMethod<void>('validateStorage', {
      'sessionId': sessionId,
      'durationUs': durationUs,
    });
  }

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
  }) async {
    final result = await _channel.invokeMapMethod<String, Object?>('finish', {
      'sessionId': sessionId,
      'durationUs': durationUs,
      'timelineStartUs': timelineStartUs,
      'musicOffsetUs': musicOffsetUs,
      'musicVolume': musicVolume,
      'hitSoundVolume': hitSoundVolume,
      'hitEventTimesUs': hitEventTimesUs,
      'judgementEventTimesUs': judgementEventTimesUs,
      'judgementEventKinds': judgementEventKinds,
      'judgementEventVolumes': judgementEventVolumes,
    });
    if (result == null) {
      throw PlatformException(
        code: 'invalid_native_result',
        message: 'Native video exporter returned no result.',
      );
    }
    return SimaiNativeVideoFinishResult(
      outputPath: result['outputPath']! as String,
      fileSizeBytes: result['fileSizeBytes']! as int,
      savedToGallery: result['savedToGallery'] as bool? ?? false,
      galleryUri: result['galleryUri'] as String?,
    );
  }

  @override
  Future<void> cancel(int sessionId) {
    return _channel.invokeMethod<void>('cancel', {'sessionId': sessionId});
  }

  @override
  Future<String?> saveToGallery(String path) {
    if (!_isMobile) {
      throw UnsupportedError(
        'Saving exported videos is supported only on Android and iOS.',
      );
    }
    return _channel.invokeMethod<String>('saveToGallery', {'path': path});
  }

  @override
  Future<void> shareVideo({required String path, String? text}) {
    if (!_isMobile) {
      throw UnsupportedError(
        'Sharing exported videos is supported only on Android and iOS.',
      );
    }
    return _channel.invokeMethod<void>('shareVideo', {
      'path': path,
      'text': text,
    });
  }
}
