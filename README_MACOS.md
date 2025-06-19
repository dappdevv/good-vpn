# OpenVPN Flutter Client - macOS

A production-ready OpenVPN client for macOS built with Flutter and real OpenVPN3 Core library integration.

## 🎯 Features

- ✅ **Real OpenVPN3 Core Integration** - Uses the actual OpenVPN3 library, not IKEv2
- ✅ **Universal Binary** - Supports both Intel (x86_64) and Apple Silicon (arm64) Macs
- ✅ **Production Ready** - Full SSL/TLS encryption with AES-256-GCM
- ✅ **Real-time Monitoring** - Live connection stats and status updates
- ✅ **Native Performance** - Built with optimized C++ libraries
- ✅ **macOS 10.15+** - Compatible with modern macOS versions

## 🏗️ Architecture

```
Flutter App (Dart)
    ↓
Platform Channel (Swift)
    ↓
C++ Wrapper (openvpn_c_wrapper.cpp)
    ↓
OpenVPN Client Library (openvpn_client.cpp)
    ↓
OpenVPN3 Core Library (C++)
    ↓
OpenSSL + Dependencies
```

## 📋 Prerequisites

- **macOS 10.15+** (Catalina or later)
- **Xcode 12+** with Command Line Tools
- **Flutter 3.0+**
- **CMake 3.18+**
- **Apple Developer Account** (for distribution)

## 🚀 Quick Start

### 1. Clone and Build

```bash
git clone <repository-url>
cd fl_openvpn_client

# Build all dependencies and run
./build_macos_release.sh
```

### 2. Development Build

```bash
# Build OpenVPN dependencies
cd openvpn && ./build_macos.sh && cd ..

# Build macOS wrapper
cd macos && ./build_openvpn.sh && cd ..

# Run Flutter app
flutter run -d macos
```

### 3. Production Build

```bash
# One-command production build
./build_macos_release.sh

# Manual production build
flutter build macos --release
```

## 📁 Project Structure

```
fl_openvpn_client/
├── lib/                          # Flutter Dart code
├── macos/                        # macOS-specific code
│   ├── Runner/
│   │   ├── MacVpnManager.swift   # Main VPN manager
│   │   ├── openvpn_c_wrapper.cpp # C++ wrapper for Swift
│   │   └── MainFlutterWindow.swift
│   ├── CMakeLists.txt            # macOS build configuration
│   └── build_openvpn.sh          # macOS wrapper build script
├── openvpn/                      # OpenVPN3 integration
│   ├── build_macos.sh            # Dependencies build script
│   ├── openvpn_client.cpp        # OpenVPN client implementation
│   ├── openvpn3_wrapper.cpp      # OpenVPN3 Core wrapper
│   └── CMakeLists.txt            # OpenVPN build configuration
└── build_macos_release.sh        # Production build script
```

## 🔧 Build System

### Dependencies Built

1. **OpenSSL 3.3.2** - Cryptographic library
2. **fmt 11.0.2** - String formatting library
3. **LZ4 1.10.0** - Compression library
4. **ASIO 1.30.2** - Networking library (header-only)
5. **OpenVPN3 Core 3.11.1** - Core OpenVPN implementation

### Build Process

1. **Dependencies**: `openvpn/build_macos.sh` builds all C++ dependencies
2. **OpenVPN Client**: CMake builds the OpenVPN client library
3. **macOS Wrapper**: CMake builds the Swift-C++ bridge
4. **Flutter App**: Standard Flutter build process with library linking

## 🔐 Security Features

- **AES-256-GCM Encryption** - Military-grade encryption
- **TLS 1.3 Support** - Latest TLS protocol
- **Perfect Forward Secrecy** - Key rotation for enhanced security
- **Certificate Validation** - Full X.509 certificate chain validation
- **Compression** - LZ4v2 compression with security considerations

## 📊 Connection Process

1. **Configuration Parsing** - Validates OpenVPN config file
2. **Server Resolution** - DNS lookup for server address
3. **SSL Handshake** - Establishes secure TLS connection
4. **Authentication** - Username/password or certificate auth
5. **Tunnel Creation** - Creates virtual network interface
6. **Route Configuration** - Sets up network routing
7. **Connected State** - Maintains connection with keep-alive

## 🛠️ Development

### Adding New Features

1. **Dart Layer**: Add UI and business logic in `lib/`
2. **Platform Channel**: Update `MacVpnManager.swift` for new methods
3. **C++ Integration**: Modify `openvpn_c_wrapper.cpp` if needed
4. **OpenVPN Core**: Update `openvpn_client.cpp` for core functionality

### Debugging

```bash
# Enable verbose logging
flutter run -d macos --verbose

# Check native logs
log stream --predicate 'process == "fl_openvpn_client"'

# Debug C++ code
lldb build/macos/Build/Products/Debug/fl_openvpn_client.app
```

## 📦 Distribution

### App Store Distribution

1. **Code Signing**: Configure in Xcode with your Apple Developer account
2. **Entitlements**: Network extensions require special entitlements
3. **Notarization**: Required for distribution outside App Store
4. **Sandboxing**: May require adjustments for VPN functionality

### Direct Distribution

```bash
# Build release version
flutter build macos --release

# Sign the app (replace with your identity)
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" \
  build/macos/Build/Products/Release/fl_openvpn_client.app

# Create DMG for distribution
hdiutil create -volname "OpenVPN Client" -srcfolder \
  build/macos/Build/Products/Release/fl_openvpn_client.app \
  OpenVPN_Client_macOS.dmg
```

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### Manual Testing Checklist

- [ ] App launches successfully
- [ ] OpenVPN library initializes
- [ ] Configuration file loads
- [ ] Connection establishes
- [ ] VPN tunnel works (check IP)
- [ ] Disconnection works
- [ ] Stats update correctly
- [ ] App handles errors gracefully

## 🔍 Troubleshooting

### Common Issues

1. **Build Failures**
   ```bash
   # Clean and rebuild
   flutter clean
   rm -rf openvpn/build macos/build
   ./build_macos_release.sh
   ```

2. **Library Not Found**
   ```bash
   # Verify libraries exist
   ls -la openvpn/build/macos/install/lib/
   ls -la macos/build/
   ```

3. **Connection Issues**
   - Check OpenVPN config file format
   - Verify server accessibility
   - Check firewall settings
   - Review app logs

### Logs Location

- **Flutter Logs**: Console output during `flutter run`
- **macOS Logs**: Console.app → filter by "fl_openvpn_client"
- **OpenVPN Logs**: Embedded in app logs with `[INFO]` prefix

## 📄 License

This project uses the same license as the main project. OpenVPN3 Core is licensed under AGPLv3.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on macOS
5. Submit a pull request

## 📞 Support

For issues specific to macOS:
1. Check this documentation
2. Review the troubleshooting section
3. Check existing GitHub issues
4. Create a new issue with detailed logs

---

**Built with ❤️ for macOS using real OpenVPN3 Core integration**
