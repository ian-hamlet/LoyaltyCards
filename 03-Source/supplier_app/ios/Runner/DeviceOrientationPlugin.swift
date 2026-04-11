import Flutter
import UIKit

class DeviceOrientationPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "device_orientation", binaryMessenger: registrar.messenger())
    let instance = DeviceOrientationPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "getOrientation" {
      let orientation = UIDevice.current.orientation
      
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
      case .faceUp:
        orientationString = "faceUp"
      case .faceDown:
        orientationString = "faceDown"
      default:
        orientationString = "unknown"
      }
      
      result(orientationString)
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}
