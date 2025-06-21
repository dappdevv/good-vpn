import Foundation
import NetworkExtension
import Flutter

// OpenVPN3 Core C++ bindings for iOS
@_silgen_name("openvpn_client_create")
func openvpn_client_create() -> OpaquePointer?

@_silgen_name("openvpn_client_destroy")
func openvpn_client_destroy(_ client: OpaquePointer)

@_silgen_name("openvpn_client_connect")
func openvpn_client_connect(_ client: OpaquePointer, _ config: UnsafePointer<CChar>, _ username: UnsafePointer<CChar>?, _ password: UnsafePointer<CChar>?) -> Bool

@_silgen_name("openvpn_client_disconnect")
func openvpn_client_disconnect(_ client: OpaquePointer)

@_silgen_name("openvpn_client_is_connected")
func openvpn_client_is_connected(_ client: OpaquePointer) -> Bool

@_silgen_name("openvpn_client_get_status")
func openvpn_client_get_status(_ client: OpaquePointer) -> UnsafePointer<CChar>?

@_silgen_name("openvpn_client_get_bytes_in")
func openvpn_client_get_bytes_in(_ client: OpaquePointer) -> UInt64

@_silgen_name("openvpn_client_get_bytes_out")
func openvpn_client_get_bytes_out(_ client: OpaquePointer) -> UInt64

@_silgen_name("openvpn_client_is_available")
func openvpn_client_is_available() -> Bool

@_silgen_name("openvpn_client_get_local_ip")
func openvpn_client_get_local_ip(_ client: OpaquePointer) -> UnsafePointer<CChar>?

class IosVpnManager: NSObject {
    private var openvpnClient: OpaquePointer?
    private var vpnManager: NETunnelProviderManager?
    private var eventSink: FlutterEventSink?
    private var statusTimer: Timer?
    private var connectedAt: Date?
    private var currentServerIp: String?
    private var bytesIn: Int64 = 0
    private var bytesOut: Int64 = 0
    private var vpnLocalIp: String?
    
    private var isConnected: Bool {
        guard let client = openvpnClient else { return false }
        return openvpn_client_is_connected(client)
    }
    
    override init() {
        super.init()
        initializeOpenVPN()
        setupVPNManager()
        setupNotifications()
        print("🔧 iOS VPN Manager initialized with OpenVPN3 Core + Packet Tunnel Provider")
    }
    
    private func initializeOpenVPN() {
        if openvpn_client_is_available() {
            openvpnClient = openvpn_client_create()
            if openvpnClient != nil {
                print("✅ OpenVPN3 Core client created successfully for iOS")
            } else {
                print("❌ Failed to create OpenVPN3 Core client")
            }
        } else {
            print("❌ OpenVPN3 Core library not available")
        }
    }
    
    private func setupVPNManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            if let error = error {
                print("⚠️ Failed to load tunnel providers: \(error)")
                return
            }
            
