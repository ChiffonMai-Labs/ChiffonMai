import Darwin
import Flutter
import Network
import Photos
import UIKit
import UserNotifications

// 信号处理器必须保持异步信号安全（禁止 Swift 对象分配、ARC 或格式化字符串）。
private var gCrashFilePath: UnsafeMutablePointer<CChar>?
private var gCrashFrames: UnsafeMutablePointer<UnsafeMutableRawPointer?>?
private var gCrashTimeBuf: UnsafeMutablePointer<CChar>?
private var gPreviousExceptionHandler: (@convention(c) (NSException) -> Void)?

private let gMonitoredCrashSignals: [Int32] = [
  SIGABRT,
  SIGILL,
  SIGSEGV,
  SIGFPE,
  SIGBUS,
  SIGTRAP,
]

private func writeStatic(_ fd: Int32, _ text: StaticString) {
  _ = Darwin.write(fd, text.utf8Start, text.utf8CodeUnitCount)
}

private func crashSignalReason(_ sig: Int32) -> StaticString {
  switch sig {
  case SIGABRT:
    return "原生异常终止 (SIGABRT)"
  case SIGILL:
    return "非法指令 (SIGILL)"
  case SIGSEGV:
    return "内存访问错误 (SIGSEGV)"
  case SIGFPE:
    return "算术异常 (SIGFPE)"
  case SIGBUS:
    return "总线错误 (SIGBUS)"
  case SIGTRAP:
    return "断点/陷阱异常 (SIGTRAP)"
  default:
    return "原生崩溃"
  }
}

