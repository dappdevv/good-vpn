# 🏗️ Platform-Specific Build Guide

## 📱 Android Platform (✅ Fully Implemented)

### Quick Start
```bash
# One-shot build for Android
./build_android.sh

# For emulator testing
python3 udp_forwarder.py &
flutter run -d emulator-5554
```

### Prerequisites
- **Android Studio**: Latest stable version
- **Android NDK**: 27.0.12077973 (exact version required)
- **Android SDK**: API 35+
- **CMake**: Included with Android Studio
- **Python 3**: For UDP forwarder (emulator testing)

### Environment Setup
```bash
# Set NDK path
export ANDROID_NDK_ROOT=/path/to/ndk/27.0.12077973

# Set target architecture
export ANDROID_ABI=x86_64        # For emulator
export ANDROID_ABI=arm64-v8a     # For modern devices
export ANDROID_ABI=armeabi-v7a   # For older devices
```

### Build Process
```bash
# 1. Build OpenVPN dependencies
cd openvpn
./build_android.sh
cd ..

# 2. Build Flutter APK
flutter build apk --debug

# 3. Install and test
flutter install
```

### Build Outputs
- **APK Location**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Native Libraries**: Included in APK under `lib/{arch}/libopenvpn_native.so`
- **Dependencies**: Built in `openvpn/build/android/{arch}/`

### Testing
```bash
# Start UDP forwarder for emulator
python3 udp_forwarder.py &

# Run on emulator
flutter run -d emulator-5554

# Monitor OpenVPN logs
adb logcat | grep -E "(OpenVPN|OpenVPN_JNI)"
```

### Architecture Support
- ✅ **x86_64**: Android emulator
- ✅ **arm64-v8a**: Modern Android devices (64-bit)
- ✅ **armeabi-v7a**: Older Android devices (32-bit)
- ✅ **x86**: Legacy emulator support

---

## 🍎 iOS Platform (🚧 Planned)

### Prerequisites (When Implemented)
- **Xcode**: Latest stable version
- **iOS SDK**: 14.0+
- **Apple Developer Account**: For device testing
- **CocoaPods**: For dependency management

### Planned Implementation
```bash
# Future iOS build process
cd ios
pod install
cd ..
flutter build ios --release
```

### Key Components (Planned)
- **NetworkExtension**: iOS VPN framework integration
- **OpenVPN3**: iOS-compatible OpenVPN library
- **Keychain**: Secure credential storage
- **Background Processing**: VPN background operation

---

## 🖥️ macOS Platform (✅ Ready with Apple Developer Account)

### Quick Start
```bash
# Configure with your Apple Developer Account
./setup_macos_developer.sh

# Build macOS app
./build_macos.sh

# Or build release version
./build_macos.sh --release
```

### Prerequisites
- **Xcode**: Latest stable version from App Store
- **macOS SDK**: 10.15+ (included with Xcode)
- **Apple Developer Account**: Active paid membership ($99/year)
- **Flutter**: 3.32.4+

### Environment Setup
```bash
# Get your Team ID from Apple Developer Account
# Update bundle identifier in macos/Runner/Configs/AppInfo.xcconfig
# Example: com.yourteam.fl-openvpn-client

# Open project in Xcode
open macos/Runner.xcworkspace

# Configure Signing & Capabilities:
# 1. Select your Team
# 2. Verify Bundle Identifier
# 3. Check VPN entitlements are present
```

### Build Process
```bash
# Automated setup (recommended)
./setup_macos_developer.sh

# Manual build
flutter build macos --debug

# Or from Xcode
# Product → Build (⌘B)
```

### Build Outputs
- **Debug**: `build/macos/Build/Products/Debug/fl_openvpn_client.app`
- **Release**: `build/macos/Build/Products/Release/fl_openvpn_client.app`
- **Code Signing**: Automatic with developer certificate
- **Entitlements**: NetworkExtension VPN capabilities

