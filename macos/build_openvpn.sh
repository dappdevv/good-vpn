#!/bin/bash

# Build OpenVPN libraries for macOS Flutter app
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OPENVPN_DIR="${PROJECT_ROOT}/openvpn"

echo "🍎 Building OpenVPN libraries for macOS Flutter app"
echo "📁 Project root: ${PROJECT_ROOT}"
echo "📁 OpenVPN directory: ${OPENVPN_DIR}"

# Check if OpenVPN directory exists
if [ ! -d "${OPENVPN_DIR}" ]; then
    echo "❌ OpenVPN directory not found: ${OPENVPN_DIR}"
    exit 1
fi

cd "${OPENVPN_DIR}"

# Build OpenVPN dependencies for macOS if not already built
if [ ! -f "build/macos/install/lib/libopenvpn3-core.a" ]; then
    echo "🔨 Building OpenVPN dependencies for macOS..."
    ./build_macos.sh
else
    echo "✅ OpenVPN dependencies already built"
fi

# Build OpenVPN client library if not already built
if [ ! -f "build/libopenvpn_client.a" ]; then
    echo "🔨 Building OpenVPN client library..."
    mkdir -p build
    cd build
    cmake .. -DCMAKE_BUILD_TYPE=Release
    make -j$(sysctl -n hw.ncpu)
    cd ..
else
    echo "✅ OpenVPN client library already built"
fi

# Build macOS wrapper library
echo "🔨 Building macOS wrapper library..."
cd "${SCRIPT_DIR}"
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(sysctl -n hw.ncpu)

echo "✅ All OpenVPN libraries built successfully!"
echo "📚 Libraries available:"
echo "  - OpenVPN3 Core: ${OPENVPN_DIR}/build/macos/install/lib/libopenvpn3-core.a"
echo "  - OpenVPN Client: ${OPENVPN_DIR}/build/libopenvpn_client.a"
echo "  - macOS Wrapper: ${SCRIPT_DIR}/build/libopenvpn_macos_wrapper.a"
