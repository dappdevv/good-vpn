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
    # For other platforms, look in the standard build directory
    find_package(${DEPS_CMAKE_CONFIG} REQUIRED 
        PATHS "${CMAKE_CURRENT_SOURCE_DIR}/build/install/lib/cmake"
    )
    set(DEPS_TARGET "OpenVPN::deps")
endif()

# OpenVPN Client Library
add_library(openvpn_client STATIC
    openvpn3_wrapper.cpp
    openvpn_client.cpp
)

target_include_directories(openvpn_client PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/openvpn3
)

target_link_libraries(openvpn_client PUBLIC
    ${DEPS_TARGET}
)

target_compile_definitions(openvpn_client PUBLIC
    ASIO_STANDALONE
    ASIO_NO_DEPRECATED
    HAVE_LZ4
    USE_OPENSSL
    OPENVPN_FORCE_TUN_NULL
)

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
