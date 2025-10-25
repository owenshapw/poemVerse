import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 禁用性能分析以避免CA事件错误
    UserDefaults.standard.set(false, forKey: "CAReportingEnabled")
    UserDefaults.standard.set(false, forKey: "CALaunchReportingEnabled")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    // 确保无障碍功能正确初始化
    if UIAccessibility.isVoiceOverRunning {
      UIAccessibility.post(notification: .screenChanged, argument: nil)
    }
  }
}
