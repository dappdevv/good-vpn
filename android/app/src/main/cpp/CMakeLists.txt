cmake_minimum_required(VERSION 3.18.1)

project("openvpn_native")

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_library(log-lib log)
find_library(android-lib android)

# OpenVPN3 Core directory
set(OPENVPN3_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openvpn3-core)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${OPENVPN3_DIR}
    ${OPENVPN3_DIR}/openvpn
    ${OPENVPN3_DIR}/client
    ${CMAKE_CURRENT_SOURCE_DIR}/asio/asio/include
    ${CMAKE_CURRENT_SOURCE_DIR}/openssl/include
    ${CMAKE_CURRENT_SOURCE_DIR}/openssl
)

# OpenVPN3 Core source files (key files for client functionality)
set(OPENVPN3_CORE_SOURCES
    ${OPENVPN3_DIR}/openvpn/buffer/buffer.hpp
    ${OPENVPN3_DIR}/openvpn/common/rc.hpp
    ${OPENVPN3_DIR}/openvpn/common/exception.hpp
    ${OPENVPN3_DIR}/openvpn/common/options.hpp
    ${OPENVPN3_DIR}/openvpn/common/string.hpp
    ${OPENVPN3_DIR}/openvpn/common/unicode.hpp
    ${OPENVPN3_DIR}/openvpn/log/logsimple.hpp
    ${OPENVPN3_DIR}/openvpn/time/time.hpp
    ${OPENVPN3_DIR}/openvpn/random/randapi.hpp
    ${OPENVPN3_DIR}/openvpn/crypto/cryptoapi.hpp
    ${OPENVPN3_DIR}/openvpn/ssl/sslapi.hpp
    ${OPENVPN3_DIR}/openvpn/transport/client/transbase.hpp
    ${OPENVPN3_DIR}/openvpn/client/cliconnect.hpp
    ${OPENVPN3_DIR}/openvpn/client/clilife.hpp
    ${OPENVPN3_DIR}/openvpn/client/cliproto.hpp
)

# Our implementation source files
set(OPENVPN3_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/openvpn_jni.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/openvpn_client.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/openvpn3_wrapper.cpp
)

# Preprocessor definitions
add_definitions(
    -DASIO_STANDALONE
    -DUSE_OPENSSL
    -DHAVE_LZ4
    -DOPENVPN_PLATFORM_ANDROID
    -DOPENVPN_PLATFORM_VERSION="Android"
    -DOPENVPN_SHOW_SESSION_TOKEN
    -DOPENVPN_DEBUG
    -DUSE_ASIO
    -DUSE_MBEDTLS
    -DOPENVPN_USE_TUN_BUILDER
    -DOPENVPN_GREMLIN
    -DOPENVPN_ENABLE_ASSERT
)

# Create shared library
add_library(
    openvpn_native
    SHARED
    ${OPENVPN3_SOURCES}
)

# Link libraries
target_link_libraries(
    openvpn_native
    ${log-lib}
    ${android-lib}
    z
)

# Compiler flags
target_compile_options(openvpn_native PRIVATE
    -Wall
    -Wextra
    -Wno-unused-parameter
    -Wno-unused-variable
    -Wno-deprecated-declarations
    -O2
    -fPIC
    -frtti
    -fexceptions
)
