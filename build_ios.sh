#!/bin/bash

# Complete iOS Build Script for OpenVPN Flutter App
# This script builds the iOS app with proper code signing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📱 Building OpenVPN Flutter iOS App"
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
DEVICE_TYPE="simulator"

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
        --device)
            DEVICE_TYPE="device"
            shift
            ;;
        --simulator)
            DEVICE_TYPE="simulator"
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
            echo "  --device      Build for physical device"
            echo "  --simulator   Build for iOS simulator (default)"
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
    
    # Clean iOS build
    if [ -d "build" ]; then
        rm -rf build
        echo "   Cleaned Flutter build directory"
    fi
    
    if [ -d "ios/build" ]; then
        rm -rf ios/build
        echo "   Cleaned iOS build directory"
    fi
    
    echo "✅ Clean completed"
fi

# Get Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get

# Build OpenVPN dependencies for iOS
echo "🔨 Building OpenVPN dependencies for iOS..."
cd ios
if [ -f "build_openvpn.sh" ]; then
    chmod +x build_openvpn.sh
    ./build_openvpn.sh
else
    echo "⚠️  iOS OpenVPN build script not found, using stub implementation"
fi
cd ..

# Check if developer account is configured
echo "🔍 Checking developer account configuration..."

BUNDLE_ID=$(grep "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner/Info.plist | sed -n 's/.*<string>\(.*\)<\/string>.*/\1/p' | head -1)
if [[ "$BUNDLE_ID" == "com.example.flOpenvpnClient" ]] || [[ -z "$BUNDLE_ID" ]]; then
    echo "⚠️  Warning: Using default bundle identifier"
    echo "   Update ios/Runner/Info.plist with your Apple Developer Account bundle ID"
    echo ""
fi

# Build iOS app
echo "🔨 Building iOS app (${BUILD_TYPE} for ${DEVICE_TYPE})..."

if [ "$DEVICE_TYPE" = "device" ]; then
    if [ "$BUILD_TYPE" = "release" ]; then
        flutter build ios --release
        APP_PATH="build/ios/iphoneos/Runner.app"
    else
        flutter build ios --debug
        APP_PATH="build/ios/iphoneos/Runner.app"
    fi
else
    # Simulator build
    if [ "$BUILD_TYPE" = "release" ]; then
        flutter build ios --release --simulator
        APP_PATH="build/ios/iphonesimulator/Runner.app"
    else
        flutter build ios --debug --simulator
        APP_PATH="build/ios/iphonesimulator/Runner.app"
    fi
fi

# Check if app was built successfully
if [ -d "$APP_PATH" ]; then
    APP_SIZE=$(du -sh "$APP_PATH" | cut -f1)
    echo "✅ iOS app built successfully!"
    echo "📱 App location: ${APP_PATH}"
    echo "📏 App size: ${APP_SIZE}"
    echo "🎯 Target: ${DEVICE_TYPE}"
    
    # Check code signing (for device builds)
    if [ "$DEVICE_TYPE" = "device" ]; then
        echo "🔐 Checking code signing..."
        if codesign -dv "$APP_PATH" 2>/dev/null; then
            echo "✅ App is properly code signed"
            SIGNING_INFO=$(codesign -dv "$APP_PATH" 2>&1 | grep "Authority" | head -1)
            echo "   $SIGNING_INFO"
        else
            echo "⚠️  App is not code signed (required for device deployment)"
            echo "   Configure your Apple Developer Account for proper signing"
        fi
        
        # Check entitlements
        echo "🔍 Checking VPN entitlements..."
        if codesign -d --entitlements :- "$APP_PATH" 2>/dev/null | grep -q "networking.networkextension"; then
            echo "✅ VPN entitlements are present"
        else
            echo "⚠️  VPN entitlements may be missing"
        fi
    fi
    
    # Show usage instructions
    echo ""
    echo "🚀 To run the iOS app:"
    if [ "$DEVICE_TYPE" = "simulator" ]; then
        echo "   1. Start iOS Simulator"
        echo "   2. Run: flutter run -d 'iPhone Simulator'"
        echo "   3. Or: open ios/Runner.xcworkspace in Xcode"
    else
        echo "   1. Connect iOS device via USB"
        echo "   2. Trust the developer profile on device"
        echo "   3. Run: flutter run -d 'iPhone'"
        echo "   4. Or: open ios/Runner.xcworkspace in Xcode"
    fi
    echo ""
    echo "📱 VPN Testing Notes:"
    echo "   - iOS VPN requires real device for testing (not simulator)"
    echo "   - App will request VPN permission on first connection"
    echo "   - Allow VPN access in iOS Settings when prompted"
    echo "   - VPN features require proper code signing with developer certificate"
    echo "   - Test with a real OpenVPN configuration file"
    echo ""
    echo "📋 Build summary:"
    echo "   - iOS app (${BUILD_TYPE}): ✅ Built"
    echo "   - Target: ${DEVICE_TYPE}"
    echo "   - App size: ${APP_SIZE}"
    echo "   - Bundle ID: ${BUNDLE_ID}"
    
    # Open Xcode if requested
    if [ "$OPEN_XCODE" = true ]; then
        echo "🔧 Opening Xcode..."
        open ios/Runner.xcworkspace
    fi
    
else
    echo "❌ iOS app build failed!"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Check that your Apple Developer Account is configured"
    echo "   2. Verify Bundle ID is unique and available"
    echo "   3. For device builds, ensure proper code signing setup"
    echo "   4. Try building from Xcode: open ios/Runner.xcworkspace"
    echo "   5. Check Flutter doctor: flutter doctor"
    exit 1
fi

echo ""
echo "🎉 Build completed successfully!"

echo ""
echo "📝 Next Steps:"
echo "   1. Test on iOS Simulator or real device"
echo "   2. Import OpenVPN configuration files"
echo "   3. Test VPN connectivity (real device only)"
echo "   4. Configure proper Apple Developer certificates for distribution" 