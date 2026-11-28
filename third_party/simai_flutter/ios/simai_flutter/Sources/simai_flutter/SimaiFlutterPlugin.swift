import Accelerate
import AVFoundation
import CoreImage
import Flutter
import Photos
import UIKit
import VideoToolbox

public final class SimaiFlutterPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel!
  private weak var registrar: FlutterPluginRegistrar?
  private let queue = DispatchQueue(label: "dev.projectfukakai.simai_flutter.video_export", qos: .userInitiated)
  private var sessions: [Int: IOSVideoExportSession] = [:]
  private var nextSessionID = 1

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SimaiFlutterPlugin()
    instance.registrar = registrar
    instance.channel = FlutterMethodChannel(
      name: "simai_flutter/video_export",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: instance.channel)
    let audioChannel = FlutterMethodChannel(
      name: "simai_flutter/audio",
      binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(instance, channel: audioChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    queue.async { [weak self] in
      guard let self else { return }
      do {
        let arguments = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "activateAudioSession":
          let session = AVAudioSession.sharedInstance()
          try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
          try session.setActive(true)
          result(Int(session.sampleRate.rounded()))
        case "isSupported":
          let width = try arguments.requiredInt("width")
          let height = try arguments.requiredInt("height")
          let fps = try arguments.requiredInt("fps")
          result(IOSVideoExportSession.hardwareEncoderSupported(width: width, height: height, fps: fps))
        case "start":
          try self.start(arguments, result: result)
        case "submitFrame":
          let session = try self.requiredSession(arguments)
          try session.submitFrame(
            slot: try arguments.requiredInt("slot"),
            presentationTimeUs: try arguments.requiredInt64("presentationTimeUs"),
            pvTimeUs: (arguments["pvTimeUs"] as? NSNumber)?.int64Value
          )
          result(nil)
        case "validateStorage":
          let session = try self.requiredSession(arguments)
          try session.ensureDiskSpace(durationUs: try arguments.requiredInt64("durationUs"))
          result(nil)
        case "finish":
          try self.finishAsync(arguments, result: result)
        case "cancel":
          let id = try arguments.requiredInt("sessionId")
          self.sessions.removeValue(forKey: id)?.cancel()
          result(nil)
        case "saveToGallery":
          try self.saveToGalleryAsync(arguments, result: result)
        case "shareVideo":
          try self.shareVideoAsync(arguments, result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch let error as IOSExportError {
        result(FlutterError(code: error.code, message: error.message, details: nil))
      } catch {
        result(FlutterError(code: "native_error", message: error.localizedDescription, details: nil))
      }
    }
  }

  private func start(_ arguments: [String: Any], result: @escaping FlutterResult) throws {
    guard sessions.isEmpty else {
      throw IOSExportError(code: "busy", message: "Another video export is already running.")
    }
    let width = try arguments.requiredInt("width")
    let height = try arguments.requiredInt("height")
    let fps = try arguments.requiredInt("fps")
    guard IOSVideoExportSession.hardwareEncoderSupported(width: width, height: height, fps: fps) else {
      throw IOSExportError(code: "unsupported", message: "No hardware H.264 encoder supports the requested size.")
    }
    let id = nextSessionID
    nextSessionID += 1

    let audioAsset = arguments["audioAsset"] as? String
    let audioAssetPath = audioAsset.flatMap { assetPath($0, package: nil) }
    let customHitPath = (arguments["hitSoundFilePath"] as? String)
      .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .flatMap { !$0.isEmpty && FileManager.default.fileExists(atPath: $0) ? $0 : nil }
    let hitPath = customHitPath ?? assetPath("assets/answer.wav", package: "simai_flutter")
    let rawJudgeAssets = arguments["judgementSoundAssetPaths"] as? [String: String] ?? [:]
    let rawJudgeFiles = arguments["judgementSoundFilePaths"] as? [String: String] ?? [:]
    var judgementSoundPaths: [String: String] = [:]
    for (kind, asset) in rawJudgeAssets {
      if let custom = rawJudgeFiles[kind]?.trimmingCharacters(in: .whitespacesAndNewlines),
         !custom.isEmpty,
         FileManager.default.fileExists(atPath: custom) {
        judgementSoundPaths[kind] = custom
      } else if let bundled = assetPath(asset, package: "simai_flutter") {
        judgementSoundPaths[kind] = bundled
      }
    }
    let pvVideoPath = (arguments["pvVideoPath"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    let pvRect = (arguments["pvRect"] as? [NSNumber])?.map(\.intValue)
    let saveToGallery = (arguments["saveToGallery"] as? Bool) ?? false
    let session = try IOSVideoExportSession(
      id: id,
      width: width,
      height: height,
      fps: fps,
      bitrate: try arguments.requiredInt("videoBitrate"),
      requestedOutputPath: arguments["outputPath"] as? String,
      audioPath: arguments["audioFilePath"] as? String ?? audioAssetPath,
      hitSoundPath: hitPath,
      judgementSoundPaths: judgementSoundPaths,
      audioMode: try arguments.requiredString("audioMode"),
      pvVideoPath: pvVideoPath,
      pvRect: pvRect,
      saveToGallery: saveToGallery
    )
    do {
      try session.start()
    } catch {
      session.cancel()
      throw error
    }
    sessions[id] = session
    result([
      "sessionId": id,
      "bufferAddresses": session.frameBuffers.map {
        NSNumber(value: Int64(bitPattern: UInt64(UInt(bitPattern: $0))))
      },
      "bufferLength": session.frameByteCount,
      "audioDurationUs": session.audioDurationUs,
      "hitSoundDurationUs": session.hitSoundDurationUs,
      "outputPath": session.outputURL.path,
    ])
  }

  private func finishAsync(_ arguments: [String: Any], result: @escaping FlutterResult) throws {
    let id = try arguments.requiredInt("sessionId")
    let session = try requiredSession(arguments)
    let hits = (arguments["hitEventTimesUs"] as? [NSNumber])?.map(\.int64Value) ?? []
    let judgeTimes = (arguments["judgementEventTimesUs"] as? [NSNumber])?.map(\.int64Value) ?? []
    let judgeKinds = arguments["judgementEventKinds"] as? [String] ?? []
    let judgeVolumes = (arguments["judgementEventVolumes"] as? [NSNumber])?.map(\.floatValue) ?? []
    let judgeCount = min(judgeTimes.count, min(judgeKinds.count, judgeVolumes.count))
    let judgementEvents: [(timeUs: Int64, kind: String, volume: Float)] = (0..<judgeCount).map {
      (timeUs: judgeTimes[$0], kind: judgeKinds[$0], volume: judgeVolumes[$0])
    }
    let durationUs = try arguments.requiredInt64("durationUs")
    let timelineStartUs = try arguments.requiredInt64("timelineStartUs")
    let musicOffsetUs = try arguments.requiredInt64("musicOffsetUs")
    let musicVolume = try arguments.requiredDouble("musicVolume")
    let hitSoundVolume = (arguments["hitSoundVolume"] as? NSNumber)?.doubleValue ?? 2.0
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      var succeeded = false
      do {
        let output = try session.finish(
          durationUs: durationUs,
          timelineStartUs: timelineStartUs,
          musicOffsetUs: musicOffsetUs,
          musicVolume: musicVolume,
          hitSoundVolume: hitSoundVolume,
          hitEventTimesUs: hits,
          judgementEvents: judgementEvents
        )
        let attributes = try FileManager.default.attributesOfItem(atPath: output.path)
        let size = (attributes[.size] as? NSNumber)?.intValue ?? 0
        if session.saveToGallery && (self?.canAddToPhotoLibrary ?? false) {
          let gallerySemaphore = DispatchSemaphore(value: 0)
          var saved = false
          var savedIdentifier: String?
          PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: output)
            savedIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
          } completionHandler: { success, _ in
            saved = success
            gallerySemaphore.signal()
          }
          gallerySemaphore.wait()
          if saved {
            try? FileManager.default.removeItem(at: output)
            var payload: [String: Any] = [
              "outputPath": savedIdentifier ?? output.path,
              "fileSizeBytes": size,
              "savedToGallery": true,
            ]
            if let savedIdentifier {
              payload["galleryUri"] = savedIdentifier
            }
            result(payload)
            succeeded = true
          } else {
            result([
              "outputPath": output.path,
              "fileSizeBytes": size,
              "savedToGallery": false,
            ])
            succeeded = true
          }
        } else {
          result([
            "outputPath": output.path,
            "fileSizeBytes": size,
            "savedToGallery": false,
          ])
          succeeded = true
        }
      } catch let error as IOSExportError {
        result(FlutterError(code: error.code, message: error.message, details: nil))
      } catch {
        result(FlutterError(code: "native_error", message: error.localizedDescription, details: nil))
      }
      if !succeeded { session.cancel() }
      self?.queue.async { self?.sessions.removeValue(forKey: id) }
    }
  }

  private func saveToGalleryAsync(
    _ arguments: [String: Any],
    result: @escaping FlutterResult
  ) throws {
    let url = try exportedVideoURL(arguments)
    guard canAddToPhotoLibrary else {
      throw IOSExportError(
        code: "photo_permission_denied",
        message: "Photo library add permission must be granted by the host application before saving a video."
      )
    }

    var localIdentifier: String?
    PHPhotoLibrary.shared().performChanges {
      let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
    } completionHandler: { success, error in
      if success {
        do {
          try FileManager.default.removeItem(at: url)
          result(localIdentifier)
        } catch {
          result(
            FlutterError(
              code: "local_cleanup_failed",
              message: "The video was saved, but its local export file could not be deleted: \(error.localizedDescription)",
              details: nil
            )
          )
        }
      } else {
        result(
          FlutterError(
            code: "gallery_write_failed",
            message: error?.localizedDescription ?? "Unable to save the exported video to the photo library.",
            details: nil
          )
        )
      }
    }
  }

  private func shareVideoAsync(
    _ arguments: [String: Any],
    result: @escaping FlutterResult
  ) throws {
    let url = try exportedVideoURL(arguments)
    let sharedURL = try createShareCopy(of: url)
    let text = arguments["text"] as? String
    DispatchQueue.main.async { [weak self] in
      guard let self, let presenter = self.currentViewController() else {
        try? FileManager.default.removeItem(at: sharedURL)
        result(
          FlutterError(
            code: "share_unavailable",
            message: "No active view controller is available to present the share sheet.",
            details: nil
          )
        )
        return
      }
      var activityItems: [Any] = [sharedURL]
      if let text, !text.isEmpty { activityItems.append(text) }
      let activityController = UIActivityViewController(
        activityItems: activityItems,
        applicationActivities: nil
      )
      activityController.completionWithItemsHandler = { _, _, _, _ in
        try? FileManager.default.removeItem(at: sharedURL)
      }
      if let popover = activityController.popoverPresentationController {
        popover.sourceView = presenter.view
        popover.sourceRect = CGRect(
          x: presenter.view.bounds.midX,
          y: presenter.view.bounds.maxY,
          width: 1,
          height: 1
        )
        popover.permittedArrowDirections = []
      }
      presenter.present(activityController, animated: true) {
        do {
          try FileManager.default.removeItem(at: url)
          result(nil)
        } catch {
          result(
            FlutterError(
              code: "local_cleanup_failed",
              message: "The share sheet was opened, but the local export file could not be deleted: \(error.localizedDescription)",
              details: nil
            )
          )
        }
      }
    }
  }

  private func createShareCopy(of sourceURL: URL) throws -> URL {
    let fileManager = FileManager.default
    let cache = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let directory = cache.appendingPathComponent("simai_flutter_share", isDirectory: true)
    do {
      try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
      let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
      let staleFiles = try fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: [.contentModificationDateKey],
        options: [.skipsHiddenFiles]
      )
      for file in staleFiles {
        let values = try? file.resourceValues(forKeys: [.contentModificationDateKey])
        if let modified = values?.contentModificationDate, modified < cutoff {
          try? fileManager.removeItem(at: file)
        }
      }
      let destination = directory.appendingPathComponent(
        "simai_\(UUID().uuidString)_\(sourceURL.lastPathComponent)"
      )
      try fileManager.copyItem(at: sourceURL, to: destination)
      return destination
    } catch {
      throw IOSExportError(
        code: "share_failed",
        message: "Unable to prepare the exported video for sharing: \(error.localizedDescription)"
      )
    }
  }

  private func exportedVideoURL(_ arguments: [String: Any]) throws -> URL {
    let path = try arguments.requiredString("path")
    let url = URL(fileURLWithPath: path)
    var isDirectory: ObjCBool = false
    guard url.isFileURL,
          FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
          !isDirectory.boolValue,
          FileManager.default.isReadableFile(atPath: url.path) else {
      throw IOSExportError(
        code: "file_not_found",
        message: "The exported video does not exist or cannot be read: \(path)"
      )
    }
    return url
  }

  private var canAddToPhotoLibrary: Bool {
    if #available(iOS 14, *) {
      switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
      case .authorized, .limited:
        return true
      case .denied, .restricted, .notDetermined:
        return false
      @unknown default:
        return false
      }
    }
    return PHPhotoLibrary.authorizationStatus() == .authorized
  }

  private func currentViewController() -> UIViewController? {
    let root = registrar?.viewController ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
    return topViewController(from: root)
  }

  private func topViewController(from root: UIViewController?) -> UIViewController? {
    if let presented = root?.presentedViewController {
      return topViewController(from: presented)
    }
    if let navigation = root as? UINavigationController {
      return topViewController(from: navigation.visibleViewController)
    }
    if let tab = root as? UITabBarController {
      return topViewController(from: tab.selectedViewController)
    }
    return root
  }

  private func requiredSession(_ arguments: [String: Any]) throws -> IOSVideoExportSession {
    let id = try arguments.requiredInt("sessionId")
    guard let session = sessions[id] else {
      throw IOSExportError(code: "unknown_session", message: "Unknown video export session \(id).")
    }
    return session
  }

  private func assetPath(_ asset: String, package: String?) -> String? {
    guard let registrar else { return nil }
    let key: String
    if let package {
      key = registrar.lookupKey(forAsset: asset, fromPackage: package)
    } else {
      key = registrar.lookupKey(forAsset: asset)
    }
    return Bundle.main.path(forResource: key, ofType: nil)
  }
}

