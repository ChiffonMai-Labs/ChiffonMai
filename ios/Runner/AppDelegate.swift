import Flutter
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
