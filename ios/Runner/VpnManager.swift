import Foundation
import NetworkExtension
import Flutter

class VpnManager: NSObject {
    private var vpnManager: NEVPNManager?
    private var eventSink: FlutterEventSink?
    private var isConnected = false
    private var connectedAt: Date?
    private var currentServerIp: String?
    private var bytesIn: Int64 = 0
    private var bytesOut: Int64 = 0
    
    init(eventChannel: FlutterEventChannel) {
        super.init()
        
        eventChannel.setStreamHandler(self)
        vpnManager = NEVPNManager.shared()
        
        // Observe VPN status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusChanged),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }
    
    func initialize() {
        vpnManager?.loadFromPreferences { [weak self] error in
            if let error = error {
                print("Failed to load VPN preferences: \(error)")
                self?.updateStatus(state: "error", message: "Failed to initialize: \(error.localizedDescription)")
            } else {
                self?.updateStatus(state: "disconnected", message: "VPN initialized")
            }
        }
    }
    
    func connect(config: String, username: String?, password: String?, serverName: String?, completion: @escaping (Bool) -> Void) {
        guard let vpnManager = vpnManager else {
            completion(false)
            return
        }
        
        updateStatus(state: "connecting", message: "Configuring VPN...")
        
        // Parse server info from config
        let serverInfo = parseServerInfo(from: config)
        currentServerIp = serverInfo.server
        
        // Configure VPN protocol
        let protocol = NEVPNProtocolIKEv2()
        protocol.serverAddress = serverInfo.server
        protocol.remoteIdentifier = serverInfo.server
        protocol.localIdentifier = username ?? "client"
        
        if let username = username, let password = password {
            protocol.authenticationMethod = .usernamePassword
            protocol.username = username
            protocol.passwordReference = storePassword(password: password)
        } else {
            protocol.authenticationMethod = .none
        }
        
        // Use IKEv2 for iOS (OpenVPN requires a custom network extension)
        protocol.useExtendedAuthentication = true
        protocol.disconnectOnSleep = false
        
        vpnManager.protocolConfiguration = protocol
        vpnManager.localizedDescription = serverName ?? "OpenVPN Client"
        vpnManager.isEnabled = true
        
        vpnManager.saveToPreferences { [weak self] error in
            if let error = error {
                print("Failed to save VPN configuration: \(error)")
                self?.updateStatus(state: "error", message: "Configuration failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            vpnManager.loadFromPreferences { [weak self] error in
                if let error = error {
                    print("Failed to reload VPN configuration: \(error)")
                    self?.updateStatus(state: "error", message: "Configuration reload failed: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                do {
                    try vpnManager.connection.startVPNTunnel()
                    self?.updateStatus(state: "connecting", message: "Starting VPN tunnel...")
                    completion(true)
                } catch {
                    print("Failed to start VPN: \(error)")
                    self?.updateStatus(state: "error", message: "Failed to start VPN: \(error.localizedDescription)")
                    completion(false)
                }
            }
        }
    }
    
    func disconnect(completion: @escaping (Bool) -> Void) {
        guard let vpnManager = vpnManager else {
            completion(false)
            return
        }
        
        updateStatus(state: "disconnecting", message: "Disconnecting...")
        vpnManager.connection.stopVPNTunnel()
        completion(true)
    }
    
    func getConnectionStats() -> [String: Any]? {
        guard isConnected else { return nil }
        
        let duration = connectedAt?.timeIntervalSinceNow.magnitude ?? 0
        
        return [
            "bytesIn": bytesIn,
            "bytesOut": bytesOut,
            "duration": Int(duration),
            "serverIp": currentServerIp ?? "",
            "localIp": getLocalIPAddress() ?? ""
        ]
    }
    
    func dispose() {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
    }
    
    @objc private func vpnStatusChanged() {
        guard let vpnManager = vpnManager else { return }
        
        switch vpnManager.connection.status {
        case .invalid:
            updateStatus(state: "error", message: "VPN configuration is invalid")
            isConnected = false
        case .disconnected:
            updateStatus(state: "disconnected", message: "Disconnected")
            isConnected = false
            connectedAt = nil
            bytesIn = 0
            bytesOut = 0
        case .connecting:
            updateStatus(state: "connecting", message: "Connecting...")
            isConnected = false
        case .connected:
            updateStatus(state: "connected", message: "Connected", serverIp: currentServerIp, localIp: getLocalIPAddress())
            isConnected = true
            connectedAt = Date()
        case .reasserting:
            updateStatus(state: "reconnecting", message: "Reconnecting...")
            isConnected = false
        case .disconnecting:
            updateStatus(state: "disconnecting", message: "Disconnecting...")
            isConnected = false
        @unknown default:
            updateStatus(state: "error", message: "Unknown VPN status")
            isConnected = false
        }
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
    
    private func storePassword(password: String) -> Data? {
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "vpn_password",
            kSecAttrService as String: "fl_openvpn_client",
            kSecValueData as String: passwordData
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            return passwordData
        } else {
            print("Failed to store password: \(status)")
            return nil
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" || name.hasPrefix("utun") {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                   &hostname, socklen_t(hostname.count),
                                   nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    private func updateStatus(state: String, message: String? = nil, serverIp: String? = nil, localIp: String? = nil) {
        let status: [String: Any?] = [
            "state": state,
            "message": message,
            "serverIp": serverIp ?? currentServerIp,
            "localIp": localIp,
            "bytesIn": isConnected ? bytesIn : nil,
            "bytesOut": isConnected ? bytesOut : nil,
            "duration": connectedAt != nil ? Int(connectedAt!.timeIntervalSinceNow.magnitude) : nil,
            "connectedAt": connectedAt != nil ? Int(connectedAt!.timeIntervalSince1970 * 1000) : nil
        ]
        
        eventSink?(status.compactMapValues { $0 })
    }
}

extension VpnManager: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