private final class IOSVideoExportSession {
  let id: Int
  let width: Int
  let height: Int
  let fps: Int
  let bitrate: Int
  let frameByteCount: Int
  let frameBuffers: [UnsafeMutableRawPointer]
  let outputURL: URL
  let audioURL: URL?
  let hitSoundURL: URL?
  let judgementSoundURLs: [String: URL]
  let audioMode: String
  let audioDurationUs: Int64
  let hitSoundDurationUs: Int64
  let saveToGallery: Bool

  private let workingDirectory: URL
  private let videoOnlyURL: URL
  private let finalMuxedURL: URL
  private let pvRect: [Int]?
  private var pvReader: IOSPvFrameReader?
  private var pvForegroundScratch: UnsafeMutableRawPointer?
  private var writer: AVAssetWriter?
  private var videoInput: AVAssetWriterInput?
  private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
  private let stateLock = NSLock()
  private var cancelled = false
  private var finished = false

  init(
    id: Int,
    width: Int,
    height: Int,
    fps: Int,
    bitrate: Int,
    requestedOutputPath: String?,
    audioPath: String?,
    hitSoundPath: String?,
    judgementSoundPaths: [String: String] = [:],
    audioMode: String,
    pvVideoPath: String? = nil,
    pvRect: [Int]? = nil,
    saveToGallery: Bool = false
  ) throws {
    guard ["musicAndHitSounds", "musicOnly", "silent"].contains(audioMode) else {
      throw IOSExportError(code: "invalid_audio_mode", message: "Unsupported audio mode: \(audioMode)")
    }
    let resolvedAudioURL = audioPath.map { URL(fileURLWithPath: $0) }
    let resolvedHitSoundURL = hitSoundPath.map { URL(fileURLWithPath: $0) }

    let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    let resolvedWorkingDirectory = cache.appendingPathComponent("simai_video_\(id)", isDirectory: true)
    let resolvedVideoOnlyURL = resolvedWorkingDirectory.appendingPathComponent("video.mp4")
    let resolvedFinalMuxedURL = resolvedWorkingDirectory.appendingPathComponent("final.mp4")
    let resolvedOutputURL: URL
    if let requestedOutputPath {
      guard (requestedOutputPath as NSString).isAbsolutePath else {
        throw IOSExportError(code: "invalid_output_path", message: "The output path must be an absolute file path.")
      }
      resolvedOutputURL = URL(fileURLWithPath: requestedOutputPath)
    } else {
      let directory = cache.appendingPathComponent("simai_exports", isDirectory: true)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      resolvedOutputURL = directory.appendingPathComponent("simai_\(Int(Date().timeIntervalSince1970 * 1000)).mp4")
    }
    try FileManager.default.createDirectory(
      at: resolvedOutputURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    let resolvedAudioDurationUs: Int64
    if audioMode != "silent" {
      guard let resolvedAudioURL, FileManager.default.fileExists(atPath: resolvedAudioURL.path) else {
        throw IOSExportError(code: "invalid_audio_source", message: "The selected audio mode requires a music source.")
      }
      let duration = AVURLAsset(url: resolvedAudioURL).duration.seconds
      guard duration.isFinite, duration > 0 else {
        throw IOSExportError(code: "invalid_audio_source", message: "The music source has no valid audio duration.")
      }
      resolvedAudioDurationUs = Int64(duration * 1_000_000)
    } else {
      resolvedAudioDurationUs = 0
    }
    var resolvedHitSoundDurationUs: Int64 = 100_000
    if audioMode == "musicAndHitSounds" {
      guard let resolvedHitSoundURL, FileManager.default.fileExists(atPath: resolvedHitSoundURL.path) else {
        throw IOSExportError(code: "missing_hit_sound", message: "The bundled hit sound is unavailable.")
      }
      let hitSec = AVURLAsset(url: resolvedHitSoundURL).duration.seconds
      if hitSec.isFinite && hitSec > 0 {
        resolvedHitSoundDurationUs = min(max(50_000, Int64(hitSec * 1_000_000)), 5_000_000)
      }
    }

    try FileManager.default.createDirectory(
      at: resolvedWorkingDirectory,
      withIntermediateDirectories: true
    )
    var resolvedPvRect: [Int]?
    var resolvedPvReader: IOSPvFrameReader?
    var resolvedPvForegroundScratch: UnsafeMutableRawPointer?
    if let pvVideoPath {
      guard let pvRect, pvRect.count == 4,
            pvRect[0] >= 0, pvRect[1] >= 0,
            pvRect[2] > 0, pvRect[3] > 0,
            pvRect[0] + pvRect[2] <= width,
            pvRect[1] + pvRect[3] <= height else {
        throw IOSExportError(code: "invalid_pv_rect", message: "启用 PV 背景导出时必须提供有效的 pvRect。")
      }
      resolvedPvRect = pvRect
      resolvedPvReader = try IOSPvFrameReader(
        videoPath: pvVideoPath,
        targetWidth: pvRect[2],
        targetHeight: pvRect[3]
      )
      resolvedPvForegroundScratch = UnsafeMutableRawPointer.allocate(
        byteCount: pvRect[2] * pvRect[3] * 4,
        alignment: 64
      )
    }

    let byteCount = width * height * 4
    self.id = id
    self.width = width
    self.height = height
    self.fps = fps
    self.bitrate = bitrate
    self.frameByteCount = byteCount
    self.frameBuffers = (0..<2).map { _ in
      UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 64)
    }
    self.outputURL = resolvedOutputURL
    self.audioURL = resolvedAudioURL
    self.hitSoundURL = resolvedHitSoundURL
    self.judgementSoundURLs = judgementSoundPaths.mapValues { URL(fileURLWithPath: $0) }
    self.audioMode = audioMode
    self.audioDurationUs = resolvedAudioDurationUs
    self.hitSoundDurationUs = resolvedHitSoundDurationUs
    self.saveToGallery = saveToGallery
    self.workingDirectory = resolvedWorkingDirectory
    self.videoOnlyURL = resolvedVideoOnlyURL
    self.finalMuxedURL = resolvedFinalMuxedURL
    self.pvRect = resolvedPvRect
    self.pvReader = resolvedPvReader
    self.pvForegroundScratch = resolvedPvForegroundScratch
  }

