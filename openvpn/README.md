# OpenVPN Client Library

Cross-platform OpenVPN client library built on OpenVPN3 Core.

## Quick Start

### Build Dependencies

For desktop platforms:
```bash
./build_dependencies.sh
```

For Android:
```bash
export ANDROID_NDK_ROOT=/path/to/ndk
export ANDROID_ABI=arm64-v8a
./build_android.sh
```

### Use in CMake

```cmake
find_package(OpenVPNClient REQUIRED)
target_link_libraries(your_target OpenVPN::openvpn_client)
```

## Dependencies

- OpenVPN3 Core
- OpenSSL
- ASIO (header-only)
- fmt
- LZ4

All dependencies are automatically cloned from GitHub and built.
