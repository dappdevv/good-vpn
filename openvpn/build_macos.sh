#!/bin/bash

# OpenVPN macOS Dependencies Build Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
DEPS_DIR="${BUILD_DIR}/deps"
MACOS_BUILD_DIR="${BUILD_DIR}/macos"

# macOS configuration
MACOS_DEPLOYMENT_TARGET="10.15"
MACOS_ARCHS="x86_64;arm64"  # Universal binary

echo "🍎 Building OpenVPN dependencies for macOS"
echo "🎯 Deployment Target: ${MACOS_DEPLOYMENT_TARGET}"
echo "🏗️  Architectures: ${MACOS_ARCHS}"

mkdir -p "${MACOS_BUILD_DIR}"
INSTALL_DIR="${MACOS_BUILD_DIR}/install"
mkdir -p "${INSTALL_DIR}"

# First run the main dependency script to clone repos
./build_dependencies.sh

# Set up macOS build environment
export MACOSX_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET}"

echo "🔨 Building OpenSSL for macOS..."
OPENSSL_BUILD_DIR="${MACOS_BUILD_DIR}/openssl"
mkdir -p "${OPENSSL_BUILD_DIR}"

# Build OpenSSL for x86_64
echo "Building OpenSSL for x86_64..."
OPENSSL_X86_DIR="${OPENSSL_BUILD_DIR}/x86_64"
mkdir -p "${OPENSSL_X86_DIR}"
cd "${DEPS_DIR}/openssl"
make clean || true

./Configure darwin64-x86_64-cc \
    --prefix="${OPENSSL_X86_DIR}" \
    --openssldir="${OPENSSL_X86_DIR}/ssl" \
    no-shared \
    no-tests \
    no-ui-console \
    -mmacosx-version-min=${MACOS_DEPLOYMENT_TARGET}

make -j$(sysctl -n hw.ncpu)
make install_sw

# Build OpenSSL for arm64
echo "Building OpenSSL for arm64..."
OPENSSL_ARM64_DIR="${OPENSSL_BUILD_DIR}/arm64"
mkdir -p "${OPENSSL_ARM64_DIR}"
make clean

./Configure darwin64-arm64-cc \
    --prefix="${OPENSSL_ARM64_DIR}" \
    --openssldir="${OPENSSL_ARM64_DIR}/ssl" \
    no-shared \
    no-tests \
    no-ui-console \
    -mmacosx-version-min=${MACOS_DEPLOYMENT_TARGET}

make -j$(sysctl -n hw.ncpu)
make install_sw

# Create universal binaries
echo "Creating universal OpenSSL binaries..."
mkdir -p "${INSTALL_DIR}/lib"
mkdir -p "${INSTALL_DIR}/include"

# Copy headers (same for both architectures)
cp -r "${OPENSSL_X86_DIR}/include/"* "${INSTALL_DIR}/include/"

# Create universal libraries
lipo -create \
    "${OPENSSL_X86_DIR}/lib/libssl.a" \
    "${OPENSSL_ARM64_DIR}/lib/libssl.a" \
    -output "${INSTALL_DIR}/lib/libssl.a"

lipo -create \
    "${OPENSSL_X86_DIR}/lib/libcrypto.a" \
    "${OPENSSL_ARM64_DIR}/lib/libcrypto.a" \
    -output "${INSTALL_DIR}/lib/libcrypto.a"

echo "✅ OpenSSL universal binary built for macOS"

# Build fmt library
echo "🔨 Building fmt for macOS..."
FMT_BUILD_DIR="${MACOS_BUILD_DIR}/fmt"
mkdir -p "${FMT_BUILD_DIR}"
cd "${FMT_BUILD_DIR}"

cmake "${DEPS_DIR}/fmt" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET}" \
    -DCMAKE_OSX_ARCHITECTURES="${MACOS_ARCHS}" \
    -DFMT_DOC=OFF \
    -DFMT_TEST=OFF \
    -DFMT_INSTALL=ON \
    -DFMT_OS=OFF \
    -DBUILD_SHARED_LIBS=OFF

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ fmt built for macOS"

# Build LZ4 library
echo "🔨 Building LZ4 for macOS..."
LZ4_BUILD_DIR="${MACOS_BUILD_DIR}/lz4"
mkdir -p "${LZ4_BUILD_DIR}"
cd "${LZ4_BUILD_DIR}"

cmake "${DEPS_DIR}/lz4/build/cmake" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET}" \
    -DCMAKE_OSX_ARCHITECTURES="${MACOS_ARCHS}" \
    -DLZ4_BUILD_CLI=OFF \
    -DLZ4_BUILD_LEGACY_LZ4C=OFF \
    -DBUILD_SHARED_LIBS=OFF

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ LZ4 built for macOS"

# Install ASIO headers (header-only)
echo "📋 Installing ASIO headers..."
mkdir -p "${INSTALL_DIR}/include"
cp -r "${DEPS_DIR}/asio/asio/include/asio" "${INSTALL_DIR}/include/"
cp "${DEPS_DIR}/asio/asio/include/asio.hpp" "${INSTALL_DIR}/include/"
echo "✅ ASIO headers installed"

