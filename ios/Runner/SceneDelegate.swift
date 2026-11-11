import Flutter
import UIKit

/// UIScene 生命周期入口。
///
/// Flutter 3.41 起 iOS 以 UIScene 生命周期启动；缺少 Scene 配置时系统在启动阶段抛
/// `__UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption` 并直接崩溃，表现为「打开即崩溃」。
class SceneDelegate: FlutterSceneDelegate {

}
