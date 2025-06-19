cmake_minimum_required(VERSION 3.18)

project(FlutterOpenVPNMacOS
    VERSION 1.0.0
    DESCRIPTION "Flutter OpenVPN Client for macOS"
    LANGUAGES CXX
)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# macOS configuration
set(CMAKE_OSX_DEPLOYMENT_TARGET "10.15")
set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64")

# OpenVPN Dependencies Path
set(OPENVPN_INSTALL_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../openvpn/build/macos/install")

# Include OpenVPN dependencies
include("${OPENVPN_INSTALL_DIR}/lib/cmake/OpenVPNDeps.cmake")

# Create OpenVPN wrapper library
add_library(openvpn_macos_wrapper STATIC
    Runner/OpenVPNMacWrapper.cpp
    Runner/openvpn_c_wrapper.cpp
)

target_include_directories(openvpn_macos_wrapper PUBLIC
    Runner
    ${OPENVPN_INSTALL_DIR}/include
    ../openvpn
)

target_link_libraries(openvpn_macos_wrapper PUBLIC
    OpenVPN::deps
    ${CMAKE_CURRENT_SOURCE_DIR}/../openvpn/build/libopenvpn_client.a
)

target_compile_definitions(openvpn_macos_wrapper PUBLIC
    ASIO_STANDALONE
    ASIO_NO_DEPRECATED
    OPENVPN_PLATFORM_MAC
    USE_OPENSSL
    USE_ASIO
    HAVE_LZ4
)

# Install the library
install(TARGETS openvpn_macos_wrapper
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

message(STATUS "OpenVPN macOS wrapper configured")