### VPN Functionality
- **NetworkExtension**: Native macOS VPN framework
- **IKEv2 Protocol**: Compatible with OpenVPN servers
- **System Integration**: Native VPN experience
- **Permission Handling**: Automatic VPN permission requests

### Testing
```bash
# Build and run
./build_macos.sh --open-xcode

# Test VPN connection:
# 1. Import OpenVPN configuration
# 2. Connect (system will request VPN permission)
# 3. Allow VPN access in System Preferences
# 4. Verify connection and IP assignment
```

### Key Components (✅ Implemented)
- **NetworkExtension**: macOS VPN framework integration
- **NEVPNManager**: VPN configuration management
- **Keychain Access**: Secure credential storage
- **Code Signing**: Developer certificate integration

---

## 🪟 Windows Platform (🚧 Planned)

### Prerequisites (When Implemented)
- **Visual Studio**: 2019+ with C++ support
- **Windows SDK**: Latest version
- **CMake**: For native compilation

### Planned Implementation
```bash
# Future Windows build process
flutter build windows --release
```

### Key Components (Planned)
- **WinTUN**: Windows VPN adapter
- **Windows VPN APIs**: Native VPN integration
- **Windows Credential Manager**: Secure storage
- **UAC Integration**: Administrator privileges

---

## 🐧 Linux Platform (🚧 Planned)

### Prerequisites (When Implemented)
- **GCC/Clang**: C++ compiler
- **CMake**: Build system
- **OpenVPN**: System OpenVPN client
- **NetworkManager**: Network management

### Planned Implementation
```bash
# Future Linux build process
flutter build linux --release
```

### Key Components (Planned)
- **OpenVPN Client**: System integration
- **NetworkManager**: VPN profile management
- **D-Bus**: System service communication
- **Polkit**: Privilege escalation

---

## 🔧 Build Script Reference

### Android Build Script (`build_android.sh`)
```bash
# Complete build with dependencies
./build_android.sh

# Build options
./build_android.sh --clean          # Clean build
./build_android.sh --release        # Release APK
./build_android.sh --deps-only      # Dependencies only
./build_android.sh --skip-deps      # Skip dependencies
./build_android.sh --help           # Show help
```

### Legacy Build Script (`build_project.sh`)
```bash
# Platform-specific builds (limited functionality)
./build_project.sh android          # Android dependencies only
./build_project.sh desktop          # Desktop dependencies (planned)
```

---

## 📊 Platform Comparison

| Platform | Status | OpenVPN Integration | Build System | Testing |
|----------|--------|-------------------|--------------|---------|
| **Android** | ✅ Complete | OpenVPN3 Core | CMake + Gradle | ✅ Emulator + Device |
| **macOS** | ✅ Ready* | NetworkExtension + IKEv2 | Xcode + Flutter | ✅ Native |
| **iOS** | 🚧 Planned | NetworkExtension | Xcode + CocoaPods | 🚧 Simulator + Device |
| **Windows** | 🚧 Planned | WinTUN + APIs | Visual Studio | 🚧 Native |
| **Linux** | 🚧 Planned | System OpenVPN | CMake + Make | 🚧 Native |

*Requires Apple Developer Account for VPN functionality

---

## 🎯 Next Steps

### For Android (Current)
- ✅ Production deployment ready
- ✅ Play Store preparation
- ✅ Performance optimization
- ✅ Security audit complete

### For Other Platforms (Future)
1. **iOS Implementation**: NetworkExtension integration
2. **macOS Support**: System extension development
3. **Windows Support**: WinTUN adapter integration
4. **Linux Support**: NetworkManager integration
5. **Cross-Platform Testing**: Unified test suite

---

## 📞 Platform-Specific Support

### Android Issues
- Check NDK version (must be 27.0.12077973)
- Verify CMakeLists.txt configuration
- Ensure UDP forwarder for emulator testing
- Monitor native library loading logs

### Future Platform Issues
- Platform-specific documentation will be added
- Build guides for each platform
- Troubleshooting sections
- Performance optimization guides

---

**Current Focus**: Android platform is production-ready. Other platforms are planned for future development phases.
