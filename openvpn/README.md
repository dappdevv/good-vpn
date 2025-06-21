# OpenVPN Cross-Platform Library

This directory contains the **generic, cross-platform OpenVPN3 Core integration** for the FL OpenVPN Client project.

## Structure

```
openvpn/
├── build_android.sh        # Android build script
├── build_ios.sh            # iOS build script  
├── build_macos.sh          # macOS build script
├── build_dependencies.sh   # Cross-platform dependency builder
├── openvpn3_wrapper.cpp    # 🌐 Generic OpenVPN3 Core wrapper
├── openvpn3_wrapper.h      # 🌐 Generic OpenVPN3 Core header
├── openvpn_client.cpp      # 🌐 Generic OpenVPN client implementation
├── openvpn_client.h        # 🌐 Generic OpenVPN client header
├── openvpn3_compat.h       # 🌐 OpenVPN3 Core compatibility header
├── CMakeLists.txt          # CMake build configuration
├── cmake/                  # CMake modules and helpers
├── openvpn3/               # OpenVPN3 Core library sources
└── build/                  # Build artifacts (ignored by git)
```

## Platform-Specific Code

Platform-specific OpenVPN implementations are now located in their respective platform directories:

- **Android**: `android/app/src/main/cpp/openvpn/` - JNI wrapper
- **iOS**: `ios/Runner/openvpn/` - Swift-C++ bridge wrapper  
- **macOS**: `macos/Runner/openvpn/` - macOS TUN builder and wrapper

## Generic Implementation

The files in this directory provide a **generic, cross-platform OpenVPN3 Core integration** that works on all platforms:

### Core Files
- `openvpn3_wrapper.cpp/h` - Generic OpenVPN3 Core wrapper with standard logging
- `openvpn_client.cpp/h` - Generic OpenVPN client interface
- `openvpn3_compat.h` - OpenVPN3 Core compatibility definitions

### Features
- ✅ **Pure OpenVPN3 Core** - Uses unmodified OpenVPN3 Core library
- ✅ **Cross-Platform** - Works on Android, iOS, macOS, Windows, Linux
- ✅ **Generic Logging** - Standard printf-based logging for all platforms
- ✅ **TUN Builder** - Generic TUN interface implementation
- ✅ **Thread Safe** - Proper threading and synchronization
- ✅ **Real Connections** - Actual OpenVPN server connections

### Build Scripts
- `build_android.sh` - Builds OpenVPN3 Core for Android (all architectures)
- `build_ios.sh` - Builds OpenVPN3 Core for iOS (device + simulator)
- `build_macos.sh` - Builds OpenVPN3 Core for macOS (x86_64 + arm64)
- `build_dependencies.sh` - Downloads and builds all dependencies

## Usage

### Android
```bash
./build_android.sh
# Uses: android/app/src/main/cpp/openvpn/openvpn_jni.cpp
```

### iOS  
```bash
./build_ios.sh
# Uses: ios/Runner/openvpn/openvpn_wrapper.cpp
```

### macOS
```bash
./build_macos.sh  
# Uses: macos/Runner/openvpn/macos_tun_builder.cpp
```

## Clean Architecture

This reorganization provides:

1. **Generic Core** - Platform-agnostic OpenVPN3 integration
2. **Platform Bridges** - Minimal platform-specific wrappers
3. **Shared Build System** - Common dependency management
4. **Clean Separation** - No platform-specific code in generic library
5. **Maintainable** - Easy to add new platforms

The generic implementation handles all OpenVPN3 Core functionality, while platform-specific wrappers provide only the necessary integration layer (JNI for Android, Swift bridge for iOS/macOS).