  deinit {
    frameBuffers.forEach { $0.deallocate() }
    pvForegroundScratch?.deallocate()
  }

  static func hardwareEncoderSupported(width: Int, height: Int, fps: Int) -> Bool {
    // The simulator has no hardware video encoder, so this probe can only fail.
    // Worse, VTCompressionSessionCreate makes VideoToolbox dlopen
    // VideoProcessing.framework; on the iOS 26/27 simulator, mapping that
    // framework's Objective-C images writes into its read-only __DATA_CONST
    // pages and crashes the host app with SIGBUS (KERN_PROTECTION_FAILURE).
    // Skip the probe entirely on the simulator.
    #if targetEnvironment(simulator)
    return false
    #else
    var session: VTCompressionSession?
    let specification: CFDictionary?
    if #available(iOS 17.4, *) {
      specification = [
        kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder as String: true,
      ] as CFDictionary
    } else {
      specification = nil
    }
    let status = VTCompressionSessionCreate(
      allocator: kCFAllocatorDefault,
      width: Int32(width),
      height: Int32(height),
      codecType: kCMVideoCodecType_H264,
      encoderSpecification: specification,
      imageBufferAttributes: nil,
      compressedDataAllocator: nil,
      outputCallback: nil,
      refcon: nil,
      compressionSessionOut: &session
    )
    guard status == noErr, let session else { return false }
    defer { VTCompressionSessionInvalidate(session) }
    guard VTSessionSetProperty(
      session,
      key: kVTCompressionPropertyKey_ExpectedFrameRate,
      value: NSNumber(value: fps)
    ) == noErr,
    VTSessionSetProperty(
      session,
      key: kVTCompressionPropertyKey_AllowFrameReordering,
      value: kCFBooleanFalse
    ) == noErr,
    VTCompressionSessionPrepareToEncodeFrames(session) == noErr else {
      return false
    }
    if #available(iOS 17.4, *) {
      let valuePointer = UnsafeMutablePointer<Unmanaged<CFTypeRef>?>.allocate(capacity: 1)
      valuePointer.initialize(to: nil)
      defer {
        valuePointer.deinitialize(count: 1)
        valuePointer.deallocate()
      }
      let propertyStatus = VTSessionCopyProperty(
        session,
        key: kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder,
        allocator: kCFAllocatorDefault,
        valueOut: valuePointer
      )
      let value = valuePointer.pointee?.takeRetainedValue()
      return propertyStatus == noErr && (value as? Bool) == true
    }
    return true
    #endif
  }

  func start() throws {
    var lastMessage = "AVAssetWriter rejected every H.264 rate-control mode."
    for rateControl in IOSVideoRateControl.allCases {
      try? FileManager.default.removeItem(at: videoOnlyURL)
      do {
        let writer = try AVAssetWriter(outputURL: videoOnlyURL, fileType: .mp4)
        let settings = videoSettings(rateControl: rateControl)
        guard writer.canApply(outputSettings: settings, forMediaType: .video) else {
          lastMessage = "AVAssetWriter does not support \(rateControl.label) settings."
          continue
        }
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else {
          lastMessage = "AVAssetWriter rejected \(rateControl.label) input."
          continue
        }
        writer.add(input)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
          assetWriterInput: input,
          sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:],
          ]
        )
        guard writer.startWriting() else {
          lastMessage = writer.error?.localizedDescription ??
            "Unable to start AVAssetWriter with \(rateControl.label) settings."
          writer.cancelWriting()
          continue
        }
        writer.startSession(atSourceTime: .zero)
        self.writer = writer
        self.videoInput = input
        self.adaptor = adaptor
        return
      } catch {
        lastMessage = error.localizedDescription
      }
    }
    throw IOSExportError(code: "video_writer", message: lastMessage)
  }

  private func videoSettings(rateControl: IOSVideoRateControl) -> [String: Any] {
    var compression: [String: Any] = [
      AVVideoExpectedSourceFrameRateKey: fps,
      AVVideoMaxKeyFrameIntervalKey: fps * 2,
      AVVideoAllowFrameReorderingKey: false,
      AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
    ]
    switch rateControl {
    case .quality:
      compression[kVTCompressionPropertyKey_Quality as String] = 0.70
    case .variableBitrate:
      compression[AVVideoAverageBitRateKey] = bitrate
      compression[kVTCompressionPropertyKey_DataRateLimits as String] = [
        NSNumber(value: bitrate / 4),
        NSNumber(value: 1),
      ]
    case .targetBitrate:
      compression[AVVideoAverageBitRateKey] = bitrate
    }
    return [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height,
      AVVideoCompressionPropertiesKey: compression,
    ]
  }

  func submitFrame(slot: Int, presentationTimeUs: Int64, pvTimeUs: Int64? = nil) throws {
    try checkCancelled()
    guard frameBuffers.indices.contains(slot) else {
      throw IOSExportError(code: "invalid_slot", message: "Invalid frame buffer slot \(slot).")
    }
    guard let input = videoInput, let adaptor, let pool = adaptor.pixelBufferPool else {
      throw IOSExportError(code: "video_writer", message: "Video writer is not ready.")
    }
    while !input.isReadyForMoreMediaData {
      try checkCancelled()
      Thread.sleep(forTimeInterval: 0.001)
    }
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
    guard status == kCVReturnSuccess, let pixelBuffer else {
      throw IOSExportError(code: "pixel_buffer", message: "Unable to acquire a VideoToolbox pixel buffer.")
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
    guard let destination = CVPixelBufferGetBaseAddress(pixelBuffer) else {
      throw IOSExportError(code: "pixel_buffer", message: "Pixel buffer has no writable base address.")
    }
    let destinationBytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
    var sourceBuffer = vImage_Buffer(
      data: frameBuffers[slot],
      height: vImagePixelCount(height),
      width: vImagePixelCount(width),
      rowBytes: width * 4
    )
    var destinationBuffer = vImage_Buffer(
      data: destination,
      height: vImagePixelCount(height),
      width: vImagePixelCount(width),
      rowBytes: destinationBytesPerRow
    )
    var permutation: [UInt8] = [2, 1, 0, 3]
    let conversion = vImagePermuteChannels_ARGB8888(
      &sourceBuffer,
      &destinationBuffer,
      &permutation,
      vImage_Flags(kvImageNoFlags)
    )
    guard conversion == kvImageNoError else {
      throw IOSExportError(code: "pixel_conversion", message: "RGBA to BGRA conversion failed: \(conversion).")
    }

    if let pvReader,
       let pvRect,
       let pvForegroundScratch,
       let pvTimeUs,
       pvReader.advanceTo(targetTimeUs: pvTimeUs) {
      let left = pvRect[0]
      let top = pvRect[1]
      let pvW = pvRect[2]
      let pvH = pvRect[3]
      let srcRowBytes = width * 4
      let srcRoiPtr = frameBuffers[slot].advanced(by: top * srcRowBytes + left * 4)
      var srcRoiBuffer = vImage_Buffer(
        data: srcRoiPtr,
        height: vImagePixelCount(pvH),
        width: vImagePixelCount(pvW),
        rowBytes: srcRowBytes
      )
      var fgBuffer = vImage_Buffer(
        data: pvForegroundScratch,
        height: vImagePixelCount(pvH),
        width: vImagePixelCount(pvW),
        rowBytes: pvW * 4
      )
      var fgPermutation: [UInt8] = [2, 1, 0, 3]
      let fgConversion = vImagePermuteChannels_ARGB8888(
        &srcRoiBuffer,
        &fgBuffer,
        &fgPermutation,
        vImage_Flags(kvImageNoFlags)
      )
      guard fgConversion == kvImageNoError else {
        throw IOSExportError(code: "pixel_conversion", message: "PV 前景区域通道转换失败: \(fgConversion).")
      }
      var bgBuffer = vImage_Buffer(
        data: pvReader.bgraBuffer,
        height: vImagePixelCount(pvH),
        width: vImagePixelCount(pvW),
        rowBytes: pvReader.rowBytes
      )
      let destRoiPtr = destination.advanced(by: top * destinationBytesPerRow + left * 4)
      var destRoiBuffer = vImage_Buffer(
        data: destRoiPtr,
        height: vImagePixelCount(pvH),
        width: vImagePixelCount(pvW),
        rowBytes: destinationBytesPerRow
      )
      // 使用预乘 Alpha 将透明镂空的 Flutter 前景叠加到解码后的 PV 帧之上
      let blendError = vImagePremultipliedAlphaBlend_BGRA8888(
        &fgBuffer,
        &bgBuffer,
        &destRoiBuffer,
        vImage_Flags(kvImageNoFlags)
      )
      guard blendError == kvImageNoError else {
        throw IOSExportError(code: "pixel_blend", message: "PV 与谱面前景预乘合成失败: \(blendError).")
      }
    }

    let time = CMTime(value: presentationTimeUs, timescale: 1_000_000)
    guard adaptor.append(pixelBuffer, withPresentationTime: time) else {
      throw IOSExportError(code: "video_writer", message: writer?.error?.localizedDescription ?? "Unable to append video frame.")
    }
  }

  func finish(
    durationUs: Int64,
    timelineStartUs: Int64,
    musicOffsetUs: Int64,
    musicVolume: Double,
    hitSoundVolume: Double = 2.0,
    hitEventTimesUs: [Int64],
    judgementEvents: [(timeUs: Int64, kind: String, volume: Float)] = []
  ) throws -> URL {
    try checkCancelled()
    try ensureDiskSpace(durationUs: durationUs)
    videoInput?.markAsFinished()
    pvReader = nil
    guard let writer else {
      throw IOSExportError(code: "video_writer", message: "Video writer is not running.")
    }
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting { semaphore.signal() }
    semaphore.wait()
    try checkCancelled()
    guard writer.status == .completed else {
      throw IOSExportError(code: "video_writer", message: writer.error?.localizedDescription ?? "Video encoding failed.")
    }
    if audioMode == "silent" {
      try replaceItem(at: outputURL, with: videoOnlyURL)
    } else {
      try IOSAudioMuxer(
        videoURL: videoOnlyURL,
        musicURL: audioURL!,
        hitSoundURL: (audioMode == "musicAndHitSounds" && !hitEventTimesUs.isEmpty) ? hitSoundURL : nil,
        judgementSoundURLs: audioMode == "musicAndHitSounds" ? judgementSoundURLs : [:],
        outputURL: finalMuxedURL,
        isCancelled: { [weak self] in self?.isCancellationRequested() ?? true }
      ).mux(
        durationUs: durationUs,
        timelineStartUs: timelineStartUs,
        musicOffsetUs: musicOffsetUs,
        musicVolume: Float(musicVolume).clamped(to: 0...1),
        hitSoundVolume: Float(hitSoundVolume).clamped(to: 0...3),
        hitEventTimesUs: hitEventTimesUs,
        judgementEvents: judgementEvents
      )
      try checkCancelled()
      try replaceItem(at: outputURL, with: finalMuxedURL)
    }
    finished = true
    try? FileManager.default.removeItem(at: workingDirectory)
    return outputURL
  }

  func cancel() {
    stateLock.lock()
    cancelled = true
    stateLock.unlock()
    pvReader = nil
    writer?.cancelWriting()
    try? FileManager.default.removeItem(at: workingDirectory)
  }

  private func checkCancelled() throws {
    if isCancellationRequested() {
      throw IOSExportError(code: "cancelled", message: "Video export was cancelled.")
    }
  }

  private func isCancellationRequested() -> Bool {
    stateLock.lock()
    defer { stateLock.unlock() }
    return cancelled
  }

  func ensureDiskSpace(durationUs: Int64) throws {
    let duration = Double(durationUs) / 1_000_000
    let estimatedFinal = Int64(Double(bitrate + 192_000) * duration / 8)
    let required = Int64(Double(estimatedFinal) * 2.5) + 64 * 1024 * 1024
    let values = try workingDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
    if let available = values.volumeAvailableCapacityForImportantUsage, available < required {
      throw IOSExportError(code: "insufficient_storage", message: "Insufficient storage for video export.")
    }
    let outputDirectory = outputURL.deletingLastPathComponent()
    guard FileManager.default.isWritableFile(atPath: outputDirectory.path) else {
      throw IOSExportError(code: "output_not_writable", message: "The output directory is not writable.")
    }
    let outputValues = try outputDirectory.resourceValues(
      forKeys: [.volumeAvailableCapacityForImportantUsageKey]
    )
    let outputRequired = estimatedFinal + 16 * 1024 * 1024
    if let available = outputValues.volumeAvailableCapacityForImportantUsage,
       available < outputRequired {
      throw IOSExportError(code: "insufficient_storage", message: "Insufficient storage at the output path.")
    }
  }

  private func replaceItem(at destination: URL, with source: URL) throws {
    let manager = FileManager.default
    let directory = destination.deletingLastPathComponent()
    try manager.createDirectory(at: directory, withIntermediateDirectories: true)
    let staging = directory.appendingPathComponent(".\(destination.lastPathComponent).\(UUID().uuidString).tmp")
    try? manager.removeItem(at: staging)
    do {
      try manager.copyItem(at: source, to: staging)
      if manager.fileExists(atPath: destination.path) {
        _ = try manager.replaceItemAt(destination, withItemAt: staging)
      } else {
        try manager.moveItem(at: staging, to: destination)
      }
      try? FileManager.default.removeItem(at: source)
    } catch {
      try? manager.removeItem(at: staging)
      throw error
    }
  }
}

