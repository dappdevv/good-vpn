# 🏗️ Complete Build and Deployment Guide

## 🎯 Overview

This guide provides comprehensive instructions for building and deploying the OpenVPN Flutter Client with native OpenVPN3 integration. The project includes automated build scripts for one-shot compilation.

## ✅ Prerequisites

### System Requirements
- **Operating System**: macOS 10.15+, Linux, or Windows 10+
- **Flutter SDK**: 3.32.4 or higher
- **Python 3**: For UDP forwarder (Android emulator testing)
- **Git**: For version control

### Android Development Setup (✅ Fully Supported)
1. **Android Studio**: Latest stable version with default SDK
2. **Android NDK**: Version 27.0.12077973 (exact version required)
3. **CMake**: For native library compilation (included with Android Studio)
4. **Android SDK**: API 35+ required

### Other Platforms (🚧 Planned)
- **iOS**: Xcode with iOS SDK (macOS only)
- **macOS**: Xcode with command line tools
- **Windows**: Visual Studio with C++ support
- **Linux**: GCC/Clang and development tools

## 🔧 Environment Setup

### 1. Install Flutter
```bash
# Download Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

### 2. Install Android NDK (Critical Step)
```bash
# Via Android Studio SDK Manager (Recommended)
# Tools → SDK Manager → SDK Tools → NDK (Side by side) → 27.0.12077973

# Or via command line
sdkmanager --install "ndk;27.0.12077973"

# Verify installation
ls $ANDROID_HOME/ndk/27.0.12077973
```

### 3. Configure NDK Path
Create/update `android/local.properties`:
```properties
sdk.dir=/Users/[username]/Library/Android/sdk
ndk.dir=/Users/[username]/Library/Android/sdk/ndk/27.0.12077973
```

## 📦 Project Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd fl_openvpn_client
```

### 2. Install Dependencies
```bash
# Flutter dependencies
flutter pub get

# Verify Flutter setup
flutter doctor
```

### 3. Verify NDK Configuration
```bash
# Check NDK version in build.gradle.kts
grep -r "27.0.12077973" android/

# Should show:
# android/app/build.gradle.kts:        ndkVersion = "27.0.12077973"
# android/local.properties:ndk.dir=.../ndk/27.0.12077973
```

## 🏗️ Building the Application

### 🚀 One-Shot Build (Recommended)

The project includes an automated build script that handles everything:

```bash
# Build debug APK with all dependencies
./build_android.sh

# Build release APK
./build_android.sh --release

# Clean build (removes all build artifacts)
./build_android.sh --clean

# Only build OpenVPN dependencies
./build_android.sh --deps-only

# Skip dependencies, only build Flutter APK
./build_android.sh --skip-deps

# Show all options
./build_android.sh --help
```

### 📱 Manual Build Process

#### Debug Build
```bash
# 1. Set up environment
export ANDROID_NDK_ROOT=/path/to/ndk/27.0.12077973
export ANDROID_ABI=x86_64  # For emulator, use arm64-v8a for device

# 2. Build OpenVPN dependencies
cd openvpn
./build_android.sh
cd ..

# 3. Build Flutter APK
flutter clean
flutter build apk --debug

# 4. Install and run
flutter install
```

#### Release Build
```bash
# 1. Clean previous builds
flutter clean

# 2. Build release APK
flutter build apk --release

# Output: build/app/outputs/flutter-apk/app-release.apk
```

### 🔍 Build Verification
```bash
# Check if native library is included
unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep libopenvpn_native.so

# Should show:
# lib/arm64-v8a/libopenvpn_native.so
# lib/armeabi-v7a/libopenvpn_native.so
# lib/x86/libopenvpn_native.so
# lib/x86_64/libopenvpn_native.so

# Check APK size and contents
ls -lh build/app/outputs/flutter-apk/
```

## 🧪 Testing Setup

### 1. Android Emulator Setup
```bash
# Create emulator (if needed)
avdmanager create avd -n test_device -k "system-images;android-35;google_apis;x86_64"

# Start emulator
emulator -avd test_device

# Verify device
flutter devices
```

### 2. UDP Forwarder for Emulator Testing (Required)

The Android emulator cannot directly access external OpenVPN servers. Use the included UDP forwarder:

```bash
# Start UDP forwarder (required for emulator testing)
python3 udp_forwarder.py &

# The forwarder listens on localhost:1194 and forwards to your OpenVPN server
# Configure your .ovpn files to connect to 10.0.2.2:1194 (emulator's host)
```

**UDP Forwarder Configuration:**
- **Local Port**: 1194 (listens on all interfaces)
- **Remote Server**: 172.16.109.4:1194 (configurable in script)
- **Protocol**: UDP packet forwarding with client tracking

### 3. Test Configuration
Place test .ovpn files in `sample_configs/` directory:
```bash
# Sample configurations are included
ls sample_configs/
# vm01.ovpn - Working test configuration
# corporate_vpn.ovpn - Enterprise example
# sample_server.ovpn - Basic server example
```