private let chiffonCrashSignalHandler: @convention(c) (Int32) -> Void = { sig in
  if let path = gCrashFilePath, Darwin.access(path, F_OK) != 0 {
    let fd = Darwin.creat(path, mode_t(0o600))
    if fd >= 0 {
      let timestampMs = Int64(Darwin.time(nil)) * 1000
      if let timeBuf = gCrashTimeBuf {
        var remaining = timestampMs > 0 ? timestampMs : 0
        var index = 31
        repeat {
          index -= 1
          timeBuf[index] = CChar(48 + (remaining % 10))
          remaining /= 10
        } while remaining > 0 && index > 0
        _ = Darwin.write(fd, timeBuf.advanced(by: index), 31 - index)
      } else {
        writeStatic(fd, "0")
      }
      writeStatic(fd, "\n")
      writeStatic(fd, crashSignalReason(sig))
      writeStatic(fd, "\nBacktrace:\n")
      if let frames = gCrashFrames {
        let count = backtrace(frames, 64)
        if count > 0 {
          backtrace_symbols_fd(frames, count, fd)
        }
      }
      Darwin.close(fd)
    }
  }
  Darwin.signal(sig, SIG_DFL)
  Darwin.raise(sig)
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let maxImportBytes = 50 * 1024 * 1024
  private static let maxCrashDetailChars = 20000

  private static var crashReporterInstalled = false
  private static var openFileChannel: FlutterMethodChannel?
  private static var pendingImportPath: String?
  private static var dartImportReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    Self.installCrashReporter()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if Self.handleIncomingImportURL(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()

    let photosChannel = FlutterMethodChannel(
      name: "com.example.app/photo_library",
      binaryMessenger: messenger
    )
    photosChannel.setMethodCallHandler { call, result in
      guard call.method == "saveImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let arguments = call.arguments as? [String: Any],
            let path = arguments["path"] as? String,
            !path.isEmpty,
            FileManager.default.isReadableFile(atPath: path) else {
        result(FlutterError(code: "INVALID_FILE", message: nil, details: nil))
        return
      }
      Self.saveImageToPhotos(URL(fileURLWithPath: path), result: result)
    }

    let networkTypeChannel = FlutterMethodChannel(
      name: "com.example.app/network_type",
      binaryMessenger: messenger
    )
    networkTypeChannel.setMethodCallHandler { call, result in
      guard call.method == "isCellularNetwork" else {
        result(FlutterMethodNotImplemented)
        return
      }
      Self.checkCellularNetwork(result: result)
    }

    let openFileChannel = FlutterMethodChannel(
      name: "com.example.app/open_file",
      binaryMessenger: messenger
    )
    Self.openFileChannel = openFileChannel
    openFileChannel.setMethodCallHandler { call, result in
      guard call.method == "getInitialImportPath" else {
        result(FlutterMethodNotImplemented)
        return
      }
      Self.dartImportReady = true
      let initial = Self.pendingImportPath
      Self.pendingImportPath = nil
      result(initial)
    }

    let exportNotificationChannel = FlutterMethodChannel(
      name: "com.example.app/export_notification",
      binaryMessenger: messenger
    )
    exportNotificationChannel.setMethodCallHandler { call, result in
      guard call.method == "notifyExportDone" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any]
      let title = (args?["title"] as? String) ?? "导出完成"
      let text = (args?["text"] as? String) ?? ""
      Self.postLocalNotification(
        identifier: "chiffonmai.export.\(UUID().uuidString)",
        title: title,
        body: text,
        result: result
      )
    }

    let crashReportChannel = FlutterMethodChannel(
      name: "com.example.app/crash_report",
      binaryMessenger: messenger
    )
    crashReportChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "takePendingCrash":
        result(Self.takePendingCrash())
      case "notifyCrashReport":
        let args = call.arguments as? [String: Any]
        let title = (args?["title"] as? String) ?? "ChiffonMai 上次异常退出"
        let text = (args?["text"] as? String) ?? ""
        Self.postLocalNotification(
          identifier: "chiffonmai.crash.\(UUID().uuidString)",
          title: title,
          body: text,
          result: result
        )
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// 将「文件」App 或系统分享传来的 `.cmf` 收藏夹文件拷贝到临时目录后转发给 Dart。
  static func handleIncomingImportURL(_ url: URL) -> Bool {
    guard url.isFileURL, url.pathExtension.lowercased() == "cmf" else {
      return false
    }
    guard let localPath = copyIncomingFileToTemp(url) else {
      return false
    }
    let deliver = {
      pendingImportPath = localPath
      // 只有 Dart 注册就绪后才实时推送并清 pending；未就绪时留给 getInitialImportPath 取走。
      if dartImportReady, let channel = openFileChannel {
        channel.invokeMethod("onFileOpened", arguments: localPath)
        pendingImportPath = nil
      }
    }
    if Thread.isMainThread {
      deliver()
    } else {
      DispatchQueue.main.async(execute: deliver)
    }
    return true
  }

  private static func copyIncomingFileToTemp(_ url: URL) -> String? {
    let accessed = url.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let fm = FileManager.default
    let attrs = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
    if attrs?.isRegularFile == false {
      return nil
    }
    if let size = attrs?.fileSize, size > maxImportBytes {
      return nil
    }

    let rawName = url.lastPathComponent.isEmpty ? "favorites.cmf" : url.lastPathComponent
    let safeName = rawName.replacingOccurrences(
      of: #"[\\/:*?"<>|]"#,
      with: "_",
      options: .regularExpression
    )
    let importDir = fm.temporaryDirectory.appendingPathComponent("chiffonmai_imports", isDirectory: true)
    try? fm.createDirectory(at: importDir, withIntermediateDirectories: true)

    let ms = Int64(Date().timeIntervalSince1970 * 1000)
    let destURL = importDir.appendingPathComponent("\(ms)_\(safeName)")
    do {
      if fm.fileExists(atPath: destURL.path) {
        try fm.removeItem(at: destURL)
      }
      try fm.copyItem(at: url, to: destURL)
      if let copiedSize = (try? fm.attributesOfItem(atPath: destURL.path)[.size] as? NSNumber)?.intValue,
         copiedSize > maxImportBytes {
        try? fm.removeItem(at: destURL)
        return nil
      }
      return destURL.path
    } catch {
      return nil
    }
  }

  private static func pendingCrashFileURL() -> URL? {
    let fm = FileManager.default
    guard let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
      return nil
    }
    try? fm.createDirectory(at: supportDir, withIntermediateDirectories: true)
    return supportDir.appendingPathComponent("pending_crash.txt")
  }

  private static func installCrashReporter() {
    guard !crashReporterInstalled, let fileURL = pendingCrashFileURL() else {
      return
    }
    crashReporterInstalled = true

    gCrashFilePath = strdup(fileURL.path)
    gCrashFrames = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 64)
    gCrashTimeBuf = UnsafeMutablePointer<CChar>.allocate(capacity: 32)
    gPreviousExceptionHandler = NSGetUncaughtExceptionHandler()

    NSSetUncaughtExceptionHandler { exception in
      if let fileURL = AppDelegate.pendingCrashFileURL() {
        let ms = Int64(Date().timeIntervalSince1970 * 1000)
        let stack = exception.callStackSymbols.joined(separator: "\n")
        let detailRaw = "\(exception.name.rawValue): \(exception.reason ?? "")\n\(stack)"
        let detail = String(detailRaw.prefix(AppDelegate.maxCrashDetailChars))
        let payload = "\(ms)\n应用崩溃\n\(detail)"
        try? payload.write(to: fileURL, atomically: true, encoding: .utf8)
      }
      gPreviousExceptionHandler?(exception)
    }

    for sig in gMonitoredCrashSignals {
      Darwin.signal(sig, chiffonCrashSignalHandler)
    }
  }

  private static func takePendingCrash() -> [String: String]? {
    guard let fileURL = pendingCrashFileURL(),
          FileManager.default.fileExists(atPath: fileURL.path),
          let text = try? String(contentsOf: fileURL, encoding: .utf8) else {
      return nil
    }
    try? FileManager.default.removeItem(at: fileURL)
    let lines = text.split(separator: "\n", maxSplits: 2, omittingEmptySubsequences: false)
    let time = lines.count > 0 ? String(lines[0]) : "0"
    let reason = (lines.count > 1 && !lines[1].isEmpty) ? String(lines[1]) : "应用崩溃"
    let detail = lines.count > 2 ? String(lines[2].prefix(maxCrashDetailChars)) : ""
    return [
      "reason": reason,
      "time": time,
      "detail": detail,
    ]
  }

  private static func postLocalNotification(
    identifier: String,
    title: String,
    body: String,
    result: @escaping FlutterResult
  ) {
    func finish() {
      DispatchQueue.main.async { result(nil) }
    }

    let center = UNUserNotificationCenter.current()
    func schedule() {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      content.sound = .default
      let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
      center.add(request) { _ in
        finish()
      }
    }

    center.getNotificationSettings { settings in
      switch settings.authorizationStatus {
      case .authorized, .provisional, .ephemeral:
        schedule()
      case .notDetermined:
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
          if granted {
            schedule()
          } else {
            finish()
          }
        }
      default:
        finish()
      }
    }
  }

  /// 后台单次采样网络路径（400ms 超时兜底后立刻取消），判断是否仅走移动蜂窝网络。
  private static func checkCellularNetwork(result: @escaping FlutterResult) {
    if #available(iOS 12.0, *) {
      let monitor = NWPathMonitor()
      let queue = DispatchQueue(label: "com.example.app.network_type")
      let lock = NSLock()
      var finished = false

      func complete(_ isCellular: Bool) {
        lock.lock()
        if finished {
          lock.unlock()
          return
        }
        finished = true
        lock.unlock()
        monitor.pathUpdateHandler = nil
        monitor.cancel()
        DispatchQueue.main.async {
          result(isCellular)
        }
      }

      monitor.pathUpdateHandler = { path in
        let isCellular =
          path.usesInterfaceType(.cellular) &&
          !path.usesInterfaceType(.wifi) &&
          !path.usesInterfaceType(.wiredEthernet)
        complete(isCellular)
      }
      monitor.start(queue: queue)
      queue.asyncAfter(deadline: .now() + .milliseconds(400)) {
        complete(false)
      }
    } else {
      result(false)
    }
  }

  private static func saveImageToPhotos(_ file: URL, result: @escaping FlutterResult) {
    func finish(_ error: FlutterError?) {
      DispatchQueue.main.async { result(error) }
    }

    func writeAsset() {
      // 直接导入原始文件，保留 PNG/JPEG 编码和分辨率。
      PHPhotoLibrary.shared().performChanges({
        PHAssetCreationRequest.forAsset().addResource(with: .photo, fileURL: file, options: nil)
      }, completionHandler: { success, error in
        if success {
          finish(nil)
        } else {
          finish(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription, details: nil))
        }
      })
    }

    if #available(iOS 14, *) {
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        if status == .authorized || status == .limited {
          writeAsset()
        } else {
          finish(FlutterError(code: "PERMISSION_DENIED", message: nil, details: nil))
        }
      }
    } else {
      writeAsset()
    }
  }
}
