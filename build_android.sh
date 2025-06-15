#!/bin/bash

# Complete Android APK Build Script for OpenVPN Flutter App
# This script builds everything needed for the Android APK in one shot

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENVPN_DIR="${SCRIPT_DIR}/openvpn"

echo "🚀 Building OpenVPN Flutter Android APK"
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

if ! command_exists python3; then
    echo "❌ Python3 not found. Please install Python3."
    exit 1
fi

if [ ! -d "$ANDROID_NDK" ] && [ ! -d "$ANDROID_NDK_ROOT" ]; then
    echo "❌ Android NDK not found. Please set ANDROID_NDK or ANDROID_NDK_ROOT environment variable."
    exit 1
fi

echo "✅ All required tools found"

# Parse command line arguments
CLEAN_BUILD=false
DEPS_ONLY=false
SKIP_DEPS=false
BUILD_TYPE="debug"

while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --deps-only)
            DEPS_ONLY=true
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
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
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --clean      Clean build (remove build directories)"
            echo "  --deps-only  Only build dependencies, skip Flutter build"
            echo "  --skip-deps  Skip dependency build, only build Flutter APK"
            echo "  --release    Build release APK"
            echo "  --debug      Build debug APK (default)"
            echo "  -h, --help   Show this help message"
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
    
    # Clean OpenVPN build
    if [ -d "${OPENVPN_DIR}/build" ]; then
        rm -rf "${OPENVPN_DIR}/build"
        echo "   Cleaned OpenVPN build directory"
    fi
    
    echo "✅ Clean completed"
fi

# Build OpenVPN dependencies
if [ "$SKIP_DEPS" = false ]; then
    echo "📦 Building OpenVPN dependencies..."
    
    cd "${OPENVPN_DIR}"
    
    # Set Android ABI (default to x86_64 for emulator)
    export ANDROID_ABI=${ANDROID_ABI:-x86_64}
    echo "   Building for Android ABI: ${ANDROID_ABI}"
    
    # Build dependencies
    ./build_android.sh
    
    echo "✅ OpenVPN dependencies built successfully"
    
    cd "${SCRIPT_DIR}"
fi

# Exit if only building dependencies
if [ "$DEPS_ONLY" = true ]; then
    echo "✅ Dependencies build completed (--deps-only specified)"
    exit 0
fi

# Get Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get

# Build Flutter APK
echo "🔨 Building Flutter APK (${BUILD_TYPE})..."

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    flutter build apk --debug
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
fi

# Check if APK was built successfully
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo "✅ APK built successfully!"
    echo "📱 APK location: ${APK_PATH}"
    echo "📏 APK size: ${APK_SIZE}"
    
    # Show installation instructions
    echo ""
    echo "🚀 To install and run the APK:"
    echo "   1. Start UDP forwarder: python3 udp_forwarder.py"
    echo "   2. Install APK: flutter install"
    echo "   3. Or manually: adb install ${APK_PATH}"
    echo ""
    echo "📋 Build summary:"
    echo "   - OpenVPN dependencies: ✅ Built"
    echo "   - Flutter APK (${BUILD_TYPE}): ✅ Built"
    echo "   - APK size: ${APK_SIZE}"
    echo "   - Ready for deployment: ✅"
    
else
    echo "❌ APK build failed!"
    exit 1
fi

echo ""
echo "🎉 Build completed successfully!"
