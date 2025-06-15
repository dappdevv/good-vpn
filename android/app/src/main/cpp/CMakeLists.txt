cmake_minimum_required(VERSION 3.18.1)

# Declare the project
project("openvpn_native")

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add compile definitions to disable fmt stdio usage
add_compile_definitions(
    FMT_USE_WRITE_CONSOLE=0
    FMT_USE_WINDOWS_H=0
)

# Set OpenVPN root directory
set(OPENVPN_ROOT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../openvpn")

# Set architecture-specific paths
if(ANDROID_ABI STREQUAL "arm64-v8a")
    set(ANDROID_ARCH "arm64")
elseif(ANDROID_ABI STREQUAL "armeabi-v7a")
    set(ANDROID_ARCH "arm")
elseif(ANDROID_ABI STREQUAL "x86")
    set(ANDROID_ARCH "x86")
elseif(ANDROID_ABI STREQUAL "x86_64")
    set(ANDROID_ARCH "x86_64")
else()
    message(FATAL_ERROR "Unsupported Android ABI: ${ANDROID_ABI}")
endif()

# Set install directory
set(INSTALL_DIR "${OPENVPN_ROOT_DIR}/build/android/${ANDROID_ARCH}/install")

# Include directories
include_directories(
    ${INSTALL_DIR}/include
    ${OPENVPN_ROOT_DIR}/build/deps/openvpn3-core
    ${OPENVPN_ROOT_DIR}/build/deps/asio/asio/include
    ${OPENVPN_ROOT_DIR}/build/deps/fmt/include
    ${OPENVPN_ROOT_DIR}/build/deps/lz4/lib
)

# Link directories
link_directories(${INSTALL_DIR}/lib)

# Find required libraries
find_library(log-lib log)
find_library(android-lib android)

# Create Android JNI wrapper
add_library(
    openvpn_native
    SHARED
    ${OPENVPN_ROOT_DIR}/openvpn_jni.cpp
    ${OPENVPN_ROOT_DIR}/openvpn_client.cpp
    ${OPENVPN_ROOT_DIR}/openvpn3_wrapper.cpp
    android_compat.cpp
)

# Link libraries
target_link_libraries(openvpn_native
    openvpn3-core
    ssl
    crypto
    fmt
    lz4
    ${log-lib}
    ${android-lib}
    -latomic
    -lm
    -ldl
)
