import Flutter
import UIKit
import Vision

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
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MeowSkinScanInput")!
    let channel = FlutterMethodChannel(name: "meowskin/scan_input", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "faces" else { result(FlutterMethodNotImplemented); return }
      guard let args = call.arguments as? [String: Any],
            let bytes = args["bytes"] as? FlutterStandardTypedData else {
        result(FlutterError(code: "invalid-image", message: "Missing image", details: nil)); return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let request = VNDetectFaceRectanglesRequest()
          try VNImageRequestHandler(data: bytes.data, orientation: .up).perform([request])
          let faces = (request.results ?? []).map { face -> [String: Double] in
            return ["roll": (face.roll?.doubleValue ?? 0) * 180 / .pi,
                    "yaw": (face.yaw?.doubleValue ?? 0) * 180 / .pi,
                    "pitch": (face.pitch?.doubleValue ?? 0) * 180 / .pi,
                    "widthFraction": face.boundingBox.width]
          }
          DispatchQueue.main.async { result(faces) }
        } catch {
          DispatchQueue.main.async { result(FlutterError(code: "face-check-failed", message: "Cannot validate face", details: nil)) }
        }
      }
    }
  }
}
