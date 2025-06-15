#!/bin/bash

# OpenVPN Android Dependencies Build Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
DEPS_DIR="${BUILD_DIR}/deps"
ANDROID_BUILD_DIR="${BUILD_DIR}/android"

# Android NDK configuration
ANDROID_NDK="${ANDROID_NDK_ROOT:-$ANDROID_HOME/ndk/27.0.12077973}"
ANDROID_API=24
ANDROID_ABI="${ANDROID_ABI:-arm64-v8a}"

if [ ! -d "${ANDROID_NDK}" ]; then
    echo "❌ Android NDK not found at: ${ANDROID_NDK}"
    echo "   Please set ANDROID_NDK_ROOT or install NDK"
    exit 1
fi

echo "🤖 Building OpenVPN dependencies for Android"
echo "📱 Android NDK: ${ANDROID_NDK}"
echo "📱 Android ABI: ${ANDROID_ABI}"

mkdir -p "${ANDROID_BUILD_DIR}/${ANDROID_ABI}"
INSTALL_DIR="${ANDROID_BUILD_DIR}/${ANDROID_ABI}/install"
mkdir -p "${INSTALL_DIR}"

# First run the main dependency script to clone repos
./build_dependencies.sh

# Set up Android toolchain variables
ANDROID_TOOLCHAIN="${ANDROID_NDK}/toolchains/llvm/prebuilt/darwin-x86_64"
export CC="${ANDROID_TOOLCHAIN}/bin/aarch64-linux-android${ANDROID_API}-clang"
export CXX="${ANDROID_TOOLCHAIN}/bin/aarch64-linux-android${ANDROID_API}-clang++"
export AR="${ANDROID_TOOLCHAIN}/bin/llvm-ar"
export RANLIB="${ANDROID_TOOLCHAIN}/bin/llvm-ranlib"

echo "🔨 Building OpenSSL for Android..."
OPENSSL_BUILD_DIR="${ANDROID_BUILD_DIR}/${ANDROID_ABI}/openssl"
mkdir -p "${OPENSSL_BUILD_DIR}"
cd "${DEPS_DIR}/openssl"

# Configure OpenSSL for Android
case "${ANDROID_ABI}" in
    "arm64-v8a")
        OPENSSL_TARGET="android-arm64"
        ;;
    "armeabi-v7a")
        OPENSSL_TARGET="android-arm"
        ;;
    "x86_64")
        OPENSSL_TARGET="android-x86_64"
        ;;
    "x86")
        OPENSSL_TARGET="android-x86"
        ;;
    *)
        echo "❌ Unsupported Android ABI: ${ANDROID_ABI}"
        exit 1
        ;;
esac

# Set Android environment for OpenSSL
export ANDROID_NDK_HOME="${ANDROID_NDK}"
export PATH="${ANDROID_TOOLCHAIN}/bin:${PATH}"

# Configure and build OpenSSL
./Configure ${OPENSSL_TARGET} \
    -D__ANDROID_API__=${ANDROID_API} \
    --prefix="${INSTALL_DIR}" \
    --openssldir="${INSTALL_DIR}/ssl" \
    no-shared \
    no-tests \
    no-ui-console \
    no-stdio

make clean
make -j$(sysctl -n hw.ncpu)
make install_sw
echo "✅ OpenSSL built for Android"

# Build fmt library (not header-only for better performance)
echo "🔨 Building fmt for Android..."
FMT_BUILD_DIR="${ANDROID_BUILD_DIR}/${ANDROID_ABI}/fmt"
mkdir -p "${FMT_BUILD_DIR}"
cd "${FMT_BUILD_DIR}"

cmake "${DEPS_DIR}/fmt" \
    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="${ANDROID_ABI}" \
    -DANDROID_PLATFORM="android-${ANDROID_API}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DFMT_DOC=OFF \
    -DFMT_TEST=OFF \
    -DFMT_INSTALL=ON \
    -DFMT_OS=OFF

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ fmt built for Android"

