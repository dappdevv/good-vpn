# 🐧 Linux OpenVPN Setup Guide (Future Implementation)

## 🎯 Overview

This guide outlines the planned setup process for the Linux version of the OpenVPN Flutter app. **Note: Linux implementation is not yet available but is planned for future development.**

## ⚠️ Current Status

- **Implementation Status**: 🟡 Planned (Not Yet Implemented)
- **Priority**: Future development phase
- **Estimated Timeline**: To be determined
- **Current Workaround**: Use existing Linux OpenVPN clients

## ✅ Prerequisites (When Implemented)

### Required Tools
- **Linux Distribution**: Ubuntu 20.04+, Fedora 35+, or equivalent
- **GCC/Clang**: Modern C++ compiler (GCC 9+ or Clang 10+)
- **CMake**: 3.16+ for native compilation
- **Flutter**: 3.32.4 or later
- **pkg-config**: For dependency management
- **Git**: For source code management

### System Requirements
- **Operating System**: Modern Linux distribution (64-bit)
- **Architecture**: x86_64 (ARM64 support planned)
- **RAM**: 4GB minimum, 8GB recommended
- **Storage**: 2GB free space for development tools
- **Root Access**: Required for VPN functionality (via sudo)

### Distribution-Specific Packages
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential cmake pkg-config git
sudo apt install libnl-3-dev libnl-genl-3-dev libssl-dev

# Fedora/RHEL
sudo dnf install gcc-c++ cmake pkg-config git
sudo dnf install libnl3-devel openssl-devel

# Arch Linux
sudo pacman -S base-devel cmake pkg-config git
sudo pacman -S libnl openssl
```

## 🚀 Planned Setup Process

### Option 1: Standard Flutter Build (Future)
```bash
# Clone the repository
git clone <repository-url>
cd fl_openvpn_client

# Install system dependencies
sudo ./scripts/install_linux_deps.sh

# Get Flutter dependencies
flutter pub get

# Build Linux app (when implemented)
flutter build linux --debug

# Run the app
./build/linux/x64/debug/bundle/fl_openvpn_client
```

### Option 2: Development Build (Future)
```bash
# Configure development environment
./scripts/setup_linux_dev.sh

# Build with native dependencies
./build_linux.sh --debug

# Or release build
./build_linux.sh --release
```

## 🔧 Planned Implementation Architecture

### Linux VPN Integration
The Linux implementation will use:
- **TUN/TAP Interfaces**: Linux kernel virtual network interfaces
- **NetworkManager**: Modern Linux network management
- **D-Bus**: Inter-process communication for system services
- **Polkit**: Privilege escalation for VPN operations
- **systemd**: Service management and integration

### Native Components (Planned)
```
linux/
├── runner/
│   ├── main.cc                 # Application entry point
│   ├── my_application.cc       # GTK application
│   └── vpn_manager.cc          # Linux VPN manager
├── libs/
│   ├── openvpn3/               # OpenVPN3 Core for Linux
│   ├── libnl/                  # Netlink library
│   └── openssl/                # OpenSSL for Linux
└── openvpn/                    # Linux-specific OpenVPN bridge
    ├── linux_tun_builder.cpp   # TUN interface management
    └── linux_openvpn_wrapper.cpp # OpenVPN3 wrapper
```

### Planned Architecture
```cpp
// Linux VPN Manager (Future Implementation)
class LinuxVpnManager {
    // TUN interface management
    int tun_fd;
    std::string tun_device_name;
    
    // OpenVPN3 Core integration
    std::unique_ptr<OpenVPN3Client> vpn_client;
    
    // NetworkManager integration
    GDBusConnection* nm_connection;
    