private enum IOSVideoRateControl: CaseIterable {
  case quality
  case variableBitrate
  case targetBitrate

  var label: String {
    switch self {
    case .quality: "quality"
    case .variableBitrate: "VBR"
    case .targetBitrate: "target bitrate"
    }
  }
}

/// iOS 原生 PV 视频顺序解码器，按轨道方向与 BoxFit.cover 裁切写入复用 BGRA 缓冲区。
private final class IOSPvFrameReader {
  private let reader: AVAssetReader
  private let trackOutput: AVAssetReaderTrackOutput
  private let ciContext: CIContext
  private let colorSpace: CGColorSpace
  private let preferredTransform: CGAffineTransform
  let targetWidth: Int
  let targetHeight: Int
  let durationUs: Int64
  let rowBytes: Int
  let bgraBuffer: UnsafeMutableRawPointer

  private var hasDecodedFrame = false
  private var lastPtsUs: Int64 = Int64.min
  private var reachedEnd = false

  init(videoPath: String, targetWidth: Int, targetHeight: Int) throws {
    guard targetWidth > 0, targetHeight > 0 else {
      throw IOSExportError(code: "invalid_pv_rect", message: "PV 目标绘制尺寸必须为正数。")
    }
    let url = URL(fileURLWithPath: videoPath)
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
          !isDirectory.boolValue,
          FileManager.default.isReadableFile(atPath: url.path) else {
      throw IOSExportError(code: "pv_not_found", message: "PV 视频文件不存在或不可读: \(videoPath)")
    }
    let asset = AVURLAsset(url: url)
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      throw IOSExportError(code: "pv_invalid", message: "PV 文件中未找到视频轨道。")
    }
    let rawDuration = videoTrack.timeRange.duration.seconds
    let fallbackDuration = asset.duration.seconds
    let durationSec = (rawDuration.isFinite && rawDuration > 0) ? rawDuration : fallbackDuration
    self.durationUs = (durationSec.isFinite && durationSec > 0)
      ? Int64((durationSec * 1_000_000).rounded())
      : 0

