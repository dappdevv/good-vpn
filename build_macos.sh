#!/bin/bash

# Complete macOS Build Script for OpenVPN Flutter App
# This script builds the macOS app with proper code signing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🍎 Building OpenVPN Flutter macOS App"
echo "📍 Project directory: ${SCRIPT_DIR}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check required tools
echo "🔍 Checking required tools..."

if ! command_exists flutter; then
    echo "❌ Flutter not found. Please install Flutter and add it to PATH."
    exit 1
fi

if ! command_exists xcodebuild; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ All required tools found"

# Parse command line arguments
CLEAN_BUILD=false
BUILD_TYPE="debug"
OPEN_XCODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --release)
            BUILD_TYPE="release"
            shift
            ;;
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --open-xcode)
            OPEN_XCODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --clean       Clean build (remove build directories)"
            echo "  --release     Build release app"
            echo "  --debug       Build debug app (default)"
            echo "  --open-xcode  Open Xcode after build"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo "🧹 Cleaning build directories..."
    
    # Clean Flutter build
    flutter clean
    
    # Clean macOS build
    if [ -d "build" ]; then
        rm -rf build
        echo "   Cleaned Flutter build directory"
    fi
    
    if [ -d "macos/build" ]; then
        rm -rf macos/build
        echo "   Cleaned macOS build directory"
    fi
    
    echo "✅ Clean completed"
fi

# Get Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get

# Check if developer account is configured
echo "🔍 Checking developer account configuration..."

BUNDLE_ID=$(grep "PRODUCT_BUNDLE_IDENTIFIER" macos/Runner/Configs/AppInfo.xcconfig | cut -d'=' -f2 | xargs)
if [[ "$BUNDLE_ID" == "com.example.flOpenvpnClient" ]]; then
    echo "⚠️  Warning: Using default bundle identifier"
    echo "   Run ./setup_macos_developer.sh to configure your Apple Developer Account"
    echo "   Or manually update macos/Runner/Configs/AppInfo.xcconfig"
    echo ""
fi

# Build macOS app
echo "🔨 Building macOS app (${BUILD_TYPE})..."

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build macos --release
    APP_PATH="build/macos/Build/Products/Release/fl_openvpn_client.app"
else
    flutter build macos --debug
    APP_PATH="build/macos/Build/Products/Debug/fl_openvpn_client.app"
fi

# Check if app was built successfully
if [ -d "$APP_PATH" ]; then
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    echo "✅ macOS app built successfully!"
    echo "📱 App location: ${APP_PATH}"
    echo "📏 App size: ${APP_SIZE}"
    
    # Check code signing
    echo "🔐 Checking code signing..."
    if codesign -dv "$APP_PATH" 2>/dev/null; then
        echo "✅ App is properly code signed"
        SIGNING_INFO=$(codesign -dv "$APP_PATH" 2>&1 | grep "Authority" | head -1)
        echo "   $SIGNING_INFO"
    else
        echo "⚠️  App is not code signed (VPN features may not work)"
        echo "   Configure your Apple Developer Account for proper signing"
    fi
    
    # Check entitlements
    echo "🔍 Checking VPN entitlements..."
    if codesign -d --entitlements :- "$APP_PATH" 2>/dev/null | grep -q "networking.networkextension"; then
        echo "✅ VPN entitlements are present"
    else
        echo "⚠️  VPN entitlements may be missing"
    fi
    
    # Show usage instructions
    echo ""
    echo "🚀 To run the macOS app:"
    echo "   1. Double-click: open \"${APP_PATH}\""
    echo "   2. Command line: open \"${APP_PATH}\""
    echo "   3. From Xcode: open macos/Runner.xcworkspace"
    echo ""
    echo "🔐 VPN Testing Notes:"
    echo "   - The app will request VPN permission on first connection"
    echo "   - Allow VPN access in System Preferences when prompted"
    echo "   - VPN features require proper code signing with developer certificate"
    echo "   - Test with a real OpenVPN configuration file"
    echo ""
    echo "📋 Build summary:"
    echo "   - macOS app (${BUILD_TYPE}): ✅ Built"
    echo "   - App size: ${APP_SIZE}"
    echo "   - Bundle ID: ${BUNDLE_ID}"
    
    # Open Xcode if requested
    if [ "$OPEN_XCODE" = true ]; then
        echo "🔧 Opening Xcode..."
        open macos/Runner.xcworkspace
    fi
    
else
    echo "❌ macOS app build failed!"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Check that your Apple Developer Account is configured"
    echo "   2. Run: ./setup_macos_developer.sh"
    echo "   3. Verify Bundle ID is unique and available"
    echo "   4. Try building from Xcode: open macos/Runner.xcworkspace"
    echo "   5. Check Flutter doctor: flutter doctor"
    exit 1
fi

echo ""
echo "🎉 Build completed successfully!"
