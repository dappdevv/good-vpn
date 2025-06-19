import Foundation
import NetworkExtension
import FlutterMacOS
import Security
import ServiceManagement

// C interface to OpenVPN library
typealias OpenVPNClientPtr = OpaquePointer

@_silgen_name("openvpn_client_create")
func openvpn_client_create() -> OpenVPNClientPtr?

@_silgen_name("openvpn_client_destroy")
func openvpn_client_destroy(_ client: OpenVPNClientPtr)

@_silgen_name("openvpn_client_connect")
func openvpn_client_connect(_ client: OpenVPNClientPtr, _ config: UnsafePointer<CChar>, _ username: UnsafePointer<CChar>?, _ password: UnsafePointer<CChar>?) -> Bool

@_silgen_name("openvpn_client_disconnect")
func openvpn_client_disconnect(_ client: OpenVPNClientPtr)

@_silgen_name("openvpn_client_get_status")
func openvpn_client_get_status(_ client: OpenVPNClientPtr) -> UnsafePointer<CChar>?

@_silgen_name("openvpn_client_is_available")
func openvpn_client_is_available() -> Bool

@_silgen_name("openvpn_client_get_bytes_in")
func openvpn_client_get_bytes_in(_ client: OpenVPNClientPtr) -> UInt64

@_silgen_name("openvpn_client_get_bytes_out")
func openvpn_client_get_bytes_out(_ client: OpenVPNClientPtr) -> UInt64

@_silgen_name("openvpn_client_get_duration")
func openvpn_client_get_duration(_ client: OpenVPNClientPtr) -> UInt64

@_silgen_name("openvpn_client_get_server_ip")
func openvpn_client_get_server_ip(_ client: OpenVPNClientPtr) -> UnsafePointer<CChar>?

@_silgen_name("openvpn_client_get_local_ip")
func openvpn_client_get_local_ip(_ client: OpenVPNClientPtr) -> UnsafePointer<CChar>?

// Stats structure matching C interface
struct ConnectionStatsC {
    let bytesIn: UInt64
    let bytesOut: UInt64
    let duration: UInt64
    let serverIp: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)
    let localIp: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar)
}

@_silgen_name("openvpn_client_get_stats")
func openvpn_client_get_stats(_ client: OpenVPNClientPtr) -> ConnectionStatsC

class MacVpnManager: NSObject {
    private var vpnManager: NEVPNManager?
    private var eventSink: FlutterEventSink?
    private var isConnected = false
    private var connectedAt: Date?
    private var currentServerIp: String?
    private var bytesIn: Int64 = 0
    private var bytesOut: Int64 = 0
    private var openvpnClient: OpenVPNClientPtr?
    private var useOpenVPN = false
    private var authorizationRef: AuthorizationRef?
    