    // Polkit authorization
    PolkitAuthority* polkit_authority;
};
```

## 🔐 Planned VPN Functionality

### Linux VPN Service Architecture
```
┌─────────────────────────────────────┐
│           Flutter UI (GTK)          │
├─────────────────────────────────────┤
│        Platform Channel            │
├─────────────────────────────────────┤
│      Linux VPN Manager             │
├─────────────────────────────────────┤
│  TUN/TAP + OpenVPN3 Core + NM      │
├─────────────────────────────────────┤
│        Linux Kernel                │
└─────────────────────────────────────┘
```

### Permission Flow (Planned)
1. **Privilege Check**: Check for sudo/root capabilities
2. **Polkit Authorization**: Request VPN permissions via Polkit
3. **TUN Creation**: Create TUN interface (requires root)
4. **NetworkManager**: Register VPN connection with NetworkManager
5. **OpenVPN Connection**: Establish tunnel through TUN interface
6. **Route Management**: Configure routing tables

## 🧪 Planned Testing Methodology

### Development Testing
```bash
# Build and test (future commands)
flutter build linux --debug
./build/linux/x64/debug/bundle/fl_openvpn_client

# Test VPN functionality:
# 1. Launch app (may prompt for password)
# 2. Import OpenVPN configuration
# 3. Connect to VPN server
# 4. Verify TUN interface creation (ip link show)
# 5. Test traffic routing (ip route show)
# 6. Verify DNS resolution
# 7. Test disconnect and cleanup
```

### Expected Behavior (When Implemented)
- ✅ **Polkit Prompt**: Request VPN permissions through system dialog
- ✅ **TUN Creation**: TUN interface appears in `ip link show`
- ✅ **VPN Connection**: OpenVPN tunnel established
- ✅ **Route Configuration**: VPN routes in `ip route show`
- ✅ **DNS Updates**: DNS servers updated via NetworkManager
- ✅ **Status Updates**: Real-time connection status
- ✅ **Clean Disconnect**: Proper interface and route cleanup

## 📊 Planned Build Outputs

### Linux App Structure (Future)
```
fl_openvpn_client
├── lib/
│   ├── libflutter_linux_gtk.so    # Flutter GTK engine
│   ├── libapp.so                  # Flutter app
│   └── libopenvpn_native.so       # OpenVPN3 Core
├── data/
│   ├── flutter_assets/            # App resources
│   ├── icudtl.dat                # ICU data
│   └── app_icon.png              # Application icon
└── fl_openvpn_client             # Main executable
```

### Distribution Packages (Planned)
- **AppImage**: Portable application bundle
- **Flatpak**: Universal Linux package
- **Snap**: Ubuntu/snapd package
- **DEB Package**: Debian/Ubuntu package
- **RPM Package**: Fedora/RHEL package
- **AUR Package**: Arch Linux package

## 🔍 Implementation Challenges

### Technical Challenges
1. **Root Privileges**: VPN requires elevated permissions
2. **TUN/TAP Management**: Complex interface creation and cleanup
3. **NetworkManager Integration**: D-Bus communication complexity
4. **Distribution Differences**: Varying network management systems
5. **Polkit Integration**: Secure privilege escalation

### Development Challenges
1. **Build Complexity**: Multiple native dependencies
2. **Testing Environment**: Various Linux distributions
3. **Permission Handling**: Secure root access management
4. **Package Distribution**: Multiple package formats

## 🚀 Development Roadmap

### Phase 1: Foundation (Future)
- [ ] Linux Flutter app skeleton with GTK
- [ ] Basic UI implementation
- [ ] OpenVPN3 Core compilation for Linux
- [ ] TUN/TAP interface research

### Phase 2: Core Implementation (Future)
- [ ] Linux TUN interface management
- [ ] OpenVPN3 Core integration
- [ ] Basic connection functionality
- [ ] Polkit integration for privileges

### Phase 3: System Integration (Future)
- [ ] NetworkManager D-Bus integration
- [ ] DNS management
- [ ] Route table management
- [ ] systemd service integration

### Phase 4: Distribution (Future)
- [ ] AppImage packaging
- [ ] Flatpak/Snap packaging
- [ ] Distribution-specific packages
- [ ] Comprehensive testing across distributions

## ⚠️ Important Notes

### Linux VPN Requirements (When Implemented)
- **Root Access**: Required for TUN interface creation
- **Polkit**: Modern privilege escalation system
- **NetworkManager**: Preferred network management (fallback to manual)
- **TUN/TAP Support**: Kernel module support required
- **D-Bus**: System message bus for service communication

### Security Considerations (Planned)
- **Polkit Authorization**: Secure privilege escalation
- **Capability-based Security**: Minimal privilege principle
- **Credential Protection**: Secure keyring integration
- **Network Isolation**: Proper traffic separation

### Performance Considerations (Estimated)
- **Memory Usage**: ~80MB runtime (estimated)
- **CPU Usage**: Low to moderate for encryption
- **Startup Time**: ~2-3 seconds (estimated)
- **Connection Time**: ~2-4 seconds (estimated)

### Distribution Compatibility (Planned)
- **Ubuntu/Debian**: Primary development target
- **Fedora/RHEL**: Secondary target
- **Arch Linux**: Community support
- **openSUSE**: Planned support
- **Other Distributions**: Best-effort compatibility

## 📞 Future Support

### When Implementation Begins
- **Build Issues**: GCC/CMake configuration and dependencies
- **VPN Functionality**: TUN/TAP and NetworkManager integration
- **Permission Issues**: Polkit and sudo configuration
- **Distribution Issues**: Package management and compatibility

### Resources (For Future Development)
- **Linux Network Programming**: TUN/TAP interfaces
- **NetworkManager Documentation**: D-Bus API reference
- **Polkit Documentation**: Authorization framework
- **Flutter Linux Documentation**: GTK desktop development

### Development Environment Setup (Future)
```bash
# Ubuntu/Debian setup
sudo apt update
sudo apt install flutter build-essential cmake pkg-config
sudo apt install libnl-3-dev libnl-genl-3-dev libssl-dev
sudo apt install libgtk-3-dev libblkid-dev liblzma-dev

