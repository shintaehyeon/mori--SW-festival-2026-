import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let defines = (Bundle.main.object(forInfoDictionaryKey: "MoriDartDefines") as? String ?? "").split(separator: ",")
    for define in defines {
      if let bytes = Data(base64Encoded: String(define)),
         let value = String(data: bytes, encoding: .utf8),
         value.hasPrefix("GOOGLE_MAPS_API_KEY=") {
        let key = String(value.dropFirst("GOOGLE_MAPS_API_KEY=".count))
        if !key.isEmpty { GMSServices.provideAPIKey(key) }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