    let reader = try AVAssetReader(asset: asset)
    let outputSettings: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
    ]
    let trackOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: outputSettings)
    trackOutput.alwaysCopiesSampleData = false
    guard reader.canAdd(trackOutput) else {
      throw IOSExportError(code: "pv_reader", message: "无法创建 PV 视频读取输出。")
    }
    reader.add(trackOutput)
    guard reader.startReading() else {
      throw IOSExportError(
        code: "pv_reader",
        message: reader.error?.localizedDescription ?? "无法开始读取 PV 视频。"
      )
    }

    self.reader = reader
    self.trackOutput = trackOutput
    self.ciContext = CIContext(options: [.useSoftwareRenderer: false])
    self.colorSpace = CGColorSpaceCreateDeviceRGB()
    self.preferredTransform = videoTrack.preferredTransform
    self.targetWidth = targetWidth
    self.targetHeight = targetHeight
    self.rowBytes = targetWidth * 4
    self.bgraBuffer = UnsafeMutableRawPointer.allocate(
      byteCount: targetWidth * targetHeight * 4,
      alignment: 64
    )
  }

  deinit {
    reader.cancelReading()
    bgraBuffer.deallocate()
  }

  func advanceTo(targetTimeUs: Int64) -> Bool {
    if durationUs <= 0 || targetTimeUs < 0 || targetTimeUs > durationUs {
      return false
    }
    let thresholdUs = targetTimeUs - 8_333
    if hasDecodedFrame && lastPtsUs >= thresholdUs {
      return true
    }
    if reachedEnd {
      return hasDecodedFrame
    }

    var lastSkippedSample: CMSampleBuffer?
    var lastSkippedPtsUs: Int64 = Int64.min

    while let sampleBuffer = trackOutput.copyNextSampleBuffer() {
      let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
      let ptsSeconds = pts.seconds
      guard ptsSeconds.isFinite else { continue }
      let ptsUs = Int64((ptsSeconds * 1_000_000).rounded())
      if ptsUs >= thresholdUs {
        if renderSampleToBuffer(sampleBuffer) {
          lastPtsUs = ptsUs
          hasDecodedFrame = true
        }
        return hasDecodedFrame
      }
      lastSkippedSample = sampleBuffer
      lastSkippedPtsUs = ptsUs
    }

    reachedEnd = true
    if let lastSkippedSample, lastSkippedPtsUs > lastPtsUs {
      if renderSampleToBuffer(lastSkippedSample) {
        lastPtsUs = lastSkippedPtsUs
        hasDecodedFrame = true
      }
    }
    return hasDecodedFrame
  }

  private func renderSampleToBuffer(_ sampleBuffer: CMSampleBuffer) -> Bool {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return false
    }
    var ciImage = CIImage(cvPixelBuffer: imageBuffer)
    if !preferredTransform.isIdentity {
      // 将左上角原点的 preferredTransform 转换到 CoreImage 左下角原点坐标系
      let rawHeight = ciImage.extent.height
      let toTopDown = CGAffineTransform(scaleX: 1, y: -1)
        .concatenating(CGAffineTransform(translationX: 0, y: rawHeight))
      let combined = toTopDown
        .concatenating(preferredTransform)
        .concatenating(CGAffineTransform(scaleX: 1, y: -1))
      ciImage = ciImage.transformed(by: combined)
      let origin = ciImage.extent.origin
      if origin.x != 0 || origin.y != 0 {
        ciImage = ciImage.transformed(
          by: CGAffineTransform(translationX: -origin.x, y: -origin.y)
        )
      }
    }

    let srcWidth = ciImage.extent.width
    let srcHeight = ciImage.extent.height
    guard srcWidth > 0, srcHeight > 0 else {
      return false
    }

    let scale = max(CGFloat(targetWidth) / srcWidth, CGFloat(targetHeight) / srcHeight)
    let scaledWidth = srcWidth * scale
    let scaledHeight = srcHeight * scale
    let offsetX = (CGFloat(targetWidth) - scaledWidth) * 0.5
    let offsetY = (CGFloat(targetHeight) - scaledHeight) * 0.5
    let renderBounds = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
    let outputImage = ciImage
      .clampedToExtent()
      .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
      .transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
      .cropped(to: renderBounds)

    ciContext.render(
      outputImage,
      toBitmap: bgraBuffer,
      rowBytes: rowBytes,
      bounds: renderBounds,
      format: .BGRA8,
      colorSpace: colorSpace
    )
    return true
  }
}

