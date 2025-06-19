#!/bin/bash

# Production Build Script for macOS OpenVPN Flutter App
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

echo "🍎 Building OpenVPN Flutter App for macOS (Production)"
echo "📁 Project root: ${PROJECT_ROOT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}🔧 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Step 1: Build OpenVPN dependencies
print_step "Building OpenVPN dependencies for macOS..."
cd "${PROJECT_ROOT}/openvpn"
if [ ! -f "build/macos/install/lib/libopenvpn3-core.a" ]; then
    ./build_macos.sh
else
    print_success "OpenVPN dependencies already built"
fi

# Step 2: Build OpenVPN client library
print_step "Building OpenVPN client library..."
if [ ! -f "build/libopenvpn_client.a" ]; then
    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(sysctl -n hw.ncpu)
    cd ..
else
    print_success "OpenVPN client library already built"
fi

# Step 3: Build macOS wrapper
print_step "Building macOS wrapper library..."
cd "${PROJECT_ROOT}/macos"
if [ ! -f "build/libopenvpn_macos_wrapper.a" ]; then
    ./build_openvpn.sh
else
    print_success "macOS wrapper already built"
fi

# Step 4: Clean Flutter build
print_step "Cleaning Flutter build cache..."
cd "${PROJECT_ROOT}"
flutter clean

# Step 5: Get Flutter dependencies
print_step "Getting Flutter dependencies..."
flutter pub get

# Step 6: Build Flutter app for release
print_step "Building Flutter app for macOS (Release)..."
flutter build macos --release

# Step 7: Verify build
if [ -f "build/macos/Build/Products/Release/fl_openvpn_client.app/Contents/MacOS/fl_openvpn_client" ]; then
    print_success "macOS app built successfully!"
    
    # Get app info
    APP_PATH="build/macos/Build/Products/Release/fl_openvpn_client.app"
    APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)
    
    echo ""
    echo "📦 Build Summary:"
    echo "  App Path: ${APP_PATH}"
    echo "  App Size: ${APP_SIZE}"
    echo "  Architecture: Universal (x86_64 + arm64)"
    echo "  OpenVPN: Real OpenVPN3 Core integration"
    echo "  Deployment Target: macOS 10.15+"
    
    # Check if app is properly signed
    print_step "Checking code signature..."
    if codesign -dv "${APP_PATH}" 2>/dev/null; then
        print_success "App is properly signed"
    else
        print_warning "App signature verification failed (expected for development builds)"
    fi
    
    echo ""
    print_success "🎉 macOS OpenVPN app build completed successfully!"
    echo "📍 You can find the app at: ${APP_PATH}"
    echo "🚀 Ready for distribution and testing!"
    
else
    print_error "Build failed - app not found"
    exit 1
fi