    init(eventChannel: FlutterEventChannel) {
        super.init()

        eventChannel.setStreamHandler(self)
        vpnManager = NEVPNManager.shared()

        // Check if OpenVPN library is available
        if openvpn_client_is_available() {
            openvpnClient = openvpn_client_create()
            useOpenVPN = (openvpnClient != nil)
            print("✅ OpenVPN library available and initialized")
        } else {
            useOpenVPN = false
            print("❌ OpenVPN library not available, falling back to IKEv2")
        }

        // Observe VPN status changes (for IKEv2 fallback)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusChanged),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

    deinit {
        if let client = openvpnClient {
            openvpn_client_destroy(client)
        }

        // Clean up authorization
        if let authRef = authorizationRef {
            AuthorizationFree(authRef, AuthorizationFlags())
        }
    }

    func initialize() {
        // Request administrator privileges once during initialization
        print("🔐 Requesting administrator privileges during app initialization...")
        if requestAdministratorPrivileges() {
            print("✅ Administrator privileges granted during initialization")
        } else {
            print("❌ Failed to obtain administrator privileges during initialization")
        }

        vpnManager?.loadFromPreferences { [weak self] error in
            if let error = error {
                print("Failed to load VPN preferences: \(error)")
                self?.updateStatus(state: "error", message: "Failed to initialize: \(error.localizedDescription)")
            } else {
                self?.updateStatus(state: "disconnected", message: "VPN initialized")
            }
        }
    }

    private func requestAdministratorPrivileges() -> Bool {
        // Check if we already have valid authorization
        if let existingAuth = authorizationRef {
            print("🔐 Checking existing administrator privileges...")

            // Test if the existing authorization is still valid
            let rightName = kAuthorizationRightExecute
            let testResult = rightName.withCString { namePtr in
                var authItem = AuthorizationItem(
                    name: namePtr,
                    valueLength: 0,
                    value: nil,
                    flags: 0
                )

                return withUnsafePointer(to: &authItem) { itemPtr in
                    var authRights = AuthorizationRights(count: 1, items: UnsafeMutablePointer(mutating: itemPtr))

                    // Test authorization without UI (no interaction)
                    let authFlags: AuthorizationFlags = [.extendRights]
                    let authStatus = AuthorizationCopyRights(existingAuth, &authRights, nil, authFlags, nil)

                    return authStatus == errAuthorizationSuccess
                }
            }

            if testResult {
                print("✅ Existing administrator privileges are still valid")
                return true
            } else {
                print("⚠️ Existing administrator privileges expired, requesting new ones...")
                // Clean up expired authorization
                AuthorizationFree(existingAuth, AuthorizationFlags())
                authorizationRef = nil
            }
        }

        print("🔐 Requesting new administrator privileges for TUN interface creation...")

        var authRef: AuthorizationRef?
        let status = AuthorizationCreate(nil, nil, AuthorizationFlags(), &authRef)

        guard status == errAuthorizationSuccess else {
            print("❌ Failed to create authorization reference: \(status)")
            return false
        }

        // Define the right we need (system.privilege.admin)
        let rightName = kAuthorizationRightExecute
        return rightName.withCString { namePtr in
            var authItem = AuthorizationItem(
                name: namePtr,
                valueLength: 0,
                value: nil,
                flags: 0
            )

            return withUnsafePointer(to: &authItem) { itemPtr in
                var authRights = AuthorizationRights(count: 1, items: UnsafeMutablePointer(mutating: itemPtr))

                // Request authorization with UI
                let authFlags: AuthorizationFlags = [.interactionAllowed, .preAuthorize, .extendRights]
                let authStatus = AuthorizationCopyRights(authRef!, &authRights, nil, authFlags, nil)

                if authStatus == errAuthorizationSuccess {
                    print("✅ Administrator privileges granted")
                    self.authorizationRef = authRef
                    return true
                } else {
                    print("❌ Administrator privileges denied: \(authStatus)")
                    if let authRef = authRef {
                        AuthorizationFree(authRef, AuthorizationFlags())
                    }
                    return false
                }
            }
        }
    }
    
    func connect(config: String, username: String?, password: String?, serverName: String?, completion: @escaping (Bool) -> Void) {
        print("🚀 macOS VPN: Starting connection to real OpenVPN server")
        print("📄 Config name: \(serverName ?? "Unknown")")

        if useOpenVPN, let client = openvpnClient {
            print("✅ Using real OpenVPN library for connection")

            // Check if we have administrator privileges (should have been obtained during initialization)
            if authorizationRef == nil {
                print("⚠️ No administrator privileges available, requesting...")
                updateStatus(state: "connecting", message: "Requesting administrator privileges...")

                guard requestAdministratorPrivileges() else {
                    print("❌ Administrator privileges required for TUN interface creation")
                    updateStatus(state: "error", message: "Administrator privileges required for VPN connection")
                    completion(false)
                    return
                }
            } else {
                print("✅ Administrator privileges already available")
            }

            updateStatus(state: "connecting", message: "Initializing OpenVPN connection...")

            // Parse server info for display
            let serverInfo = parseServerInfo(from: config)
            currentServerIp = serverInfo.server

            // Use real OpenVPN library
            let result = config.withCString { configPtr in
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

            if result {
                print("✅ OpenVPN connection initiated successfully")
                isConnected = true
                connectedAt = Date()
                updateStatus(state: "connected", message: "OpenVPN connection established")
                completion(true)
            } else {
                print("❌ OpenVPN connection failed")
                updateStatus(state: "error", message: "OpenVPN connection failed")
                completion(false)
            }
            return
        }

        // Fallback to IKEv2 (original code)
        guard vpnManager != nil else {
            print("❌ VPN manager not available")
            completion(false)
            return
        }

        updateStatus(state: "connecting", message: "Requesting VPN permission...")

        // First, load existing preferences to check permissions
        vpnManager?.loadFromPreferences { [weak self] error in
            if let error = error {
                print("❌ Failed to load VPN preferences: \(error)")
                self?.updateStatus(state: "error", message: "Permission denied: \(error.localizedDescription)")
                completion(false)
                return
            }

            self?.configureAndConnect(config: config, username: username, password: password, serverName: serverName, completion: completion)
        }
    }

    private func configureAndConnect(config: String, username: String?, password: String?, serverName: String?, completion: @escaping (Bool) -> Void) {
        guard let vpnManager = vpnManager else {
            completion(false)
            return
        }

        updateStatus(state: "connecting", message: "Parsing OpenVPN configuration...")

        // Parse server info from OpenVPN config
        let serverInfo = parseServerInfo(from: config)
        currentServerIp = serverInfo.server

        print("🌐 Parsed server: \(serverInfo.server):\(serverInfo.port)")
        print("❌ PROTOCOL MISMATCH: OpenVPN server detected, but macOS NetworkExtension only supports IKEv2/IPSec")
        print("💡 SOLUTION: Use the system OpenVPN client instead:")
        print("   sudo /usr/local/opt/openvpn/sbin/openvpn --config your_config.ovpn")
        print("🔧 This app currently uses NetworkExtension IKEv2 (incompatible with OpenVPN servers)")

        updateStatus(state: "error", message: "❌ Protocol Mismatch: OpenVPN server requires OpenVPN client, not IKEv2. Use system OpenVPN client: 'sudo /usr/local/opt/openvpn/sbin/openvpn --config vm02.ovpn'")
        completion(false)
    }

    private func configureAndConnectIKEv2(config: String, username: String?, password: String?, serverName: String?, completion: @escaping (Bool) -> Void) {
        guard let vpnManager = vpnManager else {
            completion(false)
            return
        }

        // Parse server info from OpenVPN config
        let serverInfo = parseServerInfo(from: config)
        currentServerIp = serverInfo.server

        // The following IKEv2 code is kept for reference but won't work with OpenVPN servers
        let vpnProtocol = NEVPNProtocolIKEv2()
        vpnProtocol.serverAddress = serverInfo.server
        vpnProtocol.remoteIdentifier = serverInfo.server
        vpnProtocol.localIdentifier = username ?? "flutter_client"

        // Use shared secret authentication (most compatible for IKEv2)
        vpnProtocol.authenticationMethod = .sharedSecret

        // Set up extended authentication with username/password if provided
        if let username = username, let password = password {
            vpnProtocol.useExtendedAuthentication = true
            vpnProtocol.username = username
            vpnProtocol.passwordReference = storePassword(password: password)
        } else {
            vpnProtocol.useExtendedAuthentication = false
        }
        vpnProtocol.disconnectOnSleep = false

        vpnManager.protocolConfiguration = vpnProtocol
        vpnManager.localizedDescription = serverName ?? "Flutter OpenVPN Client"
        vpnManager.isEnabled = true

        print("💾 Saving VPN configuration...")
        updateStatus(state: "connecting", message: "Saving VPN configuration...")

        vpnManager.saveToPreferences { [weak self] error in
            if let error = error {
                print("❌ Failed to save VPN configuration: \(error)")
                let errorMessage = error.localizedDescription.lowercased()

                if errorMessage.contains("missing identity") || errorMessage.contains("identity") {
                    self?.updateStatus(state: "error", message: "Code signing issue: This app needs to be signed with a valid developer certificate to use VPN features.")
                    print("💡 Solution: This is expected in development. VPN features require proper code signing.")
                } else if errorMessage.contains("permission") || errorMessage.contains("denied") {
                    self?.updateStatus(state: "error", message: "VPN permission denied. Please allow VPN access in System Preferences.")
                } else if errorMessage.contains("entitlement") {
                    self?.updateStatus(state: "error", message: "Missing VPN entitlements. App needs NetworkExtension entitlements.")
                } else {
                    self?.updateStatus(state: "error", message: "Configuration failed: \(error.localizedDescription)")
                }
                completion(false)
                return
            }

            print("✅ VPN configuration saved successfully")

            vpnManager.loadFromPreferences { [weak self] error in
                if let error = error {
                    print("❌ Failed to reload VPN configuration: \(error)")
                    self?.updateStatus(state: "error", message: "Configuration reload failed: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                print("🚀 Starting VPN tunnel...")
                self?.updateStatus(state: "connecting", message: "Starting VPN tunnel to \(self?.currentServerIp ?? "server")...")

                do {
                    try vpnManager.connection.startVPNTunnel()
                    print("✅ VPN tunnel start command sent")
                    completion(true)
                } catch {
                    print("❌ Failed to start VPN: \(error)")
                    let errorMessage = error.localizedDescription.lowercased()

                    if errorMessage.contains("missing identity") || errorMessage.contains("identity") {
                        self?.updateStatus(state: "error", message: "Code signing issue: VPN requires valid developer certificate.")
                        print("💡 This is expected in development without proper code signing.")
                    } else if errorMessage.contains("permission") || errorMessage.contains("denied") {
                        self?.updateStatus(state: "error", message: "VPN permission denied. Please allow VPN access in System Preferences.")
                    } else if errorMessage.contains("entitlement") {
                        self?.updateStatus(state: "error", message: "Missing VPN entitlements.")
                    } else {
                        self?.updateStatus(state: "error", message: "Failed to start VPN: \(error.localizedDescription)")
                    }
                    completion(false)
                }
            }
        }
    }
    
    func disconnect(completion: @escaping (Bool) -> Void) {
        if useOpenVPN, let client = openvpnClient {
            print("🔌 Disconnecting OpenVPN...")
            updateStatus(state: "disconnecting", message: "Disconnecting OpenVPN...")

            openvpn_client_disconnect(client)
            isConnected = false
            connectedAt = nil
            updateStatus(state: "disconnected", message: "OpenVPN disconnected")
            completion(true)
            return
        }

        // Fallback to IKEv2
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

        if useOpenVPN, let client = openvpnClient {
            // Get real stats from OpenVPN client
            let realStats = getRealOpenVPNStats(client: client)
            return realStats
        } else {
            // Fallback to IKEv2 stats (legacy)
            let duration = connectedAt?.timeIntervalSinceNow.magnitude ?? 0
            return [
                "bytesIn": bytesIn,
                "bytesOut": bytesOut,
                "duration": Int(duration),
                "serverIp": currentServerIp ?? "",
                "localIp": getLocalIPAddress() ?? ""
            ]
        }
    }

    private func getRealOpenVPNStats(client: OpenVPNClientPtr) -> [String: Any] {
        let bytesIn = openvpn_client_get_bytes_in(client)
        let bytesOut = openvpn_client_get_bytes_out(client)
        let duration = openvpn_client_get_duration(client)

        var serverIp = ""
        if let serverIpPtr = openvpn_client_get_server_ip(client) {
            serverIp = String(cString: serverIpPtr)
        }

        var localIp = ""
        if let localIpPtr = openvpn_client_get_local_ip(client) {
            localIp = String(cString: localIpPtr)
        }

        print("📊 Real connection stats: bytesIn=\(bytesIn), bytesOut=\(bytesOut), duration=\(duration), serverIp=\(serverIp), localIp=\(localIp)")

        return [
            "bytesIn": Int64(bytesIn),
            "bytesOut": Int64(bytesOut),
            "duration": Int64(duration),
            "serverIp": serverIp,
            "localIp": localIp.isEmpty ? (getLocalIPAddress() ?? "") : localIp
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

extension MacVpnManager: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}
