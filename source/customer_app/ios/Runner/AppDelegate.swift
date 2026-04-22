import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var orientationChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register the channel with a longer delay and retry logic
    var attempts = 0
    func registerChannel() {
      attempts += 1
      guard let controller = self.window?.rootViewController as? FlutterViewController else {
        if attempts < 50 {  // Retry for up to 5 seconds
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            registerChannel()
          }
        }
        return
      }
      
      NSLog("DeviceOrientation: Successfully registered channel on attempt \(attempts)")
      self.orientationChannel = FlutterMethodChannel(name: "device_orientation",
                                                     binaryMessenger: controller.binaryMessenger)
      self.orientationChannel?.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "getOrientation" {
          if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let orientation = windowScene.interfaceOrientation
            
            var orientationString: String
            switch orientation {
            case .portrait:
              orientationString = "portrait"
            case .portraitUpsideDown:
              orientationString = "portraitUpsideDown"
            case .landscapeLeft:
              orientationString = "landscapeLeft"
            case .landscapeRight:
              orientationString = "landscapeRight"
            default:
              orientationString = "unknown"
            }
            
            NSLog("DeviceOrientation: Returning \(orientationString)")
            result(orientationString)
          } else {
            result("unknown")
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      })
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      registerChannel()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

