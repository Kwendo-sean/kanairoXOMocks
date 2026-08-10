import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  private var screenshotChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "KanairoXOScreenshot") {
      screenshotChannel = FlutterMethodChannel(
        name: "com.kanairoxo.app/screenshots",
        binaryMessenger: registrar.messenger())

      NotificationCenter.default.addObserver(
        self,
        selector: #selector(userDidTakeScreenshot),
        name: UIApplication.userDidTakeScreenshotNotification,
        object: nil)
    }
  }

  @objc private func userDidTakeScreenshot() {
    screenshotChannel?.invokeMethod("screenshotTaken", arguments: nil)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}