private final class IOSAudioMuxer {
  let videoURL: URL
  let musicURL: URL
  let hitSoundURL: URL?
  let judgementSoundURLs: [String: URL]
  let outputURL: URL
  let isCancelled: () -> Bool

  init(
    videoURL: URL,
    musicURL: URL,
    hitSoundURL: URL?,
    judgementSoundURLs: [String: URL] = [:],
    outputURL: URL,
    isCancelled: @escaping () -> Bool
  ) {
    self.videoURL = videoURL
    self.musicURL = musicURL
    self.hitSoundURL = hitSoundURL
    self.judgementSoundURLs = judgementSoundURLs
    self.outputURL = outputURL
    self.isCancelled = isCancelled
  }

  func mux(
    durationUs: Int64,
    timelineStartUs: Int64,
    musicOffsetUs: Int64,
    musicVolume: Float,
    hitSoundVolume: Float = 2.0,
    hitEventTimesUs: [Int64],
    judgementEvents: [(timeUs: Int64, kind: String, volume: Float)] = []
  ) throws {
    if isCancelled() {
      throw IOSExportError(code: "cancelled", message: "Video export was cancelled.")
    }
    let totalDuration = CMTime(value: durationUs, timescale: 1_000_000)
    let composition = AVMutableComposition()
    var mixParameters: [AVMutableAudioMixInputParameters] = []
    try addMusic(
      to: composition,
      totalDuration: totalDuration,
      timelineStartUs: timelineStartUs,
      musicOffsetUs: musicOffsetUs,
      volume: musicVolume,
      mixParameters: &mixParameters
    )
    if let hitSoundURL, !hitEventTimesUs.isEmpty {
      try addHitSounds(
        hitSoundURL,
        to: composition,
        totalDuration: totalDuration,
        timelineStartUs: timelineStartUs,
        hitSoundVolume: hitSoundVolume,
        hitEventTimesUs: hitEventTimesUs,
        mixParameters: &mixParameters
      )
    }
    if !judgementEvents.isEmpty && !judgementSoundURLs.isEmpty {
      try addJudgementSounds(
        judgementSoundURLs,
        events: judgementEvents,
        to: composition,
        totalDuration: totalDuration,
        timelineStartUs: timelineStartUs,
        mixParameters: &mixParameters
      )
    }
    let audioMix = AVMutableAudioMix()
    audioMix.inputParameters = mixParameters

    try? FileManager.default.removeItem(at: outputURL)
    let videoAsset = AVURLAsset(url: videoURL)
    guard let sourceVideoTrack = videoAsset.tracks(withMediaType: .video).first else {
      throw IOSExportError(code: "mux", message: "Encoded video track is missing.")
    }
    guard let rawVideoFormatHint = sourceVideoTrack.formatDescriptions.first,
          CFGetTypeID(rawVideoFormatHint as CFTypeRef) == CMFormatDescriptionGetTypeID()
    else {
      throw IOSExportError(code: "mux", message: "Encoded video format description is missing.")
    }
    // `formatDescriptions` is imported as `[Any]`. On arm64e the existential
    // container is wider than a Core Foundation reference, so `unsafeBitCast`
    // traps even though the wrapped object has the correct CFTypeID. Use
    // Swift's checked bridging cast after validating the Core Media type.
    let videoFormatHint = rawVideoFormatHint as! CMFormatDescription
    let videoReader = try AVAssetReader(asset: videoAsset)
    let videoOutput = AVAssetReaderTrackOutput(track: sourceVideoTrack, outputSettings: nil)
    videoOutput.alwaysCopiesSampleData = false
    guard videoReader.canAdd(videoOutput) else {
      throw IOSExportError(code: "mux", message: "Unable to read encoded video samples.")
    }
    videoReader.add(videoOutput)

    let audioReader = try AVAssetReader(asset: composition)
    let audioOutput = AVAssetReaderAudioMixOutput(
      audioTracks: composition.tracks(withMediaType: .audio),
      audioSettings: [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 48_000,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsNonInterleaved: false,
      ]
    )
    audioOutput.audioMix = audioMix
    guard audioReader.canAdd(audioOutput) else {
      throw IOSExportError(code: "mux", message: "Unable to create the mixed audio reader.")
    }
    audioReader.add(audioOutput)

    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    var muxCompleted = false
    defer {
      if !muxCompleted {
        videoReader.cancelReading()
        audioReader.cancelReading()
        writer.cancelWriting()
        try? FileManager.default.removeItem(at: outputURL)
      }
    }
    let videoInput = AVAssetWriterInput(
      mediaType: .video,
      outputSettings: nil,
      sourceFormatHint: videoFormatHint
    )
    let audioInput = AVAssetWriterInput(
      mediaType: .audio,
      outputSettings: [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVSampleRateKey: 48_000,
        AVNumberOfChannelsKey: 2,
        AVEncoderBitRateKey: 192_000,
      ]
    )
    videoInput.expectsMediaDataInRealTime = false
    audioInput.expectsMediaDataInRealTime = false
    guard writer.canAdd(videoInput), writer.canAdd(audioInput) else {
      throw IOSExportError(code: "mux", message: "AVAssetWriter rejected the final MP4 tracks.")
    }
    writer.add(videoInput)
    writer.add(audioInput)
    guard writer.startWriting(), videoReader.startReading(), audioReader.startReading() else {
      throw IOSExportError(code: "mux", message: writer.error?.localizedDescription ?? "Unable to start final MP4 muxing.")
    }
    writer.startSession(atSourceTime: .zero)

    let group = DispatchGroup()
    appendSamples(videoOutput, to: videoInput, reader: videoReader, group: group)
    appendSamples(audioOutput, to: audioInput, reader: audioReader, group: group)
    group.wait()
    if isCancelled() {
      writer.cancelWriting()
      throw IOSExportError(code: "cancelled", message: "Video export was cancelled.")
    }
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting { semaphore.signal() }
    semaphore.wait()
    guard writer.status == .completed else {
      throw IOSExportError(code: "mux", message: writer.error?.localizedDescription ?? "Final MP4 muxing failed.")
    }
    muxCompleted = true
  }

