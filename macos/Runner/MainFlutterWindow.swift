import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var vpnManager: MacVpnManager?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Setup VPN platform channels
    setupVpnChannels(flutterViewController: flutterViewController)

    super.awakeFromNib()
  }

  private func setupVpnChannels(flutterViewController: FlutterViewController) {
    print("🚀 Setting up macOS VPN platform channels...")

    // Setup method channel
    let methodChannel = FlutterMethodChannel(
      name: "fl_openvpn_client",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    // Setup event channel
    let eventChannel = FlutterEventChannel(
      name: "fl_openvpn_client/status",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    // Initialize VPN manager
    vpnManager = MacVpnManager(eventChannel: eventChannel)

    // Handle method calls
    methodChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleMethodCall(call: call, result: result)
    }

    print("✅ macOS VPN platform channels setup complete")
  }

  private func handleMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let vpnManager = vpnManager else {
      result(FlutterError(code: "NO_VPN_MANAGER", message: "VPN manager not initialized", details: nil))
      return
    }

    switch call.method {
    case "initialize":
      print("🔧 macOS VPN: Initialize called")
      vpnManager.initialize()
      result(true)

    case "connect":
      print("🔗 macOS VPN: Connect called")
      guard let args = call.arguments as? [String: Any],
            let config = args["config"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid connect arguments", details: nil))
        return
      }

      let username = args["username"] as? String
      let password = args["password"] as? String
      let serverName = args["serverName"] as? String

      vpnManager.connect(config: config, username: username, password: password, serverName: serverName) { success in
        result(success)
      }

    case "disconnect":
      print("🔌 macOS VPN: Disconnect called")
      vpnManager.disconnect { success in
        result(success)
      }

    case "hasPermission":
      print("🔐 macOS VPN: Permission check called")
      result(true) // macOS NetworkExtension handles permissions automatically

    case "requestPermission":
      print("🔐 macOS VPN: Permission request called")
      result(true) // macOS NetworkExtension handles permissions automatically

    case "getConnectionStats":
      print("📊 macOS VPN: Stats request called")
      result(vpnManager.getConnectionStats())

    case "dispose":
      print("🧹 macOS VPN: Dispose called")
      vpnManager.dispose()
      result(true)

    default:
      print("❓ macOS VPN: Unknown method: \(call.method)")
      result(FlutterMethodNotImplemented)
    }
  }
}
