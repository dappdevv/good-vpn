#!/bin/bash

# OpenVPN Client Build Script
# This script builds the app for all supported platforms

set -e

echo "🚀 Building OpenVPN Client for all platforms..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Get Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1)
print_status "Using $FLUTTER_VERSION"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Run tests
print_status "Running tests..."
if flutter test; then
    print_success "All tests passed!"
else
    print_error "Tests failed!"
    exit 1
fi

# Create build directory
mkdir -p build/releases

# Build for macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building for macOS..."
    if flutter build macos --release; then
        print_success "macOS build completed"
        cp -r build/macos/Build/Products/Release/fl_openvpn_client.app build/releases/
    else
        print_warning "macOS build failed"
    fi
fi

# Build for Windows (if on Windows or with cross-compilation)
print_status "Attempting Windows build..."
if flutter build windows --release 2>/dev/null; then
    print_success "Windows build completed"
    cp -r build/windows/x64/runner/Release build/releases/windows
else
    print_warning "Windows build skipped (not available on this platform)"
fi

# Build for Linux (if on Linux or with cross-compilation)
print_status "Attempting Linux build..."
if flutter build linux --release 2>/dev/null; then
    print_success "Linux build completed"
    cp -r build/linux/x64/release/bundle build/releases/linux
else
    print_warning "Linux build skipped (not available on this platform)"
fi

# Build for Android
print_status "Building for Android..."
if flutter build apk --release; then
    print_success "Android APK build completed"
    cp build/app/outputs/flutter-apk/app-release.apk build/releases/
    
    # Also build AAB for Play Store
    if flutter build appbundle --release; then
        print_success "Android App Bundle build completed"
        cp build/app/outputs/bundle/release/app-release.aab build/releases/
    fi
else
    print_warning "Android build failed"
fi

# Build for iOS (only on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_status "Building for iOS..."
    if flutter build ios --release --no-codesign; then
        print_success "iOS build completed (no code signing)"
        print_warning "iOS app requires code signing for distribution"
    else
        print_warning "iOS build failed"
    fi
fi

# Build for Web
print_status "Building for Web..."
if flutter build web --release; then
    print_success "Web build completed"
    cp -r build/web build/releases/
else
    print_warning "Web build failed"
fi

# Summary
print_status "Build summary:"
echo "📁 Build artifacts are in: build/releases/"
ls -la build/releases/ 2>/dev/null || echo "No build artifacts found"

print_success "Build process completed!"
echo ""
echo "🎉 OpenVPN Client has been built for available platforms!"
echo "📦 Check the build/releases/ directory for the built applications."
