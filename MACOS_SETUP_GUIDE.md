# 🍎 macOS OpenVPN Setup Guide with Apple Developer Account

## 🎯 Overview

This guide helps you set up the macOS version of the OpenVPN Flutter app with your Apple Developer Account to enable full VPN functionality using NetworkExtension framework.

## ✅ Prerequisites

### Required Tools
- **macOS**: 10.15+ (Catalina or later)
- **Xcode**: Latest stable version from App Store
- **Flutter**: 3.32.4 or later
- **Apple Developer Account**: Active paid developer account

### Apple Developer Account Requirements
- **Active Membership**: $99/year Apple Developer Program
- **Team ID**: Found in your Apple Developer Account
- **Unique Bundle ID**: Must be unique across App Store
- **Certificates**: Development and Distribution certificates

## 🚀 Quick Setup (Automated)

### Option 1: Automated Setup Script
```bash
# Run the automated setup script
./setup_macos_developer.sh

# Follow the prompts to enter:
# - Team ID (from Apple Developer Account)
# - Bundle Identifier (e.g., com.yourteam.fl-openvpn-client)
# - Organization Name

# Build the app
./build_macos.sh
```

### Option 2: One-Shot Build
```bash
# Build debug version
./build_macos.sh

# Build release version
./build_macos.sh --release

# Clean build
./build_macos.sh --clean

# Open Xcode after build
./build_macos.sh --open-xcode
```

## 🔧 Manual Setup Process

### Step 1: Configure Bundle Identifier
Edit `macos/Runner/Configs/AppInfo.xcconfig`:
```
PRODUCT_BUNDLE_IDENTIFIER = com.yourteam.fl-openvpn-client
PRODUCT_COPYRIGHT = Copyright © 2025 Your Organization. All rights reserved.
```

### Step 2: Open Project in Xcode
```bash
open macos/Runner.xcworkspace
```

### Step 3: Configure Signing & Capabilities
1. Select **Runner** project in navigator
2. Go to **Signing & Capabilities** tab
3. Select your **Team** from dropdown
4. Verify **Bundle Identifier** matches your configuration
5. Ensure **Automatically manage signing** is checked

### Step 4: Verify VPN Entitlements
The following entitlements are already configured:
- ✅ `com.apple.developer.networking.networkextension`
  - `packet-tunnel-provider`
  - `app-proxy-provider`
  - `content-filter-provider` (Release only)
  - `dns-proxy` (Release only)
- ✅ `com.apple.security.network.client`
- ✅ `com.apple.security.network.server`
- ✅ Keychain access groups

### Step 5: Build and Test
```bash
# Build from command line
flutter build macos --debug

# Or build from Xcode
# Product → Build (⌘B)
```

## 🔐 VPN Functionality

### NetworkExtension Integration
The app uses Apple's NetworkExtension framework:
- **NEVPNManager**: VPN configuration management
- **IKEv2 Protocol**: Native macOS VPN protocol
- **Keychain Integration**: Secure credential storage
- **System VPN Integration**: Native macOS VPN experience

### VPN Permission Flow
1. **First Connection**: App requests VPN permission
2. **System Dialog**: macOS shows VPN permission dialog
3. **User Approval**: User must allow VPN access
4. **System Preferences**: VPN profile appears in Network preferences
5. **Connection**: App can establish VPN connections

### OpenVPN Compatibility
- **Protocol Translation**: OpenVPN config → IKEv2 parameters
- **Server Parsing**: Extracts server address and port
- **Certificate Handling**: Uses certificate-based authentication
- **Fallback Mode**: IKEv2 connection to OpenVPN servers

## 🧪 Testing VPN Functionality

### Test Process
1. **Build and Run**: Use signed app with developer certificate
2. **Import Config**: Load OpenVPN configuration file
3. **Connect**: Attempt VPN connection
4. **Permission**: Allow VPN access when prompted
5. **Verify**: Check connection status and IP assignment

### Expected Behavior
- ✅ **Permission Request**: System asks for VPN permission
- ✅ **VPN Profile**: Profile appears in System Preferences
- ✅ **Connection Status**: Real-time status updates
- ✅ **IP Assignment**: VPN IP address displayed
- ✅ **Disconnect**: Clean disconnection process

### Troubleshooting
- **Permission Denied**: Check code signing and entitlements
- **Configuration Error**: Verify bundle ID and team settings
- **Connection Failed**: OpenVPN servers may not support IKEv2

## 📊 Build Outputs

### Debug Build
- **Location**: `build/macos/Build/Products/Debug/fl_openvpn_client.app`
- **Signing**: Development certificate
- **Usage**: Testing and development

### Release Build
- **Location**: `build/macos/Build/Products/Release/fl_openvpn_client.app`
- **Signing**: Distribution certificate
- **Usage**: App Store or direct distribution

### Code Signing Verification
```bash
# Check signing status
codesign -dv build/macos/Build/Products/Debug/fl_openvpn_client.app

# Check entitlements
codesign -d --entitlements :- build/macos/Build/Products/Debug/fl_openvpn_client.app
```

## 🚀 Distribution

### Development Distribution
- **Ad Hoc**: Direct distribution to test devices
- **Developer ID**: Distribution outside App Store
- **Notarization**: Required for macOS 10.15+

### App Store Distribution
- **App Store Connect**: Upload through Xcode or Transporter
- **Review Process**: Apple review for VPN apps
- **Special Requirements**: VPN apps have additional review criteria

## ⚠️ Important Notes

### VPN App Requirements
- **Code Signing**: Must be properly signed with developer certificate
- **Entitlements**: NetworkExtension entitlements required
- **Privacy Policy**: Required for VPN functionality
- **App Store Review**: VPN apps have stricter review process

### Limitations
- **OpenVPN Protocol**: Not natively supported, uses IKEv2 fallback
- **Server Compatibility**: May not work with all OpenVPN servers
- **Certificate Requirements**: Requires certificate-based authentication

### Security Considerations
- **Keychain Storage**: Credentials stored in macOS Keychain
- **System Integration**: Uses native macOS VPN APIs
- **Sandboxing**: App runs in macOS sandbox with VPN entitlements

## 📞 Support

### Common Issues
1. **Code Signing Errors**: Verify Apple Developer Account setup
2. **VPN Permission Denied**: Check entitlements and bundle ID
3. **Build Failures**: Ensure Xcode and Flutter are updated
4. **Connection Issues**: Test with IKEv2-compatible servers

### Resources
- **Apple Developer Documentation**: NetworkExtension framework
- **Flutter macOS Documentation**: Platform-specific setup
- **OpenVPN Documentation**: Configuration file format
- **Xcode Documentation**: Code signing and distribution

---

**Ready to build full-featured macOS OpenVPN app with your Apple Developer Account!** 🎉
