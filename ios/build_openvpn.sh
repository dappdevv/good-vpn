#!/bin/bash

# Build OpenVPN libraries for iOS Flutter app
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENVPN_DIR="${PROJECT_ROOT}/openvpn"

echo "📱 Building OpenVPN libraries for iOS Flutter app"
echo "📁 Project root: ${PROJECT_ROOT}"
echo "📁 OpenVPN directory: ${OPENVPN_DIR}"

# Check if OpenVPN directory exists
if [ ! -d "${OPENVPN_DIR}" ]; then
    echo "❌ OpenVPN directory not found: ${OPENVPN_DIR}"
    exit 1
fi

cd "${OPENVPN_DIR}"

# Build OpenVPN dependencies for iOS if not already built
if [ ! -f "build/ios/install/lib/libopenvpn3-core.a" ]; then
    echo "🔨 Building OpenVPN dependencies for iOS..."
    ./build_ios.sh
else
    echo "✅ OpenVPN dependencies already built for iOS"
fi

# Build OpenVPN client library if not already built
if [ ! -f "build/libopenvpn_client_ios.a" ]; then
    echo "🔨 Building OpenVPN client library for iOS..."
    mkdir -p build
    cd build
    
    # Configure for iOS
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=${SCRIPT_DIR}/../cmake/ios.toolchain.cmake \
        -DPLATFORM=OS64 \
        -DDEPLOYMENT_TARGET=12.0
    make -j$(sysctl -n hw.ncpu)
    cd ..
else
    echo "✅ OpenVPN client library already built for iOS"
fi

# Build iOS wrapper library
echo "🔨 Building iOS wrapper library..."
cd "${SCRIPT_DIR}"
mkdir -p build
cd build

# Configure for iOS with proper toolchain
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_TOOLCHAIN_FILE=${SCRIPT_DIR}/../cmake/ios.toolchain.cmake \
    -DPLATFORM=OS64 \
    -DDEPLOYMENT_TARGET=12.0
make -j$(sysctl -n hw.ncpu)

echo "✅ All OpenVPN libraries built successfully for iOS!"
echo "📚 Libraries available:"
echo "  - OpenVPN3 Core: ${OPENVPN_DIR}/build/ios/install/lib/libopenvpn3-core.a"
echo "  - OpenVPN Client: ${OPENVPN_DIR}/build/libopenvpn_client_ios.a"
echo "  - iOS Wrapper: ${SCRIPT_DIR}/build/libopenvpn_ios_wrapper.a" 