# Build LZ4 library using CMake for proper cross-compilation
echo "🔨 Building LZ4 for Android..."
LZ4_BUILD_DIR="${ANDROID_BUILD_DIR}/${ANDROID_ABI}/lz4"
mkdir -p "${LZ4_BUILD_DIR}"
cd "${LZ4_BUILD_DIR}"

cmake "${DEPS_DIR}/lz4/build/cmake" \
    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="${ANDROID_ABI}" \
    -DANDROID_PLATFORM="android-${ANDROID_API}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DLZ4_BUILD_CLI=OFF \
    -DLZ4_BUILD_LEGACY_LZ4C=OFF \
    -DBUILD_SHARED_LIBS=OFF

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ LZ4 built for Android"

# Install ASIO headers (header-only)
echo "📋 Installing ASIO headers..."
mkdir -p "${INSTALL_DIR}/include"
cp -r "${DEPS_DIR}/asio/asio/include/asio" "${INSTALL_DIR}/include/"
cp "${DEPS_DIR}/asio/asio/include/asio.hpp" "${INSTALL_DIR}/include/"
echo "✅ ASIO headers installed"

# Build OpenVPN3 Core library
echo "🔨 Building OpenVPN3 Core for Android..."
OPENVPN3_BUILD_DIR="${ANDROID_BUILD_DIR}/${ANDROID_ABI}/openvpn3-core"
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
include_directories(\${CMAKE_CURRENT_SOURCE_DIR}/../../../deps/openvpn3-core)
include_directories(\${CMAKE_CURRENT_SOURCE_DIR}/../../../deps/asio/asio/include)
include_directories("${INSTALL_DIR}/include")

# Define the OpenVPN3 Core client library
add_library(openvpn3-core STATIC
    ../../../deps/openvpn3-core/client/ovpncli.cpp
    ../../../deps/openvpn3-core/openvpn/crypto/data_epoch.cpp
)

target_compile_definitions(openvpn3-core PUBLIC
    USE_OPENSSL
    USE_ASIO
    ASIO_STANDALONE
    ASIO_NO_DEPRECATED
    HAVE_LZ4
    OPENVPN_PLATFORM_ANDROID
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
    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK}/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI="${ANDROID_ABI}" \
    -DANDROID_PLATFORM="android-${ANDROID_API}" \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${INSTALL_DIR}"

make -j$(sysctl -n hw.ncpu)
make install
echo "✅ OpenVPN3 Core built for Android"

# Create Android CMake config
echo "📝 Creating Android CMake configuration..."
mkdir -p "${INSTALL_DIR}/lib/cmake"

cat > "${INSTALL_DIR}/lib/cmake/OpenVPNDepsAndroid.cmake" << 'EOF'
# OpenVPN Dependencies Android CMake Configuration

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
if(NOT TARGET OpenVPN::deps_android)
    add_library(OpenVPN::deps_android INTERFACE IMPORTED)
    target_include_directories(OpenVPN::deps_android INTERFACE
        "${OPENVPN_DEPS_INCLUDE_DIR}"
    )
    target_link_libraries(OpenVPN::deps_android INTERFACE
        "${OPENVPN3_CORE_LIB}"
        "${OPENSSL_SSL_LIB}"
        "${OPENSSL_CRYPTO_LIB}"
        "${FMT_LIB}"
        "${LZ4_LIB}"
    )
    target_compile_definitions(OpenVPN::deps_android INTERFACE
        ASIO_STANDALONE
        ASIO_NO_DEPRECATED
        OPENVPN_PLATFORM_ANDROID
        USE_OPENSSL
        USE_ASIO
        HAVE_LZ4
    )
endif()

message(STATUS "OpenVPN Android dependencies found:")
message(STATUS "  OpenVPN3 Core: ${OPENVPN3_CORE_LIB}")
message(STATUS "  OpenSSL: ${OPENSSL_SSL_LIB}")
message(STATUS "  fmt: ${FMT_LIB}")
message(STATUS "  LZ4: ${LZ4_LIB}")
message(STATUS "  ASIO: ${OPENVPN_DEPS_INCLUDE_DIR}")
EOF

echo "✅ Android dependencies ready!"
echo "📁 Install directory: ${INSTALL_DIR}"