            // Find existing OpenVPN tunnel provider or create new one
            if let existingManager = managers?.first(where: { $0.localizedDescription == "OpenVPN Client" }) {
                self?.vpnManager = existingManager
                print("✅ Found existing OpenVPN Tunnel Provider")
            } else {
                self?.createTunnelProvider()
            }
        }
    }
    
    private func createTunnelProvider() {
        let manager = NETunnelProviderManager()
        
        // Configure OpenVPN3 Core Packet Tunnel Provider
        let providerProtocol = NETunnelProviderProtocol()
        providerProtocol.providerBundleIdentifier = "com.example.flOpenvpnClient.PacketTunnel"
        providerProtocol.serverAddress = "OpenVPN3 Core"
        providerProtocol.providerConfiguration = [
            "openvpn_core": "enabled",
            "tunnel_type": "openvpn3"
        ]
        
        manager.protocolConfiguration = providerProtocol
        manager.localizedDescription = "OpenVPN Client"
        manager.isEnabled = true
        
        manager.saveToPreferences { [weak self] error in
            if let error = error {
                print("⚠️ Failed to save tunnel provider: \(error)")
            } else {
                print("✅ OpenVPN3 Tunnel Provider created and saved")
                self?.vpnManager = manager
            }
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusChanged),
            name: .NEVPNStatusDidChange,
            object: nil
        )
        print("✅ VPN Status notifications setup for OpenVPN3 Core integration")
    }
    
    @objc private func vpnStatusChanged() {
        guard let vpnManager = vpnManager else { return }
        
        let status = vpnManager.connection.status
        print("📡 OpenVPN3 Tunnel Status changed: \(status.rawValue)")
        
        switch status {
        case .connected:
            print("✅ OpenVPN3 Tunnel connected - VPN icon should be visible")
        case .connecting:
            print("🔄 OpenVPN3 Tunnel connecting...")
        case .disconnected:
            print("📱 OpenVPN3 Tunnel disconnected")
        case .disconnecting:
            print("🔄 OpenVPN3 Tunnel disconnecting...")
        default:
            print("📡 OpenVPN3 Tunnel status: \(status)")
        }
    }
    
    private func startStatusUpdates() {
        statusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateConnectionStats()
        }
    }
    
    private func stopStatusUpdates() {
        statusTimer?.invalidate()
        statusTimer = nil
    }
    
    private func updateConnectionStats() {
        guard let client = openvpnClient, isConnected else { return }
        
        bytesIn = Int64(openvpn_client_get_bytes_in(client))
        bytesOut = Int64(openvpn_client_get_bytes_out(client))
        
        // Get VPN tunnel IP from OpenVPN3 Core
        if let localIpPtr = openvpn_client_get_local_ip(client) {
            vpnLocalIp = String(cString: localIpPtr)
        }
        
        let duration = connectedAt?.timeIntervalSinceNow.magnitude ?? 0
        
        // Get status from OpenVPN3 Core
        var statusMessage = "Connected"
        if let statusPtr = openvpn_client_get_status(client) {
            statusMessage = String(cString: statusPtr)
        }
        
        updateStatus(
            state: "connected",
            message: statusMessage,
            serverIp: currentServerIp,
            localIp: vpnLocalIp ?? getVPNTunnelIP(),
            bytesIn: bytesIn,
            bytesOut: bytesOut,
            duration: Int(duration)
        )
    }
    
    func connect(config: String, username: String?, password: String?, serverName: String?, completion: @escaping (Bool) -> Void) {
        print("🔗 Starting iOS OpenVPN3 Core connection with Packet Tunnel Provider...")
        
        guard let client = openvpnClient else {
            print("❌ OpenVPN3 client not available")
            updateStatus(state: "error", message: "OpenVPN3 client not initialized")
            completion(false)
            return
        }
        
        // Parse server info from config
        let serverInfo = parseServerInfo(from: config)
        currentServerIp = serverInfo.server
        
        updateStatus(state: "connecting", message: "Connecting with OpenVPN3 Core...")
        
        // Start OpenVPN3 Core connection
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let success = config.withCString { configPtr in
                if let username = username, let password = password {
                    return username.withCString { usernamePtr in
                        return password.withCString { passwordPtr in
                            return openvpn_client_connect(client, configPtr, usernamePtr, passwordPtr)
                        }
                    }
                } else {
                    return openvpn_client_connect(client, configPtr, nil, nil)
                }
            }
            
            DispatchQueue.main.async {
                if success {
                    print("✅ OpenVPN3 Core connection initiated successfully")
                    self?.connectedAt = Date()
                    self?.updateStatus(state: "connecting", message: "Authenticating...")
                    self?.startStatusUpdates()
                    
                    // Start tunnel provider for VPN icon
                    self?.startTunnelProvider(config: config, username: username, password: password)
                    
                    completion(true)
                } else {
                    print("❌ OpenVPN3 Core connection failed")
                    self?.updateStatus(state: "error", message: "OpenVPN connection failed")
                    completion(false)
                }
            }
        }
    }
    
    private func startTunnelProvider(config: String, username: String?, password: String?) {
        guard let vpnManager = vpnManager else {
            print("⚠️ No tunnel provider available")
            return
        }
        
        vpnManager.loadFromPreferences { [weak self] error in
            if let error = error {
                print("⚠️ Failed to load tunnel provider: \(error)")
                return
            }
            
            // Configure tunnel options for OpenVPN3 Core
            var options: [String: NSObject] = [
                "config": config as NSString,
                "openvpn3_core": true as NSNumber
            ]
            
            if let username = username {
                options["username"] = username as NSString
            }
            if let password = password {
                options["password"] = password as NSString
            }
            
            do {
                try vpnManager.connection.startVPNTunnel(options: options)
                print("📱 OpenVPN3 Tunnel Provider started - VPN icon should appear")
            } catch {
                print("⚠️ Failed to start tunnel provider: \(error)")
                // This might fail on simulator, but will work on device
                if error.localizedDescription.contains("simulator") {
                    print("📱 Tunnel provider start failed on simulator (expected)")
                }
            }
        }
    }
    
    func disconnect(completion: @escaping (Bool) -> Void) {
        print("🔌 Disconnecting from iOS OpenVPN3 Core connection")
        
        // Stop tunnel provider
        if let vpnManager = vpnManager {
            vpnManager.connection.stopVPNTunnel()
            print("📱 OpenVPN3 Tunnel Provider stopped")
        }
        
        guard let client = openvpnClient else {
            completion(false)
            return
        }
        
        updateStatus(state: "disconnecting", message: "Disconnecting...")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            openvpn_client_disconnect(client)
            
            DispatchQueue.main.async {
                self?.connectedAt = nil
                self?.vpnLocalIp = nil
                self?.stopStatusUpdates()
                self?.updateStatus(state: "disconnected", message: "Disconnected")
                completion(true)
            }
        }
    }
    
    func getConnectionStats() -> [String: Any]? {
        guard isConnected else { return nil }
        
        let duration = connectedAt?.timeIntervalSinceNow.magnitude ?? 0
        
        return [
            "bytesIn": bytesIn,
            "bytesOut": bytesOut,
            "duration": Int(duration),
            "serverIp": currentServerIp ?? "",
            "localIp": vpnLocalIp ?? getVPNTunnelIP() ?? ""
        ]
    }
    
    func dispose() {
        stopStatusUpdates()
        NotificationCenter.default.removeObserver(self)
        
        if let client = openvpnClient {
            openvpn_client_disconnect(client)
            openvpn_client_destroy(client)
            openvpnClient = nil
        }
        
        eventSink = nil
        print("🧹 iOS VPN Manager disposed")
    }
    
    private func updateStatus(state: String, message: String? = nil, serverIp: String? = nil, localIp: String? = nil, bytesIn: Int64? = nil, bytesOut: Int64? = nil, duration: Int? = nil) {
        var statusData: [String: Any] = ["state": state]
        
        if let message = message {
            statusData["message"] = message
        }
        if let serverIp = serverIp {
            statusData["serverIp"] = serverIp
        }
        if let localIp = localIp {
            statusData["localIp"] = localIp
        }
        if let bytesIn = bytesIn {
            statusData["bytesIn"] = bytesIn
        }
        if let bytesOut = bytesOut {
            statusData["bytesOut"] = bytesOut
        }
        if let duration = duration {
            statusData["duration"] = duration
        }
        if let connectedAt = connectedAt {
            statusData["connectedAt"] = Int(connectedAt.timeIntervalSince1970 * 1000)
        }
        
        eventSink?(statusData)
    }
    
    private func parseServerInfo(from config: String) -> (server: String, port: Int) {
        let lines = config.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("remote ") {
                let components = trimmedLine.components(separatedBy: " ")
                if components.count >= 2 {
                    let server = components[1]
                    let port = components.count >= 3 ? Int(components[2]) ?? 1194 : 1194
                    return (server: server, port: port)
                }
            }
        }
        return (server: "unknown", port: 1194)
    }
    
    private func getVPNTunnelIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                guard let interface = ptr?.pointee else { continue }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {  // Only IPv4 addresses
                    let name = String(cString: interface.ifa_name)
                    
                    // Look for VPN tunnel interfaces first
                    if name.hasPrefix("utun") || name.hasPrefix("tun") || name.hasPrefix("ppp") {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        let ip = String(cString: hostname)
                        
                        // Filter out invalid IPs
                        if !ip.hasPrefix("127.") && !ip.hasPrefix("169.254.") && ip != "0.0.0.0" {
                            print("🌐 Found VPN tunnel IP: \(ip) on interface \(name)")
                            address = ip
                            break // Prefer VPN tunnel interface
                        }
                    }
                }
            }
            
            // If no VPN tunnel IP found, look for any valid IPv4
            if address == nil {
                ptr = ifaddr
                while ptr != nil {
                    defer { ptr = ptr?.pointee.ifa_next }
                    
                    guard let interface = ptr?.pointee else { continue }
                    let addrFamily = interface.ifa_addr.pointee.sa_family
                    
                    if addrFamily == UInt8(AF_INET) {
                        let name = String(cString: interface.ifa_name)
                        
                        if name == "en0" || name == "en1" {  // WiFi/Ethernet interfaces
                            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                            getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                            let ip = String(cString: hostname)
                            
                            if !ip.hasPrefix("127.") && !ip.hasPrefix("169.254.") && ip != "0.0.0.0" {
                                print("🌐 Found local network IP: \(ip) on interface \(name)")
                                address = ip
                                break
                            }
                        }
                    }
                }
            }
            
            freeifaddrs(ifaddr)
        }
        
        return address
    }
}

// MARK: - FlutterStreamHandler
extension IosVpnManager: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
} 