### 4. Run Tests
```bash
# 1. Start UDP forwarder (for emulator)
python3 udp_forwarder.py &

# 2. Run app on emulator
flutter run -d emulator-5554

# 3. Monitor logs
adb logcat | grep -E "(flutter|OpenVPN|OpenVPN_JNI|Exception)"

# 4. Test connection flow
# - Import vm01.ovpn configuration
# - Connect and verify VPN IP assignment
# - Check data transfer statistics
```

## 🚀 Deployment

### Development Deployment
```bash
# Install on connected device
flutter install

# Or build and install manually
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### Production Deployment
```bash
# Build signed release APK
flutter build apk --release

# For Play Store (AAB format)
flutter build appbundle --release
```

## 🔍 Troubleshooting

### Common Build Issues

#### 1. NDK Version Mismatch
**Error**: `No version of NDK matched the requested version`
**Solution**:
```bash
# Remove conflicting NDK versions
rm -rf $ANDROID_HOME/ndk/[other-versions]

# Install correct version
sdkmanager --install "ndk;27.0.12077973"

# Update local.properties
echo "ndk.dir=$ANDROID_HOME/ndk/27.0.12077973" >> android/local.properties
```

#### 2. CMake Build Failures
**Error**: `CMake Error: Could not find CMAKE_C_COMPILER`
**Solution**:
```bash
# Install CMake via SDK Manager
sdkmanager --install "cmake;3.22.1"

# Or via Android Studio: SDK Tools → CMake
```

#### 3. Native Library Not Found
**Error**: `java.lang.UnsatisfiedLinkError: dlopen failed: library "libopenvpn_native.so" not found`
**Solution**:
```bash
# Verify CMake configuration
cat android/app/src/main/cpp/CMakeLists.txt

# Clean and rebuild
flutter clean
flutter run
```

#### 4. Foreground Service Errors
**Error**: `MissingForegroundServiceTypeException`
**Solution**: Verify AndroidManifest.xml has:
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<service android:foregroundServiceType="specialUse">
    <property android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE" android:value="vpn" />
</service>
```

### Build Performance Issues

#### Slow Builds
```bash
# Enable Gradle daemon
echo "org.gradle.daemon=true" >> android/gradle.properties

# Increase memory
echo "org.gradle.jvmargs=-Xmx4g" >> android/gradle.properties

# Use parallel builds
echo "org.gradle.parallel=true" >> android/gradle.properties
```

#### Clean Build
```bash
# Full clean
flutter clean
cd android && ./gradlew clean && cd ..
flutter pub get
flutter run
```

## 📊 Build Verification Checklist

### Pre-Build Checklist
- [ ] Flutter doctor shows no issues
- [ ] NDK 27.0.12077973 installed
- [ ] local.properties configured correctly
- [ ] CMakeLists.txt present and valid
- [ ] All dependencies resolved

### Post-Build Checklist
- [ ] APK builds successfully
- [ ] Native libraries included in APK
- [ ] App installs on device
- [ ] OpenVPN service initializes
- [ ] Native library loads without errors
- [ ] VPN connection works end-to-end

### Runtime Verification
```bash
# Check native library loading
adb logcat | grep "OpenVPN native library loaded successfully"

# Check service initialization
adb logcat | grep "Native OpenVPN library initialized successfully"

# Check connection flow
adb logcat | grep -E "(connecting|authenticating|connected)"
```

## 🎯 Performance Optimization

### Build Optimization
```bash
# Enable R8 code shrinking (release builds)
# Already configured in build.gradle.kts

# Optimize APK size
flutter build apk --release --shrink

# Split APKs by architecture
flutter build apk --release --split-per-abi
```

### Runtime Optimization
- Native library is compiled with `-O2` optimization
- Proper memory management in JNI layer
- Efficient threading model for UI updates

## 📋 Deployment Checklist

### Development Deployment
- [ ] Debug build successful
- [ ] App installs and runs
- [ ] All features functional
- [ ] No crashes or errors
- [ ] Performance acceptable

### Production Deployment
- [ ] Release build successful
- [ ] APK signed properly
- [ ] All permissions declared
- [ ] Performance optimized
- [ ] Security review completed

## 🔗 Additional Resources

- [Flutter Android Build Documentation](https://docs.flutter.dev/deployment/android)
- [Android NDK Documentation](https://developer.android.com/ndk)
- [CMake Android Documentation](https://developer.android.com/ndk/guides/cmake)
- [OpenVPN3 Core Documentation](https://github.com/OpenVPN/openvpn3)

## 📞 Support

For build issues:
1. Check this guide first
2. Verify environment setup
3. Check GitHub issues
4. Create detailed issue report with:
   - Flutter version (`flutter --version`)
   - Android SDK/NDK versions
   - Build logs and error messages
   - System information