  private func addMusic(
    to composition: AVMutableComposition,
    totalDuration: CMTime,
    timelineStartUs: Int64,
    musicOffsetUs: Int64,
    volume: Float,
    mixParameters: inout [AVMutableAudioMixInputParameters]
  ) throws {
    let asset = AVURLAsset(url: musicURL)
    guard let source = asset.tracks(withMediaType: .audio).first,
          let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
    else { throw IOSExportError(code: "audio", message: "Music audio track is missing.") }
    let startSeconds = Double(musicOffsetUs - timelineStartUs) / 1_000_000
    let targetStart = CMTime(seconds: max(0, startSeconds), preferredTimescale: 48_000)
    let sourceStart = CMTime(seconds: max(0, -startSeconds), preferredTimescale: 48_000)
    let available = CMTimeMinimum(CMTimeSubtract(asset.duration, sourceStart), CMTimeSubtract(totalDuration, targetStart))
    if available > .zero {
      try track.insertTimeRange(CMTimeRange(start: sourceStart, duration: available), of: source, at: targetStart)
    }
    let parameters = AVMutableAudioMixInputParameters(track: track)
    parameters.setVolume(volume, at: .zero)
    mixParameters.append(parameters)
  }

  private func addHitSounds(
    _ url: URL,
    to composition: AVMutableComposition,
    totalDuration: CMTime,
    timelineStartUs: Int64,
    hitSoundVolume: Float,
    hitEventTimesUs: [Int64],
    mixParameters: inout [AVMutableAudioMixInputParameters]
  ) throws {
    let asset = AVURLAsset(url: url)
    guard let source = asset.tracks(withMediaType: .audio).first else {
      throw IOSExportError(code: "audio", message: "The bundled hit sound has no audio track.")
    }
    let rawSec = asset.duration.seconds
    let hitDurationUs: Int64 = (rawSec.isFinite && rawSec > 0)
      ? min(max(1, Int64(rawSec * 1_000_000)), 5_000_000)
      : 100_000
    let starts = hitEventTimesUs.map { $0 - timelineStartUs }.sorted()
    var availableAt = Array(repeating: Int64.min, count: 6)
    var tracks: [AVMutableCompositionTrack] = []
    var trackEvents: [[(Int64, Float)]] = Array(repeating: [], count: 6)
    for (eventIndex, startUs) in starts.enumerated() {
      if eventIndex & 63 == 0, isCancelled() {
        throw IOSExportError(code: "cancelled", message: "Video export was cancelled.")
      }
      if startUs >= Int64(totalDuration.seconds * 1_000_000) { break }
      let slot = availableAt.firstIndex(where: { $0 <= startUs })
        ?? availableAt.enumerated().min(by: { $0.element < $1.element })!.offset
      while tracks.count <= slot {
        if let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
          tracks.append(track)
        }
      }
      let targetStartUs = max(0, startUs)
      let sourceStartUs = max(0, -startUs)
      let remainingUs = Int64(totalDuration.seconds * 1_000_000) - targetStartUs
      let insertUs = min(hitDurationUs - sourceStartUs, remainingUs)
      if insertUs > 0 {
        try tracks[slot].insertTimeRange(
          CMTimeRange(
            start: CMTime(value: sourceStartUs, timescale: 1_000_000),
            duration: CMTime(value: insertUs, timescale: 1_000_000)
          ),
          of: source,
          at: CMTime(value: targetStartUs, timescale: 1_000_000)
        )
        let overlap = max(1, upperBound(starts, startUs) - lowerBound(starts, startUs - hitDurationUs + 1))
        let gain = min(Float(1.0), Float(Double(hitSoundVolume) / sqrt(Double(overlap))))
        trackEvents[slot].append((targetStartUs, gain))
      }
      availableAt[slot] = startUs + hitDurationUs
    }
    for (index, track) in tracks.enumerated() {
      let parameters = AVMutableAudioMixInputParameters(track: track)
      for (timeUs, gain) in trackEvents[index] {
        parameters.setVolume(gain, at: CMTime(value: timeUs, timescale: 1_000_000))
      }
      mixParameters.append(parameters)
    }
  }

  private func addJudgementSounds(
    _ urls: [String: URL],
    events: [(timeUs: Int64, kind: String, volume: Float)],
    to composition: AVMutableComposition,
    totalDuration: CMTime,
    timelineStartUs: Int64,
    mixParameters: inout [AVMutableAudioMixInputParameters]
  ) throws {
    var sources: [String: (track: AVAssetTrack, durationUs: Int64)] = [:]
    for (kind, url) in urls {
      guard FileManager.default.fileExists(atPath: url.path) else { continue }
      let asset = AVURLAsset(url: url)
      guard let source = asset.tracks(withMediaType: .audio).first else { continue }
      let rawSec = asset.duration.seconds
      let durationUs: Int64 = (rawSec.isFinite && rawSec > 0)
        ? min(max(1, Int64(rawSec * 1_000_000)), 5_000_000)
        : 200_000
      sources[kind] = (track: source, durationUs: durationUs)
    }
    let sortedEvents = events
      .compactMap { event -> (startUs: Int64, kind: String, volume: Float)? in
        guard event.volume > 0, sources[event.kind] != nil else { return nil }
        return (startUs: event.timeUs - timelineStartUs, kind: event.kind, volume: event.volume.clamped(to: 0...3))
      }
      .sorted { $0.startUs < $1.startUs }
    guard !sortedEvents.isEmpty else { return }

    let starts = sortedEvents.map(\.startUs)
    let totalDurationUs = Int64(totalDuration.seconds * 1_000_000)
    let overlapWindowUs: Int64 = 80_000
    var availableAt = Array(repeating: Int64.min, count: 12)
    var tracks: [AVMutableCompositionTrack] = []
    var trackEvents: [[(Int64, Float)]] = Array(repeating: [], count: 12)

    for (eventIndex, item) in sortedEvents.enumerated() {
      if eventIndex & 63 == 0, isCancelled() {
        throw IOSExportError(code: "cancelled", message: "Video export was cancelled.")
      }
      if item.startUs >= totalDurationUs { break }
      guard let info = sources[item.kind] else { continue }
      let slot = availableAt.firstIndex(where: { $0 <= item.startUs })
        ?? availableAt.enumerated().min(by: { $0.element < $1.element })!.offset
      while tracks.count <= slot {
        if let track = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
          tracks.append(track)
        }
      }
      let targetStartUs = max(0, item.startUs)
      let sourceStartUs = max(0, -item.startUs)
      let remainingUs = totalDurationUs - targetStartUs
      let insertUs = min(info.durationUs - sourceStartUs, remainingUs)
      if insertUs > 0 {
        try tracks[slot].insertTimeRange(
          CMTimeRange(
            start: CMTime(value: sourceStartUs, timescale: 1_000_000),
            duration: CMTime(value: insertUs, timescale: 1_000_000)
          ),
          of: info.track,
          at: CMTime(value: targetStartUs, timescale: 1_000_000)
        )
        let overlap = max(1, upperBound(starts, item.startUs) - lowerBound(starts, item.startUs - overlapWindowUs + 1))
        let gain = min(Float(1.0), Float(Double(item.volume) * 0.82 / sqrt(Double(overlap))))
        trackEvents[slot].append((targetStartUs, gain))
      }
      availableAt[slot] = item.startUs + info.durationUs
    }
    for (index, track) in tracks.enumerated() {
      let parameters = AVMutableAudioMixInputParameters(track: track)
      for (timeUs, gain) in trackEvents[index] {
        parameters.setVolume(gain, at: CMTime(value: timeUs, timescale: 1_000_000))
      }
      mixParameters.append(parameters)
    }
  }

  private func appendSamples(
    _ output: AVAssetReaderOutput,
    to input: AVAssetWriterInput,
    reader: AVAssetReader,
    group: DispatchGroup
  ) {
    group.enter()
    let queue = DispatchQueue(label: "dev.projectfukakai.simai_flutter.mux.\(UUID().uuidString)")
    var completed = false
    input.requestMediaDataWhenReady(on: queue) { [isCancelled] in
      if completed { return }
      while input.isReadyForMoreMediaData {
        if isCancelled() {
          completed = true
          reader.cancelReading()
          input.markAsFinished()
          group.leave()
          return
        }
        guard let sample = output.copyNextSampleBuffer() else {
          completed = true
          input.markAsFinished()
          group.leave()
          return
        }
        if !input.append(sample) {
          completed = true
          reader.cancelReading()
          input.markAsFinished()
          group.leave()
          return
        }
      }
    }
  }
}