# Configure Flutter for Linux
flutter config --enable-linux-desktop
flutter doctor -v

# Clone and setup project
git clone <repository-url>
cd fl_openvpn_client
flutter pub get
```

## 🎯 Current Alternatives

While Linux implementation is planned for the future, users can currently:

### Alternative Solutions
1. **OpenVPN Client**: Official command-line OpenVPN client
2. **NetworkManager-OpenVPN**: GNOME NetworkManager plugin
3. **OpenVPN3 Linux Client**: Official OpenVPN3 Linux client
4. **Tunnelblick Alternative**: Various GUI OpenVPN clients
5. **WireGuard**: Modern VPN alternative with excellent Linux support

### Configuration Compatibility
```bash
# Current OpenVPN usage on Linux
sudo openvpn --config /path/to/config.ovpn

# NetworkManager integration
nmcli connection import type openvpn file /path/to/config.ovpn

# OpenVPN3 client
openvpn3 config-import --config /path/to/config.ovpn
openvpn3 session-start --config-path /path/to/config.ovpn
```

### Migration Path
When Linux implementation becomes available:
- OpenVPN configuration files will be fully compatible
- Import existing NetworkManager VPN profiles
- Seamless transition from command-line tools
- GUI management for existing connections

## 🔧 System Integration (Planned)

### Desktop Environment Integration
```bash
# Desktop entry (future)
[Desktop Entry]
Name=FL OpenVPN Client
Comment=Cross-platform OpenVPN client
Exec=fl_openvpn_client
Icon=fl_openvpn_client
Type=Application
Categories=Network;Security;
```

### Systemd Service Integration
```bash
# systemd service (future)
[Unit]
Description=FL OpenVPN Client Service
After=network.target

[Service]
Type=dbus
BusName=com.example.FlOpenVpnClient
ExecStart=/usr/bin/fl_openvpn_client --service
User=root

[Install]
WantedBy=multi-user.target
```

### Polkit Policy
```xml
<!-- Polkit policy (future) -->
<policyconfig>
  <action id="com.example.fl-openvpn-client.connect">
    <description>Connect to VPN</description>
    <message>Authentication required to establish VPN connection</message>
    <defaults>
      <allow_any>auth_admin</allow_any>
      <allow_inactive>auth_admin</allow_inactive>
      <allow_active>auth_admin_keep</allow_active>
    </defaults>
  </action>
</policyconfig>
```

---

**Note**: This guide serves as a roadmap for future Linux implementation. The actual implementation may vary based on technical requirements, distribution differences, and Linux ecosystem changes. 