import Flutter
import Network
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let photosChannel = FlutterMethodChannel(
      name: "com.example.app/photo_library",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
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
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    networkTypeChannel.setMethodCallHandler { call, result in
      guard call.method == "isCellularNetwork" else {
        result(FlutterMethodNotImplemented)
        return
      }
      Self.checkCellularNetwork(result: result)
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