private struct IOSExportError: Error {
  let code: String
  let message: String
}

private extension Dictionary where Key == String, Value == Any {
  func requiredInt(_ key: String) throws -> Int {
    guard let value = self[key] as? NSNumber else {
      throw IOSExportError(code: "invalid_argument", message: "Missing argument: \(key)")
    }
    return value.intValue
  }

  func requiredInt64(_ key: String) throws -> Int64 {
    guard let value = self[key] as? NSNumber else {
      throw IOSExportError(code: "invalid_argument", message: "Missing argument: \(key)")
    }
    return value.int64Value
  }

  func requiredDouble(_ key: String) throws -> Double {
    guard let value = self[key] as? NSNumber else {
      throw IOSExportError(code: "invalid_argument", message: "Missing argument: \(key)")
    }
    return value.doubleValue
  }

  func requiredString(_ key: String) throws -> String {
    guard let value = self[key] as? String else {
      throw IOSExportError(code: "invalid_argument", message: "Missing argument: \(key)")
    }
    return value
  }
}

private extension Comparable {
  func clamped(to range: ClosedRange<Self>) -> Self {
    min(max(self, range.lowerBound), range.upperBound)
  }
}

private func lowerBound(_ values: [Int64], _ target: Int64) -> Int {
  var low = 0
  var high = values.count
  while low < high {
    let middle = (low + high) >> 1
    if values[middle] < target { low = middle + 1 } else { high = middle }
  }
  return low
}

private func upperBound(_ values: [Int64], _ target: Int64) -> Int {
  var low = 0
  var high = values.count
  while low < high {
    let middle = (low + high) >> 1
    if values[middle] <= target { low = middle + 1 } else { high = middle }
  }
  return low
}