# Build OpenVPN3 Core library
echo "🔨 Building OpenVPN3 Core for macOS..."
OPENVPN3_BUILD_DIR="${MACOS_BUILD_DIR}/openvpn3-core"
mkdir -p "${OPENVPN3_BUILD_DIR}"
cd "${OPENVPN3_BUILD_DIR}"

# Create a CMakeLists.txt for OpenVPN3 Core client library
cat > CMakeLists.txt << EOF
cmake_minimum_required(VERSION 3.10)
project(openvpn3-core)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set up library paths
set(OPENSSL_ROOT_DIR "${INSTALL_DIR}")
set(OPENSSL_INCLUDE_DIR "${INSTALL_DIR}/include")
set(OPENSSL_CRYPTO_LIBRARY "${INSTALL_DIR}/lib/libcrypto.a")
set(OPENSSL_SSL_LIBRARY "${INSTALL_DIR}/lib/libssl.a")

# Include directories
include_directories(\${CMAKE_CURRENT_SOURCE_DIR}/../../deps/openvpn3-core)
include_directories(\${CMAKE_CURRENT_SOURCE_DIR}/../../deps/asio/asio/include)
include_directories("${INSTALL_DIR}/include")

# Define the OpenVPN3 Core client library
add_library(openvpn3-core STATIC
    ../../deps/openvpn3-core/client/ovpncli.cpp
    ../../deps/openvpn3-core/openvpn/crypto/data_epoch.cpp
)

target_compile_definitions(openvpn3-core PUBLIC
    USE_OPENSSL
    USE_ASIO
    ASIO_STANDALONE
    ASIO_NO_DEPRECATED
    HAVE_LZ4
    OPENVPN_PLATFORM_MAC
    OPENVPN_FORCE_TUN_NULL
)

target_link_libraries(openvpn3-core
    "\${OPENSSL_SSL_LIBRARY}"
    "\${OPENSSL_CRYPTO_LIBRARY}"
    "${INSTALL_DIR}/lib/libfmt.a"
)

install(TARGETS openvpn3-core
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)
EOF

cmake . \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET}" \
    -DCMAKE_OSX_ARCHITECTURES="${MACOS_ARCHS}" \
    -DCMAKE_PREFIX_PATH="${INSTALL_DIR}"

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ OpenVPN3 Core built for macOS"

# Create macOS CMake config
echo "📝 Creating macOS CMake configuration..."
mkdir -p "${INSTALL_DIR}/lib/cmake"

cat > "${INSTALL_DIR}/lib/cmake/OpenVPNDeps.cmake" << 'EOF'
# OpenVPN Dependencies macOS CMake Configuration

set(OPENVPN_DEPS_ROOT "${CMAKE_CURRENT_LIST_DIR}/../..")
set(OPENVPN_DEPS_INCLUDE_DIR "${OPENVPN_DEPS_ROOT}/include")
set(OPENVPN_DEPS_LIB_DIR "${OPENVPN_DEPS_ROOT}/lib")

# Find libraries
find_library(OPENSSL_CRYPTO_LIB crypto PATHS "${OPENVPN_DEPS_LIB_DIR}" NO_DEFAULT_PATH)
find_library(OPENSSL_SSL_LIB ssl PATHS "${OPENVPN_DEPS_LIB_DIR}" NO_DEFAULT_PATH)
find_library(FMT_LIB fmt PATHS "${OPENVPN_DEPS_LIB_DIR}" NO_DEFAULT_PATH)
find_library(LZ4_LIB lz4 PATHS "${OPENVPN_DEPS_LIB_DIR}" NO_DEFAULT_PATH)
find_library(OPENVPN3_CORE_LIB openvpn3-core PATHS "${OPENVPN_DEPS_LIB_DIR}" NO_DEFAULT_PATH)

# Create imported targets
if(NOT TARGET OpenVPN::deps)
    add_library(OpenVPN::deps INTERFACE IMPORTED)
    target_include_directories(OpenVPN::deps INTERFACE
        "${OPENVPN_DEPS_INCLUDE_DIR}"
    )
    target_link_libraries(OpenVPN::deps INTERFACE
        "${OPENVPN3_CORE_LIB}"
        "${OPENSSL_SSL_LIB}"
        "${OPENSSL_CRYPTO_LIB}"
        "${FMT_LIB}"
        "${LZ4_LIB}"
    )
    target_compile_definitions(OpenVPN::deps INTERFACE
        ASIO_STANDALONE
        ASIO_NO_DEPRECATED
        OPENVPN_PLATFORM_MAC
        USE_OPENSSL
        USE_ASIO
        HAVE_LZ4
    )
endif()

message(STATUS "OpenVPN macOS dependencies found:")
message(STATUS "  OpenVPN3 Core: ${OPENVPN3_CORE_LIB}")
message(STATUS "  OpenSSL: ${OPENSSL_SSL_LIB}")
message(STATUS "  fmt: ${FMT_LIB}")
message(STATUS "  LZ4: ${LZ4_LIB}")
message(STATUS "  ASIO: ${OPENVPN_DEPS_INCLUDE_DIR}")
EOF

echo "✅ macOS dependencies ready!"
echo "📁 Install directory: ${INSTALL_DIR}"
