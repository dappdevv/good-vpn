cmake_minimum_required(VERSION 3.18)

project(OpenVPNClient
    VERSION 1.0.0
    DESCRIPTION "OpenVPN Client Library"
    LANGUAGES CXX
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Platform detection
if(ANDROID)
    set(PLATFORM_NAME "android")
    set(DEPS_CMAKE_CONFIG "OpenVPNDepsAndroid")
elseif(WIN32)
    set(PLATFORM_NAME "windows")
    set(DEPS_CMAKE_CONFIG "OpenVPNDeps")
elseif(APPLE)
    set(PLATFORM_NAME "macos")
    set(DEPS_CMAKE_CONFIG "OpenVPNDeps")
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")
elseif(UNIX)
    set(PLATFORM_NAME "linux")
    set(DEPS_CMAKE_CONFIG "OpenVPNDeps")
else()
    set(PLATFORM_NAME "unknown")
    set(DEPS_CMAKE_CONFIG "OpenVPNDeps")
endif()

message(STATUS "Building OpenVPN Client for platform: ${PLATFORM_NAME}")

# Find dependencies
if(ANDROID)
    # For Android, look for dependencies in the Android build directory
    set(ANDROID_ABI_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/android/${ANDROID_ABI}")
    find_package(${DEPS_CMAKE_CONFIG} REQUIRED
        PATHS "${ANDROID_ABI_DIR}/install/lib/cmake"
    )
    set(DEPS_TARGET "OpenVPN::deps_android")
else()
    # For other platforms, look in the platform-specific build directory
    if(APPLE)
        set(PLATFORM_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build/macos")
    else()
        set(PLATFORM_BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build")
    endif()

    include("${PLATFORM_BUILD_DIR}/install/lib/cmake/${DEPS_CMAKE_CONFIG}.cmake")
    set(DEPS_TARGET "OpenVPN::deps")
endif()

# OpenVPN Client Library
set(OPENVPN_CLIENT_SOURCES
    openvpn3_wrapper.cpp
    openvpn_client.cpp
)

# Add platform-specific sources
if(APPLE)
    list(APPEND OPENVPN_CLIENT_SOURCES macos_tun_builder.cpp)
endif()

add_library(openvpn_client STATIC
    ${OPENVPN_CLIENT_SOURCES}
)

target_include_directories(openvpn_client PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/openvpn3
    ${CMAKE_CURRENT_SOURCE_DIR}/build/deps/openvpn3-core
    ${CMAKE_CURRENT_SOURCE_DIR}/build/deps/asio/asio/include
)

target_link_libraries(openvpn_client PUBLIC
    ${DEPS_TARGET}
)

target_compile_definitions(openvpn_client PUBLIC
    ASIO_STANDALONE
    ASIO_NO_DEPRECATED
    HAVE_LZ4
    USE_OPENSSL
)

# Platform-specific compile definitions
if(NOT APPLE)
    # Force TUN_NULL for non-macOS platforms (Android, Windows, Linux)
    target_compile_definitions(openvpn_client PUBLIC
        OPENVPN_FORCE_TUN_NULL
    )
endif()

# Platform-specific configurations
if(ANDROID)
    target_compile_definitions(openvpn_client PUBLIC
        ANDROID
        __ANDROID__
        OPENVPN_PLATFORM_ANDROID
    )
    
    # Android JNI wrapper
    add_library(openvpn_jni SHARED
        openvpn_jni.cpp
    )
    
    target_link_libraries(openvpn_jni PRIVATE
        openvpn_client
        log  # Android log library
    )
    
    target_include_directories(openvpn_jni PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
    )
    
endif()

message(STATUS "OpenVPN Client configured for ${PLATFORM_NAME}")
