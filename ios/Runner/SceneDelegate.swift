import Flutter
import UIKit

/// UIScene 生命周期入口。
///
/// Flutter 3.41 起 iOS 以 UIScene 生命周期启动；缺少 Scene 配置时系统在启动阶段抛
/// `__UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption` 并直接崩溃，表现为「打开即崩溃」。
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    for context in connectionOptions.urlContexts {
      _ = AppDelegate.handleIncomingImportURL(context.url)
    }
  }

  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    super.scene(scene, openURLContexts: URLContexts)
    for context in URLContexts {
      _ = AppDelegate.handleIncomingImportURL(context.url)
    }
  }
}
