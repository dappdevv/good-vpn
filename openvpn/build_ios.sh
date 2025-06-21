#!/bin/bash

# Build OpenVPN3 Core and dependencies for iOS
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM="ios"
BUILD_DIR="${SCRIPT_DIR}/build/${PLATFORM}"
INSTALL_DIR="${BUILD_DIR}/install"

echo "📱 Building OpenVPN3 Core and dependencies for iOS"
echo "📁 Build directory: ${BUILD_DIR}"
echo "📁 Install directory: ${INSTALL_DIR}"

mkdir -p "${BUILD_DIR}"
mkdir -p "${INSTALL_DIR}"

# Set up iOS SDK and toolchain
export XCODE_ROOT=$(xcode-select -print-path)
export SDKROOT="${XCODE_ROOT}/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk"
export IOS_MIN_VERSION="12.0"

# Check if we have iOS SDK
if [ ! -d "$SDKROOT" ]; then
    echo "❌ iOS SDK not found at: $SDKROOT"
    echo "Please install Xcode and iOS SDK"
    exit 1
fi

echo "✅ Using iOS SDK: $SDKROOT"

# Build dependencies function
build_dependency() {
    local name=$1
    local url=$2
    local version=$3
    local build_cmd=$4
    
    echo "🔨 Building $name $version for iOS..."
    
    cd "${BUILD_DIR}"
    
    if [ ! -d "$name" ]; then
        echo "📥 Downloading $name..."
        if [[ "$url" == *.tar.gz ]]; then
            curl -L "$url" | tar xz
            mv "$name-$version" "$name" 2>/dev/null || mv "$name"* "$name" 2>/dev/null || true
        else
            git clone --depth 1 --branch "$version" "$url" "$name"
        fi
    fi
    
    cd "$name"
    
    if [ ! -f "${INSTALL_DIR}/lib/lib${name}.a" ]; then
        echo "🔨 Configuring and building $name..."
        eval "$build_cmd"
        echo "✅ $name built successfully"
    else
        echo "✅ $name already built"
    fi
    
    cd "${BUILD_DIR}"
}

# Build OpenSSL for iOS
build_dependency "openssl" \
    "https://github.com/openssl/openssl/archive/refs/tags/openssl-3.3.2.tar.gz" \
    "3.3.2" \
    "./Configure ios64-xcrun no-shared no-async --prefix=${INSTALL_DIR} --openssldir=${INSTALL_DIR}/ssl && make -j$(sysctl -n hw.ncpu) && make install"

# Build LZ4 for iOS
build_dependency "lz4" \
    "https://github.com/lz4/lz4/archive/refs/tags/v1.10.0.tar.gz" \
    "1.10.0" \
    "make -j$(sysctl -n hw.ncpu) CC='xcrun clang -arch arm64 -mios-version-min=${IOS_MIN_VERSION} -isysroot ${SDKROOT}' PREFIX=${INSTALL_DIR} install"

# Build FMT for iOS  
build_dependency "fmt" \
    "https://github.com/fmtlib/fmt/archive/refs/tags/11.0.2.tar.gz" \
    "11.0.2" \
    "mkdir -p build && cd build && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DCMAKE_OSX_SYSROOT=${SDKROOT} -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=${IOS_MIN_VERSION} -DFMT_TEST=OFF && make -j$(sysctl -n hw.ncpu) && make install"

# Download and prepare ASIO headers
echo "🔨 Preparing ASIO headers for iOS..."
ASIO_DIR="${BUILD_DIR}/asio"
if [ ! -d "$ASIO_DIR" ]; then
    cd "${BUILD_DIR}"
    git clone --depth 1 --branch asio-1-30-2 https://github.com/chriskohlhoff/asio.git
fi

# Download OpenVPN3 Core
echo "🔨 Preparing OpenVPN3 Core for iOS..."
OPENVPN3_DIR="${BUILD_DIR}/openvpn3-core"
if [ ! -d "$OPENVPN3_DIR" ]; then
    cd "${BUILD_DIR}"
    # Use master branch as v3.11.1 tag doesn't exist
    git clone --depth 1 https://github.com/OpenVPN/openvpn3.git openvpn3-core
fi

# Build OpenVPN3 Core for iOS
echo "🔨 Building OpenVPN3 Core for iOS..."
cd "$OPENVPN3_DIR"

if [ ! -f "${INSTALL_DIR}/lib/libopenvpn3-core.a" ]; then
    mkdir -p build
    cd build
    
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
        -DCMAKE_OSX_SYSROOT="${SDKROOT}" \
        -DCMAKE_OSX_ARCHITECTURES="arm64" \
        -DCMAKE_OSX_DEPLOYMENT_TARGET="${IOS_MIN_VERSION}" \
        -DOPENSSL_ROOT_DIR="${INSTALL_DIR}" \
        -DASIO_DIR="${ASIO_DIR}/asio/include" \
        -DLIBFMT_DIR="${INSTALL_DIR}" \
        -DLZ4_DIR="${INSTALL_DIR}" \
        -DOPENVPN3_CORE_STATIC=ON \
        -DBUILD_TESTING=OFF \
        -DENABLE_KOVPN=OFF \
        -DENABLE_OVPNDCO=OFF
    
    make -j$(sysctl -n hw.ncpu)
    make install
    
    echo "✅ OpenVPN3 Core built successfully for iOS"
else
    echo "✅ OpenVPN3 Core already built for iOS"
fi

echo ""
echo "🎉 All dependencies built successfully for iOS!"
echo "📚 Libraries available in: ${INSTALL_DIR}/lib"
ls -la "${INSTALL_DIR}/lib/"

echo ""
echo "📱 iOS OpenVPN3 build complete!"
echo "📁 Build output: ${BUILD_DIR}"
echo "📁 Install location: ${INSTALL_DIR}" 