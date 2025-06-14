import Flutter
import UIKit
import NetworkExtension

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var vpnManager: VpnManager?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Set up VPN method channel
    if let controller = window?.rootViewController as? FlutterViewController {
      setupVpnChannel(controller: controller)
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupVpnChannel(controller: FlutterViewController) {
    let channel = FlutterMethodChannel(name: "fl_openvpn_client", binaryMessenger: controller.binaryMessenger)
    let eventChannel = FlutterEventChannel(name: "fl_openvpn_client/status", binaryMessenger: controller.binaryMessenger)

    vpnManager = VpnManager(eventChannel: eventChannel)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }

      switch call.method {
      case "initialize":
        self.vpnManager?.initialize()
        result(true)
      case "hasPermission":
        result(true) // iOS handles permissions differently
      case "requestPermission":
        result(true) // iOS handles permissions differently
      case "connect":
        if let args = call.arguments as? [String: Any],
           let config = args["config"] as? String {
          let username = args["username"] as? String
          let password = args["password"] as? String
          let serverName = args["serverName"] as? String

          self.vpnManager?.connect(config: config, username: username, password: password, serverName: serverName) { success in
            result(success)
          }
        } else {
          result(FlutterError(code: "INVALID_CONFIG", message: "Configuration is required", details: nil))
        }
      case "disconnect":
        self.vpnManager?.disconnect { success in
          result(success)
        }
      case "getConnectionStats":
        let stats = self.vpnManager?.getConnectionStats()
        result(stats)
      case "dispose":
        self.vpnManager?.dispose()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
