import UIKit
import Flutter
import AVKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var pipController: AVPictureInPictureController?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "pip_channel", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "enterPip" {
        DispatchQueue.main.async {
          self?.startPiPIfPossible()
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func startPiPIfPossible() {
    // NOTE: This requires an AVPlayerLayer. If you load YouTube in WKWebView,
    // you might not have a direct AVPlayer. A robust approach: use native AVPlayer for playback
    // (youtube_player_iframe or youtube_extractor to get stream url) and attach to AVPlayerLayer here.
    if AVPictureInPictureController.isPictureInPictureSupported() {
      if let playerLayer = /* obtain your AVPlayerLayer */ nil {
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.startPictureInPicture()
      } else {
        // fallback: do nothing
      }
    }
  }
}
